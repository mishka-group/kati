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

  ## One kind today, three when 181 and 182 are built

  `tracked_title_id` is a hard FK to `tracked_titles`, so a book or an album
  **cannot be in a list at all**. Boards 181 and 182 both require that it can —
  181's band 1 draws one list holding a film, a book and an album under the
  heading *"One recipe, three kinds"*, and 182's sheet is opened over an album.
  The owner ratified it on 7 September. Board 12's caption had promised it since
  it was drawn: *"The same shell will hold book and album lists."*

  Four shapes were costed; **three nullable FKs on this table** — `tracked_
  title_id`, `book_id`, `album_id` — is the one to build:

    * It keeps `ON DELETE CASCADE` per kind. A `member_type`/`member_id` pair
      cannot: SQLite will not FK into a union, so deleting a book would leave
      its membership behind forever with nothing to sweep it.
    * It keeps ONE `position` sequence and ONE uniqueness scope. Three join
      tables would give a mixed ranked list three orderings and no single one to
      number `1`, `2` against, which is what 181's band 3 draws.
    * It keeps the backup's 16 → 17 step `unchanged/1`: a version-16 file's rows
      carry `tracked_title_id` and take `NULL` for the other two, exactly as the
      10 → 11 `private` step did.

  Two costs are unavoidable and both come from SQLite rather than from the
  choice: relaxing `tracked_title_id`'s `NOT NULL` needs a full table rebuild
  (`ALTER COLUMN` raises), and *exactly one non-null* cannot be added as a
  CHECK afterwards — it goes inline in the rebuild's `CREATE TABLE`, or it is an
  Ash validation and app-enforced rather than store-enforced.

  Not chosen: giving books and albums their own `tracked_titles` rows. `kind`
  already permits `:book` and `:album`, but it would be a second durable
  identity for something `books` and `music_albums` already hold, with nothing
  keeping the two in step — and a hand-typed book has no `source_id`, which this
  resource requires. It also saves no work: there is no `Kati.Media.CachedTitle`
  behind a book, so `Kati.Lists.Shelf.titles_for/1` needs the per-kind branch
  either way.
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
