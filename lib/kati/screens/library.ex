defmodule Kati.Screens.Library do
  @moduledoc """
  Screen 03 — Library.

  Built to `.scratch/design/screens/03.html`: a segmented control on a
  `#E4E0D9` trough, three quick tiles carrying mono counts, chips with counts
  at .65 opacity, and a three-across grid of 158-tall posters each with a
  progress bar burnt into its bottom edge.

  **Books and Music are drawn inactive**, and that is the design's own
  decision, not a shortcut: #60 settled that v1 ships one media domain —
  Screen — because a solo maintainer with a calendar and a sync engine on the
  critical path should not open two crowded markets. The design already greys
  them, so matching it and honouring the decision are the same act.

  Mob has no wrap primitive, so the grid is chunked into rows of three, and the
  three posters share the row by weight rather than measuring 112 each. The
  design's 112*3 + 12*2 = 360 is the arithmetic of its own 402pt frame; a real
  411dp device leaves ~370dp between the 21pt gutters, so fixed tiles stop
  ~9dp short and the right edge goes ragged.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaProgress
  alias Kati.Library.Sample
  alias Kati.Theme

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, filter: "All", shelf: "Screen")

  @doc false
  def content(assigns) do
    filter = assigns.filter
    shelf = assigns.shelf
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Library.header()}
        {Kati.Screens.Library.segments(shelf)}
        {Kati.Screens.Library.quick_tiles()}
        {Kati.Screens.Library.chips(filter)}
        {Kati.Screens.Library.grid(filter, shelf)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text text="Library" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Library.Sample.subtitle()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        {Kati.Screens.Library.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Library.disc("sort", :open_sort)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Chelekom's headless Action Icon. See screen 02's `disc/2` for why `shadow`
  # is the prop that unblocked this: a filled disc with no lift is a flat patch
  # of card white on paper, and the drawing's whole affordance is that it floats.
  #
  # `shape: :circle` gives `44 / 2` = 22.0 where the Box said 22 — `floatProp`
  # reads both as 22.0f. The glyph is a child so `Kati.UI.symbol/2` keeps
  # supplying the Material Symbol at 21; the component's `<Row>` wrapper hugs
  # that single `<Text>` and is centred by the same `Alignment.Center`.
  @doc false
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Theme.card(:light),
        shadow: Theme.shadow_button(),
        on_tap: tag
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def segments(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={18} padding={4} align="center">
        {Kati.Screens.Library.segment("movie", "Screen", active == "Screen")}
        <Spacer size={4} />
        {Kati.Screens.Library.segment("menu_book", "Books", active == "Books")}
        <Spacer size={4} />
        {Kati.Screens.Library.segment("graphic_eq", "Music", active == "Music")}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # NOT Chelekom's Segmented Control, and it is worth writing down why so the
  # next pass does not re-derive it. The component is otherwise a close fit —
  # `track_padding`, `segment_height`, `segment_radius`, `font_weight` +
  # `selected_weight`, `segment_weight` for the `flex:1` cells, even a
  # `selected_shadow` — but two things the drawing does are not expressible:
  #
  #   1. **Each segment carries an icon.** `option/3` builds
  #      `%{props: %{id:, label:, disabled:}}` and `segment/3` renders it as a
  #      Box holding one `<Text>` the control paints itself. The drawing puts a
  #      17px Material Symbol before each 13px label with a 6px gap
  #      (`03.html:16-28`). There is no leading slot, and the label is a prop
  #      rather than children precisely because the control owns that Text.
  #   2. **`gap:4px` between segments.** `track/3` emits `<Row>{segments}</Row>`
  #      with nothing interspersed and there is no `segment_gap` prop; the
  #      segments would abut. Nor can the gap be smuggled in as a child —
  #      `segmented_control/2` filters children to
  #      `match?(%{type: :mishka_segmented_control_option}, &1)` and drops the
  #      rest, so an interspersed `<Spacer>` is discarded rather than laid out.
  #
  # Either alone would move pixels, so the strip stays hand-rolled. Both are
  # upstream asks: a leading slot on an option, and a gap between segments.
  @doc false
  def segment(icon, label, on?) do
    tap = {self(), String.to_atom("shelf_" <> label)}
    bg = if on?, do: Theme.card(:light), else: 0x00FFFFFF
    fg = if on?, do: Theme.ink(), else: 0xFFAFA89E
    weight = if on?, do: "bold", else: "semibold"

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={38} corner_radius={14} background={bg} align="center" on_tap={tap}>
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight={weight} text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def quick_tiles do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Library.quick_tile("playlist_play", "Up next", "12", :open_up_next)}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("explore", "Discover", nil, :open_discover)}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("bookmarks", "Lists", "7", :open_lists)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def quick_tile(icon, label, count, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={11}
        padding_right={11}
        padding_top={12}
        padding_bottom={12}
      >
        <Row fill_width={true} align="center">
          {Kati.UI.symbol(icon, size: 19)}
          <Spacer weight={1.0} />
          {Kati.Screens.Library.tile_count(count)}
        </Row>
        <Spacer size={10} />
        <Text text={label} text_size={12.5} font_weight="bold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def tile_count(nil), do: ~MOB"<Spacer size={0} />"

  def tile_count(count) do
    ~MOB"""
    <Text text={count} font_family="mono" text_size={10} text_color={0xFFC4BDB3} max_lines={1} />
    """
  end

  @doc false
  def chips(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Kati.Library.Sample.chips()
           |> Enum.map(fn {label, count} ->
             Kati.Screens.Library.chip(label, count, label == active)
           end)
           |> Enum.intersperse(Kati.Screens.Library.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  # Chelekom's headless Chip, count and all. The count is what made this chip
  # need the component's `trailing` SLOT rather than its `trailing` string: the
  # drawing sets it in DM Mono at 10.5, and the component paints a string
  # trailing in the chip's own family and size. A slot takes a node as readily
  # as a glyph, so `chip_count/2` supplies the exact `<Text>` this screen drew.
  #
  # The tree gains one level and loses nothing:
  #
  #   was  <Row height={32} corner_radius={16} background padding_left={14}
  #             padding_right={14} align="center" on_tap>
  #          <Text label 12.5 semibold /> <Spacer size={6} /> <Text count mono />
  #        </Row>
  #
  #   now  <Box fill_width={false} height={32} … align="center" on_tap>
  #          <Row align="center">
  #            <Text label 12.5 semibold /> <Spacer size={6} /> <Text count mono />
  #          </Row>
  #        </Box>
  #
  # Width: the Box hugs (K-17 reads `fill_width={false}` now), so it measures
  # 14 + Row + 14, and the Row hugs to label + 6 + count — the same total the
  # padded Row measured on its own.
  #
  # Height: centring composes. The inner Row carries no height, so it hugs to
  # its tallest child and centres both Texts on ITS midline; the Box then
  # centres that Row inside the declared 32. Each label's box therefore lands
  # on the same midline it landed on when the Row itself was 32 tall with
  # `CenterVertically` — the intermediate container is transparent to the
  # arithmetic precisely because it hugs.
  #
  # `align="center"` on the inner Row is also what the bridge would have done
  # unasked: `rowAlignProp` DEFAULTS to `CenterVertically`, and only "top" and
  # "bottom" move it.
  @doc false
  def chip(label, count, on?) do
    # The design puts the count at .65 opacity of the label colour rather than
    # a separate token, so it stays legible on both chip states.
    count_fg = if on?, do: 0xA6FBFAF8, else: 0xA65C574F

    MishkaChip.chip(
      label: label,
      checked: on?,
      # The tag carries the label, so one handler serves every chip and adding
      # a filter needs no new clause.
      on_toggle: String.to_atom("filter_" <> label),
      trailing: Kati.Screens.Library.chip_count(count, count_fg),
      trailing_gap: 6,
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Theme.ink(),
      text_color: 0xFFFBFAF8,
      unchecked_color: Theme.card(:light),
      unchecked_text_color: 0xFF5C574F
    )
  end

  # The count, as its own node rather than as the chip's `trailing` string: a
  # string would inherit the chip's `text_size` and its sans family, and the
  # drawing sets this line in DM Mono at 10.5.
  @doc false
  def chip_count(count, color) do
    ~MOB"""
    <Text text={"#{count}"} font_family="mono" text_size={10.5} text_color={color} max_lines={1} />
    """
  end

  # The drawing's `gap:7px` sits BETWEEN chips. It used to be a trailing Spacer
  # inside each chip, which is not the same thing twice over: every chip
  # measured 7 wider than the design's `padding:0 14px`, and the row had no gap
  # at all — the chips only looked separated because their own right padding
  # had grown to 21.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  # Three across, because that is the design's wrap. The width each tile gets is
  # left to the weights in poster/1 — see the moduledoc.
  @doc false
  def grid(filter, shelf) do
    rows = filter |> Kati.Screens.Library.visible(shelf) |> Enum.chunk_every(3)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Library.grid_row(row) end)}
    </Column>
    """
  end

  @doc """
  The titles a filter and a shelf leave visible.

  Books and Music are drawn but empty: #60 settled that v1 ships one media
  domain, and the design greys them. Selecting them shows that emptiness
  honestly rather than pretending the shelf is full of films.
  """
  @spec visible(String.t(), String.t()) :: [map()]
  def visible(_filter, shelf) when shelf != "Screen", do: []

  def visible(filter, _shelf) do
    Enum.filter(Sample.titles(), fn t ->
      case filter do
        "Watching" -> t.progress > 0.0 and t.progress < 1.0
        "Not started" -> t.progress == 0.0
        "Finished" -> t.progress == 1.0
        _ -> true
      end
    end)
  end

  # A short last row must still be padded to three. Weights divide whatever is
  # there, so a row holding one poster gives it the full width and the grid
  # ends with one enormous tile — which is what "4 titles" looked like.
  @doc false
  def grid_row(row) do
    row = row ++ List.duplicate(nil, 3 - length(row))
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row |> Enum.map(&Kati.Screens.Library.poster/1) |> Enum.intersperse(Kati.Screens.Library.grid_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def poster(nil), do: ~MOB"<Box weight={1.0} />"

  def poster(item) do
    # A film opens the film screen and a series the series screen — the design
    # draws them as two different screens, so the grid has to know which.
    tap = {self(), if(item.kind == :film, do: :open_film, else: :open_series)}

    # Weighted rather than 112 wide: three equal shares of the real content
    # width fill the row on any device, where a fixed 112 only fills the
    # drawing's frame.
    ~MOB"""
    <Column weight={1.0} on_tap={tap}>
      <Box fill_width={true} height={158} corner_radius={13} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()}>
        {Kati.Screens.Library.artwork(item)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {Kati.Screens.Library.progress(item.progress)}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text text={item.title} text_size={12.5} font_weight="bold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={Kati.Screens.Library.tile_meta(item)} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
    </Column>
    """
  end

  @doc """
  The mono line under a grid title.

  The drawing carries one — `{{ it.meta }}`, DM Mono 10.5 in `#A9A29A`, 3
  under the title — and the grid was drawing the title and then stopping, so
  every cell sat ~16pt short of the frame and the rows closed up.

  The design templates the copy, so the wording is DERIVED from the one fact
  the shelf actually knows (how far in you are) rather than invented from
  nothing. It is the line to replace first when the Screen domain lands with
  a real season/episode to name.
  """
  @spec tile_meta(map()) :: String.t()
  def tile_meta(%{progress: p}) when p <= 0.0, do: "not started"
  def tile_meta(%{progress: p}) when p >= 1.0, do: "finished"
  def tile_meta(%{progress: p}), do: "#{round(p * 100)}% watched"

  # Real artwork, not a grey rectangle. `content_mode="fill"` crops to the
  # frame the way a poster does; without it Coil letterboxes and the card
  # develops margins the design does not have.
  @doc false
  def artwork(item) do
    case Kati.Library.Sample.poster(item[:seed]) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @doc """
  Burnt into the poster's bottom edge, not floated under it: a 4pt square track
  at 22% ink with an `#E8823C` fill. Orange here is "how far in you are", which
  is the design's one non-status use of it.

  Chelekom's headless Progress in `render: :box`. The native mode is Material's
  `LinearProgressIndicator`, and the two things this rail is made of are the
  two it does not expose: the track colour is `ProgressIndicatorDefaults`'
  `linearTrackColor` with no prop to reach it, and the caps belong to whichever
  material3 is pinned. So the shelf hand-rolled the two Boxes; `render: :box`
  draws exactly those, with the fraction arithmetic in one place.

  Both ends are ordinary on this grid — `tile_meta/1` has clauses for
  `not started` and `finished`, and the sample shelf reaches both (three tiles
  at 0.0, two at 1.0). The hand-rolled version needed a whole extra clause for the
  first and a guarded `progress_rest/1` for the second, because `1.0 -
  fraction` is a zero `weight` at 100% and Compose throws on it. The component
  omits whichever node would carry the zero, which draws the same nothing.
  """
  @spec progress(float()) :: map()
  def progress(fraction) do
    MishkaProgress.progress(
      render: :box,
      value: fraction,
      max: 1,
      height: 4,
      color: 0xFFE8823C,
      track_color: 0x381A1917
    )
  end

  @impl true
  def handle_tap(:open_search, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}
  def handle_tap(:open_up_next, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.UpNext)}
  def handle_tap(:open_discover, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Discover)}
  def handle_tap(:open_lists, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}
  def handle_tap(:open_series, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Series)}
  def handle_tap(:open_film, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Film)}
  # One clause for every chip and every segment: the tag carries the label, so
  # a new filter is a data change rather than a code change.
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      "shelf_" <> label -> {:noreply, Mob.Socket.assign(socket, :shelf, label)}
      _ -> {:noreply, socket}
    end
  end
end
