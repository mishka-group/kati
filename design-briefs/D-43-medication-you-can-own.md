# Medication is a page you can only read

> **Mixed — two new boards, one board edit** · ticket `D-43`

Screen 112 is a complete medication page. It lists today's doses in clock order, ticks
them, names four prescriptions with their schedules, shows the reminder as the
notification it becomes, and carries both honesty notes in the flow of the page. Every
part of it that would let a person *own* a prescription opens nothing. A man holding a new
box of tablets taps the `add` disc in the header and the page does not move — no
new-medication sheet is drawn anywhere in the set. He taps *Levothyroxine* to change the
time, and the chevron on that row leads nowhere — no per-medication page is drawn either.
He wants the 21:00 nudge to stop, or to start, and there is no control on any board that
decides whether it fires. `Kati.Health.Medication` has `create: :*` and **nothing in
`lib/` calls it**: `grep -rn 'Ash.create' lib/ --include=*.ex | grep -i medication` is
empty, and the only path that has ever put a row in `health_medications` is
`Kati.Backup.Catalog`'s restore. So on every fresh install the four doses on that page are
`Kati.Health.WeightSample.doses/0` — the drawing's own four, `id: nil`, and, as the
screen's moduledoc puts it, *"none of the four is a row anything can be written against."*

## Why this is one brief and not three

One problem stated three ways. The `add` disc has no form behind it, the four chevrons
have no page behind them, and the reminder is drawn as the notification it becomes with
nothing that decides whether it fires — but they are one flow, and the second board
absorbs the third. `times`, `active` and the reminder switch all live on the
per-medication page: `times` **is** the reminder (`Kati.Notifications.Sources.Health` arms
from that field and reads nothing else), and `active` is what takes a medication off both
the Schedules group and the reminder list at once. Drawing the reminder switch separately
would draw the same card twice and let the two copies disagree.

The stakes are shared as well. The write that does not exist is the same write in all
three places, and the thing that gets armed at the end of it is
`quiet_hours: :exempt`, `priority: :high` — the loudest notification Kati sends, from a
field no screen in the app can set.

## What to draw

| Board | What it is | What it carries |
|---|---|---|
| **187** — new | **Add a medication.** Board 119's modal sheet, a different noun | close disc, centred title, ink Save pill; Name, Dose, Schedule, Times, Instruction; 119's preview band showing both rows this becomes; the no-times note; the refusal |
| **188** — new | **One medication.** A pushed page that opens on 187's field stack, pre-filled | the five fields again as values; **Reminder** — the switch, what it will actually say, and the two facts the code has already decided; **Taking** — the `active` switch; the destructive delete at the foot in 31's manner |
| **112** — edit | Two frames under one number, in board 110's manner | **resting**, with the `add` disc and the four chevrons annotated with their destinations and the reminder block given an honest caption; **empty**, *No medications yet*, which D-19 asked for in 2026 and nobody has drawn |

The 112 edit is mostly annotation and one new state, and that is deliberate: the page is
right. What it lacks is destinations, one caption, and the frame that shows what it looks
like before anybody has typed anything.

## Every element, and its glyph

Every symbol named below is already in `Kati.Icons`' map, so this brief costs no
`mix kati.gen.icons` run — which matters, because
`test/design/material_symbols.codepoints` *"is not in the repo and never was"*.

### Board 187 — Add a medication

Board 119's chassis exactly: scrim `rgba(26,25,23,.42)`, sheet at the bottom with radius
`26px 26px 0 0`, padding `18px 21px 34px`, and a header of three parts. 119's field labels
carry no glyphs and neither do these — a glyph column beside a labelled trough is 119's
one deliberate omission.

