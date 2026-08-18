defmodule Kati.Calendar.ShamsiTest do
  @moduledoc """
  Golden-file style checks against published Iranian calendar dates.

  `ex_cldr_calendars_persian` has ~1,800 lifetime downloads, so the research's
  instruction was to treat every output as suspect until checked against a
  published table. A wrong Nowruz is the highest-visibility possible bug for the
  fa locale — it moves the new year.
  """
  use ExUnit.Case, async: true

  alias Kati.Calendar.Shamsi

  describe "Nowruz — the dates everyone would notice" do
    test "known Nowruz dates match published Iranian calendars" do
      # Persian year => the Gregorian date of 1 Farvardin.
      published = [
        {1399, ~D[2020-03-20]},
        {1400, ~D[2021-03-21]},
        {1401, ~D[2022-03-21]},
        {1402, ~D[2023-03-21]},
        {1403, ~D[2024-03-20]},
        {1404, ~D[2025-03-21]},
        {1405, ~D[2026-03-21]}
      ]

      for {year, gregorian} <- published do
        assert {:ok, ^gregorian} = Shamsi.to_gregorian(year, 1, 1),
               "Nowruz #{year} should be #{gregorian}"

        assert {^year, 1, 1} = Shamsi.from_gregorian(gregorian)
      end
    end
  end

  describe "round trips" do
    test "every day of 1405 converts both ways" do
      for month <- 1..12, day <- 1..Shamsi.days_in_month(1405, month) do
        {:ok, greg} = Shamsi.to_gregorian(1405, month, day)
        assert {1405, ^month, ^day} = Shamsi.from_gregorian(greg)
      end
    end

    test "a decade of Gregorian days round-trips" do
      start = Date.to_gregorian_days(~D[2020-01-01])
      finish = Date.to_gregorian_days(~D[2030-01-01])

      for iso <- start..finish//37 do
        date = Date.from_gregorian_days(iso)
        {y, m, d} = Shamsi.from_gregorian(date)
        assert {:ok, ^date} = Shamsi.to_gregorian(y, m, d)
      end
    end
  end

  describe "leap years" do
    test "derived from the table, not a 33-year cycle approximation" do
      # 1403 is a leap year (Esfand has 30 days); 1404 is not.
      assert Shamsi.leap_year?(1403)
      refute Shamsi.leap_year?(1404)
      assert Shamsi.days_in_month(1403, 12) == 30
      assert Shamsi.days_in_month(1404, 12) == 29
    end

    test "month lengths follow the 6x31, 5x30, 29-or-30 pattern" do
      for m <- 1..6, do: assert(Shamsi.days_in_month(1405, m) == 31)
      for m <- 7..11, do: assert(Shamsi.days_in_month(1405, m) == 30)
      assert Shamsi.days_in_month(1405, 12) in [29, 30]
    end
  end

  describe "the week starts on شنبه" do
    test "weekday_index maps Saturday to 1" do
      assert Shamsi.weekday_index(~D[2026-08-15]) == 1
      assert Shamsi.weekday_index(~D[2026-08-16]) == 2
      assert Shamsi.weekday_index(~D[2026-08-21]) == 7
    end

    test "a month grid begins its first week at شنبه, with leading blanks" do
      {:ok, weeks} = Shamsi.month_grid(1405, 1)

      assert Enum.all?(weeks, &(length(&1) == 7))

      first_real = weeks |> List.flatten() |> Enum.find(& &1)
      assert first_real.day == 1
      # Day 1 sits at its true weekday position, not forced into column 1.
      assert first_real.weekday == Shamsi.weekday_index(first_real.gregorian)

      # Leading cells are nil rather than dates borrowed from the previous month.
      leading = weeks |> hd() |> Enum.take_while(&is_nil/1)
      assert length(leading) == first_real.weekday - 1
    end

    test "the grid covers exactly the month's days" do
      for month <- [1, 7, 12] do
        {:ok, weeks} = Shamsi.month_grid(1405, month)
        days = weeks |> List.flatten() |> Enum.reject(&is_nil/1) |> Enum.map(& &1.day)
        assert days == Enum.to_list(1..Shamsi.days_in_month(1405, month))
      end
    end
  end

  describe "Persian digits" do
    test "renders output in extended Arabic-Indic digits" do
      assert Shamsi.fa(1405) == "۱۴۰۵"
      assert Shamsi.to_persian_digits("8.99") == "۸.۹۹"
    end

    test "folds Persian and Arabic-Indic input back to ASCII" do
      # Nothing downstream — FTS5, Integer.parse, a date parser — matches
      # Persian digits, so input must fold.
      assert Shamsi.from_persian_digits("۱۴۰۵") == "1405"
      assert Shamsi.from_persian_digits("٤٥٦") == "456"
      assert Shamsi.from_persian_digits("mixed ۱۲ text") == "mixed 12 text"
    end

    test "folding round-trips rendering" do
      for n <- [0, 7, 42, 1405, 999_999] do
        assert n |> Shamsi.fa() |> Shamsi.from_persian_digits() |> String.to_integer() == n
      end
    end
  end

  describe "formatting" do
    test "long form reads as a Persian date" do
      out = Shamsi.format(~D[2026-08-16], :long)
      assert out =~ "مرداد"
      assert out =~ "۱۴۰۵"
    end

    test "numeric form is zero-padded in Persian digits" do
      assert Shamsi.format(~D[2026-03-21], :numeric) =~ "۱۴۰۵/۰۱/۰۱"
    end
  end

  describe "range" do
    test "covers three centuries and reports its own bounds" do
      {first, last} = Kati.Calendar.NowruzTable.range()
      assert first <= 1300 and last >= 1600
    end

    test "a year outside the table is an error, not a wrong answer" do
      assert {:error, {:year_out_of_range, _}} = Shamsi.to_gregorian(2000, 1, 1)
    end
  end
end
