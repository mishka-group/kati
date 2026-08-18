defmodule Kati.Supervisor do
  @moduledoc """
  Kati's own supervision tree.

  Mob does not supply one. `Mob.Screen`'s moduledoc and Mob's architecture guide
  both say a crashed screen is restarted by a supervisor; there is no
  `application.ex` and no supervisor anywhere in `mob/lib` — `start_root/3` is a
  bare `GenServer.start_link`. A crashed screen therefore stays dead and the app
  looks frozen, with no crash dialogue and nothing on screen to explain it.

  Two consequences, both handled here:

    * **The root screen is a supervised child.** A crash restarts it and re-mounts
      Home rather than leaving a frozen surface. The back stack is lost, which is
      the correct trade: a user who can navigate has recovered; a user staring at
      a dead screen has not.
    * **Long-lived work lives here, never in a screen.** A screen is transient —
      it dies on every root switch — so anything holding a subscription, a timer
      or a socket must outlive it. See `Kati.Screens.Root` for the rule and
      `Kati.SupervisionRuleTest` for its enforcement.
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @impl true
  def init(:ok) do
    children =
      blocked_app_trees() ++
        [
          # Anything Kati spawns for one-off work. Kept here so a crashing task
          # cannot take a screen with it.
          {Task.Supervisor, name: Kati.TaskSupervisor},

          # The root screen. Mob registers it as :mob_screen so the C layer's
          # back handler can find it; supervising it is what turns "frozen app"
          # into "back at Home".
          %{
            id: :mob_screen,
            start: {Mob.Screen, :start_root, [Kati.Screens.Home]},
            restart: :permanent,
            shutdown: 5_000,
            type: :worker
          }

          # Arriving with their own tickets, each of which must live here rather
          # than in a screen because it outlives any single screen:
          #   Kati.Notifications.Scheduler  (#59) — owns the whole pending set
          #   Kati.Jobs.Runner              (#59) — the on-device scheduler
          #   Kati.Sync.Engine              (#54) — outbox, retries, backoff
          #   Kati.Net.Throttle             (#58) — per-source rate limits
        ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  # Supervision trees that `application_controller` refuses to start on a
  # device, started here instead so their processes genuinely exist.
  #
  # `:reactor` is the live case. Ash depends on it, it supervises a
  # `PartitionSupervisor` of task supervisors plus a concurrency tracker, and
  # its own `applications` list names `:igniter` — which needs `:inets`,
  # which the Android OTP runtime does not ship. `Application.start(:reactor)`
  # therefore fails with `{:not_started, :igniter}` no matter what is loaded.
  #
  # Calling the app's own `start/2` runs upstream's child list rather than a
  # copy of it, so this cannot drift when Reactor changes. The only thing
  # missing afterwards is the bookkeeping entry in `application_controller`;
  # every process Ash reaches for is running.
  defp blocked_app_trees do
    Enum.map(Kati.App.blocked_apps(), fn app ->
      {mod, args} = Application.spec(app, :mod)

      %{id: {:blocked_app, app}, start: {mod, :start, [:normal, args]}, type: :supervisor}
    end)
  end
end
