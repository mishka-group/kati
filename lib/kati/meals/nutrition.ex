defmodule Kati.Meals.Nutrition do
  @moduledoc """
  The seven figures every meal carries, and the integer arithmetic over them.

  ## Why integers, in these units

  `kcal` is whole kilocalories; every macro is **milligrams**; sodium already is
  on screen 45 (`840 mg`). Nothing here is a float.

  That is not tidiness. `Kati.Meals.MealLog` freezes these numbers and a test
  asserts they did not move after the recipe was edited — an assertion that is
  only worth making if "did not move" is exact. A float total that arrives back
  from SQLite as `619.9999999999999` would pass a tolerance check and hide the
  bug the freeze exists to prevent. Integers make the assertion `==`.

  Milligrams rather than grams so a portion multiplier stays exact: 1.5x of
  52 g is 78 000 mg with nothing to round.

  ## Portions

  A portion is stored as `portion_milli`, thousandths — `1000` is the `1.0x`
  screen 45 draws, `7000` is the `x7` on screen 48's apples. Scaling is integer
  multiply-then-divide with half-up rounding, so `scale/2` of the same inputs
  is the same answer on every device and in every year.
  """

  @fields [:kcal, :protein_mg, :carbs_mg, :fat_mg, :fibre_mg, :sugar_mg, :sodium_mg]

  @one_portion 1000

  @doc "The seven figure names, in the order screens print them."
  @spec fields() :: [atom()]
  def fields, do: @fields

  @doc "`1000` — the multiplier that means one portion."
  @spec one_portion() :: pos_integer()
  def one_portion, do: @one_portion

  @doc "All seven at zero, as a plain map."
  @spec zero() :: %{atom() => non_neg_integer()}
  def zero, do: Map.new(@fields, &{&1, 0})

  @doc """
  Reads the seven figures off any struct or map that carries them.

  Missing or nil figures read as zero: a Persian food nobody has entered
  sodium for contributes no sodium, which is the honest sum. Marking the total
  itself unknown would make every recipe containing one unusable.
  """
  @spec take(map()) :: %{atom() => non_neg_integer()}
  def take(source) do
    Map.new(@fields, fn field -> {field, Map.get(source, field) || 0} end)
  end

  @doc "Adds two figure maps field by field."
  @spec add(map(), map()) :: %{atom() => non_neg_integer()}
  def add(left, right) do
    Map.new(@fields, fn field -> {field, Map.get(left, field, 0) + Map.get(right, field, 0)} end)
  end

  @doc "Sums a list of anything `take/1` accepts."
  @spec sum(Enumerable.t()) :: %{atom() => non_neg_integer()}
  def sum(sources) do
    Enum.reduce(sources, zero(), fn source, acc -> add(acc, take(source)) end)
  end

  @doc """
  Rescales every figure by a `portion_milli` multiplier.

  Half-up rather than banker's rounding, because the figure a user is shown and
  the figure that is frozen have to be the same one, and half-up is what a
  reader doing the sum on paper would get.
  """
  @spec scale(map(), pos_integer()) :: %{atom() => non_neg_integer()}
  def scale(figures, @one_portion), do: take(figures)

  def scale(figures, portion_milli) when is_integer(portion_milli) and portion_milli >= 0 do
    figures
    |> take()
    |> Map.new(fn {field, value} ->
      {field, div(value * portion_milli + div(@one_portion, 2), @one_portion)}
    end)
  end

  @doc """
  Rescales a per-100 g reference row to a real amount in milligrams.

  `bundled_foods` and `licensed_foods` are per-100 g corpora, so an ingredient
  line of `150 g` salmon is `take_per_100g(food)` at `150 000 mg`.
  """
  @spec for_amount(map(), non_neg_integer()) :: %{atom() => non_neg_integer()}
  def for_amount(per_100g_figures, amount_mg) when is_integer(amount_mg) and amount_mg >= 0 do
    # 100 g is 100 000 mg, and portion_milli is thousandths — so an amount of
    # 150 000 mg is 1.5 reference portions, i.e. 1500 milli.
    scale(per_100g_figures, div(amount_mg, 100))
  end
end
