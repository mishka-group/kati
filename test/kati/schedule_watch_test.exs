defmodule Kati.ScheduleWatchTest do
  @moduledoc """
  Schedule works for films, shows and anime: saved against the title, with a
  reminder, armed on the platform, and managed from the event (#124).

  Films had a Schedule that wrote an event knowing nothing about the film and
  dropped the sentence's own *remind 1h before*; shows and anime had none.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendars.Event
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Notifications.Reminders

  doctest Kati.Notifications.Reminders, only: [label: 1]
  doctest Kati.Screens.Series, only: [schedule_sentence: 1]

  @prefix "schedule-watch-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM events WHERE summary LIKE ?1", ["Watch " <> @prefix <> "%"])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)
  end

  defp track!(suffix, kind) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: kind,
      title: @prefix <> suffix,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: kind,
      status: :watching
    })
  end

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  defp schedule!(tracked, sentence) do
    view =
      mount_screen(Kati.Screens.QuickAdd, %{sentence: sentence, tracked_id: tracked.id})
      |> render_info({:tap, :commit})

    assert assigns(view).save_error == nil
    Kati.Calendars.Scheduled.next(tracked.id)
  end

  describe "the pages" do
    test "a show and an anime draw Schedule, and it opens Quick Add for the next episode" do
      for kind <- [:tv, :anime] do
        show = track!("show-#{kind}", kind)
        view = mount_screen(Kati.Screens.Series, %{tracked_id: show.id})
        assert :schedule_watch in tags(view)

        view = render_info(view, {:tap, :schedule_watch})

        assert {:push, Kati.Screens.QuickAdd, %{sentence: sentence, tracked_id: id}} =
                 view.socket.__mob__.nav_action

        assert id == show.id
        assert sentence =~ "Watch " <> @prefix <> "show-#{kind}"
      end
    end

    test "once a watch is scheduled, the pill says when and opens the event" do
      show = track!("dark", :tv)
      event = schedule!(show, "Watch " <> @prefix <> "dark tomorrow 8pm")

      view = mount_screen(Kati.Screens.Series, %{tracked_id: show.id})
      refute :schedule_watch in tags(view)
      assert :open_schedule in tags(view)
      assert text(view) =~ Kati.Calendars.Scheduled.label(event)

      view = render_info(view, {:tap, :open_schedule})
      assert {:push, Kati.Screens.EventDetail, %{id: id}} = view.socket.__mob__.nav_action
      assert id == event.id
    end

    test "the film page does the same" do
      film = track!("dune", :movie)
      event = schedule!(film, "Watch " <> @prefix <> "dune tomorrow 8pm")

      view = mount_screen(Kati.Screens.Film, %{id: film.id})
      assert :open_schedule in tags(view)

      assert view
             |> render_info({:tap, :open_schedule})
             |> Map.get(:socket)
             |> then(& &1.__mob__.nav_action) ==
               {:push, Kati.Screens.EventDetail, %{id: event.id}}
    end
  end

  describe "the event" do
    test "knows its title and reminds at the start by default" do
      show = track!("dark", :tv)
      event = schedule!(show, "Watch " <> @prefix <> "dark tomorrow 8pm")

      assert event.tracked_title_id == show.id
      assert event.alarm_minutes == 0
    end

    test "a sentence's own reminder is kept, on any event" do
      show = track!("dark", :tv)
      event = schedule!(show, "Watch " <> @prefix <> "dark tomorrow 8pm remind 1h before")
      assert event.alarm_minutes == 60
    end

    test "the event page names the title, opens it, and changes the reminder" do
      show = track!("dark", :tv)
      event = schedule!(show, "Watch " <> @prefix <> "dark tomorrow 8pm")
      view = mount_screen(Kati.Screens.EventDetail, %{id: event.id})

      assert text(view) =~ @prefix <> "dark"
      assert text(view) =~ "At the start"
      assert :open_title in tags(view)

      view = render_info(view, {:tap, :cycle_reminder})
      assert Ash.get!(Event, event.id).alarm_minutes == 10
      assert text(view) =~ "10 min before"

      view = render_info(view, {:tap, :open_title})

      assert {:push, Kati.Screens.Series, %{tracked_id: id}} = view.socket.__mob__.nav_action
      assert id == show.id
    end
  end

  describe "reminders" do
    test "an event with a reminder is a candidate that fires that long before it starts" do
      show = track!("dark", :tv)
      event = schedule!(show, "Watch " <> @prefix <> "dark tomorrow 8pm remind 10 minutes before")

      [candidate] =
        Enum.filter(Reminders.candidates(), &(&1.id == "rem:" <> event.uid))

      assert candidate.domain == :calendar
      assert {:absolute, at} = candidate.at
      assert DateTime.diff(event.dtstart_utc, at) == 600
      assert candidate.meta.tracked_id == show.id
    end

    test "an event with no reminder is not one" do
      show = track!("dark", :tv)
      event = schedule!(show, "Watch " <> @prefix <> "dark tomorrow 8pm")
      Ash.update!(event, %{alarm_minutes: nil})

      refute Enum.any?(Reminders.candidates(), &(&1.id == "rem:" <> event.uid))
    end

    test "sync arms through a backend, records it, and cancels what was deleted" do
      defmodule Backend do
        @behaviour Kati.Notifications.Delivery
        def arm(_candidate), do: :ok
        def cancel(_id), do: :ok
      end

      show = track!("dark", :tv)
      event = schedule!(show, "Watch " <> @prefix <> "dark tomorrow 8pm")

      result = Reminders.sync(backend: Backend)
      assert ("rem:" <> event.uid) in result.armed
      assert Enum.any?(Reminders.armed(), &(&1.id == "rem:" <> event.uid))

      Ash.update!(event, %{}, action: :soft_delete)
      result = Reminders.sync(backend: Backend)
      assert ("rem:" <> event.uid) in result.cancelled
      refute Enum.any?(Reminders.armed(), &(&1.id == "rem:" <> event.uid))
    end

    test "with no platform it says so and records nothing" do
      assert Reminders.sync(backend: Kati.Notifications.Delivery.Inert) == {:error, :no_delivery}
    end

    test "the next reminder choice wraps round" do
      assert Enum.map(Reminders.choices(), &Reminders.next/1) == [0, 10, 60, nil]
    end
  end
end
