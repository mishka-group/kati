defmodule Kati.QuickAddTest do
  @moduledoc """
  Screen 18 types, reads, warns and writes.

  The audit's finding: *"The screen has no text field, no parser and no
  writer — the field, the parse card, the clash warning and the commit button
  are all fixtures, and it is reachable from the Calendar dock root."* The
  last clause is what made it worth doing first among the fixtures: this is
  not a gallery specimen, it is a page the app puts in front of people.

  The board is kept as the empty state, and that is not a fallback for want of
  anything better. Board 18 is drawn MID-TYPING and its sentence is the
  clearest statement of the syntax this screen has, so somebody who opens the
  page and types nothing is looking at the example they need.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Calendars.Event
  alias Kati.Screens.QuickAdd

  setup do
    on_exit(fn -> Kati.Repo.query!("DELETE FROM events WHERE uid LIKE ?1", ["kati-quick-%"]) end)
    :ok
  end

  describe "an untyped field" do
    test "draws the board, whole" do
      assert QuickAdd.draft("") == Kati.Screens.QuickAdd.Sample.draft()
      assert QuickAdd.draft("   ") == Kati.Screens.QuickAdd.Sample.draft()
    end

    test "and the field offers the board's sentence as the example" do
      words = QuickAdd.input("") |> inspect(limit: :infinity, printable_limit: :infinity)

      assert words =~ "dentist thu 11am for 45m, remind 1h before"
    end
  end

  describe "a typed sentence" do
    test "becomes the title, the chips and the button's word" do
      draft = QuickAdd.draft("dentist tomorrow 11am for 45m")

      assert draft.title == "Dentist"
      assert draft.kind == "PERSONAL EVENT"
      assert draft.cta == "Add to tomorrow"

      chips = draft.facts |> List.flatten() |> Enum.map(&elem(&1, 1))
      assert "11:00 – 11:45" in chips
    end

    test "an all-day event says so rather than inventing an hour" do
      draft = QuickAdd.draft("bin day tomorrow")

      assert draft.kind == "ALL-DAY EVENT"
      refute Enum.any?(List.flatten(draft.facts), &(elem(&1, 0) == "schedule"))
    end

    test "a sentence with no day cannot be committed, and the button says what is missing" do
      draft = QuickAdd.draft("dentist")

      assert draft.kind == "NEEDS A DAY"
      assert draft.cta == "Say when, and Kati will add it"
      assert draft.on_commit == nil
    end

    test "and the tokens are marked in the reader's own words" do
      draft = QuickAdd.draft("dentist tomorrow 11am")
      pieces = draft.query |> Enum.flat_map(& &1.pieces)

      assert Enum.any?(pieces, &match?({:plain, "dentist", _}, &1))
      assert Enum.any?(pieces, &match?({:token, "tomorrow", _}, &1))
      assert Enum.any?(pieces, &match?({:token, "11am", _}, &1))
    end
  end

  describe "the clash" do
    test "names a real event this would run into" do
      day = Date.add(Kati.Time.today(), 1)
      event!("Design review", day, ~T[11:00:00], 60)

      draft = QuickAdd.draft("dentist tomorrow 11:30 for 30m")

      assert {"Clashes with", "Design review", "— add anyway?"} = draft.clash
    end

    test "and says nothing about something that merely shares the day" do
      day = Date.add(Kati.Time.today(), 1)
      event!("Design review", day, ~T[08:00:00], 30)

      assert QuickAdd.draft("dentist tomorrow 11:30 for 30m").clash == nil
    end

    test "an all-day sentence clashes with nothing, having no hours" do
      day = Date.add(Kati.Time.today(), 1)
      event!("Design review", day, ~T[11:00:00], 60)

      assert QuickAdd.draft("bin day tomorrow").clash == nil
    end
  end

  describe "the commit" do
    test "writes the event the sentence describes" do
      draft = QuickAdd.draft("dentist tomorrow 11am for 45m")

      assert {:ok, _event} = QuickAdd.commit(draft)

      assert [event] = quick_events()
      assert event.summary == "Dentist"
      assert event.is_all_day == false
      assert event.duration_iso == "PT45M"
    end

    test "an all-day sentence writes an all-day event" do
      assert {:ok, _event} = QuickAdd.commit(QuickAdd.draft("bin day tomorrow"))

      assert [%{is_all_day: true, summary: "Bin day"}] = quick_events()
    end

    test "a sentence with no day writes nothing" do
      assert {:error, _why} = QuickAdd.commit(QuickAdd.draft("dentist"))
      assert quick_events() == []
    end

    test "and the drawing writes nothing, because there is no sentence behind it" do
      assert {:error, _why} = QuickAdd.commit(QuickAdd.draft(""))
      assert quick_events() == []
    end
  end

  describe "the six Or file it as chips" do
    test "each sends a tag, where five of six sent nothing" do
      for label <- ["Event", "Reminder", "Title", "Habit", "Note", "Expense"] do
        assert {_pid, _tag} = QuickAdd.kind_tap(label)
      end
    end

    test "four of them are one value of Kati.Calendars.Event.kind" do
      filed = Enum.map(["Event", "Reminder", "Habit", "Note"], &QuickAdd.filing/1)

      assert filed == [:event, :reminder, :habit, :note]
      assert Enum.all?(filed, &(&1 in Event.kinds()))

      # The two that are doors rather than settings: a film is not an event,
      # and an amount is a parse this screen does not do.
      assert QuickAdd.filing("Title") == nil
      assert QuickAdd.filing("Expense") == nil
    end

    test "and the chosen one decides what the sentence is filed as" do
      draft = QuickAdd.draft("call mum tomorrow 6pm")

      assert {:ok, _event} = QuickAdd.commit(draft, :reminder)
      assert [%{kind: :reminder, summary: "Call mum"}] = quick_events()
    end

    test "with Event as what a bare sentence is already filed as" do
      assert {:ok, _event} = QuickAdd.commit(QuickAdd.draft("bin day tomorrow"))
      assert [%{kind: :event}] = quick_events()
    end

    test "pressing a chip lights it and leaves the sentence alone" do
      socket = typed("dentist tomorrow 11am")

      {:noreply, filed} = QuickAdd.handle_info({:tap, :file_as_note}, socket)

      assert filed.assigns.filed_as == :note
      assert filed.assigns.draft == socket.assigns.draft
    end

    test "and a chip that names no filing leaves the screen alone" do
      socket = typed("dentist tomorrow 11am")

      {:noreply, after_tap} = QuickAdd.handle_info({:tap, :file_as_nonsense}, socket)

      assert after_tap.assigns.filed_as == :event
    end

    test "Title hands the parsed title to screen 06 and opens it" do
      socket = typed("the long hollow tomorrow 9pm")

      {:noreply, pushed} = QuickAdd.handle_info({:tap, :file_as_title}, socket)

      assert {:push, Kati.Screens.AddTitle, %{query: "The long hollow"}} =
               Map.get(pushed.__mob__, :nav_action)
    end

    test "and hands the whole sentence over when it could parse no title" do
      # Every token consumed and nothing left to be a title. The raw sentence
      # is still a better search term than an empty one.
      socket = typed("tomorrow 9pm")
      assert socket.assigns.draft.read.title == nil

      {:noreply, pushed} = QuickAdd.handle_info({:tap, :file_as_title}, socket)

      assert {:push, Kati.Screens.AddTitle, %{query: "tomorrow 9pm"}} =
               Map.get(pushed.__mob__, :nav_action)
    end

    test "screen 124 draws the same row as a picture, having no handler for it" do
      row = inspect(QuickAdd.kinds(QuickAdd.draft("")), limit: :infinity)

      refute row =~ "file_as_"
      assert inspect(QuickAdd.kinds(QuickAdd.draft(""), :event), limit: :infinity) =~ "file_as_"
    end
  end

  defp typed(sentence) do
    {:ok, socket} = QuickAdd.mount(%{}, %{}, Mob.Socket.new(QuickAdd))

    {:noreply, typed} = QuickAdd.handle_info({:change, :sentence, sentence}, socket)
    typed
  end

  defp quick_events do
    Event |> Ash.read!() |> Enum.filter(&String.starts_with?(&1.uid, "kati-quick-"))
  end

  defp event!(summary, date, time, minutes) do
    zone = Kati.Time.device_zone()
    starts = DateTime.new!(date, time, zone) |> DateTime.shift_zone!("Etc/UTC")

    Ash.create!(Event, %{
      uid: "kati-quick-fixture-" <> summary,
      calendar_id: QuickAdd.personal_calendar().id,
      origin: :kati,
      summary: summary,
      kind: :event,
      dtstart_utc: starts,
      dtstart_date: date,
      dtend_utc: DateTime.add(starts, minutes * 60, :second),
      is_all_day: false
    })
  end
end
