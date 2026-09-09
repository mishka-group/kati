# Kati — boards wanted, 7 September 2026

Nineteen screens and eight Lists amendments, ordered by screen number. Each
says what is on the device today, what to draw, and which delivered board
already sets the idiom — please reuse it rather than inventing a second one.

**Do not redraw anything in `test/design/incoming/`.** Ninety-five boards
arrived on 5 September; eighty-six are still unbuilt and are a build backlog,
not a design one. Boards 251 and 302–305 were recovered on 7 September after
the splitter missed them — 251 is `D-34`'s doors receipt, and 302/303/304/305
are `D-62`'s asks. They are not wanted again.

**House rules.** A board that ships into `screens/` is pinned by a literal
sweep: every string on it must render on the device, in both locales. A control
with nothing behind it is dropped, not drawn dead; an already-selected control
keeps its tap. Nothing is a mechanical transform of anything — dark modes and
RTL mirrors get drawn, not derived (186 found a destructive red that is
identical in both palette columns and needed a different value; 275 found a
mono face with no Persian digits). Each board needs one `max-width:380px`
caption block.

---

## 02 — A schedule Kati is not allowed to read

**Today:** screen 02 renders its sample when the calendar permission is absent,
so the state of every install on day one — and of every install that declined
the prompt — is invisible.

**Draw:** 02 with no calendar permission. What the week strip shows, what the
day shows, whether Kati's own events still draw, and the one control that asks.
255's closing note already words it — *"calendars already on this phone are not
connected here — they arrive with the Android permission and land with no
account row at all"* — put it where the reader is.

## 05 + 25 — Releases beyond television

**Today:** the release watcher's budget row is `:tv` and its own documentation
says that slice is films, books and records. The UI names only television. The
Books and Music shelves are real now, so a release inbox that can only speak
about episodes is the last place the app is still TV-only. `D-30` has no boards.
260 draws 05's empty state and 298 mirrors 25 in Persian; neither carries a
book, a record or a film release.

**Draw:** 25's *Tell me about* rows and 05's groups for a book publication and
a record release, plus what 66 and 21 offer to follow.

## 06 — The *Add a title* sheet before anything is typed

**Today:** 06 is the + FAB's default destination — seven of the eleven roots
open it, so it is the most reachable sheet in the app. Board 280 is its Persian
mirror and draws only the typed state: a query, four results, an add-by-hand
row. The idle sheet, the in-flight sheet and the found-nothing sheet are drawn
nowhere, in either locale, and all three ship inferred.

**Draw:** one artboard, three bands — before a keystroke, while a query is in
flight, and a query that found nothing. Use 89's `Nothing here for "…"` card
rather than a second wording, and say whether the add-by-hand row is present in
all three.

## 07 — A year with nothing counted

**Today:** no board touches 07. Its zero state and its *More numbers* row —
which is missing the second line every other row on the page carries — are both
inferred. A stats page at zero is where a plausible-looking zero does the most
damage: a reader cannot tell *nothing happened* from *nothing was counted*. The
rule is drawn three times elsewhere (259, 260, 271: the line is **worded**,
never **counted**) and applied here nowhere.

**Draw:** 07 at zero, and the *More numbers* row with its second line.

## 13 + 92 + 97 — *Hide titles I can't watch*, one sentence, three claims

**Today:** the consequence sentence under this switch names **two** screens in
English, **three** in Persian, and **three** on the board. 92's own caption says
a rule carries its consequence in words, so a rule that names a different number
of screens depending on locale is that sentence failing at its one job. 254
edits 92, 93 and 97 in this wave and touches only chevrons and the catalogue
destination.

**Draw:** one sentence, counted from the screens the switch actually filters,
drawn once and mirrored. If the count genuinely differs by locale because a
Persian screen is missing, say that rather than absorb it.

## 14 — *Show details*, both halves at once

**Today, two problems on one page.** Board 14 draws a price row and a
physical-ownership row; Kati has no column and no provider for either, and
board 203 has now explicitly declined to answer for them — *"These are the
watch's tags, not the title's: 14's identical-looking control is a different
column that does not exist."*

