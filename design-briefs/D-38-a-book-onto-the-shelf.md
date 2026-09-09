# The shelf, and how a book reaches it — in both languages

> **Mixed — two new boards and six edits** · ticket `D-38`

One brief for two gaps, because they are the same place failing at opposite ends. In
English there is a Books shelf and **no drawn way to put anything on it**. In Persian
there is a way in and **no shelf to arrive at**. Filing them apart would mean drawing a
Persian shelf for books no Persian user can add.

## The problem it solves, stated plainly

A person wants to add a book they are reading and see it on the shelf. Today neither
end works. The `+` on screen 20 opens screen 06, whose filter row is drawn as exactly
three chips — `Everything | Films | Series` — and whose own caption defers the rest in
writing: *"later the same sheet adds a book, an album or an event"*. The rescue row at
the bottom of 06 and 89 now goes somewhere — `Kati.Screens.AddByHand`, boards
154–157 — and that form offers `Kind: movie Film | live_tv Series` and nothing else.
So there is no control anywhere in the 166 that creates a `Kati.Books.Book` row; the
only writer the resource has is a backup restore, `Kati.Backup.Catalog`. On a real
device screen 20 is therefore a photograph of six books nobody owns, and screen 66
falls to `Kati.Books.Sample.detail/0` under every cover. In Persian it is worse: 57's
کتاب‌ها segment has no shelf to open, so `Kati.Screens.LibraryFa` pushes
`Kati.Screens.BookDetailFa` and the tab drops the reader straight into one fixture
book — سالنامه نمک — with no grid, no chips, no Reading-now hero and no list to come
back to. One answer constrains the other: whatever the Book kind adds to the hand-add
form is exactly what the Persian shelf's tiles, chips and hero then have to print.

## What to draw

| Board | What it is | What it carries |
|---|---|---|
| **176** — کتاب‌ها, the Persian Books shelf | **NEW**, root | 57's page with 20's substitutions: the Reading-now hero in place of the three quick tiles, book chips, a 3-across grid of radius-6 jackets. The destination 57's کتاب‌ها segment has never had |
| **177** — Add by hand, **Book** | **NEW**, pushed | 154's form in its third Kind. Author, Edition, Length or Duration, and the book statuses — drawn with **Book** chosen so the book-only fields are visible, the way 154 is drawn with Series chosen for the same reason |
| **06** — Add a title | edit | a fourth chip on the filter row, and the caption's promise partly kept. **06 still cannot find a book** — see *What it must NOT do* — so the chip's honest resting state is the one that hands off to 177 |
| **20** — Books shelf | edit | the **empty shelf**, which no board in the 166 draws. Every device has one and the app has never been shown it |
| **89** — Search, result states | edit | the *nothing anywhere* band redrawn under the **Books** scope: the outward lookup pill cannot say TMDB for a book, and `or add it by hand` must arrive at 177 with Book already chosen |
| **154** — Add by hand | edit | a third Kind chip, `menu_book Book` |
| **155** — resting & refused | edit | the third chip in both bands; the *Where Add to library goes* annotation gains its book answer (**66**, beside 04 for a series and 08 for a film); the defaults band restates that **Film is still the default** |
| **156** — افزودن دستی, RTL | edit | the third chip as **کتاب**, and the Persian labels for whatever 177 adds |
| **157** — Add by hand, dark | edit | the third chip. The one new recipe is a **mono field trough** (ISBN), and 157's caption already settles the trough — `#2A2826` with a hairline |

## Every element

### 177 — Add by hand, Book

| Band | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Add title` | 154's chrome unchanged; 44pt, radius 22, `#FBFAF8` | `arrow_back_ios_new` |
| Heading + subtitle | *Add by hand* / *"For something Kati could not find. The title is the only thing it needs."* — unchanged | — |
| **Title** field | the one required value; ink inset ring and orange caret when focused | — (label-only trough) |
| **Kind** chips | now three. Film, Series, **Book**; Book lit on this board | `movie` · `live_tv` · `menu_book` |
| **Author** field, `optional` | `Kati.Books.Book.author`. The byline 20's hero prints and 66 repeats. `Kati.Screens.Books` names its absence as one of the two things that keep that hero from moving, so this field is what fills it | — |
| **Year** field, `optional` | the field already drawn, reading `published_year` for a book | — |
| **Edition** chips | `Paperback · Ebook · Audiobook`, reused verbatim from 66's Edition band, label-only. This chip decides the next field | — |
| **Length** field, `optional` | pages under Paperback/Ebook, hours-and-minutes under Audiobook. **One field, never both** — the label restates the unit on switch exactly as 66 does | — |
| **ISBN** field, `optional` | DM Mono, typed. Nothing else in the app can ever write `Kati.Books.Book.isbn`, and 66 and 69 both draw it | — |
| **Status** chips | the book vocabulary, not the film one: *Watching* is wrong under a book. Default **Not started** | — |
| **Add to library** | primary button, 54 tall, ink fill. **One per screen** | — |
| Refusal | 155's sentence and red inset ring, unchanged: name what is missing, then *nothing was written* | `error` |
| Closing note | the honest sentence, rewritten for a book: a hand-typed book carries **no cover and no page count** unless you gave one | `info` |

