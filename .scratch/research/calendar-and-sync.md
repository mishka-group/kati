# Kati — Calendar & Two-Way Sync

Research for the calendar spine: what a professional calendar must do, how two-way sync
actually works on the wire, what Android gives us for free, the Jalali dimension, the
overlap-rendering problem under Mob, and a phasing that does not paint us into a corner.

**Method.** Every claim below is either (a) quoted from a primary spec/vendor doc with a
URL, (b) quoted from real source on this machine with a path and line number, or (c)
explicitly flagged **UNKNOWN**. Where the received wisdom on the internet is out of date
(and for mobile OAuth it badly is), I say so and cite the current doc.

**Headline verdicts, up front:**

1. **Direct Google Calendar API OAuth is close to a dead end for this app in its current
   form.** Custom URI schemes are blocked, loopback is deprecated on mobile, and the only
   sanctioned Android path is a Google Play Services binary API. On top of that, Calendar
   scopes are *sensitive*, so an unverified project is capped at **100 users for the
   lifetime of the project**. See §4.1 — this is the single most consequential finding.
2. **`CalendarContract` should be the first integration, and it is not a compromise.**
   It is what every respected FOSS Android calendar does (Etar, Simple Calendar). It gets
   Google, Exchange, and — via DAVx⁵ — every CalDAV server, for the price of two runtime
   permissions and zero OAuth. See §6.
