# Missing drawings

> The pages Kati has built without a board, and the boards that now disagree
> with them. Written 7 September 2026 against `dev` at 172 built drawings,
> 86 delivered-and-unbuilt, and 2 receipts.
>
> **This file is the request.** Everything above the line marked *Section A* is
> context; Section A is what to draw and Section B is what to rule on.

## Read this first, because it changes what you are being asked for

**Nothing in `test/design/incoming/` needs redrawing.** Ninety-five artboards
arrived on 5 September. Eight have been built. **Eighty-six are still sitting
there unbuilt**, and they already answer a great many of the questions this
codebase has been asking. They are not a backlog of design work — they are a
backlog of *build* work, and they are mine.

Five of them were lost by the splitter and were recovered on 7 September:

| Board | What it is | How it was lost |
|---|---|---|
| **251** Doors for the stranded screens | `D-34`'s receipt — the eight parent-board edits | A 1180px sheet of plain `div`s with no `<x-import>` frame, so the frame-based splitter walked past it and captured **248's** frame instead. `251.html` was byte-identical to `248.html`. Now `test/design/reference/251.html`. |
| **302** One service | `D-62`'s first ask | The pass stopped at 301 |
| **303** Lending | `D-62`'s second ask | ditto |
| **304** What a prep is | `D-42` §3 — and screen 43's prepped card, `D-62`'s third ask | ditto |
| **305** §2 and §4 — decided, not drawn | `D-62`'s two declines | ditto |

That recovery closed three of the gaps that were about to be in Section A —
**the long-press collision** (251 rules it: *"A tile selects. A row rates."*),
**the eight stranded doors**, and **what a prep is** (304 rules it: per slot,
on `MealPlanSlot`, because it is the only answer needing no midnight job). They
are not asked for below.

The splitter now slices on the labelled element itself, counting that tag's own
opens and closes. Two checks now hold: no two files in `incoming/` share an
md5, and every `data-screen-label` at or above 167 in the export is on disk in
`incoming/`, `screens/` or `reference/`.

---

# Section A — the drawings that do not exist

**Twenty-one boards.** Each one is a page or a state that ships today with ink
nobody drew. They are ordered by the scope the app is being finished in:
**Movies and TV first**, because that is the only part being built right now,
then the pages that decide where a title can be watched, then the rest.

Every entry names the screen, what is on the device today, and what the board
has to settle. Where a delivered board already sets an idiom for the same
problem, it is named — the answer should not invent a second one.

## A1 · Movies and TV — twelve boards

### A1.1 — Screen 14, *Show details*, both halves at once

Board 14 draws a price row and a physical-ownership row. **Kati has no column
and no provider for either**, and board 203 has now explicitly declined to
answer for them: *"These are the watch's tags, not the title's: 14's
identical-looking control is a different column that does not exist."*

Below that, on a real series, 14 is now **a 270pt still, a title, one mono meta
line, a paragraph, and 1100pt of blank paper** — the seven bands under it are
dropped because Cast, Audience and Critics need a person resource and a score
cache that do not exist. `D-63` asked for this board and no board arrived.

**Draw:** 14 at rest carrying only what a `Kati.Media.CachedTitle` and the
reader's own columns can answer, with its own empty band. **248 is the shape** —
where 04's missing half is replaced by a claim card that says *why* it is
missing, rather than left as paper. Price and ownership are either given a
source or removed, and their absence stated the way **252** states its waiting
price field.

### A1.2 — Screen 06, the *Add a title* sheet before anything is typed

06 is the **+ FAB's default destination**: `Kati.Screens.Root` defines
`add_sheet/0` as `Kati.Screens.AddTitle` and only three of the eleven roots
override it (Books, Music, Calendar), so seven roots open this sheet — it is
the most reachable sheet in the app. Board 280 is its Persian mirror and draws
only the typed state: a query, four results, an add-by-hand row. **The idle sheet, the
in-flight sheet and the found-nothing sheet are drawn nowhere, in either
locale.** All three ship inferred.

