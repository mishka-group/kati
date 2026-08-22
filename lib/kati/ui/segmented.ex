defmodule Kati.UI.Segmented do
  @moduledoc """
  The text-only segmented control: a paper trough holding one raised tile.

  Screen 20 already has a segmented control and this is not it. That one
  carries an icon beside each label, stands 38pt tall in an 18pt trough, and
  switches the *shelf you are looking at*. This one is 34pt in a 16pt trough,
  has no icons, and switches the **unit a number is entered in** — `Page ·
  Percent · Minutes` on screen 70, and the same three sizes wherever a value
  can be given more than one way.

  Two controls that look alike and mean different things, so they are two
  functions rather than one with a flag. Screen 20's stays exactly where it is:
  it is signed off against a captured frame, and folding it into this would put
  a pixel diff on a screen nobody asked to change.

  ## The disabled segment

  Screen 71 draws one and says in its own caption that *a disabled segment has
  no precedent in the 62*, then specifies it: paper track, `#C4BDB3` label with
  a hairline strike, no thumb. That is `disabled: true` here, and the strike is
  a real 1pt Box rather than a font feature, because Compose's
  `TextDecoration.LineThrough` lands on the glyph baseline and the drawing puts
  it through the middle.
  """

  import Mob.Sigil

  alias Kati.Theme.Palette

  @doc """
  A trough of segments.

  `options` is a list of `{label, tag}` or `{label, tag, :disabled}`. `selected`
  is the tag of the raised one. Tapping a segment sends `{:tap, tag}` — a
  disabled one sends nothing, which is the difference between a control that is
  off and a control that is missing.
  """
  @spec plain([tuple()], atom()) :: map()
  def plain(options, selected) do
    segments =
      options
      |> Enum.map(fn
        {label, tag} -> segment(label, tag, tag == selected, false)
        {label, tag, :disabled} -> segment(label, tag, false, true)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={4} />")

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.placeholder()}
      corner_radius={16}
      padding={4}
      align="center"
    >
      {segments}
    </Row>
    """
  end

  # Three clauses rather than one with conditional props, for the reason screen
  # 20's own segment gives: the raised tile is *defined* by its shadow, and a
  # nil shadow prop flattens it into the trough rather than omitting a
  # decoration.
  defp segment(label, tag, true, _disabled) do
    assigns = %{label: label, tap: {self(), tag}}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Row
        fill_width={true}
        height={34}
        corner_radius={12}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917"
        align="center"
      >
        <Spacer weight={1.0} />
        <Text
          text={@label}
          text_size={12.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  defp segment(label, _tag, false, true) do
    assigns = %{label: label}

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={34} align="center">
        <Spacer weight={1.0} />
        <Box>
          <Text
            text={@label}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.track_off()}
            max_lines={1}
          />
          <Box fill_width={true} fill_height={true} align="center">
            <Box fill_width={true} height={1} background={Palette.track_off()} />
          </Box>
        </Box>
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  defp segment(label, tag, false, false) do
    assigns = %{label: label, tap: {self(), tag}}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Row fill_width={true} height={34} align="center">
        <Spacer weight={1.0} />
        <Text
          text={@label}
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.segment_idle()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end
end
