defmodule Kati.ReviewFieldWrapsTest do
  @moduledoc """
  Screen 33's review wraps into a paragraph.

  `MobTextField` was `singleLine = true` and read no prop that could change it,
  so a long review scrolled sideways on one line. The bridge's
  `K-50 text-field-multiline` fence reads `multiline`; these pin both halves.
  """

  use ExUnit.Case, async: true

  @bridge "android/app/src/main/java/com/example/kati/MobBridge.kt"

  test "the review field asks for multiline" do
    %{props: props} = Kati.Screens.Rating.review_field("A long review")

    assert props[:multiline] == true
  end

  test "and sets no return key, since Return types a newline there" do
    %{props: props} = Kati.Screens.Rating.review_field("")

    refute Map.has_key?(props, :return_key)
  end

  test "and the bridge reads the prop it sends" do
    bridge = File.read!(@bridge)

    assert bridge =~ ~s|boolProp(node.props, "multiline")|
    assert bridge =~ "singleLine      = !multiline"
  end
end
