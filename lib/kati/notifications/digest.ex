defmodule Kati.Notifications.Digest do
  @moduledoc """
  The nine-minute floor, and the one notification that satisfies it.

  Android's doze documentation is unambiguous: *"Neither `setAndAllowWhileIdle()`
  nor `setExactAndAllowWhileIdle()` can fire alarms more than once per nine
  minutes, per app."* Per **app** — not per alarm, not per domain. So three
  alarms armed for 08:00, 08:03 and 08:06 are one alarm that fires and two that
  are late, and nothing anywhere reports it.

  A digest is therefore not a nicety layered on top of a working scheduler; it
  is the mechanism that makes a cluster deliverable at all. It is also the
  cheaper answer in slots — *"prefer one digest notification per day ('3 new
  episodes tonight') over one per episode … collapses 3 slots into 1"* — and the
  better morning, which is why Kati runs it on both platforms rather than only
  where the doze rule bites.

  ## How a cluster is chosen

  Sorted by time, the first entry anchors a cluster and every entry within nine
  minutes of **the anchor** joins it. The next entry outside that window anchors
  the next cluster. Anchoring on the anchor rather than on the previous member
  is what makes the guarantee hold: two clusters are at least nine minutes
  apart, always, however densely the input was packed. A chain that measured
  each gap against the last member could walk a 07:00 entry to 08:00 in
  eight-minute steps and satisfy every local comparison while breaking the
  global rule.

  ## A digest fires at its earliest member

  Never later. Folding cannot delay anything, so an appointment alert swept into
  a digest still arrives before the appointment — that is why
  `Kati.Notifications.Candidate`'s `quiet_hours: :exempt` has no counterpart
  here. The members' ids ride along on the digest so a tap can open the right
  thing, and every folded member stays in the plan marked `:digested` with the
  id it went into, because a reminder that silently disappeared into a summary
  is indistinguishable from one that was lost.
  """

  alias Kati.Notifications.Candidate

  # Nine minutes, in seconds — the doze floor, not a taste decision.
  @min_gap 540

  @doc "The nine-minute floor in seconds, as the platform states it."
  @spec min_gap() :: pos_integer()
  def min_gap, do: @min_gap

  @doc """
  Collapse every cluster closer than `gap` seconds into one digest each.

  Returns `{kept, folded}`: `kept` is what should actually be armed, digests
  included, and `folded` is every member that went into one, suppressed as
  `:digested` with `%{into: digest_id}`. A `gap` of `false`, `nil` or `0` is the
  identity — useful when a caller wants the budget's answer without the
  clustering, and the only way to see the raw allocation in a test.
  """
  @spec collapse([Candidate.t()], pos_integer() | false | nil) ::
          {[Candidate.t()], [Candidate.t()]}
  def collapse(candidates, gap \\ @min_gap)

  def collapse(candidates, gap) when gap in [nil, false, 0], do: {candidates, []}

  def collapse(candidates, gap) when is_integer(gap) and gap > 0 do
    candidates
    |> Enum.sort_by(&Candidate.order_key/1)
    |> cluster(gap)
    |> Enum.reduce({[], []}, fn
      [alone], {kept, folded} ->
        {[alone | kept], folded}

      cluster, {kept, folded} ->
        digest = build(cluster)
        members = Enum.map(cluster, &Candidate.suppress(&1, :digested, %{into: digest.id}))
        {[digest | kept], members ++ folded}
    end)
    |> then(fn {kept, folded} -> {Enum.reverse(kept), Enum.reverse(folded)} end)
  end

  defp cluster(sorted, gap) do
    Enum.chunk_while(sorted, nil, &chunk(&1, &2, gap), &flush/1)
  end

  defp chunk(candidate, nil, _gap), do: {:cont, {candidate, [candidate]}}

  defp chunk(candidate, {anchor, members}, gap) do
    # Measured against the ANCHOR, never against the previous member — see the
    # moduledoc for the eight-minute walk that a chained comparison permits.
    if DateTime.diff(candidate.fire_at, anchor.fire_at) < gap do
      {:cont, {anchor, [candidate | members]}}
    else
      {:cont, Enum.reverse(members), {candidate, [candidate]}}
    end
  end

  defp flush(nil), do: {:cont, nil}
  defp flush({_anchor, members}), do: {:cont, Enum.reverse(members), nil}

  defp build([anchor | _rest] = cluster) do
    ids = cluster |> Enum.map(& &1.id) |> Enum.sort()
    domains = cluster |> Enum.map(& &1.domain) |> Enum.uniq()
    count = length(cluster)

    Candidate.absolute(
      # Keyed on the instant, so the same cluster re-planned produces the same
      # id and re-arms in place instead of stacking a second summary beside the
      # first. Clusters are at least nine minutes apart, so this cannot collide.
      Candidate.id(["digest", DateTime.to_unix(anchor.fire_at)]),
      anchor.domain,
      anchor.fire_at,
      title: title(count, domains),
      body: body(cluster),
      priority: highest(cluster),
      quiet_hours: :exempt,
      members: ids,
      meta: %{digest: true, domains: domains}
    )
  end

  # English, and a fallback: #61 owns localisation, and `Kati.Time.day_name/1`
  # takes the same position for the same reason.
  defp title(count, [domain]), do: "#{count} #{noun(domain, count)}"
  defp title(count, _mixed), do: "#{count} reminders"

  defp noun(:tv, 1), do: "new episode"
  defp noun(:tv, _many), do: "new episodes"
  defp noun(:calendar, 1), do: "event"
  defp noun(:calendar, _many), do: "events"
  defp noun(:habits, 1), do: "habit"
  defp noun(:habits, _many), do: "habits"
  defp noun(:meals, 1), do: "meal"
  defp noun(:meals, _many), do: "meals"
  defp noun(:health, 1), do: "health reminder"
  defp noun(:health, _many), do: "health reminders"
  defp noun(:money, 1), do: "renewal"
  defp noun(:money, _many), do: "renewals"

  defp body(cluster) do
    named = cluster |> Enum.map(& &1.title) |> Enum.reject(&is_nil/1)

    case Enum.split(named, 3) do
      {[], _rest} -> nil
      {shown, []} -> Enum.join(shown, " · ")
      {shown, rest} -> Enum.join(shown, " · ") <> " and #{length(rest)} more"
    end
  end

  defp highest(cluster) do
    Enum.min_by(cluster, &Candidate.rank(&1.priority)).priority
  end
end
