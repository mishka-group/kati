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

  ## Where the data comes from

  `Kati.Books.Book`, through `page/0` — one entry point for the whole screen,
  because the grid, the hero and the header's counts are three views of one
  shelf and three entry points could show three different shelves. The grid,
  the subtitle and the chips are all shaped from the single `:shelf` read; the
  hero costs three more, which is what reading it through screen 66's own
  `shelved_book/1` buys.

  This file used to argue at length that the move had to wait on `Kati.Media`
  growing an author column and a per-sitting history. Both exist, and not on
  `Kati.Media`: `Kati.Books.Book` holds `author`, and
  `Kati.Books.ReadingSession` holds the minutes a pace is a rate of. So the
  hero's two blocked values — `Ines Karvel` and `23 MIN/DAY PACE` — are read
  now, and read through screen 66's own `shelved_book/1` rather than through a
  second reader, so the shelf and the detail page cannot disagree about the
  book they are both drawing.

  ## The drawing is the floor, not a stage this screen has passed

  With nothing shelved the screen draws `Kati.Books.Sample` exactly — the six
  covers, the hero, `64 books · 2 reading` and the `All 64` chip — which is the
  values `test/design/screens/20.html` was captured from. FIDELITY's rule:
  missing data is not a reason for a blank screen.

  A shelf holding one book shows **one** book. The counts move with it, and the
  `64` that `Kati.Books.Sample` defends as a literal is defended for the
  *drawing* — a shelf is a window onto a library of 64 — and stops being a
  defence the moment there is a real shelf to count. Half-moving is still the
  thing not to do, for the reason this file gave when it could not move at all:
  six covers that are the user's own under a hero naming a book they do not own
  would be a worse lie than a screen that is stand-in throughout. So `page/0`
  branches once, on the shelf, and every value on the screen goes with it.

  ## Which book the hero is

  `Kati.Books.Book`'s `read :reading`, newest first, and its head — the card
  says *Reading now* and that action is the shelf's own definition of what is
  being read (`book.ex:145`).

  With nothing marked `:reading` but books on the shelf, it is the shelf's head
  — `read :shelf`, most recently touched. That is a stretch of the card's
  label and it is the smaller of the two available stretches: the alternative
  is the drawing's hero, a book that is not on their shelf, over a grid that
  is. A book you have and touched last is at least yours.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.Books.Book
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
  #
  # The page is read once, here, and carried on the socket. `handle_tap/2` reads
  # it back to resolve a tapped tile to its row — see `open_book/2` — and a
  # second query at tap time could answer with a shelf that had moved under the
  # tile the person actually pressed.
  def load(socket), do: Mob.Socket.assign(socket, filter: "All", page: page())

  @doc """
  Everything this screen reads, in one map: the shelf, the hero, the header's
  subtitle and the chips.

  One branch and not four. Either every value on the page is this reader's or
  every value is the drawing's — the arrangement `Kati.Screens.BookDetail.book/0`
  uses for screen 66, and for the reason the moduledoc gives: a real grid under
  a drawn hero is a worse screen than an honest fixture.
  """
  @spec page() :: map()
  def page do
    case shelved() do
      [] ->
        drawn_page()

      books ->
        %{
          books: books,
          hero: hero(books),
          subtitle: Kati.Screens.Books.subtitle(books),
          chips: Kati.Screens.Books.chip_counts(books)
        }
    end
  end

  @doc """
  The drawing's values, unconditionally — the fixture, not a fallback path.

  `test/design/screens/20.html` was captured from exactly this map, and
  `Kati.ScreenEmptyDatabaseTest` compares it with what `page/0` answers when
  nothing is shelved.
  """
  @spec drawn_page() :: map()
  def drawn_page do
    %{
      books: Kati.Screens.Books.drawn_books(),
      hero: Sample.reading_now(),
      subtitle: Sample.subtitle(),
      chips: Sample.chips()
    }
  end

  # The shelf, most recently touched first — `Kati.Books.Book`'s own `:shelf`,
  # which is documented as screen 20's order.
  #
  # Same degradation `Kati.Screens.Library.shelf/0` makes: a screen that cannot
  # reach its store answers `[]` and draws the drawing, rather than taking the
  # activity down.
  defp shelved do
    case Ash.read(Book, action: :shelf) do
      {:ok, books} -> Enum.map(books, &Kati.Screens.Books.shaped/1)
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc """
  One book in the shape the grid, the chips and the counts all read.

  `id` is the row's own, and it is the only field here that is an identity
  rather than a caption — it is what a tapped tile carries to the screen it
  opens. `Kati.Library.shaped/3` says the same of its own, and
  `Kati.Books.Sample`'s rows do not pass through here and so do not have one,
  which is how `open_book/2` tells a shelf tile from a drawn one.

  `progress` is a float and never `nil`, because the drawing keeps the rail
  under **every** cover including the two at 0% — see the moduledoc. A book
  with no denominator has no fraction (`Kati.Books.Book.fraction/1` answers
  `nil` rather than a zero that would claim you have read none of it), so the
  rail falls back to the one thing its status does say: a finished book is
  full, anything else is empty. The line under the cover carries the honest
  version — `Kati.Books.Book.shelf_line/1` prints `p.214` with no total.
  """
  @spec shaped(Book.t()) :: map()
  def shaped(%Book{} = book) do
    %{
      id: book.id,
      title: book.title,
      seed: book.cover_seed,
      status: book.status,
      progress: rail(book),
      line: Book.shelf_line(book)
    }
  end

  @doc """
  The fraction a cover's rail is drawn at, for a row of either kind.

  Public and shared because the grid and the hero draw the same book, and the
  first version of this screen let them disagree: the grid shaped a row through
  `shaped/1` and the hero through `Kati.Screens.BookDetail.shelved_book/1`,
  whose `progress` is `nil` for a book with no denominator. A finished
  audiobook was then drawn **full in the grid and empty in the hero, in one
  render** — the same book, twice, at 100% and 0%.

  One rule, and it is the honest one: a book with no fraction has none
  (`Kati.Books.Book.fraction/1` answers `nil` rather than a zero that would
  claim you have read none of it), so the rail falls back to the one thing its
  status does say. Finished is full; anything else is empty. The line under the
  cover carries the truth either way — `shelf_line/1` prints `p. 214` with no
  total.
  """
  @spec rail(float() | nil, atom()) :: float()
  def rail(nil, :finished), do: 1.0
  def rail(nil, _status), do: 0.0
  def rail(fraction, _status) when is_float(fraction), do: fraction

  defp rail(%Book{} = book), do: rail(Book.fraction(book), book.status)

  @doc """
  The six books `test/design/screens/20.html` draws, in its own order.

  Stand-in data and marked as such — `Kati.Books.Sample`'s moduledoc says so at
  length. Each row is given the `status` a real one carries, so `visible/2` and
  the counts ask one question of both kinds of row and cannot answer it two
  different ways. `Kati.Screens.Library.drawn_titles/0` does exactly this, and
  the mapping is the one this file used to make inline: 0 is to read, 1 is
  finished, anything between is reading. The drawing agrees with that
  arithmetic — two of the six are strictly between the ends, and the chip above
  them says **Reading 2**.
  """
  @spec drawn_books() :: [map()]
  def drawn_books, do: Enum.map(Sample.books(), &with_status/1)

  defp with_status(%{progress: progress} = row) do
    status =
      cond do
        progress <= 0.0 -> :not_started
        progress >= 1.0 -> :finished
        true -> :reading
      end

    Map.put(row, :status, status)
  end

  @doc """
  The hero, shaped as `reading_now/1` draws it — or the drawing's.

  Read through `Kati.Screens.BookDetail.shelved_book/1` rather than through a
  second reader, which is the rule `Kati.Screens.LogProgress.book/1` follows
  for the same book: the pace line is arithmetic over
  `Kati.Books.ReadingSession`, and two implementations of it is two chances for
  the shelf and the detail page to print different numbers under one title.

  A `nil` back from that reader means the row went between the two queries. It
  answers with the drawing rather than with some other book, which is
  `shelved_book/1`'s own rule arriving one caller along.
  """
  @spec hero([map()]) :: map()
  def hero([]), do: Sample.reading_now()

  def hero(books) do
    case Kati.Screens.BookDetail.shelved_book(hero_id(books)) do
      nil -> Sample.reading_now()
      book -> from_detail(book)
    end
  end

  # The book being read, and the shelf's head when nothing says one is — see the
  # moduledoc for why that is the smaller of the two available stretches.
  defp hero_id(books) do
    case Ash.read(Book, action: :reading) do
      {:ok, [%Book{id: id} | _rest]} -> id
      _other -> books |> hd() |> Map.get(:id)
    end
  rescue
    _error -> books |> hd() |> Map.get(:id)
  end

  # Screen 66's shape, narrowed to the six values this card draws. `label` is
  # copy — the drawing's own word for what the card is — and `pace` is 66's
  # `progress_line`, which is the same string in the same format: `p. 214 / 380`
  # and, when a week of sittings can answer it, `· 23 MIN/DAY PACE`.
  #
  # `author` degrades to the empty string rather than to a name: a book typed by
  # hand may have none, and `Kati.Books.Book.author` is nullable for that.
  defp from_detail(book) do
    %{
      id: book.id,
      label: "Reading now",
      title: book.title,
      author: book.author || "",
      seed: book.seed,
      # `rail/2` and not `|| 0.0`: the grid draws this same book through
      # `shaped/1`, and a zero here where the grid has a one is the same book
      # at two different fractions in one render. See `rail/2`.
      progress: Kati.Screens.Books.rail(book.progress, book.status),
      pace: book.progress_line
    }
  end

  @doc """
  The header's mono line: `12 books · 2 reading`.

  Counted, where `Kati.Books.Sample.subtitle/0` is a literal — see the
  moduledoc on why the drawing's `64` is not arithmetic and a real shelf's
  count is. `Kati.Screens.Library.subtitle/1` is the same line for screen 03.

      iex> Kati.Screens.Books.subtitle([%{status: :reading}, %{status: :finished}])
      "2 books · 1 reading"
  """
  @spec subtitle([map()]) :: String.t()
  def subtitle(books) do
    "#{length(books)} books · #{Enum.count(books, &(&1.status == :reading))} reading"
  end

  @doc """
  The four chips and the counts beside two of them.

  The asymmetry is the drawing's and is kept: *All* and *Reading* carry a
  number, *Finished* and *To read* do not — `Kati.Books.Sample.chips/0` records
  why. Counts are strings because that is what the drawing's mono slot takes
  and what `chip_count/2` draws.

      iex> Kati.Screens.Books.chip_counts([%{status: :reading}, %{status: :finished}])
      [{"All", "2"}, {"Reading", "1"}, {"Finished", nil}, {"To read", nil}]
  """
  @spec chip_counts([map()]) :: [{String.t(), String.t() | nil}]
  def chip_counts(books) do
    [
      {"All", Integer.to_string(length(books))},
      {"Reading", books |> Enum.count(&(&1.status == :reading)) |> Integer.to_string()},
      {"Finished", nil},
      {"To read", nil}
    ]
  end

  @doc false
  def content(assigns) do
    filter = assigns.filter
    page = assigns.page

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Books.header(page.subtitle)}
        {Kati.Screens.Books.segments()}
        {Kati.Screens.Books.reading_now(page.hero)}
        {Kati.Screens.Books.chips(filter, page.chips)}
        {Kati.Screens.Books.grid(filter, page.books)}
      </Column>
    </Scroll>
    """
  end

  # `align="top"`, where screen 03's identical-looking header is centred. The
  # drawings differ — 03 says `align-items:center`, 20 says `flex-start` — and
  # the reason is the taller title block: the two discs hang from the top of
  # "Library" rather than floating beside its midpoint.
  @doc false
  def header(subtitle) do
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
            text={subtitle}
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
  def reading_now(r) do
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
  def chips(active, chips) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips
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
  tag carries the label, so a fifth chip is a change to `chip_counts/1` — and
  to `Kati.Books.Sample.chips/0`, which is the same four for the drawing — and
  not to this file.

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
      # The label and not the index: `chip_counts/1` is the order the drawing
      # draws, and a tag built from a position rots the moment that order
      # changes. `Kati.Screens.Library.chip/3` spells it the same way.
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
  def grid(filter, books) do
    rows =
      books
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

  Read off `status`, which every row carries: a real one from
  `Kati.Books.Book.status`, a drawn one from `drawn_books/0`, which derives it
  from the fraction the fixture has instead. One question of both kinds of row,
  so the two cannot be answered differently — `Kati.Screens.Library.visible/3`
  is the same arrangement for screen 03.

  Two of `Kati.Books.Book`'s five statuses are not a chip: a paused book and an
  abandoned one appear under **All** and under nothing else. The drawing offers
  four chips and inventing a fifth here would be this file drawing a control.

  A filter that leaves nothing draws an empty grid under live chips rather than
  an empty state: `Kati.Screens.Library.shelf_body/3` branches on the SHELF
  being empty and never on the filter, for the reason written out there.

      iex> Kati.Screens.Books.visible(Kati.Screens.Books.drawn_books(), "Reading") |> length()
      2
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(books, "Reading"), do: Enum.filter(books, &(&1.status == :reading))

  def visible(books, "Finished"), do: Enum.filter(books, &(&1.status == :finished))

  def visible(books, "To read"), do: Enum.filter(books, &(&1.status == :not_started))

  def visible(books, _all), do: books

  # A short last row must still be padded to three. The tiles are weighted, so
  # weights divide whatever is there and a row holding one book gives it the
  # whole width — which is what a shelf of one looked like. Screen 03's
  # `grid_row/1` pads for the same reason and with the same nothing.
  #
  # The drawing's six fill both rows exactly, so nothing is padded on the
  # fallback and its tree is unchanged.
  @doc false
  def grid_row(row) do
    row = row ++ List.duplicate(nil, 3 - length(row))

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
  One grid tile's tag: the book's id, or — for a drawn row — its seed.

  Six tiles sharing `:open_book` gave six nodes one `accessibility_id`, and
  `onNodeWithTag` throws on the second match — the shelf was unaddressable on a
  device rather than merely untested (#97).

  **The id first, because it is the only field that is one.** A shelf row's
  `cover_seed` is nullable and nothing stops two books sharing one, so a shelf
  tagged by seed puts #97 back the moment somebody types two books by hand.
  `Kati.Books.Sample`'s rows have no id and their seeds *are* unique per row,
  which is why the seed stays as the second answer rather than being dropped:
  it keeps the drawing's six tags exactly what they were.

  The hero keeps the bare `:open_book` because it is one node, and because it
  draws the same book the first tile often draws — tagging both by the same
  identity would collide again.

      iex> Kati.Screens.Books.book_tag(%{id: "3f2a", seed: "bookaa1"})
      :open_book_3f2a

      iex> Kati.Screens.Books.book_tag(%{seed: "bookcc3"})
      :open_book_bookcc3

      iex> Kati.Screens.Books.book_tag(%{})
      :open_book
  """
  @spec book_tag(map()) :: atom()
  def book_tag(book) do
    identity = Map.get(book, :id) || Map.get(book, :seed, "")

    case identity |> to_string() |> String.trim() do
      "" -> :open_book
      key -> String.to_atom("open_book_" <> key)
    end
  end

  @doc false
  def tile(nil), do: ~MOB"<Column weight={1.0} />"

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
  # The hero's own book, by name. `params_for/1` is the sheet's builder and the
  # key is spelled there, once, so the pill and the timer disc beside it cannot
  # disagree about what `:book_id` means.
  #
  # This clause used to push bare, and the reason it gave was true when it was
  # written: the hero was `Kati.Books.Sample.reading_now/0`, a literal map with
  # a cover seed and no id, so an argument built from it would have been `%{}`
  # and the ceremony would have read as a fix.
  # `Kati.ScreenParamsSweepTest`'s two inventories are the record of that, and
  # this file is the other half of the pair they describe. With nothing shelved
  # the hero is still that map and the push is still `%{}` — which is why the
  # door moves from one inventory to the other rather than off both.
  def handle_tap(:log_progress, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.LogProgress,
         Kati.Screens.LogProgress.params_for(socket.assigns.page.hero)
       )}

  # The disc is the hero's second control and the sheet's timer state is what
  # makes it one: `hero_actions/0` calls it *the same sheet with its timer
  # already running*, and it pushed exactly what `:log_progress` pushed — so the
  # two controls were the same destination in the same state, one button drawn
  # twice.
  #
  # The timer flag is merged onto the same builder's answer rather than written
  # out beside a hand-spelled key: a timer started on the hero and a session
  # logged from it are the same sitting on the same book, and two spellings of
  # the id would be one more thing to keep true.
  def handle_tap(:start_timer, socket) do
    # Named `timing` and not `params`: `Kati.ScreenParamsSweepTest` derives the
    # list of screens that READ a push from the word `params` appearing in a
    # screen's code, and a local on the pushing side would file this screen as
    # a reader it is not.
    timing =
      socket.assigns.page.hero
      |> Kati.Screens.LogProgress.params_for()
      |> Map.put(:timing?, true)

    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogProgress, timing)}
  end

  # The hero cover. Same book as the pill above it, through screen 66's own
  # builder — see `open_book/2` for the grid's half of this.
  def handle_tap(:open_book, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.BookDetail,
         Kati.Screens.BookDetail.params_for(socket.assigns.page.hero)
       )}

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

  # Every grid tile, by its own identity — see `book_tag/1`. The tag is now used
  # for routing and not only for being addressable: `open_book/2` resolves it
  # back to the row the grid drew and names that book to screen 66.
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

      "open_book_" <> _key ->
        {:noreply, Kati.Screens.Books.open_book(socket, tag)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  Open screen 66 on the tile that carries `tag`.

  The tag is resolved back to its row by running `book_tag/1` over the very list
  the grid was built from, rather than by reversing the string —
  `Kati.Screens.Library.open_tile/3` gives the reason, and it is sharper here:
  a seed is not a key anything can be looked up by, so the string would have to
  be trusted rather than matched.

  Read off `socket.assigns.page` and not off a fresh query. The shelf sorts on
  `updated_at`, so a read at tap time can hand back an order the person never
  saw, and "the tile they pressed" is a fact about the render.

  A row with no id — `Kati.Books.Sample`'s six, and a tag matching nothing —
  pushes with **no params at all** rather than with `%{book_id: nil}`, through
  the destination's own builder so the empty answer is spelled in one place.
  """
  @spec open_book(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def open_book(socket, tag) do
    row = Enum.find(socket.assigns.page.books, &(Kati.Screens.Books.book_tag(&1) == tag))

    Mob.Socket.push_screen(
      socket,
      Kati.Screens.BookDetail,
      Kati.Screens.BookDetail.params_for(row)
    )
  end
end
