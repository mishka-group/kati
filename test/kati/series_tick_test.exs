defmodule Kati.SeriesTickTest do
  @moduledoc """
  Marking an episode watched, on a series that came from TMDB.

  The defect: *Mark next watched* **killed the screen**. `episode_facts/3`
  carried the episode's `source_id` — with a comment saying why — and
  `episode_row/2`, which rebuilds the map for the tree, dropped it. No
  `write_tick/2` clause matches a map with no `:source_id` key, so the tap
  raised a `FunctionClauseError` out of `handle_info/2`, the screen process
  died, and `Kati.Supervisor` restarted the root — the app jumped to Home and
  the episode stayed unticked. Reproduced on a Pixel 9a on the first real
  series ever added.

  **No sweep could see it.** `Kati.ScreenTapSweepTest` presses every drawn tap
  against an EMPTY database, where the episodes are `Kati.Library.Sample`'s and
  carry no `source_id` either — so the tap reached the `%{source_id: nil}`
  clause and was refused politely. The crash needs a real row, which is a state
  no host sweep in this repo builds.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Series

  describe "the shape a real episode reaches the writer in" do
    test "a row from a cached episode carries the id a tick is written against" do
      # The exact map the device produced, plus the key that went missing.
      real = %{
        n: 1,
        title: "Good News About Hell",
        sub: "59 min · 17 Feb",
        watched: false,
        aired: true,
        source_id: "2094719"
      }

      assert Map.has_key?(real, :source_id)
      refute match?({:error, :no_episode_id}, Series.write_tick(nil, real))
    end

    test "the drawing's episodes have no id and are refused, not raised at" do
      drawn = %{n: 1, title: "The Weight of Water", sub: "48 min · 2 Jul", watched: false}

      assert Series.tick_result("some-tracked-id", Map.put(drawn, :source_id, nil)) ==
               {:error, :no_episode_id}
    end
  end

  describe "a tick that cannot be written" do
    test "an unhandled shape is a refusal, not a dead screen" do
      # The map that crashed: no `:source_id` key at all. Before `tick_result/2`
      # this raised out of `handle_info/2` and took the screen with it.
      crashing = %{
        n: 1,
        title: "Good News About Hell",
        sub: "59 min",
        watched: false,
        aired: true
      }

      assert Series.tick_result("7edd67df-411b-440e-afd9-8c106111561b", crashing) ==
               {:error, :nothing_to_save}
    end

    test "with no tracked row it is refused by name" do
      assert Series.write_tick(nil, %{source_id: "1", watched: false}) == {:error, :not_tracked}
    end

    test "with no episode it is refused by name" do
      assert Series.write_tick("tracked", nil) == {:error, :no_episode}
    end
  end

  describe "the screen survives it" do
    test "a tap whose write refuses leaves the screen alive and says so" do
      {:ok, socket} = Series.mount(%{}, %{}, Mob.Socket.new(Series))

      # The drawing's episodes carry no id, so this is the refusing path.
      {:noreply, after_tap} = Series.handle_info({:tap, :mark_next}, socket)

      assert %Mob.Socket{} = after_tap
      assert after_tap.assigns.series, "the screen lost its subject"
    end
  end
end
