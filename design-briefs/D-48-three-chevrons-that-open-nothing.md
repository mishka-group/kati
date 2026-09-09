# The three chevrons on 31 that open nothing

> **Modal sheet — three new boards, one edit** · ticket `D-48`

Someone opens an event from the Schedule, sees that it repeats every second Thursday, that
it will tell them an hour beforehand, and that it is in Studio B — and wants to change one
of those three things. Board 31 draws all three as list rows in one card, each ending in a
`chevron_right`: `repeat` · **Repeats** · *Every 2 weeks on Thursday*; `notifications` ·
**Alerts** · *1 hour before · at start*; `place` · **Location** · *Studio B, or a link*.
The house rule says what that mark promises — *a chevron means leads elsewhere* — and
**none of the three destinations is drawn anywhere in 01–166**. So all three taps are
answered with `nil`, and the code says so once, for all three, in the same sentence:

> `lib/kati/screens/event_detail.ex:567` — *"Only the switch row. The chevron rows name
> screens that do not exist yet, so they get `nil` rather than a tap that lands nowhere."*

That `nil` has a consequence worth stating before anything else. Screen 66's undrawn
doors are at least *ledgered* — `{Kati.Screens.BookDetail, :open_series}` and
`:open_lending` sit in `Kati.ScreenTapSweepTest` under a comment explaining that they push
nothing because nothing is drawn. **These three are in no ledger at all**, because a row
that registers no tag is a row no sweep can see. Screen 31's only entry in that whole file
is `{Kati.Screens.EventDetail, :section_Work}`, which is a chip that is already selected.
The three chevrons are invisible to every test Kati has. This brief and the moduledoc are
the only two places they are written down.

## Why this is one brief and not three

Because it is one problem three times, on one board, in one card, and splitting it would
ask the same three questions three times and get three different answers.

**1. What shape is a picker reached from a modal editor?** Screen 31 is not a pushed page.
Its own moduledoc: *"an editor you finish or abandon, not a page you came from"* — a
`close` disc, a centred *Edit event*, an ink Save pill, all in flow at the top of the
scroll, and a frame that closes at 40 because there is no dock under it. Everything the
app already knows about pickers it learned from pickers reached from *pages*. A picker
opened from a sheet is new, and it is new once, not three times.

**2. Does it apply on Save, or on dismiss?** `Kati.Sync.edit/3` takes one `changes` map and
queues one push, and `Kati.Sync.Compose.changed/1` is built around that: *"Only what
changed; a field the user did not touch produces no property and therefore no write."*
Three pickers committing on their own close is three pushes for one edit; three pickers
handing values back to 31's Save is one. That is a single decision about all three, and it
cannot be made in the ticket that happens to be built first.

**3. Does it need a scope?** *This occurrence / all future / the whole series* is a real
mechanism here — `Kati.Calendars.Override` exists for exactly it, and
`Kati.Sync.split_series/4` implements "this and following" as two ordered writes — and the
app already has words for the idea on two other boards: 44's `Edit this week only` ·
*Changes will not carry forward*, and 46's `Swap just today` | `Every week`. A scope
control that appears on the recurrence sheet and not on the alerts sheet is a bug; one
that appears on all three with different wording is three bugs.

**And a fourth reason, which is the sharpest.** All three rows are only drawn under the
*sample* event. `Kati.Screens.EventDetail.stored_fields/1` builds a real event's card from
three functions — `when_field`, `zone_field`, `place_field` — and there is no
`repeat_field` and no `alert_field` at all. Worse, `place_field/1` answers `nil` unless the
event already has a location:

```
defp place_field(%Event{location: place}) when is_binary(place) and place != "",
  do: %{icon: "place", title: "Location", sub: place, trailing: :chevron}

defp place_field(_event), do: nil
```

So on a stored event the card is **three rows, not five**, and the door to the place picker
is drawn only for an event that already has a place. Draw 199 without redrawing 31 and you
have drawn a screen that can only be reached when it is not needed. That is the edit to 31,
and it is one edit covering all three rows.

### What this brief does *not* claim

