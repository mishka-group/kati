defmodule Kati.Meals do
  @moduledoc """
  Foods, recipes, plans, and the frozen log of what was actually eaten.

  Eleven screens sit on this domain — 43 to 52, plus the Persian mirror at 60.
  Three rules shape the whole of it, and each one is a migration-1 decision
  rather than an implementation detail, because retrofitting any of them means a
  migration over data the user cannot re-enter.

  ## 1. A logged meal is frozen

  `Kati.Meals.MealLog` stores the nutrition figures **of the moment it was
  logged**, not a reference to the recipe. Double the miso in a recipe next week
  and every past Thursday keeps the numbers it had; screen 47's adherence chart
  stays a record rather than becoming a re-derivation. `recipe_id` survives as
  provenance and nilifies if the recipe is deleted, and no read path ever
  recovers a figure through it.

  ## 2. Cached totals, because SQLite cannot aggregate here

  AshSqlite has no resource aggregates and `can?(:transact)` is `false`, so a
  recipe's macro totals are columns the write path maintains. `Kati.Meals.Totals`
  is the only writer, and `totals_rev < ingredients_rev` is the stated
  consistency rule — including what happens when a multi-row write fails partway.
  The full rule is in that module's moduledoc.

  ## 3. The food corpora do not merge

  Three food tables, and the split is structural rather than remembered:

    * `Kati.Meals.Food` — Kati and the user wrote these. No upstream id, no USDA
      columns, so the Persian layer K-41 says Kati has to author is a first-class
      row and not a row with six empty columns. The remembered price lives here
      and only here, because it is the user's own fact.
    * `Kati.Meals.BundledFood` — the CC0 corpus shipped in `priv/`. `licence`
      accepts `:cc0` and nothing else.
    * `Kati.Meals.LicensedFood` — anything under someone else's terms. `licence`
      excludes `:cc0`, and `fetched_at` is not null so the eviction sweep reaches
      it. Empty today; the slot is cut now because adding a third reference to
      `recipe_ingredients` later is a migration over live recipes.

  Merging ODbL data into the CC0 table would relicense the CC0 rows. Neither
  table can absorb the other, and `Kati.Meals.RecipeIngredient` carries all three
  references separately so the boundary is visible where a food is used, not only
  where it is stored.

  ## Meals on the calendar are a projection

  Screen 52 draws meals on the day spine in clock order with everything else.
  Meals **never writes to `events`**. The calendar asks this domain for a day's
  meals and renders them; a plan duplicated into 35 event rows a week would be
  two tables that disagree the first time a slot moved, and there would be no way
  to tell which one the user edited.

  ## Numbers are integers

  kcal whole, every macro in milligrams, portions and amounts in thousandths.
  See `Kati.Meals.Nutrition`. Floats would make "the frozen figure did not move"
  a tolerance check, and a tolerance check is exactly what would hide the bug
  freezing exists to prevent.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Meals.Food
    resource Kati.Meals.BundledFood
    resource Kati.Meals.LicensedFood
    resource Kati.Meals.Recipe
    resource Kati.Meals.RecipeIngredient
    resource Kati.Meals.MealPlan
    resource Kati.Meals.MealPlanSlot
    resource Kati.Meals.MealLog
    resource Kati.Meals.ShoppingListItem
  end
end
