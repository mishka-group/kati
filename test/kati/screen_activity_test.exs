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

  # The day `test/design/screens/15.html` was drawn for: its Today rows are
  # stamped 21:12, 20:40 and 18:03, and its Earlier this month rows run back to
  # 02 AUG. Passed to `entries/1` rather than left to the clock, so the two
  # groups are testable on a day that is not the 16th — and, more to the point,
  # on the 1st of a month, where "earlier this month" is an empty range and a
  # clock-driven test would quietly assert nothing.
  @drawn_day ~D[2026-08-16]

  # Children first: media_watches carries the foreign key into tracked_titles.
  @tables ~w(media_events media_watches media_content_warnings tracked_titles cached_titles)

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
    test "draws nothing logged yet, not the drawing's seven rows" do
      view = mount_screen(Activity)
      log = assigns(view).log

      assert log == Activity.empty(),
             "a fresh install reported 1,204 entries over seven invented rows. This page " <>
               "is an append-only record of what the reader did, and a device that has " <>
               "done nothing has to say so."

      refute log == Activity.drawn()

      assert log.today == []
      assert log.earlier == []
      assert log.rewatch == []

      copy = text(view)
      refute copy =~ Sample.entries_line()

      # None of the drawing's seven rows, and none of its rewatch counts. This
      # used to assert every one of them was present.
      for row <- Sample.today() ++ Sample.earlier() do
        refute copy =~ row.rest, "#{inspect(row.rest)} is in a log that recorded nothing"
      end

      for {name, _count} <- Sample.rewatch() do
        refute copy =~ name
      end

      # Seven rows, seven thumbnails — so none of either.
      assert thumbs(view) == []
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

      # Compared on the DRAWING's own keys. A real row also carries `:id` and
      # `:kind`, which is what makes it openable — MOVIES-AND-TV.md #90 — and
      # a drawn row carries neither, which is what keeps board 15's rows
      # pictures rather than dead controls. That difference is the feature;
      # asserting the whole map would be asserting it away.
      assert drawn_only(log.today) == [drawn_tick, drawn_rating],
             "a watch and a rating no longer shape into the rows the drawing " <>
               "shows. Got #{inspect(log.today)}"

      assert drawn_only(log.earlier) == [drawn_rewatch],
             "a rewatch no longer shapes into `#{drawn_rewatch.rest}`. " <>
               "Got #{inspect(log.earlier)}"

      assert Enum.all?(log.today ++ log.earlier, &is_binary(&1.id)),
             "a row with no id cannot be opened, which is the whole of #90"

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

  describe "opening an entry" do
    test "the row carries the title it is about" do
      hollow = title!("hollow71", "The Long Hollow", :tv)
      watch!(hollow, %{watched_at: at(Kati.Time.today(), ~T[21:12:00])})

      [row] = Activity.entries(Kati.Time.today()).today

      assert row.id == hollow.id
      assert row.kind == :tv
      assert Activity.open_tag(row) == String.to_atom("open_" <> hollow.id)
    end

    test "and tapping it opens that title, under a pill reading Activity" do
      blue = title!("bluehour58", "Blue Hour", :movie)
      watch!(blue, %{watched_at: at(Kati.Time.today(), ~T[20:40:00])})

      view = mount_screen(Activity)
      [row] = assigns(view).log.today

      socket =
        Kati.Screens.Activity
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:log, assigns(view).log)

      pushed = Activity.open(socket, Activity.open_tag(row))

      assert {:push, Kati.Screens.Film, %{id: id, back: "Activity"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == blue.id
    end

    test "a drawn row opens nothing, because there is no title behind it" do
      assert Enum.all?(Kati.Activity.Sample.today(), &(Activity.open_tag(&1) == nil))
    end

    test "and the tune disc opens the sheet the chips narrow with" do
      socket = Mob.Socket.new(Kati.Screens.Activity)
      {:noreply, pushed} = Activity.handle_tap(:open_filters, socket)

      assert {:push, Kati.Screens.ShelfFilters, _} = Map.get(pushed.__mob__, :nav_action)
    end
  end

  # The row as the drawing describes it: every key board 15 has, and none of
  # the two a device adds so the entry can be opened.
  defp drawn_only(rows), do: Enum.map(rows, &Map.drop(&1, [:id, :kind]))

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

    test "a watch from before this month is still this reader's history" do
      # This used to assert the opposite, and the opposite was
      # MOVIES-AND-TV.md #58: the gate was `%{today: [], earlier: []}`, both of
      # which are month-scoped, so a reader whose watches are all older than
      # the first was handed `1,204 entries` over seven invented rows — and the
      # rewatch card, which counts their WHOLE history, was replaced too.
      hollow = title!("hollow71", "The Long Hollow", :tv)
      last_month = Date.add(Date.beginning_of_month(Kati.Time.today()), -3)

      watch!(hollow, %{
        watched_at: at(last_month, ~T[12:00:00]),
        season_number: 2,
        episode_number: 5
      })

      view = mount_screen(Activity)
      copy = text(view)

      refute assigns(view).log == Activity.drawn(),
             "a reader with a history was shown the drawing's"

      assert assigns(view).log.count == 1
      assert copy =~ "1 entry"
      refute copy =~ Sample.entries_line()

      # Neither month group can hold it, so the page says which month is empty
      # rather than leaving two silent gaps under the header.
      assert copy =~ "Nothing this month"

      # And none of the seven rows the drawing carries.
      for row <- Sample.today() ++ Sample.earlier() do
        refute copy =~ row.rest, "the drawing's rows are still on a real reader's log"
      end
    end

    test "and a device that has recorded nothing at all says so" do
      view = mount_screen(Activity)

      assert assigns(view).log == Activity.empty()
      refute text(view) =~ Sample.entries_line()
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

    test "Added finds a real add, which nothing could produce before" do
      # MOVIES-AND-TV.md #112: `verb/2` returned only Watched, Rated or
      # Rewatched, so the fourth chip matched nothing on any device — and
      # nothing recorded that a title had arrived at all.
      hollow = title!("hollow71", "The Long Hollow", :tv)
      Kati.Media.Log.write(hollow, :added, %{from_status: nil})

      added = Activity |> mount_screen() |> render_info({:tap, :filter_Added}) |> text()

      assert added =~ "The Long Hollow"
      assert added =~ "Added"
    end

    test "a drop carries its position and its reason into the log" do
      hollow = title!("hollow71", "The Long Hollow", :tv)

      Kati.Media.Log.write(hollow, :dropped, %{
        season_number: 1,
        episode_number: 3,
        reason: "Too slow"
      })

      drawn = text(mount_screen(Activity))

      assert drawn =~ "Dropped"
      assert drawn =~ "after S1E3"
      assert drawn =~ "too slow"
    end

    test "an import is a row with no title behind it" do
      # `tracked_title_id` is nullable for exactly this: screen 15's own sample
      # carries *Imported 412 titles from a CSV backup*.
      title!("hollow71", "The Long Hollow", :tv)
      Kati.Media.Log.imported(412, "goodreads_library_export.csv")

      drawn = text(mount_screen(Activity))

      assert drawn =~ "Imported"
      assert drawn =~ "412 titles"
    end

    test "a chip that matches nothing says so rather than drawing a blank" do
      # The second half of #112: the page kept its header and its chips over
      # nothing at all, which reads as a search that broke.
      hollow = title!("hollow71", "The Long Hollow", :tv)
      watch!(hollow, %{watched_at: at(Kati.Time.today(), ~T[12:00:00])})

      added = Activity |> mount_screen() |> render_info({:tap, :filter_Added}) |> text()

      assert added =~ "No added entries this month"
      assert added =~ "Press All to see it"

      # And pressing the card is the same move the `All` chip is.
      back = Activity |> mount_screen() |> render_info({:tap, :show_all}) |> text()
      assert back =~ "The Long Hollow"
    end

    test "and the card's tap is not a tag another node already carries" do
      hollow = title!("hollow71", "The Long Hollow", :tv)
      watch!(hollow, %{watched_at: at(Kati.Time.today(), ~T[12:00:00])})

      drawn =
        Activity
        |> mount_screen()
        |> render_info({:tap, :filter_Added})
        |> tree()
        |> inspect(limit: :infinity)

      assert length(Regex.scan(~r/:filter_All\b/, drawn)) == 1,
             "filter_All is drawn twice on one frame; onNodeWithTag throws on the second"
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
