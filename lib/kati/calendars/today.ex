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
    today = date || DateTime.utc_now() |> Kati.Time.in_zone(zone) |> DateTime.to_date()

    with {:ok, from} <- Kati.Time.to_utc(NaiveDateTime.new!(today, ~T[00:00:00]), zone),
         {:ok, to} <- Kati.Time.to_utc(NaiveDateTime.new!(today, ~T[23:59:59]), zone) do
      Event
      |> Ash.Query.filter(is_nil(deleted_at) and dtstart_utc >= ^from and dtstart_utc <= ^to)
      |> Ash.Query.sort(dtstart_utc: :asc)
      |> Ash.read!()
      |> Enum.map(&to_row(&1, zone))
    else
      _ -> []
    end
  rescue
    _ -> []
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
