defmodule Kati.Calendars.Event do
  @moduledoc """
  The master event row.

  ## Why the timing columns look redundant and are not

    * `dtstart_utc` is the **range-query key** and nothing else.
    * `dtstart_wall` is the **authored** wall clock, kept as `"YYYYMMDDTHHMMSS"`.
      Storing only UTC makes a recurring 09:00 meeting drift to 10:00 across a
      DST boundary, because the rule must expand in wall clock (#47).
    * `dtstart_date` replaces both when `is_all_day`. An all-day event is
      date-valued, never a midnight instant — otherwise it shifts a day when the
      user flies to Tehran.
    * `tzid` of `nil` means **floating**: "09:00 wherever you are", which is the
      correct model for habits and meal slots, not a missing value.

  `duration_iso` is canonical, not `dtend_utc`. RFC 5545 permits either, Android
  *requires* `DURATION` for recurring events, and a one-hour event crossing
  spring-forward is one hour by `DURATION` and two by wall-clock `DTEND`.
  `dtend_utc` is a derived cache for range queries on non-recurring events and is
  recomputed on every write.

  `recurs_until_utc` is the last instant this event can contribute, computed at
  write time. `nil` means unbounded. Without it, a range query has to expand
  every recurring master in the database just to discover one ended in 2019.

  ## Lossless round-tripping

  `raw_icalendar` keeps the exact bytes the server sent, and `unknown_props`
  keeps parsed-but-unmodelled properties as JSON text. Dropping either on
  write-back is silent data loss for the other client that wrote them. `transp`
  is modelled from day one for the same reason, even though nothing reads it yet.

  ## Sync bookkeeping

  `local_rev > synced_rev` means dirty. That beats a boolean because it survives
  an edit landing while a push of the previous version is still in flight.

  Rows are **never hard-deleted** once synced; `deleted_at` is a tombstone, kept
  90 days and never collected while an outbox entry still references it.
  """
  use Ash.Resource, domain: Kati.Calendars, data_layer: AshSqlite.DataLayer

  sqlite do
    table "events"
    repo Kati.Repo

    custom_indexes do
      # The natural identity: one UID family per calendar.
      index [:calendar_id, :uid], unique: true
      # The events_in_range/2 path.
      index [:calendar_id, :deleted_at, :dtstart_utc]
      # Prunes expired recurring masters before expansion.
      index [:calendar_id, :recurs_until_utc]
      # The section filter chips on screen 02.
      index [:kind, :dtstart_utc]
      index [:remote_id]
      index [:remote_href]
      index [:sync_state]
    end
  end

  attributes do
    uuid_primary_key :id

    # ── Identity ───────────────────────────────────────────────────────────
    attribute :uid, :string, allow_nil?: false, public?: true

    # Immutable after creation — enforced by a change, not a comment.
    attribute :origin, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:kati, :mirror]]

    # ── Parsed, queryable projection ───────────────────────────────────────
    attribute :summary, :string, public?: true
    attribute :location, :string, public?: true
    attribute :description, :string, public?: true

    attribute :dtstart_utc, :utc_datetime_usec, public?: true
    attribute :dtstart_wall, :string, public?: true
    attribute :dtstart_date, :date, public?: true
    attribute :tzid, :string, public?: true

    # K-22 fixes this value set; :device is the placeholder for "follows travel".
    attribute :tz_behaviour, :atom,
      allow_nil?: false,
      default: :fixed,
      public?: true,
      constraints: [one_of: [:fixed, :floating, :device]]

    attribute :is_all_day, :boolean, allow_nil?: false, default: false, public?: true
    attribute :duration_iso, :string, public?: true
    attribute :dtend_utc, :utc_datetime_usec, public?: true
    attribute :rrule, :string, public?: true
    attribute :recurs_until_utc, :utc_datetime_usec, public?: true

    attribute :kind, :atom,
      allow_nil?: false,
      default: :event,
      public?: true,
      constraints: [one_of: [:event, :reminder, :habit, :meal, :air_date, :money, :note]]

    attribute :status, :atom,
      public?: true,
      constraints: [one_of: [:tentative, :confirmed, :cancelled]]

    attribute :transp, :atom,
      public?: true,
      constraints: [one_of: [:opaque, :transparent]]

    attribute :sequence, :integer, allow_nil?: false, default: 0, public?: true
    attribute :organizer, :string, public?: true
    attribute :last_modified_utc, :utc_datetime_usec, public?: true
    attribute :created_utc, :utc_datetime_usec, public?: true

    # ── Lossless ───────────────────────────────────────────────────────────
    attribute :raw_icalendar, :string, public?: true
    # JSON text, not a map: SQLite has no JSONB indexes.
    attribute :unknown_props, :string, public?: true

    # ── Sync bookkeeping ───────────────────────────────────────────────────
    attribute :local_rev, :integer, allow_nil?: false, default: 1, public?: true
    attribute :synced_rev, :integer, allow_nil?: false, default: 0, public?: true
    attribute :remote_id, :string, public?: true
    attribute :remote_href, :string, public?: true
    attribute :remote_etag, :string, public?: true
    attribute :deleted_at, :utc_datetime_usec, public?: true

    attribute :sync_state, :atom,
      allow_nil?: false,
      default: :local_only,
      public?: true,
      constraints: [one_of: [:local_only, :clean, :dirty, :conflicted, :push_failed]]

    timestamps()
  end

  relationships do
    belongs_to :calendar, Kati.Calendars.Calendar,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true

    has_many :overrides, Kati.Calendars.Override
  end

  actions do
    defaults [:read, :destroy]
    default_accept :*

    create :create do
      primary? true
      accept :*
      change Kati.Calendars.Changes.DeriveTiming
    end

    update :update do
      primary? true
      require_atomic? false
      accept :*
      # origin is deliberately absent from the accept list below via the change.
      change Kati.Calendars.Changes.RejectOriginChange
      change Kati.Calendars.Changes.DeriveTiming
      change Kati.Calendars.Changes.BumpLocalRev
    end

    # A tombstone, not a delete. A synced row that vanishes cannot be told apart
    # from one that never existed, and the other end would resurrect it.
    update :soft_delete do
      require_atomic? false
      accept []
      change set_attribute(:deleted_at, &DateTime.utc_now/0)
      change Kati.Calendars.Changes.BumpLocalRev
    end
  end
end
