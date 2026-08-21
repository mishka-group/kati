defmodule Kati.Meals.BundledFood do
  @moduledoc """
  The CC0 reference corpus that ships in `priv/`. **Read-only, and CC0 only.**

  ## Why this is its own table

  The USDA rows are public domain. Open Food Facts is ODbL, which is a share-alike
  licence: merge one into the other and the combined table is a derived database,
  and the CC0 rows lose their unencumbered status. That is not a rule anyone can
  be trusted to remember at 2am while fixing a bug, so it is a table boundary
  instead — `licence` here accepts `:cc0` and nothing else, so a row under any
  other licence physically cannot be written to `bundled_foods`. Anything with
  someone else's terms goes to `Kati.Meals.LicensedFood`; anything Kati or the
  user wrote goes to `Kati.Meals.Food`.

  `Kati.Meals.RecipeIngredient` therefore carries three separate nullable
  references rather than one polymorphic pointer: the licence boundary is
  visible at every place a food is referenced, not only where it is stored.

  ## No `fetched_at`

  #73 requires `fetched_at` wherever third-party metadata is cached, and these
  rows are not cached — they are bundled, they never expire, and evicting them
  would delete something no network call can bring back. `bundle_version` is the
  equivalent bookkeeping: it says which shipped file a row came from, so a
  re-import can replace a corpus wholesale.

  Figures are **per 100 g**, which is how the source publishes them.
  `Kati.Meals.Nutrition.for_amount/2` is what turns that into an ingredient line.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "bundled_foods"
    repo Kati.Repo

    custom_indexes do
      index [:corpus, :source_key], unique: true, message: "already in this corpus"
      # The name search behind "add an ingredient".
      index [:name]
      index [:default_aisle]
    end
  end

  attributes do
    uuid_primary_key :id

    # ── Provenance ─────────────────────────────────────────────────────────
    # One value, deliberately. A second licence in this table is a merge, and a
    # merge is what relicenses the CC0 rows — so it fails at the constraint
    # rather than in a licence audit two years later.
    attribute :licence, :atom,
      allow_nil?: false,
      default: :cc0,
      public?: true,
      constraints: [one_of: [:cc0]]

    attribute :corpus, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:usda_foundation, :usda_sr_legacy, :usda_fndds]]

    # The upstream key — an FDC id for every corpus above. A string, because a
    # future CC0 corpus need not number its rows.
    attribute :source_key, :string, allow_nil?: false, public?: true
    attribute :bundle_version, :string, allow_nil?: false, public?: true

    # ── The food ───────────────────────────────────────────────────────────
    attribute :name, :string, allow_nil?: false, public?: true

    attribute :default_aisle, :atom,
      allow_nil?: false,
      default: :other,
      public?: true,
      constraints: [one_of: Kati.Meals.Aisle.values()]

    # ── Per 100 g, integers (see Kati.Meals.Nutrition) ─────────────────────
    attribute :kcal, :integer, allow_nil?: false, default: 0, public?: true
    attribute :protein_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :carbs_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fat_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :fibre_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sugar_mg, :integer, allow_nil?: false, default: 0, public?: true
    attribute :sodium_mg, :integer, allow_nil?: false, default: 0, public?: true

    timestamps()
  end

  actions do
    defaults [:read]
    default_accept []

    # The only writer is the bundle loader. Named for what it is so a call site
    # that is doing something else is obvious in a diff.
    create :seed do
      accept [
        :corpus,
        :source_key,
        :bundle_version,
        :name,
        :default_aisle,
        :kcal,
        :protein_mg,
        :carbs_mg,
        :fat_mg,
        :fibre_mg,
        :sugar_mg,
        :sodium_mg
      ]
    end

    # Replacing a corpus wholesale is how a newer bundle lands. Individual rows
    # are never edited: an edit would be a Kati-authored fact about someone
    # else's data, and those belong on `Kati.Meals.Food`.
    destroy :evict_corpus do
      primary? true
    end

    read :in_corpus do
      argument :corpus, :atom, allow_nil?: false
      filter expr(corpus == ^arg(:corpus))
    end
  end
end
