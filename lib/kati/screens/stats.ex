defmodule Kati.Screens.Stats do
  @moduledoc """
  Screen 07 — Your year.

  Built to `.scratch/design/screens/07.html`: a cream hero carrying the year's
  headline figure, a change pill, and 26 weeks of contribution squares; three
  count cards; then the breakdown bars.

  The contribution grid is a `flex-wrap` of 8px squares in the drawing, and
  Mob has no wrap primitive — so it is chunked into rows of 26, one column per
  week, which is exactly the "26 weeks" the design labels it with.
  """
  use Kati.Screens.Root, root: :stats

  alias Kati.Stats.Sample
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :year, Sample.year())

  @doc false
  def content(assigns) do
    year = assigns.year

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Stats.header(year)}
        {Kati.Screens.Stats.hero(year)}
        {Kati.Screens.Stats.counts(year)}
        {UI.eyebrow("Where the hours went")}
        {Kati.Screens.Stats.breakdown(year)}
        <Spacer size={26} />
        {UI.eyebrow("More numbers")}
        {Kati.Screens.Stats.more_numbers()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="center">
        <Column weight={1.0}>
          <Text text="Your year" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={year.range} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("ios_share", size: 21)}
        </Box>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def hero(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={24}
        shadow={Kati.Theme.shadow_hero()}
        padding={19}
      >
        <Row fill_width={true} vertical_align="bottom">
          <Column weight={1.0}>
            <Text text={String.upcase("Time watched")} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFB09A72} />
            <Spacer size={7} />
            <Text text={year.time} text_size={34} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} />
          </Column>
          <Row height={28} corner_radius={14} background={0x294E9A73} padding_left={9} padding_right={11} vertical_align="center">
            {Kati.UI.symbol("arrow_drop_up", size: 14, color: 0xFF3E8460, fill: true)}
            <Spacer size={5} />
            <Text text={year.change} font_family="mono" text_size={11.5} font_weight="medium" text_color={0xFF3E8460} />
          </Row>
        </Row>
        <Spacer size={18} />
        {Kati.Screens.Stats.grid()}
        <Spacer size={12} />
        <Row fill_width={true}>
          <Text text={"#{year.weeks} weeks"} font_family="mono" text_size={10} text_color={0xFFB09A72} />
          <Spacer weight={1.0} />
          <Text text={year.streak} font_family="mono" text_size={10} text_color={0xFFB09A72} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # 26 columns per row, one per week. 26*8 + 25*4 = 308, inside the 360 the
  # gutters leave, which is why the design's wrap lands on 26 as well.
  @doc false
  def grid do
    rows = Sample.contributions() |> Enum.chunk_every(26)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Stats.grid_row(row) end)}
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    ~MOB"""
    <Column>
      <Row>
        {row |> Enum.map(&Kati.Screens.Stats.cell/1) |> Enum.intersperse(Kati.Screens.Stats.cell_gap())}
      </Row>
      <Spacer size={4} />
    </Column>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell(level) do
    color = Sample.intensity(level)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={color} />
    """
  end

  @doc false
  def counts(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="top">
        {year.counts |> Enum.map(fn {n, l} -> Kati.Screens.Stats.count_card(n, l) end) |> Enum.intersperse(Kati.Screens.Stats.count_gap())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def count_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def count_card(number, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card()}
        padding={15}
      >
        <Text text={number} text_size={26} font_weight="extrabold" letter_spacing={-0.035} text_color={:on_surface} />
        <Spacer size={4} />
        <Text text={String.upcase(label)} font_family="mono" text_size={10.5} letter_spacing={0.1} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def breakdown(year) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
    >
      {Enum.map(year.breakdown, fn row -> Kati.Screens.Stats.bar(row) end)}
    </Column>
    """
  end

  @doc false
  def bar({name, fraction, value, color}) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="center">
        <Column width={88}>
          <Text text={name} text_size={12.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Box fill_width={true} height={8} corner_radius={4} background={0xFFEFECE7}>
            <Row fill_width={true}>
              <Box weight={fraction} height={8} corner_radius={4} background={color} />
              <Spacer weight={1.0 - fraction} />
            </Row>
          </Box>
        </Box>
        <Spacer size={12} />
        <Column width={34}>
          <Text text={value} font_family="mono" text_size={11} text_color={0xFFA9A29A} text_align="right" max_lines={1} />
        </Column>
      </Row>
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def more_numbers do
    rows = Kati.Stats.Sample.more_numbers()
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Stats.number_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def number_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="center" padding_top={13} padding_bottom={13}>
        <Box width={30} height={30} corner_radius={9} background={0xFFEFECE7} align="center">
          {Kati.UI.symbol(row.icon, size: 17, color: 0xFF5C574F)}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)}
      </Row>
      {Kati.Screens.Stats.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"
end
