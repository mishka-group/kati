defmodule Kati.BackupCatalogTest do
  @moduledoc """
  The classification table, held to the schema it claims to describe.

  Every assertion here exists because the failure it catches is silent. A
  resource added in a later round and never classified would simply not be in
  anyone's backup, and nobody would find out until a restore came back short. A
  column added to a backed-up resource would go in the file without the schema
  version moving, and an older app would then read a newer file and drop it.
  Neither shows up in a round-trip test, because a round-trip test only proves
  the things it already knows about.
  """
  use ExUnit.Case, async: true

  alias Kati.Backup.Catalog

  # Moves when any backed-up table gains, loses or renames a column. When it
  # does: decide whether an older app could still read the file, bump
  # `Kati.Backup.Catalog.schema_version/0` if it could not, add the
  # `Kati.Backup.Upgrade` step, and paste the new value here.
  #
  # It last moved when `Kati.Sync.RejectedChange` was promoted out of
  # `:internal`: the rows hold property values the user typed, and a backup
  # that left them out would discard, on the next restore, exactly what the
  # merge kept them for. That took `schema_version` to 2 and added the 1 -> 2
  # upgrade step, which is what `Kati.BackupFormatTest` and
  # `Kati.BackupRoundTripTest` hold to a version-1 file that must still open.
  @fingerprint "7f6e13a96c54f6e3331b5628ee47f0510e1de76c04c76ccbe442fc2683c06b0e"

  @schema_version 7

  describe "every resource is classified" do
    test "no resource in any domain is missing from both lists" do
      classified =
        MapSet.new(Enum.map(Catalog.entries(), & &1.resource)) |> MapSet.union(excluded())

      all = MapSet.new(Enum.flat_map(Catalog.domains(), &Ash.Domain.Info.resources/1))

      assert MapSet.size(all) > 0
      assert MapSet.difference(all, classified) |> MapSet.to_list() == []
    end

    test "nothing is classified twice, or classified without existing" do
      backed_up = MapSet.new(Enum.map(Catalog.entries(), & &1.resource))
      all = MapSet.new(Enum.flat_map(Catalog.domains(), &Ash.Domain.Info.resources/1))

      assert MapSet.intersection(backed_up, excluded()) |> MapSet.to_list() == []
      assert MapSet.difference(backed_up, all) |> MapSet.to_list() == []
      assert MapSet.difference(excluded(), all) |> MapSet.to_list() == []
    end

    test "every exclusion states a reason and a class" do
      for %{resource: resource, class: class, why: why} <- Catalog.excluded() do
        assert class in [:cache, :bundled, :internal], "#{inspect(resource)}"
        assert String.length(why) > 40, "#{inspect(resource)} needs a reason, not a label"
      end

      assert length(Catalog.excluded()) == 7
    end

    test "the domains it checks are the domains the app configures" do
      # Host-only: `:ash_domains` is config, and config never reaches a phone.
      # That is exactly why `Catalog.domains/0` is a literal — this test is what
      # keeps the literal honest.
      assert Enum.sort(Catalog.domains()) ==
               Enum.sort(Application.fetch_env!(:kati, :ash_domains))
    end

    test "the evictable and bundled halves are out, by name" do
      out = MapSet.new(Enum.map(Catalog.excluded(), & &1.resource))

      assert Kati.Media.CachedTitle in out
      assert Kati.Meals.LicensedFood in out
      assert Kati.Meals.BundledFood in out
    end

    test "the two sync tables are split by what they hold, not by their domain" do
      in_backup = MapSet.new(Enum.map(Catalog.entries(), & &1.resource))
      out = MapSet.new(Enum.map(Catalog.excluded(), & &1.resource))

      # A rejected change is the losing half of a conflict, held so the user can
      # put it back — property values they typed, which nothing re-fetches.
      # Leaving it out would make a restore finish the deletion the merge
      # refused to do.
      assert Kati.Sync.RejectedChange in in_backup

      # The outbox is a queue of intentions whose edits are already applied to
      # `events`, and whose every column is true only of this device.
      assert Kati.Sync.OutboxEntry in out
    end

    test "everything the user authors is in, by name" do
      in_backup = MapSet.new(Enum.map(Catalog.entries(), & &1.resource))

      for resource <- [
            Kati.Media.TrackedTitle,
            Kati.Media.Watch,
            Kati.Meals.Food,
            Kati.Meals.Recipe,
            Kati.Meals.RecipeIngredient,
            Kati.Meals.MealPlan,
            Kati.Meals.MealPlanSlot,
            Kati.Meals.MealLog,
            Kati.Meals.ShoppingListItem,
            Kati.Calendars.Account,
            Kati.Calendars.Calendar,
            Kati.Calendars.Event,
            Kati.Calendars.Override,
            Kati.Sync.RejectedChange
          ] do
        assert resource in in_backup, "#{inspect(resource)} holds user data and must be backed up"
      end
    end
  end

  describe "insert order" do
    test "a parent is always before its children" do
      tables = Catalog.tables()
      backed_up = Map.new(Catalog.entries(), &{&1.resource, &1.table})

      for entry <- Catalog.entries(), parent <- parents(entry.resource) do
        case Map.fetch(backed_up, parent) do
          {:ok, parent_table} ->
            assert index(tables, parent_table) < index(tables, entry.table),
                   "#{entry.table} points at #{parent_table} and is written before it"

          :error ->
            # A reference into a table the backup does not carry is only safe
            # because the column is dropped — SQLite enforces foreign keys, so
            # anything else would fail on the very first restore.
            assert Enum.any?(
                     Catalog.dropped_columns(entry),
                     &(&1 |> Atom.to_string() |> String.ends_with?("_id"))
                   ),
                   "#{entry.table} references #{inspect(parent)}, which is not in the backup, " <>
                     "and drops no reference column"
        end
      end
    end

    test "every table appears exactly once" do
      assert Catalog.tables() == Enum.uniq(Catalog.tables())
      assert length(Catalog.tables()) == 26
    end

    test "every backed-up resource keys on a single :id column" do
      # `Kati.Backup.Export` sorts by `.id` and `Kati.Backup.Verify` checks ids
      # for duplicates. A composite key would make both quietly wrong.
      for entry <- Catalog.entries() do
        assert Ash.Resource.Info.primary_key(entry.resource) == [:id],
               "#{entry.table} does not key on :id alone"
      end
    end
  end

  describe "dropped columns" do
    test "each one is a real attribute of its resource" do
      for entry <- Catalog.entries(), column <- Catalog.dropped_columns(entry) do
        assert Ash.Resource.Info.attribute(entry.resource, column),
               "#{entry.table} drops #{column}, which it does not have"
      end
    end

    test "the three drops are the three the format documents" do
      dropped =
        Catalog.entries()
        |> Enum.flat_map(fn entry ->
          Enum.map(Catalog.dropped_columns(entry), &"#{entry.table}.#{&1}")
        end)
        |> Enum.sort()

      assert dropped == [
               "calendar_accounts.credentials_ref",
               "recipe_ingredients.bundled_food_id",
               "recipe_ingredients.licensed_food_id"
             ]
    end

    test "a dropped column is still a column, so a restore cannot miss it" do
      entry = Enum.find(Catalog.entries(), &(&1.table == "recipe_ingredients"))

      assert :bundled_food_id in Catalog.columns(entry)
      assert :licensed_food_id in Catalog.columns(entry)
    end
  end

  describe "the schema version" do
    test "the fingerprint of every backed-up column is the one this version pins" do
      assert Catalog.fingerprint() == @fingerprint, """
      A backed-up table's columns have changed.

      Decide whether an app running the previous schema version could still
      read a file written by this one. If it could not, bump
      Kati.Backup.Catalog.schema_version/0 and add a Kati.Backup.Upgrade step
      so older backups keep opening. Then paste the new fingerprint here:

          #{Catalog.fingerprint()}
      """
    end

    test "the version this test was written against is the version in the code" do
      assert Catalog.schema_version() == @schema_version
      assert Catalog.format_version() == 1
      assert Catalog.format() == "kati.backup"
    end

    test "columns are sorted, so the bytes do not depend on declaration order" do
      for entry <- Catalog.entries() do
        assert Catalog.columns(entry) == Enum.sort(Catalog.columns(entry))
      end
    end
  end

  describe "the published format document" do
    test "names every table the backup carries" do
      doc = File.read!("docs/backup-format.md")

      for table <- Catalog.tables() do
        assert doc =~ table, "docs/backup-format.md does not mention #{table}"
      end
    end

    test "names every resource the backup leaves out, and every dropped column" do
      doc = File.read!("docs/backup-format.md")

      for %{resource: resource} <- Catalog.excluded() do
        assert doc =~ inspect(resource),
               "docs/backup-format.md does not say why #{inspect(resource)} is excluded"
      end

      for entry <- Catalog.entries(), column <- Catalog.dropped_columns(entry) do
        assert doc =~ "#{entry.table}.#{column}",
               "docs/backup-format.md does not say why #{entry.table}.#{column} is dropped"
      end
    end
  end

  test "an unknown table is refused by name" do
    assert {:error, error} = Catalog.fetch("horoscopes")
    assert error.reason == :unknown_resource
    assert error.message =~ "horoscopes"
  end

  defp excluded, do: MapSet.new(Enum.map(Catalog.excluded(), & &1.resource))

  defp parents(resource) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.filter(&(&1.type == :belongs_to))
    |> Enum.map(& &1.destination)
  end

  defp index(list, value), do: Enum.find_index(list, &(&1 == value))
end
