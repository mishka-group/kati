defmodule Kati.UI do
  @moduledoc """
  Shared building blocks, styled to the design.

  These live here rather than in Mishka Chelekom for now: #44 decided every
  component is built in Kati first and only promoted upstream once Kati has
  actually used it, so that other people's apps never receive a half-proven
  component.

  ## Sizing rules that govern every helper here

    * A `Box` **always** fills its parent's width unless it carries an explicit
      `width` (`MobBridge.kt:2662`). `fill_width: false` does not opt out.
    * `Row` and `Column` hug their content.
    * There is no wrapping primitive, and no geometry is reported back to
      `render/1`, so anything grid-shaped is chunked by a **declared** column
      count rather than measured.
  """

  import Mob.Sigil

  @doc "The elevated card: the design's most repeated recipe (262 uses)."
  def card(children, opts \\ []) do
    pad = Keyword.get(opts, :padding, 21)
    bg = Keyword.get(opts, :background, :surface)

    ~MOB"""
    <Box background={bg} corner_radius={20} padding={pad} fill_width={true}>
      <Column fill_width={true}>
        {children}
      </Column>
    </Box>
    """
  end

  @doc "Section heading: small, muted, letter-spaced — sits above a rail or list."
  def section_title(text) do
    ~MOB"""
    <Column padding_bottom={9}>
      <Text text={text} text_size={11} text_color={:muted} letter_spacing={0.14} />
    </Column>
    """
  end

  @doc """
  A poster tile at the design's 2:3 ratio.

  Real artwork arrives with the media tickets; until then this is a toned
  placeholder rather than a network fetch, so the shell can be judged offline
  and on a cold emulator.
  """
  def poster(label, tone) do
    ~MOB"""
    <Column padding_right={13}>
      <Box width={112} height={168} background={tone} corner_radius={14} align="bottom">
        <Column padding={9}>
          <Text text={label} text_size={10} text_color={0xFFFBFAF8} />
        </Column>
      </Box>
    </Column>
    """
  end

  @doc "A row in the day timeline: fixed time gutter, then the event card."
  def timeline_row(time, title, meta, accent?) do
    dot = if accent?, do: Kati.Theme.accent(), else: 0xFFC9C3B8

    ~MOB"""
    <Row align="top" fill_width={true}>
      <Box width={54} height={44} align="top">
        <Column>
          <Text text={time} text_size={11} text_color={:muted} font_family="monospace" />
        </Column>
      </Box>
      <Box width={16} height={44} align="top">
        <Column padding_top={4}>
          <Box width={7} height={7} background={dot} corner_radius={4} />
        </Column>
      </Box>
      <Column fill_width={true} padding_bottom={13}>
        <Text text={title} text_size={14} text_color={:on_surface} />
        <Spacer size={2} />
        <Text text={meta} text_size={11} text_color={:muted} />
      </Column>
    </Row>
    """
  end

  @doc "A two-up tile for the Sections grid. Chunked by a declared count — nothing wraps."
  def section_tile(label, count, tone) do
    ~MOB"""
    <Column padding_right={13} padding_bottom={13}>
      <Box width={158} height={92} background={tone} corner_radius={20} align="bottom">
        <Column padding={15}>
          <Text text={label} text_size={14} text_color={:on_surface} />
          <Spacer size={2} />
          <Text text={count} text_size={11} text_color={:muted} />
        </Column>
      </Box>
    </Column>
    """
  end
end
