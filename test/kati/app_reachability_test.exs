Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/sync_fixtures.exs", __DIR__)

defmodule Kati.AppReachabilityTest do
  @moduledoc """
  Every drawn screen a user can actually get to, and an inventory of the rest.

  ## The defect this exists for

  `Kati.Screens.Gallery` reaches all 62 screens by construction — it is a
  development scaffold, a list of every drawing. That makes it useless as
  evidence and actively misleading as a habit: a screen wired to nothing looks
  finished when you open it from the gallery, and half the app was in that
  state without anyone being able to say which half.

  `Kati.MealsRoutesTest` asks this question for the Meals section. This asks it
  for the whole app, and it is how the count went from 29 unreachable to 12.

  ## What the roots are

  The four shell roots, plus `Kati.Screens.LanguagePick`: on a fresh install
  `Kati.App.navigation/1` opens the stack on screen 53 and not on Home, so the
  first-run sequence is a second legitimate entry point rather than an orphan.
  The gallery is excluded on purpose — leaving it in makes the question
  unanswerable.

  ## Two stores, because half the doors in this app are rows

  A door is a rendered `on_tap`, and a rendered `on_tap` can depend on what is
  in the database. Until issue #91 that was invisible here, because every root
  answered an empty store with a `Sample` module: screen 03 drew nine invented
  films whether or not anything was tracked, so `:open_series` and `:open_film`
  were always on the tree and 04, 08, 14, 34 and 35 were always walkable. That
  fallback was the defect — a fresh install showed somebody else's shelf — and
  the roots now draw their real emptiness instead.

  The walk went with it. Six drawn destinations went dark in one commit and not
  one of them had moved: **04, 08, 14, 34, 35** behind screen 03's poster tiles,
  and **31** behind screen 02's event rows. The inventory was not wrong and the
  count was not wrong; the graph had stopped being the whole graph.

  So this walks **two stores and unions the result**, which is what "reachable"
  actually means — *there is a state this app can be in from which a user gets
  there*:

    * **a fresh install**, nothing stored. This is the only pass that sees the
      doors an empty state draws: screen 27's `Add a title` and `or import a
      backup` on the Library, which exist precisely because the shelf is empty.
    * **a device in use**, `populate!/0`'s rows written into the store and rolled
      back after. This is the only pass that sees the doors a row draws.

  Neither pass alone is the app. The empty pass strands the six above; the
  populated pass strands 21, 74 and 77, because a shelf with titles on it draws
  poster tiles where the empty card drew its two invitations. The union is
  exactly the 105 drawings a user can reach, against the 47 on `@no_route`.

  Nothing on that inventory changed for this, and nothing should have: the
  question "can a user get here" did not change its answer for a single screen.
  Only the walk's idea of what a user's phone looks like did.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens
  alias Kati.ScreenSweep
  alias Kati.SyncFixtures

  @roots [Screens.LanguagePick | Enum.map(Kati.Shell.roots(), & &1.screen)]

  # Screens with no in-app route, and why each one is allowed to have none.
  # An inventory, not an aspiration: wiring one fails this test, and the fix is
  # to delete its line.
  #
  # This list was twelve. Seven came off it when the overflow menu was designed
  # — every one of those seven was stranded behind a `more_horiz` the drawings
  # put in a header without ever drawing what it opens. What is left is five
  # screens that are not places in the app at all.
  @no_route [
    {Screens.States,
     "a catalogue of empty, loading and offline states for comparison against " <>
       "the drawing. Not a place in the app."},
    # The four states sheets the second wave of drawings added. Each is screen
    # 27's shape for one screen rather than for the app, and each is a reference
    # sheet for exactly the same reason: it draws all of a page's states at once,
    # so it is a picture of five situations rather than a situation the app can
    # be in.
    {Screens.BookDetailStates, "screen 66's states, in 27's manner. As above."},
    {Screens.LogProgressStates, "screen 70's states, in 27's manner. As above."},
    {Screens.AlbumDetailStates, "screen 74's states, in 27's manner. As above."},
    {Screens.ArtistDetailStates, "screen 77's states, in 27's manner. As above."},
    {Screens.DataSourcesStates, "screen 80's states, in 27's manner. As above."},
    {Screens.AttributionStates, "screen 83's states, in 27's manner. As above."},
    {Screens.MyServicesStates, "screen 92's states, in 27's manner. As above."},
    # Screen 100 is a RENDER SPEC, and says so: "the authoritative render spec...
    # so that whatever eventually writes the PNG has one page to be compared
    # against." Every figure on it is a specimen — four faces at two ratios —
    # correct for a spec and untrue of any reader. It had a Settings row under
    # About, argued from its own back pill saying `Settings`; a back pill names
    # the parent the sheet was DRAWN from, which is not the app promising a
    # reader a page. 101 is its states sheet and goes with it.
    # 148 and 152 went the way 100/101 went, one round later and for the same
    # reason. Each had a Settings row under About argued from its own back pill
    # saying `Settings`; a back pill names the parent a sheet was DRAWN from,
    # which is not the app promising a reader a page.
    #
    # What settles it is that both argue for features that now exist where a
    # reader actually meets them, so neither sheet is the only place the rule is
    # written down: the per-title anime override is screen 04's own ⋯ row and
    # the count is `Kati.Screens.Library.anime_chip/1`; paused, dropped and gone
    # cold are drawn on the shelf, and the decision between them is
    # `Kati.Screens.DropSheet`, off a title's ⋯ menu.
    {Screens.DropStates,
     "the one distinction the app makes about a shelf, written out for " <>
       "comparison against the drawing. The decision itself is screen 149, " <>
       "off a title's own menu."},
    {Screens.AnimeFilter,
     "the argument for a feature that exists: screen 04's anime toggle and " <>
       "the Library's fifth chip. A board about a rule, not a place in the app."},
    {Screens.AutoDetectMusic,
     "board 150, auto-detect for music. Every value on it is the drawing's — " <>
       "`3 SOURCES · 41 EPISODES, 128 TRACKS`, a now-playing card, four app " <>
       "switches — and Kati has no music detection: `Kati.Media.Detect` ticks " <>
       "films and episodes, and music is outside the film and series scope. " <>
       "Screen 36 stopped drawing the TV & film / Music control that led here, " <>
       "so the gallery is the only door until music detection exists."},
    {Screens.YearCards, "the year card's render spec, not a place in the app."},
    {Screens.YearCardsStates, "screen 100's states. As above."},
    {Screens.HomeOmittedSections,
     "the decision that an empty section is omitted rather than worded, drawn " <>
       "on a Persian Home so both cases can be seen at once. A board about a " <>
       "rule rather than a place in the app — screen 96's reason."},
    {Screens.HomeEmpty,
     "boards 139 and 158 are what `Kati.Screens.Home` draws, through " <>
       "`HomeEmpty.content/1`, when no section is chosen and nothing is kept. " <>
       "Nothing pushes the module since the first run's Skip lands on Home (N49): " <>
       "a skip always follows the sections step, so 139's Choose sections was " <>
       "an answer already given."},
    {Screens.HomeEmptyDark,
     "158 in the dark colourway — the same page in another colourway, " <>
       "reached by having dark on and having kept nothing."},
    {Screens.AddByHandDark,
     "screen 154 in the dark colourway. The same page in another colourway, " <>
       "reached by having dark on rather than by navigating — screen 28's " <>
       "reason, and it waits on the same fix."},
    {Screens.AddByHandStates,
     "screen 154's two states and the three decisions behind them, in 27's " <>
       "manner. A picture of two situations rather than a situation the app " <>
       "can be in."},
    {Screens.MyServicesEmpty,
     "screen 92 with nothing set up. `Kati.Screens.MyServices.content/1` " <>
       "CALLS this module's `content/1` when no service is stored — Home's " <>
       "own arrangement with screen 139 — so a user reaches it by having no " <>
       "services rather than by navigating, and nothing pushes it. The row " <>
       "that used to, `Show all 47`, was opening it over a page listing three " <>
       "subscriptions."},
    {Screens.MoneyStates, "screen 122's states, in 27's manner. As above."},
    {Screens.MealLibraryEmpty,
     "screen 116 with nothing in it, and the same board in Persian. The same " <>
       "screen in two states, not another one."},
    {Screens.GoalStates, "screen 104's states, in 27's manner. As above."},
    {Screens.GoalsEmpty,
     "screen 104 with nothing set. The same screen in a different state, not " <>
       "another one — reached by having no goals, not by navigating."},
    {Screens.WeightStates, "screen 109's states, in 27's manner. As above."},
    {Screens.HealthEmptyStates, "screen 42's empty states, in 27's manner. As above."},
    {Screens.MedicationEmpty,
     "screen 112 empty, with its two destinations, its reminder caption and " <>
       "the failure line annotated beside it — a board about one page rather " <>
       "than a second page. 27's reason, and 96's: reached by having no " <>
       "medications, not by navigating. The two destinations it names are " <>
       "both live from 112 itself."},
    {Screens.SearchTyping, "screen 86's three states before results, in 27's manner. As above."},
    {Screens.SearchResultStates,
     "screen 86's four result edge states, in 27's manner. As above."},
    {Screens.SearchLarge,
     "screen 86 at 235% text size. The same screen at a system setting, not " <>
       "another one — reached by changing the setting, not by navigating."},
    {Screens.YearShareBooks,
     "screen 98 with one scope selected, drawn so the two can be compared. A " <>
       "board about a choice rather than a place the choice is made — 98 is where " <>
       "you make it."},
    {Screens.NothingSetUpKnockOn,
     "what four other screens look like when no service is set up. A board " <>
       "about four screens rather than a fifth screen — 27's reason again."},
    {Screens.BookDetailDark,
     "screen 66 in the dark colourway. The same screen, not another one — " <>
       "reached by changing the theme, not by navigating, exactly as 28 is."},
    {Screens.HomeDark,
     "screen 01 in the dark colourway. The same screen, not another one — " <>
       "reached by changing the theme, not by navigating."},
    # ── The 24 August batch: #25, #11, #12, #15, #17, #19, #20, #21 ──────
    #
    # Every one below is 27's reason again in one of its three forms — a
    # states sheet, a colourway, or a type size. None is a place the app can
    # be in; each is a picture of places it can be in.
    {Screens.BackupStates,
     "screens 128 and 129's eight states at once, in 27's manner. As above."},
    {Screens.BackupDark,
     "screen 128 in the dark colourway. The same screen, not another one — " <>
       "reached by changing the theme, exactly as 28, 68 and 102 are."},
    {Screens.BackupLarge,
     "screens 128 and 129 at 235% text size. The same screens at a system " <>
       "setting, not other ones — reached by changing the setting, as 91 is."},
    {Screens.OnboardingLarge, "the onboarding chain at 235%. As above."},
    {Screens.ImportStates,
     "screen 140's edge states, in 27's manner. As above — and #4 has since " <>
       "shipped the states themselves: 141 draws its refusal card with `Pick " <>
       "again` live, and its wrong-guess note over a file that still reads."},
    {Screens.ShelfLarge, "screens 145 and 146 at 235%. As above."},
    {Screens.EpisodeRatings,
     "screen 04's episode rows with the rating column added, drawn so the " <>
       "before and after can be compared. A board about a change to 04, not a " <>
       "screen beside it — and the change has shipped: " <>
       "`Kati.Screens.Series.rating_column/1` draws that column beside every " <>
       "aired episode on 04 and 34, and opens screen 144 over the one you " <>
       "tapped."},
    # 65 — the drawing of Kati seen from outside the app. The lock screen (29)
    # and the two launchers (63, 64) were the others and are deleted, their
    # boards in `test/design/retired/`; this one stays because it is the frame
    # the app itself puts up.
    {Screens.LaunchScreen,
     "the frame the app puts up while it boots, drawn as a picture of itself. " <>
       "Reached by launching Kati, and by the time anything could navigate it " <>
       "is already gone."}
  ]

  # N52-D. The meal, health, goals and money pages. Their doors were Home's
  # Meals tile and Stats' More numbers rows, and every one of these pages still
  # draws sample data, so both doors are hidden until the section is real.
  @hidden_section "a section page that still draws sample data. Its doors — " <>
                    "Home's Meals tile and Stats' More numbers rows — are hidden " <>
                    "until the section reads the reader's own data (N52-D)."
  @no_route @no_route ++
              Enum.map(
                [
                  Screens.Health,
                  Screens.MealsToday,
                  Screens.MealPlan,
                  Screens.Meal,
                  Screens.MealSwap,
                  Screens.Nutrition,
                  Screens.Shopping,
                  Screens.Plans,
                  Screens.PlanShare,
                  Screens.MealReminders,
                  Screens.Goals,
                  Screens.NewGoal,
                  Screens.Money,
                  Screens.Weight,
                  Screens.LogWeight,
                  Screens.Medication,
                  Screens.MealLibrary,
                  Screens.MealEdit,
                  Screens.AddIngredient,
                  Screens.PlanImport,
                  Screens.WeekImage,
                  Screens.AddMedication,
                  Screens.MedicationDetail
                ],
                &{&1, @hidden_section}
              )

  test "every drawn screen is reachable, or is on the inventory with a reason" do
    reached = reachable(push_graph(), @roots)
    exempt = MapSet.new(Enum.map(@no_route, &elem(&1, 0)))

    stranded =
      for {number, _label, module, _kind} <- Screens.Gallery.screens(),
          not MapSet.member?(reached, module),
          not MapSet.member?(exempt, module),
          do: "  #{number}  #{inspect(module)}"

    assert stranded == [],
           "these screens are drawn but a user cannot get to them, and they are " <>
             "not on the @no_route inventory:\n" <> Enum.join(stranded, "\n")
  end

  test "the inventory has no stale entries" do
    reached = reachable(push_graph(), @roots)

    wired =
      for {module, why} <- @no_route,
          MapSet.member?(reached, module),
          do: "  #{inspect(module)} — listed as: #{why}"

    assert wired == [],
           "these are reachable now. Delete their lines from @no_route:\n" <>
             Enum.join(wired, "\n")
  end

  test "a screen retired from the gallery is one the app can actually reach" do
    reached = reachable(push_graph(), @roots)
    exempt = MapSet.new(Enum.map(@no_route, &elem(&1, 0)))

    stranded =
      for {number, label, module, _kind} <- Screens.Gallery.screens(),
          number in Screens.Gallery.routed(),
          not MapSet.member?(reached, module) or MapSet.member?(exempt, module),
          do: "  #{number}  #{label}  #{inspect(module)}"

    assert stranded == [],
           "these screens have been taken out of Settings > Every screen as " <>
             "finished, and the walk cannot reach them — so they are now in the " <>
             "app with no door at all. Put the number back in " <>
             "`Kati.Screens.Gallery`'s `@routed` only once the route is " <>
             "there:\n" <> Enum.join(stranded, "\n")
  end

  test "the roots are themselves drawn screens" do
    drawn = MapSet.new(Screens.Gallery.screens(), fn {_, _, m, _} -> m end)

    for root <- @roots do
      assert MapSet.member?(drawn, root), "#{inspect(root)} is a root but has no drawing"
    end
  end

  test "the count is what the inventory says it is" do
    # Guards the two tests above against both going quiet at once — an empty
    # graph would satisfy "no stale entries" and a graph reaching everything
    # would satisfy "nothing stranded".
    reached = reachable(push_graph(), @roots)
    drawn = MapSet.new(Screens.Gallery.screens(), fn {_, _, m, _} -> m end)

    # Intersected with the drawings: the walk also reaches `Kati.Screens.Gallery`
    # itself, which screen 01's bell opens, and it is scaffold rather than one
    # of the 62.
    reached_drawings = MapSet.intersection(reached, drawn)
    total = MapSet.size(drawn)

    assert MapSet.size(reached_drawings) == total - length(@no_route),
           "reachable #{MapSet.size(reached_drawings)} + inventory " <>
             "#{length(@no_route)} should account for all #{total} drawings"
  end

  defp push_target(module, socket, tag) do
    case module.handle_info({:tap, tag}, socket) do
      {:noreply, %Mob.Socket{__mob__: %{nav_action: {:push, dest, _}}}} ->
        dest

      {:noreply, %Mob.Socket{__mob__: %{nav_action: r}}}
      when is_tuple(r) and elem(r, 0) == :reset ->
        elem(r, 1)

      _ ->
        nil
    end
  end

  # One step past the resting screen, because an overflow menu's items do not
  # exist until it is open.
  #
  # `Kati.UI.Menu` renders nothing but its trigger when closed — a hidden panel
  # is still a window the bridge has to position, so a menu nobody opened costs
  # nothing — which means a walk over freshly mounted screens sees `:toggle_menu`
  # and none of the three destinations behind it. Screen 35 went from reachable
  # to stranded the moment screen 04's ⋯ became a menu, and it had not moved.
  #
  # So: collect the tags a screen draws, and for every tag that changes the
  # screen without navigating, re-render and collect again. One level is
  # enough — a menu inside a menu is not a thing any of these drawings has —
  # and the recursion is bounded by that rather than by a visited set.
  # Rolled back, because a few of the tags this dispatches are commits — see
  # `Kati.ScreenSweep.rolled_back/1` for the defect that made it necessary.
  #
  # Memoised for the run, because three of the four tests below ask the same
  # question of the same graph and building it is two passes over 156 screens.
  # Same mechanism and the same reason as `Kati.ScreenSweep.drawn_taps/1`: a
  # graph depends only on code, which does not change inside a run.
  defp push_graph do
    key = {__MODULE__, :push_graph}

    case :persistent_term.get(key, :miss) do
      :miss ->
        graph = build_graph()
        :persistent_term.put(key, graph)
        graph

      graph ->
        graph
    end
  end

  # The union of the two stores. See the moduledoc for why one of them is not
  # enough — and note the direction of the merge does not matter, because a
  # union is a union; `Enum.uniq/1` is tidiness, not correctness.
  defp build_graph do
    Map.merge(
      with_stored_settings(&fresh_install_edges/0),
      with_stored_settings(&in_use_edges/0),
      fn _module, empty, in_use -> Enum.uniq(empty ++ in_use) end
    )
    |> Map.merge(with_stored_settings(&locale_forks/0), fn _m, a, b -> Enum.uniq(a ++ b) end)
  end

  # The three taps whose destination is the locale, taken both ways.
  #
  # The pass above runs in one locale, which is the right shape for a graph of
  # a single app — but three controls answer `Kati.Locale` rather than a
  # module, and in one locale the walk sees one of their two destinations.
  #
  # Which one it saw used to be decided by tag ORDER, which is worse. Screen
  # 53's tags come off the tree as `[:choose_en, :choose_fa, :continue]` and
  # each was evaluated against the store the tag before it left, so `continue`
  # answered after `choose_fa` had written فارسی — and every module rendered
  # after 53 in the same comprehension inherited that. `pinned/1` below is what
  # stopped a tap deciding the next tap's answer; this is what puts back the
  # branch it removed.
  #
  # A whole second pass in `:fa` is the general form and costs a render of
  # every screen in the app. Three controls need it, and they are named here
  # rather than swept for.
  @locale_forks [
    {Screens.LanguagePick, :continue},
    {Screens.AddTitle, :add_by_hand},
    {Screens.Search, :add_by_hand},
    # mishka-group/kati#103 moved three forks rather than removing them. 164,
    # 165 and 166 are the English steps rendered under `:fa` now, so screen 53's
    # `continue` answers ONE module and the forks travel one step further in:
    # step 2's `next` is 26 or 137, its `restore` is 55 or 84, and step 5's
    # `skip` is 139 or 158. Each of those three destinations is still a mirror,
    # so each is still a fork — and 137 and 158 have no other door at all.
    {Screens.OnboardingWelcome, :next},
    {Screens.OnboardingWelcome, :restore},
    {Screens.OnboardingFirstTitle, :skip}
  ]

  defp locale_forks do
    for {module, tag} <- @locale_forks, locale <- [:en, :fa], reduce: %{} do
      acc ->
        edges =
          ScreenSweep.rolled_back(fn ->
            ScreenSweep.with_locale(locale, fn ->
              case ScreenSweep.render(module) do
                {:ok, socket, tree} ->
                  # This tag only, and from a socket mounted in this locale.
                  # Handing the whole tag list to `targets/3` would defeat the
                  # point on screen 53: `choose_fa` sits before `continue` in
                  # draw order and writes the setting `continue` reads.
                  #
                  # Typed first, because board 308 put screen 06's own fork one
                  # keystroke away: the add-by-hand row is absent before a
                  # keystroke, since it NAMES the query and there is none. A
                  # fork that only appears after typing is still a fork.
                  {socket, tree} = Kati.AppReachabilityTest.after_typing(module, socket, tree)

                  if tag in ScreenSweep.tap_tags(tree),
                    do: targets(module, socket, [tag]),
                    else: []

                _unrenderable ->
                  []
              end
            end)
          end)

        Map.update(acc, module, edges, &Enum.uniq(&1 ++ edges))
    end
  end

  defp fresh_install_edges do
    ScreenSweep.rolled_back(fn -> edges(ScreenSweep.drawn_taps(:en)) end)
  end

  # The same walk over a store with rows in it.
  #
  # Deliberately NOT through `Kati.ScreenSweep.drawn_taps/1`: that memo is keyed
  # by locale alone and is handed to two other sweeps that mean it to be the
  # empty store. Filling it from inside this transaction would hand them a
  # populated one, and the rows would be gone by the time they read it.
  defp in_use_edges do
    ScreenSweep.rolled_back(fn ->
      populate!()
      edges(ScreenSweep.with_locale(:en, &drawn_taps_now/0))
    end)
  end

  defp drawn_taps_now do
    for module <- ScreenSweep.screens(),
        {:ok, socket, tree} <- [ScreenSweep.render(module)],
        into: %{},
        do: {module, {socket, ScreenSweep.tap_tags(tree)}}
  end

  defp edges(taps) do
    ScreenSweep.with_locale(:en, fn ->
      for {module, {socket, tags}} <- taps,
          module != Screens.Gallery,
          into: %{} do
        {module,
         targets(module, socket, tags) ++
           opened_targets(module, socket, tags) ++
           typed_targets(module, socket)}
      end
    end)
  end

  # Rows a real device has, written by this test and rolled back with the rest
  # of the pass. A fixture in the store, never a `Sample` module rendered to
  # anybody — that distinction is the whole of issue #91, and the four roots'
  # moduledocs spend their length on it.
  #
  # Every row here exists to open a door the empty store cannot draw, and the
  # test that fails when one goes missing names the screen:
  #
  #   * a tracked **series** and a tracked **film** put two poster tiles on
  #     screen 03's shelf. `Kati.Screens.Library.poster/1` picks the tag off the
  #     kind — `:open_series` or `:open_film` — so it takes one of each to reach
  #     04 and 08, and 04's overflow menu is the only route to 14, 34 and 35.
  #   * one **event today** puts a row on screen 02's day. `row_event_*` is
  #     the only route to 31.
  #
  # A cached title with no `title` is dropped by `Kati.Screens.Library.shelf/0`
  # and a watch is not needed by any of it, so this is the smallest store that
  # draws both tiles.
  defp populate! do
    track!(:tv, "The Long Hollow", "hollow71")
    track!(:movie, "Blue Hour", "bluehour58")

    today = Kati.Time.today()

    SyncFixtures.event!(SyncFixtures.calendar!(), %{
      summary: "Standup",
      dtstart_utc: DateTime.new!(today, ~T[09:00:00.000000], "Etc/UTC"),
      duration_iso: "PT30M"
    })
  end

  defp track!(kind, title, seed) do
    source_id = "reachability:#{System.unique_integer([:positive])}"

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: title,
      # A design seed rather than a TMDB path, so the tile resolves its
      # artwork through `Kati.Design.Images.poster/1`.
      poster_path: seed,
      fetched_at: Kati.Time.now()
    })
    |> Ash.create!()

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching,
      progress_season: if(kind == :tv, do: 1)
    })
    |> Ash.create!()

    if kind == :tv, do: episode!(source_id)
  end

  # One cached episode for the tracked series, and it is the difference between
  # a populated store and a populated store a user would recognise. A series
  # you are watching has episodes; this one had none, so screen 04 drew its
  # "nothing cached yet" state in the pass that is supposed to be the device in
  # use — and every door an episode ROW draws was invisible to the walk.
  #
  # That is not hypothetical. Screen 144 is reached by tapping the rating
  # column beside an episode (`Kati.Screens.Series.rating_column/1`), which is
  # drawn per episode and cannot exist without one, and the walk called it
  # stranded on the day that route shipped.
  #
  # Two seasons rather than one, and a bookmark in the first, for screen 153.
  # Screen 34 draws its order strip — and the help disc beside it, the only
  # route to 153 — only over a season it can find and a show that can be
  # numbered two ways; a series of one season numbers absolutely exactly as it
  # does by season, and a bare push to 34 opens the bookmarked season.
  defp episode!(title_source_id) do
    for {season, title} <- [{1, "The Weight of Water"}, {2, "Low Tide"}] do
      Kati.Media.CachedEpisode
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        title_source_id: title_source_id,
        source_id: "#{title_source_id}:s#{season}e1",
        season_number: season,
        episode_number: 1,
        title: title,
        runtime_minutes: 48,
        fetched_at: Kati.Time.now()
      })
      |> Ash.create!()
    end
  end

  # `Mob.State` is the third global a tap pass writes to, and the only one
  # nothing was guarding.
  #
  # A pass presses every control every screen draws, and some of those controls
  # are settings: screen 141's section toggles land in `Kati.Sections`, which is
  # `Mob.State`. `Kati.Screens.Library.kept_segments/1` then draws a segment per
  # section kept — so a first pass that switched Music off leaves the second
  # pass looking at a shelf switcher with no `:shelf_Music` on it, and 21, 74
  # and 77 vanish from a graph that has nothing to do with sections. Measured,
  # not feared: that is exactly what the two passes did before this existed.
  #
  # `Kati.ScreenSweep.rolled_back/1` is this guard for the database and
  # `with_theme/1` is it for the palette; the whole table goes back rather than
  # one key, because the next setting a screen learns to write should not need
  # anyone to remember this function.
  defp with_stored_settings(fun) do
    stored = Mob.State.match(:_)

    try do
      fun.()
    after
      for {key, _value} <- Mob.State.match(:_), do: Mob.State.delete(key)
      for {key, value} <- stored, do: Mob.State.put(key, value)
    end
  end

  # The locale is re-pinned around EVERY tap, not once around the pass.
  #
  # Screen 53's taps write `Kati.Locale`, and the tags come off a tree in draw
  # order — `[:choose_en, :choose_fa, :continue]` — so `continue` was answered
  # against a store `choose_fa` had just written, and every module rendered
  # after 53 in the same comprehension inherited it. Anything that routes on
  # the locale then answered for a reader who had not chosen: the first run's
  # five steps, and `Kati.Screens.AddByHand.for_locale/0`. The graph was
  # smaller than the app and the count still balanced, because the screens it
  # lost were on `@no_route` for unrelated reasons.
  #
  # Cheap, because it is a comparison and only writes when the answer moved.
  defp targets(module, socket, tags) do
    for tag <- tags,
        {:ok, dest} <- [
          ScreenSweep.safely(fn -> pinned(fn -> push_target(module, socket, tag) end) end)
        ],
        is_atom(dest),
        dest != nil,
        uniq: true,
        do: dest
  end

  defp pinned(fun) do
    before = Kati.Locale.current()

    try do
      fun.()
    after
      if Kati.Locale.current() != before, do: Kati.Locale.put(before)
    end
  end

  defp opened_targets(module, socket, tags) do
    for tag <- tags,
        {:ok, opened} <-
          [ScreenSweep.safely(fn -> pinned(fn -> open_only(module, socket, tag) end) end)],
        opened != nil,
        {:ok, tree} <- [ScreenSweep.safely(fn -> module.render(opened.assigns) end)],
        dest <- targets(module, opened, ScreenSweep.tap_tags(tree)),
        uniq: true,
        do: dest
  end

  # The same move for a field rather than a control. **A door that only appears
  # after a keystroke is invisible to a walk that only taps**, and board 308
  # made screen 06's add-by-hand row exactly that: absent before a keystroke,
  # because it names the query and there is none. `Kati.Screens.AddByHandFa`
  # went unreachable here while staying one letter away for a person.
  #
  # `@typed` is two characters because that is the app's own floor
  # (`Kati.Search.long_enough?/1`), and a word rather than a letter so a screen
  # that searches on it has something to search for.
  # Re-rendered here rather than carried on the memo: `ScreenSweep.drawn_taps/1`
  # is shared with four other sweeps that destructure its 2-tuple, and widening
  # it for one caller is a change to all of them.
  defp typed_targets(module, socket) do
    with {:ok, tree} <- ScreenSweep.safely(fn -> module.render(socket.assigns) end) do
      typed_targets(module, socket, tree)
    else
      _unrenderable -> []
    end
  end

  defp typed_targets(module, socket, tree) do
    for tag <- ScreenSweep.change_tags(tree),
        {:ok, typed} <-
          [ScreenSweep.safely(fn -> pinned(fn -> typed_only(module, socket, tag) end) end)],
        typed != nil,
        {:ok, after_typing} <- [ScreenSweep.safely(fn -> module.render(typed.assigns) end)],
        dest <- targets(module, typed, ScreenSweep.tap_tags(after_typing)),
        uniq: true,
        do: dest
  end

  @typed "up"

  @doc false
  @spec after_typing(module(), Mob.Socket.t(), term()) :: {Mob.Socket.t(), term()}
  def after_typing(module, socket, tree) do
    ScreenSweep.change_tags(tree)
    |> Enum.reduce({socket, tree}, fn tag, {so_far, drawn} ->
      with typed when not is_nil(typed) <- typed_only(module, so_far, tag),
           {:ok, redrawn} <- ScreenSweep.safely(fn -> module.render(typed.assigns) end) do
        {typed, redrawn}
      else
        _unchanged -> {so_far, drawn}
      end
    end)
  end

  defp typed_only(module, socket, tag) do
    case module.handle_info({:change, tag, @typed}, socket) do
      {:noreply, %Mob.Socket{__mob__: %{nav_action: nil}} = moved} ->
        if moved.assigns == socket.assigns, do: nil, else: moved

      _ ->
        nil
    end
  end

  # A tap that changed the assigns and navigated nowhere — opening a panel,
  # switching a filter. Anything that navigates is already an edge.
  defp open_only(module, socket, tag) do
    case module.handle_info({:tap, tag}, socket) do
      {:noreply, %Mob.Socket{__mob__: %{nav_action: nil}} = moved} ->
        if moved.assigns == socket.assigns, do: nil, else: moved

      _ ->
        nil
    end
  end

  defp reachable(graph, from), do: walk(graph, from, MapSet.new())
  defp walk(_g, [], seen), do: seen

  defp walk(g, [m | rest], seen) do
    if MapSet.member?(seen, m),
      do: walk(g, rest, seen),
      else: walk(g, Map.get(g, m, []) ++ rest, MapSet.put(seen, m))
  end
end
