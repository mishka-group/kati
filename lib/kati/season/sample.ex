defmodule Kati.Season.Sample do
  @moduledoc """
  Stand-in data for one season's running order, until the Screen domain exists.

  Screen 34's caption is the specification: *"the messy reality of TV —
  specials inline or hidden, three numbering schemes, and two-part finales
  merged into one 2-hour tick. Progress is stored per episode so switching
  order never loses a tick."*

  So an episode's `number` is a **label**, not an index. `S1` is a special
  sitting between E1 and E2; `E7` is two parts merged into one entry. Deriving
  the number from the list position would be exactly the bug the caption warns
  about — the tick belongs to the episode, and the number is what the chosen
  order happens to call it today.

  The eyebrow says nine episodes and the drawing lists eight. That is the
  design's own count and it is kept as the design's own string rather than
  computed, because the difference is information: an order can hide an entry
  it still counts.
  """

  @doc "The season, as screen 34 draws it."
  @spec season() :: map()
  def season do
    %{
      title: "Season 2",
      subtitle: "order & specials",
      orders: ["Aired", "Absolute", "DVD"],
      current_order: "Aired",
      options: [
        %{
          icon: "star",
          title: "Include specials",
          sub: "Shown inline, at air date",
          on: true
        },
        %{
          icon: "call_merge",
          title: "Merge multi-part",
          sub: "Treat E7 & E8 as one 2h finale",
          on: true
        }
      ],
      eyebrow: "Episodes · 9 in this order",
      episodes: episodes(),
      note: "Absolute order renumbers this season 27–35 and drops the special. Your ticks follow the episode, not the number."
    }
  end

  # `special: true` tints the number bronze rather than grey — the drawing's
  # quietest way of saying "this one is not part of the count".
  defp episodes do
    [
      %{number: "E1", title: "Low Water", sub: "54m · 9 Jul", watched: true},
      %{
        number: "S1",
        title: "The Estuary — a making-of",
        sub: "22m · 12 Jul",
        watched: true,
        special: true,
        badge: %{label: "SPECIAL", tone: :cream}
      },
      %{number: "E2", title: "The Cull", sub: "49m · 16 Jul", watched: true},
      %{number: "E3", title: "Blackthorn", sub: "52m · 23 Jul", watched: true},
      %{number: "E4", title: "What the Tide Left", sub: "51m · 30 Jul", watched: true},
      %{number: "E5", title: "Hollow Season", sub: "47m · 6 Aug", watched: true},
      %{number: "E6", title: "The Undertow", sub: "55m · airs 20 Aug", watched: false},
      %{
        number: "E7",
        title: "Long Hollow",
        sub: "122m · airs 27 Aug",
        watched: false,
        badge: %{label: "PARTS 1–2", tone: :paper}
      }
    ]
  end
end
