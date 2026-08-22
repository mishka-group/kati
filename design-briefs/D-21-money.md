# Money

> **Full screen** · issue [#24](https://github.com/mishka-group/kati/issues/24) · ticket `D-21`

Give quick-add's Expense type a destination by pairing the existing subscription commitments with one-off expenses, without becoming a budgeting app.

## Where it is reached from

Screen 07 "Your year" (Stats root) → "More numbers" list → the `payments` row currently reading "Subscriptions · £46.47 a month" with chevron_right (that row today opens 23). Back pill "‹ Stats", matching 15, 22 and 23.

## Bands, top to bottom

1. Back pill "‹ Stats" + trailing `more_horiz` disc (44pt row, as 23)
2. Large title + count subtitle — 23 reads "Subscriptions / 5 active"; the ticket does not specify a new title or subtitle for the widened screen
3. Monthly headline, unchanged from 23: mono label "Every month", "£46.47", delta badge "Up £4.00 since March — Orbit raised its price"
4. Recurring commitments — mono section label (23 uses "Services"): the existing per-service rows unchanged — letter badge, "renews 18 Aug · 41h watched", price, and £/h (Lumen+ £0.21/h, Orbit £2.33/h, Kino £0.60/h). £/h stays the largest, most-coloured figure in each row; it must not be demoted by anything added below
5. One-off expenses — new section, expenses filed from quick-add grouped by month, with a month subhead per group
6. Expense row: amount in DM Mono, date, and the section it belongs to. No category, no budget, no chart
7. Monthly total for the one-off section + delta badge (recipe from 07/23). Ticket specifies the total and the badge but gives no literal copy
8. "Worth a look" insight card kept from 23: lightbulb + "You watched 6 hours on Orbit this month and have 1 title left in its queue. Pausing after 24 Aug saves £13.99." with Remind me 23 Aug / Dismiss

## States to draw

- Default — services + one-off expenses populated
- No money set up — empty state with no services, explicitly NOT £0.00 (this is every new user; interacts with D-10 which owns the service list and prices)
- Subscription with no watch hours — the £/h cell reads "—", never £0.00 and never infinity (the most likely first-week state)
- Paused subscription — "Aria Audio — paused until October", already drawn on 23; the drawing must state that it is excluded from the monthly total
- Cancelled with history — row moves out of the active list without deleting the past; its hours still count towards screen 07

## Reuse, do not invent

Back pill (arrow_back_ios_new + "Stats"); large title header; mono section label with the 13×2 orange rule; elevated card #FBFAF8 r18–22; provider badge (single-letter square L/O/K/A); delta badge (arrow_drop_up + amount, green/red); insight card (lightbulb + bolded numbers + two text actions); DM Mono for every figure; the empty-state band from 27 (glyph + two lines + ink button); ink is the only button colour.

## Left open — decide and note which way you went

Whether 23 is widened in place or this ships as a sibling screen with 23 retired — the ticket allows either. The one-off section's total copy and the month-group header format are unspecified. Whether the screen keeps the title "Subscriptions" or is renamed (and whether 07's More-numbers row is relabelled with it).

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
