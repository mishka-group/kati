defmodule Kati.Net.Tls do
  @moduledoc """
  The two global settings every HTTPS call in Kati needs, done once, on demand.

  Both used to run in `Kati.App.on_start/0` and cost **137 ms of a 1.06 s
  boot** — 13 per cent of the path to first paint, for something no screen in
  the app needs before it draws. #37 asked which statements must leave the boot
  path; these two are the clearest answer, because moving them changes no
  behaviour at all.

  ## What they are and why they cannot simply be dropped

    * **`Mob.Certs.load_cacerts!/1`.** Android's system trust store lives behind
      a Java API that BEAM's `:public_key` cannot reach, so
      `:public_key.cacerts_load/0` finds no bundle and the first HTTPS call dies
      inside Req/Finch/Mint with an opaque `FunctionClauseError`. Kati is
      entirely third-party API calls, so this must happen before anything
      touches TLS — *before*, not *at boot*.
    * **`Mob.DNS.configure_pure_beam/0`.** Flips the lookup chain off the
      iOS-broken `:native` path (the `inet_gethost` port program) onto
      `[:file, :dns]` and seeds Google and Cloudflare as fallback nameservers.

  ## Once, and cheaply thereafter

  `:persistent_term` rather than a GenServer or an Agent: this is a read on
  every request and a write once in the life of the process, which is exactly
  what `:persistent_term` is for, and it needs no supervision tree to be up.
  The read costs a few nanoseconds, so callers do not have to be careful about
  where they put the call.

  It is deliberately **not** idempotent by luck. Two requests racing on a cold
  process both see `false` and both configure — which is harmless, because both
  write the same values — and both then write the flag. A lock here would cost
  more than the double work it prevents.

  ## Who calls it

  `Kati.Sync.Adapter.CalDAV.Transport` is the only module in the app that makes
  an HTTP request today. Any second one must call this too, and the test
  `Kati.BootPathTest` fails if a new `Req.` caller appears that does not — the
  failure mode otherwise is a TLS error three screens away from its cause,
  which is the thing the boot-time version existed to prevent.
  """

  @flag {__MODULE__, :configured?}

  @doc """
  Configure the trust store and the resolver, unless it has already happened.

  Returns `:ok` either way. Safe to call on every request.
  """
  @spec ensure!() :: :ok
  def ensure! do
    if :persistent_term.get(@flag, false) do
      :ok
    else
      Mob.Certs.load_cacerts!(Kati.Priv.path("cacerts.pem"))
      Mob.DNS.configure_pure_beam()
      :persistent_term.put(@flag, true)
      :ok
    end
  end

  @doc "Whether `ensure!/0` has run in this process's node. For tests and the diagnostic screen."
  @spec configured?() :: boolean()
  def configured?, do: :persistent_term.get(@flag, false)

  @doc false
  @spec reset() :: :ok
  def reset, do: :persistent_term.erase(@flag) && :ok
end
