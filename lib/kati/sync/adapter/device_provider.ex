defmodule Kati.Sync.Adapter.DeviceProvider do
  @moduledoc """
  The `CalendarContract` transport, behind the adapter boundary.

  Everything Android-shaped lives here and nowhere above it: the engine never
  learns that a `ContentResolver` exists, which is what makes the later CalDAV
  and EventKit adapters cheap.

  ## Why it reads a file

  There is no Elixir→Kotlin call path without adding a NIF, and Mob's NIF table
  lives in the `mob` package rather than the app. So `KatiCalendarReader`
  **publishes** JSON on app start and this adapter ingests it — the same
  architecture `Kati.Calendars.DeviceImport` uses, for the same structural
  reason. It also happens to match the data: Android's sync adapters keep the
  provider fresh whether or not Kati is running, so foreground is both when the
  data is newest and when the user can see it.

  ## Why it is read-only

  `capabilities/1` reports `writable: false`, and it is not a placeholder.
  Writing to the provider needs `WRITE_CALENDAR`, which Kati does not request —
  so saying so once, here, is what stops `Kati.Sync.Outbox.enqueue/1` building
  a queue of writes that would fail forever. `push/2` refuses rather than
  pretending, and refuses with `{:error, :read_only}` rather than a retryable
  error, so `Kati.Sync.Backoff.classify/1` quarantines it instead of trying
  again every foreground until the heat death of the phone.

  ## Deletion

  The published payload names what is gone. A row that is merely absent from
  this run's file is **not** reported as deleted: the reader publishes a
  window, and a row outside the window is out of view, not removed. That
  distinction is the same one every other transport makes and getting it wrong
  deletes a user's calendar.
  """

  @behaviour Kati.Sync.Adapter

  alias Kati.Sync.Capabilities
  alias Kati.Sync.Change

  @calendars_file "device_calendars.json"
  @instances_file "device_instances.json"
  @deleted_file "device_deleted.json"

  @impl true
  def list_calendars(_account) do
    with {:ok, rows} <- read(@calendars_file) do
      {:ok,
       for row <- rows, is_binary(row["id"]) do
         %{
           remote_id: row["id"],
           display_name: row["display_name"] || row["account_name"] || "Calendar",
           colour: row["color"],
           read_only: row["read_only"] != false
         }
       end}
    end
  end

  @impl true
  def pull(calendar, cursor) do
    with {:ok, rows} <- read(@instances_file),
         {:ok, gone} <- read_optional(@deleted_file) do
      upserts =
        for row <- rows,
            row["calendar_id"] == calendar.remote_id,
            uid = uid_for(row),
            uid != nil do
          Change.upsert(uid,
            remote_id: to_string_or_nil(row["event_id"]),
            # The provider's version of an etag. Not compared with anything
            # from another transport, and not a timestamp.
            etag: to_string_or_nil(row["sync_id"] || row["event_id"]),
            fields: fields(row)
          )
        end

      deletions =
        for row <- gone,
            row["calendar_id"] == calendar.remote_id,
            uid = uid_for(row),
            uid != nil do
          Change.delete(uid, remote_id: to_string_or_nil(row["event_id"]))
        end

      {:ok, upserts ++ deletions, cursor}
    end
  end

  @impl true
  def push(_calendar, operations) do
    Enum.map(operations, &{&1, {:error, :read_only}})
  end

  @impl true
  def capabilities(_account) do
    Capabilities.new(%{
      writable: false,
      # The provider stores RRULE verbatim and expands it itself, correctly,
      # including the RFC 5545 edge cases — but it exposes no VALARM-level or
      # RDATE-level fidelity beyond that.
      recurrence: :rrule_only,
      attachments: false,
      attendees: :ro,
      # No RANGE=THISANDFUTURE. A "this and following" edit would have to be a
      # split, which needs writes, which this transport does not have.
      this_and_future: :unsupported
    })
  end

  # ── Internals ──────────────────────────────────────────────────────────────

  defp read(name) do
    case File.read(Path.join(Mob.data_dir(), name)) do
      {:ok, body} -> decode(body)
      {:error, :enoent} -> {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end

  defp read_optional(name) do
    case read(name) do
      {:ok, rows} -> {:ok, rows}
      _ -> {:ok, []}
    end
  end

  defp decode(body) do
    case Jason.decode(body) do
      {:ok, rows} when is_list(rows) -> {:ok, rows}
      _ -> {:error, :bad_json}
    end
  end

  # Both identifiers, because neither alone is reliable: UID_2445 is reported
  # null on some devices and _SYNC_ID is null for local-only calendars.
  defp uid_for(row) do
    case row["sync_id"] || row["event_id"] do
      nil -> nil
      base -> "#{base}@android"
    end
  end

  defp fields(row) do
    %{
      summary: row["title"],
      location: row["location"],
      description: row["description"],
      tzid: row["timezone"],
      is_all_day: row["all_day"] == true,
      rrule: row["rrule"]
    }
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(value), do: to_string(value)
end
