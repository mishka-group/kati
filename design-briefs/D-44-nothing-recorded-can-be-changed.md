# Every health record is write-once

> **Two new artboards and three edits** · ticket `D-44`

Health holds two kinds of record a person makes by hand — a weight and a goal — and
**neither of them can be opened, corrected or removed**. Screen 109's Entries rows carry a
date, a weight and a delta and no affordance at all: `grep -c chevron_right
test/design/screens/109.html` returns **0**, and `Kati.Screens.Weight.entry_row/1` matches
the board exactly by having no `on_tap`. Screen 104's cards carry no control either —
`card/1` builds a pace pill, a title, two figures, a bar, a projection and a footnote, and
nothing in it is tappable. So a weight typed wrong on a stepper that opens at your last
reading stands forever, and a goal whose target was wrong stays wrong until its period
closes and it silently drops off the page. Both resources already permit the fix:
`Kati.Health.Reading` and `Kati.Goals.Goal` each declare `defaults [:read, :destroy,
create: :*, update: :*]`, and `grep -rn 'Ash.destroy' lib/ --include=*.ex` names no health
resource at all. The destroy action exists, has never been called, and there is nowhere in
the drawn set it could be called from.

## Why this is one brief and not three

It is the same problem on both record types, and it needs the same three decisions made
**once**, not twice in two different ways:

1. **What affordance a list row of past facts gets** — a row tap, an overflow menu, or a
   long press. Whatever 109's rows get, 104's cards have to agree with, or Health teaches
   two gestures for one idea.
2. **What a record's detail page looks like** — the chrome, what is editable, what is a
   stated fact, and where the destructive control sits.
3. **How a destructive confirmation reads when the row is a number you wrote** — not a
   library, not an account, not 418 titles. One weighing.

Screen 106's Custom period belongs here rather than in a brief of its own for a structural
reason: **190 has to carry a period window field anyway**, because `starts_on` and
`ends_on` are what a goal edit changes when you move a deadline — and that same field is
what 106's *Custom* segment has been promising since it was drawn. `Kati.Screens.NewGoal`
answers it today with `window(:period_custom, today), do: {today, Date.add(today, 29)}`: a
silent thirty days. `D-15-new-goal` already left this open in as many words — *"what the
custom end date opens (no date picker exists in the 62-screen set)"* — and it has stayed
open ever since. Drawing it twice, once for the editor and once for the sheet, is how the
two drift.

**Explicitly not in scope: redrawing 107.** Its four states and their three actions are
already drawn, and `Kati.AppReachabilityTest` puts it on `@no_route` as *"screen 104's
states, in 27's manner"* — the class of screen `D-34` says must **not** be given a door.
`Kati.Screens.GoalStates` makes the same argument from inside: *"a reference sheet draws
all four states at once, unconditionally, and gating* Completed early *on a goal that had
actually finished would show four states on one device and one on another"*, and *"two of
them would be destructive if they were live — `Make it 48` rewrites the target of a real
goal — which is a second reason the sheet is a sheet."* Wiring those four states onto 104's
live cards is the code half. **This brief only gives 104 a card that can carry a tap**, and
gives that tap somewhere to land.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **189** | **NEW — One weight reading** | The page behind a row on 109's Entries card. The weight on 111's stepper, the date and time as stated facts, the delta against the reading before it, the Note row in the state it actually has, and a delete band. |
| **190** | **NEW — One goal** | The page behind a card on 104. The target on 106's stepper, the kind and its *what counts* sentence as stated facts, the period **with its window**, the repeat row, the progress figure, and a delete band. This is where 107's *Make it 48* lands when it is finally live. |
| **109** | **edit** | The Entries rows gain the affordance. The geometry problem is that the trailing slot is **already taken by the delta** — `SettingsList.trailing(delta/1)` — so a chevron cannot simply be appended. Plus 109's empty state, which the delete affordance creates and 109 has never had. |
| **104** | **edit** | The card gains the affordance. Its two corners are already spoken for — pace pill leading, drift figure trailing — so an overflow disc has nowhere obvious to sit. Annotate that **108 takes the identical affordance**. |
| **106** | **edit** | A window field under the *By when* segmented control, drawn in the **Custom** state, which no board has ever drawn. The default 30 days becomes visible instead of silent. |

