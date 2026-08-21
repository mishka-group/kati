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
  alias Kati.Theme.Palette
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
        # `card`, not `on_ink` / `fab_glyph` / `on_media` — the other three
        # meanings `Kati.Theme.Palette` gives `0xFFFBFAF8`. A floating disc is a
        # surface above the page, so it follows the ground into `#1E1D1B`.
        background: Palette.card(),
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
          <Text text={Kati.Meals.SampleToday.day_line()} font_family="mono" text_size={11} text_color={Palette.muted()} max_lines={1} />
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
      background={Palette.card()}
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
      {Kati.UI.symbol("unfold_more", size: 16, color: Palette.sub())}
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
    # `transparent`, not `card_hairline` / `cream_hairline` — the other two
    # tokens that are `0x00FFFFFF` in light. Those two are hairlines dark ADDS;
    # this is a cell the drawing simply does not fill, and it stays unfilled in
    # both modes. `day_color` is `ink` rather than `ink_fill`: it is the day
    # number as text on a card, not a control filled with ink.
    background = if day.today?, do: Palette.card(), else: Palette.transparent()
    shadow = if day.today?, do: Theme.shadow_button(), else: nil
    dow_color = if day.today?, do: Palette.sub(), else: Palette.tertiary()
    day_color = if day.today?, do: Palette.ink(), else: Palette.sub()

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

  @doc """
  Where each quick tile goes, keyed by its **icon** rather than its label.

  The icon is a Material Symbols identifier and is never translated; the label
  is display text and one day will be. Keying on the label would wire four
  live controls in English and four dead ones in every other locale, and the
  failure would be invisible — an unknown key yields no `on_tap`, and a Box
  with no `on_tap` is drawn exactly like one that has it.

  The four destinations are the four screens whose own drawing carries a
  `‹ Meals` back pill, which is what identifies them as the places Meals goes:
  44 the repeating week, 48 Shopping, 47 Nutrition, 49 Plans. `tune` is the
  odd one only until you read 49 — a plan owns its meals, its targets and its
  reminder times, so "Plan" is the profile you pick, not the week you look at.
  """
  @tile_taps %{
    "calendar_view_week" => :open_week,
    "shopping_cart" => :open_shopping,
    "monitoring" => :open_nutrition,
    "tune" => :open_plan
  }

  @spec tile_taps() :: %{String.t() => atom()}
  def tile_taps, do: @tile_taps

  # Nothing here changes a resting pixel: the four tiles were already drawn
  # exactly like this, and `on_tap` adds a click target, not ink. What it fixes
  # is that three of the four destinations below already had a `handle_tap/2`
  # clause and no control ever sent the tag — `Kati.Screens.MealPlan`,
  # `Kati.Screens.Shopping` and `Kati.Screens.Nutrition` were reachable only
  # from `Kati.Screens.Gallery`, and the tiles that name them did nothing.
  @doc false
  def tile(icon, label) do
    # `Map.fetch!`, not `Map.get`: an icon with no entry would otherwise yield
    # `on_tap={nil}`, which the bridge drops without a word and draws as a tile
    # that looks identical and answers nothing. A raise here is caught by the
    # render sweep long before a device sees it.
    tap = {self(), Map.fetch!(@tile_taps, icon)}

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        background={Palette.card()}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={8}
        padding_right={8}
        padding_top={11}
        padding_bottom={11}
        align="center"
        on_tap={tap}
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
            <Text text={label} text_size={11} font_weight="semibold" text_color={Palette.ink_soft()} max_lines={1} />
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
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Box fill_width={true} height={9} corner_radius={4.5} background={Palette.paper()}>
          <Row fill_width={true}>
            {Enum.map(macros, fn {_name, share, tone} -> Kati.Screens.MealsToday.segment(share, tone) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {macros |> Enum.map(fn {name, _share, tone} -> Kati.Screens.MealsToday.legend_key(name, tone) end) |> Enum.intersperse(Kati.Screens.MealsToday.legend_gap())}
          <Spacer weight={1.0} />
          <Text text={Kati.Meals.SampleToday.remaining()} font_family="mono" text_size={10} text_color={Palette.muted()} max_lines={1} />
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
        text_color={Palette.eyebrow()}
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
    # `ink`, not `ink_fill`: the time is text on the page, not a filled control.
    gutter_color = if meal.state == :next, do: Palette.ink(), else: Palette.muted()
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

  # The tick sits on a GREEN disc, and the green is a hue: it does not move with
  # the mode. So `0xFFFBFAF8` is LEFT AS A LITERAL below — see the comment there.
  @doc false
  def meal_card(%{state: :eaten} = meal) do
    # `0xFFFBFAF8` LEFT AS A LITERAL. `Kati.Theme.Palette` names four meanings
    # for this value — the card, a label on an ink fill, the FAB's plus, and a
    # title over artwork — and this is none of them: it is a glyph on a HUE.
    # `green` is `:hue`, unchanged in dark, so a tick that took `on_ink` would
    # turn to ink on a disc that never darkened. The two tokens that keep the
    # value in dark are scoped to a photographic ground (`on_media`) or to the
    # FAB, so neither is honestly this. The table has no "on a hue fill" row;
    # `Kati.Screens.Habits.today_button/2` leaves the same value for the same
    # reason.
    tick = 0xFFFBFAF8

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card_settled()}
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
        <Text text={String.upcase(meal.slot)} font_family="mono" text_size={9.5} letter_spacing={0.14} text_color={Palette.eyebrow()} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.title} text_size={13.5} font_weight="semibold" letter_spacing={-0.015} text_color={Palette.settled_ink()} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.calories} font_family="mono" text_size={10.5} text_color={Palette.muted()} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box
        width={27}
        height={27}
        corner_radius={16}
        background={Palette.green()}
        border_width={1.5}
        border_color={Palette.green()}
        align="center"
      >
        {Kati.UI.symbol("check", size: 16, color: tick)}
      </Box>
    </Row>
    """
  end

  # No photograph, no fill: a skipped meal is an outline of the meal that was
  # planned. The drawing dashes that outline and this bridge cannot.
  #
  # Its three faint marks are `rail_idle` for their VALUE, not their name: the
  # token whose meaning is "a faint chevron / an idle glyph" is `tertiary`, and
  # its light value is `0xFFB3ACA2` where these are `0xFFC4BDB3`. The design
  # draws two faint greys and only one of them is `tertiary`. Taking the better
  # name would move light mode eleven units, so the value wins — the same trade
  # `Kati.UI.SettingsList.chevron/0` records.
  def meal_card(%{state: :skipped} = meal) do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border_soft()}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      <Column weight={1.0}>
        <Text text={String.upcase(meal.slot)} font_family="mono" text_size={9.5} letter_spacing={0.14} text_color={Palette.rail_idle()} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.title} text_size={13.5} font_weight="semibold" letter_spacing={-0.015} text_color={Palette.tertiary()} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.calories} font_family="mono" text_size={10.5} text_color={Palette.rail_idle()} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box width={27} height={27} corner_radius={16} border_width={1.5} border_color={Palette.border()} align="center">
        {Kati.UI.symbol("close", size: 16, color: Palette.rail_idle())}
      </Box>
    </Row>
    """
  end

  # The empty tick in the ring is `track_ink` — right by value, and the one part
  # of the name that is wrong. `0x381A1917` has exactly one row in
  # `Kati.Theme.Palette` and it is called a track because that is where the
  # design's other 22% ink appears; what matters is that it is the same ink-tint
  # ladder the ring's own `border` sits on, so both take the alpha swap in dark
  # and the ring keeps a mark inside it. Left as the literal it would be 22%
  # black on a `#1E1D1B` card — a tick that renders as nothing.
  def meal_card(%{state: :next} = meal) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
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
          <Text text={String.upcase(meal.slot)} font_family="mono" text_size={9.5} letter_spacing={0.14} text_color={Palette.eyebrow()} max_lines={1} />
          <Spacer size={4} />
          <Text text={meal.title} text_size={15} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={meal.calories} font_family="mono" text_size={10.5} text_color={Palette.muted()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box width={32} height={32} corner_radius={16} border_width={1.5} border_color={Palette.border()} align="center">
          {Kati.UI.symbol("check", size: 19, color: Palette.track_ink())}
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
      [size: 34, shape: :circle, variant: :filled, background: Palette.paper()],
      [UI.symbol("more_horiz", size: 17, color: Palette.ink_soft())]
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
    # The ink tone is a filled call-to-action, so it INVERTS rather than
    # following the ground: `ink_fill` under `on_ink`, the pair screen 28 draws
    # for the hero's Open-inbox pill. The paper tone is a surface and follows
    # the page down instead.
    background = if tone == :ink, do: Palette.ink_fill(), else: Palette.paper()
    color = if tone == :ink, do: Palette.on_ink(), else: Palette.ink_soft()

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
        <Box width={size} height={size} corner_radius={radius} background={Palette.placeholder()} />
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
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="center">
        {Kati.UI.symbol("schedule", size: 20, color: Palette.gold_icon())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={prep.title} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={prep.line} text_size={11.5} text_color={Palette.cream_sub()} max_lines={1} />
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
  # `cream_raise`, not `lock_ink_60` — the other meaning `Kati.Theme.Palette`
  # gives `0x99FFFFFF`. That one sits on a photograph and does not move; this is
  # a chip lifted a step off the cream card, so it follows the card and goes
  # solid `#3A342D` in dark, where a 60% white would blow the panel out.
  #
  # The same pill as `action/3`, and it does not call it only because its fill
  # and ink are neither of that function's two tones.
  @doc false
  def prep_secondary(label) do
    MishkaPill.pill(
      label: label,
      background: Palette.cream_raise(),
      color: Palette.cream_sub(),
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

  # Meals is a hub, and every screen it reaches is one whose own drawing opens
  # with a `‹ Meals` back pill — 44, 45, 47, 48 and 49. Five of the six; screen
  # 51 is the sixth and no drawing anywhere gives it a control, which
  # `Kati.Screens.MealReminders` records rather than papering over.
  #
  # `:open_week` is the header disc AND the first tile: the drawing gives both
  # the same `calendar_view_week` glyph, so they are one affordance drawn twice
  # and they go to one place.
  @impl true
  def handle_tap(:open_meal, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Meal)}
  def handle_tap(:open_week, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealPlan)}
  def handle_tap(:open_shopping, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Shopping)}
  def handle_tap(:open_nutrition, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Nutrition)}

  # Both of these open screen 49, and both are the drawing's own words for it.
  # The `tune` tile is labelled "Plan" — the profile, not the week — and the
  # title pill is "Cutting v3" under an `unfold_more`, which is a picker glyph:
  # it says there are others. 49 is where the others are.
  def handle_tap(:open_plan, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Plans)}
  def handle_tap(:switch_plan, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Plans)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