The ticket pairs this with board 44's `Repeat rule` card — `repeat` · **Repeats** · *Every
week, indefinitely* · `chevron_right` — as the identical undrawn row in the meals area. It
is the identical *row*, and it is **not** the same sheet, because the codebase has already
decided otherwise. `Kati.Meals.MealPlan`:

> `repeat` has one value. A single-valued enum is the honest way to say that weekly is the
> only rule the design draws, and it leaves room for a second without a migration over user
> data.

And `D-41` has already ruled on what that means for the drawing: 183's *Repeats · Every
week* row must be *"a stated fact with no picker behind it, or a disabled row — **not** a
chevron promising choices."* An RRULE editor behind 44's row would offer a frequency
`Kati.Meals.MealPlan` cannot store. What 44's row *can* legitimately open is the other half
of its own sub-line — `weeks_total`, the *indefinitely* — and that is the same **end**
control 197 needs for `UNTIL`/`COUNT`. So: draw the end control once, on 197, in a form 44
can borrow, and say on 197 that it is shared. Do not promise 44 a frequency picker.

## What to draw

| Board | What it is | What it carries |
|---|---|---|
| **197** — Repeats | new, modal sheet over 31 | The common frequencies as rows with a `check` on the current one, a **Custom** section (every / *n* / unit, and a `S M T W T F S` weekday row for `FREQ=WEEKLY`), and an **Ends** group — *Never* / *On a date* / *After n times*. Writes `Kati.Calendars.Event.rrule`, one string. |
| **198** — Alerts | new, modal sheet over 31 | A list of the offsets already set, each removable, and an **Add an alert** control offering the common leads plus *At the time of the event*. Reads and writes nothing today — **this board needs a column drawn beside it**; see *What it must NOT do*. |
| **199** — Location | new, modal sheet over 31 | One free-text field, the places typed before offered as chips, and a **Clear** control. Writes `Kati.Calendars.Event.location`, one string. No map, no search, no geocoder. |
| **31** — edit | the field card, restated in **two** states | The card as it is drawn now (the sample, five rows) **and the card a stored event produces** — which is three rows today and must become five, with a resting row for *no repeat*, *no alerts* and *no location*. Plus: say what the `Save` pill does, because it currently does nothing at all. |

Three sheets, three destinations, and the pairing is not an economy — these are three
different controls over three different value shapes (an RRULE string, a list of offsets,
one line of text) and each needs its own frame. The saving is that they are drawn once as
**one family**: one sheet chrome, one commit rule, one scope control, one read-only state.

## Every element

### 197 — Repeats

| Element | What it is for | Glyph |
|---|---|---|
| Close disc | leave the picker without changing the rule; the sheet is a decision you come back from | `close` |
| Sheet title *Repeats* | the row's own word, so the sheet names where you came from | — |
| **Does not repeat** row | the first and default choice. `rrule` is nullable, and *no rule* has to be as reachable as any rule | `do_not_disturb_on` |
| Frequency rows | *Every day · Every week on Thursday · Every 2 weeks on Thursday · Every month on the 20th · Every year* — the sub-line of each states the rule in the event's own terms, not in RFC terms | `repeat` on the group's eyebrow tile only |
| Current-rule mark | a tick on the row that is the rule now. Not a radio — 94's argument, *"matching how 35 marks per-show state"* | `check` |
| **Custom** row | opens the interval/unit/weekday section below, for a rule none of the presets says | `tune` |
| Interval stepper | *Every* `[2]` *weeks* — the `INTERVAL` part, as a mono number between two discs | `remove` / `add` |
| Weekday row | `S M T W T F S`, multi-select, for `FREQ=WEEKLY` only. This is `BYDAY`, and **its order is data, not layout** — see RTL | — |
| Monthly choice | *on the 20th* vs *on the third Thursday* — `BYMONTHDAY` against `BYDAY` with a `BYSETPOS`. Two rows, one tick | `calendar_month` |
| **Ends** eyebrow | the group that carries `UNTIL`/`COUNT`, mutually exclusive by the RFC and by `Kati.Recurrence.Rule` | — (quiet eyebrow) |
| *Never* | unbounded. `recurs_until_utc` of `nil` | `event_repeat` |
| *On a date* | opens a month grid. `UNTIL` — and its value type must match `DTSTART`'s, which is a code concern the drawing does not have to show but must not contradict by offering a *time* | `event_busy` |
| *After n times* | `COUNT`, a mono number with the same stepper as the interval | `history` |
| Rule summary line | one sentence in English restating what has been picked, at the foot of the sheet. **This is the humaniser the app does not have**, and the sheet is where its wording is decided | `info` |
| Scope control | *This event · This and all future · All events in the series* — only when the event already repeats. See *Left open* | `call_split` — 31's own glyph for a fork |
| Commit control | whatever the Save/dismiss decision picks; if it is a button, it is **the one primary button on this sheet** | — |

