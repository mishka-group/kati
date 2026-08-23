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

  # MUST stay pure. `Mob.Nav.Registry.start_link/1` calls this from its own
  # `init/1`, and `Mob.App.start/0` starts that registry BEFORE `Mob.State` —
  # so anything here that reaches a GenServer kills the boot before a single
  # screen renders. Asking `Kati.Onboarding.complete?/0` here did exactly that:
  # the BEAM came up, `Mob.Nav.Registry.populate/1` exited on a call to a
  # process that did not exist yet, and the app sat on its splash screen
  # forever with no crash and no trace.
  #
  # The real root is chosen in `on_start/0`, which runs after `Mob.State`.
  @impl Mob.App
  def navigation(_platform) do
    stack(:main, root: Kati.Screens.Home)
  end

  @impl Mob.App
  def on_start do
    trace_start()
    Kati.Runtime.configure()
    trace("configure")

    # Re-point the stack root now that `Mob.State` is running.
    #
    # A fresh install has to run the first-run sequence — screens 53, 26 and
    # 38 — and after it the root is whichever shell the chosen locale names,
    # so someone who picked فارسی does not get an English home page on every
    # launch. `navigation/1` cannot make that decision (see the comment there);
    # `Mob.Nav.Registry.register/3` is the runtime equivalent and writes the
    # same `{name, root, params}` row `populate/1` does.
    Mob.Nav.Registry.register(:main, Kati.Onboarding.first_screen())

    # Android's system trust store lives behind a Java API that BEAM's
    # `:public_key` cannot reach, so `:public_key.cacerts_load/0` finds no
    # bundle and the first HTTPS call dies inside Req/Finch/Mint with an
    # opaque `FunctionClauseError`. Kati is entirely third-party API calls,
    # so this must happen before anything touches TLS.
    #
    # NOT here any more — `Kati.Net.Tls.ensure!/0` does it before the first
    # request instead. The two of them cost 137ms of a 1.06s boot, 13 per cent
    # of the path to first paint, and no screen in the app needs either before
    # it draws. #37 asked which statements must leave the boot path; these are
    # the two that leave it without changing any behaviour. That module's
    # moduledoc carries the argument and `Kati.BootPathTest` keeps them off.

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

    trace("priv probe")
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

    # `Kati.Components.register_all/0` is deliberately NOT called here.
    #
    # It costs ~245ms of cold start on the emulator — measured, phase-traced —
    # because it must `Code.ensure_loaded?/1` all 74 vendored components to ask
    # what they export. That is 11% of a 2136ms median launch.
    #
    # And it buys nothing today: every component is used by DIRECT FUNCTION
    # CALL, and zero `<MishkaX />` composite tags appear in any markup. The
    # registry only matters for tag expansion.
    #
    # The hazard in leaving it out is real — an unregistered tag renders as
    # NOTHING rather than raising — so it is a TEST rather than a comment:
    # `Kati.ComponentsTest` fails if markup ever uses a composite tag while
    # boot does not register. Whoever writes the first `<MishkaX />` gets a red
    # suite naming this line, not a blank screen.

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

    # #58's third leg: refresh on open. The Kotlin worker runs while the BEAM
    # is dead and leaves what it found in MOB_DATA_DIR; this is where it is
    # read back. It has to run at start rather than only on
    # `{:mob_device, :did_become_active}`, because a cold launch never sends
    # that message and a cold launch is exactly the case where the inbox is
    # full.
    case Kati.Background.Handoff.drain() do
      [] -> :ok
      runs -> :mob_nif.log("Kati: drained #{length(runs)} background refresh runs")
    end

    # ...and make sure the worker exists. Idempotent by construction — the
    # enqueue is `ExistingPeriodicWorkPolicy.KEEP`, so calling it on every boot
    # does NOT restart the interval clock. `{:error, :no_bridge}` is the normal
    # answer off Android and must not be logged as a fault.
    case Kati.Background.Periodic.ensure() do
      {:ok, %{interval_minutes: minutes}} ->
        :mob_nif.log("Kati: background refresh every #{minutes}m")

      {:error, :no_bridge} ->
        :ok

      {:error, reason} ->
        :mob_nif.log("Kati: background refresh unavailable: #{inspect(reason)}")
    end

    # A save the user cancelled, or a process that died mid-save, leaves a full
    # plaintext copy of everything they own in the staging directory. It should
    # not still be there tomorrow.
    _swept = Kati.Backup.Transport.sweep()

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
  # Worth its lines: when the app died before any screen appeared, the only
  # evidence was `step 5 => {error,{badmatch,...}}` from `src/kati.erl`, which
  # names the failing pattern but not the caller. Several deploys went into
  # guessing which call it was. This answers it in one.
  #
  # ## The timings, which #37 asks for and this file is the only place to take
  #
  # Each marker carries the milliseconds that phase cost and the total since
  # `on_start/0` was entered:
  #
  #     Kati.boot: migrations +412ms (1180ms)
  #
  # A single total says the boot is slow; a per-phase split says which
  # statement to move, which is the whole of what #37 asks. Taken with
  # `:erlang.monotonic_time/1` rather than wall time so an NTP correction
  # mid-boot cannot produce a negative phase.
  #
  # The origin lives in the process dictionary. `on_start/0` runs once, in one
  # process, before any supervision tree exists — there is nowhere else to put
  # it that is not more machinery than the measurement, and a missing origin
  # degrades to the marker without a number rather than raising.
  defp trace_start, do: Process.put(:kati_boot_origin, now_ms())

  defp trace(phase) do
    case Process.get(:kati_boot_origin) do
      nil ->
        IO.puts("Kati.boot: " <> phase)

      origin ->
        now = now_ms()
        last = Process.get(:kati_boot_last, origin)
        Process.put(:kati_boot_last, now)

        IO.puts("Kati.boot: #{phase} +#{now - last}ms (#{now - origin}ms)")
    end
  end

  defp now_ms, do: :erlang.monotonic_time(:millisecond)

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
