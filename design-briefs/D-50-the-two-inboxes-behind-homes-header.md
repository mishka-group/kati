# The two inboxes behind Home's header

> **Mixed — three new artboards, no board edits** · ticket `D-50`

Home's header opens exactly two things, and both of them are inboxes. The hero card carries
`:open_inbox` and pushes `Kati.Screens.Inbox` — screen **05**, New releases
(`lib/kati/screens/home.ex:631` and `:1269`); the bell disc beside the greeting carries
`:notifications` and pushes `Kati.Screens.InboxNotifications` (`:505` and `:1280`). A person taps
one of them because they want the same thing twice — *what has Kati got for me, and what did it
decide not to say?* — and on a phone that has just been set up, neither page can answer honestly.
Screen 05 has a board but no first-launch state, so `inbox/0` falls through to the drawing:
`def inbox, do: releases() || drawn_inbox()` at `lib/kati/screens/inbox.ex:153`, and a device that
follows nothing is shown `Kati.Library.Sample`'s three invented titles — *The Long Hollow*,
*Blue Hour*, *Paper Cities* — with a watcher card claiming **Watching for 24 titles · last checked
18:02**. The notifications inbox has no board at all: `Kati.Screens.Gallery`'s `@undrawn` list holds
it at `lib/kati/screens/gallery.ex:262`, and the screen says so itself — *"There is no artboard for
this screen"* — so its whole Now / Later / **Held back** grouping was inferred from screen 05's
idiom rather than drawn. Held back is the group that makes Kati's quiet defensible, and it is the
one thing on either page with no drawing to check against.

These are one brief because they are one problem twice, one tap apart, and answered in one idiom:
screen 05's two-list card rhythm, the watcher card at the top, and the honesty rule boards
**139**, **158** and **159** already settled — a page with nothing in it says so, rather than
borrowing the drawing's data. Drawn apart, that rule gets decided twice, and two pages a person
reaches from the same header end up disagreeing about what *nothing* looks like.

## Exactly what to draw

| Board | What it is | What it carries |
|---|---|---|
| **203** — new | **Notifications, at rest** — the first artboard `Kati.Screens.InboxNotifications` has ever had | The full page with all three groups populated: `NOW`, `LATER` and a **real Held back treatment**, then `BY SECTION`'s six budget rows and `MANNERS`' two doors. This is the board the built screen gets compared against |
| **204** — new | **Notifications, nothing waiting** — the state a fresh install actually lands in | The `notifications_off` empty card, with **no group eyebrows at all**, over a `BY SECTION` card whose six rows all read `Nothing today`, and `MANNERS` unchanged. Plus one inset: **armed but nothing held**, where `NOW` is drawn and `HELD BACK` is absent entirely |
| **205** — new | **New releases, nothing followed** — screen 05's missing first launch | 05's chrome with the watcher card **reworded to the one value that is real**, an empty state in 139's geometry, and a decision drawn about the `Mark all` pill, the two eyebrows and the mono subtitle at zero |

No existing board is edited. 01, 05 and 25 stay exactly as they are.

## Every element, and the glyph it takes

Every symbol named below is already in `Kati.Icons`' inlined map. That is a hard constraint rather
than tidiness: `test/design/material_symbols.codepoints` is not in the repo and never was,
`mix kati.gen.icons` wants it, and per `docs/DESIGN-ASSETS.md` *"nothing is blocked until a new
symbol is needed"* — so a glyph invented on these boards is the thing that blocks the build. One
name a designer will reach for here is **not** in the map: `expand_less`. See *Left open*.

### Artboard 203 — Notifications, at rest

