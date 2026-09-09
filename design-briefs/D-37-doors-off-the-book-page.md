# Five doors off the book page, and none of them drawn

> **Mixed — four new boards and five edits** · ticket `D-37`

A person is on screen 66 with a book open in front of them. They want to know which volume
comes next in the series, to remember that Jo has their copy and mark it back when it
returns, to read the three content warnings the band says exist before they carry on, to
give the book a page count so the progress bar has a denominator, and — having finished it
— to rate it. Every one of those five is **drawn as a control on 66** and every one of them
opens onto nothing: three are chevrons pointing at screens that exist in no artboard, one
is a dead value the states board promises leads to an editor, and the fifth hands to board
33, which is a film log that asks where you watched it and whether it was a rewatch.

## Why this is one brief and not five

It is the same problem five times, in `D-34`'s exact shape: **board 66 — with its dark twin
68 and its Persian twin 69 — draws an affordance, and the surface it opens is drawn nowhere
in the 166.** The series row ends in `chevron_right` and the sub-line `Next: Low Water`; the
ownership row ends in `chevron_right` and `Due 27 Aug`; the Content warnings band ends in
`3 expand_more`; the Length row prints `380 pages` and nothing else, while 67 draws
`Length | add | Add page count` and 71 draws a row reading *Add a page count · Jumps to the
Edition row on 66 · chevron_right*; and `star Rate & review` pushes `Kati.Screens.Rating`.

Split five ways these become five tickets that all say *66 promises a destination*, all
reuse the same list-row and modal-sheet recipes, and all have to answer the same question
before any of them can be drawn — see the next section. `Kati.ScreenTapSweepTest` already
carries two of them on its backlog with one shared reason:

> neither a next-in-series screen nor a lending screen exists anywhere in the 127 artboards

Delete those entries the day these boards land.

## The four boards and the five edits

| Board | What it is | What it carries |
|---|---|---|
| **172** — Next in series | new | the volumes of `The Coastal Ledgers` in position order, this one marked, the next one the ink button. The destination of 66's series row |
| **173** — Lending | new | who has your copy, when it is due, and the three transitions: lend, edit, mark returned. The destination of 66's ownership row |
| **174** — Content warnings | new | the expanded list a count of `3` promises, each entry's category, note and origin, and the control that records one |
| **175** — Log a read | new | 33 for a book: the same stars, the same review body, with **finished on**, **format read** and **re-read count** where 33 has `event Watched on`, `tv Where` and `replay 2nd rewatch` |
| **66** edit | Book detail | Length row gains its control state; the warnings trailing resolves to one glyph; the series and ownership chevrons are kept or dropped by the decision below |
| **67** edit | Book detail — states | a seventh state: the page-count entry open, and the entry that refuses. **The board's own title literal changes from `Book detail six states` to seven** |
| **68** edit | Book detail — dark | 66's edits, in 68's dark treatment. 68 is a full redraw of 66, not a swatch sheet |
| **69** edit | کتاب — Book detail, RTL | 66's edits in Persian and mirrored, including a Shamsi due date and `chevron_left` |
| **70** edit | Log progress | the handoff label. 70 prints `33 RATE & REVIEW` on its face; it becomes `175 LOG A READ` |

72 — the RTL Log progress — does **not** need an edit. It draws the timer-running state and
carries no handoff label, so there is nothing on it to re-point.

## The one decision that spans all four

**Which of these are pushed screens and which are modal sheets.** It has to be made once,
here, because the house style makes the two visibly different and 66 has to agree with
whichever it is:

- A **pushed screen** takes the back pill (`arrow_back_ios_new` + parent name), and the row
  that opens it keeps its `chevron_right`.
- A **modal sheet** takes a `close` disc and a **Save** pill, because — `Kati.Screens.Rating`,
  which is the precedent — *"it is a sheet you either commit or abandon, and a back arrow
  says neither"*. A row that opens a sheet must have its chevron **removed** on 66, 68 and
  69 in the same pass, because the house rule is absolute: a chevron means *leads elsewhere*.