### 198 — Alerts

| Element | What it is for | Glyph |
|---|---|---|
| Close disc | as above | `close` |
| Sheet title *Alerts* | the row's own word | — |
| An alert row | one lead time — *1 hour before*, *At the time of the event* — with the offset as the title and nothing borrowed for a sub-line | `notifications_active` |
| Remove, on an alert row | takes one out. Two alerts are drawn on 31 (*1 hour before · at start*), so removing one must be drawable | `close` — `MishkaPill`'s `with_remove` slot |
| **Add an alert** row | the dashed ring recipe, as 31's own *Add someone* | `add` |
| The offer list | *At the time of the event · 5 minutes before · 15 · 30 · 1 hour · 1 day · 1 week*, and a **Custom** row if a free offset is wanted | `schedule` |
| **None** row | no alert at all. Must be as reachable as any offset — an event with no reminder is the common case | `notifications_off` |
| All-day note | an all-day event has no clock, and Kati **suppresses** its notification rather than picking nine in the morning. If this event is all-day, the sheet says so instead of offering leads it will not fire | `info` |
| Budget note | that Kati holds a fixed number of notification slots across six domains and a fourth alert may not arrive. One quiet line, not a warning card | `info` |
| Sync note | **the load-bearing one.** An alert set here does not reach the calendar this event is mirrored from; see *What it must NOT do* | `cloud_off` |
| Commit control | the family's, same as 197 | — |

### 199 — Location

| Element | What it is for | Glyph |
|---|---|---|
| Close disc | as above | `close` |
| Sheet title *Location* | the row's own word | — |
| The field | one line of free text. `location` is a `:string` and nothing parses it | `place` |
| Placeholder | 31's own sub-line is the specification: *Studio B, or a link*. A room, an address or a URL, all typed | — |
| Places used before | what has been typed on other events, offered as chips so the second time is a tap | `history` |
| **Clear** control | empties the field. `location` is nullable and this is what nulls it — and clearing it **removes the row from the card**, which is a visible consequence the board should show | `delete` |
| A link, once typed | drawn as it will read on 01, 02 and 28 — plain text, not a button. Kati opens nothing | `link` |
| Where-else note | that this line leads the sub-line under the event everywhere it appears. `Kati.Calendars.Today.meta/2`: *"The location leads because it is the user's own words and the label is Kati's"* | `info` |
| Commit control | the family's | — |

### 31 — the edit

| Element | What it is for | Glyph |
|---|---|---|
| The card, stored-event state | five rows where there are three today, so all three doors exist on a real event | as drawn |
| *Does not repeat* resting row | the Repeats row when `rrule` is `nil` | `repeat` |
| *No alerts* resting row | the Alerts row when nothing is set | `notifications` |
| *Add a location* resting row | the Location row when `location` is empty — **without this, 199 is unreachable exactly when it is wanted** | `place` |
| The `Save` pill | it is drawn and it is inert: `save_pill/0` takes no tag and nothing on screen 31 writes. Say what it commits and what happens after | — |
| Read-only state of the whole card | for a mirrored event Kati may not write. See *States* | `lock` |

## States

Four, and on these three boards none of them is decoration.

