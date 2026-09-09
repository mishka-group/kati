# Doors for the stranded screens

> **Affordances on eight existing boards** · issue [#93](https://github.com/mishka-group/kati/issues/93) · ticket `D-34`

One brief for eight boards, because it is the same problem eight times: a screen exists,
is built, is tested — and the **control that would open it is not drawn anywhere**.

## Why this is one brief and not eight

`Kati.AppReachabilityTest` names 47 screens with no in-app route, each with a written
reason. Read together they are three different things, and only one of them is a design
problem:

- **~35 are not places in the app** — states of screens (`GoalsEmpty` is screen 104 with
  nothing set), reference sheets drawn for comparison, `LaunchScreen`. Giving these doors
  would be wrong, not merely unnecessary. #94 deletes most of them.
- **1 is blocked on #91** — `LoudnessPrompt` needs screen 38 split into five steps; see `D-33`.
- **~10 are waiting on this brief.** Every one is a built screen whose parent board has not
  been redrawn to carry the affordance that opens it.

Inventing these entry points in code would put controls on screens the design does not
draw them on — which this project has avoided for 152 screens. So they wait here instead.

## The eight boards, and what each needs

| Board | Affordance to draw | Opens | Issue |
|---|---|---|---|
| **03, 20, 21** — the three shelves | a trailing **filter disc** in the header, beside the existing search and sort discs | `ShelfFilters` | #19 |
| **03, 20, 21** | a **long press** on a poster tile, and the hint that teaches it | `ShelfSelection` | #19 |
| **04** — film/series detail | a **long press** on an episode row, and its affordance hint | `RateEpisode` | #15 |
| **04, 66, 74** — the three detail boards | a **Drop** action on a title | `DropSheet` | #17 |
| **35** — series settings | a **per-show numbering** row | `NumberingScheme` | #21 |
| **36** — auto-detect | a **mode switch** at the top. #20 draws auto-detect-music as a *mode* of 36 rather than a second screen; the switch is drawn on 150 and not on 36. `Kati.Screens.AutoDetect.handle_tap/2` already answers `:open_music` — **only the control is missing** | `AutoDetectMusic` | #20 |
| **150** — notifications | the board itself is waiting; `NotificationAccess` is its special-access row and is reached from it | `NotificationAccess` | — |

`AnimeFilter` and `EpisodeRatings` are **not** on this list and should not be given doors:
their own reasons say each is *a board about a change landing on existing screens*, not a
screen beside them.

## The one decision that spans boards

**Long press means two different things.** #15 wants it on an episode row (rate this
episode); #19 wants it on a poster tile (select). Both reasons say the same thing — this
has to be decided on both boards before either ships it. If long press cannot carry both
meanings, one of them needs a different affordance, and that decision belongs here rather
than in whichever ticket is built first.

## States to draw

For each board: the resting state with the new affordance present, and — where the
affordance is a gesture rather than a control — the hint that teaches it. A gesture with
no visible hint is not an affordance; it is a secret.

## Reuse, do not invent

Every one of these is an addition to a board that already exists. The disc recipe is
screens 15/20/21's header disc. The row recipe is the standard list row, and **a chevron
means *leads elsewhere*** — never use one for a row that does not push a screen.

## Left open — decide and note which way you went

The long-press collision above, first. Whether the filter disc replaces or joins the sort
disc on 03/20/21. Whether Drop is a row in an overflow menu or a control on the board.
Whether 36's mode switch is a segmented control or two chips.

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
