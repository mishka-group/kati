# Search result edge states

> **Reference sheet** · issue [#10](https://github.com/mishka-group/kati/issues/10) · ticket `D-07`

Sheet showing the four result states screen 19's canonical mixed-results view cannot show, so the layout is proven not to break at each.

## Where it is reached from

Not navigable — a reference sheet for screen 19's results area, the way screen 27 is the reference sheet for empty/loading/offline. Screen 19 exists and is reached from screen 01's search field.

## Bands, top to bottom

1. Band 1 · 'Results, one scope only' — scope row with seven `0` badges in #C4BDB3 and one non-zero; a single group beneath; the point of the band is that seven zero tabs must not read as broken
2. Band 2 · 'No results' — screen 27 band-1 idiom: a glyph, one sentence, and a useful action; the action is 'Add it by hand' or 'Search TMDB for ⟨query⟩', pushing the add flow on screen 06
3. Band 3 · 'Nothing here, but something elsewhere' — literal copy: 'Nothing in Calendar. 3 matches in Screen →'
4. Band 4 · 'Offline' — `cloud_off` badge; local data still searches and the copy says the library still works; any provider-backed lookup is the only thing withheld

## States to draw

- results in one scope only
- no results anywhere, with the add action
- no results in this scope but results elsewhere
- offline

## Reuse, do not invent

Filter/scope chip with count badge; list row (40×40 icon tile + 13.5/600 title + 11.5 #A9A29A sub + chevron_right); poster tile for Screen/Books/Music rows; screen 27's empty-state and cloud_off idioms; primary button (ink) for the add action; mono section label.

## Left open — decide and note which way you went

Whether the zero-count chips stay tappable. Whether 'Search TMDB for ⟨query⟩' or 'Add it by hand' is the single action or both appear — the ticket offers them as alternatives without choosing.

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
