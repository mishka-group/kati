defmodule Kati.Calendars.Override do
  @moduledoc """
  One instance of a recurring event, modified or cancelled.

  This is not optional and cannot be retrofitted: "edit this occurrence" is the
  single most common calendar interaction, and without a place to put it the
  only options are to edit the whole series or to lose the edit.

  A `nil` projection column means **inherit from the master**, which is why every
  one of them is nullable here even where it is required on `events`.

  `event_uid` and `calendar_id` are denormalised deliberately: one `UID` family
  is one CalDAV resource, and the patch path needs the family without a join.

  An override is its own row in `CalendarContract.Events` (with `ORIGINAL_ID`),
  so it carries its own sync bookkeeping even though it shares a CalDAV resource
  with its master.
  """
  use Ash.Resource, domain: Kati.Calendars, data_layer: AshSqlite.DataLayer

  sqlite do
    table "event_occurrence_overrides"
    repo Kati.Repo

    custom_indexes do
      index [:event_id, :recurrence_id_utc], unique: true
      index [:calendar_id, :event_uid]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :event_uid, :string, allow_nil?: false, public?: true

    # The ORIGINAL start of the overridden instance, not the new one.
    attribute :recurrence_id_utc, :utc_datetime_usec, allow_nil?: false, public?: true
    attribute :recurrence_id_wall, :string, allow_nil?: false, public?: true
    attribute :recurrence_id_is_date, :boolean, allow_nil?: false, default: false, public?: true

    # Kati never generates RANGE=THISANDFUTURE — §3.4 says the interop technique
    # is to split the series — but must tolerate reading one.
    attribute :range_this_and_future, :boolean, allow_nil?: false, default: false, public?: true

    attribute :kind, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:modified, :cancelled]]

    # nil means inherit from the master.
    attribute :summary, :string, public?: true
    attribute :location, :string, public?: true
    attribute :description, :string, public?: true
    attribute :dtstart_utc, :utc_datetime_usec, public?: true
    attribute :dtstart_wall, :string, public?: true
    attribute :dtstart_date, :date, public?: true
    attribute :tzid, :string, public?: true
    attribute :tz_behaviour, :atom, public?: true
    attribute :is_all_day, :boolean, public?: true
    attribute :duration_iso, :string, public?: true
    attribute :dtend_utc, :utc_datetime_usec, public?: true
    attribute :status, :atom, public?: true
    attribute :transp, :atom, public?: true
    attribute :sequence, :integer, public?: true

    attribute :raw_icalendar, :string, public?: true
    attribute :unknown_props, :string, public?: true

    attribute :local_rev, :integer, allow_nil?: false, default: 1, public?: true
    attribute :synced_rev, :integer, allow_nil?: false, default: 0, public?: true
    attribute :remote_id, :string, public?: true
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
    belongs_to :event, Kati.Calendars.Event,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true

    belongs_to :calendar, Kati.Calendars.Calendar,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*
  end
end
