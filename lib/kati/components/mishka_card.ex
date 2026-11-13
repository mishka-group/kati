defmodule Kati.Components.MishkaCard do
  @moduledoc """
  A headless card surface: fill, corners, shadow, padding and an optional tap —
  with the parts Chelekom's headless web Card declares: a figure, a title, the
  content, and a row of actions.

  Chelekom's Mob set has no generic Card. `MishkaPreviewCard` is a trigger plus
  a floating detail card, not a static surface, and `MishkaEmptyState` fixes its
  own layout. This module is the small missing piece: it draws the container
  and leaves the content to the caller.

  ## Direction

  `direction: :row` keeps the children on one line — the Film rating card is a
  row of two columns plus a chevron. The default is `:column`.

  The component is deliberately a plain `Row`/`Column` node rather than a Box:
  a card that stacks its children is what `Column` already means, and a card
  whose children sit side by side is what `Row` already means. Wrapping either
  in a Box would add a node with no visual or semantic job, and the first
  alignment bug would be in the wrapper.

  ## Ported from the headless web Card

  The web component's anatomy is a root holding an optional `figure` and a
  `body`, where the body holds `title`, `content` and `actions`. The two parts
  that carry layout are ported, because Mob can express them:

  * `figure` + `figure_position` — the figure is a sibling of the body, drawn
    before it (`:start`, the web default) or after it (`:end`). Hand-reordering
    the slots at every call site is what the prop exists to prevent.
  * `title` and `actions` — when either is present the rest of the children
    become a body, so the title reads first and the actions last. With neither,
    the children sit directly in the root exactly as before.

  The body is a plain `Column`: Mob has no `<figure>`, `<div>` or `<h3>` node,
  so there is no wrapper to draw for `figure`, no `title_level`, and no
  `aria-labelledby`. `id` stays a native testTag rather than an ARIA anchor.

  Not ported, because the platform has no equivalent:

  * `title_level` — Mob text nodes carry no heading role.
  * `href` / `navigate` / `patch` — `on_tap` is the native click target.
  * `class` and the `*_class` hooks — Mob styles through the props below.

  ## Slots

  All three of the web component's slots are ported as tags, so markup reads
  the way the Phoenix component does:

      <MishkaCard corner_radius={22} background={Palette.card()}>
        <MishkaCardFigure>
          <Image src={poster} width={120} height={180} />
        </MishkaCardFigure>
        <MishkaCardTitle>Your rating</MishkaCardTitle>
        <MishkaRating value={4.5} />
        <MishkaCardActions>
          <MishkaPill label="Edit" on_tap={:edit} />
        </MishkaCardActions>
      </MishkaCard>

  | Slot | Falls back to |
  |------|---------------|
  | `<MishkaCardFigure>` | the `figure` prop (node or list) |
  | `<MishkaCardTitle>` | the `title` prop (string, node or list) |
  | `<MishkaCardActions>` | the `actions` prop (node or list) |
  | bare children | the content, rendered between title and actions |

  A slot wins when both it and its prop are given. Slot tags contribute their
  own children; they draw nothing themselves, so no marker node ever reaches
  the renderer.

  ## Props

  | Prop | Values | Default | Meaning |
  |------|--------|---------|---------|
  | `direction` | `:column` `:row` | `:column` | How the root lays out. |
  | `title` | string, node, or list of nodes | unset | Drawn first in the body. A string becomes a bare `Text` with no styling. |
  | `figure` | node or list of nodes | unset | Drawn inside the root, before or after the body. |
  | `figure_position` | `:start` `:end` | `:start` | Whether the figure comes before or after the body. |
  | `actions` | node or list of nodes | unset | Drawn last in the body. |
  | `fill_width` | boolean | `true` | Span the parent. |
  | `height` | number | unset | Fixed height, as on any Mob node. |
  | `fill_height` | boolean | `false` | Span the parent's height — a sheet's surface that runs from its scrim to the screen's bottom. Left off the node unless `true`. |
  | `min_height` | number | unset | A floor under the height: the card grows past it with its content. Passed to the root as `min_height`, which needs a renderer that reads it (`heightIn(min=)` in the Android bridge); stock Mob's bridge does not yet, so there it is ignored. |
  | `weight` | number | unset | Share of a parent `Row`/`Column`, as on any Mob node. |
  | `background` | color token / ARGB int | unset | Surface fill. |
  | `corner_radius` | radius token / number | unset | Corner rounding. |
  | `shadow` | shadow spec string | unset | Drop shadow on the surface. |
  | `padding` | spacing token / number | unset | All four sides. |
  | `padding_top` / `padding_right` / `padding_bottom` / `padding_left` | spacing token / number | unset | One edge, overriding `padding`. |
  | `border_color` / `border_width` | color / number | unset | Outline. |
  | `align` | `:center`, `:leading`, … | unset | Cross-axis alignment, in either direction: a row's vertical, a column's horizontal. |
  | `on_tap` | event tag | unset | Makes the surface tappable. |
  | `id` | string | unset | Native testTag on the surface. |

  Every unset prop is left off the node entirely, not written as `nil`.

  The body adds no gap of its own, because the web component ships no spacing
  either. Callers space title, content and actions with `Spacer`s or by giving
  the nodes their own margins. Padding sits on the root, so a figure is inset
  by it like any other child; pad the content instead when the image should
  run to the card's edge.
  """

  @figure_type :mishka_card_figure
  @title_type :mishka_card_title
  @actions_type :mishka_card_actions

  @slot_types [@figure_type, @title_type, @actions_type]

  @doc """
  Composite expander (`<MishkaCard />`).

  Slot tags are partitioned out before the card is built. They are matched on
  `:type`, the same shape `MishkaEmptyState` and `MishkaAccordion` use for
  their slots, and the bare children are the card content.
  """
  @spec expand(map(), [map()], map()) :: map()
  def expand(props, children, _ctx) do
    props =
      props
      |> Map.new()
      |> slot_over_prop(:figure, slot(children, @figure_type))
      |> slot_over_prop(:title, slot(children, @title_type))
      |> slot_over_prop(:actions, slot(children, @actions_type))

    card(props, inner_block(children))
  end

  defp slot_over_prop(props, _key, []), do: props
  defp slot_over_prop(props, key, nodes), do: Map.put(props, key, nodes)

  defp slot(children, type) do
    children
    |> Enum.filter(&match?(%{type: ^type}, &1))
    |> Enum.flat_map(&Map.get(&1, :children, []))
  end

  defp inner_block(children) do
    Enum.reject(children, &match?(%{type: type} when type in @slot_types, &1))
  end

  @doc """
  The card node.

      card(direction: :row, background: 0xFFFBFAF8, corner_radius: 22, padding: 17)
  """
  @spec card(map() | keyword(), [map()]) :: map()
  def card(props \\ %{}, children \\ []) do
    props = Map.new(props)
    direction = direction(Map.get(props, :direction))
    figure = List.wrap(Map.get(props, :figure))
    title = title_nodes(Map.get(props, :title))
    actions = List.wrap(Map.get(props, :actions))
    structured? = title != [] or actions != []

    {before, after_figure} =
      case figure_position(Map.get(props, :figure_position)) do
        :end -> {[], figure}
        :start -> {figure, []}
      end

    content =
      if structured?,
        do: [body(direction, title, children, actions)],
        else: children

    base =
      %{}
      |> put_some(:fill_width, Map.get(props, :fill_width, true))
      |> put_some(:height, Map.get(props, :height))
      |> put_some(:fill_height, if(Map.get(props, :fill_height) in [true, "true"], do: true))
      |> put_some(:min_height, Map.get(props, :min_height))
      |> put_some(:weight, Map.get(props, :weight))
      |> put_some(:background, Map.get(props, :background))
      |> put_some(:corner_radius, Map.get(props, :corner_radius))
      |> put_some(:shadow, Map.get(props, :shadow))
      |> put_some(:padding, Map.get(props, :padding))
      |> put_some(:padding_top, Map.get(props, :padding_top))
      |> put_some(:padding_right, Map.get(props, :padding_right))
      |> put_some(:padding_bottom, Map.get(props, :padding_bottom))
      |> put_some(:padding_left, Map.get(props, :padding_left))
      |> put_some(:border_color, Map.get(props, :border_color))
      |> put_some(:border_width, Map.get(props, :border_width))
      |> put_some(:on_tap, Map.get(props, :on_tap))
      |> put_some(:id, Map.get(props, :id))

    base = put_some(base, :align, Map.get(props, :align))

    %{type: direction, props: base, children: before ++ content ++ after_figure}
  end

  # The body holds title, content and actions. A column card gives it the full
  # width; a row card gives it the remaining space beside the figure. The root
  # keeps its own padding.
  defp body(:row, title, content, actions) do
    %{type: :column, props: %{weight: 1.0}, children: title ++ content ++ actions}
  end

  defp body(:column, title, content, actions) do
    %{type: :column, props: %{fill_width: true}, children: title ++ content ++ actions}
  end

  # A string title is a bare `Text`; a node or a list is used as given, so a
  # screen that wants the design's type passes its own styled node.
  defp title_nodes(nil), do: []

  defp title_nodes(title) when is_binary(title) do
    [%{type: :text, props: %{text: title}, children: []}]
  end

  defp title_nodes(title) when is_map(title), do: [title]
  defp title_nodes(titles) when is_list(titles), do: titles

  defp figure_position(position) when position in [:end, "end"], do: :end
  defp figure_position(_position), do: :start

  defp direction(direction) when direction in [:row, "row"], do: :row
  defp direction(_direction), do: :column

  defp put_some(map, _key, nil), do: map
  defp put_some(map, key, value), do: Map.put(map, key, value)
end
