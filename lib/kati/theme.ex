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

  # ── Type ─────────────────────────────────────────────────────────────────
  @fa_line_height 1.2

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
  The floating chrome fill: the design's `rgba(251,250,248,.9)` **plus the blur
  it assumes**, resolved into one flat alpha.

  The design pairs that .9 with `backdrop-filter: blur(20px)`, and Mob has no
  backdrop blur — `Modifier.blur` blurs a composable's OWN content, not what is
  behind it, and a real backdrop blur needs a RenderEffect over a snapshot of
  the layer underneath. #33 recorded that and shipped the drawn .9 flat.

  Shipping the drawn alpha turned out to be the wrong half to keep. Behind the
  blur, .9 white sits over an unreadable smear and the bar reads as solid
  chrome; without it, .9 over SHARP text lets you read the words straight
  through the dock — screen 01's capture shows "Meals", "Habits" and "Settings"
  legible through the bar. Matching the number produced a bar the design does
  not have.

  So this matches the RESULT instead: 0.97, which is what .9-over-blur looks
  like. The declaration is recorded above; if the bridge ever grows a backdrop
  blur, this goes back to 0xE6 in the same commit that adds it.
  """
  def chrome_fill(:light), do: 0xF7FBFAF8
  def chrome_fill(:dark), do: 0xF71E1D1B

  @doc """
  The line-height multiplier Persian text needs in order to match Latin.

  `line_height` is a **multiplier of `text_size`**, not a dp value — the bridge
  computes `line_height * text_size` (`MobBridge.kt:2737`). It is also ignored
  unless `text_size` is set on the same `Text`, so a Persian `Text` that leans
  on the default size gets no line height at all and nothing on screen says so.

  Nothing sets a default for either font, so with `line_height` unset each one
  falls back to its own metrics — and Vazirmatn's are not Plus Jakarta's. An
  `fa` `Text` and a `sans` `Text` at the same `text_size` therefore do not
  produce the same line box, which is why a fixed-height `Row` measured against
  the Latin screen breaks on its Persian twin: nothing in the markup changed,
  only the font, and the row is suddenly the wrong height.

  1.2 is a **declared** number, not a measured one. No geometry comes back from
  `render/1`, so nothing on this side can verify it — it has to be looked at on
  the device. When it is wrong it is wrong in one place rather than in every
  `fa` `Text` in the app, which is the whole reason it is a constant.

  There is no per-font default to hook into, so `fa` screens apply it
  explicitly:

      <Text text={title} font_family="fa" text_size={17}
            line_height={Kati.Theme.fa_line_height()} />

  A drawing that specifies its own Persian line height still wins — pass that
  value instead. This is the default for the far more common case where the
  drawing says nothing at all.
  """
  def fa_line_height, do: @fa_line_height

  @doc "Design spacing, in dp. Gutters 21, gaps 9 and 13, bottom inset 132."
  def gutter, do: 21
  def gap_sm, do: 9
  def gap_md, do: 13
  def bottom_inset, do: 132

  @doc """
  The design's shadow recipes, in the `shadow` prop's CSS-like format:
  `dx dy blur spread #AARRGGBB`, layers separated by `|`.

  `card/0` is the one used 262 times. Its second layer's **-18 spread** is what
  makes it read as lifted off warm paper rather than outlined, and it is
  exactly what `Modifier.shadow` cannot express.
  """
  def shadow_card, do: "0 1 2 0 #0A1A1917 | 0 12 24 -18 #991A1917"
  def shadow_card_soft, do: "0 1 2 0 #0A1A1917 | 0 12 24 -18 #B31A1917"
  def shadow_button, do: "0 1 2 0 #0D1A1917 | 0 8 16 -12 #801A1917"
  def shadow_search, do: "0 1 2 0 #0A1A1917 | 0 8 18 -14 #801A1917"
  def shadow_hero, do: "0 1 2 0 #0A1A1917 | 0 14 28 -20 #80785018"
  def shadow_poster, do: "0 4 10 -4 #73503714"
  def shadow_dock, do: "0 1 2 0 #0D1A1917 | 0 14 30 -16 #B31A1917"
end
