defmodule Kati.SyncFixtures do
  @moduledoc """
  Rows for the sync suite, built through the real Ash actions.

  Nothing here inserts with raw SQL: the actions carry
  `Kati.Calendars.Changes.BumpLocalRev` and `DeriveTiming`, and a fixture that
  skipped them would be testing a row shape the app never produces.
  """

  alias Kati.Calendars.Account
  alias Kati.Calendars.Calendar
  alias Kati.Calendars.Event

  def unique(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"

  def account!(attrs \\ %{}) do
    Account
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{provider: :caldav, display_name: unique("account")}, attrs)
    )
    |> Ash.create!()
  end

  def calendar!(attrs \\ %{}) do
    Calendar
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{display_name: unique("calendar"), kind: :local}, attrs)
    )
    |> Ash.create!()
  end

  @doc "A remote calendar Kati may write its own events to, but not mirrored ones."
  def remote_calendar!(attrs \\ %{}) do
    account = account!()

    calendar!(
      Map.merge(
        %{
          account_id: account.id,
          kind: :provider,
          remote_id: unique("remote-cal"),
          writeback_policy: :kati_only
        },
        attrs
      )
    )
  end

  def event!(calendar, attrs \\ %{}) do
    Event
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          uid: unique("uid") <> "@kati",
          calendar_id: calendar.id,
          origin: :kati,
          summary: "Standup",
          dtstart_utc: ~U[2026-08-12 09:00:00.000000Z],
          duration_iso: "PT30M"
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  @doc """
  A mirrored row as `Kati.Sync.Engine` would have inserted it: clean, with the
  server's bytes and etag.
  """
  def mirror!(calendar, raw, attrs \\ %{}) do
    event!(
      calendar,
      Map.merge(
        %{
          origin: :mirror,
          raw_icalendar: raw,
          remote_id: unique("remote"),
          remote_etag: "etag-1",
          synced_rev: 1,
          sync_state: :clean
        },
        attrs
      )
    )
  end

  @doc "A minimal but realistic VEVENT for a given UID."
  def vevent(uid, lines \\ []) do
    body =
      [
        "UID:#{uid}",
        "DTSTAMP:20260810T120000Z",
        "DTSTART;TZID=Europe/London:20260812T090000",
        "DURATION:PT30M",
        "SUMMARY:Standup",
        "LOCATION:Room 4",
        "X-MOZ-LASTACK:20260101T093000Z"
      ] ++ lines

    "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\n" <>
      Enum.join(body, "\r\n") <> "\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
  end
end
