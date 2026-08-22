# My services

> **Settings page** · issue [#13](https://github.com/mishka-group/kati/issues/13) · ticket `D-10`

The one place the user declares their country and which streaming services they pay for, so availability, leaving-soon and cost-per-watched-hour everywhere else are correct.

## Where it is reached from

Screen 24 Settings (24.html exists; it currently has Appearance / Sections / Data / About groups and NO services row — a new list row must be added there). Back pill reads '‹ Settings'. Also linked from screen 35's override rows and from the empty states on 08, 11, 23.

## Bands, top to bottom

1. Back pill '‹ Settings'
2. Large title 'My services' + subtitle 'So Kati only shows you what you can actually watch.'
3. Mono label REGION — one list row: flag glyph/tile + 'United Kingdom' + trailing value and chevron_right, opens the country picker
4. Info footnote under the region row: availability data is per-country, and showing a title as available in the wrong country is worse than showing nothing (reasoning given by the ticket; exact copy not specified)
5. Search field over the service list (ticket says 'searchable' but does not specify placement or placeholder)
6. Mono label SUBSCRIBED — toggle rows, each provider badge (single-letter square L / O / K / A / D) + name + an EDITABLE monthly price in DM Mono; use the screen 23 set: Lumen+ £8.99, Orbit £13.99, Kino £11.49. Annotate: this screen owns the price, screen 23 reads it
7. Mono label FREE WITH ADS — toggle rows, provider badge + name, no price field
8. Mono label NOT MINE — the long tail collapsed behind a 'Show all 47' row
9. 'Something else' escape-hatch row for a service TMDB does not list, with the row itself stating it will produce no availability data (exact copy not specified)
10. Mono label RULES — toggle row 'Count rentals as available' with consequence beneath: 'A film you'd have to rent still shows up in What fits tonight.'
11. Toggle row 'Count purchases as available' + a one-line consequence (ticket does not write this line)
12. Toggle row 'Hide titles I can't watch' — the strongest setting; a one-line consequence that states what it hides and where (ticket demands it but does not write it)
13. Link-to-money row: '3 services · £46.47 a month → Subscriptions', pushing to screen 23
14. JustWatch attribution footnote — provider data comes from JustWatch via TMDB — linking to the attribution card drawn by D-05

## States to draw

- default — region set, three subscribed services, light, LTR

## Reuse, do not invent

Back pill (design-index.md:180); large title header (:178); mono section label (:183); list row 40x40 icon tile + title + sub + trailing chevron/toggle/value (:184); toggle row (:204); provider badge single-letter square + name + price/status (:214); info footnote glyph + grey paragraph in a tinted card (:203); elevated card (:181); DM Mono for all prices.

## Left open — decide and note which way you went

Numbering (ticket says 'from 63 upward' but does not assign numbers to the extra artboards). Where on screen 24 the entry row sits and which group it joins. Search field placement and placeholder. Consequence copy for 'Count purchases as available' and for 'Hide titles I can't watch'. Default on/off for the three rules toggles. Exact wording of the region footnote and of the 'Something else' row. The £ symbol itself is owned by D-21, not this ticket. Provider badge stays a letter square until real logos exist, at which point the badge slot takes the logo.

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
