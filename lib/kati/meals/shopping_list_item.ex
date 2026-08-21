defmodule Kati.Meals.ShoppingListItem do
  @moduledoc """
  One line of screen 48, for one week of one plan.

  Screen 48's whole argument is in its second line: every item names **which
  meals asked for it**, so cutting a meal visibly shrinks the list. `meal_count`
  and `meals_label` carry that — `"7 meals"`, `"4 dinners"`, `"snack x7"` — and
  the label is stored rather than derived because the phrasing varies with what
  the meals have in common, which is a rendering decision the roll-up makes once
  rather than a string every grouping recomputes.

  `got` strikes the line through and greys the amount; it does **not** remove
  the row. The design keeps a struck line in place so the list does not reflow
  under a thumb in a shop.

  ## The estimate (#71's second question)

  `£41.20 est.` had no price source. Open Prices' terms are unknown and thin
  outside a few countries, and supermarket APIs are not openly available — so the
  mechanism taken here is the last of #71's three options: **the user enters a
  price, `Kati.Meals.Food` remembers the last one paid, and the estimate is the
  sum over the items that have one.**

  `price_minor` is a **copy taken when the list was generated**, not a live read
  of the food's remembered price — the same freeze the meal log makes, for the
  same reason. Paying more for salmon in September must not rewrite what August's
  shop is recorded as having cost.

  `price_source` says which kind of number it is, so the screen can mark an
  estimate as an estimate and stay silent when too few items have one. `:none`
  is the resting state and the honest one: no price, no contribution, no
  invented total.

  ## No pantry (#71's first question)

  There is no stock level, no expiry and no depletion-on-log here, and screen
  46's "In my fridge" filter has no table behind it. A pantry is a whole feature
  with its own maintenance burden, and an out-of-date pantry is worse than none —
  so swap ranks on macro distance and on `Kati.Meals.Recipe.minutes`, both of
  which exist. `manual` is the small piece of the same intent that survives:
  a line you added yourself because you know you are out of it.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "shopping_list_items"
    repo Kati.Repo

    references do
      reference :meal_plan, on_delete: :delete
      # The remembered price may be for a food that gets deleted; the line and
      # its frozen price stay.
      reference :food, on_delete: :nilify
    end

    custom_indexes do
      index [:meal_plan_id, :week_starting_on, :aisle]
      index [:meal_plan_id, :week_starting_on, :got]
    end
  end

  attributes do
    uuid_primary_key :id

    # Screen 48's "week of 17 Aug". A Monday, matching `day_of_week` 1.
    attribute :week_starting_on, :date, allow_nil?: false, public?: true

    attribute :name, :string, allow_nil?: false, public?: true

    attribute :aisle, :atom,
      allow_nil?: false,
      default: :other,
      public?: true,
      constraints: [one_of: Kati.Meals.Aisle.values()]

    # Thousandths of the unit, as on a recipe line: 840 g is 840_000.
    attribute :amount_mg, :integer, allow_nil?: false, default: 0, public?: true

    attribute :unit, :atom,
      allow_nil?: false,
      default: :g,
      public?: true,
      constraints: [one_of: [:g, :ml, :piece, :tsp, :tbsp, :pinch, :pack, :tub]]

    # ── Which meals asked for it ───────────────────────────────────────────
    attribute :meal_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :meals_label, :string, public?: true

    attribute :got, :boolean, allow_nil?: false, default: false, public?: true
    attribute :manual, :boolean, allow_nil?: false, default: false, public?: true

    # ── The estimate, frozen at generation ─────────────────────────────────
    attribute :price_minor, :integer, public?: true
    attribute :price_currency, :string, public?: true

    attribute :price_source, :atom,
      allow_nil?: false,
      default: :none,
      public?: true,
      constraints: [one_of: [:none, :remembered, :entered]]

    timestamps()
  end

  relationships do
    belongs_to :meal_plan, Kati.Meals.MealPlan,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true

    belongs_to :food, Kati.Meals.Food, attribute_writable?: true, attribute_public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :for_week do
      argument :meal_plan_id, :uuid, allow_nil?: false
      argument :week_starting_on, :date, allow_nil?: false

      filter expr(
               meal_plan_id == ^arg(:meal_plan_id) and
                 week_starting_on == ^arg(:week_starting_on)
             )

      prepare build(sort: [aisle: :asc, name: :asc])
    end

    update :toggle_got do
      require_atomic? false
      accept [:got]
    end
  end
end
