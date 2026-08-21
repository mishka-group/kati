defmodule Kati.Native.Bridge do
  @moduledoc """
  The one place Kati talks to `Kati.Nifs.KatiBridge`.

  Three unrelated features cross the same boundary — the file transport (#64),
  notification arming and the periodic refresh worker (#58) — and each one
  needs the same four answers: is the native half bound, what did it reply, was
  that a success, and what is the reason if not. Written once here so a
  regression in the boundary is one fix rather than three, and so the
  "swallowed exception" pattern lives in a single reviewable place.

  ## The reply grammar

  Every bridge method returns a `String` and never throws across JNI:

      "ok"              the operation succeeded and has nothing to report
      "ok:<payload>"    it succeeded and this is the answer
      "error:<reason>"  it failed, and the reason is from a closed set

  `reply/2` hands that string back untouched, because the closed set differs
  per feature and mapping it to atoms is the caller's job — a shared mapping
  here would have to be the union of every caller's vocabulary, which is
  exactly the unbounded set the closed set exists to avoid.

  ## Three ways to have no native half, one answer

    * the NIF module is not in the build,
    * it is in the build but `:erlang.load_nif/2` did not bind it — the host,
      where there is no static NIF table at all,
    * it bound but `JNI_OnLoad` never cached the bridge class, which is what
      iOS and any non-Android arch reports.

  All three answer `{:error, :no_bridge}`. A caller's response to them is
  identical: tell the user the feature is not available here, and never fake it.
  """

  @nif Kati.Nifs.KatiBridge

  @type reply :: {:ok, binary()} | {:error, :no_bridge | {:native, String.t()}}

  @doc """
  Whether the bridge is bound and its class cached.

  Side-effect free: `Kati.Nifs.KatiBridge.available/0` exists precisely so this
  question can be asked without arming an alarm, enqueuing work, or putting a
  file dialog in front of the user.
  """
  @spec available?() :: boolean()
  def available? do
    match?({:ok, "ok"}, reply(:available, []))
  end

  @doc """
  Call a bridge function and return its reply string.

  Never raises. Kati runs one screen process — an exception escaping here takes
  the whole UI down, and "the share sheet is missing" is not worth a black
  screen.
  """
  @spec reply(atom(), [term()]) :: reply()
  def reply(fun, args) when is_atom(fun) and is_list(args) do
    if bound?(fun, length(args)) do
      try do
        {:ok, apply(@nif, fun, args)}
      rescue
        e -> {:error, exception_reason(e)}
      end
    else
      {:error, :no_bridge}
    end
  end

  @doc """
  Encode `payload` as the JSON string every bridge method that takes structured
  arguments expects.
  """
  @spec encode(map()) :: binary()
  def encode(payload) when is_map(payload), do: IO.iodata_to_binary(:json.encode(payload))

  @doc """
  Split a reply into `{:ok, payload}` / `{:error, reason_string}`.

  `payload` is `""` for a bare `"ok"`. A reply that is neither shape is an
  error carrying the whole string, because a bridge that has drifted should be
  visible rather than silently read as success.

      iex> Kati.Native.Bridge.split("ok")
      {:ok, ""}
      iex> Kati.Native.Bridge.split("ok:hardware")
      {:ok, "hardware"}
      iex> Kati.Native.Bridge.split("error:no_activity")
      {:error, "no_activity"}
      iex> Kati.Native.Bridge.split("what")
      {:error, "what"}
  """
  @spec split(binary()) :: {:ok, binary()} | {:error, binary()}
  def split("ok"), do: {:ok, ""}
  def split("ok:" <> payload), do: {:ok, payload}
  def split("error:" <> reason), do: {:error, reason}
  def split(other) when is_binary(other), do: {:error, other}

  # ── internals ───────────────────────────────────────────────────────────

  defp bound?(fun, arity) do
    Code.ensure_loaded?(@nif) and function_exported?(@nif, fun, arity)
  end

  # An unbound static NIF stub raises `:erlang.nif_error(:nif_not_loaded)`,
  # which is the host and iOS case and means exactly "no native half". Anything
  # else that escapes is a real fault and keeps its own message, so a genuine
  # bridge bug is never disguised as an absent platform.
  defp exception_reason(%ErlangError{original: :nif_not_loaded}), do: :no_bridge
  defp exception_reason(exception), do: {:native, Exception.message(exception)}
end
