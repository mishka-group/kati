# Configure through the SAME code path the device uses, so a host test about
# configuration means something. Anything set only in config/config.exs is
# host-only by definition and never reaches a phone.
Kati.Runtime.configure()

# Schema tests run against a real SQLite file in a temp dir — the point is that
# ecto_sqlite3's actual storage behaviour matches what the range queries assume.
tmp = Path.join(System.tmp_dir!(), "kati_test_#{System.unique_integer([:positive])}")
File.mkdir_p!(tmp)
System.put_env("MOB_DATA_DIR", tmp)

{:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
{:ok, _} = Application.ensure_all_started(:ash)
{:ok, _} = Kati.Repo.start_link()

Ecto.Migrator.run(Kati.Repo, Path.join(:code.priv_dir(:kati), "repo/migrations"), :up, all: true)

ExUnit.start()
