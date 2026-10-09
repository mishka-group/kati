defmodule Kati.Issue128Test do
  @moduledoc """
  mishka-group/kati#128, one describe per comment: the share card, the Your
  year dock, the Stats charts, What fits, Up next, Discover, the list disc
  and the long season.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Library.UpNextFilters
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Discover
  alias Kati.Screens.Film
  alias Kati.Screens.Series
  alias Kati.Screens.Stats
  alias Kati.Screens.UpNext
  alias Kati.Screens.WhatFits
  alias Kati.Screens.YearShare

  @prefix "issue-128-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM list_memberships")
      Kati.Repo.query!("DELETE FROM media_watches")
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])

      Kati.Repo.query!("DELETE FROM cached_episodes WHERE title_source_id LIKE ?1", [
        @prefix <> "%"
      ])
    end)

    :ok
  end

  describe "the share card (the issue itself)" do
    test "the card carries the id the node capture reads, and the page no scope rail" do
      drawn =
        inspect(YearShare.content(%{scope: :screen, aspect: :aspect_square, hide_private: false}),
          limit: :infinity
        )

      assert drawn =~ "capture_year_card"
      refute drawn =~ "scope_books"
      refute drawn =~ "scope_music"
    end

    test "Save and Share ask for the card, not the screen, and say why when they cannot" do
      socket = Mob.Socket.new(YearShare) |> YearShare.load()

      {:noreply, saved} = YearShare.handle_tap(:save_image, socket)
      {:noreply, shared} = YearShare.handle_tap(:share_image, socket)

      # The host has no bridge: the refusal is drawn rather than swallowed.
      assert is_binary(saved.assigns.save_error)
      assert is_binary(shared.assigns.save_error)
    end

    test "the request names the node, the page colour, the shape and the file" do
      assert Kati.Native.Files.node_request("capture_year_card", "kati-year-2026.png", 1.7778, 1) ==
               "capture_year_card|1|1.7778|kati-year-2026.png"

      assert YearShare.ratio(:aspect_square) == 1.0
      assert YearShare.ratio(:aspect_story) > 1.7
    end

    test "only a capture_ node can be asked for" do
      assert_raise FunctionClauseError, fn ->
        Kati.Native.Files.share_node("year_card", "x.png")
      end
    end
  end

  describe "Your year's dock (comment 1)" do
    test "the round slot shares the year instead of standing empty" do
      drawn = inspect(Kati.Shell.fab(:stats, 0, 0, nil), limit: :infinity)

      assert drawn =~ "share_fab"
      refute drawn =~ "size: 75"

      {:noreply, pushed} = Stats.handle_tap(:share_fab, Mob.Socket.new(Stats))
      assert {:push, Kati.Screens.YearShare, _} = Map.get(pushed.__mob__, :nav_action)
    end
  end

  describe "the Stats charts (comment 2)" do
    test "a month's bar is labelled in hours" do
      assert Stats.hours_label(0) == " "
      assert Stats.hours_label(40) == "<1h"
      assert Stats.hours_label(2719) == "45h"
    end

    test "a Watched most row opens its title, with Stats on the back pill" do
      {tracked, _cached} = shelve!("stats-top", :tv)
      tag = String.to_atom("open_top_" <> tracked.id)

      {:noreply, pushed} = Stats.handle_tap(tag, Mob.Socket.new(Stats))

      assert {:push, Series, %{tracked_id: id, back: "Stats"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == tracked.id
    end
  end

  describe "What fits (comment 2)" do
    test "with nothing known about any row in the region it does not say zero" do
      line = inspect(WhatFits.reachable_line(%{watchable: 0, known: 0}), limit: :infinity)

      assert line =~ "not known"
      refute line =~ "0 of them"
    end

    test "and with something known it counts" do
      assert inspect(WhatFits.reachable_line(%{watchable: 1, known: 2}), limit: :infinity) =~
               "1 of them is on your services"
    end
  end

  describe "Up next (comment 3)" do
    test "no Gone cold band when nothing has gone cold" do
      shelve!("warm", :tv)

      queue = UpNext.queue()

      assert queue.cold == []
      assert queue.cold_label == nil
    end

    test "the whole row opens the title, not only the play disc" do
      {tracked, _cached} = shelve!("row", :tv)
      socket = Mob.Socket.new(UpNext) |> Mob.Socket.assign(:queue, UpNext.queue())

      {:noreply, pushed} = UpNext.handle_tap(String.to_atom("row_" <> tracked.id), socket)

      assert {:push, Series, %{id: id}} = Map.get(pushed.__mob__, :nav_action)
      assert id == tracked.id
    end

    test "a series is measured by its episodes, so the runtime chips and Time left move" do
      {short, _} = shelve!("short", :tv, episodes: List.duplicate(24, 6), at: {1, 2})
      {long, _} = shelve!("long", :tv, episodes: List.duplicate(55, 10), at: {1, 9})

      pool = UpNext.pool()
      buckets = UpNextFilters.buckets(pool)

      assert {:runtime_short, n} = List.keyfind(buckets.runtimes, :runtime_short, 0)
      assert n >= 1
      assert {:runtime_medium, m} = List.keyfind(buckets.runtimes, :runtime_medium, 0)
      assert m >= 1

      ordered =
        UpNextFilters.apply(pool, %{UpNextFilters.resting() | sort: :time_left, direction: :asc})

      ids = Enum.map(ordered.ready, & &1.id)

      # One 55-minute episode left of the long one; four 24-minute ones of the
      # short one, which is 96 minutes.
      assert Enum.find_index(ids, &(&1 == long.id)) < Enum.find_index(ids, &(&1 == short.id))

      closest =
        UpNextFilters.apply(pool, %{
          UpNextFilters.resting()
          | sort: :closest_to_finishing,
            direction: :desc
        })

      assert hd(Enum.filter(Enum.map(closest.ready, & &1.id), &(&1 in [short.id, long.id]))) ==
               long.id
    end

    test "Recently touched is in time order" do
      {older, _} = shelve!("older", :tv, touched: -86_400 * 3)
      {newer, _} = shelve!("newer", :tv, touched: -60)

      ids =
        UpNext.pool()
        |> UpNextFilters.apply(UpNextFilters.resting())
        |> Map.fetch!(:ready)
        |> Enum.map(& &1.id)
        |> Enum.filter(&(&1 in [older.id, newer.id]))

      assert ids == [newer.id, older.id]
    end
  end

  describe "Discover (comment 4)" do
    test "a tap on a pick opens its page and adds nothing" do
      feed =
        Discover.answered(Discover.real_feed(%CachedTitle{title: "Silo", source_id: "1"}), {
          :ok,
          [
            %{
              title: "Severance",
              seed: nil,
              match: nil,
              source_id: "95396",
              kind: :tv,
              added: false
            }
          ]
        })

      socket = Mob.Socket.new(Discover) |> Mob.Socket.assign(:feed, feed)

      {:noreply, pushed} = Discover.handle_tap(:pick_95396, socket)

      assert {:push, Series, %{preview: %{source_id: "95396", kind: :tv}}} =
               Map.get(pushed.__mob__, :nav_action)

      refute Kati.Media.Recommendations.tracked?(%{source_id: "95396"})
    end

    test "the Picks from row scrolls, and its pills carry no shadow" do
      drawn =
        inspect(Discover.seed_chip(%CachedTitle{title: "Silo", source_id: "1"}, false),
          limit: :infinity
        )

      refute drawn =~ "shadow"
    end
  end

  describe "the list disc (comment 5)" do
    test "a series in a list draws the disc gold and filled" do
      {tracked, _} = shelve!("listed-series", :tv, episodes: [40, 40], at: nil)

      before = inspect(Series.list_disc(Series.series(tracked.id)), limit: :infinity)

      {:ok, list} = Kati.Lists.Shelf.create("Weekend")
      :ok = Kati.Lists.Shelf.add(list, tracked.id)

      assert Kati.Lists.Shelf.listed?(tracked.id)
      after_add = inspect(Series.list_disc(Series.series(tracked.id)), limit: :infinity)

      gold = Integer.to_string(Kati.Theme.Palette.gold_icon())
      refute before =~ gold
      assert after_add =~ gold
    end

    test "a film in a list says so on its pill" do
      assert {"bookmarks", "Add to list", :add_to_list} = Film.list_pill(false)
      assert {"bookmarks", "In a list", :add_to_list, _gold} = Film.list_pill(true)
    end
  end

  describe "a long season (comments 3 and 6)" do
    test "draws thirty episodes from the next one to watch, and widens on request" do
      {tracked, _} = shelve!("talk-show", :tv, episodes: List.duplicate(80, 400), at: {1, 120})
      watched!(tracked, 1..120)

      s = Series.series(tracked.id)
      assert length(s.episodes) == 400
      # 120 watched, so the next is position 120, and the window opens two
      # before it.
      assert Series.window(s) == {118, 148}

      drawn = inspect(Series.episodes(s), limit: :infinity)
      assert drawn =~ "episodes_more"
      assert drawn =~ "episodes_earlier"

      wider = Series.widen(s, :episodes_more)
      assert Series.window(wider) == {118, 208}

      earlier = Series.widen(s, :episodes_earlier)
      assert Series.window(earlier) == {58, 148}
    end

    test "a short season is drawn whole" do
      {tracked, _} = shelve!("mini", :tv, episodes: List.duplicate(50, 8), at: {1, 6})
      watched!(tracked, 1..6)

      s = Series.series(tracked.id)
      assert Series.window(s) == {0, 8}
      refute inspect(Series.episodes(s), limit: :infinity) =~ "episodes_more"
    end

    test "opening a title does not reach for the network on the host" do
      {tracked, _} = shelve!("no-net", :tv)
      assert Kati.Media.Cache.refresh_stale(tracked.id) == :ok
    end
  end

  defp watched!(tracked, numbers) do
    for n <- numbers do
      Ash.create!(Kati.Media.Watch, %{
        tracked_title_id: tracked.id,
        episode_source_id: tracked.source_id <> "-e" <> Integer.to_string(n),
        season_number: 1,
        episode_number: n,
        watched_on: Kati.Time.today(),
        watched_at: Kati.Time.now()
      })
    end
  end

  defp shelve!(name, kind, opts \\ []) do
    source_id = @prefix <> name <> "-" <> Integer.to_string(System.unique_integer([:positive]))

    cached =
      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: source_id,
        kind: kind,
        title: name,
        fetched_at: Kati.Time.now()
      })

    {season, episode} =
      case Keyword.get(opts, :at) do
        {s, e} -> {s, e}
        nil -> {nil, nil}
      end

    tracked =
      Ash.create!(TrackedTitle, %{
        source: :tmdb,
        source_id: source_id,
        kind: kind,
        status: :watching,
        progress_season: season,
        progress_episode: episode
      })

    tracked =
      case Keyword.get(opts, :touched) do
        nil ->
          tracked

        seconds ->
          Kati.Repo.query!("UPDATE tracked_titles SET last_touched_at = ?1 WHERE id = ?2", [
            DateTime.add(Kati.Time.now(), seconds, :second),
            tracked.id
          ])

          Ash.get!(TrackedTitle, tracked.id)
      end

    opts
    |> Keyword.get(:episodes, [])
    |> Enum.with_index(1)
    |> Enum.each(fn {runtime, n} ->
      Ash.create!(CachedEpisode, %{
        source: :tmdb,
        source_id: source_id <> "-e" <> Integer.to_string(n),
        title_source_id: source_id,
        season_number: 1,
        episode_number: n,
        runtime_minutes: runtime,
        air_at: DateTime.add(Kati.Time.now(), -86_400 * (500 - n), :second),
        date_confidence: :day,
        fetched_at: Kati.Time.now()
      })
    end)

    {tracked, cached}
  end
end
