defmodule Kati.Meals.LicensedFood do
  @moduledoc """
  Food rows under somebody else's licence. **Evictable, and never CC0.**

  This table is empty today and exists anyway, because it is the half of the
  licence split that is expensive to retrofit. `Kati.Meals.RecipeIngredient`
  references a food by one of three columns; adding the third column later means
  a migration over live recipes, and the pressure at that moment would be to
  skip it and put the ODbL rows in `bundled_foods` "just for now".

  So the slot is cut in migration 1. If Open Food Facts ships, it lands here:
  its own table, its own `licence` value, unmerged with the CC0 corpus, exactly
  as #73 requires.

  `licence` excludes `:cc0` on purpose. CC0 rows go to `Kati.Meals.BundledFood`,
  and the two constraints together mean neither table can absorb the other.

  ## `fetched_at` is not null

  These are cached third-party facts, so K-30's eviction rule applies verbatim:
  a row with no age cannot be swept, and an un-sweepable cache is a cache that
  silently outlives its licence terms. `Kati.Meals.RecipeIngredient` copies the
  name and the figures onto the line at write time for exactly this reason — a
  sweep costs a re-fetch, never a recipe.

  Figures are **per 100 g**, as in `Kati.Meals.BundledFood`.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "licensed_foods"
    repo Kati.Repo

    custom_indexes do
      index [:source, :source_id], unique: true, message: "already cached from this source"
      # The eviction sweep.
      index [:source, :fetched_at]
      index [:name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :licence, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:odbl, :cc_by, :cc_by_sa, :proprietary]]

    attribute :source, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:open_food_facts, :open_prices]]

    attribute :source_id, :string, allow_nil?: false, public?: true
    attribute :attribution, :string, public?: true

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :brand, :string, public?: true
    attribute :barcode, :string, public?: true

    attribute :default_aisle, :atom,
      allow_nil?: false,
      default: :other,
      public?: true,
      constraints: [one_of: Kati.Meals.Aisle.values()]

    attribute :kcal, :integer, allow_nil?: false, default: 0, public?: true
    attribute :protein_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :carbs_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fat_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fibre_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sugar_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sodium_mg, :integer, allow_nil?: false, default: 0, public?: true

    # Not null: a row with no age cannot be evicted.
    attribute :fetched_at, :utc_datetime_usec, allow_nil?: false, public?: true
    attribute :last_checked_at, :utc_datetime_usec, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :evictable do
      argument :before, :utc_datetime_usec, allow_nil?: false
      filter expr(fetched_at < ^arg(:before))
    end
  end
end
