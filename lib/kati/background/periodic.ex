defmodule Kati.Background.Periodic do
  @moduledoc """
  Kati's control surface for the background refresh.

  ## What it is for, and what it is emphatically not for

  Periodic work **refreshes data**. It does not deliver reminders. That
  division is the whole of #58's architecture and it is worth stating plainly
  because the obvious design gets it backwards:

    * an air date Kati already knows is armed **now**, with AlarmManager, by
      `Kati.Notifications.Delivery.Android`. The OS holds it through app kills
      and reboots. Nothing has to wake up to remember it.
    * a *change* to that air date — a new episode, a delay, a cancellation — is
      only discoverable by asking a server, and that is what the periodic
      worker does.
    * anything the worker missed is caught on open by
      `Kati.Background.Handoff.drain/1`.

  Polling for something already known is a battery bill for no information.

  ## The cadence, and the two numbers that are deliberately not used

  Six hours with a two-hour flex window, `NetworkType.CONNECTED`,
  `BatteryNotLow`, exponential backoff from 30 minutes, enqueued with
  **KEEP**:

    * `KEEP` and never `REPLACE` — `REPLACE` restarts the interval clock on
      every enqueue, so a user who opens Kati daily would never reach six hours
      and the worker would never run at all. The bug looks like "background
      refresh doesn't work", and the cause is the line that re-registers it.
    * **not** the 15-minute floor. 96 wakeups a day for "did my series get a
      new episode" is indefensible, and it shows up in Android Vitals'
      excessive-background-wakeups metric — a Play listing problem before it is
      a battery one.
    * **not** `setExpedited`. The expedited quota is 30 minutes per 24 hours
      even in the Active standby bucket; spending it on a routine refresh means
      it is gone when something actually needs to be prompt.

  ## iOS

  A no-op, and honestly so. There is no `BGTaskScheduler`, `BGAppRefreshTask`
  or `performFetchWithCompletionHandler` anywhere in mob 0.7.20's iOS files or
  mob_new 0.4.20's — verified by grep, not assumed. A future `mob_bgtask`
  plugin is blocked on two things beyond the BEAM problem:
  `BGTaskSchedulerPermittedIdentifiers` is an array and mob_dev's plugin plist
  merge handles scalars only, and `BGTaskScheduler.register/2` must be called
  inside `didFinishLaunchingWithOptions` — `AppDelegate.m`, which is not
  app-owned.

  So `available?/0` is false there and `ensure/1` says so. **Never ship a
  settings toggle that implies guaranteed background checking on iOS**;
  `Kati.Background.Handoff.drain/1` on open is what iOS actually has, and it is
  worth saying that on screen rather than letting a switch imply otherwise.
  """

  alias Kati.Native.Bridge

  @interval_minutes 6 * 60

  @flex_minutes 2 * 60

  @doc "Whether a real periodic scheduler exists on this build."
  @spec available?() :: boolean()
  defdelegate available?(), to: Bridge

  @doc "The default cadence, in minutes: `{interval, flex}`."
  @spec cadence() :: {pos_integer(), pos_integer()}
  def cadence, do: {@interval_minutes, @flex_minutes}

  @doc """
  Make sure the periodic refresh is enqueued. Idempotent — safe on every start.

  Returns `{:ok, %{interval_minutes: …, flex_minutes: …}}` with the values
  WorkManager actually accepted, which may not be the ones asked for: below 15
  minutes it silently raises to its floor, so the Kotlin side clamps and
  reports rather than letting a caller believe it got five.

  Options `:interval_minutes` and `:flex_minutes` exist for tests and for a
  future "check less often" setting. Neither should be lowered casually — see
  the moduledoc.
  """
  @spec ensure(keyword()) :: {:ok, map()} | {:error, term()}
  def ensure(opts \\ []) do
    payload = %{
      "interval_minutes" => Keyword.get(opts, :interval_minutes, @interval_minutes),
      "flex_minutes" => Keyword.get(opts, :flex_minutes, @flex_minutes)
    }

    case Bridge.reply(:periodic_ensure, [Bridge.encode(payload)]) do
      {:ok, reply} -> decode_ensure(reply)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Cancel the periodic refresh.

  Cancelling something that is not enqueued succeeds — WorkManager treats it as
  a no-op and so does this.
  """
  @spec cancel() :: :ok | {:error, term()}
  def cancel do
    case Bridge.reply(:periodic_cancel, []) do
      {:ok, reply} -> ack(Bridge.split(reply))
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Parse the `"ok:<interval>:<flex>"` reply.

  Public because it is the contract with `KatiPeriodicWork.ensure`, and because
  it is the part of this module a host test can reach — everything else needs
  a JVM.

      iex> Kati.Background.Periodic.decode_ensure("ok:360:120")
      {:ok, %{interval_minutes: 360, flex_minutes: 120}}
      iex> Kati.Background.Periodic.decode_ensure("error:no_context")
      {:error, :no_context}
  """
  @spec decode_ensure(binary()) :: {:ok, map()} | {:error, term()}
  def decode_ensure(reply) do
    with {:ok, payload} <- Bridge.split(reply),
         [interval, flex] <- String.split(payload, ":"),
         {interval_minutes, ""} <- Integer.parse(interval),
         {flex_minutes, ""} <- Integer.parse(flex) do
      {:ok, %{interval_minutes: interval_minutes, flex_minutes: flex_minutes}}
    else
      {:error, reason} -> {:error, reason_atom(reason)}
      _ -> {:error, {:bad_reply, reply}}
    end
  end

  defp ack({:ok, _payload}), do: :ok
  defp ack({:error, reason}), do: {:error, reason_atom(reason)}

  # A closed set. A reply from across JNI never reaches String.to_atom.
  defp reason_atom("no_context"), do: :no_context
  defp reason_atom("bad_request"), do: :bad_request
  defp reason_atom("enqueue_failed"), do: :enqueue_failed
  defp reason_atom("cancel_failed"), do: :cancel_failed
  defp reason_atom(reason) when reason in ~w(no_jvm no_bridge no_method), do: :no_bridge
  defp reason_atom(other) when is_binary(other), do: {:native, other}
  defp reason_atom(other), do: other
end
