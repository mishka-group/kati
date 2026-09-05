# Surfaces the record never covered

> **Full screen — three new artboards and one edit to 150** · ticket `D-54`

Somebody's reminders have gone quiet and they want to know whether that is Kati being
polite or Kati being broken. They tap the bell on **board 01** — it is drawn there, a 44pt
disc with an orange unread dot — and arrive at a screen no artboard in 01–166 describes.
They read *Why am I not getting these?* on it and tap that, and arrive at a second screen
no artboard describes. Later they go to Settings to check whether the edit they made to
Thursday's event actually left the phone, tap the **Sync** row board 24 draws — `sync` ·
**Sync** · *iCloud · this device + iPad* · `chevron_right` — and arrive at 1,718 lines of
Elixir that no artboard describes either. Three rooms, three drawn doors, and not one
picture behind any of them. The screens are not stubs: `Kati.Screens.Sync` renders the
outbox, three kinds of conflict question and the preserved losing edits;
`Kati.Screens.InboxNotifications` renders the whole held-back argument against a real
budget; `Kati.Screens.NotificationsHelp` splits five failure modes into *what Kati decided*
and *what the phone decided*. They are simply improvised — built out of screen 24's and
screen 05's vocabulary because there was nothing else to be faithful to — and
`Kati.ScreenDesignLiteralTest`, `Kati.ScreenTitleSubtitleTest` and
`Kati.ScreenEmptyDatabaseTest` all read `test/design/screens/NN.html` by number, so a screen
with no number is a screen with nothing asserted against it. The fourth item here is the
same failure inverted: **board 151** draws Notification access in four states, the screen is
built to it, its back pill already reads `‹ Auto-detect` — and **no board draws the row on
150 that would open it**, so the one place the app explains a permission that can read every
message on the phone is unreachable.

## Why this is one brief and not four

Because three of the four are one stance and the fourth is the sharpest edge of it.

Kati's notification manners are a single argument made in four places: push is off by
default, a badge on the bell stands in for it, quiet hours run 23:00–08:00, a weekly digest
replaces a stream, reminders stop after two skips, and six domains divide a 500-alarm
ceiling so a busy calendar cannot starve the meal reminders. The inbox is where the
suppressed reminders go; the diagnostic is where the suppression is explained; 150's missing
row is the door to the one permission wide enough to make auto-detection work at all. Give
those three different owners and they will say the quiet differently — one will call it
*by design*, one will call it *held back*, one will apologise for it — and the user meets
all three inside two taps.

Sync joins them for a different reason and it is the practical one. It is the third member
of the gallery's `@undrawn` list, which the gallery keeps explicitly as a queue rather than
a graveyard, and all three entries have the same fix: draw the frame, delete the entry, file
the screen under its number in `@screens`. The comment above the list says exactly that —
*"Delete an entry the moment its drawing lands, and add it to `@screens` with the number it
was filed under."* Drawing two of three leaves the list alive for one, and the list is the
thing this ticket is for.

There is also a shared recipe underneath all three, which is why this is smaller than three
full screens sounds. Every one of them is screen 24's settings grammar — the 21pt gutter,
`SettingsList.title/4` over a mono subtitle, `UI.eyebrow/2` over `SettingsList.card/1`,
30×30 icon tiles, hairlines, status pills, action pills and the dashed-frame note. Nothing
below asks for a container `Kati.UI.SettingsList` does not already own. What is genuinely
new is copy, order, empty states and four or five compound rows.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **216** | **NEW — Sync** | Pushed from 24's Data group and from 62's داده‌ها group, both already drawn. The three-figure tally strip, the ownership sentence, and the five groups in order: Accounts, Calendars, Waiting to send, Needs you, Kept not sent — plus the merge footnote that makes the last group mean something. |
| **217** | **NEW — Notifications** | Pushed from board 01's bell. Now, Later, **Held back**, the per-section budget list, and a Manners group whose second row is the only drawn door 218 will have. |
| **218** | **NEW — Why am I not getting these?** | Pushed from 217's Manners group. Two labelled halves — what Kati decided, what the phone decided — the armed-count note, and the closing sentence that says the quiet is deliberate. |
| **150** | **edit** | One row that opens 151, in its own group above *Which apps*. Nothing else on 150 moves. |

This brief **supersedes** `D-34`'s last table row. That row reads *"**150** — notifications ·
the board itself is waiting; `NotificationAccess` is its special-access row and is reached
from it"*, and it was true when it was written. 150 was delivered on 4 September 2026 and is
in `test/design/screens/`; what is still waiting is the row, not the board. The matching
`@no_route` reason in `Kati.AppReachabilityTest` — *"the special-access row. Reached from
150, which is itself waiting"* — is half-stale for the same reason and should be corrected
when the row lands.

---

## 216 — Sync, element by element