| Element | Purpose | Glyph |
|---|---|---|
| Close disc | 36px, `#FBFAF8`, `shadow_button()`. Abandons the sheet and writes nothing | `close` |
| Sheet title `Add a medication` | 119's centred 15px/700 title | — |
| Save pill | ink, height 34, radius 17, 12.5px/700. **The only commit** — no 54px primary at the foot; 119 has none either | — |
| **Name** | `Kati.Health.Medication.name` is the resource's one `allow_nil? false` string. 119's labelled inset trough — 44px, radius 14, `#EFECE7`, `inset 0 0 0 1.5px rgba(26,25,23,.09)` — with the orange caret | — |
| **Dose** | free text. `50 mcg`, `1000 IU`, `65 mg`. Draw it as a trough with a real value in it, never as a number field beside a unit menu — see *What it must NOT do* | — |
| **Schedule** | the user's own sentence, one line: `every morning, 08:00`. This is the field the app promises not to understand | `event_repeat` |
| **Times** | the structured half, and the only field the reminder reads. A chip row of `HH:MM` values with a trailing dashed add-disc, in 31's *Add someone* manner: 34px, radius 17, `1.5px dashed rgba(26,25,23,.2)` | `schedule` · `add` |
| **Instruction** | `before food`, `with water`. Optional, and it is printed **twice** — under the dose on 112, and inside the notification itself, because *"an instruction that only appears in the app is an instruction nobody reads at 21:00"* | `description` |
| **Preview band** | 119's band, and the strongest reuse in this brief. Two rows, both composed by functions that already exist: the Schedules row from `Medication.schedule_line/1` — `Levothyroxine` / `50 mcg · every morning, 08:00` — and the today card from `dose_line/1` — `08:00` / `Levothyroxine` / `50 mcg · before food`. Label it as 119 labels its own: *this is how it will look* | `medication` |
| **No-times note** | a quiet line under Times: a medication with no time set is still recorded and simply never reminds. This is a drawn state, not an edge case — see below | `notifications_off` |
| **Refusal line** | Save pressed with no name. Names what is missing, then says **nothing was written**. `Kati.Write`'s contract and `Kati.WriteContractTest` already enforce it on the host; the board is what lets it be seen | `error` |

### Board 188 — One medication

A pushed screen: scroller `padding: 64px 21px 40px`, floating back pill reading
`‹ Medication`, no dock, frame closes at 40.

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Medication` | the standard pushed-screen pill | `arrow_back_ios_new` |
| Large title | the medication's own name, `Levothyroxine`, 28px/700, `-.03em` | — |
| Mono subtitle | `50 MCG · ACTIVE`, DM Mono 11.5px `#A9A29A`, in 112's header manner | — |
| Eyebrow `The prescription` | accent rule, DM Mono caps | — |
| **The five fields** | 187's stack, pre-filled and editable in place. Same troughs, same labels, same order — this is one form drawn twice, which is why 187 and 188 are one brief | — |
| Eyebrow `Reminder` | a **quiet** eyebrow — `#C4BDB3` rule — because this section states as many facts as it offers choices | — |
| **Remind me** — switch row | the missing control, and the whole of the third gap. Board 150's switch: 46×28 track, radius 14, `#1A1917` on and `#DCD7CF` off, 22px knob `#FBFAF8`. Its second line names what it arms: `08:00, 13:00` | `notifications` |
| **What it will say** | the notification, drawn small, in 51's manner and composed the way the code composes it: title is the medication's name for a lone dose and `3 doses` when others share the time, body is `dose · instruction` joined with ` · `. Not a text field — see *What it must NOT do* | — |
| **Shared with** row | `08:00 · with Vitamin D and Iron`. A fact, no chevron. It exists because the switch will otherwise read as *a notification for this tablet*, and it is not one | `group` |
| **Quiet hours** row | a fact, no switch: medication is the one kind of reminder Kati never moves out of the night window. Second line: `21:00 stays 21:00` | `bedtime` |
| **No times** state | when `times` is `[]`: the row reads *This one never reminds*, the switch is absent rather than off, and the sentence says a schedule with no clock in it is a legitimate thing to have | `notifications_off` |
| Eyebrow `Taking` | quiet eyebrow | — |
| **Stop taking** — switch row | `active`. Off takes it off 112's Schedules group and off the reminder list in one move, and **keeps every dose already recorded**. Second line says so | `pause_circle` |
| **Delete this medication** | 31's destructive control verbatim: 48px, radius 24, `1.5px solid rgba(180,85,60,.3)`, glyph and label both `#B4553C`. Sits alone at the foot, below everything | `delete` |
| Delete confirmation | what it takes with it, in words, and 27's undo bar under the result | `undo` |

