defmodule Kati.Meals.SampleProfiles do
  @moduledoc """
  The meal-plan profiles screen 49 draws, as data.

  A stand-in for the Meals domain. The copy is the design's own, from
  `.scratch/design/screens/49.html`.

  A plan is the profile mechanism: it owns its meals, its targets and its
  reminder times, and exactly one is active. That is why `active` is a single
  map rather than the first element of `saved` — the shape says the rule.

  The three saved plans use the design's own image seeds (`mealmaint`,
  `mealtravel`, `mealjo`) so the rows show the photographs the drawing shows.
  """

  @doc "Everything screen 49 shows, in the order it shows it."
  @spec plans() :: map()
  def plans do
    %{
      subtitle: "4 saved · 1 active",
      active: active(),
      saved: saved(),
      switching: switching(),
      note:
        "A plan owns its meals, targets and reminder times. Switching swaps " <>
          "all three at once — nothing has to be re-entered when you come " <>
          "back to an old one."
    }
  end

  @doc """
  The one active plan, drawn on ink.

  `week` is stored in sentence case and upcased at render, per the design's
  `text-transform:uppercase`; `progress` is the drawing's own 50%, halfway
  through week 6 of 12.
  """
  @spec active() :: map()
  def active do
    %{
      week: "Week 6 of 12",
      name: "Cutting v3",
      targets: "2,100 kcal · 168P 210C 70F",
      progress: 0.5,
      started: "started 6 Jul",
      adherence: "86% adherence"
    }
  end

  @doc "The plans you can switch back to, each with the reason it exists."
  @spec saved() :: [map()]
  def saved do
    [
      %{
        seed: "mealmaint",
        name: "Maintenance",
        line: "2,450 kcal · 5 meals",
        meta: "used Mar–Jun",
        action: "Activate"
      },
      %{
        seed: "mealtravel",
        name: "Travel week",
        line: "3 meals · no prep",
        meta: "used 4 times",
        action: "Activate"
      },
      %{
        seed: "mealjo",
        name: "Jo’s plan",
        line: "shared with you",
        meta: "vegetarian",
        action: "Activate"
      }
    ]
  end

  @doc """
  How a switch behaves.

  Scheduled rather than instant, so it never mangles a half-finished week —
  which is why the first row is a disclosure rather than a switch: it opens a
  date, it does not toggle a behaviour.
  """
  @spec switching() :: [map()]
  def switching do
    [
      %{
        icon: "event_upcoming",
        title: "Switch takes effect",
        sub: "Next Monday · keeps this week intact",
        trail: :chevron
      },
      %{
        icon: "history",
        title: "Keep the history",
        sub: "Past days stay on their old plan",
        trail: {:toggle, true}
      },
      %{
        icon: "auto_mode",
        title: "Auto-switch",
        sub: "Travel week when a trip is on the calendar",
        trail: {:toggle, true}
      }
    ]
  end
end