## 189 — One weight reading, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Weight` | 189 is pushed from 109 | `arrow_back_ios_new` |
| **Save** pill, ink, 38pt high, radius 19, opposite the pill | Screen 118's header pair. The alternative chrome is screen 31's — `close` disc, centred *Edit event*, ink Save — and 31 is the app's only other editor-with-a-delete. Pick one; see Left open | — |
| Hero numeral + unit | 111's hero verbatim: DM Mono 32/500 with the unit at 15px beside it, *"the unit sits inside the numeral rather than as a separate label, so the hero reads as one value"* | — |
| Stepper `− 76.0 kg +` | 111's stepper, one tenth of the **display** unit per press. `Kati.Health.Reading` stores grams and `grams` is `constraints: [min: 1]`, so the stepper floors at one step and never at zero | `remove` / `add` |
| **Taken** — `16 August, 07:42` | `taken_on` and `taken_at`, both real columns. Draw them as **stated facts, not a picker** — see *What it must NOT do* | `event` |
| **Change** — *0.4 kg down from 13 Aug* | `Reading.delta/2` against the reading before it, and **nothing else**. `nil` for the oldest reading in the log, which draws no line at all rather than `0.0` | `arrow_downward` |
| **Note** row | The same row 111 draws — *Optional — after a run, before breakfast…* — and `Kati.Health.Reading.note` is a real column that nothing has ever written. Draw it **empty**, and say on the board whether it keeps a chevron it cannot honour | `sticky_note_2` |
| The privacy line | 109's own cream note is on the parent, not here. If 189 restates it, it is the same sentence or none | `info` |
| **Full-width rule**, then the delete band | Board 129's rule, and its reason: *"merge takes the single ink button while replace sits below a full-width rule as an outlined red row, so they are never two buttons of equal weight"* | — |
| **Delete this reading** | Screen 31's control exactly: 48pt, radius 24, `Palette.red_ring()` at 1.5px, **no fill**, 18pt glyph and 13px/700 label both `Palette.red()`. `Kati.Screens.EventDetail` states the rule — *"Outlined in red rather than filled: destructive, and one tap away from nothing. The design gives it no background at all."* | `delete` |
| The confirmation | See *The confirmation*, below. It is a band on this board, not a third artboard | `error` |

## 190 — One goal, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Goals` | 190 is pushed from 104 | `arrow_back_ios_new` |
| **Save** pill | Matching 189, whichever chrome the pair takes | — |
| Title — *52 books this year* | Derived, never typed: `Kati.Goals.Goal.title/1` is `"#{target} #{unit(kind)} #{period_phrase(period)}"`. Moving the target **rewrites the heading above the field**, and the board should show that it does | — |
| **Counts** — the *what counts* sentence | `Goal.counts/1`, beside the kind in the same table. 104 prints it on every card and 190 must not drop it | `info` |
| **Kind** — a stated fact, not a chip field | See *What it must NOT do* | `label` |
| Target stepper `− 52 +` | 106's stepper. `target` is `constraints: [min: 1]`, so it floors at 1 | `remove` / `add` |
| Figures `38 / 52` and the bar | 104's own `figures` and `Goals.bar/1` — the sheet at 107 already borrows both rather than redrawing them, and 104 wins | — |
| **Progress** — read-only for now | `Goal.progress` is stored and `Kati.Goals.recount/1` *"was never written"*. Two of the ten kinds — `meals cooked`, `habit days` — have no source at all, so this is the only page in the app where a hand-kept count could ever be corrected. **Leave room for the control; do not draw it** | `trending_up` |
| **Period** — Week / Month / Year / Custom | 106's segmented control, same four segments, same order | — |
| **Runs** — the window | `starts_on` – `ends_on`, printed as a pair. Always visible, even for Year, because *"a goal set in March runs to 31 December"* and the card is the only place that says so. Editable in the Custom case; opens the window picker | `event_available` |
| **Repeat each period** + its per-period sub-line | 106's row, and the sub-line is `NewGoal.restart_line/1`'s, which already has a Custom answer nothing has drawn: *Restarts the day after it ends* | `repeat` |
| Rule, then **Delete this goal** | Same recipe as 189, same words shape, different consequence sentence | `delete` |

