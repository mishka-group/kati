Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ThemeCoverageTest do
  @moduledoc """
  Which screens actually respond to the theme — asked of every screen at once.

  A screen that renders an IDENTICAL tree in light and in dark is one that
  ignores the theme: every colour in it is a literal the palette never sees.
  That is the defect the dark-mode work exists to remove, and it is invisible
  from a screenshot of either mode alone — you have to compare the two.

  Doing that on the device means two full capture runs. This asks the same
  question of the render tree in seconds, exhaustively, and keeps asking it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  # Set the stored CHOICE, not the palette.
  #
  # The first version of this installed a palette with `Mob.Theme.set/1` and
  # rendered — and every screen came back identical in both modes, which looked
  # like 60 broken screens. It was the test: `mount/3` calls
  # `Kati.Theme.activate/0`, which re-resolves the stored preference and
  # overwrites the palette a moment before the render. Both passes therefore
  # rendered light. Driving the preference is what a user does, and it is the
  # only input the screen actually reads.
  defp trees(module) do
    Kati.Theme.Mode.put(:light)
    {:ok, _s, light} = ScreenSweep.render(module)

    Kati.Theme.Mode.put(:dark)
    {:ok, _s, dark} = ScreenSweep.render(module)

    Kati.Theme.Mode.put(:light)
    {light, dark}
  end

  # Screens drawn dark BY DESIGN. They install their own palette and are
  # supposed to look the same whatever the app is set to — 28 and 29 are the
  # design's only dark drawings and the reference the rest were derived from.
  @drawn_dark [
    Kati.Screens.HomeDark,
    Kati.Screens.Lock,
    # Screen 68 joined the pair: it is screen 66 in the dark colourway and pins
    # dark for the same reason 28 and 29 do — the page IS the dark one, and a
    # dark drawing that followed the stored theme would draw its light twin
    # whenever the phone was set to light.
    Kati.Screens.AddByHandDark,
    Kati.Screens.HomeFaEmptyDark,
    Kati.Screens.BookDetailDark,
    # Screen 102 for the same reason: it is 98 in the dark colourway, and a dark
    # drawing that followed the stored theme would draw its light twin whenever
    # the phone was set to light.
    Kati.Screens.YearShareDark,
    # 131 is 128 in the dark colourway, and pins dark for the same reason 102
    # does: a board drawn dark in a light app has to install the palette it was
    # drawn against or it is a light screen with dark copy.
    Kati.Screens.BackupDark
  ]

  test "every screen responds to the theme, except the ones drawn dark" do
    modules = Kati.Screens.Gallery.screens() |> Enum.map(&elem(&1, 2)) |> Enum.uniq()

    blind =
      for module <- modules, module not in @drawn_dark do
        {light, dark} = trees(module)
        if light == dark, do: module
      end
      |> Enum.reject(&is_nil/1)

    assert modules != [], "no screens measured — the gallery list is the source"

    assert blind == [],
           """
           #{length(blind)} screen(s) render an IDENTICAL tree in light and dark,
           so every colour in them is a literal the palette never sees:

             #{Enum.map_join(blind, "\n  ", &inspect/1)}
           """
  end

  test "the two drawn-dark screens really are unaffected by the app's theme" do
    # The mirror of the test above, and it has to be asserted rather than
    # assumed: if these ever start following the app's palette, screen 28 goes
    # light in a light app and the design's only dark reference is gone.
    for module <- @drawn_dark do
      {light, dark} = trees(module)
      assert light == dark, "#{inspect(module)} is drawn dark and must not follow the app theme"
    end
  end
end
