defmodule Kati.Sync.Adapter.CalDAV.Transport do
  @moduledoc """
  The HTTP call itself, behind a behaviour so tests need no server.

  Everything above this is pure: `Kati.Sync.Adapter.CalDAV.XML` turns bytes into data
  and `Kati.Sync.Adapter.CalDAV` turns operations into requests. This is the
  one module that touches a socket, which is why it is the one module a test
  replaces.
  """

  @type request :: %{
          method: :get | :put | :delete | :propfind | :report | :options,
          url: String.t(),
          headers: [{String.t(), String.t()}],
          body: binary() | nil
        }

  @type response :: %{status: pos_integer(), headers: [{String.t(), String.t()}], body: binary()}

  @callback call(request()) :: {:ok, response()} | {:error, term()}

  @doc """
  The configured transport.

  Read at call time rather than compiled in, so a test can swap it per-case
  without recompiling — and so a future account-level override (a proxy, a
  self-signed CA) has somewhere to go.
  """
  @spec impl() :: module()
  def impl, do: Application.get_env(:kati, :caldav_transport, Kati.Sync.Adapter.CalDAV.Req)
end

defmodule Kati.Sync.Adapter.CalDAV.Req do
  @moduledoc """
  The real transport, over `Req`.

  ## Why the verbs are spelled out

  `PROPFIND` and `REPORT` are not in `Req`'s convenience API and are not in
  most HTTP clients', because they are WebDAV rather than HTTP/1.1 proper.
  `Req.request/1` takes `:method` as an atom and passes it through, which is
  the whole trick.

  ## Redirects are not followed

  A CalDAV `PUT` that follows a redirect can land the write on a collection the
  user did not authorise, and a `301` from a discovery request is meaningful
  data — it is how a server moves a principal. So redirects come back as
  ordinary responses and the caller decides.
  """

  @behaviour Kati.Sync.Adapter.CalDAV.Transport

  @impl true
  def call(%{method: method, url: url, headers: headers, body: body}) do
    [
      method: method,
      url: url,
      headers: headers,
      body: body,
      redirect: false,
      # A calendar home with a decade of events is a large multistatus, and the
      # default is generous rather than tuned: `Kati.Sync.Backoff` classifies a
      # timeout as retryable, so being wrong here costs a retry, not data.
      receive_timeout: 30_000,
      retry: false,
      decode_body: false
    ]
    |> Req.new()
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: status, headers: resp_headers, body: resp_body}} ->
        {:ok, %{status: status, headers: flatten(resp_headers), body: resp_body || ""}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Req gives `%{"etag" => ["\"abc\""]}`; the rest of this subsystem wants a
  # plain list of pairs and does not care that a header may repeat.
  defp flatten(headers) when is_map(headers) do
    for {name, values} <- headers, value <- List.wrap(values), do: {name, value}
  end

  defp flatten(headers) when is_list(headers), do: headers
end

defmodule Kati.Sync.Adapter.CalDAV.Credentials do
  @moduledoc """
  Where a CalDAV account's URL and password come from.

  A seam for the same reason the transport is one, not as a favour to tests:
  `Kati.SecureStore` is the Android Keystore behind a NIF, so on a host there
  is nothing to read from and no way to write. Every host test of the adapter
  would otherwise be a test of that absence.

  The stored value is JSON — `{"url": ..., "username": ..., "password": ...}` —
  under the key in `Kati.Calendars.Account.credentials_ref`. The password never
  reaches a column, a log or a screen; this module and the `authorization`
  header are the only places it exists in the clear.
  """

  @callback fetch(map()) :: {:ok, map()} | {:error, term()}

  @spec impl() :: module()
  def impl, do: Application.get_env(:kati, :caldav_credentials, Kati.Sync.Adapter.CalDAV.Keystore)
end

defmodule Kati.Sync.Adapter.CalDAV.Keystore do
  @moduledoc "Credentials out of the device keystore, via `Kati.SecureStore`."

  @behaviour Kati.Sync.Adapter.CalDAV.Credentials

  @impl true
  def fetch(%{credentials_ref: ref}) when is_binary(ref) and ref != "" do
    with {:ok, raw} <- Kati.SecureStore.get(ref),
         {:ok, map} when is_map(map) <- Jason.decode(raw) do
      {:ok, map}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :bad_credentials}
    end
  end

  def fetch(_account), do: {:error, :no_credentials}
end