### Board 112 — the edit

| Element | Change | Glyph |
|---|---|---|
| Header `add` disc | **no pixel change** — an annotation naming 187 as its destination. It has been drawn and inert since the page shipped | `add` |
| The four Schedules rows | **no pixel change** — an annotation naming 188. The chevron was always honest about being a link; it just had nothing on the other end | `chevron_right` |
| Reminder block caption | **new.** One DM Mono line under the notification picture: `SET ON EACH MEDICATION · 3 OF 4 REMIND`. Not a switch — the switch belongs on 188, one per medication, and a page-level switch would be a fifth thing that can disagree with the four | — |
| Failure line | **new, and overdue.** `save_notice/1` renders `Nothing to save yet.` in `Palette.red()` between the list and the two verbs, and no board draws it. Draw it once | — |
| **Empty frame** | the second frame. Screen 139's house recipe — *"glyph tile, sentence, one ink action, one quiet alternative"* — with the medication noun | `medication` |
| Empty subtitle | **`SUNDAY 16 AUGUST · NO DOSES` is a literal that has to be drawn.** `subtitle/1` asks the store and falls back to `WeightSample.doses_subtitle/0`, which is the fixture string `SUNDAY 16 AUGUST · 4 DOSES`. An empty page cannot print that, and a sweep cannot check a string nobody drew | — |
| Empty action | ink pill `Add a medication`, and under it the quiet alternative `or restore a backup` — which is true: `health_medications` is a member of the backup format and restore is the only writer that exists today | `add` |

## States

Kati's sweeps compare an empty state against a board — `Kati.ScreenEmptyDatabaseTest` reads
the same literals with nothing stored — so **an undrawn empty state becomes an untested
one**, and screen 112 is currently in that file's `fallbacks` list, meaning the thing it is
held to when the database is empty is its own fixture. Four states matter, and two of them
are the point of the ticket.

- **Resting.** 187 with a real value in every trough and the caret in Name, so the preview
  band has something to preview. 188 pre-filled for Levothyroxine with the reminder **on**,
  because a person usually arrives at this page to change something rather than to read it.
  112 unchanged.
- **Active.** 188's switch in both positions — on with its times printed, off with the
  second line saying what stops. 187's Times chip row with one chip and with three, since
  a single time and a list are different shapes.
- **Empty — three, and they are the ones that have never existed.** (1) **112 with no
  medications**, which `D-19-medication.md` listed under *States to draw* and which no
  board in the set carries: today the page prints four tablets belonging to nobody.
  (2) **188 with `times: []`**, the `:no_times` case — `Kati.Notifications.Sources.Health`
  is explicit that *"this medication never reminds me* has to be answerable and `:no_times`
  is the answer — screen 112 lets a schedule be a sentence with no clock in it."*
  (3) **187 before anything is typed**, which is what the sheet actually opens as.
- **Error.** 187's refusal, in the shape D-31 and board 155 established: say what is
  missing, say nothing was written, keep the button live — *a dead button explains nothing*.
  And 112's `Nothing to save yet.` line, which the code already renders and no board draws.

## RTL

**No Persian mirror board is reserved by this ticket**, and that is scoping rather than an
omission — but the rules belong on 187 and 188 so the Fa siblings are a redraw and not a
redesign, and there is a specific Persian problem here worth writing down.

