defmodule Kati.ImportMatchTest do
  @moduledoc """
  N44: an imported title is looked up on TMDB after the import is written.

  Found walking a real MyAnimeList import on the emulator: Frieren, Cowboy
  Bebop and Spirited Away all landed as `:import` rows — a name and a rating,
  no poster, no runtime, no genres and no episodes — and stayed that way.

  TMDB is a stubbed Req adapter here, the seam `Kati.MediaTmdbTest` uses. The
  file is the fixture a real MyAnimeList export is shaped like.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Import.Match, only: [best: 2, kinds: 1, unreachable?: 1]

  alias Kati.Import.Commit
  alias Kati.Import.Job
  alias Kati.Import.Match
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TitleAlias
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  @fixture Path.expand("../fixtures/import/animelist.xml", __DIR__)

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :import_match_stub).(request)
  end

  setup do
    Application.put_env(:kati, :tmdb_test_token, "test-token")
    Application.put_env(:kati, :tmdb_req_options, adapter: Adapter)
    Application.put_env(:kati, :import_match_stub, &tmdb/1)

    on_exit(fn ->
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :import_match_stub)
      Application.delete_env(:kati, :tmdb_test_token)
      wipe!()
    end)

    wipe!()
    poster_on_disk!("/frieren.jpg")
    :ok
  end

  describe "a MyAnimeList import, committed" do
    test "moves every title onto TMDB's row and keeps what the reader did" do
      start_supervised!({Task.Supervisor, name: Kati.TaskSupervisor})

      {:ok, job} = Job.read(@fixture, "animelist.xml")
      {:ok, tally} = Commit.run(job)
      await_matching()

      assert tally.new == 3

      by_id = Map.new(Ash.read!(TrackedTitle), &{&1.source_id, &1})

      assert %{"209867" => frieren, "30991" => bebop, "129" => spirited} = by_id
      assert Enum.all?([frieren, bebop, spirited], &(&1.source == :tmdb))

      assert Enum.all?([frieren, bebop, spirited], &(&1.kind == :anime)),
             "the export said anime and TMDB's filing does not overrule it"

      assert frieren.status == :finished
      assert bebop.status == :watching

      assert [%Watch{rating: 10, watched_on: ~D[2024-03-22]}] = watches(frieren)
      assert [%Watch{rating: 9}] = watches(spirited)

      cached = Ash.read!(CachedTitle)
      assert Enum.all?(cached, &(&1.source == :tmdb)), "the :import rows are gone"

      assert %CachedTitle{poster_path: "/frieren.jpg", episode_count: 2} =
               Enum.find(cached, &(&1.source_id == "209867"))

      assert %CachedTitle{runtime_minutes: 125} = Enum.find(cached, &(&1.source_id == "129"))
      assert length(Ash.read!(CachedEpisode)) == 2
    end

    test "remembers the export's name where TMDB spells the title differently" do
      {:ok, job} = Job.read(@fixture, "animelist.xml")

      Match.run(import_pairs(job))

      aliases = TitleAlias.all()

      assert Map.has_key?(aliases, "sousou no frieren")
      assert Map.has_key?(aliases, "sen to chihiro no kamikakushi")
      refute Map.has_key?(aliases, "cowboy bebop"), "TMDB's own name already answers"
    end

    test "and the same file read again adds nothing" do
      start_supervised!({Task.Supervisor, name: Kati.TaskSupervisor})

      {:ok, job} = Job.read(@fixture, "animelist.xml")
      {:ok, _tally} = Commit.run(job)
      await_matching()

      {:ok, again} = Job.read(@fixture, "animelist.xml")

      assert again.plan.new == []
      assert again.plan.merged == []
      assert length(again.plan.present) == 3

      {:ok, tally} = Commit.run(again)

      assert %{new: 0, merged: 0, failed: 0} = tally
      assert length(Ash.read!(TrackedTitle)) == 3
      assert length(Ash.read!(Watch)) == 2
      assert Kati.Screens.Import.result_line(tally) == "Nothing to import."
    end
  end

  describe "the boot backfill" do
    test "matches the titles an earlier import left on :import rows" do
      {:ok, job} = Job.read(@fixture, "animelist.xml")
      pairs = import_pairs(job)

      assert Enum.all?(pairs, fn {tracked, _record} -> tracked.source == :import end)

      assert Match.backfill() == [:matched, :matched, :matched]

      assert Ash.read!(TrackedTitle) |> Enum.map(& &1.source_id) |> Enum.sort() ==
               ["129", "209867", "30991"]

      assert Match.backfill() == []
    end
  end

  describe "leaves the row as the import wrote it" do
    test "when there is no key" do
      Application.delete_env(:kati, :tmdb_test_token)

      Application.put_env(:kati, :import_match_stub, fn _req ->
        flunk("asked TMDB with no key")
      end)

      {:ok, job} = Job.read(@fixture, "animelist.xml")

      assert [{:error, :no_api_key}, :skipped, :skipped] = Match.run(import_pairs(job))
      assert Enum.all?(Ash.read!(TrackedTitle), &(&1.source == :import))
    end

    test "when TMDB has nothing of the right kind" do
      Application.put_env(:kati, :import_match_stub, fn req ->
        {req, Req.Response.new(status: 200, body: %{"results" => [person()]})}
      end)

      {:ok, job} = Job.read(@fixture, "animelist.xml")

      assert Enum.uniq(Match.run(import_pairs(job))) == [:no_match]
      assert Enum.all?(Ash.read!(TrackedTitle), &(&1.source == :import))
      assert Enum.all?(Ash.read!(CachedTitle), &(&1.source == :import))
    end

    test "when the reader already tracks that TMDB title under another name" do
      Ash.create!(TrackedTitle, %{source: :tmdb, source_id: "30991", kind: :tv, status: :paused})

      {:ok, job} = Job.read(@fixture, "animelist.xml")

      outcomes = job |> import_pairs() |> Match.run()

      assert :taken in outcomes

      bebop = Enum.find(Ash.read!(TrackedTitle), &(&1.source_id == "Cowboy Bebop"))
      assert bebop.source == :import
    end

    test "for a row that is not an import's" do
      tracked =
        Ash.create!(TrackedTitle, %{source: :manual, source_id: "Dune", kind: :movie})

      assert Match.attach(tracked, %{title: "Dune"}) == :not_imported
    end
  end

  test "a year, when the record has one, picks between two films of one name" do
    hits = [
      %{title: "Solaris", kind: :movie, year: "1972", source_id: "593"},
      %{title: "Solaris", kind: :movie, year: "2002", source_id: "2103"}
    ]

    assert Match.best(hits, %{title: "Solaris", kind: :movie, year: 2002}).source_id == "2103"
    assert Match.best(hits, %{title: "Solaris", kind: :movie}).source_id == "593"
  end

  defp tmdb(req) do
    case req.url.path do
      "/3/search/multi" -> search(req, URI.decode_query(req.url.query || "")["query"])
      "/3/tv/209867" -> ok(req, frieren())
      "/3/tv/209867/season/1" -> ok(req, %{"episodes" => [episode(1, 11), episode(2, 12)]})
      "/3/tv/30991" -> ok(req, %{"id" => 30_991, "name" => "Cowboy Bebop", "seasons" => []})
      "/3/movie/129" -> ok(req, spirited_away())
    end
  end

  defp search(req, "Sousou no Frieren") do
    ok(req, %{
      "results" => [
        person(),
        %{
          "media_type" => "tv",
          "id" => 209_867,
          "name" => "Frieren: Beyond Journey's End",
          "first_air_date" => "2023-09-29"
        }
      ]
    })
  end

  defp search(req, "Cowboy Bebop") do
    ok(req, %{
      "results" => [
        %{
          "media_type" => "movie",
          "id" => 11_299,
          "title" => "Cowboy Bebop: The Movie",
          "release_date" => "2001-09-01"
        },
        %{
          "media_type" => "tv",
          "id" => 30_991,
          "name" => "Cowboy Bebop",
          "first_air_date" => "1998-04-03"
        }
      ]
    })
  end

  defp search(req, "Sen to Chihiro no Kamikakushi") do
    ok(req, %{
      "results" => [
        %{
          "media_type" => "tv",
          "id" => 1,
          "name" => "Spirited",
          "first_air_date" => "2010-01-01"
        },
        %{
          "media_type" => "movie",
          "id" => 129,
          "title" => "Spirited Away",
          "release_date" => "2001-07-20"
        }
      ]
    })
  end

  defp frieren do
    %{
      "id" => 209_867,
      "name" => "Frieren: Beyond Journey's End",
      "original_name" => "葬送のフリーレン",
      "poster_path" => "/frieren.jpg",
      "number_of_episodes" => 2,
      "genres" => [%{"name" => "Animation"}],
      "original_language" => "ja",
      "first_air_date" => "2023-09-29",
      "seasons" => [%{"id" => 1, "season_number" => 1, "air_date" => "2023-09-29"}]
    }
  end

  defp spirited_away do
    %{
      "id" => 129,
      "title" => "Spirited Away",
      "original_title" => "千と千尋の神隠し",
      "runtime" => 125,
      "release_date" => "2001-07-20",
      "genres" => [%{"name" => "Animation"}, %{"name" => "Family"}],
      "original_language" => "ja"
    }
  end

  defp episode(number, id) do
    %{
      "id" => id,
      "season_number" => 1,
      "episode_number" => number,
      "name" => "Episode #{number}",
      "air_date" => "2023-09-29"
    }
  end

  defp person, do: %{"media_type" => "person", "id" => 5, "name" => "Somebody"}

  defp ok(req, body), do: {req, Req.Response.new(status: 200, body: body)}

  # The rows `Commit.run/2` writes, written without it: `run/2` also starts the
  # matcher, and a test that drives `Match.run/1` itself must not race a second
  # copy of the same work.
  defp import_pairs(job) do
    for record <- job.plan.new do
      {:ok, tracked} = Commit.create(record)
      {tracked, record}
    end
  end

  defp watches(tracked) do
    Enum.filter(Ash.read!(Watch), &(&1.tracked_title_id == tracked.id))
  end

  defp await_matching do
    for pid <- Task.Supervisor.children(Kati.TaskSupervisor) do
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 5_000
    end
  end

  # `Kati.Media.Artwork.cache/1` fetches from TMDB's image CDN, which the Req
  # stub does not cover; a file already on disk is the answer it takes without
  # asking, so the match reaches the poster step and no test reaches the net.
  defp poster_on_disk!(path) do
    dir = Path.join(Mob.data_dir(), "artwork")
    File.mkdir_p!(dir)
    name = String.trim_leading(path, "/")

    for width <- ~w(w342 w780), do: File.write!(Path.join(dir, width <> "_" <> name), "jpg")

    assert Kati.Media.Artwork.local(path, :poster)
  end

  defp wipe! do
    for table <-
          ~w(media_title_aliases media_watches tracked_titles cached_episodes cached_seasons cached_titles) do
      Kati.Repo.query!("DELETE FROM " <> table)
    end
  end
end
