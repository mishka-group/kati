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
    stack(:main, root: Kati.Screens.Home)
  end

  @impl Mob.App
  def on_start do
    Kati.Runtime.configure()
    trace("configure")

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

    # Prove the bundle before anything depends on it. Five features ship
    # assets in priv/ and a missing one fails silently in a different way
    # each time — Ecto reports "already up", Mob.Certs reports a TLS error
    # three screens later. One check, at the point where a bad bundle is
    # still explicable. Quiet when healthy, per #38's boot budget.
    case Kati.Priv.probe() do
      %{ok?: true} ->
        :ok

      %{lines: lines} ->
        IO.puts("Kati: priv/ BUNDLE BROKEN\n  " <> Enum.join(lines, "\n  "))
    end

    # Configure BEAM's DNS path so Req / Finch / Mint / `gen_tcp:connect/3`
    # with a hostname work on iOS without per-host setup. Flips the lookup
    # chain from the iOS-broken `:native` (inet_gethost port program) path
    # to `[:file, :dns]` and seeds Google + Cloudflare as fallback
    # nameservers.
    Mob.DNS.configure_pure_beam()

    trace("certs+dns")
    {:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
    trace("ecto_sqlite3")
    start_ash!()
    trace("ash")
    {:ok, _} = Kati.Repo.start_link()
    trace("repo")

    # DEPLOYING A MIGRATION REQUIRES `mix mob.deploy --native`.
    #
    # The fast path (`mix mob.deploy`) pushes BEAM files only; it does not sync
    # priv/. A new migration therefore never reaches the device, `Ecto.Migrator`
    # finds nothing new, and the app logs "Migrations already up" and carries on
    # against a stale schema. Measured on device (#30): after a fast deploy the
    # device had 1 of 2 migration files and the new column silently did not
    # exist. Only `--native` runs the "Copying priv/ (full)" step.
    # `Ecto.Migrator.run/4` directly, not `with_repo/2`. That helper exists to
    # start `:ecto_sql`, the adapter's apps and the repo, then stop again
    # (`migrator.ex:with_repo/3`) — all of which has already happened above.
    # It would also open a second pool of its own default size, against a
    # repo deliberately configured `pool_size: 1` because SQLite has one
    # writer.
    Ecto.Migrator.run(Kati.Repo, priv_path("repo/migrations"), :up, all: true)

    # Loud before silent: every condition here otherwise fails invisibly — a
    # missing table renders as a frozen screen, because the screen GenServer
    # crashes on its first query with nothing on screen to say so.
    trace("migrations")
    Kati.Runtime.assert!(~w(schema_migrations spike_things))

    # The root screen starts UNDER Kati.Supervisor, not here. Mob's
    # start_root/3 is a bare GenServer.start_link, so an unsupervised screen
    # that crashes stays dead and the app simply looks frozen.
    trace("assert")
    {:ok, _} = Kati.Supervisor.start_link()
    trace("supervisor")

    # Before any screen renders: a `<MishkaChip />` in ~MOB markup expands only
    # if its tag is in the composite registry, and an unregistered tag renders
    # as NOTHING rather than raising.
    Kati.Components.register_all()
    trace("components")

    # Ingest whatever KatiCalendarReader published. Before the permission is
    # granted this is a no-op returning {:ok, :no_data} — the normal state, not
    # an error, so it must not be allowed to stop the app booting.
    case Kati.Calendars.DeviceImport.run() do
      {:ok, %{calendars: c, events: e}} ->
        :mob_nif.log("Kati: imported #{c} calendars, #{e} events")

      {:ok, :no_data} ->
        :mob_nif.log("Kati: no device calendars published yet")

      {:error, reason} ->
        :mob_nif.log("Kati: calendar import failed: #{inspect(reason)}")
    end

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

  # Apps in Ash's dependency list that must not be started on a device.
  #
  # `:igniter` is a **compile-time codegen tool** — it writes Mix tasks and
  # patches source files — but `ash.app` names it in its runtime
  # `applications`, so `Application.ensure_all_started(:ash)` tries to start
  # it. igniter in turn requires `:inets`, and the Android OTP runtime ships
  # no `:inets` at all (20 libs; `find files/otp -name 'inets*'` is empty).
  #
  # The result on a FRESH install is a dead app:
  #
  #     step 5 => {error,{badmatch,{error,{inets,
  #                 {"no such file or directory","inets.app"}}}}}
  #
  # This hid for a long time because a device that had been deployed to
  # before kept an older OTP tree across deploys — only wiping app data
  # exposes it, which is exactly what a user's first install does. It would
  # have shipped as "the app opens to a blank screen and closes".
  @never_start_on_device [:igniter]

  # A phase marker per boot step, tagged BEAMout in logcat.
  #
  # Worth its eight lines: when the app died before any screen appeared, the
  # only evidence was `step 5 => {error,{badmatch,...}}` from `src/kati.erl`,
  # which names the failing pattern but not the caller. Several deploys went
  # into guessing which call it was. This answers it in one. It also gives
  # #37 real per-phase timings on a cold start rather than a single total.
  defp trace(phase), do: IO.puts("Kati.boot: " <> phase)

  @doc false
  @spec never_start_on_device() :: [atom()]
  def never_start_on_device, do: @never_start_on_device

  # Ash itself has no `mod` in its .app — it is a library with nothing to
  # start — so the closure is walked directly instead of asking
  # `ensure_all_started(:ash)`, which would drag in the whole denylist.
  #
  # Only applications that actually have a supervision tree are started; the
  # rest are merely loaded, which is all `Application.get_env/2` needs. An
  # app whose own closure touches the denylist cannot be started through
  # `Application.start/1` at all — `application_controller` refuses with
  # `{:not_started, :igniter}` — so those are reported by
  # `blocked_apps/0` and supervised by `Kati.Supervisor` instead.
  defp start_ash! do
    for app <- app_closure(:ash), has_supervision_tree?(app), app not in blocked_apps() do
      {:ok, _} = Application.ensure_all_started(app)
    end

    :ok
  end

  @doc """
  Applications with a supervision tree that cannot be started normally on a
  device, because their own dependency list reaches `@never_start_on_device`.

  `Kati.Supervisor` starts each one's `start/2` itself, so the processes
  still exist and nothing is quietly missing — only the bookkeeping entry in
  `application_controller` is absent.
  """
  @spec blocked_apps() :: [atom()]
  def blocked_apps do
    Enum.filter(app_closure(:ash), fn app ->
      has_supervision_tree?(app) and
        Enum.any?(@never_start_on_device, &(&1 in raw_closure(app)))
    end)
  end

  @doc """
  Transitive `applications` of `root`, **pruned** at the denylist.

  Pruning has to happen during the walk, not afterwards. Descending into
  `:igniter` reaches `:inets`, which has a supervision tree and is absent
  from the device — so a filter applied to the finished list still leaves
  the boot trying to start it. Pruned, the closure is 28 apps; unpruned, 46.
  """
  @spec app_closure(atom()) :: [atom()]
  def app_closure(root), do: root |> closure([], @never_start_on_device) |> Enum.uniq()

  # Unpruned: used only to ask whether an app is reachable from the denylist,
  # which is what makes it unstartable through application_controller.
  defp raw_closure(root), do: root |> closure([], []) |> Enum.uniq()

  defp closure(app, seen, pruned) do
    if app in seen or app in pruned do
      seen
    else
      Application.load(app)

      # Record the app even when it has no spec. An app that fails to load
      # (`:inets` on device) would otherwise vanish from the closure, and
      # `blocked_apps/0` decides what is startable by looking for exactly
      # such an app.
      case Application.spec(app, :applications) do
        nil -> [app | seen]
        deps -> Enum.reduce(deps, [app | seen], &closure(&1, &2, pruned))
      end
    end
  end

  defp has_supervision_tree?(app), do: Application.spec(app, :mod) not in [nil, []]

  @doc """
  Absolute path to a file or directory inside the app's `priv/`.

  Delegates to `Kati.Priv.path/1`, which documents why `:code.priv_dir/1`
  cannot be used on Mob and why this one path is correct in both a dev
  deploy and a release build.
  """
  @spec priv_path(String.t()) :: String.t()
  defdelegate priv_path(relative), to: Kati.Priv, as: :path
end
