# Create / edit a meal

> **Full screen** · issue [#23](https://github.com/mishka-group/kati/issues/23) · ticket `D-20`

Create a new meal or edit an existing one in screen 45's exact layout switched to an editable mode, so the portion multiplier is never reimplemented.

## Where it is reached from

The Meal library's create action (new screen above), and screen 45's `more_horiz` header menu for edit — both confirmed present (45.html header carries `more_horiz`).

## Bands, top to bottom

1. Back pill '‹ Meals' + editable slot/title line (45 reads 'Dinner · 19:30 · today' / 'Miso salmon, greens & rice')
2. Hero photo slot, editable, with the no-photo case drawn
3. kcal figure + portion multiplier '− 1.0× +' — the same component as 45, explicitly not a second implementation
4. Six macro figures (Protein / Carbs / Fat / Fibre / Sugar / Sodium) + three-segment macro bar, editable
5. Ingredient list: each row = name, quantity, unit, aisle category, optional per-100 g nutrition block. Draw the row in three states — fully known (nutrition auto-filled), partially known (quantity but no nutrition), unknown (free text, no nutrition)
6. Add-ingredient affordance (ticket names no control)
7. 'Approximate total' treatment via the info footnote component — a total built from partial data must say so, 'or every number downstream is a lie'
8. Method: time / oven / serves chips + method body, editable
9. Save action (ticket specifies none)

## States to draw

- A meal with no photo
- A meal with incomplete nutrition → approximate total
- A meal used by an active plan being edited — what happens to history, following 49's discipline ('takes effect Next Monday', 'Keep the history')
- RTL — macro bar fills right-to-left, protein first, per screen 59

## Reuse, do not invent

Screen 45's entire layout including the portion multiplier (design-index §7 item 18); info footnote component (design-index:203); list row (40×40 icon tile + 13.5px title + 11.5px sub + trailing); macro bar (42, 43, 45, 47, 59); elevated card; mono section label; primary ink button

## Left open — decide and note which way you went

What happens to eaten history when a meal inside an active plan is edited (ticket says 'state what happens' — 49's rules are the precedent, not the answer). Whether edit is a mode toggle on 45 or a separate route. The save affordance and its label. The unit model (grams / millilitres / '1 onion') and the aisle category list are named as needed but not enumerated.

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
