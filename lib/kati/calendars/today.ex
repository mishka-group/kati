defmodule Kati.Calendars.Today do
  @moduledoc """
  Today's timeline rows, rendered from real events.

  Queries by UTC window rather than by date, because "today" is a wall-clock
  question in the device's zone and the rows are stored as instants.
  """

  require Ash.Query

  alias Kati.Calendars.Event

  @doc "Rows for today, ordered, already formatted for the timeline."
  @spec rows(Date.t() | nil) :: [map()]
  def rows(date \\ nil) do
    zone = Kati.Time.device_zone()
    day = date || Kati.Time.today()

    day
    |> events(zone)
    |> Enum.map(&to_row(&1, zone))
  end

  # One query, shared by the timeline rows and the lane layout, so the two
  # can never disagree about what is on a day.
  defp events(day, zone) do
    with {:ok, from} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[00:00:00]), zone),
         {:ok, to} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[23:59:59]), zone) do
      Event
      |> Ash.Query.filter(is_nil(deleted_at) and dtstart_utc >= ^from and dtstart_utc <= ^to)
      |> Ash.Query.sort(dtstart_utc: :asc)
      |> Ash.read!()
    else
      _ -> []
    end
  rescue
    _ -> []
  end

  @doc """
  The day's timed occurrences as `Kati.Calendar.Layout` input.

  Minutes from midnight in the device zone, all-day events excluded — they
  belong to the band above the gutter and the layout engine has no concept
  of them.
  """
  @spec occurrences(Date.t() | nil) :: [map()]
  def occurrences(date \\ nil) do
    zone = Kati.Time.device_zone()
    day = date || Kati.Time.today()

    day
    |> events(zone)
    |> Enum.reject(& &1.is_all_day)
    |> Enum.map(&to_occurrence(&1, zone, day))
  end

  defp to_occurrence(event, zone, day) do
    start_min = minutes_into(event.dtstart_utc, zone, day)

    end_min =
      case event.dtend_utc do
        nil -> start_min
        dt -> minutes_into(dt, zone, day)
      end

    %{
      id: event.id,
      start_min: start_min,
      # An event running past midnight is clipped to the day it is drawn on,
      # not dropped and not wrapped — the next day draws its own share.
      end_min: min(max(end_min, start_min), 1440),
      kind: event.kind,
      title: event.summary || "Untitled",
      meta: meta(event)
    }
  end

  defp minutes_into(utc, zone, day) do
    local = Kati.Time.in_zone(utc, zone)

    case Date.compare(DateTime.to_date(local), day) do
      :lt -> 0
      :gt -> 1440
      :eq -> local.hour * 60 + local.minute
    end
  end

  defp to_row(event, zone) do
    local = Kati.Time.in_zone(event.dtstart_utc, zone)
    now = DateTime.utc_now()

    %{
      time: Calendar.strftime(local, "%H:%M"),
      title: event.summary || "Untitled",
      meta: meta(event),
      # Orange means new/now, and only that: within the next hour counts as now.
      now?: DateTime.diff(event.dtstart_utc, now, :second) in 0..3600
    }
  end

  defp meta(event) do
    [event.location, kind_label(event.kind)]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" · ")
    |> case do
      "" -> "Calendar"
      s -> s
    end
  end

  defp kind_label(:air_date), do: "Airs today"
  defp kind_label(:meal), do: "Meals"
  defp kind_label(:habit), do: "Habit"
  defp kind_label(:money), do: "Money"
  defp kind_label(_), do: "Calendar"
end
