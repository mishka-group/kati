defmodule Kati.Screens.SeriesFa do
  @moduledoc """
  Screen 58 — سریال, the Persian episode tracker, pushed under کتابخانه.

  Built to `.scratch/design/screens/58.html`. Screen 04's page in Persian, and
  smaller in two ways that are easy to miss: the artwork is **300** tall, not
  330, and the frame's bottom inset is **40, not 132**, because a pushed
  screen has no dock to clear.

  ## Its own chrome, like screen 04 — and one glyph different

  `Kati.Screens.Pushed` puts an `arrow_back_ios_new` pill on paper. This page
  floats its own over the photograph, and the chevron is **`arrow_forward_ios`**:
  back is the way the reader came from, and in Persian that is the right edge.
  A mirrored screen that keeps the left-pointing chevron is the commonest RTL
  bug there is, so the drawing names the other glyph and this screen uses it.

  ## The gradient is what makes the title readable

  170pt of `rgba(239,236,231,1) 4% → .72 42% → transparent` lifted back over
  the bottom of the photograph. Without it "گودال بلند" is near-black type on
  a dark picture. Three stops, not two — the bridge's gradient parser takes as
  many colour/stop pairs as the design writes.

  ## Three episode states

  Watched rows sit flat on `#F4F1EC` with a filled ink check and a muted
  title; the two unaired rows are lifted on card white with an ink title and
  an empty `rgba(26,25,23,.16)` ring. The drawing puts a `check` glyph inside
  that ring at **zero alpha** — invisible, but it holds the ring's inner
  metrics identical to the filled one, so the column does not shift. That is
  reproduced literally rather than tidied away.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.SeriesFa.Sample
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :series, Sample.series())}
  end

  def render(assigns) do
    Fa.pushed_frame(Kati.Screens.SeriesFa.page(assigns.series))
  end

  @doc false
  def page(series) do
    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.SeriesFa.artwork(series)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={40}>
            {Kati.Screens.SeriesFa.season_card(series)}
            {Kati.Screens.SeriesFa.actions(series)}
            {Kati.Screens.SeriesFa.episodes_header(series)}
            {Kati.Screens.SeriesFa.episodes(series)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.SeriesFa.chrome(series)}
    </Box>
    """
  end

  @doc false
  def artwork(series) do
    ~MOB"""
    <Box fill_width={true} height={300} background={0xFFDCD7CF}>
      {Kati.Screens.SeriesFa.hero_art(series.seed)}
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={170} gradient="to_top #FFEFECE7 4% #B8EFECE7 42% #00EFECE7" />
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          <Text
            text={series.title}
            font_family="fa"
            font_weight="extrabold"
            text_size={28}
            line_height={1.35}
            text_color={:on_surface}
          />
          <Spacer size={8} />
          <Text text={series.meta} font_family="fa" text_size={11.5} text_color={0xFF6E6860} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

  # The 900x700 crop, which is the one the drawing names — not the 900x740
  # `Kati.Design.Images.hero/1` reaches for first.
  @doc false
  def hero_art(seed) do
    case Kati.Design.Images.path(seed, {900, 700}) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={300} content_mode="fill" />
        """
    end
  end

  @doc false
  def chrome(series) do
    back = {self(), :back}

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={0xFFFBFAF8}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          <Text
            text={series.back}
            font_family="fa"
            font_weight="semibold"
            text_size={13.5}
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
        <Box width={42} height={42} corner_radius={21} background={0xD1FBFAF8} align="center">
          {UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def season_card(series) do
    progress = series.progress

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="bottom">
          <Text
            text={series.season}
            font_family="fa"
            font_weight="bold"
            text_size={14.5}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={series.watched_line}
            font_family="fa"
            text_size={11.5}
            text_color={0xFF8A8479}
            max_lines={1}
          />
        </Row>
        <Spacer size={12} />
        <Box fill_width={true} height={6} corner_radius={3} background={0xFFE7E3DC}>
          <Row fill_width={true}>
            <Box weight={progress} height={6} corner_radius={3} background={Kati.Theme.ink()} />
            <Spacer weight={1.0 - progress} />
          </Row>
        </Box>
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Box width={6} height={6} corner_radius={3} background={0xFFE8823C} />
          <Spacer size={8} />
          <Text text={series.next_air} font_family="fa" text_size={12} text_color={0xFF5C574F} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # One disc beside the primary button, not two: this drawing keeps `bookmark`
  # and drops screen 04's `star`.
  @doc false
  def actions(series) do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Row fill_width={true} height={50} corner_radius={25} background={Kati.Theme.ink()} align="center">
          <Spacer weight={1.0} />
          {UI.symbol("check", size: 19, color: 0xFFFBFAF8)}
          <Spacer size={8} />
          <Text
            text={series.action}
            font_family="fa"
            font_weight="bold"
            text_size={13.5}
            text_color={0xFFFBFAF8}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Box>
      <Spacer size={10} />
      <Box
        width={50}
        height={50}
        corner_radius={25}
        background={0xFFFBFAF8}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        {UI.symbol("bookmark", size: 21)}
      </Box>
    </Row>
    """
  end

  @doc false
  def episodes_header(series) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={26} />
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text text="قسمت‌ها" font_family="fa" font_weight="semibold" text_size={11} text_color={0xFFA0998F} />
        <Spacer weight={1.0} />
        {series.seasons
         |> Enum.map(fn {label, on?} -> Kati.Screens.SeriesFa.season_pill(label, on?) end)
         |> Enum.intersperse(Kati.Screens.SeriesFa.pill_gap())}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def pill_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def season_pill(label, on?) do
    bg = if on?, do: Kati.Theme.ink(), else: 0xFFE4E0D9
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF6E6860

    ~MOB"""
    <Box width={32} height={28} corner_radius={10} background={bg} align="center">
      <Text text={label} font_family="fa" text_size={11.5} text_color={fg} max_lines={1} />
    </Box>
    """
  end

  @doc false
  def episodes(series) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(series.episodes, &Kati.Screens.SeriesFa.episode/1)}
    </Column>
    """
  end

  @doc false
  def episode(ep) do
    bg = if ep.watched, do: 0xFFF4F1EC, else: 0xFFFBFAF8
    shadow = if ep.watched, do: nil, else: Kati.Theme.shadow_card_soft()
    title_color = if ep.watched, do: 0xFF9C958B, else: Kati.Theme.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={bg}
        corner_radius={17}
        shadow={shadow}
        padding_left={15}
        padding_right={15}
        padding_top={13}
        padding_bottom={13}
        align="center"
      >
        <Column width={24}>
          <Text text={ep.n} font_family="fa" text_size={12} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={ep.title}
            font_family="fa"
            font_weight="semibold"
            text_size={13.5}
            text_color={title_color}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={ep.sub} font_family="fa" text_size={11} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SeriesFa.check(ep.watched)}
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc false
  def check(true) do
    ~MOB"""
    <Box
      width={27}
      height={27}
      corner_radius={14}
      background={Kati.Theme.ink()}
      border_width={1.5}
      border_color={0xFF1A1917}
      align="center"
    >
      {Kati.UI.symbol("check", size: 16, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  # The empty ring, with the drawing's own zero-alpha glyph inside it so the
  # ring's inner box measures the same as the filled one.
  def check(false) do
    ~MOB"""
    <Box
      width={27}
      height={27}
      corner_radius={14}
      border_width={1.5}
      border_color={0x291A1917}
      align="center"
    >
      {Kati.UI.symbol("check", size: 16, color: 0x001A1917)}
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}
end
