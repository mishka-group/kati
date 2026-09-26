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
    zone = Kati.Time.device_zone()

    case shows() do
      [] -> []
      tracked -> tracked |> airing_on(day, zone) |> Enum.sort_by(&order/1)
    end
  rescue
    _error -> []
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

  defp airing_on(tracked, day, zone) do
    by_show = Map.new(tracked, &{{&1.source, &1.source_id}, &1})
    cache = cached_titles(tracked)

    tracked
    |> episodes_near(day)
    |> Enum.filter(&Map.has_key?(by_show, {&1.source, &1.title_source_id}))
    |> Enum.flat_map(fn episode ->
      case landing(Release.air(episode), day, zone) do
        nil -> []
        landed -> [{episode, landed}]
      end
    end)
    |> Enum.group_by(fn {episode, _landed} -> {episode.source, episode.title_source_id} end)
    |> Enum.map(fn {key, aired} ->
      row(Map.fetch!(by_show, key), Map.get(cache, key), aired, zone)
    end)
  end

  # A day either side of the one asked for, because `air_at` is UTC and the
  # day is the device's: an 01:00 airing in Tehran is stored the evening
  # before. `landing/3` is what decides the day; this only bounds the read.
  defp episodes_near(tracked, day) do
    from = DateTime.new!(Date.add(day, -1), ~T[00:00:00], "Etc/UTC")
    to = DateTime.new!(Date.add(day, 2), ~T[00:00:00], "Etc/UTC")
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

  defp landing({:exact, at, _origin}, day, zone) do
    if DateTime.to_date(Kati.Time.in_zone(at, zone)) == day, do: {:at, at}
  end

  defp landing({:day, date, _origin}, day, _zone), do: if(date == day, do: :all_day)
  defp landing(_coarse, _day, _zone), do: nil

  defp row(tracked, cached, aired, zone) do
    [{first, _landed} | _rest] = Enum.sort_by(aired, &episode_order/1)
    at = aired |> Enum.flat_map(&instant/1) |> Enum.min(DateTime, fn -> nil end)

    %{
      id: nil,
      tracked_id: tracked.id,
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
