defmodule Kati.RatingPlaceTest do
  @moduledoc """
  Board 202's second half: **where in the world**, as opposed to on what.

  `Kati.Media.Watch.place` is a column. `Kati.Screens.Rating.where_label/1` has
  printed it since the day it existed — `Lumen+ · living room` — and **nothing
  anywhere wrote it**, so the half after the dot could never appear on any
  device. A column that is read and never written is a sentence the app can
  only ever say half of.

  Board 202's own note is why this is a section of its own rather than more
  chips in the service row above: *"Two sections, two shapes, because the two
  halves are stored apart: one is a thing stats group by, the other is a room
  in a house. Only the printed line joins them."*

  The board also settles the third option in the service row — `Not on a
  service`, *a disc, a cinema, a plane* — which is a real answer rather than
  the absence of one, and is stored as the service for that reason: leaving the
  column `nil` would make a night at the cinema indistinguishable from a night
  nobody said anything about.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Rating

  @prefix "rating-place-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    tracked = shelve!()
    log!(tracked, %{})
    %{tracked: tracked}
  end

  # A LIVE draft. `edit/2` refuses an edit to `Kati.Rating.Sample` — #96's rule
  # that a control on a drawing is a picture — so every tap below needs a watch
  # that exists.
  defp sheet(tracked) do
    mount_screen(Rating, %{tracked_title_id: tracked.id}).socket
  end

  describe "the Place field" do
    test "writes the column that only ever had a reader", %{tracked: tracked} do
      draft =
        tracked.id
        |> Rating.blank_for()
        |> Map.merge(%{rating: 4.0, service: "Lumen+", place: "living room"})

      {:ok, watch} =
        Rating.save_watch(%{watch_id: nil, tracked_title_id: tracked.id, watch: draft})

      assert watch.place == "living room"
      assert watch.service == "Lumen+"
    end

    test "and the printed line finally has both halves", %{tracked: tracked} do
      # `where_label/1` is what puts the dot between them, and until this it
      # could only ever reach the first side of it. Read off the page rather
      # than out of the private function: what matters is that a reader sees it.
      # Mounted WITH the title, not bare. Bare, this passed on
      # `Kati.Rating.Sample.watch/0`, whose own service and place happen to be
      # `Lumen+` and `living room` — so the assertion was reading the fixture
      # while the test claimed to be reading a watch it had just logged.
      # `rating:` as well, because `newest_log/1` only reopens a watch that
      # carries a rating or a review — a row with neither is not a log this
      # sheet has anything to show. Without it the sheet opened blank for the
      # title, and the assertion was met by the fixture instead.
      log!(tracked, %{rating: 8, service: "Lumen+", place: "living room"})

      assert text(mount_screen(Rating, %{tracked_title_id: tracked.id})) =~
               "Lumen+ · living room"
    end

    test "a place typed and committed reaches the draft", %{tracked: tracked} do
      {:noreply, typed} =
        Rating.handle_info({:change, :place_draft, "the Rex"}, sheet(tracked))

      assert typed.assigns.watch.place_draft == "the Rex"

      {:noreply, done} = Rating.handle_info({:tap, :commit_place}, typed)

      assert Map.get(done.assigns.watch, :place) == "the Rex"
      refute Map.has_key?(done.assigns.watch, :place_draft)
    end

    test "an emptied field clears the place rather than storing a blank", %{tracked: tracked} do
      {:noreply, typed} = Rating.handle_info({:change, :place_draft, "   "}, sheet(tracked))
      {:noreply, done} = Rating.handle_info({:tap, :commit_place}, typed)

      refute Map.get(done.assigns.watch, :place)
    end

    test "the chips are the reader's own places, and a device with none gets the field alone",
         %{tracked: tracked} do
      assert Rating.place_options(%{}) == []

      log!(tracked, %{place: "living room"})
      log!(tracked, %{place: "the Rex"})

      options = Rating.place_options(%{})

      assert "living room" in options
      assert "the Rex" in options
    end

    test "and tapping one twice puts it back to nothing", %{tracked: tracked} do
      {:noreply, on} = Rating.handle_info({:tap, :"place_the Rex"}, sheet(tracked))
      assert Map.get(on.assigns.watch, :place) == "the Rex"

      {:noreply, off} = Rating.handle_info({:tap, :"place_the Rex"}, on)
      refute Map.get(off.assigns.watch, :place)
    end
  end

  describe "Not on a service" do
    test "is offered, and is a real answer rather than the absence of one", %{tracked: tracked} do
      assert Rating.no_service() == "Not on a service"

      tag = String.to_atom("where_" <> Rating.no_service())

      {:noreply, chosen} = Rating.handle_info({:tap, tag}, sheet(tracked))

      assert Map.get(chosen.assigns.watch, :service) == "Not on a service",
             "a night at the cinema is stored as nil, which is what a night nobody " <>
               "said anything about looks like"
    end
  end

  defp shelve!(title \\ "Estuary Nights") do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :movie,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :movie,
      status: :watching
    })
  end

  defp log!(tracked, attrs) do
    Ash.create!(
      Watch,
      Map.merge(%{tracked_title_id: tracked.id, watched_at: Kati.Time.now()}, attrs)
    )
  end
end
