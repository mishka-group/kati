# The rows that lead nowhere

> **Mixed — three new artboards and five board edits** · ticket `D-46`

Somebody opens **Money**, reads *Orbit · renews 24 Aug · 6h watched · £13.99 · £2.33/h*,
decides that is too much for six hours, and taps the row. Screen 122 pushes screen 23 —
the same list again, one heading up. They tap Orbit there and nothing at all happens.
They go to **My services**, tap Orbit in the Subscribed group, and nothing happens there
either. Then they notice the £14.00 they logged as a cinema ticket was actually £4.00,
tap that row on 122, and nothing happens; they tap the same expense on 126 and nothing
happens. Finally they tap *Show all 47 · Everything JustWatch lists for the UK*, which
draws a chevron and therefore promises a destination, and land back on the screen they
started from. **Five taps, four of them on rows the boards drew as list rows, and not one
of them opens a page — because the page each is pointing at has never been drawn.**

## Why this is one brief and not three

Because it is `D-34`'s problem turned around, three times, with one recipe behind all
three.

`D-34` was eight screens that were built, tested and reachable by nothing, because the
**door** was not drawn. Money is the mirror image: the doors are drawn — a list row with
a value and, on 92 and 93, a literal `chevron_right` — and there is **no screen behind
them**. Three lists point at a service page that does not exist (122's Recurring rows,
92's Subscribed and Free groups with 97 behind them, 23's four rows). Two lists point at
an expense that does not exist (122's One-off rows, 126's outlined fact card). One row on
92 and 93 points at a catalogue that does not exist anywhere in 01–166.

Splitting it would make the three answer differently, which has already happened once:
92's *Show all 47* pushes `Kati.Screens.MyServicesEmpty` and 93's identical row pushes
`Kati.Screens.Subscriptions`, and nothing in the repo can see the divergence because
neither destination is wrong about a board that does not exist. All three are read-only
for the same reason and all three are drawn from the same recipe — screen **31** is the
model already in the set: a `close` disc, a centred title, an ink **Save** pill, editable
rows underneath and an outlined `delete` bar at the foot. And **123 has already decided
what the states these pages produce look like**: *paused until October · not in the total*
and *Dispatch — cancelled 2 Jun · out of the active list and out of the monthly figure,
its 31 hours still count toward 07*. So this brief draws the controls for states the
design has already committed to, rather than inventing them.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **193** | **NEW — one service** | The page behind every service row in the app. Badge, name, the price, the renewal date, the cost-per-watched-hour verdict, the tier, pause, and the cancel that keeps the hours. Reached from 122, 23, 92 — and from 127 and 97. |
| **194** | **NEW — one expense** | The page behind every expense row. The amount, the description, the section, the date, the stored currency, and a delete. Reached from 122's month groups and from 126's outlined fact card. |
| **195** | **NEW — the service catalogue** | The 47 rows *Show all 47* has been promising since 92 was drawn. The first board in Kati whose whole content is remote, so it is also the first that has to draw *not fetched yet* and *could not fetch*. |
| **122** | edit | A trailing chevron on every Recurring row and every One-off expense row. No other ink. |
| **23** | edit | A trailing chevron on all four Services rows. |
| **92** | edit | A trailing chevron on the three Subscribed rows and the two Free-with-ads rows; and the *Show all 47* row annotated with its real destination. |
| **93** | edit | The *Show all 47* row annotated with **the same** destination as 92's, in its no-region state. |
| **126** | edit | An affordance on the outlined fact card — the one row on that page that is a stored record rather than a drawing. |

**The five edits are chevrons and annotations, not redraws.** `grep chevron 122.html
23.html 126.html` returns **nothing** — there is not one chevron on any of the three, so
every row on them currently obeys the house rule (*a chevron means leads elsewhere*) by
being honestly mute. 92 and 93 already hold three chevrons each. The recipe for a row that
carries both a value and a chevron is on 92 already: `payments` tile, *Subscriptions* over
*3 services / £46.47 A MONTH*, then a `chevron_right` at 18px in `#C4BDB3`. Use exactly
that; do not invent a second shape for a row with a right-hand column.

