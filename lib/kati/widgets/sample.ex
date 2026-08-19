defmodule Kati.Widgets.Sample do
  @moduledoc """
  Stand-in data for the off-app surfaces screen 39 draws.

  Widgets, voice shortcuts and the share extension all read the same three
  facts the app already knows — what is next, what airs tonight, how long the
  streak is — so this module supplies them in one shape rather than three. The
  values are the design's own, from `.scratch/design/screens/39.html`.

  The shortcut rows carry `toggle` only when the drawing gives them a switch;
  the row without one gets a chevron instead, which is how the screen tells
  "this is on or off" apart from "this opens somewhere else".
  """

  @doc "Everything screen 39 shows, in the order it shows it."
  @spec widgets() :: map()
  def widgets do
    %{
      up_next: %{
        label: "UP NEXT",
        title: "Long Hollow",
        episode: "S2E6",
        seed: "hollow71"
      },
      tonight: %{label: "TONIGHT", count: "6", line: "episodes airing"},
      streak: %{label: "STREAK", count: "11", line: "nights"},
      today_label: "TODAY · WIDE",
      today: [
        %{time: "20:00", title: "6 episodes air", color: 0xFFE8823C},
        %{time: "21:30", title: "Call Mum", color: 0xFFC4BDB3}
      ],
      shortcuts: shortcuts(),
      share: share()
    }
  end

  @doc """
  Three voice shortcuts and the automations row.

  The quotes are the phrases as spoken, which is why they are drawn in
  quotation marks — the row is the sentence, not a setting name.
  """
  @spec shortcuts() :: [map()]
  def shortcuts do
    [
      %{
        icon: "mic",
        title: "“Hey Siri, what’s next?”",
        sub: "Reads your next episode",
        toggle: true
      },
      %{
        icon: "play_arrow",
        title: "“Mark it watched”",
        sub: "Ticks whatever is in progress",
        toggle: true
      },
      %{
        icon: "add",
        title: "“Add to my list”",
        sub: "Adds a title by name",
        toggle: true
      },
      %{
        icon: "bolt",
        title: "Automations",
        sub: "Run a shortcut when a season ends"
      }
    ]
  end

  @doc "The share extension, described in the app rather than in the App Store."
  @spec share() :: map()
  def share do
    %{
      title: "Save to Kati",
      sub: "from any app, link or screenshot",
      note:
        "Share a trailer, a review link or a photo of a cinema listing — " <>
          "Kati reads the title out of it and files it on your wishlist."
    }
  end
end
