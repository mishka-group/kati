defmodule Kati.SearchTmdbSectionTest do
  @moduledoc """
  Screen 19 after the owner's search round (N54).

    * The library answers first, and *On TMDB* answers under it for the same
      query — fetched on its own, off the screen's process, skeleton rows while
      it is out, and an answer to a query typed past dropped.
    * A TMDB title the library already listed is not listed twice; the add
      disc adds a title from the row, and a kept row opens its page.
    * No token is the door to Data sources; a failed request is
      `Kati.Media.Tmdb.message/1`'s sentence; nothing found anywhere offers the
      title by hand, and there is no push to screen 06 any more.
    * Recent holds committed queries only, never a prefix of another, draws no
      section while empty, and its *Clear* clears it.
    * Every search door in the app opens this screen.

  TMDB is a stub handed to Req through `:tmdb_req_options`, the seam
  `Kati.OnboardingFirstTitleTest` uses. The request runs in a spawned task that
  answers the test process, which is the screen's process here, so each test
  receives the answer and hands it to `handle_info/2` as the device would.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Search.OnTmdb

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Search
  alias Kati.Search.Recent

  @tables ~w(media_events media_watches tracked_titles cached_titles)

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :tmdb_test_stub).(request)
  end

  setup do
    Kati.Locale.put(:en)
    Recent.forget!()
    wipe!()

    on_exit(fn ->
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :tmdb_test_stub)
      Application.delete_env(:kati, :tmdb_test_token)
      wipe!()
    end)

    :ok
  end

  describe "the library first, TMDB under it" do
    test "a local hit is drawn above the On TMDB heading and TMDB's rows under it" do
      shelve!("n54-local", "Arrival Diaries", :movie)

      stub_tmdb!([
        result("n54-329865", "Arrival", "movie"),
        result("n54-77", "Arrival Street", "tv")
      ])

      view = search() |> typed("arrival") |> settle()
      drawn = texts(view)

      local = Enum.find_index(drawn, &(&1 == "Arrival Diaries"))
      heading = Enum.find_index(drawn, &(&1 == Kati.UI.eyebrow_label("On TMDB")))
      first_tmdb = Enum.find_index(drawn, &(&1 == "Arrival"))

      assert local && heading && first_tmdb, "a part of the page is missing: " <> inspect(drawn)
      assert local < heading and heading < first_tmdb
      assert "Arrival Street" in drawn

      assert length(assigns(view).results.titles) == 1,
             "the library's own count took TMDB's rows into it"
    end

    test "skeleton rows while the request is out, and none once it answers" do
      stub_tmdb!([result("n54-329865", "Arrival", "movie")])

      idle = search()
      refute Kati.UI.eyebrow_label("On TMDB") in texts(idle)
      assert skeletons(idle) == 0

      pending = typed(idle, "arrival")
      assert assigns(pending).tmdb.status == :pending
      assert Kati.UI.eyebrow_label("On TMDB") in texts(pending)
      assert skeletons(pending) == 3

      answered = settle(pending)
      assert skeletons(answered) == 0
      assert "Arrival" in texts(answered)
    end

    test "an answer to a query the reader typed past is dropped" do
      stub_tmdb!([result("n54-329865", "Arrival", "movie")])

      view = search() |> typed("arrival")
      stale_epoch = assigns(view).tmdb_epoch

      view = typed(view, "arrivals")

      view =
        render_info(
          view,
          {:tmdb_answer, stale_epoch, "arrival",
           {:ok,
            [
              %{
                title: "Arrival",
                kind: :movie,
                source_id: "n54-329865",
                year: nil,
                overview: nil,
                poster_path: nil
              }
            ]}}
        )

      assert assigns(view).tmdb.status == :pending
      assert assigns(view).tmdb.rows == []
      refute "Arrival" in texts(view)

      _ignored = render_info(view, {:search_ready, "arrival"})
      refute_receive {:tmdb_answer, _epoch, "arrival", _result}, 300
    end

    test "a title the library already lists is drawn once, as the library's" do
      shelve!("n54-329865", "Arrival", :movie)

      stub_tmdb!([
        result("n54-329865", "Arrival", "movie"),
        result("n54-2", "Arrival Two", "movie")
      ])

      view = search() |> typed("arrival") |> settle()
      drawn = texts(view)

      assert Enum.count(drawn, &(&1 == "Arrival")) == 1
      assert "Arrival Two" in drawn
      assert Search.hit_tag(hd(assigns(view).results.titles)) in tap_tags(view)
    end
  end

  describe "adding from a TMDB row" do
    test "the add disc tracks the title, and the row then opens its page" do
      stub_tmdb!([result("n54-329865", "Arrival", "movie")])

      view = search() |> typed("arrival") |> settle()
      assert :add_0 in tap_tags(view)
      refute :tmdb_open_0 in tap_tags(view), "a title nobody keeps opened a page"

      added = render_info(view, {:tap, :add_0})

      tracked =
        Enum.find(Ash.read!(TrackedTitle), &(&1.source == :tmdb and &1.source_id == "n54-329865"))

      assert tracked, "the add disc wrote nothing"
      assert tracked.status == :not_started
      assert [%{added: true, id: id}] = assigns(added).tmdb.rows
      assert id == tracked.id
      assert Recent.all() == ["arrival"], "adding a title did not commit the query"

      assert [%{id: ^id}] = assigns(added).results.titles
      assert Enum.count(texts(added), &(&1 == "Arrival")) == 1

      opened = render_info(added, {:tap, :tmdb_open_0})
      assert navigated_to(opened) == Kati.Screens.Film
      assert {:push, _film, %{id: ^id, back: "Search"}} = opened.socket.__mob__.nav_action
    end
  end

  describe "when TMDB cannot answer, or answers nothing" do
    test "no token is one row, and it opens Data sources" do
      Application.delete_env(:kati, :tmdb_test_token)
      refute Kati.Media.Tmdb.usable?(), "this host has a reader's own TMDB token stored"

      view = search() |> typed("arrival")

      assert assigns(view).tmdb.reason == :no_api_key
      assert skeletons(view) == 0
      assert Enum.count(texts(view), &(&1 == "Add your TMDB token")) == 1

      opened = render_info(view, {:tap, :add_tmdb_token})
      assert navigated_to(opened) == Kati.Screens.DataSources
    end

    test "offline is TMDB's own sentence" do
      Application.put_env(:kati, :tmdb_test_token, "test-token")
      stub(fn req -> {req, %Req.TransportError{reason: :nxdomain}} end)

      view = search() |> typed("arrival") |> settle()

      assert assigns(view).tmdb.status == :error
      assert Kati.Media.Tmdb.message(assigns(view).tmdb.reason) in texts(view)
    end

    test "nothing anywhere says so, and offers the title by hand" do
      stub_tmdb!([])

      view = search() |> typed("zzqwx") |> settle()
      drawn = texts(view)

      assert "Not in your library" in drawn
      assert "Nothing on TMDB for “zzqwx”" in drawn
      assert "Add “zzqwx” by hand?" in drawn
      assert :add_by_hand in tap_tags(view)
      refute :look_up in tap_tags(view), "screen 19 still pushes screen 06 for TMDB"

      pushed = render_info(view, {:tap, :add_by_hand})
      assert navigated_to(pushed) == Kati.Screens.AddByHand.for_locale()
      Kati.Screens.AddByHand.take_prefill()
    end

    test "a library hit and nothing on TMDB does not offer the by-hand form" do
      shelve!("n54-local", "Zzqwx Local", :movie)
      stub_tmdb!([])

      view = search() |> typed("zzqwx") |> settle()

      assert "Nothing on TMDB for “zzqwx”" in texts(view)
      refute :add_by_hand in tap_tags(view)
    end
  end

  describe "Recent" do
    test "an empty history draws no Recent section, idle or with a query" do
      idle = search()
      refute Kati.UI.eyebrow_label(Kati.Screens.SearchIdle.recent_eyebrow()) in texts(idle)
      refute "Nothing searched yet" in texts(idle)

      Application.delete_env(:kati, :tmdb_test_token)
      searched = typed(idle, "arrival")
      refute Kati.UI.eyebrow_label("Recent") in texts(searched)
    end

    test "keystrokes are not remembered; the search key is, and a prefix never is" do
      Application.delete_env(:kati, :tmdb_test_token)

      view = Enum.reduce(["T", "Th", "The", "TheM", "The Matrix"], search(), &typed(&2, &1))
      assert Recent.all() == []

      _committed = render_info(view, {:submit, :commit})
      assert Recent.all() == ["The Matrix"]

      Recent.remember("The Mat")
      assert Recent.all() == ["The Matrix"]
    end

    test "Clear forgets the shelf and the section goes with it" do
      Recent.remember("hollow")

      view = search()
      assert :clear_recent in tap_tags(view)

      cleared = render_info(view, {:tap, :clear_recent})

      assert Recent.all() == []
      assert assigns(cleared).history == []
      refute :clear_recent in tap_tags(cleared)
      refute Kati.UI.eyebrow_label(Kati.Screens.SearchIdle.recent_eyebrow()) in texts(cleared)
    end

    test "a recent line reopens its query in the field and commits it" do
      Application.delete_env(:kati, :tmdb_test_token)
      Recent.remember("hollow")

      view = search()
      epoch = assigns(view).query_epoch
      reopened = render_info(view, {:tap, :repeat_query_hollow})

      assert assigns(reopened).query == "hollow"
      assert assigns(reopened).query_epoch == epoch + 1
      assert Recent.all() == ["hollow"]
    end
  end

  describe "every search door" do
    test "opens screen 19" do
      for module <- [
            Kati.Screens.Home,
            Kati.Screens.HomeEmpty,
            Kati.Screens.HomeOmittedSections,
            Kati.Screens.Library,
            Kati.Screens.Calendar,
            Kati.Screens.Agenda,
            Kati.Screens.Books,
            Kati.Screens.Activity,
            Kati.Screens.Music
          ] do
        view = module |> mount_screen() |> render_info({:tap, :open_search})

        assert navigated_to(view) == Search,
               "#{inspect(module)}'s search door opened #{inspect(navigated_to(view))}"
      end
    end
  end

  defp search do
    mount_screen(Search, %{query: ""})
  end

  defp typed(view, query), do: render_info(view, {:change, :query, query})

  defp settle(view) do
    query = String.trim(assigns(view).query)
    view = render_info(view, {:search_ready, query})
    assert_receive {:tmdb_answer, epoch, ^query, result}, 5_000
    render_info(view, {:tmdb_answer, epoch, query, result})
  end

  defp stub_tmdb!(results) do
    Application.put_env(:kati, :tmdb_test_token, "test-token")

    stub(fn req ->
      body =
        case req.url.path do
          "/3/search/multi" ->
            %{"results" => results}

          "/3/movie/" <> id ->
            %{
              "id" => id,
              "title" => title_of(results, id),
              "release_date" => "2016-11-11",
              "runtime" => 116,
              "poster_path" => nil,
              "genres" => [],
              "original_language" => "en"
            }
        end

      {req, Req.Response.new(status: 200, body: body)}
    end)
  end

  defp title_of(results, id) do
    results |> Enum.find(%{}, &(&1["id"] == id)) |> Map.get("title", id)
  end

  defp stub(fun) do
    Application.put_env(:kati, :tmdb_test_stub, fun)
    Application.put_env(:kati, :tmdb_req_options, adapter: &Adapter.run/1)
  end

  defp result(id, title, "movie"),
    do: %{"media_type" => "movie", "id" => id, "title" => title, "release_date" => "2016-11-11"}

  defp result(id, title, "tv"),
    do: %{"media_type" => "tv", "id" => id, "name" => title, "first_air_date" => "2020-01-01"}

  defp shelve!(source_id, title, kind) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching
    })
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end

  defp skeletons(view) do
    Enum.count(flatten(view), fn node ->
      props = Map.get(node, :props) || %{}
      node.type == :box and props[:width] == 150 and props[:height] == 13
    end)
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
