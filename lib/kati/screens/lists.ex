defmodule Kati.Screens.Lists do
  @moduledoc """
  Screen 12 — Lists, pushed under Library.

  Built to `.scratch/design/screens/12.html`. Hand-made lists sit above the
  ones the app keeps, and the two are drawn as different objects rather than as
  one list with a divider: a made list shows three fanned posters, because what
  is in it is the point; a kept list shows an icon and a count, because it is a
  rule and its contents follow from the rule.

  ## The fanned stack

  The drawing overlaps three 38x54 tiles by 14pt with `margin-left:-14px`. Mob
  has no negative margin, so the fan is a `Box` of declared width with each
  tile pushed in by a `Row`'s `padding_left` — 0, 24, 48 — which reproduces the
  same geometry from the other side: 38 + 24 + 24 = 86, the width the drawing's
  three overlapped tiles occupy.

  Each tile's 2pt `#FBFAF8` ring is padding on a card-coloured box rather than
  a border, so the artwork is clipped by the inner radius and the ring stays
  crisp at the overlap.

  ## The one control

  The drawing gives this screen no chips, no segments and no switches — the
  only thing on it that can be pressed is the `add` disc, and on a screen
  called Lists that means *make a list*. So it does: a new hand-made list
  appears at the top of the made section, empty, and the header count goes up
  with it. Nothing is drawn that the design does not draw — the new row is the
  same made row, with no artwork in its stack and `0 titles` under its name,
  which is what an empty list looks like.

  The rows themselves are left untappable on purpose. Their chevrons point at a
  list-detail screen the design never draws and the app does not have, and
  `on_tap={nil}` — a row that does nothing and admits it — is better than a row
  that swallows a press.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Screens.Lists.Sample
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :lists, Sample.lists())

  @doc false
  def content(assigns) do
    l = assigns.lists

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Lists.pill_row()}
        {Kati.Screens.Lists.header(l)}
        {Kati.Screens.Lists.made(l)}
        {UI.eyebrow("Kept automatically")}
        {Kati.Screens.Lists.kept(l)}
      </Column>
    </Scroll>
    """
  end

  # Kati.Screens.Pushed floats the back pill; the drawing gives it a 42pt row
  # with 16pt under it, so this reserves that height rather than redrawing it.
  @doc false
  def pill_row, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(l) do
    tap = {self(), :new_list}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Lists" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={l.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={9} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={tap}
        >
          {Kati.UI.symbol("add", size: 21)}
        </Box>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def made(l) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(l.made, fn row -> Kati.Screens.Lists.made_row(row) end)}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def made_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={13}
        align="center"
      >
        {Kati.Screens.Lists.stack(row.seeds)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={14} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.count} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={14} />
        {Kati.Screens.Lists.badge(row.badge)}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  # 38 + 24 + 24 = 86. The Box is the frame and each Row is the offset, because
  # a Box stacks its children at the top-start corner and a Row hugs, so
  # padding_left on the Row is the only thing that moves.
  @doc false
  def stack(seeds) do
    ~MOB"""
    <Box width={86} height={54}>
      {seeds |> Enum.with_index() |> Enum.map(fn {seed, i} -> Kati.Screens.Lists.tile(seed, i * 24) end)}
    </Box>
    """
  end

  # The 2pt ring is a centred 34x50 image inside a 38x54 card-coloured box, not
  # `padding={2}`. `nodeModifier` applies padding OUTSIDE the explicit size —
  # `Modifier.padding(2).width(38)` measures 42 — so padding here would grow
  # the tile and break the 86pt fan. Centring gives the same 2pt on all four
  # sides and keeps the tile the size the drawing gives it.
  @doc false
  def tile(seed, offset) do
    ~MOB"""
    <Row padding_left={offset}>
      <Box
        width={38}
        height={54}
        corner_radius={7}
        background={Kati.Theme.card(:light)}
        shadow="0 3 8 -3 #801A1917"
        align="center"
      >
        {Kati.Screens.Lists.tile_art(seed)}
      </Box>
    </Row>
    """
  end

  @doc false
  def tile_art(seed) do
    case Sample.poster(seed) do
      nil ->
        ~MOB"<Box width={34} height={50} corner_radius={5} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={34} height={50} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # No badge means the list is neither ranked nor shared, and the drawing ends
  # that row with a chevron instead — the badge slot and the affordance slot
  # are the same slot.
  @doc false
  def badge(nil), do: Kati.UI.symbol("chevron_right", size: 19, color: 0xFFC4BDB3)

  def badge(label) do
    # Mishka's Pill. A pill and not a chip: `RANKED` / `SHARED` is a fact about
    # the list, with no selected state to carry and nothing to tap.
    #
    # The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right`
    # at 9 gives the bridge the same 9/0 edges, and padding is applied before
    # size, so `height: 22` still measures 22. The pill's root is a `Box` that
    # passes `fill_width={false}`, so it hugs (K-17) as the Row did, around a
    # `Row` holding the label beside an empty `Row` where the ✕ would be —
    # zero-wide, and both hug — with `align: :center` centring the pair exactly
    # where `align="center"` centred the lone Text. `max_lines: 1` is the pill's
    # own default and is what this Text already carried.
    MishkaPill.pill(
      label: label,
      background: 0xFFFBF1DE,
      color: 0xFF96723C,
      corner_radius: 11,
      height: 22,
      padding: 0,
      padding_left: 9,
      padding_right: 9,
      align: :center,
      text_size: 10,
      font_weight: :semibold
    )
  end

  @doc false
  def kept(l) do
    last = length(l.kept) - 1

    ~MOB"""
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
      {l.kept
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.Lists.kept_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def kept_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        {Kati.Screens.Lists.kept_icon(row.icon)}
        <Spacer size={13} />
        <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} weight={1.0} max_lines={1} />
        <Spacer size={13} />
        <Text text={row.count} font_family="mono" text_size={11.5} text_color={0xFFA9A29A} max_lines={1} />
        <Spacer size={13} />
        {Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)}
      </Row>
      {Kati.Screens.Lists.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  A kept list's leading icon — Mishka's Theme Icon.

  "A themed container around exactly one icon" is the whole of what this Box
  was, so the component is a rename rather than a rewrite. With no `id` to tag
  and the glyph passed as a child, `theme_icon/2` emits one Box whose props map
  is the hand-rolled one key for key — `width: 30, height: 30, align: :center,
  corner_radius: 9, background: #EFECE7` — around the same `Kati.UI.symbol/2`
  Text. `variant: :filled` with a raw `color` is what puts the design's own
  value in the fill rather than a theme token, and the glyph keeps the colour
  it was handed, because a caller-supplied icon always does.
  """
  @spec kept_icon(String.t()) :: map()
  def kept_icon(icon) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: 0xFFEFECE7, size: 30, radius: 9],
      [Kati.UI.symbol(icon, size: 17, color: 0xFF5C574F)]
    )
  end

  # Mishka's Separator, at the design's own colour and thickness. `render:
  # :box` is not optional — the default `:divider` is Material 3's antialiased
  # drawLine, NOT the full-width 1dp coloured rectangle this comment used to
  # claim, and it softens the bottom pixel row of every rule in the kept card.
  # See `Kati.Screens.Film.hairline/1` for the measurement.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: 0x121A1917, thickness: 1, render: :box)

  @impl true
  def handle_tap(:new_list, socket) do
    {:noreply, Mob.Socket.update(socket, :lists, &Kati.Screens.Lists.add_list/1)}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  A new hand-made list, at the top of the made section.

  Newest first, because the point of pressing `+` is to see the thing you just
  made: at the bottom of three cards it would be off the bottom of the phone on
  a longer list, and a control whose result is out of frame reads as broken.

  It carries no artwork and no badge, so it falls through to the same empty
  stack and the same chevron the design already draws for an unbadged list.
  """
  @spec add_list(map()) :: map()
  def add_list(l) do
    row = %{title: "New list", count: "0 titles", badge: nil, seeds: []}

    %{l | made: [row | l.made], subtitle: bump(l.subtitle)}
  end

  # "7 lists · 2 ranked" is a sentence, not a pair of numbers, and only its
  # first number is a count of lists. Parsing the head and putting the rest
  # back keeps the drawing's own copy — including the ranked tally, which
  # adding an unranked list does not change.
  defp bump(subtitle) do
    case Integer.parse(subtitle) do
      {n, rest} -> Integer.to_string(n + 1) <> rest
      :error -> subtitle
    end
  end
end
