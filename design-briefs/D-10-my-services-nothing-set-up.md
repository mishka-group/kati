# My services — nothing set up

> **Settings page** · issue [#13](https://github.com/mishka-group/kati/issues/13) · ticket `D-10`

The first-run default of the same screen — no region, no services — because it is the state every new user is in.

## Where it is reached from

Same as the populated screen: screen 24 Settings, back pill '‹ Settings'. Also the destination offered by the empty availability lines on 08, 11 and 23.

## Bands, top to bottom

1. Back pill '‹ Settings'
2. Large title 'My services' + subtitle 'So Kati only shows you what you can actually watch.'
3. REGION — row with no country set (ticket does not specify the unset-region copy)
4. Region footnote unchanged
5. Search field
6. SUBSCRIBED — group present but empty, nothing toggled on (ticket does not specify empty-group copy)
7. FREE WITH ADS — nothing on
8. NOT MINE — collapsed 'Show all 47' row
9. RULES — three toggles at their defaults (defaults not specified)
10. Money link row in its zero state — screen 23 must read as an empty ledger rather than £0.00, so this row must not read '£0.00' either (copy not specified)
11. JustWatch attribution footnote → D-05

## States to draw

- nothing set up — no region, no services (light, LTR)

## Reuse, do not invent

Same recipes as the populated screen, plus the empty-state pattern from screen 27 band 1 (glyph + two-line explanation + ink primary button, design-index.md:222) if the empty groups need a call to action.

## Left open — decide and note which way you went

Copy for the unset region row, for the empty SUBSCRIBED group, and for the money link row when nothing is configured. Whether the empty state uses screen 27's glyph-and-button empty card or simply shows the list with everything off.

---

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–62** and nothing may be inserted below 62. This screen takes the
next free number.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, IDs and eyebrows,
`Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

**Palette.**

| Token | Light | Meaning |
|---|---|---|
| paper | `#EFECE7` | page ground |
| card | `#FBFAF8` | any raised surface |
| cream | `#FBF1DE` | a card that carries a claim or a warning |
| ink | `#1A1917` | primary text, filled buttons |
| ink soft | `#5C574F` | body copy on a card |
| sub | `#8A8479` | a row's second line |
| tertiary | `#A9A29A` | mono captions, chevrons |
| accent | `#E8823C` | one thing per screen, never two |
| bronze | `#C98A3E` | money, meals, a gentle warning |
| green | `#4E9A73` | done, allowed |

Dark ground is `#121110`, card `#1E1D1B`, ink `#F5F2EE`.

**Recipes already in the app** — reuse rather than invent:

- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22,
  `#FBFAF8`, `arrow_back_ios_new` + parent name), no dock, frame closes at 40.
- **Root screen** — same but the dock is drawn and the frame closes at 132.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase,
  `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title,
  11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere* —
  never use one for a row that does not push a screen.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` on ink with
  `#FBFAF8` text.
- **Pill button** — height 30, radius 15, `#EFECE7`, 11.5px/600.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Progress bar** — 2px, track `#C4BDB3`, fill `#E8823C`.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never
mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go
Shamsi and digits Persian, both in DM Mono so columns still align.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure —
a seven-across week strip, a fixed-height pill — caps instead. A heading sharing a row with a
control yields to the control.