Board 175 is settled by inheritance — it is 33's shape, and 33 is a sheet. The other three
are open, and the warnings one is sharper than it looks: 66 draws the trailing as
`3 expand_more`, which promises the block **opens in place**, not that it pushes. Either
174 is the expanded block drawn as it appears inside 66 — in which case `expand_more` is
right and 174 is a states sheet rather than a screen — or it is a surface of its own and the
glyph on 66/68/69 becomes `chevron_right`. Do not leave both readings drawn.

**The page count is not part of this decision.** 71 already fixes its destination — *Jumps
to the Edition row on 66* — so the entry is inline on 66 and the Length row must **not**
gain a chevron.

## Every element, and the glyph it takes

All glyph names below are Material Symbols Rounded, and every one of them is already in
`Kati.Icons`' shipped subset. Any name added beyond this list needs `mix kati.gen.icons` and
a re-subset before it can be drawn on device — `Kati.Icons.glyph!/1` raises for a name the
font does not carry, which is why `star_half` does not appear anywhere below.

### 172 — Next in series

1. Chrome — back pill `arrow_back_ios_new` *Book*, or `close` + Save if it is a sheet
2. Series header — `menu_book` tile, the series name, and `#3 of 7` in DM Mono
3. **The volumes Kati actually holds**, one list row each, in `series_position` order:
   position in DM Mono, title, author. Finished takes `check_circle` in green; unread takes
   `radio_button_unchecked`; the one you came from is the current row and takes no glyph, it
   takes the selected treatment
4. **The gaps drawn as gaps.** Kati has no series resource — `series_name`,
   `series_position` and `series_total` are three columns on `Kati.Books.Book` — so the only
   volumes it can name are volumes you have shelved. Position 4 is a row that says the
   position and nothing else, with an `add` affordance reading *Add this volume*. Never
   invent a title
5. Primary — one ink button, *Start reading* on the next unread volume, or *Add the next
   volume* when the next position is a gap
6. A quiet line saying Kati knows the series from the books you have added

### 173 — Lending

Three whole-screen states, not three bands. Draw all three.

1. Chrome, then the book it is about — cover thumb, title, author
2. **Not lent** — `inventory_2` header, one line saying the copy is with you, and the entry
   form: *Who has it* (text field, `person` tile) and *Due back* (date field, `event` tile).
   Primary ink button *Lend it*
3. **Lent** — the standing loan as a card: `person` *Jo*, `event` *Due 27 Aug*, and a
   `history` line saying how long it has been out. Two controls: `edit` *Edit the loan* as a
   pill, and the ink button `event_available` *Mark returned*, which clears both columns
4. **Overdue** — the same card with the due line in **bronze** `#C98A3E`, not red. Bronze is
   the gentle warning in this palette; a lent book is not an error
5. The refusal line above the action, in 66's manner — one line, one place

### 174 — Content warnings

1. Chrome. If it is a sheet: `close` disc, and no Save pill if each add commits on its own
2. **The list**, three rows: `shield` tile, the category as the title, the user's note as the
   second line when there is one
3. **Origin, per row.** `Kati.Media.ContentWarning.origin` is `:user` or `:import` and the
   resource exists precisely so the two are not presented as equally authoritative. Draw it:
   `person` for typed, `upload_file` for imported, at caption size in tertiary
4. **`delete` on each row** — a warning you typed is a warning you can remove
5. **The add control** — a free-text field, not a picker. Below it, a row of recently used
   categories as chips, which is a shortcut and not a vocabulary
6. **Empty** — `None recorded` and the `add` affordance, which is what 66 draws today
7. A line saying where warnings come from: yours and your imports. This is not optional
   copy; see *What it must NOT do*

### 175 — Log a read

Board 33, book by book, with 33's chrome unchanged: `close` disc, **Save** pill, no dock.

1. Hero — cover, title, author, and `replay` *2nd read* where 33 has *2nd rewatch*. A first
   read draws **no badge at all**; `1st read` is a label for a thing that has not happened
   twice
2. Rating — the `5★` / `10pt` scale toggle, five `star` glyphs, the printed `4.5`, and the
   caption *HALF STARS ON · TAP LEFT OR RIGHT OF CENTRE*, all as 33 draws them
