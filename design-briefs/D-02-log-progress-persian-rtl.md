# Log progress — Persian RTL

> **Modal sheet** · issue [#5](https://github.com/mishka-group/kati/issues/5) · ticket `D-02`

The Persian mirror of the reading-session sheet, proving the stepper column still aligns and the timer face does not flip.

## Where it is reached from

A language variant of the new sheet, not a new route. The 62 contains no fa Books shelf — 57 کتابخانه (.scratch/design/screens/57.html) is the film/TV shelf — so no existing fa screen opens it; the parent is whichever fa books surface is drawn later.

## Bands, top to bottom

1. Sheet chrome mirrored: drawer edge and `close` glyph move to the leading (right) edge; 26 px top corners unchanged; centred Persian title
2. Context header mirrored: cover art itself does NOT mirror; position line in DM Mono with Persian digits
3. Segmented control mirrored: Page · Percent · Minutes in Persian, segment order reversed
4. Number field: DM Mono numeral with Persian digits, steppers mirrored so the numeral column still aligns
5. Timer face: NOT mirrored — direction of time and motion does not flip
6. "Started at" row mirrored: trailing time value keeps DM Mono with Persian digits
7. Confirmation line in Vazirmatn: no letter-spacing, taller line-height (1.4), Persian digits
8. Primary button mirrored, Persian label

## States to draw

- RTL default
- RTL timer running

## Reuse, do not invent

Group N's container-attribute RTL mechanism (dir="rtl" wrapper, not a fork) as used on 55–62; Vazirmatn for Persian text with DM Mono retained for numerals; screen 58's rule that mono numerals keep their column in Persian digits.

## Left open — decide and note which way you went

The ticket supplies no Persian strings for the title, the segment labels, the buttons or the confirmation line — all Persian copy is open.

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
