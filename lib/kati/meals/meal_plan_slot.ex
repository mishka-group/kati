defmodule Kati.Meals.MealPlanSlot do
  @moduledoc """
  One cell of screen 44's matrix: a meal slot on a day of the week.

  Five slots across seven days is 35 rows, which is the *"All 35, with photos"*
  screen 50 offers to share and the 35 that screen 47's `30 hit / 5 skipped`
  adds up to. It is one week, not a year: the plan repeats.

  ## `slot_time` is floating

  `07:30` means half past seven **wherever you are**. Storing it as an instant
  makes breakfast arrive at 04:30 the morning after a flight to Tehran, which is
  the failure `Kati.Calendars.Event`'s moduledoc already names — *"`tzid` of nil
  means floating: '09:00 wherever you are', which is the correct model for habits
  and meal slots"*. So the column is a bare `:time` and there is deliberately no
  timezone beside it.

  ## Three states, and the one that is not stored

  `:planned`, `:free` and `:open` are screen 44's three cell states. The
  drawing lists a fourth — `:today`, inked with an accent pip — and it is
  **not** here: today is a fact about the calendar, not about the plan. Storing
  it would mean 35 rows to rewrite at midnight and a plan that is wrong for
  anyone it is shared with.

  A `:planned` cell may still have a nil `recipe_id`. That is the slot existing
  with nothing decided for it yet, which is different from `:free` (the slot
  exists, nothing is meant to be in it) and from `:open` (not part of the plan
  this week).
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "meal_plan_slots"
    repo Kati.Repo

    references do
      reference :meal_plan, on_delete: :delete
      # A deleted recipe empties the slot; it does not delete the slot, and it
      # does not touch a single logged figure — see `Kati.Meals.MealLog`.
      reference :recipe, on_delete: :nilify
    end

    custom_indexes do
      index [:meal_plan_id, :day_of_week, :position],
        unique: true,
        message: "already a slot at this position"

      index [:meal_plan_id, :day_of_week, :slot_time]
    end
  end

  attributes do
    uuid_primary_key :id

    # Monday is 1, matching screen 44's `M T W T F S S` columns and
    # `Date.day_of_week/1`, so nothing has to translate between them.
    attribute :day_of_week, :integer,
      allow_nil?: false,
      public?: true,
      constraints: [min: 1, max: 7]

    # Row order within the day. Two snacks share a name and differ only here.
    attribute :position, :integer, allow_nil?: false, default: 0, public?: true

    attribute :slot_name, :string, allow_nil?: false, public?: true

    # Floating. See the moduledoc.
    attribute :slot_time, :time, public?: true

    attribute :state, :atom,
      allow_nil?: false,
      default: :planned,
      public?: true,
      constraints: [one_of: [:planned, :free, :open]]

    # Thousandths; 1000 is screen 45's `1.0x`.
    attribute :portion_milli, :integer, allow_nil?: false, default: 1000, public?: true

    timestamps()
  end

  relationships do
    belongs_to :meal_plan, Kati.Meals.MealPlan,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true

    belongs_to :recipe, Kati.Meals.Recipe, attribute_writable?: true, attribute_public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :on_day do
      argument :meal_plan_id, :uuid, allow_nil?: false
      argument :day_of_week, :integer, allow_nil?: false

      filter expr(meal_plan_id == ^arg(:meal_plan_id) and day_of_week == ^arg(:day_of_week))

      prepare build(sort: [position: :asc])
    end
  end
end
