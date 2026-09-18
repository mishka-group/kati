defmodule Kati.SeriesSeasonPillsTest do
  @moduledoc """
  A long-running show's season pills can be reached.

  `episodes_header/1` laid the EPISODES eyebrow and every season pill in one
  `Row` that does not scroll, so the pills ran off the side of the phone and
  stayed there. *The Simpsons* has thirty-six seasons and *Doctor Who* has
  thirty-nine; on either, a reader could not open season 9 at all. The row was
  the only arrangement the screen had. MOVIES-AND-TV.md `04 scenario`.

  Board 04 draws three pills, inline and right-aligned, and that is still what a
  three-season show gets — the fix is a second arrangement for the case the
  board never had to draw, not a replacement for the one it did.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Series

  defp seasons(n), do: Enum.map(1..n, &("S" <> to_string(&1)))

  describe "the threshold" do
    test "board 04's own three stay on the eyebrow's row" do
      assert Series.seasons_inline?(seasons(3))
    end

    test "and a show with nothing listed does not break it" do
      assert Series.seasons_inline?([])
    end

    test "seven fit and eight do not, which is the pill geometry and not a guess" do
      # 30pt wide, 5pt gap, so n measure 35n - 5 against 254pt of room.
      assert Series.seasons_inline?(seasons(7))
      refute Series.seasons_inline?(seasons(8))
    end

    test "and nothing long fits" do
      refute Series.seasons_inline?(seasons(36)), "The Simpsons"
      refute Series.seasons_inline?(seasons(39)), "Doctor Who"
    end
  end

  describe "the header" do
    test "draws every pill either way, and only one arrangement at a time" do
      for n <- [3, 8, 39] do
        drawn =
          inspect(
            Series.episodes_header(%{seasons: seasons(n), current_season: "S1"}),
            limit: :infinity
          )

        for label <- seasons(n) do
          assert drawn =~ "season_" <> label,
                 "#{label} is not reachable on a #{n}-season show"
        end
      end
    end

    test "and the long case is the one that scrolls" do
      short =
        inspect(Series.episodes_header(%{seasons: seasons(3), current_season: "S1"}),
          limit: :infinity
        )

      long =
        inspect(Series.episodes_header(%{seasons: seasons(39), current_season: "S1"}),
          limit: :infinity
        )

      refute short =~ "horizontal",
             "board 04's own three-pill row started scrolling, which is not what it draws"

      assert long =~ "horizontal",
             "thirty-nine pills are still in a row that cannot be scrolled"
    end
  end
end