Chrome and heading:

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Settings` | Pushed from 24 and from 62. Both parents are drawn; only this destination is not | `arrow_back_ios_new` |
| Header band, no trailing disc | `SettingsList.chrome(nil, 42)` — and **42 is the one measurement on this page nothing justifies**. Every sibling built this round passes 44. Draw the height so the odd number is either right or gone | — |
| Title *Sync* + mono subtitle | 24's title recipe. The subtitle is derived: `3 CALENDARS · LAST SENT 6 MIN AGO`, and with nothing stored `NO CALENDAR CONNECTED · NOTHING LEAVES THIS DEVICE` | — |
| **Tally strip** — one card, three columns | `WAITING` / `STUCK` / `TO ANSWER`. A 26pt figure over a 10pt DM Mono cap through `Kati.UI.number_with_unit/3`, `align="bottom"` with a **declared lift** because no metrics come back from a render. A zero is `tertiary`, not `ink` | — |
| Cream note — **the ownership sentence** | Above the groups rather than under them, because it is what the rest of the page means. *This device holds the original… Kati sends only the events it created, unless you turn write-back on for a calendar.* `SettingsList.note/2`'s dashed-to-solid frame | `shield` |

**Accounts** — eyebrow with the orange rule, then one card:

| Element | Purpose | Glyph |
|---|---|---|
| Account row: 30pt tile, name, sub-line, status pill | The glyph is **derived** from `Kati.Calendars.Account.provider` here and only here — `phone_iphone` for `:local` and `:android_provider`, `dns` for `:caldav`, `mail` for `:google`, `cloud` for `:graph`. `Kati.Screens.Calendars` refuses to derive it because board 32 distinguishes iCloud from CalDAV and the column cannot; this screen derives it *because there was no drawing to contradict*. Drawing 216 ends that freedom — say on the board whether the derivation stands | `dns` |
| Four status pills, not two | `SettingsList.status_pill/3` at 24pt/radius 12. **Live** (green on green wash), **Stale** (red on red wash), **Error** (red on red wash) and **Off** (sub on paper). Board 32 draws only the first two; `:error` and `:disconnected` have never been drawn anywhere, and a sync page is the one surface that has to say them out loud | — |
| Empty card — *No account is connected* | A real row in a real card, not absence: *"Kati is complete with none. Connect one in Calendars and it will appear here."* | `person` |

**Calendars** — the same shape, six possible pills:

| Element | Purpose | Glyph |
|---|---|---|
| Calendar row: name, account, queue counts | `Kati.Sync.status/1` per calendar | `calendar_month` |
| **Read only** / **On device** | The two that are not states but policy — `writeback_policy: :none`, `kind: :local`. Neutral: sub on paper | — |
| **Half sent** / **Stuck** | Red wash. *Half sent* is `Kati.Sync.Outbox.partially_synced/1` — a *this and following* split whose trim landed and whose successor did not. It is carried rather than summed away, so it needs its own pill and its own sentence | — |
| **Waiting** / **Clear** | Accent wash and green wash | — |
| Empty card — *No calendar is connected* | *"Everything you add stays on this device, which is where Kati keeps the original anyway."* | `calendar_month` |

**Waiting to send** — the outbox, capped at twelve:

| Element | Purpose | Glyph |
|---|---|---|
| Outbox row leading glyph — what the change **is**, not how it is going | `add` for a create, `edit` for an update, `delete` for a delete, `sync` for anything else | `add` |
| Row title: *New event* / *Changed* / *Deleted* | The verb, then the event | — |
| Second line, **three lines and allowed to wrap** | Not `SettingsList.body/2`'s one line. Measured, not picked: a row's body sits in roughly 195pt, about 34 characters of 11.5pt text, and the longest line here runs to ninety-odd. At two lines it ellipsised exactly the half that says *why* | — |
| **Retry** action pill — on `:push_failed` and on nothing else | 30pt/radius 15/`#EFECE7`/11.5px semibold. `Kati.Sync.Outbox.fail/3` parks `:reauth` and `:conflict` in `:blocked` *"because trying again cannot fix either of them"*. A blocked row gets a sentence instead | — |
| Five status pills: **Queued**, **Sending**, **Blocked**, **Half sent**, **After** | *After* is the entry that depends on another one landing first | — |
| Overflow row — *N more, not shown* | A cap that hid its own existence would make a queue of two hundred look like a queue of twelve | `more_horiz` |
| Empty card — *Nothing is waiting* | *"Every change Kati has made has already left this device, or never needed to."* | `cloud_done` |

**Needs you** — the conflict questions, capped at six. **This is the part of the page that
is genuinely new and the part a build cannot guess:**

