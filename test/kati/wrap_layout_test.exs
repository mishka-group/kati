defmodule Kati.WrapLayoutTest do
  @moduledoc """
  Chips that break where they stop fitting, and not where a number said.

  ## What this file is for

  mishka-group/kati#98: *"The scope chips on screen 19 wrap by **count**, not by
  measurement, because nothing on this bridge can measure them."* The ticket
  names two ways out and picks one — *"A `FlowRow` node on the bridge… removes
  the count rule entirely"* — and that node arrived in mob 0.8.0 (MOB-175) as
  `<Wrap>`, with its Android renderer in the mob_new 0.4.33 generated template.
  Merging the vendored shell forward from 0.4.20 to 0.4.33 is what made the
  node reachable at all, so these tests guard both halves: the Elixir side that
  now asks for a measured wrap, and the Kotlin arm that performs it.

  ## Why the Kotlin assertion is here rather than left to the device

  `MobBridge.kt` is generated once and never updated by any Mob tooling (see
  `native/README.md`), so the `"wrap"` arm is a file in this repo that a future
  merge can drop the way `K-01 torch-method` and `K-08 text-max-lines` were
  dropped INTO it. If it goes, `<Wrap>` renders as nothing at all — the `when`
  in `RenderNodeInner` has no else arm, which is the failure `K-18
  anchored-node` was written for and is silent by construction: no log, no
  crash, a blank where the tags were. A screenshot would catch it; nothing else
  would.

  ## Why screen 62's tags and not screen 19's chips

  Screen 19 stopped wrapping. Board 313 replaced its two rows with one
  scrolling row and a chevron — *"A drawing that wraps needs [FlowRow]; a
  drawing that scrolls does not"* — and rejected the wrap on its own merits
  as well: *"three lines tall — on a 235% page where the field alone is 62pt,
  that is the results pushed off-screen."*

  Board 62's tag row is the case that stayed. `test/design/screens/62.html`
  draws it `display:flex;flex-wrap:wrap;gap:7px`, and the module drew it
  `Enum.chunk_every(3)` under a comment naming the browser width it was
  measured at. That is #98's defect in its plainest form: a layout decision
  taken at author time, from one width and one text size, for a row whose
  labels are user data.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.SeriesMeta

  @bridge Path.expand("../../android/app/src/main/java/com/example/kati/MobBridge.kt", __DIR__)

  # Board 62's own gap, in both axes: `gap:7px` is shorthand for row and column
  # alike, and the two helpers this replaced drew 7 along a run and 7 between
  # runs.
  @gap 7

  defp subject(tags) do
    %{tags: tags, add_tag: "+ tag"}
  end

  describe "the tag row asks for a measured wrap" do
    test "one wrap node holds every tag, with no row grouping above them" do
      node = SeriesMeta.tags(subject(~w(dentist noir slow rewatch 2026)))

      assert node.type == :wrap,
             "the tags are drawn in a #{inspect(node.type)}; #98 is closed by a node that " <>
               "measures, and only `wrap` does"

      # Six children: five tags and the add-tag slot. If a count rule came back
      # this would be two or three children, each a row.
      assert length(node.children) == 6,
             "the wrap holds #{length(node.children)} children — a grouping layer is back, and " <>
               "with it the author-time decision #98 exists to remove"

      refute Enum.any?(node.children, &(&1.type == :row)),
             "a row survived between the wrap and its chips, so the wrap is packing rows and " <>
               "each row still decides its own break"
    end

    test "the gap is board 62's, along a run and between runs" do
      node = SeriesMeta.tags(subject(~w(a b c)))

      assert node.props[:spacing] == @gap
      assert node.props[:run_spacing] == @gap

      artboard = File.read!(Path.expand("../design/screens/62.html", __DIR__))

      assert artboard =~ "flex-wrap:wrap;gap:#{@gap}px",
             "62.html no longer draws this row as a #{@gap}px wrapping flex, so the two props " <>
               "above are being checked against nothing"
    end

    test "the add-tag slot is last and is the only outlined one" do
      node = SeriesMeta.tags(subject(~w(one two)))

      # `tag/2`'s add shape is the 1.5pt outline over `:transparent`; the user
      # tags are card fill. Asserted through the drawn tree rather than through
      # the flag, because the flag is what the old chunked version carried and
      # the point is that the order survived losing the rows.
      texts = node |> find_all(:text) |> Enum.map(& &1.props[:text])

      assert List.last(texts) == "+ tag",
             "the add-tag is no longer last: #{inspect(texts)}"
    end

    test "a subject with no tags still draws the add-tag and nothing else" do
      node = SeriesMeta.tags(subject([]))

      assert node.type == :wrap
      assert length(node.children) == 1
    end
  end

  describe "the bridge can perform it" do
    test "MobBridge renders a wrap node as a FlowRow" do
      bridge = File.read!(@bridge)

      assert bridge =~ "\"wrap\" -> FlowRow(",
             "the `wrap` arm is gone from RenderNodeInner. `when` there has no else arm, so " <>
               "every <Wrap> in the app now draws NOTHING — silently. See #98 and K-18."

      assert bridge =~ "import androidx.compose.foundation.layout.FlowRow",
             "FlowRow is used and not imported, which is a compile error rather than a silent " <>
               "one — but it is the same merge slip and cheaper to catch here"
    end

    test "the arm reads both spacing props, so the drawing's gaps reach Compose" do
      arm =
        @bridge
        |> File.read!()
        |> String.split("\"wrap\" -> FlowRow(")
        |> Enum.at(1)
        |> String.slice(0, 600)

      assert arm =~ "floatProp(node.props, \"spacing\")",
             "the wrap arm ignores `spacing`, so a gap set in Elixir is dropped between chips"

      assert arm =~ "floatProp(node.props, \"run_spacing\")",
             "the wrap arm ignores `run_spacing`, so the gap between wrapped lines is dropped"
    end
  end
end
