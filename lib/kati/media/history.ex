defmodule Kati.Media.History do
  @moduledoc """
  What *Clear watch history* counts, and what it removes.

  Board 267 is a destructive confirmation, and its own note is the whole of why
  this module exists rather than the screen counting for itself:

  > **Counted before the delete, never after** — a report built from the
  > delete's own row count would say nothing was deleted while it deleted
  > everything. And **reviews are named separately**: a count of "entries"
  > hides the fact that this deletes sentences a person wrote. **No total
  > across the four** — there is no such noun in this app, and a destructive
  > confirmation is the last screen that may print an invented one.

  All three rules are structural here. `counts/0` answers four separate
  figures and no sum; `clear/0` returns the number it removed rather than
  asking afterwards; and nothing in this module can produce a fifth number by
  adding the others together.

  ## What one log is

  `Kati.Media.Watch` — one row per time something was watched, read or played.
  The name is historical and the table is not: it carries films, episodes,
  books and albums alike, which is why board 267 words the first line *times
  you logged something watched, read or played* and why its caption says the
  screen's own title "may also want changing".

  ## What stays, and why each one is a different table rather than a promise

  Shelves and statuses live on `Kati.Media.TrackedTitle`; reading sessions are
  `Kati.Books.ReadingSession`; listens are `Kati.Music.Listen`; lists are
  `Kati.Lists`. None of them is touched here, and none of them *could* be —
  `clear/0` names one resource. That is the difference between a promise a
  screen prints and one the code keeps.

  ## Every episode unticks, and the bookmark survives

  The board calls this "the most surprising thing this act does". A tick IS a
  `Kati.Media.Watch` row — `Kati.Screens.Series` counts progress from those
  rows rather than storing it — so clearing the history returns every progress
  ring to zero. `Kati.Media.TrackedTitle.progress_season`/`progress_episode`
  are columns and are left alone, so a shelf still reads `S2 · E5` beside a
  ring at nothing until the reader ticks again.
  """

  alias Kati.Media.Watch

  @doc """
  The four figures board 267 prints, and never a fifth.

  `%{logs:, ratings:, reviews:, notes:}`. A row counts toward `notes` when it
  records **where** or **who with**, which is what that line says it is;
  `contains_spoilers` and the mood fields are not notes and are not counted as
  any of the four, so a reader is told about what they wrote rather than about
  every column the table has.

  Zeroes on an empty store rather than `nil`: this is a count of things a
  person did, and none is a true answer to it. That is the one place a zero is
  honest on a page like this — the board's own argument against a total is
  about an invented noun, not about counting.
  """
  @spec counts() :: %{
          logs: non_neg_integer(),
          ratings: non_neg_integer(),
          reviews: non_neg_integer(),
          notes: non_neg_integer()
        }
  def counts do
    rows = Ash.read!(Watch)

    %{
      logs: length(rows),
      ratings: Enum.count(rows, &(&1.rating != nil)),
      reviews: Enum.count(rows, &present?(&1.review)),
      notes: Enum.count(rows, &(present?(&1.place) or present?(&1.companions)))
    }
  rescue
    # A store that cannot be read is not a store with nothing in it, and the
    # difference matters on THIS screen more than anywhere: a confirmation
    # offering to clear `0 logs` from a database it could not open would be
    # asking for permission to do something it has not measured.
    _error -> :error
  catch
    :exit, _reason -> :error
  end

  @doc """
  Remove every log, and say how many went.

  The count comes from the rows read before the destroy rather than from the
  destroy's own answer — board 267's first rule, and not a stylistic one: a
  report built from the delete's own row count says nothing was deleted while
  it deletes everything.

  One resource and no cascade. Everything board 267 lists under *what stays* is
  a different table, so this cannot reach any of them.
  """
  @spec clear() :: {:ok, non_neg_integer()} | {:error, term()}
  def clear do
    rows = Ash.read!(Watch)

    Enum.reduce_while(rows, {:ok, 0}, fn row, {:ok, gone} ->
      case Ash.destroy(row) do
        :ok -> {:cont, {:ok, gone + 1}}
        {:ok, _row} -> {:cont, {:ok, gone + 1}}
        error -> {:halt, Kati.Write.note(error, "clear the watch history")}
      end
    end)
  rescue
    error -> Kati.Write.note({:error, error}, "clear the watch history")
  catch
    :exit, reason -> Kati.Write.note({:error, reason}, "clear the watch history")
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
