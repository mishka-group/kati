defmodule Kati.Sync.Engine do
  @moduledoc """
  Pull in, push out, and everything that has to be decided in between.

  The engine names no transport. It is handed an `adapter` module implementing
  `Kati.Sync.Adapter` and never learns which one it is —
  `Kati.SyncBoundaryTest` reads every file under `lib/` and fails the build if a
  concrete adapter is referenced from above this line. That is what makes the
  later CalDAV and EventKit adapters cheap, and it is also why
  `ContentResolver` knowledge lives strictly below `Kati.Sync.Adapter`.

  ## Cadence

  There is no background BEAM: Mob cannot boot a headless runtime from a Worker
  and iOS cannot do background discovery at all. Google push is out too — the
  webhook must be HTTPS with a CA-signed certificate and Kati has no server. So
  Kati syncs on **app foreground, pull-to-sync, and explicit user action**, and
  screen 32's Live/Stale badge is driven by the real
  `last_sync_at`, not by a spinner. That is honest and it is what the design
  already draws.

  ## Order of operations in `sync/3`

  1. `Kati.Sync.Outbox.recover/1` — every `:in_flight` entry is an ambiguous
     timeout from a previous run and goes back in the queue with its original
     idempotency key.
  2. **Pull first, then push.** Pulling first means a conflict is discovered
     before the push rather than as a `412` after it, so the merge runs against
     bytes already in hand instead of costing another round trip.
  3. `apply_pull/3` in bounded transactional batches.
  4. `drain/3`.
  5. Cursor and `last_sync_at` are written **only on success**, so a failed
     sync leaves the badge honest.

  ## `410 Gone`

  `{:error, :cursor_invalid}` clears the mirror rows for **that calendar only**
  and keeps the outbox and every Kati-owned event. Google's own sample calls
  `eventDataStore.clear()` at this point, which is correct for a pure mirror and
  catastrophic here: it would delete the user's own events and every queued
  mutation that had not landed yet.
  """

  require Ash.Query

  alias Kati.Calendars.Account
  alias Kati.Calendars.Calendar
  alias Kati.Calendars.Event
  alias Kati.Sync.Backoff
  alias Kati.Sync.Batch
  alias Kati.Sync.Conflict
  alias Kati.Sync.ICalendar
  alias Kati.Sync.Merge
  alias Kati.Sync.Operation
  alias Kati.Sync.Outbox
  alias Kati.Sync.RejectedChange
  alias Kati.Sync.Revision
  alias Kati.Sync.Tombstone

  @typedoc "What one pull change did to the local store."
  @type outcome ::
          :inserted | :updated | :deleted | :unchanged | :kept_local | :suppressed | :conflict

  @doc """
  One full cycle against one calendar.

  Returns the counts screen 32 renders, or an error with the local store
  untouched apart from whatever the pull already applied.
  """
  @spec sync(Calendar.t(), module(), keyword()) :: {:ok, map()} | {:error, term()}
  def sync(%Calendar{} = calendar, adapter, opts \\ []) do
    Outbox.recover(calendar.id)

    case adapter.pull(calendar, calendar.sync_cursor) do
      {:ok, changes, cursor} ->
        pulled = apply_pull(calendar, changes, opts)
        pushed = drain(calendar, adapter, opts)
        calendar = commit_cursor(calendar, cursor)
        mark_account(calendar, :live)
        {:ok, %{pulled: pulled, pushed: pushed, cursor: calendar.sync_cursor}}

      {:error, :cursor_invalid} ->
        recover_cursor(calendar)
        {:error, :cursor_invalid}

      {:error, reason} ->
        mark_account(calendar, :stale)
        {:error, reason}
    end
  end

  # ── Pull ───────────────────────────────────────────────────────────────────

  @doc """
  Apply what the transport says changed upstream.

  Runs in bounded transactional chunks: one chunk is atomic, a whole sync is
  not, and does not need to be — every change is independently meaningful, and
  holding SQLite's single write connection for the length of an account sync is
  a UI that has stopped responding.
  """
  @spec apply_pull(Calendar.t(), [Kati.Sync.Change.t()], keyword()) :: %{
          outcome() => pos_integer()
        }
  def apply_pull(%Calendar{} = calendar, changes, opts \\ []) do
    changes
    |> Batch.run(&apply_change(calendar, &1, opts), size: Keyword.get(opts, :size, 50))
    |> Enum.frequencies()
  end

  defp apply_change(calendar, %{kind: :delete} = change, _opts) do
    case find_row(calendar, change) do
      nil ->
        :unchanged

      %Event{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        :unchanged

      event ->
        case Tombstone.apply_remote_delete(event) do
          {:ok, _} ->
            :deleted

          # An unsent local edit under an upstream deletion. The row is not
          # deleted and the queued push is not sent: both would decide
          # something only the user can. Screen 37 asks.
          {:conflict, conflicted} ->
            block_entry(calendar, conflicted, :delete_edit)
            :conflict
        end
    end
  end

  defp apply_change(calendar, %{kind: :upsert} = change, opts) do
    row = find_row(calendar, change)

    cond do
      Tombstone.suppressed?(row, opts) ->
        # The row is tombstoned and within retention. Whatever the server
        # thinks, the user deleted it; a resurrection here is the bug the
        # tombstone table exists to prevent.
        :suppressed

      is_nil(row) ->
        insert_mirror(calendar, change)
        :inserted

      true ->
        reconcile(calendar, row, change)
    end
  end

  defp reconcile(calendar, row, change) do
    case Conflict.detect(row, change.etag) do
      :clean -> refresh_identity(row, change)
      :remote_only -> apply_remote(row, change)
      :local_only -> :kept_local
      :conflict -> resolve_conflict(calendar, row, change)
    end
  end

  # Neither side moved. The row still needs a write if the transport handed
  # back an identity it did not have — the common case being a push that
  # returned no ETag, which the next pull fills in. Skipping the write when
  # there is nothing new matters: a foreground sync of a quiet calendar should
  # not rewrite every row and wake every screen that watches the table.
  defp refresh_identity(row, change) do
    ref = remote_ref(change)

    news? =
      Enum.any?(
        [{:id, :remote_id}, {:etag, :remote_etag}, {:href, :remote_href}],
        fn {key, column} ->
          value = Map.get(ref, key)
          not is_nil(value) and value != Map.get(row, column)
        end
      )

    if news? or row.sync_state != :clean do
      row
      |> Ash.Changeset.for_update(:update, Revision.mark_pulled(row, ref))
      |> Ash.update!()
    end

    :unchanged
  end

  defp apply_remote(row, change) do
    attrs =
      change
      |> projection()
      |> Map.merge(Revision.mark_pulled(row, remote_ref(change)))

    row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
    :updated
  end

  defp insert_mirror(calendar, change) do
    attrs =
      change
      |> projection()
      |> Map.merge(%{
        uid: change.uid,
        calendar_id: calendar.id,
        origin: :mirror,
        # A freshly mirrored row is clean, not dirty: `local_rev` defaults to 1
        # and `synced_rev` to 0, which would otherwise read as an unsent local
        # edit and make every foreground push the server's own data back at it.
        synced_rev: 1,
        sync_state: :clean,
        remote_id: change.remote_id,
        remote_href: change.remote_href,
        remote_etag: change.etag
      })

    Event |> Ash.Changeset.for_create(:create, attrs) |> Ash.create!()
  end

  # ── Conflict resolution ────────────────────────────────────────────────────

  defp resolve_conflict(calendar, row, change) do
    entry = List.first(Outbox.open_entries(calendar.id, row.uid))
    {base, local_raw} = local_side(row, entry)

    case Merge.merge_raw(base, local_raw, change.raw_icalendar, row.origin) do
      {:merged, merged_raw} when is_binary(merged_raw) ->
        adopt_merge(row, change, merged_raw, entry)
        :updated

      {:resolved, _winner, merged_raw, rejected} ->
        record_rejected(calendar, row, rejected)
        adopt_merge(row, change, merged_raw, entry)
        :updated

      {:merged, :deleted} ->
        Tombstone.apply_remote_delete(row)
        :deleted

      {:unresolvable, reason, _context} ->
        park_conflict(row, change, entry, reason)
        :conflict

      {:error, _reason} ->
        park_conflict(row, change, entry, :unparseable)
        :conflict
    end
  end

  # The local document is the base with Kati's own changes applied — never the
  # row's stored bytes, which are still the base until a push succeeds.
  defp local_side(row, nil), do: {nil, row.raw_icalendar}

  defp local_side(row, entry) do
    case Operation.from_entry(entry) do
      {:ok, operation} ->
        base = operation.base_icalendar || row.raw_icalendar

        case base && ICalendar.apply_lines(base, operation.changed_properties) do
          {:ok, local} -> {base, local}
          _ -> {base, row.raw_icalendar}
        end

      _ ->
        {nil, row.raw_icalendar}
    end
  end

  # A merged document still has to reach the server: it holds local changes the
  # remote has never seen. So the row goes back to `:dirty` and the outbox entry
  # is rewritten to push the merge, with the remote's freshest bytes as its new
  # base and the remote's etag as its new `If-Match`.
  defp adopt_merge(row, change, merged_raw, entry) do
    updated =
      row
      |> Ash.Changeset.for_update(:update, %{
        raw_icalendar: merged_raw,
        remote_etag: change.etag,
        remote_id: change.remote_id || row.remote_id,
        sync_state: :dirty
      })
      |> Ash.update!()

    if entry, do: requeue_merge(entry, updated, change, merged_raw)
    updated
  end

  defp requeue_merge(entry, row, change, merged_raw) do
    {:ok, remote_props} = ICalendar.properties(change.raw_icalendar)
    {:ok, merged_props} = ICalendar.properties(merged_raw)

    delta =
      merged_props
      |> Enum.reject(fn {name, lines} -> Map.get(remote_props, name) == lines end)
      |> Map.new(fn {name, lines} -> {name, List.first(lines)} end)

    payload =
      Jason.encode!(%{
        "base_icalendar" => change.raw_icalendar,
        "changed_properties" => delta,
        "remote_id" => change.remote_id || row.remote_id,
        "remote_href" => change.remote_href || row.remote_href,
        "if_match" => change.etag,
        "pushed_rev" => row.local_rev
      })

    entry
    |> Ash.Changeset.for_update(:update, %{
      payload: payload,
      state: :pending,
      attempt_count: 0,
      last_error: nil,
      next_attempt_at: DateTime.utc_now(),
      # A genuinely different request — different revision, different base — so
      # a genuinely different key. Reusing the old one would let a server that
      # had already accepted the pre-merge push suppress the merge.
      idempotency_key: Outbox.idempotency_key(entry.op, entry.event_uid, row.local_rev)
    })
    |> Ash.update!()
  end

  # Nothing is decided and nothing is lost: the row holds the remote's bytes,
  # the entry still holds the base and the local edit, and screen 37 asks.
  defp park_conflict(row, change, entry, reason) do
    row
    |> Ash.Changeset.for_update(:update, %{
      raw_icalendar: change.raw_icalendar || row.raw_icalendar,
      remote_etag: change.etag,
      sync_state: :conflicted
    })
    |> Ash.update!()

    if entry do
      entry
      |> Ash.Changeset.for_update(:update, %{state: :blocked, last_error: to_string(reason)})
      |> Ash.update!()
    end
  end

  defp block_entry(calendar, row, reason) do
    case List.first(Outbox.open_entries(calendar.id, row.uid)) do
      nil ->
        :ok

      entry ->
        entry
        |> Ash.Changeset.for_update(:update, %{state: :blocked, last_error: to_string(reason)})
        |> Ash.update!()
    end
  end

  defp record_rejected(calendar, row, rejected) do
    RejectedChange
    |> Ash.Changeset.for_create(:create, %{
      calendar_id: calendar.id,
      event_uid: row.uid,
      side: rejected.side,
      reason: rejected.reason,
      properties: Jason.encode!(rejected.properties),
      base_properties: Jason.encode!(rejected.base_properties)
    })
    |> Ash.create!()
  end

  # ── Push ───────────────────────────────────────────────────────────────────

  @doc """
  Drain one batch of the outbox through the adapter.

  The three steps are separate on purpose. Claiming is a durable write that
  happens **before** the request, so a process killed with the request on the
  wire leaves evidence rather than looking untried. The request itself is made
  outside any transaction, because holding SQLite's one write connection across
  a network call is how a slow server freezes the UI. Acknowledgement is a
  third write, in bounded transactional chunks.
  """
  @spec drain(Calendar.t(), module(), keyword()) :: map()
  def drain(%Calendar{} = calendar, adapter, opts \\ []) do
    entries = Outbox.due(calendar.id, opts)
    {decodable, broken} = decode(entries)

    Enum.each(broken, &Outbox.fail(&1, :quarantine, :bad_payload))

    claimed = Outbox.claim(Enum.map(decodable, &elem(&1, 0)))
    by_id = Map.new(claimed, &{&1.id, &1})
    operations = Enum.map(decodable, &elem(&1, 1))

    results = if operations == [], do: [], else: adapter.push(calendar, operations)

    results
    |> Batch.run(fn {operation, result} ->
      acknowledge(calendar, Map.fetch!(by_id, operation.id), operation, result)
    end)
    |> Enum.frequencies()
    |> Map.put(:quarantined_payloads, length(broken))
  end

  defp decode(entries) do
    Enum.reduce(entries, {[], []}, fn entry, {ok, bad} ->
      case Operation.from_entry(entry) do
        {:ok, operation} -> {ok ++ [{entry, operation}], bad}
        {:error, _} -> {ok, bad ++ [entry]}
      end
    end)
  end

  defp acknowledge(calendar, entry, operation, :ok), do: land(calendar, entry, operation, %{})

  defp acknowledge(calendar, entry, operation, {:ok, ref}),
    do: land(calendar, entry, operation, ref)

  # A `409`/`412` on a create means the idempotency key did its job: the event
  # is already there. Treating it as a failure is how one lost response becomes
  # two identical events.
  defp acknowledge(calendar, entry, %Operation{op: :create} = operation, {:conflict, ref}),
    do: land(calendar, entry, operation, ref)

  defp acknowledge(_calendar, entry, operation, {:conflict, _ref}) do
    Outbox.fail(entry, :conflict, {:remote_moved, operation.uid})
    mark_row(operation, %{sync_state: :conflicted})
    :conflict
  end

  defp acknowledge(calendar, entry, operation, {:error, reason}) do
    case Backoff.classify(reason, operation.op) do
      verdict when verdict in [:already_landed, :already_gone] ->
        land(calendar, entry, operation, %{})

      :reauth ->
        Outbox.fail(entry, :reauth, reason)
        mark_account(calendar, :error)
        :reauth

      :quarantine ->
        Outbox.fail(entry, :quarantine, reason)
        mark_row(operation, %{sync_state: :push_failed})
        :quarantined

      verdict ->
        Outbox.fail(entry, verdict, reason)

        if Backoff.exhausted?(entry.attempt_count) do
          mark_row(operation, %{sync_state: :push_failed})
          :quarantined
        else
          :retrying
        end
    end
  end

  defp land(_calendar, entry, %Operation{op: :delete} = operation, _ref) do
    Outbox.succeed(entry)
    mark_row(operation, %{sync_state: :clean})
    :pushed
  end

  defp land(_calendar, entry, operation, ref) do
    Outbox.succeed(entry)

    body =
      case Operation.render(operation) do
        {:ok, rendered} -> rendered
        _ -> nil
      end

    case row_for(operation) do
      nil ->
        :pushed

      row ->
        attrs =
          row
          |> Revision.mark_pushed(operation.pushed_rev || row.local_rev, normalise_ref(ref))
          |> put_body(body)

        row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
        :pushed
    end
  end

  # The bytes just accepted are now what the server holds, so they become the
  # base for the next edit. Storing anything else would make the next patch a
  # patch against a document that no longer exists.
  defp put_body(attrs, nil), do: attrs
  defp put_body(attrs, body), do: Map.put(attrs, :raw_icalendar, body)

  defp mark_row(operation, attrs) do
    case row_for(operation) do
      nil -> :ok
      row -> row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
    end
  end

  defp row_for(%Operation{uid: uid, calendar_id: calendar_id}) do
    Event
    |> Ash.Query.filter(uid == ^uid and calendar_id == ^calendar_id)
    |> Ash.read_one()
    |> case do
      {:ok, row} -> row
      _ -> nil
    end
  end

  defp normalise_ref(ref) when is_map(ref) do
    %{id: Map.get(ref, :id), etag: Map.get(ref, :etag), href: Map.get(ref, :href)}
  end

  # ── Cursor recovery ────────────────────────────────────────────────────────

  @doc """
  Handle `410 Gone`: forget the cursor and the mirror, keep everything else.

  Clears **only** this calendar's `origin: :mirror` rows and its
  `sync_cursor`. Kati-owned events stay, tombstones stay, and the outbox is
  untouched — a queued mutation is a promise to the user, and a server telling
  us our cursor expired says nothing about whether that promise should be kept.
  """
  @spec recover_cursor(Calendar.t()) :: %{cleared: non_neg_integer()}
  def recover_cursor(%Calendar{} = calendar) do
    cleared =
      Event
      |> Ash.Query.filter(calendar_id == ^calendar.id and origin == :mirror)
      |> Ash.read!()
      |> Enum.map(&Ash.destroy!/1)
      |> length()

    calendar
    |> Ash.Changeset.for_update(:update, %{sync_cursor: nil})
    |> Ash.update!()

    %{cleared: cleared}
  end

  # ── Small helpers ──────────────────────────────────────────────────────────

  defp find_row(calendar, change) do
    Event
    |> Ash.Query.filter(calendar_id == ^calendar.id and uid == ^change.uid)
    |> Ash.read_one()
    |> case do
      {:ok, row} -> row
      _ -> nil
    end
  end

  defp remote_ref(change) do
    %{id: change.remote_id, etag: change.etag, href: change.remote_href}
  end

  # Only the columns the projection owns. `raw_icalendar` is included because
  # it is the server's exact bytes and the base for every later patch.
  defp projection(change) do
    change.fields
    |> Map.take([
      :summary,
      :location,
      :description,
      :dtstart_utc,
      :dtstart_wall,
      :dtstart_date,
      :tzid,
      :is_all_day,
      :duration_iso,
      :rrule,
      :status,
      :transp,
      :sequence,
      :organizer,
      :kind
    ])
    |> maybe_put(:raw_icalendar, change.raw_icalendar)
  end

  defp maybe_put(attrs, _key, nil), do: attrs
  defp maybe_put(attrs, key, value), do: Map.put(attrs, key, value)

  defp commit_cursor(calendar, cursor) do
    calendar
    |> Ash.Changeset.for_update(:update, %{
      sync_cursor: cursor,
      last_sync_at: DateTime.utc_now()
    })
    |> Ash.update!()
  end

  defp mark_account(%Calendar{account_id: nil}, _state), do: :ok

  defp mark_account(%Calendar{account_id: account_id}, state) do
    case Ash.get(Account, account_id) do
      {:ok, account} ->
        account
        |> Ash.Changeset.for_update(:update, %{
          state: state,
          last_sync_at: if(state == :live, do: DateTime.utc_now(), else: account.last_sync_at)
        })
        |> Ash.update!()

      _ ->
        :ok
    end
  end
end
