Code.require_file("../support/keyless_stubs.exs", __DIR__)

defmodule Kati.AddTitleFillTest do
  @moduledoc """
  Adding a catalogue title is a local write; the catalogue fills in behind it.

  The + on a search row used to wait on the detail call, one request per
  season and the poster before anything was written, so a long series sat for
  seconds. `Kati.Screens.AddTitle.track/3` now writes the cached and tracked
  rows from the search row at once and fetches in a task, telling the screen
  `{:kati, :title_filled, id}` when it lands.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.AddTitle
  alias Kati.Test.KeylessStubs

  @tables ~w(media_events media_watches tracked_titles cached_episodes cached_seasons cached_titles)

  setup do
    wipe!()
    Application.put_env(:kati, :fill_titles_in_background, true)

    unless Process.whereis(:mob_screen), do: Process.register(self(), :mob_screen)

    on_exit(fn ->
      Application.put_env(:kati, :fill_titles_in_background, false)
      KeylessStubs.restore!()
      wipe!()
    end)

    :ok
  end

  test "the title is on the shelf before the catalogue answers, and filled after" do
    KeylessStubs.install!()

    row = %{
      source: :anilist,
      source_id: "177709",
      kind: :tv,
      title: "SAKAMOTO DAYS",
      year: "2025",
      overview: "A retired hitman runs a shop.",
      poster_path: nil
    }

    assert {:ok, tracked} = AddTitle.track("SAKAMOTO DAYS", row)

    assert [%{source_id: "177709"}] = Ash.read!(TrackedTitle)
    assert tracked.kind == :anime
    cached = Enum.find(Ash.read!(CachedTitle), &(&1.source_id == "177709"))
    assert cached.title == "SAKAMOTO DAYS"
    assert cached.first_release_year == 2025

    assert_receive {:kati, :title_filled, id}, 5_000
    assert id == tracked.id
    assert Enum.count(Ash.read!(CachedEpisode), &(&1.title_source_id == "177709")) > 0
  end

  test "a catalogue that cannot answer still leaves the title added" do
    KeylessStubs.install!(anilist: 503)

    row = %{source: :anilist, source_id: "177709", kind: :tv, title: "SAKAMOTO DAYS"}

    assert {:ok, tracked} = AddTitle.track("SAKAMOTO DAYS", row)
    assert_receive {:kati, :title_filled, id}, 5_000
    assert id == tracked.id
    assert [%{source_id: "177709"}] = Ash.read!(TrackedTitle)
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end
end
