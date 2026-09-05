defmodule Kati.MealSwapTest do
  @moduledoc """
  Screen 46 swaps a real meal for a real one.

  It drew three candidates from `Kati.Meals.SampleSwap` and its two commit
  buttons did nothing at all — so a swap could be chosen, priced and committed
  without anything changing. The board's own caption is the specification: *"A
  swap is only useful if it tells you what it costs"*, and a cost that is typed
  rather than computed is not a cost of anything.

  ## Two buttons, two different writes

  `Kati.Meals.MealLog`'s moduledoc already said which: a `:planned` log "is
  what screen 46's *swap just today* writes". So

    * **Swap just today** logs the candidate as `:planned` against the slot —
      a claim about a day, which is where a day's claims live.
    * **Every week** moves the slot onto the new recipe — the plan is what
      repeats, so a permanent swap is a change to the plan.

  A single write with a flag would have made "just today" and "every week" the
  same fact recorded twice.
  """
  use Mob.ScreenCase, async: false

  setup do
    clear!()
    on_exit(&clear!/0)
    :ok
  end

  test "the candidates are the meal library, ranked by what the swap costs" do
    %{slot: slot} = plan_with(dinner: 620, others: [{"Cod", 605}, {"Steak", 900}, {"Tofu", 640}])
    Kati.Screens.MealSwap.hand_over(slot.id)

    view = mount_screen(Kati.Screens.MealSwap)
    titles = Enum.map(view.socket.assigns.candidates, & &1.title)

    assert view.socket.assigns.replacing.title == "Dinner recipe",
           "the screen did not find the meal it is swapping"

    # Nearest first: Cod is 15 away, Tofu 20, Steak 280.
    assert titles == ["Cod", "Tofu", "Steak"], "ranked #{inspect(titles)}"

    [best | _rest] = view.socket.assigns.candidates
    assert best.badge == "BEST", "the closest candidate is not the one badged"
    assert best.delta == "−15 kcal", "the delta is not the difference: #{best.delta}"
  end

  test "swap just today logs the candidate as planned, and leaves the plan alone" do
    %{slot: slot} = plan_with(dinner: 620, others: [{"Cod", 605}])
    Kati.Screens.MealSwap.hand_over(slot.id)

    view = mount_screen(Kati.Screens.MealSwap)
    {:noreply, _moved} = Kati.Screens.MealSwap.handle_info({:tap, :swap_once}, view.socket)

    [log] = Ash.read!(Kati.Meals.MealLog)
    assert log.state == :planned, "swapping for today should PLAN, not eat"
    assert log.meal_plan_slot_id == slot.id

    unchanged = Ash.get!(Kati.Meals.MealPlanSlot, slot.id)

    assert unchanged.recipe_id == slot.recipe_id,
           "swapping just today changed the plan, which is what Every week is for"
  end

  test "every week moves the slot, and writes no log" do
    %{slot: slot} = plan_with(dinner: 620, others: [{"Cod", 605}])
    Kati.Screens.MealSwap.hand_over(slot.id)

    view = mount_screen(Kati.Screens.MealSwap)
    cod = hd(view.socket.assigns.candidates)

    {:noreply, _moved} = Kati.Screens.MealSwap.handle_info({:tap, :swap_forever}, view.socket)

    moved_slot = Ash.get!(Kati.Meals.MealPlanSlot, slot.id)
    assert moved_slot.recipe_id == cod.id, "the plan still points at the old recipe"

    assert Ash.read!(Kati.Meals.MealLog) == [],
           "a permanent swap also logged a day, so the same fact is recorded twice"
  end

  test "with no slot handed over it is the drawing, and neither button writes" do
    # Reached from the gallery rather than from screen 43, which is the only
    # way to arrive here without a meal to swap. Committing would be committing
    # a swap of nothing.
    Kati.Screens.MealSwap.hand_over("")

    view = mount_screen(Kati.Screens.MealSwap)
    assert view.socket.assigns.slot_id == nil

    for tag <- [:swap_once, :swap_forever] do
      {:noreply, moved} = Kati.Screens.MealSwap.handle_info({:tap, tag}, view.socket)
      assert moved.__mob__.nav_action == nil, "#{tag} navigated away from a swap of nothing"
    end

    assert Ash.read!(Kati.Meals.MealLog) == []
  end

  describe "screen 45's bookmark disc" do
    test "bookmarks the recipe, and un-bookmarks it" do
      # The board has drawn this disc since the screen was built and
      # `Kati.Meals.Recipe` had no column to hold the answer, so the tap sat on
      # the sweep's backlog under "a button that never marks anything". A
      # toggle rather than an add-only action: the disc is the same disc either
      # way, and a control that can only be pressed once lies the second time.
      %{slot: slot, dinner: dinner} = plan_with(dinner: 620, others: [])
      _ = slot

      view = mount_screen(Kati.Screens.Meal)
      refute view.socket.assigns.meal.bookmarked

      {:noreply, on} = Kati.Screens.Meal.handle_info({:tap, :save}, view.socket)
      assert on.assigns.meal.bookmarked
      assert Ash.get!(Kati.Meals.Recipe, dinner.id).bookmarked

      {:noreply, off} = Kati.Screens.Meal.handle_info({:tap, :save}, on)
      refute off.assigns.meal.bookmarked
      refute Ash.get!(Kati.Meals.Recipe, dinner.id).bookmarked
    end

    test "on the drawing there is no recipe, so nothing is written" do
      view = mount_screen(Kati.Screens.Meal)
      refute view.socket.assigns.meal[:recipe_id]

      {:noreply, moved} = Kati.Screens.Meal.handle_info({:tap, :save}, view.socket)

      refute moved.assigns.meal[:bookmarked],
             "the drawn page pretended to bookmark a meal that does not exist"
    end
  end

  defp plan_with(opts) do
    plan = Ash.create!(Kati.Meals.MealPlan, %{name: "Cutting v3", status: :active})
    dinner = recipe!("Dinner recipe", Keyword.fetch!(opts, :dinner))

    for {title, kcal} <- Keyword.get(opts, :others, []), do: recipe!(title, kcal)

    slot =
      Ash.create!(Kati.Meals.MealPlanSlot, %{
        meal_plan_id: plan.id,
        recipe_id: dinner.id,
        day_of_week: Date.day_of_week(Kati.Time.today()),
        position: 0,
        slot_name: "Dinner",
        slot_time: ~T[19:30:00],
        state: :planned,
        portion_milli: 1000
      })

    %{plan: plan, slot: slot, dinner: dinner}
  end

  defp recipe!(title, kcal) do
    recipe =
      Kati.Meals.Recipe
      |> Ash.Changeset.for_create(:create, %{title: title, minutes: 20, serves: 1})
      |> Ash.create!()

    {_ingredient, recipe} =
      Kati.Meals.Totals.write_ingredient(recipe, %{
        position: 0,
        name: "Everything",
        amount_mg: 100_000,
        unit: :g,
        aisle: :fish_and_meat,
        kcal: kcal,
        protein_mg: 40_000,
        carbs_mg: 50_000,
        fat_mg: 15_000,
        fibre_mg: 0,
        sugar_mg: 0,
        sodium_mg: 100
      })

    recipe
  end

  defp clear! do
    Kati.Screens.MealSwap.hand_over("")

    for resource <- [
          Kati.Meals.MealLog,
          Kati.Meals.MealPlanSlot,
          Kati.Meals.MealPlan,
          Kati.Meals.RecipeIngredient,
          Kati.Meals.Recipe
        ] do
      resource |> Ash.read!() |> Enum.each(&Ash.destroy!/1)
    end
  end
end
