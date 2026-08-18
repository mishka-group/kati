import Config

# Register the Repo so Mix tasks (mix ecto.create, mix ecto.migrate) can
# discover it. The actual database path is configured at runtime in
# Kati.Repo.init/2 via the MOB_DATA_DIR environment variable.
config :kati, ecto_repos: [Kati.Repo]

# Wire the Repo into Mob.ScreenState so screens using `vsn:` get automatic
# state persistence. Remove this line to disable screen state persistence.
config :mob, :repo, Kati.Repo

# Host-side only. The device never reads config/*.exs — it boots `start_clean`
# with no -config and an empty .app env — so Kati.App.on_start/0 sets the
# runtime equivalents with Application.put_env/3. These entries exist so mix
# tasks (ash_sqlite.generate_migrations, ecto.migrate) can find the domains.
config :kati, ash_domains: [Kati.Spike]
config :ash, :disable_async?, true
