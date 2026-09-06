defmodule Kati.ShelfFiltersTest do
  @moduledoc """
  The sort disc's sheet, which used to be a picture.

  Screen 145 had no way to learn which shelf opened it and handed nothing
  back, so no sort or filter chosen on it could ever affect anything
  (MOVIES-AND-TV.md #26). It also opened **already filtered** — 2020s, 4★ and
  up, Anime — and announced `showing 41 of 418` on a phone that might hold two
  (#54). Both are the same missing thing: the sheet had no state outside its
  own socket, and its own socket dies on the pop.

  The choice lives in `Mob.State` now, the sheet writes it on every tap, and
  screen 03 re-reads through `Kati.Screens.Resume` — so a narrowed shelf is
  narrowed when you come back to it.

  Two of the four facets the board draws are still not offered, and this file
  asserts that too: a decade needs a first-air year and no column holds one,
  and a service needs a catalogue Kati does not have.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Library.ShelfFilters
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Library
  alias Kati.Screens.ShelfFilters, as: Sheet

  doctest ShelfFilters, only: [resting: 0, narrowed?: 1]
  doctest Sheet, only: [facet_tag: 1, stored_sort: 1]

  @prefix "shelf-filters-"

  setup do
    ShelfFilters.clear()

    on_exit(fn ->
      # The rows first. `Mob.State` is stopped around each test by
      # `Mob.ScreenCase`, and a `clear/0` that exited before the deletes would
      # leave this file's fixtures behind for the next test to collide with.
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      ShelfFilters.clear()
    end)

    :ok
  end

  describe "the stored choice" do
    test "rests at nothing selected, newest first" do
      assert ShelfFilters.current() == ShelfFilters.resting()
      refute ShelfFilters.narrowed?(ShelfFilters.current())
    end

    test "survives being written and read back" do
      ShelfFilters.put(%{sort: :title, direction: :asc, genres: ["Drama"]})

      assert ShelfFilters.current() == %{sort: :title, direction: :asc, genres: ["Drama"]}
      assert ShelfFilters.narrowed?(ShelfFilters.current())
    end

    test "and Reset puts it back" do
      ShelfFilters.put(%{sort: :title, direction: :asc, genres: ["Drama"]})
      ShelfFilters.clear()

      assert ShelfFilters.current() == ShelfFilters.resting()
    end
  end

  describe "applying it to a shelf" do
    setup do
      shelf!("severance", "Severance", "Drama, Mystery")
      shelf!("arrival", "Arrival", "Science Fiction, Drama")
      shelf!("nightbirds", "Nightbirds", nil)
      :ok
    end

    test "narrows to the genre chosen" do
      ShelfFilters.put(%{sort: :recently_added, direction: :desc, genres: ["Mystery"]})

      assert Enum.map(Library.shelf(), & &1.title) == ["Severance"]
    end

    test "two genres are an OR, not an AND" do
      ShelfFilters.put(%{
        sort: :title,
        direction: :asc,
        genres: ["Mystery", "Science Fiction"]
      })

      assert Enum.map(Library.shelf(), & &1.title) == ["Arrival", "Severance"]
    end

    test "a title naming no genre is out of every genre filter" do
      ShelfFilters.put(%{sort: :recently_added, direction: :desc, genres: ["Drama"]})

      refute "Nightbirds" in Enum.map(Library.shelf(), & &1.title)
    end

    test "and in the shelf when nothing is chosen" do
      assert "Nightbirds" in Enum.map(Library.shelf(), & &1.title)
    end

    test "sorts by title in both directions" do
      ShelfFilters.put(%{sort: :title, direction: :asc, genres: []})
      assert Enum.map(Library.shelf(), & &1.title) == ["Arrival", "Nightbirds", "Severance"]

      ShelfFilters.put(%{sort: :title, direction: :desc, genres: []})
      assert Enum.map(Library.shelf(), & &1.title) == ["Severance", "Nightbirds", "Arrival"]
    end

    test "the facets are this shelf's own genres, commonest first" do
      facets = ShelfFilters.facets(Library.shelf())

      assert {"Drama", 2} in facets
      assert {"Mystery", 1} in facets
      assert hd(facets) == {"Drama", 2}

      # Board 145's four. `Comedy` is the one it draws with a count of 0.
      refute Enum.any?(facets, &(elem(&1, 0) == "Comedy"))
    end
  end

  describe "the sheet a real shelf opens" do
    setup do
      shelf!("severance", "Severance", "Drama, Mystery")
      shelf!("arrival", "Arrival", "Science Fiction, Drama")
      %{opening: Sheet.opening()}
    end

    test "counts the reader's own library, not 41 of 418", %{opening: opening} do
      assert opening[:showing] == 2
      assert opening[:total] == 2

      refute opening[:showing] == 41
      refute opening[:total] == 418
    end

    test "opens with nothing selected", %{opening: opening} do
      assert opening[:genres] == MapSet.new()
      assert opening[:decade] == nil
      assert opening[:rating] == nil
      assert opening[:sort] == :recently_added
    end

    test "offers this shelf's genres", %{opening: opening} do
      assert {"Drama", 2} in opening[:facets]
    end

    test "and draws neither the decade nor the service group" do
      drawn = inspect(Sheet.body(Map.new(Sheet.opening())), limit: :infinity)

      refute drawn =~ "Ranges", "a decade needs a first-air year and no column holds one"
      refute drawn =~ "Lumen+", "a service needs a catalogue Kati does not have"
      assert drawn =~ "Drama"
    end

    test "and a chosen genre narrows the count it reports" do
      ShelfFilters.put(%{sort: :recently_added, direction: :desc, genres: ["Mystery"]})

      opening = Sheet.opening()

      assert opening[:showing] == 1
      assert opening[:total] == 2
    end
  end

  describe "with nothing on the shelf" do
    test "the board is drawn whole" do
      assert Sheet.opening() == Sheet.drawn_opening_for_test()
    end

    test "including its own two numbers" do
      opening = Sheet.opening()

      assert opening[:showing] == 41
      assert opening[:total] == 418
      assert opening[:facets] == nil
    end
  end

  describe "the Up next badge" do
    setup do
      shelf!("severance", "Severance", "Drama, Mystery")
      shelf!("arrival", "Arrival", "Science Fiction")
      :ok
    end

    test "counts the whole shelf, not the narrowed one" do
      ShelfFilters.put(%{sort: :recently_added, direction: :desc, genres: ["Mystery"]})

      # One title survives the filter and two are on the shelf. The badge
      # labels a door onto screen 10, which shows the queue whole — a tile
      # reading `1` over a page of two would be the tile disagreeing with the
      # screen it opens.
      assert length(Library.shelf()) == 1
      assert Library.queued() == 2
      assert Library.up_next_badge(Library.queued()) == "2"
    end

    test "and is absent when nothing is being watched" do
      assert Library.up_next_badge(0) == nil
    end
  end

  defp shelf!(slug, title, genres) do
    source_id = @prefix <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: title,
      genres: genres,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching
    })
  end
end
