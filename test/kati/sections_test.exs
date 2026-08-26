defmodule Kati.SectionsTest do
  @moduledoc """
  #86 — the sections you pick survive being picked.

  The first run asks *"Pick two. More later from 24."* and threw the answer
  away with the socket: `Kati.Screens.PickSections` toggled a `MapSet` on an
  assign, the screen popped, and the app then showed every section to
  everybody. A question asked and discarded is worse than one never asked — it
  teaches someone their answer counts, once.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.PickSections

  setup do
    # Setup only, no `on_exit`. `Mob.ScreenCase` restarts `Mob.State` around
    # every test, so there is nothing left to clean by the time an exit
    # callback runs — and calling it then raises `no process`, which turns a
    # passing test into a confusing failure in the teardown of the one after.
    #
    # This is the opposite of #87's case, where the store is SQLite and DOES
    # survive the test: there, cleaning on both sides is what stopped the suite
    # going order-dependent.
    Kati.Sections.forget!()
    :ok
  end

  describe "what is kept" do
    test "everything, before the first run has said otherwise" do
      # Not `[]`. A brand-new install showing nothing at all is
      # indistinguishable from an install that is broken, which is the exact
      # confusion this project is working to end.
      assert Kati.Sections.chosen() == Kati.Sections.all()
      assert Kati.Sections.on?("screen")
      assert Kati.Sections.on?("music")
    end

    test "a choice survives being made" do
      assert :ok = Kati.Sections.put(["screen", "books"])

      assert Kati.Sections.chosen() == ["screen", "books"]
      assert Kati.Sections.on?("screen")
      refute Kati.Sections.on?("music")
    end

    test "kept in the order the first run draws them, not the order they were tapped" do
      assert :ok = Kati.Sections.put(["notes", "screen"])

      assert Kati.Sections.chosen() == ["screen", "notes"],
             "the grid has an order and the shelf switcher reads it; tap order is not a preference"
    end

    test "nothing is refused, and an unknown id is not a section" do
      assert {:error, :none_chosen} = Kati.Sections.put([])
      assert {:error, :none_chosen} = Kati.Sections.put(["not_a_section"])

      assert Kati.Sections.chosen() == Kati.Sections.all(),
             "a refused write must leave the previous answer alone"
    end
  end

  describe "the first run" do
    test "Continue stores what was chosen" do
      view = mount_screen(PickSections)

      # The drawing arrives with screen and books already on.
      _ = render_info(view, {:tap, :continue})

      assert Kati.Sections.chosen() == ["screen", "books"]
    end

    test "Continue with zero is refused, and the run does not advance" do
      # The step's own copy promises the button counts — "Continue with 2".
      view = mount_screen(PickSections)

      view = render_info(view, {:tap, :section_screen})
      view = render_info(view, {:tap, :section_books})
      assert MapSet.size(assigns(view).chosen) == 0

      view = render_info(view, {:tap, :continue})

      assert navigated_to(view) == nil,
             "the run walked past a step that had refused to be answered"

      assert Kati.Sections.chosen() == Kati.Sections.all(),
             "nothing should have been stored"
    end
  end

  describe "turning a section off removes it everywhere" do
    test "the Library switcher offers only the shelves you kept" do
      :ok = Kati.Sections.put(["screen"])

      tree = tree(mount_screen(Kati.Screens.Library))

      assert find(tree, :text, text: "Screen") != nil

      assert find(tree, :text, text: "Books") == nil,
             "a shelf you turned off was still offered, and it can never hold anything"

      assert find(tree, :text, text: "Music") == nil
    end

    test "the home cards drop a section that is off" do
      :ok = Kati.Sections.put(["screen"])

      tree = tree(mount_screen(Kati.Screens.Home))

      assert find(tree, :text, text: "Habits") == nil,
             "the home card outlived the choice, which is the design's rule failing quietly"

      # Meals and Settings are not sections the first run offers, so they stay.
      assert find(tree, :text, text: "Settings") != nil
    end

    test "with everything kept, nothing is hidden" do
      :ok = Kati.Sections.put(Kati.Sections.all())

      tree = tree(mount_screen(Kati.Screens.Library))

      for shelf <- ["Screen", "Books", "Music"] do
        assert find(tree, :text, text: shelf) != nil, "#{shelf} went missing"
      end
    end
  end
end
