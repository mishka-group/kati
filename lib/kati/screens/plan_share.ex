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
  alias Kati.Theme.Palette
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
        background={Palette.cream()}
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
          text_color={Palette.cream_meta()}
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
  #
  # ## Why the plate does not follow the mode
  #
  # `Palette.card(:light)` and `Palette.ink(:light)`, pinned, and they are the
  # only pinned colours on this screen. A QR code is a MACHINE-readable mark,
  # which puts it in the family `Kati.Theme.Palette` calls `:media` — "a colour
  # whose ground is a photograph ... a photograph does not get lighter when the
  # app does". Let the plate follow the mode and the code inverts: light
  # modules on a dark plate, which most readers will not decode, and the plate
  # itself (`#1E1D1B`) sinks BELOW the cream card it is supposed to lift off
  # (`#2A2622`), so the shadow reads as a hole. Light mode is untouched either
  # way — `Palette.card(:light)` is `0xFFFBFAF8` exactly, the value that was
  # written here before.
  @doc false
  def qr_plate(rows) do
    ~MOB"""
    <Box
      width={120}
      height={120}
      corner_radius={20}
      background={Palette.card(:light)}
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
    ~MOB"<Box width={8} height={8} corner_radius={1} background={Palette.ink(:light)} />"
  end

  def qr_module(_light), do: ~MOB"<Box width={8} height={8} />"

  # `0xA6FFFFFF` is LEFT as a literal. It is `rgba(255,255,255,.65)` — a patch
  # raised a step off the cream card, which is exactly what
  # `Kati.Theme.Palette`'s `cream_raise/0` means — but `cream_raise` is
  # `0x99FFFFFF`, .60 rather than .65, and taking it would move light-mode
  # pixels by an alpha step. The only token whose LIGHT value is `0xA6FFFFFF`
  # is `lock_ink_65`, a `:media` colour that means "a lock-screen widget's
  # second line over the wallpaper" and is deliberately IDENTICAL in dark;
  # 65% white over the dark cream card is not what this pill wants. Neither
  # token fits, so the palette owns the answer, not this screen.
  @doc false
  def qr_actions do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Box fill_width={true} height={42} corner_radius={21} background={Palette.ink_fill()} align="center">
          <Row align="center">
            {Kati.UI.symbol("link", size: 17, color: Palette.on_ink())}
            <Spacer size={7} />
            <Text text="Copy link" text_size={12.5} font_weight="semibold" text_color={Palette.on_ink()} max_lines={1} />
          </Row>
        </Box>
      </Box>
      <Spacer size={9} />
      <Box weight={1.0}>
        <Box fill_width={true} height={42} corner_radius={21} background={0xA6FFFFFF} align="center">
          <Row align="center">
            {Kati.UI.symbol("ios_share", size: 17, color: Palette.gold_text())}
            <Spacer size={7} />
            <Text text="Share" text_size={12.5} font_weight="semibold" text_color={Palette.cream_sub()} max_lines={1} />
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
      <Text text={row.sub} text_size={11} text_color={Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  @doc """
  The 34pt circular face a **Shared with** row leads with.

  `Kati.Components.MishkaAvatar` rather than a hand-rolled `case`: this is an
  image with a fallback, which is the whole of what that component is, and it
  owns the one thing the `case` got slightly wrong — the fallback is *stacked
  under* the image rather than swapped for it, so a row that is waiting on a
  file still draws the drawing's `#E4E0D9` disc instead of bare paper.

  ## Why the pixels do not move

  `shape: :circle` resolves its radius as `size / 2` — 17.0, the number this
  wrote by hand, and `corner_radius` goes through `floatProp` so nothing is
  truncated. With a `src` the component returns a 34pt wrapper `Box` holding
  `[fallback, image]`: the wrapper carries only `corner_radius`, which
  `nodeModifier` turns into `Modifier.clip(RoundedCornerShape(17.dp))` over
  children that are already 34pt circles, so the clip is a no-op; and the
  image is the same node as before — 34x34, radius 17, `content_mode="fill"`
  — painted last and therefore on top. Without a `src` the fallback stands
  alone, at the same size, radius and `#E4E0D9` the old nil clause drew, plus
  an empty `initials` `Text` that is centred inside a fixed 34pt box and so
  measures nothing.

  `background` has to be passed: the component's default is `:surface_raised`,
  which in `Kati.Theme.light/0` is `#FBFAF8` — the card, not the placeholder.
  """
  def avatar(seed) do
    Kati.Components.MishkaAvatar.avatar(
      src: Kati.Design.Images.poster(seed),
      size: 34,
      shape: :circle,
      background: Palette.placeholder()
    )
  end

  @doc false
  def person_trail({:toggle, on?}), do: SettingsList.switch(on?)
  def person_trail({:icon, name}), do: Kati.UI.symbol(name, size: 17, color: Palette.rail_idle())
end
