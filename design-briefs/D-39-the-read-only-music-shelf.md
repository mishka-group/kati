# The read-only music shelf — a way in, and a way to rate what is there

> **Mixed — two new sheets, one new form state, four board edits** · ticket `D-39`

The music domain is finished and unreachable. `Kati.Music.Album`, `Artist`, `Track` and
`Listen` are migrated, indexed and read by four screens — and **nothing in the app writes
an album, an artist or a track**. The only music writes in `lib/` are `Kati.Music.Listen`'s
create on screen 73 and the `following` toggle on screen 77, both of which need a row that
cannot be made. So screen 21 is permanently on `Kati.Music.Sample`, screen 74's `YOUR
RATING` tile prints 4.5 stars nothing can set, and screen 73's **Save listen** answers
`{:error, :nothing_to_save}` on every device that has ever existed.

## The problem, stated plainly

A person opens the Music shelf, sees three albums they do not own, and wants to put their
own record there. There is no control anywhere that does it. The dock's `+` opens screen
06, whose scope chips stop at `Everything | Films | Series`; its *Can't find it? Add it by
hand* row opens screen 154, whose Kind row is `@kinds [{"Film", :movie, "movie"}, {"Series",
:tv, "live_tv"}]`. Screen 21 draws no add control of its own — the only glyphs in
`21.html` are `search`, `sort`, the three segment icons and the dock's `add`. Every add
surface in the 166 boards was drawn film-first and never given its music instance. Then,
supposing a record somehow arrived, tapping **Rate** on screen 74 pushes
`Kati.Screens.Rating`, which draws a sheet about the film *Blue Hour* — its own `mount/3`
takes `_params` and reads `Kati.Rating.Sample`.

## Why this is one brief and not two

Because it is the same problem twice, and splitting it would make the two halves disagree.

Both failures have the identical cause — the add surfaces and the rating surface were both
drawn for film and never redrawn. Two briefs would each have to quote the same sentence
from board 06's caption (*"later the same sheet adds a book, an album or an event — the
type is inferred from what you searched"*) and the same precedent from board 144 (*"33's
modal, episode-scoped"*), and each would independently have to invent an **album-shaped
context strip**: an album has no runtime you watched it on, no living room, no companion
and no rewatch count. That strip appears on both the add form and the rating sheet, and it
has to be answered once. Two briefs would answer it twice.

## Two decisions this brief makes rather than leaves open

**1. Artist is a Kind beside Album, not a field reached only through one.**
`Kati.Music.Album`'s `belongs_to :artist` is `allow_nil? true`, so an album-only path would
quietly accumulate records with no artist behind them. Screen 77 is a full detail screen
carrying `role`, `country`, `first_heard_on` and `following` — four values an album form
has nowhere to put. And `Kati.Screens.Music` says why the shelf needs the person and not
the string: *"'New from artists you follow' follows a person, where an `:album` row is one
record, so there is nothing of the right shape to follow."* Following somebody whose
records you do not own yet is a thing people do. So the Kind row grows to **four**.
Within the Album state the Artist field still creates one inline, so the common path stays
one form.

**2. The album rating sheet is its own board, in 144's manner — not a variant of 33.**
Board 70 hands a finished book straight to 33, so the precedent cuts both ways, and board
73's caption already settled which way for music: *"music gets no 'finished' shortcut — an
album has no equivalent of closing a book."* Music is precisely the domain whose rating
sheet does *not* arrive from a progress sheet's second commit. Three of 33's bands do not
survive translation (the rewatch pill, `Where`, `With`) and a fourth is dropped (spoilers),
so a "variant" annotation would list more removals than survivals. 144 is the pattern for
exactly this: 33's chrome, a different noun, its own artboard.

## What to draw

| Board | What it is | What it carries |
|---|---|---|
| **178** — new | **Add by hand — a record.** Screen 154's form with **Album** chosen | the four-chip Kind row; Album, Artist, Released, Tracks, First heard; one ink button; the no-art note. An **Artist chosen** inset beside it, since that state drops three fields and gains two |
| **179** — new | **Add a title — the music state.** Screen 06's sheet mid-query on `ostrand` | five scope chips with **Albums** lit; three result rows on **square** art, not 2:3 posters; one row already added; the *Add it by hand* row, now with a destination |
| **180** — new | **Rate an album.** 33's chrome, 144's manner | close disc, Save pill, album-shaped context strip, the star row, the two scales, one review body, two date rows |
| **06** — edit | the scope chip row | `Everything · Films · Series · Albums · Artists` |
| **21** — edit | the shelf's empty state, and an annotation | **no add control is added.** See below |
| **154** — edit | the Kind row | four chips, `graphic_eq` and `mic` after `movie` and `live_tv` |
| **155** — edit | the Kind row in both drawn states | four chips resting, four chips under the refusal |
| **157** — edit | the Kind row in dark | four chips; the trough decision 157 already records is unchanged |

**The 21 edit is a refusal, and it is the point of the edit.** `Kati.Screens.Root` puts the
FAB's handler on the root macro and says why: *"The FAB opens the add sheet from every root
— screen 06's note calls it 'one sheet reached from the + button', so it belongs here
rather than in four copies."* Screen 21 is not a fifth root; `Kati.Screens.Music` opens by
saying it is *"the same root wearing a different shelf"*. A second add control on the Music
shelf would be a second door to a sheet that already has one. What 21 needs instead is a
**state**: 06 opens with the **Albums** chip lit when it was reached from the Music shelf.
Draw that as 179's default rather than as a control on 21.

## Every element, with its purpose and its glyph

Every symbol named below is already in `Kati.Icons`' map, so this brief costs no
`mix kati.gen.icons` run and no pyftsubset pass. That is deliberate — see *What it must NOT
do*.

### Board 178 — Add by hand, a record

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Add title` | 154's pill, unchanged — the parent is still screen 06 | `arrow_back_ios_new` |
| Large title `Add by hand` + subtitle | 154's heading verbatim | — |
| **Title field** | relabelled by Kind: `Album` under Album, `Name` under Artist. The one required value | — |
| **Kind row — four chips** | `Film` / `Series` / `Album` / `Artist`. This is the control that reveals everything below it | `movie` · `live_tv` · `graphic_eq` · `mic` |
| **Artist field** *(Album only)* | free text, optional. `artist_id` is nullable and the form must not pretend otherwise. A typed name that matches nothing creates the artist | `person` |
| **Released** *(Album only)* | `released_year`, DM Mono, numeric, marked `optional` — 154's Year row exactly | — |
| **Tracks** *(Album only)* | a **count**, not a tracklist. Marked `optional`; it is `CachedTitle.track_count`'s music twin and the denominator screen 74 has never had | `playlist_play` |
| **First heard** *(both)* | a date, optional. `first_heard_on` is a stored column on both resources | `event` |
| **Role · Country** *(Artist only)* | one row, two free-text fields. Screen 77 prints them as `Composer · Iceland` | — |
| **Following** *(Artist only)* | a switch, **off** by default | `notifications` |
| Primary button `Add to library` | **one per screen** | — |
| Refusal line | 155's sentence, this form's noun | `error` |
| Quiet note | a hand-typed record carries no art and no tracklist; both arrive if Kati finds it later | `info` |

