Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenEmptyDatabaseTest do
  @moduledoc """
  The screens that moved onto Ash still draw their drawing on a fresh install.

  ## The blind spot this closes

  `Kati.ScreenDesignLiteralTest` already asks whether every literal a drawing
  contains is somewhere in the screen's rendered tree. It cannot ask *this*
  question, because it has no say in what is stored when it runs: this suite has
  no Ecto sandbox — `test/test_helper.exs` migrates one SQLite file and every
  test shares it — and several tests insert rows that outlive them.
  `Kati.Seeds` in particular writes **the design's own values** as real rows.

  So for a migrated screen that sweep passes either way: the literals are there
  whether the screen fell back to its Sample module or read the seeded rows back
  out of Ash, and which of the two happened moves with `--seed`. A screen that
  lost its fallback would keep passing it, and the first thing to show the
  defect would be a blank frame in the next capture — every drawing was captured
  from the Sample values, so a device with nothing tracked must still draw them.

  This file pins the other half by rendering the migrated screens against a
  database that is empty **for certain**.

  ## How the database is made empty

  Inside one transaction that is always rolled back: every table is emptied,
  the screens are rendered, and then nothing is kept. `pool_size` is 1 (see
  `Kati.Repo.init/2`) and this module is `async: false`, so the test process
  holds the only connection for the duration — the renders read through it and
  see the empty state, and the rows every other test depends on are still there
  afterwards.

  Emptiness is asserted twice over, at both levels the screens actually use:
  `count(*)` per table through Ecto, and an `Ash.read!` per resource, because
  the screens read through Ash and it is Ash's answer that has to be empty.
  """
  # `async: false` is a requirement rather than caution, three times over: the
  # renders switch `Kati.Locale`, which is global; the transaction below holds
  # the pool's only connection; and emptying every table is not something to do
  # beside a test that is inserting.
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.ScreenSweep

  # The nine screens the migration moved onto Ash, by the design number their
  # drawing is filed under. `Kati.Screens.Series` (04) and `Kati.Screens.Inbox`
  # (05) are deliberately absent: both still read `Kati.Library.Sample` outright
  # and say why at length in their moduledocs — `Kati.Media` has no episode
  # resource — so neither has a fallback that could regress.
  @migrated [
    {"03", Kati.Screens.Library},
    {"07", Kati.Screens.Stats},
    {"10", Kati.Screens.UpNext},
    {"15", Kati.Screens.Activity},
    {"43", Kati.Screens.MealsToday},
    {"44", Kati.Screens.MealPlan},
    {"45", Kati.Screens.Meal},
    {"47", Kati.Screens.Nutrition},
    {"48", Kati.Screens.Shopping}
  ]

  # Every table an Ash resource in this app is backed by, child tables first so
  # the deletes below do not trip a foreign key. Written out rather than derived
  # so that `every_table_is_listed/0` can compare it against the schema the
  # migrations actually built — a resource added without a line here would
  # otherwise leave rows in place and this file would quietly stop being about
  # an empty database.
  @tables ~w(
    event_occurrence_overrides events calendars calendar_accounts
    recipe_ingredients recipes meal_plan_slots meal_plans meal_logs
    shopping_list_items foods bundled_foods licensed_foods
    media_watches tracked_titles cached_titles
    sync_outbox sync_rejected_changes spike_things
  )

  # Tables that are not an Ash resource and are none of this file's business:
  # Ecto's own ledger, and the DETS-replacing store Mob keeps screen state in.
  @not_resources ~w(schema_migrations mob_screen_states)

  # The resources the migrated screens actually read, asked through Ash rather
  # than through Ecto. `count(*)` returning zero and `Ash.read!` returning `[]`
  # are different claims — a filter, a base_filter or a multitenancy setting
  # could make them disagree — and it is this one the screens depend on.
  @resources [
    Kati.Media.TrackedTitle,
    Kati.Media.CachedTitle,
    Kati.Media.Watch,
    Kati.Meals.MealPlan,
    Kati.Meals.MealPlanSlot,
    Kati.Meals.MealLog,
    Kati.Meals.Recipe,
    Kati.Meals.RecipeIngredient,
    Kati.Meals.ShoppingListItem,
    Kati.Meals.Food
  ]

  describe "the emptiness this file rests on" do
    test "every table in the schema is either listed or named as not a resource" do
      %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'")
      present = rows |> List.flatten() |> Enum.reject(&String.starts_with?(&1, "sqlite_"))

      missing = Enum.reject(@tables, &(&1 in present))

      assert missing == [],
             "these tables are emptied below and do not exist, so emptying them proves " <>
               "nothing: #{inspect(missing)}"

      unwatched = Enum.reject(present, &(&1 in @tables or &1 in @not_resources))

      assert unwatched == [],
             "these tables exist and are neither emptied nor declared irrelevant, so rows in " <>
               "them would survive into the renders and this file would be claiming an empty " <>
               "database it never made: #{inspect(unwatched)}"
    end

    test "inside the transaction both Ecto and Ash agree there is nothing stored" do
      {counts, reads} =
        in_empty_database(fn ->
          counts =
            for table <- @tables,
                %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}"),
                n > 0,
                do: "  #{table}: #{n}"

          reads =
            for resource <- @resources,
                rows = Ash.read!(resource),
                rows != [],
                do: "  #{inspect(resource)}: #{length(rows)}"

          {counts, reads}
        end)

      assert counts == [], "tables still hold rows inside the transaction:\n" <> Enum.join(counts, "\n")

      assert reads == [],
             "Ash still returns rows inside the transaction, which is the level the screens " <>
               "read at:\n" <> Enum.join(reads, "\n")
    end

    test "the transaction is rolled back, so the rest of the suite keeps its rows" do
      before = table_counts()
      _ = in_empty_database(fn -> :ok end)

      assert table_counts() == before,
             "emptying the tables for this file's renders was not undone. Every other test " <>
               "shares this database and this module would be deleting their fixtures"
    end
  end

  describe "with nothing stored" do
    test "every migrated screen still draws every literal its drawing contains" do
      missing =
        for screen <- render_migrated(),
            literal <- screen.design.text,
            DesignLiterals.locate(literal, screen.haystacks) == :missing,
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{inspect(literal)}"

      assert missing == [],
             "these screens moved onto Ash and no longer draw their own drawing when nothing " <>
               "is stored. A fresh install renders this as a gap, and the next frame capture " <>
               "is where it would have surfaced:\n" <> Enum.join(missing, "\n")
    end

    test "every migrated screen still draws every Material Symbol its drawing draws" do
      missing =
        for screen <- render_migrated(),
            glyphs = DesignLiterals.rendered_glyphs(screen.tree),
            name <- screen.design.icons,
            glyph = Kati.Icons.glyph(name),
            glyph != nil,
            not MapSet.member?(glyphs, glyph),
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{name}"

      assert missing == [],
             "an icon the drawing shows is absent on an empty database, which usually means " <>
               "the row that used to carry it is:\n" <> Enum.join(missing, "\n")
    end

    test "each one draws a whole screen, not chrome over an empty section" do
      # The literal check above is satisfied by presence anywhere in the tree, so
      # a screen whose lists emptied while its chrome survived could still pass it
      # if the drawing's copy happened to sit in the chrome. Counting what was
      # actually rendered catches the shape of that before it needs a frame.
      thin =
        for screen <- render_migrated(),
            length(screen.texts) < length(screen.design.text),
            do:
              "  #{screen.number} #{inspect(screen.module)} rendered #{length(screen.texts)} " <>
                "strings against a drawing holding #{length(screen.design.text)}"

      assert thin == [],
             "these screens render less copy than their drawing holds, which is what a lost " <>
               "fallback looks like:\n" <> Enum.join(thin, "\n")
    end
  end

  # ── An empty database, borrowed and given back ──────────────────────────────

  # Runs `fun` with every table emptied, and always rolls back. `Ash.read!` and
  # `Kati.Repo.query!` inside `fun` run in this same process, so they use the
  # connection the transaction checked out and see the empty state; nothing is
  # written, so the suite's other fixtures survive.
  defp in_empty_database(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Enum.each(@tables, &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  defp table_counts do
    Map.new(@tables, fn table ->
      %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}")
      {table, n}
    end)
  end

  # ── Rendering ───────────────────────────────────────────────────────────────

  # Memoised in `:persistent_term` for the reason `Kati.ScreenDesignLiteralTest`
  # states: each ExUnit test runs in its own process and `Mob.ScreenCase`
  # restarts `Mob.State` around each one, so a cache in the process dictionary
  # or in ETS dies between the tests that share the work. Only plain data —
  # trees and strings — is stored.
  defp render_migrated do
    key = {__MODULE__, :render_migrated}

    case :persistent_term.get(key, :miss) do
      :miss ->
        screens = in_empty_database(&do_render_migrated/0)
        :persistent_term.put(key, screens)
        screens

      screens ->
        screens
    end
  end

  defp do_render_migrated do
    for {number, module} <- @migrated do
      case ScreenSweep.with_locale(:en, fn -> ScreenSweep.render(module) end) do
        {:ok, _socket, tree} ->
          texts = DesignLiterals.rendered(tree)

          %{
            number: number,
            module: module,
            tree: tree,
            texts: texts,
            haystacks: DesignLiterals.haystacks(texts),
            design: DesignLiterals.read!(number)
          }

        {:error, message} ->
          flunk("screen #{number} (#{inspect(module)}) does not render:\n  #{message}")
      end
    end
  end
end
