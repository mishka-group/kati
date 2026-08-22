Code.require_file("../support/sync_schema.exs", __DIR__)
Code.require_file("../support/sync_fixtures.exs", __DIR__)

defmodule Kati.SyncOutboxTest do
  @moduledoc """
  Durability, idempotency, ordering, backoff and poison entries.
  """
  use ExUnit.Case, async: false

  import Kati.SyncFixtures

  alias Kati.Sync
  alias Kati.Sync.Backoff
  alias Kati.Sync.Operation
  alias Kati.Sync.Outbox
  alias Kati.Sync.OutboxEntry
  alias Kati.Sync.RejectedChange
  alias Kati.SyncSchema

  # `Kati.Screens.Calendars` reads `calendars` now — its "which calendars show"
  # group is `stored_calendars/0` — so the calendars this module creates are rows
  # on somebody else's screen once it has finished with them.
  # `Kati.ScreenDesignLiteralTest` renders screen 32 at an arbitrary point in the
  # run and compares its copy with `.scratch/design/screens/32.html`; with these
  # rows standing it drew them instead of the drawing's four, and whether it
  # passed depended on `--seed`. Same wipe, and the same reasoning, as
  # `Kati.SeedsTest`'s own teardown.
  setup_all do
    SyncSchema.ensure!()
    on_exit(&empty_the_calendar_tables!/0)
    :ok
  end

  # Child tables first: overrides and events carry the foreign keys.
  defp empty_the_calendar_tables! do
    for table <- ~w(event_occurrence_overrides events calendars calendar_accounts),
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  # ── The bridge, checked from the other side ────────────────────────────────

  test "the live sync tables carry exactly the columns the resources declare" do
    for resource <- [OutboxEntry, RejectedChange] do
      assert SyncSchema.live_columns(resource) == SyncSchema.declared_columns(resource),
             "#{inspect(resource)}: the table and the resource disagree about their columns"
    end
  end

  # ── Durability and idempotency ─────────────────────────────────────────────

  test "an edit writes a queue row carrying the pre-edit document as the merge base" do
    calendar = remote_calendar!(%{writeback_policy: :full})
    original = vevent("outbox-1@example.com")
    event = mirror!(calendar, original)

    {:ok, _updated} = Sync.edit(event, calendar, %{summary: "Standup (async)"})

    assert [entry] = Outbox.open_entries(calendar.id, event.uid)
    assert entry.op == :update
    assert entry.state == :pending
    assert entry.attempt_count == 0

    {:ok, operation} = Operation.from_entry(entry)

    # `Ash.Type.String` trims by default, so the stored document loses its
    # trailing CRLF and nothing else. Asserted rather than worked around, so
    # that if the trim ever reaches further than trailing whitespace this test
    # says so.
    assert operation.base_icalendar == String.trim(original),
           "the base is not the document as it stood before the edit"

    assert String.trim(original) <> "\r\n" == original

    assert String.contains?(operation.base_icalendar, "X-MOZ-LASTACK:20260101T093000Z"),
           "a vendor property did not survive storage"

    assert operation.changed_properties == %{"SUMMARY" => "SUMMARY:Standup (async)"}
    assert operation.if_match == "etag-1"
    assert operation.pushed_rev == 2
  end

  test "a create carries If-None-Match: *, an update carries If-Match" do
    calendar = remote_calendar!()
    fresh = event!(calendar, %{origin: :kati})
    {:ok, create} = Sync.publish(fresh, calendar)
    {:ok, create_op} = Operation.from_entry(create)

    assert create_op.if_none_match, "a create without If-None-Match: * cannot be replayed safely"
    assert create_op.if_match == nil

    synced =
      event!(calendar, %{origin: :kati, remote_id: "r-1", remote_etag: "etag-7", synced_rev: 1})

    {:ok, _} = Sync.edit(synced, calendar, %{summary: "Moved"})
    {:ok, update_op} = Operation.from_entry(hd(Outbox.open_entries(calendar.id, synced.uid)))

    assert update_op.op == :update
    refute update_op.if_none_match

    assert update_op.if_match == "etag-7",
           "without If-Match the server cannot detect the conflict"
  end

  test "the create key is the UID and is stable across every retry" do
    assert Outbox.idempotency_key(:create, "abc@kati", 1) ==
             Outbox.idempotency_key(:create, "abc@kati", 9)

    assert Outbox.idempotency_key(:create, "abc@kati", 1) == "create:abc@kati"
  end

  test "an update key changes with the revision, so two edits are two requests" do
    refute Outbox.idempotency_key(:update, "abc@kati", 4) ==
             Outbox.idempotency_key(:update, "abc@kati", 5)
  end

  test "claiming records the attempt before anything is sent" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati})
    {:ok, _} = Sync.publish(event, calendar)

    [entry] = Outbox.due(calendar.id)
    assert entry.state == :pending

    [claimed] = Outbox.claim([entry])
    assert claimed.state == :in_flight
    assert claimed.attempt_count == 1

    # Re-read from the database: it is the durable row that matters, not the
    # struct the caller happens to be holding.
    assert Ash.get!(OutboxEntry, entry.id).state == :in_flight
  end

  test "recovery puts an orphaned in-flight entry back, key unchanged" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati})
    {:ok, entry} = Sync.publish(event, calendar)
    Outbox.claim(Outbox.due(calendar.id))

    assert Outbox.recover(calendar.id) == 1

    recovered = Ash.get!(OutboxEntry, entry.id)
    assert recovered.state == :pending
    assert recovered.attempt_count == 1

    assert recovered.idempotency_key == entry.idempotency_key,
           "a regenerated key on retry destroys the only defence against a duplicate"
  end

  # ── Ordering ───────────────────────────────────────────────────────────────

  test "a this-and-following split is two chained entries and the second waits" do
    calendar = remote_calendar!()
    master = event!(calendar, %{origin: :kati, rrule: "FREQ=WEEKLY;BYDAY=WE"})

    {:ok, %{trim: trim, successor: successor}} =
      Sync.split_series(
        master,
        calendar,
        %{rrule: "FREQ=WEEKLY;BYDAY=WE;UNTIL=20260901T090000Z"},
        %{
          uid: unique("uid") <> "@kati",
          summary: "Standup (new time)",
          rrule: "FREQ=WEEKLY;BYDAY=WE"
        }
      )

    assert successor.depends_on == trim.id

    due = Outbox.due(calendar.id)
    assert Enum.map(due, & &1.id) == [trim.id]

    refute successor.id in Enum.map(due, & &1.id),
           "the successor became due before the trim landed"

    Outbox.succeed(Ash.get!(OutboxEntry, trim.id))
    assert successor.id in Enum.map(Outbox.due(calendar.id), & &1.id)
  end

  test "a half-landed chain is reported as partially synced rather than as success" do
    calendar = remote_calendar!()
    master = event!(calendar, %{origin: :kati, rrule: "FREQ=WEEKLY"})

    {:ok, %{trim: trim, successor: successor}} =
      Sync.split_series(master, calendar, %{rrule: "FREQ=WEEKLY;UNTIL=20260901T090000Z"}, %{
        uid: master.uid,
        summary: "Standup (new time)"
      })

    Outbox.succeed(Ash.get!(OutboxEntry, trim.id))
    Outbox.fail(Ash.get!(OutboxEntry, successor.id), :quarantine, {:http, 400})

    assert Outbox.partially_synced(calendar.id) == [master.uid]

    status = Sync.status(calendar.id)
    assert status.failed == 1
    assert status.partially_synced == [master.uid]
  end

  test "a dependency that cannot be found blocks its successor rather than freeing it" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati})
    {:ok, entry} = Sync.publish(event, calendar)

    orphan =
      entry
      |> Ash.Changeset.for_update(:update, %{depends_on: Ash.UUID.generate()})
      |> Ash.update!()

    refute orphan.id in Enum.map(Outbox.due(calendar.id), & &1.id)
  end

  test "collect removes finished entries but never one another still depends on" do
    calendar = remote_calendar!()
    master = event!(calendar, %{origin: :kati, rrule: "FREQ=WEEKLY"})

    {:ok, %{trim: trim, successor: successor}} =
      Sync.split_series(master, calendar, %{rrule: "FREQ=WEEKLY;UNTIL=20260901T090000Z"}, %{
        uid: master.uid,
        summary: "Successor"
      })

    Outbox.succeed(Ash.get!(OutboxEntry, trim.id))

    assert Outbox.collect(calendar.id) == 0
    assert Ash.get!(OutboxEntry, trim.id).state == :done

    Outbox.succeed(Ash.get!(OutboxEntry, successor.id))
    assert Outbox.collect(calendar.id) == 1
    assert {:error, _} = Ash.get(OutboxEntry, successor.id)
    assert Ash.get!(OutboxEntry, trim.id).state == :done
  end

  # ── Backoff ────────────────────────────────────────────────────────────────

  test "the delay is 2^n seconds plus up to a second of jitter, capped" do
    assert Backoff.delay_ms(0, jitter: 0) == 1_000
    assert Backoff.delay_ms(1, jitter: 0) == 2_000
    assert Backoff.delay_ms(2, jitter: 0) == 4_000
    assert Backoff.delay_ms(4, jitter: 0) == 16_000

    assert Backoff.delay_ms(3, jitter: 750) == 8_750

    # The cap is 32 s by default and 64 s where a caller asks for it.
    assert Backoff.delay_ms(10, jitter: 999) == 32_000
    assert Backoff.delay_ms(10, jitter: 999, cap_ms: 64_000) == 64_000
    assert Backoff.delay_ms(40, jitter: 0) == 32_000
  end

  test "real jitter stays inside the published bound" do
    delays = for _ <- 1..200, do: Backoff.delay_ms(2)

    assert Enum.all?(delays, &(&1 >= 4_000 and &1 <= 5_000))
    assert length(Enum.uniq(delays)) > 1, "the jitter is not actually random"
  end

  test "a quota backs off far longer than the exponential curve" do
    assert Backoff.delay_for(:hard_backoff, 1, []) > Backoff.delay_ms(8, jitter: 1_000)
  end

  test "failures are classified by status and by operation, not by status alone" do
    assert Backoff.classify({:http, 401}, :update) == :reauth
    assert Backoff.classify({:http, 403, "Rate Limit Exceeded"}, :update) == :hard_backoff
    assert Backoff.classify({:http, 403, :quota}, :create) == :hard_backoff
    assert Backoff.classify({:http, 403, "forbidden"}, :update) == :quarantine
    assert Backoff.classify({:http, 400}, :create) == :quarantine

    assert Backoff.classify({:http, 409}, :create) == :already_landed
    assert Backoff.classify({:http, 412}, :create) == :already_landed
    assert Backoff.classify({:http, 412}, :update) == :conflict

    assert Backoff.classify({:http, 404}, :delete) == :already_gone
    assert Backoff.classify({:http, 404}, :update) == :conflict

    assert Backoff.classify({:http, 503}, :update) == :retry
    assert Backoff.classify(:timeout, :create) == :retry
    assert Backoff.classify(:offline, :create) == :retry
  end

  test "a retryable failure comes back; a poison one does not" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati})
    {:ok, entry} = Sync.publish(event, calendar)

    retried = Outbox.fail(Ash.get!(OutboxEntry, entry.id), :retry, :timeout)
    assert retried.state == :pending
    assert DateTime.compare(retried.next_attempt_at, DateTime.utc_now()) == :gt

    poisoned = Outbox.fail(retried, :quarantine, {:http, 400})
    assert poisoned.state == :push_failed
    assert poisoned.last_error =~ "400"
    assert Outbox.due(calendar.id) == []
  end

  test "nothing retries forever: the attempt cap quarantines a retryable failure too" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati})
    {:ok, entry} = Sync.publish(event, calendar)

    exhausted =
      entry
      |> Ash.Changeset.for_update(:update, %{attempt_count: Backoff.max_attempts()})
      |> Ash.update!()

    assert Outbox.fail(exhausted, :retry, :timeout).state == :push_failed
  end

  test "a re-auth or conflict is blocked, not retried" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati})
    {:ok, entry} = Sync.publish(event, calendar)

    assert Outbox.fail(Ash.get!(OutboxEntry, entry.id), :reauth, {:http, 401}).state == :blocked
    assert Outbox.due(calendar.id) == []
  end

  test "screen 27's Retry clears the attempt count so one hiccup does not requarantine it" do
    calendar = remote_calendar!()
    event = event!(calendar, %{origin: :kati})
    {:ok, entry} = Sync.publish(event, calendar)

    failed =
      entry
      |> Ash.Changeset.for_update(:update, %{attempt_count: 8, state: :push_failed})
      |> Ash.update!()

    retried = Outbox.retry(failed)
    assert retried.state == :pending
    assert retried.attempt_count == 0
    assert retried.last_error == nil
    assert Enum.map(Outbox.due(calendar.id), & &1.id) == [entry.id]
  end
end
