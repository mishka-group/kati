defmodule Kati.Theme do
  @moduledoc """
  Kati's design tokens, as a `Mob.Theme`.

  Values are taken literally from the design rather than approximated. Colours
  are raw `0xAARRGGBB` integers — `Mob.Theme` resolves integers straight through
  (`theme.ex:201`), so the palette does not have to be squeezed into Mob's
  named-colour vocabulary.

  Two rules from the design that are easy to lose and hard to get back:

    * **Orange (`#E8823C`) only ever means "new" or "now".** It is not a general
      accent. If something is orange and is neither new nor happening now, that
      is a bug in the screen, not a taste question.
    * **Dark mode is not an inversion.** The elevated-card shadow is replaced by
      an inset hairline, and cream warms rather than darkens. Inverting the light
      palette produces something that is recognisably not Kati.

  There is no shadow token here because `Mob.Theme` has none — its struct carries
  colours, scales, radii and a `glass` flag and nothing else. Elevation is
  therefore Kati's own concern; see #33.
  """

  # ── Light ────────────────────────────────────────────────────────────────
  @paper 0xFFEFECE7
  @card 0xFFFBFAF8
  @ink 0xFF1A1917
  @ink_soft 0xFF5C574F
  @ink_muted 0xFF7C766D
  @accent 0xFFE8823C
  @cream 0xFFFBF1DE
  @green 0xFF4E9A73
  @bronze 0xFFB08E55
  @red 0xFFB4553C
  @hairline_light 0x14000000

  # ── Dark ─────────────────────────────────────────────────────────────────
  @paper_dark 0xFF121110
  @card_dark 0xFF1E1D1B
  @cream_dark 0xFF2A2622
  @ink_on_dark 0xFFF5F2EE
  @muted_dark 0xFF8A857C
  # Replaces the card shadow entirely in dark — inset 0 0 0 1px rgba(245,242,238,.06)
  @hairline_dark 0x0FF5F2EE

  @doc "The light theme — Kati's default surface."
  def light do
    Mob.Theme.build(
      primary: @ink,
      on_primary: @card,
      secondary: @accent,
      on_secondary: @card,
      background: @paper,
      on_background: @ink,
      surface: @card,
      surface_raised: @card,
      on_surface: @ink,
      muted: @ink_muted,
      border: @hairline_light,
      error: @red,
      on_error: @card,
      radius_sm: 2,
      radius_md: 20,
      radius_lg: 22,
      radius_pill: 32,
      glass: false
    )
  end

  @doc """
  The dark theme.

  `glass` stays false: `Mob.Theme`'s own docs say the flag is a **no-op on
  Android**, so switching it on would suggest a translucency that never arrives.
  """
  def dark do
    Mob.Theme.build(
      primary: @ink_on_dark,
      on_primary: @ink,
      secondary: @accent,
      on_secondary: @ink,
      background: @paper_dark,
      on_background: @ink_on_dark,
      surface: @card_dark,
      surface_raised: @card_dark,
      on_surface: @ink_on_dark,
      muted: @muted_dark,
      border: @hairline_dark,
      error: @red,
      on_error: @ink,
      radius_sm: 2,
      radius_md: 20,
      radius_lg: 22,
      radius_pill: 32,
      glass: false
    )
  end

  # ── Raw tokens, for the places a semantic slot does not fit ──────────────

  @doc "Accent. Only ever means new/now."
  def accent, do: @accent
  def cream(:light), do: @cream
  def cream(:dark), do: @cream_dark
  def ink, do: @ink
  def ink_soft, do: @ink_soft
  def card(:light), do: @card
  def card(:dark), do: @card_dark
  def paper(:light), do: @paper
  def paper(:dark), do: @paper_dark
  def green, do: @green
  def bronze, do: @bronze
  def red, do: @red

  @doc """
  The floating chrome fill: the design's `rgba(251,250,248,.9)` as ARGB.

  The design specifies `backdrop-filter: blur(20px)` behind this. Android has no
  backdrop blur through Mob, so per #33 this ships as a flat 0.9-alpha fill over
  the scrim. The intent — chrome that reads as floating and separate — survives;
  the literal effect does not.
  """
  def chrome_fill(:light), do: 0xE6FBFAF8
  def chrome_fill(:dark), do: 0xE61E1D1B

  @doc "Design spacing, in dp. Gutters 21, gaps 9 and 13, bottom inset 132."
  def gutter, do: 21
  def gap_sm, do: 9
  def gap_md, do: 13
  def bottom_inset, do: 132
end
