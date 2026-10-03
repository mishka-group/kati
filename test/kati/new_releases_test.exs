defmodule Kati.NewReleasesTest do
  @moduledoc """
  Screen 05, *New releases*, does what it shows (#122).

  With two titles followed and nothing dated, it drew `OUT NOW · 0` over
  nothing and `COMING UP` over an empty white card, said *never checked*
  forever because only screen 25's *Check now* ever stamped a check, and
  nothing on the page could look for news or open a coming title.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Inbox
  alias Kati.Settings.Watcher

  @prefix "new-releases-"
  @day 24 * 60 * 60

  setup do
    wipe!()
    on_exit(&wipe!/0)
    :ok
  end

  defp wipe! do
    Mob.State.put(:watcher_last_checked, nil)
    Kati.Repo.query!("DELETE FROM cached_episodes WHERE source_id LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
  end

  defp follow!(suffix, title, kind) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: kind,
      status: :watching
    })
  end

  defp airs!(tracked, s, n, days) do
    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      source_id: @prefix <> "ep-#{System.unique_integer([:positive])}",
      title_source_id: tracked.source_id,
      season_number: s,
      episode_number: n,
      title: "Episode #{n}",
      air_at: DateTime.add(Kati.Time.now(), days * @day, :second),
      date_confidence: :exact,
      fetched_at: Kati.Time.now()
    })
  end

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  describe "with titles followed and nothing dated" do
    test "both lists say so, and there is no empty card" do
      follow!("severance", "Severance", :tv)
      view = mount_screen(Inbox)
      words = text(view)

      assert words =~ "Nothing new in the last week."
      assert words =~ "No dates yet"

      refute Enum.any?(flatten(view), fn node ->
               node.type == :column and node.children == [] and
                 Map.get(node.props, :shadow) == Kati.Theme.shadow_card()
             end),
             "the Coming up card is drawn with nothing in it"
    end
  end

  describe "looking for news" do
    test "a page that has never checked checks as it opens" do
      follow!("severance", "Severance", :tv)
      view = mount_screen(Inbox)

      assert assigns(view).checking?
      assert text(view) =~ "checking now"
      refute :check_now in tags(view)
    end

    test "a fresh check is left alone, and Check now asks anyway" do
      follow!("severance", "Severance", :tv)
      Watcher.checked!()
      view = mount_screen(Inbox)

      refute assigns(view).checking?
      assert :check_now in tags(view)

      view = render_info(view, {:tap, :check_now})
      assert assigns(view).checking?
    end

    test "the answer redraws the page and the line" do
      follow!("severance", "Severance", :tv)
      Watcher.checked!()
      view = mount_screen(Inbox) |> render_info({:tap, :check_now})

      view = render_info(view, {:cache_refreshed, {:ok, %{}}})
      refute assigns(view).checking?
      assert :check_now in tags(view)
    end

    test "a check that could not run says why, and where to fix it" do
      follow!("severance", "Severance", :tv)
      Watcher.checked!()

      view =
        mount_screen(Inbox)
        |> render_info({:tap, :check_now})
        |> render_info({:cache_refreshed, {:error, :no_api_key}})

      assert text(view) =~ "No TMDB key yet"
      assert :open_data_sources in tags(view)

      view = render_info(view, {:cache_refreshed, {:ok, %{}}})
      refute text(view) =~ "No TMDB key yet"
    end

    test "every finished sweep is a check, whoever asked for it" do
      assert Watcher.last_checked() == nil
      assert {:ok, %{}} == Kati.Media.Cache.settle({:ok, %{}})
      assert %DateTime{} = Watcher.last_checked()

      Mob.State.put(:watcher_last_checked, nil)
      Kati.Media.Cache.settle({:error, :offline})
      assert Watcher.last_checked() == nil
    end

    test "stale means older than the cadence, and nothing followed is never stale" do
      refute Inbox.stale?(%{nothing_followed?: true})

      Watcher.checked!()
      refute Inbox.stale?(%{nothing_followed?: false})

      later = DateTime.add(Kati.Time.now(), 7 * 60 * 60, :second)
      assert Inbox.stale?(%{nothing_followed?: false}, later)
    end
  end

  describe "coming up" do
    test "a row opens the title it is about" do
      show = follow!("severance", "Severance", :tv)
      airs!(show, 2, 1, 5)
      Watcher.checked!()

      view = mount_screen(Inbox)
      assert :upcoming_0 in tags(view)

      view = render_info(view, {:tap, :upcoming_0})

      assert {:push, Kati.Screens.Series, %{tracked_id: id}} = view.socket.__mob__.nav_action
      assert id == show.id
    end
  end

  test "the release watcher draws no disc with nothing behind it" do
    view = mount_screen(Kati.Screens.ReleaseWatcher)
    refute Enum.any?(flatten(view), &match?(%{props: %{text: <<0xE5D3::utf8>>}}, &1))
  end
end
