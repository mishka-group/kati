# Promises with no page behind them — See all, and the five kinds

> **Mixed — one board edited, two new artboards** · ticket `D-51`

Two people are stopped by the same missing drawing. The first searches `hollow`, sees
**Screen 3** on a chip over two cards, and has no way to reach the third — board 88 fixes
the rule (*Three rows per group. Then a "See all 12 →" row*) and no board draws either the
row or the page it opens, so `Kati.Search.Query.run/1` runs `Enum.take(rows_per_group())`
and the results a person cannot see are the results they are never told about. The second
types *pick up the prescription friday 6pm* into quick add and taps **Reminder** — one of
six chips board 18 draws under *Or file it as* — and nothing happens, because
`Kati.Screens.QuickAdd.kind_tap/1` answers a tag for `"Expense"` and `nil` for the rest.
In both cases the design drew the affordance and stopped one screen short of the thing it
opens.

## Why these two are one brief

They are the same defect and they share one unanswered question: **how does a person get
back**. A truncated group and a re-filed sentence both push somewhere, and if the two are
drawn a month apart the answer gets invented twice. Both destinations are also
re-renders of surfaces the app already has — the See all page is board 19's own group with
the fold lifted, and the four kinds are board 18's cream card with different facts in it —
so drawing them together costs one board each and no new visual language.

Of 18's six chips, one has a page (`Expense` → 124) and one **is** the page you are on
(`Event` — 18 is drawn with that chip filled). Five answer nothing; four of those need
drawing.

## What to draw

| Board | What it is | What it carries |
|---|---|---|
| **19** — edit | the results page, redrawn | a `See all 3 →` row at the foot of a truncated group, and the same page **without** it where a group is not truncated |
| **206** — new | full screen, pushed under 19 | one group's every match — the query still in the field, the group's chip filled, and a foot that says where the list ends |
| **207** — new | reference sheet, pushed under Settings, in board 89's four-panel idiom | the sentence filed as **Reminder**, **Title**, **Habit** and **Note** |

207 is one artboard and not four, for board 89's reason: the four are the same card with
different facts in it, and four separate artboards would invite four different cards.

## Every element

### Board 19 — the row that was specified and never drawn

| Element | Purpose | Glyph |
|---|---|---|
| **See all row** | the last child of a group whose chip count exceeds the rows drawn. Full-bleed inside the group's own gutter, height 44, no card of its own — it belongs to the group above it, not beside it | `arrow_forward` |
| **the number in it** | *the group's chip count*, and on board 19 that is **3** — the same 3 the Screen chip carries. A different number makes the board disagree with itself, and `Kati.ScreenDesignLiteralTest` reads both | — |
| **the label** | `See all 3` in 12.5px/600 `#8A8479` — the weight and colour Home's own trailing *See all* already uses (`Kati.UI.eyebrow/2`, `:trailing`) | — |
| **absence** | the same board with a group that is not truncated and therefore has no row. Draw it; see **States** | — |

The glyph is `arrow_forward` and **not** `chevron_right`. Every card above this row already
wears a chevron meaning *open this result*; a row that opens a **list** must not wear the
same mark. Board 89 already uses `arrow_forward` for exactly this — *3 matches in Screen →*
— so the arrow is the house glyph for a cross-reference and the chevron stays a door.

### Board 206 — one group, all of it

| Element | Purpose | Glyph |
|---|---|---|
| **Back pill, in the flow** | `Search`. Board 19's own in-flow pill, not the floating pushed chrome — see **What it must NOT do** | `arrow_back_ios_new` |
| **The field, carrying the query** | says what this list is a list of. Board 86's unringed field with `hollow` set in ink where the placeholder sits, and 19's trailing clear glyph. **No orange caret**: the caret is the page you type on | `search`, `cancel` |
| **Chip row** | board 19's four counted chips with the group's chip filled. It is the way back to the other groups, so it is not decoration | — |
| **Group eyebrow** | `SCREEN — ALL 12`, mono caps after the **accent** dash. This is the only group on the page, and the accent dash goes to whichever group is first | — |
| **Result rows** | board 19's own group body, with the fold lifted: title cards for Screen, the dated-rows card for Calendar, cream cards for Notes | `chevron_right` per card |
| **Foot line** | where the list ends — an info row saying the count it showed, and, past the cap, that it stopped. This is the state a 60-row list has and a 3-row group never did | `info` |
| **No recent shelf** | the shelf is a shortcut into a *new* search, and this page is one result set. Board 19 is one tap away and keeps it | — |

