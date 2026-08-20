defmodule Kati.Screens.Music do
  @moduledoc """
  Screen 21 — the Library root with the **Music** segment selected.

  Built to `.scratch/design/screens/21.html`. Not a pushed screen and not a
  fifth root: the drawing carries the four-tab dock with `grid_view` lit, which
  is the Library root, so this is the same root wearing a different shelf. It
  therefore `use`s `Kati.Screens.Root, root: :library` and tapping **Screen**
  swaps back to `Kati.Screens.Library` the same way a root switch does.

  The drawing's note is the reason the layout is so familiar: *"third shelf,
  same skeleton"*. Header, segmented control on its `#E4E0D9` trough, then
  sections. What differs is what a shelf of music needs and a shelf of film
  does not — square artwork instead of 2:3 posters, and a listening-time card
  where the film shelf has quick tiles.

  Three literal details worth naming, because each was a decision:

    * **The selected segment carries a shadow here.** Screen 03's does not.
      `0 1px 2px rgba(26,25,23,.06), 0 6px 12px -8px rgba(26,25,23,.4)` is a
      lighter recipe than any token in `Kati.Theme`, so it is written out.
    * **`41 PLAYS` is orange.** Plays this week are "now", which is the one
      thing accent is allowed to mean.
    * **"New from artists you follow" gets the grey dash** — the records are
      not out yet, so the section is not new. `Kati.UI.Eyebrow.quiet/1`.

  Album tiles take an equal share of the row, which is what the export actually
  writes: `flex:1` with `aspect-ratio:1`. The 112 that `112*3 + 12*2 = 360`
  produces is the arithmetic of the drawing's own 402pt frame, and a real
  411dp device leaves 369dp between the 21pt gutters, so a fixed 112 leaves
  the rail 9dp short. The width has always been a weight; the *height* is now
  `aspect_ratio={1.0}` rather than a declared 112, because a capture measured
  the covers 115 wide and 112 tall — the drawing's squares, drawn oblong. The
  modifier chain is weight → aspect_ratio, so the square is taken off the width
  the Row actually granted, at any frame.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.Music.Sample
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Music.header()}
        {Kati.Screens.Music.segments()}
        {UI.eyebrow("On repeat this week")}
        {Kati.Screens.Music.on_repeat()}
        {UI.eyebrow("Listening time")}
        {Kati.Screens.Music.listening()}
        {Kati.UI.Eyebrow.quiet("New from artists you follow")}
        {Kati.Screens.Music.releases()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Library" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Music.Sample.subtitle()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        {Kati.Screens.Music.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Music.disc("sort", :open_sort)}
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
        {Kati.Screens.Music.segment("movie", "Screen", false, :segment_screen)}
        <Spacer size={4} />
        {Kati.Screens.Music.segment("menu_book", "Books", false, :segment_books)}
        <Spacer size={4} />
        {Kati.Screens.Music.segment("graphic_eq", "Music", true, :segment_music)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # The selected slab is a lifted card in a trough, not a tinted rectangle:
  # `0 1px 2px rgba(26,25,23,.06), 0 6px 12px -8px rgba(26,25,23,.4)`. Written
  # out rather than borrowed from Kati.Theme because no token is this light,
  # and rounding it to shadow_card_soft would make the control look pressed.
  @doc false
  def segment(icon, label, true, tag) do
    fg = Kati.Theme.ink()
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={Kati.Theme.card(:light)}
        shadow="0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"
        align="center"
        on_tap={tap}
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
    fg = 0xFFAFA89E
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={38} corner_radius={14} background={0x00FFFFFF} align="center" on_tap={tap}>
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight="semibold" text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def on_repeat do
    tiles =
      Sample.albums()
      |> Enum.map(&album/1)
      |> Enum.intersperse(album_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def album_gap, do: ~MOB"<Spacer size={12} />"

  # Weighted rather than 112 wide — the export's own `flex:1`. See the moduledoc.
  @doc false
  def album(item) do
    ~MOB"""
    <Column weight={1.0}>
      {Kati.Screens.Music.cover(item)}
      <Spacer size={9} />
      <Text text={item.title} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={2} />
      <Text text={item.artist} text_size={11} text_color={0xFF8A8479} max_lines={1} />
      <Spacer size={3} />
      <Text text={item.plays} font_family="mono" text_size={10} text_color={0xFFE8823C} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def cover(item) do
    case Kati.Design.Images.poster(item.seed) do
      nil ->
        ~MOB"""
        <Box fill_width={true} aspect_ratio={1.0} corner_radius={12} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()} />
        """

      src ->
        ~MOB"""
        <Box fill_width={true} aspect_ratio={1.0} corner_radius={12} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()}>
          <Image src={src} fill_width={true} aspect_ratio={1.0} corner_radius={12} content_mode="fill" />
        </Box>
        """
    end
  end

  @doc false
  def listening do
    l = Sample.listening()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text text={String.upcase(l.label)} font_family="mono" text_size={10} letter_spacing={0.14} text_color={0xFFB09A72} />
            <Spacer size={6} />
            <Text text={l.total} text_size={30} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} />
          </Column>
          <Spacer size={12} />
          <Text text={l.window} font_family="mono" text_size={11} text_color={0xFFB09A72} max_lines={1} />
        </Row>
        <Spacer size={16} />
        {Kati.Screens.Music.bars(l.bars)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # Twenty bars sharing the width by weight, each with a declared height inside
  # a 40pt field. `align="bottom"` is the whole trick — without it every bar
  # hangs from the top and the shape inverts.
  @doc false
  def bars(list) do
    children =
      list
      |> Enum.map(fn {height, tone} -> bar(height, tone) end)
      |> Enum.intersperse(bar_gap())

    ~MOB"""
    <Row fill_width={true} height={40} align="bottom">
      {children}
    </Row>
    """
  end

  @doc false
  def bar_gap, do: ~MOB"<Spacer size={3} />"

  @doc false
  def bar(height, tone) do
    ~MOB"""
    <Box weight={1.0} height={height} corner_radius={3} background={tone} />
    """
  end

  @doc false
  def releases do
    rows =
      Sample.releases()
      |> Enum.map(&release_row/1)
      |> Enum.intersperse(release_gap())

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc false
  def release_gap, do: ~MOB"<Spacer size={9} />"

  # The 8pt dot is orange and stays orange even for the Friday record: the
  # drawing marks both rows, and both are the watcher saying *this is new*.
  @doc false
  def release_row(row) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={18}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      padding_top={10}
      padding_bottom={10}
      align="center"
    >
      {Kati.Screens.Music.release_art(row)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={row.artist} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer size={4} />
        <Text text={row.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box width={8} height={8} corner_radius={4} background={0xFFE8823C} />
    </Row>
    """
  end

  @doc false
  def release_art(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={44} height={44} corner_radius={10} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={44} height={44} corner_radius={10} content_mode="fill" />
        """
    end
  end

  # Screen is the built shelf, so its segment navigates. Books has no screen
  # yet — #60 scoped v1 to one media domain — and Music is where we already
  # are, so both swallow the tap rather than pretending.
  @impl true
  def handle_tap(:segment_screen, socket) do
    {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.Library)}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
