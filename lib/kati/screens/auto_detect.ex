defmodule Kati.Screens.AutoDetect do
  @moduledoc """
  Screen 36 — Auto-detect, pushed under Settings.

  Built to `.scratch/design/screens/36.html`. Manual ticking stays the
  default; this is the opt-in that removes it, and the screen is arranged as
  the argument for trusting it: the cream banner says how many episodes it has
  already ticked, Now playing shows the rule being applied live, and the last
  card is the one ambiguous match it refused to guess at.

  Rules carries the grey dash rather than the orange one — it qualifies the
  sources above it rather than announcing anything new.

  The "Needs a decision" card is the design's real point. An unsure match
  becomes a question instead of a tick, because a wrong tick pollutes a watch
  history nobody audits.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Settings.DetectSample, as: Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :detect, %{
      sources_line: Sample.sources_line(),
      banner: Sample.banner(),
      now_playing: Sample.now_playing(),
      sources: Sample.sources(),
      rules: Sample.rules(),
      decision: Sample.decision()
    })
  end

  @doc false
  def content(assigns) do
    d = assigns.detect

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("Auto-detect", d.sources_line)}
        {Kati.Screens.AutoDetect.banner(d.banner)}
        {UI.eyebrow("Now playing")}
        {Kati.Screens.AutoDetect.now_playing(d.now_playing)}
        {UI.eyebrow("Sources")}
        {Kati.Screens.AutoDetect.group(d.sources)}
        {SettingsList.eyebrow_muted("Rules")}
        {Kati.Screens.AutoDetect.group(d.rules)}
        {UI.eyebrow("Needs a decision")}
        {Kati.Screens.AutoDetect.decision(d.decision)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def banner(b) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
        align="center"
      >
        {Kati.UI.symbol("sensors", size: 24, color: 0xFFC98A3E)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={b.title} text_size={14.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={b.meta} font_family="mono" text_size={10.5} text_color={0xFFB09A72} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {SettingsList.switch(b.on)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The Now playing card, with the elapsed bar drawn from two weighted cells.

  `Kati.Components.MishkaProgress` is the component for a progress bar and it
  cannot draw this one. It renders Mob's `<Progress>`, which the bridge maps to
  Compose's `LinearProgressIndicator`, and that widget exposes exactly one
  colour — the indicator's. The drawing needs three things it has no prop for:
  a `#E7E3DC` track (the Material default track colour is whatever the theme's
  `surfaceVariant` resolves to, and `MobProgress` never reads a `track_color`
  at all), a 5pt thickness on both the track and the fill, and a 3pt radius on
  both. Two weighted boxes inside a rounded track give all three, so they stay.
  """
  def now_playing(n) do
    rest = 1.0 - n.progress

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.AutoDetect.poster(n.seed, 44, 62, 9)}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text text={n.title} text_size={14} font_weight="bold" text_color={:on_surface} max_lines={1} />
            <Spacer size={4} />
            <Text text={n.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
          </Column>
          <Spacer size={12} />
          {SettingsList.status_pill(n.status, 0xFF3E8460, 0x294E9A73)}
        </Row>
        <Spacer size={14} />
        <Box fill_width={true} height={5} corner_radius={3} background={0xFFE7E3DC}>
          <Row fill_width={true}>
            <Box weight={n.progress} height={5} corner_radius={3} background={Kati.Theme.ink()} />
            <Spacer weight={rest} />
          </Row>
        </Box>
        <Spacer size={9} />
        <Row fill_width={true} align="center">
          <Text text={n.elapsed} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
          <Spacer weight={1.0} />
          <Text text={n.rule} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def poster(seed, w, h, radius) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"""
        <Box width={w} height={h} corner_radius={radius} background={0xFFE4E0D9} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={w} height={h} corner_radius={radius} content_mode="fill" />
        """
    end
  end

  @doc false
  def group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.AutoDetect.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.AutoDetect.control(row.control),
      padding: 13,
      rule: rule?
    )
  end

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)
  def control({:pill, label}), do: SettingsList.action_pill(label)

  @doc false
  def decision(d) do
    buttons =
      d.options
      |> Enum.map(fn o -> Kati.Screens.AutoDetect.choice(o, o == d.chosen) end)
      |> Enum.intersperse(Kati.Screens.AutoDetect.choice_gap())

    ~MOB"""
    <Column
      fill_width={true}
      background={0xFFFBFAF8}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.AutoDetect.poster(d.seed, 36, 51, 7)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={d.question} text_size={13} font_weight="bold" text_color={:on_surface} />
          <Spacer size={4} />
          <Text text={d.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {buttons}
      </Row>
    </Column>
    """
  end

  @doc false
  def choice_gap, do: ~MOB"<Spacer size={8} />"

  @doc false
  def choice(label, on?) do
    bg = if on?, do: Kati.Theme.ink(), else: 0xFFEFECE7
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={34} corner_radius={17} background={bg} align="center">
        <Spacer weight={1.0} />
        <Text text={label} text_size={11.5} font_weight="semibold" text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end
end
