Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ScreenWriteTargetTest do
  @moduledoc """
  **A write acts on the row the page drew, never on a fresh query.**

  That sentence has been carried in prose by three rounds of review and has
  been broken four times anyway. This file is the sentence as a check.

  ## The one shape, four times

  Each of these shipped green, and each was found by an agent told to break
  the domain rather than by anything in this suite:

    * `7a45424` — screen 66 wrote to the shelf's newest BOOK while the page
      drew the fixture. `book/1` collapses *nobody named one* and *the named
      one is gone* into one value, and `apply_change/2`'s `nil` means the
      shelf's newest.
    * `b4b9a0d` — screen 79 followed whoever led the shelf AT TAP TIME,
      because the page could not name the artist it drew; screen 73 credited a
      play to whoever led the shelf AT SAVE TIME.
    * `44f3656` — screen 43's Swap handed over whatever `Mob.State` was still
      holding, because a swapped card's ids were blanked.

  One shape: **the page resolves a row at mount, and the write re-queries
  later.** Both halves are individually reasonable, and the gap between them
  is only visible when the two answers differ — which is exactly the state the
  suite never put a screen in.

  ## The assertion

  Mount every screen that reads an argument with params **naming a row that
  does not exist** — a fresh uuid under every key that screen reads. Render
  it. Dispatch every tap it drew. **Nothing in the store may change.**

  A page that was named a row it cannot find is drawing its fixture. There is
  nothing on it a write can honestly act on, so a write that lands anyway
  landed on a row the reader was not looking at — which is the defect, in every
  one of its four instances, with no per-domain knowledge needed to say so.

  The store is seeded with **one row in every table** first, and that is the
  whole reason this file exists rather than being a corollary of
  `Kati.ScreenParamsSweepTest`. A wrong-row write needs a wrong row to land
  on. Against the empty store every sweep in this directory renders against,
  all four defects above write nothing and read green — measured, not assumed:
  reverting screen 66's fix and running this file over an empty store passes.

  ## The second assertion, and why the first one needed it

  The assertion above only reaches screens that READ an argument, because
  *named a row that is gone* is a state you can only put a reader in. Three of
  the four defects in the list were on screens that read NO params at the time
  they were broken, so reverting those fixes takes the screen out of the sweep
  rather than making it fail. Measured, by an adversarial pass that
  reintroduced all four: **the assertion above caught one of them.**

  So there is a second one, and it needs no params at all.

  Seed **two** rows in every table. Mount every screen **BARE** — no argument,
  the mount a gallery makes and the one every other sweep here renders.
  Render. Dispatch each tap. Then, for every row that changed:

  > **Every seeded id the changed row carries must be an id the socket's
  > assigns were holding when the tap was dispatched.**

  A row carries its own id and its foreign keys, and the assigns are walked for
  binaries that are seeded primary keys. That set is *what the page could
  honestly have been about*: the ids it resolved, drew, and could name. A write
  that lands on a row whose id the page never held is a write to a row the
  reader never saw — which is the one shape, again, said without a single word
  about params.

  Two rows rather than one, so that *the row the page drew* and *the row a
  fresh query returns* CAN differ. With one row seeded they are the same row by
  arithmetic and the gap this whole file is about cannot open. Which of the two
  a naive reader takes is that read action's own business — `:shelf` sorts
  `updated_at: :desc` and takes the second, `:all` sorts `name: :asc` and takes
  the first — and the assertion does not need to know: it is symmetric, and
  asks only that whatever was written was held.

  ## The score, measured rather than claimed

  The same four defects, reintroduced one at a time into a copy of the tree and
  run against this file as it now stands. **Two of four**, and the two that
  escape escape for different reasons, both of which are worth writing down
  because both were expected to be caught and neither is.

    * **Screen 66 — caught, by assertion 1.** Reverting `target/1` to
      `assigns.book[:id]` fails `a screen named a row that is gone writes
      nothing` and names nine of its own chips. It is a params reader, so
      assertion 1 reaches it. Assertion 3 does not see it at all: opened BARE,
      `book(nil)` resolves the shelf's head and `shaped/3` carries its id, so
      the page holds exactly the row the write lands on and is right to.

    * **Screen 79 — caught, by assertion 3, and this is the one the file was
      missing.** Reverting `shaped/2`'s `id: artist.id` and
      `handle_tap(:toggle_following, …)`'s `target/1` fails `every bare write
      lands on a row the page was holding` on `music_artists`, on the English
      screen AND on its Persian twin, which nothing had asked about at all.
      Assertion 1 cannot: the reverted screen reads no argument and falls out
      of its set.

    * **Screen 73 — NOT caught, and the reason corrects the premise.** The
      claim this assertion was built on was that screen 73's sheet drew a
      shaped map carrying no id. It does not:
      `Kati.Screens.AlbumDetail.shaped/4` has carried `id: album.id` since
      before `b4b9a0d`, so a bare sheet holds the album's id in
      `assigns.album` whether or not `mount/3` pins it in `:album_id`. What
      `b4b9a0d` fixed there was a RACE — the sheet drew A at mount and
      `save_listen/1` re-read the shelf at save, so B got the play if B reached
      the head in between — and a sweep that mounts, renders and taps with
      nothing else touching the store never opens that window. The page holds
      the id, the write lands on it, and the rule is satisfied by a screen that
      would still be wrong on a device.

      The instrument that would reach it is a **shelf that moves between the
      render and the tap**: bump the second seeded row to the head of every
      `updated_at: :desc` read after mounting and before dispatching, and a
      write that re-queries lands on a row the page cannot be holding. It is
      not built here, deliberately and not for lack of knowing how — the
      perturbation is an `UPDATE` per table per screen plus a re-read of the
      store at each of them, which is the sixteen-thousand-statement regime
      that took the connection down and made this file a flake once already.
      See `watch/2`. It wants its own file, its own transaction and its own
      measurement.

    * **Screen 43 — NOT caught, as predicted.** Its wrong row was the first
      upcoming meal in `assigns.day.meals`, a list the page drew, so the id it
      handed over was one the assigns held. The rule cannot see a write that
      picks the wrong element of a list the page is honestly holding; and the
      thing it handed over went through `Mob.State` rather than into a row, so
      even the id check never runs on it. `sheet_row_identity_test.exs` is
      where that question is asked, one row at a time and with the domain
      knowledge to say which row was right.

  So: one shape, four instances, two of them now visible from inside the suite
  where one was. What assertion 3 bought beyond that is a class the file could
  not reach at all before — a write on a screen that reads no argument — and it
  found two live ones on its first run, which are in `@writes_a_stranger` with
  their fixes.

  ## The ways this file was wrong before it was right

  Each of these produced a confident clean run, and each is why a line below
  reads the way it does.

    * **Not seeding at all**, which is the suite's actual blind spot and the
      reason the four commits above exist. `Kati.ScreenParamsSweepTest` refuses
      to seed and is right to: it compares two RENDERS, and a render against a
      stocked shelf is a different page. This file compares the STORE, so the
      shelf's contents change nothing about what it asks and everything about
      what it can see.

    * **Taking the taps from `Kati.ScreenSweep.drawn_taps/1`.** Twice wrong.
      It memoises the mounted trees in `:persistent_term` for the whole run, so
      a seeded pass that asked first would hand `Kati.ScreenTapSweepTest` and
      `Kati.AppReachabilityTest` trees drawn against a store they did not
      choose — a flake moved into someone else's file, on the orderings where
      this one runs first. And it mounts BARE, which is the one mount ASSERTION
      1 must not use: its taps have to be the ones a page drew *after being
      named a row it could not find*. So this file mounts and renders its own
      trees, inside its own transaction, and shares no memo with anything —
      which is what lets assertion 3 mount bare on purpose, against a store of
      its own, without either pass borrowing the other's page.

    * **Sweeping every screen rather than the readers, in assertion 1.** A
      screen that reads no params is handed `%{id: <uuid>}` and ignores it, so
      the mount is a bare mount — and a bare mount is a screen told *no
      particular row*, where the shelf's newest is the correct target. Screen
      151's `Log by hand` is the written example; `Kati.Screens.LogListen`'s
      no-id path is the right semantics for it. Including those screens would
      have filled assertion 1's inventory with correct behaviour, and an
      inventory of correct behaviour is how a real entry gets lost.

      Assertion 3 sweeps all of them and is not the same mistake, because it
      asks a different question of that mount: not *did you write while
      resolving nothing*, which a bare mount cannot be blamed for, but *did you
      write to a row you were not holding*, which it can. The shelf's newest is
      a correct target only for a page that RESOLVED the shelf's newest, and
      the id is what makes the difference visible.

    * **Reading the store back through `Ash.read` per resource.** Two ways to
      go blind. Every read action in this app is a lens — `:shelf` sorts,
      `:for_artist` filters — and a resource may filter its primary read too,
      so a write that made a row invisible to the action reads as *nothing
      changed*. And the seed is written with `Ash.Seed.seed!/2`, which bypasses
      actions and validations on purpose, so a seeded row can be one a typed
      read refuses to cast; the comparison would then be between two
      exceptions. `SELECT *` sees the bytes, and the table list comes out of
      `sqlite_master` so a table added next week is covered the day it is
      added — the argument `Kati.ScreenSweep.rolled_back/1` makes for a
      rollback over a `DELETE` list.

      Rows rather than `count(*)` plus a checksum, which was the other
      candidate: a checksum says the store moved, and this file's whole output
      is a message somebody has to act on. Thirty-six tables holding one row
      each is small enough to keep whole, and keeping it whole is what lets the
      failure print the row that appeared. A digest does earn its place as the
      TRIGGER — see the next bullet — but never as the finding.

    * **Comparing only the whole store, once, around the whole pass.** That is
      assertion 1 and it is not enough on its own: it says *something wrote*
      and cannot say *what*. A ratchet whose entries cannot name a door is a
      ratchet nobody can check, so the store is WATCHED at every point — after
      each mount and after each tap — and a change is attributed to the
      `{screen, tap}` that was dispatched across it. `:mount` is a point like
      any other, because a mount that writes is the same defect one callback
      earlier.

      Watched, not read. Reading all thirty-six tables at all four hundred and
      fifty points put sixteen thousand statements inside one `:immediate`
      transaction on a `pool_size: 1` repo, and that took the connection down —
      one `DBConnection.ConnectionError` in seven whole-suite runs, a flake in
      this file dressed as a finding about the app. SQLite's own
      `total_changes()` answers *did anything write* in one statement, and the
      rows are re-read only at the handful of points where something did. See
      `watch/2`, which gets more out of the counter than speed.

    * **Seeding every boolean at its default, which is the subtle one.** A
      wrong-row write is only detectable if it reaches SQLite, and
      `Ash.update/2` with nothing to change issues no statement at all — not
      even an `updated_at` bump. Screen 79's `toggle_following` is one boolean
      and the page's drawn artist has `following: true`, so the write sets
      `false` onto a seeded artist that was already `false` and leaves no
      trace anywhere.

      Measured rather than reasoned about. Two of the fixes above were reverted
      by hand against this file: screen 66's `target/1` failed it immediately
      and named nine of its own chips, and screen 79's `toggle_following`
      passed it — a green run over a live wrong-row write. The difference was
      the seed, so every writable boolean is now seeded to the opposite of its
      default, and screen 79's revert fails on `music_artists`.

      Screen 66 was caught without that help for a reason worth knowing: it
      draws four mutually exclusive status chips and three format chips, and
      the sweep presses all of them, so at least one lands on a value the row
      did not already hold. A screen with one toggle has no such luck. See
      *what this cannot do* for what is still uncovered.

    * **Letting `Mob.State` leak.** It is DETS. It is not in the transaction,
      and rolling the database back does not touch it — so the pass left
      `:kati_search_query` holding a uuid for whatever rendered screen 19 next,
      which is a defect this file would have caused in a file it never touched.
      `restored/1` puts it back, for the reason `Kati.ScreenSweep.rolled_back/1`
      gives about rows.

    * **Reading a clean run as proof.** It is not, on its own: a pass that
      mounted nothing, drew nothing or dispatched nothing also changes no rows.
      The control is `bare_pass/0` — the SAME screens, the SAME seeded store,
      the SAME taps, mounted with `%{}` instead — and it writes to five tables.
      Same taps, same store, one difference: the params. That is what makes
      assertion 1 a finding rather than an absence.

  ## What a write that is not a row edit is treated as

  `Mob.State` is a second store and assertion 1 sweeps it as one, not waved
  through: every key is diffed at every point, alongside the tables. Screen
  43's Swap travelled through it, which is why a file that looked only at rows
  could not have described the fourth defect in the list above even in
  principle.

  It still does not CATCH it, and the reason is the other half — screen 43
  reads no params, so it is not in assertion 1's set at all, and assertion 3,
  which is, watches rows and not keys. `watch_rows/3` says why. So the fourth
  defect is out of reach from two directions at once, and the measured score
  above is the honest consequence.

  A setting is a row edit in a different table, and `Kati.Theme.Mode`,
  `Kati.Money` and `Kati.Services` all write theirs there; none is reachable
  from a params reader today, and if one becomes so it will arrive as a finding
  and need a line in the inventory rather than a silent pass.

  The one entry that exists is a carried VALUE rather than a reference —
  `Kati.ScreenParamsSweepTest`'s `@carried_values` makes the same distinction
  about the same key — and its reason is written beside it.

  ## What this cannot do, and no amount of care will fix

    * **Assertion 1 only covers params readers.** A screen that reads no
      argument can never be *named a row it cannot find*, so there is no state
      that assertion can put it in. That was screen 79's own state before
      `b4b9a0d`: it took no params, and reverting that commit takes the screen
      out of assertion 1 rather than making it fail. Assertion 3 is the half
      that reaches a non-reader, and `Kati.ScreenParamsSweepTest`'s assertion 1
      is the half that covers the door into one — that one says the push names
      something, these say the write respects what the page had.

    * **Assertion 3 cannot see a wrong row inside a right list.** Its whole
      rule is *the id was held*, and a page holding a list of rows is holding
      every id in it. Screen 43's Swap is the worked example above; a grid that
      wrote to the wrong tile would be another. What narrows that is a screen
      drawing FEWER rows, which is not something a sweep gets to arrange.

    * **Assertion 3 says nothing about a row with no seeded id in it.** A tap
      that inserts a standalone row — a goal, an expense — writes a row whose
      own id is fresh and whose foreign keys are empty, so there is no id to
      have held and nothing to compare. That is correct rather than a hole
      (nobody's row was taken), but it does mean the assertion is silent on
      every screen whose only write is a create with no parent.

    * **Assertion 3's ids are primary keys, and one table's is not a uuid.**
      `Kati.Notifications.Pending`'s key is a deterministic string, seeded like
      any other, so it participates; a table whose key were an integer would
      not, since `held/3` matches binaries. Nothing in the app has one today
      and `the drawn pass seeded two rows in every table it watched` is what
      would notice the seed going missing, not this.

    * **A write that never reaches SQLite is invisible.** `total_changes()`
      sees a statement whose values happened to match, so most idempotent
      writes are caught even though assertion 1's byte comparison cannot show
      them. What nothing here can see is a write that is short-circuited
      ABOVE the database: `Ash.update/2` with no changed attribute issues no
      statement at all, so the counter never moves. That is screen 79's case
      exactly, and it is why the booleans are seeded away from their defaults.
      Enums are not, and cannot honestly be — there is no value an enum can be
      seeded to that is guaranteed to differ from what a tap writes, and
      picking one at random would trade a known hole for an unpredictable one.
      What covers those in practice is that a screen usually draws its whole
      chip set and this presses all of them.

    * **One tap at a time, each from the mounted socket.** A save that only
      writes after another control has set something is swept in its untouched
      state. Chaining the taps instead would change what is drawn between them
      and make the pass order-dependent, which is a worse trade; screens whose
      save needs a value have their own domain test.

    * **The seed is minimal, and a filtered read can see straight past it.**
      One row per table for assertion 1 and two for assertion 3, each carrying
      its required attributes and nothing else, so a
      screen whose read filters on a column the seed leaves at its default
      finds an empty shelf, draws its fixture, and is proved less about than it
      looks. That is not silent: `the same taps write when the page named
      nothing` is the measurement of how much of the app the seed actually
      reaches, and the five tables it names are the evidence.

    * **It says nothing about a write that named a row which EXISTS.** Whether
      the second row's Save moves the second row is `sheet_row_identity_test.exs`,
      which builds two real rows to ask it. This file is only about the state
      where there is no honest target at all.

    * **The seeded rows never face a foreign key.** `PRAGMA defer_foreign_keys`
      is on and the transaction is rolled back, so the end where they would be
      checked never comes. A row here can be one SQLite would refuse at commit.
      That is a property of the seed, not of the app.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  @locales [:en, :fa]

  # Every write a screen makes after being named a row that does not exist, as
  # of 2026-09-05. `{screen, point, target}`, where `point` is the tap that was
  # dispatched (or `:mount`), and `target` is `{:db, table}` or
  # `{:state, key}`.
  #
  # An entry is a claim that the page had something honest to act on even
  # though the row it was named is gone — which, for a page drawing its
  # fixture, is a strong claim and needs the sentence that justifies it. It is
  # never a to-do: a door that should not write belongs in `lib/`, not here.
  #
  # Ratcheted both ways. A write that arrives fails `every write this pass
  # makes is written down`; an entry that stops writing fails `the write
  # inventory has no stale entries`. So this list may only shrink.
  @writes_anyway [
    # ── Screen 19's `Look it up`, and the one write here that is about a
    # VALUE rather than a row.
    #
    # `search.ex:335-338` hands the query over to screen 06 through
    # `Kati.Search.hand_over/1` before pushing, so the add sheet opens already
    # searching for what was typed rather than asking for it again. The thing
    # handed over is `socket.assigns.query`, which came off this page's own
    # params — and a uuid is a perfectly good search term. The page IS drawing
    # what it was named; there is no row it failed to resolve.
    #
    # This is the same distinction `Kati.ScreenParamsSweepTest`'s
    # `@carried_values` draws about the same key, and for the same reason: a
    # label naming no row is still a label. `:back` and `:query` are on that
    # list; `:scope` is deliberately not, and neither is anything here.
    #
    # The key is `Mob.State`'s and not a row's, which is why this file sweeps
    # `Mob.State` at all — see the moduledoc. `Kati.Search.hand_over/1` lives
    # with the specification rather than on the screen, and its own doc says
    # why.
    {Kati.Screens.Search, :look_up, {:state, :kati_search_query}}
  ]

  # The tables the CONTROL pass writes to — the same screens, the same seeded
  # store, the same taps, mounted with `%{}` instead of with a uuid.
  #
  # This is what stops assertion 1 being an absence. A bare mount means *no
  # particular row*, the shelf's newest is the right target, and these writes
  # are correct: screen 66 sets a status on the seeded book, screen 111 saves
  # reading sessions against it, screens 73/77/79 credit plays and follow the
  # seeded artist. Every one of them is a tap assertion 1 also presses.
  #
  # Asserted as a SUBSET of what the control observes, so a domain that starts
  # writing more never fails this. A domain that stops is the failure worth
  # having: it means the seed no longer reaches that screen, and assertion 1
  # has quietly stopped proving anything about it.
  @bare_pass_writes ~w(
    book_reading_sessions
    books
    music_albums
    music_artists
    music_listens
  )

  # Floors, and they may only go up. Every one of them is a way for this file
  # to pass over nothing: a scan that stops finding readers, a render that
  # stops drawing controls, a `sqlite_master` read that comes back short.
  #
  # Measured on 2026-09-05: 23 readers, 36 tables, 408 taps dispatched over the
  # two locales. Set just under, because the honest direction for all three is
  # up and a floor pinned to the exact number is a floor that fails on the
  # commit that adds a button.
  @readers_swept 21
  @tables_seeded 34
  @taps_dispatched 360

  # ── assertion 3's own lists ─────────────────────────────────────────────────

  # Every write a BARELY mounted screen makes to a row carrying a seeded id
  # the page was not holding, as of 2026-09-05. `{screen, point, {:db, table}}`,
  # where `point` is the tap that was dispatched or `:mount`.
  #
  # Unlike `@writes_anyway`, this list is a BACKLOG rather than a set of
  # exemptions, and the distinction is the one `Kati.ScreenParamsSweepTest`
  # draws between `@bare_pushes` and `@empty_builders`. Nothing below is a write
  # this file is willing to call right. Each is the moduledoc's defect, found by
  # this assertion on the day it was written, on a screen whose fix is a change
  # to `lib/` that this file's own commit is not scoped to make. The entry
  # carries the fix so the next person does not have to find it again.
  #
  # Ratcheted both ways, like `@writes_anyway`, so it may only shrink.
  @writes_a_stranger [
    # ── Screen 115, the Persian mirror of the medication page.
    #
    # `Kati.Screens.HealthFa.doses/0` shapes each dose as time, name, line and
    # state and DROPS the id — `health_fa.ex:341-348`. So the two verbs inside
    # the due card carry no row, `Kati.Screens.Medication.handle_tap/2` finds
    # nothing to decide, and `other_tap/2` falls through to `next_undecided/0`,
    # which re-reads the day AT TAP TIME and takes the first `:due` dose it
    # sees. That is screen 79's defect exactly — a page that drew one thing
    # writing to whatever a fresh query answers — and here it says somebody
    # took a tablet.
    #
    # Already named in prose, and by nothing else: `medication.ex:85-93` calls
    # these *the identity-less door, kept working rather than quietly broken*
    # and says the fix is *giving 115's own list ids, which is 115's change*.
    # The prose has been right and untested since it was written; this is the
    # assertion that makes it fail. Fixing it is one line in `doses/0` plus the
    # `tap`/`taken`/`skip` tags screen 112's rows already carry.
    {Kati.Screens.HealthFa, :mark_taken, {:db, "health_doses"}},
    {Kati.Screens.HealthFa, :mark_skipped, {:db, "health_doses"}},

    # ── Screen 72's `ثبت پیشرفت` save, and the one nothing had noticed.
    #
    # `sheet(nil)` answers `Kati.Books.SampleFa.sheet/0` — the fixture, with no
    # id — where `sheet(id)` merges the named book's own fields over it
    # (`log_progress_fa.ex:82-89`). `Save` then calls
    # `Kati.Screens.LogProgress.save_session(page, nil)`, and `current_book(nil)`
    # is the head of the shelf: a session is written against a book the sheet
    # never drew, and `move_position/2` walks that book's `current_page` forward
    # to whatever the stepper was showing.
    #
    # The English sheet is not here and the difference is the whole finding.
    # Screen 70 assigns `:book` from `book(nil)`, which RESOLVES the shelf's
    # head and carries its id, so what it draws and what it writes are one row.
    # Screen 72 resolves nothing and writes anyway.
    #
    # Reachable: screen 71 hands an id whenever it has one, so the bare mount is
    # `Kati.Screens.Gallery`'s — board 72 opened from the catalogue on a device
    # with books on the shelf, where `Save` moves a real book. The fix is
    # `sheet/1`'s `nil` clause merging `shelved_book(nil)` the way screen 70's
    # `book/1` does, so the sheet draws the book it is about to write to.
    {Kati.Screens.LogProgressFa, :save, {:db, "book_reading_sessions"}},
    {Kati.Screens.LogProgressFa, :save, {:db, "books"}}
  ]

  # Floors for assertion 3's pass, and they may only go up. Measured on
  # 2026-09-05 over the two locales — 169 screens, 2465 taps — and set just
  # under, for the reason the floors above are.
  @screens_swept 160
  @drawn_taps 2300

  # Rows per table in assertion 3's seed. Two, and the moduledoc says why:
  # with one, *the row the page drew* and *the row a fresh query returns* are
  # the same row, and the gap this file is about cannot open.
  @rows_each 2

  # Ecto's own ledger and the table Mob keeps screen state in are not the app's
  # data; emptying them would be emptying the harness.
  # `Kati.ScreenParamsSweepTest` and `Kati.ScreenEmptyDatabaseTest` draw the
  # same line in the same words.
  @not_data ~w(schema_migrations mob_screen_states)

  # A row id no store will ever hold, fresh per key so no two are equal and
  # nothing can match by accident.
  defp nothing, do: Ecto.UUID.generate()

  # ── assertion 1: the store does not move ────────────────────────────────────

  test "a screen named a row that is gone writes nothing" do
    pass = named_pass()

    moved =
      for {table, rows} <- pass.after_db,
          rows != Map.get(pass.before_db, table),
          table not in exempt_tables() do
        {table, Map.get(pass.before_db, table, []), rows}
      end

    assert moved == [],
           "the store moved while every screen on it had been named a row that does not " <>
             "exist. A page that could not find what it was named is drawing its fixture, so " <>
             "there is nothing on it a write can act on — a write that landed anyway landed " <>
             "on a row the reader was not looking at, which is the defect this file exists " <>
             "for. Look at what recovers the write's target: an id kept from the params is " <>
             "right, a re-read of the shelf at tap time is the bug:\n\n" <>
             Enum.map_join(moved, "\n\n", fn {table, was, now} ->
               "  #{table}: #{length(was)} row(s) before, #{length(now)} after\n" <>
                 "    gained: #{inspect(now -- was, limit: 4, printable_limit: 200)}\n" <>
                 "    lost:   #{inspect(was -- now, limit: 4, printable_limit: 200)}"
             end)
  end

  test "the same taps write when the page named nothing" do
    # The control, and the only thing that makes assertion 1 a finding rather
    # than an absence. Same screens, same seeded store, same taps — mounted
    # with `%{}` instead of with a uuid, which means *no particular row* and
    # makes the shelf's newest the correct target.
    missing = @bare_pass_writes -- bare_pass()

    assert missing == [],
           "these tables were written by the control pass when it was measured and are not " <>
             "written now, so the seed no longer reaches the screens that write to them and " <>
             "assertion 1 has stopped proving anything there — it is passing because nothing " <>
             "can write, not because nothing wrongly does. Find what stopped resolving: a " <>
             "read action that filters on a column `seed_one_row_per_table/0` leaves at its " <>
             "default is the usual cause:\n" <> Enum.map_join(missing, "\n", &"  #{&1}")
  end

  # ── assertion 2: the ratchet ────────────────────────────────────────────────

  test "every write this pass makes is written down" do
    unexpected = Enum.reject(named_pass().writes, &Enum.member?(@writes_anyway, &1))

    assert unexpected == [],
           "these controls wrote while the page they are on had been named a row that does " <>
             "not exist. Either the write recovers its target by re-querying — keep the id " <>
             "the push NAMED beside the row it RESOLVED, the way " <>
             "`Kati.Screens.BookDetail.target/1` does, and refuse when the named row is gone " <>
             "— or the thing written is genuinely the page's own and not a row it failed to " <>
             "find, in which case add it to @writes_anyway with the sentence that says " <>
             "so:\n\n" <>
             Enum.map_join(unexpected, "\n", fn {module, point, target} ->
               "  #{inspect(module)} #{describe(point)} wrote #{describe_target(target)}"
             end)
  end

  test "the write inventory has no stale entries" do
    stale = @writes_anyway -- named_pass().writes

    assert stale == [],
           "these controls no longer write, or are no longer drawn at all. Delete them from " <>
             "@writes_anyway in #{Path.relative_to_cwd(__ENV__.file)} — an exemption that " <>
             "covers nothing is an exemption sitting over whatever arrives next:\n" <>
             Enum.map_join(stale, "\n", fn {module, point, target} ->
               "  #{inspect(module)} #{describe(point)} #{describe_target(target)}"
             end)
  end

  # ── guard A: the pass is not vacuous ────────────────────────────────────────

  test "the pass seeded a row in every table it then watched" do
    # The seed is the difference between this file and every other sweep here,
    # and it is derived — resources off the domains, required attributes off
    # each resource, table names off `sqlite_master`. Every step of that can
    # answer *nothing* without raising, and a store with no rows in it is a
    # store no wrong write can be seen against.
    pass = named_pass()

    assert map_size(pass.before_db) >= @tables_seeded,
           "the sweep watched only #{map_size(pass.before_db)} tables where " <>
             "#{@tables_seeded} is the floor. `sqlite_master` came back short, or " <>
             "@not_data has grown — either way the store is being watched through a " <>
             "keyhole"

    empty = for {table, []} <- pass.before_db, do: table

    assert empty == [],
           "these tables were seeded with nothing, so a write that landed in one would be a " <>
             "write to a store this file left empty — and an empty table is exactly the " <>
             "state in which all four of the defects in the moduledoc write nothing and " <>
             "read green. `seed_one_row_per_table/0` could not build a row: read the " <>
             "resource's required attributes and widen `value_for/1`:\n" <>
             Enum.map_join(empty, "\n", &"  #{&1}")
  end

  test "the pass mounted the readers and pressed what they drew" do
    pass = named_pass()

    assert pass.unrendered == [],
           "these screens did not render at all when named a row that does not exist, so no " <>
             "tap was pressed on them and assertion 1 is silent about them. A reader handed " <>
             "an id whose row is gone must draw its drawing, never raise — " <>
             "`Kati.ScreenParamsSweepTest`'s fallback lock is the assertion that says so:\n" <>
             Enum.join(pass.unrendered, "\n")

    assert pass.readers >= @readers_swept,
           "the scan found #{pass.readers} screens that read an argument where " <>
             "#{@readers_swept} is the floor, so this file is now sweeping less of the app " <>
             "than it was written to sweep. A screen leaves the scan for edits that change " <>
             "no behaviour at all — a renamed `mount/3` argument, a read spelled " <>
             "`params[:id]` — and every tap on it leaves assertion 1 with it. " <>
             "`Kati.ScreenParamsSweepTest` carries the same guard over the same derivation, " <>
             "in more detail; lower this only beside the reason a screen stopped reading"

    assert pass.taps >= @taps_dispatched,
           "the pass dispatched #{pass.taps} taps where #{@taps_dispatched} is the floor. " <>
             "Assertion 1 is a claim about the controls a page draws, and it is now being " <>
             "made over fewer of them than it was written for — a screen has stopped drawing " <>
             "its rows, or the render stopped reaching them"
  end

  test "a reader whose key scan came back empty fails rather than mounting bare" do
    # The hole an adversarial pass found in the derivation, and it is a hole
    # with a name: rewrite `Kati.Screens.Season` to bind `asked = params || %{}`
    # and read `asked[:key]`, and `reader?/1` still counts it while
    # `reader_keys/1` answers `[]`. `build_params.([])` is then `%{}` — a BARE
    # mount, the one mount assertion 1 must not use — and the screen keeps its
    # place in `@readers_swept` while being asked nothing at all. Every tap on
    # it passes assertion 1 by construction.
    #
    # `Kati.ScreenParamsSweepTest` fails on exactly this state, in the same
    # words, and this is that rule brought over: two files sharing a derivation
    # must share its guards, or the one without them is the one that goes
    # quiet.
    empty = for {module, []} <- readers(), do: module

    assert empty == [],
           "these screens read `params` and the key scan came back with nothing, so " <>
             "`named_pass/0` hands them `%{}` — a BARE mount, which is a screen told *no " <>
             "particular row* and the one state in which the shelf's newest is the correct " <>
             "target. They are counted in @readers_swept and assertion 1 is asking them " <>
             "nothing. Follow the read the way `key_pattern/1` follows an alias, or the " <>
             "screen leaves this sweep:\n" <> Enum.map_join(empty, "\n", &"  #{inspect(&1)}")
  end

  # ── assertion 3: a write lands on a row the page was holding ────────────────

  test "every bare write lands on a row the page was holding" do
    unexpected = Enum.reject(drawn_pass().strangers, &Enum.member?(@writes_a_stranger, &1))

    assert unexpected == [],
           "these controls wrote to a row carrying a seeded id that the socket's assigns did " <>
             "not hold when the tap was dispatched. The page was mounted BARE and the store " <>
             "has #{@rows_each} rows in every table, so the write chose a row — and the page " <>
             "cannot have chosen it, because it was not holding it. That is a write to a row " <>
             "the reader never saw, which is the one defect this file exists for, and it is " <>
             "the form of it that assertion 1 cannot reach because these screens read no " <>
             "argument. Look at what recovers the write's target: a re-read of the shelf at " <>
             "tap time is the bug, and the fix is to carry the resolved row's id into the " <>
             "assigns the way `Kati.Screens.ArtistDetail.shaped/2` carries `:id` and " <>
             "`target/1` spends it:\n\n" <>
             Enum.map_join(unexpected, "\n", fn {module, point, target} ->
               "  #{inspect(module)} #{describe(point)} wrote #{describe_target(target)}"
             end)
  end

  test "the stranger inventory has no stale entries" do
    stale = @writes_a_stranger -- drawn_pass().strangers

    assert stale == [],
           "these controls no longer write to a row the page was not holding, or are no " <>
             "longer drawn at all. Delete them from @writes_a_stranger in " <>
             "#{Path.relative_to_cwd(__ENV__.file)} — the list is a backlog and a backlog " <>
             "that has stopped describing anything is a backlog sitting over whatever " <>
             "arrives next:\n" <>
             Enum.map_join(stale, "\n", fn {module, point, target} ->
               "  #{inspect(module)} #{describe(point)} #{describe_target(target)}"
             end)
  end

  # ── guard B: assertion 3's pass is not vacuous ──────────────────────────────

  test "the drawn pass seeded two rows in every table it watched" do
    pass = drawn_pass()

    short =
      for {table, rows} <- pass.before_db,
          length(rows) < @rows_each,
          do: {table, length(rows)}

    assert short == [],
           "these tables hold fewer than #{@rows_each} rows, so assertion 3 is asking about " <>
             "them with no wrong row to land on — with one row, *the row the page drew* and " <>
             "*the row a fresh query returns* are the same row and the gap this file is " <>
             "about cannot open. `seed_rows/1` could not build the second one: a unique " <>
             "index the seed collides with is the usual cause, and `value_for/2` is where a " <>
             "second distinguishable value comes from:\n" <>
             Enum.map_join(short, "\n", fn {table, count} -> "  #{table}: #{count}" end)

    assert MapSet.size(pass.ids) >= @tables_seeded * @rows_each,
           "the pass recognises only #{MapSet.size(pass.ids)} seeded row ids where " <>
             "#{@tables_seeded * @rows_each} is the floor. `seeded_ids/1` reads primary keys " <>
             "off `PRAGMA table_info`, and an id it cannot see is an id assertion 3 will " <>
             "never ask about — the assertion goes quiet rather than failing"
  end

  test "the drawn pass mounted every screen bare and pressed what it drew" do
    pass = drawn_pass()

    assert pass.screens >= @screens_swept,
           "the drawn pass mounted #{pass.screens} screens where #{@screens_swept} is the " <>
             "floor. Assertion 3's whole reach is that it needs no params, so it covers " <>
             "every screen in the app; covering fewer of them than it was written for means " <>
             "screens are failing to mount or render bare, which is " <>
             "`Kati.ScreenRenderSweepTest`'s finding and this file's blind spot"

    assert pass.taps >= @drawn_taps,
           "the drawn pass dispatched #{pass.taps} taps where #{@drawn_taps} is the floor. " <>
             "Assertion 3 is a claim about the controls a page draws and it is now being " <>
             "made over fewer of them than it was written for"
  end

  # ── the pass ────────────────────────────────────────────────────────────────

  # Mount every reader with a fresh uuid under every key it reads, render it,
  # and press everything it drew — watching the store across each step.
  #
  # Inside `seeded/1`, which empties the store, puts one row in every table and
  # rolls the lot back. Emptying first is not tidiness: assertion 1's reasoning
  # is about *the shelf's newest*, and "one row" is only a fact if the rows
  # another test left behind are gone. `restored/1` does the same job for
  # `Mob.State`, which the transaction cannot reach.
  defp named_pass do
    memo(:named_pass, fn -> pass(fn keys -> Map.new(keys, fn key -> {key, nothing()} end) end) end)
  end

  # The control. See `the same taps write when the page named nothing`.
  defp bare_pass do
    memo(:bare_pass, fn ->
      control = pass(fn _keys -> %{} end)

      for {table, rows} <- control.after_db,
          rows != Map.get(control.before_db, table),
          do: table
    end)
  end

  # Assertion 3's pass. Every screen, mounted BARE against a store holding
  # `@rows_each` rows in every table, with each tap's row changes checked
  # against the ids the socket's assigns were holding.
  #
  # Its own seed and its own transaction, sharing neither with `pass/1`. Two
  # rows change what a page draws, and `named_pass/0`'s numbers — the
  # inventory, `@bare_pass_writes`, the floors — were all measured against one.
  # Threading a second row through those would have re-measured four ratchets
  # in order to add a fifth.
  #
  # `:mount` is a point here as it is there, and the assigns it is checked
  # against are the ones the mount produced: a mount that writes to the row it
  # then draws is honest, and a mount that writes to a row it does not draw is
  # the same defect one callback earlier.
  defp drawn_pass do
    memo(:drawn_pass, fn ->
      seeded(@rows_each, fn ->
        restored(fn ->
          before_db = read_rows()
          ids = seeded_ids(before_db)

          {points, _db} =
            Enum.reduce(@locales, {[], before_db}, fn locale, {points, db} ->
              ScreenSweep.with_locale(locale, fn ->
                {more, db} = walk_drawn(ScreenSweep.screens(), ids, db)
                {points ++ more, db}
              end)
            end)

          %{
            before_db: before_db,
            ids: ids,
            # The screens that RENDERED, not the screens that were tried: a
            # screen that will not mount bare draws no controls, so counting it
            # here would let the floor be met by screens this pass never asked
            # anything of.
            screens:
              points
              |> Enum.filter(fn {_module, point, _strangers} -> point == :mount end)
              |> Enum.map(fn {module, _point, _strangers} -> module end)
              |> Enum.uniq()
              |> length(),
            taps:
              Enum.count(points, fn {_module, point, _strangers} ->
                point not in [:mount, :no_render]
              end),
            strangers:
              for(
                {module, point, strangers} <- points,
                target <- strangers,
                do: {module, stable_point(point), target}
              )
              |> Enum.uniq()
              |> Enum.sort()
          }
        end)
      end)
    end)
  end

  # One locale's worth of assertion 3's points. A screen that will not mount or
  # render bare is not reported as broken here — `Kati.ScreenRenderSweepTest` is
  # what fails over those, and repeating its failure would bury the write
  # findings — but its mount is still watched, because a callback that wrote and
  # then raised wrote.
  defp walk_drawn(screens, ids, db) do
    Enum.reduce(screens, {[], db}, fn module, {points, db} ->
      {mounted, mount_moved, db} = watch_rows(db, ids, fn -> ScreenSweep.render(module) end)

      case mounted do
        {:ok, socket, tree} ->
          held = ids_held(socket.assigns, ids)

          {taps, db} =
            Enum.reduce(ScreenSweep.tap_tags(tree), {[], db}, fn tag, {taps, db} ->
              {_answer, moved, db} =
                watch_rows(db, ids, fn ->
                  ScreenSweep.safely(fn -> module.handle_info({:tap, tag}, socket) end)
                end)

              {taps ++ [{module, tag, strangers(moved, held)}], db}
            end)

          {points ++ [{module, :mount, strangers(mount_moved, held)} | taps], db}

        # A screen that will not mount or render bare still had its mount
        # watched — a write from a callback that then raised is a write — and
        # it is `:no_render` rather than `:mount` so it counts as neither a
        # rendered screen nor a tap.
        _unrendered ->
          {points ++ [{module, :no_render, strangers(mount_moved, MapSet.new())}], db}
      end
    end)
  end

  # The rows that moved, reduced to the tables whose moved rows were about a
  # seeded id the page was not holding. What *about* means is `touched_ids/3`.
  #
  # The table and not the id, because the id is a uuid minted by this pass and
  # an inventory entry keyed on one would go stale on the next run — the same
  # reason `stable_point/1` takes the id back out of a tap tag. The failure
  # message is where the detail belongs; the entry is a door.
  defp strangers(moved, held) do
    for {table, row_ids} <- moved,
        id <- row_ids,
        not MapSet.member?(held, id),
        uniq: true,
        do: {:db, table}
  end

  defp pass(build_params) do
    seeded(1, fn ->
      restored(fn ->
        before_db = read_store()

        {points, _db} =
          Enum.reduce(@locales, {[], before_db}, fn locale, {points, db} ->
            ScreenSweep.with_locale(locale, fn ->
              {more, db} = walk(readers(), build_params, db)
              {points ++ more, db}
            end)
          end)

        %{
          before_db: before_db,
          after_db: read_store(),
          readers: map_size(readers()),
          taps: Enum.count(points, fn {_module, point, _writes} -> point != :mount end),
          unrendered:
            for({module, :mount, {:error, why}} <- points, do: "  #{inspect(module)}: #{why}"),
          writes:
            for(
              {module, point, targets} <- points,
              is_list(targets),
              target <- targets,
              do: {module, point, target}
            )
            |> Enum.uniq()
            |> Enum.sort()
        }
      end)
    end)
  end

  # One locale's worth of points: `{screen, :mount}` and then `{screen, tag}`
  # for every tag the render drew, each carrying the store's targets that
  # changed across it — and the store's rows as they now stand, threaded on so
  # the next point compares against them.
  #
  # The store is watched at every point rather than once around the pass,
  # because an inventory keyed on `{screen, tag}` needs the finding to name the
  # door. `:mount` is a point like any other — a mount that writes is the same
  # defect one callback earlier, and `load/1` is where three of the four
  # defects in the moduledoc did their resolving.
  defp walk(readers, build_params, db) do
    Enum.reduce(readers, {[], db}, fn {module, keys}, {points, db} ->
      {mounted, mount_writes, db} = watch(db, fn -> mount_render(module, build_params.(keys)) end)

      case mounted do
        {:ok, socket, tree} ->
          {taps, db} =
            Enum.reduce(ScreenSweep.tap_tags(tree), {[], db}, fn tag, {taps, db} ->
              {_answer, writes, db} =
                watch(db, fn ->
                  ScreenSweep.safely(fn -> module.handle_info({:tap, tag}, socket) end)
                end)

              {taps ++ [{module, tag, writes}], db}
            end)

          {points ++ [{module, :mount, mount_writes} | taps], db}

        {:error, why} ->
          {points ++ [{module, :mount, {:error, why}}], db}
      end
    end)
  end

  # Run `fun` and answer with what it returned, every store target that
  # differs across it — `{:db, table}` for a row, `{:state, key}` for a
  # `Mob.State` entry — and the rows as they stand afterwards.
  #
  # Both stores, because screen 43's Swap travelled through the second one and
  # a file that watched only rows would have called the fourth defect in the
  # moduledoc out of scope. See the moduledoc on what a write that is not a row
  # edit is treated as.
  #
  # `total_changes()` is the TRIGGER and the rows are the FINDING, which is not
  # a refinement — it is what makes this file safe to run beside the rest of
  # the suite. Reading all thirty-six tables at all four hundred and fifty
  # points is sixteen thousand statements inside one `:immediate` transaction
  # on a `pool_size: 1` repo, and it took the connection down often enough to
  # be a flake in this file rather than a finding about the app: measured, one
  # `DBConnection.ConnectionError` in seven whole-suite runs. SQLite's own
  # counter answers *did anything write* in one statement, so the rows are only
  # re-read at the handful of points where something did.
  #
  # The counter also sees strictly more than the rows do — it counts a row an
  # `UPDATE` touched whether or not the value changed — so a write that lands
  # on the value already stored is reported here, without a table, where the
  # byte comparison in assertion 1 cannot see it at all. That is the
  # *idempotent write* hole in the moduledoc, half closed.
  defp watch(db, fun) do
    changes_before = row_changes()
    state_before = read_state()

    answer = fun.()

    {db_targets, db} =
      if row_changes() == changes_before do
        {[], db}
      else
        now = read_store()

        case for {table, rows} <- now, rows != Map.get(db, table), do: {:db, table} do
          [] -> {[{:db, :no_visible_change}], now}
          moved -> {moved, now}
        end
      end

    state_after = read_state()

    # Both directions over the keys, because a `Mob.State.delete/1` is a write
    # too — `Kati.Sections` and `Kati.Onboarding` both clear a key — and a scan
    # over the AFTER map alone cannot see a key that is no longer in it.
    state =
      for key <- Enum.uniq(Map.keys(state_before) ++ Map.keys(state_after)),
          Map.get(state_before, key) != Map.get(state_after, key),
          do: {:state, key}

    {answer, db_targets ++ state, db}
  end

  # `watch/2`'s shape at ROW resolution, for assertion 3.
  #
  # Answers what `fun` returned, `{table, [seeded id]}` for every row that
  # appeared, vanished or changed across it, and the rows as they now stand.
  # The list is a multiset difference in both directions, so an UPDATE shows up
  # as the old row leaving and the new row arriving — both carry the same
  # primary key, which is the id assertion 3 is about, so the doubling costs
  # nothing and the deletion half is not lost.
  #
  # Same `total_changes()` trigger as `watch/2`, for the same reason: at two
  # rows across thirty-six tables and every screen in the app, reading the store
  # at every point is the thing that took the connection down.
  #
  # `Mob.State` is deliberately not watched here. Assertion 3's rule is about a
  # ROW's id, and the one `Mob.State` write in the app that carries a row id —
  # screen 43's Swap — is the one the moduledoc says escapes anyway, because
  # the id it hands over is in the assigns. `watch/2` is where that store is
  # swept.
  defp watch_rows(db, ids, fun) do
    changes_before = row_changes()
    answer = fun.()

    if row_changes() == changes_before do
      {answer, [], db}
    else
      now = read_rows()

      moved =
        for {table, rows} <- now,
            was = Map.get(db, table, []),
            rows != was,
            row <- (rows -- was) ++ (was -- rows),
            row_ids = touched_ids(table, row, ids),
            row_ids != [],
            do: {table, row_ids}

      {answer, moved, now}
    end
  end

  # What a changed row's write was ABOUT, as seeded ids.
  #
  # Two cases, and the split is the difference between an edit and a create:
  #
  #   * **The row has a seeded primary key** — it existed before the tap, so the
  #     write is an edit or a delete and the row it acted on is that key. Only
  #     the key. Whose child the row is is not the page's business: screen 55
  #     marks a dose taken by the dose's own id, and demanding it also hold the
  #     MEDICATION's id would fail a control that names its subject exactly.
  #
  #   * **The row does not** — its id was minted by the tap, so it is a create
  #     and it has no identity of its own to have been held. What it is about is
  #     what it POINTS AT, so every seeded id in it counts. That is the half
  #     that sees screen 73's defect: a listen is an insert, and the album it
  #     credits is a foreign key.
  #
  # Found by value rather than by column name, so a column added next week is
  # covered the day it is added.
  defp touched_ids(table, row, ids) do
    own =
      for key <- primary_keys(table),
          value = Map.get(row, key),
          is_binary(value),
          MapSet.member?(ids, value),
          do: value

    case own do
      [] -> for {_column, v} <- row, is_binary(v), MapSet.member?(ids, v), uniq: true, do: v
      own -> own
    end
  end

  # Every seeded id anywhere in `term` — the ids the page could honestly have
  # been about.
  #
  # A deep walk rather than a look at named assigns, because a screen puts its
  # ids wherever its own shape puts them: `assigns.book[:id]`, a list of shaped
  # rails, a tuple in a form. The rule is *the page was holding this id*, and
  # holding it inside a list is still holding it.
  defp ids_held(term, ids), do: held(term, ids, MapSet.new())

  defp held(binary, ids, acc) when is_binary(binary) do
    if MapSet.member?(ids, binary), do: MapSet.put(acc, binary), else: acc
  end

  # Structs before maps: `Map.from_struct/1` raises on a plain map, and a
  # `%Kati.Books.Book{}` sitting in an assign holds its id in a field like any
  # other map.
  defp held(%_struct{} = struct, ids, acc), do: held(Map.from_struct(struct), ids, acc)

  defp held(map, ids, acc) when is_map(map) do
    Enum.reduce(map, acc, fn {key, value}, acc -> held(value, ids, held(key, ids, acc)) end)
  end

  defp held(list, ids, acc) when is_list(list), do: Enum.reduce(list, acc, &held(&1, ids, &2))
  defp held(tuple, ids, acc) when is_tuple(tuple), do: held(Tuple.to_list(tuple), ids, acc)
  defp held(_other, _ids, acc), do: acc

  # `Kati.ScreenSweep.mount/1` mounts a screen as a bare push; this is the same
  # call with the push naming something, and it is the one hook this file
  # needs. Rendering is part of it: a page's controls are what the render drew,
  # and the taps this file presses have to be that page's and not a bare
  # mount's.
  defp mount_render(module, params) do
    with {:ok, {:ok, %Mob.Socket{} = socket}} <-
           ScreenSweep.safely(fn -> module.mount(params, %{}, Mob.Socket.new(module)) end),
         {:ok, tree} <- ScreenSweep.safely(fn -> module.render(socket.assigns) end) do
      {:ok, socket, tree}
    else
      {:ok, other} -> {:error, "mount/3 returned #{inspect(other, limit: 3)}"}
      {:error, message} -> {:error, message}
    end
  end

  # ── the readers, from source ────────────────────────────────────────────────

  # `%{module => [key]}` for every screen that reads the push's params.
  #
  # The same derivation `Kati.ScreenParamsSweepTest` uses, deliberately: two
  # scans that disagree about which screens are readers would be two files
  # quietly checking different halves of the app. That file carries the long
  # argument for why this is source rather than
  # `function_exported?(dest, :params_for, 1)`, and the guards that fail when
  # the scan stops matching — including the one that catches a reader whose
  # keys come back empty. Read it there; the floor above is this file's share.
  defp readers do
    memo(:readers, fn ->
      for module <- ScreenSweep.screens(),
          source = File.read!(source_path(module)),
          reader?(source),
          into: %{},
          do: {module, reader_keys(source)}
    end)
  end

  defp reader?(source) do
    source =~ ~r/socket\.assigns\.params/ or
      (source =~ ~r/^  def mount\(params,/m and source =~ ~r/Map\.get\(\s*params/)
  end

  defp reader_keys(source) do
    source
    |> key_pattern()
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&String.to_atom/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp key_pattern(source) do
    aliases =
      ~r/^\s*([a-z_][a-zA-Z0-9_]*)\s*=\s*params\b/m
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()

    names =
      (["socket.assigns.params", "params"] ++ aliases)
      |> Enum.uniq()
      |> Enum.map_join("|", &Regex.escape/1)

    Regex.compile!("Map\\.get\\(\\s*(?:#{names})\\s*(?:\\|\\|\\s*%\\{\\}\\s*)?,\\s*:([a-z_]+)")
  end

  defp source_path(module) do
    file = module |> Module.split() |> List.last() |> Macro.underscore()
    path = Path.expand("../../lib/kati/screens/#{file}.ex", __DIR__)

    assert File.exists?(path), "no source for #{inspect(module)} at #{path}"
    path
  end

  # ── the seeded store ────────────────────────────────────────────────────────

  # Empty every table, put exactly one row in each, run `fun`, roll all of it
  # back.
  #
  # Emptying first makes "one row" true rather than "one row plus whatever the
  # suite left". Assertion 1's whole reasoning is about a write reaching *the
  # shelf's newest*, and which row that is has to be a fact this file
  # established.
  #
  # Foreign keys are deferred so the order `sqlite_master` returns does not
  # have to be a dependency order, and the transaction is rolled back, so the
  # end where they would be checked never comes.
  defp seeded(rows, fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Kati.Repo.query!("PRAGMA defer_foreign_keys = ON", [])
        Enum.each(app_tables(), &Kati.Repo.query!("DELETE FROM " <> &1, []))
        seed_rows(rows)
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  # `rows` rows in every table, built from each resource's own declaration.
  #
  # Through `Ash.Seed.seed!/2` rather than each resource's create action: an
  # action carries validations about what a real row means — a reading session
  # whose pages run forwards, an expense with a currency — and this file needs
  # a row to exist, not a row to be plausible. Seeding through the actions
  # would make the seed a hostage to every domain's rules and would fail on the
  # first resource whose create action wants an argument.
  #
  # Parents first, so a child's foreign key points at the row that was actually
  # seeded rather than at a uuid nothing holds. That is what makes the seeded
  # album the seeded artist's, which is what lets screen 77's rail draw a real
  # row at all.
  # A whole pass over the resources per row, rather than two rows per resource,
  # so the second round's foreign keys point at the second round's parents: the
  # second album belongs to the second artist, and a screen reading one artist's
  # records sees one of the two rather than both. Two children of one parent
  # would make the wrong row invisible to exactly the reads assertion 3 is
  # about.
  #
  # Distinguishable, and `value_for/2` is where that happens: the strings carry
  # the row's index, the integers ARE it, and every uuid is fresh. The
  # timestamps separate themselves — the second round runs after the first, and
  # the `:desc` sorts that decide *the shelf's newest* read them.
  defp seed_rows(rows) do
    Enum.reduce(1..rows, %{}, fn index, ids ->
      Enum.reduce(ordered_resources(), ids, fn resource, ids ->
        case ScreenSweep.safely(fn ->
               Ash.Seed.seed!(resource, attrs_for(resource, ids, index))
             end) do
          {:ok, record} -> Map.put(ids, resource, Map.get(record, :id))
          # Not raised over: `the pass seeded a row in every table it then
          # watched` is where an unseedable resource is reported, and it reports
          # all of them rather than the first.
          {:error, _why} -> ids
        end
      end)
    end)
  end

  defp resources do
    (Application.get_env(:kati, :ash_domains) || [])
    |> Enum.flat_map(&Ash.Domain.Info.resources/1)
  end

  defp ordered_resources do
    set = MapSet.new(resources())

    {order, _seen} =
      Enum.reduce(resources(), {[], MapSet.new()}, fn resource, acc ->
        visit(resource, set, acc)
      end)

    Enum.reverse(order)
  end

  defp visit(resource, set, {order, seen}) do
    if MapSet.member?(seen, resource) do
      {order, seen}
    else
      parents =
        for relationship <- Ash.Resource.Info.relationships(resource),
            relationship.type == :belongs_to,
            MapSet.member?(set, relationship.destination),
            do: relationship.destination

      {order, seen} =
        Enum.reduce(parents, {order, MapSet.put(seen, resource)}, &visit(&1, set, &2))

      {[resource | order], seen}
    end
  end

  defp attrs_for(resource, ids, index) do
    required =
      for attribute <- Ash.Resource.Info.attributes(resource),
          attribute.writable?,
          not attribute.allow_nil?,
          # A generated primary key has a default and is skipped here with the
          # rest; `Kati.Notifications.Pending`'s is a deterministic string with
          # no default and is not, which is why this does not filter on
          # `primary_key?`.
          is_nil(attribute.default),
          into: %{},
          do: {attribute.name, value_for(attribute, index)}

    # Every writable boolean, at the OPPOSITE of its default. See the
    # moduledoc: `Ash.update/2` with nothing to change issues no statement, so
    # a wrong-row write that sets a flag to the value the row already holds is
    # invisible, and every seeded flag sitting at its default is one screen 79
    # slipped through. Required attributes win the merge — a boolean that is
    # both is already covered above.
    flags =
      for attribute <- Ash.Resource.Info.attributes(resource),
          attribute.writable?,
          attribute.type == Ash.Type.Boolean,
          into: %{},
          do: {attribute.name, attribute.default != true}

    fks =
      for relationship <- Ash.Resource.Info.relationships(resource),
          relationship.type == :belongs_to,
          id = Map.get(ids, relationship.destination),
          into: %{},
          do: {relationship.source_attribute, id}

    flags |> Map.merge(required) |> Map.merge(fks)
  end

  # A value of the right type, and the same one everywhere so a seeded row is
  # recognisable in a failure message. Enums take the first of their `one_of`,
  # which is a choice with a hole in it — see *an idempotent write is
  # invisible* in the moduledoc.
  #
  # Raises on a type it has never met, deliberately: a silent `nil` there is a
  # `NOT NULL` failure one line later, reported as *this resource could not be
  # seeded* with no clue which attribute did it.
  # `index` is the row's round, and it is what makes the second row a DIFFERENT
  # row rather than a duplicate — which matters twice: a unique index the two
  # rows collided on would leave the table with one row, and a wrong-row write
  # onto an identical row would be invisible in the bytes.
  #
  # Round one is byte-for-byte what the one-row seed always produced, so
  # `named_pass/0`'s inventory and floors mean what they meant when they were
  # measured. Only the rounds after it are new.
  #
  # The dates are deliberately NOT walked apart. Half this app filters on
  # *today*, and a second row dated yesterday would be a second row those
  # screens never see — the wrong row has to be reachable to be landed on.
  @seed_string "screen-write-target-sweep"

  defp value_for(%{name: name, type: type, constraints: constraints}, index) do
    cond do
      is_list(constraints[:one_of]) -> hd(constraints[:one_of])
      type == Ash.Type.String -> @seed_string <> suffix(index)
      type == Ash.Type.Integer -> index
      type == Ash.Type.Boolean -> true
      type == Ash.Type.Date -> Kati.Time.today()
      type in [Ash.Type.UtcDatetime, Ash.Type.UtcDatetimeUsec] -> DateTime.utc_now()
      type == Ash.Type.UUID -> Ecto.UUID.generate()
      true -> raise "no seed value for #{inspect(name)} of #{inspect(type)}"
    end
  end

  defp suffix(1), do: ""
  defp suffix(index), do: "-" <> Integer.to_string(index)

  # ── reading the store ───────────────────────────────────────────────────────

  # `%{table => rows}`, by `SELECT *` over every table `sqlite_master` names.
  # See the moduledoc for why this and not `Ash.read` per resource, and why the
  # rows are kept rather than reduced to a count and a checksum.
  #
  # Sorted, because SQLite promises no order without an `ORDER BY` and this is
  # compared by value.
  defp read_store do
    Map.new(app_tables(), fn table ->
      %{rows: rows} = Kati.Repo.query!("SELECT * FROM " <> table, [])
      {table, Enum.sort(rows)}
    end)
  end

  # `%{table => [%{column => value}]}` — `read_store/0`'s rows with their column
  # names on, which assertion 3 needs and assertion 1 does not: comparing bytes
  # only needs the bytes, but *which id did this row carry* needs to know what a
  # column is.
  #
  # Unsorted, unlike `read_store/0`. The comparison here is a multiset
  # difference (`--`), which does not care about order, and sorting maps would
  # only cost.
  defp read_rows do
    Map.new(app_tables(), fn table ->
      %{columns: columns, rows: rows} = Kati.Repo.query!("SELECT * FROM " <> table, [])
      {table, Enum.map(rows, &Map.new(Enum.zip(columns, &1)))}
    end)
  end

  # Every id the seed put in the store, as the values of every table's PRIMARY
  # KEY.
  #
  # Primary keys and not every uuid-shaped value in the store: a row's identity
  # is what a foreign key points at and what a page can name, where some other
  # uuid column is a value the row happens to carry. Requiring the page to hold
  # one of those would be requiring it to hold a fact rather than a row.
  #
  # Off `PRAGMA table_info` rather than off `Ash.Resource.Info.primary_key/1`,
  # for the reason `app_tables/0` reads `sqlite_master`: the tables are the
  # subject, and one that no resource declares is one this would otherwise be
  # blind to.
  defp seeded_ids(db) do
    for {table, rows} <- db,
        key <- primary_keys(table),
        row <- rows,
        value = Map.get(row, key),
        is_binary(value),
        into: MapSet.new(),
        do: value
  end

  # `pk` is the column's position in the primary key, one-based, and `0` for a
  # column that is not in it — so a composite key answers with all of its parts.
  defp primary_keys(table) do
    %{rows: rows} = Kati.Repo.query!("PRAGMA table_info(" <> table <> ")", [])

    for [_cid, name, _type, _notnull, _default, pk] <- rows, pk > 0, do: name
  end

  # SQLite's own count of every row an `INSERT`, `UPDATE` or `DELETE` has
  # touched on this connection since it was opened. Monotonic, and it counts
  # rows a rolled-back statement touched too — which is exactly what is wanted
  # from a change DETECTOR, where a byte comparison is what is wanted from a
  # change DESCRIPTION.
  #
  # Sound here because the repo runs one connection (`pool_size: 1`, and
  # `Kati.Repo`'s own comment says why) and the pass holds it inside a
  # transaction, so there is no other writer whose changes this could miss or
  # borrow.
  defp row_changes do
    %{rows: [[count]]} = Kati.Repo.query!("SELECT total_changes()", [])
    count
  end

  defp app_tables do
    %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'", [])

    for [name] <- rows,
        name not in @not_data,
        not String.starts_with?(name, "sqlite_"),
        do: name
  end

  # `Mob.State` whole. `match/1` builds `{pattern, :_}`, so `:_` is every pair.
  defp read_state, do: Map.new(Mob.State.match(:_))

  # Run `fun` and put `Mob.State` back the way it was.
  #
  # The transaction cannot: `Mob.State` is DETS and `Kati.Repo.rollback/1` has
  # never heard of it. Without this the pass leaves `:kati_search_query`
  # holding a uuid — screen 19 opens on `Kati.Search.handed_over/0` when no
  # query is named, so the next file to render it would draw results for a word
  # nobody typed, and only on the orderings where this file ran first. That is
  # the failure `Kati.ScreenSweep.rolled_back/1` was written for, in the store
  # it does not cover.
  defp restored(fun) do
    before = read_state()

    try do
      fun.()
    after
      now = read_state()

      for key <- Enum.uniq(Map.keys(before) ++ Map.keys(now)),
          Map.get(before, key) != Map.get(now, key) do
        case Map.fetch(before, key) do
          {:ok, was} -> Mob.State.put(key, was)
          :error -> Mob.State.delete(key)
        end
      end
    end
  end

  # ── odds and ends ───────────────────────────────────────────────────────────

  # Tables a `@writes_anyway` entry already accounts for, so assertion 1 and
  # assertion 2 cannot disagree about the same door. Empty today: the one entry
  # is a `Mob.State` key.
  defp exempt_tables do
    for {_module, _point, {:db, table}} <- @writes_anyway, do: table
  end

  # A tap tag with the row id taken out of it, so an inventory entry survives
  # the next run.
  #
  # Screen 55 draws `dose_<uuid>` and screen 43 draws `swap_<uuid>` — the tag
  # names the row, which is the fix `44f3656` made — so the tag a seeded store
  # produces is different every pass and an entry keyed on one would go stale
  # the moment it was written. The star is what the id was: two doors that
  # differ only in which row they name are one entry, which is what a per-screen
  # inventory wants to say anyway.
  @uuid ~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  defp stable_point(:mount), do: :mount

  defp stable_point(tag) do
    tag |> Atom.to_string() |> String.replace(@uuid, "*") |> String.to_atom()
  end

  defp describe(:mount), do: "on mount"
  defp describe(:no_render), do: "on a mount that then failed to render"
  defp describe(tag), do: "on #{inspect(tag)}"

  defp describe_target({:db, :no_visible_change}),
    do: "a row, without changing a stored value — see `watch/2`"

  defp describe_target({:db, table}), do: "to the #{table} table"
  defp describe_target({:state, key}), do: "Mob.State's #{inspect(key)}"

  # `:persistent_term` for the reason `Kati.ScreenSweep.drawn_taps/1` gives:
  # each ExUnit test runs in its own process and `Mob.ScreenCase` restarts
  # `Mob.State` around each one, so a cache in the process dictionary or in ETS
  # dies between the tests that share the work.
  #
  # Keyed on `__MODULE__`, and it shares nothing with any other sweep — which
  # matters more here than anywhere else in this directory, because the trees
  # this file mounts were drawn against a SEEDED store and a sweep that read
  # them as its own would be comparing a stocked shelf to an empty one. The
  # moduledoc's second bullet is that mistake from the other side.
  defp memo(key, fun) do
    key = {__MODULE__, key}

    case :persistent_term.get(key, :miss) do
      :miss ->
        value = fun.()
        :persistent_term.put(key, value)
        value

      value ->
        value
    end
  end
end
