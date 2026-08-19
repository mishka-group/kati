defmodule Kati.Meals.SampleSwap do
  @moduledoc """
  Stand-in data for screen 46 — swapping one meal for another.

  The design's caption is the requirement: *"A swap is only useful if it tells
  you what it costs. Candidates are ranked by macro distance, the delta is
  stated in kcal, and the day's totals update before you commit."*

  So a candidate is not just a meal — it is a meal **plus its delta against
  the one being replaced**, and the delta carries its own colour: green while
  the day still fits, red once it does not. `+20 kcal` is green and `+90 kcal`
  is red, which is a judgement about the day's remaining headroom rather than
  about the sign.

  Copy is taken from `.scratch/design/screens/46.html` unchanged.
  """

  @green 0xFF4E9A73
  @red 0xFFB4553C

  @doc "The screen's own title — a swap is always a swap of something."
  @spec heading() :: String.t()
  def heading, do: "Swap dinner"

  @doc "The meal being replaced, at the top of the screen."
  @spec replacing() :: map()
  def replacing do
    %{
      label: "Replacing",
      title: "Miso salmon, greens, rice",
      macros: "620 KCAL · 52P 64C 17F",
      seed: "mealsalmon"
    }
  end

  @doc "How the candidate list is ranked. The first is the one in force."
  @spec filters() :: [String.t()]
  def filters, do: ["Closest macros", "Faster", "In my fridge"]

  @doc """
  The candidates, already ranked by macro distance.

  `badge` is only on the first, and only because it *is* the closest — the
  drawing does not decorate the others.
  """
  @spec candidates() :: [map()]
  def candidates do
    [
      %{
        title: "Cod, new potatoes, peas",
        badge: "BEST",
        macros: "605 kcal · 48P 61C 16F",
        delta: "−15 kcal",
        delta_color: @green,
        selected?: true,
        seed: "mealcod"
      },
      %{
        title: "Tofu poke bowl",
        badge: nil,
        macros: "640 kcal · 38P 72C 19F",
        delta: "+20 kcal",
        delta_color: @green,
        selected?: false,
        seed: "mealtofu"
      },
      %{
        title: "Steak, sweet potato",
        badge: nil,
        macros: "710 kcal · 55P 52C 30F",
        delta: "+90 kcal",
        delta_color: @red,
        selected?: false,
        seed: "mealsteak"
      }
    ]
  end

  @doc """
  What the selected candidate does to the day.

  The split is declared as drawn — 32/44/24 — because it is the day's totals
  *after* the swap, which is the whole point of showing it before committing.
  """
  @spec effect() :: map()
  def effect do
    %{
      label: "Daily total",
      total: "2,085 ",
      target: "/ 2,100",
      macros: [{0.32, 0xFF1A1917}, {0.44, 0xFFB08E55}, {0.24, 0xFFE4D2B0}],
      verdict: "Still inside every target for today"
    }
  end

  @doc "The two commitments: once, or for good."
  @spec commit() :: {String.t(), String.t()}
  def commit, do: {"Swap just today", "Every week"}
end
