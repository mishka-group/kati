# New goal

> **Modal sheet** · issue [#18](https://github.com/mishka-group/kati/issues/18) · ticket `D-15`

Create a goal by picking what to count, how many, and by when.

## Where it is reached from

The new Goals screen's add control, and the empty state's ink button. Modal chrome follows screen 18 Quick add.

## Bands, top to bottom

1. Modal header: centred title with leading `close`, no tab bar, no back pill — title wording not specified by the ticket
2. "WHAT" — mono section label + one chip row, grouped by section with a mono label per group
3. Chip set, ten types minimum: books · pages · minutes read · films · episodes · hours watched · albums · minutes listened · meals cooked · habit days
4. "HOW MANY" — DM Mono numeric field with a stepper, the same control as D-02's
5. "BY WHEN" — segmented control: week · month · year, plus a fourth custom end-date option
6. Repeat-each-period toggle — ticket places repeat on the goal but not explicitly in this modal
7. Confirm action — ticket does not name it; modals 31 and 33 use a trailing "Save"

## States to draw

- default
- custom end date selected

## Reuse, do not invent

Screen 18 Quick add modal chrome (centred title + leading close); filter/scope chip row; mono section label; segmented control (track #E4E0D9, thumb #FBFAF8); toggle row; D-02's mono stepper field.

## Left open — decide and note which way you went

Modal title and confirm-action labels; whether the repeat toggle lives here or on the goal card; what the custom end date opens (no date picker exists in the 62-screen set); how the chip groups are labelled per section.

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