3. Review — the body, the character count in DM Mono, `format_bold` `format_italic` `link`,
   and the `visibility_off` *Spoilers hidden* toggle
4. Context rows, replacing 33's three:
   - `event` **Finished on** Sun 16 Aug · `chevron_right`
   - `menu_book` **Read as** Paperback · `chevron_right`
   - `replay` **Re-reads** 1 · `chevron_right`
5. Tags — the four-tag row and `add` *+ tag*, unchanged from 33

### The edits on 66, 68 and 69

- **Length** — when `page_count` is nil the row draws `add Add page count` in muted, exactly
  as 67 already draws it; when it has a value it draws the value and gains a small `edit`
  affordance. Tapping either opens an inline stepper or field **in the Edition card**, with
  the unit restated. **No chevron on this row, in any state**
- **Content warnings** — one glyph, per the decision above
- **Series and ownership** — chevrons kept or dropped, per the decision above
- **`star Rate & review`** — the label does not change. Only its destination does

## States to draw

`Kati.ScreenEmptyDatabaseTest` renders every screen with nothing stored and asserts the same
literals the design board carries, so **a state that is not drawn is a state that is not
tested**. On these four boards the empty state is not an edge case: with an empty shelf
`Kati.Screens.BookDetail.book/0` falls through to `Kati.Books.Sample.detail/0`, which means
on a fresh install every one of these surfaces opens on the sample book. What the sweep
compares against has to exist.

| Board | Resting | Empty | Error |
|---|---|---|---|
| 172 | 7 volumes, 3 shelved, this one #3 | the series is known and this is the only volume Kati holds — one row and an `add` | offline: the list is local, so there is nothing to fail; draw no error |
| 173 | the standing loan | **not lent is the resting state**, and it is the form | the save that refuses: `Lend it` with no name. Sheet stays, writes nothing, says so |
| 174 | three warnings, one imported | `None recorded` + `add` — this is the state every real book is in today | — |
| 175 | rated, reviewed, 2nd read | no rating yet: stars outlined, no printed figure, Save still live because a review with no stars is a real log | the save that refuses, in 33's own idiom |
| 66/68/69 | Length with a value | Length with none, drawing `add Add page count` | the existing single failure line above the action row |
| 67 | — | — | the page-count entry that refuses a non-number |

## RTL

Yes, and it is already half-written: **69 exists**, so the edits to 66 must be drawn a second
time in Persian on 69, mirrored. That is the RTL work this ticket carries.

The four **new** boards get no Persian twins here — 172–175 are the only numbers reserved,
and a Persian mirror of each is a follow-up that must take numbers above 175. Each new board
should instead carry a short RTL note in its caption so the mirror is not re-decided later.

What mirrors: the whole grid, the list rows, the chip rows, the back pill's glyph
(`arrow_back_ios_new` → `arrow_forward_ios`), every chevron (`chevron_right` →
`chevron_left`, as 69 already draws in its series and ownership rows). What does not: cover
artwork, and star glyphs — `★★★★½` reads the same way in both languages. **The vertical
order never reverses**; the bands stay top to bottom exactly as the LTR board has them.
Dates go Shamsi and digits go Persian, both still in DM Mono so the columns align — 69
already prints `موعد ۵ شهریور` for `Due 27 Aug`, and 173's due date and overdue state must
follow it rather than invent a second convention.

## Dark

**No new dark artboards.** Kati draws a dark board only where the dark treatment carries a
decision — six in 166 — and the app derives the rest through `Kati.Theme`.

But **68 is one of those six, and it is an edit here**, because 68 is a full redraw of 66
rather than a swatch sheet. Every control this ticket adds to 66 has to appear on 68 in
68's own terms: the hairline-instead-of-shadow rule, the selected chip and the ink button
inverting to `#F5F2EE` on `#16150F`, and the cover keeping its ring drawn in card colour
rather than paper. Where 173 uses bronze for an overdue date, check it against the dark
ground on 68's swatch before committing to it.

## Reuse, do not invent

Nothing here is a new idiom.

- **Every row on 172, 173 and 174** is the standard list row — 30×30 paper tile radius 9,
  glyph 17px, 13.5px/600 title, 11.5px `#8A8479` second line.
