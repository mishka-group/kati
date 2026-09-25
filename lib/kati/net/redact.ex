defmodule Kati.Net.Redact do
  @moduledoc """
  Keeps a credential out of an error reason before the reason travels.

  Kati's two authenticated callers — `Kati.Media.Tmdb` and
  `Kati.Sync.Adapter.CalDAV.Req` — put a secret in exactly one place, the
  `authorization` header, and answer failures as `{:error, reason}`. Most
  reasons are atoms. Some are not: Mint refuses a header value it cannot send
  with `{:invalid_header_value, "authorization", value}`, which is the whole
  header, token included, and any exception a transport raises may quote the
  request it was handed. A reason is then inspected into
  `Kati.Sync.OutboxEntry.last_error` (a plaintext column), into a log line, or
  into a crash report — all places a token must never be.

  So a reason that contains a secret is replaced whole by `:redacted` at the
  edge where the secret was used. Whole rather than trimmed: a reason with the
  token cut out of it is a reason nobody can assert anything about, and
  *which* request failed is already known to the caller.

  The search walks the term — tuples, lists, maps, structs — and looks inside
  every binary, rather than looking at `inspect/2`'s rendering of it. A
  rendering escapes a newline and a struct's own `Inspect` may mask a token
  (Req's shows three characters of a bearer), and either would let the secret
  pass the check while staying in the term.
  """

  @doc """
  `reason`, or `:redacted` when any of `secrets` appears anywhere inside it.

  Secrets shorter than four bytes are ignored: they would match by accident,
  and nothing Kati holds as a credential is that short.

      iex> Kati.Net.Redact.reason(:timeout, ["abcd1234"])
      :timeout

      iex> Kati.Net.Redact.reason({:invalid_header_value, "authorization", "Bearer abcd1234"}, ["abcd1234"])
      :redacted

      iex> Kati.Net.Redact.reason(%RuntimeError{message: "sent abcd1234"}, ["abcd1234", nil])
      :redacted
  """
  @spec reason(term(), [String.t() | nil]) :: term()
  def reason(reason, secrets) do
    secrets = Enum.filter(secrets, &(is_binary(&1) and byte_size(&1) >= 4))

    if secrets != [] and carries?(reason, secrets), do: :redacted, else: reason
  end

  defp carries?(term, secrets) when is_binary(term),
    do: Enum.any?(secrets, &String.contains?(term, &1))

  defp carries?(term, secrets) when is_tuple(term),
    do: term |> Tuple.to_list() |> carries?(secrets)

  defp carries?(term, secrets) when is_map(term),
    do: term |> Map.to_list() |> carries?(secrets)

  defp carries?([head | tail], secrets),
    do: carries?(head, secrets) or carries?(tail, secrets)

  defp carries?(_other, _secrets), do: false
end
