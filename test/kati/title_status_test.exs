defmodule Kati.TitleStatusTest do
  @moduledoc """
  What the shelf calls a title, and who decides.

  Nothing in the reachable app could set a `Kati.Media.TrackedTitle`'s status.
  The only writer was `Kati.Screens.DropSheet`, which has no route in — it can
  only be opened from `Settings → Every screen` — and writes `:watching`
  anyway. So screen 03's chips read `Not started 0` and `Finished 0` on every
  device that has ever existed, every tile's caption said *watching*, and a
  film logged as seen still sat under *Continue watching*, which is the
  section for things you have not finished.

  Two rules, because a film and a series finish differently: a film is
  finished when you have watched it, and a series when its last episode is
  ticked.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Rating
  alias Kati.Screens.Series

  @prefix "status-test-"

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

  defp tracked!(kind, cached_attrs) do
    id = @prefix <> Integer.to_string(System.unique_integer([:positive]))

    Ash.create!(
      CachedTitle,
      Map.merge(
        %{
          source: :manual,
          source_id: id,
          kind: kind,
          title: "A Title",
          fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
        },
        cached_attrs
      )
    )

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: id,
      kind: kind,
      status: :watching
    })
  end

  defp status_of(id), do: TrackedTitle |> Ash.get!(id) |> Map.get(:status)

  describe "a film" do
    test "is finished by logging a watch of it" do
      film = tracked!(:movie, %{runtime_minutes: 116})

      assert status_of(film.id) == :watching

      assert {:ok, _watch} =
               Rating.save_watch(%{
                 watch_id: nil,
                 tracked_title_id: film.id,
                 watch: %{rating: 4.0, review: nil}
               })

      assert status_of(film.id) == :finished
    end
  end

  describe "a series" do
    test "ticking one of nine leaves it watching" do
      series = tracked!(:tv, %{episode_count: 9})

      assert :ok = Series.write_tick(series.id, %{source_id: "ep-1", watched: false})
      assert :ok = Series.restate(series.id)

      assert status_of(series.id) == :watching
    end

    test "ticking the last one finishes it" do
      series = tracked!(:tv, %{episode_count: 3})

      for n <- 1..3 do
        assert :ok = Series.write_tick(series.id, %{source_id: "ep-#{n}", watched: false})
      end

      assert :ok = Series.restate(series.id)
      assert status_of(series.id) == :finished
    end

    test "unticking one takes it back out of finished" do
      series = tracked!(:tv, %{episode_count: 2})

      for n <- 1..2,
          do: Series.write_tick(series.id, %{source_id: "ep-#{n}", watched: false})

      Series.restate(series.id)
      assert status_of(series.id) == :finished

      # `watched: true` is the untick — the row exists and is destroyed.
      assert :ok = Series.write_tick(series.id, %{source_id: "ep-2", watched: true})
      assert :ok = Series.restate(series.id)

      assert status_of(series.id) == :watching
    end

    test "a series whose episode count nobody knows is left alone" do
      # A hand-typed series, or one the provider has not filled. Inventing
      # *finished* out of a total nobody knows is the one thing the page
      # cannot assert.
      series = tracked!(:tv, %{})

      Series.write_tick(series.id, %{source_id: "ep-1", watched: false})
      assert :ok = Series.restate(series.id)

      assert status_of(series.id) == :watching
    end

    test "restate/1 with no id is a no-op rather than a raise" do
      assert Series.restate(nil) == :ok
      assert Series.restate(Ash.UUID.generate()) == :ok
    end
  end
end
