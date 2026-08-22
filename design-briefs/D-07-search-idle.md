# Search idle

> **Full screen** · issue [#10](https://github.com/mishka-group/kati/issues/10) · ticket `D-07`

The state screen 19 opens in when pushed from Home's search field — no query yet, keyboard already up, Recent chips visible.

## Where it is reached from

Screen 01 (Home), the header search field 'Search films, shows, events…' (confirmed present, with a trailing `tune` glyph). Also reached from screen 19 itself by tapping the field's `cancel` glyph to clear the query.

## Bands, top to bottom

1. Back pill '‹ Home'
2. Search field, empty, cursor visible — ticket does not specify what the placeholder becomes now that scope covers seven domains; keep or restate 'Search films, shows, events…'
3. Scope chip row, horizontally scrolling: All · Screen · Books · Music · Calendar · Meals · Money · Notes — ticket does not state whether count badges show at all while the query is empty
4. Mono section label 'RECENT' + chip row of past queries (existing chips: dentist, leaving soon, ines karvel, 4 stars) with a 'Clear' affordance; retention stated as 'the last 8'
5. One or two 'Try' suggestions — ticket says 'optionally' and specifies no copy
6. Raised on-screen keyboard (this is what makes it the tap-through state, not a blank screen)

## States to draw

- idle with Recent chips
- first-run idle — Recent empty by definition (cross-ref D-08)
- typing under the minimum — one character typed; the minimum must be stated on the artboard, including what it is for Persian/CJK single characters
- searching — skeleton rows, never a spinner (screen 27 band 2)
- debounced keystroke state — build note asks for it to be drawn and the debounce value stated

## Reuse, do not invent

Filter/scope chip (h 26–30, r 13–15, unselected #FBFAF8/#5C574F, selected #1A1917/#FBFAF8, mono count badge); back pill; mono section label with 13×2 orange rule; skeleton row from screen 27; screen scroller padding 64px 21px 40px (pushed screen).

## Left open — decide and note which way you went

The minimum query length (ticket says two is 'the usual answer' but explicitly leaves the non-Latin single-character case to the owner). The debounce interval. Whether zero counts render on the chips before any query is typed. The 'Try' suggestion copy and whether suggestions ship at all.

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