Screen 115 (سلامت) is the Persian health page and it draws today's doses — `۰۸:۰۰
لووتیروکسین`, the mirrored dose cards, the two verbs inside the due card. It draws **no
Schedules group at all**, and its `add` disc pushes the English screen 111. So a Persian
user has no door to a medication list, let alone to a medication. That is 115's own change:
`D-45` already claims 115's `add` disc for the Persian log-weight sheet on board 191 and
does not reach medication, so this gap belongs to neither ticket yet. What this brief owes
is a mirror spec 115's eventual redraw can follow without a second argument.

**What mirrors.** The container takes `dir="rtl"` and the whole grid mirrors: 187's sheet
header (close disc trailing, Save pill leading), every labelled trough, 188's switch rows
with the track on the leading edge, the Times chip row, 31's delete control. The back pill's
glyph becomes `arrow_forward_ios` and 112's Schedules chevrons become `chevron_left`. Clock
times go Persian digits in DM Mono so the 44px time column still aligns, and the schedule
sentence goes Persian prose — `هر روز صبح، ۰۸:۰۰`.

**What does not.** The notification preview's internal layout follows the platform, not the
page. **The vertical order never reverses**: Name before Dose before Schedule before Times
before Instruction, in Persian exactly as in English; on 188, prescription before reminder
before taking before delete, always. And the stored value never mirrors — `times` is
`"08:00"` in the database whatever the page prints, because `Sources.Health.wall/2` parses
`at <> ":00"` through `Time.from_iso8601/1` and *"a row whose time does not parse is dropped
rather than guessed at."* Persian digits are a rendering, never a stored string.

## Dark colourway

**Needed as one inset on 188, not as a third board.** Everything on 187 is board 119's
sheet, and board 157 has already made the only dark decision that stack needs: the inset
field trough *"goes `#2A2826` with a hairline rather than inverting to card colour, so a
field still reads as a hole rather than a raised surface. The orange caret is unchanged —
it is the one accent on the screen in both themes."* 187 adds no surface to that.

188 adds two things 157 does not answer, and both are about colour carrying meaning rather
than decoration: **the switch's off track** (`#DCD7CF` is a light-mode value and reads as a
raised chip on `#121110`) and **31's destructive control**, whose `#B4553C` on `#EFECE7` is
a different amount of contrast from `#B4553C` on `#121110`. Board 110 is the precedent for
how to draw it — six states on one sheet with a Dark inset among them — so 188's dark is an
inset carrying the reminder card and the delete control, and nothing else.

## Reuse, do not invent

- **187's whole chassis is board 119** — scrim, bottom sheet, close disc, centred title,
  ink Save pill, DM Mono uppercase field labels, 44px inset troughs, the orange caret, and
  above all the **preview band**. 119's line is *"This is how the row will look in the
  meal"*; 187's is the same sentence about the Schedules row.
- **187's Times add-disc is board 31's *Add someone*** — 34px, dashed 1.5px border, `add`
  glyph, muted label.
- **188's chassis is the standard pushed screen**, and its field stack is 187's, which is
  the whole reason these are one brief.
- **188's reminder rows are board 51's Manners group** — a card of list rows, 30×30 paper
  icon tile, 13.5px/600 title, 11.5px `#8A8479` second line, no chevrons, because none of
  them leads anywhere. `bedtime` for the quiet-hours fact is 51's own glyph for its own
  quiet-hours row.
- **188's notification preview is board 51's bubble** as screen 112 already renders it —
  `Palette.card_settled()`, radius 20, DM Mono `KATI · 21:00` eyebrow, title, body, action
  row.
- **188's switch is board 150's** — 46×28 track, radius 14, ink on / `#DCD7CF` off, 22px
  knob with `0 1px 3px rgba(26,25,23,.3)`.
- **188's delete is board 31's trailing *Delete event*** — 48px, radius 24, `1.5px solid
  rgba(180,85,60,.3)`, `delete` glyph and label both `#B4553C`. Not a filled button; a
  destructive control in this app is outlined.