| Element | Purpose | Glyph |
|---|---|---|
| Floating back pill, 44pt, reading **Home** | `use Kati.Screens.Pushed, back: "Home"`. `SettingsList.chrome(nil, 44)` reserves a bare 44pt band and **no trailing disc** — this page has no overflow, unlike 05's `Mark all` | `arrow_back_ios_new` |
| Large title **Notifications**, 28/700, `-.03em` | Screen 05's title recipe exactly | — |
| Mono subtitle `3 TODAY · 2 HELD BACK` | `subtitle/1`, upcased, DM Mono 11px in `#A9A29A`. It prints *today* and *held* and deliberately never prints *later* — the two numbers a person came for | — |
| Eyebrow **NOW**, accent rule | `group/3` passes `Palette.accent()` for an armed group | — |
| **Now** card — rows of 30×30 paper tile, 13.5/600 title, 11.5 `#8A8479` second line, **trailing time in DM Mono 12px `#8A8479`** | Each row is one armed reminder. The second line is the candidate's own body, falling back to the domain label. **No chevron**, though the row does push a screen — see *Left open* | one per domain: `calendar_month` · `movie` · `bolt` · `restaurant` · `monitor_heart` · `payments` |
| Eyebrow **LATER**, accent rule | Same treatment as Now — both are armed | — |
| **Later** card | Identical rows; the time is a later day's | same six |
| Eyebrow **HELD BACK**, **quiet rule** `#C4BDB3` | `group/3` swaps the dash to `Palette.rail_idle()` for the held group. This is the only visual difference the code currently makes between held and armed, and it is not enough | — |
| **Held back** card — the treatment this brief exists for | Same tile and title; the second line is the **reason**, and the trailing slot is **empty** | same six |
| The five reason sentences, verbatim | `Kati.Notifications.Inbox.held_reason/1` already writes them: `Muted for this show` · `Inside quiet hours — moved to the morning` · `Beyond this section's share of the phone's alarms` · `Rolled into the weekly digest` · `Stopped after two skips`. Draw all five, one row each — they are five different feelings, not one | — |
| Eyebrow **BY SECTION**, quiet rule | — | — |
| **By section** card — six rows, in `Kati.Notifications.Budget`'s own order | `calendar` · `tv` · `habits` · `meals` · `health` · `money`, labelled `Calendar` · **`Screen`** · `Habits` · `Meals` · `Health` · `Money`. Second line is `2 of 120 slots` in the row's normal 11.5 weight, or `Nothing today`. **No trailing value, no chevron, no tap** | the same six |
| The real Android limits, so the board prints numbers the app can | 150 · 120 · 80 · 60 · 40 · 30, against a 500 cap and a 480 total. These are `Kati.Notifications.Budget`'s table, not placeholders | — |
| Eyebrow **MANNERS**, quiet rule | — | — |
| **How loudly** — *Quiet hours, digest, stop after two skips*, with a chevron | Pushes screen **25**, Release watcher, which already draws `Inbox badge · Unread count on the bell` — so 25 names this page and this page has never named 25 back | `notifications_active` · `chevron_right` |
| **Why am I not getting these?** — *Permissions, alarms and battery*, with a chevron | Pushes `Kati.Screens.NotificationsHelp`, which is **also** in `@undrawn` (`gallery.ex:263`). Draw the row; do not draw the screen behind it — that is a different ticket | `help` · `chevron_right` |

### Artboard 204 — Notifications, nothing waiting

| Element | Purpose | Glyph |
|---|---|---|
| Back pill, title | Unchanged from 203 | `arrow_back_ios_new` |
| Mono subtitle at zero | Today `subtitle/1` prints `0 TODAY · 0 HELD BACK`. Screen 96's rule — *"never render a plausible-looking zero"* — makes that a question rather than a given. Word it or replace it on the board | — |
| **No group eyebrows whatsoever** | `group/3`'s first clause returns `[]` for an empty list, eyebrow included, and its doc says why: *"three empty headings read as an app that has broken rather than as an evening with nothing due"*. The board must show that absence, because the sweep will assert it | — |
| **The empty card** — `#FBFAF8`, radius 22, padding 19, centre-aligned | The whole page's answer. 26px glyph in `#B3ACA2`, 12pt gap, **Nothing waiting** at 16/bold, 7pt gap, then the sentence at 12.5px / 1.55 line-height in `#8A8479` | `notifications_off` |
| The sentence, verbatim | *"Kati is quiet unless you ask it not to be. Turn a reminder on and it will show up here first, before it ever interrupts you."* Already written in `empty/1`, and it invites rather than apologises — screen **27**'s own rule for an empty state | — |
| **By section**, still drawn, six rows, every one reading `Nothing today` | `by_domain/1`'s doc is explicit: *"A domain with nothing armed still gets a row, because* nothing today *is an answer and an absent row is not."* This card is what stops 204 from being a blank page with a card on it | the same six |
| **Manners**, still drawn, both rows | The second row is on the inbox rather than in Settings for exactly this state — *"the person asking that question is looking at an empty inbox when they ask it"* | `notifications_active` · `help` · `chevron_right` |
| **Inset: nothing held.** `NOW` populated, `HELD BACK` absent, subtitle `2 TODAY · 0 HELD BACK` | The commoner half of "empty" and the one the code branches on differently: `empty/1` only fires when **all three** groups are empty, so a page with two reminders and nothing suppressed draws no empty card and no held eyebrow. Both halves have to be on the board or one of them ships undrawn | — |

