defmodule Kati.Screens.Series do
  @moduledoc """
  Screen 04 — a series, pushed under Library.

  Built to `.scratch/design/screens/04.html`. The shape is a 330pt artwork
  block with a 190pt gradient lifting the paper back over it, floating chrome
  at 60pt, and the title sitting on the gradient rather than in a bar.

  The chrome here is the screen's own, not `Kati.Screens.Pushed`'s: this back
  pill floats over artwork at `rgba(251,250,248,.82)` and carries the label
  inline, where the standard pushed chrome sits on paper. Matching the drawing
  matters more than sharing a helper.

  Three episode states are drawn and all three are exercised by the sample:
  watched (muted title, filled check), unwatched (ink title, hollow check),
  and not yet aired (muted, no check).
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Library.Sample
  alias Kati.Theme

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :series, Sample.series())}
  end

  def render(assigns) do
    s = assigns.series
    pct = s.watched / s.total

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Series.artwork(s)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={132}>
            {Kati.Screens.Series.season_card(s, pct)}
            {Kati.Screens.Series.actions()}
            {Kati.Screens.Series.episodes_header(s)}
            {Kati.Screens.Series.episodes(s)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Series.chrome()}
    </Box>
    """
  end

  @doc false
  def artwork(s) do
    ~MOB"""
    <Box fill_width={true} height={330} background={0xFFDCD7CF}>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          <Text
            text={s.title}
            text_size={30}
            font_weight="extrabold"
            letter_spacing={-0.035}
            line_height={1.05}
            text_color={:on_surface}
          />
          <Spacer size={9} />
          <Text text={s.meta} font_family="mono" text_size={11.5} text_color={0xFF6E6860} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

  # The floating chrome. `arrow_back_ios_new` rather than a chevron, because
  # that is the glyph the drawing names.
  @doc false
  def chrome do
    back = {self(), :back}
    fill = 0xD1FBFAF8

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} vertical_align="center">
        <Row height={42} corner_radius={21} background={fill} padding_left={13} padding_right={16} vertical_align="center" on_tap={back}>
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
  def season_card(s, pct) do
    ~MOB"""
    <Column fill_width={true}>
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
    >
      <Row fill_width={true} vertical_align="center">
        <Text text={s.season} text_size={15} font_weight="bold" letter_spacing={-0.02} text_color={:on_surface} />
        <Spacer weight={1.0} />
        <Text
          text={"#{s.watched} of #{s.total} watched"}
          font_family="mono"
          text_size={11.5}
          text_color={0xFF8A8479}
          max_lines={1}
        />
      </Row>
      <Spacer size={12} />
      <Box fill_width={true} height={6} corner_radius={3} background={0xFFE7E3DC}>
        <Row fill_width={true}>
          <Box weight={pct} height={6} corner_radius={3} background={Kati.Theme.ink()} />
          <Spacer weight={1.0 - pct} />
        </Row>
      </Box>
      <Spacer size={14} />
      <Row fill_width={true} vertical_align="center">
        <Box width={6} height={6} corner_radius={3} background={0xFFE8823C} />
        <Spacer size={8} />
        <Text text={"Next episode airs #{s.next_air}"} text_size={12.5} text_color={0xFF5C574F} max_lines={1} />
      </Row>
    </Column>
    <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def actions do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="center">
        <Box weight={1.0}>
          <Row fill_width={true} height={50} corner_radius={25} background={Kati.Theme.ink()} vertical_align="center" horizontal_align="center">
            {Kati.UI.symbol("check", size: 19, color: 0xFFFBFAF8)}
            <Spacer size={8} />
            <Text text="Mark next watched" text_size={14} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
          </Row>
        </Box>
        <Spacer size={10} />
        {Kati.Screens.Series.action_disc("bookmark")}
        <Spacer size={10} />
        {Kati.Screens.Series.action_disc("star")}
      </Row>
    </Column>
    """
  end

  @doc false
  def action_disc(icon) do
    ~MOB"""
    <Box
      width={50}
      height={50}
      corner_radius={25}
      background={Kati.Theme.card(:light)}
      shadow={Kati.Theme.shadow_card_soft()}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
  end

  @doc false
  def episodes_header(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={26} />
      <Row fill_width={true} vertical_align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text text="EPISODES" font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFA0998F} />
        <Spacer weight={1.0} />
        {s.seasons |> Enum.map(fn n -> Kati.Screens.Series.season_pill(n, n == s.current_season) end) |> Enum.intersperse(Kati.Screens.Series.pill_gap())}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def pill_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def season_pill(label, on?) do
    bg = if on?, do: Theme.ink(), else: 0xFFE4E0D9
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F

    ~MOB"""
    <Box width={30} height={28} corner_radius={10} background={bg} align="center">
      <Text text={label} text_size={11.5} font_weight="bold" text_color={fg} max_lines={1} />
    </Box>
    """
  end

  @doc false
  def episodes(s) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(s.episodes, fn ep -> Kati.Screens.Series.episode(ep) end)}
    </Column>
    """
  end

  @doc false
  def episode(ep) do
    aired? = Map.get(ep, :aired, true)
    bg = if ep.watched, do: 0xFFF4F1EC, else: Theme.card(:light)
    title_color = if ep.watched or not aired?, do: 0xFF8A8479, else: Theme.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={bg} corner_radius={17} padding_left={15} padding_right={15} padding_top={13} padding_bottom={13} vertical_align="center">
        <Column width={22}>
          <Text text={"#{ep.n}"} font_family="mono" text_size={12} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={ep.title} text_size={14} font_weight="semibold" letter_spacing={-0.01} text_color={title_color} max_lines={1} />
          <Spacer size={4} />
          <Text text={ep.sub} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Series.check(ep.watched, aired?)}
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc false
  def check(true, _aired?) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} background={Kati.Theme.ink()} align="center">
      {Kati.UI.symbol("check", size: 16, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  def check(false, true) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} border_width={1} border_color={0xFFD8D2C8} align="center">
      {Kati.UI.symbol("check", size: 16, color: 0xFFD8D2C8)}
    </Box>
    """
  end

  # Not aired yet: no affordance at all, because there is nothing to mark.
  def check(false, false), do: ~MOB"<Spacer size={27} />"

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
