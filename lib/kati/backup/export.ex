defmodule Kati.Backup.Export do
  @moduledoc """
  The database to a `%Kati.Backup.Bundle{}`.

  Reads every table `Kati.Backup.Catalog` marks `:backup`, in catalog order,
  and writes one JSON payload per table. The only thing that happens outside
  this module is the zipping and the file write, so an export can be inspected,
  diffed and asserted on without going near a filesystem.

  ## Two exports of the same data are the same bytes

  Rows are sorted by primary key and columns are sorted by name, so a payload
  file's SHA-256 depends on the data and nothing else — not on SQLite's row
  order, not on the order attributes happen to be declared in. That is what
  lets a test prove an export is stable, and it is what makes a diff between
  two backups readable.

  Only `manifest.json` differs between two exports of identical data, and only
  in `exported_at`.
  """

  alias Kati.Backup.Bundle
  alias Kati.Backup.Catalog
  alias Kati.Backup.Codec
  alias Kati.Backup.Manifest

  @doc """
  Read every backed-up table and build the bundle.

  `:on_progress` is called once per table with `{table, index, total}` — per
  table and never per record, because there is no BEAM-side diff and every
  event re-serialises the whole tree, so a per-record callback would spend the
  restore hammering the renderer.
  """
  @spec bundle(keyword()) :: Bundle.t()
  def bundle(opts \\ []) do
    on_progress = Keyword.get(opts, :on_progress, fn _ -> :ok end)
    entries = Catalog.entries()
    total = length(entries)

    exported =
      entries
      |> Enum.with_index(1)
      |> Enum.map(fn {entry, index} ->
        on_progress.({entry.table, index, total})
        export_table(entry)
      end)

    files =
      Map.new(exported, fn %{table: table, bytes: bytes} -> {payload_path(table), bytes} end)

    counts = Map.new(exported, fn %{table: table, rows: rows} -> {table, length(rows)} end)

    dropped =
      exported
      |> Enum.flat_map(& &1.dropped)
      |> Map.new()
      |> Map.reject(fn {_column, count} -> count == 0 end)

    manifest = Manifest.build(files, counts, dropped)

    %Bundle{
      manifest: manifest,
      files: Map.put(files, "manifest.json", encode!(manifest)),
      rows: Map.new(exported, fn %{table: table, rows: rows} -> {table, rows} end)
    }
  end

  @doc "Where a table's payload lives inside the archive."
  @spec payload_path(String.t()) :: String.t()
  def payload_path(table), do: "data/#{table}.json"

  defp export_table(entry) do
    attributes = Catalog.attributes(entry)
    dropped = Catalog.dropped_columns(entry)

    records =
      entry.resource
      |> Ash.read!()
      |> Enum.sort_by(& &1.id)

    {rows, drop_counts} =
      Enum.map_reduce(records, empty_drop_counts(entry, dropped), fn record, acc ->
        row_and_drops(record, attributes, dropped, entry.table, acc)
      end)

    payload = %{
      "resource" => inspect(entry.resource),
      "table" => entry.table,
      "count" => length(rows),
      "columns" => Enum.map(attributes, &Atom.to_string(&1.name)),
      "rows" => rows
    }

    %{
      table: entry.table,
      rows: Enum.map(records, &native_row(&1, attributes, dropped)),
      bytes: encode!(payload),
      dropped: Map.to_list(drop_counts)
    }
  end

  # Every dropped column is reported, including as a zero, so the map's key set
  # is a statement of what this schema version drops rather than of what this
  # particular database happened to hold. Zeroes are pruned from the manifest
  # once, at the top.
  defp empty_drop_counts(entry, dropped_names) do
    Map.new(dropped_names, fn name -> {"#{entry.table}.#{name}", 0} end)
  end

  defp row_and_drops(record, attributes, dropped, table, acc) do
    {pairs, acc} =
      Enum.map_reduce(attributes, acc, &encode_column(&1, record, dropped, table, &2))

    # An ordered object, so every row in the file prints its columns in the same
    # order: the whole argument for JSON over a .db file is that a human can
    # read and repair it.
    {Jason.OrderedObject.new(pairs), acc}
  end

  defp encode_column(attribute, record, dropped, table, acc) do
    value = Map.fetch!(record, attribute.name)
    bump = if is_nil(value), do: 0, else: 1

    if attribute.name in dropped do
      {{attribute.name, nil}, Map.update(acc, "#{table}.#{attribute.name}", bump, &(&1 + bump))}
    else
      {{attribute.name, Codec.encode(attribute, value)}, acc}
    end
  end

  defp native_row(record, attributes, dropped) do
    Map.new(attributes, fn attribute ->
      value = if attribute.name in dropped, do: nil, else: Map.fetch!(record, attribute.name)
      {attribute.name, value}
    end)
  end

  defp encode!(term), do: Jason.encode!(term, pretty: true)
end