### Artboard 205 — New releases, nothing followed

| Element | Purpose | Glyph |
|---|---|---|
| Back pill **Home**, 44pt | Unchanged from 05 | `arrow_back_ios_new` |
| **Mark all** pill — 36pt, radius 18, `#E4E0D9`, 12.5/600 | Drawn on 05 unconditionally by `mark_all/0`. `grep -c on_tap lib/kati/screens/inbox.ex` returns **0**, so it marks nothing today — but the question this board must answer is narrower and answerable: **does it survive a page with nothing to mark?** | — |
| Large title **New releases** | Unchanged | — |
| Mono subtitle | `title/1` composes `"#{length(out_now)} out now · #{length(coming_up)} coming up"`, so at zero it reads `0 out now · 0 coming up`. Same 96 question as 204's subtitle, and it should get the same answer on both boards | — |
| **The watcher card, reworded** — cream `#FBF1DE`, radius 20, padding 15/17 | The heart of this artboard. Three values, and `Kati.Screens.Inbox`'s moduledoc separates them: `Watching for 24 titles` is **real and queryable** (`:followed` is precisely the set); `last checked 18:02` is not (*"nothing records when the watcher last swept"*); `every 6h` is not (it *"lives in no resource and no policy module"*). At zero the first becomes `Watching for 0 titles` — or a sentence — and the mono meta line has nothing honest left to say | `auto_awesome` 22px `#C98A3E`, trailing `settings` 19px `#C98A3E` |
| **The empty card**, in 139's geometry | 64×64 tile at radius 20 on `#EFECE7`, glyph 28px in `#C4BDB3`; title 17/700 at `-.02em` 18pt below; sentence 13px / 1.6 in `#8A8479`; then **one ink action** at 54pt radius 27, and **one quiet alternative** at 12.5/600 in `#8A8479`. 139's own footnote names this shape: *"glyph tile, sentence, one ink action, one quiet alternative"* | `movie` or `notifications_off` — pick one and say why |
| The ink action | Screen **06**, *Add a title*, is the only door in the app that puts something into `:followed`. Board 27's own empty specimen already pairs `add Add a title` with a quiet *or import a backup* — but 27 is the **library** empty, not the release inbox's. Whether 205 borrows it is the second open question below | `add` |
| **The what-still-works band** — 139's dashed footnote, 1.5px dashed `rgba(26,25,23,.16)`, radius 18, padding 15 | 139 ends with it because *"an empty Home that looks broken sends a new user back out"*, and the same is true one push down. Here the true sentence is that the watcher is running and has nothing to watch — not that it failed | `info` 17px `#8A8479` |
| **`OUT NOW · 0` and `COMING UP` eyebrows** — present or gone | 05 draws the first with its count interpolated (`UI.eyebrow("Out now · #{length(...)}")`) and the second with a quiet rule. The notifications inbox drops an empty group's eyebrow; 05 has never had to decide. Draw the decision | — |

## States to draw

`Kati.ScreenEmptyDatabaseTest` renders every screen against an empty store and asserts the board's
literals against the rendered tree — `test/kati/screen_empty_database_test.exs:1314` pins screen 05
as the pair `{"05", Kati.Screens.Inbox, &inbox/0, &drawn_inbox/0}`, comparing the whole map, watcher
card included. So on these two screens an undrawn empty state is not a cosmetic gap; it is an
untested one, and it is the reason two of the three artboards **are** empty states.

- **Resting.** 203 with all three groups full. This is the one state the notifications inbox has
  never had a drawing of at all.
- **Active.** A row under the finger on 203. Worth drawing because these rows are the ambiguous
  case: they push a screen and carry no chevron, so nothing else on the board says they are
  controls.
- **Empty.** Both 204 and 205, and on 204 **both** of its two shapes — all-groups-empty and
  held-empty. These differ in code and must differ on the board.