- **The undo bar is board 27's** — the same bar that follows *Dropped The Quiet Ones*.
- **112's empty card is board 27's** empty specimen at screen 139's geometry, with the
  medication noun.
- **112's failure line is `save_notice/1`'s** — 12.5px semibold, `Palette.red()`, above
  the two verbs.

## What it must NOT do — decisions the codebase has already made

**Do not draw a recurrence builder for Schedule.** `Kati.Health.Medication` decided this
and gave the reason: *"`every morning, 08:00` and `Mon, Wed, Fri` are what screen 112
prints, and they are stored as written rather than parsed into a rule. `Kati.Recurrence`
exists and could express both — and using it here would mean Kati deciding what your
prescription says, which is precisely the line the screen's own footnote draws."* Schedule
is one free-text line. A `Kati.Recurrence` picker on this board would put the app inside
the prescription.

**Do not draw Dose as a number field beside a unit menu.** Same moduledoc: *"A number and a
unit would need a unit vocabulary, and the vocabulary of medicine doses is not one an app
should be guessing at — `IU` is not convertible to `mg` without knowing the substance."*
One trough, free text, and the preview band shows exactly what it will print.

**Do not let the reminder switch promise one notification per medication.**
`Kati.Notifications.Sources.Health`: *"Three tablets at 08:00 is one thing that happens at
08:00. Waking someone three times for it teaches them to ignore the second and third, which
is the failure mode a medication reminder cannot afford."* The candidates are aggregated by
clock time and `title/1` returns `"3 doses"` for a group. That is why 188 carries the
**Shared with** row: without it the switch is a lie by omission.

**Do not draw a quiet-hours switch on 188.** Health is the one domain that is `:exempt`,
and the module says why: *"a 21:00 dose that shifts to 08:00 is not a late reminder, it is
the wrong instruction."* The row states the fact. A switch would offer a choice the
scheduler will not honour.

**Do not draw a priority, importance or loudness control.** `priority: :high` is a budget
allocation — *"`:high` says* if something in health has to go, this is not it.*"* — not a
volume. There is nothing here for a user to set.

**Do not draw a free-text field for the notification body.** `body/1` composes it from
`dose` and `instruction`, joined with ` · `, falling back to `"Due now"`. A separate
reminder-text field would be a second place to say the same thing, able to disagree with
the card on 112.

**Do not draw a picture of a notification with live buttons on 188.**
`Kati.Screens.Medication`: the reminder's three actions are *"drawn and inert here, because
tapping a picture of a notification is not taking a dose; the real ones live on the
notification."* 188's preview is a preview. Annotate it as one.

**Do not add a Missed control anywhere.** `Kati.Health.Dose`: *"`:missed` is not something
the user sets. It is what a `:due` dose becomes once its time has passed, and `resolve/2`
is the only thing that decides it."* The three states a person can cause are due, taken and
skipped.

**Do not conflate *stop taking* with *delete*.** `active` is a filter — the `:active` read
is *"the medications still being taken — screen 112's Schedules group"* — and it keeps
every `Kati.Health.Dose` row already recorded. Delete removes the medication, and doses
`belongs_to :medication` with `allow_nil? false`. Two controls, two sentences, and the
delete confirmation must say what goes with it.

**Do not put a medical claim on either board.** Screen 112's footnote is load-bearing:
*"**Kati is not a medical device** and gives no medical advice — it only records what you
tell it."* No interaction warnings, no dosage validation, no "are you sure that's right"
on a typed dose. And nothing on 187 or 188 may soften 112's other note — reminders are a
nudge and not a guarantee.

**Do not name a glyph outside the subset.** Every symbol above is in `Kati.Icons` today.

