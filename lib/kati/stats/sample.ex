defmodule Kati.Stats.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in figures for the stats screens, until the domains that would produce
  them exist. Same rule as `Kati.Library.Sample`: named as a stand-in, shaped
  like the real thing.
  """

  @doc "Screen 07's year summary."
  @spec year() :: map()
  # The day both boards were captured on: 12 August 2026 is 21 Mordad 1405, so
  # one date gives board 07 its `Jan – Aug 2026` and board 61 its
  # فروردین تا مرداد ۱۴۰۵. The header was two frozen strings, which is how a
  # transcription of the same header in two scripts ends up disagreeing about
  # which year it is.
  @captured ~D[2026-08-12]

  def year do
    %{
      range: Kati.Screens.Stats.range(@captured),
      time: hours(312 * 60 + 40),
      change: gettext("%{n}%", n: Kati.Locale.number(18)),
      weeks: 26,
      streak:
        ngettext("longest streak — %{n} night", "longest streak — %{n} nights", 11,
          n: Kati.Locale.number(11)
        ),
      counts: [
        {Kati.Locale.number(84), gettext("Films")},
        {Kati.Locale.number(19), gettext("Series")},
        {Kati.Locale.number("4.1"), gettext("Avg ★")}
      ],
      breakdown: [
        {gettext("Drama"), 0.82, bar_hours(128), 0xFF1A1917},
        {gettext("Documentary"), 0.54, bar_hours(71), 0xFF4E9A73},
        {gettext("Comedy"), 0.38, bar_hours(49), 0xFFE8823C},
        {gettext("Thriller"), 0.29, bar_hours(38), 0xFFB08E55},
        {gettext("Everything else"), 0.19, bar_hours(26), 0xFFC4BDB3}
      ]
    }
  end

  defp hours(minutes) do
    gettext("%{h}h %{m}m",
      h: Kati.Locale.number(div(minutes, 60)),
      m: Kati.Locale.number(rem(minutes, 60))
    )
  end

  defp bar_hours(h), do: gettext("%{n}h", n: Kati.Locale.number(h))

  @doc """
  The week board 61 draws under *این هفته*, over the day both boards were
  captured on.

  Seven `{date, count}` pairs starting at that week's own first day, so the
  axis under them runs **M T W T F S S** in English and **ش ی د س چ پ ج** in
  Persian off one list — `Kati.Screens.Stats.week_start_on/1` is what differs,
  not the data.

  It replaces `Kati.Fa.SampleYear.week/0`, which was seven bar heights in
  points with one of them flagged lit — a chart with no dates behind it, and so
  no way for a device ever to draw a different week. MOVIES-AND-TV.md #45 over
  a whole card; `Kati.Screens.Stats.this_week/1` is the reader.
  """
  @spec week() :: [{Date.t(), non_neg_integer()}]
  def week do
    start = Kati.Screens.Stats.week_start_on(@captured)

    [2, 1, 0, 3, 1, 2, 1]
    |> Enum.with_index()
    |> Enum.map(fn {count, offset} -> {Date.add(start, offset), count} end)
  end

  @doc "Screen 07's More numbers list."
  @spec more_numbers() :: [map()]
  def more_numbers do
    [
      # `id` as well as `title`, for `Kati.Settings.Sample`'s reason: screen 07
      # keyed its destination table on the drawn title, built each tap tag as
      # `String.to_atom("go_" <> title)` — `:"go_Activity log"` — and decided
      # which rows get a counted second line by matching the same word.
      # mishka-group/kati#103's recurring defect, three times on one card.
      %{id: :activity, icon: "history", title: gettext("Activity log"), sub: "1,204 entries"},
      %{id: :habits, icon: "bolt", title: gettext("Habits"), sub: "4 active · 12-day best"},
      %{id: :nutrition, icon: "nutrition", title: gettext("Nutrition"), sub: "Cutting v3 · 86%"},
      # Goals joined this list with screen 104, and Subscriptions became Money:
      # screen 122 is the wider page — the same four services plus the one-off
      # expenses quick-add writes — and screen 23 is still one tap further in.
      %{id: :goals, icon: "checklist", title: gettext("Goals"), sub: "3 active · 38 of 52 books"},
      %{
        id: :money,
        icon: "payments",
        title: gettext("Money"),
        sub: "£46.47 a month · 7 expenses"
      },
      # Board 61's third row, and the one the English board does not draw. It
      # was `Kati.Screens.StatsFa`'s own, for a reason that was true while the
      # mirror stood: the Persian shell's four roots are Home, Calendar, Library
      # and Stats, and none of them is a Health hub the way English's screen 42
      # is — so this row was Persian's only route to a weight page.
      #
      # It survives the fold rather than going with the mirror. Weight IS a
      # number, this IS the numbers card, and `Kati.Screens.Stats.weight_line/0`
      # has read the real reading since the row was built; the alternative was
      # deleting a live reader and a working door. `monitor_weight` is screen
      # 110's own glyph for the same page. mishka-group/kati#103.
      %{
        id: :health,
        icon: "monitor_weight",
        title: gettext("Health"),
        sub: "76.0 kg"
      },
      %{
        id: :recently_watched,
        icon: "movie",
        title: gettext("Recently watched"),
        sub: "The Long Hollow · 2h ago"
      }
    ]
  end

  @doc """
  182 days of intensity for the contribution grid — 26 weeks, as the design's
  own caption says.

  Deterministic: the same seed every render, because a grid that reshuffles on
  an unrelated tap looks broken. Weekends run heavier than weekdays, which is
  what makes it read as someone's viewing rather than noise.
  """
  @spec contributions() :: [0..4]
  def contributions do
    for day <- 0..181 do
      weekend? = rem(day, 7) in [5, 6]
      base = rem(day * 37 + div(day, 7) * 11, 10)

      cond do
        base < 3 and not weekend? -> 0
        base < 5 -> 1
        base < 7 -> 2
        weekend? or base < 9 -> 3
        true -> 4
      end
    end
  end

  @doc "The five-step ramp the grid uses, empty to heaviest."
  @spec intensity(0..4) :: integer()
  def intensity(0), do: 0xFFE7E3DC
  def intensity(1), do: 0xFFE9CFA8
  def intensity(2), do: 0xFFEDB273
  def intensity(3), do: 0xFFE8823C
  def intensity(4), do: 0xFFC96A28
end
