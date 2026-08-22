defmodule Kati.ScreenLibraryShelfTest do
  @moduledoc """
  Screen 03's grid, against `Kati.Media` and against an empty database.

  ## Why this is not covered by the sweeps

  `Kati.ScreenRenderSweepTest` mounts the screen once and asserts it renders;
  `Kati.ScreenTapSweepTest` taps what that render drew. Neither looks at the
  copy, so a shelf that queried the wrong table, dropped every row, or drew nine
  identical blank tiles would pass both. `Kati.ScreenDesignLiteralTest` does read
  the copy, but screen 03's drawing templates its whole grid — `{{ it.title }}`,
  `{{ it.meta }}`, `{{ libSubtitle }}`, `{{ t.count }}` — so the extractor yields
  no title, no subtitle and no chip count for it at all. Every string this screen
  puts under a poster is therefore checked here or nowhere.

  So each assertion is a count or an exact string, both ways round:

    * **empty database** — the nine titles `Kati.Library.Sample` holds, in its
      order, with the mono line and the chip counts the design draws. This is the
      half that keeps the screen comparable with `.scratch/design/audit/03.png`
      on a machine that has never synced anything.
    * **rows present** — the user's own shelf, and *none* of the drawn nine. A
      fallback that fired when it should not is exactly as wrong as one that
      never fires, and asserting only the first half would not notice.

  ## The wipe in `setup`

  The suite shares one SQLite file (see `test/test_helper.exs`), so "an empty
  database" has to be made rather than assumed — and what this module writes is
  not inert either: `Kati.Screens.Library` now reads `tracked_titles`, so a row
  left behind would put a stranger's title on the grid the moment another
  module mounts the screen. Same reasoning, and the same `on_exit`, as
  `Kati.SeedsTest`.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Library.Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Library

  # Child first: a watch carries the foreign key.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles)

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  # One library row: the durable half, the evictable half, and the ticks the
  # episode counter is derived from. `cached: nil` is the evicted title.
  defp track!(source_id, tracked_attrs, cached_attrs, ticks \\ 0) do
    if cached_attrs do
      CachedTitle
      |> Ash.Changeset.for_create(
        :create,
        Map.merge(
          %{source: :tmdb, source_id: source_id, kind: :tv, fetched_at: DateTime.utc_now()},
          cached_attrs
        )
      )
      |> Ash.create!()
    end

    tracked =
      TrackedTitle
      |> Ash.Changeset.for_create(
        :create,
        Map.merge(%{source: :tmdb, source_id: source_id, kind: :tv}, tracked_attrs)
      )
      |> Ash.create!()

    for n <- 1..ticks//1 do
      Watch
      |> Ash.Changeset.for_create(:create, %{
        tracked_title_id: tracked.id,
        episode_source_id: "#{source_id}-ep#{n}"
      })
      |> Ash.create!()
    end

    tracked
  end

  # The five rows the "rows present" block expects to see drawn, plus three it
  # expects to see withheld. Written as one function so every test in that block
  # is looking at the same shelf.
  defp a_library! do
    track!(
      "lib-hollow",
      %{status: :watching},
      %{kind: :tv, title: "Northlight Bay", episode_count: 10},
      5
    )

    track!(
      "lib-paper",
      %{kind: :movie, status: :watching, progress_seconds: 3000},
      %{kind: :movie, title: "Paper Cities", runtime_minutes: 100}
    )

    track!(
      "lib-under",
      %{status: :finished},
      %{kind: :tv, title: "Undertow", episode_count: 6},
      6
    )

    track!("lib-low", %{status: :not_started}, %{kind: :tv, title: "Low Water", episode_count: 4})

    # A currently-airing series: the provider declines to say how many episodes
    # there are, so there is a numerator and no denominator.
    track!("lib-ferry", %{status: :watching}, %{kind: :tv, title: "The Ferry Road"}, 3)

    # The three that must never reach the grid.
    track!("lib-hidden", %{status: :watching, archived: true}, %{kind: :tv, title: "Hidden Coast"})

    track!("lib-ghost", %{status: :watching}, nil, 2)
    track!("lib-salt", %{kind: :book, status: :watching}, %{kind: :book, title: "Saltings"})
  end

  defp titles_drawn(tree) do
    tree
    |> tile_columns()
    |> Enum.map(fn tile ->
      tile |> find_all(:text) |> hd() |> Map.fetch!(:props) |> Map.fetch!(:text)
    end)
  end

  # Every grid tile, in the order the grid lays them out. A tile is the one node
  # that carries both `weight: 1.0` and the tap that opens its title; the short
  # last row's padding is a childless `<Box weight={1.0} />` and is excluded by
  # the tap, which is also what makes this a check on the film/series routing.
  defp tile_columns(tree) do
    find_all(tree, :column, weight: 1.0, on_tap: {self(), :open_series}) ++
      find_all(tree, :column, weight: 1.0, on_tap: {self(), :open_film})
  end

  defp subtitle_of(tree) do
    tree
    |> find_all(:text, font_family: "mono", text_size: 11)
    |> Enum.map(& &1.props.text)
    |> List.first()
  end

  describe "an empty database" do
    test "the shelf is empty and the screen still draws the design's nine titles" do
      assert Library.shelf() == [],
             "the shelf answered rows against an empty database, so nothing below " <>
               "is measuring the fallback"

      drawn = Library.titles()

      assert length(drawn) == 9,
             "expected the drawing's nine titles, got #{length(drawn)}"

      assert Enum.map(drawn, & &1.title) == Enum.map(Sample.titles(), & &1.title)
      assert Enum.map(drawn, & &1.seed) == Enum.map(Sample.titles(), & &1.seed)
      assert Enum.map(drawn, & &1.progress) == Enum.map(Sample.titles(), & &1.progress)
      assert Enum.map(drawn, & &1.kind) == Enum.map(Sample.titles(), & &1.kind)
    end

    test "every one of them reaches the rendered tree, once each" do
      tree = tree(mount_screen(Library))

      for %{title: title} <- Sample.titles() do
        assert length(find_all(tree, :text, text: title)) == 1,
               "#{inspect(title)} is drawn #{length(find_all(tree, :text, text: title))} times, " <>
                 "not once"
      end

      assert length(tile_columns(tree)) == 9

      # Five series and four films, and the tap routing is what says which:
      # the design draws a film and a series as two different screens.
      assert length(find_all(tree, :column, weight: 1.0, on_tap: {self(), :open_series})) == 5
      assert length(find_all(tree, :column, weight: 1.0, on_tap: {self(), :open_film})) == 4
    end

    test "each poster is the photograph the drawing uses for that title" do
      tree = tree(mount_screen(Library))
      images = find_all(tree, :image, height: 158)

      assert length(images) == 9,
             "#{length(images)} posters for nine titles. An <Image> with an unknown " <>
               "prop renders as nothing and says nothing, so the count is the only " <>
               "evidence the artwork is there."

      for %{seed: seed} <- Sample.titles() do
        assert Enum.any?(images, &String.contains?(&1.props.src, seed)),
               "no poster on the grid came from #{seed}"
      end
    end

    test "the subtitle and the chip counts are the ones the Sample module produced" do
      titles = Library.titles()

      assert Library.subtitle(titles) == Sample.subtitle()
      assert Library.subtitle(titles) == "9 titles · 4 in progress"
      assert Library.chip_counts(titles) == Sample.chips()

      assert Library.chip_counts(titles) == [
               {"All", 9},
               {"Watching", 4},
               {"Not started", 3},
               {"Finished", 2}
             ]

      assert subtitle_of(tree(mount_screen(Library))) == "9 titles · 4 in progress"
    end

    test "the mono line under each tile is the one the fraction spells out" do
      tree = tree(mount_screen(Library))

      # Every drawn state, read off the design's own progress values rather
      # than typed in twice.
      for %{title: title, progress: progress} <- Sample.titles() do
        expected =
          cond do
            progress <= 0.0 -> "not started"
            progress >= 1.0 -> "finished"
            true -> "#{round(progress * 100)}% watched"
          end

        assert Library.tile_meta(%{
                 status: status_for(progress),
                 progress: progress
               }) == expected

        assert find(tree, :text, text: expected) != nil,
               "#{inspect(title)}'s line (#{inspect(expected)}) is nowhere in the tree"
      end

      # All three states are exercised, so none of the branches above is dead.
      assert length(find_all(tree, :text, text: "not started")) == 3
      assert length(find_all(tree, :text, text: "finished")) == 2
      assert length(find_all(tree, :text, text: "62% watched")) == 1
    end

    test "each chip filters the grid to its own count" do
      view = mount_screen(Library)

      # The drawing's own four counts, written out. Reading them back off
      # `chip_counts/1` would let an empty shelf agree with itself.
      for {label, count} <- [{"All", 9}, {"Watching", 4}, {"Not started", 3}, {"Finished", 2}] do
        filtered = render_info(view, {:tap, String.to_atom("filter_" <> label)})

        assert assigns(filtered).filter == label

        assert length(tile_columns(tree(filtered))) == count,
               "the #{inspect(label)} chip should leave #{count} tiles and the grid drew " <>
                 "#{length(tile_columns(tree(filtered)))}"
      end
    end

    test "Books and Music are drawn, and empty" do
      view = mount_screen(Library)

      for shelf <- ["Books", "Music"] do
        switched = render_info(view, {:tap, String.to_atom("shelf_" <> shelf)})

        assert assigns(switched).shelf == shelf
        assert tile_columns(tree(switched)) == []
      end
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Library), extra: [:anchored])
    end
  end

  describe "a library with rows in it" do
    setup do
      a_library!()
      :ok
    end

    test "the grid draws the user's titles and none of the drawing's" do
      tree = tree(mount_screen(Library))

      for title <- ["Northlight Bay", "Paper Cities", "Undertow", "Low Water", "The Ferry Road"] do
        assert length(find_all(tree, :text, text: title)) == 1,
               "#{inspect(title)} is on the shelf and not on the grid"
      end

      for %{title: drawn} <- Sample.titles() do
        assert find(tree, :text, text: drawn) == nil,
               "the fallback fired over a shelf that has rows: #{inspect(drawn)} is drawn"
      end

      assert length(tile_columns(tree)) == 5
    end

    test "the shelf is ordered newest touch first" do
      assert Enum.map(Library.shelf(), & &1.title) == [
               "The Ferry Road",
               "Low Water",
               "Undertow",
               "Paper Cities",
               "Northlight Bay"
             ]

      assert titles_drawn(tree(mount_screen(Library))) |> Enum.take(1) == ["The Ferry Road"]
    end

    test "an archived title, an evicted one and a book stay off the Screen shelf" do
      tree = tree(mount_screen(Library))

      assert find(tree, :text, text: "Hidden Coast") == nil,
             "an archived title is on the shelf it is archived from"

      assert find(tree, :text, text: "Saltings") == nil,
             "a book is on the Screen shelf"

      # The evicted row has no title to draw at all, so the proof it was dropped
      # is the tile count: five drawn out of eight tracked rows.
      assert length(Ash.read!(TrackedTitle)) == 8
      assert length(Library.shelf()) == 5

      assert Enum.all?(Library.shelf(), &(&1.title != nil)),
             "a tile with no name reached the grid"
    end

    test "progress is derived, never invented" do
      by_title = Map.new(Library.shelf(), &{&1.title, &1})

      # Five ticks of ten episodes. The counter is the ticks, not
      # `progress_episode` — Kati.Media.TrackedTitle is explicit about that.
      assert by_title["Northlight Bay"].progress == 0.5
      assert Library.tile_meta(by_title["Northlight Bay"]) == "50% watched"

      # A film has no episode denominator at all, so it is the resume point over
      # the runtime: 3000s of 100 minutes.
      assert by_title["Paper Cities"].progress == 0.5
      assert Library.tile_meta(by_title["Paper Cities"]) == "50% watched"

      assert by_title["Undertow"].progress == 1.0
      assert Library.tile_meta(by_title["Undertow"]) == "finished"

      assert by_title["Low Water"].progress == 0.0
      assert Library.tile_meta(by_title["Low Water"]) == "not started"

      # The airing series: three ticks and no total. It must not become "300%",
      # and it must not become a number at all.
      assert by_title["The Ferry Road"].progress == nil
      assert Library.tile_meta(by_title["The Ferry Road"]) == "watching"
      assert Library.fraction(by_title["The Ferry Road"]) == 0.0

      tree = tree(mount_screen(Library))
      assert length(find_all(tree, :text, text: "50% watched")) == 2
      assert length(find_all(tree, :text, text: "watching")) == 1
    end

    test "the subtitle and the chip counts come off the shelf, not the Sample" do
      titles = Library.titles()

      assert Library.subtitle(titles) == "5 titles · 3 in progress"
      assert subtitle_of(tree(mount_screen(Library))) == "5 titles · 3 in progress"

      assert Library.chip_counts(titles) == [
               {"All", 5},
               {"Watching", 3},
               {"Not started", 1},
               {"Finished", 1}
             ]
    end

    test "each chip filters the user's shelf to its own count" do
      view = mount_screen(Library)

      # The counts are written out rather than read back off `chip_counts/1`:
      # a shelf that lost its rows would agree with its own chip labels
      # perfectly, and this is the assertion that would still notice.
      for {label, count} <- [{"All", 5}, {"Watching", 3}, {"Not started", 1}, {"Finished", 1}] do
        filtered = render_info(view, {:tap, String.to_atom("filter_" <> label)})

        assert length(tile_columns(tree(filtered))) == count,
               "the #{inspect(label)} chip should leave #{count} tiles and the grid drew " <>
                 "#{length(tile_columns(tree(filtered)))}"
      end
    end

    test "a title whose artwork is a provider path draws the placeholder, not a broken image" do
      # `poster_path` on a real row is a TMDB path, which is not a design seed,
      # so `Kati.Design.Images.poster/1` answers nil and the tile falls back to
      # the grey rectangle the grid already draws under every poster.
      tree = tree(mount_screen(Library))

      assert find_all(tree, :image, height: 158) == [],
             "a provider path resolved to a sample photograph, which means the " <>
               "artwork lookup is matching something it should not"

      assert length(tile_columns(tree)) == 5,
             "the tiles vanished with their artwork"
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Library), extra: [:anchored])
    end
  end

  # The status a Sample row's fraction stands for. Mirrors the mapping
  # `Kati.Screens.Library.drawn_titles/0` makes, and is written out here so the
  # test would notice if that mapping changed.
  defp status_for(progress) do
    cond do
      progress <= 0.0 -> :not_started
      progress >= 1.0 -> :finished
      true -> :watching
    end
  end
end
