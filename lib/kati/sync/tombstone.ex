defmodule Kati.Sync.Tombstone do
  @moduledoc """
  Three deletions that look identical and are not.

  Conflating them is a classic data-loss bug, so they are three functions with
  three different behaviours and no shared "delete" helper underneath:

  1. **`delete_local/2`** — the user deleted a Kati-owned, synced event. Write a
     tombstone, queue the DELETE, and keep the tombstone until the push is
     acknowledged. Hard-deleting the row instead would make it indistinguishable
     from a row that never existed, and the next pull would put it straight
     back.

  2. **`apply_remote_delete/2`** — the upstream said the event is gone. Remove
     the mirror row **unless it is locally dirty**, in which case there is an
     unsent local edit and a delete arriving on top of it is a genuine
     delete/update conflict, not a deletion.

  3. **`disconnect_account/1`** — the user removed the account. Delete that
     account's mirror rows and **keep every Kati-owned event**, including the
     Kati-owned events that lived in that account's calendars. Screen 32's
     promise that Kati never touches an event it did not create has a
     mirror-image obligation: disconnecting must never destroy what Kati *did*
     create.

  ## Retention

  90 days, which must exceed the longest plausible offline period. A tombstone
  collected too early is not tidiness — it is the deleted event coming back on
  the next sync. And a tombstone is **never** collected while an outbox entry
  still references its event, because that entry is the delete that has not
  landed yet; collecting the tombstone would drop the only record that the row
  is supposed to be gone.

  ## Resurrection

  An incoming `:upsert` for a UID whose local row is tombstoned and still
  within retention is **ignored**. That is the whole point of the table: a
  60-day offline window, a full resync, a server that never processed the
  delete — none of them may bring the row back.
  """

  require Ash.Query

  alias Kati.Calendars.Calendar
  alias Kati.Calendars.Event
  alias Kati.Sync.Outbox
  alias Kati.Sync.OutboxEntry
  alias Kati.Sync.Ownership
  alias Kati.Sync.Revision

  @retention_days 90

  @doc "How long a tombstone is kept. Longer than any plausible offline period."
  @spec retention_days() :: pos_integer()
  def retention_days, do: @retention_days

  # ── 1. Local delete ────────────────────────────────────────────────────────

  @doc """
  The user deleted an event Kati owns.

  Refuses a mirrored event on a feed Kati may not write: deleting the local
  copy would only hide it until the next pull, and pretending otherwise is
  worse than saying no.
  """
  @spec delete_local(Event.t(), Calendar.t()) :: {:ok, Event.t()} | {:error, term()}
  def delete_local(%Event{} = event, %Calendar{} = calendar) do
    with :ok <- deletable(event, calendar) do
      tombstoned =
        event
        |> Ash.Changeset.for_update(:soft_delete, %{})
        |> Ash.update!()

      case queue_delete(tombstoned, calendar, event) do
        :ok -> {:ok, tombstoned}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # A row that was never on a server has nothing to tell one. It still gets a
  # tombstone — collectable immediately, since nothing can resurrect it — so
  # that "deleted" has exactly one representation in the database.
  defp queue_delete(%Event{remote_id: nil}, _calendar, _before), do: :ok

  defp queue_delete(tombstoned, calendar, before) do
    if Ownership.syncable?(tombstoned, calendar) do
      case Outbox.enqueue(%{
             calendar: calendar,
             row: before,
             op: :delete,
             base_icalendar: before.raw_icalendar,
             pushed_rev: tombstoned.local_rev
           }) do
        {:ok, _entry} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :ok
    end
  end

  defp deletable(event, calendar) do
    cond do
      event.origin == :kati -> :ok
      Ownership.writable?(event, calendar) -> :ok
      true -> Ownership.authorise(event, calendar)
    end
  end

  # ── 2. Remote delete ───────────────────────────────────────────────────────

  @doc """
  The upstream stated the event is gone.

  Never called from "it was not in the response": Google sends
  `status: "cancelled"`, CalDAV a `404` inside `sync-collection`, Graph
  `@removed`. Absence is not a signal on any of them.

  Returns `{:conflict, event}` when the row is locally dirty — the caller
  raises it as a delete/update conflict rather than resolving it here, because
  the resolution needs the merge base and the user.
  """
  @spec apply_remote_delete(Event.t()) :: {:ok, Event.t()} | {:conflict, Event.t()}
  def apply_remote_delete(%Event{} = event) do
    if Revision.dirty?(event) do
      {:conflict,
       event
       |> Ash.Changeset.for_update(:update, %{sync_state: :conflicted})
       |> Ash.update!()}
    else
      {:ok, event |> Ash.Changeset.for_update(:soft_delete, %{}) |> Ash.update!()}
    end
  end

  # ── 3. Account disconnect ──────────────────────────────────────────────────

  @doc """
  Remove an account, keeping everything Kati created.

  What happens, in order:

    * every `origin: :mirror` event in that account's calendars is **hard
      deleted** — it is someone else's data and the account that authorised
      holding it is gone, so a 90-day tombstone of it would be the wrong thing
      to keep;
    * every `origin: :kati` event survives with its remote link cleared and
      `sync_state: :local_only` — it is the user's own work and it now lives
      only here;
    * calendars that still hold a surviving event are converted to `:local` and
      detached; calendars left empty are removed;
    * the account's outbox entries are purged, because there is nowhere to
      send them.
  """
  @spec disconnect_account(String.t()) :: %{
          mirror_deleted: non_neg_integer(),
          kati_kept: non_neg_integer(),
          calendars_kept: non_neg_integer(),
          entries_purged: non_neg_integer()
        }
  def disconnect_account(account_id) when is_binary(account_id) do
    calendars = Calendar |> Ash.Query.filter(account_id == ^account_id) |> Ash.read!()
    entries_purged = purge_entries(account_id)

    {deleted, kept} =
      Enum.reduce(calendars, {0, 0}, fn calendar, {deleted, kept} ->
        events = Event |> Ash.Query.filter(calendar_id == ^calendar.id) |> Ash.read!()
        {mirror, kati} = Enum.split_with(events, &(&1.origin == :mirror))

        Enum.each(mirror, &Ash.destroy!/1)
        Enum.each(kati, &detach_event/1)

        {deleted + length(mirror), kept + length(kati)}
      end)

    calendars_kept = Enum.count(calendars, &detach_calendar/1)

    case Ash.get(Kati.Calendars.Account, account_id) do
      {:ok, account} -> Ash.destroy!(account)
      _ -> :ok
    end

    %{
      mirror_deleted: deleted,
      kati_kept: kept,
      calendars_kept: calendars_kept,
      entries_purged: entries_purged
    }
  end

  defp detach_event(event) do
    event
    |> Ash.Changeset.for_update(:update, %{
      remote_id: nil,
      remote_href: nil,
      remote_etag: nil,
      synced_rev: 0,
      sync_state: :local_only
    })
    |> Ash.update!()
  end

  # Returns true when the calendar survived, so the caller can count it.
  defp detach_calendar(calendar) do
    remaining = Event |> Ash.Query.filter(calendar_id == ^calendar.id) |> Ash.read!()

    if remaining == [] do
      Ash.destroy!(calendar)
      false
    else
      calendar
      |> Ash.Changeset.for_update(:update, %{
        account_id: nil,
        kind: :local,
        remote_id: nil,
        sync_cursor: nil,
        writeback_policy: :none
      })
      |> Ash.update!()

      true
    end
  end

  defp purge_entries(account_id) do
    OutboxEntry
    |> Ash.Query.filter(account_id == ^account_id)
    |> Ash.read!()
    |> Enum.map(&Ash.destroy!/1)
    |> length()
  end

  # ── Retention ──────────────────────────────────────────────────────────────

  @doc """
  Whether an incoming upsert for this UID must be ignored.

  True while a tombstone for it is within retention. This is what stops a
  60-day offline window, or a server that never processed the delete, from
  resurrecting the row.
  """
  @spec suppressed?(Event.t() | nil, keyword()) :: boolean()
  def suppressed?(nil, _opts), do: false
  def suppressed?(%Event{deleted_at: nil}, _opts), do: false

  def suppressed?(%Event{deleted_at: deleted_at}, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    DateTime.diff(now, deleted_at, :day) < @retention_days
  end

  @doc """
  Collect tombstones that are past retention and that nothing still needs.

  Two independent refusals, and the second is the one worth testing: a
  tombstone whose event still has an open outbox entry is **never** collected,
  whatever its age, because that entry is the delete that has not landed.

  `:calendar_id` scopes the sweep to one feed. Sweeping everything is the right
  default for a housekeeping pass, and the wrong thing when a caller means
  "tidy up after this account" — a global sweep triggered by disconnecting one
  feed would collect another feed's tombstones, and there the retention clock
  is still doing a job.
  """
  @spec collect(keyword()) :: non_neg_integer()
  def collect(opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    cutoff = DateTime.add(now, -@retention_days * 86_400, :second)

    Event
    |> Ash.Query.filter(not is_nil(deleted_at))
    |> scope(Keyword.get(opts, :calendar_id))
    |> Ash.read!()
    |> Enum.filter(fn event ->
      collectable_age?(event, cutoff) and Outbox.open_entries(event.calendar_id, event.uid) == []
    end)
    |> Enum.map(&Ash.destroy!/1)
    |> length()
  end

  defp scope(query, nil), do: query
  defp scope(query, calendar_id), do: Ash.Query.filter(query, calendar_id == ^calendar_id)

  # A row that was never pushed anywhere cannot be resurrected by anything, so
  # its tombstone has no job to do and does not wait 90 days for one.
  defp collectable_age?(%Event{remote_id: nil, sync_state: :local_only}, _cutoff), do: true

  defp collectable_age?(%Event{deleted_at: deleted_at}, cutoff) do
    DateTime.compare(deleted_at, cutoff) == :lt
  end
end
