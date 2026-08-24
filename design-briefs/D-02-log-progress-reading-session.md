# Log progress — reading session

> **Modal sheet** · issue [#5](https://github.com/mishka-group/kati/issues/5) · ticket `D-02`

Logs one reading session — a new position or a duration — so the pace figure on screen 20 finally has a write path.

## Where it is reached from

Screen 20 Books shelf (test/design/screens/20.html, lib/kati/screens/books.ex — parent confirmed). The ticket names NO control on 20; 20's Reading-now hero currently draws no button, so the trigger must be invented. Also opened from the D-01 Book detail 'Log progress' action, which is not drawn yet.

## Bands, top to bottom

1. Sheet chrome: bottom sheet, content height, 26 px top corners; centred title "Log progress", leading `close` glyph, NO trailing Save, no back pill, no tab bar
2. Context header: near-square cover thumb (placeholder="Cover"), book title, current position "at p. 214 of 380" in DM Mono
3. Unit segmented control: Page · Percent · Minutes; track #E4E0D9, thumb #FBFAF8 + 0 1px 2px shadow
4. Number field: large DM Mono numeral (26–28 px hero role) with a stepper either side, targets ≥44 px; label must read "I am now on page N", not "I read N pages"
5. Timer mode: start/stop toggle; while running the sheet shows an elapsed figure in DM Mono and the primary button becomes "Stop and save"
6. Optional "started at" row: list row with trailing time value in DM Mono, defaulting to now minus the session length
7. Confirmation line: body type, numbers bolded, insight-card manner — "that's 46 pages in 38 minutes · your fastest this week"
8. Primary button: ink #1A1917, height 44–54, radius 22–27 — "Save session"
9. Secondary text action "Finished the book": saves the session, sets status Finished, hands straight off to screen 33 Rating & review — draw the hand-off arrow/annotation
10. Caption/design note: which fields of this sheet produce screen 20's "p. 214 / 380 · 23 min/day pace", and the chosen pace definition

## States to draw

- Default idle, Page mode
- Timer running (elapsed DM Mono figure, "Stop and save" primary)
- Percent mode and Minutes mode — only the field suffix and confirmation line change, nothing else moves
- Timer-still-running affordance shown persisting after the sheet is dismissed

## Reuse, do not invent

Modal header recipe from 06/18/31/33/46 (centred title + leading `close`, no trailing action, matching 06 and 18); segmented control recipe (#E4E0D9 track, #FBFAF8 thumb); list row recipe; ink primary button; near-square image-slot placeholder="Cover" from 20; DM Mono mono-caption and hero-numeral roles; insight-card bolded-numbers sentence from 23 and 47. Mob build note: draw as `drawer` side: :bottom, header: false, corner_radius: 26 — Mob has no modal presentation API.

## Left open — decide and note which way you went

1) The pace definition — minutes per calendar day since starting vs minutes per day on days you actually read vs a trailing 7-day mean; pick one and state it under screen 20's caption. 2) How the chosen unit interacts with the edition picked on the D-01 Book detail screen and with the derived pace caption — the ticket says this has never been drawn. 3) The exact wording that disambiguates "now on page N" from "read N pages". 4) The control on screen 20 that opens the sheet — unspecified. 5) The visual form of the timer-still-running affordance.

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
