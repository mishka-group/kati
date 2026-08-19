defmodule Kati.Screens.PlanShare do
  @moduledoc """
  Screen 50 — share, import & export a plan, pushed under Plans.

  Built to `.scratch/design/screens/50.html`. A plan is a portable document:
  a QR code or a link hands it over, an explicit list states what travels with
  it, and history never leaves the device. Import accepts the same file export
  produces, which is the only reason the two live on one screen.

  The QR sits on cream — the palette's one warm surface, used here for the same
  reason screen 08 uses it for a note: this block is *yours to give away*
  rather than metadata about the plan.

  **Shared with** draws two different trailing controls on purpose. Following
  is revocable, so it is a switch; a copy someone already took is a past event,
  so it is a glyph. A switch there would imply a power the app does not have.

  All three lists are `Kati.UI.SettingsList`; the people rows pass their own
  body because the drawing sets a person at 13/11 rather than the settings
  family's 13.5/11.5, and their avatar is a 34pt circle rather than a tile.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Plans"

  alias Kati.Meals.SampleShare
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :share, SampleShare.share())

  @doc false
  def content(assigns) do
    share = assigns.share

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title(share.plan, share.subtitle)}
        {Kati.Screens.PlanShare.qr_card(share)}
        {UI.eyebrow("What travels with it")}
        {Kati.Screens.PlanShare.travels(share.travels)}
        {SettingsList.eyebrow_muted("Shared with")}
        {Kati.Screens.PlanShare.shared_with(share.shared_with)}
        {SettingsList.eyebrow_muted("Import & export")}
        {Kati.Screens.PlanShare.transfer(share.transfer)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def qr_card(share) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={20}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.PlanShare.qr_plate(share.qr)}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={16} />
        <Text
          text={share.qr_title}
          text_size={15}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={6} />
        <Text
          text={share.qr_uri}
          font_family="mono"
          text_size={10.5}
          text_color={0xFFB09A72}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={16} />
        {Kati.Screens.PlanShare.qr_actions()}
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # 9 modules of 8pt with 2pt gaps is 88pt, centred inside a 120pt plate —
  # the drawing's own arithmetic, kept so the quiet zone stays 16pt on each
  # side rather than whatever a percentage would land on.
  @doc false
  def qr_plate(rows) do
    ~MOB"""
    <Box
      width={120}
      height={120}
      corner_radius={20}
      background={Kati.Theme.card(:light)}
      shadow="0 8 20 -10 #8078501E"
      align="center"
    >
      <Column>
        {rows
         |> Enum.map(fn row -> Kati.Screens.PlanShare.qr_row(row) end)
         |> Enum.intersperse(Kati.Screens.PlanShare.qr_gap())}
      </Column>
    </Box>
    """
  end

  @doc false
  def qr_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def qr_row(row) do
    ~MOB"""
    <Row>
      {row
       |> String.graphemes()
       |> Enum.map(fn cell -> Kati.Screens.PlanShare.qr_module(cell) end)
       |> Enum.intersperse(Kati.Screens.PlanShare.qr_gap())}
    </Row>
    """
  end

  @doc false
  def qr_module("1") do
    ~MOB"<Box width={8} height={8} corner_radius={1} background={Kati.Theme.ink()} />"
  end

  def qr_module(_light), do: ~MOB"<Box width={8} height={8} />"

  @doc false
  def qr_actions do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Box fill_width={true} height={42} corner_radius={21} background={Kati.Theme.ink()} align="center">
          <Row align="center">
            {Kati.UI.symbol("link", size: 17, color: 0xFFFBFAF8)}
            <Spacer size={7} />
            <Text text="Copy link" text_size={12.5} font_weight="semibold" text_color={0xFFFBFAF8} max_lines={1} />
          </Row>
        </Box>
      </Box>
      <Spacer size={9} />
      <Box weight={1.0}>
        <Box fill_width={true} height={42} corner_radius={21} background={0xA6FFFFFF} align="center">
          <Row align="center">
            {Kati.UI.symbol("ios_share", size: 17, color: 0xFF96723C)}
            <Spacer size={7} />
            <Text text="Share" text_size={12.5} font_weight="semibold" text_color={0xFF8A7B60} max_lines={1} />
          </Row>
        </Box>
      </Box>
    </Row>
    """
  end

  @doc false
  def travels(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(Kati.Screens.PlanShare.tile_rows(rows))}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def transfer(rows) do
    Kati.UI.SettingsList.card(Kati.Screens.PlanShare.tile_rows(rows))
  end

  # One row shape for both lists. A row that carries an `on` key is a promise
  # you can revoke, so it gets a switch; one that does not is a disclosure.
  @doc false
  def tile_rows(rows) do
    last = length(rows) - 1

    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, i} ->
      SettingsList.row(
        SettingsList.icon_tile(row.icon),
        SettingsList.body(row.title, row.sub),
        Kati.Screens.PlanShare.tile_trail(row),
        rule: i < last
      )
    end)
  end

  @doc false
  def tile_trail(%{on: on?}), do: SettingsList.switch(on?)
  def tile_trail(_row), do: SettingsList.chevron()

  @doc false
  def shared_with(rows) do
    last = length(rows) - 1

    people =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          Kati.Screens.PlanShare.avatar(row.seed),
          Kati.Screens.PlanShare.person_body(row),
          Kati.Screens.PlanShare.person_trail(row.trail),
          padding: 11,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(people)}
      <Spacer size={22} />
    </Column>
    """
  end

  # 13/11 rather than the settings family's 13.5/11.5 — a person is set a shade
  # smaller than a setting in this drawing.
  @doc false
  def person_body(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={row.name} text_size={13} font_weight="semibold" text_color={:on_surface} max_lines={1} />
      <Spacer size={2} />
      <Text text={row.sub} text_size={11} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def avatar(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={34} height={34} corner_radius={17} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={34} height={34} corner_radius={17} content_mode="fill" />
        """
    end
  end

  @doc false
  def person_trail({:toggle, on?}), do: SettingsList.switch(on?)
  def person_trail({:icon, name}), do: Kati.UI.symbol(name, size: 17, color: 0xFFC4BDB3)
end
