defmodule Kati.Meals.Totals do
  @moduledoc """
  The only writer of `Kati.Meals.Recipe`'s cached macro totals.

  ## Why there is a cache at all

  AshSqlite has no resource aggregates, and `can?(:transact)` is `false`
  (`ash_sqlite-0.2.17/lib/data_layer.ex:444-514`). So a recipe's totals cannot be
  a `sum` the data layer computes, and the multi-row write that maintains them
  cannot be wrapped in a transaction that either lands whole or not at all. Both
  facts are schema commitments, not implementation details, which is why #73
  asks for a *stated* consistency rule rather than for code that is careful.

  ## The maintenance rule

  Every change to a recipe's ingredient set goes through `write_ingredient/2`,
  `update_ingredient/2` or `remove_ingredient/1` here, and each is three writes
  in this exact order:

      1. bump   recipe.ingredients_rev      (Recipe's :mark_ingredients_dirty)
      2. write  the ingredient row
      3. store  recipe totals + totals_rev  (Recipe's :store_totals)

  `totals_rev < ingredients_rev` is the definition of stale. `stale?/1` reports
  it, `fresh!/1` heals it, and `Recipe`'s `:with_stale_totals` read finds every
  recipe that needs healing.

  ## The partial-failure rule

  The order above is chosen so that no interruption can leave the cache claiming
  to be fresh when it is not:

    * **Crash between 1 and 2** — the recipe is marked stale but nothing changed.
      A wasted recompute; the figures were already right.
    * **Crash between 2 and 3** — the recipe is marked stale and it is. The next
      `fresh!/1` fixes it, and every path that freezes a figure into history
      calls `fresh!/1` first, so the wrong number cannot reach a
      `Kati.Meals.MealLog`.
    * **Never** — an ingredient changed while `totals_rev == ingredients_rev`.
      That is the only ordering that would corrupt a frozen log, and reversing
      steps 1 and 2 is what would produce it.

  Doing step 1 first costs a redundant recompute after an interrupted write.
  That is the trade: the failure mode is wasted work rather than a wrong number
  in a record that cannot be reconstructed.

  ## Totals are at one portion

  Screen 45: *"Every figure is stored at one portion."* Ingredient lines are
  entered per portion, so the total is their plain sum and `serves` never
  divides anything — it is what the method yields, a fact about the pan.
  """

  require Ash.Query

  alias Kati.Meals.Nutrition
  alias Kati.Meals.Recipe
  alias Kati.Meals.RecipeIngredient

  @doc """
  `true` when an ingredient has changed since the totals were last computed.
  """
  @spec stale?(Recipe.t()) :: boolean()
  def stale?(%Recipe{totals_rev: totals_rev, ingredients_rev: ingredients_rev}) do
    totals_rev < ingredients_rev
  end

  @doc """
  Returns the recipe with totals that are certainly current, recomputing first
  if they are not.

  Every path that freezes a figure into history calls this. A stale cache is a
  recoverable inconvenience right up to the moment it is copied into a
  `Kati.Meals.MealLog`, where it becomes permanent.
  """
  @spec fresh!(Recipe.t()) :: Recipe.t()
  def fresh!(%Recipe{} = recipe) do
    if stale?(recipe), do: recompute!(recipe), else: recipe
  end

  @doc """
  Sums the recipe's ingredient lines and stores the result.

  `totals_rev` is set to the `ingredients_rev` that was read **before** the sum,
  so an ingredient written while this was running leaves the recipe stale rather
  than marking a partial sum as current.
  """
  @spec recompute!(Recipe.t()) :: Recipe.t()
  def recompute!(%Recipe{} = recipe) do
    {:ok, reloaded} = Ash.get(Recipe, recipe.id)
    rev = reloaded.ingredients_rev

    lines =
      RecipeIngredient
      |> Ash.Query.filter(recipe_id == ^recipe.id)
      |> Ash.read!()

    figures = Nutrition.sum(lines)

    attrs =
      figures
      |> Map.new(fn {field, value} -> {:"total_#{field}", value} end)
      |> Map.put(:totals_rev, rev)

    reloaded
    |> Ash.Changeset.for_update(:store_totals, attrs)
    |> Ash.update!()
  end

  @doc """
  Adds one ingredient line, maintaining the cache. Returns `{ingredient, recipe}`.

  Step 1 happens before the line exists — see the moduledoc's partial-failure
  rule; it is the ordering, not the code, that is load-bearing.
  """
  @spec write_ingredient(Recipe.t(), map()) :: {RecipeIngredient.t(), Recipe.t()}
  def write_ingredient(%Recipe{} = recipe, attrs) do
    dirty = mark_dirty!(recipe)

    ingredient =
      RecipeIngredient
      |> Ash.Changeset.for_create(:create, Map.put(attrs, :recipe_id, recipe.id))
      |> Ash.create!()

    {ingredient, recompute!(dirty)}
  end

  @doc "Edits one ingredient line, maintaining the cache."
  @spec update_ingredient(RecipeIngredient.t(), map()) :: {RecipeIngredient.t(), Recipe.t()}
  def update_ingredient(%RecipeIngredient{} = ingredient, attrs) do
    {:ok, recipe} = Ash.get(Recipe, ingredient.recipe_id)
    dirty = mark_dirty!(recipe)

    updated =
      ingredient
      |> Ash.Changeset.for_update(:update, attrs)
      |> Ash.update!()

    {updated, recompute!(dirty)}
  end

  @doc "Removes one ingredient line, maintaining the cache."
  @spec remove_ingredient(RecipeIngredient.t()) :: Recipe.t()
  def remove_ingredient(%RecipeIngredient{} = ingredient) do
    {:ok, recipe} = Ash.get(Recipe, ingredient.recipe_id)
    dirty = mark_dirty!(recipe)
    :ok = Ash.destroy!(ingredient)
    recompute!(dirty)
  end

  @doc """
  Step 1 on its own.

  Public because the partial-failure rule is only testable if the steps can be
  run apart: a test that stops here and asserts `stale?/1` is what proves an
  interrupted write is marked rather than silently forgotten.

  Reloads first. The counter has to advance from what is **in the database**,
  not from whatever the caller is holding — a caller with a struct read before
  two other writes would otherwise set the rev backwards and mark a stale recipe
  fresh, which is the one outcome the ordering exists to prevent.
  """
  @spec mark_dirty!(Recipe.t()) :: Recipe.t()
  def mark_dirty!(%Recipe{id: id}) do
    {:ok, current} = Ash.get(Recipe, id)

    current
    |> Ash.Changeset.for_update(:mark_ingredients_dirty, %{})
    |> Ash.update!()
  end
end
