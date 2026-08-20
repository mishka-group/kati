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
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.UI
  alias Kati.Widgets.Sample

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :widgets, Sample.widgets())

  @doc false
  def content(assigns) do
    w = assigns.widgets

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
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
      <Text text="Widgets" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text="add to home screen" font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
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
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Widgets.up_next_tile(w.up_next)}
        <Spacer size={11} />
        {Kati.Screens.Widgets.count_tile(w.tonight, Kati.Theme.ink(), 0xFF6A6560, 0xFFFBFAF8, 0xFF8A837B)}
        <Spacer size={11} />
        {Kati.Screens.Widgets.count_tile(w.streak, 0xFFFBF1DE, 0xFFB09A72, 0xFF1A1917, 0xFF8A7B60)}
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
      background={Kati.Theme.card(:light)}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Column fill_width={true} fill_height={true} padding={13}>
        <Text
          text={tile.label}
          font_family="mono"
          text_size={9}
          letter_spacing={0.14}
          text_color={0xFFA0998F}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.Widgets.mini_poster(tile)}
        <Spacer size={7} />
        <Text text={tile.title} text_size={11} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer size={2} />
        <Text text={tile.episode} font_family="mono" text_size={9} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def mini_poster(tile) do
    case Kati.Design.Images.poster(tile.seed) do
      nil ->
        ~MOB"<Box width={30} height={42} corner_radius={5} background={0xFFE4E0D9} />"

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
        background={Kati.Theme.card(:light)}
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
            text_color={0xFFA0998F}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("calendar_month", size: 14, color: 0xFFC4BDB3)}
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
        <Text text={event.time} font_family="mono" text_size={9.5} text_color={0xFFA9A29A} max_lines={1} />
        <Spacer size={2} />
        <Text text={event.title} text_size={11.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
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
        background={Kati.Theme.card(:light)}
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
        <Box width={30} height={30} corner_radius={9} background={0xFFEFECE7} align="center">
          {Kati.UI.symbol(row.icon, size: 17, color: 0xFF5C574F)}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Widgets.trailing(row)}
      </Row>
      {Kati.Screens.Widgets.hairline(rule?)}
    </Column>
    """
  end

  # A switch when the row is a state, a chevron when it leads somewhere.
  @doc false
  def trailing(row) do
    case Map.get(row, :toggle) do
      nil -> Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)
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
  The design's own switch, drawn rather than delegated.

  `Kati.Components.MishkaSwitch` wraps Compose's `Switch`, which brings
  Material's metrics with it — a 52x32 track and a thumb that grows when on.
  The drawing specifies 46x28 with a 22pt thumb and a 3pt inset, and this
  screen is a fidelity screen, so the shape is built from boxes. The 40pt
  inner row is what produces the 3pt inset on both sides without mixing
  `padding` and an explicit `width` on the same node.
  """
  def toggle(on?) do
    track = if on?, do: Kati.Theme.ink(), else: 0xFFDCD7CF

    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={track} align="center">
      <Row width={40} align="center">
        {Kati.Screens.Widgets.thumb_lead(on?)}
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
        {Kati.Screens.Widgets.thumb_trail(on?)}
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
  def share(w) do
    s = w.share

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center" padding_bottom={13}>
        <Box width={34} height={34} corner_radius={10} background={Kati.Theme.ink()} align="center">
          <Box width={9} height={9} corner_radius={5} background={Kati.Theme.accent()} />
        </Box>
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={s.title} text_size={13} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={2} />
          <Text text={s.sub} text_size={11} text_color={0xFF8A8479} max_lines={1} />
        </Column>
      </Row>
      <Box fill_width={true} height={1} background={0x121A1917} />
      <Spacer size={13} />
      <Text text={s.note} text_size={12.5} line_height={1.55} text_color={0xFF5C574F} />
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

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
