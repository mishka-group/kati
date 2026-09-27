defmodule Kati.Search.Keyless do
  @moduledoc """
  Screen 19's *On AniList* and *On TVmaze* sections: what the page searches
  when the reader has no TMDB token.

  TMDB answers nothing without the reader's own token, so a fresh install
  searching *sakamoto* used to find nothing at all. AniList (anime, series and
  films) and TVmaze (series) need no key, so with no token saved the same
  query goes to both, and each answers in a section of its own under the
  library — the row look, the skeletons, the preview and the add disc of
  `Kati.Search.OnTmdb`'s section, whose `shape/1`, `mark/1` and `shown/2`
  these rows go through. With a token saved both stay `:idle` and the page is
  the TMDB page it always was.

  ## The state

  `%{anilist: section, tvmaze: section}`, each section `Kati.Search.OnTmdb.t/0`
  with its `source` beside it, moved by the same epoch as the TMDB section:
  `begin/2` on every keystroke, `request/3` once the typing settles or the
  query is committed, and `answered/3` when `{:keyless_answer, source, epoch,
  query, result}` comes back from `fetch/4`'s task.

  ## One title, two catalogues

  An anime series is usually in both. A TVmaze row is dropped when an AniList
  row answers to the same title and the same first year (`duplicate?/2`) —
  the trivial match, and only that one: a near-match is kept twice rather than
  hidden wrongly, because the two rows add different episode lists.
  """

  alias Kati.Screens.AddTitle
  alias Kati.Search.OnTmdb

  @sources [:anilist, :tvmaze]

  @typedoc "One keyless section on the socket."
  @type section :: %{
          source: :anilist | :tvmaze,
          status: :idle | :pending | :ready | :error,
          query: String.t(),
          rows: [map()],
          reason: term(),
          requested: non_neg_integer() | nil
        }

  @typedoc "Both sections."
  @type t :: %{anilist: section(), tvmaze: section()}

  @doc """
  Nothing asked of either.

      iex> Kati.Search.Keyless.idle().tvmaze.status
      :idle
  """
  @spec idle() :: t()
  def idle, do: Map.new(@sources, &{&1, idle(&1)})

  defp idle(source), do: Map.put(OnTmdb.idle(), :source, source)

  @doc "The sources in the order the page draws them."
  @spec sources() :: [:anilist | :tvmaze]
  def sources, do: @sources

  @doc """
  Both sections on `query`, before anything is sent: idle under the minimum or
  when TMDB has a token (`tmdb_ready?`), pending otherwise.

      iex> Kati.Search.Keyless.begin("sakamoto", true).anilist.status
      :idle

      iex> Kati.Search.Keyless.begin(" sakamoto ", false).tvmaze
      %{source: :tvmaze, status: :pending, query: "sakamoto", rows: [], reason: nil, requested: nil}

      iex> Kati.Search.Keyless.begin("s", false).anilist.status
      :idle
  """
  @spec begin(String.t(), boolean()) :: t()
  def begin(query, tmdb_ready?) when is_binary(query) do
    Map.new(@sources, fn source ->
      section =
        if tmdb_ready?,
          do: OnTmdb.idle(),
          else: OnTmdb.begin(query, true)

      {source, Map.put(section, :source, source)}
    end)
  end

  @doc """
  Whether either section is waiting on a request that has not gone out.

      iex> Kati.Search.Keyless.waiting?(Kati.Search.Keyless.begin("sakamoto", false))
      true

      iex> Kati.Search.Keyless.waiting?(Kati.Search.Keyless.idle())
      false
  """
  @spec waiting?(t()) :: boolean()
  def waiting?(state), do: Enum.any?(@sources, &(state[&1].status == :pending))

  @doc """
  Send every pending section's request for `epoch` that has not gone out, and
  mark it sent. `only` narrows it to the sections still on `query`.
  """
  @spec request(t(), pid(), non_neg_integer(), String.t() | nil) :: t()
  def request(state, pid, epoch, only \\ nil) do
    Map.new(@sources, fn source ->
      section = state[source]

      if section.status == :pending and section.requested != epoch and
           (is_nil(only) or section.query == only) do
        Kati.Search.Keyless.fetch(pid, epoch, section.query, source)
        {source, %{section | requested: epoch}}
      else
        {source, section}
      end
    end)
  end

  @doc """
  Ask `source` for `query` off the caller's process, answering `pid` with
  `{:keyless_answer, source, epoch, query, result}` — `Kati.Search.OnTmdb.fetch/3`'s
  task, for the same reasons.
  """
  @spec fetch(pid(), non_neg_integer(), String.t(), :anilist | :tvmaze) :: :ok
  def fetch(pid, epoch, query, source) when is_pid(pid) and source in @sources do
    work = fn ->
      send(
        pid,
        {:keyless_answer, source, epoch, query, Kati.Search.Keyless.search(source, query)}
      )
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

  @doc false
  @spec search(:anilist | :tvmaze, String.t()) :: {:ok, [map()]} | {:error, term()}
  def search(source, query) do
    Kati.Media.Provider.search(source, query)
  rescue
    error -> {:error, {:network, error}}
  end

  @doc """
  The state an answer from `source` puts that section in. An answer for a
  query the section has moved past is the caller's to drop.
  """
  @spec answered(t(), :anilist | :tvmaze, {:ok, [map()]} | {:error, term()}) :: t()
  def answered(state, source, {:ok, results}) when source in @sources,
    do:
      Map.put(state, source, %{state[source] | status: :ready, rows: shape(results), reason: nil})

  def answered(state, source, {:error, reason}) when source in @sources,
    do: Map.put(state, source, %{state[source] | status: :error, rows: [], reason: reason})

  @doc """
  The results in screen 06's row shape — `Kati.Search.OnTmdb.shape/1`'s rows,
  each carrying `:match`, the keys `duplicate?/2` compares.
  """
  @spec shape([map()]) :: [map()]
  def shape(results) do
    results
    |> Enum.map(fn result -> result |> AddTitle.row() |> Map.put(:match, match(result)) end)
    |> AddTitle.positioned()
    |> OnTmdb.mark()
  end

  @doc """
  Every section's rows re-marked against the shelf, after something above the
  page may have added or removed one.
  """
  @spec mark(t()) :: t()
  def mark(state) do
    Map.new(@sources, fn source ->
      section = state[source]
      {source, %{section | rows: OnTmdb.mark(section.rows)}}
    end)
  end

  @doc "The row a tag's position names in `source`'s section, or `nil`."
  @spec at(t(), :anilist | :tvmaze, String.t()) :: map() | nil
  def at(state, source, position) when source in @sources, do: OnTmdb.at(state[source], position)

  @doc """
  The rows `source`'s section draws: not already a library hit above it, and —
  for TVmaze — not the same title AniList already lists.
  """
  @spec shown(t(), :anilist | :tvmaze, [map()]) :: [map()]
  def shown(state, :anilist, local), do: OnTmdb.shown(state.anilist.rows, local)

  def shown(state, :tvmaze, local) do
    anilist = state.anilist.rows

    state.tvmaze.rows
    |> OnTmdb.shown(local)
    |> Enum.reject(&Kati.Search.Keyless.duplicate?(&1, anilist))
  end

  @doc """
  Whether `row` is trivially the same title as one of `others`: a title that
  reads the same once case, spaces and punctuation are set aside, and the
  same first year. A row with no year is never a duplicate.

      iex> Kati.Search.Keyless.duplicate?(
      ...>   %{match: [{"sakamotodays", "2025"}]},
      ...>   [%{match: [{"sakamotodays", "2025"}, {"sakamotodeizu", "2025"}]}]
      ...> )
      true

      iex> Kati.Search.Keyless.duplicate?(%{match: [{"sakamotodays", "2025"}]}, [%{match: [{"sakamotodays", "2024"}]}])
      false
  """
  @spec duplicate?(map(), [map()]) :: boolean()
  def duplicate?(row, others) do
    mine = MapSet.new(Map.get(row, :match, []))

    Enum.any?(others, fn other ->
      Enum.any?(Map.get(other, :match, []), &MapSet.member?(mine, &1))
    end)
  end

  @doc """
  The `{title, year}` keys a result answers to: every title it carries, folded
  to lower-case letters and digits, each with its year.

      iex> Kati.Search.Keyless.match(%{title: "SAKAMOTO DAYS", titles: ["SAKAMOTO DAYS", "Sakamoto Deizu"], year: "2025"})
      [{"sakamotodays", "2025"}, {"sakamotodeizu", "2025"}]

      iex> Kati.Search.Keyless.match(%{title: "Untitled", year: nil})
      []
  """
  @spec match(map()) :: [{String.t(), String.t()}]
  def match(%{year: year} = result) when is_binary(year) do
    [result.title | Map.get(result, :titles, [])]
    |> Enum.map(&fold/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.map(&{&1, year})
  end

  def match(_no_year), do: []

  defp fold(title) when is_binary(title),
    do: title |> String.downcase() |> String.replace(~r/[^\p{L}\p{N}]/u, "")

  defp fold(_other), do: ""
end
