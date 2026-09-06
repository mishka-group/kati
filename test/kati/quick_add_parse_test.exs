defmodule Kati.QuickAddParseTest do
  @moduledoc """
  What Kati reads out of one typed sentence.

  MOVIES-AND-TV.md #31: screen 18 had a field, a *Kati read that as* card, a
  clash warning and a commit button, and none of them were built — the whole
  page was one sentence somebody had typed into a design tool.

  The day is passed in, never read from the clock, which is
  `Kati.ScreenDateTest`'s rule and what makes a Thursday testable.
  """

  use ExUnit.Case, async: true

  alias Kati.QuickAdd.Parse

  doctest Parse

  # A Monday, so `thu` is three days out and `mon` is a week.
  @today ~D[2026-08-17]

  describe "when" do
    test "a weekday is the next one, never today" do
      assert Parse.read("dentist thu", @today).date == ~D[2026-08-20]
      assert Parse.read("standup mon", @today).date == ~D[2026-08-24]
    end

    test "today and tomorrow are what they say" do
      assert Parse.read("dentist today", @today).date == @today
      assert Parse.read("dentist tomorrow", @today).date == ~D[2026-08-18]
    end

    test "a date is read in either order" do
      assert Parse.read("dentist 20 aug", @today).date == ~D[2026-08-20]
      assert Parse.read("dentist aug 20", @today).date == ~D[2026-08-20]
      assert Parse.read("dentist 20/08", @today).date == ~D[2026-08-20]
    end

    test "a date already past is next year, which is what typing it means" do
      assert Parse.read("dentist 3 mar", @today).date == ~D[2027-03-03]
    end

    test "and a sentence with no day has none" do
      assert Parse.read("dentist", @today).date == nil
    end
  end

  describe "at" do
    test "reads the forms people type" do
      for {typed, expected} <- [
            {"11am", ~T[11:00:00]},
            {"7pm", ~T[19:00:00]},
            {"19:30", ~T[19:30:00]},
            {"11.30am", ~T[11:30:00]},
            {"12am", ~T[00:00:00]},
            {"noon", ~T[12:00:00]},
            {"midnight", ~T[00:00:00]}
          ] do
        assert Parse.read("dentist thu #{typed}", @today).time == expected,
               "#{typed} was not read as #{expected}"
      end
    end

    test "and an hour nobody typed is not invented" do
      assert Parse.read("dentist thu", @today).time == nil
    end
  end

  describe "for and remind" do
    test "read minutes and hours" do
      assert Parse.read("x thu for 45m", @today).minutes == 45
      assert Parse.read("x thu for 2h", @today).minutes == 120
      assert Parse.read("x thu for 1h30", @today).minutes == 90
      assert Parse.read("x thu for an hour", @today).minutes == 60
    end

    test "and a reminder is minutes before" do
      assert Parse.read("x thu remind 1h before", @today).remind == 60
      assert Parse.read("x thu remind me 10 minutes before", @today).remind == 10
    end
  end

  describe "the title" do
    test "is everything no token claimed, with the gaps closed" do
      assert Parse.read("dentist thu 11am for 45m, remind 1h before", @today).title == "Dentist"
      assert Parse.read("coffee with Jo tomorrow 9am", @today).title == "Coffee with Jo"
    end

    test "keeps the reader's own words, capitalised only at the front" do
      assert Parse.read("call Dad about the boiler tomorrow", @today).title ==
               "Call Dad about the boiler"
    end

    test "and a sentence of nothing but tokens has none" do
      assert Parse.read("tomorrow 9am", @today).title == nil
    end
  end

  describe "the spans" do
    test "point at the tokens in the original string, for the field to highlight" do
      sentence = "dentist thu 11am for 45m"
      read = Parse.read(sentence, @today)

      quoted = Enum.map(read.spans, fn {at, len} -> binary_part(sentence, at, len) end)

      assert quoted == ["thu", "11am", "for 45m"]
    end
  end

  describe "what may be committed" do
    test "needs a title and a day" do
      assert Parse.committable?(Parse.read("dentist thu", @today))
      refute Parse.committable?(Parse.read("dentist", @today))
      refute Parse.committable?(Parse.read("thu 11am", @today))
      refute Parse.committable?(Parse.read("", @today))
    end

    test "and an all-day event is a real thing" do
      assert Parse.committable?(Parse.read("bin day tomorrow", @today))
    end
  end
end
