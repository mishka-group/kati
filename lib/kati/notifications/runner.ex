defmodule Kati.Notifications.Runner do
  @moduledoc """
  The process that keeps the platform's alarms equal to Kati's plan.

  `Kati.Notifications.Scheduler` decides and `Kati.Notifications.Reminders` /
  `Kati.Notifications.Releases` apply; nothing ran them. This is the loop: it
  reconciles on boot, on foreground (through `refresh/0`), and every quarter of
  an hour, because the three things that change a plan on their own — the clock,
  the device's time zone, and a title's release date — change without a write
  in this app to notice.

  ## Why a process and not a screen

  `AGENTS.md` is blunt: a screen is transient and may hold no timer. An armed
  alarm outlives every screen, so the loop lives under `Kati.Supervisor` beside
  the root screen, and screens ask it to refresh rather than doing the work.

  ## It cannot take the UI down

  Both syncs answer values rather than raising, and this module also catches:
  an OEM that refuses an alarm while the phone is in Doze must not turn the
  screen black. A failure is logged and the next tick tries again — which is
  the only recovery a device with no telemetry will ever get.

  ## Alive at all is the feature

  Until this existed, the hourly, daily and rewatch features were a plan that
  nothing applied: `Reminders.sync_later/0` spawned a one-off task, and no
  reconcile ran at boot, so a reminder written on Tuesday fired only if the
  app happened to sync it in the same process before being killed.
  """

  use GenServer

  require Logger

  @interval :timer.minutes(15)

  @doc "Start the loop. Named, so a screen can ask it for a refresh."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc """
  Ask for a reconcile, off the caller's process.

  Safe when the runner is not running — the host suite never starts
  `Kati.Supervisor` — which is why the caller does not have to know.
  """
  @spec refresh() :: :ok
  def refresh do
    case Process.whereis(__MODULE__) do
      nil -> :ok
      pid -> GenServer.cast(pid, :refresh)
    end
  end

  @doc """
  Reconcile now, in the caller's process, and answer both results.

  Used by the runner's own tick and by tests; screens use `refresh/0` so a save
  never waits on the platform.
  """
  @spec sync_now() :: %{reminders: term(), releases: term()}
  def sync_now do
    %{
      reminders: safely(fn -> Kati.Notifications.Reminders.sync() end),
      releases: safely(fn -> Kati.Notifications.Releases.sync() end)
    }
  end

  @impl true
  def init(:ok) do
    send(self(), :refresh)
    {:ok, %{timer: nil}}
  end

  @impl true
  def handle_cast(:refresh, state) do
    run()
    {:noreply, %{state | timer: schedule()}}
  end

  @impl true
  def handle_info(:refresh, state) do
    run()
    {:noreply, %{state | timer: schedule()}}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp run do
    result = sync_now()
    announce()

    case {result.reminders, result.releases} do
      {{:error, reason}, _} when reason not in [:no_delivery] ->
        Logger.warning("notifications: reminders sync failed: #{inspect(reason)}")

      {_, {:error, reason}} when reason not in [:no_delivery] ->
        Logger.warning("notifications: releases sync failed: #{inspect(reason)}")

      _ok_or_no_platform ->
        :ok
    end
  end

  # Screens redraw from their own reads, so the message says only that the plan
  # moved. Addressed by name and dropped when the root screen is not up, which
  # is the contract `AGENTS.md` gives every supervised process.
  defp announce do
    send(:mob_screen, {:kati, :notifications, :changed})
  rescue
    _no_screen -> :ok
  end

  defp schedule do
    Process.send_after(self(), :refresh, @interval)
  end

  defp safely(fun) do
    fun.()
  rescue
    error -> {:error, error}
  end
end