**Resting.** Each sheet over the drawn event's own values, so the boards agree with 31:
197 on *Every 2 weeks on Thursday*, 198 on *1 hour before* **and** *At the time of the
event* — two rows, because 31 prints two — and 199 on *Studio B*. These are
`Kati.Calendar.SampleEvent`'s values and they are the state every frame of
`test/design/screens/31.html` was captured in.

**Active.** The ticked row; a weekday mid-select; a stepper at its lower bound (interval 1
— `remove` must be drawn disabled, not merely inert); a field with a caret and one
character in it. `Kati.Screens.EventDetail` already records what the caret costs on this
bridge, so draw one line of text, not a paragraph.

**Empty — draw it, or it will not exist.** `Kati.ScreenEmptyDatabaseTest` reads these
literals with nothing stored, and it is the sweep that makes an undrawn empty state an
untested one. On a fresh install: no rule (197 rests on *Does not repeat*), no alerts (198
is its offer list and nothing else), no place typed before (199 is a field with no chips
under it), and **31's own card is the three-row stored-event shape**, which is the state the
sweep actually renders for a real row. Kati's convention for this is not a separate
artboard — 144 hangs its variants as labelled panels under
`Kati.UI.SettingsList.eyebrow_muted/1` inside its own frame. Do the same: one empty swatch
per board, inside the board.

**Error, and it is the state that matters most here.** Kati does not request
`WRITE_CALENDAR`, so `Kati.Calendars.DeviceImport` sets `writeback_policy: :none` on every
provider calendar it imports — which means **the common case for a mirrored event is that
none of these three edits can be made at all**. `Kati.Sync.edit/3`:

> Refuses with `{:error, {:not_writable, detail}}` when ownership forbids the write. The
> editor renders `detail.reason`; nothing is written locally either, because a local edit
> that can never be sent and is never shown as unsent is the same lie as dropping it.

So there is a sentence to print, and it is already written —
`Kati.Sync.Ownership.refusal/2` produces *"write-back is off for ‹calendar›, so Kati stores
changes locally and sends nothing"* and *"this event is mirrored from ‹calendar› and that
feed's write-back policy is ‹policy› — only events Kati created are sent"*. Draw the
read-only state on **31**, where it belongs (the whole card, and the Save pill), rather
than on each sheet: a sheet the user cannot reach is better than three sheets that refuse.
If the sheets are reachable read-only, they need a locked variant too — say which.

Two more that are not errors and must not be drawn as warnings: an event with **no** rule
(the majority), and an event with **no** location (also the majority, and the reason 31's
place row has to exist when the value does not).

## RTL

**197 needs a Persian drawing. 198 and 199 do not.**

197 carries a weekday row, and a row whose columns are days is the case mirroring alone
gets wrong. `Kati.Calendar.Grid`:

> A Jalali week starts on **شنبه**. That is a fact about the calendar, and it survives into
> the returned data structure … Mirroring is the other mechanism entirely … **not one
> function in this module reverses a list**.

So in Persian the weekday row restarts at شنبه — a different sequence, not a flipped one —
and if the *Ends · On a date* control opens a month grid, that grid is Shamsi, six rows of
seven starting on شنبه, with Persian digits in DM Mono. Draw it as a second labelled panel
on 197 rather than asking for a fourth number.

One thing the Persian swatch must **not** imply: that the rule itself changed. The stored
`WKST` is deliberately not the locale — `Kati.Recurrence.Rule`: *"a rule authored in fa must
keep its WKST even if the UI later switches to en, or a fortnightly event silently moves."*
The Persian panel changes the order the days are **shown** in and nothing else.

**198 and 199 mirror mechanically** and need no separate artboard: the container gets
`dir="rtl"`, the grid mirrors, chevrons become `chevron_left`, digits and durations go
Persian in DM Mono. What does not mirror: the vertical order of the groups never reverses;
`close`, `add` and `check` are symmetrical; and on 31 the house rule stands —
`arrow_back_ios_new` → `arrow_forward_ios`, though 31 has a close disc rather than a back
pill and so is unaffected.

## Dark

