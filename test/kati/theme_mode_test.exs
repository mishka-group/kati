Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ThemeModeTest do
  @moduledoc """
  Guards the mode source — the one place that answers light vs dark.

  Two failures are worth more than the rest of this file:

    * **Auto meaning Light because nothing ever asked the device.** On the host
      BEAM there is no NIF, so `Mob.Theme.color_scheme/0` rescues to `:light`
      and `Kati.Theme.Mode.device/0` is a constant. Every test written against
      `resolve/0` alone would therefore pass against a `device/0` that simply
      returns `:light` — the exact defect the whole module exists to prevent.
      So the decision is tested through the pure `resolve/2`, the stored-choice
      path is tested against a device that says `:light` while the choice says
      `:dark`, and the wiring itself is asserted on the source.

    * **Light mode moving.** 62 captured frames are the baseline. The light
      palette is frozen here as literals rather than as `Kati.Theme.light()`,
      because a test that compares a function to itself cannot notice the
      function changing.
  """
  # `Mob.ScreenCase` is the blessed harness for anything that touches
  # `Mob.State`: it opens the DETS table against a throwaway data dir. Without
  # it `Mob.State.get/2` raises a `:dets` ArgumentError rather than returning
  # the default. `async: false` because the DETS table and the active
  # `Mob.Theme` are both global.
  use Mob.ScreenCase, async: false

  alias Kati.Theme
  alias Kati.Theme.Mode

  doctest Kati.Theme.Mode

  @key :theme_mode

  # The light palette as of the audit_v7 capture. Literals, not a call.
  @light_palette %Mob.Theme{
    primary: 0xFF1A1917,
    on_primary: 0xFFFBFAF8,
    secondary: 0xFFE8823C,
    on_secondary: 0xFFFBFAF8,
    surface: 0xFFFBFAF8,
    surface_raised: 0xFFFBFAF8,
    on_surface: 0xFF1A1917,
    muted: 0xFF7C766D,
    background: 0xFFEFECE7,
    on_background: 0xFF1A1917,
    error: 0xFFB4553C,
    on_error: 0xFFFBFAF8,
    border: 0x14000000,
    type_scale: 1.0,
    space_scale: 1.0,
    radius_sm: 2,
    radius_md: 20,
    radius_lg: 22,
    radius_pill: 32,
    glass: false
  }

  # Every raw light-side token a screen literal will be refactored onto. These
  # are not in the struct above and are just as load-bearing for the frames.
  @light_tokens %{
    accent: 0xFFE8823C,
    cream: 0xFFFBF1DE,
    ink: 0xFF1A1917,
    ink_soft: 0xFF5C574F,
    card: 0xFFFBFAF8,
    paper: 0xFFEFECE7,
    green: 0xFF4E9A73,
    bronze: 0xFFB08E55,
    red: 0xFFB4553C,
    chrome_fill: 0xF7FBFAF8
  }

  setup do
    assert is_pid(Process.whereis(Mob.State)),
           "Mob.State is not running — every read below would raise instead of " <>
             "exercising the store"

    was = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(was) end)

    Mob.State.delete(@key)
    :ok
  end

  describe "the choice" do
    test "an unset choice is Auto, and the key really is unset" do
      # Without this first assertion the test passes just as happily against a
      # stale :auto left on the key by an earlier run.
      assert Mob.State.get(@key, :__absent__) == :__absent__

      assert Mode.choice() == :auto
      assert Mode.default() == :auto
    end

    test "the control offers exactly three choices" do
      assert Mode.choices() == [:auto, :light, :dark]
      assert length(Mode.choices()) == 3
      assert Mode.default() in Mode.choices()
    end

    test "every offered choice round-trips through the store" do
      for choice <- Mode.choices() do
        assert :ok = Mode.put(choice)
        assert Mode.choice() == choice, "#{inspect(choice)} did not come back"
        assert Mob.State.get(@key) == choice, "#{inspect(choice)} never reached Mob.State"
      end

      assert length(Mode.choices()) == 3, "the loop above covered fewer cases than it looks"
    end

    test "the choice outlives the process that stored it" do
      # This is the whole reason it is in Mob.State and not in assigns: the
      # screen process dies on every root switch.
      assert :ok = Mode.put(:dark)

      stop_supervised!(Mob.State)
      refute Process.whereis(Mob.State), "Mob.State did not actually stop"
      start_supervised!(Mob.State)

      assert Mode.choice() == :dark
    end

    test "a value the app does not recognise reads as Auto rather than crashing" do
      Mob.State.put(@key, :sepia)
      assert Mode.choice() == :auto
    end

    test "put/1 rejects anything that is not an offered choice" do
      # Built at runtime rather than written as a literal. Elixir's type checker
      # can see that a literal `:sepia` matches none of `put/1`'s clauses and
      # warns about the call this assertion exists to make. Same move, and the
      # same reason, as `Kati.MealsRoutesTest`'s `absent`.
      sepia = String.to_atom("sepia")

      assert_raise FunctionClauseError, fn -> Mode.put(sepia) end
      assert Mob.State.get(@key, :__absent__) == :__absent__
    end
  end

  describe "resolution" do
    test "Auto follows the device, both ways" do
      assert Mode.resolve(:auto, :dark) == :dark
      assert Mode.resolve(:auto, :light) == :light
    end

    test "an explicit choice beats the device, both ways" do
      assert Mode.resolve(:light, :dark) == :light
      assert Mode.resolve(:dark, :light) == :dark
    end

    test "every choice x device pair resolves to a real mode" do
      # Catches a choice added to choices/0 with no matching resolve/2 clause:
      # that is a FunctionClauseError at mount, on a tap, in production.
      pairs = for c <- Mode.choices(), d <- [:light, :dark], do: {c, d}

      assert length(pairs) == 6

      for {choice, device} <- pairs do
        assert Mode.resolve(choice, device) in [:light, :dark],
               "resolve(#{inspect(choice)}, #{inspect(device)}) is not a mode"
      end
    end

    test "resolve/2 rejects a device answer that is not a mode" do
      # Runtime-built for the same reason as `sepia` above: a literal here is a
      # type warning on the call the assertion is about.
      sepia = String.to_atom("sepia")

      assert_raise FunctionClauseError, fn -> Mode.resolve(:auto, sepia) end
    end

    test "the stored choice beats the device end to end" do
      # The host device says :light. Storing :dark and reading :dark back
      # through resolve/0 proves the choice is consulted first, with no
      # stubbing involved.
      assert Mode.device() == :light,
             "the host BEAM is expected to report :light; this test's premise is gone"

      assert :ok = Mode.put(:dark)
      assert Mode.resolve() == :dark
    end

    test "Auto defers to whatever device/0 answers, end to end" do
      assert :ok = Mode.put(:auto)
      assert Mode.resolve() == Mode.device()
    end

    test "device/0 answers a mode" do
      assert Mode.device() in [:light, :dark]
    end
  end

  describe "the device wiring" do
    @mode_source Path.expand("../../lib/kati/theme/mode.ex", __DIR__)
    @bridge Path.expand(
              "../../android/app/src/main/java/com/example/kati/MobBridge.kt",
              __DIR__
            )
    @manifest Path.expand("../../android/app/src/main/AndroidManifest.xml", __DIR__)

    test "device/0 reads Mob.Theme.color_scheme/0 and does not hardcode a side" do
      # The host fallback makes a behavioural test of this impossible: a
      # device/0 that returns :light unconditionally passes every assertion
      # above. The wiring has to be asserted on the source.
      body = File.read!(@mode_source) |> String.replace(~r/^\s*#.*$/m, "")

      assert body =~ "Mob.Theme.color_scheme()",
             "Kati.Theme.Mode.device/0 no longer asks the device — Auto has " <>
               "silently become Light"

      assert Code.ensure_loaded?(Mob.Theme)

      assert function_exported?(Mob.Theme, :color_scheme, 0),
             "Mob.Theme.color_scheme/0 is gone; device/0 would raise at every mount"
    end

    test "the Android bridge still exposes the method the NIF looks up by name" do
      # mob's NIF resolves com/example/kati/MobBridge.getColorScheme by name at
      # runtime. Regenerating the native shell without it is not a compile
      # error on either side — it just makes color_scheme/0 fall back to
      # :light forever, on every device, with nothing logged.
      bridge = File.read!(@bridge)

      assert bridge =~ "fun getColorScheme(): String",
             "MobBridge.getColorScheme is gone — Auto would report :light on all devices"

      assert bridge =~ "UI_MODE_NIGHT_MASK"
      assert bridge =~ "fun notifyColorSchemeChanged"
    end

    test "the manifest keeps uiMode as a handled config change" do
      # Without uiMode in configChanges a night-mode toggle recreates the
      # activity instead of delivering onConfigurationChanged, and the
      # :color_scheme_changed event that a live re-resolve depends on is
      # never sent.
      assert File.read!(@manifest) =~ ~r/android:configChanges="[^"]*uiMode/
    end
  end

  describe "Kati.Theme" do
    test "light/0 is byte-identical to the audit_v7 baseline" do
      assert Theme.light() == @light_palette
    end

    test "every raw light-side token is byte-identical to the baseline" do
      actual = %{
        accent: Theme.accent(),
        cream: Theme.cream(:light),
        ink: Theme.ink(),
        ink_soft: Theme.ink_soft(),
        card: Theme.card(:light),
        paper: Theme.paper(:light),
        green: Theme.green(),
        bronze: Theme.bronze(),
        red: Theme.red(),
        chrome_fill: Theme.chrome_fill(:light)
      }

      assert map_size(actual) == 10
      assert actual == @light_tokens
    end

    test "for_mode/1 returns the palettes themselves, not re-derivations" do
      assert Theme.for_mode(:light) == Theme.light()
      assert Theme.for_mode(:light) == @light_palette
      assert Theme.for_mode(:dark) == Theme.dark()
    end

    test "dark is a different palette from light" do
      # Guards the degenerate fix where dark mode ships as light mode.
      refute Theme.dark() == Theme.light()

      differing =
        Map.keys(Map.from_struct(Theme.light()))
        |> Enum.filter(&(Map.get(Theme.light(), &1) != Map.get(Theme.dark(), &1)))

      assert length(differing) >= 8,
             "only #{length(differing)} tokens differ between light and dark: " <>
               inspect(differing)
    end

    test "for_mode/1 refuses a mode that is not a mode" do
      # `:auto` is a real choice and deliberately not a mode — which is exactly
      # what makes the literal a type warning here. Built at runtime instead.
      auto = String.to_atom("auto")

      assert auto in Mode.choices(), "the premise: :auto is a choice the app offers"
      assert_raise FunctionClauseError, fn -> Theme.for_mode(auto) end
    end

    test "mode/0 is the resolved mode and current/0 is its palette" do
      assert :ok = Mode.put(:dark)
      assert Theme.mode() == :dark
      assert Theme.current() == Theme.dark()

      assert :ok = Mode.put(:light)
      assert Theme.mode() == :light
      assert Theme.current() == Theme.light()
      assert Theme.current() == @light_palette
    end

    test "current/0 with no stored choice is the device's palette" do
      assert Mob.State.get(@key, :__absent__) == :__absent__
      assert Theme.current() == Theme.for_mode(Mode.device())
    end

    test "activate/0 makes the resolved palette the one Mob renders with" do
      # Mob.Theme.set/1 snapshots; storing a choice alone changes nothing.
      :ok = Mob.Theme.set(Theme.light())
      assert :ok = Mode.put(:dark)

      assert Mob.Theme.current() == @light_palette,
             "put/1 repainted on its own — the docs promise it does not"

      assert :ok = Theme.activate()
      assert Mob.Theme.current() == Theme.dark()

      assert :ok = Mode.put(:light)
      assert Mob.Theme.current() == Theme.dark()

      assert :ok = Theme.activate()
      assert Mob.Theme.current() == @light_palette
    end
  end

  # ── Does a screen still force light? ──────────────────────────────────────

  describe "mounting a screen with :dark stored" do
    setup do
      # Mount the screens with the light palette installed, so "dark is
      # installed afterwards" can only be the mount's own doing and never
      # something left over from a previous test.
      installed = Mob.Theme.current()
      on_exit(fn -> Mob.Theme.set(installed) end)
      :ok = Mode.put(:dark)
      :ok
    end

    # One per macro path, because they are four different pieces of code and a
    # fix to one says nothing about the other three:
    #
    #   * `Kati.Screens.Root`   — the four fixed roots, `mount/3` generated by
    #     the macro
    #   * `Kati.Screens.Pushed` — a screen pushed over a root, a second
    #     generated `mount/3`, and the commonest navigation in the app
    #   * a Persian mirror      — hand-rolled `use Mob.Screen`, its own
    #     `mount/3`, and outside both macros
    #   * a plain `use Mob.Screen` — the same, in English
    #
    # This was the defect: every one of these installed `Kati.Theme.light/0`
    # flat, on every mount, so a stored `:dark` was overwritten within one
    # navigation and dark mode could not exist however correctly the setting
    # was saved.
    @paths [
      {Kati.Screens.Home, "use Kati.Screens.Root", :macro, "screen 01, a fixed root"},
      {Kati.Screens.Settings, "use Kati.Screens.Pushed", :macro, "screen 24, pushed over a root"},
      {Kati.Screens.TodayFa, "use Mob.Screen", :own, "screen 52, a Persian mirror"},
      {Kati.Screens.Search, "use Mob.Screen", :own, "screen 08, a plain use Mob.Screen"}
    ]

    for {module, _use, _mount, why} <- @paths do
      test "#{inspect(module)} (#{why}) installs dark, not light" do
        module = unquote(module)

        Mob.Theme.set(Theme.light())
        assert {:ok, %Mob.Socket{}} = module.mount(%{}, %{}, Mob.Socket.new(module))

        assert Mob.Theme.current() == Theme.dark(),
               "#{inspect(module)} mounted with :dark stored and left " <>
                 if(Mob.Theme.current() == Theme.light(),
                   do: "the LIGHT palette installed — it forces light",
                   else: "a palette that is neither light nor dark"
                 )
      end
    end

    test "the four paths are four different paths" do
      # The table above is only worth something if its rows are not four copies
      # of the same code. A screen that quietly moved onto a different macro
      # would turn this describe block into four tests of one generated
      # `mount/3` and nobody would notice, because all four would still pass.
      #
      # Read off the SOURCE, and it has to be: `__info__(:attributes)` cannot
      # tell the two macros apart. `Kati.Screens.Pushed`'s macro declares
      # `@behaviour Kati.Screens.Root` — the callbacks are shared — so both
      # answer `Kati.Screens.Root` and the distinction that matters here
      # (which `mount/3` runs) is invisible to introspection.
      for {module, use_line, mount, _why} <- @paths do
        source = File.read!(source_path(module))

        assert source =~ use_line,
               "#{inspect(module)} is no longer a `#{use_line}` screen, so it is not the " <>
                 "path this row claims to cover"

        case mount do
          :macro ->
            refute source =~ ~r/^  def mount\(/m,
                   "#{inspect(module)} hand-rolls mount/3 now; the macro's mount is untested here"

          :own ->
            assert source =~ ~r/^  def mount\(/m,
                   "#{inspect(module)} no longer writes its own mount/3, so it duplicates a " <>
                     "macro row above"
        end
      end

      # Four rows, four distinct mount/3 implementations: the Root macro's, the
      # Pushed macro's, and one each in the two hand-rolled screens.
      assert length(@paths) == 4
      assert @paths |> Enum.map(&elem(&1, 0)) |> Enum.uniq() |> length() == 4
    end

    test "no screen in the app forces light — all 63, not just the four above" do
      # The named paths say *which* piece of code was wrong. This says the
      # answer is now universal, and it cannot rot as screens are added: a new
      # screen that hardcodes a palette at mount joins this sweep the moment it
      # compiles.
      screens = Kati.ScreenSweep.screens()

      assert length(screens) > 50,
             "the sweep found #{length(screens)} screens, too few to be reading the app"

      {forced_light, other} =
        Enum.reduce(screens, {[], []}, fn module, {light, other} ->
          Mob.Theme.set(Theme.light())

          case Kati.ScreenSweep.mount(module) do
            {:ok, _socket} ->
              cond do
                Mob.Theme.current() == Theme.dark() -> {light, other}
                Mob.Theme.current() == Theme.light() -> {[module | light], other}
                true -> {light, [module | other]}
              end

            # A screen that cannot mount is Kati.ScreenRenderSweepTest's
            # failure to report, not this one's — repeating it here would bury
            # the answer this test exists to give.
            {:error, _why} ->
              {light, other}
          end
        end)

      assert forced_light == [],
             "these screens mounted with :dark stored and installed the LIGHT palette " <>
               "anyway, so the user's choice is thrown away the moment they navigate:\n" <>
               Enum.map_join(Enum.sort(forced_light), "\n", &("  " <> inspect(&1)))

      assert other == [],
             "these screens installed a palette that is neither Kati's light nor its " <>
               "dark:\n" <> Enum.map_join(Enum.sort(other), "\n", &("  " <> inspect(&1)))
    end
  end

  describe "mounting a screen with :light stored" do
    setup do
      installed = Mob.Theme.current()
      on_exit(fn -> Mob.Theme.set(installed) end)
      :ok = Mode.put(:light)
      :ok
    end

    test "only the screens drawn dark pin dark against the stored choice" do
      # The mirror of the sweep above, and the reason it is not just "no screen
      # may ever name a side". Screens 28 and 29 are drawn dark IN A LIGHT APP
      # — they are the reference for what dark mode looks like — so
      # `Kati.Theme.current/0` would be wrong for them and `Kati.Theme.dark/0`
      # is right. Two, named. A third appearing here is a screen that has
      # picked up the bug this file exists to keep out.
      pinning =
        Enum.filter(Kati.ScreenSweep.screens(), fn module ->
          Mob.Theme.set(Theme.light())

          match?({:ok, _socket}, Kati.ScreenSweep.mount(module)) and
            Mob.Theme.current() == Theme.dark()
        end)

      assert Enum.sort(pinning) == [
               Kati.Screens.AddByHandDark,
               Kati.Screens.BackupDark,
               Kati.Screens.BookDetailDark,
               Kati.Screens.HomeDark,
               Kati.Screens.Lock,
               Kati.Screens.YearShareDark
             ]
    end
  end

  defp source_path(module) do
    file = module |> Module.split() |> List.last() |> Macro.underscore()
    path = Path.expand("../../lib/kati/screens/#{file}.ex", __DIR__)

    assert File.exists?(path), "no source for #{inspect(module)} at #{path}"
    path
  end
end
