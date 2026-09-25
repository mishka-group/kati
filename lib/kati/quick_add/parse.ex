defmodule Kati.QuickAdd.Parse do
  @moduledoc """
  One typed sentence, read.

  Screen 18's whole idea, in its own caption: *One field for the whole app.
  Parsed tokens are highlighted in place so you can see what it understood
  before committing.* The screen had the field, the highlighting and the
  understanding drawn and none of them built, so what
  it showed was one sentence somebody had typed into a design tool.

  ## What it reads, and what it deliberately does not

  Four kinds of token, which are the four board 18 highlights:

    * **When.** `thu`, `thursday`, `today`, `tomorrow`, `20 aug`, `20/08`.
      A weekday means the NEXT one — `thu` typed on a Thursday is a week away,
      because somebody adding a dentist appointment on the day would have said
      `today`.
    * **At.** `11am`, `7pm`, `19:30`, `11.30am`, `noon`, `midnight`.
    * **For.** `for 45m`, `for 1h`, `for 1h30`, `for an hour`.
    * **Remind.** `remind 1h before`, `remind me 10 minutes before`.

  Everything no token claimed is the **title**, in the order it was typed and
  with the gaps closed up. That is the rule that makes the field usable: a
  person types what the thing is and when, in either order, and never learns a
  syntax.

  What it does not do is guess. A sentence with no time is an all-day event on
  the day it names; a sentence with no day has no date at all, and
  `committable?/1` refuses it — *dentist* on no particular day is not
  something a calendar can hold. Kati says what it read and lets the person
  fix it, which is what the *Kati read that as* card is for.

  ## Case, and why the title keeps its own

  The sentence is matched case-insensitively and the title comes back as typed
  with a capital at the front, which is what board 18 draws: `dentist` in the
  field, `Dentist` on the card. Anything more — title case, smart capitals for
  names — is a guess about somebody's own words.
  """

  @weekdays %{
    "mon" => 1,
    "monday" => 1,
    "tue" => 2,
    "tues" => 2,
    "tuesday" => 2,
    "wed" => 3,
    "weds" => 3,
    "wednesday" => 3,
    "thu" => 4,
    "thur" => 4,
    "thurs" => 4,
    "thursday" => 4,
    "fri" => 5,
    "friday" => 5,
    "sat" => 6,
    "saturday" => 6,
    "sun" => 7,
    "sunday" => 7
  }

  @months %{
    "jan" => 1,
    "feb" => 2,
    "mar" => 3,
    "apr" => 4,
    "may" => 5,
    "jun" => 6,
    "jul" => 7,
    "aug" => 8,
    "sep" => 9,
    "sept" => 9,
    "oct" => 10,
    "nov" => 11,
    "dec" => 12
  }

  @typedoc """
  What one sentence said. `spans` is every token's `{start, length}` in the
  original string, which is what the field highlights in place.
  """
  @type t :: %{
          title: String.t() | nil,
          date: Date.t() | nil,
          time: Time.t() | nil,
          minutes: pos_integer() | nil,
          remind: pos_integer() | nil,
          spans: [{non_neg_integer(), pos_integer()}]
        }

  @doc """
  Read a sentence, against a day.

  `today` is passed in rather than read, because a parser that asks the clock
  cannot be tested against a fixed Thursday — `Kati.ScreenDateTest`'s rule for
  every screen in this app, and this is where its dates come from.

      iex> read = Kati.QuickAdd.Parse.read("dentist thu 11am for 45m", ~D[2026-08-17])
      iex> {read.title, read.date, read.time, read.minutes}
      {"Dentist", ~D[2026-08-20], ~T[11:00:00], 45}

      iex> read = Kati.QuickAdd.Parse.read("coffee with Jo tomorrow 9am", ~D[2026-08-17])
      iex> {read.title, read.date, read.time}
      {"Coffee with Jo", ~D[2026-08-18], ~T[09:00:00]}

      iex> read = Kati.QuickAdd.Parse.read("standup", ~D[2026-08-17])
      iex> {read.title, read.date, read.spans}
      {"Standup", nil, []}
  """
  @spec read(String.t(), Date.t()) :: t()
  def read(sentence, today) when is_binary(sentence) do
    found =
      [
        remind(sentence),
        duration(sentence),
        clock(sentence),
        day(sentence, today)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(& &1.span)

    %{
      title: title(sentence, found),
      date: pick(found, :date),
      time: pick(found, :time),
      minutes: pick(found, :minutes),
      remind: pick(found, :remind),
      spans: Enum.map(found, & &1.span)
    }
  end

  @doc """
  Whether this is enough to put on a calendar.

  A title and a day. Not a time — an all-day event is a real thing and board
  18's own *Add to Thursday* promises no hour — but never a time with no day,
  which is a claim about an afternoon nobody named.

      iex> Kati.QuickAdd.Parse.committable?(%{title: "Dentist", date: ~D[2026-08-20]})
      true

      iex> Kati.QuickAdd.Parse.committable?(%{title: "Dentist", date: nil})
      false

      iex> Kati.QuickAdd.Parse.committable?(%{title: nil, date: ~D[2026-08-20]})
      false
  """
  @spec committable?(map()) :: boolean()
  def committable?(%{title: title, date: %Date{}}) when is_binary(title) and title != "", do: true
  def committable?(_read), do: false

  # ── the four tokens ───────────────────────────────────────────────────────

  defp day(sentence, today) do
    named(sentence, ~r/\btoday\b/i, fn _m -> today end) ||
      named(sentence, ~r/\btomorrow\b/i, fn _m -> Date.add(today, 1) end) ||
      dated(sentence, today) ||
      weekday(sentence, today)
  end

  defp weekday(sentence, today) do
    names = @weekdays |> Map.keys() |> Enum.sort_by(&(-String.length(&1))) |> Enum.join("|")

    named(sentence, Regex.compile!("\\b(#{names})\\b", "i"), fn [_all, name] ->
      next_weekday(today, Map.fetch!(@weekdays, String.downcase(name)))
    end)
  end

  defp dated(sentence, today) do
    months = @months |> Map.keys() |> Enum.sort_by(&(-String.length(&1))) |> Enum.join("|")

    named(sentence, Regex.compile!("\\b(\\d{1,2})\\s+(#{months})[a-z]*\\b", "i"), fn [_a, d, m] ->
      on(today, String.to_integer(d), Map.fetch!(@months, String.downcase(m)))
    end) ||
      named(sentence, Regex.compile!("\\b(#{months})[a-z]*\\s+(\\d{1,2})\\b", "i"), fn [_a, m, d] ->
        on(today, String.to_integer(d), Map.fetch!(@months, String.downcase(m)))
      end) ||
      named(sentence, Regex.compile!("\\b(\\d{1,2})[/-](\\d{1,2})\\b"), fn [_a, d, m] ->
        on(today, String.to_integer(d), String.to_integer(m))
      end)
  end

  defp clock(sentence) do
    named(sentence, ~r/\bnoon\b/i, fn _m -> ~T[12:00:00] end, :time) ||
      named(sentence, ~r/\bmidnight\b/i, fn _m -> ~T[00:00:00] end, :time) ||
      named(sentence, ~r/\b(\d{1,2})[:.](\d{2})\s*(am|pm)?\b/i, &wall/1, :time) ||
      named(sentence, ~r/\b(\d{1,2})\s*(am|pm)\b/i, &oclock/1, :time)
  end

  defp duration(sentence) do
    named(
      sentence,
      ~r/\bfor\s+(\d{1,2})\s*h\s*(\d{1,2})\b/i,
      fn [_a, h, m] -> String.to_integer(h) * 60 + String.to_integer(m) end,
      :minutes
    ) ||
      named(
        sentence,
        ~r/\bfor\s+(\d{1,3})\s*(h|hr|hrs|hour|hours)\b/i,
        fn [_a, h, _u] -> String.to_integer(h) * 60 end,
        :minutes
      ) ||
      named(
        sentence,
        ~r/\bfor\s+(\d{1,3})\s*(m|min|mins|minute|minutes)\b/i,
        fn [_a, m, _u] -> String.to_integer(m) end,
        :minutes
      ) ||
      named(sentence, ~r/\bfor\s+an\s+hour\b/i, fn _m -> 60 end, :minutes)
  end

  defp remind(sentence) do
    named(
      sentence,
      ~r/\bremind(?:\s+me)?\s+(\d{1,3})\s*(h|hr|hrs|hour|hours)\s+before\b/i,
      fn [_a, h, _u] -> String.to_integer(h) * 60 end,
      :remind
    ) ||
      named(
        sentence,
        ~r/\bremind(?:\s+me)?\s+(\d{1,3})\s*(m|min|mins|minute|minutes)\s+before\b/i,
        fn [_a, m, _u] -> String.to_integer(m) end,
        :remind
      )
  end

  # ── the shared shape ──────────────────────────────────────────────────────

  defp named(sentence, pattern, build, key \\ :date) do
    case Regex.run(pattern, sentence, return: :index) do
      nil ->
        nil

      [{at, len} | _rest] = indexes ->
        captures =
          Enum.map(indexes, fn
            {-1, _len} -> nil
            {s, l} -> binary_part(sentence, s, l)
          end)

        case build.(captures) do
          nil -> nil
          value -> %{span: {at, len}, key: key, value: value}
        end
    end
  end

  defp pick(found, key) do
    Enum.find_value(found, fn token -> if token.key == key, do: token.value end)
  end

  # The words no token claimed, in the order they were typed, with the gaps
  # closed up — so `dentist thu 11am for 45m` is `Dentist` and not `dentist
  # for`. The leading capital is board 18's own: `dentist` in the field,
  # `Dentist` on the card.
  defp title(sentence, found) do
    found
    |> Enum.map(& &1.span)
    |> Enum.sort_by(&elem(&1, 0), :desc)
    |> Enum.reduce(sentence, fn {at, len}, acc ->
      binary_part(acc, 0, at) <> binary_part(acc, at + len, byte_size(acc) - at - len)
    end)
    |> String.replace(~r/\s*,\s*/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> case do
      "" -> nil
      words -> String.capitalize(String.first(words)) <> String.slice(words, 1..-1//1)
    end
  end

  defp next_weekday(today, weekday) do
    ahead = Integer.mod(weekday - Date.day_of_week(today), 7)
    Date.add(today, if(ahead == 0, do: 7, else: ahead))
  end

  # A day and a month with no year is the next one to come round, which is what
  # somebody typing `20 aug` in September means.
  defp on(today, day, month) do
    case Date.new(today.year, month, day) do
      {:ok, date} ->
        if Date.compare(date, today) == :lt,
          do: Date.new!(today.year + 1, month, day),
          else: date

      _invalid ->
        nil
    end
  end

  defp wall([_all, hour, minute | rest]) do
    time(String.to_integer(hour), String.to_integer(minute), List.first(rest))
  end

  defp oclock([_all, hour, meridiem]), do: time(String.to_integer(hour), 0, meridiem)

  defp time(hour, minute, meridiem) do
    hour = shift(hour, meridiem && String.downcase(meridiem))

    case Time.new(hour, minute, 0) do
      {:ok, time} -> time
      _invalid -> nil
    end
  end

  defp shift(12, "am"), do: 0
  defp shift(hour, "pm") when hour < 12, do: hour + 12
  defp shift(hour, _none), do: hour
end
