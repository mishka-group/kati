defmodule Kati.Account.Sample do
  @moduledoc """
  Stand-in account, device and permission data for screen 40.

  Sign-in exists so sync works, so the account card says what the sign-in
  bought and nothing else. Every permission carries the sentence explaining
  what it is for, which is the design's rule rather than a nicety: a row that
  cannot say why it wants something should not be asking.

  Notifications sit in the drawn state the flow actually produces — **not yet
  asked** — because screen 38 makes the notification decision before any
  permission dialog is raised. Copy is the design's own, from
  `.scratch/design/screens/40.html`.
  """

  @doc "Everything screen 40 shows, in the order it shows it."
  @spec account() :: map()
  def account do
    %{
      identity: identity(),
      devices: devices(),
      permissions: permissions(),
      privacy_note:
        "Your library, notes and history live on your devices and in your own " <>
          "iCloud. Kati has no server that can read them.",
      data: data()
    }
  end

  @doc "The signed-in identity, and the two things you can do to it."
  @spec identity() :: map()
  def identity do
    %{
      seed: "face68",
      name: "Signed in with Apple",
      relay: "RELAY ADDRESS · NO EMAIL SHARED",
      actions: ["Manage devices", "Sign out"]
    }
  end

  @doc "Every device the account syncs to, this one first."
  @spec devices() :: [map()]
  def devices do
    [
      %{
        icon: "phone_iphone",
        title: "iPhone 16 Pro",
        sub: "This device · synced 2 min ago"
      },
      %{icon: "tablet_mac", title: "iPad Air", sub: "Synced yesterday"},
      %{icon: "tv", title: "Apple TV", sub: "Detects playback only"}
    ]
  end

  @doc """
  The permissions, each with the feature that needs it.

  A row carries `pill` when the permission has never been requested, `toggle`
  once it has — so the screen can say "not yet asked" honestly instead of
  drawing an off switch that implies a refusal.
  """
  @spec permissions() :: [map()]
  def permissions do
    [
      %{
        icon: "notifications",
        title: "Notifications",
        sub: "Not yet asked — only when you turn one on",
        pill: "Allow"
      },
      %{
        icon: "calendar_month",
        title: "Calendars",
        sub: "Read + write · 3 accounts",
        toggle: true
      },
      %{
        icon: "photo_camera",
        title: "Photos",
        sub: "Only when you pick a poster",
        toggle: true
      },
      %{
        icon: "mic",
        title: "Microphone",
        sub: "Voice quick-add only",
        toggle: false
      },
      %{
        icon: "sensors",
        title: "Local network",
        sub: "Finds Chromecast for auto-detect",
        toggle: true
      }
    ]
  end

  @doc "The two rows under Privacy: what leaves, and how to end it."
  @spec data() :: [map()]
  def data do
    [
      %{
        icon: "analytics",
        title: "Share anonymous usage",
        sub: "Off",
        toggle: false
      },
      %{icon: "delete_forever", title: "Delete everything", sub: "Cannot be undone"}
    ]
  end
end