### Board 207 — the four kinds, four panels

Each panel is board 18 compressed to what differs: the typed sentence with its tokens
tinted, the cream *Kati read that as* card, the chip row with one chip filled, and the
commit label. 18's header, microphone and `close` disc are drawn once at the top and not
repeated per panel.

| Panel | Sentence to parse | Facts in the cream card | Chip glyph |
|---|---|---|---|
| **Reminder** | *pick up the prescription friday 6pm* | `calendar_today` Fri 21 Aug · `schedule` 18:00 · `notifications` 18:00 alert | `check_circle` |
| **Title** | *the long hollow s3* | the title lifted out, and the one thing the sentence does not say: Film or Series | `movie` (`live_tv` on the Series choice) |
| **Habit** | *read 20 minutes every night at 21:00* | `schedule` 21:00 · `repeat` Every day · `label` Personal. **No timezone, no per-habit alert** | `bolt` |
| **Note** | *the hollow is a character, not a place* | `calendar_today` Today, and nothing else. **No alert row** | `edit_note` |

| Shared element | Purpose | Glyph |
|---|---|---|
| **Kind eyebrow inside the card** | `REMINDER` / `TITLE` / `HABIT` / `NOTE`, mono caps — 18 draws `PERSONAL EVENT` and 124 draws `EXPENSE · BOOKS` in the same slot | — |
| **Commit label per panel** | 18's is *Add to Thursday*, 124's is *Save the expense*. Each panel needs its own; a shared *Save* would lose the one thing those two labels do, which is name what is about to exist | — |
| **Inline ringed field** | for a kind the sentence gives nothing to — 124's rule, not a warning row | — |
| **Panel caption** | one line under each, in 89's caption voice, saying what the panel decided | — |

## States

**Resting.** 19 with the row. 206 with a full list. 207's four panels are themselves the
resting state of four screens.

**Active.** The See all row pressed (the row tints, the way a list row does — it is a
control, not a caption). On 206, a chip pressed goes back to that group's own full list,
not to 19. On 207, the filled chip **is** the active state 18 already draws.

**Empty.** This is the one that must not be skipped, and there are two of them.

* **206 on an empty store.** `Kati.ScreenEmptyDatabaseTest` renders every screen against a
  database with nothing in it and a bare push — so 206 will be rendered with no group and
  no query, and whatever it draws then is what a sweep compares against this board. Reuse
  board 89's *Nothing here for "…"* card rather than inventing a second wording.
* **19 without the row.** A group of two matches out of two has nothing to see all of. The
  board must show that, because a single drawn state makes the row unconditional in the
  build — and an unconditional *See all 2* over two rows is the drawing lying about the
  store, which is the thing `Kati.Search.Query.chip_counts/1` exists to prevent.

**Error.** Search cannot fail here: everything it reads is on the device, which is what
89's own offline panel says, so **do not draw a failed search**. What stands in its place
is the cap — a group with more matches than one frame can carry. Draw 206's foot at that
cap. On 207, the equivalent is a kind the sentence carries nothing for: draw it on the
**Habit** panel, because a habit with no time cannot be scheduled at all, and draw it as
124 decided — an inline field ringed in orange, not a warning.

## RTL

**19's row needs a Persian form; 207 does not need a Persian board at all.**

Board 90 (جست‌وجو) already draws the same unpaid promise — `نمایش · ۳` over two cards and
`یادداشت‌ها · ۲` over one — so the row lands there too. This brief does not ask for 90 to be
redrawn, but specify the mirrored row here so 90 inherits it rather than inventing a second
one: label in Vazirmatn, count in DM Mono **Persian digits**, and the arrow flips —
`arrow_forward` becomes `arrow_back`, as chevrons become `chevron_left` and the back pill
becomes `arrow_forward_ios`.

