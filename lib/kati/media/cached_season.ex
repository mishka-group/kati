defmodule Kati.Media.CachedSeason do
  @moduledoc """
  One season of a series, as a provider describes it. **Entirely evictable.**

  This is the inventory `Kati.Media.TrackedTitle.progress_season` has never had
  anything to count against. That column is a bare integer — a bookmark saying
  *the user is somewhere in season 2* — and until now there was nothing to say
  how many seasons exist, what they are called, or how long each one is.

  ## Why it is not derived from the episodes

  It would be tempting to answer "how many seasons" with
  `Kati.Media.CachedEpisode.seasons/1` and be done. That is right only when
  every episode of every season is cached, and it is wrong in exactly the way
  this codebase refuses to be wrong: a title whose S2 was fetched and whose S1
  and S3 were not would draw `1 SEASON` — a confident, specific, incorrect
  number, with nothing on the screen to hint that it is a fetch artefact rather
  than a fact.

  The same argument produces `episode_count` here. It is the provider's count
  for this season, and it is the honest denominator for `5 of 7 watched` when
  the cached episode list is short. It is nullable and `min: 1` for the reason
  `Kati.Media.CachedTitle`'s shelf denominators are: a source answering 0 is
  declining to say, and a zero denominator is a division by zero wearing a
  progress ring.

  ## How it is keyed

  Not by `{source, source_id}`, and that is deliberate rather than an omission.
  A season is identified by its title and its number — every source agrees on
  that, and it is the shape the durable half already holds: a tracked row has
  `{source, source_id}` and a `progress_season`, so the season that bookmark
  names is `{source, source_id, progress_season}`. The unique key is therefore
  `{source, title_source_id, season_number}`.

  `source_id` is kept as an ordinary nullable column for the sources that do
  give a season its own id (TMDB's `season.id`, TVmaze's `/seasons` entries).
  Making it the key would have meant synthesising one for the sources that do
  not, and an id Kati invented is an id no re-fetch can match.

  Nothing references a season by foreign key, and a season references nothing
  by foreign key. Evicting a title leaves its seasons; evicting the seasons
  leaves the title and every tick.

  ## The air date obeys #74

  A season has a release of its own — screen 05's `Nightbirds — Season 2 · Full
  season drop` is a season, not an episode — so `air_at` travels with its own
  `date_confidence` and is read only through `Kati.Media.Release.air/1` and
  `Kati.Media.Release.alarm_for/3`. A whole-season drop announced for "autumn"
  must not arm an alarm on 1 September.
  """
  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  require Ash.Query

  sqlite do
    table "cached_seasons"
    repo Kati.Repo

    custom_indexes do
      # The identity: a season is its title and its number.
      index [:source, :title_source_id, :season_number], unique: true
      # The eviction sweep and the staleness scan, as on cached_titles.
      index [:source, :fetched_at]
      # Screen 05's coming-up list, where a season drop is one of the rows.
      index [:air_at]
    end
  end

  attributes do
    uuid_primary_key :id

    # ── Identity ───────────────────────────────────────────────────────────
    # The same list as every other row in this domain, pinned equal by
    # `Kati.Media.EpisodeTest`.
    attribute :source, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [
        one_of: [:tmdb, :tvmaze, :anilist, :jikan, :openlibrary, :musicbrainz, :wikidata]
      ]

    # The provider's id for the title — `CachedTitle.source_id`. A value, not a
    # foreign key.
    attribute :title_source_id, :string, allow_nil?: false, public?: true

    # 0 is specials, where TMDB files them. Part of the key, so not null.
    attribute :season_number, :integer, allow_nil?: false, public?: true, constraints: [min: 0]

    # The provider's own id for this season, where it has one. Not the key —
    # see the moduledoc.
    attribute :source_id, :string, public?: true

    # ── Cached projection ──────────────────────────────────────────────────
    # The provider's name for the season: "Season 2", but also "Specials",
    # "Miniseries", "Part 1". Nullable, and no default is invented here — a
    # screen that wants "Season 2" out of a bare number is the thing that knows
    # what its own heading should read.
    attribute :name, :string, public?: true
    attribute :overview, :string, public?: true
    attribute :poster_path, :string, public?: true

    # The denominator, from the provider rather than from `length(episodes)`.
    # See the moduledoc, and `denominator/1` for the read-side guard.
    attribute :episode_count, :integer, public?: true, constraints: [min: 1]

    # ── When it lands (#74) ────────────────────────────────────────────────
    # Never read here; `Kati.Media.Release` is the only reader.
    attribute :air_at, :utc_datetime_usec, public?: true

    attribute :date_confidence, :atom,
      allow_nil?: false,
      default: :unknown,
      public?: true,
      constraints: [one_of: [:exact, :day, :month, :quarter, :year, :unknown]]

    attribute :release_source, :atom, public?: true

    # ── Cache bookkeeping ──────────────────────────────────────────────────
    # Not null: a row with no age cannot be evicted.
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
      description "The one season matching a {source, title_source_id, number} triple."
      get? true
      argument :source, :atom, allow_nil?: false
      argument :title_source_id, :string, allow_nil?: false
      argument :season_number, :integer, allow_nil?: false

      filter expr(
               source == ^arg(:source) and
                 title_source_id == ^arg(:title_source_id) and
                 season_number == ^arg(:season_number)
             )
    end

    read :for_title do
      description "Every cached season of one title, lowest number first."
      argument :source, :atom, allow_nil?: false
      argument :title_source_id, :string, allow_nil?: false

      filter expr(source == ^arg(:source) and title_source_id == ^arg(:title_source_id))
      prepare build(sort: [season_number: :asc])
    end

    read :stale do
      description "Rows a source should be asked about again."
      argument :source, :atom, allow_nil?: false
      argument :before, :utc_datetime_usec, allow_nil?: false
      filter expr(source == ^arg(:source) and fetched_at < ^arg(:before))
    end
  end

  @doc """
  Every cached season of one title, lowest number first.

  One read. Specials (season 0) sort to the front, where their number puts
  them; `numbered/1` is the filtered view for the places that are counting
  seasons rather than listing them.
  """
  @spec for_title(atom(), String.t()) :: [t()]
  def for_title(source, title_source_id) do
    __MODULE__
    |> Ash.Query.for_read(:for_title, %{source: source, title_source_id: title_source_id})
    |> Ash.read!()
  end

  @doc "One season by the triple that identifies it, or `nil`."
  @spec by_reference(atom(), String.t(), integer()) :: t() | nil
  def by_reference(source, title_source_id, season_number) do
    __MODULE__
    |> Ash.Query.filter(
      source == ^source and title_source_id == ^title_source_id and
        season_number == ^season_number
    )
    |> Ash.read_one!()
  end

  @doc """
  The seasons that count: everything but the specials.

  Season 0 is in the order and out of the count, which is the same thing screen
  34 says about a single special with its bronze number and its SPECIAL badge.
  """
  @spec numbered([t()]) :: [t()]
  def numbered(seasons), do: Enum.reject(seasons, &specials?/1)

  @doc "True for the specials shelf, which every source files as season 0."
  @spec specials?(t()) :: boolean()
  def specials?(%__MODULE__{season_number: 0}), do: true
  def specials?(%__MODULE__{}), do: false

  @doc """
  How many seasons a title has — screen 04's `3 SEASONS`.

  Specials excluded, because "3 seasons" has never meant "2 seasons and a
  making-of". `0` for a title whose seasons have not been fetched, which the
  caller must read as *nothing to say* rather than as *a series with no
  seasons*: this is a cache, and an empty cache is an absence.
  """
  @spec count([t()]) :: non_neg_integer()
  def count(seasons), do: seasons |> numbered() |> length()

  @doc """
  The total this season's progress is measured against, or `nil`.

  The provider's `episode_count`, guarded the way
  `Kati.Media.CachedTitle.denominator/1` guards the shelf denominators: `nil`
  for an evicted or unfetched season, and `nil` for a stored zero, because a
  count of zero is a source declining to answer and honouring it as a
  denominator is the `5 of 0` this whole split exists to prevent.

  `nil` degrades to a bare count — `5 watched` with no ring — exactly as an
  unknown page count degrades to `p.214`.
  """
  @spec denominator(t() | nil) :: pos_integer() | nil
  def denominator(nil), do: nil
  def denominator(%__MODULE__{episode_count: n}) when is_integer(n) and n > 0, do: n
  def denominator(%__MODULE__{}), do: nil
end