**Where 154 has Status, 178 has nothing.** `Kati.Music.Album` has no status column and no
progress. `Kati.Media.TrackedTitle`'s five statuses — `:not_started`, `:watching`,
`:paused`, `:finished`, `:dropped` — are watch statuses; an album is not watched and is
never finished. The row is removed, not translated. Say so on the board.

### Board 179 — Add a title, the music state

| Element | Purpose | Glyph |
|---|---|---|
| Close disc + title `Add a title` | 06's chrome, unchanged | `close` |
| Search field, **focused** | drawn mid-query as 06 is — 2px ink ring, orange caret. Query `ostrand` | `search` |
| Cancel pill | 06's, unchanged | — |
| **Scope chips ×5** | `Everything` · `Films` · `Series` · **`Albums`** · `Artists`. Drawn with **Albums** in ink, because this is the state 21's FAB opens | — |
| Result eyebrow | DM Mono, `.16em`, uppercase — `3 RESULTS`. It narrows with the chip, as 06's `4 RESULTS` does | — |
| **Result row — square art** | the one row-shape difference from 06. An album is a square; the paper placeholder carries its initial | — |
| Meta line | `2025 · ALBUM · 11 TRACKS`, in 06's shape (`2023 · SERIES · 2 SEASONS`) | — |
| Note line | the artist, where 06 carries genre and service. `Kell Ostrand · Post-classical` | — |
| Trailing disc, **both states** | ink `add` for a record not on the shelf, muted `check` for one already there. 06 draws both and so must this | `add` / `check` |
| *Can't find it? Add it by hand* | 06's bordered row. It now opens 178 | `edit_note` |

