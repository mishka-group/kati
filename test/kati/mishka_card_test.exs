defmodule Kati.MishkaCardTest do
  @moduledoc """
  Guards the headless web Card parts ported into `MishkaCard` — figure order,
  the implicit body that puts the title first and the actions last, and the
  slot tags that stand in for the Phoenix slots.

  The plain-children case is asserted first: Film and the knock-on screen build
  cards without any of the new props, and their tree must stay exactly what it
  was before the parts existed.
  """

  use ExUnit.Case, async: true

  alias Kati.Components.MishkaCard

  defp expand(props, children) do
    MishkaCard.expand(props, children, %{screen: self()})
  end

  defp text(text), do: %{type: :text, props: %{text: text}, children: []}

  test "plain children stay flat in the root, with no body wrapper" do
    child = %{type: :text, props: %{text: "body"}, children: []}

    node = expand(%{corner_radius: 22, padding: 17}, [child])

    assert node.type == :column
    assert node.children == [child]
    assert node.props.corner_radius == 22
    assert node.props.padding == 17

    # Props the caller did not name must not reach the node as `nil`.
    refute Map.has_key?(node.props, :background)
    refute Map.has_key?(node.props, :border_width)
  end

  test "direction row is a Row and carries align; a column drops align" do
    row = expand(%{direction: "row", align: "center"}, [])
    column = expand(%{direction: :column, align: "center"}, [])

    assert row.type == :row
    assert row.props.align == "center"

    assert column.type == :column
    refute Map.has_key?(column.props, :align)
  end

  test "a title prop opens a body and puts the title first" do
    content = text("content")
    node = expand(%{title: "Your rating"}, [content])

    assert [body] = node.children
    assert body.type == :column
    assert body.props.fill_width == true
    assert [title, ^content] = body.children
    assert title == text("Your rating")
  end

  test "a title node keeps its own styling" do
    title = %{type: :text, props: %{text: "Styled", text_size: 18}, children: []}

    assert [body] = expand(%{title: title}, []).children
    assert body.children == [title]
  end

  test "actions open a body and land after the content" do
    content = text("content")
    action = %{type: :text, props: %{text: "Edit"}, children: []}

    assert [body] = expand(%{actions: [action]}, [content]).children
    assert body.children == [content, action]
  end

  test "a row card gives its body the space beside the figure" do
    figure = %{type: :box, props: %{width: 100, height: 150}, children: []}
    content = text("content")

    node = expand(%{direction: :row, figure: figure, title: "Title"}, [content])

    assert [^figure, body] = node.children
    assert body.type == :column
    assert body.props.weight == 1.0
  end

  test "figure_position decides whether the figure is before or after the body" do
    figure = %{type: :box, props: %{width: 100}, children: []}
    content = text("content")

    start = expand(%{figure: figure}, [content])
    finish = expand(%{figure: figure, figure_position: "end"}, [content])

    assert [^figure, ^content] = start.children
    assert [^content, ^figure] = finish.children
  end

  test "slot tags are consumed and win over their props" do
    figure_slot = %{type: :mishka_card_figure, props: %{}, children: [text("figure")]}
    title_slot = %{type: :mishka_card_title, props: %{}, children: [text("title")]}
    actions_slot = %{type: :mishka_card_actions, props: %{}, children: [text("action")]}
    content = text("content")

    node =
      expand(
        %{title: "prop title", figure: text("prop figure"), actions: [text("prop action")]},
        [title_slot, content, actions_slot, figure_slot]
      )

    assert [figure, body] = node.children
    assert figure == text("figure")

    refute Enum.any?(body.children, &match?(%{type: type} when type in [:mishka_card_title], &1))
    assert [title, ^content, action] = body.children
    assert title == text("title")
    assert action == text("action")
  end

  test "the title slot alone also opens a body" do
    title_slot = %{type: :mishka_card_title, props: %{}, children: [text("title")]}
    content = text("content")

    assert [body] = expand(%{}, [title_slot, content]).children
    assert body.children == [text("title"), content]
  end
end
