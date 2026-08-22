# Album detail

> **Full screen** · issue [#6](https://github.com/mishka-group/kati/issues/6) · ticket `D-03`

Opens one album so the user can see when they first heard it and last played it, rate it, read per-track play counts, see the listen history as a pixel field, and log a listen.

## Where it is reached from

Screen 21 Music shelf — tapping an album art tile in the "On repeat this week" rail (21 has 3 image-slot placeholder="Art" tiles, confirmed). Also 19 Search everything (result row), 12 Lists & collections (list contents), and 06 Add a title (a just-added album). Back pill reads "‹ Library"; pushed scroller padding 64px 21px 40px.

## Bands, top to bottom

1. Back pill "‹ Library" — arrow_back_ios_new + label, 13px/600
2. Square art hero — image-slot placeholder="Art", 2px paper border ring + 0 1px 3px rgba(26,25,23,.3) image hairline. DEFAULT DRAWN STATE IS NO ART: paper-filled square carrying the "Art" placeholder and the album initial in the mono label style (Cover Art Archive coverage is patchy)
3. Identity block — album title as the 22px/700/-.03em large title; "Artist · Year" as the 13.5px #A9A29A subtitle; the artist is a tappable row that pushes the Artist detail screen
4. Two dates — "First heard 3 Mar 2024 · last played yesterday" as a paired DM Mono stat, using stat-tile-trio typography with TWO tiles not three, trio alignment kept
5. Star rating — half-star capable, the same control as 08 / 14 / 33 / 45
6. Tracklist — rows in screen 04's episode-row idiom: index in DM Mono, track title, duration right-aligned in DM Mono, trailing play count in DM Mono. Zero-play tracks keep the normal card treatment; no orange for recency. A track played today may carry the 8px orange dot from the header bell — nothing else
7. Listen history band — pixel field, one cell per day, 5-tone bronze ramp ['#EFE3CB','#E4D2B0','#D3B98A','#B08E55','#1A1917'] at 2px radius, over the last 12 or 13 weeks (the same object 22 and 47 render)
8. Cream note card — #FBF1DE, for anything the user wrote about the album
9. Action row — "Log a listen" (ink primary, opens D-02 variant B) · "Rate" · "Add to list"

## States to draw

- No art — the default, drawn first
- With art — second variant
- Loading — skeleton rows, never a spinner (27 band 2)
- Error — error glyph + "Couldn't load this album / Last success 6h ago" + Retry
- Offline — cloud_off badge; local play counts, ratings and notes still render
- Zero plays — album added but never played: the pixel field renders EMPTY rather than hiding, captioned "Nothing logged yet", and the primary action becomes "Log a listen"
- Dark — card #1E1D1B with inset 0 0 0 1px rgba(245,242,238,.06) in place of the shadow; cream becomes #2A2622 with #F7EFE4 text

## Reuse, do not invent

Back pill; large-title header + 13.5px #A9A29A subtitle; image-slot rect placeholder="Art"; elevated card (#FBFAF8, r18–22); stat tile trio (07, 47); star rating (08/14/33/45); episode row (04); pixel field (07/22/47); cream card (08 note); ink primary button; the 8px orange bell dot; skeleton row / cloud_off badge / error card from 27.

## Left open — decide and note which way you went

Screen number — the ticket says "numbered from 63 upward" but assigns none. Whether the pixel field spans 12 or 13 weeks. Whether the with-art variant is a separate artboard or an inset on the same board. Whether the six states are drawn as a 27-style reference sheet or as variants on the album/artist boards — the ticket says only "six states are drawn across the set". Whether a "connected to ListenBrainz" badge appears at all; if it does it must be sourced from D-04 Data sources, not invented here.

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
