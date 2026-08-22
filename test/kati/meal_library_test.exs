defmodule Kati.MealLibraryTest do
  @moduledoc """
  The meal library — screens 116, 118 and 119.

  ## The one idea all three share

  A total built from partial ingredient data is marked `APPROX` **everywhere it
  appears**, and screen 118 gives the reason in a sentence worth keeping: a
  total built from partial data that pretends to be exact makes every number
  downstream a lie. So `approximate?/1` is asserted directly, and so is the em
  dash that stands where a macro figure is unknown — a meal with no sodium
  figure has not got zero sodium.

  ## The other

  A missing aisle becomes `Uncategorised`, never nothing, because a dropped
  ingredient vanishes from the shopping list.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Meals.Recipe
  alias Kati.Meals.RecipeIngredient
  alias Kati.Screens.AddIngredient
  alias Kati.Screens.MealEdit
  alias Kati.Screens.MealLibrary

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM recipe_ingredients", [])
      Kati.Repo.query!("DELETE FROM recipes", [])
    end)

    :ok
  end

  defp a_recipe!(attrs \\ %{}) do
    Ash.create!(
      Recipe,
      Map.merge(
        %{title: "Leftover dal", serves: 2, slot_name: "Dinner"},
        attrs
      )
    )
  end

  # `position` is unique per recipe, so it is counted rather than defaulted —
  # two lines at position 0 is the same line twice.
  defp an_ingredient!(recipe, attrs) do
    position =
      RecipeIngredient
      |> Ash.read!()
      |> Enum.count(&(&1.recipe_id == recipe.id))

    Ash.create!(
      RecipeIngredient,
      Map.merge(
        %{recipe_id: recipe.id, name: "Red lentils", aisle: :cupboard, position: position},
        attrs
      )
    )
  end

  describe "approximate" do
    test "a recipe with an unpriced ingredient is approximate" do
      recipe = a_recipe!()
      an_ingredient!(recipe, %{name: "Red lentils", amount_mg: 180_000, kcal: 620})
      an_ingredient!(recipe, %{name: "Spinach", amount_mg: 50_000, kcal: 0})

      assert MealLibrary.approximate?(Ash.get!(Recipe, recipe.id))
    end

    test "a recipe whose ingredients all carry figures is not" do
      recipe = a_recipe!()
      an_ingredient!(recipe, %{name: "Red lentils", amount_mg: 180_000, kcal: 620})

      refute MealLibrary.approximate?(Ash.get!(Recipe, recipe.id))
    end

    test "a recipe with no ingredients at all is not approximate — it is empty" do
      # Its total of zero is exactly right, which is a different thing from a
      # total that is partly unknown.
      refute MealLibrary.approximate?(a_recipe!())
    end

    test "the tilde travels into the tile's calorie figure" do
      recipe = a_recipe!()
      an_ingredient!(recipe, %{name: "Spinach", amount_mg: 50_000, kcal: 0})

      assert [%{kcal: "~0 kcal", approximate?: true}] = MealLibrary.meals()
    end
  end

  describe "screen 116" do
    test "the grid reads the library and the subtitle counts the photos it lacks" do
      a_recipe!(%{title: "Miso salmon", photo_seed: "meal-miso"})
      a_recipe!(%{title: "Leftover dal", photo_seed: nil})

      assert MealLibrary.subtitle(MealLibrary.meals()) == "2 MEALS · 1 WITHOUT A PHOTO"
    end

    test "the chip counts are the library's, not the filtered grid's" do
      # A filter count is the number of things the chip would show you, not the
      # number it is showing.
      a_recipe!(%{title: "A", slot_name: "Breakfast"})
      a_recipe!(%{title: "B", slot_name: "Dinner"})
      a_recipe!(%{title: "C", slot_name: "Dinner"})

      counts = Map.new(MealLibrary.chip_counts())

      assert counts["All"] == "3"
      assert counts["Dinner"] == "2"
      assert counts["Lunch"] == "0"
    end

    test "the filter narrows the grid" do
      a_recipe!(%{title: "A", slot_name: "Breakfast"})
      a_recipe!(%{title: "B", slot_name: "Dinner"})

      view = mount_screen(MealLibrary)
      filtered = render_info(view, {:tap, :filter_Dinner})

      assert assigns(filtered).filter == "Dinner"
      tree = tree(filtered)
      assert find(tree, :text, text: "B") != nil
      assert find(tree, :text, text: "A") == nil
    end

    test "a meal with no photo still gets a full-size tile" do
      # The grid's whole argument: the no-photo tile is the same size, so the
      # grid never goes ragged.
      a_recipe!(%{title: "Leftover dal", photo_seed: nil})

      tree = tree(mount_screen(MealLibrary))

      assert find(tree, :text, text: "Meal photo") != nil
    end

    test "with nothing stored the drawing renders, whole" do
      assert MealLibrary.meals() == MealLibrary.drawn_meals()
    end
  end

  describe "screen 118" do
    test "an unknown macro prints an em dash, never a zero" do
      # The totals are written by `Kati.Meals.Totals` through `:store_totals`,
      # never by an ordinary create — the create action deliberately does not
      # accept them, so a title edit cannot rewrite a macro figure.
      recipe =
        a_recipe!()
        |> Ash.Changeset.for_update(:store_totals, %{
          total_kcal: 380,
          total_protein_mg: 18_000,
          total_carbs_mg: 52_000,
          total_fat_mg: 11_000,
          total_fibre_mg: 9_000,
          total_sugar_mg: 0,
          total_sodium_mg: 0,
          totals_rev: 0
        })
        |> Ash.update!()

      macros = Map.new(MealEdit.macros())

      assert macros["Protein"] == "18 g"
      # A meal with no sodium figure has not got zero sodium.
      assert macros["Sodium"] == "—"
      assert recipe.total_sodium_mg == 0
    end

    test "the three ingredient states are decided by what the row holds" do
      assert MealEdit.ingredient_state(%{kcal: 620, amount_mg: 180_000}) == :known
      assert MealEdit.ingredient_state(%{kcal: 0, amount_mg: 50_000}) == :quantity_only
      assert MealEdit.ingredient_state(%{kcal: 0, amount_mg: 0}) == :free_text
    end

    test "the ingredients eyebrow counts what is actually there" do
      recipe = a_recipe!()
      an_ingredient!(recipe, %{name: "Red lentils", amount_mg: 180_000, kcal: 620})
      an_ingredient!(recipe, %{name: "Spinach", amount_mg: 50_000, kcal: 0})

      assert MealEdit.ingredients_label() == "Ingredients · 2"
    end

    test "the slot chips write, and the page re-reads" do
      recipe = a_recipe!(%{slot_name: "Dinner"})

      view = mount_screen(MealEdit)
      chosen = render_info(view, {:tap, :slot_Lunch})

      assert assigns(chosen).slot == "Lunch"

      render_info(chosen, {:tap, :save})

      assert Ash.get!(Recipe, recipe.id).slot_name == "Lunch"
    end

    test "the page states both promises an edit inside a live plan makes" do
      tree = tree(mount_screen(MealEdit))

      assert find(tree, :text, text: "Changes take effect next Monday") != nil

      assert find(tree, :text, text: "Past days keep the old numbers — nothing is recalculated") !=
               nil
    end

    test "with nothing stored the drawing renders, whole" do
      assert MealEdit.meal() == MealEdit.drawn_meal()
    end
  end

  describe "screen 119" do
    test "Uncategorised is always on the aisle row" do
      # Not a fallback the user picks — it is where an ingredient goes when
      # nobody said, and it exists so the shopping list never loses a row.
      assert "Uncategorised" in Kati.Meals.SampleLibrary.aisles()
    end

    test "the two unbuilt paths carry the badge and take no tap" do
      # A tag nothing answers is a dead tap. These are not dead, they are
      # labelled, so they carry no tag at all.
      assert AddIngredient.path_tap(false) == nil
      assert AddIngredient.path_tap(true) != nil

      tree = tree(mount_screen(AddIngredient))
      assert length(find_all(tree, :text, text: "NOT IN V1")) == 2
    end

    test "each unbuilt path says what is actually missing" do
      paths = Map.new(Kati.Meals.SampleLibrary.nutrition_paths(), &{&1.title, &1.sub})

      assert paths["Scan a barcode"] =~ "food database Kati has not chosen"
      assert paths["Search a food database"] =~ "Licence, coverage and rate limits unresolved"
    end

    test "picking an aisle changes what the preview says" do
      view = mount_screen(AddIngredient)
      assert assigns(view).aisle == "Uncategorised"

      picked = render_info(view, {:tap, :aisle_Produce})

      assert assigns(picked).aisle == "Produce"
      assert find(tree(picked), :text, text: "PRODUCE · FREE TEXT") != nil
    end

    test "the preview says the meal total stays approximate" do
      tree = tree(mount_screen(AddIngredient))

      assert find(tree, :text,
               text:
                 "This is how the row will look in the meal. It adds no numbers, so the " <>
                   "meal total stays approximate — and it still lands on the shopping list."
             ) != nil
    end
  end

  describe "the route in" do
    test "screen 43's Library tile opens the library" do
      pushed = render_info(mount_screen(Kati.Screens.MealsToday), {:tap, :open_library})

      assert navigated_to(pushed) == MealLibrary
    end
  end

  describe "the three screens render" do
    test "each one draws a tree the native layer can take" do
      for module <- [MealLibrary, MealEdit, AddIngredient] do
        assert_renderable(mount_screen(module))
      end
    end
  end
end