| Element | Purpose | Glyph |
|---|---|---|
| Question card header: tile, event name, calendar's own `display_name`, **Needs you** pill | The calendar is named rather than called *remote*, because one side is an upstream and the other is this device | `help` / `event_busy` / `event_repeat` / `call_merge` |
| Question body: 13.5px semibold headline over a 12.5px `#5C574F` paragraph | Four question shapes, each recovered from what the engine already wrote — a **missing base** (`help`), **delete versus edit** in either direction (`event_busy`), **entangled timing** (`event_repeat`), and a **plain overlap** (`call_merge`). The headline names both halves: *You changed DTSTART. Work changed RRULE.* | — |
| Answer row 1 — **Keep mine** · *Send your version. Theirs is kept below.* | | `phone_iphone` |
| Answer row 2 — **Take &lt;calendar&gt;'s** · *Drop the queued change. Yours is kept below.* | Named for the calendar, not *theirs* — the phrasing is what keeps the asymmetry visible | `cloud` |
| Answer row 3 — **Keep both** · *Theirs stays. Yours becomes a new event.* | The one answer that creates a second event, which is why these are rows and not a segmented strip. Screen 37 can use a strip because the same three words apply to forty CSV rows; here each answer has a different consequence for *this* event | `call_split` |
| The trailing mark on the three answer rows | **Decide this on the board.** All three currently draw `SettingsList.chevron()` and none of them pushes a screen — they resolve in place. The house rule is *a chevron means leads elsewhere*, so as built the page breaks it three times per conflict | `chevron_right` (or nothing) |
| Empty card — *Nothing is waiting on you* | *"Kati asks only when it genuinely cannot decide without inventing something."* | `check_circle` |

**Kept, not sent** — a **muted** eyebrow (grey rule, `SettingsList.eyebrow_muted/1`), then:

| Element | Purpose | Glyph |
|---|---|---|
| Kept row: event, what was changed, when, and which rule set it aside | `event_repeat` when the edit was entangled, `event_busy` when a deletion met an edit, `history` otherwise | `history` |
| **Re-apply** action pill — drawn only where the calendar is writable | `Kati.Sync.Ownership.writable?/2` is asked before the pill is drawn at all, and `authorise/2` again before anything is written. Where it is false the row shows a neutral **Kept** pill instead | — |
| Cream note — **the merge sentence** | The claim the whole group exists to make true: nothing above was thrown away, and putting one back is the same three-way merge as any other edit — it goes through the queue, it can be refused, it will not overwrite the winner | `call_merge` |
| Empty card — *Nothing has been set aside* | *"When two changes cannot both survive, the one that loses is kept here rather than lost."* | `history` |

## 217 — Notifications, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Home` | The bell is on board 01 and this is what it opens | `arrow_back_ios_new` |
| Title *Notifications* + mono subtitle | Derived: `2 TODAY · 5 HELD BACK` | — |
| Eyebrow **Now**, orange rule, then a card of today's armed reminders | 05's grouped-row idiom, which is what this screen was improvised from | — |
| Eyebrow **Later**, orange rule | Everything armed beyond today | — |
| Eyebrow **Held back**, **grey** rule | The rule colour is the argument: held back is not an error state. This is the group that makes the quiet defensible | — |
| Armed row: domain tile, title, body, **a time in DM Mono** on the trailing edge | `movie` for Screen, `calendar_month` for Calendar, `bolt` for Habits, `restaurant` for Meals, `monitor_heart` for Health, `payments` for Money — each domain's own section glyph, not a bell | `movie` |
| Held row: the same tile, **no trailing time**, and the reason on the second line | The asymmetry is deliberate: a held reminder has no time, and printing the one it *would* have had would be the page's one misleading number. Draw all five reasons — *Muted for this show*, *Inside quiet hours — moved to the morning*, *Beyond this section's share of the phone's alarms*, *Rolled into the weekly digest*, *Stopped after two skips* | — |
| An empty group draws **no eyebrow either** | Screen 05's rule. Three empty headings read as an app that has broken rather than as an evening with nothing due | — |
| Eyebrow **By section**, grey rule, then six rows — one per domain, always | *2 of 24 slots*, or *Nothing today*. The share is the real ceiling `Kati.Notifications.Budget` sheds against, so a full section says so **before** a reminder goes missing. A domain with no collector still draws its row, because *nothing today* is an answer and an absent row is not | `payments` |
| Eyebrow **Manners**, grey rule, then two rows with chevrons | — | — |
| Row — **How loudly** · *Quiet hours, digest, stop after two skips* | Pushes screen 25, which is drawn | `notifications_active` |
| Row — **Why am I not getting these?** · *Permissions, alarms and battery* | Pushes 218. **This row is the only drawn door 218 will have**, which is why 217 and 218 cannot be split | `help` |
| **The empty state** — a centred card, not an apology | *Nothing waiting* over *"Kati is quiet unless you ask it not to be. Turn a reminder on and it will show up here first, before it ever interrupts you."* Invites rather than apologises, which is 27's own rule for an empty state | `notifications_off` |
| **The bell's badge, on 01** | Draw what the badge shows and what it looks like at zero. `Kati.Notifications.Inbox.badge/1` counts the **Now** group only — *"a badge counting everything Kati will ever tell you would be a number that never goes down"* — and **it has no caller anywhere in `lib/`**: board 01's orange dot is passed `true` as a literal. A drawn zero state is what lets that be wired | `notifications` |