**Draw:** one artboard, three bands — before a keystroke, while a query is in
flight, and a query that found nothing. Use **89's** `Nothing here for "…"`
card rather than a second wording, and say whether the add-by-hand row is
present in all three.

### A1.3 — Screen 88, a field that is refused and a field that is missing

88 is the page a reader opens to find out **why a search missed**, and it now
carries two different kinds of *no* with **one mark between them**.

*Not yet* — three of the seven scopes (`Music`, `Meals`, `Money`) have no group
behind them but will. *Never* — the fields in `@unkept`: `cast`, because TMDB's
credits are not fetched and `Kati.Media.CachedTitle` has no column for a
person, and `Kati.Books.Book.series`, which does not exist. The code's own
comment concedes the collapse in as many words: they draw *"in the same struck,
tertiary treatment `never invitee names` already had — one visual for named and
not doing this, whatever the reason."*

The mark carrying *not yet* at the scope level is itself undrawn ink: a 22pt
pill invented in `search_spec.ex` and then borrowed by screen 25, while screens
03 and 57 grey a `Kati.UI.chip/2` for the same fact. **Two marks for one
meaning, never drawn beside each other**, and one mark for two meanings on 88.

**Draw:** 88 with a mark for *deferred* and a mark for *withdrawn*, and a
sentence for each, in the idiom **187** uses for its greyed *NOT IN V1* barcode
row. Draw the *not yet* pill once beside 03's greyed chip, so those two can be
judged as one system.

### A1.4 — Screen 19, the results page with the field cleared

**261 has just made this state reachable without drawing it.** It adds a cancel
glyph to the field, and rules that the see-all page's field carries the query
with no caret. Nobody drew what happens when the glyph is tapped.

**Draw:** 19 immediately after the field is cleared. Does it become 87's idle
page? Do the chips survive? And what happens on the see-all page — whose only
way back to the other groups **is** those chips.

### A1.5 — Screen 86, the *Try* group with nothing to suggest from

86's Try group is derived entirely from the reader's library, so on day one it
has nothing. Nothing in the delivery draws it. The rule for an empty group is
now drawn three times elsewhere in this same wave (**259**, **260**, **271**:
the line is *worded*, never *counted*) and applied here nowhere.

**Draw:** 86 with an empty library — Try absent, or present-and-worded, which
is the choice **259** makes explicitly for its by-section card.

### A1.6 — Boards 19 and 91, the chip row at 235%

Three scope chips to a line, and at the largest type size they do not fit.
**277** is the only board in the wave that takes 235% as its subject, and it
states the rule the app claims about itself: *at the largest size rows become
columns, nothing truncates, cards get taller.* A chip row is a row that has to
become something else, and 91 draws it as a row.

