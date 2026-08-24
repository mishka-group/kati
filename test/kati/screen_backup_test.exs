defmodule Kati.ScreenBackupTest do
  @moduledoc """
  `Kati.Screens.Backup` and `Kati.Screens.Restore` against the engine they
  exist to reach.

  ## What this file is for

  `Kati.Backup` was finished and proven on the device before any screen called
  it, so the risk here is **not** that the engine is wrong. It is that a screen
  and the engine disagree: a count printed from one query and a file written
  from another, a refusal shown as a failure, a passphrase field wired to
  nothing, a restore offered before the file has been read. Every assertion
  below therefore compares what a screen *drew*, or *read*, against what the
  engine *answered*, on real files with real bytes — never against a call
  returning `:ok`, which is the same standard `Kati.BackupTransportTest` holds
  itself to and for the same reason: a zero-byte backup satisfies `:ok`.

  ## One file, two screens — and which half of #25 each one owns

  This file was written when there was one screen for both halves. On 24 August
  #25's artboards landed and drew **two**: `128.html` *Back up everything* and
  `129.html` *Restore from a backup*. The behaviour split with them, so the
  tests did too, and every describe block below says which screen it drives.

    * **Export stays on `Kati.Screens.Backup`** — the count, the passphrase
      seal, and the hand-off to Save and Share.
    * **Restore moved to `Kati.Screens.Restore`** — picking a file,
      `inspect_file/2`, unlocking a sealed one, the three collision modes, the
      safety export, and every notice about a picked file. Four describe blocks
      moved with it and are marked; nothing was dropped to make the move fit,
      and the assertions that could not survive the new drawings are named in
      the comment on each one rather than deleted.

  ## Why the sweeps do not cover this

  `Kati.ScreenRenderSweepTest` mounts a screen and asserts one root node;
  `Kati.ScreenTapSweepTest` taps what the resting frame drew and asserts
  something changed. Neither reads the copy, and **neither goes past the
  resting frame** — `ScreenSweep.drawn_taps/1` renders once, at mount, so every
  control that only exists once a file has been picked (Unlock, the safety
  note) is invisible to it. This file drives those states.

  `Kati.ScreenDesignLiteralTest` covers what each drawing contains and nothing
  about what happens after a tap. Both screens hold their board exactly at rest
  — every state this file drives is a zero-height spacer until it is entered —
  which is why that sweep and this one can both be true at once.

  ## Nothing here changes the shared database

  `test/test_helper.exs` migrates one SQLite file and every test shares it, and
  a restore is the single most destructive thing this app can do to it. So:

    * the `:into_empty` case is asserted **because it refuses** — the engine
      writes nothing, which is the whole point of that mode;
    * the `:merge` case restores a backup **of this same database**, so every
      row collides on its own id and is skipped. Nothing is inserted, nothing is
      overwritten, and the table counts are asserted equal before and after;
    * `:replace` is never run. Its precondition — that Kati names and writes a
      safety export first — is asserted on the screen and on `safety_path/0`,
      not by emptying the suite's fixtures.

  The empty-database render uses one transaction that is always rolled back,
  the same shape `Kati.ScreenSampleOnlyTest` uses, with the table list read off
  `sqlite_master` so a resource added next round is emptied without anyone
  remembering to say so.
  """
  # `async: false` three times over: the renders switch `Kati.Locale`, which is
  # global; the rollback transaction below holds the pool's only connection
  # (`pool_size` is 1, see `Kati.Repo.init/2`); and exporting every table beside
  # a test that is inserting into one would race.
  use Mob.ScreenCase, async: false

  alias Kati.Backup.Sample
  alias Kati.Backup.Transport
  alias Kati.Screens.Backup
  alias Kati.Screens.Restore

  # Ecto's own ledger and the DETS-replacing store Mob keeps screen state in.
  # Everything else in the schema is an Ash resource's table.
  @not_resources ~w(schema_migrations mob_screen_states)

  @passphrase "correct horse battery staple"

  setup do
    dir = Path.join(System.tmp_dir!(), "kati_screen_backup_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf(dir) end)

    # One real row, so every "the counts agree" assertion below is about a
    # positive number. Two empty things agreeing proves nothing.
    tracked =
      Kati.Media.TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: "screen-backup-#{System.unique_integer([:positive])}",
        kind: :tv,
        status: :watching,
        rating: 7
      })
      |> Ash.create!()

    on_exit(fn -> Ash.destroy(tracked) end)

    {:ok, dir: dir}
  end

  # ── The screen at rest ──────────────────────────────────────────────────────

  describe "the resting frame" do
    test "load/1 reads nothing, so the screen is the same with a full database and an empty one" do
      # The claim `Kati.Screens.Backup`'s moduledoc makes. Byte-for-byte
      # equality is the strongest available form of "an empty database
      # renders": not merely that it does not crash, but that it draws the
      # identical tree.
      full = tree(mount_screen(Backup))
      empty = in_empty_database(fn -> tree(mount_screen(Backup)) end)

      assert full == empty,
             "the screen drew a different tree against an empty database, so something " <>
               "in mount/3 or content/1 is reading the store. Every number on this " <>
               "screen is supposed to be fetched by a tap"

      assert assigns(mount_screen(Backup)).backup == Backup.blank()
    end

    test "the emptying this rests on really empties something" do
      # A claim about zero is satisfied by a database that was empty to begin
      # with, so the row `setup` wrote is asked about directly: present outside
      # the transaction, gone inside it, and back afterwards.
      outside = Ash.count!(Kati.Media.TrackedTitle)
      assert outside > 0, "setup wrote no row, so the comparison above proves nothing"

      assert in_empty_database(fn -> Ash.count!(Kati.Media.TrackedTitle) end) == 0
      assert Ash.count!(Kati.Media.TrackedTitle) == outside
    end

    test "renders a tree the native layer can draw, in both locales" do
      for locale <- [:en, :fa], screen <- [Backup, Restore] do
        previous = Kati.Locale.current()
        Kati.Locale.put(locale)
        assert_renderable(mount_screen(screen))
        Kati.Locale.put(previous)
      end
    end

    test "no number is drawn before one has been read" do
      tree = tree(mount_screen(Backup))

      refute drawn?(tree, "records across"),
             "the screen printed a record count at mount. Every count here is meant to " <>
               "be a reading taken when the user asks for one"

      refute labelled?(tree, "Save a file"),
             "the export hand-off is offered before the user has been shown what is in " <>
               "the file — see the moduledoc on why the count comes first"
    end

    test "the restore screen reads nothing at mount either" do
      # `Kati.Screens.Restore` holds `Kati.Backup.SampleRestore`'s stand-in
      # preview at rest — the drawing's own three counts — and reads no file
      # and no table to do it. Everything it says about a real backup arrives
      # with the file.
      assert assigns(mount_screen(Restore)).restore == Restore.blank()
      assert assigns(mount_screen(Restore)).restore.file == nil
      refute drawn?(tree(mount_screen(Restore)), "records across")
    end
  end

  # ── Export ──────────────────────────────────────────────────────────────────

  describe "counting what a backup would hold" do
    test "the total is Kati.Backup.export/0's own manifest, and it is drawn" do
      view = render_info(mount_screen(Backup), {:tap, :count_records})
      preview = assigns(view).backup.preview

      counts = Kati.Backup.export().manifest |> Map.fetch!("record_counts")

      assert preview.total == counts |> Map.values() |> Enum.sum()
      assert preview.tables == map_size(counts)
      assert preview.total > 0, "the database is empty, so nothing below is a real comparison"

      assert drawn?(tree(view), Backup.preview_sub(preview)),
             "the count was read and never reached the tree"
    end

    test "the per-table breakdown lists what is there and counts what is not" do
      view = render_info(mount_screen(Backup), {:tap, :count_records})
      preview = assigns(view).backup.preview
      tree = tree(view)

      {filled, empty} = Enum.split_with(preview.rows, fn {_t, n} -> n > 0 end)

      assert filled != [], "no table holds anything, so the breakdown asserts nothing"

      for {table, count} <- filled do
        assert drawn?(tree, table), "#{table} holds #{count} rows and is not on the screen"
      end

      # THE REFUTATION IS ASKED OF THE PANEL, NOT OF THE PAGE.
      #
      # It used to be asked of the whole tree, and on `128.html` it cannot be:
      # the board's own `What travels with it` card writes `Not your connected
      # calendars` and `Calendar events Kati owns`, which contain the table
      # names `calendars` and `events` as substrings. A page-wide `refute` would
      # now fail on the drawing's copy rather than on a defect. The claim that
      # matters — the breakdown itself does not list a table holding nothing —
      # is exactly as strong when asked of the breakdown.
      panel = Backup.preview_card(preview)

      for {table, _count} <- empty do
        refute drawn?(panel, table),
               "#{table} is empty and is listed by name — twenty-nine zeroes is not a report"
      end
    end

    test "an empty database is a sentence, not fourteen zeroes" do
      # This screen's normal state on a fresh install. `Kati.Backup` will
      # happily write an empty archive and restore it, so "nothing yet" is a
      # fact about the device rather than an error — and a breakdown listing
      # twenty-nine tables at zero would be a report about nothing.
      {preview, tree} =
        in_empty_database(fn ->
          view = render_info(mount_screen(Backup), {:tap, :count_records})
          {assigns(view).backup.preview, tree(view)}
        end)

      assert preview.total == 0
      assert preview.tables == length(Kati.Backup.Catalog.tables())
      assert Enum.all?(preview.rows, fn {_table, n} -> n == 0 end)

      assert drawn?(tree, "Nothing is stored on this device yet")
      assert drawn?(tree, "it would restore, and it would restore nothing")

      # Scoped to the panel for the reason the test above gives.
      panel = Backup.preview_card(preview)

      for {table, _n} <- preview.rows do
        refute drawn?(panel, table), "#{table} is empty and was listed by name anyway"
      end

      # And the file it would write is a real one, with the same total.
      assert Backup.preview_sub(preview) == "0 records across 29 tables"
    end

    test "the columns the format leaves out are named when there are any" do
      # `Kati.Backup.Catalog` drops `calendar_accounts.credentials_ref` — a
      # handle into this phone's keystore that would not open on another one —
      # and the manifest counts the rows that had one. A backup that quietly
      # lost a column would look identical to one that kept it.
      assert Backup.dropped_line(%{}).type == :spacer

      drawn = Backup.dropped_line(%{"calendar_accounts.credentials_ref" => 2})
      assert drawn?(drawn, "calendar_accounts.credentials_ref")
      assert drawn?(drawn, "would not open on another one")
    end

    test "Save and Share appear only once the count has been answered" do
      before = tree(mount_screen(Backup))
      after_count = tree(render_info(mount_screen(Backup), {:tap, :count_records}))

      refute labelled?(before, "Save a file")
      refute labelled?(before, "Share a copy")
      assert labelled?(after_count, "Save a file")
      assert labelled?(after_count, "Share a copy")
    end

    test "Share says in its own words that it is not a backup" do
      # `Kati.Native.Files` is explicit that a completed share cannot be
      # detected on Android and that a settings screen must not offer Share as
      # the way to make a backup. That warning has to survive onto the screen,
      # or the module doc is the only place it exists.
      tree = tree(render_info(mount_screen(Backup), {:tap, :count_records}))

      assert drawn?(tree, "Android cannot confirm it arrived")
    end
  end

  describe "handing the file to the system" do
    test "the file that reaches the transport holds the counts the screen showed" do
      # The property `Kati.Backup.inspect_file/1` exists for, asserted from the
      # screen's end: what was printed is what a restore would find.
      view = render_info(mount_screen(Backup), {:tap, :count_records})
      preview = assigns(view).backup.preview

      view = render_info(view, {:tap, :save_file})
      notice = assigns(view).backup.notice

      # On the host there is no bridge, so `Kati.Backup.Transport` answers
      # `:no_transport` — and, deliberately, leaves the staged file behind with
      # its path in the message. That is the case this asserts, because it is
      # the one where a real file exists to open.
      assert notice.tone == :info
      assert is_binary(notice.meta)
      assert File.regular?(notice.meta), "the transport reported a path with no file at it"

      assert {:ok, inspected} = Kati.Backup.inspect_file(notice.meta)
      assert inspected.total_records == preview.total
      assert map_size(inspected.record_counts) == preview.tables

      assert drawn?(tree(view), notice.body),
             "the engine's own sentence about where the file is was not drawn"
    end

    test "the board's own Save button counts first and goes through the same door" do
      # `128.html` draws one control, `Save a backup`, and it is the only way a
      # person reaches any of this. If it did not run the count, every state
      # asserted above would be reachable from a test and from nowhere else.
      view = render_info(mount_screen(Backup), {:tap, :save_backup})

      assert assigns(view).backup.preview != nil,
             "the board's own button saved without taking the reading it then shows"

      assert assigns(view).backup.notice.tone == :info
      assert File.regular?(assigns(view).backup.notice.meta)
    end

    test "a passphrase switch with an empty field refuses before anything is exported" do
      view =
        mount_screen(Backup)
        |> render_info({:tap, :toggle_encrypt})
        |> render_info({:tap, :count_records})

      assert assigns(view).backup.encrypt?
      assert find(tree(view), :text_field) != nil, "the passphrase field was not drawn"

      view = render_info(view, {:tap, :save_file})
      notice = assigns(view).backup.notice

      assert notice.tone == :refused
      assert notice.body =~ "Nothing has been exported."
      assert drawn?(tree(view), notice.body)
    end

    test "typing into the field is what the export is sealed with" do
      view =
        mount_screen(Backup)
        |> render_info({:tap, :toggle_encrypt})
        |> render_info({:change, :export_passphrase, @passphrase})

      assert assigns(view).backup.passphrase == @passphrase
      assert Backup.passphrase_opts(true, @passphrase) == [passphrase: @passphrase]
      assert Backup.passphrase_opts(false, @passphrase) == []
    end
  end

  # ── Restore ─────────────────────────────────────────────────────────────────
  #
  # MOVED. Every describe block from here to `the controls` drove
  # `Kati.Screens.Backup` when one screen held both halves of #25. `129.html`
  # is the restore board and `Kati.Screens.Restore` is the screen built to it,
  # so the subject moved and the assertions came with it — `assigns.backup`
  # reads `assigns.restore`, and `Backup.group/1`, `stamp/1`, `mode_tag/1`,
  # `restore_opts/1` and `safety_path/0` are that screen's now.

  describe "a picked file is inspected before anything is written (moved to Kati.Screens.Restore)" do
    test "the card draws inspect_file/1's answer and the database is untouched", %{dir: dir} do
      {:ok, staged} = Transport.stage(dir: dir)
      before = table_counts()

      view = pick(mount_screen(Restore), staged.path, staged.filename)
      file = assigns(view).restore.file

      assert {:ok, expected} = Kati.Backup.inspect_file(staged.path)
      assert file.summary == expected
      assert file.summary.unlocked

      tree = tree(view)
      assert drawn?(tree, staged.filename)
      assert drawn?(tree, Restore.stamp(expected.exported_at))
      assert drawn?(tree, Restore.group(expected.total_records) <> " records across")

      assert table_counts() == before,
             "inspecting a backup changed the database. inspect_file/1 exists precisely " <>
               "so a screen can show a file's contents without touching anything"
    end

    test "the picked file's name replaces the drawing's, and the count row with it", %{dir: dir} do
      # `129.html` is drawn mid-preview, so the resting frame carries
      # `Kati.Backup.SampleRestore`'s filename and its three stand-in counts.
      # A real file has to displace both, or the screen would be reporting the
      # mockup's numbers about the user's backup.
      {:ok, staged} = Transport.stage(dir: dir)

      assert drawn?(tree(mount_screen(Restore)), Kati.Backup.SampleRestore.file())

      view = pick(mount_screen(Restore), staged.path, staged.filename)

      refute drawn?(tree(view), Kati.Backup.SampleRestore.file())

      assert Restore.new_count(Restore.count_cards(assigns(view).restore)) ==
               Restore.group(staged.total_records)
    end

    test "a file that is not a Kati backup is refused by name", %{dir: dir} do
      photo = Path.join(dir, "holiday.jpg")
      File.mkdir_p!(dir)
      File.write!(photo, "not a zip")

      view = pick(mount_screen(Restore), photo, "holiday.jpg")
      notice = assigns(view).restore.notice

      assert assigns(view).restore.file == nil
      assert notice.tone == :refused
      assert notice.body =~ "holiday.jpg is not a Kati backup"
      assert drawn?(tree(view), notice.body)
    end

    test "a cancelled picker is not an error" do
      view = render_info(mount_screen(Restore), {:files, :cancelled})
      notice = assigns(view).restore.notice

      assert notice.tone == :info
      assert notice.body =~ "Nothing on this device has changed."
    end
  end

  describe "an encrypted backup (moved to Kati.Screens.Restore)" do
    setup %{dir: dir} do
      {:ok, staged} = Transport.stage(dir: dir, passphrase: @passphrase)
      assert staged.encrypted
      {:ok, staged: staged}
    end

    test "says it is encrypted and shows no count it has not read", %{staged: staged} do
      view = pick(mount_screen(Restore), staged.path, staged.filename)
      summary = assigns(view).restore.file.summary

      refute summary.unlocked
      assert summary.encrypted
      assert summary.record_counts == nil

      tree = tree(view)
      assert drawn?(tree, "Encrypted — Kati cannot read it yet")
      refute drawn?(tree, "records across"), "a count was drawn for a file nobody has opened"
      assert find(tree, :text_field) != nil, "no passphrase field for a locked backup"

      # The count row still shows the drawing's three, because a sealed file
      # has answered no number at all — see `Kati.Screens.Restore.count_cards/1`.
      assert Restore.count_cards(assigns(view).restore) == Kati.Backup.SampleRestore.counts()
    end

    test "a wrong passphrase says exactly what the engine says", %{staged: staged} do
      view =
        mount_screen(Restore)
        |> pick(staged.path, staged.filename)
        |> render_info({:change, :restore_passphrase, "not the passphrase"})
        |> render_info({:tap, :unlock_file})

      notice = assigns(view).restore.notice

      # Word for word, and the words matter: a wrong key and altered bytes fail
      # identically under GCM, and the engine refuses to guess between them.
      # A screen that paraphrased this would be inventing a diagnosis.
      assert {:error, engine} =
               Kati.Backup.inspect_file(staged.path, passphrase: "not the passphrase")

      assert engine.reason == :bad_passphrase
      assert notice.body == engine.message
      assert notice.body =~ "Kati cannot tell those apart, and it will not guess"
      assert drawn?(tree(view), engine.message)

      refute assigns(view).restore.file.summary.unlocked,
             "a failed unlock left the file looking opened"
    end

    test "the right passphrase shows the counts, read out of the file", %{staged: staged} do
      view =
        mount_screen(Restore)
        |> pick(staged.path, staged.filename)
        |> render_info({:change, :restore_passphrase, @passphrase})
        |> render_info({:tap, :unlock_file})

      summary = assigns(view).restore.file.summary

      assert summary.unlocked
      assert summary.total_records == staged.total_records
      assert assigns(view).restore.notice == nil

      tree = tree(view)
      assert drawn?(tree, Restore.group(staged.total_records) <> " records across")
      assert drawn?(tree, "Merge " <> Restore.group(staged.total_records) <> " into this device")
    end
  end

  # ── The three modes ─────────────────────────────────────────────────────────

  describe "choosing a collision mode (moved to Kati.Screens.Restore)" do
    test "the default is the refusal, and all three modes are still the engine's" do
      # WHAT CHANGED, AND WHY.
      #
      # This used to assert that all three modes are drawn as three rows of one
      # card, with `mode_note(:into_empty)`'s paragraph under it. `129.html`
      # refuses that shape in its own caption — *merge takes the single ink
      # button while replace sits below a full-width rule, so they are never
      # two buttons of equal weight* — so three equal rows is exactly the
      # drawing the board rejected, and neither it nor the resting note
      # survives. What survives is the claim underneath: the engine has three
      # modes, the safest is the one a person starts in, and the argument for
      # the mode actually chosen is drawn when it is chosen.
      assert Restore.blank().mode == :into_empty
      assert Restore.modes() == [:into_empty, :merge, :replace]

      for mode <- Restore.modes() do
        {icon, title, sub} = Restore.mode_copy(mode)
        assert is_binary(icon) and is_binary(title) and is_binary(sub)
        assert Restore.mode_for(Restore.mode_tag(mode)) == mode
      end
    end

    test "every row's second line fits the one line a settings row gives it" do
      # `Kati.UI.SettingsList.body/2` pins the secondary line to `max_lines: 1`
      # and every Text in this app carries `TextOverflow.Ellipsis`, so a long
      # sub does not wrap — it is silently cut, on the device only. Screen 24's
      # longest is 38 characters, which is the width a row actually has once the
      # 30pt tile, the 13pt gap and a trailing pill have taken theirs.
      #
      # The paragraphs these screens need live in notes and panels instead,
      # where a Text with no max_lines can wrap.
      #
      # Asked of every state either screen reaches without a file in hand. A
      # picked file's row draws the filename, which is the user's and may be any
      # length — that one is honestly ellipsized and is the only exception.
      #
      # `128.html`'s own three format sentences are the second exception, and
      # they are the drawing's rather than this screen's: *For a spreadsheet or
      # another app — does not restore* is 51 characters because the board says
      # it is, and `133.html` draws that exact clause wrapping in full at 235%
      # because it is the one line a user must not miss. They are exempted by
      # reading `Kati.Backup.Sample.formats/0`, so a fourth row invented here
      # would still be caught.
      drawn_by_the_board = Enum.map(Sample.formats(), & &1.sub)

      states = [
        mount_screen(Backup),
        render_info(mount_screen(Backup), {:tap, :count_records}),
        render_info(mount_screen(Backup), {:tap, :toggle_encrypt}),
        mount_screen(Restore),
        render_info(mount_screen(Restore), {:tap, :mode_merge}),
        render_info(mount_screen(Restore), {:tap, :mode_replace})
      ]

      long =
        for view <- states,
            row <- rows_of(tree(view)),
            row not in drawn_by_the_board,
            String.length(row) > 38,
            do: "  #{String.length(row)}: #{row}"

      assert long == [],
             "these row lines are longer than a settings row can draw, so the device " <>
               "would ellipsize them:\n" <> Enum.join(long, "\n")
    end

    test "the chosen mode carries no tap, and the ones that are a change do" do
      # `Kati.Screens.Settings.segment/2`'s invariant, on the shape `129.html`
      # actually draws: the tags a screen draws are the choices it can still
      # make. `:into_empty` is the mode already chosen, so nothing on the
      # resting frame sets it; Replace is a change, so the outlined red row
      # carries its tag. Merge is offered where it becomes a change — on the
      # refusal notice — which the describe below drives.
      tags = tap_tags(tree(mount_screen(Restore)))

      assert :choose_file in tags, "the file row is drawn and picks nothing"
      assert :restore_now in tags, "the ink button is drawn and commits nothing"
      assert Restore.mode_tag(:replace) in tags
      refute Restore.mode_tag(:into_empty) in tags
    end

    test "picking merge moves the mode and draws the argument for it" do
      view = render_info(mount_screen(Restore), {:tap, :mode_merge})

      assert assigns(view).restore.mode == :merge

      assert drawn?(tree(view), "A row whose id is already on this device is skipped"),
             "the chosen mode changed and the screen said nothing about what it means"

      # And the safest mode is still reachable from here: nothing has been
      # written, so choosing again costs nothing.
      back = render_info(view, {:tap, :mode_replace})
      assert assigns(back).restore.mode == :replace
    end

    test "replace names the safety export before it is needed" do
      view = render_info(mount_screen(Restore), {:tap, :mode_replace})

      assert assigns(view).restore.mode == :replace

      # The filename on the screen, the whole path in the option the engine is
      # given: a settings page is not the place for an absolute path, and
      # `restore_opts/1` is where the precondition is actually satisfied.
      assert drawn?(tree(view), Path.basename(Restore.safety_path()))
      assert drawn?(tree(view), "if that copy cannot be written, nothing is deleted")

      assert Restore.restore_opts(assigns(view).restore)[:safety_export_path] ==
               Restore.safety_path()
    end

    test "the safety copy is not written where the staging sweep would delete it" do
      # `Transport.sweep/1` deletes anything in the staging directory older than
      # an hour, which is right for a file the user is in the middle of saving
      # and catastrophic for the only remaining copy of replaced data.
      refute String.starts_with?(Restore.safety_path(), Transport.staging_dir())
      assert String.ends_with?(Restore.safety_path(), Kati.Backup.extension())
    end

    test "the other two modes ask for no safety export" do
      for mode <- [:into_empty, :merge] do
        opts = Restore.restore_opts(%{Restore.blank() | mode: mode, unlock: ""})
        assert opts[:mode] == mode
        assert opts[:safety_export_path] == nil
      end
    end
  end

  # ── The refusal ─────────────────────────────────────────────────────────────

  describe "restoring into a Kati that already has data (moved to Kati.Screens.Restore)" do
    test "the default mode refuses, names what it found, and offers the other two", %{dir: dir} do
      {:ok, staged} = Transport.stage(dir: dir)
      before = table_counts()

      view =
        mount_screen(Restore)
        |> pick(staged.path, staged.filename)
        |> render_info({:tap, :restore_now})

      notice = assigns(view).restore.notice

      assert notice.tone == :refused,
             "the safest outcome this screen has was painted as a failure"

      assert notice.title == "Nothing has been changed"

      # The engine's sentence, unedited, including the counts it found.
      assert {:error, engine} = Kati.Backup.restore_file(staged.path, mode: :into_empty)
      assert engine.reason == :not_empty
      assert notice.body == engine.message
      assert notice.body =~ "Kati already has data on this device"
      assert notice.body =~ "Nothing has been changed."

      assert notice.actions == [
               {"Merge instead", :mode_merge},
               {"Replace instead", :mode_replace}
             ]

      tree = tree(view)
      assert drawn?(tree, engine.message)
      assert drawn?(tree, "Merge instead")
      assert drawn?(tree, "Replace instead")

      assert table_counts() == before, "a refused restore wrote to the database"
    end

    test "the offered alternative is the same tag the mode rows use", %{dir: dir} do
      {:ok, staged} = Transport.stage(dir: dir)

      view =
        mount_screen(Restore)
        |> pick(staged.path, staged.filename)
        |> render_info({:tap, :restore_now})
        |> render_info({:tap, :mode_merge})

      assert assigns(view).restore.mode == :merge
    end

    test "merge inserts nothing it already has, and says so", %{dir: dir} do
      # A backup of this same database restored back into it: every row collides
      # on its own id, so the whole file is skipped and not one row is written.
      # That is what makes this safe to run against the suite's shared fixtures,
      # and it is also the exact property `:merge` promises.
      {:ok, staged} = Transport.stage(dir: dir)
      before = table_counts()

      view =
        mount_screen(Restore)
        |> pick(staged.path, staged.filename)
        |> render_info({:tap, :mode_merge})
        |> render_info({:tap, :restore_now})

      notice = assigns(view).restore.notice

      assert notice.tone == :ok
      assert notice.title == "Restored"
      assert notice.body =~ "Nothing existing was overwritten."
      assert drawn?(tree(view), notice.body)

      assert table_counts() == before,
             "restoring a backup of this database into itself changed a row count"
    end

    test "the ink button with no file picked refuses rather than doing nothing" do
      # The resting frame draws that button, and the name above the picker is
      # the drawing's rather than a file on the device. A button that answered
      # a tap with silence would be indistinguishable from a dead one.
      view = render_info(mount_screen(Restore), {:tap, :restore_now})
      notice = assigns(view).restore.notice

      assert notice.tone == :refused
      assert notice.title == "There is no file to restore"
      assert drawn?(tree(view), notice.body)
    end
  end

  # ── Every control the resting frame draws ───────────────────────────────────

  describe "the controls" do
    test "every tap the resting frame draws is answered and changes the screen" do
      # A local, scoped copy of `Kati.ScreenTapSweepTest`'s two questions. The
      # sweep asks them of every screen and is the real guard; this one fails
      # inside the file that owns these two, which is where the fix goes.
      for screen <- [Backup, Restore] do
        view = mount_screen(screen)
        sentinel = :__screen_backup_test_unhandled__
        {:noreply, base} = screen.handle_tap(sentinel, view.socket)

        for tag <- tap_tags(tree(view)), tag != :back do
          assert {:noreply, %Mob.Socket{} = after_tap} = screen.handle_tap(tag, view.socket)

          refute after_tap.assigns == base.assigns,
                 "#{inspect(screen)} draws #{inspect(tag)} and leaves the screen exactly " <>
                   "as a tag no control draws would have. Wire it or stop drawing it"
        end
      end
    end

    test "the dismiss control clears the notice it is drawn beside" do
      # One notice apiece, each raised down the door its own screen listens on:
      # the export screen hears `{:kati_files, …}` from a Save As it opened, the
      # restore screen hears `{:files, …}` from the document picker.
      for {screen, key, message} <- [
            {Backup, :backup, {:kati_files, :cancelled}},
            {Restore, :restore, {:files, :cancelled}}
          ] do
        view = render_info(mount_screen(screen), message)
        assert Map.fetch!(assigns(view), key).notice != nil
        assert :dismiss_notice in tap_tags(tree(view))

        view = render_info(view, {:tap, :dismiss_notice})
        assert Map.fetch!(assigns(view), key).notice == nil
      end
    end

    test "the back pill still works, so the handle_info override kept super/2" do
      # Overriding `handle_info/2` replaces every clause the `Kati.Screens.Pushed`
      # macro wrote, `:back` included. Forgetting `super/2` would leave a screen
      # you cannot leave, and nothing else in the suite asks these two.
      for screen <- [Backup, Restore] do
        view = render_info(mount_screen(screen), {:tap, :back})
        assert navigated_to(view) == {:pop}
      end
    end

    test "a backup with no readable timestamp says so rather than printing a blank" do
      # Moved with the file card it stamps: the timestamp being read is the one
      # inside a picked backup, which is `Kati.Screens.Restore`'s subject now.
      assert Restore.stamp(nil) == "at an unrecorded time"
      assert Restore.stamp(~U[2026-08-21 14:32:07Z]) =~ "August 2026"
    end

    test "an unrelated message is ignored rather than matched by accident" do
      for screen <- [Backup, Restore] do
        view = mount_screen(screen)
        assert screen.event({:tick, 1}) == :ignore
        assert render_info(view, {:tick, 1}).socket.assigns == view.socket.assigns
      end
    end

    test "the safety copy reaching the system does not stamp the backup ledger" do
      # `Kati.Screens.Settings`' moduledoc names `Kati.Screens.Backup`'s
      # `{:saved, …}` branch as the ONLY writer of `Last backup`, and the
      # restore screen now hears the identical message when the pre-replace
      # copy is handed out. A date written from there would promise a backup to
      # someone who never asked for one.
      Mob.State.delete(:last_backup_at)

      view =
        render_info(
          mount_screen(Restore),
          {:kati_files, :saved,
           [%{path: "/tmp/before.katibackup", name: "before.katibackup", bytes: 8736, uri: "x"}]}
        )

      assert assigns(view).restore.notice.tone == :ok
      assert Kati.Screens.Settings.last_backup() == nil
    end
  end

  describe "the status card once a backup exists" do
    # Board 128 draws the card in its *has-been-backed-up* state: `cloud_done`,
    # `14 Aug`, `2 WEEKS AGO · 214 MB`. No other test in this app can reach that
    # state — `Mob.State` is empty everywhere, so every render takes
    # `status_frame(false, nil)` and draws `Never` / `cloud_off`, which the
    # moduledoc argues at length is the correct resting state for a fresh
    # install and not a bug to be papered over.
    #
    # The consequence is that three of the drawing's items are exempted in both
    # `Kati.ScreenDesignLiteralTest` and `Kati.ScreenEmptyDatabaseTest`. Those
    # exemptions are only honest if the branch is asserted somewhere, and this
    # is that somewhere: seed the ledger, render the real screen, and read the
    # card off the tree.
    test "a seeded ledger draws cloud_done, the date and the size" do
      at = DateTime.add(Kati.Time.now(), -14, :day)
      Mob.State.put(:last_backup_at, at)
      Mob.State.put(:last_backup_bytes, 214_000_000)

      tree = tree(mount_screen(Backup))

      assert drawn?(tree, Kati.Icons.glyph("cloud_done")),
             "the card is in its backed-up state and still drew no cloud_done"

      refute drawn?(tree, Kati.Icons.glyph("cloud_off")),
             "both branches of the status icon were drawn at once"

      assert drawn?(tree, Backup.date_text(at)),
             "the value line did not carry the ledger's own date"

      assert drawn?(tree, "2 WEEKS AGO · 214 MB"),
             "the caption did not carry the age and the size the board draws"

      refute drawn?(tree, "Never"),
             "a Kati that has been backed up still said it never had"
    end

    test "no byte ledger drops the size rather than printing a blank one" do
      # `caption/1`'s two branches. A backup made before the byte ledger
      # existed has a date and no size, and the separator must go with it.
      at = DateTime.add(Kati.Time.now(), -14, :day)
      Mob.State.put(:last_backup_at, at)

      assert Backup.caption(at) == "2 WEEKS AGO"
      refute Backup.caption(at) =~ "·"
    end
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  # Whether `needle` is inside any string this tree draws. Substring rather than
  # equality because most of the copy asserted here is a sentence the engine
  # built and the screen concatenated into a paragraph.
  defp labelled?(tree, label), do: find(tree, :text, text: label) != nil

  # Every string drawn by a node that `Kati.UI.SettingsList` pins to one line:
  # a row's title at 13.5 and its second line at 11.5.
  defp rows_of(tree) do
    tree
    |> flatten()
    |> Enum.filter(fn node ->
      node.type == :text and Map.get(node.props, :max_lines) == 1 and
        Map.get(node.props, :text_size) in [13.5, 11.5]
    end)
    |> Enum.map(& &1.props.text)
  end

  defp drawn?(tree, needle) do
    tree
    |> flatten()
    |> Enum.flat_map(fn node -> node.props |> Map.values() |> Enum.filter(&is_binary/1) end)
    |> Enum.any?(&String.contains?(&1, needle))
  end

  # Every `on_tap` tag the tree carries. `nil` means "not tappable" and is the
  # one thing a control can hold that this must not collect — the mode a screen
  # is already in carries exactly that.
  defp tap_tags(tree) do
    tree
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{on_tap: {pid, tag}} when is_pid(pid) and is_atom(tag) -> [tag]
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  defp pick(view, path, name) do
    render_info(view, {:files, :picked, [%{name: name, path: path}]})
  end

  defp resource_tables do
    %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'")

    rows
    |> List.flatten()
    |> Enum.reject(&String.starts_with?(&1, "sqlite_"))
    |> Enum.reject(&(&1 in @not_resources))
    |> Enum.sort()
  end

  defp table_counts do
    Map.new(resource_tables(), fn table ->
      %{rows: [[n]]} = Kati.Repo.query!("SELECT count(*) FROM #{table}")
      {table, n}
    end)
  end

  # Runs `fun` with every table emptied, and always rolls back. Same shape as
  # `Kati.ScreenSampleOnlyTest`'s: `defer_foreign_keys` moves constraint
  # checking to the COMMIT that never comes, so the deletes can run in whatever
  # order `sqlite_master` hands the tables back.
  defp in_empty_database(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Kati.Repo.query!("PRAGMA defer_foreign_keys = ON")
        Enum.each(resource_tables(), &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end
end
