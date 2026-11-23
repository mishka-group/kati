defmodule Kati.Habits.Habit do
  @moduledoc """
  One habit: a name, and whether it is still kept.

  ## No streak column

  Screen 22 prints a streak on every card and a best in its header, and none of
  it is stored. A streak is a count over `Kati.Habits.Tick`, computed by
  `Kati.Habits.streak/3` and `Kati.Habits.best/2` — the moduledoc of
  `Kati.Habits` has the argument. A column would be a second copy of the same
  fact, and the day it missed a tick is the day the card printed a run that had
  already broken.

  ## Archiving is a date, not a delete

  `archived_at` is nil for a habit on the screen. Nothing sets it yet: the
  screen offers no archive control and inventing a state nothing can enter is
  how a screen grows a branch no one has seen. It is here because deleting a
  habit destroys its history with it, and a habit someone stopped is a fact
  the statistics should keep.
  """

  use Ash.Resource, domain: Kati.Habits, data_layer: AshSqlite.DataLayer

  sqlite do
    table "habits"
    repo Kati.Repo

    custom_indexes do
      # The active list is the only read the screen makes.
      index [:archived_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true, constraints: [max_length: 80]

    attribute :archived_at, :utc_datetime_usec, public?: true

    timestamps()
  end

  relationships do
    has_many :ticks, Kati.Habits.Tick do
      description "Every day this habit was kept, oldest or newest first by the reader's own sort."
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :active do
      description "Habits still kept, newest first — the order screen 22 stacks them."
      filter expr(is_nil(archived_at))
      prepare build(sort: [inserted_at: :desc, id: :desc])
    end
  end

  @type t :: %__MODULE__{}
end
