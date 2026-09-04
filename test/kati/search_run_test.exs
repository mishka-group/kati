defmodule Kati.SearchRunTest do
  @moduledoc """
  `Kati.Search.run/1` against the store.

  #92's receipt is the store, not the screen, so these seed rows and assert
  what comes back — including the rows that must NOT, which is the half a
  presence-only assertion cannot make.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Search
  alias Kati.Search.Query

  setup do
    on_exit(fn ->
      for table <- ~w(cached_titles events book_notes) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    for {id, title, kind} <- [
          {"1", "The Long Hollow", :tv},
          {"2", "Hollow Season", :tv},
          {"3", "Estuary", :movie}
        ] do
      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: id,
        kind: kind,
        title: title,
        fetched_at: DateTime.utc_now()
      })
    end

    :ok
  end

  test "a query returns what matches and nothing that does not" do
    result = Query.run("hollow")

    titles = Enum.map(result.titles, & &1.title)

    assert "The Long Hollow" in titles
    assert "Hollow Season" in titles

    # The half that matters. A presence-only assertion passes on a screen that
    # returns everything it has.
    refute "Estuary" in titles
  end

  test "the best tier comes first" do
    # `Hollow Season` is a prefix match, `The Long Hollow` a substring — tier 2
    # before tier 3, which is the order `tiers/0` specifies.
    assert [%{title: "Hollow Season"} | _rest] = Query.run("hollow").titles
  end

  test "each row says which kind it is" do
    assert %{sub: sub} = Enum.find(Query.run("hollow").titles, &(&1.title == "Hollow Season"))
    assert sub =~ "Series"
  end

  test "nothing typed and nothing found are different answers" do
    idle = Query.run("h")
    assert idle.idle?, "a query under the minimum is the screen waiting, not a result"

    empty = Query.run("zzzznothing")
    refute empty.idle?, "a long-enough query that matched nothing is the screen having looked"
    assert empty.titles == []

    # Both carry lists, never nil: the render maps over them, so a nil group
    # is a crash rather than a state.
    assert is_list(idle.titles) and is_list(idle.calendar)
  end

  test "the chips count the results they stand for" do
    counts = Query.run("hollow") |> Query.chip_counts() |> Map.new()

    assert counts["Screen"] == 2
    assert counts["All"] == counts["Screen"] + counts["Calendar"] + counts["Notes"]
  end

  test "an empty store answers the no-match state rather than raising" do
    Kati.Repo.query!("DELETE FROM cached_titles", [])

    assert %{titles: [], calendar: [], note: nil} = Query.run("hollow")
  end

  describe "the history the field keeps" do
    setup do
      Kati.Search.Recent.forget!()
      :ok
    end

    test "a fresh install has none, which is a state and not a placeholder" do
      # `Kati.Search.Sample.recent/0` used to answer `dentist`, `leaving soon`,
      # `ines karvel`, `4 stars` and `miso salmon` on every device — five words
      # nobody had typed, presented as their own search history. That is the
      # defect #91 reports about the shelves, one screen further in.
      assert Kati.Search.Recent.all() == []
    end

    test "a query that ran is remembered, newest first" do
      Kati.Search.Recent.remember("hollow")
      Kati.Search.Recent.remember("estuary")

      assert Kati.Search.Recent.all() == ["estuary", "hollow"]
    end

    test "searching the same thing twice moves it to the front rather than doubling it" do
      Kati.Search.Recent.remember("hollow")
      Kati.Search.Recent.remember("estuary")
      Kati.Search.Recent.remember("hollow")

      assert Kati.Search.Recent.all() == ["hollow", "estuary"]
    end

    test "a query too short to run is not remembered" do
      # The shelf would otherwise fill with the first letter of everything ever
      # typed. `Kati.Search.long_enough?/1` is what says a query ran at all.
      Kati.Search.Recent.remember("h")

      assert Kati.Search.Recent.all() == []
    end

    test "it keeps the number screen 88 specifies and no more" do
      for i <- 1..12, do: Kati.Search.Recent.remember("query#{i}")

      assert length(Kati.Search.Recent.all()) == Kati.Search.recent_kept()
      assert hd(Kati.Search.Recent.all()) == "query12"
    end

    test "nothing is folded, because they are your words" do
      # Screen 88's own row: *never translated, they are your words*. So the
      # normalisation that ranks a query does not touch the one that is stored.
      Kati.Search.Recent.remember("Café")

      assert Kati.Search.Recent.all() == ["Café"]
    end
  end

end