## The window picker, and what 106 gains

The same field twice, drawn once.

| Element | Purpose | Glyph |
|---|---|---|
| **Runs** row on 106, under *By when*, **only when Custom is selected** | The board draws the segmented control and then goes straight to the repeat card. Draw the gap being filled, with the default already in it — `5 Sep – 4 Oct`, which is `{today, Date.add(today, 29)}` made visible instead of guessed | `calendar_month` |
| The two dates | `starts_on` and `ends_on` are both `allow_nil?: false`. A window is a pair, and a picker that returns one date leaves the other invented | `event_available` |
| What the picker **is** | Screen **16** is the month grid and it already exists, already mirrors, and already handles Shamsi. Do not draw a second calendar, and do not reach for a system date picker — Mob has no date input, which is #45 | `calendar_month` |
| The repeat sub-line under Custom | *Restarts the day after it ends* — true only once the window is real, and it has never been drawn beside one | `repeat` |

**A geometry warning for 106.** Its caption already argues that the commit lives at the
foot rather than in the header because *"the sheet is long enough that a top-right Save
would scroll out of reach"*. A window field pushes `Save goal` further down again. Draw the
Custom state at its real height and prove the button is still reachable, or say on the
board what gives.

## The affordance — the decision that spans all three edits

Three candidates, and the evidence for each is already in the tree:

- **Row tap into a pushed screen.** The house rule is *a chevron means leads elsewhere*, and
  189 and 190 genuinely are elsewhere — so a chevron would be honest. The cost is 109's
  trailing slot: `entry_row/1` puts the delta there, and the board draws it at `#B4553C` —
  which is `Palette.red()` itself. A red chevron beside a red delta, or a delta pushed
  inward to make room, are both real losses. Decide which.
- **An overflow menu.** `Kati.UI.Menu` is **built** — a 250pt panel of 46pt rows in
  `Kati.Components.Anchored`, ledgered as `K-18` — so this costs no native work and keeps
  the mono column clean. The cost is a disc per row, and on 104's card both corners are
  already occupied by the pace pill and the drift figure.
- **Long press.** Cheapest in pixels and the most dangerous. `D-34` records the collision in
  full: #15 wants long press on an episode row (rate this episode) and #19 wants it on a
  poster tile (select), and *"if long press cannot carry both meanings, one of them needs a
  different affordance"*. Adding a third meaning here decides that question by accident. And
  `D-34`'s other rule applies whichever way you go: **a gesture with no visible hint is not
  an affordance; it is a secret.**

## States: resting, active, empty, error

Kati's sweeps compare an empty state against a board, so an undrawn empty state becomes an
untested one. `Kati.ScreenEmptyDatabaseTest` gives a screen exactly three shapes: **it falls
back** to its own drawing, **it has an empty board**, or **the design draws no empty board
for it**. Both parents in this brief are in the first shape today, and the delete control is
what makes that shape a lie.

**Resting.** 189 with a reading loaded; 190 with a live goal loaded; 109's Entries card and
104's cards with the new affordance present, and — if it is a gesture — the hint that
teaches it.

**Active.** The affordance opened. If it is an overflow menu, draw the panel: the trigger,
the 250pt card at radius 18 under `shadow_card`, and its two or three rows without
chevrons, because *"a menu item performs an action rather than promising a screen with more
of the same on it"*.

