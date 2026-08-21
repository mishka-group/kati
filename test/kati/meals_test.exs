defmodule Kati.MealsTest do
  @moduledoc """
  The meal domain's three load-bearing rules, held against a real SQLite file.

  Each `describe` below corresponds to a decision in #73 that cannot be
  retrofitted over user data, so each one asserts on *values* — what the numbers
  are before and after — rather than on a write not raising. A test here that
  could pass against an empty table is not a test.
  """
  use ExUnit.Case, async: false

  alias Kati.Meals.Aisle
  alias Kati.Meals.BundledFood
  alias Kati.Meals.Food
  alias Kati.Meals.LicensedFood
  alias Kati.Meals.MealLog
  alias Kati.Meals.MealPlan
  alias Kati.Meals.MealPlanSlot
  alias Kati.Meals.Nutrition
  alias Kati.Meals.Recipe
  alias Kati.Meals.RecipeIngredient
  alias Kati.Meals.ShoppingListItem
  alias Kati.Meals.Totals

  # Screen 45's ingredient list, at one portion, with the macros distributed so
  # the five lines sum to the drawing's own `52P 64C 17F`, `7 g` fibre, `9 g`
  # sugar and `840 mg` sodium.
  #
  # kcal sums to 662 rather than the drawn 620. That is not a bug in the
  # fixture: `Kati.Meals.SampleRecipe`'s own moduledoc says the drawn headline
  # is declared rather than derived, and screen 45's claim is that the total is
  # *visibly* the sum of its parts. The sum is what the write path computes, so
  # the sum is what these tests assert.
  @miso_salmon [
    %{
      position: 0,
      name: "Salmon fillet",
      amount_mg: 150_000,
      unit: :g,
      aisle: :fish_and_meat,
      kcal: 312,
      protein_mg: 41_000,
      carbs_mg: 0,
      fat_mg: 10_100,
      fibre_mg: 0,
      sugar_mg: 0,
      sodium_mg: 110
    },
    %{
      position: 1,
      name: "Jasmine rice, dry",
      amount_mg: 65_000,
      unit: :g,
      aisle: :grains_and_pasta,
      kcal: 234,
      protein_mg: 5_000,
      carbs_mg: 55_000,
      fat_mg: 500,
      fibre_mg: 600,
      sugar_mg: 100,
      sodium_mg: 5
    },
    %{
      position: 2,
      name: "Tenderstem broccoli",
      amount_mg: 120_000,
      unit: :g,
      aisle: :produce,
      kcal: 42,
      protein_mg: 4_000,
      carbs_mg: 5_000,
      fat_mg: 500,
      fibre_mg: 5_600,
      sugar_mg: 7_500,
      sodium_mg: 40
    },
    %{
      position: 3,
      name: "White miso",
      amount_mg: 15_000,
      unit: :g,
      aisle: :cupboard,
      kcal: 30,
      protein_mg: 2_000,
      carbs_mg: 4_000,
      fat_mg: 900,
      fibre_mg: 800,
      sugar_mg: 1_400,
      sodium_mg: 685
    },
    %{
      position: 4,
      name: "Sesame oil",
      amount_mg: 5_000,
      unit: :ml,
      aisle: :cupboard,
      kcal: 44,
      protein_mg: 0,
      carbs_mg: 0,
      fat_mg: 5_000,
      fibre_mg: 0,
      sugar_mg: 0,
      sodium_mg: 0
    }
  ]

  @at_one_portion %{
    kcal: 662,
    protein_mg: 52_000,
    carbs_mg: 64_000,
    fat_mg: 17_000,
    fibre_mg: 7_000,
    sugar_mg: 9_000,
    sodium_mg: 840
  }

  # "Better with double the miso" — screen 45's own note, as an edit.
  @doubled_miso %{
    amount_mg: 30_000,
    kcal: 60,
    protein_mg: 4_000,
    carbs_mg: 8_000,
    fat_mg: 1_800,
    fibre_mg: 1_600,
    sugar_mg: 2_800,
    sodium_mg: 1_370
  }

  @after_doubling %{
    kcal: 692,
    protein_mg: 54_000,
    carbs_mg: 68_000,
    fat_mg: 17_900,
    fibre_mg: 7_800,
    sugar_mg: 10_400,
    sodium_mg: 1_525
  }

  defp recipe!(attrs \\ %{}) do
    Recipe
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{title: "Miso salmon, greens & rice", minutes: 25, oven_c: 200, serves: 1},
        attrs
      )
    )
    |> Ash.create!()
  end

  defp miso_salmon! do
    Enum.reduce(@miso_salmon, recipe!(), fn line, acc ->
      {_ingredient, updated} = Totals.write_ingredient(acc, line)
      updated
    end)
  end

  defp figures(row), do: Map.take(row, Nutrition.fields())

  defp totals(%Recipe{} = recipe) do
    Map.new(Nutrition.fields(), fn field -> {field, Map.fetch!(recipe, :"total_#{field}")} end)
  end

  defp log!(recipe, attrs \\ %{}) do
    MealLog
    |> Ash.Changeset.for_create(
      :log_recipe,
      Map.merge(
        %{recipe_id: recipe.id, logged_on: ~D[2026-08-16], logged_at: DateTime.utc_now()},
        attrs
      )
    )
    |> Ash.create!()
  end

  defp plan!(attrs \\ %{}) do
    MealPlan
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{name: "Cutting v#{System.unique_integer([:positive])}"}, attrs)
    )
    |> Ash.create!()
  end

  # `meal_plans` carries a partial unique index that permits exactly one active
  # row, so a test that activates a plan has to leave the table as it found it.
  defp stand_down_all_active do
    MealPlan
    |> Ash.read!()
    |> Enum.filter(&(&1.status == :active))
    |> Enum.each(fn plan ->
      plan |> Ash.Changeset.for_update(:stand_down, %{}) |> Ash.update!()
    end)
  end

  defp active_plans, do: MealPlan |> Ash.read!() |> Enum.filter(&(&1.status == :active))

  describe "the frozen log snapshot" do
    test "editing a recipe after logging does not move the log's figures" do
      recipe = miso_salmon!()
      assert totals(recipe) == @at_one_portion

      log = log!(recipe)
      assert figures(log) == @at_one_portion

      # The edit screen 45's note asks for.
      miso =
        RecipeIngredient
        |> Ash.read!()
        |> Enum.find(&(&1.recipe_id == recipe.id and &1.name == "White miso"))

      {_line, edited} = Totals.update_ingredient(miso, @doubled_miso)

      # The recipe genuinely moved — without this the next assertion is vacuous,
      # because a log that never changes is also what a broken write path looks
      # like.
      assert totals(edited) == @after_doubling
      refute totals(edited) == @at_one_portion

      {:ok, reloaded} = Ash.get(MealLog, log.id)
      assert figures(reloaded) == @at_one_portion

      # And the link is still there. If the freeze had been achieved by cutting
      # the reference, "the figures did not move" would be true and useless.
      assert reloaded.recipe_id == recipe.id
      assert reloaded.recipe_rev < edited.ingredients_rev
    end

    test "the snapshot scales by the portion, exactly" do
      recipe = miso_salmon!()

      log = log!(recipe, %{portion_milli: 1500})

      assert log.portion_milli == 1500
      # 662 * 1.5 = 993 exactly, and 52 000 mg * 1.5 = 78 000 mg exactly. No
      # float arrives at either, which is why the assertion can be ==.
      assert log.kcal == 993
      assert log.protein_mg == 78_000
      assert log.carbs_mg == 96_000
    end

    test "a deleted recipe leaves its logs readable, with the figures intact" do
      recipe = miso_salmon!()
      log = log!(recipe)

      Ash.destroy!(recipe)

      {:ok, orphan} = Ash.get(MealLog, log.id)
      assert figures(orphan) == @at_one_portion
      assert orphan.title == "Miso salmon, greens & rice"
      # Provenance is gone because the row it pointed at is gone; the history is
      # not, because it never lived there.
      assert is_nil(orphan.recipe_id)
    end

    test "no update action accepts a snapshot column" do
      recipe = miso_salmon!()
      log = log!(recipe)

      assert {:error, _} =
               log
               |> Ash.Changeset.for_update(:mark, %{kcal: 1})
               |> Ash.update()

      {:ok, unchanged} = Ash.get(MealLog, log.id)
      assert unchanged.kcal == 662
    end

    test "forcing a snapshot column past the accept list is refused too" do
      recipe = miso_salmon!()
      log = log!(recipe)

      # `accept` does not stop `force_change_attribute/3`, which is exactly how
      # a future refactor would unfreeze history without a test noticing.
      assert {:error, _} =
               log
               |> Ash.Changeset.for_update(:mark, %{state: :skipped})
               |> Ash.Changeset.force_change_attribute(:kcal, 1)
               |> Ash.update()

      {:ok, unchanged} = Ash.get(MealLog, log.id)
      assert unchanged.kcal == 662
      assert unchanged.state == :eaten
    end

    test "state and the user's own remarks are not frozen" do
      recipe = miso_salmon!()
      log = log!(recipe)

      {:ok, marked} =
        log
        |> Ash.Changeset.for_update(:mark, %{state: :skipped, note: "not hungry", rating: 4})
        |> Ash.update()

      assert marked.state == :skipped
      assert marked.note == "not hungry"
      assert marked.rating == 4
      # A skipped meal keeps its figures: "you skipped 620 kcal" is the sentence
      # screen 47's insight is built from.
      assert figures(marked) == @at_one_portion
    end

    test "an ad-hoc meal freezes on the same terms as a recipe" do
      log =
        MealLog
        |> Ash.Changeset.for_create(:log_manual, %{
          logged_on: ~D[2026-08-16],
          logged_at: DateTime.utc_now(),
          title: "Lunch out",
          kcal: 780,
          protein_mg: 30_000
        })
        |> Ash.create!()

      assert log.kcal == 780
      assert log.frozen_at
      assert is_nil(log.recipe_id)

      assert {:error, _} =
               log |> Ash.Changeset.for_update(:mark, %{kcal: 100}) |> Ash.update()
    end

    test "a day's intake sums the eaten rows and the skipped ones stay countable" do
      recipe = miso_salmon!()
      day = ~D[2026-08-17]

      eaten = for _ <- 1..3, do: log!(recipe, %{logged_on: day, state: :eaten})
      skipped = log!(recipe, %{logged_on: day, state: :skipped})

      rows =
        MealLog
        |> Ash.Query.for_read(:on_day, %{on: day})
        |> Ash.read!()

      assert length(rows) == 4

      intake =
        rows
        |> Enum.filter(&(&1.state == :eaten))
        |> Nutrition.sum()

      assert intake.kcal == 662 * 3
      assert length(eaten) == 3
      assert Enum.count(rows, &(&1.state == :skipped)) == 1
      assert skipped.kcal == 662
    end
  end

  describe "cached macro totals" do
    test "a recipe with no ingredients totals zero, not nil" do
      recipe = recipe!()
      assert totals(recipe) == Nutrition.zero()
      refute Totals.stale?(recipe)
    end

    test "every ingredient write leaves the cache current" do
      recipe = miso_salmon!()

      refute Totals.stale?(recipe)
      assert recipe.totals_rev == recipe.ingredients_rev
      assert recipe.ingredients_rev == 5
      assert totals(recipe) == @at_one_portion
    end

    test "removing an ingredient recomputes downward" do
      recipe = miso_salmon!()

      oil =
        RecipeIngredient
        |> Ash.read!()
        |> Enum.find(&(&1.recipe_id == recipe.id and &1.name == "Sesame oil"))

      recipe = Totals.remove_ingredient(oil)

      assert recipe.total_kcal == 662 - 44
      assert recipe.total_fat_mg == 17_000 - 5_000
      refute Totals.stale?(recipe)
    end

    test "an interrupted write is marked stale, not silently forgotten" do
      recipe = miso_salmon!()

      # Step 1 of the three-step write, on its own — which is what a crash
      # between the bump and the recompute leaves behind.
      dirty = Totals.mark_dirty!(recipe)

      assert Totals.stale?(dirty)
      assert dirty.totals_rev < dirty.ingredients_rev
      # The columns still hold the old figures, which is why "stale" has to be
      # discoverable rather than inferred from them.
      assert totals(dirty) == @at_one_portion

      found = Recipe |> Ash.Query.for_read(:with_stale_totals) |> Ash.read!()
      assert Enum.any?(found, &(&1.id == recipe.id))

      healed = Totals.fresh!(dirty)
      refute Totals.stale?(healed)
      assert totals(healed) == @at_one_portion
    end

    test "freezing a log recomputes a stale recipe first" do
      recipe = miso_salmon!()

      # An ingredient row written WITHOUT the recompute — the second half of a
      # partial failure. The cache now claims 662 and the truth is 762.
      RecipeIngredient
      |> Ash.Changeset.for_create(:create, %{
        recipe_id: recipe.id,
        position: 5,
        name: "Extra rice",
        amount_mg: 30_000,
        kcal: 100
      })
      |> Ash.create!()

      dirty = Totals.mark_dirty!(recipe)
      assert Totals.stale?(dirty)
      assert dirty.total_kcal == 662

      log = log!(dirty)

      # The freeze took the recomputed figure, not the stale column. A stale
      # cache is recoverable right up to the moment it is copied into history.
      assert log.kcal == 762

      {:ok, refreshed} = Ash.get(Recipe, recipe.id)
      refute Totals.stale?(refreshed)
      assert refreshed.total_kcal == 762
    end

    test "an ordinary recipe edit cannot write a totals column" do
      recipe = miso_salmon!()

      accept = Ash.Resource.Info.action(Recipe, :update).accept
      refute :total_kcal in accept
      refute :totals_rev in accept
      refute :ingredients_rev in accept

      assert {:error, _} =
               recipe
               |> Ash.Changeset.for_update(:update, %{total_kcal: 1})
               |> Ash.update()

      {:ok, renamed} =
        recipe |> Ash.Changeset.for_update(:update, %{title: "Miso salmon v2"}) |> Ash.update()

      assert renamed.title == "Miso salmon v2"
      assert renamed.total_kcal == 662
    end
  end

  describe "the aisle enum" do
    test "is exactly fourteen values, fixed" do
      assert Aisle.count() == 14
      assert length(Enum.uniq(Aisle.values())) == 14
      assert :other in Aisle.values()
    end

    test "keeps screen 48's own wording" do
      assert Aisle.label(:produce) == "Produce"
      assert Aisle.label(:fish_and_meat) == "Fish & meat"
      assert Aisle.label(:cupboard) == "Cupboard"
    end

    test "is enforced at the schema level, not by convention" do
      plan = plan!()

      assert {:error, _} =
               ShoppingListItem
               |> Ash.Changeset.for_create(:create, %{
                 meal_plan_id: plan.id,
                 week_starting_on: ~D[2026-08-17],
                 name: "Tenderstem broccoli",
                 aisle: :vegetables_and_things
               })
               |> Ash.create()

      assert {:ok, item} =
               ShoppingListItem
               |> Ash.Changeset.for_create(:create, %{
                 meal_plan_id: plan.id,
                 week_starting_on: ~D[2026-08-17],
                 name: "Tenderstem broccoli",
                 aisle: :produce,
                 amount_mg: 840_000,
                 meal_count: 7,
                 meals_label: "7 meals"
               })
               |> Ash.create()

      assert item.aisle == :produce
      assert item.meals_label == "7 meals"
      assert item.price_source == :none
    end

    test "every value the constraint allows is actually writable" do
      plan = plan!()

      written =
        for aisle <- Aisle.values() do
          ShoppingListItem
          |> Ash.Changeset.for_create(:create, %{
            meal_plan_id: plan.id,
            week_starting_on: ~D[2026-08-24],
            name: "line #{aisle}",
            aisle: aisle
          })
          |> Ash.create!()
        end

      assert length(written) == 14
      stored = written |> Enum.map(& &1.aisle) |> Enum.sort()
      assert stored == Enum.sort(Aisle.values())
    end
  end

  describe "the food corpora do not merge" do
    test "the bundled table takes CC0 and nothing else" do
      assert {:ok, row} =
               BundledFood
               |> Ash.Changeset.for_create(:seed, %{
                 corpus: :usda_foundation,
                 source_key: "fdc-#{System.unique_integer([:positive])}",
                 bundle_version: "2026-04",
                 name: "Salmon, Atlantic, farmed, raw",
                 default_aisle: :fish_and_meat,
                 kcal: 208,
                 protein_mg: 20_400
               })
               |> Ash.create()

      assert row.licence == :cc0

      assert {:error, _} =
               BundledFood
               |> Ash.Changeset.for_create(:seed, %{
                 corpus: :usda_foundation,
                 source_key: "fdc-#{System.unique_integer([:positive])}",
                 bundle_version: "2026-04",
                 name: "Something ODbL"
               })
               |> Ash.Changeset.force_change_attribute(:licence, :odbl)
               |> Ash.create()
    end

    test "the licensed table refuses CC0, so neither can absorb the other" do
      assert {:error, _} =
               LicensedFood
               |> Ash.Changeset.for_create(:create, %{
                 licence: :cc0,
                 source: :open_food_facts,
                 source_id: "x#{System.unique_integer([:positive])}",
                 name: "Should not exist",
                 fetched_at: DateTime.utc_now()
               })
               |> Ash.create()
    end

    test "a licensed row cannot be written without fetched_at" do
      assert {:error, _} =
               LicensedFood
               |> Ash.Changeset.for_create(:create, %{
                 licence: :odbl,
                 source: :open_food_facts,
                 source_id: "y#{System.unique_integer([:positive])}",
                 name: "Un-evictable"
               })
               |> Ash.create()
    end

    test "the eviction sweep finds an old licensed row and spares a fresh one" do
      old =
        LicensedFood
        |> Ash.Changeset.for_create(:create, %{
          licence: :odbl,
          source: :open_food_facts,
          source_id: "old-#{System.unique_integer([:positive])}",
          name: "Stale row",
          fetched_at: ~U[2020-01-01 00:00:00.000000Z]
        })
        |> Ash.create!()

      fresh =
        LicensedFood
        |> Ash.Changeset.for_create(:create, %{
          licence: :odbl,
          source: :open_food_facts,
          source_id: "new-#{System.unique_integer([:positive])}",
          name: "Fresh row",
          fetched_at: DateTime.utc_now()
        })
        |> Ash.create!()

      evictable =
        LicensedFood
        |> Ash.Query.for_read(:evictable, %{before: ~U[2026-01-01 00:00:00.000000Z]})
        |> Ash.read!()

      ids = Enum.map(evictable, & &1.id)
      assert old.id in ids
      refute fresh.id in ids
    end

    test "an ingredient may cite one corpus, or none, but never two" do
      recipe = recipe!()

      food =
        Food
        |> Ash.Changeset.for_create(:create, %{name: "White miso", default_aisle: :cupboard})
        |> Ash.create!()

      bundled =
        BundledFood
        |> Ash.Changeset.for_create(:seed, %{
          corpus: :usda_sr_legacy,
          source_key: "fdc-#{System.unique_integer([:positive])}",
          bundle_version: "2026-04",
          name: "Miso"
        })
        |> Ash.create!()

      # None: a hand-typed line is a complete line.
      assert {:ok, typed} =
               RecipeIngredient
               |> Ash.Changeset.for_create(:create, %{
                 recipe_id: recipe.id,
                 position: 0,
                 name: "White miso",
                 kcal: 30
               })
               |> Ash.create()

      assert is_nil(typed.food_id)

      # One.
      assert {:ok, cited} =
               RecipeIngredient
               |> Ash.Changeset.for_create(:create, %{
                 recipe_id: recipe.id,
                 position: 1,
                 name: "White miso",
                 food_id: food.id
               })
               |> Ash.create()

      assert cited.food_id == food.id

      # Two: a line claiming two provenances is a merge of two licences.
      assert {:error, _} =
               RecipeIngredient
               |> Ash.Changeset.for_create(:create, %{
                 recipe_id: recipe.id,
                 position: 2,
                 name: "White miso",
                 food_id: food.id,
                 bundled_food_id: bundled.id
               })
               |> Ash.create()
    end

    test "evicting a cited food leaves the recipe line whole" do
      recipe = recipe!()

      licensed =
        LicensedFood
        |> Ash.Changeset.for_create(:create, %{
          licence: :odbl,
          source: :open_food_facts,
          source_id: "cited-#{System.unique_integer([:positive])}",
          name: "Tenderstem broccoli",
          fetched_at: ~U[2020-01-01 00:00:00.000000Z]
        })
        |> Ash.create!()

      {line, _recipe} =
        Totals.write_ingredient(recipe, %{
          position: 0,
          name: "Tenderstem broccoli",
          amount_mg: 120_000,
          aisle: :produce,
          kcal: 42,
          licensed_food_id: licensed.id
        })

      Ash.destroy!(licensed)

      {:ok, survivor} = Ash.get(RecipeIngredient, line.id)
      assert survivor.name == "Tenderstem broccoli"
      assert survivor.kcal == 42
      assert survivor.amount_mg == 120_000
      # The provenance is what a sweep costs; the line is not.
      assert is_nil(survivor.licensed_food_id)
    end
  end

  describe "the Persian layer" do
    test "a Persian food needs no USDA provenance, because the table has none" do
      # Structural, not conventional: there is no upstream-id column on `foods`
      # for a Persian row to leave empty.
      assert is_nil(Ash.Resource.Info.attribute(Food, :fdc_id))
      assert is_nil(Ash.Resource.Info.attribute(Food, :source_key))
      assert is_nil(Ash.Resource.Info.attribute(Food, :corpus))

      ghormeh =
        Food
        |> Ash.Changeset.for_create(:create, %{
          name: "Ghormeh sabzi herbs",
          name_original: "سبزی قورمه‌سبزی",
          licence: :kati_original,
          cuisine: :persian,
          default_aisle: :produce,
          kcal: 45,
          protein_mg: 3_000
        })
        |> Ash.create!()

      assert ghormeh.cuisine == :persian
      assert ghormeh.licence == :kati_original

      found = Food |> Ash.Query.for_read(:by_cuisine, %{cuisine: :persian}) |> Ash.read!()
      assert Enum.any?(found, &(&1.id == ghormeh.id))
    end

    test "foods cannot claim the bundled corpus's licence" do
      assert {:error, _} =
               Food
               |> Ash.Changeset.for_create(:create, %{name: "Borrowed", licence: :cc0})
               |> Ash.create()
    end

    test "a food with no figures yet is still a usable row" do
      sangak =
        Food
        |> Ash.Changeset.for_create(:create, %{
          name: "Sangak",
          cuisine: :persian,
          default_aisle: :bakery
        })
        |> Ash.create!()

      assert is_nil(sangak.kcal)
      # Nutrition reads a missing figure as zero, so an un-costed food does not
      # make the recipe containing it unusable.
      assert Nutrition.take(sangak) == Nutrition.zero()
    end
  end

  describe "the remembered price" do
    test "lives on the user's own food row and is copied onto the list" do
      food =
        Food
        |> Ash.Changeset.for_create(:create, %{
          name: "Salmon fillet",
          default_aisle: :fish_and_meat
        })
        |> Ash.create!()

      {:ok, priced} =
        food
        |> Ash.Changeset.for_update(:remember_price, %{
          last_price_minor: 812,
          last_price_currency: "GBP"
        })
        |> Ash.update()

      assert priced.last_price_minor == 812
      assert priced.last_price_at

      plan = plan!()

      item =
        ShoppingListItem
        |> Ash.Changeset.for_create(:create, %{
          meal_plan_id: plan.id,
          week_starting_on: ~D[2026-08-17],
          name: "Salmon fillet",
          aisle: :fish_and_meat,
          food_id: priced.id,
          price_minor: priced.last_price_minor,
          price_currency: priced.last_price_currency,
          price_source: :remembered
        })
        |> Ash.create!()

      # The list's copy is frozen: paying more in September must not rewrite
      # what August's shop is recorded as having cost.
      {:ok, dearer} =
        priced
        |> Ash.Changeset.for_update(:remember_price, %{
          last_price_minor: 950,
          last_price_currency: "GBP"
        })
        |> Ash.update()

      assert dearer.last_price_minor == 950

      {:ok, unchanged} = Ash.get(ShoppingListItem, item.id)
      assert unchanged.price_minor == 812
      assert unchanged.price_source == :remembered
    end

    test "an item with no price contributes nothing rather than a guess" do
      plan = plan!()

      item =
        ShoppingListItem
        |> Ash.Changeset.for_create(:create, %{
          meal_plan_id: plan.id,
          week_starting_on: ~D[2026-08-17],
          name: "White miso",
          aisle: :cupboard
        })
        |> Ash.create!()

      assert item.price_source == :none
      assert is_nil(item.price_minor)
    end
  end

  describe "the plan is a rule, not 52 copies" do
    setup do
      stand_down_all_active()
      on_exit(&stand_down_all_active/0)
      :ok
    end

    test "exactly one plan can be active, enforced by the database" do
      first = plan!() |> Ash.Changeset.for_update(:activate, %{}) |> Ash.update!()
      assert first.status == :active
      assert first.use_count == 1
      assert first.last_used_on == Kati.Time.today()

      second = plan!()

      assert {:error, error} =
               second |> Ash.Changeset.for_update(:activate, %{}) |> Ash.update()

      assert inspect(error) =~ "already active"

      # The state, not only the error: the table still holds exactly one active
      # plan, and it is the one that was there first.
      assert [%{id: only}] = active_plans()
      assert only == first.id

      # Standing the first one down is what makes room, which is why the switch
      # path does that write first.
      first |> Ash.Changeset.for_update(:stand_down, %{}) |> Ash.update!()

      assert {:ok, promoted} =
               second |> Ash.Changeset.for_update(:activate, %{}) |> Ash.update()

      assert promoted.status == :active
      assert [%{id: still_only}] = active_plans()
      assert still_only == promoted.id

      # And the read action agrees with the table.
      assert {:ok, %{id: ^still_only}} =
               MealPlan |> Ash.Query.for_read(:active) |> Ash.read_one()
    end

    test "one week of slots is 35 rows and a repeat rule" do
      plan = plan!(%{starts_on: ~D[2026-07-06], weeks_total: 12})
      assert plan.repeat == :weekly

      names = [
        {"Breakfast", ~T[07:30:00]},
        {"Snack", ~T[10:30:00]},
        {"Lunch", ~T[13:00:00]},
        {"Snack", ~T[16:00:00]},
        {"Dinner", ~T[19:30:00]}
      ]

      slots =
        for day <- 1..7, {{name, time}, position} <- Enum.with_index(names) do
          MealPlanSlot
          |> Ash.Changeset.for_create(:create, %{
            meal_plan_id: plan.id,
            day_of_week: day,
            position: position,
            slot_name: name,
            slot_time: time
          })
          |> Ash.create!()
        end

      # Screen 50 offers "All 35, with photos"; screen 47's 30 hit + 5 skipped
      # is the same 35.
      assert length(slots) == 35

      sunday =
        MealPlanSlot
        |> Ash.Query.for_read(:on_day, %{meal_plan_id: plan.id, day_of_week: 7})
        |> Ash.read!()

      assert length(sunday) == 5

      assert Enum.map(sunday, & &1.slot_name) == [
               "Breakfast",
               "Snack",
               "Lunch",
               "Snack",
               "Dinner"
             ]

      assert Enum.map(sunday, & &1.position) == [0, 1, 2, 3, 4]
    end

    test "a slot's time is floating — a bare wall clock with no zone beside it" do
      plan = plan!()

      slot =
        MealPlanSlot
        |> Ash.Changeset.for_create(:create, %{
          meal_plan_id: plan.id,
          day_of_week: 1,
          position: 0,
          slot_name: "Breakfast",
          slot_time: ~T[07:30:00]
        })
        |> Ash.create!()

      assert slot.slot_time == ~T[07:30:00]
      # Half past seven wherever you are. Storing an instant is what makes
      # breakfast arrive at 04:30 after a flight.
      assert is_nil(Ash.Resource.Info.attribute(MealPlanSlot, :tzid))
      assert is_nil(Ash.Resource.Info.attribute(MealPlanSlot, :slot_time_utc))
    end

    test "`today` is not a storable cell state" do
      plan = plan!()

      assert {:error, _} =
               MealPlanSlot
               |> Ash.Changeset.for_create(:create, %{
                 meal_plan_id: plan.id,
                 day_of_week: 1,
                 position: 1,
                 slot_name: "Snack",
                 state: :today
               })
               |> Ash.create()

      for state <- [:planned, :free, :open] do
        assert {:ok, _} =
                 MealPlanSlot
                 |> Ash.Changeset.for_create(:create, %{
                   meal_plan_id: plan.id,
                   day_of_week: 2,
                   position: Enum.find_index([:planned, :free, :open], &(&1 == state)),
                   slot_name: "Snack",
                   state: state
                 })
                 |> Ash.create()
      end
    end

    test "deleting a recipe empties the slot without deleting the slot" do
      plan = plan!()
      recipe = miso_salmon!()

      slot =
        MealPlanSlot
        |> Ash.Changeset.for_create(:create, %{
          meal_plan_id: plan.id,
          day_of_week: 3,
          position: 0,
          slot_name: "Dinner",
          slot_time: ~T[19:30:00],
          recipe_id: recipe.id
        })
        |> Ash.create!()

      Ash.destroy!(recipe)

      {:ok, emptied} = Ash.get(MealPlanSlot, slot.id)
      assert is_nil(emptied.recipe_id)
      assert emptied.slot_name == "Dinner"
      assert emptied.state == :planned
    end

    test "there is no auto-switch column, because there is no trip to switch on" do
      # #71's third question, answered by degrading rather than inventing: the
      # scheduled switch is modelled and the trip-triggered one is not.
      assert is_nil(Ash.Resource.Info.attribute(MealPlan, :auto_switch))
      assert Ash.Resource.Info.attribute(MealPlan, :activates_on)

      plan = plan!(%{activates_on: ~D[2026-08-24], keep_history: true})
      assert plan.activates_on == ~D[2026-08-24]
      assert plan.keep_history

      {:ok, activated} = plan |> Ash.Changeset.for_update(:activate, %{}) |> Ash.update()
      # The scheduled date is consumed by the switch it scheduled.
      assert is_nil(activated.activates_on)
    end
  end

  describe "integer nutrition arithmetic" do
    test "scaling rounds half up and stays exact at one portion" do
      one = %{kcal: 662, protein_mg: 52_000}

      assert Nutrition.scale(one, 1000).kcal == 662
      assert Nutrition.scale(one, 500).kcal == 331
      assert Nutrition.scale(one, 1500).protein_mg == 78_000

      # 1.4x and 1.5x of a single kcal: half up, not half even.
      assert Nutrition.scale(%{kcal: 1}, 1400).kcal == 1
      assert Nutrition.scale(%{kcal: 1}, 1500).kcal == 2
      assert Nutrition.scale(%{kcal: 1}, 0).kcal == 0
    end

    test "a per-100g row scales to a real amount" do
      per_100g = %{kcal: 208, protein_mg: 20_400}

      # 150 g of a 208 kcal/100 g salmon.
      assert Nutrition.for_amount(per_100g, 150_000).kcal == 312
      assert Nutrition.for_amount(per_100g, 100_000).kcal == 208
      assert Nutrition.for_amount(per_100g, 150_000).protein_mg == 30_600
    end

    test "sums treat a missing figure as zero rather than as unknown" do
      assert Nutrition.sum([%{kcal: 10}, %{kcal: 5, protein_mg: 100}]) ==
               Map.merge(Nutrition.zero(), %{kcal: 15, protein_mg: 100})
    end
  end
end
