defmodule Kati.Backup.Exports do
  @moduledoc """
  The two export formats that are not a backup: per-section CSV and calendar
  `.ics`.

  They are exports, not backups, and the difference is restore. A `.katibackup`
  is a zip of one JSON payload per table, hashed per payload, and it is the only
  file Kati can read back. CSV is for a spreadsheet or another app; `.ics` is
  for a calendar that is not Kati. Both are built from the same bundle
  `Kati.Backup.Export` reads, so a value cannot differ between the three files
  a user could export on the same afternoon.

  ## CSV, one file per table

  `data/<table>.csv`, header from the table's own columns, RFC 4180 quoting —
  a field is quoted only when it has to be (comma, quote, CR or LF), and its
  quotes are doubled. The order is the catalogue's, which is stable.

  ## ICS, one file for the calendar

  `data/calendar.ics`, one VEVENT per `events` row: the UID Kati already holds,
  the UTC start and end, or `DTSTART;VALUE=DATE` for an all-day event. The
  summary, description and location are text-escaped as the RFC requires.
  No VTIMEZONE: every instant is written in UTC, which needs none.
  """

  alias Kati.Backup.Bundle
  alias Kati.Backup.Catalog
  alias Kati.Backup.Export
  alias Kati.Backup.Manifest

  @doc """
  A bundle in one of the export-shaped formats — `:csv` or `:ics`.

  It carries the same manifest as the JSON bundle (so its counts are the same
  reading of the same tables) and a `files` map the zip writer already knows
  how to pack. Restoring one is not supported and fails honestly: the manifest
  names members this reader does not have.
  """
  @spec bundle(:csv | :ics) :: Bundle.t()
  def bundle(:csv), do: finish(csv_files(Export.bundle()))
  def bundle(:ics), do: finish(ics_files(Export.bundle()))

  defp csv_files(base) do
    Map.new(base.rows, fn {table, rows} -> {"data/#{table}.csv", csv(rows)} end)
  end

  defp ics_files(base) do
    %{"data/calendar.ics" => ics(Map.get(base.rows, "events", []))}
  end

  defp finish(files) do
    manifest = Manifest.build(files, %{}, %{})

    %Bundle{
      manifest: manifest,
      files: Map.put(files, "manifest.json", Jason.encode!(manifest)),
      rows: nil
    }
  end

  @doc """
  One table as CSV: a sorted header, then its rows, CRLF-separated.

      iex> Kati.Backup.Exports.csv([%{a: "x,y", b: 1}])
      "a,b\\r\\n\\"x,y\\",1\\r\\n"
  """
  @spec csv([map()]) :: binary()
  def csv([]), do: "\r\n"

  def csv(rows) do
    columns = rows |> Enum.flat_map(&Map.keys/1) |> Enum.uniq() |> Enum.sort()

    lines =
      Enum.map(rows, fn row ->
        Enum.map_join(columns, ",", fn column -> cell(Map.get(row, column)) end)
      end)

    Enum.join([Enum.map_join(columns, ",", &cell/1) | lines], "\r\n") <> "\r\n"
  end

  defp cell(nil), do: ""
  defp cell(value) when is_binary(value), do: quote_cell(value)
  defp cell(value) when is_atom(value), do: quote_cell(Atom.to_string(value))
  defp cell(value), do: quote_cell(to_string(value))

  defp quote_cell(value) do
    if String.contains?(value, [",", "\"", "\r", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end

  @doc """
  Calendar events as one iCalendar file.

  `DTSTAMP` is the moment of export — the only field that is not the row's own
  — and `UID` is the row's, so re-importing an export replaces rather than
  duplicates what a calendar already knows.
  """
  @spec ics([map()]) :: binary()
  def ics(events) do
    stamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%dT%H%M%SZ")

    body = Enum.map_join(events, "", &event(&1, stamp))

    "BEGIN:VCALENDAR\r\n" <>
      "VERSION:2.0\r\n" <>
      "PRODID:-//Kati//Kati Calendar//EN\r\n" <>
      "CALSCALE:GREGORIAN\r\n" <> body <> "END:VCALENDAR\r\n"
  end

  defp event(row, stamp) do
    uid = row["uid"] || row["id"]

    start =
      cond do
        is_binary(row["dtstart_date"]) and row["dtstart_date"] != "" ->
          "DTSTART;VALUE=DATE:" <> ical_date(row["dtstart_date"])

        is_binary(row["dtstart_utc"]) and row["dtstart_utc"] != "" ->
          "DTSTART:" <> ical_utc(row["dtstart_utc"])

        true ->
          nil
      end

    finish = finish_line(row)

    [
      "BEGIN:VEVENT\r\n",
      "UID:" <> text(to_string(uid)) <> "\r\n",
      "DTSTAMP:" <> stamp <> "\r\n",
      if(start, do: start <> "\r\n", else: ""),
      if(finish, do: finish <> "\r\n", else: ""),
      line("SUMMARY", row["summary"]),
      line("DESCRIPTION", row["description"]),
      line("LOCATION", row["location"]),
      "END:VEVENT\r\n"
    ]
    |> IO.iodata_to_binary()
  end

  # The end is the row's own end when it has one, and otherwise the duration
  # from its start. An event with neither is still an event; a calendar that
  # refused it because the end was missing would drop the reader's day.
  defp finish_line(row) do
    cond do
      is_binary(row["dtend_utc"]) and row["dtend_utc"] != "" ->
        "DTEND:" <> ical_utc(row["dtend_utc"])

      is_binary(row["dtstart_date"]) and row["dtstart_date"] != "" ->
        "DTEND;VALUE=DATE:" <> ical_date(Date.add(ical_date!(row["dtstart_date"]), 1))

      true ->
        nil
    end
  end

  defp line(_name, nil), do: ""
  defp line(_name, ""), do: ""
  defp line(name, value) when is_binary(value), do: name <> ":" <> text(value) <> "\r\n"
  defp line(name, value), do: line(name, to_string(value))

  # RFC 5545 §3.3.11: backslash, semicolon and comma escaped, newlines folded.
  defp text(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace(";", "\\;")
    |> String.replace(",", "\\,")
    |> String.replace("\r\n", "\\n")
    |> String.replace("\n", "\\n")
  end

  defp ical_date(%Date{} = date), do: date |> Date.to_iso8601() |> ical_date()
  defp ical_date(value), do: String.replace(value, "-", "")

  defp ical_date!(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _bad -> Date.utc_today()
    end
  end

  defp ical_utc(value) do
    with {:ok, naive, _offset} <- DateTime.from_iso8601(value) do
      Calendar.strftime(naive, "%Y%m%dT%H%M%SZ")
    else
      _bad -> String.replace(value, ["-", ":"], "") |> String.replace(" ", "T")
    end
  end

  @doc "The format's extension, for the Save As… dialog."
  @spec extension(:json | :csv | :ics) :: String.t()
  def extension(:json), do: Kati.Backup.extension()
  def extension(:csv), do: ".zip"
  def extension(:ics), do: ".ics"

  @doc "Every table this export reads — the catalogue's own list."
  @spec tables() :: [String.t()]
  def tables, do: Catalog.tables()
end
