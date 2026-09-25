defmodule Kati.Settings.Watcher do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  The two controls on screen 25 that something actually reads.

  See `design-briefs/D-64`. Screen 25 draws fifteen
  controls — a master switch, six *Tell me about* switches, a four-way cadence
  and four *How loudly* switches — and every one of them edited a socket assign
  and was forgotten on the pop. The brief's own table is what this module is
  built from: it asks which consumer each control would need and answers
  **yes** for exactly two.

  ## Why the other thirteen are not here

  The brief states it plainly, and it is the reason a `Mob.State` key per switch
  would have been the wrong patch:

  > Persisting them turns *forgotten on the pop* into *remembered, and still
  > inert*, which is a worse lie: the reader has evidence the setting took, and
  > nothing behind it ever did.

  So the thirteen are drawn with the `not yet` mark screen 88 already uses for
  a scope nothing searches (#74) — visible, honest, and not offering a choice
  the app cannot keep. `Kati.Settings.Watcher.live?/1` is that seam, and each
  one becomes live the day its resource does, without the board being redrawn.

  ## The two, and what reads them

    * **the cadence** — `Kati.Background.Periodic.ensure/1` takes
      `:interval_minutes` and its own doc names this exact use: *"a future
      'check less often' setting"*. `Kati.App` calls it on every boot, so a
      cadence stored here is the interval WorkManager is asked for next start.
    * **New episodes** — the global gate over the per-title
      `Kati.Media.TrackedTitle.notify_new_episodes`, read by
      `Kati.Notifications.Sources.Media`. Off means Kati does not tell you
      about an episode however many shows you have followed.

  Both live in `Mob.State`, which is where every app-level preference in Kati
  lives — the locale, the theme, the rating scale, the detect settings.
  """

  @cadence_key :watcher_cadence
  @episodes_key :watcher_new_episodes
  @watching_key :watcher_watching

  # The four the board draws, and the interval each asks WorkManager for.
  # `Manual` is `nil`: it is not a long interval, it is no periodic work, and
  # asking for one every thousand years would be a different promise.
  #
  # WorkManager's floor is 15 minutes and the Kotlin side clamps to it, so
  # `Hourly` is honoured and nothing here can ask for less than the platform
  # allows — see `Kati.Background.Periodic.ensure/1`.
  # THREE, since board 314. `Manual` was a fourth and it meant NEVER: nothing
  # schedules a manual run, so choosing it silently switched the watcher off —
  # *"a segment that silently switches the watcher off is worse than no
  # segment."* 314 turns it into what it always was, a button: **Check now**,
  # which runs once and stamps the line above it.
  @cadences [
    {"Hourly", 60},
    {"Every 6h", 6 * 60},
    {"Daily", 24 * 60}
  ]

  @checked_key :watcher_last_checked

  # The one *Tell me about* switch with a consumer. Named rather than indexed,
  # because the board's order is the board's and an index would silently move
  # with it.
  @live_kinds ["New episodes"]

  # The *How loudly* rows with a consumer. Empty, and the list is the point:
  # nothing in Kati sends a notification for a release — the only
  # `Kati.Notifications.Delivery.backend/0` calls in `lib/` are auto-detect's,
  # a different feature with its own page — so push has no sender, quiet hours
  # has nothing to quiet, and no weekly job exists.
  #
  # `Enum.member?/2` rather than `in`, because `title in []` folds to a literal
  # `false` and warns.
  @live_loudness []

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
        # Both answers are truthy — `{:error, :no_bridge}` is the normal one off
        # Android — so this is a sequence, not a choice.
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

  @doc "The four the board draws, in its order."
  @spec cadences() :: [String.t()]
  def cadences, do: Enum.map(@cadences, &elem(&1, 0))

  @doc false
  @spec default_cadence() :: String.t()
  def default_cadence do
    {minutes, _flex} = Kati.Background.Periodic.cadence()

    Enum.find_value(@cadences, "Every 6h", fn {name, m} -> if m == minutes, do: name end)
  end

  @doc """
  Whether Kati may tell you about a new episode at all.

  The global gate over every title's own `notify_new_episodes`. On by default,
  which is the state the board draws and the one a reader who has never opened
  this page expects — following a show is asking to be told.
  """
  @spec new_episodes?() :: boolean()
  def new_episodes? do
    case Mob.State.get(@episodes_key) do
      value when is_boolean(value) -> value
      _unset -> true
    end
  rescue
    # A store this cannot reach answers `true`, which is the direction that
    # matters: a preference Kati cannot read must not silently stop telling
    # somebody about the shows they followed. `Mob.State` is DETS and is not
    # started in every test process.
    _error -> true
  end

  @doc "Set it."
  @spec put_new_episodes(boolean()) :: :ok
  def put_new_episodes(on?) do
    Mob.State.put(@episodes_key, on?)
    :ok
  rescue
    _error -> :ok
  end

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
  Whether a *How loudly* switch has anything behind it.

      iex> Kati.Settings.Watcher.loud?("Push notifications")
      false
  """
  @spec loud?(String.t()) :: boolean()
  def loud?(title), do: Enum.member?(@live_loudness, title)

  @doc """
  Whether a *Tell me about* switch has anything behind it.

      iex> Kati.Settings.Watcher.live?("New episodes")
      true

      iex> Kati.Settings.Watcher.live?("Price drops")
      false
  """
  @spec live?(String.t()) :: boolean()
  def live?(title), do: title in @live_kinds
end
