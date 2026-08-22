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

  This file pins the other half by rendering those screens against a database
  that is empty **for certain**.

  ## Which screens, and who decides

  Every screen that can reach the store, derived rather than listed by hand —
  see `@migrated`. The screen a migration lands on and nobody remembers to add
  here is precisely the screen whose fallback has never been exercised, so the
  list is checked against each screen's own compiled import table in both
  directions.

  ## What "still draws its drawing" is asked twice

  Once of the tree — every literal and every Material Symbol the drawing holds
  is somewhere in what was rendered — and once of the screen's own entry point,
  which must answer with the drawn value to the term. The first can be
  satisfied by copy that happens to live in the chrome; the second cannot, and
  it is what makes "the fallback exists" a claim a run settles rather than one
  a moduledoc asserts.

  Which means the second question is only asked of the screens `fallbacks/0`
  lists, and a `for` over a list says nothing about a screen the list omits.
  `@migrated` cannot go stale — it is pinned against the compiled call graph in
  both directions — so the way this file loses a guard is a screen that joins
  `@migrated` on the round it migrates and is not given an entry-point gate:
  rendered, passing every literal check, and its fallback taken on trust.
  `fallbacks/0` is therefore pinned against `@migrated` in both directions too,
  and by number, so a gate cannot drift onto the wrong screen either.

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

  Both of those are claims about zero, and every claim about zero is satisfied
  by a database that was empty to begin with — a `DELETE` that never ran
  against a table nobody listed would pass all of them. So one test writes rows
  first and asks the same questions of rows it knows exist: seen outside the
  transaction, gone at both levels inside it, and there again after the
  rollback.
  """
  # `async: false` is a requirement rather than caution, three times over: the
  # renders switch `Kati.Locale`, which is global; the transaction below holds
  # the pool's only connection; and emptying every table is not something to do
  # beside a test that is inserting.
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.ScreenSweep

  # Every screen that reads the database, by the design number its drawing is
  # filed under. **Not a hand-kept list of what moved**: "the screens the
  # migration moved" is a fact about one round of work and rots the round after,
  # and the question this file asks is the timeless one — *can this screen still
  # draw itself when the store is empty*. So the list is pinned from both sides
  # by "every screen that can reach the database is in the list" below, which
  # reads each screen's own compiled import table: a screen that starts reading
  # Ash and is not added here fails, and an entry here for a screen that reads
  # nothing fails too.
  #
  # `Kati.Screens.SeriesMeta` (14) and `Kati.Screens.SeriesSettings` (35) are
  # absent because they read no store at all: each still reads its Sample module
  # outright and says why at length in its moduledoc — no cast, no availability,
  # no offers, and in 35's case a referent it argues cannot be picked safely —
  # so neither has a fallback that could regress.
  #
  # **04 and 58 have moved, and this comment used to explain why they had not.**
  # The reason given was that `Kati.Media` cannot enumerate a season or name an
  # episode, which stopped being true when
  # `20260821231241_media_seasons_and_episodes` created `cached_seasons` and
  # `cached_episodes`: `Kati.Media.CachedEpisode` carries `title`,
  # `runtime_minutes`, `air_at` and `episode_number` with `for_season/3` and
  # `for_title/2` to read them, and `Kati.Media.CachedSeason.for_title/2` and
  # `count/1` are the season strip and its `3 SEASONS`. Both screens' moduledocs
  # still asserted the old blocker after it was gone, and one of them cost a
  # round; both now say what they read instead. 58 reaches the store the way a
  # mirror should — through `Kati.Screens.Series.tracked_series/0`, not a second
  # copy of the query — so it is in this list transitively and by design.
  #
  # **05 and 34 moved on the same round, and 34 moved only PARTLY.** Screen 05
  # draws both of its lists out of `Kati.Media.CachedEpisode`,
  # `Kati.Media.CachedSeason` and `Kati.Media.Release`, and keeps its watcher
  # card frozen because two of that card's three values have no store anywhere.
  # Screen 34 draws its episode list, its heading and its count, and keeps the
  # order strip, the two switches and the `PARTS 1–2` badge drawn — those are
  # columns that do not exist rather than queries nobody wrote, and
  # `Kati.Media.CachedEpisode.orders/0` answering `[:aired, :absolute]` is the
  # DVD tile's own reason.
  #
  # A partly-migrated screen is exactly the shape this file has to be careful
  # about: its gate must answer with the drawn value *whole* on an empty
  # database, frozen parts and all, which is what `fallbacks/0` compares. Both
  # therefore lay their real values over `drawn_*/0` rather than building a
  # fresh map, so the two branches cannot differ in a key neither side names.
  @migrated [
    # 01 and 02 are the two that were reading the database before this round and
    # were never in this file. Both take `Kati.Calendars.Today`, which answers
    # `[]` on a device with nothing mirrored, and both substitute the drawing at
    # that point — Home in `rest_of_today/1`'s `[]` clause, Schedule in
    # `day_rows/1` for today only. Neither had anything asserting that, which is
    # exactly the gap this file exists for: the screens most likely to be
    # captured are the two the check was not covering.
    {"01", Kati.Screens.Home},
    {"02", Kati.Screens.Calendar},
    {"03", Kati.Screens.Library},
    {"04", Kati.Screens.Series},
    {"05", Kati.Screens.Inbox},
    {"07", Kati.Screens.Stats},
    {"08", Kati.Screens.Film},
    {"10", Kati.Screens.UpNext},
    {"15", Kati.Screens.Activity},
    # 32 moved its "which calendars show" group onto `Kati.Calendars.Calendar`
    # and 42 its hero and meal row onto `Kati.Meals`. Both keep the rest of
    # their copy on a Sample module and say which parts and why in their own
    # moduledocs — `Kati.Screens.Habits` (22) and `Kati.Screens.Subscriptions`
    # (23) are absent here for the same reason 04 and 05 are: no habit
    # completion, no price, nothing to fall back FROM.
    {"32", Kati.Screens.Calendars},
    # 34 is the one screen in this list that is only PARTLY migrated — see the
    # note above. It is here for the ordinary reason: it reaches the store, so
    # its fallback is a thing that can regress.
    {"34", Kati.Screens.Season},
    # The two screens the design draws DARK, and the log sheet.
    #
    # 28 is Home in dark and reads exactly what Home reads — `Rest of today`,
    # through `Kati.Calendars.Today` — so its `[]` clause is Home's `[]` clause
    # and is guarded here the same way. Its header stays the drawing's evening
    # on purpose; `Kati.Screens.HomeDark`'s moduledoc gives both reasons.
    #
    # 29's four widgets fall back one at a time rather than as a page, which is
    # why the pair below compares the whole `widgets/0` map: a widget that
    # quietly stopped falling back would leave the other three drawing the
    # drawing and pass every literal check in this file.
    #
    # 33 reads the newest logged watch. It is the one screen here whose
    # fallback fires on a database that is NOT empty — a library full of
    # episode ticks and no rating or review anywhere still has nothing this
    # sheet can draw — so the empty case guarded here is the floor, not the
    # whole of it.
    {"28", Kati.Screens.HomeDark},
    {"29", Kati.Screens.Lock},
    {"33", Kati.Screens.Rating},
    {"42", Kati.Screens.Health},
    {"43", Kati.Screens.MealsToday},
    {"44", Kati.Screens.MealPlan},
    {"45", Kati.Screens.Meal},
    {"47", Kati.Screens.Nutrition},
    {"48", Kati.Screens.Shopping},
    # The Persian mirrors of 01, 02 and 03, reading the same two domains their
    # originals read. They are the first screens in 55-62 to reach a store at
    # all, and they are the ones with the most to lose from losing a fallback:
    # every drawing in that range was captured from its Sample module, and a
    # Persian page that renders empty cannot be compared with anything.
    {"55", Kati.Screens.HomeFa},
    {"56", Kati.Screens.ScheduleFa},
    {"57", Kati.Screens.LibraryFa},
    # 58 is 04 in Persian and reads through 04 — see the note above.
    {"58", Kati.Screens.SeriesFa}
  ]

  # Screens that read the database and have **no drawing at all**.
  #
  # Every entry in `@migrated` above is a pair of a screen and the frame under
  # `.scratch/design/screens/` it is compared against, and the whole of what
  # this file asks of one is *does it still draw its drawing when nothing is
  # stored*. These two have no frame: `.scratch/design/screens/` stops at 62,
  # none of the 62 is a backup or a sync page, and issue #25 asks for the
  # drawings and they do not exist. Filing them under `@migrated` would mean
  # inventing a number, and `DesignLiterals.read!/1` would then fail on a file
  # that is not there.
  #
  # So the literal comparison is skipped and **the render is not**: `every
  # undrawn store-reading screen still renders with nothing stored` below mounts
  # each one inside the same empty transaction and asserts it comes back a whole
  # renderable page. That is the check that actually matters for these two —
  # they are screens whose ordinary state IS empty, since a device with no
  # queued change and no conflict is the normal one, not the edge case.
  #
  # Pinned from both ends by `the undrawn list names only screens that read and
  # are genuinely undrawn`, so an entry cannot become a way to duck this file:
  # a module here that stops reading the store, or that acquires a drawing and
  # joins `Kati.Screens.Gallery`'s registry, fails.
  @undrawn [
    Kati.Screens.Backup,
    Kati.Screens.Sync
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
    media_watches tracked_titles cached_titles cached_seasons cached_episodes
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
    Kati.Calendars.Account,
    Kati.Calendars.Calendar,
    # 01 and 02 reach this one through `Kati.Calendars.Today`, and it is the
    # resource their whole timeline is. Asked here as well as counted above,
    # because `Kati.Calendars.Event` is the one resource in the app with a
    # `deleted_at` — a tombstone is a row Ecto counts and a read may filter out,
    # which is precisely the disagreement between the two levels this list
    # exists to catch.
    Kati.Calendars.Event,
    Kati.Calendars.Override,
    Kati.Media.TrackedTitle,
    Kati.Media.CachedTitle,
    Kati.Media.CachedSeason,
    Kati.Media.CachedEpisode,
    Kati.Media.Watch,
    Kati.Meals.MealPlan,
    Kati.Meals.MealPlanSlot,
    Kati.Meals.MealLog,
    Kati.Meals.Recipe,
    Kati.Meals.RecipeIngredient,
    Kati.Meals.ShoppingListItem,
    Kati.Meals.Food
  ]

  # One old cache table and both new ones. The two new ones are the point: their
  # `DELETE` has never run before this round, and a table left out of `@tables`
  # is invisible to every other test in this file.
  @probe_resources [
    Kati.Media.CachedTitle,
    Kati.Media.CachedSeason,
    Kati.Media.CachedEpisode
  ]

  # Marks the probe rows as this file's, so `delete_probe_rows!/0` can take back
  # exactly what it wrote and nothing a neighbouring test left behind.
  @probe_id "kati:empty-db-probe"

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

      assert counts == [],
             "tables still hold rows inside the transaction:\n" <> Enum.join(counts, "\n")

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

    test "rows written first are seen outside, unseen inside, and there again after" do
      # The three tests above are all satisfied by a database that was empty to
      # begin with. `count(*) == 0` proves nothing when nothing was ever
      # written, `Ash.read!` returning `[]` proves nothing either, and "the
      # counts did not change" is trivially true of a table of zero rows — so a
      # `DELETE` that silently did not run, or a transaction that did not scope
      # the renders, would pass every one of them.
      #
      # So this one writes first, and asks the same three questions of rows it
      # knows exist. Both new tables are among them, because they are the two
      # whose emptying has never run before this round.
      written = write_probe_rows!()
      on_exit(&delete_probe_rows!/0)

      outside =
        Map.new(@probe_resources, fn resource -> {resource, length(Ash.read!(resource))} end)

      for {resource, count} <- outside do
        assert count > 0,
               "#{inspect(resource)} holds nothing before the transaction opens, so emptying " <>
                 "it inside proves nothing. The probe row was not written"
      end

      inside =
        in_empty_database(fn ->
          Map.new(@probe_resources, fn resource ->
            table = AshSqlite.DataLayer.Info.table(resource)
            %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}")
            {resource, {n, length(Ash.read!(resource))}}
          end)
        end)

      for {resource, {counted, read}} <- inside do
        assert counted == 0,
               "#{inspect(resource)}'s table still counts #{counted} rows inside the " <>
                 "transaction, so the renders below are not running against an empty database"

        assert read == 0,
               "Ash still returns #{read} #{inspect(resource)} rows inside the transaction. " <>
                 "That is the level the screens read at, so a screen would still be drawing " <>
                 "them"
      end

      for {resource, ids} <- written do
        back = resource |> Ash.read!() |> Enum.map(& &1.id) |> MapSet.new()

        assert MapSet.subset?(ids, back),
               "#{inspect(resource)} rows written before the transaction are gone after it " <>
                 "rolled back. This module shares one database file with every other test " <>
                 "and would be deleting their fixtures"
      end
    end
  end

  describe "which screens this file has to cover" do
    test "every screen that can reach the database is in the list, and every one listed does" do
      # The list at the top of this file is the whole of what gets rendered
      # against an empty database, so a screen missing from it is a screen with
      # no guard at all — and the way that happens is not malice, it is a
      # migration landing in a round where nobody remembered this file. Both
      # halves are therefore derived rather than trusted.
      #
      # Derived from the **compiled import table**, not from the source: a
      # moduledoc quoting an `Ash` call is not a query
      # (`Kati.Screens.SeriesSettings`'s quotes `Ash.create!` and reads
      # nothing), and a read that has moved
      # into a helper — `Kati.Calendars.Today`, which is how 01 and 02 read —
      # is invisible to a grep of the screen's own file and plain in its imports.
      listed = MapSet.union(MapSet.new(@migrated, &elem(&1, 1)), MapSet.new(@undrawn))
      readers = MapSet.new(Enum.filter(ScreenSweep.screens(), &reaches_store?/1))

      unguarded = readers |> MapSet.difference(listed) |> Enum.sort()

      assert unguarded == [],
             "these screens read the database and are not rendered against an empty one. " <>
               "Add each to @migrated with the number its drawing is filed under — a screen " <>
               "that has just moved onto a domain is exactly the one whose fallback nobody " <>
               "has checked. A screen with no drawing at all goes in @undrawn instead, " <>
               "which skips the literal comparison and keeps the render:\n" <>
               Enum.map_join(unguarded, "\n", &"  #{inspect(&1)}")

      idle = listed |> MapSet.difference(readers) |> Enum.sort()

      assert idle == [],
             "these screens are listed as reading the database and reach no store at all, so " <>
               "rendering them against an empty one asserts nothing. Either the read was " <>
               "reverted — in which case `Kati.ScreenSampleOnlyTest` is where they belong — " <>
               "or the entry was aspirational:\n" <>
               Enum.map_join(idle, "\n", &"  #{inspect(&1)}")
    end

    test "the reachability test can tell a reader from a screen that only mentions one" do
      # A derived answer can be derived wrongly, and the way this one fails is
      # by answering `true` for everything (a namespace test that matches too
      # much) or `false` for everything (a chunk that did not load, an empty
      # module list). Both would make the test above vacuous, so three known
      # answers are pinned: one screen that queries directly, one that queries
      # only through a helper, and one whose moduledoc names an `Ash` call at
      # length and whose body reads nothing.
      #
      # That third one used to be `Kati.Screens.Season`, which now reads — so
      # the exemplar moved to `Kati.Screens.SeriesSettings`, whose moduledoc
      # quotes `Ash.create!` while arguing that its referent cannot be picked
      # safely yet. Keeping a mention-only screen pinned here is the point: a
      # namespace test that matched too much would answer `true` for it.
      assert reaches_store?(Kati.Screens.Film)
      assert reaches_store?(Kati.Screens.Home)
      refute reaches_store?(Kati.Screens.SeriesSettings)
      refute reaches_store?(Kati.Screens.Gallery)
    end

    test "the undrawn list names only screens that read and are genuinely undrawn" do
      # `@undrawn` is the one thing in this file that can make it check less, so
      # it is pinned from both ends like every other allow-list here.
      #
      # A module that stops reading the store does not belong in this file at
      # all, and a module that gains a drawing belongs in `@migrated` with its
      # number — where the literal comparison it was exempted from starts
      # applying again. `Kati.Screens.Gallery.screens/0` is the app's own
      # number → module registry and therefore the only honest answer to "does
      # a drawing exist for this screen", which is why it is asked rather than
      # a second list kept here.
      drawn = MapSet.new(Kati.Screens.Gallery.screens(), &elem(&1, 2))

      for module <- @undrawn do
        assert ScreenSweep.screen?(module),
               "#{inspect(module)} is in @undrawn and is not a screen at all"

        assert reaches_store?(module),
               "#{inspect(module)} is exempted from the literal comparison and reads no " <>
                 "store, so it has nothing to be exempted from. Remove it"

        refute MapSet.member?(drawn, module),
               "#{inspect(module)} is registered in Kati.Screens.Gallery, so a drawing " <>
                 "exists for it. Move it to @migrated with its number and let the literal " <>
                 "comparison run"
      end

      assert MapSet.disjoint?(MapSet.new(@undrawn), MapSet.new(@migrated, &elem(&1, 1))),
             "a screen is in both @migrated and @undrawn, which cannot both be true"
    end
  end

  describe "with nothing stored" do
    test "every undrawn store-reading screen still renders with nothing stored" do
      # The half of this file that `@undrawn` keeps rather than skips, and for
      # these two it is the half that matters. A backup page on a device that
      # has never exported, and a sync page on a device with no queued change
      # and no conflict, are not edge cases — they are the ordinary state, and
      # the state a fresh install opens in. A screen that only holds together
      # once there are rows would fail here and nowhere else, because no drawing
      # exists for the literal sweep to catch it with.
      #
      # Rendered inside the same rolled-back transaction as everything else, so
      # "nothing stored" means what it means everywhere else in this file.
      trees =
        in_empty_database(fn ->
          Map.new(@undrawn, fn module ->
            {:ok, _socket, tree} = ScreenSweep.render(module)
            {module, tree}
          end)
        end)

      for {module, tree} <- trees do
        assert_renderable(tree)

        texts =
          tree
          |> find_all(:text)
          |> Enum.map(&(&1.props[:text] || ""))
          |> Enum.reject(&(&1 == ""))

        assert length(texts) > 12,
               "#{inspect(module)} rendered #{length(texts)} strings against an empty " <>
                 "database. A page that is mostly chrome is what a lost empty state looks " <>
                 "like, and this screen has no drawing for anything else to compare"
      end
    end

    test "every migrated screen still draws every literal its drawing contains" do
      missing =
        for screen <- render_migrated(),
            literal <- screen.design.text,
            not exempt?(screen.number, literal),
            DesignLiterals.locate(literal, screen.haystacks) == :missing,
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{inspect(literal)}"

      assert missing == [],
             "these screens read the database and no longer draw their own drawing when " <>
               "nothing is stored. A fresh install renders this as a gap, and the next frame " <>
               "capture is where it would have surfaced:\n" <> Enum.join(missing, "\n")
    end

    test "every migrated screen has an entry-point gate, and every gate a migrated screen" do
      # `@migrated` is pinned from both sides against the compiled call graph, so
      # a screen that starts reading Ash cannot stay out of it. `fallbacks/0` had
      # no such pin, and it is the stronger of the two halves this file asks:
      # the literal checks are satisfied by presence anywhere in the tree, and
      # only this one puts the question to the screen's own read.
      #
      # A `for` over a list asserts nothing about a screen the list omits. So a
      # screen added to `@migrated` — which the derivation above *forces* on the
      # round it migrates — and not added here would be rendered, would pass
      # every literal check, and would have its fallback taken entirely on
      # trust. Verified by deleting screen 33's entry: the whole file still
      # passed, and 33 is the one whose moduledoc calls its own fallback the
      # subtlest here.
      listed = MapSet.new(@migrated, &elem(&1, 0))
      gated = MapSet.new(fallbacks(Kati.Time.today()), &elem(&1, 0))

      ungated = listed |> MapSet.difference(gated) |> Enum.sort()

      assert ungated == [],
             "these screens are rendered against an empty database and their own read is " <>
               "never asked what it answered, so their fallback is a claim rather than a " <>
               "result. Add each to `fallbacks/0` as `{number, module, what the screen " <>
               "reads, what the drawing is}`:\n" <> Enum.map_join(ungated, "\n", &"  #{&1}")

      stray = gated |> MapSet.difference(listed) |> Enum.sort()

      assert stray == [],
             "these screens have an entry-point gate and are not in @migrated, so nothing " <>
               "renders them and the gate is checking a screen this file does not cover:\n" <>
               Enum.map_join(stray, "\n", &"  #{&1}")

      # Both halves keyed by number, so the modules are checked too rather than
      # assumed to follow — a gate pointing at the wrong screen would otherwise
      # satisfy every set comparison above.
      mismatched =
        for {number, module} <- @migrated,
            {^number, gate_module, _live, _drawn} <-
              fallbacks(Kati.Time.today()),
            gate_module != module,
            do: "  #{number} is #{inspect(module)} in @migrated, #{inspect(gate_module)} here"

      assert mismatched == [],
             "an entry-point gate names a different module than the screen it is filed " <>
               "under:\n" <> Enum.join(mismatched, "\n")
    end

    test "each screen's own read answers empty, so it is the drawing that drew" do
      # The literal checks say the drawing's words reached the tree. They cannot
      # say *by which path* — a screen could satisfy every one of them from copy
      # that lives in its chrome while its list silently emptied, and one that
      # kept a Sample call it never reaches would pass them too.
      #
      # This asks the screen's own entry point instead, inside the same empty
      # database: what `mount/3` or `load/1` is handed must be, to the term, what
      # the screen answers with when it has decided to draw the drawing. It is
      # the assertion that the fallback exists AND is the branch an empty
      # database takes, which is the pair a moduledoc can claim and only a run
      # can settle.
      today = Kati.Time.today()

      wrong =
        in_empty_database(fn ->
          for {number, module, live, drawn} <- fallbacks(today),
              live.() != drawn.(),
              do: "  #{number} #{inspect(module)} did not answer with its drawn value"
        end)

      assert wrong == [],
             "these screens read an empty database and answered with something other than " <>
               "the values their drawing was captured from, so whatever they render is " <>
               "neither the user's data nor the design:\n" <> Enum.join(wrong, "\n")
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

    test "the clock literals are still exempted for the reason they were" do
      # An allow-list is the one thing in this file that can only ever make it
      # check less, so it is pinned from both ends. A dead entry — a literal the
      # drawing no longer contains — would be an exemption for nothing, and an
      # empty slot — a stand-in pattern matching nothing the screen renders —
      # would be hiding a line that stopped being drawn at all.
      rendered = Map.new(render_migrated(), &{&1.number, &1.texts})

      for {number, literal, pattern} <- device_values() do
        # Both sides are `DesignLiterals.normalise/1`'d already — whitespace
        # collapsed and case folded — so these compare in that form and the
        # entries above are written in it.
        assert literal in DesignLiterals.read!(number).text,
               "#{number}'s drawing no longer contains #{inspect(literal)}, so exempting it " <>
                 "exempts nothing"

        assert Enum.any?(rendered[number] || [], &Regex.match?(pattern, &1)),
               "#{number} renders nothing matching #{inspect(pattern)} on an empty database. " <>
                 "The exemption was granted because the screen draws the device's own clock " <>
                 "there; if it draws nothing, the line is gone and this was hiding it"
      end
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

  # ── What each screen must answer with when nothing is stored ────────────────

  # `{number, module, what the screen reads, what the drawing is}`. The two
  # halves are both the screen's own functions wherever it has a named one, so
  # this file holds no second copy of any drawn value — a Sample edited on one
  # side and not the other is the failure mode a literal list here would create.
  #
  # 01 is the one that is not a pair of accessors: Home mounts the timeline raw
  # and substitutes the drawing further in, at `rest_of_today/1`'s `[]` clause,
  # so the comparison is made where the substitution is. That is the screen's
  # real gate rather than a restatement of it — the clause is what would be
  # deleted by a change that broke this, and deleting it makes these two differ.
  defp fallbacks(today) do
    [
      {"01", Kati.Screens.Home, fn -> Kati.Screens.Home.rest_of_today(timeline()) end,
       fn -> Kati.Screens.Home.rest_of_today(Kati.Screens.Home.drawn_rows()) end},
      {"02", Kati.Screens.Calendar, fn -> Kati.Screens.Calendar.day_rows(today) end,
       &Kati.Screens.Calendar.drawn_rows/0},
      {"03", Kati.Screens.Library, &Kati.Screens.Library.titles/0,
       &Kati.Screens.Library.drawn_titles/0},
      # 04 gates the whole page rather than a card — either every value on it is
      # this user's or every value is the drawing's — so one pair covers the
      # title, the meta line, the season strip, the counter, the next airing and
      # all seven rows. `by_season` rides on both sides, which is what makes the
      # S1/S2/S3 pills a control on an empty database too.
      {"04", Kati.Screens.Series, &Kati.Screens.Series.series/0,
       &Kati.Screens.Series.drawn_series/0},
      # 05 gates on `:followed` being empty rather than on either list being
      # empty: "nothing is out this week" is a true thing for a release inbox to
      # say, and the drawing's three rows would be a false one. The pair
      # compares the whole map, watcher card included — that card is frozen, so
      # a round that wired its count up on its own would show here as the two
      # sides differing on a key neither list touches.
      {"05", Kati.Screens.Inbox, &Kati.Screens.Inbox.inbox/0, &Kati.Screens.Inbox.drawn_inbox/0},
      # 07 has no single drawn accessor: `figures/0` answers a keyword list whose
      # third element is a real read either way. The two the gate decides are
      # taken, in the order the list holds them.
      {"07", Kati.Screens.Stats,
       fn -> Keyword.take(Kati.Screens.Stats.figures(), [:year, :grid]) end,
       fn ->
         [
           year: Map.put(Kati.Stats.Sample.year(), :rising?, true),
           grid: Kati.Stats.Sample.contributions()
         ]
       end},
      {"08", Kati.Screens.Film, &Kati.Screens.Film.film/0, &Kati.Screens.Film.drawn_film/0},
      {"10", Kati.Screens.UpNext, &Kati.Screens.UpNext.queue/0,
       &Kati.Screens.UpNext.Sample.queue/0},
      {"15", Kati.Screens.Activity, &Kati.Screens.Activity.log/0, &Kati.Screens.Activity.drawn/0},
      {"32", Kati.Screens.Calendars, &Kati.Screens.Calendars.calendar_list/0,
       &Kati.Screens.Calendars.drawn_calendars/0},
      # 34 is the partly-migrated one, and the whole map is compared for exactly
      # that reason: the order strip, the two switches and the subtitle are the
      # drawing's on BOTH branches, so a gate that looked only at the episode
      # list would pass while one of the frozen parts quietly changed.
      {"34", Kati.Screens.Season, &Kati.Screens.Season.season/0,
       &Kati.Screens.Season.drawn_season/0},
      # 28 is 01's shape and is gated in the same place for the same reason: the
      # dark Home mounts the timeline raw and substitutes the drawing at
      # `rest_of_today/1`'s `[]` clause, so the comparison is made where the
      # substitution is rather than at a restatement of it.
      {"28", Kati.Screens.HomeDark,
       fn -> Kati.Screens.HomeDark.rest_of_today(Kati.Calendars.Today.rows()) end,
       fn ->
         Kati.Screens.HomeDark.rest_of_today(Kati.Screens.HomeDark.Sample.rest_of_today())
       end},
      # 29 answers with all four widgets at once, because it falls back one
      # widget at a time: three that still drew the drawing would hide a fourth
      # that had stopped being able to.
      {"29", Kati.Screens.Lock, &Kati.Screens.Lock.widgets/0, &Kati.Screens.Lock.drawn_widgets/0},
      {"33", Kati.Screens.Rating, &Kati.Screens.Rating.watch/0,
       &Kati.Screens.Rating.drawn_watch/0},
      {"42", Kati.Screens.Health, fn -> Kati.Screens.Health.day(today) end,
       &Kati.Screens.Health.drawn_day/0},
      {"43", Kati.Screens.MealsToday, fn -> Kati.Screens.MealsToday.day(today) end,
       &Kati.Screens.MealsToday.drawn_day/0},
      {"44", Kati.Screens.MealPlan, fn -> Kati.Screens.MealPlan.plan(today) end,
       &Kati.Screens.MealPlan.drawn_plan/0},
      {"45", Kati.Screens.Meal, fn -> Kati.Screens.Meal.meal(today) end,
       &Kati.Screens.Meal.drawn_meal/0},
      {"47", Kati.Screens.Nutrition, fn -> Kati.Screens.Nutrition.figures(today) end,
       &Kati.Screens.Nutrition.drawn_figures/0},
      {"48", Kati.Screens.Shopping, fn -> Kati.Screens.Shopping.list(today) end,
       &Kati.Meals.SampleShopping.list/0},
      # 55 is 01's shape, and gated in the same place for the same reason: the
      # Persian Home mounts the timeline raw and substitutes the drawing at
      # `rest_of_today/1`'s `[]` clause, so the comparison is made where the
      # substitution is rather than at a restatement of it.
      {"55", Kati.Screens.HomeFa,
       fn -> Kati.Screens.HomeFa.rest_of_today(Kati.Calendars.Today.rows()) end,
       fn ->
         Kati.Screens.HomeFa.rest_of_today(Kati.Screens.HomeFa.Sample.rest_of_today())
       end},
      # 56 answers with both halves of its day at once — the ordinary rows and
      # the evening's feature card — because only the drawn day has the second,
      # and a gate that looked at one half would pass while the other emptied.
      {"56", Kati.Screens.ScheduleFa, fn -> Kati.Screens.ScheduleFa.day(today) end,
       &Kati.Screens.ScheduleFa.drawn_day/0},
      {"57", Kati.Screens.LibraryFa, &Kati.Screens.LibraryFa.titles/0,
       &Kati.Screens.LibraryFa.drawn_titles/0},
      # 58 is 04's gate reached through 04's read, so this pair fails for two
      # different defects: a lost Persian fallback, and an English one — the
      # mirror cannot keep drawing its drawing if `tracked_series/0` stops
      # answering `nil` on an empty store.
      {"58", Kati.Screens.SeriesFa, &Kati.Screens.SeriesFa.series/0,
       &Kati.Screens.SeriesFa.drawn_series/0}
    ]
  end

  # What `Kati.Screens.Home.load/1` assigns, called the way the screen calls it.
  defp timeline, do: Kati.Calendars.Today.rows()

  # ── The literals no empty database can put back ─────────────────────────────

  # Screens 01, 02, 55 and 56 print the device clock, and their drawings froze
  # the day they were exported. That is not a fallback that could regress — it
  # is the same value on a full database and on an empty one — so each is exempted
  # here exactly as `Kati.ScreenDesignLiteralTest` exempts them, with a stand-in
  # pattern rather than a bare pass, and the stand-in carries **today's** day of
  # the month so a screen that hardcoded the drawing's date fails on every day
  # but one.
  #
  # Deliberately not shared with that file: two modules importing one allow-list
  # is how an exemption granted for one question quietly answers another, and
  # three entries is not the kind of duplication worth a shared fixture. The
  # `no_dead_entries` test below is what stops this copy going stale.
  # Screens 55 and 56 are the same three lines in Persian, and their stand-ins
  # carry today's **Shamsi** day rather than its Gregorian one — the number the
  # screens actually print. Two things about the patterns are not decoration:
  #
  #   * `\x{200C}` is in every word class. Four of the seven Persian weekday
  #     names contain a zero-width non-joiner (سه‌شنبه, پنج‌شنبه), and a ZWNJ is
  #     `\p{Cf}`, not `\p{L}` — so a bare `\p{L}+` would match on Saturday and
  #     fail on Tuesday, which is a stand-in that works four days in seven.
  #   * `\p{N}+` rather than `\d+`. The digits are U+06F0-U+06F9, which are
  #     `Nd` and are not what `\d` means.
  defp device_values do
    day = Integer.to_string(Kati.Time.now().day)
    {_year, _month, shamsi_day} = Kati.Calendar.Shamsi.from_gregorian(Kati.Time.today())
    fa_day = Kati.Calendar.Shamsi.fa(shamsi_day)
    word = "[\\p{L}\\x{200C}]+"

    [
      {"01", "sunday · 16 august", ~r/^\p{L}+ · #{day} \p{L}+$/u},
      {"01", "good evening", ~r/^good (morning|afternoon|evening)$/},
      {"02", "sunday 16 august · 5 items", ~r/^\p{L}+ #{day} \p{L}+ · \d+ items$/u},
      {"55", "یکشنبه ۲۵ مرداد ۱۴۰۵", ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"55", "عصر بخیر", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"56", "یکشنبه ۲۵ مرداد · ۵ مورد", ~r/^#{word} #{fa_day} #{word} · \p{N}+ مورد$/u}
    ]
  end

  defp exempt?(number, literal) do
    Enum.any?(device_values(), fn {n, l, _pattern} -> n == number and l == literal end)
  end

  # ── Which screens read a store ──────────────────────────────────────────────

  # True when `module`'s compiled code calls `Ash`, or calls something in this
  # app that does. Read off the BEAM's own import table, which is the exact set
  # of external functions the module actually calls — so a name in a moduledoc
  # or a comment cannot make a screen look like a reader, and a read that lives
  # one module away cannot hide from it.
  defp reaches_store?(module), do: MapSet.member?(store_readers(), module)

  # Memoised in `:persistent_term` for the reason every other cache in these
  # sweeps is: each ExUnit test runs in its own process, so a cache in the
  # process dictionary dies between the two tests that share this. Only plain
  # data is stored, and it depends on nothing but the compiled code.
  defp store_readers do
    key = {__MODULE__, :store_readers}

    case :persistent_term.get(key, :miss) do
      :miss ->
        set = compute_store_readers()
        :persistent_term.put(key, set)
        set

      set ->
        set
    end
  end

  defp compute_store_readers do
    _ = Application.load(:kati)
    callees = Map.new(Application.spec(:kati, :modules) || [], &{&1, callees_of(&1)})

    direct =
      for {module, called} <- callees, Enum.any?(called, &ash?/1), into: MapSet.new(), do: module

    close(callees, direct)
  end

  # One pass adds every module that calls something already known to reach Ash;
  # repeat until a pass adds nothing. A fixpoint rather than a walk per module,
  # so a cycle in the call graph terminates without a seen-set to carry.
  defp close(callees, reaching) do
    grown =
      for {module, called} <- callees,
          Enum.any?(called, &MapSet.member?(reaching, &1)),
          into: reaching,
          do: module

    if MapSet.size(grown) == MapSet.size(reaching), do: grown, else: close(callees, grown)
  end

  defp callees_of(module) do
    with beam when is_list(beam) <- :code.which(module),
         {:ok, {_module, [imports: imports]}} <- :beam_lib.chunks(beam, [:imports]) do
      imports |> Enum.map(&elem(&1, 0)) |> Enum.uniq()
    else
      _ -> []
    end
  end

  defp ash?(module) do
    name = Atom.to_string(module)
    name == "Elixir.Ash" or String.starts_with?(name, "Elixir.Ash.")
  end

  # ── Rows to prove the emptying with ─────────────────────────────────────────

  defp write_probe_rows! do
    fetched = DateTime.utc_now()

    title =
      Kati.Media.CachedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: @probe_id,
        kind: :tv,
        title: "Probe",
        fetched_at: fetched
      })
      |> Ash.create!()

    season =
      Kati.Media.CachedSeason
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        title_source_id: @probe_id,
        season_number: 1,
        fetched_at: fetched
      })
      |> Ash.create!()

    episode =
      Kati.Media.CachedEpisode
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: @probe_id,
        title_source_id: @probe_id,
        season_number: 1,
        episode_number: 1,
        fetched_at: fetched
      })
      |> Ash.create!()

    %{
      Kati.Media.CachedTitle => MapSet.new([title.id]),
      Kati.Media.CachedSeason => MapSet.new([season.id]),
      Kati.Media.CachedEpisode => MapSet.new([episode.id])
    }
  end

  # Every screen sweep in the suite renders against this one shared file, so a
  # probe row left behind is a row screen 03 would draw. Same hazard
  # `Kati.SeedsTest` documents, and the same fix.
  defp delete_probe_rows! do
    for table <- ~w(cached_titles cached_episodes) do
      Kati.Repo.query!("DELETE FROM #{table} WHERE source_id = ?1", [@probe_id])
    end

    Kati.Repo.query!("DELETE FROM cached_seasons WHERE title_source_id = ?1", [@probe_id])
    :ok
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
