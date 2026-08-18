defmodule Kati.Calendars.Account do
  @moduledoc """
  A source of calendars: the Android provider, a CalDAV principal, or Kati
  itself.

  `credentials_ref` is an opaque key into the keystore (#55) and is **never a
  secret**. The `CalendarContract` route stores no credentials at all, which is
  a large part of why #52 chose it.
  """
  use Ash.Resource, domain: Kati.Calendars, data_layer: AshSqlite.DataLayer

  sqlite do
    table "calendar_accounts"
    repo Kati.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :provider, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:local, :android_provider, :caldav, :google, :graph]]

    attribute :account_name, :string, public?: true
    attribute :account_type, :string, public?: true
    attribute :display_name, :string, public?: true

    # An opaque handle, never the credential itself.
    attribute :credentials_ref, :string, public?: true

    # Screen 32 draws Live and Stale badges from this.
    attribute :state, :atom,
      allow_nil?: false,
      default: :live,
      public?: true,
      constraints: [one_of: [:live, :stale, :error, :disconnected]]

    attribute :last_sync_at, :utc_datetime_usec, public?: true

    # Frozen at connect time: Google invalidates a syncToken if timeMin changes
    # between requests, so the window cannot drift with the UI.
    attribute :sync_window_from, :utc_datetime_usec, public?: true
    attribute :sync_window_to, :utc_datetime_usec, public?: true

    timestamps()
  end

  relationships do
    has_many :calendars, Kati.Calendars.Calendar
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*
  end
end
