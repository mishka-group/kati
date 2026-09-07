defmodule Kati.Search.Suggestions do
  @moduledoc """
  Two things this reader could actually search for.

  Board 86 draws a *Try* group of two, under a caption that says they are
  **drawn from what you actually have** — and they were two fixed strings,
  `what leaves this week` and `notes about the estuary`, which match nothing on
  any device but the one the board was captured on. A reader tapped one and got
  the no-match card. MOVIES-AND-TV.md #72.

  The newest title on the shelf and the book the newest note is about are both
  queries that WILL match, which is what the caption promises. A device with
  neither keeps the board's two, which is the gate every other screen on this
  list keeps.

  Deliberately not *what leaves this week*: that needs an offers resource, the
  same absence that takes the Leaving band off screen 11 and the decade chips
  off screen 145.

  ## Why this is not in `Kati.Search`

  `Kati.Search` is imported by every search screen and by four boards that
  merely describe the specification. `Kati.ScreenEmptyDatabaseTest` derives
  *reaches the store* from the compiled call graph, so an `Ash.read!` in that
  module would make screens 86, 87, 88 and 91 all answer yes and drag four
  reference sheets into a sweep about fallbacks. `Kati.Media.ArtworkBackfill`
  was split out of `Kati.Media.Artwork` for exactly this reason, and the trap
  is written up in the repo's own notes.
  """

  @doc """
  The reader's own two, or the board's.

  Never raises and never answers `[]`: this fills a group the board always
  draws, and an empty *Try* group would be a heading over nothing.
  """
  @spec for_reader([String.t()]) :: [String.t()]
  def for_reader(derived \\ derived())

  def for_reader([]), do: Kati.Search.suggestions()
  def for_reader(derived), do: derived

  @doc "What can be derived, which may be nothing at all."
  @spec derived() :: [String.t()]
  def derived do
    [newest_title(), noted_book()] |> Enum.reject(&is_nil/1) |> Enum.uniq()
  rescue
    _error -> []
  end

  defp newest_title do
    Kati.Media.CachedTitle
    |> Ash.read!()
    |> Enum.sort_by(& &1.fetched_at, {:desc, DateTime})
    |> Enum.find_value(fn row -> blank_to_nil(row.title) end)
  rescue
    _error -> nil
  end

  defp noted_book do
    Kati.Books.Note
    |> Ash.Query.load(:book)
    |> Ash.read!()
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> Enum.find_value(fn note -> note.book && blank_to_nil(note.book.title) end)
  rescue
    _error -> nil
  end

  defp blank_to_nil(value) when is_binary(value) and value != "", do: value
  defp blank_to_nil(_value), do: nil
end
