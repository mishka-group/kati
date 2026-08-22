# پول — Money, RTL

> **Full screen** · issue [#24](https://github.com/mishka-group/kati/issues/24) · ticket `D-21`

The money screen mirrored, proving amounts stay column-aligned in Persian with CLDR separators.

## Where it is reached from

The Persian Stats root, screen 61 آمار — mirrored equivalent of 07's "More numbers" money row. NOTE: 61 as drawn stops at the week bars and its footnote and does not include a More-numbers list, so that parent row does not yet exist and would have to be added to 61. Back chevron `arrow_forward_ios` with the Persian parent label, per 58/62.

## Bands, top to bottom

1. Mirrored back row: `arrow_forward_ios` + Persian parent label, `more_horiz` disc on the opposite edge
2. Mirrored title and count subtitle, Vazirmatn, no letter-spacing, taller line-height
3. Monthly headline and delta badge mirrored; amount in DM Mono with Persian digits
4. Recurring commitments — rows mirror wholesale as 62 specifies (icon right, chevron flipped); £/h keeps DM Mono with Persian digits so the rate column still aligns
5. One-off expenses section mirrored, amounts right-column aligned in DM Mono
6. Currency symbol/word placed per CLDR rather than hard-placed — `۸٫۹۹ پوند` is the drawn precedent on 56; decimal U+066B, group U+066C, percent U+066A. No ASCII comma or ASCII dot anywhere
7. Insight card mirrored

## States to draw

- RTL default

## Reuse, do not invent

Everything from the Money screen, plus the group-N mirroring rules: dir="rtl" container (not a fork), Vazirmatn with no letter-spacing, DM Mono numerals with Persian digits, rows mirroring wholesale per 62, back chevron per 58.

## Left open — decide and note which way you went

Whether the delta badge's arrow mirrors (the flip list covers reading direction; an up/down delta arrow arguably means change, not reading) — the ticket does not say. Whether 61 gains the More-numbers rows that make this screen reachable.

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
