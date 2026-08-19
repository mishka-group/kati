defmodule Kati.SeriesSettings.Sample do
  @moduledoc """
  Stand-in per-show settings, until the Screen domain exists.

  Screen 35's caption states the decision this data encodes: *"explicit
  per-show state — watching, paused or dropped as a first-class choice rather
  than a swipe action, plus the season pass and the region that decides what
  'available' means."* So `statuses/0` is three peers with one selected, not a
  boolean with an escape hatch.

  Three groups, and the third is deliberately not a peer of the first two —
  screen 35 gives **This show** a grey dash where the others get the accent
  one, because reset, archive and remove are things you do *to* the show
  rather than settings the show carries. `Kati.UI.SettingsList.eyebrow_muted/1`
  is what draws that distinction, and it is a distinction, not a shade.

  Marked clearly rather than hidden: sample data that looks like real data is
  how a demo quietly becomes a lie.
  """

  @doc "The show these settings belong to, as screen 35 draws it."
  @spec show() :: map()
  def show do
    %{
      title: "The Long Hollow",
      subtitle: "show settings",
      status_label: "Status",
      season_pass_label: "Season pass",
      region_label: "Region & availability",
      this_show_label: "This show"
    }
  end

  @doc "Watching, paused or dropped — three peers, one chosen."
  @spec statuses() :: [map()]
  def statuses do
    [
      %{icon: "play_circle", label: "Watching", on: true},
      %{icon: "pause_circle", label: "Paused", on: false},
      %{icon: "do_not_disturb_on", label: "Dropped", on: false}
    ]
  end

  @doc "What the app does on its own once a show is followed."
  @spec season_pass() :: [map()]
  def season_pass do
    [
      %{
        icon: "featured_seasonal_and_gifts",
        title: "Auto-add new seasons",
        sub: "S4 will appear when announced",
        control: {:switch, true}
      },
      %{
        icon: "notifications",
        title: "Tell me about episodes",
        sub: "Inbox only, no push",
        control: {:switch, true}
      },
      %{
        icon: "event",
        title: "Put air dates on calendar",
        sub: "Personal · orange",
        control: {:switch, true}
      },
      %{
        icon: "visibility_off",
        title: "Hide unwatched titles",
        sub: "Spoiler-safe episode names",
        control: {:switch, false}
      }
    ]
  end

  @doc "What decides whether a title counts as available at all."
  @spec region() :: [map()]
  def region do
    [
      %{icon: "public", title: "Region", sub: "United Kingdom", control: :chevron},
      %{
        icon: "subscriptions",
        title: "My services",
        sub: "Lumen+, Orbit, Kino · 3 of 12",
        control: :chevron
      },
      %{
        icon: "sell",
        title: "Watch for price drops",
        sub: "Wishlist titles under £8",
        control: {:switch, true}
      },
      %{icon: "hd", title: "Preferred quality", sub: "4K HDR where offered", control: :chevron}
    ]
  end

  @doc """
  Things done to the show rather than settings it carries.

  The last one is `danger: true`: the drawing tints its tile and its label
  `#B4553C` and gives it no second line, because there is nothing reassuring
  to say underneath it.
  """
  @spec this_show() :: [map()]
  def this_show do
    [
      %{icon: "replay", title: "Reset progress", sub: "Currently 5 of 7 in S2", control: :chevron},
      %{
        icon: "archive",
        title: "Archive",
        sub: "Keeps history, hides from shelf",
        control: :chevron
      },
      %{icon: "delete", title: "Remove from library", control: :chevron, danger: true}
    ]
  end
end
