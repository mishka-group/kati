defmodule Kati.Calendars.DeviceImport do
  @moduledoc """
  Ingests the device's calendars from the JSON `KatiCalendarReader` publishes.

  ## Why a file rather than a call

  There is no Elixir→Kotlin call path without adding a NIF, and Mob's NIF table
  lives in the `mob` package rather than the app. So the reader **publishes** on
  app start and Kati ingests on foreground — S-12's architecture, used here for a
  structural reason rather than convenience.

  It also happens to match the data: Android's sync adapters keep the provider
  fresh whether or not Kati is running, so foreground is both when the data is
  newest and when the user can see it.

  ## What is imported, and what is deliberately not

  Rows land with `origin: :mirror`, which is **immutable** — so nothing can later
  mistake a mirrored event for one Kati owns and push it to a server that never
  asked for it.

  Instances are imported, not masters. The provider has already expanded
  recurrence (correctly, including RFC 5545 edge cases), so re-expanding Kati's
  own copy would be duplicating work the OS did better. `rrule` is stored for
  round-tripping but not re-expanded.

  Identity is `{sync_id, event_id}`, storing **both**. `_SYNC_ID` is the usual
  cross-device identity, but `UID_2445` is reported null on some devices and
  `_SYNC_ID` is null for local-only calendars — so neither alone is safe as a
  key, and the pair with the calendar is.
  """

  require Ash.Query
  require Logger

  # Deliberately NOT aliasing Kati.Calendars.Calendar: it would shadow Elixir's
  # Calendar, and Calendar.strftime/2 is used below.
  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.Event

  @calendars_file "device_calendars.json"
  @instances_file "device_instances.json"

  @doc """
  Read the published JSON and upsert calendars and events.

  Returns `{:ok, %{calendars: n, events: n}}`, or `{:ok, :no_data}` when the
  reader has not published — which is the normal state before the permission is
  granted, not an error.
  """
  @spec run() :: {:ok, map() | :no_data} | {:error, term()}
  def run do
    with {:ok, cal_json} <- read(@calendars_file),
         {:ok, inst_json} <- read(@instances_file),
         {:ok, calendars} <- decode(cal_json),
         {:ok, instances} <- decode(inst_json) do
      cal_map = Enum.into(import_calendars(calendars), %{})
      count = import_instances(instances, cal_map)
      {:ok, %{calendars: map_size(cal_map), events: count}}
    else
      :no_file -> {:ok, :no_data}
      {:error, reason} -> {:error, reason}
    end
  end

  defp read(name) do
    path = Path.join(Mob.data_dir(), name)

    case File.read(path) do
      {:ok, body} -> {:ok, body}
      {:error, :enoent} -> :no_file
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode(body) do
    case Jason.decode(body) do
      {:ok, list} when is_list(list) -> {:ok, list}
      _ -> {:error, :bad_json}
    end
  end

  defp import_calendars(rows) do
    for row <- rows, id = row["id"], is_binary(id) do
      attrs = %{
        remote_id: id,
        display_name: row["display_name"] || row["account_name"] || "Calendar",
        colour_source: row["color"],
        kind: :provider,
        read_only: row["read_only"] != false,
        visible: row["visible"] != false,
        # The device provider is a mirror. Write-back is #54's decision and
        # needs WRITE_CALENDAR, which Kati does not request.
        writeback_policy: :none
      }

      {id, upsert_calendar(id, attrs)}
    end
  end

  defp upsert_calendar(remote_id, attrs) do
    case CalendarRow |> Ash.Query.filter(remote_id == ^remote_id) |> Ash.read_one() do
      {:ok, %CalendarRow{} = existing} ->
        {:ok, updated} = existing |> Ash.Changeset.for_update(:update, attrs) |> Ash.update()
        updated.id

      _ ->
        {:ok, created} = CalendarRow |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()
        created.id
    end
  end

  defp import_instances(rows, cal_map) do
    Enum.count(rows, fn row -> import_instance(row, cal_map) == :ok end)
  end

  defp import_instance(row, cal_map) do
    with calendar_id when is_binary(calendar_id) <- cal_map[row["calendar_id"]],
         begin_ms when is_integer(begin_ms) <- row["begin_ms"] do
      all_day = row["all_day"] == true
      uid = uid_for(row)

      attrs =
        %{
          uid: uid,
          calendar_id: calendar_id,
          origin: :mirror,
          summary: row["title"],
          location: row["location"],
          description: row["description"],
          tzid: row["timezone"],
          is_all_day: all_day,
          rrule: row["rrule"],
          kind: :event,
          remote_id: row["event_id"],
          sync_state: :clean,
          status: status_for(row["status"])
        }
        |> Map.merge(timing(begin_ms, row["end_ms"], all_day, row["timezone"]))

      upsert_event(uid, calendar_id, attrs)
    else
      _ -> :skip
    end
  end

  # Both identifiers, because neither alone is reliable: UID_2445 is reported
  # null on some devices and _SYNC_ID is null for local-only calendars.
  defp uid_for(row) do
    base = row["sync_id"] || row["event_id"] || "unknown"
    "#{base}@android"
  end

  defp status_for(1), do: :confirmed
  defp status_for(2), do: :cancelled
  defp status_for(0), do: :tentative
  defp status_for(_), do: nil

  defp timing(begin_ms, end_ms, true, _tz) do
    date = begin_ms |> DateTime.from_unix!(:millisecond) |> DateTime.to_date()
    # All-day events are date-valued. Storing a midnight instant is what makes
    # them shift a day when the user flies.
    %{dtstart_date: date, dtstart_utc: nil, dtstart_wall: nil, duration_iso: "P1D"}
  end

  defp timing(begin_ms, end_ms, false, tz) do
    start = DateTime.from_unix!(begin_ms, :millisecond)
    zone = if is_binary(tz) and Kati.Time.valid_zone?(tz), do: tz, else: "Etc/UTC"
    wall = start |> Kati.Time.in_zone(zone) |> DateTime.to_naive()

    duration =
      case end_ms do
        e when is_integer(e) and e > begin_ms -> "PT#{div(e - begin_ms, 1000)}S"
        _ -> "PT1H"
      end

    %{
      dtstart_utc: start,
      dtstart_wall: Calendar.strftime(wall, "%Y%m%dT%H%M%S"),
      duration_iso: duration
    }
  end

  defp upsert_event(uid, calendar_id, attrs) do
    existing =
      Event
      |> Ash.Query.filter(uid == ^uid and calendar_id == ^calendar_id)
      |> Ash.read_one()

    case existing do
      {:ok, %Event{} = row} ->
        row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update()
        :ok

      _ ->
        case Event |> Ash.Changeset.for_create(:create, attrs) |> Ash.create() do
          {:ok, _} -> :ok
          {:error, _} -> :skip
        end
    end
  end
end
