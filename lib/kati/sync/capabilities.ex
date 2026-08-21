defmodule Kati.Sync.Capabilities do
  @moduledoc """
  What one transport can actually express, stated once instead of discovered
  per-failure.

  The five fields are exactly the ones that decide whether an edit is possible
  before the user makes it. `this_and_future` is the sharpest: CalDAV can be
  told `RANGE=THISANDFUTURE`, Google and the Android provider cannot and need
  the series **split** into two masters (which is why
  `Kati.Sync.Outbox` has `depends_on` at all), and a transport that supports
  neither has to say `:unsupported` so the editor can hide the option rather
  than silently truncating the series.

  A conservative default matters more than a generous one: an adapter that
  forgets to answer is treated as read-only, so the failure mode of a missing
  answer is "Kati does not write", never "Kati writes something the server
  cannot store".
  """

  @enforce_keys [:writable, :recurrence, :attachments, :attendees, :this_and_future]
  defstruct [:writable, :recurrence, :attachments, :attendees, :this_and_future]

  @type t :: %__MODULE__{
          writable: boolean(),
          recurrence: :full | :rrule_only | :none,
          attachments: boolean(),
          attendees: :rw | :ro | :none,
          this_and_future: :native | :split | :unsupported
        }

  @doc """
  The safe answer: read-only, expresses nothing.

  Used by `Kati.Sync.Adapter.Inert` and as the base for `new/1`.
  """
  @spec read_only() :: t()
  def read_only do
    %__MODULE__{
      writable: false,
      recurrence: :none,
      attachments: false,
      attendees: :none,
      this_and_future: :unsupported
    }
  end

  @doc "Build a capability map, filling anything unstated from `read_only/0`."
  @spec new(keyword() | map()) :: t()
  def new(fields) do
    struct(read_only(), Map.new(fields))
  end

  @doc """
  Whether a push of `op` is even worth queueing against this transport.

  Called by `Kati.Sync.Outbox.enqueue/1`, so a read-only feed never accumulates
  a queue of writes it will spend the next month failing to deliver.
  """
  @spec permits?(t(), :create | :update | :delete) :: boolean()
  def permits?(%__MODULE__{writable: writable}, op) when op in [:create, :update, :delete] do
    writable
  end

  @doc """
  How a "this and following" edit has to be modelled against this transport.

  `:split` is the one that costs something: two outbox entries chained with
  `depends_on`, because trimming the master and creating its successor are two
  requests and no transport offers a transaction across them.
  """
  @spec this_and_future_strategy(t()) :: :native | :split | :unsupported
  def this_and_future_strategy(%__MODULE__{this_and_future: strategy}), do: strategy
end
