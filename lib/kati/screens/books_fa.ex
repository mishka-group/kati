defmodule Kati.Screens.BooksFa do
  @moduledoc """
  Screen 176 — کتاب‌ها, the Persian Books shelf.

  Built to `test/design/screens/176.html`, from
  `design-briefs/D-38-a-book-onto-the-shelf.md`. The board's own annotation is
  the whole method: **57's page with 20's three substitutions** — the
  Reading-now card in place of the three quick tiles, book chips, and a
  three-across grid of radius-6 jackets. Nothing was redesigned to get here,
  which is the sentence screen 20 already carries about screen 03.

  ## The destination 57's second segment never had

  `Kati.Screens.LibraryFa`'s کتاب‌ها segment used to push
  `Kati.Screens.BookDetailFa` — its own clause said why: *there is no Persian
  Books SHELF in the 127 drawings, so the segment opens the one Persian book
  page that exists.* A Persian reader tapping the Books tab was dropped into
  one fixture book with no grid, no hero and no list to come back to. 176 is
  the shelf, and the segment lands on it now; 69 is reached from this page's
  covers, which is where a book detail is reached from in every other language
  the app draws.

  ## One entry point, and the hero comes out of it

  `page/0` reads `Kati.Books.Book`'s own `:shelf` **once** and derives the
  grid, the header's count line, the four chips and the hero from that one
  answer. Screen 20 spends three more reads getting its hero through
  `Kati.Screens.BookDetail.shelved_book/1`, and it has to: its card prints a
  **pace**, which is arithmetic over `Kati.Books.ReadingSession`. This card
  does not — the board's line is `ص. ۲۱۴ / ۳۸۰`, a position, which is `Book`
  data and nothing else — so a second reader here would buy nothing and would
  be a second chance for the shelf and its own hero to disagree about one book.

  The rail is the one value both the hero and its grid tile draw, so both take
  it from `Kati.Screens.Books.rail/2` — the rule screen 20 wrote after drawing
  one finished audiobook full in its grid and empty in its hero, in one render.

  ## The counts are the drawing's, until there is a shelf to count

  `Kati.Books.SampleFa` keeps ۶۴ کتاب · ۲ در حال خواندن over six covers for
  `Kati.Books.Sample`'s reason: a shelf is a window onto a library, not the
  whole of it. A real shelf is counted instead, because a header that
  disagrees with the grid under it is worse than one that moves —
  `Kati.Screens.LibraryFa.header_line/1` splits the same way.

  ## The empty shelf is drawn as a band, because that is how the board draws it

  Board 176 puts *قفسه خالی* under a quiet eyebrow at the foot of the page,
  beside its own annotation — a specimen of the state rather than the state.
  `D-38` asks for it because **no board in the 166 draws an empty shelf** and
  every device has one on the day it is installed. It is drawn on every render
  here, as board 155's *Refused* band is on screen 177, and the sentence in it
  is the one thing on this screen that is a promise: *add the first book with
  the + button*, which is the FAB three inches below it and the door this
  ticket builds.

  ## RTL, and the three things the mirror does not do by itself

  `Kati.Screens.Fa.frame/3` declares `rtl` on the root, so the header discs go
  to the left edge, the segmented trough reverses and the dock's home tab lands
  at the right — all of it because a `Row` lays out start-to-end and nothing
  here reverses a list by hand. Three things do not follow:

    * **Artwork never mirrors.** A jacket is a photograph.
      `Kati.Screens.LibraryFa` states it for posters and
      `Kati.Screens.BookDetailFa` again for stars.
    * **The vertical order never reverses.** Header, segments, hero, chips,
      grid — top to bottom, in both languages.
    * **The progress rail fills from the right**, because progress follows
      reading direction. Both rails are a `Row` with a weighted fill and a
      weighted remainder — `Kati.Screens.LibraryFa.progress/1` and
      `Kati.Components.MishkaProgress`'s `render: :box` — so start is the right
      edge and the fill lands there with nothing reversed.

  ## What a cover opens, and the book it opens on

  A tile's tag is the row's own id — `Kati.Screens.Books.book_tag/1`, one
  spelling for both shelves — so every cover has an `accessibility_id` of its
  own and #97's collision cannot come back.

  The push used to be **bare**, and this file said so and said why: 69 matched
  `_params`, so naming a book here would have been writing an argument the
  screen does not read. `D-59` retired that justification and then made it
  expensive. Screen 69 fills its whole page from the row now — status, position,
  rating, ISBN, series, borrower, notes, sittings — so a cover that named
  nothing opened a complete, authoritative record of **the head of the shelf**
  under the title of the book you pressed. One wrong string became twenty, and
  تمام شد wrote against the wrong book. `open_book/2` is the fix and it is the
  same shape `Kati.Screens.Books.open_book/2` has: the tag is resolved back over
  the list THIS RENDER drew, and the row goes to the destination's own builder.
  The two halves — this one and 69's `mount/3` — shipped together, because
  either alone still lands on the wrong book.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Books.Book
  alias Kati.Books.SampleFa
  alias Kati.Calendar.Shamsi
  alias Kati.Components.MishkaScrollArea
  alias Kati.Screens.Fa
  alias Kati.Screens.LibraryFa
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    socket
    |> Mob.Socket.assign(:page, Kati.Screens.BooksFa.page())
    |> Mob.Socket.assign(:filter, 0)
    |> then(&{:ok, &1})
  end

  @doc """
  Everything this screen reads, in one map: the shelf, the hero, the header and
  the chips.

  One branch and not four, which is `Kati.Screens.Books.page/0`'s arrangement
  and its argument: either every value on the page is this reader's or every
  value is the drawing's. Six covers that are the user's own under a hero
  naming a book they do not own would be a worse lie than a page that is
  stand-in throughout.
  """
  @spec page() :: map()
  def page do
    case Kati.Screens.BooksFa.shelved() do
      [] ->
        Kati.Screens.BooksFa.drawn_page()

      books ->
        %{
          books: books,
          hero: Kati.Screens.BooksFa.hero(books),
          header: Kati.Screens.BooksFa.header_line(books),
          chips: Kati.Screens.BooksFa.chip_counts(books)
        }
    end
  end

  @doc """
  The drawing's values, unconditionally — the fixture, not a fallback path.

  `test/design/screens/176.html` was captured from exactly this map, and
  `Kati.ScreenEmptyDatabaseTest` compares it with what `page/0` answers when
  nothing is shelved.
  """
  @spec drawn_page() :: map()
  def drawn_page do
    %{
      books: Kati.Screens.BooksFa.drawn_books(),
      hero: SampleFa.reading_now(),
      header: SampleFa.header(),
      chips: SampleFa.chips()
    }
  end

  @doc """
  The shelf, most recently touched first — `Kati.Books.Book`'s own `:shelf`.

  A screen that cannot reach its store answers `[]` and draws the drawing,
  rather than taking the activity down: `Kati.Screens.Books.shelved/0` and
  `Kati.Screens.Library.shelf/0` degrade the same way and for the same reason.
  """
  @spec shelved() :: [map()]
  def shelved do
    case Ash.read(Book, action: :shelf) do
      {:ok, books} -> Enum.map(books, &Kati.Screens.BooksFa.shaped/1)
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc """
  One book in the shape the grid, the hero, the chips and the counts all read.

  `id` is the row's own and is the only field here that is an identity rather
  than a caption — it is what a tapped cover carries. `Kati.Books.SampleFa`'s
  rows do not pass through here and so have none, by absence and never as
  `nil`, which is how `Kati.Screens.Books.book_tag/1` tells a shelf tile from a
  drawn one.

  `progress` is a float and never `nil`, through `Kati.Screens.Books.rail/2` —
  see the moduledoc.
  """
  @spec shaped(Book.t()) :: map()
  def shaped(%Book{} = book) do
    %{
      id: book.id,
      title: book.title,
      author: book.author || "",
      seed: book.cover_seed,
      status: book.status,
      progress: Kati.Screens.Books.rail(Book.fraction(book), book.status),
      line: Kati.Screens.BooksFa.line(book)
    }
  end

  @doc """
  The Persian line under a jacket.

  `Kati.Books.Book.shelf_line/1` clause for clause and in the same order: the
  status the user asserted comes before the position that is inferred from it,
  so a finished book says تمام‌شده even when nothing says how long it is. The
  last clause is the one no denominator can describe and it prints the page
  reached rather than a fraction of an unknown total — the honest version, and
  the one the resource already draws in Latin.

  Persian digits through `Kati.Calendar.Shamsi.fa/1`, in the `fa` face:
  `kati_mono.ttf` carries none of U+06F0–U+06F9, which is `Kati.Screens.Fa`'s
  second type rule.
  """
  @spec line(Book.t()) :: String.t()
  def line(%Book{status: :finished}), do: "تمام‌شده"
  def line(%Book{status: :not_started}), do: "شروع نشده"

  def line(%Book{current_page: page} = book) when is_integer(page) do
    case Book.extent(book) do
      {total, :pages} -> "ص. #{Shamsi.fa(page)} / #{Shamsi.fa(total)}"
      _other -> "ص. #{Shamsi.fa(page)}"
    end
  end

  # `current_page` is `allow_nil?: false` with a default of 0, so this clause
  # answers for a row that reached the shelf without going through the create
  # action — a seeded row, a restored backup mid-migration. `Kati.Calendar.Shamsi.fa/1`
  # takes an integer and nothing else, and a shelf that raised on one bad row
  # would take the whole page down rather than the caption of one jacket.
  def line(%Book{}), do: "در حال خواندن"

  @doc """
  The six books `test/design/screens/176.html` draws, in its own order.

  Stand-in data, and `Kati.Books.SampleFa` says so. Each row is given the
  `status` a real one carries, so `visible/2` and the chips ask one question of
  both kinds of row — `Kati.Screens.Books.drawn_books/0`'s arrangement, and the
  same arithmetic: 0 is شروع نشده, 1 is تمام‌شده, anything between is reading.
  The board agrees, and says ۲ در حال خواندن over exactly two such covers.
  """
  @spec drawn_books() :: [map()]
  def drawn_books do
    Enum.map(SampleFa.books(), fn %{progress: progress} = row ->
      status =
        cond do
          progress <= 0.0 -> :not_started
          progress >= 1.0 -> :finished
          true -> :reading
        end

      Map.put(row, :status, status)
    end)
  end

  @doc """
  The Reading-now card: the book being read, or the shelf's head.

  The same stretch screen 20 makes and for its reason — *a book you have and
  touched last is at least yours* — taken over the list this page already read
  rather than through a second query.

  ## The eyebrow is the row's own status word, and used to be a constant

  It read `Kati.Books.SampleFa.detail/0.status_label` — the literal در حال
  خواندن — for whatever row the card had picked, and this doc gave the reason:
  *so the card and screen 69 cannot come to call the state two different
  things.* `D-59` made that sentence false on the ordinary case. `hero/1` falls
  back to `hd(books)` when nothing is being read, so a shelf of hand-typed
  books captioned its head **reading** while screen 69, which now words the
  status off the row, called the same book **شروع نشده** — the two pages
  disagreeing about one book, one screen apart, which is the acceptance
  sentence `D-59` is written around.

  So it goes through `Kati.Screens.BookDetailFa.status_label/1`, which is the
  function 69's pill uses. One reader, one word: the card cannot say a book is
  being read unless the book says so. With a reading book on the shelf the
  eyebrow is still در حال خواندن, which is what board 176 draws.
  """
  @spec hero([map()]) :: map()
  def hero([]), do: SampleFa.reading_now()

  def hero(books) do
    row = Enum.find(books, &(&1.status == :reading)) || hd(books)

    %{
      id: row.id,
      label: SampleFa.labels().reading_now,
      title: row.title,
      author: row.author,
      seed: row.seed,
      progress: row.progress,
      pace: pace(row)
    }
  end

  # The line under the rail: a POSITION, or nothing. `line/1`'s first two
  # clauses word a status rather than a position — تمام‌شده, شروع نشده — and
  # this card already has a caption above the title saying what the section is,
  # so a shelf of unstarted books printed the same words twice, sixty points
  # apart, and a finished head printed them in two spellings. Screen 69's
  # `position_line/2` makes exactly this split for exactly this reason and this
  # is the shelf's half of it. `reading_now/1` drops the node and its gap when
  # the answer is nothing, which is house rule 5.
  defp pace(%{status: status}) when status in [:finished, :not_started], do: nil
  defp pace(row), do: row.line

  @doc false
  def pace_node(pace) when pace in [nil, ""], do: []

  def pace_node(pace) do
    assigns = %{pace: pace}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={8} />
      <Text
        text={@pace}
        font_family="fa"
        text_size={11}
        text_color={Kati.Theme.Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The header, counted off the shelf that is actually drawn.

  Two books of which one is being read reads `۲ کتاب · ۱ در حال خواندن`;
  `Kati.BooksByHandTest` asserts it against real rows rather than as a
  doctest, because a map's inspected key order is not a fact about this
  function.
  """
  @spec header_line([map()]) :: map()
  def header_line(books) do
    reading = Enum.count(books, &(&1.status == :reading))

    %{
      title: "کتابخانه",
      subtitle: "#{Shamsi.fa(length(books))} کتاب · #{Shamsi.fa(reading)} در حال خواندن"
    }
  end

  @doc """
  The four count chips, in the drawing's order.

  Read off `status`, never a fraction, for `Kati.Screens.LibraryFa`'s reason:
  `Kati.Books.Book` holds five states and only three are chips, so a shelf
  carrying a paused or an abandoned book has sub-counts that do not add to
  همه — which is the truth, and the same asymmetry screen 20's four chips have.
  """
  @spec chip_counts([map()]) :: [{String.t(), String.t()}]
  def chip_counts(books) do
    [
      {"همه", Shamsi.fa(length(books))},
      {"در حال خواندن", Shamsi.fa(Enum.count(books, &(&1.status == :reading)))},
      {"تمام‌شده", Shamsi.fa(Enum.count(books, &(&1.status == :finished)))},
      {"شروع نشده", Shamsi.fa(Enum.count(books, &(&1.status == :not_started)))}
    ]
  end

  def render(assigns) do
    Fa.frame(
      :library,
      Kati.Screens.BooksFa.content(assigns),
      Kati.Screens.Identity.of(__MODULE__)
    )
  end

  @doc false
  def content(assigns) do
    page = assigns.page
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
        {Kati.Screens.BooksFa.header(page.header)}
        {Kati.Screens.BooksFa.segments()}
        {Kati.Screens.BooksFa.reading_now(page.hero)}
        {Kati.Screens.BooksFa.chips(filter, page.chips)}
        {Kati.Screens.BooksFa.grid(Kati.Screens.BooksFa.visible(page.books, filter))}
        {Kati.Screens.BooksFa.empty_band()}
        {Kati.Screens.BooksFa.annotation()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The books a chip leaves on the shelf, by the chip's index.

  The index and not the label, for `Kati.Screens.LibraryFa`'s reason: the tag
  has to survive `String.to_atom/1`, the tap registry and an
  `accessibility_id`, and an index is ASCII and ordinal where a Persian label
  is a right-to-left string.

      iex> Kati.Screens.BooksFa.visible([%{status: :reading}, %{status: :finished}], 2)
      [%{status: :finished}]
  """
  @spec visible([map()], non_neg_integer()) :: [map()]
  def visible(books, 1), do: Enum.filter(books, &(&1.status == :reading))
  def visible(books, 2), do: Enum.filter(books, &(&1.status == :finished))
  def visible(books, 3), do: Enum.filter(books, &(&1.status == :not_started))
  def visible(books, _all), do: books

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
            text_color={Palette.muted()}
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

  @doc """
  The three shelf segments, with کتاب‌ها lit.

  `Kati.Screens.LibraryFa.segment/3` draws them, over
  `Kati.Books.SampleFa.segments/0` — one control, two shelves, and the tag
  carries the segment's INDEX for the reason `visible/2` gives. The lit one is
  a constant rather than an assign: this screen *is* the Books shelf, so
  tapping نمایش is a navigation and not a state.
  """
  @spec segments() :: map()
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
        {SampleFa.segments()
         |> Enum.with_index()
         |> Enum.map(fn {seg, i} -> LibraryFa.segment(seg, i, seg.on?) end)
         |> Enum.intersperse(LibraryFa.segment_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The Reading-now hero: a 74×110 jacket, the eyebrow, the title, the author,
  a 5pt rail and the position line — then the two controls under it.

  Screen 03 spends this space on three quick tiles; a book is read over weeks
  rather than picked from a rail, so the drawing gives the space to the one in
  progress. `Kati.Screens.Books.reading_bar/1` draws the rail, which is a `Row`
  with a weighted fill, so it fills from the right here for free.
  """
  @spec reading_now(map()) :: map()
  def reading_now(r) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
      >
        <Row fill_width={true} align="center">
          <Box width={74} height={110} on_tap={{self(), :open_book}}>
            {Kati.Screens.BooksFa.jacket(r.seed, 74, 110)}
          </Box>
          <Spacer size={14} />
          <Column weight={1.0}>
            <Text
              text={r.label}
              font_family="fa"
              text_size={11}
              font_weight="semibold"
              text_color={Palette.eyebrow()}
              max_lines={1}
            />
            <Spacer size={7} />
            <Text
              text={r.title}
              font_family="fa"
              text_size={16}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={r.author}
              font_family="fa"
              text_size={12}
              text_color={Palette.sub()}
              max_lines={1}
            />
            <Spacer size={12} />
            {Kati.Screens.Books.reading_bar(r.progress)}
            {Kati.Screens.BooksFa.pace_node(r.pace)}
          </Column>
        </Row>
        {Kati.Screens.BooksFa.hero_actions()}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The hero's two controls: ثبت پیشرفت, and a timer shortcut beside it.

  Screen 72's own name on the pill, because the book you are reading is the
  only book a session can be logged against without first choosing one. The
  disc is the same sheet with its timer already running, which is why it is a
  shortcut rather than a second destination — screen 20's pair, one script
  over.
  """
  @spec hero_actions() :: map()
  def hero_actions do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
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
          {UI.symbol("add", size: 16, color: Palette.on_ink())}
          <Spacer size={6} />
          <Text
            text="ثبت پیشرفت"
            font_family="fa"
            text_size={12}
            font_weight="semibold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
        <Spacer size={9} />
        <Box
          width={34}
          height={34}
          corner_radius={17}
          background={Palette.paper()}
          align="center"
          on_tap={{self(), :start_timer}}
        >
          {UI.symbol("timer", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc false
  def chips(filter, counts) do
    rail =
      ~MOB"""
      <Row>
        {counts
         |> Enum.with_index()
         |> Enum.map(fn {{label, count}, i} -> LibraryFa.chip(label, count, i, i == filter) end)
         |> Enum.intersperse(LibraryFa.chip_gap())}
      </Row>
      """

    scroller = MishkaScrollArea.scroll_area([orientation: :horizontal], [rail])

    ~MOB"""
    <Column fill_width={true}>
      {scroller}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def grid(books) do
    rows =
      books
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.Screens.BooksFa.grid_row/1)
      |> Enum.intersperse(Kati.Screens.BooksFa.row_gap())

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={22} />
    </Column>
    """
  end

  # A short last row is padded to three. The tiles are weighted, so a row
  # holding one book would otherwise give it the whole width — screen 20's
  # `grid_row/1` pads for the same reason and with the same nothing.
  @doc false
  def grid_row(row) do
    row = row ++ List.duplicate(nil, 3 - length(row))

    ~MOB"""
    <Row fill_width={true} align="top">
      {row
       |> Enum.map(&Kati.Screens.BooksFa.tile/1)
       |> Enum.intersperse(Kati.Screens.BooksFa.grid_gap())}
    </Row>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  # `height`, not `size` — a Spacer's `size` sets both axes and this one only
  # ever divides rows.
  @doc false
  def row_gap, do: ~MOB"<Spacer height={18} />"

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
        {Kati.Screens.BooksFa.jacket(book.seed, nil, 158)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {LibraryFa.progress(book.progress)}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text
        text={book.title}
        font_family="fa"
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={book.line}
        font_family="fa"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  A cover, at radius 6 and never mirrored.

  `width` is `nil` for a grid tile, which fills its weighted column, and 74 for
  the hero. A seed the app never shipped draws nothing rather than a grey
  rectangle with a broken image in it.
  """
  @spec jacket(String.t() | nil, pos_integer() | nil, pos_integer()) :: map()
  def jacket(seed, width, height) do
    assigns = %{src: Kati.Design.Images.poster(seed), width: width, height: height}

    cond do
      assigns.src == nil and width == nil ->
        ~MOB"<Spacer size={0} />"

      assigns.src == nil ->
        ~MOB"""
        <Box width={@width} height={@height} corner_radius={6} background={Palette.placeholder()} />
        """

      width == nil ->
        ~MOB"""
        <Image src={@src} fill_width={true} height={@height} corner_radius={6} content_mode="fill" />
        """

      true ->
        ~MOB"""
        <Box
          width={@width}
          height={@height}
          corner_radius={6}
          background={Palette.placeholder()}
          shadow="0 6 14 -6 #801A1917"
        >
          <Image src={@src} width={@width} height={@height} corner_radius={6} content_mode="fill" />
        </Box>
        """
    end
  end

  @doc """
  *قفسه خالی* — the empty shelf, under its own quiet eyebrow.

  Screen 27's shape (glyph, title, one sentence) in the band the board draws it
  in. See the moduledoc for why it is a band on every render rather than a
  branch: the board draws it that way, and `D-38` asks for it precisely because
  no board in the 166 draws a shelf with nothing on it.
  """
  @spec empty_band() :: map()
  def empty_band do
    empty = SampleFa.empty()

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BooksFa.quiet_eyebrow("قفسه خالی")}
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={56} height={56} corner_radius={18} background={Palette.paper()} align="center">
            {Kati.UI.symbol(empty.icon, size: 25, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text={empty.title}
          font_family="fa"
          text_size={15}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={8} />
        <Text
          text={empty.body}
          font_family="fa"
          text_size={12.5}
          line_height={1.9}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={10} />
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  A Persian eyebrow whose rule is quiet.

  `Kati.Screens.Fa.eyebrow/1` is this recipe with the accent rule, and takes no
  option for the other one. The house style is explicit that a quiet eyebrow
  swaps the rule to `#C4BDB3` — `Palette.rail_idle/0` — and both bands that
  label a specimen rather than a section use it. Not a change to `Fa`, which
  seven screens draw through.
  """
  @spec quiet_eyebrow(String.t()) :: map()
  def quiet_eyebrow(label) do
    assigns = %{label: label}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={@label}
          font_family="fa"
          font_weight="semibold"
          text_size={11}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The board's own note about how it was built, in its seven runs.

  Seven `<Text>` nodes and not one paragraph, because the board's `<strong>`s
  split the sentence and `Kati.ScreenDesignLiteralTest` compares a drawing's
  lines against the tree's — a single joined string is a different shape from
  the drawn one even when it reads the same.
  """
  @spec annotation() :: map()
  def annotation do
    Kati.Screens.BooksFa.runs([
      {"همان صفحه ۵۷ با سه جایگزینی صفحه ۲۰: کارت «در حال خواندن» به جای سه کاشی، چیپ‌های کتاب، و شبکه سه‌تایی با جلدهای",
       :plain},
      {"شعاع ۶", :bold},
      {". نوار پیشرفت", :plain},
      {"از راست پر می‌شود", :bold},
      {"، جلدها هرگز آینه نمی‌شوند، و ترتیب عمودی برعکس نمی‌شود.", :plain},
      {"شروع نشده", :bold},
      {"همان واژه‌ای است که ۱۵۶ به کار می‌برد — یک ثبت، در هر دو جا.", :plain}
    ])
  end

  @doc """
  A dashed aside whose paragraph is a list of runs.

  `Kati.Screens.Fa.note/2` takes one string, and this board's aside emphasises
  inside the sentence. The frame is that helper's, node for node — 1.5pt on
  `Palette.border/0` at radius 18 over no fill — and only the paragraph
  differs.
  """
  @spec runs([{String.t(), :plain | :bold}]) :: map()
  def runs(parts) do
    assigns = %{parts: parts}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {Enum.map(@parts, fn {text, weight} -> Kati.Screens.BooksFa.run(text, weight) end)}
      </Column>
    </Row>
    """
  end

  @doc false
  def run(text, weight) do
    assigns = %{text: text, bold?: weight == :bold}

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={12.5}
      line_height={1.85}
      font_weight={if @bold?, do: "semibold", else: "normal"}
      text_color={if @bold?, do: Palette.ink(), else: Palette.ink_soft()}
    />
    """
  end

  @doc """
  The FAB, which on a Books shelf adds a **book**.

  `Kati.Screens.Fa.dock_tap/3` answers `:fab` with `Kati.Screens.AddTitle` —
  the sheet screen 06's own note calls *one sheet reached from the + button* —
  and that sheet cannot find a book, so it would be the + on a Books shelf
  opening a film search. The board settles it in its own empty state, in as
  many words: **اولین کتاب را با دکمه + اضافه کنید**. So this screen answers
  `:fab` itself, before anything reaches the shared dock handler, and the
  sentence in the empty card is a promise the page keeps.

  This is the door screen 177 is reached by, and today the only one: `D-38`'s
  other three — 154's third Kind chip, 06's fourth filter chip and 89's Books
  scope — are edits to boards this export did not ship, and inventing a control
  on a board that does not draw one is the one thing this pipeline does not
  allow.
  """
  def handle_info({:tap, :fab}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHandBook)}

  # The hero's own book, by name — `params_for/1` is screen 72's builder and the
  # key is spelled there once, so the pill and the disc beside it cannot
  # disagree about what `:book_id` means. With nothing shelved the hero is
  # `Kati.Books.SampleFa`'s and carries no id, which is the state
  # `Kati.ScreenParamsSweepTest`'s `@empty_builders` records for screens 20, 66
  # and 69's identical pill.
  def handle_info({:tap, :log_progress}, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.LogProgressFa,
         Kati.Screens.LogProgress.params_for(socket.assigns.page.hero)
       )}

  # The same sheet with its timer already running. Merged onto the same
  # builder's answer rather than beside a hand-spelled key: a timer started on
  # the hero and a session logged from it are the same sitting on the same book.
  def handle_info({:tap, :start_timer}, socket) do
    timing =
      socket.assigns.page.hero
      |> Kati.Screens.LogProgress.params_for()
      |> Map.put(:timing?, true)

    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogProgressFa, timing)}
  end

  # The hero's cover. The same book as the eyebrow beside it, through screen
  # 69's own builder — `Kati.Screens.Books.handle_tap(:open_book, …)` is this
  # clause in the other language, and `open_book/2` below is the grid's half.
  def handle_info({:tap, :open_book}, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.BookDetailFa,
         Kati.Screens.BookDetail.params_for(socket.assigns.page.hero)
       )}

  def handle_info({:tap, :open_search}, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.Search, %{query: "", back: "کتاب‌ها"})}

  # Board 145's sheet, from the disc board 176 draws beside search. Bare for the
  # reason screens 03, 20 and 57 are: `Kati.Screens.ShelfFilters.mount/3`
  # matches `_params` and its sort labels are literals, so there is no key to
  # name a shelf in.
  def handle_info({:tap, :open_sort}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ShelfFilters)}

  # One clause for every chip, every segment and every cover, because each tag
  # carries its own index or id. Anything left over is the dock's.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      # نمایش — back to the Screen shelf, which is this root's own page.
      "shelf_0" ->
        {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.LibraryFa)}

      # موسیقی. There is no Persian music SHELF in the drawings, so the segment
      # opens the one Persian album page that exists — `Kati.Screens.LibraryFa`
      # records the same absence for the same segment.
      "shelf_2" ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AlbumDetailFa)}

      "shelf_1" ->
        {:noreply, socket}

      "open_book_" <> _key ->
        {:noreply, Kati.Screens.BooksFa.open_book(socket, tag)}

      "filter_" <> index ->
        {:noreply, Mob.Socket.assign(socket, :filter, String.to_integer(index))}

      _other ->
        Fa.dock_tap(tag, :library, socket)
    end
  end

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :library, socket)
  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Open screen 69 on the tile that carries `tag`.

  `Kati.Screens.Books.open_book/2` in the mirror, and its two arguments are
  quoted here because both are load-bearing and neither is obvious.

  The tag is resolved back to its row by running `Kati.Screens.Books.book_tag/1`
  over **the very list the grid was built from**, rather than by reversing the
  string: a seed is not a key anything can be looked up by, so the string would
  have to be trusted rather than matched. And it is read off `socket.assigns.page`
  and not off a fresh query, because the shelf sorts on `updated_at` and a read
  at tap time can hand back an order the person never saw — *the tile they
  pressed* is a fact about the render.

  A row with no id — `Kati.Books.SampleFa`'s six, and a tag matching nothing —
  pushes with **no params at all** rather than with `%{book_id: nil}`, through
  the destination's own builder so the empty answer is spelled in one place.
  That is the fixture path every sweep in `test/` renders, and it is why screen
  69 keeps a no-id branch at all.

  The builder is `Kati.Screens.BookDetail.params_for/1` and not a Persian copy
  of it, for the reason `Kati.Screens.LogProgress.params_for/1` is shared by the
  English sheet and the Persian one: two spellings of `:book_id` is one more
  thing to keep true.
  """
  @spec open_book(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def open_book(socket, tag) do
    row = Enum.find(socket.assigns.page.books, &(Kati.Screens.Books.book_tag(&1) == tag))

    Mob.Socket.push_screen(
      socket,
      Kati.Screens.BookDetailFa,
      Kati.Screens.BookDetail.params_for(row)
    )
  end
end
