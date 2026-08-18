defmodule Kati.Recurrence.Rule do
  @moduledoc """
  An RFC 5545 RECUR value.

  Parses every rule part, including ones Kati's own editor cannot author
  (`BYWEEKNO`, `BYYEARDAY`, `BYSECOND`), because they arrive from mirrored
  calendars and a rule Kati cannot represent is a rule Kati would silently
  corrupt on write-back.

  ## Two invariants the RFC states and interop punishes

    * **`FREQ` is emitted first.** §3.3.10: *"Compliant applications MUST accept
      rule parts ordered in any sequence, but to ensure backward compatibility …
      the FREQ rule part MUST be the first rule part specified in a RECUR
      value."* So parsing is order-insensitive; serialising is not.
    * **`UNTIL`'s value type must match `DTSTART`'s.** An all-day rule takes
      `UNTIL=20261231`; a timed one takes `UNTIL=20261231T170000Z`. Mixing them
      is the most common interop failure with Google and iCloud, so `until` is
      stored as a `Date` or a `DateTime` and the type is carried, not guessed at
      serialise time.

  `UNTIL` and `COUNT` are mutually exclusive; `parse/1` rejects a value carrying
  both rather than silently preferring one.
  """

  @type freq :: :secondly | :minutely | :hourly | :daily | :weekly | :monthly | :yearly
  @type weekday :: :mo | :tu | :we | :th | :fr | :sa | :su
  @type byday :: {integer() | nil, weekday()}

  @type t :: %__MODULE__{
          freq: freq(),
          interval: pos_integer(),
          count: pos_integer() | nil,
          until: Date.t() | DateTime.t() | nil,
          by_second: [0..60],
          by_minute: [0..59],
          by_hour: [0..23],
          by_day: [byday()],
          by_monthday: [integer()],
          by_yearday: [integer()],
          by_weekno: [integer()],
          by_month: [1..12],
          by_setpos: [integer()],
          wkst: weekday()
        }

  defstruct freq: nil,
            interval: 1,
            count: nil,
            until: nil,
            by_second: [],
            by_minute: [],
            by_hour: [],
            by_day: [],
            by_monthday: [],
            by_yearday: [],
            by_weekno: [],
            by_month: [],
            by_setpos: [],
            # RFC default is MO. Deliberately NOT the current locale: a rule
            # authored in fa must keep its WKST even if the UI later switches to
            # en, or a fortnightly event silently moves.
            wkst: :mo

  @freqs %{
    "SECONDLY" => :secondly,
    "MINUTELY" => :minutely,
    "HOURLY" => :hourly,
    "DAILY" => :daily,
    "WEEKLY" => :weekly,
    "MONTHLY" => :monthly,
    "YEARLY" => :yearly
  }

  @days %{
    "MO" => :mo,
    "TU" => :tu,
    "WE" => :we,
    "TH" => :th,
    "FR" => :fr,
    "SA" => :sa,
    "SU" => :su
  }
  @day_names Map.new(@days, fn {k, v} -> {v, k} end)

  @doc "Parse a RECUR value such as `FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,SU;WKST=MO`."
  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(value) when is_binary(value) do
    parts =
      value
      |> String.trim()
      |> String.split(";", trim: true)
      |> Enum.map(fn part ->
        case String.split(part, "=", parts: 2) do
          [k, v] -> {String.upcase(k), v}
          _ -> {:invalid, part}
        end
      end)

    with :ok <- no_invalid_parts(parts),
         {:ok, rule} <- Enum.reduce_while(parts, {:ok, %__MODULE__{}}, &apply_part/2),
         :ok <- require_freq(rule),
         :ok <- exclusive_until_count(rule) do
      {:ok, rule}
    end
  end

  defp no_invalid_parts(parts) do
    case Enum.find(parts, &match?({:invalid, _}, &1)) do
      nil -> :ok
      {:invalid, part} -> {:error, {:malformed_rule_part, part}}
    end
  end

  defp require_freq(%{freq: nil}), do: {:error, :missing_freq}
  defp require_freq(_), do: :ok

  # "The UNTIL or COUNT rule parts are OPTIONAL, but they MUST NOT occur in the
  # same 'recur'." Rejected rather than silently preferring one.
  defp exclusive_until_count(%{until: u, count: c}) when not is_nil(u) and not is_nil(c),
    do: {:error, :until_and_count}

  defp exclusive_until_count(_), do: :ok

  defp apply_part({"FREQ", v}, {:ok, r}) do
    case Map.fetch(@freqs, String.upcase(v)) do
      {:ok, f} -> {:cont, {:ok, %{r | freq: f}}}
      :error -> {:halt, {:error, {:bad_freq, v}}}
    end
  end

  defp apply_part({"INTERVAL", v}, {:ok, r}), do: int_part(v, r, :interval, &(&1 > 0))
  defp apply_part({"COUNT", v}, {:ok, r}), do: int_part(v, r, :count, &(&1 > 0))

  defp apply_part({"UNTIL", v}, {:ok, r}) do
    case parse_until(v) do
      {:ok, u} -> {:cont, {:ok, %{r | until: u}}}
      :error -> {:halt, {:error, {:bad_until, v}}}
    end
  end

  defp apply_part({"WKST", v}, {:ok, r}) do
    case Map.fetch(@days, String.upcase(v)) do
      {:ok, d} -> {:cont, {:ok, %{r | wkst: d}}}
      :error -> {:halt, {:error, {:bad_wkst, v}}}
    end
  end

  defp apply_part({"BYDAY", v}, {:ok, r}) do
    case parse_byday(v) do
      {:ok, list} -> {:cont, {:ok, %{r | by_day: list}}}
      :error -> {:halt, {:error, {:bad_byday, v}}}
    end
  end

  defp apply_part({"BYSECOND", v}, {:ok, r}), do: int_list(v, r, :by_second, &(&1 in 0..60))
  defp apply_part({"BYMINUTE", v}, {:ok, r}), do: int_list(v, r, :by_minute, &(&1 in 0..59))
  defp apply_part({"BYHOUR", v}, {:ok, r}), do: int_list(v, r, :by_hour, &(&1 in 0..23))
  defp apply_part({"BYMONTH", v}, {:ok, r}), do: int_list(v, r, :by_month, &(&1 in 1..12))

  defp apply_part({"BYMONTHDAY", v}, {:ok, r}),
    do: int_list(v, r, :by_monthday, &(&1 in -31..-1 or &1 in 1..31))

  defp apply_part({"BYYEARDAY", v}, {:ok, r}),
    do: int_list(v, r, :by_yearday, &(&1 in -366..-1 or &1 in 1..366))

  defp apply_part({"BYWEEKNO", v}, {:ok, r}),
    do: int_list(v, r, :by_weekno, &(&1 in -53..-1 or &1 in 1..53))

  defp apply_part({"BYSETPOS", v}, {:ok, r}),
    do: int_list(v, r, :by_setpos, &(&1 != 0))

  # Unknown parts are ignored rather than fatal: the RFC allows x-name
  # extensions, and a mirrored calendar carrying one should still sync.
  defp apply_part({_other, _v}, acc), do: {:cont, acc}

  defp int_part(v, r, key, valid?) do
    case Integer.parse(v) do
      {n, ""} ->
        if valid?.(n), do: {:cont, {:ok, Map.put(r, key, n)}}, else: {:halt, {:error, {key, v}}}

      _ ->
        {:halt, {:error, {key, v}}}
    end
  end

  defp int_list(v, r, key, valid?) do
    parsed =
      v
      |> String.split(",", trim: true)
      |> Enum.map(&Integer.parse/1)

    if Enum.all?(parsed, &match?({_, ""}, &1)) do
      nums = Enum.map(parsed, &elem(&1, 0))

      if Enum.all?(nums, valid?),
        do: {:cont, {:ok, Map.put(r, key, nums)}},
        else: {:halt, {:error, {key, v}}}
    else
      {:halt, {:error, {key, v}}}
    end
  end

  defp parse_byday(v) do
    v
    |> String.split(",", trim: true)
    |> Enum.reduce_while({:ok, []}, fn token, {:ok, acc} ->
      case Regex.run(~r/^([+-]?\d{1,3})?(MO|TU|WE|TH|FR|SA|SU)$/i, String.upcase(token)) do
        [_, "", day] -> {:cont, {:ok, acc ++ [{nil, @days[day]}]}}
        [_, day] -> {:cont, {:ok, acc ++ [{nil, @days[day]}]}}
        [_, n, day] -> {:cont, {:ok, acc ++ [{String.to_integer(n), @days[day]}]}}
        _ -> {:halt, :error}
      end
    end)
  end

  defp parse_until(v) do
    cond do
      Regex.match?(~r/^\d{8}T\d{6}Z$/, v) ->
        <<y::binary-4, m::binary-2, d::binary-2, "T", h::binary-2, mi::binary-2, s::binary-2,
          "Z">> = v

        with {:ok, naive} <-
               NaiveDateTime.new(
                 String.to_integer(y),
                 String.to_integer(m),
                 String.to_integer(d),
                 String.to_integer(h),
                 String.to_integer(mi),
                 String.to_integer(s)
               ) do
          {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
        else
          _ -> :error
        end

      Regex.match?(~r/^\d{8}$/, v) ->
        <<y::binary-4, m::binary-2, d::binary-2>> = v

        case Date.new(String.to_integer(y), String.to_integer(m), String.to_integer(d)) do
          {:ok, date} -> {:ok, date}
          _ -> :error
        end

      true ->
        :error
    end
  end

  @doc """
  Serialise back to a RECUR value, with `FREQ` first as the RFC requires.

  Round-trips `parse/1` modulo rule-part ordering.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = r) do
    freq = String.upcase(Atom.to_string(r.freq))

    rest =
      [
        part("INTERVAL", r.interval != 1 && r.interval),
        part("COUNT", r.count),
        part("UNTIL", r.until && format_until(r.until)),
        part("BYSECOND", list(r.by_second)),
        part("BYMINUTE", list(r.by_minute)),
        part("BYHOUR", list(r.by_hour)),
        part("BYDAY", byday_list(r.by_day)),
        part("BYMONTHDAY", list(r.by_monthday)),
        part("BYYEARDAY", list(r.by_yearday)),
        part("BYWEEKNO", list(r.by_weekno)),
        part("BYMONTH", list(r.by_month)),
        part("BYSETPOS", list(r.by_setpos)),
        part("WKST", r.wkst != :mo && String.upcase(Atom.to_string(r.wkst)))
      ]
      |> Enum.reject(&is_nil/1)

    Enum.join(["FREQ=#{freq}" | rest], ";")
  end

  defp part(_k, nil), do: nil
  defp part(_k, false), do: nil
  defp part(_k, ""), do: nil
  defp part(k, v), do: "#{k}=#{v}"

  defp list([]), do: nil
  defp list(nums), do: Enum.join(nums, ",")

  defp byday_list([]), do: nil

  defp byday_list(days) do
    Enum.map_join(days, ",", fn
      {nil, d} -> @day_names[d]
      {n, d} -> "#{n}#{@day_names[d]}"
    end)
  end

  defp format_until(%Date{} = d), do: Calendar.strftime(d, "%Y%m%d")
  defp format_until(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y%m%dT%H%M%SZ")

  @doc "The weekday atom for a date, matching the `BYDAY` vocabulary."
  @spec weekday(Date.t()) :: weekday()
  def weekday(date) do
    elem({:mo, :tu, :we, :th, :fr, :sa, :su}, Date.day_of_week(date) - 1)
  end

  @doc "1..7 index of a weekday atom in a week starting at `wkst`."
  @spec day_index(weekday(), weekday()) :: 1..7
  def day_index(day, wkst) do
    order = [:mo, :tu, :we, :th, :fr, :sa, :su]
    start = Enum.find_index(order, &(&1 == wkst))
    idx = Enum.find_index(order, &(&1 == day))
    rem(idx - start + 7, 7) + 1
  end
end