**Do not treat 112's `add` disc and its chevrons as new controls.** They are drawn,
reachable and inert, and `Kati.ScreenTapSweepTest` lists all five by name —
`{Kati.Screens.Medication, :add}` and the four `:open_schedule_*` tags — with the reason:
*"`add` and `open_schedule` are drawn and reachable and open nothing: neither a
new-medication sheet nor a per-medication page is drawn anywhere in the 127 artboards."*
(That count is the vintage of the sentence, not of the set; it is 166 now and the fact has
not moved.) This brief gives them destinations; it does not give 112 new affordances.

## Left open — decide and note which way you went

- **How Times is actually picked.** This is the one real blocker. Mob has no date or time
  input (#45) — it is why board 111's `now` pill has nothing to come back from and why
  119's `edit_name` opens no keyboard. A clock picker cannot be built today. Draw the
  field, and decide what ships behind it: a chip row of common times (`08:00 · 13:00 ·
  21:00`) plus a stepper is buildable now; a real picker is not. Say which the board means.
- **Whether 187's fields are typed or chosen.** The same #45 constraint reaches Name, Dose,
  Schedule and Instruction. 119 was honest about it by putting the preview under the fields
  rather than pretending at a keyboard. 187 can do the same, or it can be drawn for the
  keyboard #45 will eventually bring. Both are defensible; the board has to pick one, and
  the preview band stays either way.
- **Which body the notification actually shows.** Board 112 draws `With water, before bed`
  and `body/1` composes `200 mg · with water`. These are different sentences for the same
  notification, and one of them is wrong. Decide whether 112's drawn line is the target the
  code should move to or a caption that should be redrawn.
- **What happens to the dose history when a medication is deleted.** Nothing in `lib/` calls
  `Ash.destroy` on any health resource, so this is genuinely undecided. Cascade, orphan, or
  refuse-while-doses-exist are three different confirmation dialogs.
- **Whether 188 carries a history band.** `Kati.Health.Dose` has one read, `:for_day`. A
  per-medication history is a second read and a second decision about how far back it goes.
  Deliberately not drawn here. If it should exist, it wants its own number.
- **Where 187 returns to.** Back to 112 with the new row in the Schedules group, or straight
  to 188 so the times and the reminder can be set in one sitting. The second is the better
  flow and the worse precedent — D-31 left the same question open for *Add to library*, and
  the two should be answered the same way.
- **112's reminder caption count.** `3 OF 4 REMIND` is drawn from the fixture. Decide
  whether the caption counts medications with times or clock times armed — they are
  different numbers the moment two tablets share 08:00.

## Acceptance — how we know the drawing is complete enough to build from

- 187 draws every field with a value in it **and** the preview band underneath, so the two
  lines `Medication.schedule_line/1` and `dose_line/1` already produce can be read off the
  board rather than inferred.
- 187's refusal is drawn with the sentence, the ring and the live button, so
  `Kati.WriteContractTest`'s contract has a picture.
- 188 draws the reminder switch **on and off**, and the `times: []` state where it is absent
  rather than off. The `:no_times` case is a state the notification source already handles
  and no board has ever shown.
- 188 draws the *Shared with* row, so nobody builds a per-medication notification.
- 188's delete is drawn with its confirmation, and the confirmation names what goes with it.
- 188's dark inset carries the off switch track and the destructive control, and nothing
  else.
- **112 is drawn empty**, with its own subtitle literal, its own sentence, one ink action
  and one quiet alternative — so `Kati.ScreenEmptyDatabaseTest` has a board to compare
  against and screen 112 can come off that file's `fallbacks` list instead of printing four
  tablets belonging to nobody.
- 112's `Nothing to save yet.` line is drawn where `save_notice/1` renders it.
- Every literal a sweep will read is on a board: every field label, every eyebrow, every
  switch second line, every info sentence. `Kati.ScreenDesignLiteralTest` asserts them
  against the rendered tree, and a literal that only lives in the caption is a literal the
  screen will be built without.
- No symbol name appears that is not already in `Kati.Icons`.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. This brief's two
new boards take **187** and **188**; the edit to 112 keeps its own number.

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
