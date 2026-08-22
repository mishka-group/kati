# Artist detail

> **Full screen** · issue [#6](https://github.com/mishka-group/kati/issues/6) · ticket `D-03`

Opens one artist so the user can follow them, browse their albums with play counts, compare albums on a play-count chart, and see whether there is an unheard release.

## Where it is reached from

Album detail — tapping the artist row in the identity block. Also screen 21 Music shelf, the "New from artists you follow" band (rows "Kell Ostrand — Estuary Tapes · out Friday" and "Vesper Line — single · out now", confirmed present). Pushed screen, padding 64px 21px 40px.

## Bands, top to bottom

1. Back pill + parent label
2. Header — artist name as the large title; circular image-slot avatar with a first-letter fallback; a "Following" toggle row (iOS switch, ink when on) annotated as the SINGLE SOURCE OF TRUTH for screen 21's "New from artists you follow" band and for the release watcher's alert types on screen 25
3. Albums rail — square art tiles with year and play count beneath, in the rail idiom of 01/03/05/10–14/20/21. Must render from locally held data with metadata filling in progressively — MusicBrainz allows 1 request per second per IP, so one request per album on open is not shippable
4. Play-count chart — horizontal bars, one per album, reusing screen 07's genre-bar recipe and its four-tone ramp #1A1917 / #4A443B / #7C766D / #B3ACA2 with a right-aligned value. No new chart style
5. "New from this artist" card — the ONE place orange is correct on these screens: announces an unheard release, tied to the release watcher (25)
6. Totals row — hours listened · first heard · distinct albums, DM Mono, stat-trio geometry

## States to draw

- Has something new — orange release card present
- Nothing new — says so plainly rather than vanishing, in the manner of 30's "Nothing else until 12 Sep"
- Metadata-only artist — known by name, no albums resolved: the rail shows screen 27 band 1's empty state scoped to this artist
- Partially filled — album rail rendered from local data with MusicBrainz metadata still arriving (rate-limit state, explicitly required)
- Loading — skeleton rows, never a spinner
- Error — error glyph + "Last success 6h ago" + Retry
- Offline — cloud_off badge; local play counts and ratings still render
- Dark — #1E1D1B card with inset hairline; cream #2A2622 / #F7EFE4

## Reuse, do not invent

Circular avatar image-slot (11/14/31/40/50); toggle row (25/32/34/35/36/51); art rail (01/03/05/10–14/20/21); horizontal bar chart with four-tone ramp (07 genres, 47); stat tile trio; empty state from 27 band 1; skeleton / offline / error from 27; back pill; large-title header.

## Left open — decide and note which way you went

Screen number. The exact nothing-new copy — the ticket gives only 30's "Nothing else until 12 Sep" as the manner, not the words. How many albums the rail and the bar chart show before truncating. How progressive metadata fill is signalled visually — the ticket requires the partially-filled state be drawn but specifies no treatment for it. Which of 25's six alert types the Following toggle drives (People you follow, Premieres, or both).

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
