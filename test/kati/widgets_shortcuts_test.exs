Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.WidgetsShortcutsTest do
  @moduledoc """
  Screen 39's voice-shortcut switches: drawn, and remembered.

  They flipped an assign and nothing else, and `shortcuts/1` was never called
  from the page at all — the section the board draws was missing and the
  switches that were there forgot themselves on the way back.
  """
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.ScreenSweep
  alias Kati.Screens.Widgets
  alias Kati.Widgets.{Sample, Shortcuts}

  setup do
    Shortcuts.forget!()
    on_exit(&Shortcuts.forget!/0)
    :ok
  end

  test "the section is on the page, with the drawing's three phrases" do
    assert {:ok, _socket, tree} = ScreenSweep.render(Widgets)
    texts = DesignLiterals.rendered(tree)

    assert "shortcuts" in texts
    assert Enum.any?(texts, &String.contains?(&1, "hey siri"))
    assert Enum.any?(texts, &String.contains?(&1, "mark it watched"))
    assert Enum.any?(texts, &String.contains?(&1, "add to my list"))
  end

  test "a flipped switch is still flipped on the next mount" do
    view = mount_screen(Widgets)
    assert Enum.at(assigns(view).widgets.shortcuts, 0).toggle == true

    view = render_info(view, {:tap, :shortcut_0})
    assert Enum.at(assigns(view).widgets.shortcuts, 0).toggle == false

    reopened = mount_screen(Widgets)
    assert Enum.at(assigns(reopened).widgets.shortcuts, 0).toggle == false

    # The other two keep the drawing's position.
    assert Enum.at(assigns(reopened).widgets.shortcuts, 1).toggle == true
  end

  test "applying stored values leaves an unset row as drawn" do
    rows = Shortcuts.apply(Sample.shortcuts())

    toggles = Enum.filter(rows, &Map.has_key?(&1, :toggle))

    assert length(toggles) == 3

    assert Enum.all?(toggles, & &1.toggle),
           "a fresh install should show the board's three switches on"
  end
end
