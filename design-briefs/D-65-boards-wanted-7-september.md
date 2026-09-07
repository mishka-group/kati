# Kati — boards wanted, 7 September 2026

Twenty-three boards, ordered by screen number. Each says what is on the device
today, what to draw, and which delivered board already sets the idiom — please
reuse it rather than inventing a second one.

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

# Lists — amendments to 181 and 182, and two Persian mirrors

**Both boards arrived and are correct; nothing here asks you to redraw them.**
What follows are the things they explicitly declined, on which the owner has now
ruled, plus the Persian half that does not exist.

**Two rulings, made 7 September:**

1. **A list can be deleted, and a title can be removed from one.** Board 181
   says *"No overflow disc — rename, share and delete are undrawn, and a disc
   with an undrawn menu is a new inert tap."* That was the right call with
   nothing decided; it is now decided, and the controls exist.
2. **A list holds films, series, books and albums.** 182's mixed card is
   ratified, and the schema will be changed to match — today
   `list_memberships.tracked_title_id` is a hard foreign key to one table, so a
   book cannot be in a list at all. Board 12's own caption already promised
   this: *"The same shell will hold book and album lists."*

**Why this is urgent rather than tidy.** There are **seven** *Add to list*
controls in the app, on six screens, and **only one of them adds anything**.
Screen 146's passes a selection; 66, 68, 74 and 76 push the Lists index carrying
nothing, so the title is never mentioned again; 147's has no tap at all; and
screen 69's — the Persian book page — has no handler and does *literally
nothing*, no push, no write, no feedback. 182 is what fixes all seven, and two
of them are Persian, which is why the mirrors below are not optional.

## 181 — amendment 1: the destructive controls

**Draw:** removing a title from a list, and deleting a list. Where each control
lives (181 currently gives the row's trailing slot to a `chevron_right` and puts
nothing at the foot), and what confirmation each takes. **269 is the app's
confirmation recipe** but is explicitly scoped to 267, 268 and 80 — either widen
it or say why a list needs its own. 253's undo bar is the other precedent and is
scoped to an expense.

Please also rule whether **rename** comes with them, since it is the third thing
181 named as undrawn and the only one still open.

## 181 — amendment 2: the album row, actually letterboxed

181's annotation argues the case — *"The slot is fixed at 38×54 with the album
letterboxed inside it, so the title's baseline never moves between a poster, a
cover and a square"* — but the drawn album row contains **no art and no
letterboxing**: it is a mono `T` over `ART` on a flat `#E4E0D9` field. The
treatment the board argues for is claimed in prose and never drawn, and with
mixed lists ratified it is now load-bearing.

**Draw:** the square album cover letterboxed inside the 38×54 slot, beside a
poster row and a book-cover row, so the three can be compared at one baseline.

## 182 — amendment: Wishlist and Owned, and their empty state

182 draws Wishlist and Owned on disc as **live, tickable** rows and greys only
Abandoned and Rewatches with *"Filled by what you do, not by a tick"* — splitting
by whether a rule fills the list rather than by whether Kati can store it. That
split is now ratified.

**Draw:** what Wishlist and Owned look like **before anything is in them**, and
whether they appear on screen 12's index as well as in the picker sheet. The
code currently drops both as *"assertions the user makes and nothing stores"*, so
this is the first time either has a state to be in.

## NEW — the Persian list detail (mirror of 181)

**No Persian list board exists except 289**, the index. A Persian reader can
open فهرست‌ها, tap a list, and land on an English LTR page.

**Draw:** the Persian mirror of 181 — the made list, the empty list, the ranked
list, the kept list — with the destructive controls from amendment 1 included,
and the RTL rules 289 already set.

## NEW — the Persian *Add to list* picker (mirror of 182)

289 says the «افزودن به فهرست» buttons on 69 and 76 *"land here too"* — on the
Persian Lists **index**. 182 rules for English that Add to list opens a **picker
sheet over the page you are on**, because a list is filled from a title. As
delivered, **the two locales teach two different gestures for one action** — the
exact failure 254 flags by name for its own Persian pair.

**Draw:** the Persian picker sheet, mirroring 182 — the tick that commits
immediately, the pre-populated state, the inline new-list field, the per-row
failure line, and the dash for a mixed selection. And please state which of 289's
sentences changes as a result, since it currently promises the other route.

Note the label these two Persian screens actually carry today is «فهرست»
("List"), not «افزودن به فهرست» — the longer string exists nowhere in the app.
Whichever the board chooses becomes the string both screens must render.
