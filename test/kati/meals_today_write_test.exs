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

  # Both halves of a card's identity, run as documentation: `tag/2` names the
  # two buttons on the lifted card and `meal_tag/1` names the card itself.
  # Every one of them takes its name from the ROW, which is what stops a
  # write reaching a meal the reader was not pressing.
  doctest Kati.Screens.MealsToday, only: [tag: 2, meal_tag: 1]

  # Cleared BEFORE and AFTER, and the second half is not tidiness.
  #
  # This file shares one database with every other test in the suite, and the
  # rows it writes are a plan with a slot on today — which is exactly what
  # `Kati.Screens.MealsToday` and `Kati.Screens.Meal` look for before they fall
  # back to their drawings. Left behind, they make screens 43 and 45 draw real
  # data during `Kati.ScreenDesignLiteralTest`, which then fails to find the
  # board's own literals.
  #
  # It failed on some seeds and passed on others, which is the worst version of
  # this: the suite was green twice out of three runs and the cause was a file
  # that had already finished.
  setup do
    clear!()
    on_exit(&clear!/0)
    :ok
  end

  defp clear! do
    for resource <- [
          MealLog,
          Kati.Meals.MealPlanSlot,
          Kati.Meals.MealPlan,
          Kati.Meals.RecipeIngredient,
          Kati.Meals.Recipe
        ] do
      resource |> Ash.read!() |> Enum.each(&Ash.destroy!/1)
    end
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

  describe "screen 45 marks the same meal the same way" do
    test "Mark eaten on the detail page writes a log, not a socket flag" do
      # It used to flip `:eaten` on the socket — a tick that drew, survived
      # until the screen was popped, and left nothing behind. A control that
      # looks like it worked is worse than one that plainly does not.
      #
      # Asserted through the same action screen 43 uses, because two screens
      # that mean "I ate this" must not be able to disagree about what it does.
      %{slot: slot} = planned_dinner()

      view = mount_screen(Kati.Screens.Meal)
      assert view.socket.assigns.meal[:slot_id] == slot.id, "45 did not find the planned slot"

      {:noreply, moved} = Kati.Screens.Meal.handle_info({:tap, :mark_eaten}, view.socket)

      logs = Ash.read!(MealLog)
      assert length(logs) == 1, "the detail page wrote #{length(logs)} rows"
      assert hd(logs).state == :eaten
      assert hd(logs).meal_plan_slot_id == slot.id
      assert moved.assigns.meal.eaten
    end

    test "with no plan it is the drawing, and the tick stays local" do
      # `Kati.Meals.SampleRecipe` is a transcription of board 45, not rows.
      # Writing a log for a meal nobody planned would be inventing the row it
      # then displayed.
      view = mount_screen(Kati.Screens.Meal)
      refute view.socket.assigns.meal[:slot_id]

      {:noreply, moved} = Kati.Screens.Meal.handle_info({:tap, :mark_eaten}, view.socket)

      assert Ash.read!(MealLog) == []
      assert moved.assigns.meal.eaten, "the drawn page stopped acknowledging the tap at all"
    end
  end

  test "a day with one planned meal shows one card, not the drawing's five" do
    # FIDELITY's rule cuts both ways. Nothing planned is the drawing whole; a
    # day with one real meal is ONE meal, and never one real card under the
    # drawing's `· 5 meals`.
    %{slot: slot} = planned_dinner()

    view = mount_screen(Kati.Screens.MealsToday)
    day = assigns(view).day

    assert [%{slot_id: id}] = day.meals
    assert id == slot.id
    assert day.day_line =~ "· 1 meal"
    refute day.day_line =~ "5 meals"
    assert day.plan == "Cutting v3"

    for drawn <- Kati.Screens.MealsToday.drawn_day().meals do
      refute Enum.any?(day.meals, &(&1.title == drawn.title)),
             "the drawing's #{drawn.title} is still on a real day"
    end
  end

  test "the third card opens the third slot" do
    # Assertion 2's own limit, met head on: two ids that name nothing render
    # identically, so proving a screen distinguishes its rows needs real rows.
    # Driven through the screen's own `handle_info/2`, never asserted about it.
    planned_dinner(name: "Breakfast", time: ~T[07:30:00], title: "Oats", position: 0)
    planned_dinner(name: "Lunch", time: ~T[12:30:00], title: "Soup", position: 1)

    %{slot: third} =
      planned_dinner(name: "Dinner", time: ~T[19:30:00], title: "Salmon", position: 2)

    view = mount_screen(Kati.Screens.MealsToday)
    meals = assigns(view).day.meals
    assert length(meals) == 3

    tags = Enum.map(meals, &Kati.Screens.MealsToday.meal_tag/1)
    assert Enum.uniq(tags) == tags, "two cards share one tag: #{inspect(tags)}"

    {:noreply, moved} =
      Kati.Screens.MealsToday.handle_info(
        {:tap, Kati.Screens.MealsToday.meal_tag(Enum.at(meals, 2))},
        view.socket
      )

    assert {:push, Kati.Screens.Meal, %{slot_id: named}} = moved.__mob__.nav_action
    assert named == third.id, "the third card opened somebody else's meal"

    # And screen 45 draws the meal it was named, rather than its own next.
    page = mount_screen(Kati.Screens.Meal, %{slot_id: third.id})
    assert assigns(page).meal.title == "Salmon"
  end

  describe "Swap acts on the card that was pressed" do
    test "two upcoming meals get two Swap buttons with two names" do
      # The defect: **Swap** was tagged `:swap` on every card, and
      # `handle_tap(:swap, …)` resolved it by taking the FIRST upcoming meal
      # it could find. A day with lunch and dinner still ahead drew two Swap
      # buttons under one name; tapping dinner's handed screen 46 the lunch.
      # Screen 79's defect, one domain over — and two nodes with one
      # `accessibility_id`, which is separately unaddressable on a device.
      %{slot: lunch} =
        planned_dinner(name: "Lunch", time: ~T[12:30:00], title: "Soup", position: 0)

      %{slot: dinner} =
        planned_dinner(name: "Dinner", time: ~T[19:30:00], title: "Salmon", position: 1)

      view = mount_screen(Kati.Screens.MealsToday)
      meals = assigns(view).day.meals

      tags = Enum.map(meals, &Kati.Screens.MealsToday.tag("swap", &1))
      assert Enum.uniq(tags) == tags, "two Swap buttons share one tag: #{inspect(tags)}"
      assert String.to_atom("swap_" <> lunch.id) in tags
      assert String.to_atom("swap_" <> dinner.id) in tags

      # The SECOND card's button hands over the SECOND slot. On the old code
      # this handed over the lunch, because the lunch led the timeline.
      {:noreply, moved} =
        Kati.Screens.MealsToday.handle_info(
          {:tap, String.to_atom("swap_" <> dinner.id)},
          view.socket
        )

      assert Kati.Screens.MealSwap.handed_over() == dinner.id,
             "Swap followed whoever led the timeline rather than the card pressed"

      assert {:push, Kati.Screens.MealSwap, _} = moved.__mob__.nav_action
    end

    test "a tag naming a slot the page never drew hands nothing over, and still opens 46" do
      # The other half of pinning: the id is resolved against the rows THIS
      # render drew. A slot deleted since — or one that was never on this
      # day — finds nothing, and a page that resolved nothing refuses to name
      # anybody rather than falling back to the timeline's head.
      %{slot: lunch} = planned_dinner(name: "Lunch", time: ~T[12:30:00], title: "Soup")

      view = mount_screen(Kati.Screens.MealsToday)
      Kati.Screens.MealSwap.hand_over(lunch.id)

      gone = Ash.UUID.generate()

      {:noreply, moved} =
        Kati.Screens.MealsToday.handle_info({:tap, String.to_atom("swap_" <> gone)}, view.socket)

      assert Kati.Screens.MealSwap.handed_over() == lunch.id,
             "a tag naming nothing overwrote the handover with a guess"

      assert {:push, Kati.Screens.MealSwap, _} = moved.__mob__.nav_action
    end

    test "the drawn day keeps the bare tag and hands nothing over at all" do
      drawn = Kati.Screens.MealsToday.drawn_day()
      meal = Enum.find(drawn.meals, &(&1.state == :next))

      assert Kati.Screens.MealsToday.tag("swap", meal) == :swap

      view = mount_screen(Kati.Screens.MealsToday)
      assert assigns(view).day == drawn, "expected the drawing with nothing planned"

      {:noreply, moved} = Kati.Screens.MealsToday.handle_info({:tap, :swap}, view.socket)

      assert Kati.Screens.MealSwap.handed_over() == nil,
             "a page drawing a board named a slot it does not have"

      assert {:push, Kati.Screens.MealSwap, _} = moved.__mob__.nav_action
    end
  end

  describe "a logged meal keeps its place in the day" do
    test "Mark eaten carries the slot's name and clock onto the snapshot" do
      # `:log_recipe` did not accept `slot_name` or `slot_time` and neither
      # screen passed them, so a `Dinner · 19:30` card came back with a blank
      # time gutter and no eyebrow — and then sorted to the BOTTOM of the day,
      # because `timeline_rows/2` orders a timeless row last. It also answered
      # `meal_tag/1` with the bare `:open_meal`, so the row stopped being able
      # to name itself the instant it was logged.
      %{slot: slot} = planned_dinner(name: "Dinner", time: ~T[19:30:00])

      view = mount_screen(Kati.Screens.MealsToday)
      before = Enum.find(assigns(view).day.meals, &(&1[:slot_id] == slot.id))
      assert before.time == "19:30"
      assert before.slot == "Dinner"

      {:noreply, moved} =
        Kati.Screens.MealsToday.handle_info(
          {:tap, Kati.Screens.MealsToday.tag("mark_eaten", before)},
          view.socket
        )

      [log] = Ash.read!(MealLog)
      assert log.slot_name == "Dinner"
      assert log.slot_time == ~T[19:30:00]

      [card] = moved.assigns.day.meals
      assert card.state == :eaten
      assert card.time == "19:30", "the logged card lost its clock"
      assert card.slot == "Dinner", "the logged card lost its eyebrow"
      # And it can still name itself — now by the slot's own id rather than by
      # the word and the clock. Two `Snack` rows at 16:00 shared one tag under
      # the old form, so the second card opened the first; `meal_tag/1` says
      # why it changed. What this test is about is unchanged: a logged row keeps
      # its place and its name in the day.
      assert Kati.Screens.MealsToday.meal_tag(card) == String.to_atom("meal_" <> slot.id)
      refute Kati.Screens.MealsToday.meal_tag(card) == :open_meal
    end

    test "two rows at the same time and slot are two different cards" do
      # `meal_tag/1` was built from the slot word and the clock, so a day with
      # two `Snack` rows at 16:00 named both of them `meal_Snack_16:00`. The
      # second card opened the first — the defect this whole phase is about, one
      # layer below the push, and invisible to every test because no fixture had
      # two rows at one time.
      %{slot: first} = planned_dinner(name: "Snack", time: ~T[16:00:00], title: "Apple")

      %{slot: second} =
        planned_dinner(name: "Snack", time: ~T[16:00:00], title: "Pear", position: 1)

      view = mount_screen(Kati.Screens.MealsToday)
      tags = Enum.map(assigns(view).day.meals, &Kati.Screens.MealsToday.meal_tag/1)

      assert length(Enum.uniq(tags)) == length(tags), "two cards share one tag: #{inspect(tags)}"
      assert String.to_atom("meal_" <> first.id) in tags
      assert String.to_atom("meal_" <> second.id) in tags
    end

    test "a swapped meal's buttons name their own row" do
      # `log_row/1` blanked `slot_id` on every logged row, on the reasoning that
      # a logged meal has nothing left to write. But `card_state/1` answers
      # `:next` for anything that is not eaten or skipped, and screen 46's *swap
      # just today* writes a `:planned` log — so a swapped meal drew as
      # upcoming, drew both write buttons, and neither could name the row under
      # it. Mark eaten did nothing; Swap handed over whatever `Mob.State` still
      # held.
      %{slot: slot} = planned_dinner(name: "Dinner", time: ~T[19:30:00], title: "Salmon")

      %{recipe: swapped_to} =
        planned_dinner(name: "Lunch", time: ~T[13:00:00], title: "Tofu bowl", position: 1)

      Kati.Screens.MealSwap.write(slot.id, %{id: swapped_to.id, title: swapped_to.title}, :once)

      view = mount_screen(Kati.Screens.MealsToday)
      card = Enum.find(assigns(view).day.meals, &(&1[:slot_id] == slot.id))

      assert card, "the swapped card is not on the day at all"
      assert card.state == :next, "the fixture no longer sets up the case this is about"
      assert card.title == "Tofu bowl", "the swap did not take"
      assert card.slot_id == slot.id, "a swapped card cannot name the slot it is for"
      assert Kati.Screens.MealsToday.tag("swap", card) == String.to_atom("swap_" <> slot.id)

      assert Kati.Screens.MealsToday.tag("mark_eaten", card) ==
               String.to_atom("mark_eaten_" <> slot.id)
    end

    test "an eaten breakfast stays above an unplanned dinner rather than sinking" do
      %{slot: breakfast} = planned_dinner(name: "Breakfast", time: ~T[07:30:00], title: "Oats")
      planned_dinner(name: "Dinner", time: ~T[19:30:00], title: "Salmon", position: 1)

      view = mount_screen(Kati.Screens.MealsToday)
      meal = Enum.find(assigns(view).day.meals, &(&1[:slot_id] == breakfast.id))

      {:noreply, moved} =
        Kati.Screens.MealsToday.handle_info(
          {:tap, Kati.Screens.MealsToday.tag("mark_eaten", meal)},
          view.socket
        )

      assert Enum.map(moved.assigns.day.meals, & &1.time) == ["07:30", "19:30"]
      assert Enum.map(moved.assigns.day.meals, & &1.state) == [:eaten, :next]
    end

    test "screen 46's swap-just-today keeps the slot's place on the timeline too" do
      # The third writer of `:log_recipe`, and the rule has to hold at all
      # three. `timeline_rows/2` lays a log OVER the slot it belongs to, so a
      # log with no `slot_name` and no `slot_time` replaced the card's
      # `Dinner` and `19:30` with blanks — and then sank the swapped meal to
      # the bottom of the day, because a timeless row sorts last.
      %{slot: slot} = planned_dinner(name: "Dinner", time: ~T[19:30:00], title: "Salmon")

      alt =
        Kati.Meals.Recipe
        |> Ash.Changeset.for_create(:create, %{title: "Tofu bowl", serves: 1})
        |> Ash.create!()

      Kati.Screens.MealSwap.write(slot.id, %{id: alt.id, title: alt.title}, :once)

      view = mount_screen(Kati.Screens.MealsToday)

      assert [card] = assigns(view).day.meals
      assert card.title == "Tofu bowl"
      assert card.time == "19:30", "the swapped meal lost the slot's clock"
      assert card.slot == "Dinner", "the swapped meal lost the slot's eyebrow"
    end

    test "screen 45's Mark eaten writes the same snapshot as screen 43's" do
      # One function, `Kati.Meals.MealLog.log_eaten/1`, because two screens
      # that mean *I ate this* must not be able to write two different rows —
      # and because the two hand-spelled copies both lost the same two fields.
      %{slot: slot} = planned_dinner(name: "Dinner", time: ~T[19:30:00])

      view = mount_screen(Kati.Screens.Meal)
      assert assigns(view).meal[:slot_id] == slot.id

      {:noreply, _} = Kati.Screens.Meal.handle_info({:tap, :mark_eaten}, view.socket)

      [log] = Ash.read!(MealLog)
      assert log.slot_name == "Dinner"
      assert log.slot_time == ~T[19:30:00]
      assert log.meal_plan_slot_id == slot.id
    end
  end

  describe "Mark eaten acts on the row the page drew" do
    test "it writes the tapped slot, not the newest one" do
      # The rule this whole phase is about: a write acts on what the page drew.
      # `Enum.find` over `socket.assigns.day.meals` and never a fresh read —
      # so a slot created after the render cannot take the log, however new it
      # is.
      %{slot: drawn} = planned_dinner(name: "Lunch", time: ~T[12:30:00], title: "Soup")

      view = mount_screen(Kati.Screens.MealsToday)
      meal = Enum.find(assigns(view).day.meals, &(&1[:slot_id] == drawn.id))

      # A newer slot lands after the render and is NOT on this page.
      %{slot: newest} =
        planned_dinner(name: "Dinner", time: ~T[19:30:00], title: "Salmon", position: 1)

      {:noreply, _} =
        Kati.Screens.MealsToday.handle_info(
          {:tap, Kati.Screens.MealsToday.tag("mark_eaten", meal)},
          view.socket
        )

      [log] = Ash.read!(MealLog)
      assert log.meal_plan_slot_id == drawn.id
      refute log.meal_plan_slot_id == newest.id
      assert log.title == "Soup"
    end

    test "a row that went between the render and the finger writes nothing" do
      %{slot: slot} = planned_dinner()

      view = mount_screen(Kati.Screens.MealsToday)
      meal = Enum.find(assigns(view).day.meals, &(&1[:slot_id] == slot.id))
      tag = Kati.Screens.MealsToday.tag("mark_eaten", meal)

      # The row goes after the render. The page is still drawing it and the
      # tag still names it, so the write IS attempted — against that slot and
      # no other, which is the point: the foreign key refuses it rather than
      # some fallback quietly landing the log on the day's head.
      Ash.destroy!(slot)

      {:noreply, moved} = Kati.Screens.MealsToday.handle_info({:tap, tag}, view.socket)

      assert Ash.read!(MealLog) == [], "an orphan log survived a slot that was gone"

      # And with the plan now empty the page is honest again: the drawing,
      # whole, rather than a blank timeline.
      assert moved.assigns.day == Kati.Screens.MealsToday.drawn_day()
    end

    test "screen 45 named a slot that is gone draws the fixture and refuses its write" do
      # `Kati.Screens.BookDetail.book/1`'s distinction, one domain over.
      # `meal/2` used to collapse *nobody named a slot* and *the named slot is
      # gone* into one value — `next_meal/1`, the earliest unlogged slot TODAY
      # — so a card whose dinner had been dropped from the plan opened on the
      # LUNCH, drew the lunch's title and macros, and logged the lunch when
      # the reader pressed Mark eaten. You named one meal and the app ate
      # another.
      %{slot: lunch} = planned_dinner(name: "Lunch", time: ~T[12:30:00], title: "Soup")

      %{slot: dinner} =
        planned_dinner(name: "Dinner", time: ~T[19:30:00], title: "Salmon", position: 1)

      Ash.destroy!(dinner)

      view = mount_screen(Kati.Screens.Meal, %{slot_id: dinner.id})
      meal = assigns(view).meal

      assert meal.title == Kati.Screens.Meal.drawn_meal().title,
             "45 fell through to #{inspect(meal.title)} instead of the drawing"

      refute meal[:slot_id], "the drawing carried a slot id"
      refute meal[:recipe_id]

      {:noreply, moved} = Kati.Screens.Meal.handle_info({:tap, :mark_eaten}, view.socket)

      assert Ash.read!(MealLog) == [],
             "a page that could not name what it drew still wrote a log"

      refute Enum.any?(Ash.read!(MealLog), &(&1.meal_plan_slot_id == lunch.id))

      # The tick is local, which is the honest thing a board-shaped page can
      # do with the tap — the same answer the gallery's own no-id page gives.
      assert moved.assigns.meal.eaten
    end

    test "naming NOTHING is still the day's next meal, which is the drawn path" do
      # The other half of the distinction, and the half that must not move:
      # `Kati.Screens.Gallery` opens 45 with `%{}` and
      # `test/design/screens/45.html` was captured in that state.
      %{slot: lunch} = planned_dinner(name: "Lunch", time: ~T[12:30:00], title: "Soup")

      view = mount_screen(Kati.Screens.Meal, %{})
      assert assigns(view).meal[:slot_id] == lunch.id

      empty = mount_screen(Kati.Screens.Meal, %{})
      assert assigns(empty).meal.title == "Soup"
    end

    test "a tag naming a slot this page never drew writes nothing" do
      planned_dinner()

      view = mount_screen(Kati.Screens.MealsToday)
      gone = Ash.UUID.generate()

      {:noreply, moved} =
        Kati.Screens.MealsToday.handle_info(
          {:tap, String.to_atom("mark_eaten_" <> gone)},
          view.socket
        )

      assert Ash.read!(MealLog) == [], "a tag naming nothing still wrote a log"
      assert moved.assigns.day == assigns(view).day
    end

    test "nothing planned is the drawing whole, and its Mark eaten writes nothing" do
      view = mount_screen(Kati.Screens.MealsToday)

      assert assigns(view).day == Kati.Screens.MealsToday.drawn_day()

      {:noreply, moved} = Kati.Screens.MealsToday.handle_info({:tap, :mark_eaten}, view.socket)

      assert Ash.read!(MealLog) == []
      assert moved.assigns.day == Kati.Screens.MealsToday.drawn_day()
    end
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
