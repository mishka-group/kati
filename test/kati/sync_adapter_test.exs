defmodule Kati.SyncAdapterTest do
  @moduledoc """
  The two transports that ship, checked against the behaviour they claim.
  """
  use ExUnit.Case, async: false

  alias Kati.Calendars.Calendar
  alias Kati.Sync.Adapter.DeviceProvider
  alias Kati.Sync.Adapter.Inert
  alias Kati.Sync.Capabilities

  defp write!(name, rows) do
    path = Path.join(Mob.data_dir(), name)
    File.write!(path, Jason.encode!(rows))
    on_exit(fn -> File.rm(path) end)
  end

  test "the inert adapter reports nothing and moves no cursor" do
    assert Inert.list_calendars(nil) == {:ok, []}
    assert Inert.pull(nil, "cursor-7") == {:ok, [], "cursor-7"}
    assert Inert.capabilities(nil) == Capabilities.read_only()

    operation = %Kati.Sync.Operation{
      id: "1",
      op: :create,
      uid: "x@kati",
      calendar_id: "c",
      idempotency_key: "k"
    }

    assert [{^operation, {:error, :no_transport}}] = Inert.push(nil, [operation])
  end

  test "a read-only capability map refuses every operation" do
    caps = Capabilities.read_only()

    refute Capabilities.permits?(caps, :create)
    refute Capabilities.permits?(caps, :update)
    refute Capabilities.permits?(caps, :delete)
    assert Capabilities.this_and_future_strategy(caps) == :unsupported
  end

  test "new/1 fills anything unstated from the conservative default" do
    caps = Capabilities.new(%{writable: true, this_and_future: :split})

    assert caps.writable
    assert caps.this_and_future == :split
    assert caps.recurrence == :none, "an unstated capability must not become a generous one"
    assert caps.attendees == :none
  end

  test "the provider adapter lists the calendars the reader published" do
    write!("device_calendars.json", [
      %{"id" => "1", "display_name" => "Work", "color" => "-1", "read_only" => false}
    ])

    assert {:ok, [calendar]} = DeviceProvider.list_calendars(nil)
    assert calendar.remote_id == "1"
    assert calendar.display_name == "Work"
    assert calendar.read_only == false
  end

  test "the provider adapter reports upserts for its own calendar only" do
    write!("device_instances.json", [
      %{
        "calendar_id" => "1",
        "event_id" => 44,
        "sync_id" => "sync-44",
        "title" => "Standup",
        "location" => "Room 4",
        "timezone" => "Europe/London",
        "rrule" => "FREQ=WEEKLY"
      },
      %{"calendar_id" => "2", "event_id" => 45, "sync_id" => "sync-45", "title" => "Other"}
    ])

    assert {:ok, changes, cursor} = DeviceProvider.pull(%Calendar{remote_id: "1"}, "state-1")

    assert cursor == "state-1", "an opaque cursor was rewritten"
    assert length(changes) == 1

    [change] = changes
    assert change.kind == :upsert
    assert change.uid == "sync-44@android"
    assert change.remote_id == "44"
    assert change.fields.summary == "Standup"
    assert change.fields.rrule == "FREQ=WEEKLY"
  end

  test "a row merely absent from this run is not reported as deleted" do
    write!("device_instances.json", [])
    write!("device_deleted.json", [])

    assert {:ok, [], _cursor} = DeviceProvider.pull(%Calendar{remote_id: "1"}, nil)

    write!("device_deleted.json", [%{"calendar_id" => "1", "event_id" => 44, "sync_id" => "sync-44"}])

    assert {:ok, [change], _cursor} = DeviceProvider.pull(%Calendar{remote_id: "1"}, nil)
    assert change.kind == :delete
    assert change.uid == "sync-44@android"
  end

  test "the provider adapter is read-only, and says so once instead of failing forever" do
    caps = DeviceProvider.capabilities(nil)

    refute caps.writable
    assert caps.recurrence == :rrule_only
    assert caps.attendees == :ro
    assert caps.this_and_future == :unsupported

    operation = %Kati.Sync.Operation{
      id: "1",
      op: :update,
      uid: "x@android",
      calendar_id: "c",
      idempotency_key: "k"
    }

    assert [{_operation, {:error, :read_only}}] = DeviceProvider.push(nil, [operation])

    # And the refusal quarantines rather than retrying: looping on a permission
    # Kati never requested would run until the phone dies.
    assert Kati.Sync.Backoff.classify(:read_only, :update) == :quarantine
    assert Kati.Sync.Backoff.classify(:no_transport, :create) == :quarantine
  end

  test "no published file at all is an empty pull, not an error" do
    for name <- ["device_calendars.json", "device_instances.json", "device_deleted.json"] do
      File.rm(Path.join(Mob.data_dir(), name))
    end

    assert {:ok, []} = DeviceProvider.list_calendars(nil)
    assert {:ok, [], nil} = DeviceProvider.pull(%Calendar{remote_id: "1"}, nil)
  end
end
