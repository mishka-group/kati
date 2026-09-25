defmodule Kati.Repo.Migrations.CascadeWatchesAndWarnings do
  @moduledoc """
  Removing a title from the library takes its history with it.

  `media_watches.tracked_title_id` and `media_content_warnings.tracked_title_id`
  referenced `tracked_titles(id)` with no `ON DELETE` action, so SQLite refused
  to delete any title that had ever been watched or warned about. The reader
  saw *"Referenced something that does not exist"* — Ash's wording for a
  foreign-key refusal — on the ⋯ *Remove* row and on screen 06's untick, and
  the titles they had actually watched were exactly the ones that would not go.
  Found on the owner's A55 with *Marram*.

  `media_events`, `media_title_aliases` and `list_memberships` already cascade;
  these two were the only children of `tracked_titles` that did not. The
  owner's decision was a full delete: the title and its history go together.

  ## Why the table is rebuilt from its own `CREATE` statement

  SQLite cannot alter a foreign key in place, so the table has to be rebuilt —
  the precedent is `20260907200000_lists_hold_three_kinds.exs`. That migration
  wrote its new table out by hand, which was safe for a table one migration
  old. `media_watches` has had columns added across four migrations, and a
  hand-written copy that missed one would silently drop the reader's data for
  it on every device this runs on.

  So the new table is the old table's own `CREATE` statement from
  `sqlite_master`, with exactly one clause changed, and the indexes are
  re-created from their own saved statements. Whatever columns a given device
  has, it keeps. Row shape is unchanged, which is why `Kati.Backup`'s
  `schema_version` does not move — it tracks the shape of a row, and a
  foreign-key action is not part of that.
  """
  use Ecto.Migration

  @tables ["media_watches", "media_content_warnings"]

  @plain ~r/REFERENCES "tracked_titles"\s*\("id"\)(?!\s+ON DELETE)/
  @cascading ~r/REFERENCES "tracked_titles"\s*\("id"\)\s+ON DELETE CASCADE/

  def up do
    Enum.each(
      @tables,
      &rebuild(&1, fn sql ->
        Regex.replace(@plain, sql, ~s|REFERENCES "tracked_titles"("id") ON DELETE CASCADE|)
      end)
    )
  end

  def down do
    Enum.each(
      @tables,
      &rebuild(&1, fn sql ->
        Regex.replace(@cascading, sql, ~s|REFERENCES "tracked_titles"("id")|)
      end)
    )
  end

  defp rebuild(table, rewrite) do
    [[create]] =
      repo().query!(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?1",
        [table]
      ).rows

    indexes =
      repo().query!(
        "SELECT sql FROM sqlite_master WHERE type = 'index' AND tbl_name = ?1 AND sql IS NOT NULL",
        [table]
      ).rows
      |> List.flatten()

    rewritten = rewrite.(create)

    # A rewrite that changed nothing means the clause was not where this
    # expected it. Refusing is better than rebuilding a table for no reason on
    # every device and reporting success.
    if rewritten == create do
      raise "#{table}: the tracked_titles reference was not in the expected form:\n#{create}"
    end

    scratch = table <> "_rebuild"

    # Quoted or bare, whichever this device's adapter wrote.
    new_table =
      Regex.replace(~r/^CREATE TABLE\s+"?#{table}"?/, rewritten, ~s|CREATE TABLE "#{scratch}"|)

    if new_table == rewritten do
      raise "#{table}: could not rename the table in its own CREATE statement:\n#{create}"
    end

    repo().query!(new_table)
    repo().query!(~s|INSERT INTO "#{scratch}" SELECT * FROM "#{table}"|)
    repo().query!(~s|DROP TABLE "#{table}"|)
    repo().query!(~s|ALTER TABLE "#{scratch}" RENAME TO "#{table}"|)

    Enum.each(indexes, &repo().query!/1)
  end
end
