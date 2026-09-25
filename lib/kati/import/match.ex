defmodule Kati.Import.Match do
  @moduledoc """
  An imported title, looked up on TMDB after the import has been written.

  `Kati.Import.Commit` creates what *Add by hand* creates — a `:import` cache
  row carrying the name and nothing else, and a tracked row pointing at it.
  That is enough to keep a rating and a date, and it is not a title: no poster,
  no runtime, no genres and, for a series, no episodes — so nothing can be
  ticked and Home's card for it has nothing to say. This is the step that
  makes it one.

  ## The tracked row is re-keyed, not shadowed

  A `Kati.Media.TrackedTitle` names its title by a value pair, and the pair is
  what everything joins on: `Kati.Media.CachedTitle` by `{source, source_id}`,
  and every `Kati.Media.CachedEpisode` by `title_source_id`, which is TMDB's
  id. A second cache row keyed on the import's name could carry the poster and
  never the episodes, which is `Kati.Screens.AddTitle.track/2`'s own argument
  for tracking a TMDB hit under the TMDB id rather than under its title.

  So a match UPDATES the tracked row to `{:tmdb, id}`. The row's id does not
  change, and that id is what the reader's watches, rating, status and
  switches hang off — every one of them survives the move untouched. The
  `:import` cache row is then deleted, because nothing points at it any more;
  cache rows are evictable by definition.

  The name the reader's export used is kept as a `Kati.Media.TitleAlias` when
  TMDB spells the title differently — `Sousou no Frieren` is the reader's word
  for `Frieren: Beyond Journey's End`. That is what lets importing the same
  file again merge into this row rather than creating a second one beside it
  (`Kati.Import.Job.shelf/0` reads aliases), and what lets a player announcing
  the export's name be recognised.

  ## Picking the hit

  `Kati.Media.Tmdb.search/1` with the export's own name. TMDB's search already
  matches alternative and original titles — it is how `Sousou no Frieren`
  finds Frieren at all — so its relevance order is the base. On top of it:

    * **kind** filters. A film record takes a film, a series a series; an
      anime export's `Type` column says which it is, and a record that said
      nothing takes either.
    * **year**, when the record carries one, must agree to within a year, and
      an exact year outranks a near one.
    * **the exact name** outranks a relevant one.

  Nothing is guessed past that: no candidate of the right kind is no match.

  ## Silent by design

  No key, no network, no hit, a hit the reader already tracks under TMDB's id,
  a detail call that fails — each leaves the row exactly as the import wrote it.
  The title still works; it is only still bare. Nothing is shown, because the
  reader asked for an import and got one.

  ## Off the screen

  `start/1` runs the lookups under `Kati.TaskSupervisor`: one search and one
  detail call per title is minutes of radio for a long export, and a screen may
  hold no work that outlives it (`Kati.SupervisionRuleTest`). `run/1` is the
  same work in the caller, which is what the tests use. `backfill/0` asks
  again at boot for every title still on its `:import` row.
  """

  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Media.TitleAlias
  alias Kati.Media.Tmdb
  alias Kati.Media.TrackedTitle

  @doc """
  Look every `{tracked, record}` pair up on TMDB, off the caller's process.

  Answers `{:ok, pid}` for the task doing it, or `:ok` when there was nothing
  to look up. Falls back to a bare `spawn/1` when `Kati.TaskSupervisor` is not
  running — a host test, not the app — for `Kati.Media.Recommendations.ask/2`'s
  reason.
  """
  @spec start([{TrackedTitle.t(), map()}]) :: {:ok, pid()} | :ok
  def start([]), do: :ok

  def start(pairs) when is_list(pairs) do
    work = fn -> Kati.Import.Match.run(pairs) end

    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, work)
    catch
      :exit, _reason -> {:ok, spawn(work)}
    end
  end

  @doc """
  Every imported title still on its `:import` row, looked up again.

  `start/1` runs once, after the commit that created the titles, and that
  moment can be the wrong one: the reader had no key yet, the phone was
  offline, or the import predates this module. Nothing else would ever ask
  again, so `Kati.App` runs this at boot under `Kati.TaskSupervisor`, the way
  it runs `Kati.Media.ArtworkBackfill`.

  The record is rebuilt from what the import kept — the name, the kind, the
  year if the cache row has one, and the cache row's own kind as `:format`,
  which is where `Kati.Import.Commit.create/1` keeps a MyAnimeList `Type`.
  Answers one outcome per row; one query and no requests when there is none.
  """
  @spec backfill() :: [atom() | {:error, term()}]
  def backfill do
    cached =
      CachedTitle
      |> Ash.Query.filter(source == :import)
      |> Ash.read!()
      |> Map.new(&{&1.source_id, &1})

    TrackedTitle
    |> Ash.Query.filter(source == :import)
    |> Ash.read!()
    |> Enum.map(&{&1, Kati.Import.Match.record_of(&1, Map.get(cached, &1.source_id))})
    |> Kati.Import.Match.run()
  rescue
    _error -> []
  end

  @doc false
  def record_of(tracked, cached) do
    %{
      title: (cached && cached.title) || tracked.source_id,
      kind: tracked.kind,
      year: cached && cached.first_release_year,
      format: if(cached && cached.kind in [:movie, :tv], do: cached.kind)
    }
  end

  @doc """
  Look every pair up, in the caller. Answers one outcome per pair, in order.

  Stops asking after the first answer that says TMDB cannot be asked at all —
  no key, a refused token, a network that blocks it — because every other
  title would get the same answer one round trip later.
  """
  @spec run([{TrackedTitle.t(), map()}]) :: [atom()]
  def run(pairs) do
    pairs
    |> Enum.reduce({[], :go}, fn
      _pair, {done, :stop} ->
        {[:skipped | done], :stop}

      {tracked, record}, {done, :go} ->
        outcome = Kati.Import.Match.attach(tracked, record)
        {[outcome | done], if(Kati.Import.Match.unreachable?(outcome), do: :stop, else: :go)}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @doc """
  Whether an outcome means TMDB cannot be asked about anything right now.

      iex> Kati.Import.Match.unreachable?({:error, :no_api_key})
      true

      iex> Kati.Import.Match.unreachable?(:no_match)
      false
  """
  @spec unreachable?(term()) :: boolean()
  def unreachable?({:error, reason}),
    do: reason in [:no_api_key, :unauthorised, :blocked] or match?({:network, _}, reason)

  def unreachable?(_outcome), do: false

  @doc """
  Look one imported title up and, on a match, move it onto TMDB's row.

  `:matched`, `:no_match`, `:taken` when the reader already tracks that TMDB
  title under another name, `:not_imported` for a row that is not (or is no
  longer) an import's, or `{:error, reason}`. See the moduledoc for what each
  leaves behind — in every case but `:matched`, the row as it was.
  """
  @spec attach(TrackedTitle.t(), map()) :: atom() | {:error, term()}
  def attach(%TrackedTitle{source: :import} = tracked, record) do
    with {:ok, results} <- Tmdb.search(record.title),
         %{} = hit <- Kati.Import.Match.best(results, record) || :no_match,
         :free <- Kati.Import.Match.free(hit.source_id),
         {:ok, filled} <- Tmdb.fetch(hit.source_id, hit.kind),
         {:ok, moved} <- Kati.Import.Match.rekey(tracked, hit, filled) do
      Kati.Import.Match.forget_import_row(tracked.source_id)
      Kati.Import.Match.remember_name(record.title, moved, filled)
      _artwork = Kati.Media.Artwork.cache(Kati.Screens.AddTitle.poster_of(filled))
      :matched
    end
  rescue
    error -> {:error, error}
  end

  def attach(_tracked, _record), do: :not_imported

  @doc """
  The search hit a record is, or `nil`. See the moduledoc for the order.

      iex> hits = [
      ...>   %{title: "Arrival", kind: :tv, year: "2016", source_id: "1"},
      ...>   %{title: "Arrival", kind: :movie, year: "1996", source_id: "2"},
      ...>   %{title: "Arrival", kind: :movie, year: "2016", source_id: "3"}
      ...> ]
      iex> Kati.Import.Match.best(hits, %{title: "Arrival", kind: :movie, year: 2016}).source_id
      "3"
      iex> Kati.Import.Match.best(hits, %{title: "Arrival", kind: :movie}).source_id
      "2"
      iex> Kati.Import.Match.best(hits, %{title: "Arrival", kind: :movie, year: 1980})
      nil
  """
  @spec best([map()], map()) :: map() | nil
  def best(results, record) do
    kinds = Kati.Import.Match.kinds(record)
    year = Map.get(record, :year)
    name = Kati.Import.Job.name_key(record.title)

    results
    |> Enum.with_index()
    |> Enum.filter(fn {hit, _rank} ->
      hit.kind in kinds and Kati.Import.Match.year_fits?(hit, year)
    end)
    |> Enum.sort_by(fn {hit, rank} ->
      {-Kati.Import.Match.score(hit, name, year), rank}
    end)
    |> case do
      [{hit, _rank} | _rest] -> hit
      [] -> nil
    end
  end

  @doc """
  The TMDB kinds a record may be matched to.

      iex> Kati.Import.Match.kinds(%{kind: :movie})
      [:movie]

      iex> Kati.Import.Match.kinds(%{kind: :anime, format: :tv})
      [:tv]

      iex> Kati.Import.Match.kinds(%{kind: :anime})
      [:movie, :tv]
  """
  @spec kinds(map()) :: [:movie | :tv]
  def kinds(record) do
    case Map.get(record, :format) || Map.get(record, :kind) do
      :movie -> [:movie]
      :tv -> [:tv]
      _either -> [:movie, :tv]
    end
  end

  @doc false
  def year_fits?(_hit, nil), do: true

  def year_fits?(hit, year) do
    case Kati.Import.Match.hit_year(hit) do
      nil -> true
      found -> abs(found - year) <= 1
    end
  end

  @doc false
  def score(hit, name, year) do
    exact = if Kati.Import.Job.name_key(hit.title) == name, do: 1, else: 0
    dated = if year && Kati.Import.Match.hit_year(hit) == year, do: 2, else: 0
    exact + dated
  end

  @doc false
  def hit_year(hit) do
    case Integer.parse(to_string(Map.get(hit, :year))) do
      {year, ""} -> year
      _unknown -> nil
    end
  end

  @doc false
  def free(source_id) do
    TrackedTitle
    |> Ash.Query.for_read(:by_reference, %{source: :tmdb, source_id: source_id})
    |> Ash.read_one()
    |> case do
      {:ok, nil} -> :free
      _taken -> :taken
    end
  end

  @doc """
  Move the tracked row onto TMDB's pair, keeping everything the reader did.

  An anime stays anime whatever TMDB files it under — the export said so, and
  board 152's rule 2 is that the source's word stands. Anything else takes the
  kind `Kati.Media.Anime.kind_for/3` gives the row TMDB just wrote, which is
  the question `Kati.Screens.AddTitle.track/2` asks of a search hit.
  """
  @spec rekey(TrackedTitle.t(), map(), map()) :: {:ok, TrackedTitle.t()} | {:error, term()}
  def rekey(tracked, hit, filled) do
    kind =
      if tracked.kind == :anime,
        do: :anime,
        else: Kati.Media.Anime.kind_for(hit.kind, Map.get(filled, :title), nil)

    tracked
    |> Ash.Changeset.for_update(:update, %{source: :tmdb, source_id: hit.source_id, kind: kind})
    |> Ash.update()
  end

  @doc false
  def forget_import_row(name) do
    CachedTitle
    |> Ash.Query.filter(source == :import and source_id == ^name)
    |> Ash.read!()
    |> Enum.each(&Ash.destroy!/1)
  end

  @doc false
  def remember_name(name, tracked, filled) do
    known =
      filled |> Map.get(:title) |> CachedTitle.names() |> Enum.map(&Kati.Import.Job.name_key/1)

    if Kati.Import.Job.name_key(name) in known do
      :ok
    else
      TitleAlias.learn(name, tracked.id)
    end
  end
end
