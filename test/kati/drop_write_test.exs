defmodule Kati.DropWriteTest do
  @moduledoc """
  Dropping a show says whether it was dropped.

  `update_tracked/2` ran `Ash.update/2`, threw the result away and rescued a
  raise to `:ok`, so a refused drop and a successful one were the same thing to
  look at: the sheet flipped to its *Dropped* face and announced a change that
  had not been made. MOVIES-AND-TV.md #57.

  The `rescue` stays, and it matters that it does — an `Ash.Changeset` error is
  a value and a raise is not, and a sheet that died inside a tap handler would
  take the screen process with it. What changed is that both now reach the
  socket instead of being flattened to `:ok`.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.DropSheet

  @prefix "drop-write-"

  setup do
    # `media_events` is read WHOLE by the assertions below — an event is not
    # keyed by this file's prefix — so it is emptied going in as well as
    # coming out. Another file's leftover row is otherwise this file's failure,
    # and only on the orders where that file ran first.
    Kati.Repo.query!("DELETE FROM media_events", [])

    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM media_events", [])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "a write that lands" do
    setup do
      %{tracked: tracked!(:paused)}
    end

    test "sets the status and clears any refusal", %{tracked: tracked} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, sheet_for(tracked))

      assert after_tap.assigns.save_error == nil
      assert after_tap.assigns.dropped?

      assert Ash.get!(TrackedTitle, tracked.id).status == :dropped
    end

    test "and *still on it* pops", %{tracked: tracked} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :keep}, sheet_for(tracked))

      assert after_tap.__mob__.nav_action == {:pop}
      assert Ash.get!(TrackedTitle, tracked.id).status == :watching
    end
  end

  describe "a write that cannot land" do
    setup do
      tracked = tracked!(:paused)
      socket = sheet_for(tracked)

      # The row is gone by the time the button is pressed — the sheet was
      # opened, the title removed on another screen, and the tap arrives
      # against a stale struct. `Ash.update/2` raises for this, which is the
      # branch the old `rescue _ -> :ok` swallowed whole.
      Ash.destroy!(tracked)

      %{socket: socket, tracked: tracked}
    end

    test "says so rather than announcing a drop", %{socket: socket} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, socket)

      assert is_binary(after_tap.assigns.save_error)

      refute after_tap.assigns.dropped?,
             "the sheet flipped to its Dropped face over a write that did not happen"
    end

    test "and draws the message", %{socket: socket} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, socket)

      drawn = inspect(DropSheet.render(after_tap.assigns), limit: :infinity)

      assert drawn =~ after_tap.assigns.save_error
    end

    test "a refused *still on it* stays on the sheet", %{socket: socket} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :keep}, socket)

      assert after_tap.__mob__.nav_action == nil,
             "popping would take the message with it and land the reader on an " <>
               "unchanged page with nothing to explain why"

      assert is_binary(after_tap.assigns.save_error)
    end
  end

  describe "the reason, which used to be thrown away" do
    setup do
      %{tracked: tracked!(:paused)}
    end

    test "is written with the position it was picked at", %{tracked: tracked} do
      # MOVIES-AND-TV.md #111. The reason was assigned to the socket, drawn as
      # a lit chip, and discarded when the sheet closed — the one question in
      # the app whose answer nothing could ever read back.
      socket = sheet_for(tracked)

      {:noreply, chosen} = DropSheet.handle_info({:tap, :reason_too_slow}, socket)
      assert chosen.assigns.reason == :too_slow

      {:noreply, _dropped} = DropSheet.handle_info({:tap, :drop}, chosen)

      assert [event] = events_for(tracked)
      assert event.kind == :dropped
      assert event.reason == "Too slow"
      assert event.tracked_title_id == tracked.id
      assert event.from_status == :paused
      assert event.season_number == 1
      assert event.episode_number == 1
    end

    test "and a drop with no reason still records the drop", %{tracked: tracked} do
      {:noreply, _dropped} = DropSheet.handle_info({:tap, :drop}, sheet_for(tracked))

      assert [%{kind: :dropped, reason: nil}] = events_for(tracked)
    end

    test "undo is a second row, not the first one erased", %{tracked: tracked} do
      socket = sheet_for(tracked)
      {:noreply, dropped} = DropSheet.handle_info({:tap, :drop}, socket)
      {:noreply, _undone} = DropSheet.handle_info({:tap, :undo}, dropped)

      kinds = tracked |> events_for() |> Enum.map(& &1.kind) |> Enum.sort()

      assert kinds == [:dropped, :resumed],
             "an append-only log whose undo erases its own cause is not one"
    end

    test "and a refused drop records nothing", %{tracked: tracked} do
      # An event log that records a change the store refused is worse than no
      # log: it is a record of something that did not happen.
      socket = sheet_for(tracked)
      Ash.destroy!(tracked)

      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, socket)

      assert after_tap.assigns.save_error
      assert events_for(tracked) == []
    end
  end

  describe "the position pill" do
    test "goes both ways" do
      # MOVIES-AND-TV.md #127: it only ever decremented, so overshooting meant
      # closing the sheet and opening it again.
      assert DropSheet.step_forward(%{season: 2, episode: 5}) == %{season: 2, episode: 6}
      assert DropSheet.step_back(%{season: 2, episode: 5}) == %{season: 2, episode: 4}

      # And back past the head of a season still walks to the one before it.
      assert DropSheet.step_back(%{season: 2, episode: 1}) == %{season: 1, episode: 1}
      assert DropSheet.step_back(%{season: 1, episode: 1}) == %{season: 1, episode: 1}
    end

    test "and both discs are on the sheet", %{} do
      tracked = tracked!(:paused)
      socket = sheet_for(tracked)
      drawn = inspect(DropSheet.render(socket.assigns), limit: :infinity)

      assert drawn =~ "step_back"
      assert drawn =~ "step_forward"
    end
  end

  describe "a film" do
    test "can be dropped, and its sheet says film" do
      # MOVIES-AND-TV.md #110: a film could not be dropped, abandoned or DNF'd
      # anywhere in the app.
      tracked = film!()
      socket = sheet_for(tracked)
      sheet = socket.assigns.sheet

      assert sheet.kind == :movie
      assert DropSheet.heading(sheet) == "Drop this film"

      # No position card: a film has no episode to have stopped after, and
      # inventing `S1 E1` would put it on a two-hour film's own history.
      assert sheet.season == nil
      assert sheet.episode == nil

      drawn = inspect(DropSheet.render(socket.assigns), limit: :infinity)
      refute drawn =~ "Stopping at"
      refute drawn =~ "step_back"

      # And no position anywhere else either. The button and the undo pill
      # build the same sentence out of the same two numbers, and with them nil
      # they read **Drop at S E** — found by opening the sheet on the Pixel_9a.
      assert DropSheet.at(sheet) == ""
      assert drawn =~ "\"Drop\""
      assert drawn =~ "Dropped Estuary\""

      {:noreply, _dropped} = DropSheet.handle_info({:tap, :drop}, socket)

      assert Ash.get!(TrackedTitle, tracked.id).status == :dropped
      assert [%{kind: :dropped, season_number: nil}] = events_for(tracked)
    end

    test "and screen 08 offers the row, but only over a real film" do
      drawn = inspect(Kati.Screens.Film.drop_item(%{tracked_id: "x"}), limit: :infinity)
      assert drawn =~ "open_drop_sheet"
      assert drawn =~ "Drop this film"

      # Over the drawing there is nothing to drop, and the row would open the
      # sheet on whatever gone-cold title happened to be newest.
      assert Kati.Screens.Film.drop_item(%{}) == []
    end
  end

  describe "the empty sheet" do
    test "has no row to write against, and refuses rather than claiming a drop" do
      # This test used to assert the opposite, and it was pinning a live defect:
      # `update_tracked(nil, _)` answered `:ok`, so `save_error` stayed nil and
      # `dropped?` flipped true. The sheet said *Dropped* over a write that
      # never happened — and `Kati.Media.Log.write(nil, _, _)` is `:ok` too, so
      # nothing recorded it either. Nothing was persisted and the reader was
      # told otherwise.
      #
      # The old argument — that an error over board 149 is a message about a
      # picture — only held while the drawing was unreachable, and it was not:
      # screens 04 and 08 fell back to their own drawings, a drawn row carries
      # no `tracked_id`, so a real ⋯ menu opened this sheet over nothing.
      {:ok, socket} = DropSheet.mount(%{}, %{}, Mob.Socket.new(DropSheet))

      assert socket.assigns.sheet == DropSheet.empty_sheet(),
             "a sheet named nothing draws its own empty state, not the board's own show"

      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, socket)

      assert after_tap.assigns.save_error == Kati.Write.message({:error, :not_tracked}),
             "a tap that wrote nothing has to say so"

      refute after_tap.assigns.dropped?,
             "the sheet turned to its Dropped face over a title it never wrote"
    end
  end

  describe "the mono line under the title" do
    # Found auditing board 148 against this screen. `cold_label` was
    # `GONE COLD · %{age}` unconditionally and `pick/2` looks a named push up in
    # the WHOLE shelf, so *Drop this show* on a title's own ⋯ menu told a reader
    # who started something this morning that it had GONE COLD · TODAY.
    #
    # 148's moduledoc is the rule: *Paused and Dropped are things a person
    # decided; Gone cold is something Kati noticed.*
    test "says nothing at all over a show being watched normally" do
      tracked = tracked!(:watching)

      refute Kati.Media.Staleness.gone_cold?(tracked),
             "the fixture went cold, so this test is not measuring the fresh case"

      assert DropSheet.mark(tracked) == ""

      drawn = inspect(DropSheet.render(sheet_for(tracked).assigns), limit: :infinity)

      refute drawn =~ "GONE COLD",
             "Kati claimed to have noticed something about a show started today"
    end

    test "says PAUSED over a title the reader paused, not GONE COLD" do
      tracked = tracked!(:paused)

      mark = DropSheet.mark(tracked)

      assert mark =~ "PAUSED"

      refute mark =~ "GONE COLD",
             "a decision the reader made was reported back as something Kati noticed"
    end

    test "and GONE COLD only when it actually is" do
      tracked = tracked!(:watching)

      cold =
        Ash.update!(
          Ash.Changeset.for_update(tracked, :update, %{}, authorize?: false)
          |> Ash.Changeset.force_change_attribute(
            :last_touched_at,
            DateTime.add(Kati.Time.now(), -400, :day)
          )
        )

      assert Kati.Media.Staleness.gone_cold?(cold),
             "400 days is not cold, so `Kati.Media.Staleness` has moved and this needs rewriting"

      assert DropSheet.mark(cold) =~ "GONE COLD"
    end
  end

  defp sheet_for(tracked) do
    {:ok, socket} =
      DropSheet.mount(%{title_id: tracked.id}, %{}, Mob.Socket.new(DropSheet))

    socket
  end

  # Only this title's events. `Ash.read!/1` answers with every row in the
  # store, so another file's leftover is otherwise this file's failure.
  defp events_for(tracked) do
    Kati.Media.Event
    |> Ash.read!()
    |> Enum.filter(&(&1.tracked_title_id == tracked.id))
  end

  defp film!() do
    source_id = @prefix <> "film"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      title: "Estuary",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      status: :paused
    })
  end

  defp tracked!(status) do
    source_id = @prefix <> "one"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: "The Quiet Ones",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: status
    })
  end
end
