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

  Copy is taken from `test/design/screens/46.html` unchanged.
  """

  @green 0xFF4E9A73
  @red 0xFFB4553C

  @doc """
  The two colours a delta can be, as the board draws them.

  Read by `Kati.Screens.MealSwap`, which builds the same rows out of real
  recipes and coloured them with a bare `@green`/`@red` that was never set in
  that module — so every row built from a plan carried `delta_color: nil` into
  `text_color=` while the fixture's three carried the drawing's colours. Two
  functions rather than two more attributes, because one copy of the number is
  the only arrangement in which the row a plan builds and the row the drawing
  builds cannot come out different colours.
  """
  @spec green() :: integer()
  def green, do: @green

  @doc "See `green/0`."
  @spec red() :: integer()
  def red, do: @red

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

  @doc """
  How the candidate list is ranked. The first is the one in force.

  ## "In my fridge" is gone, and what replaced it

  The board draws a third filter reading *In my fridge*, and there is no pantry
  in Kati — no stock, no depletion when a meal is logged, no expiry.
  `Kati.Meals.ShoppingListItem`'s moduledoc records the same finding from the
  other side: a pantry is a whole feature with its own maintenance burden, and
  one that is 60 per cent accurate is worse than none, because the swap tab
  then quietly stops offering meals you could actually cook.

  **Recently eaten** replaces it, and the difference is that Kati already knows
  the answer. `Kati.Meals.MealLog` holds every logged meal with its date, so
  *not this again* is a real ranking over data that already exists rather than
  a promise resting on a table nobody keeps true.

  All three filters now share that property, which is the rule this list is
  held to: **a filter is only offered if the app can apply it.** Closest macros
  reads the recipe's totals, Faster reads its prep time, Recently eaten reads
  the log.
  """
  @spec filters() :: [String.t()]
  def filters, do: ["Closest macros", "Faster", "Recently eaten"]

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
