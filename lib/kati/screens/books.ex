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
  alias Kati.Theme

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
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
          <Text text="Library" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Books.Sample.subtitle()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
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
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={18} padding={4} align="center">
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
    fg = Theme.ink()

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={Kati.Theme.card(:light)}
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
    fg = 0xFFAFA89E

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
        background={Kati.Theme.card(:light)}
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
            text_color={0xFFA0998F}
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
          <Text text={r.author} text_size={12} text_color={0xFF8A8479} max_lines={1} />
          <Spacer size={12} />
          {Kati.Screens.Books.reading_bar(r.progress)}
          <Spacer size={8} />
          <Text text={r.pace} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
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
        ~MOB"<Box width={74} height={110} corner_radius={6} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Box width={74} height={110} corner_radius={6} background={0xFFE4E0D9} shadow="0 6 14 -6 #801A1917">
          <Image src={src} width={74} height={110} corner_radius={6} content_mode="fill" />
        </Box>
        """
    end
  end

  # The hero's rail is ink on #E7E3DC, not accent — this is "how far through
  # the book you are", stated plainly, and the orange is saved for the covers
  # where it has to be legible at 4pt.
  @doc false
  def reading_bar(fraction) do
    ~MOB"""
    <Box fill_width={true} height={5} corner_radius={3} background={0xFFE7E3DC}>
      <Row fill_width={true}>
        <Box weight={fraction} height={5} corner_radius={3} background={Kati.Theme.ink()} />
        <Spacer weight={1.0 - fraction} />
      </Row>
    </Box>
    """
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

  @doc false
  def chip(label, count, on?) do
    bg = if on?, do: Theme.ink(), else: Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    # The drawing puts the count at .6 opacity of the label's own colour rather
    # than at a separate token, so it stays legible on both chip states.
    count_fg = if on?, do: 0x99FBFAF8, else: 0x995C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={bg} padding_left={14} padding_right={14} align="center">
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      {Kati.Screens.Books.chip_count(count, count_fg)}
    </Row>
    """
  end

  @doc false
  def chip_count(nil, _color), do: ~MOB"<Spacer size={0} />"

  def chip_count(count, color) do
    ~MOB"""
    <Row align="center">
      <Spacer size={6} />
      <Text text={count} font_family="mono" text_size={10.5} text_color={color} max_lines={1} />
    </Row>
    """
  end

  # Three across, as on screen 03: 112*3 + 12*2 = 360, the content width
  # between the 21pt gutters. Mob has no wrapping primitive, so the row count
  # is declared rather than measured — and the design's arithmetic is what
  # makes three the right declaration.
  @doc false
  def grid do
    rows = Sample.books() |> Enum.chunk_every(3)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Books.grid_row(row) end)}
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row |> Enum.map(&Kati.Screens.Books.tile/1) |> Enum.intersperse(Kati.Screens.Books.grid_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def tile(book) do
    ~MOB"""
    <Column width={112}>
      <Box width={112} height={158} corner_radius={6} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()}>
        {Kati.Screens.Books.artwork(book)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {Kati.Screens.Books.progress(book.progress)}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text text={book.title} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={book.line} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
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
        <Image src={src} width={112} height={158} corner_radius={6} content_mode="fill" />
        """
    end
  end

  # Burnt into the jacket's bottom edge: a 4pt rail at 22% ink with an accent
  # fill. The rail is drawn even at 0% — see the moduledoc.
  @doc false
  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={4} background={0x381A1917}>
      <Row fill_width={true}>
        {Kati.Screens.Books.progress_fill(fraction)}
        {Kati.Screens.Books.progress_rest(1.0 - fraction)}
      </Row>
    </Box>
    """
  end

  @doc false
  def progress_fill(fraction) when fraction <= 0.0, do: ~MOB"<Spacer size={0} />"

  def progress_fill(fraction) do
    ~MOB"""
    <Box weight={fraction} height={4} background={0xFFE8823C} />
    """
  end

  @doc false
  def progress_rest(rest) when rest <= 0.0, do: ~MOB"<Spacer size={0} />"
  def progress_rest(rest), do: ~MOB"<Spacer weight={rest} />"

  @impl true
  def handle_tap(:open_screen, socket),
    do: {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.Library)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
