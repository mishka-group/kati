# Persian onboarding, steps 2 and 3

> **First run** · issue [#91](https://github.com/mishka-group/kati/issues/91) · ticket `D-33`

The two first-run steps that have no Persian board, and the renumbering of screen 38
that #91 and `LoudnessPrompt` both wait on.

## The problem, stated plainly

A Persian first run walks steps 2 and 3 on the **English** drawings. It lands on
`HomeFa` correctly at the end, so the run works and looks wrong in the middle.

`Kati.Onboarding.screen_for_step/1` is deliberately **not** locale-aware, and its
comment explains why: artboard 137 is screen 26 in Persian, not 38, so routing the
finish step by locale would strand a Persian run. The routing cannot be fixed until
the boards exist — this is a design gap wearing a code comment.

## What is needed

1. **Persian step 2** — the mirror of *What should Kati keep?*, the six section cards
   with two preselected, the *Continue with 2* button, and the *Restore from a backup
   instead* line beneath it
2. **Persian step 3** — the mirror of *One place for what you keep* and
   *How should we tell you?*

## And while 38 is open: split it into five steps

Screen 38 currently draws more than one panel in a single scroll — the flow map (134)
already names the renumbering as a build task, and it is what `LoudnessPrompt` needs to
have an entry at all (`38·3` routing forward). Drawing the Persian pair is the natural
moment to renumber the English one.

## States to draw

- Persian step 2 (RTL)
- Persian step 3 (RTL)
- the five English steps as separate boards, if the renumbering is taken here

## Reuse, do not invent

Boards 38 and 137, exactly. Nothing on these steps is new — this is the same flow in
the other script, and the only reason it is a brief is that no board exists to build
against.

## Left open — decide and note which way you went

Whether 38 is renumbered in this brief or a later one. The Persian copy for both steps.
Whether *Restore from a backup instead* keeps its position in RTL or moves.

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
