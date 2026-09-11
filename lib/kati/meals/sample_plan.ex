defmodule Kati.Meals.SamplePlan do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in data for screen 44 — the repeating week.

  The design's caption is the domain decision: *"The plan is a rule, not 52
  copies."* So `matrix/0` is five slots × seven days of **state**, and
  `repeat_rule/0` is the rule itself — a start week and a recurrence — rather
  than a materialised year of meals. `day/0` is what the tapped column lists
  underneath.

  Copy is taken from `test/design/screens/44.html` unchanged.
  """

  @doc "The plan's name, and the mono line under it."
  @spec title() :: String.t()
  def title, do: gettext("Cutting v3")

  @spec subtitle() :: String.t()
  def subtitle, do: gettext("repeats every week")

  @doc """
  The Week / Day / Shop segmented control, Week selected.

      iex> Kati.Meals.SamplePlan.segments() |> Enum.map(&elem(&1, 0))
      [:week, :day, :shop]

  `{key, label}`. The key is the segment's identity and the label is drawn —
  `MishkaSegmentedControl.option/2` took the SAME string for both, so the
  selection was decided by string equality against a drawn English word.
  Board 60's mirror was written specifically to avoid that, minting its tag
  from the segment's INDEX, and mishka-group/kati#103 carries the mirror's
  cleaner pattern back into the one screen. `selected/2` falls back to segment
  0 in SILENCE when a value names no option, so the Persian page would have
  looked right and answered wrong.
  """
  @spec segments() :: [{atom(), String.t()}]
  def segments do
    [{:week, gettext("Week")}, {:day, gettext("Day")}, {:shop, gettext("Shop")}]
  end

  @doc """
  The matrix's column headings — one letter per day, the reader's week first.

      iex> Kati.Meals.SamplePlan.columns()
      ["M", "T", "W", "T", "F", "S", "S"]

  **Positional, not translated.** `M` is Monday and `ش` is Saturday: the two
  lists are not the same seven days in two languages, they are two different
  weeks. The English week opens on Monday and the Persian on شنبه, which is
  what `Kati.Locale.week_start/0` says and board 60's own note spells out —
  *the columns start from the right: Saturday is the first*. A catalogue would
  have paired `M` with `ش` and silently moved every meal two days.

  Sunday is inked rather than muted because it is the day being shown.
  """
  @spec columns() :: [String.t()]
  def columns do
    Kati.Locale.pick(
      ["M", "T", "W", "T", "F", "S", "S"],
      ["ش", "ی", "د", "س", "چ", "پ", "ج"]
    )
  end

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
        name: gettext("Breakfast"),
        time: Kati.Locale.number("07:30"),
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :planned]
      },
      %{
        name: gettext("Snack"),
        time: Kati.Locale.number("10:30"),
        cells: [:planned, :planned, :free, :planned, :free, :planned, :planned]
      },
      %{
        name: gettext("Lunch"),
        time: Kati.Locale.number("13:00"),
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :planned]
      },
      %{
        name: gettext("Snack"),
        time: Kati.Locale.number("16:00"),
        cells: [:planned, :planned, :planned, :planned, :free, :planned, :open]
      },
      %{
        name: gettext("Dinner"),
        time: Kati.Locale.number("19:30"),
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :today]
      }
    ]
  end

  @doc "The matrix's legend, in the order the drawing lays it out."
  @spec legend() :: [{String.t(), atom()}]
  def legend do
    [
      {gettext("Planned"), :planned},
      {gettext("Today"), :today},
      {gettext("Free"), :open}
    ]
  end

  @doc """
  A meal's slot line: its name and its clock.

      iex> Kati.Meals.SamplePlan.slot_line("Dinner", "19:30")
      "Dinner · 19:30"

  The clock's numerals follow the script — `Kati.Locale.number/1` — while the
  24-hour shape does not, because screen 93 draws that as a setting rather
  than as a consequence of the language.
  """
  @spec slot_line(String.t(), String.t()) :: String.t()
  def slot_line(name, clock), do: name <> " · " <> Kati.Locale.number(clock)

  @doc "The eyebrow over the tapped day's list."
  @spec day_line() :: String.t()
  def day_line do
    gettext("%{day} · %{count} meals",
      day: Kati.Locale.pick("Sunday", "یکشنبه"),
      count: Kati.Locale.number(3)
    )
  end

  @doc "Sunday's three meals, as the day list under the matrix draws them."
  @spec day() :: [map()]
  def day do
    [
      %{
        key: :brunch,
        slot: Kati.Meals.SamplePlan.slot_line(gettext("Brunch"), "10:00"),
        clock: Kati.Locale.number("10:00"),
        title: gettext("Eggs, sourdough, avocado"),
        course: gettext("Eggs"),
        calories: Kati.Locale.number(520),
        seed: "mealbrunch"
      },
      %{
        key: :snack,
        slot: Kati.Meals.SamplePlan.slot_line(gettext("Snack"), "16:00"),
        clock: Kati.Locale.number("16:00"),
        title: gettext("Apple, almond butter"),
        course: gettext("Apple"),
        calories: Kati.Locale.number(210),
        seed: "mealapple"
      },
      %{
        key: :dinner,
        slot: Kati.Meals.SamplePlan.slot_line(gettext("Dinner"), "19:30"),
        clock: Kati.Locale.number("19:30"),
        title: gettext("Miso salmon, greens, rice"),
        course: gettext("Miso salmon"),
        calories: Kati.Locale.number(620),
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
      %{
        icon: "repeat",
        title: gettext("Repeats"),
        sub: gettext("Every week, indefinitely"),
        trailing: :chevron
      },
      %{
        icon: "event_available",
        title: gettext("Started"),
        sub:
          gettext("Week %{week} · %{date}",
            week: Kati.Locale.number(6),
            date: Kati.Locale.date(~D[2026-07-06], :dated)
          ),
        trailing: :chevron
      },
      %{
        icon: "edit_calendar",
        title: gettext("Edit this week only"),
        sub: gettext("Changes will not carry forward"),
        trailing: :switch_off
      }
    ]
  end
end