### Board 180 — Rate an album

| Element | Purpose | Glyph |
|---|---|---|
| Close disc · title `Rate an album` · Save pill | 33's chrome. Not a back pill: this is a sheet you commit or abandon | `close` |
| **Art square, no art** | 74's default rendering — a paper square carrying the album initial and the `Art` placeholder | — |
| Title + meta | `Tidal Works` then `KELL OSTRAND · 2025` in DM Mono caps — **board 73's line, reused verbatim** | — |
| **Plays pill** | where 33 has `replay · 2nd rewatch`. `41 plays`, from the album's listens | `repeat` |
| Rating row | four filled `star` glyphs, a fifth at **FILL 0**, the printed `4.5` beside it | `star` |
| Scale toggle | 33's `5★` / `10pt`. Not a second store — see below | `star` |
| Rating hint | 33's `HALF STARS ON · TAP LEFT OR RIGHT OF CENTRE` | — |
| **Review body** | this is `Album.note`, the same field screen 74's cream card draws. Character count, and 33's three format controls | `format_bold` `format_italic` `link` |
| Note date | `Album.note_on`, DM Mono, as 74 prints `3 MAR 2024` | — |
| **First heard** row | `3 Mar 2024`, editable. A stored column, not a derivation | `event` |
| **Last played** row | `yesterday`, read-only here — screen 73's save owns it | `history` |

**No spoiler toggle, no `Where`, no `With`, and no rewatch count.** Nothing in
`Kati.Music.Listen` records a service, a room or a companion; `Kati.Media.Watch.service` is
a film fact. A record has no plot to spoil. Draw the three omissions as an annotation on
180 — a designer coming to this board later will otherwise assume they were forgotten.

## States

Kati's sweeps compare an empty state against a board — `Kati.ScreenEmptyDatabaseTest` reads
the same literals with nothing stored — so an undrawn empty state becomes an untested one.
Four matter here and one of them is new:

- **Resting.** 178 with Album chosen and the fields blank; 179 with Albums lit and results
  under it; 180 with a rating already set, since a person usually arrives to change one.
- **Active.** 179's field mid-query with the ink ring and orange caret, 06's own drawn
  state. 180's star row at 4.5 — the outlined fifth star, not a cropped one.
- **Empty — two of them.** 179 after a search that finds no record: 178 is reached most
  often from *here*, so draw the row that rescues it against an empty list. And **screen
  21's empty shelf**, in screen 27's manner, which has never existed: screen 21 reads
  `Kati.Music.Sample` unconditionally today, so the first hand-typed album is also the first
  moment the Music shelf can be genuinely empty rather than merely fictional. Screen 96's
  rule applies — *"say what is missing and offer the one thing that fixes it"* — and the one
  thing that fixes it is the FAB, not a new control.
- **Error.** 178's refusal, in 155's shape: name what is missing, then say **nothing was
  written**. The field takes the red inset ring and keeps its caret; the button is never
  disabled, *because a dead button explains nothing*. `Kati.Write`'s contract and
  `Kati.WriteContractTest` already enforce this on the host.

## RTL

**No Persian mirror is reserved by this ticket**, and that is a scoping decision rather than
an omission: 154's mirror is board 156 and it was drawn as its own board. State the rules on
178 and 180 so the Fa siblings are a redraw and not a redesign.

What mirrors: the container takes `dir="rtl"` and the whole grid mirrors — chip row, field
troughs, label-and-value rows, the trailing discs on 179's result rows. The back pill's
glyph becomes `arrow_forward_ios` and chevrons become `chevron_left`. Dates go Shamsi and
digits Persian, both in DM Mono so the columns still align.

