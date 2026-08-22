defmodule Kati.Health.Sample do
  @moduledoc """
  Stand-in Health data, until the sections it contains are real.

  Screen 42's note is the architectural claim the whole screen exists to make:
  *"Health is a container, not a feature. Each tile is an independent section
  with its own shelf, calendar feed and home card."* So the tiles are not a
  menu — they are a list of sections, two switched on and four not, and that
  distinction is the only state a tile has.

  Which is why `sections/0` returns tiles with an `on?` flag rather than two
  separate lists: the drawing lays live and unbuilt tiles in one wrapping grid,
  interleaved by nothing but order, and splitting them here would invent a
  grouping the design does not have.
  """

  @doc "The mono line under the title — the day this screen is showing."
  @spec day_line() :: String.t()
  def day_line, do: "Sunday 16 August"

  @doc """
  Today's intake, as the cream hero draws it.

  `eaten` and `target` are two runs because the drawing sets them at 34 and 16
  on one baseline; `macros` are the three segments of the 9pt bar, stored with
  the weight each takes so the bar is declared rather than recomputed from
  grams — the export's own 31/44/25 split.
  """
  @spec eaten() :: map()
  def eaten do
    %{
      label: "Eaten today",
      calories: "1,480",
      target: " / 2,100 kcal",
      meals: "3 of 5",
      macros: [
        {"Protein", 0.31, 0xFF1A1917},
        {"Carbs", 0.44, 0xFFB08E55},
        {"Fat", 0.25, 0xFFE4D2B0}
      ],
      grams: "118P · 163C · 41F"
    }
  end

  @doc "The one live section with something happening in it right now."
  @spec next_meal() :: map()
  def next_meal do
    %{
      title: "Open Meals — dinner 19:30",
      line: "Miso salmon, greens, rice · 620 kcal"
    }
  end

  @doc """
  The six sections Health holds, in the order the grid wraps them.

  A tile that is `on?` carries a status dot and a real line; one that is not
  carries a dashed outline and *"Not set up"*. Nothing else differs, which is
  the point: switching one on is a state change, not a new screen.
  """
  @spec sections() :: [map()]
  def sections do
    [
      %{
        icon: "restaurant",
        name: "Meals",
        line: "Cutting v3 · week 6",
        on?: true,
        dot: 0xFF1A1917
      },
      %{icon: "bolt", name: "Habits", line: "4 active · 12-day best", on?: true, dot: 0xFF4E9A73},
      %{icon: "bedtime", name: "Sleep", line: "Not set up", on?: false},
      # Weight and Medication stopped being outlines when screens 109 and 112
      # landed. Both now carry a real line and a dot, which is what `on?` has
      # always meant on this grid: switching a section on is a state change, not
      # a new screen. Sleep and Workouts are still unbuilt and still dashed.
      %{
        icon: "monitor_weight",
        name: "Weight",
        line: "76.0 kg · down 2.4",
        on?: true,
        dot: 0xFF4E9A73
      },
      %{icon: "fitness_center", name: "Workouts", line: "Not set up", on?: false},
      %{
        icon: "medication",
        name: "Medication",
        line: "4 doses today",
        on?: true,
        dot: 0xFF1A1917
      }
    ]
  end

  @doc "The design's own explanation of the screen, drawn inside the screen."
  @spec container_note() :: String.t()
  def container_note do
    "Health is a container, not a feature. Each tile is an independent " <>
      "section with its own shelf, calendar feed and home card — switch one " <>
      "on and it appears everywhere."
  end
end
