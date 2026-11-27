defmodule Kati.Repo.Migrations.AddSleepAndWorkouts do
  @moduledoc """
  The two health sections screen 42 drew as outlines: a night's sleep and a
  workout.

  The tables and columns below are the fragment `mix ash_sqlite.generate_migrations
  add_sleep_and_workouts` produced for the two new resources — `primary_key:
  false`, a `:uuid` id, `bigint` minutes, and the two date indexes. The rest of
  that run was not kept: this repo's snapshot baseline is behind its resources
  for forty-five of them, so the generator replayed their whole history, with
  the `raise` statements SQLite's foreign-key limits need. Their snapshots were
  left as they were and only `sleep_nights`/`workouts` were added, so the next
  resource change generates a diff of one resource rather than of all of them.

  Applied before either screen reads anything: on a device the app runs its
  migrations at boot, and a migration deployed without `--native` never reaches
  it — see `AGENTS.md`.
  """

  use Ecto.Migration

  def up do
    create_if_not_exists table(:sleep_nights, primary_key: false) do
      add(:updated_at, :utc_datetime_usec, null: false)
      add(:inserted_at, :utc_datetime_usec, null: false)
      add(:note, :text)
      add(:night_on, :date, null: false)
      add(:minutes, :bigint, null: false)
      add(:id, :uuid, null: false, primary_key: true)
    end

    create_if_not_exists(index(:sleep_nights, ["night_on"]))

    create_if_not_exists table(:workouts, primary_key: false) do
      add(:updated_at, :utc_datetime_usec, null: false)
      add(:inserted_at, :utc_datetime_usec, null: false)
      add(:done_on, :date, null: false)
      add(:minutes, :bigint, null: false)
      add(:title, :text, null: false)
      add(:id, :uuid, null: false, primary_key: true)
    end

    create_if_not_exists(index(:workouts, ["done_on"]))
  end

  def down do
    drop(table(:workouts))
    drop(table(:sleep_nights))
  end
end
