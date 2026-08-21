defmodule Kati.Screens.Film do
  @moduledoc """
  Screen 08 — a film, pushed under Library.

  Shares screen 04's shape — 330pt artwork, chrome floating at 60pt, the title
  on the gradient — and diverges where a film differs from a series: a watched
  pill above the title instead of a season card, a rating, and a note.

  The note sits on cream. The design's own caption says that is deliberate:
  it is "the one place the palette warms up", the same treatment the hero card
  gets on Home, and it marks the user's own words as different from metadata.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Library.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    {:ok, Mob.Socket.assign(socket, :film, Sample.film())}
  end

  def render(assigns) do
    f = assigns.film

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Film.artwork(f)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={40}>
            {Kati.Screens.Film.rating_card(f)}
            {Kati.Screens.Film.note(f)}
            {UI.eyebrow("Where to watch")}
            {Kati.Screens.Film.where(f)}
            {Kati.Screens.Film.actions(f)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Film.chrome()}
    </Box>
    """
  end

  @doc false
  def artwork(f) do
    ~MOB"""
    <Box fill_width={true} height={330} background={Palette.track_off()}>
      {Kati.Screens.Film.hero_art(f)}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(190)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          {Kati.Screens.Film.watched_pill(f.watched)}
          <Spacer size={11} />
          <Text text={f.title} text_size={30} font_weight="extrabold" letter_spacing={-0.035} line_height={1.05} text_color={:on_surface} />
          <Spacer size={9} />
          <Text text={f.meta} font_family="mono" text_size={11.5} text_color={Palette.meta()} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The watched pill over the artwork — Mishka's Pill.

  A pill and not a chip: nothing here is selected or selectable, it is a
  statement about the film, which is exactly the label-on-a-lozenge a pill is.
  The tick and the label ride in as `content`, because a pill's `label` prop
  builds its own Text and this one needs a glyph beside it.

  The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right` at
  11 gives the bridge the same 11/0 edges, and padding is applied before size,
  so `height: 26` measures 26 as it did. The pill's root is a `Box` that passes
  `fill_width={false}` and so hugs (K-17) where the Row hugged; inside it a
  `Row` holds the content — itself wrapped in a hugging `Row` — beside the
  empty, zero-wide `Row` that stands in for the absent ✕. Every one of those
  hugs and every one centres vertically by default, so the tick, the 6pt gap
  and the label land at the offsets they already had.
  """
  @spec watched_pill(String.t()) :: map()
  def watched_pill(label) do
    MishkaPill.pill(
      [
        background: Palette.green_wash(),
        corner_radius: 13,
        height: 26,
        padding: 0,
        padding_left: 11,
        padding_right: 11,
        align: :center
      ],
      Kati.Screens.Film.watched_content(label)
    )
  end

  @doc false
  def watched_content(label) do
    [
      Kati.UI.symbol("check_circle", size: 15, color: Palette.green_text(), fill: true),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={Palette.green_text()} max_lines={1} />
      """
    ]
  end

  @doc false
  def hero_art(f) do
    case Sample.poster(f.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={330} content_mode="fill" />
        """
    end
  end

  @doc false
  def chrome do
    back = {self(), :back}
    fill = Palette.chrome_disc()
    # `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)` — this screen floats its
    # chrome over a photograph, so both controls carry the same lift. Neither
    # had one, which is why they read as flat stickers on the still.
    lift = "0 6 16 -8 #991A1917"

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        {Kati.Screens.Film.back_pill(back, fill, lift)}
        <Spacer weight={1.0} />
        {Kati.Screens.Film.more_disc(fill, lift)}
      </Row>
    </Box>
    """
  end

  @doc """
  The floating back pill — Mishka's Pill.

  Icon plus label on a lifted lozenge is a pill with `content`; the tap is the
  pill's own `on_tap`, which takes the already-wired `{pid, tag}` untouched.

  Same pixels. `padding: 0` alongside `padding_left: 12` and
  `padding_right: 16` reproduces the Row's asymmetric 12/16 with 0 top and
  bottom — the bridge resolves an unstated edge against the uniform, and the
  uniform is 0 — and because it pads before it sizes, `height: 42` is still 42.
  `shadow` rides the root Box, which is the node that carries the fill, the
  radius and the tap, so the lift is cast around the same 21pt silhouette. The
  three extra `Row`s the pill builds (its body, the content wrapper, and the
  empty one where a ✕ would sit) all hug and all centre vertically by default,
  so the chevron, the 6pt gap and `Library` sit where they sat.
  """
  @spec back_pill(term(), non_neg_integer(), String.t()) :: map()
  def back_pill(back, fill, lift) do
    MishkaPill.pill(
      [
        background: fill,
        shadow: lift,
        corner_radius: 21,
        height: 42,
        padding: 0,
        padding_left: 12,
        padding_right: 16,
        align: :center,
        on_tap: back
      ],
      Kati.Screens.Film.back_content()
    )
  end

  @doc false
  def back_content do
    [
      Kati.UI.symbol("arrow_back_ios_new", size: 17),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text text="Library" text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} />
      """
    ]
  end

  @doc """
  The floating overflow disc — Mishka's Action Icon, now that a disc can float.

  This screen's chrome sits over a photograph, so both controls carry the
  design's `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)`; without it the disc
  reads as a flat sticker on the still. `action_icon/2` had no shadow prop and
  so could not draw it, which is the only reason this was a bare Box.

  Nothing moves: `shape: :circle` is an exact `size / 2`, so 42 rounds at 21 as
  the literal did, the fill and the shadow pass straight through, and the glyph
  is the same `Kati.UI.symbol/2` Text inside a Row that hugs it — a hugging
  Row's only child, centred in a Box of the declared size, lands where the bare
  centred Text did.
  """
  @spec more_disc(non_neg_integer(), String.t()) :: map()
  def more_disc(fill, lift) do
    MishkaActionIcon.action_icon(
      [size: 42, shape: :circle, variant: :filled, background: fill, shadow: lift],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  # Two hugging children with a weighted Spacer between them, not a weighted
  # column beside a plain one. The previous version put a width-less Box in the
  # trailing Column: a Box fills width unless `width` is a NUMBER, so it took
  # everything and starved the weight={1.0} column to zero — the card rendered
  # 333dp tall against the drawing's 84 and the stars did not appear at all.
  @doc false
  def rating_card(f) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
      align="center"
    >
      <Column weight={1.0}>
        <Text text={String.upcase("Your rating")} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={Palette.eyebrow()} />
        <Spacer size={7} />
        {Kati.Screens.Film.stars(f.stars)}
      </Column>
      <Column weight={1.0}>
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text text={String.upcase("Seen")} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={Palette.eyebrow()} max_lines={1} />
        </Row>
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text text={f.seen} text_size={16} font_weight="bold" text_color={:on_surface} max_lines={1} />
        </Row>
      </Column>
    </Row>
    """
  end

  # Material Symbols, not U+2605. Plus Jakarta Sans has no star glyph, so the
  # text version rendered as nothing at all — an empty card rather than a
  # missing-glyph box, which is why it read as a layout bug.
  @doc false
  def stars(filled) do
    ~MOB"""
    <Row align="center">
      {1..5 |> Enum.map(fn i -> Kati.Screens.Film.star(i <= filled) end) |> Enum.intersperse(Kati.Screens.Film.star_gap())}
    </Row>
    """
  end

  # The drawing sets the star line at 22px with `letter-spacing:.1em` — 2.2pt
  # of air after each glyph. Material Symbols carry no tracking of their own.
  @doc false
  def star_gap, do: ~MOB"<Box width={2} height={1} />"

  @doc false
  def star(true), do: Kati.UI.symbol("star", size: 22, color: Palette.accent(), fill: true)
  def star(false), do: Kati.UI.symbol("star", size: 22, color: Palette.accent())

  @doc false
  def note(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          <Text text={String.upcase(f.note_date)} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={Palette.cream_meta()} />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("edit", size: 17, color: Palette.gold_icon())}
        </Row>
        <Spacer size={9} />
        <Text text={f.note} text_size={14} line_height={1.55} text_color={Palette.cream_body()} />
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def where(f) do
    last = length(f.where) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {f.where |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Film.where_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def where_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Film.where_badge(row.badge)}
        <Spacer size={13} />
        <Text text={row.name} text_size={13.5} font_weight="semibold" text_color={:on_surface} weight={1.0} max_lines={1} />
        <Text text={row.price} font_family="mono" text_size={11} text_color={Palette.muted()} max_lines={1} />
      </Row>
      {Kati.Screens.Film.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  A service's two-letter badge — Mishka's Theme Icon.

  "A themed container around exactly one icon" is the whole of what this Box
  was, so the component is a rename rather than a rewrite. With no `id` to tag
  and the mark passed as a child, `theme_icon/2` emits one Box whose props map
  is the hand-rolled one key for key — `width: 32, height: 32, align: :center,
  corner_radius: 10, background: #EFECE7` — around the same mono Text.
  `variant: :filled` with a raw `color` puts the design's own value in the fill
  rather than a theme token, and the Text keeps the colour and weight it was
  written with, because a caller-supplied icon always does.
  """
  @spec where_badge(String.t()) :: map()
  def where_badge(badge) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 32, radius: 10],
      [Kati.Screens.Film.where_mark(badge)]
    )
  end

  @doc false
  def where_mark(badge) do
    ~MOB"""
    <Text text={badge} font_family="mono" text_size={13} font_weight="medium" text_color={:on_surface} />
    """
  end

  @doc """
  The rule between two `where` rows — Mishka's Separator at the design's own
  colour and thickness, drawn as a **box**.

  `render: :box` is load-bearing, and it was missing. This comment used to
  claim a `<Divider>` is `Box(fillMaxWidth().height(t).background(c))`; it is
  not. `MobDivider` is Material 3's `HorizontalDivider`, which is a `Canvas`
  that `drawLine`s an **antialiased stroke**. At this device's 2.6875x a 1dp
  rule is handed a 3px-tall canvas and a 2.6875px stroke centred in it, so the
  bottom pixel row lands at ~69% coverage: one full-width row 4-5/255 lighter
  than the `1px solid rgba(26,25,23,.07)` the drawing asks for, and no
  combination of `color` and `thickness` can fix it because the softness is in
  the primitive.

  `render: :box` puts back the primitive the hand-rolled markup used —
  `<Box fill_width={true} height={1} background={…}>`, a filled rect with no
  antialiased edge, so every pixel row carries the full colour. It carries a
  1dp `<Spacer>` that is an iOS height workaround rather than a design: on
  Android the Box's own `height` pins the rule and the background covers the
  Spacer, so the node draws exactly the rectangle this screen drew before it
  adopted the component.
  """
  @spec hairline(boolean()) :: map()
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc false
  def actions(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row fill_width={true} align="top">
        {f.actions |> Enum.map(fn {icon, label} -> Kati.Screens.Film.action(icon, label) end) |> Enum.intersperse(Kati.Screens.Film.action_gap())}
      </Row>
    </Column>
    """
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={10} />"

  # A Box for the frame and a Column for the stack, not a Column doing both.
  # `Column` takes no horizontal alignment in this bridge, so its children pin
  # to the left edge — the icons and labels sat against the button's left side.
  # A Box centres its content in both axes when given `align`.
  @doc false
  def action(icon, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        height={52}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        <Column>
          <Row align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol(icon, size: 19)}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={3} />
          <Text text={label} text_size={10.5} font_weight="semibold" text_color={Palette.ink_soft()} max_lines={1} text_align="center" />
        </Column>
      </Box>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
