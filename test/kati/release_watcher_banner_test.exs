defmodule Kati.ReleaseWatcherBannerTest do
  @moduledoc """
  Screen 25's banner counts the reader's own library.

  `Watching 24 titles · 3 FOUND THIS WEEK` was `Kati.Settings.WatcherSample`'s
  on every device — two specific claims about somebody's own following, on a
  phone that may follow none. The same class as screen 11's *Tuned to 128
  titles* and screen 07's *1,204 entries*, and both halves are countable:
  `:followed` is the read that decides what the watcher watches, and `out_now`
  is the list screen 05 already builds out of it.

  What is NOT fixed here is the rest of the page. Ten switches and a four-way
  cadence still edit one socket assign and are forgotten on the pop, and
  nothing in the app consumes any of them — MOVIES-AND-TV.md #67. Persisting a
  switch nothing reads would turn *forgotten* into *remembered and still
  inert*, which is a worse lie, so it waits for the brief.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.ReleaseWatcher
  alias Kati.Settings.WatcherSample

  doctest ReleaseWatcher, only: [watching_line: 1, found_line: 1]

  @prefix "watcher-banner-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "with nothing followed" do
    test "the board's line stands" do
      assert ReleaseWatcher.banner() == WatcherSample.banner()
    end

    test "which is the gate every other screen on this list keeps" do
      # `Watching 0 titles` over a page of switches is a page about nothing.
      assert ReleaseWatcher.banner().title == "Watching 24 titles"
    end
  end

  describe "with titles followed" do
    setup do
      followed!("severance", "Severance")
      followed!("arrival", "Arrival")
      :ok
    end

    test "the count is the reader's own" do
      banner = ReleaseWatcher.banner()

      assert banner.title == "Watching 2 titles"

      refute banner.title == WatcherSample.banner().title,
             "the banner still says 24 on a phone that follows two"
    end

    test "and the week's finds are counted rather than frozen" do
      # Nothing has aired for these two, so the honest answer is that nothing
      # was found — not the board's `3 FOUND THIS WEEK`.
      assert ReleaseWatcher.banner().meta == "NOTHING NEW THIS WEEK"
    end

    test "one title is one title" do
      assert ReleaseWatcher.watching_line(%{followed: 1}) == "Watching 1 title"
    end
  end

  describe "the two controls that have a consumer" do
    # MOVIES-AND-TV.md #67 and `design-briefs/D-64`, whose acceptance names this
    # block: *it either goes away because the controls became real, or becomes
    # an assertion about the not-yet state. It must not stay as it is.* Two of
    # the fifteen became real; the rest carry the mark.

    test "the cadence is the reader's, and boot asks the scheduler for it" do
      Kati.Settings.Watcher.put_cadence("Daily")

      {:ok, socket} = ReleaseWatcher.mount(%{}, %{}, Mob.Socket.new(ReleaseWatcher))

      assert socket.assigns.watcher.cadence == "Daily"
      assert Kati.Settings.Watcher.interval_for("Daily") == 24 * 60

      # And it survives the pop, which is the whole of the finding.
      {:ok, again} = ReleaseWatcher.mount(%{}, %{}, Mob.Socket.new(ReleaseWatcher))
      assert again.assigns.watcher.cadence == "Daily"
    end

    test "Manual asks for no periodic work rather than a very long interval" do
      assert Kati.Settings.Watcher.interval_for("Manual") == nil
    end

    test "New episodes gates the notifier, and survives the pop" do
      {:ok, socket} = ReleaseWatcher.mount(%{}, %{}, Mob.Socket.new(ReleaseWatcher))

      # Index 0 is `New episodes`, which is the one live row.
      {:noreply, off} = ReleaseWatcher.handle_tap(:kind_0, socket)

      refute Kati.Settings.Watcher.new_episodes?()
      refute hd(off.assigns.watcher.kinds).on

      followed!("gated", "The Long Hollow")

      assert Kati.Notifications.Sources.Media.followed() == [],
             "the switch is off and the notifier still has titles to tell you about"

      Kati.Settings.Watcher.put_new_episodes(true)
      refute Kati.Notifications.Sources.Media.followed() == []
    end

    test "and the thirteen with no consumer are marked rather than offered" do
      {:ok, socket} = ReleaseWatcher.mount(%{}, %{}, Mob.Socket.new(ReleaseWatcher))
      kinds = socket.assigns.watcher.kinds

      assert [live | rest] = kinds
      assert live.title == "New episodes"
      refute Map.get(live, :not_yet?, false)

      for row <- rest do
        assert Map.get(row, :not_yet?), "#{row.title} has no consumer and is offered as a switch"
      end

      # A marked row carries no tap: a switch a reader can move that changes
      # nothing is the defect this finding reports.
      drawn = inspect(ReleaseWatcher.group(kinds, "kind", 13, 22), limit: :infinity)

      assert drawn =~ "not yet"
      assert length(Regex.scan(~r/:kind_\d/, drawn)) == 1

      # The loudness group is untouched by this round and still the drawing's.
      assert socket.assigns.watcher.loudness == WatcherSample.loudness()
    end
  end

  defp followed!(slug, title) do
    source_id = @prefix <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching
    })
  end
end
