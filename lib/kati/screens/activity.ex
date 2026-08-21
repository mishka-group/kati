defmodule Kati.Screens.Activity do
  @moduledoc """
  Screen 15 — Activity, pushed under Stats.

  Built to `.scratch/design/screens/15.html`. An append-only history — every
  tick, rating, drop and import — grouped by when it happened, with the
  per-episode rewatch counts underneath. The drawing's own note calls it the
  undo trail: *nothing in the app deletes silently*, so nothing here is a
  summary, every line is an event.

  Three things the drawing is specific about and this file follows literally:

    * **Two stamps, one gutter.** Today's rows carry a `21:12` clock at mono
      11; Earlier this month's carry `12 AUG` at mono 10 with `.06em`. Both
      sit in a 44pt column, which is what screen 19's calendar rows already
      give the same stamp. Sizing each card's gutter to its own stamp is the
      tempting move and the wrong one — the export's own 38 both truncated the
      date to `12 A…` and stepped the two cards' thumbnails out of line with
      each other. The 6 the column borrowed is given back out of the gap after
      it, so `stamp column + gap` is the drawing's 50 either way and everything
      right of the stamp sits where the export puts it — see `entry_row/5`.
    * **The second eyebrow is grey.** "Earlier this month" gets a `#C4BDB3`
      dash, not the accent — see `Kati.UI.Eyebrow`. Last month is neither new
      nor now.
    * **The verb is a separate run.** `Watched`, `Rated`, `Dropped` are bold
      ink inside a `#5C574F` line, and one `Text` carries one weight. The 2
      between the runs is the word space that split them, not a gap between
      two things — at 4 the line read as two phrases.

  The rating row is written `Blue Hour ★★★★` in the export. U+2605 is not in
  Plus Jakarta Sans — screen 08 discovered that by rendering an empty rating
  card — so the stars are Material Symbols `star` glyphs at the line's own
  size and colour. The checker therefore reports that one line as missing; it
  is a glyph, not a word.

  ## The chips filter the log, and a filter can empty a day

  `All` is the resting state and shows every row, which is what `15.html`
  draws. The other three name a verb, and the verb is what the row stores in
  `lead`, so the chip filters on that and nothing else.

  A filter that leaves a dated group with no rows takes the group's **eyebrow
  with it** — `Rated` and `Added` have nothing in Earlier this month, and a
  headed card with no rows inside it is a worse answer than no card. The
  rewatch count is not part of the log and is never filtered.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Activity.Sample
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, filter: "All")

  @doc false
  def content(assigns) do
    filter = assigns.filter
    today = visible(Sample.today(), filter)
    earlier = visible(Sample.earlier(), filter)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Activity.back_gap()}
        {Kati.Screens.Activity.header()}
        {Kati.Screens.Activity.filters(filter)}
        {Kati.Screens.Activity.group(today, UI.eyebrow("Today"), 44, 11, 0.0)}
        {Kati.Screens.Activity.group(earlier, Kati.UI.Eyebrow.quiet("Earlier this month"), 44, 10, 0.06)}
        {UI.eyebrow("Rewatch count")}
        {Kati.Screens.Activity.rewatch()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The rows a chip leaves visible.

  The chip names a verb and the row keeps its verb in `lead`, so the match is
  on `lead` alone. It is a *contains*, not an equality, and that is the one
  judgement here: `Watched` keeps `Rewatched` too, because a rewatch is a
  watch — the rewatch count at the bottom of this screen already counts it as
  one.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(rows, "All"), do: rows

  def visible(rows, filter) do
    verb = String.downcase(filter)
    Enum.filter(rows, fn row -> String.contains?(String.downcase(row.lead), verb) end)
  end

  @doc """
  One dated group — its eyebrow and its card — or nothing at all.

  Returning a list rather than a wrapper `Column` is deliberate: the sigil
  flattens an interpolated list into its parent, so an empty group leaves no
  node behind and the groups that remain keep the exact spacing they had.
  """
  @spec group([map()], map(), pos_integer(), number(), number()) :: [map()]
  def group([], _eyebrow, _stamp_width, _stamp_size, _stamp_spacing), do: []

  def group(rows, eyebrow, stamp_width, stamp_size, stamp_spacing) do
    [eyebrow, entries(rows, stamp_width, stamp_size, stamp_spacing)]
  end

  # `Kati.Screens.Pushed` floats the back pill over the content, so the content
  # has to leave room for it: the drawing's pill is 42 tall with a 16 gap under
  # it, which puts the title at 122 from the top exactly as the export does.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Activity"
            text_size={28}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={Kati.Activity.Sample.entries_line()}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Activity.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Activity.disc("tune", :open_filters)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 44pt round tap target holding one glyph — `Kati.Components.MishkaActionIcon`.

  Hand-rolled until the port grew a `shadow`, and that prop is the whole reason
  it can move now: a floating disc is *defined* by the lift under it, and
  `variant: :filled` paints a fill and stops. Without the shadow the port drew
  a flat #FBFAF8 patch on #EFECE7 paper — a 4%-different rectangle, which is
  worse than not adopting.

  **The pixels are the same node.** The port builds
  `<Box width={44} height={44} align={:center} corner_radius={22.0}
  background shadow on_tap>` — the same seven props this wrote by hand, with
  `shape: :circle` resolving to an exact `size / 2` where the markup said 22,
  and `align={:center}` where it said `align="center"` (both serialise to the
  string the bridge matches on). The one structural difference is the `<Row>`
  the port wraps children in; a `Row` with no props hugs its single child and
  centres it vertically, so the glyph measures and lands exactly where it did.
  """
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), tag}
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  # Four chips at 7pt gaps measure ~285 inside the 360 the gutters leave, so
  # unlike screen 03's counted chips these do not need a horizontal Scroll.
  @doc false
  def filters(active) do
    chips =
      Sample.filters()
      |> Enum.map(fn label -> filter_chip(label, label == active) end)
      |> Enum.intersperse(chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {chips}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One filter chip — `Kati.Components.MishkaChip`.

  A chip that carries a `checked` state and toggles is the whole of what that
  component is, and this is the first round where it can be *this* chip: the
  port used to hardcode its size, its radius, its type and both unchecked
  colours, so a 32pt pill with a 12.5 semibold label on Kati's own two greys
  could not be expressed. `height`, `padding_x`/`padding_y`, `corner_radius`,
  `text_size`, `font_weight`, `max_lines`, `unchecked_color` and
  `unchecked_text_color` are all props now, and this passes every one.

  **Why the pixels do not move.** The chip was a `Row`; the port builds a
  `Box`. Both hug — a `Row` by nature, the `Box` because the port sends
  `fill_width={false}` and the bridge finally reads it (fence K-17) — and both
  run the same modifier chain: background on the rounded shape, then
  `padding(0, 14, 0, 14)`, then `height(32)`. Padding is applied before height
  on either node, so the chip measures 32 tall and `14 + label + 14` wide
  either way.

  Two prop-level differences, both inert:

    * `padding_y: 0` is written where the `Row` wrote nothing. The bridge
      resolves a missing edge to the uniform padding and a missing uniform to
      zero, so an absent top edge and an explicit `0` are the same number.
    * `align` moves from the `Row` to the `Box`. On a `Row` this bridge's
      default vertical alignment is already `CenterVertically`, so `align`
      was a no-op there; on a hugging `Box` it centres the label in the 32,
      which is the same position — `(32 - label height) / 2` from the top in
      both.
  """
  def filter_chip(label, on?) do
    # The tag carries the label, so one handler serves every chip and a fifth
    # verb is a change to `Kati.Activity.Sample.filters/0` alone.
    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: {self(), String.to_atom("filter_" <> label)},
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
      max_lines: 1
    )
  end

  @doc """
  One dated group as a single card of rows.

  `stamp_size` and `stamp_spacing` are the only difference between Today and
  Earlier this month, which is why they are parameters here rather than two
  near-identical functions. `stamp_width` is 44 from both callers — it stays
  an argument so the two calls state the shared gutter side by side, where a
  disagreement is visible.
  """
  def entries(rows, stamp_width, stamp_size, stamp_spacing) do
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        entry_row(row, stamp_width, stamp_size, stamp_spacing, i < last)
      end)

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
        {children}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  # The line is a Box with a weight wrapping a Row, not a Row with a weight:
  # only a Box is guaranteed to take the weighted slot on this bridge, and the
  # two text runs have to sit side by side inside it. The trailing weighted
  # Spacer is what makes the unweighted Texts ellipsize instead of overflowing.
  #
  # The stamp's gap is 6, not the drawing's 12, and that is arithmetic rather
  # than taste: the export writes a 38pt stamp column and a 12pt gap, so the
  # thumbnail starts 50 in from the card's padding. Our column is 44 (see the
  # moduledoc — 38 ellipsised `12 AUG`), so the gap carries the other 6 and the
  # thumbnail lands exactly where the export draws it. A measured capture had
  # it 6.4dp right of the drawing before this. The whitespace either side of
  # the stamp is unchanged: the text is start-aligned in its column, so what
  # the eye reads as the gap is (column − text) + gap, which is 17 for `21:12`
  # in both the drawing and here.
  @doc false
  def entry_row(row, stamp_width, stamp_size, stamp_spacing, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={12} padding_bottom={12}>
        <Column width={stamp_width}>
          <Text
            text={row.stamp}
            font_family="mono"
            text_size={stamp_size}
            letter_spacing={stamp_spacing}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={6} />
        {Kati.Screens.Activity.thumb(row)}
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row fill_width={true} align="center">
            <Text
              text={row.lead}
              text_size={12.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={2} />
            <Text text={row.rest} text_size={12.5} text_color={Palette.ink_soft()} max_lines={1} />
            {Kati.Screens.Activity.stars(row[:stars])}
            <Spacer weight={1.0} />
          </Row>
        </Box>
      </Row>
      {Kati.Screens.Activity.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def thumb(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={26} height={37} corner_radius={5} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={26} height={37} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # The drawing writes four ★ characters straight into the line. Plus Jakarta
  # Sans has no U+2605, so those would render as nothing at all — screen 08's
  # empty rating card was exactly this bug. Material Symbols `star` at the
  # line's own size and colour is the same mark in a font that carries it.
  @doc false
  def stars(nil), do: ~MOB"<Spacer size={0} />"

  def stars(count) do
    star = Kati.UI.symbol("star", size: 11, color: Palette.ink_soft(), fill: true)
    glyphs = List.duplicate(star, count)

    ~MOB"""
    <Row align="center">
      <Spacer size={5} />
      {glyphs}
    </Row>
    """
  end

  @doc false
  def rewatch do
    rows = Sample.rewatch()
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {{name, count}, i} -> rewatch_row(name, count, i < last) end)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      {children}
    </Column>
    """
  end

  # Orange on the count is the design's own use of accent for "again, now" —
  # a rewatch is the one number on this screen that is still happening.
  @doc false
  def rewatch_row(name, count, gap?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={name}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={count}
          font_family="mono"
          text_size={12}
          text_color={Palette.accent()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Activity.row_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def row_gap(false), do: ~MOB"<Spacer size={0} />"
  def row_gap(true), do: ~MOB"<Spacer size={12} />"

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box, and `render: :box` rather
  # than the component's `:divider` default.
  #
  # `:divider` is NOT the Box this used to be. The comment that stood here said
  # it was — that Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))` — and that is wrong:
  # Material3 draws it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an
  # ANTIALIASED stroke. At this device's 2.6875x a 1dp rule gets a 3px canvas
  # and a 2.6875px stroke centred in it, so the bottom pixel row lands at ~69%
  # coverage — a full-width row 4-5/255 lighter than the two above it. The
  # adoption softened the hairline by one pixel row and nothing said so.
  #
  # `render: :box` is the component's filled-rect primitive: `<Box fill_width
  # height={thickness} background={color}>`, which is the node that was written
  # here by hand before the adoption, so the rule goes back to three full-colour
  # rows. (Its `<Spacer size={1} />` child is an iOS height workaround — on
  # Android the Box's own `height` pins it and the background covers it.)
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  # One clause for all four chips: the tag carries the label. The two discs
  # fall through deliberately — search and the filter sheet are screens this
  # one does not own, and the drawing gives neither a destination.
  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      _ -> {:noreply, socket}
    end
  end
end
