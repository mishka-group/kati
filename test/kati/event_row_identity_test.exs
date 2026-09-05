defmodule Kati.EventRowIdentityTest do
  @moduledoc """
  Tapping the second row opens the second event (#84).

  ## The defect, stated as the test that would have caught it

  `Mob.Socket.push_screen/3` has taken a params map since the pinned Mob, and
  screen 02's timeline pushed screen 31 with none: `row_event` named the
  DESTINATION and nothing about the row. Screen 31 then assigned
  `Kati.Calendar.SampleEvent.event/0` unconditionally, so every row on the day
  opened the same page. Nothing in the suite could see it — the tap sweep
  presses the tag and gets a push, the reachability sweep gets an edge, and the
  design sweeps compare a screen that was never opened from a list.

  Every assertion here is therefore about the SECOND of three rows, and each one
  says explicitly what the wrong answers would be: the first row's event (the
  order-independent bug — any re-query takes it), and the sample (the
  no-identity bug — the push said nothing, so the screen fell back).

  ## Why the whole file runs inside one rolled-back transaction

  These tests need a day whose rows they know completely — three events and
  nothing else — and this suite has no Ecto sandbox: `test/test_helper.exs`
  migrates one SQLite file that every test shares, and several of them insert
  rows that outlive them. Emptying `events` and writing three inside a
  transaction that is always rolled back is the shape
  `Kati.ScreenEmptyDatabaseTest` and `Kati.ScreenSweep.rolled_back/1` already
  use for the mirror-image job. `pool_size` is 1 (`Kati.Repo.init/2`) and this
  module is `async: false`, so the test process holds the only connection: the
  renders read through it and see the three, and the rest of the suite's rows
  are still there afterwards.

  The alternative — write the rows, assert, delete them in `on_exit` — leaks the
  moment an assertion raises, and what it leaks is events on a day
  `Kati.CalendarDayRouteTest` asserts is empty and
  `Kati.ScreenDesignLiteralTest` renders screen 02 for. A rolled-back
  transaction cannot leak, including when the test fails.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendar.SampleDay
  alias Kati.Calendar.SampleEvent
  alias Kati.Calendars.Event
  alias Kati.Screens.Day
  alias Kati.Screens.EventDetail
  # Not `as: Calendar`: `Calendar.strftime/2` builds the authored wall clock
  # below, and an alias on that name would send it to the screen module.
  alias Kati.Screens.Calendar, as: Schedule

  # The three rows of the day under test, in the order the timeline draws them.
  # Three rather than two: with two, "the second" and "the last" are the same
  # row, and a screen that took the last one back would pass.
  @rows [
    {~T[09:00:00], ~T[09:30:00], "Standup"},
    {~T[11:00:00], ~T[11:45:00], "Dentist — Marlow Clinic"},
    {~T[13:00:00], ~T[14:00:00], "Lunch — Jo"}
  ]

  describe "a timeline row names its own event" do
    test "every row's tap tag is an atom carrying that row's id" do
      in_a_day_of_three(fn %{events: events} ->
        tags = row_tags(mount_screen(Schedule))

        assert length(tags) == 3,
               "the timeline drew #{length(tags)} row taps, not the day's three: " <>
                 inspect(tags)

        for {tag, event} <- Enum.zip(tags, events) do
          assert is_atom(tag),
                 "#{inspect(tag)} is not an atom, so the card it tags renders with no " <>
                   "accessibility_id and no device test or screen reader can address it"

          assert Atom.to_string(tag) == "row_event_" <> event.id
        end
      end)
    end

    test "the second row's tag is the second event's, not the first's" do
      in_a_day_of_three(fn %{events: [first, second, _third]} ->
        second_tag = Enum.at(row_tags(mount_screen(Schedule)), 1)

        assert Atom.to_string(second_tag) == "row_event_" <> second.id
        refute Atom.to_string(second_tag) == "row_event_" <> first.id
      end)
    end
  end

  describe "the push into screen 31" do
    test "carries the id of the row that was tapped" do
      in_a_day_of_three(fn %{events: [first, second, _third]} ->
        view = mount_screen(Schedule)
        opened = render_info(view, {:tap, Enum.at(row_tags(view), 1)})

        assert navigated_to(opened) == EventDetail
        assert opened.socket.__mob__.nav_action == {:push, EventDetail, %{id: second.id}}

        refute opened.socket.__mob__.nav_action == {:push, EventDetail, %{id: first.id}},
               "the second row pushed the first row's event, which is the defect: a screen " <>
                 "that re-queries the day takes whichever row comes back first"
      end)
    end

    test "each of the three rows pushes its own, so no two rows lead to one page" do
      in_a_day_of_three(fn %{events: events} ->
        view = mount_screen(Schedule)

        pushed =
          for tag <- row_tags(view) do
            {:push, EventDetail, %{id: id}} =
              render_info(view, {:tap, tag}).socket.__mob__.nav_action

            id
          end

        assert pushed == Enum.map(events, & &1.id)
      end)
    end
  end

  describe "screen 31 opens what it was handed" do
    test "the second event's title, not the first's and not the sample's" do
      in_a_day_of_three(fn %{events: [first, second, _third]} ->
        view = mount_screen(EventDetail, %{id: second.id})

        assert assigns(view).event.title == second.summary
        refute assigns(view).event.title == first.summary
        refute assigns(view).event.title == SampleEvent.event().title

        assert find(view, :text, text: second.summary),
               "screen 31 does not draw the title of the event it was opened with"
      end)
    end

    test "the clock line is that event's own, so the page is not just titled right" do
      in_a_day_of_three(fn %{events: [_first, second, _third]} ->
        view = mount_screen(EventDetail, %{id: second.id})
        [when_row | _rest] = assigns(view).event.fields

        assert when_row.sub == "11:00 – 11:45"
        assert when_row.trailing == {:value, "45m"}
        assert when_row.title == day_line(Kati.Time.today())

        # The drawing's own row, which is what a screen that fell back would
        # still be showing — same shape, same icon, a different Thursday.
        [drawn | _rest] = SampleEvent.fields()
        refute when_row.sub == drawn.sub
      end)
    end

    test "an id that names nothing stored falls back to the drawn event" do
      in_a_day_of_three(fn _day ->
        assert EventDetail.event(%{id: Ecto.UUID.generate()}) == SampleEvent.event()
      end)
    end

    test "no id at all is still the drawn event, to the term" do
      in_a_day_of_three(fn _day ->
        # The branch every frame of `test/design/screens/31.html` was captured
        # in, and the one the empty-database sweep renders. A round that made
        # the sample path query "the first event of today" would fail here and
        # nowhere else — the tree would still hold a title, a clock and a clash.
        assert EventDetail.event(%{}) == SampleEvent.event()
        assert assigns(mount_screen(EventDetail)).event == SampleEvent.event()
      end)
    end
  end

  describe "screen 09 draws the day it was handed" do
    test "the second day's events, not today's and not the sample's" do
      in_a_day_of_three(fn %{events: today, tomorrow: tomorrow} ->
        view = mount_screen(Day, %{date: Date.add(Kati.Time.today(), 1)})

        assert assigns(view).date == Date.add(Kati.Time.today(), 1)
        assert Enum.map(assigns(view).occurrences, & &1.id) == Enum.map(tomorrow, & &1.id)

        refute Enum.map(assigns(view).occurrences, & &1.id) == Enum.map(today, & &1.id),
               "screen 09 drew the events of the day the clock is on rather than the day " <>
                 "the route handed it"

        assert text(view) =~ hd(tomorrow).summary
      end)
    end

    test "the heading is the handed date, and its count is that day's" do
      in_a_day_of_three(fn %{tomorrow: tomorrow} ->
        date = Date.add(Kati.Time.today(), 1)
        view = mount_screen(Day, %{date: date})

        assert find(view, :text, text: day_line(date)),
               "screen 09's heading is not #{inspect(day_line(date))}, the day it was handed"

        assert text(view) =~ "#{length(tomorrow)} items",
               "the mono subtitle still holds the drawing's own headline over a real day"

        refute text(view) =~ SampleDay.summary()
      end)
    end

    test "a handed day with nothing on it renders as empty, not as the drawing" do
      in_a_day_of_three(fn _day ->
        view = mount_screen(Day, %{date: Date.add(Kati.Time.today(), 30)})

        assert assigns(view).occurrences == []
        assert text(view) =~ "Nothing scheduled"
        refute text(view) =~ "£22.98"
      end)
    end

    test "no date at all is still the drawn day, band and renewals and all" do
      in_a_day_of_three(fn _day ->
        # `Kati.Screens.ViewSwitcher` pushes 09 bare, and this is the state the
        # design was captured in. Asserted on the assigns AND on the tree: the
        # occurrences alone would still be the sample's while the furniture the
        # `drawn?` flag gates had quietly gone.
        view = mount_screen(Day)

        assert assigns(view).date == Kati.Time.today()
        assert assigns(view).occurrences == SampleDay.occurrences()
        assert text(view) =~ SampleDay.summary()
        assert text(view) =~ "£22.98"
        assert text(view) =~ "Vellum — in cinemas"
      end)
    end
  end

  # The same defect, one screen over. A reminder row on the notifications inbox
  # built its tap from `candidate.domain`, so every calendar reminder on the
  # page drew the tag `:open_calendar` and opened the Calendar ROOT — the day
  # you are already looking at, rather than the event the reminder was about.
  # The row had the whole candidate in hand and passed one field of it.
  #
  # Asserted on the second of three for `row_tags/1`'s reason: with two rows,
  # "the second" and "the last" are the same row.
  describe "a notification row names its own event" do
    test "each calendar candidate's tag carries that event's primary key" do
      in_a_day_of_three(fn %{events: events} ->
        candidates = calendar_candidates()

        assert length(candidates) == 3,
               "the calendar source answered #{length(candidates)} candidates, not the day's " <>
                 "three: " <> inspect(Enum.map(candidates, & &1.id))

        for {candidate, event} <- Enum.zip(candidates, events) do
          tag = Kati.Screens.InboxNotifications.tag_for(candidate)

          assert Atom.to_string(tag) == "open_calendar_" <> event.id

          refute tag == :open_calendar,
                 "the row still draws the domain's bare tag, so all three reminders share " <>
                   "one accessibility_id and all three open the Calendar root"
        end
      end)
    end

    test "the second reminder pushes the second event, not the first and not the root" do
      in_a_day_of_three(fn %{events: [first, second, _third]} ->
        view = mount_screen(Kati.Screens.InboxNotifications)
        tag = Kati.Screens.InboxNotifications.tag_for(Enum.at(calendar_candidates(), 1))
        opened = render_info(view, {:tap, tag})

        assert navigated_to(opened) == EventDetail
        assert opened.socket.__mob__.nav_action == {:push, EventDetail, %{id: second.id}}

        refute opened.socket.__mob__.nav_action == {:push, EventDetail, %{id: first.id}}
        refute navigated_to(opened) == Schedule
      end)
    end

    test "a calendar candidate carrying no event id still opens where it always did" do
      # The fallback the five other domains take, and the one a candidate built
      # before its source carried the key takes too. `:open_calendar` is still a
      # clause on the screen and still reaches the Calendar root.
      bare =
        Kati.Notifications.Candidate.absolute(
          "cal:no-key",
          :calendar,
          DateTime.utc_now(),
          meta: %{uid: "u"}
        )

      assert Kati.Screens.InboxNotifications.tag_for(bare) == :open_calendar
    end

    test "a domain with nowhere of its own to go is unchanged, candidate or atom" do
      meal =
        Kati.Notifications.Candidate.absolute("meal:1", :meals, DateTime.utc_now(),
          meta: %{slot_id: "s"}
        )

      assert Kati.Screens.InboxNotifications.tag_for(meal) == :open_meals
      assert Kati.Screens.InboxNotifications.tag_for(:meals) == :open_meals
    end
  end

  # ── the day these tests run against ────────────────────────────────────────

  # Three events today and two tomorrow, in a database emptied of every other
  # event, all inside one transaction that is always rolled back. `fun` is
  # handed the rows it can name.
  defp in_a_day_of_three(fun) do
    {:error, {:done, result}} =
      Kati.Repo.transaction(fn ->
        empty_the_events!()
        calendar = calendar!()
        today = Kati.Time.today()

        events = for {from, to, title} <- @rows, do: event!(calendar, today, from, to, title)

        tomorrow =
          for {from, to, title} <- Enum.take(@rows, 2),
              do: event!(calendar, Date.add(today, 1), from, to, "Tomorrow's #{title}")

        Kati.Repo.rollback({:done, fun.(%{events: events, tomorrow: tomorrow})})
      end)

    result
  end

  # Events only. The calendars they hang off stay, because deleting those would
  # empty a table screen 32 reads and this file has nothing to say about it —
  # and the transaction takes the new calendar back either way.
  defp empty_the_events! do
    for table <- ~w(event_occurrence_overrides events),
        do: Kati.Repo.query!("delete from #{table}")

    :ok
  end

  defp calendar! do
    Kati.Calendars.Calendar
    |> Ash.Changeset.for_create(:create, %{
      display_name: "Row identity #{System.unique_integer([:positive])}",
      kind: :local
    })
    |> Ash.create!()
  end

  # The same timing `Kati.Seeds` writes: a UTC instant for the range query, the
  # authored wall clock beside it, and the length as a DURATION rather than an
  # end instant — which is what `Kati.Calendars.Event`'s moduledoc requires and
  # what `dtend_utc` is then derived from.
  defp event!(calendar, date, from, to, summary) do
    zone = Kati.Time.device_zone()
    naive = NaiveDateTime.new!(date, from)
    {:ok, utc} = Kati.Time.to_utc(naive, zone)
    minutes = div(Time.diff(to, from, :second), 60)

    Event
    |> Ash.Changeset.for_create(:create, %{
      uid: "kati-row-identity-#{System.unique_integer([:positive])}@kati",
      calendar_id: calendar.id,
      origin: :kati,
      summary: summary,
      kind: :event,
      status: :confirmed,
      dtstart_utc: utc,
      dtstart_wall: Calendar.strftime(naive, "%Y%m%dT%H%M%S"),
      tzid: zone,
      duration_iso: "PT#{minutes}M",
      sync_state: :local_only
    })
    |> Ash.create!()
  end

  # ── reading the screens ────────────────────────────────────────────────────

  # The `row_*` tags the timeline drew, in the order it drew them. Read off the
  # tree rather than rebuilt from the rows: a helper that recomputed the tags
  # here would agree with a broken `tag/1` about what they are.
  defp row_tags(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(Map.get(node, :props) || %{}, :on_tap) do
        {pid, tag} when is_pid(pid) ->
          if String.starts_with?(Atom.to_string(tag), "row_"), do: [tag], else: []

        _other ->
          []
      end
    end)
    |> Enum.uniq()
  end

  # `Thu 20 Aug` — screen 09's heading and screen 31's first field row are the
  # same line, so it is written once here too.
  defp day_line(%Date{} = date) do
    day = Kati.Time.day_name(date) |> String.slice(0, 3)
    month = Kati.Time.month_name(date.month) |> String.slice(0, 3)
    "#{day} #{date.day} #{month}"
  end

  # The day's calendar candidates, in the order the source answers them —
  # `dtstart_utc` ascending, which is the order the timeline draws too. Built
  # through the source rather than assembled here, for `row_tags/1`'s reason: a
  # helper that wrote its own `meta` would agree with a broken source about what
  # a candidate carries.
  defp calendar_candidates do
    zone = Kati.Time.device_zone()
    day = Kati.Time.today()

    day
    |> Kati.Notifications.Sources.Calendar.events(zone)
    |> Kati.Notifications.Sources.Calendar.candidates(zone: zone)
  end
end
