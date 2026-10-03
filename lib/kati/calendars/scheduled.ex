defmodule Kati.Calendars.Scheduled do
  @moduledoc """
  A title's next scheduled watch: the event a *Schedule* on its page made
  (#124), so the page can say when instead of offering to schedule again.
  """
  require Ash.Query

  alias Kati.Calendars.Event

  @doc "The next event scheduled for `tracked_id` that has not started, or `nil`."
  @spec next(String.t() | nil, DateTime.t()) :: Event.t() | nil
  def next(tracked_id, now \\ Kati.Time.now())

  def next(tracked_id, now) when is_binary(tracked_id) do
    Event
    |> Ash.Query.filter(
      tracked_title_id == ^tracked_id and is_nil(deleted_at) and dtstart_utc >= ^now
    )
    |> Ash.Query.sort(dtstart_utc: :asc)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  rescue
    _error -> nil
  end

  def next(_none, _now), do: nil

  @doc """
  The pill's word for a scheduled watch: the weekday and the time, as the
  reader's calendar writes them.
  """
  @spec label(Event.t()) :: String.t()
  def label(%Event{dtstart_utc: at}) do
    local = Kati.Time.in_zone(at, Kati.Time.device_zone())
    Kati.Screens.WhatFits.weekday(local) <> " " <> Kati.Locale.time(local)
  end
end
