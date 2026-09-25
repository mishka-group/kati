defmodule Kati.SeriesSpoilerSafeTest do
  @moduledoc """
  *Hide unwatched titles* does something on the screen it is named for.

  `Kati.Media.TrackedTitle.hide_unwatched_titles` is annotated in the resource
  itself — *"Spoiler-safe episode names on screen 04."* Screen 35 writes it and
  `Kati.Screens.RateEpisode` reads it for its own headline. **Screen 04 never
  did.** A reader turned the switch on in Show settings, came back to the
  episode list, and every unwatched title was still spelled out: the one place
  the setting claims to act was the one place it did nothing.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Series

  @prefix "spoiler-safe-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM media_watches", [])
      Kati.Repo.query!("DELETE FROM cached_episodes WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  defp show!(hide?) do
    id = @prefix <> "show"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: id,
      kind: :tv,
      title: "The Quiet Ones",
      fetched_at: Kati.Time.now()
    })

    for n <- 1..2 do
      Ash.create!(CachedEpisode, %{
        source: :tmdb,
        source_id: @prefix <> "ep#{n}",
        title_source_id: id,
        season_number: 1,
        episode_number: n,
        title: "The Secret Of Episode #{n}",
        fetched_at: Kati.Time.now()
      })
    end

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: id,
      kind: :tv,
      status: :watching,
      hide_unwatched_titles: hide?
    })
  end

  defp titles(tracked) do
    Series.series(tracked.id).episodes |> Enum.map(& &1.title)
  end

  test "off, every episode is named — which is board 04" do
    tracked = show!(false)

    assert titles(tracked) == ["The Secret Of Episode 1", "The Secret Of Episode 2"]
  end

  test "on, an unwatched episode is its number instead" do
    tracked = show!(true)

    assert titles(tracked) == ["Episode 1", "Episode 2"],
           "the switch is on and screen 04 is still spelling the titles out"
  end

  test "and a watched one keeps its name, because it is not a spoiler" do
    tracked = show!(true)

    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      episode_source_id: @prefix <> "ep1",
      season_number: 1,
      episode_number: 1,
      watched_at: Kati.Time.now()
    })

    assert titles(tracked) == ["The Secret Of Episode 1", "Episode 2"],
           "hiding what the reader has already seen makes the list unreadable " <>
             "for the very person who turned the switch on"
  end

  test "and the mask is the string the rating sheet already uses" do
    # One sentence, two screens: `episode_title/2`'s mask is the numbered form
    # it already falls back to for an episode a provider never named, which is
    # what `Kati.Screens.RateEpisode` masks with. Nothing new for a translator.
    tracked = show!(true)

    assert "Episode 1" in titles(tracked)
  end
end
