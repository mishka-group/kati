defmodule Kati.Sync.Adapter.CalDAV do
  @moduledoc """
  The first adapter that can write.

  Everything before this could only read: `Kati.Sync.Adapter.Inert` refuses by
  design and `Kati.Sync.Adapter.DeviceProvider` reports `writable: false`
  because writing to Android's provider needs `WRITE_CALENDAR`, which Kati does
  not request. So the outbox, the merge, the rejected-change ledger and the
  ownership rules were all built and tested against transports that could never
  exercise them. This is the one that does.

  CalDAV rather than Google or Graph first, because the engine was already
  shaped for it: `Kati.Sync.Operation` carries `if_match` and `if_none_match`
  explicitly, `Kati.Sync.Adapter`'s `remote_ref` has an `href` field described
  as CalDAV-only and opaque, and `{:error, :cursor_invalid}` exists because
  RFC 6578 says a server may refuse a sync token. None of that was speculative;
  it was written for this.

  ## The conditional headers are the concurrency control

  `If-None-Match: *` on create means *only if it does not exist*, so a retry of
  a create that already landed answers `412` instead of making a duplicate.
  `If-Match: <etag>` on update and delete means *only if it has not moved*, so
  a remote edit under a local one answers `412` instead of overwriting someone.
  Both are decided in `Kati.Sync.Operation` above this file, which is why this
  adapter never invents one.

  A `412` on **create** is therefore success — the idempotency key did its job
  — and a `412` on **update** is a genuine conflict. Reading them the same way
  would either duplicate every retried event or discard every real conflict.

  ## The body is patched, never regenerated

  `push/2` applies `changed_properties` to `base_icalendar` with
  `Kati.Sync.ICalendar.patch/2`. It does not build a VEVENT from Kati's
  columns. Regenerating would silently drop every property Kati has no column
  for — `X-APPLE-STRUCTURED-LOCATION`, another client's `CATEGORIES`, an
  organiser's `ATTENDEE` list — and the user would discover it only when
  something else broke.

  ## An etag is not guaranteed

  sabre's own documentation warns that a `PUT` response often carries an `ETag`
  and sometimes does not. When it does not, this returns bare `:ok` rather than
  inventing one: `Kati.Sync.Conflict` reads a `nil` etag as *unknown* and the
  next pull fills it in, whereas a fabricated etag would read as *unchanged*
  and suppress a real conflict.
  """

  @behaviour Kati.Sync.Adapter

  alias Kati.Sync.Capabilities
  alias Kati.Sync.Adapter.CalDAV.Credentials
  alias Kati.Sync.Adapter.CalDAV.Transport
  alias Kati.Sync.Adapter.CalDAV.XML
  alias Kati.Sync.Change
  alias Kati.Sync.ICalendar

  @impl true
  def list_calendars(account) do
    with {:ok, conn} <- connect(account),
         {:ok, %{status: status, body: body}} when status in [207, 200] <-
           request(conn, :propfind, conn.home, propfind_home(), depth: "1"),
         {:ok, calendars} <- XML.calendars(body) do
      {:ok,
       for calendar <- calendars do
         %{
           remote_id: calendar.href,
           display_name: calendar.display_name || "Calendar",
           colour: calendar.colour,
           # `nil` means the server did not say. Treated as read-only, because
           # the failure modes are not symmetric: a calendar wrongly marked
           # read-only is a greyed-out editor the user can ask about, and one
           # wrongly marked writable is a queue of pushes that 403 forever.
           read_only: XML.writable?(calendar) != true
         }
       end}
    else
      {:ok, %{status: status}} -> {:error, {:http, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def pull(calendar, cursor) do
    with {:ok, conn} <- connect_for(calendar) do
      case request(conn, :report, calendar.remote_id, sync_collection(cursor), depth: "1") do
        {:ok, %{status: 207, body: body}} ->
          decode_sync(body)

        # RFC 6578 §3.2: a server that cannot honour a token answers 403 with
        # `valid-sync-token`. Google answers 410. Both mean the same thing and
        # both must reach the engine as `:cursor_invalid`, which clears the
        # mirror for this calendar and KEEPS the outbox.
        {:ok, %{status: status, body: body}} when status in [403, 410] ->
          if status == 410 or body =~ "valid-sync-token",
            do: {:error, :cursor_invalid},
            else: {:error, {:http, status}}

        {:ok, %{status: status}} ->
          {:error, {:http, status}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @impl true
  def push(calendar, operations) do
    case connect_for(calendar) do
      {:ok, conn} ->
        Enum.map(operations, &{&1, apply_one(conn, calendar, &1)})

      {:error, reason} ->
        # One failure per operation rather than one for the batch: the engine
        # counts attempts per entry, and collapsing them would retry a hundred
        # entries on one entry's schedule.
        Enum.map(operations, &{&1, {:error, reason}})
    end
  end

  @impl true
  def capabilities(_account) do
    Capabilities.new(%{
      writable: true,
      # RFC 5545 recurrence in full, because the server stores the VEVENT
      # verbatim and Kati patches it in place.
      recurrence: :full,
      # Not refused — unimplemented. `Kati.Sync.Capabilities` is what the
      # editor greys out from, and claiming attachments would offer a control
      # that drops the file.
      attachments: false,
      attendees: :ro,
      this_and_future: :supported
    })
  end

  # ── One operation ──────────────────────────────────────────────────────────

  defp apply_one(conn, calendar, %{op: :delete} = operation) do
    case request(conn, :delete, href_for(calendar, operation), nil, if_match: operation.if_match) do
      # 404 on a delete is the desired state reached by another route — someone
      # else removed it. Reporting an error would retry forever against a
      # resource that is already gone.
      {:ok, %{status: status}} when status in [200, 204, 404] -> :ok
      {:ok, %{status: 412}} -> {:conflict, %{id: operation.remote_id}}
      {:ok, %{status: status}} -> {:error, {:http, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp apply_one(conn, calendar, operation) do
    case icalendar_for(operation) do
      {:ok, body} -> put_one(conn, calendar, operation, body)
      # A base that holds no VEVENT is a corrupt row, not a flaky network.
      # Returned as an error so `Kati.Sync.Backoff` quarantines the entry
      # rather than replaying it every foreground forever.
      {:error, reason} -> {:error, reason}
    end
  end

  defp put_one(conn, calendar, operation, body) do
    href = href_for(calendar, operation)

    conditional =
      if operation.if_none_match, do: [if_none_match: "*"], else: [if_match: operation.if_match]

    case request(
           conn,
           :put,
           href,
           body,
           [content_type: "text/calendar; charset=utf-8"] ++ conditional
         ) do
      {:ok, %{status: status} = response} when status in [200, 201, 204] ->
        landed(response, href)

      # See the moduledoc: the same code means opposite things by operation.
      {:ok, %{status: status}} when status in [409, 412] ->
        if operation.op == :create,
          do: landed(%{headers: []}, href),
          else: {:conflict, %{id: operation.remote_id, href: href}}

      {:ok, %{status: status}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp landed(response, href) do
    case etag_header(response) do
      nil -> :ok
      etag -> {:ok, %{id: href, etag: etag, href: href}}
    end
  end

  # The href a create writes to. Derived from the UID exactly once, here, and
  # never again: `Kati.Sync.Adapter` calls href opaque and says to store the one
  # the server gave you, so an update or delete uses `remote_href` and this
  # clause is unreachable for them.
  defp href_for(_calendar, %{remote_href: href}) when is_binary(href), do: href

  defp href_for(calendar, %{uid: uid}) do
    String.trim_trailing(calendar.remote_id, "/") <> "/" <> encode_segment(uid) <> ".ics"
  end

  # A UID is user-visible text on some servers and may hold anything. Percent
  # encoding it keeps a slash in a UID from writing to another collection.
  defp encode_segment(uid), do: URI.encode(uid, &URI.char_unreserved?/1)

  # SEQUENCE is bumped on every push because attendees' clients use it to decide
  # whether an update supersedes what they already hold — see
  # `Kati.Sync.ICalendar.bump_sequence/1`.
  defp icalendar_for(%{base_icalendar: base, changed_properties: changes, uid: uid}) do
    with {:ok, patched} <- ICalendar.patch(base || ICalendar.skeleton(uid), changes),
         {:ok, bumped} <- ICalendar.bump_sequence(patched) do
      {:ok, bumped}
    end
  end

  # ── Sync report ────────────────────────────────────────────────────────────

  defp decode_sync(body) do
    with {:ok, %{responses: responses, sync_token: token}} <- XML.multistatus(body) do
      changes =
        for response <- responses, change = change_for(response), change != nil, do: change

      {:ok, changes, token}
    end
  end

  # A resource-level 404 is RFC 6578's deletion. Anything else with calendar
  # data is an upsert. A response with neither — a 403 on one property — is
  # skipped rather than guessed at.
  defp change_for(%{status: 404, href: href}) when is_binary(href) do
    Change.delete(href_uid(href), remote_id: href, remote_href: href)
  end

  defp change_for(%{calendar_data: data, href: href, etag: etag}) when is_binary(data) do
    case uid_from_data(data) || href_uid(href) do
      nil ->
        nil

      uid ->
        Change.upsert(uid,
          remote_id: href,
          remote_href: href,
          etag: etag,
          # The exact bytes, unparsed. `Kati.Sync.Change` calls this "what makes
          # lossless write-back possible at all" and `fields` "a convenience,
          # never the source of truth for a push" — so the bytes are what this
          # adapter carries, and the projection is somebody else's job.
          raw_icalendar: data
        )
    end
  end

  defp change_for(_response), do: nil

  # The UID inside the VEVENT. That is the identity every other client agrees
  # on, and it is preferred over the path because two servers can host the same
  # event at different hrefs.
  defp uid_from_data(data) do
    with {:ok, props} <- ICalendar.properties(data),
         line when is_binary(line) <- ICalendar.property(props, "UID") do
      case String.trim(ICalendar.line_value(line)) do
        "" -> nil
        uid -> uid
      end
    else
      _ -> nil
    end
  end

  # The fallback, and only ever a fallback. Most servers name the file after
  # the UID; the ones that do not are why `uid_from_data/1` is tried first.
  defp href_uid(nil), do: nil

  defp href_uid(href) do
    case href |> String.split("/") |> List.last() do
      nil -> nil
      "" -> nil
      last -> last |> String.replace_suffix(".ics", "") |> URI.decode()
    end
  end

  # ── Connection ─────────────────────────────────────────────────────────────

  # `Ash.NotLoaded` is a struct, so a bare `%{account: %{}}` pattern matches an
  # UNLOADED relationship and hands its placeholder on as if it were an
  # account. The credentials lookup would then miss, the calendar would look
  # unconfigured, and the cause would be a forgotten `load: :account` three
  # call frames away. Named as its own error so it reads as a bug rather than
  # as a user who has not signed in.
  defp connect_for(%{account: %Ash.NotLoaded{}}), do: {:error, :account_not_loaded}
  defp connect_for(%{account: %{} = account}), do: connect(account)
  defp connect_for(_calendar), do: {:error, :no_account}

  defp connect(account) do
    case Credentials.impl().fetch(account) do
      {:ok, %{"url" => url} = creds} when is_binary(url) ->
        {:ok,
         %{
           home: url,
           auth:
             "Basic " <> Base.encode64("#{creds["username"] || ""}:#{creds["password"] || ""}")
         }}

      {:ok, _incomplete} ->
        {:error, :bad_credentials}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ── Requests ───────────────────────────────────────────────────────────────

  defp request(conn, method, url, body, opts) do
    headers =
      [{"authorization", conn.auth}] ++
        header("depth", opts[:depth]) ++
        header("content-type", opts[:content_type]) ++
        header("if-match", quoted(opts[:if_match])) ++
        header("if-none-match", opts[:if_none_match])

    Transport.impl().call(%{method: method, url: url, headers: headers, body: body})
  end

  defp header(_name, nil), do: []
  defp header(name, value), do: [{name, value}]

  # Stored bare by the XML parser, so exactly one set of quotes goes back on.
  defp quoted(nil), do: nil
  defp quoted(etag), do: ~s("#{etag}")

  defp etag_header(%{headers: headers}) do
    Enum.find_value(headers, fn {name, value} ->
      if String.downcase(name) == "etag", do: String.trim(value, "\"")
    end)
  end

  defp etag_header(_response), do: nil

  # ── Bodies ─────────────────────────────────────────────────────────────────

  defp propfind_home do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <d:propfind xmlns:d="DAV:" xmlns:cs="http://calendarserver.org/ns/">
      <d:prop>
        <d:resourcetype/>
        <d:displayname/>
        <d:current-user-privilege-set/>
        <cs:calendar-color/>
        <cs:getctag/>
      </d:prop>
    </d:propfind>
    """
  end

  # `sync-level 1` is the whole collection. A `nil` token asks for everything,
  # which is what an initial sync is; the server answers with a token to use
  # next time.
  defp sync_collection(cursor) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <d:sync-collection xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
      <d:sync-token>#{cursor || ""}</d:sync-token>
      <d:sync-level>1</d:sync-level>
      <d:prop>
        <d:getetag/>
        <c:calendar-data/>
      </d:prop>
    </d:sync-collection>
    """
  end
end
