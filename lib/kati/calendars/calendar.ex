defmodule Kati.Calendars.Calendar do
  @moduledoc """
  One calendar within an account, or a purely local Kati calendar.

  Two columns worth explaining:

    * `colour_source` keeps the provider's own value **verbatim** — CalDAV
      `apple:calendar-color`, Google `colorId`, Android `CALENDAR_COLOR` — and is
      never rendered. `colour_token` is the Kati palette slot it maps to.
      Rendering foreign hex directly would break a locked design system.
    * `sync_cursor` is **opaque**. RFC 6578 is explicit that a sync token
      *"MUST be treated as an 'opaque' string by the client"*, so nothing may
      parse or compare it beyond equality.
  """
  use Ash.Resource, domain: Kati.Calendars, data_layer: AshSqlite.DataLayer

  sqlite do
    table "calendars"
    repo Kati.Repo

    custom_indexes do
      index [:account_id, :remote_id], unique: true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :remote_id, :string, public?: true
    attribute :display_name, :string, public?: true
    attribute :colour_source, :string, public?: true
    attribute :colour_token, :atom, public?: true

    attribute :kind, :atom,
      allow_nil?: false,
      default: :local,
      public?: true,
      constraints: [one_of: [:local, :provider]]

    attribute :read_only, :boolean, allow_nil?: false, default: false, public?: true
    attribute :visible, :boolean, allow_nil?: false, default: true, public?: true

    # Screen 32's privacy promise: by default Kati writes back only the events
    # it created, never a mirrored one.
    attribute :writeback_policy, :atom,
      allow_nil?: false,
      default: :kati_only,
      public?: true,
      constraints: [one_of: [:none, :kati_only, :full]]

    attribute :sync_cursor, :string, public?: true
    attribute :last_sync_at, :utc_datetime_usec, public?: true

    timestamps()
  end

  relationships do
    belongs_to :account, Kati.Calendars.Account,
      allow_nil?: true,
      attribute_writable?: true,
      attribute_public?: true

    has_many :events, Kati.Calendars.Event
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*
  end
end
