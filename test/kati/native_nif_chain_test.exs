defmodule Kati.NativeNifChainTest do
  @moduledoc """
  Keeps the five links of Kati's project-owned NIF chain in step.

      Kati.Nifs.<Module>.<fun>/<arity>       lib/kati/nifs/*.ex
        └─ nif_funcs[] entry                 c_src/*.c
             └─ GetStaticMethodID(name, sig) c_src/*.c
                  └─ @JvmStatic fun name(…)  MobBridge.kt
                       └─ registered init    mob.exs + priv/generated/driver_tab_*.zig

  **Every one of those joins fails at runtime, on a device, and only there.**
  A name or arity that disagrees between the Elixir stub and `nif_funcs[]`
  makes `:erlang.load_nif/2` answer `{:bad_lib, …}` and the whole module go
  unbound — which Kati then reports, correctly and uselessly, as "there is no
  native store". A JNI descriptor that disagrees with the Kotlin makes
  `GetStaticMethodID` return NULL, which reads as "the bridge method is
  missing". A missing driver-table entry makes the init symbol unresolved at
  link time on a build machine nobody is watching.

  None of it can be caught by compiling: the C file, the Kotlin file and the
  Elixir file are three separate compilations that never see each other, and
  the host has no JVM to bind against. So the joins are checked as text, here,
  where a rename fails the suite in the same commit that made it.

  These tests read source rather than behaviour on purpose, and that is the
  honest limit of what a host can prove: they cannot say the Keystore works,
  or that a share sheet opens. They say the wires are connected to each other.
  """
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)

  @bridge_kt Path.join(@root, "android/app/src/main/java/com/example/kati/MobBridge.kt")
  @beam_jni Path.join(@root, "android/app/src/main/jni/beam_jni.c")
  @jni_header Path.join(@root, "c_src/kati_jni.h")
  @mob_exs Path.join(@root, "mob.exs")

  @chain [
    {"kati_secure_store", Kati.Nifs.KatiSecureStore},
    {"kati_bridge", Kati.Nifs.KatiBridge}
  ]

  describe "the Elixir stub and the C function table" do
    for {name, module} <- @chain do
      test "#{name}: every C entry has an Elixir stub of the same arity" do
        {name, module} = {unquote(name), unquote(module)}
        declared = c_nif_funcs(name)

        assert declared != [], "no nif_funcs[] entries parsed out of c_src/#{name}.c"

        exported = module.__info__(:functions)

        for {fun, arity} <- declared do
          assert {String.to_atom(fun), arity} in exported,
                 "c_src/#{name}.c exports #{fun}/#{arity} and #{inspect(module)} does not. " <>
                   "load_nif/2 answers {:bad_lib, _} on the whole module for one mismatch."
        end
      end

      test "#{name}: every Elixir stub has a C entry of the same arity" do
        {name, module} = {unquote(name), unquote(module)}
        declared = MapSet.new(c_nif_funcs(name), fn {fun, arity} -> {fun, arity} end)

        # load_nif/0 is the loader itself and is never a NIF.
        stubs =
          module.__info__(:functions)
          |> Enum.reject(fn {fun, arity} -> {fun, arity} == {:load_nif, 0} end)

        assert stubs != [], "#{inspect(module)} exports nothing but its loader"

        for {fun, arity} <- stubs do
          assert MapSet.member?(declared, {Atom.to_string(fun), arity}),
                 "#{inspect(module)}.#{fun}/#{arity} has no entry in c_src/#{name}.c, so it " <>
                   "stays a stub that raises :nif_not_loaded forever — on device too"
        end
      end

      test "#{name}: ERL_NIF_INIT names the module the stub actually is" do
        {name, module} = {unquote(name), unquote(module)}
        source = c_source(name)

        [_, declared] = Regex.run(~r/ERL_NIF_INIT\(\s*([A-Za-z0-9_.]+)\s*,/, source)

        assert declared == "Elixir." <> inspect(module),
               "c_src/#{name}.c registers #{declared}; the static NIF table matches on that " <>
                 "exact string, so #{inspect(module)} would never bind"
      end

      test "#{name}: every stub raises rather than returning a stub value" do
        {name, module} = {unquote(name), unquote(module)}

        for {fun, arity} <- c_nif_funcs(name) do
          args = List.duplicate("", arity)

          assert_raise ErlangError, fn ->
            apply(module, String.to_atom(fun), args)
          end
        end

        # ...and the raise is specifically :nif_not_loaded, which is what
        # Kati.Native.Bridge maps to :no_bridge. Anything else would surface as
        # an unexplained native error on every host call.
        [{fun, arity} | _] = c_nif_funcs(name)

        error =
          assert_raise ErlangError, fn ->
            apply(module, String.to_atom(fun), List.duplicate("", arity))
          end

        assert error.original == :nif_not_loaded
      end
    end
  end

  describe "the C file and the Kotlin bridge" do
    test "every bridge method the C calls exists, is @JvmStatic, and matches its descriptor" do
      kotlin = File.read!(@bridge_kt)
      calls = Enum.flat_map(@chain, fn {name, _} -> bridge_calls(name) end)

      assert length(calls) >= 11,
             "only #{length(calls)} bridge calls parsed — the scan is not reading the C files"

      for {method, descriptor} <- calls do
        assert kotlin =~ ~r/@JvmStatic\s*\n\s*fun #{method}\(/,
               "MobBridge.#{method} is missing or not @JvmStatic. GetStaticMethodID cannot " <>
                 "find a non-static method, and the failure is a NULL at runtime on device."

        {expected_params, expected_return} = parse_descriptor(descriptor)
        {actual_params, actual_return} = kotlin_signature(kotlin, method)

        assert actual_params == expected_params,
               "MobBridge.#{method} takes #{inspect(actual_params)} but the C calls it with " <>
                 "#{descriptor} (#{inspect(expected_params)})"

        assert actual_return == expected_return,
               "MobBridge.#{method} returns #{inspect(actual_return)} but the C descriptor " <>
                 "#{descriptor} says #{inspect(expected_return)}"
      end
    end

    test "the bridge class is cached in JNI_OnLoad, where FindClass can still see it" do
      jni = File.read!(@beam_jni)

      assert jni =~ "jclass g_kati_bridge_cls",
             "the C NIFs declare `extern jclass g_kati_bridge_cls` and would not link"

      assert jni =~ ~r/JNI_OnLoad(?s).{0,600}kati_cache_bridge_class\(env\)/,
             "the cache is populated somewhere other than JNI_OnLoad — a NIF thread has no " <>
               "Java frames, so FindClass there resolves against the system class loader " <>
               "and cannot see com.example.kati.MobBridge"

      assert jni =~ "ExceptionClear",
             "a pending exception makes the NEXT JNI call on the thread abort the process"

      assert File.read!(@jni_header) =~ "extern jclass g_kati_bridge_cls;"
    end

    test "nothing calls a bridge method without going through the cached class" do
      # FindClass from a scheduler thread is the one mistake that looks like it
      # works — it compiles, links, and returns NULL only on a device.
      for {name, _} <- @chain do
        refute c_source(name) =~ "FindClass",
               "c_src/#{name}.c calls FindClass directly; use g_kati_bridge_cls"
      end
    end
  end

  describe "the build registration" do
    test "both NIFs are listed in mob.exs, scoped to Android" do
      mob_exs = File.read!(@mob_exs)

      for {name, _} <- @chain do
        assert mob_exs =~ "%{module: :#{name}, archs: [:android]}",
               "mob.exs must list :#{name} as an Android-only static NIF. Dropping it means " <>
                 "mix mob.regen_driver_tab removes it from the table and the module never " <>
                 "binds; widening it to [:all] puts an init symbol in driver_tab_ios.zig " <>
                 "that nothing compiles, because mix mob.add_nif does not wire c_src/*.c " <>
                 "into ios/build.zig or ios/build_device.zig."
      end
    end

    test "the android driver table declares and references both init symbols" do
      table = File.read!(Path.join(@root, "priv/generated/driver_tab_android.zig"))

      for {name, _} <- @chain do
        assert table =~ "extern fn #{name}_nif_init()",
               "driver_tab_android.zig does not declare #{name}_nif_init"

        assert table =~ ".nif_init = #{name}_nif_init,",
               "#{name}_nif_init is declared but not in the table, so load_nif/2 finds " <>
                 "nothing and the module never binds"
      end
    end

    test "the ios driver table references neither, so the iOS link still resolves" do
      table = File.read!(Path.join(@root, "priv/generated/driver_tab_ios.zig"))

      # This is not a preference. `ios/build.zig` and `ios/build_device.zig`
      # have no project-C-NIF block — mob_dev's own generated skeleton says
      # adding one is a manual step — so an entry here is an undefined symbol
      # at link time, discovered on a build machine nobody is watching.
      assert table =~ "mob_nif_nif_init",
             "the scan is not reading a real driver table"

      for {name, _} <- @chain do
        refute table =~ "#{name}_nif_init",
               "driver_tab_ios.zig references #{name}_nif_init but nothing compiles c_src/ " <>
                 "for iOS"
      end
    end

    test "each C file still has a non-Android arm" do
      # Nothing compiles it today, and it is what makes widening `archs` a
      # config change plus the iOS build wiring rather than a rewrite — and
      # what makes the CMake fallback path, which GLOBs every c_src/*.c
      # regardless of arch, safe.
      for {name, _} <- @chain do
        source = c_source(name)

        assert source =~ "#ifdef __ANDROID__"

        assert source =~ ~r/#else(?s).*#endif/,
               "c_src/#{name}.c has no non-Android arm"

        assert source =~ ~r/error:no_(?:bridge|native_store)/,
               "the non-Android arm must answer honestly, not succeed silently"
      end
    end
  end

  # ── helpers ───────────────────────────────────────────────────────────────

  defp c_source(name), do: File.read!(Path.join(@root, "c_src/#{name}.c"))

  # The entries of `static ErlNifFunc nif_funcs[] = { … }`, as {name, arity}.
  defp c_nif_funcs(name) do
    [_, body] =
      Regex.run(~r/ErlNifFunc nif_funcs\[\]\s*=\s*\{(.*?)\};/s, c_source(name))

    ~r/\{"([A-Za-z0-9_?]+)",\s*(\d+),/
    |> Regex.scan(body)
    |> Enum.map(fn [_, fun, arity] -> {fun, String.to_integer(arity)} end)
  end

  # Every `kati_bridge_call(env, "method", "descriptor"` in a C file.
  defp bridge_calls(name) do
    ~r/kati_bridge_call(?:_pid)?\(env,\s*"([A-Za-z0-9_]+)",\s*\n?\s*"([^"]+)"/
    |> Regex.scan(c_source(name))
    |> Enum.map(fn [_, method, descriptor] -> {method, descriptor} end)
    |> Enum.uniq()
  end

  # A JNI descriptor into {[param types], return type}, in Kotlin's names.
  defp parse_descriptor(descriptor) do
    [_, params, ret] = Regex.run(~r/^\((.*)\)(.+)$/, descriptor)
    {jni_types(params), jni_type(ret)}
  end

  defp jni_types(""), do: []

  defp jni_types("J" <> rest), do: ["Long" | jni_types(rest)]

  defp jni_types("Ljava/lang/String;" <> rest), do: ["String" | jni_types(rest)]

  defp jni_type("V"), do: nil
  defp jni_type("Ljava/lang/String;"), do: "String"

  # The declared parameter types and return type of `fun <method>(…)` in
  # MobBridge.kt.
  defp kotlin_signature(kotlin, method) do
    [_, params, ret] =
      Regex.run(~r/fun #{method}\(([^)]*)\)(?:\s*:\s*([A-Za-z0-9_]+))?/, kotlin, capture: :all)
      |> pad_signature()

    types =
      params
      |> String.split(",", trim: true)
      |> Enum.map(fn param -> param |> String.split(":") |> List.last() |> String.trim() end)

    {types, if(ret == "", do: nil, else: ret)}
  end

  defp pad_signature([full, params]), do: [full, params, ""]
  defp pad_signature(captures), do: captures
end
