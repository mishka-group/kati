defmodule Kati.Background.Watchlist do
  @moduledoc """
  What the background worker checks while Kati is closed, decided here (#125).

  `KatiRefreshWorker` runs every few hours with no BEAM — the BEAM cannot start
  without the activity — so it cannot ask what to look for. This writes the
  answer down for it, through `Kati.Background.Handoff.put_watchlist/2`:

    * **items** — every followed show or anime whose new episodes the reader
      wants (`notify_new_episodes`, the *Tell me about: New episodes* switch),
      from a source the worker can ask without the BEAM (TMDB, TVmaze,
      AniList), each with the latest episode Kati already knows has aired. The
      worker tells the reader only about episodes after that one.
    * **settings** — whether push is on, and the quiet-hours window.
    * **strings** — the notification's words in the reader's language, and the
      digits to write numbers in. The worker formats; it never translates.

  Written at boot, after every refresh sweep, and whenever the Library comes
  back on top, so it follows the shelf closely enough for a check every few
  hours.
  """
  use Gettext, backend: Kati.Gettext

  alias Kati.Background.Handoff
  alias Kati.Media.CachedEpisode
  alias Kati.Media.TrackedTitle
  alias Kati.Settings.Watcher

  @sources [:tmdb, :tvmaze, :anilist]

  @doc "Build the watchlist and write it. `{:ok, count}` or `{:error, reason}`."
  @spec write(keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  def write(opts \\ []) do
    Handoff.put_watchlist(
      Kati.Background.Watchlist.entries(),
      Keyword.merge(
        [
          settings: Kati.Background.Watchlist.settings(),
          strings: Kati.Background.Watchlist.strings()
        ],
        opts
      )
    )
  rescue
    error -> {:error, error}
  end

  @doc "Write it off the caller's process."
  @spec write_later() :: :ok
  def write_later do
    Task.Supervisor.start_child(Kati.TaskSupervisor, fn -> Kati.Background.Watchlist.write() end)
    :ok
  catch
    :exit, _no_supervisor -> :ok
  end

  @doc """
  One entry per followed show the worker should check.
  """
  @spec entries(DateTime.t()) :: [map()]
  def entries(now \\ Kati.Time.now()) do
    if Watcher.watching?() and Watcher.new_episodes?() do
      TrackedTitle
      |> Ash.Query.for_read(:followed)
      |> Ash.read!()
      |> Enum.filter(&(&1.kind in [:tv, :anime] and &1.source in @sources))
      |> Enum.reject(&(&1.notify_new_episodes == false))
      |> Enum.map(&Kati.Background.Watchlist.entry(&1, now))
    else
      []
    end
  rescue
    _error -> []
  end

  @doc false
  def entry(tracked, now) do
    cached = Kati.Media.Release.cached_for(tracked)
    {season, episode} = Kati.Background.Watchlist.last_aired(tracked, now)

    %{
      source: tracked.source,
      source_id: tracked.source_id,
      tracked_id: tracked.id,
      kind: tracked.kind,
      title: (cached && cached.title) || tracked.source_id,
      last_season: season,
      last_episode: episode
    }
  end

  @doc """
  The latest episode the cache knows has aired, as `{season, episode}`, or
  `{nil, nil}` when it knows of none — then the worker reports nothing for the
  show until the cache knows where it stands.
  """
  @spec last_aired(TrackedTitle.t(), DateTime.t()) :: {integer() | nil, integer() | nil}
  def last_aired(tracked, now) do
    tracked.source
    |> CachedEpisode.for_title(tracked.source_id)
    |> Enum.reject(& &1.special)
    |> Enum.filter(fn ep ->
      is_integer(ep.season_number) and is_integer(ep.episode_number) and
        match?(%DateTime{}, ep.air_at) and DateTime.compare(ep.air_at, now) != :gt
    end)
    |> Enum.max_by(&{&1.season_number, &1.episode_number}, fn -> nil end)
    |> case do
      nil -> {nil, nil}
      ep -> {ep.season_number, ep.episode_number}
    end
  rescue
    _error -> {nil, nil}
  end

  @doc "Push on or off, and the quiet window in minutes after midnight."
  @spec settings() :: map()
  def settings do
    quiet =
      case Watcher.quiet_hours() do
        %Kati.Notifications.QuietHours{from: from, to: to} ->
          %{"from" => minutes(from), "to" => minutes(to)}

        _off ->
          :null
      end

    %{"push" => Watcher.loud?(:push), "quiet" => quiet}
  end

  defp minutes(%Time{hour: h, minute: m}), do: h * 60 + m

  @doc """
  The notification's words, with `{count}`, `{range}` and `{shows}` for the
  worker to fill, and the reader's ten digits.
  """
  @spec strings() :: map()
  def strings do
    %{
      "one" => gettext("New episode · {range}"),
      "many" => gettext("{count} new episodes · {range}"),
      "summary" => gettext("New episodes of {shows} shows"),
      "channel" => gettext("New episodes"),
      "digits" => Enum.map_join(0..9, &Kati.Locale.number/1)
    }
  end
end
