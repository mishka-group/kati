defmodule Kati.Media.TrackedTitle do
  @moduledoc """
  One title the user follows. **Never evicted.**

  This is the other half of the split `Kati.Media.CachedTitle` describes: the
  cache holds what a provider said, this holds what the user did. It points at
  a title by `{source, source_id}` — a *value*, not a foreign key — so a cache
  wipe deletes the poster and the synopsis and leaves the status, the position,
  the rating and the watch history exactly where they were. A `belongs_to` would
  make eviction either impossible or destructive; there is no third option, which
  is why the reference is a pair of columns and `by_reference` is an action
  rather than a join.

  ## What lives here and what does not

  `Kati.Media.CachePolicy`'s test — *would the user lose something they created?*
  — decides every column. Position, status, rating, the per-show switches and
  `user_override_date` pass it. Episode counts, page counts and track counts do
  **not**: nobody authored "380 pages", so a denominator belongs on the cache
  row even though the shelves need one to draw a ring. `progress_page` is stored
  without its total for exactly that reason.

  ## `user_override_date` — #74's rule, and why it is on this row

  A date the user typed **must win over every source**. Put it on the cache and
  the next eviction sweep silently discards a correction the user made by hand,
  and the app goes back to being confidently wrong about the thing they already
  fixed. So it lives here, beside the status it belongs to, and
  `Kati.Media.Release` is the only place that decides what beats what.

  ## Statuses

  Five, and they are one vocabulary across film, television, books and records
  — a book being read is `:watching`, which reads oddly and is still better than
  a second column that means the same thing. Screen 35 makes `:watching`,
  `:paused` and `:dropped` first-class peers rather than a swipe action; screens
  03 and 20 add `:not_started` and `:finished` as shelf filters.

  `archived` is deliberately **not** a status. Screen 35 offers it beside reset
  and remove — "keeps history, hides from shelf" — because it is a thing done to
  a show, not a thing the show is.

  ## Ratings

  Stored on the ten-point scale as an integer 1..10, which is also the five-star
  scale with half stars: screen 33's `4.5` is `9`. One column rather than a float
  and a scale flag, because the scale is a display preference and a half star is
  not a rounding error. This is the rating that stands **now**; what the user
  thought on a particular night is on that night's `Kati.Media.Watch`.

  `last_touched_at` is what the shelves sort by, and it is forced on every write
  by `Kati.Media.Changes.Touch` rather than left to callers — a shelf ordered by
  a field that some write paths remember to set is a shelf that reorders at
  random.
  """
  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  sqlite do
    table "tracked_titles"
    repo Kati.Repo

    custom_indexes do
      # The reference into the cache. One tracked row per title, per source.
      index [:source, :source_id], unique: true
      # The shelf query on screens 03, 20 and 21: a section, newest first.
      index [:kind, :archived, :last_touched_at]
      # The filter chips.
      index [:status, :last_touched_at]
      # The release watcher's scan for hand-corrected dates.
      index [:user_override_date]
    end
  end

  attributes do
    uuid_primary_key :id

    # ── The reference into the cache ───────────────────────────────────────
    # Deliberately the same value sets as CachedTitle's, held as literals in
    # both places and pinned equal by a test: a tracked row that names a source
    # the cache cannot hold can never be filled in.
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

    # ── What the user decided ──────────────────────────────────────────────
    attribute :status, :atom,
      allow_nil?: false,
      default: :not_started,
      public?: true,
      constraints: [one_of: [:not_started, :watching, :paused, :finished, :dropped]]

    # Screen 35: keeps history, hides from shelf. Not a status — see moduledoc.
    attribute :archived, :boolean, allow_nil?: false, default: false, public?: true

    # ── Where the user is ──────────────────────────────────────────────────
    # A position, never a fraction: the denominator is metadata and lives on the
    # cache row. For a series the *authority* on how much is watched is the set
    # of `Kati.Media.Watch` ticks — screen 04 is explicit that the counter is
    # derived and never stored, because two places that both know "5 of 7" will
    # eventually disagree. These two are the bookmark, not the count.
    attribute :progress_season, :integer, public?: true
    attribute :progress_episode, :integer, public?: true

    attribute :progress_page, :integer, public?: true
    attribute :progress_track, :integer, public?: true

    # Position inside the current episode, film or track. Nothing writes it yet;
    # screen 10 prints "18M LEFT", which cannot be derived from a runtime alone,
    # and there is nowhere else for a resume point to live.
    attribute :progress_seconds, :integer, public?: true

    # ── What the user thought ──────────────────────────────────────────────
    attribute :rating, :integer, public?: true, constraints: [min: 1, max: 10]

    # ── The date the user asserts, which beats every source (#74) ──────────
    # A date, not an instant: this is someone typing "it's out on the third",
    # and inventing an hour to go with it is the same class of lie as inventing
    # 1 January for a bare year.
    attribute :user_override_date, :date, public?: true

    # ── Per-show switches (screen 35) ──────────────────────────────────────
    # `notify_new_episodes` is read by `Kati.Media.Release.alarm_at/3`: a muted
    # show suppresses its alarm at the same gate that low confidence does, so a
    # scheduler cannot honour one rule and forget the other.
    attribute :notify_new_episodes, :boolean, allow_nil?: false, default: true, public?: true

    attribute :auto_add_new_seasons, :boolean, allow_nil?: false, default: true, public?: true

    attribute :add_air_dates_to_calendar, :boolean,
      allow_nil?: false,
      default: true,
      public?: true

    # Spoiler-safe episode names on screen 04.
    attribute :hide_unwatched_titles, :boolean, allow_nil?: false, default: false, public?: true

    # ── Shelf order ────────────────────────────────────────────────────────
    attribute :last_touched_at, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0,
      public?: true

    timestamps()
  end

  relationships do
    has_many :watches, Kati.Media.Watch
  end

  actions do
    defaults [:read, :destroy]
    default_accept :*

    create :create do
      primary? true
      accept :*
      change Kati.Media.Changes.Touch
    end

    update :update do
      primary? true
      require_atomic? false
      accept :*
      change Kati.Media.Changes.Touch
    end

    # Bumping the shelf without claiming anything else changed.
    update :touch do
      require_atomic? false
      accept []
      change Kati.Media.Changes.Touch
    end

    # The join that deliberately is not one — screen 06 asks "is this already in
    # the library?" of a search result that only carries provider ids.
    read :by_reference do
      description "The one title matching a {source, source_id} pair, or nothing."
      get? true
      argument :source, :atom, allow_nil?: false
      argument :source_id, :string, allow_nil?: false
      filter expr(source == ^arg(:source) and source_id == ^arg(:source_id))
    end

    # Archived rows are excluded here rather than by the caller: "hides from
    # shelf" is the whole meaning of the flag.
    read :shelf do
      description "One shelf section, newest touch first."
      argument :kind, :atom, allow_nil?: false
      filter expr(archived == false and kind == ^arg(:kind))
      prepare build(sort: [last_touched_at: :desc])
    end

    # Finished and dropped titles are excluded: an announcement about a show the
    # user abandoned is noise, and the watcher's cost is one request per row.
    read :followed do
      description "The titles the release watcher has any business looking at."
      filter expr(archived == false and status in [:not_started, :watching, :paused])
    end
  end
end
