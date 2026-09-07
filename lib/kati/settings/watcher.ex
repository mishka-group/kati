defmodule Kati.Settings.Watcher do
  @moduledoc """
  The two controls on screen 25 that something actually reads.

  MOVIES-AND-TV.md #67 and `design-briefs/D-64`. Screen 25 draws fifteen
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

  # The four the board draws, and the interval each asks WorkManager for.
  # `Manual` is `nil`: it is not a long interval, it is no periodic work, and
  # asking for one every thousand years would be a different promise.
  #
  # WorkManager's floor is 15 minutes and the Kotlin side clamps to it, so
  # `Hourly` is honoured and nothing here can ask for less than the platform
  # allows — see `Kati.Background.Periodic.ensure/1`.
  @cadences [
    {"Hourly", 60},
    {"Every 6h", 6 * 60},
    {"Daily", 24 * 60},
    {"Manual", nil}
  ]

  # The one *Tell me about* switch with a consumer. Named rather than indexed,
  # because the board's order is the board's and an index would silently move
  # with it.
  @live_kinds ["New episodes"]

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
  Ask WorkManager for this cadence, or leave it alone on `Manual`.

  `ensure/1` is `KEEP`, so it does not restart a clock that is already running
  at the same interval — which is why `Kati.App` can call it on every boot. A
  changed interval is a changed request, and the day the platform is asked for
  it is the next start. Recorded rather than hidden: a reader who picks
  `Hourly` gets hourly from then on, not retroactively.

  `{:error, :no_bridge}` is the normal answer off Android and is not a fault.
  """
  @spec reschedule(String.t()) :: :ok
  def reschedule(label) do
    case Kati.Settings.Watcher.interval_for(label) do
      nil ->
        :ok

      minutes ->
        # Both answers are truthy — `{:error, :no_bridge}` is the normal one off
        # Android — so this is a sequence, not a choice.
        Kati.Background.Periodic.ensure(interval_minutes: minutes)
        :ok
    end
  rescue
    _error -> :ok
  end

  @doc """
  The interval a cadence asks for, in minutes — `nil` for `Manual`.

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
  Whether a *Tell me about* switch has anything behind it.

      iex> Kati.Settings.Watcher.live?("New episodes")
      true

      iex> Kati.Settings.Watcher.live?("Price drops")
      false
  """
  @spec live?(String.t()) :: boolean()
  def live?(title), do: title in @live_kinds
end
