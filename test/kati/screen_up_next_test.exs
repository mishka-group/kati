defmodule Kati.ScreenUpNextTest do
  @moduledoc """
  Screen 10 reading `Kati.Media` instead of `Kati.Screens.UpNext.Sample`.

  Three claims, and they are separate:

    * **With rows, the screen draws the rows.** Every line of the fixture is a
      column — the section a title is in is its `status`, `S2 · E6` is
      `progress_season`/`progress_episode`, `18M LEFT` is `progress_seconds`
      against `runtime_minutes`, the poster is `poster_path`. So each assertion
      names the string the drawing gives that line, and the negative assertions
      name titles that are *only* in the sample module: a screen that quietly
      fell back would still render four ready rows and pass a bare count.
    * **With none, it still draws the drawing.** This screen is the reference
      for frame 10 and a fresh install has nothing tracked, so `queue/0` must
      answer `Sample.queue/0` *whole* — asserted as map equality, not as "some
      titles appeared".
    * **The strings are the same strings.** The fixture is built so the domain
      reproduces two of the sample module's own metas exactly
      (`S2 · E6 · 18M LEFT`, `S2 · E3 · 52m`). If the formatting drifts, those
      two comparisons fail against the sample rather than against a literal
      typed into this file.

  ## The shared database

  `test/test_helper.exs` gives the whole suite one SQLite file, so "an empty
  library" has to be made rather than assumed — the same reason
  `Kati.SeedsTest` empties its tables in `setup`. Both directions matter here:
  the wipe before makes the fallback test mean something, and the wipe after
  keeps `Kati.ScreenDesignLiteralTest` mounting screen 10 against an empty
  library, which is what lets it find the drawing's own copy.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.UpNext
  alias Kati.Screens.UpNext.Sample

  # Child first: a watch carries the foreign key to a tracked title.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles)

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "an empty library" do
    test "answers with the drawing's own queue, whole" do
      assert UpNext.queue() == Sample.queue()
    end

    test "renders every line frame 10 draws" do
      words = text(tree(mount_screen(UpNext)))
      drawn = Sample.queue()

      assert words =~ drawn.subtitle
      # Both eyebrows go through `Kati.UI.eyebrow/2`, which upcases.
      assert words =~ String.upcase(drawn.ready_label)
      assert words =~ String.upcase(drawn.cold_label)
      assert words =~ drawn.hero.title
      assert words =~ drawn.hero.meta

      for row <- drawn.ready do
        assert words =~ row.title, "the drawn ready row #{row.title} is missing"
        assert words =~ row.meta
      end

      for row <- drawn.cold do
        assert words =~ row.title
        assert words =~ row.meta
        assert words =~ row.action
      end
    end

    test "draws one photograph per drawn row, plus the hero still" do
      images = find_all(tree(mount_screen(UpNext)), :image)
      drawn = Sample.queue()

      # The hero at its 700x400 crop, and a 40x56 poster on every other row.
      assert length(images) == 1 + length(drawn.ready) + length(drawn.cold)
      assert Enum.any?(images, &(&1.props[:height] == 170))
      assert Enum.count(images, &(&1.props[:width] == 40)) == 5
    end
  end

  describe "a library with titles in it" do
    setup :seed_library

    test "puts the newest touched watching title in the hero" do
      q = UpNext.queue()

      assert q.hero.title == "The Long Hollow"
      assert q.hero.seed == "hollow71"
    end

    test "builds the hero's meta out of the bookmark and the resume point" do
      q = UpNext.queue()

      # 47 minutes long, 29 of them behind: the drawing's own hero line, arrived
      # at from two columns rather than copied out of the sample module.
      assert q.hero.meta == "S2 · E6 · 18M LEFT"
      assert q.hero.meta == Sample.queue().hero.meta
    end

    test "burns in the fraction those same two numbers give" do
      q = UpNext.queue()

      assert_in_delta q.hero.progress, 1740 / 2820, 0.0001

      # Neither end of the range, because `<Box weight={0.0}>` throws in Compose.
      assert q.hero.progress > 0.0 and q.hero.progress < 1.0
    end

    test "lists the rest of the watching shelf in touch order, newest first" do
      q = UpNext.queue()

      assert Enum.map(q.ready, & &1.title) == ["Marram", "Salt & Iron"]
      assert Enum.map(q.ready, & &1.meta) == ["S2 · E3 · 52m", "S1 · E4 · 41m"]
      assert Enum.map(q.ready, & &1.seed) == ["marram15", "saltiron33"]

      # And the first of those is the sample module's own line for that title.
      marram = Enum.find(Sample.queue().ready, &(&1.title == "Marram"))
      assert hd(q.ready).meta == marram.meta
    end

    test "the cold section is the paused titles, with the drop offer" do
      q = UpNext.queue()

      assert Enum.map(q.cold, & &1.title) == ["The Quiet Ones"]
      assert hd(q.cold).meta == "S1 · E3 · TODAY"
      assert hd(q.cold).action == "Drop"
    end

    test "counts the sections from the shelf, and airing soon from Release" do
      q = UpNext.queue()

      # Three watching rows: the hero plus the two under it. One of the four
      # cached rows carries a `:day` date still ahead; the other future date is
      # a bare year, which `Kati.Media.Release` refuses to name and this
      # therefore refuses to count.
      assert q.subtitle == "3 ready · 1 airing soon"
      assert q.ready_label == "Ready to watch · 2"
      assert q.cold_label == "Gone cold · 1"
    end

    test "leaves out archived, finished and dropped titles" do
      q = UpNext.queue()

      titles = [q.hero.title | Enum.map(q.ready ++ q.cold, & &1.title)]

      refute "Nightbirds" in titles, "an archived title is still on the shelf"
      refute "Harbour" in titles, "a finished title is still on the shelf"
      refute "Vellum" in titles, "a dropped title is still on the shelf"
      assert length(titles) == 4
    end

    test "renders the rows, and none of the sample module's own" do
      words = text(tree(mount_screen(UpNext)))

      assert words =~ "The Long Hollow"
      assert words =~ "S2 · E6 · 18M LEFT"
      assert words =~ "Marram"
      assert words =~ "S2 · E3 · 52m"
      assert words =~ "The Quiet Ones"
      assert words =~ "S1 · E3 · TODAY"
      assert words =~ "READY TO WATCH · 2"

      # `Ashfall` and `The Cartographer` are in the drawn queue and not in this
      # database. A screen that fell back would still draw four ready rows and
      # still pass every count above.
      refute words =~ "Ashfall"
      refute words =~ "The Cartographer"
      refute words =~ "READY TO WATCH · 12"
    end

    test "draws a poster for every row that has one" do
      images = find_all(tree(mount_screen(UpNext)), :image)

      # The hero's 700x400 crop plus three 40x56 posters — two ready, one cold.
      assert length(images) == 4
      assert Enum.count(images, &(&1.props[:width] == 40)) == 3
      assert Enum.any?(images, &(&1.props[:height] == 170))
    end
  end

  describe "a title whose cache row was evicted" do
    setup do
      source_id = track!(%{title: nil, status: :watching, season: 4, episode: 1})
      %{source_id: source_id}
    end

    test "keeps its position and says so, rather than vanishing" do
      q = UpNext.queue()

      assert q.hero.title == "Untitled"
      assert q.hero.seed == nil
      assert q.hero.meta == "S4 · E1"
      assert q.hero.progress == nil
    end

    test "renders without a still and without a bar" do
      tree = tree(mount_screen(UpNext))

      assert text(tree) =~ "Untitled"
      assert text(tree) =~ "S4 · E1"
      assert find_all(tree, :image) == []
    end
  end

  describe "age/1" do
    test "names the distance in the units the drawing uses" do
      now = DateTime.utc_now()

      assert UpNext.age(nil) == "NOT STARTED"
      assert UpNext.age(now) == "TODAY"
      assert UpNext.age(back(now, 1)) == "YESTERDAY"
      assert UpNext.age(back(now, 3)) == "3 DAYS AGO"
      assert UpNext.age(back(now, 9)) == "1 WEEK AGO"
      assert UpNext.age(back(now, 21)) == "3 WEEKS AGO"
      assert UpNext.age(back(now, 40)) == "1 MONTH AGO"
      # The drawing's own cold row.
      assert UpNext.age(back(now, 120)) == "4 MONTHS AGO"
      assert UpNext.age(back(now, 400)) == "1 YEAR AGO"
      assert UpNext.age(back(now, 800)) == "2 YEARS AGO"
    end
  end

  # ── fixtures ───────────────────────────────────────────────────────────────

  defp empty_the_tables! do
    for table <- @tables,
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  defp back(from, days), do: DateTime.add(from, -days * 86_400, :second)

  # Created oldest first: `Kati.Media.Changes.Touch` forces `last_touched_at` to
  # now on every write, so creation order IS shelf order and the last watching
  # row written is the hero. That is the same ordering the shelf uses on the
  # device, exercised rather than stubbed.
  defp seed_library(_context) do
    track!(%{
      title: "Salt & Iron",
      seed: "saltiron33",
      status: :watching,
      season: 1,
      episode: 4,
      runtime: 41,
      # A bare year: displayable, never armable, and never "soon".
      release: {DateTime.add(DateTime.utc_now(), 30 * 86_400, :second), :year}
    })

    track!(%{
      title: "Marram",
      seed: "marram15",
      status: :watching,
      season: 2,
      episode: 3,
      runtime: 52,
      release: {DateTime.add(DateTime.utc_now(), 7 * 86_400, :second), :day}
    })

    track!(%{
      title: "The Long Hollow",
      seed: "hollow71",
      status: :watching,
      season: 2,
      episode: 6,
      runtime: 47,
      # 29 minutes in, so 18 are left — the drawing's own hero line.
      seconds: 1740
    })

    track!(%{
      title: "The Quiet Ones",
      seed: "quietones12",
      status: :paused,
      season: 1,
      episode: 3
    })

    # The three that must not appear anywhere on this screen.
    track!(%{title: "Nightbirds", status: :watching, archived: true})
    track!(%{title: "Harbour", status: :finished})
    track!(%{title: "Vellum", status: :dropped})

    :ok
  end

  # Both halves of one title. The cache row is written only when the fixture
  # names a title — a `nil` title is the evicted case, and there the durable row
  # stands alone exactly as `Kati.Media.CachedTitle`'s moduledoc promises.
  defp track!(attrs) do
    source_id = "upnext:#{System.unique_integer([:positive])}"

    if attrs[:title], do: cache!(source_id, attrs)

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: attrs.status,
      archived: attrs[:archived] || false,
      progress_season: attrs[:season],
      progress_episode: attrs[:episode],
      progress_seconds: attrs[:seconds]
    })
    |> Ash.create!()

    source_id
  end

  defp cache!(source_id, attrs) do
    {release_at, confidence} = attrs[:release] || {nil, :unknown}

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: attrs.title,
      # `Kati.Seeds` puts the design's seed here on purpose, so a renderer can
      # resolve the artwork through `Kati.Design.Images.poster/1`.
      poster_path: attrs[:seed],
      runtime_minutes: attrs[:runtime],
      next_release_at: release_at,
      date_confidence: confidence,
      fetched_at: DateTime.utc_now()
    })
    |> Ash.create!()
  end
end
