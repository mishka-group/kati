defmodule Kati.Screens.SeriesSettings do
  @moduledoc """
  Screen 35 — per-show settings, pushed under Series.

  Built to `.scratch/design/screens/35.html`. Three grouped lists in the usual
  card rhythm, over one thing that is not a list: the **Status** row, where
  watching / paused / dropped are three tiles of equal weight with one filled
  ink. The design's caption is explicit that this is the point — state as "a
  first-class choice rather than a swipe action" — so it is drawn as a choice
  and not as a switch with a hidden third value.

  The last eyebrow's dash is grey rather than accent. Orange means new or now,
  and **This show** is a set of things you do *to* the show — reset, archive,
  remove — rather than a peer of the two groups above it, so it takes
  `Kati.UI.SettingsList.eyebrow_muted/1`.

  The final row is the only one in the Settings subtree drawn in `#B4553C`:
  a red tile, a red label and no second line. It gets its own leading and body
  here rather than a `danger:` flag threaded through the shared helper, which
  would put a colour decision inside a component that has no opinion about
  meaning.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Series"

  alias Kati.SeriesSettings.Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :show, Sample.show())

  @doc false
  def content(assigns) do
    show = assigns.show

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome("more_horiz", 44)}
        {SettingsList.title(show.title, show.subtitle)}
        {UI.eyebrow(show.status_label)}
        {Kati.Screens.SeriesSettings.statuses()}
        {UI.eyebrow(show.season_pass_label)}
        {Kati.Screens.SeriesSettings.group(Kati.SeriesSettings.Sample.season_pass())}
        {UI.eyebrow(show.region_label)}
        {Kati.Screens.SeriesSettings.group(Kati.SeriesSettings.Sample.region())}
        {SettingsList.eyebrow_muted(show.this_show_label)}
        {Kati.Screens.SeriesSettings.last_group(Kati.SeriesSettings.Sample.this_show())}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def statuses do
    tiles =
      Sample.statuses()
      |> Enum.map(&Kati.Screens.SeriesSettings.status/1)
      |> Enum.intersperse(Kati.Screens.SeriesSettings.status_gap())

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
  def status_gap, do: ~MOB"<Spacer size={8} />"

  # The chosen tile carries a heavier, tighter shadow than the card recipe —
  # `0 12px 24px -14px rgba(26,25,23,.9)` — so it reads as pressed into the
  # paper rather than floating over it like its two neighbours.
  @doc false
  def status(%{on: true} = s) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        corner_radius={18}
        background={Kati.Theme.ink()}
        shadow="0 12 24 -14 #E61A1917"
        padding_left={10}
        padding_right={10}
        padding_top={14}
        padding_bottom={14}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.UI.symbol(s.icon, size: 21, color: 0xFFFBFAF8)}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
        <Text text={s.label} text_size={12} font_weight="bold" text_color={0xFFFBFAF8} text_align="center" max_lines={1} />
      </Column>
    </Box>
    """
  end

  def status(s) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        corner_radius={18}
        background={Kati.Theme.card(:light)}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={10}
        padding_right={10}
        padding_top={14}
        padding_bottom={14}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.UI.symbol(s.icon, size: 21, color: 0xFF8A8479)}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
        <Text text={s.label} text_size={12} font_weight="bold" text_color={0xFF5C574F} text_align="center" max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.SeriesSettings.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  # The last group closes the frame, so it carries no trailing gap.
  @doc false
  def last_group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.SeriesSettings.row(row, i < last) end)

    SettingsList.card(body)
  end

  @doc false
  def row(%{danger: true} = row, rule?) do
    SettingsList.row(
      Kati.Screens.SeriesSettings.danger_tile(row.icon),
      Kati.Screens.SeriesSettings.danger_body(row.title),
      SettingsList.chevron(),
      padding: 13,
      rule: rule?
    )
  end

  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.SeriesSettings.control(row.control),
      padding: 13,
      rule: rule?
    )
  end

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  @doc "The 30x30 tile at 10% red — the one destructive affordance on the screen."
  def danger_tile(name) do
    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={0x1AB4553C} align="center">
      {Kati.UI.symbol(name, size: 17, color: 0xFFB4553C)}
    </Box>
    """
  end

  @doc false
  def danger_body(title) do
    ~MOB"""
    <Text text={title} text_size={13.5} font_weight="semibold" text_color={0xFFB4553C} max_lines={1} />
    """
  end
end
