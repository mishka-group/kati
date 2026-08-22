defmodule Kati.MixProject do
  use Mix.Project

  def project do
    [
      app: :kati,
      version: "0.1.2",
      elixir: "~> 1.19",
      start_permanent: false,
      deps: deps(),
      aliases: aliases(),
      erlc_paths: ["src"],
      erlc_options: [:debug_info],
      # `mix test` walks test/ with `:test_pattern` and warns about every file
      # that is neither loaded as a test nor explicitly ignored — its guess at
      # a misnamed `foo_tests.exs`. test/support/screen_sweep.exs is neither:
      # it is a plain module the two screen sweeps pull in with
      # `Code.require_file/2`. Ignoring the folder is the answer Mix documents
      # for exactly this; an `elixirc_paths` override for :test would be the
      # other one, and it would compile support/ into the app for every mix
      # task rather than only for the tests that ask for it.
      test_ignore_filters: [&String.starts_with?(&1, "test/support/")]
    ]
  end

  def application do
    # `:xmerl` is for `Kati.Sync.CalDAV.XML`, which reads WebDAV multistatus
    # replies. It has to be declared rather than merely present: without it the
    # `Record.extract(from_lib: "xmerl/include/xmerl.hrl")` in that module
    # cannot find the header under MIX_ENV=test, and — the part that would have
    # been discovered on a phone rather than here — the app's release would not
    # carry the application, so every CalDAV pull would die on the device with
    # an undefined module.
    [extra_applications: [:logger, :xmerl]]
  end

  defp deps do
    [
      # Mob is pre-1.0 with a fast release cadence, no `mix mob.upgrade`, and a
      # native shell that is forked at generation time — so every bump has to be
      # a deliberate act with a bridge diff, not a silent `~>` drift.
      {:mob, "== 0.7.20"},
      {:mob_dev, "== 0.6.23", only: :dev, runtime: false},
      {:ecto_sqlite3, "~> 0.24"},
      # Ash is the data layer for the whole system. Pinned exactly: Kati appears
      # to be the first public user of AshSqlite on a device BEAM, so a silent
      # minor bump is not something to discover on a user's phone.
      {:ash, "== 3.31.3"},
      {:ash_sqlite, "== 0.2.17"},
      # Timezone database. `tz` compiles IANA data into modules at BUILD time;
      # `tzdata` downloads at runtime into a writable directory, which a
      # device-first app with no server must refuse. The periodic updaters are
      # opt-in child specs Kati simply never adds.
      {:tz, "~> 0.28"},
      {:jason, "~> 1.4"},
      # Localization. `ex_cldr` over Localize 1.0: all three of Localize's
      # runtime-data assumptions are false on Mob (Application.app_dir raises,
      # its supervisor never boots, config/*.exs never reaches the device).
      {:ex_cldr, "~> 2.47"},
      {:ex_cldr_numbers, "~> 2.38"},
      {:ex_cldr_dates_times, "~> 2.25"},
      {:ex_cldr_calendars, "~> 2.4"},
      {:ex_cldr_messages, "~> 2.0"},
      {:gettext, "~> 1.0"},
      # Dev only: used once by `mix kati.gen.nowruz` to generate the lookup
      # table. Its runtime conversion is 476us, which is 7.9ms for a month grid
      # before formatting; the generated table is 1.26us.
      {:ex_cldr_calendars_persian, "~> 1.1", only: :dev, runtime: false},
      # Mozilla's CA trust store. Android has no bundle at any path OTP knows,
      # so this is copied into priv/ and loaded at boot — see Kati.App.
      {:castore, "~> 1.0"},
      # The HTTP client for `Kati.Sync.CalDAV.Req`, and Kati's first outbound
      # call of any kind. It was already here transitively — igniter depends on
      # it — but a transitive dependency is not a promise: a dev-only tool
      # dropping it would take Kati's only transport with it, and the failure
      # would be a compile error on a phone build rather than here.
      #
      # `Kati.App.on_start/0` was already prepared for it: it loads the cacert
      # bundle and switches BEAM's DNS off the iOS-broken `:native` path, both
      # commented for "Req / Finch / Mint". This is what those lines were for.
      {:req, "~> 0.7"},
      # Code quality — Credo + ex_slop (catches AI-generated patterns
      # like blanket rescue, narrator docs, redundant Enum chains, etc).
      # Mishka Chelekom is a DEV-ONLY CLI that generates component source into
      # lib/kati/components/. It is not a runtime dependency and never ships.
      #
      # A `path:` dep, not hex or git: priv/mob is excluded from the hex package
      # so a hex dep cannot generate Mob components at all, and mishka's own
      # mix.exs carries `path:` deps on ../igniter_js and ../igniter_css, so a
      # `github:` dep cannot resolve either. The owner maintains the library, so
      # a sibling checkout is the intended workflow rather than a workaround.
      {:mishka_chelekom, path: "../mishka_chelekom", only: :dev, runtime: false},
      # Only so igniter_js/igniter_css can build their NIFs from source, which
      # mishka_chelekom requires and which have no published precompiled
      # artifacts for the version it pins. Dev-only; never reaches the device.
      {:rustler, ">= 0.0.0", only: :dev},
      # Direct path deps ONLY so rustler is visible in the same tree when these
      # force-build their NIFs. They are transitive deps of mishka_chelekom,
      # which declares rustler dev-only — and a dependency's dev deps are not
      # installed for the consumer, so igniter_js could not see it.
      {:igniter_js, path: "../igniter_js", only: :dev, override: true},
      {:igniter_css, path: "../igniter_css", only: :dev, override: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      # Refresh priv/cacerts.pem from castore on every compile. Copying once by
      # hand would pin Kati to whatever Mozilla trusted on the day it was
      # copied, and the staleness would be invisible until a certificate
      # rotation broke TLS on users' phones.
      compile: ["kati.certs", "compile"],
      "kati.certs": &sync_cacerts/1
    ]
  end

  defp sync_cacerts(_args) do
    Mix.Task.run("loadpaths")
    source = CAStore.file_path()
    dest = Path.join(__DIR__, "priv/cacerts.pem")

    if not File.exists?(dest) or File.read!(source) != File.read!(dest) do
      File.mkdir_p!(Path.dirname(dest))
      File.cp!(source, dest)
      Mix.shell().info([:green, "* synced ", :reset, "priv/cacerts.pem from castore"])
    end
  end
end
