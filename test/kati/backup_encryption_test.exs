defmodule Kati.BackupEncryptionTest do
  @moduledoc """
  Opt-in passphrase encryption, against the same real SQLite file the rest of
  the schema tests use.

  Four things here would each pass a careless test and be a defect anyway, so
  each is asserted on content rather than on a call returning `:ok`:

    * **Encryption encrypts.** A zip stores its member names in the clear, so
      the plaintext archive literally contains `data/media_watches.json`. The
      encrypted file must not, and it must not open as a zip at all. Without
      that pair, "round trip" would pass over a function that returned its
      argument.
    * **A wrong passphrase is an authentication failure**, `:bad_passphrase`,
      and specifically **not** `:unreadable_archive` or `:checksum_mismatch`.
      Those are the honest sentence and the dishonest one: "your passphrase is
      wrong" is actionable, and "this file is damaged" sends a user hunting for
      another copy of a file that was fine. The refutations are the test.
    * **A flipped byte in the ciphertext is the same authentication failure**,
      caught by the GCM tag before a single byte reaches the unzipper — never
      plausible junk that then fails to parse.
    * **The cost parameter is read from the file, not compiled in.** A backup
      sealed at a lower iteration count still opens on a reader whose default
      is higher, which is the whole reason the number is in the header.

  The round trips assert positive counts before comparing, so "everything came
  back" cannot mean "both sides were empty".
  """
  use ExUnit.Case, async: false

  alias Kati.Backup
  alias Kati.Backup.Archive
  alias Kati.Backup.Catalog
  alias Kati.Backup.Envelope
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  @passphrase "شب‌های تابستان — correct horse battery staple"
  @wrong_passphrase "شب‌های تابستان — correct horse battery stapler"

  # The three things that break a naive serialiser — a quote, a comma and a
  # newline — so the round trip is a round trip of something awkward.
  @review "She said \"it's fine\", then,\nafter a beat, it was not. دیدم ۱۲ مرداد"

  # A substring of that review with nothing JSON has to escape, so it appears
  # byte for byte inside the payload file and can be honestly grepped for. The
  # full review does not: `"` becomes `\"` and the newline becomes `\n`.
  @needle "دیدم ۱۲ مرداد"

  # A zip stores its member names uncompressed in the central directory, so
  # this string is present verbatim in every plain `.katibackup` and must be
  # absent from every encrypted one.
  @member_name "data/media_watches.json"

  @tables Enum.reverse(Catalog.tables()) ++ ["bundled_foods", "licensed_foods", "cached_titles"]

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  # ── The round trip ─────────────────────────────────────────────────────────

  describe "an encrypted backup" do
    test "restores every row it carried, through a file on disk" do
      populate!()
      before_rows = rows()
      before_counts = counts()

      # So that "equal" below cannot mean "both empty".
      assert before_counts["tracked_titles"] == 1
      assert before_counts["media_watches"] == 2

      file = path("kati-backup.katibackup")

      assert {:ok, report} = Backup.export_to_file(file, passphrase: @passphrase)
      assert report.encrypted == true
      assert report.total_records == Enum.sum(Map.values(before_counts))

      empty_the_tables!()
      assert Enum.all?(Map.values(counts()), &(&1 == 0))

      assert {:ok, restored} = Backup.restore_file(file, passphrase: @passphrase)
      assert restored.total_inserted == Enum.sum(Map.values(before_counts))
      assert counts() == before_counts
      assert rows() == before_rows

      # And the row content survived the trip through AES, not just the count.
      watches = Map.fetch!(rows(), "media_watches")
      assert @review in Enum.map(watches, & &1.review)
    end

    # OBSERVED ONCE, NOT REPRODUCED. This test failed in one full-suite run and
    # passed on re-run, in isolation at five seeds, and in seven later full runs.
    #
    # Chance is not the explanation: @needle is 25+ bytes of Persian, so
    # ciphertext containing it by accident is not a thing that happens. The
    # likely cause is the suite's shared database — there is NO Ecto sandbox,
    # every test writes the same SQLite file, and several tests truncate tables
    # they do not own. If one of those runs between `populate!()` and
    # `export()`, the plain backup has no needle to find and the assertion on
    # line 104 fails first.
    #
    # Checked and ruled out: no `async: true` test touches the database (the
    # three that name Kati.Repo only inspect source text), so it is not an
    # async race between files. Left recorded rather than "fixed" by weakening
    # an assertion — the real fix is a sandbox, and guessing at one would hide
    # the next occurrence.
    test "hides what a plain backup shows in the clear" do
      populate!()
      bundle = Backup.export()

      plain = Backup.to_binary(bundle)
      assert {:ok, sealed} = Backup.to_encrypted_binary(bundle, @passphrase)

      # The zip keeps its member names, and its payload, readable.
      assert String.contains?(plain, @member_name)
      assert {:ok, files} = Archive.unpack(plain)
      assert files |> Map.fetch!(@member_name) |> String.contains?(@needle)

      # The envelope keeps neither, and is not a zip at all.
      refute String.contains?(sealed, @member_name)
      refute String.contains?(sealed, @needle)
      assert {:error, %{reason: :unreadable_archive}} = Archive.unpack(sealed)

      # And it is exactly the same archive once opened — byte for byte.
      assert {:ok, ^plain} = Envelope.open(sealed, @passphrase)
    end

    test "shares no bytes with a second sealing of the same archive" do
      populate!()

      # Packed ONCE, and sealed twice — where this used to export twice and pin
      # the second plaintext against the first.
      #
      # That was a real failure roughly one run in four, and it was not the
      # envelope's: `:zip.create/3` stamps every member with the clock at the
      # moment it packs, in both the local header and the extended-timestamp
      # extra field. Two `Backup.to_binary/1` calls that straddle a second tick
      # therefore differ by two bytes per member, and the two archives are
      # genuinely not equal. Each sealing pays for a key derivation, so the two
      # exports were far enough apart to straddle a tick often — which read as
      # flakiness in the crypto and never as a clock in the zip.
      #
      # The claim being made here is about the envelope — same input, same
      # passphrase, a fresh salt and a fresh IV each time — so the input is now
      # held fixed instead of rebuilt. `Backup.to_encrypted_binary/2` is
      # `to_binary/1 |> Envelope.seal/2` and both tests above call it.
      plain = Backup.to_binary(Backup.export())

      assert {:ok, first} = Envelope.seal(plain, @passphrase)
      assert {:ok, second} = Envelope.seal(plain, @passphrase)

      # Same data, same passphrase, different salt and different IV — so the
      # two files reveal nothing by comparison, and neither can be replayed
      # against the other.
      assert first != second
      assert header_of(first)["salt"] != header_of(second)["salt"]
      assert header_of(first)["iv"] != header_of(second)["iv"]
      assert parts(first).ciphertext != parts(second).ciphertext

      # Both still open, and onto the archive that went in.
      assert {:ok, ^plain} = Envelope.open(first, @passphrase)
      assert {:ok, ^plain} = Envelope.open(second, @passphrase)
    end

    test "opens with the same passphrase typed in a different Unicode normalisation" do
      populate!()

      composed = "café pásswörd"
      decomposed = :unicode.characters_to_nfd_binary(composed)

      # The same text, and genuinely different bytes — which is what a Persian
      # or accented keyboard on the new phone can produce.
      assert composed != decomposed
      assert :unicode.characters_to_nfc_binary(decomposed) == composed

      assert {:ok, sealed} = Backup.to_encrypted_binary(Backup.export(), composed)
      assert {:ok, plain} = Envelope.open(sealed, decomposed)
      assert {:ok, ^plain} = Envelope.open(sealed, composed)
      assert header_of(sealed)["normalization"] == "nfc"
    end
  end

  # ── A wrong passphrase ─────────────────────────────────────────────────────

  describe "a passphrase that is not the one" do
    test "fails as authentication, not as a damaged file, and writes nothing" do
      sealed = populate_and_seal()
      empty_the_tables!()

      assert {:error, error} = Backup.restore_binary(sealed, passphrase: @wrong_passphrase)

      assert error.reason == :bad_passphrase
      assert error.message =~ "passphrase"

      # The dishonest answers. Each of these would send the user looking for
      # another copy of a file that is perfectly fine.
      refute error.reason in [:unreadable_archive, :not_a_backup, :checksum_mismatch]
      refute error.message =~ "damaged"

      assert Enum.all?(Map.values(counts()), &(&1 == 0))
    end

    test "is refused before the archive is ever opened" do
      sealed = populate_and_seal()

      # One character shorter than the real one: near-miss typing, not garbage.
      almost = String.slice(@passphrase, 0..-2//1)
      assert almost != @passphrase

      assert {:error, %{reason: :bad_passphrase}} = Envelope.open(sealed, almost)
    end

    test "an empty one is refused as unusable rather than used" do
      sealed = populate_and_seal()

      for blank <- ["", "   ", "\n"] do
        assert {:error, error} = Backup.restore_binary(sealed, passphrase: blank)
        assert error.reason == :unusable_passphrase
      end

      # And an export cannot be "encrypted" with nothing.
      assert {:error, %{reason: :unusable_passphrase}} =
               Backup.to_encrypted_binary(Backup.export(), "")
    end

    test "no passphrase at all says the file is encrypted, not that it is broken" do
      sealed = populate_and_seal()

      assert {:error, error} = Backup.restore_binary(sealed)
      assert error.reason == :passphrase_required
      assert error.message =~ "encrypted"
      refute error.reason == :unreadable_archive
    end
  end

  # ── Tampering ──────────────────────────────────────────────────────────────

  describe "one flipped byte" do
    test "in the ciphertext fails authentication rather than producing junk" do
      sealed = populate_and_seal()
      empty_the_tables!()

      parts = parts(sealed)
      corrupt = rebuild(%{parts | ciphertext: flip(parts.ciphertext)})

      assert byte_size(corrupt) == byte_size(sealed)
      assert corrupt != sealed

      # The right passphrase, and it still refuses — at the tag, before a byte
      # of the archive is handed to the unzipper.
      assert {:error, error} = Backup.restore_binary(corrupt, passphrase: @passphrase)
      assert error.reason == :bad_passphrase
      refute error.reason in [:unreadable_archive, :checksum_mismatch, :bad_manifest]

      assert Enum.all?(Map.values(counts()), &(&1 == 0))
    end

    test "in the tag fails authentication" do
      sealed = populate_and_seal()

      parts = parts(sealed)
      corrupt = rebuild(%{parts | tag: flip(parts.tag)})

      assert {:error, %{reason: :bad_passphrase}} = Envelope.open(corrupt, @passphrase)
    end

    test "in the header fails authentication, because the header is the AAD" do
      sealed = populate_and_seal()

      # `created_at` feeds neither the key nor the IV — it is only ever the
      # additional authenticated data. Editing it must still be caught, or the
      # readable part of the file would be forgeable.
      edited =
        edit_header(sealed, &Map.put(&1, "created_at", "1999-01-01T00:00:00.000000Z"))

      assert header_of(edited)["salt"] == header_of(sealed)["salt"]
      assert header_of(edited)["iv"] == header_of(sealed)["iv"]
      assert parts(edited).ciphertext == parts(sealed).ciphertext

      assert {:error, %{reason: :bad_passphrase}} = Envelope.open(edited, @passphrase)
    end

    test "a file cut short is a damaged file, which is a different sentence" do
      sealed = populate_and_seal()
      head = binary_part(sealed, 0, 8 + 4 + 10)

      assert {:error, error} = Backup.restore_binary(head, passphrase: @passphrase)
      assert error.reason == :unreadable_archive
      assert error.message =~ "encrypted"
      assert error.message =~ "cut short"
      refute error.reason == :bad_passphrase
    end
  end

  # ── Both forms, detected from the bytes ────────────────────────────────────

  describe "an unencrypted backup" do
    test "still restores, and still restores when a passphrase is in hand" do
      populate!()
      before_rows = rows()
      before_counts = counts()
      assert before_counts["media_watches"] == 2

      file = path("plain.katibackup")
      assert {:ok, report} = Backup.export_to_file(file)
      assert report.encrypted == false

      # It is the zip it always was.
      assert {:ok, files} = file |> File.read!() |> Archive.unpack()
      assert Map.has_key?(files, @member_name)
      refute Envelope.encrypted?(File.read!(file))

      empty_the_tables!()
      assert {:ok, _} = Backup.restore_file(file)
      assert counts() == before_counts
      assert rows() == before_rows

      # A user who typed a passphrase for a file that turns out not to need one
      # gets their data back, not a lecture.
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_file(file, passphrase: @passphrase)
      assert rows() == before_rows
    end

    test "and an encrypted one are told apart without the user saying which" do
      populate!()
      bundle = Backup.export()

      plain = Backup.to_binary(bundle)
      assert {:ok, sealed} = Backup.to_encrypted_binary(bundle, @passphrase)

      refute Envelope.encrypted?(plain)
      assert Envelope.encrypted?(sealed)
      refute Envelope.encrypted?("")
      refute Envelope.encrypted?("PK")
      refute Envelope.encrypted?(:crypto.strong_rand_bytes(64))
    end
  end

  # ── Identifying a file nobody has unlocked ─────────────────────────────────

  describe "inspect_file/1 without the passphrase" do
    test "says this is an encrypted Kati backup, and which version" do
      populate!()
      file = path("kati-backup.katibackup")
      assert {:ok, _} = Backup.export_to_file(file, passphrase: @passphrase)

      assert {:ok, summary} = Backup.inspect_file(file)

      assert summary.encrypted == true
      assert summary.unlocked == false
      assert summary.encryption.envelope_version == Envelope.envelope_version()
      assert summary.encryption.cipher == "aes-256-gcm"
      assert summary.encryption.kdf == "pbkdf2-hmac-sha512"
      assert summary.encryption.iterations == Envelope.iterations()
      assert summary.encryption.supported == true
      assert %DateTime{} = summary.encryption.created_at

      # And it is honest about what it cannot see: the counts are inside the
      # ciphertext, so they are nil rather than zero. Zero would be a lie a
      # confirmation screen would print.
      assert summary.record_counts == nil
      assert summary.total_records == nil
      assert summary.schema_version == nil
    end

    test "shows the counts too once the passphrase is given" do
      populate!()
      before_counts = counts()
      assert before_counts["media_watches"] == 2

      file = path("kati-backup.katibackup")
      assert {:ok, _} = Backup.export_to_file(file, passphrase: @passphrase)

      assert {:ok, summary} = Backup.inspect_file(file, passphrase: @passphrase)

      assert summary.encrypted == true
      assert summary.unlocked == true
      assert summary.record_counts == before_counts
      assert summary.total_records == Enum.sum(Map.values(before_counts))
      assert summary.schema_version == Catalog.schema_version()
      assert summary.encryption.cipher == "aes-256-gcm"
    end

    test "an unencrypted file says so, and still reads as it always did" do
      populate!()
      before_counts = counts()
      file = path("plain.katibackup")
      assert {:ok, _} = Backup.export_to_file(file)

      assert {:ok, summary} = Backup.inspect_file(file)

      assert summary.encrypted == false
      assert summary.unlocked == true
      assert summary.encryption == nil
      assert summary.record_counts == before_counts
      assert summary.total_records == Enum.sum(Map.values(before_counts))
    end

    test "a file that is neither is still refused" do
      file = path("holiday.jpg")
      File.write!(file, :crypto.strong_rand_bytes(4096))

      assert {:error, error} = Backup.inspect_file(file)
      assert error.reason in [:not_a_backup, :unreadable_archive]
    end

    test "a wrong passphrase on inspect is an authentication failure, not a bad file" do
      populate!()
      file = path("kati-backup.katibackup")
      assert {:ok, _} = Backup.export_to_file(file, passphrase: @passphrase)

      assert {:error, %{reason: :bad_passphrase}} =
               Backup.inspect_file(file, passphrase: @wrong_passphrase)
    end
  end

  # ── The header is the compatibility contract ───────────────────────────────

  describe "the header" do
    test "records the cost, so raising it later does not orphan this file" do
      populate!()
      before_rows = rows()
      assert map_size(before_rows) == 23

      # Sealed at a cost lower than this app's default, exactly as a backup
      # written two Kati versions ago would have been.
      cheap = 100_000
      assert cheap < Envelope.iterations()

      assert {:ok, sealed} =
               Backup.export()
               |> Backup.to_binary()
               |> Envelope.seal(@passphrase, iterations: cheap)

      assert header_of(sealed)["iterations"] == cheap

      # The reader takes the number from the file, not from its own default.
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_binary(sealed, passphrase: @passphrase)
      assert rows() == before_rows
    end

    test "an envelope version this app does not know is refused, and says so" do
      sealed = populate_and_seal()
      future = edit_header(sealed, &Map.put(&1, "envelope_version", 99))

      assert {:error, error} = Backup.restore_binary(future, passphrase: @passphrase)
      assert error.reason == :unsupported_encryption
      assert error.message =~ "newer version of Kati"
      assert error.message =~ "99"
      refute error.reason == :bad_passphrase

      # And it still identifies itself, which is the whole point of a readable
      # header — the user is told to update Kati, not that their file is junk.
      assert {:ok, summary} = Backup.inspect_binary(future)
      assert summary.encrypted == true
      assert summary.encryption.envelope_version == 99
      assert summary.encryption.supported == false
    end

    test "a cipher or KDF Kati does not implement is refused by name" do
      sealed = populate_and_seal()
      swapped = edit_header(sealed, &Map.put(&1, "kdf", "scrypt"))

      assert {:error, error} = Backup.restore_binary(swapped, passphrase: @passphrase)
      assert error.reason == :unsupported_encryption
      assert error.message =~ "scrypt"
    end

    test "a cost outside what Kati will run is refused rather than attempted" do
      sealed = populate_and_seal()

      for absurd <- [1, 0, -1, 1_000_000_000, "many", nil] do
        edited = edit_header(sealed, &Map.put(&1, "iterations", absurd))

        assert {:error, %{reason: :unsupported_encryption}} =
                 Envelope.open(edited, @passphrase),
               "#{inspect(absurd)} rounds was accepted"
      end
    end

    test "a salt or IV of the wrong size is refused rather than padded" do
      sealed = populate_and_seal()

      for {key, value} <- [
            {"salt", Base.encode64("short")},
            {"iv", Base.encode64("short")},
            {"salt", "not base64 at all!!"},
            {"iv", nil}
          ] do
        edited = edit_header(sealed, &Map.put(&1, key, value))

        assert {:error, error} = Envelope.open(edited, @passphrase)
        assert error.reason == :unsupported_encryption
        assert error.message =~ key
      end
    end
  end

  # ── The copy taken before a :replace ───────────────────────────────────────

  describe "the safety export" do
    test "inherits the passphrase, so a replace does not leave the old data in the clear" do
      # A different backup, encrypted, coming in from elsewhere.
      incoming = path("incoming.katibackup")
      other = create!(TrackedTitle, :create, %{source: :tmdb, source_id: "1726", kind: :movie})
      assert {:ok, _} = Backup.export_to_file(incoming, passphrase: @passphrase)
      empty_the_tables!()

      # What the phone holds now, and is about to lose.
      populate!()
      old_rows = rows()
      assert counts()["media_watches"] == 2

      safety = path("before-restore.katibackup")

      assert {:ok, report} =
               Backup.restore_file(incoming,
                 mode: :replace,
                 safety_export_path: safety,
                 passphrase: @passphrase
               )

      assert report.safety_export == safety
      assert counts()["tracked_titles"] == 1
      assert {:ok, restored} = Ash.get(TrackedTitle, other.id)
      assert restored.source_id == "1726"

      # The copy of the old data is encrypted with the same passphrase, and it
      # is a real backup: it restores.
      copy = File.read!(safety)
      assert Envelope.encrypted?(copy)
      refute String.contains?(copy, @needle)

      assert {:ok, summary} = Backup.inspect_file(safety)
      assert summary.encrypted == true
      assert summary.unlocked == false

      empty_the_tables!()
      assert {:ok, _} = Backup.restore_file(safety, passphrase: @passphrase)
      assert rows() == old_rows
    end

    test "is written in the clear when the restore needed no passphrase" do
      incoming = path("incoming.katibackup")
      create!(TrackedTitle, :create, %{source: :tmdb, source_id: "1726", kind: :movie})
      assert {:ok, _} = Backup.export_to_file(incoming)
      empty_the_tables!()

      populate!()
      old_rows = rows()
      assert counts()["media_watches"] == 2
      safety = path("before-restore.katibackup")

      assert {:ok, _} =
               Backup.restore_file(incoming, mode: :replace, safety_export_path: safety)

      refute Envelope.encrypted?(File.read!(safety))

      empty_the_tables!()
      assert {:ok, _} = Backup.restore_file(safety)
      assert rows() == old_rows
    end
  end

  # ── Fixtures and helpers ───────────────────────────────────────────────────

  defp populate! do
    tracked =
      create!(TrackedTitle, :create, %{
        source: :tmdb,
        source_id: "603",
        kind: :movie,
        status: :finished,
        rating: 9
      })

    create!(Watch, :create, %{
      tracked_title_id: tracked.id,
      watched_on: ~D[2026-08-12],
      watched_at: ~U[2026-08-12 19:40:00.000000Z],
      rating: 9,
      review: @review,
      companions: "Jo, Sam",
      service: "Lumen+"
    })

    create!(Watch, :create, %{
      tracked_title_id: tracked.id,
      watched_on: ~D[2026-08-03],
      review: "دیدم ۱۲ مرداد — ۹ از ۱۰"
    })

    tracked
  end

  defp populate_and_seal do
    populate!()
    {:ok, sealed} = Backup.to_encrypted_binary(Backup.export(), @passphrase)
    sealed
  end

  defp create!(resource, action, attrs) do
    resource |> Ash.Changeset.for_create(action, attrs) |> Ash.create!()
  end

  defp rows, do: Backup.export().rows

  defp counts do
    Map.new(Catalog.entries(), fn entry -> {entry.table, Ash.count!(entry.resource)} end)
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  defp path(name) do
    dir = Path.join(System.tmp_dir!(), "kati_crypt_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    Path.join(dir, name)
  end

  # The envelope, taken apart by hand rather than through the module under
  # test, so a bug in `split/1` cannot hide behind the tests that use it.
  defp parts(binary) do
    <<"KATIENC\0", length::unsigned-big-32, rest::binary>> = binary
    <<header::binary-size(^length), tag::binary-size(16), ciphertext::binary>> = rest
    %{header: header, tag: tag, ciphertext: ciphertext}
  end

  defp rebuild(%{header: header, tag: tag, ciphertext: ciphertext}) do
    "KATIENC\0" <> <<byte_size(header)::unsigned-big-32>> <> header <> tag <> ciphertext
  end

  defp header_of(binary), do: binary |> parts() |> Map.fetch!(:header) |> Jason.decode!()

  defp edit_header(binary, fun) do
    parts = parts(binary)
    edited = parts.header |> Jason.decode!() |> fun.() |> Jason.encode!()
    rebuild(%{parts | header: edited})
  end

  # Flip the low bit of the byte in the middle. One bit, in one byte, in a file
  # of a few thousand.
  defp flip(binary) do
    offset = div(byte_size(binary), 2)
    <<head::binary-size(^offset), byte, tail::binary>> = binary
    head <> <<Bitwise.bxor(byte, 1)>> <> tail
  end
end