## Every element, and the glyph it takes

Every symbol below is already in `Kati.Icons`' 140-name map, so these three boards cost no
`mix kati.gen.icons` run. That is deliberate — `test/design/material_symbols.codepoints`
is not in the repo, so a new symbol is a blocked build rather than a small chore.

### 193 — one service

| Element | Purpose | Glyph |
|---|---|---|
| Chrome — `close` disc, centred title, ink **Save** pill | 31's header row, in flow at the top of the scroll. Not a back pill — see *Left open*: three different parents push this page, and `Kati.Screens.Pushed` takes one compile-time `back:` label | `close` |
| **Badge tile**, 40×40 | 92's `badge_tile/1` exactly — paper, radius 12, the letter at 15px/700. `Kati.Services.Service.badge/1` falls back to the name's first character and returns `?` for an uncased one; draw the `?` case as an inset | — |
| Service name, editable | `name` is the one `allow_nil?: false` column. Draw the refusal when it is blank | — |
| Mono subtitle | `£8.99 A MONTH · RENEWS 18 AUG`, DM Mono, `.16em`. Both halves can be nil — see the empty state | — |
| **The rate, as the hero** | A cream card carrying `£0.21/h` over `41h watched`. Green at £0.21/h, `#B4553C` at £2.33/h, **tertiary at `—`**. This is the figure the whole money section exists for; on a page about one service it is the page's subject, not a column | `trending_up` |
| **Price** row | `monthly_pence` + `currency`. Whether it is a field here or read-only is **not this ticket's** — see *What it must NOT do* | `payments` |
| **Renews** row | `renews_on`, a stored `:date` column. `Kati.Notifications.Sources.Money` is its only reader today | `event_upcoming` |
| **Tier** row | `Subscribed` / `Free with ads` / `Not mine` — the three `Kati.Services.Service.tier` values, which are 92's three groups. Moving a service between them is what re-files its row on 92 | `subscriptions` |
| **Pause** — a switch or a row | `paused` is a stored boolean. 122's own note states the consequence and the board must repeat it: *paused services keep their row and leave the total* | `pause_circle` |
| Paused-state line | `paused until October · not in the total` — **123's exact words**. Draw the resumed state too, since a pause a person cannot undo is a cancel | `play_arrow` |
| **What is on it** — quiet note | For a service with `provider_id: nil` (everything typed under *Something else*): *Kati will remember it for your subscription total, but cannot tell you what is on it.* 92 promises this sentence; 193 is where a reader finds out it applies to their row | `info` |
| **Cancel this subscription** — outlined destructive bar | 31's `delete/0` recipe: full width, 48 high, radius 24, `Palette.red_ring()` border at 1.5, `delete` at 18px and a 13px/700 label, **no background at all** | `delete` |
| The sentence under it | 123's cancelled card, verbatim: *out of the active list and out of the monthly figure. Its 31 hours still count toward 07, because you did watch them.* This is the difference between cancelling and deleting and it has to be on the board | `history` |

**The word on the destructive bar is `Cancel`, not `Delete`, and the board must say why.**
Screen 95 already draws the consequence one screen over — *Orbit is off, but 43 entries
mention it · Those stay exactly as they were. Kati never rewrites what happened.* A
service is referenced by watch history that outlives it, which is exactly what `:not_mine`
is a tier for. `Kati.Services.Service`'s moduledoc puts it plainly:

> That is not clutter: knowing a title is on a service you have **not** got is what makes
> `Hide titles I can't watch` mean anything, so a service the user has explicitly marked
> as not theirs is a fact worth keeping.

### 194 — one expense

