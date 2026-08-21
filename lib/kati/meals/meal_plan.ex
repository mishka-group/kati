defmodule Kati.Meals.MealPlan do
  @moduledoc """
  A plan, which is Kati's profile mechanism. Screens 44 and 49.

  Screen 49 states the rule this table is shaped by: *"A plan owns its meals,
  its targets and its reminder times, and exactly one is active."* So the targets
  and the reminder settings are columns **here** rather than app-wide settings —
  switching a plan swaps all three at once, and nothing has to be re-entered when
  an old one comes back.

  "Exactly one active" is a partial unique index, not a convention. A second
  active plan makes every "what am I eating" query ambiguous, and the day it
  happens is the day someone is debugging a screen rather than a write.

  ## The plan is a rule, not 52 copies

  Screen 44's caption. `Kati.Meals.MealPlanSlot` holds **one week** — five slots
  across seven days, the 35 meals screen 50 offers to share — and `repeat` says
  it recurs. A year of a plan is 35 rows and a rule, never 1 820 rows.

  `repeat` has one value. A single-valued enum is the honest way to say that
  weekly is the only rule the design draws, and it leaves room for a second
  without a migration over user data.

  ## Switching (#71's third question)

  Screen 49 draws three switching rows. Two are modelled and one is not:

    * **"Switch takes effect · Next Monday"** is `activates_on`. It is drawn as a
      disclosure rather than a toggle because it opens a date, and a date is what
      it stores.
    * **"Keep the history · Past days stay on their old plan"** is
      `keep_history`, and it is what makes a switch safe: a `Kati.Meals.MealLog`
      already names the plan it was logged under, so the past does not move.
    * **"Auto-switch · Travel week when a trip is on the calendar"** is
      **retired**. There is no trip in Kati — no travel entity, no location
      state, and the calendar's own "follows travel" is a separate open question
      (#71, K-49). A boolean pointing at a concept the schema cannot express is a
      column that can only ever be false, so it is absent and the scheduled
      switch above carries the intent instead.

  ## Calendar rows are a projection

  Screen 52 draws meals on the day spine. They are **not** written to `events`.
  Meals owns its rows and the calendar asks for them; duplicating a plan into 35
  events per week would give two tables that disagree the first time a slot moved,
  and `Kati.Calendars.Event.kind`'s `:meal` value exists for a mirrored external
  calendar's meal, not for Kati's own plan.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "meal_plans"
    repo Kati.Repo

    custom_indexes do
      # Exactly one active plan. A partial unique index over a single row's
      # worth of state, which SQLite supports and a convention does not.
      index [:status],
        unique: true,
        where: "status = 'active'",
        name: "meal_plans_single_active_index",
        message: "another plan is already active"

      index [:status, :last_used_on]
      index [:activates_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true

    attribute :status, :atom,
      allow_nil?: false,
      default: :saved,
      public?: true,
      constraints: [one_of: [:active, :saved, :archived]]

    attribute :origin, :atom,
      allow_nil?: false,
      default: :user,
      public?: true,
      constraints: [one_of: [:user, :imported]]

    # Screen 49's "Jo's plan · shared with you". A name, not an account: Kati is
    # device-first and there is nobody to look up.
    attribute :imported_from, :string, public?: true
    attribute :imported_at, :utc_datetime_usec, public?: true

    # ── The rule (screen 44's repeat card) ─────────────────────────────────
    attribute :repeat, :atom,
      allow_nil?: false,
      default: :weekly,
      public?: true,
      constraints: [one_of: [:weekly]]

    # "Started · Week 6 · 6 Jul 2026". A date, not an instant: a plan starts on
    # a day wherever you are.
    attribute :starts_on, :date, public?: true
    # nil is "indefinitely", which is what screen 44 draws. 12 is "week 6 of 12".
    attribute :weeks_total, :integer, public?: true

    # ── Switching ──────────────────────────────────────────────────────────
    attribute :activates_on, :date, public?: true
    attribute :keep_history, :boolean, allow_nil?: false, default: true, public?: true
    attribute :last_used_on, :date, public?: true
    attribute :use_count, :integer, allow_nil?: false, default: 0, public?: true

    # ── Targets (screen 49's "2,100 kcal · 168P 210C 70F") ─────────────────
    attribute :target_kcal, :integer, public?: true
    attribute :target_protein_mg, :integer, public?: true
    attribute :target_carbs_mg, :integer, public?: true
    attribute :target_fat_mg, :integer, public?: true
    attribute :target_fibre_mg, :integer, public?: true

    # Screen 47's target tick sits at 95% on every bar — the tolerance band,
    # not the target. Stored in per-mille so it is an integer like everything
    # else here.
    attribute :tolerance_permille, :integer, allow_nil?: false, default: 950, public?: true

    # ── Reminders (screen 51) ──────────────────────────────────────────────
    #
    # Meals is the one section allowed to push by default, and screen 51's four
    # "manners" rows are the price of that. They live on the plan because
    # screen 49 says a plan owns its reminder times.
    #
    # There is no `notification_actions` column. Mob supports no notification
    # actions on either platform (`mob-framework.md:1208-1213`), so screen 51's
    # inline Eaten/Skip/Snooze is retired — see #71's fifth question. The
    # notification deep-links into the meal instead, which needs no schema.
    attribute :reminders_enabled, :boolean, allow_nil?: false, default: true, public?: true
    attribute :reminder_lead_minutes, :integer, allow_nil?: false, default: 15, public?: true
    attribute :evening_preview_at, :time, public?: true
    attribute :quiet_hours_from, :time, public?: true
    attribute :quiet_hours_until, :time, public?: true
    attribute :skip_during_events, :boolean, allow_nil?: false, default: true, public?: true
    attribute :stop_after_skips, :integer, allow_nil?: false, default: 2, public?: true
    attribute :silent_only, :boolean, allow_nil?: false, default: false, public?: true

    attribute :photo_seed, :string, public?: true
    attribute :tags, :string, public?: true

    timestamps()
  end

  relationships do
    has_many :slots, Kati.Meals.MealPlanSlot
    has_many :logs, Kati.Meals.MealLog
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :active do
      get? true
      filter expr(status == :active)
    end

    # Stands a plan down so another can take the active slot. Two writes with no
    # transaction to hold them, so this one goes FIRST: a moment with no active
    # plan reads as "nothing planned", which is recoverable, while a moment with
    # two reads as a corrupt database and trips the unique index.
    update :stand_down do
      require_atomic? false
      accept []
      change set_attribute(:status, :saved)
    end

    update :activate do
      require_atomic? false
      accept []
      change set_attribute(:status, :active)
      change Kati.Meals.Changes.RecordUse
    end
  end
end
