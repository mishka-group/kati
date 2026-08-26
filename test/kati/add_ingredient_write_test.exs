defmodule Kati.AddIngredientWriteTest do
  @moduledoc """
  Screen 119's Save adds an ingredient, to the meal that opened the sheet.

  ## What was wrong

  `handle_info({:tap, :save}, socket)` popped the screen and wrote nothing. On
  this sheet that is the worst version of the defect `Kati.Write` was written
  for: the bottom half of screen 119 is a picture of the row it is about to
  add — *this is how the row will look in the meal* — and the sheet closed as
  though it had added it. Screen 118 re-reads its ingredient list on every
  render, so the row's absence was on screen a frame later with nothing
  anywhere to say why.

  ## Why every assertion here needs two meals

  The same reason `Kati.SheetRowIdentityTest` exists. A sheet that wrote to the
  head of a re-query and a sheet that wrote to the meal it was handed are
  indistinguishable while the table holds one recipe — and one recipe is the
  state every other suite here puts it in. So each write is asked as a pair:
  the meal that opened the sheet gained the line, **and the other meal did
  not**. Only the second half can fail on the defect this file is about.

  ## Why the cache is asserted, not just the row

  `Kati.Meals.Totals` is the only writer of a recipe's cached macro totals, and
  its three-step order — bump `ingredients_rev`, write the line, store the
  totals — is what stops a stale cache being frozen into a
  `Kati.Meals.MealLog` and becoming permanent. A screen that reached
  `Ash.create/2` on `Kati.Meals.RecipeIngredient` directly would pass every
  row-shaped assertion in this file and leave `totals_rev == ingredients_rev`
  over a recipe whose ingredients had just changed. `stale?/1` is what tells
  the two apart, so it is asked after every save.

  ## Why every row is prefixed and deleted, on both sides

  Screens 116, 118 and 119 fall back to their drawings only while `recipes` is
  empty, and `Kati.ScreenDesignLiteralTest` and `Kati.ScreenEmptyDatabaseTest`
  render them against this same shared SQLite file — the suite has no Ecto
  sandbox. A recipe left behind here fails a file this one never touched, for
  the seeds that order the modules the wrong way round. So the rows go before
  the test as well as after it: an interrupted run leaves the table dirty, and
  the next run's `setup` is the only thing that can clear it.
  """
  use Mob.ScreenCase, async: false

  require Ash.Query

  # The three pure ones, run as their own examples. `only:` because the rest of
  # the module is markup and store calls, and a doctest is only worth having
  # where the answer fits on the line above it.
  doctest Kati.Screens.AddIngredient, only: [amount_mg: 1, unit_value: 1, aisle_value: 1]

  alias Kati.Meals.Recipe
  alias Kati.Meals.RecipeIngredient
  alias Kati.Meals.SampleLibrary
  alias Kati.Meals.Totals
  alias Kati.Screens.AddIngredient
  alias Kati.Screens.MealEdit

  @prefix "add-ingredient-write-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  describe "the sheet is handed the meal that opened it" do
    test "Add an ingredient pushes screen 118's own meal id" do
      second = a_recipe!(%{title: @prefix <> "B second"})
      a_recipe!(%{title: @prefix <> "A first"})

      view =
        MealEdit
        |> mount_screen(%{meal_id: second.id})
        |> render_info({:tap, :add_ingredient})

      assert {:push, AddIngredient, %{meal_id: id}} = pushed(view)
      assert id == second.id
    end

    test "an ingredient row's chevron opens the same sheet, on the same meal" do
      # The design draws no edit-an-ingredient screen and every row carries one
      # shared `:edit_ingredient` tag, so the chevron opens `Add an ingredient`.
      # What it must not do is open it aimed at a different meal.
      second = a_recipe!(%{title: @prefix <> "B second"})
      a_recipe!(%{title: @prefix <> "A first"})

      view =
        MealEdit
        |> mount_screen(%{meal_id: second.id})
        |> render_info({:tap, :edit_ingredient})

      assert pushed(view) == {:push, AddIngredient, %{meal_id: second.id}}
    end

    test "an editor naming no meal pushes no meal" do
      # `Add a meal` names no row on purpose, and the sheet is told that rather
      # than being handed a plausible id to write to.
      a_recipe!(%{title: @prefix <> "A first"})

      view =
        MealEdit
        |> mount_screen()
        |> render_info({:tap, :add_ingredient})

      assert pushed(view) == {:push, AddIngredient, %{}}
    end

    test "the sheet carries the id it was mounted with" do
      recipe = a_recipe!(%{title: @prefix <> "A first"})

      assert assigns(mount_screen(AddIngredient, %{meal_id: recipe.id})).meal_id == recipe.id
      assert assigns(mount_screen(AddIngredient)).meal_id == nil
    end
  end

  describe "Save adds the row the preview is showing" do
    test "the line reaches the store and is there on a fresh read" do
      recipe = a_recipe!(%{title: @prefix <> "A first"})

      view =
        AddIngredient
        |> mount_screen(%{meal_id: recipe.id})
        |> render_info({:tap, :save})

      assert pushed(view) == {:pop}, "a landed save closes the sheet"
      refute assigns(view).save_error

      # Read from scratch rather than through the struct the write handed back:
      # the question is whether the row is in the database, not whether the
      # writer returned something.
      assert [line] = lines_of(recipe)
      assert line.name == SampleLibrary.draft().name
      assert line.recipe_id == recipe.id
      assert {:ok, %RecipeIngredient{}} = Ash.get(RecipeIngredient, line.id)
    end

    test "the line lands on the meal that opened the sheet, and not on the other one" do
      first = a_recipe!(%{title: @prefix <> "A first"})
      second = a_recipe!(%{title: @prefix <> "B second"})

      AddIngredient
      |> mount_screen(%{meal_id: second.id})
      |> render_info({:tap, :save})

      assert length(lines_of(second)) == 1
      assert lines_of(first) == []

      # The editor behind the sheet counts it, and the other editor does not.
      assert MealEdit.ingredients_label(second.id) == "Ingredients · 1"
      assert MealEdit.ingredients_label(first.id) == "Ingredients · 0"
    end

    test "the chosen aisle is what the row is filed under" do
      recipe = a_recipe!(%{title: @prefix <> "A first"})

      AddIngredient
      |> mount_screen(%{meal_id: recipe.id})
      |> render_info({:tap, :"aisle_Fish_&_meat"})
      |> render_info({:tap, :save})

      assert [%RecipeIngredient{aisle: :fish_and_meat}] = lines_of(recipe)
    end

    test "the drawing's own aisle is Kati.Meals.Aisle's :other, never nothing" do
      # The sharp end of the whole sheet: an ingredient filed nowhere vanishes
      # off the shopping list, so `Uncategorised` is a real bucket rather than
      # an absent one.
      recipe = a_recipe!(%{title: @prefix <> "A first"})

      AddIngredient
      |> mount_screen(%{meal_id: recipe.id})
      |> render_info({:tap, :save})

      assert [%RecipeIngredient{aisle: :other}] = lines_of(recipe)
      assert :other in Kati.Meals.Aisle.values()
    end

    test "the stored row is the row the preview promised" do
      # `a few` is words rather than a measurement, which the store spells
      # `amount_mg: 0` and screen 118 reads back as free text. The two words
      # for the bucket differ on purpose — see `aisle_value/1`.
      recipe = a_recipe!(%{title: @prefix <> "A first"})

      sheet = mount_screen(AddIngredient, %{meal_id: recipe.id})
      assert find(tree(sheet), :text, text: "UNCATEGORISED · FREE TEXT") != nil

      render_info(sheet, {:tap, :save})

      assert [row] = MealEdit.ingredients(recipe.id)
      assert row.name == SampleLibrary.draft().name
      assert row.amount == "a few"
      assert row.state == :free_text
      assert row.meta == "OTHER · FREE TEXT"
    end

    test "a second ingredient gets the next position, not a rejected duplicate" do
      # `recipe_ingredients` carries a UNIQUE index on `{recipe_id, position}`.
      # A sheet that wrote `position: 0` would add one line to a meal and then
      # refuse every line after it.
      recipe = a_recipe!(%{title: @prefix <> "A first"})

      AddIngredient
      |> mount_screen(%{meal_id: recipe.id})
      |> render_info({:tap, :save})
      |> render_info({:tap, :save})

      assert Enum.map(lines_of(recipe), & &1.position) == [0, 1]
    end

    test "the cached totals are current afterwards, not merely present" do
      # The whole reason the write goes through `Kati.Meals.Totals`. A line
      # inserted around it leaves the recipe claiming totals it does not have,
      # and `Kati.Meals.Changes.FreezeNutrition` would copy that claim into a
      # log permanently.
      recipe = a_recipe!(%{title: @prefix <> "A first"})
      before_rev = recipe.ingredients_rev

      AddIngredient
      |> mount_screen(%{meal_id: recipe.id})
      |> render_info({:tap, :save})

      reloaded = Ash.get!(Recipe, recipe.id)

      assert reloaded.ingredients_rev > before_rev, "the write did not mark the cache dirty"
      refute Totals.stale?(reloaded), "the write left the cached totals stale"
      assert reloaded.totals_rev == reloaded.ingredients_rev
    end
  end

  describe "a save that cannot land keeps the sheet open" do
    test "no meal named is no write, and says so" do
      # The refusal that makes the sheet safe to tap anywhere — including
      # `Kati.ScreenTapSweepTest`, which taps `:save` on every screen with no
      # params at all against this same database.
      recipe = a_recipe!(%{title: @prefix <> "A first"})

      view =
        AddIngredient
        |> mount_screen()
        |> render_info({:tap, :save})

      refute pushed(view) == {:pop}, "a refused save must not close the sheet"
      assert assigns(view).save_error == "Nothing to save yet."
      assert lines_of(recipe) == []
      assert Ash.count!(RecipeIngredient) == 0
    end

    test "the message is on the sheet, not only in the assigns" do
      view =
        AddIngredient
        |> mount_screen()
        |> render_info({:tap, :save})

      assert find(tree(view), :text, text: "Nothing to save yet.") != nil
    end

    test "a meal deleted under the sheet is not a reason to write elsewhere" do
      first = a_recipe!(%{title: @prefix <> "A first"})
      gone = a_recipe!(%{title: @prefix <> "B second"})

      view = mount_screen(AddIngredient, %{meal_id: gone.id})
      Ash.destroy!(gone)

      view = render_info(view, {:tap, :save})

      refute pushed(view) == {:pop}
      assert assigns(view).save_error =~ "did not save"
      assert lines_of(first) == []
      assert Ash.count!(RecipeIngredient) == 0
    end

    test "the writer answers a tuple, both ways" do
      recipe = a_recipe!(%{title: @prefix <> "A first"})
      assigns = assigns(mount_screen(AddIngredient, %{meal_id: recipe.id}))

      assert {:ok, %RecipeIngredient{}} = AddIngredient.save_ingredient(assigns)
      assert {:error, _reason} = AddIngredient.save_ingredient(%{assigns | meal_id: nil})
    end
  end

  describe "the drawn values that become a row" do
    test "a quantity that is words is stored as no amount at all" do
      assert AddIngredient.amount_mg(SampleLibrary.draft().quantity) == 0
      assert AddIngredient.amount_mg("180") == 180_000
    end

    test "every aisle the sheet offers maps onto a value the store has" do
      # A chip that mapped to an atom outside `Kati.Meals.Aisle` would be a
      # rejected changeset at the far end of a button that looks fine.
      for aisle <- SampleLibrary.aisles() do
        assert AddIngredient.aisle_value(aisle) in Kati.Meals.Aisle.values()
      end
    end

    test "every unit the sheet can carry maps onto one the resource accepts" do
      accepted =
        RecipeIngredient
        |> Ash.Resource.Info.attribute(:unit)
        |> Map.fetch!(:constraints)
        |> Keyword.fetch!(:one_of)

      assert AddIngredient.unit_value(SampleLibrary.draft().unit) in accepted
      assert AddIngredient.unit_value("ml") in accepted
    end
  end

  defp pushed(view), do: view.socket.__mob__.nav_action

  # This recipe's lines, read from scratch and in the order screen 118 reads
  # them.
  defp lines_of(recipe) do
    RecipeIngredient
    |> Ash.Query.filter(recipe_id == ^recipe.id)
    |> Ash.Query.sort(position: :asc)
    |> Ash.read!()
  end

  defp a_recipe!(attrs) do
    Ash.create!(Recipe, Map.merge(%{title: @prefix <> "A meal", serves: 2}, attrs))
  end

  # Children first: the foreign key refuses the parent delete otherwise. Raw
  # SQL because this also runs from `on_exit`, after the test process is gone.
  defp delete_rows! do
    Kati.Repo.query!(
      "DELETE FROM recipe_ingredients WHERE recipe_id IN " <>
        "(SELECT id FROM recipes WHERE title LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM recipes WHERE title LIKE ?1", [@prefix <> "%"])
  end
end
