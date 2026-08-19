defmodule Kati.Library.Sample do
  @moduledoc """
  Stand-in library data, until the Screen domain exists.

  The design's screens are drawn full — nine titles, four of them in progress,
  chips carrying counts. A screen rendered against an empty database cannot be
  compared with its drawing, and every state the design specifies (a title part
  watched, a title finished, a title not started) would go unexercised.

  So this module supplies the shape the domain will supply later:
  `%{title, progress, kind}`, ordered as the grid draws them. When the real
  domain lands, delete this and point `Kati.Screens.Library` at it — the
  screen reads a list of maps and does not care where they came from.

  Marked clearly rather than hidden, because sample data that looks like real
  data is how a demo quietly becomes a lie.
  """

  @titles [
    %{title: "The Long Hollow", progress: 0.62, kind: :series},
    %{title: "Salt & Iron", progress: 0.24, kind: :series},
    %{title: "Blue Hour", progress: 0.0, kind: :film},
    %{title: "Nightjar", progress: 1.0, kind: :series},
    %{title: "The Quiet Coast", progress: 0.41, kind: :series},
    %{title: "Ember & Ash", progress: 0.0, kind: :film},
    %{title: "Winterlight", progress: 1.0, kind: :film},
    %{title: "Paper Cities", progress: 0.08, kind: :series},
    %{title: "The Fen", progress: 0.0, kind: :series}
  ]

  @doc "Every title, in the order the grid draws them."
  @spec titles() :: [map()]
  def titles, do: @titles

  @doc "The header's mono subtitle: `9 titles · 4 in progress`."
  @spec subtitle() :: String.t()
  def subtitle do
    total = length(@titles)
    active = Enum.count(@titles, &(&1.progress > 0.0 and &1.progress < 1.0))
    "#{total} titles · #{active} in progress"
  end

  @doc "Filter chips with their counts, the first one selected."
  @spec chips() :: [{String.t(), non_neg_integer()}]
  def chips do
    [
      {"All", length(@titles)},
      {"Watching", Enum.count(@titles, &(&1.progress > 0.0 and &1.progress < 1.0))},
      {"Not started", Enum.count(@titles, &(&1.progress == 0.0))},
      {"Finished", Enum.count(@titles, &(&1.progress == 1.0))}
    ]
  end

  @doc """
  One series, as screen 04 draws it: the header line, the season's progress,
  the next airing, and seven episodes with three distinct states — watched,
  unwatched, and the one that has not aired.
  """
  @spec series() :: map()
  def series do
    %{
      title: "The Long Hollow",
      meta: "2024 · DRAMA · LUMEN+ · 3 SEASONS",
      season: "Season 2",
      seasons: ["S1", "S2", "S3"],
      current_season: "S2",
      watched: 5,
      total: 7,
      next_air: "Thu 20 Aug, 20:00",
      episodes: [
        %{n: 1, title: "The Weight of Water", sub: "48 min · 2 Jul", watched: true},
        %{n: 2, title: "Hollow Ground", sub: "51 min · 9 Jul", watched: true},
        %{n: 3, title: "What the Tide Left", sub: "47 min · 16 Jul", watched: true},
        %{n: 4, title: "Salt in the Wound", sub: "52 min · 23 Jul", watched: true},
        %{n: 5, title: "The Longest Night", sub: "49 min · 30 Jul", watched: true},
        %{n: 6, title: "Ash and After", sub: "50 min · 6 Aug", watched: false},
        %{n: 7, title: "Homecoming", sub: "Airs Thu 20 Aug", watched: false, aired: false}
      ]
    }
  end

  @doc """
  The new-releases inbox, screen 05: three titles out now and three coming up.

  The dot colour carries the reason a row is here — a new episode, a premiere,
  or something about to leave a service — which is the design's way of saying
  three different things in one list without three different layouts.
  """
  @spec inbox() :: map()
  def inbox do
    %{
      watching: 24,
      last_checked: "last checked 18:02 · every 6h",
      out_now: [
        %{
          title: "The Long Hollow",
          line: "S2 E6 — Ash and After",
          meta: "48 min · LUMEN+ · aired 20:00",
          dot: 0xFFE8823C
        },
        %{
          title: "Blue Hour",
          line: "Premiere",
          meta: "1h 52m · CINEMA · out today",
          dot: 0xFF4E9A73
        },
        %{
          title: "Paper Cities",
          line: "S1 E2 — The Cartographer",
          meta: "44 min · LUMEN+ · aired 19:00",
          dot: 0xFFE8823C
        }
      ],
      coming_up: [
        %{month: "AUG", day: "20", title: "The Long Hollow", line: "S2 E7 — Homecoming", meta: "Thu, 20:00"},
        %{month: "AUG", day: "23", title: "Salt & Iron", line: "S1 E4", meta: "Sun, 21:00"},
        %{month: "SEP", day: "02", title: "Ember & Ash", line: "Leaves Lumen+", meta: "Tue"}
      ]
    }
  end
end
