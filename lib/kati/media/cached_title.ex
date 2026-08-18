defmodule Kati.Media.CachedTitle do
  @moduledoc """
  Third-party metadata for one title. **Entirely evictable.**

  Nothing the user created lives here — that belongs on their own tracking rows,
  which reference a title by `{source, source_id}` and survive a cache wipe
  intact. The split is what makes eviction safe, and it is why `fetched_at` is
  `allow_nil?: false` rather than a nicety: a row with no age cannot be evicted
  and would quietly break TMDB's six-month ceiling.

  `external_ids` and `date_confidence` come from #74 and are here because they
  must exist in the first migration: retrofitting either across a media schema
  over live user data is exactly the migration to avoid.
  """
  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  sqlite do
    table "cached_titles"
    repo Kati.Repo

    custom_indexes do
      index [:source, :source_id], unique: true
      # The eviction sweep and the staleness scan.
      index [:source, :fetched_at]
      index [:next_release_at]
      index [:kind]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :source, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [
        one_of: [:tmdb, :tvmaze, :anilist, :jikan, :openlibrary, :musicbrainz, :wikidata]
      ]

    attribute :source_id, :string, allow_nil?: false, public?: true

    attribute :kind, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:movie, :tv, :anime, :book, :album]]

    # ── Cached projection ──────────────────────────────────────────────────
    attribute :title, :string, public?: true
    attribute :title_original, :string, public?: true
    attribute :overview, :string, public?: true
    attribute :poster_path, :string, public?: true
    attribute :backdrop_path, :string, public?: true
    attribute :runtime_minutes, :integer, public?: true
    attribute :genres, :string, public?: true

    # ── Release timing (#74) ───────────────────────────────────────────────
    attribute :next_release_at, :utc_datetime_usec, public?: true

    # Only :exact and :day may arm an alarm. A source that gives a bare year
    # must never become "1 January" and fire a confidently wrong notification.
    attribute :date_confidence, :atom,
      allow_nil?: false,
      default: :unknown,
      public?: true,
      constraints: [one_of: [:exact, :day, :month, :quarter, :year, :unknown]]

    # Which source produced next_release_at — needed to resolve disagreements,
    # since TVmaze's airstamp is an instant and TMDB's air_date is a bare date.
    attribute :release_source, :atom, public?: true

    # ── Cross-service identity (#74) ───────────────────────────────────────
    # Discrete columns rather than a JSON map: SQLite has no JSONB indexes, and
    # reconciliation looks these up by value.
    attribute :tmdb_id, :string, public?: true
    attribute :imdb_id, :string, public?: true
    attribute :tvmaze_id, :string, public?: true
    attribute :anilist_id, :string, public?: true
    attribute :mal_id, :string, public?: true
    attribute :tvdb_id, :string, public?: true

    # ── Cache bookkeeping ──────────────────────────────────────────────────
    # Not null on purpose: a row with no age cannot be evicted.
    attribute :fetched_at, :utc_datetime_usec, allow_nil?: false, public?: true
    attribute :last_checked_at, :utc_datetime_usec, public?: true
    attribute :etag, :string, public?: true
    attribute :last_modified, :string, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :stale do
      argument :source, :atom, allow_nil?: false
      argument :before, :utc_datetime_usec, allow_nil?: false
      filter expr(source == ^arg(:source) and fetched_at < ^arg(:before))
    end
  end
end
