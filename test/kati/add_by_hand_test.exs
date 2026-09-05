defmodule Kati.AddByHandTest do
  @moduledoc """
  Screen 154 writes a real row, and refuses in words when it cannot.

  The receipt is `Kati.Media.TrackedTitle`, not the socket: a form that moves
  an assign and writes nothing is exactly what screen 89's row was for as long
  as it had no destination.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.TrackedTitle
  alias Kati.Screens.AddByHand

  setup do
    on_exit(fn -> Kati.Repo.query!("DELETE FROM tracked_titles", []) end)
    :ok
  end

  # A real mounted socket, not a map with an `:assigns` key. `Mob.Socket`
  # carries more than its assigns and its own functions pattern-match on the
  # struct, so a stand-in fails inside `assign/3` rather than in the code
  # under test.
  defp socket(overrides) do
    Enum.reduce(overrides, mount_screen(AddByHand).socket, fn {k, v}, s ->
      Mob.Socket.assign(s, k, v)
    end)
  end

  test "a typed title reaches the store as a manual row" do
    AddByHand.save(socket(%{title: "The Long Hollow", kind: :tv, status: "Watching"}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.source == :manual
    assert row.source_id == "The Long Hollow"
    assert row.kind == :tv
    assert row.status == :watching
  end

  test "a film is a film" do
    AddByHand.save(socket(%{title: "Estuary", kind: :movie}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.kind == :movie
    assert row.status == :not_started
  end

  test "surrounding space is not part of the title" do
    AddByHand.save(socket(%{title: "  Low Water  "}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.source_id == "Low Water"
  end

  describe "the save that refuses" do
    test "no title writes nothing and says so" do
      result = AddByHand.save(socket(%{title: ""}))

      assert Ash.count!(TrackedTitle) == 0
      assert result.assigns.save_error =~ "title"
    end

    test "a title of only space is no title" do
      result = AddByHand.save(socket(%{title: "   "}))

      assert Ash.count!(TrackedTitle) == 0
      assert is_binary(result.assigns.save_error)
    end
  end

  test "every status the board draws maps to one the resource takes" do
    for {label, expected} <- [
          {"Not started", :not_started},
          {"Watching", :watching},
          {"Finished", :finished}
        ] do
      assert AddByHand.status_atom(label) == expected
    end
  end

  describe "a hand-typed title is a title the app can see" do
    test "it reaches the shelf, which is the only place a person looks for it" do
      # `Kati.Screens.Library`'s own rule: **a row with no cached title is
      # dropped**, because a tile captioned `nil` is worse than a tile that is
      # not there. So writing only the tracked row put a title in the library
      # that the library did not draw — the one path from a fresh install to a
      # library with anything in it, producing a row nobody could see.
      #
      # Every test here counted `tracked_titles` and passed, on device and on
      # the host, because the count was never the question.
      saved(%{title: "Estuary Nights", kind: :movie, status: "Not started"})

      titles = Enum.map(Kati.Screens.Library.shelf(), & &1.title)

      assert "Estuary Nights" in titles,
             "the title was written and the shelf does not draw it: " <> inspect(titles)
    end

    test "and search finds it, which is the other place" do
      # `Kati.Search.Query.run/1` reads `Kati.Media.CachedTitle` — the same row
      # the shelf reads the name from — so the two failed together and are
      # fixed together. #92's first criterion is that typing returns rows that
      # match, and a title you added by hand is the one row you are most likely
      # to go looking for.
      saved(%{title: "Estuary Nights", kind: :movie, status: "Not started"})

      found = Enum.map(Kati.Search.Query.run("estuary").titles, & &1.title)

      assert "Estuary Nights" in found,
             "a hand-typed title is in the library and cannot be found: " <> inspect(found)
    end

    test "adding one you already have is refused in words a person can act on" do
      # Refusing is right — two rows for one title is not a state the shelf can
      # draw. What was wrong is what it said: the tracked row's uniqueness is a
      # database constraint and Ash reports it as "Has already been taken",
      # which is a sentence about a column. Someone who has just typed a name
      # they already own needs to be told that.
      saved(%{title: "Estuary Nights", kind: :movie, status: "Not started"})
      socket = saved(%{title: "Estuary Nights", kind: :tv, status: "Watching"})

      assert socket.assigns[:save_error] =~ "already in your library"
      refute socket.assigns[:save_error] =~ "taken"

      assert length(Kati.Screens.Library.shelf()) == 1,
             "refusing the second add still left two rows on the shelf"
    end
  end

  defp saved(assigns) do
    Kati.Screens.AddByHand.save(%Mob.Socket{
      Mob.Socket.new(Kati.Screens.AddByHand)
      | assigns: Map.merge(%{save_error: nil}, assigns)
    })
  end
end
