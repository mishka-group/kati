defmodule Kati.RecurrenceTest do
  @moduledoc """
  RFC 5545's own examples, plus the two behaviours the RFC states and
  implementations routinely get wrong: drop-don't-clamp, and dropped instances
  not consuming a COUNT slot.
  """
  use ExUnit.Case, async: true

  alias Kati.Recurrence
  alias Kati.Recurrence.Rule

  setup_all do
    Kati.Runtime.configure()
    :ok
  end

  defp window(from, to) do
    {DateTime.from_naive!(from, "Etc/UTC"), DateTime.from_naive!(to, "Etc/UTC")}
  end

  defp dates(instants), do: Enum.map(instants, &DateTime.to_date/1)

  describe "Rule parsing" do
    test "parses a full rule regardless of part order" do
      {:ok, r} = Rule.parse("BYDAY=TU,SU;FREQ=WEEKLY;INTERVAL=2;COUNT=4;WKST=MO")
      assert r.freq == :weekly
      assert r.interval == 2
      assert r.count == 4
      assert r.by_day == [{nil, :tu}, {nil, :su}]
      assert r.wkst == :mo
    end

    test "FREQ is required" do
      assert {:error, :missing_freq} = Rule.parse("INTERVAL=2")
    end

    test "UNTIL and COUNT must not both appear" do
      assert {:error, :until_and_count} = Rule.parse("FREQ=DAILY;COUNT=3;UNTIL=20261231T000000Z")
    end

    test "UNTIL keeps its value type — date for all-day, datetime for timed" do
      {:ok, all_day} = Rule.parse("FREQ=DAILY;UNTIL=20261231")
      {:ok, timed} = Rule.parse("FREQ=DAILY;UNTIL=20261231T170000Z")

      assert %Date{} = all_day.until
      assert %DateTime{} = timed.until
    end

    test "parses ordinal BYDAY such as the last Friday" do
      {:ok, r} = Rule.parse("FREQ=MONTHLY;BYDAY=-1FR")
      assert r.by_day == [{-1, :fr}]
    end

    test "parses rule parts Kati's own editor cannot author" do
      {:ok, r} = Rule.parse("FREQ=YEARLY;BYWEEKNO=20;BYYEARDAY=100;BYSECOND=30")
      assert r.by_weekno == [20]
      assert r.by_yearday == [100]
      assert r.by_second == [30]
    end

    test "serialises with FREQ first, as the RFC requires" do
      {:ok, r} = Rule.parse("BYDAY=TU;INTERVAL=2;FREQ=WEEKLY")
      out = Rule.to_string(r)
      assert String.starts_with?(out, "FREQ=WEEKLY")
    end

    test "round-trips" do
      for value <- [
            "FREQ=DAILY",
            "FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,SU;WKST=SU",
            "FREQ=MONTHLY;BYMONTHDAY=-1",
            "FREQ=MONTHLY;BYDAY=-1FR;COUNT=5",
            "FREQ=YEARLY;BYMONTH=3;BYDAY=2SU"
          ] do
        {:ok, parsed} = Rule.parse(value)
        {:ok, reparsed} = Rule.parse(Rule.to_string(parsed))
        assert reparsed == parsed, "round trip failed for #{value}"
      end
    end
  end

  describe "drop, do not clamp (RFC 3.3.10)" do
    test "MONTHLY BYMONTHDAY=31 skips months without a 31st" do
      {:ok, rule} = Rule.parse("FREQ=MONTHLY;BYMONTHDAY=31")

      months =
        Recurrence.expand(
          ~N[2026-01-31 09:00:00],
          "Etc/UTC",
          rule,
          [],
          [],
          window(~N[2026-01-01 00:00:00], ~N[2026-12-31 23:59:59])
        )
        |> dates()
        |> Enum.map(& &1.month)

      # No February, April, June, September or November.
      assert 2 not in months
      assert 4 not in months
      assert 6 not in months
      assert 9 not in months
      assert 11 not in months
      assert months == [1, 3, 5, 7, 8, 10, 12]
    end

    test "a dropped instance does not consume a COUNT slot" do
      {:ok, rule} = Rule.parse("FREQ=MONTHLY;BYMONTHDAY=31;COUNT=3")

      got =
        Recurrence.expand(
          ~N[2026-01-31 09:00:00],
          "Etc/UTC",
          rule,
          [],
          [],
          window(~N[2026-01-01 00:00:00], ~N[2027-12-31 23:59:59])
        )
        |> dates()

      # Jan 31, Mar 31, May 31 — February never counted against the three.
      assert length(got) == 3
      assert Enum.map(got, & &1.month) == [1, 3, 5]
    end
  end

  describe "timezone edges" do
    test "a nonexistent local time is dropped, not shifted" do
      # 01:30 daily across the UK spring-forward on 2026-03-29.
      {:ok, rule} = Rule.parse("FREQ=DAILY")

      got =
        Recurrence.expand(
          ~N[2026-03-27 01:30:00],
          "Europe/London",
          rule,
          [],
          [],
          window(~N[2026-03-26 00:00:00], ~N[2026-04-01 00:00:00])
        )
        |> Enum.map(&DateTime.to_date/1)
        |> Enum.map(& &1.day)

      # 29 March has no 01:30 local time, so that instance simply is not there.
      assert 29 not in got
      assert 28 in got and 30 in got
    end

    test "expand drops a gap while Kati.Time picks the after instant" do
      # The two behaviours are deliberately different: the RFC mandates dropping
      # for a recurrence, while a user-entered single time should still fire.
      assert {:ok, _dt, :gap} = Kati.Time.resolve(~N[2026-03-29 01:30:00], "Europe/London")

      {:ok, rule} = Rule.parse("FREQ=DAILY;COUNT=1")

      assert [] ==
               Recurrence.expand(
                 ~N[2026-03-29 01:30:00],
                 "Europe/London",
                 rule,
                 [],
                 [],
                 window(~N[2026-03-29 00:00:00], ~N[2026-03-30 00:00:00])
               )
    end
  end

  describe "WKST" do
    test "changes which weeks a fortnightly rule groups together" do
      # RFC 5545's own example, in UTC for clarity.
      {:ok, mo} = Rule.parse("FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO")
      {:ok, su} = Rule.parse("FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU")

      w = window(~N[1997-08-01 00:00:00], ~N[1997-09-30 00:00:00])
      start = ~N[1997-08-05 09:00:00]

      mo_days =
        Recurrence.expand(start, "Etc/UTC", mo, [], [], w) |> dates() |> Enum.map(& &1.day)

      su_days =
        Recurrence.expand(start, "Etc/UTC", su, [], [], w) |> dates() |> Enum.map(& &1.day)

      assert mo_days == [5, 10, 19, 24]
      assert su_days == [5, 17, 19, 31]
      refute mo_days == su_days
    end

    test "defaults to MO when absent, not to a locale" do
      {:ok, r} = Rule.parse("FREQ=WEEKLY;INTERVAL=2")
      assert r.wkst == :mo
    end
  end

  describe "RDATE and EXDATE" do
    test "the set is (rrule ∪ rdate) \\ exdate, deduplicated and sorted" do
      {:ok, rule} = Rule.parse("FREQ=DAILY;COUNT=3")

      got =
        Recurrence.expand(
          ~N[2026-08-10 09:00:00],
          "Etc/UTC",
          rule,
          [~N[2026-08-20 09:00:00], ~N[2026-08-11 09:00:00]],
          [~N[2026-08-11 09:00:00]],
          window(~N[2026-08-01 00:00:00], ~N[2026-08-31 00:00:00])
        )
        |> dates()
        |> Enum.map(& &1.day)

      # 10, 11, 12 from the rule; 20 added; 11 excluded; duplicate 11 collapsed.
      assert got == [10, 12, 20]
    end
  end

  describe "all-day events" do
    test "expand in dates, never instants" do
      {:ok, rule} = Rule.parse("FREQ=WEEKLY;COUNT=3")

      got =
        Recurrence.expand(
          ~D[2026-08-10],
          nil,
          rule,
          [],
          [],
          window(~N[2026-08-01 00:00:00], ~N[2026-09-30 00:00:00])
        )

      assert Enum.all?(got, &match?(%Date{}, &1))
      assert Enum.map(got, & &1.day) == [10, 17, 24]
    end
  end

  describe "common shapes" do
    test "every weekday" do
      {:ok, rule} = Rule.parse("FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR")

      got =
        Recurrence.expand(
          ~N[2026-08-17 09:00:00],
          "Etc/UTC",
          rule,
          [],
          [],
          window(~N[2026-08-17 00:00:00], ~N[2026-08-23 23:59:59])
        )
        |> dates()
        |> Enum.map(& &1.day)

      assert got == [17, 18, 19, 20, 21]
    end

    test "last Friday of the month" do
      {:ok, rule} = Rule.parse("FREQ=MONTHLY;BYDAY=-1FR")

      got =
        Recurrence.expand(
          ~N[2026-08-28 18:00:00],
          "Etc/UTC",
          rule,
          [],
          [],
          window(~N[2026-08-01 00:00:00], ~N[2026-10-31 23:59:59])
        )
        |> dates()

      assert Enum.map(got, &{&1.month, &1.day}) == [{8, 28}, {9, 25}, {10, 30}]
    end

    test "last day of the month, which is how a monthly bill should be authored" do
      {:ok, rule} = Rule.parse("FREQ=MONTHLY;BYMONTHDAY=-1")

      got =
        Recurrence.expand(
          ~N[2026-01-31 09:00:00],
          "Etc/UTC",
          rule,
          [],
          [],
          window(~N[2026-01-01 00:00:00], ~N[2026-04-30 23:59:59])
        )
        |> dates()

      # Unlike BYMONTHDAY=31 this never skips: 31, 28, 31, 30.
      assert Enum.map(got, & &1.day) == [31, 28, 31, 30]
    end

    test "UNTIL bounds the set inclusively" do
      {:ok, rule} = Rule.parse("FREQ=DAILY;UNTIL=20260812T090000Z")

      got =
        Recurrence.expand(
          ~N[2026-08-10 09:00:00],
          "Etc/UTC",
          rule,
          [],
          [],
          window(~N[2026-08-01 00:00:00], ~N[2026-08-31 00:00:00])
        )
        |> dates()
        |> Enum.map(& &1.day)

      assert got == [10, 11, 12]
    end
  end
end