What does **not** mirror: posters and artwork, and the vertical order — Screen still comes
before Calendar before Notes, because that order is `Kati.Search`'s fixed rail and not a
reading direction. The matched substring stays weight-and-ink in Persian exactly as in
English, which is 90's own caption; it is never orange in either.

207 gets no Persian mirror, and the reason is not a shortcut: there is no
`Kati.Screens.QuickAddFa` and board 18 has no Persian twin. A Persian four-kinds sheet
would put a Persian quick add in the app before the quick add itself has one.

## Dark colourway

**Not needed.** Every element here is an existing recipe whose dark values are already in
`Kati.Theme.Palette` — paper `#121110`, card `#1E1D1B`, ink `#F5F2EE` — and the one new
element, the See all row, introduces no colour of its own: it is `#8A8479` text and a
`#C4BDB3`-weight glyph on the group's ground. The one thing that could have needed a dark
board is the match emphasis, and it is deliberately colour-free (weight and ink, never
orange), so it survives the flip by construction rather than by being redrawn.

## Reuse, do not invent

* **The See all row** — board 88 already specified it; Home's `See all` (board 01, via
  `Kati.UI.eyebrow/2`'s `:trailing`) is its type treatment; board 89's *3 matches in Screen
  →* is its arrow.
* **206's field** — board 86's unringed field, with the query in place of the placeholder.
* **206's back pill** — board 19's in-flow pill, relabelled `Search`.
* **206's chips** — board 19's counted chips, `Kati.Components.MishkaChip`.
* **206's rows** — board 19's three group bodies, unchanged. The page is one page with
  three bodies, not three pages.
* **206's foot** — the info-row recipe 19's own waiting state already uses
  (`Kati.UI.SettingsList.note/2`).
* **207's chrome** — board 89: back pill `Settings`, 28px title with a grey subtitle, an
  eyebrow per panel, a closing caption for the board.
* **207's panels** — board 18's field, cream card, fact chips and commit row; 124's inline
  ringed field.

## What it must NOT do

**Do not colour a match.** Board 88's own row: *"600 → 700 and ink. Never orange — orange
only means new/now."* Board 90 says why in full: *"a substring that matched is neither, it
is the thing you asked for."*

**Do not re-order groups on 206, or sort across them.** `Kati.Search`: *"Screen · Books ·
Music · Calendar · Meals · Money · Notes, always, whatever matched… a user learns where to
look; relevance-sorted groups move the target every keystroke."* Within the group the order
is the four tiers, ties broken by recency.

**Do not draw an unbounded list.** `Kati.Screens.SearchSpec` on the three-row rule: *"it
keeps a result list readable, **and** it is what keeps a frame under 256 event handles —
which is `Kati.TapHandleBudgetTest`'s ceiling and a real one, because a screen that exceeds
it kills its own process."* That test's working budget is 180 handles, and 206 is the first
screen in the app whose row count is not fixed by a drawing. The foot is not a nicety.

**Do not give 206 the shared pushed chrome.** `Kati.Screens.Search`: *"The drawing puts the
back pill **in the flow**… Using the shared chrome would draw a second, differently styled
pill on top of the search field."* 206 carries a field, so it inherits that constraint.

**Do not make the See all row a second scope chip.** The chips already narrow:
*"The four counted chips narrow the page to one group — Screen, Calendar or Notes — and
'All' puts all three back."* The row's whole job is the part the chip does not do — lifting
the fold.

**Do not turn the Notes group into a list on 19.** `Kati.Search.Query`: *"One note, because
screen 19 draws one card and not a list."* Board 90 nevertheless counts `یادداشت‌ها · ۲`, so
whether that group gets a row at all is left open below — but 19 itself keeps one card.

**Do not draw a heading over nothing.** Empty groups are omitted rather than worded, which
is screen 96's rule and the one `Kati.Screens.Search.visible_groups/2` follows: *"a heading
over nothing reads as something that failed to load."*

