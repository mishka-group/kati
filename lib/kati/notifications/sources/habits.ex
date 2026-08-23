defmodule Kati.Notifications.Sources.Habits do
  @moduledoc """
  Habit reminders, aggregated into one notification per clock time.

  A habit is a `Kati.Calendars.Event` with `kind: :habit` — screen 22 counts
  them and the calendar stores them, and there is no second table.
  `Kati.Notifications.Sources.Calendar` deliberately leaves this kind alone so
  that the aggregation below happens exactly once.

  ## Four habits at 08:00 is one notification, and that is the whole design

  `Kati.Notifications.Budget` gives `:habits` eighty Android slots and **eight**
  on iOS. A user with four daily habits would spend half the iOS allocation on
  a single morning if each one armed itself, and would be told the same thing
  four times in a row — which is how a person learns to swipe the notification
  away without reading it.

  So habits due at the same wall-clock time become one candidate whose
  `members` name them. The title counts, the body lists, and the sheet behind
  it can still tick them individually.

  ## Wall-clock, always

  *Read for twenty minutes at 21:00* means 21:00 wherever you are. A habit that
  shifted with a flight would be a habit you broke by travelling, which is the
  one thing a streak must not do to somebody — so these are wall-clock
  candidates regardless of what `tz_behaviour` the calendar row carries. It is
  the one place this app overrides an event's own field, and the reason is that
  a habit is not an appointment: nobody else is waiting at the other end of it.
  """

  require Ash.Query

  alias Kati.Calendars.Event
  alias Kati.Notifications.Candidate

  @own_kinds [:habit]

  @doc """
  The one `Kati.Calendars.Event` kind this source takes.

  Public for the same reason `Kati.Notifications.Sources.Calendar.own_kinds/0`
  is: three sources read one table, and a kind claimed twice is not a duplicate
  notification but another domain's reminder deleted.
  """
  @spec own_kinds() :: [atom()]
  def own_kinds, do: @own_kinds

  @doc """
  One candidate per clock time on `day`, aggregating the habits due at each.

  Takes the rows rather than reading them — `events/2` is the reader.
  `opts` takes `:zone`.
  """
  @spec candidates([Event.t()], Date.t(), keyword()) :: [Candidate.t()]
  def candidates(events, %Date{} = day, opts \\ []) when is_list(events) do
    zone = Keyword.get(opts, :zone) || Kati.Time.device_zone()

    events
    |> Enum.group_by(&clock(&1, zone))
    |> Enum.sort_by(fn {time, _group} -> time || ~T[23:59:59] end)
    |> Enum.map(fn {time, group} -> group_candidate(day, time, group, zone) end)
  end

  @doc "The day's habit events."
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

  @doc """
  The stable id for one clock time's habit group.

  The clock goes in colon-free — `07:00:00` becomes `070000` — because
  `Kati.Notifications.Candidate.id/1` refuses a part containing a colon, so
  that an id cannot be built two ways from two identities and collide.
  """
  @spec id(Date.t(), Time.t() | nil) :: String.t()
  def id(%Date{} = day, %Time{} = time),
    do: Candidate.id(["habit", day, time |> Time.to_string() |> String.replace(":", "")])

  def id(%Date{} = day, nil), do: Candidate.id(["habit", day, "untimed"])

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

  # An all-day habit has no clock, and it groups under `nil` rather than being
  # dropped: *tick this today* is a real habit and its group is suppressed with
  # a reason, which is what makes screen 05's help page able to explain it.
  defp clock(%Event{is_all_day: true}, _zone), do: nil

  defp clock(%Event{dtstart_utc: %DateTime{} = at}, zone) do
    at |> Kati.Time.in_zone(zone) |> DateTime.to_time() |> Time.truncate(:second)
  end

  defp clock(%Event{}, _zone), do: nil

  defp group_candidate(day, nil, group, _zone) do
    Candidate.suppressed(id(day, nil), :habits, :all_day,
      title: title(group),
      members: Enum.map(group, & &1.uid),
      meta: %{count: length(group)}
    )
  end

  defp group_candidate(day, %Time{} = time, group, zone) do
    Candidate.wall_clock(id(day, time), :habits, NaiveDateTime.new!(day, time), zone,
      title: title(group),
      body: body(group),
      members: Enum.map(group, & &1.uid),
      meta: %{count: length(group), at: Time.to_string(time)}
    )
  end

  defp title([%Event{} = one]), do: label(one)
  defp title(group), do: "#{length(group)} habits"

  defp body([%Event{}]), do: "Due now"
  defp body(group), do: Enum.map_join(group, ", ", &label/1)

  defp label(%Event{summary: summary}) when is_binary(summary) and summary != "", do: summary
  defp label(%Event{}), do: "A habit"
end
