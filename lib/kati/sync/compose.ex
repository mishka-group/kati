defmodule Kati.Sync.Compose do
  @moduledoc """
  Kati's columns, turned into iCalendar properties — the *only* direction that
  is ever allowed to generate.

  Reading is the other way round and never happens here: an incoming document
  keeps its own bytes and `Kati.Sync.ICalendar` patches them. This module
  exists for the two cases where there are no bytes yet or where Kati is
  stating a change:

    * `changed/1` — the properties one local edit touched, which is what the
      push patches the base with. Only what changed; a field the user did not
      touch produces no property and therefore no write.
    * `event/1` — a full property set for an `origin: :kati` event's very first
      push, where there is genuinely no server document to preserve.

  ## `DTSTART` is not one column

  A start time is `dtstart_date` for an all-day event (a date, never a midnight
  instant — otherwise it moves a day when the user flies to Tehran),
  `dtstart_wall` plus `TZID` for a zoned one, `dtstart_wall` alone for a
  floating one, and `dtstart_utc` only as a last resort. The parameters are part
  of the value, which is why the property map is keyed by name and holds whole
  content lines.

  ## `DURATION` alongside `RRULE`

  Emitted whenever there is a recurrence rule, because the Android provider
  **requires** `DURATION` next to `RRULE`/`RDATE` and rejects the row without
  it. It is also the right canonical form on every other transport: a one-hour
  event crossing spring-forward is one hour by `DURATION` and two by wall-clock
  `DTEND`.
  """

  alias Kati.Calendars.Event
  alias Kati.Sync.ICalendar

  @field_property %{
    summary: "SUMMARY",
    location: "LOCATION",
    description: "DESCRIPTION",
    rrule: "RRULE",
    duration_iso: "DURATION",
    status: "STATUS",
    transp: "TRANSP",
    organizer: "ORGANIZER"
  }

  @doc """
  The properties one edit changed.

  Values come back as whole content lines, TEXT-escaped where RFC 5545 says the
  value type is TEXT, because a line is the unit `Kati.Sync.ICalendar` and
  `Kati.Sync.Merge` both work in. A caller with a property Kati does not model
  passes it through `:properties`, already formed as a line, because only the
  caller knows its parameters.
  """
  @spec changed(map()) :: %{String.t() => String.t() | nil}
  def changed(changes) do
    mapped =
      changes
      |> Map.drop([:properties])
      |> Enum.reduce(%{}, fn {field, value}, acc ->
        case Map.fetch(@field_property, field) do
          {:ok, name} -> Map.put(acc, name, ICalendar.content_line(name, encode(value)))
          :error -> acc
        end
      end)

    Map.merge(mapped, Map.get(changes, :properties, %{}))
  end

  @doc """
  Every property a first push needs.

  `UID` is included and is client-generated: without a client-chosen identifier
  there is no idempotency key, and without an idempotency key every network
  timeout risks a duplicate event.
  """
  @spec event(Event.t()) :: %{String.t() => String.t() | nil}
  def event(%Event{} = row) do
    %{"UID" => "UID:" <> row.uid}
    |> put("SUMMARY", row.summary)
    |> put("LOCATION", row.location)
    |> put("DESCRIPTION", row.description)
    |> put("STATUS", encode(row.status))
    |> put("TRANSP", encode(row.transp))
    |> put("RRULE", row.rrule)
    |> Map.merge(dtstart(row))
    |> Map.merge(duration(row))
  end

  @doc """
  The `DTSTART` line for a row, as a one-entry map.

  Public because the editor needs the same rendering when it previews what
  would be written, and two renderings of a start time is one too many.
  """
  @spec dtstart(Event.t()) :: %{String.t() => String.t()}
  def dtstart(%Event{is_all_day: true, dtstart_date: %Date{} = date}) do
    %{"DTSTART" => "DTSTART;VALUE=DATE:" <> Calendar.strftime(date, "%Y%m%d")}
  end

  def dtstart(%Event{dtstart_wall: wall, tzid: tzid}) when is_binary(wall) and is_binary(tzid) do
    %{"DTSTART" => "DTSTART;TZID=#{tzid}:#{wall}"}
  end

  # No TZID is not a missing value: it is a floating time, "09:00 wherever you
  # are", which is the right model for a habit or a meal slot.
  def dtstart(%Event{dtstart_wall: wall}) when is_binary(wall) do
    %{"DTSTART" => "DTSTART:" <> wall}
  end

  def dtstart(%Event{dtstart_utc: %DateTime{} = utc}) do
    %{"DTSTART" => "DTSTART:" <> Calendar.strftime(utc, "%Y%m%dT%H%M%SZ")}
  end

  def dtstart(%Event{}), do: %{}

  defp duration(%Event{duration_iso: iso}) when is_binary(iso),
    do: %{"DURATION" => "DURATION:" <> iso}

  # The Android provider rejects a recurring row that has no DURATION, so a
  # missing one is filled rather than omitted. An hour is the calendar default
  # everywhere and is visibly wrong if it is wrong, which a zero-length event
  # is not.
  defp duration(%Event{rrule: rrule}) when is_binary(rrule), do: %{"DURATION" => "DURATION:PT1H"}
  defp duration(%Event{}), do: %{}

  defp put(map, _name, nil), do: map
  defp put(map, name, value), do: Map.put(map, name, ICalendar.content_line(name, value))

  defp encode(nil), do: nil
  defp encode(value) when is_atom(value), do: value |> Atom.to_string() |> String.upcase()
  defp encode(value) when is_binary(value), do: value
  defp encode(value), do: to_string(value)
end
