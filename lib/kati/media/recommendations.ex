defmodule Kati.Media.Recommendations do
  @moduledoc """
  What to watch next, from a provider that actually knows.

  ## The defect this exists for

  Screen 11 — Discover — was `Kati.Screens.Discover.Sample.feed()` end to end.
  Every string on it was frozen, and six of them were specific claims about the
  reader: *Tuned to 128 titles* on a shelf of six, *Because you watched The
  Long Hollow* for somebody who never had, three films with `94% match`,
  `89% match` and `81% match`, three people the app has never heard of, and
  *Leaving Lumen+ in 7 days* for a service that may not be on the account.
  MOVIES-AND-TV.md ranks it #50 and calls it the app's most confident lie.

  Two of its three sections cannot be made true this round and the screen's own
  moduledoc says why: there is no person anywhere in Kati, and no offers
  resource to hold an availability window. The first one can, and this is it.

  ## What is real, and what a match percentage would have been

  TMDB answers `/movie/{id}/recommendations` and `/tv/{id}/recommendations`.
  That is a real recommendation from a real corpus, keyed on a title the reader
  actually tracked — which is exactly what the drawing's *Because you watched*
  claims to be.

  What comes back carries **no score**, and none is invented here. TMDB's own
  ordering is a ranking and not a percentage, and `94% match` is a statement
  about how well a title fits one particular person's history — Kati runs no
  recommender and has nowhere to keep such a number. So `match` is `nil` and
  screen 11 draws no line under the title. Three real posters with three
  invented percentages under them would have been the same defect with better
  artwork.

  ## Why the seed is the newest touched title

  `Kati.Media.TrackedTitle`'s `:shelf` read is *newest touch first*, and the
  newest touch is the closest thing the app has to *what you are watching now*.
  The heading says which title the picks came from, so the reader can see the
  premise rather than take the list on trust — and when the premise is wrong,
  they know why the list is.

  Archived titles are out, because `:shelf` excludes them: recommending from a
  show somebody hid is recommending from a decision they already made.

  ## Why it is asked for rather than called

  A TMDB request from `mount/3` would block the screen for the length of a
  round trip on a phone's radio, and a screen that pushes and then freezes is
  worse than one that fills in. So `ask/1` runs the work under
  `Kati.TaskSupervisor` — the same shape, and for the same
  `Kati.SupervisionRuleTest` reason, as `Kati.Media.SearchDebounce` — and sends
  `{:recommendations, seed_id, picks}` back. The screen compares `seed_id` with
  what it is drawing and drops an answer about a title it has moved off.

  Posters are downloaded before the message is sent, so the rail draws pictures
  rather than filling in three at a time as the files land. That is the one
  reason this waits on `Kati.Media.Artwork.cache/1` at all — nothing here is
  being kept, and `Artwork` prunes what nothing references.
  """

  alias Kati.Media.Artwork
  alias Kati.Media.CachedTitle
  alias Kati.Media.Tmdb
  alias Kati.Media.TrackedTitle

  require Ash.Query

  # Three, because the drawing's rail is three columns wide. Asking for more
  # and slicing here rather than at the screen keeps the network cost of this
  # feature at three pictures.
  @picks 3

  @kinds [:movie, :tv, :anime]

  @doc """
  The title the picks are drawn from: the newest thing the reader touched.

  `{tracked, cached}` when there is one with a cache row behind it — the cache
  is where the title and the provider id live, and a recommendation needs both
  — and `nil` for every other state: an empty store, a shelf of archived rows,
  a title whose cache was evicted.

  `nil` is what puts screen 11 back on its board, which is the answer an empty
  device should get.
  """
  @spec seed() :: {TrackedTitle.t(), CachedTitle.t()} | nil
  def seed(source_id \\ nil)

  def seed(source_id) when is_binary(source_id) do
    # The title the reader ASKED to be recommended from, if it is still theirs.
    # MOVIES-AND-TV.md #87 gave screen 11's `tune` disc this question, and a
    # named title that has since been removed falls back to the newest rather
    # than answering nothing — the rule every push in this app keeps.
    Enum.find_value(seedable(), fn {tracked, cached} ->
      if cached.source_id == source_id, do: {tracked, cached}
    end) || Kati.Media.Recommendations.seed()
  rescue
    _error -> nil
  end

  def seed(_newest) do
    Enum.find_value(newest(), fn tracked ->
      case cached_for(tracked) do
        %CachedTitle{source_id: id, title: title} = cached
        when is_binary(id) and is_binary(title) and title != "" ->
          {tracked, cached}

        _no_cache ->
          nil
      end
    end)
  rescue
    _error -> nil
  end

  @doc """
  Ask for recommendations, and be sent them when they arrive.

  Sends `{:recommendations, source_id, result}` to `pid`, where `result` is
  `{:ok, picks}` or `{:error, reason}`. The reason travels because the three
  ways this comes back empty are three different things to say: a token nobody
  has entered is a thing the reader can fix in Settings, a request that could
  not be made is a thing to try again, and a provider that knows of nothing
  like this show is neither.

  Answers `:ok` whatever happens. See `Kati.Media.SearchDebounce.ask/2` for why
  the `catch :exit` is not a `rescue`.
  """
  @spec ask(pid(), CachedTitle.t()) :: :ok
  def ask(pid, %CachedTitle{} = cached) when is_pid(pid) do
    work = fn -> send(pid, {:recommendations, cached.source_id, picks_for(cached)}) end

    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, work)
      :ok
    catch
      :exit, _reason ->
        spawn(work)
        :ok
    end
  rescue
    _error -> :ok
  end

  @doc """
  The same, for a BROWSE rather than a recommendation.

  `ask/2` answers *what is like the thing you last touched*, which needs
  something on the shelf. This answers *what is there*, narrowed by board 169's
  sheet, and needs nothing — so screen 11 has something real to draw for a
  reader who has tracked nothing at all, which is the state it used to fill
  with `Kati.Screens.Discover.Sample`.

  The message carries the CHOICE back, for `ask/2`'s own reason: the reader can
  have changed a chip while a request was in flight, and a rail drawn under the
  wrong filter is the same defect as a rail drawn under the wrong seed.
  """
  @spec browse(pid(), map(), Date.t()) :: :ok
  def browse(pid, choice, today) when is_pid(pid) and is_map(choice) do
    work = fn -> send(pid, {:discover, choice, browse_for(choice, today)}) end

    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, work)
      :ok
    catch
      :exit, _reason ->
        spawn(work)
        :ok
    end
  rescue
    _error -> :ok
  end

  @doc """
  The browse itself — the network call, run wherever the caller is.

  Separated from `browse/3` the way `picks_for/1` is separated from `ask/2`, so
  a test can make the request without a supervisor and without a mailbox.
  """
  @spec browse_for(map(), Date.t()) ::
          {:ok, %{picks: [map()], total: non_neg_integer()}} | {:error, term()}
  def browse_for(choice, today) do
    kind = Kati.Discover.Filters.endpoint(choice)

    case Tmdb.discover(kind, Kati.Discover.Filters.params(choice, kind, today)) do
      {:ok, %{picks: rows, total: total}} ->
        {:ok, %{picks: shape(rows), total: total}}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    _error -> {:error, :unavailable}
  end

  @doc """
  TMDB rows as the rail draws them.

  The step `browse_for/2` was missing on its first device run, and the symptom
  was the whole screen: `/discover` answers `poster_path` and the rail reads
  `:seed`, so `Kati.Screens.Discover.pick/1` raised `KeyError` on the first row
  and the pushed screen died with it — a tap on *Discover* that bounced
  straight back to Home. Nothing on the host could have caught it: the host
  suite never makes the request, and the screen test injects an answer already
  in the right shape.

  So both producers end here rather than each shaping its own rows. Titles
  already on the shelf are dropped for `picks_for/1`'s reason — a browse that
  offers you what you are already keeping is not a browse.
  """
  @spec shape([map()]) :: [map()]
  def shape(rows) do
    rows
    |> Enum.reject(&tracked?/1)
    |> Enum.take(@picks)
    |> Enum.map(&pick/1)
  end

  @doc """
  The picks themselves — the network call, run wherever the caller is.

  Separated from `ask/2` so a test can make the request without a supervisor
  and without a mailbox.

  `{:error, reason}` is the client's own reason, verbatim — `:no_api_key` for a
  device nobody has given a token, and whatever `Kati.Media.Tmdb` names for a
  transport failure. A raise anywhere in here is `{:error, :unavailable}`
  rather than a crash: this runs in a task whose only reader is a screen, and
  a screen waiting forever on a message that will not come is worse than one
  that says it could not look.
  """
  @spec picks_for(CachedTitle.t()) :: {:ok, [map()]} | {:error, term()}
  def picks_for(%CachedTitle{source_id: source_id, kind: kind}) do
    case Tmdb.recommendations(source_id, provider_kind(kind)) do
      {:ok, rows} ->
        {:ok,
         rows
         |> Enum.reject(&tracked?/1)
         |> Kati.Media.Recommendations.watchable()
         |> Enum.take(@picks)
         |> Enum.map(&pick/1)}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    _error -> {:error, :unavailable}
  end

  # How many candidates are looked up when the switch is on. See `watchable/1`.
  @lookups 8

  @doc """
  The candidates screen 92's *Hide titles I can't watch* leaves on the rail.

  The whole list untouched when the switch is off, which is its default and
  the state a device is in until somebody turns it on — no extra request, no
  extra wait.

  When it IS on, a suggestion the reader cannot watch is not a suggestion, so
  each candidate is looked up until three have passed. `@lookups` caps it:
  three picks are wanted and a rail is not worth twenty requests, so a reader
  whose rules exclude everything gets a short rail rather than a long pause —
  and a short rail is the true answer to *what can I watch tonight that I have
  not already got*.

  A lookup that fails leaves the candidate IN. `Kati.Media.Availability`'s
  rule, one layer up: unknown is not unavailable, and a rail emptied by a
  request that timed out would be a rail emptied for a reason nobody can see.
  """
  @spec watchable([map()]) :: [map()]
  def watchable(candidates) do
    reader = Kati.Services.availability()

    if reader.rules[:hide_unavailable] do
      candidates
      |> Enum.take(@lookups)
      |> Enum.reject(&Kati.Media.Recommendations.unwatchable?(&1, reader))
    else
      candidates
    end
  end

  @doc false
  @spec unwatchable?(map(), map()) :: boolean()
  def unwatchable?(%{source_id: source_id, kind: kind}, reader) do
    case Tmdb.watch_providers(source_id, kind) do
      {:ok, providers} ->
        Kati.Media.Availability.hide?(
          Kati.Media.Availability.offers(providers, reader.region),
          reader.subscribed,
          reader.rules
        )

      {:error, _reason} ->
        false
    end
  rescue
    _error -> false
  end

  @doc """
  Whether the reader already has this.

  A suggestion to watch a thing that is on the shelf is not a suggestion, and
  on a small library TMDB's answer for one show routinely contains two others
  the reader added the same evening. Rejected before `@picks` is applied, so
  three already-owned titles cost the rail three rows rather than emptying it.

  Read against the whole of `Kati.Media.TrackedTitle` rather than through
  `:shelf`: an archived title is still a title somebody has decided about, and
  suggesting it back is the same noise.
  """
  @spec tracked?(map()) :: boolean()
  def tracked?(%{source_id: source_id}) do
    TrackedTitle
    |> Ash.Query.filter(source == :tmdb and source_id == ^source_id)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> Enum.any?()
  rescue
    _error -> false
  end

  @doc """
  The sentence over the rail, naming the title the picks came from.

      iex> Kati.Media.Recommendations.because("Severance")
      "Because you watched Severance"
  """
  @spec because(String.t()) :: String.t()
  def because(title), do: "Because you watched " <> title

  # One pick, with its poster already on disk. `match: nil` — see the
  # moduledoc. `seed` is the provider path, which `Kati.Design.Images.path/2`
  # resolves through `Kati.Media.Artwork` exactly as a shelf poster is.
  defp pick(row) do
    # A picture that will not download is a pick without a picture, not a lost
    # pick — `Kati.Design.Images.path/2` already answers `nil` for a poster
    # this device has not fetched, and screen 11 already draws the placeholder
    # rectangle behind it.
    _ = safely(fn -> Artwork.cache(row.poster_path) end)

    # `source_id` and `kind` ride along because a recommendation you cannot act
    # on is half a feature — screen 11 was *the only page in the app that shows
    # films you cannot open* (MOVIES-AND-TV.md #14 under screen 11), and these
    # two are exactly what `Kati.Screens.AddTitle.track/2` needs. The board's
    # own picks carry neither, which is what keeps them untappable: a fixture
    # is not a title anybody can add.
    %{
      title: row.title,
      seed: row.poster_path,
      match: nil,
      source_id: row.source_id,
      kind: row.kind,
      added: false
    }
  end

  defp safely(fun) do
    fun.()
  rescue
    _error -> :error
  catch
    :exit, _reason -> :error
  end

  # `:anime` is a Kati kind and not a TMDB one — the provider files anime under
  # `tv`, which is why `Kati.Media.CachedTitle` keeps the three apart and the
  # client only ever sees two.
  defp provider_kind(:movie), do: :movie
  defp provider_kind(_series), do: :tv

  @doc """
  Every title the picks could be seeded on, newest first.

  What screen 11's `tune` disc offers. The same `:shelf` reads `newest/0`
  makes, without its per-kind `limit(1)`: that limit is right for *what am I
  recommending from by default* and wrong for *what could I recommend from*.

  A title with no cache row behind it is left out for `seed/0`'s own reason —
  there is nothing to name it by, and a row offered as a choice has to have a
  name on it.
  """
  @spec seedable() :: [{TrackedTitle.t(), CachedTitle.t()}]
  def seedable do
    @kinds
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    |> Enum.sort_by(& &1.last_touched_at, {:desc, DateTime})
    |> Enum.flat_map(fn tracked ->
      case cached_for(tracked) do
        %CachedTitle{source_id: id, title: title} = cached
        when is_binary(id) and is_binary(title) and title != "" ->
          [{tracked, cached}]

        _no_cache ->
          []
      end
    end)
  rescue
    _error -> []
  end

  defp newest do
    @kinds
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.Query.limit(1)
      |> Ash.read!()
    end)
    |> Enum.sort_by(& &1.last_touched_at, {:desc, DateTime})
  end

  defp cached_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end
end