**Empty — four of them, and the first two are the load-bearing pair.**

1. **109 with no readings.** This state has never once been rendered.
   `Kati.Screens.Weight.entries/0` is `case stored() do [] -> WeightSample.entries()`, so
   deleting your last reading brings **the drawing's four back**, dated 6–16 August, as
   though they were yours. The picture already exists — 110's *No entries · Nothing logged
   yet · One reading starts the record. Two make a trend. · Log a weight* — and it is a
   **band** on a states sheet with no route. Say on the board that 109 takes that band, the
   way Library takes screen 27's *Empty — nothing added yet* band and is read by
   `Kati.DesignLiterals.band/3`.
2. **104 with no goals.** Identical shape: `Goals.goals/0` falls back to `drawn_goals/0`, so
   deleting your last goal resurrects the drawing's three. Here the answer is easier and
   already drawn **and built** — screen **105** and `Kati.Screens.GoalsEmpty`, whose sentence
   is *"No goals. Kati will still count everything."*, described in its own moduledoc as
   *"verbatim from the brief and protected in review"*. Home already does exactly this with
   screen 139. Say that 104 draws 105 whole.
3. **189's Note row with no note.** Every reading has one, because nothing writes the column.
4. **190's window when the period is not Custom.** Derived, stated, not editable — and the
   same row in the Custom case, editable. Two drawings of one row.

**Error.**

- **A save that refuses.** 106's recipe: `NewGoal.save_notice/1` puts the sentence in
  `Palette.red()` at 13px **above** the commit, *"between the person and the control they
  just pressed"*, and reserves a zero Spacer when there is none so the field above does not
  shift. 189 and 190 use the same placement.
- **A delete that does not land.** `Kati.Write`'s contract, in its page form rather than its
  sheet form — `Kati.Screens.Goals` states it: on a page *"the switch shows what the store
  says and snaps back when a write did not land"*. For a delete that means the parent
  re-reads and **the row comes back**. Draw where that sentence goes, or the failure is
  indistinguishable from a success.

## The confirmation

This is the third decision, and it has to be sized to what is actually being destroyed.
The app's existing destructive copy is written for catastrophes — screen 40's *Delete
everything · Cannot be undone*, screen 129's *Deletes all 418 titles, every note and every
session*. **A weighing is not that**, and borrowing that voice for one row of a log teaches
people to ignore it.

What the sentence must name instead is the real consequence, which is arithmetic:

- **A deleted reading moves its neighbours' deltas.** `Reading.delta/2` compares a reading
  with the one before it, so removing 13 Aug makes 16 Aug's `−0.4` a delta against 09 Aug
  instead.
- **Deleting the newest or the oldest reading rewrites the hero.**
  `Kati.Screens.Weight.latest/0` takes `hd(readings)` and `List.last(readings)`, so both the
  32pt figure and the `DOWN FROM 78.4 ON 4 MAY` caption move.
- **Deleting the last one empties the log** — see the empty states above. The confirmation is
  the only place a person can be told that before it happens.
- **For a goal**, the consequence is the whole card and its history. There is nothing beneath
  it: `Goal` owns no children and nothing references it.

Name the record in the sentence — *Delete 76.4 kg from 13 August?* — because the row is a
number you wrote and a confirmation that says *this item* is asking about nothing.

## RTL — does this need a Persian mirror?

**No new Persian artboard, and one mandatory annotation.**

**What mirrors, and must be said in prose on 104's edit:** board **108** (اهداف) draws the
same three goal cards in Persian, and it **takes the identical affordance**. If 104's cards
gain an overflow disc, 108's gain one on the mirrored corner; if they gain a tap, so do
108's. Two locales teaching two different gestures for one action is the failure this
annotation exists to prevent.

