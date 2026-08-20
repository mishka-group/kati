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

  @doc false
  def chip(label, count, on?) do
    # The tag carries the label, so one handler serves every chip and adding a
    # filter needs no new clause.
    tap = {self(), String.to_atom("filter_" <> label)}
    bg = if on?, do: Theme.ink(), else: Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    # The design puts the count at .65 opacity of the label colour rather than
    # a separate token, so it stays legible on both chip states.
    count_fg = if on?, do: 0xA6FBFAF8, else: 0xA65C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={bg} padding_left={14} padding_right={14} align="center" on_tap={tap}>
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      <Spacer size={6} />
      <Text text={"#{count}"} font_family="mono" text_size={10.5} text_color={count_fg} max_lines={1} />
    </Row>
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

  # Burnt into the poster's bottom edge, not floated under it: a 4pt track at
  # 22% ink with an accent fill. Orange here is "how far in you are", which is
  # the design's one non-status use of it.
  @doc false
  def progress(fraction) when fraction <= 0.0 do
    ~MOB"""
    <Box fill_width={true} height={4} background={0x381A1917} />
    """
  end

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
