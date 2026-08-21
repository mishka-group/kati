defmodule Kati.Backup.Transport do
  @moduledoc """
  Where `Kati.Backup` stops and the device begins.

  `Kati.Backup` deliberately knows nothing about `Mob` — its whole tree runs
  under `mix test` on a host, and that is worth protecting. But a backup that
  exists only inside `filesDir` is not a backup: the user cannot see it, cannot
  copy it, and loses it with the app. This module is the seam, and it is the
  only file in the backup tree that names a platform.

  ## The two-step shape, and why it is two steps

      stage  →  a real file in a directory Kati owns
      hand   →  a system intent that gives it to the user

  They are separate because the first can fail for reasons the user can act on
  (no space, a bad passphrase) and the second can be *declined*, which is not a
  failure at all. Fusing them would force one answer to cover "your disk is
  full" and "you changed your mind".

  It also means the staged file survives a cancelled save. That is deliberate:
  the user can try again — or be told the path — without re-exporting, which on
  a large library is seconds of work and a second read of every table.

  ## The staging directory is swept, not trusted

  Staged files are plaintext copies of everything the user owns unless a
  passphrase was given, sitting in app-private storage. `sweep/1` deletes the
  ones older than an hour and runs on every `stage/1`, so the directory holds
  the backup a user is in the middle of saving and nothing else. It is under
  `Mob.data_dir/1`, not the cache directory: Android may evict a cache
  directory at any moment, including in the seconds between the intent opening
  and the user choosing a folder.

  ## Restore comes in through the same door

  `accept/1` takes what `Mob.Files.pick/2` delivers and answers whether it is a
  Kati backup — by extension, because SAF cannot filter on one (`.katibackup`
  has no registered MIME type) and the picker therefore shows everything. This
  check is what stands between "the user tapped the wrong row" and a confusing
  error out of the archive reader.

  ## Nothing here decides to overwrite anything

  `restore/2` requires a `:mode`, and `Kati.Backup` requires a
  `:safety_export_path` before it will accept `:replace`. Both refusals belong
  to the layer below and are not softened here.
  """

  alias Kati.Backup
  alias Kati.Backup.Error
  alias Kati.Native.Files

  @staging "backup_staging"

  @stale_after_seconds 3600

  @mime "application/octet-stream"

  @doc "The directory staged backups are written to. Created if missing."
  @spec staging_dir(keyword()) :: Path.t()
  def staging_dir(opts \\ []) do
    case Keyword.get(opts, :dir) do
      nil ->
        Mob.data_dir(@staging)

      dir when is_binary(dir) ->
        File.mkdir_p!(dir)
        dir
    end
  end

  @doc """
  Export the database to a file in the staging directory.

  Takes everything `Kati.Backup.export_to_file/2` takes — `:passphrase`
  included — plus:

    * `:dir` — override the staging directory. Tests pass a tmp dir; nothing
      else should.
    * `:date` — the date in the filename. Defaults to today.

  Returns the export summary with `:path` and `:filename` on it, which is what
  a settings screen prints: *"412 films, 64 books, 1,203 events — 2.1 MB"*.
  """
  @spec stage(keyword()) :: {:ok, map()} | {:error, Error.t()}
  def stage(opts \\ []) do
    dir = staging_dir(opts)
    _swept = sweep(opts)

    filename = Backup.suggested_filename(Keyword.get(opts, :date, Date.utc_today()))
    path = Path.join(dir, filename)

    with {:ok, summary} <- Backup.export_to_file(path, opts) do
      {:ok, Map.put(summary, :filename, filename)}
    end
  end

  @doc """
  Export, then open the system Save As… dialog.

  Returns the staged summary as soon as the dialog is open — **not** when the
  file has been written. The outcome arrives as a message; decode it with
  `Kati.Native.Files.decode/1` and treat `:cancelled` as a normal answer.

  On a platform with no transport this returns `{:error, %Error{reason:
  :no_transport}}` **and the staged file still exists**, with its path in
  `details`. A screen should say where it is rather than pretend nothing
  happened — that path is the whole of the user's insurance on iOS today.
  """
  @spec save(keyword()) :: {:ok, map()} | {:error, Error.t()}
  def save(opts \\ []), do: hand_off(:save_as, opts)

  @doc """
  Export, then open the system share sheet.

  Read `Kati.Native.Files`'s note on why a completed share cannot be detected
  before offering this as a way to *make* a backup. It is a way to *send* one.
  """
  @spec share(keyword()) :: {:ok, map()} | {:error, Error.t()}
  def share(opts \\ []), do: hand_off(:share, opts)

  @doc """
  Delete staged files older than an hour. Returns how many went.

  Called by `stage/1`, and worth calling on start: a save that was interrupted
  by the process dying leaves a full copy of the user's data behind, and it
  should not still be there tomorrow.
  """
  @spec sweep(keyword()) :: non_neg_integer()
  def sweep(opts \\ []) do
    dir = staging_dir(opts)
    cutoff = Keyword.get(opts, :now, DateTime.utc_now()) |> DateTime.add(-@stale_after_seconds)

    dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, Backup.extension()))
    |> Enum.count(fn name -> stale?(Path.join(dir, name), cutoff) end)
  end

  @doc """
  The one picked item that is a Kati backup, or a refusal naming what was
  picked instead.

  Takes the list `{:files, :picked, items}` carries. Only the first match is
  returned: a restore is a single-file operation, and offering to merge two
  backups is a decision nobody has made.

      iex> Kati.Backup.Transport.accept([%{name: "photo.jpg", path: "/tmp/a"}])
      {:error, %Kati.Backup.Error{reason: :not_a_backup,
         message: "photo.jpg is not a Kati backup. Choose a .katibackup file.",
         details: %{picked: ["photo.jpg"]}}}
  """
  @spec accept([map()]) :: {:ok, map()} | {:error, Error.t()}
  def accept(items) when is_list(items) do
    case Enum.find(items, &backup?/1) do
      nil -> refuse(items)
      item -> {:ok, item}
    end
  end

  @doc """
  Verify a picked backup and write it into the database.

  A thin composition — `Kati.Backup.restore_file/2` does the work and owns
  every refusal — but it exists so a screen never has to remember that
  `accept/1` comes first. Skipping that check turns "you picked a photo" into
  an archive-reader error.
  """
  @spec restore([map()] | map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def restore(items, opts) when is_list(items) do
    with {:ok, item} <- accept(items), do: restore(item, opts)
  end

  def restore(%{path: path}, opts) when is_binary(path) do
    Backup.restore_file(path, opts)
  end

  @doc """
  Whether a picked item looks like a Kati backup.

  By extension, and by extension only. SAF filters by MIME type and
  `.katibackup` has none registered, so the Android picker cannot narrow and
  the name is the only signal that survives. `K-20 file-picker-display-name`
  is what makes that name a real filename rather than a provider-internal
  document id — without it this function answers `false` for every file on the
  device.
  """
  @spec backup?(map()) :: boolean()
  def backup?(item) when is_map(item) do
    name = item[:name] || item["name"]

    is_binary(name) and String.downcase(Path.extname(name)) == Backup.extension()
  end

  def backup?(_item), do: false

  # ── internals ───────────────────────────────────────────────────────────

  defp hand_off(call, opts) do
    transport = Keyword.get(opts, :transport, Files)

    with {:ok, summary} <- stage(opts) do
      args = [name: summary.filename, mime: @mime, subject: summary.filename]

      case apply(transport, call, [summary.path, args]) do
        :ok -> {:ok, summary}
        {:error, reason} -> transport_error(reason, summary)
      end
    end
  end

  defp transport_error(reason, summary) when reason in [:no_bridge, :not_a_file] do
    Error.error(
      :no_transport,
      "This build of Kati cannot hand a file to the system. " <>
        "The backup is written and waiting at #{summary.path}.",
      %{path: summary.path, native: reason}
    )
  end

  defp transport_error(reason, summary) do
    Error.error(
      :transport_failed,
      "Kati wrote the backup but could not open the system dialog. " <>
        "It is waiting at #{summary.path}.",
      %{path: summary.path, native: reason}
    )
  end

  defp stale?(path, cutoff) do
    with {:ok, %File.Stat{mtime: mtime}} <- File.stat(path, time: :posix),
         true <- DateTime.compare(DateTime.from_unix!(mtime), cutoff) == :lt,
         :ok <- File.rm(path) do
      true
    else
      _ -> false
    end
  end

  defp refuse([]) do
    Error.error(:not_a_backup, "No file was chosen.", %{picked: []})
  end

  defp refuse(items) do
    names = Enum.map(items, fn item -> item[:name] || item["name"] end)

    Error.error(
      :not_a_backup,
      "#{Enum.join(names, ", ")} is not a Kati backup. Choose a #{Backup.extension()} file.",
      %{picked: names}
    )
  end
end
