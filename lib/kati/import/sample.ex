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

  `recognised/0` adds a second job for board 141 — a Goodreads export, one
  step earlier than screen 37's Trakt backup: the source has just been
  recognised and the mapping has not been opened yet. It is a different job on
  a different source, not screen 37's job renamed, so it gets its own function
  rather than a second call to `job/0` with a patched `file`.
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

  @doc """
  The job board 141 draws: a Goodreads export, the source just recognised.

  `progress` is the step meter's own five bars, three of them filled — the
  drawing's literal dot-line, kept as the booleans it paints rather than
  reduced to a fraction. It answers to nobody's `step`/`steps` pair: board
  141 draws it at three of five while the subtitle beside it reads `STEP 1 OF
  4`, and the two do not reconcile — see `Kati.Screens.ImportRecognised`'s
  moduledoc for why both are kept rather than one being quietly fixed.

  `outcome/0` is reused rather than repeated: the drawing gives this job the
  exact three counts and three colours screen 37's job already has — `384`
  new, `28` merged in green, `6` conflicts in red — so a second copy of the
  same three maps would be the literal without the honesty of naming the
  coincidence.
  """
  @spec recognised() :: map()
  def recognised do
    %{
      action: "Import 412",
      source: "Goodreads",
      step_label: "STEP 1 OF 4",
      progress: [true, true, true, false, false],
      file: "goodreads_library_export.csv",
      shape: "418 ROWS · 9 COLUMNS",
      matched: 7,
      total_columns: 9,
      skipped: 2,
      columns: recognised_columns(),
      outcome: outcome()
    }
  end

  @doc """
  The nine columns board 141's expanded mapping table draws.

  Same shape as `columns/0` — `icon`, `field`, `note`, `skipped?` — but this
  job's own set: nine columns rather than five, seven matched rather than
  four, and no `sample` value, because this board's row never draws one.
  """
  @spec recognised_columns() :: [map()]
  def recognised_columns do
    [
      %{column: "Title", note: nil, icon: "arrow_forward", field: "Title", skipped?: false},
      %{column: "Author", note: nil, icon: "arrow_forward", field: "Author", skipped?: false},
      %{
        column: "My Rating",
        note: "converts 10pt → 5★",
        icon: "arrow_forward",
        field: "Rating",
        skipped?: false
      },
      %{
        column: "Date Read",
        note: nil,
        icon: "arrow_forward",
        field: "Finished on",
        skipped?: false
      },
      %{
        column: "Bookshelves",
        note: "to-read → Wishlist",
        icon: "arrow_forward",
        field: "Status",
        skipped?: false
      },
      %{column: "My Review", note: nil, icon: "arrow_forward", field: "Review", skipped?: false},
      %{
        column: "Number of Pages",
        note: nil,
        icon: "arrow_forward",
        field: "Length",
        skipped?: false
      },
      %{column: "Publisher", note: "skipped", icon: "block", field: "Skip", skipped?: true},
      %{column: "Binding", note: "skipped", icon: "block", field: "Skip", skipped?: true}
    ]
  end
end
