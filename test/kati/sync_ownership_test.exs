Code.require_file("../support/sync_schema.exs", __DIR__)
Code.require_file("../support/sync_fixtures.exs", __DIR__)

defmodule Kati.SyncOwnershipTest do
  @moduledoc """
  The ownership column, the predicate, and the two gates that enforce it.
  """
  use ExUnit.Case, async: false

  import Kati.SyncFixtures

  alias Kati.Calendars.Event
  alias Kati.Sync
  alias Kati.Sync.Outbox
  alias Kati.Sync.Ownership

  setup_all do
    Kati.SyncSchema.ensure!()
    :ok
  end

  test "origin is an atom constrained to :kati or :mirror" do
    attribute = Ash.Resource.Info.attribute(Event, :origin)

    assert attribute.type == Ash.Type.Atom
    assert attribute.allow_nil? == false
    assert Enum.sort(attribute.constraints[:one_of]) == [:kati, :mirror]
  end

  test "origin is immutable after creation" do
    calendar = calendar!()
    event = event!(calendar, %{origin: :mirror})

    assert {:error, error} =
             event |> Ash.Changeset.for_update(:update, %{origin: :kati}) |> Ash.update()

    assert Exception.message(error) =~ "origin is immutable"
    assert Ash.get!(Event, event.id).origin == :mirror
  end

  test "the predicate is exactly origin == :kati or writeback_policy == :full" do
    kati_only = remote_calendar!(%{writeback_policy: :kati_only})
    full = remote_calendar!(%{writeback_policy: :full})

    assert Ownership.permitted?(%{origin: :kati}, kati_only)
    refute Ownership.permitted?(%{origin: :mirror}, kati_only)
    assert Ownership.permitted?(%{origin: :mirror}, full)
    assert Ownership.permitted?(%{origin: :kati}, full)
  end

  test "a :none feed refuses everything, including Kati's own events" do
    none = remote_calendar!(%{writeback_policy: :none})

    assert Ownership.permitted?(%{origin: :kati}, none),
           "the design predicate itself does not consider :none"

    refute Ownership.writable?(%{origin: :kati}, none)
    refute Ownership.writable?(%{origin: :mirror}, none)
  end

  test "classify separates the never-synced case from the hybrid one" do
    local = calendar!(%{kind: :local})
    remote = remote_calendar!()

    assert Ownership.classify(%{origin: :kati}, local) == :kati_local
    assert Ownership.classify(%{origin: :kati}, remote) == :kati_remote
    assert Ownership.classify(%{origin: :mirror}, remote) == :mirror

    refute Ownership.syncable?(%{origin: :kati}, local)
    assert Ownership.syncable?(%{origin: :kati}, remote)
  end

  test "the hybrid case: a Kati event with a remote_id stays Kati-owned and wins" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati, remote_id: "google-123", remote_etag: "e1"})

    assert event.origin == :kati
    assert event.remote_id == "google-123"
    assert Ownership.classify(event, calendar) == :kati_remote
    assert Ownership.winner(event) == :local
    assert Ownership.winner(%{origin: :mirror}) == :remote
  end

  test "gate one: the editor's path refuses a mirrored event on a default-policy feed" do
    calendar = remote_calendar!(%{writeback_policy: :kati_only})
    event = mirror!(calendar, vevent("mirror-1@example.com"))

    assert {:error, {:not_writable, detail}} = Sync.edit(event, calendar, %{summary: "Mine now"})
    assert detail.origin == :mirror
    assert detail.writeback_policy == :kati_only
    assert detail.reason =~ "only events Kati created"

    # And nothing was written locally either.
    assert Ash.get!(Event, event.id).summary == "Standup"
    assert Outbox.open_entries(calendar.id, event.uid) == []
  end

  test "gate two: the engine refuses the same write even when the editor is bypassed" do
    calendar = remote_calendar!(%{writeback_policy: :kati_only})
    event = mirror!(calendar, vevent("mirror-2@example.com"))

    # Straight to the queue, exactly as a code path the editor does not own would.
    assert {:error, {:not_writable, detail}} =
             Outbox.enqueue(%{
               calendar: calendar,
               row: event,
               op: :update,
               base_icalendar: event.raw_icalendar,
               changed_properties: %{"SUMMARY" => "SUMMARY:Mine now"}
             })

    assert detail.writeback_policy == :kati_only
    assert Outbox.open_entries(calendar.id, event.uid) == []
  end

  test "a :full feed lets a mirrored event through both gates" do
    calendar = remote_calendar!(%{writeback_policy: :full})
    event = mirror!(calendar, vevent("mirror-3@example.com"))

    assert {:ok, updated} = Sync.edit(event, calendar, %{summary: "Edited upstream copy"})
    assert updated.summary == "Edited upstream copy"
    assert [entry] = Outbox.open_entries(calendar.id, event.uid)
    assert entry.op == :update
  end

  test "a read-only transport refuses the enqueue even where ownership permits" do
    calendar = remote_calendar!(%{writeback_policy: :full})
    event = event!(calendar, %{origin: :kati})

    assert {:error, {:read_only_transport, detail}} =
             Outbox.enqueue(%{
               calendar: calendar,
               row: event,
               op: :create,
               capabilities: Kati.Sync.Adapter.DeviceProvider.capabilities(nil)
             })

    assert detail.op == :create
    assert Outbox.open_entries(calendar.id, event.uid) == []
  end
end
