defmodule Kati.Spike.Thing do
  @moduledoc """
  Spike resource carrying the two types Kati cannot compromise on.

  `:decimal` backs the money ledger and `:utc_datetime_usec` backs every
  calendar timestamp. `ecto_sqlite3` stores decimals as text/numeric, and
  SQLite has no native datetime type, so decimal-to-float coercion and
  microsecond truncation are the two failure modes worth proving absent —
  with exact equality, not approximate.
  """
  use Ash.Resource,
    domain: Kati.Spike,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("spike_things")
    repo(Kati.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:label, :string, allow_nil?: false, public?: true)
    attribute(:amount, :decimal, allow_nil?: false, public?: true)
    attribute(:occurred_at, :utc_datetime_usec, allow_nil?: false, public?: true)
    # Added in a second migration to prove an upgrade applies over existing
    # user data rather than silently starting from a fresh database
    # (#30, criterion 4).
    attribute(:note, :string, public?: true)
    attribute(:source, :string, public?: true)
    attribute(:upgrade_probe, :string, public?: true)
    create_timestamp(:inserted_at)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:label, :amount, :occurred_at, :note, :source])
    end
  end
end
