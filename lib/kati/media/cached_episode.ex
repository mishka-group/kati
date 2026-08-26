defmodule Kati.Media.CachedEpisode do
  @moduledoc """
  One episode of a series, as a provider describes it. **Entirely evictable.**

  `Kati.Media.Watch` has always carried an `episode_source_id` — *"the
  provider's own episode id"* — and until now nothing in Kati stored the record
  it names. A tick could say *something was watched*; nothing could say what
  S2E6 is called, how long it runs or when it aired. That is the whole of
  screen 04's list, screen 05's `S2 E6 — Ash and After`, and screen 34's running
  order, and it is why all three sat on their Sample modules.

  ## Why this is cache and not user data

  `Kati.Media.CachePolicy`'s test decides it: *would the user lose something
  they created?* Nobody authored "48 min", "Ash and After" or "aired 6 Aug" — a
  provider did, and a re-fetch says them again. So an episode is cache: it has
  a not-null `fetched_at` so the eviction sweep can reach it, and it holds
  **nothing the user did**. There is no `watched` column here, and there must
  never be one: whether an episode is ticked is a `Kati.Media.Watch` row, on the
  durable side, and putting a copy of that answer on an evictable row would
  make a cache wipe cost the user their progress.

  ## How it is reached, and by what

  Keyed by `{source, source_id}` and unique on the pair, exactly as
  `Kati.Media.CachedTitle` is. `source_id` is the provider's id for *this
  episode*, which is the value `Kati.Media.Watch.episode_source_id` already
  holds — so a tick reaches its episode as `{tracked.source, watch.episode_source_id}`,
  a **value pair and never a foreign key**. `for_ticks/2` is that join, done in
  one query.

  An episode carries only one `source` because it is always the same provider
  as the title it belongs to: an episode id from TVmaze is meaningless against
  a TMDB title, and `Kati.Media.Watch` has nowhere to record a second source
  anyway — it reaches the episode through its tracked title's. So the parent is
  `{source, title_source_id}` and it, too, is a value pair. Nothing cascades:
  evicting a title leaves its episodes standing, evicting the episodes leaves
  the title standing, and both re-fetch into the same references.

  ## The air date obeys #74

  `air_at` never travels without `date_confidence`, and neither is read here.
  `Kati.Media.Release` is the only thing allowed to turn the pair into an
  answer — `Kati.Media.Release.air/1` for what to draw,
  `Kati.Media.Release.alarm_for/3` for what may be scheduled — because an
  episode "airing Thursday" that is really a bare year must not arm an alarm,
  and a second module deciding that would be a second rule to keep in step.
  `:unknown` is the default for the same reason it is on `CachedTitle`: a row a
  source never annotated must degrade, not arm.

  ## The numbering is a label, not an identity

  `Kati.Media.Watch` states the rule this resource has to live up to: *"your
  ticks follow the episode, not the number."* `season_number`,
  `episode_number` and `absolute_number` are all what one order happens to call
  this episode, and every one of them is nullable — TVmaze gives a special a
  season and no number at all. The identity is `source_id`, and only `source_id`.

  `special` is stored rather than derived from `season_number == 0`. That
  equivalence is TMDB's convention and TVmaze does not share it (a special
  there keeps its real season and loses its number), so deriving it would be
  right for one source and wrong for another.

  **DVD order is deliberately absent.** Screen 34 draws three tiles — Aired,
  Absolute, DVD — and `orders/0` answers with two, because no source in
  `Kati.Media.CachePolicy.sources/0` provides per-episode DVD numbering: TVDB's
  `dvdSeason`/`dvdEpisodeNumber` are the fields that would fill it and Kati
  never fetches from TVDB (it stores a `tvdb_id` for reconciliation and nothing
  more), while TMDB expresses alternate orders as *episode groups*, which is a
  separate endpoint and a separate record, not a column here. A column nothing
  can fill is worse than an order Kati admits it does not have.
  """
  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  require Ash.Query

  sqlite do
    table "cached_episodes"
    repo Kati.Repo

    custom_indexes do
      # The identity, and the pair a tick joins on.
      index [:source, :source_id], unique: true
      # Screen 04's list for one title, and screen 34's running order.
      index [:source, :title_source_id, :season_number, :episode_number]
      # The eviction sweep and the staleness scan, as on cached_titles.
      index [:source, :fetched_at]
      # Screen 05: what is out now, and what is coming up.
      index [:air_at]
    end
  end

  attributes do
    uuid_primary_key :id

    # ── Identity ───────────────────────────────────────────────────────────
    # The same list as CachedTitle's and TrackedTitle's, held as a literal here
    # too and pinned equal by `Kati.Media.EpisodeTest`: an episode naming a
    # source the cache cannot hold could never be fetched.
    attribute :source, :atom,
      allow_nil?: false,
      public?: true,
      # `:manual` — see `Kati.Media.CachedTitle`. Every resource in this domain
      # names the same sources, and `Kati.Media.EpisodeTest` enforces it: a
      # source one resource accepts and another rejects is a row that can be
      # created and then not joined to.
      constraints: [
        one_of: [:manual, :tmdb, :tvmaze, :anilist, :jikan, :openlibrary, :musicbrainz, :wikidata]
      ]

    # The provider's id for this episode. `Kati.Media.Watch.episode_source_id`
    # holds this value, which is what makes a tick joinable.
    attribute :source_id, :string, allow_nil?: false, public?: true

    # The provider's id for the title this belongs to — `CachedTitle.source_id`.
    # A value, not a foreign key: see the moduledoc.
    attribute :title_source_id, :string, allow_nil?: false, public?: true

    # ── Numbering, which is a label ────────────────────────────────────────
    # 0 is a legal season: TMDB files specials there. Nullable because TVmaze
    # gives some specials no placement at all, and inventing one would be the
    # renumbering screen 34's caption warns about.
    attribute :season_number, :integer, public?: true, constraints: [min: 0]

    # Nullable for the same reason, and `min: 0` because a pilot numbered 0 is a
    # real thing a source says rather than an error to reject.
    attribute :episode_number, :integer, public?: true, constraints: [min: 0]

    # AniList `Media.episodes` numbering and Jikan's `mal_id`-ordered list count
    # straight through a series without restarting each season, which is how
    # anime is numbered and what screen 34's Absolute tile shows. Null wherever
    # a source does not number that way — TMDB and TVmaze do not.
    attribute :absolute_number, :integer, public?: true, constraints: [min: 1]

    # Stored, not derived from season 0 — see the moduledoc. Screen 34 draws it
    # as a bronze number and a SPECIAL badge: in the order, out of the count.
    attribute :special, :boolean, allow_nil?: false, default: false, public?: true

    # ── Cached projection ──────────────────────────────────────────────────
    # Nullable: an episode announced but not yet titled is normal, and "TBA" is
    # a string a provider invented rather than a name.
    attribute :title, :string, public?: true
    attribute :overview, :string, public?: true

    # The episode still (TMDB `still_path`, TVmaze `image.original`). Named apart
    # from `CachedTitle.poster_path` because it is a different crop of a
    # different thing.
    attribute :still_path, :string, public?: true

    # Screen 04's "48 min", screen 34's "54m". `min: 1` for the reason the shelf
    # denominators carry it: a source answering 0 is declining to say, and a
    # stored zero would be drawn as a runtime of nothing.
    attribute :runtime_minutes, :integer, public?: true, constraints: [min: 1]

    # ── When it airs (#74) ─────────────────────────────────────────────────
    # Never read here. `Kati.Media.Release` is the only reader — see the
    # moduledoc.
    attribute :air_at, :utc_datetime_usec, public?: true

    # The same ladder as `CachedTitle.date_confidence`, defaulting to the same
    # `:unknown`, so a row nothing annotated degrades instead of arming.
    attribute :date_confidence, :atom,
      allow_nil?: false,
      default: :unknown,
      public?: true,
      constraints: [one_of: [:exact, :day, :month, :quarter, :year, :unknown]]

    # Which source produced `air_at`. TVmaze's `airstamp` is an instant and
    # TMDB's `air_date` is a bare date, so a disagreement needs to know who said
    # what before it can be resolved.
    attribute :release_source, :atom, public?: true

    # ── Cache bookkeeping ──────────────────────────────────────────────────
    # Not null on purpose, and for the same reason as on `CachedTitle`: a row
    # with no age cannot be evicted, and an un-evictable episode would put the
    # whole table outside TMDB's six-month ceiling.
    attribute :fetched_at, :utc_datetime_usec, allow_nil?: false, public?: true
    attribute :last_checked_at, :utc_datetime_usec, public?: true
    attribute :etag, :string, public?: true
    attribute :last_modified, :string, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :by_reference do
      description "The one episode matching a {source, source_id} pair, or nothing."
      get? true
      argument :source, :atom, allow_nil?: false
      argument :source_id, :string, allow_nil?: false
      filter expr(source == ^arg(:source) and source_id == ^arg(:source_id))
    end

    read :for_title do
      description "Every cached episode of one title, in aired order."
      argument :source, :atom, allow_nil?: false
      argument :title_source_id, :string, allow_nil?: false

      filter expr(source == ^arg(:source) and title_source_id == ^arg(:title_source_id))
      prepare build(sort: [season_number: :asc, episode_number: :asc])
    end

    read :for_season do
      description "One season's episodes, in aired order."
      argument :source, :atom, allow_nil?: false
      argument :title_source_id, :string, allow_nil?: false
      argument :season_number, :integer, allow_nil?: false

      filter expr(
               source == ^arg(:source) and
                 title_source_id == ^arg(:title_source_id) and
                 season_number == ^arg(:season_number)
             )

      prepare build(sort: [episode_number: :asc])
    end

    read :stale do
      description "Rows a source should be asked about again."
      argument :source, :atom, allow_nil?: false
      argument :before, :utc_datetime_usec, allow_nil?: false
      filter expr(source == ^arg(:source) and fetched_at < ^arg(:before))
    end
  end

  @typedoc """
  A numbering scheme an episode list can be drawn in.

  Two, not three. Screen 34 offers Aired, Absolute and DVD; `orders/0` answers
  with the two Kati's sources can actually fill. See the moduledoc for why DVD
  is not among them.
  """
  @type order :: :aired | :absolute

  @doc """
  Every order Kati can renumber a season into.

  Exposed as data rather than left to each screen so a control cannot offer a
  tile it has no numbers for — a segmented control whose third option changes
  nothing is a lie told in pixels.
  """
  @spec orders() :: [order()]
  def orders, do: [:aired, :absolute]

  @doc """
  One episode by the pair that identifies it, or `nil`.

  `nil` is an ordinary answer: an episode a tick names may have been evicted or
  never fetched, and the tick is still a fact about a night the user had.
  """
  @spec by_reference(atom(), String.t()) :: t() | nil
  def by_reference(source, source_id) do
    __MODULE__
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  @doc """
  Many episodes by their provider ids, keyed by `source_id`.

  **One query, never one per id.** `Kati.Screens.Library.shelf/0` is the pattern:
  a screen holding a list of ticks needs every episode they name in a fixed
  number of reads, and an id with no row is simply absent from the map rather
  than a `nil` entry the caller has to filter.
  """
  @spec by_source_ids(atom(), [String.t()]) :: %{optional(String.t()) => t()}
  def by_source_ids(_source, []), do: %{}

  def by_source_ids(source, source_ids) do
    ids = source_ids |> Enum.reject(&is_nil/1) |> Enum.uniq()

    if ids == [] do
      %{}
    else
      __MODULE__
      |> Ash.Query.filter(source == ^source and source_id in ^ids)
      |> Ash.read!()
      |> Map.new(&{&1.source_id, &1})
    end
  end

  @doc """
  The episodes a title's ticks name, keyed by `episode_source_id`.

  This is the join Kati deliberately does not have as a foreign key. A
  `Kati.Media.Watch` carries the provider's episode id and its tracked title
  carries the source, so the pair is `{tracked.source, watch.episode_source_id}`
  — pass the first and the ticks, and get back one map in one query.

  Whole-title watches (a film, a finished book) carry no episode id and are
  skipped rather than looked up.

      ticks = Ash.read!(Ash.Query.for_read(Watch, :episode_ticks, %{tracked_title_id: id}))
      episodes = CachedEpisode.for_ticks(tracked.source, ticks)
      Map.get(episodes, hd(ticks).episode_source_id)

  A tick whose episode has been evicted is a miss, and that is the point: the
  tick survives the wipe and the name comes back with the next fetch.
  """
  @spec for_ticks(atom(), [struct()]) :: %{optional(String.t()) => t()}
  def for_ticks(source, watches) when is_atom(source) and is_list(watches) do
    by_source_ids(source, Enum.map(watches, & &1.episode_source_id))
  end

  @doc """
  Every cached episode of one title, in aired order.

  A fixed one read. The list is what is *cached*, which is not necessarily what
  exists — a partially fetched season is short, and that is why the denominator
  a season's progress is drawn against belongs on `Kati.Media.CachedSeason`
  rather than being `length/1` of this.
  """
  @spec for_title(atom(), String.t()) :: [t()]
  def for_title(source, title_source_id) do
    __MODULE__
    |> Ash.Query.for_read(:for_title, %{source: source, title_source_id: title_source_id})
    |> Ash.read!()
  end

  @doc "One season's cached episodes, in aired order."
  @spec for_season(atom(), String.t(), integer()) :: [t()]
  def for_season(source, title_source_id, season_number) do
    __MODULE__
    |> Ash.Query.for_read(:for_season, %{
      source: source,
      title_source_id: title_source_id,
      season_number: season_number
    })
    |> Ash.read!()
  end

  @doc """
  A list of episodes renumbered into one of the orders `orders/0` names.

  `:aired` sorts by `{season_number, episode_number}`, which for every source
  Kati fetches from **is** broadcast order: TMDB's and TVmaze's season and
  episode numbers are the aired numbering by definition, and their alternate
  orders live elsewhere (see the moduledoc). Elixir's term ordering puts an
  integer before an atom, so an episode a source left unnumbered sorts to the
  end of the list rather than to the head of it.

  `:absolute` sorts by `absolute_number` and **drops the episodes that have
  none** — which is the design's own note, *"absolute order renumbers this
  season 27–35 and drops the special"*. An episode a source gave no absolute
  number to is not given one here; a number Kati invented is exactly the tick-
  losing renumbering screen 34 exists to warn about.
  """
  @spec in_order([t()], order()) :: [t()]
  def in_order(episodes, :aired) do
    Enum.sort_by(episodes, &{&1.season_number, &1.episode_number})
  end

  def in_order(episodes, :absolute) do
    episodes
    |> Enum.filter(&is_integer(&1.absolute_number))
    |> Enum.sort_by(& &1.absolute_number)
  end

  @doc """
  What one order calls this episode, or `nil` when that order cannot place it.

  `nil` rather than a fallback to the other scheme: a list that silently shows
  an aired number under an Absolute heading is a renumbering the user cannot
  see, and the caller is the only thing that knows whether to draw a gap or to
  leave the row out.
  """
  @spec number_in(t(), order()) :: integer() | nil
  def number_in(%__MODULE__{episode_number: n}, :aired), do: n
  def number_in(%__MODULE__{absolute_number: n}, :absolute), do: n

  @doc """
  The distinct season numbers this list of episodes covers, ascending.

  Derived from what is cached, so it under-reports a partly fetched title —
  `Kati.Media.CachedSeason.count/1` is the inventory to draw `3 SEASONS` from.
  Specials (season 0) are included here because they are seasons the list can
  be filtered by; `Kati.Media.CachedSeason.count/1` is the one that excludes
  them, because they are not what "3 seasons" means.
  """
  @spec seasons([t()]) :: [integer()]
  def seasons(episodes) do
    episodes
    |> Enum.map(& &1.season_number)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  The episode ids a set of watches has ticked.

  A `MapSet` rather than a list because the only question asked of it is
  membership, once per drawn row — screen 04 ticks by *existence of a row*, so
  unticking destroys and rewatching simply adds another and neither changes the
  answer here.
  """
  @spec ticked_ids([struct()]) :: MapSet.t(String.t())
  def ticked_ids(watches) do
    watches
    |> Enum.map(& &1.episode_source_id)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  @doc """
  Whether this episode is among the ticked ids.

  Keyed on `source_id` and never on `{season, episode}` — that is the bug
  `Kati.Media.Watch`'s moduledoc names outright, and the reason a renumbered
  season keeps its ticks.
  """
  @spec ticked?(t(), MapSet.t(String.t())) :: boolean()
  def ticked?(%__MODULE__{source_id: id}, ticked), do: MapSet.member?(ticked, id)

  @doc """
  How many of these episodes are ticked, and how many there are.

  The counter screen 04 draws as `5 of 7 watched`, derived at read time and
  never stored — the screen is explicit that storing it gives two places the
  chance to disagree, and the first tap is what makes them.

  The denominator here is the length of the list handed in, which is what the
  screen actually draws. A season whose provider says it has more episodes than
  are cached should be counted against `Kati.Media.CachedSeason.denominator/1`
  instead, and the caller is the one that knows which of the two it is showing.
  """
  @spec watched_of([t()], MapSet.t(String.t())) :: {non_neg_integer(), non_neg_integer()}
  def watched_of(episodes, ticked) do
    {Enum.count(episodes, &ticked?(&1, ticked)), length(episodes)}
  end
end
