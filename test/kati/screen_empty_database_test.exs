Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenEmptyDatabaseTest do
  @moduledoc """
  The screens that moved onto Ash draw the right drawing on a fresh install.

  ## The blind spot this closes

  `Kati.ScreenDesignLiteralTest` already asks whether every literal a drawing
  contains is somewhere in the screen's rendered tree. It cannot ask *this*
  question, because it has no say in what is stored when it runs: this suite has
  no Ecto sandbox — `test/test_helper.exs` migrates one SQLite file and every
  test shares it — and several tests insert rows that outlive them.
  `Kati.Seeds` in particular writes **the design's own values** as real rows.

  So for a migrated screen that sweep passes either way: the literals are there
  whether the screen fell back to its Sample module or read the seeded rows back
  out of Ash, and which of the two happened moves with `--seed`. A screen that
  lost its fallback would keep passing it, and the first thing to show the
  defect would be a blank frame in the next capture.

  This file pins the other half by rendering those screens against a database
  that is empty **for certain**.

  ## Which drawing an empty screen is compared with

  Until #91 there was one answer for every screen here: **its own**. Every
  drawing was captured from a Sample module, so a screen with nothing stored had
  to keep drawing that Sample or it could not be compared with anything.

  That is still true of most of this list, and it is what `fallbacks/0` gates.
  It is no longer true of the four roots. A fresh install that fabricates the
  user's own content is the app lying about the one thing it exists to hold —
  #91 is one sentence of the owner reading exactly that off his own phone — so
  `Kati.Screens.Library`, `Kati.Screens.Home`, `Kati.Screens.Stats` and
  `Kati.Screens.Calendar` now draw their real emptiness, and each screen's
  moduledoc carries the argument.

  A root therefore has **two** drawings, and this file compares it with the
  second one. Three shapes, and every screen here is in exactly one of them:

    * **it falls back** — the drawing it draws when empty is its own. The
      original contract, and still the answer for over a hundred screens.
    * **it has an empty board** — `@empty_boards`. Home draws screen 139 whole;
      Library draws the *Empty — nothing added yet* band of screen 27, which is
      a reference sheet of four specimens and is therefore read a band at a time
      (`Kati.DesignLiterals.band/3`).
    * **the design draws no empty board for it** — `@no_empty_board`. Screens
      02, 07, 28 and 55: no artboard in the 152 draws a Schedule with nothing on
      it, a year with nothing counted, a **dark** Home with nothing kept, or a
      **Persian** one. Their cards are built out of the boards that *do* word
      those states, so what is compared is the QUOTATION — `@quoted` — plus the
      shape floor `@undrawn` uses. Their own suites,
      `Kati.ScreenCalendarEmptyStateTest`, `Kati.ScreenStatsEmptyTest`,
      `Kati.ScreenDarkWidgetsTest` and `Kati.ScreenHomePersianEmptyStateTest`, hold
      the rest and are named in the entries.

  The populated half of all four is not lost with the fallback:
  `Kati.ScreenDesignLiteralTest.drawn_state/0` puts each one in the state its own
  board draws and compares it there, which is the same tree it compared before.

  ## Which screens, and who decides

  Every screen that can reach the store, derived rather than listed by hand —
  see `@migrated`. The screen a migration lands on and nobody remembers to add
  here is precisely the screen whose fallback has never been exercised, so the
  list is checked against each screen's own compiled import table in both
  directions.

  ## What "draws the right drawing" is asked twice

  Once of the tree — every literal and every Material Symbol the drawing holds
  is somewhere in what was rendered — and once of the screen's own entry point,
  which must answer to the term. The first can be satisfied by copy that happens
  to live in the chrome; the second cannot, and it is what makes "the fallback
  exists" a claim a run settles rather than one a moduledoc asserts.

  There are two entry-point gates, because there are now two right answers:

    * `fallbacks/0` — the read must answer with the screen's **drawn** value.
    * `empties/0` — the read must answer with its **empty** value, and must not
      answer with the drawn one. That second half is the #91 guard: it is what
      fails the day somebody puts `case shelf() do [] -> drawn_titles()` back.

  Either way a `for` over a list says nothing about a screen the list omits.
  `@migrated` cannot go stale — it is pinned against the compiled call graph in
  both directions — so the way this file loses a guard is a screen that joins
  `@migrated` on the round it migrates and is given no gate at all: rendered,
  passing every literal check, and its branch taken on trust. The two gate lists
  are therefore pinned against `@migrated` in both directions too, and by
  number, so a gate cannot drift onto the wrong screen either — and against each
  other, so a screen cannot be in both.

  ## How the database is made empty

  Inside one transaction that is always rolled back: every table is emptied,
  the screens are rendered, and then nothing is kept. `pool_size` is 1 (see
  `Kati.Repo.init/2`) and this module is `async: false`, so the test process
  holds the only connection for the duration — the renders read through it and
  see the empty state, and the rows every other test depends on are still there
  afterwards.

  Emptiness is asserted twice over, at both levels the screens actually use:
  `count(*)` per table through Ecto, and an `Ash.read!` per resource, because
  the screens read through Ash and it is Ash's answer that has to be empty.

  Both of those are claims about zero, and every claim about zero is satisfied
  by a database that was empty to begin with — a `DELETE` that never ran
  against a table nobody listed would pass all of them. So one test writes rows
  first and asks the same questions of rows it knows exist: seen outside the
  transaction, gone at both levels inside it, and there again after the
  rollback.
  """
  # `async: false` is a requirement rather than caution, three times over: the
  # renders switch `Kati.Locale`, which is global; the transaction below holds
  # the pool's only connection; and emptying every table is not something to do
  # beside a test that is inserting.
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.ScreenSweep

  # Every screen that reads the database, by the design number its drawing is
  # filed under. **Not a hand-kept list of what moved**: "the screens the
  # migration moved" is a fact about one round of work and rots the round after,
  # and the question this file asks is the timeless one — *can this screen still
  # draw itself when the store is empty*. So the list is pinned from both sides
  # by "every screen that can reach the database is in the list" below, which
  # reads each screen's own compiled import table: a screen that starts reading
  # Ash and is not added here fails, and an entry here for a screen that reads
  # nothing fails too.
  #
  # **14 and 35 have both moved, and this comment used to say why neither had.**
  # The reason given for 35 was that half of it would become the reader's own
  # and half would stay a picture. That rule is right and it named the wrong
  # unit: the half with no schema is two whole GROUPS — *Region & availability*
  # and *This show* — and a group with nothing behind it is dropped rather than
  # drawn dead, which is the shape 14's own bands settled. So over a real show
  # 35 is the Status tiles and the Season pass and nothing else, and over no
  # show it is board 35 whole. See `Kati.Screens.SeriesSettings.show/1`.
  #
  # **04 and 58 have moved, and this comment used to explain why they had not.**
  # The reason given was that `Kati.Media` cannot enumerate a season or name an
  # episode, which stopped being true when
  # `20260821231241_media_seasons_and_episodes` created `cached_seasons` and
  # `cached_episodes`: `Kati.Media.CachedEpisode` carries `title`,
  # `runtime_minutes`, `air_at` and `episode_number` with `for_season/3` and
  # `for_title/2` to read them, and `Kati.Media.CachedSeason.for_title/2` and
  # `count/1` are the season strip and its `3 SEASONS`. Both screens' moduledocs
  # still asserted the old blocker after it was gone, and one of them cost a
  # round; both now say what they read instead. 58 reaches the store the way a
  # mirror should — through `Kati.Screens.Series.tracked_series/0`, not a second
  # copy of the query — so it is in this list transitively and by design.
  #
  # **05 and 34 moved on the same round, and 34 moved only PARTLY.** Screen 05
  # draws both of its lists out of `Kati.Media.CachedEpisode`,
  # `Kati.Media.CachedSeason` and `Kati.Media.Release`, and keeps its watcher
  # card frozen because two of that card's three values have no store anywhere.
  # Screen 34 draws its episode list, its heading and its count, and keeps the
  # order strip, the two switches and the `PARTS 1–2` badge drawn — those are
  # columns that do not exist rather than queries nobody wrote, and
  # `Kati.Media.CachedEpisode.orders/0` answering `[:aired, :absolute]` is the
  # DVD tile's own reason.
  #
  # A partly-migrated screen is exactly the shape this file has to be careful
  # about: its gate must answer with the drawn value *whole* on an empty
  # database, frozen parts and all, which is what `fallbacks/0` compares. Both
  # therefore lay their real values over `drawn_*/0` rather than building a
  # fresh map, so the two branches cannot differ in a key neither side names.
  @migrated [
    # 01, 02, 03 and 07 are the four roots, and they are the four screens in
    # this list that no longer answer an empty store with their own drawing —
    # see the moduledoc's *Which drawing an empty screen is compared with*, and
    # #91 for why. Each is still here for the reason every other screen is: it
    # reaches the store, so what it draws when the store is empty is a thing
    # that can regress. What changed is only which drawing it is compared with
    # (`@empty_boards`, `@no_empty_board`) and which gate it answers to
    # (`empties/0` rather than `fallbacks/0` — except 01, whose `rest_of_today/1`
    # still substitutes and says so at its own definition).
    #
    # 01 and 02 were reading the database before that round and were never in
    # this file until it was written; the screens most likely to be captured
    # were the two the check was not covering.
    {"01", Kati.Screens.Home},
    {"02", Kati.Screens.Calendar},
    {"03", Kati.Screens.Library},
    {"04", Kati.Screens.Series},
    # 14 joined when *Show details* started describing the show you opened it
    # over. It reads the shelf and the cache the way 04 and 08 do, and gates
    # the whole page on the same rule: either every value is this reader's or
    # every value is the board's. What it does NOT read is a person, an offer
    # or a tag on a title — there is no resource for any of them, so on a real
    # series those three bands are `[]` and the page is shorter rather than
    # borrowing the board's.
    {"14", Kati.Screens.SeriesMeta},
    # 12 joined with #106. Two of its four *Kept automatically* rows are the
    # reader's own counts now — `Rewatches` is a `Kati.Media.Watch` carrying a
    # `rewatch_number` and `Abandoned` is `status: :dropped` — where all four
    # were the drawing's numbers on every device. `Rewatches · 0` on an empty
    # store is a true answer, so the page falls back to its own board for
    # everything else and this file compares it there.
    {"12", Kati.Screens.Lists},
    {"152", Kati.Screens.AnimeFilter},
    {"05", Kati.Screens.Inbox},
    {"07", Kati.Screens.Stats},
    {"08", Kati.Screens.Film},
    # 09 and 31 joined on 26 August with #84, and both fall back on the same
    # trigger: **the push said nothing about which one**. 09 draws the day it
    # was handed and 31 the event it was handed, so a bare push — which is what
    # this file's renders are, and what `Kati.Screens.ViewSwitcher` sends 09 —
    # is the branch that answers with the drawing. That is a different trigger
    # from every other screen here, whose fallback fires on the store being
    # empty; the two gates below say which they are asking.
    {"09", Kati.Screens.Day},
    {"31", Kati.Screens.EventDetail},
    # 52 joined on 5 September with the same trigger and for the same reason.
    # It read `Kati.Calendar.SampleMealDay` unconditionally, so every route in
    # landed on `Mon 17 Aug` and the page's own title was the one thing on it
    # that could never be wrong because it was never right. Now `day/1` reads
    # the date `Kati.Screens.Calendar` hands it, and a bare push — this file's
    # renders, and the ⋯ menu's own row until it carries one — is the branch
    # that answers with the drawing.
    {"52", Kati.Screens.MealsDay},
    {"10", Kati.Screens.UpNext},
    # 98, 100 and 101 joined when the share card stopped being a fixture. Every
    # figure on it was `Kati.Stats.ShareSample`'s — `312h 40m`, `↑ 18%`, three
    # titles nobody had watched — on a device where screen 07 one tap earlier
    # drew the reader's own year (MOVIES-AND-TV.md #79). A share card is the
    # one page whose whole purpose is to leave the device, so a fixture on it
    # is a fixture somebody posts. 100 and 101 draw 98's own card.
    {"98", Kati.Screens.YearShare},
    {"99", Kati.Screens.YearShareBooks},
    {"101", Kati.Screens.YearCardsStates},
    # 86 and 87 joined when the *Try* group stopped being two fixed strings.
    # Board 86's caption says the two suggestions are *drawn from what you
    # actually have* and they were `what leaves this week` and `notes about the
    # estuary` — queries that match nothing on any device but the one the board
    # was captured on (MOVIES-AND-TV.md #72). 87 is here because it draws 86's
    # own chip row and reaches the read through it.
    {"86", Kati.Screens.SearchIdle},
    {"87", Kati.Screens.SearchTyping},
    # 25 joined when its cream banner stopped claiming `Watching 24 titles · 3
    # FOUND THIS WEEK` on every device. Both halves are counts of the reader's
    # own library, through the same `:followed` read screen 05 uses; a device
    # following nothing keeps the board's line, because `Watching 0 titles`
    # over a page of switches is a page about nothing.
    {"25", Kati.Screens.ReleaseWatcher},
    # 145 joined when the sort disc's sheet stopped being a picture. It reads
    # the shelf twice — once as it stands and once with nothing selected — so
    # `showing N of M` is two numbers about this reader rather than board
    # 145's `41 of 418`. An empty shelf has neither, so it draws the board
    # whole, which is the state the board is a drawing of.
    {"145", Kati.Screens.ShelfFilters},
    # 167 is 145's sheet with Up next's vocabulary, and it joined for 145's
    # reason: it reads the queue twice — once as it stands and once with no
    # chip lit — so `showing N of M` and every chip's badge are counts of what
    # this reader is actually watching. A device with nothing on the go has
    # neither, so it draws board 167 whole, which is the state the board is a
    # drawing of.
    {"167", Kati.Screens.UpNextFilters},
    # 23 joined when it stopped quoting four services and £46.47 a month at
    # every reader. It gates the page whole — either the ledger is yours or it
    # is the board's — because a page with your one service in it and the
    # drawing's other three under it reads as entirely real.
    {"23", Kati.Screens.Subscriptions},
    # 18 joined when its field, its parse card and its commit button stopped
    # being one sentence somebody typed into a design tool. It reads the
    # calendar for the clash — `Kati.Calendars.Today.timed/1` — and writes an
    # event on commit. An empty field draws board 18 whole, which is the state
    # that board is a drawing of: it is captured MID-TYPING, and its sentence
    # is the clearest statement of the syntax this screen has.
    {"18", Kati.Screens.QuickAdd},
    # 146 joined when selection mode stopped selecting nine invented titles.
    # It reads the shelf through `Kati.Screens.Library.shelf/0` — one shelf,
    # one reader — and gates it whole: a grid of the reader's own posters with
    # the board's two tiles highlighted inside it is a page that looks
    # entirely real and is half a drawing. An empty shelf keeps board 146.
    {"146", Kati.Screens.ShelfSelection},
    # 11 joined when its first band stopped being a fixture. It gates the whole
    # feed the way 04 gates its page: an empty store has nothing to recommend
    # FROM, so it draws board 11 whole. A store with a title in it gets one
    # section — the picks, under the title they came from — because the other
    # two need a person resource and an offers resource, neither of which
    # exists. `Kati.DiscoverFeedTest` holds that half.
    {"11", Kati.Screens.Discover},
    {"15", Kati.Screens.Activity},
    # 32 moved its "which calendars show" group onto `Kati.Calendars.Calendar`
    # and 42 its hero and meal row onto `Kati.Meals`. Both keep the rest of
    # their copy on a Sample module and say which parts and why in their own
    # moduledocs — `Kati.Screens.Habits` (22) and `Kati.Screens.Subscriptions`
    # (23) are absent here for the same reason 04 and 05 are: no habit
    # completion, no price, nothing to fall back FROM.
    {"32", Kati.Screens.Calendars},
    # 34 is the one screen in this list that is only PARTLY migrated — see the
    # note above. It is here for the ordinary reason: it reaches the store, so
    # its fallback is a thing that can regress.
    {"34", Kati.Screens.Season},
    # 35 is here for the ordinary reason: it reaches the store, so what it draws
    # against an empty one can regress. Its gate is the whole `show/1` map,
    # because the two groups it drops over a real show are keys in that map —
    # a gate that compared only the status would pass while the page went bare.
    {"35", Kati.Screens.SeriesSettings},
    # 13 joined when its window started filtering something. Its own moduledoc
    # had already recorded that three of the four things blocking it stopped
    # being blocked when `Kati.Media.CachedEpisode` was built; the fourth is a
    # mood — `Kati.Media.Watch.moods` is real and nothing writes it, so it is
    # `[]` on every device — and the chips are dropped over a real list rather
    # than drawn dead. On an empty store there is nothing that
    # fits and no film that does not, so the page is board 13 whole.
    {"13", Kati.Screens.WhatFits},
    # 37 joined the round the importer was built. It reads the shelf to decide
    # what a file would do to it — new, merged, or a conflict with a rating
    # already stored — and on an empty store there is nothing to merge into and
    # no file to read, so it answers board 37 whole.
    #
    # 120, 140 and 142 briefly joined with it and should not have. They read
    # nothing; they borrowed a `Box` and a step bar from this module, and this
    # file's derivation closes over the compiled import table, so sharing
    # markup with a module that had just gained a database made three screens
    # into store readers. The chrome moved to `Kati.UI.ImportChrome`, which is
    # where shared chrome goes, and the derivation went back to telling the
    # truth. Worth the six lines: the alternative was three gates asserting
    # that a screen which reads nothing draws its own fixture.
    # 36 joined the round auto-detect was built. It counts the ticks Kati made
    # rather than the reader — `Kati.Media.Watch.detected` since
    # `20260907060000_add_watch_detected` — and matches what is playing against
    # the shelf. On a host there is no bridge, so `Kati.Media.Detect.access/0`
    # answers `:unavailable` and the page is board 36 whole, which is what the
    # gallery and every sweep render.
    {"36", Kati.Screens.AutoDetect},
    {"37", Kati.Screens.Import},
    # 141 joined with it, and reads for the same reason: it describes the file
    # the picker handed over, and `Kati.Import.Job.read/2` counts what that
    # file would do against the shelf. Given no file it answers board 141
    # whole, which is what the gallery and every sweep render.
    {"141", Kati.Screens.ImportRecognised},
    # The two screens the design draws DARK, and the log sheet.
    #
    # 28 is Home in dark and reads exactly what Home reads — `Rest of today`,
    # through `Kati.Calendars.Today` — so its `[]` clause is Home's `[]` clause
    # and is guarded here the same way. Its header stays the drawing's evening
    # on purpose; `Kati.Screens.HomeDark`'s moduledoc gives both reasons.
    #
    # 29's four widgets fall back one at a time rather than as a page, which is
    # why the pair below compares the whole `widgets/0` map: a widget that
    # quietly stopped falling back would leave the other three drawing the
    # drawing and pass every literal check in this file.
    #
    # 33 reads the newest logged watch. It is the one screen here whose
    # fallback fires on a database that is NOT empty — a library full of
    # episode ticks and no rating or review anywhere still has nothing this
    # sheet can draw — so the empty case guarded here is the floor, not the
    # whole of it.
    {"28", Kati.Screens.HomeDark},
    {"29", Kati.Screens.Lock},
    {"33", Kati.Screens.Rating},
    {"42", Kati.Screens.Health},
    {"43", Kati.Screens.MealsToday},
    {"44", Kati.Screens.MealPlan},
    {"45", Kati.Screens.Meal},
    {"47", Kati.Screens.Nutrition},
    {"48", Kati.Screens.Shopping},
    # The Persian mirrors of 01, 02 and 03, reading the same two domains their
    # originals read. They are the first screens in 55-62 to reach a store at
    # all, and they are the ones with the most to lose from losing a fallback:
    # every drawing in that range was captured from its Sample module, and a
    # Persian page that renders empty cannot be compared with anything.
    {"55", Kati.Screens.Home},
    # 56 was `Kati.Screens.ScheduleFa` until mishka-group/kati#103 folded that
    # mirror away. Board 56 is screen 02 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"56", Kati.Screens.Calendar},
    # 57 was `Kati.Screens.LibraryFa` until mishka-group/kati#103 folded that
    # mirror away. Board 57 is screen 03 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"57", Kati.Screens.Library},
    # 58 is 04 in Persian and reads through 04 — see the note above.
    # 58 was `Kati.Screens.Series` until mishka-group/kati#103 folded that
    # mirror away. It is screen 04 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"58", Kati.Screens.Series},
    # 54 reads a store now: its Currency row shows the reader's own currency
    # rather than a literal `£ GBP`. `Kati.Money.currency/0` answers "GBP" with
    # nothing stored, so the line an empty device draws is the line the drawing
    # was captured with — no fallback, no gate, just a real read whose empty
    # answer happens to be the board's.
    {"54", Kati.Screens.Language},
    # 39 reads the shelf now: it previews the one widget that ships, from
    # `Kati.Screens.UpNext.queue/0` — the same hero the Glance widget reads.
    {"39", Kati.Screens.Widgets},
    # The Books domain's three screens, and 66 and 70 are the pair this file was
    # written for: 66 falls back to `Kati.Books.Sample.detail/0` for the whole
    # page, and 70 falls back for the book it is about to write a session
    # against. 70 is also the first screen here that can WRITE — its fallback
    # is what stops a save being aimed at a book that does not exist.
    #
    # 20 is the shelf those two hang off, and it joined on 5 September when its
    # grid moved onto `Kati.Books.Book`. It falls back the way 66 does and for
    # the same reason — one branch for the whole page — because a real grid
    # under the drawing's hero would be the half-migration its own moduledoc
    # argues against.
    {"20", Kati.Screens.Books},
    {"66", Kati.Screens.BookDetail},
    {"70", Kati.Screens.LogProgress},
    # The Music domain's four. 74 and 77 gate the whole page as 66 does; 73
    # gates the album it is about to write a play against, through 74's reader
    # for the reason 70 uses 66's.
    #
    # 21 is the shelf the other three hang off, and it joined on 5 September
    # when its tiles moved onto `Kati.Music.Album`. Same shape as 20 one shelf
    # over: one branch for the whole page, because a rail of the user's own
    # covers under the drawing's `9h 12m` would be the half-migration the
    # screen's own moduledoc argues against.
    {"21", Kati.Screens.Music},
    {"73", Kati.Screens.LogListen},
    {"74", Kati.Screens.AlbumDetail},
    {"77", Kati.Screens.ArtistDetail},
    # 24 and 62 joined this list the moment their Watching group started
    # counting real services: a settings page that says `3 subscribed` is a
    # settings page with a read in it, and its fallback is the drawing's own
    # three.
    {"24", Kati.Screens.Settings},
    # 62 was `Kati.Screens.SettingsFa` until mishka-group/kati#103 folded that
    # mirror away. It is screen 24 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"62", Kati.Screens.Settings},
    {"80", Kati.Screens.DataSources},
    {"92", Kati.Screens.MyServices},
    {"94", Kati.Screens.CountryPicker},
    {"104", Kati.Screens.Goals},
    {"106", Kati.Screens.NewGoal},
    {"122", Kati.Screens.Money},
    {"124", Kati.Screens.QuickAddExpense},
    {"125", Kati.Screens.Currency},
    {"109", Kati.Screens.Weight},
    {"111", Kati.Screens.LogWeight},
    {"112", Kati.Screens.Medication},
    {"116", Kati.Screens.MealLibrary},
    {"118", Kati.Screens.MealEdit},
    {"119", Kati.Screens.AddIngredient},
    # 100 is a reference sheet and draws no user data of its own — its only
    # read is the pixel field it borrows from screen 74, which is where its
    # gate points.
    {"100", Kati.Screens.YearCards},
    # The Persian book pair. 69 reads the shelf ITSELF — `book/1` resolves the
    # `:book_id` it was pushed with through `Kati.Books.Book`'s `:shelf` action
    # — and supplies every value its page draws rather than the Persian chrome
    # over 66's, which is what D-59 changed and what stopped it printing one
    # book's reading under another book's title. Its fallback is a real branch:
    # nothing shelved, or an id that names no row, and both answer with
    # `Kati.Books.SampleFa.detail/0`. 72 resolves its own `:book_id` the same
    # way now, so both gate on the same pair for the reason 70 gates on 66's.
    # 69 was `Kati.Screens.BookDetailFa` until mishka-group/kati#103 folded
    # that mirror away. It is screen 66 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"69", Kati.Screens.BookDetail},
    # 72 was `Kati.Screens.LogProgressFa` until mishka-group/kati#103 folded
    # that mirror away. It is screen 70 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"72", Kati.Screens.LogProgress},
    # The five states-and-dark sheets. Each renders its primary's own reader
    # under a different theme or in a different state, so each gates on that
    # primary's pair — a states sheet whose fallback broke would be showing a
    # picture of a state the app can no longer reach.
    {"67", Kati.Screens.BookDetailStates},
    {"68", Kati.Screens.BookDetailDark},
    {"71", Kati.Screens.LogProgressStates},
    {"75", Kati.Screens.AlbumDetailStates},
    {"78", Kati.Screens.ArtistDetailStates},
    # The six the second wave added on top: two Persian music pages, and the
    # states-and-RTL pairs for Data sources and Attribution. Each gates on its
    # primary's own pair, for the reason every mirror in this list does — a
    # mirror that fell back differently from the page it mirrors would be the
    # defect worth catching.
    # 76 was `Kati.Screens.AlbumDetailFa` until mishka-group/kati#103 folded
    # that mirror away. It is screen 74 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"76", Kati.Screens.AlbumDetail},
    {"81", Kati.Screens.DataSourcesStates},
    # 82 was `Kati.Screens.DataSourcesFa` until mishka-group/kati#103 folded
    # that mirror away. It is screen 80 under `:fa` now — hence its number on
    # `@fa_numbers` below — and it keeps its own row for the reason 97 does.
    {"82", Kati.Screens.DataSources},
    # 85 was here, paired with screen 80's own fallback, for as long as it was
    # `Kati.Screens.AttributionFa`. mishka-group/kati#103 folded that mirror
    # away and board 85 is screen 83 under `:fa` now — and screen 83 reads no
    # store at all, so rendering it against an empty one asserts nothing. Its
    # literals are held by `Kati.ScreenDesignLiteralTest`, whose `@fa_screens`
    # already carries 85.
    {"126", Kati.Screens.MoneyDay},
    # Screen 92's three companions: its empty state, its states sheet, and the
    # board showing what four other screens look like when nothing is set up.
    # All three gate on 92's own pair.
    {"93", Kati.Screens.MyServicesEmpty},
    {"95", Kati.Screens.MyServicesStates},
    {"96", Kati.Screens.NothingSetUpKnockOn},
    # 97 was `Kati.Screens.MyServicesFa` until mishka-group/kati#103 folded that
    # mirror away. Board 97 is screen 92 rendered under `:fa` now — so it is on
    # `@fa_numbers` below, and it keeps its own row here because the board is
    # still a drawing this file renders against an empty store, and because a
    # `for` over `@migrated` would otherwise stop asking the Persian page
    # anything at all.
    {"97", Kati.Screens.MyServices},
    # The Persian search and the two year-card twins. Each gates on the pair its
    # primary gates on, for the reason every mirror in this list does.
    # 90 was `Kati.Screens.Search` until mishka-group/kati#103 folded that
    # mirror away. It is screen 19 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"90", Kati.Screens.Search},
    {"103", Kati.Screens.YearShare},
    {"105", Kati.Screens.GoalsEmpty},
    {"110", Kati.Screens.WeightStates},
    {"113", Kati.Screens.HealthEmptyStates},
    {"107", Kati.Screens.GoalStates},
    {"114", Kati.Screens.RetiredTile},
    {"117", Kati.Screens.MealLibraryEmpty},
    {"123", Kati.Screens.MoneyStates},
    # 115 is the Persian weight-and-doses page, and 61 joined the moment its
    # More numbers rows started counting real goals and services.
    # 61 was `Kati.Screens.StatsFa` until mishka-group/kati#103 folded that
    # mirror away. Board 61 is screen 07 under `:fa` now — hence its number on
    # `@fa_numbers` below — and it keeps its own row here because the board is
    # still a drawing this file renders against an empty store.
    {"61", Kati.Screens.Stats},
    # Screen 120 is deliberately NOT here. `Kati.Screens.PlanImport` draws the
    # import flow entirely from its own literals — no store, no Sample module —
    # so rendering it against an empty database would assert nothing, and the
    # derivation below says so. The render and literal sweeps still cover it.
    #
    # The four pictures. None of these reads anything itself — each is a frame
    # drawn from another screen's `drawn_*` value — and each lands here anyway
    # because the derivation reads the compiled import table, which cannot tell
    # calling `Kati.Screens.Lock.drawn_widgets/0` from calling
    # `Kati.Screens.Lock.widgets/0`. That is the right way round: what these
    # four depend on is precisely that the borrowed pair still agrees on an
    # empty database, and their gates below ask exactly that.
    {"121", Kati.Screens.WeekImage},
    {"63", Kati.Screens.MarkIos},
    {"64", Kati.Screens.MarkAndroid},
    # #25 and #11's screens that reach a store. `Kati.Screens.Backup` left
    # `@undrawn` on 24 August when 128 landed — the comment there says to move
    # an entry the moment its drawing arrives, and this is that move.
    {"128", Kati.Screens.Backup},
    {"131", Kati.Screens.BackupDark},
    {"139", Kati.Screens.HomeEmpty},
    {"144", Kati.Screens.RateEpisode},
    {"149", Kati.Screens.DropSheet},
    # 129 and 135 joined on 24 August, when #25's restore half moved off
    # `Kati.Screens.Backup` and onto the screen its drawing puts it on. They
    # reach the store through `Kati.Backup.restore_file/2` — a tap, not a
    # mount — and 135 inherits the classification through its one reuse of
    # `Kati.Screens.Restore.qr_pattern/0`. Both are here anyway: this list is
    # derived from the compiled import table precisely so that a screen cannot
    # opt itself out by only touching the store on a tap.
    {"129", Kati.Screens.Restore},
    {"135", Kati.Screens.RestoreFirstRun},
    # 26 joined on 26 August, with #82. It reaches the store through
    # `Kati.Calendars.DeviceImport.run/0` on `{:permission, :calendar,
    # :granted}` — a permission answer, not a mount — and this list is derived
    # from the compiled import table precisely so a screen cannot opt itself out
    # by only touching the store on a message.
    {"26", Kati.Screens.PickSections},
    # 06 joined on 26 August with #87, when adding a title stopped toggling a
    # boolean on a socket and started writing a `CachedTitle` and a
    # `TrackedTitle`. It is the first writer the film and TV spine has ever had.
    {"06", Kati.Screens.AddTitle},
    # 19 and 89 joined on 4 September with #92, when screen 19 stopped mounting
    # `Kati.Screens.Search.Sample` unconditionally and started running the
    # query screen 86 hands it. With no query it still draws the board — no
    # board draws screen 19 empty, because the design never puts a user here
    # without one — so the comparison below is unchanged and what it now
    # guards is the fallback.
    {"19", Kati.Screens.Search},
    {"89", Kati.Screens.SearchResultStates},
    # 154 writes rather than reads: what it draws is its own form, and the
    # store is only touched when Add is pressed. It is here because this list
    # is derived from the compiled import table, which is what stops a screen
    # opting itself out by only writing on a tap.
    # 46 joined when its two commit buttons stopped drawing and doing nothing.
    # It reads the slot screen 43 hands it and ranks the meal library against
    # what that slot costs; with no plan there is no slot, and the page is
    # `Kati.Meals.SampleSwap`'s drawing — which is what the comparison below
    # holds it to.
    {"46", Kati.Screens.MealSwap},
    {"154", Kati.Screens.AddByHand},
    # 163 and 166 are the last step of the first run, and they are here for
    # exactly 154's reason: they WRITE on Finish and read nothing. Until
    # 5 September they wrote nothing either — the picked title was drawn with a
    # tick and dropped — so a first run ended on a Home with an empty library,
    # which is the one thing screen 163 exists to prevent.
    {"163", Kati.Screens.OnboardingFirstTitle},
    {"166", Kati.Screens.OnboardingFirstTitle},
    {"155", Kati.Screens.AddByHandStates},
    {"156", Kati.Screens.AddByHand},
    {"157", Kati.Screens.AddByHandDark},
    {"158", Kati.Screens.HomeEmpty},
    {"159", Kati.Screens.HomeEmptyDark},
    {"160", Kati.Screens.HomeOmittedSections},
    # D-43's three. 188 WRITES and reads nothing — it is 154's case exactly,
    # and it is here because this list is derived from the compiled import
    # table, which is what stops a screen opting itself out by only writing on
    # a tap. 189 reads the medication screen 112 named and falls back to its
    # own drawing when that names nothing, which is the branch `fallbacks/0`
    # holds it to. 190 reads nothing at all — it is a picture of screen 112's
    # empty frame and its two destinations — and is on this list only because
    # it draws screen 104's chrome, which reaches Ash; 155 is here for exactly
    # that reason.
    {"188", Kati.Screens.AddMedication},
    {"189", Kati.Screens.MedicationDetail},
    {"190", Kati.Screens.MedicationEmpty},
    # 176 is the Persian Books shelf and it READS: `page/0` is one read of
    # `Kati.Books.Book`'s `:shelf`, and the grid, the header's count line, the
    # four chips and the Reading-now hero are four views of that one answer.
    # Gated as screen 20 is and for its reason — either every value on the page
    # is this reader's or every value is the drawing's.
    # 176 was `Kati.Screens.Books` until mishka-group/kati#103 folded that
    # mirror away. It is screen 20 under `:fa` now — hence its number on
    # `@fa_numbers` below.
    {"176", Kati.Screens.Books},
    # 177 WRITES rather than reads: what it draws is its own form, and the
    # store is only touched when Add to library is pressed. It is here for
    # 154's reason — this list is derived from the compiled import table, which
    # is what stops a screen opting itself out by only writing on a tap.
    {"177", Kati.Screens.AddByHandBook},
    # D-39's three. 178 and 179 WRITE rather than read — each draws its own
    # form or its own transcription of a board, and the store is only touched
    # when Add is pressed. Both are here for 154's reason: this list is derived
    # from the compiled import table, which is what stops a screen opting
    # itself out by only writing on a tap. 180 both reads and writes — it opens
    # on the album screen 74 named it and edits that record's rating and note —
    # so it is gated on 74's own reader for the reason screen 73 is: a sheet
    # aimed at a different album from the screen that opened it would rate the
    # wrong record.
    {"178", Kati.Screens.AddByHandRecord},
    {"179", Kati.Screens.AddTitleMusic},
    {"180", Kati.Screens.RateAlbum}
  ]

  # ── Which drawing an empty screen is compared with ──────────────────────────

  # `screen number => the drawings its EMPTY state is drawn from`. Absent means
  # "its own", which is what every screen here answered before #91 and what all
  # but four still answer.
  #
  # A **list**, because an empty root is not always one board: half of a page
  # can go on being the page it always was. Every drawing named is compared in
  # full and the literals are unioned, so naming a second one can only ever ask
  # for more.
  #
  # `:whole` takes the board end to end. `{from, to}` takes one band of it and
  # names the band by the drawing's own two eyebrows — see
  # `Kati.DesignLiterals.band/3` for why a reference sheet has to be read that
  # way and why a missing anchor raises instead of matching nothing.
  #
  #   * **01 → 139, and 139 alone.** `Kati.Screens.Home`'s empty branch is
  #     `Kati.Screens.HomeEmpty.content/1` *called*, not copied — 139 is a board
  #     in its own right, registered under its own number, and the module that
  #     owns an artboard owns its copy. So Home with nothing stored and screen
  #     139 are the same page, and this compares Home against it: 139's own
  #     entry below then says the same thing about `Kati.Screens.HomeEmpty`, and
  #     the pair is what would fail if Home ever grew a second copy of 139 that
  #     drifted from the first. Board 01 is not named beside it because 139
  #     replaces the whole page, its own search field and eyebrow included.
  #   * **03 → 03 AND 27's first band.** The Library keeps its own board's
  #     chrome and says so: `Kati.Screens.Library`'s moduledoc argues that the
  #     header, the Screen/Books/Music switcher and the three quick tiles are
  #     live with an empty shelf and *"stay exactly as screen 03 draws them"*,
  #     and that only the row of filter chips goes — which the board templates
  #     (`{{ t.label }}`), so no literal leaves with them. Board 03 is therefore
  #     still compared in full. What is added is band one of
  #     `test/design/screens/27.html` — *States*, a reference sheet of four
  #     specimens, whose first is this screen's own emptiness: a `movie` glyph on
  #     a paper square, *No titles yet*, the sentence, an ink *Add a title* pill
  #     and *or import a backup*. The other three bands are loading, offline and
  #     undo, which the Library does not draw and screen 27 itself does.
  @empty_boards %{
    "01" => [{"139", :whole}],
    # 10 → no board at all, the same treatment 12 gets: a shelf with nothing
    # ready or cold draws `empty/0`'s honest card now, not board 10's own
    # hero and four rows, so there is nothing left on this screen for an
    # empty database to be held to.
    "10" => [],
    # 04 and 58 → no board either, the same treatment. `empty_series/0` is the
    # frame with nothing in any slot: no title, no year, no season bar, no
    # primary and no rows, so board 04's own show has nothing left on this
    # screen for an empty database to be held to. The board is still compared —
    # `Kati.ScreenDesignLiteralTest` installs `drawn_series/0` for exactly that.
    "04" => [],
    "58" => [],
    # 08 → no board either, and for the same reason as 04.
    "08" => [],
    # 35 → no board either: an empty page carries no title, and the two bands
    # the board draws are both dropped the moment a real show names itself.
    "35" => [],
    # 98 and 99 → no board either: a year with nothing counted has no hours,
    # no ranked titles, no contribution grid and no genre bars, so what is left
    # of board 98 on an empty store is the card's own frame.
    "98" => [],
    "99" => [],
    # 101 and 103 draw 98's card as well — 101 as its five states, 103 as 98
    # under `:fa` — so both lose the same content.
    "101" => [],
    "103" => [],
    # 13 → no board: nothing fits means no rows and no nearest-over card, so
    # board 13's own four films have nothing left to compare.
    "13" => [],
    # 34 → no board: no episodes, no options and no note, so board 34's own
    # nine rows have nothing left to compare.
    "34" => [],
    # 36 → no board: an unavailable device has no sessions, no now-playing card
    # and no decision, so board 36's own content has nothing left to compare.
    "36" => [],
    # 25 → the banner's own two lines only. Every other band on board 25 is
    # `Kati.Settings.WatcherSample`'s and stays — 13 of its 15 controls have no
    # preferences domain to read (see P2), which is a schema gap rather than a
    # fallback.
    "25" => [],
    # 14 → no board either: no title, no synopsis, no cast, no ratings and no
    # where-to-watch rows, so board 14's own series has nothing left to compare.
    "14" => [],
    # 11 → no board either: no seed means no picks, no people, no leaving-soon
    # rail and no subtitle, so board 11's own feed has nothing left to compare.
    "11" => [],
    # 23 → no board either: no services means no rows, no total and no
    # suggestion, so board 23's own four have nothing left to compare.
    "23" => [],
    # 33 → no board: the sheet's own frame survives — the ten-point scale, the
    # review placeholder, the three context titles and the tag row are the
    # screen's structure — but every VALUE board 33 draws is Blue Hour's, so an
    # unlogged sheet has none of them left to be held to.
    # 29 → no board: the wallpaper, the clock and the four widget frames are the
    # screen's structure and all four still draw, but every VALUE on board 29 is
    # the drawing's, so an empty store has none of them left to be held to.
    #
    # 63 and 64 are NOT here. They are launcher mockups that read nothing —
    # `Kati.Screens.MarkIos.tonight/0` quotes board 29's own Today row and
    # `Kati.Meals.SamplePlan`'s dinner outright — so their pages are the same on
    # an empty store as on a full one. They are on this file's `@migrated` list
    # only because they import `Kati.Screens.Lock`, which is the 120/140/142 case
    # the comment above `@migrated` writes up. Their gate below is borrowed from
    # 29 for that reason: what they depend on is that 29's pair still agree.
    # Making their own two halves real is launcher-widget work — Part 18 of
    # fake_hardcoded.md — and the meal half is out of the film/series scope.
    "29" => [],
    # 37 and 141 → no board: an unpicked file has no name, no shape, no columns,
    # no plan and no conflict, so board 37's `trakt-backup.csv` and board 141's
    # 418 rows have nothing left on either screen to be held to. Both keep their
    # frames — 37 its step meter and its two eyebrows, 141 a worded card.
    "37" => [],
    "141" => [],
    "33" => [],
    # 15 → no board either: nothing logged means no rows, no rewatch card and a
    # count of zero, so board 15's own seven rows have nothing left to compare.
    "15" => [],
    # 39 → no board either: the three phantom tiles and the shortcut rows are
    # deleted, so what is left of board 39 on an empty store is chrome.
    "39" => [],
    # 09 → no board either: an empty day draws no rows, so board 09's own
    # fourteen items and the band and chips composed from them go with them.
    "09" => [],
    # 146 → no board either: an empty shelf draws no tiles, so board 146's own
    # nine and the counts composed from them are gone with them.
    "146" => [],
    # 149 → no board either. `empty_sheet/0` carries no title, no cold mark and
    # no position, so board 149's own *The Quiet Ones* has nothing left on this
    # screen for an empty database to be held to.
    "149" => [],
    # 145 → no board either: an empty shelf's facets/decades are both [],
    # so none of board 145's chip rails have anything to draw, the same
    # treatment 10 and 12 get.
    "145" => [],
    # 154 draws its form in whatever state the socket holds, and its load state
    # is Film — board 155 says so: "Resting — empty, Film, nothing assumed".
    # Board 154 is drawn with Series chosen so the episode-count field is
    # visible, which is a state a user reaches and not the one the screen opens
    # in, so the resting comparison is 155's first band rather than 154 whole.
    "154" => [{"155", {"Resting — empty, Film, nothing assumed", "Film is the default"}}],
    # 92 → 93's own empty card, and 92's chrome besides.
    #
    # This is screen 03's arrangement, one screen over: the page keeps its own
    # board's header, region row, search field, *Something else*, rules and
    # money row — every one of them live and unchanged with nothing stored —
    # and what goes is the list of services, which becomes board 93's `No
    # services yet` card. So board 92 cannot be compared whole here (its three
    # subscriptions are a state a reader reaches), and the band that replaces
    # them is 93's.
    #
    # 93 as a WHOLE is not the answer, and reading it is what says so: it has
    # no way to add a service — 92's *Something else* row is not on it — and
    # its *Free with ads* group lists two services the reader has not got.
    # MOVIES-AND-TV.md #75.
    "92" => [{"93", {"Subscribed · none yet", "Free with ads"}}],
    # 23 → board 96's fourth band, which is what that sheet was drawn FOR.
    #
    # This page fell back to `Kati.Subscriptions.Sample` when the store held
    # nothing, so a reader with no services was shown somebody else's four —
    # and screen 96, whose whole subject is what four screens look like on day
    # one, could never produce any of its bands. Its own moduledoc named the
    # change it was waiting on: `Kati.Screens.MyServices.listed/0` had to stop
    # falling back first (#75), and it has. MOVIES-AND-TV.md #120.
    #
    # The band and not board 96 whole: 96 is a reference sheet of four
    # specimens, read a band at a time exactly as screen 27 is for the Library
    # above. What 23 keeps with nothing stored is its own back row and disc;
    # what goes is the ledger, and 96's card is what replaces it — *No
    # subscriptions yet*, and explicitly not `£0.00 a month`, because a zero
    # total is a sentence about your spending and it would be false.
    # The band stops at the sheet's own footnote. *The empty ledger hides the
    # delta badge…* is 96 explaining what it chose, addressed to somebody
    # reading the sheet — it is not copy screen 23 shows to somebody who has
    # simply not set up a service yet.
    "23" => [
      {"96",
       {"No subscriptions yet",
        "<div style=\"display:flex;align-items:flex-start;gap:11px;padding:15px;border-radius:18px"}}
    ],
    # 12 → its own card, because board 12 has no drawn empty state and falling
    # back to the board would show three lists nobody made to somebody who has
    # made none — #75's defect, one screen over. `[]` is the same answer screen
    # 97 gives below and for the same reason: no board words this state, so
    # what is compared is the screen's own chrome plus the `@quoted` floor,
    # and `Kati.ScreenListsTest` holds the card's own two sentences.
    # MOVIES-AND-TV.md #106.
    "12" => [],
    # 97 is 92 in Persian and empties the same way. There is no Persian board
    # for the empty state — 93 has no mirror — so the comparison is 97's own
    # chrome, which the `@quoted` floor and `Kati.MyServicesGateTest` hold,
    # and the card's two Persian sentences are board 93's, translated in
    # `priv/gettext/fa` beside the rest of the page's words rather than frozen
    # in a mirror module.
    "97" => [],
    # 157 is 154 in the dark colourway and opens in the same resting state, so
    # it answers to the same band of board 155 — see the entry above, and
    # MOVIES-AND-TV.md #29 for what it used to open in instead.
    "157" => [{"155", {"Resting — empty, Film, nothing assumed", "Film is the default"}}],
    # Board 156 is screen 154 in the mirror, and 154 IS the mirror since
    # mishka-group/kati#103's first fold. It is drawn with **Series** chosen, and
    # `episodes/1` answers a bare Spacer under `:movie` — so the episode label,
    # its `optional` marker, its `۷` placeholder and the note under it are all
    # in a state the screen does not open in, exactly as 154's own entry above
    # records for the English board.
    #
    # Two bands rather than one, because the part after the note IS drawn at
    # rest: the commit button and the hand-typed-title note under it. The
    # episode band between them is the only thing skipped, and
    # `Kati.ScreenDesignLiteralTest.drawn_state/0` compares it directly by
    # putting the screen into `:tv`.
    "156" => [
      {"156", {"arrow_forward_ios", "تعداد قسمت‌ها"}},
      {"156", {"کاتی همین را صادقانه نشان می‌دهد.", nil}}
    ],
    # 188 is 154's case with both states on ONE board: the sheet is drawn
    # resting, with a value in every trough, and again refused, with the card
    # that names what is missing. The refusal is a state a user reaches by
    # pressing Save on an empty name, not the one the sheet opens in — a sheet
    # that opened announcing a failed save would be telling someone their save
    # failed before they pressed anything — so this compares the resting band
    # and `Kati.ScreenDesignLiteralTest.drawn_state/0` compares the refusal.
    #
    # The band is bounded by the sheet's own title and the last clause of the
    # note above the refusal, rather than by two eyebrows: board 188 draws one
    # eyebrow, and `Kati.DesignLiterals.band/3` anchors on any literal the
    # frame contains. It stops THERE rather than at the refusal's first line
    # because this file compares symbols as well as words, and the refusal
    # card's `error` glyph sits before its first word — a band that ended at
    # the sentence would demand a resting sheet draw the glyph of a failure
    # that has not happened.
    "188" => [{"188", {"Add a medication", "what you cannot type, you can at least see."}}],
    "03" => [
      {"03", :whole},
      {"27", {"Empty — nothing added yet", "Loading — skeleton, never a spinner"}}
    ]
  }

  # Screens whose EMPTY state the design does not draw anywhere.
  #
  # `{screen number, why, the suite that holds the copy instead}`. This is the
  # one list here that can make the literal comparison smaller, so it is pinned
  # from both ends by `the screens with no empty board are migrated screens that
  # really have none` below: an entry must be a screen this file renders, and it
  # must not also claim an empty board.
  #
  # It buys exemption from the literal and symbol comparison and **nothing
  # else**. Both screens are still rendered against the empty database, still
  # held to the shape floor `@undrawn` uses, still gated at their own entry point
  # by `empties/0`, and every line of their empty cards that IS quoted from a
  # board is compared in `@quoted` directly below.
  @no_empty_board [
    # 05 with nothing followed. Board 05 is drawn with a watcher card that has
    # a count in it and two sections of releases, and every one of those
    # belongs to a reader who follows something — so a fresh install used to
    # get `drawn_inbox/0`: the drawing's three coming-up rows and
    # `Kati.Library.Sample`'s Out now rows, on the one page whose whole job is
    # to say what is new. That is #91's sentence about a different screen.
    #
    # Board 260 is the state it draws instead, and it is in
    # `test/design/incoming/` rather than `screens/` because it draws two
    # frames and a page of notes — the same treatment every state catalogue of
    # that wave gets. So there is no single artboard to compare this against,
    # which is what this list is for.
    #
    # The board's own ruling is the part worth keeping: **the card became a
    # sentence.** Setting the watcher count to `0` while keeping its meta line
    # "would put a live number beside two frozen ones in the same breath".
    {"05",
     "board 05's watcher count and both release sections belong to a reader who follows " <>
       "something. Board 260 is what a fresh install draws — two cards and a way in — and " <>
       "it is a states board, drawn as two frames with notes, so no single artboard holds " <>
       "this page", Kati.ScreenInboxEmptyTest},
    # 86 and 87 with nothing stored. Board 86 draws two things a fresh device
    # cannot have: a *Recent* shelf of five queries — this reader's own search
    # history, which `Kati.ScreenDesignLiteralTest.drawn_state/0` installs to
    # compare the board — and a *Try* group of two suggestions its own caption
    # says are drawn from what you actually have. The second is what brought
    # these two into this file at all (MOVIES-AND-TV.md #72); the first was
    # always a device value and no board draws the page without it.
    #
    # 87 is here because it draws 86's chip row and reaches the same read
    # through it.
    {"86",
     "board 86 draws a Recent shelf of five queries and two suggestions, and both are this " <>
       "reader's own. A fresh install has neither, and no board draws the idle page without " <>
       "them — 87's *Nothing searched yet* card is what it draws instead, and this screen " <>
       "already draws that card", Kati.SearchSuggestionsTest},
    {"87",
     "87 IS the idle page with nothing typed, so its own empty state is the one it draws; " <>
       "what it cannot draw on a fresh device is 86's Recent shelf and its two derived " <>
       "suggestions", Kati.SearchSuggestionsTest},
    # 06 is drawn MID-QUERY: the four results, the `4 results` caption and the
    # availability lines under them all belong to a search somebody has run.
    # The sheet used to open on them, so a reader who had typed nothing was
    # shown four invented films with real poster images and one of them ticked
    # as already in their library (MOVIES-AND-TV.md #43) — and typing one or
    # two letters put them back (#44).
    #
    # It opens empty now, and no board draws that state. `Kati.AddTitleStatesTest`
    # holds the three cards it draws instead, and `Kati.ScreenDesignLiteralTest`
    # renders 06 in the state its own board WAS captured in — a query typed and
    # four results — which is where board 06's literals are still compared.
    {"06",
     "board 06 is drawn mid-query and its four results belong to that query. The sheet " <>
       "opens empty, and the three states it can be in with nothing typed — resting, under " <>
       "the minimum, and no match — have no board of their own; `D-31` is the brief that " <>
       "would settle it", Kati.AddTitleStatesTest},
    # 19 and 89 are results pages and no board draws one with nothing typed,
    # for a reason that was true until this round: until the field was real the
    # design never put a person on 19 without a query. A person can clear the
    # field now, so the state exists.
    #
    # What it draws is not a third wording of the same idea. Board 87's
    # *Nothing searched yet* card and board 88's paragraph about why the chips
    # carry no counts are both already owned by screens that draw the specs —
    # `Kati.Screens.SearchTyping.nothing_yet/0` and `Kati.Search.counts_note/0`
    # — and 19 draws those. `Kati.SearchRunTest` holds what the read itself
    # answers on a store with rows and without.
    {"19",
     "no board draws the results page with nothing typed: 19 is drawn mid-query and its " <>
       "whole subject is one query matched four ways. Its idle state is board 87's card and " <>
       "board 88's note, drawn through the screens that own them, and its no-match state is " <>
       "board 89's card wired to the two ways out", Kati.SearchRunTest},
    {"89",
     "89 is the four edge states of 19 side by side, so it has no empty state of its own — " <>
       "it IS the drawing of them. On this list because it reads what 19 reads",
     Kati.SearchRunTest},
    # 90 is 19 in the other script since mishka-group/kati#103, so it inherits
    # 19's answer whole: the board is drawn mid-query and its idle state is the
    # two cards 19's is, read under `:fa`. The reason is 19's rather than a
    # second one, because a Persian reader clearing the field reaches the same
    # branch by the same route.
    {"90",
     "90 is board 19 under `:fa` and no board draws the results page with nothing typed in " <>
       "either script. What it draws idle is board 87's card and board 88's note through the " <>
       "screens that own them, translated, and its no-match state is board 89's card. " <>
       "`Kati.SearchRunTest` holds what the read answers on a store with rows and without",
     Kati.SearchRunTest},
    {"02",
     "no artboard draws a Schedule with nothing on it — 02 draws a day with five items — " <>
       "and none draws one Kati is not allowed to read either. `Kati.Screens.Calendar`'s " <>
       "moduledoc names the four boards its two cards are built from and quotes each",
     Kati.ScreenCalendarEmptyStateTest},
    # 56 is 02 read under `:fa` since mishka-group/kati#103 and inherits 02's
    # answer whole: no board draws a Schedule with nothing on it in either
    # script, and the two cards a Persian reader gets are 02's own, translated.
    {"56",
     "56 is board 02 under `:fa` and no artboard draws a Schedule with nothing on it in " <>
       "either script — 56 draws a day with five items, like 02. The two cards it draws " <>
       "instead are 02's own read in the other script, and `Kati.ScreenCalendarEmptyStateTest` " <>
       "is what holds which of the two a permission decides", Kati.ScreenCalendarEmptyStateTest},
    {"07",
     "no board in the 152 draws screen 07 with no history. `Kati.Screens.Stats`'s moduledoc " <>
       "names the four that decided its card — 101's *Not enough data*, 27's geometry, 123's " <>
       "rule for a statistic with nothing under it, and 110's refusal to draw a chart that " <>
       "would mean nothing", Kati.ScreenStatsEmptyTest},
    # 61 is 07 read under `:fa` since mishka-group/kati#103, and it inherits
    # 07's answer whole: no board draws the year card with no year behind it in
    # either script, and the page a Persian reader gets with nothing watched is
    # the same card, translated. `Kati.ScreenStatsEmptyTest` holds it.
    # 57 is 03 read under `:fa` since mishka-group/kati#103. Screen 03's empty
    # shelf is board 27's card — an English reference sheet with no Persian
    # twin anywhere in the 152 — so a Persian reader with nothing shelved gets
    # that card translated, and no board in the set draws it.
    {"57",
     "57 is board 03 under `:fa`, and 03's empty shelf is board 27's *Empty — nothing added " <>
       "yet* card. 27 is a reference sheet drawn in English and nothing in the 152 mirrors " <>
       "it, so there is no Persian board of a shelf with nothing on it. What the page draws " <>
       "instead is 27's own card read in the other script, and " <>
       "`Kati.ScreenLibraryEmptyTest` holds which of its two states a shelf is in",
     Kati.ScreenLibraryEmptyTest},
    {"61",
     "61 is board 07 under `:fa` and no board draws the stats page with nothing watched in " <>
       "either script. The card it draws instead is 07's — 101's *Not enough data* wording " <>
       "through `Kati.Screens.Stats.nothing_yet/0` — read in the other script, and the " <>
       "*More numbers* list under it is the same list saying what each page behind it says",
     Kati.ScreenStatsEmptyTest},
    # 28 and 55 are screen 01 in dark and in Persian, and 139 — screen 01 with
    # nothing kept — has neither a dark mirror nor a Persian one anywhere in the
    # 152. So neither page branches the way 01 branches: each is its own board
    # with the stand-in data gone, which is a real page in both cases — header,
    # search, the calendar band, the dock and the FAB, plus 55's three section
    # tiles. That is deliberately LESS than 01 does and it is the honest less:
    # the alternative is a Persian 139 nobody drew.
    #
    # The asymmetry between the two is worth stating rather than smoothing over.
    # 28's empty sentence is 139's own, verbatim, because 139 is English and 28
    # is English — the `@quoted` pair below is the same pair screen 02 carries.
    # 55's is not quotable from any board, because no board says it in Persian;
    # `Kati.Screens.Home.empty_day/0` is where that sentence lives and where
    # the three ways out are argued. What constrains 55 here instead is board
    # 55's own chrome, which the empty page must still draw in full — see
    # `@quoted`.
    {"28",
     "no board draws a dark Home with nothing kept: 139 is screen 01's empty state in light " <>
       "and the design has no dark mirror of it. 28's *Rest of today* takes 139's own " <>
       "sentence, which is what the pair in @quoted holds; its two announcing bands are " <>
       "omitted whole, on screen 96's rule. `Kati.Screens.HomeDark`'s moduledoc argues both, " <>
       "and 28 is a gallery board rather than a root — `Kati.AppReachabilityTest` files it " <>
       "as a colourway of 01, reached by changing the theme rather than by navigating",
     Kati.ScreenDarkWidgetsTest},
    {"55",
     "board 158 draws a Persian Home with nothing kept, and board 317 is the ruling that 55 " <>
       "must USE it: `Kati.Onboarding.shell_root/1` answers `Kati.Screens.Home` in both languages, " <>
       "so 55 is the page a Persian install opens on, and it drew its own bands emptied " <>
       "there. It calls `Kati.Screens.HomeEmpty.content/1` now, gated on " <>
       "`Kati.Screens.Home.nothing_kept?/1` — one gate for two languages, which is 317's " <>
       "own sentence — so the four lines in @quoted are quoted from 158 rather than from 55. " <>
       "`Kati.Screens.Home.empty_day/0` still words 55's own empty day for a reader who " <>
       "HAS kept something, and is argued at that function", Kati.ScreenHomePersianEmptyStateTest}
  ]

  # `{screen number, the board it is quoted from, the line}`.
  #
  # An empty state with no board of its own is still not free to say whatever it
  # likes: both of these are built by quoting boards that DO word the state, and
  # a quotation is a thing a test can check at both ends. Each entry asserts
  #
  #   * the board still contains the line — so a re-export that drops it fails
  #     here rather than leaving an entry that exempts nothing, and
  #   * the screen still renders it against an empty database.
  #
  # The line is matched as a substring of the board's literal, because a board
  # sometimes writes as one em-dashed sentence what a screen draws as a title and
  # a sub-line. 139 writes `Nothing scheduled — add anything with +` on one row;
  # `Kati.Screens.Calendar.timeline/2` splits it at the dash and drops the
  # chevron, and says why.
  #
  # Screen 02's permission card is deliberately absent: its sentence is board
  # 40's Calendars row word for word, and the branch that draws it needs
  # `Kati.Permissions.status(:calendar)` to answer a refusal, which on a host is
  # `:unknown`. `Kati.ScreenCalendarEmptyStateTest`'s *the refusal states what
  # Kati wanted it for* reaches it through `empty_reason/2` instead, which is
  # pure for exactly that reason.
  #
  # ## Screen 55 quotes its own board, and that is a different claim
  #
  # 02, 07 and 28 all quote a board that words the state they are in. 55 cannot:
  # the state is *a Persian Home with nothing kept*, no board in the 152 says
  # anything about it, and the one sentence it needs —
  # `Kati.Screens.Home.empty_day/0` — is therefore not a quotation at all. It
  # is held by `Kati.ScreenHomePersianEmptyStateTest` instead, at both ends: that the
  # screen draws it on an empty day, and that a real event replaces it.
  #
  # What is quotable is the other half, and it is the half this list can check:
  # **55 with nothing stored is board 55 with its stand-in data gone**, so every
  # line of that board which is NOT stand-in data has to survive. The six below
  # are exactly those lines — the search placeholder, the two eyebrows whose
  # bands remain, and the three section labels — and the entries assert both
  # ends the same way every other entry here does: board 55 still contains the
  # line, and the screen still renders it against an empty database. An empty
  # Persian Home that quietly lost its section tiles, or its calendar band,
  # fails here.
  @quoted [
    # 19 and 89 are results pages with nothing typed, and what constrains them
    # is the chrome that survives whatever the query answered: the field's own
    # placeholder, the four scope chips, and the shelf's heading. A results
    # page that quietly lost its chips would still have looked like a page.
    #
    # Both are quoted from board 87, which is where the idle field is drawn.
    # `All` is board 19's own — it is the chip that reads as selected on every
    # one of the four boards — and it is the one literal here that says the
    # scope row survived.
    # 06 with nothing typed. What constrains it is the chrome that survives
    # whatever a search answered — the sheet's own heading, its three scope
    # chips, and the row that is the only way to add a title the catalogue
    # cannot find. A sheet that quietly lost its chips would still have looked
    # like a sheet.
    #
    # All five are board 06's own; the four RESULTS are the part that belongs
    # to a query, and `Kati.ScreenDesignLiteralTest` compares those in the
    # state the board was captured in.
    # 86 and 87 with nothing stored: the field's own placeholder, the chip row
    # that survives whatever the history held, and the note under it. A page
    # that quietly lost its chips would still have looked like a page.
    # 05 with nothing followed. Board 260's own copy is on a board that is not
    # in `screens/` — it draws two frames and a page of notes — so what is
    # quotable is the chrome of board 05 that survives an empty inbox: the
    # page's own name. `Kati.ScreenInboxEmptyTest` holds board 260's two cards,
    # their two doors, and the absence of the meta line the board's note is
    # about.
    {"05", "05", "New releases"},
    {"86", "87", "Search anything you keep"},
    {"86", "86", "Screen"},
    {"86", "86", "Try"},
    {"87", "87", "Search anything you keep"},
    {"87", "87", "Nothing searched yet"},
    {"06", "06", "Add a title"},
    {"06", "06", "Everything"},
    {"06", "06", "Films"},
    {"06", "06", "Series"},
    # `Can't find it? Add it by hand` was a fifth row here until board 308 made
    # the control absent before a keystroke — it NAMES the query now, and an
    # untouched sheet has none to name. There is no replacement quotation:
    # 06 is drawn mid-query, so every line it has to lend is one of the four
    # above, and what an empty sheet says instead is 87's card at this size
    # rather than anything 06 draws.
    {"19", "87", "Search anything you keep"},
    {"19", "19", "All"},
    {"19", "19", "Recent"},
    # 90's two, and only two. The pair 19 borrows from board 87 has no Persian
    # twin — 87 is an English board and nothing in the 152 draws the idle field
    # in Persian — so what constrains 90 is the chrome board 90 draws itself:
    # the chip that reads as selected, and the shelf's own heading. A Persian
    # results page that quietly lost its scope row or its Recent heading fails
    # here exactly as the English one does.
    {"90", "90", "همه"},
    {"90", "90", "اخیر"},
    {"89", "87", "Search anything you keep"},
    {"89", "89", "All"},
    {"02", "139", "Nothing scheduled"},
    {"02", "139", "add anything with +"},
    # 56's three, and what constrains it is the chrome board 56 draws itself
    # and an empty store cannot take away: the page's own name and the two
    # chips whose meaning does not depend on a row existing. 139 is an English
    # board with no Persian twin, so the pair 02 borrows from it has none here.
    {"56", "56", "برنامه"},
    {"56", "56", "همه"},
    {"56", "56", "نمایش"},
    # 57's four. Board 27 is English, so what constrains an empty Persian shelf
    # is the chrome board 57 draws itself and no empty store can take away: the
    # page's own name, and the three shelf segments, which are `Kati.Sections`'
    # answer rather than the shelf's.
    {"57", "57", "کتابخانه"},
    {"57", "57", "نمایش"},
    {"57", "57", "کتاب‌ها"},
    {"57", "57", "موسیقی"},
    {"07", "101", "Not much to show yet"},
    # 61's three, and the reason they are three where 07 has one: 07 borrows its
    # empty sentence from board 101, which is an English board with no Persian
    # twin, so nothing in the 152 words a Persian stats page with nothing on it.
    # What constrains 61 instead is the chrome board 61 draws itself and an
    # empty store cannot take away — the page's own name, and the two rows of
    # the *More numbers* list whose second lines are read rather than drawn.
    {"61", "61", "سال شما"},
    {"61", "61", "اعداد بیشتر"},
    {"61", "61", "اهداف"},
    {"28", "139", "Nothing scheduled"},
    {"28", "139", "add anything with +"},
    # Board 317 gave screen 55 the gate 139 gives screen 01, so a Persian
    # device with nothing kept draws board **158** — «همان جمله ۱۵۸», the
    # board's own words, and it needs no fresh translation because 158 is
    # already the Persian mirror of 139. The six lines that used to be here
    # were board 55's own chrome, on the reading that an empty Persian Home is
    # 55 emptied; 317 overturns that reading and these four hold the new one at
    # both ends. `Kati.ScreenHomePersianEmptyStateTest`'s board-317 describe holds
    # the rest, including that the three announcing bands are gone.
    {"55", "158", "هنوز چیزی اینجا نیست"},
    {"55", "158", "انتخاب بخش‌ها"},
    {"55", "158", "تقویم همچنان کار می‌کند"},
    {"55", "158", "جست‌وجوی هر چیزی که نگه می‌دارید"}
  ]

  # Screens that read the database and have **no drawing at all**.
  #
  # Every entry in `@migrated` above is a pair of a screen and the frame under
  # `test/design/screens/` it is compared against, and the whole of what
  # this file asks of one is *does it still draw its drawing when nothing is
  # stored*. These two have no frame: `test/design/screens/` stops at 62,
  # none of the 62 is a backup or a sync page, and issue #25 asks for the
  # drawings and they do not exist. Filing them under `@migrated` would mean
  # inventing a number, and `DesignLiterals.read!/1` would then fail on a file
  # that is not there.
  #
  # So the literal comparison is skipped and **the render is not**: `every
  # undrawn store-reading screen still renders with nothing stored` below mounts
  # each one inside the same empty transaction and asserts it comes back a whole
  # renderable page. That is the check that actually matters for these two —
  # they are screens whose ordinary state IS empty, since a device with no
  # queued change and no conflict is the normal one, not the edge case.
  #
  # Pinned from both ends by `the undrawn list names only screens that read and
  # are genuinely undrawn`, so an entry cannot become a way to duck this file:
  # a module here that stops reading the store, or that acquires a drawing and
  # joins `Kati.Screens.Gallery`'s registry, fails.
  @undrawn [
    # Board 267's screen. It reads `Kati.Media.Watch` to count what a clear
    # would remove, and an empty store is the ordinary case rather than a
    # fallback: four zeroes is the true answer to "how much have you logged"
    # on a device that has logged nothing, and `actions/1` draws the
    # destructive row without a tap when there is nothing to clear.
    # `Kati.ScreenClearHistoryTest` holds both.
    Kati.Screens.ClearHistory,
    # Board 169's sheet. It reads no domain at all — the choice lives in
    # `Mob.State` and the counts it might have drawn come from TMDB rather than
    # from the store — so an empty database is the only state it ever renders
    # in, and it is here because six of the board's eleven controls cannot be
    # answered by any TMDB field and the page therefore draws its buildable
    # half. `Kati.Discover.Filters` names each omission; `Kati.DiscoverFiltersTest`
    # holds what it draws.
    Kati.Screens.DiscoverFilters,
    # Boards 252/302's page. A bare push names no service and answers `nil`,
    # which is the state an empty store is always in — `find/1` does not pick
    # the first service on the shelf, because this page pauses things and takes
    # them off it. `Kati.ScreenServiceTest` holds that.
    Kati.Screens.Service,
    # The two notification screens. Both read a store — the inbox builds a plan
    # from every domain's candidates, the diagnostic reads the permission state
    # and the same plan — and neither has a drawing to be compared against, so
    # they take the `@undrawn` path: rendered against an empty database, checked
    # for shape, and exempt from the literal comparison.
    Kati.Screens.InboxNotifications,
    Kati.Screens.NotificationsHelp,
    Kati.Screens.Sync,
    # The two Lists screens. Boards 330-333 and 335 draw them and arrived on
    # 7 September, so "no drawing" is no longer the reason — what they are is
    # **state catalogues**: 330 stacks the resting page, an open menu, a
    # confirmation and an undo bar in one frame, and 333 is 1249px of states in
    # an 806px sheet. Neither is a state a screen is ever in, so neither can be
    # compared literal-for-literal against a render.
    #
    # The repo's answer to that is a specimen screen per states board — 155 for
    # 154, 95 for 92 — and those are not built yet. Until they are, these two
    # skip the literal comparison and keep the render, which is what this list
    # is for. MOVIES-AND-TV.md #106.
    Kati.Screens.AddToList,
    Kati.Screens.ListDetail
    # Board 301, the Persian country sheet — screen 97's country row is the
    # door, and 324 is the board that gave that row something to ask for. 301's
    # frame is drawn beside three notes about what 94 and 97 got wrong rather
    # than as a numbered artboard, so it stays in `test/design/incoming/` and
    # this screen takes the `@undrawn` path: rendered against an empty
    # database, checked for shape, exempt from the literal comparison.
  ]

  # The fewest strings a whole page can be. Thirteen is the bound the `@undrawn`
  # render test below has always held those two screens to, written as the floor
  # rather than as the number one below it, and it is named here because a second
  # test now uses it for the same argument: a page that is mostly chrome is what
  # a lost empty state looks like. It is the floor under every screen in this
  # file, including the ones whose drawing holds fewer literals than this.
  @chrome_floor 13

  # The one screen whose empty state is genuinely smaller than the floor, and
  # the drawing says so. Board 96's fourth band is *an empty ledger* — a card
  # holding a title, a sentence and a button, and nothing else — and its own
  # note spells out what the state takes away with it: the delta badge, the
  # per-service rows and the Worth-a-look card, all of which would report a
  # change of nothing against nothing. Screen 23 keeps its header and draws
  # that card, which is nine strings.
  #
  # An exception rather than a lower `@chrome_floor`: the floor is what catches
  # a page that lost its content and kept its chrome, and lowering it for
  # everybody to fit one screen the design drew small would stop it catching
  # that. Named, with a number, so a page that shrinks further still fails.
  # MOVIES-AND-TV.md #120.
  @small_empty_boards %{
    "23" => 9,
    # 34 with no season is the subtitle, three order labels, the zero eyebrow
    # and the back pill's chrome — twelve strings. The nine episode rows and the
    # two switches that padded it past the floor act on rows it has not got.
    # 37 with no file picked is the Import pill, the heading, its subtitle, the
    # file card's two lines, the Match columns eyebrow and one worded sentence
    # where the mapping table was — ten strings. The five mapped columns, the
    # three outcome cards and the conflict card that padded it past the floor
    # are every part of the page that describes a file, and there is no file.
    #
    # Ten and not eleven because **WHAT WILL HAPPEN** goes with them: the
    # emulator walk found it standing over an empty row, and a heading
    # promising a plan with no plan under it is the same claim the fixture used
    # to make, one line shorter. `outcome_eyebrow/1` carries why it is absent
    # here where board 321's *Try* heading is worded.
    "37" => 10,
    # 141 with no file picked is a single card: a glyph, a title, a sentence.
    # Five strings, and it is the SAME shape as its own refusal page one case
    # over — `refused/1`'s frame around a different sentence — which is the
    # precedent this exception rests on. A page that has been given nothing has
    # exactly one thing to say, and board 141's own note on the refusal branch
    # is the argument against padding it: *"a page that draws them anyway is
    # lying in nine places to apologise in one"*.
    "141" => 5,
    "34" => 12,
    # 14 with nothing stored is the back pill, the empty hero's two lines and
    # the "no cast, no scores" card — ten strings. The synopsis, cast, ratings
    # and where-to-watch rows that padded it past the floor are exactly what a
    # page about no series has not got.
    "14" => 10,
    # 15 with nothing logged is the heading, its count sentence, the four chips
    # and one empty line — the seven rows and the rewatch card that used to pad
    # it past the generic floor are the whole of what an empty log has not got.
    "15" => 8,
    # 39 with nothing queued is the title, the mono line, two eyebrows, the
    # preview's own two sentences and the share card — twelve strings. The three
    # phantom tiles and the four shortcut rows that used to pad it past the
    # generic floor were the whole of what this round deleted.
    "39" => 12,
    # 09's empty day is the date heading, the view switcher's four labels and
    # one "Nothing scheduled" sentence — eleven strings. There is no second
    # section under it to pad the count with, and inventing one would be
    # inventing copy this state does not need.
    "09" => 11,
    # 10's honest empty card is the whole page now — no hero, no rows, no
    # second section beneath it the way Lists keeps its kept rows. An icon,
    # "Nothing queued", one body sentence and the back pill's chrome is
    # eleven strings, and padding it to clear a generic floor would be
    # inventing a second sentence this state does not need.
    "10" => 11
  }

  # The same exception for an `@undrawn` screen, and the same argument.
  # `Kati.Screens.ListDetail` with nothing stored is one page saying one thing —
  # *this list is gone* and the one way on. It cannot be thirteen strings
  # without padding, and padding an empty state is the opposite of what the
  # floor is for.
  #
  # 9 until board 331 drew this state, which is the direction a floor is
  # allowed to move for: the page used to carry a second sentence about what
  # was not lost and an info note underneath, and 331 draws neither — a gone
  # list gets an eyebrow, a glyph, two lines and a pill back to the index,
  # *"because the page you came from no longer exists."* Seven strings is the
  # drawing, not a shrink.
  #
  # Named with a number, so a page that shrinks further still fails.
  # MOVIES-AND-TV.md #106.
  @small_undrawn %{
    # Board 333's empty sheet is five strings and nothing else: the header, the
    # sentence, its second line, the field's placeholder and the pill. The
    # board drops the kept card here on purpose — *"it is inert here"* — so
    # there is nothing further to draw, and the empty sheet is the state a
    # reader with no lists always meets first. Five IS the drawing.
    Kati.Screens.AddToList => 5,
    # 337's empty sheet is the Persian mirror of the same five.
    Kati.Screens.ListDetail => 7
    # 336's gone card is one line shorter than 331's: the Persian pill reads
    # «فهرست‌های شما» and there is no eyebrow above the card, because 336 draws
    # the state as a page rather than as a band in a catalogue.
  }

  # Every table an Ash resource in this app is backed by, child tables first so
  # the deletes below do not trip a foreign key. Written out rather than derived
  # so that `every_table_is_listed/0` can compare it against the schema the
  # migrations actually built — a resource added without a line here would
  # otherwise leave rows in place and this file would quietly stop being about
  # an empty database.
  @tables ~w(list_memberships lists event_occurrence_overrides events calendars calendar_accounts recipe_ingredients recipes meal_plan_slots meal_plans meal_logs shopping_list_items foods bundled_foods licensed_foods media_watches media_events media_content_warnings media_warning_preferences media_title_aliases tracked_titles cached_titles cached_seasons cached_episodes sync_outbox sync_rejected_changes followed_authors book_notes book_reading_sessions books music_listens music_tracks music_albums music_artists services goals expenses health_doses health_readings health_medications notification_pending)

  # Tables that are not an Ash resource and are none of this file's business:
  # Ecto's own ledger, and the DETS-replacing store Mob keeps screen state in.
  @not_resources ~w(schema_migrations mob_screen_states)

  # The resources the migrated screens actually read, asked through Ash rather
  # than through Ecto. `count(*)` returning zero and `Ash.read!` returning `[]`
  # are different claims — a filter, a base_filter or a multitenancy setting
  # could make them disagree — and it is this one the screens depend on.
  @resources [
    Kati.Calendars.Account,
    Kati.Calendars.Calendar,
    # 01 and 02 reach this one through `Kati.Calendars.Today`, and it is the
    # resource their whole timeline is. Asked here as well as counted above,
    # because `Kati.Calendars.Event` is the one resource in the app with a
    # `deleted_at` — a tombstone is a row Ecto counts and a read may filter out,
    # which is precisely the disagreement between the two levels this list
    # exists to catch.
    Kati.Calendars.Event,
    Kati.Calendars.Override,
    Kati.Media.TrackedTitle,
    Kati.Media.CachedTitle,
    Kati.Media.CachedSeason,
    Kati.Media.CachedEpisode,
    Kati.Media.Watch,
    Kati.Meals.MealPlan,
    Kati.Meals.MealPlanSlot,
    Kati.Meals.MealLog,
    Kati.Meals.Recipe,
    Kati.Meals.RecipeIngredient,
    Kati.Meals.ShoppingListItem,
    Kati.Meals.Food
  ]

  # One old cache table and both new ones. The two new ones are the point: their
  # `DELETE` has never run before this round, and a table left out of `@tables`
  # is invisible to every other test in this file.
  @probe_resources [
    Kati.Media.CachedTitle,
    Kati.Media.CachedSeason,
    Kati.Media.CachedEpisode
  ]

  # Marks the probe rows as this file's, so `delete_probe_rows!/0` can take back
  # exactly what it wrote and nothing a neighbouring test left behind.
  @probe_id "kati:empty-db-probe"

  describe "the emptiness this file rests on" do
    test "every table in the schema is either listed or named as not a resource" do
      %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'")
      present = rows |> List.flatten() |> Enum.reject(&String.starts_with?(&1, "sqlite_"))

      missing = Enum.reject(@tables, &(&1 in present))

      assert missing == [],
             "these tables are emptied below and do not exist, so emptying them proves " <>
               "nothing: #{inspect(missing)}"

      unwatched = Enum.reject(present, &(&1 in @tables or &1 in @not_resources))

      assert unwatched == [],
             "these tables exist and are neither emptied nor declared irrelevant, so rows in " <>
               "them would survive into the renders and this file would be claiming an empty " <>
               "database it never made: #{inspect(unwatched)}"
    end

    test "inside the transaction both Ecto and Ash agree there is nothing stored" do
      {counts, reads} =
        in_empty_database(fn ->
          counts =
            for table <- @tables,
                %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}"),
                n > 0,
                do: "  #{table}: #{n}"

          reads =
            for resource <- @resources,
                rows = Ash.read!(resource),
                rows != [],
                do: "  #{inspect(resource)}: #{length(rows)}"

          {counts, reads}
        end)

      assert counts == [],
             "tables still hold rows inside the transaction:\n" <> Enum.join(counts, "\n")

      assert reads == [],
             "Ash still returns rows inside the transaction, which is the level the screens " <>
               "read at:\n" <> Enum.join(reads, "\n")
    end

    test "the transaction is rolled back, so the rest of the suite keeps its rows" do
      before = table_counts()
      _ = in_empty_database(fn -> :ok end)

      assert table_counts() == before,
             "emptying the tables for this file's renders was not undone. Every other test " <>
               "shares this database and this module would be deleting their fixtures"
    end

    test "rows written first are seen outside, unseen inside, and there again after" do
      # The three tests above are all satisfied by a database that was empty to
      # begin with. `count(*) == 0` proves nothing when nothing was ever
      # written, `Ash.read!` returning `[]` proves nothing either, and "the
      # counts did not change" is trivially true of a table of zero rows — so a
      # `DELETE` that silently did not run, or a transaction that did not scope
      # the renders, would pass every one of them.
      #
      # So this one writes first, and asks the same three questions of rows it
      # knows exist. Both new tables are among them, because they are the two
      # whose emptying has never run before this round.
      written = write_probe_rows!()
      on_exit(&delete_probe_rows!/0)

      outside =
        Map.new(@probe_resources, fn resource -> {resource, length(Ash.read!(resource))} end)

      for {resource, count} <- outside do
        assert count > 0,
               "#{inspect(resource)} holds nothing before the transaction opens, so emptying " <>
                 "it inside proves nothing. The probe row was not written"
      end

      inside =
        in_empty_database(fn ->
          Map.new(@probe_resources, fn resource ->
            table = AshSqlite.DataLayer.Info.table(resource)
            %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}")
            {resource, {n, length(Ash.read!(resource))}}
          end)
        end)

      for {resource, {counted, read}} <- inside do
        assert counted == 0,
               "#{inspect(resource)}'s table still counts #{counted} rows inside the " <>
                 "transaction, so the renders below are not running against an empty database"

        assert read == 0,
               "Ash still returns #{read} #{inspect(resource)} rows inside the transaction. " <>
                 "That is the level the screens read at, so a screen would still be drawing " <>
                 "them"
      end

      for {resource, ids} <- written do
        back = resource |> Ash.read!() |> Enum.map(& &1.id) |> MapSet.new()

        assert MapSet.subset?(ids, back),
               "#{inspect(resource)} rows written before the transaction are gone after it " <>
                 "rolled back. This module shares one database file with every other test " <>
                 "and would be deleting their fixtures"
      end
    end
  end

  # How many of a board's literals no render of it can produce, and why. The
  # floor below subtracts this from the board's count, so it is a smaller
  # number rather than an absent check.
  #
  #   * 144 and 149 draw a moment the live screen is not in. See the pairs in
  #     `device_values/0` for which literals those are.
  #
  #   * 190 is an annotation board, and its two long notes are prose with
  #     phrases emphasised INSIDE the sentence — `4 doses`, `clock times
  #     armed`, `one`, `dose · instruction`. `Kati.DesignLiterals` yields each
  #     emphasised run as its own literal, so one drawn paragraph arrives here
  #     as eight. A screen cannot answer that count: `Mob.Renderer`'s `Text`
  #     takes a `String` and the bridge hands it to Compose's `Text`, which has
  #     no span list — so a sentence with a bold phrase in the middle of it is
  #     one node in this app or it is a broken line wrap. Every literal is
  #     still checked for by the test above, and found; this is the count, and
  #     the count is 2 short of what no implementation can reach.
  #
  #   * 166 draws a moment too, and it is one tile's tick. Board 163 and its
  #     Persian mirror draw `گودال بلند` already selected, and the app opened
  #     that way until 8 September — which meant a reader who pressed **Finish
  #     setup** without choosing was handed one of the board's four INVENTED
  #     titles, and screen 139 was unreachable by the path most people walk.
  #     `Kati.Screens.OnboardingFirstTitle.load/1` carries the argument. The
  #     glyph is a `Text` node like any other, so a page with no tile ticked
  #     renders exactly one string fewer than the board it is held to. 163 is
  #     not here: its own board holds enough copy to clear the floor without it.
  @floor_allowance %{"144" => 5, "149" => 3, "190" => 2, "166" => 1}

  @moment_symbols [
    {"128", "cloud_done"},
    {"144", "expand_more"},
    {"144", "visibility_off"},
    {"149", "undo"},
    # Board 12's *Wishlist* and *Owned on disc* rows, retired with the two
    # lines they carried — both are assertions a reader makes and no column
    # holds. `Kati.ScreenDesignLiteralTest`'s `@retired_symbols` is this
    # entry's twin and carries the argument. MOVIES-AND-TV.md #106.
    {"12", "bookmark"},
    {"12", "inventory_2"},
    # Boards 163 and 166's ticked tile, in both scripts, and the twin of
    # `@floor_allowance`'s 166 entry above.
    # `Kati.ScreenDesignLiteralTest`'s `@unreachable_symbols` carries the same
    # pair with the whole argument: nothing is picked on a bare mount, and
    # `Kati.FirstRunTest` taps a tile and asserts what follows.
    {"163", "check"},
    {"166", "check"},
    # Board 62's four rows that screen 53 owns, and its Meals section, folded
    # away by mishka-group/kati#103. `DesignLiterals.retired_lines/0` holds the
    # words and the argument; `Kati.ScreenDesignLiteralTest`'s
    # `@retired_symbols` is this entry's twin.
    # Board 176's annotation aside, retired with its seven runs —
    # `DesignLiterals.retired_lines/0` carries the argument.
    {"176", "info"},
    {"62", "event"},
    {"62", "pin"},
    {"62", "restaurant"}
  ]

  # The floor this screen is actually held to. Three answers, in order: a screen
  # whose empty board the design drew small takes its own named number; a screen
  # compared with its OWN board takes that board's literal count; everything
  # else takes the greater of that count and `@chrome_floor`.
  defp floor_for(screen, drawn_floor) do
    case Map.fetch(@small_empty_boards, screen.number) do
      {:ok, named} ->
        named

      :error ->
        if screen.boards == [screen.number],
          do: drawn_floor,
          else: max(drawn_floor, @chrome_floor)
    end
  end

  # A screen may be held to more than one drawing (see `@empty_boards`), so the
  # question is asked of every board it is compared with rather than of its own
  # number.
  defp exempt_symbol?(boards, name),
    do: Enum.any?(@moment_symbols, fn {number, symbol} -> number in boards and symbol == name end)

  describe "which screens this file has to cover" do
    test "every screen that can reach the database is in the list, and every one listed does" do
      # The list at the top of this file is the whole of what gets rendered
      # against an empty database, so a screen missing from it is a screen with
      # no guard at all — and the way that happens is not malice, it is a
      # migration landing in a round where nobody remembered this file. Both
      # halves are therefore derived rather than trusted.
      #
      # Derived from the **compiled import table**, not from the source: a
      # moduledoc quoting an `Ash` call is not a query
      # (`Kati.Screens.SeriesSettings`'s quotes `Ash.create!` and reads
      # nothing), and a read that has moved
      # into a helper — `Kati.Calendars.Today`, which is how 01 and 02 read —
      # is invisible to a grep of the screen's own file and plain in its imports.
      listed = MapSet.union(MapSet.new(@migrated, &elem(&1, 1)), MapSet.new(@undrawn))
      readers = MapSet.new(Enum.filter(ScreenSweep.screens(), &reaches_store?/1))

      unguarded = readers |> MapSet.difference(listed) |> Enum.sort()

      assert unguarded == [],
             "these screens read the database and are not rendered against an empty one. " <>
               "Add each to @migrated with the number its drawing is filed under — a screen " <>
               "that has just moved onto a domain is exactly the one whose fallback nobody " <>
               "has checked. A screen with no drawing at all goes in @undrawn instead, " <>
               "which skips the literal comparison and keeps the render:\n" <>
               Enum.map_join(unguarded, "\n", &"  #{inspect(&1)}")

      idle = listed |> MapSet.difference(readers) |> Enum.sort()

      assert idle == [],
             "these screens are listed as reading the database and reach no store at all, so " <>
               "rendering them against an empty one asserts nothing. Either the read was " <>
               "reverted — in which case `Kati.ScreenSampleOnlyTest` is where they belong — " <>
               "or the entry was aspirational:\n" <>
               Enum.map_join(idle, "\n", &"  #{inspect(&1)}")
    end

    test "the reachability test can tell a reader from a screen that only mentions one" do
      # A derived answer can be derived wrongly, and the way this one fails is
      # by answering `true` for everything (a namespace test that matches too
      # much) or `false` for everything (a chunk that did not load, an empty
      # module list). Both would make the test above vacuous, so three known
      # answers are pinned: one screen that queries directly, one that queries
      # only through a helper, and one whose moduledoc names an `Ash` call at
      # length and whose body reads nothing.
      #
      # That third one used to be `Kati.Screens.Season`, then
      # `Kati.Screens.SeriesSettings`; both now read. The exemplar is
      # `Kati.Screens.Habits`, which gives a whole moduledoc section to *Why
      # this screen is still on `Kati.Habits.Sample`* and reads nothing.
      # Keeping a mention-only screen pinned here is the point: a namespace
      # test that matched too much would answer `true` for it.
      assert reaches_store?(Kati.Screens.Film)
      assert reaches_store?(Kati.Screens.Home)
      refute reaches_store?(Kati.Screens.Habits)
      refute reaches_store?(Kati.Screens.Gallery)
    end

    test "the undrawn list names only screens that read and are genuinely undrawn" do
      # `@undrawn` is the one thing in this file that can make it check less, so
      # it is pinned from both ends like every other allow-list here.
      #
      # A module that stops reading the store does not belong in this file at
      # all, and a module that gains a drawing belongs in `@migrated` with its
      # number — where the literal comparison it was exempted from starts
      # applying again. `Kati.Screens.Gallery.screens/0` is the app's own
      # number → module registry and therefore the only honest answer to "does
      # a drawing exist for this screen", which is why it is asked rather than
      # a second list kept here.
      drawn = MapSet.new(Kati.Screens.Gallery.screens(), &elem(&1, 2))

      for module <- @undrawn do
        assert ScreenSweep.screen?(module),
               "#{inspect(module)} is in @undrawn and is not a screen at all"

        assert reaches_store?(module),
               "#{inspect(module)} is exempted from the literal comparison and reads no " <>
                 "store, so it has nothing to be exempted from. Remove it"

        refute MapSet.member?(drawn, module),
               "#{inspect(module)} is registered in Kati.Screens.Gallery, so a drawing " <>
                 "exists for it. Move it to @migrated with its number and let the literal " <>
                 "comparison run"
      end

      assert MapSet.disjoint?(MapSet.new(@undrawn), MapSet.new(@migrated, &elem(&1, 1))),
             "a screen is in both @migrated and @undrawn, which cannot both be true"
    end
  end

  describe "with nothing stored" do
    test "every undrawn store-reading screen still renders with nothing stored" do
      # The half of this file that `@undrawn` keeps rather than skips, and for
      # these two it is the half that matters. A backup page on a device that
      # has never exported, and a sync page on a device with no queued change
      # and no conflict, are not edge cases — they are the ordinary state, and
      # the state a fresh install opens in. A screen that only holds together
      # once there are rows would fail here and nowhere else, because no drawing
      # exists for the literal sweep to catch it with.
      #
      # Rendered inside the same rolled-back transaction as everything else, so
      # "nothing stored" means what it means everywhere else in this file.
      trees =
        in_empty_database(fn ->
          Map.new(@undrawn, fn module ->
            {:ok, _socket, tree} = ScreenSweep.render(module)
            {module, tree}
          end)
        end)

      for {module, tree} <- trees do
        assert_renderable(tree)

        texts =
          tree
          |> find_all(:text)
          |> Enum.map(&(&1.props[:text] || ""))
          |> Enum.reject(&(&1 == ""))

        floor = Map.get(@small_undrawn, module, @chrome_floor)

        assert length(texts) >= floor,
               "#{inspect(module)} rendered #{length(texts)} strings against an empty " <>
                 "database. A page that is mostly chrome is what a lost empty state looks " <>
                 "like, and this screen has no drawing for anything else to compare"
      end
    end

    test "every migrated screen still draws every literal its drawing contains" do
      # `screen.design` is the drawing this screen is compared with when nothing
      # is stored — its own for all but the four roots, and for those the empty
      # boards `@empty_boards` names. `screen.boards` are those drawings' numbers,
      # and
      # `nil` for the two screens the design draws no empty state for at all.
      missing =
        for screen <- render_migrated(),
            screen.boards != [],
            literal <- screen.design.text,
            not exempt?(screen.boards, literal),
            not retired?(screen.boards, literal),
            DesignLiterals.locate(literal, screen.haystacks) == :missing,
            do:
              "  #{screen.number} #{inspect(screen.module)} never draws #{inspect(literal)} " <>
                "(drawing #{Enum.join(screen.boards, " + ")})"

      assert missing == [],
             "these screens read the database and no longer draw the drawing they are held to " <>
               "when nothing is stored. A fresh install renders this as a gap, and the next " <>
               "frame capture is where it would have surfaced:\n" <> Enum.join(missing, "\n")
    end

    test "every migrated screen has an entry-point gate, and every gate a migrated screen" do
      # `@migrated` is pinned from both sides against the compiled call graph, so
      # a screen that starts reading Ash cannot stay out of it. `fallbacks/0` had
      # no such pin, and it is the stronger of the two halves this file asks:
      # the literal checks are satisfied by presence anywhere in the tree, and
      # only this one puts the question to the screen's own read.
      #
      # A `for` over a list asserts nothing about a screen the list omits. So a
      # screen added to `@migrated` — which the derivation above *forces* on the
      # round it migrates — and not added here would be rendered, would pass
      # every literal check, and would have its fallback taken entirely on
      # trust. Verified by deleting screen 33's entry: the whole file still
      # passed, and 33 is the one whose moduledoc calls its own fallback the
      # subtlest here.
      today = Kati.Time.today()
      gates = gate_modules(today)

      listed = MapSet.new(@migrated, &elem(&1, 0))
      gated = MapSet.new(Map.keys(gates))

      ungated = listed |> MapSet.difference(gated) |> Enum.sort()

      assert ungated == [],
             "these screens are rendered against an empty database and their own read is " <>
               "never asked what it answered, so what they draw is a claim rather than a " <>
               "result. Add each to `fallbacks/0` as `{number, module, what the screen " <>
               "reads, what the drawing is}`, or — if the screen answers with its own " <>
               "emptiness — to `empties/0`:\n" <> Enum.map_join(ungated, "\n", &"  #{&1}")

      stray = gated |> MapSet.difference(listed) |> Enum.sort()

      assert stray == [],
             "these screens have an entry-point gate and are not in @migrated, so nothing " <>
               "renders them and the gate is checking a screen this file does not cover:\n" <>
               Enum.map_join(stray, "\n", &"  #{&1}")

      # Both halves keyed by number, so the modules are checked too rather than
      # assumed to follow — a gate pointing at the wrong screen would otherwise
      # satisfy every set comparison above. Read across BOTH lists, so a screen
      # that is in each of them has to name the same module in each.
      mismatched =
        for {number, module} <- @migrated,
            gate_module <- Map.get(gates, number, []),
            gate_module != module,
            do: "  #{number} is #{inspect(module)} in @migrated, #{inspect(gate_module)} here"

      assert mismatched == [],
             "an entry-point gate names a different module than the screen it is filed " <>
               "under:\n" <> Enum.join(mismatched, "\n")
    end

    test "a screen held to a different drawing is a screen this file renders" do
      # `@empty_boards` and `@no_empty_board` are the two things here that change
      # WHICH drawing a screen is compared with, and `@no_empty_board` is the one
      # that can make the comparison smaller. Both are pinned from both ends, the
      # way every allow-list in this file is.
      numbers = MapSet.new(@migrated, &elem(&1, 0))
      boarded = MapSet.new(Map.keys(@empty_boards))
      unboarded = MapSet.new(@no_empty_board, &elem(&1, 0))

      for set <- [boarded, unboarded], number <- MapSet.to_list(set) do
        assert MapSet.member?(numbers, number),
               "screen #{number} is given an empty-state drawing and is not in @migrated, so " <>
                 "nothing renders it and the entry decides nothing"
      end

      assert MapSet.disjoint?(boarded, unboarded),
             "a screen claims both an empty board and no empty board: " <>
               inspect(MapSet.to_list(MapSet.intersection(boarded, unboarded)))

      # An `@no_empty_board` entry is not a free pass. Each has to be held to the
      # lines it quotes from the boards that DO word its state, so a screen
      # cannot join that list and then say anything at all.
      quoted = MapSet.new(@quoted, &elem(&1, 0))

      assert MapSet.difference(unboarded, quoted) |> MapSet.to_list() == [],
             "these screens are exempted from the literal comparison and quote nothing, so " <>
               "no drawing constrains their empty state at all: " <>
               inspect(MapSet.to_list(MapSet.difference(unboarded, quoted)))

      assert MapSet.difference(quoted, unboarded) |> MapSet.to_list() == [],
             "these screens quote another board and are not in @no_empty_board, so the " <>
               "quotation is a second, looser check running beside a full comparison they " <>
               "already pass: " <>
               inspect(MapSet.to_list(MapSet.difference(quoted, unboarded)))

      # And every named drawing resolves to something, one at a time rather than
      # as the union — a band that sliced to nothing would otherwise hide behind
      # the whole board named beside it, and screen 03 names both.
      # `Kati.DesignLiterals.band/3` raises on a label it cannot find, so a
      # re-exported reference sheet fails here rather than quietly comparing
      # against less.
      for {number, specs} <- @empty_boards, {board, _} = spec <- specs do
        refute drawing(spec).text == [],
               "screen #{number} is compared with drawing #{board}, which yielded no " <>
                 "literals at all — a comparison against nothing passes for every screen"
      end
    end

    test "each screen's own read answers empty, so it is the drawing that drew" do
      # The literal checks say the drawing's words reached the tree. They cannot
      # say *by which path* — a screen could satisfy every one of them from copy
      # that lives in its chrome while its list silently emptied, and one that
      # kept a Sample call it never reaches would pass them too.
      #
      # This asks the screen's own entry point instead, inside the same empty
      # database: what `mount/3` or `load/1` is handed must be, to the term, what
      # the screen answers with when it has decided to draw the drawing. It is
      # the assertion that the fallback exists AND is the branch an empty
      # database takes, which is the pair a moduledoc can claim and only a run
      # can settle.
      #
      # **This is one of two contracts now, not the only one.** It was written
      # when every screen here answered an empty store with its Sample module,
      # and it still holds for every screen `fallbacks/0` lists. The four roots
      # answer with their emptiness instead, and the test below is that contract
      # — same question, opposite right answer. Neither is the weaker: this one
      # says a drawn value came back, that one says an empty value came back AND
      # the drawn value it could have come back with is still there.
      today = Kati.Time.today()

      wrong =
        in_empty_database(fn ->
          for {number, module, live, drawn} <- fallbacks(today),
              live.() != drawn.(),
              do: "  #{number} #{inspect(module)} did not answer with its drawn value"
        end)

      assert wrong == [],
             "these screens read an empty database and answered with something other than " <>
               "the values their drawing was captured from, so whatever they render is " <>
               "neither the user's data nor the design:\n" <> Enum.join(wrong, "\n")
    end

    test "each root's own read answers its emptiness, and not the drawing it dropped" do
      # The #91 guard, and the mirror of the test above. A root that answered an
      # empty store with `Kati.Library.Sample` put nine films nobody had added on
      # the first screen of a fresh phone, in the shape and colour of the user's
      # own shelf, and the owner read it as exactly what it was. Every screen in
      # `empties/0` is one that used to do that.
      #
      # Two claims, because either alone is satisfiable by a mistake — see
      # `empties/0`. The second is what stops an emptied Sample module turning
      # the first into two nothings agreeing.
      today = Kati.Time.today()

      {answered, vacuous} =
        in_empty_database(fn ->
          answered =
            for {number, module, live, empty, _drawn} <- empties(today),
                live.() != empty,
                do:
                  "  #{number} #{inspect(module)} answered #{inspect(live.(), limit: 3)} " <>
                    "where an empty store should answer #{inspect(empty)}"

          vacuous =
            for {number, module, _live, empty, drawn} <- empties(today),
                drawn.() == empty,
                do: "  #{number} #{inspect(module)}'s drawn value is #{inspect(empty)} too"

          {answered, vacuous}
        end)

      assert answered == [],
             "these screens read an empty database and answered with something other than " <>
               "nothing. A value where there is no data is the drawing being handed to a " <>
               "person as their own, which is #91:\n" <> Enum.join(answered, "\n")

      assert vacuous == [],
             "these screens' transcriptions of their own drawing are empty, so the check " <>
               "above compares nothing with nothing and would pass on a screen that had lost " <>
               "both branches. `Kati.ScreenDesignLiteralTest` renders the board out of these " <>
               "same functions and would fail with it:\n" <> Enum.join(vacuous, "\n")
    end

    test "every migrated screen still draws every Material Symbol its drawing draws" do
      missing =
        for screen <- render_migrated(),
            screen.boards != [],
            glyphs = DesignLiterals.rendered_glyphs(screen.tree),
            name <- screen.design.icons,
            glyph = Kati.Icons.glyph(name),
            glyph != nil,
            not MapSet.member?(glyphs, glyph),
            not exempt_symbol?(screen.boards, name),
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{name}"

      assert missing == [],
             "an icon the drawing shows is absent on an empty database, which usually means " <>
               "the row that used to carry it is:\n" <> Enum.join(missing, "\n")
    end

    test "the clock literals are still exempted for the reason they were" do
      # An allow-list is the one thing in this file that can only ever make it
      # check less, so it is pinned from both ends. A dead entry — a literal the
      # drawing no longer contains — would be an exemption for nothing, and an
      # empty slot — a stand-in pattern matching nothing the screen renders —
      # would be hiding a line that stopped being drawn at all.
      rendered = Map.new(render_migrated(), &{&1.number, &1.texts})

      for {number, literal, pattern} <- device_values() do
        # Both sides are `DesignLiterals.normalise/1`'d already — whitespace
        # collapsed and case folded — so these compare in that form and the
        # entries above are written in it.
        assert literal in DesignLiterals.read!(number).text,
               "#{number}'s drawing no longer contains #{inspect(literal)}, so exempting it " <>
                 "exempts nothing"

        assert Enum.any?(rendered[number] || [], &Regex.match?(pattern, &1)),
               "#{number} renders nothing matching #{inspect(pattern)} on an empty database. " <>
                 "The exemption was granted because the screen draws the device's own clock " <>
                 "there; if it draws nothing, the line is gone and this was hiding it"
      end
    end

    test "each one draws a whole screen, not chrome over an empty section" do
      # The literal check above is satisfied by presence anywhere in the tree, so
      # a screen whose lists emptied while its chrome survived could still pass it
      # if the drawing's copy happened to sit in the chrome. Counting what was
      # actually rendered catches the shape of that before it needs a frame.
      # A board that draws several moments at once holds more copy than any one
      # render can, and so does one whose prose emphasises phrases inside a
      # sentence. `@floor_allowance` names both and says how many literals each
      # loses that way, so the count still has to be right — it is a smaller
      # number, not an absent check.
      #
      # A screen compared with its OWN board keeps the floor it always had: the
      # board's literal count, which for a screen the size of 114 is under a
      # dozen and is still the right number, because it is a count of what that
      # screen draws.
      #
      # A screen compared with an empty board or with none does not — screen
      # 27's *Empty* band holds four literals, 139 holds twelve, and
      # `@no_empty_board` holds none at all, so the drawing's own count would be
      # a floor a nearly-blank page could clear. Those take `@chrome_floor`
      # instead, which is `@undrawn`'s bound and the same argument.
      thin =
        for screen <- render_migrated(),
            allowance = Map.get(@floor_allowance, screen.number, 0),
            drawn_floor = length(screen.design.text) - allowance,
            floor = floor_for(screen, drawn_floor),
            length(screen.texts) < floor,
            do:
              "  #{screen.number} #{inspect(screen.module)} rendered #{length(screen.texts)} " <>
                "strings against a floor of #{floor}"

      assert thin == [],
             "these screens render less copy than the drawing they are held to, which is what " <>
               "a lost empty state looks like:\n" <> Enum.join(thin, "\n")
    end

    test "the small-undrawn exception names a screen that is still small" do
      # Pinned from both ends like every allow-list here: a screen that grew
      # back past the ordinary floor has an entry hiding nothing.
      trees =
        in_empty_database(fn ->
          Map.new(Map.keys(@small_undrawn), fn module ->
            {:ok, _socket, tree} = ScreenSweep.render(module)
            {module, tree}
          end)
        end)

      for {module, floor} <- @small_undrawn do
        count =
          trees
          |> Map.fetch!(module)
          |> find_all(:text)
          |> Enum.map(&(&1.props[:text] || ""))
          |> Enum.reject(&(&1 == ""))
          |> length()

        assert count < @chrome_floor,
               "#{inspect(module)} renders #{count} strings, which clears the ordinary floor " <>
                 "of #{@chrome_floor}. Delete its @small_undrawn entry"

        assert count >= floor,
               "#{inspect(module)} renders #{count} strings against its own named floor of " <>
                 "#{floor}"
      end
    end

    test "the small-empty-board exception names a screen that is still small" do
      # An exception that stopped being needed would be an exemption for
      # nothing, so it is pinned from both ends like every allow-list here: the
      # screen has to still be under `@chrome_floor`, or its entry is hiding a
      # page that grew back and should be held to the ordinary bound.
      rendered = Map.new(render_migrated(), &{&1.number, &1.texts})

      for {number, floor} <- @small_empty_boards do
        count = length(rendered[number] || [])

        assert count < @chrome_floor,
               "#{number} renders #{count} strings, which clears the ordinary floor of " <>
                 "#{@chrome_floor}. Delete its @small_empty_boards entry"

        assert count >= floor,
               "#{number} renders #{count} strings against its own named floor of #{floor}"
      end
    end

    test "the lines quoted from another board are still on it, and still on the screen" do
      # The two screens the design draws no empty state for do not get to say
      # whatever they like. Both build their card by quoting a board that DOES
      # word the state, and a quotation can be checked at both ends — see
      # `@quoted`. This is what they have instead of a literal comparison, and it
      # is why an `@no_empty_board` entry is not an exemption from everything.
      refute @quoted == [],
             "the quotation list is empty, so @no_empty_board now buys total exemption. " <>
               "Delete the mechanism rather than keeping one that checks nothing"

      rendered = Map.new(render_migrated(), &{&1.number, &1.haystacks})

      dead =
        for {number, board, line} <- @quoted,
            normalised = DesignLiterals.normalise(line),
            not Enum.any?(DesignLiterals.read!(board).text, &String.contains?(&1, normalised)),
            do: "  #{number} quotes #{inspect(line)} from board #{board}, which no longer has it"

      assert dead == [],
             "a quotation is exempted from nothing and asserts nothing once the board it " <>
               "quotes has stopped saying it:\n" <> Enum.join(dead, "\n")

      unspoken =
        for {number, board, line} <- @quoted,
            normalised = DesignLiterals.normalise(line),
            DesignLiterals.locate(
              normalised,
              rendered[number] ||
                %{
                  nodes: [],
                  flow: "",
                  squashed: ""
                }
            ) == :missing,
            do: "  #{number} never draws #{inspect(line)}, which it takes from board #{board}"

      assert unspoken == [],
             "these screens have no empty board of their own and are held to the lines they " <>
               "quote from the boards that word the state instead. The quotation is gone from " <>
               "the screen:\n" <> Enum.join(unspoken, "\n")
    end
  end

  # ── What each screen must answer with when nothing is stored ────────────────

  # THE SCREENS THAT FALL BACK.
  #
  # `{number, module, what the screen reads, what the drawing is}`. The two
  # halves are both the screen's own functions wherever it has a named one, so
  # this file holds no second copy of any drawn value — a Sample edited on one
  # side and not the other is the failure mode a literal list here would create.
  #
  # `empties/0` below is the other half of this: the screens whose read answers
  # their emptiness rather than the drawing. Every screen in `@migrated` is in
  # one list or the other, and the two may overlap only where both statements
  # are true of the same screen — which today is 01 and 139 and nowhere else.
  #
  # 01 and 139 are NOT here any more, and that is this round's whole point.
  #
  # 01's entry used to be `rest_of_today(timeline())` compared with
  # `rest_of_today(drawn_rows())` — the assertion that an empty day drew the
  # drawing's `20:00 · The Long Hollow` and `21:30 · Call Mum`. It was written
  # as a debt and kept as one: #91 put screen 139 in front of a device with
  # nothing kept at all, so the substitution was only reachable by somebody who
  # had one tracked title and an empty calendar. `Kati.Sections.answered?/0` is
  # now the third term in `nothing_kept?/1`, which means everyone who answers
  # the first run's sections question reaches screen 01 — and the debt would
  # have been paid by every one of them, in invented rows. So the clause is
  # gone, an empty day draws screen 139's own sentence, and both halves of 01
  # are gated in `empties/0`. 139 has no rest-of-today card at all: it draws its
  # `Today` row itself, and `nothing_kept?/1` is the read it is gated on there.
  defp fallbacks(today) do
    [
      # 02, 03 and 07 are NOT here. Their reads answer their emptiness now, and
      # `empties/0` is the gate that says so — see the moduledoc.
      # 04 gates the whole page rather than a card — either every value on it is
      # this user's or every value is the drawing's — so one pair covers the
      # title, the meta line, the season strip, the counter, the next airing and
      # all seven rows. `by_season` rides on both sides, which is what makes the
      # S1/S2/S3 pills a control on an empty database too.
      # 05 gates on `:followed` being empty rather than on either list being
      # empty: "nothing is out this week" is a true thing for a release inbox to
      # say, and the drawing's three rows would be a false one. The pair
      # compares the whole map, watcher card included — that card is frozen, so
      # a round that wired its count up on its own would show here as the two
      # sides differing on a key neither list touches.
      # 12 does NOT gate the page. Two of its four *Kept automatically* rows
      # are the reader's own counts and the rest of the screen is the drawing's,
      # which is the arrangement screen 03 keeps — so the pair is asked of the
      # rows themselves: `Rewatches · 0` and `Abandoned · 0` on an empty store,
      # against the drawing's own two rows. The other two rows were retired
      # with the lines they carried (MOVIES-AND-TV.md #106).
      {"12", Kati.Screens.Lists, &Kati.Screens.Lists.kept_rows/0,
       fn ->
         # Board 331 gave each kept row its own empty sentence — *Add to list* is
         # a lie on a shelf you cannot add to — and board 333 gave it an id, so
         # a kept list can be opened and its detail page can say which one it is.
         [
           %{
             id: "kept:rewatches",
             icon: "replay",
             title: "Rewatches",
             count: "0",
             empty_title: "Nothing rewatched",
             empty_body:
               "Kati fills this one — log a watch of something you have seen and it lands here."
           },
           %{
             id: "kept:abandoned",
             icon: "do_not_disturb_on",
             title: "Abandoned",
             count: "0",
             empty_title: "Nothing abandoned",
             empty_body: "Kati fills this one — drop a show and it lands here."
           }
         ]
       end},
      # 98, 100 and 101 gate on the same map — the subtitle, the hours face and
      # the three titles arrive together or not at all, which is the whole-page
      # rule screens 04 and 08 keep. An empty history answers board 98's card,
      # which is the state all three boards were captured in. 99 is 98 with the
      # Books chip lit and 101 is the five states of 100's cards; both draw 98's
      # own card and reach the read through it.
      # 25 gates on the banner, which is the only part of it that reads
      # anything: the ten switches and the cadence are still
      # `Kati.Settings.WatcherSample`'s, and MOVIES-AND-TV.md #67 is what says
      # so — they edit one socket assign and nothing consumes them.
      # 23 gates on the whole ledger: the count, the total, every row and the
      # advice card arrive together or the board's do.
      # 18 gates on the whole draft: the sentence, the title, the chips, the
      # clash and the button's word arrive together or the board's do. An
      # untyped field is the board.
      {"18", Kati.Screens.QuickAdd, fn -> Kati.Screens.QuickAdd.draft("") end,
       &Kati.Screens.QuickAdd.Sample.draft/0},
      # 11 gates on the seed rather than on the feed: `Kati.Media.Recommendations.seed/0`
      # is the title the picks would be drawn FROM, and an empty store has
      # none. One pair covers the subtitle, the four chips, the heading, the
      # three picks with their percentages, the three people and the two
      # leaving rows, because they arrive as one map or not at all.
      # 14 gates like 04: one pair covers the title, the still, the meta line,
      # the synopsis, the three ratings, the four cast members, the three ways
      # to watch and the five tags, because they arrive as one map or not at
      # all. An empty store has no shelf row to describe, so the answer is the
      # board — and a device with a series on it gets four real values and
      # three empty bands, which is the half of this that only
      # `Kati.SeriesMetaSubjectTest` can see.
      # 09 is asked the question this file's renders ask: a bare push, the one
      # `Kati.Screens.ViewSwitcher` sends and the one `render_migrated/0` makes,
      # must answer with the drawn day whole — its date, its fourteen
      # occurrences and the flag that keeps the band, the renewals row and the
      # `14 items · 2 clashes` headline drawn. Compared as the triple `day/1`
      # answers rather than as its occurrences alone: the flag is what the other
      # three read, so a gate that dropped it would pass while the day went
      # bare.
      #
      # 31 is gated on the branch that READS: an id that names nothing stored,
      # which on an empty database is every id there is. That is the fallback a
      # push can actually land on — an event deleted on another device, a
      # restored backup, a fresh install — and it has to answer with the drawing
      # rather than with a blank page. The no-id path is pinned in
      # `Kati.EventRowIdentityTest` beside the tap that produces an id, where
      # the two can be compared with each other.
      {"31", Kati.Screens.EventDetail,
       fn -> Kati.Screens.EventDetail.event(%{id: Ecto.UUID.generate()}) end,
       &Kati.Calendar.SampleEvent.event/0},
      # 52 is gated the way 09 is, on the branch a bare push lands on, because it
      # is the same branch: `day/1` with no `:date` answers the drawn day whole
      # — the heading, the spine and the `drawn?` flag the collapse row and the
      # chips read. Not gated on a handed date against an empty store, for 09's
      # reason: a day that holds nothing is empty, and drawing five meals on it
      # would be the substitution this file exists to catch.
      {"52", Kati.Screens.MealsDay, fn -> Kati.Screens.MealsDay.day(%{}) end,
       &Kati.Screens.MealsDay.drawn_day/0},
      {"32", Kati.Screens.Calendars, &Kati.Screens.Calendars.calendar_list/0,
       &Kati.Screens.Calendars.drawn_calendars/0},
      # 34 is the partly-migrated one, and the whole map is compared for exactly
      # that reason: the order strip, the two switches and the subtitle are the
      # drawing's on BOTH branches, so a gate that looked only at the episode
      # list would pass while one of the frozen parts quietly changed.
      # 35 gates the whole `show/1` map for 34's reason and one of its own: the
      # map carries both the values (status, the four season-pass switches) and
      # the two flags that decide whether *Region & availability* and *This
      # show* are drawn at all. On an empty store every one of those is the
      # board's, groups included, which is the page the gallery renders.
      # 13 gates the whole `tonight/1` map, because the window, the count, the
      # rows and the `61 MIN OVER` on the last one are four views of one
      # number. A gate that compared only the list would pass while the sentence
      # above it described a film nobody has.
      # 37 is gated on the branch a bare push lands on, which is every push
      # that names no file: the gallery's, a sweep's, and screen 140's
      # *Something else*. `job_for/1` then answers `Kati.Import.Sample`'s whole
      # job — the file name, the shape, the five columns, the counts and the
      # conflict — which is the state board 37 was captured in.
      #
      # NOT gated on a path naming nothing readable. That answers the drawing
      # too, with `:refusal` on it so the screen can say why, and those are two
      # different renders on purpose: a file that could not be read is a thing
      # to tell somebody about, and a push that named no file is not.
      # 36 gates the whole `detect/0` map: the banner's count, the Now playing
      # card, the Sources rows and the decision are five views of one device,
      # and a gate on the banner alone would pass while the card described a
      # session nobody is playing.
      # 28 is NOT here any more, and neither is 55. Both used to compare
      # `rest_of_today(Kati.Calendars.Today.rows())` with
      # `rest_of_today(Sample.rest_of_today())` — the assertion that a device
      # with nothing mirrored drew the drawing's 20:00 and 21:30. That is the
      # substitution #91 is about, one colourway and one script over, and their
      # gates are in `empties/0` now, one per band.
      # 29 answers with all four widgets at once, because it falls back one
      # widget at a time: three that still drew the drawing would hide a fourth
      # that had stopped being able to.
      # 20 gates the whole page as 66 does, and for the reason its own moduledoc
      # gives: the grid, the hero, the subtitle and the chip counts are four
      # views of one shelf, so one pair covers all four and a gate that looked
      # only at the grid would pass while the hero named a book nobody owns.
      {"20", Kati.Screens.Books, &Kati.Screens.Books.page/0, &Kati.Screens.Books.drawn_page/0},
      # 176 gates the whole page exactly as 20 does, through the same pair of
      # names: the Persian shelf reads `Kati.Books.Book`'s `:shelf` once and the
      # grid, the hero, the header line and the four chip counts all come out of
      # that one answer, so one pair covers all four and a gate that looked only
      # at the grid would pass while the hero named a book nobody owns.
      {"176", Kati.Screens.Books, &Kati.Screens.Books.page/0, &Kati.Screens.Books.drawn_page/0},
      # 66 gates the whole page, as 04 does: either every value on it is this
      # reader's book or every value is the drawing's, so one pair covers the
      # hero, the ratings, the edition facts, the notes and the history band.
      {"66", Kati.Screens.BookDetail, &Kati.Screens.BookDetail.book/0,
       &Kati.Screens.BookDetail.drawn_book/0},
      # 70 falls back to the same book 66 does, and deliberately through 66's own
      # reader rather than a second one — a sheet aimed at a different book from
      # the screen that opened it would write a session against the wrong title.
      # That is what this pair pins: not that the sheet has a fallback, but that
      # it is 66's.
      {"70", Kati.Screens.LogProgress, &Kati.Screens.LogProgress.book/0,
       &Kati.Screens.BookDetail.drawn_book/0},
      # 21 gates the whole page as 20 does, and for the reason its own moduledoc
      # gives: the three tiles, the listening card, the release band and the
      # header's count are four views of one shelf, so one pair covers all four
      # and a gate that looked only at the tiles would pass while the card
      # totalled hours nobody listened to.
      {"21", Kati.Screens.Music, &Kati.Screens.Music.page/0, &Kati.Screens.Music.drawn_page/0},
      # 74 and 77 gate the whole page for the reason 66 does. 73 gates the album
      # rather than the tracklist, and through 74's own reader: a sheet aimed at
      # a different album from the screen that opened it would credit the wrong
      # record.
      {"73", Kati.Screens.LogListen, &Kati.Screens.LogListen.album/0,
       &Kati.Screens.AlbumDetail.drawn_album/0},
      {"74", Kati.Screens.AlbumDetail, &Kati.Screens.AlbumDetail.album/0,
       &Kati.Screens.AlbumDetail.drawn_album/0},
      {"77", Kati.Screens.ArtistDetail, &Kati.Screens.ArtistDetail.artist/0,
       &Kati.Screens.ArtistDetail.drawn_artist/0},
      # 92 and its three borrowers moved to `empties/0` on 6 September. They
      # gated the service groups the way every screen here used to — an empty
      # store answered `Kati.Services.Sample` — and MOVIES-AND-TV.md #75 is
      # what that looked like on a phone: Home saying *No subscriptions yet*
      # and 92, one tap later, listing Lumen+ £8.99, Orbit £13.99, Kino £11.49
      # and `£46.47 A MONTH`. The groups read the store now and answer with
      # nothing when it holds nothing; board 92 is compared in the state it is
      # a drawing OF by `Kati.ScreenDesignLiteralTest.drawn_state/0`.
      # #25 and #11's readers. Four of the six borrow the pair they are built
      # on, which is the shape 120 already uses: the screen draws another
      # screen's `drawn_*` value, so what it depends on is that the borrowed
      # pair still agrees on an empty database, and that is what this asks.
      # 129 and 135 write rather than read: what they draw at rest is
      # `Kati.Backup.SampleRestore`'s fixture, and the database only enters on
      # the tap that restores. Their gate is 128's for the reason 106's is
      # 104's — a screen that restored into a Kati whose service list disagreed
      # with the page that sent it there would be the defect worth catching.
      # 26 writes rather than reads: what it draws is its own section tiles, and
      # the database is only touched when someone answers the calendar dialog.
      # Gated on 128's reader for the reason 106 is gated on 104's — a first run
      # that ingested a calendar into a Kati whose service list disagreed with
      # the page that sent it there would be the defect worth catching.
      # 06 draws its own search results and writes on a tap; what it READS from
      # the store on an empty database is nothing at all. Gated on 92's reader
      # for the reason 106 is gated on 104's — a sheet that added a title into
      # a Kati whose service list disagreed with the page that opened it would
      # be the defect worth catching.
      # 154 draws its own form and reads nothing: it WRITES on Add, which is
      # why it is on the migrated list at all. Gated on 92's reader for the
      # reason 06 is — a form that added a title into a Kati whose service list
      # disagreed with the page that opened it would be the defect worth
      # catching.
      # D-39's add path. 178 draws its own form and 179 its own transcription of
      # board 179's three rows; neither reads the store at all, and both are on
      # the migrated list because they WRITE on a tap. Gated on 92's reader the
      # way 154 and 06 are, and for their reason — a form that shelved a record
      # into a Kati whose service list disagreed with the page that opened it
      # would be the defect worth catching.
      # 180 is gated on screen 74's own reader, not on a second one, for the
      # reason screen 73 is: the sheet and the page that opened it must be
      # about one record, and an id is what turns a shared reader into a shared
      # referent. With nothing shelved both answer the drawing, which is the
      # branch that makes `save_rating/1` refuse rather than commit the
      # fixture's rating onto somebody's shelf.
      {"180", Kati.Screens.RateAlbum, &Kati.Screens.AlbumDetail.album/0,
       &Kati.Screens.AlbumDetail.drawn_album/0},
      # 177 is 154 in its Book kind: it draws its own form and reads nothing,
      # and it is on the migrated list because Add to library writes a
      # `Kati.Books.Book`. Gated the way 154 is, for 154's reason — a form that
      # put a book on the shelf of a Kati whose service list disagreed with the
      # page that opened it would be the defect worth catching.
      # 163 and 166 draw four posters and a tick and read nothing; they are on
      # the migrated list because Finish writes the picked title. Gated the way
      # 154 is, for 154's reason — a first run that shelved a title into a Kati
      # whose service list disagreed with the page that sent it there would be
      # the defect worth catching.
      # 155 reads nothing at all — it is a picture of 154's two states, and it
      # is on the migrated list only because it calls 154's own helpers and the
      # list is derived from the compiled import table. Gated the same way 154
      # is, for the same reason.
      # 156 and 157 are 154 in another script and another colourway, and read
      # exactly what it reads — nothing. On this list because they call its
      # helpers and the list is derived from the compiled import table.
      # 158 IS the empty state — it is screen 55 with nothing kept, so it
      # answers with its own emptiness rather than falling back to a drawing.
      # `Kati.Screens.HomeEmpty` is gated the same way for the same reason.
      # 149 is NOT here: it gates on `Kati.Screens.Library.titles/0`, which #91
      # made answer with the shelf and nothing else. Its gate is in `empties/0`,
      # still through Library's own reader for the reason it always was.
      # 80 reads the metadata cache rather than a domain the user writes to, so
      # what it falls back to is a sentence about there being nothing — which is
      # the correct thing for a cache page to say and is asserted as itself.
      {"80", Kati.Screens.DataSources, &Kati.Screens.DataSources.cache_size/0,
       fn -> "Nothing cached yet" end},
      # 104 gates all three cards at once, as 66 does: either every goal on the
      # page is yours or every one is the drawing's.
      {"104", Kati.Screens.Goals, &Kati.Screens.Goals.goals/0, &Kati.Screens.Goals.drawn_goals/0},
      # 106 writes rather than reads, and what it reads is the kind list, which
      # is a constant of the build. Its gate is 104's, because a sheet whose
      # types disagreed with the page that opened it would be the defect worth
      # catching.
      {"106", Kati.Screens.NewGoal, &Kati.Screens.Goals.goals/0,
       &Kati.Screens.Goals.drawn_goals/0},
      {"122", Kati.Screens.Money, &Kati.Screens.Money.months/0,
       &Kati.Screens.Money.drawn_months/0},
      # 124 and 125 both write to a store and read one value back — the
      # currency — which is `Mob.State` rather than the database and is
      # therefore the same on an empty one. Gated on 122's reader for the same
      # reason 106 is gated on 104's.
      {"124", Kati.Screens.QuickAddExpense, &Kati.Screens.Money.months/0,
       &Kati.Screens.Money.drawn_months/0},
      {"125", Kati.Screens.Currency, &Kati.Screens.Money.months/0,
       &Kati.Screens.Money.drawn_months/0},
      # 109 gates the entry list, which is what the hero, the chart and every
      # delta on the page are derived from — one read, so one gate. 111 gates on
      # it too, for the reason 70 gates on 66's: the sheet's confirmation is
      # arithmetic over the same series the page charts.
      {"109", Kati.Screens.Weight, &Kati.Screens.Weight.entries/0,
       &Kati.Screens.Weight.drawn_entries/0},
      {"111", Kati.Screens.LogWeight, &Kati.Screens.Weight.entries/0,
       &Kati.Screens.Weight.drawn_entries/0},
      {"112", Kati.Screens.Medication, &Kati.Screens.Medication.doses/0,
       &Kati.Screens.Medication.drawn_doses/0},
      # 189 has a reader of its own and it is the one that matters: handed an
      # id that names nothing — which is every id on an empty database — the
      # page must answer with its own drawing, whose absent `:id` is what stops
      # every control on it writing to a stranger.
      {"189", Kati.Screens.MedicationDetail, &Kati.Screens.MedicationDetail.medication/0,
       &Kati.Screens.MedicationDetail.drawn_medication/0},
      # 188 writes and reads nothing; 190 reads nothing at all and is on the
      # migrated list because it draws screen 104's chrome. Both gate on 112's
      # doses for the reason 119 gates on 118's meal and 106 on 104's goals: a
      # sheet that added a medication into a Kati whose Today group disagreed
      # with the page that opened it would be the defect worth catching.
      {"188", Kati.Screens.AddMedication, &Kati.Screens.Medication.doses/0,
       &Kati.Screens.Medication.drawn_doses/0},
      {"190", Kati.Screens.MedicationEmpty, &Kati.Screens.Medication.doses/0,
       &Kati.Screens.Medication.drawn_doses/0},
      # 116 gates the whole grid, 118 the meal it is editing. 119 reads nothing
      # of its own — it is a form over a draft — so it gates on 118's meal, for
      # the reason 70 gates on 66's: a sheet aimed at a different meal from the
      # screen that opened it would add an ingredient to the wrong one.
      {"116", Kati.Screens.MealLibrary, &Kati.Screens.MealLibrary.meals/0,
       &Kati.Screens.MealLibrary.drawn_meals/0},
      {"118", Kati.Screens.MealEdit, &Kati.Screens.MealEdit.meal/0,
       &Kati.Screens.MealEdit.drawn_meal/0},
      {"119", Kati.Screens.AddIngredient, &Kati.Screens.MealEdit.meal/0,
       &Kati.Screens.MealEdit.drawn_meal/0},
      {"100", Kati.Screens.YearCards, &Kati.Screens.AlbumDetail.field/0,
       &Kati.Music.Sample.listen_field/0},
      {"69", Kati.Screens.BookDetail, &Kati.Screens.BookDetail.book/0,
       &Kati.Screens.BookDetail.drawn_book/0},
      {"72", Kati.Screens.LogProgress, &Kati.Screens.LogProgress.book/0,
       &Kati.Screens.BookDetail.drawn_book/0},
      {"67", Kati.Screens.BookDetailStates, &Kati.Screens.BookDetail.book/0,
       &Kati.Screens.BookDetail.drawn_book/0},
      {"68", Kati.Screens.BookDetailDark, &Kati.Screens.BookDetail.book/0,
       &Kati.Screens.BookDetail.drawn_book/0},
      {"71", Kati.Screens.LogProgressStates, &Kati.Screens.LogProgress.book/0,
       &Kati.Screens.BookDetail.drawn_book/0},
      {"75", Kati.Screens.AlbumDetailStates, &Kati.Screens.AlbumDetail.album/0,
       &Kati.Screens.AlbumDetail.drawn_album/0},
      {"78", Kati.Screens.ArtistDetailStates, &Kati.Screens.ArtistDetail.artist/0,
       &Kati.Screens.ArtistDetail.drawn_artist/0},
      {"76", Kati.Screens.AlbumDetail, &Kati.Screens.AlbumDetail.album/0,
       &Kati.Screens.AlbumDetail.drawn_album/0},
      {"81", Kati.Screens.DataSourcesStates, &Kati.Screens.DataSources.cache_size/0,
       &Kati.Screens.DataSources.nothing_cached/0},
      {"82", Kati.Screens.DataSources, &Kati.Screens.DataSources.cache_size/0,
       &Kati.Screens.DataSources.nothing_cached/0},
      {"126", Kati.Screens.MoneyDay, &Kati.Screens.MoneyDay.rows/0,
       &Kati.Screens.MoneyDay.drawn_rows/0},
      {"103", Kati.Screens.YearShare, &Kati.Screens.AlbumDetail.field/0,
       &Kati.Music.Sample.listen_field/0},
      {"105", Kati.Screens.GoalsEmpty, &Kati.Screens.Goals.goals/0,
       &Kati.Screens.Goals.drawn_goals/0},
      {"110", Kati.Screens.WeightStates, &Kati.Screens.Weight.entries/0,
       &Kati.Screens.Weight.drawn_entries/0},
      {"113", Kati.Screens.HealthEmptyStates, fn -> Kati.Screens.Health.day(today) end,
       &Kati.Screens.Health.drawn_day/0},
      {"107", Kati.Screens.GoalStates, &Kati.Screens.Goals.goals/0,
       &Kati.Screens.Goals.drawn_goals/0},
      {"114", Kati.Screens.RetiredTile, fn -> Kati.Screens.Health.day(today) end,
       &Kati.Screens.Health.drawn_day/0},
      {"117", Kati.Screens.MealLibraryEmpty, &Kati.Screens.MealLibrary.meals/0,
       &Kati.Screens.MealLibrary.drawn_meals/0},
      {"123", Kati.Screens.MoneyStates, &Kati.Screens.Money.months/0,
       &Kati.Screens.Money.drawn_months/0},
      {"61", Kati.Screens.Stats, &Kati.Screens.Goals.goals/0, &Kati.Screens.Goals.drawn_goals/0},
      # The four pictures, each gated on the pair it borrows rather than on a
      # read of its own — the same shape 120 already uses. 121 draws 44's week
      # grid, 127 draws 122's months, and 63 and 64 both draw 28's lock widgets.
      {"121", Kati.Screens.WeekImage, fn -> Kati.Screens.MealPlan.plan(today) end,
       &Kati.Screens.MealPlan.drawn_plan/0},
      {"42", Kati.Screens.Health, fn -> Kati.Screens.Health.day(today) end,
       &Kati.Screens.Health.drawn_day/0},
      {"43", Kati.Screens.MealsToday, fn -> Kati.Screens.MealsToday.day(today) end,
       &Kati.Screens.MealsToday.drawn_day/0},
      {"44", Kati.Screens.MealPlan, fn -> Kati.Screens.MealPlan.plan(today) end,
       &Kati.Screens.MealPlan.drawn_plan/0},
      {"45", Kati.Screens.Meal, fn -> Kati.Screens.Meal.meal(today) end,
       &Kati.Screens.Meal.drawn_meal/0},
      {"47", Kati.Screens.Nutrition, fn -> Kati.Screens.Nutrition.figures(today) end,
       &Kati.Screens.Nutrition.drawn_figures/0},
      {"48", Kati.Screens.Shopping, fn -> Kati.Screens.Shopping.list(today) end,
       &Kati.Meals.SampleShopping.list/0},
      # 54 is in this list mechanically rather than because anything falls back.
      # Its Currency row reads `Kati.Money.currency/0`, which answers "GBP" with
      # nothing stored — so a fresh device draws the line the board was captured
      # with, and the pair is here to catch those drifting apart, not to permit
      # a drawing. The row was the literal `"£ GBP"` until the reader's own
      # currency replaced it.
      {"54", Kati.Screens.Language, &Kati.Language.Sample.currency_line/0, fn -> "£ GBP" end}
    ]
  end

  # THE SCREENS THAT ANSWER WITH THEIR EMPTINESS.
  #
  # `{number, module, what the screen reads, what an empty store answers,
  # what the drawing is}`, and both halves of the claim matter:
  #
  #   * `read == empty` — the screen's own entry point answers `[]`, `nil` or
  #     `true` on a database with nothing in it. That is what a person's first
  #     launch actually calls, and it is the assertion that fails the day
  #     somebody puts `case shelf() do [] -> drawn_titles()` back.
  #   * `drawn != empty` — the transcription the screen used to fall back to
  #     still holds something. Without it the first claim goes vacuous the
  #     moment a Sample module is emptied: two nothings agreeing proves nothing,
  #     and every `drawn_*` here is still public precisely so that
  #     `Kati.ScreenDesignLiteralTest` can render the board out of it.
  #
  # Both sides go through the screen's own functions, for the reason
  # `fallbacks/0` gives: no second copy of any value lives in this file.
  defp empties(today) do
    [
      # 04 answers its own empty page rather than the drawing. `empty_series/0`
      # is board 248's seventeen keys with the title and year emptied too — the
      # frame 04 already draws for a series whose episode list it does not have,
      # with nothing in the slots. `drawn_series/0` stays on the right of the
      # pair: it is what `Kati.ScreenDesignLiteralTest` installs to compare the
      # page against .scratch/design/audit/04.png, and nothing else reads it.
      # 35 answers its own empty page now. The map still carries both the values
      # and the two flags that decide whether *Region & availability* and *This
      # show* are drawn, and those flags stay nil — both bands are the drawing's
      # and both are already dropped over a real show.
      {"35", Kati.Screens.SeriesSettings, fn -> Kati.Screens.SeriesSettings.show(%{}) end,
       Kati.Screens.SeriesSettings.empty_show(),
       fn -> Map.put(Kati.SeriesSettings.Sample.show(), :tracked, nil) end},
      # 98 and 99 answer a year with nothing counted. This matters more here
      # than on most screens: a share card is built to be saved and sent, so an
      # invented one does not merely mislead the person holding the phone — it
      # travels. 99 is 98 with the Books chip lit and reaches the same read.
      {"98", Kati.Screens.YearShare, &Kati.Screens.YearShare.share/0,
       Kati.Screens.YearShare.empty_share(), &Kati.Screens.YearShare.drawn_share/0},
      {"99", Kati.Screens.YearShareBooks, &Kati.Screens.YearShare.share/0,
       Kati.Screens.YearShare.empty_share(), &Kati.Screens.YearShare.drawn_share/0},
      # 101 draws 98's own card too and reaches the read through it.
      {"101", Kati.Screens.YearCardsStates, &Kati.Screens.YearShare.share/0,
       Kati.Screens.YearShare.empty_share(), &Kati.Screens.YearShare.drawn_share/0},
      # 33 and 144 answer their own empty sheet. The draft used to be
      # `Kati.Rating.Sample.watch/0`, so opening the log sheet over a film with
      # nothing logged handed the reader Blue Hour's 8, its review body, its
      # spoiler flag and its three context rows — and `writable?/1` was the only
      # thing standing between that and Save filing it under their own row.
      #
      # `:watched_at` is dropped from both sides: an unlogged sheet defaults its
      # hour to the moment it is read, exactly as `blank_for/1` does, so the two
      # calls below are microseconds apart over a field neither branch chose.
      {"33", Kati.Screens.Rating, fn -> Map.drop(Kati.Screens.Rating.watch(), [:watched_at]) end,
       Map.drop(Kati.Screens.Rating.empty_watch(), [:watched_at]),
       &Kati.Screens.Rating.drawn_watch/0},
      {"144", Kati.Screens.RateEpisode,
       fn -> Map.drop(Kati.Screens.Rating.watch(), [:watched_at]) end,
       Map.drop(Kati.Screens.Rating.empty_watch(), [:watched_at]),
       &Kati.Screens.Rating.drawn_watch/0},
      # 86 and 87 gate on the same read, which is the only one either makes.
      # `for_reader/1` fell back to board 86's own two — *what leaves this
      # week*, *notes about the estuary* — under a caption promising they are
      # drawn from this reader's library, and they match nothing on any device
      # but the one the board was captured on. `try_group/1` draws a worded card
      # over `[]` instead, and both that function and `Kati.Search.suggestions/0`
      # behind it are deleted.
      {"86", Kati.Screens.SearchIdle, &Kati.Search.Suggestions.derived/0, [],
       fn -> ["what leaves this week", "notes about the estuary"] end},
      {"87", Kati.Screens.SearchTyping, &Kati.Search.Suggestions.derived/0, [],
       fn -> ["what leaves this week", "notes about the estuary"] end},
      # 29 answers four empty widgets. It used to answer the board's four, so a
      # fresh install's lock screen promised *The Long Hollow S2E6*, six
      # episodes airing tonight, four things left today and a 312-hour year on
      # an eleven-night streak — every figure on the page the board's own.
      # 63 and 64 borrow 29's pair rather than reading anything themselves, the
      # shape 120 already uses.
      #
      # `:clock` is dropped from all three: it reads the device now, so the two
      # calls below are a moment apart over a field that is neither branch's.
      {"29", Kati.Screens.Lock, fn -> Map.drop(Kati.Screens.Lock.widgets(), [:clock]) end,
       Map.drop(Kati.Screens.Lock.empty_widgets(), [:clock]), &Kati.Screens.Lock.drawn_widgets/0},
      {"63", Kati.Screens.MarkIos, fn -> Map.drop(Kati.Screens.Lock.widgets(), [:clock]) end,
       Map.drop(Kati.Screens.Lock.empty_widgets(), [:clock]), &Kati.Screens.Lock.drawn_widgets/0},
      {"64", Kati.Screens.MarkAndroid, fn -> Map.drop(Kati.Screens.Lock.widgets(), [:clock]) end,
       Map.drop(Kati.Screens.Lock.empty_widgets(), [:clock]), &Kati.Screens.Lock.drawn_widgets/0},
      # 37 and 141 answer their own empty state. A push naming no file is not
      # only the gallery: *Something else* on screen 140 is a routed row, and it
      # opened 37 on `trakt-backup.csv` — five columns of somebody else's film
      # export, under a plan promising 384 new records, 28 merged and 6
      # conflicts — for a reader who had picked nothing. 141 announced 418 rows,
      # nine columns and seven matched over the same nothing. `live?/1` kept
      # both commit pills inert, so the numbers could not be acted on; they were
      # still the only thing on either page.
      #
      # 141's refusal branch had already reached this conclusion for the case
      # one step over — *"a page that draws them anyway is lying in nine places
      # to apologise in one"* — and a push that named no file has less to say
      # than a refusal does, not more.
      {"37", Kati.Screens.Import, fn -> Kati.Screens.Import.job_for(%{}) end,
       Kati.Screens.Import.empty_job(), fn -> Kati.Import.Sample.job(:trakt) end},
      {"141", Kati.Screens.ImportRecognised, fn -> Kati.Screens.ImportRecognised.job_for(%{}) end,
       Kati.Screens.ImportRecognised.empty_recognised(), &Kati.Import.Sample.recognised/0},
      # 15 is an append-only record of what the reader DID, so a device that has
      # done nothing has to say so. It reported 1,204 entries over seven
      # invented rows on every fresh install.
      {"15", Kati.Screens.Activity, &Kati.Screens.Activity.log/0, Kati.Screens.Activity.empty(),
       &Kati.Screens.Activity.drawn/0},
      # 23 answers an empty ledger with nothing subscribed. It drew `5 active`,
      # `£46.47`, `Up £4.00` and four services — a bill, to a reader who pays
      # for nothing.
      {"23", Kati.Screens.Subscriptions, &Kati.Screens.Subscriptions.ledger/0,
       Kati.Screens.Subscriptions.empty_ledger(), &Kati.Screens.Subscriptions.drawn_ledger/0},
      # 11 answers an empty feed. A recommendation is an answer to *because you
      # watched X*, and `Recommendations.seed/0` answers nil when there is no X.
      # It drew the WHOLE page from the fixture, subtitle included.
      {"11", Kati.Screens.Discover, &Kati.Screens.Discover.feed/0,
       Kati.Screens.Discover.empty_feed(), &Kati.Screens.Discover.Sample.feed/0},
      # 14 answers an empty page. `tracked_meta/1` answers nil for three
      # different reasons and only one is "this reader owns nothing" — an id
      # naming no row and a read that raised both landed on the drawing too.
      {"14", Kati.Screens.SeriesMeta, &Kati.Screens.SeriesMeta.series/0,
       Kati.Screens.SeriesMeta.empty_series(), &Kati.Screens.SeriesMeta.Sample.series/0},
      # 25's banner counts zero on a device that follows nothing. It answered
      # `Watching 24 titles` and `3 found this week`, with the reason written
      # beside it — "Watching 0 titles over a page of switches is a page about
      # nothing." A page about nothing is a true thing for this page to say to a
      # reader who follows nothing, and the switches under it still work.
      {"25", Kati.Screens.ReleaseWatcher, &Kati.Screens.ReleaseWatcher.banner/0,
       Kati.Screens.ReleaseWatcher.banner(), &Kati.Settings.WatcherSample.banner/0},
      # 36 reads its own unavailable state now. It answered `drawn_detect/0`
      # whenever access was `:unavailable`, which is EVERY sideloaded build —
      # Play Protect blocks the listener it reads — so the one state a real
      # reader of this APK is always in was the one drawing the fixture.
      {"36", Kati.Screens.AutoDetect, &Kati.Screens.AutoDetect.detect/0,
       Kati.Screens.AutoDetect.detect(), &Kati.Screens.AutoDetect.drawn_detect/0},
      # 34 answers an empty season. `tracked_season/2` answers nil for a season
      # nobody named as readily as for an empty shelf, so a push that lost its
      # params described somebody else's running order. The order strip keeps
      # its three labels — that is the app's vocabulary, not a claim.
      {"34", Kati.Screens.Season, &Kati.Screens.Season.season/0,
       Kati.Screens.Season.empty_season(), &Kati.Screens.Season.drawn_season/0},
      # 13 answers an empty window. `real_tonight/1` answers nil for two reasons
      # and only one is "nothing fits" — it is wrapped in a `rescue`, so a read
      # that raised landed on the drawing too. The clock and the chosen window
      # stay real, and the five length buckets stay because they are what can be
      # ASKED rather than an answer.
      {"13", Kati.Screens.WhatFits, &Kati.Screens.WhatFits.tonight/0,
       Kati.Screens.WhatFits.empty_tonight(), &Kati.Screens.WhatFits.drawn_tonight/0},
      # 39 answers `nil` with nothing queued — the preview says so rather than
      # drawing the board's four tiles, three of which were widgets nobody can
      # add to a home screen.
      {"39", Kati.Screens.Widgets, &Kati.Screens.Widgets.up_next_now/0, nil,
       fn -> Kati.Widgets.Sample.widgets().up_next end},
      # 09 answers `[]` for every empty day now, today included. The comment
      # here used to say the no-date branch was "deliberately NOT gated on a
      # handed date, because that answers `[]`, and `[]` is the right answer" —
      # the two branches just disagreed. They agree now: a day with nothing on
      # it is empty whichever day it is.
      {"09", Kati.Screens.Day, fn -> Kati.Screens.Day.day(%{}) end, {today, [], false},
       fn -> {today, Kati.Calendar.SampleDay.occurrences(), true} end},
      # 146 gates on the list, which is the whole of what it draws that could
      # come from anywhere: the tiles, which start selected, and every count the
      # header composes from them. An empty shelf answers with nothing now —
      # the board's own nine were nine titles a reader who owns none was being
      # offered to select, two of them already ticked.
      {"146", Kati.Screens.ShelfSelection, &Kati.Screens.ShelfSelection.shelf/0, [],
       &Kati.Library.Sample.selection_shelf/0},
      # 08 makes the same move as 04: `empty_film/0` is `shaped/3`'s sixteen
      # keys carrying nothing, so a reader who owns no films is shown an empty
      # frame rather than the board's own *Blue Hour* and its viewing history.
      {"08", Kati.Screens.Film, &Kati.Screens.Film.film/0, Kati.Screens.Film.empty_film(),
       &Kati.Screens.Film.drawn_film/0},
      {"04", Kati.Screens.Series, &Kati.Screens.Series.series/0,
       Kati.Screens.Series.empty_series(), &Kati.Screens.Series.drawn_series/0},
      # 58 is 04's gate reached through 04's read, so it moves with it: the
      # mirror cannot keep drawing its drawing once `series/0` answers the empty
      # page on an empty store. One pair still covers both defects, a Persian
      # fallback and an English one, because both sides read the same function.
      {"58", Kati.Screens.Series, &Kati.Screens.Series.series/0,
       Kati.Screens.Series.empty_series(), &Kati.Screens.Series.drawn_series/0},
      # 01 and 139: `nothing_kept?/1` is the branch between the two boards. It
      # counts `Kati.Media.TrackedTitle`, reads the timeline and asks
      # `Kati.Sections.answered?/0`, and it decides which of the two pages a
      # device with nothing on it is shown. Handed the timeline an empty device
      # has it answers `true`; handed the one the drawing holds it answers
      # `false`, which is what makes the first answer a result rather than a
      # constant.
      #
      # It is no longer what stands between a person and a page of invented
      # rows. The four entries under 01 below are, one per band, and they are
      # the ones that fail the day somebody puts a literal back.
      # 19 and 89 read the store through `Kati.Search.Query.run/1`, and there is
      # nothing to fall back to any more: `Kati.Screens.Search.Sample` is gone
      # and the screen draws its own idle and no-match states instead. So the
      # gate is the read itself — a query against an empty database answers
      # with empty groups, and the same query against a store with the row in
      # it does not.
      # 46's read is the slot screen 43 hands over, and an empty store has no
      # plan to take one from — so the gate is that handover answering nothing,
      # which is what puts the page on `Kati.Meals.SampleSwap`'s drawing.
      {"46", Kati.Screens.MealSwap, &Kati.Screens.MealSwap.handed_over/0, nil,
       fn -> "a-slot-id" end},
      # 10 joined 12 and 92: `queue/0` used to fall back to `Sample.queue/0`
      # whole whenever the shelf had never held anything or an unreadable
      # store rescued to the same `[]` a genuinely empty one does. Both cases
      # now answer `empty/0`, the same honest card a shelf holding only
      # finished or dropped titles already got — no gate is needed to tell
      # them apart any more, so the pair is a straight whole-map comparison.
      {"10", Kati.Screens.UpNext, &Kati.Screens.UpNext.queue/0, Kati.Screens.UpNext.empty(),
       &Kati.Screens.UpNext.Sample.queue/0},
      # 152's gate is misclassified/0 — nil on a device with nothing tagged
      # anime by a guess rather than the reader's own tag, a map once there
      # is one. Kati.Media.AnimeSample.misclassified/0 is the drawn Marram
      # card the board was captured with.
      {"152", Kati.Screens.AnimeFilter, &Kati.Screens.AnimeFilter.misclassified/0, nil,
       &Kati.Media.AnimeSample.misclassified/0},
      # 167's gate is the same one screen 10 makes: no fallback, an empty
      # pool's own zeroed counts through the same device_state/2 a real queue
      # goes through, never board 167's own fifteen.
      {"167", Kati.Screens.UpNextFilters, &Kati.Screens.UpNextFilters.opening/0,
       Kati.Screens.UpNextFilters.device_state(
         %{ready: [], cold: []},
         Kati.Library.UpNextFilters.resting()
       ), &Kati.Screens.UpNextFilters.drawn_opening_for_test/0},
      # 145's gate is its whole opening state, one keyword list: the sort,
      # the direction, the four chip groups and both counts arrive together
      # or not at all. An empty shelf now answers its own zero rather than
      # the board's `41 of 418`.
      {"145", Kati.Screens.ShelfFilters, &Kati.Screens.ShelfFilters.opening/0,
       [
         sort: :recently_added,
         direction: :desc,
         decade: nil,
         rating: nil,
         genres: MapSet.new(),
         services: MapSet.new(),
         showing: 0,
         total: 0,
         facets: [],
         decades: []
       ], &Kati.Screens.ShelfFilters.drawn_opening_for_test/0},
      # 05's gate is `releases/0` — the read, which answers `nil` when nothing is
      # followed and a map when something is. It used to be paired with
      # `drawn_inbox/0`, because that was what an unfollowed device fell back
      # to; board 260 replaced the fallback with a page of its own, so the pair
      # is now *the read answered nothing* against *the read answered something*
      # rather than *the drawing*.
      {"05", Kati.Screens.Inbox, &Kati.Screens.Inbox.releases/0, nil,
       fn -> Kati.Screens.Inbox.drawn_inbox() end},
      {"19", Kati.Screens.Search, fn -> Kati.Search.Query.run("hollow").titles end, [],
       fn -> Kati.Screens.Search.drawn_results().titles end},
      {"89", Kati.Screens.SearchResultStates, fn -> Kati.Search.Query.run("hollow").titles end,
       [], fn -> Kati.Screens.Search.drawn_results().titles end},
      # 92 and the three screens that read through it. The live value is the
      # reader's two service groups; the empty value is two empty lists; the
      # drawn value is still there, on `Kati.Screens.MyServices.drawn/0`, which
      # is what stops an emptied Sample module turning the pair into two
      # nothings agreeing. MOVIES-AND-TV.md #75.
      {"92", Kati.Screens.MyServices,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"24", Kati.Screens.Settings,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      # The screens that borrow 92's reader. Each of them can WRITE into a Kati
      # whose service list it would otherwise disagree with — the reason each
      # is named in `fallbacks/0`'s own comments, which stay there — and the
      # question about that reader changed on 6 September: it used to answer
      # with `Kati.Services.Sample` and now answers with nothing. So the borrow
      # moved with it, from "the borrowed pair still agrees" to "the borrowed
      # reader answers empty, and the drawn value it could have answered with
      # is still there". MOVIES-AND-TV.md #75.
      {"128", Kati.Screens.Backup,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"131", Kati.Screens.BackupDark,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"129", Kati.Screens.Restore,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"135", Kati.Screens.RestoreFirstRun,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"26", Kati.Screens.PickSections,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"06", Kati.Screens.AddTitle,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"154", Kati.Screens.AddByHand,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"178", Kati.Screens.AddByHandRecord,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"179", Kati.Screens.AddTitleMusic,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"177", Kati.Screens.AddByHandBook,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"163", Kati.Screens.OnboardingFirstTitle,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"166", Kati.Screens.OnboardingFirstTitle,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"155", Kati.Screens.AddByHandStates,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"156", Kati.Screens.AddByHand,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"157", Kati.Screens.AddByHandDark,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"158", Kati.Screens.HomeEmpty,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"159", Kati.Screens.HomeEmptyDark,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"160", Kati.Screens.HomeOmittedSections,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"62", Kati.Screens.Settings,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"94", Kati.Screens.CountryPicker,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"93", Kati.Screens.MyServicesEmpty,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"95", Kati.Screens.MyServicesStates,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"96", Kati.Screens.NothingSetUpKnockOn,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      # 97 is 92 under `:fa`, and the gate is 92's — the same read, asked in the
      # other script. It is named separately because `@migrated` names it
      # separately: the pairing test below reads across both lists.
      {"97", Kati.Screens.MyServices,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"90", Kati.Screens.Search,
       fn -> {Kati.Screens.MyServices.subscribed(), Kati.Screens.MyServices.free()} end, {[], []},
       fn -> {Kati.Services.Sample.subscribed(), Kati.Services.Sample.free()} end},
      {"01", Kati.Screens.Home, fn -> Kati.Screens.Home.nothing_kept?(timeline()) end, true,
       fn -> Kati.Screens.Home.nothing_kept?(Kati.Screens.Home.drawn_rows()) end},
      {"139", Kati.Screens.HomeEmpty, fn -> Kati.Screens.Home.nothing_kept?(timeline()) end, true,
       fn -> Kati.Screens.Home.nothing_kept?(Kati.Screens.Home.drawn_rows()) end},
      # Screen 01's five bands, each asked its own question, because they had
      # five different wrong answers and a single gate over the page would have
      # let four of them through. Every `drawn_*` on the right is what
      # `Kati.ScreenDesignLiteralTest.drawn_state/0` installs to compare screen
      # 01 against its board, so the pair is: the board still holds this, and no
      # device ever answers with it.
      #
      # `New this week`. `Kati.Screens.Inbox.releases/0` answers `nil` for a
      # device that follows nothing, and `hero_summary/0` passes that on rather
      # than announcing three episodes at somebody who follows none.
      {"01", Kati.Screens.Home, &Kati.Screens.Home.hero_summary/0, nil,
       &Kati.Screens.Home.drawn_hero/0},
      # `Continue watching`, through `Kati.Screens.Library.shelf/0` — the same
      # read screen 03 is gated on, so the two cannot disagree about what is on
      # the shelf.
      {"01", Kati.Screens.Home, &Kati.Screens.Home.continue_watching_rows/0, [],
       &Kati.Screens.Home.drawn_continue_watching/0},
      # `Watching`. The count only — the region beside it is a `Mob.State`
      # preference with a default, not a row, so it is not a thing an empty
      # database can be wrong about. The count was: it came through
      # `Kati.Screens.MyServices.subscribed/0`, whose empty answer is the
      # drawing's three services.
      {"01", Kati.Screens.Home, fn -> Kati.Screens.Home.services().count end, 0,
       fn -> Kati.Screens.Home.drawn_services().count end},
      # `Sections`. The tiles themselves are navigation and are drawn either
      # way; it is the two metas under them that claimed a dinner and two
      # unfinished habits, and neither has a resource behind it anywhere.
      {"01", Kati.Screens.Home, fn -> Enum.map(Kati.Screens.Home.tile_rows(), & &1.meta) end,
       [nil, nil, nil], fn -> Enum.map(Kati.Screens.Home.drawn_tiles(), & &1.meta) end},
      # `Rest of today`, asked of `Kati.Calendars.Today` rather than of the card
      # it fills. That read was never the problem — the `[]` clause underneath
      # it was, and the clause is gone, so what is left to assert is that the
      # empty day really is empty and that the drawing it no longer reaches for
      # is still there for the board to be compared against.
      {"01", Kati.Screens.Home, fn -> timeline() end, [], &Kati.Screens.Home.drawn_rows/0},
      # 02 answers `[]` for EVERY date now, today included. The old entry
      # compared `day_rows(today)` with `drawn_rows/0` and passed because
      # `day_rows/1` had a today-only clause that substituted the board's five
      # cards; a person's first launch drew a dentist appointment, a passport
      # reminder and a renewal that were not theirs.
      {"02", Kati.Screens.Calendar, fn -> Kati.Screens.Calendar.day_rows(today) end, [],
       &Kati.Screens.Calendar.drawn_rows/0},
      # 56 is 02 read under `:fa` since mishka-group/kati#103, so it gates on
      # 02's own pair — the same read, and the same drawing to fall back to. It
      # keeps a row of its own because the board is still a drawing this file
      # renders against an empty store, and a `for` over `@migrated` would
      # otherwise stop asking the Persian page anything at all.
      {"56", Kati.Screens.Calendar, fn -> Kati.Screens.Calendar.day_rows(today) end, [],
       &Kati.Screens.Calendar.drawn_rows/0},
      {"03", Kati.Screens.Library, &Kati.Screens.Library.titles/0, [],
       &Kati.Screens.Library.drawn_titles/0},
      # 57 is 03 read under `:fa` since mishka-group/kati#103, so it gates on
      # 03's own pair — the same read, and the same drawing to fall back to.
      {"57", Kati.Screens.Library, &Kati.Screens.Library.titles/0, [],
       &Kati.Screens.Library.drawn_titles/0},
      # 07 has no single accessor: `figures/0` answers a keyword list whose third
      # element is a real read either way. The two the branch turns on are taken,
      # in the order the list holds them — and `year: nil` rather than a map of
      # zeroes is the whole signal, so the pair would fail a round that answered
      # with `%{}` and drew a dashboard of noughts.
      {"07", Kati.Screens.Stats,
       fn -> Keyword.take(Kati.Screens.Stats.figures(), [:year, :grid]) end,
       [year: nil, grid: []],
       fn ->
         [
           year: Map.put(Kati.Stats.Sample.year(), :rising?, true),
           grid: Kati.Stats.Sample.contributions()
         ]
       end},
      # 149 reads Library's own shelf, for the reason 70 reads 66's: a sheet
      # aimed at a different shelf from the screen that opened it would drop the
      # wrong title.
      {"149", Kati.Screens.DropSheet, &Kati.Screens.Library.titles/0, [],
       &Kati.Screens.Library.drawn_titles/0},
      # ── 28 and 55, band by band ───────────────────────────────────────────
      #
      # Screen 01's mirrors, gated the way 01 is: one entry per band, because
      # each band had its own wrong answer and a single gate over either page
      # would have let the others through. Every `drawn_*` on the right is what
      # `Kati.ScreenDesignLiteralTest.drawn_state/0` installs to compare the
      # board against itself, so the pair reads: the board still holds this, and
      # no device ever answers with it.
      #
      # Both pages read through screen 01's own readers rather than through
      # copies — `Kati.Screens.Home.hero_summary/0` and
      # `continue_watching_rows/0` — so a mirror cannot come to disagree with
      # the page it mirrors about how many episodes are out or what is on the
      # shelf. That is why the `live` half of the hero entries is each screen's
      # own reshaping function and not 01's: what is being asserted is that the
      # reshaping passes `nil` through rather than filling a headline in.
      #
      # `Kati.Screens.HomeDark.Sample` and `Kati.Screens.Home.Sample` stay
      # exactly where they are. They are the transcriptions the two boards were
      # captured from, and the `drawn != empty` half of every pair below is what
      # stops an emptied Sample turning the first half into two nothings
      # agreeing.
      {"28", Kati.Screens.HomeDark, &Kati.Screens.HomeDark.hero_summary/0, nil,
       &Kati.Screens.HomeDark.drawn_hero/0},
      {"28", Kati.Screens.HomeDark, &Kati.Screens.Home.continue_watching_rows/0, [],
       &Kati.Screens.HomeDark.Sample.continue/0},
      {"28", Kati.Screens.HomeDark, fn -> timeline() end, [],
       &Kati.Screens.HomeDark.Sample.rest_of_today/0},
      {"55", Kati.Screens.Home, &Kati.Screens.Home.hero_summary/0, nil,
       &Kati.Screens.Home.drawn_hero/0},
      {"55", Kati.Screens.Home, &Kati.Screens.Home.continue_watching_rows/0, [],
       &Kati.Screens.Home.drawn_continue_watching/0},
      # The tiles themselves are navigation and are drawn either way; it is the
      # two metas under them that claimed a dinner and two unfinished habits,
      # and neither has a resource behind it anywhere. 01 carries the identical
      # pair one screen over.
      {"55", Kati.Screens.Home, fn -> Enum.map(Kati.Screens.Home.tile_rows(), & &1.meta) end,
       [nil, nil, nil], fn -> Enum.map(Kati.Screens.Home.drawn_tiles(), & &1.meta) end},
      {"55", Kati.Screens.Home, fn -> timeline() end, [], &Kati.Screens.Home.drawn_rows/0}
    ]
  end

  # Every gate in both lists, as `number => the modules gating it`. A list rather
  # than a module, because a screen may legitimately be in both — `fallbacks/0`
  # says which two are and why — and a `Map.new` would then hide one of the two
  # from the module comparison above.
  defp gate_modules(today) do
    pairs =
      Enum.map(fallbacks(today), fn {number, module, _live, _drawn} -> {number, module} end) ++
        Enum.map(empties(today), fn {number, module, _live, _empty, _drawn} ->
          {number, module}
        end)

    Enum.group_by(pairs, &elem(&1, 0), &elem(&1, 1))
  end

  # What `Kati.Screens.Home.load/1` assigns, called the way the screen calls it.
  defp timeline, do: Kati.Calendars.Today.rows()

  # ── The literals no empty database can put back ─────────────────────────────

  # Screens 01, 02, 55 and 56 print the device clock, and their drawings froze
  # the day they were exported. That is not a fallback that could regress — it
  # is the same value on a full database and on an empty one — so each is exempted
  # here exactly as `Kati.ScreenDesignLiteralTest` exempts them, with a stand-in
  # pattern rather than a bare pass, and the stand-in carries **today's** day of
  # the month so a screen that hardcoded the drawing's date fails on every day
  # but one.
  #
  # Deliberately not shared with that file: two modules importing one allow-list
  # is how an exemption granted for one question quietly answers another, and
  # three entries is not the kind of duplication worth a shared fixture. The
  # `no_dead_entries` test below is what stops this copy going stale.
  # Screens 55 and 56 are the same three lines in Persian, and their stand-ins
  # carry today's **Shamsi** day rather than its Gregorian one — the number the
  # screens actually print. Two things about the patterns are not decoration:
  #
  #   * `\x{200C}` is in every word class. Four of the seven Persian weekday
  #     names contain a zero-width non-joiner (سه‌شنبه, پنج‌شنبه), and a ZWNJ is
  #     `\p{Cf}`, not `\p{L}` — so a bare `\p{L}+` would match on Saturday and
  #     fail on Tuesday, which is a stand-in that works four days in seven.
  #   * `\p{N}+` rather than `\d+`. The digits are U+06F0-U+06F9, which are
  #     `Nd` and are not what `\d` means.
  defp device_values do
    day = Integer.to_string(Kati.Time.now().day)
    {_year, _month, shamsi_day} = Kati.Calendar.Shamsi.from_gregorian(Kati.Time.today())
    fa_day = Kati.Calendar.Shamsi.fa(shamsi_day)
    word = "[\\p{L}\\x{200C}]+"

    [
      # An entry is keyed by the DRAWING the line is in, and `exempt?/2` is
      # asked with the drawings the screen is compared with — so 01's two are no
      # longer exempting anything: Home with nothing stored is held to board 139,
      # and 139 carries its own copy of this pair further down. They are kept
      # because the staleness checks alone are worth having on them: the line
      # must still be one board 01 contains, and screen 01 must still render
      # something shaped like the device's clock where the board froze one. The
      # same is true of 02's, whose screen is in `@no_empty_board` and is
      # compared against no board's literals at all — the entry is what keeps
      # `Wednesday 26 August · 0 items` a checked line rather than an unchecked
      # one.
      # 46's third filter. `Kati.ScreenDesignLiteralTest` carries the same pair
      # and the argument in full: *In my fridge* needs a pantry — stock,
      # depletion, expiry — and Kati has none, so the filter row draws
      # *Recently eaten* instead. The rule is that a filter is only offered if
      # the app can apply it, and a pantry that is 60 per cent accurate would
      # quietly stop offering meals you could cook.
      #
      # Here because 46 joined the migrated list when its two commit buttons
      # started writing; the line was exempt before and is exempt for the same
      # reason on both sides.
      {"46", "in my fridge", ~r/^recently eaten$/},
      # 23's back pill. Board 23 reads `Stats` and the only route into the
      # page is screen 92's Money row, so the word and the gesture disagreed
      # (MOVIES-AND-TV.md #66). The twin of this entry is in
      # `Kati.ScreenDesignLiteralTest`, where the board is compared in the
      # arrival it is a drawing OF.
      {"23", "stats", ~r/^(my services|stats)$/u},
      # 24's and 42's *My services* row, and the twin of this pair is in
      # `Kati.ScreenDesignLiteralTest`. Both boards froze `United Kingdom · 3
      # subscribed` and the line counts the reader's own services now — the
      # count Home has always drawn, which is what let one screen say *No
      # subscriptions yet* while another said three (MOVIES-AND-TV.md #75).
      {"24", "united kingdom · 3 subscribed", ~r/^.+ · (none yet|\d+ subscribed)$/u},
      {"42", "united kingdom · 3 subscribed", ~r/^.+ · (none yet|\d+ subscribed)$/u},
      # 05's watcher line, and the twin of this entry is in
      # `Kati.ScreenDesignLiteralTest`, which carries the full reasoning. Both
      # halves are stored now — board 314 built the record on the page this
      # card's cog opens — and an empty `Mob.State` answers `never checked`
      # beside the default cadence, which is exactly what a fresh install says.
      {"01", "sunday · 16 august", ~r/^\p{L}+ · #{day} \p{L}+$/u},
      {"01", "good evening", ~r/^good (morning|afternoon|evening)$/},
      {"02", "sunday 16 august · 5 items", ~r/^\p{L}+ #{day} \p{L}+ · \d+ items$/u},
      # 09's heading, and it is here for the same reason it is in
      # `Kati.ScreenDesignLiteralTest`'s twin of this list rather than for a new
      # one: a bare push has no date to draw, so the heavy day titles itself
      # with the device's own today in the drawing's short form. The frame froze
      # one Thursday. This entry arrived with 09 itself, on the round the screen
      # started reading the store (#84).
      {"09", "thu 20 aug", ~r/^\p{L}{3} #{day} \p{L}{3}$/u},
      # 139 is 01 with nothing stored — the same greeting, from the same
      # `Kati.Screens.Home.today/0`. Its date line is not here because an empty
      # Home draws no timeline to date, so only the greeting survives to be
      # exempted; `Kati.ScreenDesignLiteralTest` carries both, because the
      # populated render draws both.
      {"139", "good evening", ~r/^good (morning|afternoon|evening)$/},
      {"55", "یکشنبه ۲۵ مرداد ۱۴۰۵", ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"55", "عصر بخیر", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"56", "یکشنبه ۲۵ مرداد · ۵ مورد", ~r/^#{word} #{fa_day} #{word} · \p{N}+ مورد$/u},
      # 158's pair, which are 55's: the Persian empty Home reads the same
      # `Kati.Screens.Home.moment/0`, so a board-frozen ۲۵ مرداد ۱۴۰۵ is the
      # same frozen value on the same clock.
      {"158", "یکشنبه ۲۵ مرداد ۱۴۰۵", ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"158", "عصر بخیر", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"159", "یکشنبه ۲۵ مرداد ۱۴۰۵", ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"159", "عصر بخیر", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"160", "یکشنبه ۲۵ مرداد ۱۴۰۵", ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"160", "عصر بخیر", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      # 24 and 62's Export row: `Kati.Screens.Settings.last_backup/0` is `nil`
      # until something completes a Save As, and `Mob.State` is empty here.
      # `Kati.ScreenDesignLiteralTest` carries the same pair with the full
      # reasoning; this list is that one's shorter twin.
      {"24", "last backup 14 aug", ~r/^(last backup \d{1,2} \p{L}{3}|never backed up)$/u},
      {"62", "آخرین پشتیبان ۱۴ مرداد",
       ~r/^(آخرین پشتیبان \p{N}+ #{word}|هنوز پشتیبانی گرفته نشده)$/u},
      # 62's My services row, which board 62 froze at **ایران · ۳ سرویس** — a
      # country invented for a reader who has chosen none, which is board 324's
      # closing sentence one screen over, and a count nobody has.
      # `Kati.ScreenDesignLiteralTest` carries the same pair with the full
      # reasoning; this list is that one's shorter twin.
      {"62", "ایران · ۳ سرویس", ~r/^.+ · (هنوز هیچ‌کدام|\p{N}+ اشتراک)$/u},
      # 61's three More numbers rows, which are 07's two in Persian plus the
      # weight row Persian has no Health hub to reach. `Kati.ScreenDesignLiteralTest`
      # carries the same three with the full reasoning; this list is that one's
      # shorter twin.
      {"61", "۳ هدف فعال", ~r/^(هدفی تعیین نشده — کاتی به‌هرحال می‌شمارد|\p{N}+ هدف|تعیین نشده)$/u},
      {"61", "۴۶٫۴۷ پوند در ماه", ~r/^(هنوز چیزی برای جمع‌زدن نیست|.*در ماه.*|\p{N}+ هزینه)$/u},
      # 80's three provider-supplied values and two cache figures, none of which
      # exists on a device with an empty database and no tokens.
      {"80", "connected as ines.k · 412 listens",
       ~r/^(connected as \p{L}[\p{L}.]* · \d+ listens|scrobbles, listening history)$/u},
      {"80", "34 mb cached", ~r/^(\d+ mb cached|nothing cached yet)$/u},
      {"80", "oldest entry 2 months",
       ~r/^(oldest entry (today|\d+ (day|days|month|months))|nothing to refresh)$/u},
      # 94's Netherlands row: the drawing pairs Cambodia's flag with it, and
      # `Kati.Services.flag/1` derives the emoji from the country code. See
      # `Kati.ScreenDesignLiteralTest` for the full reasoning — reproducing the
      # slip would mean shipping a wrong flag to keep a sweep quiet.
      {"94", "🇰🇭", ~r/^🇳🇱$/u},
      # 128's status card. `Kati.Screens.Settings.last_backup/0` is `nil` until
      # something completes a Save As, so on an empty database this card reads
      # "Never" — which is the state the board itself calls *a warning, not an
      # error*, and the default state of every user. Same pair 24 and 62 carry.
      {"128", "14 aug", ~r/^(\d{1,2} \p{L}{3}|never)$/u},
      {"128", "2 weeks ago · 214 mb", ~r/^(.*ago · \d+ mb|still only on this phone)$/u},
      # 94's field placeholder counts `Kati.Services.countries/0` rather than
      # JustWatch's 190. Board 94 froze the wrong number over a list of seven,
      # and the field was a picture that filtered nothing —
      # MOVIES-AND-TV.md #78. The pattern insists on a count the screen
      # builds, which is stricter than the frozen literal it replaces.
      {"94", "search 190 countries", ~r/^search \d+ countries$/u},
      # 139's greeting line prints the device's own clock, as 01's does.
      {"139", "sunday · 16 august", ~r/^\p{L}+ · #{day} \p{L}+$/u},
      # 144 and 149's boards each show SEVERAL MOMENTS in one frame, and a live
      # screen can only be in one of them. Both modules argue the reading in
      # their own moduledocs and both are worth reading before changing this:
      #
      #   * 144's "Spoiler-safe variant" panel is a swatch documenting a
      #     SUBSTITUTION inside the one headline — `S2 E6 · The Undertow`
      #     becomes `S2 E6 · Episode 6` — not a second headline drawn beside
      #     the first. `headline/2` performs the substitution.
      #   * 149's board draws the action row AND the dark undo pill together,
      #     which are before and after the same tap. `dropped?` starts false,
      #     so the sheet opens on the action row and the pill replaces it.
      {"144", "spoiler-safe variant", ~r/^rate this episode$/},
      {"144", "s2 e6 · episode 6", ~r/^s2 e6 · (the undertow|episode 6)$/},
      {"144", "rewatch — your last verdict, above the input", ~r/^review$/},
      {"144", "you, 3 mar 2024 · \uF09A4", ~r/^what did you make of it\?$/},
      {"144",
       "the estuary scenes land completely differently once you know what mara is looking for.",
       ~r/^what did you make of it\?$/},
      # (149's two entries were here. They exempted `drop at s1 e3` and
      # `still on it` because the sheet drew the board's own captured position;
      # `empty_sheet/0` carries no position at all now, so the lines are drawn
      # by nothing and an exemption would be hiding their absence rather than
      # explaining it. Both are still drawn over a real gone-cold title, which
      # is what `Kati.DropWriteTest` walks.)
      # 115's direction note was here. mishka-group/kati#103 folded board 115's
      # mirror away; the board is registered against screen 109 now, which does
      # not read the database — so it is not on this file's list at all and its
      # exemption lives only in `Kati.ScreenDesignLiteralTest`, which is where
      # a screen that reaches no store belongs.
      # 14's back pill. The board was captured as an arrival from the shelf, so
      # it draws `Library`; the app's only door into screen 14 is the series
      # page's *Show details*, so the pill defaults to `Series` and takes
      # `Library` from a push that says so. This file's renders are bare
      # pushes, which is the default. `Kati.BackLabelTest` holds both branches,
      # and `Kati.ScreenDesignLiteralTest` compares the board against the
      # arrival it is a drawing OF rather than exempting the word.
      {"14", "library", ~r/^(library|series)$/u},
      # 111's `Today` row prints the device's clock. See
      # `Kati.ScreenDesignLiteralTest` for the full reasoning.
      {"111", "16 august, 07:42", ~r/^#{day} \p{L}+, \d{2}:\d{2}$/u},
      # Screen 82's three provider-and-cache values, the Persian mirror of the
      # three screen 80 already carries: a pairing code for a provider Kati has
      # no client for, the database file's own size, and the age of its oldest
      # row. None exists on a device with an empty database and no tokens.
      {"82", "۴kq9۲", ~r/^\p{N}?[\p{L}\p{N}]+$/u},
      {"82", "۳۴ مگابایت", ~r/^(\p{N}+ مگابایت|هنوز چیزی ذخیره نشده)$/u},
      {"82", "۲ ماه قدیمی‌ترین", ~r/^(.*قدیمی‌ترین|چیزی برای تازه‌سازی نیست)$/u}
    ]
  end

  # Symbols whose row is a moment this screen is not in. Same reasoning as the
  # literal pairs above; see 144's and 149's moduledocs.

  defp exempt?(boards, literal) do
    Enum.any?(device_values(), fn {n, l, _pattern} -> n in boards and l == literal end)
  end

  # Lines a screen deliberately does not draw. `Kati.ScreenDesignLiteralTest`
  # holds the list and the reasons, one per entry; this file asks the same
  # question of the same screens against an empty database, so it asks the
  # same list rather than keeping a second one to drift from the first.
  defp retired?(boards, literal) do
    Enum.any?(DesignLiterals.retired_lines(), fn {n, l} ->
      n in boards and l == literal
    end)
  end

  # ── Which screens read a store ──────────────────────────────────────────────

  # True when `module`'s compiled code calls `Ash`, or calls something in this
  # app that does. Read off the BEAM's own import table, which is the exact set
  # of external functions the module actually calls — so a name in a moduledoc
  # or a comment cannot make a screen look like a reader, and a read that lives
  # one module away cannot hide from it.
  defp reaches_store?(module), do: MapSet.member?(store_readers(), module)

  # Memoised in `:persistent_term` for the reason every other cache in these
  # sweeps is: each ExUnit test runs in its own process, so a cache in the
  # process dictionary dies between the two tests that share this. Only plain
  # data is stored, and it depends on nothing but the compiled code.
  defp store_readers do
    key = {__MODULE__, :store_readers}

    case :persistent_term.get(key, :miss) do
      :miss ->
        set = compute_store_readers()
        :persistent_term.put(key, set)
        set

      set ->
        set
    end
  end

  defp compute_store_readers do
    _ = Application.load(:kati)
    callees = Map.new(Application.spec(:kati, :modules) || [], &{&1, callees_of(&1)})

    direct =
      for {module, called} <- callees, Enum.any?(called, &ash?/1), into: MapSet.new(), do: module

    close(callees, direct)
  end

  # One pass adds every module that calls something already known to reach Ash;
  # repeat until a pass adds nothing. A fixpoint rather than a walk per module,
  # so a cycle in the call graph terminates without a seen-set to carry.
  defp close(callees, reaching) do
    grown =
      for {module, called} <- callees,
          Enum.any?(called, &MapSet.member?(reaching, &1)),
          into: reaching,
          do: module

    if MapSet.size(grown) == MapSet.size(reaching), do: grown, else: close(callees, grown)
  end

  defp callees_of(module) do
    with beam when is_list(beam) <- :code.which(module),
         {:ok, {_module, [imports: imports]}} <- :beam_lib.chunks(beam, [:imports]) do
      imports |> Enum.map(&elem(&1, 0)) |> Enum.uniq()
    else
      _ -> []
    end
  end

  defp ash?(module) do
    name = Atom.to_string(module)
    name == "Elixir.Ash" or String.starts_with?(name, "Elixir.Ash.")
  end

  # ── Rows to prove the emptying with ─────────────────────────────────────────

  defp write_probe_rows! do
    fetched = DateTime.utc_now()

    title =
      Kati.Media.CachedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: @probe_id,
        kind: :tv,
        title: "Probe",
        fetched_at: fetched
      })
      |> Ash.create!()

    season =
      Kati.Media.CachedSeason
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        title_source_id: @probe_id,
        season_number: 1,
        fetched_at: fetched
      })
      |> Ash.create!()

    episode =
      Kati.Media.CachedEpisode
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: @probe_id,
        title_source_id: @probe_id,
        season_number: 1,
        episode_number: 1,
        fetched_at: fetched
      })
      |> Ash.create!()

    %{
      Kati.Media.CachedTitle => MapSet.new([title.id]),
      Kati.Media.CachedSeason => MapSet.new([season.id]),
      Kati.Media.CachedEpisode => MapSet.new([episode.id])
    }
  end

  # Every screen sweep in the suite renders against this one shared file, so a
  # probe row left behind is a row screen 03 would draw. Same hazard
  # `Kati.SeedsTest` documents, and the same fix.
  defp delete_probe_rows! do
    for table <- ~w(cached_titles cached_episodes) do
      Kati.Repo.query!("DELETE FROM #{table} WHERE source_id = ?1", [@probe_id])
    end

    Kati.Repo.query!("DELETE FROM cached_seasons WHERE title_source_id = ?1", [@probe_id])
    :ok
  end

  # ── An empty database, borrowed and given back ──────────────────────────────

  # Runs `fun` with every table emptied, and always rolls back. `Ash.read!` and
  # `Kati.Repo.query!` inside `fun` run in this same process, so they use the
  # connection the transaction checked out and see the empty state; nothing is
  # written, so the suite's other fixtures survive.
  defp in_empty_database(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Enum.each(@tables, &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  defp table_counts do
    Map.new(@tables, fn table ->
      %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}")
      {table, n}
    end)
  end

  # ── Rendering ───────────────────────────────────────────────────────────────

  # Memoised in `:persistent_term` for the reason `Kati.ScreenDesignLiteralTest`
  # states: each ExUnit test runs in its own process and `Mob.ScreenCase`
  # restarts `Mob.State` around each one, so a cache in the process dictionary
  # or in ETS dies between the tests that share the work. Only plain data —
  # trees and strings — is stored.
  defp render_migrated do
    key = {__MODULE__, :render_migrated}

    case :persistent_term.get(key, :miss) do
      :miss ->
        screens = in_empty_database(&do_render_migrated/0)
        :persistent_term.put(key, screens)
        screens

      screens ->
        screens
    end
  end

  # The boards whose literals are PERSIAN, rendered in the locale they are drawn
  # in rather than in `:en`.
  #
  # Every other Persian board is a `*Fa` module holding its copy as literals, so
  # the locale it renders under makes no difference to what it draws. 156 was the
  # first that is not: mishka-group/kati#103's fold deleted
  # `Kati.Screens.AddByHandFa`, and board 156 is now screen 154 rendered under
  # `:fa` — which is also what makes its back chevron `arrow_forward_ios`, since
  # `Kati.Screens.Pushed.back_glyph/0` reads the direction. Rendered in `:en` it
  # draws the English page and every one of the board's lines is "missing". 97
  # joined it when `Kati.Screens.MyServicesFa` folded into screen 92, and every
  # fold after this one adds its board here.
  #
  # `Kati.ScreenDesignLiteralTest`'s `@fa_screens` is the same list for the same
  # reason, and the two grow together as the fold proceeds.
  @fa_numbers ~w(55 56 57 58 60 61 62 69 72 76 82 90 97 103 137 156 158 159 160 164 165 166 176)

  defp do_render_migrated do
    for {number, module} <- @migrated do
      locale = if number in @fa_numbers, do: :fa, else: :en

      case ScreenSweep.with_locale(locale, fn -> ScreenSweep.render(module) end) do
        {:ok, _socket, tree} ->
          texts = DesignLiterals.rendered(tree)

          {boards, design} = empty_drawing(number)

          %{
            number: number,
            module: module,
            # The drawings this render is compared with, which is `[the screen's
            # own number]` for everything but the four roots — see
            # `@empty_boards` and `@no_empty_board`. `[]` means the design draws
            # no empty state for this screen and the literal comparison does not
            # run.
            boards: boards,
            tree: tree,
            texts: texts,
            haystacks: DesignLiterals.haystacks(texts),
            design: design
          }

        {:error, message} ->
          flunk("screen #{number} (#{inspect(module)}) does not render:\n  #{message}")
      end
    end
  end

  # The drawings a screen with nothing stored is held to, as
  # `{[number], %{text:, icons:}}` — the second is their union, in the order
  # they are named, so `locate/2` and the symbol check ask about all of them at
  # once.
  defp empty_drawing(number) do
    for {board, _spec} = named <- specs(number), reduce: {[], %{text: [], icons: []}} do
      {boards, union} ->
        drawing = drawing(named)

        {boards ++ [board],
         %{
           text: Enum.uniq(union.text ++ drawing.text),
           icons: Enum.uniq(union.icons ++ drawing.icons)
         }}
    end
  end

  defp specs(number) do
    cond do
      number in Enum.map(@no_empty_board, &elem(&1, 0)) -> []
      Map.has_key?(@empty_boards, number) -> Map.fetch!(@empty_boards, number)
      true -> [{number, :whole}]
    end
  end

  defp drawing({board, :whole}), do: DesignLiterals.read!(board)
  defp drawing({board, {from, to}}), do: DesignLiterals.band(board, from, to)
end
