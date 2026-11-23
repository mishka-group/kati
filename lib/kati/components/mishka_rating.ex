defmodule Kati.Components.MishkaRating do
  @moduledoc """
  A headless five-star rating row, with halves.

  Chelekom's Mob set has no rating port. The star row is a repeated glyph, so
  the component is small: a `Row` of star cells joined by a declared gap, and
  the caller supplies the value, the size and the two inks.

  ## The half star is a clip, not a second glyph

  `star_half` is not in Kati's icon subset and a bridge `Text` ellipsises a
  glyph narrower than itself. A half star is therefore the outlined star with
  the filled one stacked over it and cut at 50% by `clip_width` — the same
  construction the Film page and the rating sheet already use. `clip_width`
  clips the draw and leaves measurement alone, so the pair occupies one star's
  line box and the row does not grow.

  Every cell hugs its glyph and centres it (`fill_width: false`, no width or
  height). `size` is a text size, not a cell width: Android draws it in sp,
  which grows with the system font scale, and a cell a fixed `size` wide would
  cut the outline at a large scale. The filled glyph sits in an overlay Box
  that hugs it and carries the clip, so `clip_width: 0.5` is half of the
  glyph's own advance at any scale. The half cell hugs the wider of the two and
  centres both; `★` and `☆` come from the same font, so the centred glyphs
  coincide and the cut lands on the star's centre. No height either: a cell
  keeps its glyph's line box, so the Row centres every star on the same line.

  ## Props

  | Prop | Values | Default | Meaning |
  |------|--------|---------|---------|
  | `value` | number | `0` | The rating, in stars — `3.5` is three and a half. |
  | `max` | integer | `5` | How many cells. |
  | `size` | number | `22` | One cell's edge, and the glyph size. |
  | `gap` | number | `2` | Space between cells. |
  | `color` | color token / ARGB int | `:primary` | Full and half fill. |
  | `empty_color` | color token / ARGB int | `color` | The outline under an empty or half cell. |
  | `half` | boolean | `true` | Draw the half step when the value has one. |
  | `tap_tags` | list of atoms | unset | One tag per half step, left then right — makes each cell report `{:tap, tag}`. |
  | `id` | string | unset | Native testTag on the row. |

  Children are ignored; the row is data.
  """

  import Mob.Sigil

  alias Kati.Components.Event

  @doc "Composite expander (`<MishkaRating />`). Delegates to `rating/1`."
  @spec expand(map(), [map()], map()) :: map()
  def expand(props, _children, _ctx), do: rating(props)

  @doc """
  The rating row.

      rating(value: 3.5, size: 22, gap: 2)
  """
  @spec rating(map() | keyword()) :: map()
  def rating(props \\ %{}) do
    props = Map.new(props)

    value = Map.get(props, :value) || 0
    max = Map.get(props, :max) || 5
    size = Map.get(props, :size) || 22
    gap = Map.get(props, :gap) || 2
    color = Map.get(props, :color) || :primary
    empty_color = Map.get(props, :empty_color) || color
    half? = Map.get(props, :half, true) != false

    full = trunc(value)
    half_star? = half? and value - full >= 0.5
    tags = Map.get(props, :tap_tags)

    cells =
      1..max
      |> Enum.map(fn i ->
        star(
          cond do
            i <= full -> :full
            i == full + 1 and half_star? -> :half
            true -> :empty
          end,
          size,
          color,
          empty_color
        )
        |> tappable(tags, i, size)
      end)
      |> Enum.intersperse(gap_node(gap))

    ~MOB"""
    <Row align="center">
      {cells}
    </Row>
    """
    |> put(:id, Map.get(props, :id))
  end

  defp star(:full, size, color, _empty_color),
    do: cell_box(%{}, Kati.UI.symbol("star", size: size, color: color, fill: true))

  defp star(:empty, size, _color, empty_color),
    do: cell_box(%{}, Kati.UI.symbol("star", size: size, color: empty_color))

  defp star(:half, size, color, empty_color) do
    empty = Kati.UI.symbol("star", size: size, color: empty_color)

    filled =
      cell_box(
        %{clip_width: 0.5},
        Kati.UI.symbol("star", size: size, color: color, fill: true)
      )

    cell_box(%{}, [empty, filled])
  end

  # A cell hugs its glyph and centres it. `size` is a text size, not a cell
  # width: at a large font scale Android grows the glyph in sp, and a cell a
  # fixed `size` wide would cut the outline. No height either, so the row
  # centres every star on the same line box. `clip_width` is a fraction of the
  # overlay's own laid-out width, so the half cut stays on the glyph's centre
  # at any scale. The vendored bridge treats `fill_width: false` as intrinsic.
  defp cell_box(extra, children) do
    %{
      type: :box,
      props: Map.merge(%{fill_width: false, align: :center}, extra),
      children: List.wrap(children)
    }
  end

  defp gap_node(gap), do: %{type: :box, props: %{width: gap, height: 1}, children: []}

  # A tappable cell is the glyph with two invisible half-width targets over it,
  # laid out exactly as `Kati.Screens.Rating` drew them before this component
  # carried them: the targets sit last so Compose hit-tests them first, and the
  # wrapper centres them on the taller glyph box.
  defp tappable(node, nil, _index, _size), do: node

  defp tappable(node, tags, index, size) do
    left = Event.handler(Enum.at(tags, index * 2 - 2))
    right = Event.handler(Enum.at(tags, index * 2 - 1))

    %{
      type: :box,
      props: %{fill_width: false, align: :center},
      children: [
        node,
        %{
          type: :row,
          props: %{width: size, height: size},
          children: [
            target(size / 2, size, left),
            target(size / 2, size, right)
          ]
        }
      ]
    }
  end

  defp target(width, height, handler) do
    %{type: :box, props: %{width: width, height: height}, children: []}
    |> put(:on_tap, handler)
  end

  defp put(node, _key, nil), do: node
  defp put(node, key, value), do: %{node | props: Map.put(node.props, key, value)}
end
