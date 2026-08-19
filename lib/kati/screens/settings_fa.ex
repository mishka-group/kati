defmodule Kati.Screens.SettingsFa do
  @moduledoc """
  Screen 62 — تنظیمات, the Persian mirror of Settings.

  Built to `.scratch/design/screens/62.html`. Pushed under خانه (Home), so no
  dock and a bottom inset of **40, not 132**.

  ## Two glyphs point opposite ways here, and both are right

  The back pill takes `arrow_forward_ios` and every disclosure row takes
  `chevron_left`. In Persian, back is rightwards and forward is leftwards, so
  the pair reads correctly only when both are mirrored — and Material Symbols
  are text in a font, which nothing auto-mirrors. A screen that flips one and
  not the other sends the reader in both directions at once.

  `layout_direction="rtl"` is a literal, as on the other Persian screens: the
  copy is Persian, so this screen is right-to-left whatever the app's locale
  says. Only `MainActivity` acts on the prop, and only on the root node.

  ## The switch is drawn rather than delegated

  `Kati.Components.MishkaSwitch` wraps Compose's own `Switch`, which brings
  platform metrics and platform animation with it. The design specifies a
  46x28 track with a 22pt thumb on a 3pt inset, in two exact colours — screen
  41 reached the same conclusion. Fidelity wins over reuse for the one control
  the drawing measures.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Design.Images
  alias Kati.Fa.SampleSettings
  alias Kati.Theme

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :settings, SampleSettings.settings())}
  end

  def render(assigns) do
    settings = assigns.settings

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.SettingsFa.header(settings)}
          {Kati.Screens.SettingsFa.title(settings)}
          {Kati.Screens.SettingsFa.me(settings)}
          {Kati.Screens.SettingsFa.sections(settings)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def header(settings) do
    back = {self(), :back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
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
            text={settings.back}
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
          {Kati.UI.symbol("help", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(settings) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={settings.title}
        font_family="fa"
        text_size={27}
        font_weight="bold"
        line_height={1.35}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text text={settings.subtitle} font_family="fa" text_size={11.5} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def me(settings) do
    me = settings.me

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={22}
        shadow={Theme.shadow_card_soft()}
        padding={16}
        align="center"
      >
        {Kati.Screens.SettingsFa.avatar(me.seed)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={me.name}
            font_family="fa"
            text_size={15.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={me.meta} font_family="fa" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={14} />
        <Row height={26} corner_radius={13} background={0x294E9A73} padding_left={10} padding_right={10} align="center">
          {Kati.UI.symbol("cloud_done", size: 14, color: 0xFF3E8460)}
          <Spacer size={5} />
          <Text
            text={me.sync}
            font_family="fa"
            text_size={11}
            font_weight="semibold"
            text_color={0xFF3E8460}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def avatar(seed) do
    case Images.poster(seed) do
      nil ->
        ~MOB"<Box width={52} height={52} corner_radius={26} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={52} height={52} corner_radius={26} content_mode="fill" />
        """
    end
  end

  # The last section carries no bottom gap — the drawing wraps only the first
  # three in a `margin-bottom:22px` block, and the frame's own 40 closes the
  # page.
  @doc false
  def sections(settings) do
    last = length(settings.sections) - 1

    ~MOB"""
    <Column fill_width={true}>
      {settings.sections
       |> Enum.with_index()
       |> Enum.map(fn {section, i} -> Kati.Screens.SettingsFa.section(section, i < last) end)}
    </Column>
    """
  end

  @doc false
  def section(section, gap?) do
    last = length(section.rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.SettingsFa.eyebrow(section.label, section.dash)}
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
        {section.rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.SettingsFa.row(row, i < last) end)}
      </Column>
      {Kati.Screens.SettingsFa.section_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def section_gap(false), do: ~MOB"<Spacer size={0} />"
  def section_gap(true), do: ~MOB"<Spacer size={22} />"

  @doc """
  The section label, in Persian.

  `Kati.UI.eyebrow/2` is DM Mono, uppercased and letter-spaced. The drawing's
  Persian labels are Vazirmatn at 11 semibold with `letter-spacing:0` — Persian
  has no case, and tracking it apart breaks the joins between letters. The
  muted dash is the design's mark for a section you visit rather than set up.
  """
  def eyebrow(label, dash) do
    color = if dash == :muted, do: 0xFFC4BDB3, else: Theme.accent()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={color} />
        <Spacer size={9} />
        <Text text={label} font_family="fa" text_size={11} font_weight="semibold" text_color={0xFFA0998F} />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.SettingsFa.leading(row)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            font_family="fa"
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.SettingsFa.sub(row.sub)}
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SettingsFa.trailing(row.trailing)}
      </Row>
      {Kati.Screens.SettingsFa.hairline(rule?)}
    </Column>
    """
  end

  # The language row's tile carries two letters instead of a glyph — the design
  # names the language in the language, which no icon can do.
  @doc false
  def leading(%{badge: badge}) do
    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={Kati.Theme.ink()} align="center">
      <Text text={badge} font_family="fa" text_size={12} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
    </Box>
    """
  end

  def leading(row) do
    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={0xFFEFECE7} align="center">
      {Kati.UI.symbol(row.icon, size: 17, color: 0xFF5C574F)}
    </Box>
    """
  end

  @doc false
  def sub(nil), do: ~MOB"<Spacer size={0} />"

  def sub(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={text} font_family="fa" text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  # `chevron_left` and not `chevron_right`: forward is leftwards in Persian,
  # and a Material Symbol is a glyph in a font — nothing mirrors it for us.
  @doc false
  def trailing(:chevron), do: Kati.UI.symbol("chevron_left", size: 18, color: 0xFFC4BDB3)

  def trailing({:text, label}) do
    ~MOB"""
    <Text text={label} font_family="fa" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
    """
  end

  def trailing({:toggle, on?}), do: toggle(on?)

  def trailing({:segmented, options}) do
    [first | rest] = options

    ~MOB"""
    <Row background={0xFFEFECE7} corner_radius={12} padding={3} align="center">
      {Kati.Screens.SettingsFa.segment(first, true)}
      {Enum.map(rest, fn label -> Kati.Screens.SettingsFa.segment_slot(label) end)}
    </Row>
    """
  end

  # The 3pt gap belongs to the segments after the first, so the trough's own
  # 3pt padding is not doubled at the leading edge.
  @doc false
  def segment_slot(label) do
    ~MOB"""
    <Row align="center">
      <Spacer size={3} />
      {Kati.Screens.SettingsFa.segment(label, false)}
    </Row>
    """
  end

  @doc false
  def segment(label, on?) do
    background = if on?, do: Theme.card(:light), else: 0x00FFFFFF
    color = if on?, do: Theme.ink(), else: 0xFFA0998F

    ~MOB"""
    <Row height={26} corner_radius={9} background={background} padding_left={10} padding_right={10} align="center">
      <Text
        text={label}
        font_family="fa"
        text_size={10.5}
        font_weight="semibold"
        text_color={color}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The design's own switch: a 46x28 track, a 22pt thumb, a 3pt inset.

  The inset comes from a 40pt inner row rather than from padding, because
  mixing `padding` with an explicit `width` on one node inflates it on this
  bridge instead of insetting it. The thumb takes the trailing edge when on —
  and under RTL that is the physical left, which is exactly what the drawing
  shows, with no mirroring code of its own.
  """
  def toggle(on?) do
    track = if on?, do: Theme.ink(), else: 0xFFDCD7CF

    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={track} align="center">
      <Row width={40} align="center">
        {Kati.Screens.SettingsFa.thumb_lead(on?)}
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
        {Kati.Screens.SettingsFa.thumb_trail(on?)}
      </Row>
    </Box>
    """
  end

  @doc false
  def thumb_lead(true), do: ~MOB"<Spacer weight={1.0} />"
  def thumb_lead(false), do: ~MOB"<Spacer size={0} />"

  @doc false
  def thumb_trail(true), do: ~MOB"<Spacer size={0} />"
  def thumb_trail(false), do: ~MOB"<Spacer weight={1.0} />"

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}
end
