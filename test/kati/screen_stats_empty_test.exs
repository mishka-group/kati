defmodule Kati.ScreenStatsEmptyTest do
  @moduledoc """
  Screen 07 on a phone that has watched nothing — issue #91.

  Until this file existed, an empty `Kati.Media` made `Kati.Screens.Stats` draw
  `Kati.Stats.Sample` whole: `312h 40m`, a `18%` rise, `84 Films`, `19 Series`,
  `4.1 Avg ★`, a 182-day contribution field, five genre bars and three films
  nobody had watched. A person opening the Stats tab on the day they installed
  Kati was shown a year of somebody's viewing, presented as theirs. That is the
  defect the app's owner reported.

  ## Why the tests that describe the empty page assert an absence too

  An empty state is the one screen whose *presence* checks are all satisfiable by
  the screen it replaces. `assert words =~ "Not much to show yet"` passes on a
  page that also draws every invented figure underneath it — the card and the
  fabrication are not mutually exclusive, and a half-done change produces exactly
  that page. So every test that describes what the empty page IS pairs the two,
  and the refuted strings are read out of `Kati.Stats.Sample` rather than typed
  here: a sample module edited to say something else cannot quietly turn a
  `refute` into a claim about a string nothing was ever going to draw.

  Four tests carry no `refute`, and deliberately: the range, `More numbers`
  itself, the five rows' pushes and the share disc are claims that something
  KEPT working, and there is no absence to pair a kept thing with. Each is
  pinned against a source rather than a literal instead — the range against
  `Kati.Time.today()`, the rows against `Kati.Stats.Sample.more_numbers/0`, the
  pushes and the disc against the modules they land on — so freezing the range
  to the drawing's `Jan – Aug 2026`, dropping the list, or unwiring a tap each
  fails one of them.

  `the drawing's figures are still the ones being refuted` is the guard under
  that: it fails if `Kati.Stats.Sample` stops holding the values this file names,
  which is the one way the refutes above could go vacuous.

  ## And why the last describe seeds a watch

  Every `refute` here is also satisfied by a screen that draws nothing at all —
  by a blank page, or by a `content/1` that lost its second branch. So the last
  block puts one watch in the database and asserts the counted page comes back
  whole: a headline figure, 182 squares, the second lines under `More numbers`.
  The empty state has to be a *branch*, not a deletion.

  ## The shared database

  One SQLite file for the whole suite (see `test/test_helper.exs`), so an empty
  history is made rather than assumed, and the same four tables
  `Kati.ScreenStatsTest` empties are the ones emptied here.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Stats
  alias Kati.Stats.Sample

  # Child first: a watch carries the foreign key to a tracked title.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles)

  # Board 101's own words, and the sentence written to its cadence. Named once so
  # the presence checks and the "what the card is" check cannot drift apart.
  @headline "Not much to show yet"
  @sentence "Your year is counted from what you tick off. " <>
              "Mark one thing watched and this page starts filling itself."

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "a phone that has watched nothing" do
    test "answers with no year at all, rather than with the drawing's" do
      figures = Stats.figures()

      # `nil`, not a map of zeroes: see `figures/0`'s own doc, and board 123 —
      # dividing by no hours has no answer and Kati declines to invent one.
      assert figures[:year] == nil
      assert figures[:grid] == []
      assert figures[:recent] == []

      refute figures[:grid] == Sample.contributions()
      refute figures[:recent] == Stats.recent()
    end

    test "the range under `Your year` is still the device's own clock" do
      today = Kati.Time.today()
      expected = "#{month(1)} – #{month(today.month)} #{today.year}"

      assert Stats.figures()[:range] == expected
      assert text(tree(mount_screen(Stats))) =~ expected
      assert text(tree(mount_screen(Stats))) =~ "Your year"
    end

    test "draws the card board 101 draws when there is too little behind the year" do
      tree = tree(mount_screen(Stats))
      words = text(tree)

      assert words =~ @headline
      assert words =~ @sentence

      # The 64pt tile, at the glyph `Kati.Shell` already gives this tab. Counted
      # rather than found, because the dock draws that same glyph on every root:
      # one occurrence is the tab bar and proves nothing, and two is the tile.
      assert length(find_all(tree, :text, text: Kati.Icons.glyph("bar_chart_4_bars"))) == 2

      # And the page is a whole renderable page, not a fragment.
      assert_renderable(tree)
    end

    test "draws none of the year the drawing invented" do
      words = text(tree(mount_screen(Stats)))
      year = Sample.year()

      refute words =~ year.time
      refute words =~ year.streak
      refute words =~ "#{year.weeks} weeks"

      # `year.change` is "18%", and the pill it lives in is gone with it.
      refute words =~ year.change

      for {number, label} <- year.counts do
        refute words =~ String.upcase(label),
               "the #{label} count card is still drawn on a phone that has watched nothing"

        # `4.1` and `19` are distinctive; `84` would also match a runtime, so the
        # label above is the load-bearing half and this is the belt.
        refute words =~ number
      end
    end

    test "draws no genre breakdown, because no hours have gone anywhere" do
      words = text(tree(mount_screen(Stats)))

      refute words =~ String.upcase("Where the hours went")

      for {name, _fraction, value, _colour} <- Sample.year().breakdown do
        refute words =~ name
        refute words =~ value
      end
    end

    test "draws no contribution grid — a field of 182 zeroes is a measurement of nothing" do
      tree = tree(mount_screen(Stats))

      assert find_all(tree, :box, width: 8, height: 8) == []
      # The populated screen draws 182 of them; see the last describe.
      assert length(Sample.contributions()) == 182
    end

    test "draws no `Recently watched`, and no stars for things nobody rated" do
      tree = tree(mount_screen(Stats))
      words = text(tree)

      refute words =~ String.upcase("Recently watched")

      for row <- Stats.recent() do
        refute words =~ row.title
        refute words =~ row.meta
      end

      assert find_all(tree, :text, text: Kati.Icons.glyph("star")) == []
    end

    test "keeps `More numbers`, because those five rows are the only route to those screens" do
      words = text(tree(mount_screen(Stats)))

      assert words =~ String.upcase("More numbers")

      for row <- Sample.more_numbers(), row.title != "Recently watched" do
        assert words =~ row.title, "#{row.title} lost its row, and with it its only route"
      end
    end

    test "and strips their invented second lines" do
      words = text(tree(mount_screen(Stats)))

      for row <- Sample.more_numbers(), row.title != "Recently watched" do
        refute words =~ row.sub,
               "#{row.title} still reports #{inspect(row.sub)}, which nothing in this app " <>
                 "can ask for"
      end
    end

    test "every `More numbers` row still opens the screen it names" do
      # Kept rows have to be live ones: a row drawn on an empty page and wired to
      # nothing is a worse lie than the figure it lost.
      socket = mount_screen(Stats).socket

      for {title, module} <- [
            {"Activity log", Kati.Screens.Activity},
            {"Habits", Kati.Screens.Habits},
            {"Nutrition", Kati.Screens.Health},
            {"Goals", Kati.Screens.Goals},
            {"Money", Kati.Screens.Money}
          ] do
        {:noreply, moved} = Stats.handle_tap(String.to_atom("go_" <> title), socket)

        assert moved.__mob__.nav_action == {:push, module, %{}},
               "the #{title} row does not open #{inspect(module)} on an empty database"
      end
    end

    test "the share disc is still wired, per board 101's fifth band" do
      socket = mount_screen(Stats).socket
      {:noreply, moved} = Stats.handle_tap(:share_year, socket)

      assert moved.__mob__.nav_action == {:push, Kati.Screens.YearShare, %{}}
    end

    test "the drawing's figures are still the ones being refuted" do
      # Every `refute` above reads its string out of `Kati.Stats.Sample`. If that
      # module stopped holding these, the refutes would be claims about strings
      # nothing was ever going to draw, and this whole file would pass over a
      # screen still full of them.
      year = Sample.year()

      assert year.time == "312h 40m"
      assert year.change == "18%"
      assert year.streak == "longest streak — 11 nights"
      assert year.counts == [{"84", "Films"}, {"19", "Series"}, {"4.1", "Avg ★"}]
      assert length(year.breakdown) == 5
      assert length(Sample.more_numbers()) == 6

      # And they are still the drawing's, not just the sample module's.
      drawn = File.read!(Path.join(__DIR__, "../design/screens/07.html"))
      assert drawn =~ "312h 40m"
      assert drawn =~ "1,204 entries"
    end
  end

  describe "the same screen once one thing has been watched" do
    setup :one_watch

    test "comes back whole — so the empty state is a branch and not a deletion" do
      tree = tree(mount_screen(Stats))
      words = text(tree)

      # 96 minutes, this year, today.
      assert Stats.figures()[:year].time == "1h 36m"
      assert words =~ "1h 36m"
      assert words =~ String.upcase("Where the hours went")
      assert words =~ String.upcase("Recently watched")
      assert words =~ "Harbour"

      assert length(find_all(tree, :box, width: 8, height: 8)) == 182

      # The empty card is gone the moment there is something to count — the
      # sentence, the headline, and the tile that leaves the dock's lone copy of
      # the glyph behind.
      refute words =~ @headline
      refute words =~ @sentence
      assert length(find_all(tree, :text, text: Kati.Icons.glyph("bar_chart_4_bars"))) == 1
    end

    test "and the `More numbers` second lines come back with it" do
      words = text(tree(mount_screen(Stats)))

      for row <- Sample.more_numbers(), row.title != "Recently watched" do
        assert words =~ row.sub
      end
    end
  end

  # ── fixtures ───────────────────────────────────────────────────────────────

  defp empty_the_tables! do
    for table <- @tables,
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  defp month(n), do: n |> Kati.Time.month_name() |> String.slice(0, 3)

  defp one_watch(_context) do
    source_id = "stats-empty:#{System.unique_integer([:positive])}"

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      title: "Harbour",
      poster_path: "harbour86",
      runtime_minutes: 96,
      fetched_at: Kati.Time.now()
    })
    |> Ash.create!()

    tracked =
      TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: source_id,
        kind: :movie,
        status: :watching,
        rating: 8
      })
      |> Ash.create!()

    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      watched_on: Kati.Time.today(),
      watched_at: DateTime.add(Kati.Time.now(), -30 * 60, :second)
    })
    |> Ash.create!()

    :ok
  end
end
