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

  ## The shelf denominators

  `episode_count`, `page_count` and `track_count` are here for the same reason,
  and they are here rather than on `Kati.Media.TrackedTitle` because
  `Kati.Media.CachePolicy`'s test decides it: *would the user lose something they
  created?* Nobody authored "380 pages" — a provider did, and a re-fetch says it
  again — so the denominator is cache even though it is the shelves that need
  it. `TrackedTitle` stores `progress_page` without its total for exactly that
  reason, and screens 03 and 20 draw "p.214/380" by putting the two halves back
  together at render time.

  That join can fail, and it must fail *visibly rather than falsely*. A cache row
  can be evicted, a provider can decline to say how long a book is, and a series
  that has not aired yet has no episode count to give. So `denominator/1` answers
  `nil` in all three cases and `progress/2` degrades to a bare position — "p.214"
  with no ring — instead of inventing a total. Zero is treated as an absence
  everywhere for the same reason: a zero denominator is not "0% read", it is a
  division by zero wearing a progress ring.
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
      # `:manual` is a title someone typed in, with no provider behind it.
      #
      # Every other member of this list is a place a row can be looked up
      # again; `:manual` is the one that cannot, and that is the point. #60
      # ships film and TV in v1, and until a provider client exists the only
      # way a title enters Kati at all is by hand. A row with no source would
      # have been the alternative, and `allow_nil?: false` here is load-bearing
      # — a title that belongs to nothing cannot be reconciled with a provider
      # row later, when there is one to reconcile against.
      constraints: [
        one_of: [:manual, :tmdb, :tvmaze, :anilist, :jikan, :openlibrary, :musicbrainz, :wikidata]
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

    # ── Shelf denominators ─────────────────────────────────────────────────
    # The totals screens 03 and 20 divide a stored position by. All three are
    # nullable, and `min: 1` is deliberate: a source that answers 0 is saying it
    # does not know yet, and the fetch layer must normalise that to nil rather
    # than store a number a progress ring would divide by. `denominator/1`
    # guards the read side as well, for rows that never met a changeset.

    # Whole-series episode totals: TMDB `number_of_episodes`, TVmaze's episode
    # list length, AniList `Media.episodes`, Jikan `anime.episodes`. Null is the
    # normal answer for a currently-airing show — AniList returns it outright —
    # and for a series announced but not yet scheduled.
    attribute :episode_count, :integer, public?: true, constraints: [min: 1]

    # Open Library's edition-level `number_of_pages`, or Wikidata P1104. Null at
    # the work level (a work has no pages, its editions do) and for an ebook
    # with no fixed pagination.
    attribute :page_count, :integer, public?: true, constraints: [min: 1]

    # MusicBrainz release: `media[].track-count` summed across discs, so a
    # double album counts through rather than restarting. Null for a
    # release-group, which has no tracks of its own.
    attribute :track_count, :integer, public?: true, constraints: [min: 1]

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

  @typedoc """
  How much of a title is done, at the precision actually known.

    * `{:fraction, done, total}` — a ring and a "214/380" label.
    * `{:position, done}` — the position is known and the total is not. Screens
      print it alone; there is no ring, because there is nothing to be a
      fraction *of*.
    * `:unknown` — neither half is known.

  The coarse cases carry no total at all, for the same reason
  `Kati.Media.Release` returns a period rather than a day for a low-confidence
  date: a caller cannot accidentally divide by something that is not there.
  """
  @type progress ::
          {:fraction, non_neg_integer(), pos_integer()}
          | {:position, pos_integer()}
          | :unknown

  @doc """
  The total this title's progress is measured against, or `nil`.

  Chosen by `kind`, because each kind counts in its own unit and the position it
  is divided into is stored in that same unit on `Kati.Media.TrackedTitle`:

    * `:tv` and `:anime` → `episode_count`. The numerator is the count of
      `Kati.Media.Watch` ticks, not `progress_episode` — screen 04 is explicit
      that the counter is derived, and `progress_episode` is a bookmark inside a
      season rather than a total across the series.
    * `:book` → `page_count`, against `progress_page`.
    * `:album` → `track_count`, against `progress_track`.
    * `:movie` → `nil`. A film's position is `progress_seconds` and the only
      total it could divide is `runtime_minutes`, which is a different unit.
      Screen 10's "18M LEFT" does that ×60 where the units are visible rather
      than having this function hide it, and a film's shelf state is watched or
      not, not a partial ring.

  `nil` for an evicted or unfetched row, and `nil` for a stored zero: a count of
  zero is a source declining to answer, and honouring it as a denominator is the
  "p.214/0" this whole split exists to prevent.
  """
  @spec denominator(t() | nil) :: pos_integer() | nil
  def denominator(nil), do: nil
  def denominator(%__MODULE__{kind: :tv} = cached), do: positive(cached.episode_count)
  def denominator(%__MODULE__{kind: :anime} = cached), do: positive(cached.episode_count)
  def denominator(%__MODULE__{kind: :book} = cached), do: positive(cached.page_count)
  def denominator(%__MODULE__{kind: :album} = cached), do: positive(cached.track_count)
  # :movie, and any kind a later migration adds. Answering nil degrades to a
  # bare position, which is always drawable; guessing does not.
  def denominator(%__MODULE__{}), do: nil

  @doc """
  A title's progress, given the position held on the user's tracking row.

  `cached` may be `nil` — that is the evicted case, and it is the whole point:
  the position survives the wipe and still renders, without its total.

  The numerator is passed in rather than read off the cache row because it is
  the durable half and this module never touches it. See `denominator/1` for
  which position belongs to which kind.

      progress(book, 214)     #=> {:fraction, 214, 380}
      progress(book, nil)     #=> {:fraction, 0, 380}   — an empty ring
      progress(nil, 214)      #=> {:position, 214}      — evicted, still honest
      progress(unpaged, 214)  #=> {:position, 214}
      progress(nil, nil)      #=> :unknown

  A position past the total is reported as given — a stale cache should not
  quietly rewrite where the user says they are — and it is `ratio/1` that clamps
  so the ring cannot overflow.
  """
  @spec progress(t() | nil, integer() | nil) :: progress()
  def progress(cached, position) do
    case {denominator(cached), positive(position)} do
      {nil, nil} -> :unknown
      {nil, done} -> {:position, done}
      {total, nil} -> {:fraction, 0, total}
      {total, done} -> {:fraction, done, total}
    end
  end

  @doc """
  The `0.0..1.0` a progress ring sweeps, or `nil` when there is nothing to sweep.

  `nil` rather than `0.0` for the unknown cases on purpose: an empty ring and no
  ring are different statements, and only the caller knows which to draw.
  """
  @spec ratio(progress()) :: float() | nil
  def ratio({:fraction, done, total}) when total > 0, do: min(done / total, 1.0)
  def ratio(_progress), do: nil

  # Zero and negatives are absences, not counts. See the moduledoc.
  defp positive(n) when is_integer(n) and n > 0, do: n
  defp positive(_other), do: nil
end
