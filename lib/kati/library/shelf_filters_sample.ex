defmodule Kati.Library.ShelfFiltersSample do
  @moduledoc """
  Board 145's facets: five sort options, two ranges, two filter rows, and the
  418-title shelf they are all drawn against.

  `Kati.Library.Sample.chips/0` already answers the four tabs that stay the
  default surface on screens 03, 20 and 21 — All / Watching / Not started /
  Finished. This is the escalation those tabs open into, so it lives beside
  that module rather than inside it: the four-tab counts are the shelf as the
  grid shows it, and these are the shelf as the sheet slices it, and a screen
  that wants one should not have to pull in the other's twelve tuples to get
  it.

  Every triple is `{key, label, count}`, the same shape `Kati.Goals.Goal.kinds/0`
  hands `Kati.Screens.NewGoal` — a stable atom for the tap tag, and the label
  and count the drawing prints beside it. `Kati.Screens.ShelfFilters` derives
  its own key lists from these rather than this module handing back bare
  atoms, for the same reason: the tag and the thing tapped should not drift
  out of sync because they were typed twice.

  The 418 and the 41 are the drawing's own numbers, not counted off any list
  here — nine sample titles cannot produce a shelf of 418, and 418 is not
  meant to be counted, only shown. `Kati.Screens.ShelfFilters.recompute/1`
  explains where 41 stops being load-bearing.
  """

  @doc "The five sort rows, in the order the card draws them."
  @spec sort_options() :: [{atom(), String.t()}]
  def sort_options do
    [
      {:recently_added, "Recently added"},
      {:release_date, "Release date"},
      {:your_rating, "Your rating"},
      {:title, "Title"},
      {:runtime, "Runtime"}
    ]
  end

  @doc "The decade buckets, first row of Ranges."
  @spec decades() :: [{atom(), String.t(), non_neg_integer()}]
  def decades do
    [
      {:decade_2020s, "2020s", 24},
      {:decade_2010s, "2010s", 38},
      {:decade_2000s, "2000s", 11},
      {:decade_older, "Older", 6}
    ]
  end

  @doc "The rating buckets, second row of Ranges."
  @spec ratings() :: [{atom(), String.t(), non_neg_integer()}]
  def ratings do
    [
      {:rating_4, "4★ and up", 31},
      {:rating_3, "3★ and up", 52},
      {:rating_unrated, "Unrated", 9}
    ]
  end

  @doc """
  The genre chips, first row of Filters.

  Comedy carries `0` on purpose — the drawing's own literal, and the reason
  `Kati.Screens.ShelfFilters.facet_chip/4` exists rather than a call to
  `Kati.UI.chip/2`.
  """
  @spec genres() :: [{atom(), String.t(), non_neg_integer()}]
  def genres do
    [
      {:genre_drama, "Drama", 41},
      {:genre_anime, "Anime", 12},
      {:genre_documentary, "Documentary", 8},
      {:genre_comedy, "Comedy", 0}
    ]
  end

  @doc """
  Second row of Filters: two services, then two personal statuses.

  One row, not two, because the drawing puts them there — `Lumen+` and
  `Orbit` answer *where*, `Dropped` and `Gone cold` answer *what happened*,
  and the board treats both as the same kind of chip rather than splitting
  them into a fifth eyebrow.
  """
  @spec services() :: [{atom(), String.t(), non_neg_integer()}]
  def services do
    [
      {:service_lumen, "Lumen+", 22},
      {:service_orbit, "Orbit", 7},
      {:status_dropped, "Dropped", 3},
      {:status_gone_cold, "Gone cold", 2}
    ]
  end

  @doc "The shelf's total size — the drawing's own `418`."
  @spec total() :: pos_integer()
  def total, do: 418
end
