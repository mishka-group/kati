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

  ## Components, and the strip that cannot be one

    * `check/1` — `Kati.Components.MishkaThemeIcon`, `:filled` for the ink tick
      and `:subtle` for the empty ring. `:subtle` paints nothing and takes the
      drawing's hairline through `border_color` / `border_width`, both new this
      round.
    * `badge_pill/3` — `Kati.Components.MishkaPill`, which is exactly a compact
      label in a coloured token.

  **The order strip stays hand-rolled.** `Kati.Components.MishkaSegmentedControl`
  now takes every colour, radius, height and shadow this drawing asks for —
  including `selected_shadow`, which is the whole difference between the chosen
  tile and its two neighbours — and still cannot draw it, for one reason:
  **the drawing sets its three tiles 4pt apart** and the component lays its
  segments in a bare `Row` with nothing between them and no spacing prop. Three
  flush tiles are different pixels.

  There is a second thing worth recording even though the gap above settles it:
  the component's equal-width answer is `segment_weight`, which it merges onto
  the *same* `Box` that carries `fill_width: false`. Since fence K-17 that
  `false` makes the box hug, so a weight and a hug would be arguing on one node.
  `order/2` keeps the two on separate boxes — an outer `Box weight={1.0}` around
  an inner `Box fill_width={true}` — which is why it has a wrapper that looks
  redundant and is not.
  """
  use Kati.Screens.Pushed, back: "Series"

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Season.Sample
  alias Kati.Theme.Palette
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
      <Row fill_width={true} background={Palette.placeholder()} corner_radius={16} padding={4} align="center">
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
        background={Palette.card()}
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
        <Text text={label} text_size={12.5} font_weight="semibold" text_color={Palette.segment_idle()} max_lines={1} />
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
    bg = if watched?, do: Palette.card_settled(), else: Palette.card()
    title_color = if watched?, do: Palette.settled_ink(), else: Palette.ink()
    number_color = if Map.get(ep, :special, false), do: Palette.gold_icon(), else: Palette.tertiary()

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

  # `weight`, not `fill_width`: this Row is a sibling of the watched tick inside
  # the episode row, and a sibling that fills the width leaves the tick nothing
  # to sit in — the disc was being measured past the right edge of every card.
  # A weight takes what is left once the 27pt disc has had its share.
  @doc false
  def episode_body(ep, title_color, number_color) do
    ~MOB"""
    <Row weight={1.0} align="center">
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
        <Text text={ep.sub} font_family="mono" text_size={10.5} text_color={Palette.tertiary()} max_lines={1} />
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
        :cream -> {Palette.cream(), Palette.gold_text()}
        _ -> {Palette.paper(), Palette.ink_soft()}
      end

    ~MOB"""
    <Row align="center">
      <Spacer size={7} />
      {Kati.Screens.Season.badge_pill(badge.label, bg, fg)}
    </Row>
    """
  end

  @doc """
  The `SPECIAL` tag itself: `Kati.Components.MishkaPill`.

  A pill is a compact label in a coloured token, which is the whole of what this
  is — no state, nothing to remove, so none of `MishkaChip`'s `checked` and none
  of the pill's own `with_remove`.

  `padding: 0` is load-bearing. A pill always writes a `padding` key defaulting
  to `:space_sm`, and `MobBridge.kt` resolves an unspecified edge against that
  uniform (`pad(v) = (v ?: uniform ?: 0)`), so `padding_left`/`padding_right`
  alone would leave the drawing's 18pt badge padded top and bottom as well.
  """
  def badge_pill(label, background, color) do
    MishkaPill.pill(
      label: label,
      background: background,
      color: color,
      height: 18,
      corner_radius: 9,
      padding: 0,
      padding_left: 7,
      padding_right: 7,
      text_size: 9.5,
      font_weight: :bold,
      align: :center
    )
  end

  @doc """
  The watched tick and the empty ring, both `Kati.Components.MishkaThemeIcon` —
  "a themed container around exactly one icon", and in the ring's case around
  none.

  `variant: :filled` with an explicit `color` paints the ink disc; `:subtle`
  paints nothing at all (its skin's `background` is `nil`, which the component
  leaves off the node rather than sending as a null) and takes the drawing's
  ring through `border_color` / `border_width`. `border_width` is read with
  `floatProp`, so the 1.5 survives.

  ## The tick inverts, it does not follow

  The disc is an ink-filled control, so it takes the pair the design draws for
  one: `Palette.ink_fill/0` under `Palette.on_ink/0` — `#1A1917` + `#FBFAF8` in
  light, `#F7EFE4` + `#1A1917` in dark, the fill swapping sides of the ramp
  rather than darkening with the page. Screen 12's identical 27pt tick is
  already written that way. `Kati.Theme.ink/0` was the fill before and takes no
  mode, so in dark the disc and its check would both have been near-black.

  ## Why the pixels do not move

  `check(true)` returns `Box{width: 27, height: 27, align: :center,
  corner_radius: 14, background: ink_fill}` around the glyph — node for node what
  was written by hand. `check(false)` adds one prop the hand-rolled version did
  not carry, `align: :center`, on a box with no children: there is nothing to
  align.
  """
  def check(true) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink_fill(), size: 27, radius: 14},
      [Kati.UI.symbol("check", size: 16, color: Palette.on_ink())]
    )
  end

  def check(false) do
    MishkaThemeIcon.theme_icon(%{
      variant: :subtle,
      size: 27,
      radius: 14,
      border_color: Palette.border(),
      border_width: 1.5
    })
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
        border_color={Palette.border()}
        padding={15}
        align="top"
      >
        {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
        <Spacer size={11} />
        <Text text={s.note} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} weight={1.0} />
      </Row>
    </Column>
    """
  end
end