| Element | Purpose | Glyph |
|---|---|---|
| Chrome — `close` disc, title, ink **Save** pill | 31's again, and 124's own header is the same disc | `close` |
| **The amount, as the hero** | DM Mono, large, the stored `currency`'s symbol beside it. `£9.99` | — |
| **The amount with no amount** | `amount_pence` is nullable and 122 prints `"—"` for it. The hero draws the em dash and the field beneath is 124's inline trough ringed in orange — *the page's one accent* | `error` |
| **Description** — a text field | `description`, `allow_nil?: false`. The one required value, and today it is the literal `"The Salt Almanac"` on every row a user can create | — |
| **Section** row | The six `section` values: `Screen` / `Books` / `Music` / `Meals` / `Habits` / `Other`. The app's own four-section glyph set, from `Kati.Screens.Books.segment/4` | `movie` · `menu_book` · `graphic_eq` · `restaurant` · `bolt` · `label` |
| **Date** row | `spent_on`, a `:date`. 124 already draws this as a parse pill reading `Sun 16 Aug` | `calendar_today` |
| Quiet currency note | The currency is stored **per row**. Screen 125 changes the *display* currency and must not relabel a stored figure — `Kati.Money.Expense`'s moduledoc is explicit and the note is what stops a reader expecting this page to convert | `info` |
| **Delete expense** — outlined destructive bar | 31's bar again. `Kati.Money.Expense` has a plain `:destroy` and no tombstone column, so this one really removes the row | `delete` |
| Refusal line, above the commit | 124's contract: *a save that did not land does not close the sheet*, with the typed value still in the field | `error` |

**No categories, no budget, no chart on this page either.** 122's caption forbids all
three by name and `Kati.Money.Expense` reads it back:

> Screen 122's caption forbids them by name. What an expense has instead is a **section**
> — Screen, Books, Music, Meals — which is the classification the whole app already runs
> on … One taxonomy, reused, rather than a second one invented for money.

### 195 — the service catalogue

| Element | Purpose | Glyph |
|---|---|---|
| Chrome | Whichever 94 or 92 you pick — see *Left open*. If it is a modal, 94's `close` disc and centred title; if pushed, `‹ My services` | `close` / `arrow_back_ios_new` |
| Title + region line | `All services` over `47 in the United Kingdom`. **The 47 is JustWatch's count, not Kati's** — `Kati.Services.Sample.catalogue_count/0` says so in one line — so the region name and the count belong in the same sentence | `public` |
| **Search field**, a real one | 92's `search_field/1` is a `<TextField>` and 93's is a resting `Text`; this board is the populated one, so it is 92's. Placeholder `Search services` | `search` |
| Result row | Badge tile, name, and a **trailing state control** — the row's tier | — |
| **The tier control** | The one genuinely new control on these three boards, because 92 expresses tier as *group membership* and a flat catalogue cannot. 94's precedent is a `check` marking the current selection rather than a radio — but tier has **three** values, not two | `check` |
| Group heads | The same three 92 uses: `Subscribed · 3`, `Free with ads`, `Not mine` — or one flat list, if the tier control carries the state. Not both | — |
| *Something else* row | 92's `add` escape hatch, repeated here: a service JustWatch does not list is still a service you pay for, and the catalogue is where a person discovers it is missing | `add` |
| Availability note | 92's `info` sentence, unchanged: *Which service carries what comes from JustWatch, through TMDB. Both are credited on 83.* | `info` |

**195 is the first board in Kati whose content is fetched rather than stored, and both
failure states are already worded elsewhere.** No region set is 93's line — *Pick a
country first for an accurate list*. No provider list is 95's card, verbatim: `cloud_off`
over *Can't reach the provider list · Your saved services still show, and still toggle*.
Draw both; do not write new copy for either.

### The five edits, stated exactly

**122** — a `chevron_right` at 18px `#C4BDB3` outboard of the right-hand column on all
four Recurring rows and all six One-off rows. The Recurring rows carry a two-line trailing
column (price over rate), so the chevron sits outboard of that column, vertically centred
on the row — 92's *Subscriptions* row is the precedent for value-plus-chevron and should
be reproduced rather than reinterpreted. The paused row keeps its greyed treatment and
still gets a chevron; a service you are deciding about is precisely the one you tap.

