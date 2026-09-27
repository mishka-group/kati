defmodule Kati.MediaAnilistTest do
  @moduledoc """
  `Kati.Media.Anilist` against canned AniList answers.

  AniList is a stub handed to Req through `:anilist_req_options` — the seam
  `Kati.MediaTmdbTest` uses for TMDB — so nothing here reaches the network.
  The shapes are AniList's own GraphQL answers for *SAKAMOTO DAYS* (177709),
  a series, and *Kimi no Na wa.* (21519), a film.
  """
  use ExUnit.Case, async: false

  doctest Kati.Media.Anilist
  doctest Kati.Media.Provider

  alias Kati.Media.Anilist
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Provider

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :anilist_test_stub).(request)
  end

  setup do
    wipe!()

    on_exit(fn ->
      Kati.TestOffline.restore(:anilist_req_options)
      Application.delete_env(:kati, :anilist_test_stub)
      wipe!()
    end)

    :ok
  end

  describe "search" do
    test "an empty query asks AniList nothing" do
      stub(fn _req -> flunk("the empty query reached the network") end)
      assert {:ok, []} = Anilist.search("   ")
    end

    test "series and films come back shaped, with AniList as their source" do
      test_pid = self()

      stub(fn req ->
        send(test_pid, {:asked, req.method, URI.to_string(req.url), Jason.decode!(req.body)})

        json(req, 200, %{
          "data" => %{
            "Page" => %{
              "media" => [sakamoto(), your_name(), %{"id" => 3, "title" => %{}}]
            }
          }
        })
      end)

      assert {:ok, [series, film]} = Anilist.search(" sakamoto ")

      assert_received {:asked, :post, "https://graphql.anilist.co",
                       %{"variables" => %{"s" => "sakamoto"}} = body}

      assert body["query"] =~ "type:ANIME"

      assert %{
               title: "SAKAMOTO DAYS",
               kind: :tv,
               source: :anilist,
               source_id: "177709",
               year: "2025",
               poster_path:
                 "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177709.jpg"
             } = series

      assert series.overview == "Taro Sakamoto was the ultimate assassin. Then he fell in love."

      assert %{title: "Your Name.", kind: :movie, source_id: "21519", year: "2016"} = film
    end

    test "a failure is a reason, never a raise" do
      stub(fn req -> json(req, 429, %{"errors" => [%{"message" => "Too Many Requests."}]}) end)
      assert {:error, :rate_limited} = Anilist.search("sakamoto")

      stub(fn req -> json(req, 500, "") end)
      assert {:error, {:http, 500}} = Anilist.search("sakamoto")

      stub(fn _req -> raise "the socket went away" end)
      assert {:error, reason} = Anilist.search("sakamoto")

      assert reason == :blocked or match?({:network, _}, reason),
             "a transport failure came back as #{inspect(reason)}"
    end

    test "every failure has a sentence with AniList's name in it" do
      for reason <- [:rate_limited, :not_found, {:http, 502}, {:network, :timeout}, :blocked] do
        assert Provider.message(:anilist, reason) =~ "AniList"
      end

      assert Provider.message(:anilist, {:error, :blocked}) =~ "blocking AniList"
    end
  end

  describe "fetch" do
    test "a series is one title, one season and an episode per count, with stable ids" do
      stub(fn req -> json(req, 200, %{"data" => %{"Media" => sakamoto()}}) end)

      assert {:ok, %{title: %CachedTitle{} = title, seasons: 1, episodes: 11}} =
               Anilist.fetch("177709", :tv)

      assert title.source == :anilist
      assert title.kind == :tv
      assert title.original_language == "ja"
      assert title.genres == "Animation, Action, Comedy"
      assert title.anilist_id == "177709"
      assert title.mal_id == "58939"
      assert title.episode_count == 11
      assert title.first_release_year == 2025
      assert title.poster_path =~ "https://s4.anilist.co/"

      assert Kati.Media.Anime.provider_says?(title),
             "an AniList series is not classified as anime"

      assert [%CachedSeason{season_number: 1, episode_count: 11}] =
               CachedSeason.for_title(:anilist, "177709")

      episodes = CachedEpisode.for_title(:anilist, "177709")
      assert Enum.map(episodes, & &1.episode_number) == Enum.to_list(1..11)
      assert Enum.map(episodes, & &1.source_id) == Enum.map(1..11, &"177709-#{&1}")
      assert Enum.all?(episodes, &(&1.runtime_minutes == 23 and &1.season_number == 1))

      aired = Enum.find(episodes, &(&1.episode_number == 11))
      assert aired.date_confidence == :exact
      assert DateTime.to_unix(aired.air_at) == 1_742_000_000

      assert {:ok, %{episodes: 11}} = Anilist.fetch("177709", :tv)

      assert length(CachedEpisode.for_title(:anilist, "177709")) == 11,
             "a second fetch wrote the episodes twice"
    end

    test "a film is one row, with its runtime" do
      stub(fn req -> json(req, 200, %{"data" => %{"Media" => your_name()}}) end)

      assert {:ok, %{title: title, seasons: 0, episodes: 0}} = Anilist.fetch("21519", :movie)
      assert title.kind == :movie
      assert title.runtime_minutes == 106
      assert CachedEpisode.for_title(:anilist, "21519") == []
    end

    test "an id AniList does not know, and one that is not an id at all" do
      stub(fn req -> json(req, 404, %{"data" => %{"Media" => nil}}) end)
      assert {:error, :not_found} = Anilist.fetch("999999999", :tv)

      stub(fn _req -> flunk("a non-numeric id reached the network") end)
      assert {:error, :not_found} = Anilist.fetch("not-a-number", :tv)
    end
  end

  defp sakamoto do
    %{
      "id" => 177_709,
      "idMal" => 58_939,
      "format" => "TV",
      "episodes" => 11,
      "duration" => 23,
      "title" => %{
        "romaji" => "SAKAMOTO DAYS",
        "english" => "SAKAMOTO DAYS",
        "native" => "SAKAMOTO DAYS"
      },
      "coverImage" => %{
        "large" => "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177709.jpg",
        "extraLarge" =>
          "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177709.jpg"
      },
      "startDate" => %{"year" => 2025, "month" => 1, "day" => 11},
      "countryOfOrigin" => "JP",
      "description" =>
        "Taro Sakamoto was the ultimate assassin.<br><br>\nThen he fell in <i>love</i>.",
      "genres" => ["Action", "Comedy"],
      "nextAiringEpisode" => %{"episode" => 11, "airingAt" => 1_742_000_000}
    }
  end

  defp your_name do
    %{
      "id" => 21_519,
      "format" => "MOVIE",
      "episodes" => 1,
      "duration" => 106,
      "title" => %{"romaji" => "Kimi no Na wa.", "english" => "Your Name.", "native" => "君の名は。"},
      "coverImage" => %{
        "large" => "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21519.png"
      },
      "startDate" => %{"year" => 2016, "month" => 8, "day" => 26},
      "countryOfOrigin" => "JP",
      "description" => "Two strangers find themselves linked.",
      "genres" => ["Drama", "Romance", "Supernatural"]
    }
  end

  defp stub(fun) do
    Application.put_env(:kati, :anilist_test_stub, fun)
    Application.put_env(:kati, :anilist_req_options, adapter: Adapter, retry: false)
  end

  defp json(req, status, body), do: {req, Req.Response.new(status: status, body: body)}

  defp wipe! do
    for table <- ~w(cached_episodes cached_seasons cached_titles) do
      Kati.Repo.query!("DELETE FROM " <> table, [])
    end
  end
end
