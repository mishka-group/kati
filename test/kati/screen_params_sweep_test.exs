Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ScreenParamsSweepTest do
  @moduledoc """
  Every door into a screen that reads an argument either names one, or is
  written down here with a reason — in one of two inventories, because there
  are two different ways to hand a screen nothing — and every screen that reads
  one falls back to its drawing when the argument names a row that is gone.

  ## The defect this exists for

  A push is wired in two halves the compiler never introduces to each other.
  `Mob.Socket.push_screen/3` defaults its params to `%{}` (mob's
  `socket.ex:142`), so `push_screen(socket, Kati.Screens.MealEdit)` compiles,
  runs, navigates, and hands the editor nothing; `Kati.Screens.MealEdit` then
  reads `Map.get(socket.assigns.params || %{}, :meal_id)`, gets `nil`, and
  falls back to the library's first meal. The user taps the third row and the
  first row opens. Nothing raises, nothing is red, and the screenshot is
  correct because the screen it drew is a real screen about a real meal.

  That is #84 in one sentence, and Phase 1 wired fifty of them. This sweep is
  what stops the fifty-first being written.

  ## The ways this sweep was wrong before it was right

  Every one of these produced a confident clean run, or a confident wrong list,
  and each is the reason a line below reads the way it does.

    * **Keying the destination on `function_exported?(dest, :params_for, 1)`.**
      Four separate proposals did, and it is simply wrong.
      `Kati.Screens.RetiredTile` reads `Map.get(params, :section, @drawn)` at
      `retired_tile.ex:229` and publishes no builder at all; neither do
      `Kati.Screens.Day`, `Kati.Screens.MoneyDay` or `Kati.Screens.MealsDay`.
      A builder is a convenience for the caller, not the contract. What makes a
      screen a reader is that it reads, so the reader list is derived from the
      source that does the reading — the two shapes are
      `socket.assigns.params` (what `Kati.Screens.Pushed`'s generated mount
      assigns, `pushed.ex:56-58`) and a `def mount(params,` head that reaches
      for `Map.get(params, …)`.

    * **Scraping the keys with one fixed regex.** `Map.get(params, :key)`
      covers every reader in the app but one: `Kati.Screens.Season` rebinds
      `asked = params || %{}` at `season.ex:267` and reads `:title_id` and
      `:season` off `asked`. That reader came back with an EMPTY key list, and
      a reader with no keys is a reader assertion 2 skips in silence — it would
      have been swept, counted, and never actually checked. So the scan follows
      the rebinding, and `the derived readers are not vacuous` fails a reader
      whose keys came back empty rather than letting it pass over nothing.

    * **Deriving the pushes from the source.** No scan can see a push
      assembled in shared chrome or in a helper — `Kati.Screens.ViewSwitcher`
      is handed a tag and a socket and pushes on behalf of three screens that
      contain no `push_screen` call for it at all. So the pushes are dispatched
      for real: every tag `Kati.ScreenSweep.drawn_taps/1` says a screen drew is
      sent to `module.handle_info({:tap, tag}, socket)` and the answer is read
      off `updated.__mob__.nav_action`, which is the pair
      `Kati.ScreenTapSweepTest.outcome/3` already reads.

    * **Deriving the pushes from the runtime ALONE, which is the big one.**
      `{:push, dest, %{}}` is also exactly what a correctly wired
      `push_screen(socket, dest, Dest.params_for(row))` produces when `row` is
      a Sample module with no id on it — and every sweep in this repo renders
      against a store with nothing in it. Straight runtime reported 86 bare
      pushes into readers; twenty of them are real, twenty-one are the board
      index, and the remaining forty-five were `params_for/1` over a fixture —
      `Kati.Screens.MealsToday`'s five meal cards, all six of
      `Kati.Screens.MealLibrary`'s rows, `Kati.Screens.MealEdit`'s ingredients,
      `Kati.Screens.AlbumDetail`'s two, `Kati.Screens.LibraryFa`'s six tiles.
      An inventory of 86 would have been more than half false, and a false entry
      in an inventory is worse than no inventory: it is a written statement that
      a wired connection cannot be wired, sitting exactly where somebody would
      look to check. Those forty-five are not thrown away, though — they are a
      different fact about a real door, and they are what `@empty_builders`
      holds. Thirty-five doors are in that state as the app stands today.

      So the runtime finding is paired with the clause that answered the tag:
      `bare_in_source?/3`. When the `def` whose head names that tag pushes that
      destination with two arguments and never three, nobody wrote the
      argument. When no clause names the tag (a tag built by a `tag/1`, matched
      by a `"hit_" <> _` prefix), the question falls back to the whole module.
      See *what this cannot do* for what that fallback costs.

    * **Letting that pairing CANCEL the runtime finding, which is the same
      mistake from the other end.** The source check answers "did somebody
      write an argument", and for a while a `false` deleted the door from the
      sweep entirely — thirty-five live doors that hand a reader `%{}` were
      invisible, and the way out of the inventory was to write an argument
      rather than to carry one. Arity is not the payload:
      `push_screen(socket, Dest, Dest.params_for(row))` and
      `push_screen(socket, Dest, %{})` are the same push the moment `row` has
      no id, so a check that ends at *it passed three arguments* rewards the
      ceremony this file's own entry for `{Books, :log_progress, LogProgress}`
      calls out by name. The pairing SORTS the finding now; it never drops it.

    * **Comparing renders against whatever the suite happened to leave in the
      database.** With one row on the shelf, a bare mount answers with the
      newest row and a bogus id answers with the drawing, so the two differ —
      correctly, and assertion 2 would have failed on correct code, on the
      seeds that ordered the modules the wrong way round. It runs inside a
      transaction that empties the store and is rolled back, the shape
      `Kati.ScreenEmptyDatabaseTest.in_empty_database/1` uses. The tables are
      read out of `sqlite_master` rather than written down, because a
      hand-kept list of thirty-five table names is a list that silently stops
      covering the table added next week — the same argument
      `Kati.ScreenSweep.rolled_back/1` makes for a rollback over a `DELETE`.

    * **Treating every key a reader reads as an identity.** It is not.
      `Kati.Screens.Search` reads `:back` and `:query`, and those are VALUES —
      the word in the back pill and the words in the field. `"no-such-row"` is
      a perfectly good label and a perfectly good search term, so the two
      renders differ, and they should. `@carried_values` names the two, and
      `:scope` is deliberately NOT among them: `Kati.Search.narrowable/1`
      passes through the four chips the page draws and answers `"All"` for
      anything else, so a scope naming nothing renders the page that names
      nothing, exactly as an id does. That is the control that says this list
      is about the difference between a value and a reference rather than
      about keys `Kati.Screens.Search` happens to read.

  ## The two inventories, and why they are two

  A door that hands a reader `%{}` at runtime is on exactly one of these lists,
  and which one it is on is a fact about the source, not a matter of taste.

    * `@bare_pushes` — **nobody wrote the argument.** The clause that answers
      the tap pushes `dest` with two arguments and never three. Fixing one is
      an edit to that clause, so each entry says why that edit cannot be made:
      the source holds nothing to name.

    * `@empty_builders` — **the row has no id.** The clause names its subject
      and hands it to the destination's own `params_for/1`, and the builder
      answers `%{}` because the row it was given carries no id — every screen
      here fell back to its drawn fixture, and a fixture row is a literal map
      with an artwork seed and no `:id`. Nothing in the push can fix one of
      these; the fix is a change to where the SCREEN gets its rows. That is the
      round after this one, so this list is the BACKLOG, kept where the sweep
      can keep it honest rather than in prose nothing checks.

  Both are ratchets in both directions. A door that arrives in neither fails
  the assertion over its half; a door that leaves one fails that half's *has no
  stale entries* test. And the split is what stops the two facts trading
  places: writing `Dest.params_for(row)` over a row with no id moves a line
  from the first list to the second, which is red twice — once for the arrival
  and once for the departure — rather than a line quietly disappearing.

  ## What this cannot do, and no amount of care will fix

    * **"Every push from a list row carries a third argument" is not
      assertable.** Nothing in a rendered tree distinguishes a list row from a
      menu row or a settings link, and most two-argument pushes in the app are
      correct. Inverting it so the DESTINATION declares the requirement is what
      makes it mechanical, and that inversion is assertion 1.

    * **"The right film appears" is not assertable here.** Assertion 2 makes
      that concrete rather than hiding it: two ids that name nothing render
      identically BY DESIGN, so proving a screen distinguishes two subjects
      needs two real stored rows, and that is per-domain work — a tracked
      title, a cache row, seasons and episodes for screen 04 alone. That claim
      lives in `test/kati/sheet_row_identity_test.exs`, which exists for it and
      already builds its rows in a rolled-back transaction.

    * **A grid with nothing on the shelf draws no per-row tags.** This is the
      empty store again, from the other side. `Kati.Screens.Library` answers an
      empty shelf with screen 27's `No titles yet` card, so screen 03's poster
      pushes — a whole batch of the connections this round is about — are
      INVISIBLE to assertion 1 until a device or a fixture puts titles on the
      shelf. `Kati.ScreenTapSweepTest` records the same hole for the same
      screen. Do not seed to paper over it: seeding changes what every screen
      draws and turns the sweep into a fixture suite.

    * **A computed tag is only asked of its module.** `bare_in_source?/3` finds
      the clause by looking for the tag atom in a `def` head, and a tag built
      at render time (`Kati.Screens.MealsToday.meal_tag/2`, `"hit_" <> index`)
      appears in no head. Those fall back to the module-wide question, so a
      module with one wired door into a destination masks a bare door into the
      same destination reached by a computed tag. `Kati.Screens.LibraryFa`'s
      six tiles are the shape of the thing being traded away — and they are
      also the shape of the forty-five false positives that made the trade
      worth taking.

      Since the split, a masked door is MISFILED rather than invisible: it is
      still reported, on `@empty_builders`, where its line will claim a fixture
      with no id is the reason it carries nothing. That is a smaller loss than
      vanishing and a real one, and it is the reason each entry there names the
      fixture and the builder rather than saying "no id yet" — a line nobody
      can check is how a masked door would hide inside the backlog.

    * **It sees one push per `{screen, tag}`, not per call site.** A clause
      with two branches into one destination, one naming an id and one not, is
      swept as whichever branch the empty store takes.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  @locales [:en, :fa]

  # Every door into a params reader that hands it nothing, as of 2026-09-05.
  # `{screen, tag, destination}`, and each is a fact about the SOURCE having
  # nothing to name — never a to-do. `the bare-push list has no stale entries`
  # fails on an entry that has since learned to name something, so this list may
  # only shrink.
  #
  # Before adding a line here, read the fourth bullet of the moduledoc. A tap
  # only reaches this list when the clause that answers it pushes with two
  # arguments, so "the row it belongs to had no id in the fixture" is NOT a
  # reason that applies to anything below — that case is `@empty_builders`, and
  # a door in that state fails the assertion over THAT list instead.
  @bare_pushes [
    # ── The Day/Week/Month/Agenda switcher's `Day` segment, drawn by all three
    # of the other views. `Kati.Screens.Day` can receive a date — it is
    # `use Kati.Screens.Pushed` and `day/1` reads `%{date: date}` — but none of
    # the three sources holds one to send. `week.ex:39` assigns
    # `SampleWeek.week()`, `month_grid.ex:39` `SampleMonth.month()`,
    # `agenda.ex:47` `SampleAgenda.agenda()`, and the only day-shaped values in
    # those fixtures are display labels: `Thu 13 · 9 items`, `August 2026`.
    # Carrying a label is worse than carrying nothing.
    #
    # Attributed to the three screens that DRAW the segment rather than to
    # `Kati.Screens.ViewSwitcher`, which is what pushes: the switcher is shared
    # chrome, it is not a screen, `Kati.ScreenSweep.screens/0` does not return
    # it, and `view_switcher.ex:150-155` is handed a tag and a socket and knows
    # nothing about which screen drew it. That is also why it has no
    # view-specific value to pass.
    #
    # `test/kati/screen_empty_database_test.exs:1329` pins the bare push into 09
    # as the branch that must answer with the drawn day, so this is load-bearing
    # in both directions. Unblocks when 16/17/30 move off their fixtures onto
    # real dates.
    {Kati.Screens.Agenda, :view_Day, Kati.Screens.Day},
    {Kati.Screens.MonthGrid, :view_Day, Kati.Screens.Day},
    {Kati.Screens.Week, :view_Day, Kati.Screens.Day},

    # ── Rate, from the two domains screen 33 does not rate.
    #
    # The only key `Kati.Screens.Rating` reads is `:tracked_title_id`
    # (`rating.ex:262`), and its whole path — `logged_record/1`,
    # `save_watch/1`, `watch_id` — is a `Kati.Media.Watch` over a
    # `Kati.Media.TrackedTitle`. A book id or an album id put in that key would
    # name a row `Ash.get/2` can never find, and `Kati.Books.Book.rating` is a
    # separate ten-point integer on the book itself, not a watch.
    #
    # Making 33 rate a book or an album is a screen build — a second reader, a
    # second writer, and a decision about which of two rating columns the stars
    # commit to — not a params fix. `Kati.Screens.Film` and
    # `Kati.Screens.Series` are the control: they push the same screen and DO
    # name a title, which is what says 33's contract is wired and these five
    # doors are the ones with nothing to put in it.
    # (`{Kati.Screens.AlbumDetail, :rate, Kati.Screens.Rating}` was here. `D-39`
    # built the screen this paragraph said was the only fix — board 180, an
    # album rating sheet in 144's manner — and screen 74's Rate row now pushes
    # `Kati.Screens.RateAlbum` naming the album the page drew. The door moved to
    # `@empty_builders`, because the clause names its subject and the builder
    # answers `%{}` only while the page is drawing `Kati.Music.Sample.album/0`.
    # The Persian twin below is untouched: no board reserves a Persian rating
    # sheet for music, and 297 is `D-57`'s.)
    {Kati.Screens.AlbumDetailFa, :rate, Kati.Screens.Rating},
    {Kati.Screens.BookDetail, :rate, Kati.Screens.Rating},
    {Kati.Screens.BookDetailDark, :rate, Kati.Screens.Rating},
    {Kati.Screens.BookDetailFa, :rate, Kati.Screens.Rating},
    # 157's `Finish`, which is 66's in another colourway. The English screen's
    # own `:finish` is absent from this list rather than fixed: on the empty
    # shelf it has no book to finish and returns without pushing at all, so the
    # sweep never sees it. Screen 157 draws its board's state instead of
    # reading, so its `Finish` pushes on every path.
    {Kati.Screens.BookDetailDark, :finish, Kati.Screens.Rating},

    # ── Screen 117's `New meal`, and correct forever.
    #
    # `meal_library.ex:437-440` says it in the source: `:add` is the one push
    # that is deliberately given no meal, because it opens the editor ON a new
    # meal and the editor's no-id path is the blank one. The six tiles beside it
    # are the control — `open_meal/2` resolves the tile's index to the row and
    # pushes `Kati.Screens.MealEdit.params_for(meal)`, which is the fix for
    # exactly the defect its own comment describes: *tap the third meal, edit
    # the first*.
    {Kati.Screens.MealLibrary, :add, Kati.Screens.MealEdit},

    # ── Screen 43's `Swap`, ON THE DRAWN DAY, which is the only day this
    # sweep sees. Bare because the board has no slot, not because the screen
    # has no id to send.
    #
    # This entry's reason changed on 2026-09-05 and the change is worth having
    # written down, because the tag it names is no longer the tag a real card
    # draws. **Swap** used to be `:swap` on EVERY card, and the clause
    # answering it took the first upcoming meal it could find — so a day with
    # lunch and dinner still ahead drew two Swap buttons under one name and
    # tapping dinner's swapped the lunch. `Kati.Screens.MealsToday.tag/2` now
    # builds `:swap_<slot id>` the way it already built `:mark_eaten_<slot id>`,
    # and `swap/2` resolves that id against the rows THIS render drew.
    #
    # So a real card never reaches the clause this line is about. What does is
    # `Kati.Meals.SampleToday`, whose rows have no slot id — the same absence
    # that puts the five cards above in `@empty_builders` — and the clause is
    # bare because a transcription of a board has no slot to name. It is not
    # `%{}` standing in for a lost argument; there is no argument in the room.
    #
    # The argument still travels by the other channel when there IS one:
    # `swap/2` hands the slot over through `Mob.State`
    # (`Kati.Screens.MealSwap.hand_over/1`), the way screen 86 hands a query to
    # 19, and `Kati.Screens.MealSwap.swap/1` reads a named slot first and falls
    # back to that. `Kati.MealSwapTest` drives that door directly, and
    # `Kati.MealsTodayWriteTest` drives the per-card tags. Moving it onto the
    # push would be changing the door screen 46 was built around.
    {Kati.Screens.MealsToday, :swap, Kati.Screens.MealSwap},

    # ── Screen 151's `Log by hand`, and correctly bare.
    #
    # 151 is a permission board about the notification listener
    # (`notification_access.ex:105`); it holds no album, no artist and no shelf
    # read of any kind. Its own doc says what the tap means at
    # `notification_access.ex:461-464`: the sheet gates AUTO-detecting a listen,
    # so what it offers instead is hand-logging in general.
    # `Kati.Screens.LogListen`'s no-id path — the shelf's first, then the
    # drawing (`log_listen.ex:50-52`) — is the right semantics for that, and an
    # explicit `%{}` would be the same value this push already sends. No edit.
    {Kati.Screens.NotificationAccess, :log_by_hand, Kati.Screens.LogListen},

    # ── Screen 90's two hits.
    #
    # `@hits` at `search_fa.ex:215-231` is two typed maps and `mount/3` reads
    # nothing, so the only identifier a hit carries is its design seed
    # (`hollow71`). `Kati.Seeds.sample_source_id/1` would turn that into the
    # `{source, source_id}` pair a real shelf row carries, but `Kati.Seeds.groups/0`
    # seeds `:calendars` and `:media` only and never a
    # `Kati.Media.TrackedTitle`, so the reference would resolve to nothing.
    # Both hits are the same series in Persian, which is why one destination
    # answers both (`search_fa.ex:971-976`).
    {Kati.Screens.SearchFa, :hit_0, Kati.Screens.SeriesFa},
    {Kati.Screens.SearchFa, :hit_1, Kati.Screens.SeriesFa}
  ]

  # Every door into a params reader that names its subject and hands the reader
  # nothing anyway, as of 2026-09-05, because the subject it named has no id.
  # `{screen, tag, destination}`.
  #
  # This is the other half of the split. In `@bare_pushes` above, the clause
  # pushes with two arguments and the source has nothing to name. Here the
  # clause pushes `Dest.params_for(row)` — the shape that FIXED #84 at each of
  # these doors, and most of them say so in a comment over the push — and
  # `params_for/1` answers `%{}` because `row` is the screen's drawn fixture: a
  # literal map with an artwork seed on it and no id, which is what each of
  # these screens falls back to while its own table holds no rows. The tap
  # resolves the right row; the row has no name to give.
  #
  # The pass does not FORCE that emptiness — `pushes/0` says why it must not —
  # so a run that found one of these domains stocked would report those lines
  # as stale rather than pass over them silently. Six orderings on 2026-09-05
  # found the same thirty-five.
  #
  # So this list is a BACKLOG and not a defect list, and no edit to any push
  # can shorten it. Each line ends when its screen's shelf holds real rows —
  # which is a change to `lib/`, one domain at a time, and not this file's
  # business. Its value is that the thirty-five are now countable: before the
  # split they were cancelled by the source check and appeared nowhere at all.
  #
  # Ratcheted both ways, like the list above. A new door that builds an empty
  # argument has to be written down here with the fixture named; a door whose
  # rows grew ids has to be deleted from here.
  @empty_builders [
    # ── Screen 117's six meal tiles.
    #
    # `meal_library.ex:455-459` resolves the tile's index back to the row this
    # render drew and pushes `Kati.Screens.MealEdit.params_for(meal)`, and its
    # own comment names the defect it closed: *tap the third meal, edit the
    # first*. With no recipes stored, `meal_library.ex:56` answers with
    # `Kati.Meals.SampleLibrary.meals/0`, whose six rows carry no `:id` — the
    # file says so at `meal_library.ex:88` — so `params_for/1`
    # (`meal_edit.ex:116-117`) answers `%{}`.
    #
    # `:add` beside them is in `@bare_pushes` and is the control for this whole
    # list: same screen, same destination, and bare ON PURPOSE, because a new
    # meal has no id to carry rather than none to find.
    {Kati.Screens.MealLibrary, :open_meal_0, Kati.Screens.MealEdit},
    {Kati.Screens.MealLibrary, :open_meal_1, Kati.Screens.MealEdit},
    {Kati.Screens.MealLibrary, :open_meal_2, Kati.Screens.MealEdit},
    {Kati.Screens.MealLibrary, :open_meal_3, Kati.Screens.MealEdit},
    {Kati.Screens.MealLibrary, :open_meal_4, Kati.Screens.MealEdit},
    {Kati.Screens.MealLibrary, :open_meal_5, Kati.Screens.MealEdit},

    # ── Screen 43's five timeline cards.
    #
    # `Kati.Screens.MealsToday.open_meal/2` finds the row back by rebuilding
    # every row's own tag and pushes `Kati.Screens.Meal.params_for(meal)`. With
    # no plan stored the day is `Kati.Meals.SampleToday`'s and no sample row has
    # a `:slot_id`, which `Kati.Screens.MealsToday.tag/2` states in its own doc,
    # so `Kati.Screens.Meal.params_for/1` answers `%{}`.
    #
    # `:swap` on the same screen is in `@bare_pushes` for a related reason and
    # not the same one: these five carry an argument that is empty, and that
    # one has no argument to carry. Both come off the same fixture, which is
    # why one domain's rows will clear all six lines at once — and neither is
    # fixable from the push.
    {Kati.Screens.MealsToday, :"meal_Breakfast_07:30", Kati.Screens.Meal},
    {Kati.Screens.MealsToday, :"meal_Dinner_19:30", Kati.Screens.Meal},
    {Kati.Screens.MealsToday, :"meal_Lunch_13:00", Kati.Screens.Meal},
    {Kati.Screens.MealsToday, :"meal_Snack_10:30", Kati.Screens.Meal},
    {Kati.Screens.MealsToday, :"meal_Snack_16:00", Kati.Screens.Meal},

    # ── Screen 118's `Add an ingredient` row and its five ingredient chevrons,
    # and this is the one that is empty for a borrowed reason.
    #
    # `ingredient_sheet/1` (`meal_edit.ex:853-859`) pushes
    # `params_for(%{id: socket.assigns.meal_id})` — the editor naming its own
    # meal to the sheet, so a line is filed against the meal whose row was
    # tapped and not against the head of a re-query. `:meal_id` is `nil` here
    # because the editor itself was opened by the six tiles above with `%{}`,
    # so the emptiness is INHERITED: these six clear themselves the day screen
    # 117's rows carry ids, without an edit to this screen at all.
    #
    # All six tags reach the one clause. `:edit_ingredient` is shared by every
    # ingredient row on purpose — `meal_edit.ex:847-852` — and the tags below
    # are the rows' own.
    {Kati.Screens.MealEdit, :add_ingredient, Kati.Screens.AddIngredient},
    {Kati.Screens.MealEdit, :ingredient_Coconut_milk, Kati.Screens.AddIngredient},
    {Kati.Screens.MealEdit, :ingredient_Curry_leaves, Kati.Screens.AddIngredient},
    {Kati.Screens.MealEdit, :ingredient_Onion, Kati.Screens.AddIngredient},
    {Kati.Screens.MealEdit, :"ingredient_Red_lentils,_dry", Kati.Screens.AddIngredient},
    {Kati.Screens.MealEdit, :ingredient_Spinach, Kati.Screens.AddIngredient},

    # ── Screen 57's six grid tiles.
    #
    # `library_fa.ex:926-934` looks the tile back up by its poster tag and
    # pushes `Kati.Screens.Series.params_for/1` over it, so the Persian grid
    # and the English one spell `:id` once between them. The empty shelf falls
    # back to `Kati.Screens.LibraryFa.Sample.titles/0`
    # (`library_fa/sample.ex:53-62`), six literals whose only unique field is a
    # `seed` for the artwork, so `series.ex:258-259` answers `%{}`.
    #
    # The tags are the titles with their spaces replaced (`poster_tag/1`,
    # `library_fa.ex:744-753`), which is also why they are the tiles' identity
    # in this list and not in the push.
    {Kati.Screens.LibraryFa, :open_series_بارش_خاکستر, Kati.Screens.SeriesFa},
    {Kati.Screens.LibraryFa, :open_series_بندر_آرام, Kati.Screens.SeriesFa},
    {Kati.Screens.LibraryFa, :open_series_ساعت_آبی, Kati.Screens.SeriesFa},
    {Kati.Screens.LibraryFa, :open_series_نمک_و_آهن, Kati.Screens.SeriesFa},
    {Kati.Screens.LibraryFa, :open_series_پرندگان_شب, Kati.Screens.SeriesFa},
    {Kati.Screens.LibraryFa, :open_series_گودال_بلند, Kati.Screens.SeriesFa},

    # ── Screen 77's four album rows.
    #
    # `artist_detail.ex:736-752` finds the row back in the list this page drew
    # and pushes `Kati.Screens.AlbumDetail.params_for(row)`. Its comment above
    # the clause is the reason in the source's own words: the tag is built from
    # title and year *precisely because the drawing's four rows carry
    # `seed: nil`*. With no artist stored the rows are
    # `Kati.Music.Sample.artist_albums/0` (`music/sample.ex:238-245`) and none
    # holds an `:id`, so `album_detail.ex:100-101` answers `%{}`.
    {Kati.Screens.ArtistDetail, :open_album_Estuary_Tapes, Kati.Screens.AlbumDetail},
    {Kati.Screens.ArtistDetail, :open_album_Low_Country_2023, Kati.Screens.AlbumDetail},
    {Kati.Screens.ArtistDetail, :open_album_Nine_Rooms_2021, Kati.Screens.AlbumDetail},
    {Kati.Screens.ArtistDetail, :open_album_Tidal_Works_2025, Kati.Screens.AlbumDetail},

    # ── Screens 73 and 74's `Log a listen` and artist row, in both languages.
    #
    # `album_detail.ex:857-881` and `album_detail_fa.ex:911-939` hand
    # `socket.assigns.album` to the sheet's and the artist page's builders, and
    # both comments record the #84 they closed — a page opened on the third
    # album credited the play, and bumped the track counts, on the first. With
    # nothing shelved the album is `Kati.Music.Sample.album/0`
    # (`music/sample.ex:90-108`), which has neither `:id` nor `:artist_id`, so
    # `album_detail.ex:100-101` and `artist_detail.ex:73-74` answer `%{}`.
    #
    # The Persian mirror pushes the Persian artist page and the ENGLISH sheet
    # deliberately; `album_detail_fa.ex:903-909` is where that debt is written
    # down, and it is not this file's.
    {Kati.Screens.AlbumDetail, :log_listen, Kati.Screens.LogListen},
    {Kati.Screens.AlbumDetail, :open_artist, Kati.Screens.ArtistDetail},
    # Screen 74's `Rate`, which since `D-39` names an album to screen 180
    # instead of naming nothing to screen 33. `album_detail.ex`'s clause pushes
    # `Kati.Screens.RateAlbum.params_for(%{id: target(socket.assigns)})` —
    # through `target/1`, so a page drawing the fixture because the record it
    # was opened on has been deleted cannot fall through to somebody else's
    # album. With nothing shelved that target is `nil`, because
    # `Kati.Music.Sample.album/0` has no `:id`, so the builder answers `%{}`
    # exactly as the two doors above it do and clears with the same rows.
    {Kati.Screens.AlbumDetail, :rate, Kati.Screens.RateAlbum},
    {Kati.Screens.AlbumDetailFa, :log_listen, Kati.Screens.LogListen},
    {Kati.Screens.AlbumDetailFa, :open_artist, Kati.Screens.ArtistDetailFa},

    # ── Screens 66, 157 and 69's `Log progress`.
    #
    # `book_detail.ex:1003-1010`, `book_detail_dark.ex:585-592` and
    # `book_detail_fa.ex:653-660` all push
    # `Kati.Screens.LogProgress.params_for(socket.assigns.book)`, one builder
    # for three doors so the English sheet and the Persian one cannot drift
    # about what `:book_id` means. Nothing shelved makes the book
    # `Kati.Books.Sample.detail/0` (`books/sample.ex:91-114`) — or its Persian
    # twin — and neither holds an `:id`, so `log_progress.ex:105-106` answers
    # `%{}`. `book_detail.ex:997-1001` says exactly this.
    #
    # `{Kati.Screens.Books, :log_progress, Kati.Screens.LogProgress}` used to sit
    # in `@bare_pushes` as the same pill on the shelf screen, over the same
    # id-less hero, with the argument NOT written — the clearest pair of entries
    # in this file for what the two lists are for. Screen 20's shelf moved onto
    # `Kati.Books.Book` on 5 September and the argument is written now, so that
    # door crossed from that list to this one. It did not leave both, and the
    # difference between the two days is exactly what these lists measure: the
    # source names its subject, and with nothing shelved the subject is still
    # the drawing's hero and the builder still answers `%{}`. The entries below
    # it are that same pill's four other doors.
    {Kati.Screens.BookDetail, :log_progress, Kati.Screens.LogProgress},
    {Kati.Screens.BookDetailDark, :log_progress, Kati.Screens.LogProgress},
    {Kati.Screens.BookDetailFa, :log_progress, Kati.Screens.LogProgressFa},
    {Kati.Screens.Books, :log_progress, Kati.Screens.LogProgress},
    # Screen 176's ثبت پیشرفت pill — screen 20's, one script over, and it
    # arrives on this list rather than in `@bare_pushes` for the reason the
    # paragraph above gives about screen 20: `books_fa.ex` names its subject
    # and hands `socket.assigns.page.hero` to `Kati.Screens.LogProgress`'s own
    # builder, the same builder 20, 66, 68 and 69 use, so the English sheet and
    # the Persian one cannot drift about what `:book_id` means. With nothing
    # shelved the hero is `Kati.Books.SampleFa.reading_now/0`, which is
    # `detail/0` reshaped and carries no `:id`, so `log_progress.ex:105-106`
    # answers `%{}`.
    #
    # `:start_timer` beside it is NOT here and is not missing: it merges
    # `timing?: true` onto the same builder's answer, so the argument is
    # non-empty even over a fixture. Screen 20's pair splits the same way.
    {Kati.Screens.BooksFa, :log_progress, Kati.Screens.LogProgressFa},

    # ── Screen 20's grid and its hero cover, into screen 66.
    #
    # `books.ex` resolves a tapped tile back to the row the grid drew and pushes
    # `Kati.Screens.BookDetail.params_for(row)`; the hero cover pushes the same
    # builder over the hero. Screen 66 reads `:book_id` since the same round, so
    # the contract is wired end to end and the drawing is what empties it: with
    # nothing shelved the six rows are `Kati.Books.Sample.books/0`
    # (`books/sample.ex:24-31`) and the hero is `reading_now/0`, and no row in
    # either has an `:id`.
    #
    # Seven tags rather than one clause's worth, because the six tile tags are
    # built at render time from each row's identity — `books.ex`'s `book_tag/1`
    # — and a shelved row's tag is its uuid. These six are the drawing's seeds,
    # which is what the sweep renders and what it will keep rendering.
    {Kati.Screens.Books, :open_book, Kati.Screens.BookDetail},
    {Kati.Screens.Books, :open_book_bookaa1, Kati.Screens.BookDetail},
    {Kati.Screens.Books, :open_book_bookbb2, Kati.Screens.BookDetail},
    {Kati.Screens.Books, :open_book_bookcc3, Kati.Screens.BookDetail},
    {Kati.Screens.Books, :open_book_bookdd4, Kati.Screens.BookDetail},
    {Kati.Screens.Books, :open_book_bookee5, Kati.Screens.BookDetail},
    {Kati.Screens.Books, :open_book_bookff6, Kati.Screens.BookDetail},

    # ── Screen 21's three tiles and its two release rows.
    #
    # These five CROSSED from `@bare_pushes` on 5 September, the way screen 20's
    # `Log progress` pill did an hour earlier, and the entry they replace is
    # worth quoting because it was true when it was written: *no album or artist
    # identity exists at the tap … screen 21 never reads `Kati.Music.Album`, and
    # nothing anywhere in `lib/` creates one.* It reads it now. `music.ex`'s
    # `page/0` is one entry point over `Kati.Music.Album`'s `:shelf`,
    # `Kati.Music.Artist`'s `:followed` and `Kati.Music.Listen`, its rows carry
    # the album's own id and the artist's, and `open_album/2` and `open_artist/2`
    # resolve a tapped tag back to the row the render drew and hand it to the
    # destination's own builder.
    #
    # So the source names its subject, and what empties the argument is the
    # drawing: with nothing shelved the three tiles are
    # `Kati.Music.Sample.albums/0` (`music/sample.ex:20-28`) and the two rows are
    # `releases/0` (`music/sample.ex:71-77`), literal maps whose only unique
    # field is an ARTWORK seed — `albm1`…`albm5`, for
    # `Kati.Design.Images.poster/1` — and no row in either has an `:id` or an
    # `:artist_id`. `album_detail.ex`'s `params_for/1` and
    # `artist_detail.ex`'s answer `%{}`.
    #
    # The tags are the drawing's seeds because that is what the sweep renders. A
    # shelved row's tag is its uuid — `album_tag/1` takes the id first and the
    # seed second, because `art_seed` is nullable and two pressings can share
    # one.
    {Kati.Screens.Music, :open_album_albm1, Kati.Screens.AlbumDetail},
    {Kati.Screens.Music, :open_album_albm2, Kati.Screens.AlbumDetail},
    {Kati.Screens.Music, :open_album_albm3, Kati.Screens.AlbumDetail},
    {Kati.Screens.Music, :open_artist_albm4, Kati.Screens.ArtistDetail},
    {Kati.Screens.Music, :open_artist_albm5, Kati.Screens.ArtistDetail},

    # ── Screen 45's `Swap`.
    #
    # `meal.ex:1169-1173` pushes `Kati.Screens.MealSwap.params_for(meal)` and
    # its comment says why the push and not the store: 46 used to open on
    # whatever slot `Mob.State` still held from a tap on another screen. A
    # drawn meal has no `:slot_id` — `meal.ex:108-113` falls back to
    # `drawn_meal/0` — so `meal_swap.ex:162-163` answers `%{}` and 46 reads the
    # store exactly as it did.
    #
    # `{Kati.Screens.MealsToday, :swap, Kati.Screens.MealSwap}` is in
    # `@bare_pushes`, and the pair is not a contradiction: 43 hands its slot
    # over through `Mob.State` on purpose, 45 names it on the push. Two doors
    # into 46, two mechanisms, two lists.
    {Kati.Screens.Meal, :swap, Kati.Screens.MealSwap},

    # ── Screen 112's four Schedules chevrons, into screen 189.
    #
    # `medication.ex`'s `other_tap/2` finds the row back by rebuilding every
    # schedule's own tag against the list THIS RENDER drew — the shape #84
    # settled on the doses above them — and pushes
    # `Kati.Screens.MedicationDetail.params_for(schedule)`. The tags are the
    # medicines' own names (`schedule_tag/1`, #97), which is also why they are
    # four lines here rather than one.
    #
    # They were in `Kati.ScreenTapSweepTest`'s inert list until D-43, with the
    # reason that no per-medication page was drawn anywhere. Board 189 is that
    # page. What empties the argument now is the same thing that empties every
    # line above: with nothing stored, `Kati.Screens.Medication.schedules/0`
    # answers with `Kati.Health.WeightSample.schedules/0`, four literal maps
    # that carry no `:id` at all, so `params_for/1` answers `%{}`.
    #
    # These four clear the day a medication is stored, and screen 188 is the
    # first thing in the app that can store one — so unlike most of this list,
    # the change that ends them is a tap rather than a migration.
    {Kati.Screens.Medication, :open_schedule_Levothyroxine, Kati.Screens.MedicationDetail},
    {Kati.Screens.Medication, :open_schedule_Vitamin_D, Kati.Screens.MedicationDetail},
    {Kati.Screens.Medication, :open_schedule_Iron, Kati.Screens.MedicationDetail},
    {Kati.Screens.Medication, :open_schedule_Magnesium, Kati.Screens.MedicationDetail}
  ]

  # Keys a reader takes that are a VALUE rather than a reference to a row, with
  # the render they change. Exempt from assertion 2 because the assertion is
  # about identity: a label that names no row is still a label.
  #
  # `the carried-value list has no stale entries` fails on an entry whose two
  # renders now agree, so this list may only shrink too — and if one ever does
  # agree, the key stopped being read and the exemption is the thing hiding it.
  @carried_values [
    # The word in the back pill. `Kati.Screens.Search`'s `@drawn_back` is
    # `Home` because board 19 draws `Home`, and a door names its own name —
    # `books.ex:678` pushes `%{query: "", back: "Books"}`. Any string is a
    # valid label, so a string naming no row renders as itself. That is the
    # param working.
    {Kati.Screens.Search, :back},
    # The words in the field. `Kati.Search.Query.run("no-such-row")` is a real
    # search for that phrase and correctly answers with empty groups, where a
    # push naming no query at all opens on `Kati.Search.handed_over/0` — see
    # `Kati.Screens.Search.opening_query/1` for why silence and `""` are two
    # different answers. Both are right; they are not the same render.
    {Kati.Screens.Search, :query}
  ]

  # Readers named by hand, so a scan that stops matching fails loudly instead of
  # passing over nothing. Each was read at the line beside it. `Season` is here
  # because it is the one the first version of the key scan went blind on.
  @named_readers [
    # `socket.assigns.params`, the `Kati.Screens.Pushed` shape.
    {Kati.Screens.AlbumDetail, :album_id},
    {Kati.Screens.Day, :date},
    {Kati.Screens.MealEdit, :meal_id},
    {Kati.Screens.MealsDay, :date},
    {Kati.Screens.MoneyDay, :date},
    {Kati.Screens.Season, :title_id},
    # `def mount(params, …)` plus `Map.get(params, …)`, the hand-rolled shape.
    {Kati.Screens.EventDetail, :id},
    {Kati.Screens.LogListen, :album_id},
    {Kati.Screens.BookDetail, :book_id},
    {Kati.Screens.LogProgress, :book_id},
    {Kati.Screens.RetiredTile, :section},
    # The five the comment below used to name as pinned NOWHERE. A count that
    # may only go up catches a reader leaving; it does not catch one leaving
    # while another arrives, and `@derived_readers` is armed with no margin at
    # all. So the screens Phase 1 turned INTO readers are named here, each read
    # at the line beside it, and the guard is now about the set and not only
    # the size.
    {Kati.Screens.AddIngredient, :meal_id},
    {Kati.Screens.Film, :id},
    {Kati.Screens.Meal, :slot_id},
    {Kati.Screens.Search, :query},
    {Kati.Screens.Series, :id}
  ]

  # What the scan actually finds, and a RATCHET: it may only go UP.
  #
  # This is the number the non-vacuity guard is armed at, and arming it at
  # `length(@named_readers)` instead was the hole it exists to close: the scan
  # finds twenty-one readers and the hand-list holds ten, so `21 >= 10` passed
  # with ELEVEN readers gone — more than half the set, and
  # `Kati.Screens.Film`, `Kati.Screens.Search`, `Kati.Screens.Meal`,
  # `Kati.Screens.Series` and `Kati.Screens.AddIngredient` are pinned nowhere
  # else in this file. A reader leaves the scan for edits that change no
  # behaviour at all — renaming a `mount/3` argument, spelling a read
  # `params[:id]` — and every door into it leaves assertion 1 and the fallback
  # lock with it, silently.
  #
  # `@named_readers` stays what it is: a sample, ten screens read at the line
  # beside each, which says WHICH screens rather than how many. This says how
  # many, and the two are pinned to different things on purpose.
  #
  # Lowering it is allowed only beside the reason a screen stopped reading its
  # params, in the commit that stopped it.
  #
  # 21 → 22 on 5 September: `Kati.Screens.BookDetail` reads `:book_id` now, so
  # screen 20's grid can name the book a tile opens rather than leaving 66 to
  # take the shelf's head. Re-arming it is the point of a ratchet — left at 21
  # it would have absorbed the next reader to go missing.
  @derived_readers 22

  # Screens whose CODE says `params` and which `reader?/1` deliberately does not
  # count. The coarse half of guard A.
  #
  # Every guard above this line is downstream of one regex pair, and a regex is
  # a spelling. `params[:id]`, `Map.fetch!(params, :id)`, `%{id: id} = params`
  # and a mount head written `def mount(p,` are all a screen reading its
  # argument, and `reader?/1` sees none of them — it would answer *not a
  # reader*, the fallback lock would stop checking that screen, and the count
  # above would stay at 21 as long as something else joined. So this asks a
  # question no spelling can dodge: **the word `params`, anywhere in the code**.
  # A screen that mentions it is either a reader or written down here.
  #
  # Comments and docs are stripped before the question is asked, because this
  # file's own prose says `params` on nearly every page and so do the screens'.
  #
  # It is empty, and that is the useful state: every screen in the app that
  # names `params` in code is a reader the scan finds. A row here is a claim
  # that a screen names it and means something else, and it needs a sentence
  # saying what.
  @not_readers []

  # What the app's own screens reach, with the board index left out. Counted
  # WITHOUT `Kati.Screens.Gallery` for the reason the guard itself gives: the
  # board index alone pushes into every reader in the app, so a floor that
  # counts it is a floor met by the one module assertion 1 excludes.
  #
  # The pass reaches one of two numbers, and which one is not this file's
  # choice. `Kati.ScreenSweep.drawn_taps/1` memoises the mounted trees for the
  # whole run, so the trees are whatever the store held when the FIRST sweep to
  # ask mounted them: with titles on the shelf `Kati.Screens.Library` draws its
  # posters and the pass finds 83 doors over 18 readers; with none it draws
  # screen 27's `No titles yet` card and finds 73 over 16 — the moduledoc's
  # empty-shelf bullet, arriving as a number. Measured over six orderings on
  # 2026-09-05: those two, nothing between them, nothing below.
  #
  # So the floors sit just under the LOW one. They may only go up, and the
  # thing that would raise them honestly is the fixture that bullet says the
  # sweep is waiting on.
  #
  # 15 was also the old distinct floor, and it is not the same assertion: it
  # was met by `Kati.Screens.Gallery`'s twenty-one on its own, and it now has
  # to be met by the app.
  @doors_into_readers 70
  @readers_with_a_door 15

  # The board index is excluded from assertion 1, and structurally rather than
  # as twenty-one entries above.
  #
  # `Kati.Screens.Gallery` is a list of the 165 boards. It opens each screen in
  # the state its drawing was captured in, and it has no subject at all: there
  # is no meal it means, no book it means, no day it means. Twenty-one
  # identical entries would be twenty-one copies of that one sentence, and the
  # ratchet on them would be a ratchet on a screen that must never name
  # anything.
  #
  # `the gallery names nothing, which is why it is excluded` is what keeps the
  # exclusion honest: it asserts the claim over every push the gallery makes,
  # to a reader or not, rather than trusting it.
  @index Kati.Screens.Gallery

  # ── assertion 1: the ratchet ────────────────────────────────────────────────

  test "every drawn tap that opens a params reader names something for it" do
    unexpected = Enum.reject(bare_pushes(), &Enum.member?(@bare_pushes, &1))

    assert unexpected == [],
           "these controls open a screen that reads an argument and hand it none, so the " <>
             "screen falls back to whatever its no-argument path finds — the shelf's first " <>
             "row, the drawing, or the day the clock is on. Name the subject in the push, or " <>
             "add the tap to @bare_pushes with the reason its source has nothing to " <>
             "name:\n\n" <>
             Enum.map_join(unexpected, "\n", fn {module, tag, dest} ->
               "  #{inspect(module)} draws #{inspect(tag)} and pushes #{inspect(dest)}, " <>
                 "which reads #{inspect(readers()[dest])}"
             end)
  end

  test "the bare-push list has no stale entries" do
    stale = @bare_pushes -- bare_pushes()

    assert stale == [],
           "these pushes name something now. Delete them from @bare_pushes in " <>
             "#{Path.relative_to_cwd(__ENV__.file)} so the list keeps meaning what it " <>
             "says:\n" <>
             Enum.map_join(stale, "\n", fn entry -> "  #{inspect(entry)}" end)
  end

  test "every drawn tap that builds an argument builds one that is not empty" do
    unexpected = Enum.reject(empty_builder_pushes(), &Enum.member?(@empty_builders, &1))

    assert unexpected == [],
           "these controls hand their subject to the destination's own builder and the " <>
             "builder answered `%{}`, so the screen was opened with nothing after all. The " <>
             "door is written and the row it named has no id, which is NOT the defect " <>
             "assertion 1 is about and is not fixed in the push: either this screen's rows " <>
             "grew ids and the builder stopped seeing them — read `params_for/1` at the " <>
             "destination — or the screen is still drawing a fixture, in which case add the " <>
             "tap to @empty_builders and name the fixture:\n\n" <>
             Enum.map_join(unexpected, "\n", fn {module, tag, dest} ->
               "  #{inspect(module)} draws #{inspect(tag)} and pushes #{inspect(dest)}, " <>
                 "which reads #{inspect(readers()[dest])}"
             end)
  end

  test "the empty-builder list has no stale entries" do
    stale = @empty_builders -- empty_builder_pushes()

    assert stale == [],
           "these doors hand their reader something now, or stopped being drawn at all. " <>
             "Delete them " <>
             "from @empty_builders in #{Path.relative_to_cwd(__ENV__.file)} — a backlog is " <>
             "only worth keeping while every line on it is still true, and a line that has " <>
             "come good is the one thing this list wants to lose:\n" <>
             Enum.map_join(stale, "\n", fn entry -> "  #{inspect(entry)}" end)
  end

  test "the gallery names nothing, which is why it is excluded" do
    all = Enum.filter(pushes(), fn {module, _tag, _dest, _params} -> module == @index end)
    named = for {_module, tag, dest, params} <- all, params != %{}, do: {tag, dest, params}

    # Non-vacuous first: the exclusion means nothing if the gallery drew no
    # pushes at all in the pass — every screen in the app is one row of it.
    assert length(all) > 100,
           "the gallery pushed only #{length(all)} screens, so the claim below is being made " <>
             "over almost nothing and #{inspect(@index)} is excluded from assertion 1 for free"

    assert named == [],
           "#{inspect(@index)} is excluded from assertion 1 because it has no subject to " <>
             "name. It now names one, so the exclusion is hiding whatever the other rows do " <>
             "not name:\n" <>
             Enum.map_join(named, "\n", fn entry -> "  #{inspect(entry)}" end)
  end

  # ── assertion 2: the fallback lock ──────────────────────────────────────────

  # A value of the right type for every key in the app — they are all strings
  # or, for `:date`, something a `%Date{}` match refuses — and a row id no
  # store will ever hold.
  @nothing "no-such-row"

  test "an id that names no row renders exactly what naming nothing renders" do
    renders =
      in_empty_store(fn ->
        ScreenSweep.per_locale(@locales, fn locale ->
          for {module, keys} <- readers(),
              key <- keys,
              not Enum.member?(@carried_values, {module, key}) do
            {locale, module, key, render_with(module, %{key => @nothing}),
             render_with(module, %{})}
          end
        end)
      end)

    # Non-vacuity, and this assertion had none: the equality below is between
    # two answers from `render_with/2`, and one of the answers it can give is
    # `{:error, message}`. `Kati.ScreenSweep.safely/1` builds that message out
    # of `Exception.format_banner/2` and three arity-only stack frames
    # (`screen_sweep.exs:314-331`) — nothing in it depends on the params — so
    # two mounts that raise the SAME way compare equal and the pair passes with
    # nothing drawn on either side. That is a live way out of a failure here,
    # and it is cheaper than the fix: a reader that grows an `Ash.get!` over a
    # table this test has just emptied exempts itself and reads green. 44 pairs
    # render today and none raises.
    unrendered =
      for {locale, module, key, named, bare} <- renders,
          {:error, message} <- [named, bare] do
        "  (#{locale}) #{inspect(module)} with #{inspect(key)}: #{message}"
      end

    assert unrendered == [],
           "these screens did not render at all, so the comparison below is between two " <>
             "failures rather than between two pages and it cannot fail. Mounting a reader " <>
             "with an id that names nothing must draw the drawing, not raise:\n" <>
             Enum.join(Enum.uniq(unrendered), "\n")

    offenders =
      for {locale, module, key, named, bare} <- renders, named != bare, do: {locale, module, key}

    assert offenders == [],
           "these screens render one page for an id that names nothing and a different page " <>
             "for no id at all. An id whose row is gone must draw what a bare push draws — " <>
             "the drawing — and never substitute another row. The usual cause is a store " <>
             "read placed ahead of the params check in `load/1` or `mount/3`:\n" <>
             Enum.map_join(offenders, "\n", fn {locale, module, key} ->
               "  (#{locale}) #{inspect(module)} with #{inspect(key)}"
             end)
  end

  test "the carried-value list has no stale entries" do
    stale =
      in_empty_store(fn ->
        for {module, key} <- @carried_values,
            render_with(module, %{key => @nothing}) == render_with(module, %{}) do
          {module, key}
        end
      end)

    assert stale == [],
           "these keys no longer change what is drawn, so they are not carried values any " <>
             "more — either the screen stopped reading them, in which case the exemption is " <>
             "hiding that, or they became identity keys the assertion above should be " <>
             "covering. Delete them from @carried_values in " <>
             "#{Path.relative_to_cwd(__ENV__.file)}:\n" <>
             Enum.map_join(stale, "\n", fn entry -> "  #{inspect(entry)}" end)
  end

  # ── guard A: the derivation is not vacuous ──────────────────────────────────

  test "the derived readers are not vacuous" do
    readers = readers()

    for {module, key} <- @named_readers do
      keys = Map.get(readers, module)

      assert keys != nil,
             "#{inspect(module)} reads #{inspect(key)} and the scan no longer finds it, so " <>
               "every assertion in this file is now silently skipping it. See the moduledoc " <>
               "on the two reader shapes"

      assert key in keys,
             "#{inspect(module)} is still a reader but the scan lost #{inspect(key)} from " <>
               "its keys — it found #{inspect(keys)}. The fallback lock is not being checked " <>
               "for that key any more"
    end

    assert map_size(readers) >= @derived_readers,
           "the scan found #{map_size(readers)} readers where the derivation found " <>
             "#{@derived_readers} the day that number was written down, so it has stopped " <>
             "seeing #{@derived_readers - map_size(readers)} of them and every assertion in " <>
             "this file is now silently skipping those screens. The usual cause is a screen " <>
             "respelling its read — a renamed `mount/3` argument, `params[:id]`, a pattern " <>
             "match in the head — none of which changes behaviour. See the moduledoc on the " <>
             "two reader shapes, and lower @derived_readers only beside the reason a screen " <>
             "genuinely stopped reading its params"

    empty = for {module, []} <- readers, do: module

    assert empty == [],
           "these screens read `params` and the key scan came back with nothing, so the " <>
             "fallback lock passes over them without checking anything. " <>
             "`Kati.Screens.Season` was exactly this — it rebinds `asked = params || %{}` " <>
             "and the scan did not follow it:\n" <>
             Enum.map_join(empty, "\n", &"  #{inspect(&1)}")
  end

  test "a screen that says params in code is a reader or is written down" do
    named = MapSet.new(Map.keys(readers()) ++ @not_readers)

    unclassified =
      for module <- ScreenSweep.screens(),
          not MapSet.member?(named, module),
          code = strip_prose(File.read!(source_path(module))),
          code =~ ~r/\bparams\b/,
          do: module

    assert unclassified == [],
           "these screens name `params` in code and `reader?/1` does not count them, so the " <>
             "fallback lock is not checking them and `@derived_readers` cannot notice. Either " <>
             "widen `reader?/1` to the spelling they use — which is the usual answer, since " <>
             "the two it knows are the two the app happened to write first — or add each to " <>
             "`@not_readers` with a sentence saying what it means by the word:\n" <>
             Enum.map_join(unclassified, "\n", &"  #{inspect(&1)}")
  end

  test "the tap pass reaches enough pushes for assertion 1 to mean anything" do
    # The mirror of the guard above, on the other half of the derivation. Every
    # push is dispatched through `handle_info/2`, and a change to Mob's nav
    # shape — or a pass that rendered no screens — would turn assertion 1 into
    # a clean run over an empty list rather than a failure.
    #
    # Built WITHOUT `@index`, which is the whole difference between a guard and
    # a tautology. `Kati.Screens.Gallery` is a row per board and opens every
    # screen in the app, so it alone pushes into all twenty-one readers: it
    # supplied twenty-one of the doors this used to count and EVERY one of the
    # distinct destinations, which left both floors met by the one module
    # assertion 1 excludes. Every other screen in the app could have stopped
    # drawing taps entirely and this still passed.
    into_readers =
      for {module, _tag, dest, _params} <- pushes(),
          module != @index,
          Map.has_key?(readers(), dest),
          do: dest

    assert length(into_readers) >= @doors_into_readers,
           "the app's own screens push into a params reader only " <>
             "#{length(into_readers)} times, where #{@doors_into_readers} is the floor and " <>
             "73 is the fewest they reached when it was set. Assertion 1 is checking less " <>
             "of the app than it was written to check — a screen has stopped drawing its " <>
             "rows, or the pass stopped reaching them"

    assert length(Enum.uniq(into_readers)) >= @readers_with_a_door,
           "the app's own pushes reach only #{length(Enum.uniq(into_readers))} distinct " <>
             "readers, where #{@readers_with_a_door} is the floor and 16 of the " <>
             "#{@derived_readers} readers had a door on the leanest ordering when it was " <>
             "set. A reader with no door pointed at it is a screen assertion 1 cannot say " <>
             "anything about"
  end

  # ── guard B: a date-keyed screen draws its day ──────────────────────────────

  test "a screen that takes a date draws the day it was handed" do
    # Free of fixtures: an empty Monday and an empty Tuesday still differ by
    # their heading. Both dates are far from today deliberately —
    # `Kati.Screens.Day.day/1` and `Kati.Screens.MealsDay.day/1` both answer
    # TODAY with the drawing when the store is empty, and two dates that both
    # landed on that branch would agree for a reason that has nothing to do
    # with whether the screen draws its argument.
    one = Date.add(Kati.Time.today(), 40)
    two = Date.add(Kati.Time.today(), 41)

    dated = for {module, keys} <- readers(), :date in keys, do: module

    assert dated != [],
           "no screen reads a `:date` any more, so this guard is checking nothing"

    ignored =
      in_empty_store(fn ->
        for module <- dated,
            render_with(module, %{date: one}) == render_with(module, %{date: two}),
            do: module
      end)

    assert ignored == [],
           "these screens accept a `:date` and draw the same page for #{one} and #{two}, so " <>
             "the date is assigned and never read. A page whose heading cannot be wrong " <>
             "because it is never right is the defect `Kati.Screens.MealsDay`'s moduledoc " <>
             "describes:\n" <> Enum.map_join(ignored, "\n", &"  #{inspect(&1)}")
  end

  # ── readers, from source ────────────────────────────────────────────────────

  # `%{module => [key]}` for every screen that reads the push's params, and the
  # keys it reads. See the moduledoc for why this is source and not
  # `function_exported?(dest, :params_for, 1)`.
  defp readers do
    memo(:readers, fn ->
      for module <- ScreenSweep.screens(),
          source = File.read!(source_path(module)),
          reader?(source),
          into: %{},
          do: {module, reader_keys(source)}
    end)
  end

  # The two shapes. `Kati.Screens.Pushed`'s generated mount assigns the push's
  # params to `:params` (`pushed.ex:56-58`), so a screen built on that macro
  # reads them off the socket; a hand-rolled `use Mob.Screen` screen writes its
  # own `mount/3` and reads the argument directly.
  defp reader?(source) do
    source =~ ~r/socket\.assigns\.params/ or
      (source =~ ~r/^  def mount\(params,/m and source =~ ~r/Map\.get\(\s*params/)
  end

  # Every `:key` the file takes out of the params map, following one rebinding
  # of it — `asked = params || %{}`, which is what `Kati.Screens.Season` does
  # and what the first version of this scan missed entirely.
  defp reader_keys(source) do
    source
    |> key_pattern()
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&String.to_atom/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp key_pattern(source) do
    aliases =
      ~r/^\s*([a-z_][a-zA-Z0-9_]*)\s*=\s*params\b/m
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()

    names =
      (["socket.assigns.params", "params"] ++ aliases)
      |> Enum.uniq()
      |> Enum.map_join("|", &Regex.escape/1)

    Regex.compile!("Map\\.get\\(\\s*(?:#{names})\\s*(?:\\|\\|\\s*%\\{\\}\\s*)?,\\s*:([a-z_]+)")
  end

  # Comments, `@doc` and `@moduledoc` removed. The word this file asks about
  # appears in the prose of nearly every screen that has nothing to do with it.
  defp strip_prose(source) do
    source
    |> String.replace(~r/@(?:module)?doc\s+"""(?:.|\n)*?"""/, "")
    |> String.replace(~r/^\s*#.*$/m, "")
  end

  defp source_path(module) do
    file = module |> Module.split() |> List.last() |> Macro.underscore()
    path = Path.expand("../../lib/kati/screens/#{file}.ex", __DIR__)

    assert File.exists?(path), "no source for #{inspect(module)} at #{path}"
    path
  end

  # ── pushes, from the runtime ────────────────────────────────────────────────

  # `{screen, tag, destination, params}` for every tap in every locale that
  # asked to push, dispatched exactly the way a device dispatches it.
  #
  # Through `Kati.ScreenSweep.rolled_back/1` because this presses every control
  # every screen draws, and a few of them commit: screen 106's `Save goal`,
  # 111's `Save reading`, 124's `Save the expense` each write a row and mean to.
  # Left behind, those rows stop screens 104, 109, 111 and 122 falling back to
  # their drawings, and the failure lands on a file this one never touched.
  #
  # **One rollback per tap, not one around the sweep**, and the difference is
  # what this file measures. A door is classified by what its handler builds,
  # and several handlers resolve their row by READING the store at tap time
  # rather than off the tree the page drew — `Kati.Screens.ArtistDetail`'s
  # discography rail is one, `artist_detail.ex:842-853`. Under a single outer
  # transaction, screen 179's `add_<title>` discs shelve `Tidal Works` early in
  # the sweep and that rail then finds a row with a real id later in the same
  # sweep, so one fixture door was empty or full depending on which order the
  # two screens came out of a map. Rolling back around each dispatch judges
  # every door against the same store, which is the only way the two
  # inventories below mean anything.
  #
  # NOT through `in_empty_store/1`, though the numbers below would be steadier
  # for it. `Kati.ScreenSweep.drawn_taps/1` memoises the mounted trees in
  # `:persistent_term` for the whole run (`screen_sweep.exs:361-379`), so
  # whichever sweep asks first is the one that decides what every other sweep
  # sees. Emptying the store here would hand `Kati.ScreenTapSweepTest` and
  # `Kati.AppReachabilityTest` trees drawn against a store they did not choose,
  # on the orderings where this file happens to run first — a flake moved into
  # someone else's file rather than fixed. What that memo costs THIS file is
  # written beside the floors above.
  defp pushes do
    memo(:pushes, fn ->
      @locales
      |> ScreenSweep.per_locale(fn locale ->
        for {module, {socket, tags}} <- ScreenSweep.drawn_taps(locale),
            tag <- tags,
            {:push, dest, params} <- [nav_action(module, socket, tag)],
            is_atom(dest) do
          {module, tag, dest, params}
        end
      end)
      |> Enum.uniq()
      |> Enum.sort()
    end)
  end

  defp nav_action(module, socket, tag) do
    dispatched =
      ScreenSweep.rolled_back(fn ->
        ScreenSweep.safely(fn -> module.handle_info({:tap, tag}, socket) end)
      end)

    case dispatched do
      {:ok, {:noreply, %Mob.Socket{} = updated}} -> Map.get(updated.__mob__, :nav_action)
      _unreached -> nil
    end
  end

  # `{screen, tag, destination}` for every drawn tap that opens a params reader
  # with nothing in hand — the runtime finding whole, before it is sorted.
  #
  # 55 of them today. Neither list below is allowed to drop one: the two
  # partition this, so a door can move between them and can never leave both.
  defp runtime_bare_pushes do
    for {module, tag, dest, params} <- pushes(),
        module != @index,
        params == %{},
        Map.has_key?(readers(), dest) do
      {module, tag, dest}
    end
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Nobody wrote the argument: the clause that answers the tag pushes the
  # destination with two arguments and never three. `@bare_pushes` is this.
  defp bare_pushes do
    Enum.filter(runtime_bare_pushes(), fn {module, tag, dest} ->
      bare_in_source?(module, tag, dest)
    end)
  end

  # The argument was written and came out empty: the clause names its subject
  # and the destination's `params_for/1` answered `%{}` over a row with no id.
  # `@empty_builders` is this, and it is the backlog. See the moduledoc.
  defp empty_builder_pushes do
    Enum.reject(runtime_bare_pushes(), fn {module, tag, dest} ->
      bare_in_source?(module, tag, dest)
    end)
  end

  # Whether the code that answers `tag` pushes `dest` without params — which
  # SORTS a runtime-bare door between the two inventories and never removes it
  # from both. A `false` here means the argument is written and empty, not that
  # the door is fine.
  #
  # The clause is found by looking for the tag's own atom in a `def` head, which
  # is how every hand-written tap clause in the app is spelled
  # (`def handle_tap(:rate, socket)`, `def handle_info({:tap, :back}, socket)`).
  # A tag built at render time appears in no head, and for those the question
  # falls back to the module as a whole — see the moduledoc for what that costs.
  defp bare_in_source?(module, tag, dest) do
    to_dest = Enum.filter(push_sites(module), fn {_head, pushed, _arity} -> pushed == dest end)
    named = Enum.filter(to_dest, fn {head, _pushed, _arity} -> tag in head end)
    sites = if named == [], do: to_dest, else: named

    not Enum.any?(sites, fn {_head, _pushed, arity} -> arity == 3 end)
  end

  # `{atoms in the def's head, destination, arity}` for every `push_screen`
  # call in the module's source.
  #
  # Read off the parsed source rather than matched with a regex: the call is
  # written four ways in `lib/kati/screens` — qualified, piped, on one line and
  # spread over five — and a regex that reads three of them reports the fourth
  # as naming nothing. Pipes are rewritten into ordinary calls first, so
  # `socket |> Mob.Socket.push_screen(Dest)` counts its two arguments.
  defp push_sites(module) do
    memo({:push_sites, module}, fn ->
      module
      |> source_path()
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.prewalk(fn
        {:|>, _meta, [left, right]} -> unpipe(left, right)
        other -> other
      end)
      |> collect_defs()
    end)
  end

  # `Macro.pipe/3` refuses to rewrite a pipe into something that is not a call
  # — `|> case do`, a capture — and there is no such pipe in front of a
  # `push_screen` anywhere. Left as it was rather than raised over, so a screen
  # that grows one somewhere else in its file does not take this sweep down
  # with a message about a line that has nothing to do with a push.
  defp unpipe(left, right) do
    Macro.pipe(left, right, 0)
  rescue
    ArgumentError -> right
  end

  defp collect_defs(ast) do
    {_ast, sites} =
      Macro.prewalk(ast, [], fn
        {kind, _meta, [head, body]} = node, acc when kind in [:def, :defp] ->
          atoms = atoms_in(head)
          {node, Enum.map(push_calls(body), fn {dest, arity} -> {atoms, dest, arity} end) ++ acc}

        node, acc ->
          {node, acc}
      end)

    sites
  end

  defp push_calls(ast) do
    {_ast, calls} =
      Macro.prewalk(ast, [], fn node, acc ->
        case push_call(node) do
          nil -> {node, acc}
          call -> {node, [call | acc]}
        end
      end)

    calls
  end

  defp push_call({{:., _meta, [_module, :push_screen]}, _call, args}), do: destination(args)
  defp push_call({:push_screen, _meta, args}) when is_list(args), do: destination(args)
  defp push_call(_node), do: nil

  # `push_screen(socket, Kati.Screens.Thing)` and its three-argument form. A
  # destination held in a variable — `Kati.Screens.Calendar.pick/2` and the
  # gallery's own row loop — answers `nil` and is not a site: which screen it
  # opens is not knowable here, and the runtime half already knows.
  defp destination([_socket, {:__aliases__, _meta, parts} | rest]),
    do: {Module.concat(parts), 2 + length(rest)}

  defp destination(_args), do: nil

  defp atoms_in(term) when is_atom(term), do: [term]
  defp atoms_in(term) when is_list(term), do: Enum.flat_map(term, &atoms_in/1)

  defp atoms_in(term) when is_tuple(term),
    do: term |> Tuple.to_list() |> Enum.flat_map(&atoms_in/1)

  defp atoms_in(_term), do: []

  # ── mounting with other params, and an empty store to do it in ──────────────

  # `Kati.ScreenSweep.mount/1` mounts a screen as a bare push. This is the same
  # call with the push naming something, which is the whole hook this file
  # needs.
  defp render_with(module, params) do
    with {:ok, {:ok, %Mob.Socket{} = socket}} <-
           ScreenSweep.safely(fn -> module.mount(params, %{}, Mob.Socket.new(module)) end),
         {:ok, tree} <- ScreenSweep.safely(fn -> module.render(socket.assigns) end) do
      {:ok, tree}
    else
      {:ok, other} -> {:error, "mount/3 returned #{inspect(other, limit: 3)}"}
      {:error, message} -> {:error, message}
    end
  end

  # Run `fun` against a store with nothing in it, and put back everything it
  # emptied.
  #
  # Assertion 2 asks what a screen draws when the id it was handed names no
  # row, and the comparison is only meaningful when NO id names a row: with one
  # title on the shelf, `Kati.Screens.Season` answers a bare mount with the
  # newest series and a bogus one with the drawing, which differ for a reason
  # that is correct.
  #
  # The tables are read out of the database rather than written down here.
  # `Kati.ScreenEmptyDatabaseTest` keeps a list of thirty-five names because it
  # is also asserting things about that list; this file is not, and a second
  # copy of it would be a second thing to forget to add a table to. Foreign keys
  # are deferred to the end of the transaction so the order `sqlite_master`
  # happens to return does not have to be a dependency order — and the
  # transaction is rolled back, so the end never comes.
  defp in_empty_store(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Kati.Repo.query!("PRAGMA defer_foreign_keys = ON", [])
        Enum.each(app_tables(), &Kati.Repo.query!("DELETE FROM " <> &1, []))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  # Ecto's own ledger and the table Mob keeps screen state in are not the app's
  # data and emptying them would be emptying the harness.
  @not_data ~w(schema_migrations mob_screen_states)

  defp app_tables do
    %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'", [])

    for [name] <- rows,
        name not in @not_data,
        not String.starts_with?(name, "sqlite_"),
        do: name
  end

  # `:persistent_term` for the reason `Kati.ScreenSweep.drawn_taps/1` gives:
  # each ExUnit test runs in its own process and `Mob.ScreenCase` restarts
  # `Mob.State` around each one, so a cache in the process dictionary or in ETS
  # dies between the tests that share the work. Only plain data is stored, and
  # all of it depends on code alone.
  defp memo(key, fun) do
    key = {__MODULE__, key}

    case :persistent_term.get(key, :miss) do
      :miss ->
        value = fun.()
        :persistent_term.put(key, value)
        value

      value ->
        value
    end
  end
end