- **173's fields** are screen 92's field recipe, the one `D-31` sends *Add by hand* to.
- **175 is board 33**, kept as literally as the substitutions allow: same close disc, same
  Save pill, same star row, same review card, same tag row.
- **The half star on 175 is `star` at FILL 0**, outlined, in the accent — not a cropped
  glyph. `Kati.Screens.Rating` explains at length why the drawing's construction (a grey
  star with an orange one over it, in a box half as wide) is not reachable across the bridge,
  and 175 must not re-introduce it.
- **174's warning rows** are the same rows; its chips are the standard chip, height 32,
  radius 16.
- **172's finished marks** are 04's episode `check`, in green.
- **The overdue bronze** is the money-and-meals bronze, already in the palette.
- **The refusal line** is 66's existing one — one line, above the action row.
- **The undo pill**, if 173's *Mark returned* gets one, is 71's undo pill, which 71's own
  note says *"surfaces on both 20 and 66"*.

## What it must NOT do

Decisions the codebase has already made. Contradicting one of these makes the board
undrawable rather than merely wrong.

**Do not draw a loan history on 173.** `Kati.Books.Book`:

> `lent_to` and `lent_due_on` sit here rather than in their own resource because a book is
> lent to at most one person at a time and Kati has no reason to remember who had it in
> 2019. When it does, this becomes a relationship and these two become the newest row.

One loan, one name, one date. A list of past borrowers is a schema change, not a band.

**Do not draw a page-count field that also holds a runtime.** `Kati.Books.Book`:

> Page count and duration are one field each, never both. An audiobook has no pages and a
> paperback has no runtime […] so `format` is what decides which of `page_count` and
> `duration_minutes` is meaningful

The entry the Length row opens has to follow the Edition chips above it: pages for
Paperback and Ebook, `11h 20m` for Audiobook, with the unit restated so the number never
looks like the other kind.

**Do not invent a denominator when there is none.** Same moduledoc:

> `page_count` is nullable on purpose. Screen 67's *partial metadata* state is a real Open
> Library answer — a work with no pagination — and the screen draws `p. 214 · NO PAGE COUNT`
> and an `Add page count` affordance rather than inventing a denominator.

**Do not let the warnings block open itself.** `Kati.Screens.BookDetail`:

> Closed by default and closed on arrival is the ticket's own instruction, and it is not a
> default that wants overriding: the point of a content warning is that you can choose to
> look at it, which a block that opens itself takes away.

So 174 is reached by a deliberate tap, and 66 must not preview its contents — no blurred
peek, no first warning shown as a teaser.

**Do not draw warnings as if they came from a provider.** `Kati.Media.ContentWarning`:

> Kati has **no source** for content warnings. Open Library carries none, and StoryGraph's
> are its own dataset rather than an API. D-13 states the consequence plainly: a warnings
> block that is always empty is worse than none, so the design must say where warnings come
> from. They come from here — the user's own entries, plus whatever an import brings in.

**Do not draw a category picker as the only way in.** Same moduledoc:

> Unlike `Kati.Media.Mood`, whose closed vocabulary exists so it can be aggregated, a warning
> is a thing that happened in a story and nobody owns the list. A fixed enum would make the
> feature useless for the warning the user actually needs to record.

**Do not put Avoid / Warn me / Show on 174.** That is `Kati.Media.WarningPreference`, it is
keyed on the category rather than the title, and it lives in *Settings → Content I'd rather
avoid* — D-13's screen, not this one. A stance control on a book page would make a per-user
preference look like a per-book fact.

**Do not give any of these boards two ink buttons.** One per screen. On 66 the ink button is
already spoken for and the reasoning is on the record — *"Log progress is the only one of
the four you press more than once per book"* — so nothing this ticket adds to 66 may be
promoted to a primary.

**Do not offer a status control on 175.** `Book.status` has five values and 66's control
offers four, because *"`:not_started` is the default, and the four the control offers are the
four you can move *to*"*. 175 is reached from `Finish` and from 70's *Finished the book*,
both of which have already set the status. Re-asking is a second writer for one field.