And on a real series the page is a 270pt still, a title, one mono meta line, a
paragraph, a two-row *Where to watch* card — then **40% of the page is empty
paper**. Cast, Audience, Critics and the reader's tags all fell away because
they need a person resource and a score cache that do not exist. `D-63` asked
for this board and none arrived.

**Draw:** 14 at rest carrying only what a cached title and the reader's own
columns can answer, with its own empty band. **248 is the shape** — where 04's
missing half is replaced by a claim card that says *why* it is missing, rather
than left as paper. Price and ownership are either given a source or removed,
their absence stated the way 252 states its waiting price field.

## 19 + 91 — The results page with the field cleared, and the chip row at 235%

**Two asks on the search results page.**

**The cleared field.** 261 adds a cancel glyph to the field it draws and rules
that the see-all page's field carries the query with no caret — so the wave has
just made this state reachable without drawing it. Draw 19 immediately after
the ✕ is pressed: does it become 87's idle page? Do the chips survive? What
happens on the see-all page, whose only way back to the other groups **is** those
chips?

**235%.** Three scope chips to a line, and at the largest type size they
overflow. 277 states the rule the app claims about itself — *at the largest size
rows become columns, nothing truncates, cards get taller* — and a chip row is a
row that has to become something else. Note this is also the one finding the app
cannot fix in code: the bridge has no `FlowRow`, filed upstream as
mishka-group/kati#98. **A drawing that wraps needs a bridge change; a drawing
that scrolls does not — that trade is yours to make.** Apply the same treatment
to 261's four counted chips and its see-all row.

## 25 — *checked 18:02*, and what *Manual* means

**Today:** `checked 18:02` is a literal on a page with no record of ever having
checked, and *Manual* — one of four cadence segments — now really means
**never**, because nothing schedules a manual run. Small, and it sits on the
same page as the 05+25 ask above, so it is cheapest drawn with it.

## 28 — A dark Home with nothing kept

**Today:** inferred from the light one — on a palette where this wave has just
found a token that does not survive the crossing: 186 rules `#B4553C` is
byte-identical in both columns and needs `#E08A6E`. Dark is provably not a
mechanical transform of light here, so an inferred dark empty is exactly the
assumption that just failed.

**Draw:** 28 with nothing kept, on the dark ground, with any token that does not
hold called out the way 186 calls out the destructive red.

## 50 + 120 — The QR that says one thing and promises another

**Today:** the QR encodes **settings only**. The card beneath it promises the
whole plan — all 35 meals. The person on the other end scans it, gets a plan
with no meals, and was told otherwise. 186 touches 50 only to take its header ⋯
off.

**Draw:** 50's card reworded to what the code actually encodes, **or** the
encode widened — either way, one board saying which, plus the receiving side on
120.

## 55 — The Persian empty Home

**Today:** the board already exists — 158 — and the Persian root ignores it:
`HomeFa` renders its sample regardless, so a fresh Persian install sees invented
content on the first screen it shows.

**Nothing new is needed in ink.** What is wanted is the gate stated on a board
the way 260 states 05's: which read decides, and what 55 draws while it is empty.

## 80 + 81 + 82 — The token card, the pairing card, and one retirement

80 is **the page every TMDB failure message in the app points at**, so it is the
screen a stuck reader is sent to. Three undrawn things on it.

1. **The token card.** Board 80 draws two chips and the note *"Paste your own
   only if you want your own limits"* — and nothing to paste into. The app
   composes a lock tile, a text field, a Save pill, a saved/error line, the
   instruction *"themoviedb.org → your account → Settings → API. Copy the read
   access token."* and a no-secure-store fallback. All written, none drawn — and
   it showed: until 7 September the field laid out at zero width, so there was
   no placeholder, no caret and no way to type at all. **Draw it in three
   states: empty, saved, refused.**
2. **The pairing card at rest.** 80 draws it only as *Enter this code / K4Q9B2 /
   listenbrainz.org/link / Expires in 9:48* — never in the state every device is
   actually in: no code issued, no clock. Board 81 has seven specimens for this
   screen and that is not one of them. The typography built around a
   six-character code (34pt, centred, .14em) is now carrying a URL, and the
   connected case is drawn as a **second row**, so a source appears twice.
   **Draw the pairing card as states of one row — unpaired, verifying,
   connected, refused — in 257's idiom, which already solves exactly this for
   calendar accounts.**
