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

    * **6 -> 7** — `goals` and `expenses` joined with screens 104 and 122.

    * **7 -> 8** — `health_medications`, `health_readings` and `health_doses`
      joined with screens 109 and 112.

    * **9 -> 10** — `recipes` gained `bookmarked`, which is what screen 45's
      bookmark disc writes. Nothing moves, for the reason the step below it
      gives in full: a version-9 archive has every member a version-10 app
      expects and its recipe rows simply lack one key, which `Ash.Seed.seed!/2`
      fills with the attribute default — `false`, which is what an unbookmarked
      recipe is.

    * **8 -> 9** — `recipes` gained `slot_name` with screen 116. **Nothing
      moves**, and that is the point of the step existing: a version-8 archive
      has every member a version-9 app expects, and its recipe rows simply lack
      one key, which `Ash.Seed.seed!/2` fills with the attribute default. The
      version still had to move — `schema_version` tracks the row shape, and a
      shape that gained a column is a different shape — so the step is here
      saying so, rather than the chain having a hole in it. A step that does
      nothing is the honest way to record a change that needs nothing done.

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
      {5, 6, &add_services/1},
      {6, 7, &add_goals_and_expenses/1},
      {7, 8, &add_health/1},
      {8, 9, &unchanged/1},
      {9, 10, &unchanged/1},
      # `tracked_titles` gained `private`, which screen 98's share card reads.
      # Nothing moves: a version-10 file has no such column and every row takes
      # the attribute default of `false`, which is what a title nobody has
      # marked private is.
      {10, 11, &unchanged/1},
      # `media_watches` gained `detected`, which screen 36's banner counts.
      # Nothing moves: a version-11 file has no such column and every row takes
      # the attribute default of `false`, which is the truth about every watch
      # written before Kati could notice one — the reader tapped it.
      {11, 12, &unchanged/1},
      # `media_title_aliases` arrived, and a version-12 file simply has none —
      # the reader had not been asked yet. Nothing to move: an absent table
      # restores as an empty one, and Kati asks about a name the first time it
      # hears it, which is what it would have done anyway.
      {12, 13, &unchanged/1},
      # `media_events` arrived, and a version-13 file has none: nothing wrote
      # one before this version existed. Nothing to move, and nothing to
      # reconstruct either — a status column says where a title IS and cannot
      # be read backwards into when it got there or why, which is the whole
      # reason the table exists. So a restored 13 has a history that starts on
      # the day it was upgraded, and that is the honest answer.
      {13, 14, &unchanged/1},
      # `tracked_titles` gained `anime_override` and `cached_titles` gained
      # `original_language`. Nothing moves: a version-14 file has neither
      # column, and every row takes the attribute default. For
      # `anime_override` that default is `NULL` — *I have not said* — which is
      # exactly right for a title written before there was anywhere to say it,
      # and leaves the provider rule free to answer.
      {14, 15, &unchanged/1},
      # `lists` and `list_memberships` arrived. Both are supplied as empty
      # members and neither can be derived: a list is a thing the reader made
      # and named, and its order is a thing they chose. A restored version-15
      # file therefore has no lists — which is what that device had.
      {15, 16, &unchanged/1},
      # `list_memberships` gained `book_id` and `album_id`, and
      # `tracked_title_id` stopped being `NOT NULL` — a list holds a film, a
      # series, a book or an album now (board 332). Nothing moves: a version-16
      # row carries `tracked_title_id` and takes `NULL` for the other two, which
      # is the shape the 10 -> 11 `private` step had.
      {16, 17, &unchanged/1},
      # `followed_authors` arrived (board 307). Nothing derives it — an author
      # is a free string on `books` and following one is the reader's own
      # statement — so a version-17 file restores with nobody followed, which
      # is exactly what the device it came off had.
      {17, 18, &unchanged/1},
      # `tracked_titles` gained `numbering`. Nothing moves: a version-18 row
      # takes `NULL` — no choice made — and follows the default numbering,
      # which is what the device it came off showed.
      {18, 19, &unchanged/1}
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

  # Two members, same `Map.put_new/3` reasoning as every step above.
  defp add_goals_and_expenses(rows) do
    rows |> Map.put_new("goals", []) |> Map.put_new("expenses", [])
  end

  # Three members, same `Map.put_new/3` reasoning as every step above.
  defp add_health(rows) do
    rows
    |> Map.put_new("health_medications", [])
    |> Map.put_new("health_readings", [])
    |> Map.put_new("health_doses", [])
  end

  # See the 8 -> 9 note in the moduledoc: a column arrived, and a missing
  # column takes the attribute default where a missing table would raise.
  defp unchanged(rows), do: rows

  defp no_path(version, target) do
    Error.error(
      :unsupported_schema_version,
      "This backup was written with schema version #{version}, and this version of " <>
        "Kati (schema version #{target}) has no way to read it. Nothing has been changed.",
      %{from: version, to: target}
    )
  end
end
