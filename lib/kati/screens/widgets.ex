defmodule Kati.Screens.Widgets do
  @moduledoc """
  Screen 39 — Widgets, Shortcuts & share, pushed under Settings.

  Built to `.scratch/design/screens/39.html`: the parts of the app used
  without opening it. Three square widget previews at the top, a wide one
  underneath, the voice shortcuts as a switch list, and the share extension
  described in a card.

  The previews are drawn, not screenshotted — they are the real widget
  layouts at widget scale, which is the only way this screen can be checked
  against the drawing.

  Two literal details worth keeping:

    * the eyebrow above **Share sheet** has a `#C4BDB3` dash rather than the
      accent one, because that section is descriptive rather than actionable.
      `Kati.UI.eyebrow/2` always draws the accent dash, so `quiet_eyebrow/1`
      here is the muted variant;
    * the widget captions (`UP NEXT`, `TONIGHT`, `STREAK`, `TODAY · WIDE`) are
      capitals in the drawing's own copy, not `text-transform`, so they are
      capitals in the data.

  The three shortcut switches are live; the widget previews above them are
  not, and that is deliberate. The eyebrow says **Sizes**, but the drawing
  shows previews rather than a picker: none of the four is drawn selected and
  the three squares carry three different fills, so a selected state would have
  to be invented and the resting frame would move. They stay pictures of
  widgets, which is what they are.

  No dock, so the frame's bottom inset is 40 rather than 132.

  ## The one colour here that is still a literal

  Every other colour on this screen is a `Kati.Theme.Palette` token. The
  TONIGHT tile's caption is not: the drawing sets it in `#6A6560` on the ink
  tile, and `#6A6560` exists in the palette only as a **dark** value — it is
  what `muted`, `tertiary` and `segment_idle` all collapse to on near-black —
  and never as a light one. So no token resolves to it in light, and giving it
  the nearest one (`on_ink_muted`, `#BFB8AC`) would change a baseline frame to
  make dark mode work. It stays `0xFF6A6560` until the table names it; see
  `sizes/1`.

  It happens to land well on the inverted tile anyway — `#6A6560` on
  `ink_fill`'s `#F7EFE4` reads at about 5.5:1 — so the tile is legible in dark
  rather than merely unbroken.

  ## Audited: drawn copy — the tiles are pictures of widgets, not widgets

  **Every string on this screen is `Kati.Widgets.Sample`, and it stays that
  way.** The eyebrow says **Sizes** and the export's own caption says *"four
  widget sizes off one data model"*: what is being shown is the same content at
  four scales, which is a claim about layout rather than about this user's
  evening.

  Three of the four could be read today — `Long Hollow · S2E6` is the hero
  `Kati.Screens.UpNext.queue/0` already assembles from `Kati.Media`, and
  `20:00 · 6 episodes air` is `Kati.Calendars.Today`, which screens 01 and 02
  read. **STREAK · 11 nights cannot**, and that is what decides it: nothing
  anywhere records that a habit was kept — `Kati.Calendars.Override.kind` is
  `:modified | :cancelled`, so an occurrence can be called off and cannot be
  ticked — which is why `Kati.Screens.Habits` is on its Sample outright. Making
  three tiles live would leave one permanently invented sitting in the same row,
  which is the mixture `Kati.Screens.Film` refuses: either every value is this
  user's or every value is the drawing's. The set moves when a habit completion
  exists to count.

  The **shortcut switches** flip locally and are stored nowhere, honestly:
  there is no voice layer in `lib/` at all, so *"Hey Siri, what's next?"* is
  describing a surface Kati does not yet have rather than a setting it keeps.
  A stored boolean would arm nothing.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaSwitch
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.Widgets.Sample

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :widgets, Sample.widgets())

  @doc false
  def content(assigns) do
    w = assigns.widgets

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Widgets.header()}
        {Kati.Screens.Widgets.title()}
        {UI.eyebrow("Sizes")}
        {Kati.Screens.Widgets.sizes(w)}
        {Kati.Screens.Widgets.wide(w)}
        {UI.eyebrow("Shortcuts")}
        {Kati.Screens.Widgets.shortcuts(w)}
        {Kati.Screens.Widgets.quiet_eyebrow("Share sheet")}
        {Kati.Screens.Widgets.share(w)}
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
        {Kati.Screens.Widgets.disc("more_horiz")}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc the header hangs opposite the back pill.

  `Kati.Components.MishkaThemeIcon` is documented as "a themed container around
  exactly one icon", which is precisely what this is — and it could not be one
  until the container took a `shadow`. That is the whole difference here: a disc
  is *defined* by floating. `variant: :filled` paints `#FBFAF8` and stops, which
  on this screen's `#F2EFEA` paper reads as a pale patch rather than as a button
  above it, so before `shadow` existed this had to stay hand-rolled markup.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns

      %{type: :box,
        props: %{width: 44, height: 44, align: :center, corner_radius: 22,
                 background: Palette.card(), shadow: Kati.Theme.shadow_button()},
        children: [glyph]}

  — the same seven keys, with the same seven values, that the `<Box>` above it
  carried. `align: :center` and `align="center"` reach the bridge as the same
  string: `align` is in none of the renderer's token whitelists, so an
  unrecognised atom passes through and `:json.encode/1` writes an atom as its
  own name.

  Nothing else in the component runs. `:filled` contributes no gradient layer;
  `skin(:filled, …)` proposes no border, so `put_some/3` drops both
  `border_color` and `border_width` rather than writing nils; the id markers are
  skipped without an `id`; and the `icon` shorthand is skipped when children are
  given — which is also why the glyph goes in as a child. That shorthand builds
  a `Text` with no `font_family`, so the Material Symbols ligature
  `"more_horiz"` would be typeset as the word instead of resolved to the glyph.

  `Kati.UI.SettingsList.disc/1` is the same call, and both now spell the colour
  `Kati.Theme.Palette.card/0` — the card token, not `on_ink`, `fab_glyph` or
  `on_media`, which are the other three meanings of `0xFFFBFAF8`. A disc is a
  surface that floats above the page, so it follows the ground: `#1E1D1B` in
  dark, like every card.
  """
  def disc(icon) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
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
        text="Widgets"
        text_size={28}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text="add to home screen"
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

  # Three squares. The drawing writes them `flex:1; aspect-ratio:1`, and 113
  # was only ever what that resolved to on the 402dp frame: (360 - 22) / 3 =
  # 112.67. On a 411dp device the weights make each tile 115.67 wide while the
  # declared height stayed 113, so the "squares" were 3dp out and the up-next
  # tile's content — 13 + label + 42 + 7 + title + 2 + episode + 13 — had
  # already outgrown the box it was pinned to. The tiles carry
  # `aspect_ratio={1.0}` instead: the height follows the width the weight
  # actually hands out, at any frame. See `up_next_tile/1`.
  @doc false
  def sizes(w) do
    # The ink tile is an ink-filled surface carrying an `on_ink` number, so it
    # takes screen 28's drawn pair: `ink_fill` under `on_ink`. The cream tile
    # stays in the cream family, headline included — `cream_ink`, not `ink`,
    # because `0xFF1A1917` on cream is the headline meaning of that literal.
    tonight =
      Kati.Screens.Widgets.count_tile(
        w.tonight,
        Palette.ink_fill(),
        # Still a literal, and it has to be: `0xFF6A6560` appears in
        # `Kati.Theme.Palette` only as a DARK value (`muted`, `tertiary`,
        # `segment_idle`), never as a light one, so no token resolves to it in
        # light and naming one would move a baseline frame. See the moduledoc.
        0xFF6A6560,
        Palette.on_ink(),
        Palette.on_ink_meta()
      )

    streak =
      Kati.Screens.Widgets.count_tile(
        w.streak,
        Palette.cream(),
        Palette.cream_meta(),
        Palette.cream_ink(),
        Palette.cream_sub()
      )

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Widgets.up_next_tile(w.up_next)}
        <Spacer size={11} />
        {tonight}
        <Spacer size={11} />
        {streak}
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  # `aspect_ratio` rather than a declared height, and the height has to stay
  # bounded somehow: `fill_height` on the inner Column and the `Spacer
  # weight={1.0}` below it are what produce the drawing's
  # `justify-content:space-between`, and both collapse to nothing the moment
  # the tile wraps its content. The modifier chain is weight → aspect_ratio,
  # so the square is measured off the width the Row actually granted.
  @doc false
  def up_next_tile(tile) do
    ~MOB"""
    <Box
      weight={1.0}
      aspect_ratio={1.0}
      corner_radius={20}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Column fill_width={true} fill_height={true} padding={13}>
        <Text
          text={tile.label}
          font_family="mono"
          text_size={9}
          letter_spacing={0.14}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.Widgets.mini_poster(tile)}
        <Spacer size={7} />
        <Text
          text={tile.title}
          text_size={11}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text
          text={tile.episode}
          font_family="mono"
          text_size={9}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def mini_poster(tile) do
    case Kati.Design.Images.poster(tile.seed) do
      nil ->
        ~MOB"<Box width={30} height={42} corner_radius={5} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={30} height={42} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # The two numeric tiles differ only in their four colours, so they share one
  # function rather than being copied — the drawing's own structure.
  @doc false
  def count_tile(tile, background, label_color, number_color, line_color) do
    ~MOB"""
    <Box
      weight={1.0}
      aspect_ratio={1.0}
      corner_radius={20}
      background={background}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Column fill_width={true} fill_height={true} padding={13}>
        <Text
          text={tile.label}
          font_family="mono"
          text_size={9}
          letter_spacing={0.14}
          text_color={label_color}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={tile.count}
          text_size={34}
          font_weight="extrabold"
          letter_spacing={-0.04}
          text_color={number_color}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text text={tile.line} text_size={10} text_color={line_color} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def wide(w) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Row fill_width={true} align="center">
          <Text
            text={w.today_label}
            font_family="mono"
            text_size={9}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("calendar_month", size: 14, color: Palette.rail_idle())}
        </Row>
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {w.today
           |> Enum.map(fn event -> Kati.Screens.Widgets.wide_event(event) end)
           |> Enum.intersperse(Kati.Screens.Widgets.wide_gap())}
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def wide_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def wide_event(event) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Box width={2.5} height={26} corner_radius={2} background={event.color} />
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text
          text={event.time}
          font_family="mono"
          text_size={9.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text
          text={event.title}
          text_size={11.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  @doc false
  def shortcuts(w) do
    last = length(w.shortcuts) - 1

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
        {w.shortcuts
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Widgets.shortcut_row(row, i, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def shortcut_row(row, i, rule?) do
    tap = Kati.Screens.Widgets.shortcut_tap(row, i)

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Widgets.icon_tile(row.icon)}
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
        {Kati.Screens.Widgets.trailing(row)}
      </Row>
      {Kati.Screens.Widgets.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The 30x30 paper tile a shortcut row leads with, from
  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is what this is.

  The same swap `Kati.UI.SettingsList.icon_tile/1` makes for the settings rows,
  with the drawing's own numbers: 30dp square, radius 9, `#EFECE7` paper, glyph
  at 17 in `#5C574F`. `variant: :filled` with an explicit `color`, not
  `variant: :white` — the white variant paints the theme's `:surface`, which
  here is `#FBFAF8`, the card the tile sits on.

  The glyph is a child rather than the `icon` prop, because that shorthand
  builds a `Text` with no `font_family` and a Material Symbols ligature —
  `"mic"`, `"ios_share"` — would be typeset as the word instead of resolved to
  the glyph.

  With children and no `id`, `theme_icon/2` returns the same `:box` node
  carrying the same five props this wrote by hand, so nothing moves.
  """
  def icon_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.ink_soft())]
    )
  end

  # A switch when the row is a state, a chevron when it leads somewhere.
  @doc false
  def trailing(row) do
    case Map.get(row, :toggle) do
      nil -> Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())
      on? -> Kati.Screens.Widgets.toggle(on?)
    end
  end

  @doc """
  The tap a shortcut row carries, or `nil` when it carries none.

  The same fact `trailing/1` reads decides both: a row with a `toggle` is a
  state and flips, a row with a chevron leads to a screen that does not exist
  yet, so it gets no tap rather than one that silently does nothing — the rule
  `Kati.Screens.Series.episode/1` applies to an unaired episode.
  """
  @spec shortcut_tap(map(), non_neg_integer()) :: {pid(), atom()} | nil
  def shortcut_tap(row, i) do
    case Map.get(row, :toggle) do
      nil -> nil
      _ -> {self(), String.to_atom("shortcut_" <> Integer.to_string(i))}
    end
  end

  @doc """
  The design's own switch, as `Kati.Components.MishkaSwitch` in `render: :box`.

  It used to say the component could not draw this and the shape had to be
  hand-built. That was true of `render: :toggle`, which is Compose's Material
  `Switch` at Material's own 52x32 metrics with a handle that grows from 16 to
  24 on the way on — no prop at any layer reshapes it. It is **not** true of
  `render: :box`, which draws a track `Box` carrying a thumb `Box` and takes
  the drawing's own numbers: 46x28, radius 14, a 22pt thumb at a 3pt inset.

  `thumb_offset/4` places the thumb, so the arithmetic is not repeated here.
  It resolves to -9 off and +9 on, which is the 3..25 / 21..43 span the 40pt
  inner Row and its weighted Spacers used to produce — same pixels, one node
  shallower, and no `weight` in the tree at all.

  No `on_toggle`: the tap stays on the row (`shortcut_tap/2`), because 46x28 is
  under the 44pt touch minimum this screen's neighbours honour.
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
      # colours stay ONE token, because the drawing's thumb does not change
      # colour — only the track does.
      track_on_color: Palette.ink_fill(),
      track_off_color: Palette.track_off(),
      thumb_on_color: Palette.on_ink(),
      thumb_off_color: Palette.on_ink(),
      thumb_shadow: "0 1 3 0 #4D1A1917"
    )
  end

  @doc false
  def share(w) do
    s = w.share

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center" padding_bottom={13}>
        <Box width={34} height={34} corner_radius={10} background={Palette.ink()} align="center">
          <Box width={9} height={9} corner_radius={5} background={Kati.Theme.accent()} />
        </Box>
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={s.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={2} />
          <Text text={s.sub} text_size={11} text_color={Palette.sub()} max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.Widgets.hairline(true)}
      <Spacer size={13} />
      <Text text={s.note} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
    </Column>
    """
  end

  @doc """
  The 7% ink rule — between two shortcut rows, and inside the share card.

  `Kati.Components.MishkaSeparator` is what a 1px rule between rows is, so the
  rule is its, and `render: :box` is the word that makes that true here.

  ## Why `render: :box`

  The component's default `:divider` maps to Material3's `HorizontalDivider`,
  which is not the `Box(fillMaxWidth().height(t).background(c))` this file used
  to claim but an antialiased `drawLine`. At 2.6875x a 1dp rule is given a 3px
  canvas and a 2.6875px stroke, so its bottom pixel row lands at ~69% coverage
  — a full-width row 4-5/255 lighter than the two above it. The drawing paints a
  flat 7% hairline, and no `color`/`thickness` pair recovers it, because the
  softness is in the primitive rather than the values.

  `render: :box` builds

      <Box fill_width={true} height={1} background={Palette.hairline()}>
        <Spacer size={1} />
      </Box>

  — the exact three modifiers this screen wrote by hand before it adopted the
  component. The `Spacer` is an iOS workaround for `MobBox` dropping a Box's
  `height` when it has no `width`; on Android the `height` pins the rule and
  `MobSpacer` is a bare sized `Spacer` with no background, so it draws nothing.

  The alpha survives because the colour is an ARGB int: `color` is in the
  renderer's `@color_props` whitelist and an integer reaches `colorProp`
  untouched.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  # The index rather than the title: these titles are spoken phrases wrapped in
  # typographic quotes, and the tag has to survive a round trip through
  # `String.to_atom/1`.
  @impl true
  def handle_tap(tag, socket) do
    w = socket.assigns.widgets

    case Atom.to_string(tag) do
      "shortcut_" <> i ->
        rows =
          List.update_at(w.shortcuts, String.to_integer(i), fn row ->
            %{row | toggle: not row.toggle}
          end)

        {:noreply, Mob.Socket.assign(socket, :widgets, %{w | shortcuts: rows})}

      _ ->
        {:noreply, socket}
    end
  end
end
