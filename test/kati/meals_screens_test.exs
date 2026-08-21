defmodule Kati.MealsScreensTest do
  @moduledoc """
  The five Meals screens, read off the domain and off the drawing.

  Every one of them used to call a `Kati.Meals.Sample*` module from inside its
  markup, so the screen and its data were the same file and there was nothing
  to be wrong about. They now query `Kati.Meals`, which opens two failures at
  once and this file asserts both halves of each:

    * **The rows are ignored.** A screen that still draws `Cutting v3` with the
      user's own plan in the database looks perfect and is a lie. Every "with
      rows" test below therefore asserts the drawn string is **gone** as well
      as that the real one is there — a `=~` on the real value alone passes
      against a screen that draws both.
    * **The screen empties.** These screens are also the design reference, and
      a fresh install has no plan at all. Every "with nothing" test asserts the
      sample's own strings, by value, because that is what
      `.scratch/design/audit/NN.png` was captured from.

  ## Why the fixtures are built and torn down by hand

  There is no sandbox: `test/test_helper.exs` migrates one real SQLite file and
  every test in the run shares it. `meal_plans` also carries a partial unique
  index permitting exactly one active row, so a test that leaves an active plan
  behind does not fail here — it fails in whichever file runs next, by drawing
  a screen full of this file's fixtures. `on_exit/1` therefore destroys
  everything in reverse dependency order, and the "with nothing" tests assert
  the drawing precisely so that a leak is caught immediately.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Meals.MealLog
  alias Kati.Meals.MealPlan
  alias Kati.Meals.MealPlanSlot
  alias Kati.Meals.Recipe
  alias Kati.Meals.SampleShopping
  alias Kati.Meals.SampleToday
  alias Kati.Meals.ShoppingListItem
  alias Kati.Screens
  alias Kati.Theme.Palette

  # The screens read `Kati.Time.today/0` at mount, so the fixtures have to be
  # written on the day they will be read on. Taken once here rather than per
  # call so that a fixture and the assertion about it cannot land on opposite
  # sides of a midnight.
  @today Kati.Time.today()

  # A meal logged under no plan at all, five weeks back. Named so the teardown
  # can find it: it is the one fixture row that is not on today's date.
  @stray "Fixture stray meal"

  # Screen 43's five slots, at the drawing's own times, so the row the merge
  # produces can be compared with the row the drawing produces.
  @slots [
    {0, "Breakfast", ~T[07:30:00]},
    {1, "Snack", ~T[10:30:00]},
    {2, "Lunch", ~T[13:00:00]},
    {3, "Snack", ~T[16:00:00]},
    {4, "Dinner", ~T[19:30:00]}
  ]

  setup do
    # Whatever an earlier file left standing. A single active plan is all it
    # takes to turn every "with nothing" assertion below into a comparison
    # against someone else's fixture — and a single meal logged on today's date
    # by another file is a sixth card on screen 43 and a fourth green pip.
    stand_down_all()
    destroy_where(MealLog, &(&1.logged_on == @today))
    on_exit(&cleanup/0)
    :ok
  end

  describe "screen 43 with nothing in the database" do
    test "draws the day the design drew, string for string" do
      drawn = text(tree(mount_screen(Screens.MealsToday)))

      assert drawn =~ SampleToday.day_line()
      assert drawn =~ SampleToday.plan()
      # `Kati.UI.eyebrow/1` upper-cases what it is given, so the intake line is
      # compared in the case the screen actually draws it in.
      assert drawn =~ String.upcase(SampleToday.intake_line())
      assert drawn =~ SampleToday.remaining()
      assert drawn =~ SampleToday.prep().title

      for meal <- SampleToday.meals() do
        assert drawn =~ meal.title
        assert drawn =~ meal.time
      end

      assert drawn =~ "SKIPPED"
    end

    test "draws five meals, one card each" do
      # The 44pt time gutter is one column per row, so it counts the rows the
      # timeline actually built — a fallback that lost the merge would still
      # draw the titles from somewhere and lose these.
      gutters = find_all(tree(mount_screen(Screens.MealsToday)), :column, width: 44)

      assert length(gutters) == length(SampleToday.meals())
    end

    test "draws the drawing's five pips on every day of the strip" do
      cells = find_all(tree(mount_screen(Screens.MealsToday)), :box, width: 3, height: 3)

      assert length(cells) == 35,
             "the week strip drew #{length(cells)} pips. Seven days at five " <>
               "slots each is 35, and a strip that fell back to a plan with no " <>
               "slots draws none of them."
    end
  end

  describe "screen 43 with a plan and a logged day" do
    setup :a_logged_day

    test "draws the user's meals, and none of the drawing's" do
      drawn = text(tree(mount_screen(Screens.MealsToday)))

      assert drawn =~ "Porridge and figs"
      assert drawn =~ "Lentil soup"
      assert drawn =~ "07:30"
      assert drawn =~ "19:30"

      # The evening slot has no log yet, so its card is the plan's recipe and
      # the recipe's own cached total — the `:next` card, which is the one
      # state on this screen that is not a row in `meal_logs`.
      assert drawn =~ "Fixture baked cod"
      assert drawn =~ "620 kcal"

      # The skipped slot keeps its card and loses its number.
      assert drawn =~ "SKIPPED"

      for meal <- SampleToday.meals() do
        refute drawn =~ meal.title
      end

      refute drawn =~ SampleToday.plan()
      refute drawn =~ SampleToday.day_line()
    end

    test "the plan pill and the day line come off the plan and the day" do
      drawn = text(tree(mount_screen(Screens.MealsToday)))

      assert drawn =~ "Screens fixture plan"
      assert drawn =~ Calendar.strftime(@today, "%A %-d %B") <> " · 5 meals"
    end

    test "the intake line and what is left come off the logs and the target" do
      drawn = text(tree(mount_screen(Screens.MealsToday)))

      # 400 + 300 + 500 eaten; the skipped 200 does not count, and neither does
      # the dinner that has not happened.
      assert drawn =~ String.upcase("Today · 1,200 of 2,100 kcal")
      assert drawn =~ "900 kcal left"
    end

    test "today's pips are the meals eaten, not the meals planned" do
      tree = tree(mount_screen(Screens.MealsToday))

      green = find_all(tree, :box, width: 3, height: 3, background: Palette.green())
      planned = find_all(tree, :box, width: 3, height: 3, background: Palette.rail_idle())

      assert length(green) == 3,
             "three meals were eaten today and #{length(green)} pips are green"

      # Six other days of the same five-slot plan.
      assert length(planned) == 30
      assert length(find_all(tree, :box, width: 3, height: 3)) == 35
    end

    test "the macro bar is the day's own split" do
      %{macros: macros} = Screens.MealsToday.day(@today)

      assert [{"Protein", protein, _}, {"Carbs", carbs, _}, {"Fat", fat, _}] = macros

      # 60 g protein and 120 g carbs at 4 kcal a gram, 30 g fat at 9:
      # 240 + 480 + 270 = 990 kcal of macros.
      assert protein == 0.24
      assert carbs == 0.48
      assert fat == 0.27
      assert_in_delta protein + carbs + fat, 1.0, 0.011
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Screens.MealsToday))
    end
  end

  describe "screen 48 with nothing in the database" do
    test "draws the shopping list the design drew" do
      drawn = text(tree(mount_screen(Screens.Shopping)))
      list = SampleShopping.list()

      assert drawn =~ list.subtitle
      assert drawn =~ list.basket
      assert drawn =~ list.estimate

      for aisle <- list.aisles do
        assert drawn =~ String.upcase(aisle.name)

        for item <- aisle.items do
          assert drawn =~ item.name
          assert drawn =~ item.amount
          assert drawn =~ item.meals
        end
      end
    end

    test "draws a tick box for every line, four of them ticked" do
      tree = tree(mount_screen(Screens.Shopping))
      items = SampleShopping.aisles() |> Enum.flat_map(& &1.items)
      got = Enum.count(items, & &1.got)

      assert length(find_all(tree, :box, width: 22, height: 22)) == length(items)

      assert length(find_all(tree, :box, width: 22, height: 22, background: Palette.ink_fill())) ==
               got
    end
  end

  describe "screen 48 with a week of items" do
    setup :a_shopping_week

    test "draws the user's lines, grouped into the aisles they are on" do
      drawn = text(tree(mount_screen(Screens.Shopping)))

      assert drawn =~ "Rye bread"
      assert drawn =~ "Cod fillet"
      assert drawn =~ "Red lentils"

      # `Kati.UI.SettingsList.eyebrow_muted/1` upper-cases the aisle heading.
      assert drawn =~ "BAKERY"
      assert drawn =~ "FISH & MEAT"
      assert drawn =~ "CUPBOARD"

      for aisle <- SampleShopping.aisles(), item <- aisle.items do
        refute drawn =~ item.name
      end
    end

    test "counts the basket and the week from the rows" do
      drawn = text(tree(mount_screen(Screens.Shopping)))
      monday = Date.add(@today, -(Date.day_of_week(@today) - 1))

      assert drawn =~ "week of #{Calendar.strftime(monday, "%-d %b")} · 3 items"
      assert drawn =~ "1 of 3 in the basket"
      refute drawn =~ SampleShopping.list().basket
    end

    test "the amounts are the stored thousandths, in the shop's own words" do
      drawn = text(tree(mount_screen(Screens.Shopping)))

      assert drawn =~ "1 kg"
      assert drawn =~ "600 g"
      assert drawn =~ "×2"
    end

    test "the estimate is the sum of the lines that carry a price" do
      drawn = text(tree(mount_screen(Screens.Shopping)))

      # 2.40 + 6.10; the third line has no price and adds nothing.
      assert drawn =~ "£8.50 est."
      refute drawn =~ SampleShopping.list().estimate
    end

    test "the aisles are walked in shopping order, not alphabetically" do
      %{aisles: aisles} = Screens.Shopping.list(@today)

      assert Enum.map(aisles, & &1.name) == ["Bakery", "Fish & meat", "Cupboard"]
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Screens.Shopping))
    end
  end

  describe "screen 44 with nothing in the database" do
    test "draws the week the design drew" do
      drawn = text(tree(mount_screen(Screens.MealPlan)))
      sample = Kati.Meals.SamplePlan

      assert drawn =~ sample.title()
      assert drawn =~ sample.subtitle()
      assert drawn =~ String.upcase(sample.day_line())

      for row <- sample.day() do
        assert drawn =~ row.title
        assert drawn =~ String.upcase(row.slot)
      end

      for row <- sample.repeat_rule() do
        assert drawn =~ row.title
        assert drawn =~ row.sub
      end
    end

    test "draws 35 cells, and inks the column the list below shows" do
      tree = tree(mount_screen(Screens.MealPlan))

      assert length(find_all(tree, :box, height: 37, corner_radius: 9)) == 35

      # Sunday, the day the drawing's list is of — and the last column, which
      # is what makes the fallback the drawing rather than today's week.
      assert Screens.MealPlan.drawn_plan().today == 6
    end
  end

  describe "screen 44 with a plan on the database" do
    setup :a_logged_day

    test "draws the plan's own name, week and meals" do
      drawn = text(tree(mount_screen(Screens.MealPlan)))
      sample = Kati.Meals.SamplePlan

      assert drawn =~ "Screens fixture plan"
      assert drawn =~ "repeats every week"
      assert drawn =~ String.upcase("#{Calendar.strftime(@today, "%A")} · 5 meals")

      # Five slots, five recipes, listed under the matrix.
      assert drawn =~ "Fixture breakfast"
      assert drawn =~ "Fixture lunch"
      assert drawn =~ "Fixture baked cod"
      assert drawn =~ String.upcase("Dinner · 19:30")

      refute drawn =~ sample.title()

      for row <- sample.day() do
        refute drawn =~ row.title
      end
    end

    test "inks today's column, and only today's" do
      tree = tree(mount_screen(Screens.MealPlan))

      cells = find_all(tree, :box, height: 37, corner_radius: 9)
      inked = find_all(tree, :box, height: 37, corner_radius: 9, background: Palette.ink())

      assert length(cells) == 35

      assert length(inked) == 5,
             "#{length(inked)} cells are inked. `:today` is one column of five " <>
               "slots, computed from the calendar — `Kati.Meals.MealPlanSlot` " <>
               "stores no such state, and 35 inked cells is what reading one " <>
               "would look like."

      assert Screens.MealPlan.plan(@today).today == Date.day_of_week(@today) - 1
    end

    test "the repeat rule is the plan's own rule" do
      drawn = text(tree(mount_screen(Screens.MealPlan)))
      started = Calendar.strftime(Date.add(@today, -35), "%-d %b %Y")

      assert drawn =~ "Every week, indefinitely"
      # Five weeks ago is week 6, counted rather than stored.
      assert drawn =~ "Week 6 · #{started}"
      refute drawn =~ "Week 6 · 6 Jul 2026"
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Screens.MealPlan))
    end
  end

  describe "screen 45 with nothing in the database" do
    test "draws the meal the design drew" do
      drawn = text(tree(mount_screen(Screens.Meal)))
      sample = Kati.Meals.SampleRecipe

      assert drawn =~ sample.meal().title
      assert drawn =~ String.upcase(sample.meal().slot)
      assert drawn =~ sample.meal().portion
      assert drawn =~ sample.method()

      for line <- sample.ingredients() do
        assert drawn =~ line.name
        assert drawn =~ line.amount
      end

      for {_name, value, _tone} <- sample.macros(), do: assert(drawn =~ value)
      for {_icon, label} <- sample.method_facts(), do: assert(drawn =~ label)
      for row <- sample.history(), do: assert(drawn =~ row.title)

      # The card's own eyebrow, which is drawn with it and absent with it.
      assert drawn =~ "HISTORY"
    end
  end

  describe "screen 45 with a plan on the database" do
    setup :a_logged_day

    test "opens on the day's next meal, not on the drawing's" do
      drawn = text(tree(mount_screen(Screens.Meal)))
      sample = Kati.Meals.SampleRecipe

      # Breakfast, both snacks and lunch are logged; the evening is not.
      assert drawn =~ "Fixture baked cod"
      assert drawn =~ String.upcase("Dinner · 19:30 · today")
      assert drawn =~ "620"

      refute drawn =~ sample.meal().title
      refute drawn =~ sample.method()
    end

    test "the figures are the recipe's cached totals, at its own portion" do
      drawn = text(tree(mount_screen(Screens.Meal)))

      assert drawn =~ "40 g"
      assert drawn =~ "30 g"
      assert drawn =~ "20 g"
      assert drawn =~ "1.0×"

      # The one ingredient line, with its own kcal beside it.
      assert drawn =~ "Fixture line"
      assert drawn =~ "100 g"
    end

    test "history draws the rows the recipe can answer for, and no others" do
      drawn = text(tree(mount_screen(Screens.Meal)))

      assert drawn =~ "Your rating"
      assert drawn =~ "Better with double the miso"

      # Nothing has been logged against this recipe — the fixture's logs are
      # manual ones — so there is no "Eaten n times" row to draw.
      refute drawn =~ "Eaten"
      refute drawn =~ "Last on"
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Screens.Meal))
    end
  end

  describe "screen 47 with nothing in the database" do
    test "draws the figures the design drew" do
      drawn = text(tree(mount_screen(Screens.Nutrition)))
      sample = Kati.Meals.SampleNutrition

      assert drawn =~ sample.plan_line()
      assert drawn =~ sample.hero().average
      assert drawn =~ sample.hero().target

      for {value, label, _tone} <- sample.counts() do
        assert drawn =~ value
        assert drawn =~ String.upcase(label)
      end

      for row <- sample.macros(), do: assert(drawn =~ row.value)
    end

    test "the consistency field and the insight are still the drawing's" do
      # Both are recorded gaps rather than oversights: nothing in Kati.Meals
      # expresses a four-level day or writes an observation about Fridays.
      drawn = text(tree(mount_screen(Screens.Nutrition)))
      {left, right} = Kati.Meals.SampleNutrition.field_caption()

      assert drawn =~ left
      assert drawn =~ right
      assert drawn =~ "Friday is your weak day"

      assert length(find_all(tree(mount_screen(Screens.Nutrition)), :box, width: 8, height: 8)) ==
               84
    end
  end

  describe "screen 47 with a logged week" do
    setup :a_logged_day

    test "the hero, the counts and the macros are the user's own" do
      tree = tree(mount_screen(Screens.Nutrition))
      drawn = text(tree)
      sample = Kati.Meals.SampleNutrition

      assert drawn =~ "1,200"
      assert drawn =~ "2,100"
      refute drawn =~ sample.hero().average

      # Three eaten and one skipped is 75%, which is the whole point of the
      # card: `86%` is the drawing's and must be gone.
      figures = find_all(tree, :text, text_size: 24) |> Enum.map(& &1.props.text)
      assert figures == ["75%", "3", "1"]

      assert drawn =~ "60 / 168 g"
      assert drawn =~ "120 / 210 g"
      assert drawn =~ "30 / 70 g"
      assert drawn =~ "0 / 35 g"
    end

    test "a meal logged under no plan is in no figure on this screen" do
      %{periods: %{"All" => all}} = Screens.Nutrition.figures(@today)
      [{_value, "Adherence", _tone}, {hit, _, _}, {skipped, _, _}] = all.counts

      # The stray meal is 4,000 kcal, eaten, five weeks back — inside the
      # twelve-week window and outside the plan. Counting it would put the
      # `All` average in four figures and add a fourth meal to the count.
      assert hit == "3"
      assert skipped == "1"
      assert all.hero.average == "1,200"

      refute text(tree(mount_screen(Screens.Nutrition))) =~ "4,000"
    end

    test "the plan line counts the week from the plan's start" do
      drawn = text(tree(mount_screen(Screens.Nutrition)))

      assert drawn =~ "Screens fixture plan · week 6"
      refute drawn =~ Kati.Meals.SampleNutrition.plan_line()
    end

    test "the header and the figures are decided by the same question" do
      # A plan whose window holds no log at all falls back — and falls back
      # whole. Titling the drawing's 2,040 kcal with the user's own plan name
      # would read as their figure and be nobody's.
      destroy_where(MealLog, &(&1.logged_on == @today or &1.title == @stray))

      drawn = text(tree(mount_screen(Screens.Nutrition)))

      assert drawn =~ Kati.Meals.SampleNutrition.plan_line()
      assert drawn =~ Kati.Meals.SampleNutrition.hero().average
      refute drawn =~ "Screens fixture plan"
    end

    test "a day under the tolerance band is drawn as under, not as on target" do
      %{periods: %{"Week" => week}} = Screens.Nutrition.figures(@today)

      today = Enum.at(week.bars, Date.day_of_week(@today) - 1)
      assert {_label, height, tone} = today

      # 1,200 kcal against a 2,100 target: 40 kcal to the point is 30pt, and
      # 1,200 is below the 95% band, so the bar is the neutral one.
      assert height == 30
      assert tone == Palette.bar_neutral()
    end

    test "each period is a different window over the same log" do
      %{periods: periods} = Screens.Nutrition.figures(@today)

      assert length(periods["Week"].bars) == 7
      assert length(periods["Month"].bars) == 4
      assert length(periods["All"].bars) == 12

      # One logged day is one day's average whichever window it is read in.
      assert periods["Month"].hero.average == "1,200"
      assert periods["All"].hero.average == "1,200"
    end

    test "the segment redraws the card it owns" do
      view = mount_screen(Screens.Nutrition)
      month = render_info(view, {:tap, :period_Month})

      assert assigns(month).period == "Month"
      assert length(find_all(tree(month), :text, text_size: 24)) == 3
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Screens.Nutrition))
    end
  end

  describe "a plan that is not the active one" do
    setup :a_saved_plan

    test "does not reach any of the five screens" do
      # `Kati.Meals.MealPlan`'s partial unique index permits one active plan and
      # any number of saved ones, and the sample data every other test file
      # leaves behind is saved. A screen that read "any plan" would draw a
      # stranger's week on a device that had never chosen it, and every design
      # comparison in the suite would then depend on test order.
      assert text(tree(mount_screen(Screens.MealsToday))) =~ SampleToday.plan()
      assert text(tree(mount_screen(Screens.MealPlan))) =~ Kati.Meals.SamplePlan.title()
      assert text(tree(mount_screen(Screens.Meal))) =~ Kati.Meals.SampleRecipe.meal().title
      assert text(tree(mount_screen(Screens.Shopping))) =~ SampleShopping.list().subtitle

      assert text(tree(mount_screen(Screens.Nutrition))) =~
               Kati.Meals.SampleNutrition.hero().average
    end
  end

  # ── Fixtures ────────────────────────────────────────────────────────────

  defp a_logged_day(_context) do
    plan =
      plan!(%{
        name: "Screens fixture plan",
        target_kcal: 2100,
        target_protein_mg: 168_000,
        target_carbs_mg: 210_000,
        target_fat_mg: 70_000,
        target_fibre_mg: 35_000,
        starts_on: Date.add(@today, -35),
        repeat: :weekly
      })

    # One recipe per slot, shared across the week, so the evening card can be
    # asserted by name and the dinner's 620 kcal is a cached total the write
    # path computed rather than a number typed into the fixture.
    recipes = Map.new(@slots, fn {_position, name, _time} -> {name, recipe!(name)} end)
    dinner = with_kcal(Map.fetch!(recipes, "Dinner"), "Fixture baked cod", 620)
    recipes = Map.put(recipes, "Dinner", dinner)

    # Every day of the week gets the same five slots, so the strip has
    # something to count on the six days that are not today.
    slots =
      for day_of_week <- 1..7,
          {position, name, time} <- @slots do
        slot!(plan, day_of_week, position, name, time, Map.fetch!(recipes, name))
      end

    today_slots =
      slots
      |> Enum.filter(&(&1.day_of_week == Date.day_of_week(@today)))
      |> Enum.sort_by(& &1.position)

    [breakfast, snack, lunch, afternoon, _dinner] = today_slots

    log!(plan, breakfast, "Porridge and figs", :eaten, %{
      kcal: 400,
      protein_mg: 15_000,
      carbs_mg: 60_000,
      fat_mg: 10_000
    })

    log!(plan, snack, "Almonds", :eaten, %{
      kcal: 300,
      protein_mg: 10_000,
      carbs_mg: 10_000,
      fat_mg: 12_000
    })

    log!(plan, lunch, "Lentil soup", :eaten, %{
      kcal: 500,
      protein_mg: 35_000,
      carbs_mg: 50_000,
      fat_mg: 8_000
    })

    log!(plan, afternoon, "Apple", :skipped, %{kcal: 200})

    # Five weeks back, eaten, and belonging to no plan — the shape a meal out
    # takes. It is inside screen 47's twelve-week window and must not be inside
    # its figures.
    MealLog
    |> Ash.Changeset.for_create(:log_manual, %{
      logged_on: Date.add(@today, -35),
      logged_at: DateTime.utc_now(),
      state: :eaten,
      title: @stray,
      kcal: 4000,
      protein_mg: 1_000_000
    })
    |> Ash.create!()

    :ok
  end

  # A plan with a full week on it, and `status: :saved` — the state every plan
  # in the database is in until one is chosen.
  defp a_saved_plan(_context) do
    plan =
      MealPlan
      |> Ash.Changeset.for_create(:create, %{name: "Screens fixture saved", target_kcal: 2100})
      |> Ash.create!()

    recipe = recipe!("Saved")

    for day_of_week <- 1..7, {position, name, time} <- @slots do
      slot!(plan, day_of_week, position, name, time, recipe)
    end

    :ok
  end

  defp a_shopping_week(_context) do
    plan = plan!(%{name: "Screens fixture plan", target_kcal: 2100})
    monday = Date.add(@today, -(Date.day_of_week(@today) - 1))

    item!(plan, monday, %{
      name: "Rye bread",
      aisle: :bakery,
      amount_mg: 2_000,
      unit: :piece,
      meal_count: 7,
      meals_label: "7 breakfasts",
      got: false,
      price_minor: 240,
      price_currency: "GBP",
      price_source: :remembered
    })

    item!(plan, monday, %{
      name: "Cod fillet",
      aisle: :fish_and_meat,
      amount_mg: 600_000,
      unit: :g,
      meal_count: 4,
      meals_label: "4 dinners",
      got: true,
      price_minor: 610,
      price_currency: "GBP",
      price_source: :entered
    })

    item!(plan, monday, %{
      name: "Red lentils",
      aisle: :cupboard,
      amount_mg: 1_000_000,
      unit: :g,
      meal_count: 6,
      got: false
    })

    :ok
  end

  defp plan!(attrs) do
    MealPlan
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!()
    |> Ash.Changeset.for_update(:activate, %{})
    |> Ash.update!()
  end

  defp slot!(plan, day_of_week, position, name, time, recipe) do
    MealPlanSlot
    |> Ash.Changeset.for_create(:create, %{
      meal_plan_id: plan.id,
      day_of_week: day_of_week,
      position: position,
      slot_name: name,
      slot_time: time,
      state: :planned,
      recipe_id: recipe.id
    })
    |> Ash.create!()
  end

  defp recipe!(name) do
    Recipe
    |> Ash.Changeset.for_create(:create, %{
      title: "Fixture #{String.downcase(name)}",
      photo_seed: "mealsalmon",
      minutes: 20,
      serves: 1
    })
    |> Ash.create!()
  end

  # `Kati.Meals.Totals` is the only writer of a recipe's cached figures, so the
  # fixture goes through it rather than forcing the columns — the `:next` card's
  # calorie line is then the sum the write path computed.
  defp with_kcal(recipe, title, kcal) do
    {_line, totalled} =
      Kati.Meals.Totals.write_ingredient(recipe, %{
        position: 0,
        name: "Fixture line",
        amount_mg: 100_000,
        unit: :g,
        kcal: kcal,
        protein_mg: 40_000,
        carbs_mg: 30_000,
        fat_mg: 20_000
      })

    totalled
    |> Ash.Changeset.for_update(:update, %{
      title: title,
      rating: 5,
      note: "Better with double the miso"
    })
    |> Ash.update!()
  end

  defp log!(plan, slot, title, state, figures) do
    MealLog
    |> Ash.Changeset.for_create(
      :log_manual,
      Map.merge(
        %{
          logged_on: @today,
          logged_at: DateTime.utc_now(),
          state: state,
          title: title,
          slot_name: slot.slot_name,
          slot_time: slot.slot_time,
          meal_plan_id: plan.id,
          meal_plan_slot_id: slot.id
        },
        figures
      )
    )
    |> Ash.create!()
  end

  defp item!(plan, monday, attrs) do
    ShoppingListItem
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{meal_plan_id: plan.id, week_starting_on: monday}, attrs)
    )
    |> Ash.create!()
  end

  defp stand_down_all do
    MealPlan
    |> Ash.read!()
    |> Enum.filter(&(&1.status == :active))
    |> Enum.each(&(&1 |> Ash.Changeset.for_update(:stand_down, %{}) |> Ash.update!()))
  end

  # Reverse dependency order, and the logs first: `meal_plan_id` nilifies on a
  # plan's destroy, so a log deleted afterwards is a log nothing can find.
  defp cleanup do
    destroy_where(MealLog, &(&1.logged_on == @today or &1.title == @stray))
    destroy_where(MealPlan, &String.starts_with?(&1.name, "Screens fixture"))
    destroy_where(Recipe, &String.starts_with?(&1.title, "Fixture "))
    destroy_where(ShoppingListItem, &(&1.name in ["Rye bread", "Cod fillet", "Red lentils"]))
  end

  defp destroy_where(resource, keep?) do
    resource
    |> Ash.read!()
    |> Enum.filter(keep?)
    |> Enum.each(&Ash.destroy!/1)
  end
end
