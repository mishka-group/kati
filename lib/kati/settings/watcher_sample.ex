defmodule Kati.Settings.WatcherSample do
  @moduledoc """
  Stand-in release-watcher preferences, screen 25.

  The defaults here are the argument, not filler. Push is off and the inbox
  badge is on, because the app is designed to be checked rather than to
  interrupt — every alert type can be routed to the inbox instead of the lock
  screen, and the drawing says so in its own footnote.

  Delete this when a preferences domain lands; the screen reads lists of maps
  and does not care where they came from.
  """

  @doc "The mono line under the title."
  @spec checked() :: String.t()
  def checked, do: "checked 18:02"

  @doc "The cream banner: how many titles are watched, and what that found."
  @spec banner() :: map()
  def banner do
    %{title: "Watching 24 titles", meta: "3 FOUND THIS WEEK", on: true}
  end

  @doc """
  Tell me about — the six kinds of thing the watcher can look for.

  Price drops is the one switched off: it is the only row that is about money
  rather than about a title you already follow.
  """
  @spec kinds() :: [map()]
  def kinds do
    [
      %{icon: "live_tv", title: "New episodes", sub: "Shows you are watching", on: true},
      %{icon: "celebration", title: "Premieres", sub: "New seasons and first episodes", on: true},
      %{icon: "timer", title: "Leaving soon", sub: "7 days’ notice", on: true},
      %{
        icon: "person",
        title: "People you follow",
        sub: "Announcements, not just releases",
        on: true
      },
      %{icon: "sell", title: "Price drops", sub: "Titles on your wishlist", on: false},
      %{icon: "payments", title: "Renewals", sub: "2 days before", on: true}
    ]
  end

  @doc "How often the watcher runs, and which cadence is chosen."
  @spec cadences() :: [String.t()]
  def cadences, do: ["Hourly", "Every 6h", "Daily", "Manual"]

  @doc "The selected cadence."
  @spec cadence() :: String.t()
  def cadence, do: "Every 6h"

  @doc "How loudly — where a find is allowed to land."
  @spec loudness() :: [map()]
  def loudness do
    [
      %{
        icon: "notifications_off",
        title: "Push notifications",
        sub: "Off — the home card is enough",
        on: false
      },
      %{icon: "inbox", title: "Inbox badge", sub: "Unread count on the bell", on: true},
      %{icon: "bedtime", title: "Quiet hours", sub: "23:00 – 08:00", on: true},
      %{icon: "mail", title: "Weekly digest", sub: "Sundays at 18:00", on: true}
    ]
  end

  @doc "The footnote that states the default out loud."
  @spec note() :: String.t()
  def note do
    "Push is off by default. The app is designed to be checked, not to " <>
      "interrupt — that is what the home card and the badge are for."
  end
end
