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

  @doc """
  A Material Symbol, by the name the design uses.

  The design's icons are Material Symbols Rounded — a ligature font — and Kati
  ships a 143-glyph subset of it. `Kati.Icons.glyph!/1` raises for a name that
  is not in the subset, because the alternative is an empty box on screen that
  reads as a layout bug rather than a missing asset.

  `fill: true` selects the FILL 1 instance. The design uses it for exactly one
  thing — the active tab — and never for a partial value.
  """
  @spec symbol(String.t(), keyword()) :: term()
  def symbol(name, opts \\ []) do
    glyph = Kati.Icons.glyph!(name)
    size = Keyword.get(opts, :size, 22)
    color = Keyword.get(opts, :color, Kati.Theme.ink())
    family = if Keyword.get(opts, :fill, false), do: "symbols_filled", else: "symbols"

    ~MOB"""
    <Text text={glyph} font_family={family} text_size={size} text_color={color} max_lines={1} />
    """
  end

  @doc """
  A fade from paper up to nothing.

  The design uses this twice over: a 120pt band under the dock so content
  dissolves rather than stopping, and a 190pt band over the bottom of a hero
  photograph so the title has something to sit on.

  It replaced a flat opaque rectangle, which does not fade — it guillotines.
  On Home it was cutting the Sections tiles in half.

  `stop` is where the gradient stops being fully opaque paper, as a percentage
  of `height` measured from the bottom. It is a parameter because the drawings
  disagree on purpose: five of them (04, 08, 14, 45, 58) want the 4% default —
  a hairline of solid paper under a dock that content may touch — while
  thirteen (01, 02, 03, 07, 16, 17, 20, 21, 30, 55, 56, 57, 61) want 42%, which
  is what actually hides the content behind the dock. At 4% the Persian Home's
  section tiles read straight through it.
  """
  @spec paper_fade(pos_integer(), number()) :: term()
  def paper_fade(height, stop \\ 4) do
    # ~MOB is an uppercase sigil, so #{} inside it is literal text — the
    # gradient string has to be built out here.
    gradient = "to_top #FFEFECE7 #{stop}% #00EFECE7"

    ~MOB"""
    <Box fill_width={true} height={height} gradient={gradient} />
    """
  end

  @doc """
  A section label: a 13x2 accent dash, then mono caps.

  The design uses it eleven times on Home alone, always
  `DM Mono 10.5px / .16em / uppercase / #A0998F` after a `#E8823C` dash — the
  one place orange appears without meaning "new" or "now", because it is
  punctuation rather than status.

  `:trailing` adds a right-aligned label, which the design uses for "See all".
  """
  @spec eyebrow(String.t(), keyword()) :: term()
  def eyebrow(label, opts \\ []) do
    trailing = Keyword.get(opts, :trailing)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
        />
        <Spacer weight={1.0} />
        {Kati.UI.eyebrow_trailing(trailing)}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def eyebrow_trailing(nil), do: ~MOB"<Spacer size={0} />"

  def eyebrow_trailing(label) do
    ~MOB"""
    <Text text={label} text_size={12.5} font_weight="semibold" text_color={0xFF8A8479} />
    """
  end

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
          <Text text={time} text_size={11} text_color={:muted} font_family="mono" />
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

  @doc """
  A filter chip.

  Three states, not two. `:disabled` is the design's own way of showing a
  section that exists but is not built yet — screens 03 and 57 draw Books and
  Music greyed rather than hiding them, which is also how #60 scoped v1 to
  Screen. Hiding them would misrepresent the app's shape; grey states the
  intent.

  ## Options

    * `:selected` — the filled state: ink pill, `#FBFAF8` label.
    * `:disabled` — transparent pill, `#B5AEA3` label.
    * `:count` — a dimmer number after the label, as the library and day filters
      draw it.

  ## No trailing gap

  This pill deliberately ends where it ends. Several screens grew their own chip
  with the inter-chip gap baked in *inside* the pill as a trailing `Spacer`,
  which both pushes the label off centre — the pill has 15dp on the left and
  15dp plus the gap on the right — and makes chips abut whenever the gap is
  interpreted as part of the background. The gap belongs to whoever is arranging
  the chips, so callers intersperse a `<Spacer width={9} />` between them.
  """
  @spec chip(String.t(), keyword() | atom()) :: term()
  def chip(label, opts \\ [])

  # The old positional-state form, kept so a call written from memory does not
  # raise on a keyword lookup against an atom.
  def chip(label, state) when is_atom(state) do
    chip(label, selected: state == :selected, disabled: state == :disabled)
  end

  def chip(label, opts) when is_list(opts) do
    count = Keyword.get(opts, :count)
    count_text = if count, do: to_string(count), else: nil

    {bg, fg, count_fg} =
      cond do
        Keyword.get(opts, :disabled, false) -> {0x00FFFFFF, 0xFFB5AEA3, 0xFFB5AEA3}
        Keyword.get(opts, :selected, false) -> {Kati.Theme.ink(), 0xFFFBFAF8, 0xFFBFB8AC}
        true -> {Kati.Theme.card(:light), 0xFF5C574F, 0xFFA0998F}
      end

    width = chip_content_width(label, count_text)

    ~MOB"""
    <Box
      background={bg}
      corner_radius={16}
      height={32}
      width={width}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      <Row align="center">
        <Text text={label} text_size={12} text_color={fg} max_lines={1} />
        {Kati.UI.chip_count(count_text, count_fg)}
      </Row>
    </Box>
    """
  end

  @doc false
  def chip_count(nil, _color), do: ~MOB"<Spacer size={0} />"

  def chip_count(text, color) do
    # A Box stacks, so the count has to share a Row with the label rather than
    # be handed to the pill as a second child.
    ~MOB"""
    <Row align="center">
      <Spacer width={6} />
      <Text text={text} text_size={11} text_color={color} max_lines={1} />
    </Row>
    """
  end

  # A Box that is not given a NUMBER for `width` fills its parent, and nothing
  # measures text on the Elixir side, so the pill is sized from the character
  # count. Crude, and honest about being crude — the alternative is a Row that
  # swallows the whole line. This counts the CONTENT only: the bridge applies
  # padding before width, so folding the 15dp sides in here would double them.
  defp chip_content_width(label, nil), do: text_width(label)
  defp chip_content_width(label, count), do: text_width(label) + 6 + text_width(count)

  # ~7dp per glyph at text_size 12; erring wide, since a clipped label reads as
  # broken while a loose one only reads as a loose chip.
  defp text_width(text), do: String.length(text) * 7

  @doc "One day in the calendar's 7-day strip."
  def day_cell(dow, num, today?, on_tap \\ nil) do
    bg = if today?, do: Kati.Theme.ink(), else: 0x00FFFFFF
    fg = if today?, do: 0xFFFBFAF8, else: 0xFF1A1917
    sub = if today?, do: 0xFFBFB8AC, else: 0xFF7C766D
    tap = on_tap || {self(), :noop}

    ~MOB"""
    <Column padding_right={7}>
      <Box width={44} height={62} background={bg} corner_radius={20} align="center" on_tap={tap}>
        <Column align="center">
          <Text text={dow} text_size={10} text_color={sub} />
          <Spacer size={4} />
          <Text text={num} text_size={15} text_color={fg} />
        </Column>
      </Box>
    </Column>
    """
  end

  @doc "A headline statistic with its label."
  def stat(value, label) do
    ~MOB"""
    <Column padding_right={26}>
      <Text text={value} text_size={22} text_color={:on_surface} letter_spacing={-0.5} />
      <Spacer size={3} />
      <Text text={label} text_size={11} text_color={:muted} />
    </Column>
    """
  end

  @doc """
  A big number and a small suffix sitting on the same baseline.

  `align="bottom"` is not baseline alignment. It bottoms out the two text
  *boxes*, and a text box carries descender space in proportion to its size, so
  a small suffix beside a big number lands 3-9dp below the number's baseline —
  far enough to read as a bug rather than as typography. The bridge has no
  baseline mode (`align` is top/center/bottom only) and no metrics come back
  from `render/1`, so the correction cannot be computed: it is declared.

  `drop` is how far the small text has to be lifted, in dp, applied as bottom
  padding. `(big_size - small_size) / 5` is a decent first guess, but it is a
  design number rather than a formula — pass what the drawing shows.

  Both texts are already-rendered nodes, so the caller keeps control of size,
  weight and colour.
  """
  @spec baseline_row(term(), term(), number()) :: term()
  def baseline_row(big, small, drop) do
    ~MOB"""
    <Row align="bottom">
      {big}
      <Column padding_bottom={drop}>
        {small}
      </Column>
    </Row>
    """
  end

  @doc "A labelled horizontal bar. Width is declared, never measured."
  def bar(label, width, tone) do
    ~MOB"""
    <Column padding_bottom={11} fill_width={true}>
      <Row align="center">
        <Box width={92} height={22} align="leading">
          <Column>
            <Text text={label} text_size={12} text_color={:on_surface} />
          </Column>
        </Box>
        <Box width={width} height={9} background={tone} corner_radius={5} />
      </Row>
    </Column>
    """
  end

  @doc """
  The design's pixel field: 104 cells at 2px radius, the shared visual for
  anything that accumulates over time.

  Chunked into declared rows because `Row` does not wrap and no geometry comes
  back from `render/1`.
  """
  def pixel_field(intensities, per_row) do
    rows = Enum.chunk_every(intensities, per_row)

    ~MOB"""
    <Column>
      {Enum.map(rows, fn row -> Kati.UI.pixel_row(row) end)}
    </Column>
    """
  end

  @doc false
  def pixel_row(row) do
    ~MOB"""
    <Row>
      {Enum.map(row, fn i -> Kati.UI.pixel(i) end)}
    </Row>
    """
  end

  @doc false
  def pixel(intensity) do
    tone =
      case intensity do
        0 -> 0xFFE4DFD6
        1 -> 0xFFD8CDB8
        2 -> 0xFFC7A97E
        3 -> 0xFFB08E55
        _ -> 0xFF8A6B3A
      end

    ~MOB"""
    <Column padding_right={3} padding_bottom={3}>
      <Box width={15} height={15} background={tone} corner_radius={2} />
    </Column>
    """
  end
end
