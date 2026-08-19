defmodule Kati.Screens.Film do
  @moduledoc """
  Screen 08 — a film, pushed under Library.

  Shares screen 04's shape — 330pt artwork, chrome floating at 60pt, the title
  on the gradient — and diverges where a film differs from a series: a watched
  pill above the title instead of a season card, a rating, and a note.

  The note sits on cream. The design's own caption says that is deliberate:
  it is "the one place the palette warms up", the same treatment the hero card
  gets on Home, and it marks the user's own words as different from metadata.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Library.Sample
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :film, Sample.film())}
  end

  def render(assigns) do
    f = assigns.film

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Film.artwork(f)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={132}>
            {Kati.Screens.Film.rating_card(f)}
            {Kati.Screens.Film.note(f)}
            {UI.eyebrow("Where to watch")}
            {Kati.Screens.Film.where(f)}
            {Kati.Screens.Film.actions(f)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Film.chrome()}
    </Box>
    """
  end

  @doc false
  def artwork(f) do
    ~MOB"""
    <Box fill_width={true} height={330} background={0xFFDCD7CF}>
      {Kati.Screens.Film.hero_art(f)}
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          <Row height={26} corner_radius={13} background={0x294E9A73} padding_left={9} padding_right={11} align="center">
            {Kati.UI.symbol("check_circle", size: 15, color: 0xFF3E8460, fill: true)}
            <Spacer size={6} />
            <Text text={f.watched} text_size={11.5} font_weight="semibold" text_color={0xFF3E8460} max_lines={1} />
          </Row>
          <Spacer size={9} />
          <Text text={f.title} text_size={30} font_weight="extrabold" letter_spacing={-0.035} line_height={1.05} text_color={:on_surface} />
          <Spacer size={9} />
          <Text text={f.meta} font_family="mono" text_size={11.5} text_color={0xFF6E6860} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero_art(f) do
    case Sample.poster(f.slug) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={330} content_mode="fill" />
        """
    end
  end

  @doc false
  def chrome do
    back = {self(), :back}
    fill = 0xD1FBFAF8

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row height={42} corner_radius={21} background={fill} padding_left={13} padding_right={16} align="center" on_tap={back}>
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={7} />
          <Text text="Library" text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} />
        </Row>
        <Spacer weight={1.0} />
        <Box width={42} height={42} corner_radius={21} background={fill} align="center">
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def rating_card(f) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
      align="center"
    >
      <Column weight={1.0}>
        <Text text={String.upcase("Your rating")} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFA0998F} />
        <Spacer size={7} />
        <Text text={f.rating} text_size={22} letter_spacing={0.1} text_color={0xFFE8823C} max_lines={1} />
      </Column>
      <Column>
        <Text text={String.upcase("Seen")} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFA0998F} text_align="right" />
        <Spacer size={8} />
        <Text text={f.seen} text_size={16} font_weight="bold" text_color={:on_surface} text_align="right" max_lines={1} />
      </Column>
    </Row>
    """
  end

  @doc false
  def note(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Column fill_width={true} background={0xFFFBF1DE} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          <Text text={String.upcase(f.note_date)} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFB09A72} />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("edit", size: 17, color: 0xFFC98A3E)}
        </Row>
        <Spacer size={9} />
        <Text text={f.note} text_size={14} line_height={1.55} text_color={0xFF4A4238} />
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def where(f) do
    last = length(f.where) - 1

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
      {f.where |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Film.where_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def where_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Box width={32} height={32} corner_radius={10} background={0xFFEFECE7} align="center">
          <Text text={row.badge} text_size={13} font_weight="bold" text_color={0xFF5C574F} />
        </Box>
        <Spacer size={13} />
        <Text text={row.name} text_size={13.5} font_weight="semibold" text_color={:on_surface} weight={1.0} max_lines={1} />
        <Text text={row.price} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      </Row>
      {Kati.Screens.Film.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  @doc false
  def actions(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row fill_width={true} align="top">
        {f.actions |> Enum.map(fn {icon, label} -> Kati.Screens.Film.action(icon, label) end) |> Enum.intersperse(Kati.Screens.Film.action_gap())}
      </Row>
    </Column>
    """
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def action(icon, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        height={52}
        corner_radius={20}
        background={Kati.Theme.card(:light)}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        {Kati.UI.symbol(icon, size: 19)}
        <Spacer size={3} />
        <Text text={label} text_size={10.5} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
      </Column>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
