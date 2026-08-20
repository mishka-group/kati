defmodule Kati.Screens.MonthGrid do
  @moduledoc """
  Screen 16 — Calendar, month.

  Built to `.scratch/design/screens/16.html`. The design's own caption states
  the idea: *"Month view is a load map, not a list"* — one dot per section, a
  filled card on the heaviest day, and the selected day's clashes summarised
  underneath. Nothing on the grid says what an event is called, because at
  seven columns nothing legible would fit.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active, so it renders through `Kati.Shell` and the four-mode switcher is how
  you leave it rather than a back pill.

  ## The square is the bridge's, not a declared number

  Each cell is `aspect-ratio: 1` in the export, and `aspect_ratio={1.0}` is
  what the cell carries — the modifier chain is weight → aspect_ratio, so the
  height follows the width the Row actually handed out, at any frame. The 50
  that used to be declared here was only ever the answer at the drawing's own
  402pt frame: `(360 - 12) / 7 = 49.7`. A 411dp device gives each column 51,
  so a capture measured the cells 51 wide and 50 tall — squares that were not
  square. `Kati.Screens.Widgets` and `Kati.Screens.SeriesMeta` carry the same
  fix for the same reason.
  """
  use Kati.Screens.Root, root: :calendar

  alias Kati.Calendar.SampleMonth
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme
  alias Kati.UI

  # Monday-first, matching the drawing's header row. Duplicated letters are
  # the design's, not a mistake: Tuesday and Thursday are both T.
  @weekdays ["M", "T", "W", "T", "F", "S", "S"]

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :month, SampleMonth.month())

  @doc false
  def content(assigns) do
    month = assigns.month

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.MonthGrid.header(month)}
        {Kati.Screens.MonthGrid.switcher()}
        {Kati.Screens.MonthGrid.weekday_row()}
        {Kati.Screens.MonthGrid.grid(month)}
        {Kati.Screens.MonthGrid.legend()}
        {UI.eyebrow(month.selected_label)}
        {Kati.Screens.MonthGrid.clashes(month)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(month) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={month.title}
          text_size={24}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={6} />
        {UI.symbol("unfold_more", size: 19, color: 0xFF8A8479)}
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
        {"Week", false},
        {"Month", true},
        {"Agenda", false}
      ])

    ~MOB"""
    <Column fill_width={true}>
      {bar}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def weekday_row do
    cells =
      @weekdays
      |> Enum.map(fn letter -> Kati.Screens.MonthGrid.weekday(letter) end)
      |> Enum.intersperse(cell_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {cells}
      </Row>
      <Spacer size={6} />
    </Column>
    """
  end

  @doc false
  def weekday(letter) do
    ~MOB"""
    <Box weight={1.0} align="center">
      <Text
        text={letter}
        font_family="mono"
        text_size={10}
        letter_spacing={0.08}
        text_color={0xFFB3ACA2}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def grid(month) do
    rows = Enum.chunk_every(month.days, 7)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.MonthGrid.grid_row(row) end)}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    cells =
      row
      |> Enum.map(fn day -> Kati.Screens.MonthGrid.day_cell(day) end)
      |> Enum.intersperse(cell_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cells}
      </Row>
      <Spacer size={2} />
    </Column>
    """
  end

  # The cell centres its stack, and both halves of that are load-bearing:
  # a Column takes no horizontal alignment on this bridge, so the number and
  # the dot row are centred by full-width Rows with weighted Spacers either
  # side, and the Box's align="center" is what puts the pair on the cell's
  # vertical middle.
  @doc false
  def day_cell(day) do
    background = day.background
    shadow = day.shadow
    color = day.color
    weight = day.weight

    ~MOB"""
    <Box
      weight={1.0}
      aspect_ratio={1.0}
      corner_radius={13}
      background={background}
      shadow={shadow}
      align="center"
    >
      <Column fill_width={true}>
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text text={day.label} text_size={13.5} font_weight={weight} text_color={color} max_lines={1} />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.MonthGrid.dots(day.dots)}
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Box>
    """
  end

  # An empty day still reserves the 5pt band, so a date with no dots sits at
  # the same height as one with three. The drawing does the same — the dot
  # container is `height:5px` whether or not it has children.
  @doc false
  def dots([]), do: ~MOB"<Row height={5} />"

  def dots(colors) do
    children =
      colors
      |> Enum.map(fn color -> Kati.Screens.MonthGrid.dot(color) end)
      |> Enum.intersperse(dot_gap())

    ~MOB"""
    <Row height={5} align="center">
      {children}
    </Row>
    """
  end

  @doc false
  def dot_gap, do: ~MOB"<Spacer size={2.5} />"

  @doc false
  def dot(color) do
    ~MOB"""
    <Box width={5} height={5} corner_radius={3} background={color} />
    """
  end

  @doc false
  def legend do
    items =
      SampleMonth.legend()
      |> Enum.map(fn {color, label} -> Kati.Screens.MonthGrid.legend_item(color, label) end)
      |> Enum.intersperse(legend_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {items}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={14} />"

  @doc false
  def legend_item(color, label) do
    ~MOB"""
    <Row align="center">
      <Box width={6} height={6} corner_radius={3} background={color} />
      <Spacer size={6} />
      <Text
        text={String.upcase(label)}
        font_family="mono"
        text_size={10}
        letter_spacing={0.08}
        text_color={0xFFA0998F}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def clashes(month) do
    last = length(month.clashes) - 1

    ~MOB"""
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
      {month.clashes
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.MonthGrid.clash_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def clash_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column width={38}>
          <Text text={row.time} font_family="mono" text_size={11.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Box width={3} height={22} corner_radius={2} background={Theme.accent()} />
        <Spacer size={13} />
        <Text
          text={row.label}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={13} />
        {UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)}
      </Row>
      {Kati.Screens.MonthGrid.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box. A horizontal rule with no
  # label is the whole of what that component draws, and it draws it as
  # `<Divider>` — which on this bridge is Compose's `HorizontalDivider`, i.e.
  # `Box(fillMaxWidth().height(thickness.dp).background(color))`. That is
  # literally the Box that used to be written here, so the rule is the same
  # 1dp band of the same 7%-ink at the same width.
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true), do: MishkaSeparator.separator(color: 0x121A1917, thickness: 1)

  # ── What a tap changes ────────────────────────────────────────────────────

  # The switcher this screen draws is its only control, and its three live
  # segments (`view_Day`, `view_Week`, `view_Agenda`) are routed by the module
  # that drew them. `Kati.Screens.ViewSwitcher.handle_tap/2` returns the socket
  # untouched for anything that is not a `view_*` tag, so delegating the whole
  # callback is safe and stays right if this screen grows a control of its own
  # — those clauses go above this line.
  @impl true
  def handle_tap(tag, socket), do: Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
end
