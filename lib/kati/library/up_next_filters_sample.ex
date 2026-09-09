defmodule Kati.Library.UpNextFiltersSample do
  @moduledoc """
  Board 167's own values, and the words every chip on it is drawn with.

  The twin of `Kati.Library.ShelfFiltersSample`, with one difference worth
  naming: these numbers are internally consistent. `5 + 6 + 3 + 1 = 15`, and
  `15 = 12 ready + 3 cold`, and `Airing soon 4` is a subset of the twelve — so
  the drawn footer is `showing 15 of 15` with nothing chosen and no figure has
  to be explained away. Board 145's `41 of 418` is illustrative and says so;
  this one is screen 10's own header arithmetic.

  The labels are not stand-in data. `Kati.Library.UpNextFilters` holds tags and
  this holds the words, so a chip, a count and the sentence a narrowed page
  says about itself cannot come to disagree about what `:band_airing` is
  called.
  """

  @sorts [
    {:recently_touched, "Recently touched"},
    {:closest_to_finishing, "Closest to finishing"},
    {:time_left, "Time left"},
    {:airing_soonest, "Airing soonest"}
  ]

  @runtimes [
    {:runtime_short, "Under 30m", 5},
    {:runtime_medium, "30–60m", 6},
    {:runtime_long, "Over an hour", 3},
    {:runtime_unknown, "No runtime", 1}
  ]

  @bands [
    {:band_ready, "Ready", 12},
    {:band_airing, "Airing soon", 4},
    {:band_cold, "Gone cold", 3}
  ]

  @doc "The four orderings, in the board's order."
  @spec sort_options() :: [{atom(), String.t()}]
  def sort_options, do: @sorts

  @doc "The runtime rail as the board draws it, counts included."
  @spec runtimes() :: [{atom(), String.t(), non_neg_integer()}]
  def runtimes, do: @runtimes

  @doc "The band rail as the board draws it."
  @spec bands() :: [{atom(), String.t(), non_neg_integer()}]
  def bands, do: @bands

  @doc "The board's own total, which is its two bands added up."
  @spec total() :: non_neg_integer()
  def total, do: 15

  @doc """
  One tag's word, wherever it is drawn.

      iex> Kati.Library.UpNextFiltersSample.label(:band_airing)
      "Airing soon"

      iex> Kati.Library.UpNextFiltersSample.label(:recently_touched)
      "Recently touched"
  """
  @spec label(atom()) :: String.t()
  def label(tag) do
    Enum.find_value(@sorts, fn {key, word} -> key == tag && word end) ||
      Enum.find_value(@runtimes ++ @bands, fn {key, word, _n} -> key == tag && word end) ||
      to_string(tag)
  end

  @doc """
  The footnote, which is one `Text` on purpose.

  `Kati.DesignLiterals.locate/2` is `String.contains?` over each node's own
  string, so every run board 167's three `<strong>`s split this sentence into
  has to land inside one node to be found at the `:node` tier — the shape
  `Kati.Screens.ShelfFilters.note_text/1` already has. Split across two `Text`s
  it would drop to `:flow`, and the middle run spans a bold word in the middle
  of a clause, so there is no split that would not.
  """
  @spec note() :: String.t()
  def note do
    "Airing soon is a date, not a window. A title whose release is a bare " <>
      "year is not in the bucket rather than counted as 1 January \u2014 \u201Csoon\u201D " <>
      "is a date Kati is sure enough of to name. No runtime is not padding: an " <>
      "evicted cache row keeps its position and has no duration, so it needs " <>
      "somewhere nameable to land."
  end
end
