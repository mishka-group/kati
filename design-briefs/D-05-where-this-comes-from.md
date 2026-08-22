# Where this comes from

> **Settings page** · issue [#8](https://github.com/mishka-group/kati/issues/8) · ticket `D-05`

A colophon that names every metadata source and licence Kati depends on, discharging the TMDB, JustWatch, TVmaze, Open Library and MusicBrainz attribution obligations in the app's own voice.

## Where it is reached from

Screen 24 (Settings) -> About group -> a new row. Confirmed: 24 exists and has an ABOUT mono-label group, but it currently holds only Version (info glyph) and Privacy (shield, "Nothing leaves the device") rows, so 24 must gain the row that opens this screen.

## Bands, top to bottom

1. Back pill '‹ About' (fallback '‹ Settings' — see decisions), 13px/600 + arrow_back_ios_new
2. Large title 'Where this comes from' 22px/700/-.03em, left-aligned, with 13.5px #A9A29A subtitle 'Posters, covers, air dates and facts'
3. TMDB card — real TMDB logo in a wide image-slot (never a letter tile); Kati line 'Film posters, backdrops and the facts behind them.'; then verbatim notice as body text 12.5–13.5px #5C574F: 'This product uses the TMDB API but is not endorsed or certified by TMDB.'; then a link row to themoviedb.org with trailing chevron_right
4. JustWatch card — JustWatch mark; 'Which services a title is on, and when it’s leaving.'; a credit sentence naming JustWatch (ticket does not give exact wording); link row. Card must exist even though the data arrives via TMDB
5. TVmaze card — TVmaze mark; 'TV schedules and episode lists.'; CC BY-SA credit carrying a working link back (the link is the licence condition, not decoration); 'CC BY-SA' named in mono caption 10.5px #A0998F
6. Open Library card — mark; 'Book covers, editions and ISBNs.'; credit sentence (wording unspecified in ticket); link row
7. MusicBrainz + Cover Art Archive card — both marks, both projects named; 'Album and artist data, and cover art where it exists.'; credit; link row
8. Tier-2 provider slot — absent on this default artboard; rendered only when a provider is connected, state owned by D-04 (see the states sheet)
9. Open-source licences card — MIT (Kati’s own, matched to Mob), Apache-2.0 (Mishka Chelekom generated components; no upstream NOTICE file), OFL typefaces named individually: Plus Jakarta Sans, DM Mono, Vazirmatn; pushes or expands into the full third-party notice list; annotate that the on-screen list is generated from THIRD_PARTY_NOTICES.md, not hand-maintained
10. Non-commercial note as an info footnote in a tinted card — Kati is free, ad-free and IAP-free so TMDB/Last.fm non-commercial terms hold; exact copy not specified, and the ticket allows this to live in About instead

## States to draw

- default — all Tier-0 sources, no Tier-2 card, light, LTR

## Reuse, do not invent

Elevated card (#FBFAF8, radius 18–22, padding 14–18, box-shadow 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)); large-title header; back pill; list row (40×40 #EFECE7 icon tile + 13.5px/600 title + trailing chevron_right) for the link rows; mono caption 10.5px/.16em #A0998F for licence names; info footnote card (info glyph + grey paragraph in a tinted card); image-slot for logos, on the provider-badge 40×40 tile geometry where the mark is square. Do not introduce a link colour — #C96A28/#E8823C are canvas chrome, not app colours. Only new asset: the real third-party marks, used unmodified, never recoloured to Kati's palette.

## Left open — decide and note which way you went

Back-pill parent: '‹ About' (adds a new parent label to the observed set) vs '‹ Settings' with the entry point on the About card. Whether the open-source card pushes to a separate notices screen or expands in place. Whether the non-commercial statement sits here or in About. Credit wording for JustWatch, TVmaze, Open Library and MusicBrainz/CAA — only the TMDB sentence is quoted verbatim in the ticket. Logo slot geometry per mark (square tile vs wider wordmark slot). Screen number: 'from 63 upward', shared range with D-04. Brand assets must be obtained before drawing.

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
