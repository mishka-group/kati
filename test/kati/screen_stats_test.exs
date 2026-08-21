defmodule Kati.ScreenStatsTest do
  @moduledoc """
  Screen 07's year, computed from `Kati.Media` instead of read off
  `Kati.Stats.Sample`.

  The fixture is four watches this year and one last year, chosen so that every
  figure on the card has a hand-checkable answer:

      title            kind    runtime   watched on      watched at
      The Long Hollow  :tv       47      today           2 hours ago
      The Long Hollow  :tv       47      40 days ago     40 days ago
      Blue Hour        :movie   112      yesterday       26 hours ago
      Marram           :tv       50      3 days ago      3 days ago
      Blue Hour        :movie   112      a year ago      a year ago

  So the year is 47+47+112+50 = 256 minutes, the shelf holds one film and two
  series, and the three newest watches are exactly the three the drawing's own
  `recent/0` lists — same episode labels, same `2h ago` / `yesterday` /
  `3 days ago`. That last agreement is the point: the assertions compare against
  `Kati.Screens.Stats.recent/0` itself, so a change to how the meta line is
  built fails against the drawing rather than against a literal typed here.

  Dates and instants are set separately and on purpose. Everything date-shaped
  — the grid, the streak, the year totals — reads `watched_on`, and everything
  clock-shaped reads `watched_at`; deriving the dates from the instants instead
  would make this module fail for the two hours either side of midnight.

  ## What is deliberately still the drawing's

  `Where the hours went` and `More numbers` are asserted to be *unchanged* from
  `Kati.Stats.Sample`, because they are stand-ins and the screen says so. That
  is a real assertion: it fails the day someone wires a genre breakdown to
  `CachedTitle.genres`, which is the free-text column the moduledoc refuses to
  parse, and it fails without anyone having to remember to come back here.

  ## The shared database

  One SQLite file for the whole suite (see `test/test_helper.exs`), so an empty
  history has to be made rather than assumed — and left behind, or
  `Kati.ScreenDesignLiteralTest` would mount screen 07 over this module's four
  watches and find none of the drawing's copy.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Stats
  alias Kati.Stats.Sample

  # Child first: a watch carries the foreign key to a tracked title.
  @tables ~w(media_watches tracked_titles cached_titles)

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "an empty history" do
    test "answers with the drawing's own figures" do
      figures = Stats.figures()

      assert figures[:grid] == Sample.contributions()
      assert figures[:recent] == Stats.recent()
      assert Map.delete(figures[:year], :rising?) == Sample.year()

      # The pill's arrow is a state the sample module has no field for, and the
      # drawing has it pointing up.
      assert figures[:year].rising? == true
    end

    test "renders every figure frame 07 draws" do
      words = text(tree(mount_screen(Stats)))
      year = Sample.year()

      assert words =~ year.range
      assert words =~ year.time
      assert words =~ year.change
      assert words =~ year.streak
      assert words =~ "#{year.weeks} weeks"

      for {number, label} <- year.counts do
        assert words =~ number
        assert words =~ String.upcase(label)
      end

      for {name, _fraction, value, _colour} <- year.breakdown do
        assert words =~ name
        assert words =~ value
      end

      for row <- Stats.recent() do
        assert words =~ row.title
        assert words =~ row.meta
      end
    end

    test "draws 182 squares — 26 weeks of them" do
      squares = find_all(tree(mount_screen(Stats)), :box, width: 8, height: 8)

      assert length(squares) == 182
      assert length(Sample.contributions()) == 182
    end
  end

  describe "a history with watches in it" do
    setup :seed_history

    test "sums this year's runtimes into the headline figure" do
      # 47 + 47 + 112 + 50, and NOT last year's 112.
      assert Stats.figures()[:year].time == "4h 16m"
    end

    test "reads the change against the same span of last year" do
      year = Stats.figures()[:year]

      # 256 against 112 is +128.57%, and it is a rise.
      assert year.change == "129%"
      assert year.rising? == true
    end

    test "counts distinct titles, not ticks" do
      # The Long Hollow is watched twice this year and is one series.
      assert Stats.figures()[:year].counts == [{"1", "Films"}, {"2", "Series"}, {"4.2", "Avg ★"}]
    end

    test "names the longest run of consecutive nights" do
      # Today and yesterday; the other two nights stand alone.
      assert Stats.figures()[:year].streak == "longest streak — 2 nights"
    end

    test "the range and the week count come from the device clock" do
      year = Stats.figures()[:year]
      today = Kati.Time.today()

      assert year.range ==
               "#{month(1)} – #{month(today.month)} #{today.year}"

      assert year.weeks == 26
    end

    test "puts each night in its own square, and leaves the rest empty" do
      grid = Stats.figures()[:grid]

      assert length(grid) == 182
      # Oldest first, so today is the last square.
      assert List.last(grid) == 1
      assert Enum.at(grid, 180) == 1, "yesterday's square is empty"
      assert Enum.at(grid, 179) == 0
      assert Enum.at(grid, 178) == 1, "the watch three days ago has no square"

      # Four nights inside the window; the fifth watch is a year old.
      assert Enum.sum(grid) == 4
      assert Enum.count(grid, &(&1 == 0)) == 178
    end

    test "the three newest watches are the drawing's three, from the domain" do
      assert Stats.figures()[:recent] == Stats.recent()
    end

    test "keeps the breakdown and More numbers as the drawing's own" do
      # Both are stand-ins for domains that do not exist. When one of them
      # starts reading a domain, this is where that shows up.
      assert Stats.figures()[:year].breakdown == Sample.year().breakdown

      words = text(tree(mount_screen(Stats)))

      for row <- Sample.more_numbers(), row.title != "Recently watched" do
        assert words =~ row.title
        assert words =~ row.sub
      end
    end

    test "renders the computed figures, and none of the drawn ones" do
      words = text(tree(mount_screen(Stats)))

      assert words =~ "4h 16m"
      assert words =~ "129%"
      assert words =~ "longest streak — 2 nights"
      assert words =~ "The Long Hollow"
      assert words =~ "S2 E5 · 2h ago"

      # `312h 40m` and `11 nights` are the drawing's and are not in this
      # database. A screen that fell back would still draw a headline figure,
      # a change pill and a streak line, and pass every count above.
      refute words =~ "312h 40m"
      refute words =~ "11 nights"
      refute words =~ "18%"
    end

    test "draws one filled star per whole point of the night's rating" do
      # 10, 8 and 8 on the ten-point scale — five, four and four glyphs.
      stars = find_all(tree(mount_screen(Stats)), :text, text: Kati.Icons.glyph("star"))

      assert Enum.map(Stats.figures()[:recent], & &1.stars) == [5, 4, 4]
      assert length(stars) == 13
    end
  end

  describe "a watch with no rating at all" do
    setup do
      title = title!("Harbour", :movie, "harbour86", 96, nil)
      watch!(title, %{watched_on: Kati.Time.today(), watched_at: minutes_ago(30)})
      :ok
    end

    test "draws no stars rather than a range that runs backwards" do
      row = hd(Stats.figures()[:recent])

      assert row.stars == 0
      assert row.meta == "FILM · 30m ago"

      # `1..0` is a decreasing range in Elixir, so the unguarded row drew two.
      assert find_all(tree(mount_screen(Stats)), :text, text: Kati.Icons.glyph("star")) == []
    end

    test "reports the average as absent rather than as nought stars" do
      assert Stats.figures()[:year].counts == [{"1", "Films"}, {"0", "Series"}, {"—", "Avg ★"}]
    end
  end

  describe "ago/1" do
    test "names the distance in the words the drawing uses" do
      assert Stats.ago(minutes_ago(0)) == "just now"
      assert Stats.ago(minutes_ago(40)) == "40m ago"
      # The drawing's own top row.
      assert Stats.ago(minutes_ago(120)) == "2h ago"
      assert Stats.ago(minutes_ago(26 * 60)) == "yesterday"
      assert Stats.ago(minutes_ago(3 * 1440)) == "3 days ago"
      assert Stats.ago(minutes_ago(9 * 1440)) == "1 week ago"
      assert Stats.ago(minutes_ago(20 * 1440)) == "2 weeks ago"
      assert Stats.ago(minutes_ago(40 * 1440)) == "1 month ago"
      assert Stats.ago(minutes_ago(200 * 1440)) == "6 months ago"
    end
  end

  # ── fixtures ───────────────────────────────────────────────────────────────

  defp empty_the_tables! do
    for table <- @tables,
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  defp month(n), do: n |> Kati.Time.month_name() |> String.slice(0, 3)

  defp minutes_ago(minutes), do: DateTime.add(Kati.Time.now(), -minutes * 60, :second)

  defp seed_history(_context) do
    today = Kati.Time.today()

    hollow = title!("The Long Hollow", :tv, "hollow71", 47, 9)
    blue = title!("Blue Hour", :movie, "bluehour58", 112, 8)
    marram = title!("Marram", :tv, "marram15", 50, 8)

    watch!(hollow, %{
      season_number: 2,
      episode_number: 5,
      episode_source_id: "ep-2205",
      watched_on: today,
      watched_at: minutes_ago(120),
      rating: 10
    })

    # Far enough back to be outside the grid's 26 weeks? No — 40 days is inside
    # it, and outside the "three newest" the card shows. Both are deliberate.
    watch!(hollow, %{
      season_number: 2,
      episode_number: 4,
      episode_source_id: "ep-2204",
      watched_on: Date.add(today, -40),
      watched_at: minutes_ago(40 * 1440)
    })

    # A whole-title watch: no episode to number, so the meta line says FILM.
    watch!(blue, %{watched_on: Date.add(today, -1), watched_at: minutes_ago(26 * 60)})

    watch!(marram, %{
      season_number: 1,
      episode_number: 8,
      episode_source_id: "ep-1108",
      watched_on: Date.add(today, -3),
      watched_at: minutes_ago(3 * 1440)
    })

    # Last year, inside the same span of months — the half of the change pill
    # that is not this year.
    watch!(blue, %{
      watched_on: Date.add(today, -365),
      watched_at: DateTime.add(Kati.Time.now(), -365 * 86_400, :second)
    })

    :ok
  end

  defp title!(title, kind, seed, runtime, rating) do
    source_id = "stats:#{System.unique_integer([:positive])}"

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: title,
      # `Kati.Seeds` stores the design's seed here, so a renderer can resolve
      # the artwork through `Kati.Design.Images.poster/1`.
      poster_path: seed,
      runtime_minutes: runtime,
      fetched_at: Kati.Time.now()
    })
    |> Ash.create!()

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching,
      rating: rating
    })
    |> Ash.create!()
  end

  defp watch!(tracked, attrs) do
    Watch
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{tracked_title_id: tracked.id}, attrs)
    )
    |> Ash.create!()
  end
end
