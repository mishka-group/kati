defmodule Kati.RepoLockingModeTest do
  @moduledoc """
  The WAL index stays in memory, so there is no `-shm` to map (#108).

  The BEAM died twice with `SIGBUS`/`BUS_ADRERR` inside `sqlite3_step`: a
  mapped address with no page behind it. With `locking_mode = EXCLUSIVE`,
  SQLite keeps the WAL index on the heap and never creates `kati.db-shm`, the
  one file it would otherwise map. These pin the connection to that mode, and
  check the file itself is absent after a write.
  """
  use ExUnit.Case, async: false

  defp pragma(name) do
    %{rows: [[value]]} = Ecto.Adapters.SQL.query!(Kati.Repo, "PRAGMA #{name}")
    value
  end

  test "the connection holds the database in exclusive locking mode" do
    assert pragma("locking_mode") == "exclusive"
  end

  test "the journal is still the write-ahead log" do
    assert pragma("journal_mode") == "wal"
  end

  test "a write leaves a WAL beside the database and no shared-memory index" do
    Ecto.Adapters.SQL.query!(
      Kati.Repo,
      "CREATE TABLE IF NOT EXISTS repo_locking_probe (id INTEGER)"
    )

    Ecto.Adapters.SQL.query!(Kati.Repo, "INSERT INTO repo_locking_probe VALUES (1)")
    Ecto.Adapters.SQL.query!(Kati.Repo, "DROP TABLE repo_locking_probe")

    db = Path.join(Mob.data_dir(), "kati.db")

    assert File.exists?(db <> "-wal")
    refute File.exists?(db <> "-shm")
  end
end
