defmodule Kati.SearchSuggestionsTest do
  @moduledoc """
  Board 86's *Try* group, drawn from what this reader actually has.

  The caption says exactly that, and the two rows were `what leaves this week`
  and `notes about the estuary` — fixed strings that match nothing on any
  device but the one the board was captured on. A reader tapped one and got the
  no-match card.

  The newest title on the shelf and the book the newest note is about are both
  queries that WILL match. *What leaves this week* is deliberately not derived:
  it needs an offers resource, the same absence that takes the Leaving band off
  screen 11 and the decade chips off screen 145.

  This file is also what `Kati.ScreenEmptyDatabaseTest`'s `@no_empty_board`
  rows for 86 and 87 name as holding their copy instead.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Screens.SearchIdle
  alias Kati.Search.Suggestions

  @prefix "search-suggestions-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "with a title on the shelf" do
    setup do
      shelve!("severance", "Severance")
      :ok
    end

    test "the newest one is offered" do
      assert "Severance" in Suggestions.derived()
    end

    test "and the board's unmatchable pair is gone" do
      offered = Suggestions.derived()

      refute "what leaves this week" in offered,
             "a suggestion that needs an offers resource is still being offered"

      refute "notes about the estuary" in offered
    end

    test "and it is a query that actually matches" do
      for suggestion <- Suggestions.derived() do
        results = Kati.Search.Query.run(suggestion)

        refute Kati.Screens.Search.empty?(results),
               "#{inspect(suggestion)} is offered under *drawn from what you have* and " <>
                 "matches nothing"
      end
    end

    test "the idle page draws them" do
      drawn = inspect(SearchIdle.suggestions(), limit: :infinity, printable_limit: :infinity)

      assert drawn =~ "Severance"
      refute drawn =~ "what leaves this week"
    end
  end

  describe "the scopes screens 86 and 88 draw" do
    test "say which of them a search actually looks in" do
      # Every scope the design draws is searched now: Music (albums and
      # artists), Meals (recipes and logged meals) and Money (expenses) joined
      # Screen, Books, Calendar and Notes.
      for key <- [:all, :screen, :books, :calendar, :notes, :music, :meals, :money] do
        assert Kati.Search.built?(key), "#{key} is not searched"
      end
    end

    test "and a scope cannot be marked built without a group behind it" do
      # The KEY, since mishka-group/kati#103: `built?/1` answers about the key
      # and a label is a translation — asked with the label it answered `false`
      # for every scope the moment the chips spoke Persian.
      built =
        Kati.Search.scopes()
        |> Enum.map(fn {key, _label, _fields} -> key end)
        |> Enum.filter(&Kati.Search.built?/1)

      assert Enum.sort(built) == Enum.sort(Kati.Search.narrowable_scopes() -- [:all]),
             "`built?/1` and `narrowable_scopes/0` disagree, so a chip is offered for a " <>
               "group that does not exist or withheld for one that does"
    end
  end

  describe "the boards that state the contract" do
    test "screen 88 marks the scopes a search does not look in" do
      drawn =
        inspect(Kati.Screens.SearchSpec.scopes(), limit: :infinity, printable_limit: :infinity)

      # Every scope is searched, so none is marked *not yet*: a pill against a
      # scope that IS built would be a lie.
      refute drawn =~ "NOT YET"
    end

    test "and a built scope carries no pill" do
      for key <- [:screen, :music, :meals, :money] do
        refute inspect(Kati.Screens.SearchSpec.state_pill(key), limit: :infinity) =~ "NOT YET"
      end
    end

    test "screen 86 offers no chip it will then discard" do
      drawn = inspect(SearchIdle.chips(:all), limit: :infinity, printable_limit: :infinity)

      # Every label is still on the row — board 86 draws eight and the contract
      # is the design's — but the four with no group behind them carry no tag,
      # so the choice is never offered and then dropped by `narrowable/1`.
      for label <- Enum.map(Kati.Search.chip_keys(), &Kati.Search.scope_label/1) do
        assert drawn =~ label
      end

      for built <- [:screen, :books, :calendar, :notes, :music, :meals, :money] do
        assert drawn =~ "scope_#{built}", "#{built} has a group and lost its tap"
      end
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

    Ash.create!(Kati.Media.TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> slug,
      kind: :tv,
      status: :watching
    })
  end

  describe "a title that was removed" do
    test "is not offered, though the cache still holds it" do
      cached!("removed", "Removal Probe")

      refute "Removal Probe" in Suggestions.derived(),
             "*Try* offered a title the reader removed — N13"
    end
  end
end
