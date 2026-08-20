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

  alias Kati.Components.MishkaSeparator
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
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={40}>
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
        {Kati.UI.paper_fade(190)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          <Row height={26} corner_radius={13} background={0x294E9A73} padding_left={11} padding_right={11} align="center">
            {Kati.UI.symbol("check_circle", size: 15, color: 0xFF3E8460, fill: true)}
            <Spacer size={6} />
            <Text text={f.watched} text_size={11.5} font_weight="semibold" text_color={0xFF3E8460} max_lines={1} />
          </Row>
          <Spacer size={11} />
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
    case Sample.poster(f.seed) do
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
    # `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)` — this screen floats its
    # chrome over a photograph, so both controls carry the same lift. Neither
    # had one, which is why they read as flat stickers on the still.
    lift = "0 6 16 -8 #991A1917"

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row height={42} corner_radius={21} background={fill} shadow={lift} padding_left={12} padding_right={16} align="center" on_tap={back}>
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={6} />
          <Text text="Library" text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} />
        </Row>
        <Spacer weight={1.0} />
        <Box width={42} height={42} corner_radius={21} background={fill} shadow={lift} align="center">
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
    </Box>
    """
  end

  # Two hugging children with a weighted Spacer between them, not a weighted
  # column beside a plain one. The previous version put a width-less Box in the
  # trailing Column: a Box fills width unless `width` is a NUMBER, so it took
  # everything and starved the weight={1.0} column to zero — the card rendered
  # 333dp tall against the drawing's 84 and the stars did not appear at all.
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
        {Kati.Screens.Film.stars(f.stars)}
      </Column>
      <Column weight={1.0}>
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text text={String.upcase("Seen")} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFA0998F} max_lines={1} />
        </Row>
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text text={f.seen} text_size={16} font_weight="bold" text_color={:on_surface} max_lines={1} />
        </Row>
      </Column>
    </Row>
    """
  end

  # Material Symbols, not U+2605. Plus Jakarta Sans has no star glyph, so the
  # text version rendered as nothing at all — an empty card rather than a
  # missing-glyph box, which is why it read as a layout bug.
  @doc false
  def stars(filled) do
    ~MOB"""
    <Row align="center">
      {1..5 |> Enum.map(fn i -> Kati.Screens.Film.star(i <= filled) end) |> Enum.intersperse(Kati.Screens.Film.star_gap())}
    </Row>
    """
  end

  # The drawing sets the star line at 22px with `letter-spacing:.1em` — 2.2pt
  # of air after each glyph. Material Symbols carry no tracking of their own.
  @doc false
  def star_gap, do: ~MOB"<Box width={2} height={1} />"

  @doc false
  def star(true), do: Kati.UI.symbol("star", size: 22, color: 0xFFE8823C, fill: true)
  def star(false), do: Kati.UI.symbol("star", size: 22, color: 0xFFE8823C)

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
          <Text text={row.badge} font_family="mono" text_size={13} font_weight="medium" text_color={:on_surface} />
        </Box>
        <Spacer size={13} />
        <Text text={row.name} text_size={13.5} font_weight="semibold" text_color={:on_surface} weight={1.0} max_lines={1} />
        <Text text={row.price} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      </Row>
      {Kati.Screens.Film.hairline(rule?)}
    </Column>
    """
  end

  # Mishka's Separator, at the design's own colour and thickness.
  #
  # The pixels are the hand-rolled Box's exactly: `separator/1` emits
  # `<Divider color thickness>`, and `MobDivider` is Material 3's
  # `HorizontalDivider`, which is `Box(modifier.fillMaxWidth().height(thickness)
  # .background(color))` — the same full-width 1dp rectangle in the same colour
  # that `<Box fill_width height={1} background>` produced.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: MishkaSeparator.separator(color: 0x121A1917, thickness: 1)

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

  # A Box for the frame and a Column for the stack, not a Column doing both.
  # `Column` takes no horizontal alignment in this bridge, so its children pin
  # to the left edge — the icons and labels sat against the button's left side.
  # A Box centres its content in both axes when given `align`.
  @doc false
  def action(icon, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        height={52}
        corner_radius={20}
        background={Kati.Theme.card(:light)}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        <Column>
          <Row align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol(icon, size: 19)}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={3} />
          <Text text={label} text_size={10.5} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} text_align="center" />
        </Column>
      </Box>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
