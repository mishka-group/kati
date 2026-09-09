defmodule Kati.Repo.Migrations.AddLists do
  @moduledoc """
  Hand-made lists, and what is in them.

  MOVIES-AND-TV.md #106. Screen 12 drew three lists that belonged to nobody and
  a `+` that prepended a row titled `New list` to a socket assign — lost on
  back, duplicated on a second press, holding nothing either way.

  Two tables, which is what board 12 needs and no more. `lists` carries the
  name and the two flags the board draws as badges; `list_memberships` carries
  one row per title, with the position that makes a ranked list ranked.

  `name_key` is the trimmed, case-folded name, stored rather than computed so
  the unique index can hold it: two lists called `Rainy Sunday` are one list
  somebody made twice. Membership references `tracked_titles` and not
  `cached_titles`, because a list is about a title the reader KEEPS and the
  cache is evicted.
  """
  use Ecto.Migration

  def up do
    create table(:lists, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :name, :text, null: false
      add :name_key, :text, null: false
      add :ranked, :boolean, null: false, default: false
      add :shared, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:lists, [:name_key])
    create index(:lists, [:inserted_at])

    create table(:list_memberships, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :position, :integer, null: false, default: 0

      add :list_id, references(:lists, type: :uuid, on_delete: :delete_all), null: false

      add :tracked_title_id,
          references(:tracked_titles, type: :uuid, on_delete: :delete_all),
          null: false

      timestamps()
    end

    create unique_index(:list_memberships, [:list_id, :tracked_title_id])
    create index(:list_memberships, [:list_id, :position])
  end

  def down do
    drop table(:list_memberships)
    drop table(:lists)
  end
end
