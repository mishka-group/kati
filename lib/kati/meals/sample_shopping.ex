defmodule Kati.Meals.SampleShopping do
  @moduledoc """
  The shopping list screen 48 draws, as data.

  A stand-in for the Meals domain, which does not exist yet. The copy is the
  design's own, from `.scratch/design/screens/48.html`, because the whole
  argument of the screen is in the wording: every line names **which meals
  asked for it**, so cutting a meal visibly shrinks the list. Inventing
  "2 x tomatoes" here would throw that away.

  Shaped as a list of aisles, each with a list of items, which is the shape a
  real `Kati.Meals.shopping_list/1` would return — grouping is the domain's
  job, not the screen's, because the drawing also offers "By meal" and
  "Missing only" groupings of the same items.
  """

  @doc "Everything screen 48 shows, in the order it shows it."
  @spec list() :: map()
  def list do
    %{
      subtitle: "week of 17 Aug · 24 items",
      basket: "9 of 24 in the basket",
      estimate: "£41.20 est.",
      # 38% in the drawing — the bar is 9 of 24 rounded to the design's own
      # figure, not recomputed, so the screen matches what was drawn.
      progress: 0.38,
      filters: filters(),
      aisles: aisles()
    }
  end

  @doc """
  The three groupings, the first one chosen.

  They are not a segmented control: the design draws them as chips on paper
  with a shadow, which is the same recipe screen 03 uses for its filters.
  """
  @spec filters() :: [{String.t(), boolean()}]
  def filters do
    [{"By aisle", true}, {"By meal", false}, {"Missing only", false}]
  end

  @doc """
  Nine items over three aisles, four of them already in the basket.

  `got` is what strikes the line through and greys the amount. The design
  keeps a struck line in place rather than removing it, so the list does not
  reflow under your thumb while you are reading it in a shop.
  """
  @spec aisles() :: [map()]
  def aisles do
    [
      %{
        name: "Produce",
        items: [
          %{name: "Tenderstem broccoli", meals: "7 meals", amount: "840 g", got: false},
          %{name: "Baby spinach", meals: "3 meals", amount: "200 g", got: false},
          %{name: "Apples", meals: "snack ×7", amount: "×7", got: true},
          %{name: "Avocado", meals: "brunch", amount: "×2", got: false}
        ]
      },
      %{
        name: "Fish & meat",
        items: [
          %{name: "Salmon fillet", meals: "4 dinners", amount: "600 g", got: false},
          %{name: "Chicken breast", meals: "5 lunches", amount: "900 g", got: true}
        ]
      },
      %{
        name: "Cupboard",
        items: [
          %{name: "Jasmine rice", meals: "6 meals", amount: "1 kg", got: true},
          %{name: "White miso", meals: "4 dinners", amount: "1 tub", got: false},
          %{name: "Rolled oats", meals: "7 breakfasts", amount: "750 g", got: true}
        ]
      }
    ]
  end
end
