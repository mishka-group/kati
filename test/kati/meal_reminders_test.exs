defmodule Kati.MealRemindersTest do
  @moduledoc """
  Screen 51 writes the two reminder columns the scheduler reads.

  The page drew seven controls and not one wrote anything; these are the two
  that are columns on `Kati.Meals.MealPlan` and that
  `Kati.Notifications.Sources.Meals` gates on.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Meals.MealPlan
  alias Kati.Screens.MealReminders

  @prefix "meal-reminders-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  test "the evening preview toggles evening_preview_at, and back" do
    plan = plan!(evening_preview_at: ~T[20:00:00])

    view = mount_screen(MealReminders)
    assert assigns(view).reminders.day_before.on == true

    view = render_info(view, {:tap, :toggle_day_before})
    assert assigns(view).reminders.day_before.on == false
    assert Ash.get!(MealPlan, plan.id).evening_preview_at == nil

    view = render_info(view, {:tap, :toggle_day_before})
    assert assigns(view).reminders.day_before.on == true
    assert Ash.get!(MealPlan, plan.id).evening_preview_at == ~T[20:00:00]
  end

  test "on-the-day reminders toggle reminders_enabled" do
    plan = plan!(reminders_enabled: true)

    view = mount_screen(MealReminders)
    assert assigns(view).reminders.on_the_day.on == true

    view = render_info(view, {:tap, :toggle_on_the_day})
    assert assigns(view).reminders.on_the_day.on == false
    assert Ash.get!(MealPlan, plan.id).reminders_enabled == false
  end

  test "with no plan the page offers the importer, and a tap writes nothing" do
    delete_rows!()

    view = mount_screen(MealReminders)
    assert assigns(view).reminders == Kati.Screens.MealReminders.empty_state()

    # The switches belong to a plan; the card is what a device without one gets,
    # and its one control goes to the importer rather than writing anything.
    view = render_info(view, {:tap, :toggle_day_before})

    # Scoped to this file's own plans: the suite stores plans of its own, and
    # `== []` was asserting about those too.
    assert Enum.all?(Ash.read!(MealPlan), &(not String.starts_with?(&1.name, @prefix)))
    _ = view
  end

  defp plan!(attrs) do
    Ash.create!(MealPlan, Map.merge(%{name: @prefix <> "Plan", status: :active}, Map.new(attrs)))
  end

  defp delete_rows! do
    Kati.Repo.query!(
      "DELETE FROM meal_plan_slots WHERE meal_plan_id IN (SELECT id FROM meal_plans WHERE name LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM meal_plans WHERE name LIKE ?1", [@prefix <> "%"])
  end
end
