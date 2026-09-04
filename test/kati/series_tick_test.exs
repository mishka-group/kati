defmodule Kati.SeriesTickTest do
  @moduledoc """
  Ticking an episode writes a `Kati.Media.Watch`, and unticking removes it.

  #90's sentence is that a tick *"moves a socket assign and nothing else"* and
  that *"nothing in the app has ever written a Watch"*. These assert the store,
  not the screen — a screen redrawing a boolean is indistinguishable from a
  screen redrawing a row, which is why every criterion on that ticket says the
  receipt is the store.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Series

  setup do
    on_exit(fn ->
      for table <- ~w(media_watches tracked_titles cached_episodes cached_titles) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    {:ok, tracked} =
      Ash.create(TrackedTitle, %{
        source: :tmdb,
        source_id: "95396",
        kind: :tv,
        status: :watching
      })

    {:ok, _cached} =
      Ash.create(CachedTitle, %{
        source: :tmdb,
        source_id: "95396",
        kind: :tv,
        title: "Severance",
        fetched_at: DateTime.utc_now()
      })

    {:ok, episode} =
      Ash.create(CachedEpisode, %{
        source: :tmdb,
        source_id: "2337670",
        title_source_id: "95396",
        season_number: 1,
        episode_number: 1,
        title: "Good News About Hell",
        fetched_at: DateTime.utc_now()
      })

    {:ok, tracked: tracked, episode: episode}
  end

  defp row(episode, watched?), do: %{source_id: episode.source_id, watched: watched?}

  test "a tick writes one row against that episode", %{tracked: tracked, episode: episode} do
    assert Ash.count!(Watch) == 0

    assert :ok = Series.write_tick(tracked.id, row(episode, false))

    assert [watch] = Ash.read!(Watch)
    assert watch.tracked_title_id == tracked.id
    assert watch.episode_source_id == "2337670"

    # The stamp is the device's day, not UTC's — `Kati.ScreenDateTest` forbids
    # `Date.utc_today/0` in a screen for exactly this reason.
    assert watch.watched_on == Kati.Time.today()
  end

  test "unticking removes the row rather than writing a second", %{
    tracked: tracked,
    episode: episode
  } do
    assert :ok = Series.write_tick(tracked.id, row(episode, false))
    assert Ash.count!(Watch) == 1

    assert :ok = Series.write_tick(tracked.id, row(episode, true))

    # Destroyed, not negated. `Kati.Media.Watch`'s own `:episode_ticks` action
    # ticks by membership — "an episode is watched when a row for it exists" —
    # so a row saying `watched: false` would read as watched.
    assert Ash.count!(Watch) == 0
  end

  test "a tick survives being read back", %{tracked: tracked, episode: episode} do
    assert :ok = Series.write_tick(tracked.id, row(episode, false))

    ticks =
      Watch
      |> Ash.Query.for_read(:episode_ticks, %{tracked_title_id: tracked.id})
      |> Ash.read!()

    assert CachedEpisode.ticked?(episode, CachedEpisode.ticked_ids(ticks))
  end

  describe "what cannot be written against" do
    test "a series nobody has tracked", %{episode: episode} do
      assert {:error, :not_tracked} = Series.write_tick(nil, row(episode, false))
      assert Ash.count!(Watch) == 0
    end

    test "an episode the cache has no id for", %{tracked: tracked} do
      assert {:error, :no_episode_id} =
               Series.write_tick(tracked.id, %{source_id: nil, watched: false})

      assert Ash.count!(Watch) == 0
    end

    test "no episode at all", %{tracked: tracked} do
      assert {:error, :no_episode} = Series.write_tick(tracked.id, nil)
    end
  end
end
