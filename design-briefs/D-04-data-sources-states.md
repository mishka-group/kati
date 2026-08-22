# Data sources — states

> **Reference sheet** · issue [#7](https://github.com/mishka-group/kati/issues/7) · ticket `D-04`

Reference sheet carrying the seven non-default states of the Data sources screen, in the manner of screen 27.

## Where it is reached from

Not a navigable screen — a states reference sheet for the Data sources screen, same role screen 27 plays for the app at large (27 itself is reached from Settings with a `‹ Settings` back pill).

## Bands, top to bottom

1. Band label: PROVIDER FAILING — TVmaze row with a red #B4553C status dot, "last checked 18:02 · couldn't reach TVmaze", Retry action, in screen 27 band 4's error idiom
2. Band label: RATE-LIMITED — distinct from failing and deliberately non-alarming: "MusicBrainz · slowing down · 1 request a second" as a neutral note, not red
3. Band label: OFFLINE — the cloud_off badge plus a sentence saying the library still works
4. Band label: VERIFYING A PASTED KEY — inline skeleton in the key field, never a spinner
5. Band label: BAD KEY — a plain failure line plus what to check; never a raw HTTP status (copy not specified)
6. Band label: CACHE NEAR THE CEILING — "oldest entry 5 months · Kati will refresh these automatically"
7. Band label: AFTER WIPING — every Tier-2 row back to disconnected, with screen 27's dark undo bar
8. Confirmation for "Disconnect everything and wipe tokens" — required by acceptance but its copy and presentation (inline vs modal sheet) are not specified

## States to draw

- provider failing
- rate-limited
- offline
- verifying a pasted key
- bad key
- cache near the ceiling
- after wiping (undo bar visible)

## Reuse, do not invent

Screen 27's five-band reference-sheet layout and idioms: error card with Retry (design-index:225), cloud_off offline badge (design-index:224), shimmer skeleton rows never a spinner (design-index:223), dark undo pill (design-index:211). Plus the same provider list row and tinted info card recipes as the main artboard.

## Left open — decide and note which way you went

The ticket says "one new pushed screen" yet mandates eight drawn states, which cannot fit one artboard — splitting the seven non-default states onto a screen-27-style reference sheet is an inference, not something the ticket states; confirm with the owner. Also open: whether the wipe confirmation is a modal sheet or an inline destructive-confirm row, and its copy. Bad-key copy ("what to check") is unwritten.

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
