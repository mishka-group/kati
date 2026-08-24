# Weight

> **Full screen** · issue [#22](https://github.com/mishka-group/kati/issues/22) · ticket `D-19`

Log a weight and see the trend over time — the one tile of the four the ticket says to build outright.

## Where it is reached from

Screen 42 Health hub, the "Weight" tile in the Sections tile grid (today reads "Not set up"). Parent confirmed: test/design/screens/42.html and lib/kati/screens/health.ex. Pushed screen, back pill "‹ Health", matching screen 43.

## Bands, top to bottom

1. Back pill "‹ Health" + large-title header "Weight"
2. Hero numeral in DM Mono (current weight) with a delta badge beside it
3. Range segmented control — Week / Month / All, the same control screen 47 uses
4. Trend chart of the weight series — ticket says "a line or bar chart" and does not choose
5. List of entries (dated rows) — ticket names the list but specifies no row content
6. Entry point into the Log-weight modal — ticket does not say where this control sits or what it says

## States to draw

- No entries — screen 27's empty-state geometry
- One entry — no trend possible; say so in words rather than drawing a flat line
- A gap in the data
- Unit switched — kg / lb / st, following screen 54's Content → units
- Dark
- RTL

## Reuse, do not invent

Back pill; large-title header; segmented control (47); bar chart (47/07) or the chart form chosen; delta badge (07/23); stat tile trio (07/47); elevated card; list row; screen 27's empty state; pixel field is available but not asked for

## Left open — decide and note which way you went

Line chart vs bar chart is left open. Whether the unit switch is read-only from screen 54 or overridable here. Where the add-entry control lives and what it is labelled. Whether Dark and RTL are separate numbered artboards (as 28 and 55–62 are) or bands on this one.

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