**What does not need a mirror drawn here:** 189, because board **115** (سلامت) is the
Persian weight-and-doses page and it draws **no Entries list at all** — there is no Persian
109 for a row affordance to land on. And the Persian half of this area has a prior gap of
its own: there is no `*_fa` module for `LogWeight` or `NewGoal`, and both 115's and 108's
`add` discs push the **English** sheets. Drawing a Persian record page while the Persian
*create* sheet is still English would mirror the wrong half first.

**Specify in prose so the mirror is buildable later:** the container gets `dir="rtl"` and
the whole grid mirrors; the back pill's glyph becomes `arrow_forward_ios` and chevrons
become `chevron_left`; **the vertical order never reverses** — hero above stepper, stepper
above the date, delete always last; the stepper keeps `−` on the leading edge, which in RTL
is the right; weights keep DM Mono with Persian digits and the Persian decimal separator
`U+066B`, which is what holds 115's column aligned; and the signed delta keeps its sign on
the leading edge so `−0.4` does not read as `0.4−`. Dates go Shamsi — and 108's own note is
the rule the window field has to obey: *a yearly goal ends at the end of اسفند, not on 31
December.*

## Dark colourway

**Not needed as separate artboards — needed as one check.** Neither 189 nor 190 introduces a
surface the dark palette has not already answered: card, paper tile, stepper, segmented
trough, settings row and cream note, all of which 110's own `Dark` band already shows for
this exact page.

The one thing to verify rather than assume is the **outlined delete row**, because it is the
first control in Health that carries red as a whole control rather than as a small figure.
`Palette.red` is `0xFFB4553C` in **both** columns and `red_ring` is `0x4DB4553C` in both — the
value does not lighten for dark, it just lands on `#1E1D1B` instead of `#FBFAF8`. Draw the
delete band once in dark and confirm the ring is still visible; nothing else on either board
needs a dark frame.

## Reuse, do not invent

- **189's hero, stepper and Note row** are screen **111**'s, unchanged.
- **190's stepper, segmented control and repeat row** are screen **106**'s, unchanged — including
  `restart_line/1`'s per-period sub-line.
- **190's figures and bar** are screen **104**'s. Screen 107 already established the precedent
  and the rule with it: *"where 104 has a public function the sheet takes it and 104 wins."*
- **The window picker** is screen **16**, the month grid. There must not be a second calendar
  in this app.
- **The delete control** is screen **31**'s *Delete event*: 48pt, radius 24, `red_ring` at 1.5px,
  no fill.
- **The rule above it** is board **129**'s, and so is the rule it enforces: the destructive
  control and the commit are never two buttons of equal weight.
- **The refusal line** is screen **106**'s `save_notice/1`, above the commit.
- **The overflow panel**, if that is the affordance, is `Kati.UI.Menu` — already built, already
  ledgered as `K-18`. Do not draw a new popover.
- **Every row** is the standard list row — 30×30 paper tile, 13.5px/600 title, 11.5px sub — and
  **a chevron means *leads elsewhere***. 190's *Kind* and *Counts* rows must therefore not
  carry one.
- **The empty states** are borrowed, not invented: 110's *No entries* band for 109, screen 105
  whole for 104.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not put a unit switch on 189.** 111 has one and it is defensible there — `Kati.Screens.LogWeight`:

> *Changing it here is a correction, not a preference.* You weighed yourself on a scale set
> to pounds and typed pounds; the switch is you saying which number you just read.

That argument does not survive the move to a stored record. `Kati.Health.put_unit/1` writes
to `Mob.State` and is **app-wide** — *"Converts nothing"* — and `Reading` has no unit column
at all. A switch on 189 would silently retune every figure on 109, the hero included, while
appearing to be about one row. Print the unit as a label.

**Do not draw a scale, a sync, or an import.** `Kati.Health`:

> There is no integration point in this domain, no `source` column with a `:healthkit` value
> waiting to be filled in, and no sync. Adding one later means adding a column and saying so;
> leaving room for one now would be implying a road map the app has not committed to.

