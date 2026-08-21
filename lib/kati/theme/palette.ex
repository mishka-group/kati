defmodule Kati.Theme.Palette do
  @moduledoc """
  Every colour the screens write as a raw hex literal, given a name and a
  second value for dark.

  `Kati.Theme` carries one slot per `Mob.Theme` role — `:background`,
  `:surface`, `:on_surface`, `:muted`, `:border` — and that is thirteen
  colours. The screens need ninety-three. So ninety-three ARGB literals are
  typed straight into the markup, `0xFFA9A29A` at a time, and switching
  `Mob.Theme` from `light/0` to `dark/0` would not move a single one of them.
  That is the whole reason there is no dark mode: not that the dark palette is
  missing (it exists, in `Kati.Theme.dark/0`), but that the screens never ask
  it anything.

  This module is the missing question. Each literal gets a name, its exact
  light value, and a dark value.

  ## The rule this module exists under

  **Light mode must not change by a single pixel.** The 62 frames in
  `.scratch/design/audit_v7/` are the baseline. So every token resolves, in
  light, to *exactly* the literal it replaces — no rounding, no "close
  enough", no tidying of a value that looks like a typo. `Palette.muted()` is
  `0xFFA9A29A` and will be until the drawing changes. The test writes out all
  87 light values by hand — a second, independent copy — and asserts them one
  at a time, so a change to the table here fails there and the failure names
  the token.

  Eighty-seven tokens rather than ninety-three literals, because five literals
  do more than one job; see *One literal, several meanings* below. Every one of
  the ninety-three is still reachable, and the test proves it against the files
  on disk rather than against a number typed into it.

  ## Where the dark values come from

  Four kinds of source under nine labels, and every token says which one it
  used. Nothing here is invented and then presented as the design's.

    * `:drawn` — screens 28 (Home, dark) and 29 (Lock) are the only dark
      drawings that exist, and 28 is *the same page as screen 01*. Laid side by
      side, `Kati.Screens.Home` and `Kati.Screens.HomeDark` give the dark twin
      of a light literal role for role: the date line is `#A9A29A` on 01 and
      `#6A6560` on 28, the row meta is `#8A8479` and `#8A837B`, the timeline
      rail is `#C4BDB3` and `#4A453F`. Nineteen tokens are settled this way,
      and they are the anchors everything else is measured against. The light
      dock in `Kati.Screens.Fa` against the dark dock in `Kati.Screens.HomeDark`
      settles five more — twenty-four `:drawn` in all.

    * `:theme` — the value is already in `Kati.Theme`'s dark palette
      (`@paper_dark`, `@card_dark`, `@cream_dark`, `@ink_on_dark`,
      `@hairline_dark`), or `Kati.Theme.dark/0` deliberately keeps the light
      one (`secondary: @accent`, `error: @red`).

    * `:hue` / `:media` — deliberately identical in both modes. `:hue` is a
      colour that means something by being that colour: orange is new/now,
      green is done, red is destructive. Screen 28 keeps `#E8823C` at full
      strength on near-black, so hues do not shift. `:media` is a colour whose
      ground is a **photograph**, not a themed surface — the lock screen's
      white-on-wallpaper family, and text burnt over artwork. A photograph does
      not get lighter when the app does.

    * `:alpha`, `:ramp`, `:recession`, `:inversion`, `:step` — **derived**, by
      the five rules below. These are the ones the design does not answer, and
      calling them anything else would be a lie. Thirty-four tokens.

  The tally is `:drawn` 24, `:theme` 3, `:hue` 11, `:media` 15, `:alpha` 18,
  `:ramp` 10, `:recession` 1, `:inversion` 3, `:step` 2 — and the test asserts
  it, so this paragraph cannot quietly stop being true.

  ## The five derivations, stated

  **`:alpha` — a tint keeps its alpha and changes its base.** The design writes
  its rules and borders as ink at an alpha: `0x121A1917` is `rgba(26,25,23,.07)`.
  Screen 28 draws the same rule as `0x12F5F2EE` — identical alpha, ink swapped
  for ink-on-dark — and `Kati.Theme`'s `@hairline_dark` (`0x0FF5F2EE`) is built
  the same way. So `0xAA1A1917` becomes `0xAAF5F2EE`, alpha untouched. Drawn
  once, applied to the other nine ink tints.

  **`:ramp` — a neutral with no drawn twin is placed between two that have
  one.** The drawn pairs form a ladder: `#1A1917`→`#F5F2EE`, `#8A8479`→`#8A837B`,
  `#A9A29A`→`#6A6560`, `#B3ACA2`→`#6A6560`, `#C4BDB3`→`#4A453F`,
  `#EFECE7`→`#121110`. A light neutral is located on that ladder by relative
  luminance (WCAG) and takes the corresponding point between the two dark
  values that bracket it. Every ramp value therefore lies *between two colours
  the design drew*; none is extrapolated past the ends.

  Inert fills — `track_off`, `bar_neutral`, `star_empty` — are placed on the
  drawing's two inert fills instead (`#E7E3DC`→`#312F2C` and
  `#C4BDB3`→`#4A453F`) rather than on the text ladder, because a track and a
  glyph at the same lightness on paper are not the same thing on near-black.
  Mixing them was the first attempt and it put the empty star four units off
  the card, where it would not have been visible at all.

  It is worth saying what this rule reveals: four light steps (`#9C958B`,
  `#A0998F`, `#A9A29A`, `#B3ACA2`) collapse onto values within a few units of
  `#6A6560`, because the dark drawing simply has fewer neutral steps than the
  light one. That is the drawing's decision, not a loss in translation.

  **`:recession` — a ground that sinks toward the page sinks by the same
  fraction.** `#F4F1EC` is the settled/done card: 64% of the way from the card
  to the page. Applying 64% to `#1E1D1B`→`#121110` gives `#161514`.

  **`:inversion` — a control that is ink-filled in light is paper-filled in
  dark.** Screen 28 proves it: the hero's Open-inbox pill is `#1A1917` filled
  with `#FBFAF8` text on 01, and `#F7EFE4` filled with `#1A1917` text on 28.
  So anything sitting *on* that fill swaps sides of the ramp, at the contrast
  ratio it had against the fill it was on. Solving for equal contrast gives
  `#473F36` and `#706A62`, both within four units of colours the design already
  uses — `#4A4238` and `#6E6860` — so the tokens take the design's values
  rather than the computed ones. Landing that close is the check on the rule;
  taking the drawn value is the rule about whose number wins.

  **`:step` — a shaded hue unshades on a dark ground.** `#3E8460` is `#4E9A73`
  darkened so green text reads on a 16% green wash over paper. Over near-black
  the shading is backwards, so the token takes the undarkened hue. Same for
  `#96723C`, which is `#C98A3E` darkened.

  ## One literal, several meanings — which is the whole point

  Five light literals carry more than one meaning, and they are the reason a
  find-and-replace over the screens would have produced a broken dark mode
  rather than a dark mode:

    * `0xFFFBFAF8` is the **card**, a **label on an ink fill**, the **plus
      inside the FAB**, and a **title burnt over artwork**. In dark those go
      four different ways — `#1E1D1B`, `#1A1917`, `#16150F`, and unchanged.
    * `0xFF1A1917` is **ink**, the **CTA pill's fill**, the **headline on
      cream**, and the **FAB's fill**. Dark: `#F5F2EE`, `#F7EFE4`, `#F7EFE4`,
      `#F5F2EE`.
    * `0xFFEFECE7` is the **page** and the **disc behind the active tab**. In
      dark the page is `#121110` and the disc is `#0E0D0C` — *darker* than the
      page, so it reads as a hole rather than a highlight.
    * `0x00FFFFFF` is **nothing drawn**, and also the light form of both
      hairlines dark adds.
    * `0x99FFFFFF` is a **chip raised off the cream card** and a **lock-screen
      widget's mono meta**. One follows the theme; the other sits on a
      photograph and does not.

  Two pairs are identical in *both* modes and are still two tokens, because a
  call site reading `Palette.fab_fill()` says something `Palette.ink()` does
  not: `ink`/`fab_fill`, and `ink_fill`/`cream_ink`. The second pair being
  equal is the drawing's own idea — screen 28's CTA pill is the cream
  headline made solid.

  Collisions in the *dark* column are commoner, and they are the ramp rule
  showing its work: the dark drawing has fewer neutral steps than the light
  one, so several light steps land on `#6A6560`. `collisions/0` and `twins/0`
  compute both lists; the test pins them, so a *new* collision — the kind that
  means two tokens were accidentally given one meaning — fails.

  ## What this module deliberately does not do

  It does not touch `Kati.Theme`, and it does not know about shadows. Dark
  replaces the light card's shadow with an inset hairline — `card_hairline/0`
  is that hairline — but the shadow itself is `Kati.Theme.shadow_card/0`'s
  business.

  > #### The border that is not there {: .warning}
  >
  > `card_hairline/0` is **fully transparent in light**, because a light card
  > lifts with a shadow and draws no border at all. Alpha 0 is not the same as
  > absent: Compose draws a border *inward*, so a `Box` with `border_width={1}`
  > and a transparent `border_color` still loses a device pixel of content box
  > on all four sides. Passing an invisible border in light mode moves the
  > frame. A screen must omit `border_width` entirely when the mode is light —
  > not pass it with a see-through colour. Same for `cream_hairline/0`.

  ## Reading the mode

      Palette.card()          # resolves by the current mode
      Palette.card(:light)    # always 0xFFFBFAF8
      Palette.card(:dark)     # always 0xFF1E1D1B

  **This module stores no mode of its own.** `mode/0` reads the theme
  `Mob.Theme` is already carrying and answers `:dark` only when that theme is
  Kati's dark one. There is deliberately no `put_mode/1` to go out of step with
  `Mob.Theme.set/1`: two switches for one thing is how a screen ends up with
  dark tokens on a light `:background`, and nothing on this side would say so.

  It also keeps `Kati.Runtime`'s rule intact — it is the only module in `lib/`
  that writes application environment, and a colour table is not boot
  configuration.

  Changing mode is therefore one call:

      Mob.Theme.set(Kati.Theme.dark())

  `mode/0` answers `:light` for anything that is not positively Kati's dark
  theme — including Mob's own neutral base, which is a dark grey and is not
  this app's dark mode. That is the safe direction: with today's 23 hardcoded
  `Mob.Theme.set(Kati.Theme.light())` calls still in place, every zero-arity
  token returns its light literal and the 62 frames cannot move.

  Screen 24's Auto / Light / Dark control is a *preference*, and a preference
  is something to persist and then apply — the applying is the `set/1` above.
  Where the preference lives is the settings domain's business, not a colour
  table's.
  """

  # ── The table ────────────────────────────────────────────────────────────
  #
  # {name, light, dark, source, meaning}
  #
  # `light` is the literal, exactly. `source` is where `dark` came from, and
  # is enforced by the test to be one of @sources.

  @tokens [
    # ── Surfaces ─────────────────────────────────────────────────────────
    {:paper, 0xFFEFECE7, 0xFF121110, :drawn,
     "The page behind everything, and the ground every contrast is measured against."},
    {:card, 0xFFFBFAF8, 0xFF1E1D1B, :drawn,
     "A card lifted off the page — by a shadow in light, by a hairline in dark."},
    {:card_settled, 0xFFF4F1EC, 0xFF161514, :recession,
     "A card whose row is done or past — sunk back toward the page."},
    {:cream, 0xFFFBF1DE, 0xFF2A2622, :drawn,
     "The warm card. Dark warms it to a lit-lamp brown rather than darkening it."},
    {:placeholder, 0xFFE4E0D9, 0xFF2A2826, :drawn,
     "The grey standing in for an image, and the trough a segmented control sits in — the design uses one value for both."},
    {:poster_on_cream, 0xFFEADFC6, 0xFF3A342D, :drawn,
     "An image placeholder sitting ON the cream card, warmer than the plain one."},
    {:track, 0xFFE7E3DC, 0xFF312F2C, :drawn, "The unfilled part of a progress bar or meter."},
    {:track_off, 0xFFDCD7CF, 0xFF3A3732, :ramp,
     "A switch's off track; a step in a dotline not yet reached."},
    {:bar_neutral, 0xFFD8D2C8, 0xFF3D3935, :ramp,
     "A bar in a chart that is not the highlighted one."},
    {:star_empty, 0xFFE0DAD1, 0xFF2A2826, :ramp,
     "An unfilled star in a rating — the faintest mark the design draws."},

    # ── Ink and neutral marks ────────────────────────────────────────────
    {:ink, 0xFF1A1917, 0xFFF5F2EE, :drawn,
     "Headline and title ink, the strongest thing on the page."},
    {:ink_soft, 0xFF5C574F, 0xFFCBC7C1, :ramp,
     "Body copy — one step below ink, for text meant to be read rather than scanned."},
    {:meta, 0xFF6E6860, 0xFFB6B1AB, :ramp, "The mono meta line under a detail-screen title."},
    {:bar_ink, 0xFF7C766D, 0xFFA29C94, :ramp, "A neutral bar carrying a value, not a category."},
    {:sub, 0xFF8A8479, 0xFF8A837B, :drawn, "The second line under a row's title."},
    {:settled_ink, 0xFF9C958B, 0xFF79736D, :ramp,
     "The title of a row already done or already watched."},
    {:eyebrow, 0xFFA0998F, 0xFF746F69, :ramp, "The mono section label after the accent dash."},
    {:muted, 0xFFA9A29A, 0xFF6A6560, :drawn,
     "Mono meta, field placeholders, times. The design's own `muted`."},
    {:segment_idle, 0xFFAFA89E, 0xFF6A6560, :ramp, "The unselected half of a segmented control."},
    {:tertiary, 0xFFB3ACA2, 0xFF6A6560, :drawn,
     "A faint chevron, an idle tab glyph — a mark that is present but not addressed."},
    {:rail_idle, 0xFFC4BDB3, 0xFF4A453F, :drawn,
     "The 3pt rail beside a timeline row that is not now."},

    # ── On an ink-filled control (which inverts in dark) ──────────────────
    {:on_ink, 0xFFFBFAF8, 0xFF1A1917, :drawn,
     "A label on an ink fill, which inverts with the mode rather than following it."},
    {:on_ink_glyph, 0xFFF5F2EE, 0xFF1A1917, :inversion,
     "A glyph on an ink card, where the ground is already inverted."},
    {:on_ink_muted, 0xFFBFB8AC, 0xFF4A4238, :inversion,
     "The muted step on an ink fill — a day name under its date, say."},
    {:on_ink_meta, 0xFF8A837B, 0xFF6E6860, :inversion, "The mono meta step on an ink fill."},
    {:on_ink_count, 0x99FBFAF8, 0x991A1917, :alpha,
     "A count inside a selected, ink-filled chip."},
    {:on_ink_count_soft, 0xA6FBFAF8, 0xA61A1917, :alpha,
     "The same count, one screen's softer alpha."},
    {:on_ink_veil, 0x1FF5F2EE, 0x1F1A1917, :alpha, "A lighter patch laid ON an ink card."},
    {:on_ink_track, 0x26F5F2EE, 0x261A1917, :alpha, "A progress track ON an ink card."},
    {:count_idle, 0x995C574F, 0x99CBC7C1, :alpha, "The unselected twin of `on_ink_count`."},
    {:count_idle_soft, 0xA65C574F, 0xA6CBC7C1, :alpha,
     "The unselected twin of `on_ink_count_soft`."},
    {:count_idle_faint, 0x8C5C574F, 0x8CCBC7C1, :alpha,
     "The faintest unselected count, on the screen that draws it lightest."},
    {:ink_fill, 0xFF1A1917, 0xFFF7EFE4, :drawn, "The fill of the hero's call-to-action pill."},

    # ── Cream ────────────────────────────────────────────────────────────
    {:cream_ink, 0xFF1A1917, 0xFFF7EFE4, :drawn,
     "The headline on a cream card. Screen 28 makes the CTA pill this same colour."},
    {:cream_body, 0xFF4A4238, 0xFFE4DBCE, :ramp,
     "A note paragraph on cream — the longest text the design sets on a warm ground."},
    {:cream_sub, 0xFF8A7B60, 0xFFA89B87, :drawn, "The second line on a cream card."},
    {:cream_meta, 0xFFB09A72, 0xFF7A6F5E, :drawn, "The mono meta line on a cream card."},
    {:cream_rule, 0x4DB09A72, 0x4D7A6F5E, :alpha, "The hairline inside a cream card."},
    {:cream_raise, 0x99FFFFFF, 0xFF3A342D, :drawn,
     "A chip or patch lifted a step off the cream card."},
    {:cream_hairline, 0x00FFFFFF, 0x24E8823C, :drawn,
     "The orange ring dark draws around the cream card instead of the shadow light gives it. Invisible in light — see the warning in the moduledoc."},
    {:gold_icon, 0xFFC98A3E, 0xFFC98A3E, :hue,
     "A gold glyph on cream — the note/annotation hue."},
    {:gold_label, 0xFFC08A4C, 0xFFC08A4C, :hue,
     "A gold mono label — a clash count, a warning line above a row."},
    {:gold_text, 0xFF96723C, 0xFFC98A3E, :step,
     "Gold text on a wash — shaded for paper, unshaded for near-black."},
    {:bar_gold, 0xFFE4D2B0, 0xFFE4D2B0, :hue, "A pale gold bar in a nutrition chart."},

    # ── State hues ───────────────────────────────────────────────────────
    {:accent, 0xFFE8823C, 0xFFE8823C, :drawn,
     "Orange. Only ever means new or now. Screen 28 keeps it at full strength on near-black."},
    {:accent_wash, 0x2EE8823C, 0x2EE8823C, :hue,
     "An 18% orange wash behind a highlighted token."},
    {:accent_fill, 0x47E8823C, 0x47E8823C, :hue,
     "A stronger orange fill behind a matched search run."},
    {:green, 0xFF4E9A73, 0xFF4E9A73, :hue,
     "Done, ticked, live. A hue, so it does not move with the ground."},
    {:green_wash, 0x294E9A73, 0x294E9A73, :hue, "The ground of a live status pill."},
    {:green_text, 0xFF3E8460, 0xFF4E9A73, :step,
     "Green text on the green wash — shaded for paper, unshaded for near-black."},
    {:red, 0xFFB4553C, 0xFFB4553C, :theme,
     "Destructive, stale, over. `Kati.Theme.dark/0` keeps `error: @red`."},
    {:red_wash, 0x1AB4553C, 0x1AB4553C, :hue, "A 10% red ground behind a destructive glyph."},
    {:red_wash_strong, 0x24B4553C, 0x24B4553C, :hue, "The ground of a stale status pill."},
    {:red_ring, 0x4DB4553C, 0x4DB4553C, :hue, "The ring around a destructive control."},
    {:bronze, 0xFFB08E55, 0xFFB08E55, :theme,
     "Meals, money. `Kati.Theme.bronze/0` takes no mode."},

    # ── Ink tints: rules, borders, tracks ─────────────────────────────────
    {:hairline, 0x121A1917, 0x12F5F2EE, :drawn,
     "The 7% rule between two rows. The one alpha-swap the design draws itself."},
    {:hairline_soft, 0x141A1917, 0x14F5F2EE, :alpha, "An 8% rule between grouped rows."},
    {:hairline_strong, 0x1A1A1917, 0x1AF5F2EE, :alpha,
     "A 10% rule where a group needs more separation."},
    {:border_soft, 0x241A1917, 0x24F5F2EE, :alpha,
     "A 14% outline, the lightest border the design draws."},
    {:border, 0x291A1917, 0x29F5F2EE, :alpha, "The 16% outline on an outlined control."},
    {:border_strong, 0x2E1A1917, 0x2EF5F2EE, :alpha,
     "An 18% outline, on a control that needs to read as pressable."},
    {:border_stronger, 0x331A1917, 0x33F5F2EE, :alpha, "A 20% outline on a small subtle disc."},
    {:track_ink, 0x381A1917, 0x38F5F2EE, :alpha,
     "A 22% ink track, used where a card is already pale."},
    {:divider_heavy, 0x591A1917, 0x59F5F2EE, :alpha,
     "A 35% vertical divider between two numbers."},
    {:ink_invisible, 0x001A1917, 0x00F5F2EE, :alpha,
     "A glyph drawn at zero alpha to hold a slot the layout needs. Nothing renders in either mode."},
    {:card_hairline, 0x00FFFFFF, 0x0FF5F2EE, :theme,
     "What dark uses instead of the card's shadow — `Kati.Theme`'s `@hairline_dark`, drawn on screen 28 as `inset 0 0 0 1px rgba(245,242,238,.06)`. Invisible in light — see the warning in the moduledoc."},

    # ── Chrome ───────────────────────────────────────────────────────────
    {:dock_fill, 0xE6FBFAF8, 0xEB1E1D1B, :drawn,
     "The floating dock. The alpha changes with the mode — .90 light, .92 dark — and both numbers are drawn."},
    {:chrome_disc, 0xD1FBFAF8, 0xD11E1D1B, :alpha, "A floating chrome disc over artwork."},
    {:tab_well, 0xFFEFECE7, 0xFF0E0D0C, :drawn,
     "The disc behind the active tab. In dark it is DARKER than the page, so it reads as a hole punched through the bar rather than a highlight on it."},
    {:fab_fill, 0xFF1A1917, 0xFFF5F2EE, :drawn,
     "The add button beside the dock — ink on paper, and paper on ink in dark."},
    {:fab_glyph, 0xFFFBFAF8, 0xFF16150F, :drawn,
     "The plus inside it — a deeper ink than `on_ink`, because it sits on the brightest thing on a near-black page."},
    {:transparent, 0x00FFFFFF, 0x00FFFFFF, :hue,
     "Nothing drawn, in either mode. An explicit absence rather than an omission."},

    # ── Over a photograph ────────────────────────────────────────────────
    {:on_media, 0xFFFBFAF8, 0xFFFBFAF8, :media,
     "A title burnt over artwork, where the ground is a photograph."},
    {:on_media_meta, 0xBFFBFAF8, 0xBFFBFAF8, :media,
     "Mono meta burnt over artwork, at 75% so the picture still reads through."},
    {:on_media_track, 0x40FBFAF8, 0x40FBFAF8, :media,
     "A progress track burnt into the bottom edge of artwork."},
    {:on_media_ghost, 0x66F4F1EC, 0x66F4F1EC, :media, "A poster placeholder over artwork."},
    {:lock_ink, 0xFFFFFFFF, 0xFFFFFFFF, :media, "The lock screen clock and widget titles."},
    {:lock_ink_85, 0xD9FFFFFF, 0xD9FFFFFF, :media, "The lock screen date line."},
    {:lock_ink_65, 0xA6FFFFFF, 0xA6FFFFFF, :media,
     "A lock-screen widget's second line, at 65% over the wallpaper."},
    {:lock_ink_60, 0x99FFFFFF, 0x99FFFFFF, :media,
     "A lock-screen widget's mono meta line, at 60% over the wallpaper."},
    {:lock_ink_55, 0x8CFFFFFF, 0x8CFFFFFF, :media,
     "A lock-screen widget's eyebrow — mono, letter-spaced, half-alpha, no accent dash."},
    {:lock_ink_50, 0x80FFFFFF, 0x80FFFFFF, :media,
     "A lock-screen widget's smallest mono figure, at the edge of legible."},
    {:lock_ink_40, 0x66FFFFFF, 0x66FFFFFF, :media,
     "The rail beside a lock-screen row that is not now."},
    {:lock_ink_15, 0x26FFFFFF, 0x26FFFFFF, :media, "A poster placeholder inside a lock widget."},
    {:lock_hairline, 0x24FFFFFF, 0x24FFFFFF, :media, "The 14% ring around a glass panel."},
    {:lock_glass, 0x801C1A18, 0x801C1A18, :media,
     "The glass panel itself, half-alpha over the wallpaper."},
    {:lock_ground, 0xFF1C1A18, 0xFF1C1A18, :media,
     "What stands in for the wallpaper when there is no image."}
  ]

  @sources [:drawn, :theme, :hue, :media, :alpha, :ramp, :recession, :inversion, :step]
  @derived [:alpha, :ramp, :recession, :inversion, :step]

  @modes [:light, :dark]

  # The page colour in dark, used to infer the mode from the active theme.
  # Stated here rather than read from `Kati.Theme` so this module owns its own
  # answer; `theme_agrees?/0` is the cross-check that they have not drifted.
  @dark_paper 0xFF121110

  @doc """
  The whole table, as a list of maps.

  Each entry carries `:name`, `:light`, `:dark`, `:source` and `:meaning`.
  """
  @spec tokens() :: [
          %{
            name: atom(),
            light: pos_integer(),
            dark: pos_integer(),
            source: atom(),
            meaning: String.t()
          }
        ]
  def tokens do
    Enum.map(@tokens, fn {name, light, dark, source, meaning} ->
      %{name: name, light: light, dark: dark, source: source, meaning: meaning}
    end)
  end

  @doc "Every token name, in table order."
  @spec names() :: [atom()]
  def names, do: Enum.map(@tokens, fn {name, _, _, _, _} -> name end)

  @doc """
  How many tokens there are.

  Asserted in the test. A table that silently resolves to nothing is the
  failure mode this repo has already been bitten by, and a count is what
  catches it.
  """
  @spec count() :: pos_integer()
  def count, do: length(@tokens)

  @doc "The sources a token's dark value may claim."
  @spec sources() :: [atom()]
  def sources, do: @sources

  @doc "The sources that mean *derived, not drawn*."
  @spec derived_sources() :: [atom()]
  def derived_sources, do: @derived

  @doc """
  Every colour this table can produce, both modes, as a set.

  The point of it: the test asserts that this set contains all ninety-three
  literals the screens actually write, so a token nobody uses cannot pad the
  table and a literal nobody named cannot slip through.
  """
  @spec literals() :: MapSet.t(pos_integer())
  def literals do
    Enum.reduce(@tokens, MapSet.new(), fn {_, light, dark, _, _}, acc ->
      acc |> MapSet.put(light) |> MapSet.put(dark)
    end)
  end

  @doc """
  Every value that more than one token resolves to, in each mode.

  Returns `%{light: %{value => [name]}, dark: %{value => [name]}}`. The test
  pins both maps: a collision that is *meant* is listed there with its reason,
  and any other one is a bug.
  """
  @spec collisions() :: %{light: %{pos_integer() => [atom()]}, dark: %{pos_integer() => [atom()]}}
  def collisions do
    %{light: collisions_on(:light), dark: collisions_on(:dark)}
  end

  defp collisions_on(mode) do
    tokens()
    |> Enum.group_by(&Map.fetch!(&1, mode), & &1.name)
    |> Enum.filter(fn {_value, names} -> length(names) > 1 end)
    |> Map.new(fn {value, names} -> {value, Enum.sort(names)} end)
  end

  @doc """
  Tokens that are identical in *both* modes — same light value, same dark
  value, different name.

  Kept apart on purpose; see the moduledoc. Anything not on the pinned list is
  a token that should have been one token.
  """
  @spec twins() :: [[atom()]]
  def twins do
    tokens()
    |> Enum.group_by(&{&1.light, &1.dark}, & &1.name)
    |> Enum.filter(fn {_pair, names} -> length(names) > 1 end)
    |> Enum.map(fn {_pair, names} -> Enum.sort(names) end)
    |> Enum.sort()
  end

  # ── Mode ──────────────────────────────────────────────────────────────────

  @doc """
  The mode every zero-arity token resolves through.

  Read from the theme `Mob.Theme` is already carrying — this module stores
  nothing of its own. `:dark` only when that theme's `:background` is Kati's
  dark page; `:light` for everything else, Mob's own neutral base included.

  To change it: `Mob.Theme.set(Kati.Theme.dark())`.
  """
  @spec mode() :: :light | :dark
  def mode do
    case Mob.Theme.current() do
      %{background: @dark_paper} -> :dark
      _ -> :light
    end
  end

  @doc """
  Whether `Kati.Theme.dark/0`'s background still matches what `mode/0` looks
  for.

  `mode/0` recognises dark by comparing the active theme's background against
  this module's own `paper` dark value. If `Kati.Theme.dark/0` ever moves its
  page colour, that recognition stops firing — and it would stop *silently*,
  the whole app staying light with a dark theme installed and nothing saying
  so. The test calls this, which is what makes the coupling visible instead of
  load-bearing and unwatched.
  """
  @spec theme_agrees?() :: boolean()
  def theme_agrees?, do: Kati.Theme.dark().background == @dark_paper

  # ── Lookup ────────────────────────────────────────────────────────────────

  @doc "A token's light value — the literal it replaces, exactly."
  @spec light(atom()) :: pos_integer()
  def light(name), do: token(name, :light)

  @doc "A token's dark value."
  @spec dark(atom()) :: pos_integer()
  def dark(name), do: token(name, :dark)

  @doc "A token resolved through `mode/0`."
  @spec token(atom()) :: pos_integer()
  def token(name), do: token(name, mode())

  @doc "A token resolved in an explicit mode."
  @spec token(atom(), :light | :dark) :: pos_integer()
  def token(name, mode)

  for {name, light, dark, _source, _meaning} <- @tokens do
    def token(unquote(name), :light), do: unquote(light)
    def token(unquote(name), :dark), do: unquote(dark)
  end

  # ── The call-site API ─────────────────────────────────────────────────────
  #
  # One `name/0` and one `name/1` per token, generated from the table so the
  # two cannot drift. `Palette.card()` reads at a call site the way a colour
  # should; `Palette.card(:light)` is for the places that are deliberately one
  # mode, like screen 29's lock preview.

  for {name, light, dark, _source, meaning} <- @tokens do
    hex = fn value -> "0x" <> String.pad_leading(Integer.to_string(value, 16), 8, "0") end

    @doc """
    #{meaning}

    Light `#{hex.(light)}` · dark `#{hex.(dark)}`.
    """
    def unquote(name)(), do: token(unquote(name), mode())

    @doc false
    def unquote(name)(mode) when mode in unquote(@modes), do: token(unquote(name), mode)
  end
end
