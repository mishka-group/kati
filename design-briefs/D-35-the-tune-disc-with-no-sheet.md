# The tune disc with no sheet

> **Mixed — two new sheets and two board edits** · ticket `D-35`

One brief for two boards, because it is the same problem twice: a `tune` disc is drawn in
the header, and **the only filter sheet in the set refuses to be its destination**.

Board 145's own caption says so out loud — *one sheet for screens 03, 20 and 21 — three
sheets would end the "identical parts" claim within a release*. Naming three shelves is
also naming everything else, so Up next and Discover are **excluded on the record**, not
merely omitted. That is why they arrive here together and not in two tickets.

## The problem, stated plainly

A person on **Up next** has twelve episodes ready, four titles airing soon and three shows
that have gone cold, all on one scroller, and a `tune` disc at the top right of the board.
A person on **Discover** has four tabs, three picks, three people and two leaving rows,
"Tuned to 128 titles" underneath the title, and the same `tune` disc. Neither disc does
anything. `Kati.Screens.UpNext` draws it at `up_next.ex:358` and `grep -c on_tap
lib/kati/screens/up_next.ex` returns **0** — not one control on the screen its own
moduledoc calls *"the screen the whole app is for"* answers a tap. `Kati.Screens.Discover`
draws it at `discover.ex:195-204` as a plain `Box` with no tag at all, so it cannot even
reach `Kati.ScreenTapSweepTest`'s backlog; the only live tags on 11 are the chips
(`discover.ex:544`) and the Schedule pills (`:568`). Both screens have an obvious axis
nobody can reach — 10's own header counts `12 ready · 4 airing soon` against a `Gone cold ·
3` section, 11's counts `Tuned to 128 titles` across four tabs — and the sheet that would
reach them has ruled itself out in writing.

## The one decision that must be made before either sheet

**Is this 145 generalised, or two more sheets?** 145 is already drawn as *one instance* —
the Library one, where the fifth sort row prints Runtime because Books would print Pages
and Music would print Length — and `Kati.Screens.ShelfFilters` says its data is therefore
*"this file's data, not a shared one three screens reach into"*. Generalising means 167 and
168 are the fourth and fifth instances of that sheet: same chrome, same sort card, same
bucket rails, same footer, and only the buckets change with the host. Not generalising
means the "identical parts" claim the caption is defending dies here rather than in the
release it was worried about.

The sections below are written so either answer can be drawn from them: the **shape** is
identical on both artboards and only the **rails** differ. What cannot happen is one answer
on 167 and the other on 168.

## What to draw

| # | Artboard | What it carries |
|---|---|---|
| **167** | **Up next — sort & filter** | The sheet over screen 10, and — stacked below it on the same artboard, the way 146 stacks its three headers — the two states that cannot be a second sheet: the frame with nothing chosen, and a chip that would empty the screen |
| **168** | **Discover — sort & filter** | The same sheet over screen 11, with Discover's own rails. If the sheet is generalised, this is drawn and labelled as its **second instance**, as 145 is labelled the Library one |
| **edit 10** | Up next | The disc's active state, the mono line naming the filter, the hero under a filter, a section a filter emptied, and the whole screen a filter emptied |
| **edit 11** | Discover | The disc's active state, and what replaces `Tuned to 128 titles` while a filter is on |

Nothing here is a new screen number below 167, and neither host gets a Persian or a dark
twin — see the two sections on that below.

## Every element, and its glyph

Every glyph named here is already in `Kati.Icons`, which is the hard rule
`Kati.Screens.ShelfFilters` states for exactly this situation: *"`arrow_downward` is in
`Kati.Icons`; `arrow_upward` is not, and the hard rule is to grep before reaching for a
glyph, not to add one so a spec reads cleaner."* If the drawing needs one that is not
listed, name it in the export so `mix kati.gen.icons` can take it.

### 167 — Up next

| Element | Purpose | Glyph |
|---|---|---|
| Scrim + sheet + header | `Kati.UI.Sheet`, unchanged: `rgba(26,25,23,.42)` scrim, top-two-corners radius, `18px 21px 34px`, close disc · centred **Sort & filter** · a 36pt hole the same width as the disc | `close` |
| Eyebrow **Sort** | accent dash; the first rail | — |
| Sort row, chosen | the ink-tile row of 145's sort card | `check` |
| Sort rows, the rest | **Recently touched** · **Closest to finishing** · **Time left** · **Airing soonest**. All four are columns that already exist: `last_touched_at` (the order `:shelf` defines and the order 10 rests in), `progress_season`/`progress_episode`, `progress_seconds` against `runtime_minutes` — the same pair that prints `18M LEFT` — and `Kati.Media.Release.resolve/2` | `sort` |
| Direction pill | on the chosen row only, `DESC` in DM Mono 10.5 beside the arrow. ASC is the same glyph in a 180° box, per `direction_pill/1` | `arrow_downward` |
| Eyebrow **Ranges — buckets, not sliders** | quiet dash; 145's wording verbatim | — |
| **Time left** rail | `Under 30m` · `30–60m` · `Over an hour` · `No runtime`, each with a DM Mono count badge. The fourth is not padding: a cache row can be evicted, and `Kati.Screens.UpNext` renders that row `Untitled` rather than dropping it, so it has a position and no duration and must land somewhere nameable | — |
| **Where it is** rail | `Ready 12` · `Airing soon 4` · `Gone cold 3` — the screen's own three counts, taken off its own header and eyebrows | — |
| Footer card | `showing 6 of 15` in DM Mono 13, `Reset` at 12.5/600 in `#8A8479` | — |
| Dashed note | the claim this sheet has to make: **Airing soon is a date, not a window.** `Kati.Screens.UpNext` — *"'soon' is a date Kati is sure enough of to name"* — so a title whose release is a bare year is **not** in the bucket rather than counted as 1 January | `info` |