**Two things named in the surveyed claims are deliberately out of scope, and are code and
schema tickets rather than design gaps.** They should not appear in this brief's acceptance
and should not stop a board being drawn:

- `book_detail.ex:229` hardcodes `series_next: nil` and `book_detail.ex:227` hardcodes
  `warning_count: 0`. Both are frozen values in `shaped/3`. The drawings are correct; the
  reader is not.
- `Kati.Media.ContentWarning` is bound to `Kati.Media.TrackedTitle` and `Kati.Books` has no
  equivalent, so there is nowhere to store a book's warning today. Board 174 says what the
  surface is; the resource is a separate change and follows it.

Finally: **whoever draws 174 should draw the film side in the same pass.** Board 04 carries
no warnings band at all today, and warnings appear on exactly three boards in the 166 — 66,
68 and 69 — all of them books. If the book sheet ships alone, the same pattern gets invented
a second time for film, and the two will not match.

## Left open — decide and note which way you went

**The push-versus-sheet decision above, first**, since three boards and three chevrons on
three drawings hang on it.

**175 has three values with no column behind them.** `Kati.Books.Book` carries `rating` and
nothing else this board needs: there is no `review`, no `finished_on` and no read count.
`Kati.Books.ReadingSession.reread` is a per-sitting boolean, not a tally, and *"a re-read
covers pages already read"* — counting reads from it is not the same question. Draw the
board anyway, and say so in its caption: on lending the schema is ahead of the design, and
here the design is ahead of the schema, which is the ordinary direction.

**Whether *Read as* on 175 writes `Book.format` or a per-read format of its own.** If it
writes `Book.format` then 66's Edition chips and 175's row are two controls on one field,
which the project has avoided everywhere else. If it does not, it needs a column.

**Whether 33's `group With Jo` row survives on 175.** A book club is real; a shared reading
session is not. Decide, and if it survives, say what it means for a book.

**Whether *Borrowed from* belongs on 173.** `D-01` asked band 9 for *Owned / Borrowed / Lent
to*, and the schema shipped `owned`, `lent_to` and `lent_due_on` — borrowed-from has no
column. Either 173 is the lending page only, or it becomes the ownership page and asks for
one more field.

**Whether the Length editor is a stepper or a keyboard field.** 70's page control is a
stepper with `remove` and `add`; a page count of 380 is a bad stepper.

**Whether *Mark returned* on 173 gets an undo pill**, and whether 172's *Add this volume*
hands to `Add by hand` (154) or to search (06).

**Persian copy for all four new boards.** 72's caption sets the precedent and should be
matched: *"All Persian copy was open; these strings are proposals."*

## Acceptance — how we know the drawing is enough to build from

1. **Every literal is there to be asserted.** `Kati.ScreenDesignLiteralTest` reads every text
   literal and every Material Symbol off the board and asserts it against the rendered tree.
   A board with placeholder copy is a board the sweep cannot be pointed at.
2. **Every glyph is a real Material Symbols Rounded name**, listed in the caption if it is
   new, because `mix kati.gen.icons` builds the shipped font subset from these boards and
   `Kati.Icons.glyph!/1` raises for a name the font does not have.
3. **Every board has an empty state drawn**, per the table above, or a written line saying
   why it cannot be empty.
4. **Every control on every board names its destination** — a screen, a sheet, or an
   in-place change. `Kati.ScreenTapSweepTest` proves each drawn tag reaches a handler that
   changes something; a control whose destination is undrawn goes on the `@inert_taps`
   backlog with a reason, and this ticket exists to stop that list growing.
5. **66, 68 and 69 agree with each other**, control for control and chevron for chevron. A
   control added to 66 and missed on 68 is a defect the dark sweep will find and the RTL
   sweep will not.
6. **67's title literal is corrected** to name the number of states it now draws.
7. **70 no longer prints `33`.** The handoff label names the new board.
8. **The two backlog entries can be deleted** — `{Kati.Screens.BookDetail, :open_series}` and
   `{:open_lending}`, plus their `BookDetailDark` and `BookDetailFa` mirrors — because both
   rows now push something drawn.

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
