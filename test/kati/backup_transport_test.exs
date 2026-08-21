defmodule Kati.BackupTransportTest do
  @moduledoc """
  The seam between a backup that exists and a backup a user can hold.

  Every assertion here is on a real file with real bytes and a real record
  count read back out of it — never on a call returning `:ok`. A transport test
  that only checked `:ok` would pass against a zero-byte file, which is exactly
  the failure this feature must never have.

  The native half is replaced by a recorder rather than mocked away: what
  reaches `Kati.Native.Files.save_as/2` — the path, the pre-filled filename,
  the MIME type — is the whole contract with the Android intent, and it is
  asserted directly.
  """
  use ExUnit.Case, async: false

  alias Kati.Backup
  alias Kati.Backup.Error
  alias Kati.Backup.Transport

  defmodule Recorder do
    @moduledoc false
    def save_as(path, opts), do: send(self(), {:save_as, path, opts}) && :ok
    def share(path, opts), do: send(self(), {:share, path, opts}) && :ok
  end

  defmodule Absent do
    @moduledoc false
    def save_as(_path, _opts), do: {:error, :no_bridge}
    def share(_path, _opts), do: {:error, :no_bridge}
  end

  setup do
    dir = Path.join(System.tmp_dir!(), "kati_transport_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf(dir) end)

    # One real row, so "the backup contains what the screen said" cannot be
    # satisfied by an empty database agreeing with an empty file.
    tracked =
      Kati.Media.TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: "transport-#{System.unique_integer([:positive])}",
        kind: :tv,
        status: :watching,
        rating: 8
      })
      |> Ash.create!()

    on_exit(fn -> Ash.destroy(tracked) end)

    {:ok, dir: dir, tracked: tracked}
  end

  describe "staging" do
    test "writes a file that reads back as the backup it claims to be", %{dir: dir} do
      assert {:ok, staged} = Transport.stage(dir: dir, date: ~D[2026-08-21])

      assert staged.filename == "kati-backup-2026-08-21.katibackup"
      assert Path.basename(staged.path) == staged.filename
      assert File.regular?(staged.path)
      assert staged.bytes > 0
      assert File.stat!(staged.path).size == staged.bytes

      # Positive first, so "the counts agree" cannot mean "both are empty".
      assert staged.record_counts["tracked_titles"] >= 1
      assert staged.total_records >= 1

      # The counts printed on screen must be the counts inside the file, or a
      # confirmation dialog is offering numbers a restore would then refuse.
      assert {:ok, inspected} = Backup.inspect_file(staged.path)
      assert inspected.record_counts == staged.record_counts
    end

    test "an encrypted export stages encrypted bytes", %{dir: dir} do
      assert {:ok, staged} = Transport.stage(dir: dir, passphrase: "correct horse battery")
      assert staged.encrypted

      assert {:ok, locked} = Backup.inspect_file(staged.path)
      assert locked.encrypted
      refute locked.unlocked
    end

    test "the staging directory holds only backups", %{dir: dir} do
      assert {:ok, _} = Transport.stage(dir: dir, date: ~D[2026-08-21])

      assert [name] = File.ls!(dir)
      assert String.ends_with?(name, ".katibackup")
    end
  end

  describe "handing the file to the system" do
    test "save passes the staged path and the dated filename to the intent", %{dir: dir} do
      assert {:ok, staged} =
               Transport.save(dir: dir, date: ~D[2026-08-21], transport: Recorder)

      assert_received {:save_as, path, opts}
      assert path == staged.path
      assert opts[:name] == "kati-backup-2026-08-21.katibackup"

      # application/octet-stream and not application/zip: a more specific type
      # invites the picker to rename the file to match it, and the user ends up
      # with a .zip that Kati's own import filter then rejects.
      assert opts[:mime] == "application/octet-stream"
    end

    test "share passes a subject as well", %{dir: dir} do
      assert {:ok, staged} = Transport.share(dir: dir, transport: Recorder)

      assert_received {:share, path, opts}
      assert path == staged.path
      assert opts[:subject] == staged.filename
    end

    test "with no transport the file is still written and its path is in the error",
         %{dir: dir} do
      # This is the iOS and host answer, and it is the difference between "your
      # backup failed" and "your backup is at this path" — which on iOS today
      # is the whole of the feature.
      assert {:error, %Error{} = error} =
               Transport.save(dir: dir, date: ~D[2026-08-21], transport: Absent)

      assert error.reason == :no_transport
      assert File.regular?(error.details.path)
      assert File.stat!(error.details.path).size > 0
      assert error.message =~ error.details.path
    end
  end

  describe "sweeping" do
    test "a stale staged file is deleted and a fresh one is kept", %{dir: dir} do
      assert {:ok, staged} = Transport.stage(dir: dir, date: ~D[2026-08-21])

      # Nothing to sweep yet: the file was written a moment ago.
      assert Transport.sweep(dir: dir) == 0
      assert File.regular?(staged.path)

      # An hour and a minute later it is a full plaintext copy of the user's
      # data that nobody is saving any more.
      later = DateTime.utc_now() |> DateTime.add(3661)
      assert Transport.sweep(dir: dir, now: later) == 1
      refute File.exists?(staged.path)
    end

    test "staging sweeps as it goes", %{dir: dir} do
      assert {:ok, old} = Transport.stage(dir: dir, date: ~D[2020-01-01])
      File.touch!(old.path, System.os_time(:second) - 7200)

      assert {:ok, fresh} = Transport.stage(dir: dir, date: ~D[2026-08-21])

      refute File.exists?(old.path)
      assert File.regular?(fresh.path)
    end
  end

  describe "accepting a picked file" do
    test "a .katibackup is accepted whatever else was offered" do
      items = [
        %{name: "IMG_2043.jpg", path: "/tmp/a"},
        %{name: "kati-backup-2026-08-21.katibackup", path: "/tmp/b"},
        %{name: "notes.txt", path: "/tmp/c"}
      ]

      assert {:ok, %{path: "/tmp/b"}} = Transport.accept(items)
    end

    test "the extension match is case-insensitive" do
      assert Transport.backup?(%{name: "KATI-BACKUP.KATIBACKUP"})
      assert Transport.backup?(%{"name" => "a.katibackup"})
    end

    test "anything else is refused by name, with the names in the message" do
      assert {:error, %Error{} = error} = Transport.accept([%{name: "photo.jpg", path: "/tmp/a"}])
      assert error.reason == :not_a_backup
      assert error.message =~ "photo.jpg"
      assert error.details.picked == ["photo.jpg"]
    end

    test "an empty pick is refused rather than crashing" do
      assert {:error, %Error{reason: :not_a_backup}} = Transport.accept([])
    end

    test "a provider-internal document id is not mistaken for a backup" do
      # What the picker returned before `K-20 file-picker-display-name`. The
      # bug ran the other way — a real backup rejected — but the guard has to
      # hold in both directions.
      refute Transport.backup?(%{name: "msf:1000000123"})
      refute Transport.backup?(%{name: "primary:Download/kati-backup-2026-08-21"})
      refute Transport.backup?(%{})
      refute Transport.backup?(%{name: nil})
    end
  end

  describe "restore through the same door" do
    test "a staged export picked back up is read row for row", %{dir: dir, tracked: tracked} do
      assert {:ok, staged} = Transport.stage(dir: dir, date: ~D[2026-08-21])
      picked = [%{name: staged.filename, path: staged.path, mime: "application/octet-stream"}]

      # :merge over a database that still holds these exact rows, so every row
      # is recognised and skipped. Asserting on the SKIP counts rather than on
      # `:ok` is what proves the file was read and matched: a truncated or
      # empty archive would skip nothing.
      assert {:ok, report} = Transport.restore(picked, mode: :merge)

      assert report.skipped["tracked_titles"] == staged.record_counts["tracked_titles"]
      assert report.skipped["tracked_titles"] >= 1
      assert report.total_inserted == 0

      # ...and the row itself is untouched, which is what "never silently
      # overwritten" means in practice.
      assert {:ok, after_restore} = Ash.get(Kati.Media.TrackedTitle, tracked.id)
      assert after_restore.rating == tracked.rating
      assert after_restore.last_touched_at == tracked.last_touched_at
    end

    test "restoring the wrong file refuses before the archive reader sees it" do
      assert {:error, %Error{reason: :not_a_backup}} =
               Transport.restore([%{name: "photo.jpg", path: "/tmp/nope"}], mode: :merge)
    end
  end
end
