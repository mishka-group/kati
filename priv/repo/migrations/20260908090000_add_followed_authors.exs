defmodule Kati.Repo.Migrations.AddFollowedAuthors do
  @moduledoc """
  Authors you follow.

  Board 307 gives screen 25 a **New books** switch whose sub-line reads
  *Authors you follow*, and gives screen 66 the row that fills it — the board's
  own words: *"New row on the book page — the only new ink 66 needs."* Neither
  had anywhere to write: `Kati.Books.Book` carries `author` as a free string
  and nothing in the app knew an author was a thing you could follow.

  One column of substance. Following is about the person, so the row is keyed
  by the name rather than by a book — a boolean on `books` would be per copy,
  and two books by the same author could disagree about whether you follow
  them.

  `name_key` is the trimmed, case-folded name, stored rather than computed so
  the unique index can hold it. That is `lists.name_key`'s arrangement and its
  reason: `ines karvel` and `Ines Karvel ` are one person followed twice.
  """
  use Ecto.Migration

  def up do
    create table(:followed_authors, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false)
      add(:name, :text, null: false)
      add(:name_key, :text, null: false)

      timestamps()
    end

    create unique_index(:followed_authors, [:name_key])
  end

  def down do
    drop(table(:followed_authors))
  end
end
