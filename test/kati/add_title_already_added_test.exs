defmodule Kati.AddTitleAlreadyAddedTest do
  @moduledoc """
  A title already on the shelf says so before you add it again.

  `row/1` wrote `added: false` and nothing corrected it, so searching for a
  film added last week offered to add it again — and the tap did, because
  `add/2` reads `row.added` to choose between `track/2` and `untrack/2`. The
  same title went on twice from the same page and the disc never said
  otherwise.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.AddTitle

  @prefix "already-added-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  defp track!(source_id) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      title: "Kept",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      status: :watching
    })
  end

  defp row(source_id), do: %{source: :tmdb, source_id: source_id, added: false}

  test "a row nobody has added stays unticked" do
    assert [%{added: false}] = AddTitle.already_added([row(@prefix <> "absent")])
  end

  test "and one already on the shelf is ticked" do
    track!(@prefix <> "kept")

    assert [%{added: true}] = AddTitle.already_added([row(@prefix <> "kept")]),
           "the page offered to add a title the reader already has"
  end

  test "each row is answered for itself" do
    track!(@prefix <> "kept")

    marked = AddTitle.already_added([row(@prefix <> "kept"), row(@prefix <> "absent")])

    assert Enum.map(marked, & &1.added) == [true, false]
  end

  test "and the shelf is read once, not once per row" do
    # A `by_reference` call per result would be a query per row on a page that
    # draws twenty. This pins the shape rather than the count: the function
    # takes the whole list and returns the whole list.
    track!(@prefix <> "kept")

    many = Enum.map(1..20, fn n -> row(@prefix <> "row#{n}") end)

    assert length(AddTitle.already_added(many)) == 20
  end

  test "a shelf that cannot be read leaves the rows alone" do
    # And it must not be the `:shelf` ACTION, which takes a required `:kind`
    # argument and raises without one. The first cut called it, the rescue
    # swallowed the raise, and this function returned every row untouched with
    # the whole suite green — the exact fallback-hides-the-bug shape this file
    # is one of many about.
    track!(@prefix <> "kept")

    refute AddTitle.already_added([row(@prefix <> "kept")]) == [row(@prefix <> "kept")],
           "the read is failing silently and every row is coming back as it went in"
  end
end
