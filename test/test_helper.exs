# Configure through the SAME code path the device uses, so a host test about
# configuration means something. Anything set only in config/config.exs is
# host-only by definition and never reaches a phone.
Kati.Runtime.configure()

# A catalogue add fills its details in a task on a device
# (`Kati.Screens.AddTitle.fill_later/2`). Here it fills before `track/3`
# returns, so a test that adds and then reads the episodes reads them;
# `Kati.AddTitleFillTest` switches it back on to test the background path.
Application.put_env(:kati, :fill_titles_in_background, false)

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

# AniList, TVmaze and the image CDNs are keyless, so nothing stops a screen
# test that never thought about them from reaching the real network: screen
# 19 asks AniList and TVmaze whenever no TMDB token is saved, and adding a
# title downloads its poster. Each of their Req seams starts every test
# answering 503 without a socket; a test about one of them installs its own
# adapter and puts `Kati.TestOffline.options/0` back when it is done.
defmodule Kati.TestOffline do
  @moduledoc false
  @keys [:anilist_req_options, :tvmaze_req_options, :artwork_req_options]

  def run(request), do: {request, Req.Response.new(status: 503, body: "")}

  def options, do: [adapter: __MODULE__, retry: false]

  def restore(key) when key in @keys, do: Application.put_env(:kati, key, options())

  def restore_all, do: Enum.each(@keys, &restore/1)
end

Kati.TestOffline.restore_all()

# `:live` reaches a third-party API over the network with somebody's key.
# Excluded by default, because a test that fails when TMDB is slow, or when
# the machine running it has no key, is a test that reports something other
# than whether the code is right. Run them deliberately:
#
#     set -a; . ~/.config/kati/tmdb.env; set +a
#     mix test --include live
ExUnit.start(exclude: [:live])
