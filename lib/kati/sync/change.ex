defmodule Kati.Sync.Change do
  @moduledoc """
  One thing a transport says happened upstream.

  Two kinds, and the distinction is load-bearing: `:upsert` carries bytes,
  `:delete` carries only identity. There is deliberately no third kind meaning
  "absent from the response", because absence is not a signal on any transport
  Kati speaks — Google sends `status: "cancelled"`, CalDAV a `404` inside
  `sync-collection`, Graph `@removed`, and the Android provider a row that is
  no longer there for a query that asked for deletions. An adapter that cannot
  distinguish these must not emit `:delete` at all; the cost of a missed
  deletion is a stale row, and the cost of an invented one is the user's data.

  `raw_icalendar` is the exact bytes the server sent and is what makes
  lossless write-back possible at all (`Kati.Sync.ICalendar`). `fields` is the
  parsed projection for the queryable columns — a convenience, never the
  source of truth for a push.
  """

  @enforce_keys [:kind, :uid]
  defstruct [
    :kind,
    :uid,
    :remote_id,
    :remote_href,
    :etag,
    :raw_icalendar,
    fields: %{}
  ]

  @type t :: %__MODULE__{
          kind: :upsert | :delete,
          uid: String.t(),
          remote_id: String.t() | nil,
          remote_href: String.t() | nil,
          etag: String.t() | nil,
          raw_icalendar: String.t() | nil,
          fields: map()
        }

  @doc "An upstream create or update."
  @spec upsert(String.t(), keyword()) :: t()
  def upsert(uid, attrs \\ []) when is_binary(uid) do
    struct!(%__MODULE__{kind: :upsert, uid: uid}, attrs)
  end

  @doc """
  An upstream deletion the transport **stated**.

  Never construct this from "the row was not in the response".
  """
  @spec delete(String.t(), keyword()) :: t()
  def delete(uid, attrs \\ []) when is_binary(uid) do
    struct!(%__MODULE__{kind: :delete, uid: uid}, attrs)
  end
end
