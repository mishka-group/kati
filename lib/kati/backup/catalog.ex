defmodule Kati.Backup.Catalog do
  @moduledoc """
  What goes in a backup, what stays out, and why — in one list.

  This module is the answer to #64's first requirement: *"Enumerate every Ash
  resource and mark each `:backup` / `:cache` / `:secret`."* It is a literal
  table rather than something derived, because "is this the user's own work?"
  is a judgement about meaning that no introspection can make. What **is**
  derived is the column list of each backed-up table, read from the resource
  itself — so a new column is in the backup the day it exists, and cannot be
  forgotten.

  `Kati.BackupCatalogTest` fails the build if a resource in any domain is
  missing from both lists, so a resource added in a later round cannot quietly
  fall out of the backup.

  ## The classification test

  A table is **`:backup`** when a row in it can hold something the user
  authored — typed, ticked, rated, planned, corrected — that no network and no
  re-seed can reproduce. Everything else is out:

    * **`:cache`** — third-party metadata behind a `fetched_at` eviction sweep.
      Restoring it would be restoring someone else's data, months after the
      terms it was fetched under allowed it to be kept, and it re-fetches on
      its own. `Kati.Media.CachedTitle` and `Kati.Meals.LicensedFood`.
    * **`:bundled`** — the CC0 corpus shipped in `priv/`. Identical on every
      install, so a copy in the file is bytes for nothing.
    * **`:internal`** — a development spike, or a table Mob owns.
    * **`:device_bound`** — a *column*, not a table: an opaque handle into a
      keystore this device has and the next one does not.

  ## Dropped columns, and why that is not silent loss

  Three columns are written as `null` into the payload:

    * `recipe_ingredients.bundled_food_id` and `recipe_ingredients.licensed_food_id`
      point into tables the backup does not carry, and SQLite enforces foreign
      keys, so a restore would fail on the reference. What is lost is
      **provenance only** — the ingredient row carries its own name, amount,
      unit, aisle and all seven nutrition figures, so the recipe restores whole
      and correct.
    * `calendar_accounts.credentials_ref` is a handle into the device keystore
      (#55). Carrying it would restore an account that claims a key the new
      phone has never seen.

  Every one of them is counted into the manifest's `dropped_columns`, so the
  loss is stated in the file rather than discovered later. Any attribute marked
  `sensitive?: true` is dropped by the same mechanism, automatically.

  ## Insert order

  `entries/0` is in foreign-key order: a parent is always before its children,
  and a `:replace` restore deletes in exactly the reverse. `Kati.BackupCatalogTest`
  proves the order rather than trusting the comment, by walking each resource's
  `belongs_to` relationships.
  """

  alias Kati.Backup.Error

  @format "kati.backup"
  @format_version 1

  # Bump this — and the fingerprint in `Kati.BackupCatalogTest` — whenever a
  # backed-up column is added, removed, renamed, or changes encoding. The test
  # is what makes the rule real: it fails on the change, not on the next
  # restore of a file the change silently broke.
  @schema_version 1

  # Every domain whose resources must be classified. Not read from
  # `:ash_domains`: that key is host-only config and is `nil` on a phone
  # (`Kati.Runtime`'s moduledoc), so a device-side check would silently pass by
  # finding nothing.
  @domains [Kati.Spike, Kati.Calendars, Kati.Media, Kati.Meals]

  @entries [
    %{table: "calendar_accounts", resource: Kati.Calendars.Account, drop: [:credentials_ref]},
    %{table: "calendars", resource: Kati.Calendars.Calendar, drop: []},
    %{table: "events", resource: Kati.Calendars.Event, drop: []},
    %{table: "event_occurrence_overrides", resource: Kati.Calendars.Override, drop: []},
    %{table: "tracked_titles", resource: Kati.Media.TrackedTitle, drop: []},
    %{table: "media_watches", resource: Kati.Media.Watch, drop: []},
    %{table: "foods", resource: Kati.Meals.Food, drop: []},
    %{table: "recipes", resource: Kati.Meals.Recipe, drop: []},
    %{
      table: "recipe_ingredients",
      resource: Kati.Meals.RecipeIngredient,
      drop: [:bundled_food_id, :licensed_food_id]
    },
    %{table: "meal_plans", resource: Kati.Meals.MealPlan, drop: []},
    %{table: "meal_plan_slots", resource: Kati.Meals.MealPlanSlot, drop: []},
    %{table: "meal_logs", resource: Kati.Meals.MealLog, drop: []},
    %{table: "shopping_list_items", resource: Kati.Meals.ShoppingListItem, drop: []}
  ]

  @excluded [
    %{
      resource: Kati.Media.CachedTitle,
      class: :cache,
      why:
        "Third-party title metadata under a provider's terms, behind a fetched_at " <>
          "eviction sweep. The user's half references it by {source, source_id} as a " <>
          "value, so nothing is orphaned by leaving it out, and it re-fetches."
    },
    %{
      resource: Kati.Meals.LicensedFood,
      class: :cache,
      why:
        "Food data under someone else's licence, with a not-null fetched_at so the " <>
          "eviction sweep reaches it. Re-fetched, never re-distributed."
    },
    %{
      resource: Kati.Meals.BundledFood,
      class: :bundled,
      why:
        "The CC0 corpus shipped in priv/. Byte-identical on every install, so a copy " <>
          "in the backup is size for nothing."
    },
    %{
      resource: Kati.Spike.Thing,
      class: :internal,
      why: "A migration spike. Holds no user data and is not drawn anywhere."
    }
  ]

  @doc "The archive's format marker, written into every manifest."
  @spec format() :: String.t()
  def format, do: @format

  @doc "The file-layout version: manifest shape, member names, hashing."
  @spec format_version() :: pos_integer()
  def format_version, do: @format_version

  @doc "The row-shape version. See the moduledoc for when it moves."
  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @doc "Every domain whose resources this module is required to classify."
  @spec domains() :: [module()]
  def domains, do: @domains

  @doc "The backed-up tables, parents before children."
  @spec entries() :: [map()]
  def entries, do: @entries

  @doc "The backed-up table names, in insert order."
  @spec tables() :: [String.t()]
  def tables, do: Enum.map(@entries, & &1.table)

  @doc "The resources that are deliberately absent, each with its reason."
  @spec excluded() :: [map()]
  def excluded, do: @excluded

  @doc "The entry for one table, or an error naming the file that asked for it."
  @spec fetch(String.t()) :: {:ok, map()} | {:error, Error.t()}
  def fetch(table) do
    case Enum.find(@entries, &(&1.table == table)) do
      nil ->
        Error.error(
          :unknown_resource,
          "This backup contains data for #{table}, which this version of Kati does not know about.",
          %{table: table, known: tables()}
        )

      entry ->
        {:ok, entry}
    end
  end

  @doc """
  Every attribute of a backed-up resource, sorted by name.

  Sorted so the payload's column order — and therefore the bytes, and therefore
  the SHA-256 — does not depend on the order someone happened to declare the
  attributes in.
  """
  @spec attributes(map()) :: [Ash.Resource.Attribute.t()]
  def attributes(entry) do
    entry.resource
    |> Ash.Resource.Info.attributes()
    |> Enum.sort_by(& &1.name)
  end

  @doc "The column names of a backed-up table, sorted."
  @spec columns(map()) :: [atom()]
  def columns(entry), do: entry |> attributes() |> Enum.map(& &1.name)

  @doc """
  The columns written as `null` — the declared drops plus anything the resource
  marks `sensitive?`.
  """
  @spec dropped_columns(map()) :: [atom()]
  def dropped_columns(entry) do
    sensitive =
      entry
      |> attributes()
      |> Enum.filter(& &1.sensitive?)
      |> Enum.map(& &1.name)

    (entry.drop ++ sensitive) |> Enum.uniq() |> Enum.sort()
  end

  @doc """
  A hash over every backed-up table and column.

  `Kati.BackupCatalogTest` pins this to a literal. A column added to a
  backed-up resource moves it, the test fails, and whoever added the column is
  told to bump `schema_version/0` — which is the only thing that makes the
  version rule mean anything.
  """
  @spec fingerprint() :: String.t()
  def fingerprint do
    @entries
    |> Enum.map_join("\n", fn entry ->
      cols = entry |> columns() |> Enum.map_join(",", &Atom.to_string/1)
      "#{entry.table}:#{cols}"
    end)
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