- **Error.** Do not invent one. Board **27**, the states reference sheet, already draws this exact
  failure — an `error` glyph over **Couldn't check for releases**, a mono `Last success 6h ago`, and
  a `Retry` — and `Kati.Screens.States`' moduledoc says why the figure beneath it is not read live:
  *"Dating a real last success against an invented failure is worse than the drawing: it reads as a
  live incident report and is not one."* What 205 owes is one sentence saying **where that card
  goes on this page** when a check fails on a device that follows nothing — above the empty card,
  in place of it, or not at all. 27 also settles offline (`cloud_off`, *Ticks are saved and will
  sync later*) and loading (a skeleton, never a spinner) for both pages.

## RTL

**Yes for both, and it is cheap** — every element on all three artboards is a row of glyph ·
label · trailing value, which mirrors mechanically. Do not draw separate Persian artboards under
this ticket; draw the mirror rules onto these three and let a Persian pair be its own ticket, the
way **158** was drawn as 139's mirror rather than folded into it.

- **Mirrors:** the whole grid under `dir="rtl"`; each row's icon tile and label swap sides; the
  trailing time moves to the leading edge; the back pill's glyph becomes `arrow_forward_ios`; the
  two `chevron_right` on the Manners rows become `chevron_left`; the eyebrow's 13×2 rule moves to
  the right of its label.
- **Does not mirror:** the **vertical order**. `NOW · LATER · HELD BACK · BY SECTION · MANNERS` runs
  top to bottom in both directions, and *Held back* stays third — it is a consequence of the two
  groups above it, and reordering it in Persian would make the page argue differently in one
  language. On 205, the poster artwork never mirrors, and neither does the watcher card's internal
  order.
- Times and dates go Shamsi with Persian digits, both in DM Mono so the trailing time column on 203
  still aligns down the page — that column is the whole reason the armed rows read as a schedule.

## Dark colourway

**Not as separate artboards**, and 159 is why: it is the dark pair for 139 and it has already
settled the empty-state recess — *"The glyph tile goes `#2A2826` against the `#1E1D1B` card so the
empty state still reads as a recess, and cards lift on a hairline rather than a shadow."* 204's
`notifications_off` tile and 205's 64×64 tile are that same tile, and they inherit that answer.
Everything else on these boards is `Palette.card()`, `Palette.paper()`, `Palette.sub()` and
`Palette.rail_idle()`, all of which carry a real dark column (`rail_idle` goes `#C4BDB3` → `#4A453F`)
and swap with the mode on their own.

**One exception, and it is checkable.** `Kati.Theme.Palette` stores `gold_icon` as
`{:gold_icon, 0xFFC98A3E, 0xFFC98A3E, :hue, …}` — byte-identical in the light and dark columns —
while `cream` beneath it moves `#FBF1DE` → `#2A2622`. So 205's watcher card is the one element on
these three boards whose glyph does not move when its ground does. Draw that card **once** on dark
ground as an inset on 205 and either confirm `#C98A3E` holds on `#2A2622` or name the treatment
that replaces it. No new artboard number for it.

## Reuse, do not invent

- **The page frame** on all three is the pushed-screen recipe: scroller `padding: 64px 21px 40px`,
  floating back pill, no dock, frame closes at 40. Screen 05 is the reference.
- **The title and mono subtitle** are 05's, unchanged: 28/700 at `-.03em`, 5pt gap, DM Mono 11px in
  `#A9A29A`.
- **The row card** is `Kati.UI.SettingsList.card/1` with the house list row — 30×30 paper tile at
  radius 9, glyph 17px `#5C574F`, title 13.5/600, second line 11.5px `#8A8479`.
- **The trailing time** is 05's own coming-up meta: DM Mono 12px in `#8A8479`.
- **The eyebrow** is the house eyebrow, accent rule for an armed group and `#C4BDB3` for a quiet
  one — exactly the split `group/3` already passes.
- **The empty card on 204** is `Kati.Screens.InboxNotifications.empty/1` as built: centred glyph,
  16/bold heading, 12.5/1.55 body on a `#FBFAF8` card at radius 22.
- **The empty geometry on 205** is **139**'s, not a new one — glyph tile, sentence, one ink action,
  one quiet alternative — and 139 took it from **27**.
- **The what-still-works band on 205** is 139's dashed `info` footnote.
- **The cream watcher card** is 05's own, at radius 20 with `#B09A72` mono meta.
- **The four non-resting states** are 27's specimens, unchanged.
- **The Manners rows** are the standard list row *with* chevrons, because both of them genuinely
  push a screen.

## What it must NOT do

