defmodule Kati.Meals.MealLog do
  @moduledoc """
  What was actually eaten, **frozen at the moment it was logged**.

  This is the row #73 says cannot be retrofitted, and the reason is worth
  stating plainly: a log that stored a `recipe_id` and looked the figures up at
  read time would let an edit made next week rewrite last week. Double the miso
  in the miso salmon and every Thursday in June silently gains 30 kcal; screen
  47's adherence chart becomes fiction, and the data needed to reconstruct the
  old snapshot is exactly what the edit destroyed.

  So every figure a screen ever prints about the past is a column **on this
  row**: the title, the slot, the portion, and the seven figures. `recipe_id` is
  kept, but only as provenance — nothing reads a number through it, and it
  nilifies when the recipe is deleted while the figures stay exactly where they
  are.

  ## The snapshot is written once

  `create :log_recipe` and `create :log_manual` take the snapshot. **No update
  action accepts a snapshot column**, and `Kati.Meals.Changes.RejectSnapshotChange`
  fails loudly if one is forced anyway — so a widened `accept` list in a later
  refactor breaks a test instead of quietly unfreezing history. Re-logging is a
  destroy and a create, which is honest: it is a new claim about the past, not an
  amendment to an old one.

  `recipe_rev` records the recipe's `ingredients_rev` at the moment of the
  freeze. It is what lets a screen say "the recipe has changed since you ate
  this" without keeping a second copy of the recipe, and it is what makes the
  freeze *provable* rather than merely asserted.

  ## The three states

  `:eaten` and `:skipped` are screen 43's logged cards, and together they are
  screen 47's `30 hit / 5 skipped / 86%`. A skipped meal keeps its frozen figures
  — the card prints `SKIPPED` instead of a calorie count, but "you skipped
  620 kcal" is the sentence the nutrition screen's insight is built out of, and
  it is unrecoverable once the recipe moves on.

  `:planned` is the third, and it is what screen 46's *"Swap just today"*
  produces: a deviation from the plan's rule, materialised for one day so the
  rule itself does not have to change. Its figures are frozen at swap time, and
  marking it eaten does not refresh them — the numbers you agreed to when you
  swapped are the numbers you ate.

  `:next` is not a state here. Screen 43 draws it, and it means "the earliest
  unlogged slot today", which is a fact about the clock rather than about a row.

  ## `logged_on` is a date, `logged_at` is an instant

  A meal counts toward the day you ate it, which is a floating-time fact — the
  same distinction `Kati.Calendars.Event` draws between `dtstart_date` and
  `dtstart_utc`. Summing a day's intake by an instant range would move breakfast
  into yesterday for the first two hours of every Amsterdam day.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  @snapshot_fields [
    :title,
    :slot_name,
    :slot_time,
    :portion_milli,
    :kcal,
    :protein_mg,
    :carbs_mg,
    :fat_mg,
    :fibre_mg,
    :sugar_mg,
    :sodium_mg,
    :recipe_rev,
    :frozen_at
  ]

  @doc """
  The columns no update may touch. `Kati.Meals.Changes.RejectSnapshotChange`
  reads this list, and so does the test that proves an edit cannot move history.
  """
  @spec snapshot_fields() :: [atom()]
  def snapshot_fields, do: @snapshot_fields

  sqlite do
    table "meal_logs"
    repo Kati.Repo

    references do
      # Provenance nilifies; the frozen figures never move.
      reference :recipe, on_delete: :nilify
      reference :meal_plan, on_delete: :nilify
      reference :meal_plan_slot, on_delete: :nilify
    end

    custom_indexes do
      # Screen 43's day, and screen 47's week and month.
      index [:logged_on, :slot_time]
      index [:meal_plan_id, :logged_on]
      # The adherence count.
      index [:state, :logged_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :logged_on, :date, allow_nil?: false, public?: true
    attribute :logged_at, :utc_datetime_usec, allow_nil?: false, public?: true

    attribute :state, :atom,
      allow_nil?: false,
      default: :eaten,
      public?: true,
      constraints: [one_of: [:planned, :eaten, :skipped]]

    # ── THE SNAPSHOT. Written at creation, never again. ────────────────────
    attribute :title, :string, allow_nil?: false, public?: true
    attribute :slot_name, :string, public?: true
    attribute :slot_time, :time, public?: true
    attribute :portion_milli, :integer, allow_nil?: false, default: 1000, public?: true

    attribute :kcal, :integer, allow_nil?: false, default: 0, public?: true
    attribute :protein_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :carbs_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fat_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fibre_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sugar_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sodium_mg, :integer, allow_nil?: false, default: 0, public?: true

    # The recipe's `ingredients_rev` when the freeze was taken.
    attribute :recipe_rev, :integer, public?: true
    attribute :frozen_at, :utc_datetime_usec, allow_nil?: false, public?: true

    # ── Not part of the snapshot: the user may write these whenever ────────
    attribute :note, :string, public?: true
    attribute :rating, :integer, public?: true, constraints: [min: 0, max: 5]

    timestamps()
  end

  relationships do
    belongs_to :recipe, Kati.Meals.Recipe, attribute_writable?: true, attribute_public?: true

    belongs_to :meal_plan, Kati.Meals.MealPlan,
      attribute_writable?: true,
      attribute_public?: true

    belongs_to :meal_plan_slot, Kati.Meals.MealPlanSlot,
      attribute_writable?: true,
      attribute_public?: true
  end

  actions do
    defaults [:read, :destroy]
    # Nothing is accepted by default. Every accept list below is written out, so
    # adding a snapshot column cannot make it writable by accident.
    default_accept []

    # The freeze. Figures are NOT accepted — they are computed from the recipe
    # inside the action, so a caller cannot pass numbers that never existed.
    # `:slot_name` and `:slot_time` are on this list and the six figures are
    # not, and the difference is where the value comes from. A figure is
    # DERIVED from the recipe, so accepting one would let a caller pass a
    # number that never existed — that is what `Kati.Meals.Changes.FreezeNutrition`
    # is for. The slot's name and clock are derived from nothing: they live on
    # `Kati.Meals.MealPlanSlot`, which this action never reads, and only the
    # caller holds the slot the log is being written against.
    #
    # They were absent until 2026-09-05, and the two screens that write this
    # action both lost them. `Kati.Screens.MealsToday`'s **Mark eaten** turned
    # a `Dinner · 19:30` card into a card with a blank time gutter and no slot
    # eyebrow, which then sorted to the bottom of the day (`timeline_rows/2`
    # orders a timeless row last) and answered `meal_tag/1` with the bare
    # `:open_meal` — so the row stopped being able to name itself the instant
    # it was logged. `:log_manual` has accepted both all along, which is what
    # made the asymmetry a slip rather than a decision.
    create :log_recipe do
      primary? true

      accept [
        :logged_on,
        :logged_at,
        :state,
        :meal_plan_id,
        :meal_plan_slot_id,
        :slot_name,
        :slot_time,
        :note,
        :rating
      ]

      argument :recipe_id, :uuid, allow_nil?: false
      argument :portion_milli, :integer, default: 1000

      change Kati.Meals.Changes.FreezeNutrition
    end

    # An ad-hoc meal with no recipe behind it — eating out, or a plate someone
    # else cooked. The figures are the caller's, because there is nothing to
    # derive them from, but they freeze on exactly the same terms.
    create :log_manual do
      accept [
        :logged_on,
        :logged_at,
        :state,
        :meal_plan_id,
        :meal_plan_slot_id,
        :note,
        :rating,
        :title,
        :slot_name,
        :slot_time,
        :portion_milli,
        :kcal,
        :protein_mg,
        :carbs_mg,
        :fat_mg,
        :fibre_mg,
        :sugar_mg,
        :sodium_mg
      ]

      change set_attribute(:frozen_at, &DateTime.utc_now/0)
    end

    # State and the user's own remarks. No figure is in the accept list, and the
    # change fails the write if one is forced in anyway.
    update :mark do
      primary? true
      require_atomic? false
      accept [:state, :note, :rating]
      change Kati.Meals.Changes.RejectSnapshotChange
    end

    read :on_day do
      argument :on, :date, allow_nil?: false
      filter expr(logged_on == ^arg(:on))
      prepare build(sort: [slot_time: :asc, logged_at: :asc])
    end

    read :between do
      argument :from, :date, allow_nil?: false
      argument :to, :date, allow_nil?: false
      filter expr(logged_on >= ^arg(:from) and logged_on <= ^arg(:to))
    end
  end

  @doc """
  Log that a planned slot was eaten, from the row the page drew.

  **Two screens mean "I ate this" and this is the one thing they do.** Screen
  43's timeline card and screen 45's `Mark eaten` both write this action, and
  before this function they each spelled the attributes out — the same seven
  keys, twice, and both spellings were missing the same two. So a meal logged
  from either screen came back with no clock and no slot name, and the two
  screens could have started disagreeing about the eighth key the day one of
  them grew it. `Kati.Screens.Books.rail/2` exists for the same reason one
  layer up: one value, one implementation, or two readers will eventually
  print two answers.

  ## It writes about the row it is handed, and refuses anything else

  `row` is a timeline row or a screen 45 page — whichever the page RESOLVED
  and is drawing — and this function reads its `:slot_id` and `:recipe_id` and
  nothing else. It never queries for "the next meal" or "the plan's head", so
  there is no path by which the log lands on a meal the reader was not looking
  at. A row without both ids is a drawn one, and a drawn one is not a row:
  `:error` comes back and the caller leaves the store alone.

  The figures are deliberately absent from the map below —
  `Kati.Meals.Changes.FreezeNutrition` computes them from the recipe at this
  instant, which is the whole point of the resource.
  """
  @spec log_eaten(map()) :: {:ok, struct()} | :error | {:error, term()}
  def log_eaten(row) when is_map(row) do
    slot_id = Map.get(row, :slot_id)
    recipe_id = Map.get(row, :recipe_id)

    if is_binary(slot_id) and is_binary(recipe_id) do
      __MODULE__
      |> Ash.Changeset.for_create(:log_recipe, %{
        recipe_id: recipe_id,
        portion_milli: Map.get(row, :portion_milli) || Kati.Meals.Nutrition.one_portion(),
        logged_on: Kati.Time.today(),
        logged_at: Kati.Time.now() |> DateTime.truncate(:microsecond),
        state: :eaten,
        meal_plan_id: Map.get(row, :plan_id),
        meal_plan_slot_id: slot_id,
        # The card's own eyebrow and time gutter, carried onto the snapshot so
        # the logged card keeps the name and the clock the planned card had.
        # Off the ROW rather than off a fresh read of the slot, for the same
        # reason the ids are: the page drew these two strings, and re-reading
        # the slot here would let a swap that landed in between rename a meal
        # the reader has just said they ate.
        slot_name: Map.get(row, :slot_name),
        slot_time: Map.get(row, :slot_time)
      })
      |> Ash.create()
      |> Kati.Write.note("mark eaten #{Map.get(row, :title)}")
    else
      :error
    end
  end

  def log_eaten(_row), do: :error
end
