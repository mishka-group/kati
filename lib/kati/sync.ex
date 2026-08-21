defmodule Kati.Sync do
  @moduledoc """
  The sync domain, and the only door a local edit uses to reach a remote.

  ## The honest case

  Kati's canonical store is the **device**. A remote calendar is an upstream
  Kati does not control and cannot lock. So ownership is not symmetric and
  "conflict" almost always means *the upstream changed under a local edit*, not
  *two peers diverged*. Three rules follow, and every module here is one of
  them made mechanical:

    * **`Kati.Sync.Ownership`** decides who wins, from a column set at creation
      and never changed — `origin: :kati` means Kati is authoritative,
      `origin: :mirror` means the remote is. Not the section colour, not which
      app made the row.
    * **`Kati.Sync.Merge`** tries hard not to need that decision: disjoint
      property sets merge silently, and only genuine overlap falls through to
      ownership.
    * **The loser is preserved, never discarded.** Whichever side loses,
      its values land in `Kati.Sync.RejectedChange` with the base they were a
      change from, so "the remote won" means *here is what you typed, one tap
      away* instead of *your edit is gone*. A merge that silently drops the
      user's edit is the failure this whole design exists to prevent.

  ## The queue is the API

  Nothing calls a transport directly. `edit/3`, `publish/2`, `delete/2` and
  `split_series/4` all write to `Kati.Sync.OutboxEntry`, and only
  `Kati.Sync.Engine.drain/3` ever calls `push/2` on an adapter.
  `Kati.SyncBoundaryTest` reads every source file under `lib/` and fails the
  build if that stops being true, because a mutation held in a process's memory
  is lost the moment the user backgrounds the app in a tunnel — and they have
  no way to know it was lost.

  ## Two ownership gates

  `edit/3` authorises before it writes, so the editor is read-only where policy
  forbids. `Kati.Sync.Outbox.enqueue/1` authorises **again**, so a write that
  reaches the queue by a path the editor does not own is still refused. They do
  not share a call; that is the point of having two.

  ## No clocks decide anything

  Precedence comes from `local_rev`/`synced_rev` and from etags. A device three
  minutes fast, or set to 2019, changes no outcome. Wall-clock time is used for
  exactly two things — *when to retry* and *when a tombstone is old enough to
  collect* — and neither decides whose edit survives.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Sync.OutboxEntry
    resource Kati.Sync.RejectedChange
  end

  require Ash.Query

  alias Kati.Calendars.Calendar
  alias Kati.Calendars.Event
  alias Kati.Sync.Compose
  alias Kati.Sync.ICalendar
  alias Kati.Sync.Operation
  alias Kati.Sync.Outbox
  alias Kati.Sync.OutboxEntry
  alias Kati.Sync.Ownership
  alias Kati.Sync.RejectedChange
  alias Kati.Sync.Tombstone

  @doc """
  Apply a local edit and queue it.

  The base — the `raw_icalendar` as it stood **before** this edit — goes into
  the outbox payload, which is what makes a conflict discovered three days
  later a three-way merge rather than a guess.

  Refuses with `{:error, {:not_writable, detail}}` when ownership forbids the
  write. The editor renders `detail.reason`; nothing is written locally either,
  because a local edit that can never be sent and is never shown as unsent is
  the same lie as dropping it.
  """
  @spec edit(Event.t(), Calendar.t(), map()) :: {:ok, Event.t()} | {:error, term()}
  def edit(%Event{} = event, %Calendar{} = calendar, changes) do
    with :ok <- Ownership.authorise(event, calendar) do
      base = event.raw_icalendar
      syncable? = Ownership.syncable?(event, calendar)
      attrs = Map.drop(changes, [:properties])

      updated =
        event
        |> Ash.Changeset.for_update(
          :update,
          Map.put(attrs, :sync_state, if(syncable?, do: :dirty, else: :local_only))
        )
        |> Ash.update!()

      if syncable? do
        queue(event, calendar, updated, base, Compose.changed(changes))
      else
        {:ok, updated}
      end
    end
  end

  defp queue(event, calendar, updated, base, properties) do
    op = if event.remote_id, do: :update, else: :create

    case Outbox.enqueue(%{
           calendar: calendar,
           row: event,
           op: op,
           base_icalendar: base,
           changed_properties: properties,
           pushed_rev: updated.local_rev
         }) do
      {:ok, _entry} -> {:ok, updated}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Queue an `origin: :kati` event's first push into a remote calendar.

  This is the hybrid case the ownership model exists for: the row stays
  `origin: :kati` and gains a `remote_id`, in the same table, and wins on
  conflict by default. The `UID` was generated on the device, which is what
  makes the create idempotent — a retry after an ambiguous timeout comes back
  `409`/`412` meaning *it already landed*, not *it failed*.
  """
  @spec publish(Event.t(), Calendar.t()) :: {:ok, OutboxEntry.t()} | {:error, term()}
  def publish(%Event{} = event, %Calendar{} = calendar) do
    with :ok <- Ownership.authorise(event, calendar) do
      Outbox.enqueue(%{
        calendar: calendar,
        row: event,
        op: :create,
        base_icalendar: event.raw_icalendar,
        changed_properties: Compose.event(event),
        pushed_rev: event.local_rev
      })
    end
  end

  @doc "Delete an event locally: a tombstone plus a queued DELETE."
  @spec delete(Event.t(), Calendar.t()) :: {:ok, Event.t()} | {:error, term()}
  defdelegate delete(event, calendar), to: Tombstone, as: :delete_local

  @doc """
  "This and following", as the two ordered operations it actually is.

  Trim the master's `UNTIL`, then create its successor. No transport offers a
  transaction across the two, so the second entry carries `depends_on` and
  cannot run until the first is `:done`. If the second fails after the first
  succeeded, `Kati.Sync.Outbox.partially_synced/1` reports the UID and screen 27
  shows an error card with **Retry** — because the alternative, a silent
  success, is the user losing every future occurrence with nothing on screen
  saying so.

  Kati never emits `RANGE=THISANDFUTURE` itself: §3.4's interop technique is the
  split, and a transport that reports `this_and_future: :native` is the
  exception rather than the plan.
  """
  @spec split_series(Event.t(), Calendar.t(), map(), map()) ::
          {:ok, %{trim: OutboxEntry.t(), successor: OutboxEntry.t()}} | {:error, term()}
  def split_series(%Event{} = master, %Calendar{} = calendar, trim_changes, successor) do
    with :ok <- Ownership.authorise(master, calendar),
         {:ok, trim} <-
           Outbox.enqueue(%{
             calendar: calendar,
             row: master,
             op: :update,
             base_icalendar: master.raw_icalendar,
             changed_properties: Compose.changed(trim_changes),
             pushed_rev: master.local_rev
           }),
         {:ok, created} <-
           Outbox.enqueue(%{
             calendar: calendar,
             # The successor of a split inherits the master's ownership: it is
             # the same series, and a successor Kati may not write is one it
             # may not create.
             row: successor |> Map.put(:remote_id, nil) |> Map.put(:origin, master.origin),
             op: :create,
             base_icalendar: nil,
             changed_properties: Compose.changed(successor),
             depends_on: trim.id,
             pushed_rev: 1
           }) do
      {:ok, %{trim: trim, successor: created}}
    end
  end

  @doc "Rows waiting on a human decision — screen 37's queue."
  @spec conflicts(String.t()) :: [Event.t()]
  def conflicts(calendar_id) do
    Event
    |> Ash.Query.filter(calendar_id == ^calendar_id and sync_state == :conflicted)
    |> Ash.Query.sort(dtstart_utc: :asc)
    |> Ash.read!()
  end

  @doc """
  Screen 37's three answers, applied.

    * `:keep_mine` — the local document wins. The remote's contested values are
      kept as a rejected change, and the push is requeued.
    * `:take_file` — the remote wins. The local edit is kept as a rejected
      change and the queued push is dropped, because it no longer describes
      anything the user asked for.
    * `:keep_both` — the remote stays on the calendar and the local version
      becomes a **new** Kati-owned event with a fresh `UID`. That is the only
      answer that is genuinely lossless, and it is why the resolver offers it.
  """
  @spec resolve(Event.t(), Calendar.t(), :keep_mine | :take_file | :keep_both) ::
          {:ok, Event.t()} | {:error, term()}
  def resolve(%Event{} = event, %Calendar{} = calendar, choice) do
    entry = List.first(Outbox.open_entries(calendar.id, event.uid))
    do_resolve(event, calendar, entry, choice)
  end

  defp do_resolve(event, calendar, entry, :take_file) do
    if entry do
      case Operation.from_entry(entry) do
        {:ok, operation} ->
          record_rejected(calendar, event, %{
            side: :local,
            reason: :user_choice,
            properties: operation.changed_properties,
            base_properties: %{}
          })

        _ ->
          :ok
      end

      Ash.destroy!(entry)
    end

    {:ok, mark(event, %{sync_state: :clean, synced_rev: event.local_rev + 1})}
  end

  defp do_resolve(event, calendar, entry, :keep_mine) do
    if entry do
      entry
      |> Ash.Changeset.for_update(:update, %{
        state: :pending,
        attempt_count: 0,
        last_error: nil,
        next_attempt_at: DateTime.utc_now(),
        idempotency_key: Outbox.idempotency_key(entry.op, entry.event_uid, event.local_rev + 1)
      })
      |> Ash.update!()
    end

    record_rejected(calendar, event, %{
      side: :remote,
      reason: :user_choice,
      properties: remote_properties(event),
      base_properties: %{}
    })

    {:ok, mark(event, %{sync_state: :dirty})}
  end

  defp do_resolve(event, calendar, entry, :keep_both) do
    with {:ok, operation} <- from_entry(entry),
         base when is_binary(base) <- operation.base_icalendar || event.raw_icalendar,
         {:ok, local_raw} <- ICalendar.apply_lines(base, operation.changed_properties) do
      uid = "#{System.unique_integer([:positive])}-split@kati"
      {:ok, forked} = ICalendar.apply_lines(local_raw, %{"UID" => "UID:" <> uid})

      copy =
        Event
        |> Ash.Changeset.for_create(:create, %{
          uid: uid,
          calendar_id: calendar.id,
          origin: :kati,
          summary: event.summary,
          dtstart_utc: event.dtstart_utc,
          dtstart_wall: event.dtstart_wall,
          dtstart_date: event.dtstart_date,
          tzid: event.tzid,
          is_all_day: event.is_all_day,
          duration_iso: event.duration_iso,
          raw_icalendar: forked,
          sync_state: :local_only
        })
        |> Ash.create!()

      Ash.destroy!(entry)
      publish(copy, calendar)
      {:ok, mark(event, %{sync_state: :clean, synced_rev: event.local_rev + 1})}
    else
      _ -> do_resolve(event, calendar, entry, :take_file)
    end
  end

  defp from_entry(nil), do: :error
  defp from_entry(entry), do: Operation.from_entry(entry)

  defp remote_properties(%Event{raw_icalendar: nil}), do: %{}

  defp remote_properties(%Event{raw_icalendar: raw}) do
    case ICalendar.properties(raw) do
      {:ok, props} -> Map.new(props, fn {name, lines} -> {name, List.first(lines)} end)
      _ -> %{}
    end
  end

  defp record_rejected(calendar, event, rejected) do
    RejectedChange
    |> Ash.Changeset.for_create(:create, %{
      calendar_id: calendar.id,
      event_uid: event.uid,
      side: rejected.side,
      reason: rejected.reason,
      properties: Jason.encode!(rejected.properties),
      base_properties: Jason.encode!(rejected.base_properties)
    })
    |> Ash.create!()
  end

  defp mark(event, attrs) do
    event |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
  end

  @doc "Edits that lost and have not been re-applied or dismissed."
  @spec rejected(String.t()) :: [RejectedChange.t()]
  def rejected(calendar_id) do
    RejectedChange
    |> Ash.Query.filter(
      calendar_id == ^calendar_id and is_nil(applied_at) and is_nil(dismissed_at)
    )
    |> Ash.read!()
  end

  @doc """
  Re-apply a rejected change: the property lines it holds, ready to be edited
  back in.

  Deliberately returns the values rather than writing them. Re-applying is
  another edit and goes through `edit/3` like any other, so it authorises,
  bumps the revision and gets its own outbox entry — a shortcut here would be a
  second write path, which is the thing this module exists not to have.
  """
  @spec reapply(RejectedChange.t()) :: {:ok, map()} | {:error, term()}
  def reapply(%RejectedChange{} = rejected) do
    with {:ok, properties} <- Jason.decode(rejected.properties) do
      rejected
      |> Ash.Changeset.for_update(:update, %{applied_at: DateTime.utc_now()})
      |> Ash.update!()

      {:ok, properties}
    end
  end

  @doc "Screen 32's badge, screen 27's card: one map per calendar."
  @spec status(String.t()) :: map()
  defdelegate status(calendar_id), to: Outbox
end
