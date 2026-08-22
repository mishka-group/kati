# Meal library

> **Full screen** · issue [#23](https://github.com/mishka-group/kati/issues/23) · ticket `D-20`

Browse, search and filter every meal you have, and start a new one — the missing input to the eleven meal screens.

## Where it is reached from

Screen 43 (Meals — today). Ticket fixes the back pill as '‹ Meals' but names no control; 43's toolbar chip row (Week / Shop / Nutrition / Plan) is the only chip row on the parent — owner picks the entry.

## Bands, top to bottom

1. Back pill '‹ Meals' + large left-aligned title (ticket specifies no title string)
2. Search field over meal names
3. Slot filter chips: breakfast / lunch / dinner / snack
4. Meal grid OR list — ticket says 'a grid or list' and does not choose; each entry carries a 'Meal photo' slot
5. A create action (ticket names only 'a create action' — no placement, label or affordance given)

## States to draw

- Empty — no meals at all, using screen 27's empty geometry (glyph, two lines, ink button, secondary link)
- A meal with no photo (ticket calls this the common case)
- A meal with incomplete nutrition — approximate mark on its kcal figure
- RTL

## Reuse, do not invent

Back pill; large title header; filter/scope chip (43, 46, 47, 48); poster tile/rail with 'Meal photo' placeholder; elevated card (#FBFAF8, r18–22); screen 27's empty-state geometry; primary ink button

## Left open — decide and note which way you went

Grid vs list. Screen title and empty-state copy. Which control on 43 opens it. Whether create is a FAB, a header button or a row.

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
