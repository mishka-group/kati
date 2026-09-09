defmodule Kati.ShelfRoutesTest do
  @moduledoc """
  The three shelves are one control drawn three times, and it works from all
  three.

  Screens 03, 20 and 21 each draw the same segmented row — Screen, Books,
  Music. Only 03 answered all of it: from Books, **Music** did nothing, and
  from Music, **Books** did nothing. So a reader who went Screen → Books had
  one way back and no way across, which is what a tab that does not work looks
  like from the outside.

  ## Why crossing pushes and returning to Screen resets

  `Kati.Screens.Library` is a dock root and the other two are pushed from it.
  So returning to Screen has to RESET the stack — otherwise the dock would sit
  underneath a pushed page — while crossing between Books and Music PUSHES,
  which is exactly what 03's own `shelf_Books` and `shelf_Music` already did.

  One rule, read off the screen that already had it. The alternative was
  inventing a second rule here and having the three shelves disagree about what
  the back gesture means.
  """
  use Mob.ScreenCase, async: false

  # `{from, tag, to}` — every segment on every shelf that moves.
  # `{from, tag, to, action}` — every segment on every shelf that moves, and
  # which kind of move it is.
  @moves [
    {Kati.Screens.Library, :shelf_Books, Kati.Screens.Books, :push},
    {Kati.Screens.Library, :shelf_Music, Kati.Screens.Music, :push},
    {Kati.Screens.Books, :open_screen, Kati.Screens.Library, :reset},
    {Kati.Screens.Books, :open_music, Kati.Screens.Music, :push},
    {Kati.Screens.Music, :segment_screen, Kati.Screens.Library, :reset},
    {Kati.Screens.Music, :segment_books, Kati.Screens.Books, :push}
  ]

  for {from, tag, to, action} <- @moves do
    test "#{inspect(from)} #{tag} reaches #{inspect(to)}" do
      view = mount_screen(unquote(from))

      {:noreply, moved} = unquote(from).handle_info({:tap, unquote(tag)}, view.socket)

      assert {unquote(action), unquote(to), _params} = moved.__mob__.nav_action,
             "expected a #{unquote(action)} to #{inspect(unquote(to))}, got " <>
               inspect(moved.__mob__.nav_action)
    end
  end

  test "every shelf can reach both of the others, so none is a dead end" do
    # The property, rather than six separate edges: from any shelf you can get
    # to the other two. Stated this way because the failure was asymmetric —
    # 03 answered everything and the other two answered one segment each — and
    # a list of edges is easy to complete by halves.
    shelves = [Kati.Screens.Library, Kati.Screens.Books, Kati.Screens.Music]

    for from <- shelves do
      reachable =
        for {^from, _tag, to, _action} <- @moves, into: MapSet.new(), do: to

      assert MapSet.equal?(reachable, MapSet.new(shelves -- [from])),
             "#{inspect(from)} reaches #{inspect(MapSet.to_list(reachable))}, " <>
               "not both of the other two"
    end
  end

  test "the segment for the shelf you are on stays put" do
    # Not a no-op by omission: each of the three answers its own segment
    # explicitly, so a reader tapping the shelf they are already looking at
    # gets a settled control rather than a reset to the page they are on.
    for {module, tag} <- [
          {Kati.Screens.Library, :shelf_Screen},
          {Kati.Screens.Books, :open_books},
          {Kati.Screens.Music, :segment_music}
        ] do
      view = mount_screen(module)
      {:noreply, moved} = module.handle_info({:tap, tag}, view.socket)

      assert moved.__mob__.nav_action == nil,
             "#{inspect(module)} navigated when its own segment was tapped"
    end
  end
end
