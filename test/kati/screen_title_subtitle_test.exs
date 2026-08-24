defmodule Kati.ScreenTitleSubtitleTest do
  @moduledoc """
  The line under a 28pt screen title is drawn in one of three shapes, and this
  is what says which.

  `Kati.UI.SettingsList.title/4` used to draw one — mono 11 over a 5pt gap —
  and 40 of the 52 boards whose screen calls it draw something else. Nothing
  caught that: `Kati.ScreenDesignLiteralTest` reads the words a screen draws,
  not the type scale it draws them at, so a subtitle two points out and in the
  wrong family passes every check in the suite and is visible to anyone who
  puts the render beside the drawing.

  So this reads the drawing. For every screen that draws a 28pt bold title with
  a line under it, the board's own `font-size`, family and `margin-top` are
  parsed out of the HTML and compared to what the screen rendered. There is no
  allow-list: a board and a screen that disagree is a failure, because the
  board is the specification and the screen is the claim.

  ## Why the gap is checked too

  The three shapes disagree about the space above the subtitle — 6pt for
  `:meta`, 5 for `:meta_tight` and `:name` — which is exactly the kind of
  detail a caller gets right on the size and wrong on the spacer. Checking one
  without the other would leave half the shape unpinned.

  ## What this does NOT cover, and why the count is asserted

  A screen is compared only when it renders a 28pt **bold** `Text` with a line
  under it — which is what `Kati.UI.SettingsList.title/4` and
  `Kati.Screens.MealPlan.title/2` build, and is the population those two
  helpers serve. 92 of the 152 drawings parse as having a 28px title over a
  line, so roughly a third of them head their screen some other way and are out
  of scope here rather than silently passing.

  That gap is why `enough pairs are actually compared` exists. A sweep whose
  parser stops matching, or whose helper stops emitting a recognisable title,
  would quietly compare nothing and report success; the floor turns that into a
  failure. Raise it when the number genuinely grows — never lower it to make a
  red build green.
  """

  use Mob.ScreenCase, async: false

  @registry Kati.Screens.Gallery.screens()

  @boards ".scratch/design/screens"

  describe "the line under a 28pt title" do
    test "is the size, family and gap its own board draws" do
      wrong =
        for {number, _label, module, _kind} <- @registry,
            board = board_subtitle(number),
            board != nil,
            drawn = drawn_subtitle(module),
            drawn != nil,
            drawn != board,
            do:
              "  #{number} #{inspect(module)}\n" <>
                "      board: #{describe(board)}\n" <>
                "      drawn: #{describe(drawn)}"

      assert wrong == [],
             "these screens draw the line under their title at a size, family or gap the " <>
               "drawing does not:\n" <> Enum.join(wrong, "\n")
    end

    test "enough pairs are actually compared" do
      # A parser that silently matches nothing turns this whole file into a test
      # that asserts `[] == []`. Both halves are counted, because either one
      # going quiet has the same effect: the drawings that parse, and the
      # screens that both parse AND render a title to compare it against.
      parsed =
        Enum.count(@registry, fn {number, _l, _m, _k} -> board_subtitle(number) != nil end)

      compared =
        Enum.count(@registry, fn {number, _l, module, _k} ->
          board_subtitle(number) != nil and drawn_subtitle(module) != nil
        end)

      assert parsed >= 85,
             "only #{parsed} drawings parsed as a 28pt title over a subtitle; the parser has " <>
               "stopped matching the markup Claude Design emits"

      assert compared >= 55,
             "only #{compared} screens were compared against their drawing. The sweep is " <>
               "reading fewer titles than it did; see the moduledoc on why this floor is here"
    end
  end

  # ── The drawing ─────────────────────────────────────────────────────────────

  # `{size, family, gap}` off the board, or `nil` when it has no 28px title with
  # a line under it. Sizes are floats because the drawings write `11.5px`.
  defp board_subtitle(number) do
    path = Path.join(@boards, "#{number}.html")

    with true <- File.exists?(path),
         html = File.read!(path),
         [_, style] <- Regex.run(~r/font-size:28px.*?<\/div>\s*<div style="([^"]*)"/s, html),
         [_, size] <- Regex.run(~r/font-size:([\d.]+)px/, style) do
      {parse_size(size), family(style), gap(style)}
    else
      _ -> nil
    end
  end

  defp family(style), do: if(style =~ "Mono", do: "mono", else: nil)

  defp gap(style) do
    case Regex.run(~r/margin-top:(\d+)px/, style) do
      [_, gap] -> String.to_integer(gap)
      _ -> nil
    end
  end

  defp parse_size(text) do
    {value, _rest} = Float.parse(text)
    value
  end

  # ── The screen ──────────────────────────────────────────────────────────────

  # The same triple, read off the rendered tree: the first 28pt bold `Text`, the
  # first `Spacer` after it, and the first `Text` after that.
  defp drawn_subtitle(module) do
    nodes = module |> mount_screen() |> flatten()

    with index when is_integer(index) <- Enum.find_index(nodes, &title?/1),
         rest = Enum.drop(nodes, index + 1),
         %{} = spacer <- Enum.find(rest, &(&1.type == :spacer)),
         %{} = text <- Enum.find(rest, &(&1.type == :text)) do
      {as_float(text.props[:text_size]), text.props[:font_family], spacer.props[:size]}
    else
      _ -> nil
    end
  rescue
    # A screen that cannot mount is `Kati.ScreenRenderSweepTest`'s failure to
    # report, not this one's — repeating it here would bury the findings.
    _error -> nil
  end

  defp title?(%{type: :text, props: props}),
    do: props[:text_size] == 28 and props[:font_weight] == "bold"

  defp title?(_node), do: false

  defp as_float(size) when is_integer(size), do: size * 1.0
  defp as_float(size), do: size

  defp describe({size, family, gap}),
    do: "#{size}pt #{family || "sans"}, #{gap}pt gap"
end
