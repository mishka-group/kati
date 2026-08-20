defmodule Kati.Screens.MealsToday do
  @moduledoc """
  Screen 43 — Today, pushed under Health.

  Built to `.scratch/design/screens/43.html`. The design's own caption says
  what this screen is: *"The day reads like the schedule screen because it is
  the same component: time gutter, one card per item, the next one lifted."*
  So the 44pt time column, the card per meal and the lift on the next thing
  are not choices made here — they are screen 02's, reused, which is the whole
  argument for meals not needing a lane of their own.

  Three states are drawn, and they are genuinely different cards rather than
  one card with a flag:

    * `:eaten` — flat `#F4F1EC`, no shadow, text dropped to `#9C958B`, and a
      filled green ring. It is done; it should stop asking for attention.
    * `:skipped` — no photograph at all, an outline instead of a fill, and
      `SKIPPED` where the calories were. A skipped meal has no calories, so
      showing a number would be a lie.
    * `:next` — lifted on the day's heaviest shadow, a 3pt accent rule, a
      larger photograph, and its three actions inline.

  ## Where this diverges from the drawing

    * **The dashed outline on the skipped card is solid.** `1.5px dashed
      rgba(26,25,23,.14)` has no dashed equivalent on this bridge, so it is a
      1.5pt solid edge at the same colour — the same trade `Kati.Screens.Health`
      records for its unbuilt tiles.
    * **The next card's 3pt rule is a declared 52pt.** It is `align-self:
      stretch` in the drawing; nothing measures geometry here, and 52 is the
      photograph's height, which is what sets the row's height.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Health"

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Meals.SampleToday, as: Sample
  alias Kati.Theme
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.MealsToday.header()}
        {Kati.Screens.MealsToday.title()}
        {Kati.Screens.MealsToday.week_strip()}
        {Kati.Screens.MealsToday.tiles()}
        {UI.eyebrow(Sample.intake_line())}
        {Kati.Screens.MealsToday.macro_card()}
        {Kati.Screens.MealsToday.timeline()}
        {UI.eyebrow("Tomorrow — needs prep tonight")}
        {Kati.Screens.MealsToday.prep()}
      </Column>
    </Scroll>
    """
  end

  # `Kati.Screens.Pushed` floats the ‹ Health pill over this content. This row
  # reserves its height and carries the week button opposite it.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.MealsToday.week_button()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  # `Kati.Components.MishkaActionIcon` — an icon-only button on a raised
  # surface, which is what this is. It could not be one until the component
  # took a `shadow`: a floating disc is DEFINED by its shadow, and a
  # `variant: :filled` without one is a flat patch of `#FBFAF8` on `#EFECE7`
  # paper, which is nearly the same colour.
  #
  # `shape: :circle` is an exact `size / 2` — 44 gives the 22 written here
  # before. The glyph is a child rather than `icon:` because Kati's icons are
  # Material Symbols through `Kati.UI.symbol/2`, a `Text` in the `symbols`
  # family, not the component's own `:lg` Text. A child is wrapped in a `<Row>`
  # that hugs it, inside a Box that already centred it, so the glyph does not
  # move.
  @doc false
  def week_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Theme.card(:light),
        shadow: Theme.shadow_button(),
        on_tap: :open_week
      ],
      [UI.symbol("calendar_view_week", size: 21)]
    )
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="bottom">
        <Column weight={1.0}>
          <Text text="Today" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Meals.SampleToday.day_line()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.MealsToday.plan_pill()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Orange here is the plan that is running *now*, which is the one meaning the
  # accent is allowed to carry.
  @doc false
  def plan_pill do
    tap = {self(), :switch_plan}

    ~MOB"""
    <Row
      height={36}
      corner_radius={18}
      background={Kati.Theme.card(:light)}
      shadow={Kati.Theme.shadow_button()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Box width={7} height={7} corner_radius={4} background={Kati.Theme.accent()} />
      <Spacer size={7} />
      <Text text={Kati.Meals.SampleToday.plan()} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={7} />
      {Kati.UI.symbol("unfold_more", size: 16, color: 0xFF8A8479)}
    </Row>
    """
  end

  @doc false
  def week_strip do
    cells =
      Sample.week()
      |> Enum.map(&day_cell/1)
      |> Enum.intersperse(day_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cells}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def day_gap, do: ~MOB"<Spacer size={2} />"

  # Centring is done with weighted spacers inside full-width Rows, not with
  # text_align: a Text given text_align fills its parent's width on this
  # bridge, which is exactly what a flex-1 cell must not let it do.
  @doc false
  def day_cell(day) do
    background = if day.today?, do: Theme.card(:light), else: 0x00FFFFFF
    shadow = if day.today?, do: Theme.shadow_button(), else: nil
    dow_color = if day.today?, do: 0xFF8A8479, else: 0xFFB3ACA2
    day_color = if day.today?, do: Theme.ink(), else: 0xFF8A8479

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        corner_radius={16}
        background={background}
        shadow={shadow}
        padding_top={9}
        padding_bottom={10}
        align="center"
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text text={day.dow} font_family="mono" text_size={10} text_color={dow_color} max_lines={1} />
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={4} />
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text text={day.day} text_size={15} font_weight="bold" text_color={day_color} max_lines={1} />
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={6} />
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            {day.dots |> Enum.map(&Kati.Screens.MealsToday.pip/1) |> Enum.intersperse(Kati.Screens.MealsToday.pip_gap())}
            <Spacer weight={1.0} />
          </Row>
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def pip_gap, do: ~MOB"<Spacer size={1.5} />"

  @doc false
  def pip(color) do
    ~MOB"""
    <Box width={3} height={3} corner_radius={2} background={color} />
    """
  end

  @doc false
  def tiles do
    tiles =
      Sample.tiles()
      |> Enum.map(fn {icon, label} -> tile(icon, label) end)
      |> Enum.intersperse(tile_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={8} />"

  @doc false
  def tile(icon, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={8}
        padding_right={8}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol(icon, size: 18)}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={7} />
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text text={label} text_size={11} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
            <Spacer weight={1.0} />
          </Row>
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def macro_card do
    macros = Sample.macros()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Box fill_width={true} height={9} corner_radius={4.5} background={0xFFEFECE7}>
          <Row fill_width={true}>
            {Enum.map(macros, fn {_name, share, tone} -> Kati.Screens.MealsToday.segment(share, tone) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {macros |> Enum.map(fn {name, _share, tone} -> Kati.Screens.MealsToday.legend_key(name, tone) end) |> Enum.intersperse(Kati.Screens.MealsToday.legend_gap())}
          <Spacer weight={1.0} />
          <Text text={Kati.Meals.SampleToday.remaining()} font_family="mono" text_size={10} text_color={0xFFA9A29A} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # The drawing rounds the bar's ends with `overflow:hidden`. Mob does not clip
  # children, so the segments stay square inside a rounded track and the ink
  # one overhangs the 4.5pt corner by a hair — the same compromise screen 42
  # records, and preferable to per-segment radii, which open visible notches.
  #
  # Still hand-rolled for the reason `Kati.Screens.Health.macro_bar/1` sets out
  # at length: `Kati.Components.MishkaMeter` draws ONE fill in ONE colour over a
  # track, and this is three fills in three colours filling the track between
  # them. Its `render={:box}` mode has no segmented form and forwards no
  # `weight`, so neither the bar nor any single segment of it can be a meter.
  # 42 and 43 draw the same bar and want the same upstream change.
  @doc false
  def segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={9} background={tone} />
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def legend_key(name, tone) do
    ~MOB"""
    <Row align="center">
      <Box width={7} height={7} corner_radius={2} background={tone} />
      <Spacer size={5} />
      <Text
        text={String.upcase(name)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.08}
        text_color={0xFFA0998F}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def timeline do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(Kati.Meals.SampleToday.meals(), fn meal -> Kati.Screens.MealsToday.meal_row(meal) end)}
    </Column>
    """
  end

  @doc false
  def meal_row(meal) do
    gutter_top = if meal.state == :next, do: 17, else: 15
    gutter_color = if meal.state == :next, do: Theme.ink(), else: 0xFFA9A29A
    gutter_weight = if meal.state == :next, do: "medium", else: "regular"

    tap = {self(), :open_meal}

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={gutter_top}>
          <Text text={meal.time} font_family="mono" text_size={12} font_weight={gutter_weight} text_color={gutter_color} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          {Kati.Screens.MealsToday.meal_card(meal)}
        </Box>
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def meal_card(%{state: :eaten} = meal) do
    ~MOB"""
    <Row
      fill_width={true}
      background={0xFFF4F1EC}
      corner_radius={18}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      {Kati.Screens.MealsToday.thumb(meal.seed, 40, 11)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={String.upcase(meal.slot)} font_family="mono" text_size={9.5} letter_spacing={0.14} text_color={0xFFA0998F} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.title} text_size={13.5} font_weight="semibold" letter_spacing={-0.015} text_color={0xFF9C958B} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.calories} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box
        width={27}
        height={27}
        corner_radius={16}
        background={0xFF4E9A73}
        border_width={1.5}
        border_color={0xFF4E9A73}
        align="center"
      >
        {Kati.UI.symbol("check", size: 16, color: 0xFFFBFAF8)}
      </Box>
    </Row>
    """
  end

  # No photograph, no fill: a skipped meal is an outline of the meal that was
  # planned. The drawing dashes that outline and this bridge cannot.
  def meal_card(%{state: :skipped} = meal) do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={0x241A1917}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      <Column weight={1.0}>
        <Text text={String.upcase(meal.slot)} font_family="mono" text_size={9.5} letter_spacing={0.14} text_color={0xFFC4BDB3} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.title} text_size={13.5} font_weight="semibold" letter_spacing={-0.015} text_color={0xFFB3ACA2} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.calories} font_family="mono" text_size={10.5} text_color={0xFFC4BDB3} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box width={27} height={27} corner_radius={16} border_width={1.5} border_color={0x291A1917} align="center">
        {Kati.UI.symbol("close", size: 16, color: 0xFFC4BDB3)}
      </Box>
    </Row>
    """
  end

  def meal_card(%{state: :next} = meal) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={18}
      shadow="0 1 2 0 #0D1A1917 | 0 16 30 -18 #BF1A1917"
      padding={14}
    >
      <Row fill_width={true} align="center">
        <Box width={3} height={52} corner_radius={2} background={Kati.Theme.accent()} />
        <Spacer size={12} />
        {Kati.Screens.MealsToday.thumb(meal.seed, 52, 13)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={String.upcase(meal.slot)} font_family="mono" text_size={9.5} letter_spacing={0.14} text_color={0xFFA0998F} max_lines={1} />
          <Spacer size={4} />
          <Text text={meal.title} text_size={15} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={meal.calories} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box width={32} height={32} corner_radius={16} border_width={1.5} border_color={0x291A1917} align="center">
          {Kati.UI.symbol("check", size: 19, color: 0x381A1917)}
        </Box>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} padding_left={15} align="center">
        {Kati.Screens.MealsToday.action("Mark eaten", :ink, :mark_eaten)}
        <Spacer size={8} />
        {Kati.Screens.MealsToday.action("Swap", :paper, :swap)}
        <Spacer size={8} />
        {Kati.Screens.MealsToday.overflow()}
      </Row>
    </Column>
    """
  end

  # The third action is a disc rather than a label, so it is the icon-only
  # button component. No `shadow` here — the drawing gives this one none, it
  # sits inside the lifted card rather than on the paper — and `variant:
  # :filled` on its own is exactly the `background` + `corner_radius` box it
  # replaces. `shape: :circle` computes 34 / 2 = 17.0, the radius written
  # before. It carries no handler, and passing no `on_tap` wires none.
  @doc false
  def overflow do
    MishkaActionIcon.action_icon(
      [size: 34, shape: :circle, variant: :filled, background: 0xFFEFECE7],
      [UI.symbol("more_horiz", size: 17, color: 0xFF5C574F)]
    )
  end

  # `Kati.Components.MishkaPill`: a compact label with a tap and no selected
  # state, which is the port's own dividing line — "a Chip is selected, a Pill
  # is removed… if you find yourself giving a pill a checked state, you want
  # Chip". These never carry one, so they are pills.
  #
  # Pixel-for-pixel the same node, one wrapper deeper. Before: a hugging `Row`
  # with the fill, the radius, 14 of horizontal padding and a 34 height, around
  # one `Text`. Now: a `Box fill_width={false}` carrying that same fill, radius,
  # padding and height, around a `Row` holding the `Text` and the empty `Row`
  # the unused remove-slot leaves behind — which measures 0x0 and adds nothing
  # to the line.
  #
  # The four padding edges are all named, so the component's `:space_sm`
  # default is inert: `nodeModifier/1` reads the uniform value only for an edge
  # that is missing. `padding_top`/`padding_bottom` of 0 are what the Row got
  # by having no vertical padding at all, and 0 pins the outer height at 34,
  # since the bridge pads before it sizes.
  #
  # `align: :center` replaces the Row's `align="center"`: a Box centres its
  # content in both axes, and horizontally the content box is exactly the
  # Text's width, so only the vertical half of that does anything — which is
  # what `CenterVertically` was doing.
  @doc false
  def action(label, tone, tag) do
    background = if tone == :ink, do: Theme.ink(), else: 0xFFEFECE7
    color = if tone == :ink, do: 0xFFFBFAF8, else: 0xFF5C574F

    MishkaPill.pill(
      label: label,
      background: background,
      color: color,
      corner_radius: 17,
      height: 34,
      padding_left: 14,
      padding_right: 14,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: tag
    )
  end

  @doc false
  def thumb(seed, size, radius) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"""
        <Box width={size} height={size} corner_radius={radius} background={0xFFE4E0D9} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={size} height={size} corner_radius={radius} content_mode="fill" />
        """
    end
  end

  @doc false
  def prep do
    prep = Sample.prep()

    ~MOB"""
    <Column fill_width={true} background={Kati.Theme.cream(:light)} corner_radius={20} padding={16}>
      <Row fill_width={true} align="center">
        {Kati.UI.symbol("schedule", size: 20, color: 0xFFC98A3E)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={prep.title} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={prep.line} text_size={11.5} text_color={0xFF8A7B60} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {Kati.Screens.MealsToday.action(prep.primary, :ink, :see_tomorrow)}
        <Spacer size={8} />
        {Kati.Screens.MealsToday.prep_secondary(prep.secondary)}
      </Row>
    </Column>
    """
  end

  # `rgba(255,255,255,.6)` on cream, which is a lighter cream rather than a
  # grey — so it stays a white at 60% alpha instead of being flattened.
  #
  # The same pill as `action/3`, and it does not call it only because its fill
  # and ink are neither of that function's two tones.
  @doc false
  def prep_secondary(label) do
    MishkaPill.pill(
      label: label,
      background: 0x99FFFFFF,
      color: 0xFF8A7B60,
      corner_radius: 17,
      height: 34,
      padding_left: 14,
      padding_right: 14,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: :done_prepping
    )
  end

  @impl true
  def handle_tap(:open_meal, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Meal)}
  def handle_tap(:open_plan, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealPlan)}
  def handle_tap(:open_shopping, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Shopping)}
  def handle_tap(:open_nutrition, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Nutrition)}
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
