defmodule Kati.Backup.Manifest do
  @moduledoc """
  `manifest.json`: what is in the file, and whether this app may read it.

  It carries the two versions, the app that wrote it, the UTC instant it was
  written, a record count per table, the columns that were deliberately dropped,
  and a SHA-256 and byte length for every payload file. The counts are what a
  confirmation screen shows before a restore — *"412 films, 64 books, 1,203
  calendar events"* — and the hashes are what makes showing them honest.

  ## The version rule

  Two versions, because two things move independently:

    * `format_version` — the shape of the archive: which members exist, what
      the manifest looks like, how payload bytes are hashed.
    * `schema_version` — the shape of the rows: which tables, which columns,
      how a value is spelled.

  A file whose **either** version is newer than this app understands is
  **refused outright**, with a sentence naming both numbers. It is not read
  field by field and it is not partially applied: a newer file may contain a
  column this app would drop on the floor, and a restore that silently drops a
  column is a restore that quietly loses the data it was run to save.

  An older `schema_version` is upgraded by `Kati.Backup.Upgrade` before
  anything else looks at it, so the rest of the tree only ever sees rows of the
  current shape.
  """

  alias Kati.Backup.Archive
  alias Kati.Backup.Catalog
  alias Kati.Backup.Error

  @doc """
  Build the manifest for a set of payload files.

  `files` is `%{path => bytes}` for the payloads only; `manifest.json` cannot
  hash itself.
  """
  @spec build(%{String.t() => binary()}, %{String.t() => non_neg_integer()}, %{
          String.t() => non_neg_integer()
        }) :: map()
  def build(files, record_counts, dropped_columns) do
    %{
      "format" => Catalog.format(),
      "format_version" => Catalog.format_version(),
      "schema_version" => Catalog.schema_version(),
      "app_version" => app_version(),
      "exported_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "record_counts" => record_counts,
      "dropped_columns" => dropped_columns,
      "files" =>
        Map.new(files, fn {path, bytes} ->
          {path, %{"sha256" => Archive.sha256(bytes), "bytes" => byte_size(bytes)}}
        end)
    }
  end

  @doc """
  Parse and version-check a decoded manifest.

  Returns the manifest unchanged on success — the caller keeps working with the
  string-keyed map the file actually holds, so nothing can drift between what
  was checked and what is used.
  """
  @spec parse(term()) :: {:ok, map()} | {:error, Error.t()}
  def parse(%{} = manifest) do
    with :ok <- check_format(manifest),
         :ok <- check_version(manifest, "format_version", Catalog.format_version()),
         :ok <- check_version(manifest, "schema_version", Catalog.schema_version()),
         :ok <- check_shape(manifest) do
      {:ok, manifest}
    end
  end

  def parse(_other) do
    Error.error(:bad_manifest, "This backup's manifest is not readable.")
  end

  @doc "The count of every record the file claims to hold, across every table."
  @spec total_records(map()) :: non_neg_integer()
  def total_records(manifest) do
    manifest |> Map.get("record_counts", %{}) |> Map.values() |> Enum.sum()
  end

  @doc "The instant the backup was written, or `nil` if it is unreadable."
  @spec exported_at(map()) :: DateTime.t() | nil
  def exported_at(manifest) do
    case DateTime.from_iso8601(Map.get(manifest, "exported_at", "")) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp check_format(%{"format" => format}) when format == "kati.backup", do: :ok

  defp check_format(_manifest) do
    Error.error(
      :unsupported_format,
      "This file is not a Kati backup — it does not say so in its manifest."
    )
  end

  defp check_version(manifest, key, supported) do
    case Map.get(manifest, key) do
      version when is_integer(version) and version > supported ->
        Error.error(
          version_reason(key),
          "This backup was written by a newer version of Kati (#{key} #{version}; " <>
            "this app understands up to #{supported}). Update Kati and try again. " <>
            "Nothing has been changed.",
          %{key => version, :supported => supported}
        )

      version when is_integer(version) and version >= 1 ->
        :ok

      other ->
        Error.error(:bad_manifest, "This backup's #{key} is missing or unreadable.", %{
          key => other
        })
    end
  end

  defp version_reason("format_version"), do: :unsupported_format
  defp version_reason("schema_version"), do: :unsupported_schema_version

  defp check_shape(manifest) do
    with %{"files" => files, "record_counts" => counts} <- manifest,
         true <- is_map(files) and is_map(counts) do
      :ok
    else
      _ -> Error.error(:bad_manifest, "This backup's manifest is missing its file list.")
    end
  end

  # `Mix.Project` does not exist on a phone, and `config/*.exs` is never read
  # there either. The loaded application spec is the one source that answers on
  # both, and it is informational — nothing branches on it.
  defp app_version do
    case :application.get_key(:kati, :vsn) do
      {:ok, vsn} -> List.to_string(vsn)
      _ -> "unknown"
    end
  end
end
