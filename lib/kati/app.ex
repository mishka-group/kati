defmodule Kati.App do
  @moduledoc """
  Application entry point for Kati.

  `on_start/0` is the only place device runtime configuration can happen.
  `config/*.exs` is a **build-time** artifact that never ships: the device
  boots `start_clean` with no `-config` in argv and an empty `.app` env, so
  every `config :foo, ...` line is invisible on a phone. Anything the app
  needs at runtime is set by `Kati.Runtime`, which is the only module that
  writes application environment.
  """

  use Mob.App

  # Erlang distribution is a development convenience — `mix mob.deploy`,
  # `mix mob.connect`, `:observer`. It opens a listening socket with a
  # fixed cookie, so it must never be in a release build. Resolved at
  # compile time because `Mix` does not exist on the device.
  @dev? Mix.env() == :dev

  @impl Mob.App
  def navigation(_platform) do
    stack(:main, root: Kati.HomeScreen)
  end

  @impl Mob.App
  def on_start do
    Kati.Runtime.configure()

    # Android's system trust store lives behind a Java API that BEAM's
    # `:public_key` cannot reach, so `:public_key.cacerts_load/0` finds no
    # bundle and the first HTTPS call dies inside Req/Finch/Mint with an
    # opaque `FunctionClauseError`. Kati is entirely third-party API calls,
    # so this must happen before anything touches TLS.
    #
    # `Mob.Certs`' own docs suggest `Application.app_dir/2` here — that is
    # wrong on device for the same reason it is wrong for migrations (see
    # `priv_path/1`).
    Mob.Certs.load_cacerts!(priv_path("cacerts.pem"))

    # Configure BEAM's DNS path so Req / Finch / Mint / `gen_tcp:connect/3`
    # with a hostname work on iOS without per-host setup. Flips the lookup
    # chain from the iOS-broken `:native` (inet_gethost port program) path
    # to `[:file, :dns]` and seeds Google + Cloudflare as fallback
    # nameservers.
    Mob.DNS.configure_pure_beam()

    {:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
    # Ash has no application callback module, so nothing strictly needs
    # starting — but :ecto, :telemetry and :spark do, and ensure_all_started
    # pulls them in transitively. Recorded as the working variant by #30.
    {:ok, _} = Application.ensure_all_started(:ash)
    {:ok, _} = Kati.Repo.start_link()

    # DEPLOYING A MIGRATION REQUIRES `mix mob.deploy --native`.
    #
    # The fast path (`mix mob.deploy`) pushes BEAM files only; it does not sync
    # priv/. A new migration therefore never reaches the device, `Ecto.Migrator`
    # finds nothing new, and the app logs "Migrations already up" and carries on
    # against a stale schema. Measured on device (#30): after a fast deploy the
    # device had 1 of 2 migration files and the new column silently did not
    # exist. Only `--native` runs the "Copying priv/ (full)" step.
    Ecto.Migrator.with_repo(Kati.Repo, fn repo ->
      Ecto.Migrator.run(repo, priv_path("repo/migrations"), :up, all: true)
    end)

    # Loud before silent: every condition here otherwise fails invisibly — a
    # missing table renders as a frozen screen, because the screen GenServer
    # crashes on its first query with nothing on screen to say so.
    Kati.Runtime.assert!(~w(schema_migrations spike_things))

    Mob.Screen.start_root(Kati.HomeScreen)

    if @dev? do
      Mob.Dist.ensure_started(
        node: :"kati_android@127.0.0.1",
        cookie: dev_cookie()
      )
    end

    :ok
  end

  # `:mob_secret` is mob_dev's default and `mix mob.connect` hardcodes it at
  # mob.connect.ex:114, so a custom value silently breaks `mob.connect`,
  # `mob.push` and `mob.verify_strip` — which is how this was found.
  #
  # That is acceptable because the cookie is not protecting anything: the
  # `@dev?` gate above means distribution is absent from release builds
  # entirely, and mob_beam additionally drops -name/-setcookie when
  # MOB_RELEASE is defined. The risk was ever shipping a listening socket to
  # users, not the value of a dev-only cookie. Still overridable.
  defp dev_cookie do
    System.get_env("MOB_DIST_COOKIE", "mob_secret") |> String.to_atom()
  end

  @doc """
  Absolute path to a file or directory inside the app's `priv/`.

  `Application.app_dir/2` calls `:code.priv_dir/1`, which needs the
  versioned `$OTP_ROOT/lib/APP-VERSION/ebin/` layout of a normal release.
  Mob deploys `.beam` files to a **flat** `-pa` directory with no such
  structure, so `:code.priv_dir/1` returns `{:error, :bad_name}`.

  The failure is silent and expensive: `Ecto.Migrator.run/3` finds zero
  migrations, logs "Migrations already up", never creates a table, and the
  first query crashes the screen GenServer — which renders as a frozen
  screen with no error.

  `mob_beam` sets `MOB_BEAMS_DIR` before `erl_start`, and the deployer
  pushes `priv/` to `$MOB_BEAMS_DIR/priv/`, so that is the device path.
  """
  @spec priv_path(String.t()) :: String.t()
  def priv_path(relative) do
    case System.get_env("MOB_BEAMS_DIR") do
      nil -> Application.app_dir(:kati, Path.join("priv", relative))
      beams_dir -> Path.join([beams_dir, "priv", relative])
    end
  end
end
