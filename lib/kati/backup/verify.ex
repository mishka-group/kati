defmodule Kati.Backup.Verify do
  @moduledoc """
  Everything that can be known about a backup **before** the database is touched.

  #64's requirement is blunt: *"Restore verifies every hash and every count
  before any write; a corrupted payload is rejected with the database
  untouched."* This module is that pass, and it is the same pass whether the
  user is being shown the counts on a confirmation screen or is confirming the
  restore — one level of trust, not two, so a screen can never show numbers a
  restore would then reject.

  In order: the archive opens; the manifest is present, readable and of a
  version this app understands; the member list is exactly what the manifest
  claims, with no extra file smuggled in; every payload's SHA-256 and byte
  length match; every payload parses; rows are brought forward to the current
  schema version; every table is one this app knows; every row carries exactly
  the columns that table has, no more and no fewer; every value decodes to its
  column's type; no primary key appears twice; and the row counts agree with
  the manifest.

  Only then does the bundle come back with `rows` filled in — and
  `Kati.Backup.Restore` will not take a bundle whose `rows` are `nil`.
  """

  alias Kati.Backup.Archive
  alias Kati.Backup.Bundle
  alias Kati.Backup.Catalog
  alias Kati.Backup.Codec
  alias Kati.Backup.Error
  alias Kati.Backup.Export
  alias Kati.Backup.Manifest
  alias Kati.Backup.Upgrade

  @manifest_path "manifest.json"

  # How many bad values one error carries. Enough to fix a file by hand,
  # bounded so a wholly corrupt payload does not build a megabyte of message.
  @max_reported 20

  @doc "Open, check and decode a `.katibackup` binary."
  @spec bundle(binary()) :: {:ok, Bundle.t()} | {:error, Error.t()}
  def bundle(binary) do
    with {:ok, files} <- Archive.unpack(binary),
         {:ok, manifest} <- read_manifest(files),
         :ok <- check_members(files, manifest),
         :ok <- check_hashes(files, manifest),
         {:ok, payloads} <- parse_payloads(files, manifest),
         {:ok, upgraded} <- Upgrade.walk(payloads, Map.fetch!(manifest, "schema_version")),
         :ok <- check_tables(upgraded),
         {:ok, rows} <- decode_rows(upgraded),
         :ok <- check_counts(rows, manifest) do
      {:ok, %Bundle{manifest: manifest, files: files, rows: rows}}
    end
  end

  @doc """
  What a confirmation screen shows: versions, when it was written, and how many
  of what.

  Takes a **verified** bundle, so the counts it reports are counts of rows that
  are actually there and actually readable.
  """
  @spec summary(Bundle.t()) :: map()
  def summary(%Bundle{manifest: manifest, rows: rows}) when is_map(rows) do
    %{
      format_version: Map.fetch!(manifest, "format_version"),
      schema_version: Map.fetch!(manifest, "schema_version"),
      app_version: Map.get(manifest, "app_version", "unknown"),
      exported_at: Manifest.exported_at(manifest),
      record_counts: Map.new(rows, fn {table, list} -> {table, length(list)} end),
      total_records: rows |> Map.values() |> Enum.map(&length/1) |> Enum.sum(),
      dropped_columns: Map.get(manifest, "dropped_columns", %{})
    }
  end

  defp read_manifest(files) do
    with {:ok, bytes} <- fetch_file(files, @manifest_path),
         {:ok, decoded} <- decode_json(bytes, @manifest_path) do
      Manifest.parse(decoded)
    end
  end

  defp fetch_file(files, path) do
    case Map.fetch(files, path) do
      {:ok, bytes} ->
        {:ok, bytes}

      :error ->
        Error.error(:missing_file, "This backup is missing #{path}.", %{
          path: path,
          present: files |> Map.keys() |> Enum.sort()
        })
    end
  end

  defp decode_json(bytes, path) do
    case Jason.decode(bytes) do
      {:ok, decoded} ->
        {:ok, decoded}

      {:error, error} ->
        Error.error(:unreadable_archive, "#{path} inside this backup is not readable JSON.", %{
          path: path,
          json: Exception.message(error)
        })
    end
  end

  defp check_members(files, manifest) do
    claimed = manifest |> Map.fetch!("files") |> Map.keys() |> MapSet.new()
    present = files |> Map.keys() |> MapSet.new() |> MapSet.delete(@manifest_path)

    missing = MapSet.difference(claimed, present)
    extra = MapSet.difference(present, claimed)

    cond do
      MapSet.size(missing) > 0 ->
        Error.error(
          :missing_file,
          "This backup says it contains #{Enum.join(missing, ", ")}, and it does not.",
          %{missing: MapSet.to_list(missing)}
        )

      MapSet.size(extra) > 0 ->
        Error.error(
          :unexpected_file,
          "This backup contains files its manifest does not list: #{Enum.join(extra, ", ")}. " <>
            "Kati will not read it.",
          %{extra: MapSet.to_list(extra)}
        )

      true ->
        :ok
    end
  end

  defp check_hashes(files, manifest) do
    manifest
    |> Map.fetch!("files")
    |> Enum.reduce_while(:ok, fn {path, claimed}, :ok ->
      bytes = Map.fetch!(files, path)
      actual = Archive.sha256(bytes)

      cond do
        Map.get(claimed, "bytes") != byte_size(bytes) ->
          {:halt,
           mismatch(path, "is #{byte_size(bytes)} bytes, not #{Map.get(claimed, "bytes")}")}

        Map.get(claimed, "sha256") != actual ->
          {:halt, mismatch(path, "does not match the checksum in the manifest")}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp mismatch(path, what) do
    Error.error(
      :checksum_mismatch,
      "This backup is damaged: #{path} #{what}. Nothing has been changed. " <>
        "Try another copy of the file.",
      %{path: path}
    )
  end

  defp parse_payloads(files, manifest) do
    manifest
    |> Map.fetch!("files")
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reduce_while({:ok, %{}}, fn path, {:ok, acc} ->
      with {:ok, payload} <- decode_json(Map.fetch!(files, path), path),
           {:ok, table} <- payload_table(payload, path),
           {:ok, rows} <- payload_rows(payload, path) do
        {:cont, {:ok, Map.put(acc, table, rows)}}
      else
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp payload_table(%{"table" => table}, path) when is_binary(table) do
    if Export.payload_path(table) == path do
      {:ok, table}
    else
      Error.error(:bad_manifest, "#{path} inside this backup claims to hold #{table}.", %{
        path: path,
        table: table
      })
    end
  end

  defp payload_table(_payload, path) do
    Error.error(:bad_manifest, "#{path} inside this backup does not say which table it holds.")
  end

  defp payload_rows(%{"rows" => rows}, path) when is_list(rows) do
    if Enum.all?(rows, &is_map/1) do
      {:ok, rows}
    else
      Error.error(:bad_manifest, "#{path} inside this backup holds something that is not a row.")
    end
  end

  defp payload_rows(_payload, path) do
    Error.error(:bad_manifest, "#{path} inside this backup has no rows list.")
  end

  defp check_tables(payloads) do
    known = MapSet.new(Catalog.tables())
    present = payloads |> Map.keys() |> MapSet.new()

    unknown = MapSet.difference(present, known)
    absent = MapSet.difference(known, present)

    cond do
      MapSet.size(unknown) > 0 ->
        Catalog.fetch(unknown |> MapSet.to_list() |> List.first())

      MapSet.size(absent) > 0 ->
        Error.error(
          :missing_file,
          "This backup has no data file for #{Enum.join(Enum.sort(absent), ", ")}. " <>
            "A backup Kati wrote always has one for every table, even an empty one.",
          %{missing: MapSet.to_list(absent)}
        )

      true ->
        :ok
    end
  end

  defp decode_rows(payloads) do
    Catalog.entries()
    |> Enum.reduce_while({:ok, %{}}, fn entry, {:ok, acc} ->
      case decode_table(entry, Map.fetch!(payloads, entry.table)) do
        {:ok, rows} -> {:cont, {:ok, Map.put(acc, entry.table, rows)}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp decode_table(entry, rows) do
    attributes = Catalog.attributes(entry)
    expected = attributes |> Enum.map(&Atom.to_string(&1.name)) |> MapSet.new()

    with :ok <- check_columns(entry, rows, expected),
         {:ok, decoded} <- decode_values(entry, rows, attributes) do
      check_ids(entry, decoded)
    end
  end

  defp check_columns(entry, rows, expected) do
    rows
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {row, index}, :ok ->
      present = row |> Map.keys() |> MapSet.new()

      missing = expected |> MapSet.difference(present) |> MapSet.to_list() |> Enum.sort()
      extra = present |> MapSet.difference(expected) |> MapSet.to_list() |> Enum.sort()

      if missing == [] and extra == [] do
        {:cont, :ok}
      else
        {:halt,
         Error.error(
           :column_mismatch,
           "Row #{index + 1} of #{entry.table} in this backup does not have the columns " <>
             "Kati expects" <>
             describe(" — missing ", missing) <>
             describe(", unknown ", extra) <>
             ". Nothing has been changed.",
           %{table: entry.table, row: index, missing: missing, unknown: extra}
         )}
      end
    end)
  end

  defp describe(_prefix, []), do: ""
  defp describe(prefix, names), do: prefix <> Enum.join(names, ", ")

  defp decode_values(entry, rows, attributes) do
    {decoded, problems} =
      rows
      |> Enum.with_index()
      |> Enum.map_reduce([], fn {row, index}, problems ->
        decode_row(row, index, attributes, problems)
      end)

    case Enum.reverse(problems) do
      [] ->
        {:ok, decoded}

      [first | _] = all ->
        Error.error(
          :bad_value,
          "This backup holds a value Kati cannot read in #{entry.table} (#{first}). " <>
            "Nothing has been changed.",
          %{table: entry.table, problems: Enum.take(all, @max_reported), total: length(all)}
        )
    end
  end

  defp decode_row(row, index, attributes, problems) do
    Enum.reduce(attributes, {%{}, problems}, fn attribute, {native, problems} ->
      case Codec.decode(attribute, Map.fetch!(row, Atom.to_string(attribute.name))) do
        {:ok, value} -> {Map.put(native, attribute.name, value), problems}
        {:error, sentence} -> {native, ["row #{index + 1}: #{sentence}" | problems]}
      end
    end)
  end

  defp check_ids(entry, rows) do
    ids = Enum.map(rows, & &1.id)

    case ids -- Enum.uniq(ids) do
      [] ->
        {:ok, rows}

      [duplicate | _] ->
        Error.error(
          :duplicate_id,
          "This backup holds two rows of #{entry.table} with the same id (#{duplicate}). " <>
            "Nothing has been changed.",
          %{table: entry.table, id: duplicate}
        )
    end
  end

  defp check_counts(rows, manifest) do
    claimed = Map.fetch!(manifest, "record_counts")

    rows
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce_while(:ok, fn {table, list}, :ok ->
      actual = length(list)

      case Map.get(claimed, table) do
        ^actual ->
          {:cont, :ok}

        other ->
          {:halt,
           Error.error(
             :count_mismatch,
             "This backup says it holds #{inspect(other)} rows of #{table} and holds " <>
               "#{actual}. Nothing has been changed.",
             %{table: table, claimed: other, actual: actual}
           )}
      end
    end)
  end
end
