defmodule Kati.Sync.Runner do
  @moduledoc """
  The process that actually syncs, now that something has to.

  `Kati.Sync.Engine` was finished and nothing called it: `sync/3` had no caller
  anywhere in `lib/`, so a foreground never pulled a device calendar, the
  outbox never drained, and screen 47's ledger could only ever show what a
  previous install left behind.

  ## Foreground, not a timer

  The engine's own moduledoc states the cadence and it is not negotiable: Mob
  cannot boot a headless BEAM and iOS cannot discover in the background, so Kati
  syncs on foreground, on pull, and on explicit action. This process therefore
  syncs **once shortly after boot**, and then only when a screen asks —
  `Kati.Screens.Sync`'s *Send now*, and Home's resume.

  The delay exists because boot is the worst second of the app's life: the repo
  has just migrated and the bridge is still answering permission questions.
  Five seconds in, a missed sync costs nothing and a cold-start regression costs
  the first frame.

  ## It cannot take the UI down

  Each calendar is synced inside its own try. One adapter that raises — a
  provider file half-written, a stale etag — leaves the others alone and turns
  into a result the screen can show, which is the same contract
  `Kati.Notifications.Runner` keeps for the same reason.
  """

  use GenServer

  require Logger

  @delay_ms 5_000

  @doc "Start the loop. Named, so a screen can ask for a sync."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc "Ask for a sync, off the caller's process. Safe when nothing is running."
  @spec refresh() :: :ok
  def refresh do
    case Process.whereis(__MODULE__) do
      nil -> :ok
      pid -> GenServer.cast(pid, :sync)
    end
  end

  @doc """
  Sync every calendar Kati holds, in the caller's process.

  Answers `%{calendar_id => :ok | {:error, reason}}`. The adapter is chosen by
  the calendar's account provider: the device provider is the phone's own
  calendars, CalDAV is an account somebody connected, and anything else is
  `Inert` — which answers "nothing to do" rather than failing.
  """
  @spec sync_now() :: %{String.t() => term()}
  def sync_now do
    Kati.Calendars.Calendar
    |> Ash.Query.load(:account)
    |> Ash.read()
    |> case do
      {:ok, calendars} -> Map.new(calendars, &sync_calendar/1)
      _error -> %{}
    end
  rescue
    error -> %{"*" => {:error, error}}
  end

  defp sync_calendar(calendar) do
    adapter = adapter(calendar.account)

    result =
      try do
        Kati.Sync.Engine.sync(calendar, adapter)
      rescue
        error -> {:error, error}
      end

    {calendar.id, result}
  end

  @doc "Which adapter an account's calendars use."
  @spec adapter(struct() | nil) :: module()
  def adapter(%{provider: :android_provider}), do: Kati.Sync.Adapter.DeviceProvider
  def adapter(%{provider: :caldav}), do: Kati.Sync.Adapter.CalDAV
  def adapter(_other), do: Kati.Sync.Adapter.Inert

  @impl true
  def init(:ok) do
    Process.send_after(self(), :sync, @delay_ms)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sync, state) do
    run()
    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl true
  def handle_cast(:sync, state) do
    run()
    {:noreply, state}
  end

  defp run do
    case sync_now() do
      results ->
        failures =
          Enum.filter(results, fn {_id, result} ->
            match?({:error, _}, result)
          end)

        if failures != [] do
          Logger.warning("sync: #{length(failures)} calendar(s) failed: #{inspect(failures)}")
        end

        send(:mob_screen, {:kati, :sync, :changed})
    end
  rescue
    error -> Logger.warning("sync: reconcile failed: #{inspect(error)}")
  end
end
