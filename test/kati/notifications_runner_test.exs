defmodule Kati.NotificationsRunnerTest do
  @moduledoc """
  The loop that applies the plan, and the four domain sources it now collects.

  The sources themselves are held by `Kati.NotificationSourcesTest`; this file
  is the wiring: a renewal that reaches the candidate list, a meal plan whose
  reminders are off saying so, and a runner that reconciles without taking the
  process tree down when there is no platform to arm.
  """
  use ExUnit.Case, async: false

  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Runner
  alias Kati.Services.Service

  @prefix "notifications-runner-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  test "a service renewing tomorrow is a candidate for today" do
    tomorrow = Date.add(Kati.Time.today(), 1)

    Ash.create!(Service, %{
      name: @prefix <> "Cinema",
      monthly_pence: 900,
      renews_on: tomorrow
    })

    ids =
      Kati.Notifications.Reminders.candidates()
      |> Enum.map(& &1.id)

    assert Enum.any?(ids, &String.starts_with?(&1, "renew:")),
           "a renewal tomorrow produced no candidate: #{inspect(ids)}"
  end

  test "a meal plan with its reminders off contributes a suppression, not silence" do
    plan =
      Ash.create!(Kati.Meals.MealPlan, %{
        name: @prefix <> "Plan",
        reminders_enabled: false
      })

    candidates = Kati.Notifications.Sources.Meals.candidates(plan, [], Kati.Time.today())
    assert [%Candidate{suppressed: :reminders_off}] = candidates
  end

  test "the runner reconciles on start and answers without a platform" do
    pid = start_supervised!({Runner, []})
    assert Process.alive?(pid)

    # Inert delivery answers `:no_delivery`; the runner turns that into a
    # result, not a crash.
    result = Runner.sync_now()
    assert match?({:error, :no_delivery}, result.reminders)
    assert match?({:error, :no_delivery}, result.releases)
  end

  defp delete_rows! do
    Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])

    Kati.Repo.query!(
      "DELETE FROM meal_plan_slots WHERE meal_plan_id IN (SELECT id FROM meal_plans WHERE name LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM meal_plans WHERE name LIKE ?1", [@prefix <> "%"])
  end
end
