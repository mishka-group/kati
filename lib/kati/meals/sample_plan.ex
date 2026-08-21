defmodule Kati.Meals.SamplePlan do
  @moduledoc """
  Stand-in data for screen 44 — the repeating week.

  The design's caption is the domain decision: *"The plan is a rule, not 52
  copies."* So `matrix/0` is five slots × seven days of **state**, and
  `repeat_rule/0` is the rule itself — a start week and a recurrence — rather
  than a materialised year of meals. `day/0` is what the tapped column lists
  underneath.

  Copy is taken from `.scratch/design/screens/44.html` unchanged.
  """

  @doc "The plan's name, and the mono line under it."
  @spec title() :: String.t()
  def title, do: "Cutting v3"

  @spec subtitle() :: String.t()
  def subtitle, do: "repeats every week"

  @doc "The Week / Day / Shop segmented control, Week selected."
  @spec segments() :: [String.t()]
  def segments, do: ["Week", "Day", "Shop"]

  @doc """
  The matrix's column headings — one letter per day, Monday first.

  Sunday is inked rather than muted because it is the day being shown.
  """
  @spec columns() :: [String.t()]
  def columns, do: ["M", "T", "W", "T", "F", "S", "S"]

  @doc """
  Five meal slots × seven days.

  A cell is one of three states and nothing else, because the drawing gives it
  nothing else — the column is too narrow for a name:

    * `:planned` — a filled tray with a `#C4BDB3` pip
    * `:free` — a filled tray, no pip: the slot exists, nothing is in it
    * `:open` — an outlined tray: not part of the plan this week
    * `:today` — inked, with an accent pip
  """
  @spec matrix() :: [map()]
  def matrix do
    [
      %{
        name: "Breakfast",
        time: "07:30",
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :planned]
      },
      %{
        name: "Snack",
        time: "10:30",
        cells: [:planned, :planned, :free, :planned, :free, :planned, :planned]
      },
      %{
        name: "Lunch",
        time: "13:00",
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :planned]
      },
      %{
        name: "Snack",
        time: "16:00",
        cells: [:planned, :planned, :planned, :planned, :free, :planned, :open]
      },
      %{
        name: "Dinner",
        time: "19:30",
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :today]
      }
    ]
  end

  @doc "The matrix's legend, in the order the drawing lays it out."
  @spec legend() :: [{String.t(), atom()}]
  def legend, do: [{"Planned", :planned}, {"Today", :today}, {"Free", :open}]

  @doc "The eyebrow over the tapped day's list."
  @spec day_line() :: String.t()
  def day_line, do: "Sunday · 3 meals"

  @doc "Sunday's three meals, as the day list under the matrix draws them."
  @spec day() :: [map()]
  def day do
    [
      %{
        slot: "Brunch · 10:00",
        title: "Eggs, sourdough, avocado",
        calories: "520",
        seed: "mealbrunch"
      },
      %{slot: "Snack · 16:00", title: "Apple, almond butter", calories: "210", seed: "mealapple"},
      %{
        slot: "Dinner · 19:30",
        title: "Miso salmon, greens, rice",
        calories: "620",
        seed: "mealsalmon"
      }
    ]
  end

  @doc """
  The rule the plan actually is.

  The third row is a switch rather than a chevron: editing *this week only* is
  a mode, not a destination, and the drawing draws it off.
  """
  @spec repeat_rule() :: [map()]
  def repeat_rule do
    [
      %{icon: "repeat", title: "Repeats", sub: "Every week, indefinitely", trailing: :chevron},
      %{
        icon: "event_available",
        title: "Started",
        sub: "Week 6 · 6 Jul 2026",
        trailing: :chevron
      },
      %{
        icon: "edit_calendar",
        title: "Edit this week only",
        sub: "Changes will not carry forward",
        trailing: :switch_off
      }
    ]
  end
end
