defmodule Kati.CalendarSelectedDateTest do
  @moduledoc """
  One selected day across the calendar's five views.

  Picking a date on the month grid did not reach screen 02: the Schedule, the
  month, the week and the agenda are roots, `Kati.Screens.Root.mount/3` drops
  push params, and nothing else held the day. `Kati.Calendars.SelectedDate`
  holds it now, and these tests walk the reader's own paths through it — pick
  on one view, arrive on another, and find the same day there.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendars.SelectedDate
  alias Kati.Screens.Agenda
  alias Kati.Screens.Calendar
  alias Kati.Screens.Day
  alias Kati.Screens.MonthGrid
  alias Kati.Screens.ViewSwitcher
  alias Kati.Screens.Week

  doctest Kati.Calendars.SelectedDate

  @key "calendar:selected_date"

  setup do
    SelectedDate.reset()
    :ok
  end

  describe "the store" do
    test "answers today when nothing is selected" do
      assert SelectedDate.get() == Kati.Time.today()
    end

    test "answers the day put, and today again after a reset" do
      day = Date.add(Kati.Time.today(), 40)

      assert SelectedDate.put(day) == day
      assert SelectedDate.get() == day
      assert SelectedDate.reset() == Kati.Time.today()
      assert SelectedDate.get() == Kati.Time.today()
    end

    test "a day stored by another launch reads as today" do
      Mob.State.put(@key, {:an_earlier_launch, ~D[2026-01-05]})

      assert SelectedDate.get() == Kati.Time.today()
    end
  end

  describe "the month grid hands its day to the Schedule" do
    test "a day picked on 16 is the day 02 mounts on" do
      day = other_day_this_month()

      view = mount_screen(MonthGrid) |> tapped(MonthGrid.day_tag(day))

      assert navigated_to(view) == nil
      assert assigns(view).date == day
      assert SelectedDate.get() == day

      schedule = mount_screen(Calendar)
      assert assigns(schedule).date == day
      assert assigns(schedule).rows == Calendar.day_rows(day)
      assert text(schedule) =~ Calendar.subtitle(day, 0)
    end

    test "coming back to a Schedule already underneath reads the day again" do
      schedule = mount_screen(Calendar)
      day = other_day_this_month()

      mount_screen(MonthGrid) |> tapped(MonthGrid.day_tag(day))
      back = render_info(schedule, {:kati, :resumed, nil})

      assert assigns(back).date == day
      assert assigns(back).rows == Calendar.day_rows(day)
    end

    test "a month moved on 16 moves the Schedule with it" do
      view = mount_screen(MonthGrid) |> tapped(:month_next)
      {first, _last} = Kati.Locale.month_span(assigns(view).date)

      assert assigns(view).date == first
      assert assigns(mount_screen(Calendar)).date == first
    end
  end

  describe "the week hands its day to the Schedule" do
    test "a lane named on 17 is the day 02 mounts on" do
      view = mount_screen(Week)
      day = Enum.find(assigns(view).week.lanes, &(not &1.selected?)).date

      view = tapped(view, Week.lane_tag(day))

      assert navigated_to(view) == nil
      assert assigns(mount_screen(Calendar)).date == day
    end

    test "a week moved on 17 moves the Schedule a week" do
      view = mount_screen(Week) |> tapped(:week_next)
      day = Date.add(Kati.Time.today(), 7)

      assert assigns(view).date == day
      assert assigns(mount_screen(Calendar)).date == day
    end
  end

  describe "the Schedule hands its day to every view" do
    test "a day picked on 02 is the day 16, 17 and 30 open on" do
      schedule = mount_screen(Calendar)
      day = strip_day(schedule)

      tapped(schedule, strip_tag(day))

      month = mount_screen(MonthGrid)
      assert assigns(month).date == day
      assert Enum.find(assigns(month).month.days, & &1.selected?).date == day

      week = mount_screen(Week)
      assert assigns(week).date == day
      assert Enum.find(assigns(week).week.lanes, & &1.selected?).date == day

      assert assigns(mount_screen(Agenda)).date == day
      assert assigns(mount_screen(Day)).date == day
    end

    test "the Today pill is a control, and it puts every view back on today" do
      today = Kati.Time.today()
      schedule = mount_screen(Calendar)
      day = strip_day(schedule)

      schedule = tapped(schedule, strip_tag(day))
      assert assigns(schedule).date == day

      assert find(schedule, :row, on_tap: {self(), :today}),
             "the Today pill carries no tap"

      schedule = tapped(schedule, :today)

      assert navigated_to(schedule) == nil
      assert assigns(schedule).date == today
      assert assigns(schedule).rows == Calendar.day_rows(today)
      assert assigns(mount_screen(MonthGrid)).date == today
      assert assigns(mount_screen(Week)).date == today
    end
  end

  describe "the switcher keeps the day" do
    test "Month → Day, Week → Day and Agenda → Day all open the selected day" do
      day = Date.add(Kati.Time.today(), 2)
      SelectedDate.put(day)

      for module <- [MonthGrid, Week, Agenda] do
        view = mount_screen(module) |> tapped(:view_Day)

        assert view.socket.__mob__.nav_action == {:push, Day, %{date: day}},
               "#{inspect(module)}'s Day segment did not carry #{day}"
      end
    end

    test "Month → Week and Week → Month land on the same day" do
      day = Date.add(Kati.Time.today(), 9)
      SelectedDate.put(day)

      assert navigated_to(mount_screen(MonthGrid) |> tapped(:view_Week)) == Week
      assert assigns(mount_screen(Week)).date == day

      assert navigated_to(mount_screen(Week) |> tapped(:view_Month)) == MonthGrid
      assert assigns(mount_screen(MonthGrid)).date == day
    end

    test "a second tap on the month's selected day opens 09 on it" do
      day = other_day_this_month()

      view = mount_screen(MonthGrid) |> tapped(MonthGrid.day_tag(day))
      view = tapped(view, MonthGrid.day_tag(day))

      assert view.socket.__mob__.nav_action == {:push, Day, %{date: day}}
      assert assigns(mount_screen(Day, %{date: day})).date == day
      assert assigns(mount_screen(Calendar)).date == day
    end

    test "a second tap on the week's named lane opens 09 on it" do
      view = mount_screen(Week)
      day = Enum.find(assigns(view).week.lanes, &(not &1.selected?)).date

      view = view |> tapped(Week.lane_tag(day)) |> tapped(Week.lane_tag(day))

      assert view.socket.__mob__.nav_action == {:push, Day, %{date: day}}
      assert assigns(mount_screen(Calendar)).date == day
    end

    test "09's density disc opens the agenda, on the same day" do
      day = Date.add(Kati.Time.today(), 5)
      SelectedDate.put(day)

      view = mount_screen(Day, %{date: day})
      assert find_tap(view, :view_Agenda), "the density disc carries no tap"

      assert navigated_to(tapped(view, :view_Agenda)) == Agenda
      assert assigns(mount_screen(Agenda)).date == day
    end

    test "the segments are drawn in the reader's language and still route" do
      Kati.Locale.put(:fa)

      view = mount_screen(MonthGrid)
      words = text(view)

      for key <- ~w(Day Week Agenda) do
        assert words =~ Kati.Locale.as(:fa, fn -> ViewSwitcher.label(key) end)
        assert find_tap(view, String.to_atom("view_" <> key)), "no view_#{key} tap under :fa"
      end

      refute words =~ "Agenda"
    end
  end

  describe "the agenda's footer" do
    test "reaches thirty days further, from the same day" do
      view = mount_screen(Agenda)
      through = assigns(view).agenda.through

      view = tapped(view, :agenda_more)

      assert assigns(view).agenda.through == Date.add(through, 30)
      assert assigns(view).date == Kati.Time.today()
    end
  end

  describe "Persian month and week navigation" do
    test "the month grid steps Shamsi months, and the Schedule follows" do
      Kati.Locale.put(:fa)
      SelectedDate.put(~D[2026-03-25])

      view = mount_screen(MonthGrid)

      assert {assigns(view).month.first, assigns(view).month.last} ==
               {~D[2026-03-21], ~D[2026-04-20]}

      assert assigns(view).month.title =~ "فروردین"

      view = tapped(view, :month_previous)
      assert assigns(view).date == ~D[2026-02-20]
      assert assigns(view).month.last == ~D[2026-03-20]
      assert assigns(view).month.title =~ "اسفند"
      assert assigns(mount_screen(Calendar)).date == ~D[2026-02-20]

      view = view |> tapped(:month_next) |> tapped(:month_next)
      assert assigns(view).date == ~D[2026-04-21]
      assert assigns(view).month.title =~ "اردیبهشت"
      assert SelectedDate.get() == ~D[2026-04-21]
    end

    test "every Shamsi month grid is whole weeks from Saturday and holds its month" do
      Kati.Locale.put(:fa)
      SelectedDate.put(~D[2026-03-21])

      Enum.reduce(1..12, mount_screen(MonthGrid), fn _step, view ->
        month = assigns(view).month
        first_cell = hd(month.days).date

        assert Date.day_of_week(first_cell) == 6, "#{month.title} does not start on Saturday"
        assert rem(length(month.days), 7) == 0
        assert Enum.any?(month.days, &(&1.date == month.first and &1.in_month?))
        assert Enum.any?(month.days, &(&1.date == month.last and &1.in_month?))
        assert (Date.diff(month.last, month.first) + 1) in 29..31

        tapped(view, :month_next)
      end)
    end

    test "the week runs Saturday to Friday and steps a week at a time" do
      Kati.Locale.put(:fa)
      SelectedDate.put(~D[2026-09-24])

      view = mount_screen(Week)
      assert assigns(view).week.start == ~D[2026-09-19]
      assert Date.day_of_week(assigns(view).week.start) == 6

      view = tapped(view, :week_previous)
      assert assigns(view).week.start == ~D[2026-09-12]
      assert assigns(mount_screen(Calendar)).date == ~D[2026-09-17]
    end
  end

  defp tapped(view, tag), do: render_info(view, {:tap, tag})

  defp strip_tag(date), do: String.to_atom("day_" <> Date.to_iso8601(date))

  defp find_tap(view, tag) do
    view
    |> flatten()
    |> Enum.find(fn node ->
      case Map.get(Map.get(node, :props) || %{}, :on_tap) do
        {_pid, ^tag} -> true
        ^tag -> true
        _other -> false
      end
    end)
  end

  defp strip_day(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(Map.get(node, :props) || %{}, :on_tap) do
        {_pid, tag} when is_atom(tag) -> strip_date(Atom.to_string(tag))
        _other -> []
      end
    end)
    |> Enum.find(&(&1 != Kati.Time.today())) || flunk("the strip drew no day but today")
  end

  defp strip_date("day_" <> iso), do: [Date.from_iso8601!(iso)]
  defp strip_date(_tag), do: []

  defp other_day_this_month do
    today = Kati.Time.today()
    {first, last} = Kati.Locale.month_span(today)
    if today == last, do: first, else: Date.add(today, 1)
  end
end
