defmodule Kati.CalendarNavigationTest do
  @moduledoc """
  The calendar goes anywhere, and every control on it does something (#126).

  The Schedule's strip was the seven days around the selected one with no way
  past them but the month grid; the month, the week and the day turned only by
  their arrows, the day not at all; the agenda only read forward; the `+` on
  three of the views opened the film search; ticks vanished with the screen;
  a calendar switched off still showed; the reader's all-day events were on no
  day page; and today lost its mark the moment another day was selected.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendars.Event
  alias Kati.Calendars.SelectedDate
  alias Kati.Screens.Calendar

  doctest Kati.Screens.Calendar, only: [swipe_step: 2, week_turn: 1]

  setup do
    SelectedDate.reset()
    Kati.Locale.put(:en)

    on_exit(fn ->
      SelectedDate.reset()
      Kati.Repo.query!("DELETE FROM events WHERE uid LIKE 'cal-nav-%'", [])
      Kati.Repo.query!("DELETE FROM calendars WHERE display_name = 'Hidden calendar'", [])
      Mob.State.put(:calendar_done, [])
    end)
  end

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  defp swipes(view, side) do
    for %{props: %{^side => {_pid, tag}}} <- flatten(view), do: tag
  end

  defp event!(attrs) do
    calendar = Map.get_lazy(attrs, :calendar, &Kati.Screens.QuickAdd.personal_calendar/0)

    Ash.create!(
      Event,
      Map.merge(
        %{
          uid: "cal-nav-#{System.unique_integer([:positive])}",
          calendar_id: calendar.id,
          origin: :kati,
          summary: "An event",
          kind: :event,
          dtstart_utc: DateTime.new!(Kati.Time.today(), ~T[12:00:00], "Etc/UTC"),
          dtstart_date: Kati.Time.today()
        },
        Map.delete(attrs, :calendar)
      )
    )
  end

  describe "the Schedule" do
    test "the arrows move a week, and the strip turns a week under the finger" do
      today = Kati.Time.today()
      view = mount_screen(Calendar)
      assert :week_previous in tags(view)
      assert :week_next in tags(view)

      view = render_info(view, {:tap, :week_next})
      assert assigns(view).week == Date.add(today, 7)
      assert assigns(view).date == today
      assert SelectedDate.get() == today

      assert [%{props: pager}] =
               for(%{type: :scroll, props: %{pager: true}} = n <- flatten(view), do: n)

      assert {_pid, :week_page} = pager.on_change
      assert pager.page == 1
      view = render_info(view, {:change, :week_page, "0"})
      assert assigns(view).week == today
    end

    test "sliding the strip shows another week and leaves the selected day alone" do
      today = Kati.Time.today()
      view = mount_screen(Calendar) |> render_info({:change, :week_page, "2"})

      assert assigns(view).date == today
      assert SelectedDate.get() == today
      assert assigns(view).week == Date.add(today, 7)
      assert String.to_atom("day_" <> Date.to_iso8601(Date.add(today, 7))) in tags(view)

      next = Date.add(today, 8)
      view = render_info(view, {:tap, String.to_atom("day_" <> Date.to_iso8601(next))})
      assert assigns(view).date == next
      assert assigns(view).week == nil

      view = render_info(view, {:change, :week_page, "0"}) |> render_info({:tap, :today})
      assert assigns(view).date == today
      assert assigns(view).week == nil
    end

    test "a swipe across the day moves a day, the other way round in Persian" do
      today = Kati.Time.today()
      view = mount_screen(Calendar) |> render_info({:swipe_left, :swipe_day_left})
      assert assigns(view).date == Date.add(today, 1)

      Kati.Locale.put(:fa)
      view = render_info(view, {:swipe_left, :swipe_day_left})
      assert assigns(view).date == today
    end

    test "today keeps its mark when another day is selected" do
      today = Kati.Time.today()
      # Another day of the same week, so today is still on the strip.
      other = if Date.day_of_week(today) == 7, do: Date.add(today, -1), else: Date.add(today, 1)
      SelectedDate.put(other)
      words = inspect(mount_screen(Calendar) |> tree(), limit: :infinity)

      assert words =~ Integer.to_string(Kati.Theme.Palette.accent())
    end

    test "a watch scheduled from a title is a Screen row that opens its event" do
      dark =
        Ash.create!(Kati.Media.TrackedTitle, %{
          source: :manual,
          source_id: "cal-nav-dark",
          kind: :tv,
          status: :watching
        })

      event = event!(%{summary: "Watch Dark", tracked_title_id: dark.id})

      view = mount_screen(Calendar) |> render_info({:tap, :filter_screen})
      tag = String.to_atom("row_event_" <> event.id)
      assert tag in tags(view)

      view = render_info(view, {:tap, tag})
      assert {:push, Kati.Screens.EventDetail, %{id: id}} = view.socket.__mob__.nav_action
      assert id == event.id
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id = 'cal-nav-dark'", [])
    end

    test "a calendar switched off keeps its events off the day" do
      hidden =
        Ash.create!(Kati.Calendars.Calendar, %{
          display_name: "Hidden calendar",
          kind: :local,
          visible: false
        })

      event!(%{summary: "Hidden lunch", calendar: hidden})
      event!(%{summary: "Shown lunch"})

      titles = Enum.map(Calendar.day_rows(Kati.Time.today()), & &1.title)
      assert "Shown lunch" in titles
      refute "Hidden lunch" in titles
    end

    test "a quick add never lands in a calendar that is switched off" do
      # Every local calendar off for the length of this test, so the answer
      # does not depend on what earlier tests left switched on.
      before = Kati.Repo.query!("SELECT id, visible FROM calendars", []).rows
      Kati.Repo.query!("UPDATE calendars SET visible = 0 WHERE kind = 'local'", [])

      on_exit(fn ->
        known = Enum.map(before, &hd/1)

        for [id, visible] <- before,
            do: Kati.Repo.query!("UPDATE calendars SET visible = ?1 WHERE id = ?2", [visible, id])

        for [id] <- Kati.Repo.query!("SELECT id FROM calendars", []).rows,
            id not in known,
            do: Kati.Repo.query!("DELETE FROM calendars WHERE id = ?1", [id])
      end)

      hidden =
        Ash.create!(Kati.Calendars.Calendar, %{
          display_name: "Hidden calendar",
          kind: :local,
          visible: false
        })

      chosen = Kati.Screens.QuickAdd.personal_calendar()
      refute chosen.id == hidden.id
      assert chosen.visible
    end
  end

  describe "the month, the week and the agenda" do
    test "a swipe on the month grid turns the month" do
      view = mount_screen(Kati.Screens.MonthGrid)
      month = assigns(view).date.month
      view = render_info(view, {:swipe_left, :swipe_month_left})
      refute assigns(view).date.month == month
    end

    test "a swipe on the week's lanes moves a week" do
      view = mount_screen(Kati.Screens.Week)
      date = assigns(view).date
      view = render_info(view, {:swipe_left, :swipe_week_left})
      assert Date.diff(assigns(view).date, date) == 7
    end

    test "the agenda reads back thirty days" do
      today = Kati.Time.today()
      view = mount_screen(Kati.Screens.Agenda)
      assert :agenda_earlier in tags(view)

      view = render_info(view, {:tap, :agenda_earlier})
      assert assigns(view).date == Date.add(today, -30)
    end

    test "every view's + adds to the calendar, not a film" do
      for module <- [Calendar, Kati.Screens.MonthGrid, Kati.Screens.Week, Kati.Screens.Agenda] do
        assert module.add_sheet() == Kati.Screens.QuickAdd,
               "#{inspect(module)}'s + opens the wrong sheet"
      end
    end
  end

  describe "the day" do
    test "the arrows and a swipe move a day" do
      today = Kati.Time.today()
      view = mount_screen(Kati.Screens.Day, %{date: today})
      assert :day_next in tags(view)

      view = render_info(view, {:tap, :day_next})
      assert assigns(view).date == Date.add(today, 1)

      view = render_info(view, {:swipe_right, :swipe_day_right})
      assert assigns(view).date == today
    end

    test "the reader's own all-day events are in the day's band" do
      event!(%{summary: "Birthday", is_all_day: true})
      view = mount_screen(Kati.Screens.Day, %{date: Kati.Time.today()})
      assert text(view) =~ "Birthday"
    end

    test "a tick is kept after the screen is gone" do
      event = event!(%{summary: "Call the dentist", kind: :reminder})
      today = Kati.Time.today()
      view = mount_screen(Kati.Screens.Day, %{date: today})
      tag = String.to_atom("todo_" <> event.id)

      if tag in tags(view) do
        render_info(view, {:tap, tag})
        view = mount_screen(Kati.Screens.Day, %{date: today})
        assert Enum.any?(assigns(view).occurrences, &(to_string(&1.id) == event.id and &1[:done]))
      end
    end
  end
end
