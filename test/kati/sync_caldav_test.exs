defmodule Kati.SyncCalDAVTest do
  alias Kati.SyncCalDAVTest.Store

  @moduledoc """
  The first adapter that can write, tested without a CalDAV server.

  ## Why this is possible at all

  The transport is one behaviour with one function, so everything above it —
  request building, conditional headers, the multistatus parse, the
  status-to-result mapping — is pure and gets exercised here against canned
  replies. What is NOT covered is whether a real server agrees, and no host
  test can cover that; `Kati.Sync.Backoff` is what survives the difference.

  ## The three that would be silent

  A create that retries into a duplicate, a deletion read as an ordinary
  response, and a push that regenerates the VEVENT instead of patching it.
  None of the three raises, all three corrupt a user's calendar, and each has
  its own describe block below.
  """
  use ExUnit.Case, async: false

  alias Kati.Sync.Adapter.CalDAV
  alias Kati.Sync.Operation

  @account %{credentials_ref: "caldav_test"}
  @calendar %{
    remote_id: "https://dav.test/cal/home/personal/",
    account: @account
  }

  setup do
    Application.put_env(:kati, :caldav_transport, __MODULE__.FakeTransport)
    Application.put_env(:kati, :caldav_credentials, __MODULE__.FakeCredentials)

    start_supervised!(%{
      id: Store,
      start: {Agent, :start_link, [fn -> %{replies: [], seen: []} end, [name: Store]]}
    })

    on_exit(fn ->
      Application.delete_env(:kati, :caldav_transport)
      Application.delete_env(:kati, :caldav_credentials)
    end)

    :ok
  end

  # `Kati.SecureStore` is the Android Keystore behind a NIF; on a host there is
  # nothing to read. The adapter reads credentials through a behaviour for that
  # reason, and this is the host half of it.
  defmodule FakeCredentials do
    @behaviour Kati.Sync.Adapter.CalDAV.Credentials

    @impl true
    def fetch(_account) do
      {:ok, %{"url" => "https://dav.test/cal/home/", "username" => "u", "password" => "p"}}
    end
  end

  # ── A transport that answers from a script and records what it was asked ───
  defmodule FakeTransport do
    @behaviour Kati.Sync.Adapter.CalDAV.Transport

    @impl true
    def call(request) do
      Agent.get_and_update(Store, fn state ->
        {reply, rest} =
          case state.replies do
            [head | tail] -> {head, tail}
            [] -> {{:ok, %{status: 500, headers: [], body: ""}}, []}
          end

        {reply, %{state | replies: rest, seen: state.seen ++ [request]}}
      end)
    end
  end

  defp script(replies), do: Agent.update(Store, &%{&1 | replies: replies})
  defp requests, do: Agent.get(Store, & &1.seen)
  defp ok(status, body, headers \\ []), do: {:ok, %{status: status, headers: headers, body: body}}

  defp header(request, name) do
    Enum.find_value(request.headers, fn {k, v} -> if String.downcase(k) == name, do: v end)
  end

  describe "a deletion is read as a deletion" do
    test "a resource-level 404 inside a sync report becomes a :delete change" do
      script([
        ok(207, """
        <D:multistatus xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
          <D:response>
            <D:href>/cal/home/personal/gone.ics</D:href>
            <D:status>HTTP/1.1 404 Not Found</D:status>
          </D:response>
          <D:sync-token>tok-2</D:sync-token>
        </D:multistatus>
        """)
      ])

      assert {:ok, [change], "tok-2"} = CalDAV.pull(@calendar, "tok-1")
      assert change.kind == :delete
      assert change.uid == "gone"
    end

    test "an ordinary hit carries the server's exact bytes" do
      # `Kati.Sync.Change` calls raw_icalendar "what makes lossless write-back
      # possible at all". An adapter that parses to columns and drops the bytes
      # passes every other test and silently deletes properties Kati has no
      # column for on the next push.
      script([
        ok(207, """
        <D:multistatus xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
          <D:response>
            <D:href>/cal/home/personal/a.ics</D:href>
            <D:propstat>
              <D:prop>
                <D:getetag>"e-1"</D:getetag>
                <C:calendar-data>#{ics()}</C:calendar-data>
              </D:prop>
              <D:status>HTTP/1.1 200 OK</D:status>
            </D:propstat>
          </D:response>
          <D:sync-token>tok-2</D:sync-token>
        </D:multistatus>
        """)
      ])

      assert {:ok, [change], _} = CalDAV.pull(@calendar, nil)
      assert change.kind == :upsert
      assert change.uid == "party@example.test", "the UID must come from the VEVENT, not the path"
      assert change.etag == "e-1", "quotes belong to the wire, not to the column"
      assert change.raw_icalendar =~ "X-APPLE-STRUCTURED-LOCATION"
    end

    test "a refused sync token is :cursor_invalid, not an error" do
      # The engine treats this one specially — it clears the mirror for this
      # calendar and KEEPS the outbox. Classified as an ordinary HTTP error it
      # would back off forever instead.
      script([ok(403, "<D:error xmlns:D=\"DAV:\"><D:valid-sync-token/></D:error>")])
      assert {:error, :cursor_invalid} = CalDAV.pull(@calendar, "stale")

      script([ok(410, "")])
      assert {:error, :cursor_invalid} = CalDAV.pull(@calendar, "stale")
    end

    test "an ordinary 403 is not mistaken for a stale token" do
      script([ok(403, "<D:error xmlns:D=\"DAV:\"><D:need-privileges/></D:error>")])
      assert {:error, {:http, 403}} = CalDAV.pull(@calendar, "tok")
    end
  end

  describe "the conditional headers are the concurrency control" do
    test "a create asks for If-None-Match: *" do
      script([ok(201, "", [{"ETag", "\"new\""}])])
      CalDAV.push(@calendar, [create_op()])

      assert [request] = requests()
      assert request.method == :put
      assert header(request, "if-none-match") == "*"
      assert header(request, "if-match") == nil
    end

    test "an update asks for If-Match with exactly one set of quotes" do
      script([ok(204, "")])
      CalDAV.push(@calendar, [update_op(if_match: "e-1")])

      assert [request] = requests()
      assert header(request, "if-match") == ~s("e-1"), "the etag is stored bare and quoted here"
      assert header(request, "if-none-match") == nil
    end

    test "a delete carries If-Match and goes to the stored href" do
      script([ok(204, "")])
      CalDAV.push(@calendar, [delete_op(if_match: "e-9")])

      assert [request] = requests()
      assert request.method == :delete
      assert request.url == "https://dav.test/cal/home/personal/known.ics"
      assert header(request, "if-match") == ~s("e-9")
    end
  end

  describe "412 means opposite things by operation" do
    test "on a create it is success — the idempotency key did its job" do
      # The retry of a create that already landed. Reported as a conflict, the
      # engine would surface a conflict the user cannot act on; reported as an
      # error it would retry forever and never converge.
      script([ok(412, "")])
      assert [{_op, result}] = CalDAV.push(@calendar, [create_op()])
      assert result == :ok
    end

    test "on an update it is a genuine conflict" do
      script([ok(412, "")])
      assert [{_op, {:conflict, ref}}] = CalDAV.push(@calendar, [update_op(if_match: "e-1")])
      assert ref.href =~ "known.ics"
    end

    test "a 404 on delete is the desired state, reached by another route" do
      script([ok(404, "")])
      assert [{_op, :ok}] = CalDAV.push(@calendar, [delete_op(if_match: "e-1")])
    end
  end

  describe "the body is patched, never regenerated" do
    test "a push keeps properties Kati has no column for" do
      base = """
      BEGIN:VCALENDAR\r
      BEGIN:VEVENT\r
      UID:party@example.test\r
      SUMMARY:Old name\r
      X-APPLE-STRUCTURED-LOCATION:keep me\r
      CATEGORIES:someone else's\r
      END:VEVENT\r
      END:VCALENDAR\r
      """

      script([ok(204, "")])

      CalDAV.push(@calendar, [
        update_op(base_icalendar: base, changed: %{"SUMMARY" => "New name"})
      ])

      assert [request] = requests()
      assert request.body =~ "SUMMARY:New name"
      refute request.body =~ "SUMMARY:Old name"

      assert request.body =~ "X-APPLE-STRUCTURED-LOCATION:keep me",
             "regenerating from columns is how another client's data disappears"

      assert request.body =~ "CATEGORIES:someone else's"
    end
  end

  describe "an etag is not guaranteed" do
    test "a PUT that returns one reports it" do
      script([ok(201, "", [{"ETag", "\"fresh\""}])])
      assert [{_op, {:ok, ref}}] = CalDAV.push(@calendar, [create_op()])
      assert ref.etag == "fresh"
    end

    test "a PUT that returns none reports bare :ok rather than inventing one" do
      # sabre warns an ETag is often returned and sometimes is not. A
      # fabricated one reads as *unchanged* to Kati.Sync.Conflict and would
      # suppress a real conflict; nil reads as *unknown* and the next pull
      # fills it in.
      script([ok(204, "")])
      assert [{_op, :ok}] = CalDAV.push(@calendar, [create_op()])
    end
  end

  describe "calendars the server will not let us write" do
    test "a read-only share is reported read-only" do
      script([
        ok(207, """
        <multistatus xmlns="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
          <response>
            <href>/cal/home/mine/</href>
            <propstat><prop>
              <resourcetype><collection/><cal:calendar/></resourcetype>
              <displayname>Mine</displayname>
              <current-user-privilege-set>
                <privilege><read/></privilege><privilege><write-content/></privilege>
              </current-user-privilege-set>
            </prop><status>HTTP/1.1 200 OK</status></propstat>
          </response>
          <response>
            <href>/cal/home/theirs/</href>
            <propstat><prop>
              <resourcetype><collection/><cal:calendar/></resourcetype>
              <displayname>Theirs</displayname>
              <current-user-privilege-set><privilege><read/></privilege></current-user-privilege-set>
            </prop><status>HTTP/1.1 200 OK</status></propstat>
          </response>
        </multistatus>
        """)
      ])

      assert {:ok, [mine, theirs]} = CalDAV.list_calendars(@account)
      refute mine.read_only
      assert theirs.read_only
    end

    test "a server that reports no privileges is treated as read-only" do
      # Not symmetric: a calendar wrongly greyed out is a question the user can
      # ask, and one wrongly writable is a queue of pushes that 403 forever.
      script([
        ok(207, """
        <multistatus xmlns="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
          <response>
            <href>/cal/home/quiet/</href>
            <propstat><prop>
              <resourcetype><collection/><cal:calendar/></resourcetype>
              <displayname>Quiet</displayname>
            </prop><status>HTTP/1.1 200 OK</status></propstat>
          </response>
        </multistatus>
        """)
      ])

      assert {:ok, [quiet]} = CalDAV.list_calendars(@account)
      assert quiet.read_only
    end
  end

  describe "an unloaded relationship is not an account" do
    test "a calendar whose account was never loaded says so" do
      # `Ash.NotLoaded` is a struct, so a `%{account: %{}}` pattern matches it
      # and passes the placeholder on as if it were an account. The credentials
      # lookup then misses and the calendar reads as unconfigured, three call
      # frames from the forgotten `load: :account` that caused it.
      calendar = %{remote_id: "https://dav.test/c/", account: %Ash.NotLoaded{}}

      assert {:error, :account_not_loaded} = CalDAV.pull(calendar, nil)
      assert [{_op, {:error, :account_not_loaded}}] = CalDAV.push(calendar, [create_op()])
    end

    test "a batch that cannot connect fails per operation, not per batch" do
      # The engine counts attempts per entry. One shared failure would put a
      # hundred entries on one entry's retry schedule.
      calendar = %{remote_id: "https://dav.test/c/", account: %Ash.NotLoaded{}}
      results = CalDAV.push(calendar, [create_op(), delete_op(if_match: "e")])

      assert length(results) == 2
      assert Enum.all?(results, &match?({_op, {:error, :account_not_loaded}}, &1))
    end
  end

  describe "capabilities" do
    test "this adapter can write, which is the point of it" do
      caps = CalDAV.capabilities(@account)
      assert caps.writable
      assert Kati.Sync.Capabilities.permits?(caps, :create)
      assert Kati.Sync.Capabilities.permits?(caps, :update)
      assert Kati.Sync.Capabilities.permits?(caps, :delete)
    end
  end

  # Kept out of the heredoc: a VEVENT's lines start at column 0 and an indented
  # heredoc would either reindent them or warn.
  defp ics do
    Enum.join(
      [
        "BEGIN:VCALENDAR",
        "BEGIN:VEVENT",
        "UID:party@example.test",
        "SUMMARY:Party",
        "X-APPLE-STRUCTURED-LOCATION:keep me",
        "END:VEVENT",
        "END:VCALENDAR"
      ],
      "\r\n"
    )
  end

  # ── Operations ─────────────────────────────────────────────────────────────

  defp create_op(opts \\ []) do
    %Operation{
      id: "op-1",
      op: :create,
      uid: "party@example.test",
      calendar_id: "cal-1",
      idempotency_key: "k-1",
      if_none_match: true,
      changed_properties: Keyword.get(opts, :changed, %{"SUMMARY" => "Party"})
    }
  end

  defp update_op(opts) do
    %Operation{
      id: "op-2",
      op: :update,
      uid: "party@example.test",
      calendar_id: "cal-1",
      idempotency_key: "k-2",
      remote_href: "https://dav.test/cal/home/personal/known.ics",
      if_match: Keyword.get(opts, :if_match),
      base_icalendar: Keyword.get(opts, :base_icalendar),
      changed_properties: Keyword.get(opts, :changed, %{"SUMMARY" => "Party"})
    }
  end

  defp delete_op(opts) do
    %Operation{
      id: "op-3",
      op: :delete,
      uid: "party@example.test",
      calendar_id: "cal-1",
      idempotency_key: "k-3",
      remote_href: "https://dav.test/cal/home/personal/known.ics",
      if_match: Keyword.get(opts, :if_match)
    }
  end
end
