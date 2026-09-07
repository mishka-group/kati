defmodule Kati.MediaCacheTest do
  @moduledoc """
  Screen 80's two cache pills, MOVIES-AND-TV.md #102.

  *Refresh* and *Clear* under **Cached metadata** emitted no tap at all — the
  only cache controls in the app were pictures, and because neither carried a
  tag the sweep could not report them either.

  The claim worth holding down is not that the buttons move. It is what
  **Clear** is allowed to touch: the three cache resources say in their own
  moduledocs that no column on any of them can hold something the user made,
  and the library is joined to them by a value pair rather than a foreign key
  precisely so that emptying one cannot orphan the other. A cleared cache must
  leave every tracked title, every tick and every rating exactly where it was.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Media.Cache, only: [tmdb_kind: 1]

  doctest Kati.Screens.DataSources, only: [refresh_line: 1]

  alias Kati.Media.Cache
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.DataSources

  @prefix "media-cache-"

  setup do
    on_exit(&wipe!/0)
    wipe!()
    %{tracked: seed!()}
  end

  describe "clearing" do
    test "empties the three cache tables" do
      assert {:ok, removed} = Cache.clear()

      assert removed >= 3
      assert Ash.read!(CachedTitle) == []
      assert Ash.read!(CachedSeason) == []
      assert Ash.read!(CachedEpisode) == []
    end

    test "and leaves the library, the ticks and the ratings where they were", %{
      tracked: tracked
    } do
      {:ok, _removed} = Cache.clear()

      assert [kept] = Ash.read!(TrackedTitle) |> Enum.filter(&(&1.id == tracked.id))
      assert kept.status == :watching

      assert [watch] = Ash.read!(Watch) |> Enum.filter(&(&1.tracked_title_id == tracked.id))
      assert watch.rating == 9
    end

    test "and says how many rows went" do
      socket = DataSources |> Mob.Socket.new() |> Mob.Socket.assign(:expanded, nil)

      {:noreply, after_tap} = DataSources.handle_tap(:clear_cache, socket)

      assert after_tap.assigns.cache_notice =~ ~r/^Cleared \d+ cached rows?\.$/
    end

    test "and says so when there was nothing to clear" do
      {:ok, _removed} = Cache.clear()

      socket = DataSources |> Mob.Socket.new() |> Mob.Socket.assign(:expanded, nil)
      {:noreply, after_tap} = DataSources.handle_tap(:clear_cache, socket)

      assert after_tap.assigns.cache_notice == "Nothing was cached."
    end
  end

  describe "refreshing" do
    test "sweeps the tracked shelf and not the cache table", %{tracked: tracked} do
      # A cached row with no tracked row behind it is a search result nobody
      # added, and refreshing it would spend the reader's request budget on a
      # title they did not ask for.
      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: @prefix <> "stranger",
        kind: :movie,
        title: "Never Added",
        fetched_at: Kati.Time.now()
      })

      ids = Cache.tracked() |> Enum.map(& &1.source_id)

      assert tracked.source_id in ids
      refute (@prefix <> "stranger") in ids
    end

    test "says what to do about the failure it meets most often" do
      # A missing key is the one the reader can actually fix — two cards up
      # this same page — and `Kati.Media.Tmdb.message/1` already owns the
      # sentence, so `refresh_line/1` hands it over rather than writing a
      # second one.
      #
      # Asserted on the sentence and not by calling `refresh/0`: this suite
      # shares one store, a key another test stored would send this one to
      # TMDB, and a unit test that makes network requests is a unit test that
      # fails on a train.
      assert DataSources.refresh_line({:error, :no_api_key}) =~ "Settings → Data sources"

      assert DataSources.refresh_line({:error, :no_api_key}) ==
               Kati.Media.Tmdb.message(:no_api_key)
    end

    test "the pill says it is working while the sweep is out" do
      socket = DataSources |> Mob.Socket.new() |> Mob.Socket.assign(:expanded, nil)

      {:noreply, working} = DataSources.handle_tap(:refresh_cache, socket)

      assert working.assigns.refreshing?
      assert working.assigns.cache_notice == nil
      assert inspect(DataSources.cache(nil, true), limit: :infinity) =~ "Refreshing…"
    end

    test "and the answer puts it back and says what happened" do
      socket =
        DataSources
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:expanded, nil)
        |> Mob.Socket.assign(:refreshing?, true)

      {:noreply, done} =
        DataSources.handle_info({:cache_refreshed, {:ok, %{refreshed: 2, failed: 1}}}, socket)

      refute done.assigns.refreshing?
      assert done.assigns.cache_notice == "Refreshed 2 titles. 1 could not be reached."
    end
  end

  describe "the pills themselves" do
    test "carry taps where they carried none" do
      card = inspect(DataSources.cache(), limit: :infinity)

      assert card =~ "refresh_cache"
      assert card =~ "clear_cache"
    end

    test "and the shared pill still draws nothing for a screen with nothing behind it" do
      refute inspect(Kati.UI.SettingsList.action_pill("Got it"), limit: :infinity) =~ "on_tap"
    end

    test "the notice is drawn only when there is something to say" do
      assert DataSources.cache_notice(nil) == %{type: :spacer, children: [], props: %{size: 0}}
      assert inspect(DataSources.cache_notice("Cleared 4 cached rows.")) =~ "Cleared 4"
    end
  end

  defp seed! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Tidewrack",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(CachedSeason, %{
      source: :tmdb,
      title_source_id: @prefix <> "title",
      season_number: 1,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      source_id: @prefix <> "ep",
      title_source_id: @prefix <> "title",
      season_number: 1,
      episode_number: 1,
      title: "Saltmarsh",
      fetched_at: Kati.Time.now()
    })

    tracked =
      Ash.create!(TrackedTitle, %{
        source: :tmdb,
        source_id: @prefix <> "title",
        kind: :tv,
        status: :watching
      })

    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      rating: 9,
      watched_on: Kati.Time.today(),
      watched_at: DateTime.truncate(Kati.Time.now(), :second)
    })

    tracked
  end

  defp wipe! do
    Kati.Repo.query!(
      "DELETE FROM media_watches WHERE tracked_title_id IN " <>
        "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM cached_episodes WHERE title_source_id LIKE ?1", [@prefix <> "%"])

    Kati.Repo.query!("DELETE FROM cached_seasons WHERE title_source_id LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
  end
end
