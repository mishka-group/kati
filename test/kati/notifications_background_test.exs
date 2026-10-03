defmodule Kati.NotificationsBackgroundTest do
  @moduledoc """
  Notifications without the app open, grouped by title, opening the title,
  configurable, and remembered on the Notifications screen (#125).
  """
  use Mob.ScreenCase, async: false

  alias Kati.Background.Handoff
  alias Kati.Background.Watchlist
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Fold
  alias Kati.Notifications.History
  alias Kati.Notifications.Sources.Rewatch
  alias Kati.Settings.Watcher

  doctest Kati.Notifications.Delivery.Android, only: [opens: 1]
  doctest Kati.Notifications.History, only: [line: 1]
  doctest Kati.Notifications.Sources.Rewatch, only: [anniversary: 2]
  doctest Kati.Screens.ReleaseWatcher, only: [reminders: 0]
  doctest Kati.Settings.Watcher, only: [reminders: 0]

  @prefix "notify-bg-"
  @day 86_400

  setup do
    History.clear()
    Mob.State.put(:notification_armed, %{})
    for key <- [:watcher_scheduled_reminders, :watcher_rewatch_reminders], do: Mob.State.put(key, true)

    on_exit(fn ->
      History.clear()

      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM cached_episodes WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)
  end

  defp follow!(suffix, kind, source \\ :tvmaze) do
    Ash.create!(CachedTitle, %{
      source: source,
      source_id: @prefix <> suffix,
      kind: kind,
      title: "Show " <> suffix,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: source,
      source_id: @prefix <> suffix,
      kind: kind,
      status: :watching
    })
  end

  defp aired!(tracked, s, n, days) do
    Ash.create!(CachedEpisode, %{
      source: tracked.source,
      source_id: @prefix <> "ep-#{System.unique_integer([:positive])}",
      title_source_id: tracked.source_id,
      season_number: s,
      episode_number: n,
      title: "E#{n}",
      air_at: DateTime.add(Kati.Time.now(), days * @day, :second),
      date_confidence: :exact,
      fetched_at: Kati.Time.now()
    })
  end

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  defp candidate(id, tracked_id, at, opts \\ []) do
    Candidate.absolute(id, :tv, at,
      title: Keyword.get(opts, :title, "Dark"),
      body: Keyword.get(opts, :body, "New episode"),
      meta: %{tracked_id: tracked_id, kind: :tv}
    )
  end

  describe "one notification per title per day" do
    test "a day's updates for one title fold into the earliest, counting the rest" do
      at = ~U[2026-10-10 18:00:00Z]

      [folded] =
        Fold.by_title(
          [
            candidate("a", "dark", at),
            candidate("b", "dark", DateTime.add(at, 600)),
            candidate("c", "dark", DateTime.add(at, 1200))
          ],
          "Etc/UTC"
        )

      assert folded.id == "a"
      assert folded.body == "3 new episodes"
      assert folded.members == ["a", "b", "c"]
    end

    test "different titles and different days stay apart" do
      at = ~U[2026-10-10 18:00:00Z]

      out =
        Fold.by_title(
          [
            candidate("a", "dark", at),
            candidate("b", "severance", at),
            candidate("c", "dark", DateTime.add(at, @day))
          ],
          "Etc/UTC"
        )

      assert length(out) == 3
    end
  end

  describe "a tap opens the title" do
    test "the alarm's payload carries the title for Kati.Widgets.Launch" do
      payload =
        Kati.Notifications.Delivery.Android.payload(%{
          candidate("a", "abc", ~U[2026-10-10 18:00:00Z])
          | fire_at: ~U[2026-10-10 18:00:00Z]
        })

      assert payload["data"]["kati_open"] == "title"
      assert payload["data"]["id"] == "abc"
    end

    test "a notification about several titles opens the Notifications screen" do
      socket = Mob.Socket.new(Kati.Screens.Home)
      opened = Kati.Widgets.Launch.open(socket, %{data: %{kati_open: "notifications"}})

      assert {:push, Kati.Screens.InboxNotifications, _} = opened.__mob__.nav_action
    end
  end

  describe "the watchlist the worker reads" do
    test "names each followed show with the last episode Kati knows aired" do
      show = follow!("dark", :tv)
      aired!(show, 1, 3, -10)
      aired!(show, 1, 4, -3)
      aired!(show, 1, 5, 4)

      [entry] = Enum.filter(Watchlist.entries(), &(&1.tracked_id == show.id))
      assert entry.last_season == 1
      assert entry.last_episode == 4
      assert entry.title == "Show dark"
    end

    test "leaves out a muted show, and everything when New episodes is off" do
      show = follow!("muted", :tv)
      Ash.update!(show, %{notify_new_episodes: false})
      refute Enum.any?(Watchlist.entries(), &(&1.tracked_id == show.id))

      other = follow!("other", :tv)
      Watcher.put_kind(:new_episodes, false)
      refute Enum.any?(Watchlist.entries(), &(&1.tracked_id == other.id))
      Watcher.put_kind(:new_episodes, true)
    end

    test "is written with the settings and the words, in the reader's digits" do
      show = follow!("dark", :tv)
      aired!(show, 2, 6, -1)
      dir = Path.join(System.tmp_dir!(), "kati-watchlist-#{System.unique_integer([:positive])}")

      assert {:ok, _n} = Watchlist.write(dir: dir)
      body = [dir: dir] |> Handoff.watchlist_path() |> File.read!() |> :json.decode()

      assert is_boolean(body["settings"]["push"])
      assert body["strings"]["one"] =~ "{range}"
      assert body["strings"]["digits"] == "0123456789"
      assert Enum.any?(body["items"], &(&1["tracked_id"] == show.id and &1["last_episode"] == 6))

      Kati.Locale.put(:fa)
      assert Watchlist.strings()["digits"] == "۰۱۲۳۴۵۶۷۸۹"
      Kati.Locale.put(:en)
    end
  end

  describe "the history the Notifications screen shows" do
    test "an armed alarm becomes history once its time has passed, grouped by title" do
      at = DateTime.add(Kati.Time.now(), -60)

      History.remember_armed([
        %{candidate("a", "dark", at, body: "New episode · S2E7") | fire_at: at},
        %{candidate("b", "dark", at, body: "New episode · S2E8") | fire_at: at},
        %{
          candidate("c", "later", DateTime.add(at, 9_000))
          | fire_at: DateTime.add(at, 9_000)
        }
      ])

      History.collect()
      [group] = History.grouped()

      assert group.tracked_id == "dark"
      assert group.count == 2
      assert History.line(group) =~ "2 updates"
      assert History.unread() == 2
    end

    test "the worker's finds are added once, however many times a run is read" do
      items = [%{"tracked_id" => "dark", "key" => "S2E7", "title" => "Dark", "body" => "New"}]
      History.add_found(items, Kati.Time.now())
      History.add_found(items, Kati.Time.now())

      assert length(History.list()) == 1
    end

    test "the screen shows it, opens the title, marks it read, and clears" do
      show = follow!("dark", :tv)

      History.add_found(
        [%{"tracked_id" => show.id, "kind" => "tv", "key" => "S1E2", "title" => "Dark", "body" => "New"}],
        Kati.Time.now()
      )

      view = mount_screen(Kati.Screens.InboxNotifications)
      assert text(view) =~ "Dark"
      assert :recent_0 in tags(view)
      assert History.unread() == 0

      opened = render_info(view, {:tap, :recent_0})
      assert {:push, Kati.Screens.Series, %{tracked_id: id}} = opened.socket.__mob__.nav_action
      assert id == show.id

      cleared = render_info(view, {:tap, :clear_recent})
      refute :recent_0 in tags(cleared)
      assert History.list() == []
    end
  end

  describe "the Notifications screen" do
    test "every section row opens its section" do
      view = mount_screen(Kati.Screens.InboxNotifications)

      for tag <- [:open_calendar, :open_tv, :open_habits, :open_meals, :open_health, :open_money] do
        assert tag in tags(view), "#{tag} is drawn without a tap"
      end
    end

    test "the empty state has a way to the settings" do
      view = mount_screen(Kati.Screens.InboxNotifications)
      assert :open_watcher in tags(view)
    end
  end

  describe "rewatch reminders" do
    test "a loved title, on the anniversary of its last watch, at 19:00" do
      film = follow!("dune", :movie, :tmdb)
      today = Kati.Time.today()
      watched = Date.add(today, -365 + 3)

      Ash.create!(Watch, %{
        tracked_title_id: film.id,
        watched_at: DateTime.new!(watched, ~T[12:00:00], "Etc/UTC"),
        rating: 9
      })

      [c] = Enum.filter(Rewatch.candidates(today, "Etc/UTC"), &(&1.meta.tracked_id == film.id))
      assert {:wall_clock, naive, _zone} = c.at
      assert NaiveDateTime.to_date(naive) == Date.add(watched, 365)
      assert naive.hour == 19
      assert c.body =~ "a year ago"
    end

    test "nothing for a title rated below four stars, or for a recent watch" do
      film = follow!("meh", :movie, :tmdb)

      Ash.create!(Watch, %{
        tracked_title_id: film.id,
        watched_at: DateTime.add(Kati.Time.now(), -360 * @day),
        rating: 5
      })

      refute Enum.any?(Rewatch.candidates(), &(&1.meta.tracked_id == film.id))
    end

    test "the switch turns them off" do
      film = follow!("dune", :movie, :tmdb)
      watched = Date.add(Kati.Time.today(), -362)

      Ash.create!(Watch, %{
        tracked_title_id: film.id,
        watched_at: DateTime.new!(watched, ~T[12:00:00], "Etc/UTC"),
        rating: 10
      })

      assert Enum.any?(Kati.Notifications.Reminders.candidates(), &(&1.meta.tracked_id == film.id))

      Watcher.put_reminder(:rewatch, false)
      refute Enum.any?(Kati.Notifications.Reminders.candidates(), &(&1.meta.tracked_id == film.id))
    end
  end

  describe "the settings" do
    test "screen 25 draws both reminder switches, and each flips its store" do
      view = mount_screen(Kati.Screens.ReleaseWatcher)
      assert :remind_scheduled in tags(view)
      assert :remind_rewatch in tags(view)

      render_info(view, {:tap, :remind_rewatch})
      refute Watcher.reminder?(:rewatch)
      render_info(view, {:tap, :remind_scheduled})
      refute Watcher.reminder?(:scheduled)
    end

    test "the diagnostic says what push and quiet hours actually are" do
      Watcher.put_loud(:push, true)
      view = mount_screen(Kati.Screens.NotificationsHelp)
      assert text(view) =~ "Push is on"

      Watcher.put_loud(:push, false)
      Watcher.put_loud(:quiet_hours, false)
      view = mount_screen(Kati.Screens.NotificationsHelp)
      assert text(view) =~ "Push is off until you ask"
      assert text(view) =~ "night included"
      Watcher.put_loud(:quiet_hours, true)
    end
  end
end
