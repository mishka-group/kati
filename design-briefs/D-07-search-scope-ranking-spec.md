# Search scope & ranking spec

> **Reference sheet** · issue [#10](https://github.com/mishka-group/kati/issues/10) · ticket `D-07`

The annotation deliverable — states per scope exactly which fields are searched and in what order results come back, which is what the ticket calls the actual output.

## Where it is reached from

Not navigable — a companion spec card to screen 19. The ticket offers it as 'an annotation layer (or a companion spec card)', so it may instead be drawn as annotations on 19 itself.

## Bands, top to bottom

1. Per-scope field list · Screen — title, original title, alternative titles, cast names, your tags, your review text
2. Books — title, author, series name, ISBN, your notes and quotes
3. Music — album, artist, track title, your notes
4. Calendar — event title, location, notes; NOT invitee names
5. Meals — meal name, ingredient names. Money — service name. Notes — every cream-card note in the app, whatever it is attached to
6. Group order, fixed: Screen · Books · Music · Calendar · Meals · Money · Notes (fixed order beats relevance-ordered groups because the user learns where to look)
7. Within-group ranking: exact title match → prefix match → substring → body-text match; ties broken by recency
8. Per-group cap: at most three rows, then a 'See all 12 →' row (also the 256-event-handle-per-frame argument)
9. Emphasis rule: weight 600→700 plus the ink colour, never orange — orange only ever means new/now
10. Minimum query length, stated, including the non-Latin single-character case
11. Recent-query retention: the last 8, with a Clear affordance; Recent queries are never translated
12. Persian normalisation set, spelled out with codepoints
13. Debounce — the build note asks for the interval to be stated because scope counts imply seven counted queries per keystroke

## States to draw

- default only

## Reuse, do not invent

Info footnote (info/lock glyph + small grey paragraph in a tinted card); mono section label; list row for the field tables; cream card if any of it is quoted as the user's own words.

## Left open — decide and note which way you went

Annotation layer on screen 19 versus a standalone spec card — the ticket allows either. The minimum query length value. The debounce value. Explicitly out of scope: do not promise typo tolerance or stemming on screen, because the FTS5-versus-hand-rolled-LIKE mechanism is unresolved.

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
