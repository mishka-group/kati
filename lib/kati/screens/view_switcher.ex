defmodule Kati.Screens.ViewSwitcher do
  @moduledoc """
  Day / Week / Month / Agenda — the one switcher screens 16, 17 and 30 share.

  The drawing is literal about it: a `#E4E0D9` trough at radius 16 with 4pt of
  padding, four `flex:1` segments 34 tall at radius 12, and the selected one
  lifted onto card white with its own shallow shadow.

  Hand-rolled rather than `Kati.Components.MishkaSegmentedControl`, and the
  reason is that `flex:1`. That port's own docs say its segments are
  **content-sized** — it drops `weight` so the Android and iOS mappings agree —
  which would bunch four labels of unequal length against the leading edge
  instead of giving each an exact quarter of the strip. Everything else about
  the port would have fitted; the one thing it cannot do is the thing this
  control is.

  The labels stay with the screens rather than living here, so each screen
  file still contains every word its drawing contains.
  """

  import Mob.Sigil

  # `0 1px 2px rgba(26,25,23,.06), 0 6px 12px -8px rgba(26,25,23,.4)`.
  # Shallower than the card recipe because the tile is lifted off a trough
  # rather than off paper.
  @selected_shadow "0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"

  @doc """
  The strip, given `[{label, selected?}]` in the order the design draws them.
  """
  @spec bar([{String.t(), boolean()}]) :: term()
  def bar(items) do
    segments =
      items
      |> Enum.map(fn {label, on?} -> segment(label, on?) end)
      |> Enum.intersperse(gap())

    ~MOB"""
    <Box fill_width={true} background={0xFFE4E0D9} corner_radius={16} padding={4}>
      <Row fill_width={true} align="center">
        {segments}
      </Row>
    </Box>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def segment(label, on?) do
    # Bound to locals first: inside ~MOB an `@name` is an assign, never a
    # module attribute, so @selected_shadow would be read as assigns.selected_shadow.
    shadow = if on?, do: @selected_shadow, else: nil
    background = if on?, do: 0xFFFBFAF8, else: 0x00FFFFFF
    color = if on?, do: 0xFF1A1917, else: 0xFFAFA89E
    weight = if on?, do: "bold", else: "semibold"

    ~MOB"""
    <Box
      weight={1.0}
      height={34}
      corner_radius={12}
      background={background}
      shadow={shadow}
      align="center"
    >
      <Text text={label} text_size={12.5} font_weight={weight} text_color={color} max_lines={1} />
    </Box>
    """
  end
end
