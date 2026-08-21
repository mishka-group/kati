defmodule Kati.Calendar.SampleWeek do
  @moduledoc """
  Screen 17's week: 10 – 16 Aug, drawn as seven lanes of nameless blocks.

  The design's caption is the specification: *"Seven lanes are too narrow for
  names, so they carry none: block height is duration, colour is section, and
  the week reads as a load map at a glance."* Only the start hour is printed
  inside a block, in mono, because that is the one label that fits.

  Three block styles carry the three sections, and they are not tints of one
  another — a habit is a green wash with no shadow, a personal item is a card
  with a hairline shadow, and something on screen is cream. That is the same
  vocabulary the day screen uses, at a seventh of the width.

  Stand-in data until the Calendar domain lands, marked as such.
  """

  @doc "The header: the range, and the day the card below names."
  @spec week() :: map()
  def week do
    %{
      range: "10 – 16 Aug",
      selected_label: "Thu 13 · 9 items",
      lanes: lanes(),
      events: events(),
      load: load()
    }
  end

  @doc """
  Seven lanes, Monday first. `selected?` marks the day whose header sits on a
  card — Sunday in the drawing, which is *not* the day the list below names.
  Two different states, drawn differently on purpose: the header shows today,
  the eyebrow names whatever lane you last tapped.
  """
  @spec lanes() :: [map()]
  def lanes do
    [
      %{name: "MON", day: "10", selected?: false, blocks: [block(46, :habit, "08")]},
      %{
        name: "TUE",
        day: "11",
        selected?: false,
        blocks: [block(46, :personal, "09"), block(53, :screen, "14")]
      },
      %{
        name: "WED",
        day: "12",
        selected?: false,
        blocks: [block(48, :personal, "11"), block(53, :screen, "20")]
      },
      %{
        name: "THU",
        day: "13",
        selected?: false,
        blocks: [
          block(65, :personal, "09"),
          block(46, :personal, "13"),
          block(72, :screen, "20")
        ]
      },
      %{name: "FRI", day: "14", selected?: false, blocks: [block(84, :personal, "10")]},
      %{name: "SAT", day: "15", selected?: false, blocks: [block(110, :screen, "19")]},
      %{
        name: "SUN",
        day: "16",
        selected?: true,
        blocks: [block(46, :habit, "08"), block(53, :screen, "20")]
      }
    ]
  end

  @doc """
  The named day, expanded. This is where the week gets its words back: the
  lanes carry none, so the card under them is the only place a title appears.
  """
  @spec events() :: [map()]
  def events do
    [
      %{time: "09:30", rule: :personal, title: "Standup", length: "15m"},
      %{time: "09:30", rule: :screen, title: "Design review", length: "1h"},
      %{time: "13:00", rule: :personal, title: "Lunch — Jo", length: "1h"},
      %{time: "20:00", rule: :screen, title: "6 episodes air", length: "to 23:00"}
    ]
  end

  @doc """
  The load bar: one column per day, the heaviest in ink.

  Heights are the drawing's own pixels rather than a computed scale, because
  the sentence beneath them ("Thursday is carrying 9 items") is what the chart
  is for — the bars only have to make the shape of the week obvious.
  """
  @spec load() :: map()
  def load do
    %{
      bars: [
        {18, false},
        {30, false},
        {24, false},
        {54, true},
        {12, false},
        {36, false},
        {42, false}
      ],
      letters: ["M", "T", "W", "T", "F", "S", "S"],
      lead: "Thursday is carrying",
      strong: "9 items",
      tail: ". Two things could move to Friday."
    }
  end

  @doc "The lane-block recipe for a section: fill, left rule, and lift."
  @spec style(atom()) :: map()
  def style(:habit), do: %{background: 0x244E9A73, rule: 0xFF4E9A73, shadow: nil}
  def style(:screen), do: %{background: 0xFFFBF1DE, rule: 0xFFE8823C, shadow: nil}

  def style(:personal),
    do: %{background: 0xFFFBFAF8, rule: 0xFF1A1917, shadow: "0 1 2 0 #0D1A1917"}

  defp block(height, section, hour), do: %{height: height, section: section, hour: hour}
end