### 176 — کتاب‌ها, the Persian Books shelf

| Band | Purpose | Glyph |
|---|---|---|
| Header | کتابخانه at **27px/700 with `letter-spacing: 0`** — 57 drops 20's 28px and its `-.03em`, because Persian does not take negative tracking — and the count line under it in **Vazirmatn 11.5 `#A9A29A`, margin-top 5**, not 20's DM Mono 11 | — |
| Two header discs | search and sort, 44pt, `#FBFAF8`, mirrored to the left edge | `search` · `sort` |
| Segmented trough | نمایش · **کتاب‌ها** · موسیقی on `#E4E0D9`, کتاب‌ها lit — the control 57 already draws, with the second segment finally landing somewhere | `movie` · `menu_book` · `graphic_eq` |
| **Reading-now hero** | the card that replaces 57's three quick tiles: 74×110 jacket, `Reading now` eyebrow in Persian, title, author, a 5px rail, and the progress line. Copy is `Kati.Books.SampleFa.detail/0` verbatim — سالنامه نمک · اینس کارول · `ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز` — so 176 and 69 cannot disagree | — |
| Hero's two controls | ink pill **ثبت پیشرفت** (screen 72's own name) and a disc beside it | `add` · `timer` |
| Count chips | همه · در حال خواندن · تمام‌شده · *(to read)*, with Persian digits in the count | — |
| Grid | 3 across, weighted rather than fixed at 112 (`Kati.Screens.LibraryFa` gives the arithmetic), jackets at **radius 6**, a 4px rail on **every** cover including the ones at 0% | — |
| Tile captions | title Vazirmatn 12.5/700 margin-top 9; second line Vazirmatn 11 `#A9A29A` margin-top 3 — 57's, not 20's | — |
| Dock + FAB | root chrome: four dock glyphs with `grid_view` lit, and the ink FAB | `home` · `calendar_month` · `grid_view` · `bar_chart_4_bars` · `add` |

**Every glyph named above is already in `Kati.Icons`.** Keep it that way.
`test/design/material_symbols.codepoints` is not in the repo and never was, so
`mix kati.gen.icons` cannot subset a symbol the app does not already ship — a new glyph
on these boards blocks the build in a way nothing else here does.

## States

- **Resting** — 177 with Book chosen and the book fields visible; 176 with the hero, four
  chips and six jackets.
- **Empty** — the one that matters most, and the one nothing in the 166 draws. Screen 20
  renders `Kati.Books.Sample.books()` unconditionally, which is why
  `Kati.ScreenEmptyDatabaseTest` passes today without ever seeing an empty shelf. Draw it
  for **both** 20 and 176: 27's recipe — glyph, title, one sentence, one action — with
  `menu_book`, and the action being the door this brief draws. An undrawn empty state here
  is an untested one on every fresh install.
- **Active** — the lit Kind chip on 177 and the lit segment and chip on 176. On 176 the lit
  chip must be one that has results; 89's third band is the drawn argument for why.
- **Error** — 177's refusal is 155's, unchanged in shape: the field keeps its caret and takes
  the red inset ring, the button is **never disabled**, and the sentence ends in *nothing was
  written*. There is one new refusal to word: adding a book already on the shelf.
  `Kati.Screens.AddByHand.refusal/2` already turns Ash's *"Has already been taken"* into a
  sentence about the title rather than the column, and a book needs the same sentence.

## RTL

Yes, and it is half the brief. **176 is the mirror**; there is no new English shelf here, only
20's empty state.

- The whole grid mirrors: `dir="rtl"`, header discs to the left, segmented trough reversed so
  نمایش sits at the leading right edge.