**23** — the same chevron on the four Services rows. Nothing else on 23 changes. The
`more_horiz` disc is the **sibling ticket's** and must not be answered here.

**92** — the chevron on the three Subscribed rows and the two Free-with-ads rows, and the
*Show all 47* row annotated **`→ 195`**. Its price column is untouched by this ticket.

**93** — the *Show all 47* row annotated **`→ 195`**, with its own sub-line *Pick a
country first for an accurate list* intact. It is the same destination as 92's, and saying
so on both boards is the whole point of the edit: the code answers the identical tag two
different ways today and nothing can see it.

**126** — the outlined fact card (`check` · *Bought The Salt Almanac* · `RECORDED, NOT
SCHEDULED` · `£9.99`) gains an affordance opening **194**. This is the one card on 126
that is a stored row rather than a drawing. The renewal cards — the merged group, the
all-day Kino annual, the single 09:00 renewal — **do not** get one from this ticket; a
renewal on 126 is a calendar event, not a `Kati.Services.Service` row, and pointing it at
193 would be a claim the code cannot honour. Say that on the board so the next reader does
not "finish the job".

## States to draw

`Kati.ScreenEmptyDatabaseTest` renders every one of these screens against an empty
database and asserts the same literals `Kati.ScreenDesignLiteralTest` asserts against a
full one — 122, 92, 94 and 124 are all on its list already — so **an empty state nobody
drew is an empty state nobody tests**. Four matter here, and the empty ones are the point.

**Resting.** 193 on a fully-specified service — Orbit, £13.99, renews 24 Aug, £2.33/h in
red, not paused. 194 on a priced expense. 195 with the list fetched and three rows already
subscribed. A person arrives at all three to *change* something, so resting is the
populated case.

**Active.** 193's pause switch mid-state, with the paused row's greyed treatment and
*paused until October · not in the total* underneath — the two halves of the pause have to
be drawn together or the switch reads as cosmetic. 194's amount trough focused: 2px inset
ring, orange caret, 124's exact recipe. 195's search field mid-query.

**Empty — and there are four, all of them the common case.**

- **193 for a service with no price and no renewal date.** This is not an edge:
  `Kati.Screens.MyServices.create_service/1` writes `name`, `tier` and `provider_id` and
  nothing else, so **every service a user has ever added** arrives here with
  `monthly_pence: nil` and `renews_on: nil`. The mono subtitle has no halves, the hero has
  no figure and the *what is on it* note applies. Draw it.
- **193's rate at `—`.** 123's second band, which its own moduledoc calls the one the
  sheet exists for: a subscription with no watched hours is what every reader has in week
  one, and `Kati.Money.per_hour/2`'s first clause is `hours <= 0 -> "—"`. Never `£0.00`,
  never an infinity.
- **194 with no amount.** 124's whole subject — *an expense with no amount still counts as
  a thing that happened.* The hero is an em dash and the field is orange, and the board
  says saving is still allowed.
- **195 with no region and 195 with no match.** 93's sentence and 95's *No service called
  that · Kati uses JustWatch's list through TMDB. If it is a real service they do not
  track, add it as Something else.*

**Error.** 195's `cloud_off` card. 194's refused save, in `Kati.Write`'s shape: name what
failed, keep the sheet up, keep the typed value, put the sentence **directly above the
commit row** because an error further up a scrolling page can be off-screen at the moment
it appears — and **never disable the button**, since a dead button explains nothing. 193's
blank-name refusal takes the same shape.

## RTL — does this need a Persian mirror?

**No new Persian artboard is reserved by this ticket**, and that is a scoping decision
rather than an omission: state the rules on 193, 194 and 195 so the Fa siblings are a
redraw and not a redesign.

