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
      # Notes before books: the foreign key refuses the parent delete otherwise.
      Kati.Repo.query!("DELETE FROM book_notes WHERE body LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM books WHERE title LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the groups a query answers with" do
    test "books are their own group, not four rows of the Screen one" do
      results = Query.run("zzz-nothing-matches-this")

      assert Map.has_key?(results, :books)
      assert Enum.any?(Query.chip_counts(results), &(elem(&1, 0) == :books))
      assert :books in Kati.Search.narrowable_scopes()
    end

    test "and the screen draws them under their own heading" do
      groups =
        Search.visible_groups(%{titles: [%{}], books: [%{}], calendar: [], notes: []}, :all)

      assert {:screen, :titles} in groups
      assert {:books, :books} in groups
    end

    test "a chip narrows to the group it names" do
      results = %{titles: [%{}], books: [%{}], calendar: [], notes: []}

      assert Search.visible_groups(results, :books) == [{:books, :books}]
      assert Search.visible_groups(results, :screen) == [{:screen, :titles}]
    end
  end

  describe "the counts" do
    setup do
      for n <- 1..7, do: shelve!("match-#{n}", "Nightbird #{n}")
      :ok
    end

    test "count what matched, not what was drawn" do
      results = Query.run("Nightbird")

      assert length(results.titles) == 7

      assert {:screen, Kati.Search.scope_label(:screen), 7} in Query.chip_counts(results),
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

  describe "the Notes group" do
    setup do
      book = Ash.create!(Kati.Books.Book, %{title: @prefix <> "notebook"})

      for n <- 1..5 do
        Ash.create!(Kati.Books.Note, %{
          book_id: book.id,
          body: @prefix <> "marram grass, note #{n}"
        })
      end

      :ok
    end

    test "returns every note that matched, not the best one" do
      results = Query.run("marram")

      assert length(results.notes) == 5,
             "the group still ranked the whole list and took the head"
    end

    test "the Notes chip counts what matched, and All adds all of it" do
      counts =
        "marram"
        |> Query.run()
        |> Query.chip_counts()
        |> Map.new(fn {key, _label, n} -> {key, n} end)

      assert counts[:notes] == 5, "the chip agreed with the cap rather than with the match"

      assert counts[:all] ==
               counts[:screen] + counts[:books] + counts[:calendar] + counts[:notes]
    end

    test "and every match is drawn" do
      drawn =
        "marram"
        |> Query.run()
        |> Kati.Screens.Search.notes()
        |> inspect(limit: :infinity, printable_limit: :infinity)

      for n <- 1..5 do
        assert drawn =~ "note #{n}", "note #{n} was capped out of the page"
      end
    end
  end

  describe "a title that is only cached" do
    setup do
      cached!("unshelved", "Emergence")
      :ok
    end

    # N13. The cache outlives a title — removing one keeps it, and screen 06
    # caches a title the moment it is ticked — so a search over the whole table
    # found films the reader had removed, under *Kati only searches what you
    # keep*, as rows with no screen to open.
    test "is not found" do
      assert Query.run("Emergence").titles == []
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

      # The chips it counts, not the scopes it can narrow to. Board 90 draws
      # all eight — `Kati.Search.Query.chip_counts/1` walks `chip_keys/0` since
      # mishka-group/kati#103 — and a sentence about what a reader sees on open
      # has to name the row they see. It said five over a row of eight.
      assert note =~ "#{length(Kati.Search.chip_keys())} zeroes"
    end

    test "and it says so in the other script too" do
      # The whole sentence is one msgid, so this is the check that the Persian
      # rendering of board 90 does not draw an English paragraph under a
      # Persian page — which is what the device found.
      Kati.Locale.as(:fa, fn ->
        note = Kati.Search.local_note()

        refute note =~ "Counts stay off"
        assert note =~ "چیپ‌ها"
        assert note =~ Kati.Locale.number(length(Kati.Search.chip_keys()))
      end)
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
