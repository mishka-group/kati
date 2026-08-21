defmodule Kati.Notifications.Reconcile do
  @moduledoc """
  Intended set plus armed set in, arm/cancel operations out. Nothing else.

  Kati **reconciles rather than accumulates**. Every foreground and every
  successful worker run recomputes the whole intended set and asks this module
  what would have to change on the platform for reality to match it. That is a
  deliberately expensive-sounding design and it is the cheap one: re-arming is
  idempotent (`MobNotify.schedule/2` upserts, and `FLAG_UPDATE_CURRENT` makes
  the alarm side idempotent too), while an accumulating scheduler has to be
  right about every incremental edit forever, and is wrong the first time a user
  force-stops the app.

  ## Why it is a pure function and not a loop with side effects

  AshSqlite reports `can?(:transact) == false`. There is no transaction to wrap
  a reconcile in, so "the process died halfway through" is a state that has to
  be *survivable*, not preventable. Splitting the decision from the application
  gives that for free:

    * every operation stands alone and means the same thing on its own;
    * applying a prefix of the list and running again produces the remaining
      operations, because the second run recomputes from the world as it now is;
    * applying the *whole* list twice is a no-op the second time —
      `operations(plan, armed_after(plan)) == []` — which is the idempotence
      test, not a claim in a comment.

  Cancels are emitted before arms, and arms in soonest-first order. An interrupt
  therefore leaves the platform holding the reminders the user needs first,
  and never leaves it over the cap with stale entries still armed.
  """

  alias Kati.Notifications.Armed
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Plan

  @type operation :: {:cancel, String.t()} | {:arm, Candidate.t()}

  @doc """
  What has to happen on the platform for `armed` to become `plan`.

  Three cases, and the third is the one that matters for cost: an entry already
  armed with the same time and text produces **no operation at all**. A user who
  foregrounds Kati six times an hour does not re-arm two hundred alarms six
  times an hour.

  An entry whose time or text moved produces `{:arm, candidate}` with no
  matching cancel — the id is stable, and arming a stable id is an upsert on
  both platforms. A cancel is emitted only when an id is genuinely gone.
  """
  @spec operations(Plan.t(), [Armed.t()]) :: [operation()]
  def operations(%Plan{armed: intended}, armed) when is_list(armed) do
    current = Armed.index(armed)
    wanted = MapSet.new(intended, & &1.id)

    cancels =
      armed
      |> Enum.reject(&MapSet.member?(wanted, &1.id))
      |> Enum.sort_by(& &1.id)
      |> Enum.map(&{:cancel, &1.id})

    arms =
      intended
      |> Enum.sort_by(&Candidate.order_key/1)
      |> Enum.filter(&changed?(Map.get(current, &1.id), &1))
      |> Enum.map(&{:arm, &1})

    cancels ++ arms
  end

  defp changed?(nil, _candidate), do: true

  defp changed?(%Armed{fingerprint: fingerprint}, candidate) do
    fingerprint != Candidate.fingerprint(candidate)
  end

  @doc """
  The armed set a plan implies once its operations have been applied.

  Feed it back into `operations/2` to prove a reconcile has settled, or hold it
  as the state the next foreground diffs against.
  """
  @spec armed_after(Plan.t(), DateTime.t() | nil) :: [Armed.t()]
  def armed_after(%Plan{armed: intended}, armed_at \\ nil) do
    Enum.map(intended, &Armed.from_candidate(&1, armed_at))
  end

  @doc """
  Armed entries whose moment has passed — the "you missed N" reconciliation.

  `RTC_WAKEUP` alarms do not fire while a device is off, a reboot wipes them,
  and the Kotlin re-arm explicitly drops past-due entries. So a missed alarm
  leaves no trace anywhere except here: an armed record whose `fire_at` is
  behind `now` on foreground either fired or was eaten, and the app cannot tell
  which. It can tell the *user*, in the app, which is what #59 asks for — and
  it must not re-arm it, because a reminder delivered a day late is worse than a
  banner saying it was missed.
  """
  @spec missed([Armed.t()], DateTime.t()) :: [Armed.t()]
  def missed(armed, %DateTime{} = now) when is_list(armed) do
    armed
    |> Enum.filter(&(DateTime.compare(&1.fire_at, now) != :gt))
    |> Enum.sort_by(&DateTime.to_unix(&1.fire_at, :microsecond))
  end
end