- **Artwork never mirrors.** A jacket is a photograph. `Kati.Screens.LibraryFa` states it and
  `Kati.Screens.BookDetailFa` states it again for the stars.
- **The vertical order never reverses.** Header, segments, hero, chips, grid — top to bottom,
  in that order, in both languages.
- **The progress rail fills from the right**, because progress follows reading direction. It is
  a `Row` with a weighted fill and a weighted remainder, not an absolutely positioned box.
- 176 is a **root**, so there is no back pill to flip. On **156** the back pill's glyph is
  `arrow_forward_ios` and stays so.
- Digits are Persian, the year is **Shamsi** — 156's caption is explicit: *۱۴۰۳, not 2024* — and
  anything the English board sets in DM Mono is set in Vazirmatn at the mono size and colour, so
  the columns still align. `kati_mono.ttf` carries no Persian digits.
- Titles and authors transliterate on the fixture only. `Kati.Books.SampleFa`: *"the sample
  transliterates title and author — the user's own note text is never touched."*

## Dark

**Not needed for 176.** No shelf in the 166 has a dark board — 03, 20, 21 and 57 all rely on the
token swap that 28 and 68 pin, and a fifth shelf does not change that argument.

**Needed for 177, and it is one board's worth of edit rather than a new board.** 157 already
exists and takes the third chip. The single decision dark introduces is the **ISBN field's mono
trough**, and 157's own caption has already made it: the inset trough goes `#2A2826` with a
hairline rather than inverting to card colour, *"so a field still reads as a hole rather than a
raised surface"*, and the orange caret is unchanged.

## Reuse, do not invent

Nothing on either board is a new recipe.

- **176 is 57's page with 20's three substitutions.** 20's caption is the whole method — *"built
  from the identical parts — only the aspect ratio, the progress unit (pages, not episodes) and
  the hero card change. Nothing was redesigned to get here."* 176 is that sentence applied once
  more, to 57.
- **The hero** is 20's Reading-now card; its copy is `Kati.Books.SampleFa`'s, already written.
- **The segmented trough, the count chips, the grid and the dock** are 57's, untouched.
- **The empty state** is screen 27's, whose shape is `icon / title / body / action / secondary`.
- **177 is 154**, with one chip added and the film-only fields swapped for book ones.
- **The Edition chips** are 66's three, label-only, in 66's order and 66's spelling — `Ebook`,
  not *E-book*.
- **The refusal** is 155's, which is 95's empty-save sentence in a different sheet.
- **The Kind chip** for Book is the `menu_book` glyph the Books segment already carries on 20,
  57 and 03 — one glyph meaning *book* everywhere in the app.
- A **chevron means leads elsewhere**. Do not put one on a row that does not push a screen.

## What it must NOT do

**Do not draw a cover placeholder on 177.** `Kati.Screens.AddByHand`:

> No `CachedTitle` is invented alongside it: a hand-typed title has no poster and no episode
> list, and the board says so in as many words rather than drawing a placeholder that implies
> one is coming.

A book typed by hand has no jacket. The board says so in words; it does not draw a grey
rectangle that promises one.

**Do not make Book the default Kind.** `Kati.Screens.AddByHand`:

> Board 155 says so in as many words — *"Resting — empty, Film, nothing assumed"* … A form that
> assumed Series would be assuming the answer to its own second question.

177 is *drawn* in Book for the same reason 154 is drawn in Series — so the fields are visible —
and 155's resting band stays Film.

**Do not put a page count and a duration on the same book.** `Kati.Books.Book`:

> An audiobook has no pages and a paperback has no runtime … Storing both and showing one would
> let an edition switch silently keep a stale figure, so `format` is what decides which of
> `page_count` and `duration_minutes` is meaningful.

One extent field, whose label and unit follow the Edition chip.

**Do not require a page count.** Same moduledoc: *"`page_count` is nullable on purpose."* A book
with none draws no bar and no denominator — `Book.fraction/1` answers `nil` rather than `0.0`,
because a bar pinned at zero says *you have read none of it*. The field is an offer, marked
`optional`, exactly as *Total episodes* is on 154.

**Do not offer Paused or Did-not-finish on the add form.** `Kati.Books.Book`:

> `:not_started` is the default, and the four the control offers are the four you can move *to*.

Those four belong to 66's status control. A book you are adding has not been paused.

**Do not let 06's Books chip imply Kati can find a book.** `Kati.Screens.AddTitle`:

> This sheet searches titles the user does **not** have, and Kati has nothing that can answer
> such a query.

There is no Open Library client anywhere in `lib/` — the one metadata client is `Kati.Media.Tmdb`,
and `Kati.Books.Book.source` accepts `:open_library` for a fetch nothing performs — and building it
is a code ticket, not this brief. The Books chip's honest states are *nothing
found* and the hand-add door beneath it.

**Do not make 89's Books scope offer TMDB.** `Kati.Screens.SearchResultStates`:

> The `add` pill goes outward to TMDB and the line under it goes to the manual path, in that
> order, because a title Kati has never heard of is likelier to be findable than to be worth
> typing out.

For a book that order inverts, because the outward half does not exist. Under Books the manual
path is the offer.

**Do not recount the shelf's header.** `Kati.Books.Sample`:

> The shelf says **64 books** while it draws six covers, and the chip says **All 64** — a shelf is
> a window onto a library, not the whole of it.

176's `۶۴ کتاب · ۲ در حال خواندن` is the drawing's figure, as `Kati.Screens.LibraryFa` already
insists for 57: *"The drawn counts are the drawing's, and only the drawing's."*

**Do not draw the Goodreads import as the empty shelf's way out.** 140 → 141 → 37 is fully drawn
and `Kati.Screens.ImportRecognised` sits on `Kati.Import.Sample` and writes nothing. Pointing a
brand-new empty state at it would promise a write that does not happen.

**Do not redesign the shelf.** 20 exists and is built; this brief adds one state to it.

## Left open — decide and note which way you went

1. **The Persian word for the *To read* chip.** `شروع نشده` exists (156's status chip, and
   `Kati.Screens.LibraryFa.meta/1`), but 20's chip says *To read*, which is a different register
   from *not started*. Pick one and use it on both 176 and 177.
2. **How many Status chips 177 offers** — the three 154 draws (Not started / Reading / Finished),
   or all five `Kati.Books.Book.status` holds. Three is the reuse; five is the truth.
3. **Whether ISBN is on the form at all.** Nothing else can write it, so leaving it off means a
   hand-added book's ISBN row on 66 is blank forever. Typed either way — no book-scanning path
   is drawn anywhere, and the three boards using `qr_code_scanner` are plan and backup import.
4. **Whether Edition is on the form or left to 66.** Off the form, a hand-added audiobook cannot
   say `11h 20m` until the reader visits 66.
5. **A fourth chip, or a scrolling row, on 06.** The filter row is three fixed chips across a
   402pt frame; *Everything | Films | Series | Books* is tight, and the caption promises albums
   and events after this.
6. **Where *Add to library* lands for a book** — 66, or back to the shelf that now has it. 155's
   annotation answers this for films and series and must answer it for books too.
7. **What the empty shelf's secondary line says**, given the previous section rules out the
   import chain.
8. **Whether 69's back pill re-points at 176.** `Kati.Screens.BookDetailFa` records the parent as
   inferred — *"There is no Persian Books shelf in the 127, so the back pill names the shelf that
   exists."* Once 176 exists that sentence is stale, and 69 is a redraw this ticket reserves no
   number for.

## Acceptance

The drawing is complete enough to build from when:

- **176 and 177 exist as 402×874 `IOSDevice` artboards** and every literal on them is real text
  in the frame — `Kati.ScreenDesignLiteralTest` asserts each one against the rendered tree.
- **Every glyph on both boards already appears in `Kati.Icons`.**
- **176 is drawn as a root**: dock present, `grid_view` lit, frame closing at 132, no back pill.
- **177 is drawn as a pushed screen**: back pill `‹ Add title`, no dock, frame closing at 40.
- **The empty state is drawn for both 20 and 176**, so `Kati.ScreenEmptyDatabaseTest` has
  something to compare a fresh install against.
- **All four Kind chips read the same across 154, 155, 156 and 157** — three chips on each, with
  156's third reading کتاب.
- **176's hero copy matches `Kati.Books.SampleFa.detail/0` character for character**, so 69 and
  176 tell one story.
- **Every extent on the boards names its unit**, and no board shows a page count and a duration
  together.
- **Each chevron leads to a board that exists**, and no new row promises a screen this brief does
  not draw.
- **The header title and its subtitle carry stated sizes, families and `margin-top`** —
  `Kati.ScreenTitleSubtitleTest` reads exactly those three.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. This brief's two
new boards take **176** and **177**; the six edits keep their own numbers.

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