This is also the one finding in the whole ledger that **Kati cannot fix in
Kati** — the bridge has no `FlowRow`, filed as
[mishka-group/kati#98](https://github.com/mishka-group/kati/issues/98). A
drawing that wraps needs a bridge change; a drawing that scrolls does not.
**That trade is the board's to make.**

**Draw:** 91's chip row at 235%, wrapped or scrolled, with the same treatment
applied to **261's** four counted chips and to its see-all row.

### A1.7 — Screen 07, a year with nothing counted

No board in the wave touches 07. **252** cites it in passing (cancelled hours
still count toward 07) and does not draw it. So the stats page's zero state is
inferred, and its *More numbers* row is missing the second line every other row
on the page carries.

A stats page at zero is the one place a plausible-looking zero does the most
damage — a reader cannot tell *nothing happened* from *nothing was counted*.

**Draw:** 07 at zero, and the *More numbers* row with its second line.

### A1.8 — Screens 25 and 05, releases beyond television

`D-30` has no boards in this delivery. **260** draws 05's empty state and
**298** mirrors 25 in Persian, and **neither carries a book, a record or a film
release.** The watcher's budget row is `:tv` and its own documentation says
that slice is films, books and records — with a UI that names only television.

The Books and Music shelves are real now. **A release inbox that can only speak
about episodes is the last place the app is still TV-only.**

**Draw:** 25's *Tell me about* rows and 05's groups for a book publication and
a record release, plus what 66 and 21 offer to follow.

### A1.9 — Screen 140, *five more sources* and the door behind it

Board 140 draws **Five more sources / Simkl · TV Time · Libib · Last.fm ·
AniList** — five claimed, five named. The code has since corrected the row to
**Four more sources** and dropped AniList, because AniList is not one of the
four the mapper reads. So the board and the screen now disagree about a
literal, which is the state the literal sweep exists to prevent.

And the chevron **opens a file picker with no source named** — it pushes the
manual column mapper with no file, so the one row naming four services opens a
column table about nothing. There is no screen listing four sources for it to
open, because none was ever drawn.

**278 is the Persian mirror and reproduces the older defect rather than either
fix** — «پنج منبع دیگر / سیمکل · تی‌وی‌تایم · لایبیب · لست‌اف‌ام», five claimed
and four named, carrying a chevron with no stated destination. Building 278
faithfully ships a count that was already wrong.

**Draw:** 140's summary row with a count that matches its own names in both
locales, and the screen behind its chevron — **or** the chevron removed the way
278 removed the one on «چیز دیگری», with a sentence saying why.

### A1.10 — Screen 141, the recognition sentence's six variants

141's job is one sentence: *what was recognised*. One shape is drawn. **Six
were written in a screen file** — mismatch bands, refusals, the possessive
form, the "said" form. It is the sentence a person reads immediately before
committing an import.

**Draw:** 141's recognition line in each of its six shapes on one artboard, in
**262's** four-panel idiom — same card, different facts.

### A1.11 — Boards 98 and 100, the two year-share card faces

102 carried **two card faces** 98 never previewed. They landed on **one** card,
under a heading nobody drew, and — until `dab876b` — without the wordmark board
100 requires (*"only the field card carries the wordmark"*). 102 has since been
retired to `test/design/retired/`, because it was read as a dark colourway of
98 and is not one: `Kati.Theme.Palette.mode/0` already draws 98 dark.

**This is the one artefact of the app that leaves the app** — it is shared as
an image — so an invented heading is invented ink in public.

**Draw:** the two faces as two artboards at their real sizes, with the
wordmark's placement and the heading's exact words, in the idiom 102 set.

### A1.12 — Screen 25's *checked 18:02*, and what *Manual* means

`checked 18:02` is a literal on a page that has no record of ever having
checked, and *Manual* — one of the four cadence segments — now really means
**never**, because nothing schedules a manual run. Small, and it sits on the
same page as A1.8, so it is cheapest drawn with it.

## A2 · Where a title can be watched — four boards

### A2.1 — Boards 80, 81 and 82, the token card and the pairing card

Three separate undrawn things on one page, and 80 is **the page every TMDB
failure message in the app points at** — so it is the screen a stuck reader is
sent to.

1. **The token card.** Board 80 draws two chips and the note *"Paste your own
   only if you want your own limits"* — and nothing to paste into. The app
   composes a lock tile, a `TextField`, a Save pill, a saved/error line, the
   instruction *"themoviedb.org → your account → Settings → API…"* and a
   no-secure-store fallback. **All of it written, none of it drawn** — and it
   showed. Until 7 September the field carried a Column's vertical `weight`
   where it needed a width, so it rendered at zero: no placeholder, no caret,
   no way to type, and the token stayed on screen after it was stored. The one
   card on this page a person has to use was unusable from the day it was
   written, and there was no drawing to check it against.
2. **The pairing card at rest.** 80 draws it only as *Enter this code / K4Q9B2
   / listenbrainz.org/link / Expires in 9:48* — never in the state every device
   is actually in: no code issued, no clock. Board 81 has seven specimens for
   this screen and that is not one of them. The typography built around a
   six-character code (34pt, centred, .14em) is now carrying a URL. The
   connected case is drawn as a **second row**, so a source appears twice.
3. **80 and 82 retired the same row two different ways**, so the English and
   Persian data-sources pages now disagree about what exists. This is the exact
   failure **254** flags for its own Persian pair: *"if the LTR rows become
   doors and the mirrors do not, the two locales disagree about which rows lead
   anywhere."* Here it has already happened.

**Draw:** the key card in three states — empty, saved, refused. The pairing card
as **states of one row** (unpaired, verifying, connected, refused) in **257's**
idiom, which already solves exactly this for calendar accounts. And one
retirement, drawn once in **114's** retired treatment and mirrored, with 82
showing the same set of rows 80 shows.

### A2.2 — Screen 93, are its switches live or a specimen?

The same three availability rules, on the same three columns, **remember on 92
and 97 and forget on 93** — deliberately, because 93's subject *is* the
un-set-up state and a switch that persists would take the page out of the state
it is drawing. Nothing on any board says which is right. **254** edits all three
boards in this wave and touches only chevrons and the catalogue destination.

**Draw:** a band on 93 saying whether its switches are live or specimen — and
if specimen, the mark that says so, which is the same undrawn mark A1.3 is
about.

### A2.3 — Screen 97, the Persian *My services* with nothing set up

**93 exists as a board precisely because the nothing-set-up state needed
drawing.** The Persian side has the same state and no board. **301** draws the
Persian country picker behind 97's کشور row, and **254** flags 97's rows for
chevrons; neither draws the page empty.

**Draw:** 97 with no country and no services, mirroring 93 — including whether
the rules group is drawn at all, which is the question 93's own build had to
answer alone.

### A2.4 — *Hide titles I can't watch*, one sentence, three claims

The consequence sentence names **two screens in English, three in Persian, and
three on the board**. 92's own caption says a rule carries its consequence in
words — so a rule that names a different number of screens depending on locale
is that sentence failing at its one job.

**Draw:** one sentence, counted from the screens the switch actually filters,
drawn once and mirrored. If the count genuinely differs by locale because a
Persian screen is missing, **that has to be said rather than absorbed.**

## A3 · Outside Movies and TV — five boards

These are not in the current build scope, but each is a page shipping invented
ink today, and each is cheap to draw next to the ones above.

### A3.1 — Screen 28, a dark Home with nothing kept

Inferred from the light one — on a palette where this wave has just found a
token that **does not survive the crossing**: 186 rules `#B4553C` is
byte-identical in both columns and needs `#E08A6E`. So dark is provably not a
mechanical transform of light for this palette, and an inferred dark empty is
exactly the assumption that just failed.

**Draw:** 28 with nothing kept, on the dark ground, with any token that does not
hold called out the way 186 calls out the destructive red.

### A3.2 — Screen 02, a schedule Kati is not allowed to read

**The state of every install on day one**, and of every install that declined
the prompt. 02 renders its sample when the permission is absent. **255's**
closing note is the nearest anything comes: *"calendars already on this phone
are not connected here — they arrive with the Android permission and land with
no account row at all."*

**Draw:** 02 with no calendar permission — what the week strip shows, what the
day shows, whether Kati's own events still draw, and the one control that asks.
Put 255's sentence where the reader is.

### A3.3 — Screen 55, the Persian empty Home

**The board already exists** — 158 — and the Persian root ignores it:
`Kati.Screens.HomeFa` renders its sample regardless, so a fresh Persian install
sees invented content on **the first screen it shows**.

**Nothing new is needed in ink.** What is wanted is the gate stated on a board
the way **260** states 05's: which read decides, and what 55 draws while it is
empty.

### A3.4 — Screen 112, medications and nothing due today

*"You have medications and nothing is due today"* was written in
`lib/kati/screens/medication.ex`. `D-43`'s three boards are built and none of
them draws this day — **which is the commonest day for anyone with a weekly
prescription.**

**Draw:** the has-medications-nothing-due band, keeping the eyebrow per `D-59`,
beside the true-empty state, so the literal sweep has both to compare against.

### A3.5 — Screens 50 and 120, the QR that says one thing and promises another

The QR encodes **settings only**. The card beneath it promises the whole plan —
all 35 meals. The person on the other end scans it, gets a plan with no meals,
and was told otherwise. **186** touches 50 only to take its header ⋯ off.

**Draw:** 50's card reworded to what the code actually encodes, or the encode
widened — either way, one board saying **which**, plus the receiving side on 120.

---

# Section B — the rulings, where two things already disagree

**Nineteen conflicts.** These need no new artboard: a delivered board and the
shipped code decide the same question differently, or **two delivered boards
decide it differently from each other.** Nothing here can be built until it is
ruled on, because building either side makes the other wrong.

They are marked **[MT]** where they block the Movies-and-TV scope.

## B1 · Two boards against one screen

| # | Conflict | What has to be chosen |
|---|---|---|
| B1.1 **[MT]** | **181 vs. the shipped Lists feature.** The code puts a red `Remove` pill in every row and a red `Delete this list` at the foot; 181 puts a `chevron_right` in the trailing slot and says outright *"No overflow disc — rename, share and delete are undrawn, and a disc with an undrawn menu is a new inert tap."* Row geometry differs too (38×54 r7 on a plate with a 2px border, vs 40×56 r9 bare), and 181's second line names the kind **in words with its own fact** — *Film · 2025*, *Book · Ines Karvel*, *Album · Kell Ostrand*. | Building 181 literally **deletes two destructive controls** — a behaviour change, not a restyle. Rule whether removal and deletion exist at all, and if they do, where. |
| B1.2 **[MT]** | **182 vs. the shipped add-to-list.** The code pushes screen 12 in an invented mode where every made row silently changes verb based on how the reader arrived. 182 makes it a **modal tick sheet over the page you are on**, pre-populated (*"a sheet that opens blank invites the duplicate the tick exists to prevent"*), committing on the tick with no Save, a failure putting the tick back off with the reason in words, and a 19×2 ink dash for a mixed selection. | The invented one-row-two-verbs mode has **no drawing at all**, and the sheet's failure path is the only place any board says what a refused membership write looks like. |
| B1.3 **[MT]** | **182 band 2 vs. `Kati.Screens.Lists`.** The code retired Wishlist and Owned as *"assertions the user makes and nothing stores"*. 182 draws them **live and tickable** and greys only Abandoned and Rewatches, with the second line *"Filled by what you do, not by a tick"* — splitting by whether a rule fills the list, not by whether Kati can store it. | Built as drawn this is **a schema change**. Left as built, 12 and 182 disagree about which kept lists accept a title. |
| B1.4 **[MT]** | **248/250 vs. screen 04's no-episode state.** The code renders a `0 of 0 watched` season strip, a card blaming search (*"a title added from search brings one with it"*), and the 50pt ink **Mark next watched** primary unconditionally. 248 forbids the primary outright — *"a primary that refuses is worse than none"* — replaces the season bar with a bronze `live_tv` claim card, and explains the actual cause. | 250 exists specifically to pin that **the hand-typed title and year survive the fill.** Nothing in the code says so. |
| B1.5 **[MT]** | **204 vs. screen 144.** `RateEpisode` draws its three context rows with **no chevron**, by written decision — *"the row with nothing to disclose, not a picker not yet wired"* — and that position shaped the whole `D-36` set. 204 overrules it: all three rows gain a `chevron_right`, with the `now` pill staying beside it as a shortcut. | Left alone, 201/202/203 are reachable from 33 and not from 144, and the two sheets differ for no visible reason. |
| B1.6 **[MT]** | **204's spoiler line vs. screen 33.** The code ships a two-state control so a reviewer can mark a twist (added under ledger #96). 204: *"It stays a label."* | The board **removes a control someone added for a real reason** and offers no replacement route. Settle before either is touched. |
| B1.7 **[MT]** | **254 vs. `MyServices.catalogue_line/1`.** The code deliberately killed *Show all 47*: *"Kati has no catalogue provider… 47 was the drawing's number and could never become anyone's."* 254 draws a whole searchable 47-row catalogue headed *IN THE UNITED KINGDOM · JUSTWATCH'S COUNT*, with a three-way Mine/Free/Not cell per row. | The board **reverses a deliberate deletion and assumes a provider source that does not exist.** (254 does correctly fix the divergence where 92's row pushed `MyServicesEmpty` and 93's identical row pushed `Subscriptions`.) |
| B1.8 **[MT]** | **261 vs. `Kati.Search.Query`, in both directions at once.** The code removed group truncation on purpose — the old `Enum.take/2` ran *before* `chip_counts/1` counted, so the chips lied. 261 restores the cap with a full-bleed *See all 3* row (`arrow_forward`, never a chevron). Meanwhile the code grew a **fifth chip (Books) and a fourth group heading**, and 261 draws four chips over three groups — 19's original set. | Building 261 literally **pins 19 back to four chips.** 261's own note flags a third mismatch: its back pill reads *Search* where `screens/19.html` draws *Home*. |
| B1.9 **[MT]** | **262 vs. screen 18.** `QuickAdd` files Reminder / Habit / Note straight onto `Kati.Calendars.Event.kind` with no intermediate page, and its Title chip pushes screen 06. 262 draws a **new confirmation screen behind all four chips** — the typed sentence with tokens tinted, a cream *Kati read that as* card, a commit label naming what will exist — and routes Title to **154** pre-filled, not 06. | Three kinds commit today with **nothing shown of what was parsed**, so a misparse is found on the calendar. 262's stated premise about `kind_tap/1` is also stale — whoever builds it will read the code against a description that no longer matches. |
| B1.10 **[MT]** | **271/259 vs. Home's bell.** `unread?/0` now answers `plan().armed != []`, which **includes the Later group**. The boards: *"The bell's dot counts the Now group only: a badge counting everything Kati will ever say is a number that never goes down"* — and at zero, no dot. `Kati.Notifications.Inbox.badge/1` already implements the board's rule and **is called by nothing.** | A show airing next Thursday puts a dot on the bell today. Both boards also still assert the dot is hardcoded, which is stale as of `0597fa6` — a builder trusting that premise will hunt a half-fixed defect. |
| B1.11 **[MT]** | **167 vs. `UpNext.tune_disc/0`.** The code shares **one** filter sheet with screen 03, with the reasoning written beside it: *"Up next narrows the same shelf, so a second sheet would be a second set of choices able to disagree with the first."* 167 draws a **separate instance** with its own sort card and buckets; 168 goes further and corrects 10's caption from *most finishable* to recency. | **One reader with one set of shelf choices, or one per host?** That is a store question, not a drawing question. 167's premise (`grep -c on_tap` = 0) is stale — the disc already works. |
| B1.12 **[MT]** | **169 vs. `Discover`'s tune panel.** The code toggles an invented in-flow panel headed *PICKS FROM* holding a seed chip per title — i.e. what the picks come **from**. 169 opens the generalised sort-and-filter sheet with Discover's own rails, and changes 11's header from *Tuned to 128 titles* to *4 of 8 · 90% and up* while a filter is on. | Structurally different — a modal sheet, not an in-flow panel. 169's premise (the disc is "a plain Box with no tag") is also stale. |
| B1.13 | **175 vs. `BookDetail`.** Finishing a book currently opens screen 33, **which asks which service you streamed it on.** 175 draws a *Log a read* sheet instead — a `replay` *2nd read* badge, Finished on / Read as / Re-reads, Save live at zero stars. | Two screens carry the handoff label, so it is two edits. |
| B1.14 | **208 vs. board 24.** 208 rules *"a settings-family header disc is a door, and a door is drawn only where the board names the room"* — so 24's help disc comes off, the pill goes 42 → 44 (*"24's 42 is the outlier and moves"*), the disc moves to the back-pill row, and the 13pt drop is fixed by `padding_top` 54 → 51 **in the shared pushed-screen helper**. | One number touches **every pushed screen in the app.** Worth one commit — screen by screen makes the 24-vs-62 locale divergence invisible again. |

## B2 · Two boards against each other

| # | Conflict | What has to be chosen |
|---|---|---|
| B2.1 | **186 vs. 196, on the same disc on the same screen.** 196 *"retroactively approves the existing panel on 02, 03, 04, 08 and 43"*. 186 retires it for meals: *"that panel ships on five screens and is drawn on none, and a meal menu is six rows with a photo identity row above it, which a 250pt anchored panel cannot carry"* — and separately rules a one-destination ⋯ becomes a labelled row. | 43 is **the only screen in the ratified five that the meals brief also claims.** Whichever is built, the other is wrong. |
| B2.2 | **271 vs. 258, on the notification budget.** The compile-checked Android table is calendar 150, tv 120, habits 80, meals 60, health 40, money 30. **258 draws the real table.** 271 draws *Screen 2 of 24 slots* — and 24 is in neither the Android nor the iOS column. The two also disagree about their own subtitle: 258 reads *3 TODAY · 2 HELD BACK* over **five** held rows; 271 reads *2 TODAY · 5 HELD BACK*. | The literal sweep can be pinned to **one**. Whichever wins, the 24 becomes 120 or the board asserts a cap the compile-time check rejects. |
| B2.3 | **194 vs. 300, on the Persian log-weight sheet.** 194 draws **three** unit segments — کیلوگرم / پوند / استون. 300 draws **two**, and rules why: *"stone is a British unit a Persian reader has no use for, and three full Persian words do not fit the trough."* 300 also declares itself the shared failure-inset reference for 296, 297 and 299. | The control that decides the trough's layout. 300 is the reasoned answer and 194 the earlier one. 194 also draws only **two of the three** change cases the brief named — the gain case is on neither. |
| B2.4 | **275 against 249, 273, 274, 276, 279 — and against board 62.** `kati_mono.ttf` contains **none of U+06F0–U+06F9**, so Persian digits cannot render in the mono face. 275 turns that into a ruling: *"anything the design set in mono is set here in Vazirmatn at the same size and colour, and columns stay aligned by DECLARED WIDTH."* It is the only `D-55` board with no DM Mono in it. **Five sibling boards set Persian digits in DM Mono anyway**, and board 62 — already in `screens/` — says the opposite outright. | Built literally, six boards **ship blank glyphs**. 275's rule should be applied to the other five *before* any of them moves. |
| B2.5 **[MT]** | **289 vs. 182, on what *Add to list* does.** 289 says the «افزودن به فهرست» buttons on 69 and 76 land on the Persian Lists **index**. 182 rules for English that it opens a **picker sheet over the page you are on**. | The two locales would teach **two different gestures for one action** — the failure 254 flags by name for its own Persian pair. 289 is the only Persian list board in the wave, so there is no Persian 181 or 182 to route to. |

---

## House rules these answers have to hold to

Carried from the previous waves, because each one has cost a round:

* **A board that moves into `test/design/screens/` is pinned by
  `Kati.ScreenDesignLiteralTest`** — every literal in it must render on the
  device, in both locales. A sentence drawn is a sentence the app must say.
* **A board in `screens/` with no module behind it turns the whole suite red.**
  That is why 86 boards sit in `incoming/`.
* **Each board needs one `max-width:380px` caption block.** The 5 September
  export carried none, and it caught all three agents that touched it.
* **A control with nothing behind it is dropped, not drawn dead.** An
  already-selected control keeps its tap. This is the rule the whole ledger was
  closed against.
* **Nothing is a mechanical transform of anything.** 186 found a destructive red
  that is byte-identical in both palette columns and needed a different value;
  275 found a mono face with no Persian digits. Mirrors and dark modes get
  drawn, not derived.
* **Do not redraw a board that exists.** The export's copies of 01–166 are
  *re-renders* and differ from the repo's — importing one moves a drawing the
  literal sweep is pinned to. Only 167+ was ever taken from it.
