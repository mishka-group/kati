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

    * **The target tick is a centred child, not an absolute one.** The drawing
      positions it `top:-3px; left:95%` over the 8pt track. There is no
      absolute positioning here, so the track is a 14pt frame with the bar and
      the 14pt tick both centred inside it — the same 95% (a weighted Row) and
      the same 3pt of overhang either side, as layout rather than as an offset.
    * **`4 of 5 skips` is not bold.** The drawing puts a `<strong>` run inside
      the insight sentence; a `Text` on this bridge carries one style, so the
      emphasis is lost and the sentence is intact.

  ## The segments are the screen's one control

  Week / Month / All is a *period*, and a period that does not change the
  numbers under it is a lie the screen tells three times. So the segment owns
  everything above the consistency field — the hero average, its bar chart and
  day labels, the three count cards, and the four macro bars — and
  `period_data/1` is where a period's figures live. `"Week"` returns
  `Kati.Meals.SampleNutrition` unchanged, which is what the drawing shows and
  therefore what the resting screen must still draw.

  What the segment does **not** touch is deliberate: `Consistency · 12 weeks`
  names its own window in its own eyebrow, and the insight is a standing
  observation about Fridays. Neither is scoped to the segment, so neither moves
  when it does.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"

  alias Kati.Components.MishkaActionIcon
  alias Kati.Meals.SampleNutrition, as: Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, period: "Week")

  @doc false
  def content(assigns) do
    period = assigns.period
    data = period_data(period)

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Nutrition.back_gap()}
        {Kati.Screens.Nutrition.header()}
        {Kati.Screens.Nutrition.segments(period)}
        {Kati.Screens.Nutrition.hero(data)}
        {Kati.Screens.Nutrition.counts(data)}
        {UI.eyebrow("Macros vs target")}
        {Kati.Screens.Nutrition.macros(data)}
        {Kati.Screens.Nutrition.muted_eyebrow("Consistency · 12 weeks")}
        {Kati.Screens.Nutrition.field()}
        {Kati.Screens.Nutrition.muted_eyebrow("What the data says")}
        {Kati.Screens.Nutrition.insight()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Everything the period segment owns, for one period.

  `"Week"` is the drawing: it hands back `Kati.Meals.SampleNutrition` untouched
  so the resting screen is pixel-identical to `47.html`. The other two are the
  same four shapes at a longer scale — a monthly average slightly over the
  weekly one, four weekly bars instead of seven daily ones, counts that are the
  week's multiplied out, and macro averages that drift the way a longer window
  does.

  The bar tones are the same three verdicts `bars/0` uses — ink on target,
  `#D8D2C8` under, `#B4553C` over — so a red bar means the same thing in every
  period.

  ## Why the on-target ink is two tokens

  Three lists here write `0xFF1A1917` and they sit on two different grounds, so
  they resolve through two different `Kati.Theme.Palette` tokens. Both are
  `#1A1917` in light, so nothing moves; in dark they are ten units of blue
  apart, which is the palette's whole point.

    * `bars` are drawn inside the **cream** hero, alongside a `cream_meta`
      label and a `cream_meta` axis, so the on-target bar is `cream_ink` and
      warms to `#F7EFE4` with everything else on that card.
    * `counts` and `macros` are drawn on plain **cards**, so their on-target
      figure and dot are `ink` and go to `#F5F2EE`.

  The two verdicts either side are unambiguous: `#D8D2C8` is `bar_neutral`,
  which the palette defines as "a bar in a chart that is not the highlighted
  one" — this chart — and `#B4553C` is `red`. The macro tones are the palette's
  own chart family too: `bronze`, `bar_gold` and `bar_ink`.
  """
  @spec period_data(String.t()) :: %{
          hero: map(),
          bars: [{String.t(), pos_integer(), non_neg_integer()}],
          counts: [{String.t(), String.t(), non_neg_integer()}],
          macros: [map()]
        }
  def period_data("Month") do
    %{
      hero: %{
        label: "Daily average",
        average: "2,088",
        unit: " kcal",
        target_label: "Target",
        target: "2,100"
      },
      bars: [
        {"W1", 46, Palette.bar_neutral()},
        {"W2", 52, Palette.cream_ink()},
        {"W3", 61, Palette.red()},
        {"W4", 50, Palette.cream_ink()}
      ],
      counts: [
        {"84%", "Adherence", Palette.ink()},
        {"126", "Meals hit", Palette.ink()},
        {"24", "Skipped", Palette.red()}
      ],
      macros: [
        %{name: "Protein", value: "149 / 168 g", fill: 0.89, tone: Palette.ink()},
        %{name: "Carbs", value: "205 / 210 g", fill: 0.98, tone: Palette.bronze()},
        %{name: "Fat", value: "64 / 70 g", fill: 0.91, tone: Palette.bar_gold()},
        %{name: "Fibre", value: "27 / 35 g", fill: 0.77, tone: Palette.bar_ink()}
      ]
    }
  end

  def period_data("All") do
    %{
      hero: %{
        label: "Daily average",
        average: "2,062",
        unit: " kcal",
        target_label: "Target",
        target: "2,100"
      },
      bars: [
        {"1", 38, Palette.bar_neutral()},
        {"2", 44, Palette.bar_neutral()},
        {"3", 49, Palette.cream_ink()},
        {"4", 52, Palette.cream_ink()},
        {"5", 47, Palette.bar_neutral()},
        {"6", 51, Palette.cream_ink()},
        {"7", 58, Palette.cream_ink()},
        {"8", 62, Palette.red()},
        {"9", 55, Palette.cream_ink()},
        {"10", 43, Palette.bar_neutral()},
        {"11", 50, Palette.cream_ink()},
        {"12", 46, Palette.bar_neutral()}
      ],
      counts: [
        {"81%", "Adherence", Palette.ink()},
        {"340", "Meals hit", Palette.ink()},
        {"80", "Skipped", Palette.red()}
      ],
      macros: [
        %{name: "Protein", value: "146 / 168 g", fill: 0.87, tone: Palette.ink()},
        %{name: "Carbs", value: "212 / 210 g", fill: 1.0, tone: Palette.bronze()},
        %{name: "Fat", value: "66 / 70 g", fill: 0.94, tone: Palette.bar_gold()},
        %{name: "Fibre", value: "24 / 35 g", fill: 0.69, tone: Palette.bar_ink()}
      ]
    }
  end

  def period_data(_week) do
    %{
      hero: Sample.hero(),
      bars: Sample.bars(),
      counts: Sample.counts(),
      macros: Sample.macros()
    }
  end

  # `Kati.Screens.Pushed` floats the ‹ Meals pill over this content, and unlike
  # screens 43 and 44 nothing sits opposite it — so this is a plain reservation
  # of the drawing's 42pt pill and the 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Nutrition" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Meals.SampleNutrition.plan_line()} font_family="mono" text_size={11} text_color={Palette.muted()} max_lines={1} />
        </Column>
        <Spacer size={9} />
        {Kati.Screens.Nutrition.share_button()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # `Kati.Components.MishkaActionIcon` — an icon-only button on a raised
  # surface, which is what this is. It could not be one until the component
  # took a `shadow`: a floating disc is defined by its shadow, and `#FBFAF8` on
  # `#EFECE7` paper without one barely reads as a disc.
  #
  # `shape: :circle` computes 44 / 2 = 22.0, the radius written here before;
  # `variant: :filled` paints `background` and stops. The glyph goes in as a
  # child rather than as `icon:`, because Kati's icons are Material Symbols
  # through `Kati.UI.symbol/2` — a `Text` in the `symbols` family — not the
  # component's own `:lg` Text. A child is wrapped in a `<Row>` that hugs it,
  # inside a Box that already centred it, so the glyph does not move.
  @doc false
  def share_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: :share
      ],
      [UI.symbol("ios_share", size: 21)]
    )
  end

  # NOT `Kati.Components.MishkaSegmentedControl`, and the reason is one number.
  #
  # The control can now build everything else this strip is: the trough is
  # `background`, `corner_radius: 16` and `track_padding: 4`; a segment is
  # `segment_radius: 12`, `segment_height: 34`, `segment_weight: 1.0` and
  # `padding: 0`; the chosen one takes `color`, `text_color`, `selected_weight`
  # and `selected_shadow`, the others `label_color` and `font_weight`. Screen
  # 44's strip is that call, and is pixel-identical to what it replaced.
  #
  # What it cannot do is **put 4pt between the segments**. The drawing's track
  # is `display:flex;gap:4px` and the reason is visual rather than tidy: the
  # chosen segment is a white pill on a `#E4E0D9` trough, and with the three
  # abutting, the trough disappears between them and the pill reads as a lid on
  # the strip rather than as one of three. The component lays its segments out
  # in a bare `<Row>` with no gap and no way to intersperse one — `expand/3`
  # and `segmented_control/2` keep only children matching
  # `:mishka_segmented_control_option` and drop everything else, so a `<Spacer>`
  # written between the options never reaches the tree.
  #
  # That is the whole gap: a `segment_gap` (or a `gap` on the segments' Row —
  # `gap` is already a spacing prop the renderer resolves) would make this call
  # identical to 44's. Screen 44 differs only in that its own markup has never
  # drawn the gap its drawing also asks for, which is why the component fits
  # there today and not here.
  @doc false
  def segments(active) do
    tabs =
      Sample.segments()
      |> Enum.map(fn label -> segment(label, label == active) end)
      |> Enum.intersperse(segment_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={Palette.placeholder()} corner_radius={16} padding={4} align="center">
        {tabs}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # The selected tab's white pill has to read as one of three, not as a lid on
  # a strip: without this the three abut and the trough disappears between them.
  @doc false
  def segment_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def segment(label, on?) do
    # The tag carries the period, so one handler serves all three and a fourth
    # segment would be a change to `SampleNutrition.segments/0` alone.
    tap = {self(), String.to_atom("period_" <> label)}
    background = if on?, do: Palette.card(), else: Palette.transparent()
    color = if on?, do: Palette.ink(), else: Palette.segment_idle()
    weight = if on?, do: "bold", else: "semibold"
    shadow = if on?, do: "0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917", else: nil

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        height={34}
        corner_radius={12}
        background={background}
        shadow={shadow}
        align="center"
        on_tap={tap}
      >
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
  def hero(data) do
    hero = data.hero
    bars = data.bars

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text text={String.upcase(hero.label)} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={Palette.cream_meta()} />
            <Spacer size={7} />
            {Kati.Screens.Nutrition.average_figure(hero)}
          </Column>
          <Spacer size={12} />
          <Column width={52}>
            <Text
              text={String.upcase(hero.target_label)}
              font_family="mono"
              text_size={10}
              letter_spacing={0.1}
              text_color={Palette.cream_meta()}
              text_align="right"
              max_lines={1}
            />
            <Spacer size={6} />
            <Text text={hero.target} text_size={15} font_weight="semibold" text_color={:on_surface} text_align="right" max_lines={1} />
          </Column>
        </Row>
        <Spacer size={18} />
        {Kati.Screens.Nutrition.chart(bars)}
        <Spacer size={9} />
        {Kati.Screens.Nutrition.chart_labels(bars)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # `2,040` and ` kcal` are one inline run in the drawing, so they share a
  # baseline. `align="bottom"` aligns the two text *boxes*, and a 34pt box
  # carries more descent than a 15pt one, so the unit sank below the figure —
  # a capture measured it 3.8pt low. The lift is that descent difference,
  # 0.2 × (34 − 15) = 3.8, applied by `Kati.UI.number_with_unit/3`.
  @doc false
  def average_figure(hero) do
    number = ~MOB"""
    <Text text={hero.average} text_size={34} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} max_lines={1} />
    """

    unit = ~MOB"""
    <Text text={hero.unit} text_size={15} font_weight="semibold" text_color={Palette.cream_meta()} max_lines={1} />
    """

    UI.number_with_unit(number, unit, 3.8)
  end

  # A 64pt frame with the bars aligned to its bottom, which is what the
  # drawing's `justify-content:flex-end` inside a full-height column does.
  @doc false
  def chart(bars) do
    columns =
      bars
      |> Enum.map(fn {_letter, height, tone} -> bar(height, tone) end)
      |> Enum.intersperse(bar_gap())

    ~MOB"""
    <Row fill_width={true} height={64} align="bottom">
      {columns}
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
  def chart_labels(bars) do
    labels = Enum.map(bars, fn {letter, _height, _tone} -> chart_label(letter) end)

    ~MOB"""
    <Row fill_width={true} align="center">
      {labels}
    </Row>
    """
  end

  @doc false
  def chart_label(letter) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer weight={1.0} />
      <Text text={letter} font_family="mono" text_size={9.5} text_color={Palette.cream_meta()} max_lines={1} />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc false
  def counts(data) do
    cards =
      data.counts
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
        background={Palette.card()}
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
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def macros(data) do
    rows = data.macros
    last = length(rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
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
        <Text text={row.value} font_family="mono" text_size={11} text_color={Palette.muted()} max_lines={1} />
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

  # A 14pt frame holding two centred layers: the 8pt bar, and the 14pt tick
  # over it. The frame is what gives the tick its 3pt of overhang either side —
  # a taller child is not clipped by a Box, but it *is* clipped by the 8pt
  # track's own corner_radius, which is where the tick lost 9 of its 14 points
  # and rendered as a stub. Centring both in 14 draws the drawing's
  # `top:-3px` as real space rather than as an offset out of a mask.
  @doc false
  def track(row) do
    ~MOB"""
    <Box fill_width={true} height={14} align="center">
      <Box fill_width={true} height={8} corner_radius={4} background={Palette.paper()}>
        {Kati.Screens.Nutrition.fill(row.fill, row.tone)}
      </Box>
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

  # The tick is `0x591A1917`, and `divider_heavy` is the only token whose light
  # value is that — the palette named it for the 35% vertical rule it draws
  # between two numbers, which is the same ink tint at the same alpha and the
  # same 1.5pt width, put to a different use. Taking it keeps the tick on the
  # ink-tint ladder, so in dark it becomes 35% of `#F5F2EE` and stays a mark ON
  # the bar; left as `0x591A1917` it would be 35% black over a `#1E1D1B` card
  # and the target would silently stop being drawn.
  @doc false
  def tick do
    mark = Sample.target_mark()
    rest = 1.0 - mark

    ~MOB"""
    <Row fill_width={true}>
      <Spacer weight={mark} />
      <Box width={1.5} height={14} background={Palette.divider_heavy()} />
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
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Enum.map(rows, fn row -> Kati.Screens.Nutrition.field_row(row) end)}
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Text text={left} font_family="mono" text_size={10} text_color={Palette.tertiary()} max_lines={1} />
          <Spacer weight={1.0} />
          <Text text={right} font_family="mono" text_size={10} text_color={Palette.tertiary()} max_lines={1} />
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
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # `cream_body` on a card, which reads as a contradiction and is not one:
  # `0xFF4A4238` appears exactly once in the palette's light column and that is
  # the token. The design uses its warmest body ink for the one paragraph on
  # this screen meant to be READ rather than counted, and puts it on a white
  # card rather than on cream. In dark it becomes `#E4DBCE` — warm off-white on
  # `#1E1D1B`, which keeps the sentence reading warmer than the figures around
  # it, which is what the light drawing does too.
  @doc false
  def insight do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      align="top"
    >
      {Kati.UI.symbol("lightbulb", size: 19, color: Palette.accent())}
      <Spacer size={11} />
      <Text
        text={Kati.Meals.SampleNutrition.insight()}
        text_size={13}
        line_height={1.55}
        text_color={Palette.cream_body()}
        weight={1.0}
      />
    </Row>
    """
  end

  # One clause for all three segments: the tag carries the period, so the
  # handler never learns their names. `:share` falls through deliberately —
  # the disc is drawn and its sheet is not this screen's to open.
  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "period_" <> label -> {:noreply, Mob.Socket.assign(socket, :period, label)}
      _ -> {:noreply, socket}
    end
  end
end
