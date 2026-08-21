defmodule Kati.Calendar.GridTest do
  @moduledoc """
  The Jalali grid engine, asserted on real months.

  ## Why the table is written out by hand

  Every expectation below is an independent value, not something read back out
  of the code under test:

    * the **Nowruz** date of each year is the published Iranian one — the same
      list `Kati.Calendar.ShamsiTest` checks against a printed calendar;
    * the **offset** from Nowruz to each month's first day is a fixed calendar
      fact (six months of 31 days, then five of 30), so 1 مرداد is always
      Nowruz + 124;
    * the **weekday** of each resulting Gregorian date came from the system
      calendar (`date -j`), not from Elixir;
    * the **column** is `rem(iso_day_of_week - 6 + 7, 7)`, worked out per row.

  A grid test that only counted cells would pass on a completely wrong offset,
  because 42 cells is 42 cells no matter which column day 1 lands in. So every
  row here asserts the **exact column of the 1st** and the **exact length**.

  ## The two months that matter most

  `{1404, 1}` starts in column 6 with 31 days — 37 cells, which no 5×7 grid
  holds. `{1404, 12}` starts in column 6 with 29 days — exactly 35, which a
  5×7 grid holds precisely, so it is the month that would make a five-row
  implementation look correct. Both are here.
  """
  use ExUnit.Case, async: true

  doctest Kati.Calendar.Grid

  alias Kati.Calendar.Grid
  alias Kati.Calendar.Shamsi

  @root Path.expand("../..", __DIR__)

  # Source with its documentation and comments removed, so a rule about what the
  # code *does* is neither satisfied nor broken by prose. Both modules
  # deliberately name `Cldr.Calendar.localize/3` and `Kati.Locale` in their docs
  # — to say why they are not used — and a naive grep reads those as violations.
  defp code_only(relative) do
    @root
    |> Path.join(relative)
    |> File.read!()
    |> String.replace(~r/@(module)?doc\s+"""(?s).*?"""/, "")
    |> String.replace(~r/@(module)?doc\s+".*"/, "")
    |> String.replace(~r/^\s*#.*$/m, "")
  end

  # {jalali year, month, gregorian 1st, weekday name, column under شنبه, length}
  @months [
    # 1403 — a leap year: اسفند has 30 days.
    {1403, 1, ~D[2024-03-20], "Wednesday", 4, 31},
    {1403, 5, ~D[2024-07-22], "Monday", 2, 31},
    {1403, 7, ~D[2024-09-22], "Sunday", 1, 30},
    {1403, 12, ~D[2025-02-19], "Wednesday", 4, 30},
    # 1404 — an ordinary year: اسفند has 29.
    {1404, 1, ~D[2025-03-21], "Friday", 6, 31},
    {1404, 6, ~D[2025-08-23], "Saturday", 0, 31},
    {1404, 12, ~D[2026-02-20], "Friday", 6, 29},
    # 1405 — ordinary, and the year the design's screens are drawn in.
    {1405, 1, ~D[2026-03-21], "Saturday", 0, 31},
    {1405, 5, ~D[2026-07-23], "Thursday", 5, 31},
    {1405, 11, ~D[2027-01-21], "Thursday", 5, 30}
  ]

  # The design's abbreviations, design-index.md:381. Held as a literal here and
  # derived from CLDR in the code, so the two are compared rather than shared.
  @design_weekday_labels ["\u0634", "\u06CC", "\u062F", "\u0633", "\u0686", "\u067E", "\u062C"]

  # Zero-width non-joiner. Invisible in source, load-bearing in a lookup key.
  @zwnj "\u200C"

  describe "weekday_order/1 — the sequence, before anything is rendered" do
    test "Saturday, Monday and Sunday starts" do
      assert Grid.weekday_order(6) == [6, 7, 1, 2, 3, 4, 5]
      assert Grid.weekday_order(1) == [1, 2, 3, 4, 5, 6, 7]
      assert Grid.weekday_order(7) == [7, 1, 2, 3, 4, 5, 6]
    end

    test "every start is a rotation of 1..7, never a reversal" do
      for first_day <- 1..7 do
        order = Grid.weekday_order(first_day)

        assert length(order) == 7
        assert Enum.sort(order) == Enum.to_list(1..7)
        assert hd(order) == first_day

        # A rotation steps forward by one, wrapping. A reversed list would step
        # backwards — which is the mistake this whole module exists to prevent.
        for {day, index} <- Enum.with_index(order) do
          assert day == rem(first_day - 1 + index, 7) + 1
        end
      end
    end
  end

  describe "lead_blanks/2" do
    test "1 مرداد ۱۴۰۵ is a Thursday and leaves five blanks" do
      {:ok, first} = Shamsi.to_gregorian(1405, 5, 1)

      assert first == ~D[2026-07-23]
      assert Cldr.Calendar.iso_day_of_week(first) == 4
      assert Grid.lead_blanks(first, 6) == 5
    end

    test "the same date leaves a different count under a different week start" do
      first = ~D[2026-07-23]

      # Thursday is ISO 4: three days after Monday, four after Sunday.
      assert Grid.lead_blanks(first, 1) == 3
      assert Grid.lead_blanks(first, 7) == 4
      assert Grid.lead_blanks(first, 6) == 5
    end

    test "a first-of-month landing on the week start leaves none" do
      # 1 شهریور ۱۴۰۴ is a Saturday.
      {:ok, first} = Shamsi.to_gregorian(1404, 6, 1)
      assert first == ~D[2025-08-23]
      assert Grid.lead_blanks(first, 6) == 0
      # ...and five under a Monday-first week: the same Saturday, a different
      # number of columns from the start of the row.
      assert Grid.lead_blanks(first, 1) == 5
    end
  end

  describe "week_start/2 and week/2" do
    test "the week containing a date begins on the week start, and runs seven days" do
      # 2026-08-16 is a Sunday. Under a Saturday-first week it belongs to the
      # week beginning 2026-08-15; under a Monday-first week, to 2026-08-10.
      assert Grid.week_start(~D[2026-08-16], 6) == ~D[2026-08-15]
      assert Grid.week_start(~D[2026-08-16], 1) == ~D[2026-08-10]
      assert Grid.week_start(~D[2026-08-16], 7) == ~D[2026-08-16]

      assert Grid.week(~D[2026-08-16], 6) == [
               ~D[2026-08-15],
               ~D[2026-08-16],
               ~D[2026-08-17],
               ~D[2026-08-18],
               ~D[2026-08-19],
               ~D[2026-08-20],
               ~D[2026-08-21]
             ]
    end

    test "a date already on the week start is its own week start" do
      # 2026-08-15 is a Saturday.
      assert Grid.week_start(~D[2026-08-15], 6) == ~D[2026-08-15]
      assert Grid.column(~D[2026-08-15], 6) == 0
      assert hd(Grid.week(~D[2026-08-15], 6)) == ~D[2026-08-15]
    end

    test "every day of one week reports the same week" do
      week = Grid.week(~D[2026-08-16], 6)
      assert Enum.map(week, &Grid.week(&1, 6)) |> Enum.uniq() == [week]
    end
  end

  describe "month/5 — real Jalali months across a leap year and an ordinary one" do
    test "day 1 lands in its exact column, and the month is its exact length" do
      for {year, month, gregorian, weekday, column, length} <- @months do
        {:ok, grid} = Grid.month(year, month, Shamsi, 6, today: ~D[1970-01-01])

        assert grid.first_date == gregorian,
               "#{year}-#{month} should begin on #{gregorian} (#{weekday})"

        assert grid.lead_blanks == column,
               "#{year}-#{month} begins on a #{weekday}, so it belongs in column #{column}"

        assert grid.days_in_month == length
        assert grid.last_date == Date.add(gregorian, length - 1)

        cells = List.flatten(grid.rows)

        # The blanks stop exactly where day 1 starts — asserted from both sides,
        # so an off-by-one in either direction fails.
        assert Enum.all?(Enum.take(cells, column), &is_nil(&1.day))
        assert Enum.at(cells, column).day == 1
        assert Enum.at(cells, column).date == gregorian
      end
    end

    test "every month is six rows of seven, and the trailing blanks are counted" do
      for {year, month, _greg, _weekday, column, length} <- @months do
        {:ok, grid} = Grid.month(year, month, Shamsi, 6, today: ~D[1970-01-01])

        assert length(grid.rows) == 6
        assert Enum.all?(grid.rows, &(length(&1) == 7))

        cells = List.flatten(grid.rows)
        assert length(cells) == 42

        days = Enum.reject(cells, &is_nil(&1.day))
        assert length(days) == length
        assert Enum.map(days, & &1.day) == Enum.to_list(1..length)

        trailing = 42 - column - length
        assert Enum.all?(Enum.take(cells, -trailing), &is_nil(&1.day))

        # ...and nothing blank sits between two days.
        assert Enum.all?(Enum.take(Enum.drop(cells, column), length), & &1.day)
      end
    end

    test "column 0 is شنبه in every row, blanks included" do
      {:ok, grid} = Grid.month(1405, 5, Shamsi, 6, today: ~D[1970-01-01])

      assert hd(grid.weekday_order) == 6

      for row <- grid.rows do
        assert Enum.at(row, 0).iso_day_of_week == 6
        assert Enum.at(row, 6).iso_day_of_week == 5
        assert Enum.map(row, & &1.column) == [0, 1, 2, 3, 4, 5, 6]
      end
    end

    test "each day cell's weekday matches the date it carries" do
      # The grid derives weekdays arithmetically from the first day's, to avoid
      # 42 conversions. This checks the arithmetic against the real answer.
      for {year, month, _greg, _weekday, _column, _length} <- @months do
        {:ok, grid} = Grid.month(year, month, Shamsi, 6, today: ~D[1970-01-01])

        for cell <- List.flatten(grid.rows), cell.day do
          assert cell.iso_day_of_week == Cldr.Calendar.iso_day_of_week(cell.date)
          assert cell.date == Date.add(grid.first_date, cell.day - 1)
          assert cell.year == year and cell.month == month
        end
      end
    end

    test "1404 is ordinary and 1403 is leap, and اسفند shows it" do
      {:ok, leap} = Grid.month(1403, 12, Shamsi, 6, today: ~D[1970-01-01])
      {:ok, ordinary} = Grid.month(1404, 12, Shamsi, 6, today: ~D[1970-01-01])

      assert leap.days_in_month == 30
      assert ordinary.days_in_month == 29
      assert leap.last_date == ~D[2025-03-20]
      assert ordinary.last_date == ~D[2026-03-20]
    end

    test "the today flag lands on exactly one cell, and only when it is in the month" do
      {:ok, grid} = Grid.month(1405, 5, Shamsi, 6, today: ~D[2026-08-16])
      flagged = grid.rows |> List.flatten() |> Enum.filter(& &1.today?)

      assert length(flagged) == 1
      assert hd(flagged).date == ~D[2026-08-16]
      # 25 مرداد ۱۴۰۵.
      assert hd(flagged).day == 25

      {:ok, elsewhere} = Grid.month(1405, 1, Shamsi, 6, today: ~D[2026-08-16])
      assert elsewhere.rows |> List.flatten() |> Enum.all?(&(&1.today? == false))
    end

    test "a Gregorian month is the same machinery with a different first day" do
      {:ok, grid} = Grid.month(2026, 8, Calendar.ISO, 1, today: ~D[1970-01-01])

      # 2026-08-01 is a Saturday, ISO 6, so five columns in under a Monday week.
      assert grid.first_date == ~D[2026-08-01]
      assert grid.lead_blanks == 5
      assert grid.days_in_month == 31
      assert grid.weekday_order == [1, 2, 3, 4, 5, 6, 7]
      assert length(grid.rows) == 6
    end

    test "a year outside the Nowruz table is an error, not a wrong grid" do
      assert {:error, {:year_out_of_range, 2000}} = Grid.month(2000, 1, Shamsi, 6)
    end
  end

  describe "sequence is independent of direction" do
    test "ordering cannot branch on the locale, because it never sees one" do
      # The sequence must still start at شنبه with K-12's RTL provider disabled.
      # That holds structurally rather than by luck: `first_day` is a parameter,
      # and no executable line in the module can read the direction to branch on.
      body = code_only("lib/kati/calendar/grid.ex")

      refute body =~ "Kati.Locale",
             "the grid consults Kati.Locale; direction and sequence must stay separate"

      refute body =~ ~r/\brtl\b|layout_direction|LayoutDirection/,
             "the grid mentions direction in code; that belongs to the container"

      # ...and the module says so where a reader will find it.
      source = @root |> Path.join("lib/kati/calendar/grid.ex") |> File.read!()
      assert source =~ "Direction is a container attribute"

      {:ok, grid} = Grid.month(1405, 5, Shamsi, 6, today: ~D[1970-01-01])
      assert Grid.weekday_order(6) == [6, 7, 1, 2, 3, 4, 5]
      assert grid.weekday_order == [6, 7, 1, 2, 3, 4, 5]
    end

    test "columns run 0..6 ascending — nothing in the module reverses a list" do
      {:ok, grid} = Grid.month(1405, 5, Shamsi, 6, today: ~D[1970-01-01])
      {:ok, strip} = Grid.day_strip(~D[2026-08-16], Shamsi, 6, today: ~D[1970-01-01])

      for row <- grid.rows, do: assert(Enum.map(row, & &1.column) == Enum.to_list(0..6))
      assert Enum.map(strip, & &1.column) == Enum.to_list(0..6)
      # Dates ascend too: a mirrored grid would still ascend, a reversed one
      # would not.
      assert strip |> Enum.map(& &1.date) |> Enum.sort(Date) == Enum.map(strip, & &1.date)
    end

    test "no function in the grid or its calendar reverses a sequence" do
      for file <- ["lib/kati/calendar/grid.ex", "lib/kati/calendar/shamsi.ex"] do
        refute code_only(file) =~ "Enum.reverse",
               "#{file} reverses a list; direction is the container's job, not the data's"
      end
    end
  end

  describe "week_matrix/5 — screens 44 and 60" do
    test "columns carry the Saturday-first sequence in the data, before rendering" do
      {:ok, matrix} =
        Grid.week_matrix(~D[2026-08-16], [:breakfast], Shamsi, 6, today: ~D[1970-01-01])

      assert Enum.map(matrix.columns, & &1.iso_day_of_week) == [6, 7, 1, 2, 3, 4, 5]
      assert matrix.weekday_order == [6, 7, 1, 2, 3, 4, 5]
      assert matrix.first_day_of_week == 6
    end

    test "the same call with a Monday start returns 1..7" do
      {:ok, matrix} =
        Grid.week_matrix(~D[2026-08-16], [:breakfast], Calendar.ISO, 1, today: ~D[1970-01-01])

      assert Enum.map(matrix.columns, & &1.iso_day_of_week) == [1, 2, 3, 4, 5, 6, 7]
      assert matrix.weekday_order == [1, 2, 3, 4, 5, 6, 7]
    end

    test "the row axis is the caller's and passes through untouched" do
      slots = [:breakfast, :lunch, :snack, :dinner, :late]

      {:ok, matrix} = Grid.week_matrix(~D[2026-08-16], slots, Shamsi, 6, today: ~D[1970-01-01])

      assert length(matrix.rows) == 5
      assert Enum.map(matrix.rows, & &1.row) == slots

      for row <- matrix.rows do
        assert length(row.cells) == 7
        assert Enum.all?(row.cells, &(&1.row == row.row))
        assert Enum.map(row.cells, & &1.iso_day_of_week) == [6, 7, 1, 2, 3, 4, 5]
        assert Enum.map(row.cells, & &1.date) == Enum.map(matrix.columns, & &1.date)
      end
    end

    test "an anchor anywhere in the week produces the same seven columns" do
      week = Enum.map(0..6, &Date.add(~D[2026-08-15], &1))

      grids =
        for anchor <- week do
          {:ok, matrix} = Grid.week_matrix(anchor, [:x], Shamsi, 6, today: ~D[1970-01-01])
          Enum.map(matrix.columns, & &1.date)
        end

      assert Enum.uniq(grids) == [week]
    end
  end

  describe "day_strip/4 — screens 02, 43, 56 and 59" do
    test "seven cells, in column order, today flagged exactly once" do
      {:ok, cells} = Grid.day_strip(~D[2026-08-16], Shamsi, 6, today: ~D[2026-08-16])

      assert length(cells) == 7
      assert Enum.map(cells, & &1.iso_day_of_week) == [6, 7, 1, 2, 3, 4, 5]
      assert Enum.count(cells, & &1.today?) == 1
      assert Enum.find(cells, & &1.today?).date == ~D[2026-08-16]
      # 2026-08-16 is a Sunday, so it is the second cell of a Saturday-first week.
      assert Enum.find_index(cells, & &1.today?) == 1
    end

    test "no cell is flagged when today is outside the strip" do
      {:ok, cells} = Grid.day_strip(~D[2026-08-16], Shamsi, 6, today: ~D[2026-09-16])
      assert Enum.all?(cells, &(&1.today? == false))
    end

    test "every cell is a real day carrying its Jalali date" do
      {:ok, cells} = Grid.day_strip(~D[2026-08-16], Shamsi, 6, today: ~D[1970-01-01])

      assert Enum.map(cells, &{&1.year, &1.month, &1.day}) == [
               {1405, 5, 24},
               {1405, 5, 25},
               {1405, 5, 26},
               {1405, 5, 27},
               {1405, 5, 28},
               {1405, 5, 29},
               {1405, 5, 30}
             ]

      # Cross-checked against the conversion, one date at a time.
      for cell <- cells do
        assert Shamsi.from_gregorian(cell.date) == {cell.year, cell.month, cell.day}
      end
    end

    test "a strip that crosses a Jalali month boundary reports both months" do
      # 1 مرداد ۱۴۰۵ is 2026-07-23, a Thursday — column 5 — so the boundary
      # falls inside a week rather than on its edge. تیر has 31 days.
      #
      # A boundary that lands on a شنبه would never cross a strip at all, which
      # is why 1 شهریور ۱۴۰۴ (a Saturday) is the wrong month to test this with.
      {:ok, cells} = Grid.day_strip(~D[2026-07-23], Shamsi, 6, today: ~D[1970-01-01])

      assert hd(cells).date == ~D[2026-07-18]

      assert Enum.map(cells, &{&1.month, &1.day}) == [
               {4, 27},
               {4, 28},
               {4, 29},
               {4, 30},
               {4, 31},
               {5, 1},
               {5, 2}
             ]

      for cell <- cells do
        assert Shamsi.from_gregorian(cell.date) == {cell.year, cell.month, cell.day}
      end
    end

    test "a strip that crosses a Jalali year boundary rolls the year" do
      # نوروز ۱۴۰۵ is 2026-03-21, a Saturday: the week before ends on 29 اسفند
      # ۱۴۰۴, the last day of an ordinary year.
      {:ok, cells} = Grid.day_strip(~D[2026-03-20], Shamsi, 6, today: ~D[1970-01-01])

      assert Map.take(List.last(cells), [:year, :month, :day]) == %{
               year: 1404,
               month: 12,
               day: 29
             }

      {:ok, next} = Grid.day_strip(~D[2026-03-21], Shamsi, 6, today: ~D[1970-01-01])
      assert Map.take(hd(next), [:year, :month, :day]) == %{year: 1405, month: 1, day: 1}
    end

    test "arity 3 falls back to the device's today" do
      {:ok, cells} = Grid.day_strip(Kati.Time.today(), Shamsi, 6)
      assert Enum.count(cells, & &1.today?) == 1
      assert Enum.find(cells, & &1.today?).date == Kati.Time.today()
    end
  end

  describe "labels come from CLDR, reordered" do
    test "the fa header is ش ی د س چ پ ج, derived rather than written" do
      narrow = Kati.Cldr.Calendar.days("fa", :persian) |> get_in([:stand_alone, :narrow])

      {:ok, labels} = Grid.weekday_labels(:fa, 6)

      # Derived: the same map, reindexed by the Saturday-first order.
      assert labels == Enum.map([6, 7, 1, 2, 3, 4, 5], &Map.fetch!(narrow, &1))

      # ...and it matches the design, character by character. Both assertions
      # are needed: the first proves nothing is hand-written, the second catches
      # a CLDR change that would silently move the header.
      assert labels == @design_weekday_labels

      for {label, expected} <- Enum.zip(labels, @design_weekday_labels) do
        assert label == expected
      end
    end

    test "the unreordered CLDR map really does start at Monday" do
      # If this ever stops being true, the reordering above is wrong in a way
      # that would otherwise be invisible.
      narrow = Kati.Cldr.Calendar.days("fa", :persian) |> get_in([:stand_alone, :narrow])

      assert Map.fetch!(narrow, 1) == "د"
      assert Map.fetch!(narrow, 6) == "ش"
      assert Enum.map(1..7, &Map.fetch!(narrow, &1)) == ["د", "س", "چ", "پ", "ج", "ش", "ی"]
    end

    test "the wide fa labels reorder to شنبه first" do
      {:ok, labels} = Grid.weekday_labels(:fa, 6, format: :wide, context: :format)

      assert hd(labels) == "شنبه"
      assert List.last(labels) == "جمعه"
      assert Enum.at(labels, 1) == "یکشنبه"
    end

    test "the English header is Monday-first" do
      {:ok, labels} = Grid.weekday_labels(:en, 1, format: :abbreviated)
      assert labels == ~w(Mon Tue Wed Thu Fri Sat Sun)
    end

    test "month names come from CLDR too" do
      {:ok, months} = Grid.month_labels(:fa)

      assert months == ~w(فروردین اردیبهشت خرداد تیر مرداد شهریور مهر آبان آذر دی بهمن اسفند)
      assert {:ok, "مرداد"} = Grid.month_label(:fa, 5)
      assert {:ok, "August"} = Grid.month_label(:en, 8)
    end

    test "an unknown locale is an error, not a crash" do
      assert {:error, {:unknown_locale, :de}} = Grid.weekday_labels(:de, 6)
      assert {:error, {:unknown_locale, "de"}} = Grid.for_locale("de")
    end
  end

  describe "the week start comes from CLDR, and the :en trap is handled deliberately" do
    test "fa starts on Saturday, en on Monday" do
      assert Grid.first_day_of_week(:fa) == {:ok, 6}
      assert Grid.first_day_of_week(:en) == {:ok, 1}
    end

    test "asking CLDR for :en directly would give Sunday — which is the trap" do
      {:ok, en} = Kati.Cldr.validate_locale("en")
      {:ok, fa} = Kati.Cldr.validate_locale("fa")

      # This is why Kati's English row names territory :GB rather than resolving
      # the locale: :en resolves to US, and US week data says Sunday.
      assert Cldr.Calendar.first_day_for_locale(en) == 7
      assert Cldr.Calendar.first_day_for_locale(fa) == 6

      assert Cldr.Calendar.first_day_for_territory(:US) == 7
      assert Cldr.Calendar.first_day_for_territory(:GB) == 1
      assert Cldr.Calendar.first_day_for_territory(:IR) == 6

      {:ok, row} = Grid.for_locale(:en)
      assert row.week_territory == :GB
      assert row.first_day_of_week == 1
    end

    test "the locale row carries the calendar, not the direction" do
      {:ok, fa} = Grid.for_locale(:fa)
      {:ok, en} = Grid.for_locale(:en)

      assert fa.calendar == Shamsi
      assert fa.cldr_calendar == :persian
      assert en.calendar == Calendar.ISO
      assert en.cldr_calendar == :gregorian

      # Direction is Kati.Locale's, and it is deliberately not duplicated here.
      refute Map.has_key?(fa, :direction)
      assert Kati.Locale.direction(:fa) == :rtl
    end
  end

  describe "the quick-add lexicon" do
    test "Jalali month names resolve, however they are written" do
      assert Grid.month_from_label(:fa, "مرداد") == {:ok, 5}
      assert Grid.month_from_label(:fa, "  مرداد  ") == {:ok, 5}
      assert Grid.month_from_label(:fa, "اسفند") == {:ok, 12}
      assert Grid.month_from_label(:en, "August") == {:ok, 8}
      assert Grid.month_from_label(:en, "aug") == {:ok, 8}
    end

    test "پنجشنبه and پنج‌شنبه are the same day" do
      # CLDR writes it without a ZWNJ; Kati's own Shamsi literals write it with
      # one. The two strings differ by a single invisible codepoint.
      cldr = Kati.Cldr.Calendar.days("fa", :persian) |> get_in([:format, :wide]) |> Map.fetch!(4)
      kati = Shamsi.weekday_name(6)

      refute cldr == kati
      assert String.contains?(kati, @zwnj)
      refute String.contains?(cldr, @zwnj)

      assert Grid.weekday_from_label(:fa, cldr) == {:ok, 4}
      assert Grid.weekday_from_label(:fa, kati) == {:ok, 4}
    end

    test "the Arabic-keyboard forms of یکشنبه resolve too" do
      # ي U+064A instead of ی U+06CC, ك U+0643 instead of ک U+06A9.
      persian_form = "\u06CC\u06A9\u0634\u0646\u0628\u0647"
      arabic_form = "\u064A\u0643\u0634\u0646\u0628\u0647"

      refute arabic_form == persian_form
      assert Grid.weekday_from_label(:fa, persian_form) == {:ok, 7}
      assert Grid.weekday_from_label(:fa, arabic_form) == {:ok, 7}
    end

    test "an ambiguous abbreviation does not resolve to a guess" do
      # English narrow is M T W T F S S: "T" is Tuesday and Thursday both.
      assert Grid.weekday_from_label(:en, "T") == :error
      assert Grid.weekday_from_label(:en, "S") == :error
      assert Grid.weekday_from_label(:en, "Tue") == {:ok, 2}
      assert Grid.weekday_from_label(:en, "Thursday") == {:ok, 4}
    end

    test "every fa weekday name round-trips through its own label" do
      # first_day: 1 gives the labels in plain ISO order, so index n-1 is day n.
      {:ok, labels} = Grid.weekday_labels(:fa, 1, format: :wide, context: :format)

      for {label, iso} <- Enum.with_index(labels, 1) do
        assert Grid.weekday_from_label(:fa, label) == {:ok, iso}
      end
    end

    test "every fa month name round-trips through its own label" do
      {:ok, months} = Grid.month_labels(:fa)

      for {name, index} <- Enum.with_index(months, 1) do
        assert Grid.month_from_label(:fa, name) == {:ok, index}
      end
    end

    test "a word that is not a month or a day is an error" do
      assert Grid.month_from_label(:fa, "صبح") == :error
      assert Grid.weekday_from_label(:fa, "فردا") == :error
    end
  end

  describe "the UTC range a Jalali month spans" do
    test "مرداد ۱۴۰۵ straddles two Gregorian months" do
      {:ok, grid} = Grid.month(1405, 5, Shamsi, 6, today: ~D[1970-01-01])
      {:ok, {from, to}} = Grid.utc_range(grid, "Asia/Tehran")

      assert grid.first_date == ~D[2026-07-23]
      assert grid.last_date == ~D[2026-08-22]
      refute grid.first_date.month == grid.last_date.month

      # Half-open: midnight Tehran on the first day, midnight Tehran on the day
      # after the last. Tehran is UTC+3:30 with no DST since 1401.
      assert DateTime.to_date(from) == ~D[2026-07-22]
      assert DateTime.to_time(from) == ~T[20:30:00]
      assert DateTime.to_date(to) == ~D[2026-08-22]
      assert DateTime.to_time(to) == ~T[20:30:00]
      assert from.time_zone == "Etc/UTC" and to.time_zone == "Etc/UTC"
    end

    test "every Jalali month of 1405 straddles a Gregorian boundary" do
      for month <- 1..12 do
        {:ok, grid} = Grid.month(1405, month, Shamsi, 6, today: ~D[1970-01-01])

        refute grid.first_date.month == grid.last_date.month,
               "#{month} runs #{grid.first_date}..#{grid.last_date}, inside one Gregorian month"
      end
    end

    test "the range is half-open, so the two ends never overlap" do
      {:ok, mordad} = Grid.month(1405, 5, Shamsi, 6, today: ~D[1970-01-01])
      {:ok, shahrivar} = Grid.month(1405, 6, Shamsi, 6, today: ~D[1970-01-01])

      {:ok, {_, mordad_to}} = Grid.utc_range(mordad, "Asia/Tehran")
      {:ok, {shahrivar_from, _}} = Grid.utc_range(shahrivar, "Asia/Tehran")

      assert DateTime.compare(mordad_to, shahrivar_from) == :eq
    end

    test "the range follows the zone, not UTC" do
      {:ok, grid} = Grid.month(1405, 5, Shamsi, 6, today: ~D[1970-01-01])

      {:ok, {tehran, _}} = Grid.utc_range(grid, "Asia/Tehran")
      {:ok, {amsterdam, _}} = Grid.utc_range(grid, "Europe/Amsterdam")

      # Tehran is UTC+3:30 all year (Iran dropped DST in 1401); Amsterdam is
      # UTC+2 in July. Midnight comes to Tehran ninety minutes earlier.
      assert DateTime.compare(tehran, amsterdam) == :lt
      assert DateTime.diff(amsterdam, tehran) == 90 * 60
    end
  end

  describe "the code path is the one the issue requires" do
    test "Cldr.Calendar.localize is not reachable from the grid" do
      # localize/3 iterates Cldr.Calendar.Interval.week/1, which is
      # {:error, :not_defined} for Persian — so it does not degrade, it raises.
      for file <- [
            "lib/kati/calendar/grid.ex",
            "lib/kati/calendar/shamsi.ex",
            "lib/kati/calendar/nowruz_table.ex",
            "lib/kati/i18n/digits.ex"
          ] do
        refute code_only(file) =~ "localize",
               "#{file} calls Cldr.Calendar.localize/3, which raises for Persian dates"
      end

      # The prohibition is written down as well as enforced, so the next person
      # to reach for localize/3 finds out why before the crash does.
      source = @root |> Path.join("lib/kati/calendar/grid.ex") |> File.read!()
      assert source =~ "Cldr.Calendar.localize/3"
    end

    test "the grid references no Mob.* API" do
      refute code_only("lib/kati/calendar/grid.ex") =~ ~r/\bMob\./
      refute code_only("lib/kati/i18n/digits.ex") =~ ~r/\bMob\./
    end

    test "the Persian CLDR calendar dependency is not loaded, and fa still works" do
      # ex_cldr_calendars_persian is `only: :dev, runtime: false` in mix.exs: it
      # generates the Nowruz table and never ships. If the grid needed it at
      # runtime this assertion would fail, and the dependency would have to move.
      refute Code.ensure_loaded?(Cldr.Calendar.Persian)

      assert {:ok, @design_weekday_labels} = Grid.weekday_labels(:fa, 6)
      assert {:ok, %{first_date: ~D[2026-07-23]}} = Grid.month(1405, 5, Shamsi, 6)
    end

    test "no Ash resource stores a Persian calendar" do
      # Storage stays Calendar.ISO; Shamsi is a Date view at the presentation
      # boundary only. An attribute typed in a Persian calendar would make every
      # range query and every sync comparison a conversion.
      resources =
        [@root, "lib/kati/{calendars,media,meals,spike}/**/*.ex"]
        |> Path.join()
        |> Path.wildcard()

      assert length(resources) > 10,
             "expected to find the Ash resources, found #{length(resources)}"

      for file <- resources do
        source = File.read!(file)

        refute source =~ "Shamsi",
               "#{Path.relative_to(file, @root)} mentions Shamsi; storage must stay Calendar.ISO"

        refute source =~ "Cldr.Calendar.Persian",
               "#{Path.relative_to(file, @root)} names a Persian calendar in the data layer"
      end
    end
  end
end

defmodule Kati.Calendar.GridConversionTest do
  @moduledoc """
  One calendar conversion per grid, counted.

  The measurement the issue rests on: `Date.convert!/2` into a Persian calendar
  costs ~476 µs, so a 42-cell grid built the obvious way is ~7.9 ms of pure
  conversion per render on a Mac and several times that on a phone. This asserts
  the shape that avoids it — convert once, walk — by tracing the two functions
  that actually perform a conversion and counting the calls.

  Not `async: true`: `:erlang.trace_pattern/3` is VM-global.
  """
  use ExUnit.Case, async: false

  alias Kati.Calendar.Grid
  alias Kati.Calendar.Shamsi

  setup do
    for {mod, fun, arity} <- Grid.calendar_conversions() do
      # `trace_pattern` silently matches nothing when the module is not loaded
      # yet, and every count below would then be a confident zero. Load it, and
      # assert the pattern took.
      Code.ensure_loaded!(mod)

      assert :erlang.trace_pattern({mod, fun, arity}, true, [:local]) == 1,
             "no trace pattern set for #{inspect(mod)}.#{fun}/#{arity}"
    end

    on_exit(fn ->
      for {mod, fun, arity} <- Grid.calendar_conversions() do
        :erlang.trace_pattern({mod, fun, arity}, false, [:local])
      end
    end)

    :ok
  end

  # The work runs in a spawned process with the test process as its tracer.
  #
  # Not for isolation — because a process cannot usefully trace itself. Measured
  # on OTP 29: `:erlang.trace(self(), true, [:call])` returns 1, `trace_info`
  # reports `{:flags, [:call]}` and `{:traced, :local}`, and **no trace message
  # is ever delivered**. A self-traced counter reads zero for every call, which
  # is exactly the number this test wants to see — so it would have passed
  # against an implementation that converted 42 times.
  defp conversions(fun) do
    parent = self()

    worker =
      spawn(fn ->
        receive do
          :go -> send(parent, {:result, fun.()})
        end
      end)

    assert :erlang.trace(worker, true, [:call, {:tracer, parent}]) == 1
    send(worker, :go)

    result =
      receive do
        {:result, r} -> r
      after
        5_000 -> flunk("the traced worker never finished")
      end

    # Trace signals for the calls are emitted before the worker's own send, and
    # signal order between two processes is guaranteed, so the mailbox is
    # complete by the time {:result, _} has been taken out of it.
    {result, drain([])}
  end

  defp drain(acc) do
    receive do
      {:trace, _pid, :call, {mod, fun, args}} -> drain([{mod, fun, length(args)} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  test "the trace actually fires — otherwise every count below would be zero" do
    {_, calls} = conversions(fn -> Shamsi.to_gregorian(1405, 5, 1) end)
    assert calls == [{Shamsi, :to_gregorian, 3}]

    {_, calls} = conversions(fn -> Shamsi.from_gregorian(~D[2026-07-23]) end)
    assert calls == [{Shamsi, :from_gregorian, 1}]
  end

  test "a 42-cell month grid converts once, not 42 times" do
    {{:ok, grid}, calls} =
      conversions(fn -> Grid.month(1405, 5, Shamsi, 6, today: ~D[1970-01-01]) end)

    assert grid.rows |> List.flatten() |> length() == 42
    assert grid.rows |> List.flatten() |> Enum.count(& &1.day) == 31
    assert calls == [{Shamsi, :to_gregorian, 3}]
  end

  test "every month of a year converts once each" do
    for month <- 1..12 do
      {{:ok, _}, calls} =
        conversions(fn -> Grid.month(1405, month, Shamsi, 6, today: ~D[1970-01-01]) end)

      assert calls == [{Shamsi, :to_gregorian, 3}],
             "month #{month} performed #{length(calls)} conversions"
    end
  end

  test "a seven-day strip converts once, not seven times" do
    {{:ok, cells}, calls} =
      conversions(fn -> Grid.day_strip(~D[2026-08-16], Shamsi, 6, today: ~D[1970-01-01]) end)

    assert length(cells) == 7
    assert calls == [{Shamsi, :from_gregorian, 1}]
  end

  test "a strip crossing a month boundary still converts once" do
    {{:ok, cells}, calls} =
      conversions(fn -> Grid.day_strip(~D[2026-07-23], Shamsi, 6, today: ~D[1970-01-01]) end)

    assert cells |> Enum.map(& &1.month) |> Enum.uniq() == [4, 5]
    assert calls == [{Shamsi, :from_gregorian, 1}]
  end

  test "a 5x7 matrix converts once regardless of how many rows it has" do
    for rows <- [[], [:a], [:a, :b, :c, :d, :e], Enum.to_list(1..20)] do
      {{:ok, _}, calls} =
        conversions(fn ->
          Grid.week_matrix(~D[2026-08-16], rows, Shamsi, 6, today: ~D[1970-01-01])
        end)

      assert calls == [{Shamsi, :from_gregorian, 1}],
             "#{length(rows)} rows performed #{length(calls)} conversions"
    end
  end
end
