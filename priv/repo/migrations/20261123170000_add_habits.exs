defmodule Kati.Repo.Migrations.AddHabits do
  @moduledoc """
  Habits and the days they were kept.

  Hand-written in the shape `mix ash_sqlite.generate_migrations` produces, and
  applied before the Habits screen reads anything: on a device the app runs its
  migrations at boot, and a migration deployed without `--native` never reaches
  it — see `AGENTS.md`.
  """

  use Ecto.Migration

  def up do
    create table(:habits, primary_key: false) do
      add(:updated_at, :utc_datetime_usec, null: false)
      add(:inserted_at, :utc_datetime_usec, null: false)
      add(:archived_at, :utc_datetime_usec)
      add(:name, :text, null: false)
      add(:id, :uuid, null: false, primary_key: true)
    end

    create index(:habits, ["archived_at"])

    create table(:habit_ticks, primary_key: false) do
      add(
        :habit_id,
        references(:habits,
          column: :id,
          name: "habit_ticks_habit_id_fkey",
          type: :uuid,
          on_delete: :delete_all
        ),
        null: false
      )

      add(:updated_at, :utc_datetime_usec, null: false)
      add(:inserted_at, :utc_datetime_usec, null: false)
      add(:ticked_on, :date, null: false)
      add(:id, :uuid, null: false, primary_key: true)
    end

    create index(:habit_ticks, ["ticked_on"])

    create unique_index(:habit_ticks, ["habit_id", "ticked_on"],
             name: "habit_ticks_habit_id_on_index"
           )
  end

  def down do
    drop_if_exists(
      unique_index(:habit_ticks, ["habit_id", "ticked_on"], name: "habit_ticks_habit_id_on_index")
    )

    drop_if_exists(index(:habit_ticks, ["ticked_on"], name: "habit_ticks_ticked_on_index"))

    drop(table(:habit_ticks))

    drop_if_exists(index(:habits, ["archived_at"], name: "habits_archived_at_index"))

    drop(table(:habits))
  end
end
