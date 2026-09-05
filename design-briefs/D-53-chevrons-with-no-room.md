# The chevrons that promise a screen nobody drew

> **Mixed — seven new artboards and three board edits** · ticket `D-53`

Somebody opens **Settings**, scrolls to Sections, and taps *Reorder sections · Drag to
change home order*. Nothing happens. They scroll on to Data, tap *Clear watch history* —
the one row in that group with no second line under it at all, so tapping it is the only
way to find out what it would do — and nothing happens. They go on to **This device**,
read *Everything is in one file on this phone*, tap *Delete everything · Cannot be
undone*, and nothing happens there either. Then they open **Language** to put the app on a
Shamsi calendar, and tap *Calendar*, then *Numerals*, then *Week starts*, then *Time
format*, then *Units*. Five taps, five chevrons, five times nothing. The sixth row in that
group — *Currency* — opens screen 125 and works. **Eight rows, eight chevrons, eight
promises the drawings make and no board keeps**, on the three screens a person goes to
when they want the app to behave differently.

## Why this is one brief and not five

Because it is one rule broken eight times. The house rule is on every board and in the
code that reads them — *a chevron means **leads elsewhere**, never use one for a row that
does not push a screen* — and `Kati.Screens.Account` states the consequence where it
decides which rows get a tap:

> The same fact `trailing/1` reads decides this too, which is the point of the three
> shapes: a pill and a switch are both things you do here, **a chevron is a door to a
> screen this build does not have**. A tap that silently does nothing would be worse than
> no tap at all.

So all eight are inert by policy rather than by neglect, and none of them appears on
`Kati.ScreenTapSweepTest`'s Backlog list — a backlog entry needs a *tag*, and a row with
no destination is never given one. They are invisible to every sweep in the repo. The
count is checkable: 24 draws thirteen chevrons and `Kati.Screens.Settings`'
`@destinations` names eleven of the titles behind them; 54 draws seven and
`Kati.Screens.Language.tap/1` has exactly one clause, `tap("Currency")`; 40 draws two and
`Kati.Screens.Account.row_tap/3` answers `nil` for both.

Underneath the eight there are **three pieces of drawing and one shared recipe**:

- **Five of the eight are one picker, five times.** Calendar, Numerals, Week starts, Time
  format and Units are the same page with different options, and **125 is that page
  already drawn** — a list of choices with a tick, a worked example of what changes, and a
  confirmation naming what does *not*. Five briefs would produce five slightly different
  confirmations for the same act.
- **Reorder sections is the one genuinely new interaction.** Screen 26 is a *picker*
  ("Pick two to start"), not a reorderer; it has no ordering control anywhere on it. This
  is the only drag-to-reorder surface the app would have.
- **Clear watch history and Delete everything are two uses of one undrawn pattern.** Kati
  has never drawn a destructive confirmation. It has drawn three things next to one: 125's
  *Switch to EUR?* cream card with **Switch anyway / Keep GBP**, which confirms before;
  95's *Region is now Iran* card with **Got it / Undo**, which explains after; and 129's
  *Replace everything on this device* — a red-ringed row that **selects** and an ink button
  that commits. The third is nearest and is still a different act: it is a mode of a
  restore, inside a flow that has already picked a file.

Split them and the two destructive boards each invent a chevron destination in their own
way — which has already happened once in this app, on the two boards that draw *Show all
47*, where identical rows push two different modules and nothing in the repo can see the
divergence because neither destination is wrong about a board that does not exist. One
brief is what stops it happening a second time.

There is a **third caller waiting for the same recipe** and it is not in this ticket:
board 80 draws *Disconnect everything and wipe tokens* with `delete_forever` and a
`chevron_right`, and nothing is behind it either. Draw the confirmation for three, not
two, and 80 becomes a copy change rather than a fourth invention.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **209** | **NEW — An override, worked through on Calendar** | The page behind all five of 54's *Follows the language* and *Content* chevrons. Options, the inherited default, a worked example, and the confirmation. This is the **pattern board**: every rule the other four inherit is annotated here. |
| **210** | **NEW — The other four overrides** | Numerals, Week starts, Time format and Units as four state cards on one frame, in 130's manner. Only what differs from 209: the options, the sample, and whether the act earns a confirmation. |
| **211** | **NEW — Reorder sections** | The drag surface 24's row has promised since it was drawn. Rows with a `drag_indicator` handle instead of a chevron, and the hint that teaches the gesture. |
| **212** | **NEW — Reorder sections — states** | The lifted row, the insertion gap, the drop, the one-section case, and 235%. A gesture with no drawn mid-state cannot be built. |
| **213** | **NEW — Clear watch history** | The destructive confirmation, first use. What goes, what stays, the count, and the two-step. |
| **214** | **NEW — Delete everything** | The same recipe, second use, with the heavier ring and the safety export the engine already requires. |
| **215** | **NEW — The destructive confirmation — states** | Nothing to clear, in flight, finished, refused, and the absence of an undo. Shared by 213, 214 and — later — 80. |
| **24** | edit | Annotate *Reorder sections* → 211 and *Clear watch history* → 213. Give *Clear watch history* the second line it does not have. |
| **40** | edit | Annotate *Delete everything* → 214, and say in words that *Move to a new phone* is **not** this ticket's. |
| **54** | edit | Annotate all five chevrons with their destinations, and mark that *Add a language* and *Writing direction* are not among them. |