- **It must not put the drawing's data on an empty page.** This is the defect, stated by the code
  that causes it. `Kati.Screens.Inbox`: *"With nothing followed there is nothing to be new and
  `Kati.Library.Sample` is drawn instead… A user who follows something and has nothing out this
  week sees an **empty** Out now section rather than the drawing's three rows: that is the true
  answer, and substituting the drawing there would be three titles they do not have."* 205 is the
  board that lets the same honesty reach the *fresh install* branch, which today gets the drawing.
- **It must not put a live number beside a frozen one.** `Kati.Screens.Inbox` refuses to wire the
  watcher count on its own and says why: *"A card that reads `Watching for 7 titles · last checked
  18:02` puts a live number beside a frozen one in the same breath, and the second is then
  indistinguishable from the first"* — which is `Kati.Library.Sample`'s own warning, *"sample data
  that looks like real data is how a demo quietly becomes a lie"*. So 205 may not simply set the
  count to `0` and leave `last checked 18:02 · every 6h` under it. Either the whole meta line goes,
  or the card becomes a sentence.
- **It must not give a held row a time.** `trailing/2` returns `nil` for every held candidate, and
  the doc is unambiguous: *"a held reminder has no time, and printing the time it* would *have had
  would be the page's one misleading number."* Whatever the Held back treatment turns out to be, its
  trailing slot stays empty.
- **It must not draw an eyebrow over an empty group.** `group/3`: *"An empty group draws no eyebrow
  either — screen 05's rule, and the reason is that three empty headings read as an app that has
  broken rather than as an evening with nothing due."*
- **It must not drop a section's row because that section is quiet.** `by_domain/1` is the opposite
  rule and it applies to the same page: *"A domain with nothing armed still gets a row, because*
  nothing today *is an answer and an absent row is not."* On 204 all six rows stay.
- **It must not send a row to the thing it is about.** `tag_for/1` states the routing and the reason:
  *"a held meal reminder is a question about screen 51, not about this page. So the tap carries the
  **domain** rather than the candidate, because the domain is the thing that has a screen; a
  candidate has an id, and an id has no destination."* A row about tonight's dal opens Meal
  reminders, never the meal.
- **It must not draw a badge counting everything.** `Kati.Notifications.Inbox.badge/1`: *"The `now`
  group only. A badge counting everything Kati will ever tell you would be a number that never goes
  down, and a badge you cannot clear is a badge people learn to ignore."* If 204 shows the bell at
  all in a callout, it shows it against `now`.
- **It must not answer the Watch pill.** 05's `Watch` pill and the watcher card's `settings` cog are
  a separate, filed gap — nothing on 05 carries an `on_tap` today, and what those two open is not
  this ticket's to decide. 205 draws the page with **nothing followed**, where there are no Out now
  rows and therefore no Watch pills at all. Do not use the empty board as a back door to that
  decision.
- **It must not give screen 05 a route argument.** Every detail screen in this app opens
  generically; that is a code defect with its own history and not a thing a board fixes.
- **It must not treat `Kati.Screens.NotificationsHelp` as drawn.** It sits in the same `@undrawn`
  list one line below the notifications inbox, and `Kati.Screens.Gallery` explains the whole pair:
  *"#26 is a **design** ticket that names the components rather than supplying a frame."* This brief
  supplies the frame for one of the two. Drawing the second by implication is how the pair ends up
  inconsistent.
- **It must not invent a symbol.** See the constraint above the element tables.

## Left open — decide and note which way you went

- **The ticket's first question: is Held back a collapsed group or a footnote?** A collapsed group
  is a real option — but `expand_less` is **not** in `Kati.Icons`' map (`expand_more` is), so a
  disclosure that rotates is buildable today and one that swaps glyphs is not. A footnote is the
  other road, and it costs something the moduledoc says is the point: *"Held back is the group that
  makes the quiet defensible… a user who can read them can tell the difference between an app being
  careful and an app having failed."* A footnote that hides five different reasons behind one line
  gives that up. Decide, and say which.
- **The ticket's second question: does 205 offer the follow action, or only explain?** Board 27's
  library empty offers `add Add a title` with a quiet *or import a backup* beneath it, and 139's
  Home empty offers `Choose sections` with *or restore a backup*. Both offer. But a release inbox is
  the **output of a watcher**, not a shelf — the honest instruction may be *go and add something to
  the shelf and this fills itself*, which is a different sentence and possibly a different
  destination (06, or the shelf at 03). If it explains only, it must still say what would fill it.
- **Does a row that pushes a screen need a chevron?** The house rule runs one way only — *a chevron
  means leads elsewhere* — and says nothing about the inverse. 203's reminder rows push a screen and
  carry a **time** in the trailing slot instead. Either the time displaces the chevron (and the row
  reads as a listing, not a control), or both appear, or the chevron wins and the time moves. The
  Manners rows below them have chevrons, so whichever way this goes, one card on the page will look
  like a control and the other will not.
- **The mono subtitle at zero**, on both 204 and 205. `0 TODAY · 0 HELD BACK` and `0 out now · 0
  coming up` are exactly the *plausible-looking zero* screen 96 forbids, printed by
  `subtitle/1` and `title/1` today. Replace them, drop them, or argue that a counted zero under a
  heading that says *Nothing waiting* is honest rather than plausible. One answer for both boards.
- **Does `Mark all` survive an empty 05?** It marks nothing today, which is a code gap; whether it
  is *drawn* on a page with nothing to mark is a design decision and this is the board for it.
- **What the watcher card says at zero.** `Watching for 0 titles`, a sentence, or the card omitted
  entirely — and if it is omitted, whether the `settings` cog goes with it, since that cog is the
  only thing on 05 pointing at screen 25.
- **The bell's dot.** `Kati.Screens.Home.disc("notifications", true, :notifications)` hardcodes the
  badge to `true`, and `Kati.Notifications.Inbox.badge/1` — which computes the real count — is
  called by nothing in `lib/`. So a fresh install shows an unread dot over a bell that opens *Nothing
  waiting*. Board 01 draws that dot; `Kati.Screens.HomeEmpty` draws no bell at all
  (`home_empty.ex:187` puts a single `tune` disc in the header), so the notifications inbox at its
  emptiest is reachable only from a Home that is *not* empty. This ticket edits no boards, so record
  the decision as a note on 204 and let 01 be redrawn under its own ticket if it needs to be.
- **Whether `BY SECTION` belongs above or below `MANNERS`.** The built order puts the budget card
  first. On 204, where every one of its six rows reads `Nothing today`, six identical rows directly
  under an empty card may read as a second, longer way of saying nothing.
- **Whether 203's held rows carry a marker of their own** — a `visibility_off` or
  `do_not_disturb_on` in place of the trailing time, or a lower-contrast tile — beyond the quiet
  eyebrow rule the code already draws. Both glyphs are in the map.

## Acceptance — how we know it is complete enough to build from

1. **`Kati.Screens.InboxNotifications` has a board.** 203 exists, and the line
   `{:open_undrawn_notifications, "Notifications", Kati.Screens.InboxNotifications}` at
   `lib/kati/screens/gallery.ex:262` can be moved out of `@undrawn` into `@screens` under the number
   203, which is what that list's own comment asks for: *"Delete an entry the moment its drawing
   lands."*
2. **The moduledoc sentence stops being true.** `lib/kati/screens/inbox_notifications.ex` says *"There
   is no artboard for this screen"* and *"It is built in screen 05's idiom instead"*. Both are
   replaceable with a board number when 203 lands.
3. **Held back has a drawn treatment**, with all five `held_reason/1` sentences visible on the board
   and every held row's trailing slot demonstrably empty.
4. **All six `BY SECTION` rows are on 203 and on 204**, in `Budget.domains/0`'s order, labelled with
   `domain_label/1`'s words — including **`Screen`** for `:tv` — and carrying the real Android
   limits.
5. **204 shows both empty shapes**: the all-groups-empty page with the `notifications_off` card and
   no group eyebrows, and the inset where only Held back is absent.
6. **205's watcher card contains no unqueryable value.** A reviewer can point at every figure on it
   and name the column behind it, or the card is a sentence with no figures.
7. **205 draws an empty state, not a blank page**: glyph tile, sentence, one action or a stated
   refusal to offer one, and the band saying what still works.
8. **Every mono zero on 204 and 205 is either worded or gone**, with one rule applied to both.
9. **Each of the eight *Left open* decisions is recorded on the artboard it belongs to**, in the
   drawing's own annotation column, so the next reader does not have to re-derive it.
10. **`Kati.ScreenEmptyDatabaseTest` has something to compare against.** Today it pins screen 05's
    empty render to `drawn_inbox/0` — the drawing's three invented titles. When 205 lands, that pair
    can be repointed at a real empty state, and the notifications inbox can join the sweep at all.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. These boards take
the numbers reserved above.

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
