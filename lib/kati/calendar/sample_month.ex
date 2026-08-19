defmodule Kati.Calendar.SampleMonth do
  @moduledoc """
  Screen 16's month: August 2026, drawn as a load map rather than a list.

  The drawing puts **one dot per section** under each date, never a count and
  never a preview of the text, so a month reads as "where the weight is" at a
  glance. Three sections are drawn — Screen (orange), Personal (ink), Habits
  (green) — and the legend under the grid names them, because a colour with no
  key is decoration.

  Two cells are special and they are not the same thing:

    * **16** is today — an ink card with its dots inverted to paper white.
    * **20** is the selected day — a card-white tile with a hairline shadow,
      and it is the day the summary and the clash list underneath describe.

  Stand-in data until the Screen and Calendar domains land, marked as such.
  """

  # The section colours, from the legend the drawing puts under the grid.
  @screen 0xFFE8823C
  @personal 0xFF1A1917
  @habits 0xFF4E9A73
  # Today's cell is ink, so its dots invert to paper.
  @on_ink 0xFFFBFAF8

  @transparent 0x00FFFFFF
  @in_month 0xFF1A1917
  @out_of_month 0xFFC4BDB3

  # `box-shadow: 0 1px 2px rgba(26,25,23,.05)` — one layer, not the card recipe.
  # The selected tile sits on the grid, not lifted off paper.
  @selected_shadow "0 1 2 0 #0D1A1917"

  @dots %{
    3 => [@screen],
    6 => [@habits],
    9 => [@personal, @screen],
    12 => [@screen],
    14 => [@habits],
    16 => [@on_ink, @on_ink, @on_ink],
    20 => [@screen, @personal, @habits],
    22 => [@personal],
    25 => [@screen],
    27 => [@screen, @habits],
    29 => [@personal]
  }

  @doc "The month the screen renders."
  @spec month() :: map()
  def month do
    %{
      title: "August 2026",
      selected_label: "Thu 20 · 14 items · 2 clashes",
      days: days(),
      clashes: clashes()
    }
  end

  @doc """
  Forty-two cells: five trailing days of July, all of August, six leading days
  of September. Six rows of seven, which is what the drawing's grid resolves to.
  """
  @spec days() :: [map()]
  def days do
    Enum.map(27..31, &outside/1) ++ Enum.map(1..31, &in_month/1) ++ Enum.map(1..6, &outside/1)
  end

  @doc """
  The selected day's clashes, summarised under the grid.

  Each row is a *time* and what collides at it, not an event — that is the
  point of the summary: three lines stand in for fourteen items.
  """
  @spec clashes() :: [map()]
  def clashes do
    [
      %{time: "09:30", label: "2 at once — Standup, Design review"},
      %{time: "13:00", label: "3 at once — Lunch, Plumber, +1"},
      %{time: "20:00", label: "6 episodes air"}
    ]
  end

  @doc "The legend under the grid: the dot colours, named."
  @spec legend() :: [{non_neg_integer(), String.t()}]
  def legend do
    [{@screen, "Screen"}, {@personal, "Personal"}, {@habits, "Habits"}]
  end

  defp outside(n) do
    %{
      label: "#{n}",
      color: @out_of_month,
      weight: "medium",
      background: @transparent,
      shadow: nil,
      dots: []
    }
  end

  defp in_month(16) do
    %{
      label: "16",
      color: @on_ink,
      weight: "bold",
      background: @in_month,
      shadow: nil,
      dots: Map.fetch!(@dots, 16)
    }
  end

  defp in_month(20) do
    %{
      label: "20",
      color: @in_month,
      weight: "bold",
      background: 0xFFFBFAF8,
      shadow: @selected_shadow,
      dots: Map.fetch!(@dots, 20)
    }
  end

  defp in_month(n) do
    %{
      label: "#{n}",
      color: @in_month,
      weight: "medium",
      background: @transparent,
      shadow: nil,
      dots: Map.get(@dots, n, [])
    }
  end
end
