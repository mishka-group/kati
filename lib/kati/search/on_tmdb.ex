defmodule Kati.Search.OnTmdb do
  @moduledoc """
  Screen 19's *On TMDB* section: the catalogue under the reader's own library.

  The owner's ruling: typing a query shows what the reader keeps first, and
  under it what TMDB has for the same words — fetched on its own, without a
  push to screen 06 and without a second button to press. A row found there is
  added from the row itself, through the same `Kati.Screens.AddTitle.track/3`
  screen 06 adds with.

  ## The state, and who moves it

  One map on the socket, `%{status:, query:, rows:, reason:, requested:}`:

    * `:idle` — nothing typed, or less than `Kati.Search.minimum/1`.
    * `:pending` — a request is wanted or in flight; the section draws
      `Kati.Screens.AddTitle.skeletons/0`.
    * `:ready` — TMDB answered; `rows` are shaped by `shape/1`.
    * `:error` — `reason` is what `Kati.Media.Tmdb.message/1` words, and
      `:no_api_key` is the door to screen 80 instead.

  ## Off the render path, and off the screen's own process

  `fetch/3` makes the request in a task under `Kati.TaskSupervisor` and sends
  `{:tmdb_answer, epoch, query, result}` back, so a slow radio never holds the
  screen. The epoch is the screen's; an answer carrying an older one is for a
  query the reader has typed past, and the screen drops it.
  """

  alias Kati.Screens.AddTitle

  @typedoc "The section's state on the socket."
  @type t :: %{
          status: :idle | :pending | :ready | :error,
          query: String.t(),
          rows: [map()],
          reason: term(),
          requested: non_neg_integer() | nil
        }

  @doc "Nothing asked of TMDB."
  @spec idle() :: t()
  def idle, do: %{status: :idle, query: "", rows: [], reason: nil, requested: nil}

  @doc """
  The state a query starts in, before anything is sent.

  Under the minimum it is idle. With no token it is the refusal straight away —
  a skeleton for a request that can never be made would be a wait for nothing.
  `usable?` is the screen's own answer to `Kati.Media.Tmdb.usable?/0`, read
  once on mount rather than from the secure store on every keystroke.

      iex> Kati.Search.OnTmdb.begin("a", true).status
      :idle

      iex> Kati.Search.OnTmdb.begin("arrival", false).reason
      :no_api_key

      iex> Kati.Search.OnTmdb.begin(" arrival ", true)
      %{status: :pending, query: "arrival", rows: [], reason: nil, requested: nil}
  """
  @spec begin(String.t(), boolean()) :: t()
  def begin(query, usable?) when is_binary(query) do
    trimmed = String.trim(query)

    cond do
      not Kati.Search.long_enough?(trimmed) ->
        idle()

      not usable? ->
        %{idle() | status: :error, query: trimmed, reason: :no_api_key}

      true ->
        %{idle() | status: :pending, query: trimmed}
    end
  end

  @doc """
  Ask TMDB for `query` off the caller's process, answering `pid` with
  `{:tmdb_answer, epoch, query, result}`.

  Supervised when `Kati.TaskSupervisor` is running and plainly spawned when it
  is not, for the reason `Kati.Media.SearchDebounce.ask/2` gives: starting a
  child of a supervisor that is not there exits rather than raises.
  """
  @spec fetch(pid(), non_neg_integer(), String.t()) :: :ok
  def fetch(pid, epoch, query) when is_pid(pid) and is_binary(query) do
    work = fn -> send(pid, {:tmdb_answer, epoch, query, search(query)}) end

    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, work)
      :ok
    catch
      :exit, _reason ->
        spawn(work)
        :ok
    end
  end

  defp search(query) do
    Kati.Media.Tmdb.search(query)
  rescue
    error -> {:error, {:network, error}}
  end

  @doc "The state an answer puts the section in."
  @spec answered(t(), {:ok, [map()]} | {:error, term()}) :: t()
  def answered(state, {:ok, results}),
    do: %{state | status: :ready, rows: shape(results), reason: nil}

  def answered(state, {:error, reason}),
    do: %{state | status: :error, rows: [], reason: reason}

  @doc """
  TMDB's results in screen 06's row shape, each stamped with its position and
  with whether the reader already keeps it.
  """
  @spec shape([map()]) :: [map()]
  def shape(results) do
    results
    |> Enum.map(&AddTitle.row/1)
    |> AddTitle.positioned()
    |> Kati.Search.OnTmdb.mark()
  end

  @doc """
  Each row's `:added` and `:id` from the shelf, read once for the whole list.

  `:id` is the tracked title's, so a row the reader keeps opens screen 04 or 08
  like a library hit does. A shelf that cannot be read leaves the rows as they
  were — unticked is a smaller wrong than no results.

      iex> Kati.Search.OnTmdb.mark([])
      []
  """
  @spec mark([map()]) :: [map()]
  def mark(rows) do
    tracked =
      Kati.Media.TrackedTitle
      |> Ash.read!()
      |> Map.new(&{{&1.source, &1.source_id}, &1.id})

    Enum.map(rows, fn row ->
      id = Map.get(tracked, {row.source, row.source_id})
      row |> Map.put(:added, not is_nil(id)) |> Map.put(:id, id)
    end)
  rescue
    _error -> rows
  end

  @doc """
  The rows the section draws: every TMDB row that is not already a library hit
  above it, matched by `{source, source_id}`.

      iex> Kati.Search.OnTmdb.shown(
      ...>   [%{source: :tmdb, source_id: "1"}, %{source: :tmdb, source_id: "2"}],
      ...>   [%{source: :tmdb, source_id: "1"}]
      ...> )
      [%{source: :tmdb, source_id: "2"}]
  """
  @spec shown([map()], [map()]) :: [map()]
  def shown(rows, local_titles) do
    local =
      MapSet.new(local_titles, &{Map.get(&1, :source), Map.get(&1, :source_id)})

    Enum.reject(rows, &MapSet.member?(local, {&1.source, &1.source_id}))
  end

  @doc "The row a tag's position names, or `nil`."
  @spec at(t(), String.t()) :: map() | nil
  def at(state, position) do
    case Integer.parse(position) do
      {index, ""} when index >= 0 -> Enum.find(state.rows, &(&1.position == index))
      _other -> nil
    end
  end

  @doc "The screen that opens a kept row: a film is its own page, anything else a series."
  @spec destination(map()) :: module()
  def destination(%{kind: :movie}), do: Kati.Screens.Film
  def destination(_row), do: Kati.Screens.Series
end