**But two existing Persian boards inherit the chevron edits, and the ticket does not list
them.** Board **97** (سرویس‌های من) is 92's mirror and already draws three `chevron_left`;
its Subscribed and Free rows need the same chevron 92's do. Board **127** (پول) is 122's
mirror, draws **no chevron at all**, and carries the same Recurring and One-off rows. Both
have to move with their LTR originals or the two locales disagree about which rows are
doors — flag this back rather than leaving it discovered later.

**What mirrors:** the container takes `dir="rtl"` and the whole grid mirrors — the badge
tile and its text swap sides, the trailing value column moves to the left, the chevron
becomes `chevron_left`, the field troughs and the tier control mirror. The `close` disc
and the Save pill swap ends of the header row. Dates go Shamsi and digits Persian.

**What does not:** **the vertical order never reverses** — badge, name, rate hero, price,
renews, tier, pause, cancel, in Persian exactly as in English. Provider names stay Latin;
97's own caption settles it — *provider names stay Latin, they are trade names, not copy*.
Figures keep DM Mono with Persian digits and the CLDR separators (decimal U+066B, group
U+066C) so the price and £/h columns still align under mirroring, and 127's caption says
so: *no ASCII comma or dot anywhere*. The currency word follows the figure per CLDR rather
than being hard-placed.

## Dark colourway

**Not needed as three more boards.** None of the five parents has a dark board either —
122, 23, 92, 93 and 126 exist in light only — so a dark 193 would be the only dark page in
the money section, and every surface these three boards use has a dark answer already
recorded on a board that has one:

- The **cream rate hero** is board 75's inset: *Cream warms to `#2A2622` with `#F7EFE4`
  text; cards lift on a hairline, not a shadow.*
- The **field troughs** on 193 and 194 are board 157's: `#2A2826` with a hairline rather
  than inverting to card colour, *so a field still reads as a hole rather than a raised
  surface. The orange caret is unchanged — it is the one accent on the screen in both
  themes.*
- The **outlined destructive bar** needs no decision at all: `Kati.Theme.Palette`'s
  `:red_ring` is `0x4DB4553C` in **both** columns, declared `:hue`. It is the same ring in
  either theme by construction.

If a dark board is drawn later it is 193, not all three, and it is a colourway of a page
rather than a fourth artboard number.

## Reuse, do not invent

- **The chrome** on 193 and 194 is **screen 31's**: `close` disc, centred title, ink Save
  pill, all in flow at the top of the scroll, frame closing at 40 because there is no dock.
- **The destructive bar** is 31's `delete/0`, prop for prop.
- **The badge tile** is 92's `badge_tile/1` — 40×40, radius 12, paper, letter at 15px/700.
- **The rate's colour verdict** is 122's `rate/1`: green / `#B4553C` / tertiary-for-em-dash.
  Do not introduce a fourth tone.
- **The row with a value and a chevron** is 92's *Subscriptions* row.
- **The cream card** is 122's hero and 123's four cards.
- **The orange-ringed amount trough** is 124's, unchanged.
- **The empty-ledger card** is 123's `nothing_set_up` — `payments` at 24px in a 52pt paper
  square, a 15px/700 line, a 12.5px sub-line — if 195 needs a nothing-fetched card.
- **The `cloud_off` and no-match cards** are 95's, verbatim.
- **The tick-not-radio** on 195 is 94's, whose caption gives the reason: *the tick marks
  the current selection rather than a radio control, matching how 35 marks per-show state.*
- **A chevron means *leads elsewhere*** — that is why 122, 23 and 126 have none today, and
  it is the entire content of three of the five edits.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not draw a price editor on 193 and call it done.** The editable monthly price screen
92's caption promises is **its own gap and its own ticket**, and 92 is where the design put
the ownership: *this screen owns these prices; 23 reads them — edit here, and cost per
watched hour follows.* `Kati.Screens.MyServices` states the blockage and names the ticket:

> It carries **no price**, and that is the honest half of the promise rather than an
> omission. Band 6 of the ticket asks for an editable monthly price and no artboard
> anywhere draws the editor … so a service typed in here appears in the Subscribed group
> with its name and a blank right-hand column.

