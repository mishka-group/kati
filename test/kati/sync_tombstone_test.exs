Code.require_file("../support/sync_schema.exs", __DIR__)
Code.require_file("../support/sync_fixtures.exs", __DIR__)
Code.require_file("../support/fake_transport.exs", __DIR__)

defmodule Kati.SyncTombstoneTest do
  @moduledoc """
  Deletions, and the three different things they mean.

  The load-bearing assertion in this file is negative: after a delete and a
  sync, the row is **not** back. A test that only checked `deleted_at` was set
  would pass against an engine that resurrects the row on the next pull, which
  is precisely the bug tombstones exist to prevent.
  """
  use ExUnit.Case, async: false

  import Kati.SyncFixtures

  alias Kati.Calendars.Calendar
  alias Kati.Calendars.Event
  alias Kati.Sync
  alias Kati.Sync.Change
  alias Kati.Sync.Engine
  alias Kati.Sync.Outbox
  alias Kati.Sync.OutboxEntry
  alias Kati.Sync.Tombstone

  require Ash.Query

  # `Kati.Screens.Calendars` reads `calendars` now — its "which calendars show"
  # group is `stored_calendars/0` — so the calendars this module creates are rows
  # on somebody else's screen once it has finished with them.
  # `Kati.ScreenDesignLiteralTest` renders screen 32 at an arbitrary point in the
  # run and compares its copy with `.scratch/design/screens/32.html`; with these
  # rows standing it drew them instead of the drawing's four, and whether it
  # passed depended on `--seed`. Same wipe, and the same reasoning, as
  # `Kati.SeedsTest`'s own teardown.
  setup_all do
    Kati.SyncSchema.ensure!()
    on_exit(&empty_the_calendar_tables!/0)
    :ok
  end

  # Child tables first: overrides and events carry the foreign keys.
  defp empty_the_calendar_tables! do
    for table <- ~w(event_occurrence_overrides events calendars calendar_accounts),
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  defp reload(event), do: Ash.get!(Event, event.id)

  defp live_rows(calendar, uid) do
    Event
    |> Ash.Query.filter(calendar_id == ^calendar.id and uid == ^uid and is_nil(deleted_at))
    |> Ash.read!()
  end

  # ── 1. Local delete ────────────────────────────────────────────────────────

  test "deleting a synced Kati event writes a tombstone and queues the DELETE" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati, remote_id: "remote-9", remote_etag: "etag-1"})

    assert {:ok, tombstoned} = Sync.delete(event, calendar)
    assert tombstoned.deleted_at != nil
    assert tombstoned.local_rev > event.local_rev

    assert [entry] = Outbox.open_entries(calendar.id, event.uid)
    assert entry.op == :delete

    # The row is still there — as a tombstone, not as an event.
    assert reload(event).deleted_at != nil
    assert live_rows(calendar, event.uid) == []
  end

  test "the tombstone is retained until the push is acknowledged" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati, remote_id: "remote-10", remote_etag: "etag-1"})
    {:ok, _} = Sync.delete(event, calendar)

    # 200 days later, with the DELETE still queued.
    later = DateTime.add(DateTime.utc_now(), 200 * 86_400, :second)
    assert Tombstone.collect(now: later, calendar_id: calendar.id) == 0
    assert reload(event).deleted_at != nil

    Outbox.succeed(hd(Outbox.open_entries(calendar.id, event.uid)))
    assert Tombstone.collect(now: later, calendar_id: calendar.id) == 1
    assert {:error, _} = Ash.get(Event, event.id)
  end

  test "a delete then a pull that still carries the event does not resurrect it" do
    calendar = remote_calendar!()
    raw = vevent("resurrect-1@example.com")

    event =
      event!(calendar, %{
        origin: :kati,
        uid: "resurrect-1@example.com",
        raw_icalendar: raw,
        remote_id: "remote-11",
        remote_etag: "etag-1"
      })

    {:ok, _} = Sync.delete(event, calendar)

    # The server has not processed the delete yet and sends the event back.
    change =
      Change.upsert("resurrect-1@example.com",
        remote_id: "remote-11",
        etag: "etag-2",
        raw_icalendar: raw,
        fields: %{summary: "Standup"}
      )

    assert %{suppressed: 1} = Engine.apply_pull(calendar, [change])

    assert live_rows(calendar, "resurrect-1@example.com") == [],
           "a deleted event came back on the next sync"

    assert reload(event).deleted_at != nil
  end

  test "a 60-day offline window is still inside retention, so nothing resurrects" do
    calendar = remote_calendar!()
    raw = vevent("resurrect-2@example.com")

    event =
      event!(calendar, %{
        origin: :kati,
        uid: "resurrect-2@example.com",
        raw_icalendar: raw,
        remote_id: "remote-12"
      })

    {:ok, tombstoned} = Sync.delete(event, calendar)

    sixty_days_on = DateTime.add(tombstoned.deleted_at, 60 * 86_400, :second)

    assert Tombstone.suppressed?(reload(event), now: sixty_days_on)
    assert Tombstone.collect(now: sixty_days_on, calendar_id: calendar.id) == 0

    change = Change.upsert("resurrect-2@example.com", etag: "etag-2", raw_icalendar: raw)
    assert %{suppressed: 1} = Engine.apply_pull(calendar, [change], now: sixty_days_on)
    assert live_rows(calendar, "resurrect-2@example.com") == []
  end

  test "retention is 90 days and a tombstone past it with no queue entry is collected" do
    assert Tombstone.retention_days() == 90

    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati, remote_id: "remote-13"})
    {:ok, tombstoned} = Sync.delete(event, calendar)
    Outbox.succeed(hd(Outbox.open_entries(calendar.id, event.uid)))

    eighty_nine = DateTime.add(tombstoned.deleted_at, 89 * 86_400, :second)
    ninety_one = DateTime.add(tombstoned.deleted_at, 91 * 86_400, :second)

    assert Tombstone.collect(now: eighty_nine, calendar_id: calendar.id) == 0
    assert reload(event).deleted_at != nil

    assert Tombstone.collect(now: ninety_one, calendar_id: calendar.id) == 1
    assert {:error, _} = Ash.get(Event, event.id)
  end

  test "a never-pushed local event's tombstone does not wait 90 days" do
    calendar = calendar!(%{kind: :local})
    event = event!(calendar, %{origin: :kati})

    {:ok, _} = Sync.delete(event, calendar)
    assert Outbox.open_entries(calendar.id, event.uid) == []
    assert Tombstone.collect(calendar_id: calendar.id) == 1
    assert {:error, _} = Ash.get(Event, event.id)
  end

  # ── 2. Remote delete ───────────────────────────────────────────────────────

  test "a stated remote deletion removes a clean mirror row" do
    calendar = remote_calendar!()

    event =
      mirror!(calendar, vevent("remote-delete-1@example.com"), %{
        uid: "remote-delete-1@example.com"
      })

    assert %{deleted: 1} =
             Engine.apply_pull(calendar, [Change.delete("remote-delete-1@example.com")])

    assert reload(event).deleted_at != nil
    assert live_rows(calendar, "remote-delete-1@example.com") == []
  end

  test "a remote deletion over a locally dirty row is a conflict, not a deletion" do
    calendar = remote_calendar!(%{writeback_policy: :full})
    raw = vevent("remote-delete-2@example.com")
    event = mirror!(calendar, raw, %{uid: "remote-delete-2@example.com"})

    {:ok, edited} = Sync.edit(event, calendar, %{summary: "Still going ahead"})
    assert edited.local_rev > edited.synced_rev

    assert %{conflict: 1} =
             Engine.apply_pull(calendar, [Change.delete("remote-delete-2@example.com")])

    survivor = reload(event)
    assert survivor.deleted_at == nil, "an unsent local edit was deleted rather than raised"
    assert survivor.sync_state == :conflicted
    assert survivor.summary == "Still going ahead"
  end

  # ── 3. Account disconnect ──────────────────────────────────────────────────

  test "disconnecting an account deletes its mirror rows and keeps every Kati event" do
    account = account!()

    calendar =
      calendar!(%{
        account_id: account.id,
        kind: :provider,
        remote_id: unique("cal"),
        writeback_policy: :full
      })

    mirrored =
      mirror!(calendar, vevent("disc-mirror@example.com"), %{uid: "disc-mirror@example.com"})

    mine =
      event!(calendar, %{
        origin: :kati,
        uid: "disc-mine@kati",
        summary: "My own thing",
        remote_id: "remote-42",
        remote_etag: "etag-1",
        synced_rev: 1,
        sync_state: :clean
      })

    {:ok, _} = Sync.publish(mine, calendar)
    assert length(Outbox.open_entries(calendar.id, mine.uid)) == 1

    result = Tombstone.disconnect_account(account.id)

    assert result.mirror_deleted == 1
    assert result.kati_kept == 1
    assert result.calendars_kept == 1
    assert result.entries_purged == 1

    assert {:error, _} = Ash.get(Event, mirrored.id)

    survivor = reload(mine)
    assert survivor.summary == "My own thing"
    assert survivor.origin == :kati
    assert survivor.remote_id == nil
    assert survivor.remote_etag == nil
    assert survivor.sync_state == :local_only

    detached = Ash.get!(Calendar, calendar.id)
    assert detached.account_id == nil
    assert detached.kind == :local
    assert detached.writeback_policy == :none

    assert {:error, _} = Ash.get(Kati.Calendars.Account, account.id)
    assert OutboxEntry |> Ash.Query.filter(calendar_id == ^calendar.id) |> Ash.read!() == []
  end

  test "a calendar left with nothing of Kati's own is removed with the account" do
    account = account!()
    calendar = calendar!(%{account_id: account.id, kind: :provider, remote_id: unique("cal")})

    mirror!(calendar, vevent("disc-only-mirror@example.com"), %{
      uid: "disc-only-mirror@example.com"
    })

    result = Tombstone.disconnect_account(account.id)

    assert result.mirror_deleted == 1
    assert result.kati_kept == 0
    assert result.calendars_kept == 0
    assert {:error, _} = Ash.get(Calendar, calendar.id)
  end

  test "deleting a mirrored event Kati may not write is refused, not faked" do
    calendar = remote_calendar!(%{writeback_policy: :kati_only})
    event = mirror!(calendar, vevent("no-delete@example.com"), %{uid: "no-delete@example.com"})

    assert {:error, {:not_writable, _}} = Sync.delete(event, calendar)
    assert reload(event).deleted_at == nil
  end
end
