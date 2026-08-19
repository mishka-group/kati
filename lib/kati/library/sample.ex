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

  # The design's own titles and its own photographs. Each `seed` is the
  # picsum seed the export uses for that title — `hollow71` is The Long
  # Hollow — so the app shows the exact picture the drawing shows rather than
  # something that merely occupies the same rectangle.
  @titles [
    %{title: "The Long Hollow", seed: "hollow71", progress: 0.62, kind: :series},
    %{title: "Salt & Iron", seed: "saltiron33", progress: 0.24, kind: :series},
    %{title: "Blue Hour", seed: "bluehour58", progress: 0.0, kind: :film},
    %{title: "Ashfall", seed: "ashfall42", progress: 0.41, kind: :series},
    %{title: "Marram", seed: "marram15", progress: 1.0, kind: :series},
    %{title: "Harbour", seed: "harbour86", progress: 0.0, kind: :film},
    %{title: "Nightbirds", seed: "nightbirds24", progress: 1.0, kind: :film},
    %{title: "Vellum", seed: "vellum97", progress: 0.08, kind: :film},
    %{title: "The Cartographer", seed: "cartog60", progress: 0.0, kind: :series}
  ]

  @doc """
  Absolute path to a sample poster, or `nil` when there is none.

  The artwork lives in `priv/sample/`, which #72 proved survives a release
  build, so the same lookup works in dev and on a shipped device. Real artwork
  rather than grey rectangles, because a screen full of placeholders cannot be
  compared with a drawing full of posters.
  """
  @spec poster(String.t()) :: String.t() | nil
  def poster(seed), do: Kati.Design.Images.poster(seed)

  @doc "Wide artwork for a series header."
  @spec art(String.t()) :: String.t() | nil
  def art(seed), do: Kati.Design.Images.hero(seed)

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
      title: "The Long Hollow", seed: "hollow71",
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
          title: "The Long Hollow", seed: "hollow71",
          line: "S2 E6 — Ash and After",
          meta: "48 min · LUMEN+ · aired 20:00",
          dot: 0xFFE8823C
        },
        %{
          title: "Blue Hour", seed: "bluehour58",
          line: "Premiere",
          meta: "1h 52m · CINEMA · out today",
          dot: 0xFF4E9A73
        },
        %{
          title: "Paper Cities", seed: "cartog60",
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

  @doc """
  Search results for screen 06, mid-query on "quiet".

  Two states are drawn and both appear here: a title not in the library yet
  (ink `add` button) and one already added (muted `check`), because the design
  distinguishes them and a list of four identical rows would not exercise it.
  """
  @spec search_results() :: [map()]
  def search_results do
    [
      %{title: "The Quiet Coast", seed: "quieterplace8", meta: "2023 · SERIES · 2 SEASONS", note: "Drama · Lumen+", added: false},
      %{title: "Quiet Earth", seed: "quietones12", meta: "2019 · FILM · 1h 48m", note: "Science fiction", added: false},
      %{title: "A Quiet Place to Land", seed: "quieterplace8", meta: "2021 · FILM · 2h 04m", note: "Drama · Cinema", added: true},
      %{title: "Quietus", seed: "quietus39", meta: "2024 · SERIES · 1 SEASON", note: "Thriller · Northlight", added: false}
    ]
  end

  @doc "One film, as screen 08 draws it."
  @spec film() :: map()
  def film do
    %{
      title: "Blue Hour",
      seed: "bluehour58",
      meta: "2025 · 1H 52M · DRAMA",
      watched: "Watched 12 Aug",
      stars: 4,
      seen: "2 times",
      note_date: "Note · 12 Aug",
      note:
        "Saw it at the Rex with Jo. The last twenty minutes are the whole film " <>
          "— worth a rewatch on a proper screen.",
      where: [
        %{badge: "L", name: "Lumen+", price: "included"},
        %{badge: "K", name: "Kino store", price: "£9.99"}
      ],
      actions: [{"replay", "Log rewatch"}, {"event", "Schedule"}, {"ios_share", "Share"}]
    }
  end
end
