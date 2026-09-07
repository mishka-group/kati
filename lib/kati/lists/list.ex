defmodule Kati.Lists.List do
  @moduledoc """
  One hand-made list.

  Board 12 draws a name, a count, and one of two badges. `ranked` and `shared`
  are the badges, and they are a list's own state rather than a property of
  anything in it — which is why they are columns here and not derived.

  `name` is unique, case-folded through the same `Kati.Import.Job.name_key/1`
  every other name comparison in this app uses: two lists called `Rainy Sunday`
  are one list somebody made twice, and the screen that creates them says so
  rather than making a second.
  """
  use Ash.Resource, domain: Kati.Lists, data_layer: AshSqlite.DataLayer

  sqlite do
    table "lists"
    repo Kati.Repo

    custom_indexes do
      # The screen's own order: newest first.
      index [:inserted_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true

    # The key `name` is compared on — trimmed and case-folded. Stored rather
    # than computed so SQLite can hold the unique index on it.
    attribute :name_key, :string, allow_nil?: false, public?: true

    # The board's two badges. Both default false: a list is a list until
    # somebody says otherwise.
    attribute :ranked, :boolean, allow_nil?: false, default: false, public?: true
    attribute :shared, :boolean, allow_nil?: false, default: false, public?: true

    timestamps()
  end

  identities do
    identity :unique_name, [:name_key]
  end

  relationships do
    has_many :memberships, Kati.Lists.Membership
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :newest_first do
      description "Every list, newest first — the order screen 12 draws."
      prepare build(sort: [inserted_at: :desc])
    end
  end
end
