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
    {Screens.HomeFaEmpty,
     "screen 55 with nothing stored, and the Persian pair of 139. Reached by " <>
       "having kept nothing, not by navigating — the same reason " <>
       "`Kati.Screens.HomeEmpty` is here, and it sits beside it."},
    {Screens.AddByHandFa,
     "screen 154 in the mirror, stranded exactly as `Kati.Screens.RestoreFa` " <>
       "and `Kati.Screens.OnboardingFa` are: screen 89's row pushes the " <>
       "English form, and routing every mirror by locale is #93's third " <>
       "criterion rather than one `if` per row that opens one."},
    {Screens.AddByHandDark,
     "screen 154 in the dark colourway. The same page in another colourway, " <>
       "reached by having dark on rather than by navigating — screen 28's " <>
       "reason, and it waits on the same fix."},
    {Screens.AddByHandStates,
     "screen 154's two states and the three decisions behind them, in 27's " <>
       "manner. A picture of two situations rather than a situation the app " <>
       "can be in."},
    {Screens.YearCardsStates, "screen 100's states, in 27's manner. As above."},
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
    {Screens.SearchTyping, "screen 86's three states before results, in 27's manner. As above."},
    {Screens.SearchResultStates,
     "screen 86's four result edge states, in 27's manner. As above."},
    {Screens.SearchLarge,
     "screen 86 at 235% text size. The same screen at a system setting, not " <>
       "another one — reached by changing the setting, not by navigating."},
    {Screens.YearShareDark,
     "screen 98 in the dark colourway. The same screen, not another one — " <>
       "reached by changing the theme, exactly as 28 and 68 are."},
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
    {Screens.Lock,
     "a drawing of the OS lock screen showing Kati's notification. Nothing in " <>
       "an app can navigate to the lock screen."},
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
    {Screens.RestoreFa,
     "screen 129 in Persian. The same screen, not another one — reached by " <>
       "choosing فارسی, exactly as every other Persian mirror is."},
    {Screens.OnboardingFa, "the onboarding chain in Persian. As above."},
    {Screens.OnboardingLarge, "the onboarding chain at 235%. As above."},
    {Screens.ImportStates, "screen 140's edge states, in 27's manner. As above."},
    {Screens.ShelfLarge, "screens 145 and 146 at 235%. As above."},
    {Screens.DropStates,
     "the drop, DNF and abandon states across all three media at once, in " <>
       "27's manner — a board about five states rather than a sixth place."},
    {Screens.AnimeFilter,
     "a board about one change landing on four existing screens — 03's chip, " <>
       "26's sub-choice, 37's two tiles, 35's numbering row. 96's reason: a " <>
       "board about four screens rather than a fifth screen."},
    {Screens.EpisodeRatings,
     "screen 04's episode rows with the rating column added, drawn so the " <>
       "before and after can be compared. A board about a change to 04, not a " <>
       "screen beside it."},
    # ── Drawn, built, and waiting on an entry point ──────────────────────
    #
    # These eight are NOT reference sheets. Each is a real destination whose
    # own board draws the control that opens it — and that control belongs on a
    # PARENT screen the 23 August export did not redraw. Adding it anyway would
    # mean inventing a control on a board that does not have one, which is the
    # one thing the design pipeline in this repo does not allow.
    #
    # Each entry names the edit it is waiting for, so this list stays a queue
    # rather than becoming a graveyard.
    {Screens.LoudnessPrompt,
     "the three outcomes of 38·3's loudness choice. Its entry is 38·3 itself " <>
       "routing forward, which needs 38 renumbered to five steps — the flow " <>
       "map (134) names that as the build task."},
    {Screens.RateEpisode,
     "screen 33 in its episode variant. Its entry is a LONG PRESS on an " <>
       "episode row in screen 04, and 04's board has not been redrawn to carry " <>
       "the affordance hint that teaches it. #15."},
    {Screens.ShelfFilters,
     "the shelf filter sheet. Its entry is a trailing filter disc in the " <>
       "header of screens 03, 20 and 21, and none of the three boards has been " <>
       "redrawn with it. #19."},
    {Screens.ShelfSelection,
     "the shelf in selection mode. Its entry is a LONG PRESS on a poster " <>
       "tile — the same gesture 04 uses for a different meaning, which #15 and " <>
       "#19 agree has to be decided on both boards before either ships it."},
    {Screens.DropSheet,
     "the drop sheet. Its entry is a Drop action on a title, and the three " <>
       "detail boards (04, 66, 74) have not been redrawn with it. #17."},
    {Screens.AutoDetectMusic,
     "auto-detect in music mode. #20 draws it as a MODE of screen 36 rather " <>
       "than a second screen, so its entry is a mode switch at the top of 36 — " <>
       "drawn on 150 and not yet on 36. `Kati.Screens.AutoDetect.handle_tap/2` " <>
       "already answers `:open_music`; only the control is missing."},
    {Screens.NotificationAccess,
     "the special-access row. Reached from 150, which is itself waiting."},
    {Screens.NumberingScheme,
     "the per-show numbering row. Its entry is a row on screen 35, whose " <>
       "board has not been redrawn. #21."},
    {Screens.HomeEmpty,
     "screen 01 with nothing set up. The same screen in the state a skipped " <>
       "onboarding leaves it in — reached by skipping, not by navigating, " <>
       "exactly as 105 and 117 are."},
    # 63, 64 and 65 — the three drawings of Kati seen from outside the app.
    # 29's reason, three more times: an app cannot navigate to the surface it
    # is being launched from.
    {Screens.MarkIos,
     "a drawing of an iOS home screen with Kati's icon on it. Nothing in an " <>
       "app can navigate to the launcher — 29's reason exactly, and 63's own " <>
       "moduledoc names 29 as its precedent."},
    {Screens.MarkAndroid, "the same drawing on an Android launcher. As above."},
    {Screens.LaunchScreen,
     "the frame the app puts up while it boots, drawn as a picture of itself. " <>
       "Reached by launching Kati, and by the time anything could navigate it " <>
       "is already gone."}
  ]

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
      {:noreply, %Mob.Socket{__mob__: %{nav_action: {:push, dest, _}}}} -> dest
      {:noreply, %Mob.Socket{__mob__: %{nav_action: {:reset, dest, _}}}} -> dest
      _ -> nil
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
  end

  # Nothing stored. `Kati.ScreenSweep.drawn_taps/1`'s memo IS this pass — it is
  # what `Kati.ScreenTapSweepTest` and `Kati.MealsRoutesTest` both mount against
  # — so this half is shared with them rather than paid for twice.
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
        {module, targets(module, socket, tags) ++ opened_targets(module, socket, tags)}
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
      # `Kati.Seeds` stores the design's seed here, so the tile resolves its
      # artwork through `Kati.Design.Images.poster/1` the way a seeded row does.
      poster_path: seed,
      fetched_at: Kati.Time.now()
    })
    |> Ash.create!()

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching
    })
    |> Ash.create!()
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

  defp targets(module, socket, tags) do
    for tag <- tags,
        {:ok, dest} <- [ScreenSweep.safely(fn -> push_target(module, socket, tag) end)],
        is_atom(dest),
        dest != nil,
        uniq: true,
        do: dest
  end

  defp opened_targets(module, socket, tags) do
    for tag <- tags,
        {:ok, opened} <- [ScreenSweep.safely(fn -> open_only(module, socket, tag) end)],
        opened != nil,
        {:ok, tree} <- [ScreenSweep.safely(fn -> module.render(opened.assigns) end)],
        dest <- targets(module, opened, ScreenSweep.tap_tags(tree)),
        uniq: true,
        do: dest
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