3. **80 and 82 retired the same row two different ways**, so the English and
   Persian pages now disagree about what exists. This is the exact failure 254
   flags for its own Persian pair: *"if the LTR rows become doors and the mirrors
   do not, the two locales disagree about which rows lead anywhere."* **Draw one
   retirement, once, in 114's retired treatment, mirrored — with 82 showing the
   same set of rows 80 shows.**

## 86 — The *Try* group with nothing to suggest from

**Today:** 86's Try group is derived entirely from the reader's library, so on
day one it has nothing, and nothing draws it. The rule for an empty group is
drawn three times in this same wave (259, 260, 271) and applied here nowhere.

**Draw:** 86 with an empty library — Try absent, or present-and-worded, which is
the choice 259 makes explicitly for its by-section card.

## 88 — A field that is refused and a field that is missing

**Today:** 88 is the page a reader opens to find out **why a search missed**, and
it carries two different kinds of *no* with **one mark between them**.

*Not yet* — three scopes (Music, Meals, Money) have no group behind them but
will. *Never* — `cast`, because credits are not fetched and there is no column
for a person, and a book's `series`, which does not exist. The code's own
comment concedes the collapse: they draw *"in the same struck, tertiary
treatment `never invitee names` already had — one visual for named and not doing
this, whatever the reason."*

The mark carrying *not yet* at scope level is itself undrawn ink — a 22pt pill
invented in code and borrowed by screen 25, while screens 03 and 57 grey a chip
for the same fact. Two marks for one meaning, never drawn beside each other; one
mark for two meanings on 88.

**Draw:** 88 with a mark for *deferred* and a mark for *withdrawn*, a sentence
for each, in the idiom 187 uses for its greyed *NOT IN V1* barcode row. And draw
the *not yet* pill once beside 03's greyed chip so the two can be judged as one
system.

## 93 — Are its switches live, or a specimen?

**Today:** the same three availability rules, on the same three columns,
**remember on 92 and 97 and forget on 93** — deliberately, because 93's subject
*is* the un-set-up state and a switch that persists would take the page out of
the state it is drawing. Nothing on any board says which is right.

**Draw:** a band on 93 saying whether its switches are live or specimen — and if
specimen, the mark that says so, which is the same undrawn mark 88 needs.

## 97 — The Persian *My services* with nothing set up

**Today:** 93 exists as a board precisely because the nothing-set-up state needed
drawing. The Persian side has the same state and no board. 301 draws the Persian
country picker behind 97's کشور row and 254 flags 97's rows for chevrons;
neither draws the page empty.

**Draw:** 97 with no country and no services, mirroring 93 — including whether
the rules group is drawn at all, which is the question 93's own build had to
answer alone.

## 98 + 100 — The two year-share card faces

**Today:** board 102 carried **two card faces** 98 never previewed. They landed
on **one** card, under a heading nobody drew, and until 7 September without the
wordmark board 100 requires (*"only the field card carries the wordmark"*). 102
has since been retired — it was read as a dark colourway of 98 and is not one;
the palette already draws 98 dark on a dark device.

This is the one artefact of the app that **leaves** the app — it is shared as an
image — so an invented heading is invented ink in public.

**Draw:** the two faces as two artboards at their real sizes, with the wordmark's
placement and the heading's exact words, in the idiom 102 set.

## 112 — Medications, and nothing due today

**Today:** *"You have medications and nothing is due today"* was written in a
screen file. `D-43`'s three boards are built and none draws this day — which is
the commonest day for anyone with a weekly prescription.

**Draw:** the has-medications-nothing-due band, keeping the eyebrow per `D-59`,
beside the true-empty state, so the sweep has both to compare against.

## 140 — *Five more sources*, and the door behind it

**Today:** board 140 draws **Five more sources / Simkl · TV Time · Libib ·
Last.fm · AniList**. The code has since corrected the row to **Four more
sources** and dropped AniList, because AniList is not one of the four the mapper
reads — so board and screen now disagree about a literal, which is the state the
sweep exists to prevent.

And the chevron **opens a file picker with no source named** — it pushes the
manual column mapper with no file, so the one row naming four services opens a
column table about nothing. No screen listing four sources was ever drawn.

