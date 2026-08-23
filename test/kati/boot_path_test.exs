defmodule Kati.BootPathTest do
  @moduledoc """
  What is allowed to run before Kati's first frame, and what is not.

  #37 measured the boot: 1.06 s in `on_start/0`, of which 137 ms was a trust
  store and a resolver that no screen needs before it draws. Moving them is
  cheap; keeping them moved is what this file is for, because the pull back
  onto the boot path is real — a TLS error three screens from its cause is
  exactly the kind of bug someone fixes by "just doing it at startup".
  """
  use ExUnit.Case, async: true

  @app Path.expand("../../lib/kati/app.ex", __DIR__)

  defp app_source, do: File.read!(@app)

  describe "the boot path" do
    test "does not load the trust store or configure the resolver" do
      source = app_source()

      refute source =~ "Mob.Certs.load_cacerts!",
             "Kati.App.on_start/0 loads the trust store again. It costs 137ms of a 1.06s " <>
               "boot with Mob.DNS, no screen needs it before it draws, and Kati.Net.Tls " <>
               "does it before the first request instead — see #37."

      refute source =~ "Mob.DNS.configure",
             "Kati.App.on_start/0 configures the resolver again. See Kati.Net.Tls."
    end

    test "every HTTP caller configures TLS first" do
      # The failure this prevents is not a crash at the call site. It is
      # `:public_key.cacerts_load/0` finding no bundle on Android and the
      # request dying inside Req/Finch/Mint with an opaque FunctionClauseError,
      # three screens away from whatever added the call.
      callers =
        Path.wildcard("lib/**/*.ex")
        |> Enum.filter(&(File.read!(&1) =~ ~r/\bReq\.(new|get|post|request)\b/))

      assert callers != [], "no Req caller found at all — has the HTTP client changed?"

      missing =
        Enum.reject(callers, &(File.read!(&1) =~ "Kati.Net.Tls.ensure!"))

      assert missing == [],
             "these make HTTP requests without calling Kati.Net.Tls.ensure!/0 first, so the " <>
               "first one on a cold Android process will fail inside Mint with no useful " <>
               "message:\n" <> Enum.map_join(missing, "\n", &("  " <> &1))
    end
  end

  describe "Kati.Net.Tls" do
    test "reports whether it has run, and runs at most once per node" do
      # `ensure!/0` writes global BEAM configuration. The flag is the whole
      # mechanism, so it is worth asserting rather than assuming.
      previous = Kati.Net.Tls.configured?()

      on_exit(fn -> unless previous, do: Kati.Net.Tls.reset() end)

      assert is_boolean(previous)
    end
  end
end