### 168 — Discover

| Element | Purpose | Glyph |
|---|---|---|
| Sheet chrome | identical to 167 | `close` |
| Sort rows | **Best match** · **Newest** · **Leaving soonest**; chosen row and direction pill as above | `check` / `sort` / `arrow_downward` |
| **Match** rail | `90% and up` · `80% and up` · `Unscored`, with counts — the same shape 145 gives its rating rail, against the `94% / 89% / 81%` the board already prints | — |
| **Kind** rail | `Film` · `Series`. `Kati.Media.TrackedTitle.kind` is real and is what `D-31`'s Kind segment writes | — |
| **Service** rail | `Lumen+ 5` · `Orbit 2` — the two services 145 already chips, counted against *this* feed, not the shelf's 22 and 7 | — |
| **People** chip | one chip, `Only with news` — the distinction the row already draws with an orange dot against a muted `check`, at rail scale | — |
| Footer card | `showing 4 of 8` + `Reset` | — |
| Dashed note | the claim this sheet has to make: **every count on this sheet comes from `Kati.Screens.Discover.Sample`**, as every number on screen 11 does. Say it on the board so the build is not asked to infer a recommender from a chip | `info` |

**168 must not chip the four tabs.** `For you / People / Leaving / Awards` is the default
surface; this sheet is the escalation over it, which is precisely how 145 divides the four
shelf tabs from itself.

### The edits to 10 and 11

| Element | Purpose | Glyph |
|---|---|---|
| Disc, resting | unchanged: 44pt, `#FBFAF8`, `Kati.Theme.shadow_button()` | `tune` |
| Disc, active | a filter is on. Ink-filled, per the chip pair below | `tune` |
| 10's mono line | today `12 ready · 4 airing soon`; under a filter it names the filter — `6 of 15 · under 30m`. The **rule** is 146's (*"A silent persistent sort is the confusing option; a named one is not"*); the **typography** stays 10's own sentence case at DM Mono 11 `#A9A29A`, not 146's uppercase, because this is 10's line | — |
| 11's mono line | `Tuned to 128 titles` is the corpus, not a result count, so a filter **replaces** it rather than editing it: `4 of 8 · 90% and up`. It comes back untouched at Reset | — |
| An emptied section | the eyebrow goes with the rows. `Kati.Screens.Activity` already settled this for the same gesture: *"A filter that leaves a dated group with no rows takes the group's eyebrow with it … a headed card with no rows inside it is a worse answer than no card"* | — |
| An emptied screen | 147's zero-result recipe at 100%: the glyph, **Nothing matches**, the sentence that names the culprit chip, and the pill that drops it. 147 draws it as a whole board only because it is at 235%; here it is a band | `search` |

## States to draw

Kati compares an undrawn state against nothing, so an undrawn state is an untested one.
Four matter, and only two of them need new pixels on the sheets themselves.

- **Resting.** 167 and 168 with nothing chosen, footer reading the whole count. This is the
  frame the sheet actually opens in for a new user, and it is the one 145 does *not* have —
  145 opens already filtered, which is why its own moduledoc has to explain that `41` is
  illustrative. Draw the clean frame first and the filtered frame under it.
- **Active.** Chips selected, footer narrowed, the disc filled on 10 and 11, the mono line
  naming the filter. This is the state the two board edits exist for.
