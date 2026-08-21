defmodule Kati.Meals.Food do
  @moduledoc """
  A food Kati or the user wrote. Never imported, never licensed, never evicted.

  ## The Persian layer is why this table has no USDA columns

  K-41 found that **no Persian food dataset exists anywhere**, so Kati authors
  one. If `foods` were a USDA table with a nullable provenance, every Persian row
  would be a row with six empty columns and an implied apology, and the first
  query someone wrote would be `where fdc_id is not null`. Instead the USDA
  corpus lives in `Kati.Meals.BundledFood` with its own keys, and this table has
  no notion of an upstream id at all. A `:persian` row here is not missing
  anything.

  `cuisine` is nullable because most foods belong to no cuisine in particular —
  it marks the ones Kati authored *as* a cuisine's vocabulary, which is what
  makes the Persian layer findable.

  ## Why the remembered price lives here and nowhere else

  Screen 48 shows `£41.20 est.` and there is no price source in the world Kati
  can reach — see #71's fourth question. The answer taken here is the honest one:
  the user enters a price, Kati remembers the last one paid, and the estimate is
  a sum over the items that have one.

  A remembered price is the **user's own fact**, so it can only be stored on a
  row the user owns. `Kati.Meals.LicensedFood` is evictable and
  `Kati.Meals.BundledFood` is read-only, so neither can hold it — the licence
  split earns itself here rather than only in a licence audit.

  Figures are **per 100 g** and every one of them is nullable, because a food
  someone typed the name of is a useful row before anybody has looked up its
  protein.
  """
  use Ash.Resource, domain: Kati.Meals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "foods"
    repo Kati.Repo

    custom_indexes do
      index [:name]
      index [:cuisine]
      index [:default_aisle]
    end
  end

  attributes do
    uuid_primary_key :id

    # Two values only. Anything under another party's terms is a different
    # table; see `Kati.Meals.LicensedFood`.
    attribute :licence, :atom,
      allow_nil?: false,
      default: :user_authored,
      public?: true,
      constraints: [one_of: [:kati_original, :user_authored]]

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :name_original, :string, public?: true

    # nil is the common case. `:persian` is the layer K-41 says Kati has to
    # author itself.
    attribute :cuisine, :atom,
      public?: true,
      constraints: [one_of: [:persian, :british, :levantine, :east_asian, :south_asian]]

    attribute :default_aisle, :atom,
      allow_nil?: false,
      default: :other,
      public?: true,
      constraints: [one_of: Kati.Meals.Aisle.values()]

    # ── Per 100 g, nullable (see the moduledoc) ────────────────────────────
    attribute :kcal, :integer, public?: true
    attribute :protein_mg, :integer, public?: true
    attribute :carbs_mg, :integer, public?: true
    attribute :fat_mg, :integer, public?: true
    attribute :fibre_mg, :integer, public?: true
    attribute :sugar_mg, :integer, public?: true
    attribute :sodium_mg, :integer, public?: true

    # ── The remembered price (#71, screen 48) ──────────────────────────────
    # Minor units, so £4.12 is 412 and nothing rounds. The currency travels with
    # it because a plan can be shared across a border and a bare number would be
    # silently wrong rather than obviously missing.
    attribute :last_price_minor, :integer, public?: true
    attribute :last_price_currency, :string, public?: true
    attribute :last_price_at, :utc_datetime_usec, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :by_cuisine do
      argument :cuisine, :atom, allow_nil?: false
      filter expr(cuisine == ^arg(:cuisine))
    end

    # Records what this actually cost, which is the only price source Kati has.
    update :remember_price do
      require_atomic? false
      accept [:last_price_minor, :last_price_currency]
      change set_attribute(:last_price_at, &DateTime.utc_now/0)
    end
  end
end
