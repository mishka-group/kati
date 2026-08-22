# کتاب — Book detail, RTL

> **Full screen** · issue [#4](https://github.com/mishka-group/kati/issues/4) · ticket `D-01`

The Persian variant of the Book detail screen, proving the localisation pass survives a progress bar, a mono page column and cover artwork.

## Where it is reached from

Screen 57 کتابخانه — Library, RTL is the only RTL shelf drawn, so it is the parent by elimination; the ticket does not name one. Back pill uses `arrow_forward_ios` + parent label, as 58 does.

## Bands, top to bottom

1. Chrome — container dir="rtl", direction:rtl, pushed padding; back pill with `arrow_forward_ios` + '‹ کتابخانه'; large title in Vazirmatn, no letter-spacing, taller line-height (1.4)
2. Hero band — cover artwork never mirrors; progress bar fills from the right; page figures stay in DM Mono with Persian digits (۲۱۴ / ۳۸۰) so the column still aligns
3. Ratings row — two columns mirrored, star glyphs unmirrored
4. Status control — four choices mirrored, still tappable, still not a swipe
5. Edition row — format chips mirrored; page count / duration and ISBN stay DM Mono with Persian digits
6. Content warnings — collapsible block mirrored, chevron flipped
7. Your notes and quotes — cream card mirrored; page anchor in DM Mono Persian digits; user's own words never translated
8. Series row — list row mirrored, chevron flipped to `chevron_left`
9. Ownership row — mirrored
10. History band — dated session rows mirrored; dates in Shamsi, times in DM Mono Persian digits
11. Action row — mirrored; ink button keeps its single-button rule

## States to draw

- RTL Persian — in progress (light)

## Reuse, do not invent

Group N mechanics from 57/58/59: dir="rtl" container rather than a fork, arrow_forward_ios back pill, Vazirmatn type, right-filling progress bar, DM Mono with Persian digits, unmirrored artwork and stars; all Book detail recipes otherwise unchanged.

## Left open — decide and note which way you went

RTL parent and back label are not named in the ticket (57 inferred). Persian screen title and the sample book's strings are unspecified — the design's rule is that a user's own words are never translated, with transliteration plus an optional 'show original alongside', so which of the two the sample uses is open. Shamsi dates for the history band are implied by group N but not stated here.

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
