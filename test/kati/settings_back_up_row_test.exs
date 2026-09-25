defmodule Kati.SettingsBackUpRowTest do
  @moduledoc """
  Settings' *Back up everything* row reads the backup ledger (N19).

  ## The defect this exists for

  The row's second line was `Kati.Settings.Sample.data/0`'s copy of board 24:
  `Last backup 14 Aug · 214 MB`, on every phone. *Export everything*, one row
  below it, already read `Kati.Screens.Settings.last_backup/0` and said *Never
  backed up* — so a fresh install claimed a backup and denied it in the same
  card.

  ## What is asserted

    * the sample no longer carries a line for either backup row, so nothing
      but the ledger can answer;
    * `Kati.Screens.Settings.backup_line/2` in all four cases — no backup, a
      date with no size, a size with no date, and both — in both languages;
    * the rendered screen, before and after a Save As is recorded;
    * that the two rows are one destination today, which the report on N19
      says rather than deleting a row.

  `Mob.State` is set explicitly on the way in rather than restored on the way
  out: `on_exit/1` runs in another process, after `Mob.ScreenCase` has stopped
  the store.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Backup
  alias Kati.Screens.Settings

  @never_en "Never backed up"
  @never_fa "هنوز پشتیبانی گرفته نشده"

  @drawn ~U[2026-08-14 12:00:00Z]

  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)

    Mob.State.put(:last_backup_at, nil)
    Mob.State.put(:last_backup_bytes, nil)
    Kati.Locale.put(:en)
    :ok
  end

  describe "the sample" do
    test "carries no second line for either backup row" do
      rows = Map.new(Kati.Settings.Sample.data(), &{&1.id, &1})

      assert rows["back_up"].sub == nil
      assert rows["export"].sub == nil
    end
  end

  describe "backup_line/2" do
    test "no backup is the absence, with or without a stray size" do
      assert Settings.backup_line(nil, nil) == @never_en
      assert Settings.backup_line(nil, 214_000_000) == @never_en
      assert fa(fn -> Settings.backup_line(nil, 214_000_000) end) == @never_fa
    end

    test "a date with no size is the date alone" do
      assert Settings.backup_line(@drawn, nil) == "Last backup 14 Aug"
    end

    test "a date and a size is the drawing's own line" do
      assert Settings.backup_line(@drawn, 214_000_000) == "Last backup 14 Aug · 214 MB"
      assert Settings.backup_line(@drawn, 8736) == "Last backup 14 Aug · 8 KB"

      assert fa(fn -> Settings.backup_line(@drawn, 214_000_000) end) ==
               "آخرین پشتیبان ۲۳ مرداد · ۲۱۴ مگابایت"
    end
  end

  describe "the rendered row" do
    test "a fresh install says it has never backed up, twice, and never the drawing's figure" do
      texts = texts(mount_screen(Settings))

      assert Enum.count(texts, &(&1 == @never_en)) == 2
      refute "Last backup 14 Aug · 214 MB" in texts
    end

    test "a recorded Save As is the date and size on Back up, and the date on Export" do
      :ok = Settings.record_backup(@drawn)
      :ok = Backup.record_bytes(8736)

      texts = texts(mount_screen(Settings))

      assert "Last backup 14 Aug · 8 KB" in texts
      assert "Last backup 14 Aug" in texts
      refute @never_en in texts
      refute "Last backup 14 Aug · 214 MB" in texts
    end

    test "the Save As branch of the backup screen stamps what the row reads" do
      render_info(
        mount_screen(Backup),
        {:kati_files, :saved,
         [%{path: "/tmp/kati.katibackup", name: "kati.katibackup", bytes: 2_400_000, uri: "x"}]}
      )

      date = Kati.Locale.date(DateTime.to_date(Settings.last_backup()), :short)

      assert "Last backup #{date} · 2 MB" in texts(mount_screen(Settings))
    end
  end

  test "Back up and Export open the same screen today" do
    destinations = Settings.destinations()

    assert destinations["back_up"] == Backup
    assert destinations["export"] == Backup
  end

  defp fa(fun) do
    Kati.Locale.put(:fa)

    try do
      fun.()
    after
      Kati.Locale.put(:en)
    end
  end

  defp texts(view) do
    for node <- flatten(view),
        text = (Map.get(node, :props) || %{})[:text],
        is_binary(text),
        do: text
  end
end
