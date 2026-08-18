defmodule Kati.Recurrence do
  @moduledoc """
  RFC 5545 recurrence expansion.

  Pure Elixir, no `Mob.*`, so it tests entirely on the host.

  ## Expand in wall clock, in the event's own zone, then convert

  The pipeline is `{dtstart_wall, rrule} → NaiveDateTime candidates → attach
  tzid → shift to UTC`. Never iterate in UTC: an event stored as a UTC instant
  plus an RRULE drifts by an hour when its zone's offset changes, which the
  research names as the single most common recurrence bug in the wild.

  ## Drop, do not clamp

  §3.3.10: *"Recurrence rules may generate recurrence instances with an invalid
  date (e.g., February 30) or nonexistent local time … Such recurrence instances
  MUST be ignored and MUST NOT be counted as part of the recurrence set."*

  Two consequences, both tested:

    * `FREQ=MONTHLY;BYMONTHDAY=31` **skips** February, April, June, September
      and November. It does not fall back to the 28th or 30th.
    * A dropped instance **does not consume a `COUNT` slot**. This is easy to get
      wrong when `COUNT` is applied as a `take/2` over generated candidates.

  ## Timezone edges — and the deliberate split with the event editor

    * `{:gap, _, _}` — a nonexistent local time. `expand/6` **drops** it, as the
      RFC mandates.
    * `{:ambiguous, first, _}` — takes `first`, the pre-transition offset. The
      RFC does not specify this; the choice is Kati's.

  Note this differs from `Kati.Time.resolve/2`, which picks the `after` instant
  for a gap. That is correct for a **user-entered single time** — someone who
  set 01:30 wants their alarm — and wrong for a **recurrence instance**, which
  the RFC says must vanish. Both behaviours exist on purpose; `expand/6` gets
  the RFC's, the event editor gets `Kati.Time`'s.

  ## WKST

  Honoured when given, defaulting to `MO` per the RFC — **not** to the current
  locale. It changes which weeks `INTERVAL > 1` groups together, so a fortnightly
  event authored in a Saturday-start locale and one authored in a Monday-start
  locale can legitimately land on different dates. Storing it explicitly is what
  stops an event moving when the UI language changes.
  """

  alias Kati.Recurrence.Rule

  @max_iterations 10_000

  @doc """
  Expand a recurrence into instants within a window.

  Returns UTC `DateTime`s (or `Date`s for all-day), sorted and deduplicated.

  `tzid` of `nil` means floating time: the wall clock is the truth and the
  instant depends on wherever the device is. Callers render floating events in
  the device zone rather than converting at expansion.
  """
  @spec expand(
          NaiveDateTime.t() | Date.t(),
          String.t() | nil,
          Rule.t() | nil,
          [NaiveDateTime.t() | Date.t()],
          [NaiveDateTime.t() | Date.t()],
          {DateTime.t(), DateTime.t()}
        ) :: [DateTime.t() | Date.t()]
  def expand(dtstart, tzid, rule, rdates \\ [], exdates \\ [], window)

  def expand(%Date{} = dtstart, _tzid, rule, rdates, exdates, {from, to}) do
    # All-day: dates all the way down, no zone involved.
    from_d = DateTime.to_date(from)
    to_d = DateTime.to_date(to)

    base = if rule, do: expand_dates(dtstart, rule, to_d), else: [dtstart]

    (base ++ Enum.filter(rdates, &match?(%Date{}, &1)))
    |> Enum.reject(&(&1 in exdates))
    |> Enum.filter(&(Date.compare(&1, from_d) != :lt and Date.compare(&1, to_d) != :gt))
    |> Enum.uniq()
    |> Enum.sort(Date)
  end

  def expand(%NaiveDateTime{} = dtstart, tzid, rule, rdates, exdates, {from, to}) do
    zone = tzid || "Etc/UTC"
    to_wall = to |> shift(zone) |> DateTime.to_naive()

    naive_instances =
      if rule, do: expand_naive(dtstart, rule, to_wall), else: [dtstart]

    (naive_instances ++ Enum.filter(rdates, &match?(%NaiveDateTime{}, &1)))
    |> Enum.uniq()
    |> Enum.reject(fn n -> Enum.any?(exdates, &naive_eq?(&1, n)) end)
    |> Enum.flat_map(&to_instant(&1, tzid))
    |> Enum.filter(fn dt ->
      DateTime.compare(dt, from) != :lt and DateTime.compare(dt, to) != :gt
    end)
    |> Enum.uniq_by(&DateTime.to_unix(&1, :microsecond))
    |> Enum.sort(DateTime)
  end

  defp naive_eq?(%NaiveDateTime{} = a, b), do: NaiveDateTime.compare(a, b) == :eq
  defp naive_eq?(_, _), do: false

  defp shift(dt, zone) do
    case DateTime.shift_zone(dt, zone) do
      {:ok, shifted} -> shifted
      _ -> dt
    end
  end

  # A nonexistent local time is dropped, per the RFC. An ambiguous one takes the
  # first (pre-transition) offset.
  defp to_instant(naive, nil) do
    # Floating: the caller renders it in the device zone. Represented here as a
    # UTC instant of the same wall clock so windowing works.
    [DateTime.from_naive!(naive, "Etc/UTC")]
  end

  defp to_instant(naive, tzid) do
    case DateTime.from_naive(naive, tzid) do
      {:ok, dt} -> [DateTime.shift_zone!(dt, "Etc/UTC")]
      {:ambiguous, first, _second} -> [DateTime.shift_zone!(first, "Etc/UTC")]
      {:gap, _before, _after} -> []
      {:error, _} -> []
    end
  end

  # ── Expansion ────────────────────────────────────────────────────────────

  defp expand_naive(dtstart, rule, to_wall) do
    {h, m, s} = {dtstart.hour, dtstart.minute, dtstart.second}

    dtstart
    |> NaiveDateTime.to_date()
    |> candidate_dates(rule, NaiveDateTime.to_date(to_wall))
    |> Enum.flat_map(fn date -> times_for(date, rule, {h, m, s}) end)
    |> Enum.filter(&(NaiveDateTime.compare(&1, dtstart) != :lt))
    |> Enum.sort(NaiveDateTime)
    |> apply_until_count(rule, & &1)
  end

  defp expand_dates(dtstart, rule, to_date) do
    dtstart
    |> candidate_dates(rule, to_date)
    |> Enum.filter(&(Date.compare(&1, dtstart) != :lt))
    |> Enum.sort(Date)
    |> apply_until_count(rule, & &1)
  end

  # COUNT counts what SURVIVES. Dropped invalid dates never reached this list,
  # so take/2 here is correct precisely because generation already dropped them.
  defp apply_until_count(list, %Rule{count: nil, until: nil}, _), do: list

  defp apply_until_count(list, %Rule{count: n, until: nil}, _) when is_integer(n),
    do: Enum.take(list, n)

  defp apply_until_count(list, %Rule{until: until}, _) when not is_nil(until),
    do: Enum.filter(list, &before_until?(&1, until))

  defp before_until?(%Date{} = d, %Date{} = u), do: Date.compare(d, u) != :gt

  defp before_until?(%NaiveDateTime{} = n, %DateTime{} = u),
    do: NaiveDateTime.compare(n, DateTime.to_naive(u)) != :gt

  defp before_until?(%NaiveDateTime{} = n, %Date{} = u),
    do: Date.compare(NaiveDateTime.to_date(n), u) != :gt

  defp before_until?(%Date{} = d, %DateTime{} = u),
    do: Date.compare(d, DateTime.to_date(u)) != :gt

  # Generate candidate DATES period by period, applying the BY parts.
  defp candidate_dates(start_date, %Rule{} = rule, to_date) do
    Stream.iterate(0, &(&1 + 1))
    |> Stream.take(@max_iterations)
    |> Enum.reduce_while([], fn i, acc ->
      period_start = advance(start_date, rule.freq, i * rule.interval)

      cond do
        Date.compare(period_start, to_date) == :gt and acc != [] -> {:halt, acc}
        Date.compare(period_start, to_date) == :gt -> {:halt, acc}
        true -> {:cont, acc ++ dates_in_period(period_start, rule, to_date)}
      end
    end)
    |> Enum.filter(&(Date.compare(&1, to_date) != :gt))
    |> Enum.uniq()
    |> Enum.sort(Date)
  end

  defp advance(date, :daily, n), do: Date.add(date, n)
  defp advance(date, :weekly, n), do: Date.add(date, n * 7)
  defp advance(date, :monthly, n), do: add_months(date, n)
  defp advance(date, :yearly, n), do: add_months(date, n * 12)
  # Sub-daily frequencies advance by day here; times_for/3 fans out within it.
  defp advance(date, _, n), do: Date.add(date, n)

  # Month arithmetic that does NOT clamp: a day that does not exist in the
  # target month yields :invalid and is dropped by the caller, per the RFC.
  defp add_months(date, n) do
    total = date.year * 12 + date.month - 1 + n
    year = div(total, 12)
    month = rem(total, 12) + 1

    case Date.new(year, month, date.day) do
      {:ok, d} ->
        d

      # February 30 and friends: return a sentinel far outside any window rather
      # than clamping to the 28th, so the instance is simply absent.
      {:error, :invalid_date} ->
        %Date{year: year, month: month, day: 1, calendar: Calendar.ISO}
        |> Map.put(:__invalid__, true)
    end
  end

  defp dates_in_period(period_start, %Rule{} = rule, to_date) do
    dates =
      case rule.freq do
        :weekly -> week_dates(period_start, rule)
        :monthly -> month_dates(period_start, rule)
        :yearly -> year_dates(period_start, rule)
        _ -> [period_start]
      end

    dates
    |> Enum.reject(&Map.get(&1, :__invalid__, false))
    |> Enum.filter(&by_month_ok?(&1, rule))
    |> Enum.filter(&by_monthday_ok?(&1, rule))
    |> Enum.filter(&by_day_ok?(&1, rule))
    |> Enum.filter(&(Date.compare(&1, to_date) != :gt))
    |> apply_setpos(rule)
  end

  defp week_dates(period_start, %Rule{by_day: []} = _rule), do: [period_start]

  defp week_dates(period_start, %Rule{} = rule) do
    # The week containing period_start, aligned to WKST.
    offset = Rule.day_index(Rule.weekday(period_start), rule.wkst) - 1
    week_start = Date.add(period_start, -offset)

    rule.by_day
    |> Enum.map(fn {_n, day} -> Date.add(week_start, Rule.day_index(day, rule.wkst) - 1) end)
  end

  defp month_dates(period_start, %Rule{by_monthday: [], by_day: []}), do: [period_start]

  defp month_dates(period_start, %Rule{} = rule) do
    days_in_month = Date.days_in_month(period_start)
    first = %{period_start | day: 1}

    from_monthday =
      Enum.flat_map(rule.by_monthday, fn d ->
        day = if d < 0, do: days_in_month + d + 1, else: d

        case Date.new(period_start.year, period_start.month, day) do
          {:ok, date} -> [date]
          _ -> []
        end
      end)

    from_byday =
      Enum.flat_map(rule.by_day, fn {n, day} ->
        all =
          for offset <- 0..(days_in_month - 1),
              date = Date.add(first, offset),
              Rule.weekday(date) == day,
              do: date

        cond do
          is_nil(n) -> all
          n > 0 -> Enum.slice(all, n - 1, 1)
          true -> Enum.slice(all, length(all) + n, 1)
        end
      end)

    case {from_monthday, from_byday} do
      {[], b} -> b
      {m, []} -> m
      # Both present: BYDAY limits BYMONTHDAY (Note 1 in the expand/limit table).
      {m, b} -> Enum.filter(m, &(&1 in b))
    end
  end

  defp year_dates(period_start, %Rule{by_month: []} = rule) when rule.by_day == [],
    do: [period_start]

  defp year_dates(period_start, %Rule{} = rule) do
    months = if rule.by_month == [], do: [period_start.month], else: rule.by_month

    Enum.flat_map(months, fn month ->
      case Date.new(period_start.year, month, 1) do
        {:ok, first} ->
          month_dates(%{first | day: min(period_start.day, Date.days_in_month(first))}, rule)

        _ ->
          []
      end
    end)
  end

  defp by_month_ok?(_date, %Rule{by_month: []}), do: true
  defp by_month_ok?(date, %Rule{by_month: months}), do: date.month in months

  defp by_monthday_ok?(_date, %Rule{by_monthday: []}), do: true
  defp by_monthday_ok?(_date, %Rule{freq: f}) when f in [:monthly, :yearly], do: true

  defp by_monthday_ok?(date, %Rule{by_monthday: days}) do
    dim = Date.days_in_month(date)
    Enum.any?(days, fn d -> if d < 0, do: dim + d + 1 == date.day, else: d == date.day end)
  end

  defp by_day_ok?(_date, %Rule{by_day: []}), do: true
  defp by_day_ok?(_date, %Rule{freq: f}) when f in [:weekly, :monthly, :yearly], do: true

  defp by_day_ok?(date, %Rule{by_day: days}) do
    wd = Rule.weekday(date)
    Enum.any?(days, fn {_n, d} -> d == wd end)
  end

  defp apply_setpos(dates, %Rule{by_setpos: []}), do: dates

  defp apply_setpos(dates, %Rule{by_setpos: positions}) do
    sorted = Enum.sort(dates, Date)
    n = length(sorted)

    positions
    |> Enum.flat_map(fn p ->
      idx = if p > 0, do: p - 1, else: n + p

      case Enum.at(sorted, idx) do
        nil -> []
        d -> [d]
      end
    end)
    |> Enum.uniq()
  end

  defp times_for(date, %Rule{by_hour: [], by_minute: [], by_second: []}, {h, m, s}) do
    case NaiveDateTime.new(date.year, date.month, date.day, h, m, s) do
      {:ok, n} -> [n]
      _ -> []
    end
  end

  defp times_for(date, %Rule{} = rule, {h, m, s}) do
    hours = if rule.by_hour == [], do: [h], else: rule.by_hour
    minutes = if rule.by_minute == [], do: [m], else: rule.by_minute
    seconds = if rule.by_second == [], do: [s], else: rule.by_second

    for hh <- hours, mm <- minutes, ss <- seconds do
      NaiveDateTime.new(date.year, date.month, date.day, hh, mm, ss)
    end
    |> Enum.flat_map(fn
      {:ok, n} -> [n]
      _ -> []
    end)
  end
end