- **Empty.** Two different empties and both are needed. *(a)* A chip whose count is `0` —
  drawn selectable, in 145's hairline grey, so the chip says it would empty the screen
  **before** it is tapped. *(b)* The screen after it was tapped anyway: 147's `search` +
  **Nothing matches** + the named culprit + **Drop the X chip**. Up next has no drawn empty
  state anywhere in the set, so this band is also the only artboard
  `Kati.ScreenEmptyDatabaseTest` will ever have to compare a filtered Up next against.
- **Error.** A **stale filter** — a bucket that was chosen, persisted, and no longer exists
  when the screen comes back: the service is gone, or the row that had `No runtime` got its
  cache back. The screen must not silently drop it and must not show an empty list with no
  explanation. Draw it as a band on the 10 edit; 168 inherits the same treatment.

## RTL

**No Persian artboard.** There is no `UpNextFa` and no `DiscoverFa` — the Persian set is
55–62 plus the named twins, and neither host has one — and 145 has no Persian twin either,
so asking for one here would be the first sheet in the app to get one.

What mirrors under the house rule, stated so nobody has to guess: the sheet's header
mirrors, so the close disc moves to the right and the 36pt hole to the left, and the title
stays centred **in the sheet** rather than in what is left beside the disc. Rails mirror and
run right to left. The direction pill mirrors as a unit; `arrow_downward` points down in
both directions and does not flip. The back pill's glyph becomes `arrow_forward_ios`. The
**vertical order never reverses** — Sort is still above Ranges above Filters above the
footer. Posters, stills and faces never mirror. Counts and the `showing … of …` line go
Persian digits in DM Mono so the columns still align.

## Dark colourway

**No dark artboard, and one dark value that does need drawing.**

Only 28, 68, 102, 131, 157 and 159 are drawn dark, and neither host is among them. Almost
everything here already has a dark answer: a selected chip takes `ink_fill` under `on_ink`,
which screen 28 draws — `#1A1917` + `#FBFAF8` becomes `#F7EFE4` + `#1A1917`, the fill
inverting rather than following the ground — and the active `tune` disc takes exactly that
pair, so it stays a lifted control rather than sinking into `#121110`.

The exception is the one this brief introduces by reusing it. The **0-count badge** —
145's fourth chip colour, the hairline grey that warns before the tap — is a literal with
no token, and `Kati.UI.chip/2` says so in the file: *"`0xFFB5AEA3` is not in
`Kati.Theme.Palette` … It stays light-grey in dark, which is wrong and visible; it needs a
token, not a guess."* A guess is what a designer is for. Name the dark value for that badge
in the export and the token can be added rather than invented.

## Reuse, do not invent

Every part of both sheets already exists somewhere:

- **The sheet** — `Kati.UI.Sheet`: scrim, top-two-corners radius, `18px 21px 34px`, close
  disc · centred title · 36pt hole.
- **The sort card** — 145's `SettingsList`: `check` on the chosen row, `sort` on the rest,
  a trailing direction pill on the chosen one only.
- **The rails** — 145's chip buckets with DM Mono count badges, including the hairline-grey
  zero.
- **The footer** — 145's card: mono `showing … of …` on the left, `Reset` on the right.
- **The dashed note** — 145's and 146's: `info` glyph, 1.5px dashed `rgba(26,25,23,.16)`,
  18pt radius.
- **The zero-result band** — 147's, verbatim, at 100%.
- **The header line under a filter** — 146's rule, 10's and 11's own typography.
- **The disc** — 10's own, which is already `Kati.Components.MishkaActionIcon` with
  `Kati.Theme.shadow_button()` passed through untouched.

## What it must NOT do

Decisions the codebase has already made, each with the sentence that made it.

**No slider, on either sheet.** `Kati.Screens.ShelfFilters`: *"the component table has no
slider, and a bucket carries a count while a slider cannot."* Time left is three buckets and
a fourth for unknown, not a two-handle range.

**No formula behind the footer count.** The same file, on 145's own `41`: *"it is the
drawing's own illustrative number for the state as drawn. Inventing a formula that
reverse-engineers 41 would state a false premise about how the numbers relate."* `6 of 15`
and `4 of 8` above are illustrative in exactly the same way. Say so on the board.

**No `Archived` bucket on 167.** `Kati.Screens.UpNext`: *"`archived` rows are excluded
because that flag's whole meaning is hides from shelf."* A filter that could bring them back
would make the flag mean two things.

**No "next 7 days" bucket.** The same file: *"No window in days is chosen here: 'soon' is a
date Kati is sure enough of to name."* The bucket is `Airing soon`, and its membership is
`Kati.Media.Release.resolve/2` answering `:exact` or `:day`.

