defmodule Kati.Screens.Meal do
  @moduledoc """
  Screen 45 — a meal in full, pushed under Meals.

  Built to `.scratch/design/screens/45.html`. It shares screens 04 and 08's
  shape — artwork with the paper gradient lifted back over it, chrome floating
  at 60pt, the title sitting on paper rather than on the photograph — and
  diverges where a meal differs from a film: the hero is 250pt instead of 330
  because the numbers matter more than the picture, and the first card under it
  is the portion.

  Its own chrome rather than `Kati.Screens.Pushed`, for the same reason screen
  08 has its own: the back pill has to float **over** the photograph, and the
  pushed frame draws it over paper.

  ## Where this diverges from the drawing

    * **The rating is five Material Symbols stars, not five `&starf;`
      characters.** Plus Jakarta Sans carries no U+2605 — screen 08 shipped
      that once and the card rendered empty. So the glyph changes and the mark
      does not, and `bin/check_screen.py` reports that one line as missing for
      exactly this reason.
    * **The macro bar's ends are square inside a rounded track.** The drawing
      clips them with `overflow:hidden`; Mob does not clip children.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Meals.SampleRecipe, as: Sample
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :meal, Sample.meal())}
  end

  def render(assigns) do
    meal = assigns.meal

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Meal.artwork(meal)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={40}>
            {Kati.Screens.Meal.portion_card(meal)}
            {Kati.Screens.Meal.actions()}
            {UI.eyebrow("Ingredients · 1 portion")}
            {Kati.Screens.Meal.ingredients()}
            {Kati.Screens.Meal.muted_eyebrow("Method")}
            {Kati.Screens.Meal.method()}
            {Kati.Screens.Meal.muted_eyebrow("History")}
            {Kati.Screens.Meal.history()}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Meal.chrome()}
    </Box>
    """
  end

  @doc false
  def artwork(meal) do
    ~MOB"""
    <Box fill_width={true} height={250} background={0xFFDCD7CF}>
      {Kati.Screens.Meal.hero_art(meal)}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(130)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={4}>
          <Text
            text={String.upcase(meal.slot)}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.14}
            text_color={0xFF8A8479}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={meal.title}
            text_size={26}
            font_weight="extrabold"
            letter_spacing={-0.035}
            line_height={1.1}
            text_color={:on_surface}
          />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero_art(meal) do
    case Kati.Design.Images.hero(meal.seed) do
      nil -> ~MOB"<Spacer size={0} />"
      src -> ~MOB"""
        <Image src={src} fill_width={true} height={250} content_mode="fill" />
        """
    end
  end

  # The card fill, not `chrome_fill/1`. The dock's 90%-opaque chrome reads as
  # glass over a blurred backdrop; there is no backdrop blur here, so over a
  # photograph it is simply see-through — the building behind the meal came
  # through the overflow disc. Every other floating disc in the app
  # (`Kati.Screens.Health.disc/2`, screen 47's share button) is opaque card.
  @doc false
  def chrome do
    back = {self(), :back}
    more = {self(), :more}
    fill = Kati.Theme.card(:light)

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row height={44} corner_radius={22} background={fill} shadow={Kati.Theme.shadow_button()} padding_left={12} padding_right={16} align="center" on_tap={back}>
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={6} />
          <Text text="Meals" text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} />
        </Row>
        <Spacer weight={1.0} />
        <Box width={44} height={44} corner_radius={22} background={fill} shadow={Kati.Theme.shadow_button()} align="center" on_tap={more}>
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def portion_card(meal) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text text={String.upcase("Per portion")} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFA0998F} />
            <Spacer size={6} />
            <Row align="bottom">
              <Text text={meal.calories} text_size={32} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} max_lines={1} />
              <Text text={meal.unit} text_size={15} font_weight="semibold" text_color={0xFFA9A29A} max_lines={1} />
            </Row>
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Meal.stepper(meal)}
        </Row>
        <Spacer size={14} />
        {Kati.Screens.Meal.macro_bar()}
        <Spacer size={14} />
        {Kati.Screens.Meal.macro_tiles()}
        <Spacer size={12} />
        <Box fill_width={true} height={1} background={0x121A1917} />
        <Spacer size={12} />
        {Kati.Screens.Meal.minors()}
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  # `remove` is muted and `add` is inked: at 1.0× there is nothing to take away
  # yet, which the drawing says with colour rather than with a disabled state.
  @doc false
  def stepper(meal) do
    down = {self(), :portion_down}
    up = {self(), :portion_up}

    ~MOB"""
    <Row height={32} corner_radius={16} background={0xFFEFECE7} padding_left={12} padding_right={12} align="center">
      <Box on_tap={down} width={16} height={16} align="center">
        {Kati.UI.symbol("remove", size: 16, color: 0xFF8A8479)}
      </Box>
      <Spacer size={7} />
      <Text text={meal.portion} font_family="mono" text_size={13} font_weight="medium" text_color={:on_surface} max_lines={1} />
      <Spacer size={7} />
      <Box on_tap={up} width={16} height={16} align="center">
        {Kati.UI.symbol("add", size: 16)}
      </Box>
    </Row>
    """
  end

  @doc false
  def macro_bar do
    ~MOB"""
    <Box fill_width={true} height={10} corner_radius={5} background={0xFFEFECE7}>
      <Row fill_width={true}>
        {Enum.map(Kati.Meals.SampleRecipe.split(), fn {share, tone} -> Kati.Screens.Meal.segment(share, tone) end)}
      </Row>
    </Box>
    """
  end

  @doc false
  def segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={10} background={tone} />
    """
  end

  @doc false
  def macro_tiles do
    tiles =
      Sample.macros()
      |> Enum.map(fn {name, value, tone} -> macro_tile(name, value, tone) end)
      |> Enum.intersperse(tile_gap())

    ~MOB"""
    <Row fill_width={true} align="top">
      {tiles}
    </Row>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def macro_tile(name, value, tone) do
    ~MOB"""
    <Box weight={1.0}>
      <Column fill_width={true} background={0xFFEFECE7} corner_radius={14} padding={11}>
        <Row fill_width={true} align="center">
          <Box width={6} height={6} corner_radius={2} background={tone} />
          <Spacer size={5} />
          <Text
            text={String.upcase(name)}
            font_family="mono"
            text_size={9}
            letter_spacing={0.1}
            text_color={0xFFA0998F}
            max_lines={1}
          />
        </Row>
        <Spacer size={6} />
        <Text text={value} text_size={16} font_weight="bold" text_color={:on_surface} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def minors do
    columns =
      Sample.minors()
      |> Enum.map(fn {label, value} -> minor(label, value) end)
      |> Enum.intersperse(minor_gap())

    ~MOB"""
    <Row fill_width={true} align="top">
      {columns}
    </Row>
    """
  end

  @doc false
  def minor_gap, do: ~MOB"<Spacer size={14} />"

  @doc false
  def minor(label, value) do
    ~MOB"""
    <Column weight={1.0}>
      <Text
        text={String.upcase(label)}
        font_family="mono"
        text_size={9}
        letter_spacing={0.1}
        text_color={0xFFA0998F}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text text={value} text_size={13} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def actions do
    eat = {self(), :mark_eaten}
    swap = {self(), :swap}
    save = {self(), :save}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box weight={1.0}>
          <Box
            fill_width={true}
            height={50}
            corner_radius={25}
            background={Kati.Theme.ink()}
            shadow="0 12 24 -12 #D91A1917"
            align="center"
            on_tap={eat}
          >
            <Row fill_width={true} align="center">
              <Spacer weight={1.0} />
              {Kati.UI.symbol("check", size: 19, color: 0xFFFBFAF8)}
              <Spacer size={8} />
              <Text text="Mark eaten" text_size={14} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
              <Spacer weight={1.0} />
            </Row>
          </Box>
        </Box>
        <Spacer size={10} />
        {Kati.Screens.Meal.disc("swap_horiz", swap)}
        <Spacer size={10} />
        {Kati.Screens.Meal.disc("bookmark", save)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def disc(icon, tap) do
    ~MOB"""
    <Box
      width={50}
      height={50}
      corner_radius={25}
      background={Kati.Theme.card(:light)}
      shadow={Kati.Theme.shadow_card_soft()}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
  end

  @doc false
  def ingredients do
    rows = Sample.ingredients()
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
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Meal.ingredient_row(row, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def ingredient_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={12} padding_bottom={12}>
        <Box width={20} height={20} corner_radius={6} border_width={1.5} border_color={0x291A1917} />
        <Spacer size={13} />
        <Text text={row.name} text_size={13} font_weight="semibold" text_color={:on_surface} weight={1.0} max_lines={1} />
        <Spacer size={13} />
        <Text text={row.amount} font_family="mono" text_size={11.5} text_color={0xFF5C574F} max_lines={1} />
        <Spacer size={13} />
        <Column width={30}>
          <Text text={row.calories} font_family="mono" text_size={10.5} text_color={0xFFC4BDB3} text_align="right" max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.Meal.hairline(rule?)}
    </Column>
    """
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # Method and History are neither, so the drawing gives them a #C4BDB3 dash.
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

  # On cream, like screen 08's note: the design's one warm surface, used here
  # for the part of the card a person reads rather than counts.
  @doc false
  def method do
    facts =
      Sample.method_facts()
      |> Enum.map(fn {icon, label} -> fact(icon, label) end)
      |> Enum.intersperse(fact_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Kati.Theme.cream(:light)} corner_radius={20} padding={17}>
        <Row fill_width={true} align="center">
          {facts}
        </Row>
        <Spacer size={13} />
        <Text text={Kati.Meals.SampleRecipe.method()} text_size={13.5} line_height={1.65} text_color={0xFF4A4238} />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def fact_gap, do: ~MOB"<Spacer size={14} />"

  @doc false
  def fact(icon, label) do
    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol(icon, size: 15, color: 0xFFC98A3E)}
      <Spacer size={6} />
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={0xFF8A7B60} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def history do
    rows = Sample.history()
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
      {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Meal.history_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def history_row(row, rule?) do
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
          {Kati.Screens.Meal.history_sub(row)}
        </Column>
        <Spacer size={13} />
        {Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)}
      </Row>
      {Kati.Screens.Meal.hairline(rule?)}
    </Column>
    """
  end

  # Material Symbols, not U+2605 — screen 08 proved the text version renders as
  # nothing at all in Plus Jakarta Sans, which reads as a layout bug rather
  # than a missing glyph.
  @doc false
  def history_sub(%{stars: 0} = row) do
    ~MOB"""
    <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    """
  end

  def history_sub(row) do
    ~MOB"""
    <Row align="center">
      {Enum.map(1..row.stars, fn _ -> Kati.Screens.Meal.star() end)}
      <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def star, do: Kati.UI.symbol("star", size: 12, color: 0xFF8A8479, fill: true)

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}
end
