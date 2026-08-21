defmodule Kati.Sync.Adapter.Inert do
  @moduledoc """
  An adapter that reports nothing, writes nothing, and succeeds. The default,
  and not a stub.

  Two real situations want exactly this, and the second is the common one:

    * **the host.** `mix test` and `iex -S mix` have no calendar server. The
      engine's decisions — ownership, merge, tombstones, backoff — are the
      product here and they are all testable without one.
    * **no account connected.** Most of Kati works with no remote calendar at
      all: habits, meals and media air-dates are `origin: :kati` events on a
      local calendar and are never synced by design. Installing this adapter
      makes that state explicit rather than leaving a `nil` to be checked at
      every call site.

  It reports `Kati.Sync.Capabilities.read_only/0`, which is what stops
  `Kati.Sync.Outbox.enqueue/1` accumulating a queue nothing will ever drain.
  """

  @behaviour Kati.Sync.Adapter

  alias Kati.Sync.Capabilities

  @impl true
  def list_calendars(_account), do: {:ok, []}

  # The cursor is echoed back unchanged: a sync that found nothing must not
  # move a position it never read from.
  @impl true
  def pull(_calendar, cursor), do: {:ok, [], cursor}

  @impl true
  def push(_calendar, operations) do
    Enum.map(operations, &{&1, {:error, :no_transport}})
  end

  @impl true
  def capabilities(_account), do: Capabilities.read_only()
end
