defmodule Kati.BackupFormatTest do
  @moduledoc """
  The file format, with no database anywhere near it.

  Everything under `Kati.Backup` except the two ends — reading rows and writing
  them — is pure, and this is what proves it: the type table, the version rule,
  the container and the upgrade walker all run here with nothing started.

  The type table matters more than it looks. A column whose Ash type nobody
  taught the codec would be written as `null` by a careless implementation and
  come back empty for every user who restored, so `encode/2` raises instead —
  and that raise is asserted here rather than discovered in a support thread.
  """
  use ExUnit.Case, async: true

  alias Kati.Backup.Archive
  alias Kati.Backup.Bundle
  alias Kati.Backup.Catalog
  alias Kati.Backup.Codec
  alias Kati.Backup.Manifest
  alias Kati.Backup.Upgrade

  describe "the type table" do
    test "every type Kati's backed-up resources actually use round-trips" do
      cases = [
        {Ash.Type.UUID, [], "0189f0a1-2b3c-4d5e-8f90-1234567890ab"},
        {Ash.Type.String, [], "Miso salmon, greens & rice"},
        {Ash.Type.Integer, [], -42},
        {Ash.Type.Boolean, [], false},
        {Ash.Type.Date, [], ~D[2026-08-16]},
        {Ash.Type.Time, [], ~T[07:30:00.000000]},
        {Ash.Type.UtcDatetimeUsec, [], ~U[2026-08-16 05:30:00.123456Z]},
        {Ash.Type.UtcDatetime, [], ~U[2026-08-16 05:30:00Z]},
        {Ash.Type.Decimal, [], Decimal.new("12.3400")},
        {Ash.Type.Float, [], 1.5},
        {Ash.Type.Atom, [one_of: [:eaten, :skipped]], :skipped}
      ]

      # Guard against the list itself going empty and taking the loop with it.
      assert length(cases) == 11

      for {type, constraints, value} <- cases do
        encoded = Codec.encode_value(type, value)
        assert {:ok, ^value} = Codec.decode_value(type, constraints, encoded, :probe)
      end
    end

    test "every type used by a backed-up resource is one the codec knows" do
      used =
        Catalog.entries()
        |> Enum.flat_map(&Catalog.attributes/1)
        |> Enum.map(& &1.type)
        |> Enum.uniq()

      known = [
        Ash.Type.UUID,
        Ash.Type.String,
        Ash.Type.Integer,
        Ash.Type.Boolean,
        Ash.Type.Date,
        Ash.Type.Time,
        Ash.Type.UtcDatetimeUsec,
        Ash.Type.UtcDatetime,
        Ash.Type.Decimal,
        Ash.Type.Float,
        Ash.Type.Atom,
        # The codec encodes an array element by element through the rules for
        # its element type, so what has to be known is the ELEMENT type. Listed
        # explicitly rather than matched loosely: an array of something the
        # codec cannot write must still fail this test, not slip through on the
        # word "array".
        {:array, Ash.Type.Atom}
      ]

      assert used -- known == []
      assert length(used) >= 6
    end

    test "a type the codec has never seen raises rather than writing null" do
      assert_raise Kati.Backup.Error, ~r/no encoding is defined/, fn ->
        Codec.encode_value(Ash.Type.Map, %{a: 1}, :something_new)
      end
    end

    test "nil survives, and a null in a not-null column is a readable refusal" do
      # Real attributes off a real resource: `note` is nullable on a meal log
      # and `title` is the frozen name, which may not be.
      nullable = Ash.Resource.Info.attribute(Kati.Meals.MealLog, :note)
      required = Ash.Resource.Info.attribute(Kati.Meals.MealLog, :title)

      assert nullable.allow_nil?
      refute required.allow_nil?

      assert Codec.encode(nullable, nil) == nil
      assert Codec.decode(nullable, nil) == {:ok, nil}
      assert {:error, message} = Codec.decode(required, nil)
      assert message =~ "title"
    end

    test "a decimal goes out as a string, so nothing rounds it on the way back" do
      encoded = Codec.encode_value(Ash.Type.Decimal, Decimal.new("0.1"))

      assert encoded == "0.1"
      assert is_binary(encoded)
    end
  end

  describe "dates in the file" do
    test "are ISO-8601 with ASCII digits, whatever the app's locale draws" do
      assert Codec.encode_value(Ash.Type.Date, ~D[2026-08-16]) == "2026-08-16"
      assert Codec.encode_value(Ash.Type.Time, ~T[21:40:00.000000]) == "21:40:00.000000"

      assert Codec.encode_value(Ash.Type.UtcDatetimeUsec, ~U[2026-08-16 19:40:00.000000Z]) ==
               "2026-08-16T19:40:00.000000Z"
    end

    test "a Jalali-looking date with Persian digits is refused, not guessed at" do
      # ۱۴۰۵-۰۵-۲۵ — what screen 60 draws, and what must never reach a file.
      assert {:error, message} =
               Codec.decode_value(Ash.Type.Date, [], "۱۴۰۵-۰۵-۲۵", :dtstart_date)

      assert message =~ "dtstart_date"
    end

    test "an instant written with an offset comes back as the same instant in UTC" do
      assert {:ok, decoded} =
               Codec.decode_value(Ash.Type.UtcDatetimeUsec, [], "2026-08-16T21:40:00+02:00")

      assert decoded == ~U[2026-08-16 19:40:00Z]
    end
  end

  describe "atoms from a file" do
    test "a value outside a one_of constraint is refused, and no atom is made" do
      assert {:error, message} =
               Codec.decode_value(
                 Ash.Type.Atom,
                 [one_of: [:eaten, :skipped, :planned]],
                 "kati_backup_never_a_real_state",
                 :state
               )

      assert message =~ "state"
      assert message =~ "eaten"

      assert_raise ArgumentError, fn ->
        String.to_existing_atom("kati_backup_never_a_real_state")
      end
    end

    test "a constraint-free column takes a name that looks like one, and nothing else" do
      assert {:ok, :accent} = Codec.decode_value(Ash.Type.Atom, [], "accent", :colour_token)

      assert {:error, message} =
               Codec.decode_value(Ash.Type.Atom, [], "not an atom!", :colour_token)

      assert message =~ "colour_token"
    end
  end

  describe "the version rule" do
    test "a manifest of this version passes" do
      assert {:ok, _} = Manifest.parse(manifest())
    end

    test "a newer schema version is refused with both numbers, not partly read" do
      assert {:error, error} =
               Manifest.parse(%{manifest() | "schema_version" => Catalog.schema_version() + 1})

      assert error.reason == :unsupported_schema_version
      assert error.message =~ "newer version of Kati"
      assert error.message =~ "#{Catalog.schema_version() + 1}"
      assert error.message =~ "Nothing has been changed"
    end

    test "a newer file format is refused too" do
      assert {:error, error} =
               Manifest.parse(%{manifest() | "format_version" => Catalog.format_version() + 1})

      assert error.reason == :unsupported_format
    end

    test "something that is not a Kati backup at all is refused first" do
      assert {:error, error} = Manifest.parse(%{manifest() | "format" => "some.other.app"})
      assert error.reason == :unsupported_format

      assert {:error, %{reason: :bad_manifest}} = Manifest.parse(Map.delete(manifest(), "files"))
      assert {:error, %{reason: :bad_manifest}} = Manifest.parse("not a map")
    end

    test "a missing or nonsense version is a bad manifest, not a zero" do
      assert {:error, %{reason: :bad_manifest}} =
               Manifest.parse(Map.delete(manifest(), "schema_version"))

      assert {:error, %{reason: :bad_manifest}} =
               Manifest.parse(%{manifest() | "schema_version" => "one"})

      assert {:error, %{reason: :bad_manifest}} =
               Manifest.parse(%{manifest() | "schema_version" => 0})
    end

    test "a built manifest carries everything #64 requires of it" do
      built = Manifest.build(%{"data/events.json" => "[]"}, %{"events" => 0}, %{})

      assert built["format"] == "kati.backup"
      assert is_integer(built["schema_version"])
      assert is_integer(built["format_version"])
      assert built["app_version"] =~ ~r/\A(\d+\.\d+\.\d+|unknown)\z/
      assert {:ok, _, _} = DateTime.from_iso8601(built["exported_at"])
      assert built["exported_at"] =~ "Z"
      assert built["record_counts"] == %{"events" => 0}

      assert built["files"]["data/events.json"] == %{
               "sha256" => Archive.sha256("[]"),
               "bytes" => 2
             }
    end
  end

  describe "the container" do
    test "packs and unpacks the same bytes" do
      files = %{"manifest.json" => "{}", "data/events.json" => "[1,2,3]"}
      binary = Archive.pack(%Bundle{manifest: %{}, files: files})

      assert {:ok, ^files} = Archive.unpack(binary)
    end

    test "a file that is not a zip is a sentence, not a crash" do
      assert {:error, error} = Archive.unpack("this is a text file")
      assert error.reason == :unreadable_archive
      assert error.message =~ "not a Kati backup"

      assert {:error, %{reason: :not_a_backup}} = Archive.unpack(:not_even_a_binary)
    end

    test "an archive that expands past the cap is refused before it is expanded" do
      files = %{"manifest.json" => "{}", "data/events.json" => String.duplicate("x", 5_000)}
      binary = Archive.pack(%Bundle{manifest: %{}, files: files})

      # The real cap is 256MB; the point of the test is that the guard reads
      # the *uncompressed* size — 5 000 bytes here, out of a 200-byte archive —
      # rather than the size of the file on disk.
      assert byte_size(binary) < 1_000
      assert Archive.max_uncompressed_bytes() == 256 * 1024 * 1024

      assert {:error, error} = Archive.unpack(binary, max_uncompressed_bytes: 1_000)
      assert error.reason == :unreadable_archive
      assert error.message =~ "5"
      assert error.details.uncompressed_bytes == 5_002

      assert {:ok, ^files} = Archive.unpack(binary, max_uncompressed_bytes: 10_000)
    end

    test "the checksum changes when a single byte does" do
      refute Archive.sha256("hello") == Archive.sha256("hellp")
      assert String.length(Archive.sha256("hello")) == 64
    end
  end

  describe "the upgrade walker" do
    test "a file already at the current version is left alone" do
      rows = %{"events" => [%{"id" => "x"}]}
      assert {:ok, ^rows} = Upgrade.walk(rows, Catalog.schema_version())
    end

    # The composition and gap tests pass their own steps rather than the real
    # chain, because one real step cannot demonstrate either property. They are
    # about `walk/4` itself; the tests below are about the steps Kati ships.
    test "steps compose, oldest first" do
      steps = [
        {1, 2, fn rows -> Map.put(rows, "trail", ["one-two"]) end},
        {2, 3, fn rows -> Map.update!(rows, "trail", &(&1 ++ ["two-three"])) end}
      ]

      assert {:ok, upgraded} = Upgrade.walk(%{}, 1, 3, steps)
      assert upgraded["trail"] == ["one-two", "two-three"]
    end

    test "a gap in the chain stops the walk rather than skipping a shape" do
      steps = [{1, 2, &Function.identity/1}]

      assert {:error, %{reason: :unsupported_schema_version}} = Upgrade.walk(%{}, 1, 3, steps)
    end

    test "a version with no path forward is refused, not silently accepted" do
      assert {:error, error} = Upgrade.walk(%{}, 99, [])
      assert error.reason == :unsupported_schema_version
      assert error.message =~ "99"
      assert error.message =~ "Nothing has been changed"
    end
  end

  describe "the steps Kati ships" do
    test "the chain is unbroken from every version that has ever been written" do
      assert Catalog.schema_version() == 5

      froms = Enum.map(Upgrade.steps(), fn {from, _to, _fun} -> from end)
      tos = Enum.map(Upgrade.steps(), fn {_from, to, _fun} -> to end)

      assert froms == Enum.to_list(1..(Catalog.schema_version() - 1))
      assert tos == Enum.to_list(2..Catalog.schema_version())

      # Every version ever shipped reaches today, through the real steps.
      for from <- 1..Catalog.schema_version() do
        assert {:ok, _} = Upgrade.walk(%{}, from), "no path forward from schema version #{from}"
      end
    end

    test "1 -> 2 supplies the rejected-changes table a version-1 file never had" do
      v1 = %{"events" => [%{"id" => "e"}], "media_watches" => []}

      # `walk/4` with the destination spelled out, so this stays a test of the
      # 1 -> 2 step. `walk/2` runs every step up to today's version, and once a
      # later step also adds a table the "+1" below would be counting all of
      # them.
      assert {:ok, upgraded} = Upgrade.walk(v1, 1, 2, Upgrade.steps())

      # The member the v2 readers fetch by name is there, and empty.
      assert upgraded["sync_rejected_changes"] == []

      # And nothing else moved.
      assert upgraded["events"] == [%{"id" => "e"}]
      assert upgraded["media_watches"] == []
      assert map_size(upgraded) == map_size(v1) + 1
    end

    test "1 -> 2 never replaces rows that are already there" do
      row = %{"id" => "r", "event_uid" => "standup@kati"}

      assert {:ok, upgraded} =
               Upgrade.walk(%{"sync_rejected_changes" => [row]}, 1, 2, Upgrade.steps())

      assert upgraded["sync_rejected_changes"] == [row]
    end

    test "2 -> 3 supplies the two content-warning tables a version-2 file never had" do
      v2 = %{"events" => [%{"id" => "e"}], "media_watches" => []}

      assert {:ok, upgraded} = Upgrade.walk(v2, 2, 3, Upgrade.steps())

      assert upgraded["media_content_warnings"] == []
      assert upgraded["media_warning_preferences"] == []
      assert map_size(upgraded) == map_size(v2) + 2
    end

    test "a version-2 watch restores with no moods rather than failing" do
      # The half that needs NO step, and the reason: a missing table raises
      # because `Kati.Backup.Restore` does `Map.fetch!/2` per table, and a
      # missing COLUMN does not — `Ash.Seed.seed!/2` takes a plain map, so the
      # attribute default applies. `moods` defaults to `[]`.
      v2_watch = %{"id" => "w", "rating" => 8}

      assert {:ok, upgraded} =
               Upgrade.walk(%{"media_watches" => [v2_watch]}, 2, 3, Upgrade.steps())

      assert upgraded["media_watches"] == [v2_watch]
      refute Map.has_key?(hd(upgraded["media_watches"]), "moods")
    end

    test "the table it supplies is one the catalog actually carries" do
      # If the promotion were ever reverted without the step going with it, the
      # step would be inventing a table `Kati.Backup.Verify` then refuses.
      assert {:ok, upgraded} = Upgrade.walk(%{}, 1)

      assert Map.keys(upgraded) -- Catalog.tables() == []
      assert "sync_rejected_changes" in Catalog.tables()
    end
  end

  describe "the published JSON Schema" do
    test "both schemas parse, and say what they are" do
      for name <- ~w(manifest payload) do
        schema = schema(name)
        assert schema["$schema"] =~ "json-schema.org"
        assert schema["type"] == "object"
        assert schema["additionalProperties"] == false
        assert is_binary(schema["description"])
      end
    end

    test "the manifest schema requires exactly the keys the exporter writes" do
      built = Manifest.build(%{"data/events.json" => "[]"}, %{"events" => 0}, %{})
      schema = schema("manifest")

      assert Enum.sort(schema["required"]) == Enum.sort(Map.keys(built))
      assert Enum.sort(Map.keys(schema["properties"])) == Enum.sort(Map.keys(built))
      assert schema["properties"]["format"]["const"] == Catalog.format()
    end

    test "the schemas are committed where the format document points" do
      doc = File.read!("docs/backup-format.md")

      assert doc =~ "backup/manifest.schema.json"
      assert doc =~ "backup/payload.schema.json"
    end
  end

  defp schema(name), do: File.read!("docs/backup/#{name}.schema.json") |> Jason.decode!()

  defp manifest do
    %{
      "format" => "kati.backup",
      "format_version" => Catalog.format_version(),
      "schema_version" => Catalog.schema_version(),
      "app_version" => "0.1.2",
      "exported_at" => "2026-08-21T09:00:00.000000Z",
      "record_counts" => %{"events" => 0},
      "dropped_columns" => %{},
      "files" => %{}
    }
  end
end
