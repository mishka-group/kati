defmodule Kati.SettingsBackupLineTest do
  @moduledoc """
  The `Last backup` line on screens 24 and 62, and the ledger behind it.

  ## The defect this exists for

  `Kati.Backup` has been finished and proven on device for rounds — export,
  encrypted export, a restore that refuses a non-empty database by name and
  count, merge, a wrong passphrase that says why it cannot tell a wrong
  passphrase from a tampered file. And screen 24 said **`Last backup 14 Aug`**,
  which was a string in `Kati.Settings.Sample` and nothing else. Screen 62 said
  the same thing in Shamsi.

  That is the worst shape a defect can take on this screen. Android's
  `allowBackup` is `false`, the database lives in `filesDir`, and there is no
  server and no account, so a user who loses the phone loses everything — and
  the one line in the app that tells them whether they are covered was a
  decoration that read the same on a phone that had never made a backup as on
  one that had. A screenshot could not see it. Every test passed.

  ## What is asserted, and where each assertion stops

  Two halves that fail separately:

    * **`backup_line/1` is pure**, on both screens, so the two sentences can be
      checked without a store and the date form can be checked at all — the
      store is empty in every test here, so the *drawn* line is always the
      absence and the dated branch would otherwise never be read.
    * **the screens draw what the ledger says**, checked through a second
      `mount_screen/1` with its own socket, because that is the only thing that
      can tell a stored fact from one computed in the render that drew it.

  The last test is the one that keeps the frame still: recording a backup must
  change **exactly one** `Text` on screen 24. 62 captured frames are this app's
  baseline, and "the Export row now reads a ledger" may not become "screen 24
  now looks different".
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Backup
  alias Kati.Screens.Settings
  alias Kati.Screens.SettingsFa

  # `SettingsFa.mount/3` calls `Kati.Theme.activate/0`, which is
  # `Application.put_env/3` — one global for the whole run and not one
  # `Mob.ScreenCase` resets. Put back what was installed on the way in, for the
  # reason `Kati.SettingsThemeTest` sets out at length.
  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)
  end

  # Written out rather than read from the screens: a test that asks the code
  # under test what to expect agrees with it by construction.
  @never_en "Never backed up"
  @never_fa "هنوز پشتیبانی گرفته نشده"

  # 14 August 2026 at noon — the drawing's own date, so the dated branch is
  # checked against the literal `24.html` froze rather than against a date this
  # file invented.
  @drawn ~U[2026-08-14 12:00:00Z]

  # ── The ledger ──────────────────────────────────────────────────────────────

  test "a fresh install has never backed up" do
    assert Settings.last_backup() == nil
  end

  test "record_backup/1 stores the moment, and last_backup/0 reads back the one just written" do
    assert Settings.record_backup(@drawn) == :ok
    assert Settings.last_backup() == @drawn
  end

  test "record_backup/0 stamps the device clock" do
    # The arity a caller actually reaches for. Asserted as a window rather than
    # an equality, because the clock moves between the two calls.
    before = Kati.Time.now()
    assert Settings.record_backup() == :ok
    at = Settings.last_backup()

    assert DateTime.compare(at, before) in [:gt, :eq]
    assert DateTime.compare(at, DateTime.add(Kati.Time.now(), 1, :second)) == :lt
  end

  test "anything else on the key reads as no backup rather than crashing a mount" do
    # A value from an older build, or a hand-edited DETS file. `Kati.Theme.Mode`
    # falls back the same way and for the same reason: this is read during
    # `render/1`, and raising here takes down the screen a user is looking at.
    for junk <- ["14 Aug", :never, 0, %{}] do
      Mob.State.put(:last_backup_at, junk)
      assert Settings.last_backup() == nil, "#{inspect(junk)} was taken for a backup time"
    end
  end

  # ── The writer ──────────────────────────────────────────────────────────────
  #
  # A reading with no writer is the same defect as a hardcoded string, wearing a
  # function's clothes: `last_backup/0` would answer `nil` forever, both screens
  # would draw *Never backed up* forever, and every assertion above would still
  # pass because every one of them stamps the ledger itself. So the wire is
  # driven from the far end — a real `{:kati_files, :saved, …}` message down
  # `Kati.Screens.Backup.handle_info/2`, through `Kati.Native.Files.decode/1`,
  # which is the shape the bridge actually sends.

  test "the Save As branch of the backup screen is what stamps the ledger" do
    assert Settings.last_backup() == nil

    before = Kati.Time.now()

    view =
      render_info(
        mount_screen(Backup),
        {:kati_files, :saved,
         [%{path: "/tmp/kati.katibackup", name: "kati.katibackup", bytes: 8736, uri: "content://x"}]}
      )

    # The notice is the screen's half and the ledger is settings'. Both, so a
    # future edit cannot satisfy this by stamping and drawing nothing.
    assert "Saved" in texts(view)

    at = Settings.last_backup()

    assert at != nil,
           "a completed Save As left the ledger empty, so screen 24's Export row can never " <>
             "say anything but #{@never_en} no matter how many backups a user makes"

    assert DateTime.compare(at, before) in [:gt, :eq]
  end

  test "a share and a dismissed sheet leave the ledger alone" do
    # `Kati.Native.Files`' own moduledoc: Android answers a chooser with
    # `RESULT_CANCELED` whether the send completed or the sheet was dismissed.
    # A date written from either branch would promise a backup to a user whose
    # file went into an abandoned mail draft.
    for sub <- [:shared, :dismissed] do
      render_info(mount_screen(Backup), {:kati_files, sub, [%{name: "kati.katibackup"}]})

      assert Settings.last_backup() == nil,
             ":#{sub} stamped the backup ledger, and Android cannot tell that case from a " <>
               "sheet the user dismissed"
    end
  end

  # ── The two sentences ───────────────────────────────────────────────────────

  test "with no backup, both screens state the absence" do
    assert Settings.backup_line(nil) == @never_en
    assert SettingsFa.backup_line(nil) == @never_fa
  end

  test "with a backup, both screens draw the date in their drawing's own form" do
    # `24.html` writes `Last backup 14 Aug` and `62.html` writes
    # `آخرین پشتیبان ۱۴ مرداد`. Only the value was ever wrong, so the form does
    # not move: day then short month in English, Shamsi day and month in
    # Persian, no year in either.
    assert Settings.backup_line(@drawn) == "Last backup 14 Aug"
    assert SettingsFa.backup_line(@drawn) == "آخرین پشتیبان ۲۳ مرداد"
  end

  test "the English month is always the three-letter short form" do
    # `Kati.Time.month_name/1` answers `September`, and the drawing's row is one
    # line at 11.5 with `max_lines={1}`. Every month, so a five-month build
    # cannot be the one that overflows.
    for month <- 1..12 do
      at = DateTime.new!(Date.new!(2026, month, 9), ~T[12:00:00])
      ["Last", "backup", "9", short] = String.split(Settings.backup_line(at))

      assert String.length(short) == 3, "#{Kati.Time.month_name(month)} rendered as #{short}"
    end
  end

  # ── What the screens draw ───────────────────────────────────────────────────

  test "at rest both screens draw the absence, and neither draws the drawing's date" do
    for {module, never, drawn} <- [
          {Settings, @never_en, "Last backup 14 Aug"},
          {SettingsFa, @never_fa, "آخرین پشتیبان ۱۴ مرداد"}
        ] do
      texts = texts(mount_screen(module))

      assert never in texts, "#{inspect(module)} does not say a backup has never been made"

      refute drawn in texts,
             "#{inspect(module)} still draws the frozen date from its drawing, which is the " <>
               "defect this file exists for"
    end
  end

  test "a backup recorded now is read by a screen mounted afterwards, in both locales" do
    # The one that matters: a second socket, which has never seen the write.
    :ok = Settings.record_backup(@drawn)

    assert "Last backup 14 Aug" in texts(mount_screen(Settings))
    assert "آخرین پشتیبان ۲۳ مرداد" in texts(mount_screen(SettingsFa))
  end

  test "the row that reports the ledger is the row with the upload glyph, and it is unique" do
    # Both screens match on the glyph rather than on the title, so that neither
    # carries the other's words. That is only sound while `upload` names exactly
    # one row in each sample — a second one would silently start reporting the
    # ledger too.
    en = Enum.map(Kati.Settings.Sample.data(), & &1.icon)
    fa = for section <- Kati.Fa.SampleSettings.sections(), row <- section.rows, do: row[:icon]

    assert Enum.count(en, &(&1 == "upload")) == 1
    assert Enum.count(fa, &(&1 == "upload")) == 1
  end

  test "recording a backup moves exactly one Text on screen 24" do
    # The resting frame is 62 captured drawings and may not drift. Everything
    # else on this screen — the account card, the four groups, the trough — has
    # to be byte-for-byte what it was, so the whole rendered copy is compared
    # rather than the one row.
    before = texts(mount_screen(Settings))
    :ok = Settings.record_backup(@drawn)
    after_ = texts(mount_screen(Settings))

    assert length(before) == length(after_), "the ledger added or removed a node"

    changed = for {a, b} <- Enum.zip(before, after_), a != b, do: {a, b}

    assert changed == [{@never_en, "Last backup 14 Aug"}]
  end

  test "recording a backup moves exactly one Text on screen 62" do
    before = texts(mount_screen(SettingsFa))
    :ok = Settings.record_backup(@drawn)
    after_ = texts(mount_screen(SettingsFa))

    assert length(before) == length(after_), "the ledger added or removed a node"

    changed = for {a, b} <- Enum.zip(before, after_), a != b, do: {a, b}

    assert changed == [{@never_fa, "آخرین پشتیبان ۲۳ مرداد"}]
  end

  # Every string the screen draws, in draw order. Raw rather than normalised —
  # this file is about which sentence appears, and `Kati.DesignLiterals` folds
  # the case away.
  defp texts(view) do
    for node <- flatten(view),
        text = (Map.get(node, :props) || %{})[:text],
        is_binary(text),
        do: text
  end
end