**Do not offer to fill in a missing day, and do not interpolate anything.** `Kati.Health.Reading`:

> there is one row per weighing and nothing between them, so `delta/2` compares a reading
> with the one before it and never interpolates.

**Do not put a date picker behind 189's Taken row.** That is a real gap with its own name —
*logging a weighing at a time other than now* — and its own blocker: Mob has no date input,
#45, and `save_reading/1` writes `Kati.Time.today()` and `Kati.Time.now()` unconditionally.
189 prints the stored date and time as facts. (The window picker on 190 and 106 is a
different case: `starts_on` and `ends_on` are both `allow_nil?: false` and have no
defensible default, so they get screen 16's grid. If that grid-as-picker lands, the weighing
date becomes drawable too — but not here, and not by implication.)

**Do not draw a kind picker on 190.** `progress` is stored, and `Kati.Goals.Goal` says what
that means:

> `progress` is therefore a column that a domain **may** move. Where a real count exists,
> `Kati.Goals.recount/1` writes it; where none does, the number is the user's own.

A books goal at 38 turned into a films goal would carry 38 finished books across as 38
films, and `counts/1`'s sentence — the D-14 answer, held beside the kind in the same table —
would change underneath a number it no longer describes. Kind is a stated fact; changing
your mind is delete and create.

**Do not derive 190's window from its period.** `Kati.Goals.Goal`:

> Deriving the window from `period` would silently move the deadline of every goal set
> mid-period.

**Do not let a Save on 190 write to more than one goal.** This exact defect has already been
found and fixed once on 104 — `Kati.Screens.Goals`:

> Toggling it on a page of four goals rewrote four rows to answer something asked about one,
> and there was no way to tell from the screen which goal you had changed, because the row
> never named one.

190 is a page **about one goal**, which is the shape that makes it safe. Nothing on it may
address the set.

**Do not compute an adjective anywhere in the delete copy.** `Kati.Goals`:

> *On pace to finish 106 of 120*, not *you're falling behind* … Nothing here computes an
> adjective.

A confirmation that says *you'll lose your progress* breaks the one rule this area is built
on. State the arithmetic.

**Do not say a deleted goal "moves to the archive".** Board 107 says it twice and
`Kati.Screens.GoalStates` repeats it — *"the period is over, its card goes to the archive
intact"* — and there is no archive. `Kati.Goals.Goal` declares exactly one named read,
`:live`, filtered `ends_on >= ^arg(:today)`, and `Kati.Screens.Goals` is its only caller.
Nothing anywhere reads a closed goal.

**Do not solve the closed-goal problem by inventing an archive board.** Note it and leave it
— see Left open. It is why the door 104 gains cannot reach the goals two of 107's four bands
are about.

**Do not give 107 a door, and do not redraw it.** `D-34`'s list is explicit about the class:
states of screens and reference sheets *"are not places in the app … giving these doors
would be wrong, not merely unnecessary."*

**Do not draw a fourth pace pill on 104.** `Kati.Screens.GoalStates` records where that
change belongs:

> `impossible_pill/1` is drawn here at the board's `Palette.red/0` on
> `Palette.red_wash_strong/0`; a fourth pace is the change 104 would have to make first.

The pill already exists on 107. 104's redraw only has to leave room for it beside the new
affordance, not invent it.

**Do not let the card's tap and the state's buttons be the same thing.** When 107's
*Impossible* state is finally live on 104, that card carries *Make it 48* and *Leave it* as
buttons **and** a tap into 190. A card that is entirely tappable with two buttons inside it
is a geometry the board has to resolve, not a detail to leave to the build.

**Do not draw a second confirmation style.** Board 129 settled the shape and it holds here at
a smaller scale: a full-width rule, an outlined red row below it, and never two buttons of
equal weight.

## Left open — decide and note which way you went

