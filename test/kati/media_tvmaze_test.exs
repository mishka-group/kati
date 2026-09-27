defmodule Kati.MediaTvmazeTest do
  @moduledoc """
  `Kati.Media.Tvmaze` against canned TVmaze answers.

  TVmaze is a stub handed to Req through `:tvmaze_req_options`, so nothing
  here reaches the network. The shapes are TVmaze's own `/search/shows` and
  `/shows/:id?embed[]=seasons&embed[]=episodes` answers, cut down.
  """
  use ExUnit.Case, async: false

  doctest Kati.Media.Tvmaze

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Provider
  alias Kati.Media.Tvmaze

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :tvmaze_test_stub).(request)
  end

  setup do
    wipe!()

    on_exit(fn ->
      Kati.TestOffline.restore(:tvmaze_req_options)
      Application.delete_env(:kati, :tvmaze_test_stub)
      wipe!()
    end)

    :ok
  end

  describe "search" do
    test "an empty query asks TVmaze nothing" do
      stub(fn _req -> flunk("the empty query reached the network") end)
      assert {:ok, []} = Tvmaze.search("")
    end

    test "shows come back as series, with TVmaze as their source" do
      test_pid = self()

      stub(fn req ->
        send(test_pid, {:asked, URI.to_string(req.url)})

        json(req, 200, [
          %{"score" => 0.9, "show" => show()},
          %{"score" => 0.1, "show" => %{"id" => 2, "name" => nil}}
        ])
      end)

      assert {:ok, [row]} = Tvmaze.search("sakamoto days")
      assert_received {:asked, "https://api.tvmaze.com/search/shows?q=sakamoto+days"}

      assert %{
               title: "Sakamoto Days",
               kind: :tv,
               source: :tvmaze,
               source_id: "77777",
               year: "2025",
               overview: "A legendary hitman retires & opens a shop.",
               poster_path: "https://static.tvmaze.com/uploads/images/medium_portrait/1/1.jpg"
             } = row
    end

    test "a failure is a reason, never a raise, and has TVmaze's name in its sentence" do
      stub(fn req -> json(req, 429, "") end)
      assert {:error, :rate_limited} = Tvmaze.search("sakamoto")

      stub(fn req -> json(req, 503, "") end)
      assert {:error, {:http, 503} = reason} = Tvmaze.search("sakamoto")
      assert Provider.message(:tvmaze, reason) == "TVmaze answered 503. Nothing was saved."
    end
  end

  describe "fetch" do
    test "a show writes its title, real seasons and real episodes" do
      test_pid = self()

      stub(fn req ->
        send(test_pid, {:asked, URI.to_string(req.url)})
        json(req, 200, Map.put(show(), "_embedded", embedded()))
      end)

      assert {:ok, %{title: %CachedTitle{} = title, seasons: 1, episodes: 3}} =
               Tvmaze.fetch("77777", :tv)

      assert_received {:asked, url}
      assert url =~ "https://api.tvmaze.com/shows/77777?"
      assert url =~ "embed%5B%5D=seasons"
      assert url =~ "embed%5B%5D=episodes"

      assert title.source == :tvmaze
      assert title.kind == :tv
      assert title.original_language == "ja"
      assert title.genres == "Animation, Action, Anime"
      assert title.tvmaze_id == "77777"
      assert title.imdb_id == "tt31265720"
      assert title.episode_count == 2

      assert title.poster_path ==
               "https://static.tvmaze.com/uploads/images/original_untouched/1/1.jpg"

      assert Kati.Media.Anime.provider_says?(title)

      assert [%CachedSeason{season_number: 1, episode_count: 11, source_id: "900"}] =
               CachedSeason.for_title(:tvmaze, "77777")

      episodes = CachedEpisode.for_title(:tvmaze, "77777")
      pilot = Enum.find(episodes, &(&1.source_id == "5001"))
      special = Enum.find(episodes, &(&1.source_id == "5003"))

      assert pilot.title == "Legendary Hitman"
      assert pilot.season_number == 1 and pilot.episode_number == 1
      assert pilot.runtime_minutes == 24
      assert pilot.overview == "Sakamoto's peace ends."
      assert pilot.date_confidence == :exact
      assert pilot.air_at == ~U[2025-01-11 14:30:00.000000Z]

      assert special.special
      assert special.season_number == 0
      assert special.episode_number == nil
      assert special.date_confidence == :day

      assert {:ok, %{episodes: 3}} = Tvmaze.fetch("77777", :tv)
      assert length(CachedEpisode.for_title(:tvmaze, "77777")) == 3
    end

    test "an id TVmaze does not know" do
      stub(fn req -> json(req, 404, %{"name" => "Not Found"}) end)
      assert {:error, :not_found} = Tvmaze.fetch("123456789", :tv)
      assert Provider.message(:tvmaze, :not_found) == "TVmaze has nothing under that id."
    end
  end

  defp show do
    %{
      "id" => 77_777,
      "name" => "Sakamoto Days",
      "type" => "Animation",
      "language" => "Japanese",
      "genres" => ["Action", "Anime"],
      "premiered" => "2025-01-11",
      "summary" => "<p>A legendary hitman retires &amp; opens a shop.</p>",
      "externals" => %{"imdb" => "tt31265720", "thetvdb" => 431_111},
      "image" => %{
        "medium" => "https://static.tvmaze.com/uploads/images/medium_portrait/1/1.jpg",
        "original" => "https://static.tvmaze.com/uploads/images/original_untouched/1/1.jpg"
      }
    }
  end

  defp embedded do
    %{
      "seasons" => [
        %{
          "id" => 900,
          "number" => 1,
          "name" => "",
          "episodeOrder" => 11,
          "premiereDate" => "2025-01-11",
          "image" => nil
        }
      ],
      "episodes" => [
        %{
          "id" => 5001,
          "name" => "Legendary Hitman",
          "season" => 1,
          "number" => 1,
          "type" => "regular",
          "airdate" => "2025-01-11",
          "airstamp" => "2025-01-11T14:30:00+00:00",
          "runtime" => 24,
          "summary" => "<p>Sakamoto's peace ends.</p>"
        },
        %{
          "id" => 5002,
          "name" => "Vs. Assassins",
          "season" => 1,
          "number" => 2,
          "airdate" => "2025-01-18",
          "airstamp" => "2025-01-18T14:30:00+00:00",
          "runtime" => 24,
          "summary" => nil
        },
        %{
          "id" => 5003,
          "name" => "Recap",
          "season" => 1,
          "number" => nil,
          "type" => "significant_special",
          "airdate" => "2025-02-01",
          "airstamp" => nil,
          "runtime" => nil
        }
      ]
    }
  end

  defp stub(fun) do
    Application.put_env(:kati, :tvmaze_test_stub, fun)
    Application.put_env(:kati, :tvmaze_req_options, adapter: Adapter, retry: false)
  end

  defp json(req, status, body), do: {req, Req.Response.new(status: status, body: body)}

  defp wipe! do
    for table <- ~w(cached_episodes cached_seasons cached_titles) do
      Kati.Repo.query!("DELETE FROM " <> table, [])
    end
  end
end
