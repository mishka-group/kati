# Configure through the SAME code path the device uses, so a host test about
# configuration means something. Anything set only in config/config.exs is
# host-only by definition and never reaches a phone.
Kati.Runtime.configure()

# Schema tests run against a real SQLite file in a temp dir — the point is that
# ecto_sqlite3's actual storage behaviour matches what the range queries assume.
#
# The name must be unique ACROSS RUNS, not only within one. `System.unique_integer/1`
# is unique per VM and restarts from small values in the next one — measured: five
# consecutive `mix run` starts produced 1189, 37, 4610, 40, 34 — so two `mix test`
# runs land on the same directory often, and `File.mkdir_p!/1` on an existing
# directory is a silent success. The second run then migrates a database that
# already holds the first run's rows, and the failures that follow are the ones
# the shared file makes possible: a duplicate `{source, source_id}` in
# `Kati.Media.TrackingTest` (the source ids are built from the same restarting
# counter), twice the meal logs on a day `Kati.MealsTest` counts, and yesterday's
# seeded events still sitting on the day the screen tests mount. All of it looks
# like a race and none of it is. The OS pid is what makes the name unique across
# runs; the counter keeps it unique within one.
tmp =
  Path.join(
    System.tmp_dir!(),
    "kati_test_#{System.pid()}_#{System.unique_integer([:positive])}"
  )

File.mkdir_p!(tmp)
System.put_env("MOB_DATA_DIR", tmp)

# And take it away again, so the directory a future run might collide with does
# not exist. Pids are recycled; a suite that leaves 139 databases behind in
# tmp_dir is what made the collision above likely rather than theoretical.
ExUnit.after_suite(fn _results -> File.rm_rf(tmp) end)

{:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
{:ok, _} = Application.ensure_all_started(:ash)
{:ok, _} = Kati.Repo.start_link()

Ecto.Migrator.run(Kati.Repo, Path.join(:code.priv_dir(:kati), "repo/migrations"), :up, all: true)

# A suite is not an app launch. `Kati.Screens.Root` redirects the first root it
# mounts after a launch into the first-run sequence; latching this closed keeps
# that out of every test that is not about it. `Kati.FirstRunTest` re-arms it.
:persistent_term.put({Kati.Screens.Root, :launched}, true)

ExUnit.start()
