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

  describe "the rest of the page" do
    test "is still the drawing's, and this file says so rather than hiding it" do
      {:ok, socket} = ReleaseWatcher.mount(%{}, %{}, Mob.Socket.new(ReleaseWatcher))
      watcher = socket.assigns.watcher

      assert watcher.kinds == WatcherSample.kinds()
      assert watcher.cadence == WatcherSample.cadence()
      assert watcher.loudness == WatcherSample.loudness()
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
