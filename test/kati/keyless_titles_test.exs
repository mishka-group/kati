Code.require_file("../support/keyless_stubs.exs", __DIR__)

defmodule Kati.KeylessTitlesTest do
  @moduledoc """
  A title added from AniList or TVmaze is a whole title: its preview, its
  series or film page, *Mark next watched*, the anime filter — and nothing
  that only TMDB can answer is sent to TMDB for it.

  The keyless rows carry AniList's and TVmaze's own ids. TMDB keeps different
  titles under the same numbers, so a refresh, a recommendation seed or a
  detail fetch that sent one to TMDB would bring back somebody else's film.
  TMDB is a stub here that reports every path it is asked for; the keyless
  catalogues are `Kati.Test.KeylessStubs`.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Film
  alias Kati.Screens.Series
  alias Kati.Screens.TitlePreview
  alias Kati.Test.KeylessStubs

  @tables ~w(media_events media_watches tracked_titles cached_episodes cached_seasons cached_titles)

  defmodule TmdbAdapter do
    @moduledoc false
    def run(request) do
      send(Application.fetch_env!(:kati, :keyless_titles_owner), {:tmdb_asked, request.url.path})
      {request, Req.Response.new(status: 404, body: %{})}
    end
  end

  setup do
    Kati.Locale.put(:en)
    Application.delete_env(:kati, :tmdb_test_token)
    wipe!()
    KeylessStubs.install!()

    on_exit(fn ->
      KeylessStubs.restore!()
      Application.delete_env(:kati, :tmdb_test_token)
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :keyless_titles_owner)
      wipe!()
    end)

    :ok
  end

  describe "an AniList series" do
    test "previews from AniList, adds as anime, and ticks its episodes" do
      view =
        mount_screen(
          Series,
          TitlePreview.params(anilist_row("177709", "SAKAMOTO DAYS", :tv), "Search")
        )

      assert assigns(view).preview.status == :loading
      assert "Loading from AniList…" in texts(view)
      assert_receive {:keyless_request, :anilist, {:detail, 177_709}}, 2_000

      view = answer(view)
      drawn = texts(view)

      assert "SAKAMOTO DAYS" in drawn
      assert "Taro Sakamoto was the ultimate assassin." in drawn
      assert :add_to_library in tap_tags(view)
      refute :episode_0 in tap_tags(view), "a preview drew a tickable episode"

      added = render_info(view, {:tap, :add_to_library})

      assert [tracked] = Ash.read!(TrackedTitle)
      assert {tracked.source, tracked.source_id, tracked.kind} == {:anilist, "177709", :anime}
      assert :mark_next in tap_tags(added)
      assert :episode_0 in tap_tags(added)

      _ticked = render_info(added, {:tap, :mark_next})

      assert [%Watch{episode_source_id: "177709-1"}] =
               Enum.filter(Ash.read!(Watch), &(&1.tracked_title_id == tracked.id))

      reopened = mount_screen(Series, %{id: tracked.id})
      assert "SAKAMOTO DAYS" in texts(reopened)
      assert :mark_next in tap_tags(reopened)
    end

    test "is the anime filter's own, and says where the call came from" do
      track!(anilist_row("177709", "SAKAMOTO DAYS", :tv))

      view = mount_screen(Kati.Screens.AnimeFilter, %{})

      assert %{title: "SAKAMOTO DAYS", note: "Found on AniList, which lists only anime"} =
               assigns(view).anime.misclassified
    end
  end

  describe "an AniList film" do
    test "opens the film page as a preview and adds as an anime film" do
      view =
        mount_screen(
          Film,
          TitlePreview.params(anilist_row("21519", "Your Name.", :movie), "Search")
        )

      view = answer(view)
      assert "Your Name." in texts(view)

      added = render_info(view, {:tap, :add_to_library})

      assert [tracked] = Ash.read!(TrackedTitle)
      assert {tracked.source, tracked.kind} == {:anilist, :anime}
      assert Kati.Media.Anime.film?(tracked.kind, cached(:anilist, "21519"))
      assert assigns(added).film.tracked_id == tracked.id
      assert Kati.UI.eyebrow_label("Your rating") in texts(added)
    end
  end

  describe "a TVmaze series" do
    test "previews from TVmaze, and its real episodes tick once added" do
      view =
        mount_screen(
          Series,
          TitlePreview.params(tvmaze_row("4444", "Sakamoto Desu ga?"), "Search")
        )

      assert "Loading from TVmaze…" in texts(view)
      view = answer(view)
      assert "The Coolest High Schooler" in texts(view)

      added = render_info(view, {:tap, :add_to_library})
      [tracked] = Ash.read!(TrackedTitle)
      _ticked = render_info(added, {:tap, :mark_next})

      assert [%Watch{episode_source_id: "44001"}] =
               Enum.filter(Ash.read!(Watch), &(&1.tracked_title_id == tracked.id))
    end

    test "a catalogue that fails is its own sentence on the preview" do
      KeylessStubs.install!(tvmaze: 500)

      view =
        Series
        |> mount_screen(TitlePreview.params(tvmaze_row("4444", "Sakamoto Desu ga?"), "Search"))
        |> answer()

      assert "TVmaze answered 500. Nothing was saved." in texts(view)
      assert :back in tap_tags(view)
    end
  end

  describe "what only TMDB can answer" do
    setup do
      track!(anilist_row("177709", "SAKAMOTO DAYS", :tv))
      track!(tvmaze_row("4444", "Sakamoto Desu ga?"))
      Application.put_env(:kati, :keyless_titles_owner, self())
      Application.put_env(:kati, :tmdb_test_token, "test-token")
      Application.put_env(:kati, :tmdb_req_options, adapter: TmdbAdapter, retry: false)
      :ok
    end

    test "the cache refresh sends each row to its own catalogue, never TMDB" do
      assert Kati.Media.Cache.tracked() == []
      flush_requests()

      assert {:ok, %{refreshed: 2, failed: 0}} = Kati.Media.Cache.refresh()
      refute_received {:tmdb_asked, _path}
      assert_received {:keyless_request, :anilist, {:detail, 177_709}}
      assert_received {:keyless_request, :tvmaze, {:detail, 4444}}
    end

    test "a cleared cache comes back from AniList and TVmaze, with no TMDB key at all" do
      Application.delete_env(:kati, :tmdb_test_token)
      assert {:ok, _removed} = Kati.Media.Cache.clear()
      assert Ash.read!(CachedTitle) == []

      assert {:ok, %{refreshed: 2, failed: 0}} = Kati.Media.Cache.refresh()
      assert cached(:anilist, "177709").title == "SAKAMOTO DAYS"
      assert cached(:tvmaze, "4444").title == "Sakamoto Desu ga?"
      refute_received {:tmdb_asked, _path}
    end

    test "no keyless title seeds a recommendation" do
      assert Kati.Media.Recommendations.seed() == nil
      assert Kati.Media.Recommendations.seedable() == []
      assert Kati.Media.Recommendations.seed("177709") == nil
    end

    test "their title pages open without asking TMDB anything" do
      for tracked <- Ash.read!(TrackedTitle) do
        view = mount_screen(Series, %{id: tracked.id})
        assert tracked.id == assigns(view).id
      end

      refute_received {:tmdb_asked, _path}
    end

    test "Discover's feed has nothing to seed on, and asks TMDB nothing about them" do
      _view = mount_screen(Kati.Screens.Discover, %{})
      refute_receive {:tmdb_asked, "/3/movie/177709" <> _rest}, 200
      refute_receive {:tmdb_asked, "/3/tv/177709" <> _rest}, 50
      refute_receive {:tmdb_asked, "/3/tv/4444" <> _rest}, 50
    end
  end

  defp anilist_row(id, title, kind),
    do: %{source: :anilist, source_id: id, kind: kind, title: title}

  defp tvmaze_row(id, title), do: %{source: :tvmaze, source_id: id, kind: :tv, title: title}

  defp track!(row) do
    assert {:ok, tracked} = Kati.Screens.AddTitle.track(row.title, row, :watching)
    tracked
  end

  defp cached(source, source_id) do
    Enum.find(Ash.read!(CachedTitle), &(&1.source == source and &1.source_id == source_id))
  end

  defp flush_requests do
    receive do
      {:keyless_request, _source, _what} -> flush_requests()
    after
      0 -> :ok
    end
  end

  defp answer(view) do
    assert_receive {:title_preview, source_id, result}, 5_000
    render_info(view, {:title_preview, source_id, result})
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
