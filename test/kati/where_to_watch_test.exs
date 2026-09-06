defmodule Kati.WhereToWatchTest do
  @moduledoc """
  Screen 14's *Where to watch* band, filled by the data screen 92's rules
  needed.

  Board 14 draws three ways to watch and `Kati.Screens.SeriesMeta.shaped/2`
  answered `[]`, with the moduledoc saying why: *the same absent offers
  resource*. It is not absent — TMDB folds JustWatch's per-country data into
  the detail response Kati already fetches — so the band fills, and the same
  column answers the three rules on screen 92 (MOVIES-AND-TV.md #77 and the
  offers half of #51).

  Two rules this file holds:

    * **The reader's country, and no other.** Screen 92's own note is that
      telling somebody a film is on Lumen+ when it is only on Lumen+ in Canada
      is worse than telling them nothing.
    * **No prices, ever.** TMDB says where, never how much. Board 14 draws
      `£14.99` beside *buy season* and a number Kati invented there would be
      the most expensive kind of lie this page can tell.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.SeriesMeta
  alias Kati.Services.Service

  doctest SeriesMeta, only: [where_line: 4]

  @prefix "where-to-watch-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", ["Where %"])
    end)

    :ok
  end

  describe "the band" do
    test "names every way the title is offered here, in the board's order" do
      cached =
        cache!(%{
          "GB" => %{
            "flatrate" => ["Netflix"],
            "rent" => ["Apple TV"],
            "buy" => ["Amazon"]
          }
        })

      rows = SeriesMeta.where_rows(cached)

      assert Enum.map(rows, & &1.name) == ["Netflix", "Apple TV", "Amazon"]
      assert Enum.map(rows, & &1.line) == ["included", "rent", "buy"]
    end

    test "says which one the reader is already paying for" do
      Ash.create!(Service, %{name: "Where Netflix", tier: :subscribed})
      cached = cache!(%{"GB" => %{"flatrate" => ["Where Netflix", "Now"]}})

      rows = SeriesMeta.where_rows(cached)

      assert Enum.find(rows, &(&1.name == "Where Netflix")).line ==
               "included · you pay for this"

      assert Enum.find(rows, &(&1.name == "Now")).line == "included"
    end

    test "carries the service's initial as its badge" do
      cached = cache!(%{"GB" => %{"flatrate" => ["netflix"]}})

      assert [%{badge: "N"}] = SeriesMeta.where_rows(cached)
    end

    test "never carries a price, because TMDB never sends one" do
      cached = cache!(%{"GB" => %{"rent" => ["Apple TV"], "buy" => ["Amazon"]}})

      assert Enum.all?(SeriesMeta.where_rows(cached), &(&1.price == nil))
    end

    test "is empty for a country JustWatch does not answer for" do
      cached = cache!(%{"IE" => %{"flatrate" => ["Netflix"]}})

      assert SeriesMeta.where_rows(cached) == []
    end

    test "is empty for a title nobody has fetched" do
      assert SeriesMeta.where_rows(cache!(nil)) == []
      assert SeriesMeta.where_rows(nil) == []
    end
  end

  describe "the page" do
    test "draws the band over a title with providers" do
      cached = cache!(%{"GB" => %{"flatrate" => ["Kanopy"]}})
      tracked = track!(cached)

      words = drawn(tracked.id)

      assert words =~ "Kanopy"
      assert words =~ String.upcase("Where to watch")
    end

    test "and drops the heading entirely when there is nothing to say" do
      tracked = track!(cache!(nil))

      words = drawn(tracked.id)

      refute words =~ String.upcase("Where to watch")
    end
  end

  defp drawn(tracked_id) do
    {:ok, socket} =
      SeriesMeta.mount(
        %{tracked_id: tracked_id},
        %{},
        Mob.Socket.new(Kati.Screens.SeriesMeta)
      )

    socket.assigns
    |> SeriesMeta.render()
    |> inspect(limit: :infinity, printable_limit: :infinity)
  end

  defp cache!(providers) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Tidewrack",
      providers: providers,
      fetched_at: Kati.Time.now()
    })
  end

  defp track!(_cached) do
    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      status: :watching
    })
  end
end
