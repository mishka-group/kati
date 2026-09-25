defmodule Kati.ReleaseWatcherTest do
  @moduledoc """
  Screen 25: every control writes `Kati.Settings.Watcher`, reads back after a
  remount, and changes what the app does.

    * **the banner** counts the reader's own followed titles and this week's
      finds — never the board's `Watching 24 titles · 3 FOUND THIS WEEK`;
    * **Tell me about** filters screen 05's two lists and the release alerts;
    * **Push notifications** arms and cancels release alerts through
      `Kati.Notifications.Releases.sync/1`, recorded in
      `Kati.Notifications.Pending`;
    * **Inbox badge** gates Home's unread dot;
    * **Quiet hours** decides whether the scheduler moves a night-time alert;
    * **the master switch** and **the cadence** decide what the background
      worker is asked for.

  Every `Mob.State` key the page writes is set explicitly on the way in;
  `Mob.ScreenCase` gives each test its own `Mob.State`, so nothing outlives the
  test. Every row this file writes is deleted after it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Notifications.Plan
  alias Kati.Notifications.Releases
  alias Kati.Screens.Inbox
  alias Kati.Screens.ReleaseWatcher
  alias Kati.Settings.Watcher

  doctest ReleaseWatcher, only: [watching_line: 1, found_line: 1, kinds: 0, loudness: 0]

  doctest Watcher,
    only: [request: 2, kinds: 0, loudness: 0, release_kind: 1, interval_for: 1]

  defmodule Backend do
    @moduledoc false
    @behaviour Kati.Notifications.Delivery

    @impl true
    def arm(candidate) do
      send(self(), {:armed, candidate.id})
      :ok
    end

    @impl true
    def cancel(id) do
      send(self(), {:cancelled, id})
      :ok
    end
  end

  @tables ~w(media_watches media_content_warnings tracked_titles cached_episodes cached_seasons cached_titles)
  @day 24 * 60 * 60

  setup do
    defaults!()
    empty!()

    on_exit(&empty!/0)

    :ok
  end

  describe "the banner" do
    test "counts zero on a device that follows nothing" do
      assert ReleaseWatcher.banner().title == "Watching 0 titles"
      assert ReleaseWatcher.banner().meta == "NOTHING NEW THIS WEEK"
    end

    test "counts the followed titles and this week's finds" do
      show = track!("Tidewrack", :tv)
      episode!(show, 2, 6, -2 * 60 * 60)
      track!("Vellum", :movie)

      banner = ReleaseWatcher.banner()

      assert banner.title == "Watching 2 titles"
      assert banner.meta == "1 FOUND THIS WEEK"
    end

    test "the master switch writes the store and survives the pop" do
      view = mount_screen(ReleaseWatcher)
      assert view.socket.assigns.watcher.banner.on

      {:noreply, off} = ReleaseWatcher.handle_tap(:banner, view.socket)

      refute off.assigns.watcher.banner.on
      refute Watcher.watching?()
      assert Watcher.request(Watcher.watching?(), Watcher.cadence()) == :cancel
      refute mount_screen(ReleaseWatcher).socket.assigns.watcher.banner.on
    end

    test "the cadence writes the store and survives the pop" do
      view = mount_screen(ReleaseWatcher)

      {:noreply, daily} = ReleaseWatcher.handle_tap(:cadence_Daily, view.socket)

      assert daily.assigns.watcher.cadence == "Daily"
      assert Watcher.cadence() == "Daily"
      assert mount_screen(ReleaseWatcher).socket.assigns.watcher.cadence == "Daily"
      assert Watcher.request(true, Watcher.cadence()) == {:ensure, 24 * 60}
    end
  end

  describe "every switch on the page" do
    test "is drawn with a tap, and a tap flips the store and reads back after a remount" do
      tags =
        Enum.map(Watcher.kinds(), &{:"kind_#{&1}", fn -> Watcher.kind?(&1) end}) ++
          Enum.map(Watcher.loudness(), &{:"loud_#{&1}", fn -> Watcher.loud?(&1) end})

      drawn = inspect(tree(mount_screen(ReleaseWatcher)), limit: :infinity)

      for {tag, read} <- tags do
        assert drawn =~ inspect(tag), "#{tag} is not drawn with a tap"

        before = read.()
        socket = mount_screen(ReleaseWatcher).socket
        {:noreply, flipped} = ReleaseWatcher.handle_tap(tag, socket)

        assert read.() == not before, "#{tag} did not write the store"
        assert on?(flipped, tag) == not before, "#{tag} did not redraw"

        assert on?(mount_screen(ReleaseWatcher).socket, tag) == not before,
               "#{tag} did not survive the pop"
      end
    end

    test "draws none of the controls with nothing behind them" do
      words = text(tree(mount_screen(ReleaseWatcher)))

      for gone <- [
            "New books",
            "New records",
            "Leaving soon",
            "People you follow",
            "Price drops",
            "Renewals",
            "Weekly digest",
            "NOT YET",
            "Watching 24 titles",
            "3 FOUND THIS WEEK"
          ] do
        refute words =~ gone, "screen 25 still draws #{inspect(gone)}"
      end

      assert words =~ "Push notifications"
      assert words =~ "Off — the home card is enough"
    end

    test "a tag naming no switch changes nothing" do
      socket = mount_screen(ReleaseWatcher).socket

      {:noreply, same} = ReleaseWatcher.handle_tap(:kind_price_drops, socket)
      assert same.assigns.watcher == socket.assigns.watcher
    end
  end

  describe "in Persian" do
    test "every row says its two lines in Persian" do
      Kati.Locale.put(:fa)

      words =
        try do
          text(tree(mount_screen(ReleaseWatcher)))
        after
          Kati.Locale.put(:en)
        end

      for persian <- [
            "قسمت‌های سریال‌هایی که دنبال می‌کنید",
            "فیلم‌هایی که دنبال می‌کنید، در روز انتشار",
            "نقطه‌ی روی زنگ صفحه‌ی خانه",
            "خاموش — کارت خانه کافی است"
          ] do
        assert words =~ persian
      end

      for english <- ["Episodes of shows you follow", "The dot on Home's bell", "Film releases"] do
        refute words =~ english
      end
    end
  end

  describe "Tell me about" do
    setup do
      show = track!("Tidewrack", :tv)
      episode!(show, 2, 6, -2 * 60 * 60)
      episode!(show, 2, 7, 3 * @day)
      episode!(show, 3, 1, 5 * @day)
      season!(show, 4, 20 * @day)
      film = track!("Vellum", :movie)
      release!(film, 10 * @day)
      :ok
    end

    test "every kind on draws every release" do
      inbox = Inbox.inbox()

      assert Enum.map(inbox.out_now, & &1.line) == ["S2 E6 — Episode 6"]

      assert Enum.map(inbox.coming_up, & &1.title) == [
               "Tidewrack — S2E7",
               "Tidewrack — S3E1",
               "Vellum",
               "Tidewrack — Season 4"
             ]
    end

    test "New episodes off takes the ordinary episodes out of both lists and the alerts" do
      tap!(:kind_new_episodes)

      inbox = Inbox.inbox()
      assert inbox.out_now == []

      assert Enum.map(inbox.coming_up, & &1.title) == [
               "Tidewrack — S3E1",
               "Vellum",
               "Tidewrack — Season 4"
             ]

      refute Enum.any?(Inbox.alerts(), &String.ends_with?(&1.id, ":2:7"))
    end

    test "Premieres off takes season drops and first episodes out" do
      tap!(:kind_premieres)

      assert Enum.map(Inbox.inbox().coming_up, & &1.title) == ["Tidewrack — S2E7", "Vellum"]
    end

    test "Film releases off takes the film out" do
      tap!(:kind_film_releases)

      refute Enum.any?(Inbox.inbox().coming_up, &(&1.title == "Vellum"))
      refute Enum.any?(Inbox.alerts(), &(&1.title == "Vellum"))
    end
  end

  describe "Push notifications" do
    setup do
      show = track!("Tidewrack", :tv)
      episode!(show, 2, 7, 3 * @day)
      %{id: Kati.Notifications.Sources.Media.episode_id(:tmdb, show.source_id, 2, 7)}
    end

    test "off arms nothing" do
      refute Watcher.loud?(:push)

      assert %{armed: [], cancelled: []} = Releases.sync(backend: Backend)
      assert Releases.armed() == []
    end

    test "on arms the coming-up release and records it; off cancels it", %{id: id} do
      Watcher.put_loud(:push, true)

      assert %{armed: [^id]} = Releases.sync(backend: Backend)
      assert_received {:armed, ^id}
      assert Enum.map(Releases.armed(), & &1.id) == [id]

      assert %{armed: [], cancelled: []} = Releases.sync(backend: Backend),
             "an unchanged plan re-armed what was already armed"

      Watcher.put_loud(:push, false)

      assert %{cancelled: [^id]} = Releases.sync(backend: Backend)
      assert_received {:cancelled, ^id}
      assert Releases.armed() == []
    end

    test "a build with no delivery backend records nothing" do
      Watcher.put_loud(:push, true)

      assert Releases.sync(backend: Kati.Notifications.Delivery.Inert) == {:error, :no_delivery}
      assert Releases.armed() == []
    end

    test "the alert names the show and the episode", %{id: id} do
      alert = Enum.find(Inbox.alerts(), &(&1.id == id))

      assert alert.title == "Tidewrack"
      assert alert.body == "New episode: S2 E7 — Episode 7"
      assert alert.domain == :tv
    end
  end

  describe "Inbox badge" do
    test "off takes the dot off Home's bell" do
      show = track!("Tidewrack", :tv)
      episode!(show, 2, 7, 3 * @day)

      assert Kati.Screens.Home.unread?(), "an armed release alert is waiting behind the bell"

      tap!(:loud_badge)

      refute Kati.Screens.Home.unread?()
    end
  end

  describe "Quiet hours" do
    setup do
      show = track!("Tidewrack", :tv)
      zone = Kati.Time.device_zone()
      night = Date.add(Kati.Time.today(), 2)
      {:ok, at} = Kati.Time.to_utc(NaiveDateTime.new!(night, ~T[02:00:00]), zone)
      episode_at!(show, 2, 7, at)
      %{id: Kati.Notifications.Sources.Media.episode_id(:tmdb, show.source_id, 2, 7)}
    end

    test "on moves a 02:00 alert to the morning", %{id: id} do
      assert Plan.find(Releases.plan(), id).shifted_from
      assert Plan.find(Kati.Screens.InboxNotifications.plan(), id).shifted_from
    end

    test "off leaves it where it is", %{id: id} do
      tap!(:loud_quiet_hours)

      assert Watcher.quiet_hours() == false
      refute Plan.find(Releases.plan(), id).shifted_from
      refute Plan.find(Kati.Screens.InboxNotifications.plan(), id).shifted_from
    end
  end

  defp tap!(tag) do
    {:noreply, _socket} = ReleaseWatcher.handle_tap(tag, mount_screen(ReleaseWatcher).socket)
    :ok
  end

  defp on?(socket, tag) do
    w = socket.assigns.watcher

    row =
      Enum.find(w.kinds ++ w.loudness, fn row ->
        prefix = if row.key in Watcher.kinds(), do: "kind_", else: "loud_"
        tag == :"#{prefix}#{row.key}"
      end)

    row.on
  end

  defp defaults! do
    Enum.each(Watcher.kinds(), &Watcher.put_kind(&1, true))
    Watcher.put_loud(:push, false)
    Watcher.put_loud(:badge, true)
    Watcher.put_loud(:quiet_hours, true)
    Watcher.put_watching(true)
    Watcher.put_cadence("Every 6h")
  end

  defp empty! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM #{table}", [])
    Kati.Repo.query!("DELETE FROM notification_pending WHERE id LIKE 'ep:%'", [])
    :ok
  end

  defp track!(title, kind) do
    source_id = "rw#{System.unique_integer([:positive])}"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: title,
      fetched_at: now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching
    })
  end

  defp episode!(tracked, season, number, seconds),
    do: episode_at!(tracked, season, number, DateTime.add(now(), seconds, :second))

  defp episode_at!(tracked, season, number, at) do
    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      source_id: "rwep#{System.unique_integer([:positive])}",
      title_source_id: tracked.source_id,
      season_number: season,
      episode_number: number,
      title: "Episode #{number}",
      air_at: at,
      date_confidence: :exact,
      fetched_at: now()
    })
  end

  defp season!(tracked, number, seconds) do
    Ash.create!(CachedSeason, %{
      source: :tmdb,
      title_source_id: tracked.source_id,
      season_number: number,
      air_at: DateTime.add(now(), seconds, :second),
      date_confidence: :exact,
      fetched_at: now()
    })
  end

  defp release!(tracked, seconds) do
    CachedTitle
    |> Ash.Query.for_read(:read)
    |> Ash.read!()
    |> Enum.find(&(&1.source_id == tracked.source_id))
    |> Ash.Changeset.for_update(:update, %{
      next_release_at: DateTime.add(now(), seconds, :second),
      date_confidence: :exact
    })
    |> Ash.update!()
  end

  defp now, do: Kati.Time.now() |> DateTime.shift_zone!("Etc/UTC")
end
