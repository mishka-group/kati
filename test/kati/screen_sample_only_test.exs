Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenSampleOnlyTest do
  @moduledoc """
  The four screens that could **not** move onto the domains still draw their
  drawings when nothing is stored.

  ## Why these four are here rather than in `Kati.ScreenEmptyDatabaseTest`

  That file covers the screens the migration *moved*, and its question is
  whether a migrated screen kept the Sample fallback that makes a fresh install
  render. These four never moved. Each one names, in its own moduledoc, exactly
  which resource or column it is waiting on:

    * **06 Add a title** — no provider search client, and no first-release
      year or availability on `Kati.Media.CachedTitle`.
    * **11 Discover** — no recommender, no person, no service availability.
    * **18 Quick add** — no natural-language parser anywhere in `lib/`.
    * **19 Search** — no index. Nothing anywhere matches a title, an episode,
      an event or a review by substring.

  So today this file asserts something that is nearly free: a screen reading
  only its Sample module cannot be disturbed by an empty database, because it
  never asks the database anything.

  It is written now anyway, and it is not ceremony. The moment one of these
  four *does* move, the guard is already standing over it. The failure mode
  `Kati.ScreenEmptyDatabaseTest` documents at length is that a screen which
  lost its fallback keeps passing every other check and surfaces only as a
  blank captured frame; a guard added in the same commit as the migration is a
  guard whose first run is the one that has to catch it. This one has already
  been green a hundred times before it matters.

  ## How the database is made empty

  The same shape `Kati.ScreenEmptyDatabaseTest` uses — one transaction that is
  always rolled back — with one difference worth stating. That file writes its
  table list out by hand so a new resource trips its own guard. Two hand-kept
  copies of one list is how the second copy goes stale silently, so this file
  reads the list off `sqlite_master` instead and drops the two tables that are
  not resources. A resource that lands next round is therefore emptied here
  without anyone remembering to say so.

  Reading the list also means it cannot be ordered child-first, so
  `PRAGMA defer_foreign_keys` moves constraint checking to the commit that
  never comes. Emptiness is then asserted twice over, at both levels the
  screens use: `count(*)` through Ecto, and `Ash.read!` per resource, because
  Ash is where a screen reads and a base filter could make the two disagree.
  """
  # `async: false` for the three reasons `Kati.ScreenEmptyDatabaseTest` gives:
  # the renders switch `Kati.Locale`, which is global; the transaction below
  # holds the pool's only connection (`pool_size` is 1, see `Kati.Repo.init/2`);
  # and emptying every table is not something to do beside a test inserting into
  # one.
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.ScreenSweep

  # The screens still on their Sample modules, by the design number their
  # drawing is filed under.
  #
  # 22 and 23 join the four for the same kind of reason, and each says which in
  # its own moduledoc:
  #
  #   * **22 Habits** — `Kati.Calendars.Event.kind` can say a repeating item is
  #     a habit, and nothing anywhere records that one was **kept**.
  #     `Kati.Calendars.Override.kind` is `:modified | :cancelled`, so an
  #     occurrence can be called off and cannot be ticked. Every number the
  #     screen draws — the streak, the seven squares, the 13-week field, the
  #     header's best — is a count over that missing history.
  #   * **23 Subscriptions** — no table in the app holds a **price**. The
  #     nearest thing is a `kind: :money` event with an amount in its free-text
  #     `description`, which is two of the four services and not a source.
  @on_sample [
    {"06", Kati.Screens.AddTitle},
    {"11", Kati.Screens.Discover},
    {"18", Kati.Screens.QuickAdd},
    {"19", Kati.Screens.Search},
    {"22", Kati.Screens.Habits},
    {"23", Kati.Screens.Subscriptions}
  ]

  # Ecto's own ledger and the DETS-replacing store Mob keeps screen state in.
  # Everything else in the schema is an Ash resource's table and gets emptied.
  @not_resources ~w(schema_migrations mob_screen_states)

  # What these four screens would read from once they move — the two domains
  # their moduledocs name. Asked through Ash rather than through Ecto, because
  # `count(*)` returning zero and `Ash.read!` returning `[]` are different
  # claims and it is the second one a screen depends on.
  @resources [
    Kati.Media.TrackedTitle,
    Kati.Media.CachedTitle,
    Kati.Media.Watch,
    Kati.Calendars.Account,
    Kati.Calendars.Calendar,
    Kati.Calendars.Event
  ]

  describe "the emptiness this file rests on" do
    test "the table list is read off the schema and holds the tables that matter" do
      tables = resource_tables()

      # A derived list cannot go stale, but it can come back empty — a changed
      # pragma, a renamed system table — and emptying nothing would make every
      # assertion below vacuous. So the tables the four screens' own domains sit
      # on are named here, and only here, as proof the read worked.
      for table <-
            ~w(cached_titles media_content_warnings tracked_titles media_watches events calendars) do
        assert table in tables,
               "#{table} was not read off sqlite_master, so this file is not emptying it " <>
                 "and the renders below prove nothing about a fresh install"
      end

      assert @not_resources -- tables == @not_resources,
             "a table this file declares not-a-resource is being emptied anyway"
    end

    test "inside the transaction both Ecto and Ash agree there is nothing stored" do
      {counts, reads} =
        in_empty_database(fn ->
          counts =
            for table <- resource_tables(),
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
  end

  describe "with nothing stored" do
    test "every screen still on a Sample draws every literal its drawing contains" do
      missing =
        for screen <- render_on_sample(),
            literal <- screen.design.text,
            DesignLiterals.locate(literal, screen.haystacks) == :missing,
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{inspect(literal)}"

      assert missing == [],
             "these screens no longer draw their own drawing when nothing is stored. If one " <>
               "of them has just moved onto a domain, it moved without keeping its Sample " <>
               "fallback — see the moduledoc:\n" <> Enum.join(missing, "\n")
    end

    test "every screen still on a Sample draws every Material Symbol its drawing draws" do
      missing =
        for screen <- render_on_sample(),
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
      # a screen whose lists emptied while its chrome survived could still pass
      # it whenever the drawing's copy happens to sit in the chrome. Counting
      # what was rendered catches the shape of that before it needs a frame.
      thin =
        for screen <- render_on_sample(),
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

  # Every table in the schema that backs an Ash resource, read off SQLite rather
  # than listed. See the moduledoc for why this file derives what
  # `Kati.ScreenEmptyDatabaseTest` writes out.
  defp resource_tables do
    %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'")

    rows
    |> List.flatten()
    |> Enum.reject(&String.starts_with?(&1, "sqlite_"))
    |> Enum.reject(&(&1 in @not_resources))
    |> Enum.sort()
  end

  # Runs `fun` with every table emptied, and always rolls back. `Ash.read!` and
  # `Kati.Repo.query!` inside `fun` run in this same process, so they use the
  # connection the transaction checked out and see the empty state; nothing is
  # written, so the suite's other fixtures survive.
  #
  # `defer_foreign_keys` is what lets the deletes run in whatever order
  # `sqlite_master` hands them back: it moves constraint checking to COMMIT, and
  # this transaction never commits. It is scoped to the transaction and resets
  # itself, so nothing outside sees it.
  defp in_empty_database(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Kati.Repo.query!("PRAGMA defer_foreign_keys = ON")
        Enum.each(resource_tables(), &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  defp table_counts do
    Map.new(resource_tables(), fn table ->
      %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}")
      {table, n}
    end)
  end

  # ── Rendering ───────────────────────────────────────────────────────────────

  # Memoised in `:persistent_term` for the reason the other two screen sweeps
  # state: each ExUnit test runs in its own process and `Mob.ScreenCase` restarts
  # `Mob.State` around each one, so a cache in the process dictionary or in ETS
  # dies between the tests that share the work. Only plain data is stored.
  defp render_on_sample do
    key = {__MODULE__, :render_on_sample}

    case :persistent_term.get(key, :miss) do
      :miss ->
        screens = in_empty_database(&do_render_on_sample/0)
        :persistent_term.put(key, screens)
        screens

      screens ->
        screens
    end
  end

  defp do_render_on_sample do
    for {number, module} <- @on_sample do
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
