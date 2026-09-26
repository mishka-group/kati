defmodule Kati.CalendarViewsRealTest do
  @moduledoc """
  N51 — the Month, Week and Agenda views draw the reader's calendar.

  They drew `Kati.Calendar.SampleMonth`, `SampleWeek` and `SampleAgenda`: a
  fresh install opened on *August 2026*, the 16th selected, *THU 20 · 14 ITEMS
  · 2 CLASHES*, *Standup, Design review*, *Lunch, Plumber, +1* and *6 episodes
  air*. These pin both halves — an empty store draws none of that, and a
  stored event or a followed show's airing lands on its own date in all three.

  Every row is written inside one rolled-back transaction that first empties
  the calendar and the followed shows, for the reason
  `Kati.CalendarAiringsTest` gives: one SQLite file is shared by every test.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Locale, only: [month_span: 1]

  alias Kati.Calendars.Event
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Agenda
  alias Kati.Screens.EventDetail
  alias Kati.Screens.MonthGrid
  alias Kati.Screens.Week

  @fixtures ["Standup", "Plumber", "Design review", "episodes air", "clashes", "August 2026"]

  setup do
    Kati.Locale.put(:en)
    :ok
  end

  describe "an empty store" do
    test "draws no fixture on the month, the week or the agenda" do
      emptied(fn ->
        for module <- [MonthGrid, Week, Agenda] do
          drawn = render(module)

          for fixture <- @fixtures do
            refute drawn =~ fixture,
                   "#{inspect(module)} drew #{inspect(fixture)} on an empty store"
          end

          assert drawn =~ "Nothing scheduled", "#{inspect(module)} did not say it is empty"
        end
      end)
    end

    test "the month is today's month, with no dots and no legend" do
      emptied(fn ->
        today = Kati.Time.today()
        month = mounted(MonthGrid).month

        assert month.title == Calendar.strftime(today, "%B %Y")
        assert Enum.all?(month.days, &(&1.sections == []))
        assert month.sections == []
        assert Enum.find(month.days, & &1.today?).date == today
      end)
    end

    test "the month is the reader's own under Persian" do
      emptied(fn ->
        Kati.Locale.as(:fa, fn ->
          today = Kati.Time.today()
          {first, last} = Kati.Locale.month_span(today)
          month = MonthGrid.month(today, today)

          assert month.first == first
          assert month.last == last
          assert month.title =~ Kati.Locale.month_name(today)
          assert Enum.count(month.days, & &1.in_month?) == Date.diff(last, first) + 1
        end)
      end)
    end

    test "screen 31 without a stored event says so rather than drawing one" do
      emptied(fn ->
        for params <- [%{}, %{id: Ecto.UUID.generate()}] do
          event = EventDetail.event(params)
          assert event == EventDetail.missing()
          drawn = inspect(EventDetail.render(%{event: event}), limit: :infinity)

          refute drawn =~ "Design review"
          refute drawn =~ "Delete event"
          assert drawn =~ "This event is not here"
        end
      end)
    end
  end

  describe "a stored event" do
    test "is a dot on its date, a row under the month, a block in the week and a group in the agenda" do
      emptied(fn ->
        today = Kati.Time.today()
        event!(today, ~T[09:30:00], ~T[10:30:00], "Dentist")

        month = mounted(MonthGrid).month
        assert Enum.find(month.days, &(&1.date == today)).sections == [:personal]
        assert month.sections == [:personal]
        assert [%{title: "Dentist"}] = month.rows
        assert render(MonthGrid) =~ "Dentist"

        week = mounted(Week).week
        lane = Enum.find(week.lanes, &(&1.date == today))
        assert [%{section: :personal, hour: "09"}] = lane.blocks
        assert render(Week) =~ "Dentist"
        assert render(Week) =~ "1h"

        assert render(MonthGrid) =~ "PERSONAL", "the legend names no section that has items"

        [group | _rest] = mounted(Agenda).agenda.groups
        assert group.date == today
        assert [%{title: "Dentist"}] = group.rows
        assert render(Agenda) =~ "Dentist"
        assert render(Agenda) =~ "Nothing else through"
        assert render(Agenda) =~ Kati.Icons.glyph!("expand_more")
      end)
    end

    test "tapping another date on the month selects it, and tapping it again opens that day" do
      emptied(fn ->
        today = Kati.Time.today()
        other = if today.day > 15, do: Date.add(today, -3), else: Date.add(today, 3)
        event!(other, ~T[18:00:00], ~T[19:00:00], "Choir")

        {:ok, socket} = MonthGrid.mount(%{}, %{}, %Mob.Socket{})
        {:noreply, picked} = MonthGrid.handle_tap(MonthGrid.day_tag(other), socket)

        assert picked.assigns.date == other
        assert [%{title: "Choir"}] = picked.assigns.month.rows

        {:noreply, opened} = MonthGrid.handle_tap(MonthGrid.day_tag(other), picked)
        assert {:push, Kati.Screens.Day, %{date: ^other}} = opened.__mob__.nav_action
      end)
    end

    test "the month's chevrons move a month either way" do
      emptied(fn ->
        today = Kati.Time.today()
        {:ok, socket} = MonthGrid.mount(%{}, %{}, %Mob.Socket{})

        {:noreply, back} = MonthGrid.handle_tap(:month_previous, socket)
        {first, _last} = Kati.Locale.month_span(today)
        assert back.assigns.month.last == Date.add(first, -1)

        {:noreply, again} = MonthGrid.handle_tap(:month_next, back)
        assert again.assigns.date == today
      end)
    end
  end

  describe "a followed show's airing" do
    test "is a Screen dot, a block and an agenda row beside the stored event" do
      emptied(fn ->
        today = Kati.Time.today()
        event!(today, ~T[09:30:00], ~T[10:00:00], "Dentist")
        show = follow!("The Bear")
        for n <- 1..8, do: episode!(show, 5, n, today)

        month = mounted(MonthGrid).month
        assert Enum.find(month.days, &(&1.date == today)).sections == [:screen, :personal]
        assert render(MonthGrid) =~ "The Bear"
        assert render(MonthGrid) =~ "S5 · E1 · 8 episodes"

        lane = Enum.find(mounted(Week).week.lanes, &(&1.date == today))
        assert Enum.map(lane.blocks, & &1.section) == [:screen, :personal]
        assert render(Week) =~ "The Bear"

        [group | _rest] = mounted(Agenda).agenda.groups
        assert Enum.map(group.rows, & &1.title) == ["The Bear", "Dentist"]
      end)
    end
  end

  describe "screen 09 on a day with an all-day airing" do
    test "lists it under All day, counts it, and does not say Nothing scheduled" do
      emptied(fn ->
        day = Kati.Time.today()
        show = follow!("The Bear")
        episode!(show, 5, 1, day)

        {:ok, socket} =
          Kati.Screens.Day.mount(%{date: day}, %{}, Mob.Socket.new(Kati.Screens.Day))

        page = inspect(Kati.Screens.Day.content(socket.assigns), limit: :infinity)

        assert page =~ "All day"
        assert page =~ "The Bear"
        refute page =~ "Nothing scheduled"
        assert {"Screen", 1} in Kati.Screens.Day.counts(socket.assigns)
      end)
    end
  end

  defp mounted(module) do
    {:ok, socket} = module.mount(%{}, %{}, %Mob.Socket{})
    socket.assigns
  end

  defp render(module), do: inspect(module.content(mounted(module)), limit: :infinity)

  defp emptied(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        for table <-
              ~w(event_occurrence_overrides events cached_episodes tracked_titles cached_titles),
            do: Kati.Repo.query!("delete from #{table}")

        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  defp event!(date, from, to, summary) do
    calendar =
      Kati.Calendars.Calendar
      |> Ash.Changeset.for_create(:create, %{
        display_name: "Views #{System.unique_integer([:positive])}",
        kind: :local
      })
      |> Ash.create!()

    zone = Kati.Time.device_zone()
    naive = NaiveDateTime.new!(date, from)
    {:ok, utc} = Kati.Time.to_utc(naive, zone)
    minutes = div(Time.diff(to, from, :second), 60)

    Event
    |> Ash.Changeset.for_create(:create, %{
      uid: "kati-views-#{System.unique_integer([:positive])}@kati",
      calendar_id: calendar.id,
      origin: :kati,
      summary: summary,
      kind: :event,
      status: :confirmed,
      dtstart_utc: utc,
      dtstart_wall: naive |> NaiveDateTime.to_iso8601() |> String.replace(["-", ":"], ""),
      tzid: zone,
      duration_iso: "PT#{minutes}M",
      sync_state: :local_only
    })
    |> Ash.create!()
  end

  defp follow!(title) do
    source_id = "calendar-views:#{System.unique_integer([:positive])}"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: title,
      fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching,
      add_air_dates_to_calendar: true
    })
  end

  defp episode!(show, season, number, date) do
    Ash.create!(CachedEpisode, %{
      source: show.source,
      source_id: "calendar-views-episode:#{System.unique_integer([:positive])}",
      title_source_id: show.source_id,
      season_number: season,
      episode_number: number,
      air_at: DateTime.new!(date, ~T[00:00:00.000000], "Etc/UTC"),
      date_confidence: :day,
      fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end
end
