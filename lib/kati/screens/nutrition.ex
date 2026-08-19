defmodule Kati.Screens.Nutrition do
  @moduledoc """
  Screen 47 — nutrition and adherence, pushed under Meals.

  Built to `.scratch/design/screens/47.html`. The order of the screen is its
  argument, and the design states it: *"Adherence is the number that matters,
  not calories — so it leads."* Calories get the cream hero because they are
  the number people look for; adherence gets the first count card because it
  is the number that decides whether the plan is working.

  The pixel field is deliberately the same one screens 07 and 22 draw — *"so a
  good week looks the same everywhere"* — and the target tick sits on every
  macro bar rather than only on the ones that missed, because a bar with no
  reference is a shape rather than a measurement.

  ## Where this diverges from the drawing

    * **The target tick is an offset child, not an absolute one.** The drawing
      positions it `top:-3px; left:95%` over the 8pt track. There is no
      absolute positioning here, so it is a weighted Row inside the track with
      `offset_y={-3}` — the same 95% and the same 3pt overhang either side.
    * **`4 of 5 skips` is not bold.** The drawing puts a `<strong>` run inside
      the insight sentence; a `Text` on this bridge carries one style, so the
      emphasis is lost and the sentence is intact.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"

  alias Kati.Meals.SampleNutrition, as: Sample
  alias Kati.Theme
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Nutrition.back_gap()}
        {Kati.Screens.Nutrition.header()}
        {Kati.Screens.Nutrition.segments()}
        {Kati.Screens.Nutrition.hero()}
        {Kati.Screens.Nutrition.counts()}
        {UI.eyebrow("Macros vs target")}
        {Kati.Screens.Nutrition.macros()}
        {Kati.Screens.Nutrition.muted_eyebrow("Consistency · 12 weeks")}
        {Kati.Screens.Nutrition.field()}
        {Kati.Screens.Nutrition.muted_eyebrow("What the data says")}
        {Kati.Screens.Nutrition.insight()}
      </Column>
    </Scroll>
    """
  end

  # `Kati.Screens.Pushed` floats the ‹ Meals pill over this content, and unlike
  # screens 43 and 44 nothing sits opposite it — so this is a plain reservation
  # of the drawing's 42pt pill and the 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header do
    share = {self(), :share}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Nutrition" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Meals.SampleNutrition.plan_line()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={9} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={share}
        >
          {Kati.UI.symbol("ios_share", size: 21)}
        </Box>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def segments do
    [first | rest] = Sample.segments()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={16} padding={4} align="center">
        {Kati.Screens.Nutrition.segment(first, true)}
        {Enum.map(rest, fn label -> Kati.Screens.Nutrition.segment(label, false) end)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def segment(label, on?) do
    background = if on?, do: Theme.card(:light), else: 0x00FFFFFF
    color = if on?, do: Theme.ink(), else: 0xFFAFA89E
    weight = if on?, do: "bold", else: "semibold"
    shadow = if on?, do: "0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917", else: nil

    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} height={34} corner_radius={12} background={background} shadow={shadow} align="center">
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text text={label} text_size={12.5} font_weight={weight} text_color={color} max_lines={1} />
          <Spacer weight={1.0} />
        </Row>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero do
    hero = Sample.hero()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.cream(:light)}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text text={String.upcase(hero.label)} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFB09A72} />
            <Spacer size={7} />
            <Row align="bottom">
              <Text text={hero.average} text_size={34} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} max_lines={1} />
              <Text text={hero.unit} text_size={15} font_weight="semibold" text_color={0xFFB09A72} max_lines={1} />
            </Row>
          </Column>
          <Spacer size={12} />
          <Column width={52}>
            <Text
              text={String.upcase(hero.target_label)}
              font_family="mono"
              text_size={10}
              letter_spacing={0.1}
              text_color={0xFFB09A72}
              text_align="right"
              max_lines={1}
            />
            <Spacer size={6} />
            <Text text={hero.target} text_size={15} font_weight="semibold" text_color={:on_surface} text_align="right" max_lines={1} />
          </Column>
        </Row>
        <Spacer size={18} />
        {Kati.Screens.Nutrition.chart()}
        <Spacer size={9} />
        {Kati.Screens.Nutrition.chart_labels()}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # A 64pt frame with the bars aligned to its bottom, which is what the
  # drawing's `justify-content:flex-end` inside a full-height column does.
  @doc false
  def chart do
    bars =
      Sample.bars()
      |> Enum.map(fn {_letter, height, tone} -> bar(height, tone) end)
      |> Enum.intersperse(bar_gap())

    ~MOB"""
    <Row fill_width={true} height={64} align="bottom">
      {bars}
    </Row>
    """
  end

  @doc false
  def bar_gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def bar(height, tone) do
    ~MOB"""
    <Box weight={1.0} height={height} corner_radius={5} background={tone} />
    """
  end

  @doc false
  def chart_labels do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Meals.SampleNutrition.bars(), fn {letter, _height, _tone} -> Kati.Screens.Nutrition.chart_label(letter) end)}
    </Row>
    """
  end

  @doc false
  def chart_label(letter) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer weight={1.0} />
      <Text text={letter} font_family="mono" text_size={9.5} text_color={0xFFB09A72} max_lines={1} />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc false
  def counts do
    cards =
      Sample.counts()
      |> Enum.map(fn {value, label, tone} -> count_card(value, label, tone) end)
      |> Enum.intersperse(count_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cards}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def count_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def count_card(value, label, tone) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Text text={value} text_size={24} font_weight="extrabold" letter_spacing={-0.035} text_color={tone} max_lines={1} />
        <Spacer size={5} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10}
          letter_spacing={0.1}
          text_color={0xFFA9A29A}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def macros do
    rows = Sample.macros()
    last = length(rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Nutrition.macro_row(row, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def macro_row(row, gap?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box width={7} height={7} corner_radius={2} background={row.tone} />
        <Spacer size={6} />
        <Text text={row.name} text_size={12.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
        <Spacer weight={1.0} />
        <Text text={row.value} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      </Row>
      <Spacer size={7} />
      {Kati.Screens.Nutrition.track(row)}
      {Kati.Screens.Nutrition.macro_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def macro_gap(false), do: ~MOB"<Spacer size={0} />"
  def macro_gap(true), do: ~MOB"<Spacer size={13} />"

  # Two stacked Rows inside one track: the fill, then the tick. A Box stacks
  # its children, so the tick draws over the fill rather than beside it, and
  # offset_y lifts it the 3pt the drawing gives it above the 8pt bar.
  @doc false
  def track(row) do
    ~MOB"""
    <Box fill_width={true} height={8} corner_radius={4} background={0xFFEFECE7}>
      {Kati.Screens.Nutrition.fill(row.fill, row.tone)}
      {Kati.Screens.Nutrition.tick()}
    </Box>
    """
  end

  # A full bar is drawn as a full-width Box rather than as weight 1.0 beside a
  # weight 0.0 spacer, which Compose rejects.
  @doc false
  def fill(amount, tone) when amount >= 1.0 do
    ~MOB"""
    <Box fill_width={true} height={8} corner_radius={4} background={tone} />
    """
  end

  def fill(amount, tone) do
    rest = 1.0 - amount

    ~MOB"""
    <Row fill_width={true}>
      <Box weight={amount} height={8} corner_radius={4} background={tone} />
      <Spacer weight={rest} />
    </Row>
    """
  end

  @doc false
  def tick do
    mark = Sample.target_mark()
    rest = 1.0 - mark

    ~MOB"""
    <Row fill_width={true}>
      <Spacer weight={mark} />
      <Box width={1.5} height={14} offset_y={-3} background={0x591A1917} />
      <Spacer weight={rest} />
    </Row>
    """
  end

  @doc false
  def field do
    rows = Sample.consistency() |> Enum.chunk_every(27)
    {left, right} = Sample.field_caption()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Enum.map(rows, fn row -> Kati.Screens.Nutrition.field_row(row) end)}
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Text text={left} font_family="mono" text_size={10} text_color={0xFFB3ACA2} max_lines={1} />
          <Spacer weight={1.0} />
          <Text text={right} font_family="mono" text_size={10} text_color={0xFFB3ACA2} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def field_row(row) do
    ~MOB"""
    <Column>
      <Row>
        {row |> Enum.map(&Kati.Screens.Nutrition.cell/1) |> Enum.intersperse(Kati.Screens.Nutrition.cell_gap())}
      </Row>
      <Spacer size={4} />
    </Column>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell(level) do
    tone = Sample.tone(level)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={tone} />
    """
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # Neither the field nor the insight is either, so both take #C4BDB3.
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
  def insight do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      align="top"
    >
      {Kati.UI.symbol("lightbulb", size: 19, color: Kati.Theme.accent())}
      <Spacer size={11} />
      <Text
        text={Kati.Meals.SampleNutrition.insight()}
        text_size={13}
        line_height={1.55}
        text_color={0xFF4A4238}
        weight={1.0}
      />
    </Row>
    """
  end
end
