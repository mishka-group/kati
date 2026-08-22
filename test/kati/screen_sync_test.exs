Code.require_file("../support/sync_schema.exs", __DIR__)
Code.require_file("../support/sync_fixtures.exs", __DIR__)

defmodule Kati.ScreenSyncTest do
  @moduledoc """
  `Kati.Screens.Sync` against the engine it exists to make visible.

  ## Why this file has to carry more than a screen test usually does

  Every other screen in this app is checked twice over by the sweeps: the
  render sweep mounts it, the tap sweep taps it, and
  `Kati.ScreenDesignLiteralTest` compares every word it draws with the frame
  under `.scratch/design/screens/`. That third check does not exist here —
  there is no frame, `Kati.Screens.Sync` is in `@undesigned`, and issue #25 has
  been asking for the drawing since before the engine landed. Nothing else in
  the suite reads this screen's copy.

  So the copy is read here, and it is read as **claims about the store** rather
  than as strings: a row that says "1 change waiting" is asserted beside an
  outbox holding one entry, and a row that says a change is blocked is asserted
  beside an entry `Kati.Sync.Outbox.fail/3` actually blocked. A page about a
  queue that is confidently wrong about the queue is worse than no page.

  ## The four things a run has to settle

    * **The empty page.** A device with no account, no queued change and no
      conflict is the *ordinary* state of this screen, not an edge case, and it
      is the state a fresh install opens in. All four groups have to draw
      something a person can read.
    * **Retry is offered exactly where it works.** `Kati.Sync.Outbox.fail/3`
      parks `:reauth` and `:conflict` in `:blocked` *"because trying again
      cannot fix either of them"*. A Retry button on one of those is a control
      that reliably does nothing, which is the whole defect
      `Kati.ScreenTapSweepTest` was written to end — and that sweep cannot see
      it, because the tap *is* answered, it just cannot help.
    * **The three questions are told apart.** `Kati.Sync.conflicts/1` answers
      with events, not verdicts, so the screen recovers the reason from what
      the engine already wrote. Each of the three is built here the way the
      engine builds it and the question is read back.
    * **Nothing is discarded, and the screen can prove it.** Resolving keeps
      the loser; re-applying goes back through `Kati.Sync.edit/3` and lands in
      the outbox rather than clobbering a row.

  ## The wipe in `setup`

  The suite shares one SQLite file — `test/test_helper.exs` migrates one
  database and there is no Ecto sandbox — so "nothing stored" has to be made
  rather than assumed, and what this module writes is not inert: a leftover
  calendar is a fifth row on screen 32, and a leftover outbox entry is a row on
  this one. Same `on_exit`, and the same reasoning, as
  `Kati.ScreenCalendarsTest` and `Kati.SeedsTest`.
  """
  use Mob.ScreenCase, async: false

  import Kati.SyncFixtures

  alias Kati.Calendars.Account
  alias Kati.Calendars.Event
  alias Kati.Screens.Sync, as: Screen
  alias Kati.Sync.Merge
  alias Kati.Sync.Outbox
  alias Kati.Sync.OutboxEntry
  alias Kati.Sync.RejectedChange

  require Ash.Query

  # Child tables first: overrides and events carry the foreign keys, and the two
  # sync tables reference a calendar by a plain column that no cascade covers.
  @tables ~w(
    sync_outbox sync_rejected_changes
    event_occurrence_overrides events calendars calendar_accounts
  )

  setup_all do
    Kati.SyncSchema.ensure!()
    :ok
  end

  setup do
    empty!()
    on_exit(&empty!/0)
    :ok
  end

  defp empty! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  # ── Reading the rendered page ───────────────────────────────────────────────

  defp texts(tree), do: tree |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  # Substring rather than equality: every line on this page is assembled from a
  # calendar's own name and a count, so the assertion has to be about the claim
  # and not about the punctuation around it.
  defp says?(tree, needle), do: Enum.any?(texts(tree), &String.contains?(&1, needle))

  defp tags(tree) do
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

  defp page, do: mount_screen(Screen)

  defp entry!, do: OutboxEntry |> Ash.read!() |> List.first()
  defp entries, do: OutboxEntry |> Ash.Query.sort(inserted_at: :asc) |> Ash.read!()
  defp rejections, do: Ash.read!(RejectedChange)

  # A remote calendar with a name the assertions can name back, and a policy
  # that lets Kati's own events out.
  defp work! do
    account =
      Account
      |> Ash.Changeset.for_create(:create, %{
        provider: :caldav,
        display_name: "Fastmail",
        state: :live,
        last_sync_at: DateTime.utc_now()
      })
      |> Ash.create!()

    calendar =
      calendar!(%{
        display_name: "Work",
        kind: :provider,
        account_id: account.id,
        remote_id: unique("remote-cal"),
        writeback_policy: :kati_only,
        last_sync_at: DateTime.utc_now()
      })

    {account, calendar}
  end

  # ── The ordinary state: nothing stored ─────────────────────────────────────

  describe "with nothing stored, which is this screen's normal state" do
    test "all four groups draw a row rather than vanishing" do
      t = tree(page())

      assert says?(t, "No account is connected")
      assert says?(t, "No calendar is connected")
      assert says?(t, "Nothing is waiting")
      assert says?(t, "Nothing is waiting on you")
      assert says?(t, "Nothing has been set aside")
    end

    test "the reads answer empty, so it is the empty state that drew" do
      # Both halves, for `Kati.ScreenEmptyDatabaseTest`'s reason: the copy
      # above is satisfied by presence anywhere in the tree, and only the
      # screen's own entry point can say the page got there by reading nothing.
      state = Screen.state()

      assert state.calendars == []
      assert state.accounts == []
      assert state.outbox == []
      assert state.conflicts == []
      assert state.rejected == []
      assert state.waiting == 0
      assert state.stuck == 0
    end

    test "the subtitle says what an empty device actually is" do
      assert Screen.subtitle(Screen.state()) ==
               "NO CALENDAR CONNECTED · NOTHING LEAVES THIS DEVICE"
    end

    test "the only tappable thing is the back pill" do
      # Not decoration. Every control this page draws acts on a row, so a page
      # with no rows must draw no controls — a Retry or a Keep mine with
      # nothing behind it would be answered by `handle_tap/2` and do nothing,
      # which is precisely the shape `Kati.ScreenTapSweepTest` cannot see.
      assert tags(tree(page())) == [:back]
    end

    test "the page is renderable and is a page, not chrome" do
      t = tree(page())
      assert_renderable(t)
      assert length(texts(t)) > 12
    end

    test "the asymmetry is stated on the page itself" do
      # `Kati.Sync`'s moduledoc says ownership is not symmetric. A screen that
      # laid the two sides out as equals would deny that in the only place a
      # user can read.
      t = tree(page())
      assert says?(t, "This device holds the original")
      assert says?(t, "cannot lock")
      assert says?(t, "Kati sends only the events it created")
    end
  end

  # ── Status ──────────────────────────────────────────────────────────────────

  describe "status, per account and per calendar" do
    test "an account draws its own state, its calendar count and when it last ran" do
      {_account, _calendar} = work!()
      t = tree(page())

      assert says?(t, "Fastmail")
      assert says?(t, "1 calendar · last checked just now")
      assert says?(t, "Live")
    end

    test "a calendar with a queued change says how many and shows Waiting" do
      {_account, calendar} = work!()
      event = event!(calendar, %{summary: "Standup"})
      {:ok, _} = Kati.Sync.edit(event, calendar, %{summary: "Standup, moved"})

      t = tree(page())

      assert says?(t, "Work")
      assert says?(t, "1 change waiting")
      assert says?(t, "Waiting")
    end

    test "a calendar with nothing queued says so and shows Clear" do
      {_account, _calendar} = work!()
      t = tree(page())

      assert says?(t, "nothing waiting · last sent just now")
      assert says?(t, "Clear")
    end

    test "a local calendar says out loud that nothing is ever sent" do
      calendar!(%{display_name: "Habits", kind: :local})
      t = tree(page())

      assert says?(t, "local calendar, nothing is ever sent")
      assert says?(t, "On device")
    end

    test "a calendar with write-back off says where changes stay" do
      {_account, _} = work!()
      calendar!(%{display_name: "Team", kind: :provider, writeback_policy: :none})

      t = tree(page())
      assert says?(t, "write-back is off, so changes stay on this device")
      assert says?(t, "Read only")
    end

    test "the counts come from Kati.Sync.status/1 rather than from a second query" do
      {_account, calendar} = work!()
      event = event!(calendar, %{summary: "Standup"})
      {:ok, _} = Kati.Sync.edit(event, calendar, %{summary: "Moved"})

      [model] = Screen.state().calendars
      status = Kati.Sync.status(calendar.id)

      assert model.pending == status.pending
      assert model.blocked == status.blocked
      assert model.failed == status.failed
    end
  end

  # ── The outbox ──────────────────────────────────────────────────────────────

  describe "the outbox" do
    setup do
      {_account, calendar} = work!()
      event = event!(calendar, %{summary: "Standup"})
      {:ok, _} = Kati.Sync.edit(event, calendar, %{summary: "Standup, moved"})
      {:ok, calendar: calendar, event: event}
    end

    test "a queued change names the event and says nothing has been lost" do
      t = tree(page())

      # "New event", not "Changed": `Kati.Sync.edit/3` picks its op from
      # `remote_id`, and a Kati event that has never reached this calendar is a
      # create however many times it has been edited here. The title is the
      # summary as it stands NOW rather than as it stood when the entry was
      # written — a queue row is about a row the user can still open.
      assert says?(t, "New event · Standup, moved")
      assert says?(t, "queued, nothing has been lost")
      assert says?(t, "Queued")
      refute says?(t, "Retry")
    end

    test "an event the calendar already has is queued as a change, not as new" do
      calendar = Ash.get!(Kati.Calendars.Calendar, entry!().calendar_id)
      event = event!(calendar, %{summary: "Retro", remote_id: unique("remote")})
      {:ok, _} = Kati.Sync.edit(event, calendar, %{summary: "Retro, moved"})

      assert says?(tree(page()), "Changed · Retro, moved")
    end

    test "a quarantined entry offers Retry and says how many attempts it took" do
      entry = entry!()
      [claimed] = Outbox.claim([entry])
      Outbox.fail(claimed, :quarantine, "the server said 500")

      t = tree(page())

      assert says?(t, "gave up after 1 attempt")
      assert says?(t, "the server said 500")
      assert says?(t, "Retry")
      assert :retry_0 in tags(t)
    end

    test "tapping Retry requeues the entry and says it did" do
      entry = entry!()
      [claimed] = Outbox.claim([entry])
      Outbox.fail(claimed, :quarantine, "the server said 500")

      view = render_info(page(), {:tap, :retry_0})
      requeued = entry!()

      assert requeued.state == :pending
      assert requeued.attempt_count == 0
      assert requeued.last_error == nil
      assert assigns(view).message =~ "Queued again"
    end

    test "a blocked entry says why and is NOT offered a Retry" do
      # `Kati.Sync.Outbox.fail/3` parks a conflict in `:blocked` because trying
      # again cannot fix it. Drawing Retry here would be a button that is
      # answered, changes state, and helps nobody.
      entry = entry!()
      Outbox.fail(entry, :conflict, {:remote_moved, entry.event_uid})

      t = tree(page())

      assert says?(t, "the calendar moved under this change")
      assert says?(t, "trying again cannot fix this on its own")
      assert says?(t, "Blocked")
      refute says?(t, "Retry")
      assert tags(t) == [:back]
    end

    test "an entry blocked behind a conflict points at the question instead" do
      entry = entry!()
      Outbox.fail(entry, :conflict, {:remote_moved, entry.event_uid})

      Event
      |> Ash.Query.filter(uid == ^entry.event_uid)
      |> Ash.read_one!()
      |> Ash.Changeset.for_update(:update, %{sync_state: :conflicted})
      |> Ash.update!()

      t = tree(page())
      assert says?(t, "blocked until you answer the question below")
    end

    test "an entry waiting on a predecessor says so rather than looking stuck" do
      first = entry!()

      {:ok, _second} =
        Outbox.enqueue(%{
          calendar: Ash.get!(Kati.Calendars.Calendar, first.calendar_id),
          row: %{uid: unique("uid") <> "@kati", origin: :kati, local_rev: 1},
          op: :create,
          depends_on: first.id
        })

      t = tree(page())
      assert says?(t, "waiting for an earlier change to land first")
      assert says?(t, "After")
    end

    test "an entry whose event is gone falls back to the UID rather than to blank" do
      # `Kati.Sync.OutboxEntry`'s foreign keys are plain columns precisely so
      # the queue outlives the rows it refers to. A row with no title is the
      # documented case, not a bug.
      entry = entry!()

      Event
      |> Ash.Query.filter(uid == ^entry.event_uid)
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      t = tree(page())
      assert says?(t, entry.event_uid)
    end
  end

  # ── Conflicts, as questions ─────────────────────────────────────────────────

  describe "the three unmergeable cases, each as a question" do
    test "a missing base is asked as a missing base" do
      {_account, calendar} = work!()
      event!(calendar, %{summary: "Standup", sync_state: :conflicted})

      t = tree(page())

      assert says?(t, "There is no record of what this looked like before the edit.")
      assert says?(t, "Kati keeps the version an edit started from")
      assert [model] = Screen.state().conflicts
      assert model.kind == :no_base
    end

    test "a delete meeting an edit is asked as a delete meeting an edit" do
      {_account, calendar} = work!()
      raw = vevent("del-1@kati")

      event =
        event!(calendar, %{
          uid: "del-1@kati",
          summary: "Standup",
          raw_icalendar: raw,
          sync_state: :conflicted
        })

      {:ok, _} =
        Outbox.enqueue(%{
          calendar: calendar,
          row: event,
          op: :delete,
          base_icalendar: raw,
          changed_properties: %{}
        })

      t = tree(page())

      assert [model] = Screen.state().conflicts
      assert model.kind == :delete_edit
      assert says?(t, "You deleted this. Work changed it.")
      assert says?(t, "Keep both is the answer neither side's rule can express")
    end

    test "entangled timing names both halves of the one description" do
      # The case `Kati.Sync.Merge` refuses to merge across differing names:
      # DTSTART moved here, RRULE changed there. The question has to be able to
      # say both, or it is only "there is a conflict".
      {_account, calendar} = work!()
      base = vevent("timing-1@kati")
      remote = vevent("timing-1@kati", ["RRULE:FREQ=DAILY"])

      event =
        event!(calendar, %{
          uid: "timing-1@kati",
          summary: "Standup",
          raw_icalendar: remote,
          sync_state: :conflicted
        })

      {:ok, _} =
        Outbox.enqueue(%{
          calendar: calendar,
          row: event,
          op: :update,
          base_icalendar: base,
          changed_properties: %{"DTSTART" => "DTSTART:20260812T100000Z"}
        })

      t = tree(page())

      assert [model] = Screen.state().conflicts
      assert model.kind == :entangled_timing
      assert says?(t, "You changed DTSTART. Work changed RRULE.")
      assert says?(t, "different property names and one description")
    end

    test "a plain overlap is not dressed up as one of the three" do
      {_account, calendar} = work!()
      base = vevent("overlap-1@kati")
      remote = vevent("overlap-1@kati") |> String.replace("SUMMARY:Standup", "SUMMARY:Stand-up")

      event =
        event!(calendar, %{
          uid: "overlap-1@kati",
          summary: "Standup",
          raw_icalendar: remote,
          sync_state: :conflicted
        })

      {:ok, _} =
        Outbox.enqueue(%{
          calendar: calendar,
          row: event,
          op: :update,
          base_icalendar: base,
          changed_properties: %{"SUMMARY" => "SUMMARY:Standing up"}
        })

      t = tree(page())

      assert [model] = Screen.state().conflicts
      assert model.kind == :overlap
      assert says?(t, "You and Work both changed SUMMARY.")
      assert says?(t, "the one you did not pick is kept below")
    end

    test "each question draws all three answers, with what each one does" do
      {_account, calendar} = work!()
      event!(calendar, %{summary: "Standup", sync_state: :conflicted})

      t = tree(page())

      assert says?(t, "Keep mine")
      assert says?(t, "Take Work's")
      assert says?(t, "Keep both")
      assert says?(t, "Yours becomes a new event")

      for tag <- [:keep_mine_0, :take_theirs_0, :keep_both_0], do: assert(tag in tags(t))
    end
  end

  # ── Resolving ───────────────────────────────────────────────────────────────

  describe "answering a question" do
    setup do
      {_account, calendar} = work!()
      base = vevent("ans-1@kati")
      remote = vevent("ans-1@kati", ["RRULE:FREQ=DAILY"])

      event =
        event!(calendar, %{
          uid: "ans-1@kati",
          summary: "Standup",
          raw_icalendar: remote,
          sync_state: :conflicted
        })

      {:ok, _} =
        Outbox.enqueue(%{
          calendar: calendar,
          row: event,
          op: :update,
          base_icalendar: base,
          changed_properties: %{"DTSTART" => "DTSTART:20260812T100000Z"}
        })

      {:ok, calendar: calendar, event: event}
    end

    test "Keep mine requeues the push and keeps the calendar's values", %{event: event} do
      view = render_info(page(), {:tap, :keep_mine_0})

      assert Ash.get!(Event, event.id).sync_state == :dirty
      assert [%RejectedChange{side: :remote}] = rejections()
      assert assigns(view).message =~ "kept below"
    end

    test "Take the calendar's drops the push and keeps the local edit", %{event: event} do
      view = render_info(page(), {:tap, :take_theirs_0})

      assert Ash.get!(Event, event.id).sync_state == :clean
      assert entries() == []
      assert [%RejectedChange{side: :local}] = rejections()
      assert assigns(view).message =~ "not discarded"
    end

    test "Keep both leaves a second event, and the page says so" do
      view = render_info(page(), {:tap, :keep_both_0})

      forked = Event |> Ash.read!() |> Enum.filter(&String.ends_with?(&1.uid, "-split@kati"))

      assert length(forked) == 1
      assert assigns(view).message =~ "separate Kati event"
    end

    test "an answered question leaves the page" do
      view = render_info(page(), {:tap, :take_theirs_0})
      assert assigns(view).sync.conflicts == []
      assert says?(tree(view), "Nothing is waiting on you")
    end

    test "a tag naming a row that is no longer there says so instead of raising" do
      view = render_info(page(), {:tap, :keep_mine_7})
      assert assigns(view).message =~ "no longer here"
    end
  end

  # ── Kept edits ──────────────────────────────────────────────────────────────

  describe "the edits that lost" do
    setup do
      {_account, calendar} = work!()
      event = event!(calendar, %{uid: "kept-1@kati", summary: "Standup"})

      rejected =
        RejectedChange
        |> Ash.Changeset.for_create(:create, %{
          calendar_id: calendar.id,
          event_uid: "kept-1@kati",
          side: :remote,
          reason: :ownership_kati,
          properties:
            Jason.encode!(%{
              "DTSTART" => ["DTSTART:20260812T110000Z"],
              "RRULE" => ["RRULE:FREQ=DAILY"]
            }),
          base_properties: Jason.encode!(%{"DTSTART" => ["DTSTART:20260812T090000Z"]})
        })
        |> Ash.create!()

      {:ok, calendar: calendar, event: event, rejected: rejected}
    end

    test "a kept edit names whose it was, which properties, and which rule set it aside" do
      t = tree(page())

      assert says?(t, "Standup")
      assert says?(t, "The calendar's DTSTART and RRULE")
      assert says?(t, "this is a Kati event, so Kati's version won")
      assert says?(t, "Re-apply")
    end

    test "the page states that putting one back is a merge, not a clobber" do
      t = tree(page())

      assert says?(t, "Nothing above was thrown away")
      assert says?(t, "the same three-way merge as any other edit")
      assert says?(t, "will not overwrite whatever the winner left behind")
    end

    test "Re-apply goes through the queue rather than writing the row directly" do
      view = render_info(page(), {:tap, :reapply_0})

      assert [entry] = entries()
      assert entry.event_uid == "kept-1@kati"
      assert entry.op == :create or entry.op == :update
      assert assigns(view).message =~ "merged against what is there now"
    end

    test "Re-apply marks the kept row applied, so it stops being offered twice" do
      view = render_info(page(), {:tap, :reapply_0})

      assert [row] = rejections()
      assert row.applied_at != nil
      assert Kati.Sync.rejected(row.calendar_id) == []
      assert assigns(view).sync.rejected == []
    end

    test "a kept edit whose write policy forbids it is shown and not offered" do
      # The two-gates rule, applied to a screen: do not draw a control policy
      # will refuse. The row still appears — the edit is still kept, which is
      # the whole point of the table.
      empty!()
      calendar = calendar!(%{display_name: "Team", kind: :provider, writeback_policy: :kati_only})
      event!(calendar, %{uid: "mirror-1@kati", summary: "Sprint review", origin: :mirror})

      RejectedChange
      |> Ash.Changeset.for_create(:create, %{
        calendar_id: calendar.id,
        event_uid: "mirror-1@kati",
        side: :local,
        reason: :ownership_mirror,
        properties: Jason.encode!(%{"LOCATION" => ["LOCATION:Room 9"]}),
        base_properties: "{}"
      })
      |> Ash.create!()

      t = tree(page())

      assert says?(t, "Sprint review")
      assert says?(t, "Your LOCATION")
      assert says?(t, "this event is mirrored, so the calendar's version won")
      assert says?(t, "Kept")
      refute says?(t, "Re-apply")
      assert tags(t) == [:back]
    end

    test "a kept edit whose event is gone says so rather than half-working" do
      Event |> Ash.read!() |> Enum.each(&Ash.destroy!/1)

      t = tree(page())
      assert says?(t, "kept-1@kati")
      refute says?(t, "Re-apply")
    end
  end

  # ── The list this screen keeps a second copy of ─────────────────────────────

  describe "the entangled timing set" do
    @base %{
      "DTSTART" => ["DTSTART:20260812T090000Z"],
      "SUMMARY" => ["SUMMARY:Standup"],
      "LOCATION" => ["LOCATION:Room 4"]
    }

    test "every name the screen calls entangled really is unmergeable across names" do
      # `Kati.Screens.Sync`'s `@entangled` is a second copy of a private list in
      # `Kati.Sync.Merge`, and a second copy of a constant goes stale silently —
      # here it would go stale as a question that says "there is a conflict"
      # where it used to name both halves. So the copy is pinned against the
      # behaviour rather than against the other list: for each name, a local
      # `DTSTART` move against a remote change to that name must be *contested*,
      # which is the property the entangled rule exists to produce.
      local = Map.put(@base, "DTSTART", ["DTSTART:20260812T100000Z"])

      for name <- Screen.entangled() do
        remote = Map.put(@base, name, [name <> ":X"])

        assert match?(
                 {:resolved, _winner, _props, _rejected},
                 Merge.merge(@base, {:present, local}, {:present, remote}, :kati)
               ),
               "#{name} is in Kati.Screens.Sync's entangled list and Kati.Sync.Merge merges " <>
                 "a change to it silently, so the timing question names a half that is not " <>
                 "actually contested"
      end
    end

    test "a property outside the set still merges silently, so the pin is not vacuous" do
      # The control. Without it the assertion above would pass just as happily
      # against a merge that contested everything.
      local = Map.put(@base, "DTSTART", ["DTSTART:20260812T100000Z"])

      for name <- ~w(SUMMARY LOCATION DESCRIPTION STATUS TRANSP ORGANIZER) do
        remote = Map.put(@base, name, [name <> ":X"])

        assert match?(
                 {:merged, {:present, _props}},
                 Merge.merge(@base, {:present, local}, {:present, remote}, :kati)
               ),
               "#{name} is not in the entangled list and Kati.Sync.Merge contests it anyway"
      end
    end

    test "the list is not empty, so neither loop above swept nothing" do
      assert length(Screen.entangled()) == 7
    end
  end

  # ── Truncation ──────────────────────────────────────────────────────────────

  describe "a queue longer than the page" do
    test "the hidden entries are counted rather than silently dropped" do
      # A cap that hid its own existence would make a queue of twenty look like
      # a queue of twelve, which is the one thing a page about a queue must not
      # do.
      {_account, calendar} = work!()

      for _ <- 1..15 do
        event = event!(calendar, %{summary: "Standup"})
        {:ok, _} = Kati.Sync.edit(event, calendar, %{summary: "Moved"})
      end

      t = tree(page())

      assert says?(t, "3 changes more, not shown")
      assert Screen.state().waiting == 15
    end
  end

  # ── Words ───────────────────────────────────────────────────────────────────

  describe "the sentences the rows are built from" do
    test "one, two and many property names read as a sentence" do
      assert Screen.list_names([]) == "something"
      assert Screen.list_names(["DTSTART"]) == "DTSTART"
      assert Screen.list_names(["DTSTART", "RRULE"]) == "DTSTART and RRULE"
      assert Screen.list_names(["DTSTART", "EXDATE", "RRULE"]) == "DTSTART, EXDATE and RRULE"
    end

    test "counts are pluralised, including the one that is not" do
      assert Screen.plural(1, "change") == "1 change"
      assert Screen.plural(0, "change") == "0 changes"
      assert Screen.plural(2, "attempt") == "2 attempts"
    end

    test "the engine's recorded reasons become sentences, and an unknown one survives" do
      assert Screen.reason("delete_edit") == "a deletion met an edit"
      assert Screen.reason("no_base") == "the version this edit started from is missing"
      assert Screen.reason("unparseable") == "one of the two versions could not be read"
      assert Screen.reason(inspect({:remote_moved, "x@kati"})) =~ "moved under this change"
      assert Screen.reason(nil) == "no reason was recorded"

      # Anything the engine did not name is passed through rather than flattened
      # to "an error" — the transport's own words are the only actionable part.
      assert Screen.reason("HTTP 507 Insufficient Storage") == "HTTP 507 Insufficient Storage"
    end

    test "a refusal is rendered in the refusing module's own words" do
      {_account, calendar} = work!()
      event = event!(calendar, %{origin: :mirror})

      {:error, {:not_writable, detail}} =
        Kati.Sync.Ownership.authorise(event, calendar)

      assert Screen.refused({:not_writable, detail}) =~ detail.reason
    end

    test "how long ago, at each step it changes shape" do
      now = Kati.Time.now()

      assert Screen.ago(nil) == "never"
      assert Screen.ago(now) == "just now"
      assert Screen.ago(DateTime.add(now, -180, :second)) == "3m ago"
      assert Screen.ago(DateTime.add(now, -7200, :second)) == "2h ago"
      assert Screen.ago(DateTime.add(now, -3 * 86_400, :second)) == "3d ago"
    end
  end

  # ── A half-landed chain ─────────────────────────────────────────────────────

  describe "a this-and-following split that only half landed" do
    test "the calendar and the entry both say so, rather than saying queued" do
      # `Kati.Sync.Outbox.partially_synced/1` exists because losing this is how
      # a failed split becomes the silent loss of every future occurrence: the
      # master's UNTIL was trimmed and its successor never arrived. A page that
      # drew the survivor as an ordinary queued change would be the last thing
      # between the user and that.
      {_account, calendar} = work!()
      event = event!(calendar, %{uid: "split-1@kati", summary: "Standup"})

      {:ok, trim} =
        Outbox.enqueue(%{calendar: calendar, row: event, op: :update, base_icalendar: nil})

      Outbox.succeed(trim)

      {:ok, successor} =
        Outbox.enqueue(%{calendar: calendar, row: event, op: :create, base_icalendar: nil})

      Outbox.fail(successor, :conflict, "the server refused the successor")

      assert Outbox.partially_synced(calendar.id) == ["split-1@kati"]

      t = tree(page())
      assert says?(t, "1 change only half landed")
      assert says?(t, "Half sent")
    end
  end

  # ── Two properties nothing else in the suite checks for this screen ─────────

  describe "the page as a page" do
    test "it responds to the theme, so it is not a light screen with a dark frame" do
      # `Kati.ThemeCoverageTest` sweeps the gallery registry, and this screen is
      # not in it because no drawing exists. Same question, asked here: a tree
      # identical in both modes means every colour on it is a literal the
      # palette never sees, which is the defect the palette exists to remove.
      {_account, calendar} = work!()
      event!(calendar, %{summary: "Standup", sync_state: :conflicted})

      Kati.Theme.Mode.put(:light)
      light = tree(page())

      Kati.Theme.Mode.put(:dark)
      dark = tree(page())

      # Restored here rather than in `on_exit`, for the reason
      # `Kati.ThemeCoverageTest` restores inline: `Mob.ScreenCase` takes
      # `Mob.State` down around each test, so an `on_exit` writing a preference
      # is a `GenServer.call` to a process that has already gone.
      Kati.Theme.Mode.put(:light)

      refute light == dark
    end

    test "a full page stays far below the tap-handle cap that kills a screen" do
      # `MAX_TAP_HANDLES` is 256 and going over it raises inside the renderer,
      # which kills a screen process that has no supervisor. This screen is not
      # in `Kati.TapHandleBudgetTest`'s gallery-derived list, and it is the one
      # screen here whose control count grows with the user's data — so the
      # caps that bound it are asserted rather than assumed.
      {_account, calendar} = work!()

      for _ <- 1..20 do
        event = event!(calendar, %{summary: "Standup"})
        {:ok, _} = Kati.Sync.edit(event, calendar, %{summary: "Moved"})
      end

      for i <- 1..10 do
        event!(calendar, %{uid: "c-#{i}@kati", summary: "Review", sync_state: :conflicted})
      end

      handles =
        page()
        |> tree()
        |> flatten()
        |> Enum.count(&(Map.get(&1.props || %{}, :on_tap) not in [nil, false]))

      assert handles < 60,
             "#{handles} tap handles on one page. The caps in Kati.Screens.Sync are what " <>
               "keep this bounded as a queue grows; something is drawing per-row controls " <>
               "outside them"
    end
  end

  # ── Taps this screen does not draw ──────────────────────────────────────────

  describe "tags nothing drew" do
    test "an unknown tag changes nothing at all" do
      view = page()
      after_tap = render_info(view, {:tap, :not_a_control})

      assert assigns(after_tap) == assigns(view)
      assert navigated_to(after_tap) == nil
    end

    test "a malformed index is refused rather than read as the last row" do
      # `Enum.at/2` reads -1 as the LAST element, so a tag carrying one would
      # resolve a question the user never tapped. Same trap
      # `Kati.Screens.Settings.choice_at/1` guards.
      {_account, calendar} = work!()
      event!(calendar, %{summary: "Standup", sync_state: :conflicted})

      view = render_info(page(), {:tap, :"keep_mine_-1"})

      assert assigns(view).message =~ "no longer here"
      assert rejections() == []
    end
  end
end
