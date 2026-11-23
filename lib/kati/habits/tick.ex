defmodule Kati.Habits.Tick do
  @moduledoc """
  One habit, kept on one calendar day.

  A row is the whole claim — there is no count, no duration and no note. A day
  is either kept or it is not, which is what the drawing's square says and what
  `Kati.Habits.streak/3` counts.

  ## One row per day, enforced by the database

  The unique index on `[habit_id, ticked_on]` is the rule, not a check in a screen: two
  taps that race create one row and the second create is refused. `toggle/2`
  reads that refusal as "already kept", because the tick the second tap wanted
  is the tick the first one wrote.

  ## `ticked_on` is a date

  The day the reader was living in, through `Kati.Time.today/0`. An instant
  would move a tick into yesterday for the first two hours of every Amsterdam
  day — the same split `Kati.Calendars.Event` makes between `dtstart_date` and
  `dtstart_utc`.
  """

  use Ash.Resource, domain: Kati.Habits, data_layer: AshSqlite.DataLayer

  sqlite do
    table "habit_ticks"
    repo Kati.Repo

    references do
      reference :habit, on_delete: :delete
    end

    custom_indexes do
      index [:habit_id, :ticked_on],
        unique: true,
        message: "this habit is already ticked for that day"

      # The field reads a date range across every habit.
      index [:ticked_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :ticked_on, :date, allow_nil?: false, public?: true

    timestamps()
  end

  relationships do
    belongs_to :habit, Kati.Habits.Habit do
      allow_nil? false
      attribute_writable? true
      attribute_public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  @type t :: %__MODULE__{}
end
