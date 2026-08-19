defmodule Kati.Settings.Sample do
  @moduledoc """
  Stand-in preferences, until a settings domain exists.

  Screen 24 is drawn full — every section switched on but Money, a sync badge
  that has an opinion about how fresh it is, a last backup with a date on it.
  A settings screen rendered against defaults would show five identical rows
  and none of the states the drawing specifies, so this supplies the shape the
  domain will supply later: a list of rows, each naming its icon, its copy and
  its control.

  Copy is the drawing's own, down to the typographic apostrophe in
  "another tracker's backup". Marked clearly as a stand-in, because sample
  data that looks like real data is how a demo quietly becomes a lie.
  """

  @doc "The mono line under the title."
  @spec synced() :: String.t()
  def synced, do: "Synced 2 min ago"

  @doc "The account card: the design's own photograph, its counts and its sync state."
  @spec account() :: map()
  def account do
    %{
      seed: "face68",
      name: "Your Kati",
      meta: "1,204 ENTRIES · 4 SECTIONS",
      status: "Synced"
    }
  end

  @doc "Appearance — the one group whose first row carries a segmented control."
  @spec appearance() :: [map()]
  def appearance do
    [
      %{
        icon: "contrast",
        title: "Theme",
        sub: nil,
        control: {:segments, ["Auto", "Light", "Dark"], "Auto"}
      },
      %{
        icon: "format_size",
        title: "Text size",
        sub: "Follows system · up to 235%",
        control: :chevron
      },
      %{icon: "motion_blur", title: "Reduce motion", sub: nil, control: {:switch, false}}
    ]
  end

  @doc """
  Sections — the growth mechanic made literal.

  Each row states which surfaces its section appears on, which is why the
  secondary line is not decoration: turning Music off removes a shelf, and the
  row says so before you touch it.
  """
  @spec sections() :: [map()]
  def sections do
    [
      %{
        icon: "movie",
        title: "Screen",
        sub: "Home card, calendar feed, shelf",
        control: {:switch, true}
      },
      %{icon: "menu_book", title: "Books", sub: "Home card, shelf", control: {:switch, true}},
      %{icon: "graphic_eq", title: "Music", sub: "Shelf only", control: {:switch, true}},
      %{icon: "bolt", title: "Habits", sub: "Calendar feed", control: {:switch, true}},
      %{icon: "payments", title: "Money", sub: "Calendar feed", control: {:switch, false}},
      %{
        icon: "drag_indicator",
        title: "Reorder sections",
        sub: "Drag to change home order",
        control: :chevron
      }
    ]
  end

  @doc "Data — import, export, sync, and the one destructive row."
  @spec data() :: [map()]
  def data do
    [
      %{
        icon: "download",
        title: "Import",
        sub: "CSV, JSON, or another tracker’s backup",
        control: :chevron
      },
      %{icon: "upload", title: "Export everything", sub: "Last backup 14 Aug", control: :chevron},
      %{icon: "sync", title: "Sync", sub: "iCloud · this device + iPad", control: :chevron},
      %{icon: "delete", title: "Clear watch history", sub: nil, control: :chevron}
    ]
  end

  @doc "About — version and the privacy claim the app has to keep."
  @spec about() :: [map()]
  def about do
    [
      %{icon: "info", title: "Version", sub: "0.1 · mock build", control: :chevron},
      %{icon: "shield", title: "Privacy", sub: "Nothing leaves the device", control: :chevron}
    ]
  end
end
