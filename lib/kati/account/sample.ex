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
  `test/design/screens/40.html`.
  """

  @doc "Everything screen 40 shows, in the order it shows it."
  @spec account() :: map()
  def account do
    %{
      storage: storage(),
      permissions: permissions(),
      install: install_permissions(),
      privacy_note:
        "Kati has no analytics and no server. There is nothing to switch off, " <>
          "and nothing that could be read if there were.",
      data: data()
    }
  end

  @doc """
  Where the data is, what it weighs, and how it leaves.

  Replaces the account card. Screen 40 opened with *"Signed in with Apple ·
  relay address · no email shared"* above a list of syncing devices, and Kati
  has no account, no server and no second device to sync with — so the card
  states the model positively instead of listing an absence.

  There is a hard reason the *Move to a new phone* row cannot be soft:
  `android:allowBackup` is `false` and there is no server, so a user who loses
  this phone loses everything unless they have exported it themselves.
  """
  @spec storage() :: map()
  def storage do
    %{
      headline: "Everything is in one file on this phone.",
      body:
        "There is no account, no sign-in and no server. Because there is no " <>
          "server, moving to a new phone means moving the file yourself.",
      rows: [
        %{icon: "inventory_2", title: "Storage used", value: "214 MB · 1,206 titles"},
        # "Never" is the honest empty value and should read as a gentle warning
        # rather than an error — nothing has gone wrong, but nothing is safe
        # either.
        %{icon: "upload", title: "Last backup", value: "Never", warn: true},
        %{icon: "phone_iphone", title: "Move to a new phone", value: nil, chevron: true}
      ]
    }
  end

  @doc """
  The permissions, each stating its purpose before anything is asked.

  Exactly what `AndroidManifest.xml` declares and Kati uses. The drawing's
  Photos, Microphone and Local network rows are gone: `READ_MEDIA_IMAGES`,
  `RECORD_AUDIO` and the Bluetooth permissions were never requested (K-30,
  K-31 removed the surfaces that would have needed them), so a row for any of
  them asks the user about something Kati cannot do.

  `capability` is what `Kati.Permissions.status/1` reads. The trailing control
  is decided from that answer at render time rather than stored here — a
  permission changes in system settings while Kati is backgrounded, which is
  the normal way it changes, so a copy kept in a sample would be a lie exactly
  when it matters.
  """
  @spec permissions() :: [map()]
  def permissions do
    [
      %{
        icon: "notifications",
        title: "Notifications",
        capability: :notifications,
        sub: "Only when you turn one on.",
        # Android 13 made this a runtime permission, and a denial is not fatal:
        # screen 25's inbox card is the degraded path, so the row says so
        # rather than leaving the user to discover it.
        denied_sub: "Turned off. New episodes will still appear in your inbox."
      },
      %{
        icon: "calendar_month",
        title: "Calendars",
        capability: :calendar,
        # READ_CALENDAR only. WRITE_CALENDAR is not declared, which is why
        # `Kati.Sync.Adapter.DeviceProvider` reports `writable: false` — so the
        # row promises reading and nothing else.
        sub: "To show your appointments beside your episodes. Kati only reads them.",
        denied_sub: "Turned off. Your episodes will show without your appointments."
      },
      %{
        icon: "schedule",
        title: "Alarms and reminders",
        capability: :exact_alarms,
        sub: "So a reminder set for 21:00 arrives at 21:00.",
        denied_sub: "Turned off. Reminders will arrive late, when the phone next wakes."
      }
    ]
  end

  @doc """
  What Kati asks for by being installed, stated as fact.

  These have no runtime state to read and no dialog behind them — they are
  granted by being declared. Drawing a control for them would be a switch that
  cannot move, so the screen states them and moves on.
  """
  @spec install_permissions() :: [map()]
  def install_permissions do
    [
      %{
        icon: "public",
        title: "Internet",
        sub: "To look up what you are watching. Nothing about you is sent."
      },
      %{
        icon: "history",
        title: "Start at boot",
        sub:
          "Android drops pending alarms when the phone restarts. This puts your reminders back."
      },
      %{
        icon: "notifications_active",
        title: "Vibrate",
        sub: "So a reminder can be felt, not just seen."
      }
    ]
  end

  @doc "The two rows under Privacy: what leaves, and how to end it."
  @spec data() :: [map()]
  def data do
    [
      # No "Share anonymous usage" row. With no server it had nowhere to send
      # anything, so an off switch was a control over a thing that did not
      # exist — the privacy note says it in one sentence instead.
      %{icon: "delete_forever", title: "Delete everything", sub: "Cannot be undone"}
    ]
  end
end
