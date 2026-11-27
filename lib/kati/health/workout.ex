defmodule Kati.Health.Workout do
  @moduledoc """
  One workout, typed by hand.

  The fourth outline on screen 42's grid, and the same fix as
  `Kati.Health.SleepNight`: a title, how long it took, and the day it happened.
  There is no exercise catalogue and no route — a workout in Kati is a line in
  a week, which is what the tile's *N this week* counts.
  """

  use Ash.Resource, domain: Kati.Health, data_layer: AshSqlite.DataLayer

  sqlite do
    table "workouts"
    repo Kati.Repo

    custom_indexes do
      index [:done_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false, public?: true, constraints: [max_length: 80]
    attribute :minutes, :integer, allow_nil?: false, public?: true, constraints: [min: 1]

    attribute :done_on, :date, allow_nil?: false, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :recent do
      description "Every workout, newest first."
      prepare build(sort: [done_on: :desc, inserted_at: :desc])
    end
  end

  @doc """
  How many workouts this week holds, Monday first.

      iex> Kati.Health.Workout.count_in_week([%{done_on: ~D[2026-11-25]}], ~D[2026-11-23])
      1
  """
  @spec count_in_week([map()], Date.t()) :: non_neg_integer()
  def count_in_week(workouts, monday) do
    sunday = Date.add(monday, 6)

    Enum.count(workouts, &(&1.done_on >= monday and &1.done_on <= sunday))
  end
end
