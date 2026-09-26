Code.require_file("../support/show_boards.exs", __DIR__)

defmodule Kati.GroupARealTest do
  @moduledoc """
  N52-A: the six film and series pages — 08 *Film*, 04 *Series*, 34 *Episode
  order*, 14 *Show details*, 35 *Show settings* and 143 *Episode ratings* —
  draw the reader's own data or an honest empty page, and never a board.

  Two halves, both through the screen's own `mount/3` and `render/1`, which is
  the path a reader's push takes:

    * **nothing to draw** — an empty store, a bare push and an id that names
      nothing each render one sentence, and not one string of any board's
      show: its name, its episodes, its services, its figures.
    * **the reader's own** — a film and a series seeded through the Ash
      resources (`TrackedTitle`, `CachedTitle`, `CachedSeason`,
      `CachedEpisode`, `Watch`), and each page draws those values.

  The store is shared by the whole suite, so the empty half empties the tables
  it reads rather than assuming them empty.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens
  alias Kati.Test.ShowBoards

  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles
             cached_seasons cached_episodes)

  @pages [
    {Screens.Film, :id},
    {Screens.Series, :id},
    {Screens.Season, :title_id},
    {Screens.SeriesMeta, :id},
    {Screens.SeriesSettings, :tracked_id},
    {Screens.EpisodeRatings, :title_id}
  ]

  setup do
    empty!()
    on_exit(&empty!/0)
    :ok
  end

  defp empty! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  describe "with nothing to draw" do
    for {module, key} <- @pages do
      test "#{inspect(module)} draws no board, bare or over an id that names nothing" do
        for params <- [%{}, %{unquote(key) => Ecto.UUID.generate()}] do
          words = words(unquote(module), params)

          leaked = Enum.filter(board_strings(), fn s -> Enum.any?(words, &(&1 =~ s)) end)

          assert leaked == [],
                 "#{inspect(unquote(module))} with #{inspect(params)} drew #{inspect(leaked)}"

          assert Enum.any?(words, &(&1 in honest_sentences())),
                 "#{inspect(unquote(module))} with #{inspect(params)} drew no sentence " <>
                   "saying why it is empty: #{inspect(words)}"
        end
      end
    end

    test "and no page draws a control over nothing" do
      for {module, _key} <- @pages do
        tree = render(module, %{})
        taps = tree |> flatten() |> Enum.map(& &1.props[:on_tap]) |> Enum.reject(&is_nil/1)

        assert Enum.all?(taps, &match?({_pid, :back}, &1)),
               "#{inspect(module)} drew #{inspect(taps)} over an empty store"
      end
    end
  end

  describe "with the reader's own film" do
    test "screen 08 draws its title, meta line, watch, rating and note" do
      tracked = film!()
      words = words(Screens.Film, %{id: tracked.id})

      assert "Tokyo Story" in words
      assert "1953 · 2H 16M · DRAMA" in words
      assert "Watched 12 Mar" in words
      assert "1 time" in words
      assert "Still the quietest ending." in words
      refute Enum.any?(board_strings(), fn s -> Enum.any?(words, &(&1 =~ s)) end)
    end
  end

  describe "with the reader's own series" do
    setup do
      %{tracked: series!()}
    end

    test "screen 04 draws its title, its episodes and the tick", %{tracked: tracked} do
      words = words(Screens.Series, %{id: tracked.id})

      assert "Saltmarsh" in words
      assert "The Ferry" in words
      assert "The Lighthouse" in words
      assert "1 of 2 watched" in words
      assert "DRAMA · 1 SEASON" in words
    end

    test "screen 34 draws the same season, in aired order", %{tracked: tracked} do
      words = words(Screens.Season, %{title_id: tracked.id, season: 1})

      assert "Season 1" in words
      assert "The Ferry" in words
      assert "The Lighthouse" in words
      assert "E1" in words
      refute "DVD" in words
    end

    test "screen 14 draws its title, synopsis and the reader's own trio", %{tracked: tracked} do
      words = words(Screens.SeriesMeta, %{id: tracked.id})

      assert "Saltmarsh" in words
      assert "A tide clock runs a village." in words
      assert "1 / 2" in words
      refute "Trailer" in words
    end

    test "screen 35 lights the show's own status and draws its live rows", %{tracked: tracked} do
      show = Screens.SeriesSettings.show(%{tracked_id: tracked.id})

      assert show.title == "Saltmarsh"

      assert [%{status: :watching}] =
               Enum.filter(Screens.SeriesSettings.status_tiles(show), & &1.on)

      words = words(Screens.SeriesSettings, %{tracked_id: tracked.id})
      assert "Saltmarsh" in words
      assert "Tell me about episodes" in words
      refute "Auto-add new seasons" in words
      refute "Reset progress" in words
    end

    test "screen 143 draws the show, the season and the rating given", %{tracked: tracked} do
      words = words(Screens.EpisodeRatings, %{title_id: tracked.id, season: 1})

      assert "Saltmarsh" in words
      assert "SEASON 1 · 1 OF 2 RATED" in words
      assert "The Ferry" in words
      assert "4" in words
      refute "Hold a row to rate it" in words
    end

    test "a bare push to 35, 34, 14 and 143 draws the shelf's series, not a board" do
      for module <- [
            Screens.SeriesSettings,
            Screens.Season,
            Screens.SeriesMeta,
            Screens.EpisodeRatings
          ] do
        words = words(module, %{})

        assert Enum.any?(words, &(&1 in ["Saltmarsh", "Season 1"])),
               "#{inspect(module)} bare did not draw the reader's series: #{inspect(words)}"

        refute Enum.any?(board_strings(), fn s -> Enum.any?(words, &(&1 =~ s)) end)
      end
    end
  end

  defp words(module, params) do
    module
    |> render(params)
    |> find_all(:text)
    |> Enum.map(&(&1.props[:text] || ""))
    |> Enum.reject(&(&1 == ""))
  end

  defp render(module, params) do
    Kati.Locale.activate()
    {:ok, socket} = module.mount(params, %{}, Mob.Socket.new(module))
    module.render(socket.assigns)
  end

  defp honest_sentences do
    [
      "No films in your library yet",
      "No series in your library yet",
      "This title is no longer in your library",
      "No episode list yet."
    ]
  end

  # What a board claims about a show nobody tracked: names, episodes,
  # services, figures and seeds, from every board these six pages were drawn
  # from.
  defp board_strings do
    film = Kati.Library.Sample.film()
    series = ShowBoards.series()
    season = ShowBoards.season()
    meta = ShowBoards.series_meta()
    ratings = ShowBoards.episode_ratings()

    [
      film.title,
      film.note,
      series.title,
      meta.synopsis,
      "The Long Hollow",
      "Blue Hour",
      "Lumen+",
      "hollow71",
      "Auto-add new seasons",
      "Reset progress",
      "Hold a row to rate it",
      "Trailer"
    ]
    |> Kernel.++(Enum.map(series.episodes, & &1.title))
    |> Kernel.++(Enum.map(season.episodes, & &1.title))
    |> Kernel.++(Enum.map(ratings.episodes, & &1.title))
    |> Kernel.++(Enum.map(meta.cast, & &1.name))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
  end

  defp film! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: "group-a-film",
      kind: :movie,
      title: "Tokyo Story",
      first_release_year: 1953,
      runtime_minutes: 136,
      genres: "Drama",
      fetched_at: DateTime.utc_now()
    })

    tracked =
      Ash.create!(TrackedTitle, %{
        source: :tmdb,
        source_id: "group-a-film",
        kind: :movie,
        status: :finished
      })

    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      watched_on: ~D[2026-03-12],
      rating: 8,
      review: "Still the quietest ending."
    })
    |> Ash.create!()

    tracked
  end

  defp series! do
    source_id = "group-a-series"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: "Saltmarsh",
      overview: "A tide clock runs a village.",
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

    for {n, title} <- [{1, "The Ferry"}, {2, "The Lighthouse"}] do
      Ash.create!(CachedEpisode, %{
        source: :tmdb,
        source_id: "#{source_id}-e#{n}",
        title_source_id: source_id,
        season_number: 1,
        episode_number: n,
        title: title,
        runtime_minutes: 45,
        air_at: DateTime.add(DateTime.utc_now(), -30 + n, :day),
        date_confidence: :day,
        fetched_at: DateTime.utc_now()
      })
    end

    tracked =
      Ash.create!(TrackedTitle, %{
        source: :tmdb,
        source_id: source_id,
        kind: :tv,
        status: :watching,
        progress_season: 1
      })

    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      episode_source_id: "#{source_id}-e1",
      season_number: 1,
      episode_number: 1,
      watched_at: Kati.Time.now(),
      rating: 8
    })
    |> Ash.create!()

    tracked
  end
end
