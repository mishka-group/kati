defmodule Kati.FakeTransport do
  @moduledoc """
  A remote calendar that keeps every write as a separate row.

  The row list is the whole point. A store keyed by `UID` could not represent a
  duplicate, so a duplicate-suppression test against one would pass whether or
  not the suppression worked. Here a second create appends a second row unless
  something stops it — and the only thing that stops it is the idempotency key,
  which is exactly what the airplane-mode suite is testing.

  `mode` is where the radio gets toggled:

    * `:normal` — the request lands and the response arrives.
    * `:fail_before_request` — nothing reaches the server.
    * `:fail_after_request` — the write lands and the **response is lost**. This
      is the dangerous one: the client cannot tell it apart from the case above.
  """

  use Agent

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{rows: [], keys: MapSet.new(), mode: :normal, seq: 0} end)
  end

  def set_mode(store, mode), do: Agent.update(store, &%{&1 | mode: mode})
  def mode(store), do: Agent.get(store, & &1.mode)
  def rows(store), do: Agent.get(store, & &1.rows)
  def rows(store, uid), do: Enum.filter(rows(store), &(&1.uid == uid))
  def count(store, uid), do: length(rows(store, uid))

  @doc "Seed a row as if the server already had it — the mirror side of a pull."
  def seed(store, uid, body, etag) do
    Agent.update(store, fn state ->
      %{state | rows: state.rows ++ [%{id: "remote-" <> uid, uid: uid, body: body, etag: etag}]}
    end)
  end

  @doc "Change a row underneath the client, the way another app would."
  def touch(store, uid, body, etag) do
    Agent.update(store, fn state ->
      rows =
        Enum.map(state.rows, fn row ->
          if row.uid == uid, do: %{row | body: body, etag: etag}, else: row
        end)

      %{state | rows: rows}
    end)
  end

  @doc "Apply one operation, honouring the idempotency key and `If-Match`."
  def apply_operation(store, operation) do
    Agent.get_and_update(store, fn state -> do_apply(state, operation) end)
  end

  defp do_apply(%{mode: :fail_before_request} = state, _operation) do
    {{:error, :timeout}, state}
  end

  defp do_apply(state, operation) do
    {result, state} = perform(state, operation)

    case state.mode do
      # The write landed; the response died on the way home.
      :fail_after_request -> {{:error, :timeout}, state}
      _ -> {result, state}
    end
  end

  defp perform(state, %{op: :create} = operation) do
    if MapSet.member?(state.keys, operation.idempotency_key) do
      row = Enum.find(state.rows, &(&1.uid == operation.uid))
      {{:conflict, ref(row)}, state}
    else
      seq = state.seq + 1
      body = render(operation)

      row = %{
        id: "remote-#{seq}",
        uid: operation.uid,
        body: body,
        etag: "etag-#{seq}"
      }

      {{:ok, ref(row)},
       %{
         state
         | rows: state.rows ++ [row],
           keys: MapSet.put(state.keys, operation.idempotency_key),
           seq: seq
       }}
    end
  end

  defp perform(state, %{op: :update} = operation) do
    row = Enum.find(state.rows, &(&1.uid == operation.uid))

    cond do
      is_nil(row) ->
        {{:error, {:http, 404}}, state}

      # `If-Match` is how a CalDAV server enforces conflict detection for free.
      is_binary(operation.if_match) and operation.if_match != row.etag ->
        {{:conflict, ref(row)}, state}

      true ->
        seq = state.seq + 1
        updated = %{row | body: render(operation), etag: "etag-#{seq}"}
        rows = Enum.map(state.rows, &if(&1.uid == row.uid, do: updated, else: &1))
        {{:ok, ref(updated)}, %{state | rows: rows, seq: seq}}
    end
  end

  defp perform(state, %{op: :delete} = operation) do
    case Enum.find(state.rows, &(&1.uid == operation.uid)) do
      nil ->
        {{:error, {:http, 404}}, state}

      row ->
        {:ok, %{state | rows: Enum.reject(state.rows, &(&1.uid == row.uid))}}
        |> then(fn {_ok, state} -> {{:ok, ref(row)}, state} end)
    end
  end

  defp render(operation) do
    case Kati.Sync.Operation.render(operation) do
      {:ok, body} -> body
      _ -> nil
    end
  end

  defp ref(nil), do: %{id: "unknown", etag: nil, href: nil}
  defp ref(row), do: %{id: row.id, etag: row.etag, href: "/cal/" <> row.id <> ".ics"}
end

defmodule Kati.FakeAdapter do
  @moduledoc """
  A `Kati.Sync.Adapter` over `Kati.FakeTransport`.

  The store is passed in the process dictionary rather than as an argument
  because the behaviour's callbacks take a calendar and nothing else — which is
  the right shape for a real transport, and the reason the engine can be handed
  any module at all.
  """

  @behaviour Kati.Sync.Adapter

  alias Kati.FakeTransport
  alias Kati.Sync.Capabilities

  def install(store), do: Process.put(:fake_store, store)
  def store, do: Process.get(:fake_store)

  @impl true
  def list_calendars(_account), do: {:ok, []}

  @impl true
  def pull(_calendar, cursor), do: {:ok, Process.get(:fake_changes, []), cursor || "cursor-1"}

  @impl true
  def push(_calendar, operations) do
    Enum.map(operations, fn operation ->
      {operation, FakeTransport.apply_operation(store(), operation)}
    end)
  end

  @impl true
  def capabilities(_account) do
    Capabilities.new(%{
      writable: true,
      recurrence: :full,
      attachments: false,
      attendees: :rw,
      this_and_future: :split
    })
  end
end
