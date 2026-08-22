# Log a listen — manual album

> **Modal sheet** · issue [#5](https://github.com/mishka-group/kati/issues/5) · ticket `D-02`

Logs a manual album listen so the music shelf has a write path while automatic scrobbling (K-35) stays unproven.

## Where it is reached from

Screen 21 Music shelf (.scratch/design/screens/21.html, lib/kati/screens/music.ex — parent confirmed), presumably from an album tile in the "On repeat this week" rail; the ticket names no specific control. Also from the D-03 album screen, which is not drawn yet.

## Bands, top to bottom

1. Sheet chrome: identical to Variant A — 26 px top corners, content height, centred title, leading `close`, no trailing action (title string for this variant is NOT specified)
2. Context header: square album art (placeholder="Art"), album title, artist and year
3. Unit segmented control: Whole album · Selected tracks · Minutes
4. Selected-tracks mode: compact track list with tick rows reusing screen 04's episode-row treatment; already-counted tracks use watched-row fill #F4F1EC, #9C958B text, no shadow. Scope to ONE album (Mob caps at 256 event handles per frame)
5. Number field (Minutes mode): same DM Mono numeral + stepper geometry as Variant A
6. "Started at" row: implied by "same geometry" but not restated in the ticket
7. Confirmation line: "that's 11 tracks · 47 minutes · 4th time this month"
8. Primary button: ink — "Save listen"

## States to draw

- Whole album (default)
- Selected tracks — list with some rows already counted in #F4F1EC
- Minutes mode

## Reuse, do not invent

Same modal header, segmented control, ink primary button and confirmation-line treatment as Variant A; screen 04's episode-row / watched-row recipe for the track ticks; square image-slot placeholder="Art" from 21.

## Left open — decide and note which way you went

1) The centred title string for this variant — the ticket only fixes "Log progress" for Variant A. 2) Whether the "started at" row appears here. 3) Whether music gets an equivalent of the "Finished the book" shortcut — the ticket specifies none.

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
