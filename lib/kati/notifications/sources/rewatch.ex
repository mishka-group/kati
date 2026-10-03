defmodule Kati.Notifications.Sources.Rewatch do
  @moduledoc """
  Rewatch reminders: a title the reader loved, on the anniversary of the last
  time they watched it (#125).

  *Loved* is a rating of 8 or more out of 10 — four stars — on the title's own
  log, not an episode's. The reminder fires at 19:00 on the day, a year or
  more after that last watch, and only while the day is within the next
  `@horizon_days`: further out, a rewatch in between would make it wrong.

  One candidate per title, with an id that names the year, so next year's is a
  new reminder rather than this one again.
  """
  use Gettext, backend: Kati.Gettext

  require Ash.Query

  alias Kati.Media.Watch
  alias Kati.Notifications.Candidate

  @loved 8
  @horizon_days 30
  @at ~T[19:00:00]

  @doc "The rewatch candidates whose anniversary falls within the horizon."
  @spec candidates(Date.t(), String.t()) :: [Candidate.t()]
  def candidates(today \\ Kati.Time.today(), zone \\ Kati.Time.device_zone()) do
    Watch
    |> Ash.Query.filter(is_nil(episode_source_id) and not is_nil(watched_at))
    |> Ash.read!()
    |> Enum.group_by(& &1.tracked_title_id)
    |> Enum.flat_map(fn {tracked_id, watches} ->
      Kati.Notifications.Sources.Rewatch.candidate(tracked_id, watches, today, zone)
    end)
  rescue
    _error -> []
  end

  @doc false
  def candidate(tracked_id, watches, today, zone) do
    last = Enum.max_by(watches, & &1.watched_at, DateTime)
    loved? = Enum.any?(watches, &(is_integer(&1.rating) and &1.rating >= @loved))
    watched_on = last.watched_at |> Kati.Time.in_zone(zone) |> DateTime.to_date()

    with true <- loved?,
         %Date{} = day <- Kati.Notifications.Sources.Rewatch.anniversary(watched_on, today),
         true <- Date.diff(day, today) <= @horizon_days,
         {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, tracked_id),
         false <- tracked.archived do
      years = day.year - watched_on.year
      cached = Kati.Media.Release.cached_for(tracked)
      title = (cached && cached.title) || tracked.source_id

      [
        Candidate.wall_clock(
          Candidate.id(["rem", "rw", tracked_id, Integer.to_string(day.year)]),
          :calendar,
          NaiveDateTime.new!(day, @at),
          zone,
          title: title,
          body:
            ngettext(
              "You watched it a year ago today. Watch it again?",
              "You watched it %{n} years ago today. Watch it again?",
              years,
              n: Kati.Locale.number(years)
            ),
          meta: %{tracked_id: tracked_id, kind: tracked.kind}
        )
      ]
    else
      _not_now -> []
    end
  end

  @doc """
  The next anniversary of `watched_on` that is today or later and at least a
  year after it; `nil` for a watch less than a year old.

      iex> Kati.Notifications.Sources.Rewatch.anniversary(~D[2024-10-10], ~D[2026-10-03])
      ~D[2026-10-10]
      iex> Kati.Notifications.Sources.Rewatch.anniversary(~D[2024-09-01], ~D[2026-10-03])
      ~D[2027-09-01]
      iex> Kati.Notifications.Sources.Rewatch.anniversary(~D[2026-05-01], ~D[2026-10-03])
      ~D[2027-05-01]
      iex> Kati.Notifications.Sources.Rewatch.anniversary(~D[2024-02-29], ~D[2026-10-03])
      ~D[2027-02-28]
  """
  @spec anniversary(Date.t(), Date.t()) :: Date.t()
  def anniversary(watched_on, today) do
    this_year = on(watched_on, today.year)

    cond do
      Date.compare(this_year, today) != :lt and today.year > watched_on.year -> this_year
      true -> on(watched_on, max(today.year + 1, watched_on.year + 1))
    end
  end

  defp on(%Date{month: 2, day: 29}, year) do
    if Calendar.ISO.leap_year?(year), do: Date.new!(year, 2, 29), else: Date.new!(year, 2, 28)
  end

  defp on(%Date{month: m, day: d}, year), do: Date.new!(year, m, d)
end
