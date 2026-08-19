defmodule Kati.Settings.CalendarsSample do
  @moduledoc """
  Stand-in calendar connections, screen 32.

  `Kati.Calendars` already models accounts and calendars for real, but nothing
  yet returns the three-account, four-calendar arrangement the drawing shows —
  and the drawing needs all of it: two live accounts and one gone stale, three
  calendars drawn and one switched off, and write-back on for exactly one of
  the three things Kati could push.

  Section colour is inherited by the imported calendar, which is why each row
  carries its own swatch rather than a shared accent: Personal is ink, Work is
  the green, Family is the bronze, and Birthdays — switched off — is the grey
  the rest of the app uses for "exists, not shown".
  """

  @doc "The mono line under the title."
  @spec connected() :: String.t()
  def connected, do: "3 connected"

  @doc """
  The connected accounts, and the row that adds another.

  A stale account is not an error — the calendar still draws from its last
  sync — so it gets its own amber-red pill rather than the error card screen
  27 specifies.
  """
  @spec accounts() :: [map()]
  def accounts do
    [
      %{
        icon: "cloud",
        title: "iCloud",
        sub: "jo@icloud.com · 2 calendars",
        status: "Live",
        state: :live
      },
      %{
        icon: "mail",
        title: "Google",
        sub: "work@studio.co · 1 calendar",
        status: "Live",
        state: :live
      },
      %{
        icon: "dns",
        title: "CalDAV",
        sub: "fastmail · last sync 4h ago",
        status: "Stale",
        state: :stale
      }
    ]
  end

  @doc "The label on the dashed row under the accounts."
  @spec add_account() :: String.t()
  def add_account, do: "Add an account"

  @doc "Which calendars are drawn, each with the colour it lends its events."
  @spec calendars() :: [map()]
  def calendars do
    [
      %{color: 0xFF1A1917, title: "Personal", on: true},
      %{color: 0xFF4E9A73, title: "Work", on: true},
      %{color: 0xFFB08E55, title: "Family", on: true},
      %{color: 0xFFC4BDB3, title: "Birthdays", on: false}
    ]
  end

  @doc """
  What Kati is allowed to write out.

  Air dates go to a named calendar on a named account, so the row states both.
  Habits and Renewals stay in — they are Kati's own idea of an event and would
  be noise in a calendar someone else reads.
  """
  @spec write_back() :: [map()]
  def write_back do
    [
      %{icon: "live_tv", title: "Air dates", sub: "Push to iCloud · Personal", on: true},
      %{icon: "bolt", title: "Habits", sub: "Keep inside Kati only", on: false},
      %{icon: "payments", title: "Renewals", sub: "Keep inside Kati only", on: false}
    ]
  end

  @doc "The footnote that states the read/write boundary."
  @spec note() :: String.t()
  def note do
    "Kati reads your calendars to draw the day. It only writes back what you " <>
      "tick above, and never touches an event it did not create."
  end
end
