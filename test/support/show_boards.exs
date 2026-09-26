defmodule Kati.Test.ShowBoards do
  @moduledoc """
  Boards 04, 08, 14, 34, 35 and 143 as TEST fixtures: the state each drawing was
  captured in, for the tests that compare a render against its board.

  They lived in `lib/` — `drawn_film/0`, `drawn_series/0`, `drawn_season/0`,
  `Kati.Season.Sample`, `Kati.Screens.SeriesMeta.Sample` and
  `Kati.SeriesSettings.Sample` — while those screens could still fall back to
  them. No screen does now: an empty store, an id that names nothing and a
  bare push each draw their own honest page. So the boards are only shapes a
  test installs, and a fixture belongs under `test/support/`, never in what
  ships (N52-A).

  Boards 04 and 08 are still read out of `Kati.Library.Sample`, which other
  screens share and which stays in `lib/` until they stop needing it.
  """
  use Gettext, backend: Kati.Gettext

  alias Kati.Library.Sample

  @doc "Board 08's film."
  @spec film() :: map()
  def film, do: Sample.film()

  @doc """
  Board 04's series, with `by_season` added so its S1/S2/S3 pills switch.

  The season headings go through `gettext/1`, so board 58 — the same screen
  under `:fa` — gets its own words from the same call.
  """
  @spec series() :: map()
  def series do
    drawn = Sample.series()

    by_season =
      Map.new(drawn.seasons, fn label ->
        episodes = Sample.season_episodes(label)

        {label,
         %{
           season: gettext("Season %{n}", n: Kati.Locale.number(String.trim_leading(label, "S"))),
           total: length(episodes),
           episodes: episodes
         }}
      end)

    Map.put(drawn, :by_season, by_season)
  end

  @doc """
  Board 34's season: Season 2 of the drawn show, its three order tiles, both
  switches, the special, the merged finale and the footnote's two sentences.
  """
  @spec season() :: map()
  def season do
    %{
      tracked_id: "board-34",
      title: "Season 2",
      subtitle: "order & specials",
      orders: ["Aired", "Absolute", "DVD"],
      current_order: "Aired",
      options: [
        %{icon: "star", title: "Include specials", sub: "Shown inline, at air date", on: true},
        %{
          icon: "call_merge",
          title: "Merge multi-part",
          sub: "Treat E7 & E8 as one 2h finale",
          on: true
        }
      ],
      eyebrow: "Episodes · 9 in this order",
      episodes: [
        aired("E1", "Low Water", 54, ~D[2026-07-09]),
        aired("S1", "The Estuary — a making-of", 22, ~D[2026-07-12])
        |> Map.merge(%{special: true, badge: %{label: "SPECIAL", tone: :cream}}),
        aired("E2", "The Cull", 49, ~D[2026-07-16]),
        aired("E3", "Blackthorn", 52, ~D[2026-07-23]),
        aired("E4", "What the Tide Left", 51, ~D[2026-07-30]),
        aired("E5", "Hollow Season", 47, ~D[2026-08-06]),
        upcoming("E6", "The Undertow", 55, ~D[2026-08-20]),
        upcoming("E7", "Long Hollow", 122, ~D[2026-08-27])
        |> Map.put(:badge, %{label: "PARTS 1–2", tone: :paper})
      ],
      note:
        "Absolute order renumbers this season 27–35 and drops the special. " <>
          "Your ticks follow the episode, not the number."
    }
  end

  @doc """
  Board 143's season, as screen 143 reads one: the drawn show's Season 2,
  six episodes, three of them rated, the sixth not yet aired. The rows carry
  no episode id, so the rating column draws the numeral with no door behind
  it.
  """
  @spec episode_ratings() :: map()
  def episode_ratings do
    %{
      tracked_id: "board-143",
      show: "The Long Hollow",
      title: "Season 2",
      none?: false,
      episodes: [
        aired("E1", "Low Water", 54, ~D[2026-07-09]) |> Map.put(:rating, 4.5),
        aired("E2", "The Cull", 49, ~D[2026-07-16]) |> Map.put(:rating, nil),
        aired("E3", "Blackthorn", 52, ~D[2026-07-23]) |> Map.put(:rating, 5.0),
        aired("E4", "What the Tide Left", 51, ~D[2026-07-30]) |> Map.put(:rating, 3.5),
        aired("E5", "Hollow Season", 47, ~D[2026-08-06]) |> Map.put(:rating, nil),
        upcoming("E6", "The Undertow", 55, ~D[2026-08-20])
        |> Map.merge(%{rating: nil, aired: false})
      ]
    }
  end

  defp aired(number, title, minutes, on),
    do: %{number: number, title: title, sub: "#{minutes}m · " <> short(on), watched: true}

  defp upcoming(number, title, minutes, on),
    do: %{number: number, title: title, sub: "#{minutes}m · airs " <> short(on), watched: false}

  defp short(date), do: Kati.Locale.date(date, :short)

  @doc """
  Board 14's series: the drawn show's three ratings, its synopsis, four cast
  members, three ways to watch and four tags.
  """
  @spec series_meta() :: map()
  def series_meta do
    %{
      tracked_id: nil,
      title: "The Long Hollow",
      seed: "hollow71",
      meta: "2024 · 15 · DRAMA, MYSTERY · 3 SEASONS · 26 EP",
      ratings: [
        %{label: "Yours", value: "4.5", color: 0xFFE8823C, star?: true},
        %{label: "Audience", value: "8.1", color: 0xFF1A1917, star?: false},
        %{label: "Critics", value: "96%", color: 0xFF4E9A73, star?: false}
      ],
      synopsis:
        "A tidal surveyor returns to the estuary village she left at seventeen, " <>
          "and finds the water has been keeping records of its own.",
      cast: [
        %{name: "Ines Karvel", role: "Mara", seed: "face26"},
        %{name: "Tomas Rhee", role: "Bryn", seed: "face14"},
        %{name: "Ada Vance", role: "Sister Ill", seed: "face45"},
        %{name: "Ola Beck", role: "The Warden", seed: "face58"}
      ],
      where: [
        %{badge: "L", name: Kati.Locale.ltr("Lumen+"), line: "included · 4K HDR", price: nil},
        %{badge: "K", name: "Kino store", line: "buy season", price: "£14.99"},
        %{badge: "D", name: "Your shelf", line: "Blu-ray, S1–S2", price: "owned"}
      ],
      tags: ["slow burn", "coastal", "watch with Jo", "rewatchable"],
      add_tag: "+ tag"
    }
  end

  @doc """
  Board 35's show, as a real show's page draws it: *The Long Hollow*,
  watching, following new episodes, in the United Kingdom, paying for three
  services. The tracked row is built in memory and never stored, so the page
  draws its live rows without a database behind them.
  """
  @spec series_settings() :: map()
  def series_settings do
    tracked = %Kati.Media.TrackedTitle{
      id: "board-35",
      status: :watching,
      notify_new_episodes: true,
      hide_unwatched_titles: false
    }

    %{
      title: "The Long Hollow",
      subtitle: gettext("show settings"),
      status_label: gettext("Status"),
      season_pass_label: gettext("Season pass"),
      region: "GB",
      services: ["Lumen+", "Orbit", "Kino"],
      tracked: tracked
    }
  end
end
