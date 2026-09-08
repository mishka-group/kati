defmodule Kati.Library.UpNextFilters do
  @moduledoc """
  The sort and filter board 167 chooses, and the queue it is applied to.

  Not `Kati.Library.ShelfFilters`: that key holds `:recently_added | :title |
  :rating | :runtime` over the whole shelf. None of board 167's four orderings
  is in it, and one key holding two vocabularies would mean picking `Title` on
  screen 03 reorders screen 10.

  ## Closest to finishing is a fraction, not a bookmark

  A season and an episode number are not a fraction without a season length,
  and screen 10 deliberately does not read `Kati.Media.CachedEpisode` — its own
  moduledoc says why `S2 · E6` stays two numbers. So this is `progress_seconds`
  over `runtime_minutes * 60`, the same pair that prints `18M LEFT`, and
  `Time left` is the absolute remainder of it.

  They are not duplicates: a 22-minute episode 80% through and a three-hour
  film 80% through sort together by fraction and forty minutes apart by
  remainder. Board 167 draws no arithmetic, so nothing on it is contradicted.

  ## Sort persists, filters last a session

  Board 168 rules it: a sort that survives reorders, a filter that survives
  hides — and a silently empty screen on launch is the worse failure. Both live
  under one `Mob.State` key; the filter half carries `:run`, the epoch
  millisecond this VM started, and is dropped on read when it does not match
  `run_id/0`. No new process, and a filter cannot outlive the launch that set
  it.

  On Android the BEAM can outlive an activity restart, so *session* means *this
  launch of the VM* — the honest reading, stated here rather than left to be
  discovered.
  """

  alias Kati.Media.Release

  @key "up_next:filters"
  @sorts [:recently_touched, :closest_to_finishing, :time_left, :airing_soonest]
  @runtimes [:runtime_short, :runtime_medium, :runtime_long, :runtime_unknown]
  @bands [:band_ready, :band_airing, :band_cold]

  @doc "The four orderings board 167 draws."
  @spec sorts() :: [atom()]
  def sorts, do: @sorts

  @doc "The four runtime buckets."
  @spec runtime_keys() :: [atom()]
  def runtime_keys, do: @runtimes

  @doc "The three bands."
  @spec band_keys() :: [atom()]
  def band_keys, do: @bands

  @doc "Nothing chosen: the order screen 10 has always drawn."
  @spec resting() :: map()
  def resting, do: %{sort: :recently_touched, direction: :desc, runtimes: [], bands: []}

  @doc """
  Which way a newly chosen sort points before anyone flips it.

  A sort named *Airing soonest* opening at `:desc` would draw the word
  **soonest** over the latest row. So a newly chosen sort takes its own natural
  direction and a second tap flips it — deliberately NOT
  `Kati.Screens.ShelfFilters.apply_sort/2`'s *any other row becomes the new
  sort at DESC*, whose four keys all read newest-or-highest first.

      iex> Kati.Library.UpNextFilters.natural_direction(:airing_soonest)
      :asc

      iex> Kati.Library.UpNextFilters.natural_direction(:recently_touched)
      :desc
  """
  @spec natural_direction(atom()) :: :asc | :desc
  def natural_direction(:time_left), do: :asc
  def natural_direction(:airing_soonest), do: :asc
  def natural_direction(_newest_first), do: :desc

  @doc "The millisecond this VM started, which is what *session* means here."
  @spec run_id() :: integer()
  def run_id do
    System.convert_time_unit(
      :erlang.system_info(:start_time) + :erlang.time_offset(),
      :native,
      :millisecond
    )
  end

  @doc """
  What the reader chose: the sort always, the filters only within this launch.

  A store this cannot reach answers `resting/0` — the two degradation clauses
  `Kati.Library.ShelfFilters` carries, for its reasons: `Mob.State` is DETS and
  raises when its table is not open, and the GenServer may not be up at all.
  """
  @spec current() :: map()
  def current do
    case Mob.State.get(@key) do
      %{sort: sort, direction: direction} = stored
      when sort in @sorts and direction in [:asc, :desc] ->
        %{
          sort: sort,
          direction: direction,
          runtimes: session(stored, :runtimes, @runtimes),
          bands: session(stored, :bands, @bands)
        }

      _absent ->
        resting()
    end
  rescue
    _error -> resting()
  catch
    :exit, _reason -> resting()
  end

  defp session(%{run: run} = stored, key, allowed) when is_integer(run) do
    if run == run_id(),
      do: Enum.filter(List.wrap(Map.get(stored, key)), &(&1 in allowed)),
      else: []
  end

  defp session(_stored, _key, _allowed), do: []

  @doc "Remember it, stamped with this launch."
  @spec put(map()) :: map()
  def put(choice) do
    Mob.State.put(@key, Map.put(choice, :run, run_id()))
    choice
  rescue
    _error -> choice
  catch
    :exit, _reason -> choice
  end

  @doc """
  Clear the filters and NOT the sort.

  Board 168: it clears the filters only. Sort is the persisted thing, and one
  control doing two jobs is how a reset comes to mean two different things.
  This is where this sheet parts company with
  `Kati.Screens.ShelfFilters.reset/1`, which clears both.
  """
  @spec clear_filters(map()) :: map()
  def clear_filters(choice), do: put(%{choice | runtimes: [], bands: []})

  @doc "Whether any chip is lit."
  @spec narrowed?(map()) :: boolean()
  def narrowed?(choice), do: choice.runtimes != [] or choice.bands != []

  @doc "Whether the order has been moved off the resting one."
  @spec resorted?(map()) :: boolean()
  def resorted?(choice),
    do: {choice.sort, choice.direction} != {resting().sort, resting().direction}

  @doc """
  The chosen chips' words, for the sentence a narrowed page says about itself.

  Labels rather than tags, because the sentence is read: *Under 30m · Gone
  cold* is what the reader picked, in the board's own words.
  """
  @spec names(map()) :: [String.t()]
  def names(choice) do
    Enum.map(choice.runtimes ++ choice.bands, &Kati.Library.UpNextFiltersSample.label/1)
  end

  # ── The arithmetic ──────────────────────────────────────────────────────────

  @doc """
  Under 30m / 30–60m / Over an hour / No runtime.

  The fourth is not padding: a cache row can be evicted and screen 10 renders
  that row `Untitled` rather than dropping it, so it has a position and no
  duration.
  """
  @spec runtime_bucket(map(), map()) :: atom()
  def runtime_bucket(row, cache) do
    case minutes(row, cache) do
      nil -> :runtime_unknown
      m when m < 30 -> :runtime_short
      m when m <= 60 -> :runtime_medium
      _longer -> :runtime_long
    end
  end

  @doc """
  Which bands a row is in — a LIST, because the first two overlap on purpose.

  Board 167 counts `Ready 12 · Airing soon 4 · Gone cold 3` over fifteen rows,
  which is screen 10's own header: the four airing soon are among the twelve
  ready.
  """
  @spec bands_of(map(), map(), boolean()) :: [atom()]
  def bands_of(_row, _cache, true), do: [:band_cold]

  def bands_of(row, cache, _warm) do
    if Kati.Screens.UpNext.airing?(row, cache),
      do: [:band_ready, :band_airing],
      else: [:band_ready]
  end

  @doc """
  Every bucket at its real count, zeroes included.

  Board 168's warning chip, and the one place this differs from
  `Kati.Library.ShelfFilters.facets/1`, which drops an empty bucket: a chip
  offered at `0` says the shelf holds none of that, where a chip that is not
  there says nothing at all.
  """
  @spec buckets(map()) :: map()
  def buckets(pool) do
    rows = Enum.map(pool.ready, &{&1, false}) ++ Enum.map(pool.cold, &{&1, true})

    %{
      runtimes:
        Enum.map(@runtimes, fn tag ->
          {tag, Enum.count(rows, fn {row, _cold?} -> runtime_bucket(row, pool.cache) == tag end)}
        end),
      bands:
        Enum.map(@bands, fn tag ->
          {tag, Enum.count(rows, fn {row, cold?} -> tag in bands_of(row, pool.cache, cold?) end)}
        end)
    }
  end

  @doc """
  The pool, narrowed and ordered.

  Board 145's rule restated, because it is the rule this app keeps: within a
  rail the chips are an OR, across the two rails an AND, and an empty rail
  restricts nothing.
  """
  @spec apply(map(), map()) :: map()
  def apply(pool, choice) do
    %{
      ready:
        pool.ready |> Enum.filter(&keep?(&1, pool.cache, false, choice)) |> order(pool, choice),
      cold: pool.cold |> Enum.filter(&keep?(&1, pool.cache, true, choice)) |> order(pool, choice)
    }
  end

  defp keep?(row, cache, cold?, choice) do
    (choice.runtimes == [] or runtime_bucket(row, cache) in choice.runtimes) and
      (choice.bands == [] or Enum.any?(bands_of(row, cache, cold?), &(&1 in choice.bands)))
  end

  # A row whose key cannot be read sorts LAST in BOTH directions, not at zero:
  # a title with no resume point is not the one closest to finishing, and a
  # title with no runtime does not have nought minutes left. That is the same
  # argument screen 10 makes for drawing no bar rather than a 0% one.
  #
  # It is done by splitting rather than by sorting a `{unknown?, value}` pair,
  # because a pair cannot express it: whichever way round the flag is written,
  # one of the two comparators puts the flagged group at the FRONT. Splitting
  # states the rule directly and is true of both directions by construction.
  defp order(rows, pool, choice) do
    {known, unknown} =
      rows
      |> Enum.map(&{&1, sort_key(&1, pool.cache, choice.sort)})
      |> Enum.split_with(fn {_row, key} -> key != nil end)

    known
    |> Enum.sort_by(fn {_row, key} -> key end, sorter(choice.direction))
    |> Enum.concat(unknown)
    |> Enum.map(fn {row, _key} -> row end)
  end

  defp sorter(:asc), do: &<=/2
  defp sorter(_desc), do: &>=/2

  defp sort_key(row, _cache, :recently_touched), do: row.last_touched_at
  defp sort_key(row, cache, :closest_to_finishing), do: fraction(row, cache)
  defp sort_key(row, cache, :time_left), do: remaining(row, cache)
  defp sort_key(row, cache, :airing_soonest), do: moment(row, cache)

  defp minutes(row, cache) do
    case Map.get(cache, {row.source, row.source_id}) do
      %{runtime_minutes: m} when is_integer(m) and m > 0 -> m
      _unknown -> nil
    end
  end

  defp fraction(row, cache) do
    with m when is_integer(m) <- minutes(row, cache),
         seconds when is_integer(seconds) and seconds > 0 <- row.progress_seconds do
      min(seconds / (m * 60), 1.0)
    else
      _unknown -> nil
    end
  end

  defp remaining(row, cache) do
    with m when is_integer(m) <- minutes(row, cache) do
      max(m * 60 - (row.progress_seconds || 0), 0)
    else
      _unknown -> nil
    end
  end

  defp moment(row, cache) do
    case Release.resolve(row, Map.get(cache, {row.source, row.source_id})) do
      {:exact, at, _origin} -> DateTime.to_unix(at)
      {:day, date, _origin} -> date |> Date.to_erl() |> :calendar.date_to_gregorian_days()
      _no_date -> nil
    end
  end
end
