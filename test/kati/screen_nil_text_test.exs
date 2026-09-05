Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ScreenNilTextTest do
  @moduledoc """
  No screen draws a `Text` with nothing in it.

  ## `text={nil}` is not an empty line

  It is the word **nil**, in the page's own type, where the copy should be.
  The prop is passed through `Mob.Renderer` untouched and reaches the bridge as
  the atom; Compose draws what it is handed. A host test sees `text: nil` in
  the tree and has no opinion about it, which is why this file exists and why
  it was written after a device found the defect rather than before.

  What the device showed: the first book added by hand with no author, on
  screen 66, printing

      It Almanac toS
      nil

  under the title — `Kati.UI.SettingsList.subtitle/2` drawing `b.author`
  straight into `text=`. The sweep found one more the same afternoon, on
  screen 109, through the same helper and invisible for the same reason: no
  fixture in the app had ever left that field empty.

  ## Why a sweep rather than a test per screen

  The defect is not in a screen, it is in a *habit* — a value read off a row
  and handed to `text=` without asking whether the row has one. Every screen
  in the app does that dozens of times, and the ones that will break are the
  ones nobody has data for yet. So this walks every screen in both locales and
  asks one question, and it costs a second.

  A screen drawing its fixture is the weakest case this can check: fixtures
  are complete by construction. It is still worth checking, because a fixture
  that grows a `nil` is a screen that will draw **nil** for every user on the
  day it ships, and this is the only thing in the suite that would say so.
  """

  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  @locales [:en, :fa]

  describe "every screen, in both locales" do
    test "no Text node is drawn with a nil text prop" do
      offenders =
        for locale <- @locales,
            {module, nils} <- ScreenSweep.with_locale(locale, fn -> nil_texts() end),
            do: "  #{locale} #{inspect(module)} draws #{length(nils)}: #{inspect(hd(nils))}"

      assert offenders == [],
             "these screens hand `text=` a nil. On a device that is not a blank line — it is " <>
               "the word `nil` in the page's own type, where the copy should be. Give the " <>
               "helper a nil clause that draws nothing, or give the value a fallback:\n" <>
               Enum.join(offenders, "\n")
    end

    test "the sweep actually looked at the screens" do
      # A sweep whose render always errored would pass the test above in
      # silence. `Kati.ScreenRenderSweepTest` is what fails over a screen that
      # cannot render; this only has to prove it saw enough of them to mean
      # something.
      drawn = ScreenSweep.with_locale(:en, fn -> Enum.count(ScreenSweep.screens(), &drawn?/1) end)

      assert drawn >= 150,
             "only #{drawn} screens rendered, so the sweep above passed over almost nothing"
    end
  end

  defp nil_texts do
    for module <- ScreenSweep.screens(),
        {:ok, _socket, tree} <- [ScreenSweep.render(module)],
        nils = nil_text_nodes(tree),
        nils != [],
        do: {module, nils}
  end

  defp nil_text_nodes(tree) do
    tree
    |> Mob.ScreenCase.flatten()
    |> Enum.filter(fn node ->
      node.type == :text and Map.get(node.props || %{}, :text) == nil
    end)
    |> Enum.map(&Map.get(&1, :props))
  end

  defp drawn?(module), do: match?({:ok, _socket, _tree}, ScreenSweep.render(module))
end
