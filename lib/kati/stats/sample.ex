defmodule Kati.Stats.Sample do
  @moduledoc """
  Stand-in figures for the stats screens, until the domains that would produce
  them exist. Same rule as `Kati.Library.Sample`: named as a stand-in, shaped
  like the real thing.
  """

  @doc "Screen 07's year summary."
  @spec year() :: map()
  def year do
    %{
      range: "Jan – Aug 2026",
      time: "312h 40m",
      change: "18%",
      weeks: 26,
      streak: "longest streak — 11 nights",
      counts: [{"84", "Films"}, {"19", "Series"}, {"4.1", "Avg ★"}],
      breakdown: [
        {"Drama", 0.82, "128h", 0xFF1A1917},
        {"Documentary", 0.54, "71h", 0xFF4E9A73},
        {"Comedy", 0.38, "49h", 0xFFE8823C},
        {"Thriller", 0.29, "38h", 0xFFB08E55},
        {"Everything else", 0.19, "26h", 0xFFC4BDB3}
      ]
    }
  end

  @doc "Screen 07's More numbers list."
  @spec more_numbers() :: [map()]
  def more_numbers do
    [
      %{icon: "history", title: "Activity log", sub: "1,204 entries"},
      %{icon: "bolt", title: "Habits", sub: "4 active · 12-day best"},
      %{icon: "nutrition", title: "Nutrition", sub: "Cutting v3 · 86%"},
      # Goals joined this list with screen 104, and Subscriptions became Money:
      # screen 122 is the wider page — the same four services plus the one-off
      # expenses quick-add writes — and screen 23 is still one tap further in.
      %{icon: "flag", title: "Goals", sub: "3 active · 38 of 52 books"},
      %{icon: "payments", title: "Money", sub: "£46.47 a month · 7 expenses"},
      %{icon: "movie", title: "Recently watched", sub: "The Long Hollow · 2h ago"}
    ]
  end

  @doc """
  182 days of intensity for the contribution grid — 26 weeks, as the design's
  own caption says.

  Deterministic: the same seed every render, because a grid that reshuffles on
  an unrelated tap looks broken. Weekends run heavier than weekdays, which is
  what makes it read as someone's viewing rather than noise.
  """
  @spec contributions() :: [0..4]
  def contributions do
    for day <- 0..181 do
      weekend? = rem(day, 7) in [5, 6]
      base = rem(day * 37 + div(day, 7) * 11, 10)

      cond do
        base < 3 and not weekend? -> 0
        base < 5 -> 1
        base < 7 -> 2
        weekend? or base < 9 -> 3
        true -> 4
      end
    end
  end

  @doc "The five-step ramp the grid uses, empty to heaviest."
  @spec intensity(0..4) :: integer()
  def intensity(0), do: 0xFFE7E3DC
  def intensity(1), do: 0xFFE9CFA8
  def intensity(2), do: 0xFFEDB273
  def intensity(3), do: 0xFFE8823C
  def intensity(4), do: 0xFFC96A28
end
