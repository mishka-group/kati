defmodule Kati.Calendar.Grid do
  @moduledoc """
  Month grids, week matrices and day strips — with the week start as a
  **parameter**, not a branch.

  Everything a calendar surface lays out on a day axis comes from here: the 6×7
  month grid (screens 16 and 60), the 5×7 meal matrix (screens 44 and 60) and
  the seven-pill day strip (screens 02, 43, 56 and 59). All three share one
  question — *which column is this date in?* — and one answer, `column/2`.

  ## Ordering is data. Direction is a container attribute.

  A Jalali week starts on **شنبه**. That is a fact about the calendar, and it
  survives into the returned data structure: `weekday_order(6)` is
  `[6, 7, 1, 2, 3, 4, 5]` whether or not anything is ever rendered, whether or
  not the renderer is RTL, whether or not `LocalLayoutDirection` has been set.

  Mirroring is the other mechanism entirely. It belongs to the native pass —
  `CompositionLocalProvider(LocalLayoutDirection …)` — and to
  `Kati.Locale.direction/1`, and **not one function in this module reverses a
  list**. Screen 60's warning is exactly about conflating them:

  > *"the hardest case in the whole pass: a matrix whose columns are days.
  > Mirroring alone would put Monday on the right and still be wrong — the
  > sequence itself has to restart at شنبه."*

  Put the other way: mirror a Monday-first grid and you get Monday on the right,
  which is a different wrong answer, not a right one. Reverse a Saturday-first
  grid and you get جمعه first, which is also wrong. The order is right *before*
  direction is considered, and direction then does nothing to the order.

  ## One conversion per grid, not one per cell

  `Date.convert!/2` into a Persian calendar costs ~476 µs, so a naive 42-cell
  grid is ~7.9 ms of pure conversion per render on an Apple-silicon Mac and
  several times that on a mid-range phone. Every function here converts
  **once** — the first of the month, or the first day of the strip — and then
  walks: ISO dates by `Date.add/2`, calendar dates by incrementing the day and
  rolling over on `days_in_month`, weekday indices by arithmetic on the first
  day's. `calendar_conversions/0` names the two functions a test can trace to
  prove it.

  ## Labels are CLDR's, after reordering

  `weekday_labels/3` reads `Kati.Cldr.Calendar.days/2` and reorders it by
  `weekday_order/1`; for `fa` + `:persian` + `stand_alone.narrow` that produces
  **ش ی د س چ پ ج**, character for character the design's abbreviations, with
  nothing hand-written.

  `Cldr.Calendar.localize/3` is **not** used and must not be: its implementation
  iterates `Cldr.Calendar.Interval.week/1`, which is `{:error, :not_defined}`
  for Persian, so it does not degrade — it raises.

  ## Pure, with one door

  Nothing here calls `Mob.*`, and every function is host-testable. The single
  exception is the `:today` option, which defaults to `Kati.Time.today/0` —
  the device zone's today, because a grid that highlights the wrong day between
  midnight and 02:00 is wrong in the way users notice first. Pass `:today`
  explicitly and the call is pure; every test below does.
  """

  alias Kati.Calendar.Shamsi
  alias Kati.I18n.Digits

  @type cell :: %{
          day: pos_integer() | nil,
          date: Date.t() | nil,
          year: integer() | nil,
          month: 1..12 | nil,
          iso_day_of_week: 1..7,
          column: 0..6,
          today?: boolean()
        }

  @type grid :: %{
          calendar: module(),
          year: integer(),
          month: 1..12,
          first_day_of_week: 1..7,
          weekday_order: [1..7],
          days_in_month: pos_integer(),
          lead_blanks: 0..6,
          first_date: Date.t(),
          last_date: Date.t(),
          rows: [[cell()]]
        }

  @type matrix :: %{
          first_day_of_week: 1..7,
          weekday_order: [1..7],
          columns: [cell()],
          rows: [%{row: term(), cells: [map()]}]
        }

  # The locale row the design promises: "add a locale row (direction, calendar,
  # digits, week start, typeface) · translate one flat key file … · Nothing
  # else." Direction is deliberately absent — it lives in Kati.Locale, because
  # it is a container attribute and this module is about sequence.
  #
  # `week_territory` rather than a literal first day, and rather than the
  # locale, because of a one-character trap: `first_day_for_locale(:en)` is
  # **7 (Sunday)**, since `:en` resolves to territory US, while Kati's design
  # table says English → Monday. Naming :GB records that choice where it can be
  # read, and keeps the value CLDR's rather than ours.
  @locale_rows %{
    fa: %{cldr_locale: "fa", cldr_calendar: :persian, calendar: Shamsi, week_territory: :IR},
    en: %{
      cldr_locale: "en",
      cldr_calendar: :gregorian,
      calendar: Calendar.ISO,
      week_territory: :GB
    }
  }

  # Label sets safe to reverse-index. `:narrow` is excluded because it is
  # ambiguous by construction — English narrow is M T W T F S S, where "T" is
  # both Tuesday and Thursday. `:short` exists for days but not for months;
  # `label_set/4` answers `{:error, …}` there and the generator drops it.
  @reversible_formats [:wide, :abbreviated, :short]
  @label_contexts [:format, :stand_alone]

  # Orthographic variants that must collapse before a label is looked up. Named
  # by escape rather than pasted, because four of the seven are invisible.
  #
  # ZWNJ is the one that bites: CLDR's `fa` data writes پنجشنبه with no joiner
  # while Kati's own literals (and most Iranian input) write پنج‌شنبه with one,
  # so an un-normalised lookup misses on two strings that render identically.
  # The yeh and kaf pairs are the Arabic-keyboard forms of the Persian letters —
  # U+064A vs U+06CC, U+0643 vs U+06A9 — which no amount of care at the input
  # field prevents a paste from introducing.
  @orthography %{
    # ZWNJ, ZWJ, LRM, RLM — all zero-width, all dropped
    "\u200C" => "",
    "\u200D" => "",
    "\u200E" => "",
    "\u200F" => "",
    # Arabic yeh (U+064A) and alef maksura (U+0649) -> Farsi yeh (U+06CC)
    "\u064A" => "\u06CC",
    "\u0649" => "\u06CC",
    # Arabic kaf (U+0643) -> keheh (U+06A9)
    "\u0643" => "\u06A9"
  }

  @rows 6
  @cols 7

  # ── the ordering primitives ──────────────────────────────────────────────

  @doc """
  The seven ISO weekday numbers in column order for a given first day.

  ISO numbering throughout: 1 is Monday … 7 is Sunday. So Saturday-first is
  `[6, 7, 1, 2, 3, 4, 5]`, Monday-first is `[1, 2, 3, 4, 5, 6, 7]` and
  Sunday-first is `[7, 1, 2, 3, 4, 5, 6]`.

      iex> Kati.Calendar.Grid.weekday_order(6)
      [6, 7, 1, 2, 3, 4, 5]

  """
  @spec weekday_order(1..7) :: [1..7]
  def weekday_order(first_day) when first_day in 1..7 do
    Enum.map(0..6, &(rem(first_day - 1 + &1, 7) + 1))
  end

  @doc """
  The column `date` occupies in a week that starts on `first_day`, 0-indexed.

  This is the whole of the layout rule. `lead_blanks/2` is this function applied
  to the first of the month; a day strip's anchor offset is this function
  applied to the anchor.
  """
  @spec column(Date.t(), 1..7) :: 0..6
  def column(%Date{} = date, first_day) when first_day in 1..7 do
    offset(Cldr.Calendar.iso_day_of_week(date), first_day)
  end

  @doc """
  How many blank cells precede day 1 of the month.

  The check the research ran, which is also the first test: 1 مرداد ۱۴۰۵ is
  2026-07-23, `iso_day_of_week` 4 (Thursday), so under a Saturday start
  `rem(4 - 6 + 7, 7) = 5` — شنبه through چهارشنبه blank, then پنجشنبه.
  """
  @spec lead_blanks(Date.t(), 1..7) :: 0..6
  def lead_blanks(%Date{} = first_of_month, first_day), do: column(first_of_month, first_day)

  @doc "The ISO date the week containing `date` begins on, under `first_day`."
  @spec week_start(Date.t(), 1..7) :: Date.t()
  def week_start(%Date{} = date, first_day), do: Date.add(date, -column(date, first_day))

  @doc "The seven ISO dates of the week containing `date`, in column order."
  @spec week(Date.t(), 1..7) :: [Date.t()]
  def week(%Date{} = date, first_day) do
    start = week_start(date, first_day)
    Enum.map(0..6, &Date.add(start, &1))
  end

  # ── the grids ────────────────────────────────────────────────────────────

  @doc """
  A month grid: six rows of seven cells, column 0 being `first_day`.

  Six rows rather than five, always. A month of 31 days starting six columns in
  needs 37 cells, which no 5×7 grid holds; a grid that sometimes has five rows
  and sometimes six also changes height as the user pages, which the design's
  screen 16 does not do.

  Cells outside the month are blanks — `day: nil`, `date: nil` — never dates
  borrowed from the neighbouring month, so a renderer never has to decide what a
  greyed-out 29 means. Blanks still carry `column` and `iso_day_of_week`, so a
  surface that tints the جمعه column can tint it in the blank rows too.

  Options:

    * `:today` — the date to flag. Defaults to `Kati.Time.today/0`, the device
      zone's today; pass it explicitly to keep the call pure.

  """
  @spec month(integer(), 1..12, module(), 1..7, keyword()) :: {:ok, grid()} | {:error, term()}
  def month(year, month, calendar, first_day, opts \\ [])
      when month in 1..12 and first_day in 1..7 do
    with {:ok, first_date} <- month_start(calendar, year, month) do
      today = today(opts)
      count = month_length(calendar, year, month)
      lead = lead_blanks(first_date, first_day)
      first_dow = Cldr.Calendar.iso_day_of_week(first_date)

      days =
        for i <- 0..(count - 1) do
          date = Date.add(first_date, i)

          %{
            day: i + 1,
            date: date,
            year: year,
            month: month,
            iso_day_of_week: rem(first_dow - 1 + i, 7) + 1,
            column: rem(lead + i, 7),
            today?: date == today
          }
        end

      cells =
        blanks(0, lead, first_day) ++
          days ++ blanks(lead + count, @rows * @cols - lead - count, first_day)

      {:ok,
       %{
         calendar: calendar,
         year: year,
         month: month,
         first_day_of_week: first_day,
         weekday_order: weekday_order(first_day),
         days_in_month: count,
         lead_blanks: lead,
         first_date: first_date,
         last_date: Date.add(first_date, count - 1),
         rows: Enum.chunk_every(cells, @cols)
       }}
    end
  end

  @doc """
  The seven-day strip containing `anchor`, in column order.

  Every cell is a real day — a strip has no blanks — carrying its calendar
  `{year, month, day}`, its ISO date and its column. A strip that crosses a
  month boundary reports both months, which is the point: مرداد's last week runs
  into شهریور and the strip has to say so.
  """
  @spec day_strip(Date.t(), module(), 1..7, keyword()) :: {:ok, [cell()]} | {:error, term()}
  def day_strip(%Date{} = anchor, calendar, first_day, opts \\ []) when first_day in 1..7 do
    start = week_start(anchor, first_day)
    start_dow = Cldr.Calendar.iso_day_of_week(start)

    with {:ok, first_triple} <- to_calendar_date(calendar, start) do
      today = today(opts)
      triples = walk(calendar, first_triple, @cols)

      cells =
        triples
        |> Enum.with_index()
        |> Enum.map(fn {{y, m, d}, i} ->
          date = Date.add(start, i)

          %{
            day: d,
            date: date,
            year: y,
            month: m,
            iso_day_of_week: rem(start_dow - 1 + i, 7) + 1,
            column: i,
            today?: date == today
          }
        end)

      {:ok, cells}
    end
  end

  @doc """
  The rows × 7 matrix of screens 44 and 60.

  The **row** axis is domain-supplied — `rows` are meal slots, or anything else
  a caller wants down the side — and passes through untouched. The **column**
  axis is this module's: seven day columns in `weekday_order(first_day)` order,
  each cell tagged with its row term and its day so the caller can decorate it
  with state (Planned / Today / Free) without recomputing which day it is.

  The returned `:columns` list is what a test should assert on. If
  `Enum.map(matrix.columns, & &1.iso_day_of_week)` is `[6, 7, 1, 2, 3, 4, 5]`,
  the sequence is right and mirroring is somebody else's mechanism.
  """
  @spec week_matrix(Date.t(), [term()], module(), 1..7, keyword()) ::
          {:ok, matrix()} | {:error, term()}
  def week_matrix(%Date{} = anchor, rows, calendar, first_day, opts \\ []) do
    with {:ok, columns} <- day_strip(anchor, calendar, first_day, opts) do
      {:ok,
       %{
         first_day_of_week: first_day,
         weekday_order: weekday_order(first_day),
         columns: columns,
         rows:
           Enum.map(rows, fn row ->
             %{row: row, cells: Enum.map(columns, &Map.put(&1, :row, row))}
           end)
       }}
    end
  end

  @doc """
  The half-open UTC range `[from, to)` a grid spans, in a named zone.

  Half-open on purpose: an event at 23:59:59.999 on the last day is inside the
  month and an event at 00:00:00 the next day is not, and only a half-open range
  says both without a fencepost. This is the range a query takes — a Jalali
  month is not a Gregorian month and every one of them straddles two, so a
  `{year, month}` pair could not express it at all.
  """
  @spec utc_range(grid(), String.t()) :: {:ok, {DateTime.t(), DateTime.t()}} | {:error, term()}
  def utc_range(%{first_date: first, last_date: last}, zone) do
    with {:ok, from} <- midnight_utc(first, zone),
         {:ok, to} <- midnight_utc(Date.add(last, 1), zone) do
      {:ok, {from, to}}
    end
  end

  defp midnight_utc(date, zone) do
    date |> NaiveDateTime.new!(~T[00:00:00]) |> Kati.Time.to_utc(zone)
  end

  # ── the locale row ───────────────────────────────────────────────────────

  @doc """
  The calendar half of a locale's row: which calendar, which CLDR data, which
  week start.

  Direction is **not** here. It is `Kati.Locale.direction/1`, it is a container
  attribute, and keeping the two apart is the whole point of the split.
  """
  @spec for_locale(atom() | String.t()) :: {:ok, map()} | {:error, term()}
  def for_locale(locale) when is_atom(locale) do
    case Map.fetch(@locale_rows, locale) do
      {:ok, row} ->
        {:ok,
         Map.put(
           row,
           :first_day_of_week,
           Cldr.Calendar.first_day_for_territory(row.week_territory)
         )}

      :error ->
        {:error, {:unknown_locale, locale}}
    end
  end

  def for_locale(locale) when is_binary(locale) do
    case Enum.find(Map.keys(@locale_rows), &(Atom.to_string(&1) == locale)) do
      nil -> {:error, {:unknown_locale, locale}}
      key -> for_locale(key)
    end
  end

  @doc """
  The ISO weekday a locale's week starts on, from CLDR's territory week data.

  `fa` answers 6 (شنبه) and `en` answers 1 (Monday) — the second only because
  Kati's English row names territory `:GB`. Asking CLDR for `:en` directly gives
  **7**, because `:en` resolves to US, and that one character changes every
  calendar screen.
  """
  @spec first_day_of_week(atom() | String.t()) :: {:ok, 1..7} | {:error, term()}
  def first_day_of_week(locale) do
    with {:ok, %{first_day_of_week: day}} <- for_locale(locale), do: {:ok, day}
  end

  @doc "The two functions that perform a calendar conversion; trace them to count."
  @spec calendar_conversions() :: [{module(), atom(), arity()}]
  def calendar_conversions do
    [{Shamsi, :to_gregorian, 3}, {Shamsi, :from_gregorian, 1}]
  end

  # ── labels ───────────────────────────────────────────────────────────────

  @doc """
  Weekday labels for a locale, reordered into column order.

  `weekday_labels(:fa, 6)` is `["ش", "ی", "د", "س", "چ", "پ", "ج"]` — CLDR's
  `stand_alone.narrow` for the Persian calendar, reindexed by
  `weekday_order(6)`. Nothing here is written by hand.

  Options: `:format` (`:narrow` | `:short` | `:abbreviated` | `:wide`, default
  `:narrow`) and `:context` (`:stand_alone` | `:format`, default
  `:stand_alone`).
  """
  @spec weekday_labels(atom() | String.t(), 1..7, keyword()) ::
          {:ok, [String.t()]} | {:error, term()}
  def weekday_labels(locale, first_day, opts \\ []) when first_day in 1..7 do
    with {:ok, by_index} <- label_set(locale, :days, opts, :narrow) do
      {:ok, Enum.map(weekday_order(first_day), &Map.fetch!(by_index, &1))}
    end
  end

  @doc """
  Month names for a locale's calendar, 1..12 in calendar order.

  For `fa` this is فروردین … اسفند from CLDR's Persian data; for `en`, January …
  December. Month order is not affected by the week start, so nothing is
  reordered here.
  """
  @spec month_labels(atom() | String.t(), keyword()) :: {:ok, [String.t()]} | {:error, term()}
  def month_labels(locale, opts \\ []) do
    with {:ok, by_index} <- label_set(locale, :months, opts, :wide) do
      {:ok, Enum.map(1..12, &Map.fetch!(by_index, &1))}
    end
  end

  @doc "One month name, 1-indexed."
  @spec month_label(atom() | String.t(), 1..12, keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def month_label(locale, month, opts \\ []) when month in 1..12 do
    with {:ok, by_index} <- label_set(locale, :months, opts, :wide) do
      {:ok, Map.fetch!(by_index, month)}
    end
  end

  @doc """
  Resolve a written month name to its index — the quick-add lexicon.

  Input is folded (`۲۵` → `25`) and orthographically normalised (ZWNJ removed,
  Arabic yeh and kaf mapped to their Persian forms) before lookup, so a name
  typed on an Arabic keyboard, pasted from a CLDR string, or copied from Kati's
  own literals all resolve to the same index.
  """
  @spec month_from_label(atom() | String.t(), String.t()) :: {:ok, 1..12} | :error
  def month_from_label(locale, label), do: lookup(locale, :months, label)

  @doc """
  Resolve a written weekday name to its ISO index (1 = Monday … 7 = Sunday).

  `"پنجشنبه"` and `"پنج‌شنبه"` both answer `{:ok, 4}`; the two strings differ by
  a zero-width non-joiner and nothing else, and CLDR writes one while Iranian
  keyboards produce the other.

  Ambiguous forms do not resolve: English narrow labels are excluded from the
  index entirely, and any label that would map to two different days is dropped
  rather than guessed at.
  """
  @spec weekday_from_label(atom() | String.t(), String.t()) :: {:ok, 1..7} | :error
  def weekday_from_label(locale, label), do: lookup(locale, :days, label)

  # ── internals ────────────────────────────────────────────────────────────

  defp offset(iso_day_of_week, first_day), do: rem(iso_day_of_week - first_day + 7, 7)

  defp today(opts), do: Keyword.get_lazy(opts, :today, &Kati.Time.today/0)

  defp blanks(_from, count, _first_day) when count <= 0, do: []

  defp blanks(from, count, first_day) do
    order = weekday_order(first_day)

    for i <- from..(from + count - 1) do
      col = rem(i, 7)

      %{
        day: nil,
        date: nil,
        year: nil,
        month: nil,
        iso_day_of_week: Enum.at(order, col),
        column: col,
        today?: false
      }
    end
  end

  defp month_start(Shamsi, year, month), do: Shamsi.to_gregorian(year, month, 1)

  defp month_start(calendar, year, month) do
    with {:ok, date} <- Date.new(year, month, 1, calendar) do
      Date.convert(date, Calendar.ISO)
    end
  end

  defp month_length(Shamsi, year, month), do: Shamsi.days_in_month(year, month)
  defp month_length(calendar, year, month), do: calendar.days_in_month(year, month)

  defp to_calendar_date(Shamsi, %Date{} = date), do: {:ok, Shamsi.from_gregorian(date)}

  defp to_calendar_date(calendar, %Date{} = date) do
    with {:ok, converted} <- Date.convert(date, calendar) do
      {:ok, {converted.year, converted.month, converted.day}}
    end
  end

  # `n` consecutive calendar dates from one conversion. Rolling the day over by
  # arithmetic is what keeps a seven-cell strip at one conversion instead of
  # seven — and `Shamsi.from_gregorian/1` scans the Nowruz table to find the
  # year, so seven of them is not seven times a cheap thing.
  defp walk(calendar, first, n) do
    rest =
      Enum.scan(List.duplicate(nil, n - 1), first, fn _, {y, m, d} ->
        cond do
          d < month_length(calendar, y, m) -> {y, m, d + 1}
          m < 12 -> {y, m + 1, 1}
          true -> {y + 1, 1, 1}
        end
      end)

    [first | rest]
  end

  defp label_set(locale, kind, opts, default_format) do
    format = Keyword.get(opts, :format, default_format)
    context = Keyword.get(opts, :context, :stand_alone)

    with {:ok, row} <- for_locale(locale),
         %{} = data <- cldr_data(kind, row) do
      case get_in(data, [context, format]) do
        %{} = by_index -> {:ok, by_index}
        _ -> {:error, {:unknown_label_set, kind, context, format}}
      end
    else
      {:error, _} = error -> error
      other -> {:error, {:no_cldr_data, kind, other}}
    end
  end

  defp cldr_data(:days, row), do: Kati.Cldr.Calendar.days(row.cldr_locale, row.cldr_calendar)
  defp cldr_data(:months, row), do: Kati.Cldr.Calendar.months(row.cldr_locale, row.cldr_calendar)

  defp lookup(locale, kind, label) when is_binary(label) do
    case Map.fetch(index(locale, kind), normalize(label)) do
      {:ok, value} -> {:ok, value}
      :error -> :error
    end
  end

  # Built from every unambiguous label set CLDR offers, both contexts. A key
  # that two different indices claim is removed, not resolved: "T" meaning
  # Tuesday-or-Thursday is not a parse, it is a coin toss.
  #
  # Rebuilt per lookup — six small maps of at most twelve entries each. That is
  # a parser-time cost paid once per typed line, not a render-time cost paid per
  # cell, so it is deliberately not cached: a cache here would be a second copy
  # of CLDR data that could go stale against the first.
  defp index(locale, kind) do
    for context <- @label_contexts,
        format <- @reversible_formats,
        {:ok, by_index} <- [label_set(locale, kind, [context: context, format: format], format)],
        {index, label} <- by_index,
        reduce: %{} do
      acc ->
        key = normalize(label)

        case Map.fetch(acc, key) do
          {:ok, ^index} -> acc
          {:ok, _other} -> Map.put(acc, key, :ambiguous)
          :error -> Map.put(acc, key, index)
        end
    end
    |> Map.reject(fn {_k, v} -> v == :ambiguous end)
  end

  defp normalize(text) do
    text
    |> Digits.fold()
    |> String.replace(Map.keys(@orthography), &Map.fetch!(@orthography, &1))
    |> String.trim()
    |> String.downcase()
  end
end