What does not: **artwork never mirrors** — 179's square art and 180's paper square with its
initial keep their orientation, and `Album.initial/1` returns `?` for a title that starts
with something uncased, which is the Persian case and is already handled. **Star glyphs
never mirror.** **The vertical order never reverses**: Title before Kind before Released
before Tracks, in Persian exactly as in English.

## Dark colourway

**Not needed as a fourth board, and here is why.** The one recipe on 178 that needed a dark
decision is the inset field trough, and board 157 already made it: *"it goes `#2A2826` with
a hairline rather than inverting to card colour, so a field still reads as a hole rather
than a raised surface. The orange caret is unchanged — it is the one accent on the screen in
both themes."* 178 adds no new surface to that form. 180's only new surface is the art
square, and board 75's Dark inset answers it: *"Cream warms to `#2A2622` with `#F7EFE4`
text; cards lift on a hairline, not a shadow."*

The 157 edit is therefore the four-chip Kind row and nothing else.

## Reuse, do not invent

- **178's whole chassis** is board 154 — pushed screen, back pill, heading, labelled inset
  trough, `optional` marker, one ink `Add to library`, the `info` note under it.
- **The Kind chips** are `Kati.Components.MishkaChip` at the standard recipe: height 32,
  radius 16, padding-x 15, 12.5px/600, selected in ink.
- **179's chassis** is board 06 entire — close disc, focused field, chip row, DM Mono result
  eyebrow, the bordered *Add it by hand* row.
- **179's square art tile** is board 21's album tile, `flex:1` with `aspect-ratio:1`, at
  result-row size.
- **180's chrome** is board 33's: close disc (`Kati.Components.MishkaCloseButton`, filled,
  with `Kati.Theme.shadow_button()`), Save pill (`Kati.Components.MishkaPill`).
- **180's context header** is board 73's — the square, the title, the DM Mono `KELL OSTRAND
  · 2025` caps line.
- **180's star row** is board 33's construction: five separate `star` glyphs sharing one
  line box, the fifth at FILL 0.
- **180's plays pill** is 33's rewatch pill with a different glyph and noun.
- **The refusal** is board 155's, sentence and inset ring both.
- **21's empty card** is board 27's, with the Music shelf's noun.

## What it must NOT do — decisions the codebase has already made

**Do not draw a cropped half star.** `Kati.Screens.Rating` is explicit: *"Kati's icon subset
carries `star` and nothing called `star_half`, and `Kati.Icons.glyph!/1` raises for a name
the font does not have, so there is no half glyph to ask for."* And the drawing's own
construction is unreachable: *"a 26sp glyph in a 13dp box is not cropped to half a star: it
is measured at 13dp, becomes one unbreakable character too wide for its line, and is
ellipsised away to nothing."* The half slot is the same `star` glyph at FILL 0.

**Do not draw the review as a second thing from screen 74's note.** `Kati.Music.Album`:
*"One note per album rather than a resource: unlike a book, which is read over weeks and
annotated at pages, an album gets the one thing you thought about it."* 180's body edits the
card 74 already draws. Two review fields would be two truths about one record.

**Do not draw a 10-point store beside a 5-star one.** `Kati.Music.Album` stores
`attribute :rating, :integer, constraints: [min: 0, max: 10]` and comments it *"Halves, as
every other rating in this app is stored."* The `10pt` toggle is one column read two ways.

**Do not draw a Status row, a Finished action, or a progress bar on 178.**
`Kati.Music.Listen`: *"music gets no 'finished' shortcut — an album has no equivalent of
closing a book. So this sheet has one commit and screen 70 has two."*

**Do not ask for track durations on 178.** `Kati.Music.Track` marks `seconds` nullable and
says why: *"a tracklist typed by hand often has names and no timings."* 178 asks for a
count, and never for eleven rows of `4:12`.

**Do not draw an art picker or a broken-image state.** `Kati.Screens.AlbumDetail`: *"the
square is the default rendering and not a fallback, and `Kati.Music.Album.initial/1` fills
it."*

