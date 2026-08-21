defmodule Kati.Meals.RecipeIngredient do
  @moduledoc """
  One line of screen 45's ingredient list, at one portion.

  ## The line is self-sufficient

  `name`, `amount_mg`, `unit` and the seven figures are stored **on the line**,
  not looked up through the food reference. Screen 45 draws each ingredient's
  own kcal so that *"the total is visibly the sum of its parts"*, and a line that
  had to join three tables to render that number would go blank the moment a
  cached food row was evicted.

  So the food reference is **provenance**, not a dependency: it says where the
  numbers came from and lets a re-lookup refresh them, and nothing breaks when it
  is nil. A hand-typed `White miso · 15 g · 30 kcal` has no reference at all, and
  that is a complete row.

  ## Three references, not one polymorphic column

  `food_id`, `bundled_food_id` and `licensed_food_id`, at most one set. The
  licence split described in `Kati.Meals.BundledFood` is only structural if it is
  visible at the point of reference too — a single `food_id` pointing into a
  merged table is the merge, however many tables it was assembled from. A
  validation enforces the "at most one", so a row that claims two provenances
  fails rather than picking one.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "recipe_ingredients"
    repo Kati.Repo

    references do
      reference :recipe, on_delete: :delete
      # Provenance may vanish; the line may not.
      reference :food, on_delete: :nilify
      reference :bundled_food, on_delete: :nilify
      reference :licensed_food, on_delete: :nilify
    end

    custom_indexes do
      index [:recipe_id, :position], unique: true, message: "already a line at this position"
      # The shopping-list roll-up walks lines by aisle.
      index [:aisle]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :position, :integer, allow_nil?: false, default: 0, public?: true

    attribute :name, :string, allow_nil?: false, public?: true

    # Thousandths of the unit: 150 g is 150_000, 5 ml is 5_000, x2 is 2_000.
    # Integers for the same reason as Kati.Meals.Nutrition — a recipe edited
    # twice must land on the same number it started from.
    attribute :amount_mg, :integer, allow_nil?: false, default: 0, public?: true

    attribute :unit, :atom,
      allow_nil?: false,
      default: :g,
      public?: true,
      constraints: [one_of: [:g, :ml, :piece, :tsp, :tbsp, :pinch, :pack, :tub]]

    # Copied down from the food's `default_aisle` at write time, and editable
    # after: which shelf a thing is on is a fact about a shop, and the user's
    # shop wins over the corpus's guess.
    attribute :aisle, :atom,
      allow_nil?: false,
      default: :other,
      public?: true,
      constraints: [one_of: Kati.Meals.Aisle.values()]

    # ── This line's own figures (see the moduledoc) ────────────────────────
    attribute :kcal, :integer, allow_nil?: false, default: 0, public?: true
    attribute :protein_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :carbs_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fat_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fibre_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sugar_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sodium_mg, :integer, allow_nil?: false, default: 0, public?: true

    # Screen 45's checkbox: ticking a line is what puts it on the shopping list.
    attribute :shop_for, :boolean, allow_nil?: false, default: true, public?: true

    timestamps()
  end

  relationships do
    belongs_to :recipe, Kati.Meals.Recipe,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true

    belongs_to :food, Kati.Meals.Food, attribute_writable?: true, attribute_public?: true

    belongs_to :bundled_food, Kati.Meals.BundledFood,
      attribute_writable?: true,
      attribute_public?: true

    belongs_to :licensed_food, Kati.Meals.LicensedFood,
      attribute_writable?: true,
      attribute_public?: true
  end

  validations do
    validate Kati.Meals.Validations.OneFoodReference
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*
  end
end
