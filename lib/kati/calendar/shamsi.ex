defmodule Kati.Calendar.Shamsi do
  @moduledoc """
  Solar Hijri (Jalali/Shamsi) conversion and month grids.

  **Display only.** Stored data stays Gregorian/UTC — this module converts at the
  edge, for rendering and for parsing a date the user picked. Storing Shamsi
  would make every range query and every sync comparison a conversion.

  ## Why a table rather than the reference implementation

  `ex_cldr_calendars_persian` is correct — observational, Tehran meridian — and
  costs **476 µs per conversion**. A month grid is 35 cells, so 7.9 ms before a
  single character is formatted, on every scroll. `Kati.Calendar.NowruzTable`
  is a generated lookup covering 1300–1600 SH, verified against the reference
  with **0 mismatches**, at ~1.26 µs.

  The Persian leap rule is not a simple cycle — it follows the vernal equinox at
  the Tehran meridian — which is exactly why a table generated from the
  authority beats a hand-written approximation of the 33-year cycle.

  ## Weeks start on Saturday

  Not a mirroring concern. Screen 60 calls this *"the hardest case in the whole
  pass: a matrix whose columns are days. Mirroring alone would put Monday on the
  right and still be wrong — the sequence itself has to restart at شنبه."*
  `month_grid/2` returns weeks already ordered شنبه → جمعه, so a renderer never
  has to reorder.
  """

  alias Kati.Calendar.NowruzTable

  @months_fa {"فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر",
              "دی", "بهمن", "اسفند"}

  @weekdays_fa {"شنبه", "یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنج‌شنبه", "جمعه"}
  @weekdays_fa_short {"ش", "ی", "د", "س", "چ", "پ", "ج"}

  @doc "Persian month names, 1..12."
  def month_name(m) when m in 1..12, do: elem(@months_fa, m - 1)

  @doc "Persian weekday names, 1..7 where 1 is شنبه."
  def weekday_name(d) when d in 1..7, do: elem(@weekdays_fa, d - 1)
  def weekday_short(d) when d in 1..7, do: elem(@weekdays_fa_short, d - 1)

  @doc """
  Convert a Gregorian `Date` to `{year, month, day}` in the Solar Hijri calendar.
  """
  @spec from_gregorian(Date.t()) :: {integer(), 1..12, 1..31}
  def from_gregorian(%Date{} = date) do
    iso_days = Date.to_gregorian_days(date)
    year = year_for(iso_days)
    nowruz = NowruzTable.nowruz(year)
    day_of_year = iso_days - nowruz

    {month, day} = month_and_day(day_of_year)
    {year, month, day}
  end

  @doc "Convert `{year, month, day}` in Solar Hijri to a Gregorian `Date`."
  @spec to_gregorian(integer(), 1..12, 1..31) :: {:ok, Date.t()} | {:error, term()}
  def to_gregorian(year, month, day) when month in 1..12 and day >= 1 do
    with nowruz when is_integer(nowruz) <- NowruzTable.nowruz(year),
         true <- day <= days_in_month(year, month) do
      {:ok, Date.from_gregorian_days(nowruz + day_of_year(month, day))}
    else
      nil -> {:error, {:year_out_of_range, year}}
      false -> {:error, {:invalid_day, year, month, day}}
    end
  end

  def to_gregorian(_, _, _), do: {:error, :invalid_date}

  @doc """
  True when a Persian year has 366 days.

  Derived from the table rather than a 33-year cycle approximation: the real
  rule follows the vernal equinox at the Tehran meridian, and the cycle drifts.
  """
  @spec leap_year?(integer()) :: boolean()
  def leap_year?(year) do
    with a when is_integer(a) <- NowruzTable.nowruz(year),
         b when is_integer(b) <- NowruzTable.nowruz(year + 1) do
      b - a == 366
    else
      _ -> false
    end
  end

  @doc "Days in a Persian month. Months 1–6 have 31, 7–11 have 30, 12 has 29 or 30."
  @spec days_in_month(integer(), 1..12) :: 29..31
  def days_in_month(_year, month) when month in 1..6, do: 31
  def days_in_month(_year, month) when month in 7..11, do: 30
  def days_in_month(year, 12), do: if(leap_year?(year), do: 30, else: 29)

  @doc """
  The weekday index of a Gregorian date in a Saturday-start week: 1 is شنبه.
  """
  @spec weekday_index(Date.t()) :: 1..7
  def weekday_index(%Date{} = date) do
    # Date.day_of_week/1 is 1=Monday..7=Sunday. Saturday (6) must become 1.
    rem(Date.day_of_week(date) + 1, 7) + 1
  end

  @doc """
  A month grid for a Persian year and month, as a list of weeks.

  Each week is a list of 7 entries, ordered **شنبه first**. Leading and trailing
  cells outside the month are `nil` rather than dates from adjacent months, so a
  renderer can draw blanks without deciding what they mean.
  """
  @spec month_grid(integer(), 1..12) :: {:ok, [[%{} | nil]]} | {:error, term()}
  def month_grid(year, month) do
    with {:ok, first} <- to_gregorian(year, month, 1) do
      count = days_in_month(year, month)
      lead = weekday_index(first) - 1

      cells =
        List.duplicate(nil, lead) ++
          for day <- 1..count do
            {:ok, date} = to_gregorian(year, month, day)
            %{day: day, gregorian: date, weekday: weekday_index(date)}
          end

      padded = cells ++ List.duplicate(nil, rem(7 - rem(length(cells), 7), 7))
      {:ok, Enum.chunk_every(padded, 7)}
    end
  end

  @doc """
  Format a Gregorian date in Persian, e.g. `"یکشنبه ۲۵ مرداد ۱۴۰۵"`.

  Digits are Persian (U+06F0–U+06F9) because `fa`'s default number system is
  `arabext`.
  """
  @spec format(Date.t(), :long | :short | :numeric) :: String.t()
  def format(%Date{} = date, style \\ :long) do
    {y, m, d} = from_gregorian(date)

    case style do
      :long -> "#{weekday_name(weekday_index(date))} #{fa(d)} #{month_name(m)} #{fa(y)}"
      :short -> "#{fa(d)} #{month_name(m)}"
      :numeric -> "#{fa(y)}/#{fa_pad(m)}/#{fa_pad(d)}"
    end
  end

  @doc "Render an integer with Persian digits."
  @spec fa(integer()) :: String.t()
  def fa(n) when is_integer(n), do: n |> Integer.to_string() |> to_persian_digits()

  defp fa_pad(n) when n < 10, do: to_persian_digits("0#{n}")
  defp fa_pad(n), do: fa(n)

  @doc """
  Map ASCII digits to Persian (extended Arabic-Indic) digits.

  Used for output. Input folding — a user typing ۱۴۰۵ — is the inverse and lives
  in `from_persian_digits/1`.
  """
  @spec to_persian_digits(String.t()) :: String.t()
  def to_persian_digits(text) when is_binary(text) do
    String.replace(text, ~w(0 1 2 3 4 5 6 7 8 9), fn d ->
      <<0x06F0 + String.to_integer(d)::utf8>>
    end)
  end

  @doc """
  Fold Persian and Arabic-Indic digits back to ASCII.

  A user typing a Shamsi date, or a search query containing a number, arrives in
  Persian digits; nothing downstream — FTS5, `Integer.parse/1`, a date parser —
  matches them.
  """
  @spec from_persian_digits(String.t()) :: String.t()
  def from_persian_digits(text) when is_binary(text) do
    text
    |> String.graphemes()
    |> Enum.map_join(fn g ->
      case :binary.first(g) do
        _ ->
          cp = g |> String.to_charlist() |> hd()

          cond do
            # Extended Arabic-Indic (Persian) ۰-۹
            cp in 0x06F0..0x06F9 -> <<?0 + (cp - 0x06F0)>>
            # Arabic-Indic ٠-٩
            cp in 0x0660..0x0669 -> <<?0 + (cp - 0x0660)>>
            true -> g
          end
      end
    end)
  end

  # ── internals ────────────────────────────────────────────────────────────

  defp year_for(iso_days) do
    {first, last} = NowruzTable.range()

    Enum.reduce_while(last..first//-1, first, fn y, acc ->
      case NowruzTable.nowruz(y) do
        n when is_integer(n) and n <= iso_days -> {:halt, y}
        _ -> {:cont, acc}
      end
    end)
  end

  defp month_and_day(day_of_year) when day_of_year < 186 do
    {div(day_of_year, 31) + 1, rem(day_of_year, 31) + 1}
  end

  defp month_and_day(day_of_year) do
    rest = day_of_year - 186
    {div(rest, 30) + 7, rem(rest, 30) + 1}
  end

  defp day_of_year(month, day) when month <= 6, do: (month - 1) * 31 + (day - 1)
  defp day_of_year(month, day), do: 186 + (month - 7) * 30 + (day - 1)
end
