# Attribution — Persian & RTL

> **Settings page** · issue [#8](https://github.com/mishka-group/kati/issues/8) · ticket `D-05`

The same colophon in Persian and mirrored, showing that Kati's sentences translate while the quoted third-party notices do not and the brand marks do not mirror.

## Where it is reached from

Screen 62 (تنظیمات — Settings, RTL, back pill ← خانه) is the fa parent, but 62 currently shows only Language / Appearance / Sections / Data groups and has no About group, so the entry row does not exist there yet; the ticket routes only the LTR screen, from 24.

## Bands, top to bottom

1. Back pill mirrored to the right edge with the glyph flipped to arrow_forward_ios / chevron_left, parent label in Persian
2. Title and subtitle in Persian, Vazirmatn, no letter-spacing, line-height ~1.4 (Persian strings not supplied by the ticket)
3. TMDB card — logo unmirrored; Kati sentence translated to Persian; the verbatim English notice 'This product uses the TMDB API but is not endorsed or certified by TMDB.' sits below it, untranslated
4. JustWatch, TVmaze, Open Library, MusicBrainz + Cover Art Archive cards — same order, Persian Kati sentence above, quoted credit in its original language below
5. Link rows mirrored: icon tile on the right, trailing chevron flipped to chevron_left; Latin domain names and licence names stay Latin in DM Mono
6. Open-source licences card — Persian framing sentence; MIT, Apache-2.0, OFL and the three typeface names stay in their original form
7. Logos never mirror — 'Brand mark' is on the holds list (design-index:370); annotate this on the artboard

## States to draw

- Persian (fa) — Kati sentences translated, quoted notices not
- RTL — rows and cards mirrored wholesale, chevrons flipped, logos unmirrored

## Reuse, do not invent

Screen 62's mirrored settings row treatment; the same elevated card, list row, mono caption and info footnote recipes; Vazirmatn type rules (no tracking, taller line-height, Persian digits in DM Mono).

## Left open — decide and note which way you went

Whether Persian and RTL are one artboard (group N, screens 55–62, treats them as one) or two. The ticket supplies no Persian translations of the five Kati sentences. Whether screen 62 gains an About group so the fa route exists. Bidi handling of Latin URLs and licence names inside RTL rows.

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
