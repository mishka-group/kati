defmodule Kati.Settings.Watcher do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Screen 25's preferences — every control on the release watcher's settings
  page, stored in `Mob.State` and read back by what it governs.

  `Mob.State` is where every app-level preference in Kati lives — the locale,
  the theme, the rating scale, the detect settings — and these are the same
  kind of thing: one device's answer to *how should this app behave*, not a row
  about a title.

  ## What each one governs

    * **the master switch** (`watching?/0`) — `Kati.Background.Periodic`, the
      watcher's background check. Off cancels the worker; on enqueues it at the
      cadence. `Kati.App` reads both on every boot.
    * **the cadence** (`cadence/0`) — the interval that worker is asked for.
    * **Tell me about** (`kind?/1`, one switch per `kinds/0`) — which releases
      the watcher reports at all. `Kati.Screens.Inbox` filters both of its lists
      by them, so screen 05, Home's *New this week* and every release alert are
      the same filtered set. Which switch a release answers to is
      `release_kind/1`.
    * **Push notifications** (`loud?(:push)`) — whether
      `Kati.Notifications.Releases.sync/1` arms the coming-up releases on the
      platform. Off by default: the app is designed to be checked, and the
      bell's inbox holds the same list either way.
    * **Inbox badge** (`loud?(:badge)`) — the unread dot on Home's bell,
      `Kati.Screens.Home.unread?/0`.
    * **Quiet hours** (`quiet_hours/0`) — the window
      `Kati.Notifications.Scheduler.plan/2` shifts reminders out of, for the
      plan the bell's inbox draws and for the alerts push arms.

  Every reader answers its default when `Mob.State` cannot be reached, and the
  defaults lean the safe way: the release kinds and the badge default on, so an
  unreadable store never silently stops telling somebody about the shows they
  followed; push defaults off, so an unreadable store never starts interrupting
  somebody who did not ask.
  """

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Notifications.QuietHours

  @cadence_key :watcher_cadence
  @watching_key :watcher_watching
  @checked_key :watcher_last_checked

  @cadences [
    {"Hourly", 60},
    {"Every 6h", 6 * 60},
    {"Daily", 24 * 60}
  ]

  @kinds [
    new_episodes: :watcher_new_episodes,
    premieres: :watcher_premieres,
    film_releases: :watcher_film_releases
  ]

  @loudness [
    push: {:watcher_push, false},
    badge: {:watcher_badge, true},
    quiet_hours: {:watcher_quiet_hours, true}
  ]

  @doc """
  The cadence the reader chose, or the board's own.

      iex> Kati.Settings.Watcher.cadence() in Kati.Settings.Watcher.cadences()
      true
  """
  @spec cadence() :: String.t()
  def cadence do
    case Mob.State.get(@cadence_key) do
      label when is_binary(label) -> if label in cadences(), do: label, else: default_cadence()
      _unset -> default_cadence()
    end
  rescue
    _error -> default_cadence()
  end

  @doc "Remember the cadence, and ask the scheduler for it."
  @spec put_cadence(String.t()) :: :ok
  def put_cadence(label) do
    if label in cadences() do
      Mob.State.put(@cadence_key, label)
      Kati.Settings.Watcher.reschedule(label)
    end

    :ok
  rescue
    _error -> :ok
  end

  @doc """
  Ask WorkManager for this cadence, or cancel the worker when the master switch
  is off.

  `ensure/1` is `KEEP`, so it does not restart a clock that is already running
  at the same interval — which is why `Kati.App` can call it on every boot. A
  changed interval is a changed request, and the day the platform is asked for
  it is the next start. Recorded rather than hidden: a reader who picks
  `Hourly` gets hourly from then on, not retroactively.

  `{:error, :no_bridge}` is the normal answer off Android and is not a fault.
  """
  @spec reschedule(String.t()) :: :ok
  def reschedule(label) do
    case Kati.Settings.Watcher.request(Kati.Settings.Watcher.watching?(), label) do
      :cancel ->
        Kati.Background.Periodic.cancel()

      {:ensure, minutes} ->
        Kati.Background.Periodic.ensure(interval_minutes: minutes)

      :ignore ->
        :ok
    end

    :ok
  rescue
    _error -> :ok
  end

  @doc """
  What the scheduler should be asked for, given the switch and the cadence.

  Pure, so the decision is settleable without a JVM — `Kati.Background.Periodic`
  answers `{:error, :no_bridge}` on a host and the branch taken is the thing
  worth asserting.

      iex> Kati.Settings.Watcher.request(false, "Hourly")
      :cancel

      iex> Kati.Settings.Watcher.request(true, "Hourly")
      {:ensure, 60}
  """
  @spec request(boolean(), String.t()) :: :cancel | {:ensure, pos_integer()} | :ignore
  def request(false, _label), do: :cancel

  def request(true, label) do
    case Kati.Settings.Watcher.interval_for(label) do
      nil -> :ignore
      minutes -> {:ensure, minutes}
    end
  end

  @doc """
  When the watcher last actually checked, or `nil`.

  Board 314's first lie: `checked 18:02` was a literal on a page with no record
  of ever having checked, which is the same defect 260 fixed on this page's
  sibling. This is a real timestamp, and `nil` — *never checked* — is what
  every fresh install answers.
  """
  @spec last_checked() :: DateTime.t() | nil
  def last_checked do
    case Mob.State.get(@checked_key) do
      stamp when is_binary(stamp) ->
        case DateTime.from_iso8601(stamp) do
          {:ok, at, _offset} -> at
          _unparseable -> nil
        end

      _none ->
        nil
    end
  rescue
    _error -> nil
  end

  @doc "Record that a check has just happened."
  @spec checked!() :: :ok
  def checked! do
    Mob.State.put(@checked_key, DateTime.to_iso8601(Kati.Time.now()))
    :ok
  rescue
    _error -> :ok
  end

  @doc """
  `never checked`, `checking now`, or how long ago — board 314's own three.

      iex> Kati.Settings.Watcher.checked_line(nil, false)
      "never checked"

      iex> Kati.Settings.Watcher.checked_line(DateTime.add(Kati.Time.now(), -7200), false)
      "checked 2 hours ago"

      iex> Kati.Settings.Watcher.checked_line(nil, true)
      "checking now"
  """
  @spec checked_line(DateTime.t() | nil, boolean()) :: String.t()
  def checked_line(_at, true), do: gettext("checking now")
  def checked_line(nil, _idle), do: gettext("never checked")

  def checked_line(at, _idle) do
    if DateTime.diff(Kati.Time.now(), at) < 60 do
      gettext("checked just now")
    else
      gettext("checked %{ago}", ago: Kati.Settings.Watcher.since(at))
    end
  end

  @doc """
  How long ago a moment was, as the sentence around it reads it.

      iex> Kati.Settings.Watcher.since(DateTime.add(Kati.Time.now(), -7200))
      "2 hours ago"

  Split out of `checked_line/2` by mishka-group/kati#103, because screen 80's
  board 318 says `SAVED 2 MINUTES AGO` and was building that by String-replacing
  `"checked "` off the front of this one's answer — which is a sentence, and a
  sentence is translated. Two callers, one span.
  """
  @spec since(DateTime.t()) :: String.t()
  def since(at) do
    seconds = DateTime.diff(Kati.Time.now(), at)

    cond do
      seconds < 3600 -> minutes(seconds)
      seconds < 86_400 -> hours(seconds)
      true -> days(seconds)
    end
  end

  defp minutes(seconds) do
    n = div(seconds, 60)
    ngettext("%{n} minute ago", "%{n} minutes ago", n, n: Kati.Locale.number(n))
  end

  defp hours(seconds) do
    n = div(seconds, 3600)
    ngettext("%{n} hour ago", "%{n} hours ago", n, n: Kati.Locale.number(n))
  end

  defp days(seconds) do
    n = div(seconds, 86_400)
    ngettext("%{n} day ago", "%{n} days ago", n, n: Kati.Locale.number(n))
  end

  @doc """
  The interval a cadence asks for, in minutes — `nil` for a name that is not
  one of the three.

      iex> Kati.Settings.Watcher.interval_for("Hourly")
      60

      iex> Kati.Settings.Watcher.interval_for("Manual")
      nil
  """
  @spec interval_for(String.t()) :: pos_integer() | nil
  def interval_for(label) do
    Enum.find_value(@cadences, fn {name, minutes} -> if name == label, do: minutes end)
  end

  @doc "The three cadences screen 25 offers, in its order."
  @spec cadences() :: [String.t()]
  def cadences, do: Enum.map(@cadences, &elem(&1, 0))

  @doc false
  @spec default_cadence() :: String.t()
  def default_cadence do
    {minutes, _flex} = Kati.Background.Periodic.cadence()

    Enum.find_value(@cadences, "Every 6h", fn {name, m} -> if m == minutes, do: name end)
  end

  @doc """
  The *Tell me about* switches, in the order screen 25 draws them.

      iex> Kati.Settings.Watcher.kinds()
      [:new_episodes, :premieres, :film_releases]
  """
  @spec kinds() :: [atom()]
  def kinds, do: Keyword.keys(@kinds)

  @doc """
  Whether the watcher reports releases of this kind. On unless switched off.
  """
  @spec kind?(atom()) :: boolean()
  def kind?(kind), do: @kinds |> Keyword.fetch!(kind) |> flag(true)

  @doc "Set one *Tell me about* switch."
  @spec put_kind(atom(), boolean()) :: :ok
  def put_kind(kind, on?) when is_boolean(on?) do
    Mob.State.put(Keyword.fetch!(@kinds, kind), on?)
    :ok
  rescue
    _error -> :ok
  end

  @doc """
  The kinds switched on right now, read once so a list of releases can be
  filtered without a store read per row.
  """
  @spec wanted_kinds() :: MapSet.t(atom())
  def wanted_kinds, do: kinds() |> Enum.filter(&kind?/1) |> MapSet.new()

  @doc """
  Which *Tell me about* switch a release answers to.

  A season drop and the first episode of any season are premieres; every other
  episode is a new episode; a film's own release date is a film release.

      iex> Kati.Settings.Watcher.release_kind(%Kati.Media.CachedEpisode{episode_number: 1})
      :premieres

      iex> Kati.Settings.Watcher.release_kind(%Kati.Media.CachedEpisode{episode_number: 6})
      :new_episodes

      iex> Kati.Settings.Watcher.release_kind(:film)
      :film_releases
  """
  @spec release_kind(CachedEpisode.t() | CachedSeason.t() | :film) :: atom()
  def release_kind(%CachedSeason{}), do: :premieres
  def release_kind(%CachedEpisode{episode_number: 1}), do: :premieres
  def release_kind(%CachedEpisode{}), do: :new_episodes
  def release_kind(:film), do: :film_releases

  @doc "Whether new episodes are reported — the *New episodes* switch."
  @spec new_episodes?() :: boolean()
  def new_episodes?, do: kind?(:new_episodes)

  @doc "Set the *New episodes* switch."
  @spec put_new_episodes(boolean()) :: :ok
  def put_new_episodes(on?), do: put_kind(:new_episodes, on?)

  @doc """
  Whether the watcher may check on its own — the banner's master switch.

  `Kati.Background.Periodic` IS the release watcher's background check and
  nothing else — *"Periodic work refreshes data. It does not deliver
  reminders."* — so this switch has exactly one honest meaning and one
  consumer: off cancels the worker, on enqueues it at the cadence below.
  **Check now** is untouched, because a one-off run is an action and not a
  schedule (board 314).

  On by default, which is the state the board draws. A store this cannot reach
  answers `true`, for `new_episodes?/0`'s reason: a preference Kati cannot read
  must not silently switch the watcher off.
  """
  @spec watching?() :: boolean()
  def watching? do
    case Mob.State.get(@watching_key) do
      value when is_boolean(value) -> value
      _unset -> true
    end
  rescue
    _error -> true
  end

  @doc "Set it, and ask the scheduler for what it now means."
  @spec put_watching(boolean()) :: :ok
  def put_watching(on?) when is_boolean(on?) do
    Mob.State.put(@watching_key, on?)
    Kati.Settings.Watcher.reschedule(Kati.Settings.Watcher.cadence())
    :ok
  rescue
    _error -> :ok
  end

  @doc """
  The *How loudly* switches, in the order screen 25 draws them.

      iex> Kati.Settings.Watcher.loudness()
      [:push, :badge, :quiet_hours]
  """
  @spec loudness() :: [atom()]
  def loudness, do: Keyword.keys(@loudness)

  @doc """
  Whether a *How loudly* switch is on. Push defaults off; the badge and quiet
  hours default on.
  """
  @spec loud?(atom()) :: boolean()
  def loud?(key) do
    {store, default} = Keyword.fetch!(@loudness, key)
    flag(store, default)
  end

  @doc "Set one *How loudly* switch."
  @spec put_loud(atom(), boolean()) :: :ok
  def put_loud(key, on?) when is_boolean(on?) do
    {store, _default} = Keyword.fetch!(@loudness, key)
    Mob.State.put(store, on?)
    :ok
  rescue
    _error -> :ok
  end

  @doc """
  The quiet-hours rule for `Kati.Notifications.Scheduler.plan/2`: the window
  when the switch is on, `false` — the scheduler's *rule off* — when it is not.
  """
  @spec quiet_hours() :: QuietHours.t() | false
  def quiet_hours do
    if loud?(:quiet_hours), do: QuietHours.default(), else: false
  end

  defp flag(store, default) do
    case Mob.State.get(store) do
      value when is_boolean(value) -> value
      _unset -> default
    end
  rescue
    _error -> default
  end
end
