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

  @doc """
  The glyph that means **forward** — where the reader is going.

      iex> Kati.Locale.forward_glyph()
      "arrow_forward"

  The twin of `Kati.Screens.Pushed.back_glyph/0`, and it exists for the same
  reason that one does: `layout_direction` mirrors a LAYOUT and cannot mirror
  a picture. An arrow is a picture. Under `rtl` the primary action's glyph has
  to be `arrow_back`, which reads wrong in a diff and right on a phone — the
  three Persian onboarding boards all draw it that way and say so in their
  captions.

  `mishka-group/kati#103`'s fold is what made this shared rather than a
  sentence written twice: `Kati.Screens.OnboardingWelcomeFa.forward/2` was one
  of the two functions a mirror kept for itself.
  """
  @spec forward_glyph() :: String.t()
  def forward_glyph, do: if(direction(current()) == :rtl, do: "arrow_back", else: "arrow_forward")

  @doc """
  The face a mono line takes.

      iex> Kati.Locale.mono_face()
      "mono"

  `kati_mono.ttf` carries **no** Persian glyph, so a Persian sentence set in
  `mono` is handed to Android's own substitute face — it renders, in a typeface
  that is not Kati's, beside sentences that are. `Kati.Screens.Fa` states the
  rule and `Kati.PersianFontTest` keeps it: Persian mono copy is Vazirmatn at
  the mono size.

  A NUMBER in mono is a different question and keeps its face — see
  `number/1`.
  """
  @spec mono_face() :: String.t()
  def mono_face, do: pick("mono", "fa")

  @doc """
  A number in the reader's own digits.

      iex> Kati.Locale.number(190)
      "190"

  `Kati.I18n.Digits.to_persian/1` under `:fa` and `Integer.to_string/1`
  otherwise. Every mirror reached for the first of those by hand — screen 301's
  `جست‌وجو در ۱۹۰ کشور` is one of seventeen — and a folded screen has one place
  to ask instead.

  **Not every number is this one.** A figure the design sets in DM Mono keeps
  Latin digits in both scripts, because `kati_mono.ttf` carries none of
  U+06F0–U+06F9; `Kati.Screens.Fa` states that rule and `Kati.PersianFontTest`
  keeps it. This is for the numerals inside a sentence.
  """
  @spec number(integer() | String.t()) :: String.t()
  def number(value) do
    text = to_string(value)
    if direction(current()) == :rtl, do: Kati.I18n.Digits.to_persian(text), else: text
  end

  @doc """
  One of two values, by writing direction.

      iex> Kati.Locale.pick(13.5, 14)
      13.5

  The general form of `tracking/1` and `leading/1`, for the places a drawing
  and its mirror differ by a number rather than by a word — a type size, a
  gap, a glyph. Both values stay at the call site, which is the point: a
  Persian screen that differs by 0.5pt should say so where it differs, not in a
  second module.
  """
  @spec pick(term(), term()) :: term()
  def pick(latin, persian), do: if(direction(current()) == :rtl, do: persian, else: latin)

  @doc """
  The glyph that means **back** — where the reader came from.

      iex> Kati.Locale.back_glyph()
      "arrow_back"

  The plain arrow, and the exact inversion of `forward_glyph/0`.
  `Kati.Screens.Pushed.back_glyph/0` is the other one and stays separate: it is
  the `_ios` chevron the floating pill draws, and a sequence that steps back
  through itself is not a stack being popped — the boards draw the difference.
  """
  @spec back_glyph() :: String.t()
  def back_glyph, do: if(direction(current()) == :rtl, do: "arrow_forward", else: "arrow_back")

  @doc """
  Latin tracking, or none.

      iex> Kati.Locale.tracking(-0.03)
      -0.03

  The design tightens its 28pt headings by a fraction of an em. Arabic script
  has no such tradition and Vazirmatn is not drawn for it — the mirrors all
  dropped `letter_spacing` rather than mirroring it, and
  `Kati.Screens.AddByHand.labelled/4` already carries the long version of the
  argument for the eyebrow labels.
  """
  @spec tracking(number()) :: number()
  def tracking(latin), do: if(direction(current()) == :rtl, do: 0, else: latin)

  @doc """
  A paragraph's line height: the design's own, or Persian's.

      iex> Kati.Locale.leading(1.55)
      1.55

  `Kati.Theme.fa_line_height/0` is the constant and its doc is where the
  reasoning lives — Vazirmatn's metrics are not Plus Jakarta's, so a fixed-height
  row measured against the Latin screen breaks on its Persian twin. This is that
  constant applied per paragraph, with the Latin value as the argument so both
  numbers stay visible at the call site.
  """
  @spec leading(number()) :: number()
  def leading(latin), do: if(direction(current()) == :rtl, do: 1.95, else: latin)

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
