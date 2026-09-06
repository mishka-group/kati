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
  MOVIES-AND-TV.md #39, and the English half of `D-60`'s argument.
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

    test "and draws it" do
      {:ok, socket} = Series.mount(%{}, %{}, Mob.Socket.new(Series))
      ticked = Series.tick(socket, "0")

      drawn = inspect(Series.render(ticked.assigns), limit: :infinity)

      assert drawn =~ ticked.assigns.save_error,
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
      failed = Mob.Socket.assign(socket, :save_error, "That did not save.")

      assert inspect(Season.content(failed.assigns), limit: :infinity) =~ "That did not save."
    end

    test "and nothing when there is nothing to say" do
      {:ok, socket} = Season.mount(%{}, %{}, Mob.Socket.new(Season))

      assert socket.assigns.save_error == nil
    end
  end
end
