defmodule Kati.RatingTagsTest do
  @moduledoc """
  Screen 33's three controls that were drawn and did nothing, MOVIES-AND-TV.md #96.

    * **`+ tag`** carried a tap that reached `handle_info/2`'s fall-through and
      was filed in `Kati.ScreenTapSweepTest`'s `@inert_taps` as *a sheet that
      never opens*. `Kati.Media.Watch.tags` is a real column with no writer.
    * **The spoiler badge** drew `Spoilers hidden` over `contains_spoilers` and
      could not be changed — and with the flag false it drew nothing at all, so
      a reader with a twist in their review had no way to say so.
    * **The `5★` / `10pt` toggle** had its first tile hardcoded lit and no tap
      on either, because the screen's moduledoc argued no resource holds a
      display preference. None should; `Mob.State` does, which is where
      `Kati.Locale` has kept the locale since the app had two screens.

  The sweep cannot see any of this. It renders against an empty store, where
  the sheet draws `Kati.Rating.Sample` and every one of these controls is
  deliberately a picture — a tag typed onto the drawing would be refused by
  Save after it had been typed. So they are pressed here, over a real watch.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Rating.Scale, only: [label: 2, unit: 1]

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Rating

  @prefix "rating-tags-"

  setup do
    Kati.Rating.Scale.put(:stars)

    # Reset in `setup` and never in `on_exit`: `Mob.ScreenCase` restarts
    # `Mob.State` around each test, so by the time an `on_exit` runs the
    # process this preference lives in is already gone.
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    tracked = tracked!()
    %{tracked: tracked, watch: watch!(tracked)}
  end

  describe "the spoiler badge" do
    test "sets the flag, and the flag reaches the row", %{tracked: tracked} do
      socket = sheet(tracked)

      {:noreply, marked} = Rating.handle_info({:tap, :toggle_spoilers}, socket)
      assert marked.assigns.watch.spoilers == "Spoilers hidden"

      {:ok, _saved} = Rating.save_watch(marked.assigns)
      assert only_watch!().contains_spoilers
    end

    test "and unsets it again, which is the half a one-way toggle would lose", %{
      tracked: tracked
    } do
      socket = sheet(tracked)
      {:noreply, marked} = Rating.handle_info({:tap, :toggle_spoilers}, socket)
      {:noreply, cleared} = Rating.handle_info({:tap, :toggle_spoilers}, marked)

      assert cleared.assigns.watch.spoilers == nil

      {:ok, _saved} = Rating.save_watch(cleared.assigns)
      refute only_watch!().contains_spoilers
    end

    test "is a picture over the drawing" do
      drawn = Rating.drawn_watch()

      refute Rating.writable?(drawn)
      refute inspect(Rating.spoiler_toggle(drawn.spoilers, false)) =~ "toggle_spoilers"
    end
  end

  describe "the tag field" do
    test "opens under the chips, takes a word, and closes behind it", %{tracked: tracked} do
      socket = sheet(tracked)

      {:noreply, open} = Rating.handle_info({:tap, :add_tag}, socket)
      assert open.assigns.watch.tag_draft == ""

      {:noreply, typed} = Rating.handle_info({:change, :tag_draft, "rainy sunday"}, open)
      {:noreply, added} = Rating.handle_info({:tap, :commit_tag}, typed)

      assert added.assigns.watch.tags == ["rainy sunday"]
      refute Map.has_key?(added.assigns.watch, :tag_draft)
    end

    test "and the word reaches the column, which is one comma-separated string", %{
      tracked: tracked
    } do
      socket = sheet(tracked)

      {:noreply, one} = Rating.handle_info({:tap, :use_tag_rewatch}, socket)
      {:noreply, two} = Rating.handle_info({:tap, :use_tag_late}, one)

      {:ok, _saved} = Rating.save_watch(two.assigns)

      assert only_watch!().tags == "rewatch, late"
      assert Rating.watch(tracked.id).tags == ["rewatch", "late"]
    end

    test "a tag already on the watch is not added twice", %{tracked: tracked} do
      socket = sheet(tracked)

      {:noreply, once} = Rating.handle_info({:tap, :use_tag_rewatch}, socket)
      {:noreply, twice} = Rating.handle_info({:tap, :use_tag_rewatch}, once)

      assert twice.assigns.watch.tags == ["rewatch"]
    end

    test "a blank commit closes the field rather than adding an empty word", %{
      tracked: tracked
    } do
      socket = sheet(tracked)

      {:noreply, open} = Rating.handle_info({:tap, :add_tag}, socket)
      {:noreply, typed} = Rating.handle_info({:change, :tag_draft, "   "}, open)
      {:noreply, done} = Rating.handle_info({:tap, :commit_tag}, typed)

      assert done.assigns.watch.tags == []
      refute Map.has_key?(done.assigns.watch, :tag_draft)
    end

    test "tapping a tag removes it", %{tracked: tracked} do
      socket = sheet(tracked)
      {:noreply, added} = Rating.handle_info({:tap, :use_tag_rewatch}, socket)

      {:noreply, dropped} = Rating.handle_info({:tap, :drop_tag_rewatch}, added)

      assert dropped.assigns.watch.tags == []
    end

    test "suggests the words this reader has used before, commonest first", %{tracked: tracked} do
      other = tracked!("second")
      watch!(other, %{tags: "rewatch, with Jo", review: "One."})
      watch!(other, %{tags: "rewatch", review: "Two."})

      assert Rating.suggestions(%{tags: []}) == ["rewatch", "with Jo"]

      # And never one that is already on this watch.
      assert Rating.suggestions(%{tags: ["rewatch"]}) == ["with Jo"]

      _ = tracked
    end

    test "and the chips are pictures over the drawing" do
      drawn = inspect(Rating.tags(Rating.drawn_watch()), limit: :infinity)

      refute drawn =~ "add_tag"
      refute drawn =~ "drop_tag_"
    end
  end

  describe "the 5★ / 10pt toggle" do
    test "changes which scale every rating in the app is read on", %{tracked: tracked} do
      socket = sheet(tracked)

      {:noreply, points} = Rating.handle_info({:tap, :scale_10pt}, socket)

      assert Kati.Rating.Scale.current() == :points
      assert points.assigns.watch.scale == :points
      assert Kati.Rating.Scale.label(4.5) == "9"
      assert Kati.Screens.EpisodeRatings.rating_label(4.5) == "9"

      {:noreply, stars} = Rating.handle_info({:tap, :scale_5}, points)

      assert Kati.Rating.Scale.current() == :stars
      assert stars.assigns.watch.scale == :stars
      assert Kati.Screens.EpisodeRatings.rating_label(4.5) == "4.5"
    end

    test "and changes nothing about the watch itself", %{tracked: tracked} do
      socket = sheet(tracked)

      {:noreply, points} = Rating.handle_info({:tap, :scale_10pt}, socket)
      {:ok, _saved} = Rating.save_watch(points.assigns)

      # One stored integer, two ways of reading it. A scale that rewrote the
      # column would lose the half a five-star reader cannot express.
      assert only_watch!().rating == 9
    end

    test "is kept where the locale is kept, which is what makes it survive", %{
      tracked: tracked
    } do
      # `Mob.State` is DETS and SIGKILL-safe — `Kati.Locale`'s own moduledoc —
      # so a preference written here is still set after a restart. Asserted as
      # "it reached that store" rather than by restarting: `Mob.ScreenCase`
      # clears `Mob.State` between tests, which is the opposite of the claim.
      {:noreply, _points} = Rating.handle_info({:tap, :scale_10pt}, sheet(tracked))

      assert Mob.State.get(:rating_scale, :stars) == :points
    end

    test "is a picture on screen 73, which has no handler for it" do
      drawn = inspect(Rating.scale_toggle(false), limit: :infinity)

      refute drawn =~ "scale_10pt"
      assert inspect(Rating.scale_toggle(true), limit: :infinity) =~ "scale_10pt"
    end
  end

  defp sheet(tracked) do
    Rating
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:watch, Rating.watch(tracked.id))
    |> Mob.Socket.assign(:watch_id, only_watch!().id)
    |> Mob.Socket.assign(:tracked_title_id, tracked.id)
    |> Mob.Socket.assign(:save_error, nil)
  end

  defp only_watch! do
    Watch |> Ash.read!() |> Enum.find(&(&1.review == "Held up."))
  end

  defp watch!(tracked, attrs \\ %{}) do
    Ash.create!(
      Watch,
      Map.merge(
        %{
          tracked_title_id: tracked.id,
          rating: 9,
          review: "Held up.",
          watched_on: ~D[2026-07-04],
          watched_at: DateTime.truncate(Kati.Time.now(), :second)
        },
        attrs
      )
    )
  end

  defp tracked!(suffix \\ "title") do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: :movie,
      title: "Harbour",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: :movie,
      status: :watching
    })
  end
end
