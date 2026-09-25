defmodule Kati.Notifications.Releases do
  @moduledoc """
  Release alerts on the platform — what screen 25's *Push notifications* switch
  turns on.

  The alerts are `Kati.Screens.Inbox.alerts/0`: the **Coming up** rows of
  screen 05, one candidate each, already filtered by the *Tell me about*
  switches and already gated by `Kati.Media.Release` (a muted show or a vague
  date is a suppressed candidate, never an alarm). `sync/1` plans them through
  `Kati.Notifications.Scheduler` with the reader's quiet-hours rule, then
  reconciles the plan against what Kati last armed:

    * push **on** — the plan's armed set is what the platform should hold;
    * push **off** — the intended set is empty, so everything this module armed
      is cancelled.

  What was armed is recorded in `Kati.Notifications.Pending`, restricted to the
  `:tv` domain and to ids under the `ep:` prefix this module produces, so a
  reconcile never touches another feature's alarms. `Kati.Notifications.Reconcile`
  emits no operation for an unchanged entry, so calling `sync/1` often is cheap.

  It runs when a switch that changes the answer moves on screen 25, when that
  screen's *Check now* completes, and on every boot (`Kati.App`) — the
  refresh-on-open net for air dates that changed while Kati was closed.

  A build with no delivery backend — the host, iOS — answers
  `{:error, :no_delivery}` and records nothing: `Kati.Notifications.Delivery.Inert`
  accepts every arm, and recording those as armed would be a record of alarms
  that do not exist.
  """

  alias Kati.Notifications.Delivery
  alias Kati.Notifications.Pending
  alias Kati.Notifications.Plan
  alias Kati.Notifications.Reconcile
  alias Kati.Notifications.Scheduler
  alias Kati.Settings.Watcher

  @doc """
  The plan push would arm right now, whether or not push is on.

  `opts`: `:now` (defaults to `Kati.Time.now/0`) and `:zone`, passed to the
  scheduler.
  """
  @spec plan(keyword()) :: Plan.t()
  def plan(opts \\ []) do
    Scheduler.plan(
      Kati.Screens.Inbox.alerts(),
      Keyword.merge(
        [platform: :android, now: Kati.Time.now(), quiet_hours: Watcher.quiet_hours()],
        opts
      )
    )
  end

  @doc """
  Make the platform hold exactly the release alerts the reader asked for.

  Answers `Kati.Notifications.Delivery.run/2`'s result — the ids armed, the ids
  cancelled, and any operation the platform refused — or `{:error, reason}`.
  Never raises.

  `opts`: `:backend` (defaults to `Kati.Notifications.Delivery.backend/0`) and
  `:now`.
  """
  @spec sync(keyword()) :: Delivery.result() | {:error, term()}
  def sync(opts \\ []) do
    backend = Keyword.get_lazy(opts, :backend, &Delivery.backend/0)

    if backend == Delivery.Inert do
      {:error, :no_delivery}
    else
      reconcile(backend, Keyword.get_lazy(opts, :now, &Kati.Time.now/0))
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  The release alerts Kati has recorded as armed, soonest first.
  """
  @spec armed() :: [Pending.t()]
  def armed do
    Pending
    |> Ash.Query.for_read(:for_domain, %{domain: :tv})
    |> Ash.read!()
    |> Enum.filter(&String.starts_with?(&1.id, "ep:"))
  end

  defp reconcile(backend, now) do
    rows = armed()

    intended =
      if Watcher.loud?(:push),
        do: plan(now: now),
        else: %Plan{platform: :android, now: now}

    result =
      intended
      |> Reconcile.operations(Enum.map(rows, &Pending.to_armed/1))
      |> Delivery.run(backend)

    record!(result, intended, Map.new(rows, &{&1.id, &1}), now)
    result
  end

  defp record!(result, plan, existing, now) do
    Enum.each(result.cancelled, fn id -> destroy(Map.get(existing, id)) end)

    by_id = Map.new(plan.armed, &{&1.id, &1})
    armed_at = utc(now)

    Enum.each(result.armed, fn id ->
      destroy(Map.get(existing, id))

      attrs =
        by_id
        |> Map.fetch!(id)
        |> Pending.from_candidate(armed_at)
        |> Map.update!(:fire_at_utc, &utc/1)

      Pending
      |> Ash.Changeset.for_create(:create, attrs)
      |> Ash.create!()
    end)
  end

  defp destroy(nil), do: :ok
  defp destroy(row), do: Ash.destroy!(row)

  defp utc(at), do: at |> DateTime.shift_zone!("Etc/UTC") |> DateTime.truncate(:second)
end
