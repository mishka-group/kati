defmodule Kati.RatingWriteTest do
  @moduledoc """
  #88 — screen 33 records a rating and a review.

  The sheet has always READ the newest log and drawn it, and
  `Kati.ScreenRatingLogTest` covers that half at length. What it could not
  cover, and said so, was a write: the screen drew exactly three tap targets,
  none of them could change a value, and `:save` popped the sheet without
  touching the store. Its own moduledoc named the gap — *"a `Save` wired today
  would write back, to the value, exactly what it had just read."*

  ## Why every assertion here reads the store

  Because the socket cannot settle any of them. A draft assign holding a rating
  of 7 is exactly what the old screen would have looked like if it had held one
  — the whole defect #85 is about is that a lost write and a completed one are
  indistinguishable from the screen. `AGENTS.md` puts it as *"the receipt is
  never the screen"*, for device tests, and it is no less true on the host.

  ## The one that is not about a value: `one watch, not two`

  A sheet that reopens a log and commits a NEW row would answer "I changed my
  mind about the rating" with two contradictory logs of one night. Nothing about
  the second write would look wrong — the row would be there, with the right
  value in it — and the damage would surface much later, on screen 15's activity
  list, as a night watched twice. So the count is asserted, not just the value.
  """

  use Mob.ScreenCase, async: false

  # The three functions that convert between the screen's scale and the
  # column's, run rather than read. Each one's example is the exact value the
  # drawing shows — 4.5 stars is nine points — and an example that is never
  # executed is a comment that looks like a test.
  doctest Kati.Screens.Rating, only: [star_tag: 1, point_of: 1, ten_point: 1]

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Rating

  # Child first: a watch carries the foreign key. The same list and the same
  # `on_exit` as `Kati.ScreenRatingLogTest`, for the same reason — a tracked
  # title left behind is a stranger's row on screen 03's grid the moment
  # another module mounts it, and a watch left behind is what stops
  # `Kati.ScreenTapSweepTest` seeing the empty database its `@inert_taps` list
  # is reasoned against.
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

  # One watch that is a LOG rather than a tick, because only a log fills this
  # sheet — `Kati.Media.Watch` holds both in one row shape and
  # `Kati.Screens.Rating.logged_watch/0` filters on the difference. A review and
  # no rating, so the rating assertions below start from nothing rather than
  # from a value that might have been left where it was.
  defp a_logged_watch! do
    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: "write-estuary",
      kind: :movie,
      title: "Estuary",
      runtime_minutes: 96,
      fetched_at: DateTime.utc_now()
    })
    |> Ash.create!()

    tracked =
      TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: "write-estuary",
        kind: :movie,
        status: :finished
      })
      |> Ash.create!()

    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      watched_on: ~D[2026-08-02],
      watched_at: ~U[2026-08-02 20:30:00.000000Z],
      review: "Placeholder."
    })
    |> Ash.create!()
  end

  defp stored, do: Ash.read!(Watch)

  defp only_watch! do
    [watch] = stored()
    watch
  end

  defp tap_tags(tree) do
    for node <- flatten(tree),
        {_pid, tag} <- [Map.get(node.props || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  describe "the controls exist at all" do
    test "each star carries two tap targets, one per point of the column's scale" do
      a_logged_watch!()

      drawn =
        Rating |> mount_screen() |> tree() |> tap_tags() |> Enum.filter(&Rating.point_of/1)

      # Ten, not five. `Kati.Media.Watch.rating` is `min: 1, max: 10`, and a
      # target per STAR would leave every odd point — every half star this app
      # already stores and draws — unreachable from the screen that exists to
      # set it. The drawing says so itself: `TAP LEFT OR RIGHT OF CENTRE`.
      assert Enum.sort(drawn) == Enum.sort(Enum.map(1..10, &Rating.star_tag/1))
    end

    test "the review is a field a device test can address" do
      a_logged_watch!()
      tree = tree(mount_screen(Rating))

      # Without an `accessibility_id` the bridge's `K-35 test-tag` fence has
      # nothing to hang a `testTag` on — `Mob.Renderer` emits one for an atom
      # tap tag and a field has no tap tag — so the field would be unreachable
      # from `android/app/src/androidTest` no matter how well it worked.
      assert find(tree, :text_field, accessibility_id: "review") != nil,
             "the review body is still a picture of a field"
    end
  end

  describe "the id and the draft come from the same place" do
    # The sheet is committable exactly when what it is showing is a real row's.
    # `mount/3` derives both from one call for that reason, and this is the
    # pairing stated as an assertion rather than as a shape of code.
    #
    # The bug it is here for was found by making `shape/1` raise — which is what
    # its rescue is for — with a watch in the store: `logged_record/0` answered a
    # row, `shape/1` answered `nil`, the sheet fell back to `Kati.Rating.Sample`
    # and kept the row's id. Save then reported success, popped, and replaced
    # the user's own rating and review with the fixture's. That branch cannot be
    # reached from a test without editing the module, so what is pinned here is
    # the invariant either branch has to satisfy: no id beside the drawing.
    test "no sheet showing the drawing carries a row to commit it to" do
      empty = mount_screen(Rating)

      assert assigns(empty).watch == Rating.drawn_watch()
      assert assigns(empty).watch_id == nil

      a_logged_watch!()
      real = mount_screen(Rating)

      assert assigns(real).watch_id != nil
      assert assigns(real).watch != Rating.drawn_watch()

      # Said once more as the implication itself, because it is the half that
      # holds however many ways there come to be of arriving at the drawing.
      for view <- [empty, real] do
        assigns = assigns(view)

        assert assigns.watch_id == nil or assigns.watch != Rating.drawn_watch(),
               "the sheet is drawing the fixture and holding a real row's id, so Save " <>
                 "would file Blue Hour under the user's own log"
      end
    end
  end

  describe "a rating persists" do
    test "tapping a star and pressing Save puts the point on the row" do
      a_logged_watch!()
      assert only_watch!().rating == nil

      view = mount_screen(Rating)
      view = render_info(view, {:tap, Rating.star_tag(7)})
      view = render_info(view, {:tap, :save})

      # Seven of ten, which the sheet draws as three and a half stars. The
      # column is the ten-point one and the screen is the five-point one, and
      # the conversion is the thing most likely to be wrong in a way nobody
      # notices — 3.5 stored as 3 is a rating quietly rounded down.
      assert only_watch!().rating == 7
      assert assigns(view).save_error == nil
    end

    test "the sheet closes on a save that landed" do
      a_logged_watch!()

      view =
        Rating
        |> mount_screen()
        |> render_info({:tap, Rating.star_tag(10)})
        |> render_info({:tap, :save})

      assert navigated_to(view) == {:pop},
             "a committed sheet stays open, so there is nothing to tell a person it worked"
    end

    test "the half points are reachable, which is the whole reason there are ten" do
      a_logged_watch!()

      for point <- 1..10 do
        Rating
        |> mount_screen()
        |> render_info({:tap, Rating.star_tag(point)})
        |> render_info({:tap, :save})

        assert only_watch!().rating == point
      end
    end
  end

  describe "a review persists" do
    test "what was typed is what is stored, as typed" do
      a_logged_watch!()
      typed = "The estuary scenes land differently the second time."

      Rating
      |> mount_screen()
      |> render_info({:change, :review, typed})
      |> render_info({:tap, :save})

      assert only_watch!().review == typed
    end

    test "a review of nothing but whitespace is stored as nothing" do
      a_logged_watch!()

      Rating
      |> mount_screen()
      |> render_info({:change, :review, "   "})
      |> render_info({:tap, :save})

      # `nil`, not `""`. `Kati.Screens.Rating.logged_watch/0` filters a log on
      # `review != ""` OR a rating, so an empty string stored here is a row the
      # sheet would reopen on and also consider unlogged.
      assert only_watch!().review == nil
    end

    test "the character count under the field follows the field" do
      a_logged_watch!()

      view =
        Rating
        |> mount_screen()
        |> render_info({:change, :review, "Six.."})

      assert assigns(view).watch.characters == "5 characters"
    end
  end

  describe "changing a rating replaces rather than appends" do
    test "two ratings on one night leave one watch, carrying the later value" do
      a_logged_watch!()

      Rating
      |> mount_screen()
      |> render_info({:tap, Rating.star_tag(4)})
      |> render_info({:tap, :save})

      assert only_watch!().rating == 4

      # A fresh mount, because the first save closed the sheet. This is the
      # user changing their mind: reopen the log, tap a different star, save.
      Rating
      |> mount_screen()
      |> render_info({:tap, Rating.star_tag(9)})
      |> render_info({:tap, :save})

      assert length(stored()) == 1,
             "the second save created a second watch, so one night is now logged twice"

      assert only_watch!().rating == 9
    end

    test "saving twice without changing anything is still one watch" do
      a_logged_watch!()

      view = mount_screen(Rating)
      view = render_info(view, {:tap, Rating.star_tag(6)})
      view = render_info(view, {:tap, :save})
      _view = render_info(view, {:tap, :save})

      assert length(stored()) == 1
      assert only_watch!().rating == 6
    end

    test "a rating does not take the review with it, and a review does not take the rating" do
      a_logged_watch!()

      Rating
      |> mount_screen()
      |> render_info({:tap, Rating.star_tag(8)})
      |> render_info({:tap, :save})

      watch = only_watch!()

      assert watch.rating == 8

      assert watch.review == "Placeholder.",
             "saving a rating blanked the review, which the sheet never asked about"
    end
  end

  describe "a failed write keeps the sheet open" do
    test "with nothing logged there is nothing to save, and the sheet says so" do
      # The database is empty, so the sheet is drawing `Kati.Rating.Sample` —
      # somebody else's film and a review nobody wrote. Committing that would
      # file the drawing under the user's own log, so the write refuses.
      assert Rating.logged_record() == nil

      view = mount_screen(Rating)
      view = render_info(view, {:tap, Rating.star_tag(9)})
      view = render_info(view, {:tap, :save})

      assert stored() == [], "the drawing was written to the store as if it were a log"

      assert navigated_to(view) == nil,
             "the sheet closed on a save that wrote nothing, which is the exact defect #85 " <>
               "fixed everywhere else"

      assert assigns(view).save_error == "Nothing to save yet."
    end

    test "a row that has gone leaves the sheet up with the draft still on it" do
      a_logged_watch!()

      view = mount_screen(Rating)
      view = render_info(view, {:tap, Rating.star_tag(5)})
      view = render_info(view, {:change, :review, "Still typed."})

      # The row goes while the sheet is open — a wipe on another screen, a
      # restore, a device mid-migration. `Ash.update/1` answers `{:error, _}`
      # and this is the branch that has to survive it.
      Enum.each(stored(), &Ash.destroy!/1)

      view = render_info(view, {:tap, :save})

      assert navigated_to(view) == nil
      assert is_binary(assigns(view).save_error)

      # The draft is what the recovery needs. Pressing Save again is only worth
      # doing if the rating you tapped and the words you typed are still there.
      assert assigns(view).watch.rating == 2.5
      assert assigns(view).watch.review == "Still typed."

      assert find(tree(view), :text, text: assigns(view).save_error) != nil,
             "the failure is on the socket and nowhere on the sheet"
    end

    test "the notice goes away once a save lands" do
      view = mount_screen(Rating)
      view = render_info(view, {:tap, :save})
      assert assigns(view).save_error != nil

      # Same sheet, now with something under it. A stale failure sitting over a
      # save that worked is its own lie.
      a_logged_watch!()

      view =
        Rating
        |> mount_screen()
        |> render_info({:tap, Rating.star_tag(2)})
        |> render_info({:tap, :save})

      assert assigns(view).save_error == nil
      assert only_watch!().rating == 2
    end
  end
end
