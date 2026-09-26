Code.require_file("../support/show_boards.exs", __DIR__)

defmodule Kati.SeriesPagesRealIdTest do
  @moduledoc """
  The three series pages — 04 *Series*, 14 *Show details* and 35 *Show
  settings* — opened the way the app opens them, over a real show and over one
  that has gone, in both locales.

  `Kati.ScreenParamsSweepTest` holds the id that names nothing against a bare
  push. This holds the other direction for these three pages: an id that names
  a real row never draws a word of the board's own show. The boards are test
  fixtures now — `Kati.Library.Sample` and `Kati.Test.ShowBoards` — and the
  strings taken from them below are the ones that are claims about a show
  (its name, its synopsis, its cast, its region, its prices), not the app's
  own vocabulary that a real show shares with the board.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle

  @prefix "series-pages-real-"
  @pages [
    {Kati.Screens.Series, :id},
    {Kati.Screens.SeriesMeta, :id},
    {Kati.Screens.SeriesSettings, :tracked_id}
  ]

  setup do
    on_exit(fn ->
      for table <- ~w(tracked_titles cached_titles) do
        Kati.Repo.query!("DELETE FROM #{table} WHERE source_id LIKE ?1", [@prefix <> "%"])
      end

      for table <- ~w(cached_seasons cached_episodes) do
        Kati.Repo.query!("DELETE FROM #{table} WHERE title_source_id LIKE ?1", [@prefix <> "%"])
      end
    end)

    %{tracked: series!()}
  end

  for locale <- [:en, :fa], {module, key} <- @pages do
    test "#{inspect(module)} over a real #{key} draws none of the board's show (#{locale})", %{
      tracked: tracked
    } do
      Kati.Locale.as(unquote(locale), fn ->
        words = words(unquote(module), %{unquote(key) => tracked.id})

        assert Enum.any?(words, &(&1 =~ "Hollowmere")),
               "the page over a real show does not name it"

        leaked = Enum.filter(board_claims(), fn claim -> Enum.any?(words, &(&1 =~ claim)) end)

        assert leaked == [],
               "#{inspect(unquote(module))} opened over a real show drew the board's own " <>
                 "#{inspect(leaked)}"
      end)
    end

    test "#{inspect(module)} over a #{key} that has gone says so (#{locale})" do
      Kati.Locale.as(unquote(locale), fn ->
        words = words(unquote(module), %{unquote(key) => Ecto.UUID.generate()})

        assert Enum.any?(
                 words,
                 &(&1 == Gettext.gettext(Kati.Gettext, "This title is no longer in your library"))
               )

        leaked = Enum.filter(board_claims(), fn claim -> Enum.any?(words, &(&1 =~ claim)) end)
        assert leaked == []
      end)
    end
  end

  defp words(module, params) do
    {:ok, socket} = module.mount(params, %{}, Mob.Socket.new(module))

    socket.assigns
    |> module.render()
    |> find_all(:text)
    |> Enum.map(&(&1.props[:text] || ""))
    |> Enum.reject(&(&1 == ""))
  end

  defp board_claims do
    series = Kati.Library.Sample.series()
    meta = Kati.Test.ShowBoards.series_meta()

    [
      series.title,
      Kati.Test.ShowBoards.series_settings().title,
      meta.title,
      meta.synopsis
    ]
    |> Kernel.++(Enum.map(series.episodes, & &1.title))
    |> Kernel.++(Enum.flat_map(meta.cast, &[&1.name, &1.role]))
    |> Kernel.++(Enum.map(meta.where, & &1.name))
    |> Kernel.++(meta.tags)
    |> Kernel.++(board_35_rows())
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  # Board 35's rows with nothing behind them, which no face of screen 35 draws.
  defp board_35_rows do
    [
      "Auto-add new seasons",
      "S4 will appear when announced",
      "Put air dates on calendar",
      "Personal · orange",
      "United Kingdom",
      "Lumen+, Orbit, Kino · 3 of 12",
      "Watch for price drops",
      "Wishlist titles under £8",
      "Preferred quality",
      "4K HDR where offered",
      "Reset progress",
      "Currently 5 of 7 in S2",
      "Archive",
      "Keeps history, hides from shelf"
    ]
  end

  defp series! do
    source_id = @prefix <> "hollowmere"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: "Hollowmere",
      overview: "A ferry town keeps its own clocks.",
      genres: "Drama",
      episode_count: 2,
      fetched_at: DateTime.utc_now()
    })

    Ash.create!(CachedSeason, %{
      source: :tmdb,
      title_source_id: source_id,
      season_number: 1,
      episode_count: 2,
      fetched_at: DateTime.utc_now()
    })

    for n <- 1..2 do
      Ash.create!(CachedEpisode, %{
        source: :tmdb,
        source_id: "#{source_id}-e#{n}",
        title_source_id: source_id,
        season_number: 1,
        episode_number: n,
        title: "Hollowmere night #{n}",
        runtime_minutes: 45,
        air_at: DateTime.add(DateTime.utc_now(), -30 + n, :day),
        date_confidence: :day,
        fetched_at: DateTime.utc_now()
      })
    end

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching
    })
  end
end
