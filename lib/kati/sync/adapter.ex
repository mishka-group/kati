defmodule Kati.Sync.Adapter do
  @moduledoc """
  The one seam between the sync engine and any transport.

  Google, CalDAV, Graph and `CalendarContract` are four different shapes of the
  same four questions: what calendars are there, what changed, please apply
  this, and what can you actually express. Everything above this behaviour is
  written once; everything below it is per-transport. Nothing in
  `Kati.Sync.Engine`, `Kati.Sync.Outbox` or `Kati.Sync.Merge` may name a
  concrete adapter — `Kati.SyncBoundaryTest` fails the build if one does.

  ## `cursor` is opaque

  RFC 6578 is explicit that a sync token *"MUST be treated as an 'opaque'
  string by the client"*. `Kati.Calendars.Calendar.sync_cursor` stores whatever
  `pull/2` returned last time and nothing anywhere parses, compares or orders
  it beyond equality. Google's `syncToken`, CalDAV's `sync-token`, Graph's
  `deltaLink` and the provider's sync state are all carried through this one
  column unexamined.

  `{:error, :cursor_invalid}` is a distinct return, not an ordinary error: it
  is Google's `410 Gone`, and its handling is deliberately narrow —
  `Kati.Sync.Engine.recover_cursor/1` clears the mirror rows **for that
  calendar only** and **keeps the outbox**. Google's own sample calls
  `eventDataStore.clear()`, which is right for a pure mirror and destroys
  Kati-owned events plus every queued mutation.

  ## Deletion is never an absence

  `pull/2` returns `Kati.Sync.Change` values and a deletion is an explicit
  `:delete` change, because that is what every transport actually sends:
  Google `status: "cancelled"`, CalDAV a `404` inside `sync-collection`, Graph
  `@removed`, the provider a row that is gone from a `DIRTY`-aware query.
  Treating "not in the response" as "deleted" is wrong on all four and is how
  an incremental sync deletes a user's whole calendar.

  ## `capabilities/1` is the part people forget

  Screen 32's per-feed *Write back* rules are a UI over this map, and the
  editor greys out what a backend cannot express instead of accepting an edit
  and dropping it on the floor. A read-only transport says so here once, rather
  than failing every push forever.
  """

  alias Kati.Calendars.Account
  alias Kati.Calendars.Calendar
  alias Kati.Sync.Capabilities
  alias Kati.Sync.Change
  alias Kati.Sync.Operation

  @typedoc "Whatever the transport calls its incremental-sync position. Opaque."
  @type cursor :: term()

  @typedoc """
  A server's identity for one resource.

  `href` is CalDAV-only and **opaque** — store the one the server gave you and
  never derive it from the UID.
  """
  @type remote_ref :: %{
          required(:id) => String.t(),
          optional(:etag) => String.t() | nil,
          optional(:href) => String.t() | nil
        }

  @typedoc "A calendar as the transport describes it, before it becomes a row."
  @type remote_calendar :: %{
          required(:remote_id) => String.t(),
          optional(:display_name) => String.t() | nil,
          optional(:colour) => String.t() | nil,
          optional(:read_only) => boolean()
        }

  @typedoc """
  What one push attempt did.

    * `:ok` — it landed, and the transport gave back no reference. sabre warns
      that *"an ETag is often returned, but there are cases where this is not
      true"*, so this is a real answer and not a lazy one. The row keeps a
      `nil` etag, which `Kati.Sync.Conflict` reads as *unknown*, never as
      *moved*, and the next pull fills it in.
    * `{:ok, ref}` — it landed and here is the new identity and etag.
    * `{:conflict, ref}` — `409`/`412`. On a **create** that means
      *it already landed* (the idempotency key did its job) and is treated as
      success. On an **update** it means the remote moved under us and is a
      genuine conflict.
    * `{:error, reason}` — classified by `Kati.Sync.Backoff.classify/1`.
  """
  @type push_result :: :ok | {:ok, remote_ref()} | {:conflict, remote_ref()} | {:error, term()}

  @callback list_calendars(Account.t()) :: {:ok, [remote_calendar()]} | {:error, term()}

  @callback pull(Calendar.t(), cursor() | nil) ::
              {:ok, [Change.t()], cursor()} | {:error, :cursor_invalid} | {:error, term()}

  @callback push(Calendar.t(), [Operation.t()]) :: [{Operation.t(), push_result()}]

  @callback capabilities(Account.t()) :: Capabilities.t()
end
