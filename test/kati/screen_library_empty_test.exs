defmodule Kati.ScreenLibraryEmptyTest do
  @moduledoc """
  Screen 03 on a fresh device: the emptiness the design draws, and no films.

  ## What this file is for

  #91's criterion is *"every root screen shows a real empty state, not sample
  rows, on a fresh device"*, and the report behind it is one sentence from the
  person who installed the app on his own phone: *"you all show dummy data and
  it is not connected to database"*. Screen 03 was the clearest case —
  `Kati.Screens.Library.titles/0` answered an empty shelf with
  `drawn_titles/0`, nine invented films and series out of
  `Kati.Library.Sample`, drawn in exactly the shape and colour a real shelf is
  drawn in.

  ## Why presence alone would not settle it

  A test that only asserts *No titles yet* is somewhere in the tree passes on a
  screen that draws the card **and** the nine posters — which is precisely what
  a half-finished version of this change looks like, and precisely what screen
  27 itself draws, since a reference sheet shows an empty state beside a full
  library on purpose. So every block below is a pair: the empty state's own
  nodes are present **and** the sample content is absent, asserted by name.

  The absence half is written against `Kati.Library.Sample` rather than against
  nine typed strings, so an edit to the fixture cannot quietly walk out from
  under it.

  ## Where the copy comes from

  Not from this file. Every string the card draws is read back out of
  `test/design/screens/27.html` — the artboard that draws this screen's
  emptiness, under the band `Empty — nothing added yet` — so the words on the
  device and the words in the drawing cannot drift apart without this going
  red. A test that typed the copy twice would let them.

  ## The wipe in `setup`

  The suite shares one SQLite file (see `test/test_helper.exs`), so "a fresh
  device" has to be made rather than assumed. Same tables, same `on_exit` and
  same reasoning as `Kati.ScreenLibraryShelfTest`, which is the file that
  covers the other half — a shelf with rows in it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Library.Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Library

  # Child first: a watch carries the foreign key.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles)

  # The artboard that draws screen 03's empty state. Screen 03 itself draws a
  # full shelf and templates every string in it; the emptiness is drawn here.
  @artboard "test/design/screens/27.html"

  # The card's four strings, and the one glyph on it, exactly as 27 draws them.
  # Each is asserted to be in the artboard before it is asserted to be on the
  # screen — see `the card's copy is the artboard's, not this file's`.
  @title "No titles yet"
  @body "Add one thing you are watching and the calendar starts filling itself."
  @action "Add a title"
  @secondary "or import a backup"
  @glyph_name "movie"

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  defp texts(tree) do
    tree
    |> find_all(:text)
    |> Enum.map(&(&1.props[:text] || ""))
  end

  # One tracked title with a cache row, so the "a shelf with rows" block can
  # prove the empty state does not fire over real data.
  defp track!(source_id, title) do
    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: title,
      episode_count: 6,
      fetched_at: DateTime.utc_now()
    })
    |> Ash.create!()

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching
    })
    |> Ash.create!()
  end

  describe "the read itself" do
    test "titles/0 answers with nothing, and does not reach the Sample module" do
      assert Library.shelf() == []

      assert Library.titles() == [],
             "titles/0 answered #{length(Library.titles())} rows against an empty database. " <>
               "That is the defect #91 reports: the fallback to Kati.Library.Sample is back."

      # The fixture is untouched and still holds nine — so the assertion above
      # is about the screen's read and not about an emptied Sample module.
      assert length(Sample.titles()) == 9
      assert length(Library.drawn_titles()) == 9
    end
  end

  describe "a fresh device" do
    test "the card's copy is the artboard's, not this file's" do
      artboard = File.read!(@artboard)

      assert artboard =~ "Empty &mdash; nothing added yet",
             "#{@artboard} no longer carries the band this screen's empty state is drawn under"

      for literal <- [@title, @body, @action, @secondary] do
        assert artboard =~ literal,
               "#{inspect(literal)} is not in #{@artboard} any more, so asserting the screen " <>
                 "draws it is asserting nothing about the design"
      end
    end

    test "the empty state is drawn, word for word" do
      drawn = texts(tree(mount_screen(Library)))

      for literal <- [@title, @body, @action, @secondary] do
        assert Enum.count(drawn, &(&1 == literal)) == 1,
               "#{inspect(literal)} is drawn #{Enum.count(drawn, &(&1 == literal))} times on a " <>
                 "fresh device, not once"
      end
    end

    test "the paper tile carries the movie glyph the artboard puts on it" do
      tree = tree(mount_screen(Library))
      glyph = Kati.Icons.glyph!(@glyph_name)

      tile =
        find(tree, :box,
          width: 64,
          height: 64,
          corner_radius: 20,
          background: Kati.Theme.Palette.paper()
        )

      assert tile != nil, "the 64pt paper square screen 27 heads the card with is not drawn"

      assert find(tile, :text, text: glyph) != nil,
             "the tile is drawn and #{@glyph_name} is not in it"
    end

    test "not one of the nine invented titles reaches the tree" do
      drawn = texts(tree(mount_screen(Library)))

      for %{title: invented} <- Sample.titles() do
        refute invented in drawn,
               "#{inspect(invented)} is on a fresh device's Library. It is a film nobody " <>
                 "added, and drawing it is the whole of #91."
      end
    end

    test "no poster, no progress rail and no per-title mono line is drawn" do
      tree = tree(mount_screen(Library))

      assert find_all(tree, :image, height: 158) == [],
             "a poster is drawn on a shelf with nothing on it"

      assert find_all(tree, :column, weight: 1.0, on_tap: {self(), :open_film}) == [],
             "a film tile is drawn on a shelf with nothing on it"

      assert find_all(tree, :column, weight: 1.0, on_tap: {self(), :open_series}) == [],
             "a series tile is drawn on a shelf with nothing on it"

      drawn = texts(tree)

      # `tile_meta/1`'s whole vocabulary. Every one of these is a claim about a
      # title, so none of them can be true when there is no title.
      for line <- ["not started", "finished", "watching", "paused", "dropped"] do
        refute line in drawn, "#{inspect(line)} is drawn with nothing on the shelf to be it"
      end
    end

    test "the four zero chips are not drawn, and the count line still is" do
      tree = tree(mount_screen(Library))
      drawn = texts(tree)

      # Screen 96: "hides the delta badge, the per-service rows and the
      # Worth-a-look card entirely — a 'down 0%' chip would be noise". The
      # board templates these four, so hiding them drops no drawn value.
      for chip <- ["All", "Watching", "Not started", "Finished"] do
        refute chip in drawn, "the #{inspect(chip)} filter chip is drawn with nothing to filter"
      end

      # The subtitle is the opposite case and is asserted here so the two
      # cannot be confused for each other again: `03.html` draws an 11pt mono
      # line 5pt under the 28pt title, `Kati.ScreenTitleSubtitleTest` reads
      # that off the board as the spec, and a drawn line outranks an inference
      # about zeros.
      assert "0 titles · 0 in progress" in drawn

      assert find(tree, :text, font_family: "mono", text_size: 11) != nil,
             "the board's mono line under the title went missing with the shelf"
    end

    test "the parts that still work are still drawn" do
      # Screen 139's rule for an empty board: it "states which parts still
      # work, because an empty Home that looks broken sends a new user back
      # out". Books and Music are separate domains, and Discover and Lists do
      # not need a shelf.
      drawn = texts(tree(mount_screen(Library)))

      for literal <- ["Library", "Screen", "Books", "Music", "Up next", "Discover", "Lists"] do
        assert literal in drawn,
               "#{inspect(literal)} is drawn on screen 03 and vanished with the shelf"
      end
    end

    test "both controls on the card go somewhere" do
      view = mount_screen(Library)

      assert navigated_to(render_info(view, {:tap, :add_title})) == Kati.Screens.AddTitle,
             "the one thing that ends this state has to be the thing the ink pill opens"

      assert navigated_to(render_info(view, {:tap, :import_backup})) == Kati.Screens.Restore
    end

    test "each of the card's two tags names exactly one node" do
      # `Mob.Renderer` derives an `accessibility_id` from every atom `on_tap`,
      # and Compose's `onNodeWithTag` throws on a second match — so a tag drawn
      # twice is a control no device test can address. This is the check
      # `Kati.ScreenTapSweepTest` makes across the app, asked of the two nodes
      # this change added.
      tree = tree(mount_screen(Library))

      assert length(find_all(tree, :row, on_tap: {self(), :add_title})) == 1
      assert length(find_all(tree, :column, on_tap: {self(), :import_backup})) == 1
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Library), extra: [:anchored])
    end
  end

  describe "a shelf with one row on it" do
    setup do
      track!("lib-empty-guard", "Northlight Bay")
      :ok
    end

    test "the empty state stands down and the grid comes back" do
      drawn = texts(tree(mount_screen(Library)))

      assert "Northlight Bay" in drawn

      for literal <- [@title, @body, @action, @secondary] do
        refute literal in drawn,
               "#{inspect(literal)} is drawn over a shelf that has a title on it"
      end

      assert "1 titles · 1 in progress" in drawn,
             "the mono subtitle is withheld only while there is nothing to count"

      for chip <- ["All", "Watching", "Not started", "Finished"] do
        assert chip in drawn, "the #{inspect(chip)} chip did not come back with the shelf"
      end
    end

    test "a filter that matches nothing empties the grid without claiming the shelf is empty" do
      # The design draws no state for "this filter matches none of your nine",
      # so the screen does what it always did: an empty grid under live chips
      # whose counts say which one to tap next. Putting *No titles yet* here
      # would be a second untruth in place of the first.
      view = render_info(mount_screen(Library), {:tap, :"filter_Not started"})
      drawn = texts(tree(view))

      assert assigns(view).filter == "Not started"
      assert find_all(tree(view), :column, weight: 1.0, on_tap: {self(), :open_series}) == []

      refute @title in drawn,
             "the shelf holds a title; a filter matching none of it is not an empty library"

      assert "1 titles · 1 in progress" in drawn
    end
  end
end
