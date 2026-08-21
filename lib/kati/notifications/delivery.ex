defmodule Kati.Notifications.Delivery do
  @moduledoc """
  The seam between deciding and delivering. Two callbacks, and no platform in
  either signature.

  `Kati.Notifications.Scheduler` produces operations; something has to perform
  them against `MobNotify` on Android, `UNUserNotificationCenter` on iOS, or
  nothing at all on the host. That something implements this behaviour, and the
  scheduler never learns which one it got — the only platform-shaped thing that
  reaches the decision layer is the atom naming which column of the allocation
  table to read.

  ## Why the behaviour is this small

  `arm/1` and `cancel/1` are the entire vocabulary because they are the entire
  vocabulary that both platforms actually support. Deliberately absent:

    * **listing what is pending.** Android cannot be asked, and the iOS answer
      reflects the system's own silent truncation rather than Kati's intent.
      `Kati.Notifications.Armed` is Kati's record instead.
    * **"is this already armed?"** — the fingerprint comparison in
      `Kati.Notifications.Reconcile` answers it without a round trip.

  So a backend is a dozen lines, and a backend that is wrong can be swapped
  without the budget rules moving.

  The vocabulary is not a guess: Kati's Android host already keeps
  `KatiNotificationStore`, whose whole public surface is
  `schedule(ctx, id, title, body, data, triggerAtMs)` and `cancel(ctx, id)`,
  keyed by the same stable id this layer produces. An Android backend is that
  pair plus a serialisation of `meta` and `members` into `data` for the tap
  handler; an iOS backend is `UNUserNotificationCenter`'s `add` and
  `removePendingNotificationRequests`. Neither needs to know a budget exists.

  ## Failures are values

  `arm/1` returns `{:error, reason}` rather than raising. Kati runs one screen
  process (see AGENTS.md); an exception raised while re-arming two hundred
  alarms on foreground takes the whole UI down with it. `run/2` collects the
  failures and returns them, so a permission that was revoked while the app was
  backgrounded turns into a diagnostic line rather than a black screen.
  """

  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Reconcile

  @doc "Arm one notification. The id is stable, so this is an upsert."
  @callback arm(Candidate.t()) :: :ok | {:error, term()}

  @doc """
  The backend for this build: the real one where a platform can arm something,
  `Kati.Notifications.Delivery.Inert` everywhere else.

  One function so that no screen, and no scheduler call site, ever asks "which
  platform am I on". The question it really answers is narrower than the
  platform anyway — `Kati.Notifications.Delivery.Android.available?/0` is false
  on a host, false on iOS, and false on an Android build whose NIF did not
  bind, and the correct behaviour is identical in all three.

  Notifications being **refused** is deliberately *not* part of this decision.
  A user who has denied `POST_NOTIFICATIONS` still gets a full plan — the
  in-app inbox renders from it — and the caller that wants to stop arming
  invisible alarms checks
  `Kati.Notifications.Delivery.Android.status/0` and installs `Inert` itself.
  Folding that in here would make the choice depend on a permission that can
  change while the app is running, and hide the reason from the screen that has
  to explain it.
  """
  @spec backend() :: module()
  def backend do
    if __MODULE__.Android.available?(), do: __MODULE__.Android, else: __MODULE__.Inert
  end

  @doc "Cancel by id. Cancelling something that is not armed must succeed."
  @callback cancel(String.t()) :: :ok | {:error, term()}

  @type result :: %{
          armed: [String.t()],
          cancelled: [String.t()],
          errors: [{Reconcile.operation(), term()}]
        }

  @doc """
  Perform a reconcile's operations in order, collecting what failed.

  In order matters: `Kati.Notifications.Reconcile` emits cancels first and arms
  soonest-first, so an interrupted run has released stale slots before it starts
  claiming new ones, and has armed the reminders needed first.
  """
  @spec run([Reconcile.operation()], module()) :: result()
  def run(operations, backend) when is_list(operations) and is_atom(backend) do
    Enum.reduce(operations, %{armed: [], cancelled: [], errors: []}, fn operation, acc ->
      apply_operation(operation, backend, acc)
    end)
    |> Map.update!(:armed, &Enum.reverse/1)
    |> Map.update!(:cancelled, &Enum.reverse/1)
    |> Map.update!(:errors, &Enum.reverse/1)
  end

  defp apply_operation({:arm, candidate} = operation, backend, acc) do
    case backend.arm(candidate) do
      :ok -> %{acc | armed: [candidate.id | acc.armed]}
      {:error, reason} -> %{acc | errors: [{operation, reason} | acc.errors]}
    end
  end

  defp apply_operation({:cancel, id} = operation, backend, acc) do
    case backend.cancel(id) do
      :ok -> %{acc | cancelled: [id | acc.cancelled]}
      {:error, reason} -> %{acc | errors: [{operation, reason} | acc.errors]}
    end
  end
end
