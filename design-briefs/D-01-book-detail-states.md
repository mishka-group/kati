# Book detail — states

> **Reference sheet** · issue [#4](https://github.com/mishka-group/kati/issues/4) · ticket `D-01`

The six state variants of the Book detail screen, drawn against screen 27's states vocabulary so each one is comparable to the full variant.

## Where it is reached from

Not user-reachable. Reference sheet sibling of the new Book detail screen, following the precedent of 27 Empty, loading, offline (‹ Settings). Number: the next free after the Book detail screen (64 if D-01 claims four artboards).

## Bands, top to bottom

1. Loading — skeleton, never a spinner: grey #E7E3DC cover block plus two shimmer bars (linear-gradient(90deg,#E7E3DC,#F1EEE9,#E7E3DC))
2. Partial metadata — the common Open Library case: cover slot empty showing the 'Cover' placeholder, page count replaced by a tappable 'Add page count' affordance, and no layout shift versus the full variant
3. Error — `error` glyph, 'Couldn't load this book / Last success 6h ago', Retry
4. Offline — `cloud_off` badge; locally-stored progress, notes and status still render and stay editable
5. Not started — zero sessions: no progress bar, status control in an unset state, primary action reading 'Start reading'
6. DNF — captured position shown honestly, no strike-through: 'Did not finish · stopped at p. 148 of 380 · 39%'

## States to draw

- loading
- partial metadata (no cover, no page count)
- error with Retry
- offline
- not started
- DNF

## Reuse, do not invent

Screen 27's skeleton row, cloud_off offline badge, error card with Retry; the full Book detail bands re-rendered per state; mono section label as the per-band caption; ink Retry / 'Start reading' primary button.

## Left open — decide and note which way you went

Ticket does not say whether the six states are one reference sheet (27's pattern) or six separate artboards. 'No layout shift versus the full variant' argues that at least partial-metadata, not-started and DNF need full-frame treatment rather than a band. Whether the sheet carries a back pill ('‹ Settings' like 27) or is chromeless is unstated.

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
