# Book detail

> **Full screen** · issue [#4](https://github.com/mishka-group/kati/issues/4) · ticket `D-01`

The pushed detail screen for one book — progress, edition, warnings, notes, series, ownership and reading history in one place, so a cover tap on the Books shelf finally has somewhere to go.

## Where it is reached from

Screen 20 Books shelf — tap any cover in the 7-slot cover grid (or the Reading-now hero). Also pushed from 19 Search everything result rows, 12 Lists cards, and 06 Add a title after an add. All four parents confirmed present (20.html/19.html/12.html/06.html; lib/kati/screens/books.ex). Number: next free, i.e. 63 — never insert below 62.

## Bands, top to bottom

1. Chrome — pushed scroller 64px 21px 40px, no tab bar; back pill '‹ Library'; large title 22px/700/-.03em with author as 13.5px #A9A29A subtitle
2. Hero band — near-square image-slot placeholder="Cover" (2px paper border ring + 0 1px 3px rgba(26,25,23,.3) hairline) beside a stack of title, author, publication year, status pill; if in progress a 2px bar, track #C4BDB3 / fill #E8823C, captioned in DM Mono 'p. 214 / 380 · 23 min/day pace'. Orange appears nowhere else on the screen
3. Ratings row — two columns only, 'Yours ★4.5' and 'Community', keeping screen 14's column alignment and label typography; no critics column
4. Status control — four tappable first-class choices, never a swipe: 'Reading · Finished · Paused · Did not finish'; choosing Did not finish reveals an inline 'got to p. ___' field and an optional one-tap reason chip row (chip labels unspecified)
5. Edition row — format chips 'Paperback · Ebook · Audiobook' (standard chip recipe), then page count or duration with the unit visibly restated on switch (380 pages vs 11h 20m), ISBN in DM Mono, and a 'this is the edition I own' toggle row
6. Content warnings — collapsible block, closed by default, warnings as chips with a count; empty variant is one 11.5px #A9A29A line 'None recorded' plus an 'Add' affordance
7. Your notes and quotes — cream card #FBF1DE used exactly as screen 08 uses it; each quote carries a DM Mono page anchor 'p. 148' in mono caption colour #6E6860
8. Series row — list row '#3 of 7 in ⟨series⟩' with trailing chevron and a next-in-series affordance
9. Ownership row — Owned / Borrowed / Lent to ⟨name⟩ with an optional due date
10. History band — dated reading-session rows in screen 15 Activity log row style; session copy comes from D-02's logger and is not specified in this ticket
11. Action row — 'Log progress · Finish · Rate & review · Add to list'; exactly one ink button, the other three in 08's circular/secondary treatment (Log rewatch / Schedule / Share row)

## States to draw

- default — in progress, full metadata, light, LTR

## Reuse, do not invent

Pushed scroller + back pill + large-title header; elevated card (#FBFAF8, r18-22, standard card shadow); poster tile image-slot at near-square with Cover placeholder; 2px progress bar; star rating (half-star, from 08/14); 14's three-rating row reduced to two columns; filter/scope chip recipe for format, warning and DNF-reason chips; list row (40x40 icon tile + 13.5/600 title + 11.5 #A9A29A sub + chevron) for series and ownership; toggle row for 'edition I own'; cream card from 08; mono section label with 13x2 orange rule per band; 15's activity row; ink primary button + circular icon buttons.

## Left open — decide and note which way you went

Which of the four actions is the single ink button — ticket names the rule, not the winner (Log progress is the obvious candidate; the not-started variant says 'Start reading'). Community rating has no Open Library source: draw the column, expect '—' in build; Hardcover GraphQL is the candidate source. Title + author appear in both the large-title header and the hero stack; the ticket does not resolve that duplication. Content-warning vocabulary/source is D-13's; DNF reason chips and their labels are D-14's; history row content is D-02's. Whether books ship at this depth in v1 at all is open owner decision K-33 — draw it regardless.

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
