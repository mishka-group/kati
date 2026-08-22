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
  @no_route [
    {Screens.Books,
     "#60 settled that v1 ships one media domain. Screen 03 greys " <>
       "Books and Music, and 20's own moduledoc says Music is 'drawn but inert, " <>
       "exactly as screen 03 draws Books and Music'."},
    {Screens.Music, "as above — #60."},
    {Screens.States,
     "a catalogue of empty, loading and offline states for " <>
       "comparison against the drawing. Not a place in the app."},
    {Screens.HomeDark,
     "screen 01 in the dark colourway. The same screen, not " <>
       "another one — reached by changing the theme, not by navigating."},
    {Screens.Lock,
     "a drawing of the OS lock screen showing Kati's notification. " <>
       "Nothing in an app can navigate to the lock screen."},
    {Screens.WhatFits,
     "no drawn entry. 13's back pill reads Library and its " <>
       "header carries a more_horiz, but screen 03 draws no header overflow."},
    {Screens.SeriesMeta, "no drawn entry, same shape as 13."},
    {Screens.QuickAdd,
     "no drawn entry. The FAB opens Kati.Screens.AddTitle, " <>
       "which is the drawn add flow; 18 is a second one with no control naming it."},
    {Screens.Rating,
     "no drawn entry. Screen 04's episode rows toggle watched; " <>
       "nothing draws a way to open a rating sheet."},
    {Screens.Season,
     "no drawn entry. Screen 04's season pills switch in place " <>
       "and its more_horiz already opens Series settings, which draws no " <>
       "episode-order row."},
    {Screens.MealReminders,
     "no drawn entry — checked glyph by glyph in that " <>
       "screen's own moduledoc. Screen 43's more_horiz belongs to the next meal " <>
       "card, not to the header."},
    {Screens.MealsDay,
     "no drawn entry. 52's back pill reads Calendar, but the " <>
       "day screen draws Personal/Money/Screen filters and no Meals one."}
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

  defp push_graph do
    ScreenSweep.with_locale(:en, fn ->
      for {module, {socket, tags}} <- ScreenSweep.drawn_taps(:en),
          module != Screens.Gallery,
          into: %{} do
        targets =
          for tag <- tags,
              {:ok, dest} <- [ScreenSweep.safely(fn -> push_target(module, socket, tag) end)],
              is_atom(dest),
              dest != nil,
              uniq: true,
              do: dest

        {module, targets}
      end
    end)
  end

  defp reachable(graph, from), do: walk(graph, from, MapSet.new())
  defp walk(_g, [], seen), do: seen

  defp walk(g, [m | rest], seen) do
    if MapSet.member?(seen, m),
      do: walk(g, rest, seen),
      else: walk(g, Map.get(g, m, []) ++ rest, MapSet.put(seen, m))
  end
end
