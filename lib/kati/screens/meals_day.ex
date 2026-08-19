defmodule Kati.Screens.MealsDay do
  @moduledoc """
  Screen 52 — meals on the calendar.

  Built to `.scratch/design/screens/52.html`. A day where five of the eleven
  items are meals, drawn to prove that meals need no special lane: they take a
  bronze rule, sit in clock order with everything else, and then collapse into
  a single row under the same 3+ density rule that collapses six episodes on
  screen 09.

  Pushed under Calendar — the drawing's back pill says `‹ Calendar` — so the
  frame's bottom padding is **40, not 132**. There is no dock here, and 132
  would leave a hand's width of dead paper under the last row.

  ## Where this diverges from the drawing

    * The lane rule is `align-self: stretch` in the design and a declared 34pt
      here. Nothing measures geometry on this bridge, and every row carries the
      same two lines of text, so a fixed rule is exact rather than approximate
      — but it would need revisiting if a title ever wrapped.
    * An unlogged meal's ring is drawn empty. The design puts a `check` glyph
      inside it at `rgba(26,25,23,0)` — fully transparent — which is a way of
      reserving space in CSS, not a mark anyone sees.
  """
  use Kati.Screens.Pushed, back: "Calendar"

  alias Kati.Calendar.SampleMealDay
  alias Kati.Theme
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :day, SampleMealDay.day())

  @doc false
  def content(assigns) do
    day = assigns.day

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.MealsDay.header()}
        {Kati.Screens.MealsDay.title(day)}
        {Kati.Screens.MealsDay.chips(day)}
        {Kati.Screens.MealsDay.timeline(day)}
        {Kati.Screens.MealsDay.muted_eyebrow("Collapse meals")}
        {Kati.Screens.MealsDay.collapsed(day)}
        {Kati.Screens.MealsDay.note(day)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is drawn by Kati.Screens.Pushed over this content; this row
  # reserves its height and carries the density control opposite it.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Theme.card(:light)}
          shadow={Theme.shadow_button()}
          align="center"
        >
          {UI.symbol("density_medium", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={day.title}
        text_size={28}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text text={day.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {day.chips
         |> Enum.with_index()
         |> Enum.map(fn {{label, count}, i} -> Kati.Screens.MealsDay.chip(label, count, i == 0) end)
         |> Enum.intersperse(Kati.Screens.MealsDay.chip_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(label, count, on?) do
    background = if on?, do: Theme.ink(), else: Theme.card(:light)
    color = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    shadow = if on?, do: nil, else: Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={background}
      shadow={shadow}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <Text text={label} text_size={12} font_weight="semibold" text_color={color} max_lines={1} />
      {Kati.Screens.MealsDay.chip_count(count)}
    </Row>
    """
  end

  # The count is the label at 60% — `opacity:.6` on the same colour, which as
  # ARGB is the alpha, not a lighter grey.
  @doc false
  def chip_count(nil), do: ~MOB"<Spacer size={0} />"

  def chip_count(count) do
    ~MOB"""
    <Row align="center">
      <Spacer size={6} />
      <Text text={count} font_family="mono" text_size={10} text_color={0x995C574F} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def timeline(day) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(day.rows, fn row -> Kati.Screens.MealsDay.row(row) end)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def row(row) do
    background = if row.state == :past, do: 0xFFF4F1EC, else: Theme.card(:light)
    shadow = if row.state == :past, do: nil, else: Theme.shadow_card_soft()
    color = if row.state == :past, do: 0xFF9C958B, else: 0xFF1A1917

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={13}>
          <Text text={row.time} font_family="mono" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row
            fill_width={true}
            background={background}
            corner_radius={17}
            shadow={shadow}
            padding_left={13}
            padding_right={13}
            padding_top={12}
            padding_bottom={12}
            align="center"
          >
            <Box width={3} height={34} corner_radius={2} background={row.rule} />
            <Spacer size={11} />
            <Column weight={1.0}>
              <Text text={row.title} text_size={13} font_weight="semibold" text_color={color} max_lines={1} />
              <Spacer size={4} />
              <Text text={row.sub} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
            </Column>
            {Kati.Screens.MealsDay.check(row.check)}
          </Row>
        </Box>
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  # In a Row, after the text. As a sibling inside the Box it would stack over
  # the title instead of sitting beside it.
  @doc false
  def check(:none), do: ~MOB"<Spacer size={0} />"

  def check(:eaten) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      <Box
        width={24}
        height={24}
        corner_radius={12}
        background={0xFF4E9A73}
        border_color={0xFF4E9A73}
        border_width={1.5}
        align="center"
      >
        {Kati.UI.symbol("check", size: 14, color: 0xFFFBFAF8)}
      </Box>
    </Row>
    """
  end

  def check(:todo) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      <Box
        width={24}
        height={24}
        corner_radius={12}
        border_color={0x291A1917}
        border_width={1.5}
      />
    </Row>
    """
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange here would claim
  # the collapsed meals are new. The design draws this one #C4BDB3.
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
  def collapsed(day) do
    collapsed = day.collapsed

    ~MOB"""
    <Row
      fill_width={true}
      background={Theme.card(:light)}
      corner_radius={18}
      shadow={Theme.shadow_card_soft()}
      padding_left={14}
      padding_right={14}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      <Box width={3} height={36} corner_radius={2} background={collapsed.rule} />
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={collapsed.title} text_size={13} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer size={4} />
        <Text text={collapsed.sub} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
      <Spacer size={12} />
      {UI.symbol("expand_more", size: 19, color: 0xFF5C574F)}
    </Row>
    """
  end

  @doc false
  def note(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      <Row fill_width={true} align="top" padding_left={2} padding_right={2}>
        {UI.symbol("info", size: 15, color: 0xFFB3ACA2)}
        <Spacer size={8} />
        <Text text={day.note} text_size={11.5} line_height={1.45} text_color={0xFF8A8479} weight={1.0} />
      </Row>
    </Column>
    """
  end
end
