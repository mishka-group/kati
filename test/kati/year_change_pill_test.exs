defmodule Kati.YearChangePillTest do
  @moduledoc """
  The pill beside *Time watched* on screen 07.

  Two mistakes, and they are different ones.

    * **A first year has no last year.** `change/2` answered `0` for a prior
      year of zero minutes, so a device whose history begins today drew
      `↑ 0%` in green — a claim of *level with last year* about a year that
      does not exist.
    * **A year that fell was green.** The arrow had a falling branch and the
      colours did not: glyph and number were `green_text` on `green_wash`
      whatever the direction, so watching less than last year was
      congratulated in the same colour as watching more.

  Board 07's year rises, so the drawn frame is unchanged either way — which is
  exactly why neither of these could be found by comparing against it.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Stats
  alias Kati.Theme.Palette

  describe "with nothing to compare against" do
    test "no pill is drawn at all" do
      drawn = inspect(Stats.change_pill(%{change: nil, rising?: true}), limit: :infinity)

      assert drawn == inspect(%{type: :spacer, children: [], props: %{size: 0}})
    end

    test "and nothing on it is a percentage" do
      drawn = inspect(Stats.change_pill(%{change: nil, rising?: true}), limit: :infinity)

      # `%` appears in `inspect`'s own map syntax, so the claim is about the
      # nodes: a spacer has no text and no ground.
      refute drawn =~ ":text"
      refute drawn =~ to_string(Palette.green_wash())
    end
  end

  describe "a year that rose" do
    test "is green, and points up" do
      drawn = inspect(Stats.change_pill(%{change: "12%", rising?: true}), limit: :infinity)

      assert drawn =~ "12%"
      assert drawn =~ to_string(Palette.green_text())
      assert drawn =~ to_string(Palette.green_wash())
      refute drawn =~ to_string(Palette.red_wash())
    end
  end

  describe "a year that fell" do
    test "is not green" do
      drawn = inspect(Stats.change_pill(%{change: "12%", rising?: false}), limit: :infinity)

      assert drawn =~ "12%"
      assert drawn =~ to_string(Palette.red())
      assert drawn =~ to_string(Palette.red_wash())

      refute drawn =~ to_string(Palette.green_wash()),
             "a year the reader watched less in was drawn on the ground that means good news"
    end

    test "and points down" do
      down = inspect(Stats.arrow(%{rising?: false}), limit: :infinity)
      up = inspect(Stats.arrow(%{rising?: true}), limit: :infinity)

      refute down == up
      assert down =~ to_string(Palette.red())
    end
  end
end
