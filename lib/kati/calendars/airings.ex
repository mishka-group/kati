defmodule Kati.Calendars.Airings do
  @moduledoc """
  The episodes of followed shows that air on a day, as timeline rows.

  Nothing writes an airing into `Kati.Calendars.Event`: an event carries
  `uid`, `summary` and `location` and no `{source, source_id}` pair, so a row
  stored there could never reach the show that produced it — its poster, its
  `S2 · E3` line, or the series page a tap should open (L4). So an airing is
  not stored as an event at all. It is read at render time from the one place
  the date lives, `Kati.Media.CachedEpisode.air_at`, joined to its show by
  `title_source_id` — the value pair `Kati.Screens.Inbox` already joins on —
  and carries everything the row needs because it came from the show.

  ## Which shows, and which dates

  A show is on the calendar when it is `Kati.Media.TrackedTitle`'s `:followed`
  read — not archived, not finished, not dropped — and its own
  `add_air_dates_to_calendar` switch is on. That switch has been on the row
  since the schema existed; this is its reader.

  A date is read through `Kati.Media.Release.air/1` and nothing else, so #74's
  rule holds here as it does everywhere: an `:exact` airing lands at its hour
  in the device's zone, a `:day` airing (TMDB's bare `air_date`) lands on its
  day with no hour — *All day* — and anything coarser never lands on a day at
  all.

  ## One row per show

  A streaming service drops a whole season on one day. Eight rows of the same
  show would push the reader's own day off the screen, so a show's episodes on
  one day are one row: its title, its poster, the first episode's `S# · E#`,
  and the count when there is more than one.

  ## Films, on the day they come out

  A followed film has no episodes, but it has a date: `Kati.Media.Release.resolve/2`
  over its cached title, where a `user_override_date` wins — the same read
  `Kati.Screens.Inbox` lists a film's release with. It lands by the same
  `:exact`/`:day` rule and carries `tracked_kind: :film`, which is what sends a
  tap to the film page rather than to a series page. The date is the one the
  store holds — `next_release_at` is the NEXT release — so the day moves when
  a source moves it, and a film nobody has dated to the day lands nowhere.

  ## On screen 09

  `occurrences/1` is the same rows in `Kati.Calendar.Layout`'s shape, for the
  ones with an hour. A day-only airing has no minute to lane at, and screen 09
  draws no all-day band, so it stays on 02, 16, 17 and 30.
  """

  use Gettext, backend: Kati.Gettext

  require Ash.Query

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle

  @typedoc """
  One airing row: the `Kati.Calendars.Today` row shape, plus the show.

  `kind` is `:air_date` and `id` is `nil`, because there is no event. `at` is
  the instant it airs for an `:exact` date and `nil` for an all-day one;
  `tracked_id` is the followed `Kati.Media.TrackedTitle` a tap opens, and
  `seed` is that show's `Kati.Media.CachedTitle.poster_path`.
  """
  @type row :: %{
          id: nil,
          tracked_id: String.t(),
          tracked_kind: :series | :film,
          kind: :air_date,
          location: nil,
          title: String.t(),
          meta: String.t(),
          seed: String.t() | nil,
          time: String.t(),
          at: DateTime.t() | nil,
          now?: boolean()
        }

  @doc """
  The day's airings, all-day ones first and then by the hour they air.

  `[]` for a store that cannot be read: the calendar still draws the reader's
  own day.
  """
  @spec rows(Date.t() | nil) :: [row()]
  def rows(date \\ nil) do
    day = date || Kati.Time.today()
    Map.get(by_day(day, day), day, [])
  end

  @doc """
  Every airing from `from` to `to` inclusive, keyed by the day it lands on in
  the device's zone, each day ordered the way `rows/1` orders one.

  One read of the followed shows and one of their episodes for the whole run,
  which is what lets a month grid put a dot under each day without asking the
  store forty-two times. A day with nothing airing has no key.
  """
  @spec by_day(Date.t(), Date.t()) :: %{Date.t() => [row()]}
  def by_day(%Date{} = from, %Date{} = to) do
    zone = Kati.Time.device_zone()

    case shows() do
      [] ->
        %{}

      tracked ->
        cache = cached_titles(tracked)

        tracked
        |> airing_between(cache, from, to, zone)
        |> Map.merge(releasing_between(tracked, cache, from, to, zone), fn _day, a, b ->
          a ++ b
        end)
        |> Map.new(fn {day, rows} -> {day, Enum.sort_by(rows, &order/1)} end)
    end
  rescue
    _error -> %{}
  end

  @doc """
  The episode line: `S2 · E3`, and the count when a show airs more than one.

      iex> Kati.Locale.as(:en, fn ->
      ...>   Kati.Calendars.Airings.episode_line(%{season_number: 2, episode_number: 3}, 1)
      ...> end)
      "S2 · E3"

      iex> Kati.Locale.as(:en, fn ->
      ...>   Kati.Calendars.Airings.episode_line(%{season_number: 1, episode_number: 1}, 8)
      ...> end)
      "S1 · E1 · 8 episodes"

      iex> Kati.Locale.as(:fa, fn ->
      ...>   Kati.Calendars.Airings.episode_line(%{season_number: 2, episode_number: 3}, 1)
      ...> end)
      "ف۲ · ق۳"

  An episode a source never placed — a special with no numbers — is named by
  the count alone rather than by a number invented for it.
  """
  @spec episode_line(map(), pos_integer()) :: String.t()
  def episode_line(%{season_number: s, episode_number: e}, count)
      when is_integer(s) and is_integer(e) do
    line = gettext("S%{s} · E%{e}", s: Kati.Locale.number(s), e: Kati.Locale.number(e))
    if count > 1, do: line <> " · " <> episodes(count), else: line
  end

  def episode_line(_episode, count), do: episodes(count)

  defp episodes(count),
    do: ngettext("%{n} episode", "%{n} episodes", count, n: Kati.Locale.number(count))

  defp shows do
    TrackedTitle
    |> Ash.Query.for_read(:followed)
    |> Ash.read!()
    |> Enum.filter(& &1.add_air_dates_to_calendar)
  end

  defp airing_between(tracked, cache, from, to, zone) do
    by_show = Map.new(tracked, &{{&1.source, &1.source_id}, &1})

    tracked
    |> episodes_near(from, to)
    |> Enum.filter(&Map.has_key?(by_show, {&1.source, &1.title_source_id}))
    |> Enum.flat_map(fn episode ->
      case landing(Release.air(episode), zone) do
        {day, landed} -> if within?(day, from, to), do: [{day, episode, landed}], else: []
        nil -> []
      end
    end)
    |> Enum.group_by(fn {day, episode, _landed} ->
      {day, {episode.source, episode.title_source_id}}
    end)
    |> Enum.group_by(
      fn {{day, _key}, _aired} -> day end,
      fn {{_day, key}, aired} ->
        aired = Enum.map(aired, fn {_day, episode, landed} -> {episode, landed} end)
        row(Map.fetch!(by_show, key), Map.get(cache, key), aired, zone)
      end
    )
  end

  defp releasing_between(tracked, cache, from, to, zone) do
    tracked
    |> Enum.filter(&(&1.kind == :movie))
    |> Enum.flat_map(fn film ->
      cached = Map.get(cache, {film.source, film.source_id})

      case landing(Release.resolve(film, cached), zone) do
        {day, landed} ->
          if within?(day, from, to), do: [{day, film_row(film, cached, landed, zone)}], else: []

        nil ->
          []
      end
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  defp film_row(film, cached, landed, zone) do
    at =
      case landed do
        {:at, at} -> at
        :all_day -> nil
      end

    %{
      id: nil,
      tracked_id: film.id,
      tracked_kind: :film,
      kind: :air_date,
      location: nil,
      title: (cached && cached.title) || gettext("Untitled"),
      meta: gettext("Film release"),
      seed: cached && cached.poster_path,
      time: if(at, do: Kati.Locale.time(Kati.Time.in_zone(at, zone)), else: gettext("All day")),
      at: at,
      now?: false
    }
  end

  @doc """
  The day's airings and releases that have an hour, as `Kati.Calendar.Layout`
  occurrences for screen 09: the minute each lands at, no length, and the
  row's own title, line, poster and show.
  """
  @spec occurrences(Date.t()) :: [map()]
  def occurrences(%Date{} = date) do
    zone = Kati.Time.device_zone()

    for %{at: %DateTime{} = at} = row <- rows(date) do
      local = Kati.Time.in_zone(at, zone)
      minute = local.hour * 60 + local.minute

      %{
        id: "airing_" <> row.tracked_id,
        tracked_id: row.tracked_id,
        tracked_kind: row.tracked_kind,
        start_min: minute,
        end_min: minute,
        kind: :air_date,
        location: nil,
        title: row.title,
        meta: row.meta,
        seed: row.seed
      }
    end
  end

  defp within?(day, from, to),
    do: Date.compare(day, from) != :lt and Date.compare(day, to) != :gt

  # A day either side of the run asked for, because `air_at` is UTC and the
  # day is the device's: an 01:00 airing in Tehran is stored the evening
  # before. `landing/2` is what decides the day; this only bounds the read.
  defp episodes_near(tracked, first, last) do
    from = DateTime.new!(Date.add(first, -1), ~T[00:00:00], "Etc/UTC")
    to = DateTime.new!(Date.add(last, 2), ~T[00:00:00], "Etc/UTC")
    ids = tracked |> Enum.map(& &1.source_id) |> Enum.uniq()

    CachedEpisode
    |> Ash.Query.filter(title_source_id in ^ids and air_at >= ^from and air_at < ^to)
    |> Ash.read!()
  end

  defp cached_titles(tracked) do
    ids = tracked |> Enum.map(& &1.source_id) |> Enum.uniq()

    CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  end

  defp landing({:exact, at, _origin}, zone),
    do: {DateTime.to_date(Kati.Time.in_zone(at, zone)), {:at, at}}

  defp landing({:day, date, _origin}, _zone), do: {date, :all_day}
  defp landing(_coarse, _zone), do: nil

  defp row(tracked, cached, aired, zone) do
    [{first, _landed} | _rest] = Enum.sort_by(aired, &episode_order/1)
    at = aired |> Enum.flat_map(&instant/1) |> Enum.min(DateTime, fn -> nil end)

    %{
      id: nil,
      tracked_id: tracked.id,
      tracked_kind: :series,
      kind: :air_date,
      location: nil,
      title: (cached && cached.title) || gettext("Untitled"),
      meta: episode_line(first, length(aired)),
      seed: cached && cached.poster_path,
      time: if(at, do: Kati.Locale.time(Kati.Time.in_zone(at, zone)), else: gettext("All day")),
      at: at,
      now?: false
    }
  end

  defp instant({_episode, {:at, at}}), do: [at]
  defp instant({_episode, :all_day}), do: []

  defp episode_order({episode, _landed}),
    do: {episode.season_number || 0, episode.episode_number || 0}

  defp order(%{at: nil, title: title}), do: {0, 0, title}
  defp order(%{at: at, title: title}), do: {1, DateTime.to_unix(at, :microsecond), title}
end
