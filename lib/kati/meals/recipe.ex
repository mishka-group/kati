defmodule Kati.Meals.Recipe do
  @moduledoc """
  A meal that can be cooked and counted. Screen 45, in full.

  Everything is stored **at one portion**, because screen 45's multiplier is the
  thing that rescales it: *"Every figure is stored at one portion."* `serves` is
  what the method yields and is a fact about the pan, never a divisor — the
  ingredient lines are already per portion, so their sum is the per-portion
  total.

  ## The cached totals, and the rule that keeps them honest

  AshSqlite has no resource aggregates and `can?(:transact)` is `false`
  (`ash_sqlite-0.2.17/lib/data_layer.ex:444-514`), so `total_kcal` and its six
  siblings are columns the write path maintains, not sums the database computes.
  Two writes that must agree, with no transaction to hold them together, is
  exactly the shape that rots silently. So:

    * **`ingredients_rev`** is bumped by the write path **before** an ingredient
      row is touched.
    * **`totals_rev`** is set to whatever `ingredients_rev` was when the totals
      were last computed.
    * **`totals_rev < ingredients_rev` means stale**, and every read that cares
      recomputes rather than trusting the columns.

  That ordering is the partial-failure rule. Crash between the bump and the
  ingredient write and the recipe is marked stale when it is not — a wasted
  recompute. Crash between the ingredient write and the recompute and it is
  marked stale when it is. The one thing that cannot happen is an ingredient
  changing while the cache still claims to be fresh, which is the failure that
  would put a wrong number into a frozen log for ever.

  It is the same counter shape as `Kati.Calendars.Event`'s
  `local_rev > synced_rev`, for the same reason a boolean will not do: a second
  edit landing while a recompute is in flight would clear a flag that is still
  owed.

  `Kati.Meals.Totals` owns every write to these columns. `:update` does not
  accept them.

  ## Third-party recipes

  Screen 50 imports "JSON, CSV, or a recipe URL". A recipe that came off the web
  is cached third-party metadata, so it carries `fetched_at` per K-30 — but it
  is **not** evictable, because the user has by then rated it, noted it and
  eaten it fourteen times. `fetched_at` here answers "how old is what we
  scraped", which is what a re-fetch prompt needs; the eviction sweep skips this
  table.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "recipes"
    repo Kati.Repo

    custom_indexes do
      index [:title]
      # The swap screen ranks on macro distance and on time to cook; both start
      # from a scan of this table.
      index [:total_kcal]
      index [:minutes]
      # The staleness scan: `where` cannot reference another column portably, so
      # this is a covering pair the sweep filters in Elixir.
      index [:ingredients_rev, :totals_rev]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false, public?: true

    attribute :origin, :atom,
      allow_nil?: false,
      default: :user,
      public?: true,
      constraints: [one_of: [:kati, :user, :imported]]

    # ── The method (screen 45's three facts and its paragraph) ─────────────
    attribute :method, :string, public?: true
    attribute :minutes, :integer, public?: true
    attribute :oven_c, :integer, public?: true
    attribute :serves, :integer, allow_nil?: false, default: 1, public?: true
    attribute :photo_seed, :string, public?: true

    # Screen 45's bookmark disc had nothing to hold it. The board draws the
    # control and the resource had no column, so the tap was on
    # `Kati.ScreenTapSweepTest`'s backlog — "a button that never marks
    # anything" — for as long as both existed.
    #
    # On the recipe rather than on a separate list, because a bookmark is a
    # fact about the recipe and not a row of its own: one boolean cannot get
    # out of step with the thing it describes, and a join table for a flag is
    # a second place for the same truth to live.
    attribute :bookmarked, :boolean, allow_nil?: false, default: false, public?: true

    # Which meal of the day this one usually is — `Breakfast`, `Lunch`,
    # `Dinner`, `Snack`, `Brunch`. Screen 116's chips group the library by it.
    #
    # A free string rather than an enum, and deliberately the same shape as
    # `Kati.Meals.MealLog.slot_name`: the vocabulary is the user's. Somebody
    # who eats second breakfast should be able to say so, and an enum would
    # make that a feature request rather than a word.
    #
    # Nullable, because a meal that is not any particular time of day is
    # ordinary — screen 116 shows it under `All` and under nothing else.
    attribute :slot_name, :string, public?: true

    # ── The user's own facts (screen 45's history rows) ────────────────────
    attribute :rating, :integer, public?: true, constraints: [min: 0, max: 5]
    attribute :note, :string, public?: true

    # ── Cached totals, at one portion. Written only by Kati.Meals.Totals. ──
    attribute :total_kcal, :integer, allow_nil?: false, default: 0, public?: true
    attribute :total_protein_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :total_carbs_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :total_fat_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :total_fibre_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :total_sugar_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :total_sodium_mg, :integer, allow_nil?: false, default: 0, public?: true

    attribute :ingredients_rev, :integer, allow_nil?: false, default: 0, public?: true
    attribute :totals_rev, :integer, allow_nil?: false, default: 0, public?: true

    # ── Third-party provenance ─────────────────────────────────────────────
    attribute :source_url, :string, public?: true
    attribute :fetched_at, :utc_datetime_usec, public?: true

    timestamps()
  end

  relationships do
    has_many :ingredients, Kati.Meals.RecipeIngredient do
      sort position: :asc
    end
  end

  actions do
    defaults [:read, :destroy]

    default_accept [
      :title,
      :origin,
      :method,
      :minutes,
      :oven_c,
      :serves,
      :photo_seed,
      # Screen 118's slot chips are the only control on that editor that
      # commits, so this is the only new field the editor can accept.
      :slot_name,
      # Screen 45's bookmark disc. On the accept list rather than behind an
      # action of its own because it is an ordinary edit to an ordinary field —
      # the narrowness this list is protecting is the TOTALS and the two revs,
      # which is what "an ordinary edit to the title cannot quietly rewrite a
      # cached macro figure" is about.
      :bookmarked,
      :rating,
      :note,
      :source_url,
      :fetched_at
    ]

    create :create do
      primary? true
    end

    # Deliberately narrow: the totals columns and the two revs are absent, so an
    # ordinary edit to the title cannot quietly rewrite a cached macro figure.
    update :update do
      primary? true
    end

    # Step one of the write path. Bumped BEFORE the ingredient row is touched —
    # see the moduledoc; the ordering is the whole rule.
    update :mark_ingredients_dirty do
      require_atomic? false
      accept []
      change Kati.Meals.Changes.BumpIngredientsRev
    end

    # Step three. Only `Kati.Meals.Totals` calls this, and it passes the rev the
    # figures were computed against so a concurrent bump is not swallowed.
    update :store_totals do
      require_atomic? false

      accept [
        :total_kcal,
        :total_protein_mg,
        :total_carbs_mg,
        :total_fat_mg,
        :total_fibre_mg,
        :total_sugar_mg,
        :total_sodium_mg,
        :totals_rev
      ]
    end

    read :with_stale_totals do
      filter expr(totals_rev < ingredients_rev)
    end
  end
end
