defmodule Kati.BackupRoundTripTest do
  @moduledoc """
  Populate, export, wipe, restore — against the same real SQLite file the rest
  of the schema tests use.

  #64 calls this "the single highest-value test in the project", and the reason
  is that every other test in this repository assumes the data is still there.
  So the assertions here are on **rows**, not on calls returning `:ok`: the
  whole exported shape before the wipe must equal the whole exported shape
  after the restore, column for column, and the counts must be positive first
  so that "equal" cannot mean "both empty".

  Three things are checked past the plain round trip, because each is a
  property that only breaks silently:

    * `Kati.Meals.MealLog`'s frozen figures come back **frozen**, proven by
      editing the recipe between the log and the export so that anything
      recomputing from today's recipe would produce a different number.
    * `Kati.Media.TrackedTitle.last_touched_at` comes back unmoved, which is
      what proves the restore is not replaying create actions —
      `Kati.Media.Changes.Touch` would stamp every shelf with the moment of the
      restore.
    * `inserted_at` comes back unmoved, for the same reason.
  """
  use ExUnit.Case, async: false

  alias Kati.Backup
  alias Kati.Backup.Archive
  alias Kati.Backup.Bundle
  alias Kati.Backup.Catalog
  alias Kati.Calendars.Account
  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.Event
  alias Kati.Calendars.Override
  alias Kati.Meals.BundledFood
  alias Kati.Meals.Food
  alias Kati.Meals.MealLog
  alias Kati.Meals.MealPlan
  alias Kati.Meals.MealPlanSlot
  alias Kati.Meals.Recipe
  alias Kati.Meals.RecipeIngredient
  alias Kati.Meals.ShoppingListItem
  alias Kati.Meals.Totals
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  # An opaque handle into the device keystore. It is not a secret, and it is
  # still device-bound: a restored account that claimed it would be pointing at
  # a key the new phone has never held. The test greps the produced bytes for
  # this exact string.
  @credentials_ref "keystore://kati/caldav/a71f-never-in-a-backup"

  # A review with the three things that break a naive serialiser, and a note
  # with Persian digits — which belong in a note and must never reach a date.
  @awkward_review "She said \"it's fine\", then, after a beat,\nit was not fine."
  @persian_note "دیدم ۱۲ مرداد — ۹ از ۱۰"

  # Screen 45's own X-property, kept verbatim so a re-export cannot regenerate a
  # VEVENT and throw it away.
  @raw_ical """
  BEGIN:VEVENT\r
  UID:standup@kati\r
  DTSTART;TZID=Europe/Amsterdam:20260817T090000\r
  RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR\r
  SUMMARY:Standup\r
  X-APPLE-STRUCTURED-LOCATION;VALUE=URI:geo:52.3676,4.9041\r
  END:VEVENT\r
  """

  # Every table this module writes to, children first. `cached_titles` is here
  # even though the backup never carries it: this module makes cache rows on
  # purpose, to prove a restore leaves them alone.
  @tables Enum.reverse(Catalog.tables()) ++ ["bundled_foods", "licensed_foods", "cached_titles"]

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  # ── The fixture ────────────────────────────────────────────────────────────

  defp populate! do
    account =
      create!(Account, :create, %{
        provider: :caldav,
        account_name: "jo@example.org",
        display_name: "Fastmail",
        credentials_ref: @credentials_ref,
        state: :live,
        last_sync_at: ~U[2026-08-16 06:00:00.000000Z]
      })

    calendar =
      create!(CalendarRow, :create, %{
        display_name: "Personal",
        kind: :provider,
        account_id: account.id,
        colour_token: :accent,
        visible: true,
        sync_cursor: "CiwKGjB..."
      })

    standup =
      create!(Event, :create, %{
        uid: "standup@kati",
        calendar_id: calendar.id,
        origin: :mirror,
        summary: "Standup",
        dtstart_wall: "20260817T090000",
        tzid: "Europe/Amsterdam",
        duration_iso: "PT15M",
        rrule: "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR",
        raw_icalendar: @raw_ical,
        unknown_props: ~s({"X-MOZ-LASTACK":"20260816T101500Z"})
      })

    birthday =
      create!(Event, :create, %{
        uid: "birthday@kati",
        calendar_id: calendar.id,
        origin: :kati,
        summary: "Mum's birthday",
        is_all_day: true,
        dtstart_date: ~D[2026-09-04],
        kind: :note
      })

    moved =
      create!(Override, :create, %{
        event_id: standup.id,
        calendar_id: calendar.id,
        event_uid: standup.uid,
        recurrence_id_utc: ~U[2026-08-19 07:00:00.000000Z],
        recurrence_id_wall: "20260819T090000",
        kind: :modified,
        summary: "Standup (late)",
        dtstart_wall: "20260819T100000"
      })

    cancelled =
      create!(Override, :create, %{
        event_id: standup.id,
        calendar_id: calendar.id,
        event_uid: standup.uid,
        recurrence_id_utc: ~U[2026-08-20 07:00:00.000000Z],
        recurrence_id_wall: "20260820T090000",
        kind: :cancelled
      })

    # Evictable third-party metadata. Never exported; never touched by a restore.
    create!(CachedTitle, :create, %{
      source: :tmdb,
      source_id: "603",
      kind: :movie,
      title: "The Matrix",
      overview: "A cache row, not a memory.",
      fetched_at: ~U[2026-08-01 00:00:00.000000Z]
    })

    tracked =
      create!(TrackedTitle, :create, %{
        source: :tmdb,
        source_id: "603",
        kind: :movie,
        status: :finished,
        rating: 9,
        user_override_date: ~D[2026-11-03],
        progress_seconds: 4_200
      })

    logged =
      create!(Watch, :create, %{
        tracked_title_id: tracked.id,
        watched_on: ~D[2026-08-12],
        watched_at: ~U[2026-08-12 19:40:00.000000Z],
        rating: 9,
        review: @awkward_review,
        companions: "Jo, Sam",
        tags: "rewatch,late night",
        service: "Lumen+",
        place: "living room",
        rewatch_number: 2
      })

    in_persian =
      create!(Watch, :create, %{
        tracked_title_id: tracked.id,
        watched_on: ~D[2026-08-03],
        review: @persian_note
      })

    food =
      create!(Food, :create, %{
        name: "White miso",
        licence: :user_authored,
        cuisine: :east_asian,
        default_aisle: :cupboard,
        kcal: 199,
        protein_mg: 12_000,
        last_price_minor: 289,
        last_price_currency: "GBP",
        last_price_at: ~U[2026-08-10 11:00:00.000000Z]
      })

    bundled =
      create!(BundledFood, :seed, %{
        corpus: :usda_foundation,
        source_key: "173_salmon",
        bundle_version: "2026.08",
        name: "Salmon, atlantic, raw",
        default_aisle: :fish_and_meat,
        kcal: 208
      })

    recipe = create!(Recipe, :create, %{title: "Miso salmon", minutes: 25, serves: 1})

    {_line, recipe} =
      Totals.write_ingredient(recipe, %{
        position: 0,
        name: "Salmon fillet",
        amount_mg: 150_000,
        unit: :g,
        aisle: :fish_and_meat,
        bundled_food_id: bundled.id,
        kcal: 312,
        protein_mg: 41_000
      })

    {miso_line, recipe} =
      Totals.write_ingredient(recipe, %{
        position: 1,
        name: "White miso",
        amount_mg: 15_000,
        unit: :g,
        aisle: :cupboard,
        food_id: food.id,
        kcal: 30,
        protein_mg: 2_000
      })

    plan = create!(MealPlan, :create, %{name: "Cutting v3", status: :saved, weeks_total: 12})

    slot =
      create!(MealPlanSlot, :create, %{
        meal_plan_id: plan.id,
        day_of_week: 1,
        position: 0,
        slot_name: "Dinner",
        slot_time: ~T[19:00:00.000000],
        recipe_id: recipe.id,
        state: :planned
      })

    log =
      create!(MealLog, :log_recipe, %{
        recipe_id: recipe.id,
        logged_on: ~D[2026-08-16],
        logged_at: ~U[2026-08-16 18:05:00.000000Z],
        meal_plan_id: plan.id,
        meal_plan_slot_id: slot.id,
        note: @persian_note
      })

    item =
      create!(ShoppingListItem, :create, %{
        meal_plan_id: plan.id,
        week_starting_on: ~D[2026-08-17],
        name: "White miso",
        aisle: :cupboard,
        amount_mg: 15_000,
        unit: :g,
        food_id: food.id,
        price_minor: 289,
        price_currency: "GBP",
        price_source: :remembered
      })

    # The edit that makes the frozen-figures assertion mean something: after
    # this, anything recomputing the log from the recipe gets a different number.
    {_line, edited} = Totals.update_ingredient(miso_line, %{kcal: 90, protein_mg: 6_000})
    refute edited.total_kcal == log.kcal

    %{
      account: account,
      calendar: calendar,
      standup: standup,
      birthday: birthday,
      moved: moved,
      cancelled: cancelled,
      tracked: tracked,
      logged: logged,
      in_persian: in_persian,
      food: food,
      bundled: bundled,
      recipe: edited,
      plan: plan,
      slot: slot,
      log: log,
      item: item
    }
  end

  defp create!(resource, action, attrs) do
    resource |> Ash.Changeset.for_create(action, attrs) |> Ash.create!()
  end

  defp rows, do: Backup.export().rows

  defp counts do
    Map.new(Catalog.entries(), fn entry -> {entry.table, Ash.count!(entry.resource)} end)
  end

  defp path(name) do
    dir = Path.join(System.tmp_dir!(), "kati_backup_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    Path.join(dir, name)
  end

  # Rebuild the manifest's hashes over whatever the payloads now say, so a
  # deliberately edited payload reaches the checks *past* the checksum.
  defp reseal(files) do
    payloads = Map.delete(files, "manifest.json")

    manifest =
      files
      |> Map.fetch!("manifest.json")
      |> Jason.decode!()
      |> Map.put(
        "files",
        Map.new(payloads, fn {path, bytes} ->
          {path, %{"sha256" => Archive.sha256(bytes), "bytes" => byte_size(bytes)}}
        end)
      )

    Map.put(files, "manifest.json", Jason.encode!(manifest))
  end

  defp edit_payload(binary, table, fun, opts \\ []) do
    {:ok, files} = Archive.unpack(binary)
    path = "data/#{table}.json"
    edited = files |> Map.fetch!(path) |> Jason.decode!() |> fun.() |> Jason.encode!()
    files = Map.put(files, path, edited)
    files = if opts[:reseal] == false, do: files, else: reseal(files)
    Archive.pack(%Bundle{manifest: %{}, files: files})
  end

  defp edit_manifest(binary, fun) do
    {:ok, files} = Archive.unpack(binary)
    edited = files |> Map.fetch!("manifest.json") |> Jason.decode!() |> fun.() |> Jason.encode!()
    Archive.pack(%Bundle{manifest: %{}, files: Map.put(files, "manifest.json", edited)})
  end

  # ── The round trip ─────────────────────────────────────────────────────────

  describe "populate, export, wipe, restore" do
    test "every row comes back, column for column" do
      populate!()

      before_rows = rows()
      before_counts = counts()
      binary = Backup.to_binary(Backup.export())

      # The fixture actually wrote something to every table it claims to.
      assert before_counts["events"] == 2
      assert before_counts["event_occurrence_overrides"] == 2
      assert before_counts["media_watches"] == 2
      assert before_counts["recipe_ingredients"] == 2
      assert before_counts["meal_logs"] == 1
      assert Enum.count(before_counts, fn {_t, n} -> n > 0 end) == 13

      empty_the_tables!()
      assert Enum.all?(Map.values(counts()), &(&1 == 0))

      assert {:ok, report} = Backup.restore_binary(binary)
      assert report.mode == :into_empty
      assert report.total_inserted == Enum.sum(Map.values(before_counts))
      assert report.inserted == before_counts

      assert counts() == before_counts
      assert rows() == before_rows
    end

    test "an empty database round-trips, and restores as empty" do
      binary = Backup.to_binary(Backup.export())

      assert {:ok, summary} = Backup.inspect_binary(binary)
      assert summary.total_records == 0
      assert map_size(summary.record_counts) == 13

      assert {:ok, report} = Backup.restore_binary(binary)
      assert report.total_inserted == 0
      assert Enum.all?(Map.values(counts()), &(&1 == 0))
    end

    test "the timestamps come back unmoved, so nothing replayed the writes" do
      %{tracked: tracked, log: log} = populate!()

      binary = Backup.to_binary(Backup.export())
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_binary(binary)

      {:ok, restored} = Ash.get(TrackedTitle, tracked.id)

      # Kati.Media.Changes.Touch would have stamped this with the restore.
      assert restored.last_touched_at == tracked.last_touched_at
      assert restored.inserted_at == tracked.inserted_at
      assert restored.updated_at == tracked.updated_at

      {:ok, restored_log} = Ash.get(MealLog, log.id)
      assert restored_log.inserted_at == log.inserted_at
      assert restored_log.frozen_at == log.frozen_at
    end

    test "a meal log's frozen figures come back frozen, not recomputed" do
      %{log: log, recipe: edited} = populate!()

      frozen = Map.take(log, MealLog.snapshot_fields())

      # The recipe has moved on since the log was written. Without this the
      # assertion below would pass against a restore that recomputed.
      refute edited.total_kcal == log.kcal
      refute edited.total_protein_mg == log.protein_mg

      binary = Backup.to_binary(Backup.export())
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_binary(binary)

      {:ok, restored} = Ash.get(MealLog, log.id)

      assert Map.take(restored, MealLog.snapshot_fields()) == frozen
      assert restored.kcal == log.kcal
      assert restored.recipe_rev == log.recipe_rev
      # And the provenance link survived, so "the figures did not move" is not
      # true merely because the reference was cut.
      assert restored.recipe_id == edited.id
      assert restored.recipe_rev < edited.ingredients_rev
    end

    test "text with a comma, a quote, a newline and Persian digits survives" do
      %{logged: logged, in_persian: in_persian, log: log} = populate!()

      binary = Backup.to_binary(Backup.export())
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_binary(binary)

      {:ok, restored} = Ash.get(Watch, logged.id)
      assert restored.review == @awkward_review
      assert restored.review =~ "\n"
      assert restored.companions == "Jo, Sam"

      {:ok, persian} = Ash.get(Watch, in_persian.id)
      assert persian.review == @persian_note

      {:ok, restored_log} = Ash.get(MealLog, log.id)
      assert restored_log.note == @persian_note
    end

    test "the retained iCalendar bytes come back byte for byte" do
      %{standup: standup} = populate!()

      binary = Backup.to_binary(Backup.export())
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_binary(binary)

      {:ok, restored} = Ash.get(Event, standup.id)

      # Against what was *stored*, not against the literal: Ash trims a string
      # attribute on write, so the row lost the trailing CRLF before the backup
      # ever saw it. What a backup owes is the bytes the database holds.
      assert restored.raw_icalendar == standup.raw_icalendar
      assert restored.raw_icalendar =~ "X-APPLE-STRUCTURED-LOCATION"
      assert restored.unknown_props =~ "X-MOZ-LASTACK"
      assert restored.rrule == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
    end

    test "an all-day event stays date-valued and a cancelled instance stays cancelled" do
      %{birthday: birthday, cancelled: cancelled, moved: moved} = populate!()

      binary = Backup.to_binary(Backup.export())
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_binary(binary)

      {:ok, restored} = Ash.get(Event, birthday.id)
      assert restored.is_all_day
      assert restored.dtstart_date == ~D[2026-09-04]

      {:ok, gone} = Ash.get(Override, cancelled.id)
      assert gone.kind == :cancelled
      assert gone.recurrence_id_utc == ~U[2026-08-20 07:00:00.000000Z]

      {:ok, late} = Ash.get(Override, moved.id)
      assert late.kind == :modified
      assert late.summary == "Standup (late)"
    end
  end

  # ── What is deliberately not in the file ───────────────────────────────────

  describe "what the backup leaves out" do
    test "the evictable cache is absent, and a restore does not touch it" do
      populate!()
      before_cached = Ash.count!(CachedTitle)
      assert before_cached == 1

      binary = Backup.to_binary(Backup.export())
      {:ok, files} = Archive.unpack(binary)

      refute Map.has_key?(files, "data/cached_titles.json")
      refute Map.has_key?(files, "data/bundled_foods.json")
      refute Map.has_key?(files, "data/licensed_foods.json")
      refute files |> Map.fetch!("manifest.json") |> String.contains?("cached_titles")

      assert {:ok, _} =
               Backup.restore_binary(binary,
                 mode: :replace,
                 safety_sink: fn _bundle -> {:ok, :discarded} end
               )

      # The cache is not the backup's to delete, and not the backup's to fill.
      assert Ash.count!(CachedTitle) == before_cached
    end

    test "the keystore handle is nowhere in the produced bytes" do
      %{account: account} = populate!()
      assert account.credentials_ref == @credentials_ref

      {:ok, files} = binary_files()

      for {path, bytes} <- files do
        refute String.contains?(bytes, @credentials_ref), "#{path} carries the keystore handle"
      end

      # And the column is still a column, written as null, so a restore cannot
      # mistake "dropped" for "unknown".
      accounts = Map.fetch!(rows(), "calendar_accounts")
      assert [%{credentials_ref: nil}] = accounts
      assert Map.has_key?(hd(accounts), :credentials_ref)
    end

    test "every dropped reference is counted into the manifest, not silently nulled" do
      populate!()

      manifest = Backup.export().manifest

      assert manifest["dropped_columns"] == %{
               "calendar_accounts.credentials_ref" => 1,
               "recipe_ingredients.bundled_food_id" => 1
             }
    end

    test "an ingredient whose food row is not in the backup keeps everything it authored" do
      %{bundled: bundled} = populate!()

      before_line =
        RecipeIngredient |> Ash.read!() |> Enum.find(&(&1.bundled_food_id == bundled.id))

      assert before_line

      binary = Backup.to_binary(Backup.export())
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_binary(binary)

      {:ok, restored} = Ash.get(RecipeIngredient, before_line.id)

      # The pointer is gone, because the row it pointed at is a shipped corpus
      # the backup does not carry. Nothing the user or the recipe authored is.
      assert is_nil(restored.bundled_food_id)
      assert restored.name == before_line.name
      assert restored.amount_mg == before_line.amount_mg
      assert restored.unit == before_line.unit
      assert restored.aisle == before_line.aisle
      assert restored.kcal == before_line.kcal
      assert restored.protein_mg == before_line.protein_mg
      assert restored.recipe_id == before_line.recipe_id
    end
  end

  # ── Everything is checked before anything is written ───────────────────────

  describe "verification before the first write" do
    test "one flipped byte in a payload is refused, with the database untouched" do
      populate!()
      before_counts = counts()
      binary = Backup.to_binary(Backup.export())

      {:ok, files} = Archive.unpack(binary)
      path = "data/media_watches.json"
      <<head::binary-size(40), byte, tail::binary>> = Map.fetch!(files, path)
      flipped = <<head::binary, rem(byte + 1, 256), tail::binary>>

      corrupt =
        Archive.pack(%Bundle{manifest: %{}, files: Map.put(files, path, flipped)})

      assert {:error, error} = Backup.restore_binary(corrupt)
      assert error.reason == :checksum_mismatch
      assert error.message =~ "damaged"
      assert error.message =~ "Nothing has been changed"
      assert counts() == before_counts
    end

    test "a backup from a newer Kati is refused whole, not read field by field" do
      populate!()
      empty_the_tables!()
      binary = Backup.to_binary(Backup.export())

      newer = edit_manifest(binary, &Map.put(&1, "schema_version", 99))

      assert {:error, error} = Backup.restore_binary(newer)
      assert error.reason == :unsupported_schema_version
      assert error.message =~ "newer version of Kati"
      assert Enum.all?(Map.values(counts()), &(&1 == 0))
    end

    test "a count the manifest cannot back up is refused" do
      populate!()
      binary = Backup.to_binary(Backup.export())

      lying =
        edit_payload(binary, "media_watches", fn payload ->
          Map.put(payload, "rows", tl(payload["rows"]))
        end)

      assert {:error, error} = Backup.restore_binary(lying)
      assert error.reason == :count_mismatch
      assert error.message =~ "media_watches"
    end

    test "a column this app does not know is refused, never dropped in silence" do
      populate!()
      binary = Backup.to_binary(Backup.export())

      extra =
        edit_payload(binary, "foods", fn payload ->
          Map.update!(payload, "rows", fn rows ->
            Enum.map(rows, &Map.put(&1, "vitamin_c_mg", 12))
          end)
        end)

      assert {:error, error} = Backup.restore_binary(extra)
      assert error.reason == :column_mismatch
      assert error.message =~ "vitamin_c_mg"

      missing =
        edit_payload(binary, "foods", fn payload ->
          Map.update!(payload, "rows", fn rows ->
            Enum.map(rows, &Map.delete(&1, "cuisine"))
          end)
        end)

      assert {:error, %{reason: :column_mismatch, message: message}} =
               Backup.restore_binary(missing)

      assert message =~ "cuisine"
    end

    test "a value of the wrong shape is refused with the column named" do
      populate!()
      binary = Backup.to_binary(Backup.export())

      broken =
        edit_payload(binary, "events", fn payload ->
          Map.update!(payload, "rows", fn [row | rest] ->
            [Map.put(row, "dtstart_date", "۱۴۰۵-۰۵-۲۵") | rest]
          end)
        end)

      assert {:error, error} = Backup.restore_binary(broken)
      assert error.reason == :bad_value
      assert error.message =~ "dtstart_date"
      assert error.message =~ "events"
    end

    test "a file with a member its manifest does not list is refused" do
      populate!()
      binary = Backup.to_binary(Backup.export())
      {:ok, files} = Archive.unpack(binary)

      smuggled =
        Archive.pack(%Bundle{
          manifest: %{},
          files: Map.put(files, "data/horoscopes.json", "{}")
        })

      assert {:error, error} = Backup.restore_binary(smuggled)
      assert error.reason == :unexpected_file
      assert error.message =~ "horoscopes"
    end

    test "two rows with the same id are refused before either is written" do
      populate!()
      before_counts = counts()
      binary = Backup.to_binary(Backup.export())

      doubled =
        edit_payload(binary, "media_watches", fn payload ->
          rows = payload["rows"]

          payload
          |> Map.put("rows", rows ++ [hd(rows)])
          |> Map.put("count", length(rows) + 1)
        end)

      doubled = edit_manifest(doubled, &put_in(&1, ["record_counts", "media_watches"], 3))

      assert {:error, error} = Backup.restore_binary(doubled)
      assert error.reason == :duplicate_id
      assert counts() == before_counts
    end
  end

  # ── Nothing partial, on a data layer that cannot transact ──────────────────

  describe "a failure part way through" do
    test "leaves nothing behind, including the wipe a :replace had already done" do
      populate!()
      before_rows = rows()
      before_counts = counts()

      # A rating of 99 passes every structural check — it is an integer in an
      # integer column — and is refused by the resource at write time, on the
      # sixth of thirteen tables. Five tables have already been written by then,
      # and a `:replace` has already emptied all thirteen.
      poisoned =
        Backup.export()
        |> Backup.to_binary()
        |> edit_payload("media_watches", fn payload ->
          Map.update!(payload, "rows", fn [row | rest] -> [Map.put(row, "rating", 99) | rest] end)
        end)

      assert {:error, error} =
               Backup.restore_binary(poisoned,
                 mode: :replace,
                 safety_sink: fn _bundle -> {:ok, :held} end
               )

      assert error.reason == :write_failed
      assert error.message =~ "Nothing has been changed"

      # The wipe rolled back with the inserts.
      assert counts() == before_counts
      assert rows() == before_rows
    end

    test "a failure into an empty database leaves it empty" do
      poisoned =
        populate_and_export()
        |> edit_payload("media_watches", fn payload ->
          Map.update!(payload, "rows", fn [row | rest] -> [Map.put(row, "rating", 99) | rest] end)
        end)

      empty_the_tables!()

      assert {:error, %{reason: :write_failed}} = Backup.restore_binary(poisoned)
      assert Enum.all?(Map.values(counts()), &(&1 == 0))
    end
  end

  # ── What happens to rows that are already there ────────────────────────────

  describe "existing rows" do
    test "the default mode refuses, and says what it found" do
      populate!()
      before_rows = rows()
      binary = Backup.to_binary(Backup.export())

      assert {:error, error} = Backup.restore_binary(binary)
      assert error.reason == :not_empty
      assert error.message =~ "already has data"
      assert error.message =~ "events"
      assert error.message =~ "Nothing has been changed"
      assert rows() == before_rows
    end

    test "merge inserts what is missing and never overwrites what is here" do
      backup = populate_and_export()
      backup_rows = rows()
      backup_counts = counts()

      empty_the_tables!()

      # A different device, with its own data on it.
      other =
        create!(TrackedTitle, :create, %{
          source: :tmdb,
          source_id: "1726",
          kind: :movie,
          status: :watching,
          rating: 6
        })

      assert {:ok, report} = Backup.restore_binary(backup, mode: :merge)

      assert report.mode == :merge
      assert report.total_skipped == 0
      assert report.inserted == backup_counts
      assert counts()["tracked_titles"] == backup_counts["tracked_titles"] + 1

      # The row that was already here is untouched.
      {:ok, kept} = Ash.get(TrackedTitle, other.id)
      assert kept.source_id == "1726"
      assert kept.rating == 6
      assert kept.last_touched_at == other.last_touched_at

      # And every row from the backup is here, exactly as it was exported.
      restored = rows()

      for {table, list} <- backup_rows, row <- list do
        assert row in Map.fetch!(restored, table), "#{table} lost a row in the merge"
      end
    end

    test "merging the same backup twice changes nothing the second time" do
      backup = populate_and_export()

      empty_the_tables!()
      assert {:ok, first} = Backup.restore_binary(backup, mode: :merge)
      after_first = rows()

      assert {:ok, second} = Backup.restore_binary(backup, mode: :merge)

      assert second.total_inserted == 0
      assert second.total_skipped == first.total_inserted
      assert rows() == after_first
    end

    test "merge refuses a natural-key collision rather than guessing which row wins" do
      backup = populate_and_export()
      empty_the_tables!()

      # The same film, tracked again on the new phone before the restore ran:
      # same {source, source_id}, different id. There is no answer to "which of
      # these two is the one you meant" that does not lose something.
      twin =
        create!(TrackedTitle, :create, %{
          source: :tmdb,
          source_id: "603",
          kind: :movie,
          rating: 3
        })

      assert {:error, error} = Backup.restore_binary(backup, mode: :merge)
      assert error.reason == :write_failed
      assert error.message =~ "Nothing has been changed"

      # The row that was here is exactly as it was, and nothing else landed.
      {:ok, kept} = Ash.get(TrackedTitle, twin.id)
      assert kept.rating == 3
      assert counts()["tracked_titles"] == 1
      assert counts()["media_watches"] == 0
      assert counts()["events"] == 0
    end

    test "replace will not empty the tables without a copy of them first" do
      backup = populate_and_export()
      before_rows = rows()

      assert {:error, error} = Backup.restore_binary(backup, mode: :replace)
      assert error.reason == :safety_export_required
      assert error.message =~ "saving a copy"
      assert rows() == before_rows

      # And through the file-level API, which refuses for the same reason when
      # no path is given for the copy.
      file = path("backup.katibackup")
      File.write!(file, backup)

      assert {:error, %{reason: :safety_export_required}} =
               Backup.restore_file(file, mode: :replace)
    end

    test "replace swaps the data and leaves the old copy restorable" do
      backup = populate_and_export()
      backup_rows = rows()
      backup_counts = counts()

      empty_the_tables!()

      # What is on the device now: something else entirely.
      other =
        create!(TrackedTitle, :create, %{source: :tmdb, source_id: "1726", kind: :movie})

      other_rows = rows()

      file = path("backup.katibackup")
      File.write!(file, backup)
      safety = path("before-restore.katibackup")

      assert {:ok, report} =
               Backup.restore_file(file, mode: :replace, safety_export_path: safety)

      assert report.mode == :replace
      assert report.safety_export == safety
      assert report.deleted["tracked_titles"] == 1
      assert counts() == backup_counts
      assert rows() == backup_rows
      assert {:error, _} = Ash.get(TrackedTitle, other.id)

      # The copy taken before the wipe is a real backup: it restores.
      empty_the_tables!()
      assert {:ok, _} = Backup.restore_file(safety)
      assert rows() == other_rows
    end
  end

  # ── The file itself ────────────────────────────────────────────────────────

  describe "the file" do
    test "no date or number field carries a Persian digit, whatever the notes say" do
      populate!()
      {:ok, files} = binary_files()

      numeric = [
        Ash.Type.Date,
        Ash.Type.Time,
        Ash.Type.UtcDatetimeUsec,
        Ash.Type.UtcDatetime,
        Ash.Type.Integer,
        Ash.Type.Float,
        Ash.Type.Decimal
      ]

      checked =
        for entry <- Catalog.entries(),
            attribute <- Catalog.attributes(entry),
            attribute.type in numeric,
            row <- Jason.decode!(Map.fetch!(files, "data/#{entry.table}.json"))["rows"],
            value = row[Atom.to_string(attribute.name)],
            not is_nil(value) do
          refute to_string(value) =~ ~r/[\x{06F0}-\x{06F9}\x{0660}-\x{0669}]/u,
                 "#{entry.table}.#{attribute.name} carries an eastern-Arabic digit"

          assert to_string(value) =~ ~r/\A[0-9.:TZ+\-]+\z/u,
                 "#{entry.table}.#{attribute.name} is not a plain ISO-8601 value"

          1
        end

      # The loop above is worthless if it walked nothing.
      assert length(checked) > 30

      # And the Persian text really is in the file, in the field it belongs in.
      assert files |> Map.fetch!("data/media_watches.json") |> String.contains?("۱۲")
    end

    test "two exports of the same data are the same bytes" do
      populate!()

      {:ok, first} = binary_files()
      {:ok, second} = binary_files()

      assert Map.delete(first, "manifest.json") == Map.delete(second, "manifest.json")

      # Only `exported_at` may differ between the two manifests.
      a = first |> Map.fetch!("manifest.json") |> Jason.decode!()
      b = second |> Map.fetch!("manifest.json") |> Jason.decode!()
      assert Map.delete(a, "exported_at") == Map.delete(b, "exported_at")
    end

    test "the manifest carries everything a confirmation screen needs" do
      populate!()
      manifest = Backup.export().manifest

      assert manifest["format"] == "kati.backup"
      assert manifest["schema_version"] == Catalog.schema_version()
      assert manifest["record_counts"]["events"] == 2
      assert manifest["record_counts"]["media_watches"] == 2
      assert map_size(manifest["files"]) == 13

      for {path, %{"sha256" => hash, "bytes" => bytes}} <- manifest["files"] do
        assert String.starts_with?(path, "data/")
        assert String.length(hash) == 64
        assert bytes > 0
      end
    end

    test "every payload is the shape the published schema says it is" do
      populate!()
      {:ok, files} = binary_files()
      schema = "docs/backup/payload.schema.json" |> File.read!() |> Jason.decode!()

      for entry <- Catalog.entries() do
        payload = files |> Map.fetch!("data/#{entry.table}.json") |> Jason.decode!()

        assert Enum.sort(Map.keys(payload)) == Enum.sort(schema["required"])
        assert payload["table"] == entry.table
        assert payload["count"] == length(payload["rows"])
        assert payload["columns"] == Enum.map(Catalog.columns(entry), &Atom.to_string/1)

        for row <- payload["rows"] do
          assert Enum.sort(Map.keys(row)) == payload["columns"]
        end
      end
    end

    test "inspecting a file reports the counts without touching the database" do
      populate!()
      file = path("backup.katibackup")
      assert {:ok, written} = Backup.export_to_file(file)
      assert written.total_records == Enum.sum(Map.values(counts()))
      assert written.bytes > 0
      assert File.exists?(file)

      before_rows = rows()
      empty_the_tables!()

      assert {:ok, summary} = Backup.inspect_file(file)
      assert summary.schema_version == Catalog.schema_version()
      assert summary.record_counts["events"] == 2
      assert summary.total_records == Enum.sum(Map.values(counts_of(before_rows)))
      assert %DateTime{} = summary.exported_at
      assert summary.dropped_columns["calendar_accounts.credentials_ref"] == 1

      # Inspecting wrote nothing.
      assert Enum.all?(Map.values(counts()), &(&1 == 0))
    end

    test "a file that is not a backup at all is a sentence, not a crash" do
      file = path("holiday.jpg")
      File.write!(file, "not a zip, not a backup, a photo of a dog")

      assert {:error, error} = Backup.inspect_file(file)
      assert error.reason == :unreadable_archive

      assert {:error, %{reason: :not_a_backup}} = Backup.inspect_file(path("nothing-here"))
    end

    test "progress is reported once per table, not once per row" do
      populate!()
      binary = Backup.to_binary(Backup.export())
      empty_the_tables!()

      {:ok, collector} = Agent.start_link(fn -> [] end)
      on_exit(fn -> if Process.alive?(collector), do: Agent.stop(collector) end)

      assert {:ok, _} =
               Backup.restore_binary(binary,
                 on_progress: fn step -> Agent.update(collector, &[step | &1]) end
               )

      steps = collector |> Agent.get(& &1) |> Enum.reverse()

      # 13 rows went in across 13 tables; a per-record callback would have fired
      # far more than 13 times.
      assert length(steps) == 13
      assert Enum.map(steps, &elem(&1, 0)) == Catalog.tables()
      assert List.last(steps) == {"shopping_list_items", 13, 13}
    end

    test "an unchecked bundle is not written, whatever is in it" do
      populate!()
      before_counts = counts()

      unchecked = %Bundle{manifest: %{}, files: %{}, rows: nil}

      assert {:error, error} = Backup.restore(unchecked)
      assert error.reason == :bad_manifest
      assert error.message =~ "not been checked"
      assert counts() == before_counts
    end

    test "a mode nobody defined is refused before anything reads the rows" do
      binary = Backup.to_binary(Backup.export())

      assert {:error, error} = Backup.restore_binary(binary, mode: :overwrite_probably)
      assert error.reason == :bad_manifest
      assert error.message =~ "overwrite_probably"
    end

    test "the suggested filename is dated and carries the extension" do
      assert Backup.suggested_filename(~D[2026-08-21]) == "kati-backup-2026-08-21.katibackup"
      assert Backup.extension() == ".katibackup"
    end
  end

  # ── Helpers that need the fixture ──────────────────────────────────────────

  defp populate_and_export do
    populate!()
    Backup.to_binary(Backup.export())
  end

  defp binary_files do
    Backup.export() |> Backup.to_binary() |> Archive.unpack()
  end

  defp counts_of(rows), do: Map.new(rows, fn {table, list} -> {table, length(list)} end)
end
