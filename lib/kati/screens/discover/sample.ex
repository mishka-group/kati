defmodule Kati.Screens.Discover.Sample do
  @moduledoc """
  Stand-in recommendation data for screen 11, until the Screen domain exists.

  The drawing's own copy throughout — the match percentages, the roles, the
  service name and the number of days it is leaving in. `new?` is the field
  that decides the trailing mark on a person's row: an orange dot when there is
  something to look at, a muted `check` when there is not. Two people with news
  and one without, because the design draws both states and a list of three
  identical rows would exercise neither.
  """

  @doc "Everything screen 11 draws."
  @spec feed() :: map()
  def feed do
    %{
      subtitle: "Tuned to 128 titles",
      chips: [
        %{label: "For you", count: nil, selected: true},
        %{label: "People", count: nil, selected: false},
        %{label: "Leaving", count: "5", selected: false},
        %{label: "Awards", count: nil, selected: false}
      ],
      because: "Because you watched The Long Hollow",
      picks: [
        %{title: "Vellum", seed: "vellum97", match: "94% match"},
        %{title: "Quietus", seed: "quietus39", match: "89% match"},
        %{title: "Quiet Harbour", seed: "harbour86", match: "81% match"}
      ],
      people: [
        %{name: "Ines Karvel", line: "Director · 2 new projects", seed: "face32", new?: true},
        %{name: "Tomas Rhee", line: "Writer · 1 in production", seed: "face14", new?: true},
        %{name: "Ada Vance", line: "Actor · nothing new", seed: "face45", new?: false}
      ],
      leaving_label: "Leaving Lumen+ in 7 days",
      leaving: [
        %{
          title: "Nightbirds",
          seed: "nightbirds24",
          line: "on your wishlist",
          action: "Schedule"
        },
        %{
          title: "A Quieter Place to Land",
          seed: "quieterplace8",
          line: "never started",
          action: "Schedule"
        }
      ]
    }
  end

  @doc "A poster or a face, whichever the seed was drawn as."
  @spec image(String.t()) :: String.t() | nil
  def image(seed), do: Kati.Design.Images.poster(seed)
end