## 218 — Why am I not getting these?, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill | Says `‹ Settings` today and is reached only from the inbox. **The board decides which** — see *Left open* | `arrow_back_ios_new` |
| Title *Why am I not getting these?* + mono subtitle `FIVE THINGS, THREE OF THEM SILENT` | — | — |
| Eyebrow **What Kati decided**, orange rule | Listed **first**, deliberately: the commonest true answer in this app is *because you did not turn any on*, and a page that opened with permissions would teach the user to blame the phone for a setting | — |
| Row — **Push is off until you ask** · trailing mono *By design* in `sub` grey | Neither good nor bad, so it must not be coloured as though it were | `notifications` |
| Row — **Quiet hours 23:00 – 08:00** · *A reminder inside them moves to the morning. It is never dropped.* · *Shifting* | — | `bedtime` |
| Row — **Held back right now** · a live count and its reasons · chevron back into 217 | The only chevron in this group | `inbox` |
| Eyebrow **What the phone decided**, **bronze** rule | A second rule colour, and it is the page's structure: two halves, two owners | — |
| Row — **Showing notifications** · *Denied, Kati still arms the alarm and the phone never displays it. Nothing reports the failure.* | Four states, three trailings: granted shows mono **On** in green; unasked and denied show an **Allow** pill; blocked shows an **Open settings** pill; and `:none` shows mono **Off** in gold. Draw all four | `notifications` |
| Row — **Exact alarms** · *Without this a reminder is batched — right for "new episode", wrong for "starts now".* | Same four trailings | `schedule` |
| Row — **Battery optimisation** · **Open settings** pill | Its sub-line wraps to **five** lines, not four, because it shares its width with the pill — counted from the device, not guessed | `bolt` |
| Row — **After a restart** · *Anything that was due while the phone was off is gone — it cannot be delivered late.* · mono **Re-armed** in green | — | `timer` |
| Note — **the armed count** | A real figure, not a warning: *"N reminders are armed. This phone allows 500 across the whole app, divided between the six sections so a busy calendar cannot quietly starve your meal reminders. When a section is full, the furthest-away reminder is the one dropped — never the soonest."* | `info` |
| Closing note — **the quiet is deliberate** | Last on the page, because it is the answer somebody arrives at after reading the rest, and putting it first would read as an excuse | `info` |

## The edit to 150 — the row that opens 151

Board 150 draws four bands under its mode switch: the two now-playing cards, *Which apps*,
*Rules*, and *Needs a decision*. **None of them mentions the permission that makes any of it
work.** `D-28` §3 asked for the permission row on this screen — *"The permission row, drawn
very carefully… four things on the row, in this order"* — and the 4 September delivery
answered it with a whole board instead: 151, four states, purpose then scope then the one
action, its back pill already reading `‹ Auto-detect`. Everything §3 asked for exists. The
row does not.

| Element | Purpose | Glyph |
|---|---|---|
| Its own group, **above *Which apps*** | The permission gates every row in that card. Under them it reads as a footnote to a list it is actually the precondition for | — |
| One row: **Notification access** · a one-line reason · chevron into 151 | The row explains nothing and pushes the sheet that explains everything — but *Notification access* alone is not a reason to press, so the sub-line has to carry the scope in one clause. 151's own state-3 row phrases it *On · media notifications only* | `sensors` |
| Its **shipped** appearance: the retired treatment | Play Protect blocks a sideloaded APK declaring `NOTIFICATION_LISTENER` and Kati installs directly, so what ships is 114's retired row — dimmed, `NOT IN V1` badge, `#F1EEE9` tile, `tertiary` title, `rail_idle` sub — reading *Not set up — tap to see why*. 151 draws that row already; 150's is the same row one screen up | `sensors` |
| **The trailing slot holds two marks and the helper holds one** | `SettingsList.trailing/1` wraps a **single** node with a 12pt leading spacer. A `NOT IN V1` badge *and* a `chevron_right` is two. Draw the spacing, or drop one and say which | `chevron_right` |
| What the row becomes in the other three states | 151 is a reference sheet — four specimens stacked. 150's row is **live**, so the board must say what it reads when the permission is granted, never granted, and revoked | — |

---

## States to draw

