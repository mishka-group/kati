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
  @doc """
  How many rows the leaving section holds, as the chip's badge prints it.

      iex> Kati.Screens.Discover.Sample.leaving_count()
      "2"
  """
  @spec leaving_count() :: String.t()
  def leaving_count, do: Integer.to_string(length(Kati.Screens.Discover.Sample.leaving()))

  @spec feed() :: map()
  def feed do
    %{
      subtitle: "Tuned to 128 titles",
      chips: [
        %{label: "For you", count: nil, selected: true},
        %{label: "People", count: nil, selected: false},
        # The count follows the list. Board 11 draws `5` over two leaving rows —
        # MOVIES-AND-TV.md #24's second half — and a badge that disagrees with
        # the section under it is the plausible-looking figure screen 96's rule
        # is against. `leaving_count/0` reads `leaving/0`, so the two cannot
        # part company again.
        %{label: "Leaving", count: Kati.Screens.Discover.Sample.leaving_count(), selected: false},
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
      leaving: Kati.Screens.Discover.Sample.leaving()
    }
  end

  @doc "The rows the leaving section holds, which is what its badge counts."
  @spec leaving() :: [map()]
  def leaving do
    [
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
  end

  @doc "A poster or a face, whichever the seed was drawn as."
  @spec image(String.t()) :: String.t() | nil
  def image(seed), do: Kati.Design.Images.poster(seed)
end
