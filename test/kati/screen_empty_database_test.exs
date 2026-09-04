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
      `Kati.ScreenDarkWidgetsTest` and `Kati.ScreenHomeFaEmptyStateTest`, hold
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
  # `Kati.Screens.SeriesMeta` (14) and `Kati.Screens.SeriesSettings` (35) are
  # absent because they read no store at all: each still reads its Sample module
  # outright and says why at length in its moduledoc — no cast, no availability,
  # no offers, and in 35's case a referent it argues cannot be picked safely —
  # so neither has a fallback that could regress.
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
    {"10", Kati.Screens.UpNext},
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
    {"55", Kati.Screens.HomeFa},
    {"56", Kati.Screens.ScheduleFa},
    {"57", Kati.Screens.LibraryFa},
    # 58 is 04 in Persian and reads through 04 — see the note above.
    {"58", Kati.Screens.SeriesFa},
    # The Books domain's two screens, and they are the pair this file was
    # written for: 66 falls back to `Kati.Books.Sample.detail/0` for the whole
    # page, and 70 falls back for the book it is about to write a session
    # against. 70 is also the first screen here that can WRITE — its fallback
    # is what stops a save being aimed at a book that does not exist.
    {"66", Kati.Screens.BookDetail},
    {"70", Kati.Screens.LogProgress},
    # The Music domain's three. 74 and 77 gate the whole page as 66 does; 73
    # gates the album it is about to write a play against, through 74's reader
    # for the reason 70 uses 66's.
    {"73", Kati.Screens.LogListen},
    {"74", Kati.Screens.AlbumDetail},
    {"77", Kati.Screens.ArtistDetail},
    # 24 and 62 joined this list the moment their Watching group started
    # counting real services: a settings page that says `3 subscribed` is a
    # settings page with a read in it, and its fallback is the drawing's own
    # three.
    {"24", Kati.Screens.Settings},
    {"62", Kati.Screens.SettingsFa},
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
    # The Persian book pair. 69 reads screen 66's own shelf and supplies only
    # the Persian chrome — see `Kati.Screens.BookDetailFa.book/0` — so its
    # fallback is a real branch. 72 draws the fixture and reaches the store only
    # through 66's cover helper, so it gates on the same pair for the reason 70
    # gates on 66's.
    {"69", Kati.Screens.BookDetailFa},
    {"72", Kati.Screens.LogProgressFa},
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
    {"76", Kati.Screens.AlbumDetailFa},
    {"79", Kati.Screens.ArtistDetailFa},
    {"81", Kati.Screens.DataSourcesStates},
    {"82", Kati.Screens.DataSourcesFa},
    {"85", Kati.Screens.AttributionFa},
    {"126", Kati.Screens.MoneyDay},
    # Screen 92's three companions: its empty state, its states sheet, and the
    # board showing what four other screens look like when nothing is set up.
    # All three gate on 92's own pair.
    {"93", Kati.Screens.MyServicesEmpty},
    {"95", Kati.Screens.MyServicesStates},
    {"96", Kati.Screens.NothingSetUpKnockOn},
    {"97", Kati.Screens.MyServicesFa},
    # The Persian search and the two year-card twins. Each gates on the pair its
    # primary gates on, for the reason every mirror in this list does.
    {"90", Kati.Screens.SearchFa},
    {"102", Kati.Screens.YearShareDark},
    {"103", Kati.Screens.YearShareFa},
    {"105", Kati.Screens.GoalsEmpty},
    {"110", Kati.Screens.WeightStates},
    {"113", Kati.Screens.HealthEmptyStates},
    {"107", Kati.Screens.GoalStates},
    {"108", Kati.Screens.GoalsFa},
    {"114", Kati.Screens.RetiredTile},
    {"117", Kati.Screens.MealLibraryEmpty},
    {"123", Kati.Screens.MoneyStates},
    # 115 is the Persian weight-and-doses page, and 61 joined the moment its
    # More numbers rows started counting real goals and services.
    {"115", Kati.Screens.HealthFa},
    {"61", Kati.Screens.StatsFa},
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
    {"127", Kati.Screens.MoneyFa},
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
    {"132", Kati.Screens.RestoreFa},
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
    {"154", Kati.Screens.AddByHand},
    {"155", Kati.Screens.AddByHandStates},
    {"156", Kati.Screens.AddByHandFa},
    {"157", Kati.Screens.AddByHandDark},
    {"158", Kati.Screens.HomeFaEmpty},
    {"159", Kati.Screens.HomeFaEmptyDark},
    {"160", Kati.Screens.HomeFaOmittedSections}
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
    # 154 draws its form in whatever state the socket holds, and its load state
    # is Film — board 155 says so: "Resting — empty, Film, nothing assumed".
    # Board 154 is drawn with Series chosen so the episode-count field is
    # visible, which is a state a user reaches and not the one the screen opens
    # in, so the resting comparison is 155's first band rather than 154 whole.
    "154" => [{"155", {"Resting — empty, Film, nothing assumed", "Film is the default"}}],
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
    {"02",
     "no artboard draws a Schedule with nothing on it — 02 draws a day with five items — " <>
       "and none draws one Kati is not allowed to read either. `Kati.Screens.Calendar`'s " <>
       "moduledoc names the four boards its two cards are built from and quotes each",
     Kati.ScreenCalendarEmptyStateTest},
    {"07",
     "no board in the 152 draws screen 07 with no history. `Kati.Screens.Stats`'s moduledoc " <>
       "names the four that decided its card — 101's *Not enough data*, 27's geometry, 123's " <>
       "rule for a statistic with nothing under it, and 110's refusal to draw a chart that " <>
       "would mean nothing", Kati.ScreenStatsEmptyTest},
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
    # `Kati.Screens.HomeFa.empty_day/0` is where that sentence lives and where
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
     "no board draws a Persian Home with nothing kept, and this is the one screen here where " <>
       "that matters to a real user: `Kati.Onboarding.shell_root/1` answers " <>
       "`Kati.Screens.HomeFa` for `:fa`, so 55 is the page a Persian install opens on. Its " <>
       "two announcing bands are omitted whole and its section tiles keep their labels and " <>
       "lose their invented counts, on screen 96's rule; its empty day says " <>
       "`Kati.Screens.HomeFa.empty_day/0`, the one Persian sentence in the app that no " <>
       "artboard contains, written on `Kati.Screens.SettingsFa.backup_line/1`'s precedent " <>
       "and argued at that function", Kati.ScreenHomeFaEmptyStateTest}
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
  # `Kati.Screens.HomeFa.empty_day/0` — is therefore not a quotation at all. It
  # is held by `Kati.ScreenHomeFaEmptyStateTest` instead, at both ends: that the
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
    {"02", "139", "Nothing scheduled"},
    {"02", "139", "add anything with +"},
    {"07", "101", "Not much to show yet"},
    {"28", "139", "Nothing scheduled"},
    {"28", "139", "add anything with +"},
    {"55", "55", "جست‌وجوی فیلم، سریال، رویداد…"},
    {"55", "55", "بخش‌ها"},
    {"55", "55", "وعده‌ها"},
    {"55", "55", "عادت‌ها"},
    {"55", "55", "تنظیمات"},
    {"55", "55", "باقی امروز"}
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
    # The two notification screens. Both read a store — the inbox builds a plan
    # from every domain's candidates, the diagnostic reads the permission state
    # and the same plan — and neither has a drawing to be compared against, so
    # they take the `@undrawn` path: rendered against an empty database, checked
    # for shape, and exempt from the literal comparison.
    Kati.Screens.InboxNotifications,
    Kati.Screens.NotificationsHelp,
    Kati.Screens.Sync
  ]

  # The fewest strings a whole page can be. Thirteen is the bound the `@undrawn`
  # render test below has always held those two screens to, written as the floor
  # rather than as the number one below it, and it is named here because a second
  # test now uses it for the same argument: a page that is mostly chrome is what
  # a lost empty state looks like. It is the floor under every screen in this
  # file, including the ones whose drawing holds fewer literals than this.
  @chrome_floor 13

  # Every table an Ash resource in this app is backed by, child tables first so
  # the deletes below do not trip a foreign key. Written out rather than derived
  # so that `every_table_is_listed/0` can compare it against the schema the
  # migrations actually built — a resource added without a line here would
  # otherwise leave rows in place and this file would quietly stop being about
  # an empty database.
  @tables ~w(event_occurrence_overrides events calendars calendar_accounts recipe_ingredients recipes meal_plan_slots meal_plans meal_logs shopping_list_items foods bundled_foods licensed_foods media_watches media_content_warnings media_warning_preferences tracked_titles cached_titles cached_seasons cached_episodes sync_outbox sync_rejected_changes book_notes book_reading_sessions books music_listens music_tracks music_albums music_artists services goals expenses health_doses health_readings health_medications notification_pending)

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

  # How many of a board's literals belong to a moment the live screen is not in.
  # See the pairs in `device_values/0` for which they are.
  @moment_screens %{"144" => 5, "149" => 3}

  @moment_symbols [
    {"128", "cloud_done"},
    {"144", "expand_more"},
    {"144", "visibility_off"},
    {"149", "undo"}
  ]

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
      # That third one used to be `Kati.Screens.Season`, which now reads — so
      # the exemplar moved to `Kati.Screens.SeriesSettings`, whose moduledoc
      # quotes `Ash.create!` while arguing that its referent cannot be picked
      # safely yet. Keeping a mention-only screen pinned here is the point: a
      # namespace test that matched too much would answer `true` for it.
      assert reaches_store?(Kati.Screens.Film)
      assert reaches_store?(Kati.Screens.Home)
      refute reaches_store?(Kati.Screens.SeriesSettings)
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

        assert length(texts) >= @chrome_floor,
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
      # render can. `@moment_screens` names those and how many literals belong
      # to a moment the screen is not in, so the count still has to be right —
      # it is a smaller number, not an absent check.
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
            allowance = Map.get(@moment_screens, screen.number, 0),
            drawn_floor = length(screen.design.text) - allowance,
            floor =
              if(screen.boards == [screen.number],
                do: drawn_floor,
                else: max(drawn_floor, @chrome_floor)
              ),
            length(screen.texts) < floor,
            do:
              "  #{screen.number} #{inspect(screen.module)} rendered #{length(screen.texts)} " <>
                "strings against a floor of #{floor}"

      assert thin == [],
             "these screens render less copy than the drawing they are held to, which is what " <>
               "a lost empty state looks like:\n" <> Enum.join(thin, "\n")
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
      {"04", Kati.Screens.Series, &Kati.Screens.Series.series/0,
       &Kati.Screens.Series.drawn_series/0},
      # 05 gates on `:followed` being empty rather than on either list being
      # empty: "nothing is out this week" is a true thing for a release inbox to
      # say, and the drawing's three rows would be a false one. The pair
      # compares the whole map, watcher card included — that card is frozen, so
      # a round that wired its count up on its own would show here as the two
      # sides differing on a key neither list touches.
      {"05", Kati.Screens.Inbox, &Kati.Screens.Inbox.inbox/0, &Kati.Screens.Inbox.drawn_inbox/0},
      {"08", Kati.Screens.Film, &Kati.Screens.Film.film/0, &Kati.Screens.Film.drawn_film/0},
      # 09 is asked the question this file's renders ask: a bare push, the one
      # `Kati.Screens.ViewSwitcher` sends and the one `render_migrated/0` makes,
      # must answer with the drawn day whole — its date, its fourteen
      # occurrences and the flag that keeps the band, the renewals row and the
      # `14 items · 2 clashes` headline drawn. Compared as the triple `day/1`
      # answers rather than as its occurrences alone: the flag is what the other
      # three read, so a gate that dropped it would pass while the day went
      # bare.
      #
      # Deliberately NOT gated on a handed date against an empty store. That
      # answers `[]`, and `[]` is the right answer — a day the user opened and
      # that holds nothing is empty, and dressing it in the drawing's fourteen
      # items is the lie every other entry in this list exists to prevent.
      {"09", Kati.Screens.Day, fn -> Kati.Screens.Day.day(%{}) end,
       fn -> {today, Kati.Calendar.SampleDay.occurrences(), true} end},
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
      {"10", Kati.Screens.UpNext, &Kati.Screens.UpNext.queue/0,
       &Kati.Screens.UpNext.Sample.queue/0},
      {"15", Kati.Screens.Activity, &Kati.Screens.Activity.log/0, &Kati.Screens.Activity.drawn/0},
      {"32", Kati.Screens.Calendars, &Kati.Screens.Calendars.calendar_list/0,
       &Kati.Screens.Calendars.drawn_calendars/0},
      # 34 is the partly-migrated one, and the whole map is compared for exactly
      # that reason: the order strip, the two switches and the subtitle are the
      # drawing's on BOTH branches, so a gate that looked only at the episode
      # list would pass while one of the frozen parts quietly changed.
      {"34", Kati.Screens.Season, &Kati.Screens.Season.season/0,
       &Kati.Screens.Season.drawn_season/0},
      # 28 is NOT here any more, and neither is 55. Both used to compare
      # `rest_of_today(Kati.Calendars.Today.rows())` with
      # `rest_of_today(Sample.rest_of_today())` — the assertion that a device
      # with nothing mirrored drew the drawing's 20:00 and 21:30. That is the
      # substitution #91 is about, one colourway and one script over, and their
      # gates are in `empties/0` now, one per band.
      # 29 answers with all four widgets at once, because it falls back one
      # widget at a time: three that still drew the drawing would hide a fourth
      # that had stopped being able to.
      {"29", Kati.Screens.Lock, &Kati.Screens.Lock.widgets/0, &Kati.Screens.Lock.drawn_widgets/0},
      {"33", Kati.Screens.Rating, &Kati.Screens.Rating.watch/0,
       &Kati.Screens.Rating.drawn_watch/0},
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
      # 92 gates both service groups at once — either the shelf is yours or the
      # whole page is the drawing's — and 24, 62 and 94 all gate on 92's own
      # reader rather than on a second one, because the count in Settings' row
      # and the list on 92 must never be able to disagree.
      {"92", Kati.Screens.MyServices, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"24", Kati.Screens.Settings, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # #25 and #11's readers. Four of the six borrow the pair they are built
      # on, which is the shape 120 already uses: the screen draws another
      # screen's `drawn_*` value, so what it depends on is that the borrowed
      # pair still agrees on an empty database, and that is what this asks.
      {"128", Kati.Screens.Backup, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"131", Kati.Screens.BackupDark, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"132", Kati.Screens.RestoreFa, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # 129 and 135 write rather than read: what they draw at rest is
      # `Kati.Backup.SampleRestore`'s fixture, and the database only enters on
      # the tap that restores. Their gate is 128's for the reason 106's is
      # 104's — a screen that restored into a Kati whose service list disagreed
      # with the page that sent it there would be the defect worth catching.
      {"129", Kati.Screens.Restore, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"135", Kati.Screens.RestoreFirstRun, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # 26 writes rather than reads: what it draws is its own section tiles, and
      # the database is only touched when someone answers the calendar dialog.
      # Gated on 128's reader for the reason 106 is gated on 104's — a first run
      # that ingested a calendar into a Kati whose service list disagreed with
      # the page that sent it there would be the defect worth catching.
      {"26", Kati.Screens.PickSections, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # 06 draws its own search results and writes on a tap; what it READS from
      # the store on an empty database is nothing at all. Gated on 92's reader
      # for the reason 106 is gated on 104's — a sheet that added a title into
      # a Kati whose service list disagreed with the page that opened it would
      # be the defect worth catching.
      {"06", Kati.Screens.AddTitle, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # 19 and 89 read the store through `Kati.Search.Query.run/1` and fall back
      # to the board when no query arrived from screen 86. The gate is that
      # fallback itself: `results_for/0` must answer the drawing on an empty
      # database, because screen 19 is the RESULTS page and the design never
      # puts a user on it without a query — 86 is the idle board, and it is
      # routed from Home.
      # 154 draws its own form and reads nothing: it WRITES on Add, which is
      # why it is on the migrated list at all. Gated on 92's reader for the
      # reason 06 is — a form that added a title into a Kati whose service list
      # disagreed with the page that opened it would be the defect worth
      # catching.
      {"154", Kati.Screens.AddByHand, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # 155 reads nothing at all — it is a picture of 154's two states, and it
      # is on the migrated list only because it calls 154's own helpers and the
      # list is derived from the compiled import table. Gated the same way 154
      # is, for the same reason.
      {"155", Kati.Screens.AddByHandStates, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # 156 and 157 are 154 in another script and another colourway, and read
      # exactly what it reads — nothing. On this list because they call its
      # helpers and the list is derived from the compiled import table.
      {"156", Kati.Screens.AddByHandFa, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"157", Kati.Screens.AddByHandDark, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      # 158 IS the empty state — it is screen 55 with nothing kept, so it
      # answers with its own emptiness rather than falling back to a drawing.
      # `Kati.Screens.HomeEmpty` is gated the same way for the same reason.
      {"158", Kati.Screens.HomeFaEmpty, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"159", Kati.Screens.HomeFaEmptyDark, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"160", Kati.Screens.HomeFaOmittedSections, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"19", Kati.Screens.Search, &Kati.Screens.Search.results_for/0,
       &Kati.Screens.Search.Sample.results/0},
      {"89", Kati.Screens.SearchResultStates, &Kati.Screens.Search.results_for/0,
       &Kati.Screens.Search.Sample.results/0},
      {"144", Kati.Screens.RateEpisode, &Kati.Screens.Rating.watch/0,
       &Kati.Screens.Rating.drawn_watch/0},
      # 149 is NOT here: it gates on `Kati.Screens.Library.titles/0`, which #91
      # made answer with the shelf and nothing else. Its gate is in `empties/0`,
      # still through Library's own reader for the reason it always was.
      {"62", Kati.Screens.SettingsFa, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"94", Kati.Screens.CountryPicker, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
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
      {"69", Kati.Screens.BookDetailFa, &Kati.Screens.BookDetailFa.book/0,
       &Kati.Screens.BookDetailFa.drawn_book/0},
      {"72", Kati.Screens.LogProgressFa, &Kati.Screens.BookDetailFa.book/0,
       &Kati.Screens.BookDetailFa.drawn_book/0},
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
      {"76", Kati.Screens.AlbumDetailFa, &Kati.Screens.AlbumDetail.album/0,
       &Kati.Screens.AlbumDetail.drawn_album/0},
      {"79", Kati.Screens.ArtistDetailFa, &Kati.Screens.ArtistDetail.artist/0,
       &Kati.Screens.ArtistDetail.drawn_artist/0},
      {"81", Kati.Screens.DataSourcesStates, &Kati.Screens.DataSources.cache_size/0,
       fn -> "Nothing cached yet" end},
      {"82", Kati.Screens.DataSourcesFa, &Kati.Screens.DataSources.cache_size/0,
       fn -> "Nothing cached yet" end},
      {"85", Kati.Screens.AttributionFa, &Kati.Screens.DataSources.cache_size/0,
       fn -> "Nothing cached yet" end},
      {"126", Kati.Screens.MoneyDay, &Kati.Screens.MoneyDay.rows/0,
       &Kati.Screens.MoneyDay.drawn_rows/0},
      {"93", Kati.Screens.MyServicesEmpty, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"95", Kati.Screens.MyServicesStates, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"96", Kati.Screens.NothingSetUpKnockOn, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"97", Kati.Screens.MyServicesFa, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"90", Kati.Screens.SearchFa, &Kati.Screens.MyServices.listed/0,
       &Kati.Screens.MyServices.drawn/0},
      {"102", Kati.Screens.YearShareDark, &Kati.Screens.AlbumDetail.field/0,
       &Kati.Music.Sample.listen_field/0},
      {"103", Kati.Screens.YearShareFa, &Kati.Screens.AlbumDetail.field/0,
       &Kati.Music.Sample.listen_field/0},
      {"105", Kati.Screens.GoalsEmpty, &Kati.Screens.Goals.goals/0,
       &Kati.Screens.Goals.drawn_goals/0},
      {"110", Kati.Screens.WeightStates, &Kati.Screens.Weight.entries/0,
       &Kati.Screens.Weight.drawn_entries/0},
      {"113", Kati.Screens.HealthEmptyStates, fn -> Kati.Screens.Health.day(today) end,
       &Kati.Screens.Health.drawn_day/0},
      {"107", Kati.Screens.GoalStates, &Kati.Screens.Goals.goals/0,
       &Kati.Screens.Goals.drawn_goals/0},
      {"108", Kati.Screens.GoalsFa, &Kati.Screens.Goals.goals/0,
       &Kati.Screens.Goals.drawn_goals/0},
      {"114", Kati.Screens.RetiredTile, fn -> Kati.Screens.Health.day(today) end,
       &Kati.Screens.Health.drawn_day/0},
      {"117", Kati.Screens.MealLibraryEmpty, &Kati.Screens.MealLibrary.meals/0,
       &Kati.Screens.MealLibrary.drawn_meals/0},
      {"123", Kati.Screens.MoneyStates, &Kati.Screens.Money.months/0,
       &Kati.Screens.Money.drawn_months/0},
      {"115", Kati.Screens.HealthFa, &Kati.Screens.Weight.entries/0,
       &Kati.Screens.Weight.drawn_entries/0},
      {"61", Kati.Screens.StatsFa, &Kati.Screens.Goals.goals/0,
       &Kati.Screens.Goals.drawn_goals/0},
      # The four pictures, each gated on the pair it borrows rather than on a
      # read of its own — the same shape 120 already uses. 121 draws 44's week
      # grid, 127 draws 122's months, and 63 and 64 both draw 28's lock widgets.
      {"121", Kati.Screens.WeekImage, fn -> Kati.Screens.MealPlan.plan(today) end,
       &Kati.Screens.MealPlan.drawn_plan/0},
      {"127", Kati.Screens.MoneyFa, &Kati.Screens.Money.months/0,
       &Kati.Screens.Money.drawn_months/0},
      {"63", Kati.Screens.MarkIos, &Kati.Screens.Lock.widgets/0,
       &Kati.Screens.Lock.drawn_widgets/0},
      {"64", Kati.Screens.MarkAndroid, &Kati.Screens.Lock.widgets/0,
       &Kati.Screens.Lock.drawn_widgets/0},
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
      # 56 answers with both halves of its day at once — the ordinary rows and
      # the evening's feature card — because only the drawn day has the second,
      # and a gate that looked at one half would pass while the other emptied.
      {"56", Kati.Screens.ScheduleFa, fn -> Kati.Screens.ScheduleFa.day(today) end,
       &Kati.Screens.ScheduleFa.drawn_day/0},
      {"57", Kati.Screens.LibraryFa, &Kati.Screens.LibraryFa.titles/0,
       &Kati.Screens.LibraryFa.drawn_titles/0},
      # 58 is 04's gate reached through 04's read, so this pair fails for two
      # different defects: a lost Persian fallback, and an English one — the
      # mirror cannot keep drawing its drawing if `tracked_series/0` stops
      # answering `nil` on an empty store.
      {"58", Kati.Screens.SeriesFa, &Kati.Screens.SeriesFa.series/0,
       &Kati.Screens.SeriesFa.drawn_series/0}
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
      {"03", Kati.Screens.Library, &Kati.Screens.Library.titles/0, [],
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
      # `Kati.Screens.HomeDark.Sample` and `Kati.Screens.HomeFa.Sample` stay
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
      {"55", Kati.Screens.HomeFa, &Kati.Screens.HomeFa.hero_summary/0, nil,
       &Kati.Screens.HomeFa.drawn_hero/0},
      {"55", Kati.Screens.HomeFa, &Kati.Screens.Home.continue_watching_rows/0, [],
       &Kati.Screens.HomeFa.Sample.continue/0},
      # The tiles themselves are navigation and are drawn either way; it is the
      # two metas under them that claimed a dinner and two unfinished habits,
      # and neither has a resource behind it anywhere. 01 carries the identical
      # pair one screen over.
      {"55", Kati.Screens.HomeFa, fn -> Enum.map(Kati.Screens.HomeFa.tile_rows(), & &1.meta) end,
       [nil, nil, nil], fn -> Enum.map(Kati.Screens.HomeFa.drawn_tiles(), & &1.meta) end},
      {"55", Kati.Screens.HomeFa, fn -> timeline() end, [],
       &Kati.Screens.HomeFa.Sample.rest_of_today/0}
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
      # `Kati.Screens.HomeFa.moment/0`, so a board-frozen ۲۵ مرداد ۱۴۰۵ is the
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
      {"149", "dropped the quiet ones at s1 e3", ~r/^drop at s1 e3$/},
      {"149", "undo", ~r/^still on it$/},
      # 115's direction note, which is the second board slip this list carries
      # and the same shape as 94's flag: the board writes *…و ستون امروز در سمت
      # راست است* — today's column is on the right — and its own bars put the
      # ink one at the left, because they are laid out oldest-first inside an
      # `rtl` row. `Kati.Screens.HealthFa`'s moduledoc has the full reasoning.
      # Reproducing the slip would ship a direction note pointing at the wrong
      # end of the chart, which every reader of the screen can check.
      #
      # The pattern insists on چپ rather than accepting either word, so a revert
      # to the board's راست fails here instead of quietly passing.
      {"115",
       "نمودار از راست به چپ خوانده می‌شود و ستون امروز در سمت راست است. " <>
         "اعداد وزن در dm mono با ارقام فارسی و جداکننده اعشار",
       ~r/^نمودار از راست به چپ .+ ستون امروز در سمت چپ است\./u},
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

  defp do_render_migrated do
    for {number, module} <- @migrated do
      case ScreenSweep.with_locale(:en, fn -> ScreenSweep.render(module) end) do
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