**Do not invent a Habit screen, a Reminder screen or a Note screen.**
`Kati.Notifications.Sources.Habits`: *"A habit is a `Kati.Calendars.Event` with
`kind: :habit` — screen 22 counts them and the calendar stores them, and there is no second
table."* `Kati.Calendars.Event`'s kinds are `[:event, :reminder, :habit, :meal, :air_date,
:money, :note]`; three of 207's four panels file into that one table, and every fact chip
must be a field of it.

**Do not put an alert on the Note panel.** `Kati.Notifications.Sources.Calendar`: *"`:note`
— never a notification. A note is a thing you wrote, not a thing that happens."*

**Do not put a timezone on the Habit panel, or promise it its own notification.**
`Kati.Notifications.Sources.Habits`: *"Read for twenty minutes at 21:00 means 21:00 wherever
you are"* — a habit is wall-clock, always — and *"Four habits at 08:00 is one notification,
and that is the whole design."*

**Do not draw a chip that leads nowhere as though it does.**
`Kati.Screens.QuickAdd.kind_tap/1`: *"`nil` rather than an inert tag, because a chip that
sends a tag nothing answers is reported as a dead tap — and these five are not dead, they
are undrawn."* Whatever 207 leaves undrawn stays `nil` in the build.

## Left open — decide and note which way you went

**1. Is 206 a scoped copy of 19, or a genuinely new list?** The cheap-looking option is not
cheap and is not the same page: `filter` on `Kati.Screens.Search` already narrows to one
group, but the truncation happened earlier — `Kati.Search.Query.run/1` takes three rows
before anything is filtered — so a chip pre-selected on 19 still shows three of twelve. If
the answer is "a scoped copy", say so on the board, because it means the take has to be
lifted for a scoped query and the chip counts have to survive it.

**2. Which groups get a row at all.** Screen and Calendar are lists and obviously do.
Notes is one card by design on 19 and counts 2 on 90. Either the row appears there and 206
draws a stack of cream cards, or Notes is exempt and the count on 90 needs an explanation.

**3. Does Title parse, or hand off?** `Kati.Media.TrackedTitle` needs Film or Series and a
typed sentence rarely says which; board 154's *Add by hand* form already asks in a
segmented control and is already wired from board 89. Handing the sentence to 154 with the
title pre-filled may be the whole panel.

**4. Where a bare Note lands.** `Kati.Books.Note` `belongs_to :book` with
`allow_nil? false`, so a note with no book named cannot be one; the only store for it is a
`Kati.Calendars.Event` with `kind: :note`. Decide whether a sentence that *does* name a
book files under the book instead, and draw whichever one the panel claims.

**5. The four commit labels.** *Add to Thursday* and *Save the expense* both name what is
about to exist. Write four more in that voice.

**6. 206's Calendar and Notes bodies** — inherited from 19 unchanged, or worth a strip at
the foot of 206 the way 89 compresses its four states.

## Acceptance — how we know the drawing can be built from

1. `grep -o 'See all' test/design/screens/19.html` returns a match. Today it returns
   nothing, and the string exists only in 88 and 01.
2. The number in 19's row equals the count on the same board's Screen chip. Both are
   literals `Kati.ScreenDesignLiteralTest` asserts against the rendered tree, so they
   cannot be allowed to disagree.
3. Board 19 shows both the row present and a group without it, so the build knows the row
   is conditional rather than chrome.
4. 206 draws: a back pill reading `Search`, the query in an unringed field, the chip row
   with one chip filled, more than three rows in one group, and a foot. It can then enter
   `Kati.Screens.Gallery`'s `@screens` as `{"206", …, :push}` and take a gate in
   `Kati.ScreenEmptyDatabaseTest` naming its drawn/empty pair.
5. 206's empty state is drawn, so the empty-database sweep has a board to compare against
   rather than a screen inventing a sentence at render time.
6. 207 draws four panels, each naming its chip, its facts and its commit label — enough for
   `Kati.Screens.QuickAdd.kind_tap/1` to gain four clauses and for
   `Kati.ScreenTapSweepTest`'s `@inert_taps` **Backlog** to gain no new line.
7. The Note panel carries no `notifications` glyph and the Habit panel no timezone.
8. Every glyph named here is already in the shipped subset — `arrow_forward`, `arrow_back`,
   `arrow_back_ios_new`, `search`, `cancel`, `chevron_right`, `info`, `check_circle`,
   `movie`, `live_tv`, `bolt`, `edit_note`, `schedule`, `calendar_today`, `notifications`,
   `label`, `repeat` — so `mix kati.gen.icons` needs no new codepoint.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. This screen takes the
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
