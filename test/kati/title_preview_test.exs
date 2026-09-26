defmodule Kati.TitlePreviewTest do
  @moduledoc """
  N55: a TMDB title the reader does not keep opens as a preview of its own
  page — screen 08 for a film, 04 for a series — with *Add to library* on it.

    * Screen 19's TMDB row body and screen 06's result row push the preview;
      the add discs are unchanged.
    * The preview draws from the cache, filled by `Kati.Media.Tmdb.fetch/2` in
      a task: title, year, runtime, genres, overview, and no rating card, no
      ticks, no ⋯.
    * *Add to library* tracks the title as `:not_started` through screen 06's
      own write and the page turns tracked in place; the search row it came
      from reads as added on the way back.
    * A title already tracked opens the ordinary page; a failed fetch says
      `Kati.Media.Tmdb.message/1`'s sentence under a working back pill.

  TMDB is a stub handed to Req through `:tmdb_req_options`. The fetch runs in
  a task that answers the test process — the screen's process here — so each
  test receives `{:title_preview, …}` and hands it to `handle_info/2` as the
  device would.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Screens.TitlePreview

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Film
  alias Kati.Screens.Series
  alias Kati.Screens.TitlePreview

  @tables ~w(media_events media_watches tracked_titles cached_episodes cached_seasons cached_titles)

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :tmdb_test_stub).(request)
  end

  setup do
    Kati.Locale.put(:en)
    Kati.Search.Recent.forget!()
    wipe!()

    on_exit(fn ->
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :tmdb_test_stub)
      Application.delete_env(:kati, :tmdb_test_token)
      wipe!()
    end)

    :ok
  end

  describe "the doors" do
    test "a TMDB row on screen 19 pushes its preview, and its disc still adds" do
      stub_tmdb!()

      view = mount_screen(Kati.Screens.Search, %{query: ""})
      view = render_info(view, {:change, :query, "arrival"})
      view = render_info(view, {:search_ready, "arrival"})
      assert_receive {:tmdb_answer, epoch, "arrival", result}, 5_000
      view = render_info(view, {:tmdb_answer, epoch, "arrival", result})

      assert :tmdb_open_0 in tap_tags(view)
      assert :add_0 in tap_tags(view)

      opened = render_info(view, {:tap, :tmdb_open_0})
      assert navigated_to(opened) == Film

      assert {:push, Film,
              %{
                preview: %{source: :tmdb, source_id: "n55-film", kind: :movie, title: "Arrival"},
                back: "Search"
              }} = opened.socket.__mob__.nav_action

      assert Ash.read!(TrackedTitle) == [], "opening a preview put the title on the shelf"
    end

    test "a series row on screen 06 pushes screen 04's preview" do
      view =
        Kati.Screens.AddTitle
        |> mount_screen(%{})
        |> render_info({:results_for_test, [tmdb_row("n55-show", "Low Tide", :tv)]})

      assert :preview_0 in tap_tags(view)
      assert :add_0 in tap_tags(view)

      opened = render_info(view, {:tap, :preview_0})
      assert navigated_to(opened) == Series

      assert {:push, Series, %{preview: %{source_id: "n55-show", kind: :tv}, back: "Add title"}} =
               opened.socket.__mob__.nav_action
    end
  end

  describe "a film nobody keeps" do
    test "loads off the mount, then draws the provider's half and an Add pill" do
      stub_tmdb!()

      view = mount_screen(Film, TitlePreview.params(film_row(), "Search"))

      assert assigns(view).preview.status == :loading
      assert "Loading from TMDB…" in texts(view)
      assert :back in tap_tags(view)

      view = answer(view)
      drawn = texts(view)

      assert "Arrival" in drawn
      assert "2016 · 1H 56M · DRAMA, SCIENCE FICTION" in drawn
      assert "A linguist is recruited to talk to visitors." in drawn
      assert Kati.UI.eyebrow_label("Overview") in drawn
      assert "Add to library" in drawn
      assert :add_to_library in tap_tags(view)

      refute Kati.UI.eyebrow_label("Your rating") in drawn, "a preview drew a rating card"
      refute :rate in tap_tags(view)
      refute :toggle_menu in tap_tags(view), "a preview drew the ⋯"
      refute :add_to_list in tap_tags(view)

      assert Ash.read!(TrackedTitle) == []
      assert [%CachedTitle{source_id: "n55-film"}] = Ash.read!(CachedTitle)
    end

    test "Add to library tracks it as not started and the page turns tracked in place" do
      stub_tmdb!()

      view = Film |> mount_screen(TitlePreview.params(film_row(), "Search")) |> answer()
      added = render_info(view, {:tap, :add_to_library})

      assert [tracked] = Ash.read!(TrackedTitle)
      assert tracked.source == :tmdb and tracked.source_id == "n55-film"
      assert tracked.status == :not_started

      assert assigns(added).preview == nil
      assert assigns(added).id == tracked.id
      assert assigns(added).film.tracked_id == tracked.id
      assert navigated_to(added) == nil, "adding navigated away"

      assert Kati.UI.eyebrow_label("Your rating") in texts(added)
      assert :toggle_menu in tap_tags(added)
      refute :add_to_library in tap_tags(added)

      assert "A linguist is recruited to talk to visitors." in texts(added),
             "the overview vanished once the film was added"

      assert Kati.UI.eyebrow_label("Overview") in texts(added)
    end

    test "a tracked film whose cache has no overview draws no Overview heading" do
      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: "n55-bare",
        kind: :movie,
        title: "Bare",
        fetched_at: Kati.Time.now()
      })

      tracked =
        Ash.create!(TrackedTitle, %{
          source: :tmdb,
          source_id: "n55-bare",
          kind: :movie,
          status: :watching
        })

      view = mount_screen(Film, %{id: tracked.id})

      assert "Bare" in texts(view)
      refute Kati.UI.eyebrow_label("Overview") in texts(view)
    end

    test "the search row reads as added when the reader comes back" do
      stub_tmdb!()

      search = mount_screen(Kati.Screens.Search, %{query: "arrival"})
      search = render_info(search, {:search_ready, "arrival"})
      assert_receive {:tmdb_answer, epoch, "arrival", result}, 5_000
      search = render_info(search, {:tmdb_answer, epoch, "arrival", result})
      assert [%{added: false}] = assigns(search).tmdb.rows

      Film
      |> mount_screen(TitlePreview.params(film_row(), "Search"))
      |> answer()
      |> render_info({:tap, :add_to_library})

      back = render_info(search, {:kati, :resumed, nil})
      assert [%{added: true, id: id}] = assigns(back).tmdb.rows
      assert is_binary(id)
    end

    test "a title already tracked opens the ordinary page" do
      stub_tmdb!()

      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: "n55-film",
        kind: :movie,
        title: "Arrival",
        fetched_at: Kati.Time.now()
      })

      tracked =
        Ash.create!(TrackedTitle, %{
          source: :tmdb,
          source_id: "n55-film",
          kind: :movie,
          status: :watching
        })

      view = mount_screen(Film, TitlePreview.params(film_row(), "Search"))

      assert assigns(view).preview == nil
      assert assigns(view).id == tracked.id
      assert :toggle_menu in tap_tags(view)
      refute :add_to_library in tap_tags(view)
      refute_receive {:title_preview, _id, _result}, 200
    end

    test "a failed fetch is TMDB's own sentence, and back still works" do
      Application.put_env(:kati, :tmdb_test_token, "test-token")
      stub(fn req -> {req, Req.Response.new(status: 404, body: %{})} end)

      view = Film |> mount_screen(TitlePreview.params(film_row(), "Search")) |> answer()

      assert assigns(view).preview.status == :error
      assert Kati.Media.Tmdb.message(:not_found) in texts(view)
      refute :add_to_library in tap_tags(view)

      popped = render_info(view, {:tap, :back})
      assert {:pop} = popped.socket.__mob__.nav_action
    end

    test "with no token there is nothing to fetch, and the page says so" do
      Application.delete_env(:kati, :tmdb_test_token)
      refute Kati.Media.Tmdb.usable?(), "this host has a reader's own TMDB token stored"

      view = mount_screen(Film, TitlePreview.params(film_row(), "Search"))

      assert assigns(view).preview.reason == :no_api_key
      assert Kati.Media.Tmdb.message(:no_api_key) in texts(view)
      refute_receive {:title_preview, _id, _result}, 200
    end
  end

  describe "a series nobody keeps" do
    test "draws its seasons and episodes read-only, and Add makes them tickable" do
      stub_tmdb!()

      view =
        Series
        |> mount_screen(TitlePreview.params(tmdb_row("n55-show", "Low Tide", :tv), "Search"))
        |> answer()

      drawn = texts(view)

      assert "Low Tide" in drawn
      assert "2020 · DRAMA · 2 SEASONS · 3 EPISODES" in drawn
      assert "A harbour town keeps a secret." in drawn
      assert "The Pier" in drawn
      assert "The Lighthouse" in drawn
      assert :season_S2 in tap_tags(view)
      assert :add_to_library in tap_tags(view)

      refute :episode_0 in tap_tags(view), "a preview drew a tickable episode"
      refute :rate_0 in tap_tags(view)
      refute :mark_next in tap_tags(view)
      refute :toggle_menu in tap_tags(view)

      second = render_info(view, {:tap, :season_S2})
      assert "The Storm" in texts(second)
      refute :episode_0 in tap_tags(second)

      added = render_info(second, {:tap, :add_to_library})

      assert [%TrackedTitle{source_id: "n55-show", status: :not_started}] =
               Ash.read!(TrackedTitle)

      assert assigns(added).preview == nil
      assert :episode_0 in tap_tags(added)
      assert :mark_next in tap_tags(added)

      assert "A harbour town keeps a secret." in texts(added),
             "the overview vanished once the series was added"

      assert Kati.UI.eyebrow_label("Overview") in texts(added)
    end
  end

  defp answer(view) do
    assert_receive {:title_preview, source_id, result}, 5_000
    render_info(view, {:title_preview, source_id, result})
  end

  defp film_row, do: tmdb_row("n55-film", "Arrival", :movie)

  defp tmdb_row(source_id, title, kind) do
    %{
      title: title,
      seed: nil,
      meta: "",
      note: nil,
      added: false,
      source: :tmdb,
      source_id: source_id,
      kind: kind
    }
  end

  defp stub_tmdb! do
    Application.put_env(:kati, :tmdb_test_token, "test-token")

    stub(fn req ->
      body =
        case req.url.path do
          "/3/search/multi" ->
            %{
              "results" => [
                %{
                  "media_type" => "movie",
                  "id" => "n55-film",
                  "title" => "Arrival",
                  "release_date" => "2016-11-11"
                }
              ]
            }

          "/3/movie/n55-film" ->
            %{
              "id" => "n55-film",
              "title" => "Arrival",
              "overview" => "A linguist is recruited to talk to visitors.",
              "release_date" => "2016-11-11",
              "runtime" => 116,
              "poster_path" => nil,
              "genres" => [%{"name" => "Drama"}, %{"name" => "Science Fiction"}],
              "original_language" => "en"
            }

          "/3/tv/n55-show" ->
            %{
              "id" => "n55-show",
              "name" => "Low Tide",
              "overview" => "A harbour town keeps a secret.",
              "first_air_date" => "2020-01-01",
              "number_of_episodes" => 3,
              "genres" => [%{"name" => "Drama"}],
              "seasons" => [
                %{"season_number" => 1, "id" => 901, "name" => "Season 1", "episode_count" => 2},
                %{"season_number" => 2, "id" => 902, "name" => "Season 2", "episode_count" => 1}
              ]
            }

          "/3/tv/n55-show/season/1" ->
            %{
              "episodes" => [
                episode(9011, 1, 1, "The Pier", "2020-01-01"),
                episode(9012, 1, 2, "The Lighthouse", "2020-01-08")
              ]
            }

          "/3/tv/n55-show/season/2" ->
            %{"episodes" => [episode(9021, 2, 1, "The Storm", "2021-01-01")]}
        end

      {req, Req.Response.new(status: 200, body: body)}
    end)
  end

  defp episode(id, season, number, name, air_date) do
    %{
      "id" => id,
      "season_number" => season,
      "episode_number" => number,
      "name" => name,
      "air_date" => air_date,
      "runtime" => 48
    }
  end

  defp stub(fun) do
    Application.put_env(:kati, :tmdb_test_stub, fun)
    Application.put_env(:kati, :tmdb_req_options, adapter: &Adapter.run/1)
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end

  defp tap_tags(view) do
    for node <- flatten(view),
        {_pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  defp texts(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end
end
