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

  The two glyphs are siblings in a Box with the cell's **width and no height**.
  The width is what the 50% crop needs; the height must hug the glyph's line
  box, which at `size: 22` is a few dp taller than 22. A fixed `size × size`
  Box made this one cell shorter than its neighbours: the Row centred a 22dp
  box against the other stars' taller text boxes and the half star's baseline
  dropped below the line. Removing the height puts it back in the same line
  box, exactly as a bare star is.

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
  | `id` | string | unset | Native testTag on the row. |

  Children are ignored; the row is data.
  """

  import Mob.Sigil

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

    cells =
      1..max
      |> Enum.map(fn i ->
        cond do
          i <= full -> star(:full, size, color, empty_color)
          i == full + 1 and half_star? -> star(:half, size, color, empty_color)
          true -> star(:empty, size, color, empty_color)
        end
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
    do: Kati.UI.symbol("star", size: size, color: color, fill: true)

  defp star(:empty, size, _color, empty_color),
    do: Kati.UI.symbol("star", size: size, color: empty_color)

  defp star(:half, size, color, empty_color) do
    %{
      type: :box,
      props: %{width: size},
      children: [
        Kati.UI.symbol("star", size: size, color: empty_color),
        %{
          type: :box,
          props: %{width: size, clip_width: 0.5},
          children: [Kati.UI.symbol("star", size: size, color: color, fill: true)]
        }
      ]
    }
  end

  defp gap_node(gap), do: %{type: :box, props: %{width: gap, height: 1}, children: []}

  defp put(node, _key, nil), do: node
  defp put(node, key, value), do: %{node | props: Map.put(node.props, key, value)}
end
