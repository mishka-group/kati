# Goals

> **Full screen** · issue [#18](https://github.com/mishka-group/kati/issues/18) · ticket `D-15`

A pushed Stats screen where each goal shows its target, current figure, progress and a plain-language projection of where it lands.

## Where it is reached from

Screen 07 History & stats — a new row in the "More numbers" list (confirmed present in 07.html; today routes to 15 Activity log, 22 Habits, 47 Nutrition, 23 Subscriptions).

## Bands, top to bottom

1. Back pill "‹ Stats" (matches 15, 22, 23)
2. Large title "Goals" + subtitle — ticket does not specify the subtitle wording (count of active goals implied)
3. Goal card — ON PACE: target as a sentence "52 books this year"; hero mono numeral "38 / 52" in DM Mono 26–28px with the target in mono caption colour #6E6860
4. Same card: 2px progress bar, track #C4BDB3, fill #E8823C (legitimate orange — progress is now)
5. Same card: projection line in the insight-card idiom, numbers bolded — "on pace to finish 48 of 52 by 31 December"
6. Same card: small pixel field or sparkline of accumulation across the period, bronze ramp #EFE3CB→#1A1917
7. Goal card — AHEAD: identical anatomy plus delta badge in green #4E9A73
8. Goal card — BEHIND: identical anatomy plus delta badge in red; projection states the fact — "on pace to finish 41 of 52", never "you're falling behind"
9. "Repeat each period" affordance on the goal, echoing 44's "Repeats every week, indefinitely" — ticket does not say whether it sits on the card, a goal detail or the create modal
10. Per-goal footnote naming what counts (whether DNF pages and dropped hours count) — the rule itself is undecided, pending D-14
11. Add-a-goal entry point — ticket does not specify the control (FAB / header button / row)
12. Cross-link to screen 22 Habits ("read every day" is a habit, "read 52 books" is a goal) — ticket calls this a should, not a must

## States to draw

- on pace
- ahead
- behind

## Reuse, do not invent

Elevated card (#FBFAF8, r18–22, card shadow); progress bar recipe; insight card (lightbulb + bolded-number sentence, from 23/47); delta badge (from 07/23); pixel field bronze ramp (from 07/22/47); back pill; large title header; mono section label; info footnote.

## Left open — decide and note which way you went

Where the repeat affordance lives (card vs goal detail vs create modal); what control adds a goal; which of the ten goal types the populated screen shows; per-type counting rules (blocked in substance on D-14); whether the Habits cross-link is drawn; whether a goal detail/edit screen exists at all.

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
