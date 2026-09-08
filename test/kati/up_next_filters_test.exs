defmodule Kati.UpNextFiltersTest do
  @moduledoc """
  Board 167's sheet, and the store behind it.

  Screen 10's `tune` disc opened `Kati.Screens.ShelfFilters` from the day it
  got a tap. That sheet sorts by *Recently added · Title · Your rating ·
  Runtime · Release date* over the whole shelf — not one of which is an
  ordering of a queue — and both sheets wrote one stored key, so choosing
  `Title` on screen 03 reordered Up next and clearing the shelf's chips
  cleared this page's bands.

  What this file holds is the four claims that arrangement could not make:
  that the two stores are separate, that a filter lasts a session and a sort
  does not, that a row can be in two bands at once, and that a filter which
  empties the page says so rather than drawing the *nothing queued* card that
  means something else.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Library.UpNextFilters, as: Filters
  alias Kati.Library.UpNextFiltersSample, as: Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.UpNext

  @prefix "up-next-filters-"
  @key "up_next:filters"

  # No `Mob.State` teardown: `Mob.ScreenCase` starts the store per test against
  # a throwaway data dir and tears it down with the test process, so every test
  # here begins with nothing stored. Deleting the key in `on_exit` would call a
  # GenServer that is already gone.
  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the store is not the shelf's" do
    test "a sort chosen here leaves Kati.Library.ShelfFilters where it was" do
      before = Kati.Library.ShelfFilters.current()

      Filters.put(%{Filters.resting() | sort: :time_left, direction: :asc})

      assert Kati.Library.ShelfFilters.current() == before
      assert Filters.current().sort == :time_left
    end

    test "none of board 167's four orderings is a key the shelf sheet can store" do
      # The concrete form of the argument above: if any of these round-tripped
      # through `stored_sort/1` unchanged, one key really could hold both
      # vocabularies and the two sheets would be safe to share.
      for sort <- Filters.sorts() do
        refute Kati.Screens.ShelfFilters.stored_sort(sort) == sort
      end
    end
  end

  describe "a sort persists and a filter lasts a session" do
    test "both come back within the launch that wrote them" do
      Filters.put(%{sort: :time_left, direction: :asc, runtimes: [:runtime_short], bands: []})

      assert Filters.current() == %{
               sort: :time_left,
               direction: :asc,
               runtimes: [:runtime_short],
               bands: []
             }
    end

    test "a filter written by an earlier launch is dropped and the sort is not" do
      # The stored shape with somebody else's run id in it, which is exactly
      # what survives an app restart on Android: `Mob.State` is DETS, so the
      # file outlives the VM that wrote it.
      Mob.State.put(@key, %{
        sort: :airing_soonest,
        direction: :asc,
        runtimes: [:runtime_short],
        bands: [:band_cold],
        run: Filters.run_id() - 1
      })

      current = Filters.current()

      assert current.sort == :airing_soonest
      assert current.direction == :asc
      assert current.runtimes == []
      assert current.bands == []
    end

    test "a stored value that is not one of the four is refused whole" do
      Mob.State.put(@key, %{sort: :title, direction: :desc, runtimes: [], bands: []})

      assert Filters.current() == Filters.resting()
    end
  end

  describe "a newly chosen sort opens the way its own name reads" do
    test "the two that count down open ascending" do
      assert Filters.natural_direction(:time_left) == :asc
      assert Filters.natural_direction(:airing_soonest) == :asc
    end

    test "the two that count back open descending" do
      assert Filters.natural_direction(:recently_touched) == :desc
      assert Filters.natural_direction(:closest_to_finishing) == :desc
    end

    test "and the sheet writes that direction rather than 145's flat DESC" do
      socket = Mob.Socket.new(Kati.Screens.UpNextFilters)
      Kati.Screens.UpNextFilters.apply_sort(socket, :airing_soonest)

      assert Filters.current().direction == :asc
    end

    test "tapping the row a second time flips it" do
      socket = Mob.Socket.new(Kati.Screens.UpNextFilters)
      Kati.Screens.UpNextFilters.apply_sort(socket, :airing_soonest)
      Kati.Screens.UpNextFilters.apply_sort(socket, :airing_soonest)

      assert Filters.current().direction == :desc
    end
  end

  describe "Reset clears the chips and not the sort" do
    test "which is board 168's ruling, and the one place this parts from 145" do
      Filters.put(%{
        sort: :time_left,
        direction: :asc,
        runtimes: [:runtime_short],
        bands: [:band_cold]
      })

      socket = Mob.Socket.new(Kati.Screens.UpNextFilters)
      Kati.Screens.UpNextFilters.reset(socket)

      assert Filters.current() == %{
               sort: :time_left,
               direction: :asc,
               runtimes: [],
               bands: []
             }
    end
  end

  describe "the arithmetic" do
    test "a runtime lands in one of four buckets, and an unreadable one in the fourth" do
      pool = %{
        cache: %{
          {:tmdb, "a"} => %{runtime_minutes: 22},
          {:tmdb, "b"} => %{runtime_minutes: 60},
          {:tmdb, "c"} => %{runtime_minutes: 155}
        }
      }

      assert Filters.runtime_bucket(%{source: :tmdb, source_id: "a"}, pool.cache) ==
               :runtime_short

      assert Filters.runtime_bucket(%{source: :tmdb, source_id: "b"}, pool.cache) ==
               :runtime_medium

      assert Filters.runtime_bucket(%{source: :tmdb, source_id: "c"}, pool.cache) == :runtime_long

      assert Filters.runtime_bucket(%{source: :tmdb, source_id: "gone"}, pool.cache) ==
               :runtime_unknown
    end

    test "60 minutes is the last minute of the middle bucket, not the first of the long one" do
      # The boundary the board's own words fix: `30-60m` and `Over an hour`.
      cache = %{{:tmdb, "x"} => %{runtime_minutes: 60}, {:tmdb, "y"} => %{runtime_minutes: 61}}

      assert Filters.runtime_bucket(%{source: :tmdb, source_id: "x"}, cache) == :runtime_medium
      assert Filters.runtime_bucket(%{source: :tmdb, source_id: "y"}, cache) == :runtime_long
    end

    test "the three bands add up to more than the rows, because two of them overlap" do
      airing = shelve!("Airing", :tv, next_release_in_days: 3)
      quiet = shelve!("Quiet", :movie)

      pool = UpNext.pool()
      cache = pool.cache

      assert Filters.bands_of(row(pool, airing), cache, false) == [:band_ready, :band_airing]
      assert Filters.bands_of(row(pool, quiet), cache, false) == [:band_ready]
      assert Filters.bands_of(row(pool, quiet), cache, true) == [:band_cold]
    end

    test "every bucket is offered at its real count, zeroes included" do
      shelve!("Only", :movie, runtime: 155)

      buckets = Filters.buckets(UpNext.pool())

      assert {:runtime_long, 1} in buckets.runtimes
      assert {:runtime_short, 0} in buckets.runtimes
      assert {:band_cold, 0} in buckets.bands

      # Not "the empty ones are dropped": a chip offered at 0 says the queue
      # holds none of that, where a chip that is not there says nothing.
      assert length(buckets.runtimes) == length(Filters.runtime_keys())
      assert length(buckets.bands) == length(Filters.band_keys())
    end

    test "chips in one rail are an OR and the two rails are an AND" do
      short = shelve!("Short", :tv, runtime: 22)
      long = shelve!("Long", :movie, runtime: 155)

      pool = UpNext.pool()

      both = Filters.apply(pool, %{Filters.resting() | runtimes: [:runtime_short, :runtime_long]})
      assert ids(both) == Enum.sort([short.id, long.id])

      one = Filters.apply(pool, %{Filters.resting() | runtimes: [:runtime_short]})
      assert ids(one) == [short.id]

      # Across the rails: `Under 30m` AND `Gone cold` over a queue whose only
      # short title is warm is board 168's emptied screen.
      crossed =
        Filters.apply(pool, %{
          Filters.resting()
          | runtimes: [:runtime_short],
            bands: [:band_cold]
        })

      assert ids(crossed) == []
    end

    test "an empty rail restricts nothing" do
      a = shelve!("A", :movie)
      pool = UpNext.pool()

      assert ids(Filters.apply(pool, Filters.resting())) == [a.id]
    end

    test "a row with no runtime sorts last whichever way Time left points" do
      known = shelve!("Known", :movie, runtime: 155)
      unknown = shelve!("Unknown", :movie, runtime: nil)

      pool = UpNext.pool()

      down = Filters.apply(pool, %{Filters.resting() | sort: :time_left, direction: :desc})
      up = Filters.apply(pool, %{Filters.resting() | sort: :time_left, direction: :asc})

      # The point of the `{unknown?, value}` pair: a title with no runtime does
      # not have nought minutes left, so it is not the shortest remainder in
      # `:asc` and not the longest in `:desc` — it is outside the ordering.
      assert List.last(down.ready).id == unknown.id
      assert List.last(up.ready).id == unknown.id
      assert hd(down.ready).id == known.id
      assert hd(up.ready).id == known.id
    end
  end

  describe "the sheet" do
    test "opens on the board's own fifteen when there is nothing on the go" do
      opening = Kati.Screens.UpNextFilters.opening()

      assert opening[:showing] == Sample.total()
      assert opening[:total] == Sample.total()
      assert {:runtime_short, 5} in opening[:runtime_counts]
      assert {:band_ready, 12} in opening[:band_counts]
    end

    test "and on this reader's own counts once there is" do
      shelve!("Only", :movie, runtime: 155)

      opening = Kati.Screens.UpNextFilters.opening()

      assert opening[:showing] == 1
      assert opening[:total] == 1
      assert {:runtime_long, 1} in opening[:runtime_counts]
    end

    test "a chip tap writes, and the footer narrows with it" do
      shelve!("Short", :tv, runtime: 22)
      shelve!("Long", :movie, runtime: 155)

      socket = Mob.Socket.new(Kati.Screens.UpNextFilters)
      narrowed = Kati.Screens.UpNextFilters.toggle(socket, :runtimes, :runtime_short)

      assert Filters.current().runtimes == [:runtime_short]
      assert narrowed.assigns.showing == 1
      assert narrowed.assigns.total == 2
    end

    test "and tapping the same chip again widens it back" do
      shelve!("Short", :tv, runtime: 22)
      shelve!("Long", :movie, runtime: 155)

      socket = Mob.Socket.new(Kati.Screens.UpNextFilters)

      widened =
        socket
        |> Kati.Screens.UpNextFilters.toggle(:runtimes, :runtime_short)
        |> Kati.Screens.UpNextFilters.toggle(:runtimes, :runtime_short)

      assert Filters.current().runtimes == []
      assert widened.assigns.showing == 2
    end

    test "draws every literal board 167 holds under a real queue too" do
      shelve!("Short", :tv, runtime: 22)

      view = mount_screen(Kati.Screens.UpNextFilters)
      words = text(view)

      for label <- ["Sort & filter", "Recently touched", "Airing soonest", "Under 30m", "Reset"] do
        assert words =~ label
      end
    end
  end

  describe "a filter that empties the page" do
    test "says nothing matches, and names the chips that did it" do
      shelve!("Short", :tv, runtime: 22)

      Filters.put(%{Filters.resting() | bands: [:band_cold]})
      queue = UpNext.queue()

      assert queue.subtitle == "Nothing matches"
      assert queue.narrowed? == true
      assert queue.names == ["Gone cold"]
    end

    test "which is a different card from the one an empty shelf gets" do
      # `Nothing queued` is a fact about the shelf and `Nothing matches` is a
      # fact about the chips, and the one thing that fixes each is different.
      shelve!("Short", :tv, runtime: 22)

      Filters.put(%{Filters.resting() | bands: [:band_cold]})
      words = text(mount_screen(Kati.Screens.UpNext))

      assert words =~ "Nothing matches"
      assert words =~ "Clear the filters"
      refute words =~ "Nothing queued"
    end

    test "and its one control clears the chips without touching the sort" do
      shelve!("Short", :tv, runtime: 22)
      Filters.put(%{sort: :time_left, direction: :asc, runtimes: [], bands: [:band_cold]})

      socket = Mob.Socket.new(Kati.Screens.UpNext)
      {:noreply, cleared} = UpNext.handle_tap(:clear_filters, socket)

      assert Filters.current() == %{
               sort: :time_left,
               direction: :asc,
               runtimes: [],
               bands: []
             }

      refute cleared.assigns.queue[:narrowed?]
    end
  end

  defp ids(%{ready: ready, cold: cold}), do: Enum.sort(Enum.map(ready ++ cold, & &1.id))

  defp row(pool, tracked), do: Enum.find(pool.ready ++ pool.cold, &(&1.id == tracked.id))

  defp shelve!(title, kind, opts \\ []) do
    runtime = Keyword.get(opts, :runtime, 45)

    next_release_at =
      case Keyword.get(opts, :next_release_in_days) do
        nil -> nil
        days -> DateTime.add(Kati.Time.now(), days * 86_400, :second)
      end

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      title: title,
      runtime_minutes: runtime,
      next_release_at: next_release_at,
      date_confidence: if(next_release_at, do: :exact, else: :unknown),
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      status: :watching,
      progress_seconds: 600
    })
  end
end
