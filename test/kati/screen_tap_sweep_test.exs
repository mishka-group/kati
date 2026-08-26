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
      for table <- ~w(goals expenses health_readings tracked_titles cached_titles) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    :ok
  end

  alias Kati.ScreenSweep
  alias Kati.TapSweepProbe.BarePushed
  alias Kati.TapSweepProbe.BareRoot

  @locales [:en, :fa]

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
  # This list may only SHRINK. The test enforces both directions — a new
  # collision fails it, and so does an entry here that no longer collides.
  @known_collisions %{
    "20" => ["open_book"],
    "21" => ["open_album", "open_artist"],
    "28" => ["inbox", "root_calendar"],
    "38" => ["finish"],
    "42" => ["open_meals", "open_retired"],
    "52" => ["density"],
    "55" => ["open_inbox"],
    "57" => ["open_series"],
    "77" => ["open_album"],
    "86" => ["repeat_query", "try_suggestion"],
    "92" => ["edit_service"],
    "93" => ["edit_service"],
    "96" => ["my_services"],
    "112" => ["open_schedule"],
    "113" => ["open_habits", "open_meals", "open_medication", "open_weight"],
    "114" => ["close"],
    "122" => ["open_subscriptions"],
    "126" => ["toggle_density"],
    "127" => ["open_services"],
    "151" => ["open_settings"]
  }

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
    {Kati.Screens.LanguagePick, :choose_en},
    {Kati.Screens.LanguagePick, :choose_fa},
    # ── Drawn, reachable, and pushing nothing because the design draws no
    # destination. Screen 66's series row ends in `Next: Low Water` and its
    # ownership row in `Due 27 Aug`; both carry a chevron, and neither a
    # next-in-series screen nor a lending screen exists anywhere in the 127
    # artboards. Answering them with a no-op is the honest state — the row is
    # real, the data behind it is real, and the page it would open has not been
    # drawn. Delete these the moment either is.
    {Kati.Screens.BookDetail, :open_series},
    {Kati.Screens.BookDetail, :open_lending},
    {Kati.Screens.Activity, :filter_All},
    {Kati.Screens.AddTitle, :filter_Everything},
    {Kati.Screens.Calendar, :filter_All},
    {Kati.Screens.Discover, :"filter_For you"},
    {Kati.Screens.EventDetail, :section_Work},
    {Kati.Screens.Library, :filter_All},
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
    # ── Screen 83's six link rows. Every card and the notices row opens a URL
    # in the platform browser, and Kati has no fence for that: nothing in
    # `native/LEDGER.md` opens an external link, and inventing one to make six
    # taps look alive would be shipping a native change for a test. The rows
    # are drawn, reachable, and honest about being links; what they would open
    # is the browser, through a bridge that does not exist yet.
    {Kati.Screens.Attribution, :open_tmdb},
    {Kati.Screens.Attribution, :open_justwatch},
    {Kati.Screens.Attribution, :open_tvmaze},
    {Kati.Screens.Attribution, :open_open_library},
    {Kati.Screens.Attribution, :open_musicbrainz},
    {Kati.Screens.Attribution, :open_notices},
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
    # opens is nothing, which is what keeps this entry honest, and
    # `:edit_service` opens nothing because no per-service editor is drawn
    # anywhere in the set.
    {Kati.Screens.MyServices, :rule_rentals},
    {Kati.Screens.MyServices, :rule_purchases},
    {Kati.Screens.MyServices, :rule_hide_unavailable},
    {Kati.Screens.MyServices, :search},
    {Kati.Screens.MyServices, :edit_service},
    {Kati.Screens.CountryPicker, :search},
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
    # `file_as_expense` is the Expense chip, and on this screen it is the
    # selected one: you are already looking at what it files the sentence as.
    # On screen 18 the same chip pushes here, which is what makes the family
    # live.
    {Kati.Screens.QuickAddExpense, :edit_amount},
    {Kati.Screens.QuickAddExpense, :file_as_expense},
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
    # ── Screen 112's four.
    #
    # `mark_taken` and `mark_skipped` write, and the write lands on the first
    # dose of the day that has not been decided about. This sweep runs against
    # an empty database, where there are no doses at all and the page is the
    # drawing's — so the write is a no-op, which is correct rather than dead.
    # `Kati.HealthTest` asserts both with doses stored.
    #
    # `add` and `open_schedule` are drawn and reachable and open nothing:
    # neither a new-medication sheet nor a per-medication page is drawn
    # anywhere in the 127 artboards.
    {Kati.Screens.Medication, :mark_taken},
    {Kati.Screens.Medication, :mark_skipped},
    {Kati.Screens.Medication, :add},
    {Kati.Screens.Medication, :open_schedule},
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
    {Kati.Screens.AddIngredient, :edit_ingredient},
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
    {Kati.Screens.YearShare, :scope_All},
    {Kati.Screens.YearShare, :aspect_square},
    # The diagnostic's battery row opens the phone's own settings screen, which
    # Kati has no fence for — nothing in `native/LEDGER.md` launches an Android
    # settings intent, and the research is explicit that the exemption must be
    # reached by deep link rather than requested, because
    # `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` carries Play-policy risk. The row
    # is drawn, reachable and honest about waiting on that fence — the same
    # state screen 83's six link rows are in.
    {Kati.Screens.NotificationsHelp, :open_battery},
    # ── Screen 151, the notification-listener sheet. Both `Open system
    # settings` rows want the Android notification-listener settings intent,
    # which no fence in `native/LEDGER.md` launches — the same missing fence
    # `:open_battery` above is waiting on, one permission over. `:log_by_hand`
    # is NOT here: it pushes `Kati.Screens.LogListen`, because this sheet gates
    # auto-detecting a listen and hand-logging one is a screen Kati already has.
    {Kati.Screens.NotificationAccess, :open_settings},
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
    # "Screen"` and `watches_anime?: true`, so `:pick_screen` and
    # `:watches_yes` write the values already there while `:pick_books` and
    # `:watches_no` move the screen. `:music` is screen 150's own segment of
    # the header switch it draws; its sibling `:tv` leaves for screen 36.
    {Kati.Screens.AnimeFilter, :pick_screen},
    {Kati.Screens.AnimeFilter, :watches_yes},
    {Kati.Screens.AutoDetectMusic, :music},
    # ── Screen 69, the Persian book page.
    #
    # Its controls are screen 66's controls and are inert for the same reasons,
    # one language over: `finish` and `add_to_list` push screens that exist,
    # and `open_series`/`open_lending` push screens the design has not drawn.
    # The status and edition chips are the mirror of 66's, which write against a
    # shelved book and no-op against an empty one.
    #
    # Screen 66 carries the English half of this list above; a Persian mirror
    # that behaved differently from the page it mirrors would be the defect
    # worth catching, and it would show up as one of these going live alone.
    {Kati.Screens.BookDetailFa, :finish},
    {Kati.Screens.BookDetailFa, :add_to_list},
    {Kati.Screens.BookDetailFa, :open_series},
    {Kati.Screens.BookDetailFa, :open_lending},
    {Kati.Screens.BookDetailFa, :status_reading},
    {Kati.Screens.BookDetailFa, :status_finished},
    {Kati.Screens.BookDetailFa, :status_paused},
    {Kati.Screens.BookDetailFa, :status_did_not_finish},
    {Kati.Screens.BookDetailFa, :format_paperback},
    {Kati.Screens.BookDetailFa, :format_ebook},
    {Kati.Screens.BookDetailFa, :format_audiobook},
    # Screen 72's opening unit and its timer stop, the same two shapes screen
    # 70's list above carries.
    {Kati.Screens.LogProgressFa, :unit_page},
    {Kati.Screens.LogProgressFa, :stop_timer},
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
    {Kati.Screens.SearchIdle, :scope_All},
    # Screen 84's two link rows. Screen 83's six are above for the same reason
    # and this sheet reuses that screen's cards: every one opens a URL in the
    # platform browser, and Kati has no fence that does.
    {Kati.Screens.AttributionStates, :open_tmdb},
    {Kati.Screens.AttributionStates, :open_listenbrainz},
    # Screen 85's link rows, the Persian mirror of 83's. Same reason: every one
    # opens a URL in the platform browser and Kati has no fence that does.
    {Kati.Screens.AttributionFa, :open_tmdb},
    {Kati.Screens.AttributionFa, :open_tvmaze},
    {Kati.Screens.AttributionFa, :open_open_library},
    {Kati.Screens.AttributionFa, :open_musicbrainz},
    # Screen 82's TMDB key choice, opening on Kati's own — the already-selected
    # member of a family whose other half does move.
    {Kati.Screens.DataSourcesFa, :key_kati},
    # Screen 126's opening filter.
    {Kati.Screens.MoneyDay, :filter_All},
    # Screen 82's other key choice, and screen 93's two fields. `key_own` writes
    # through `Kati.Sources.put_tmdb_key/1` to `Mob.State`, which this heuristic
    # cannot see — the LanguagePick blind spot again, and covered by
    # `Kati.ServicesTest`. The two on 93 open no keyboard (#45).
    {Kati.Screens.DataSourcesFa, :key_own},
    {Kati.Screens.MyServicesEmpty, :search},
    {Kati.Screens.MyServicesEmpty, :edit_service},
    # Screen 99's scope chips. The board has one section's figures on it and
    # cannot follow them anywhere — relighting a chip over a card that did not
    # move is the one thing it exists to argue against. Its own moduledoc says
    # so, and 98 is where the choice is actually made.
    {Kati.Screens.YearShareBooks, :scope_All},
    {Kati.Screens.YearShareBooks, :scope_Books},
    {Kati.Screens.YearShareBooks, :scope_Screen},
    {Kati.Screens.YearShareBooks, :scope_Music},
    {Kati.Screens.YearShareBooks, :scope_Meals},
    {Kati.Screens.YearShareBooks, :scope_Habits},
    {Kati.Screens.YearShareBooks, :aspect_square},
    # Screen 97's third rule, the Persian mirror of 92's — the same `Mob.State`
    # blind spot the English entries above record.
    {Kati.Screens.MyServicesFa, :rule_hide_unavailable},
    # The opening chip on each of the four screens the third batch added. Same
    # already-selected case as every other family above: 87 and 90 open on All,
    # and 102 and 103 are 98's board with its own opening scope and ratio.
    {Kati.Screens.SearchTyping, :scope_All},
    {Kati.Screens.SearchFa, :scope_all},
    {Kati.Screens.YearShareDark, :scope_All},
    {Kati.Screens.YearShareDark, :aspect_square},
    {Kati.Screens.YearShareFa, :scope_All},
    {Kati.Screens.YearShareFa, :aspect_square},
    # Screen 113 draws screen 42's Meals tile as one of the states it is about.
    # A picture of a tile, not a tile.
    {Kati.Screens.HealthEmptyStates, :open_meals},
    # Screen 115's dose buttons and its opening range. The two writes land on
    # the first undecided dose of the day and there are none on an empty
    # database, which is the same no-op screen 112's English entries record.
    {Kati.Screens.HealthFa, :mark_taken},
    {Kati.Screens.HealthFa, :mark_skipped},
    {Kati.Screens.HealthFa, :range_month},
    # A dose row itself, which marks the same dose the `Taken` button does and
    # is the same no-op on an empty database.
    {Kati.Screens.Medication, :toggle_dose},
    # Screen 109's current range. The chart draws every reading whatever the
    # segment says — the range is drawn and not yet applied, because a series
    # of four readings has no month to narrow to. It narrows when there is
    # something to narrow.
    {Kati.Screens.Weight, :range_month},
    {Kati.Screens.Library, :shelf_Screen},
    {Kati.Screens.LibraryFa, :filter_0},
    {Kati.Screens.LibraryFa, :shelf_0},
    {Kati.Screens.MealsDay, :filter_All},
    {Kati.Screens.MealsMatrixFa, :view_0},
    {Kati.Screens.Nutrition, :period_Week},
    {Kati.Screens.ReleaseWatcher, :"cadence_Every 6h"},
    {Kati.Screens.Search, :filter_All},
    {Kati.Screens.Series, :season_S2},
    {Kati.Screens.Settings, :theme_Auto},
    {Kati.Screens.SettingsFa, :theme_0},

    # (`Kati.Screens.Calendar`'s selected day cell belongs in the group above
    # and cannot be written here: its tag carries today's ISO date, so a
    # literal would rot overnight. `inert_baseline/0` adds it.)

    # ── Backlog. Every tag in the family is inert, so the whole control does
    # nothing — a sheet that never opens, a button that never marks anything.
    # These reach a `_tag ->` catch-all (or, on a hand-rolled screen, the
    # `handle_info(_message, socket)` one), which is why `handle_tap/2 answers
    # every tag its screen draws` cannot see them. Delete a line as you wire it.
    {Kati.Screens.Activity, :open_filters},
    {Kati.Screens.Activity, :open_search},
    {Kati.Screens.Books, :open_books},
    {Kati.Screens.Books, :open_music},
    {Kati.Screens.Books, :open_search},
    {Kati.Screens.Books, :open_sort},
    {Kati.Screens.Health, :open_filters},
    # (`{Kati.Screens.Home, :open_calendar}` was here. #91 wired it: screen
    # 139's *Today* row carries the same tag as screen 01's header disc, and a
    # page borrowed from `Kati.Screens.HomeEmpty` could not ship with it still
    # dead. Struck off as this list's own header asks.)
    {Kati.Screens.Language, :add_language},
    {Kati.Screens.Library, :open_sort},
    {Kati.Screens.LibraryFa, :open_sort},
    {Kati.Screens.Meal, :more},
    {Kati.Screens.Meal, :save},
    {Kati.Screens.MealSwap, :swap_forever},
    {Kati.Screens.MealSwap, :swap_once},
    {Kati.Screens.MealsToday, :done_prepping},
    {Kati.Screens.MealsToday, :mark_eaten},
    {Kati.Screens.MealsToday, :open_week},
    {Kati.Screens.MealsToday, :see_tomorrow},
    {Kati.Screens.MealsToday, :swap},
    {Kati.Screens.MealsToday, :switch_plan},
    {Kati.Screens.Music, :open_search},
    {Kati.Screens.Music, :open_sort},
    {Kati.Screens.Music, :segment_books},
    {Kati.Screens.Music, :segment_music},
    {Kati.Screens.Nutrition, :share},
    {Kati.Screens.Rating, :add_tag},
    {Kati.Screens.ScheduleFa, :open_menu},
    {Kati.Screens.Subscriptions, :open_menu},
    # ── Blocked on a capability the app does not have. Screen 121 is the week
    # rendered as one printable page, and its button says Save image. Kati can
    # put a file into `ACTION_CREATE_DOCUMENT` or `ACTION_SEND` —
    # `Kati.Native.Files.save_as/2` and `share/2` — but it has no way to turn a
    # rendered screen into a bitmap to hand them, and no screen in the app does:
    # `Kati.Screens.YearCards.handle_tap/2` stubs its own save for exactly the
    # same reason. The tap is drawn because the button is drawn, and the button
    # is drawn because it is on the board. It stops being inert the day the
    # bridge gains a screen-to-bitmap call, and not before.
    {Kati.Screens.WeekImage, :save_image}
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