Kati's sweeps compare an empty state against a board, so an **undrawn empty state becomes an
untested one**. `Kati.ScreenEmptyDatabaseTest` asserts a screen's literals with nothing
stored; a screen either falls back to its own drawing, has an empty board, or is recorded as
having neither — and all three of these screens are in the third category today.

- **Resting.** 216 with two accounts, three calendars, a short outbox and one conflict.
  217 with two reminders in **Now**, three in **Later** and five **Held back**. 218 with
  notifications granted and exact alarms not.
- **Active.** 216 after an answer has been given — the page re-reads and prints a transient
  note through the same `info` frame as the footnotes. Draw one: *"Your version is queued
  again. What Work had is kept below."* There is no other drawing of a settled action on
  this page, and it is the state a user sees most often after doing the one thing the page
  is for.
- **Empty — four, and every one of them is the ordinary case rather than the edge.**
  1. **216 with nothing stored.** This is what a fresh install renders and it is not one
     empty state but five stacked ones: five muted cards, three zeroes in the tally strip
     in `tertiary` rather than `ink`, and the subtitle reading *NO CALENDAR CONNECTED ·
     NOTHING LEAVES THIS DEVICE*. The groups are drawn as **rows in real cards** rather
     than omitted, deliberately — *"a settings group that vanishes when it is empty makes
     the page's shape depend on the data, and a person who has never had a conflict should
     still be able to see where the answer would appear."*
  2. **217 with nothing due.** The centred `notifications_off` card, **and no eyebrows at
     all** above it. This is the commonest state of the app by a wide margin, since push is
     off by default.
  3. **217's *By section* list with six zero rows.** *Nothing today* six times, under a
     subtitle that has to read `0 TODAY · 0 HELD BACK`.
  4. **The bell's badge at zero**, on board 01. Nothing draws it.
- **Error — three, all real rather than invented.**
  1. **216's Stuck column non-zero**, with the two kinds it can be: a `:push_failed` row
     carrying **Retry**, and a `:blocked` row carrying a sentence and no pill. Drawing Retry
     on a blocked entry would be a button that reliably does nothing.
  2. **218 with both permissions refused** — the state the screen exists for. And its
     harder sibling: **blocked**, where Android will not re-prompt, so the pill must say
     *Open settings* and not *Allow*.
  3. **A store that cannot be read.** Every reading function on 216 wraps its query in a
     `rescue` that answers `[]` — *"a store it cannot reach draws an empty page, never a
     crash on a screen the user is looking at."* That means an unreachable database and an
     empty database are the **same drawing**, and the board should say whether that is
     acceptable or whether the page needs a way to tell them apart.

## RTL — does this need a Persian mirror?

**One of the three does, and it is not optional; the other two do not, and the reason is
different for each.**

**216 needs a Persian mirror, because its door is already drawn in Persian.** Board 62's
داده‌ها group draws `sync` · **همگام‌سازی** · *آی‌کلاد · این دستگاه و آی‌پد* · `chevron_left`,
and `Kati.Screens.SettingsFa` routes that row — keyed on the **glyph**, because the Persian
titles carry a zero-width non-joiner — straight to `Kati.Screens.Sync`, the English module.
`Kati.SettingsDataRoutesTest` pins both routes and its whole point is that *"the point of the
pair is that they arrive at the same place"*. So today a Persian reader taps a mirrored row
and lands in an LTR English page mid-sentence. There is no `sync_fa.ex` in
`lib/kati/screens/`. Whether the Persian screen gets built is a separate ticket's call — the
wider Persian Data-group parity gap is not this brief's — but **the drawing it would be built
from is this brief's**, and without it nobody can build one.

What mirrors on the Persian 216: the grid, the back pill's side, the row layout, the
eyebrow's rule (which moves to the right of its label), the tally strip's three columns.
Dates go Shamsi and digits Persian, both in DM Mono so the columns still align. What does
**not** mirror: the **vertical order never reverses** — tally strip still above the ownership
note, Accounts still above Calendars, *Kept, not sent* still last. The back pill's glyph
becomes `arrow_forward_ios` and chevrons become `chevron_left`.

There are two Latin values on this page that a build cannot be trusted to infer, and 82 has
already settled the treatment — Latin in DM Mono inside `direction:rtl`, Persian digits
substituted only where the value is a number. They are the **property names** in a conflict
question (`DTSTART`, `RRULE`, `EXDATE` — they are iCalendar keywords and are not
translatable) and a **calendar's own `display_name`**, which is whatever the server sent.
Draw one Persian question card with both in it.

**217 and 218 do not need Persian boards.** Board 62 draws no bell — the Persian Settings
root has no notifications row of any kind — and `Kati.Screens.HomeFa` is the Persian home; if
it grows a bell, that is the `settings-notifications-row` gap's business and not this one's.
Parity does not oblige a mirror of a screen whose only door is untranslated.

