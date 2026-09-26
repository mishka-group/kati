Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.TapSweepProbe do
  @moduledoc """
  Two throwaway screens that define no tap handler of their own.

  They exist so `Kati.ScreenTapSweepTest` can assert what the two shell macros
  *do not* supply. Not under `Kati.Screens.*`, so `Kati.ScreenSweep.screens/0`
  never picks them up.
  """

  defmodule BareRoot do
    @moduledoc false
    use Kati.Screens.Root, root: :home

    @doc false
    def content(_assigns), do: ~MOB"<Box fill_width={true} />"
  end

  defmodule BarePushed do
    @moduledoc false
    use Kati.Screens.Pushed, back: "Home"

    @doc false
    def content(_assigns), do: ~MOB"<Box fill_width={true} />"
  end
end

defmodule Kati.ScreenTapSweepTest do
  @moduledoc """
  Taps every control every screen draws, and fails when one is dead.

  ## The defect this exists for

  A control is wired in two halves that the compiler never introduces to each
  other: the `~MOB` template picks a tag (`on_tap={{self(), :new_habit}}`) and
  a callback somewhere else matches it. Nothing checks that the second half
  exists. A screen using `Kati.Screens.Pushed` declares
  `@behaviour Kati.Screens.Root`, whose `handle_tap/2` is an *optional*
  callback, so omitting it is not even a warning — and
  `Kati.Screens.Root.rescue_tap/3` deliberately survives the omission so a
  mistyped tag cannot kill the screen a user is looking at. The result is a
  button that does nothing, a green build, and a screenshot that looks correct
  because the resting appearance is correct.

  ## The two ways to get this sweep wrong

  Both produced confident, wrong clean runs before this file existed:

    * **Assuming every screen has `handle_tap/2`.** Roughly a third of Kati's
      screens are hand-rolled `use Mob.Screen` — `Kati.Screens.Search`,
      `Kati.Screens.Meal`, the Persian mirrors — and match taps in
      `handle_info/2` with no `handle_tap/2` at all. Calling `handle_tap/2` on
      those reports ~20 failures that are not defects.

    * **Reading the behaviour list with `attributes[:behaviour]`.**
      `:attributes` is a keyword list with repeated keys, so that returns only
      the first, which is always `Mob.Screen` — every macro-built screen gets
      classified as hand-rolled and the check that matters never runs. See
      `Kati.ScreenSweep.behaviours/1`.

  So each tag is dispatched down the path its own screen actually uses,
  decided by `Kati.ScreenSweep.root_behaviour?/1`.

  ## What is checked, and how hard

  `handle_tap/2 answers every tag its screen draws` is the exact one, and it
  runs **around** `rescue_tap/3` rather than through it, so it holds whatever
  that function decides to survive. It catches both shapes of missing handler:
  no `handle_tap/2` at all is an `UndefinedFunctionError`, and a `handle_tap/2`
  whose clauses miss this one tag is a `FunctionClauseError` — as long as the
  screen has no `_tag` catch-all. A catch-all is a real hole in the coverage
  and `no new dead-looking taps` is the (weaker, heuristic) net under it.
  """
  use Mob.ScreenCase, async: false

  # THIS SWEEP WRITES, AND MUST NOT LEAVE ANYTHING BEHIND.
  #
  # It dispatches every tag every screen draws, and some of those tags are
  # commits: screens 106, 111 and 124 each create a row and mean to. Left
  # behind, those rows stop screens 104, 109, 111 and 122 falling back to their
  # drawings, and the failure surfaces on `Kati.ScreenDesignLiteralTest` — a
  # file this one never touched — for the seeds that order them the wrong way
  # round.
  #
  # `Kati.ScreenSweep.rolled_back/1` explains it in full and is what the other
  # two tap-dispatching sweeps go through. This one deletes instead, because
  # its dispatch is spread across several tests rather than gathered into one
  # function call — the tables named explicitly, and the list grows the day a
  # new sheet starts committing.
  #
  # ## The day it grew, and how it was found
  #
  # `tracked_titles` and `cached_titles` are here because #87 gave
  # `Kati.Screens.AddTitle` a real write, and this sweep taps every `add_<title>`
  # control that screen draws: three rows in each table, `Kati.Library.Sample`'s
  # own titles, left behind on every run since. The list did not grow with the
  # write, which is the failure mode the paragraph above predicts word for word.
  #
  # It cost nothing until the module count changed. `Kati.ServicesTest` asserts
  # `Kati.Screens.DataSources.cache_size/0` reads "Nothing cached yet", which is
  # `Ash.count(CachedTitle) == 0` and nothing else, and it wipes no tables of its
  # own — so it passes or fails purely on where the seed drops it relative to
  # this file. Adding one test module reshuffles that, and #88's did: seed 7 went
  # green before it and red after, on a leak neither file had anything to do
  # with. Measured by counting `cached_titles` after every module.
  #
  # Watches are deliberately NOT in the list. This sweep creates none — screen
  # 33's Save can only UPDATE, and on the empty database the sweep sees it
  # refuses outright — so a `media_watches` row present here would be somebody
  # else's leak, and a blanket DELETE would tidy away the evidence of it. SQLite
  # enforces the foreign key, so it would announce itself rather than pass
  # quietly: this callback raises on the `tracked_titles` delete.
  setup do
    on_exit(fn ->
      # `health_doses` before `health_medications`: a dose `belongs_to` its
      # medication with `allow_nil? false`, so the child table goes first or
      # SQLite refuses the parent delete. Both joined the list when screen 188
      # gave this app its first way to create a medication — the sweep taps
      # `Save` on every sheet, and that sheet's draft has a name in it, so a
      # row lands exactly as screen 106's `New goal` lands one in `goals`.
      #
      # `music_tracks`, `music_albums` and `music_artists` joined on
      # 5 September with `D-39`: screens 178 and 179 are the first writers the
      # music domain has ever had, and this sweep presses every `add_<title>`
      # disc screen 179 draws. Left behind, those rows stop
      # `Kati.Screens.Music.page/0` falling back to `Kati.Music.Sample`, and the
      # failure surfaces on `Kati.ScreenDesignLiteralTest`'s board 21 — a file
      # this one never touched — for the seeds that order them the wrong way
      # round. That is the paragraph above happening again, so the list grew
      # with the write rather than after it.
      #
      # Child first here too: `music_tracks` and `music_listens` both reference
      # `music_albums`, which references `music_artists`.
      #
      # `music_listens` was left out on the argument `media_watches` is left
      # out on — *this sweep creates none, so a listen here is somebody else's
      # leak and the foreign key should announce it.* The foreign key
      # immediately did, and the argument was wrong on the very run that made
      # it: screen 111's `Save reading` refuses on an empty shelf, and the
      # shelf is no longer empty by the time the sweep reaches it, because
      # screen 179's `add_<title>` discs shelved albums earlier in the same
      # sweep. A screen that no-ops against an empty table stops no-opping the
      # moment another screen in the sweep can fill that table, so the two
      # arguments are not the same argument: `media_watches` has no writer in
      # this sweep at all, and `music_listens` now has one at one remove.
      for table <-
            ~w(goals expenses health_readings health_doses health_medications tracked_titles cached_titles music_tracks music_listens music_albums music_artists) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    :ok
  end

  alias Kati.ScreenSweep
  alias Kati.TapSweepProbe.BarePushed
  alias Kati.TapSweepProbe.BareRoot

  @locales [:en, :fa]

  # Tags whose non-ASCII comes from a ROW and not from a label — see the test
  # that reads this. `Kati.Library.Sample.titles/0` is nine titles with no id,
  # so `Kati.Screens.Library.poster_tag/1` falls back to the caption for every
  # one — and since mishka-group/kati#103 folded board 57's mirror away, the
  # caption is Persian when the reader is. The mirror's own six are gone with
  # it; these are the same shelf read in the other script.
  @from_the_data [
    {Kati.Screens.Library, :open_series_بارش_خاکستر},
    {Kati.Screens.Library, :open_film_بندر_آرام},
    {Kati.Screens.Library, :open_film_ساعت_آبی},
    {Kati.Screens.Library, :open_series_نمک_و_آهن},
    {Kati.Screens.Library, :open_film_پرندگان_شب},
    {Kati.Screens.Library, :open_series_گودال_بلند},
    {Kati.Screens.Library, :open_series_مارام},
    {Kati.Screens.Library, :open_film_ولوم},
    {Kati.Screens.Library, :"open_series_نقشه‌کش"}
  ]

  # The remaining design- and capability-blocked groups are written up in
  # `design-briefs/D-62-the-controls-that-name-a-place-with-nothing-behind-it.md`
  # — seven service rows with no page to open, four chevrons on a book pointing
  # at two screens nobody drew, screen 43's *Done prepping* and its five
  # neighbours waiting on an answer to *what does done mean*, and *Save image*
  # waiting on a fence that turns a composable into a bitmap. Filed rather than
  # fixed, because each needs a drawing that does not exist or a decision about
  # what the app means, and inventing either in a screen file is the one thing
  # this pipeline does not allow.
  #
  # Every tap this sweep knows to be dead right now. Each entry is a screen
  # that draws a control and cannot answer it, kept so the sweep fails on a
  # NEW one instead of failing on the backlog. Delete an entry when you wire
  # the tag — `the dead-tap allow-list has no stale entries` fails if you
  # leave it behind.
  #
  # Empty, and worth keeping that way. Its first population was screens
  # 16/17/30 — `Kati.Screens.Agenda`, `Kati.Screens.MonthGrid` and
  # `Kati.Screens.Week` each drew `Kati.Screens.ViewSwitcher`'s
  # Day/Week/Month/Agenda strip and defined no `handle_tap/2` at all, so the
  # switcher was decoration on all three calendar views. Found by this sweep,
  # fixed by the one-line delegation `Kati.Screens.ViewSwitcher`'s moduledoc
  # prescribes, and removed from here because `the dead-tap allow-list has no
  # stale entries` requires it.
  @dead_taps []

  # Taps that reach a handler and change nothing, as of 2026-08-20. See `no new
  # dead-looking taps` for what this list is and, more importantly, what it is
  # not. Two groups, and the difference matters when you read a name here.
  # The screens that still give one name to more than one node, with the tags
  # they repeat. `Mob.Renderer` derives an `accessibility_id` from every atom
  # `on_tap`, so a tag drawn twice is an id drawn twice, and
  # `onNodeWithTag` throws on the second match rather than picking one. Every
  # entry here is a control no device test can address.
  #
  # ## Why a list and not twenty-two fixes
  #
  # The check above was blind from the day it was written, so this is not new
  # breakage — it is breakage that was always there and could not be seen. The
  # honest move on finding twenty-four of them was to make them visible and fix
  # the ones on the journey this ticket had to test, rather than to redraw
  # twenty-four screens' tags in the same commit and verify none of it.
  #
  # 43 and 118 are absent because they were fixed: `Kati.Screens.MealsToday`
  # names each card after its slot AND its clock — two `Snack` rows in one day
  # made the slot alone collide, which this check caught — and
  # `Kati.Screens.MealEdit` names each line after its ingredient. Those two are
  # the meals journey's own doors, so they are the ones #95 had to open; the
  # device test that walks through them still needs a meal to attach an
  # ingredient to, which is #91's work, not this ticket's.
  #
  # The shape of the fix is the same every time and is written down in
  # `Kati.Screens.MealsToday.meal_tag/1`: give the repeated control the identity
  # of the row it belongs to. `Kati.Screens.ImportSources.tag/1` and
  # `Kati.Screens.AddIngredient`'s aisle chips are the same pattern.
  #
  # 03 is off the list as of #91, and NOT by the fix above — its two tags are
  # still one name over every poster in a full grid. This sweep renders against
  # the empty store (see `setup`), and `Kati.Screens.Library` no longer answers
  # an empty shelf with `Kati.Library.Sample`'s nine films: it draws screen
  # 27's `No titles yet` card, which has no grid and therefore no repeated tag.
  # The debt is unpaid and has moved out of this sweep's reach; it comes back
  # the day a device test puts two titles on the shelf, and the fix is still
  # `meal_tag/1`'s.
  #
  # 02 is off the list as of #91, and unlike 03 it is off for good rather than
  # out of reach. `row_event` was the BARE tag — `Kati.Screens.Calendar.tag/1`'s
  # no-id branch — and only `drawn_rows/0` ever produced one: two of the
  # drawing's five cards are `kind: "event"` with no stored event to name, so
  # one page carried the name twice. Nothing renders `drawn_rows/0` any more,
  # and every row the timeline draws now comes from `Kati.Calendars.Today` and
  # carries its event's own id, so a second `row_event` cannot be minted on a
  # full shelf either. `Kati.ScreenCalendarEmptyStateTest` asserts the tag is
  # absent, which is the claim that keeps this struck off.
  #
  # 28's `inbox` and 55's `open_inbox` came off this map when the two Home
  # mirrors stopped fabricating their spine, and they came off WITHOUT being
  # fixed. This sweep renders against the empty store, and each page's `New
  # this week` hero — which carried the second copy of the tag, the first being
  # the notification disc in the header — is omitted when there is nothing to
  # announce. On that branch 28 draws board 315's page and 55 draws 158's, and
  # neither of those headers has a bell in it at all. So the debt moved out of
  # this sweep's reach rather than being paid, and this note said so.
  #
  # It is paid now, and by the split this note prescribed: the bell is
  # `:notifications` on 01, 28 and 55 alike and opens
  # `Kati.Screens.InboxNotifications`, which is what screen 01's bell has
  # always opened; the hero's button is `:open_inbox` and means *the release
  # inbox*. Because this sweep still cannot see the branch that draws both,
  # the claim is held where the fixture can exist —
  # `Kati.ScreenDarkWidgetsTest` and `Kati.ScreenHomePersianEmptyStateTest` each
  # write a tracked title and an aired episode, then assert no tag repeats.
  #
  # This list may only SHRINK. The test enforces both directions — a new
  # collision fails it, and so does an entry here that no longer collides.
  # Empty, and the ratchet is what keeps it that way: a new collision fails
  # `no two nodes in one screen carry the same accessibility_id`, and an entry
  # that no longer collides fails it too, so this map cannot rot in either
  # direction.
  #
  # It held twenty-four when #97 opened and nineteen when the last of them was
  # picked up. Screen 03 is the one to read about before adding an entry here
  # rather than a fix: it left this map early, on the grounds that the sweep
  # saw no collision — and the sweep saw none because the shelf is empty in
  # every test, so the grid had no tiles to collide. `Kati.Screens.Library`
  # then carried one tag per KIND on a real phone's shelf for as long as it
  # took someone to look. An empty register is evidence of nothing on its own;
  # what it means is that every screen with two of a kind on it has been drawn
  # with two of a kind on it.
  @known_collisions %{}

  @inert_taps [
    # ── Correct. The selected member of a family of controls: the filter that
    # is already showing, the shelf you are already on. Tapping it sets the
    # value it already has, so nothing changes and this heuristic cannot tell
    # it from a dead control. Each was confirmed by its siblings: every OTHER
    # tag in the same family does change the screen, so the family is wired and
    # only its current member looks inert.
    # ── Wired, but the change lives outside the socket. This heuristic
    # compares assigns and nav action; `Kati.Locale.put/1` writes `Mob.State`,
    # which is neither. `choose_en` is additionally the already-selected
    # member of its family. Both are covered properly by
    # `Kati.ScreenLanguagePickTest`, which asserts the locale actually moves
    # and the tick follows it.
    # Screen 154's two resting choices. Board 155 states the default in as many
    # words — "Resting — empty, Film, nothing assumed" — and Not started is the
    # status a title you are adding has — so each is the already-selected member of its family, which
    # is the first group above. `kind_movie` and the other two statuses all move
    # the assign, which is what says the family is wired.
    {Kati.Screens.AddByHand, :kind_movie},
    # 157 is 154 in the dark colourway and opens in the same resting state, so
    # its Film chip is the already-selected member of the same family. It was
    # not here before because 157 opened on `:tv` — board 157's captured
    # frame, loaded rather than drawn, which is what let *Add to library*
    # write The Long Hollow into a real library.
    {Kati.Screens.AddByHandDark, :kind_movie},
    # Steps 4 and 5's resting choices — the loudness the board opens on and the
    # title it opens with picked. Every other choice in each family moves the
    # assign, which is what says the family is wired.
    # Screen 19's clear disc, on a page the sweep opens with nothing typed.
    # Clearing an empty field is correctly a no-op; the sweep reaches 19
    # without a query because 86 is what hands it one, and there is no board
    # that draws 19 mid-query AND its clear having been pressed.
    # Screen 36's threshold, on a host with no bridge. It is wired now:
    # *Tick at* steps the threshold `Kati.Media.Detect.threshold/0`
    # reads. It cannot change anything here — `Mob.State` is not running in
    # this sweep, so the write is rescued into a no-op — and it is pressed over
    # a real preference store in `Kati.MediaDetectTest`. (*This phone*, the
    # permission row beside it, pushes screen 151 and so is not inert.)
    {Kati.Screens.AutoDetect, :cycle_threshold},
    # Screen 13's own selected window, for screen 36's reason one line up. The
    # board is drawn at `45m` and this sweep renders it, so pressing `45m`
    # re-reads the same window and answers the same page. The other four move
    # it, and are swept. `Kati.ScreenWhatFitsTest` presses all five over a real
    # shelf, where the list under them actually changes.
    {Kati.Screens.WhatFits, :window_45m},
    # Screen 18's own lit chip, for screen 36's reason one line up. *Or file it
    # as* is a choice of one, and `Event` is what a bare sentence is already
    # filed as, so pressing it sets `:filed_as` to what it already holds. The
    # other five move the screen — four set a different
    # `Kati.Calendars.Event.kind`, Title opens screen 06 — and are swept.
    {Kati.Screens.QuickAdd, :file_as_event},
    # Screen 43's **Mark eaten** on the DRAWN day, which is the only day the
    # sweep sees. With a plan in the store the tag carries the slot's id and
    # writes a `Kati.Meals.MealLog` — `Kati.MealsTodayWriteTest` asserts that
    # against real rows. `Kati.Meals.SampleToday` is a transcription of board
    # 43 rather than rows, so its meals have no slot to log against and
    # `Kati.Screens.MealsToday.tag/2` hands back the bare tag rather than one
    # ending in `_nil`. A button that wrote a log for a meal nobody planned
    # would be inventing the row it then displayed.
    # Screen 46's two commitments, on the drawn page — which is the only page
    # this sweep sees. With a slot handed over by screen 43 they write:
    # **Swap just today** logs the candidate as `:planned` and **Every week**
    # moves the slot onto it, and `Kati.MealSwapTest` asserts both against real
    # rows, including that neither does the other's job. Reached from the
    # gallery there is no slot, so the page is `Kati.Meals.SampleSwap`'s
    # drawing and committing would be committing a swap of nothing.
    # Screen 45's bookmark disc, on the drawn page. With a plan there is a
    # recipe and the disc toggles `Kati.Meals.Recipe.bookmarked` —
    # `Kati.MealSwapTest` asserts it both ways round. `Kati.Meals.SampleRecipe`
    # is a transcription of board 45 rather than a row, so there is nothing to
    # bookmark and the tap changes nothing rather than inventing the recipe it
    # would have to write against.
    {Kati.Screens.Meal, :save},
    {Kati.Screens.MealSwap, :swap_once},
    {Kati.Screens.MealSwap, :swap_forever},
    {Kati.Screens.MealsToday, :mark_eaten},
    # (The comment that stood here described screen 05's **Mark all** as having
    # joined this group "the round it was wired", and the audit
    # pointed out that it was orphaned: the control had no tap at all, so the
    # entry it described had been struck as a phantom and the sentence outlived
    # it. #82 wired all three of screen 05's controls on 7 September, and the
    # sentence is true now and belongs to none of them — a control drawn
    # without a tap over an empty list is not a tag this sweep can see.
    # `Kati.ScreenInboxTest` presses them over real rows.)
    #
    # Screen 19's clear disc. This entry outlived its own reason too: #94 found
    # the control HALF working on the device — the counts went to zero and the
    # typed word stayed in the field — and it is fixed. It stays here for the
    # reason it was first written, which is about the SWEEP and not the screen:
    # 19 is reached with an empty field, 86 is what hands it a query, and
    # clearing an empty field is correctly a no-op.
    {Kati.Screens.Search, :clear},
    # Screen 06's clear disc, for screen 19's reason one line up: the field it
    # empties is already empty on a bare mount.
    # The same one, in the mirror. Its tag is positional rather than named —
    # `Kati.Screens.OnboardingLoudness`'s own former mirror says why: an atom made of
    # Persian words is a name no device test can type.

    #
    # `{Kati.Screens.OnboardingFirstTitle, :pick_The_Long_Hollow}` and its
    # mirror `:pick_1` sat here on the same grounds and are GONE, because the
    # grounds went. Step 5 opened with a tile already ticked, so tapping it was
    # the resting member of its family — and it opened that way because board
    # 163 draws that tile ticked, and the tick was read as a DEFAULT rather
    # than as the drawing showing what a chosen tile looks like. A reader who
    # pressed Finish setup without choosing was therefore handed one of the
    # board's four invented films.
    # The tiles are gone too since (N46): step 5 is screen 06's TMDB search, so
    # there is no pick tag left to list.
    # 157 and 156 are 154 in another colourway and another script, and each is
    # drawn in the state its own board shows — Series chosen so the episode
    # field is visible. The resting member of a family again, three times.
    {Kati.Screens.AddByHandDark, :kind_tv},
    {Kati.Screens.AddByHandDark, :status_not_started},
    {Kati.Screens.AddByHand, :status_not_started},
    # 165's resting choice — the loudness the board opens on. It was its
    # mirror's entry until mishka-group/kati#103 folded 165 into 162.
    {Kati.Screens.OnboardingLoudness, :choose_quiet},
    # Board 169's two settled members. The sheet opens on `Kati.Discover.Filters.resting/0`
    # — most popular, no kind, no rating — so `:sort_popular` sets the sort it
    # already has and `:reset` clears a choice that is already clear. Every
    # other control on the sheet moves the choice, which is what says the
    # families are wired: `Kati.DiscoverFiltersTest` presses all nine.
    {Kati.Screens.DiscoverFilters, :sort_popular},
    {Kati.Screens.DiscoverFilters, :reset},
    # Screen 177's three resting choices — the Kind the screen IS, the Edition
    # the form opens on and the status a book you are adding has. The
    # already-selected member of its family, three times, and every other
    # member of each family moves the assign or navigates, which is what says
    # the family is wired.
    {Kati.Screens.AddByHandBook, :kind_book},
    {Kati.Screens.AddByHandBook, :edition_paperback},
    {Kati.Screens.AddByHandBook, :status_not_started},
    # Screen 176's lit segment and lit chip, for the same reason: کتاب‌ها is the
    # shelf you are on and همه is the filter already showing. نمایش and موسیقی
    # both navigate and the other three chips all move the filter.
    {Kati.Screens.LanguagePick, :choose_en},
    {Kati.Screens.LanguagePick, :choose_fa},
    # Screen 54's *Title language* switch writes `Kati.Locale.put_original_titles/1`
    # to `Mob.State`, and the control mount re-reads the value the real tap just
    # wrote — the blind spot the two entries above are here for. Covered by
    # `Kati.OriginalTitlesTest`, which asserts the stored choice moves and the
    # film and series headers follow it.
    {Kati.Screens.Language, :toggle_original_titles},
    # ── Drawn, reachable, and pushing nothing because the design draws no
    # destination. Screen 66's series row ends in `Next: Low Water` and its
    # ownership row in `Due 27 Aug`; both carry a chevron, and neither a
    # next-in-series screen nor a lending screen exists anywhere in the 127
    # artboards. Answering them with a no-op is the honest state — the row is
    # real, the data behind it is real, and the page it would open has not been
    # drawn. Delete these the moment either is.
    {Kati.Screens.BookDetail, :open_series},
    {Kati.Screens.BookDetail, :open_lending},
    # (Screen 177's Album and Artist Kind chips were here, with the instruction
    # *delete both the moment 178 lands*. It landed with `D-39`, and both now
    # push `Kati.Screens.AddByHandRecord` — the record form, which opens on
    # Album and whose own Kind row moves to Artist. Struck out rather than
    # deleted, because a list that only grows is a list nobody believes.)
    {Kati.Screens.Activity, :filter_All},
    # Screen 06's × clears the field. On this sweep there is nothing to clear:
    # every screen is pressed on the socket it MOUNTED with, and screen 06
    # mounts with an empty query and the board's four rows — which is exactly
    # what the tap resets to. The control is live and was not: it was drawn as
    # a bare `Kati.UI.symbol("cancel", …)` with no `on_tap`, so a tap fell
    # through to the `<TextField>` under it and the next thing typed was
    # appended to the query somebody was trying to delete. Found on a device.
    {Kati.Screens.AddTitle, :clear_query},
    {Kati.Screens.AddTitle, :filter_Everything},
    {Kati.Screens.Calendar, :filter_all},
    # (`{Kati.Screens.Discover, :"filter_For you"}` was here. Screen 11 answers
    # an empty feed on a bare mount now — a recommendation is an answer to
    # *because you watched X*, and there is no X — so the chip rail draws one
    # already-selected chip and a selected filter carries no tap. The tag is
    # drawn by nothing, and this file walks the tags a tree DRAWS. The chip is
    # still live on a feed with picks in it.)
    # (`{Kati.Screens.EventDetail, :section_Work}` was here. N51: screen 31 no
    # longer draws the board's event, so no section chip is drawn at all.)
    # Screen 20's, which joined the day its chip rail was wired: `All` is the
    # chip `load/1` opens on, so tapping it re-selects what is selected.
    # Screen 70's unit segments. `Page` is the one the sheet opens on, so
    # tapping it sets the unit it already has; `unit_percent` and
    # `unit_minutes` both move, which is what proves the family is wired.
    {Kati.Screens.LogProgress, :unit_page},
    # Screen 73's scope segments. The sheet opens on `Selected tracks` — see
    # `Kati.Screens.LogListen`'s moduledoc for why that rather than `Whole
    # album` — so it is this one that sets the value it already has.
    {Kati.Screens.LogListen, :scope_selected},
    # ── Screen 33's ninth point of ten, and only the ninth.
    #
    # The first category above, drawn as a row rather than a strip: the sheet's
    # five stars carry ten half-star tap targets, `:star_1` to `:star_10`, and
    # tapping one sets the rating it names. This sweep runs against a database
    # with no logged watch in it — every test that writes one empties
    # `media_watches` on the way out — so the sheet is `Kati.Rating.Sample`'s
    # 4.5 stars, which is nine points, and `:star_9` is the point already set.
    # The other nine all move the rating, which is what proves the family is
    # wired rather than decorative.
    #
    # `:save` is deliberately NOT here. On the same empty database it answers
    # `{:error, :nothing_to_save}` and puts that sentence on the sheet, which is
    # a change this heuristic can see — and the reason it can is the whole of
    # #85: a save that fails has to leave a mark.
    {Kati.Screens.Rating, :star_9},
    # ── Screen 180's ninth point, for exactly the reason above, one domain
    # over. `Kati.Screens.RateAlbum` opens on the album screen 74 was about,
    # which on an empty shelf is `Kati.Music.Sample.album/0` — rating 9, which
    # is 4.5 stars. `:save` is deliberately not here either: it answers
    # `{:error, :nothing_to_save}` and draws the sentence.
    {Kati.Screens.RateAlbum, :star_9},
    # ── Screens 178 and 179's already-chosen members, the first category above.
    # Board 178 is drawn with **Album** chosen and the form loads in it, so
    # `:kind_album` sets the kind it already has; `:kind_artist` moves it, and
    # `:kind_movie`, `:kind_tv` and `:kind_book` push the form that owns
    # those three, which is what says the family is wired. Board 179 is drawn
    # with **Albums** lit because it is the state screen 21's FAB opens, so
    # `:filter_Albums` is that row's settled member; `:filter_Artists` narrows
    # and the other three push screen 06.
    {Kati.Screens.AddByHandRecord, :kind_album},
    {Kati.Screens.AddTitleMusic, :filter_Albums},
    # (Screen 83's six link rows were here, and screen 85's four below them.
    # `K-43 open-url` was built and they all open the site they name now —
    # `Kati.Screens.Attribution.site_for/1` is the table and
    # `Kati.Screens.Attribution.follow/2` is the tap. The reason on file was
    # *every one opens a URL in the platform browser, and Kati has no fence
    # that does*, which was true for as long as nobody built the fence. Struck
    # out rather than deleted, because a list that only grows is a list nobody
    # believes.)

    # ── Screen 92's three rule switches and both search fields.
    #
    # The rules ARE wired: each writes through `Kati.Services.toggle_rule/1` and
    # re-reads the set into the socket. What this heuristic cannot see is that
    # the write lands in `Mob.State`, which is neither an assign nor a nav
    # action — the same blind spot `Kati.Screens.LanguagePick`'s two entries
    # above are here for, and the reason it bites unevenly is that the sweep's
    # control mount re-reads the value the real tap just wrote. Covered properly
    # by `Kati.ServicesTest`, which asserts the stored set actually moves.
    #
    # The two search fields and the service row are drawn, reachable and open
    # nothing. `:search` is the field's ROW, and since #95 the row is no longer
    # the whole control: screen 92's field is a `<TextField>`, because screen 95
    # draws it mid-query and points what you type at the `Something else` row
    # below it. Typing arrives as `{:change, :service_query, _}` and a sweep of
    # taps cannot see it — `Kati.ServiceWriteTest` asserts the field holds what
    # was typed and that the row writes it. What the row's own `on_tap` still
    # opens is nothing, which is what keeps this entry honest.
    #
    # `:edit_service` used to sit under the same sentence — *no per-service
    # editor is drawn anywhere in the set* — and no longer does. Board 95's
    # switch is on every service row and the row's own tap refills the field
    # the service was typed in. This sweep still
    # cannot see either: it renders against an empty store, where screen 92 has
    # no service rows at all. `Kati.ServiceWriteTest` presses them over real
    # ones, which is the only place that control exists.
    {Kati.Screens.MyServices, :rule_rentals},
    {Kati.Screens.MyServices, :rule_purchases},
    {Kati.Screens.MyServices, :rule_hide_unavailable},
    # (`{Kati.Screens.MyServices, :search}` left this list with N52-C: the
    # typing field's row carried a tag nothing answered, and it carries none
    # now. 93's drawn field keeps its own, below.)
    # One entry per drawn service since #97 gave the rows their own names
    # (`Kati.Screens.MyServices.service_tag/1`). They are listed rather than
    # matched by prefix because that is what this list is: a control named here
    # is a control somebody looked at. Naming them changes nothing about what
    # they open, which is still nothing — the paragraph above is unaltered.
    # `{Kati.Screens.CountryPicker, :search}` left this list on 6 September.
    # The field was a picture whose tap fell through to
    # `handle_info(_message, …)`, over a placeholder that promised 190
    # countries against a list of seven. It is a
    # `<TextField>` that filters now, and the placeholder counts the list.
    # ── Screen 66's status and edition chips.
    #
    # All seven write: `Kati.Screens.BookDetail.apply_change/1` updates the
    # book and the page re-reads, because the hero band, the bar, the pace line
    # and the extent are all derived from the row. What this sweep runs against
    # is an EMPTY shelf, where there is no book to update and the page is the
    # drawing's — so the write is a no-op and the assigns are identical, which
    # is correct behaviour rather than a dead control. `Kati.BooksTest` asserts
    # the write with a book on the shelf.
    {Kati.Screens.BookDetail, :status_reading},
    {Kati.Screens.BookDetail, :status_finished},
    {Kati.Screens.BookDetail, :status_paused},
    {Kati.Screens.BookDetail, :status_did_not_finish},
    {Kati.Screens.BookDetail, :format_paperback},
    {Kati.Screens.BookDetail, :format_ebook},
    {Kati.Screens.BookDetail, :format_audiobook},
    # Screen 125's current currency. Tapping it clears the confirmation, which
    # on a device already showing one IS a change — but the sweep's control
    # mount opens with a confirmation for a DIFFERENT currency, so the two
    # sockets agree. `Kati.MoneyTest` asserts the clear directly.
    {Kati.Screens.Currency, :pick_GBP},
    # And the currency the confirmation is already about — see
    # `Kati.Screens.Currency.other_than/1`. Tapping it re-raises the same
    # confirmation.
    {Kati.Screens.Currency, :pick_EUR},
    # Screen 106's already-selected type and period, the same family case as
    # every other selected chip above.
    {Kati.Screens.NewGoal, :kind_films},
    {Kati.Screens.NewGoal, :period_year},
    # ── Screen 124's two.
    #
    # `edit_amount` is drawn and reachable and opens no keyboard, because Mob
    # has no text input — every field in this app is drawn rather than typed
    # into, which is #45. The field is honest about being empty and the sheet
    # saves without it, which is the screen's whole subject.
    #
    # (`{Kati.Screens.QuickAddExpense, :file_as_expense}` was here, for the
    # already-selected reason: on this screen the Expense chip is the one you
    # are already looking at. The other five are wired on
    # screen 18, and screen 124 answers none of them — it has its own chip lit
    # and its own screen behind it — so it now draws the whole row as a
    # picture, the rule `Kati.Screens.Rating.scale_toggle/1` states for the
    # toggle it lends 73 the same way. A picture draws no tags, so the entry
    # became a phantom. Screen 18's own lit chip is in this list instead.)
    # ── Screen 111's three.
    #
    # `unit_kg` is the one the sheet opens on, and `unit_st` writes through
    # `Kati.Health.put_unit/1` to `Mob.State` — which this heuristic cannot see,
    # the same blind spot `Kati.Screens.LanguagePick`'s entries are here for. It
    # bites unevenly because the control mount re-reads what the real tap wrote.
    # `Kati.HealthTest` asserts the unit actually moves.
    #
    # `now` sets the reading's timestamp to the clock, which it already is:
    # the sheet opens on now, so the button is a way back from a time you have
    # changed. With no time picker behind it — Mob has no date input, which is
    # #45 — there is nothing to come back from yet.
    {Kati.Screens.LogWeight, :unit_kg},
    {Kati.Screens.LogWeight, :unit_st},
    {Kati.Screens.LogWeight, :now},
    # ── Screen 112's two.
    #
    # `mark_taken` and `mark_skipped` write, and the write lands on the first
    # dose of the day that has not been decided about — resolved against the
    # socket each screen was mounted with, since D-59, rather than re-queried
    # at tap time.
    #
    # This sweep runs against an empty database, so that list is
    # `drawn_doses/0` and the row it hands `save_dose/2` carries no
    # `:medication_id`: the write is REFUSED rather than absent. It sets
    # `:save_error` and writes no row, which is why these two stay here — the
    # tag is answered and the store is untouched — and why the old word
    # *no-op* has been dropped. `Kati.HealthTest` asserts both with doses
    # stored.
    #
    # It was four until D-43. `add` and the four `open_schedule` tags were
    # here with the reason *"neither a new-medication sheet nor a
    # per-medication page is drawn anywhere in the artboards"*; boards 188 and
    # 189 are those two drawings, and the disc and the chevrons push
    # `Kati.Screens.AddMedication` and `Kati.Screens.MedicationDetail` now. The
    # four chevrons still hand the page `%{}` on an empty store, because the
    # drawing's four schedules carry no id — that fact lives on
    # `Kati.ScreenParamsSweepTest`'s `@empty_builders`, which is where a door
    # that names something empty belongs rather than here.
    # ── Screen 119's four.
    #
    # `aisle_Uncategorised` is the aisle the draft opens on, the same
    # already-selected case as every other chip family above.
    #
    # `edit_name`, `edit_quantity` and `edit_ingredient` open no keyboard,
    # because Mob has no text input — every field in this app is a drawn value
    # (#45). The sheet is honest about it: the preview under the fields shows
    # exactly the row the draft will become.
    {Kati.Screens.AddIngredient, :aisle_Uncategorised},
    {Kati.Screens.AddIngredient, :edit_name},
    {Kati.Screens.AddIngredient, :edit_quantity},
    {Kati.Screens.AddIngredient, :edit_unit},
    # `Type it in` is the built path and opens a form Mob cannot draw yet — the
    # same #45 gap. The row is honest: the two beside it carry `NOT IN V1`, and
    # this one does not, because typing figures in is what the app will do.
    {Kati.Screens.AddIngredient, :type_it_in},
    # ── Screens 116 and 118.
    #
    # `filter_All` and `slot_Dinner` are the selected members of their
    # families. `search` opens no keyboard (#45). `add_photo` needs a camera or
    # a picker, and fence K-31 removed both — see `native/LEDGER.md` for why
    # they went and what it would take to bring one back.
    {Kati.Screens.MealLibrary, :filter_All},
    {Kati.Screens.MealLibrary, :search},
    {Kati.Screens.MealEdit, :slot_Dinner},
    {Kati.Screens.MealEdit, :add_photo},
    # Screen 98's opening scope and ratio, the same already-selected case as
    # every other family above.
    {Kati.Screens.YearShare, :scope_all},
    {Kati.Screens.YearShare, :aspect_square},
    # The diagnostic's battery row opens the phone's own settings screen, which
    # Kati has no fence for — nothing in `native/LEDGER.md` launches an Android
    # settings intent, and the research is explicit that the exemption must be
    # reached by deep link rather than requested, because
    # `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` carries Play-policy risk. The row
    # is drawn, reachable and honest about waiting on that fence — the same
    # state screen 83's six link rows are in.

    # ── Screen 136, the loudness prompt's `Continue`. Wired, and the change
    # lives outside the socket twice over: `Mob.Permissions.request/2` raises
    # the system dialog, and `Permissions.note_asked/1` writes `Mob.State` so a
    # later read can tell `:blocked` from `:unasked`. Under test the native
    # call has no bridge, `continue/1`'s rescue returns the socket it was
    # given, and this heuristic sees a no-op. Same shape, same reason, as
    # `Kati.Screens.LanguagePick`'s pair above.
    {Kati.Screens.LoudnessPrompt, :continue},
    # ── Screens 152 and 150, three already-selected members with live
    # siblings — the first category this list documents, confirmed the way that
    # paragraph prescribes. `load/1` opens screen 152 on `onboarding_pick:
    # :screen` and `watches_anime?` read from the reader's own shelf, which is
    # `false` for anyone with nothing tracked as anime — so `:pick_screen` and
    # `:watches_no` write the values already there while `:pick_books` and
    # `:watches_yes` move the screen. `:music` is screen 150's own segment of
    # the header switch it draws; its sibling `:tv` leaves for screen 36.
    {Kati.Screens.AnimeFilter, :pick_screen},
    {Kati.Screens.AnimeFilter, :watches_no},
    {Kati.Screens.AutoDetectMusic, :music},
    # ── Screen 145 on an empty shelf. Reset clears the filters, and a device
    # with nothing tracked opens with none chosen — the reader's own zero,
    # not the board's preselection. Its sibling on 167 does not appear here
    # because that sheet has no Reset of its own; sort persists there.
    {Kati.Screens.ShelfFilters, :reset},
    # ── Screen 69, the Persian book page.
    #
    # Its controls are screen 66's controls and are inert for the same reasons,
    # one language over: `finish` and `add_to_list` push screens that exist,
    # and `open_series`/`open_lending` push screens the design has not drawn.
    # The status and edition chips are the mirror of 66's, which write against a
    # shelved book and no-op against an empty one.
    #
    # Screen 66 carries the English half of this list above, and since
    # mishka-group/kati#103 it carries the whole of it: board 69 is that screen
    # under `:fa`, so there is no second module whose entries could go live
    # alone. What is left here is board 69's own `finish`, which the English
    # list does not carry because 66's is on `@writes_anyway` — the two pages
    # are one page and this line is the last thing the pair disagreed about.
    # `add_to_list` on the four detail pages, and why it reads inert HERE and
    # only here. Board 334 wired all four on 7 September: each now pushes
    # `Kati.Screens.AddToList` carrying the member the page is about, and on a
    # real book or album the sheet opens with its ticks populated. On a DRAWN
    # fixture there is no row — `Kati.Screens.BookDetail.member/1` answers `nil`
    # for a map with no id — and `Kati.Lists.Door.open/3` then answers the
    # socket unchanged rather than pushing a sheet that would write to a row the
    # reader never chose.
    #
    # This is `Kati.Screens.Series.follow_disc/1`'s rule, one page over: a
    # control over a picture stays a picture. The sweep mounts the drawing, so
    # the drawing is what it sees.
    {Kati.Screens.BookDetail, :add_to_list},
    {Kati.Screens.BookDetailDark, :add_to_list},
    {Kati.Screens.AlbumDetail, :add_to_list},
    # Screen 72's two were here until mishka-group/kati#103 folded
    # `Kati.Screens.LogProgressFa` into screen 70. Board 72 is that screen under
    # `:fa`, so its opening unit and its timer stop are screen 70's own entries
    # above — one line each, not two.
    # ── Screen 68, screen 66 in the dark colourway.
    #
    # Its controls ARE screen 66's controls — the dark page reuses that module's
    # builders — so they are inert here for exactly the reasons the English
    # entries above give, and they would stop being inert on the same day.
    {Kati.Screens.BookDetailDark, :open_series},
    {Kati.Screens.BookDetailDark, :open_lending},
    {Kati.Screens.BookDetailDark, :status_reading},
    {Kati.Screens.BookDetailDark, :status_finished},
    {Kati.Screens.BookDetailDark, :status_paused},
    {Kati.Screens.BookDetailDark, :status_did_not_finish},
    {Kati.Screens.BookDetailDark, :format_paperback},
    {Kati.Screens.BookDetailDark, :format_ebook},
    {Kati.Screens.BookDetailDark, :format_audiobook},
    # ── Screen 71, screen 70's states in 27's manner.
    #
    # A states sheet draws all five situations at once, so its controls are
    # pictures of controls — the stepper belongs to a state rather than to a
    # value, and pressing it would move a number that is illustrating a
    # different state's problem. Screen 27's own controls are inert for exactly
    # this reason and always have been.
    {Kati.Screens.LogProgressStates, :step_up},
    {Kati.Screens.LogProgressStates, :step_down},
    {Kati.Screens.LogProgressStates, :stop},
    {Kati.Screens.LogProgressStates, :unit_percent},
    {Kati.Screens.LogProgressStates, :unit_minutes},
    # Screen 86's opening scope, the same already-selected case as every other
    # chip family above.
    {Kati.Screens.SearchIdle, :scope_all},
    # Screen 84's two link rows. Screen 83's six are above for the same reason
    # and this sheet reuses that screen's cards: every one opens a URL in the
    # platform browser, and Kati has no fence that does.
    {Kati.Screens.AttributionStates, :open_tmdb},
    {Kati.Screens.AttributionStates, :open_listenbrainz},

    # Screen 20's already-selected shelf chip. `chip_counts/1` draws all four
    # and the lit one's tap re-selects what is already selected, which changes
    # nothing — the same shape screen 03's `filter_all` has, and the same
    # reason: only the unselected chips are choices, and the selected one keeps
    # its tag so a fifth chip is a change to `chip_counts/1` and not to the
    # handler. It was `{Kati.Screens.BooksFa, :filter_0}` until #103 folded
    # that mirror into this screen and the tags became ids.
    {Kati.Screens.Books, :filter_all},
    # Screen 82's `key_kati` was here until mishka-group/kati#103 folded the
    # mirror away. The chip in force carries no tag on screen 80 — `key_chip/3`
    # draws it only for the chip that is NOT selected — so with one screen
    # instead of two there is no `key_kati` drawn anywhere, in either locale,
    # and the line that named it went with the mirror.
    # Screen 126's opening filter.
    {Kati.Screens.MoneyDay, :filter_All},
    # Screen 93's two fields, which open no keyboard (#45). (Screen 80's
    # `key_own` was here too. The key chips are drawn only on a build carrying
    # Kati's own key, which is never the case under test, so the tag is no
    # longer drawn at all — the reader's own key is simply the default.
    # `Kati.DataSourcesKeyTest` draws the chips both ways.)
    {Kati.Screens.MyServicesEmpty, :search},
    # Two, not five: 93 draws only the free card — having no subscriptions is
    # the whole subject of the board. Same `service_tag/1`, same reason.
    {Kati.Screens.MyServicesEmpty, :edit_service_Aria_Free},
    {Kati.Screens.MyServicesEmpty, :edit_service_Dispatch},
    # Board 323 made 93's rules screen 92's rules, live — so `Hide titles I
    # can't watch` joins its twin four screens up on this list, and for the
    # identical reason: `Kati.Services.toggle_rule/1` writes to `Mob.State`,
    # which is neither an assign nor a nav action, and the sweep's control
    # mount re-reads the value the real tap just wrote. `Kati.ServicesTest`
    # presses it and asserts the stored set moves — and that screen 92 opened
    # next agrees with it, which is the whole of the ruling.
    #
    # Only this one of the three: the sweep still sees `rule_rentals` and
    # `rule_purchases` move, and this list is what somebody looked at rather
    # than what looks like it.
    {Kati.Screens.MyServicesEmpty, :rule_hide_unavailable},
    # Screen 99's scope chips. The board has one section's figures on it and
    # cannot follow them anywhere — relighting a chip over a card that did not
    # move is the one thing it exists to argue against. Its own moduledoc says
    # so, and 98 is where the choice is actually made.
    {Kati.Screens.YearShareBooks, :scope_all},
    {Kati.Screens.YearShareBooks, :scope_books},
    {Kati.Screens.YearShareBooks, :scope_screen},
    {Kati.Screens.YearShareBooks, :scope_books},
    {Kati.Screens.YearShareBooks, :scope_music},
    {Kati.Screens.YearShareBooks, :scope_meals},
    {Kati.Screens.YearShareBooks, :scope_habits},
    {Kati.Screens.YearShareBooks, :aspect_square},
    # Screen 97's third rule, the Persian mirror of 92's — the same `Mob.State`
    # blind spot the English entries above record.
    # The opening chip on each of the four screens the third batch added. Same
    # already-selected case as every other family above: 87 and 90 open on All,
    # and 102 and 103 are 98's board with its own opening scope and ratio.
    #
    # Board 90's own entry is gone rather than renamed. Since
    # mishka-group/kati#103 folded the mirror away, 90 IS screen 19 read under
    # `:fa`, and 19 has always named its chips `filter_<key>` — so the one
    # `{Kati.Screens.Search, :filter_all}` below covers the board in both
    # scripts, and `:scope_all` was a tag nothing had drawn since the fold.
    {Kati.Screens.SearchTyping, :scope_all},
    # Screen 113 draws screen 42's Meals tile as one of the states it is about.
    # A picture of a tile, not a tile.
    # Once per grid since #97 banded the tags — this board draws the same four
    # sections twice, so the Meals tile is two nodes. Both are inert for the
    # reason the single entry was: the tile is drawn OFF in both states, and a
    # switched-off section has nothing to open.
    {Kati.Screens.HealthEmptyStates, :open_meals_nothing_set_up},
    {Kati.Screens.HealthEmptyStates, :open_meals_meals_off},
    # Screen 115's dose buttons and its opening range. The two writes land on
    # the first undecided dose of the day, resolved against the socket this
    # screen was mounted with; on an empty database that is the drawing's list,
    # whose rows carry no `:medication_id`, so the write is refused and no row
    # is created — the same answer, in the same words, as screen 112's English
    # entries above.
    # A dose row itself, which marks the same dose the `Taken` button does and
    # is the same no-op on an empty database.
    # Screen 109's current range. The chart draws every reading whatever the
    # segment says — the range is drawn and not yet applied, because a series
    # of four readings has no month to narrow to. It narrows when there is
    # something to narrow.
    {Kati.Screens.Weight, :range_month},
    {Kati.Screens.Library, :shelf_screen},
    # The same segment on the other two shelves. Screens 03, 20 and 21 draw one
    # control three times, and on each of them one segment is the shelf you are
    # already looking at. The other two now move — see
    # `Kati.Screens.Books.handle_tap/2` — which is what makes these two the
    # resting member of a family rather than two more dead tabs.
    {Kati.Screens.Books, :open_books},
    {Kati.Screens.Music, :segment_music},
    {Kati.Screens.MealsDay, :filter_All},
    {Kati.Screens.Nutrition, :period_Week},
    {Kati.Screens.ReleaseWatcher, :"cadence_Every 6h"},
    {Kati.Screens.Search, :filter_all},
    # Board 167's resting sort, and it is an artefact of how this sweep walks
    # rather than a control that does nothing. Every tag is dispatched against
    # the SAME starting socket, but `Kati.Library.UpNextFilters` is a
    # `Mob.State` key, so the store carries each tap forward: by the time
    # `:recently_touched` is reached another sort has already been written, and
    # selecting it puts the page back to exactly the state it mounted in.
    # Identical assigns, identical nav action, and therefore indistinguishable
    # from a tap that landed nowhere.
    #
    # It is live, and a run settles that rather than this comment:
    # `Kati.UpNextFiltersTest`'s "tapping the row a second time flips it"
    # dispatches it twice from a known store and asserts the direction moves.
    {Kati.Screens.UpNextFilters, :recently_touched},
    # (`{Kati.Screens.Series, :season_S2}` was here. Screen 04 draws its own
    # empty page on an empty store now, and an empty page has no season pills,
    # so the tag is drawn by nothing and the entry described an app that used to
    # exist. The pill is still a live control on a series that HAS seasons —
    # `Kati.SeriesTickTest` is where that is held.)

    # (`Kati.Screens.Calendar`'s selected day cell belongs in the group above
    # and cannot be written here: its tag carries today's ISO date, so a
    # literal would rot overnight. `inert_baseline/0` adds it.)

    # ── Backlog. Every tag in the family is inert, so the whole control does
    # nothing — a sheet that never opens, a button that never marks anything.
    # These reach a `_tag ->` catch-all (or, on a hand-rolled screen, the
    # `handle_info(_message, socket)` one), which is why `handle_tap/2 answers
    # every tag its screen draws` cannot see them. Delete a line as you wire it.
    # (The four `:open_sort` discs were here — screens 03, 20, 21 and 57. Board
    # 145 is captioned *One sheet for screens 03, 20 and 21* and has been in
    # `test/design/screens/` since the shelf wave, so the reason on file —
    # `books.ex:642`'s *no board in the 165 draws a sort sheet for any shelf* —
    # had outlived itself. All four now push `Kati.Screens.ShelfFilters`, and
    # all four push it BARE: `shelf_filters.ex:79` discards params, so a
    # `%{shelf: …}` would be an argument nobody reads. Struck together, because
    # three of four would be the inconsistency the sheet's own caption names.)
    {Kati.Screens.Health, :open_filters},
    # (`{Kati.Screens.Home, :open_calendar}` was here. #91 wired it: screen
    # 139's *Today* row carries the same tag as screen 01's header disc, and a
    # page borrowed from `Kati.Screens.HomeEmpty` could not ship with it still
    # dead. Struck off as this list's own header asks.)
    {Kati.Screens.Language, :add_language},
    # Screen 43's **Done prepping**. `Kati.Meals.Recipe` stores a method, a
    # duration and an oven temperature, and nothing anywhere records that a
    # prep was DONE — screen 43's own moduledoc says the card stays on
    # `Kati.Meals.SampleToday.prep/0` rather than being faked for exactly that
    # reason. The button is drawn because the board draws it; it marks nothing
    # because there is no column to mark, and inventing one to quiet a sweep is
    # what this list exists to prevent.
    {Kati.Screens.MealsToday, :done_prepping},
    {Kati.Screens.Meal, :more},
    {Kati.Screens.Nutrition, :share}
    # (`{Kati.Screens.Rating, :add_tag}` was here, filed under Backlog as *a
    # sheet that never opens*. It was struck off, and there is
    # still no sheet: a tag is one short word, so the field opens under the
    # chips with the tags this reader has used before beside it. The tag is now
    # a phantom to this sweep for the reason screen 35's status tiles are —
    # the sweep renders against an empty store, where the sheet draws
    # `Kati.Rating.Sample` and the chips carry no taps at all. `Kati.RatingTagsTest`
    # presses them over a real watch.)
    # (`{Kati.Screens.Subscriptions, :open_menu}` was here — the `more_horiz`
    # disc on screen 23, filed under Backlog because 23.html draws exactly one
    # and no menu, sheet or popover anywhere in the export. The entry kept the
    # tap alive on the argument that *"stripping `on_tap` would take its press
    # feedback away too."*
    #
    # Press feedback was what was wrong with it. A disc that lights under the
    # finger and does nothing is a control that has answered; one that does not
    # light has not been offered. The disc is still drawn — it is the board's
    # furniture — and it takes no tag, so this list no longer has one to name.)
    # (Screen 121's `save_image` was here, with the sentence *it stops being
    # inert the day the bridge gains a screen-to-bitmap call, and not before.*
    # `K-45 capture-screen` is that call: `Kati.Native.Files.save_screen/1`
    # draws the content view into a PNG in the cache and hands it to the same
    # `ACTION_CREATE_DOCUMENT` picker the backups go through. Struck out rather
    # than deleted, because a list that only grows is a list nobody believes.
    #
    # `Kati.Screens.YearCards.handle_tap/2` stubs its own save for the reason
    # this one used to, and is now the last screen in the app that does. It is
    # one call away.)
  ]

  test "both locales are swept" do
    # Every sweep below iterates `@locales`, and the reason is not thoroughness
    # for its own sake: a tag can differ per locale. `Kati.Screens.Language`
    # draws the row for the language you are NOT in, so its tag is
    # `:choose_language_fa` in English and `:choose_language_en` in Persian —
    # tap either one in the wrong locale and it is not the control the screen
    # drew. An `:en`-only sweep silently misses half of that screen.
    #
    # This test is the canary for the failure mode that makes the whole file
    # worthless without saying so: a locale that yields no screens at all.
    expected = length(ScreenSweep.screens())

    for locale <- @locales do
      swept = map_size(ScreenSweep.drawn_taps(locale))

      assert swept == expected,
             "the #{locale} pass rendered only #{swept} of #{expected} screens, so " <>
               "every tap check below silently skipped the rest"
    end
  end

  test "every drawn tap reaches its screen's real handler and returns a socket" do
    # The device path, byte for byte: a Button's `on_tap` sends
    # `{:tap, tag}` to the screen process, so `handle_info/2` is what runs —
    # for a macro screen and a hand-rolled one alike. This is the arm that
    # covers the shell's own tags (`:back`, `:fab`, `root_*`), which never
    # reach `handle_tap/2`, and the hand-rolled screens, which have no
    # `handle_tap/2` to reach.
    #
    # It asserts the weaker half of the contract — the message is accepted and
    # the return shape is right — because `rescue_tap/3` is designed to absorb
    # the strong half. `handle_tap/2 answers every tag its screen draws` is
    # where a missing handler actually fails.
    offenders =
      ScreenSweep.per_locale(@locales, fn locale ->
        for {module, {socket, tags}} <- ScreenSweep.drawn_taps(locale),
            tag <- tags,
            message = dispatch_failure(module, socket, tag) do
          "(#{locale}) " <> message
        end
      end)

    assert offenders == [], "\n" <> Enum.join(offenders, "\n\n")
  end

  test "handle_tap/2 answers every tag its screen draws" do
    # `Enum.member?/2` rather than `in`: `@dead_taps` is empty, and `x in []`
    # is a compile-time warning ("the right side of in is always empty"). The
    # list is meant to be empty and meant to be able to grow again, so the
    # membership test has to read the same either way.
    unexpected =
      Enum.reject(dead_taps(), fn {module, tag, _} -> Enum.member?(@dead_taps, {module, tag}) end)

    assert unexpected == [],
           "these controls are drawn but nothing answers them, so tapping does " <>
             "nothing and the build stays green:\n\n" <>
             Enum.map_join(unexpected, "\n\n", fn {module, tag, message} ->
               "  #{inspect(module)} draws #{inspect(tag)}:\n    #{message}"
             end)
  end

  test "the dead-tap allow-list has no stale entries" do
    stale = @dead_taps -- Enum.map(dead_taps(), fn {module, tag, _} -> {module, tag} end)

    assert stale == [],
           "these taps are wired now. Delete them from @dead_taps in " <>
             "#{Path.relative_to_cwd(__ENV__.file)} so the list keeps meaning " <>
             "what it says:\n" <>
             Enum.map_join(stale, "\n", fn {module, tag} ->
               "  {#{inspect(module)}, #{inspect(tag)}}"
             end)
  end

  test "the inert list names no tag that is not drawn" do
    # `@inert_taps` had no stale check, and a list with no stale check is a
    # list that accumulates fiction. It is documented as a FLOOR rather than an
    # inventory — an entry that comes good costs nothing — but an entry naming
    # a tag no screen draws at all is a different thing: it is a sentence about
    # a control that does not exist, and the next person to read the list
    # believes it.
    #
    # Found by counting. `{Kati.Screens.QuickAddExpense, :edit_amount}` carried
    # a paragraph about Mob having no text input, on a screen that no longer
    # draws that tag at all — and by then every add form in the app had a real
    # `<TextField>` in it.
    #
    # Both locales, because a tag drawn only in Persian is still drawn.
    drawn =
      for locale <- @locales,
          {module, {_socket, tags}} <- ScreenSweep.drawn_taps(locale),
          tag <- tags,
          into: MapSet.new(),
          do: {module, tag}

    phantom = Enum.reject(@inert_taps, &MapSet.member?(drawn, &1))

    assert phantom == [],
           "these entries name a tag no screen draws, in either locale. The control was " <>
             "renamed or removed and the entry outlived it — delete each one, so the list " <>
             "stays a description of the app rather than of an app that used to exist:\n" <>
             Enum.map_join(phantom, "\n", fn {module, tag} ->
               "  {#{inspect(module)}, #{inspect(tag)}}"
             end)
  end

  test "no new dead-looking taps" do
    # A ratchet, not a proof, and the difference is worth being clear about.
    #
    # `handle_tap/2 answers every tag its screen draws` cannot see two cases: a
    # `handle_tap/2` ending in a `_tag -> {:noreply, socket}` catch-all, which
    # answers every tag by doing nothing; and a hand-rolled `use Mob.Screen`
    # screen, whose `handle_info(_message, socket)` catch-all does the same. In
    # both, an unwired control is indistinguishable from a wired one — from the
    # outside. From the outside is all a test has.
    #
    # So: dispatch the tag, dispatch a tag no screen could possibly draw, and
    # compare what came back. Identical assigns and identical nav action means
    # the real tag landed exactly where the nonsense one did.
    #
    # That over-reports, deliberately. Tapping the filter that is already
    # selected is a legitimate no-op and shows up here, which is why
    # `@inert_taps` is long and why this test only fails on tags that are NOT
    # already in it. A wired tap is free to leave the list; a newly drawn
    # control that answers to nothing may not join it silently.
    #
    # Unlike `@dead_taps` this list is NOT checked for stale entries. It is a
    # floor, not an inventory: a tap that becomes live simply stops being
    # reported, and failing the build to make someone delete a line from a
    # heuristic's baseline would spend more attention than the line is worth.
    new = inert_taps() -- inert_baseline()

    assert new == [],
           "these newly drawn controls reach nothing that changes anything — " <>
             "wire them, or add them to @inert_taps with a reason:\n" <>
             Enum.map_join(new, "\n", fn {module, tag} ->
               "  {#{inspect(module)}, #{inspect(tag)}}"
             end)
  end

  test "no control is named after the word printed on it" do
    # The first edit of #103's fold.
    #
    # `Kati.Screens.AddByHand.kind_chip/5` used to build its tap out of the
    # label — `"kind_" <> label` — so the Persian form's Series chip was
    # `:kind_سریال`. Two things follow from that and both are defects. A screen
    # RENAMES ITS OWN CONTROLS when the language changes, so no device test can
    # type them: `Kati.Screens.OnboardingLoudness`'s own former mirror had already recorded
    # it as "an atom made of Persian words is a name no device test can type."
    # And once the mirrors fold into their English screens, the tag would
    # change under the same screen depending on who is looking at it.
    #
    # An ASCII tag is not the point; a STABLE tag is. ASCII is what can be
    # checked here, and every label Kati would build a tag from in the other
    # script is outside it, so the check catches the real thing.
    #
    # `@from_the_data` below is the other way a tag can come out non-ASCII, and
    # it is not this defect: a tag built from a ROW rather than from a label.
    # `Kati.Screens.Library.poster_tag/1` prefers the tracked row's id and falls
    # back to the caption only for sample rows that have none, so on a device it
    # is `open_film_<uuid>`; its Persian mirror has only sample rows, so all six
    # of its tiles fall back. They go when the mirror goes.
    named_for_a_word =
      @locales
      |> ScreenSweep.per_locale(fn locale ->
        for {module, {_socket, tags}} <- ScreenSweep.drawn_taps(locale),
            tag <- tags,
            not (tag |> Atom.to_string() |> String.printable?(0)) or
              String.match?(Atom.to_string(tag), ~r/[^\x00-\x7F]/),
            do: {module, tag}
      end)
      |> List.flatten()
      |> Enum.uniq()
      |> Kernel.--(@from_the_data)
      |> Enum.sort()

    assert named_for_a_word == [],
           "these taps are named after the label drawn on them rather than " <>
             "after the value behind it, so the control changes name with the " <>
             "language and no device test can type it — pass the stable key " <>
             "(`:movie`, `:not_started`) to the chip and build the tag from " <>
             "that, as `Kati.Screens.AddByHand.tag/2` does:\n" <>
             Enum.map_join(named_for_a_word, "\n", fn {module, tag} ->
               "  {#{inspect(module)}, #{inspect(tag)}}"
             end)
  end

  test "every on_tap the app draws is a shape the bridge actually registers" do
    # The gap that let a dead control through a fully green run.
    #
    # `Kati.Screens.ImportRecognised` shipped `on_tap: :check_mapping` — a bare
    # atom. `Mob.Renderer` calls `nif.register_tap/1` for `{:on_tap, pid}` and
    # for `{:on_tap, {pid, tag}}` and for nothing else; a bare atom falls to the
    # generic prop catch-all and is serialised as data. No handle is registered,
    # no `accessibility_id` is emitted, and the row is decoration on the device.
    #
    # Every other check in this file was blind to it. `ScreenSweep.tap_tags/1`
    # collects `%{on_tap: {pid, tag}} when is_atom(tag)`, so a malformed tag is
    # not a tag it can see — it is not drawn, not dead, not inert, just absent.
    # `handle_tap/2 answers every tag its screen draws` passed because the tag
    # was never counted as drawn. `Kati.AppReachabilityTest`'s push graph
    # skipped it for the same reason. A sweep that can only see well-formed
    # values cannot report a malformed one, so this asks the opposite question:
    # not "is every tag wired" but "is every value even a tag".
    #
    # `nil` is legal and deliberate — `ScreenSweep.tap_tags/1`'s own doc says so.
    # It is what the selected segment of a switcher carries, and it is the one
    # thing a control can hold that means "not tappable" rather than "broken".
    #
    # Most call sites cannot get this wrong: `Kati.UI.MishkaPill.pill/1` and
    # `Kati.UI.MishkaActionIcon.action_icon/2` run a bare atom through
    # `Event.handler/1` and wrap it themselves. `Kati.UI.SettingsList.row/4`
    # puts `:on_tap` onto the node untouched, which is why the one screen that
    # hand-wrote a row got it wrong and forty others did not.
    malformed =
      @locales
      |> ScreenSweep.per_locale(fn _locale ->
        for module <- ScreenSweep.screens(),
            {:ok, _socket, tree} <- [ScreenSweep.render(module)],
            node <- Mob.ScreenCase.flatten(tree),
            {:ok, value} <- [Map.fetch(Map.get(node, :props) || %{}, :on_tap)],
            not registrable_tap?(value),
            do: "  #{inspect(module)} draws on_tap: #{inspect(value)}"
      end)
      |> Enum.uniq()
      |> Enum.sort()

    assert malformed == [],
           "these `on_tap` values reach the device without a name. A bare atom is not " <>
             "registered at all and the control is inert; a `{pid, term}` whose term is not " <>
             "an atom does fire, but emits no `accessibility_id`, so no sweep in this file " <>
             "and no screen reader can see it. Give each one an atom tag — " <>
             "`Kati.Screens.ImportSources.tag/1` is the shape to copy:\n" <>
             Enum.join(malformed, "\n")
  end

  test "every screen says which screen it is, exactly once" do
    # What a device test waits on.
    #
    # Nothing else on a phone identifies a screen: the bridge's root state is a
    # counter and a string, and asserting on visible text cannot substitute,
    # because Kati draws the same words in an English screen and its Persian
    # mirror, and again in a live screen and its `— states` sheet. So
    # `Kati.Shell.render/1` and `Kati.Screens.Pushed.chrome/3` each stamp an
    # `accessibility_id` of `screen:<name>`, which `K-35 test-tag` turns into a
    # Compose `testTag` the harness can wait for.
    #
    # Exactly once, not at least once: two stamps on one tree is a screen
    # wrapped in another screen's chrome, and a `waitUntil` that matched either
    # would be waiting on the wrong thing.
    counts =
      for {number, _label, module, _kind} <- Kati.Screens.Gallery.screens(),
          {:ok, _socket, tree} <- [ScreenSweep.render(module)] do
        stamps =
          tree
          |> Mob.ScreenCase.flatten()
          |> Enum.count(fn node ->
            case Map.get(node.props || %{}, :accessibility_id) do
              "screen:" <> _rest -> true
              _other -> false
            end
          end)

        {number, module, stamps}
      end

    wrong = for {n, m, c} <- counts, c != 1, do: "  #{n} #{inspect(m)} stamps #{c}"

    assert wrong == [],
           "these screens do not say which screen they are, or say it twice:\n" <>
             Enum.join(wrong, "\n")
  end

  test "no two nodes in one screen carry the same accessibility_id" do
    # A tag that names two things names neither. `onNodeWithTag` throws on a
    # second match rather than picking one, so a duplicate is a device test that
    # cannot be written rather than one that quietly passes.
    #
    # ## This check was blind, and said so confidently
    #
    # It read `props[:accessibility_id]` off the pre-serialization tree. Almost
    # nothing sets that by hand: `Mob.Renderer` DERIVES the id at serialization
    # from `on_tap`, emitting `Atom.to_string(tag)` for a `{pid, atom}` tuple
    # (`deps/mob/lib/mob/renderer.ex:313`). So the pre-serialization tree
    # carried exactly one id on 148 of 152 screens — `Pushed.chrome/3`'s
    # `screen:` stamp — and two on the four that also tag a `TextField` by
    # hand. One id per screen cannot repeat, so the assertion could not go red,
    # measured by histogram rather than argued.
    #
    # Its own comment predicted `Kati.Screens.Library` would collide "as soon as
    # a shelf holds two of a kind" and that it "draws too few against an empty
    # store to collide yet". Both halves were wrong: 03 repeated `:open_film`
    # AND `:open_series` against the empty store, and had since the screen was
    # written, because the empty store drew nine invented films. A guard that
    # names the defect it is blind to is worse than no guard, because it is
    # cited as cover. (#91 took the nine films away, so 03 is off the register
    # below without the collision having been fixed — see the note there.)
    #
    # This reads the union of both: ids set by hand, and the ids the renderer
    # will derive. That is what the device addresses.
    collisions =
      for {number, _label, module, _kind} <- Kati.Screens.Gallery.screens(),
          {:ok, _socket, tree} <- [ScreenSweep.render(module)],
          repeated = repeated_ids(tree),
          repeated != [],
          do: {number, module, repeated}

    found = Map.new(collisions, fn {number, _m, tags} -> {number, tags} end)

    # Grew: a screen that collides and is not written down below.
    grew =
      for {number, module, tags} <- collisions,
          known = Map.get(@known_collisions, number, []),
          new_tags = tags -- known,
          new_tags != [],
          do: "  #{number} #{inspect(module)} repeats #{inspect(new_tags)}"

    assert grew == [],
           "these screens give one name to more than one node, so no device test can " <>
             "address either — `onNodeWithTag` throws on the second match:\n" <>
             Enum.join(grew, "\n")

    # Went stale: written down below, but fixed. The list is a debt register,
    # and a register nobody strikes entries off is a list of lies within a
    # month — which is exactly how the check above came to be cited for four
    # years of collisions it could not see.
    stale =
      for {number, tags} <- @known_collisions,
          fixed = tags -- Map.get(found, number, []),
          fixed != [],
          do: "  #{number} no longer repeats #{inspect(fixed)}"

    assert stale == [],
           "these are fixed — strike them off `@known_collisions` so the ratchet " <>
             "tightens:\n" <> Enum.join(stale, "\n")
  end

  test "neither shell macro supplies a default handle_tap/2" do
    # The load-bearing assumption under this whole file. A
    # `def handle_tap(_tag, socket), do: {:noreply, socket}` in either macro
    # would answer every tag on every screen, and `handle_tap/2 answers every
    # tag its screen draws` would pass over an app of dead buttons — the exact
    # state this sweep was written to end. `Kati.Screens.Root`'s moduledoc says
    # the default is omitted on purpose; this is that sentence, enforced.
    assert Kati.Screens.Root.tap_handler_missing?(BareRoot),
           "Kati.Screens.Root's macro now defines a default handle_tap/2. Every " <>
             "screen answers every tag with silence again, and this file can no " <>
             "longer tell a wired control from a dead one."

    assert Kati.Screens.Root.tap_handler_missing?(BarePushed),
           "Kati.Screens.Pushed's macro now defines a default handle_tap/2 — see above."
  end

  # ── the sweeps themselves ──────────────────────────────────────────────────

  # `{module, tag, why}` for every tag whose screen answers taps through
  # `handle_tap/2` and cannot answer this one. Called around `rescue_tap/3`,
  # never through it, so what that function chooses to survive is irrelevant.
  defp dead_taps do
    @locales
    |> ScreenSweep.per_locale(fn locale ->
      for {module, {socket, tags}} <- ScreenSweep.drawn_taps(locale),
          ScreenSweep.root_behaviour?(module),
          tag <- tags,
          not ScreenSweep.shell_tag?(tag),
          why = handle_tap_failure(module, socket, tag) do
        {module, tag, why}
      end
    end)
    |> Enum.uniq_by(fn {module, tag, _why} -> {module, tag} end)
    |> Enum.sort()
  end

  defp handle_tap_failure(module, socket, tag) do
    case ScreenSweep.safely(fn -> module.handle_tap(tag, socket) end) do
      {:ok, {:noreply, %Mob.Socket{}}} -> nil
      {:ok, other} -> "handle_tap/2 returned #{inspect(other, limit: 5)}"
      {:error, message} -> message
    end
  end

  # `@inert_taps`, plus the entry that cannot be written as a literal and the
  # ones already accounted for under a stricter test.
  defp inert_baseline do
    # `Kati.Screens.Calendar`'s day strip tags each cell with its own ISO date
    # (`day_2026-08-20`), and the cell for today is the one already selected —
    # inert for the same correct reason as every `filter_All` above. Written
    # out it would be right for one day and wrong on all the others, so it is
    # rebuilt from the same clock the screen reads.
    today = String.to_atom("day_" <> Date.to_iso8601(Kati.Time.today()))

    # Taps already tracked, by name and with a reason, in `@dead_taps`. They
    # are inert too — that is what dead means — and listing them twice would
    # mean deleting them twice.
    [{Kati.Screens.Calendar, today} | @inert_taps] ++ @dead_taps
  end

  # A tap value Kati is willing to draw. A bare pid is the whole-node form;
  # `{pid, atom}` is the tagged form and the only one that also emits an
  # `accessibility_id`, which is what every sweep in this file and every screen
  # reader reads a control by. `nil` is "not tappable" and is not a defect.
  #
  # Everything else is refused, for two different reasons. A bare atom does not
  # register and cannot be tapped at all. A `{pid, term}` whose term is not an
  # atom does register and does fire — `Mob.List` tags its own rows
  # `{:list, id, :select, index}` — but arrives nameless, so it is invisible to
  # every check here and unnamed to a screen reader. The first is broken; the
  # second is unobservable, and this file exists to make taps observable.
  defp registrable_tap?(nil), do: true
  defp registrable_tap?(pid) when is_pid(pid), do: true
  defp registrable_tap?({pid, tag}) when is_pid(pid) and is_atom(tag), do: true
  defp registrable_tap?(_other), do: false

  # Every `{module, tag}` that reaches a handler and leaves the screen exactly
  # as a tag no screen draws would have left it.
  defp inert_taps do
    sentinel = :__kati_tap_sweep_unhandled__

    @locales
    |> ScreenSweep.per_locale(fn locale ->
      for {module, {socket, tags}} <- ScreenSweep.drawn_taps(locale),
          {:ok, baseline} <- [outcome(module, socket, sentinel)],
          tag <- tags,
          not ScreenSweep.shell_tag?(tag),
          outcome(module, socket, tag) == {:ok, baseline} do
        {module, tag}
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # What a tap did, reduced to the two things a screen can show for it: the
  # assigns the next render reads, and the navigation it asked for.
  defp outcome(module, socket, tag) do
    case ScreenSweep.safely(fn -> module.handle_info({:tap, tag}, socket) end) do
      {:ok, {:noreply, %Mob.Socket{} = updated}} ->
        {:ok, {updated.assigns, Map.get(updated.__mob__, :nav_action)}}

      other ->
        other
    end
  end

  defp dispatch_failure(module, socket, tag) do
    case ScreenSweep.safely(fn -> module.handle_info({:tap, tag}, socket) end) do
      {:ok, {:noreply, %Mob.Socket{}}} ->
        nil

      {:ok, other} ->
        "#{inspect(module)} handle_info({:tap, #{inspect(tag)}}, socket) returned\n" <>
          "  #{inspect(other, limit: 5)}\n" <>
          "  instead of {:noreply, %Mob.Socket{}}"

      {:error, message} ->
        "#{inspect(module)} raised on {:tap, #{inspect(tag)}}:\n  #{message}"
    end
  end

  # Every id the DEVICE will see for this tree: the ones set by hand, plus the
  # ones `Mob.Renderer` derives from an atom `on_tap` at serialization. Reading
  # only the first is what made the duplicate check above vacuous for the life
  # of the project.
  defp emitted_ids(tree) do
    tree
    |> Mob.ScreenCase.flatten()
    |> Enum.flat_map(fn node ->
      props = node.props || %{}

      explicit =
        case Map.get(props, :accessibility_id) do
          id when is_binary(id) -> [id]
          _other -> []
        end

      derived =
        case Map.get(props, :on_tap) do
          {pid, tag} when is_pid(pid) and is_atom(tag) -> [Atom.to_string(tag)]
          _other -> []
        end

      explicit ++ derived
    end)
  end

  defp repeated_ids(tree) do
    ids = emitted_ids(tree)

    (ids -- Enum.uniq(ids))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
