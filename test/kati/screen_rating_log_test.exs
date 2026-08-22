defmodule Kati.ScreenRatingLogTest do
  @moduledoc """
  Screen 33 against `Kati.Media.Watch`, and against a database with nothing
  logged in it.

  ## Why the sweeps cannot settle this

  The same gap `Kati.ScreenFilmTest` and `Kati.ScreenEmptyDatabaseTest` set out.
  `Kati.ScreenRenderSweepTest` mounts the sheet and asserts it renders,
  `Kati.ScreenTapSweepTest` taps what it drew, and neither reads a word of it —
  so a sheet that picked the wrong watch, halved the rating the wrong way or
  showed somebody else's review would pass both. `Kati.ScreenDesignLiteralTest`
  does read the copy and still cannot settle it: the suite shares one SQLite
  file with no Ecto sandbox, so which of the two paths ran when that sweep
  rendered screen 33 moves with `--seed`.

  ## The half this file exists for that no other file can ask

  `Kati.ScreenEmptyDatabaseTest` guards the fallback on an **empty** database.
  Screen 33's fallback also fires on a database that is emphatically not empty,
  and that is the case with no other guard: `Kati.Media.Watch` holds a tick and
  a log in one row shape, a tick carries no rating and no review, and a library
  full of ticks therefore has nothing this sheet can draw. `a library of ticks
  is not a log, so the drawing is drawn` is the test that pins it, and it is the
  reason `logged_watch/0` filters rather than taking the newest row outright.

  ## What is deliberately NOT asserted here: a write

  Screen 33 reads. `Kati.Screens.Rating`'s moduledoc gives the reason at length
  — the sheet draws exactly three tap targets and none of them can change a
  value, so a `Save` wired today would write back what it had just read. When
  the write lands, the tests it needs are not these: they are about a changeset,
  and about `Kati.ScreenTapSweepTest` no longer being able to create rows in the
  shared database by tapping `:save` on every run.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Rating.Sample
  alias Kati.Screens.Rating

  # Child first: a watch carries the foreign key.
  @tables ~w(media_watches tracked_titles cached_titles)

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  # What this module writes is not inert: a tracked title left behind is a
  # stranger's row on screen 03's grid and screen 08's page the moment another
  # module mounts either. Same reasoning and the same `on_exit` as
  # `Kati.ScreenFilmTest`.
  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  defp track!(source_id, cached_attrs) do
    if cached_attrs do
      CachedTitle
      |> Ash.Changeset.for_create(
        :create,
        Map.merge(
          %{source: :tmdb, source_id: source_id, kind: :movie, fetched_at: DateTime.utc_now()},
          cached_attrs
        )
      )
      |> Ash.create!()
    end

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      status: :finished
    })
    |> Ash.create!()
  end

  defp watch!(tracked, attrs) do
    Watch
    |> Ash.Changeset.for_create(:create, Map.put(attrs, :tracked_title_id, tracked.id))
    |> Ash.create!()
  end

  # One logged watch, carrying every column the sheet draws. Not one of the
  # drawing's own values is reused, deliberately: a fixture that agreed with the
  # drawing anywhere would let a sheet that never left the fallback pass.
  defp a_logged_watch! do
    tracked = track!("log-paper", %{title: "Paper Cities", runtime_minutes: 100})

    watch!(tracked, %{
      watched_on: ~D[2026-07-04],
      watched_at: ~U[2026-07-04 22:15:00.000000Z],
      rating: 7,
      review: "Rex, back row.",
      contains_spoilers: true,
      rewatch_number: 3,
      service: "Rex",
      place: "back row",
      companions: "Sam",
      tags: "coastal, slow burn"
    })

    tracked
  end

  defp texts(tree), do: tree |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  defp drawn?(tree, string), do: Enum.any?(texts(tree), &(&1 == string))

  defp stars(tree), do: find_all(tree, :text, font_family: "symbols_filled", text_size: 26)

  describe "nothing logged" do
    test "the sheet draws the drawing, to the term" do
      assert Rating.logged_watch() == nil,
             "a watch answered against an empty log, so nothing below is measuring the " <>
               "fallback"

      assert Rating.watch() == Sample.watch(),
             "the fallback is not `Kati.Rating.Sample.watch/0` verbatim, and that fixture " <>
               "is what `.scratch/design/audit/33.png` was captured from"
    end

    test "every string the drawing carries reaches the rendered tree" do
      tree = tree(mount_screen(Rating))
      w = Sample.watch()

      for string <- [w.title, w.meta, w.rewatch, w.spoilers, w.review, w.characters] ++ w.tags do
        assert drawn?(tree, string), "#{inspect(string)} is nowhere in the tree"
      end

      assert drawn?(tree, "4.5"), "the rating beside the stars is not drawn"
      assert drawn?(tree, String.upcase(w.rating_note))

      for %{title: title, sub: sub} <- w.context do
        assert drawn?(tree, title)
        assert drawn?(tree, sub)
      end
    end

    test "a library of ticks is not a log, so the drawing is drawn" do
      # The case no other file can ask: the database is full and the sheet still
      # has nothing of the user's to show. `Kati.Media.Watch` holds a tick and a
      # log in one row shape and a tick carries neither a rating nor a review,
      # so taking the newest row outright would draw an empty sheet here.
      tracked = track!("log-ticked", %{title: "Salt & Iron"})

      watch!(tracked, %{episode_source_id: "ep-1", season_number: 1, episode_number: 1})
      watch!(tracked, %{episode_source_id: "ep-2", season_number: 1, episode_number: 2})

      assert Ash.read!(Watch) != [], "the ticks were not written, so this proves nothing"

      assert Rating.logged_watch() == nil,
             "a tick filled the sheet. It has no rating, no review and no context, so what " <>
               "it fills the sheet with is five empty cards"

      assert Rating.watch() == Sample.watch()
    end

    test "a review of nothing but whitespace is not a log either" do
      tracked = track!("log-blank", %{title: "Low Water"})
      watch!(tracked, %{review: "", watched_on: ~D[2026-07-01]})

      assert Rating.logged_watch() == nil
    end
  end

  describe "with the user's own log" do
    test "the sheet draws that watch and none of the drawn values" do
      a_logged_watch!()

      w = Rating.watch()
      assert w.title == "Paper Cities"
      assert w.meta == "1H 40M"
      assert w.rewatch == "3rd rewatch"
      assert w.rating == 3.5
      assert w.spoilers == "Spoilers hidden"
      assert w.review == "Rex, back row."
      assert w.characters == "14 characters"
      assert w.tags == ["coastal", "slow burn"]

      tree = tree(mount_screen(Rating))

      for string <- ["Paper Cities", "1H 40M", "3rd rewatch", "3.5", "coastal", "slow burn"] do
        assert drawn?(tree, string), "#{inspect(string)} is nowhere in the tree"
      end

      drawn = Sample.watch()

      for string <- [drawn.title, drawn.meta, drawn.rewatch, drawn.review, drawn.characters] do
        refute drawn?(tree, string),
               "#{inspect(string)} is the drawing's, and a real log is being shown"
      end
    end

    test "when, where and who with are the three columns that hold them" do
      a_logged_watch!()

      [when_row, where_row, with_row] = Rating.watch().context

      # `watched_on` carries the date and `watched_at` the hour, which is the
      # whole reason `Kati.Media.Watch` keeps the two apart.
      assert when_row.sub == "Sat 4 Jul · 22:15"
      assert where_row.sub == "Rex · back row"
      assert with_row.sub == "Sam"
    end

    test "the newest log is the one drawn" do
      tracked = track!("log-two", %{title: "Undertow"})

      watch!(tracked, %{watched_at: ~U[2026-01-01 20:00:00.000000Z], rating: 4, review: "older"})
      watch!(tracked, %{watched_at: ~U[2026-08-01 20:00:00.000000Z], rating: 6, review: "newer"})

      assert Rating.watch().review == "newer"
    end

    test "the year is absent from the meta line, because nothing stores one" do
      a_logged_watch!()

      # `next_release_at` is the NEXT release and would print next Tuesday as a
      # film's year. The same gap `Kati.Screens.Film` records.
      refute Rating.watch().meta =~ ~r/\d{4}/
    end

    test "a rating this screen cannot claim is drawn as five empty stars and a dash" do
      tracked = track!("log-unrated", %{title: "Marram", runtime_minutes: 92})
      watch!(tracked, %{watched_on: ~D[2026-07-04], review: "No score, just words."})

      assert Rating.watch().rating == nil
      assert Rating.rating_label(nil) == "—"

      tree = tree(mount_screen(Rating))
      empties = stars(tree) |> Enum.map(& &1.props.text_color) |> Enum.uniq()

      assert length(stars(tree)) == 5, "an unrated log draws five stars, all of them empty"
      assert empties == [Kati.Theme.Palette.star_empty()], "one of them is filled in the accent"
      assert drawn?(tree, "—")
    end

    test "a whole rating prints without a trailing .0" do
      tracked = track!("log-whole", %{title: "Ashfall"})
      watch!(tracked, %{watched_on: ~D[2026-07-04], rating: 8})

      assert Rating.watch().rating == 4.0
      assert Rating.rating_label(4.0) == "4"
      assert drawn?(tree(mount_screen(Rating)), "4")
    end

    test "a review with no spoilers draws neither the label nor the glyph" do
      tracked = track!("log-clean", %{title: "Harbour"})
      watch!(tracked, %{watched_on: ~D[2026-07-04], rating: 6, review: "Nothing given away."})

      assert Rating.watch().spoilers == nil

      tree = tree(mount_screen(Rating))

      refute drawn?(tree, "Spoilers hidden"),
             "`contains_spoilers` is false, so nothing is hidden and the toggle is asserting " <>
               "the opposite of the sentence beside it"

      refute drawn?(tree, Kati.Icons.glyph!("visibility_off"))
    end

    test "a first watch carries no rewatch badge" do
      tracked = track!("log-first", %{title: "Vellum"})
      watch!(tracked, %{watched_on: ~D[2026-07-04], rating: 6, rewatch_number: 1})

      assert Rating.watch().rewatch == nil,
             "`rewatch_number` of 1 is a first watch, which is not a rewatch"

      refute drawn?(tree(mount_screen(Rating)), "1st rewatch")
    end

    test "an evicted cache leaves the review and takes the title" do
      # The whole reason the reference is a `{source, source_id}` VALUE PAIR: a
      # cache wipe cannot orphan the row that holds the user's own words.
      tracked = track!("log-evicted", nil)
      watch!(tracked, %{watched_on: ~D[2026-07-04], rating: 6, review: "Still mine."})

      w = Rating.watch()
      assert w.title == "Untitled"
      assert w.review == "Still mine."
      assert w.meta == "", "there is no cache row, so there is no runtime to print"
    end

    test "the scale toggle and the half-star note stay the drawing's either way" do
      a_logged_watch!()
      tree = tree(mount_screen(Rating))

      # Both are display preferences and no resource holds one — see
      # `Kati.Screens.Rating`'s moduledoc. They are the same on a real log as on
      # the fallback, which is what makes them a decision rather than a gap.
      assert drawn?(tree, String.upcase(Sample.watch().rating_note))

      for %{label: label} <- Sample.scales(), do: assert(drawn?(tree, label))
    end
  end
end
