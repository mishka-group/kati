defmodule Kati.HabitsTest do
  @moduledoc """
  The habit arithmetic: a streak, its best, a day's tone, and the field.

  All of it is pure, so all of it is tested without a database. The screen is
  held by `Kati.ScreenHabitsTest`; this file is the rules it reads.
  """
  use ExUnit.Case, async: true

  alias Kati.Habits

  @today ~D[2026-11-23]

  defp kept(dates) do
    ticks = Map.new(dates, fn date -> {{"habit", date}, true} end)
    fn id, date -> Map.has_key?(ticks, {id, date}) end
  end

  describe "week_dates/2" do
    test "an English week opens on Monday and holds seven days" do
      dates = Habits.week_dates(@today, 1)

      assert length(dates) == 7
      assert Date.day_of_week(hd(dates)) == 1
      assert Date.day_of_week(List.last(dates)) == 7
      assert @today in dates
    end

    test "a Persian week opens on Saturday and holds the same seven" do
      dates = Habits.week_dates(@today, 6)

      assert length(dates) == 7
      assert Date.day_of_week(hd(dates)) == 6
      assert Date.day_of_week(List.last(dates)) == 5
      assert @today in dates
    end
  end

  describe "streak/3" do
    test "counts back from today while today is kept" do
      kept? = kept([@today, Date.add(@today, -1), Date.add(@today, -2)])

      assert Habits.streak("habit", @today, kept?) == 3
    end

    test "counts back from yesterday while today is not" do
      kept? = kept([Date.add(@today, -1), Date.add(@today, -2)])

      assert Habits.streak("habit", @today, kept?) == 2
    end

    test "a gap ends the run" do
      kept? = kept([@today, Date.add(@today, -1), Date.add(@today, -3)])

      assert Habits.streak("habit", @today, kept?) == 2
    end

    test "nothing kept is a broken streak, not a one" do
      assert Habits.streak("habit", @today, kept([])) == 0
    end
  end

  describe "longest/2" do
    test "the longest run anywhere, not the current one" do
      ticks =
        Map.new(
          [~D[2026-01-01], ~D[2026-01-02], ~D[2026-01-03], ~D[2026-01-04], ~D[2026-01-10]],
          &{{"habit", &1}, true}
        )

      assert Habits.longest("habit", ticks) == 4
    end

    test "one tick is a run of one, and none is none" do
      assert Habits.longest("habit", %{{"habit", @today} => true}) == 1
      assert Habits.longest("habit", %{}) == 0
    end
  end

  describe "day_state/4" do
    test "kept days carry the tone of how recent they are" do
      ticks =
        Map.new([@today, Date.add(@today, -10), Date.add(@today, -40)], &{{"habit", &1}, true})

      habit = "habit"

      assert Habits.day_state(habit, @today, @today, ticks) == :done
      assert Habits.day_state(habit, Date.add(@today, -10), @today, ticks) == :partial
      assert Habits.day_state(habit, Date.add(@today, -40), @today, ticks) == :lapsed
      assert Habits.day_state(habit, Date.add(@today, -5), @today, ticks) == :missed
    end

    test "a day in the future is never done" do
      future = Date.add(@today, 1)
      ticks = %{{"habit", future} => true}

      assert Habits.day_state("habit", future, @today, ticks) == :missed
    end
  end

  describe "tone/1" do
    test "four shades, and a zero is the palest" do
      assert Habits.tone(0.0) == :pale
      assert Habits.tone(0.2) == :pale
      assert Habits.tone(0.5) == :light
      assert Habits.tone(0.8) == :mid
      assert Habits.tone(1.0) == :full
    end
  end

  describe "fraction/3 and field/4" do
    test "the fraction is over the habits there are now" do
      born = %{id: "a", inserted_at: ~U[2026-11-20 09:00:00Z]}

      assert Habits.fraction(~D[2026-11-19], [born], %{}) == 0.0
      assert Habits.fraction(~D[2026-11-21], [born], %{{"a", ~D[2026-11-21]} => true}) == 1.0
    end

    test "the field is the requested number of days, oldest first" do
      field = Habits.field(@today, 91, [], %{})

      assert length(field) == 91
      assert hd(field) == :pale
    end
  end
end
