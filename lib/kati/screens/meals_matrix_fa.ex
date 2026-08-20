defmodule Kati.Screens.MealsMatrixFa do
  @moduledoc """
  Screen 60 — برنامه هفتگی, the Persian mirror of the weekly meals matrix.

  Built to `.scratch/design/screens/60.html`. Pushed under وعده‌ها (Meals), so
  no dock and a bottom inset of **40, not 132**.

  ## The one screen mirroring alone cannot fix

  The design's own caption calls this the hardest case in the Persian pass: a
  matrix whose columns are days. Flipping the container puts Monday on the
  right and leaves the week starting on the wrong day; the *sequence* has to
  restart at شنبه. So the order comes from `Kati.Fa.SampleWeek.days/0` — a
  calendar fact — and `layout_direction="rtl"` only decides which end of the
  row the first column lands on. Get one without the other and the table is
  confidently wrong rather than obviously wrong.

  `layout_direction` is a literal rather than `Kati.Locale.direction_prop/0`
  for the same reason as `Kati.Screens.TodayFa`: the copy here is Persian, so
  the screen is right-to-left whatever the app's locale says.

  ## Where this diverges from the drawing

    * The open cell's `1.5px dashed` ring is drawn solid — `Modifier.border`
      through this bridge takes no dash pattern.

  ## The cells are square by construction, not by arithmetic

  The drawing's cell is `aspect-ratio: 1`, and so is this one:
  `fill_width` inside a weighted slot, then `aspect_ratio={1.0}`, which is the
  chain `Kati.Screens.MonthGrid` uses for the same reason. A declared height
  computed from the drawing's own 402pt frame — 360 less 28 of card padding,
  less the 66pt label column, less seven 3pt gaps, over seven columns — comes
  out at 35, and a capture on a 411dp device measured the cells 36.5 wide: the
  arithmetic of one frame does not survive the trip, and the ratio does.

  ## The segments, and why they narrow rather than replace

  هفته / روز / خرید select **which days the matrix fills**, and the selection
  is held as an *index* into `plan.segments` rather than as the Persian label,
  so no control flow on this screen depends on matching a right-to-left string.
  Index 0 — هفته — fills all seven, which is the drawing.

  Two rules shaped this:

    * **The grid does not move.** Every unfilled day keeps its slot and draws
      nothing in it, so the seven weighted columns, the 66pt label column and
      the day initials above stay exactly where the week view puts them. A
      matrix that reflows to one fat 250pt cell when you ask for one day is a
      different drawing, not the same one narrowed.
    * **No new copy.** A mirror screen exists to be compared against its
      drawing, so a segment may only re-read `Kati.Fa.SampleWeek` — it may not
      invent Persian a designer never wrote. روز is the day the matrix already
      calls today; خرید is the days after it, the ones you have still to shop
      for. Nothing else on the screen is available to say, so nothing else is
      said.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Design.Images
  alias Kati.Fa.SampleWeek
  alias Kati.Theme

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, plan: SampleWeek.plan(), view: 0)}
  end

  def render(assigns) do
    plan = assigns.plan
    view = assigns.view

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.MealsMatrixFa.header(plan)}
          {Kati.Screens.MealsMatrixFa.title(plan)}
          {Kati.Screens.MealsMatrixFa.segments(plan, view)}
          {Kati.Screens.MealsMatrixFa.matrix(plan, view)}
          {Kati.Screens.MealsMatrixFa.note(plan)}
          {Kati.Screens.MealsMatrixFa.eyebrow(plan.day_label)}
          {Kati.Screens.MealsMatrixFa.meals(plan)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  # `arrow_forward_ios`, not `arrow_back_ios_new`: back points the way the
  # reader came from, and in Persian that is rightwards.
  @doc false
  def header(plan) do
    back = {self(), :back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Theme.card(:light)}
          shadow={Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {Kati.UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          <Text
            text={plan.back}
            font_family="fa"
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Theme.card(:light)}
          shadow={Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("edit", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(plan) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={plan.title}
        font_family="fa"
        text_size={27}
        font_weight="bold"
        line_height={1.35}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text text={plan.subtitle} font_family="fa" text_size={11.5} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  # Each segment has to be a DIRECT child of the trough Row: `weight` is shared
  # out among a Row's own children, so wrapping a weighted segment in a plain
  # Row hid its weight behind a wrapper that neither filled nor weighted, and
  # that wrapper took the whole trough. The gaps are interspersed between the
  # segments instead of riding inside them, which also keeps the trough's own
  # 4pt padding from being doubled at the leading edge.
  @doc false
  def segments(plan, view) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={16} padding={4} align="center">
        {plan.segments
         |> Enum.with_index()
         |> Enum.map(fn {label, i} -> Kati.Screens.MealsMatrixFa.segment(label, i, i == view) end)
         |> Enum.intersperse(Kati.Screens.MealsMatrixFa.segment_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def segment_gap, do: ~MOB"<Spacer size={4} />"

  # The tag carries the segment's INDEX, not its label: an index is ASCII and
  # ordinal, where a Persian label would put a right-to-left string inside an
  # atom that has to survive the tap registry and the accessibility id.
  @doc false
  def segment(label, index, on?) do
    tap = {self(), String.to_atom("view_" <> Integer.to_string(index))}
    background = if on?, do: Theme.card(:light), else: 0x00FFFFFF
    color = if on?, do: Theme.ink(), else: 0xFFAFA89E
    weight = if on?, do: "bold", else: "semibold"
    shadow = if on?, do: "0 1 2 0 #0F1A1917", else: nil

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Box fill_width={true} height={34} corner_radius={12} background={background} shadow={shadow} align="center">
        <Text text={label} font_family="fa" text_size={12.5} font_weight={weight} text_color={color} max_lines={1} />
      </Box>
    </Box>
    """
  end

  @doc """
  Which day columns a segment fills, as indices into `plan.days`.

  Indices, because the segment is held as one — see the moduledoc. Every other
  column still draws its slot, so this narrows what the matrix says without
  moving anything it draws.
  """
  @spec columns(map(), non_neg_integer()) :: [non_neg_integer()]
  def columns(plan, view) do
    all = Enum.to_list(0..(length(plan.days) - 1))

    case view do
      1 -> [plan.today]
      2 -> Enum.filter(all, fn i -> i > plan.today end)
      _ -> all
    end
  end

  @doc false
  def matrix(plan, view) do
    cols = Kati.Screens.MealsMatrixFa.columns(plan, view)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={22}
        shadow={Theme.shadow_card_soft()}
        padding_left={14}
        padding_right={14}
        padding_top={16}
        padding_bottom={16}
      >
        {Kati.Screens.MealsMatrixFa.day_header(plan)}
        {Enum.map(plan.rows, fn row -> Kati.Screens.MealsMatrixFa.matrix_row(row, cols) end)}
        {Kati.Screens.MealsMatrixFa.legend(plan)}
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def day_header(plan) do
    today = plan.today

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box width={66} height={1} />
        {plan.days
         |> Enum.with_index()
         |> Enum.map(fn {day, i} -> Kati.Screens.MealsMatrixFa.day_cell(day, i == today) end)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def day_cell(day, today?) do
    color = if today?, do: 0xFF1A1917, else: 0xFFB3ACA2

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} align="center">
        <Spacer size={3} />
        <Text
          text={day}
          font_family="fa"
          text_size={11}
          font_weight="semibold"
          text_color={color}
          text_align="center"
          weight={1.0}
        />
      </Row>
    </Box>
    """
  end

  @doc false
  def matrix_row(row, cols) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column width={66}>
          <Text
            text={row.label}
            font_family="fa"
            text_size={11.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={2} />
          <Text text={row.time} font_family="mono" text_size={9.5} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        {row.cells
         |> Enum.with_index()
         |> Enum.map(fn {state, i} -> Kati.Screens.MealsMatrixFa.cell(state, i in cols) end)}
      </Row>
      <Spacer size={6} />
    </Column>
    """
  end

  # A day the segment does not cover keeps its slot and draws nothing in it —
  # that is what holds the seven columns still while the matrix narrows.
  @doc false
  def cell(_state, false) do
    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} align="center">
        <Spacer size={3} />
        <Box fill_width={true} aspect_ratio={1.0} />
      </Row>
    </Box>
    """
  end

  # The 3pt gutter rides inside each cell's slot rather than being interspersed,
  # so the seven weighted columns stay equal and line up with the header above.
  def cell(:today, true) do
    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} align="center">
        <Spacer size={3} />
        <Box fill_width={true} aspect_ratio={1.0} corner_radius={9} background={Kati.Theme.ink()} align="center">
          <Box width={7} height={7} corner_radius={4} background={Kati.Theme.accent()} />
        </Box>
      </Row>
    </Box>
    """
  end

  def cell(:open, true) do
    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} align="center">
        <Spacer size={3} />
        <Box fill_width={true} aspect_ratio={1.0} corner_radius={9} border_color={0x291A1917} border_width={1.5} />
      </Row>
    </Box>
    """
  end

  def cell(:free, true) do
    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} align="center">
        <Spacer size={3} />
        <Box fill_width={true} aspect_ratio={1.0} corner_radius={9} background={0xFFEFECE7} />
      </Row>
    </Box>
    """
  end

  def cell(_planned, true) do
    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} align="center">
        <Spacer size={3} />
        <Box fill_width={true} aspect_ratio={1.0} corner_radius={9} background={0xFFEFECE7} align="center">
          <Box width={7} height={7} corner_radius={4} background={0xFFC4BDB3} />
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def legend(plan) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={7} />
      <Box fill_width={true} height={1} background={0x121A1917} />
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {plan.legend
         |> Enum.map(fn {state, label} -> Kati.Screens.MealsMatrixFa.legend_key(state, label) end)
         |> Enum.intersperse(Kati.Screens.MealsMatrixFa.legend_gap())}
      </Row>
    </Column>
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={14} />"

  @doc false
  def legend_key(state, label) do
    ~MOB"""
    <Row align="center">
      {Kati.Screens.MealsMatrixFa.legend_dot(state)}
      <Spacer size={5} />
      <Text text={label} font_family="fa" text_size={10} text_color={0xFFA0998F} max_lines={1} />
    </Row>
    """
  end

  # `box-shadow: inset 0 0 0 1.5px #DCD7CF` on a 7pt dot is a ring, which is a
  # border here — the design's way of saying "a slot with nothing in it".
  @doc false
  def legend_dot(:open) do
    ~MOB"<Box width={7} height={7} corner_radius={4} border_color={0xFFDCD7CF} border_width={1.5} />"
  end

  def legend_dot(:today) do
    ~MOB"<Box width={7} height={7} corner_radius={4} background={0xFFE8823C} />"
  end

  def legend_dot(_planned) do
    ~MOB"<Box width={7} height={7} corner_radius={4} background={0xFFC4BDB3} />"
  end

  @doc false
  def note(plan) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={Theme.cream(:light)} corner_radius={18} padding={15} align="top">
        {Kati.UI.symbol("swap_horiz", size: 18, color: 0xFFC98A3E)}
        <Spacer size={11} />
        <Text text={plan.note} font_family="fa" text_size={12.5} line_height={1.7} text_color={0xFF4A4238} weight={1.0} />
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The section label, in Persian.

  `Kati.UI.eyebrow/2` is DM Mono, uppercased and letter-spaced; the drawing's
  Persian labels are Vazirmatn at 11 semibold with `letter-spacing:0`, because
  tracking Persian apart breaks the joins between letters. Same accent dash.
  """
  def eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Theme.accent()} />
        <Spacer size={9} />
        <Text text={label} font_family="fa" text_size={11} font_weight="semibold" text_color={0xFFA0998F} />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def meals(plan) do
    last = length(plan.meals) - 1

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
      {plan.meals
       |> Enum.with_index()
       |> Enum.map(fn {meal, i} -> Kati.Screens.MealsMatrixFa.meal_row(meal, i < last) end)}
    </Column>
    """
  end

  @doc false
  def meal_row(meal, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        {Kati.Screens.MealsMatrixFa.thumb(meal.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={meal.label} font_family="fa" text_size={10.5} font_weight="semibold" text_color={0xFFA0998F} max_lines={1} />
          <Spacer size={4} />
          <Text text={meal.title} font_family="fa" text_size={13} font_weight="semibold" text_color={:on_surface} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Text text={meal.calories} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      </Row>
      {Kati.Screens.MealsMatrixFa.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def thumb(seed) do
    case Images.poster(seed) do
      nil ->
        ~MOB"<Box width={40} height={40} corner_radius={11} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={40} corner_radius={11} content_mode="fill" />
        """
    end
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "view_" <> index ->
        {:noreply, Mob.Socket.assign(socket, :view, String.to_integer(index))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
