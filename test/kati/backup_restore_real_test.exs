defmodule Kati.BackupRestoreRealTest do
  @moduledoc """
  Boards 129, 131 and 133 draw this device's data, and never the board's.

  Until 25 September all three drew a backup nobody had made. Screen 129 named
  `kati-backup-2026-08-14.json`, summarised it as `384 / 28 / 6`, opened a
  `Blue Hour` conflict at `1 of 6` and warned that Replace would delete
  `418 titles` — on a phone with nothing on it and no file picked. Screens 131
  and 133 said the last backup was `14 Aug`, `2 WEEKS AGO`, `214 MB` and
  *Up to date* on a phone that had never made one.

  Each test here writes real state — rows through Ash, a date and a size into
  the ledger `Kati.Screens.Settings` and `Kati.Screens.Backup` keep — mounts the
  screen on a fresh socket, and reads what it drew. Every one also refutes the
  board's own figures, because a screen that drew both the reading and the
  drawing would pass the first half alone.
  """
  # `async: false`: the renders switch the global theme and locale, the empty
  # database runs inside the pool's only connection, and the rows written here
  # are counted by the screen under test.
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Backup
  alias Kati.Screens.BackupDark
  alias Kati.Screens.BackupLarge
  alias Kati.Screens.Restore
  alias Kati.Screens.Settings

  @not_resources ~w(schema_migrations mob_screen_states)

  # The figures boards 129, 131 and 133 drew on every phone.
  @board_129 [
    "kati-backup-2026-08-14.json",
    "Merge 384 into this device",
    "Blue Hour",
    "Conflicts · keep which?",
    "apply to all",
    "418 titles"
  ]
  @board_backup ["14 Aug", "214 MB", "2 WEEKS AGO", "Up to date"]

  # `Mob.ScreenCase` starts `Mob.State` under the test's own supervisor, so the
  # ledger is gone with the test and cannot be touched from `on_exit/1`; it is
  # cleared on the way in instead, in case a run started it earlier.
  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)

    Mob.State.delete(:last_backup_at)
    Mob.State.delete(:last_backup_bytes)
    :ok
  end

  describe "screen 129 on an empty device" do
    test "names no file, counts nothing, and says there is nothing to merge or delete" do
      {here, tree} =
        in_empty_database(fn ->
          view = mount_screen(Restore)
          {assigns(view).restore.here, tree(view)}
        end)

      assert here == 0

      assert drawn?(tree, "No file chosen yet")
      assert drawn?(tree, "No file has been read yet, so there is nothing to count.")
      assert drawn?(tree, "Nothing is stored on this device yet, so the file goes in as it is")

      assert drawn?(
               tree,
               "Nothing is stored on this device yet, so a replace has nothing to delete"
             )

      assert drawn?(tree, "Merge into this device")

      refute drawn?(tree, "This device already has data"),
             "an empty device was told it already has data"

      for figure <- @board_129 do
        refute drawn?(tree, figure), "an empty device drew the board's #{inspect(figure)}"
      end
    end
  end

  describe "screen 129 over rows this test wrote" do
    setup do
      before = Restore.records_on_device()
      rows = for _ <- 1..2, do: track!()
      on_exit(fn -> Enum.each(rows, &Ash.destroy/1) end)
      {:ok, before: before}
    end

    test "counts the rows the engine counts, and names that number on Replace", %{before: before} do
      view = mount_screen(Restore)
      here = assigns(view).restore.here

      assert here == before + 2, "the two rows written here were not counted"

      assert here ==
               Kati.Backup.occupied() |> Enum.map(&elem(&1, 1)) |> Enum.sum(),
             "the screen counted something other than what :into_empty refuses over"

      assert {"tracked_titles", titles} =
               List.keyfind(Kati.Backup.occupied(), "tracked_titles", 0)

      assert titles >= 2

      tree = tree(view)
      assert drawn?(tree, "Deletes all #{Restore.group(here)} records on this device")
      assert drawn?(tree, "This device already has data, so the file is ")

      refute drawn?(tree, "Nothing is stored on this device yet"),
             "a device holding rows was told it holds nothing"

      for figure <- @board_129 do
        refute drawn?(tree, figure), "a device with real rows drew the board's #{inspect(figure)}"
      end
    end

    test "a row written after mount is counted by the next mount", %{before: before} do
      assert assigns(mount_screen(Restore)).restore.here == before + 2

      third = track!()
      on_exit(fn -> Ash.destroy(third) end)

      assert assigns(mount_screen(Restore)).restore.here == before + 3
    end

    test "tapping restore with no file picked says so, and writes nothing", %{before: before} do
      view = render_info(mount_screen(Restore), {:tap, :restore_now})
      notice = assigns(view).restore.notice

      assert notice.title == "There is no file to restore"
      assert notice.body =~ "No file has been chosen yet."
      refute notice.body =~ "drawing"
      assert Restore.records_on_device() == before + 2
    end
  end

  describe "screen 131, the dark colourway of 128" do
    test "a phone that never saved a backup reads Never" do
      tree = tree(mount_screen(BackupDark))

      assert drawn?(tree, "Never")
      assert drawn?(tree, "STILL ONLY ON THIS PHONE")
      assert drawn?(tree, Kati.Icons.glyph("cloud_off"))

      for figure <- @board_backup do
        refute drawn?(tree, figure), "an empty ledger drew the board's #{inspect(figure)}"
      end
    end

    test "a saved backup draws the ledger's own date and size" do
      at = DateTime.add(Kati.Time.now(), -3, :day)
      :ok = Settings.record_backup(at)
      :ok = Backup.record_bytes(5_300_000)

      tree = tree(mount_screen(BackupDark))

      assert drawn?(tree, Backup.date_text(at))
      assert drawn?(tree, Backup.caption(at))
      assert Backup.caption(at) =~ "5 MB"
      assert drawn?(tree, Kati.Icons.glyph("cloud_done"))
      refute drawn?(tree, "STILL ONLY ON THIS PHONE")

      for figure <- @board_backup do
        refute drawn?(tree, figure), "a real ledger drew the board's #{inspect(figure)}"
      end
    end

    test "a completed Save As stamps the date and the size 128 reads back" do
      view = mount_screen(BackupDark)

      render_info(
        view,
        {:kati_files, :saved,
         [%{path: "/tmp/kati.katibackup", name: "kati.katibackup", bytes: 8736, uri: "x"}]}
      )

      assert %DateTime{} = Settings.last_backup()
      assert Backup.last_backup_bytes() == 8736
      assert drawn?(tree(mount_screen(Backup)), Backup.caption(Settings.last_backup()))
    end
  end

  describe "screen 133, 128 at 235%" do
    test "a phone that never saved a backup reads Never and prints no size" do
      tree = tree(mount_screen(BackupLarge))

      assert drawn?(tree, "Never")
      assert drawn?(tree, "STILL ONLY ON THIS PHONE")
      assert drawn?(tree, "Not backed up yet")
      refute drawn?(tree, " MB")

      for figure <- @board_backup do
        refute drawn?(tree, figure), "an empty ledger drew the board's #{inspect(figure)}"
      end
    end

    test "a saved backup draws the ledger's date, age and size on their own lines" do
      at = DateTime.add(Kati.Time.now(), -3, :day)
      :ok = Settings.record_backup(at)
      :ok = Backup.record_bytes(5_300_000)

      tree = tree(mount_screen(BackupLarge))

      assert drawn?(tree, Backup.date_text(at))
      assert drawn?(tree, Kati.UI.eyebrow_label(Kati.Screens.UpNext.age(at)))
      assert drawn?(tree, "5 MB")
      assert drawn?(tree, "Saved to a file you chose")
      refute drawn?(tree, "Never")

      for figure <- @board_backup do
        refute drawn?(tree, figure), "a real ledger drew the board's #{inspect(figure)}"
      end
    end

    test "the Persian page reads the ledger too" do
      previous = Kati.Locale.current()
      Kati.Locale.put(:fa)

      tree =
        try do
          tree(mount_screen(BackupLarge))
        after
          Kati.Locale.put(previous)
        end

      assert drawn?(tree, "هنوز پشتیبانی گرفته نشده")
      refute drawn?(tree, "۲۳ مرداد")
      refute drawn?(tree, "۲۱۴")
    end
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  defp track! do
    Kati.Media.TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: "backup-restore-real-#{System.unique_integer([:positive])}",
      kind: :tv,
      status: :watching
    })
    |> Ash.create!()
  end

  defp drawn?(tree, needle) do
    tree
    |> flatten()
    |> Enum.flat_map(fn node -> node.props |> Map.values() |> Enum.filter(&is_binary/1) end)
    |> Enum.any?(&String.contains?(&1, needle))
  end

  defp resource_tables do
    %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'")

    rows
    |> List.flatten()
    |> Enum.reject(&String.starts_with?(&1, "sqlite_"))
    |> Enum.reject(&(&1 in @not_resources))
  end

  # Every table emptied, the renders run, and everything rolled back — the
  # shape `Kati.ScreenBackupTest` uses, so the suite's shared rows survive.
  defp in_empty_database(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Kati.Repo.query!("PRAGMA defer_foreign_keys = ON")
        Enum.each(resource_tables(), &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end
end
