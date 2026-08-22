defmodule Kati.ScreenBackupTest do
  @moduledoc """
  `Kati.Screens.Backup` against the engine it exists to reach.

  ## What this file is for

  `Kati.Backup` was finished and proven on the device before any screen called
  it, so the risk here is **not** that the engine is wrong. It is that the
  screen and the engine disagree: a count printed from one query and a file
  written from another, a refusal shown as a failure, a passphrase field wired
  to nothing, a restore offered before the file has been read. Every assertion
  below therefore compares what the screen *drew* against what the engine
  *answered*, on real files with real bytes — never against a call returning
  `:ok`, which is the same standard `Kati.BackupTransportTest` holds itself to
  and for the same reason: a zero-byte backup satisfies `:ok`.

  ## Why the sweeps do not cover this

  `Kati.ScreenRenderSweepTest` mounts the screen and asserts one root node;
  `Kati.ScreenTapSweepTest` taps what the resting frame drew and asserts
  something changed. Neither reads the copy, and **neither goes past the
  resting frame** — `ScreenSweep.drawn_taps/1` renders once, at mount, so every
  control that only exists once a file has been picked (Unlock, Restore, the
  safety note) is invisible to it. This file drives those states.

  `Kati.ScreenDesignLiteralTest` cannot cover it at all: there is no drawing.
  See `Kati.Screens.Backup`'s own moduledoc, and `@undesigned` in that file.

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

  alias Kati.Backup.Transport
  alias Kati.Screens.Backup

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
      # The claim `Kati.Screens.Backup`'s moduledoc makes, and the one
      # `Kati.ScreenEmptyDatabaseTest` cannot make for it because that file is
      # keyed by design number and this screen has no drawing. Byte-for-byte
      # equality is the strongest available form of "an empty database renders":
      # not merely that it does not crash, but that it draws the identical tree.
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
      for locale <- [:en, :fa] do
        previous = Kati.Locale.current()
        Kati.Locale.put(locale)
        assert_renderable(mount_screen(Backup))
        Kati.Locale.put(previous)
      end
    end

    test "no number is drawn before one has been read" do
      tree = tree(mount_screen(Backup))

      refute drawn?(tree, "records across"),
             "the screen printed a record count at mount. Every count here is meant to " <>
               "be a reading taken when the user asks for one"

      refute labelled?(tree, "Save a file"),
             "Save is offered before the user has been shown what is in the file — see " <>
               "the moduledoc on why the count comes first"
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

      for {table, _count} <- empty do
        refute drawn?(tree, table),
               "#{table} is empty and is listed by name — fourteen zeroes is not a report"
      end
    end

    test "an empty database is a sentence, not fourteen zeroes" do
      # This screen's normal state on a fresh install. `Kati.Backup` will
      # happily write an empty archive and restore it, so "nothing yet" is a
      # fact about the device rather than an error — and a breakdown listing
      # fourteen tables at zero would be a report about nothing.
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

      for {table, _n} <- preview.rows do
        refute drawn?(tree, table), "#{table} is empty and was listed by name anyway"
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

  describe "a picked file is inspected before anything is written" do
    test "the card draws inspect_file/1's answer and the database is untouched", %{dir: dir} do
      {:ok, staged} = Transport.stage(dir: dir)
      before = table_counts()

      view = pick(mount_screen(Backup), staged.path, staged.filename)
      file = assigns(view).backup.file

      assert {:ok, expected} = Kati.Backup.inspect_file(staged.path)
      assert file.summary == expected
      assert file.summary.unlocked

      tree = tree(view)
      assert drawn?(tree, staged.filename)
      assert drawn?(tree, Backup.stamp(expected.exported_at))
      assert drawn?(tree, Backup.group(expected.total_records) <> " records across")

      assert table_counts() == before,
             "inspecting a backup changed the database. inspect_file/1 exists precisely " <>
               "so a screen can show a file's contents without touching anything"
    end

    test "a file that is not a Kati backup is refused by name", %{dir: dir} do
      photo = Path.join(dir, "holiday.jpg")
      File.mkdir_p!(dir)
      File.write!(photo, "not a zip")

      view = pick(mount_screen(Backup), photo, "holiday.jpg")
      notice = assigns(view).backup.notice

      assert assigns(view).backup.file == nil
      assert notice.tone == :refused
      assert notice.body =~ "holiday.jpg is not a Kati backup"
      assert drawn?(tree(view), notice.body)
    end

    test "a cancelled picker is not an error" do
      view = render_info(mount_screen(Backup), {:files, :cancelled})
      notice = assigns(view).backup.notice

      assert notice.tone == :info
      assert notice.body =~ "Nothing on this device has changed."
    end
  end

  describe "an encrypted backup" do
    setup %{dir: dir} do
      {:ok, staged} = Transport.stage(dir: dir, passphrase: @passphrase)
      assert staged.encrypted
      {:ok, staged: staged}
    end

    test "says it is encrypted and shows no count it has not read", %{staged: staged} do
      view = pick(mount_screen(Backup), staged.path, staged.filename)
      summary = assigns(view).backup.file.summary

      refute summary.unlocked
      assert summary.encrypted
      assert summary.record_counts == nil

      tree = tree(view)
      assert drawn?(tree, "Encrypted — Kati cannot read it yet")
      refute drawn?(tree, "records across"), "a count was drawn for a file nobody has opened"
      assert find(tree, :text_field) != nil, "no passphrase field for a locked backup"

      refute labelled?(tree, "Restore this backup"),
             "a restore was offered for a file that has not been verified"
    end

    test "a wrong passphrase says exactly what the engine says", %{staged: staged} do
      view =
        mount_screen(Backup)
        |> pick(staged.path, staged.filename)
        |> render_info({:change, :restore_passphrase, "not the passphrase"})
        |> render_info({:tap, :unlock_file})

      notice = assigns(view).backup.notice

      # Word for word, and the words matter: a wrong key and altered bytes fail
      # identically under GCM, and the engine refuses to guess between them.
      # A screen that paraphrased this would be inventing a diagnosis.
      assert {:error, engine} =
               Kati.Backup.inspect_file(staged.path, passphrase: "not the passphrase")

      assert engine.reason == :bad_passphrase
      assert notice.body == engine.message
      assert notice.body =~ "Kati cannot tell those apart, and it will not guess"
      assert drawn?(tree(view), engine.message)

      refute assigns(view).backup.file.summary.unlocked,
             "a failed unlock left the file looking opened"
    end

    test "the right passphrase shows the counts, read out of the file", %{staged: staged} do
      view =
        mount_screen(Backup)
        |> pick(staged.path, staged.filename)
        |> render_info({:change, :restore_passphrase, @passphrase})
        |> render_info({:tap, :unlock_file})

      summary = assigns(view).backup.file.summary

      assert summary.unlocked
      assert summary.total_records == staged.total_records
      assert assigns(view).backup.notice == nil

      tree = tree(view)
      assert drawn?(tree, Backup.group(staged.total_records) <> " records across")
      assert labelled?(tree, "Restore this backup")
    end
  end

  # ── The three modes ─────────────────────────────────────────────────────────

  describe "choosing a collision mode" do
    test "the default is the refusal, and it is drawn as one of three choices" do
      tree = tree(mount_screen(Backup))

      assert Backup.blank().mode == :into_empty

      for mode <- Backup.modes() do
        {_icon, title, _sub} = Backup.mode_copy(mode)
        assert labelled?(tree, title), "#{inspect(mode)} is not offered on the screen"
      end

      assert drawn?(tree, "It is the default because it is the only one with no way to go wrong")
    end

    test "every row's second line fits the one line a settings row gives it" do
      # `Kati.UI.SettingsList.body/2` pins the secondary line to `max_lines: 1`
      # and every Text in this app carries `TextOverflow.Ellipsis`, so a long
      # sub does not wrap — it is silently cut, on the device only. Screen 24's
      # longest is 38 characters, which is the width a row actually has once the
      # 30pt tile, the 13pt gap and a trailing pill have taken theirs.
      #
      # The paragraphs this screen needs live in notes and panels instead, where
      # a Text with no max_lines can wrap. See `mode_note/1`.
      # Asked of every state the screen reaches without a file in hand. A picked
      # file's row draws the filename, which is the user's and may be any
      # length — that one is honestly ellipsized and is the only exception.
      states = [
        mount_screen(Backup),
        render_info(mount_screen(Backup), {:tap, :count_records}),
        render_info(mount_screen(Backup), {:tap, :toggle_encrypt}),
        render_info(mount_screen(Backup), {:tap, :mode_merge}),
        render_info(mount_screen(Backup), {:tap, :mode_replace})
      ]

      long =
        for view <- states,
            row <- rows_of(tree(view)),
            String.length(row) > 38,
            do: "  #{String.length(row)}: #{row}"

      assert long == [],
             "these row lines are longer than a settings row can draw, so the device " <>
               "would ellipsize them:\n" <> Enum.join(long, "\n")
    end

    test "the chosen mode carries no tap, and the other two do" do
      # `Kati.Screens.Settings.segment/2`'s invariant: the tags a screen draws
      # are the choices it can still make. Without it, "tapping the chosen row
      # changes nothing" and "this control is dead" are the same observation.
      tags = tap_tags(tree(mount_screen(Backup)))

      refute Backup.mode_tag(:into_empty) in tags
      assert Backup.mode_tag(:merge) in tags
      assert Backup.mode_tag(:replace) in tags
    end

    test "picking merge moves the mark and frees the tag it came from" do
      view = render_info(mount_screen(Backup), {:tap, :mode_merge})
      tags = tap_tags(tree(view))

      assert assigns(view).backup.mode == :merge
      assert Backup.mode_tag(:into_empty) in tags
      refute Backup.mode_tag(:merge) in tags
    end

    test "replace names the safety export before it is needed" do
      view = render_info(mount_screen(Backup), {:tap, :mode_replace})

      assert assigns(view).backup.mode == :replace

      # The filename on the screen, the whole path in the option the engine is
      # given: a settings page is not the place for an absolute path, and
      # `restore_opts/1` is where the precondition is actually satisfied.
      assert drawn?(tree(view), Path.basename(Backup.safety_path()))
      assert drawn?(tree(view), "if that copy cannot be written, nothing is deleted")

      assert Backup.restore_opts(assigns(view).backup)[:safety_export_path] ==
               Backup.safety_path()
    end

    test "the safety copy is not written where the staging sweep would delete it" do
      # `Transport.sweep/1` deletes anything in the staging directory older than
      # an hour, which is right for a file the user is in the middle of saving
      # and catastrophic for the only remaining copy of replaced data.
      refute String.starts_with?(Backup.safety_path(), Transport.staging_dir())
      assert String.ends_with?(Backup.safety_path(), Kati.Backup.extension())
    end

    test "the other two modes ask for no safety export" do
      for mode <- [:into_empty, :merge] do
        opts = Backup.restore_opts(%{Backup.blank() | mode: mode, unlock: ""})
        assert opts[:mode] == mode
        assert opts[:safety_export_path] == nil
      end
    end
  end

  # ── The refusal ─────────────────────────────────────────────────────────────

  describe "restoring into a Kati that already has data" do
    test "the default mode refuses, names what it found, and offers the other two", %{dir: dir} do
      {:ok, staged} = Transport.stage(dir: dir)
      before = table_counts()

      view =
        mount_screen(Backup)
        |> pick(staged.path, staged.filename)
        |> render_info({:tap, :restore_now})

      notice = assigns(view).backup.notice

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
        mount_screen(Backup)
        |> pick(staged.path, staged.filename)
        |> render_info({:tap, :restore_now})
        |> render_info({:tap, :mode_merge})

      assert assigns(view).backup.mode == :merge
    end

    test "merge inserts nothing it already has, and says so", %{dir: dir} do
      # A backup of this same database restored back into it: every row collides
      # on its own id, so the whole file is skipped and not one row is written.
      # That is what makes this safe to run against the suite's shared fixtures,
      # and it is also the exact property `:merge` promises.
      {:ok, staged} = Transport.stage(dir: dir)
      before = table_counts()

      view =
        mount_screen(Backup)
        |> pick(staged.path, staged.filename)
        |> render_info({:tap, :mode_merge})
        |> render_info({:tap, :restore_now})

      notice = assigns(view).backup.notice

      assert notice.tone == :ok
      assert notice.title == "Restored"
      assert notice.body =~ "Nothing existing was overwritten."
      assert drawn?(tree(view), notice.body)

      assert table_counts() == before,
             "restoring a backup of this database into itself changed a row count"
    end
  end

  # ── Every control the resting frame draws ───────────────────────────────────

  describe "the controls" do
    test "every tap the resting frame draws is answered and changes the screen" do
      # A local, scoped copy of `Kati.ScreenTapSweepTest`'s two questions. The
      # sweep asks them of every screen and is the real guard; this one fails
      # inside the file that owns the screen, which is where the fix goes.
      view = mount_screen(Backup)
      sentinel = :__screen_backup_test_unhandled__
      {:noreply, base} = Backup.handle_tap(sentinel, view.socket)

      for tag <- tap_tags(tree(view)), tag != :back do
        assert {:noreply, %Mob.Socket{} = after_tap} = Backup.handle_tap(tag, view.socket)

        refute after_tap.assigns == base.assigns,
               "#{inspect(tag)} is drawn and leaves the screen exactly as a tag no " <>
                 "control draws would have. Wire it or stop drawing it"
      end
    end

    test "the dismiss control clears the notice it is drawn beside" do
      view = render_info(mount_screen(Backup), {:files, :cancelled})
      assert assigns(view).backup.notice != nil
      assert :dismiss_notice in tap_tags(tree(view))

      view = render_info(view, {:tap, :dismiss_notice})
      assert assigns(view).backup.notice == nil
    end

    test "the back pill still works, so the handle_info override kept super/2" do
      # Overriding `handle_info/2` replaces every clause the `Kati.Screens.Pushed`
      # macro wrote, `:back` included. Forgetting `super/2` would leave a screen
      # you cannot leave, and nothing else in the suite asks this screen.
      view = render_info(mount_screen(Backup), {:tap, :back})
      assert navigated_to(view) == {:pop}
    end

    test "a backup with no readable timestamp says so rather than printing a blank" do
      assert Backup.stamp(nil) == "at an unrecorded time"
      assert Backup.stamp(~U[2026-08-21 14:32:07Z]) =~ "August 2026"
    end

    test "an unrelated message is ignored rather than matched by accident" do
      view = mount_screen(Backup)
      assert Backup.event({:tick, 1}) == :ignore
      assert render_info(view, {:tick, 1}).socket.assigns == view.socket.assigns
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
  # one thing a control can hold that this must not collect — the chosen mode
  # row carries exactly that.
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