**The three edits are annotations and one new sub-line, not redraws.** Nothing on 24, 40
or 54 moves. Their resting frames are baseline: `Kati.ScreenDesignLiteralTest` asserts
every literal and every symbol on all three against the rendered tree, and
`Kati.ScreenEmptyDatabaseTest` asserts the same literals for 24 with nothing stored.

### The two decisions this brief makes rather than leaves

**One picker screen, one recipe, two boards — not five.** The five rows open the same
module with a different argument. `Mob.Socket.push_screen/3` already takes a params map
and the app already does this: `Kati.Screens.AutoDetect` pushes
`Kati.Screens.RetiredTile` with `%{section: "Browser extension"}`, and screen 114 is one
artboard serving several tiles. So 209 is the page, drawn on Calendar because Calendar is
the consequential one, and 210 carries the four deltas. **This is not the generic-detail
defect**: the defect is a detail screen that *cannot* be told what it is detailing, and
this screen's whole identity is its argument. The board should say so, because a picker
that ignored its argument would be five rows opening the Calendar page.

**One recipe, two destructive boards — not one sheet.** The *shape* is one and is drawn
once, on 213. They are two artboards because the copy contract is per-act and the sweeps
assert strings per screen: the two acts empty different tables, have different exception
lists, and — the decisive difference — one of them is already governed by a rule in the
engine. `Kati.Backup.Restore` refuses `:replace` without a `:safety_sink` that has
successfully written an export first (*"If the safety export cannot be written, the wipe
does not happen"*), and `Kati.Theme.Palette` has already given that act its own heavier
ring:

> `red_ring_strong` — the heavier ring screens 129 and 132 draw around Replace everything
> — **the one control in the app that cannot be undone**, so it carries more ring than a
> merely destructive row.

So 213 takes `red_ring` and offers an export; 214 takes `red_ring_strong` and takes one
first. Drawing them as one board would have to pick one of those and be wrong about the
other.

## 209 — An override, worked through on Calendar

Every symbol below is in `Kati.Icons`' map already, so none of these seven boards costs a
`mix kati.gen.icons` run — which matters, because
`test/design/material_symbols.codepoints` is not in the repo and a new symbol is a blocked
build rather than a small chore.

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Language` | 125's exactly — 44pt, radius 22, `#FBFAF8`. Its label is a compile-time string on `Kati.Screens.Pushed`, which is why the Persian twin is a second module and not a mode; see *RTL* | `arrow_back_ios_new` |
| Title + mono eyebrow | `Calendar` over a DM Mono 10.5px `.16em` line. 125's is `ONE CURRENCY, CHOSEN ONCE`; this one says the thing 125 never had to — that the value is **followed** until it is set | — |
| **The inherited-default row**, first in the card | The state all five rows are actually in today. 54 prints `Gregorian · Shamsi available` and, on the row that never becomes a setting, `Left to right · set by English` — so the list needs an option meaning *whatever the language says*, above the explicit ones. The mark is already specified: `Kati.Theme.Palette`'s `green_wash_soft` is documented as the ground under a tick that marks *an inherited default (153)*. Use 153's, not a second shape | `check` on `green_wash_soft` |
| Option row | 125's row, prop for prop: a 40×40 paper tile at radius 12, the value's name and a second line, and a `check` at 20px in `Palette.green()` on the current one. The tick marks the current selection rather than a radio — 94's caption settles it, and 35 marks per-show state the same way | `calendar_month` · `check` |
| Options for Calendar | Gregorian and Shamsi, which is exactly what 54's own sub-line offers. **Not a list of every calendar CLDR knows** — 62's locale table draws Hijri in the `ar` row and Arabic is not a shipped locale | — |
| **The worked example** | 125's `Formatting` card, unchanged in shape: two rows, `En` and `فا` locale tiles at 40×40, the *same date* rendered in each. Produced by `Kati.Cldr`, never typed — that is the whole claim of the block, and 125's own doc says two hand-written examples *"would be a claim about CLDR made without consulting it"* | — |
| Consequence note | `Kati.UI.SettingsList.note/2`, the bordered `info` card. Says what changes: every date the app *prints* | `info` |
| **The confirmation** | 125's cream card verbatim in structure — an `error` glyph at 18px in `Palette.gold_icon()`, a bold `Switch to Shamsi?`, then two **labelled halves** (`Changes:` / `Does not change:`), then an ink pill and a quiet text link. Two halves and not one paragraph, because 125's doc gives the reason: *"the question a user actually has is what happens to my money and a single paragraph would let the reassuring half be skimmed past"* | `error` |
| The two controls | An ink pill, height 38, radius 19 — `Switch anyway` — and beside it a plain `Keep Gregorian` in `cream_sub`, no pill. Never two buttons of equal weight; 129's caption makes that the rule for consequential pairs | — |

**The sentence 209 exists for** is the calendar analogue of 125's `£8.99 becomes €8.99,
not €10.42`: *changing the calendar changes every date Kati shows you and no date Kati has
stored.* That is true rather than aspirational, and for the same structural reason 125's
is — `Kati.Calendars.Event` keeps `dtstart_date` apart from `dtstart_utc`, and
`Kati.Media.Watch` keeps `watched_on` apart from `watched_at`, precisely because *"watched
on 12 August" is date-valued, and storing it as midnight moves it a day the moment the
user flies.*

## 210 — The other four overrides

One 402×874 frame, back pill, title `Overrides`, mono eyebrow `FOUR MORE, ONE PAGE`, then
four labelled state cards — the shape 130 uses for eight backup states and 27 for three.
Each card carries only its options, its sample, and whether it earns a confirmation.

| Card | Options | The sample it must draw | Confirmation? | Glyph |
|---|---|---|---|---|
| **Numerals** | Latin `1234` · Persian `۰۱۲۳` — 54's own copy | The same figure in both, **in the face it will actually ship in** | Yes | `pin` |
| **Week starts** | Monday · Saturday · Sunday | The seven-across day strip, drawn twice | Yes | `event` |
| **Time format** | 12-hour · 24-hour | Screen 33's `Sun 16 Aug · 21:40`, in both | No | `schedule` |
| **Units** | Metric · Imperial | A meal line in both — 54 writes `Metric · grams and millilitres` | Yes | `restaurant` |

**Numerals is the one override with a typographic cost, and the board has to draw the
cost.** `kati_mono.ttf` carries none of U+06F0–U+06F9, which `Kati.Screens.Currency`
records where it draws its own Persian example: `۱٬۲۳۴٫۵۶ پوند بریتانیا` in mono *"is
drawn by Android's fallback face beside the English row's real DM Mono. Vazirmatn at the
same size is the wrong face and the right glyphs, which is the better half of it."* So
switching numerals changes the **face** of every count, time, ID and eyebrow in the app,
not only the digits, and a sample drawn in DM Mono would be a sample of something that
cannot ship. Draw it in Vazirmatn and say why on the card.

**Week starts has a consequence already drawn, on 56.** Its caption: *"The Persian week
begins on شنبه, so the day strip reorders — a change no amount of CSS mirroring would
produce."* That sentence is the confirmation's `Changes:` half. Note also that the week
strip is named in the house style as chrome that **caps** rather than grows with Dynamic
Type, so the sample is drawn at the size it holds.

**Units is Currency's argument a second time, and should reuse its words.** The nutrition
figures on a `Kati.Meals.MealLog` are frozen at log time — `Kati.Backup.Restore` refuses
to replay them through a create action because that *"would recompute the frozen nutrition
figures from whatever the recipe says now — destroying the one property #73 exists to
establish."* So Units, like Currency, is a **display** setting over stored figures. The
`Does not change:` half writes itself.

**Time format gets no confirmation, and the board should say so out loud.** Nothing stored
moves and nothing reorders; a confirmation on it would teach a reader that the other three
confirmations are decoration.

## 211 — Reorder sections

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Settings` | Pushed from 24. No dock, so the frame closes at 40 | `arrow_back_ios_new` |
| Title + eyebrow | `Reorder sections` over 24's own second line, `Drag to change home order` — the copy is already written, do not rewrite it | — |
| **The hint** | A quiet line, or a `touch_app` glyph beside one, teaching that a row is dragged by its handle. `D-34`'s rule holds: *a gesture with no visible hint is not an affordance; it is a secret* | `touch_app` |
| **Section row** | The standard list row with **the handle where the chevron would be**: a 30×30 paper tile at radius 9, the section's name at 13.5px/600, and 24's own second line under it (`Home card, calendar feed, shelf`), then `drag_indicator` at 18px in `#C4BDB3`. **No chevron on these rows** — they lead nowhere, which is the rule this whole brief is about | `movie` · `menu_book` · `graphic_eq` · `bolt` · `payments` · `edit_note` · `drag_indicator` |
| **How many rows the resting frame draws** | **Four.** 24's account card prints `4 SECTIONS`, and `Kati.Screens.Settings.meta/2` rewrites that number from the switches below it, so at rest it is Screen, Books, Music and Habits. A board that drew five would contradict the card one screen up | — |
| The blocked note | A bordered `info` card stating that a stored order is what this screen needs and what nothing keeps — see *What it must NOT do* | `info` |

**The list is the kept sections only, and Money is not on it.** 24 ships Money off, and a
list mixing on and off rows would need two controls per row — a handle and a switch — on a
page whose whole subject is one gesture. A section switched on later joins the order at
the end; say that in a line, because otherwise it appears in the middle and reads as a
bug.

**Which sections exist at all is a settled question and 211 is the first board to draw the
answer.** `Kati.Screens.Settings` records the disagreement:

> The app cannot yet say what a section *is*. This screen offers five (Screen, Books,
> Music, Habits, Money) with four on; screen 26 (`Kati.Screens.PickSections`) offers six —
> it adds **Notes** — with two chosen. Two drawings, two different section sets and two
> different defaults, and both are baseline frames that may not move.

`Kati.Sections` has since picked: `@known` is `~w(screen books music habits money notes)`,
six ids, *"in the order the first run draws them"*. So 212's states card draws the full
six and 211's resting frame draws the four that are on. **Do not add a Notes row to 24** —
that is a different gap and a different ticket.

## 212 — Reorder sections — states

Five cards on one frame, and the middle three are the ones that make the gesture buildable.

- **Lifted.** The row under the finger, raised on the card shadow, the rows either side
  parted, and the gap where it will land. The one state that cannot be inferred from the
  resting frame.
- **Dropped.** What settles, and how fast. Draw whether the neighbours slide or snap.
- **One section left.** `Kati.Sections.put/1` refuses an empty list — *"a store that
  accepted nothing would make that rule a matter of remembering to check it at every call
  site"* — so a single row can exist. A single row cannot be reordered, and its handle
  should say so rather than be draggable to nowhere.
- **235%.** The house style's rule: content grows, chrome whose size carries structure
  caps. Draw the 30pt tile and the handle at the size they hold while the two text lines
  grow past them.
- **There is no empty state, and the board should say why.** `Kati.Sections.chosen/0`
  answers everything before the first run has been walked, *"deliberately not `[]`. An
  empty list would mean a brand-new install shows nothing at all, and a screen with no
  content is indistinguishable from a screen that is broken."* This is a page that cannot
  be empty, which is worth one annotated line — every other new board in this ticket has
  an empty state that matters.

## 213 — Clear watch history

Bands, top to bottom.

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Settings` | Pushed, not a sheet. Every chevron on 24 pushes a page, and the exception list below does not fit in a modal that hugs its content | `arrow_back_ios_new` |
| Title + mono eyebrow | `Clear watch history` over `WHAT GOES, AND WHAT STAYS` — 130's manner | — |
| **What goes**, a card of counted lines | One honest number, not a headline total. `Kati.Backup.Restore.wipe/1` shows how it is taken: `Ash.count!` **before** the delete, because *"SQLite's `num_rows` for a `delete` without `RETURNING` is 0, so a report built from it would tell the user nothing was deleted while it deleted everything"* | `history` |
| **The three things inside a watch that are not a date** | A watch carries a rating, a review, its spoiler flag, the moods, the companions and the tags. Clearing the history deletes reviews the person wrote. Name them; a count of "entries" hides them | `star` · `edit_note` |
| **What it does not touch**, a second card | 95's shape — *"Your library, ratings, notes and history do not change at all"*. Here: the shelves survive, because status lives on `Kati.Media.TrackedTitle` and not on a watch; and reading sessions and listens survive, because `book_reading_sessions` and `music_listens` are separate tables in `Kati.Backup.Catalog` | `check` |
| **Keep a copy first** — an offered row, not an automatic step | Opens `Kati.Screens.Backup`, which 24's *Back up everything* row already routes to. Offered here and **taken automatically on 214** — see that board | `upload` |
| **The destructive bar** | Screen 31's `delete/0` prop for prop: full width, 48 high, radius 24, `Palette.red_ring()` at 1.5, `delete` at 18px and a 13px/700 label in `Palette.red()`, **no background at all** — *"outlined in red rather than filled"*. With 129's ellipsis, because it **selects and does not commit** | `delete` |
| The confirmation it raises | 125's cream card, the two labelled halves, the ink pill and the quiet keep-link. The page's one primary control | `error` |

**The label on 24 is wrong and the board is where that gets said.** `Kati.Media.Watch`'s
first line is *"One act of watching, reading or listening. **Never evicted.**"* and
`Kati.Media.TrackedTitle.kind` is `[:movie, :tv, :anime, :book, :album]` — so a watch row
can be a book finished or a record played through, and *Clear watch history* empties those
too. The row on 24 has **no second line at all**, which makes it the only row in the Data
group whose meaning cannot be read before tapping it. The edit to 24 is that line. Whether
the title changes with it is in *Left open*.

**The consequence that has to be on the board in words.** Series progress is not stored:

> For a series the *authority* on how much is watched is the set of `Kati.Media.Watch`
> ticks — screen 04 is explicit that the counter is derived and never stored, because two
> places that both know "5 of 7" will eventually disagree.

And a tick *is* a row: *"an episode is watched when a row for it exists, so unticking
destroys and rewatching simply adds another."* So clearing the history **unticks every
episode in the app** and every progress ring returns to zero — while
`progress_season`/`progress_episode`, which are the bookmark and live on the title,
survive. A shelf will read `S2 · E5` beside a ring at nothing. Draw that pair; it is the
single most surprising thing this act does.

## 214 — Delete everything

The same page, with three differences and nothing else.

| Element | Difference from 213 | Glyph |
|---|---|---|
| The bar | `Palette.red_ring_strong()` and `delete_forever`, because 40's own sub-line is *Cannot be undone* and the palette reserves that ring for exactly that claim | `delete_forever` |
| **The safety export**, a band above the bar | Not offered — **taken**. `Kati.Backup` refuses `:replace` without a `:safety_export_path` and `Kati.Backup.Restore` refuses it without a `:safety_sink`, and 129 already draws the consequence of that rule: a screen that let a person discover a designed precondition by being refused would be turning it into an error message. Name the file before it is needed | `archive` |
| Where that file goes | **Not** the staging directory. `Kati.Backup.Transport.sweep/1` empties staging hourly, and *"the safety export is the only remaining copy of data the user has just replaced — an hour later it would be gone."* The notice carries the path so the copy can be handed to the system afterwards. The path itself is DM Mono, the way 80 sets its pairing code | `description` |
| The counts | 130's *Restore finished* card is the model — five named lines and a total, not thirty-one. `Kati.Backup.Catalog` lists 31 tables and a wall of them is not a warning, it is a receipt | `check_circle` |

**What survives a wipe, and whether that is intended, is the question 214 must answer.**
`Kati.Backup.Restore.wipe/1` deletes the catalog's tables and nothing else, and the app's
preferences are not tables: the locale, the theme, the kept sections and the backup ledger
all live in `Mob.State`, a DETS file, and the provider tokens board 80 describes sit
unencrypted on the device outside all of it. A *Delete everything* built on `wipe/1` alone
leaves the app in Persian, in dark mode, with your ListenBrainz token still on the phone.
Either the board says those go too — in which case it is naming a second engine that does
not exist — or it says they stay, in which case the row's word *everything* needs
qualifying. It cannot say neither.

## 215 — The destructive confirmation — states

`Kati.ScreenEmptyDatabaseTest` renders every screen against an empty database and asserts
the same literals `Kati.ScreenDesignLiteralTest` asserts against a full one — 24 is on its
list already — so **an empty state nobody drew is an empty state nobody tests**. Four of
these six are that.

- **Resting.** The selected state: the bar tapped, the confirmation card up, both counts
  real. This is the state the page is worth drawing for, the way 125 opens with its
  confirmation showing rather than hiding its own subject until you tap something.
- **Nothing to clear** — the common case in week one. No watches at all, or no data at
  all. `Clear 0 entries` is not an answer; 130's *never backed up* card is the tone to
  take, cream and bronze rather than red, *"because it is every user's starting
  condition"*. The destructive bar should not be drawn as an enabled control over nothing.
- **In flight.** 130's *Restoring* card is the shape — a 2px progress bar, a mono count —
  but the sentence is the **opposite** of 130's *leaving this screen is safe*. Every write
  here runs inside one `Kati.Repo.transaction/1` and *"a restore either happened or it did
  not"*, so what this card promises is that it cannot half-happen.
- **Finished.** 130's `check_circle` card, with what went and what is still here.
- **Refused.** 214 only: the safety export could not be written, so **nothing was
  deleted**. This is a designed refusal rather than a failure, and 130's *refused wholly*
  card is the register — name what happened, state plainly that nothing changed.
- **The absence of an undo.** The app's undo precedent is a transient bar — 95's *Got it ·
  Undo* — and there is none here. Draw the absence as a line rather than omitting it,
  because a reader who has seen 95 will look for one.

## States to draw

**Resting** matters least and is drawn last. All seven boards are pages a person arrives
at to *change* something, so the populated case is the easy one.

**Active** is where the work is. 209 and 210: a confirmation raised, with the current
value still ticked underneath — the tick does not move until the switch is taken. 211 and
212: the lifted row, which cannot be inferred. 213 and 214: the bar **selected**, which is
a state 129 already has and no other board in the app does.

**Empty** is the common case and there are four:

- **209/210 with the override never set** — the state all five rows are in today, on every
  install. The inherited-default row is ticked and no explicit option is. This is not an
  edge; it is what a fresh phone shows.
- **211 with one section kept.** Above.
- **213 with no watches.** Above.
- **214 on a device with no data.** `Kati.Screens.Restore` already refuses an empty-device
  case in the other direction and names what it found; this is the same sentence pointed
  the other way.

**Error.** 214's refused safety export. And on 209 and 210, the state that is *not* an
error and reads like one: a locale whose CLDR data does not carry the chosen combination.
Say what happens rather than leaving it to a crash.

## RTL — what mirrors, and which of these need a Persian board

**The five pickers need a Persian mirror and the ticket has not reserved one — flag it
back rather than leaving it to be discovered.** This is not a nicety. Board **62** — the
Persian Settings page — draws three of the five override rows inline in its زبان و منطقه
group, with `chevron_left` and nothing behind them: `calendar_month · تقویم · شمسی`,
`pin · اعداد · فارسی ۱۲۳۴`, `event · شروع هفته · شنبه`. They are the same three glyphs 54
uses, which matters because `Kati.Screens.SettingsFa`'s `@destinations` is keyed **by
glyph and not by the Persian title**, for a stated reason:

> The glyph is the one part of these rows that is not copy, so screen 24 and this screen
> name the same destinations without a translation table between them.

So the Persian rows will route themselves the moment the destination exists — and land on
an LTR English page. There is also no Persian Language screen at all (`Kati.Screens.Language`
notes there is no `LanguageFa` and nothing pushes `Kati.Screens.SettingsFa` from anywhere),
so on the Persian side these three rows are reached from **62**, whose back label is
تنظیمات, not زبان. `Kati.Screens.Pushed` takes its back label at compile time —
one string per module — so this is a second module and a Persian board, not a mode of 209.

**Reorder sections and the two destructive pages need no Persian board from this ticket,
and that is scoping rather than omission.** 62's بخش‌ها group draws five toggles and no
reorder row; 62's داده‌ها group draws no *Clear watch history*; and 40 has no Persian
mirror at all. State the rules on 211, 213 and 214 so the Fa siblings are a redraw and not
a redesign — and note that 132 has **already** mirrored the destructive shape once, drawing
`جایگزینی همه‌چیز روی این دستگاه` with the same `error` glyph and the same red ring.

**What mirrors.** The container takes `dir="rtl"` and the whole grid mirrors: the leading
tile and its text swap sides, the trailing `check`, `drag_indicator` and chevrons move to
the left, chevrons become `chevron_left`, the back pill's glyph becomes
`arrow_forward_ios`. The confirmation's ink pill and its quiet keep-link swap ends of their
row. 132's caption is the precedent for the button pair: *"the conflict resolver's three
buttons reverse with the container, putting مال من at the leading right edge where Keep
mine sits on the left in 129 — same default, mirrored position."*

**What does not.** **The vertical order never reverses** — inherited default, options,
sample, note, confirmation, in Persian exactly as in English; and on 211 the section order
is the user's own data, so it is the one list on any of these boards that must be drawn
exactly as stored under mirroring. Artwork never mirrors. Latin names stay Latin — provider
and format names are trade names, not copy, which 82 and 97 both settle. Dates go Shamsi
and digits Persian, both in a face that has the glyphs; on 210's Numerals card, that is the
whole subject of the card and not a detail of it.

## Dark colourway

**Not needed as seven more boards, and every surface these boards use already has a dark
answer recorded on a board that has one.** None of the three parents — 24, 40, 54 — exists
in dark, so a dark 213 would be the only dark page in Settings.

- The **cream confirmation card** is board 75's inset: cream warms to `#2A2622` with
  `#F7EFE4` text; cards lift on a hairline, not a shadow.
- The **outlined destructive bar** needs no decision at all. `Kati.Theme.Palette` declares
  both `:red_ring` and `:red_ring_strong` as `:hue`, identical in the light and dark
  columns by construction. It is the same ring in either theme.
- `:red` itself is `:theme` and `Kati.Theme.dark/0` keeps `error: @red`, so the glyph and
  the label do not move either.
- The **paper tile** behind a section glyph is `Kati.UI.SettingsList.icon_tile_ink/1`,
  which already answers for `:dark`.

If a dark board is drawn later it is **214** — the one page where being wrong about
contrast has a consequence — and it is a colourway of a page, not an eighth artboard.

## Reuse, do not invent

- **The whole of 209** is screen **125**, re-pointed. Chrome, the 40×40 tile, the `check`
  in `Palette.green()`, the two-locale sample card, the `info` note, the cream
  confirmation with its two labelled halves, the ink pill beside a quiet text link. If
  209 and 125 do not look like the same page, one of them is wrong.
- **The inherited-default tick** is board 153's, whose ground `green_wash_soft` the palette
  documents by name.
- **The tick and not a radio** is 94's, and 35's per-show marks.
- **The destructive bar** is screen 31's `delete/0`, prop for prop: 48 high, radius 24,
  1.5 border, no background.
- **The heavier ring and the ellipsis that selects rather than commits** are 129's, and
  132 has already mirrored them.
- **The two-halves consequence card** is 125's; the **after-the-fact** card with an undo is
  95's; the **states sheet** is 130's and 27's; the **refused-wholly** register is 130's.
- **The list row** is the app's: a 30×30 paper tile at radius 9, 13.5px/600 title, 11.5px
  `#8A8479` second line. On 211 the trailing slot holds `drag_indicator` instead of a
  chevron, and that substitution is the whole visual idea of the screen.
- **The counted lines** on 213 and 214 are 130's *Restore finished* card.
- **A chevron means *leads elsewhere*.** That rule is why these eight rows are inert today
  and it is the entire content of the three board edits.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not draw a converter on Units, or a rewriter on Numerals or Calendar.** The rule is
125's and it is written into `Kati.Screens.Currency`: *"There is no code path in
`Kati.Money` that rewrites a stored figure, which is what makes the second half true rather
than aspirational."* The same holds for dates and for grams — `Kati.Backup.Restore` will
not even replay a meal log through its create action, because that *"would recompute the
frozen nutrition figures from whatever the recipe says now."* These five settings change
what is **printed**. A board that implied otherwise would promise a migration.

**Do not draw the fifth *Follows the language* row as a picker.** Writing direction is not
one of the five and never becomes a setting. `Kati.Language.Sample` says so where it draws
it: *"Writing direction shows a value rather than a chevron because it is not a choice — it
is derived, and the drawing says so by printing `auto` where the other four print an
arrow."* 54 already draws it correctly. Leave it.

**Do not give *Add a language* a destination.** It is on 54, it draws a chevron, and it is
**not** one of this ticket's five: it already carries a tag and already sits on
`Kati.ScreenTapSweepTest`'s Backlog as `{Kati.Screens.Language, :add_language}`. It is a
different gap with a different owner, and answering it here would settle a question about
shipping a third locale from inside a brief about pickers.

**Do not draw a destination for *Move to a new phone*, *Version*, *Privacy*, or the `help`
disc.** All four are on 24 or 40, all four are undrawn chevrons, and all four are sibling
tickets. 40 draws exactly two chevrons and only one of them is this ticket's; say so on
the board so the next reader does not "finish the job".

**Do not draw a Save button on 211.** `Kati.Sections.put/1` writes `Mob.State`, which
`Kati.Screens.Language` describes as *"a named GenServer over a DETS table —
process-independent, app-wide and synced to disk before the call returns."* A settings list
with a Save pill would be the only one in the app.

**Do not draw an order the store can keep and no surface reads — draw it, and annotate what
it is waiting on.** This is the one place 211 must be explicit, because the gap is real in
two halves. `Kati.Sections.chosen/0` is
`Enum.filter(@known, &(&1 in list))` — it re-sorts every read into `@known` order, so a
stored order would be discarded by the current store. And no surface reads an order anyway:
`Kati.Screens.Home`, `Kati.Screens.HomeFa` and `Kati.Screens.Library` each `Enum.filter`
their own static list by `Kati.Sections.on?/1`. 211's board should carry the annotation
naming what it needs, the way 193's board is asked to name which ticket owns its price
field — a drawing is a better reason to add a column than a comment apologising for itself.

**Do not put a route argument in the boards' chrome.** Only 7 of 62 screens read a route
argument and most detail screens open generically; that is a code defect, not a design gap,
and it is not this ticket's. What 209 *does* need is for the board to state that this
screen's identity **is** its argument — five rows opening one page is the design, and a
picker that ignored the argument would be five rows opening Calendar.

**Do not print `1,204 entries` as the count of what will be deleted.**
`Kati.Screens.Settings` is explicit that the noun does not exist:

> `1,204 ENTRIES` — there is no *entry* anywhere in Kati. The word spans four domains that
> count different things … and a total over them is a unit this app has never defined.
> Summing the tables to reach a number would be inventing the noun, not reading it.

A destructive confirmation is the last screen in the app that may print an invented number.

**Do not model the confirmation on screen 31's *Delete event*.** That bar is one tap and no
confirmation at all, and its comment says why it can be: *"destructive, and one tap away
from nothing."* One event is one tap away from nothing. A library is not. Reuse 31's
**shape** and none of its behaviour.

**Do not draw a *Clear cache* row on either destructive board.** Kati already distinguishes
the two, in `Kati.Media.CachePolicy` — *durable, never evicted: the user's own facts* against
*cached, evictable* — and board 80 already owns the cache half with its own `Refresh` and
`Clear`. These two boards are about the durable half only.

**Do not let 213 imply it clears reading sessions or listens.** `book_reading_sessions` and
`music_listens` are their own tables in `Kati.Backup.Catalog` and `wipe/1` is not what 213
calls. The *what stays* card is where that gets said.

## Left open — decide and note which way you went

- **Whether the order on 211 is Home's or every surface's.** 24's row says *Drag to change
  home order*, and `Kati.Sections`' own argument for one membership list points the other
  way: *"turning one off removes it everywhere at once … three flags drift, and the drift
  shows up as a section that is half off."* Membership and order are different questions
  and the moduledoc only answers the first. If the order is global, 24's second line is
  wrong and this ticket's edit to 24 grows by one string.
- **Whether *Clear watch history* keeps its title.** It empties a table that holds books and
  albums as well as episodes, and its second line — the edit this ticket makes to 24 — may
  not be able to carry that alone. *Clear what you have logged* is one alternative. The
  board should draw the sub-line either way; changing the title is a call about 24's
  baseline frame.
- **Whether 214 takes the preferences and the tokens with it.** See 214 above. This is a
  product decision with a schema behind it, not a drawing decision, but the drawing is what
  forces it to be made.
- **Whether the confirmation is a raised card or a second screen.** 125 raises a card
  in-page. 129 raises a band. Neither is a dialog, and this app has no dialog anywhere —
  drawing the first one for the most destructive act in the app is defensible and is a
  decision, not a default.
- **Whether the destructive commit is the page's ink primary button.** The house style
  allows **one per screen**, and on 213 and 214 the only candidate is the destructive act
  itself. 129 gave its ink button to the *safe* option and its outline to the destructive
  one; these two pages have no safe option to give it to. Either the ink button goes to the
  act, or these are the only two pages in the app with no primary button at all.
- **Whether an override can be un-set.** 209 draws an inherited default as the first option,
  which implies going back to it is a tap. If it is not — if choosing Gregorian is a
  one-way move off *follows the language* — the row is a different control and the board
  must say so.
- **What 210's four cards do about their own Persian samples.** Numerals and Week starts
  both have their subject *inside* the sample, which means the four cards are partly a
  Persian board already. Whether that makes the reserved Fa board cheaper or redundant is
  worth answering before it is drawn.
- **Whether 215's *in flight* state can be reached at all.** One transaction over 31 tables
  on a phone may be fast enough that a progress bar is a flash of chrome nobody reads. If it
  is, the honest drawing is no progress state and a disabled page, and that is a smaller
  board than the one reserved here.

## Acceptance — how we know the drawing is complete enough to build from

1. Every one of the eight rows on 24, 40 and 54 has a board number written beside it, and
   the three that are **not** this ticket's — *Move to a new phone*, *Version*, *Privacy* —
   are annotated as belonging elsewhere, in words, on the board.
2. 209 can be read beside 125 and the two are recognisably one page. Anything on 209 that
   is not on 125 is either the inherited-default row or annotated with why it had to be new.
3. 210's four cards each carry their options, their sample and a yes/no on the
   confirmation, and Numerals' sample is drawn in the face it ships in with the reason
   beside it.
4. 211 draws four rows at rest, matching 24's `4 SECTIONS`, and 212 draws the lifted row —
   so a builder can see the gesture without having to invent its mid-state.
5. 211's board names, in words, that a stored order is what it is waiting on, so
   `Kati.Sections` can gain one on the strength of a drawing.
6. 213 and 214 are the same page twice, differing only in ring weight, glyph, the safety
   export and the counted lines. If a third difference has appeared, one of them has been
   redesigned.
7. 213's board carries the untick sentence — every progress ring returns to zero while the
   bookmark survives — because that consequence exists nowhere else in the drawings.
8. 214's board states what survives a wipe, whichever way it went, so `Mob.State` is not a
   surprise discovered during the build.
9. 215 draws a state for a device with nothing on it, for all three of the destructive
   callers, so `Kati.ScreenEmptyDatabaseTest` has something to assert against.
10. Board 80's *Disconnect everything and wipe tokens* can be pointed at 213's recipe
    without redrawing it, and the brief says so.

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
