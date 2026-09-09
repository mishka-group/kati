defmodule Kati.TickProvenanceTest do
  @moduledoc """
  What an episode tick remembers about itself.

  `Kati.Media.Watch` has carried `season_number` and `episode_number` since it
  was written, and `write_tick/2` wrote neither. The columns existed, the
  screens that read them existed, and the one writer in the app left them
  `nil` — so two boards drew a value nothing could produce:

    * **#46.** Screen 07's *Recently watched* draws `S2 E5` under a title.
      `recent_label/1` has always had that clause and always fell through to
      `"SERIES"`, because the numbers were never stored.
    * **#18.** *Time watched* read `Kati.Media.CachedTitle.runtime_minutes`,
      and TMDB puts a series' duration on each EPISODE — `/tv/{id}` answers
      `episode_run_time`, not `runtime` — so the column is `nil` for every
      series in the store and the headline read `0h 0m` however many episodes
      somebody ticked.

  Both are one write and one read. Neither could be caught by a sweep: the
  numbers only exist on a cached episode, and `Kati.ScreenTapSweepTest` runs
  against an empty store where every tick is refused before it is written.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Series

  @prefix "tick-provenance-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_episodes WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    %{tracked: tracked!()}
  end

  describe "the row a tick writes" do
    test "says which season and which episode", %{tracked: tracked} do
      assert :ok = Series.write_tick(tracked.id, row(season: 2, n: 5))

      assert [watch] = Ash.read!(Watch)
      assert watch.season_number == 2
      assert watch.episode_number == 5
    end

    test "takes the number off `n`, which is what the row is drawn with", %{tracked: tracked} do
      assert :ok = Series.write_tick(tracked.id, row(season: 1, n: 3))

      assert [%{episode_number: 3}] = Ash.read!(Watch)
    end

    test "and a drawn episode with neither is still refused, not written blank", %{
      tracked: tracked
    } do
      assert {:error, :no_episode_id} =
               Series.write_tick(tracked.id, %{source_id: nil, watched: false})

      assert Ash.read!(Watch) == []
    end
  end

  describe "screen 07 reading it back" do
    test "labels the tick S2 E5 rather than SERIES", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row(season: 2, n: 5))

      # `S2 E5` is a value nothing could produce before this: `recent_label/1`
      # has always had the clause and always fell through, because the numbers
      # were never written. Its presence IS the assertion.
      #
      # `SERIES` is deliberately not refuted. Screen 07 draws that word in
      # other places — the kind count card among them — so its absence would be
      # a claim about the whole page rather than about this row.
      assert drawn() =~ "S2 E5"
    end

    test "and counts the episode's own runtime, not the title's", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row(season: 2, n: 5))

      # The cached EPISODE carries 47 minutes and the cached TITLE carries no
      # runtime at all, which is what every series in the store looks like.
      assert drawn() =~ "47m"
      refute drawn() =~ "0h 0m"
    end
  end

  defp drawn do
    {:ok, socket} = Kati.Screens.Stats.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.Stats))

    Kati.Screens.Stats
    |> Mob.Socket.new()
    |> then(fn _ -> Kati.Screens.Stats.render(socket.assigns) end)
    |> inspect(limit: :infinity, printable_limit: :infinity)
  end

  defp row(season: season, n: n) do
    %{source_id: @prefix <> "ep", watched: false, season: season, n: n}
  end

  defp tracked! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Severance",
      # No runtime, which is what TMDB gives for a series.
      fetched_at: Kati.Time.now()
    })

    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      title_source_id: @prefix <> "title",
      source_id: @prefix <> "ep",
      season_number: 2,
      episode_number: 5,
      title: "Trojan's Horse",
      runtime_minutes: 47,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      status: :watching
    })
  end
end
