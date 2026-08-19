defmodule Kati.Screens.Settings do
  @moduledoc """
  Screen 24 — Settings, pushed under Home.

  Built to `.scratch/design/screens/24.html`. Everything the app can be told,
  in the same card rhythm as every other screen: an account card, then four
  grouped lists.

  The **Sections** group is the growth mechanic made literal. Each row names
  the surfaces its section appears on — "Home card, calendar feed, shelf" —
  so a switch is not an opaque toggle but a statement about what will stop
  being drawn. That is also why Money ships off while the other four ship on:
  the drawing states the default, and defaults are the product.

  The last eyebrow's dash is grey, not orange. Orange means new/now, and About
  is a footnote to Data rather than a peer of it, so it uses
  `Kati.UI.SettingsList.eyebrow_muted/1`.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Settings.Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :settings, %{
      synced: Sample.synced(),
      account: Sample.account(),
      appearance: Sample.appearance(),
      sections: Sample.sections(),
      data: Sample.data(),
      about: Sample.about()
    })
  end

  @doc false
  def content(assigns) do
    s = assigns.settings

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome(nil, 42)}
        {SettingsList.title("Settings", s.synced, "help")}
        {Kati.Screens.Settings.account(s.account)}
        {UI.eyebrow("Appearance")}
        {Kati.Screens.Settings.group(s.appearance, 14, 22)}
        {UI.eyebrow("Sections")}
        {Kati.Screens.Settings.group(s.sections, 13, 22)}
        {UI.eyebrow("Data")}
        {Kati.Screens.Settings.group(s.data, 14, 22)}
        {SettingsList.eyebrow_muted("About")}
        {Kati.Screens.Settings.group(s.about, 14, 0)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def account(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={16}
        align="center"
      >
        {Kati.Screens.Settings.avatar(a)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text text={a.name} text_size={16} font_weight="bold" letter_spacing={-0.02} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={a.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Row height={26} corner_radius={13} background={0x294E9A73} padding_left={10} padding_right={10} align="center">
          {Kati.UI.symbol("cloud_done", size: 14, color: 0xFF3E8460)}
          <Spacer size={5} />
          <Text text={a.status} text_size={11} font_weight="semibold" text_color={0xFF3E8460} max_lines={1} />
        </Row>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def avatar(a) do
    case Kati.Design.Images.poster(a.seed) do
      nil ->
        ~MOB"<Box width={52} height={52} corner_radius={26} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={52} height={52} corner_radius={26} content_mode="fill" />
        """
    end
  end

  @doc false
  def group(rows, pad, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Settings.row(row, pad, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  @doc false
  def row(row, pad, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.Settings.control(row.control),
      padding: pad,
      rule: rule?
    )
  end

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  def control({:segments, options, selected}),
    do: Kati.Screens.Settings.segments(options, selected)

  # The theme picker, at a third of the size of screen 25's. Same trough-and-
  # raised-tile idea, but it lives inside a row rather than spanning the frame,
  # so its segments hug their labels instead of taking a weight.
  @doc false
  def segments(options, selected) do
    tiles =
      options
      |> Enum.map(fn o -> Kati.Screens.Settings.segment(o, o == selected) end)
      |> Enum.intersperse(Kati.Screens.Settings.segment_gap())

    ~MOB"""
    <Row background={0xFFEFECE7} corner_radius={12} padding={3} align="center">
      {tiles}
    </Row>
    """
  end

  @doc false
  def segment_gap, do: ~MOB"<Spacer size={3} />"

  @doc false
  def segment(label, true) do
    ~MOB"""
    <Row
      height={26}
      corner_radius={9}
      background={0xFFFBFAF8}
      shadow="0 1 2 0 #1F1A1917"
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Text text={label} text_size={11} font_weight="semibold" text_color={:on_surface} max_lines={1} />
    </Row>
    """
  end

  def segment(label, false) do
    ~MOB"""
    <Row height={26} corner_radius={9} padding_left={10} padding_right={10} align="center">
      <Text text={label} text_size={11} font_weight="semibold" text_color={0xFFA0998F} max_lines={1} />
    </Row>
    """
  end
end
