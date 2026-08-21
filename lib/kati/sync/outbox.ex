defmodule Kati.Sync.Outbox do
  @moduledoc """
  The queue every remote mutation goes through, and the rules that make
  replaying one safe.

  ## Enqueue authorises

  `enqueue/1` calls `Kati.Sync.Ownership.authorise/2` before it writes a row.
  That is the second of the two ownership gates: the editor's check stops the
  UI offering a write it may not make, and this one stops a write that reached
  the queue some other way. Neither delegates to the other.

  ## The idempotency key is generated once

  A create's key is derived from the event `UID`, which Kati generates
  client-side for everything it owns. An update's or delete's key includes the
  revision being pushed, so two different edits are two different keys and the
  *same* edit retried a hundred times is one. It is written at enqueue and is
  never regenerated — regenerating it on retry would destroy the only defence
  against a duplicate after an ambiguous timeout.

  ## Claiming is durable and happens before the request

  `claim/2` writes `:in_flight` and the incremented `attempt_count` **before**
  the transport is called. A process killed with the request on the wire
  therefore leaves evidence, and `recover/1` puts those entries back in the
  queue rather than losing them. That combination — durable claim plus a stable
  idempotency key — is what makes the airplane-mode cases produce one event
  instead of two.

  ## The one clock in the engine

  `next_attempt_at` is wall-clock time, and it is the only place the sync
  engine reads one. It decides **when to try again**, never **whose edit
  survives** — that comes from `local_rev`/`synced_rev` and etags, in modules
  `Kati.SyncBoundaryTest` proves never call a clock at all. A device three
  minutes fast retries three minutes early; nobody loses an edit.

  ## Ordering

  Due order is insertion order, and an entry whose `depends_on` is not `:done`
  is not due at any time. That is how "this and following" survives: trim the
  master, then create the successor, never the other way round and never the
  second without the first.
  """

  require Ash.Query

  alias Kati.Calendars.Calendar
  alias Kati.Sync.Backoff
  alias Kati.Sync.Capabilities
  alias Kati.Sync.OutboxEntry
  alias Kati.Sync.Ownership

  @default_batch 50

  @typedoc "Everything `enqueue/1` needs. `row` is the event or override being pushed."
  @type request :: %{
          required(:calendar) => Calendar.t(),
          required(:row) => map(),
          required(:op) => :create | :update | :delete,
          optional(:base_icalendar) => String.t() | nil,
          optional(:changed_properties) => %{String.t() => String.t() | nil},
          optional(:depends_on) => String.t() | nil,
          optional(:pushed_rev) => pos_integer() | nil
        }

  @doc """
  Queue one mutation, or refuse it.

  Refuses for two different reasons and says which: the ownership predicate
  (`{:not_writable, _}`) and the transport simply not being able to write
  (`{:read_only_transport, _}`). A read-only feed accumulating a queue it can
  never drain is the failure mode this second check exists to prevent.
  """
  @spec enqueue(request()) :: {:ok, OutboxEntry.t()} | {:error, term()}
  def enqueue(%{calendar: calendar, row: row, op: op} = request) do
    with :ok <- Ownership.authorise(row, calendar),
         :ok <- transport_permits(request, op) do
      pushed_rev = Map.get(request, :pushed_rev) || Map.get(row, :local_rev)

      payload =
        %{
          "base_icalendar" => Map.get(request, :base_icalendar),
          "changed_properties" => Map.get(request, :changed_properties, %{}),
          "remote_id" => Map.get(row, :remote_id),
          "remote_href" => Map.get(row, :remote_href),
          "if_match" => Map.get(row, :remote_etag),
          "pushed_rev" => pushed_rev
        }
        |> Jason.encode!()

      OutboxEntry
      |> Ash.Changeset.for_create(:create, %{
        account_id: calendar.account_id,
        calendar_id: calendar.id,
        event_uid: Map.fetch!(row, :uid),
        op: op,
        payload: payload,
        idempotency_key: idempotency_key(op, Map.fetch!(row, :uid), pushed_rev),
        depends_on: Map.get(request, :depends_on),
        next_attempt_at: DateTime.utc_now()
      })
      |> Ash.create()
    end
  end

  @doc """
  The idempotency key for one operation.

  A create keys on the `UID` alone: the same event created twice is the same
  create, whatever else happened in between. An update or delete keys on the
  revision as well, so a retry of revision 4 and a fresh push of revision 5 are
  different requests and neither suppresses the other.
  """
  @spec idempotency_key(:create | :update | :delete, String.t(), pos_integer() | nil) ::
          String.t()
  def idempotency_key(:create, uid, _rev), do: "create:" <> uid
  def idempotency_key(op, uid, rev), do: "#{op}:#{uid}:#{rev || 0}"

  @doc """
  Entries ready to go out for one calendar, oldest first.

  "Ready" is three conditions, and the third is the one people forget: the
  entry is `:pending`, its `next_attempt_at` has passed, and every entry it
  depends on is `:done`.
  """
  @spec due(String.t(), keyword()) :: [OutboxEntry.t()]
  def due(calendar_id, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    limit = Keyword.get(opts, :limit, @default_batch)

    OutboxEntry
    |> Ash.Query.filter(calendar_id == ^calendar_id and state == :pending)
    |> Ash.Query.sort(inserted_at: :asc)
    |> Ash.read!()
    |> Enum.filter(&due?(&1, now))
    |> Enum.take(limit)
  end

  @doc """
  Mark entries `:in_flight` and count the attempt, before anything is sent.

  This is deliberately a separate durable write from the request. If it were
  folded into the acknowledgement, a crash between the two would leave an entry
  that looks untried and would be sent a second time — which is the duplicate
  the whole outbox exists to prevent.
  """
  @spec claim([OutboxEntry.t()]) :: [OutboxEntry.t()]
  def claim(entries) do
    Enum.map(entries, fn entry ->
      entry
      |> Ash.Changeset.for_update(:update, %{
        state: :in_flight,
        attempt_count: entry.attempt_count + 1
      })
      |> Ash.update!()
    end)
  end

  @doc """
  Put orphaned `:in_flight` entries back in the queue.

  Run on foreground. Every one of them is an ambiguous timeout: the request may
  have landed, and the only honest thing to do is send it again with the same
  idempotency key and let the server say `409`/`412` if it already has it.
  """
  @spec recover(String.t() | nil) :: non_neg_integer()
  def recover(calendar_id \\ nil) do
    OutboxEntry
    |> filter_calendar(calendar_id)
    |> Ash.Query.filter(state == :in_flight)
    |> Ash.read!()
    |> Enum.map(fn entry ->
      entry
      |> Ash.Changeset.for_update(:update, %{
        state: :pending,
        next_attempt_at: retry_at(entry.attempt_count)
      })
      |> Ash.update!()
    end)
    |> length()
  end

  @doc "An entry landed."
  @spec succeed(OutboxEntry.t()) :: OutboxEntry.t()
  def succeed(entry) do
    entry
    |> Ash.Changeset.for_update(:update, %{state: :done, last_error: nil})
    |> Ash.update!()
  end

  @doc """
  An entry failed. The verdict decides whether it comes back.

  `:retry` and `:hard_backoff` return it to `:pending` with a delay;
  `:quarantine` and an exhausted attempt count park it in `:push_failed` where
  screen 27's error card can offer **Retry**; `:reauth` and `:conflict` park it
  in `:blocked`, because trying again cannot fix either of them.
  """
  @spec fail(OutboxEntry.t(), Backoff.verdict(), term()) :: OutboxEntry.t()
  def fail(entry, verdict, reason) do
    attrs =
      cond do
        verdict in [:reauth, :conflict] ->
          %{state: :blocked}

        verdict == :quarantine or Backoff.exhausted?(entry.attempt_count) ->
          %{state: :push_failed}

        true ->
          %{state: :pending, next_attempt_at: retry_at(entry.attempt_count, verdict)}
      end

    entry
    |> Ash.Changeset.for_update(:update, Map.put(attrs, :last_error, describe(reason)))
    |> Ash.update!()
  end

  @doc """
  Requeue a quarantined entry — screen 27's **Retry** button.

  Resets the attempt count, because the user pressing Retry is new information
  (they fixed something, or the network came back) and carrying eight failed
  attempts forward would quarantine it again on the next hiccup.
  """
  @spec retry(OutboxEntry.t()) :: OutboxEntry.t()
  def retry(entry) do
    entry
    |> Ash.Changeset.for_update(:update, %{
      state: :pending,
      attempt_count: 0,
      next_attempt_at: DateTime.utc_now(),
      last_error: nil
    })
    |> Ash.update!()
  end

  @doc "Every entry still referencing this event, in any state but `:done`."
  @spec open_entries(String.t(), String.t()) :: [OutboxEntry.t()]
  def open_entries(calendar_id, event_uid) do
    OutboxEntry
    |> Ash.Query.filter(
      calendar_id == ^calendar_id and event_uid == ^event_uid and state != :done
    )
    |> Ash.read!()
  end

  @doc """
  Event UIDs whose chain is half-landed: something succeeded and something did
  not.

  This is the "partially synced" badge. Losing it is how a failed
  "this and following" split becomes silent loss of future occurrences — the
  master's `UNTIL` was trimmed and its successor never arrived, and nothing on
  screen says so.
  """
  @spec partially_synced(String.t()) :: [String.t()]
  def partially_synced(calendar_id) do
    OutboxEntry
    |> Ash.Query.filter(calendar_id == ^calendar_id)
    |> Ash.read!()
    |> Enum.group_by(& &1.event_uid)
    |> Enum.filter(fn {_uid, entries} ->
      Enum.any?(entries, &(&1.state == :done)) and Enum.any?(entries, &(&1.state != :done))
    end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  @doc """
  Delete `:done` entries nothing depends on any more.

  Not a general GC: an entry another entry still points at stays, because
  `depends_on` resolving to nothing is indistinguishable from a dependency that
  never existed.
  """
  @spec collect(String.t()) :: non_neg_integer()
  def collect(calendar_id) do
    all = OutboxEntry |> Ash.Query.filter(calendar_id == ^calendar_id) |> Ash.read!()
    depended_on = MapSet.new(all, & &1.depends_on)

    all
    |> Enum.filter(&(&1.state == :done and not MapSet.member?(depended_on, &1.id)))
    |> Enum.map(&Ash.destroy!/1)
    |> length()
  end

  @doc "A one-line summary for screen 32's badge and screen 27's card."
  @spec status(String.t()) :: map()
  def status(calendar_id) do
    entries = OutboxEntry |> Ash.Query.filter(calendar_id == ^calendar_id) |> Ash.read!()

    %{
      pending: Enum.count(entries, &(&1.state in [:pending, :in_flight])),
      blocked: Enum.count(entries, &(&1.state == :blocked)),
      failed: Enum.count(entries, &(&1.state == :push_failed)),
      partially_synced: partially_synced(calendar_id)
    }
  end

  # ── Internals ──────────────────────────────────────────────────────────────

  defp filter_calendar(query, nil), do: query
  defp filter_calendar(query, calendar_id), do: Ash.Query.filter(query, calendar_id == ^calendar_id)

  defp due?(entry, now) do
    ready? = is_nil(entry.next_attempt_at) or DateTime.compare(entry.next_attempt_at, now) != :gt
    ready? and dependency_met?(entry)
  end

  defp dependency_met?(%OutboxEntry{depends_on: nil}), do: true

  defp dependency_met?(%OutboxEntry{depends_on: id}) do
    case Ash.get(OutboxEntry, id) do
      {:ok, %OutboxEntry{state: :done}} -> true
      # A dependency that cannot be found is treated as unmet, not as met. The
      # opposite default would let the successor of a lost trim-master run
      # alone, which is the exact silent loss `depends_on` exists to stop.
      _ -> false
    end
  end

  defp transport_permits(request, op) do
    case Map.get(request, :capabilities) do
      nil ->
        :ok

      capabilities ->
        if Capabilities.permits?(capabilities, op) do
          :ok
        else
          {:error, {:read_only_transport, %{op: op, capabilities: capabilities}}}
        end
    end
  end

  defp retry_at(attempts, verdict \\ :retry) do
    DateTime.add(DateTime.utc_now(), Backoff.delay_for(verdict, attempts, []), :millisecond)
  end

  defp describe(reason) when is_binary(reason), do: reason
  defp describe(reason), do: inspect(reason)
end
