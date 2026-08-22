# The week as an image

> **Full screen** · issue [#23](https://github.com/mishka-group/kati/issues/23) · ticket `D-20`

One saveable page of the plan week — the recommended replacement for 'Print the week (PDF, fridge-sized)', which has no implementation path.

## Where it is reached from

Screen 50 (Share, import & export), the `picture_as_pdf` row 'Print the week / One page, fridge-sized' — confirmed present in 50.html.

## Bands, top to bottom

1. Page header — plan name and week (50 shows 'Cutting v3'; 48 uses the 'week of 17 Aug' idiom)
2. 5 slots × 7 days matrix, the idiom from screen 44 — but as a page, so cells can carry names rather than state only
3. Paper and ink, legible at arm's length (ticket's literal requirement)
4. Save / share action in the app chrome around the render

## States to draw

- RTL — the week restarts at شنبه rather than mirroring (screen 60: 'the hardest case in the whole pass')
- A week with free slots
- Incomplete-nutrition marks carried onto the page

## Reuse, do not invent

Matrix grid (44, 60); D-11's on-device card rendering; the ink/paper palette; mono section label

## Left open — decide and note which way you went

Whether screen 50's PDF row is retired (D-19's 'Not in this version' treatment), replaced by this image, or kept with native PDF work costed — ticket recommends the image, the choice is the owner's. Whether cells show names, kcal or both. File export itself depends on D-22 (Mob.Share is text-only; needs an ACTION_CREATE_DOCUMENT patch to MobBridge.kt).

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
