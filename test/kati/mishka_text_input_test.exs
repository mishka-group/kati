defmodule Kati.MishkaTextInputTest do
  use ExUnit.Case, async: true

  alias Kati.Components.MishkaTextInput

  test "forwards the control's props and leaves unset ones off the node" do
    node =
      MishkaTextInput.text_input(
        value: "Dune",
        placeholder: "Title",
        multiline: true,
        text_size: 14,
        accessibility_id: "review"
      )

    assert node.type == :text_field
    assert node.props.value == "Dune"
    assert node.props.placeholder == "Title"
    assert node.props.multiline == true
    assert node.props.text_size == 14
    assert node.props.accessibility_id == "review"

    refute Map.has_key?(node.props, :background)
    refute Map.has_key?(node.props, :on_change)
  end

  test "widens every form event" do
    node =
      MishkaTextInput.text_input(
        on_change: :typed,
        on_submit: :sent,
        on_focus: :focused,
        on_blur: :blurred
      )

    assert node.props.on_change == {self(), :typed}
    assert node.props.on_submit == {self(), :sent}
    assert node.props.on_focus == {self(), :focused}
    assert node.props.on_blur == {self(), :blurred}
  end

  test "an already-wired handler is left alone" do
    assert MishkaTextInput.text_input(on_change: {self(), :typed}).props.on_change ==
             {self(), :typed}
  end

  test "expand/3 uses the tag's props and ignores children" do
    art = [%{type: :text, props: %{text: "x"}, children: []}]

    assert MishkaTextInput.expand(%{value: "v"}, art, %{screen: self()}) ==
             MishkaTextInput.text_input(value: "v")
  end

  test "an empty field renders" do
    node = MishkaTextInput.text_input()

    assert node.type == :text_field
    assert node.props == %{}
  end
end
