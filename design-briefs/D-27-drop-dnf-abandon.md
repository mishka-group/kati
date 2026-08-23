# One drop, DNF and abandon state machine, for shows, books and albums

> **One reference board in screen 27's manner + the surface edits it implies** · issue [#17](https://github.com/mishka-group/kati/issues/17) · ticket `D-27`

Three media, three vocabularies, and no board says what any of them mean. Draw the states once so all three surfaces can read the same page.

## The five states, named once

| State | Show | Book | Album |
|---|---|---|---|
| **Active** | Watching · next up S2 E6 | Reading · p. 214 / 380 | In rotation · 11 plays |
| **Paused** | Paused, deliberately | Paused, deliberately | Paused |
| **Gone cold** | No activity for 4 months, Kati noticed | No session for 6 weeks | No play for 3 months |
| **Dropped** | Dropped at S1 E3 | Did not finish at p. 148 of 380 (39%) | Dropped after 2 listens |
| **Finished** | Season complete / series complete | Finished 12 Aug | — |

## The distinction the whole board exists to draw

**Gone cold is observed by Kati. Paused and Dropped are chosen by the user.**

Screen 10 currently blurs them by offering *Drop* from inside the Gone cold section. Render Gone cold at a **different weight** — it is a suggestion, not a status — and draw the Drop action from there as visibly *accepting Kati's suggestion* rather than as the same button that appears elsewhere.

Get this wrong and the app is telling people what they think about their own books.

## Three properties every drop carries, in all three media

1. **A captured position.** `S1E3`, `p. 148`, `track 4`. **Never a bare "dropped" with no stopping point** — that is the single thing that makes this better than every incumbent, all of which throw the position away.
2. **An optional one-tap reason chip.** Standard chip recipe. Suggested set: *Lost interest · Too slow · Not for me · Too long · Bad time for it · Might come back*. One tap, **never mandatory** — a required reason is a reason people lie about.
3. **Undoability.** Screen 27's dark undo pill, because the activity log is append-only and doubles as the undo trail.

## The reference board

Screen 27's manner: one board, five bands, an eyebrow each, all three media shown per band so the parallel is visible rather than asserted. Plus a sixth band for the **transitions** — which state can become which, and what each one captures on the way.

## Per-surface edits this implies

| Surface | Edit |
|---|---|
| Screen 04 series detail | the state row, and Drop capturing the position |
| Screen 10 Up next | Gone cold at its lighter weight; Drop reads as accepting |
| Book detail (66) | *Did not finish at p. 148 of 380 (39%)* — the percentage is the useful part |
| Album detail (74) | Dropped after N listens |
| The three shelves | the state as a filter chip, feeding `D-26`'s sheet |

## States to draw

All five, in all three media, plus: **a drop being undone**, **a dropped title picked back up** (does it resume at the captured position, or start over?), and **a reason chip declined** — the drop with no reason must look complete, not unfinished.

## Reuse, do not invent

Screen 27's banded reference format and its eyebrows · the chip recipe · the dark undo pill · screen 10's Gone cold section · the DM Mono position values.

## Left open — decide and note which way you went

- **Whether Album gets a Finished state at all.** An album does not finish the way a series does. The table above leaves it blank; either fill it or say on the board that it is deliberately empty.
- **What picking a dropped title back up does.** Resume at the captured position, or clear it. The position was captured for a reason, so resuming is the stronger default — but say it.
- **Whether Gone cold can be dismissed** without dropping. *"No, I'm still on it"* is a real answer and there is nowhere to give it.

---

## House style — Kati

Draw into `Kati.dc.html` as new `IOSDevice` artboards, **402×874**.

**Numbering.** The app now runs **01–139**. Nothing may be inserted below 139; new boards take the next free numbers upward. An *edit* to an existing screen is redrawn as a new board rather than changed in place, so the before and after can be compared.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, IDs and eyebrows, `Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

**Palette.**

| Token | Light | Meaning |
|---|---|---|
| paper | `#EFECE7` | page ground |
| card | `#FBFAF8` | any raised surface |
| cream | `#FBF1DE` | a card carrying a claim, a warning, or anything the user wrote |
| ink | `#1A1917` | primary text, filled buttons |
| ink soft | `#5C574F` | body copy on a card |
| sub | `#8A8479` | a row's second line |
| tertiary | `#A9A29A` | mono captions, chevrons |
| mono caption | `#6E6860` | DM Mono values in a row |
| accent | `#E8823C` | one thing per screen, never two |
| bronze | `#C98A3E` | money, meals, a gentle warning |
| green | `#4E9A73` | done, allowed |
| red | `#B4553C` | destructive, and only destructive |

Dark ground is `#121110`, card `#1E1D1B`, ink `#F5F2EE`.

**Recipes already in the app** — reuse rather than invent:

- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22, `#FBFAF8`, `arrow_back_ios_new` + parent name), no dock, frame closes at 40.
- **Root screen** — same but the dock is drawn and the frame closes at 132.
- **Modal / bottom sheet** — centred title, leading `close` disc, scrim `rgba(26,25,23,.42)`, sheet ground `#EFECE7` with the top corners rounded at 22.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase, `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title, 11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere* — never use one for a row that does not push a screen.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` with `#FBFAF8` text.
- **Pill button** — height 30, radius 15, `#EFECE7`, 11.5px/600.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Selection ring** — `0 0 0 2px #1A1917, 0 8px 18px -14px rgba(26,25,23,.7)`.
- **Undo pill** — the dark pill from screen 27: ink ground, white label, `#E8823C` action word.
- **Info footnote** — a bordered block with an `info` glyph, `#5C574F` body at 1.65 leading.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go Shamsi and digits Persian, both in DM Mono so columns still align. **Persian carries no letter-spacing** — tracking pulls Arabic-script joins apart — and takes a taller line-height, 1.7–1.9 for a paragraph. The week starts **Saturday**, and mirroring alone does not achieve that: the sequence restarts at شنبه.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure — a seven-across week strip, a fixed-height pill — caps instead. A heading sharing a row with a control yields to the control.
