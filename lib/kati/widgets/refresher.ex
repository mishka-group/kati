defmodule Kati.Widgets.Refresher do
  @moduledoc """
  The one process that rewrites the widget's snapshot and tells the launcher.

  ## Why a process, and why only one

  The widget used to be refreshed once, at boot. Everything that changed the
  hero afterwards — ticking an episode, finishing a film, dropping a show,
  adding or removing a title — left the home screen showing the old answer
  until the app was next launched from cold, which on a phone that keeps Kati
  in memory can be days.

  The writes that move the hero do not go through one function: there are
  dozens of `Ash.update/2` calls on `Kati.Media.TrackedTitle` across the
  screens. They do all go through the resource, so `Kati.Widgets.Notifier`
  sits there and calls `Kati.Widgets.Notifier.poke/0`, and nothing else in the app has to remember
  the widget exists. Two changes do not pass through an Ash action and poke
  for themselves: a poster finishing its download is a file rather than a
  row (`Kati.Media.Artwork`), and a backup restore writes through
  `Ash.Seed`, which runs no action and so no notifier
  (`Kati.Backup.Restore`, once, after it commits).

  A poke is a cast and costs the writer nothing. The refresh itself runs
  here, `@delay` later, so a burst of writes — a backup restore, a season
  marked watched in one go — is one rewrite rather than hundreds, and so the
  snapshot has exactly one writer and its `.tmp` file cannot be raced.

  ## Telling the launcher

  Writing the file is not enough: a Glance widget redraws when it is told to.
  After a successful write this asks `Kati.Native.Bridge` for `widget_redraw`,
  which is `MobBridge.katiWidgetRedraw` (`K-51 widget-bridge`). On the host
  and on iOS that answers `{:error, :no_bridge}`, which is the truth — there
  is no widget to redraw — and is ignored.

  ## When it is not running

  A poke is a cast to this process's registered name, and a cast to a name nobody holds
  is dropped rather than raised. The host suite never starts
  `Kati.Supervisor`, so the thousands of tracked-title writes in it cost one
  failed `send/2` each and write nothing. A test that wants the behaviour
  starts this process itself, with a `:dir` of its own.
  """

  use GenServer

  require Logger

  @delay 400

  @doc """
  Start the refresher. `:dir` is handed to `Kati.Widgets.Snapshot` and exists
  for tests; `:delay` is the coalescing window in milliseconds.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Run a pending refresh now and answer what it returned, or `:idle` when
  nothing was pending.
  """
  @spec flush(GenServer.server()) :: :ok | :idle | {:error, term()}
  def flush(server \\ __MODULE__), do: GenServer.call(server, :flush, 30_000)

  @impl true
  def init(opts) do
    state = %{
      timer: nil,
      delay: Keyword.get(opts, :delay, @delay),
      snapshot: Keyword.take(opts, [:dir])
    }

    {:ok, schedule(state)}
  end

  # `Kati.Widgets.Notifier.poke/0` sends this. Many pokes inside one window are
  # one refresh; a poke that lands while a refresh is running schedules the
  # next one, so the last write always wins.
  @impl true
  def handle_cast(:poke, state), do: {:noreply, schedule(state)}

  @impl true
  def handle_call(:flush, _from, %{timer: nil} = state), do: {:reply, :idle, state}

  def handle_call(:flush, _from, state) do
    _ = Process.cancel_timer(state.timer)
    {:reply, refresh(state), %{state | timer: nil}}
  end

  @impl true
  def handle_info(:refresh, state) do
    _ = refresh(state)
    {:noreply, %{state | timer: nil}}
  end

  def handle_info(_other, state), do: {:noreply, state}

  defp schedule(%{timer: nil} = state),
    do: %{state | timer: Process.send_after(self(), :refresh, state.delay)}

  defp schedule(state), do: state

  defp refresh(state) do
    case Kati.Widgets.Snapshot.refresh(state.snapshot) do
      :ok ->
        _ = Kati.Native.Bridge.reply(:widget_redraw, [])
        :ok

      {:error, reason} = error ->
        Logger.info("widget snapshot not written: #{inspect(reason)}")
        error
    end
  rescue
    error ->
      Logger.info("widget snapshot not written: #{Exception.message(error)}")
      {:error, error}
  end
end
