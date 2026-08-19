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
end
