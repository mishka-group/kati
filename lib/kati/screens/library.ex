defmodule Kati.Screens.Library do
  @moduledoc """
  Screen 03 — Library.

  Built to `.scratch/design/screens/03.html`: a segmented control on a
  `#E4E0D9` trough, three quick tiles carrying mono counts, chips with counts
  at .65 opacity, and a three-across grid of 112x158 posters each with a
  progress bar burnt into its bottom edge.

  **Books and Music are drawn inactive**, and that is the design's own
  decision, not a shortcut: #60 settled that v1 ships one media domain —
  Screen — because a solo maintainer with a calendar and a sync engine on the
  critical path should not open two crowded markets. The design already greys
  them, so matching it and honouring the decision are the same act.

  Mob has no wrap primitive, so the grid is chunked into rows of three. That
  is exactly the design's arithmetic: 112*3 + 12*2 = 360, the content width
  inside the 21pt gutters.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.Library.Sample
  alias Kati.Theme

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Library.header()}
        {Kati.Screens.Library.segments()}
        {Kati.Screens.Library.quick_tiles()}
        {Kati.Screens.Library.chips()}
        {Kati.Screens.Library.grid()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="center">
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

  @doc false
  def disc(icon, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box
      width={44}
      height={44}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_button()}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
  end

  @doc false
  def segments do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={18} padding={4} vertical_align="center">
        {Kati.Screens.Library.segment("movie", "Screen", true)}
        <Spacer size={4} />
        {Kati.Screens.Library.segment("menu_book", "Books", false)}
        <Spacer size={4} />
        {Kati.Screens.Library.segment("graphic_eq", "Music", false)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def segment(icon, label, on?) do
    bg = if on?, do: Theme.card(:light), else: 0x00FFFFFF
    fg = if on?, do: Theme.ink(), else: 0xFFAFA89E
    weight = if on?, do: "bold", else: "semibold"

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={38} corner_radius={14} background={bg} vertical_align="center" horizontal_align="center">
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight={weight} text_color={fg} max_lines={1} />
      </Row>
    </Box>
    """
  end

  @doc false
  def quick_tiles do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="top">
        {Kati.Screens.Library.quick_tile("playlist_play", "Up next", "12")}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("explore", "Discover", nil)}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("bookmarks", "Lists", "7")}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def quick_tile(icon, label, count) do
    ~MOB"""
    <Box weight={1.0}>
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
        <Row fill_width={true} vertical_align="center">
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
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Kati.Library.Sample.chips()
           |> Enum.with_index()
           |> Enum.map(fn {{label, count}, i} -> Kati.Screens.Library.chip(label, count, i == 0) end)}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chip(label, count, on?) do
    bg = if on?, do: Theme.ink(), else: Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    # The design puts the count at .65 opacity of the label colour rather than
    # a separate token, so it stays legible on both chip states.
    count_fg = if on?, do: 0xA6FBFAF8, else: 0xA65C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={bg} padding_left={14} padding_right={14} vertical_align="center">
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      <Spacer size={6} />
      <Text text={"#{count}"} font_family="mono" text_size={10.5} text_color={count_fg} max_lines={1} />
      <Spacer size={7} />
    </Row>
    """
  end

  # Three across. 112*3 + 12*2 = 360 = the content width between the gutters,
  # which is why the design's grid is exactly three wide and why chunking by
  # three reproduces it rather than approximating it.
  @doc false
  def grid do
    rows = Sample.titles() |> Enum.chunk_every(3)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Library.grid_row(row) end)}
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="top">
        {row |> Enum.map(&Kati.Screens.Library.poster/1) |> Enum.intersperse(Kati.Screens.Library.grid_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def poster(item) do
    # A film opens the film screen and a series the series screen — the design
    # draws them as two different screens, so the grid has to know which.
    tap = {self(), if(item.kind == :film, do: :open_film, else: :open_series)}

    ~MOB"""
    <Column width={112} on_tap={tap}>
      <Box width={112} height={158} corner_radius={13} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()}>
        {Kati.Screens.Library.artwork(item)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {Kati.Screens.Library.progress(item.progress)}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text text={item.title} text_size={12.5} font_weight="bold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
    </Column>
    """
  end

  # Real artwork, not a grey rectangle. `content_mode="fill"` crops to the
  # frame the way a poster does; without it Coil letterboxes and the card
  # develops margins the design does not have.
  @doc false
  def artwork(item) do
    case Kati.Library.Sample.poster(item[:slug]) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} width={112} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  # Burnt into the poster's bottom edge, not floated under it: a 4pt track at
  # 22% ink with an accent fill. Orange here is "how far in you are", which is
  # the design's one non-status use of it.
  @doc false
  def progress(fraction) when fraction <= 0.0, do: ~MOB"<Spacer size={0} />"

  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={4} background={0x381A1917}>
      <Row fill_width={true}>
        <Box weight={fraction} height={4} background={0xFFE8823C} />
        {Kati.Screens.Library.progress_rest(1.0 - fraction)}
      </Row>
    </Box>
    """
  end

  @doc false
  def progress_rest(rest) when rest <= 0.0, do: ~MOB"<Spacer size={0} />"
  def progress_rest(rest), do: ~MOB"<Spacer weight={rest} />"

  @impl true
  def handle_tap(:open_series, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Series)}
  def handle_tap(:open_film, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Film)}
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
