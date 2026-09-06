defmodule Kati.SearchGroupsTest do
  @moduledoc """
  Screen 19 says what it found, and says it under the right heading.

  Five findings, all on the same screen and all of them the search telling the
  reader something that was not so.

    * **#61.** `titles_for/1` concatenated books into `:titles`, so a book was
      drawn under the heading SCREEN, counted by the Screen chip, and given a
      chevron that opened nothing.
    * **#62.** Every group ended `|> Enum.take(3)` BEFORE `chip_counts/1`
      counted it, so ten matching films rendered three, the chip said `3`, and
      the other seven were unreachable — the `See all N →` row
      `Kati.Search.rows_per_group/0` promises exists nowhere in `lib/`.
    * **#63.** The idle page drew board 88's specification, which describes
      eight scopes and a 180 ms debounce. This screen narrows to five and runs
      on every keystroke, deliberately.
    * **#64.** A note hit's eyebrow was the bare word `NOTE` — no date, no
      book — where the board draws `NOTE · 6 AUG · THE LONG HOLLOW`.
    * **#65.** A cache-only hit — looked up on the add sheet, never shelved —
      carried a chevron that pushed screen 04 or 08 BARE, so a tap on one
      title opened a page about another.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Search
  alias Kati.Search.Query

  doctest Query, only: [note_eyebrow: 1]
  doctest Kati.Search, only: [local_note: 0]

  @prefix "search-groups-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the groups a query answers with" do
    test "books are their own group, not four rows of the Screen one" do
      results = Query.run("zzz-nothing-matches-this")

      assert Map.has_key?(results, :books)
      assert Enum.any?(Query.chip_counts(results), &(elem(&1, 0) == "Books"))
      assert "Books" in Kati.Search.narrowable_scopes()
    end

    test "and the screen draws them under their own heading" do
      groups =
        Search.visible_groups(%{titles: [%{}], books: [%{}], calendar: [], note: nil}, "All")

      assert {"Screen", :titles} in groups
      assert {"Books", :books} in groups
    end

    test "a chip narrows to the group it names" do
      results = %{titles: [%{}], books: [%{}], calendar: [], note: nil}

      assert Search.visible_groups(results, "Books") == [{"Books", :books}]
      assert Search.visible_groups(results, "Screen") == [{"Screen", :titles}]
    end
  end

  describe "the counts" do
    setup do
      for n <- 1..7, do: cached!("match-#{n}", "Nightbird #{n}")
      :ok
    end

    test "count what matched, not what was drawn" do
      results = Query.run("Nightbird")

      assert length(results.titles) == 7

      assert {"Screen", 7} in Query.chip_counts(results),
             "the chip agreed with the cap rather than with the match"
    end

    test "and every match is drawn" do
      results = Query.run("Nightbird")
      drawn = inspect(Search.titles(results), limit: :infinity, printable_limit: :infinity)

      for n <- 1..7 do
        assert drawn =~ "Nightbird #{n}", "match #{n} was capped out of the page"
      end
    end
  end

  describe "a hit with no row behind it" do
    setup do
      cached!("unshelved", "Emergence")
      :ok
    end

    test "carries no tap" do
      results = Query.run("Emergence")

      assert [row] = results.titles
      assert row.id == nil
      assert Search.hit_tag(row) == nil
    end

    test "so it cannot open a page about a different title" do
      results = Query.run("Emergence")
      socket = Mob.Socket.assign(Mob.Socket.new(Search), :results, results)

      # The tag of the one row, had it carried one. Nothing answers it.
      same = Search.open_hit(socket, :open_series_Emergence, Kati.Screens.Series)

      assert same.__mob__.nav_action == nil,
             "a cache-only hit still pushes screen 04 bare, which draws the fixture"
    end

    test "and a shelved one does carry a tap, onto its own row" do
      tracked = shelve!("shelved", "Severance")
      results = Query.run("Severance")

      row = Enum.find(results.titles, &(&1.title == "Severance"))

      assert row.id == tracked.id
      refute Search.hit_tag(row) == nil

      socket = Mob.Socket.assign(Mob.Socket.new(Search), :results, results)
      moved = Search.open_hit(socket, Search.hit_tag(row), Kati.Screens.Series)

      assert moved.__mob__.nav_action == {:push, Kati.Screens.Series, %{id: tracked.id}}
    end
  end

  describe "the note this screen draws while it waits" do
    test "is about this screen" do
      note = Kati.Search.local_note()

      refute note =~ "debounce", "screen 19 runs on every keystroke, deliberately"
      refute note =~ "eight zeroes", "screen 19 narrows to five scopes"
      assert note =~ "#{length(Kati.Search.narrowable_scopes())} zeroes"
    end

    test "and board 88 keeps its own" do
      assert Kati.Search.counts_note() =~ "debounce at 180 ms"
    end
  end

  defp cached!(slug, title) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> slug,
      kind: :tv,
      title: title,
      fetched_at: Kati.Time.now()
    })
  end

  defp shelve!(slug, title) do
    cached!(slug, title)

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> slug,
      kind: :tv,
      status: :watching
    })
  end
end
