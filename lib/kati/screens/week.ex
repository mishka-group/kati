defmodule Kati.Screens.Week do
  @moduledoc """
  Screen 17 — Calendar, week.

  Built to `.scratch/design/screens/17.html`. Seven `flex:1` lanes of blocks
  with no titles in them: height is duration, colour is section, and the only
  text a block carries is its start hour in mono. Names live in the card
  underneath, for whichever lane you tap — which is what the `touch_app` line
  between them says out loud.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active.

  ## Two eyebrows, two dashes

  `Kati.UI.eyebrow/2` always draws the accent dash, and the drawing uses it
  for the named day. "Load this week" gets a `#C4BDB3` dash instead — the
  design's way of marking a section that reports rather than points at
  something happening — so that one is drawn here.

  ## The sentence under the bars

  The drawing sets `9 items` in bold inside a running sentence. A `Text` node
  carries one style, and this bridge has no rich-text run, so the three
  fragments the design writes are composed into a single wrapping paragraph
  and the inline bold is lost. Splitting it into three `Text` nodes in a `Row`
  would keep the weight and lose the wrap, which is the worse trade for a
  sentence this long.
  """
  use Kati.Screens.Root, root: :calendar

  alias Kati.Calendar.SampleWeek
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :week, SampleWeek.week())

  @doc false
  def content(assigns) do
    week = assigns.week

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Week.header(week)}
        {Kati.Screens.Week.switcher()}
        {Kati.Screens.Week.lanes(week)}
        {UI.eyebrow(week.selected_label)}
        {Kati.Screens.Week.events(week)}
        {Kati.Screens.Week.hint()}
        {Kati.Screens.Week.muted_eyebrow("Load this week")}
        {Kati.Screens.Week.load_card(week)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(week) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={week.range}
          text_size={22}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {UI.symbol("chevron_left", size: 22, color: 0xFF8A8479)}
        <Spacer size={8} />
        {UI.symbol("chevron_right", size: 22, color: 0xFF1A1917)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def switcher do
    bar =
      Kati.Screens.ViewSwitcher.bar([
        {"Day", false},
        {"Week", true},
        {"Month", false},
        {"Agenda", false}
      ])

    ~MOB"""
    <Column fill_width={true}>
      {bar}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def lanes(week) do
    columns =
      week.lanes
      |> Enum.map(fn lane -> Kati.Screens.Week.lane(lane) end)
      |> Enum.intersperse(lane_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {columns}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def lane_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def lane(lane) do
    ~MOB"""
    <Column weight={1.0}>
      {Kati.Screens.Week.lane_header(lane)}
      <Spacer size={6} />
      {Kati.Screens.Week.blocks(lane.blocks)}
    </Column>
    """
  end

  # Only the selected lane's header sits on a card; the rest are bare paper.
  @doc false
  def lane_header(lane) do
    background = if lane.selected?, do: 0xFFFBFAF8, else: 0x00FFFFFF
    shadow = if lane.selected?, do: "0 1 2 0 #0D1A1917", else: nil

    ~MOB"""
    <Column
      fill_width={true}
      corner_radius={12}
      background={background}
      shadow={shadow}
      padding_top={7}
      padding_bottom={9}
    >
      <Box fill_width={true} align="center">
        <Text
          text={lane.name}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.06}
          text_color={0xFFB3ACA2}
          max_lines={1}
        />
      </Box>
      <Spacer size={4} />
      <Box fill_width={true} align="center">
        <Text text={lane.day} text_size={14} font_weight="bold" text_color={:on_surface} max_lines={1} />
      </Box>
    </Column>
    """
  end

  @doc false
  def blocks(blocks) do
    ~MOB"""
    <Column fill_width={true}>
      {blocks
       |> Enum.map(fn block -> Kati.Screens.Week.block(block) end)
       |> Enum.intersperse(Kati.Screens.Week.block_gap())}
    </Column>
    """
  end

  @doc false
  def block_gap, do: ~MOB"<Spacer size={4} />"

  # `border-left: 2.5px solid` is a real child, not a border prop: the bridge's
  # border draws all four edges, and the drawing wants only the leading one.
  # The Row's corner_radius clips it, which is exactly what a bordered box with
  # a radius does in the browser.
  @doc false
  def block(block) do
    style = SampleWeek.style(block.section)
    height = block.height
    background = style.background
    rule = style.rule
    shadow = style.shadow

    ~MOB"""
    <Row
      fill_width={true}
      height={height}
      corner_radius={9}
      background={background}
      shadow={shadow}
      align="top"
    >
      <Box width={2.5} height={height} background={rule} />
      <Column padding_left={6} padding_right={6} padding_top={7} padding_bottom={7}>
        <Text text={block.hour} font_family="mono" text_size={10} text_color={0xFFA0998F} max_lines={1} />
      </Column>
    </Row>
    """
  end

  @doc false
  def events(week) do
    last = length(week.events) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {week.events
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Week.event_row(row, i < last) end)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def event_row(row, rule?) do
    rule_color = if row.rule == :screen, do: Theme.accent(), else: Theme.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        <Column width={38}>
          <Text text={row.time} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box width={3} height={20} corner_radius={2} background={rule_color} />
        <Spacer size={12} />
        <Text
          text={row.title}
          text_size={13}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={12} />
        <Text text={row.length} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
      </Row>
      {Kati.Screens.Week.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box, and `render: :box` rather
  # than the component's `:divider` default.
  #
  # `:divider` is NOT the Box this used to be. The comment that stood here said
  # it was — that Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))` — and that is wrong:
  # Material3 draws it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an
  # ANTIALIASED stroke. At this device's 2.6875x a 1dp rule gets a 3px canvas
  # and a 2.6875px stroke centred in it, so the bottom pixel row lands at ~69%
  # coverage — a full-width row 4-5/255 lighter than the two above it. The
  # adoption softened the hairline by one pixel row and nothing said so.
  #
  # `render: :box` is the component's filled-rect primitive: `<Box fill_width
  # height={thickness} background={color}>`, which is the node that was written
  # here by hand before the adoption, so the rule goes back to three full-colour
  # rows. (Its `<Spacer size={1} />` child is an iOS height workaround — on
  # Android the Box's own `height` pins it and the background covers it.)
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true),
    do: MishkaSeparator.separator(color: 0x121A1917, thickness: 1, render: :box)

  @doc false
  def hint do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {UI.symbol("touch_app", size: 15, color: 0xFFB3ACA2)}
        <Spacer size={8} />
        <Text text="Tap any lane to name its day here" text_size={11.5} text_color={0xFF8A8479} />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Kati.UI.eyebrow's dash is always the accent; this one is #C4BDB3.
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFC4BDB3} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def load_card(week) do
    load = week.load

    bars =
      load.bars
      |> Enum.map(fn {height, peak?} -> Kati.Screens.Week.bar(height, peak?) end)
      |> Enum.intersperse(bar_gap())

    letters =
      load.letters
      |> Enum.map(fn letter -> Kati.Screens.Week.letter(letter) end)

    sentence = load.lead <> " " <> load.strong <> load.tail

    ~MOB"""
    <Column
      fill_width={true}
      background={Theme.card(:light)}
      corner_radius={20}
      shadow={Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} height={56} align="bottom">
        {bars}
      </Row>
      <Spacer size={10} />
      <Row fill_width={true} align="center">
        {letters}
      </Row>
      <Spacer size={12} />
      <Text text={sentence} text_size={12.5} line_height={1.45} text_color={0xFF5C574F} />
    </Column>
    """
  end

  @doc false
  def bar_gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def bar(height, peak?) do
    color = if peak?, do: Theme.ink(), else: 0xFFE4E0D9

    ~MOB"""
    <Box weight={1.0} height={height} corner_radius={5} background={color} />
    """
  end

  @doc false
  def letter(letter) do
    ~MOB"""
    <Box weight={1.0} align="center">
      <Text text={letter} font_family="mono" text_size={9.5} text_color={0xFFB3ACA2} max_lines={1} />
    </Box>
    """
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  # The switcher this screen draws is its only control, and its three live
  # segments (`view_Day`, `view_Month`, `view_Agenda`) are routed by the module
  # that drew them. `Kati.Screens.ViewSwitcher.handle_tap/2` returns the socket
  # untouched for anything that is not a `view_*` tag, so delegating the whole
  # callback is safe and stays right if this screen grows a control of its own
  # — those clauses go above this line.
  @impl true
  def handle_tap(tag, socket), do: Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
end