278 is the Persian mirror and reproduces the older defect rather than either
fix — «پنج منبع دیگر / سیمکل · تی‌وی‌تایم · لایبیب · لست‌اف‌ام», five claimed
and four named, carrying a chevron with no stated destination.

**Draw:** the summary row with a count that matches its own names in both
locales, and the screen behind its chevron — **or** the chevron removed the way
278 removed the one on «چیز دیگری», with a sentence saying why.

## 141 — The recognition sentence's six variants

**Today:** 141's job is one sentence — *what was recognised*. One shape is drawn.
**Six were written in a screen file**: mismatch bands, refusals, the possessive
form, the "said" form. It is the sentence a person reads immediately before
committing an import.

**Draw:** 141's recognition line in each of its six shapes on one artboard, in
262's four-panel idiom — same card, different facts.

---

# Lists — what 181 and 182 left, and two Persian mirrors

**Both boards arrived and are right; nothing here asks you to redraw them.** A
sweep of the two boards against the shipped screens found **twenty-four things
neither board draws**, fourteen of them reachable in the app today. They group
into six amendments and two new mirrors.

**Two rulings, made 7 September:**

1. **A list can be deleted, and a title can be removed from one.** 181 says
   *"No overflow disc — rename, share and delete are undrawn, and a disc with an
   undrawn menu is a new inert tap."* That was right with nothing decided. It is
   decided now: both controls exist.
2. **A list holds films, series, books and albums.** 182's mixed card is
   ratified and the schema follows — today `list_memberships.tracked_title_id`
   is a hard foreign key to one table, so a book cannot be in a list at all.
   Board 12's caption already promised it: *"The same shell will hold book and
   album lists."*

**Why this is urgent rather than tidy.** There are **seven** *Add to list*
controls, on six screens, and **one** of them adds anything. Screen 146's passes
a selection; 66, 68, 74 and 76 push the Lists index carrying nothing, so the
title is never mentioned again; 147's has no tap; and screen 69's — the Persian
book page — has no handler at all, so nothing pushes and nothing is written.

## L1 — 181: the destructive half

