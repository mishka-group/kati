defmodule Kati.ShelfProgressTest do
  @moduledoc """
  The rail under a jacket, and the line under a Home card, for a film and for
  a series.

  A film you had watched drew an empty rail and no `%` forever. The only
  fraction a film had was `progress_seconds / runtime`, and nothing in the app
  writes `progress_seconds` — there is no scrubber and no player — while
  `ticks_by_title/1`, which makes a series' progress, filters on
  `not is_nil(episode_source_id)` and so cannot see a title-level watch at all.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Library

  @prefix "shelf-progress-test-"

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

    :ok
  end

  defp a_film!(runtime) do
    id = @prefix <> Integer.to_string(System.unique_integer([:positive]))

    cached =
      Ash.create!(CachedTitle, %{
        source: :manual,
        source_id: id,
        kind: :movie,
        title: "A Film",
        runtime_minutes: runtime,
        fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    tracked =
      Ash.create!(TrackedTitle, %{
        source: :manual,
        source_id: id,
        kind: :movie,
        status: :watching
      })

    {tracked, cached}
  end

  describe "a film" do
    test "not watched shows its runtime and no rail" do
      {tracked, cached} = a_film!(116)

      row = Library.shaped(tracked, cached, 0, 0)

      assert row.meta == "1h 56m"
      assert row.progress == nil
    end

    test "watched fills the rail and says so" do
      {tracked, cached} = a_film!(116)

      row = Library.shaped(tracked, cached, 0, 1)

      assert row.progress == 1.0
      assert row.meta == "Watched · 1h 56m"
    end

    test "a resume point still wins, for whenever something writes one" do
      {tracked, cached} = a_film!(120)
      halfway = %{tracked | progress_seconds: 3600}

      row = Library.shaped(halfway, cached, 0, 0)

      assert row.progress == 0.5
      assert row.meta == "60m left"
    end

    test "with no runtime known it says nothing rather than guessing" do
      {tracked, cached} = a_film!(nil)

      assert Library.shaped(tracked, cached, 0, 0).meta == nil
      assert Library.shaped(tracked, cached, 0, 1).meta == nil
    end
  end

  describe "runtime_line/1" do
    test "hours and minutes, and neither when the other is zero" do
      assert Library.runtime_line(116) == "1h 56m"
      assert Library.runtime_line(120) == "2h"
      assert Library.runtime_line(48) == "48m"
      assert Library.runtime_line(60) == "1h"
    end
  end

  describe "the shelf reads a watched film" do
    test "a logged film appears with a full rail on the real shelf" do
      {tracked, _cached} = a_film!(116)

      Ash.create!(Watch, %{
        tracked_title_id: tracked.id,
        watched_on: Kati.Time.today(),
        rating: 8
      })

      row = Library.shelf() |> Enum.find(&(&1.id == tracked.id))

      assert row, "the film is not on the shelf at all"
      assert row.progress == 1.0
      assert row.meta =~ "Watched"
    end
  end
end
