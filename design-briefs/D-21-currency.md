# Currency

> **Settings page** · issue [#24](https://github.com/mishka-group/kati/issues/24) · ticket `D-21`

Choose the one currency Kati records and displays every amount in, and state plainly that changing it converts nothing.

## Where it is reached from

Screen 54 "Settings — language & region" → Content group → the `payments` row "Currency · £ GBP" with chevron_right. The row is already drawn and leads nowhere (lib/kati/screens/language.ex:72 notes currency "ha[s] nowhere to be written"). Back pill labelled with 54's title; 54's own pill reads "‹ Settings" and the ticket does not specify this one.

## Bands, top to bottom

1. Back pill + large title "Currency" (title copy not specified by the ticket)
2. Currency list with the current selection checked — 54 shows "£ GBP"; the list's contents, order and whether it is searchable are unspecified
3. Info footnote carrying the recommended model verbatim in substance: one currency per Kati, chosen once, never converted — every amount is stored and displayed in it
4. The one-line why: Kati has no server and cannot know yesterday's rate
5. Formatting preview of the same amount in the active locale — English 1,234.56 vs Persian using CLDR group U+066C and decimal U+066B with arabext digits (`۸٫۹۹ پوند` is the precedent on 56). Formatting is free via ex_cldr; the locale row already carries `:currency_code`
6. Change-currency confirmation: states what changes (symbol and formatting) and what does not (historical amounts are NOT converted)

## States to draw

- Default — a currency selected
- Currency changed — the confirmation stating that nothing is converted
- RTL — the Persian formatting preview with CLDR separators, no ASCII comma

## Reuse, do not invent

Settings list row (40×40 icon tile + title + sub + trailing value/chevron) from 24/54/62; check glyph on the selected row as 54's language list does; info footnote card (`info` glyph + grey paragraph) used on 54, 40, 32; back pill; large title header.

## Left open — decide and note which way you went

THE ticket's headline decision: one currency per app with no conversion (recommended) vs per-item currency with a named rate source — the latter additionally needs a rate history and an "as of" date on every figure, and the ticket says to cost that extra surface before drawing it. Also open: whether the change confirmation is a modal sheet or an inline confirm, and whether the design cannot offer "Persian text with Latin digits for money" (engineering note says :latn is rejected for fa, so it cannot be an option).

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
