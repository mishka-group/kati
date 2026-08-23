Code.require_file("../support/screen_sweep.exs", __DIR__)

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
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens
  alias Kati.ScreenSweep

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
    {Screens.SearchSpec,
     "the search contract, drawn as its own board. A specification for the " <>
       "build to be compared against rather than a place in the app — screen 27's " <>
       "own reason, one subject over."},
    {Screens.BookDetailDark,
     "screen 66 in the dark colourway. The same screen, not another one — " <>
       "reached by changing the theme, not by navigating, exactly as 28 is."},
    {Screens.HomeDark,
     "screen 01 in the dark colourway. The same screen, not another one — " <>
       "reached by changing the theme, not by navigating."},
    {Screens.Lock,
     "a drawing of the OS lock screen showing Kati's notification. Nothing in " <>
       "an app can navigate to the lock screen."}
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
  defp push_graph do
    ScreenSweep.rolled_back(fn ->
      ScreenSweep.with_locale(:en, fn ->
        for {module, {socket, tags}} <- ScreenSweep.drawn_taps(:en),
            module != Screens.Gallery,
            into: %{} do
          {module, targets(module, socket, tags) ++ opened_targets(module, socket, tags)}
        end
      end)
    end)
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
