defmodule Kati.ScreenActivityTest do
  @moduledoc """
  Screen 15's log, read through `Kati.Media.Watch` instead of off a sample.

  ## The three claims, and why each one needs its own fixture

    * **A real watch renders.** `Kati.Screens.Activity.entries/1` turns rows
      into the drawing's `%{stamp, seed, lead, rest, stars}`, and every step of
      that — the verb, the `S2E5` label, the ten-point rating halved into whole
      glyphs, the seed recovered from the cache row — is a place where a wrong
      answer still renders *something*. So the assertions are equality against
      `Kati.Activity.Sample`'s own maps rather than `=~` against a fragment: the
      sample is what the frame was captured from, so a shaped row that differs
      from it by one character is a screen that no longer matches its drawing.

    * **An empty database still renders the drawing.** This screen is the
      design reference as well as a feature, and a fresh install has no
      watches. A `=~` on one string would pass against a screen that had lost
      six of its seven rows, so the counts are asserted too.

    * **Real rows REPLACE the drawing.** The easiest way to get the first two
      claims to pass is to render both — the sample rows and the real ones —
      and every `assert copy =~` in the file would still be green. Each of the
      two tests therefore carries a `refute` for the other's data.

  ## What is deliberately not asserted

  `Added`, `Finished`, `Dropped` and `Imported` — four of the seven rows the
  sample draws. Nothing in `Kati.Media` records a status change, a wishlist or
  an import, so there is no fixture that could produce them and no query that
  could find them. Asserting they are absent would pin today's gap as if it
  were the design; asserting they are present would need data invented here.
  They are named in `Kati.Screens.Activity`'s moduledoc instead.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Activity.Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Activity

  # The day `.scratch/design/screens/15.html` was drawn for: its Today rows are
  # stamped 21:12, 20:40 and 18:03, and its Earlier this month rows run back to
  # 02 AUG. Passed to `entries/1` rather than left to the clock, so the two
  # groups are testable on a day that is not the 16th — and, more to the point,
  # on the 1st of a month, where "earlier this month" is an empty range and a
  # clock-driven test would quietly assert nothing.
  @drawn_day ~D[2026-08-16]

  # Children first: media_watches carries the foreign key into tracked_titles.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles)

  # The whole suite shares one SQLite file (test/test_helper.exs), so an empty
  # database has to be made rather than assumed — and made again afterwards,
  # because what this module leaves behind is not inert: a watch dated today
  # would put real rows on screen 15 for `Kati.ScreenDesignLiteralTest`, which
  # asserts the drawing's own copy is in the tree. Whether that module passed
  # would otherwise depend on the shuffle putting it before this one.
  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "an empty database" do
    test "still draws every row of the drawing" do
      view = mount_screen(Activity)
      log = assigns(view).log

      assert log == Activity.drawn(),
             "screen 15 stopped falling back to the drawing on an empty database. " <>
               "It is the reference the captured frame is compared against, and a " <>
               "fresh install has no watches, so this is the state the frame was " <>
               "taken in."

      assert length(log.today) == 3
      assert length(log.earlier) == 4
      assert length(log.rewatch) == 3

      copy = text(view)
      assert copy =~ Sample.entries_line()

      for row <- Sample.today() ++ Sample.earlier() do
        assert copy =~ row.stamp, "no #{row.stamp} stamp in the tree"
        assert copy =~ row.lead, "no #{row.lead} verb in the tree"
        assert copy =~ row.rest, "no #{inspect(row.rest)} in the tree"
      end

      # `Kati.UI.eyebrow` sets its label in caps, so this is the rendered form.
      assert copy =~ "REWATCH COUNT"

      for {name, count} <- Sample.rewatch() do
        assert copy =~ name
        assert copy =~ count
      end

      # Seven rows, seven thumbnails. A row that lost its artwork still draws
      # the placeholder tile at the same size, so this counts rows rather than
      # pictures and cannot be satisfied by a shorter list.
      assert length(thumbs(view)) == 7
    end
  end

  describe "the drawing's own rows, rebuilt as real watches" do
    test "shape into exactly the maps the sample produced" do
      hollow = title!("hollow71", "The Long Hollow", :tv)
      blue = title!("bluehour58", "Blue Hour", :movie)
      birds = title!("nightbirds24", "Nightbirds", :tv)

      watch!(hollow, %{
        watched_at: at(@drawn_day, ~T[21:12:00]),
        season_number: 2,
        episode_number: 5
      })

      # 8 on the ten-point scale is four whole stars — see Kati.Media.TrackedTitle.
      watch!(blue, %{watched_at: at(@drawn_day, ~T[20:40:00]), rating: 8})

      watch!(birds, %{
        watched_at: at(~D[2026-08-12], ~T[19:00:00]),
        season_number: 1,
        episode_number: 1,
        rewatch_number: 3
      })

      log = Activity.entries(@drawn_day)

      [drawn_tick, drawn_rating | _added] = Sample.today()
      [drawn_rewatch | _finished_dropped_imported] = Sample.earlier()
      [drawn_count | _] = Sample.rewatch()

      assert log.today == [drawn_tick, drawn_rating],
             "a watch and a rating no longer shape into the rows the drawing " <>
               "shows. Got #{inspect(log.today)}"

      assert log.earlier == [drawn_rewatch],
             "a rewatch no longer shapes into `#{drawn_rewatch.rest}`. " <>
               "Got #{inspect(log.earlier)}"

      assert log.rewatch == [drawn_count]
      assert log.entries_line == "3 entries"
    end

    test "the rating becomes four star glyphs, not the number 8" do
      blue = title!("bluehour58", "Blue Hour", :movie)
      watch!(blue, %{watched_at: at(Kati.Time.today(), ~T[12:00:00]), rating: 8})

      view = mount_screen(Activity)

      assert length(find_all(view, :text, text: star_glyph())) == 4,
             "a rating of 8 must draw four filled stars — U+2605 is not in Plus " <>
               "Jakarta Sans, so a text star draws nothing at all and the row " <>
               "silently loses its rating."

      refute text(view) =~ "8"
    end
  end

  describe "real rows replace the drawing" do
    test "a watch recorded today is the log, and the sample is gone" do
      hollow = title!("hollow71", "The Long Hollow", :tv)
      today = Kati.Time.today()

      watch!(hollow, %{
        watched_at: at(today, ~T[12:00:00]),
        season_number: 2,
        episode_number: 5
      })

      view = mount_screen(Activity)
      log = assigns(view).log
      copy = text(view)

      assert length(log.today) == 1
      assert log.earlier == []

      assert copy =~ "The Long Hollow S2E5"
      assert copy =~ "12:00"
      assert copy =~ "1 entry"
      assert length(thumbs(view)) == 1

      refute copy =~ Sample.entries_line()
      refute copy =~ "Vellum to Wishlist"
      refute copy =~ "412 titles from a CSV backup"

      # One watch is not a rewatch, so the card and its eyebrow both go — the
      # rule `group/5` already follows for a filtered-empty day.
      refute copy =~ "REWATCH COUNT"
    end

    test "a watch from before this month leaves the drawing standing" do
      hollow = title!("hollow71", "The Long Hollow", :tv)
      last_month = Date.add(Date.beginning_of_month(Kati.Time.today()), -3)

      watch!(hollow, %{
        watched_at: at(last_month, ~T[12:00:00]),
        season_number: 2,
        episode_number: 5
      })

      view = mount_screen(Activity)

      assert assigns(view).log == Activity.drawn(),
             "a watch older than this month belongs to neither group, so the " <>
               "screen has nothing of its own to show and must draw the drawing."

      assert text(view) =~ Sample.entries_line()
    end
  end

  describe "the chips filter real rows" do
    test "Rated keeps a real rating and drops a real tick" do
      today = Kati.Time.today()
      hollow = title!("hollow71", "The Long Hollow", :tv)
      blue = title!("bluehour58", "Blue Hour", :movie)

      watch!(hollow, %{
        watched_at: at(today, ~T[12:00:00]),
        season_number: 2,
        episode_number: 5
      })

      watch!(blue, %{watched_at: at(today, ~T[11:00:00]), rating: 8})

      resting = text(mount_screen(Activity))
      assert resting =~ "The Long Hollow S2E5"
      assert resting =~ "Blue Hour"

      rated = Activity |> mount_screen() |> render_info({:tap, :filter_Rated}) |> text()

      assert rated =~ "Blue Hour"

      refute rated =~ "The Long Hollow S2E5",
             "the Rated chip matched a plain tick. The chip filters on `lead` " <>
               "and nothing else, so a tick shaped with the wrong verb passes " <>
               "every other test in this file and fails here."
    end
  end

  # ── Fixtures ───────────────────────────────────────────────────────────────

  # A cached title and the durable row that references it — by {source,
  # source_id} as a value pair, through `Kati.Seeds.sample_source_id/1`, which
  # is the convention the seeder already writes and the screen already reads.
  defp title!(seed, name, kind) do
    source_id = Kati.Seeds.sample_source_id(seed)

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: Kati.Seeds.sample_source(),
      source_id: source_id,
      kind: kind,
      title: name,
      # Not a TMDB path: the seeder writes the design seed here, and screen 15
      # resolves its 26x37 thumbnail from it.
      poster_path: seed,
      fetched_at: DateTime.utc_now()
    })
    |> Ash.create!()

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: Kati.Seeds.sample_source(),
      source_id: source_id,
      kind: kind
    })
    |> Ash.create!()
  end

  defp watch!(tracked, attrs) do
    Watch
    |> Ash.Changeset.for_create(:create, Map.merge(%{tracked_title_id: tracked.id}, attrs))
    |> Ash.create!()
  end

  # A wall-clock time in the device's own zone, stored as the instant it is.
  # Written through `Kati.Time.to_utc/2` rather than as a literal `~U` so the
  # stamp the screen reads back is 21:12 in every zone the suite might run in.
  defp at(date, time) do
    {:ok, utc} = Kati.Time.to_utc(NaiveDateTime.new!(date, time), Kati.Time.device_zone())
    utc
  end

  # ── Reading the tree ───────────────────────────────────────────────────────

  # The 26x37 tile in a log row's gutter, whether it drew artwork or the grey
  # placeholder. Both are the same rectangle, which is what makes this a count
  # of ROWS rather than a count of pictures that happened to resolve.
  defp thumbs(view) do
    find_all(view, :image, width: 26, height: 37) ++ find_all(view, :box, width: 26, height: 37)
  end

  defp star_glyph, do: Kati.Icons.glyph!("star")

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end
end
