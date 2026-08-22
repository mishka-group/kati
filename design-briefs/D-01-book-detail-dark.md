# Book detail — dark

> **Full screen** · issue [#4](https://github.com/mishka-group/kati/issues/4) · ticket `D-01`

The Book detail screen at night, showing that the hairline-instead-of-shadow rule survives a cover hero, a cream note card and a progress bar.

## Where it is reached from

Same route as the light screen — cover tap on 20 Books shelf — with the app in dark theme. No dark Books shelf artboard exists (28 Dark — home is the only dark precedent), so this is a theme variant, not a separate route.

## Bands, top to bottom

1. Chrome — paper #121110, title #F5F2EE, back pill '‹ Library'
2. Hero band — cover hairline ring on dark; progress track/fill unchanged, #E8823C stays the only orange
3. Ratings row — two columns on dark card #1E1D1B with inset 0 0 0 1px rgba(245,242,238,.06) instead of a shadow
4. Status control — four choices on dark; selected state in ink-on-light inversion per screen 28's treatment (exact treatment unstated)
5. Edition row — chips and toggle on dark card
6. Content warnings — collapsible block on dark card
7. Your notes and quotes — cream card warms to #2A2622 with #F7EFE4 text
8. Series row · Ownership row — dark list rows
9. History band — dark activity rows
10. Action row — ink button on dark (treatment unstated by the ticket beyond 'every button is ink')

## States to draw

- dark — in progress

## Reuse, do not invent

Screen 28's dark tokens: paper #121110, card #1E1D1B + inset hairline, cream → #2A2622 / #F7EFE4, secondary text #8A837B, accent #E8823C unchanged; every Book detail recipe otherwise identical to the light screen.

## Left open — decide and note which way you went

Whether the dark variant earns its own number (28's precedent) or is drawn as an annotated variant of the light screen. The ink-button and selected-chip treatment on near-black paper is not specified — 28 is the only reference. No dark Books shelf exists to push from.

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
