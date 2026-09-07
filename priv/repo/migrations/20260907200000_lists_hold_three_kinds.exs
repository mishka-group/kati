defmodule Kati.Repo.Migrations.ListsHoldThreeKinds do
  @moduledoc """
  A list holds a film, a series, a book or an album.

  `D-65` L3, drawn on board 332: one 38x54 slot, three fills, three titles on
  one baseline. `20260907160000_add_lists.exs` gave `list_memberships` a single
  member column — `tracked_title_id`, a hard FK, `null: false` — so a book or an
  album could not be in a list at all. Board 12's caption had promised otherwise
  since it was drawn: *"The same shell will hold book and album lists."*

  ## Why three nullable FKs and not a type/id pair

  A `member_type` + `member_id` pair reads more cleanly and loses the thing that
  matters: SQLite will not foreign-key into a union, so `ON DELETE CASCADE` goes
  with it. Delete a book and its membership stays behind forever, drawn by
  nothing and swept by nothing. Three nullable FKs keep the cascade per kind,
  keep ONE `position` sequence — which board 332's ranked mixed list needs, since
  `1`, `2`, `10` number across kinds — and keep one uniqueness scope per kind.

  Three separate join tables would also keep the cascade and lose the single
  ordering, which is the same failure one level along.

  ## Why the whole table is rebuilt

  Relaxing `tracked_title_id`'s `NOT NULL` is `ALTER COLUMN`, which
  `ecto_sqlite3` refuses outright (*"ALTER COLUMN not supported by SQLite3"*),
  and `ADD CONSTRAINT` is refused for the same reason — so the *exactly one
  non-null* rule has to go inline in a fresh `CREATE TABLE` rather than be added
  afterwards. Since the rebuild is happening anyway, it carries the CHECK, and
  the rule is enforced by the store rather than only by
  `Kati.Lists.Membership`'s own validation.

  Existing rows carry `tracked_title_id` and take `NULL` for the other two,
  which is why `Kati.Backup.Upgrade`'s 16 -> 17 step is `unchanged/1` — the same
  shape the 10 -> 11 `private` step had.
  """
  use Ecto.Migration

  def up do
    execute("PRAGMA foreign_keys = OFF")

    execute("""
    CREATE TABLE list_memberships_new (
      id TEXT PRIMARY KEY NOT NULL,
      position INTEGER NOT NULL DEFAULT 0,
      list_id TEXT NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
      tracked_title_id TEXT REFERENCES tracked_titles(id) ON DELETE CASCADE,
      book_id TEXT REFERENCES books(id) ON DELETE CASCADE,
      album_id TEXT REFERENCES music_albums(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      CHECK (
        (CASE WHEN tracked_title_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN book_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN album_id IS NULL THEN 0 ELSE 1 END) = 1
      )
    )
    """)

    execute("""
    INSERT INTO list_memberships_new
      (id, position, list_id, tracked_title_id, book_id, album_id, inserted_at, updated_at)
    SELECT id, position, list_id, tracked_title_id, NULL, NULL, inserted_at, updated_at
    FROM list_memberships
    """)

    execute("DROP TABLE list_memberships")
    execute("ALTER TABLE list_memberships_new RENAME TO list_memberships")

    # One partial unique index per kind, replacing the single one the old table
    # carried: a title is in a list once, and so is a book, and so is an album.
    create unique_index(:list_memberships, [:list_id, :tracked_title_id],
             where: "tracked_title_id IS NOT NULL",
             name: :list_memberships_list_id_tracked_title_id_index
           )

    create unique_index(:list_memberships, [:list_id, :book_id],
             where: "book_id IS NOT NULL",
             name: :list_memberships_list_id_book_id_index
           )

    create unique_index(:list_memberships, [:list_id, :album_id],
             where: "album_id IS NOT NULL",
             name: :list_memberships_list_id_album_id_index
           )

    create index(:list_memberships, [:list_id, :position])

    execute("PRAGMA foreign_keys = ON")
  end

  def down do
    execute("PRAGMA foreign_keys = OFF")

    execute("""
    CREATE TABLE list_memberships_old (
      id TEXT PRIMARY KEY NOT NULL,
      position INTEGER NOT NULL DEFAULT 0,
      list_id TEXT NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
      tracked_title_id TEXT NOT NULL REFERENCES tracked_titles(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    # A book or an album membership has nowhere to go in the old shape and is
    # dropped rather than invented into a tracked title.
    execute("""
    INSERT INTO list_memberships_old
      (id, position, list_id, tracked_title_id, inserted_at, updated_at)
    SELECT id, position, list_id, tracked_title_id, inserted_at, updated_at
    FROM list_memberships
    WHERE tracked_title_id IS NOT NULL
    """)

    execute("DROP TABLE list_memberships")
    execute("ALTER TABLE list_memberships_old RENAME TO list_memberships")

    create unique_index(:list_memberships, [:list_id, :tracked_title_id])
    create index(:list_memberships, [:list_id, :position])

    execute("PRAGMA foreign_keys = ON")
  end
end
