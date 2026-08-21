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
      %{title: "Vellum — in cinemas", meta: "release · wishlisted", seed: "vellum97"}
    ]
  end

  @doc """
  Timed occurrences, in `Kati.Calendar.Layout` shape.

  Clock times are the drawing's, not approximations of it: 08:00, a two-way
  clash at 09:30, a three-way one at 13:00, a todo at 15:00, the renewals at
  18:00 (see `money/0`), three episodes collapsing at 20:00 and a leaving
  notice at 23:15.

  Two fields exist only because the drawing draws them:

    * `:rail` overrides the kind colour on Design review, which the drawing
      alone among the meetings paints orange.
    * `:flat` sinks the 23:15 row onto `#F4F1EC` the way a done or todo row
      sinks. It is a notice rather than an appointment — nothing to do, and
      nothing to tick — so it sits with the settled rows.

  The counts add up to the header's own `14 items · 2 clashes`, and to the
  chips' `6 + 6 + 2`: the third 13:00 item — the one the `+1` tile hides — is
  a Screen item, which is the only split of these rows that reaches 6/6/2.
  """
  @spec occurrences() :: [map()]
  def occurrences do
    [
      # 08:00 — a habit, already ticked. One line: the tick says the rest.
      %{id: 1, start_min: 480, end_min: 510, kind: :habit, title: "Morning run", done: true},
      # 09:30 — two at once.
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
      # 13:00 — three at once, capped at two lanes with a +1 tile.
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
      # 15:00 — a todo, and the only thing on the day that can be ticked.
      %{id: 7, start_min: 900, end_min: 930, kind: :todo, title: "Renew passport", todo: true},
      # 20:00 — three episodes, which Layout folds into one grouped card.
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
      # 23:15 — a deadline you did not set. Flat paper, and a poster instead
      # of a kind rail.
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

  @doc "Money renewals, merged into one row — the design's `2 renewals`, at 18:00."
  @spec money() :: map()
  def money, do: %{count: 2, at: "18:00", label: "2 renewals", total: "£22.98"}

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