**No dark artboards.** Every colour these three boards use already has a dark value with a
test behind it: paper, card, ink, ink-soft, sub, the `rgba(26,25,23,.07)` hairline, the
`#C4BDB3` chevron and one accent. There is no artwork, no photograph and no gradient over a
still, which is what forced dark boards for 01, 102 and 131. `Kati.Theme.PaletteTest`
writes the light column out by hand and `Kati.ThemeModeTest` asserts `Kati.Theme.light/0`
byte for byte, so a token drawn here resolves in both modes without a second drawing.

Two things to check rather than redraw. The dashed ring on 198's *Add an alert* is 31's own
*Add someone* ring, which ships **solid** at `rgba(26,25,23,.2)` because the bridge's border
has no dash pattern — 31's moduledoc says so; do not draw a dash the app cannot render. And
a light card lifts with a shadow while a dark card lifts with an inset hairline, so the
sheets' rows separate differently in the two modes by design.

## Reuse, do not invent

Every part of all three boards already exists in the app.

- **The sheet.** `Kati.UI.Sheet.sheet/3` — scrim `rgba(26,25,23,.42)`, drawer
  `border-radius: 26px 26px 0 0`, padding `18px 21px 34px`, a 36pt close disc with a 19pt
  glyph, a centred 15px/700 title, and a 36pt empty hole opposite it. Seven screens are
  already this shape.
- **The card and the row — 31's own.** Not the radius-22 card from the house style below:
  this is the `SettingsList` card, `#FBFAF8`, **radius 20**, padding `4px 15px`, rows at
  `13px 0`, hairline `1px solid rgba(26,25,23,.07)`, a 30×30 paper tile (radius 9,
  `#EFECE7`, glyph 17px `#5C574F`), title 13.5px/600 `#1A1917`, second line 11.5px
  `#8A8479` at `margin-top: 3px`, trailing chevron 18px `#C4BDB3`. Measured off
  `test/design/screens/31.html`; use these numbers, not approximations of them.
- **The tick.** 94's `check` at 19px in ink. Not a radio, not a checkbox.
- **The value row that opens a small choice.** 36's Rules group — `percent` · *Tick at* ·
  `90% watched` · `chevron_right` — is the settled shape for exactly this.
- **The month grid**, if *Ends · On a date* uses one: 16's — weekday header, six rows of
  seven, `chevron_left`/`chevron_right` steppers on the month name. `Kati.Calendar.Grid`
  already returns the matrix with the week start as a parameter.
- **The stepper.** 70's unit stepper, and the mono numeral treatment from 31's own `1h`.
- **The chips** under 199: 33's tag pill — height 30, radius 15, card fill, soft card
  shadow — both already `MishkaPill`.
- **The dashed ring** on 198: 31's *Add someone*, as it actually ships (solid, `.2`).
- **The quiet eyebrow** over *Ends*: `Kati.Screens.EventDetail.muted_eyebrow/1`, which is
  the eyebrow with a `#C4BDB3` rule instead of the accent.
- **The scope wording**, if a scope control is drawn: 44's *Edit this week only* /
  *Changes will not carry forward* and 46's *Swap just today* | *Every week* are the app's
  two existing sentences for this idea. Pick from them; do not write a third.

## What it must NOT do

Eight decisions the codebase has already made. None is negotiable in a drawing.

**1. These are screens, not inline expansions.** The question `D-36` had to leave open for
board 33 is already answered for board 31, in the sample's own docstring —
`Kati.Calendar.SampleEvent.fields/0`:

> `trailing` says how each one is changed — a value, a switch, or a chevron into its own
> screen — because *"1 hour before · at start"* cannot be edited in place and *"Timezone"*
> does not need a screen at all.

So do not draw 197–199 as sections that grow inside 31's card. Three chevrons mean three
destinations, and the app has said which rows get one and which do not.

**2. Do not draw screen 31 showing through the scrim.** `Kati.UI.Sheet`:

> A sheet is a page you can see *through*, and the thing you see is the screen underneath —
> which Mob does not composite, because a pushed screen replaces the one below it. So the
> scrim is painted here as a flat fill over `:background`.

Behind the scrim is flat theme background, not a dimmed 31. A board that draws the event
card ghosted behind the sheet is drawing something the bridge cannot produce.

