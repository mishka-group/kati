defmodule Kati.Sync.Adapter.CalDAV.XML do
  @moduledoc """
  Reading a WebDAV `multistatus` document, and nothing else.

  Pure. Takes bytes, returns data, performs no IO — which is the only reason
  the CalDAV adapter can be tested without a CalDAV server, and the reason the
  parsing rules below are checkable rather than asserted.

  ## Why namespaces are matched and prefixes are not

  There is no such thing as "the `d:` prefix". `DAV:` is the namespace; the
  prefix is whatever the server felt like. Real servers in the wild use `d:`,
  `D:`, `dav:` and no prefix at all, and a parser keyed on the string before
  the colon works against three servers and mysteriously fails against the
  fourth. So the document is scanned namespace-conformant and every element is
  matched on `{namespace, local_name}`.

  ## Status lives in two places and both matter

  A `<response>` may carry one `<status>` — that is the whole-resource answer,
  and `404` there is how RFC 6578 reports a deletion inside a sync report. Or
  it may carry `<propstat>` blocks, each with its own status, because a server
  is allowed to say "here is the etag (200), and I will not tell you the
  calendar data (403)" about the same resource. Collapsing those two shapes
  into one loses the deletion, which is the difference between an incremental
  sync and a calendar-wipe.

  ## What is deliberately not done

  No XPath. `:xmerl_xpath` needs namespace bindings threaded through every
  query and buys nothing here — the document is four levels deep and the walk
  below is shorter than the bindings would be.
  """

  require Record

  Record.defrecordp(
    :xmlElement,
    Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  )

  Record.defrecordp(
    :xmlText,
    Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  )

  # Atoms, because that is what `xmlElement.expanded_name` holds when the scan
  # is namespace-conformant: xmerl resolves every prefix against the in-scope
  # declarations and hands back `{:"DAV:", :response}`. Matching that is exact
  # and needs no prefix bookkeeping of our own.
  @dav :"DAV:"
  @caldav :"urn:ietf:params:xml:ns:caldav"
  @calendarserver :"http://calendarserver.org/ns/"

  @typedoc """
  One `<response>`, flattened.

  `status` is the resource-level code when the server gave one and `nil` when
  it only spoke in `propstat` blocks. A `nil` status with props present is an
  ordinary hit; `404` is a deletion.
  """
  @type response :: %{
          href: String.t() | nil,
          status: pos_integer() | nil,
          etag: String.t() | nil,
          calendar_data: String.t() | nil
        }

  @doc """
  Parse a `multistatus` body.

  Returns `{:error, :malformed}` rather than raising: a truncated response from
  a proxy is an ordinary network event, and `Kati.Sync.Backoff` should get to
  classify it like any other.
  """
  @spec multistatus(binary()) ::
          {:ok, %{responses: [response()], sync_token: String.t() | nil}}
          | {:error, :malformed}
  def multistatus(body) when is_binary(body) do
    with {:ok, root} <- scan(body) do
      {:ok,
       %{
         responses: Enum.map(children(root, @dav, :response), &response/1),
         sync_token: first_text(root, @dav, :"sync-token")
       }}
    end
  end

  @doc """
  Every `href` in a `calendar-home-set` or `current-user-principal` document.

  Discovery answers with the same `multistatus` shape but the interesting part
  is nested one level deeper, inside the prop rather than beside it.
  """
  @spec hrefs_in(binary(), String.t()) :: {:ok, [String.t()]} | {:error, :malformed}
  def hrefs_in(body, property) when is_binary(body) and is_binary(property) do
    name = String.to_atom(property)

    with {:ok, root} <- scan(body) do
      hrefs =
        for response <- children(root, @dav, :response),
            propstat <- children(response, @dav, :propstat),
            prop <- children(propstat, @dav, :prop),
            holder <- children(prop, @dav, name) ++ children(prop, @caldav, name),
            href <- children(holder, @dav, :href),
            do: text_of(href)

      {:ok, Enum.reject(hrefs, &(&1 in [nil, ""]))}
    end
  end

  @doc """
  Calendars described by a `PROPFIND` on the calendar home set.

  A collection is a calendar when its resourcetype carries the CalDAV
  `calendar` element. The home set also contains the inbox, the outbox and
  plain collections, and every one of them has a `displayname` — so filtering
  on "has a name" would subscribe the user to their own scheduling inbox.
  """
  @spec calendars(binary()) :: {:ok, [map()]} | {:error, :malformed}
  def calendars(body) when is_binary(body) do
    with {:ok, root} <- scan(body) do
      {:ok,
       for response <- children(root, @dav, :response),
           calendar?(response),
           href = first_text(response, @dav, :href),
           href not in [nil, ""] do
         %{
           href: href,
           display_name: prop_text(response, @dav, :displayname),
           colour: prop_text(response, @calendarserver, :"calendar-color"),
           ctag: prop_text(response, @calendarserver, :getctag),
           privileges: privileges(response)
         }
       end}
    end
  end

  @doc """
  Whether a parsed calendar may be written to.

  Read from `current-user-privilege-set`, which is the server's own answer and
  the only trustworthy one — a calendar can be shared read-only, and the client
  has no other way to know before a `PUT` fails. When the server does not
  report privileges at all, this returns `nil`: *unknown*, not *writable*.
  """
  @spec writable?(map()) :: boolean() | nil
  def writable?(%{privileges: nil}), do: nil
  def writable?(%{privileges: privs}), do: "write-content" in privs or "write" in privs

  # ── Internals ──────────────────────────────────────────────────────────────

  defp scan(body) do
    # `xmerl_scan` raises on malformed input and also emits to stderr; both are
    # wrong for a network payload, so it is wrapped rather than trusted.
    {doc, _rest} =
      body
      |> String.to_charlist()
      |> :xmerl_scan.string(
        namespace_conformant: true,
        quiet: true
      )

    {:ok, doc}
  rescue
    _ -> {:error, :malformed}
  catch
    :exit, _ -> {:error, :malformed}
  end

  defp response(element) do
    %{
      href: first_text(element, @dav, :href),
      status: element |> first_text(@dav, :status) |> status_code(),
      etag: element |> prop_text(@dav, :getetag) |> unquote_etag(),
      calendar_data: prop_text(element, @caldav, :"calendar-data")
    }
  end

  # `<status>HTTP/1.1 404 Not Found</status>` — the number is the whole point
  # and the words after it are for humans.
  defp status_code(nil), do: nil

  defp status_code(line) do
    case Regex.run(~r/\bHTTP\/\d\.\d\s+(\d\d\d)\b/, line) do
      [_, code] -> String.to_integer(code)
      _ -> nil
    end
  end

  # Etags are quoted in the header and quoted in the XML, and a weak validator
  # carries a `W/` prefix. Stored bare so `If-Match` can put back exactly one
  # set of quotes rather than two.
  defp unquote_etag(nil), do: nil

  defp unquote_etag(etag) do
    etag
    |> String.trim()
    |> String.replace_prefix("W/", "")
    |> String.trim("\"")
  end

  # A collection is a calendar when its resourcetype carries the CalDAV
  # `calendar` element — not when it merely has a display name. The home set
  # also holds the scheduling inbox and outbox, and both are named.
  defp calendar?(response) do
    Enum.any?(children(response, @dav, :propstat), fn propstat ->
      Enum.any?(children(propstat, @dav, :prop), fn prop ->
        Enum.any?(children(prop, @dav, :resourcetype), fn type ->
          children(type, @caldav, :calendar) != []
        end)
      end)
    end)
  end

  defp privileges(response) do
    sets =
      for propstat <- children(response, @dav, :propstat),
          prop <- children(propstat, @dav, :prop),
          set <- children(prop, @dav, :"current-user-privilege-set"),
          do: set

    case sets do
      [] ->
        nil

      sets ->
        for set <- sets,
            privilege <- children(set, @dav, :privilege),
            granted <- elements(privilege),
            do: local_of(granted)
    end
  end

  # A prop value, from whichever propstat block carries it.
  defp prop_text(element, ns, name) do
    Enum.find_value(children(element, @dav, :propstat), fn propstat ->
      Enum.find_value(children(propstat, @dav, :prop), fn prop ->
        first_text(prop, ns, name)
      end)
    end)
  end

  defp first_text(element, ns, name) do
    case children(element, ns, name) do
      [found | _] -> text_of(found)
      [] -> nil
    end
  end

  defp children(element, ns, name) do
    for child <- elements(element), matches?(child, ns, name), do: child
  end

  defp matches?(element, ns, name) do
    xmlElement(element, :expanded_name) == {ns, name}
  end

  # The local half of an expanded name, for elements whose namespace is already
  # known from context — the granted privilege inside a `<privilege>` wrapper.
  defp local_of(element) do
    case xmlElement(element, :expanded_name) do
      {_ns, local} -> Atom.to_string(local)
      local when is_atom(local) -> Atom.to_string(local)
    end
  end

  defp elements(element) do
    for child <- xmlElement(element, :content), Record.is_record(child, :xmlElement), do: child
  end

  defp text_of(element) do
    element
    |> xmlElement(:content)
    |> Enum.map(fn
      node -> if Record.is_record(node, :xmlText), do: xmlText(node, :value), else: ~c""
    end)
    |> List.flatten()
    |> List.to_string()
    |> String.trim()
  end
end
