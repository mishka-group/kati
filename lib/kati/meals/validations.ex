defmodule Kati.Meals.Validations.OneFoodReference do
  @moduledoc """
  A recipe line may cite at most one food corpus.

  `Kati.Meals.RecipeIngredient` carries three nullable references — `food_id`
  into the rows Kati and the user wrote, `bundled_food_id` into the CC0 corpus,
  `licensed_food_id` into anything under someone else's terms. Two set at once is
  a line that claims two provenances, and the whole reason the corpora are
  separate tables is that their licences do not mix.

  **Zero** is valid and common: a hand-typed `White miso · 15 g · 30 kcal` cites
  nothing, and it is a complete line. The reference is provenance, never a
  dependency.
  """
  use Ash.Resource.Validation

  @refs [:food_id, :bundled_food_id, :licensed_food_id]

  @impl true
  def validate(changeset, _opts, _context) do
    set =
      Enum.filter(@refs, fn field ->
        not is_nil(Ash.Changeset.get_attribute(changeset, field))
      end)

    case set do
      [] ->
        :ok

      [_one] ->
        :ok

      many ->
        {:error,
         Ash.Error.Changes.InvalidAttribute.exception(
           field: hd(many),
           message:
             "an ingredient cites at most one food corpus, and #{inspect(many)} were set. " <>
               "The corpora are separate tables because their licences do not mix."
         )}
    end
  end
end
