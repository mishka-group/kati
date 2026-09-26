defmodule Kati.GroupCRealTest do
  @moduledoc """
  Screens 03, 05, 06, 10, 19 and 92 against the store, for the claims N52-C
  makes about them: what a title's status is from the moment it is added,
  that one Persian or CJK character searches on 06 as it does on 19, and that
  no empty state draws a control that does nothing or a sentence that is not
  true of the reader.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.AddTitle
  alias Kati.Screens.Inbox
  alias Kati.Screens.Library
  alias Kati.Screens.MyServices
  alias Kati.Screens.Rating
  alias Kati.Screens.Search, as: SearchScreen
  alias Kati.Screens.UpNext

  @tables ~w(media_watches media_content_warnings cached_episodes cached_seasons tracked_titles cached_titles)

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :tmdb_test_stub).(request)
  end

  setup do
    Kati.Locale.put(:en)
    wipe!()
    token = System.get_env("TMDB_READ_TOKEN")

    on_exit(fn ->
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :tmdb_test_stub)

      if token,
        do: System.put_env("TMDB_READ_TOKEN", token),
        else: System.delete_env("TMDB_READ_TOKEN")

      wipe!()
    end)

    :ok
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end

  defp tracked(title) do
    Enum.find(Ash.read!(TrackedTitle), &(&1.source == :manual and &1.source_id == title))
  end

  defp shelf_row(title),
    do: Enum.find(Library.shelf(Kati.Library.ShelfFilters.resting()), &(&1.title == title))

  defp texts(view_or_tree) do
    view_or_tree
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _ -> []
      end
    end)
  end

  defp tags(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{on_tap: {pid, tag}} when is_pid(pid) and is_atom(tag) -> [tag]
        _ -> []
      end
    end)
  end

  describe "a title added from screen 06 is not started" do
    test "a film added from a result row is not started, and not watching" do
      row = %{title: "Groupc Film", kind: :movie, meta: "", note: nil, added: false}

      view =
        mount_screen(AddTitle, %{})
        |> render_info({:results_for_test, [row]})
        |> render_info({:tap, :add_0})

      assert [%{added: true}] = assigns(view).results
      assert %TrackedTitle{status: :not_started, kind: :movie} = tracked("Groupc Film")

      shelf = shelf_row("Groupc Film")
      assert shelf.status == :not_started
      assert Library.tile_meta(shelf) == "not started"

      counts = Map.new(Library.chip_counts([shelf]), fn {key, _label, n} -> {key, n} end)
      assert counts[:not_started] == 1
      assert counts[:watching] == 0
      assert Library.queued() == 0
    end

    test "a series added is not started until an episode is ticked" do
      {:ok, _cached} = AddTitle.create_cache("Groupc Series", :tv, %{episode_count: 3})
      assert {:ok, series} = AddTitle.track("Groupc Series", %{kind: :tv})
      assert series.status == :not_started

      Ash.create!(Watch, %{
        tracked_title_id: series.id,
        episode_source_id: "groupc:s1e1",
        watched_at: DateTime.truncate(Kati.Time.now(), :second),
        watched_on: Kati.Time.today()
      })

      Kati.Screens.Series.restate(series.id)
      assert Ash.get!(TrackedTitle, series.id).status == :watching
      assert shelf_row("Groupc Series").status == :watching
    end

    test "logging a watch of a film finishes it" do
      {:ok, _cached} = AddTitle.create_cache("Groupc Logged", :movie, %{runtime_minutes: 100})
      assert {:ok, film} = AddTitle.track("Groupc Logged", %{kind: :movie})

      assert {:ok, _watch} =
               Rating.save_watch(%{
                 watch_id: nil,
                 tracked_title_id: film.id,
                 watch: %{rating: nil, review: nil}
               })

      assert Ash.get!(TrackedTitle, film.id).status == :finished

      row = shelf_row("Groupc Logged")
      assert row.status == :finished
      assert row.progress == 1.0
    end

    test "logging a watch of an anime film finishes it, and fills its rail" do
      Ash.create!(CachedTitle, %{
        source: :manual,
        source_id: "Groupc Anime Film",
        kind: :movie,
        title: "Groupc Anime Film",
        runtime_minutes: 117,
        fetched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      anime =
        Ash.create!(TrackedTitle, %{
          source: :manual,
          source_id: "Groupc Anime Film",
          kind: :anime,
          status: :not_started
        })

      assert {:ok, _watch} =
               Rating.save_watch(%{
                 watch_id: nil,
                 tracked_title_id: anime.id,
                 watch: %{rating: nil, review: nil}
               })

      assert Ash.get!(TrackedTitle, anime.id).status == :finished
      assert shelf_row("Groupc Anime Film").progress == 1.0
    end

    test "logging a watch of a series does not finish it" do
      {:ok, _cached} = AddTitle.create_cache("Groupc Show", :tv, %{episode_count: 8})
      assert {:ok, show} = AddTitle.track("Groupc Show", %{kind: :tv})

      Rating.finish_title({:ok, :watch}, show.id)

      assert Ash.get!(TrackedTitle, show.id).status == :not_started
    end
  end

  describe "V16 — one Persian, Arabic or CJK character searches on 06 and 19" do
    defp with_tmdb(fun) do
      choice = Kati.Sources.tmdb_key()
      Kati.Sources.put_tmdb_key(:kati)
      System.put_env("TMDB_READ_TOKEN", "test-token")
      Application.put_env(:kati, :tmdb_req_options, adapter: Adapter)

      try do
        fun.()
      after
        Kati.Sources.put_tmdb_key(choice)
      end
    end

    defp stub_tmdb(title) do
      Application.put_env(:kati, :tmdb_test_stub, fn req ->
        body = %{
          "results" => [
            %{
              "media_type" => "movie",
              "id" => 4242,
              "title" => title,
              "release_date" => "2001-07-20"
            }
          ]
        }

        {req, Req.Response.new(status: 200, body: body)}
      end)
    end

    test "screen 06: one Persian letter waits for TMDB and then shows what it found" do
      with_tmdb(fn -> persian_letter_searches() end)
    end

    defp persian_letter_searches do
      stub_tmdb("شهر")

      typed = mount_screen(AddTitle, %{}) |> render_info({:change, :title_query, "ش"})
      assert assigns(typed).searching?, "one Persian letter was held under the floor"

      found = render_info(typed, {:search_ready, "ش"})
      assert Enum.map(assigns(found).results, & &1.title) == ["شهر"]
      refute assigns(found).searching?
    end

    test "screen 06: one CJK character searches, one Latin letter does not" do
      with_tmdb(fn -> cjk_searches_latin_does_not() end)
    end

    defp cjk_searches_latin_does_not do
      stub_tmdb("千と千尋の神隠し")

      found =
        mount_screen(AddTitle, %{})
        |> render_info({:change, :title_query, "千"})
        |> render_info({:search_ready, "千"})

      assert Enum.map(assigns(found).results, & &1.title) == ["千と千尋の神隠し"]

      Application.put_env(:kati, :tmdb_test_stub, fn _req ->
        flunk("one Latin letter reached TMDB")
      end)

      latin =
        mount_screen(AddTitle, %{})
        |> render_info({:change, :title_query, "a"})
        |> render_info({:search_ready, "a"})

      refute assigns(latin).searching?
      assert assigns(latin).results == []
    end

    test "the minimum is the query's, whatever the app's locale" do
      Kati.Locale.put(:en)

      for one <- ["ش", "ك", "ﻙ", "千", "の"] do
        assert Kati.Search.minimum(one) == 1, "#{inspect(one)} asked for two characters"
        assert Kati.Search.long_enough?(one)
      end

      assert Kati.Search.minimum("a") == 2
      refute Kati.Search.long_enough?(" a ")
    end

    test "screen 06 handed one letter opens searching only when that letter is enough" do
      assert assigns(mount_screen(AddTitle, %{query: "ك"})).searching?
      refute assigns(mount_screen(AddTitle, %{query: "a"})).searching?
    end

    test "screen 19: one CJK character runs the query" do
      Ash.create!(CachedTitle, %{
        source: :manual,
        source_id: "千年女優",
        kind: :movie,
        title: "千年女優",
        fetched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      Ash.create!(TrackedTitle, %{
        source: :manual,
        source_id: "千年女優",
        kind: :movie,
        status: :not_started
      })

      view = mount_screen(SearchScreen, %{query: ""}) |> render_info({:change, :query, "千"})

      refute assigns(view).results.idle?
      assert Enum.map(assigns(view).results.titles, & &1.title) == ["千年女優"]
    end
  end

  describe "empty states say only what is true, and draw no dead control" do
    test "an empty Up next draws its card, and not a paused-shelf card under it" do
      view = mount_screen(UpNext, %{})
      drawn = texts(view)

      assert "Nothing queued" in drawn
      refute "Nothing ready to watch" in drawn
      refute Enum.any?(drawn, &String.contains?(&1, "paused"))
    end

    test "a ready row with no bookmark and no runtime says what it is" do
      for title <- ["Groupc Hero", "Groupc Second"] do
        {:ok, _cached} = AddTitle.create_cache(title, :tv)
        {:ok, row} = AddTitle.track(title, %{kind: :tv})
        Ash.update!(row, %{status: :watching})
      end

      ready = UpNext.queue().ready
      assert [%{meta: meta}] = ready
      assert meta != ""
    end

    test "an inbox with nothing to mark draws no Mark all" do
      view = mount_screen(Inbox, %{})

      refute "Mark all" in texts(view)
      refute :mark_all in tags(view)
    end

    test "My services names pages by title, and its field carries no dead tap" do
      view = mount_screen(MyServices, %{})
      drawn = Enum.join(texts(view), "\n")

      refute drawn =~ "on 83"
      refute drawn =~ "23 reads"
      refute :search in tags(view)
    end
  end

  describe "no screen of this group reads a shared fixture module" do
    test "Library, Inbox and My services hold no board fixture of their own" do
      refute function_exported?(Library, :drawn_titles, 0)
      refute function_exported?(Inbox, :drawn_inbox, 0)
      refute function_exported?(Inbox, :coming_up_rows, 0)
      refute function_exported?(MyServices, :drawn_page, 0)

      for file <- ~w(library up_next add_title search inbox my_services) do
        source = File.read!("lib/kati/screens/#{file}.ex")
        refute source =~ "Kati.Library.Sample", "#{file}.ex names Kati.Library.Sample"
        refute source =~ "Lists.Sample", "#{file}.ex names Lists.Sample"
      end
    end
  end
end
