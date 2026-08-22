defmodule Kati.Books.Sample do
  @moduledoc """
  Stand-in book data, until the Books domain exists.

  Screen 20 is screen 03 rebuilt from the identical parts — the design's own
  caption says so: *"only the aspect ratio, the progress unit (pages, not
  episodes) and the hero card change. Nothing was redesigned to get here."*
  So this module deliberately mirrors `Kati.Library.Sample`'s shape rather
  than inventing a second one: a list of maps with a `seed`, a fraction, and
  the line the tile prints under its cover.

  Two numbers are literals rather than derivations, because the drawing means
  them to be. The shelf says **64 books** while it draws six covers, and the
  chip says **All 64** — a shelf is a window onto a library, not the whole of
  it. Computing those from `books/0` would quietly turn 64 into 6 and lose the
  point.

  Marked clearly rather than hidden: sample data that looks like real data is
  how a demo becomes a lie.
  """

  # The design's own titles, and the picsum seed the export uses for each
  # cover, so the app shows the exact photograph the drawing shows.
  @books [
    %{title: "The Salt Almanac", seed: "bookaa1", progress: 0.56, line: "p.214/380"},
    %{title: "Estuary", seed: "bookbb2", progress: 0.36, line: "p.88/240"},
    %{title: "Field Notes", seed: "bookcc3", progress: 1.0, line: "finished"},
    %{title: "Marram Grass", seed: "bookdd4", progress: 0.0, line: "to read"},
    %{title: "Low Water", seed: "bookee5", progress: 1.0, line: "finished"},
    %{title: "The Warden", seed: "bookff6", progress: 0.0, line: "to read"}
  ]

  @doc "Every book on the shelf, in the order the grid draws them."
  @spec books() :: [map()]
  def books, do: @books

  @doc "The header's mono subtitle. A literal — see the moduledoc."
  @spec subtitle() :: String.t()
  def subtitle, do: "64 books · 2 reading"

  @doc """
  The one book being read right now, as the hero card draws it.

  `pace` is the design's own phrasing and its own capitals — it is copy, not a
  CSS `text-transform`, so it is stored as written rather than upcased at
  render.
  """
  @spec reading_now() :: map()
  def reading_now do
    %{
      label: "Reading now",
      title: "The Salt Almanac",
      author: "Ines Karvel",
      seed: "bookaa1",
      progress: 0.56,
      pace: "p. 214 / 380 · 23 MIN/DAY PACE"
    }
  end

  @doc """
  The filter chips, first one selected.

  Two carry counts and two do not, which is the drawing's own asymmetry:
  a count earns its place when it is small enough to be a fact you act on.
  """
  @spec chips() :: [{String.t(), String.t() | nil}]
  def chips do
    [
      {"All", "64"},
      {"Reading", "2"},
      {"Finished", nil},
      {"To read", nil}
    ]
  end

  @doc "Absolute path to a cover, or `nil` when that seed was never drawn."
  @spec cover(String.t()) :: String.t() | nil
  def cover(seed), do: Kati.Design.Images.poster(seed)

  @doc """
  Screen 66's book, as the drawing captured it.

  The fallback, in the sense `Kati.Library.Sample.film/0` is one for screen 08:
  what the detail screen shows when `Kati.Books.Book` holds nothing. Every value
  here is read off `.scratch/design/screens/66.html`, including the two the
  drawing means as literals — the pace, which needs seven days of sessions to
  compute and has none here, and the community rating, which has no source at
  all and is drawn as an em dash on purpose.
  """
  @spec detail() :: map()
  def detail do
    %{
      title: "The Salt Almanac",
      author: "Ines Karvel",
      seed: "bookaa1",
      status: :reading,
      status_label: "Reading",
      meta: "2024 · FABER · 380 PP",
      progress: 0.56,
      progress_line: "p. 214 / 380 · 23 MIN/DAY PACE",
      rating: 9,
      rating_label: "4.5",
      community: nil,
      format: :paperback,
      extent_label: "380 pages",
      isbn: "978–0–571–33915–2",
      owned: true,
      warning_count: 3,
      series_line: "#3 of 7 in The Coastal Ledgers",
      series_next: "Next: Low Water",
      lent_to: "Lent to Jo",
      lent_due: "Due 27 Aug"
    }
  end

  @doc """
  The two entries in the cream card, in the order the drawing prints them.

  A quote and a note, which is the whole reason `Kati.Books.Note` has a `kind`:
  the first wears quotation marks and the second does not, and both anchor to a
  page.
  """
  @spec notes() :: [map()]
  def notes do
    [
      %{kind: :quote, body: "The tide keeps its own ledger.", anchor: "p. 148"},
      %{
        kind: :note,
        body: "Re-read chapter seven before starting the second volume.",
        anchor: "p. 206"
      }
    ]
  end

  @doc """
  The reading history band, newest first.

  Dates are the drawing's own and are deliberately not computed from the clock:
  this is the fixture, and a fixture whose dates move is a fixture that cannot
  be compared with the frame it was captured from.
  """
  @spec sessions() :: [map()]
  def sessions do
    [
      %{date: "16 AUG", span: "p. 168 → 214", duration: "38m"},
      %{date: "14 AUG", span: "p. 130 → 168", duration: "31m"},
      %{date: "11 AUG", span: "p. 94 → 130", duration: "29m"}
    ]
  end

  @doc "The four status choices screen 66 offers, and the one that is on."
  @spec statuses() :: [{atom(), String.t()}]
  def statuses do
    [
      {:reading, "Reading"},
      {:finished, "Finished"},
      {:paused, "Paused"},
      {:did_not_finish, "Did not finish"}
    ]
  end

  @doc "The three edition formats, in the drawing's order."
  @spec formats() :: [{atom(), String.t()}]
  def formats do
    [{:paperback, "Paperback"}, {:ebook, "Ebook"}, {:audiobook, "Audiobook"}]
  end
end