**No episode name anywhere on 10, including in a filter summary.** *"adding a name here
would widen a `max_lines={1}` line that is already close to the play disc … So this stays a
pair of numbers, and the episode name is screen 04's."*

**No half-fallback on the filtered Up next.** *"The fallback is all-or-nothing on purpose: a
real hero over the drawing's ready list would be four titles the user does not have."* Draw
the filtered screen as one thing, not as a real hero over drawn rows.

**No person filter that implies a person.** `Kati.Screens.Discover` quotes
`Kati.Media.Watch.companions`: *"Kati has no people table and no contacts permission, and
inventing either to hold the word 'Jo' would be a larger privacy decision than the feature
is asking for."* `Only with news` filters rows the sample already carries. It is not a
follow list, and **no person board belongs in this ticket** — that is a separate decision
about whether Kati has people at all.

**No fixing Awards from the sheet.** *"'Awards' names a section this feed does not carry, so
it empties the screen rather than relabelling one of the others as awards."* The sheet must
not quietly hide the tab or repoint it.

**No Apply, Show-N or Done on 167 or 168.** 145 ends at `Reset` and a `close`, and
`shelf_filters.ex:329` pops. Whether a filter travels back to its host is an open question
on **145** and is not this brief's to answer — but inventing a commit control here would
give the app two different filter models before it has one that works.

**A pick on 11 opening the title it shows is not a design gap.** Only 7 of 62 screens read a
route argument; a poster that opens the wrong page is a code defect. Do not draw a board
for it.

## Where screen 15 goes

The same `tune` disc is drawn on **15 (Activity)** with the same nothing behind it —
`{Kati.Screens.Activity, :open_filters}` sits on `Kati.ScreenTapSweepTest`'s backlog at
`screen_tap_sweep_test.exs:693`. It is outside this area and is not drawn here, and the
answer is recorded now so a third sheet is not invented later:

**15 is a host of this sheet, not a fourth sheet.** Its four tabs are the default surface
and its escalation is a date range and a verb, which is the same two-rail shape. If the
generalised answer is taken above, 15 becomes an instance of it in its own ticket. If the
per-screen answer is taken, 15's disc gets **removed from the board** rather than given a
sheet of its own — an undrawn control is a smaller defect than a fourth copy of one sheet.

## Left open — decide and note which way you went

- **Generalised or per-screen**, first, and before either artboard is finished. Everything
  else on this page is drawable under either answer; the two answers cannot be mixed.
- **Which sort 10 actually rests in.** The board's caption says *"ordered by what is most
  finishable"*; `Kati.Screens.UpNext` orders by `last_touched_at` descending because that is
  *"the order the `:shelf` action itself defines"*. The sheet lists both. Which one carries
  the `check` on first open decides which of the two is the screen's real promise.
- **Does the hero follow the filter?** The hero is the first ready row *"rather than a
  separate query, so 'what you are closest to' cannot disagree with the list under it"*. A
  filter that removes it either promotes the next filtered row to hero or leaves the hero
  pinned and unfiltered. Draw whichever you choose; the other is a defect either way.
- **Does a filter persist the way sort does?** 146 says sort persists between visits and is
  named on the resting header. It says nothing about filters. If they persist, the stale
  band above is a real state; if they do not, it is not, and the mono line only ever names a
  filter within a session.
- **Whether Reset clears the sort too.** 145's does — *"a reset that put you back in a
  different filtered state would not be a reset"* — but 145's sort is the persisted thing,
  and clearing a persisted sort from a filter sheet may be one control doing two jobs.

## Acceptance — how we know it is complete enough to build from

- Both artboards carry every literal a build would need to reproduce them: each sort row's
  label, each chip's label **and its count badge**, the footer's `showing … of …`, `Reset`,
  and the dashed note's full sentence. `Kati.ScreenDesignLiteralTest` asserts every one of
  these against the rendered tree, so a label that only exists in this brief is a label the
  screen cannot be built to.
- Every glyph on both boards is a name in `Kati.Icons`, or is called out in the export as a
  new one for `mix kati.gen.icons`.
- The **zero-result band** is drawn on both 10 and 11, not described. Without it there is
  nothing for a filtered empty state to be compared against, and Kati's rule is that an
  undrawn state is an untested one.
- Both header edits are drawn in **both** states — resting and filtered — on the same
  board, so the difference is a diff rather than a description.
- The 0-count badge has a named dark value.
- Each of the five items in *Left open* has an answer written on the board it lands on, in a
  dashed note or a cream note, the way 145 and 146 record theirs.
- Nothing on either board implies a recommender, a person, a service catalogue or a player.
  If a chip cannot be traced to a column in `Kati.Media` or to a field in the host screen's
  Sample, it does not ship.

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
