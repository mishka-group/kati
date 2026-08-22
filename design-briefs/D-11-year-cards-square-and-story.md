# Year cards — Square and Story

> **Reference sheet** · issue [#14](https://github.com/mishka-group/kati/issues/14) · ticket `D-11`

Pin down the four cards at both required aspect ratios so the generator has one authoritative render spec.

## Where it is reached from

Not a pushed screen — a reference sheet sitting beside 63 on the shelf, in the manner of 27 and 41. The cards it specifies are what 63's pager shows.

## Bands, top to bottom

1. Sheet title + mono eyebrow; a one-line palette rule: paper #EFECE7, card #FBFAF8, ink #1A1917, bronze ramp, and no orange on any card
2. Hours card at 4:5 and at 9:16 — "312h 40m" as a 28 px hero numeral, the `arrow_drop_up` +18% delta badge, and the year set large
3. Top titles card at 4:5 and at 9:16 — poster-stack collage, three overlapping posters with a 2 px paper border, overlapping rightward in LTR
4. Genres card at 4:5 and at 9:16 — screen 07's horizontal bar chart, four-tone ramp #1A1917 / #4A443B / #7C766D / #B3ACA2, values right-aligned (07's data: Drama 104, Thriller 71, Documentary 49, Comedy 31)
5. Pixel field card at 4:5 and at 9:16 — 104 cells, bronze ramp #EFE3CB / #E4D2B0 / #D3B98A / #B08E55 / #1A1917, 2 px radius

## States to draw

- 4:5 (Square) — all four cards
- 9:16 (Story) — all four cards

## Reuse, do not invent

Pixel field; horizontal bar chart with its four-tone ramp; poster stack; delta badge; hero numeral type role (28 px); elevated card / cream card surfaces.

## Left open — decide and note which way you went

How each card reflows between 4:5 and 9:16 (crop, restack, or re-scale) is not specified. Whether a card carries any Kati wordmark or attribution is not specified — the ticket only says the pixel-field card is the one most likely to make someone ask what the app is.

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
