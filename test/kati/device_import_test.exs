defmodule Kati.DeviceImportTest do
  @moduledoc """
  `Kati.Calendars.DeviceImport` is keyed on the provider's calendar id.

  N18: the Sync page listed twenty-four calendars, all named `kati-e2e`. Either
  the import made a new row for the same provider calendar on every boot, or
  the provider really held twenty-four. These tests settle which: the same
  provider calendar imported twice is one row, and two provider calendars that
  happen to share a name are two — so a count on the Sync page is the
  provider's count, and the twenty-four were `CalendarTest.ensureCalendar`
  inserting a fresh calendar on every e2e run and never deleting it.
  """
  use ExUnit.Case, async: false

  require Ash.Query

  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.DeviceImport
  alias Kati.Calendars.Event

  setup do
    prefix = "device-import-test-#{System.unique_integer([:positive])}-"
    on_exit(fn -> remove!(prefix) end)
    {:ok, prefix: prefix}
  end

  defp publish!(calendars, instances) do
    for {name, rows} <- [
          {"device_calendars.json", calendars},
          {"device_instances.json", instances}
        ] do
      path = Path.join(Mob.data_dir(), name)
      File.write!(path, Jason.encode!(rows))
      on_exit(fn -> File.rm(path) end)
    end
  end

  defp calendar(id, name) do
    %{
      "id" => id,
      "display_name" => name,
      "account_name" => name,
      "account_type" => "LOCAL",
      "color" => "5151859",
      "read_only" => false,
      "visible" => true
    }
  end

  defp instance(calendar_id, event_id) do
    begin_ms = DateTime.to_unix(~U[2026-09-25 09:00:00Z], :millisecond)

    %{
      "calendar_id" => calendar_id,
      "event_id" => event_id,
      "title" => "kati-e2e-planted",
      "begin_ms" => begin_ms,
      "end_ms" => begin_ms + 1_800_000,
      "all_day" => false,
      "timezone" => "Etc/UTC"
    }
  end

  defp calendars_with_prefix(prefix) do
    CalendarRow
    |> Ash.Query.filter(contains(remote_id, ^prefix))
    |> Ash.read!()
  end

  defp remove!(prefix) do
    for calendar <- calendars_with_prefix(prefix) do
      Event
      |> Ash.Query.filter(calendar_id == ^calendar.id)
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      Ash.destroy!(calendar)
    end
  end

  test "importing the same provider calendar twice leaves one row", %{prefix: prefix} do
    id = prefix <> "7"
    publish!([calendar(id, "kati-e2e")], [instance(id, prefix <> "event-1")])

    assert {:ok, %{calendars: 1, events: 1}} = DeviceImport.run()
    assert {:ok, %{calendars: 1, events: 1}} = DeviceImport.run()

    assert [%CalendarRow{remote_id: ^id, display_name: "kati-e2e"} = row] =
             calendars_with_prefix(prefix)

    assert [_one] = Event |> Ash.Query.filter(calendar_id == ^row.id) |> Ash.read!()
  end

  test "a renamed provider calendar is updated in place, not added again", %{prefix: prefix} do
    id = prefix <> "7"
    publish!([calendar(id, "kati-e2e")], [])
    assert {:ok, _} = DeviceImport.run()

    publish!([calendar(id, "Renamed")], [])
    assert {:ok, _} = DeviceImport.run()

    assert [%CalendarRow{display_name: "Renamed"}] = calendars_with_prefix(prefix)
  end

  test "two provider calendars that share a name are two rows", %{prefix: prefix} do
    publish!([calendar(prefix <> "7", "kati-e2e"), calendar(prefix <> "8", "kati-e2e")], [])

    assert {:ok, %{calendars: 2}} = DeviceImport.run()
    assert {:ok, %{calendars: 2}} = DeviceImport.run()

    assert prefix |> calendars_with_prefix() |> Enum.map(& &1.display_name) ==
             ["kati-e2e", "kati-e2e"]
  end
end
