defmodule Kati.Backup do
  @moduledoc """
  Export and restore: the only thing between a user and total data loss.

  Kati sets `android:allowBackup="false"`, has no server and no account, and
  keeps its database in app-private storage that a file browser cannot reach.
  Every one of those is the right decision on its own, and together they mean a
  lost, stolen, broken or replaced phone is the **total and unrecoverable** loss
  of every film logged, every meal planned and every date corrected by hand. A
  working export is not a feature of this app, it is the insurance policy on all
  the others, and a restore nobody can run is worse than no backup at all
  because it is a false comfort.

  ## The file

  A `.katibackup` is a **zip of JSON**, never a copy of `kati.db`: a SQLite file
  is opaque, coupled to the schema that wrote it, and unrepairable by hand,
  where JSON is diffable, greppable and salvageable in a text editor on any
  machine. Inside:

      manifest.json          format, versions, app version, exported_at (UTC),
                             a record count per table, the columns deliberately
                             dropped, and a SHA-256 and byte length per payload
      data/<table>.json      one file per backed-up table

  `docs/backup-format.md` is the published format, with the per-resource
  `:backup` / `:cache` / `:bundled` / `:internal` classification and a JSON
  Schema for both shapes. It is published so that the data outlives the app.

  ## The four things this module promises

    * **Nothing partial.** Everything is verified — hashes, counts, columns,
      every value — before the first write, and every write runs inside one
      `Kati.Repo.transaction/1`. An error means the database was not touched.
    * **A newer file is refused, not half-read.** See `Kati.Backup.Manifest`.
    * **Rows come back exactly as they went in**, including
      `Kati.Meals.MealLog`'s frozen nutrition figures and every `inserted_at`.
      See `Kati.Backup.Restore`.
    * **Existing rows are never silently overwritten.** The default mode
      refuses outright; see `Kati.Backup.Restore` for the three.

  ## Where the file goes

  Nothing here references `Mob`. Getting bytes off the device is a separate
  problem with a separate ticket — `Mob.Share` is text-only and Android needs a
  bridge patch before any file can leave the app — and this tree deliberately
  knows nothing about it, so the whole of it runs under `mix test` on a host.
  Callers pass a path in and get a path back.
  """

  alias Kati.Backup.Archive
  alias Kati.Backup.Bundle
  alias Kati.Backup.Error
  alias Kati.Backup.Export
  alias Kati.Backup.Restore
  alias Kati.Backup.Verify

  @extension ".katibackup"

  @doc "The extension every Kati backup carries."
  @spec extension() :: String.t()
  def extension, do: @extension

  @doc """
  A filename to propose in a Save As… dialog.

  Dated, because a user with three backups needs to know which is which, and
  the date is the only thing they will recognise.
  """
  @spec suggested_filename(Date.t()) :: String.t()
  def suggested_filename(date \\ Date.utc_today()) do
    "kati-backup-#{Date.to_iso8601(date)}#{@extension}"
  end

  @doc "Read every backed-up table into a bundle. See `Kati.Backup.Export`."
  @spec export(keyword()) :: Bundle.t()
  defdelegate export(opts \\ []), to: Export, as: :bundle

  @doc "Zip a bundle. The bytes a caller hands to a Save As… or a Share sheet."
  @spec to_binary(Bundle.t()) :: binary()
  defdelegate to_binary(bundle), to: Archive, as: :pack

  @doc """
  Export straight to a file.

  Returns the path, the size and the record count, which is what a settings
  screen has to print afterwards.
  """
  @spec export_to_file(Path.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def export_to_file(path, opts \\ []) do
    bundle = export(opts)
    binary = to_binary(bundle)

    case File.write(path, binary) do
      :ok ->
        {:ok,
         %{
           path: path,
           bytes: byte_size(binary),
           record_counts: Map.fetch!(bundle.manifest, "record_counts"),
           total_records:
             bundle.manifest |> Map.fetch!("record_counts") |> Map.values() |> Enum.sum(),
           dropped_columns: Map.fetch!(bundle.manifest, "dropped_columns")
         }}

      {:error, posix} ->
        Error.error(:write_failed, "Kati could not write the backup to #{path}.", %{
          posix: posix
        })
    end
  end

  @doc """
  Open and check a backup file without touching the database.

  This is what the confirmation step shows — *"1,203 calendar events, written on
  16 August"* — and it is the same check the restore runs, so a screen can never
  offer numbers a restore would then refuse.
  """
  @spec inspect_file(Path.t()) :: {:ok, map()} | {:error, Error.t()}
  def inspect_file(path) do
    with {:ok, binary} <- read_file(path), do: inspect_binary(binary)
  end

  @doc """
  `inspect_file/1` for bytes that never became a file.

  A document picker on Android hands back a `content://` URI, and reading one
  is a stream, not a path — so every entry point here has a binary form.
  """
  @spec inspect_binary(binary()) :: {:ok, map()} | {:error, Error.t()}
  def inspect_binary(binary) do
    with {:ok, bundle} <- Verify.bundle(binary), do: {:ok, Verify.summary(bundle)}
  end

  @doc "Read a file and verify it. The bundle comes back with its rows decoded."
  @spec read(Path.t()) :: {:ok, Bundle.t()} | {:error, Error.t()}
  def read(path) do
    with {:ok, binary} <- read_file(path), do: Verify.bundle(binary)
  end

  @doc """
  Verify a file and write it into the database.

  Options are `Kati.Backup.Restore`'s, plus `:safety_export_path` — where the
  pre-restore copy of the current data goes in `:replace` mode. `:replace`
  without one is refused: emptying the tables without saving what was in them
  first is the one thing a backup feature must never do.
  """
  @spec restore_file(Path.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def restore_file(path, opts \\ []) do
    with {:ok, binary} <- read_file(path), do: restore_binary(binary, opts)
  end

  @doc "`restore_file/2` for bytes that never became a file."
  @spec restore_binary(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def restore_binary(binary, opts \\ []) do
    with {:ok, bundle} <- Verify.bundle(binary), do: restore(bundle, opts)
  end

  @doc "Write an already-verified bundle. See `Kati.Backup.Restore`."
  @spec restore(Bundle.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def restore(%Bundle{} = bundle, opts \\ []) do
    Restore.apply(bundle, with_safety_sink(opts))
  end

  defp read_file(path) do
    case File.read(path) do
      {:ok, binary} ->
        {:ok, binary}

      {:error, posix} ->
        Error.error(:not_a_backup, "Kati could not open #{path}.", %{posix: posix})
    end
  end

  defp with_safety_sink(opts) do
    case {Keyword.get(opts, :mode), Keyword.get(opts, :safety_export_path)} do
      {:replace, path} when is_binary(path) ->
        Keyword.put(opts, :safety_sink, fn bundle -> write_safety(bundle, path) end)

      _ ->
        opts
    end
  end

  defp write_safety(bundle, path) do
    case File.write(path, to_binary(bundle)) do
      :ok -> {:ok, path}
      {:error, posix} -> {:error, posix}
    end
  end
end
