defmodule Kati.BackupExportsTest do
  @moduledoc """
  The two export formats: per-section CSV and calendar `.ics`.

  Both are built from the bundle `Kati.Backup.Export` reads, so a value cannot
  differ between the three files a user could export on the same afternoon.
  """
  use ExUnit.Case, async: true

  doctest Kati.Backup.Exports

  alias Kati.Backup
  alias Kati.Backup.Exports

  describe "csv/1" do
    test "a header, the rows, and CRLF" do
      rows = [%{b: 1, a: "one"}, %{a: "two", b: 2}]
      csv = Exports.csv(rows)

      assert String.starts_with?(csv, "a,b\r\n")
      assert csv =~ "one,1\r\n"
      assert csv =~ "two,2\r\n"
    end

    test "a field with a comma, a quote or a newline is quoted, and quotes double" do
      csv = Exports.csv([%{note: "a,b", quote: "he said \"no\"", line: "one\ntwo"}])
      [header, row] = String.split(csv, "\r\n", parts: 2)

      assert header == "line,note,quote"
      assert row =~ ~s("one\ntwo")
      assert row =~ ~s("a,b")
      assert row =~ ~s("he said ""no""")
    end

    test "nil is an empty field" do
      assert Exports.csv([%{a: nil, b: 1}]) == "a,b\r\n,1\r\n"
    end
  end

  describe "ics/1" do
    test "one VEVENT with its UID, summary and UTC instant" do
      ics =
        Exports.ics([
          %{
            "uid" => "standup@kati",
            "summary" => "Standup; daily",
            "dtstart_utc" => "2026-11-25T09:00:00Z",
            "dtend_utc" => "2026-11-25T09:30:00Z",
            "description" => "line one, line two"
          }
        ])

      assert String.starts_with?(ics, "BEGIN:VCALENDAR\r\n")
      assert String.ends_with?(ics, "END:VCALENDAR\r\n")
      assert ics =~ "BEGIN:VEVENT\r\n"
      assert ics =~ "UID:standup@kati\r\n"
      assert ics =~ "DTSTART:20261125T090000Z\r\n"
      assert ics =~ "DTEND:20261125T093000Z\r\n"
      assert ics =~ "SUMMARY:Standup\\; daily\r\n"
      assert ics =~ "DESCRIPTION:line one\\, line two\r\n"
      assert ics =~ "DTSTAMP:"
    end

    test "an all-day event is a DATE, and its end is the next day" do
      ics =
        Exports.ics([
          %{"uid" => "a@kati", "summary" => "Birthday", "dtstart_date" => "2026-11-26"}
        ])

      assert ics =~ "DTSTART;VALUE=DATE:20261126\r\n"
      assert ics =~ "DTEND;VALUE=DATE:20261127\r\n"
    end
  end

  describe "the bundles" do
    test "CSV carries one file per table, and a manifest" do
      bundle = Backup.export(format: :csv)

      assert Map.has_key?(bundle.files, "manifest.json")
      assert Map.has_key?(bundle.files, "data/tracked_titles.csv")

      assert Jason.decode!(bundle.files["manifest.json"])["files"]
             |> Map.has_key?("data/tracked_titles.csv")

      assert %{"format" => "kati.backup"} = bundle.manifest
    end

    test "ICS carries one calendar file" do
      bundle = Backup.export(format: :ics)

      assert Map.has_key?(bundle.files, "data/calendar.ics")
      assert bundle.files["data/calendar.ics"] =~ "BEGIN:VCALENDAR"
    end

    test "the Save As… name follows the format" do
      date = ~D[2026-11-25]

      assert Backup.suggested_filename(date) == "kati-backup-2026-11-25.katibackup"
      assert Backup.suggested_filename(date, :csv) == "kati-backup-2026-11-25.zip"
      assert Backup.suggested_filename(date, :ics) == "kati-backup-2026-11-25.ics"
    end
  end
end
