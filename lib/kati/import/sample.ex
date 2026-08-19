defmodule Kati.Import.Sample do
  @moduledoc """
  Stand-in import data, until a real CSV reader exists.

  Screen 37 is drawn mid-job — step 3 of 4, five columns already matched, a
  count of what the write will do, and the first of six conflicts waiting for
  an answer. None of that can be shown against an empty database, and the
  screen's whole argument is that the user sees the consequences *before*
  anything is written, so the drawing's own numbers live here.

  Every string is the design's own copy from `.scratch/design/screens/37.html`
  rather than invented sample text, so the screen can be compared with its
  drawing line for line. When the reader lands, this module is replaced by the
  parse result — the screen reads a map and does not care where it came from.
  """

  @doc """
  The job screen 37 draws: a Trakt backup, three of four steps done.

  `columns` is the mapping table. `icon` is the glyph the drawing puts between
  the file's column and Kati's field — `arrow_forward` for a match, `block`
  for the one column that will be dropped — and `skipped?` greys the target so
  colour is not the only thing saying it will be ignored.
  """
  @spec job() :: map()
  def job do
    %{
      action: "Import 412",
      file: "trakt-backup.csv",
      subtitle: "trakt-backup.csv · step 3 of 4",
      shape: "418 ROWS · 9 COLUMNS",
      steps: 4,
      step: 3,
      columns: columns(),
      outcome: outcome(),
      conflict: conflict()
    }
  end

  @doc "The five mapped columns, with the value the drawing samples from row 1."
  @spec columns() :: [map()]
  def columns do
    [
      %{
        column: "title",
        sample: ~s("Blue Hour"),
        icon: "arrow_forward",
        field: "Title",
        note: nil,
        skipped?: false
      },
      %{
        column: "watched_at",
        sample: "2026-08-12",
        icon: "arrow_forward",
        field: "Watched on",
        note: nil,
        skipped?: false
      },
      %{
        column: "rating",
        sample: "9",
        icon: "arrow_forward",
        field: "Rating",
        note: "converts 10pt → 5★",
        skipped?: false
      },
      %{
        column: "type",
        sample: "movie",
        icon: "arrow_forward",
        field: "Kind",
        note: nil,
        skipped?: false
      },
      %{
        column: "show_notes",
        sample: "(empty in 402 rows)",
        icon: "block",
        field: "Skip",
        note: "skipped",
        skipped?: true
      }
    ]
  end

  @doc """
  What the write will do, as three counts.

  Green for merged and red for conflicts, because those are the two outcomes
  a person actually has to think about; new rows are the boring majority and
  stay ink.
  """
  @spec outcome() :: [map()]
  def outcome do
    [
      %{value: "384", label: "New", color: 0xFF1A1917},
      %{value: "28", label: "Merged", color: 0xFF4E9A73},
      %{value: "6", label: "Conflicts", color: 0xFFB4553C}
    ]
  end

  @doc """
  The conflict on top of the pile.

  One at a time, with `apply to all` offered underneath rather than as the
  default — six decisions is a short queue and a blanket answer to a question
  you have not read is how an import quietly destroys a rating.
  """
  @spec conflict() :: map()
  def conflict do
    %{
      title: "Blue Hour",
      seed: "bluehour58",
      line: "Yours ★4 · file says ★5",
      choices: [{"Keep mine", true}, {"Take file", false}, {"Keep both", false}],
      progress: "1 of 6 · apply to all"
    }
  end
end
