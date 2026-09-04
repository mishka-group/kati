defmodule Kati.MediaTmdbTest do
  @moduledoc """
  `Kati.Media.Tmdb` against canned TMDB responses and against the real one.

  The canned half is the whole of what runs by default: a plug handed to Req
  through `:tmdb_req_options` answers the three endpoints with the shapes TMDB
  actually returns, captured from a live call to `Severance` (95396). Parsing
  and the three cache writes are asserted against those.

  The live half is tagged `:live` and excluded, because a test that needs the
  network and somebody's key is a test that fails for reasons the code did not
  cause. Run it with a key present:

      set -a; . ~/.config/kati/tmdb.env; set +a
      mix test test/kati/media_tmdb_test.exs --include live
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Tmdb

  # Captured once, before any test replaces it with the stub token. A per-test
  # `setup` cannot do this: by the second test the value it reads is the stub
  # its own predecessor left behind, and the live test then authenticates with
  # "test-token" and is told so by TMDB.
  setup_all do
    :persistent_term.put({__MODULE__, :real_token}, System.get_env("TMDB_READ_TOKEN"))
    :ok
  end

  setup do
    real = :persistent_term.get({__MODULE__, :real_token}, nil)
    System.put_env("TMDB_READ_TOKEN", "test-token")

    on_exit(fn ->
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :tmdb_test_stub)

      for table <- ~w(cached_episodes cached_seasons cached_titles) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    {:ok, real_token: real}
  end

  # A Req `adapter:` and not a `plug:`. Req's plug option needs the `:plug`
  # dependency, which this project does not have.
  #
  # The adapter is a module rather than the bare function Req 0.7 deprecates,
  # and the function it runs is held in application env — one indirection, and
  # it keeps the test output free of a deprecation warning that would otherwise
  # print once per stubbed request.
  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :tmdb_test_stub).(request)
  end

  defp stub(fun) do
    Application.put_env(:kati, :tmdb_test_stub, fun)
    Application.put_env(:kati, :tmdb_req_options, adapter: Adapter)
  end

  defp json(req, status, body) do
    {req, Req.Response.new(status: status, body: body)}
  end

  describe "search" do
    test "an empty query asks TMDB nothing" do
      stub(fn _req -> flunk("the empty query reached the network") end)

      assert {:ok, []} = Tmdb.search("   ")
    end

    test "films and series come back shaped; people do not come back at all" do
      stub(fn req ->
        json(req, 200, %{
          "results" => [
            %{
              "media_type" => "tv",
              "id" => 95_396,
              "name" => "Severance",
              "first_air_date" => "2022-02-17",
              "overview" => "Mark leads a team.",
              "poster_path" => "/p.jpg"
            },
            %{
              "media_type" => "movie",
              "id" => 5072,
              "title" => "Severance",
              "release_date" => "2006-06-16"
            },
            %{"media_type" => "person", "id" => 1, "name" => "Adam Scott"}
          ]
        })
      end)

      assert {:ok, [series, film]} = Tmdb.search("severance")

      assert series.kind == :tv
      assert series.source_id == "95396"
      assert series.year == "2022"
      assert series.poster_path == "/p.jpg"

      assert film.kind == :movie
      assert film.year == "2006"

      # A person is not a title. `/search/multi` returns them and nothing in
      # Kati can track one, so a search row is always something addable.
      refute Enum.any?([series, film], &(&1.title == "Adam Scott"))
    end

    test "a row with no usable title is dropped rather than drawn blank" do
      stub(fn req ->
        json(req, 200, %{"results" => [%{"media_type" => "tv", "id" => 9, "name" => ""}]})
      end)

      assert {:ok, []} = Tmdb.search("nothing")
    end
  end

  describe "fetch, and what reaches the store" do
    test "a series writes its title, its seasons and every episode" do
      stub(fn req ->
        case req.url.path do
          "/3/tv/95396" ->
            json(req, 200, %{
              "id" => 95_396,
              "name" => "Severance",
              "original_name" => "Severance",
              "overview" => "Mark leads a team.",
              "poster_path" => "/p.jpg",
              "number_of_episodes" => 19,
              "genres" => [%{"name" => "Drama"}, %{"name" => "Mystery"}],
              "seasons" => [
                %{"id" => 1, "season_number" => 1, "episode_count" => 2, "air_date" => "2022-02-17"}
              ]
            })

          "/3/tv/95396/season/1" ->
            json(req, 200, %{
              "episodes" => [
                %{
                  "id" => 2_337_670,
                  "season_number" => 1,
                  "episode_number" => 1,
                  "name" => "Good News About Hell",
                  "air_date" => "2022-02-17",
                  "runtime" => 59
                },
                %{
                  "id" => 2_337_671,
                  "season_number" => 1,
                  "episode_number" => 2,
                  "name" => "Half Loop",
                  "air_date" => "2022-02-17"
                }
              ]
            })
        end
      end)

      assert {:ok, %{seasons: 1, episodes: 2}} = Tmdb.fetch("95396", :tv)

      assert [title] = Ash.read!(CachedTitle)
      assert title.source == :tmdb
      assert title.title == "Severance"
      assert title.kind == :tv
      assert title.episode_count == 19
      assert title.genres == "Drama, Mystery"
      assert title.tmdb_id == "95396"

      assert [season] = Ash.read!(CachedSeason)
      assert season.season_number == 1
      assert season.episode_count == 2

      episodes = CachedEpisode |> Ash.read!() |> Enum.sort_by(& &1.episode_number)
      assert length(episodes) == 2
      assert Enum.map(episodes, & &1.title) == ["Good News About Hell", "Half Loop"]
      assert hd(episodes).runtime_minutes == 59
    end

    test "an air date is a day and never an exact instant" do
      stub(&season_stub/1)

      {:ok, _written} = Tmdb.fetch("95396", :tv)

      assert [episode] = Ash.read!(CachedEpisode)

      # TMDB gives a date and no time. Recording `:exact` of a midnight this
      # provider invented is the small lie the cache exists to avoid.
      assert episode.date_confidence == :day
      assert DateTime.to_date(episode.air_at) == ~D[2022-02-17]
    end

    test "fetching twice updates rather than duplicating" do
      stub(&season_stub/1)

      {:ok, _first} = Tmdb.fetch("95396", :tv)
      {:ok, _second} = Tmdb.fetch("95396", :tv)

      assert Ash.count!(CachedTitle) == 1
      assert Ash.count!(CachedSeason) == 1
      assert Ash.count!(CachedEpisode) == 1
    end

    test "a season that fails leaves the rest cached rather than nothing" do
      stub(fn req ->
        case req.url.path do
          "/3/tv/95396" ->
            json(req, 200, %{
              "id" => 95_396,
              "name" => "Severance",
              "seasons" => [
                %{"id" => 1, "season_number" => 1, "episode_count" => 1},
                %{"id" => 2, "season_number" => 2, "episode_count" => 1}
              ]
            })

          "/3/tv/95396/season/1" ->
            json(req, 200, %{"episodes" => [episode(1, 1, 11)]})

          "/3/tv/95396/season/2" ->
            json(req, 500, %{})
        end
      end)

      assert {:ok, %{seasons: 1, episodes: 1}} = Tmdb.fetch("95396", :tv)

      # The title and the season that answered are cached. Eight seasons cached
      # and one missing beats nothing cached, and the next `:stale` pass
      # re-fetches the gap.
      assert Ash.count!(CachedTitle) == 1
      assert Ash.count!(CachedEpisode) == 1
    end

    test "an episode TMDB gives no id for is not written under a made-up one" do
      stub(fn req ->
        case req.url.path do
          "/3/tv/95396" ->
            json(req, 200, %{
              "id" => 95_396,
              "name" => "Severance",
              "seasons" => [%{"id" => 1, "season_number" => 1}]
            })

          "/3/tv/95396/season/1" ->
            json(req, 200, %{"episodes" => [%{"season_number" => 1, "episode_number" => 1}]})
        end
      end)

      assert {:ok, %{episodes: 0}} = Tmdb.fetch("95396", :tv)
      assert Ash.count!(CachedEpisode) == 0
    end
  end

  describe "failures are visible, and named" do
    for {status, reason} <- [{401, :unauthorised}, {429, :rate_limited}, {404, :not_found}] do
      test "#{status} is #{reason}" do
        stub(fn req -> json(req, unquote(status), %{}) end)

        assert {:error, unquote(reason)} = Tmdb.search("anything")
      end
    end

    test "an unworded status still says nothing was saved" do
      stub(fn req -> json(req, 500, %{}) end)

      assert {:error, {:http, 500}} = Tmdb.search("anything")
      assert Tmdb.message({:http, 500}) =~ "Nothing was saved"
    end

    test "no key is not a failed request, and says where to fix it" do
      System.delete_env("TMDB_READ_TOKEN")
      System.delete_env("TMDB_TOKEN")
      on_exit(fn -> System.put_env("TMDB_READ_TOKEN", "test-token") end)

      assert {:error, :no_api_key} = Tmdb.search("anything")
      assert Tmdb.message(:no_api_key) =~ "Data sources"
    end

    test "every reason a caller can be handed has a sentence" do
      # No `_` clause in `message/1` on purpose: a reason nobody has worded yet
      # should be a compile-time gap, not a plausible sentence about a
      # different problem.
      for reason <- [
            :no_api_key,
            :unauthorised,
            :rate_limited,
            :not_found,
            {:http, 503},
            {:network, :timeout}
          ] do
        assert is_binary(Tmdb.message(reason))
        assert Tmdb.message({:error, reason}) == Tmdb.message(reason)
      end
    end

    test "the network being gone is a reason, not a raise" do
      stub(fn _req -> raise "no route to host" end)

      assert {:error, {:network, _reason}} = Tmdb.search("anything")
      assert Tmdb.message({:network, :enetunreach}) =~ "Hand-typed titles still work"
    end
  end

  describe "against the real TMDB" do
    @describetag :live

    test "one search and one detail fill the cache", %{real_token: real} do
      Application.delete_env(:kati, :tmdb_req_options)
      if real, do: System.put_env("TMDB_READ_TOKEN", real)

      assert {:ok, results} = Tmdb.search("Severance")
      assert series = Enum.find(results, &(&1.kind == :tv and &1.title == "Severance"))

      assert {:ok, written} = Tmdb.fetch(series.source_id, :tv)
      assert written.episodes > 0

      assert Ash.count!(CachedTitle) == 1
      assert Ash.count!(CachedEpisode) == written.episodes
    end
  end

  defp season_stub(req) do
    case req.url.path do
      "/3/tv/95396" ->
        json(req, 200, %{
          "id" => 95_396,
          "name" => "Severance",
          "seasons" => [%{"id" => 1, "season_number" => 1}]
        })

      "/3/tv/95396/season/1" ->
        json(req, 200, %{"episodes" => [episode(1, 1, 2_337_670)]})
    end
  end

  defp episode(season, number, id) do
    %{
      "id" => id,
      "season_number" => season,
      "episode_number" => number,
      "name" => "Good News About Hell",
      "air_date" => "2022-02-17"
    }
  end
end
