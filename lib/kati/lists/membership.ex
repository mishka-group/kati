defmodule Kati.Lists.Membership do
  @moduledoc """
  One title in one list.

  `position` is what makes a ranked list ranked, and it is kept on every list
  rather than only on ranked ones: a list that becomes ranked should not have
  to invent an order it never recorded, and the order titles were added in is
  the honest default.

  Unique on `{list_id, tracked_title_id}` — adding a title twice is how
  somebody checks whether it is already in, which is `Kati.Screens.AddTitle.
  cache/1`'s reasoning and holds here too.
  """
  use Ash.Resource, domain: Kati.Lists, data_layer: AshSqlite.DataLayer

  sqlite do
    table "list_memberships"
    repo Kati.Repo

    custom_indexes do
      index [:list_id, :position]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :position, :integer, allow_nil?: false, default: 0, public?: true

    timestamps()
  end

  relationships do
    belongs_to :list, Kati.Lists.List,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true

    # The durable row, never the cache: a list is about a title the reader
    # keeps, and the cache is evicted.
    belongs_to :tracked_title, Kati.Media.TrackedTitle,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true
  end

  identities do
    identity :one_per_list, [:list_id, :tracked_title_id]
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :for_list do
      description "Everything in one list, in its own order."
      argument :list_id, :uuid, allow_nil?: false
      filter expr(list_id == ^arg(:list_id))
      prepare build(sort: [position: :asc])
    end
  end
end
