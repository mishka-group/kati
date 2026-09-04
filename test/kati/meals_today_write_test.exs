defmodule Kati.MealsTodayWriteTest do
  @moduledoc """
  Screen 43's **Mark eaten** writes a meal log.

  It drew the button and did nothing with it. `Kati.ScreenTapSweepTest`'s
  backlog names that shape exactly — *"a button that never marks anything"* —
  and the row it sat on carried only what the card draws, so there was nothing
  for it to write about even in principle.

  Two things had to change and the second is the one a test can miss. The row
  now carries the slot and recipe it came from; and the tag carries the slot's
  id, because a day holds up to three upcoming meals and the card is drawn once
  per meal. A bare `:mark_eaten` would have marked whichever meal the handler
  happened to find.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Meals.MealLog

  setup do
    for resource <- [
          MealLog,
          Kati.Meals.MealPlanSlot,
          Kati.Meals.MealPlan,
          Kati.Meals.RecipeIngredient,
          Kati.Meals.Recipe
        ] do
      resource |> Ash.read!() |> Enum.each(&Ash.destroy!/1)
    end

    :ok
  end

  test "marking a planned meal eaten writes a log with the frozen figures" do
    %{plan: plan, slot: slot, recipe: recipe} = planned_dinner()

    view = mount_screen(Kati.Screens.MealsToday)
    meal = Enum.find(assigns(view).day.meals, &(&1[:slot_id] == slot.id))

    assert meal, "the planned slot did not reach the screen at all"
    assert meal.state == :next

    {:noreply, moved} =
      Kati.Screens.MealsToday.handle_info(
        {:tap, Kati.Screens.MealsToday.tag("mark_eaten", meal)},
        view.socket
      )

    logs = Ash.read!(MealLog)

    assert length(logs) == 1, "Mark eaten wrote #{length(logs)} rows"
    [log] = logs

    assert log.state == :eaten
    assert log.meal_plan_slot_id == slot.id
    assert log.meal_plan_id == plan.id

    # The figures are FROZEN at the moment of the claim — that is the whole
    # point of `:log_recipe`, and a row that copied nothing would be a row that
    # says the meal had no calories.
    assert log.kcal == recipe.total_kcal,
           "the log did not freeze the recipe's figures: #{log.kcal} vs #{recipe.total_kcal}"

    # And the screen redraws from the store rather than patching its socket.
    eaten = Enum.filter(moved.assigns.day.meals, &(&1.state == :eaten))
    assert length(eaten) == 1, "the card did not move to eaten after the write"
  end

  test "the button names its own meal, so two upcoming meals cannot collide" do
    # The failure this prevents is silent: with a bare tag, marking lunch eaten
    # would have written whichever row the handler found first.
    %{slot: dinner} = planned_dinner()
    %{slot: lunch} = planned_dinner(name: "Lunch", time: ~T[12:30:00], title: "Soup", position: 1)

    view = mount_screen(Kati.Screens.MealsToday)
    tags = Enum.map(assigns(view).day.meals, &Kati.Screens.MealsToday.tag("mark_eaten", &1))

    assert Enum.uniq(tags) == tags, "two meals share one tag: #{inspect(tags)}"
    assert String.to_atom("mark_eaten_" <> dinner.id) in tags
    assert String.to_atom("mark_eaten_" <> lunch.id) in tags
  end

  test "a day drawn from the board keeps the bare tag rather than one ending in nil" do
    # `Kati.Meals.SampleToday` is a transcription of the drawing, not rows, so
    # its meals have no slot id. `mark_eaten_nil` would be a worse name than
    # none at all.
    drawn = Kati.Screens.MealsToday.drawn_day()
    meal = Enum.find(drawn.meals, &(&1.state == :next))

    assert Kati.Screens.MealsToday.tag("mark_eaten", meal) == :mark_eaten
  end

  defp planned_dinner(opts \\ []) do
    # Built through the real pipeline rather than by typing totals into the
    # row. `Kati.Meals.Recipe`'s create deliberately does not accept the totals
    # columns — its own comment says an ordinary edit to a title must not be
    # able to rewrite a cached macro figure — so the figures come from an
    # ingredient, through `Kati.Meals.Totals.write_ingredient/2`, exactly as
    # they do when somebody types one in.
    recipe =
      Kati.Meals.Recipe
      |> Ash.Changeset.for_create(:create, %{
        title: Keyword.get(opts, :title, "Miso salmon"),
        minutes: 25,
        oven_c: 200,
        serves: 1
      })
      |> Ash.create!()

    {_ingredient, recipe} =
      Kati.Meals.Totals.write_ingredient(recipe, %{
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
        sodium_mg: 900
      })

    plan =
      case Kati.Meals.MealPlan |> Ash.Query.for_read(:active) |> Ash.read_one() do
        {:ok, %{} = existing} -> existing
        _none -> Ash.create!(Kati.Meals.MealPlan, %{name: "Cutting v3", status: :active})
      end

    slot =
      Ash.create!(Kati.Meals.MealPlanSlot, %{
        meal_plan_id: plan.id,
        recipe_id: recipe.id,
        day_of_week: Date.day_of_week(Kati.Time.today()),
        position: Keyword.get(opts, :position, 0),
        slot_name: Keyword.get(opts, :name, "Dinner"),
        slot_time: Keyword.get(opts, :time, ~T[19:30:00]),
        state: :planned,
        portion_milli: 1000
      })

    %{plan: plan, slot: slot, recipe: recipe}
  end
end
