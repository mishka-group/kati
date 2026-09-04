Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.PushedFrameTest do
  @moduledoc """
  A pushed screen puts its content inside a scroll with the board's margins.

  ## What went wrong, twice, and what did not notice

  `Kati.Screens.Pushed` builds that frame for the Latin screens.
  `Kati.Screens.Fa.pushed_frame/2` does not: it is the root `Box` and nothing
  else — it declares `rtl` and paints the background — and every Persian
  screen inside it has been writing the same `Scroll` and padded `Column` by
  hand. Four written in one round forgot to, and on a device the result is a
  page whose step rail has scrolled up under the status bar and whose headline
  runs off the leading edge, because a `Column` with no padding starts at the
  pixel.

  Every host test passed. The tree is one root node, every literal the drawing
  contains is in it, every control is tappable, the taps go where they should.
  A layout has no assertion in any of them — it was found by opening the app
  and looking at it, which is the note `HANDOFF.md` has carried since the
  sample-data round and the reason this file exists.

  ## What it checks

  Only the frame, and only for screens that declare one. A screen renders a
  `:scroll` somewhere under its root, and the node under that scroll carries
  the boards' own margins: **21pt sides, 64 above**. Those are not this
  file's numbers — every board in `test/design/screens` sets
  `padding:64px 21px 40px` on its frame, and `Kati.Screens.Pushed` already
  uses them.

  A screen that legitimately fills its frame edge to edge says so by joining
  `@full_bleed` with a reason, rather than by this test having no opinion.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  # Screens under `pushed_frame/2` that are not pages. Each is a decision, and
  # the difference between a decision and an omission is that somebody wrote
  # the reason down.
  @not_a_page [
    # A sheet, not a page: a scrim over the screen behind it and a rounded
    # panel on the bottom edge. It is sized by its content and closes rather
    # than scrolls — 34pt below and 18 above the panel's own top, not the
    # frame's 64.
    Kati.Screens.LogProgressFa,
    # A hero, not a page: the artwork meets the status bar, so a 64pt inset
    # would put a band of paper above a picture that is meant to bleed. Its
    # content column below the artwork carries the 21pt sides like everything
    # else.
    Kati.Screens.SeriesFa
  ]

  @sides 21
  @top 64

  test "every Persian pushed screen pads itself the way its board does" do
    wrong =
      # In ENGLISH, which is the whole discriminator. `Kati.Shell` reads the
      # direction from `Kati.Locale`, so under `:fa` every screen in the app
      # renders `rtl` and this would be checking all 165 of them against a
      # frame most of them do not use. The Persian mirrors hard-code `rtl`
      # whatever the setting says — that is `Kati.Screens.Fa`'s first
      # paragraph — so in `:en` an RTL root IS a Persian mirror.
      ScreenSweep.with_locale(:en, fn ->
        for module <- ScreenSweep.screens(),
            module not in @not_a_page,
            persian_pushed?(module),
            {:ok, _socket, tree} <- [ScreenSweep.render(module)],
            reason = frame_fault(tree),
            do: "  #{inspect(module)} — #{reason}"
      end)

    assert wrong == [], """
    these Persian screens hand their content straight to the root Box, so it
    starts at the pixel: the top of the page sits under the status bar and the
    first line runs off the leading edge. Nothing else in the suite has an
    opinion about a layout — this was found by opening the app.

    `Kati.Screens.Fa.page/1` is the frame, and it is the boards' own numbers.

    #{Enum.join(wrong, "\n")}
    """
  end

  test "the check can fail, which is the only thing that makes it worth having" do
    # A frame checker that cannot find a missing frame is the shape of test
    # this codebase has been bitten by — see `HANDOFF.md` on the duplicate-id
    # check that was vacuous for the life of the project. So: a tree with no
    # scroll in it must be reported.
    bare = %{type: :box, props: %{layout_direction: "rtl"}, children: []}

    assert frame_fault(bare) != nil
  end

  # A pushed Persian screen renders `Kati.Screens.Fa.pushed_frame/2`: a root
  # box that declares `rtl` and carries no dock. The dock is what separates a
  # root from a pushed screen, and `Kati.Screens.Fa.frame/3` always draws one.
  defp persian_pushed?(module) do
    case ScreenSweep.render(module) do
      {:ok, _socket, %{type: :box, props: %{layout_direction: "rtl"}} = tree} ->
        not Enum.any?(Mob.ScreenCase.flatten(tree), &dock_tab?/1)

      _other ->
        false
    end
  end

  defp dock_tab?(node) do
    case Map.get(node, :props) || %{} do
      %{on_tap: {_pid, tag}} -> String.starts_with?(Atom.to_string(tag), "root_")
      _no_tap -> false
    end
  end

  defp frame_fault(tree) do
    nodes = Mob.ScreenCase.flatten(tree)

    case Enum.find(nodes, &(&1.type == :scroll)) do
      nil ->
        "draws no Scroll at all, so a page taller than the frame cannot be read"

      scroll ->
        padded_fault(Map.get(scroll, :children) || [])
    end
  end

  defp padded_fault([%{props: props} | _rest]) do
    cond do
      props[:padding_top] != @top -> "padding_top #{inspect(props[:padding_top])}, board says #{@top}"
      props[:padding_left] != @sides -> "padding_left #{inspect(props[:padding_left])}, board says #{@sides}"
      props[:padding_right] != @sides -> "padding_right #{inspect(props[:padding_right])}, board says #{@sides}"
      true -> nil
    end
  end

  defp padded_fault(_empty), do: "its Scroll has no content"
end
