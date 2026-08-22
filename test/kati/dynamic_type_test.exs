defmodule Kati.DynamicTypeTest do
  @moduledoc """
  #79 — what may carry a fixed size when the text scales.

  The rule, decided here rather than per-screen because 62 screens repeat it:

    * A fixed `width`/`height` states a **shape**. A 44x44 box with
      `corner_radius={22}` is a circle; growing it makes it an oval, so it stays
      fixed however large the text gets. Same for a poster, a 3x36 rule, a 7x7
      dot, a colour swatch.

    * `min_width`/`min_height` state a **measurement of text** — a number that
      came from "how wide is this label". Those must be a floor, not a cap: the
      drawing's size at 100%, free to grow after that.

  Told apart by asking what the number describes, not by what it contains: both
  kinds hold a `<Text>`, because an icon glyph is a text node too.
  """
  use ExUnit.Case, async: true

  @bridge "android/app/src/main/java/com/example/kati/MobBridge.kt"

  # Every container whose number was measured from a label. Each one truncated
  # its text at 235% before K-28; `{file, line, label}` so a failure names the
  # thing that broke rather than a count.
  @text_measured [
    {"lib/kati/screens/calendar.ex", "the schedule's time gutter"},
    {"lib/kati/screens/day.ex", "the day view's time gutters"},
    {"lib/kati/ui.ex", "timeline_row's time column"}
  ]

  describe "the min-size primitive" do
    test "the bridge still reads min_width and min_height" do
      # An unknown prop is DROPPED, in silence. `nodeModifier` reads the props
      # it knows and ignores the rest, so a `min_width` the bridge had stopped
      # reading would leave every gutter with no floor at all, log nothing, and
      # fail nothing — the exact shape of bug that put "0…" on screen in the
      # first place. This assertion is the only thing between K-28 and that.
      src = File.read!(@bridge)

      assert src =~ ~s|floatProp(props, "min_width")|,
             "K-28 is gone from #{@bridge}: min_width is now a silently ignored prop"

      assert src =~ ~s|floatProp(props, "min_height")|,
             "K-28 is gone from #{@bridge}: min_height is now a silently ignored prop"
    end
  end

  describe "display titles stop growing before they break" do
    test "the bridge still reads max_font_scale" do
      # Same silent-drop hazard as min_width: a prop the bridge ignores is not
      # an error, it just does nothing, and the title goes back to three lines.
      src = File.read!(@bridge)

      assert src =~ ~s|floatProp(node.props, "max_font_scale")|,
             "K-29 is gone from #{@bridge}: max_font_scale is a silently ignored prop"
    end

    test "every 28sp display title carries a cap" do
      # 28 is the display size. Uncapped, it is 66sp at 235% and "Schedule"
      # wants ~290dp of the 272 its column has — one word over three lines.
      offenders =
        "lib/kati/**/*.ex"
        |> Path.wildcard()
        |> Enum.reject(&String.contains?(&1, "/components/"))
        |> Enum.flat_map(fn file ->
          file
          |> File.read!()
          |> String.split("\n")
          |> Enum.chunk_every(2, 1, :discard)
          |> Enum.with_index(1)
          |> Enum.filter(fn {[line, next], _} ->
            String.match?(line, ~r/^\s*text_size=\{28\}\s*$/) and
              not String.contains?(next, "max_font_scale")
          end)
          |> Enum.map(fn {_, i} -> "#{file}:#{i}" end)
        end)

      assert offenders == [],
             "display titles with no max_font_scale — they wrap mid-word at 235%:\n  " <>
               Enum.join(offenders, "\n  ")
    end
  end

  describe "text measurements are floors, not caps" do
    for {file, what} <- @text_measured do
      test "#{what} grows with the text (#{file})" do
        src = File.read!(unquote(file))

        refute src =~ ~r/<Column width=\{44\}/,
               "#{unquote(what)}: `width={44}` caps the column at 44dp, so \"08:00\" " <>
                 "renders as \"0…\" once the system font scale passes ~1.6. Use min_width."

        assert src =~ ~r/min_width=\{\d/,
               "#{unquote(what)}: expected a min_width floor and found none"
      end
    end
  end
end
