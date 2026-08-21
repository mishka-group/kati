defmodule Kati.Calendar.SampleMealDay do
  @moduledoc """
  Screen 52's day: Monday 17 August, with five meals on the spine.

  The design's caption states the decision this data exists to make visible:
  *"Meals join the spine on equal terms with a bronze lane colour, and inherit
  the density rules already written — five in a day collapse to one row exactly
  as six episodes do."* So the day is drawn twice over — eight expanded rows,
  then the collapsed summary underneath — because the screen is an argument
  about density, and one of those two states alone would not make it.

  Three row states, and they are three different facts:

    * **past** — `#F4F1EC`, no lift, muted title. The morning has happened.
    * **eaten** — past, plus a filled green check. A meal you logged.
    * **live** — card white with the usual lift, and an empty ring on the
      meals, because an unlogged meal is a thing you can still do.

  Bronze (`#B08E55`) is the meal lane throughout, which is what lets five rows
  read as one section without a heading.

  Stand-in data until the Meals domain lands, marked as such.
  """

  @meal 0xFFB08E55
  @habit 0xFF4E9A73
  @personal 0xFF1A1917
  @screen 0xFFE8823C

  @doc "The day the screen renders."
  @spec day() :: map()
  def day do
    %{
      title: "Mon 17 Aug",
      subtitle: "5 meals · 6 other items",
      chips: chips(),
      rows: rows(),
      collapsed: collapsed(),
      note:
        "Five meals a day would drown the calendar, so they obey the same 3+ rule as episodes."
    }
  end

  @doc "The section filters. `All` carries no count; the sections carry theirs."
  @spec chips() :: [{String.t(), String.t() | nil}]
  def chips, do: [{"All", nil}, {"Meals", "5"}, {"Screen", "2"}, {"Personal", "4"}]

  @doc "The day's spine, in clock order, meals and everything else together."
  @spec rows() :: [map()]
  def rows do
    [
      %{
        time: "07:30",
        rule: @meal,
        title: "Breakfast — overnight oats",
        sub: "410 kcal",
        state: :past,
        check: :eaten
      },
      %{
        time: "08:00",
        rule: @habit,
        title: "Morning run",
        sub: "12-day streak",
        state: :past,
        check: :none
      },
      %{
        time: "10:30",
        rule: @meal,
        title: "Snack — yoghurt, walnuts",
        sub: "180 kcal",
        state: :live,
        check: :todo
      },
      %{
        time: "11:00",
        rule: @personal,
        title: "Dentist — Marlow Clinic",
        sub: "11:00 – 11:45",
        state: :live,
        check: :none
      },
      %{
        time: "13:00",
        rule: @meal,
        title: "Lunch — chicken, quinoa",
        sub: "540 kcal",
        state: :live,
        check: :todo
      },
      %{
        time: "16:00",
        rule: @meal,
        title: "Snack — apple, almond butter",
        sub: "210 kcal",
        state: :live,
        check: :todo
      },
      %{
        time: "19:30",
        rule: @meal,
        title: "Dinner — miso salmon",
        sub: "620 kcal",
        state: :live,
        check: :todo
      },
      %{
        time: "20:00",
        rule: @screen,
        title: "The Long Hollow S2E6",
        sub: "Lumen+",
        state: :live,
        check: :none
      }
    ]
  end

  @doc """
  The same five meals as one row.

  The mono line is upper-case in the drawing's own markup rather than by
  `text-transform`, so it is stored the way it is drawn — this is the design's
  literal, not a caps decision taken here.
  """
  @spec collapsed() :: map()
  def collapsed do
    %{rule: @meal, title: "5 meals · 1,960 kcal", sub: "1 EATEN · NEXT AT 10:30"}
  end
end
