defmodule Kati.Screens.Books do
  @moduledoc """
  Screen 20 — the Books shelf, the Library root with **Books** selected.

  Built to `.scratch/design/screens/20.html`. The drawing's own caption is the
  brief: *"The second shelf, built from the identical parts — only the aspect
  ratio, the progress unit (pages, not episodes) and the hero card change."*
  So this file is deliberately screen 03's arrangement with three differences
  and no fourth:

    * covers are radius **6**, not 13 — a book jacket has square corners
    * the tile's second line is a page count, not a title's status
    * a **Reading now** card replaces screen 03's three quick tiles

  It is a root, not a pushed screen: the dock is drawn, `grid_view` is the
  active tab, and the frame closes at 132 to clear it. Tapping **Screen**
  returns to `Kati.Screens.Library`; **Music** is screen 21 and is drawn but
  inert, exactly as screen 03 draws Books and Music.

  The progress track is drawn on **every** cover, including the two at 0%.
  The drawing keeps the 22%-ink rail under a book you have not opened, which
  is what makes "to read" read as a state rather than as missing data.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.Books.Sample
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaProgress
  alias Kati.Theme
  alias Kati.Theme.Palette

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Books.header()}
        {Kati.Screens.Books.segments()}
        {Kati.Screens.Books.reading_now()}
        {Kati.Screens.Books.chips()}
        {Kati.Screens.Books.grid()}
      </Column>
    </Scroll>
    """
  end

  # `align="top"`, where screen 03's identical-looking header is centred. The
  # drawings differ — 03 says `align-items:center`, 20 says `flex-start` — and
  # the reason is the taller title block: the two discs hang from the top of
  # "Library" rather than floating beside its midpoint.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Library"
            text_size={28}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={Kati.Books.Sample.subtitle()}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={9} />
        {Kati.Screens.Books.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Books.disc("sort", :open_sort)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 44pt round tap target holding one glyph — `Kati.Components.MishkaActionIcon`.

  The same disc screens 15 and 21 draw, and the same reason it could not be a
  component until now: the port had no `shadow`, and a floating disc *is* its
  shadow. `variant: :filled` on its own would have drawn a flat #FBFAF8
  rectangle on #EFECE7 paper.

  **The pixels are the same node**: `<Box width={44} height={44}
  align={:center} corner_radius={22.0} background shadow on_tap>`, where
  `shape: :circle` resolves `size / 2` to the 22 the markup wrote out. The
  port's `<Row>` around its children hugs the single glyph and is centred by
  the same Box, so the symbol does not move.
  """
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: {self(), tag}
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def segments do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.placeholder()}
        corner_radius={18}
        padding={4}
        align="center"
      >
        {Kati.Screens.Books.segment("movie", "Screen", false, :open_screen)}
        <Spacer size={4} />
        {Kati.Screens.Books.segment("menu_book", "Books", true, :open_books)}
        <Spacer size={4} />
        {Kati.Screens.Books.segment("graphic_eq", "Music", false, :open_music)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # Two clauses rather than a conditional `shadow`. The raised tile is what
  # says which shelf you are on — the drawing gives it
  # `0 1px 2px rgba(26,25,23,.06), 0 6px 12px -8px rgba(26,25,23,.4)` — and a
  # nil shadow prop would flatten it back into the trough.
  @doc false
  def segment(icon, label, true, tag) do
    tap = {self(), tag}
    fg = Palette.ink()

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"
        align="center"
      >
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight="bold" text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  def segment(icon, label, false, tag) do
    tap = {self(), tag}
    fg = Palette.segment_idle()

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Row fill_width={true} height={38} corner_radius={14} align="center">
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight="semibold" text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  # The hero the shelf earns by having exactly one book open. Screen 03 spends
  # this space on three quick tiles; a book is read over weeks rather than
  # picked from a rail, so the drawing gives the space to the one in progress
  # and prints the pace it is being read at.
  @doc false
  def reading_now do
    r = Sample.reading_now()

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
        align="center"
      >
        {Kati.Screens.Books.hero_cover(r)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={String.upcase(r.label)}
            font_family="mono"
            text_size={10}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={r.title}
            text_size={16}
            font_weight="bold"
            letter_spacing={-0.02}
            line_height={1.25}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={r.author} text_size={12} text_color={Palette.sub()} max_lines={1} />
          <Spacer size={12} />
          {Kati.Screens.Books.reading_bar(r.progress)}
          <Spacer size={8} />
          <Text
            text={r.pace}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def hero_cover(r) do
    case Sample.cover(r.seed) do
      nil ->
        ~MOB"<Box width={74} height={110} corner_radius={6} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Box
          width={74}
          height={110}
          corner_radius={6}
          background={Palette.placeholder()}
          shadow="0 6 14 -6 #801A1917"
        >
          <Image src={src} width={74} height={110} corner_radius={6} content_mode="fill" />
        </Box>
        """
    end
  end

  @doc """
  The **Reading now** hero's rail — 5pt, radius 3, ink on `#E7E3DC`.

  Ink, not accent: this is "how far through the book you are", stated plainly,
  and the orange is saved for the covers where it has to be legible at 4pt.

  Drawn by Chelekom's headless Progress in `render: :box`. The native mode is
  Material's `LinearProgressIndicator`, which fills its parent, paints its own
  track colour and owns its own thickness — so a 5pt ink rail on a named track
  at radius 3 was not expressible at any combination of its props, and this
  file hand-rolled the two Boxes instead. `render: :box` *is* those two Boxes.

  A finished book is 100% (the shelf draws three), which under the hand-rolled
  shape made the remainder `<Spacer weight={0.0} />` — the weight Compose
  throws on. The component drops the remainder at 1.0 and the fill at 0.0
  rather than emitting a zero.
  """
  @spec reading_bar(float()) :: map()
  def reading_bar(fraction) do
    MishkaProgress.progress(
      render: :box,
      value: fraction,
      max: 1,
      height: 5,
      corner_radius: 3,
      color: Palette.ink(),
      track_color: Palette.track()
    )
  end

  @doc false
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Kati.Books.Sample.chips()
           |> Enum.with_index()
           |> Enum.map(fn {{label, count}, i} -> Kati.Screens.Books.chip(label, count, i == 0) end)
           |> Enum.intersperse(Kati.Screens.Books.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One shelf chip — `Kati.Components.MishkaChip`, count in the trailing slot.

  Screen 19 draws the same chip and adopts the same component; this one has no
  handler, because the drawing gives these chips no destination and a tap that
  does nothing is worse than no tap. `on_toggle` is simply not passed, and the
  port omits the key rather than sending a null — so the node carries no
  `on_tap` at all, exactly as the hand-rolled `Row` did.

  **Why the pixels do not move.** The chip was a `Row`; the port builds a `Box`
  that hugs by `fill_width={false}` (read by the bridge since fence K-17), and
  both run background → rounded clip → `padding(0, 14, 0, 14)` → `height(32)`.
  The count moves from a nested `Row` of `[Spacer 6, Text]` into the slot's
  `[Spacer 6, node]` — the same two nodes in the same order, one nesting level
  along, and a `Row` on this bridge centres its children vertically by default,
  so the 10.5 count still sits on the 12.5 label's centre line and the group is
  centred in the 32.

  A chip with **no** count used to carry a `<Spacer size={0} />` where the
  number would go; now `trailing` is `nil` and the port emits no slot at all.
  `Spacer(Modifier.size(0.dp))` measures 0x0, so the two are the same width.
  """
  def chip(label, count, on?) do
    # The drawing puts the count at .6 opacity of the label's own colour rather
    # than at a separate token, so it stays legible on both chip states.
    count_fg = if on?, do: Palette.on_ink_count(), else: Palette.count_idle()

    MishkaChip.chip(
      label: label,
      checked: on?,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      trailing: Kati.Screens.Books.chip_count(count, count_fg),
      trailing_gap: 6
    )
  end

  @doc false
  def chip_count(nil, _color), do: nil

  def chip_count(count, color) do
    ~MOB"""
    <Text text={count} font_family="mono" text_size={10.5} text_color={color} max_lines={1} />
    """
  end

  # Three across, as on screen 03. Mob has no wrapping primitive, so the row
  # count is declared rather than measured — three because that is the drawing's
  # wrap, not because of the 112*3 + 12*2 = 360 arithmetic, which only ever
  # described the export's own 402pt frame.
  #
  # The 18pt gap goes *between* rows: interspersed rather than trailed off each
  # row, so the last row does not push 18pt of dead space above the dock.
  @doc false
  def grid do
    rows =
      Sample.books()
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.Screens.Books.grid_row/1)
      |> Enum.intersperse(Kati.Screens.Books.row_gap())

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    ~MOB"""
    <Row fill_width={true} align="top">
      {row |> Enum.map(&Kati.Screens.Books.tile/1) |> Enum.intersperse(Kati.Screens.Books.grid_gap())}
    </Row>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  # `height`, not `size` — a Spacer's `size` sets both axes, and this one only
  # ever divides rows.
  @doc false
  def row_gap, do: ~MOB"<Spacer height={18} />"

  # Weighted rather than 112 wide: three equal shares of the real content width
  # fill the row on any device, where a fixed 112 only fills the drawing's frame.
  @doc false
  def tile(book) do
    ~MOB"""
    <Column weight={1.0}>
      <Box
        fill_width={true}
        height={158}
        corner_radius={6}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.Books.artwork(book)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {Kati.Screens.Books.progress(book.progress)}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text
        text={book.title}
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={book.line}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  def artwork(book) do
    case Sample.cover(book.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={6} content_mode="fill" />
        """
    end
  end

  @doc """
  The rail burnt into the jacket's bottom edge: 4pt, square, an `#E8823C` fill
  on a 22%-ink track. The track is drawn even at 0% — see the moduledoc.

  Chelekom's headless Progress in `render: :box`. The native mode could not
  draw this at all: `<Progress>` is Material's `LinearProgressIndicator`, whose
  track colour is `ProgressIndicatorDefaults.linearTrackColor` and is not a
  prop, so a rail on 22% ink was unreachable — as were the square corners,
  since 1.3 rounds that widget's caps.

  Both ends are on the shelf at once: screen 20 draws two covers at 100%
  (*Field Notes*, *Low Water*) and two at 0% (*Marram Grass*, *The Warden*).
  This file used to guard them by hand with a pair of `<Spacer size={0} />`
  clauses; the component omits the node instead, which is the same nothing and
  keeps a zero `weight` off the wire on the `1.0 - fraction` side too.
  """
  @spec progress(float()) :: map()
  def progress(fraction) do
    MishkaProgress.progress(
      render: :box,
      value: fraction,
      max: 1,
      height: 4,
      color: Palette.accent(),
      track_color: Palette.track_ink()
    )
  end

  @impl true
  def handle_tap(:open_screen, socket),
    do: {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.Library)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
