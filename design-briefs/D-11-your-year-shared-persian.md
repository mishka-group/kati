# Your year, shared — Persian

> **Full screen** · issue [#14](https://github.com/mishka-group/kati/issues/14) · ticket `D-11`

The mirrored Persian variant of the share flow, with Persian digits, a Shamsi year and a top-right-origin pixel field.

## Where it is reached from

Screen 61 (آمار — charts, RTL), whose header already carries the same inert `ios_share` disc as 07. The ticket requires Persian variants but does not name the entry point explicitly.

## Bands, top to bottom

1. Mirrored back pill — `arrow_forward_ios` + parent label "آمار", per the 58 / 62 convention
2. Right-aligned large title in Vazirmatn (no letter-spacing, taller line-height) + DM Mono subtitle "فروردین تا مرداد ۱۴۰۵". Persian title copy not specified
3. Section switcher mirrored — chips run right-to-left
4. Card pager mirrored, pages advance leftward. Draw the pixel-field card in frame with its year starting in the top-right corner, and the genres card peeking with bars filling from the right
5. Numerals stay DM Mono with Persian digits — ۳۱۲ ساعت, ▲۱۸٪ (U+066A), Shamsi year ۱۴۰۵ and not 2026
6. Aspect segmented control (Square · Story) mirrored — Persian labels not specified
7. Toggle row mirrored — switch on the left. Persian copy not specified
8. Ink "Save image" primary button — Persian copy not specified
9. Mirrored info footnote carrying the on-device / nothing-uploaded statement

## States to draw

- Persian RTL, light

## Reuse, do not invent

Screen 61's mirrored chart rules (right-to-left time axis, bars filling from the right, pixel field starting top-right); 58's mirrored back chevron; the locale row's Vazirmatn + Persian-digits-in-DM-Mono typography rules; all of 63's controls, mirrored.

## Left open — decide and note which way you went

Every Persian string (title, control labels, footnote) — the ticket names none. Whether the remaining two Persian cards (Hours, Top titles) need their own reference sheet, or whether showing the pixel-field and genres cards here is enough. Whether a Persian dark variant is also required — the ticket lists dark and Persian as separate requirements without crossing them.

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
