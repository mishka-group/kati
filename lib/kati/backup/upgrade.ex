defmodule Kati.Backup.Upgrade do
  @moduledoc """
  Older backups, brought forward one schema version at a time.

  #64's forward-compatibility rule has two halves and they are not symmetric: a
  **newer** file is refused outright by `Kati.Backup.Manifest`, and an **older**
  file must keep working forever. This is the second half.

  A step is `{from, to, fun}` where `fun` takes `%{table => [row]}` — rows still
  as JSON, before any column is decoded — and returns the same shape one
  version newer. `walk/3` composes them, so a v1 file read by a v4 app runs
  three functions rather than one function that has to remember three shapes.

  ## The steps

    * **1 -> 2** — `sync_rejected_changes` joined the backup, so a version-1
      archive has no `data/sync_rejected_changes.json` and no row for it in
      `record_counts`. Everything downstream reads the catalog's tables by
      name: `Kati.Backup.Verify` refuses a payload set that is missing one, and
      `Kati.Backup.Restore` does `Map.fetch!/2` per table. The step supplies the
      empty list those readers expect, so an old backup restores with its
      rejected changes simply **absent** rather than with an error about a
      member it was never written with.

    * **2 -> 3** — `media_content_warnings` and `media_warning_preferences`
      joined the backup for #16. Same shape of problem as 1 -> 2 and the same
      fix. Note what does NOT need a step: `media_watches` gained `moods`,
      `pace` and `driven_by`, and a version-2 row simply lacks those keys —
      `Ash.Seed.seed!/2` takes a plain map, so the attribute defaults apply and
      an old watch restores with no moods rather than failing. A missing
      **table** raises because `Kati.Backup.Restore` does `Map.fetch!/2` per
      table; a missing **column** does not.

    * **3 -> 4** — `books`, `book_reading_sessions` and `book_notes` joined the
      backup when the Books domain landed. Same shape again, three members this
      time. A version-3 archive restores with an empty shelf, which is what it
      actually recorded: the tables did not exist when it was written, so there
      is nothing to be sorry about losing.

    * **4 -> 5** — `music_artists`, `music_albums`, `music_tracks` and
      `music_listens` joined the backup when the Music domain landed. Four
      members, same shape again.

    * **5 -> 6** — `services` joined the backup with screen 92. One member.

  The step adds the key and never replaces one, so it is safe to run over rows
  that already have it and it cannot be the thing that loses a row.

  Row counts are checked against the manifest **before** the walk, against the
  file as it was actually written — otherwise a table this step invents would
  be compared against a count no version-1 manifest ever claimed.
  """

  alias Kati.Backup.Catalog
  alias Kati.Backup.Error

  @type rows :: %{String.t() => [map()]}
  @type step :: {pos_integer(), pos_integer(), (rows() -> rows())}

  @doc "Every upgrade step, oldest first."
  @spec steps() :: [step()]
  def steps,
    do: [
      {1, 2, &add_rejected_changes/1},
      {2, 3, &add_content_warnings/1},
      {3, 4, &add_books/1},
      {4, 5, &add_music/1},
      {5, 6, &add_services/1}
    ]

  @doc """
  Bring rows from `from` up to the current schema version.

  Fails rather than guessing when a version has no path forward — a file from a
  version this app has no step for is a file it cannot honestly claim to read.
  """
  @spec walk(rows(), pos_integer(), [step()]) :: {:ok, rows()} | {:error, Error.t()}
  def walk(rows, from, steps \\ steps()) do
    walk(rows, from, Catalog.schema_version(), steps)
  end

  @doc """
  `walk/3` with the destination spelled out.

  The general form: `walk/3` is this with the target fixed at whatever version
  the app is on today.
  """
  @spec walk(rows(), pos_integer(), pos_integer(), [step()]) ::
          {:ok, rows()} | {:error, Error.t()}
  def walk(rows, from, target, steps), do: walk_to(rows, from, target, steps)

  defp walk_to(rows, version, target, _steps) when version == target, do: {:ok, rows}

  defp walk_to(rows, version, target, steps) do
    case Enum.find(steps, fn {from, _to, _fun} -> from == version end) do
      {_from, to, fun} -> walk_to(fun.(rows), to, target, steps)
      nil -> no_path(version, target)
    end
  end

  # `Map.put_new/3` rather than `Map.put/3`: the step's job is that the member
  # exists, not that it is empty. A file that somehow already carries the table
  # keeps its rows and has them checked like any others, and running the step
  # twice cannot erase them.
  defp add_rejected_changes(rows), do: Map.put_new(rows, "sync_rejected_changes", [])

  # Same `Map.put_new/3` reasoning as above, twice.
  defp add_content_warnings(rows) do
    rows
    |> Map.put_new("media_content_warnings", [])
    |> Map.put_new("media_warning_preferences", [])
  end

  # Three members, same `Map.put_new/3` reasoning as the two steps above.
  defp add_books(rows) do
    rows
    |> Map.put_new("books", [])
    |> Map.put_new("book_reading_sessions", [])
    |> Map.put_new("book_notes", [])
  end

  # Four members, same `Map.put_new/3` reasoning as the three steps above.
  defp add_music(rows) do
    rows
    |> Map.put_new("music_artists", [])
    |> Map.put_new("music_albums", [])
    |> Map.put_new("music_tracks", [])
    |> Map.put_new("music_listens", [])
  end

  # One member, same `Map.put_new/3` reasoning as the four steps above.
  defp add_services(rows), do: Map.put_new(rows, "services", [])

  defp no_path(version, target) do
    Error.error(
      :unsupported_schema_version,
      "This backup was written with schema version #{version}, and this version of " <>
        "Kati (schema version #{target}) has no way to read it. Nothing has been changed.",
      %{from: version, to: target}
    )
  end
end
