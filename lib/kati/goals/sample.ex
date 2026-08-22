defmodule Kati.Goals.Sample do
  @moduledoc """
  Screens 104 and 106, as the drawings captured them.

  Three cards, one anatomy, and each in a different state — ahead, on pace,
  behind — because a goals page with three cards all doing well would be a
  drawing of a mood rather than of a screen.

  Every figure here is the drawing's own. The projections are stated rather
  than computed for the reason `Kati.Books.Sample` states its pace: a fixture
  whose numbers move with the clock cannot be compared with the frame it was
  captured from.
  """

  @doc "The three cards, in the order screen 104 draws them."
  @spec goals() :: [map()]
  def goals do
    [
      %{
        pace: :on_pace,
        pace_label: "On pace",
        title: "52 books this year",
        progress: 38,
        target: 52,
        fraction: 38 / 52,
        drift: nil,
        projection_lead: "On pace to finish",
        projection: "48 of 52",
        projection_tail: "by",
        projection_date: "31 December",
        counts:
          "Counts finished books only. A book you did not finish counts its pages toward " <>
            "the pages goal, not this one."
      },
      %{
        pace: :ahead,
        pace_label: "Ahead",
        title: "600 minutes read a month",
        progress: 740,
        target: 600,
        fraction: 1.0,
        drift: "23%",
        projection_lead: "Already past it, with",
        projection: "9 days",
        projection_tail: "left in August.",
        projection_date: nil,
        counts: "Counts timed sittings only — a session logged by page has no minutes to give."
      },
      %{
        pace: :behind,
        pace_label: "Behind",
        title: "120 films this year",
        progress: 84,
        target: 120,
        fraction: 84 / 120,
        drift: "11%",
        projection_lead: "On pace to finish",
        projection: "106 of 120",
        projection_tail: ".",
        projection_date: nil,
        counts: "Dropped shows keep the hours they earned. Nothing is taken back."
      }
    ]
  end

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle, do: "3 ACTIVE · JAN – DEC 2026"
end
