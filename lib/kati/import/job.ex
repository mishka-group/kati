defmodule Kati.Import.Job do
  @moduledoc """
  A picked file, read: what is in it, what it would do, and what it cannot.

  Screens 140, 141 and 37 draw three views of one thing — *this file has 418
  rows*, *these nine columns are recognised*, *384 new, 28 merged, 6 conflicts,
  press Import 412* — and until now each drew its own fixture, which is how
  141 and 37 came to contradict each other about the same file (#53).

  There is one job now, built once from the path, and the three screens read
  different parts of it.

  ## New, merged, conflict

  Every record is matched to the shelf by title, case-insensitively, through
  the cache the shelf reads names from. Three outcomes, and they are three
  different things to do:

    * **new** — nothing on the shelf has that name. The import creates the
      title and logs the watch, the way *Add by hand* does: `source: :import`,
      so a row that came out of somebody's export is never mistaken for one
      TMDB answered for.
    * **merged** — the title is already yours and the file's watch is not. The
      watch is added; the title is left exactly as it is.
    * **conflict** — the title is already yours AND you already have a watch
      with a rating for that same day, and the two ratings disagree. That is
      the only thing this refuses to decide, because it is the only thing where
      both answers destroy something.

  A file with no dates cannot conflict: two ratings of one film watched on
  days nobody recorded are two watches, not a disagreement.

  ## Counted before anything is written

  `plan/1` writes nothing. The counts screen 37 draws are the counts of what
  `Kati.Import.Commit.run/2` would do, computed from the same list it will
  walk, so the number on the pill and the number of rows that appear cannot
  drift apart.
  """

  require Ash.Query

  alias Kati.Import.Csv
  alias Kati.Import.Mapping
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  @doc """
  Read a file into a job, or say why not.

  `{:error, :unreadable}` for a file the device would not hand over,
  `{:error, :empty}` for one with no rows, and `{:error, :unrecognised}` for
  one whose header names nothing Kati can use — three different things to tell
  somebody, which is what screen 142 is a drawing of.
  """
  @spec read(String.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def read(path, name) when is_binary(path) do
    with {:ok, text} <- file(path),
         {:ok, {headers, rows}} <- Csv.read(text) do
      columns = Mapping.columns(headers, rows)
      records = Mapping.records(headers, rows)

      if Enum.all?(columns, & &1.skipped?) or records == [] do
        {:error, :unrecognised}
      else
        {:ok, Kati.Import.Job.shaped(name, headers, rows, columns, records)}
      end
    end
  end

  @doc """
  The same job in the shape screen 141 draws — one file, described.

  141 counts what was recognised and 37 shows the mapping and the plan, and
  the two used to be two fixtures that contradicted each other about the same
  file (#53). One job now, read once, and each screen reads the part it draws.
  """
  @spec recognised(map()) :: map()
  def recognised(job) do
    matched = Enum.count(job.columns, &(not &1.skipped?))

    %{
      action: job.action,
      source: job.file,
      step_label: "STEP 1 OF 4",
      progress: [true, true, true, false, false],
      file: job.file,
      shape: job.shape,
      matched: matched,
      total_columns: length(job.columns),
      skipped: length(job.columns) - matched,
      columns: job.columns,
      outcome: job.outcome,
      # The whole job, carried. 141 and 37 are two views of one file (#53) and
      # 141's own `Import 412` pill has to be able to commit it (#89) — without
      # this it could only describe a file and then hand the reader on.
      job: job
    }
  end

  @doc false
  def shaped(name, headers, rows, columns, records) do
    plan = Kati.Import.Job.plan(records)

    %{
      file: name,
      subtitle: "#{name} · step 3 of 4",
      shape: "#{length(rows)} ROWS · #{length(headers)} COLUMNS",
      steps: 4,
      step: 3,
      columns: columns,
      records: records,
      plan: plan,
      action: "Import #{length(plan.new) + length(plan.merged)}",
      outcome: Kati.Import.Job.outcome(plan),
      conflicts: plan.conflicts,
      conflict: Kati.Import.Job.conflict_card(plan.conflicts, 0, nil)
    }
  end

  @doc """
  What committing this file would do, against the shelf as it stands.

  Nothing is written. See the moduledoc.
  """
  @spec plan([map()]) :: %{new: [map()], merged: [map()], conflicts: [map()]}
  def plan(records) do
    shelf = Kati.Import.Job.shelf()

    Enum.reduce(records, %{new: [], merged: [], conflicts: []}, fn record, acc ->
      case Map.get(shelf, Kati.Import.Job.name_key(record.title)) do
        nil ->
          %{acc | new: acc.new ++ [record]}

        tracked ->
          case Kati.Import.Job.clash(tracked, record) do
            nil -> %{acc | merged: acc.merged ++ [Map.put(record, :tracked_id, tracked.id)]}
            clash -> %{acc | conflicts: acc.conflicts ++ [clash]}
          end
      end
    end)
  end

  @doc """
  The disagreement between a file's row and a watch already stored, or `nil`.

  Both must name a rating and a day, and the days must be the same one: that is
  what makes them two accounts of one evening rather than two evenings.
  """
  @spec clash(TrackedTitle.t(), map()) :: map() | nil
  def clash(tracked, record) do
    with %Date{} = day <- Map.get(record, :watched_on),
         points when is_integer(points) <- Map.get(record, :rating),
         %Watch{rating: mine} = watch when is_integer(mine) <-
           Kati.Import.Job.watch_on(tracked, day),
         true <- mine != points do
      %{
        title: record.title,
        tracked_id: tracked.id,
        watch_id: watch.id,
        day: day,
        mine: mine,
        theirs: points,
        record: record
      }
    else
      _agreed -> nil
    end
  end

  @doc false
  def watch_on(tracked, day) do
    Watch
    |> Ash.Query.filter(tracked_title_id == ^tracked.id and watched_on == ^day)
    |> Ash.read!()
    |> List.first()
  rescue
    _error -> nil
  end

  @doc """
  The three figures screen 37 draws over the mapping card.

  The drawing's own colours: ink for new, the green for merged, the red for
  conflicts, because a conflict is the only one of the three that is waiting
  on the reader.
  """
  @spec outcome(map()) :: [map()]
  def outcome(plan) do
    [
      %{value: "#{length(plan.new)}", label: "New", color: 0xFF1A1917},
      %{value: "#{length(plan.merged)}", label: "Merged", color: 0xFF4E9A73},
      %{value: "#{length(plan.conflicts)}", label: "Conflicts", color: 0xFFB4553C}
    ]
  end

  @doc """
  The conflict card at position `index`, or `nil` when the queue is empty.

  One at a time, with `apply to all` offered underneath rather than as the
  default — the fixture's own note, and it was right: a blanket answer to a
  question you have not read is how an import quietly destroys a rating.
  """
  @spec conflict_card([map()], non_neg_integer(), atom() | nil) :: map() | nil
  def conflict_card(conflicts, index, answer \\ nil)

  def conflict_card([], _index, _answer), do: nil

  def conflict_card(conflicts, index, answer) do
    case Enum.at(conflicts, index) do
      nil ->
        nil

      clash ->
        %{
          title: clash.title,
          # The board's own shape, so screen 37 draws a real conflict through
          # the markup it already had. No seed: an imported title has no poster
          # and `conflict_poster/1` already draws the placeholder for `nil`.
          seed: nil,
          line:
            Calendar.strftime(clash.day, "%-d %b %Y") <>
              " · yours ★#{Kati.Import.Job.stars(clash.mine)}" <>
              " · file ★#{Kati.Import.Job.stars(clash.theirs)}",
          progress: "#{index + 1} of #{length(conflicts)} · apply to all",
          watch_id: clash.watch_id,
          index: index,
          # Nothing lit until the reader says something. The fixture lit *Keep
          # mine*, and a default answer to a question about destroying a rating
          # is the one thing this card exists to avoid.
          choices: [
            {"Keep mine", answer == :keep_mine},
            {"Take file", answer == :take_file},
            {"Keep both", answer == :keep_both}
          ]
        }
    end
  end

  @doc """
  A ten-point rating as the five-star number a person reads.

      iex> Kati.Import.Job.stars(9)
      "4.5"

      iex> Kati.Import.Job.stars(8)
      "4"
  """
  @spec stars(integer()) :: String.t()
  def stars(points), do: Kati.Rating.Scale.label(points / 2, :stars)

  @doc """
  The shelf, keyed by the name an import matches on.

  Through `:shelf`, so a title the reader hid is not silently merged into.
  A tracked row whose cache has gone keys on its own `source_id`, which for a
  hand-added or imported title IS the name — see `Kati.Screens.AddByHand`.
  """
  @spec shelf() :: %{String.t() => TrackedTitle.t()}
  def shelf do
    tracked =
      [:movie, :tv, :anime]
      |> Enum.flat_map(fn kind ->
        TrackedTitle
        |> Ash.Query.for_read(:shelf, %{kind: kind})
        |> Ash.read!()
      end)

    cached =
      CachedTitle
      |> Ash.read!()
      |> Map.new(&{{&1.source, &1.source_id}, &1})

    # Every name a row answers to, not only the one the shelf draws:
    # `Kati.Media.CachedTitle.names/1` gives TMDB's own two, so an export that
    # names a show by its original title merges into the row the reader
    # already has rather than creating a second copy of it beside it.
    for row <- tracked,
        name <-
          (case CachedTitle.names(Map.get(cached, {row.source, row.source_id})) do
             [] -> [row.source_id]
             names -> names
           end),
        into: %{},
        do: {Kati.Import.Job.name_key(name), row}
  rescue
    _error -> %{}
  end

  @doc """
  How two names are compared: trimmed, case-folded, punctuation kept.

  Kept, deliberately. `Se7en` and `Seven` are two films and stripping the digit
  would merge them; the case and the whitespace are the only differences that
  are never meaningful.

      iex> Kati.Import.Job.name_key("  The Long Hollow ")
      "the long hollow"
  """
  @spec name_key(String.t()) :: String.t()
  def name_key(name), do: name |> String.trim() |> String.downcase()

  defp file(path) do
    case File.read(path) do
      {:ok, text} -> {:ok, text}
      {:error, _reason} -> {:error, :unreadable}
    end
  end
end
