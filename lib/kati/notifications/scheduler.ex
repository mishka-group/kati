defmodule Kati.Notifications.Scheduler do
  @moduledoc """
  The one budget owner: which notifications should exist, when, and which do not.

  Six domains want reminders and both platforms cap the app rather than the
  feature, so somebody has to divide a fixed number of slots between them. If
  that somebody is "whichever feature was written last", the division is
  discovered on a user's phone — as a silent truncation on iOS or a thrown
  `IllegalStateException` on Android. This module is that somebody, written
  before the six reminder features rather than retrofitted into them.

  ## It decides; it does not deliver

  `plan/2` is a pure function from a list of `Kati.Notifications.Candidate`
  structs to a `Kati.Notifications.Plan`. It calls no platform API, holds no
  state, and does not know which OS it is on — the platform reaches it as the
  atom `:android` or `:ios` in the options, and its only use is to pick a column
  out of `Kati.Notifications.Budget`. Delivery is #58's concern and arrives
  through the `Kati.Notifications.Delivery` behaviour, so a backend can be
  swapped without this module changing.

  That split is also what makes the budget testable. "Six hundred candidates in,
  fifty out, and here are the fifty" is an assertion about a value.

  ## The pipeline, in order, and why that order

      resolve → carry gates → dedupe → drop past → quiet hours → budget → digest

  1. **Resolve.** Wall-clock candidates become instants in the user's current
     zone, through `Kati.Time`, which owns the DST gap and ambiguity answers.
     Absolute candidates are already instants and do not move. Re-planning after
     a timezone change is the *whole* of the rebuild story: the same candidates
     produce new instants for wall-clock entries and identical ones for absolute
     entries, with no second code path to keep in step.
  2. **Carry the gates' refusals.** `{:suppressed, :muted}` from
     `Kati.Media.Release.alarm_at/3` travels into the plan unaltered. Kati has
     exactly one release gate, and it is not re-implemented here.
  3. **Dedupe by id.** Two candidates for the same reminder arm one alarm on the
     platform, so they must count as one slot here too. The earlier instant
     wins.
  4. **Drop the past.** A plan is about the future; `rearmAll` on the Kotlin
     side drops past-due entries anyway, and re-arming one would be a stale
     notification rather than a reminder.
  5. **Quiet hours.** 23:00–08:00 **shifts**, never suppresses. Before the
     budget, because shifting changes what "soonest" means.
  6. **Budget.** Per domain, keep the soonest N and shed the furthest-future
     rest — never the soonest. Per domain rather than globally, so the shed set
     does not depend on the order the domains were collected in.
  7. **Digest.** Anything violating the nine-minute floor collapses into one
     notification that fires at the earliest member's instant. Last, per #59's
     step 3, and it only ever *reduces* the armed count — so the budget stays a
     ceiling. Freed slots are deliberately not refilled: which entries got
     shed would then depend on how the survivors happened to cluster, and that
     is not something a user or a test could predict.

  ## Using it

      iex> now = ~U[2026-08-21 10:00:00Z]
      iex> candidates = [
      ...>   Kati.Notifications.Candidate.absolute("ep:tmdb:1396", :tv, ~U[2026-08-22 17:00:00Z],
      ...>     title: "Wilderness"),
      ...>   Kati.Notifications.Candidate.absolute("ev:9", :calendar, ~U[2026-08-19 09:00:00Z],
      ...>     title: "Dentist")
      ...> ]
      iex> plan = Kati.Notifications.Scheduler.plan(candidates,
      ...>   platform: :ios, now: now, zone: "Etc/UTC")
      iex> Kati.Notifications.Plan.armed_ids(plan)
      ["ep:tmdb:1396"]
      iex> Kati.Notifications.Plan.reason(plan, "ev:9")
      :past

  ## Options

    * `:platform` — `:android` or `:ios`. Required; there is no default, because
      guessing wrong picks the wrong cliff.
    * `:now` — defaults to `DateTime.utc_now/0`. Injected by every test.
    * `:zone` — IANA id for wall-clock resolution and quiet hours. Defaults to
      `Kati.Time.device_zone/0`, read fresh so a user who has just flown is not
      served a stale zone.
    * `:quiet_hours` — a `Kati.Notifications.QuietHours` struct, or `false` when
      the user has turned the rule off.
    * `:min_gap` — the nine-minute floor in seconds, or `false` to keep every
      entry discrete.
  """

  alias Kati.Notifications.Armed
  alias Kati.Notifications.Budget
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Digest
  alias Kati.Notifications.Plan
  alias Kati.Notifications.QuietHours
  alias Kati.Notifications.Reconcile

  @spec plan([Candidate.t()], keyword()) :: Plan.t()
  def plan(candidates, opts \\ []) when is_list(candidates) do
    platform = platform!(opts)
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    zone = Keyword.get_lazy(opts, :zone, &Kati.Time.device_zone/0)
    quiet = Keyword.get(opts, :quiet_hours, QuietHours.default())
    gap = Keyword.get(opts, :min_gap, Digest.min_gap())

    {live, refused} =
      candidates
      |> Enum.map(&Candidate.resolve(&1, zone))
      |> Enum.split_with(&Candidate.live?/1)

    {live, duplicates} = dedupe(live)
    {live, past} = drop_past(live, now)

    live = Enum.map(live, &quiet_hours(&1, quiet, zone))

    {selected, over_budget} = allocate(live, platform)
    {armed, digested} = Digest.collapse(selected, gap)

    %Plan{
      armed: Enum.sort_by(armed, &Candidate.order_key/1),
      suppressed: refused ++ duplicates ++ past ++ over_budget ++ digested,
      platform: platform,
      now: now,
      zone: zone
    }
  end

  @doc """
  Plan, then diff against what is already armed: `{plan, operations}`.

  The single entry point for a foreground reconcile. See
  `Kati.Notifications.Reconcile` for the shape of the operations and for why
  they are safe to apply halfway and run again — AshSqlite reports
  `can?(:transact) == false`, so "interrupted" is a state this has to survive
  rather than prevent.
  """
  @spec reconcile([Candidate.t()], [Armed.t()], keyword()) :: {Plan.t(), [Reconcile.operation()]}
  def reconcile(candidates, armed, opts \\ []) do
    plan = plan(candidates, opts)
    {plan, Reconcile.operations(plan, armed)}
  end

  defp platform!(opts) do
    platform = Keyword.get(opts, :platform)

    if platform in Budget.platforms() do
      platform
    else
      raise ArgumentError,
            "Kati.Notifications.Scheduler needs :platform — one of " <>
              "#{inspect(Budget.platforms())}, got #{inspect(platform)}. " <>
              "The allocation table has a column per platform and no default."
    end
  end

  # First writer of an id wins on ties; the earlier instant wins otherwise. Both
  # halves matter — the same event collected twice must not hold two slots, and
  # a re-planned candidate whose time moved earlier must not be shadowed by the
  # stale copy.
  defp dedupe(candidates) do
    {kept, duplicates} =
      candidates
      |> Enum.with_index()
      |> Enum.group_by(fn {candidate, _index} -> candidate.id end)
      |> Enum.reduce({[], []}, fn {_id, group}, {kept, duplicates} ->
        [winner | losers] =
          Enum.sort_by(group, fn {candidate, index} ->
            {DateTime.to_unix(candidate.fire_at, :microsecond), index}
          end)

        {[winner | kept], losers ++ duplicates}
      end)

    {
      kept |> restore_order(),
      duplicates
      |> restore_order()
      |> Enum.map(&Candidate.suppress(&1, :duplicate))
    }
  end

  defp restore_order(indexed) do
    indexed |> Enum.sort_by(fn {_candidate, index} -> index end) |> Enum.map(&elem(&1, 0))
  end

  defp drop_past(candidates, now) do
    {live, past} =
      Enum.split_with(candidates, fn candidate ->
        DateTime.compare(candidate.fire_at, now) == :gt
      end)

    {live, Enum.map(past, &Candidate.suppress(&1, :past))}
  end

  defp quiet_hours(candidate, false, _zone), do: candidate
  defp quiet_hours(%Candidate{quiet_hours: :exempt} = candidate, _window, _zone), do: candidate

  defp quiet_hours(candidate, %QuietHours{} = window, zone) do
    case QuietHours.shift(window, candidate.fire_at, zone) do
      {:shifted, at} -> %{candidate | fire_at: at, shifted_from: candidate.fire_at}
      :keep -> candidate
    end
  end

  defp allocate(candidates, platform) do
    candidates
    |> Enum.group_by(& &1.domain)
    |> Enum.reduce({[], []}, fn {domain, group}, {kept, shed} ->
      limit = Budget.limit(platform, domain)

      {take, drop} =
        group
        |> Enum.sort_by(&Candidate.order_key/1)
        |> Enum.split(limit)

      shed_here =
        Enum.map(drop, &Candidate.suppress(&1, :over_budget, %{limit: limit, domain: domain}))

      {kept ++ take, shed ++ shed_here}
    end)
  end
end