## Dark colourway

**Not needed as separate boards, with one note.** Every surface on all three is one the dark
palette has already answered — card, paper tile, cream note, hairline, action pill, status
pill and the muted empty card on `#121110` / `#1E1D1B` — and 216 in particular resolves
**every** colour through `Kati.Theme.Palette` rather than a literal, which is precisely what
lets a screen with no dark drawing still be a dark screen.

The one thing worth a written note rather than a drawing is **the six status-pill washes on
216**. Green wash, red wash and accent wash carry meaning here in a way they do not on a
settings page — *Clear* versus *Stuck* is the only thing distinguishing two otherwise
identical rows — and three washes on `#1E1D1B` need stating so a build does not pick them
itself. 151's `#F1EEE9` retired tile has the same problem one board over: it is a **third
grey**, between `paper` and `card` and equal to neither, and if 150's new row wears the
retired treatment it inherits that literal.

## Reuse, do not invent

- **All three pages are screen 24's grammar.** 21pt gutters, `padding: 64px 21px 40px`,
  floating back pill, `SettingsList.title/4` over a DM Mono subtitle, `UI.eyebrow/2` over
  `SettingsList.card/1`, 30×30 paper tiles with 17px `#5C574F` glyphs, hairlines between
  rows. Do not invent a container `Kati.UI.SettingsList` does not already own.
- **The grouped-row rhythm on 217 is screen 05's**, which is what it was improvised from —
  including 05's rule that an empty group draws no eyebrow.
- **The status pill** is `SettingsList.status_pill/3`: 24pt high, radius 12, a 5pt dot and a
  10.5px/600 label in one colour. **The action pill** is `SettingsList.action_pill/1` at
  30pt/radius 15/`#EFECE7`/11.5px semibold — *Retry*, *Re-apply*, *Allow*, *Open settings*
  are all this one recipe.
- **The dashed-to-solid note** is `SettingsList.note/2` — 216's two footnotes, 218's budget
  note and its closing sentence are the same frame four times.
- **The empty card** is a real row in a real card with `muted_body` type — `sub` for the
  title, `tertiary` for the line under it. Not a centred illustration. 217's empty state is
  the exception and it is 27's centred-card recipe, not a sixth invention.
- **The three-line second line** on 216's rows is a variant of `SettingsList.body/2` with
  `max_lines: 3`, same type, same colours, same 3pt gap. Not a new row style.
- **150's new row** is 151's own state-4 row, moved one screen up: 114's retired treatment,
  which is the shape of *drawn and not built* app-wide.
- **Prefer glyphs the app already ships.** `mix kati.gen.icons` builds the font subset from
  these boards, and `test/design/material_symbols.codepoints` **is not in the repo** — the
  map in `Kati.Icons` is inlined and nothing is blocked *"until a new symbol is needed"*.
  Every glyph named in this brief is already in it. That is not an accident:
  `Kati.Screens.NotificationsHelp` says so in its own moduledoc — *"a row wanting `alarm`,
  `battery_saver` or `restart_alt` would mean regenerating the font subset for a screen the
  design has not drawn. `schedule`, `bolt` and `timer` say the same three things and are
  already there. When #26 gains an artboard, the glyphs it asks for arrive with it."* This
  brief **is** that artboard, so 218 may now ask for the three it wanted — but asking costs
  a missing codepoints file, so ask deliberately and name each one on the board.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not draw a *Send now* button on 216.** Draining is `Kati.Sync.Engine.drain/3` and it
takes an adapter. `Kati.Screens.Sync` states the consequence:

> **No Send now.** Draining is `Kati.Sync.Engine.drain/3` and it takes an adapter.
> `Kati.SyncBoundaryTest` asserts that `lib/kati/sync/engine.ex` is the only file in the app
> that speaks to a transport, and a screen choosing one would be the second. Sending is the
> background syncer's job.

A *Send now* control is not a missing feature to draw in; it is a build failure with a test
that catches it.

**Do not draw a *Dismiss* on a kept edit.** Same moduledoc:

> **No Dismiss on a kept edit.** `Kati.Sync.RejectedChange.dismissed_at` has no writer
> anywhere in `lib/`, and inventing one on this side would be a discard button for the one
> table whose entire purpose is that nothing is discarded.

**Do not draw an editor.** *"Opening the event belongs to screen 31; this page is about the
queue."* A conflict question may name the event; it may not offer its fields.

**Do not lay the two sides out as equal halves, and do not use the word *remote*.**
`Kati.Sync`:

> Kati's canonical store is the **device**. A remote calendar is an upstream Kati does not
> control and cannot lock. So ownership is not symmetric and "conflict" almost always means
> *the upstream changed under a local edit*, not *two peers diverged*.