**3. 197 must not offer a rule Kati would corrupt.** `Kati.Recurrence.Rule` parses every
part *"including ones Kati's own editor cannot author (`BYWEEKNO`, `BYYEARDAY`,
`BYSECOND`), because they arrive from mirrored calendars and a rule Kati cannot represent is
a rule Kati would silently corrupt on write-back."* So the sheet has a second job the
presets do not cover: **what it shows when the event's existing rule is one it cannot
edit.** Draw that state — the rule stated, and no control that would rewrite it.

**4. `UNTIL` and `COUNT` are mutually exclusive**, and `Rule.parse/1` *"rejects a value
carrying both rather than silently preferring one."* The Ends group is one choice of three,
never two set at once.

**5. "This and all future" is a split, not a flag.** `Kati.Calendars.Override`: *"Kati never
generates `RANGE=THISANDFUTURE` — §3.4 says the interop technique is to split the series —
but must tolerate reading one."* And `Kati.Sync.split_series/4` is *"two ordered
operations … If the second fails after the first succeeded,
`Kati.Sync.Outbox.partially_synced/1` reports the UID and screen 27 shows an error card
with Retry."* A scope control that offers this is offering an operation that can half-fail,
and the place that failure is already drawn is screen 27 — so do not invent a second one on
197, and do not draw the scope as instantaneous.

**6. 198 is half a design problem and half a missing column, and the brief should say which
half is which.** The board is the design's. The rest is not:

- There is **no alerts column**. `Kati.Screens.EventDetail` states it plainly:
  *"`rrule` is stored and there is no humaniser anywhere in `lib/` … Alerts have no column
  at all."*
- The notification path **exists and already fires** — `Kati.Notifications.Sources.Calendar`
  builds one candidate per event — but it fires **at the event's start and nowhere else**,
  and its id, `Candidate.id(["cal", uid])`, is one id per event. Two alerts on one event is
  two ids, which is a code change, not a drawing.
- **An alert does not round-trip.** `Kati.Sync.Compose`'s property map is `SUMMARY`,
  `LOCATION`, `DESCRIPTION`, `RRULE`, `DURATION`, `STATUS`, `TRANSP`, `ORGANIZER`. There is
  no `VALARM` anywhere in `lib/`, so an alert set in Kati stays on this device and the other
  client never sees it. That is a sentence the sheet has to carry, not a footnote to skip.
- All-day and cancelled events are **suppressed with a reason**, not fired at a guessed
  hour: *"An all-day event has no clock. Picking one for it would be inventing a time the
  user never chose."*
- `Kati.Notifications.Budget` *"divides a fixed number of slots between six domains"*, so
  the sheet must not promise that every alert arrives.

**7. 199 is a text field, not a place search.** `location` is a plain `:string`, pushed as
the `LOCATION` line and printed as the leading half of a row's sub-line on 01, 02 and 28.
Kati has no location permission, no geocoder, no map and no contacts. Drawing a search
field with results, a pin on a map, or a *"nearby"* list would be designing three
capabilities the app does not have. And `Kati.Calendars.Today` records what happens when
this free string is read as though it meant something:

> an event whose location the user had typed as *Money* was routed to Subscriptions, and
> any edit to a word here silently re-routed every row of that kind.

Nothing on 199 may suggest the text is parsed.

**8. Do not draw 44's Repeats row as a frequency picker.** Covered above:
`Kati.Meals.MealPlan.repeat` is a single-valued enum and `D-41` has already said 183's row
must not carry a chevron promising choices. 197's **Ends** group is what 44 can borrow.

## Left open — decide and note which way you went

- **Commit rule, and it comes first because the other answers follow it.** *On Save*: each
  sheet hands a value back, 31's card updates, and Save writes once through
  `Kati.Sync.edit/3` with one `changes` map — which is the shape `Compose.changed/1` was
  written for. *On dismiss*: each sheet writes as it closes, 31's Save becomes redundant,
  and one edit becomes three pushes. Note that 94 commits on tap and has no button at all,
  and that 31's Save pill is currently inert either way — so whichever is chosen, this
  ticket is what gives that pill a job.
