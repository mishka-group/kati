Code.require_file("../support/show_boards.exs", __DIR__)

defmodule Kati.TickRefusalTest do
  @moduledoc """
  A tick the store refused says so.

  Screens 04 and 34 have assigned `:save_error` since the day a tick could
  fail, and neither drew it. So a refused tick was a tap into total nothing:
  the row did not fill, the counter did not move, and the page said no more
  than it would have if the finger had missed the row.

  It is not a rare branch. `write_tick/2` refuses every episode with no
  `source_id`, which is every episode of the drawn series — so on a device with
  nothing tracked, EVERY tap on an episode row is a silent refusal.
  It is the English half of `D-60`'s argument.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Season
  alias Kati.Screens.Series

  describe "screen 04" do
    test "assigns a refusal when the write is refused" do
      {:ok, socket} = Series.mount(%{}, %{}, Mob.Socket.new(Series))

      # The drawn series' episodes carry no `source_id`, so this is the refusal
      # every device without a tracked series gets.
      ticked = Series.tick(socket, "0")

      assert is_binary(ticked.assigns.save_error)
    end

    # Over a real series: a bare mount over a shelf with no series is now the
    # page that says so, with no episode to tick and nowhere a band belongs.
    test "and draws it" do
      source_id = "tick-refusal-#{System.unique_integer([:positive])}"

      Ash.create!(Kati.Media.CachedTitle, %{
        source: :manual,
        source_id: source_id,
        kind: :tv,
        title: "Refusal Probe",
        fetched_at: Kati.Time.now()
      })

      tracked =
        Ash.create!(Kati.Media.TrackedTitle, %{
          source: :manual,
          source_id: source_id,
          kind: :tv,
          status: :watching
        })

      {:ok, socket} = Series.mount(%{id: tracked.id}, %{}, Mob.Socket.new(Series))
      failed = Mob.Socket.assign(socket, :save_error, "That did not save.")

      drawn = inspect(Series.render(failed.assigns), limit: :infinity)

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id = ?1", [source_id])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id = ?1", [source_id])

      assert drawn =~ "That did not save.",
             "screen 04 assigns the refusal and draws it nowhere, which is the defect"
    end

    test "a page with nothing wrong draws no band" do
      {:ok, socket} = Series.mount(%{}, %{}, Mob.Socket.new(Series))

      assert socket.assigns.save_error == nil
      refute inspect(Series.render(socket.assigns), limit: :infinity) =~ "error"
    end
  end

  describe "screen 34" do
    test "draws the refusal its own tick assigns" do
      {:ok, socket} = Season.mount(%{}, %{}, Mob.Socket.new(Season))

      # N52-A: an empty store draws one sentence and no rows, so there is no
      # tick to refuse; the board's season is the page a refusal lands on.
      failed =
        socket
        |> Mob.Socket.assign(:season, Kati.Test.ShowBoards.season())
        |> Mob.Socket.assign(:save_error, "That did not save.")

      assert inspect(Season.content(failed.assigns), limit: :infinity) =~ "That did not save."
    end

    test "and nothing when there is nothing to say" do
      {:ok, socket} = Season.mount(%{}, %{}, Mob.Socket.new(Season))

      assert socket.assigns.save_error == nil
    end
  end
end
