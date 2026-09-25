defmodule Kati.AddByHandDarkTest do
  @moduledoc """
  Screen 157 types, and stops writing a title nobody asked for.

  The audit's finding: *"None of the three text fields accept input, and Add
  to library writes the hardcoded fixture title 'The Long Hollow' into the
  user's real library."*

  Both halves come from the same habit — a board's captured frame put into a
  `load/1`:

    * The screen loaded `title: "The Long Hollow", kind: :tv, year: "2024"`,
      which is the state board 157 was drawn in, and then offered a button
      that writes what is loaded. So looking at a colourway specimen added a
      series to somebody's library.
    * It delegates `content/1` and `handle_tap/2` to `Kati.Screens.AddByHand`
      and stopped there, so the fields it draws carry that screen's
      `on_change` and every `{:change, …}` fell through
      `Kati.Screens.Pushed`'s catch-all. Three fields drawn, none typeable,
      and no way to see it: a field renders its value, and the value never
      moved.

  The captured frame lives in `Kati.ScreenDesignLiteralTest.drawn_state/0`
  now, which is where a captured frame belongs.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.TrackedTitle
  alias Kati.Screens.AddByHandDark

  describe "what it opens on" do
    test "is the resting state board 155 states, not board 157's frame" do
      view = mount_screen(AddByHandDark)

      assert assigns(view).title == ""
      assert assigns(view).kind == :movie
      assert assigns(view).year == ""
    end

    test "so Add to library with nothing typed writes nothing" do
      view = mount_screen(AddByHandDark)
      view = render_info(view, {:tap, :add})

      assert Ash.read!(TrackedTitle) == []
      assert assigns(view).save_error != nil
    end
  end

  describe "the three fields" do
    for field <- [:title, :year, :episodes] do
      test "#{field} holds what was typed" do
        view = mount_screen(AddByHandDark)
        view = render_info(view, {:change, unquote(field), "typed"})

        assert Map.fetch!(assigns(view), unquote(field)) == "typed"
      end
    end

    test "and what is typed is what gets written" do
      view = mount_screen(AddByHandDark)
      view = render_info(view, {:change, :title, "addbyhanddark-Tidewrack"})
      view = render_info(view, {:tap, :add})

      assert [%{source_id: "addbyhanddark-Tidewrack"}] = Ash.read!(TrackedTitle)
      assert assigns(view).save_error == nil

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", ["addbyhanddark-%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", ["addbyhanddark-%"])
    end

    test "and The Long Hollow is not among them" do
      view = mount_screen(AddByHandDark)
      view = render_info(view, {:tap, :add})

      refute Enum.any?(Ash.read!(TrackedTitle), &(&1.source_id == "The Long Hollow"))
      assert assigns(view).title == ""
    end
  end

  describe "the colourway" do
    test "is still dark" do
      Kati.Theme.Mode.put(:light)
      Kati.Theme.activate()

      mount_screen(AddByHandDark)

      assert Kati.Theme.Palette.mode() == :dark
    end
  end
end