- **The affordance itself**, and therefore the same choice on 109's rows, 104's cards and
  108's cards. If it is long press, say explicitly what that does to `D-34`'s unresolved
  collision.
- **What happens to 109's trailing delta** if the affordance takes the trailing slot: does the
  delta move inward, or does the chevron go somewhere a chevron has never been?
- **Which editor chrome the pair takes** — screen 118's pushed back pill plus a 38pt ink Save,
  or screen 31's `close` disc, centred title and Save. 31 is the app's only other editor with
  a delete at its foot, which is an argument; 189 and 190 are pushed from pages, which is the
  other. They must match each other whichever way it goes.
- **Whether the confirmation is a band, a sheet or an inline two-step.** Drawn here as a band
  because no number is reserved for a third artboard; a sheet would also be defensible and
  `Kati.UI.Sheet` exists.
- **Whether 189 keeps the Note row's chevron.** The column is real and unwritable — Mob has no
  text input, #45 — and a chevron that opens nothing is the exact defect
  `D-31` was written about on screen 89.
- **Whether 190 gets a progress control.** It is the only page in the app where a hand-kept
  count for `meals cooked` or `habit days` could ever be corrected, and it is entangled with
  `Kati.Goals.recount/1`, which was never written. Leave the space; say whether it is a field
  or a fact.
- **Where a closed goal is reached from.** 104 shows only `ends_on >= today`, so 190 is
  unreachable for exactly the goals 107's *Completed early* and *Period rolled over* bands
  describe. An archive is a screen this brief has no number for; record which board should own
  it.
- **Whether the window picker returns a range in one pass or two dates in two**, and whether
  screen 16's grid is entered as a picker or a second, smaller grid is drawn inside the sheet.
- **The exact deletion copy for each of the two record types**, and whether the confirmation
  names the count it is about to change (*two deltas recompute*) or only the record.

## Acceptance — how we know the drawing is complete enough to build from

1. Every control on 189 and 190 names a stored column or a destination on the board.
   `Kati.Health.Reading` and `Kati.Goals.Goal` between them hold every value these two boards
   write; a field with no column behind it is a defect in the drawing, not a migration to
   write.
2. **One affordance, drawn three times** — on 109's row, on 104's card, and annotated onto
   108's — and it is the same gesture in all three. If it is a gesture rather than a control,
   its hint is drawn.
3. 109's exported board contains the affordance and its Entries rows still print a delta that
   is legible beside it. 104's exported board contains the affordance and still has room for
   107's `Palette.red` pace pill.
4. **Both empty states are drawn or explicitly delegated by name**: 109 to 110's *No entries*
   band, 104 to screen 105 whole. Neither may be left to fall back to its sample once a delete
   exists, and the board must say which of the three `Kati.ScreenEmptyDatabaseTest` shapes each
   parent is now in.
5. **The window field appears on 106**, in the Custom state, with `5 Sep – 4 Oct` or its
   equivalent visible rather than assumed — and `Save goal` is still reachable at that height.
6. `106.html` and `190` draw the **same** window row. `grep` should find one shape, not two.
7. Both delete bands exist, both sit under a full-width rule, both are outlined and unfilled,
   and neither is drawn at the weight of a commit.
8. **The confirmation names the record and states the arithmetic** — the neighbouring deltas,
   the hero, or the empty log — and contains no adjective about the person reading it.
9. The refusal is drawn once per board, above the commit, in `Palette.red()`.
10. The board says nothing about an archive, and nothing about a scale, a sync or a source.
11. 107 is untouched. No door is drawn into it, and nothing on 104 or 190 redraws its bands.
12. Every new glyph is checked against the shipped subset before it is drawn — `Kati.Icons`
    carries 140 and `mix kati.gen.icons` reads the boards, so `monitor_weight`, `edit`,
    `delete`, `repeat`, `event_available`, `calendar_month`, `sticky_note_2`, `label` and
    `trending_up` are all already in it, and a symbol that is not will need the font rebuilt.

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
