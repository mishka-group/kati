defmodule Kati.Locale do
  @moduledoc """
  Kati's active locale and its writing direction.

  The locale is an **in-app setting**, not `Locale.getDefault()`. A Persian user
  on an English phone must still get Persian and RTL, and the two must never
  disagree — which is why the direction is derived from this value and passed
  down as a prop rather than read natively at the leaves.

  Stored in `Mob.State` (DETS, SIGKILL-safe) so it survives a restart.
  """

  @locales [:en, :fa]
  @default :en

  @doc "Every locale Kati ships. Machinery supports more; translations do not."
  def supported, do: @locales

  @doc "The active locale."
  @spec current() :: :en | :fa
  def current do
    case Mob.State.get(:locale, @default) do
      l when l in @locales -> l
      _ -> @default
    end
  end

  @doc """
  Set the active locale, and resolve it into the calling process.

  Both halves, for the reason `Kati.Screens.Settings.put_choice/1` gives about
  the theme: storing the preference and snapshotting it are two different
  things, and storing without activating is a correct setting nobody can see
  until the next screen mounts.
  """
  @spec put(:en | :fa) :: :ok
  def put(locale) when locale in @locales do
    Mob.State.put(:locale, locale)
    activate()
  end

  @doc "Writing direction for a locale."
  @spec direction(atom()) :: :ltr | :rtl
  def direction(:fa), do: :rtl
  def direction(_), do: :ltr

  @doc "Writing direction of the active locale, as the string the bridge expects."
  @spec direction_prop() :: String.t()
  def direction_prop do
    case direction(current()) do
      :rtl -> "rtl"
      :ltr -> "ltr"
    end
  end

  @doc """
  The typeface a locale's own text is set in, as the string the bridge expects.

  The twin of `direction_prop/0`, and it travels the same way: on the ROOT node
  of the three shared frames, where `MainActivity` reads it (`K-48
  locale-face-root`) and installs it as the default every `Text` falls back to.

  This is the half a screen cannot reach. A `Text` a screen writes can carry
  `font_family`; a `Text` a **component** builds cannot — `MishkaChip`'s
  `expand/3` discards its children, and `MishkaSegmentedControl` and
  `MishkaNavLink` take their labels as strings — and `MobBridge`'s
  `fontFamilyProp` resolved that missing prop to Plus Jakarta Sans, which
  carries no Arabic-script glyph at all. Android then substitutes its own face,
  so the sentence renders, correctly shaped, in a typeface that is not Kati's.
  `Kati.PersianFontTest`'s moduledoc is where that was first written down, and
  it is why the Persian mirrors adopt so little of `Kati.Components`.

      iex> Kati.Locale.face_for(:fa)
      "fa"

      iex> Kati.Locale.face_for(:en)
      "sans"
  """
  @spec face_for(atom()) :: String.t()
  def face_for(:fa), do: "fa"
  def face_for(_latin), do: "sans"

  @doc """
  The face of the active locale.

  `"sans"` rather than `nil` for English, deliberately: the bridge treats a
  root that names no face as *behave exactly as before*, so passing the name
  makes the English case a decision this app states rather than a default it
  inherits.
  """
  @spec face_prop() :: String.t()
  def face_prop, do: face_for(current())

  @doc "The CLDR locale name for the active locale."
  @spec cldr_name() :: String.t()
  def cldr_name, do: Atom.to_string(current())

  @doc """
  Resolve the stored locale into THIS process, for `Kati.Gettext`.

  The twin of `Kati.Theme.activate/0`, and it sits beside it at every one of
  its call sites for the same reason: `Mob.Theme.set/1` and
  `Gettext.put_locale/2` both snapshot into the calling process, so storing a
  new choice with `put/1` changes nothing on screen by itself. A screen needs
  both, plus a re-render.

  **Process-scoped, deliberately, rather than `Application.put_env/3` on
  `:gettext, :default_locale`.** That would be one global write instead of 52
  paired calls and it is the wrong trade twice over: `Kati.Runtime` is the only
  module in this app allowed to write application environment (its moduledoc
  says why, and a locale is not a runtime config key), and a global default
  would mean a test that renders one screen in `:fa` had changed the locale for
  every other test in the run. `Kati.LocaleActivateTest` is what keeps the
  pairing honest.

  Gettext falls back to the msgid when a locale has no entry, and the msgid is
  the English copy — so a process that never called this draws English rather
  than a missing-translation marker. That is the right failure and also the
  quiet one, which is exactly why the pairing is asserted rather than trusted.
  """
  @spec activate() :: :ok
  def activate do
    Gettext.put_locale(Kati.Gettext, cldr_name())
    :ok
  end
end
