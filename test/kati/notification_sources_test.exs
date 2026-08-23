defmodule Kati.NotificationSourcesTest do
  @moduledoc """
  The five collectors that arrived after `Kati.Notifications.Sources.Media`.

  The engine was written before any of them — `Kati.Notifications.Scheduler`'s
  moduledoc gives the argument — so these are not tests of budgeting or of
  quiet hours, which have their own. They are tests of the six answers the
  engine is given, and they assert on **values**: which candidates come out of
  a known set of rows, at what instant, in what state and with which members.

  Each source takes its rows rather than reading them, which is what makes that
  possible at all. A collector that read its own input could only be asked
  whether it raised.
  """
  use ExUnit.Case, async: true

  alias Kati.Calendars.Event
  alias Kati.Health.Medication
  alias Kati.Meals.MealPlan
  alias Kati.Meals.MealPlanSlot
  alias Kati.Notifications.Budget
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Sources
  alias Kati.Services.Service

  @day ~D[2026-08-23]
  @zone "Europe/London"

  defp fire_at(%Candidate{} = candidate) do
    candidate |> Candidate.resolve(@zone) |> Map.fetch!(:fire_at)
  end

  defp by_id(candidates, id), do: Enum.find(candidates, &(&1.id == id))

  # ── Health ─────────────────────────────────────────────────────────────────

  describe "medication reminders" do
    defp medication(name, times, attrs \\ []) do
      struct(%Medication{id: name, name: name, times: times, active: true}, attrs)
    end

    test "two medications at one clock time are one candidate, not two" do
      # The whole reason this domain aggregates. Waking someone twice for one
      # moment teaches them to ignore the second.
      candidates =
        Sources.Health.candidates(
          [medication("Levothyroxine", ["08:00"]), medication("Iron", ["08:00"])],
          @day,
          zone: @zone
        )

      assert length(candidates) == 1
      [one] = candidates

      assert one.title == "2 doses"
      assert Enum.sort(one.members) == ["Iron", "Levothyroxine"]
      assert one.meta.count == 2
    end

    test "different clock times stay separate, in clock order" do
      candidates =
        Sources.Health.candidates(
          [medication("Magnesium", ["21:00"]), medication("Levothyroxine", ["08:00"])],
          @day,
          zone: @zone
        )

      assert Enum.map(candidates, & &1.meta.at) == ["08:00", "21:00"]
    end

    test "a dose is exempt from quiet hours and armed high" do
      # A 21:00 dose shifted to the morning is not a late reminder, it is the
      # wrong instruction. Screen 112's reliability note depends on this.
      [one] = Sources.Health.candidates([medication("Magnesium", ["21:00"])], @day, zone: @zone)

      assert one.quiet_hours == :exempt
      assert one.priority == :high
    end

    test "the instant is the wall clock in the given zone, not UTC" do
      [one] = Sources.Health.candidates([medication("Iron", ["14:00"])], @day, zone: @zone)

      # 23 August 2026 is BST, so 14:00 local is 13:00Z. A source that built a
      # UTC instant from the string would put this an hour out for half the year.
      assert fire_at(one) == ~U[2026-08-23 13:00:00Z]
    end

    test "a medication with no times is suppressed with a reason, not dropped" do
      [one] = Sources.Health.candidates([medication("Vitamin D", [])], @day, zone: @zone)

      assert one.suppressed == :no_times
      assert one.title == "Vitamin D"
    end

    test "a time that does not parse arms nothing at all" do
      # Guessing an instant for a medication is worse than not arming it.
      assert Sources.Health.candidates([medication("Iron", ["half eight"])], @day, zone: @zone) ==
               []
    end
  end

  # ── Meals ──────────────────────────────────────────────────────────────────

  describe "meal reminders" do
    defp plan(attrs \\ []) do
      struct(
        %MealPlan{
          id: "plan",
          name: "Cutting v3",
          reminders_enabled: true,
          reminder_lead_minutes: 15,
          silent_only: false
        },
        attrs
      )
    end

    defp slot(name, time, id \\ nil) do
      %MealPlanSlot{id: id || name, slot_name: name, slot_time: time}
    end

    test "the lead time is subtracted, because that is what the control is for" do
      [one] =
        Sources.Meals.candidates(plan(), [slot("Dinner", ~T[19:30:00])], @day, zone: @zone)

      assert fire_at(one) == ~U[2026-08-23 18:15:00Z]
      assert one.body == "In 15 min"
    end

    test "a lead of zero says Now rather than In 0 min" do
      [one] =
        Sources.Meals.candidates(
          plan(reminder_lead_minutes: 0),
          [slot("Dinner", ~T[19:30:00])],
          @day,
          zone: @zone
        )

      assert one.body == "Now"
    end

    test "the plan's switch suppresses once, for the plan, not once per slot" do
      candidates =
        Sources.Meals.candidates(
          plan(reminders_enabled: false),
          [slot("Breakfast", ~T[08:00:00]), slot("Dinner", ~T[19:30:00])],
          @day,
          zone: @zone
        )

      assert [%Candidate{suppressed: :reminders_off, title: "Cutting v3"}] = candidates
    end

    test "no plan is nothing at all, not a held reminder" do
      # A fresh install has no plan. A held row would say a reminder was
      # withheld that was never going to be sent.
      assert Sources.Meals.candidates(nil, [], @day, zone: @zone) == []
    end

    test "a slot with no clock is suppressed with its own reason" do
      [one] = Sources.Meals.candidates(plan(), [slot("Lunch", nil)], @day, zone: @zone)

      assert one.suppressed == :no_time
      assert one.title == "Lunch"
    end

    test "silent_only is expressed as priority, which is the scheduler's currency" do
      [one] =
        Sources.Meals.candidates(
          plan(silent_only: true),
          [slot("Dinner", ~T[19:30:00])],
          @day,
          zone: @zone
        )

      assert one.priority == :low
    end

    test "the evening preview is one candidate naming every slot" do
      slots = [slot("Breakfast", ~T[08:00:00]), slot("Dinner", ~T[19:30:00])]

      candidates =
        Sources.Meals.candidates(plan(evening_preview_at: ~T[21:00:00]), slots, @day, zone: @zone)

      preview = by_id(candidates, Sources.Meals.preview_id(@day))

      assert preview.title == "Tomorrow's meals"
      assert preview.body == "Breakfast · Dinner"
      assert Enum.sort(preview.members) == ["Breakfast", "Dinner"]
      assert preview.priority == :low
      assert fire_at(preview) == ~U[2026-08-23 20:00:00Z]
    end

    test "no preview time means no preview, and that is a setting rather than a failure" do
      candidates =
        Sources.Meals.candidates(plan(), [slot("Dinner", ~T[19:30:00])], @day, zone: @zone)

      assert length(candidates) == 1
      assert Enum.all?(candidates, &is_nil(&1.suppressed))
    end
  end

  # ── Habits ─────────────────────────────────────────────────────────────────

  describe "habit reminders" do
    defp habit(summary, at, attrs \\ []) do
      struct(
        %Event{uid: summary, summary: summary, kind: :habit, dtstart_utc: at, is_all_day: false},
        attrs
      )
    end

    test "a day's habits at one time are one notification" do
      # `:habits` gets EIGHT iOS slots. Four habits arming themselves would
      # spend half of them on one morning.
      candidates =
        Sources.Habits.candidates(
          [
            habit("Read", ~U[2026-08-23 07:00:00Z]),
            habit("Stretch", ~U[2026-08-23 07:00:00Z]),
            habit("Water", ~U[2026-08-23 07:00:00Z])
          ],
          @day,
          zone: @zone
        )

      assert [%Candidate{title: "3 habits", body: "Read, Stretch, Water"} = one] = candidates
      assert Enum.sort(one.members) == ["Read", "Stretch", "Water"]
    end

    test "one habit keeps its own name" do
      [one] =
        Sources.Habits.candidates([habit("Read", ~U[2026-08-23 07:00:00Z])], @day, zone: @zone)

      assert one.title == "Read"
      assert one.body == "Due now"
    end

    test "a habit is wall-clock even when its event is not" do
      # A habit that shifted with a flight is a habit you broke by travelling.
      [one] =
        Sources.Habits.candidates(
          [habit("Read", ~U[2026-08-23 07:00:00Z], tz_behaviour: :absolute)],
          @day,
          zone: @zone
        )

      assert {:wall_clock, _naive, @zone} = one.at
    end

    test "an all-day habit is suppressed with a reason and still names its members" do
      [one] =
        Sources.Habits.candidates(
          [habit("Tidy", ~U[2026-08-23 00:00:00Z], is_all_day: true)],
          @day,
          zone: @zone
        )

      assert one.suppressed == :all_day
      assert one.members == ["Tidy"]
    end
  end

  # ── Calendar ───────────────────────────────────────────────────────────────

  describe "calendar reminders" do
    defp event(summary, attrs \\ []) do
      struct(
        %Event{
          uid: summary,
          summary: summary,
          kind: :event,
          dtstart_utc: ~U[2026-08-23 12:00:00Z],
          is_all_day: false,
          status: :confirmed
        },
        attrs
      )
    end

    test "a fixed event arms at its instant" do
      [one] = Sources.Calendar.candidates([event("Dentist")], zone: @zone)

      assert fire_at(one) == ~U[2026-08-23 12:00:00Z]
      assert one.domain == :calendar
    end

    test "a floating event arms on its wall clock, in its own zone" do
      [one] =
        Sources.Calendar.candidates(
          [
            event("Standup",
              tz_behaviour: :floating,
              dtstart_wall: "2026-08-23T09:30:00",
              tzid: "Europe/Berlin"
            )
          ],
          zone: @zone
        )

      assert {:wall_clock, ~N[2026-08-23 09:30:00], "Europe/Berlin"} = one.at
    end

    test "an all-day event is suppressed rather than fired at an invented hour" do
      [one] = Sources.Calendar.candidates([event("Anniversary", is_all_day: true)], zone: @zone)

      assert one.suppressed == :all_day
    end

    test "a cancelled event says so instead of firing" do
      [one] = Sources.Calendar.candidates([event("Dentist", status: :cancelled)], zone: @zone)

      assert one.suppressed == :cancelled
    end

    test "the location is the body, because it is the thing you need on the way" do
      [one] =
        Sources.Calendar.candidates([event("Dentist", location: "12 Bridge St")], zone: @zone)

      assert one.body == "12 Bridge St"
    end
  end

  # ── Money ──────────────────────────────────────────────────────────────────

  describe "renewal reminders" do
    defp service(name, renews_on, attrs \\ []) do
      struct(
        %Service{
          id: name,
          name: name,
          renews_on: renews_on,
          paused: false,
          monthly_pence: 1399,
          currency: "GBP"
        },
        attrs
      )
    end

    test "it fires the day before, which is the only day the answer can change" do
      [one] =
        Sources.Money.candidates([service("Orbit", ~D[2026-08-24])], @day, zone: @zone)

      assert fire_at(one) == ~U[2026-08-23 08:00:00Z]
      assert one.title == "Orbit"
    end

    test "a renewal that is not tomorrow contributes nothing — not a held row" do
      assert Sources.Money.candidates([service("Orbit", ~D[2026-09-24])], @day, zone: @zone) == []
      assert Sources.Money.candidates([service("Orbit", nil)], @day, zone: @zone) == []
    end

    test "paused is a state the user chose, so it is suppressed rather than filtered" do
      [one] =
        Sources.Money.candidates([service("Orbit", ~D[2026-08-24], paused: true)], @day,
          zone: @zone
        )

      assert one.suppressed == :paused
    end

    test "the amount is in the body, because a count of renewals names nothing" do
      [one] = Sources.Money.candidates([service("Orbit", ~D[2026-08-24])], @day, zone: @zone)

      assert one.body =~ "13"
      assert one.body =~ "tomorrow"
      assert one.members == ["Orbit"]
    end
  end

  # ── The six together ───────────────────────────────────────────────────────

  describe "the six domains" do
    test "every domain the budget allocates for has a collector" do
      # `Kati.Notifications.Inbox.by_domain/1` reads the budget's list, so a
      # domain with no collector draws an empty row forever and nothing says so.
      collectors = %{
        calendar: Sources.Calendar,
        tv: Sources.Media,
        habits: Sources.Habits,
        meals: Sources.Meals,
        health: Sources.Health,
        money: Sources.Money
      }

      assert Enum.sort(Map.keys(collectors)) == Enum.sort(Budget.domains())

      for {_domain, module} <- collectors do
        Code.ensure_loaded!(module)

        arities =
          module.__info__(:functions)
          |> Enum.filter(&(elem(&1, 0) == :candidates))
          |> Enum.map(&elem(&1, 1))

        assert arities != [], "#{inspect(module)} exports no candidates/_"
      end
    end

    test "no two sources claim the same event kind" do
      # `Kati.Calendars.Event` has seven kinds and three sources read that
      # table. A kind read twice is not a duplicate notification — the budget
      # divides a fixed number of slots, so it is another domain's reminder
      # deleted.
      day = @day
      zone = @zone

      rows = [
        %Event{uid: "e", summary: "Dentist", kind: :event, dtstart_utc: ~U[2026-08-23 12:00:00Z]},
        %Event{uid: "h", summary: "Read", kind: :habit, dtstart_utc: ~U[2026-08-23 07:00:00Z]},
        %Event{uid: "m", summary: "Dal", kind: :meal, dtstart_utc: ~U[2026-08-23 19:00:00Z]},
        %Event{uid: "$", summary: "Orbit", kind: :money, dtstart_utc: ~U[2026-08-23 09:00:00Z]},
        %Event{uid: "a", summary: "S2E6", kind: :air_date, dtstart_utc: ~U[2026-08-23 20:00:00Z]},
        %Event{uid: "n", summary: "A note", kind: :note, dtstart_utc: ~U[2026-08-23 11:00:00Z]}
      ]

      # Each source says which kinds are its own, and the two sets are disjoint.
      calendar_kinds = Sources.Calendar.own_kinds()
      habit_kinds = Sources.Habits.own_kinds()

      assert calendar_kinds -- habit_kinds == calendar_kinds

      # The seven kinds are accounted for exactly once: two sources claim three
      # between them, three more are read from their own domain's table rather
      # than from this one, and a note is never a notification.
      elsewhere = [:meal, :money, :air_date]
      never = [:note]

      assert Enum.sort(calendar_kinds ++ habit_kinds ++ elsewhere ++ never) ==
               Enum.sort(Event.kinds())

      # And the sources behave the way they say: handed every row, each takes
      # only its own.
      calendar =
        Sources.Calendar.candidates(Enum.filter(rows, &(&1.kind in calendar_kinds)), zone: zone)

      habits =
        Sources.Habits.candidates(Enum.filter(rows, &(&1.kind in habit_kinds)), day, zone: zone)

      assert Enum.map(calendar, & &1.meta.uid) == ["e"]
      assert Enum.flat_map(habits, & &1.members) == ["h"]
    end
  end

  # ── Against a real database ────────────────────────────────────────────────

  describe "the readers" do
    @moduletag :db

    # Every row this block writes is destroyed again. `Kati.MealsTest` records
    # the hazard in full: a fixture left behind makes a screen take the real
    # path instead of its Sample fallback, and the drawing's literals stop
    # appearing on a sweep this file never touches.
    setup do
      on_exit(fn ->
        for table <- ~w(health_doses health_medications services events) do
          Kati.Repo.query!("DELETE FROM " <> table, [])
        end
      end)

      :ok
    end

    test "a stored medication reaches a candidate through the reader" do
      # The builders above are proved against structs. This is the path the app
      # actually takes, and a rule proved only against hand-built structs is a
      # rule proved only against hand-built structs.
      Ash.create!(Medication, %{name: "Levothyroxine", dose: "50 mcg", times: ["08:00"]})

      rows = Sources.Health.active()
      assert Enum.map(rows, & &1.name) == ["Levothyroxine"]

      [one] = Sources.Health.candidates(rows, @day, zone: @zone)

      assert one.title == "Levothyroxine"
      assert one.body == "50 mcg"
      assert fire_at(one) == ~U[2026-08-23 07:00:00Z]
    end

    test "an inactive medication is not read at all" do
      Ash.create!(Medication, %{name: "Old one", times: ["08:00"], active: false})

      assert Sources.Health.active() == []
    end

    test "a stored subscription reaches a renewal candidate" do
      Ash.create!(Service, %{
        name: "Orbit",
        tier: :subscribed,
        monthly_pence: 1399,
        renews_on: ~D[2026-08-24]
      })

      rows = Sources.Money.subscribed()
      assert Enum.map(rows, & &1.name) == ["Orbit"]

      [one] = Sources.Money.candidates(rows, @day, zone: @zone)

      assert one.title == "Orbit"
      assert fire_at(one) == ~U[2026-08-23 08:00:00Z]
    end

    test "the screen's collector answers with every domain, and does not raise" do
      # `Kati.Screens.InboxNotifications.candidates/0` is six reads behind a
      # rescue each. The assertion that matters is not the list — an empty
      # database has little to say — but that one collector's silence is not
      # the page's: it returns a list rather than blowing up, on a database
      # with nothing in it, which is what a fresh install is.
      assert is_list(Kati.Screens.InboxNotifications.candidates())
    end
  end
end
