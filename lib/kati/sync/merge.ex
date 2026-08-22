defmodule Kati.Sync.Merge do
  @moduledoc """
  Three-way property merge: base, local, remote.

  The base is what makes this a merge rather than a guess. It is the
  `raw_icalendar` as it stood **before** the local edit, carried in the outbox
  payload (`Kati.Sync.Operation.base_icalendar`) precisely so that at
  resolution time — which may be days later, after the entry has been retried
  through an airport — the engine can still tell "local set the location" apart
  from "local kept the location the server already had".

  Without a base there is no merge. Two documents that differ tell you nothing
  about who moved.

  ## The rule this module exists to enforce

  **Nothing is discarded.** Every stage either merges both sides, or names a
  winner *and hands back the loser's values* for `Kati.Sync.RejectedChange` to
  keep. A resolution that silently drops the user's edit is the failure this
  whole ticket exists to prevent, so it is not expressible in the return type:
  `{:resolved, winner, props, rejected}` always carries `rejected`.

  ## Resolution order

  1. **Disjoint property sets merge silently.** Local changed `SUMMARY`, remote
     changed `LOCATION` — both survive, nobody is asked anything. This is the
     large majority of real conflicts.

  2. **Overlap falls to ownership** (`Kati.Sync.Ownership`): `origin: :kati`
     means Kati is authoritative and local wins; `origin: :mirror` means the
     remote is authoritative and remote wins. Either way the loser's values are
     returned as a rejected change the user can re-apply.

  3. **The user decides** — screen 37's *Keep mine / Take file / Keep both* —
     but only for the cases below, which the previous two stages genuinely
     cannot answer.

  ## What is deliberately *not* mergeable

    * **Entangled timing.** `DTSTART`, `DTEND`, `DURATION`, `RRULE`, `RDATE`,
      `EXDATE` and `RECURRENCE-ID` are one interlocked description of when the
      event happens. Local moving `DTSTART` to 10:00 while remote changes
      `RRULE` from weekly to daily are *disjoint property names* and merging
      them produces a daily 10:00 series nobody authored. So a change inside
      this set on **both** sides is treated as overlap even when the names
      differ, and goes to stage 2.

    * **Delete versus edit — unresolvable.** One side removed the resource, the
      other edited it. There is no property merge, and ownership cannot help:
      applying the delete destroys an edit that a tombstone cannot carry, and
      ignoring it resurrects something the user deleted. *Keep both* — restore
      the row and re-apply the edit — is a real outcome that neither side's
      rule expresses, so this is exactly the case worth interrupting someone
      for. Returns `{:unresolvable, :delete_edit, context}`.

    * **A missing base — unresolvable.** A row that is dirty but has no base
      (the outbox entry was quarantined, or the edit predates the outbox) is
      not mergeable and must not be quietly overwritten by the remote. Returns
      `{:unresolvable, :no_base, context}`.

  ## No clocks

  Nothing here reads a timestamp. Precedence comes from the base diff and from
  `origin`, never from `LAST-MODIFIED`, `DTSTAMP` or the device clock — a phone
  three minutes fast, or set to 2019, changes no outcome in this module.
  `Kati.SyncBoundaryTest` asserts that by reading the source.
  """

  alias Kati.Sync.ICalendar

  @entangled ~w(DTSTART DTEND DURATION RRULE RDATE EXDATE RECURRENCE-ID)

  @typedoc "One side of the merge: the properties it holds, or the fact it is gone."
  @type side :: {:present, ICalendar.properties()} | :deleted

  @typedoc "The losing values, with the base they were a change from."
  @type rejected :: %{
          side: :local | :remote,
          reason: :ownership_kati | :ownership_mirror,
          properties: %{String.t() => [String.t()] | nil},
          base_properties: %{String.t() => [String.t()] | nil}
        }

  @type result ::
          {:merged, side()}
          | {:resolved, :local | :remote, ICalendar.properties(), rejected()}
          | {:unresolvable, :delete_edit | :no_base, map()}

  @doc """
  Merge three property maps under an ownership rule.

  `origin` is the event's own `:kati | :mirror`, not the calendar's — a Kati
  event living in a Google calendar is still Kati's, which is the whole reason
  `origin` is a column and not an inference.
  """
  @spec merge(ICalendar.properties() | nil, side(), side(), :kati | :mirror) :: result()
  def merge(nil, {:present, local}, {:present, remote}, _origin) do
    {:unresolvable, :no_base, %{reason: :no_base, local: local, remote: remote}}
  end

  def merge(_base, :deleted, :deleted, _origin), do: {:merged, :deleted}

  def merge(base, :deleted, {:present, remote}, _origin) do
    if changed?(base, remote) do
      {:unresolvable, :delete_edit,
       %{deleted_by: :local, edited_by: :remote, base: base, remote: remote}}
    else
      # The remote never moved, so the local delete is uncontested.
      {:merged, :deleted}
    end
  end

  def merge(base, {:present, local}, :deleted, _origin) do
    if changed?(base, local) do
      {:unresolvable, :delete_edit,
       %{deleted_by: :remote, edited_by: :local, base: base, local: local}}
    else
      # Not locally dirty: the remote deletion applies, which is exactly
      # `Kati.Sync.Tombstone`'s "remove the mirror row unless it is dirty".
      {:merged, :deleted}
    end
  end

  def merge(base, {:present, local}, {:present, remote}, origin)
      when is_map(base) and origin in [:kati, :mirror] do
    local_diff = diff(base, local)
    remote_diff = diff(base, remote)
    contested = contested(local_diff, remote_diff)

    if contested == [] do
      {:merged, {:present, apply_diff(apply_diff(base, remote_diff), local_diff)}}
    else
      resolve_by_ownership(base, local_diff, remote_diff, contested, origin)
    end
  end

  @doc """
  The same merge, but over documents, returning bytes.

  The winning document is built by patching the **remote** bytes, never the
  local ones. The remote copy is the freshest thing the server sent and carries
  any vendor property it added while Kati was offline; patching it with the
  local side's winning lines preserves both. Rebuilding from the local copy
  would throw away everything the server learned in the meantime.
  """
  @spec merge_raw(
          String.t() | nil,
          String.t() | :deleted,
          String.t() | :deleted,
          :kati | :mirror
        ) ::
          {:merged, String.t() | :deleted}
          | {:resolved, :local | :remote, String.t(), rejected()}
          | {:unresolvable, :delete_edit | :no_base, map()}
          | {:error, :no_vevent}
  def merge_raw(base_raw, local_raw, remote_raw, origin) do
    with {:ok, base} <- parse_base(base_raw),
         {:ok, local} <- parse(local_raw),
         {:ok, remote} <- parse(remote_raw) do
      case merge(base, local, remote, origin) do
        {:merged, {:present, props}} ->
          {:merged, rebuild(remote_raw, remote, props)}

        {:merged, :deleted} ->
          {:merged, :deleted}

        {:resolved, winner, props, rejected} ->
          {:resolved, winner, rebuild(remote_raw, remote, props), rejected}

        other ->
          other
      end
    end
  end

  # ── Internals ──────────────────────────────────────────────────────────────

  defp parse_base(nil), do: {:ok, nil}

  defp parse_base(raw) when is_binary(raw) do
    case ICalendar.properties(raw) do
      {:ok, props} -> {:ok, props}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse(:deleted), do: {:ok, :deleted}

  defp parse(raw) when is_binary(raw) do
    case ICalendar.properties(raw) do
      {:ok, props} -> {:ok, {:present, props}}
      {:error, reason} -> {:error, reason}
    end
  end

  # merge/4 wants a bare map for the base and a tagged side for the others.
  defp rebuild(remote_raw, {:present, remote_props}, merged_props) do
    delta =
      merged_props
      |> Enum.reject(fn {name, lines} -> Map.get(remote_props, name) == lines end)
      |> Map.new()

    removed = for name <- Map.keys(remote_props), not Map.has_key?(merged_props, name), do: name

    {:ok, raw} =
      ICalendar.apply_lines(remote_raw, Map.merge(delta, Map.new(removed, &{&1, nil})))

    raw
  end

  defp changed?(base, side) when is_map(base) and is_map(side), do: diff(base, side) != %{}
  defp changed?(nil, _side), do: true

  # `nil` in a diff means "this property is gone on that side".
  defp diff(base, side) do
    names = MapSet.union(MapSet.new(Map.keys(base)), MapSet.new(Map.keys(side)))

    names
    |> Enum.reduce(%{}, fn name, acc ->
      base_value = Map.get(base, name)
      side_value = Map.get(side, name)

      if base_value == side_value, do: acc, else: Map.put(acc, name, side_value)
    end)
  end

  # Overlap is a name both sides changed to *different* values, plus the
  # entangled-timing rule: any timing change on both sides is contested even
  # when the property names are different.
  defp contested(local_diff, remote_diff) do
    direct =
      local_diff
      |> Map.keys()
      |> Enum.filter(fn name ->
        Map.has_key?(remote_diff, name) and local_diff[name] != remote_diff[name]
      end)

    local_timing = Enum.filter(Map.keys(local_diff), &(&1 in @entangled))
    remote_timing = Enum.filter(Map.keys(remote_diff), &(&1 in @entangled))

    timing =
      if local_timing != [] and remote_timing != [] and
           Map.take(local_diff, local_timing) != Map.take(remote_diff, remote_timing) do
        local_timing ++ remote_timing
      else
        []
      end

    (direct ++ timing) |> Enum.uniq() |> Enum.sort()
  end

  defp resolve_by_ownership(base, local_diff, remote_diff, contested, origin) do
    {winner, winner_diff, loser_diff, reason} =
      case origin do
        :kati -> {:local, local_diff, remote_diff, :ownership_kati}
        :mirror -> {:remote, remote_diff, local_diff, :ownership_mirror}
      end

    merged =
      base
      |> apply_diff(Map.drop(loser_diff, contested))
      |> apply_diff(Map.drop(winner_diff, contested))
      |> apply_diff(Map.take(winner_diff, contested))

    rejected = %{
      side: if(winner == :local, do: :remote, else: :local),
      reason: reason,
      properties: Map.take(loser_diff, contested),
      base_properties: Map.new(contested, &{&1, Map.get(base, &1)})
    }

    {:resolved, winner, merged, rejected}
  end

  defp apply_diff(props, diff) do
    Enum.reduce(diff, props, fn
      {name, nil}, acc -> Map.delete(acc, name)
      {name, lines}, acc -> Map.put(acc, name, lines)
    end)
  end
end
