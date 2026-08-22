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
  # function call — three tables named explicitly, and the list grows the day a
  # new sheet starts committing.
  setup do
    on_exit(fn ->
      for table <- ~w(goals expenses health_readings) do
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
    # nothing: neither a service search nor a per-service editor is drawn
    # anywhere in the 127 artboards.
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
    {Kati.Screens.Home, :open_calendar},
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
    {Kati.Screens.Subscriptions, :open_menu}
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
end
