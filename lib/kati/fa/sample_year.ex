defmodule Kati.Fa.SampleYear do
  @moduledoc """
  Screen 61's year, as data — the Persian mirror of the stats root.

  A stand-in, named as one. Copy is the design's own, from
  `test/design/screens/61.html`, including the Persian numerals: the
  domain that would produce real figures does not exist yet, and inventing
  formatted output here would make the screen impossible to compare with its
  drawing.

  ## Not the same numbers as screen 07

  The English stats screen has its own ramp and its own generated sequence.
  This one carries the drawing's **literal** 104 cells and the drawing's warm
  five-step ramp, which ends on ink rather than on orange, because the field
  sits on cream here and an orange top step disappears into it. Two screens,
  two data sets — the mirror is drawn, not derived.
  """

  @doc "Everything screen 61 draws, in the order it draws it."
  @spec year() :: map()
  def year do
    %{
      title: "سال شما",
      range: "فروردین تا مرداد ۱۴۰۵",
      time_label: "زمان تماشا",
      hours: "۳۱۲",
      hours_unit: "ساعت",
      change: "۱۸٪",
      weeks: "۲۶ هفته",
      streak: "بلندترین رشته — ۱۱ شب",
      counts: [{"۸۴", "فیلم"}, {"۱۹", "سریال"}, {"۴.۱", "میانگین"}],
      breakdown_label: "ساعت‌ها کجا رفتند",
      breakdown: breakdown(),
      week_label: "این هفته",
      week: week(),
      days: ["ش", "ی", "د", "س", "چ", "پ", "ج"],
      note:
        "نمودارها هم برعکس می‌شوند: محور زمان از راست به چپ خوانده می‌شود " <>
          "و میله‌ها از راست پر می‌شوند."
    }
  end

  @doc """
  Where the hours went: name, share of the widest bar, hours, and tone.

  The tones are a single grey ramp rather than four hues. The design uses
  colour here to order the rows, not to name them — the genre is already
  written beside each bar — so the darkest bar is simply the largest.
  """
  @spec breakdown() :: [{String.t(), float(), String.t(), integer()}]
  def breakdown do
    [
      {"درام", 0.86, "۱۰۴", 0xFF1A1917},
      {"هیجان‌انگیز", 0.58, "۷۱", 0xFF4A443B},
      {"مستند", 0.41, "۴۹", 0xFF7C766D},
      {"کمدی", 0.26, "۳۱", 0xFFB3ACA2}
    ]
  end

  @doc """
  This week's seven bars, Saturday first, as heights in points.

  Saturday first for the same reason as screen 60's matrix: the time axis is
  read from the right, so the week has to *start* at شنبه as well as be
  mirrored. Wednesday is the tall ink bar — the day being read.
  """
  @spec week() :: [{pos_integer(), boolean()}]
  def week do
    [{42, false}, {36, false}, {12, false}, {54, true}, {24, false}, {30, false}, {18, false}]
  end

  @doc """
  104 cells of intensity for the contribution field, top-right first.

  The drawing's own sequence, cell for cell, rather than a generated one:
  this screen exists to be compared with it. Chunked into rows of 26 by the
  screen, which is what its "۲۶ هفته" label claims.
  """
  @spec contributions() :: [0..4]
  def contributions do
    [
      2,
      0,
      0,
      0,
      1,
      4,
      0,
      1,
      2,
      0,
      3,
      2,
      2,
      2,
      1,
      2,
      3,
      0,
      3,
      2,
      0,
      2,
      0,
      3,
      2,
      1,
      0,
      3,
      0,
      2,
      0,
      2,
      1,
      0,
      2,
      2,
      0,
      1,
      1,
      3,
      0,
      2,
      2,
      4,
      3,
      2,
      3,
      0,
      3,
      1,
      0,
      0,
      1,
      1,
      1,
      2,
      1,
      1,
      3,
      3,
      2,
      4,
      3,
      2,
      3,
      2,
      0,
      3,
      3,
      0,
      3,
      0,
      3,
      0,
      2,
      0,
      4,
      3,
      0,
      1,
      3,
      1,
      4,
      3,
      3,
      0,
      2,
      1,
      1,
      1,
      4,
      0,
      1,
      1,
      2,
      0,
      1,
      1,
      3,
      0,
      4,
      2,
      1,
      2
    ]
  end

  @doc "The five-step ramp on cream, lightest to heaviest."
  @spec intensity(0..4) :: integer()
  def intensity(0), do: 0xFFEFE3CB
  def intensity(1), do: 0xFFE4D2B0
  def intensity(2), do: 0xFFD3B98A
  def intensity(3), do: 0xFFB08E55
  def intensity(_), do: 0xFF1A1917
end
