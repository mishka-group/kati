defmodule Kati.Screens.Account do
  @moduledoc """
  Screen 40 — Account & permissions, pushed under Settings.

  Built to `.scratch/design/screens/40.html`. The account card is deliberately
  small: a relay address, the fact that no email was shared, and two buttons.
  Below it the devices that sync, then every permission with the sentence
  saying what it is for, then privacy — the cream card claiming there is no
  server to read any of it, and the two rows that make that checkable.

  Three trailing controls, and which one a row gets is the row's meaning:

    * a **switch** for something already granted and now on or off;
    * an **Allow** pill for something never requested, so an off switch cannot
      be mistaken for a refusal;
    * a **chevron** for something that leads elsewhere.

  The switch is drawn from boxes rather than taken from
  `Kati.Components.MishkaSwitch` — Compose's `Switch` brings Material's own
  52x32 metrics, and the drawing specifies 46x28 with a 22pt thumb.

  No dock, so the frame's bottom inset is 40 rather than 132.

  ## The switches and the Allow pill are live

  Tapping a permission row flips its switch; tapping the Allow row grants the
  permission, which — by the rule above — means the pill *becomes* a switch,
  on. Nothing is added: the drawing already contains both shapes, and the
  screen just moves a row from one to the other.

  The drawn state is the sample's own, so the resting screen is unchanged:
  Notifications unasked, Calendars, Photos and Local network on, Microphone
  and Share anonymous usage off.

  Chevron rows carry no tap. A chevron means *leads elsewhere*, and there is
  nowhere yet for a device or Delete everything to lead — the rule
  `Kati.Screens.Series.episode/1` applies to an unaired episode.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Account.Sample
  alias Kati.Components.MishkaAvatar
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :account, Sample.account())

  @doc false
  def content(assigns) do
    a = assigns.account

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Account.header()}
        {Kati.Screens.Account.title()}
        {Kati.Screens.Account.identity(a)}
        {UI.eyebrow("Devices")}
        {Kati.Screens.Account.list(a.devices, 22, "device_")}
        {UI.eyebrow("Permissions")}
        {Kati.Screens.Account.list(a.permissions, 22, "perm_")}
        {Kati.Screens.Account.quiet_eyebrow("Privacy")}
        {Kati.Screens.Account.privacy(a)}
        {Kati.Screens.Account.list(a.data, 0, "data_")}
      </Column>
    </Scroll>
    """
  end

  # 44pt reserves the row the back pill floats in — the pill is drawn by
  # Kati.Screens.Pushed — so the overflow disc sits opposite it.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Account" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text="sync & access" font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The muted eyebrow: the design's `#C4BDB3` dash instead of the accent."
  def quiet_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFC4BDB3} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def identity(a) do
    i = a.identity

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={22}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.Account.avatar(i)}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text={i.name}
          text_size={18}
          font_weight="bold"
          letter_spacing={-0.025}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={i.relay}
          font_family="mono"
          text_size={10.5}
          text_color={0xFFA9A29A}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={16} />
        <Row fill_width={true} align="center">
          {i.actions
           |> Enum.map(fn label -> Kati.Screens.Account.action(label) end)
           |> Enum.intersperse(Kati.Screens.Account.action_gap())}
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 64pt face, drawn by `Kati.Components.MishkaAvatar`.

  A circular image with a fill behind it for when there is no image is the
  whole of what an avatar is, so the two clauses this used to carry collapse
  into one call: the component takes `src` as `nil` and renders the fallback
  alone, which is exactly what the missing-poster clause drew.

  ## Why the pixels do not move

  `shape: :circle` is an exact `size / 2` radius rather than a token, so 64
  gives 32 — the drawing's own number. With a `src` the component stacks
  `[fallback, image]` inside a 64x64 `Box`, and the image is the same
  `width=64 height=64 corner_radius=32 content_mode="fill"` node this wrote by
  hand, painted over a fallback of identical size and radius; the fallback's
  `Text` carries no initials, so it contributes no glyph. Without a `src` the
  fallback stands alone: a 64x64 `Box` at radius 32 filled `#E4E0D9`.

  `initials` is deliberately not passed. The drawing shows a photograph and
  nothing behind it, and a person's initials over their own face is a detail
  the export does not contain.
  """
  def avatar(i) do
    MishkaAvatar.avatar(
      src: Kati.Design.Images.poster(i.seed),
      size: 64,
      shape: :circle,
      background: 0xFFE4E0D9
    )
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def action(label) do
    ~MOB"""
    <Box weight={1.0} height={42} corner_radius={21} background={0xFFEFECE7} align="center">
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
    </Box>
    """
  end

  # One card recipe for all three lists — the drawing uses the same 4/15 card
  # and the same 13pt rows for devices, permissions and the privacy pair.
  #
  # `prefix` names which list a tap came from, so one row recipe can serve
  # three lists whose rows mean different things: "perm_2" and "data_0" reach
  # different collections in `handle_tap/2`.
  @doc false
  def list(rows, gap, prefix) do
    last = length(rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Account.row(row, i < last, prefix, i) end)}
      </Column>
      <Spacer size={gap} />
    </Column>
    """
  end

  # The tap sits on the row rather than on the switch or the pill: 46x28 and
  # the 30pt pill are both under the 44x44 screen 41 promises, and the row is
  # 56 tall. Compose's `clickable` paints only on press, so the resting
  # drawing is untouched.
  @doc false
  def row(row, rule?, prefix, i) do
    tap = Kati.Screens.Account.row_tap(row, prefix, i)

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Account.icon_tile(row.icon)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Account.trailing(row)}
      </Row>
      {Kati.Screens.Account.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The 30x30 paper tile every row leads with, from
  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is what this is.

  The same swap `Kati.UI.SettingsList.icon_tile/1` makes for the settings rows,
  and every number is still the drawing's: 30dp square, radius 9, `#EFECE7`
  paper, glyph at 17 in `#5C574F`. `variant: :filled` with an explicit `color`,
  **not** `variant: :white` — the white variant paints the theme's `:surface`,
  which here is `#FBFAF8`, the card the tile sits on.

  The glyph goes in as a child rather than through the `icon` prop: that
  shorthand builds its own `Text` with no `font_family`, so a Material Symbols
  ligature like `"photo_library"` would be typeset as the word.

  With children and no `id`, `theme_icon/2` returns the same `:box` node with
  the same five props this wrote by hand, so nothing moves.
  """
  def icon_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: 0xFFEFECE7, size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: 0xFF5C574F)]
    )
  end

  @doc false
  def trailing(row) do
    cond do
      Map.has_key?(row, :pill) -> Kati.Screens.Account.pill(row.pill)
      Map.has_key?(row, :toggle) -> Kati.Screens.Account.toggle(row.toggle)
      true -> Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)
    end
  end

  @doc """
  The tap a row carries, or `nil` when it carries none.

  The same fact `trailing/1` reads decides this too, which is the point of the
  three shapes: a pill and a switch are both things you do here, a chevron is
  a door to a screen this build does not have. A tap that silently does
  nothing would be worse than no tap at all.

  The index rather than the title, following `Kati.Screens.Widgets`: the tag
  has to survive a round trip through `String.to_atom/1`.
  """
  @spec row_tap(map(), String.t(), non_neg_integer()) :: {pid(), atom()} | nil
  def row_tap(row, prefix, i) do
    if Map.has_key?(row, :toggle) or Map.has_key?(row, :pill) do
      {self(), String.to_atom(prefix <> Integer.to_string(i))}
    end
  end

  @doc false
  def pill(label) do
    ~MOB"""
    <Row height={30} corner_radius={15} background={0xFFEFECE7} padding_left={12} padding_right={12} align="center">
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
    </Row>
    """
  end

  @doc """
  The design's own switch, drawn rather than delegated.

  46x28 with a 22pt thumb and a 3pt inset. The 40pt inner row produces that
  inset without mixing `padding` and an explicit `width` on one node, which in
  this bridge inflates the node instead of insetting it.
  """
  def toggle(on?) do
    track = if on?, do: Kati.Theme.ink(), else: 0xFFDCD7CF

    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={track} align="center">
      <Row width={40} align="center">
        {Kati.Screens.Account.thumb_lead(on?)}
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
        {Kati.Screens.Account.thumb_trail(on?)}
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
  def privacy(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFFBF1DE} corner_radius={20} padding={16} align="top">
        {Kati.UI.symbol("lock", size: 18, color: 0xFFC98A3E)}
        <Spacer size={11} />
        <Text
          text={a.privacy_note}
          text_size={12.5}
          line_height={1.55}
          text_color={0xFF4A4238}
          weight={1.0}
        />
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  # `Kati.Components.MishkaSeparator` is what a 1px rule between rows is, so
  # the rule is its. Its plain variant is a `<Divider>`, and the bridge's
  # `MobDivider` renders Compose's `HorizontalDivider(thickness, color)` —
  # defined as `Box(modifier.fillMaxWidth().height(thickness).background(color))`,
  # the same three modifiers this wrote by hand. The drawing's 7% ink survives
  # because `color` is an ARGB int: it is in the renderer's `@color_props`
  # whitelist, and an integer reaches `colorProp` untouched.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: MishkaSeparator.separator(color: 0x121A1917, thickness: 1)

  @doc "The list a tap leaves behind, with the tapped row flipped."
  @spec flip([map()], String.t()) :: [map()]
  def flip(rows, index) do
    List.update_at(rows, String.to_integer(index), &Kati.Screens.Account.flipped/1)
  end

  @doc """
  What one row becomes when it is tapped.

  Granting a never-asked permission turns the pill into the switch the drawing
  gives an already-granted one — the moduledoc's rule run forwards. The
  subtitle loses its "Not yet asked" half and keeps the rest, because that is
  the only clause that stopped being true; the surviving sentence is the
  design's own, in the shape the Photos row already uses.

  "Share anonymous usage" prints its state as its subtitle, so the word has to
  follow the switch or the row contradicts itself.
  """
  @spec flipped(map()) :: map()
  def flipped(%{pill: _} = row) do
    row
    |> Map.delete(:pill)
    |> Map.put(:toggle, true)
    |> Map.put(:sub, "Only when you turn one on")
  end

  def flipped(%{toggle: on?, sub: sub} = row) when sub in ["On", "Off"] do
    next = not on?

    %{row | toggle: next, sub: if(next, do: "On", else: "Off")}
  end

  def flipped(%{toggle: on?} = row), do: %{row | toggle: not on?}
  def flipped(row), do: row

  @doc """
  One clause per list rather than per row: the tag carries the index.

  A sixth permission is a line in `Kati.Account.Sample` and nothing here.
  """
  @impl true
  def handle_tap(tag, socket) do
    a = socket.assigns.account

    case Atom.to_string(tag) do
      "perm_" <> i ->
        rows = Kati.Screens.Account.flip(a.permissions, i)
        {:noreply, Mob.Socket.assign(socket, :account, %{a | permissions: rows})}

      "data_" <> i ->
        rows = Kati.Screens.Account.flip(a.data, i)
        {:noreply, Mob.Socket.assign(socket, :account, %{a | data: rows})}

      _ ->
        {:noreply, socket}
    end
  end
end
