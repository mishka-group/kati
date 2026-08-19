defmodule Kati.Calendar.SampleAgenda do
  @moduledoc """
  Screen 30's agenda: the view that skips empty days entirely.

  The design's caption is the rule: *"date kickers only appear where something
  exists, and gaps are stated rather than scrolled through."* So the groups are
  not a week — they are TODAY, TOMORROW, a Thursday nine days out and a date in
  September, with the silence between them named by the footer rather than
  drawn as empty rows.

  Each kicker carries two labels: a short name in ink and a longer mono
  subtitle in `#A0998F`. The subtitle is where the day's weight goes when it
  has any ("20 Aug · 14 items · 2 clashes"), which is how a heavy day
  announces itself before you reach it.

  Stand-in data until the Calendar domain lands, marked as such.
  """

  @screen 0xFFE8823C
  @personal 0xFF1A1917
  @habit 0xFF4E9A73
  @money 0xFF8A8479

  @doc "The whole agenda, in the order the drawing lists it."
  @spec agenda() :: map()
  def agenda do
    %{groups: groups(), footer: "Nothing else until 12 Sep"}
  end

  @doc "The date groups. A group with no rows would not be drawn at all."
  @spec groups() :: [map()]
  def groups do
    [
      %{
        kicker: "TODAY",
        sub: "Sun 16 Aug",
        rows: [
          %{
            time: "20:00",
            rule: @screen,
            seed: "hollow71",
            title: "The Long Hollow S2E6",
            sub: "Lumen+"
          },
          %{time: "21:30", rule: @personal, seed: nil, title: "Call Mum", sub: "repeats weekly"}
        ]
      },
      %{
        kicker: "TOMORROW",
        sub: "Mon 17 Aug",
        rows: [
          %{
            time: "08:00",
            rule: @habit,
            seed: nil,
            title: "Morning run",
            sub: "habit · 12-day streak"
          },
          %{time: "18:00", rule: @money, seed: nil, title: "Lumen+ renews", sub: "£8.99"}
        ]
      },
      %{
        kicker: "THU",
        sub: "20 Aug · 14 items · 2 clashes",
        rows: [
          %{
            time: "09:30",
            rule: @screen,
            seed: nil,
            title: "2 at once — Standup, Design review",
            sub: "clash"
          },
          %{
            time: "20:00",
            rule: @screen,
            seed: "ashfall42",
            title: "6 episodes air",
            sub: "Lumen+, Orbit, Kino"
          }
        ]
      },
      %{
        kicker: "SEP",
        sub: "04 Sep",
        rows: [
          %{
            time: "—",
            rule: @screen,
            seed: "vellum97",
            title: "Vellum in cinemas",
            sub: "wishlisted"
          }
        ]
      }
    ]
  end
end
