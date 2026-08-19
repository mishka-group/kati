defmodule Kati.Calendar.SampleDay do
  @moduledoc """
  Screen 09's reference day: *"14 items, 2 clashes"*.

  The design calls this "A heavy day · density rules", and it is drawn to
  exercise every rule at once — sequential cards, a two-lane clash, a
  three-way clash capped at two lanes with a `+1 MORE`, three same-kind items
  collapsing into one grouped card, an all-day band, and two money renewals
  merged into a single row.

  So the data is not decoration: each row is here to make one rule visible. A
  day of ordinary meetings would render the same screen with none of them
  showing.
  """

  @doc "All-day items, drawn in the band above the gutter."
  @spec all_day() :: [map()]
  def all_day do
    [
      %{title: "Vellum — in cinemas", meta: "release · wishlisted", seed: "bluehour58"}
    ]
  end

  @doc "Timed occurrences, in `Kati.Calendar.Layout` shape."
  @spec occurrences() :: [map()]
  def occurrences do
    [
      %{id: 1, start_min: 480, end_min: 510, kind: :habit, title: "Morning run", meta: "Habit · 12-day streak", done: true},
      %{id: 2, start_min: 540, end_min: 570, kind: :event, title: "Standup", meta: "Work"},
      %{id: 3, start_min: 600, end_min: 660, kind: :event, title: "Design review", meta: "Work · 4 people"},
      %{id: 4, start_min: 630, end_min: 690, kind: :event, title: "Plumber", meta: "Home"},
      %{id: 5, start_min: 645, end_min: 700, kind: :event, title: "Renew passport", meta: "Personal"},
      %{id: 6, start_min: 780, end_min: 840, kind: :event, title: "Lunch — Jo", meta: "The Rex"},
      %{id: 10, start_min: 900, end_min: 930, kind: :todo, title: "Renew passport", meta: "Personal", todo: true},
      %{id: 7, start_min: 1140, end_min: 1170, kind: :air_date, title: "The watching loop", meta: "S2 E6 · Lumen+"},
      %{id: 8, start_min: 1150, end_min: 1180, kind: :air_date, title: "Blue Hour", meta: "leaves Lumen+ at midnight"},
      %{id: 9, start_min: 1160, end_min: 1190, kind: :air_date, title: "Thu 20 Aug", meta: "release"}
    ]
  end

  @doc "Money renewals, merged into one row — the design's `2 renewals`."
  @spec money() :: map()
  def money, do: %{count: 2, label: "2 renewals", total: "£22.98"}

  @doc """
  The header's own count. The design says *14 items · 2 clashes*, and it counts
  every drawn thing — the all-day release, the merged money row and the members
  inside a collapsed group — not the number of cards on screen.
  """
  @spec summary() :: String.t()
  def summary, do: "14 items · 2 clashes"

  @doc "The filter chips and their counts."
  @spec chips() :: [{String.t(), non_neg_integer()}]
  def chips, do: [{"Screen", 6}, {"Personal", 6}, {"Money", 2}]
end
