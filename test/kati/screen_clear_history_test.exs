defmodule Kati.ScreenClearHistoryTest do
  @moduledoc """
  Board 267 — Clear watch history, and the three rules it makes about numbers.

  Screen 24's Data group had one row that opened nothing, and board 267 notes
  that it was also *"the only row in its group whose meaning cannot be read
  before tapping it"* — a destructive row with no second line. Both halves are
  answered here: the row has a line, and it has a destination.

  The board's rules are structural rather than stylistic, and each is a test:

    * **counted before the delete, never after** — a report built from the
      delete's own row count says nothing was deleted while it deletes
      everything;
    * **reviews are named separately** — a count of "entries" hides that this
      deletes sentences a person wrote;
    * **no total across the four** — there is no such noun in this app, and a
      destructive confirmation is the last screen that may print an invented
      one.

  And the promise the page makes about what stays is kept by the code rather
  than printed by the screen: every line under *What stays* is a different
  table, and `Kati.Media.History.clear/0` names one resource.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.History
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.ClearHistory

  @prefix "clear-history-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the four figures" do
    test "count what each line says it counts, and nothing else" do
      tracked = shelve!()

      log!(tracked, %{})
      log!(tracked, %{rating: 8})
      log!(tracked, %{rating: 9, review: "A quiet one."})
      log!(tracked, %{place: "the sofa"})
      log!(tracked, %{companions: "Jo"})

      counts = History.counts()

      assert counts.logs == 5
      assert counts.ratings == 2
      assert counts.reviews == 1

      # Where OR who with — one row can be both and is counted once.
      assert counts.notes == 2
    end

    test "and a blank review is not a review" do
      tracked = shelve!()
      log!(tracked, %{review: "   "})

      assert History.counts().reviews == 0
    end

    test "nothing anywhere adds them up" do
      # Board 267: "No total across the four — there is no such noun in this
      # app, and a destructive confirmation is the last screen that may print
      # an invented one."
      tracked = shelve!()
      for _ <- 1..3, do: log!(tracked, %{rating: 7, review: "x", place: "y"})

      counts = History.counts()
      total = counts.logs + counts.ratings + counts.reviews + counts.notes
      assert total == 12

      words = text(mount_screen(ClearHistory))

      refute words =~ Integer.to_string(total),
             "the page printed a total across the four figures"
    end
  end

  describe "the page" do
    test "says what goes and what stays, in the board's own words" do
      words = text(mount_screen(ClearHistory))

      assert words =~ "Clear watch history"
      assert words =~ String.upcase("What goes, and what stays")

      for line <- [
            "times you logged something watched, read or played",
            "ratings on those logs",
            "reviews you wrote",
            "notes about where and who with"
          ] do
        assert words =~ line, "board 267's line #{inspect(line)} is missing"
      end

      assert words =~ String.upcase("What stays")
      assert words =~ "Every shelf and every status"
      assert words =~ "Reading sessions and listens"
      assert words =~ "Your library, lists and wishlist"
    end

    test "and names the surprise, which exists nowhere else in the drawings" do
      words = text(mount_screen(ClearHistory))

      assert words =~ "Every episode unticks."
      assert words =~ "S2 · E5"
    end

    test "the backup row is offered, not taken" do
      words = text(mount_screen(ClearHistory))

      assert words =~ "Keep a copy first"
      assert words =~ "Offered, not taken"

      # It opens the backup screen and does nothing else. A confirmation that
      # silently backed up first would be deciding for the reader on the screen
      # where that is least acceptable.
      {:noreply, pushed} = ClearHistory.handle_tap(:back_up, Mob.Socket.new(ClearHistory))
      assert {:push, Kati.Screens.Backup, _} = Map.get(pushed.__mob__, :nav_action)
    end

    test "with nothing logged, the destructive row draws no tap" do
      assert History.counts().logs == 0

      drawn = inspect(ClearHistory.actions(History.counts()), limit: :infinity)

      assert drawn =~ ":back_up"
      refute drawn =~ ":ask", "a row that opens a confirmation about zero logs is a dead control"
    end

    test "and with something logged it does" do
      tracked = shelve!()
      log!(tracked, %{})

      drawn = inspect(ClearHistory.actions(History.counts()), limit: :infinity)

      assert drawn =~ ":ask"
    end
  end

  describe "the confirmation" do
    test "names this reader's own number and both sentences" do
      tracked = shelve!()
      for _ <- 1..4, do: log!(tracked, %{})

      words = text(ClearHistory.confirm(true, History.counts()))

      assert words =~ "Clear 4 logs?"
      assert words =~ "Changes: every tick, rating and review, and every progress ring."
      assert words =~ "Does not change: your shelves, your lists"
      assert words =~ "Clear it"
      assert words =~ "Keep it"
    end

    test "is not drawn until it is asked for, and Keep it puts it away" do
      socket = Mob.Socket.new(ClearHistory)

      refute inspect(ClearHistory.confirm(false, History.counts())) =~ "Clear it"

      {:noreply, asked} = ClearHistory.handle_tap(:ask, socket)
      assert asked.assigns.confirming?

      {:noreply, kept} = ClearHistory.handle_tap(:keep, asked)
      refute kept.assigns.confirming?
    end
  end

  describe "the clear itself" do
    test "removes every log and reports the number counted BEFORE the delete" do
      tracked = shelve!()
      for _ <- 1..3, do: log!(tracked, %{rating: 5})

      assert {:ok, 3} = History.clear()
      assert History.counts().logs == 0
    end

    test "and keeps everything the page promises it keeps" do
      tracked = shelve!()
      log!(tracked, %{})

      assert {:ok, 1} = History.clear()

      # The shelf row itself, with its status and its bookmark — the board's
      # "your bookmark survives" and "they live on the title, not on a log".
      assert {:ok, still} = Ash.get(TrackedTitle, tracked.id)
      assert still.status == :watching
    end

    test "the page after a clear says what it did, and offers nothing more to clear" do
      tracked = shelve!()
      for _ <- 1..2, do: log!(tracked, %{})

      view = mount_screen(ClearHistory)
      {:noreply, cleared} = ClearHistory.handle_tap(:clear, view.socket)

      assert cleared.assigns.cleared == 2
      refute cleared.assigns.confirming?

      # Re-read rather than subtracted: the figures on the page were counted
      # before the delete, and the page after it is a different question.
      assert cleared.assigns.counts.logs == 0
    end
  end

  describe "screen 24's row" do
    test "has a second line now, which is board 267's own edit" do
      row = Enum.find(Kati.Settings.Sample.data(), &(&1.title == "Clear watch history"))

      assert row, "the Clear watch history row is gone from screen 24"

      assert row.sub == "Ticks, ratings and reviews — the shelves stay",
             "the only destructive row in the Data group still cannot be read before it is tapped"
    end

    test "and it opens something" do
      assert Kati.Screens.Settings.destinations()["Clear watch history"] ==
               Kati.Screens.ClearHistory
    end
  end

  defp shelve!(title \\ "Estuary Nights") do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :tv,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :tv,
      status: :watching
    })
  end

  defp log!(tracked, attrs) do
    Ash.create!(
      Watch,
      Map.merge(%{tracked_title_id: tracked.id, watched_at: Kati.Time.now()}, attrs)
    )
  end
end
