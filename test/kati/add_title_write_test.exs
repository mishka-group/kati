defmodule Kati.AddTitleWriteTest do
  @moduledoc """
  #87 — the film and TV spine holds a row.

  Issue #60 decided v1 ships one media domain, Screen, and it was the one with
  no write path at all: nine screens queried `Kati.Media` correctly and every
  one of them queried a table that could not hold a row. Adding a title toggled
  a boolean on a socket and the row died with the screen.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.AddTitle

  setup do
    # Cleaned BOTH sides, and the `on_exit` half is the one that matters.
    #
    # This file writes real rows into the shared store. Cleaning only on the
    # way in leaves the last test's rows behind for whatever runs next — and
    # what runs next includes `Kati.ScreenEmptyDatabaseTest`, whose entire
    # subject is what screens draw against an EMPTY database. It made the suite
    # order-dependent: two identical runs, one failure and then two, then none.
    #
    # A suite that passes depending on order is worth less than no suite, which
    # is the lesson this whole effort started from.
    wipe = fn ->
      Ash.read!(Kati.Media.TrackedTitle) |> Enum.each(&Ash.destroy!/1)
      Ash.read!(Kati.Media.CachedTitle) |> Enum.each(&Ash.destroy!/1)
    end

    wipe.()
    on_exit(wipe)
    :ok
  end

  describe "adding a title" do
    test "writes both rows, and they are there after the screen is gone" do
      view = mount_screen(AddTitle)
      title = "The Quiet Coast"

      assert Ash.read!(Kati.Media.TrackedTitle) == []

      _ = render_info(view, {:tap, String.to_atom("add_" <> title)})

      # The receipt is the store, not the socket. A boolean on an assign is
      # exactly what this ticket replaced.
      tracked = Ash.read!(Kati.Media.TrackedTitle)
      cached = Ash.read!(Kati.Media.CachedTitle)

      assert length(tracked) == 1
      assert length(cached) == 1

      assert hd(tracked).source == :manual,
             "a hand-typed title has no provider, and pretending otherwise makes the row " <>
               "unreconcilable when there is one"

      assert hd(tracked).source_id == title
      assert hd(cached).title == title
    end

    test "a series is stored as :tv, a film as :movie" do
      # Read off the meta line the drawing already writes, because neither a
      # sample row nor a typed title carries a kind of its own.
      assert AddTitle.kind_of(%{meta: "2023 · SERIES · 2 SEASONS"}) == :tv
      assert AddTitle.kind_of(%{meta: "2019 · FILM · 1h 48m"}) == :movie
      assert AddTitle.kind_of(nil) == :movie
    end

    test "untracking removes what you decided and keeps what the title is" do
      view = mount_screen(AddTitle)
      title = "The Quiet Coast"

      view = render_info(view, {:tap, String.to_atom("add_" <> title)})
      assert length(Ash.read!(Kati.Media.TrackedTitle)) == 1

      _ = render_info(view, {:tap, String.to_atom("add_" <> title)})

      assert Ash.read!(Kati.Media.TrackedTitle) == [],
             "untracking left the decision behind"

      assert length(Ash.read!(Kati.Media.CachedTitle)) == 1,
             "untracking deleted what the title IS, which was never the user's decision"
    end

    test "adding the same title twice does not write a second pair" do
      view = mount_screen(AddTitle)
      title = "Quiet Earth"

      view = render_info(view, {:tap, String.to_atom("add_" <> title)})
      view = render_info(view, {:tap, String.to_atom("add_" <> title)})
      _ = render_info(view, {:tap, String.to_atom("add_" <> title)})

      assert length(Ash.read!(Kati.Media.TrackedTitle)) == 1
    end
  end

  describe "the field" do
    test "holds what was typed" do
      view = mount_screen(AddTitle)

      view = render_info(view, {:change, :title_query, "hollow"})

      assert assigns(view).query == "hollow"
      assert find(tree(view), :text_field, accessibility_id: "title_query") != nil
    end
  end
end
