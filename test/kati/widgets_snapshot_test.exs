defmodule Kati.Widgets.SnapshotTest do
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Widgets.Snapshot

  @moduletag :tmp_dir

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    Kati.Repo.query!("DELETE FROM media_watches", [])
    Kati.Repo.query!("DELETE FROM tracked_titles", [])
    Kati.Repo.query!("DELETE FROM cached_titles", [])
  end

  test "drops the hero key entirely when nothing is on the go", %{tmp_dir: dir} do
    :ok = Snapshot.put(nil, dir: dir)

    body = File.read!(Snapshot.path(dir: dir))
    refute Map.has_key?(JSON.decode!(body), "hero")
  end

  test "writes the real hero, atomically", %{tmp_dir: dir} do
    hero = %{title: "The Long Hollow", meta: "S2 · E6 · 18m left"}
    :ok = Snapshot.put(hero, dir: dir)

    body = File.read!(Snapshot.path(dir: dir))

    assert %{"hero" => %{"title" => "The Long Hollow", "meta" => "S2 · E6 · 18m left"}} =
             JSON.decode!(body)

    refute File.exists?(Snapshot.path(dir: dir) <> ".tmp")
  end

  test "refresh/1 reads the real shelf and drops hero when it is empty", %{tmp_dir: dir} do
    :ok = Snapshot.refresh(dir: dir)

    body = File.read!(Snapshot.path(dir: dir))
    refute Map.has_key?(JSON.decode!(body), "hero")
  end

  test "refresh/1 writes the real title once one is watching", %{tmp_dir: dir} do
    source_id = "widget-snapshot-test"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: "Ashfall",
      fetched_at: DateTime.utc_now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching,
      progress_season: 1,
      progress_episode: 2
    })

    :ok = Snapshot.refresh(dir: dir)

    body = File.read!(Snapshot.path(dir: dir))
    assert %{"hero" => %{"title" => "Ashfall"}} = JSON.decode!(body)
  end
end
