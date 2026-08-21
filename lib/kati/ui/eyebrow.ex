defmodule Kati.UI.Eyebrow do
  @moduledoc """
  The section label's *quiet* variant: a grey dash instead of an orange one.

  `Kati.UI.eyebrow/2` always draws the `#E8823C` dash, and that is right,
  because the design's rule is that **orange only ever means "new" or "now"**.
  Screens 10, 11 and 13 each carry a section that is the opposite of new — a
  queue that has gone cold, a service dropping titles, the films that do *not*
  fit tonight — and every one of them swaps the dash to `#C4BDB3` in the
  drawing. Same typography, same 13x2 rule, same 11pt gap underneath; only the
  dash changes.

  So this is not a second eyebrow style, it is the same eyebrow with its one
  meaningful bit turned off, and keeping it here means the three screens agree
  rather than each inventing a grey dash of its own.
  """

  import Mob.Sigil

  @doc "A section label whose dash is muted, for a section that is not new."
  @spec quiet(String.t()) :: term()
  def quiet(label) do
    # `rail_idle` is the only token whose light value is `0xFFC4BDB3`, and its
    # meaning transfers exactly: the palette calls it "the rail beside a timeline
    # row that is not now", and this dash is the same statement about a section.
    # Both are the drawing saying *present, but not now* in the same grey, and
    # dark draws that grey as `#4A453F` on screen 28.
    dash = Kati.Theme.Palette.rail_idle()
    label_color = Kati.Theme.Palette.eyebrow()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={dash} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={label_color}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end
end
