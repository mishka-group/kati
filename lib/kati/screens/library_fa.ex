defmodule Kati.Screens.LibraryFa do
  @moduledoc """
  Screen 57 — کتابخانه, the Persian Library root.

  Built to `.scratch/design/screens/57.html`. Screen 03's page in a root that
  declares `rtl`: the segmented control on its `#E4E0D9` trough, three quick
  tiles, count chips, and a three-across grid of 112x158 posters — 112*3 +
  12*2 = 360, the width inside the 21pt gutters, which is why chunking by
  three reproduces the drawing's wrap rather than approximating it.

  ## The two things the mirror does not do by itself

  **Artwork never flips.** A poster is a photograph, and a mirrored photograph
  is a different picture. The images are drawn exactly as they are in English;
  only the grid around them reorders, which it does because a `Row` lays out
  start-to-end.

  **The progress bar fills from the right.** The drawing floats the fill right
  — *"progress follows reading direction"* — and here that is the same `Row`
  with a weighted fill and a weighted remainder as screen 03, with nothing
  reversed: start is the right edge, so it fills from the right.

  A title's second line is the one addition over 03, which puts nothing under
  the poster's name: the drawing wants فصل ۲ · ۵ از ۷ there, so it is data on
  the item rather than a computed string, since "۵ از ۷" and "تمام‌شده" and
  "فیلم · ۲۰۲۵" are three different sentences, not one template.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.LibraryFa.Sample
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())

    socket
    |> Mob.Socket.assign(:header, Sample.header())
    |> Mob.Socket.assign(:titles, Sample.titles())
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    Fa.frame(:library, Kati.Screens.LibraryFa.content(assigns))
  end

  @doc false
  def content(assigns) do
    header = assigns.header
    titles = assigns.titles

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.LibraryFa.header(header)}
        {Kati.Screens.LibraryFa.segments()}
        {Kati.Screens.LibraryFa.quick_tiles()}
        {Kati.Screens.LibraryFa.chips()}
        {Kati.Screens.LibraryFa.grid(titles)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(header) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={header.title}
            font_family="fa"
            font_weight="bold"
            text_size={27}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={header.subtitle}
            font_family="fa"
            text_size={11.5}
            text_color={0xFFA9A29A}
            max_lines={1}
          />
        </Column>
        {Fa.disc("search", :open_search)}
        <Spacer size={9} />
        {Fa.disc("sort", :open_sort)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def segments do
    [screen, books, music] = Sample.segments()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={18} padding={4} align="center">
        {Kati.Screens.LibraryFa.segment(screen)}
        <Spacer size={4} />
        {Kati.Screens.LibraryFa.segment(books)}
        <Spacer size={4} />
        {Kati.Screens.LibraryFa.segment(music)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def segment(%{on?: true} = seg) do
    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={0xFFFBFAF8}
        shadow="0 1 2 0 #0F1A1917"
        align="center"
      >
        <Spacer weight={1.0} />
        {UI.symbol(seg.icon, size: 17)}
        <Spacer size={6} />
        <Text
          text={seg.label}
          font_family="fa"
          font_weight="bold"
          text_size={12.5}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  def segment(seg) do
    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={38} corner_radius={14} align="center">
        <Spacer weight={1.0} />
        {UI.symbol(seg.icon, size: 17, color: 0xFFAFA89E)}
        <Spacer size={6} />
        <Text
          text={seg.label}
          font_family="fa"
          font_weight="semibold"
          text_size={12.5}
          text_color={0xFFAFA89E}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def quick_tiles do
    [up_next, discover, lists] = Sample.quick_tiles()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.LibraryFa.quick_tile(up_next)}
        <Spacer size={9} />
        {Kati.Screens.LibraryFa.quick_tile(discover)}
        <Spacer size={9} />
        {Kati.Screens.LibraryFa.quick_tile(lists)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def quick_tile(tile) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={11}
        padding_right={11}
        padding_top={12}
        padding_bottom={12}
      >
        <Row fill_width={true} align="center">
          {UI.symbol(tile.icon, size: 19)}
          <Spacer weight={1.0} />
          {Kati.Screens.LibraryFa.tile_count(tile.count)}
        </Row>
        <Spacer size={9} />
        <Text
          text={tile.label}
          font_family="fa"
          font_weight="bold"
          text_size={12.5}
          text_color={:on_surface}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def tile_count(nil), do: ~MOB"<Spacer size={0} />"

  def tile_count(count) do
    ~MOB"""
    <Text text={count} font_family="fa" text_size={10} text_color={0xFFC4BDB3} max_lines={1} />
    """
  end

  @doc false
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Sample.chips()
           |> Enum.with_index()
           |> Enum.map(fn {{label, count}, i} -> Kati.Screens.LibraryFa.chip(label, count, i == 0) end)}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  # The count sits at .6 of the label's own colour rather than on a token of
  # its own, so it stays legible on the ink chip and on the white ones.
  @doc false
  def chip(label, count, on?) do
    bg = if on?, do: 0xFF1A1917, else: 0xFFFBFAF8
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    count_fg = if on?, do: 0x99FBFAF8, else: 0x995C574F
    shadow = if on?, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={bg}
      shadow={shadow}
      padding_left={14}
      padding_right={14}
      align="center"
    >
      <Text text={label} font_family="fa" font_weight="semibold" text_size={12.5} text_color={fg} max_lines={1} />
      <Spacer size={6} />
      <Text text={count} font_family="fa" text_size={10} text_color={count_fg} max_lines={1} />
      <Spacer size={7} />
    </Row>
    """
  end

  @doc false
  def grid(titles) do
    rows = Enum.chunk_every(titles, 3)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, &Kati.Screens.LibraryFa.grid_row/1)}
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row
         |> Enum.map(&Kati.Screens.LibraryFa.poster/1)
         |> Enum.intersperse(Kati.Screens.LibraryFa.grid_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def poster(item) do
    tap = {self(), :open_series}

    ~MOB"""
    <Column width={112} on_tap={tap}>
      <Box
        width={112}
        height={158}
        corner_radius={13}
        background={0xFFE4E0D9}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.LibraryFa.artwork(item.seed)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {Kati.Screens.LibraryFa.progress(item.progress)}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text
        text={item.title}
        font_family="fa"
        font_weight="bold"
        text_size={12.5}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text text={item.meta} font_family="fa" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def artwork(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} width={112} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  # The track is drawn even at zero — the wish-list title keeps its 22% ink
  # band with nothing in it, which is how the grid stays one grid. A Compose
  # weight must be greater than zero, so the two ends are their own clauses
  # rather than a weight of 0.0.
  @doc false
  def progress(fraction) when fraction <= 0.0 do
    ~MOB"<Box fill_width={true} height={4} background={0x381A1917} />"
  end

  def progress(fraction) when fraction >= 1.0 do
    ~MOB"""
    <Box fill_width={true} height={4} background={0x381A1917}>
      <Box fill_width={true} height={4} background={0xFFE8823C} />
    </Box>
    """
  end

  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={4} background={0x381A1917}>
      <Row fill_width={true}>
        <Box weight={fraction} height={4} background={0xFFE8823C} />
        <Spacer weight={1.0 - fraction} />
      </Row>
    </Box>
    """
  end

  def handle_info({:tap, :open_series}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SeriesFa)}

  def handle_info({:tap, :open_search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :library, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
