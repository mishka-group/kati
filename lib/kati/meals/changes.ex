defmodule Kati.Meals.Changes.FreezeNutrition do
  @moduledoc """
  Takes the snapshot a `Kati.Meals.MealLog` is made of.

  Reads the recipe **once**, at this instant, scales it by the portion, and
  force-writes every snapshot column. Nothing later reads the recipe to render
  this log, which is the whole point: editing the recipe next week must not
  move last week's figures.

  Two details that are not decoration:

    * It calls `Kati.Meals.Totals.fresh!/1` first. Freezing a cached total that
      is stale — `totals_rev < ingredients_rev`, i.e. an ingredient changed and
      the recompute has not landed — would freeze a wrong number permanently,
      which is worse than any of the transient staleness the cache is allowed.
    * It records `recipe_rev`, the recipe's `ingredients_rev` at the freeze.
      That is what makes "this log predates that edit" a checkable fact rather
      than an assertion in a moduledoc.
  """
  use Ash.Resource.Change

  alias Kati.Meals.Nutrition
  alias Kati.Meals.Recipe
  alias Kati.Meals.Totals

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &freeze/1)
  end

  defp freeze(changeset) do
    recipe_id = Ash.Changeset.get_argument(changeset, :recipe_id)
    portion = Ash.Changeset.get_argument(changeset, :portion_milli) || Nutrition.one_portion()

    case Ash.get(Recipe, recipe_id) do
      {:ok, recipe} ->
        apply_snapshot(changeset, Totals.fresh!(recipe), portion)

      {:error, error} ->
        Ash.Changeset.add_error(changeset,
          field: :recipe_id,
          message: "cannot log a recipe that does not exist (#{Exception.message(error)})"
        )
    end
  end

  defp apply_snapshot(changeset, recipe, portion) do
    figures =
      recipe
      |> totals_as_figures()
      |> Nutrition.scale(portion)

    changeset
    |> force(:title, recipe.title)
    |> force(:portion_milli, portion)
    |> force(:recipe_id, recipe.id)
    |> force(:recipe_rev, recipe.ingredients_rev)
    |> force(:frozen_at, DateTime.utc_now())
    |> then(fn cs ->
      Enum.reduce(Nutrition.fields(), cs, fn field, acc ->
        force(acc, field, Map.fetch!(figures, field))
      end)
    end)
  end

  # The recipe stores its cached totals under `total_*`; a log stores figures
  # under the bare names. One rename, in one place.
  defp totals_as_figures(recipe) do
    Map.new(Nutrition.fields(), fn field ->
      {field, Map.get(recipe, :"total_#{field}") || 0}
    end)
  end

  defp force(changeset, field, value) do
    Ash.Changeset.force_change_attribute(changeset, field, value)
  end
end

defmodule Kati.Meals.Changes.RejectSnapshotChange do
  @moduledoc """
  Fails any update that would move a frozen figure.

  `Kati.Meals.MealLog`'s update actions already leave every snapshot column out
  of their `accept` lists, so this is the second lock rather than the first. It
  exists because the first one is a list that a later refactor can widen with no
  test failing — `accept :*` is one keystroke — and because
  `force_change_attribute/3` bypasses `accept` entirely.

  A log is amended by destroying it and logging again. That is not a limitation:
  a corrected snapshot is a new claim about the past, and it should carry its own
  `frozen_at`.

  It runs in `before_action/2` rather than inline. `Ash.Changeset.for_update/3`
  applies an action's changes as the changeset is built, so an inline check reads
  the changeset **before** the caller's own pipeline has run — and a
  `force_change_attribute/3` appended after `for_update/3` is exactly the write
  this exists to stop. Checked inline, it let a forced `kcal` through and the
  test that caught it was measuring nothing.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &reject_moved_figures/1)
  end

  defp reject_moved_figures(changeset) do
    frozen = Kati.Meals.MealLog.snapshot_fields()

    changeset.attributes
    |> Map.keys()
    |> Enum.filter(&(&1 in frozen))
    |> case do
      [] ->
        changeset

      moved ->
        Ash.Changeset.add_error(changeset,
          field: hd(moved),
          message:
            "a logged meal's figures are frozen; #{inspect(moved)} cannot be changed. " <>
              "Destroy the log and log it again."
        )
    end
  end
end

defmodule Kati.Meals.Changes.BumpIngredientsRev do
  @moduledoc """
  Increments a recipe's `ingredients_rev`.

  Step one of the three-step ingredient write. `totals_rev < ingredients_rev`
  is what "the cached macro totals are stale" means, and this is the write that
  makes it true — deliberately **before** the ingredient row is touched, so a
  crash in the middle leaves the cache marked stale rather than marked fresh.

  A counter, not a boolean, for the reason `Kati.Calendars.Event` gives for
  `local_rev`: a second edit landing while a recompute is in flight would clear
  a flag that is still owed, and the recipe would report totals for a version of
  itself that no longer exists.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    current = Map.get(changeset.data, :ingredients_rev) || 0
    Ash.Changeset.force_change_attribute(changeset, :ingredients_rev, current + 1)
  end
end

defmodule Kati.Meals.Changes.RecordUse do
  @moduledoc """
  Records a plan being switched to: the day, the count, and the schedule it
  consumed.

  `Kati.Time.today/0` rather than `Date.utc_today/0`: for the first two hours of
  every Amsterdam day a UTC-derived date names yesterday, which would put screen
  49's "used Mar-Jun" line a day out for anyone who switches plans in the
  evening.

  `activates_on` is cleared because it is a **scheduled** switch — screen 49's
  "Switch takes effect · Next Monday". A date that survives the switch it asked
  for would fire again on the next read.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    used = Map.get(changeset.data, :use_count) || 0

    changeset
    |> Ash.Changeset.force_change_attribute(:last_used_on, Kati.Time.today())
    |> Ash.Changeset.force_change_attribute(:use_count, used + 1)
    |> Ash.Changeset.force_change_attribute(:activates_on, nil)
  end
end
