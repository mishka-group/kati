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
end
