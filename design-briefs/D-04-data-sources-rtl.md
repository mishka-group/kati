# منابع داده — Data sources, RTL

> **Settings page** · issue [#7](https://github.com/mishka-group/kati/issues/7) · ticket `D-04`

The Persian mirror of the Data sources screen, proving the provider rows, timestamps and pairing code survive direction, numerals and script changes.

## Where it is reached from

Screen 62 (تنظیمات — Settings, RTL) — the mirrored Data-group row. Note: 62.html does not yet carry a Data sources row; acceptance only mandates updating screen 24, so adding the row to 62 is implied rather than stated.

## Bands, top to bottom

1. Mirrored back pill — `arrow_forward_ios` + "تنظیمات"
2. Right-aligned large title "منابع داده" + subtitle (Persian copy not supplied by the ticket)
3. Mono section label with the 13×2px orange rule on the right — five labels, same order as LTR
4. Three keyless provider rows mirrored — icon tile right, status dot and last-checked timestamp in DM Mono with Persian digits
5. TMDB card with the mirrored segmented control and its tinted footnote
6. Tier-2 row with the device-code pairing card — 6-character code stays in DM Mono with Persian digits
7. Token-storage tinted info card, right-aligned
8. Destructive "Disconnect everything and wipe tokens" row in #B4553C, mirrored
9. Cached metadata row — size and oldest-entry age in DM Mono with Persian digits

## States to draw

- RTL / fa (default all-good state only — the ticket asks for one RTL variant, not an RTL states sheet)

## Reuse, do not invent

Screen 62's wholesale row mirroring — icon right, chevron flipped to `chevron_left`, back pill glyph `arrow_forward_ios` (design-index:160). Vazirmatn with no letter-spacing and taller line-height; DM Mono retained for all numerals with Persian digits substituted (design-index:376-378). Same section-label, list-row, tinted-card, segmented-control and pairing-card recipes as the LTR artboard.

## Left open — decide and note which way you went

No Persian copy is supplied for any string on this screen (title, subtitle, section labels, the TMDB explanation, the token-storage disclosure, the cache footnote) — all must be written or commissioned. Also open: whether screen 62 gets the routing row (acceptance names only screen 24), and whether the RTL variant is its own artboard or an inset on the LTR one. Locale table lists ar/tr as ready, but the ticket asks only for the fa variant.

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