A mine-versus-theirs split screen would quietly deny that. The three answers are *Keep mine
/ Take the calendar's / Keep both*, and every question names the calendar by its own
`display_name`.

**Do not draw Retry on a blocked entry.** `Kati.Sync.Outbox.fail/3` parks `:reauth` and
`:conflict` *"because trying again cannot fix either of them"*. A blocked row gets a sentence
saying which of the two it is.

**Do not repeat board 24's sub-line on 216's own heading.** 24 draws the Sync row as
*iCloud · this device + iPad*, and `Kati.Settings.Sample` still holds that string. There is
no iCloud sync, no second device and no account anywhere in Kati — board 40 states the
policy in its own header: *"There is no account, no sign-in and no server."* 216's subtitle
is derived from what is actually stored (`3 CALENDARS · LAST SENT 6 MIN AGO`) and must not
inherit the claim. Whether 24's row is redrawn is another ticket's call; **216 must not make
the claim true by repetition.**

**Do not print *reached from four places* on 218.** Its moduledoc says so —
*"The inbox's Manners group, screen 25's How loudly, screen 51's manners rows and screen 40's
Notifications permission row"* — and exactly **one** of the four exists: `grep -rn
'NotificationsHelp' lib/` finds a single `push_screen` and it is in
`lib/kati/screens/inbox_notifications.ex`. Boards 25, 51 and 40 draw no chevron into it and
none is this ticket's to edit. Draw the one door that will exist and let the moduledoc be
corrected.

**Do not give 150's row an Allow button.** `Kati.Screens.NotificationAccess` is unambiguous:

> Notification access has no dialog to raise. `NotificationListenerService` is *special
> access* — Android's own name for the handful of permissions granted only from a system
> settings screen … it does not get an Allow button, because there is nothing for Allow to
> do. The one action is `Open system settings`.

And `Kati.Permissions`'s capability type is `:notifications | :calendar | :exact_alarms` —
there is no `:notification_access` status to read, so a live row on 150 cannot show one
today. It shows the retired state, which is what actually ships.

**Do not fold 150's row into board 40's Notifications row, and do not draw a second copy of
151's copy on 150.** The first is `D-28` §3's own rule, restated by the screen that keeps it:

> A permission that can read a person's texts does not belong in a list next to "show me
> notifications", so it is not folded into 40's row.

The second is the reason 151 exists: purpose, then scope, then the one action, in a fixed
order that does not reorder by state. A second, shortened scope sentence on 150 is a second
place for that sentence to drift.

**Do not wire *Open system settings* or *Open settings* as though they work.** Both 151 and
218 leave those taps answering with the screen unchanged, and the reason is one line:

> Reaching the system notification-listener settings needs an Android intent no build has
> yet, and `Kati.Screens.NotificationsHelp` leaves `:open_battery` in the same honest state
> for the same reason. Drawn, reachable, and waiting on the intent rather than pretending to
> have it.

Draw the pill. Do not draw a success state behind it.

**Do not colour *by design* as good or bad.** 218's three tones are green for a thing that is
working, gold for a thing that is off, and `sub` grey for a decision Kati made — *"which is
neither good nor bad and must not be coloured as though it were."* Quiet hours are not a
warning.

**Do not print a time on a held-back reminder.** *"A held reminder has no time, and printing
the time it would have had would be the page's one misleading number."*

**Do not redistribute budget slots, or draw a total.** `Kati.Notifications.Budget`: an empty
calendar does not lend its 150 alarms to television, *"because the alternative — a
first-come allocation — makes the set that gets shed depend on the order the domains happened
to be collected in, and a shed set nobody can predict is not a budget."* Six independent
ceilings, six rows, no bar summing to 500.

**Do not make the bell's badge count everything.** `Kati.Notifications.Inbox.badge/1` counts
the **Now** group only — *"a badge you cannot clear is a badge people learn to ignore."*

**Do not draw a domain row for a domain with no collector as absent.** All six draw, always.
*"Nothing today* is an answer and an absent row is not."

**Do not put a chevron on a row that resolves in place.** The house rule, and 216 currently
breaks it three times per conflict card. Whichever way the board goes, it must go one way.

## Left open — decide and note which way you went

- **The trailing mark on 216's three answer rows.** A chevron says *leads elsewhere* and
  these do not; but a row with nothing on its trailing edge may not read as pressable at
  all. A third option is the action-pill treatment *Retry* and *Re-apply* already use. Pick
  one and note it, because three chevrons per conflict is the largest single house-rule
  breach in this ticket.
- **218's back pill.** It reads `‹ Settings` and it is reached from `‹ Notifications`.
  Neither is obviously right: the diagnostic will eventually be reached from Settings too
  (that is the `settings-notifications-row` gap), and a pill that names the wrong parent is
  worse than one that names a general one. Say which, and whether the pill changes with the
  route.
- **Whether 216 keeps deriving its account glyph.** `Kati.Screens.Sync` takes that freedom
  *"because there is no drawing to contradict"*. This board is the contradiction. Either the
  derivation is blessed on the board — and then iCloud and a generic CalDAV principal look
  identical, which board 32 went out of its way to avoid — or 216 needs the same
  service/brand slot `Kati.Screens.Calendars` asks for. It cannot stay undecided once a
  drawing exists.
- **Whether 216's header is 42 or 44.** One number, and nothing currently justifies 42.
- **What 216's five empty groups look like all at once.** Five muted cards stacked is a
  legitimate answer and also possibly a wall. If some of them collapse when empty, say which
  and why the *"a person should still see where the answer would appear"* argument does not
  apply to those.
- **An unreachable store versus an empty one.** Today they are the same page. Decide whether
  216 needs a sixth state that says *Kati could not read its own store* — and if so, what it
  says, because it is the one message on the page that cannot be derived from data.
- **Whether 218 asks for `battery_saver`, `restart_alt` and `alarm`.** Three glyphs that
  say those three rows better than `bolt`, `timer` and `schedule` do. The cost is real:
  `mix kati.gen.icons` needs `test/design/material_symbols.codepoints`, which is not in the
  repo. Ask for them or bless the three substitutes — either is fine, silence is not.
- **What 217's subtitle says at zero.** `0 TODAY · 0 HELD BACK` is honest and reads as
  broken. It is the state most users are in most of the time.
- **The two marks in 150's trailing slot.** `NOT IN V1` badge plus chevron in a helper that
  wraps one node. Draw the spacing, or drop one.
- **Where 150's new row sits relative to the mode switch.** Above *Which apps* is this
  brief's recommendation because the permission gates that card; directly under the
  segmented control is the other defensible answer, since the permission gates the whole
  music mode and not only the app list.
- **Whether the Persian 216 is drawn now or ledgered.** 62's door is already drawn and
  already routed, so the mirror is owed. Whether it is owed *by this ticket* is the owner's
  call, and it should be written down either way rather than discovered later.

## Acceptance — how we know the drawing is complete enough to build from

1. `test/design/screens/216.html`, `217.html` and `218.html` exist, and
   `Kati.Screens.Gallery`'s `@undrawn` list can be emptied: all three entries move into
   `@screens` as `{"216", "Sync", …}`, `{"217", "Notifications", …}` and
   `{"218", "Why am I not getting these?", …}`. An `@undrawn` list with entries left in it
   after this ticket means a board is missing.
2. Every literal the three screens render appears on its board.
   `Kati.ScreenDesignLiteralTest` asserts text and symbols against the rendered tree, so a
   sentence in the code that is not on the board is a failure the moment the number exists —
   including the four conflict headlines, the five held-back reasons, the six pill labels on
   216 and the four empty-card sentences.
3. Each title's subtitle is drawn with a stated `font-size`, family and `margin-top`.
   `Kati.ScreenTitleSubtitleTest` reads exactly that, and it currently reads nothing for
   these three.
4. The empty board for each screen is drawn, not described.
   `Kati.ScreenEmptyDatabaseTest` compares literals with nothing stored, and 216's
   nothing-stored page is a different drawing from its resting one — five muted cards, three
   `tertiary` zeroes, a different subtitle.
5. All six of 216's calendar pills and all four of its account pills appear somewhere across
   the resting and error states, each with a colour and a label — **Error** and **Off**
   included, which board 32 has never drawn.
6. The board settles the trailing mark on the three answer rows, and the settled answer is
   consistent with *a chevron means leads elsewhere* everywhere else on the page.
7. `grep` on the exported 216 finds **no** *Send now*, no *Dismiss*, and no editable event
   field, and finds **Retry** only on a `push_failed` row.
8. 216's subtitle contains no *iCloud* and no second device.
9. 217 draws the *Why am I not getting these?* row with a chevron, so 218 has exactly one
   drawn door — and 218's own copy claims exactly that one, not four.
10. 218 draws all four permission trailings (**On**, **Allow**, **Open settings**, **Off**)
    and its two tones are distinguishable from its neutral one in both colourways.
11. Board 150's export gains exactly one row and one group heading, in its shipped retired
    state, with the other three states written down beside it; the mode switch, the two
    now-playing cards, *Which apps*, *Rules* and *Needs a decision* are byte-identical.
12. Every glyph on the four boards is in `Kati.Icons`'s inlined map, or the board names the
    new symbol explicitly so someone can decide whether it is worth unblocking
    `mix kati.gen.icons` for.
13. The Persian 216 panel exists or is explicitly deferred in writing; if it exists, its
    property names and calendar names read left-to-right inside the mirrored grid and its
    vertical order is unchanged from the LTR board.

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
