defmodule Kati.Theme.Mode do
  @moduledoc """
  The one place that answers **which palette Kati is in** — and who decided.

  Three things can have an opinion about light vs dark, and until this module
  existed only the last of them was ever consulted:

    1. the user, via screen 24's Auto / Light / Dark control,
    2. the device, via Android's night-mode setting,
    3. the screen, via `Mob.Theme.set(Kati.Theme.light())` hardcoded at mount.

  (3) won everywhere, which is why the app has no dark mode even though
  `Kati.Theme.dark/0` has existed the whole time. The resolution order here is
  (1) then (2): an explicit `:light` or `:dark` wins, and `:auto` — the
  default, and what the drawing shows selected — defers to the device.

  ## Where the device answer comes from

  Mob *does* expose it; nothing has to be faked and nothing has to be added to
  the bridge. The chain, verified end to end in this repo:

      Kati.Theme.Mode.device/0
        └─ Mob.Theme.color_scheme/0            deps/mob/lib/mob/theme.ex:236
             └─ :mob_nif.color_scheme/0        deps/mob/src/mob_nif.erl:257
                  └─ MobBridge.getColorScheme/0
                     android/app/src/main/java/com/example/kati/MobBridge.kt:424
                       └─ configuration.uiMode &&& UI_MODE_NIGHT_MASK

  `libkati.so` carries both the class path `com/example/kati/MobBridge` and the
  method name `getColorScheme` in all three shipped ABIs, so the NIF resolves
  the real method rather than falling through to Mob's legacy-app default.

  A flip **while the app is foregrounded** is delivered too: the manifest lists
  `uiMode` in `android:configChanges` (AndroidManifest.xml:96), so the toggle
  reaches `MainActivity.onConfigurationChanged/1` (MainActivity.kt:381) instead
  of recreating the activity, and that forwards through
  `MobBridge.notifyColorSchemeChanged/1` and `beam_jni.c`'s
  `nativeNotifyColorScheme` to `{:mob_device, :color_scheme_changed, scheme}`
  for anything that has called `Mob.Device.subscribe(:appearance)`.

  Kati does not yet subscribe to that. Two notes for whoever wires it:

    * `Mob.Theme.AdaptiveWatcher` looks like the ready-made answer and is not.
      Its guard is `Mob.Theme.current() == module.theme()` — it re-resolves
      only when the active theme *already equals* the freshly resolved one,
      which is exactly the case where nothing needs doing. On a real flip the
      two differ and the event is dropped. Silent, and in `deps/`.
    * The theme is snapshotted into application environment at
      `Mob.Theme.set/1` time and read from there on every render, so a
      re-resolve also needs the visible screen to re-render.

  ## On the host BEAM

  There is no NIF in `mix test`, so `Mob.Theme.color_scheme/0` rescues to
  `:light` and `device/0` is constant. That makes any host test of "Auto
  follows the device" vacuous when written against `resolve/0`, so the
  device answer is a parameter: `resolve/2` is pure and is what the tests
  exercise, and `Kati.ThemeModeTest` separately asserts that `device/0` is
  wired to `Mob.Theme.color_scheme/0` rather than hardcoding a side.

  ## Persistence

  The choice lives in `Mob.State` — a named GenServer over DETS that syncs
  before `put/2` returns — for the same reason `Kati.Locale` does: the screen
  process dies on every root switch, so anything held in assigns is gone the
  moment the setting is used. `Mob.State` must be running; `Mob.State.get/2`
  raises a `:dets` `ArgumentError` against an unopened table rather than
  returning the default, so this module deliberately does not rescue — a
  swallowed error here would read as "user has no preference" forever.
  """

  @key :theme_mode

  @choices [:auto, :light, :dark]
  @default :auto

  @modes [:light, :dark]

  @type choice :: :auto | :light | :dark
  @type mode :: :light | :dark

  @doc """
  Every choice screen 24's Theme control offers, in the order it draws them.

  The control is built from this list rather than from three literals, so a
  segment can never exist with nothing behind it.
  """
  @spec choices() :: [choice()]
  def choices, do: @choices

  @doc "The choice a user who has never touched the control has: Auto."
  @spec default() :: choice()
  def default, do: @default

  @doc """
  The user's stored choice, or `:auto` when they have never made one.

  Anything else on the key — a value from an older build, a hand-edited DETS
  file — reads as `:auto` rather than crashing a mount.
  """
  @spec choice() :: choice()
  def choice do
    case Mob.State.get(@key, @default) do
      c when c in @choices -> c
      _ -> @default
    end
  end

  @doc """
  Record the user's choice. Persisted before this returns.

  This stores the preference; it does **not** repaint. The active palette is a
  snapshot taken by `Mob.Theme.set/1`, so a settings tap wants
  `Kati.Theme.activate/0` after this — otherwise the choice is correct and
  invisible until the next root switch.
  """
  @spec put(choice()) :: :ok
  def put(choice) when choice in @choices do
    Mob.State.put(@key, choice)
    :ok
  end

  @doc """
  What the device says: `:light` or `:dark`.

  `:light` on the host BEAM and on any platform whose bridge does not answer —
  see the module doc for why that fallback is safe here and misleading in a
  test.
  """
  @spec device() :: mode()
  def device do
    case Mob.Theme.color_scheme() do
      :dark -> :dark
      _ -> :light
    end
  end

  @doc """
  The mode Kati is actually in: the stored choice, resolved against the device.

  This is the function screens and `Kati.Theme.current/0` call.
  """
  @spec resolve() :: mode()
  def resolve, do: resolve(choice(), device())

  @doc """
  `resolve/0` with both inputs supplied — the whole decision, as a pure
  function.

      iex> Kati.Theme.Mode.resolve(:auto, :dark)
      :dark
      iex> Kati.Theme.Mode.resolve(:light, :dark)
      :light
  """
  @spec resolve(choice(), mode()) :: mode()
  def resolve(:auto, device) when device in @modes, do: device
  def resolve(:light, device) when device in @modes, do: :light
  def resolve(:dark, device) when device in @modes, do: :dark
end
