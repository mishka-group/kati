# Add an ingredient

> **Modal sheet** · issue [#23](https://github.com/mishka-group/kati/issues/23) · ticket `D-20`

Add one ingredient to a meal and choose where its nutrition numbers come from.

## Where it is reached from

The Create / edit a meal screen's add-ingredient affordance. Ticket names no control for it.

## Bands, top to bottom

1. Modal header: centred title, leading `close`, trailing 'Save' (31/33 precedent)
2. Manual path — name, quantity, unit, aisle category. Ticket: 'Always available'; must not depend on any provider
3. Optional per-100 g nutrition block — kcal and macros, typed
4. 'Scan a barcode' entry point (mob_scanner exists as a QR/barcode plugin) marked as dependent on a food database that has not been chosen
5. 'Search a food database' entry point, marked provider-dependent — licence, rate limit, attribution and non-US coverage all unresolved
6. Preview of which of the three ingredient row states this entry will land in

## States to draw

- Unknown ingredient — free text, no nutrition
- Provider not chosen — scan and search paths marked or disabled
- Ingredient with no aisle → 'Uncategorised' rather than dropped
- RTL

## Reuse, do not invent

Modal header (06, 18, 31, 33, 46); list row; filter/scope chip; info footnote; primary ink button; 50's camera/QR path as the precedent for a scanner entry

## Left open — decide and note which way you went

THE owner decision of this ticket: the food data source — manual only, barcode scan, or a bundled/live food database (bundled costs APK size against 6.5–7.5 MB of Ash + 2.49 MB CLDR; live inherits D-04/D-05 rate-limit and attribution obligations). Also open: the unit list, the aisle category list, and whether this is a separate artboard at all — the ticket does not name it among its three screens.

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
