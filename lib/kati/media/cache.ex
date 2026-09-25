defmodule Kati.Media.Cache do
  @moduledoc """
  The two things screen 80 offers to do to the metadata cache: refresh, clear.

  Both pills were drawn without taps — *the only cache
  controls in the app are pictures* — and neither had anything behind it.

  ## Clearing is safe by construction, which is why it can be offered at all

  `Kati.Media.CachedTitle`, `Kati.Media.CachedSeason` and
  `Kati.Media.CachedEpisode` say the same thing in their own moduledocs: they
  are cache, entirely, and no column on any of them can hold something the
  user made. The library is `Kati.Media.TrackedTitle` and the log is
  `Kati.Media.Watch`, and neither is touched here — the reference between the
  two halves is a **value pair** rather than a foreign key precisely so that
  emptying one cannot orphan the other. A cleared cache is a shelf that has
  forgotten every poster and no title, and every tick survives it.

  `Kati.Media.Artwork.clear/0` goes with the rows, because a poster file whose
  row is gone is bytes nothing will ever look up again.

  ## Refreshing is per TRACKED title, not per cached row

  `Kati.Media.Tmdb.fetch/2` re-reads a title and upserts it, its seasons and
  its episodes. Sweeping the tracked shelf rather than the cache table is the
  difference between *bring what I keep up to date* and *re-download whatever
  happens to be lying about*: a cached row with no tracked row behind it is a
  search result nobody added, and refreshing it would spend the reader's
  request budget on a title they did not ask for.

  One title at a time and failures counted rather than raised, for
  `fetch_seasons/3`'s own reason one module over: eight titles refreshed and
  one that could not be is a better answer than nothing, and the answer says
  which.

  ## Off the screen's process

  A refresh is one HTTP round trip per season per show, so it cannot run in a
  tap handler — the screen would stop drawing until TMDB answered. It goes to
  `Kati.TaskSupervisor` and sends `{:cache_refreshed, result}` back, which is
  `Kati.Media.SearchDebounce.ask/2`'s shape and for its reasons: a screen that
  is popped mid-sweep is a `send/2` to a dead pid, which is a no-op, and
  `Kati.SupervisionRuleTest` forbids the alternative.
  """

  alias Kati.Media.Artwork
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Tmdb
  alias Kati.Media.TrackedTitle

  @kinds [:movie, :tv, :anime]

  @doc """
  Empty the metadata cache: the three tables, and the posters they named.

  Answers the number of rows removed, so the screen can say what happened
  rather than redraw and hope.
  """
  @spec clear() :: {:ok, non_neg_integer()} | {:error, term()}
  def clear do
    removed =
      [CachedEpisode, CachedSeason, CachedTitle]
      |> Enum.map(&destroy_all/1)
      |> Enum.sum()

    _ = Artwork.clear()

    {:ok, removed}
  rescue
    error -> {:error, error}
  end

  @doc """
  Re-read every tracked title from TMDB, and say how it went.

  `{:ok, %{refreshed: n, failed: n}}`, or `{:error, reason}` when the whole
  sweep could not start — a missing key is the one that matters, and
  `Kati.Media.Tmdb.message/1` already has the sentence for it.
  """
  @spec refresh() ::
          {:ok, %{refreshed: non_neg_integer(), failed: non_neg_integer()}} | {:error, term()}
  def refresh do
    case Tmdb.key() do
      {:error, reason} ->
        {:error, reason}

      {:ok, _key} ->
        {:ok,
         Kati.Media.Cache.tracked()
         |> Enum.reduce(%{refreshed: 0, failed: 0}, fn tracked, tally ->
           case Tmdb.fetch(tracked.source_id, Kati.Media.Cache.tmdb_kind(tracked.kind)) do
             {:ok, _written} -> Map.update!(tally, :refreshed, &(&1 + 1))
             {:error, _reason} -> Map.update!(tally, :failed, &(&1 + 1))
           end
         end)}
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Ask for a refresh, and be sent `{:cache_refreshed, result}` when it is done.

  Answers `:ok` whatever happens. See the moduledoc.
  """
  @spec ask(pid()) :: :ok
  def ask(pid) when is_pid(pid) do
    sweep = fn -> send(pid, {:cache_refreshed, Kati.Media.Cache.refresh()}) end

    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, sweep)
      :ok
    catch
      :exit, _no_supervisor ->
        spawn(sweep)
        :ok
    end
  end

  @doc false
  @spec tracked() :: [TrackedTitle.t()]
  def tracked do
    Enum.flat_map(@kinds, fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
      |> Enum.filter(&(&1.source == :tmdb))
    end)
  rescue
    _error -> []
  end

  @doc """
  What TMDB calls a kind. Anime is a television series there.

      iex> Kati.Media.Cache.tmdb_kind(:anime)
      :tv

      iex> Kati.Media.Cache.tmdb_kind(:movie)
      :movie
  """
  @spec tmdb_kind(atom()) :: :movie | :tv
  def tmdb_kind(:movie), do: :movie
  def tmdb_kind(_series), do: :tv

  defp destroy_all(resource) do
    rows = Ash.read!(resource)
    Enum.each(rows, &Ash.destroy!/1)
    length(rows)
  end
end
