defmodule Kati.NextEpisodeTest do
  @moduledoc """
  Home and screen 10 name the same next episode (N15), and an anime film on
  Home says how long it is (N16).
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.NextEpisode
  alias Kati.Media.TrackedTitle

  doctest Kati.Media.NextEpisode

  @prefix "next-episode-"

  setup do
    wipe = fn ->
      Kati.Repo.query!("DELETE FROM cached_episodes WHERE title_source_id LIKE ?1", [
        @prefix <> "%"
      ])

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end

    wipe.()
    on_exit(wipe)
    :ok
  end

  defp series!(slug, bookmark) do
    id = @prefix <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: id,
      kind: :tv,
      title: slug,
      episode_count: 4,
      fetched_at: Kati.Time.now()
    })

    for {s, e} <- [{0, 1}, {1, 1}, {1, 2}, {2, 1}, {2, 2}] do
      Ash.create!(CachedEpisode, %{
        source: :tmdb,
        source_id: "#{id}-#{s}-#{e}",
        title_source_id: id,
        season_number: s,
        episode_number: e,
        special: s == 0,
        fetched_at: Kati.Time.now()
      })
    end

    {s, e} = bookmark || {nil, nil}

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: id,
      kind: :tv,
      status: :watching,
      progress_season: s,
      progress_episode: e,
      last_touched_at: Kati.Time.now()
    })
  end

  test "the next episode crosses into the next season" do
    assert NextEpisode.of(series!("crossing", {1, 2})) == {2, 1}
  end

  test "nothing watched starts at the first episode, not the special" do
    assert NextEpisode.of(series!("fresh", nil)) == {1, 1}
  end

  test "caught up has no next episode" do
    assert NextEpisode.of(series!("done", {2, 2})) == nil
  end

  test "Home and screen 10 say the same thing" do
    tracked = series!("agree", {1, 2})

    home =
      Kati.Screens.Home.continue_meta(%{id: tracked.id, meta: "S1 · E99"})

    assert home == "S2 · E1", "Home still counts ticks inside season 1"

    %{hero: hero} = Kati.Screens.UpNext.queue()
    assert hero.meta =~ "S2 · E1", "screen 10 still prints the bookmark, not the next episode"
  end

  test "an anime film on the shelf says how long it is" do
    id = @prefix <> "film"

    cached =
      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: id,
        kind: :movie,
        title: "Spirited Away",
        runtime_minutes: 125,
        fetched_at: Kati.Time.now()
      })

    tracked =
      Ash.create!(TrackedTitle, %{source: :tmdb, source_id: id, kind: :anime, status: :watching})

    assert Kati.Screens.Library.meta_for(tracked, cached, 0) == "2h 5m"
  end
end
