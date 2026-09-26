defmodule Kati.Test.HeavyDay do
  @moduledoc """
  Board 09's heavy day, as a TEST fixture: eleven timed occurrences in
  `Kati.Calendar.Layout`'s shape, with a two-lane clash at 09:30, a three-way
  one at 13:00 and three episodes collapsing at 20:00.

  It lived in `lib/` as `Kati.Calendar.SampleDay` while screen 09 drew it for
  an empty calendar. Screen 09 draws the reader's own day now, so the day is
  only a shape tests store and lay out — and a fixture belongs under
  `test/support/`, never in what ships.
  """

  @doc "The eleven occurrences, by start minute."
  @spec occurrences() :: [map()]
  def occurrences do
    [
      %{id: 1, start_min: 480, end_min: 510, kind: :habit, title: "Morning run", done: true},
      %{id: 2, start_min: 570, end_min: 585, kind: :event, title: "Standup", meta: "09:30–09:45"},
      %{
        id: 3,
        start_min: 570,
        end_min: 630,
        kind: :event,
        title: "Design review",
        meta: "09:30–10:30",
        rail: 0xFFE8823C
      },
      %{
        id: 4,
        start_min: 780,
        end_min: 840,
        kind: :event,
        title: "Lunch — Jo",
        meta: "13:00–14:00"
      },
      %{id: 5, start_min: 780, end_min: 900, kind: :event, title: "Plumber", meta: "13:00–15:00"},
      %{id: 6, start_min: 780, end_min: 810, kind: :air_date, title: "Marram", meta: "S2 · E3"},
      %{id: 7, start_min: 900, end_min: 930, kind: :todo, title: "Renew passport", todo: true},
      %{
        id: 8,
        start_min: 1200,
        end_min: 1230,
        kind: :air_date,
        title: "Ashfall",
        meta: "S3 · E2",
        seed: "ashfall42"
      },
      %{
        id: 9,
        start_min: 1205,
        end_min: 1235,
        kind: :air_date,
        title: "Salt & Iron",
        meta: "S1 · E4",
        seed: "saltiron33"
      },
      %{
        id: 10,
        start_min: 1210,
        end_min: 1240,
        kind: :air_date,
        title: "The Cartographer",
        meta: "S2 · E1",
        seed: "cartog60"
      },
      %{
        id: 11,
        start_min: 1395,
        end_min: 1410,
        kind: :air_date,
        title: "Blue Hour",
        meta: "leaves Lumen+ at midnight",
        seed: "bluehour58",
        flat: true
      }
    ]
  end

  @doc "The headline board 09 drew over this day, which no real day may borrow."
  @spec summary() :: String.t()
  def summary, do: "14 items · 2 clashes"
end
