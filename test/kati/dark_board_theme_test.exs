defmodule Kati.DarkBoardThemeTest do
  @moduledoc """
  Looking at a dark board does not leave the app dark.

  Seven boards are drawn in the dark colourway and each
  sets the dark palette in its own `load/1`. `Mob.Theme.set/1` is global and a
  pop does not remount the screen it returns to, so opening one left the whole
  app dark — a dark Settings, a dark Library, a dark Home — until some other
  pushed screen mounted and `Kati.Screens.Pushed`'s macro re-activated the
  preference. Nothing the reader could press said so or undid it.

  `Kati.Screens.Resume.pop/1` re-activates, at the one place every back control
  in the app already goes through.
  """

  use Mob.ScreenCase, async: false

  @dark [
    Kati.Screens.AddByHandDark,
    Kati.Screens.HomeDark,
    Kati.Screens.BackupDark,
    Kati.Screens.BookDetailDark,
    Kati.Screens.HomeEmptyDark
  ]

  setup do
    Kati.Theme.Mode.put(:light)
    Kati.Theme.activate()
    :ok
  end

  describe "a board drawn in the dark colourway" do
    for module <- @dark do
      test "#{inspect(module)} sets the app dark while it is open" do
        assert Kati.Theme.Palette.mode() == :light

        {:ok, _socket} =
          unquote(module).mount(%{}, %{}, Mob.Socket.new(unquote(module)))

        assert Kati.Theme.Palette.mode() == :dark,
               "this board is drawn dark and did not set the palette"
      end

      test "#{inspect(module)} and the reader's own theme comes back on the way out" do
        {:ok, _socket} =
          unquote(module).mount(%{}, %{}, Mob.Socket.new(unquote(module)))

        assert Kati.Theme.Palette.mode() == :dark

        Kati.Screens.Resume.pop(Mob.Socket.new(unquote(module)))

        assert Kati.Theme.Palette.mode() == :light,
               "the app is still dark after backing out of a dark board"
      end
    end
  end

  describe "a reader whose own choice is dark" do
    test "keeps it across a pop" do
      Kati.Theme.Mode.put(:dark)
      Kati.Theme.activate()

      Kati.Screens.Resume.pop(Mob.Socket.new(Kati.Screens.Library))

      assert Kati.Theme.Palette.mode() == :dark,
             "popping re-activated the preference and got the wrong one"
    end
  end
end
