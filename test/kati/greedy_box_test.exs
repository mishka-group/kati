Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.GreedyBoxTest do
  @moduledoc """
  A `Box` with no size of its own fills the space beside it, and that is how a
  whole card goes blank.

  ## The defect this was written for

  Screen 05's watcher card is a `Row` of three things: a sparkle, a weighted
  `Column` holding two lines, and a cog. The cog was
  `<Box on_tap={@tap}>{symbol}</Box>` — **no width, no height** — so it took
  every point the `Column` should have had. On a device the card was two icons
  in an empty cream bar; the `Column` was left about 20pt wide and
  `max_lines={1}` clipped both lines away to nothing.

  Nothing in this suite could see it. `render/1` answers a TREE, the tree was
  correct, `Kati.ScreenInboxTest` read both strings straight out of it, and
  3,680 tests passed while the card was blank on a phone. It took a device and
  a deliberately unwrapped `Text` — the headline coming out one letter per row
  — to prove where the width had gone.

  ## What this asserts

  The shape, not the pixels: **a Box with no size may not sit beside a sibling
  that has `weight`.** One of the two is going to lose, and it will be the
  weighted one, silently, in a way that only a screenshot shows.

  It is deliberately narrow. It does not claim every unsized Box is wrong —
  one alone in a Column is ordinary, and a Box that fills on purpose says so
  with `fill_width`. It claims only that the pair cannot both be right in one
  Row, which is a thing a rendering suite cannot check and a tree can.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  @locales [:en, :fa]

  # `Kati.UI.Segmented`'s inactive segment, and the one entry here.
  #
  # `segment/4` centres its label between two `Spacer weight={1.0}`s and wraps
  # the label in a bare `<Box>` so a strike-through line can be laid over it.
  # That Box has no width it could be given: it has to hug a label whose width
  # is the label's. So the pair this test forbids is genuinely what the control
  # needs, and the consequence — if the Box does fill — is a label pushed off
  # centre rather than a card gone blank.
  #
  # It is on the list rather than fixed because the fix is a change to a shared
  # component that four screens draw, and it wants a device to be judged on.
  # The two screens named are the two that draw an inactive segment at rest.
  @content_hugging [Kati.Screens.LogProgressFa, Kati.Screens.LogProgressStates]

  # Anything that gives a node a width of its own. `weight` counts: a Box that
  # names a share is asking for a share rather than for everything.
  @sized ~w(width height min_width min_height max_width max_height
            fill_width fill_height aspect_ratio weight size)a

  test "no unsized Box sits beside a weighted sibling" do
    greedy =
      @locales
      |> ScreenSweep.per_locale(fn _locale ->
        for module <- ScreenSweep.screens(),
            module not in @content_hugging,
            {:ok, _socket, tree} <- [ScreenSweep.render(module)],
            {parent, box} <- greedy_boxes(tree),
            do:
              "  #{inspect(module)} — a #{parent} holds an unsized Box beside a weighted " <>
                "sibling. The Box: #{inspect(Map.keys(Map.get(box, :props, %{})))}"
      end)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    assert greedy == [],
           "an unsized `Box` fills its parent, so it takes the space its weighted sibling " <>
             "asked for — and the loser goes blank rather than erroring. Give the Box a " <>
             "`width`/`height` the way `Kati.UI.SettingsList.icon_tile/1` and " <>
             "`Kati.Screens.Inbox.watcher_idle/0` do:\n" <> Enum.join(greedy, "\n")
  end

  defp greedy_boxes(node) when is_map(node) do
    children = Map.get(node, :children, []) |> List.wrap() |> Enum.filter(&is_map/1)

    here =
      if Enum.any?(children, &weighted?/1) do
        for child <- children, unsized_box?(child), do: {Map.get(node, :type), child}
      else
        []
      end

    here ++ Enum.flat_map(children, &greedy_boxes/1)
  end

  defp greedy_boxes(_other), do: []

  defp weighted?(node), do: is_number(Map.get(props(node), :weight))

  defp unsized_box?(node) do
    Map.get(node, :type) == :box and
      not Enum.any?(@sized, &Map.has_key?(props(node), &1))
  end

  defp props(node), do: Map.get(node, :props, %{})
end
