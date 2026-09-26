defmodule Kati.CacheRefreshKindTest do
  @moduledoc """
  A refresh asks TMDB's film endpoint for an anime film.

  `Cache.tmdb_kind/1` sent every non-`:movie` kind to the TV endpoint, so the
  release watcher's *Check now* refetched *Spirited Away* (film 129, tracked as
  `:anime`) as TV 129 and wrote *Soccer Aid* over it. Found on the Pixel 9a.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Media.Cache, only: [tmdb_kind: 2]

  @prefix "refresh-kind-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  test "an anime whose cached row is a film is refreshed as a film" do
    id = @prefix <> "film"

    Ash.create!(Kati.Media.CachedTitle, %{
      source: :tmdb,
      source_id: id,
      kind: :movie,
      title: "Spirited Away",
      runtime_minutes: 125,
      fetched_at: Kati.Time.now()
    })

    tracked =
      Ash.create!(Kati.Media.TrackedTitle, %{
        source: :tmdb,
        source_id: id,
        kind: :anime,
        status: :finished
      })

    cached =
      Kati.Media.CachedTitle |> Ash.read!() |> Enum.find(&(&1.source_id == id))

    assert Kati.Media.Cache.tmdb_kind(tracked, cached) == :movie
  end
end