3. **There is no usable Elixir RRULE engine.** `cocktail`, the only real candidate, has no
   `FREQ=YEARLY` at all (so: no birthdays), no `BYSETPOS`, no ordinal `BYDAY` (so: no "last
   Friday of the month"), and its own README lists DST bugs as an open roadmap item. This
   is a build-it-ourselves item and it is on the critical path. See §3.5.
4. **The day-view overlap layout is solvable in pure Mob** — but only because the generated
   `MobBridge.kt` in this project already honours undocumented `offset_x`/`offset_y` props.
   Without those you would need a native component. See §8.

---

## Table of contents

1. [What a professional calendar must do](#1-what-a-professional-calendar-must-do)
2. [Benchmark: the seven apps, feature by feature](#2-benchmark-the-seven-apps-feature-by-feature)
3. [Recurrence: RFC 5545 in the detail that bites](#3-recurrence-rfc-5545-in-the-detail-that-bites)
4. [Two-way sync — the transports](#4-two-way-sync--the-transports)
5. [The sync engine](#5-the-sync-engine)
6. [Android-native integration: `CalendarContract`](#6-android-native-integration-calendarcontract)
7. [The Persian/Jalali dimension](#7-the-persianjalali-dimension)
8. [The hard rendering problem: lane assignment under Mob](#8-the-hard-rendering-problem-lane-assignment-under-mob)
9. [Phasing](#9-phasing)
10. [Issues worth filing](#10-issues-worth-filing)

---

## 1. What a professional calendar must do

The design already commits Kati to a real calendar, not a list of reminders. `design-index.md:6`
quotes the design's own header: *"The calendar is the spine that every section feeds into."*
Group D is titled *"Calendar, properly"* (`design-index.md:103`) and group I *"Calendar,
completed"* (`design-index.md:122`). Screen 31 already draws timezone `"Europe/London ·
follows travel"`, recurrence `"Every 2 weeks on Thursday"`, alerts, and invitees with reply
status (`design-index.md:124`). Screen 32 already draws iCloud/Google/CalDAV accounts with
per-feed **write-back** rules (`design-index.md:125`). So the bar is set by the design, not
by me.

Below, each capability is stated as a requirement, with the standard that defines it and the
part that is genuinely hard.

### 1.1 The event model

| Concern | Requirement | Hard part |
|---|---|---|
| **All-day vs timed** | All-day events are *date-valued*, not midnight-to-midnight timestamps. RFC 5545 gives `DTSTART;VALUE=DATE:20260817`. Android has a dedicated `ALL_DAY` column: *"A value of 1 indicates this event occupies the entire day, as defined by the local time zone."* ([Calendar Provider](https://developer.android.com/guide/topics/providers/calendar-provider)) | An all-day event must **not** shift when the user flies to Tehran. Storing it as a UTC instant is the classic bug. Store a `Date`, not a `DateTime`. |
| **Timed** | Instant + IANA timezone id, both stored. `DTSTART;TZID=Europe/London:20260817T093000`. | Storing only UTC loses the authoring zone, so a recurring 09:00 meeting drifts to 10:00 across a DST boundary. **You must keep the TZID.** |
| **Floating time** | RFC 5545's "date with local time" — no `TZID`, no `Z`. Means "09:00 wherever you are". | Correct model for habits, meal slots (screens 43/52), and "take pills at 08:00". Kati has more legitimate floating-time events than a work calendar does. |
| **Duration vs end** | RFC 5545 allows `DTEND` or `DURATION`. Android *requires* `DURATION` for recurring events: *"For recurring events, you must include a `DURATION` in addition to `RRULE` or `RDATE`."* | A 1-hour event that spans a DST spring-forward is 1 hour by `DURATION` and 2 hours by wall-clock `DTEND`. Pick `DURATION` and be consistent. |

**Design consequence for Kati:** the storage decision already locked by the owner
("stored data stays Gregorian/UTC", `design-index.md:151` locale table) needs one
amendment: *Gregorian yes, UTC-only no.* Store `{utc_instant, tzid, wall_clock, is_all_day,
is_floating}`. Jalali stays display-only, which is correct and unaffected.

### 1.2 Timezones and travel

Screen 31 draws `"Europe/London · follows travel"` (`design-index.md:124`). That phrase implies
three distinct behaviours that Fantastical and Apple Calendar separate explicitly:

- **Fixed-zone event** — a flight departing 14:00 Tehran time stays 14:00 Tehran regardless
  of where you are.
- **Floating event** — 08:00 breakfast is 08:00 wherever you wake up.
- **Time zone override / "travel mode"** — the *grid itself* renders in a chosen zone. Apple
  Calendar calls this "Time Zone Override"; Fantastical exposes per-event start/end zones.

These are three different fields, not one toggle. **UNKNOWN:** which of the three the Kati
design intends by "follows travel" — the screen shows only the string. This needs an owner
decision before the event schema is frozen.

Second-order requirement: **the IANA tz database changes several times a year**. On Android
the OS ships it; on the BEAM, `Calendar.get_time_zone_database/0` defaults to a stub that
raises for anything but UTC. Kati must add `tz` or `tzdata` (Elixir) and decide whether to
ship a snapshot or update it. **This is a concrete dependency, not a detail.**

### 1.3 Reminders / alarms

RFC 5545 `VALARM` with `TRIGGER` relative to start or end (`TRIGGER:-PT15M`) or absolute
(`TRIGGER;VALUE=DATE-TIME:...`), plus `REPEAT`/`DURATION` for nagging alarms, and `ACTION`
of `DISPLAY` / `AUDIO` / `EMAIL`. Android's `CalendarContract.Reminders` covers minutes-before
and a method.

**Mob-specific constraint, and it is a real one.** Local notifications *do* work — verified
in native source on both platforms (`mob-framework.md:1096-1098`: *"Elixir can schedule an
OS-level local notification at a future timestamp that the OS fires while the app is dead"*)
via the `mob_notify` plugin. But there is **no scheduler**: `mob-framework.md:1313` —
*"There is no scheduler, no cron, and no WorkManager binding."* So every alarm must be
materialised as an OS notification *at write time*, and re-materialised whenever the event
or its recurrence changes. That means a **notification-reconciliation pass** is a first-class
component, not an afterthought:

- On every event write, cancel + reschedule that event's alarms.
- Recurring events: schedule only the next *N* occurrences (iOS has a hard 64-pending-
  notification limit; Android's is effectively memory-bound but AlarmManager exact alarms
  need `SCHEDULE_EXACT_ALARM`). Top up on app foreground.
- `Mob.Device.open_settings(:exact_alarm)` exists
  (`/Users/shahryar/Desktop/first_mob_beam/fresh_mob_beam/source/mob/lib/mob/device.ex:331`),
  which is the Android 12+ exact-alarm settings deep link — evidence Mob anticipates this.

### 1.4 Snooze and undo

**Snooze** is not a calendar concept — it is a notification concept. Requirement: notification
action buttons that re-arm the alarm for +5/+15/+60 min without opening the app. Screen 51
already draws exactly this for meals: *"a 19:15 'Dinner in 15 minutes' with inline **Eaten /
Skip / Snooze** actions"* (`design-index.md:148`). `mob_notify` supports notification actions
(`mob-framework.md:1208` "Actions"), so this is reachable.

**Undo** is drawn as a system-wide promise: screen 27's fifth band is *"Undo — every
destructive action"* (`design-index.md:226`) and screen 15 *"Doubles as the undo trail"*
(`design-index.md:102`). For a *syncing* calendar this is materially harder than for a local
one, because undo after a push means a second push. Design rule: **undo must be implemented
as a compensating command in the outbox, never as a rollback of local state**, or the outbox
and the store will disagree. See §5.4.

### 1.5 Availability, attendees, RSVP

- **Availability / busy** — RFC 5545 `TRANSP:OPAQUE|TRANSPARENT`; Android `AVAILABILITY`
  (*"If this event counts as busy time or is free time that can be scheduled over"*);
  Google's `transparency`. Cheap to model, cheap to round-trip. **Do it from day one** even
  if nothing reads it, because dropping it on round-trip is data loss.
- **Attendees / RSVP** — `ATTENDEE;PARTSTAT=ACCEPTED;ROLE=REQ-PARTICIPANT;RSVP=TRUE:mailto:…`,
  plus `ORGANIZER`. Screen 31 draws *"invitees with reply status"* (`design-index.md:124`).
  **Reading and displaying attendees is easy. *Responding* to an invitation is not** — it is
  iTIP/iMIP (RFC 5546), which means either the server does scheduling for you (Google's
  `events.patch` on `attendees[].responseStatus`, CalDAV scheduling per RFC 6638) or you send
  MIME email. For a no-server app, **read-only attendees is the honest scope**, with RSVP
  deferred until a transport that does scheduling server-side is in place.
- **Free/busy lookup** — Google `freebusy.query`; CalDAV `free-busy-query` REPORT.
  Note: Google's CalDAV endpoint does **not** implement it — *"All reports except
  `free-busy-query` are implemented"*
  ([CalDAV guide](https://developers.google.com/workspace/calendar/caldav/v2/guide)).

### 1.6 Attachments

RFC 5545 `ATTACH` takes either a URI or inline `ENCODING=BASE64;VALUE=BINARY`. Google models
attachments as Drive file links. **Recommendation: store the `ATTACH` property verbatim and
render links; never inline binary.** Inlining bloats every PUT and every sync payload, and
SQLite-on-device (`mob-framework.md:1338-1356`) is the wrong place for blobs. This is also a
round-tripping requirement — see §5.6.

### 1.7 Multiple calendars, colours, visibility

Screen 32 is literally this screen: *"Accounts (iCloud Live, Google Live, CalDAV **Stale**
'last sync 4h ago'), which calendars show, **Write back** rules per feed"*
(`design-index.md:125`). The model needed:

```
Account (provider, credentials_ref, display_name, state)
  └─ Calendar (remote_id, display_name, colour, read_only?, visible?, writeback_policy)
       └─ Event
```

`writeback_policy` is the interesting one, and the design already states the rule: screen 32
carries *"the privacy note about never touching an event it did not create"*
(`design-index.md:125`). That is a **strong, correct default** and it maps exactly onto the
ownership model in §5.5. Colour: CalDAV exposes `apple:calendar-color` (an `#RRGGBBAA`
string); Google exposes `colorId` into a fixed palette plus `backgroundColor`; Android has
`CALENDAR_COLOR`. All three round-trip badly into each other — **store the source colour
verbatim and map to Kati's palette for display**, since Kati's palette is a locked design
system (`design-index.md:255-278`) and foreign hex values would break it.

### 1.8 Views

The design mandates five: Day (02), Week (17), Month (16), Agenda (30), and the density
reference (09), plus a 3-day view is *not* drawn. Requirements per view:

| View | Requirement | Note for Kati |
|---|---|---|
| **Day** | Time gutter, proportional blocks, overlap lanes, all-day band | Screen 09 spec: *"sequential cards, `2 at once` split lanes capped at two columns with a `+1 MORE` tile, 3+ same-kind grouped cards with poster stacks, an all-day band, merged money events"* (`design-index.md:94`). See §8. |
| **3-day** | Same engine, narrower columns | Not in the design. Falls out free once §8 works; worth adding for phones held in landscape. |
| **Week** | 7 columns, block height ∝ duration | Screen 17: *"Seven nameless lanes; block height = duration, colour = section"* (`design-index.md:105`). |
| **Month** | 6×7 grid, load indicators | Screen 16: *"6×7 grid with per-section dots"* (`design-index.md:104`). Six rows is the right choice — a 5-row month grid breaks for months starting late in the week. |
| **Year** | 12 mini-months | Not drawn. Fantastical and Apple ship it. Low value for Kati's density-first design; **skip**. |
| **Agenda** | Skips empty days, states gaps | Screen 30: *"skips empty days entirely… gaps stated ('Nothing else until 12 Sep')"* (`design-index.md:123`). This is a nicer agenda than Google's. |

**Week start and working hours.** Locale-driven, and Kati has already specified it: the locale
table (`design-index.md:164-169`) gives `en → Monday`, `fa → Saturday`, and screen 54 lists
week start among *"the five settings that follow the language"*, *"each still overridable"*
(`design-index.md:152`). Working hours are undrawn; they matter for the week/day grid's
default scroll position and dimming. **Recommend: a simple `work_start`/`work_end`/`work_days`
triple in settings, used only for initial scroll offset and background tint.**

### 1.9 Search

Screen 19 does cross-section search with scope tabs including `Calendar 2`
(`design-index.md:108`). SQLite via Ash gives us FTS5 for free if we ask for it. Requirement:
title + location + description + attendee names, ranked, with the recurrence expanded lazily
(you search *events*, you display *occurrences*).

### 1.10 Natural-language quick add

Screen 18 is remarkably well specified: *"'dentist thu 11am for 45m, remind 1h before' with
tokens highlighted in place, 'Kati read that as' preview card, clash warning *before* save"*
(`design-index.md:106`). This is the Fantastical interaction, and Fantastical's own
description of its parser is: *"understands dates, times, durations, recurrence, locations,
invitees, and alerts"* ([Flexibits](https://flexibits.com/fantastical)).

Two things make Kati's version harder and one makes it easier:

- **Harder:** it must also route to non-calendar types — screen 18's *"Or file it as"* chips
  are `Event/Reminder/Title/Habit/Note/Expense`. That is intent classification, not just date
  parsing.
- **Harder:** it must parse **Persian**. `پنجشنبه ۱۱ صبح` needs Persian digit folding
  (U+06F0–U+06F9), Persian weekday names, and Jalali date literals (`۲۵ مرداد`).
- **Easier:** it can be a hand-written token grammar. NimbleParsec is already in the
  dependency graph (Mob compiles `~MOB` with it, `mob-framework.md:303`), and a
  chart-parser over a fixed lexicon of ~200 tokens per locale is a weekend, not a research
  project. **No LLM, no server.** The "Kati read that as" preview card is what makes a
  deterministic parser acceptable — the user sees and corrects the interpretation.

---

## 2. Benchmark: the seven apps, feature by feature

Sourced from vendor documentation and store listings; where I could not verify a claim from a
primary source I have marked it **UNVERIFIED** rather than assert it.

| Capability | Fantastical | Notion Calendar | Google Calendar | Business Calendar 2 | Etar | Apple Calendar | Outlook |
|---|---|---|---|---|---|---|---|
| Backing store | EventKit (iOS/macOS) | Google/Microsoft APIs | own | `CalendarContract` | `CalendarContract` | EventKit / CalDAV | Graph / EAS |
| Full RRULE authoring | yes | limited | limited UI, full storage | yes | yes (AOSP editor) | yes | limited |
| NL quick add | **flagship** | yes | yes ("Quick add") | no | no | limited | no |
| Travel time | **yes** (time-to-leave, travel blocks) | no | yes | no | no | yes | no |
| Conference-link detect | **yes** (Zoom/Teams/Webex/…) | yes | yes | no | no | no | yes |
| Calendar sets/groups | **yes**, incl. time-activated | no | no | yes | no | no | no |
| Proposals / poll times | yes | yes | no | no | no | no | yes (FindTime) |
| Views incl. year | D/W/M/Q/**Y** + list | D/W/M | D/3D/W/M/Y/schedule | D/W/M/Y/agenda + custom | M/W/D/agenda | D/W/M/Y | D/W/M/agenda |
| Open source | no | no | no | no | **yes** | no | no |
| Does its own sync? | via EventKit | yes | yes | **no** | **no** | CalDAV yes | yes |

**Sources.** Fantastical: [flexibits.com/fantastical](https://flexibits.com/fantastical),
[App Store listing](https://apps.apple.com/us/app/fantastical-calendar/id718043190),
[iClarified on calendar sets & conference detection](https://www.iclarified.com/76298/fantastical-gets-new-workfromhome-features-including-automatic-conference-call-detection-timed-calendars-sets-more).
Etar: [README](https://github.com/Etar-Group/Etar-Calendar/blob/master/README.md),
[F-Droid](https://f-droid.org/packages/ws.xsoh.etar/).

### The two lessons that actually matter for Kati

**Lesson 1 — the best FOSS Android calendars do not implement sync.** Etar's README is
unambiguous: it *"Uses Android calendar storage to show all synchronized calendars"*, and
*"a Caldav client isn't included in Etar"* — users install DAVx⁵ separately. Simple Calendar
Pro takes the same route. This is not laziness; it is the correct architecture on Android,
because the OS already runs the sync adapters, in the background, with the OS's own battery
and network policy. **Kati should copy it.** See §6.

**Lesson 2 — Fantastical's moat is the parser and the *views*, not the sync.** Fantastical
does no sync at all; it reads EventKit. Everything users pay for — NL parsing, calendar sets,
travel time, the DayTicker — is presentation and input. Kati's design is already competitive
on exactly those axes (screen 18's inline token highlighting and pre-save clash warning is
*better* than Fantastical's) and is not competitive on sync. **Invest accordingly.**

---

## 3. Recurrence: RFC 5545 in the detail that bites

Spec: [RFC 5545](https://www.rfc-editor.org/rfc/rfc5545.txt) (fetched in full; line numbers
below refer to that text file).

### 3.1 The RRULE grammar

`FREQ` is required and **must come first**: *"Compliant applications MUST accept rule parts
ordered in any sequence, but to ensure backward compatibility with applications that pre-date
this revision of iCalendar the FREQ rule part MUST be the first rule part specified in a RECUR
value."* (§3.3.10, rfc5545.txt:2222-2226)

`UNTIL` and `COUNT` are mutually exclusive: *"The UNTIL or COUNT rule parts are OPTIONAL, but
they MUST NOT occur in the same 'recur'."*

Rule parts: `FREQ`, `UNTIL`, `COUNT`, `INTERVAL`, `BYSECOND`, `BYMINUTE`, `BYHOUR`, `BYDAY`,
`BYMONTHDAY`, `BYYEARDAY`, `BYWEEKNO`, `BYMONTH`, `BYSETPOS`, `WKST`.

### 3.2 The three rules everyone gets wrong

**(a) `UNTIL` must match `DTSTART`'s value type.** rfc5545.txt:2255-2271:

> "The value of the UNTIL rule part MUST have the same value type as the "DTSTART" property.
> Furthermore, if the "DTSTART" property is specified as a date with local time, then the
> UNTIL rule part MUST also be specified as a date with local time. If the "DTSTART" property
> is specified as a date with UTC time or a date with local time and time zone reference, then
> the UNTIL rule part MUST be specified as a date with UTC time."

So an all-day recurring event gets `UNTIL=20261231`, and a zoned timed one gets
`UNTIL=20261231T170000Z`. Mixing them is the most common interop failure with Google and
iCloud.

**(b) Invalid instances are dropped, not clamped.** rfc5545.txt:2382-2386:

> "Recurrence rules may generate recurrence instances with an invalid date (e.g., February 30)
> or nonexistent local time (e.g., 1:30 AM on a day where the local time is moved forward by
> an hour at 1:00 AM). Such recurrence instances MUST be ignored and MUST NOT be counted as
> part of the recurrence set."

`FREQ=MONTHLY;BYMONTHDAY=31` therefore **skips** February, April, June, September and
November — it does not fall back to the 28th/30th. Users find this surprising; Google's UI
avoids it by offering "last day of month" as `BYMONTHDAY=-1`. Kati's recurrence editor should
do the same.

**(c) `BYxxx` parts either *expand* or *limit*, and the order is fixed.** rfc5545.txt:2419-2422:
`BYMONTH`, `BYWEEKNO`, `BYYEARDAY`, `BYMONTHDAY`, `BYDAY`, `BYHOUR`, `BYMINUTE`, `BYSECOND`,
`BYSETPOS`; *"then COUNT and UNTIL are evaluated."* The table (rfc5545.txt:2430-2452):

```
   +----------+--------+--------+-------+-------+------+-------+------+
   |          |SECONDLY|MINUTELY|HOURLY |DAILY  |WEEKLY|MONTHLY|YEARLY|
   +----------+--------+--------+-------+-------+------+-------+------+
   |BYMONTH   |Limit   |Limit   |Limit  |Limit  |Limit |Limit  |Expand|
   |BYWEEKNO  |N/A     |N/A     |N/A    |N/A    |N/A   |N/A    |Expand|
   |BYYEARDAY |Limit   |Limit   |Limit  |N/A    |N/A   |N/A    |Expand|
   |BYMONTHDAY|Limit   |Limit   |Limit  |Limit  |N/A   |Expand |Expand|
   |BYDAY     |Limit   |Limit   |Limit  |Limit  |Expand|Note 1 |Note 2|
   |BYHOUR    |Limit   |Limit   |Limit  |Expand |Expand|Expand |Expand|
   |BYMINUTE  |Limit   |Limit   |Expand |Expand |Expand|Expand |Expand|
   |BYSECOND  |Limit   |Expand  |Expand |Expand |Expand|Expand |Expand|
   |BYSETPOS  |Limit   |Limit   |Limit  |Limit  |Limit |Limit  |Limit |
   +----------+--------+--------+-------+-------+------+-------+------+

      Note 1:  Limit if BYMONTHDAY is present; otherwise, special expand
               for MONTHLY.
      Note 2:  Limit if BYYEARDAY or BYMONTHDAY is present; otherwise,
               special expand for WEEKLY if BYWEEKNO present; otherwise,
               special expand for MONTHLY if BYMONTH present; otherwise,
               special expand for YEARLY.
```

This table *is* the algorithm. An implementation that follows it literally is correct; one
that special-cases common patterns is not. Also note `BYSECOND` accepts `0 to 60` — leap
seconds.

**`WKST` matters more for Kati than for most apps.** `WKST` changes which weeks
`FREQ=WEEKLY;INTERVAL=2` groups together. With `fa` locale defaulting to Saturday
(`design-index.md:167`), a fortnightly Persian event and a fortnightly English event with the
same `DTSTART` can land on different dates. **Store `WKST` explicitly on every weekly rule
with `INTERVAL > 1`, derived from the calendar's locale at authoring time — do not let it
float with the UI language.**

### 3.3 EXDATE, RDATE, RECURRENCE-ID

- **`EXDATE`** (§3.8.5.1) — timestamps removed from the recurrence set. Value type must match
  `DTSTART`'s. Multiple `EXDATE` lines are allowed and are unioned.
- **`RDATE`** (§3.8.5.2) — extra timestamps added, and it may carry `VALUE=PERIOD` for
  one-off instances of a different duration. *"Duplicate instances are ignored"* (rfc5545.txt:6638).
- **`RECURRENCE-ID`** (§3.8.4.4) — a *separate `VEVENT` component with the same `UID`* that
  overrides one instance. The `RECURRENCE-ID` value is the instance's **original** start time,
  not its new one.

**Result: a recurring event is not one row.** It is a *master* `VEVENT` plus zero or more
*override* `VEVENT`s sharing a `UID`. Any data model that stores "one event = one row with an
rrule string" cannot represent a moved instance. This is the single most important modelling
consequence in this document. See §5.6.

### 3.4 "This event / this and following / all"

RFC 5545 defines `RANGE` on `RECURRENCE-ID` (§3.2.13). Verified from the fetched RFC:

- Only one value is legal: **`THISANDFUTURE`**, *"a range defined by the recurrence identifier
  and all subsequent instances."*
- Default with no `RANGE` is the single instance.
- `THISANDPRIOR` is deprecated and *"MUST NOT be generated by applications."*

Example from the RFC: `RECURRENCE-ID;RANGE=THISANDFUTURE:19980401T133000Z`

**But almost nobody implements `RANGE=THISANDFUTURE`.** The de-facto interop technique — and
the one Google documents — is the *split*:

> "Call `events.update()` to trim the original recurring event by setting `UNTIL` before the
> target instance's start time, or using `COUNT` instead. Call `events.insert()` to create a
> new recurring event with identical data except the desired change, starting at the target
> instance time."
> — [Google, Recurring events](https://developers.google.com/workspace/calendar/api/guides/recurringevents)

Google also warns against the naive alternative: *"You should not modify instances
individually when you want to modify 'this and following' instances, as this creates lots of
exceptions that clutter the calendar, slowing down access and sending a high number of change
notifications to users."*

**Therefore the three edit modes must be implemented as follows:**

| Mode | Local operation | What goes to the remote |
|---|---|---|
| **This event only** | Insert an override row (`recurrence_id` = original start) | New `VEVENT` with same `UID` + `RECURRENCE-ID`; Google: `PUT /events/{instanceId}` |
| **This and following** | Set `UNTIL` on the master to *just before* this instance; insert a new master starting here, carrying over the overrides that fall after the split | Two operations, in that order, ideally atomically — see §5.4 on partial failure |
| **All events** | Patch the master; **decide what happens to existing overrides** | One update. Google/Apple keep overrides unless the field changed conflicts. |

The "all events" case has an under-specified sub-question that every calendar answers
differently: *if I change the master's time by +1h, do my previously-moved instances move
too?* Apple keeps overrides put; Google keeps them put. **Recommendation: keep overrides,
and surface a count ("3 moved occurrences will keep their own times") in the confirmation.**
Screen 44's repeat-rule rows already prove the design is comfortable with this kind of
explicitness: *"Repeats every week, indefinitely", "Started Week 6 · 6 Jul 2026", "Edit this
week only"* (`design-index.md:141`).

### 3.5 The Elixir library situation — a blocker

Queried hex.pm directly (`curl https://hex.pm/api/packages/<name>`, 2026-08-17):

| Package | Latest | Last updated | Verdict |
|---|---|---|---|
| `cocktail` | 0.10.3 | 2024-01-03 | **Insufficient** — see below |
| `icalendar` | 1.1.3 | 2026-02-10 | Generator only (*"An ICalendar file generator"*) |
| `ex_ical` | 0.2.0 | 2018-06-29 | Abandoned |
| `caldav_client` | 2.0.0 | 2022-03-07 | Useful reference; explicitly out of scope for iCal conversion |
| `ex_cldr_calendars` | 2.4.4 | 2026-06-26 | Actively maintained, 2.9M downloads |
| `ex_cldr_calendars_persian` | 1.1.1 | 2025-03-19 | See §7 |
| `jalaali` | 0.4.1 | 2023-06-25 | See §7 |

**Cocktail cannot express the recurrences a calendar needs.** From
[`lib/cocktail.ex:11`](https://github.com/peek-travel/cocktail/blob/master/lib/cocktail.ex):

```elixir
@type frequency :: :monthly | :weekly | :daily | :hourly | :minutely | :secondly
```

**There is no `:yearly`.** That alone rules it out — birthdays and anniversaries are the most
common recurring events in a *personal* calendar, which is exactly what Kati is.

The full option list (`lib/cocktail.ex:36-47`) is `:frequency, :interval, :count, :until,
:days, :days_of_month, :hours, :minutes, :seconds, :times, :time_range`. Cross-referencing
against §3.1, that means **missing: `BYMONTH`, `BYYEARDAY`, `BYWEEKNO`, `BYSETPOS`, `WKST`,
and ordinal `BYDAY`** (`@type day :: day_number | day_atom` has no ordinal, so `BYDAY=-1FR`
— "last Friday of the month" — is inexpressible). The `lib/cocktail/validation/` directory
confirms it: `day.ex, day_of_month.ex, hour_of_day.ex, interval.ex, minute_of_hour.ex,
schedule_lock.ex, second_of_minute.ex, shift.ex, time_of_day.ex, time_range.ex`.

Its own README roadmap admits the rest:

> - [ ] investigate and fix DST bugs when using zoned DateTime
> - [ ] support all iCalendar RRULE options
> - [ ] support week-start option
> - [ ] support iCalendar EXRULE

Cocktail *does* have `add_recurrence_time/2` and `add_exception_time/2` (RDATE/EXDATE
equivalents) and `to_i_calendar/from_i_calendar`, which is genuinely useful.

**Recommendation:** write `Kati.Recurrence` — a from-scratch RRULE expander implementing the
expand/limit table in §3.2(c) literally, as a pure function
`expand(dtstart, tzid, rrule, rdates, exdates, window) :: [DateTime.t()]`. Budget: this is
roughly 600–900 lines with a good test suite, and the RFC ships ~40 worked examples in §3.8.5.3
that make excellent test vectors. **Do not vendor libical via NIF** — `mob-framework.md:491-493`
notes static linking is mandatory and *"On physical iOS, `dlopen` of `.so` files fails
silently"*, so a C dependency multiplies the native-shell fork problem
(`mob-framework.md:1517`) for no gain over pure Elixir here.

Reuse `cocktail` only if the schedule is simple, or lift its `Cocktail.Span` idea. Reuse
`ex_cldr_calendars` for week/month arithmetic — it is the maintained one.

---

## 4. Two-way sync — the transports

### 4.1 Google Calendar API — and the OAuth wall

#### 4.1.1 The client-secret question is the easy part

Google is explicit that native apps cannot hold secrets
([OAuth 2.0 for Mobile & Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app)):

> "Installed apps are distributed to individual devices, and it is assumed that these apps
> cannot keep secrets."

and

> "The `client_secret` is not applicable to requests from clients registered as Android, iOS,
> or Chrome applications."

So: an Android OAuth client type needs **no secret**, and the *client ID* is not a secret
either — it can sit in the open-source repo. **The "we can't ship a client secret" worry is
solved by registering an Android client type, not a Web/Desktop one.** Good.

#### 4.1.2 The hard part: there is no longer a redirect URI we can use

Same page, current text:

> "Custom URI schemes are no longer supported due to the risk of app impersonation."

and

> "support for the loopback IP address redirect option on **mobile apps** is [DEPRECATED]"

This is the culmination of a policy announced in
[Improving user safety in OAuth flows](https://developers.googleblog.com/en/improving-user-safety-in-oauth-flows-through-new-oauth-custom-uri-scheme-restrictions/):

> "By default, new Android apps will no longer be allowed to use Custom URI schemes"

with the recommended alternative being *"Google Identity Services for Android SDK to deliver
the OAuth 2.0 response directly to your app"*. Existing clients were grandfathered; new ones
are not — and Kati is new.

**The consequence for Kati is severe and specific.** The RFC 8252 / AppAuth pattern
(system browser + PKCE + `com.example.kati:/oauth2redirect`) that every "how to do OAuth in a
mobile app" tutorial teaches **will not be approvable for a new Android OAuth client**. PKCE
is still supported and still correct (*"Google supports the Proof Key for Code Exchange (PKCE)
protocol to make the installed app flow more secure"*, `code_challenge_method=S256`), but PKCE
does not help if there is no legal redirect URI.

The sanctioned path is [`AuthorizationClient`](https://developer.android.com/identity/authorization):

> "For authorizing actions that need access to user data stored by Google, we recommend using
> `AuthorizationClient`."

```gradle
implementation "com.google.android.gms:play-services-auth:21.6.0"
```

```kotlin
val requestedScopes: List<Scope> = listOf(Scope("https://www.googleapis.com/auth/calendar"))
val authorizationRequest = AuthorizationRequest.builder()
    .setRequestedScopes(requestedScopes)
    .build()

Identity.getAuthorizationClient(activity)
    .authorize(authorizationRequest)
    .addOnSuccessListener { authorizationResult ->
        if (authorizationResult.hasResolution()) {
            val pendingIntent = authorizationResult.pendingIntent
            startAuthorizationIntent.launch(
                IntentSenderRequest.Builder(pendingIntent!!.intentSender).build())
        } else {
            // Access was previously granted
        }
    }
    .addOnFailureListener { e -> Log.e(TAG, "Failed to authorize", e) }
```

App identity is established by **package name + SHA-1 signing certificate fingerprint**, not
by a secret:

> "Enter the SHA-1 signing certificate fingerprint of the app distribution. If your app uses
> app signing by Google Play, copy the SHA-1 fingerprint from the app signing page of the
> Play Console."

**Four consequences the owner needs to weigh:**

1. **It is a Play Services binary dependency.** That means a Mob native extension (Tier-1/2
   plugin, `mob-framework.md:556-566`) — Kotlin calling `Identity.getAuthorizationClient`,
   handing the token back over the NIF boundary. Not hard, but it is native code in the
   `MobBridge.kt` we already own, and it deepens the fork problem.
2. **The GitHub-APK build and the Play build have different SHA-1s.** Play App Signing
   re-signs. So you need **two Android OAuth client IDs** in the same Cloud project (one per
   fingerprint), and a debug one besides. Not a blocker, just paperwork nobody warns you about.
3. **No GMS = no Google sync.** GrapheneOS, /e/OS, F-Droid-purist devices, and Huawei have no
   Play Services. For an open-source app whose audience skews exactly that way, this is a real
   population. `CalendarContract` (§6) has no such problem.
4. **UNKNOWN:** whether Google would approve a Chrome-Custom-Tabs + loopback flow for a new
   Android client today as an exception. The doc says deprecated, not removed. Do not plan on it.

#### 4.1.3 The verification wall

Calendar scopes are **sensitive**. Google's own example:
*"Reading events stored in Google Calendar is an example of a sensitive scope"*
([Sensitive scope verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification)).

Unverified projects requesting sensitive scopes are capped:

> "unverified apps that are accessing restricted or sensitive scopes have a 100 new-user cap
> restriction"

and, critically:

> "The user cap applies over the entire lifetime of the project, and it cannot be reset or
> changed."

Users below the cap also see an interstitial warning screen before consent. Verification
requires a published privacy policy, a homepage on a **domain you have verified in Search
Console**, a demo video, and a review that *"can take up to 10 days"*.

**This is the decisive constraint.** An open-source personal app shipping on Play + App Store
+ GitHub APK either (a) does the verification properly — feasible, since Kati will need a
privacy policy and a site anyway, but it is a recurring compliance obligation with a
non-trivial chance of rejection or later re-review; or (b) accepts a hard ceiling of 100
Google-connected users forever; or (c) **asks each user to paste their own OAuth client ID**,
which some FOSS apps do and which is a genuinely awful onboarding experience; or (d) **does
not talk to Google directly at all** and lets the OS sync adapter do it (§6).

**(d) is the recommendation.** It is also, not coincidentally, what Etar does.

#### 4.1.4 Incremental sync — `syncToken`

([Synchronize resources efficiently](https://developers.google.com/workspace/calendar/api/guides/sync))

- Initial full list returns `nextSyncToken`; store it.
- Subsequent lists pass `syncToken=…` and return only changes.
- *"the result will always contain deleted entries, so that the clients get the chance to
  remove them from storage"* — deletions arrive as events with `status: "cancelled"`, **not**
  as absences. This is the tombstone mechanism, and it is why you must not treat "not in the
  response" as "deleted".
- Token invalidation: *"the server will respond to an incremental request with a response code
  `410`"*, which *"should trigger a full wipe of the client's store and a new full sync"*:

```java
if (e.getStatusCode() == 410) {
  // A 410 status code, "Gone", indicates that the sync token is invalid.
  syncSettingsDataStore.delete(SYNC_TOKEN_KEY);
  eventDataStore.clear();
  run();
}
```

  ⚠️ **Do not implement that sample literally in Kati.** `eventDataStore.clear()` is safe for
  a pure mirror; Kati's store also holds Kati-owned events and unpushed local edits. A 410
  must clear only the *mirror rows for that calendar* and must preserve the outbox. See §5.3.
- *"The set of query parameters that can be used on incremental syncs is restricted. Each list
  request should use the same set of query parameters, including the initial request."* —
  changing `timeMin` between syncs invalidates the token (HTTP 400). **So pick the sync window
  once, at account-connect time, and never change it silently.** If the user later wants
  history, that is a deliberate full resync.
- `singleEvents=true` expands recurrences server-side. **Do not use it for sync** — you would
  mirror occurrences instead of rules and lose the ability to edit the series. Use it only for
  read-only feeds (holidays, subscribed ICS).

#### 4.1.5 Push vs polling — settled by the no-server constraint

([Push notifications](https://developers.google.com/workspace/calendar/api/guides/push))

> "This is your webhook callback URL, and it must use HTTPS."

Self-signed certificates are explicitly rejected. And the payload is useless on its own:

> "Notification messages posted by the Google Calendar API to your receiving URL do not include
> a message body. These messages do not contain specific information about updated resources,
> you will need to make another API call to see the full change details."

A device-first app with **no server** (owner's locked decision) cannot host an HTTPS webhook
with a CA-signed cert. **Push is out. Polling is the only option.** Which collides with
`mob-framework.md:1313` (*"There is no scheduler, no cron, and no WorkManager binding"*) and
`mob-framework.md:1324` (*"iOS: no. Categorically, with current Mob. Nothing runs."*).

**Therefore Kati's sync cadence is: on app foreground, on user pull-to-sync, and on explicit
user action.** That is honest, it matches screen 32's design (which already draws a **Stale**
badge with *"last sync 4h ago"*, `design-index.md:125` and `:233`), and it is another argument
for §6 — because `CalendarContract` data is kept fresh by the OS's sync adapters whether Kati
is running or not.

#### 4.1.6 Quotas

([Usage limits](https://developers.google.com/workspace/calendar/api/guides/quota))

| Limit | Value |
|---|---|
| Per minute per project | 10,000 requests |
| Per minute **per user** per project | **600 requests** |
| Per day per project | 1,000,000 requests |

Errors are `403 usageLimits` or `429 usageLimits`. Required backoff:
`min(((2^n)+random_number_milliseconds), maximum_backoff)`, with `maximum_backoff` *"typically
32 or 64 seconds"* and *"randomization of up to 1,000 milliseconds"*.

600/min/user is generous for a personal calendar but easy to blow through on a first full sync
of a decade of history with per-event GETs. **Use `events.list` pagination, never per-event
fetches.**

### 4.2 CalDAV

Specs: [RFC 4791](https://datatracker.ietf.org/doc/html/rfc4791) (CalDAV),
[RFC 6578](https://datatracker.ietf.org/doc/html/rfc6578) (collection sync),
`http://calendarserver.org/ns/` `getctag` (a non-IETF extension), and the best practical
write-up, [sabre/dav's *Building a CalDAV client*](https://sabre.io/dav/building-a-caldav-client/).

#### 4.2.1 Discovery

Chain: `PROPFIND /` for `DAV:current-user-principal` → `PROPFIND {principal}` for
`caldav:calendar-home-set` → `PROPFIND {home} Depth: 1` for the calendar list.

```xml
PROPFIND /calendars/johndoe/ HTTP/1.1
Depth: 1
Content-Type: application/xml; charset=utf-8

<d:propfind xmlns:d="DAV:" xmlns:cs="http://calendarserver.org/ns/"
    xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop>
     <d:resourcetype />
     <d:displayname />
     <cs:getctag />
     <c:supported-calendar-component-set />
  </d:prop>
</d:propfind>
```

Filter to entries whose `resourcetype` contains `<c:calendar/>`, and check
`supported-calendar-component-set` for `VEVENT` (some collections are `VTODO`-only).

Also worth supporting: `.well-known/caldav` (RFC 6764) and `_caldavs._tcp` SRV records, which
is how a user typing just `fastmail.com` gets bootstrapped.

#### 4.2.2 Three change-detection mechanisms, in preference order

1. **`sync-collection` REPORT (RFC 6578)** — the good one.

```xml
REPORT /calendars/johndoe/home/ HTTP/1.1
Content-Type: application/xml; charset="utf-8"

<d:sync-collection xmlns:d="DAV:">
  <d:sync-token>http://sabredav.org/ns/sync/3145</d:sync-token>
  <d:sync-level>1</d:sync-level>
  <d:prop><d:getetag/></d:prop>
</d:sync-collection>
```

   Deletions are explicit: *"For members that have been removed, the `DAV:response` MUST
   contain one `DAV:status` with a value set to '404 Not Found' and MUST NOT contain any
   `DAV:propstat` element."* Token invalidation surfaces as the `DAV:valid-sync-token`
   precondition (sabre reports it as HTTP 403), and *"Servers MUST limit themselves to
   invalidating tokens only when absolutely necessary."* Tokens are opaque: *"The
   synchronization token itself MUST be treated as an 'opaque' string by the client."*

2. **`getctag` + etag diff** — the fallback when `sync-token` is absent. Poll the ctag; if it
   changed, run a `calendar-query` REPORT asking only for `getetag`, and diff against your
   cached etags to derive created/updated/deleted. One cheap request when nothing changed.

3. **Full `calendar-query` with `calendar-data`** — initial sync only.

Fetch changed objects in **one** `calendar-multiget`, not N GETs:

```xml
<c:calendar-multiget xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
    <d:prop><d:getetag /><c:calendar-data /></d:prop>
    <d:href>/calendars/johndoe/home/132456762153245.ics</d:href>
    <d:href>/calendars/johndoe/home/fancy-caldav-client-1234253678.ics</d:href>
</c:calendar-multiget>
```

#### 4.2.3 Writes and optimistic concurrency

```
PUT /calendars/johndoe/home/132456762153245.ics HTTP/1.1
Content-Type: text/calendar; charset=utf-8
If-Match: "2134-314"
```

`If-Match` with the cached etag is the conflict detector: a `412 Precondition Failed` means
the server copy moved under you. Creates use `If-None-Match: *`. Deletes take `If-Match` too.

#### 4.2.4 The four quirks that will cost you a day each

Quoting sabre's warnings, which are the accumulated scar tissue of the ecosystem:

1. **Retain the raw iCalendar.** *"I strongly recommend _always_ retaining the iCalendar the
   server sent to you."* Non-standard properties must survive a round trip. This is the
   requirement that shapes the data model — see §5.6.
2. **ETags are not guaranteed on write.** *"an ETag is often returned, but there are cases
   where this is not true. There are cases where the caldav server must modify the iCalendar
   object right after storage."* Fix: if no `ETag` header comes back, immediately `GET` the
   resource. (Google's CalDAV and iCloud both do server-side rewriting — adding `SEQUENCE`,
   normalising `VTIMEZONE`.)
3. **URLs are opaque.** *"You must not rely on"* `.ics` extensions or a UID↔URL relationship.
   Store the href the server gave you. Corollary: **UID is immutable** and it is one VEVENT
   family (one `UID`, master + overrides) per resource.
4. **Multistatus parsing is fiddly.** Status elements appear at two nesting levels; a
   `207 Multi-Status` can contain per-resource failures. Never treat 207 as success.

**Per-server notes.**
- **Google CalDAV** — endpoints `https://apidata.googleusercontent.com/caldav/v2/CALENDAR_ID/user`
  and `.../events`. **It does not escape the OAuth problem**: *"The CalDAV server refuses to
  authenticate a request unless it arrives over HTTPS with OAuth 2.0 authentication of a Google
  Account"*, and *"Attempting to connect over HTTP or using Basic Authentication results in an
  HTTP `401 Unauthorized` status code."* It supports RFC 6578 (*"Client applications must
  switch to this mode of operation after the initial sync"*) and ctag; all REPORTs except
  `free-busy-query`.
- **iCloud** — needs an **app-specific password**, not the Apple ID password; discovery starts
  at `https://caldav.icloud.com` and redirects to a per-user shard host (`p##-caldav…`), so the
  client must follow cross-host redirects and re-resolve the principal. **UNKNOWN to me from
  primary sources:** whether iCloud currently advertises `sync-token` on all collections;
  historically it did not on some, making ctag+etag the safe default. Test, do not assume.
- **Fastmail** — a well-behaved, standards-first server; supports `.well-known`, SRV,
  `sync-collection`. ([Fastmail's own sync guide](https://www.fastmail.help/hc/en-us/articles/360058752754-How-to-synchronize-a-calendar).)

**Elixir tooling:** `caldav_client` 2.0.0 (last released 2022-03-07) exists and is a useful
reference for the XML shapes, but its own description concedes *"conversion between native
Elixir structures and iCalendar format (RFC 5545) is beyond the scope of this library."*
Treat it as documentation, not a dependency.

### 4.3 Exchange / Microsoft Graph

Endpoint: `GET /me/calendarView/delta?startDateTime={…}&endDateTime={…}`
([Get incremental changes to events](https://learn.microsoft.com/en-us/graph/delta-query-events)).

- Paging via `@odata.nextLink` (`$skipToken`), round completion via `@odata.deltaLink`
  (`$deltaToken`). Tokens encode the original parameters: *"You do not need to include these
  parameters in subsequent requests as they are encoded in the tokens."*
- `Prefer: odata.maxpagesize={x}` controls page size. `$select` **is not supported**.
- Deletions are explicit and clean:

```json
{
    "@odata.type": "#microsoft.graph.event",
    "id": "AAMkADk0MGFkODE3…",
    "@removed": { "reason": "deleted" }
}
```

- **The big limitation:** v1.0 delta is bound to a *calendar view*, i.e. a fixed date window.
  *"The capability for the former—getting incremental changes to events in a calendar not bound
  to a fixed start and end date range—is currently available only in the beta version."* And
  *"To track the changes in multiple calendars, you need to track each calendar individually."*
  A calendar-view delta returns **expanded occurrences** of recurring series, not the series —
  the same trap as Google's `singleEvents=true`.

**Recommendation: deprioritise Graph entirely.** Kati is a personal app; the Exchange audience
is a work audience; and the OAuth story (Entra ID app registration, admin consent for some
tenants) is worse than Google's. Anyone who needs it can get it through `CalendarContract`,
because the Outlook Android app registers a sync adapter.

---

## 5. The sync engine

Design it once, transport-agnostic, and let Google/CalDAV/Graph/`CalendarContract` be adapters
behind one behaviour. Everything below is transport-independent unless flagged.

### 5.1 The adapter behaviour

```elixir
defmodule Kati.Sync.Adapter do
  @type cursor :: term()          # syncToken | sync-token | deltaLink | ctag+etags | CalendarContract sync state
  @type remote_ref :: %{id: String.t(), etag: String.t() | nil, href: String.t() | nil}

  @callback list_calendars(account) :: {:ok, [remote_calendar]} | {:error, term}
  @callback pull(calendar, cursor | nil) ::
              {:ok, [change], cursor} | {:error, :cursor_invalid} | {:error, term}
  @callback push(calendar, [operation]) :: [{operation, :ok | {:conflict, remote_ref} | {:error, term}}]
  @callback capabilities(account) :: %{
              writable: boolean(),
              recurrence: :full | :rrule_only | :none,
              attachments: boolean(),
              attendees: :rw | :ro | :none,
              this_and_future: :native | :split | :unsupported
            }
end
```

`capabilities/1` is the part people forget. Screen 32's per-feed **Write back** rules
(`design-index.md:125`) are exactly a UI over this map, and having it lets the editor grey out
what a given backend cannot express instead of silently dropping it.

### 5.2 Change tracking on the local side

Every syncable row carries:

| Column | Purpose |
|---|---|
| `local_rev` | Monotonic integer, bumped on **every** local write. Cheap, no clock involved. |
| `synced_rev` | The `local_rev` that was last successfully pushed. `local_rev > synced_rev` ⇒ dirty. |
| `remote_etag` | Last etag/`@odata.etag`/Google `etag` seen. The basis for `If-Match`. |
| `remote_id`, `remote_href` | Server identity. `href` is CalDAV-only and opaque (§4.2.4). |
| `deleted_at` | Tombstone. Never hard-delete a synced row. |
| `sync_state` | `:local_only \| :clean \| :dirty \| :conflicted \| :push_failed` |

`local_rev`/`synced_rev` beats "dirty boolean" because it survives the race where a user edits
a row *while* a push of the previous version is in flight: on push success you set
`synced_rev = pushed_rev`, and the row correctly stays dirty.

### 5.3 Tombstones

Three distinct deletions, and conflating them is a classic data-loss bug:

1. **Local delete of a Kati-owned event** → tombstone, push a DELETE, keep the tombstone until
   the push is acknowledged, then it may be garbage-collected.
2. **Remote delete** (Google `status: "cancelled"`, CalDAV 404 in `sync-collection`, Graph
   `@removed`) → delete the mirror row **unless it is locally dirty**, in which case it is a
   delete/update conflict (§5.4).
3. **Account disconnect** → delete all mirror rows for that account, and **keep** every
   Kati-owned event. Screen 32's promise that Kati never touches *"an event it did not create"*
   has a mirror-image obligation: disconnecting must never destroy what Kati *did* create.

**Tombstone retention** must exceed the longest plausible offline period, because a tombstone
GC'd too early resurrects the event on the next sync. Recommendation: **90 days**, and never
GC a tombstone that still has an outbox entry.

### 5.4 The outbox, idempotency, and partial failure

**All remote mutations go through a durable outbox table**, never straight from the UI:

```
outbox(id, account_id, calendar_id, event_uid, op, payload,
       attempt_count, next_attempt_at, idempotency_key, depends_on, inserted_at)
```

- **Idempotency.** None of the three transports offer an idempotency key. Construct one:
  for creates, **generate the `UID` client-side** and use `If-None-Match: *` (CalDAV) or a
  client-chosen `id` (Google accepts a client-supplied `id` on `events.insert`). Then a retry
  after an ambiguous timeout either succeeds or returns 409/412 — both of which mean "it
  already landed", not "it failed". Without this, every network timeout risks a duplicate event.
- **Ordering and `depends_on`.** The "this and following" split (§3.4) is two operations that
  must land in order: trim-master, then create-new-master. If the second fails after the first
  succeeded, the user has silently lost future occurrences. Model it as a **two-entry outbox
  chain with `depends_on`**, and — because no transport gives us a transaction — make the
  *local* state the source of truth and keep retrying entry 2 until it lands, surfacing a
  "partially synced" badge meanwhile. Screen 27's error card with **Retry**
  (`design-index.md:225`) is the right UI.
- **Backoff.** Per §4.1.6: exponential with jitter, cap 32–64 s, and a separate longer backoff
  for 4xx-that-are-not-retryable (401 → re-auth prompt; 403 quota → back off hard; 400 →
  quarantine the entry and surface it, never retry forever).
- **Poison entries.** After N failures, move to `:push_failed` and show it. A silent infinite
  retry loop on a malformed event is worse than an error card.

### 5.5 Ownership: "Kati owns it" vs "mirror of a remote"

This is the modelling question the brief asks, and it deserves a sharp answer.

**Model it as an `origin` enum plus a nullable link, not as two tables.**

```elixir
# Ash resource sketch
attribute :origin, :atom, constraints: [one_of: [:kati, :mirror]]
attribute :remote_id,   :string          # nil when origin == :kati and not yet published
attribute :remote_href, :string
attribute :remote_etag, :string
belongs_to :calendar, Kati.Calendar      # a calendar itself is :local or belongs to an account
attribute :raw_icalendar, :string        # see §5.6 — populated for :mirror, and for :kati after first push
```

Rules that follow:

| Situation | Behaviour |
|---|---|
| `origin: :kati`, calendar is local | Never synced. The default for habits, meals, media air-dates. |
| `origin: :kati`, calendar is remote | Kati is authoritative on conflict; push wins by default. |
| `origin: :mirror` | **Remote is authoritative.** Local edits are only permitted if the calendar's `writeback_policy` allows it; otherwise the editor is read-only. |
| `origin: :mirror` + local edit + remote change | True conflict. See below. |

**The critical subtlety:** an event Kati created *into* a Google calendar is `origin: :kati`
with a `remote_id` — it is simultaneously Kati-owned and remote-backed. That is why one table
with an enum beats two tables. Screen 32's *"never touching an event it did not create"* is
then enforceable as a single predicate: `origin == :kati or calendar.writeback_policy == :full`.

**Do not use "the section colour" or "which app made it" as the ownership signal.** Use an
explicit column, set at creation, immutable thereafter.

### 5.6 The data model that round-trips without loss

The requirement, from §4.2.4: *"I strongly recommend always retaining the iCalendar the server
sent to you."* RFC 5545 makes the same point from the other end — unknown properties are
legal and must be tolerated. On IANA-registered properties (§3.8.8.1):

> "Compliant applications are expected to be able to parse these other IANA-registered
> properties but can ignore them."

and on `X-` properties (§3.8.8.2):

> "User agents that support this content type are expected to be able to parse the extension
> properties and property parameters but can ignore them."

"Can ignore them" is permission to not *understand* them. It is **not** permission to *destroy*
them on write-back — and destroying them is what a naive parse-into-columns-then-regenerate
pipeline does. Real examples that will be in your users' data: `X-APPLE-STRUCTURED-LOCATION`
(the geofence behind Apple's travel-time alerts), `X-APPLE-TRAVEL-DURATION`,
`X-GOOGLE-CONFERENCE`, `X-MICROSOFT-CDO-BUSYSTATUS`, `X-MOZ-LASTACK` (Thunderbird's snooze
state). Drop those and you have silently broken the user's other apps.

**The model:**

```
event
  uid                TEXT      -- iCalendar UID; stable, immutable, client-generated for :kati
  calendar_id        REF
  origin             ENUM      -- :kati | :mirror
  -- ── parsed, queryable projection ──────────────────────────────
  summary, location, description
  dtstart_utc        INTEGER   -- for range queries / indexing
  dtstart_wall       TEXT      -- 'YYYYMMDDTHHMMSS', the authored wall clock
  tzid               TEXT      -- NULL means floating
  is_all_day         BOOLEAN
  duration_iso       TEXT      -- 'PT1H'; prefer over dtend (§1.1)
  rrule              TEXT
  status, transp, sequence, last_modified
  -- ── the lossless part ─────────────────────────────────────────
  raw_icalendar      TEXT      -- the exact bytes the server sent, or our last PUT
  unknown_props      TEXT      -- JSON: properties we parsed but do not model
  -- ── sync bookkeeping (§5.2) ───────────────────────────────────
  local_rev, synced_rev, remote_id, remote_href, remote_etag, deleted_at, sync_state

event_occurrence_override        -- RECURRENCE-ID overrides (§3.3) — NOT optional
  event_uid          REF
  recurrence_id_utc  INTEGER    -- the ORIGINAL start of the overridden instance
  kind               ENUM       -- :modified | :cancelled   (:cancelled ≡ EXDATE)
  ... same parsed columns, nullable = inherit from master ...
  raw_icalendar      TEXT

event_rdate(event_uid, at_utc, period_duration)
event_exdate(event_uid, at_utc)          -- or fold into overrides as :cancelled
event_alarm(event_uid, trigger_iso, action, description, os_notification_id)
event_attendee(event_uid, email, name, role, partstat, rsvp)
event_attachment(event_uid, uri, fmttype, filename)
```

**The write-back rule.** On push, do **not** regenerate the iCalendar from columns. Instead:
*parse `raw_icalendar` → apply only the properties Kati actually changed → serialise*. This is
a targeted patch of a text document, and it is the only technique that survives contact with
properties you have never heard of. `sequence` increments on any change to a scheduled event.

**On SQLite constraints** (`mob-framework.md:1381`): *"`pool_size: 1` (single writer), limited
`ALTER TABLE`, no arrays or JSONB indexes (use string + Jason, or normalise)"*. Hence
`unknown_props` as a JSON **string**, and hence the separate child tables rather than arrays.
Single-writer also means the sync engine and the UI contend for one connection — **run sync
writes in bounded batches inside transactions**, or a long sync will make the UI stutter.

### 5.7 Conflict detection and resolution

**Detection** is version-vector-lite, and does not require synchronised clocks:

```
local_dirty  = local_rev > synced_rev
remote_moved = fetched_etag != stored_remote_etag
conflict     = local_dirty and remote_moved
```

For CalDAV this is enforced server-side for free by `If-Match` → `412`. For Google, compare
`etag` and use `If-Match` on the update. For Graph, compare `@odata.etag`.

**Resolution policy**, in order of preference:

1. **Field-level merge when disjoint.** If local changed only `summary` and remote changed only
   `location`, merge. Requires storing the *base* version — keep the pre-edit `raw_icalendar`
   in the outbox payload, giving a genuine three-way merge (base/local/remote) at the property
   level. This resolves the large majority of real conflicts silently and correctly.
2. **Ownership rule** (§5.5) when fields overlap: `origin: :kati` → local wins;
   `origin: :mirror` → remote wins, and the local edit is preserved as a "rejected change" the
   user can re-apply.
3. **Ask the user** only when 1 and 2 both fail. And the design already has the component for
   it — screen 37's conflict resolver: *"Keep mine / Take file / Keep both — 1 of 6 · apply to
   all"* (`design-index.md:132`). **Reuse that exact UI for sync conflicts.** It is already
   drawn, it already handles batching, and consistency is worth more than a bespoke sheet.

**Never use last-write-wins on wall-clock timestamps.** Which brings us to:

### 5.8 Clock skew

Three separate hazards:

1. **Device clock wrong.** The user's phone is 3 minutes fast, or manually set to 2019.
   *Mitigation:* never compare a local timestamp against a remote one to decide precedence.
   Use etags and revisions (§5.7). Where a timestamp is unavoidable, **use the server's
   `Date:` response header** as the time base and store the observed offset.
2. **Server `LAST-MODIFIED` is not comparable across servers.** Two CalDAV servers, two clocks.
   Only compare a resource's timestamp with *its own* previous value, never across resources.
3. **DST and the "same event, different offset" trap.** A recurring event stored as a UTC
   instant + RRULE will drift when the zone's offset changes. This is the reason §5.6 stores
   `dtstart_wall` + `tzid` alongside `dtstart_utc`: **expand the recurrence in the event's own
   timezone in wall-clock terms, then convert each occurrence to UTC.** Expanding in UTC and
   converting after is wrong, and it is the single most common recurrence bug in the wild —
   cocktail's own roadmap flags it (§3.5: *"investigate and fix DST bugs when using zoned
   DateTime"*).

Also: the nonexistent-local-time case from §3.2(b) — a 01:30 daily event on a spring-forward
day — **MUST be dropped**, per the RFC. And the *ambiguous* case (autumn fall-back, 01:30
happens twice) is **not** specified by RFC 5545. Convention, which Kati should follow: take the
**first** (i.e. the pre-transition offset). Document the choice.

### 5.9 Credential storage — an unsolved problem in Mob

`mob-framework.md:1384-1388` is blunt:

> "**Encryption at rest: none.** No SQLCipher, no keychain/keystore, no encrypted storage
> anywhere in Mob. Surface matrix confirms 'Missing: keychain/keystore, encrypted storage'.
> `Mob.State`'s DETS file and the SQLite DB are plaintext in the app sandbox. For a movie
> tracker that's probably fine; for a stored Trakt OAuth token it is not — you would need a
> native extension."

An OAuth **refresh token** or an iCloud **app-specific password** is a long-lived credential to
the user's entire calendar. Storing it in plaintext SQLite is not acceptable for a security-
reviewed open-source release. **This is a hard prerequisite for any direct-network sync, and it
is a native extension either way**: Android `EncryptedSharedPreferences` / Keystore-wrapped
AES, iOS Keychain. Note this is *another* argument for §6 — the `CalendarContract` route stores
no credentials at all, because the OS holds them.

### 5.10 TLS, before any of this works

`mob-framework.md:1401-1430`: `:public_key.cacerts_load/0` finds no CA bundle on Android, so
*"any library that consults it (Req → Mint → `:ssl`, Finch, anything using OTP-26+ default
`:ssl` opts) **crashes on the first TLS connect**"*, often surfacing as an opaque
`FunctionClauseError`. And: *"⚠️ `Mob.Certs` is NOT wired into the generated project… A fresh
`mix mob.new` app calling TMDB over HTTPS **will crash on Android on the first request**."*

Fix, unconditionally, as the first line of `on_start/0`:

```elixir
Mob.Certs.load_cacerts!(Application.app_dir(:kati, "priv/cacerts.pem"))
```

with `castore`'s bundle in `priv/`. **File this as issue #1 of the whole project**, not of the
calendar — it blocks TMDB, Trakt, and every sync transport alike.

---

## 6. Android-native integration: `CalendarContract`

### 6.1 What it is

A content provider ([reference](https://developer.android.com/reference/android/provider/CalendarContract),
[guide](https://developer.android.com/guide/topics/providers/calendar-provider)) with tables
`Calendars`, `Events`, `Instances`, `Attendees`, `Reminders`, `ExtendedProperties`, `SyncState`,
`EventsEntity`, `CalendarCache`.

Permissions: `android.permission.READ_CALENDAR` and `android.permission.WRITE_CALENDAR` —
both **dangerous**, so runtime-requested. Screen 40 already draws this honestly:
*"permission rows each stating their purpose … Calendars read+write"* (`design-index.md:136`).

### 6.2 The columns map cleanly onto RFC 5545

`DTSTART`, `DTEND`, `DURATION` (*"in RFC5545 format. For example, a value of `"PT1H"`"*),
`EVENT_TIMEZONE`, `EVENT_END_TIMEZONE`, `ALL_DAY`, `RRULE` (*"For example,
`"FREQ=WEEKLY;COUNT=10;WKST=SU"`"*), `RDATE`, `EXRULE`, `EXDATE`, `AVAILABILITY`,
`ORGANIZER`, `GUESTS_CAN_MODIFY`. Overrides are modelled with `ORIGINAL_ID` /
`ORIGINAL_SYNC_ID` / `ORIGINAL_INSTANCE_TIME` / `ORIGINAL_ALL_DAY` — i.e. Android's
equivalent of `RECURRENCE-ID`, which confirms the §5.6 model is the right shape.

Two gotchas:

- **Recurring events need `DURATION`, not `DTEND`:** *"For recurring events, you must include a
  `DURATION` in addition to `RRULE` or `RDATE`."* (Exception: the `INSERT` Intent path converts
  for you.)
- **`SYNC_DATA1`…`SYNC_DATA10` and `ExtendedProperties` are writable only by a registered sync
  adapter** (`CALLER_IS_SYNCADAPTER=true` + `ACCOUNT_NAME`/`ACCOUNT_TYPE` query params). A
  plain app cannot stash arbitrary metadata on someone else's event. **This is the concrete
  limit on how much Kati-specific state can live in the provider**, and it is why Kati keeps
  its own SQLite store and treats the provider as a peer, not as storage.

### 6.3 The `Instances` table does the recurrence expansion for you

*"The `CalendarContract.Instances` table holds the start and end time for each occurrence of an
event… For recurring events, multiple rows are automatically generated."* Query it by appending
the range to the URI:

```kotlin
val builder: Uri.Builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
ContentUris.appendId(builder, startMillis)
ContentUris.appendId(builder, endMillis)
val cur: Cursor = contentResolver.query(builder.build(), INSTANCE_PROJECTION, selection, selectionArgs, null)
```

Columns include `BEGIN`, `END`, `START_DAY`/`END_DAY` (Julian days), `START_MINUTE`/`END_MINUTE`
(minutes from midnight in the calendar's timezone), `EVENT_ID`.

**`START_MINUTE`/`END_MINUTE` are exactly the inputs the lane-assignment algorithm in §8 needs**
— minutes-from-midnight, already timezone-resolved by the OS. That is a meaningful shortcut,
and it means the day view can be built against provider data before Kati's own expander exists.

### 6.4 Zero-permission escape hatch

*"Using the `INSERT` Intent lets your application hand off the event insertion task to the
Calendar itself. With this approach, your application doesn't even need to have the
`WRITE_CALENDAR` permission included in its manifest file."*

```kotlin
val intent = Intent(Intent.ACTION_INSERT)
        .setData(CalendarContract.Events.CONTENT_URI)
        .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startMillis)
        .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endMillis)
        .putExtra(CalendarContract.Events.TITLE, "Yoga")
startActivity(intent)
```

Useful for a v0 "Add to phone calendar" action, and for users who decline the permission.
`ACTION_EDIT` and `ACTION_VIEW` exist too.

### 6.5 Honest comparison: `CalendarContract` vs direct Google API

| | `CalendarContract` | Direct Google Calendar API |
|---|---|---|
| **Auth** | Two runtime permissions | OAuth via Play Services `AuthorizationClient` (§4.1.2) |
| **Verification** | none | **Sensitive-scope review; 100-user lifetime cap otherwise** (§4.1.3) |
| **Credentials to store** | **none** | refresh token → needs encrypted storage Mob lacks (§5.9) |
| **Providers covered** | Google, Exchange, Samsung, local, **+ every CalDAV server via DAVx⁵** | Google only |
| **Background freshness** | **OS sync adapters keep it fresh with the app closed** | polling only, foreground only (§4.1.5) |
| **Network code** | none | full HTTP + retry + backoff + token refresh |
| **Recurrence expansion** | **free, via `Instances`** | must implement (§3.5) |
| **Works without Play Services** | **yes** | no |
| **Works on iOS** | no (EventKit is the analogue) | yes |
| **Fidelity** | good, but no arbitrary metadata on foreign events (§6.2) | full, incl. conferencing, colours, ACLs |
| **Offline** | **provider is local** | needs its own cache |
| **Failure modes** | OEM provider bugs; user revokes permission | quota, 410 token, re-auth, verification lapse |
| **Effort to first working sync** | **days** | weeks, plus review latency |

**Verdict: `CalendarContract` first, unambiguously.** It is strictly better on eight of eleven
rows, it is the pattern the respected FOSS Android calendars use, it requires no secrets, no
review, and no server, and it delivers *more* providers than the Google API does. The design's
screen 32 — accounts, per-calendar visibility, write-back rules — renders perfectly well over
provider accounts; the user sees "Google · you@gmail.com" either way.

**The honest costs of choosing it:**

1. **It is Android-only.** iOS needs EventKit, a separate native extension with a similar shape
   (`EKEventStore`, `NSCalendarsUsageDescription`). Since Android is the stated priority
   (owner's locked decision) and iOS is later, this is acceptable — and the *adapter behaviour*
   in §5.1 is what makes the second implementation cheap.
2. **You inherit OEM provider bugs.** Samsung and Xiaomi have historically shipped divergent
   providers. Defensive reads, no assumptions about column presence.
3. **Two-way conflict is still real.** Writing into a provider row that a sync adapter then
   overwrites is a genuine conflict — the provider gives you `_SYNC_ID` and `DIRTY` but the
   arbitration is between you and the adapter. The §5 engine still applies; the transport is
   just a `ContentResolver` instead of HTTP.
4. **`Instances` expansion is *not* a substitute for Kati's own expander.** Kati-owned events
   living only in Kati's SQLite still need §3.5. `Instances` helps for mirrored events only.

### 6.6 What this costs in Mob

A Tier-1/2 plugin (`mob-framework.md:556-566`): Kotlin functions over `ContentResolver`,
exposed to Elixir via `mix mob.add_nif` or a `Mob.Component`-style bridge, returning maps.
Permission requests go through Mob's permissions API (`mob-framework.md:662`). No new
third-party dependency, no Play Services, no secrets. **This is the smallest native surface of
any sync option, which also minimises exposure to the native-shell fork problem
(`mob-framework.md:1517`).**

---

## 7. The Persian/Jalali dimension

### 7.1 What the design already locked

From `design-index.md:164-169` (the locale table) and §6 of that doc:

| Code | Dir | Calendar | Digits | Week starts | Typeface |
|---|---|---|---|---|---|
| `en` | LTR | Gregorian | 1234 | Monday | Plus Jakarta Sans |
| `fa` | RTL | Shamsi | ۱۲۳۴ | **Saturday** | Vazirmatn |

And the design's own warning, screen 60 (`design-index.md:158`):

> *"the hardest case in the whole pass: a matrix whose columns are days. Mirroring alone would
> put Monday on the right and still be wrong — the sequence itself has to restart at شنبه."*

Screen 56 says the same for the calendar day strip (`design-index.md:154`), with the note
*"هفته از شنبه آغاز می‌شود"* and the observation that this is *"a change no amount of CSS
mirroring would produce."* Weekday abbreviations are **ش ی د س چ پ ج** (`design-index.md:381`).

### 7.2 The calendar system

The Solar Hijri (Jalali/Shamsi) calendar:

- **Month lengths:** first six months 31 days, next five 30 days, last month (اسفند) 29 days
  in a common year and 30 in a leap year. Total 365/366.
  Months: فروردین، اردیبهشت، خرداد، تیر، مرداد، شهریور (31) · مهر، آبان، آذر، دی، بهمن (30) ·
  اسفند (29/30).
- **Year start:** نوروز, the day of the vernal equinox as observed at the reference meridian
  (52.5°E, Tehran). The rule is *"A Jalaali year begins on the first day of astronomically
  determined spring or on the day following it according to whether the exact moment of the
  equinox occurs before or after … 12:00 of the Teheran mean time."*
- **Leap years:** the calendar is fundamentally **observational**, not arithmetic. The common
  approximation is a 33-year cycle with leap years at remainders `1, 5, 9, 13, 17, 22, 26, 30`
  mod 33, with "break years" correcting drift. Birashk's 2820-year algorithm is another
  approximation.
  ([Wikipedia](https://en.wikipedia.org/wiki/Jalali_calendar),
  [Borkowski, *The Persian calendar for 3000 years*](https://www.astro.uni.torun.pl/~kb/Papers/EMP/PersianC-EMP.htm))

**Practical consequence:** do **not** hand-roll the conversion. Approximations disagree with
the official Iranian calendar in specific years, and getting نوروز wrong by a day is the most
visible possible bug for a Persian user.

### 7.3 Elixir options

| Package | Version | Updated | Notes |
|---|---|---|---|
| `ex_cldr_calendars_persian` | 1.1.1 | 2025-03-19 | *"Implementation of the Persian Solar Hijri calendar for Elixir"*. Implements the `Calendar` behaviour, so `Date`/`DateTime` work natively. Pairs with `ex_cldr_calendars` (2.4.4, updated 2026-06-26, 2.98M downloads) for month/week arithmetic and CLDR localisation. |
| `jalaali` | 0.4.1 | 2023-06-25 | *"Elixir Shamsi calendar"*. Simpler, standalone, no CLDR. Unmaintained for ~3 years. |

**Recommendation: `ex_cldr_calendars_persian` + `ex_cldr_calendars`.** The `Calendar`-behaviour
approach means `Date.convert(~D[2026-08-17], Cldr.Calendar.Persian)` just works, CLDR supplies
localised month/day names and the correct Persian digit and separator forms (the design uses
U+066B decimal separator and U+066A percent, `design-index.md:378`), and it is actively
maintained. **UNKNOWN and worth verifying before committing:** which leap-year algorithm
`ex_cldr_calendars_persian` 1.1.1 uses (astronomical vs 33-year vs Birashk) and whether it
agrees with the official Iranian calendar for the next decade. **Write a golden-file test with
~20 known نوروز dates from an authoritative Iranian source before shipping.**

### 7.4 Rendering a Gregorian event in a Shamsi grid

The architecture is simple if you keep one rule: **conversion happens at the presentation
boundary, never in storage or query.**

```
storage:  UTC instant + tzid          (Gregorian, unchanged — owner's locked decision)
   ↓ query by UTC range
domain:   occurrences as DateTime in the event's tzid
   ↓ presentation boundary
display:  DateTime → device tz → Date → Cldr.Calendar.Persian → {jy, jm, jd} → Persian digits
```

**But the *grid* must be built in Jalali, not converted from a Gregorian grid.** This is the
distinction the design is pointing at with screen 60. Concretely, to render مرداد ۱۴۰۵:

1. Compute the Jalali month's first day and length **in Jalali terms** (31 days for مرداد).
2. Convert the first day to Gregorian to get its weekday.
3. **Compute the leading blank count against a Saturday week start**, not a Monday one:
   `offset = rem(gregorian_day_of_week - 6 + 7, 7)` for `ISO day_of_week` where Sat = 6.
   Equivalently, use `Cldr.Calendar` with an explicit `min_days`/`first_day` configuration
   rather than deriving it from `Date.day_of_week/1`'s ISO default.
4. Emit 6 rows × 7 columns; column 0 is شنبه.
5. **Then** query events by the UTC range spanned by that Jalali month (which is *not* a
   Gregorian month boundary — it will straddle two).

Step 5 is the one that surprises people: a Jalali month view needs a `[start_utc, end_utc)`
range derived from the Jalali month, so the query layer must accept an arbitrary range, not a
"year+month" pair. **Design the calendar query API as `events_in_range(from_utc, to_utc)` from
day one** and both calendar systems fall out for free.

**RTL is orthogonal.** Direction is a container property (`design-index.md:359-362`:
*"RTL is a container attribute, not a fork"*), whereas week-start is a *sequence* property.
The design is explicit that these are different problems, and it is right. In Mob terms:
`Row` children are emitted in logical order and the platform mirrors them under RTL, so the
lane/column code emits `[شنبه, یکشنبه, …]` and lets the container handle direction.

**UNKNOWN:** whether Mob's Compose bridge sets `LayoutDirection.Rtl` at all. `Row` in
`MobBridge.kt` uses `Modifier.padding(start=…, end=…)` (direction-aware) — see
`/Users/shahryar/Desktop/first_mob_beam/fresh_mob_beam/android/app/src/main/java/com/example/fresh_mob_beam/MobBridge.kt:3396-3404`,
which maps `padding_left → start` and `padding_right → end` — so the plumbing is
direction-aware, but I found **no** `LocalLayoutDirection` provider or RTL switch in the
bridge. **Verify this early**; if absent, RTL is a `MobBridge.kt` change (a
`CompositionLocalProvider(LocalLayoutDirection provides …)` wrapper at the root), which is
cheap but must be planned.

---

## 8. The hard rendering problem: lane assignment under Mob

### 8.1 The algorithm

Overlapping-event layout is **interval graph colouring**. Build a graph whose vertices are the
day's timed events and whose edges join pairs that overlap in time; that graph is an *interval
graph*, and interval graphs are perfect — so the **minimum number of columns equals the size of
the largest clique, which is just the maximum number of events concurrent at any instant**. A
greedy left-to-right sweep achieves that optimum, which is why every calendar uses the same
three-phase algorithm:

**Phase 1 — group into collision clusters.** Sort by start (ties broken by longer-first, then
by id for stability). Sweep, accumulating events into a cluster while `event.start <
cluster.max_end`; when an event starts at or after `cluster.max_end`, close the cluster and
start a new one. Clusters are independent — each lays out in its own coordinate space.

**Phase 2 — assign columns within a cluster.** For each event in sorted order, place it in the
lowest-indexed column whose last event ends at or before this event's start; if none, open a
new column. This is exactly greedy interval-graph colouring and yields the minimum column count.

**Phase 3 — expand widths.** An event that has no neighbour to its right may widen. For each
event, scan columns to the right until you find one containing an event that overlaps it; the
event spans from its own column up to (not including) that one. This is what makes Google
Calendar's short events widen into the gap rather than leaving dead space.

```elixir
defmodule Kati.Calendar.Layout do
  @moduledoc """
  Interval-graph colouring for a day column. Pure, no geometry input.
  Returns {event, col, span, n_cols} — fractional geometry only.
  """
  def lanes(events, opts \\ []) do
    max_cols = Keyword.get(opts, :max_cols, 2)

    events
    |> Enum.sort_by(&{&1.start_min, -&1.end_min, &1.id})
    |> cluster()
    |> Enum.flat_map(&layout_cluster(&1, max_cols))
  end

  defp cluster(sorted) do
    sorted
    |> Enum.reduce([], fn ev, acc ->
      case acc do
        [{group, max_end} | rest] when ev.start_min < max_end ->
          [{[ev | group], max(max_end, ev.end_min)} | rest]
        _ ->
          [{[ev], ev.end_min} | acc]
      end
    end)
    |> Enum.map(fn {group, _} -> Enum.reverse(group) end)
    |> Enum.reverse()
  end

  defp layout_cluster(group, max_cols) do
    # columns :: [last_end_min], index = column number
    {placed, cols} =
      Enum.reduce(group, {[], []}, fn ev, {placed, cols} ->
        case Enum.find_index(cols, &(&1 <= ev.start_min)) do
          nil -> {[{ev, length(cols)} | placed], cols ++ [ev.end_min]}
          i   -> {[{ev, i} | placed], List.replace_at(cols, i, ev.end_min)}
        end
      end)

    n = length(cols)
    placed = Enum.reverse(placed)

    if n <= max_cols do
      Enum.map(placed, fn {ev, col} ->
        %{event: ev, col: col, span: span_right(ev, col, placed, n), n_cols: n}
      end)
    else
      overflow(placed, max_cols, n)          # see §8.2
    end
  end

  defp span_right(ev, col, placed, n) do
    blocked =
      placed
      |> Enum.filter(fn {o, c} -> c > col and overlaps?(o, ev) end)
      |> Enum.map(fn {_, c} -> c end)
      |> Enum.min(fn -> n end)
    blocked - col
  end

  defp overlaps?(a, b), do: a.start_min < b.end_min and b.start_min < a.end_min
end
```

**Complexity:** O(n log n) for the sort, then O(n·k) where k is the column count within a
cluster (in practice ≤ 4). For a personal calendar's ~20 events/day this is microseconds — it
can run inside `render/1` with no caching, though caching per (day, revision) is trivial and
worth it.

### 8.2 Kati's twist: the cap and the `+n MORE` tile

Screen 09 does *not* want unbounded columns. `design-index.md:94`:

> *"`2 at once` split lanes capped at two columns with a `+1 MORE` tile, 3+ same-kind grouped
> cards with poster stacks"*

So `overflow/3` in the sketch above: keep the first `max_cols` columns' worth of events (rank
by start time, then duration — the two most "primary" events), and replace the remainder with a
single tile reading `+n MORE` occupying the trailing column, tapping through to a list. And
screen 52's *"Collapse meals → 5 meals · 1,960 kcal · 1 eaten · next at 10:30"*
(`design-index.md:149`) is the same idea keyed on *kind* rather than on count — a pre-pass that
folds ≥3 same-section events in one cluster into one synthetic event before layout runs.

**This ordering matters:** collapse-by-kind must run *before* lane assignment, or you will
allocate columns to events you are about to hide.

### 8.3 The Mob constraint — and why it is survivable

**The constraint is real.** Two independent verifications:

1. **No wrap/flow primitive.** The tag whitelist at
   `/Users/shahryar/Desktop/first_mob_beam/fresh_mob_beam/source/mob/priv/tags/android.txt`
   is exactly: `Box Button Column Divider Image LazyList List Progress Row Scroll Slider Spacer
   TabBar Text TextField Toggle Video CameraPreview WebView GpuView`. `ios.txt` is the same
   minus nothing relevant. `grep -rn "FlowRow\|FlowColumn\|flexWrap" .../source/mob/android`
   returns **no matches**. This corroborates `mob-framework.md:336`: *"Wrapping: there is no
   flow/wrap primitive documented."*
2. **No geometry feedback to `render/1`.** The only measurement in the whole stack is
   `Modifier.onGloballyPositioned`, and it is used solely to populate a Kotlin-side test handle
   (`MobBridge.kt:2219-2226`, `handle.viewportPx = …`). It reaches Elixir only through
   `Mob.Test.element_frames/1`, which is `:rpc.call(node, :mob_nif, :element_frames, [])`
   (`.../source/mob/lib/mob/test.ex:1118-1119`) — a **dev-machine-over-distribution** call, and
   the docs mark the Android registry *"(planned)"* (`test.ex:378`). There is also **no screen
   size or density in `Mob.Device`** — its public API is battery, thermal, network, orientation,
   `os_version`, `model`, `keep_awake`, `open_url`, `open_settings`
   (`.../source/mob/lib/mob/device.ex:128-336`). `render/1` genuinely cannot know how wide it is.

**Why it is survivable — three mechanisms, in order of preference.**

**(a) Fractional layout + `weight`. This is the right answer and it needs nothing new.**
The layout algorithm emits `{col, span, n_cols}` — *ratios*, not pixels. `Row` supports a
per-child `weight` float and the Compose bridge honours it directly:

```kotlin
"row" -> Row(modifier = m, verticalAlignment = rowAlignProp(node.props)) {
    node.children.forEach { child ->
        val w = floatProp(child.props, "weight")
        RenderNode(child, if (w != null) Modifier.weight(w) else Modifier)
    }
}
```
(`MobBridge.kt:2195-2200`)

So a cluster of `n_cols` columns is a `Row` whose children carry `weight={span}` and whose gaps
carry `weight={gap_cols}` via a `Spacer`. **Widths resolve at native layout time, on the device,
at the correct density — exactly the information `render/1` lacks.** No geometry feedback
needed, because we never needed absolute widths, only proportions.

Vertical position is easy because it is *not* proportional: minutes map to dp at a fixed scale
the app chooses (e.g. 1 min = 1.0 dp → a 24 h day is 1440 dp inside a `Scroll`). Height is
`(end_min - start_min) * scale`; top offset is `start_min * scale`.

**(b) `offset_y` for absolute vertical placement — available, but undocumented.**
The generated bridge already supports it:

```kotlin
fun RenderNode(node: MobNode, modifier: Modifier = Modifier) {
    val ox = floatProp(node.props, "offset_x") ?: 0f
    val oy = floatProp(node.props, "offset_y") ?: 0f
    if (ox != 0f || oy != 0f) {
        Box(modifier = Modifier.offset(x = ox.dp, y = oy.dp)) {
            RenderNodeInner(node, modifier)
        }
    } else {
        RenderNodeInner(node, modifier)
    }
}
```
(`MobBridge.kt:2162-2172`; the same `offset_x` read appears in the older project's bridge at
`/Users/shahryar/Desktop/first_mob_beam/android/app/src/main/java/com/example/first_mob_beam/MobBridge.kt:2591`,
which suggests it is template-provided rather than hand-added)

⚠️ **But `offset_x`/`offset_y` are undocumented.** `grep -rn "offset_x"` across
`source/mob/lib`, `source/mob/guides` and `source/mob/priv` returns **zero hits** — the only
match in the entire Mob package is `test.ex:962`, where `offset_x` is a *scroll* offset, an
unrelated meaning. **So this is host-app behaviour, not framework API**, and it could vanish or
change in a future `mob_new` template. That is fine — Kati owns `MobBridge.kt` (Mob ships no
host bridge at all; `find source/mob -name "MobBridge*"` returns nothing) — but it must be a
*conscious* decision recorded in the repo, not an accident.

Prefer (a) for horizontal, (b) for vertical placement inside the day's absolute-positioned
canvas, since a `Box` with `fill_height` plus `offset_y` children is the natural expression of
a time gutter.

**(c) A native `Mob.Component` day-view.** The escape hatch (`mob-framework.md:505-545`):
implement `Mob.Component`, register a Compose factory under `"Kati_DayView"`, hand it a list of
`{id, top_frac, height_frac, col, span, n_cols, colour, title}` and let Compose lay it out.

**Do not do this first.** It is the right answer only if (a)+(b) prove insufficient — most
likely candidates being drag-to-move gestures or pinch-to-zoom the time scale, neither of which
is in the design. Note the design is unusually helpful here: `design-index.md:438-441` records
that the whole 825 KB design file has **no** transitions, animations, transforms, no
`position:sticky`, and **no swipe-to-action anywhere**. The day view is a static layout problem.

### 8.4 `Canvas` — available, with a caveat

`Mob.UI.canvas/1` and `Mob.Canvas` exist (`source/mob/lib/mob/canvas.ex`) with ops
`line/circle/ellipse/arc/rect/path/text/image`, and the generated bridge dispatches
`"canvas" -> MobCanvas(node, m)` (`MobBridge.kt:2256`).

⚠️ **`Canvas` is not in the tag whitelists** (`priv/tags/android.txt`, `priv/tags/ios.txt`), so
`~MOB(<Canvas …/>)` compiles only via the unknown-tag path (*"unknown tags still compile with a
warning"*, `mob-framework.md:307`). And the moduledoc is explicit that the renderer is the
app's responsibility: *"Mob ships no host-app code; each app's `MobBridge.kt` /
`MobBridge.swift` contains the Canvas renderer."* Its coordinate contract is genuinely useful
though — logical units scaled to actual pixels per axis, so *"a draw op at `(width / 2, height
/ 2)` lands in the dead centre of the rendered canvas regardless of the canvas's actual
on-screen pixel size."*

**Use `Canvas` for the week lane chart (screen 17) and the pixel fields (07/22/47/61), not for
the day view** — the day view needs tappable, accessible, dynamically-typed *widgets*, and
canvas-drawn rectangles are none of those. Screen 41's requirement that the densest card reflow
at 235% Dynamic Type without truncation (`design-index.md:137`) rules canvas out for anything
carrying text the user must read.

---

## 9. Phasing

### Phase 0 — unblock (before any calendar code)

| # | Item | Why |
|---|---|---|
| 0.1 | Wire `Mob.Certs.load_cacerts!/1` + bundle `castore` PEM into `priv/` | Android TLS crashes on first request otherwise (`mob-framework.md:1427-1430`). Blocks everything networked. |
| 0.2 | Confirm the `MOB_BEAMS_DIR` migrations workaround is in `app.ex` | Otherwise *"tables are never created and any query against them crashes the screen GenServer, making the screen appear frozen"* (`mob-framework.md:1374-1379`). |
| 0.3 | Decide and record: `offset_x`/`offset_y` are load-bearing app-owned bridge behaviour | §8.3(b). Add a bridge test. |
| 0.4 | Verify RTL: does the Compose bridge provide `LocalLayoutDirection`? | §7.4. If not, it is a bridge change, and it gates all of group N. |

### Phase 1 — the calendar Kati owns (no sync at all)

Ship a genuinely good local calendar. This is most of the user value and none of the risk.

1. **`Kati.Recurrence`** — the RRULE expander (§3.5). Expand in the event's own timezone in
   wall-clock terms; drop invalid instances; implement the expand/limit table literally.
   Test vectors from RFC 5545 §3.8.5.3.
2. **Ash resources** per §5.6 — including `event_occurrence_override`, `raw_icalendar` and
   `unknown_props` **from the first migration**. Adding these later means a data migration
   over user data; adding them now costs two columns.
3. **`events_in_range(from_utc, to_utc)`** as the single query entry point (§7.4).
4. **`Kati.Calendar.Layout`** (§8.1) + Day (02) and the density rules (09).
5. Month (16), Week (17), Agenda (30), Event detail/edit (31) with the three recurrence edit
   modes (§3.4) — even with no sync, "this and following" must be right, because it defines
   the storage shape.
6. Alarms → `mob_notify`, with the reconciliation pass (§1.3).
7. Jalali display layer + شنبه week start (§7.4), screens 56 and 60.
8. Quick add (18) — English first, Persian second.

**Exit criterion:** a user can run their whole life in Kati offline, and screens 02, 09, 16,
17, 18, 30, 31, 56, 60 are real.

### Phase 2 — `CalendarContract`, read-only

1. Native plugin: list calendars, query `Instances` over a range, read `Events` for the master
   RRULE, read `Reminders`/`Attendees`.
2. Runtime permission flow, with screen 40's "state the purpose" treatment
   (`design-index.md:136`).
3. Merge provider occurrences into the day/week/month/agenda views alongside Kati's own,
   coloured per calendar.
4. Screen 32 rendered over provider accounts, with visibility toggles and a **Live/Stale**
   badge.

**Exit criterion:** Kati shows the user's Google/Exchange/CalDAV(-via-DAVx⁵) events without a
single OAuth dialog.

### Phase 3 — `CalendarContract`, write-back

This is where the §5 engine earns its keep. **Prerequisites, all of them, before a single
write:**

- [ ] Outbox table + idempotency keys + backoff (§5.4)
- [ ] `origin` ownership model enforced end-to-end (§5.5)
- [ ] Tombstones with 90-day retention (§5.3)
- [ ] Conflict detection via `local_rev`/`synced_rev` + provider `_SYNC_ID`/`DIRTY` (§5.7)
- [ ] Conflict UI — reuse screen 37's *"Keep mine / Take file / Keep both"* (`design-index.md:132`)
- [ ] `raw_icalendar` patch-don't-regenerate write path (§5.6)
- [ ] Per-calendar `writeback_policy`, defaulting to "only events Kati created" (screen 32)

Then: create/update/delete Kati events into a chosen provider calendar, and edit mirrored events
only where policy allows.

**Exit criterion:** an event created in Kati appears in the user's Google Calendar on the web
within one OS sync cycle, and vice versa, with no duplicates after airplane-mode testing.

### Phase 4 — CalDAV direct

The best *direct* transport, because it needs no Google review, no Play Services, no client ID
— just a URL and an app-specific password (still requiring §5.9 encrypted storage). Target
Fastmail and iCloud first. Discovery → `sync-collection` with ctag fallback → multiget →
`If-Match` writes (§4.2). This is what makes Kati work on a de-Googled phone.

### Phase 5 — iOS EventKit

Same adapter behaviour (§5.1), different native module. Unblocks the iOS release.

### Phase 6 — Google Calendar API direct (only if justified)

**Gate it on a business decision, not an engineering one:** is the owner willing to complete
and maintain sensitive-scope verification (§4.1.3)? If no, **do not build this** — Phase 2/3
already delivers Google events via the OS. If yes: `AuthorizationClient` plugin, `syncToken`
incremental sync, 410 handling that spares the outbox, foreground-only polling.

**Not recommended at any phase:** Microsoft Graph direct (§4.3), push notifications (§4.1.5),
RSVP/iTIP (§1.5), year view (§1.8).

---

## 10. Issues worth filing

Grouped by phase; `[P0]` = blocks the phase, `[P1]` = needed for the phase to be honest,
`[P2]` = polish.

### Phase 0 — unblock
1. `[P0]` Wire `Mob.Certs.load_cacerts!/1` into `Kati.App.on_start/0`; bundle `castore` PEM.
2. `[P0]` Verify/port the `MOB_BEAMS_DIR` migrations-dir workaround.
3. `[P1]` Pin `MobBridge.kt` in-repo with a CHANGELOG note; add a regression test for
   `offset_x`/`offset_y`.
4. `[P1]` Determine whether the Compose bridge sets `LocalLayoutDirection`; add it if not.
5. `[P1]` Add `tz` (or `tzdata`) and decide the tzdb update policy.

### Phase 1 — local calendar
6. `[P0]` `Kati.Recurrence`: expander implementing the expand/limit table (§3.2c).
7. `[P0]` Recurrence: expand in wall-clock in the event's tz, then convert to UTC (§5.8.3).
8. `[P0]` Recurrence: drop invalid dates and nonexistent local times; document the
   ambiguous-time choice (first occurrence).
9. `[P0]` Recurrence: RFC 5545 §3.8.5.3 examples as the golden test suite.
10. `[P0]` Event schema with `raw_icalendar` + `unknown_props` + `event_occurrence_override`
    **in migration 1**.
11. `[P0]` `events_in_range(from_utc, to_utc)` as the sole query entry point.
12. `[P0]` `Kati.Calendar.Layout` — interval-graph colouring, `max_cols`, span expansion.
13. `[P0]` Collapse-by-kind pre-pass (screens 09/52) running *before* lane assignment.
14. `[P1]` Three recurrence edit modes, with "this and following" as an UNTIL-split (§3.4).
15. `[P1]` `WKST` written explicitly on every `INTERVAL > 1` weekly rule (§3.2).
16. `[P1]` Prefer `DURATION` over `DTEND` everywhere (§1.1).
17. `[P1]` All-day events stored as `Date`, never as midnight instants.
18. `[P1]` Floating-time support (no TZID) for habits/meals.
19. `[P1]` Alarm reconciliation pass; cap pending OS notifications; top up on foreground.
20. `[P1]` Notification actions for snooze (screen 51).
21. `[P1]` Jalali display layer via `ex_cldr_calendars_persian`.
22. `[P0]` **Golden-file test: ~20 known نوروز dates vs the official Iranian calendar** — the
    highest-visibility possible bug for the fa locale.
23. `[P1]` Month grid built in Jalali terms with a Saturday week start (screens 56/60).
24. `[P1]` Persian digit folding (U+06F0–U+06F9) in the quick-add parser.
25. `[P2]` Owner decision: what does *"follows travel"* on screen 31 mean — fixed zone,
    floating, or grid override? (§1.2)
26. `[P2]` Working hours setting (initial scroll offset + tint).
27. `[P2]` FTS5 index for calendar search (screen 19).
28. `[P2]` 3-day view (free once §8 lands).

### Phase 2/3 — CalendarContract
29. `[P0]` Native plugin: `Calendars` / `Instances` / `Events` / `Reminders` / `Attendees` reads.
30. `[P0]` Runtime `READ_CALENDAR`/`WRITE_CALENDAR` flow with purpose strings (screen 40).
31. `[P0]` Outbox table with idempotency keys, `depends_on` chains, backoff, poison quarantine.
32. `[P0]` `origin` (`:kati` | `:mirror`) enforced in the editor and the sync engine.
33. `[P0]` Tombstones, 90-day retention, never GC'd while an outbox entry exists.
34. `[P0]` Account disconnect deletes mirrors and preserves Kati-owned events.
35. `[P0]` Conflict detection (`local_rev`/`synced_rev` + `DIRTY`/`_SYNC_ID`).
36. `[P0]` Three-way property merge with the base `raw_icalendar` from the outbox.
37. `[P1]` Conflict UI reusing screen 37's resolver.
38. `[P1]` Per-calendar `writeback_policy`; default "only events Kati created" (screen 32).
39. `[P1]` Recurring writes must set `DURATION` (Android requires it).
40. `[P1]` Live/Stale badge + last-sync timestamp (screen 32, already drawn).
41. `[P1]` `ACTION_INSERT` intent fallback for users who decline the permission.
42. `[P2]` Defensive reads for OEM provider divergence (Samsung/Xiaomi).
43. `[P2]` Airplane-mode duplicate-suppression test suite.

### Phase 4+ — direct transports
44. `[P0]` **Encrypted credential storage as a native extension** (Keystore/Keychain) — Mob has
    none (§5.9). Blocks every direct transport.
45. `[P0]` CalDAV discovery (`.well-known`, SRV, principal, home-set) with cross-host redirects
    (iCloud shards).
46. `[P0]` `sync-collection` with ctag+etag fallback; treat sync-tokens as opaque.
47. `[P0]` `If-Match` on every PUT/DELETE; `If-None-Match: *` on create.
48. `[P0]` Re-`GET` when a PUT returns no ETag (sabre's warning).
49. `[P1]` `207 Multi-Status` per-resource error handling.
50. `[P1]` iOS EventKit adapter behind the same `Kati.Sync.Adapter`.
51. `[P2]` Google direct: `AuthorizationClient` plugin, two Android client IDs (Play + GitHub
    SHA-1s).
52. `[P2]` Google direct: 410 handling that clears only that calendar's mirrors, never the outbox.
53. `[P2]` Google direct: freeze sync-window query params at connect time.
54. `[P2]` Owner decision required before any of 51–53: complete sensitive-scope verification,
    or accept the 100-user lifetime cap? (§4.1.3)

---

## Sources

**Specs.** [RFC 5545 (iCalendar)](https://www.rfc-editor.org/rfc/rfc5545.txt) ·
[RFC 4791 (CalDAV)](https://datatracker.ietf.org/doc/html/rfc4791) ·
[RFC 6578 (WebDAV Collection Sync)](https://datatracker.ietf.org/doc/html/rfc6578)

**Google.** [OAuth 2.0 for Mobile & Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app) ·
[Authorization on Android](https://developer.android.com/identity/authorization) ·
[Custom URI scheme restrictions](https://developers.googleblog.com/en/improving-user-safety-in-oauth-flows-through-new-oauth-custom-uri-scheme-restrictions/) ·
[Sensitive scope verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification) ·
[Synchronize resources efficiently](https://developers.google.com/workspace/calendar/api/guides/sync) ·
[Push notifications](https://developers.google.com/workspace/calendar/api/guides/push) ·
[Usage limits](https://developers.google.com/workspace/calendar/api/guides/quota) ·
[Recurring events](https://developers.google.com/workspace/calendar/api/guides/recurringevents) ·
[CalDAV API guide](https://developers.google.com/workspace/calendar/caldav/v2/guide)

**CalDAV practice.** [sabre/dav — Building a CalDAV client](https://sabre.io/dav/building-a-caldav-client/) ·
[Fastmail sync guide](https://www.fastmail.help/hc/en-us/articles/360058752754-How-to-synchronize-a-calendar)

**Microsoft.** [Delta query for events](https://learn.microsoft.com/en-us/graph/delta-query-events)

**Android.** [CalendarContract reference](https://developer.android.com/reference/android/provider/CalendarContract) ·
[Calendar Provider guide](https://developer.android.com/guide/topics/providers/calendar-provider)

**Competitors.** [Fantastical](https://flexibits.com/fantastical) ·
[Fantastical App Store](https://apps.apple.com/us/app/fantastical-calendar/id718043190) ·
[iClarified — conference detection & calendar sets](https://www.iclarified.com/76298/fantastical-gets-new-workfromhome-features-including-automatic-conference-call-detection-timed-calendars-sets-more) ·
[Etar README](https://github.com/Etar-Group/Etar-Calendar/blob/master/README.md) ·
[Etar on F-Droid](https://f-droid.org/packages/ws.xsoh.etar/)

**Persian calendar.** [Jalali calendar (Wikipedia)](https://en.wikipedia.org/wiki/Jalali_calendar) ·
[Borkowski, *The Persian calendar for 3000 years*](https://www.astro.uni.torun.pl/~kb/Papers/EMP/PersianC-EMP.htm)

**Elixir packages** (queried via `https://hex.pm/api/packages/<name>`, 2026-08-17).
[cocktail](https://github.com/peek-travel/cocktail) ·
[caldav_client](https://hexdocs.pm/caldav_client/readme.html) ·
`ex_cldr_calendars`, `ex_cldr_calendars_persian`, `jalaali`, `icalendar`, `ex_ical`

**Local sources verified.**
`/Users/shahryar/Documents/Programming/Elixir/kati/.scratch/research/design-index.md` ·
`/Users/shahryar/Documents/Programming/Elixir/kati/.scratch/research/mob-framework.md` ·
`/Users/shahryar/Desktop/first_mob_beam/fresh_mob_beam/source/mob/` (Mob v0.7.20 —
`mix.exs:7`, `priv/tags/android.txt`, `priv/tags/ios.txt`, `lib/mob/canvas.ex`,
`lib/mob/device.ex`, `lib/mob/test.ex`) ·
`/Users/shahryar/Desktop/first_mob_beam/fresh_mob_beam/android/app/src/main/java/com/example/fresh_mob_beam/MobBridge.kt`
</content>
</invoke>
