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

  The switch **is** `Kati.Components.MishkaSwitch`, in `render: :box`. It was
  drawn from boxes here for as long as the component had only one rendering —
  Compose's `Switch`, at Material's own fixed 52x32 with a growing handle,
  against a drawing that specifies 46x28 and a 22pt thumb. `render: :box`
  draws the same two boxes from the same numbers, so the shape moved into the
  component and the pixels did not move at all. See `toggle/1`.

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
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaSwitch
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :account, Sample.account())

  @doc false
  def content(assigns) do
    a = assigns.account

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
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
        {Kati.Screens.Account.disc("more_horiz")}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc opposite the back pill.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon" — which is what a disc is, and which it could not be until the container
  took a `shadow`. A disc is *defined* by floating: `variant: :filled` paints
  `#FBFAF8` and stops, and on this screen's paper that reads as a pale patch
  rather than as a button sitting above it.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns

      %{type: :box,
        props: %{width: 44, height: 44, align: :center, corner_radius: 22,
                 background: Palette.card(), shadow: Kati.Theme.shadow_button()},
        children: [glyph]}

  — the same seven keys with the same seven values the hand-rolled `<Box>`
  carried; `Palette.card/0` is `0xFFFBFAF8` in light, which is what that `<Box>`
  wrote. `align: :center` and `align="center"` reach the bridge as the same
  string, since `align` is in none of the renderer's token whitelists and
  `:json.encode/1` writes an atom as its own name.

  Nothing else in the component runs: `:filled` has no gradient layer,
  `skin(:filled, …)` proposes no border so `put_some/3` omits `border_color` and
  `border_width` entirely rather than writing nils, and the id markers are
  skipped without an `id`. The glyph goes in as a child because the `icon`
  shorthand builds a `Text` with no `font_family`, which would typeset the
  ligature `"more_horiz"` as the word.
  """
  def disc(icon) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        # `card`, not `on_ink` / `fab_glyph` / `on_media` — the other three
        # meanings `Kati.Theme.Palette` gives `0xFFFBFAF8`. A disc is a surface
        # floating above the page, so it follows the ground and goes `#1E1D1B`
        # in dark, like every other card on this screen.
        color: Palette.card(),
        size: 44,
        radius: 22,
        shadow: Kati.Theme.shadow_button()
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Account"
        text_size={28}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text="sync & access"
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The muted eyebrow: the design's `#C4BDB3` dash instead of the accent."
  def quiet_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
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
        background={Palette.card()}
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
          text_color={Palette.muted()}
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
      background: Palette.placeholder()
    )
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def action(label) do
    ~MOB"""
    <Box weight={1.0} height={42} corner_radius={21} background={Palette.paper()} align="center">
      <Text
        text={label}
        text_size={12.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
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
        background={Palette.card()}
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
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
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
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.ink_soft())]
    )
  end

  @doc false
  def trailing(row) do
    cond do
      Map.has_key?(row, :pill) -> Kati.Screens.Account.pill(row.pill)
      Map.has_key?(row, :toggle) -> Kati.Screens.Account.toggle(row.toggle)
      # `rail_idle`, which is right by value and wrong by name: the token whose
      # MEANING is "a faint chevron" is `tertiary`, but its light value is
      # `0xFFB3ACA2` and this chevron is `0xFFC4BDB3`. The design draws two
      # chevron greys and only one of them is `tertiary`; taking the better name
      # would move light mode eleven units, so the value wins. Same call as
      # `Kati.UI.SettingsList.chevron/0`.
      true -> Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())
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

  @doc """
  The **Allow** button a never-asked permission carries instead of a switch.

  `Kati.Components.MishkaPill`, now that the pill takes a `height`, per-edge
  padding and a numeric `text_size` — 30 tall, 15 of radius, 12 of side padding
  and an 11.5pt semibold label are the five numbers the drawing gives, and none
  of them was expressible before. It is the same recipe as
  `Kati.UI.SettingsList.action_pill/1`, which is the point: the drawing draws
  one paper button and this screen should not draw a second one.

  ## `padding: 0` is load-bearing

  The pill pads before it sizes, and its `padding` default is `:space_sm`. Left
  alone that token is the fallback for the two edges this does not name, so a
  `height: 30` pill would measure 30 plus two paddings. `padding: 0` makes the
  vertical fallback zero; the bridge's `hasEdge` arm then resolves top and
  bottom to `uniform ?: 0`, which is the same `Modifier.padding` call the
  hand-rolled `Row` produced by writing no vertical padding at all.

  ## Why the pixels do not move

  The container changes from a `Row` to a `Box`, and both build the same
  modifier chain — `nodeModifier` is one function for every node type, so the
  background, the radius, the padding and the height are applied identically.
  What differs is how the container hugs and where its content sits:

    * a `Row` hugs its width; a `Box` hugs only when told, and MishkaPill's root
      passes `fill_width={false}`, which fence K-17 now honours in the bridge's
      box branch (`hugs = boolProp(props, "fill_width") == false`). Same width;
    * the `Row` centred its child with `verticalAlignment`; the `Box` centres it
      with `align: :center`. Same 30pt box, same centred label;
    * the label gains two wrappers — MishkaPill's body `Row`, and the empty
      `<Row />` that stands in for the ✕ when `with_remove` is false. Both hug,
      the empty one measures 0x0, and a `Row` given no `align` already defaults
      to `Alignment.CenterVertically` (`rowAlignProp`), so neither shifts
      anything.

  `max_lines: 1` is the component's own and matches what this passed: a Compose
  `Text` squeezed narrower than its content wraps character by character, so a
  pill that does not quite fit its row would render as a stack of letters.
  """
  def pill(label) do
    MishkaPill.pill(
      label: label,
      background: Palette.paper(),
      color: :on_surface,
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc """
  The design's own switch, as `Kati.Components.MishkaSwitch` in `render: :box`.

  46x28 with a 22pt thumb and a 3pt inset — the drawing's numbers, passed
  rather than rebuilt. `thumb_offset/4` owns the placement and resolves to
  -9 off and +9 on, which is the 3..25 / 21..43 span the 40pt inner Row and its
  weighted Spacers used to produce.

  The moduledoc used to explain, correctly, why the component was no help here.
  `render: :box` is the answer to it: it draws a track `Box` carrying a thumb
  `Box` and takes the metrics as props, so Material's fixed 52x32 is no longer
  the only shape the component can produce. Both notes are corrected rather
  than deleted, because the reason `render: :toggle` is still the default is
  the same reason they were written.

  No `on_toggle`: `row/4` puts the tap on the whole row, so the switch is
  drawing only — see the comment there.
  """
  def toggle(on?) do
    MishkaSwitch.switch(
      render: :box,
      checked: on?,
      track_width: 46,
      track_height: 28,
      track_radius: 14,
      thumb_size: 22,
      thumb_radius: 11,
      thumb_inset: 3,
      # The whole control inverts rather than following the ground, which is
      # what the design does with every ink-filled control: `ink_fill` under
      # `on_ink`, the pair screen 28 draws for the hero's CTA pill. Both thumb
      # colours stay ONE token — the drawing's thumb does not change colour,
      # only the track does, and that has to stay true in dark.
      track_on_color: Palette.ink_fill(),
      track_off_color: Palette.track_off(),
      thumb_on_color: Palette.on_ink(),
      thumb_off_color: Palette.on_ink(),
      thumb_shadow: "0 1 3 0 #4D1A1917"
    )
  end

  @doc false
  def privacy(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
        {Kati.UI.symbol("lock", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Text
          text={a.privacy_note}
          text_size={12.5}
          line_height={1.55}
          text_color={Palette.cream_body()}
          weight={1.0}
        />
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two rows.

  `Kati.Components.MishkaSeparator` is what a 1px rule between rows is, so the
  rule is its — with `render: :box`, which is the word that makes it match.

  ## Why `render: :box`

  The component's default `:divider` maps to Material3's `HorizontalDivider`,
  which is **not** `Box(fillMaxWidth().height(t).background(c))` as this file
  previously claimed but an antialiased `drawLine`. At this device's 2.6875x a
  1dp rule gets a 3px canvas and a 2.6875px stroke centred in it, so the last
  pixel row lands at ~69% coverage — a full-width row 4-5/255 lighter than the
  two above it. The drawing paints a flat 7% hairline, and no `color` or
  `thickness` recovers that, because the softness lives in the primitive.

  `render: :box` builds

      <Box fill_width={true} height={1} background={0x121A1917}>
        <Spacer size={1} />
      </Box>

  — the same three modifiers this file wrote by hand before adopting the
  component. The `Spacer` is an iOS workaround for `MobBox` dropping a Box's
  `height` when it has no `width`; on Android the Box's own `height` pins the
  rule and `MobSpacer` paints nothing.

  The 7% survives because `color` is an ARGB int: it is in the renderer's
  `@color_props` whitelist and an integer reaches `colorProp` untouched.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

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