**Do not derive First heard from the listens.** `Kati.Music.Album`: *"Deriving them would
report first heard: yesterday for a record somebody has had since 2011."* That is why the
field is on 178 at all.

**Do not let 178's Following switch imply an alert.** `Kati.Music.Artist`: *"premieres stay
a separate opt-in so following an artist cannot silently turn on push."* The switch's
subtitle says what it feeds — 21's releases band and one of 25's six alert types — and
nothing more.

**Do not draw a scrobble or connection badge anywhere here.**
`Kati.Screens.AlbumDetail`: *"connection state belongs to 80. A per-album scrobble indicator
would put the same fact in as many places as there are albums, each able to disagree with
the others."*

**Do not add a second add control to screen 21.** See the 21 edit above.

**Do not draw tag pills on 180.** 33 has four and a `+ tag`, and
`{Kati.Screens.Rating, :add_tag}` sits in `Kati.ScreenTapSweepTest`'s Backlog as a control
that does nothing. Drawing tags here would ship a second inert control on a brand-new board.

**Do not name a glyph outside the subset.** Every symbol in this brief is already in
`Kati.Icons`. A new name means `mix kati.gen.icons`, and
`test/design/material_symbols.codepoints` *"is not in the repo and never was"*.

## Left open — decide and note which way you went

- **Where a hand-typed album actually lands.** `Kati.Screens.AddByHand` writes a
  `Kati.Media.CachedTitle` and a `Kati.Media.TrackedTitle`; screen 21 reads `Kati.Music`,
  because `Kati.Media.CachedTitle` *"has no byline column at all"* and `Kati.Media.Watch`
  *"records that a record was played and when, never for how long."* So the Album and Artist
  chips on 154's Kind row cannot simply be a third and fourth column of the same write — the
  form branches to a different domain below the chip row. That is a code decision, and the
  drawing should not pretend to settle it; what the drawing owes is a Kind row that reads as
  one control even though what it reveals is two forms.
- **Whether Artist gets its own board rather than a state of 178.** Drawn here as an inset,
  because it shares the chassis. If the Role/Country/Following block grows, it wants 181.
- **The Tracks field's second life.** A count today. If it should later accept a pasted
  running order, the field is where that lands, and the board should say whether it is a
  single line or a growing list.
- **Whether 180 keeps the `10pt` toggle at all.** 144 dropped 33's toggle for a plain
  `HALF STEPS` label. Two precedents, one column.
- **The plays pill's figure.** `41 plays` is `Kati.Music.Track.plays` summed, or the count of
  `Listen` rows — the two disagree after a scrobble import, and `Track`'s own moduledoc says
  *"neither can be reconstructed from the other."* Pick one and print its noun.
- **179's third scope chip pair.** Five chips is the most any chip row in Kati carries. If
  the row must scroll, say which chips are pinned.
- **Screen 21's empty card copy.** The film shelf's says *Add a title*; music's noun is not
  settled.

## Acceptance — how we know the drawing is complete enough to build from

- 178 draws **both** Kind states — Album with its five fields, Artist with its four — and
  the Kind row on all three of 154, 155 and 157 carries four chips with the same glyphs.
- 178's refusal is drawn with the sentence, the ring and the live button, so
  `Kati.WriteContractTest`'s contract has a picture.
- 179 draws at least one result row already added and one not, as 06 does, and its result
  eyebrow's count matches the rows drawn under it.
- 179's *Add it by hand* row is drawn as a control with a destination, not as the unwired
  row 89 carried for months.
- 180 draws the fifth star **outlined**, and prints `4.5` beside it.
- 180 carries a visible annotation naming the four things it does not have — spoilers,
  `Where`, `With`, rewatch — and why.
- The empty Music shelf is drawn once, in 27's manner, so
  `Kati.ScreenEmptyDatabaseTest` has a board to compare against.
- Every literal a sweep will read is on the board: every label, every `optional` marker,
  every eyebrow, every info sentence. `Kati.ScreenDesignLiteralTest` asserts them against
  the rendered tree, and a literal that only lives in the caption is a literal the screen
  will be built without.
- No symbol name appears that is not already in `Kati.Icons`.

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
