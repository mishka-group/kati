defmodule Kati.ScreenListsTest do
  @moduledoc """
  Screen 12's *Kept automatically* card counts the reader's own library.

  MOVIES-AND-TV.md #106: all four rows were the drawing's numbers on every
  device, and two of them are one query each. The other two are assertions a
  reader makes about a title and no column holds, so they are not drawn rather
  than drawn frozen — a card where two rows are the reader's library and two are
  somebody else's reads as fully real, which is the call #75 made one screen
  over.

  The rest of the screen is still the fixture and cannot stop being: see the
  moduledoc, and [#99](https://github.com/mishka-group/kati/issues/99) for the
  three drawings that would let it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Lists

  @prefix "lists-test-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM media_watches", [])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the two rows the store can answer" do
    test "count nothing on an empty shelf, which is a true answer" do
      Kati.Repo.query!("DELETE FROM media_watches", [])

      assert [%{title: "Rewatches", count: "0"}, %{title: "Abandoned", count: "0"}] =
               Lists.kept_rows()
    end

    test "count a dropped title and a rewatch" do
      dropped = shelve!("one", :dropped)
      watched = shelve!("two", :watching)

      Ash.create!(Watch, %{
        tracked_title_id: watched.id,
        rewatch_number: 2,
        watched_on: ~D[2026-09-01],
        watched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      # A first watch is not a rewatch.
      Ash.create!(Watch, %{
        tracked_title_id: dropped.id,
        watched_on: ~D[2026-09-01],
        watched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      assert Lists.rewatch_count() == 1
      assert Lists.abandoned_count() == 1

      drawn = inspect(Lists.kept(Lists.lists()), limit: :infinity)
      assert drawn =~ "Rewatches"
      assert drawn =~ "Abandoned"
    end

    test "and an archived title is not abandoned, it is hidden" do
      shelve!("gone", :dropped)
      [row] = Ash.read!(TrackedTitle) |> Enum.filter(&(&1.source_id == @prefix <> "gone"))
      row |> Ash.Changeset.for_update(:update, %{archived: true}) |> Ash.update!()

      assert Lists.abandoned_count() == 0
    end
  end

  describe "the two rows nothing stores" do
    test "are not drawn at all" do
      drawn = inspect(Lists.kept(Lists.lists()), limit: :infinity)

      refute drawn =~ "Wishlist"
      refute drawn =~ "Owned on disc"
    end

    test "and neither is a chevron that opens nothing" do
      # Every kept row drew one, at a list-detail screen the design never
      # draws. `chevron_right`'s glyph is what would be in the tree.
      drawn = inspect(Lists.kept(Lists.lists()), limit: :infinity)

      refute drawn =~ Kati.Icons.glyph!("chevron_right")
    end
  end

  describe "the + disc" do
    test "says what it is waiting for instead of inventing a row" do
      # It used to prepend a row titled `New list` to the socket: lost on back,
      # duplicated on a second press, holding nothing either way.
      socket = Mob.Socket.assign(Mob.Socket.new(Lists), :lists, Lists.lists())

      {:noreply, pressed} = Lists.handle_tap(:new_list, socket)

      assert pressed.assigns.waiting?

      said = inspect(Lists.waiting(true), limit: :infinity)
      assert said =~ "needs a name"
      assert said =~ "Add to list"

      # And the made section is unchanged: no invented row.
      assert length(pressed.assigns.lists.made) == length(Lists.lists().made)
    end

    test "and says nothing until it is pressed" do
      assert inspect(Lists.waiting(false), limit: :infinity) =~ "spacer"
    end
  end

  defp shelve!(id, status) do
    source_id = @prefix <> id

    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: source_id,
      kind: :movie,
      title: "Test " <> id,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: source_id,
      kind: :movie,
      status: status
    })
  end
end