- **Whether a scope control appears at all, and on which sheets.** Changing a location on
  one occurrence is as real as changing a time on one, and `Kati.Calendars.Override` holds
  `location` and `summary` as nullable inherit-from-master columns for exactly that. If the
  answer is "only on 197", say so on 198 and 199 so the omission reads as a decision.
- **Where the scope is asked** — inside each picker, or once at 31's Save. Once at Save is
  fewer controls and one confirmation; inside each picker is what most calendars do.
- **How much of RFC 5545 the Custom section reaches.** Weekly-with-`BYDAY` and
  monthly-by-date-or-by-position covers almost every real rule. `BYMONTH`, `BYSETPOS`
  beyond *third Thursday*, and `BYYEARDAY` are the tail. Say where the line is, and what
  the sheet shows for a rule past it (see *must not* #3).
- **The wording of the humaniser.** *Every 2 weeks on Thursday* is board 31's own sentence
  and there is nothing in `lib/` that produces it. The summary line on 197 is where that
  wording is settled for the whole app — 02, 09 and 28 will all read it eventually.
- **What 198 offers as leads**, and whether *Custom* is one of them. A free offset is a
  second control; the seven common ones may be enough.
- **Whether the read-only state is a locked 31 or three locked sheets**, and which sentence
  it prints — `Ownership.refusal/2` already writes two.
- **Whether *Add a location* is a row in the card or a control elsewhere.** A card whose
  rows appear and disappear with their values is what 31 does today; a card with a fixed
  five rows is what the sample draws. One of the two has to give.

## Acceptance

The drawing is complete enough to build from when:

1. For each of the three rows, a reader can say **what a tap opens, what it writes and
   when the write happens** — `rrule`, the alerts column that does not exist yet, and
   `location`.
2. **31 is drawn twice** — the sample's five-row card and a stored event's card — and the
   second one carries a reachable row for *no repeat*, *no alerts* and *no location*. A
   reader can see that 199 is reachable from an event that has no place.
3. **31's `Save` pill has a stated job**, and the board says what happens after it — the
   sheet closes, or it stays.
4. **The read-only state is drawn once**, with the sentence it prints, so a mirrored event
   from a `writeback_policy: :none` calendar is a designed page and not a dead card.
5. Each of 197, 198 and 199 carries its **empty swatch inside its own frame**, under an
   `eyebrow_muted` label, in the 144 manner — because `Kati.ScreenEmptyDatabaseTest` reads
   these literals with nothing stored.
6. **197 carries the Persian panel**, weekday row restarting at شنبه, Shamsi months and
   Persian digits in DM Mono, with a note that the stored `WKST` is unchanged.
7. **198 states, on the board, that an alert is local to this device.**
8. **197 shows what it does with a rule it cannot author.**
9. The scope decision is visible: either a scope control is drawn on the boards that have
   one, or a line says why there is none.
10. Every literal appears **once** across the boards. `Kati.ScreenDesignLiteralTest` asserts
    each against the rendered tree, and copy in a drawing and nowhere in a tree fails the
    sweep.
11. Every subtitle's `font-size`, family and `margin-top` are drawn as numbers, because
    `Kati.ScreenTitleSubtitleTest` measures exactly those three.
12. Every glyph named is one of `close`, `check`, `chevron_left`, `chevron_right`, `repeat`,
    `event_repeat`, `event_busy`, `calendar_month`, `notifications`, `notifications_active`,
    `notifications_off`, `place`, `link`, `schedule`, `history`, `add`, `remove`, `delete`,
    `do_not_disturb_on`, `tune`, `call_split`, `cloud_off`, `lock`, `info` — **all
    twenty-four are already in `Kati.Icons`' map**, so no `mix kati.gen.icons` run and no
    pyftsubset step is needed. If a twenty-fifth is wanted, name it here:
    `Kati.Icons.glyph!/1` raises for a name the font does not carry, and
    `test/design/material_symbols.codepoints` is not in the repo, so a new symbol is a
    blocked build rather than a blank box.

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
