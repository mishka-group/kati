defmodule Kati.Notifications.Sources.Meals do
  @moduledoc """
  Meal reminders, from the active plan's own settings rather than from a global one.

  Screen 51 draws seven controls and every one of them is a column on
  `Kati.Meals.MealPlan`: `reminders_enabled`, `reminder_lead_minutes`,
  `evening_preview_at`, `quiet_hours_from`/`quiet_hours_until`,
  `skip_during_events`, `stop_after_skips` and `silent_only`. They are the
  plan's, not the app's, because two plans can want different things — a
  cutting week wants a reminder before every slot and a maintenance week wants
  the evening preview and nothing else.

  ## The lead time is why a slot's clock is not the fire time

  A slot at 19:30 with a 15-minute lead fires at 19:15. That is the whole point
  of the control: a reminder that arrives when the meal is due is a reminder to
  feel guilty, not to cook. `reminder_lead_minutes` defaults to 15 and the
  subtraction happens here, once.

  ## The evening preview is one candidate for the whole of tomorrow

  `evening_preview_at` is a single nightly notification that names what is
  planned, and it aggregates the same way `Kati.Notifications.Sources.Health`
  aggregates a clock time: one candidate, `members` naming the slots. Without
  it a plan with five slots would spend five of the `:meals` budget's sixty
  Android slots on one day, and the budget's iOS column is **six**.

  ## What is suppressed, and why each one is an answer rather than an absence

    * `:reminders_off` — the plan's own switch. One suppressed candidate for the
      plan rather than one per slot, because the reason is the plan's.
    * `:no_time` — a slot with no `slot_time`. Screen 44 allows one: a plan can
      say *lunch* without saying when, and a slot with no clock has no instant
      to fire at.

  A device with **no** active plan contributes nothing at all rather than a
  suppressed candidate, and the distinction is the one this whole namespace
  turns on. A suppressed candidate means *this would have fired and here is why
  it did not*, which is what the inbox's held group prints. Nothing is planned
  is not a held reminder — it is a section the user has not set up — and
  printing it as one would put a row on a fresh install's inbox saying a
  reminder was withheld that was never going to be sent.

  Screen 51's remaining two controls are **not** read here and that is
  deliberate. `skip_during_events` needs the calendar's busy state at fire time,
  which is the Kotlin worker's question and not the scheduler's, and
  `stop_after_skips` needs a count of consecutive skips that
  `Kati.Meals.MealLog` does not yet keep. Both are drawn, both are stored, and
  neither is silently pretended to work: they are named here so the next reader
  does not go looking for the code that honours them.
  """

  alias Kati.Meals.MealPlan
  alias Kati.Meals.MealPlanSlot
  alias Kati.Notifications.Candidate

  @doc """
  Every meal candidate for `day` — the per-slot reminders and the evening preview.

  Takes the plan and its slots rather than reading them, which is
  `Kati.Notifications.Sources.Media`'s shape: a function that reads its own
  input cannot be asked what it does with a given one. `active_plan/0` and
  `slots/2` are the readers.

  `opts` takes `:zone`.
  """
  @spec candidates(MealPlan.t() | nil, [MealPlanSlot.t()], Date.t(), keyword()) :: [Candidate.t()]
  def candidates(plan, slots, day, opts \\ [])

  def candidates(nil, _slots, %Date{}, _opts), do: []

  def candidates(%MealPlan{reminders_enabled: false} = plan, _slots, %Date{}, _opts) do
    [
      Candidate.suppressed(Candidate.id(["meal", "plan", plan.id]), :meals, :reminders_off,
        title: plan.name
      )
    ]
  end

  def candidates(%MealPlan{} = plan, slots, %Date{} = day, opts) when is_list(slots) do
    zone = Keyword.get(opts, :zone) || Kati.Time.device_zone()

    Enum.concat(slot_candidates(plan, slots, day, zone), preview(plan, slots, day, zone))
  end

  @doc "The active plan, or `nil` when there is none or the store cannot answer."
  @spec active_plan() :: MealPlan.t() | nil
  def active_plan do
    MealPlan
    |> Ash.Query.for_read(:active)
    |> Ash.read_one()
    |> case do
      {:ok, plan} -> plan
      _error -> nil
    end
  rescue
    _error -> nil
  end

  @doc "The plan's slots for `day`'s weekday, in the order screen 44 draws them."
  @spec slots(MealPlan.t(), Date.t()) :: [MealPlanSlot.t()]
  def slots(%MealPlan{id: id}, %Date{} = day) do
    MealPlanSlot
    |> Ash.Query.for_read(:on_day, %{meal_plan_id: id, day_of_week: Date.day_of_week(day)})
    |> Ash.read()
    |> case do
      {:ok, rows} -> rows
      _error -> []
    end
  rescue
    _error -> []
  end

  @doc "The stable id for one slot's reminder."
  @spec slot_id(Date.t(), MealPlanSlot.t()) :: String.t()
  def slot_id(%Date{} = day, %MealPlanSlot{} = slot),
    do: Candidate.id(["meal", day, slot.id])

  @doc "The stable id for a day's evening preview."
  @spec preview_id(Date.t()) :: String.t()
  def preview_id(%Date{} = day), do: Candidate.id(["meal", "preview", day])

  defp slot_candidates(plan, slots, day, zone) do
    Enum.map(slots, fn slot -> slot_candidate(plan, slot, day, zone) end)
  end

  defp slot_candidate(_plan, %MealPlanSlot{slot_time: nil} = slot, day, _zone) do
    Candidate.suppressed(slot_id(day, slot), :meals, :no_time,
      title: slot.slot_name,
      meta: %{slot_id: slot.id}
    )
  end

  defp slot_candidate(plan, %MealPlanSlot{} = slot, day, zone) do
    wall =
      day
      |> NaiveDateTime.new!(slot.slot_time)
      |> NaiveDateTime.add(-plan.reminder_lead_minutes * 60, :second)

    Candidate.wall_clock(slot_id(day, slot), :meals, wall, zone,
      title: slot.slot_name,
      body: lead_line(plan, slot),
      priority: priority(plan),
      members: [slot.id],
      meta: %{slot_id: slot.id, lead_minutes: plan.reminder_lead_minutes}
    )
  end

  # No preview time set, or nothing to preview. A plan whose evening preview is
  # off is not suppressed — the control is a time or nothing, and nothing means
  # the user turned it off, which is a setting rather than a failure.
  defp preview(%MealPlan{evening_preview_at: nil}, _slots, _day, _zone), do: []
  defp preview(%MealPlan{}, [], _day, _zone), do: []

  defp preview(%MealPlan{} = plan, slots, day, zone) do
    wall = NaiveDateTime.new!(day, plan.evening_preview_at)

    [
      Candidate.wall_clock(preview_id(day), :meals, wall, zone,
        title: "Tomorrow's meals",
        body: Enum.map_join(slots, " · ", & &1.slot_name),
        priority: :low,
        members: Enum.map(slots, & &1.id),
        meta: %{preview: true, count: length(slots)}
      )
    ]
  end

  # `silent_only` is a delivery decision the plan makes, and the scheduler's
  # currency for "deliver this quietly" is priority: `:low` is what the budget
  # drops first and what the Android channel maps to no sound.
  defp priority(%MealPlan{silent_only: true}), do: :low
  defp priority(%MealPlan{}), do: :normal

  defp lead_line(%MealPlan{reminder_lead_minutes: 0}, %MealPlanSlot{}), do: "Now"

  defp lead_line(%MealPlan{reminder_lead_minutes: minutes}, %MealPlanSlot{}),
    do: "In #{minutes} min"
end
