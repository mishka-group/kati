defmodule Kati.Meals.SampleToday do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in data for screen 43 — the meal plan's own Today.

  Every string here is taken from `test/design/screens/43.html` rather
  than invented, so the built screen can be compared with the drawing line for
  line. The Meals domain does not exist yet; when it does, this module is the
  shape it has to return, and swapping it out is one line in the screen.

  Two things are stored as they are *drawn* rather than as they would be
  *derived*:

    * The week strip's five dots per day are colours, not counts. The drawing
      gives Sunday three green and two empty, and Wednesday four planned and
      one empty — a state per meal slot, which the domain will compute and the
      drawing simply states.
    * The macro bar's 31/44/25 split is declared. Recomputing it from grams
      would give a slightly different bar than the one drawn, and the drawing
      is the reference.
  """

  # The five dots under a day: what the design's three tones mean.
  @done 0xFF4E9A73
  @planned 0xFFC4BDB3
  @empty 0xFFE0DAD1

  @doc "The mono line under the title."
  @spec day_line() :: String.t()
  def day_line,
    do:
      gettext("%{day} · %{count} meals",
        # The fixture's own day, spelled rather than formatted: board 43 writes it
        # long (`Sunday 16 August`) where `Kati.Locale.date/2`'s `:long` is the
        # short form, and board 59 writes the Persian-calendar date the same day
        # falls on.
        # A frozen fixture date is copy.
        day: gettext("Sunday 16 August"),
        count: Kati.Locale.number(5)
      )

  @doc "The plan the day belongs to, named in the pill beside the title."
  @spec plan() :: String.t()
  def plan, do: gettext("Cutting v3")

  @doc """
  The seven days of the strip, Monday first.

  `dots` is one colour per meal slot, so a day with four planned meals and one
  free evening reads as four filled pips and one hollow — the same shorthand
  the week calendar uses.
  """
  @spec week() :: [map()]
  def week do
    [
      %{
        dow: "Mon",
        day: "10",
        today?: false,
        dots: [@planned, @planned, @planned, @planned, @planned]
      },
      %{
        dow: "Tue",
        day: "11",
        today?: false,
        dots: [@planned, @planned, @planned, @planned, @planned]
      },
      %{
        dow: "Wed",
        day: "12",
        today?: false,
        dots: [@planned, @planned, @planned, @planned, @empty]
      },
      %{
        dow: "Thu",
        day: "13",
        today?: false,
        dots: [@planned, @planned, @planned, @planned, @planned]
      },
      %{
        dow: "Fri",
        day: "14",
        today?: false,
        dots: [@planned, @planned, @planned, @empty, @empty]
      },
      %{
        dow: "Sat",
        day: "15",
        today?: false,
        dots: [@planned, @planned, @planned, @planned, @planned]
      },
      %{dow: "Sun", day: "16", today?: true, dots: [@done, @done, @done, @empty, @empty]}
    ]
  end

  @doc "The four quick tiles under the strip: where Meals goes from here."
  @spec tiles() :: [{String.t(), String.t()}]
  def tiles do
    [
      # Library joined the row with screen 116, and it goes FIRST: it is the
      # input to everything else on this page, and a library you reach after
      # the shopping list is a library you build after you needed it.
      {"grid_view", gettext("Library")},
      {"calendar_view_week", gettext("Week")},
      {"shopping_cart", gettext("Shop")},
      {"monitoring", gettext("Nutrition")},
      {"tune", gettext("Plan")}
    ]
  end

  @doc "The eyebrow over the macro card — the day's headline number."
  @spec intake_line() :: String.t()
  def intake_line,
    do:
      gettext("Today · %{eaten} of %{target} kcal",
        eaten: Kati.Locale.number("1,480"),
        target: Kati.Locale.number("2,100")
      )

  @doc "The 9pt bar's three segments, as the drawing splits them."
  @spec macros() :: [{String.t(), float(), non_neg_integer()}]
  def macros do
    [
      {gettext("Protein"), 0.31, 0xFF1A1917},
      {gettext("Carbs"), 0.44, 0xFFB08E55},
      {gettext("Fat"), 0.25, 0xFFE4D2B0}
    ]
  end

  @doc "What is left of the target, in the macro card's right-hand corner."
  @spec remaining() :: String.t()
  def remaining, do: gettext("%{count} kcal left", count: Kati.Locale.number(620))

  @doc """
  The day, in clock order.

  Three states, not two — `:eaten`, `:skipped` and `:next` — because the
  drawing gives each its own card: a logged meal goes flat and grey, a skipped
  one loses its photograph and keeps only an outline, and the one coming up is
  lifted, larger, and carries its actions.
  """
  @spec meals() :: [map()]
  def meals do
    [
      %{
        state: :eaten,
        time: Kati.Locale.number("07:30"),
        slot: gettext("Breakfast"),
        title: gettext("Overnight oats, berries"),
        calories: gettext("%{count} kcal", count: Kati.Locale.number(410)),
        seed: "mealoats"
      },
      %{
        state: :eaten,
        time: Kati.Locale.number("10:30"),
        slot: gettext("Snack"),
        title: gettext("Greek yoghurt, walnuts"),
        calories: gettext("%{count} kcal", count: Kati.Locale.number(180)),
        seed: "mealyog"
      },
      %{
        state: :eaten,
        time: Kati.Locale.number("13:00"),
        slot: gettext("Lunch"),
        title: gettext("Chicken, quinoa, slaw"),
        calories: gettext("%{count} kcal", count: Kati.Locale.number(540)),
        seed: "mealchick"
      },
      %{
        state: :skipped,
        time: Kati.Locale.number("16:00"),
        slot: gettext("Snack"),
        title: gettext("Apple, almond butter"),
        calories: Kati.UI.eyebrow_label(gettext("Skipped")),
        seed: nil
      },
      %{
        state: :next,
        time: Kati.Locale.number("19:30"),
        slot: gettext("Dinner"),
        title: gettext("Miso salmon, greens, rice"),
        calories: gettext("%{count} kcal", count: Kati.Locale.number(620)),
        seed: "mealsalmon"
      }
    ]
  end

  @doc """
  Tomorrow's prep, surfaced tonight.

  The design's caption calls this *"the day-before half of the reminder"* —
  the one thing on this screen that is not about today at all.
  """
  @spec prep() :: map()
  def prep do
    %{
      title: gettext("Soak the oats, thaw the chicken"),
      line:
        gettext("%{day} has %{meals} meals · %{prep} need prep",
          day: Kati.Locale.pick("Monday", "دوشنبه"),
          meals: Kati.Locale.number(5),
          prep: Kati.Locale.number(2)
        ),
      primary: gettext("See tomorrow"),
      secondary: gettext("Done prepping")
    }
  end
end
