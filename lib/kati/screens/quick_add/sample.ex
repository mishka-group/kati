defmodule Kati.Screens.QuickAdd.Sample do
  @moduledoc """
  The one draft screen 18 is drawn mid-parse on, until a parser exists.

  `.scratch/design/screens/18.html` does not draw an empty field. It draws
  *dentist thu 11am for 45m, remind 1h before* already typed, already
  understood, with a caret still blinking after the last token — so the screen
  can only be compared with its drawing if the sample carries the same
  half-finished sentence.

  ## Why the query is a list of pieces rather than a string

  The design highlights **inside** the sentence: `thu 11am`, `45m` and
  `1h before` sit on their own tinted grounds while the words between them do
  not. There is no inline-span primitive on this bridge, so the sentence is
  modelled the way it is drawn — a run of typed pieces, each knowing whether it
  is plain prose, a parsed token, or the accent-tinted reminder token, and how
  much space precedes it.

  Lines are declared rather than measured, for the same reason every other grid
  in this app is: nothing reports geometry back to `render/1`. The break falls
  where the browser puts it in the drawing — after `, remind`.

  When the parser lands, delete this and hand `Kati.Screens.QuickAdd` the same
  shape: the screen reads pieces and facts and does not care who produced them.
  """

  @doc """
  The draft as screen 18 draws it.

  `kind` is stored in capitals because the drawing types it in capitals —
  there is no `text-transform` on that line, so `PERSONAL EVENT` is the copy
  itself and not a styling of *Personal event*.
  """
  @spec draft() :: map()
  def draft do
    %{
      query: query(),
      title: "Dentist",
      kind: "PERSONAL EVENT",
      facts: facts(),
      clash: {"Clashes with", "Design review", "— add anyway?"},
      kinds: kinds(),
      cta: "Add to Thursday"
    }
  end

  @doc """
  The typed sentence, one entry per drawn line.

  `caret` marks the line the cursor is still sitting on — the last one, which
  is what makes the screen read as mid-typing rather than as a result.
  """
  @spec query() :: [map()]
  def query do
    [
      %{
        caret: false,
        pieces: [
          {:plain, "dentist", 0},
          {:token, "thu 11am", 4},
          {:plain, "for", 4},
          {:token, "45m", 4},
          {:plain, ", remind", 0}
        ]
      },
      %{caret: true, pieces: [{:accent, "1h before", 0}]}
    ]
  end

  @doc """
  What Kati understood, as chips.

  Chunked into the two rows the drawing's `flex-wrap` produces at 402pt, since
  there is no wrapping primitive to produce them from a flat list.
  """
  @spec facts() :: [[{String.t(), String.t()}]]
  def facts do
    [
      [{"calendar_today", "Thu 20 Aug"}, {"schedule", "11:00 – 11:45"}],
      [{"notifications", "10:00 alert"}, {"label", "Personal"}]
    ]
  end

  @doc """
  The six things one field can become, the first one selected.

  This is the design's real claim — *one field for the whole app* — so the list
  is every section Kati keeps, not only the calendar ones.
  """
  @spec kinds() :: [{String.t(), String.t(), boolean()}]
  def kinds do
    [
      {"event", "Event", true},
      {"check_circle", "Reminder", false},
      {"movie", "Title", false},
      {"bolt", "Habit", false},
      {"edit_note", "Note", false},
      {"payments", "Expense", false}
    ]
  end
end
