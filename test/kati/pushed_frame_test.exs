Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.PushedFrameTest do
  @moduledoc """
  A pushed screen puts its content inside a scroll with the board's margins.

  ## What went wrong, twice over, and what did not notice

  **Neither frame is built for you.** `Kati.Screens.Fa.pushed_frame/2` is the
  root `Box` — it declares `rtl` and paints the background — and
  `Kati.Screens.Pushed.chrome/3` is the root `Box` plus a back pill that
  *floats over* the content in its own padded row. In both, `{@content}` is
  dropped in unpadded and unscrolled, and every screen inside has been writing
  the same `Scroll` and padded `Column` by hand.

  Six written in one round did not. On a device that is a page whose first line
  is hard against the edge and whose top sits under the status bar — and on the
  three pushed English ones, a heading underneath the floating pill.

  The first version of this file caught the Persian three and passed the
  English three, because it identified a pushed screen by its root declaring
  `rtl`. That is a fact about the Persian mirrors, not about pushed screens, so
  it checked half the population and reported the half green. **The owner found
  the other half by looking at the app** — the second time in one round, and
  the reason the discriminator below reads the source for `use
  Kati.Screens.Pushed` rather than guessing from a rendered tree.

  Every other host test passed on all six. The tree is one root node, every
  literal the drawing contains is in it, every control is tappable, the taps go
  where they should. A layout has no assertion in any of them.

  ## What it checks

  Only the frame, and only for screens that declare one. A screen renders a
  `:scroll` somewhere under its root, and the node under that scroll carries
  the boards' own side margins — **21pt** — and starts far enough down to be
  read. Those are not this file's numbers: every board in
  `test/design/screens` sets `padding:64px 21px 40px` on its frame.

  The top is the one measurement with two right answers, and the boards say
  which. A board that draws a back pill gets `Kati.Screens.Pushed.content_top/0`
  — 110, which is the floating pill's 54 plus its 42 plus breathing room. A
  board that puts its back control in the flow gets 64. So the check is that
  the top is **one of those two**, rather than a single number that would call
  half the app wrong.

  A screen that legitimately fills its frame edge to edge says so by joining
  `@not_a_page` with a reason, rather than by this test having no opinion.
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
    Kati.Screens.SeriesFa,
    # Screen 09's timeline bleeds to both edges on purpose, so the side padding
    # is on an inner column and the rule the sides run through — the hour rail
    # — is not inset with the text. The outer column still carries 64 above and
    # 40 below; it is the sides that are deliberately not there.
    Kati.Screens.Day,
    # 63, 64 and 65 are drawings of Kati seen from OUTSIDE the app: a phone's
    # home screen with the icon on it, and the splash. A margin would be a
    # margin around a picture of a phone.
    Kati.Screens.MarkAndroid,
    Kati.Screens.MarkIos,
    Kati.Screens.LaunchScreen,
    # The developer index. Not a page of the app — `Kati.AppReachabilityTest`
    # calls it scaffold and #94 is the ticket to delete it.
    Kati.Screens.Gallery
  ]

  @sides 21
  @tops [64, 110]
  @screens_dir Path.expand("../../lib/kati/screens", __DIR__)

  test "every pushed screen pads itself the way its board does" do
    wrong =
      ScreenSweep.with_locale(:en, fn ->
        for module <- pushed(),
            module not in @not_a_page,
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

  test "it is looking at a real population, not an empty one" do
    # The failure this file has already had once: a discriminator that matched
    # the wrong thing checked six screens and reported the other twenty green.
    # A floor turns "found nothing to check" into a failure.
    assert length(pushed()) > 20,
           "only #{length(pushed())} pushed screens were found; the discriminator has " <>
             "stopped matching and this file is passing over the app"
  end

  test "the check can fail, which is the only thing that makes it worth having" do
    # A frame checker that cannot find a missing frame is the shape of test
    # this codebase has been bitten by — see `HANDOFF.md` on the duplicate-id
    # check that was vacuous for the life of the project. So: a tree with no
    # scroll in it must be reported.
    bare = %{type: :box, props: %{layout_direction: "rtl"}, children: []}

    assert frame_fault(bare) != nil
  end

  # Read off the SOURCE, and that is the correction this file needed.
  #
  # The first version asked the rendered tree — a root `Box` declaring `rtl`
  # with no dock — which describes the Persian mirrors and not pushed screens,
  # so it checked six of them and passed the twenty-odd English ones straight
  # through. What actually makes a screen pushed is the macro it is built on,
  # and that is a fact about the file rather than about a render.
  #
  # `use Kati.Screens.Pushed` covers the Latin half; `Kati.Screens.Fa` mirrors
  # hand-roll `use Mob.Screen` and call `Fa.pushed_frame/2` in `render/1`, so
  # the second pattern catches those. A screen that does neither is a root or a
  # sheet and is not this file's business.
  defp pushed do
    for path <- Path.wildcard(Path.join(@screens_dir, "*.ex")),
        source = File.read!(path),
        source =~ "use Kati.Screens.Pushed" or source =~ "Fa.pushed_frame(",
        module = Module.concat(Kati.Screens, Macro.camelize(Path.basename(path, ".ex"))),
        ScreenSweep.screen?(module),
        do: module
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
      props[:padding_top] not in @tops ->
        "padding_top #{inspect(props[:padding_top])}, board says 64 (back control in the " <>
          "flow) or 110 (a floating pill to clear)"

      props[:padding_left] != @sides ->
        "padding_left #{inspect(props[:padding_left])}, board says #{@sides}"

      props[:padding_right] != @sides ->
        "padding_right #{inspect(props[:padding_right])}, board says #{@sides}"

      true ->
        nil
    end
  end

  defp padded_fault(_empty), do: "its Scroll has no content"
end
