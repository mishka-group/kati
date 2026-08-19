defmodule Kati.Meals.SampleRecipe do
  @moduledoc """
  Stand-in data for screen 45 — a meal in full.

  The design's caption lists what a meal has to carry: *"Everything a meal
  needs to be cooked and counted: portion multiplier that rescales every
  number, macros as a bar and as figures, ingredients that tick off into the
  shopping list, and the history that tells you whether it is worth keeping."*

  Every figure is stored at **one portion**, because the multiplier is the
  thing that rescales them. The drawing shows `1.0×`, so the drawn numbers and
  the stored numbers are the same until someone taps `add`.

  Copy is taken from `.scratch/design/screens/45.html` unchanged.
  """

  @doc "The eyebrow and title over the photograph."
  @spec meal() :: map()
  def meal do
    %{
      slot: "Dinner · 19:30 · today",
      title: "Miso salmon, greens & rice",
      seed: "mealsalmon",
      portion: "1.0×",
      calories: "620",
      unit: " kcal"
    }
  end

  @doc "The 10pt bar's three segments, as the drawing splits them."
  @spec split() :: [{float(), non_neg_integer()}]
  def split, do: [{0.34, 0xFF1A1917}, {0.42, 0xFFB08E55}, {0.24, 0xFFE4D2B0}]

  @doc "The three macro tiles under the bar."
  @spec macros() :: [{String.t(), String.t(), non_neg_integer()}]
  def macros do
    [
      {"Protein", "52 g", 0xFF1A1917},
      {"Carbs", "64 g", 0xFFB08E55},
      {"Fat", "17 g", 0xFFE4D2B0}
    ]
  end

  @doc "The three secondary figures under the hairline."
  @spec minors() :: [{String.t(), String.t()}]
  def minors, do: [{"Fibre", "7 g"}, {"Sugar", "9 g"}, {"Sodium", "840 mg"}]

  @doc """
  The ingredients, at one portion.

  Each carries its own kcal so the total is visibly the sum of its parts, and
  each has a checkbox because ticking one is what puts it on the shopping list.
  """
  @spec ingredients() :: [map()]
  def ingredients do
    [
      %{name: "Salmon fillet", amount: "150 g", calories: "312"},
      %{name: "Jasmine rice, dry", amount: "65 g", calories: "234"},
      %{name: "Tenderstem broccoli", amount: "120 g", calories: "42"},
      %{name: "White miso", amount: "15 g", calories: "30"},
      %{name: "Sesame oil", amount: "5 ml", calories: "44"}
    ]
  end

  @doc "The three facts above the method, each with its own icon."
  @spec method_facts() :: [{String.t(), String.t()}]
  def method_facts do
    [
      {"schedule", "25 min"},
      {"local_fire_department", "Oven 200°"},
      {"restaurant", "Serves 1"}
    ]
  end

  @doc "The method itself — one paragraph, as the drawing writes it."
  @spec method() :: String.t()
  def method do
    "Whisk the miso with the sesame oil and a splash of water. Coat the " <>
      "salmon, rest 10 minutes while the rice cooks. Roast 12 minutes, steam " <>
      "the broccoli for the last 4."
  end

  @doc """
  The history rows.

  `stars: 5` rather than a string of `★`: Plus Jakarta Sans carries no U+2605,
  so the rating is drawn with the Material Symbols `star` glyph — the same
  thing screen 08 discovered when its rating card rendered empty.
  """
  @spec history() :: [map()]
  def history do
    [
      %{icon: "event_repeat", title: "Eaten 14 times", sub: "Last on Thursday", stars: 0},
      %{icon: "star", title: "Your rating", sub: " · a keeper", stars: 5},
      %{icon: "sticky_note_2", title: "Note", sub: "Better with double the miso", stars: 0}
    ]
  end
end
