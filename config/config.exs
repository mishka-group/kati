import Config

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ HOST ONLY. The device never reads this file.                              │
# │                                                                           │
# │ A Mob app boots `start_clean` with no -config in argv and an empty .app    │
# │ env, so every line here is invisible on a phone. Verified on device:      │
# │ Application.get_env(:kati, :ecto_repos) returns [Kati.Repo] on the host    │
# │ and nil on the device.                                                    │
# │                                                                           │
# │ What belongs HERE:  keys read by mix tasks, and Application.compile_env   │
# │                     keys, which are baked in at compile time.             │
# │ What belongs in Kati.Runtime: every key read via Application.get_env/2    │
# │                     at runtime.                                           │
# └───────────────────────────────────────────────────────────────────────────┘

# Register the Repo so Mix tasks (mix ecto.create, mix ecto.migrate) can
# discover it. The actual database path is configured at runtime in
# Kati.Repo.init/2 via the MOB_DATA_DIR environment variable.
config :kati, ecto_repos: [Kati.Repo]

# Host-side only. The device never reads config/*.exs — it boots `start_clean`
# with no -config and an empty .app env — so Kati.App.on_start/0 sets the
# runtime equivalents with Application.put_env/3. These entries exist so mix
# tasks (ash_sqlite.generate_migrations, ecto.migrate) can find the domains.
config :kati, ash_domains: [Kati.Spike, Kati.Calendars, Kati.Media, Kati.Meals]