193 **displays** `monthly_pence` and draws the nil case. Whether the field that sets it
lives on 92 or on 193 is the price ticket's decision, and 193's board should carry an
annotation saying which one it is waiting on rather than quietly answering it.

**Do not draw a *New subscription* button on 193, 195 or any of the edits.** The create
path is already drawn and already built — 92's *Something else* row. `Kati.Screens.MyServices`:

> `Something else` used to push screen 23, which is a read-only page about money you
> already spend — the one place in the app that could not answer "add a service Kati has
> never heard of". It writes now.

And `Kati.Screens.Subscriptions` says what a second one would cost:

> 23.html holds one `more_horiz` and no menu, sheet or popover anywhere in the export …
> so a *New subscription* sheet here would be a screen invented rather than built, which
> is the one thing 152 drawn artboards exist to make unnecessary.

**Do not answer either `more_horiz`.** 122's disc and 23's disc are the sibling ticket's
subject. 23's is already tagged `:open_menu` and already sits on
`Kati.ScreenTapSweepTest`'s Backlog list; 122's carries no `on_tap` at all. Putting a menu
behind either one here would settle a question two boards wide from inside a brief about
rows.

**Do not put a route argument on any of the three boards.** Only 7 of 62 screens read a
route argument and most detail screens open generically — that is a **code** defect, and
`Kati.Screens.EventDetail` is the fix already written for it:

> A detail screen that cannot be told what it is detailing is a detail screen about
> whatever the store hands back first.

`Kati.Screens.Money`'s own handler admits the same thing about the rows this ticket is
giving chevrons to:

> They open the screen the bare tag opened: `Kati.Screens.Subscriptions` takes no argument,
> so this is identity for the sake of being addressable rather than for routing.

The boards' job is to draw the door. Passing an id through it is `mount/3`'s.

**Do not draw a categories row, a budget or a chart on 194.** 122's caption forbids all
three by name, and `Kati.Money.Expense` holds a `section` instead. Six values, no seventh.

**Do not let 194 convert currencies.** `Kati.Money.Expense`:

> The currency is stored per row rather than read at render, because screen 125 changes the
> *display* currency and must not touch a stored figure. A row that read the current setting
> would silently relabel £8.99 as €8.99.

**Do not draw *Delete service* anywhere.** See 95's removed-service card. History that
references a service outlives it, and `:not_mine` is the tier that exists for precisely
that.

**Do not draw a hours-watched breakdown on 193.** The figure is not derivable and the
design says so at length. `Kati.Money`:

> `£0.21/h` needs a price **and** hours watched, which live in two different domains.

`Kati.Screens.Subscriptions` says why the second half is missing:

> `Kati.Media.Watch` records that an episode was watched — not for how long …  so hours
> per *service* would additionally need a provider→service mapping, which nothing holds
> either.

193 prints the same line 122 prints, from the same source. It must not imply a new
derivation exists behind it.

**Do not draw a *paused until* date picker without saying what stores it.**
`Kati.Services.Service` holds `paused` as a plain boolean and **no resume date column**.
123's *paused until October* is copy on a states sheet, not a stored value. Either the row
reads *Paused* and the month is dropped, or the board says a column is needed — but it
must not draw a date the schema cannot keep.

**The same is true of *cancelled 2 Jun*.** There is no `cancelled_on` anywhere in
`Kati.Services`. A cancel that moves the tier to `:not_mine` is expressible today; the
date beside it is not.

**Do not give 126's renewal cards a chevron.** See the 126 edit above.

**Do not make 195's rows push 193.** A catalogue row is a service you have not got; 193 is
a page about one you have. The tier control is the whole interaction on 195.

## Left open — decide and note which way you went

- **Whether pause and cancel live on 193 or in a header menu.** This is the decision that
  spans this ticket and its sibling. If they live behind 122's or 23's `more_horiz`, 193
  loses its two most important controls and becomes a read-only page — which is the state
  it is in today. If they live on 193, the sibling ticket's menus have less to carry. Pick
  one and say so on both boards; do not draw them in both places.
