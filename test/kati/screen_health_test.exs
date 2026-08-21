defmodule Kati.ScreenHealthTest do
  @moduledoc """
  Screen 42's hero and meal row, against `Kati.Meals` and against a database
  with no plan in it.

  ## Why this is not covered by the sweeps

  `Kati.ScreenRenderSweepTest` mounts the screen and asserts it renders;
  `Kati.ScreenTapSweepTest` taps what that render drew; neither reads the copy.
  `Kati.ScreenDesignLiteralTest` does read it, and cannot help here either —
  every figure this screen prints is also in `Kati.Health.Sample`, which the
  screen still falls back to, so a query that answered nothing would keep
  passing it. Every number on the hero is therefore checked here or nowhere.

  Both directions are asserted for each block:

    * **nothing planned** — the drawing's own figures, by value, because
      `.scratch/design/audit/42.png` was captured from them.
    * **a plan and a logged day** — the user's figures, and *none* of the
      drawing's. `=~` on the real value alone passes against a screen that
      draws both.

  ## The seam this file pins deliberately

  The sections grid is not domain data — nothing stores which sections a user
  has switched on — so only the Meals tile's line moves with the plan and the
  Habits tile keeps the drawing's *"4 active · 12-day best"*. That is asserted
  rather than left implicit: it is the honest consequence of there being no
  habit-completion resource, and if one ever lands, this test is where the
  claim stops being true.

  ## The wipe in `setup`

  There is no sandbox — `test/test_helper.exs` migrates one SQLite file and the
  whole run shares it — and `meal_plans` carries a partial unique index
  permitting exactly one active row. A plan left standing does not fail here,
  it fails in whichever file runs next. Same setup and teardown as
  `Kati.MealsScreensTest`, for the same reason.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Health.Sample
  alias Kati.Meals.MealLog
  alias Kati.Meals.MealPlan
  alias Kati.Meals.MealPlanSlot
  alias Kati.Meals.Recipe
  alias Kati.Screens.Health

  # The screen reads `Kati.Time.today/0` at mount, so the fixtures are written
  # for the day they will be read on — taken once, so a fixture and the
  # assertion about it cannot land on opposite sides of a midnight.
  @today Kati.Time.today()

  # Screen 43's five slots at the drawing's own times, so screen 42's "3 of 5"
  # and its 19:30 dinner are the same day the sibling screen draws.
  @slots [
    {0, "Breakfast", ~T[07:30:00]},
    {1, "Snack", ~T[10:30:00]},
    {2, "Lunch", ~T[13:00:00]},
    {3, "Snack", ~T[16:00:00]},
    {4, "Dinner", ~T[19:30:00]}
  ]

  @prefix "Health fixture"

  setup do
    clear!()
    on_exit(&clear!/0)
    :ok
  end

  defp clear! do
    destroy_where(MealLog, &(&1.logged_on == @today))
    stand_down_all()
    destroy_where(MealPlan, &String.starts_with?(&1.name, @prefix))
    destroy_where(Recipe, &String.starts_with?(&1.title, @prefix))
    :ok
  end

  defp stand_down_all do
    MealPlan
    |> Ash.read!()
    |> Enum.filter(&(&1.status == :active))
    |> Enum.each(&(&1 |> Ash.Changeset.for_update(:stand_down, %{}) |> Ash.update!()))
  end

  defp destroy_where(resource, match?) do
    resource |> Ash.read!() |> Enum.filter(match?) |> Enum.each(&Ash.destroy!/1)
  end

  # ── Fixtures ───────────────────────────────────────────────────────────────

  # Five weeks in, so the Meals tile's derived week is 6 — the drawing's own
  # number, reached by arithmetic rather than by being written down.
  defp plan!(attrs \\ %{}) do
    MealPlan
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{name: "#{@prefix} plan", target_kcal: 2100, starts_on: Date.add(@today, -35)},
        attrs
      )
    )
    |> Ash.create!()
    |> Ash.Changeset.for_update(:activate, %{})
    |> Ash.update!()
  end

  defp recipe!(name) do
    Recipe
    |> Ash.Changeset.for_create(:create, %{
      title: "#{@prefix} #{String.downcase(name)}",
      photo_seed: "mealsalmon",
      minutes: 20,
      serves: 1
    })
    |> Ash.create!()
  end

  # `Kati.Meals.Totals` is the only writer of a recipe's cached figures, so the
  # 620 kcal on the meal row is a total the write path computed rather than a
  # number typed into the fixture — which is what the screen scales by the
  # slot's portion.
  defp with_kcal(recipe, kcal) do
    {_line, totalled} =
      Kati.Meals.Totals.write_ingredient(recipe, %{
        position: 0,
        name: "#{@prefix} line",
        amount_mg: 100_000,
        unit: :g,
        kcal: kcal,
        protein_mg: 40_000,
        carbs_mg: 30_000,
        fat_mg: 20_000
      })

    totalled
  end

  defp slot!(plan, position, name, time, recipe) do
    MealPlanSlot
    |> Ash.Changeset.for_create(:create, %{
      meal_plan_id: plan.id,
      day_of_week: Date.day_of_week(@today),
      position: position,
      slot_name: name,
      slot_time: time,
      state: :planned,
      recipe_id: recipe && recipe.id
    })
    |> Ash.create!()
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

  # The day the drawing draws, in the database: five slots, three eaten, one
  # skipped, and a dinner nobody has decided about yet.
  defp a_logged_day(_context) do
    plan = plan!()
    dinner = "Dinner" |> recipe!() |> with_kcal(620)

    slots =
      for {position, name, time} <- @slots do
        recipe = if name == "Dinner", do: dinner, else: recipe!("#{name}#{position}")
        slot!(plan, position, name, time, recipe)
      end

    [breakfast, snack, lunch, afternoon, _dinner_slot] = slots

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

    # A skipped meal keeps its frozen figures and contributes none of them: it
    # is not in the 1,200 and it is not the next meal either.
    log!(plan, afternoon, "Apple", :skipped, %{kcal: 200, carbs_mg: 25_000})

    {:ok, plan: plan, slots: slots}
  end

  # ── Readers ────────────────────────────────────────────────────────────────

  # The three weighted fills of the 9pt macro bar, in the order they are laid.
  # The track is `fill_width` and carries no weight, so it is not one of these.
  defp segments(tree) do
    tree
    |> find_all(:box, height: 9)
    |> Enum.map(& &1.props[:weight])
    |> Enum.reject(&is_nil/1)
  end

  defp line_of(tree, name) do
    tree
    |> find_all(:text, text_size: 11)
    |> Enum.map(& &1.props.text)
    |> Enum.find(&String.starts_with?(&1 || "", name))
  end

  describe "with nothing planned" do
    test "the day is the drawing's, block for block" do
      assert Health.day(@today) == Health.drawn_day()

      day = Health.day(@today)

      assert day.day_line == Sample.day_line()
      assert day.eaten == Sample.eaten()
      assert day.next_meal == Sample.next_meal()
      assert day.sections == Sample.sections()
    end

    test "every figure the drawing prints reaches the tree" do
      tree = tree(mount_screen(Health))
      e = Sample.eaten()

      for value <- [e.calories, e.target, e.meals, e.grams, Sample.day_line()] do
        assert find(tree, :text, text: value) != nil,
               "#{inspect(value)} is nowhere in the tree"
      end

      assert find(tree, :text, text: Sample.next_meal().title) != nil
      assert find(tree, :text, text: Sample.next_meal().line) != nil
    end

    test "the macro bar draws the drawing's own three shares" do
      assert segments(tree(mount_screen(Health))) ==
               Enum.map(Sample.eaten().macros, fn {_name, share, _tone} -> share end)
    end

    test "all six sections are drawn with the drawing's lines" do
      tree = tree(mount_screen(Health))

      for section <- Sample.sections() do
        assert find(tree, :text, text: section.name) != nil
        assert find(tree, :text, text: section.line) != nil
      end
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Health))
    end
  end

  describe "with a plan and a logged day" do
    setup :a_logged_day

    test "the hero counts what was eaten, and none of what was not" do
      tree = tree(mount_screen(Health))

      # 400 + 300 + 500. The skipped apple's 200 is frozen on its row and is
      # deliberately not in this figure.
      assert find(tree, :text, text: "1,200") != nil
      assert find(tree, :text, text: " / 2,100 kcal") != nil
      assert find(tree, :text, text: "3 of 5") != nil

      # 60 g protein, 120 g carbs, 30 g fat, from the milligrams the logs froze.
      assert find(tree, :text, text: "60P · 120C · 30F") != nil

      # `Sample.eaten().meals` is deliberately absent from this list: the
      # fixture reproduces the drawing's own day, so its pill reads "3 of 5"
      # too and the comparison could not tell the two apart. The proof that
      # the pill is counted rather than printed is the "4 of 5" further down,
      # which is a value the drawing never carries.
      for value <- [Sample.eaten().calories, Sample.eaten().grams] do
        assert find(tree, :text, text: value) == nil,
               "the fallback fired over a day that has rows: #{inspect(value)} is drawn"
      end
    end

    test "the mono line under the title is today, not the day the drawing was captured" do
      tree = tree(mount_screen(Health))

      assert find(tree, :text, text: Calendar.strftime(@today, "%A %-d %B")) != nil
      assert find(tree, :text, text: Sample.day_line()) == nil
    end

    test "the macro bar is the energy split of those figures" do
      # 60 g protein and 120 g carbs at 4 kcal a gram, 30 g fat at 9 — which is
      # the only reading under which the three segments add up to the 1,200 the
      # hero states above them.
      assert segments(tree(mount_screen(Health))) == [0.24, 0.48, 0.27]
    end

    test "the meal row is the earliest thing neither eaten nor skipped" do
      tree = tree(mount_screen(Health))

      assert find(tree, :text, text: "Open Meals — dinner 19:30") != nil
      assert find(tree, :text, text: "#{@prefix} dinner · 620 kcal") != nil

      # The title cannot tell the two apart — the fixture reproduces the
      # drawing's own 19:30 dinner, so both read "Open Meals — dinner 19:30".
      # The line under it can: the drawing's names a recipe this database has
      # never held.
      assert find(tree, :text, text: Sample.next_meal().line) == nil,
             "the fallback fired over a day that has an unlogged meal on it"

      # The 16:00 snack is earlier and was skipped, so it is not the next meal.
      assert find(tree, :text, text: "Open Meals — snack 16:00") == nil
    end

    test "the Meals tile carries the plan's name and its derived week" do
      assert line_of(tree(mount_screen(Health)), @prefix) == "#{@prefix} plan · week 6"
    end

    test "the Habits tile is still the drawing's, and that is the honest state" do
      # There is no resource anywhere that records a habit being kept — see
      # `Kati.Screens.Habits` — so this line has no source and stays the
      # drawing's. When one lands, this assertion is what says so.
      tree = tree(mount_screen(Health))
      habits = Enum.find(Sample.sections(), &(&1.icon == "bolt"))

      assert find(tree, :text, text: habits.line) != nil
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Health))
    end
  end

  describe "a day with nothing left to eat" do
    setup :a_logged_day

    test "draws no meal row rather than a meal that has already happened", %{
      plan: plan,
      slots: slots
    } do
      log!(plan, List.last(slots), "Baked cod", :eaten, %{kcal: 620, protein_mg: 40_000})

      tree = tree(mount_screen(Health))

      assert Health.next_meal_row([], []) == nil

      assert find_all(tree, :box, width: 36, height: 36) == [],
             "the 36pt meal tile is drawn, so the row survived a day with nothing " <>
               "unlogged on it"

      assert find(tree, :text, text: Sample.next_meal().title) == nil,
             "the drawing's dinner is drawn over a day whose dinner was eaten"

      assert find(tree, :text, text: "4 of 5") != nil
    end
  end

  describe "a rest day inside a real plan" do
    setup do
      plan = plan!()
      # A week's worth of slots, none of them on today. The plan is real and
      # today is empty, which is a different thing from having no plan.
      other_day = rem(Date.day_of_week(@today), 7) + 1

      MealPlanSlot
      |> Ash.Changeset.for_create(:create, %{
        meal_plan_id: plan.id,
        day_of_week: other_day,
        position: 0,
        slot_name: "Breakfast",
        slot_time: ~T[07:30:00],
        state: :planned,
        recipe_id: recipe!("Breakfast").id
      })
      |> Ash.create!()

      :ok
    end

    test "draws an empty day rather than the drawing's full one" do
      tree = tree(mount_screen(Health))

      assert find(tree, :text, text: "0") != nil
      assert find(tree, :text, text: "0 of 0") != nil
      assert find(tree, :text, text: "0P · 0C · 0F") != nil
      assert segments(tree) == []

      assert find(tree, :text, text: Sample.eaten().calories) == nil,
             "a plan with a free day fell back to the drawing, which would put " <>
               "1,480 kcal on a day nothing was eaten"

      assert find_all(tree, :box, width: 36, height: 36) == [],
             "a meal row is drawn on a day the plan has no meals on"
    end
  end

  describe "a macro that contributed nothing" do
    setup do
      plan = plan!()
      slot = slot!(plan, 0, "Breakfast", ~T[07:30:00], recipe!("Breakfast"))

      log!(plan, slot, "Toast and jam", :eaten, %{
        kcal: 500,
        protein_mg: 20_000,
        carbs_mg: 40_000,
        fat_mg: 0
      })

      :ok
    end

    test "draws nothing rather than a segment of zero weight" do
      # A `weight` of zero is a share of the leftover space, which Compose
      # throws on — a different question from "no width". The drawing never
      # asks it and a real day asks it every morning.
      assert segments(tree(mount_screen(Health))) == [0.33, 0.67]
    end
  end
end
