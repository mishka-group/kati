# Attribution — states

> **Reference sheet** · issue [#8](https://github.com/mishka-group/kati/issues/8) · ticket `D-05`

One reference sheet proving the attribution screen survives a connected Tier-2 account, no network, and Dynamic Type at 235% without truncating a legal notice.

## Where it is reached from

Not navigable — a states sheet for the new attribution screen, which is reached from screen 24 (Settings) -> About. Follows the precedent of screens 27 (empty/loading/offline) and 41 (the 235% re-lay).

## Bands, top to bottom

1. Band 1 — 'With connected accounts': the same stack with one Tier-2 card added in position 6 (ListenBrainz shown), sourced from D-04's connection state
2. Band 2 — 'Offline': the screen rendering identically with no network, annotated that logos are bundled assets and never fetched, because an attribution screen that fails to display offline is a compliance failure
3. Band 3 — 'Dynamic Type 235%': the TMDB card re-laid per screen 41's rule — rows become stacks, the card gets taller, the verbatim notice wraps in full and nothing truncates

## States to draw

- with connected accounts (one Tier-2 card)
- offline — renders identically from bundled assets, annotated
- Dynamic Type 235% — long-notice reflow, no truncation

## Reuse, do not invent

Same recipes as the main screen (elevated card, list row, mono caption, image-slot); screen 41's 235% re-lay pattern; screen 27's states-sheet band structure with mono section labels per band.

## Left open — decide and note which way you went

Whether the three states are one reference sheet or three separate artboards. Whether 235% is drawn for the whole screen or only the TMDB card, as screen 41 does. Whether the offline band borrows screen 27's offline badge at all — the ticket only requires that it render identically. Which Tier-2 provider to show if D-04 lands on a different default than ListenBrainz.

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
