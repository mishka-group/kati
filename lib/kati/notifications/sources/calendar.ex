defmodule Kati.Notifications.Sources.Calendar do
  @moduledoc """
  Calendar reminders, and the four kinds this source deliberately does not take.

  `Kati.Calendars.Event.kind` is one of seven, and only two of them are this
  source's: `:event` and `:reminder`. The other five each belong to the domain
  that owns them —

    * `:habit` → `Kati.Notifications.Sources.Habits`, which aggregates a day's
      habits into one notification rather than sending four.
    * `:meal` → `Kati.Notifications.Sources.Meals`, which reads the plan's own
      lead time rather than the event's clock.
    * `:money` → `Kati.Notifications.Sources.Money`, which reads the renewal
      date off the service.
    * `:air_date` → `Kati.Notifications.Sources.Media`, which goes through
      `Kati.Media.Release.alarm_at/3`'s gate and so honours a muted show and a
      date nobody was sure about.
    * `:note` — never a notification. A note is a thing you wrote, not a thing
      that happens.

  Taking them here would double every one of them, and it would double them
  **badly**: the same event would arrive once with its own domain's rules
  applied and once with none of them. `Kati.Notifications.Budget` divides a
  fixed number of slots between six domains, so a double is not a duplicate
  notification, it is another domain's reminder deleted.

  ## `tz_behaviour` decides absolute or wall-clock, and the event already knows

  `Kati.Calendars.Event` stores both `dtstart_utc` and `dtstart_wall`, and
  `tz_behaviour` says which one is the truth: a floating event is a wall-clock
  fact that moves with the user, and anything else is an instant. That is
  exactly the distinction `Kati.Notifications.Candidate` draws between
  `wall_clock/5` and `absolute/4`, so this source reads the field rather than
  guessing from whether a zone happens to be set.

  ## All-day events are suppressed, not fired at nine

  An all-day event has no clock. Picking one for it would be inventing a time
  the user never chose, on the one screen whose whole job is to be the day's
  actual shape — so `:all_day` is a suppression with a reason, and screen 05's
  help page can say so. The same holds for a cancelled event: the row is still
  there, and firing it would be worse than saying why it did not.
  """

  require Ash.Query

  alias Kati.Calendars.Event
  alias Kati.Notifications.Candidate

  @own_kinds [:event, :reminder]

  @doc """
  A candidate per event, in `zone`.

  Takes the rows rather than reading them — `events/2` is the reader, and the
  split is `Kati.Notifications.Sources.Media`'s.
  """
  @spec candidates([Event.t()], keyword()) :: [Candidate.t()]
  def candidates(events, opts \\ []) when is_list(events) do
    zone = Keyword.get(opts, :zone) || Kati.Time.device_zone()

    Enum.map(events, &candidate(&1, zone))
  end

  @doc """
  The two `Kati.Calendars.Event` kinds this source takes.

  Public so the claim can be checked rather than trusted:
  `Kati.NotificationSourcesTest` asserts that the three sources reading this
  table claim disjoint kinds, and it can only do that if each one says which.
  """
  @spec own_kinds() :: [atom()]
  def own_kinds, do: @own_kinds

  @doc """
  The day's events of this source's own two kinds.

  Queried by UTC window rather than by date, for the reason
  `Kati.Calendars.Today` gives: *today* is a wall-clock question in the device's
  zone and the rows are stored as instants.
  """
  @spec events(Date.t(), String.t()) :: [Event.t()]
  def events(%Date{} = day, zone) do
    with {:ok, from} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[00:00:00]), zone),
         {:ok, to} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[23:59:59]), zone),
         {:ok, rows} <- read(from, to) do
      rows
    else
      _error -> []
    end
  end

  @doc "The stable id for one event's reminder."
  @spec id(Event.t()) :: String.t()
  def id(%Event{uid: uid}), do: Candidate.id(["cal", uid])

  defp read(from, to) do
    Event
    |> Ash.Query.filter(
      is_nil(deleted_at) and kind in ^@own_kinds and
        dtstart_utc >= ^from and dtstart_utc <= ^to
    )
    |> Ash.Query.sort(dtstart_utc: :asc)
    |> Ash.read()
  rescue
    _error -> :error
  end

  defp candidate(%Event{is_all_day: true} = event, _zone),
    do:
      Candidate.suppressed(id(event), :calendar, :all_day, title: title(event), meta: meta(event))

  defp candidate(%Event{status: :cancelled} = event, _zone),
    do:
      Candidate.suppressed(id(event), :calendar, :cancelled,
        title: title(event),
        meta: meta(event)
      )

  defp candidate(%Event{tz_behaviour: :floating} = event, zone) do
    case wall(event) do
      {:ok, naive} ->
        Candidate.wall_clock(id(event), :calendar, naive, event.tzid || zone,
          title: title(event),
          body: body(event),
          meta: meta(event)
        )

      :error ->
        Candidate.suppressed(id(event), :calendar, :no_date, title: title(event))
    end
  end

  defp candidate(%Event{dtstart_utc: %DateTime{} = at} = event, _zone) do
    Candidate.absolute(id(event), :calendar, at,
      title: title(event),
      body: body(event),
      meta: meta(event)
    )
  end

  defp candidate(%Event{} = event, _zone),
    do: Candidate.suppressed(id(event), :calendar, :no_date, title: title(event))

  # `dtstart_wall` is stored as the string the source wrote. A row whose wall
  # clock does not parse falls back to the instant rather than being dropped:
  # an event with a time is better armed in the wrong zone than not at all,
  # and `tz_behaviour` is the only thing that was floating about it.
  defp wall(%Event{dtstart_wall: wall}) when is_binary(wall) do
    case NaiveDateTime.from_iso8601(wall) do
      {:ok, naive} -> {:ok, naive}
      _error -> :error
    end
  end

  defp wall(%Event{}), do: :error

  defp title(%Event{summary: summary}) when is_binary(summary) and summary != "", do: summary
  defp title(%Event{}), do: "An event"

  defp body(%Event{location: location}) when is_binary(location) and location != "", do: location
  defp body(%Event{kind: :reminder}), do: "Reminder"
  defp body(%Event{}), do: nil

  defp meta(%Event{} = event),
    do: %{uid: event.uid, kind: event.kind, origin: event.origin}
end
