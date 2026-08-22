# Log progress — states

> **Reference sheet** · issue [#5](https://github.com/mishka-group/kati/issues/5) · ticket `D-02`

A reference sheet, in screen 27's manner, showing the five states the Log progress sheet must handle.

## Where it is reached from

Not navigable — a reference sheet in the pattern of screen 27 Empty, loading, offline (.scratch/design/screens/27.html, lib/kati/screens/states.ex, reached ‹ Settings).

## Bands, top to bottom

1. First session: confirmation line degrades honestly to "that's 46 pages in 38 minutes" with no comparison clause — do not fabricate a comparison
2. Invalid entry: page below the current position or above the page count; inline correction in #B4553C with a one-tap fix — "Did you mean you re-read to p. 194?"
3. No page count known: Page segment disabled plus an "Add a page count" affordance that jumps to the Edition row on the D-01 Book detail screen
4. Offline: the session saves with no degradation; `cloud_off` badge shown only if the sheet would otherwise imply a fetch
5. Post-save undo: the dark undo pill from 27 on return — "Logged 46 pages · Undo"

## States to draw

- First session (no comparison)
- Invalid entry with one-tap fix
- No page count known
- Offline
- Post-save undo bar

## Reuse, do not invent

Screen 27's five-band states-sheet layout and its dark undo pill and `cloud_off` offline badge; screen 31's three one-tap clash fixes as the model for the inline correction; error red #B4553C.

## Left open — decide and note which way you went

1) A disabled segmented-control segment has no precedent anywhere in the 62 — its treatment must be invented. 2) Where the undo pill surfaces on return: screen 20, the D-01 Book detail screen, or both.

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
