defmodule Kati.Screens.MealPlan do
  @moduledoc """
  Screen 44 — the repeating week, pushed under Meals.

  Built to `.scratch/design/screens/44.html`. The design's caption states both
  the layout and the domain rule behind it: *"Five slots × seven days as a
  matrix — too narrow for names, so cells carry state only and the tapped day
  lists underneath, exactly like the week calendar. The plan is a rule, not 52
  copies."*

  So the matrix is deliberately dumb. A cell says planned / free / not-in-the-
  plan and nothing more, and the names live in the list below it — the same
  split screen 17 makes between the week grid and the day it expands.

  ## Where this diverges from the drawing

    * **The cells are a declared 37pt square.** They are `flex:1` with
      `aspect-ratio:1` in the drawing, and nothing measures geometry on this
      bridge, so the height has to be declared. The arithmetic is done against
      the device, not the 402pt frame, because the width is fluid and the
      height is not: 411 less the 21pt gutters, less the card's 14pt padding
      either side, less the 62pt label column and seven 3pt gaps, is 258 across
      seven cells — 36.9 each. A capture measured 36.5 against a declared 35,
      which read as a wide cell rather than a square one.
    * **The unplanned Sunday snack is a solid outline.** `1.5px dashed
      rgba(26,25,23,.16)` has no dashed equivalent here, so it is solid at the
      same weight and colour.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"

  alias Kati.Meals.SamplePlan, as: Sample
  alias Kati.Theme
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.MealPlan.header()}
        {Kati.Screens.MealPlan.title()}
        {Kati.Screens.MealPlan.segments()}
        {Kati.Screens.MealPlan.matrix()}
        {UI.eyebrow(Sample.day_line())}
        {Kati.Screens.MealPlan.day_list()}
        {Kati.Screens.MealPlan.muted_eyebrow("Repeat rule")}
        {Kati.Screens.MealPlan.repeat_rule()}
      </Column>
    </Scroll>
    """
  end

  # `Kati.Screens.Pushed` floats the ‹ Meals pill over this content. This row
  # reserves its height and carries the edit button opposite it.
  @doc false
  def header do
    tap = {self(), :edit_plan}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={tap}
        >
          {Kati.UI.symbol("edit", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={Kati.Meals.SamplePlan.title()} text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} max_lines={1} />
      <Spacer size={5} />
      <Text text={Kati.Meals.SamplePlan.subtitle()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
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
        {Kati.Screens.MealPlan.segment(first, true)}
        {Enum.map(rest, fn label -> Kati.Screens.MealPlan.segment(label, false) end)}
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
  def matrix do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={14}
        padding_right={14}
        padding_top={16}
        padding_bottom={16}
      >
        {Kati.Screens.MealPlan.column_heads()}
        {Enum.map(Kati.Meals.SamplePlan.matrix(), fn row -> Kati.Screens.MealPlan.matrix_row(row) end)}
        {Kati.Screens.MealPlan.legend()}
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  # The last column is inked because Sunday is the day the list below shows.
  #
  # The 62pt lead is `width`, not `size`: `size` sets both axes, and a 62pt tall
  # spacer would give the header row 62pt of height for a 10pt letter.
  @doc false
  def column_heads do
    columns = Sample.columns()
    last = length(columns) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box width={62} height={12} />
        {columns
         |> Enum.with_index()
         |> Enum.map(fn {letter, i} -> Kati.Screens.MealPlan.column_head(letter, i == last) end)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def column_head(letter, on?) do
    color = if on?, do: Theme.ink(), else: 0xFFB3ACA2

    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer size={3} />
      <Spacer weight={1.0} />
      <Text text={letter} font_family="mono" text_size={10} text_color={color} max_lines={1} />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc false
  def matrix_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column width={62}>
          <Text text={row.name} text_size={11.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={2} />
          <Text text={row.time} font_family="mono" text_size={9.5} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        {Enum.map(row.cells, fn state -> Kati.Screens.MealPlan.cell(state) end)}
      </Row>
      <Spacer size={6} />
    </Column>
    """
  end

  # The 3pt gap rides inside the cell rather than being interspersed, so the
  # label column gets one too — which is what `display:flex;gap:3px` does when
  # the label is the first child.
  @doc false
  def cell(state) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer size={3} />
      <Box weight={1.0} height={37} corner_radius={9} background={Kati.Screens.MealPlan.cell_fill(state)} border_width={Kati.Screens.MealPlan.cell_border(state)} border_color={0x291A1917} align="center">
        {Kati.Screens.MealPlan.pip(state)}
      </Box>
    </Row>
    """
  end

  @doc false
  def cell_fill(:today), do: Theme.ink()
  def cell_fill(:open), do: 0x00FFFFFF
  def cell_fill(_), do: 0xFFEFECE7

  @doc false
  def cell_border(:open), do: 1.5
  def cell_border(_), do: 0

  @doc false
  def pip(:planned) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={0xFFC4BDB3} />
    """
  end

  def pip(:today) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={Kati.Theme.accent()} />
    """
  end

  def pip(_), do: ~MOB"<Spacer size={0} />"

  @doc false
  def legend do
    keys =
      Sample.legend()
      |> Enum.map(fn {label, state} -> legend_key(label, state) end)
      |> Enum.intersperse(legend_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={7} />
      <Box fill_width={true} height={1} background={0x121A1917} />
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {keys}
      </Row>
    </Column>
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={14} />"

  # `Free` is a ring rather than a fill — `box-shadow: inset 0 0 0 1.5px` in
  # the drawing, which is a border by another name.
  @doc false
  def legend_key(label, state) do
    ~MOB"""
    <Row align="center">
      {Kati.Screens.MealPlan.legend_swatch(state)}
      <Spacer size={5} />
      <Text
        text={String.upcase(label)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.06}
        text_color={0xFFA0998F}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def legend_swatch(:planned) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={0xFFC4BDB3} />
    """
  end

  def legend_swatch(:today) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={Kati.Theme.accent()} />
    """
  end

  def legend_swatch(_) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} border_width={1.5} border_color={0xFFDCD7CF} />
    """
  end

  @doc false
  def day_list do
    rows = Sample.day()
    last = length(rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.MealPlan.day_row(row, i < last) end)}
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def day_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        {Kati.Screens.MealPlan.thumb(row.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={String.upcase(row.slot)} font_family="mono" text_size={9.5} letter_spacing={0.14} text_color={0xFFA0998F} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Text text={row.calories} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      </Row>
      {Kati.Screens.MealPlan.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def thumb(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={40} height={40} corner_radius={11} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={40} corner_radius={11} content_mode="fill" />
        """
    end
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # The repeat rule is neither, so the drawing gives it a #C4BDB3 dash.
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
  def repeat_rule do
    rows = Sample.repeat_rule()
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.MealPlan.rule_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def rule_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Box width={30} height={30} corner_radius={9} background={0xFFEFECE7} align="center">
          {Kati.UI.symbol(row.icon, size: 17, color: 0xFF5C574F)}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.MealPlan.trailing(row.trailing)}
      </Row>
      {Kati.Screens.MealPlan.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def trailing(:chevron), do: Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)

  # 46x28 with a 22pt knob inset 3pt, drawn the way
  # `Kati.Screens.Accessibility.toggle/1` draws it: the inset comes from a 40pt
  # inner Row, not from `padding`, because this bridge applies padding outside
  # an explicit width — `width={46} padding={3}` renders 52x34, not 46x28.
  # The knob leads and the space trails, which is the off state.
  def trailing(:switch_off) do
    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={0xFFDCD7CF} align="center">
      <Row width={40} align="center">
        <Box width={22} height={22} corner_radius={11} background={Kati.Theme.card(:light)} shadow="0 1 3 0 #4D1A1917" />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  @impl true
  def handle_tap(:edit_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Plans)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
