defmodule Kati.Sync.RejectedChange do
  @moduledoc """
  The edit that lost, kept so it can be re-applied.

  This table is the difference between a conflict policy and a data-loss bug.
  When `Kati.Sync.Merge` cannot merge two changes it names a winner — from
  ownership, never from a clock — and the loser's property values land here
  with the base they were a change from. Nothing is discarded, so "remote wins"
  means *the remote is what is on the calendar now, and here is what you typed,
  one tap away* rather than *your edit is gone*.

  The `base_properties` column is what makes re-applying meaningful rather than
  a blind overwrite: it records what the property was **before** the losing
  edit, so re-applying can be offered as a three-way merge again instead of
  clobbering whatever the winner put there.

  A `side` of `:remote` is not a mistake. When `origin: :kati` and the two
  sides overlap, Kati wins — but the remote change was also the user, making an
  edit in Google Calendar's web UI. Discarding that silently is the same
  failure with the roles swapped, so it is preserved by exactly the same
  mechanism.
  """
  use Ash.Resource, domain: Kati.Sync, data_layer: AshSqlite.DataLayer

  sqlite do
    table "sync_rejected_changes"
    repo Kati.Repo

    custom_indexes do
      index [:calendar_id, :event_uid]
      index [:applied_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :calendar_id, :uuid, allow_nil?: false, public?: true
    attribute :event_uid, :string, allow_nil?: false, public?: true

    attribute :side, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:local, :remote]]

    attribute :reason, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:ownership_kati, :ownership_mirror, :delete_edit, :user_choice]]

    # JSON text: property name to its content lines, or null for "removed".
    attribute :properties, :string, allow_nil?: false, public?: true
    attribute :base_properties, :string, allow_nil?: false, default: "{}", public?: true

    attribute :applied_at, :utc_datetime_usec, public?: true
    attribute :dismissed_at, :utc_datetime_usec, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*
  end
end
