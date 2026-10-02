import Config

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ Read on the host by mix tasks, and on the device since mob 0.9.6.         │
# │                                                                           │
# │ mob_dev ships this file to the phone as `mob_app_config`, and             │
# │ `Mob.App.start/0` applies it before Kati boots. Before that a phone saw   │
# │ none of it. Kati.Runtime still sets every key the app reads at runtime,   │
# │ so nothing here may be the only place a device gets a value from: a      │
# │ build made without mob_dev's module (host tests, an older mob_dev) must   │
# │ boot the same way.                                                        │
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
config :kati,
  ash_domains: [
    Kati.Books,
    Kati.Calendars,
    Kati.Media,
    Kati.Meals,
    Kati.Goals,
    Kati.Health,
    Kati.Lists,
    Kati.Money,
    Kati.Music,
    Kati.Notifications,
    Kati.Services,
    Kati.Sync
  ]

# Read TWICE, which is why it is also in Kati.Runtime: Ash 3.33's
# RequireStringLengthCountConfig transformer refuses to compile any resource
# until it is set, and `Ash.Type.String` reads it again at runtime whenever a
# `max_length`/`min_length` or `string_length` is evaluated — where, on the
# phone, only Kati.Runtime can put it. `:codepoints` is what SQLite's
# `length()` counts, so a constraint checked in Elixir and one checked
# atomically in the database agree.
config :ash, default_string_length_count: :codepoints
