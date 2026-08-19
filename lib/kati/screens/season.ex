defmodule Kati.Screens.Season do
  @moduledoc """
  Screen 34 — a season's order and its specials, pushed under Series.

  Built to `.scratch/design/screens/34.html`. Three numbering schemes across
  the top, two switches that decide what counts as an episode, then the list
  those choices produce. The dashed footnote at the bottom is the screen's
  whole argument: **your ticks follow the episode, not the number**, so
  switching from Aired to Absolute renumbers the list without losing a thing.

  Three row states are drawn and all three are exercised:

    * **watched** — `#F4F1EC`, muted title, an ink disc with a white check
    * **aired, not watched** — a lifted `#FBFAF8` card, ink title, empty ring
    * **a special** — the same as watched, but its number is bronze and it
      carries a `SPECIAL` badge, because it is in the order without being in
      the count

  E6 and E7 draw the same empty ring. The export gives E6 a `check` glyph at
  zero alpha and E7 none at all, which is the same picture by two routes; one
  ring, drawn once, is the honest version of it.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Series"

  alias Kati.Season.Sample
  alias Kati.Theme
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :season, Sample.season())

  @doc false
  def content(assigns) do
    s = assigns.season

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome("more_horiz", 44)}
        {SettingsList.title(s.title, s.subtitle)}
        {Kati.Screens.Season.orders(s)}
        {Kati.Screens.Season.options(s)}
        {UI.eyebrow(s.eyebrow)}
        {Kati.Screens.Season.episodes(s)}
        {Kati.Screens.Season.note(s)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def orders(s) do
    tiles =
      s.orders
      |> Enum.map(fn label -> Kati.Screens.Season.order(label, label == s.current_order) end)
      |> Enum.intersperse(Kati.Screens.Season.order_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={16} padding={4} align="center">
        {tiles}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def order_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def order(label, true) do
    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        height={34}
        corner_radius={12}
        background={Kati.Theme.card(:light)}
        shadow="0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"
        align="center"
      >
        <Text text={label} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
      </Box>
    </Box>
    """
  end

  def order(label, false) do
    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} height={34} corner_radius={12} align="center">
        <Text text={label} text_size={12.5} font_weight="semibold" text_color={0xFFAFA89E} max_lines={1} />
      </Box>
    </Box>
    """
  end

  @doc false
  def options(s) do
    rows = s.options
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, row.sub),
          SettingsList.switch(row.on),
          padding: 13,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def episodes(s) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(s.episodes, fn ep -> Kati.Screens.Season.episode(ep) end)}
    </Column>
    """
  end

  @doc false
  def episode(ep) do
    watched? = ep.watched
    bg = if watched?, do: 0xFFF4F1EC, else: Theme.card(:light)
    title_color = if watched?, do: 0xFF9C958B, else: Theme.ink()
    number_color = if Map.get(ep, :special, false), do: 0xFFC98A3E, else: 0xFFB3ACA2

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Season.episode_row(ep, bg, title_color, number_color, watched?)}
      <Spacer size={8} />
    </Column>
    """
  end

  # Two clauses rather than one with a conditional `shadow`, because a watched
  # row sits flat in the paper and an unaired one is lifted off it — that is
  # the difference the drawing uses to say "there is still something to do
  # here", and a nil shadow prop would quietly flatten both.
  @doc false
  def episode_row(ep, bg, title_color, number_color, true) do
    ~MOB"""
    <Row
      fill_width={true}
      background={bg}
      corner_radius={17}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.Screens.Season.episode_body(ep, title_color, number_color)}
      {Kati.Screens.Season.check(true)}
    </Row>
    """
  end

  def episode_row(ep, bg, title_color, number_color, false) do
    ~MOB"""
    <Row
      fill_width={true}
      background={bg}
      corner_radius={17}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.Screens.Season.episode_body(ep, title_color, number_color)}
      {Kati.Screens.Season.check(false)}
    </Row>
    """
  end

  @doc false
  def episode_body(ep, title_color, number_color) do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Column width={22}>
        <Text text={ep.number} font_family="mono" text_size={12} text_color={number_color} max_lines={1} />
      </Column>
      <Spacer size={13} />
      <Column weight={1.0}>
        <Row fill_width={true} align="center">
          <Text
            text={ep.title}
            text_size={14}
            font_weight="semibold"
            text_color={title_color}
            max_lines={1}
          />
          {Kati.Screens.Season.badge(Map.get(ep, :badge))}
        </Row>
        <Spacer size={4} />
        <Text text={ep.sub} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
      </Column>
      <Spacer size={13} />
    </Row>
    """
  end

  @doc false
  def badge(nil), do: ~MOB"<Spacer size={0} />"

  def badge(badge) do
    {bg, fg} =
      case badge.tone do
        :cream -> {Kati.Theme.cream(:light), 0xFF96723C}
        _ -> {0xFFEFECE7, 0xFF5C574F}
      end

    ~MOB"""
    <Row align="center">
      <Spacer size={7} />
      <Row height={18} corner_radius={9} background={bg} padding_left={7} padding_right={7} align="center">
        <Text text={badge.label} text_size={9.5} font_weight="bold" text_color={fg} max_lines={1} />
      </Row>
    </Row>
    """
  end

  @doc false
  def check(true) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} background={Kati.Theme.ink()} align="center">
      {Kati.UI.symbol("check", size: 16, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  def check(false) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} border_width={1.5} border_color={0x291A1917} />
    """
  end

  # Solid, not dashed: `Modifier.border` takes a width and a colour and no
  # PathEffect. The 1.5pt weight, the alpha and this drawing's own 15pt padding
  # are literal; the stitching is what does not survive.
  @doc false
  def note(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={8} />
      <Row
        fill_width={true}
        corner_radius={18}
        border_width={1.5}
        border_color={0x291A1917}
        padding={15}
        align="top"
      >
        {Kati.UI.symbol("info", size: 17, color: 0xFF8A8479)}
        <Spacer size={11} />
        <Text text={s.note} text_size={12.5} line_height={1.55} text_color={0xFF5C574F} weight={1.0} />
      </Row>
    </Column>
    """
  end
end