- **Whether correcting an expense is 194 or an inline edit on 124.** 124 already draws the
  section and the date as **parse pills** and the amount as an inline field, so the
  ingredients of an editor are on that board already — an *edit* mode of 124 is a real
  alternative to a new page, in the way board 118 is board 45 switched to one. If it goes
  that way, 194 becomes 124's second state rather than an artboard, and the ticket gives
  back a number.
- **Whether 195 is a pushed list or a modal like 94.** 94's caption argues the modal case
  for exactly this shape — *picking a country is one decision you come back from, not a
  place you navigate to* — but 47 rows with a search field and three-state controls is a
  list you work through, not a decision you make once. The back pill versus a grabber is
  the whole of the difference and it has to be drawn one way.
- **What 193's back chrome is.** Three parents push it (122, 23, 92 — five with 127 and
  97), and `Kati.Screens.Pushed` takes its label at compile time: `Keyword.fetch!(opts,
  :back)`, one string per module, so a back pill reading `‹ Money` lies to anyone who
  arrived from My services. 31's `close` disc sidesteps it entirely — `back: nil` is
  already supported and means *this board draws its own back control in the flow*. Draw
  one or the other; a `‹ Money` pill on a page reachable from three places is the one
  option that is wrong.
- **What 195's tier control looks like with three values.** A three-way segmented cell, a
  cycling tap, or a chevron into a small sheet. 94's tick answers a two-state question and
  does not translate.
- **Whether 193's rate hero is a cream card or a row.** 122 puts the account's total in a
  cream hero; whether one service's £/h earns the same weight is a judgement about what
  the page is for.
- **Whether 194's delete confirms.** `Kati.Money.Expense`'s `:destroy` is real, and the
  app's undo precedent is a transient bar (`undo` · *3 accounts disconnected* · **Undo**),
  not a dialog. Either is defensible; drawing neither is not.
- **Whether 92 and 93's *Show all 47* keeps its count in the title of 195.** The 47 is
  JustWatch's number for the UK and changes with the region; a title that hardcodes it is
  a title that will be wrong in Tehran.

## Acceptance — how we know the drawing is complete enough to build from

1. Every control on 193, 194 and 195 names a stored column or a destination on the board.
   `Kati.Services.Service` and `Kati.Money.Expense` between them hold every value 193 and
   194 write — a field on the board with no column behind it is a defect in the drawing,
   not a migration to write.
2. **Six** section values on 194, not four. Habits and Other are in, because the constraint
   list is `[:screen, :books, :music, :meals, :habits, :other]` and a board drawing four of
   six leaves two rows in the ledger that no page can classify.
3. The four empty states are drawn: 193 with no price and no renewal date, 193's rate at
   `—`, 194 with no amount, 195 with no region. An empty state that is not on a board is
   not asserted by `Kati.ScreenEmptyDatabaseTest`.
4. Both refusals are drawn with their sentence and with the button still live — the
   nameless service and the failed expense save.
5. `grep chevron_right test/design/screens/122.html 23.html` returns a hit per service row
   and per expense row, and `grep chevron_left 127.html 97.html` returns the mirrored set.
   The five edits are checkable by grep or they did not happen.
6. 92's *Show all 47* and 93's *Show all 47* name **the same** destination on both boards.
   That single agreement is what makes the current divergence — 92 to `MyServicesEmpty`,
   93 to `Subscriptions` — a bug somebody can see.
7. 126's board says, in words, that the renewal cards are **not** doors and why. The
   drawing is the only place that claim can live.
8. The destructive bar on 193 reads *Cancel*, sits over 123's hours sentence, and no board
   anywhere in the set draws *Delete service*.
9. 193's board states which ticket owns the price field, so
   `Kati.Screens.MyServices.create_service/1` can gain a price on the strength of a drawing
   rather than on the strength of a comment apologising for itself.

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
