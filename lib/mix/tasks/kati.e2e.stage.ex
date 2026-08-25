defmodule Mix.Tasks.Kati.E2e.Stage do
  @shortdoc "Stage otp.zip into the e2e build's assets"

  @moduledoc """
  Builds `android/app/src/e2e/assets/otp.zip` — the Erlang runtime the e2e APK
  carries inside itself.

  ## Why this task exists at all

  A `debug` APK does not contain a runtime. `MobBridge.extractOtpIfNeeded/1`
  returns immediately when `otp.zip` is not in the asset list
  (`MobBridge.kt:361`), and the BEAMs arrive afterwards over adb from
  `mix mob.deploy`. That is a good loop for developing and a bad one for
  testing: the code under test is whatever was last pushed, which need not be
  the code in the working tree, and a green suite proves nothing about the
  commit it ran on.

  So the `e2e` build type carries its runtime as an asset, and this task builds
  it. `android/app/src/e2e/assets/` is variant-scoped, so the zip cannot leak
  into a debug build — the same reason `MobDev.ReleaseAndroid` puts the release
  zip under `src/release/assets/` rather than `src/main/assets/`, and the same
  reason `bin/deploy_native.sh:50-54` deletes a stray `src/main/assets/otp.zip`
  on sight.

  ## Why it duplicates mob_dev

  `MobDev.ReleaseAndroid.build_aab/1` does exactly this staging and then builds
  an AAB. Its staging half is private — `stage_otp_tree/2`, `add_app_beams!/2`,
  `add_app_priv!/2` and `add_exqlite!/1` are all `defp` — so there is no way to
  reach it without building a release bundle we do not want.

  What is duplicated here is deliberately the *thin* half. Everything with real
  logic in it is called rather than copied: `MobDev.OtpDownloader.ensure_android/1`
  fetches and caches the tree, `MobDev.HotPush.runtime_beam_dirs/0` decides which
  BEAMs are runtime BEAMs, `MobDev.AppFile.dep_version/1` reads the lock, and
  `MobDev.OtpAssetBundle.build/3` does the stripping and zipping. The forty-odd
  lines below are three `cp` calls and a directory layout.

  The one piece **not** duplicated is the `:crypto` stub. When an OTP tree ships
  without `crypto.a`, `MobDev.ReleaseAndroid` swaps in a stubbed `crypto.beam`,
  and reproducing that is both fiddly and dangerous — a wrong stub makes
  `:ssl.versions/0` raise and every HTTPS request fail at the handshake, which
  is exactly the class of bug that is invisible until a device test hits the
  network. This task refuses to run instead, and says so.

  Retire the duplication if `stage_otp_tree/2` is ever made public upstream.

  ## Usage

      mix kati.e2e.stage              # ABI of the connected device, or x86_64
      mix kati.e2e.stage --abi arm64-v8a
  """

  use Mix.Task

  @assets "android/app/src/e2e/assets"
  @zip Path.join(@assets, "otp.zip")

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [abi: :string])
    Mix.Task.run("compile")

    abi = opts[:abi] || detect_abi()
    app = to_string(Mix.Project.config()[:app])

    Mix.shell().info("  ABI: #{abi}")

    with {:ok, otp} <- MobDev.OtpDownloader.ensure_android(abi),
         :ok <- refuse_without_crypto(otp),
         {:ok, staging} <- stage(otp, app),
         File.mkdir_p!(@assets),
         {:ok, info} <- MobDev.OtpAssetBundle.build(staging, @zip, slim: true) do
      File.rm_rf!(staging)

      Mix.shell().info(
        "  #{@zip} — #{info.zipped_files} files, #{div(info.zip_size_kb, 1024)}MB"
      )

      :ok
    else
      {:error, why} -> Mix.raise("kati.e2e.stage: #{inspect(why)}")
    end
  end

  # The ABI of whatever is attached, because staging the wrong one produces a
  # zip that installs cleanly and dies at `mob_start_beam`. Falls back to
  # x86_64 rather than arm64: the emulator is the thing this task is usually
  # feeding, and `android/app/build.gradle`'s abi-filters fence records that
  # x86_64 exists precisely so the emulator runs at native speed here.
  defp detect_abi do
    case System.cmd("adb", ["shell", "getprop", "ro.product.cpu.abi"], stderr_to_stdout: true) do
      {out, 0} ->
        case String.trim(out) do
          "" -> "x86_64"
          abi -> abi
        end

      _ ->
        "x86_64"
    end
  end

  defp refuse_without_crypto(otp) do
    if MobDev.ReleaseAndroid.real_crypto_available?(otp) do
      :ok
    else
      {:error,
       "this OTP tree ships no crypto.a, so it needs the :crypto stub that " <>
         "MobDev.ReleaseAndroid applies privately. This task deliberately does not " <>
         "reproduce it — see the moduledoc. Use `mix mob.release.android` or ask " <>
         "upstream to make stage_otp_tree/2 public."}
    end
  end

  # ── The duplicated half ────────────────────────────────────────────────────

  defp stage(otp, app) do
    staging =
      Path.join(System.tmp_dir!(), "kati_e2e_stage_#{:erlang.unique_integer([:positive])}")

    File.rm_rf!(staging)

    case System.cmd("cp", ["-R", otp <> "/.", staging], stderr_to_stdout: true) do
      {_, 0} ->
        add_beams!(staging, app)
        add_priv!(staging, app)
        add_exqlite!(staging)
        {:ok, staging}

      {out, _} ->
        {:error, "could not copy the OTP tree: #{out}"}
    end
  end

  # Flattened into one directory, because that is the shape the `-pa` code path
  # on the device expects — the same shape the deployer pushes.
  defp add_beams!(staging, app) do
    dest = Path.join(staging, app)
    File.mkdir_p!(dest)

    for dir <- beam_dirs() do
      System.cmd("cp", ["-r", "#{Path.expand(dir)}/.", dest], stderr_to_stdout: true)
    end
  end

  defp beam_dirs do
    extra =
      for lib <- [:eex, :ssl],
          ebin = Path.join(to_string(:code.lib_dir(lib)), "ebin"),
          File.dir?(ebin),
          do: ebin

    MobDev.HotPush.runtime_beam_dirs() ++ extra
  end

  defp add_priv!(staging, app) do
    priv = Path.join(File.cwd!(), "priv")

    if File.dir?(priv) do
      dest = Path.join([staging, app, "priv"])
      File.rm_rf!(dest)
      System.cmd("cp", ["-R", priv, dest], stderr_to_stdout: true)
    end

    :ok
  end

  # exqlite has to sit at `lib/exqlite-VSN/ebin` in the OTP root rather than in
  # the flat app directory, because `:code.lib_dir(:exqlite)` is what resolves
  # the NIF path at runtime and it only answers for a real OTP lib layout.
  defp add_exqlite!(staging) do
    with vsn when is_binary(vsn) <- MobDev.AppFile.dep_version(:exqlite),
         ebin when is_binary(ebin) <- exqlite_ebin() do
      lib = Path.join(staging, "lib/exqlite-#{vsn}")
      File.mkdir_p!(Path.join(lib, "ebin"))
      File.mkdir_p!(Path.join(lib, "priv"))
      System.cmd("cp", ["-r", "#{Path.expand(ebin)}/.", Path.join(lib, "ebin")], stderr_to_stdout: true)
    else
      _ -> :ok
    end
  end

  defp exqlite_ebin do
    case Path.wildcard("_build/#{Mix.env()}/lib/exqlite/ebin") do
      [ebin | _] -> ebin
      [] -> nil
    end
  end
end
