defmodule Kati.TickStatusTest do
  @moduledoc """
  A tick moves the shelf, however the tick was made.

  Two gaps left after titles stopped being added as *watching* (N52-C): a
  series nobody knows the episode count of stayed *not started* however many
  episodes were ticked, because the count gated the whole update; and a tick
  Kati made on its own (`Kati.Media.Detect.tick/2`) was a watch row and
  nothing else, so the show it ticked, or the film it logged, never moved.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.Detect
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  doctest Kati.Screens.Series, only: [status_after: 3]

  @prefix "tick-status-test-"

  setup do
    on_exit(&wipe!/0)
    wipe!()
    :ok
  end

  defp wipe! do
    for resource <- [Watch, TrackedTitle, CachedTitle],
        row <- Ash.read!(resource),
        String.starts_with?(to_string(Map.get(row, :source_id) || row_title(row)), @prefix),
        do: Ash.destroy!(row)
  rescue
    _error -> :ok
  end

  defp row_title(%Watch{} = watch) do
    case Ash.get(TrackedTitle, watch.tracked_title_id) do
      {:ok, tracked} -> tracked.source_id
      _gone -> @prefix
    end
  end

  defp row_title(_row), do: ""

  defp shelve!(title, kind, count \\ nil) do
    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: kind,
      title: title,
      episode_count: count,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: kind,
      status: :not_started
    })
  end

  defp status(tracked), do: Ash.get!(TrackedTitle, tracked.id).status

  test "a series with no known episode count is watching after its first tick" do
    tracked = shelve!("Hand-typed show", :tv)

    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      episode_source_id: @prefix <> "ep1",
      watched_at: DateTime.truncate(Kati.Time.now(), :second),
      watched_on: Kati.Time.today()
    })

    Kati.Screens.Series.restate(tracked.id)

    assert status(tracked) == :watching
  end

  test "a detected episode tick moves a series to watching" do
    tracked = shelve!("Detected show", :tv, 8)

    assert {:ok, :ticked} = Detect.tick(tracked, @prefix <> "ep1")
    assert status(tracked) == :watching
  end

  test "a detected tick of the last episode finishes the series" do
    tracked = shelve!("Short show", :tv, 1)

    assert {:ok, :ticked} = Detect.tick(tracked, @prefix <> "ep1")
    assert status(tracked) == :finished
  end

  test "a detected film watch finishes the film" do
    tracked = shelve!("Detected film", :movie)

    assert {:ok, :ticked} = Detect.tick(tracked, nil)
    assert status(tracked) == :finished
  end
end
