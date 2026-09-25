defmodule Kati.Native.TapRelay do
  @moduledoc """
  Delivers a tap — a notification's, or the home-screen widget's — that brings
  an already running Kati to the front.

  ## The gap it closes

  Mob routes a tap in two ways. From a killed app, `MainActivity.onCreate`
  stores the payload and `Mob.Router`'s `init/1` takes it, then hands the
  current screen `{:notification, %{data: …}}`. That works, and it is how the
  widget's tap opens a title from cold (`Kati.Widgets.Launch`).

  From a RUNNING app, `MainActivity.onNewIntent` sends the payload to
  `io.mob.plugin.MobNotifyHub.notifyPid` — the process the `mob_notify`
  plugin registers with `register_push/1`. Kati has no such plugin (#75 took
  push out, `K-30 drop-push`), so that pid is `0`, and the payload is stored
  for a router init that does not come until the root screen next restarts.
  A tap on a running Kati therefore only ever brought it to the front, and
  one that was stored could surface later, somewhere else, as a jump nobody
  asked for.

  This process is the pid. It registers itself through
  `MobBridge.katiRouteTaps` (`K-51 widget-bridge`) and forwards what arrives
  to `:mob_screen` as `{:mob_launch_notification, json}` — the message Mob's
  own native delivery sends — so `Mob.Router` decodes it exactly as it does a
  cold launch's, and the current screen gets the same
  `{:notification, …}`. Nothing here parses a payload.

  `K-51 widget-tap-relaunch` covers the third case: a new `MainActivity` in a
  process whose BEAM is already running (Android destroyed the Activity and
  kept the process). There `onCreate` stores the payload and nobody takes it
  either, so the fence hands it to this process instead.

  ## Why it starts after the root screen

  A cold launch's payload is taken by `Mob.Router.init/1`. Until that has
  run, the payload belongs to the router, and `Kati.Supervisor` starts this
  child after `:mob_screen` so there is never a moment when both would claim
  it.

  ## Where there is no bridge

  On the host and on iOS the registration answers `{:error, :no_bridge}`, and
  this process simply waits for messages that will never come.
  """

  use GenServer

  @doc false
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(opts) do
    registered = Kati.Native.Bridge.reply(:route_taps, [inspect(__MODULE__)])
    {:ok, %{registered: registered, to: Keyword.get(opts, :to, :mob_screen)}}
  end

  @impl true
  def handle_info({:mob_launch_notification, json} = message, state) when is_binary(json) do
    forward(state.to, message)
    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}

  defp forward(to, message) when is_atom(to) do
    if Process.whereis(to), do: send(to, message)
  end

  defp forward(to, message) when is_pid(to), do: send(to, message)
end
