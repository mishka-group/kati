defmodule Kati.Sync.Operation do
  @moduledoc """
  One outbox entry, decoded into everything a transport needs to make the
  request — and nothing it does not.

  The three fields that decide correctness:

    * `base_icalendar` — the bytes as they stood **before** the local edit.
      This is the merge base, and the reason a conflict discovered three days
      later is still resolvable rather than a coin toss.
    * `changed_properties` — only the properties Kati actually changed. The
      push patches `base_icalendar` with these and serialises; it never
      regenerates a document from columns, which is what would silently delete
      the `X-APPLE-STRUCTURED-LOCATION` some other app put there.
    * `idempotency_key` — stable across every retry of this entry.

  `if_match` and `if_none_match` are carried explicitly rather than derived by
  the adapter, so the concurrency rule is decided once, above the transport:
  `If-None-Match: *` on create, `If-Match: <etag>` on update and delete. A
  CalDAV server then enforces conflict detection for free and answers `412`;
  Google and Graph do the same with their own etags.
  """

  alias Kati.Sync.ICalendar
  alias Kati.Sync.OutboxEntry

  @enforce_keys [:id, :op, :uid, :calendar_id, :idempotency_key]
  defstruct [
    :id,
    :op,
    :uid,
    :calendar_id,
    :account_id,
    :idempotency_key,
    :base_icalendar,
    :remote_id,
    :remote_href,
    :if_match,
    :pushed_rev,
    changed_properties: %{},
    if_none_match: false
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          op: :create | :update | :delete,
          uid: String.t(),
          calendar_id: String.t(),
          account_id: String.t() | nil,
          idempotency_key: String.t(),
          base_icalendar: String.t() | nil,
          remote_id: String.t() | nil,
          remote_href: String.t() | nil,
          if_match: String.t() | nil,
          pushed_rev: pos_integer() | nil,
          changed_properties: %{String.t() => String.t() | nil},
          if_none_match: boolean()
        }

  @doc "Decode a stored entry into the operation it describes."
  @spec from_entry(OutboxEntry.t()) :: {:ok, t()} | {:error, :bad_payload}
  def from_entry(%OutboxEntry{} = entry) do
    case Jason.decode(entry.payload) do
      {:ok, payload} when is_map(payload) ->
        {:ok,
         %__MODULE__{
           id: entry.id,
           op: entry.op,
           uid: entry.event_uid,
           calendar_id: entry.calendar_id,
           account_id: entry.account_id,
           idempotency_key: entry.idempotency_key,
           base_icalendar: payload["base_icalendar"],
           changed_properties: payload["changed_properties"] || %{},
           remote_id: payload["remote_id"],
           remote_href: payload["remote_href"],
           if_match: payload["if_match"],
           pushed_rev: payload["pushed_rev"],
           if_none_match: entry.op == :create
         }}

      _ ->
        {:error, :bad_payload}
    end
  end

  @doc """
  The bytes to send: the base, patched with only what Kati changed.

  `SEQUENCE` is incremented on an update because RFC 5545 requires it to move
  on any change to a scheduled event — that is how every attendee's client
  knows this copy supersedes the one it already has.

  A create with no base gets a minimal `VEVENT` skeleton, which is the only
  place in the engine that generates iCalendar rather than patching it. From
  the second push onwards the base is whatever the server sent back.
  """
  @spec render(t()) :: {:ok, String.t()} | {:error, term()}
  def render(%__MODULE__{op: :delete}), do: {:error, :delete_has_no_body}

  def render(%__MODULE__{op: op} = operation) do
    base = operation.base_icalendar || ICalendar.skeleton(operation.uid)

    with {:ok, patched} <- ICalendar.apply_lines(base, operation.changed_properties) do
      if op == :update, do: ICalendar.bump_sequence(patched), else: {:ok, patched}
    end
  end
end
