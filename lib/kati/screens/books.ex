defmodule Kati.Screens.Books do
  @moduledoc """
  Screen 20 — the Books shelf, the Library root with **Books** selected.

  Built to `test/design/screens/20.html`. The drawing's own caption is the
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

  ## Why this screen still reads `Kati.Books.Sample`

  Screen 03 moved onto `Kati.Media` (see `Kati.Screens.Library.shelf/0`), and
  most of this one could follow it. `Kati.Media.TrackedTitle` already takes
  `kind: :book`; its `:shelf` action carries an index documented as serving
  "screens 03, 20 and 21"; and `Kati.Media.CachedTitle`'s own moduledoc names
  *this* screen for the `p.214/380` line — `progress_page` on the durable row
  over `page_count` on the cache row, put back together at render time by
  `progress/2`, which answers a bare position rather than inventing a total
  when the cache is gone. The grid, the chips and the counting half of the
  header are all reachable today.

  The **Reading now** hero is what keeps the screen whole, because two of the
  four things it says have no column anywhere in `Kati.Media`:

    * **`Ines Karvel`** — a byline. `Kati.Media.CachedTitle` holds `title`,
      `title_original`, `overview`, `poster_path`, `backdrop_path`,
      `runtime_minutes` and `genres`, and not one of them is an author. The
      same absence blocks screen 21's artist, so this is one missing column
      rather than two.
    * **`23 MIN/DAY PACE`** — a rate, and nothing stores the minutes it is a
      rate of. `Kati.Media.Watch` records that something was read and when,
      never for how long, and `Kati.Media.TrackedTitle.progress_page` is one
      current position with no history behind it, so a per-day pace cannot be
      computed from anything stored. The `p. 214 / 380` in front of it *is*
      expressible; the clause after the dot is not.

  Half-moving it is the thing not to do. The grid could be read today, but a
  screen whose six covers are the user's own and whose hero names a book they
  do not own is a worse lie than one that is stand-in throughout and says so —
  and the hero is the largest object on the screen.

  The shelf is also empty by decision rather than by accident: #60 scoped v1 to
  one media domain, Screen, which is why screen 03 draws Books and Music
  inactive and `Kati.Screens.Library.visible/3` answers `[]` for them. Nothing
  in v1 writes a `kind: :book` row, so a query here would return nothing on
  every device and the fallback would be carrying the screen regardless.

  `64 books` and the `All 64` chip stay literals for the drawing's own reason,
  recorded in `Kati.Books.Sample`: a shelf is a window onto a library, and
  counting the six covers would quietly turn 64 into 6.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.Books.Sample
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaProgress
  alias Kati.Theme
  alias Kati.Theme.Palette

  @impl true
  # The shelf opens on `All`, which is the chip the drawing draws selected.
  # `Kati.Screens.Library.load/1` opens on the same word for the same reason:
  # screens 03, 20 and 21 are one control drawn three times.
  def load(socket), do: Mob.Socket.assign(socket, :filter, "All")

  @doc false
  def content(assigns) do
    filter = assigns.filter

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
        {Kati.Screens.Books.chips(filter)}
        {Kati.Screens.Books.grid(filter)}
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
            max_font_scale={1.6}
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
        <Box width={74} height={110} on_tap={{self(), :open_book}}>
          {Kati.Screens.Books.hero_cover(r)}
        </Box>
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
          {Kati.Screens.Books.hero_actions()}
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The hero's two controls: `Log progress`, and a timer shortcut beside it.

  Screen 70's ticket named no control that opens it, and this is where the
  drawing put one — on the hero, because the book you are reading is the only
  book a session can be logged against without first choosing one. The timer
  disc is the same sheet with its timer already running, which is why it is a
  shortcut rather than a second destination.
  """
  @spec hero_actions() :: map()
  def hero_actions do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        <Row
          height={34}
          corner_radius={17}
          background={Palette.ink_fill()}
          padding_left={14}
          padding_right={14}
          align="center"
          on_tap={{self(), :log_progress}}
        >
          {Kati.UI.symbol("add", size: 16, color: Palette.on_ink())}
          <Spacer size={6} />
          <Text
            text="Log progress"
            text_size={12}
            font_weight="semibold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
        <Spacer size={8} />
        <Box
          width={34}
          height={34}
          corner_radius={17}
          background={Palette.paper()}
          align="center"
          on_tap={{self(), :start_timer}}
        >
          {Kati.UI.symbol("timer", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer weight={1.0} />
      </Row>
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
  def chips(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Kati.Books.Sample.chips()
           |> Enum.map(fn {label, count} ->
             Kati.Screens.Books.chip(label, count, label == active)
           end)
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

  Screen 19 draws the same chip and adopts the same component. This one used to
  be passed no `on_toggle` at all — *the drawing gives these chips no
  destination and a tap that does nothing is worse than no tap* — and the
  destination that paragraph went looking for was never a push. It is this
  screen in another state, which is exactly what screen 03's identical chips
  do: `library.ex:896-898` passes the same `on_toggle`, answered at
  `library.ex:1270-1271`, and 20 is 03 rebuilt from the identical parts. The
  tag carries the label, so a fifth chip is a change to
  `Kati.Books.Sample.chips/0` and not to this file.

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
      # The label and not the index: `Kati.Books.Sample.chips/0` is the order
      # the drawing draws, and a tag built from a position rots the moment that
      # order changes. `Kati.Screens.Library.chip/3` spells it the same way.
      on_toggle: String.to_atom("filter_" <> label),
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
  def grid(filter) do
    rows =
      Sample.books()
      |> Kati.Screens.Books.visible(filter)
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.Screens.Books.grid_row/1)
      |> Enum.intersperse(Kati.Screens.Books.row_gap())

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc """
  The books a chip leaves on the shelf.

  Read off the fraction, because there is nothing else to read it off:
  `Kati.Books.Sample`'s rows carry a `progress` and the line the tile prints,
  and no `status` column — so *Reading* is a book between the two ends rather
  than a row that says so. The drawing agrees with that arithmetic, which is
  what says it is the right read: two of the six are strictly between 0 and 1,
  and the chip above them says **Reading 2**.

  The chips keep their drawn counts and do not count this. `All 64` is a window
  onto a library of 64 — `Kati.Books.Sample`'s moduledoc — and counting the six
  visible would turn 64 into 6, which is the same reason the header says
  `64 books` over six covers.

  A filter that leaves nothing draws an empty grid under live chips rather than
  an empty state: `Kati.Screens.Library.shelf_body/3` branches on the SHELF
  being empty and never on the filter, for the reason written out there.

      iex> Kati.Screens.Books.visible(Kati.Books.Sample.books(), "Reading") |> length()
      2
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(books, "Reading"),
    do: Enum.filter(books, &(&1.progress > 0.0 and &1.progress < 1.0))

  def visible(books, "Finished"), do: Enum.filter(books, &(&1.progress >= 1.0))

  def visible(books, "To read"), do: Enum.filter(books, &(&1.progress == 0.0))

  def visible(books, _all), do: books

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
  @doc """
  One grid tile's tag, built from the book's seed.

  Six tiles sharing `:open_book` gave six nodes one `accessibility_id`, and
  `onNodeWithTag` throws on the second match — the shelf was unaddressable on a
  device rather than merely untested (#97).

  The seed and not the title: `Kati.Books.Sample`'s seeds are unique per row
  where a title need not be, and #97's first trap is that a name which is not
  unique is not an identity. The hero keeps the bare `:open_book` because it is
  one node, and because it draws `reading_now/0` — whose seed is `bookaa1`, the
  same seed as the first tile. Tagging both by seed would collide again.

      iex> Kati.Screens.Books.book_tag(%{seed: "bookcc3"})
      :open_book_bookcc3

      iex> Kati.Screens.Books.book_tag(%{})
      :open_book
  """
  @spec book_tag(map()) :: atom()
  def book_tag(book) do
    case book |> Map.get(:seed, "") |> to_string() |> String.trim() do
      "" -> :open_book
      seed -> String.to_atom("open_book_" <> seed)
    end
  end

  @doc false
  def tile(book) do
    ~MOB"""
    <Column weight={1.0} on_tap={{self(), Kati.Screens.Books.book_tag(book)}}>
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
  def handle_tap(:log_progress, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogProgress)}

  # The disc is the hero's second control and the sheet's timer state is what
  # makes it one: `hero_actions/0` calls it *the same sheet with its timer
  # already running*, and it pushed exactly what `:log_progress` pushed — so the
  # two controls were the same destination in the same state, one button drawn
  # twice.
  #
  # The map is written out here rather than built by a `params_for`-style call
  # into `Kati.Screens.LogProgress`, which is where the key is read. That is not
  # a preference: this screen reads no store at all — its shelf is
  # `Kati.Books.Sample`, see the moduledoc — and a call into the sheet's module
  # would put it in the compiled call graph `Kati.ScreenEmptyDatabaseTest`
  # derives its coverage from, as a database reader with no database read.
  # `Kati.Screens.Library`'s search disc spells its params the same way.
  #
  # No book id goes with it, and that is this screen's own limit rather than an
  # oversight: the shelf's rows carry a `cover_seed` and name no
  # `Kati.Books.Book`. So the sheet still answers with the shelf's first, which
  # is what it answers today.
  def handle_tap(:start_timer, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogProgress, %{timing?: true})}

  def handle_tap(:open_book, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.BookDetail)}

  def handle_tap(:open_screen, socket),
    do: {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.Library)}

  @doc """
  The other two shelves, and the search and sort discs beside them.

  The three shelves are one control drawn three times — screens 03, 20 and 21
  carry the same segmented row — and only 03 answered all of it. From here
  **Books** was the segment you were already on and **Music** did nothing at
  all, so a reader who came Screen → Books was stuck with one way back and no
  way across. That is the shape of a tab that does not work.

  **Push, and `:open_screen` above still resets** — the asymmetry is the
  difference between a peer and a root. `Kati.Screens.Library` is a dock root
  and these two are pushed from it, so returning to Screen has to reset the
  stack or the dock would sit under a pushed page; crossing to Music pushes,
  which is exactly what 03's own `shelf_Music` does. One rule read off the
  screen that already had it, rather than a second rule invented here.

  Search is `Kati.Screens.Search` — the same screen 03's disc opens — and sort
  is `Kati.Screens.ShelfFilters`, whose board is 145 and whose caption is *one
  sheet for screens 03, 20 and 21 — three sheets would end the "identical
  parts" claim within a release.* This paragraph used to say sort had nowhere
  to go and that no board in the 165 draws a sort sheet for any shelf. 145 is
  that board: the sheet is built, it mounts, it is registered `:push` at
  `gallery.ex:184`, and `Kati.Screens.Library` already pushes it
  (`library.ex:1246-1251`) — from a ⋯ menu row, which 03 grew only because no
  shelf had claimed its disc yet. The trailing `sort` disc board 20 draws in
  its own header, beside search, is the door 145's caption describes, so the
  disc pushes it rather than staying on `Kati.ScreenTapSweepTest`'s backlog.

  **Bare, and that is the sheet's limit rather than a forgotten argument.** 145
  also says *only the section-specific sort label changes: Runtime, Pages,
  Length* — but `Kati.Screens.ShelfFilters.mount/3` matches `_params`, and its
  five sort rows come from `Kati.Library.ShelfFiltersSample.sort_options/0`,
  where `Runtime` is a literal. There is no key to name a shelf in, and writing
  one the sheet does not read is an argument nobody can check —
  `Kati.ScreenParamsSweepTest`'s own subject. When 145 learns which shelf
  opened it, this push gains its third argument and that sweep starts holding
  it to it.

  Screens 03 and 57 draw the same disc and are still on the backlog. 145's
  caption names 03 first, so the three of them are one control drawn three
  times here too: the two that could be reached from this batch's files are
  wired, and `Kati.Screens.Library`'s disc is the one left to move — its own
  `menu/1` already says *when 03 is redrawn with its filter disc, `ShelfFilters`
  moves to it and comes out of this menu*, and 03 has had the disc all along.
  """
  def handle_tap(:open_music, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Music)}

  def handle_tap(:open_books, socket), do: {:noreply, socket}

  # See `Kati.Screens.Library`'s own clause: the disc carries the empty query it
  # actually has, so 19 stops opening on whatever `Kati.Search.handed_over/0`
  # was still holding from a previous launch, and carries its own name so the
  # pill leads back to the shelf you left.
  #
  # `Books` and not `Library`: `pop_screen/1` returns to screen 20, which is a
  # root of its own rather than a page inside 03.
  def handle_tap(:open_search, socket),
    do:
      {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search, %{query: "", back: "Books"})}

  # Board 145's sheet, from the disc board 20 draws beside search. Pushed with
  # two arguments and not three — see the paragraph on `:open_music` for why the
  # shelf cannot be named yet, and what makes it nameable.
  def handle_tap(:open_sort, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ShelfFilters)}

  # Every grid tile, by its own seed — see `book_tag/1`. They all open the same
  # screen today: `Kati.Screens.BookDetail` takes no argument, so this is
  # identity for the sake of being addressable rather than for routing.
  #
  # The prefix carries its trailing underscore on purpose. `"open_book"` alone
  # also matches `:open_books`, the Books segment at the top of this screen,
  # and swallowing it here would send the segment to a book detail.
  #
  # Below the named clauses, above the catch-all: a prefix match placed before
  # them makes every one of them unreachable, silently.
  def handle_tap(tag, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      # The four shelf chips, by their own labels — see `chip/3`. One clause for
      # the family, so a fifth chip is a data change rather than a code change,
      # which is the rule `Kati.Screens.Library.handle_tap/2` already follows.
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      "open_book_" <> _seed ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.BookDetail)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