**Draw:** removing a title from a list, and deleting a list. Where each control
lives (181 gives the row's trailing slot to a `chevron_right`, and the ranked
row's to a `drag_indicator` — there is no third mark, no swipe, no edit mode),
and what confirmation each takes.

**And undo.** Board 146 draws `Removed 4 titles · Undo` and it ships. Today the
app offers undo for pulling a title off a shelf and nothing for destroying a
whole list, whose memberships cascade. **269** is the app's confirmation recipe
but is scoped to 267, 268 and 80; **253's** undo bar is scoped to an expense.
Widen one, or say why a list needs its own.

Please also rule on **rename** — the third thing 181 named as undrawn, and the
only one still open.

## L2 — 181: the states it did not draw

Six, all reachable:

* **The absent list, which is not the empty list.** `Shelf.detail/1` answers
  `nil` and the code draws a distinct page — *"No list here"*, a card, a *Your
  lists* pill. Reachable from a list deleted on another device, or a stale id
  after a delete. 181 drew *empty* and never *gone*, and the code is explicit
  they are different facts.
* **The empty made list with its name.** 181's band 2 draws `0 TITLES` and **no
  title, no header** — while calling it "the common case". The screen draws the
  name and the count.
* **The empty kept list.** `Abandoned · 0` ships on every fresh install. The
  only drawn empty card belongs to a *made* list and reads *"Open a film, book
  or album and tap Add to list"* — which is a lie on a shelf you cannot add to.
* **A row with no artwork**, for a title whose cache was evicted or never had a
  poster. 181's only art-less row is the album's `T / ART` **kind** placeholder.
* **A title with no metadata** — the code falls back to `"Untitled"`, and 181
  draws five well-formed subtitles and no fallback line.
* **Length.** Rank 10+ in band 3's fixed 14px mono column; and a long title in
  band 3's text column, which is 39px narrower than band 1's and is the one
  recipe with **no** `text-overflow:ellipsis`, so it wraps and breaks the 82px
  row rhythm.

## L3 — 181: the album row, actually letterboxed

181's annotation argues the case — *"The slot is fixed at 38×54 with the album
letterboxed inside it, so the title's baseline never moves between a poster, a
cover and a square"* — but the drawn album row contains **no art and no
letterboxing**: a mono `T` over `ART` on a flat `#E4E0D9` field. Claimed in
prose, never drawn, and with mixed lists ratified it is now load-bearing.

**Draw:** the square cover letterboxed in the 38×54 slot, beside a poster row
and a book-cover row, so the three can be compared at one baseline.

## L4 — 182: the sheet as one real screen, and the empty sheet

182 is 1249px of stacked states in an 806px cap — a state catalogue, not a
screen.

**Draw:** the composed resting sheet. Its height at three lists versus seven,
where it scrolls, what the header does when scrolled, whether there is a
grabber, and any dismissal other than the `close` disc.

**And the empty sheet** — a reader with no lists taps *Add to list*, and 182
always draws a three-row card. What remains is a dashed *New list* over a kept
card that is entirely inert. This is 181's own argument turned on 182: not an
edge case, **the common case**, since both the index and the sheet are first
reached by someone with zero lists.

Three smaller things on the same board: whether the failed row is **re-tappable**
and when the error clears; what tapping the **dash** does (add-all or
remove-all), and the fourth state where every selected title is already in the
list; and what **Wishlist** and **Owned on disc** are — 182 draws them at full
ink with no tick and no reason, directly beside two rows that are dimmed *and*
explained, so a finger lands on them and nothing says what happens.

## L5 — 182: the entry point, which does not exist

182's sheet is drawn for an album — `Tidal Works · Album`. The kinds that make
up every drawn list row (Film · 2025, Series · 2024, Series · dropped at S1 E3)
have **no drawn door into it at all**: a film page's three actions are Log
rewatch / Schedule / Share, and a series page the same. Meanwhile 181's empty
card and 182's sheet both promise *"open a film, book or album and tap Add to
list."*

**Draw:** the *Add to list* control on a film and on a series page, and what it
looks like **after** — once that title is in two lists. That after-state is what
a reader sees the second time they open the sheet, and 182 states outright that
the screen under the scrim is not drawn.

## L6 — naming a list, and failing, each drawn once

**Two naming grammars disagree.** The index's `+` opens a 48px field with a
*Make it* action pill; 182 draws a 36px field in a dashed row **with no commit
control**. Board 12 drew the disc and nothing behind it, so the surface people
actually reach is drawn by no board.

**Draw one**, and with it two cases neither board has: **a name that already
exists** (the code returns the existing list and writes nothing —
indistinguishable from making one), and **a list made while a selection is in
hand** (you name it, it is made *empty*, and the page still says "Pick a list
for 4 titles").

**And the failure grammar.** 182 drew exactly one — *"Couldn't add it. Nothing
was written."* Still silent today: a failed create, a failed remove (**the row
silently reappears**), a failed delete (the page pops anyway and you land on
Lists with the list still there), and a failed add on the shipped path (you
arrive at the list without your title, no message). Draw the rule once and name
where it hangs in each case.

## L7 — NEW: the Persian list detail (mirror of 181)

**289 is the only Persian lists board, and it is the index.** A Persian reader
opens فهرست‌ها, taps a list, and lands on an English LTR page — there is no
`ListDetailFa`. All seven of 289's own rows lead there.

**Draw:** the Persian mirror of 181 — made, empty, ranked, kept — including L1's
destructive controls and L2's states, in the RTL rules 289 already set.

## L8 — NEW: the Persian *Add to list* picker (mirror of 182)

289 says the «افزودن به فهرست» buttons on 69 and 76 *"land here too"* — on the
Persian Lists **index**. 182 rules for English that *Add to list* opens a
**picker sheet over the page you are on**, because a list is filled from a title.
As delivered, **the two locales teach two different gestures for one action** —
the exact failure 254 flags by name for its own Persian pair.

**Draw:** the Persian picker, mirroring 182 — the tick that commits immediately,
the pre-populated state, the inline new-list field, the per-row failure line and
its Persian wording (no Persian save-failure string exists anywhere in the app —
that is `D-60`), and the dash for a mixed selection. Please also say which of
289's sentences changes, since it currently promises the other route.

Note the label these two Persian screens carry today is «فهرست» ("List"), not
«افزودن به فهرست» — the longer string exists nowhere in the app. Whichever the
board chooses becomes the string both screens must render.
