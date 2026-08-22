# Money on the calendar

> **Full screen** · issue [#24](https://github.com/mishka-group/kati/issues/24) · ticket `D-21`

Show how money behaves in the day spine: a renewal card in the time gutter and the all-day band, the 3+ merge, and whether a past expense appears at all.

## Where it is reached from

Screen 02 Schedule (Calendar root) — its Money filter chip and its 18:00 renewal row are the live parents. Drawn as a pushed reference sibling of 09 ("A heavy day") and 52 ("Meals on the calendar"), both back pill "‹ Calendar"; the ticket does not name the control that pushes it.

## Bands, top to bottom

1. Back pill "‹ Calendar" + `density_medium` disc (as 09 and 52)
2. Large title + item-count subtitle (52 reads "Mon 17 Aug / 5 meals · 6 other items"); exact copy unspecified
3. Filter chip row: All / Money n / Screen / Personal, as 02, 09 and 52
4. All-day band containing a renewal — the ticket requires it; no copy or treatment given (09's all-day band today holds "Vellum — in cinemas / release · wishlisted")
5. Single renewal in the time gutter: `payments` glyph, "Lumen+ renews", amount right-aligned in DM Mono — 02 draws it at 18:00 as "£8.99"
6. Merged money card: three renewals on one day collapsed to one card with a total and an expand_more chevron, under the same 3+ rule meals obey on 52 and episodes obey on 09. 09 currently draws this merge at TWO ("18:00 · payments · 2 renewals · £22.98") — the count must move to 3+, or the exception must be stated
7. Expanded state of that merged card, showing the three renewal rows
8. A one-off expense on the calendar — with a visible distinction between a past fact (expense) and a future commitment (renewal). Treatment is NOT specified; the ticket only requires a stated answer, including the answer "it does not appear"
9. Info footnote stating the rule, in the tinted-card pattern 09 and 52 both end with; copy unspecified

## States to draw

- Default day with money present
- Merged / collapsed vs expanded money card
- A day with a renewal in the all-day band

## Reuse, do not invent

Time-gutter timeline (left mono time column + one card per item, grouped/collapsed cards, all-day band); filter chips with count badges; the collapse row from 52 ("Collapse meals → 5 meals · 1,960 kcal · 1 eaten · next at 10:30" + expand_more); `payments` Material Symbol already used on 02, 09 and 56; info footnote card; DM Mono amounts.

## Left open — decide and note which way you went

Whether one-off expenses appear on the calendar at all, and how a past fact is drawn differently from a future commitment. Whether money merges at 3+ (aligning with meals and episodes) or keeps 09's drawn 2+ behaviour — the two currently contradict.

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
