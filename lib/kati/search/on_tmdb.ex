defmodule Kati.Search.OnTmdb do
  @moduledoc """
  Screen 19's *On TMDB* section: the catalogue under the reader's own library.

  The owner's ruling: typing a query shows what the reader keeps first, and
  under it what TMDB has for the same words — fetched on its own, without a
  push to screen 06 and without a second button to press. A row found there is
  added from the row itself, through the same `Kati.Screens.AddTitle.track/3`
  screen 06 adds with.

  ## The state, and who moves it

  One map on the socket, `%{status:, query:, rows:, reason:, requested:, page:,
  more?:, more:}`:

    * `:idle` — nothing typed, or less than `Kati.Search.minimum/1`.
    * `:pending` — a request is wanted or in flight; the section draws
      `Kati.Screens.AddTitle.skeletons/0`.
    * `:ready` — TMDB answered; `rows` are shaped by `shape/1`.
    * `:error` — `reason` is what `Kati.Media.Tmdb.message/1` words, and
      `:no_api_key` is the door to screen 80 instead.

  ## More than one page

  `page` is the last page the rows hold and `more?` whether the catalogue said
  there is another. *Show more* under the rows asks for `page + 1`
  (`more_begin/1`, then `fetch_more/5`); `more` is that request's own state —
  `:idle`, `:loading` while the skeletons stand under the rows, or `{:error,
  reason}` when it failed and the control offers to try again. The rows already
  drawn never go back to skeletons, and the answer is appended
  (`more_answered/4`), with a row the reader already sees dropped rather than
  drawn twice. The AniList and TVmaze sections (`Kati.Search.Keyless`) carry
  the same keys and go through the same functions.

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
          requested: non_neg_integer() | nil,
          page: pos_integer(),
          more?: boolean(),
          more: :idle | :loading | {:error, term()}
        }

  @doc "Nothing asked of TMDB."
  @spec idle() :: t()
  def idle,
    do: %{
      status: :idle,
      query: "",
      rows: [],
      reason: nil,
      requested: nil,
      page: 1,
      more?: false,
      more: :idle
    }

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
      %{status: :pending, query: "arrival", rows: [], reason: nil, requested: nil, page: 1, more?: false, more: :idle}
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
    Kati.Media.Tmdb.search_page(query, 1)
  rescue
    error -> {:error, {:network, error}}
  end

  @doc """
  The state an answer puts the section in. A page answer carries `more?`; a
  bare list is a whole answer with nothing after it.
  """
  @spec answered(t(), {:ok, [map()] | map()} | {:error, term()}) :: t()
  def answered(state, answer), do: Kati.Search.OnTmdb.answered(state, answer, &shape/1)

  @doc "`answered/2` with the section's own row shaper."
  @spec answered(t(), {:ok, [map()] | map()} | {:error, term()}, ([map()] -> [map()])) :: t()
  def answered(state, {:ok, %{results: results, more?: more?}}, shaper),
    do: %{
      state
      | status: :ready,
        rows: shaper.(results),
        reason: nil,
        page: 1,
        more?: more?,
        more: :idle
    }

  def answered(state, {:ok, results}, shaper) when is_list(results),
    do: Kati.Search.OnTmdb.answered(state, {:ok, %{results: results, more?: false}}, shaper)

  def answered(state, {:error, reason}, _shaper),
    do: %{state | status: :error, rows: [], reason: reason, more?: false, more: :idle}

  @doc """
  The section with its next page asked for, and that page's number — or
  `:none` when there is nothing to ask: not answered yet, no page after this
  one, or a page already on its way.

      iex> Kati.Search.OnTmdb.more_begin(%{Kati.Search.OnTmdb.idle() | status: :ready, more?: true})
      {:ok, %{Kati.Search.OnTmdb.idle() | status: :ready, more?: true, more: :loading}, 2}

      iex> Kati.Search.OnTmdb.more_begin(%{Kati.Search.OnTmdb.idle() | status: :ready, more?: false})
      :none
  """
  @spec more_begin(t()) :: {:ok, t(), pos_integer()} | :none
  def more_begin(%{status: :ready, more?: true, more: more, page: page} = state)
      when more != :loading,
      do: {:ok, %{state | more: :loading}, page + 1}

  def more_begin(_state), do: :none

  @doc """
  Ask `source` for `page` of `query` off the caller's process, answering `pid`
  with `{:more_answer, source, epoch, query, page, result}` — `fetch/3`'s task.
  """
  @spec fetch_more(pid(), non_neg_integer(), atom(), String.t(), pos_integer()) :: :ok
  def fetch_more(pid, epoch, source, query, page) when is_pid(pid) and is_binary(query) do
    work = fn ->
      result =
        try do
          Kati.Media.Provider.search_page(source, query, page)
        rescue
          error -> {:error, {:network, error}}
        end

      send(pid, {:more_answer, source, epoch, query, page, result})
    end

    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, work)
      :ok
    catch
      :exit, _reason ->
        spawn(work)
        :ok
    end
  end

  @doc """
  The section once `page` has answered: its rows appended after the ones
  already drawn and every row re-positioned, a row already present dropped.
  An answer for a page the section is not waiting on changes nothing; a
  failure keeps the rows and leaves `more?` on, so the control can try again.
  """
  @spec more_answered(t(), pos_integer(), {:ok, map()} | {:error, term()}, ([map()] -> [map()])) ::
          t()
  def more_answered(%{more: :loading, page: last} = state, page, answer, shaper)
      when page == last + 1 do
    case answer do
      {:ok, %{results: results, more?: more?}} ->
        seen = MapSet.new(state.rows, &{&1.source, &1.source_id})

        fresh =
          results
          |> shaper.()
          |> Enum.reject(&MapSet.member?(seen, {&1.source, &1.source_id}))

        %{
          state
          | rows: AddTitle.positioned(state.rows ++ fresh),
            page: page,
            more?: more? and fresh != [],
            more: :idle
        }

      {:error, reason} ->
        %{state | more: {:error, reason}}
    end
  end

  def more_answered(state, _page, _answer, _shaper), do: state

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
