defmodule Kati.Sync.OutboxEntry do
  @moduledoc """
  One durable intention to change something upstream.

  Everything that leaves the device passes through this table. There is no code
  path from a screen to a transport — `Kati.SyncBoundaryTest` proves it by
  reading every source file under `lib/` — because a mutation that exists only
  in a process's memory is lost the moment the user backgrounds the app in a
  tunnel, and the user has no way to know it was lost.

  ## Why the foreign keys are plain columns

  `account_id` and `calendar_id` are `:uuid` attributes, not `belongs_to`
  relationships. The outbox has to **outlive the rows it refers to** — that is
  what durability means here. Google's `410 Gone` clears a calendar's mirror
  rows and must keep the queue; an account disconnect purges its entries
  deliberately, by policy, in `Kati.Sync.Tombstone.disconnect_account/1`. A
  database-level cascade would make both of those someone else's decision, and
  the wrong one.

  ## `idempotency_key`

  Unique, generated once at enqueue, and **never regenerated on retry**. None
  of Google, CalDAV or Graph offers an idempotency key, so Kati constructs one:
  a client-generated `UID` sent with `If-None-Match: *` (CalDAV) or as a
  client-supplied `id` (Google). Its entire purpose is that after an ambiguous
  timeout the retry gets a definite answer — a `409`/`412` meaning *it already
  landed* rather than an unanswerable "did it?". Change the key on retry and
  the mechanism is gone and the duplicate is back.

  ## `depends_on` and why `:done` rows linger

  "This and following" is two operations that must land in order: trim the
  master's `UNTIL`, then create its successor. If the second fails after the
  first succeeded the user has silently lost every future occurrence, so entry
  2 carries `depends_on` pointing at entry 1 and does not become due until
  entry 1 is `:done`.

  That is also why a finished entry is kept rather than deleted: a `depends_on`
  pointing at nothing cannot distinguish "the predecessor succeeded and was
  tidied away" from "the predecessor never existed", and those must not have
  the same consequence. `Kati.Sync.Outbox.collect/1` removes `:done` entries
  only once nothing depends on them.

  ## States

    * `:pending` — due when `next_attempt_at` has passed and its dependency is done.
    * `:in_flight` — claimed, attempt recorded, request possibly on the wire.
      Written **before** the request, so a crash mid-flight leaves evidence.
    * `:done` — landed.
    * `:blocked` — a conflict or a credential problem the drainer cannot fix
      by trying again. Waits for a merge or a re-auth.
    * `:push_failed` — quarantined. Screen 27's error card with **Retry**.
  """
  use Ash.Resource, domain: Kati.Sync, data_layer: AshSqlite.DataLayer

  sqlite do
    table "sync_outbox"
    repo Kati.Repo

    custom_indexes do
      # The drainer's query: due entries for one calendar, oldest first.
      index [:calendar_id, :state, :next_attempt_at]
      # The tombstone GC's question: does anything still reference this uid?
      index [:calendar_id, :event_uid]
      # The dependency gate.
      index [:depends_on]
      # The whole idempotency mechanism rests on this being unique.
      index [:idempotency_key], unique: true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :account_id, :uuid, public?: true
    attribute :calendar_id, :uuid, allow_nil?: false, public?: true
    attribute :event_uid, :string, allow_nil?: false, public?: true

    attribute :op, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:create, :update, :delete]]

    # JSON text, not a map: SQLite has no JSONB indexes, and this is read whole
    # or not at all. Carries the pre-edit raw_icalendar — the merge base.
    attribute :payload, :string, allow_nil?: false, default: "{}", public?: true

    attribute :attempt_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :next_attempt_at, :utc_datetime_usec, public?: true
    attribute :idempotency_key, :string, allow_nil?: false, public?: true
    attribute :depends_on, :uuid, public?: true

    attribute :state, :atom,
      allow_nil?: false,
      default: :pending,
      public?: true,
      constraints: [one_of: [:pending, :in_flight, :done, :blocked, :push_failed]]

    attribute :last_error, :string, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*
  end
end
