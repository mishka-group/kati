defmodule Kati.Screens.BookDetail do
  @moduledoc """
  Screen 66 — one book, pushed under Library.

  The screen a cover tap on screen 20 finally lands on. Screen 08 is a film and
  this is its shape reused rather than a second detail idiom: the same cream
  card for the user's own words, the same star row, the same one-ink-button
  action row. Where it diverges is where a book differs from a film — a
  **position that moves**, an **edition** you own a specific copy of, and a
  **history of sittings** that a film simply does not have.

  ## Three decisions the ticket left open, and which way each went

    * **Which action takes the ink.** `Log progress`. The ticket named the rule
      — exactly one ink button — and not the winner. Log progress is the only
      one of the four you press more than once per book, and the not-started
      state relabels it `Start reading` rather than promoting a different
      control, which is the same button doing the same job.
    * **Title and author appear twice** in the ticket's own bands — once in the
      large-title header, once in the hero stack. Resolved by giving them to the
      header alone; the hero stack carries status, the edition facts and the
      pace instead. So the hero is the only place that changes as you read.
    * **The community rating has no source.** Open Library carries none. The
      column is drawn, because a rating with nothing beside it reads as *your*
      rating being the only opinion that exists, and it prints an em dash. It is
      `nil` here rather than `0`, and `community/1` is the only thing that knows
      the difference.

  ## Where the data comes from

  `Kati.Books`, through `book/0`. Same shape as `Kati.Screens.Film`: the shelf's
  own order decides the referent, because nothing hands this screen an id — a
  poster tap on screen 20 pushes this module and no more, exactly as screen 43
  pushes `Kati.Screens.Meal`. So the book is the one the shelf puts first, and
  with nothing shelved `Kati.Books.Sample.detail/0` is drawn instead, which is
  the values `test/design/screens/66.html` was captured from.

  FIDELITY's rule, again: missing data is not a reason for a blank screen.

  ## What is read and what is frozen

  Everything on this screen is a row the user made, with two exceptions, and
  both are exceptions on the *fallback* only:

    * **The pace.** `23 MIN/DAY PACE` needs seven days of
      `Kati.Books.ReadingSession` and the fallback has none, so the sample
      states it. A real book computes it through
      `Kati.Books.ReadingSession.pace/1`, whose definition is screen 70's own
      caption and is not repeated here.
    * **The community rating**, for the reason above — and that one is frozen
      in both directions, because there is nothing to read.

  ## A chip that does not write now says so

  The seven status and edition chips are the only controls here that change the
  row, and they used to swallow the answer. `apply_change/1` ended `:ok`
  whatever `Ash.update/2` returned, the page re-read, and a chip that had
  written nothing was indistinguishable from one that had. On a fresh install
  it was worse than quiet: the shelf is empty, `book/0` falls through to
  `Kati.Books.Sample.detail/0`, and the re-read hands back the same sample
  either way — so the two outcomes were the same pixels.

  `Kati.Write` is the contract now. The write answers `{:ok, book}` or
  `{:error, reason}`, the tap either re-reads or reports, and the reason goes
  to the log on its way past.

  The report is drawn above the action row rather than beside the chip that
  failed. One line serves both writes this screen makes — the chips and
  `Finish` — and a second failure idiom in the chip band would be a second
  thing to keep true. `Finish` is the write with the worse failure anyway: it
  hands to screen 33, and handing over on a lost write asks someone to rate a
  book the shelf still has them halfway through.
  """

  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Books.Book
  alias Kati.Books.Note
  alias Kati.Books.ReadingSession
  alias Kati.Books.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.Write

  # The three secondary actions, in the drawing's order. `Log progress` is not
  # here: it is the ink button and is drawn by `actions/1` itself, so the list
  # cannot accidentally grow a second primary.
  @secondary [
    {"check", "Finish", :finish},
    {"star", "Rate & review", :rate},
    {"bookmarks", "Add to list", :add_to_list}
  ]

  # `:save_error` opens as `nil` so the notice has a value to be absent as, and
  # so a re-mount never inherits the last failure a previous visit reported.
  def load(socket) do
    socket
    |> Mob.Socket.assign(:book, book())
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  The book this screen is about: the shelf's first, or the drawing's.

  Public because `Kati.ScreenEmptyDatabaseTest` asks a screen what it would
  show, and because the dark twin (screen 68) is this screen under a different
  theme rather than a second reader.
  """
  @spec book() :: map()
  def book, do: shelved_book() || Sample.detail()

  @doc "The drawing's values, unconditionally. The fixture, not a fallback path."
  @spec drawn_book() :: map()
  def drawn_book, do: Sample.detail()

  @doc """
  The newest shelved book, shaped for the render, or `nil` when nothing is
  shelved.

  Three reads and never one per band — the book, its sessions and its notes —
  for the same reason `Kati.Screens.Film` takes three: a band is not a query.
  """
  @spec shelved_book() :: map() | nil
  def shelved_book, do: shelved_book(nil)

  @doc """
  One shelved book by id, shaped for the render — the shelf's first when no id
  is named.

  Both arities exist because two different questions are asked of this reader.
  Screen 66 opened from nowhere in particular still has to draw *something*, and
  the shelf's first is the standing answer to that; a sheet pushed **off a row**
  is asking about that row and nothing else, and #84 is the whole class of
  defect where the second question was answered with the first.

  An id that names no row answers `nil` rather than falling back to the head of
  the shelf. A row that has been deleted under you is not the same fact as an
  empty shelf, and quietly substituting a different book would be the very
  swap this reader now exists to prevent — the caller draws its sample instead.
  """
  @spec shelved_book(String.t() | nil) :: map() | nil
  def shelved_book(id) do
    case row(id) do
      nil ->
        nil

      %Book{} = book ->
        shaped(book, sessions_of(book), notes_of(book))
    end
  end

  defp row(nil), do: newest()

  defp row(id) when is_binary(id) do
    case Ash.get(Book, id) do
      {:ok, %Book{} = book} -> book
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp newest do
    case Ash.read(Book, action: :shelf) do
      {:ok, [book | _rest]} -> book
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp sessions_of(%Book{id: id}) do
    ReadingSession
    |> Ash.Query.for_read(:for_book, %{book_id: id})
    |> Ash.read()
    |> case do
      {:ok, sessions} -> sessions
      _other -> []
    end
  rescue
    _error -> []
  end

  defp notes_of(%Book{id: id}) do
    Note
    |> Ash.Query.for_read(:for_book, %{book_id: id})
    |> Ash.read()
    |> case do
      {:ok, notes} -> notes
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc """
  One book plus its sessions and notes, as the render wants them.

  Public and pure, so the shaping can be tested without a database — the same
  arrangement `Kati.Screens.Film.shaped/3` uses, and for the same reason.
  """
  @spec shaped(Book.t(), [ReadingSession.t()], [Note.t()]) :: map()
  def shaped(%Book{} = book, sessions, notes) do
    %{
      # The row's own id, carried so a control on this page can name the book it
      # is about rather than leaving the screen it pushes to guess. `Log
      # progress` is the one that needs it; `Kati.Books.Sample.detail/0` has no
      # id and is not given a `nil` one, so `book[:id]` is the read and the
      # sample answers `nil` by absence.
      id: book.id,
      title: book.title,
      author: book.author,
      seed: book.cover_seed,
      status: book.status,
      status_label: status_label(book.status),
      meta: meta_line(book),
      progress: Book.fraction(book),
      progress_line: progress_line(book, sessions),
      rating: book.rating,
      rating_label: rating_label(book.rating),
      community: nil,
      format: book.format,
      extent_label: extent_label(book),
      isbn: book.isbn,
      owned: book.owned,
      warning_count: 0,
      series_line: Book.series_line(book),
      series_next: nil,
      lent_to: lent_line(book),
      lent_due: due_line(book),
      notes: Enum.map(notes, &shape_note/1),
      sessions: Enum.map(sessions, &shape_session/1)
    }
  end

  defp shape_note(%Note{} = note),
    do: %{kind: note.kind, body: note.body, anchor: Note.anchor(note)}

  defp shape_session(%ReadingSession{read_on: on} = session) do
    %{
      date: String.upcase(Calendar.strftime(on, "%-d %b")),
      span: ReadingSession.span_line(session),
      duration: ReadingSession.duration_line(session)
    }
  end

  # The four the status control offers, plus the fifth nothing moves *to*.
  defp status_label(:not_started), do: "Not started"

  defp status_label(status) do
    {_value, label} = Enum.find(Sample.statuses(), {status, "Reading"}, &(elem(&1, 0) == status))
    label
  end

  # `2024 · FABER · 380 PP`, degrading a part at a time rather than all at once.
  # A book with a publisher and no year prints the publisher, which is the same
  # rule `Kati.Screens.Film.meta_line/1` follows for runtime and genre.
  defp meta_line(%Book{} = book) do
    [
      book.published_year && Integer.to_string(book.published_year),
      book.publisher && String.upcase(book.publisher),
      extent_meta(book)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp extent_meta(%Book{} = book) do
    case Book.extent(book) do
      {pages, :pages} -> "#{pages} PP"
      {minutes, :minutes} -> "#{div(minutes, 60)}H #{rem(minutes, 60)}M"
      nil -> nil
    end
  end

  # `380 pages` or `11h 20m` — the unit restated, which is band 5's whole point.
  defp extent_label(%Book{} = book) do
    case Book.extent(book) do
      {pages, :pages} -> "#{pages} pages"
      {minutes, :minutes} -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
      nil -> nil
    end
  end

  # `p. 214 / 380 · 23 MIN/DAY PACE`, and each half may be absent. Screen 67's
  # partial-metadata state is the first half with no denominator; a book nobody
  # has timed is the first half with no second.
  defp progress_line(%Book{} = book, sessions) do
    position =
      case Book.extent(book) do
        {total, :pages} -> "p. #{book.current_page} / #{total}"
        _other -> "p. #{book.current_page} · NO PAGE COUNT"
      end

    case ReadingSession.pace(sessions, Kati.Time.today()) do
      nil -> position
      pace -> position <> " · #{pace} MIN/DAY PACE"
    end
  end

  # Ten-point scale, printed as the halves it is: `9` is `4.5`. Trailing `.0`
  # dropped, because the drawing writes `4.5` and would write `4`.
  defp rating_label(nil), do: nil

  defp rating_label(rating) when is_integer(rating) do
    case rem(rating, 2) do
      0 -> Integer.to_string(div(rating, 2))
      _odd -> "#{div(rating, 2)}.5"
    end
  end

  defp lent_line(%Book{lent_to: name}) when is_binary(name) and name != "", do: "Lent to #{name}"
  defp lent_line(%Book{owned: true}), do: "Owned"
  defp lent_line(%Book{}), do: nil

  defp due_line(%Book{lent_due_on: %Date{} = due}),
    do: "Due " <> Calendar.strftime(due, "%-d %b")

  defp due_line(%Book{}), do: nil

  @doc false
  def content(assigns) do
    b = assigns.book
    # Read through `Access` rather than the dot: this screen's own mount always
    # sets it, and a caller that builds assigns by hand to draw one band should
    # not have to know about a key it is not asking for.
    save_error = assigns[:save_error]

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(b.title, b.author, nil, :name)}
        {Kati.Screens.BookDetail.hero(b)}
        {Kati.Screens.BookDetail.ratings(b)}
        {UI.eyebrow("Status")}
        {Kati.Screens.BookDetail.statuses(b)}
        {UI.eyebrow("Edition")}
        {Kati.Screens.BookDetail.edition(b)}
        {UI.eyebrow("Content warnings")}
        {Kati.Screens.BookDetail.warnings(b)}
        {Kati.Screens.BookDetail.notes_section(b)}
        {Kati.Screens.BookDetail.series_section(b)}
        {Kati.Screens.BookDetail.history_section(b)}
        {Kati.Screens.BookDetail.save_notice(save_error)}
        {Kati.Screens.BookDetail.actions(b)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The hero card: cover beside status, edition facts, bar and pace.

  The bar is the one place orange appears on this screen, which is the ticket's
  own constraint and the reason the status pill is green rather than accent.
  """
  @spec hero(map()) :: map()
  def hero(b) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true}>
          {Kati.Screens.BookDetail.cover(b)}
          <Spacer size={15} />
          <Column weight={1.0}>
            {Kati.Screens.BookDetail.status_pill(b.status, b.status_label)}
            <Spacer size={11} />
            <Text
              text={b.meta}
              font_family="mono"
              text_size={11}
              text_color={Palette.muted()}
              max_lines={1}
            />
            {Kati.Screens.BookDetail.bar(b.progress)}
            <Spacer size={9} />
            <Text
              text={b.progress_line}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  # A 86x112 tile with a 2pt card-coloured ring, which is the drawing's own
  # `border: 2px solid #FBFAF8` — the ring is card, not paper, so it reads as a
  # lifted edge against the card it sits on rather than a gap cut out of it.
  @doc false
  def cover(b) do
    case Kati.Design.Images.poster(b.seed) do
      nil ->
        ~MOB"""
        <Box width={86} height={112} corner_radius={6} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Box
          width={86}
          height={112}
          corner_radius={8}
          background={Palette.card()}
          padding={2}
          shadow={Kati.Theme.shadow_button()}
        >
          <Image src={src} fill_width={true} fill_height={true} content_mode="fill" corner_radius={6} />
        </Box>
        """
    end
  end

  @doc """
  The status lozenge: a 5pt dot and a label, on a wash of its own colour.

  Green for reading and finished, bronze for paused, tertiary for the two that
  stopped. Not the accent — orange belongs to the progress bar on this screen,
  and two oranges is the one thing the palette's own rule forbids.
  """
  @spec status_pill(atom(), String.t()) :: map()
  def status_pill(status, label) do
    {dot, text, wash} = status_colours(status)

    ~MOB"""
    <Row
      height={24}
      corner_radius={12}
      background={wash}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Box width={5} height={5} corner_radius={3} background={dot} />
      <Spacer size={6} />
      <Text text={label} text_size={11} font_weight="bold" text_color={text} max_lines={1} />
    </Row>
    """
  end

  defp status_colours(:reading), do: {Palette.green(), Palette.green_text(), Palette.green_wash()}

  defp status_colours(:finished),
    do: {Palette.green(), Palette.green_text(), Palette.green_wash()}

  defp status_colours(:paused),
    do: {Palette.bronze(), Palette.gold_text(), Palette.cream()}

  defp status_colours(_stopped),
    do: {Palette.tertiary(), Palette.sub(), Palette.track()}

  @doc """
  The 2pt progress bar, or nothing at all.

  `nil` — no page count — draws no bar, because a bar pinned at zero claims you
  have read none of it, which is exactly what screen 67's partial-metadata
  state exists to avoid saying. See `Kati.Books.Book.fraction/1`.
  """
  @spec bar(float() | nil) :: map() | []
  def bar(nil), do: []

  def bar(fraction) do
    rail =
      Kati.Components.MishkaProgress.progress(
        render: :box,
        value: fraction,
        max: 1,
        height: 2,
        corner_radius: 1,
        color: Palette.accent(),
        track_color: Palette.track_off()
      )

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      {rail}
    </Column>
    """
  end

  @doc """
  Two rating columns and no third.

  Screen 14 draws three — yours, community, critics — and the ticket cut
  critics because no source exists for it. Community survives the same
  reasoning only because `—` beside a label is a different statement from an
  absent column: it says nobody has told us, where an absent column would say
  your opinion is the only one there is.
  """
  @spec ratings(map()) :: map()
  def ratings(b) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.BookDetail.rating_card("Yours", b.rating, b.rating_label)}
        </Column>
        <Spacer size={10} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetail.rating_card("Community", b.community, nil)}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def rating_card(label, rating, value) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow={Kati.Theme.shadow_card()}
    >
      <Text
        text={String.upcase(label)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_color={Palette.muted()}
      />
      <Spacer size={9} />
      <Row fill_width={true} align="center">
        {Kati.Screens.BookDetail.stars(rating)}
        <Spacer size={9} />
        <Text
          text={value || "—"}
          font_family="mono"
          text_size={13}
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  Five glyphs, `filled` of them solid.

  Whole stars from a ten-point scale, exactly as `Kati.Screens.Film.star_count/1`
  does it — `9` draws four, because rounding it to five would claim half a star
  nobody gave, and the `4.5` beside the row is where the half is said.
  """
  @spec stars(integer() | nil) :: map()
  def stars(rating) do
    filled = if is_integer(rating), do: div(rating, 2), else: 0

    ~MOB"""
    <Row align="center">
      {1..5 |> Enum.map(fn i -> Kati.Screens.BookDetail.star(i <= filled) end) |> Enum.intersperse(~MOB"<Box width={2} height={1} />")}
    </Row>
    """
  end

  @doc false
  def star(true), do: UI.symbol("star", size: 22, color: Palette.accent(), fill: true)
  def star(false), do: UI.symbol("star", size: 22, color: Palette.star_empty())

  @doc """
  The four status choices, as first-class taps.

  Never a swipe, which the ticket says by name: a status is the thing you come
  to this screen to change, and a gesture with no affordance is not a control.
  """
  @spec statuses(map()) :: map()
  def statuses(b) do
    chips =
      Sample.statuses()
      |> Enum.map(fn {value, label} ->
        UI.chip(label,
          selected: value == b.status,
          on_toggle: String.to_atom("status_#{value}")
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {chips}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Format chips, then the two facts that follow from the format, then the toggle.

  The length row restates its unit — `380 pages` against `11h 20m` — and that
  restatement is the band's reason for existing: an edition switched from
  paperback to audiobook whose number did not change its unit would be a page
  count presented as a duration.
  """
  @spec edition(map()) :: map()
  def edition(b) do
    chips =
      Sample.formats()
      |> Enum.map(fn {value, label} ->
        UI.chip(label,
          selected: value == b.format,
          on_toggle: String.to_atom("format_#{value}")
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {chips}
      </Row>
      <Spacer size={12} />
      {SettingsList.card([
        {SettingsList.body("Length", nil), SettingsList.trailing(Kati.Screens.BookDetail.value(b.extent_label))},
        {SettingsList.body("ISBN", nil), SettingsList.trailing(Kati.Screens.BookDetail.mono(b.isbn))}
      ] |> Enum.map(fn {body, trailing} -> SettingsList.row(nil, body, trailing) end))}
      <Spacer size={12} />
      {Kati.Screens.BookDetail.owned_row(b.owned)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def value(nil) do
    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol("add", size: 17, color: Kati.Theme.Palette.muted())}
      <Spacer size={6} />
      <Text text="Add page count" text_size={13} text_color={Kati.Theme.Palette.muted()} />
    </Row>
    """
  end

  def value(text) do
    ~MOB"""
    <Text text={text} text_size={13.5} text_color={Kati.Theme.Palette.sub()} max_lines={1} />
    """
  end

  @doc false
  def mono(nil), do: Kati.Screens.BookDetail.value(nil)

  def mono(text) do
    ~MOB"""
    <Text
      text={text}
      font_family="mono"
      text_size={12}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc false
  def owned_row(owned?) do
    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("inventory_2"),
        SettingsList.body("This is the edition I own", nil),
        SettingsList.trailing(SettingsList.switch(owned?))
      )
    ])
  end

  @doc """
  The warnings block, closed.

  Closed by default and closed on arrival is the ticket's own instruction, and
  it is not a default that wants overriding: the point of a content warning is
  that you can choose to look at it, which a block that opens itself takes away.
  """
  @spec warnings(map()) :: map()
  def warnings(b) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          nil,
          SettingsList.body("Warnings", nil),
          SettingsList.trailing(Kati.Screens.BookDetail.warning_trailing(b.warning_count))
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def warning_trailing(0) do
    ~MOB"""
    <Row align="center">
      <Text text="None recorded" text_size={11.5} text_color={Kati.Theme.Palette.muted()} />
      <Spacer size={8} />
      {Kati.UI.symbol("add", size: 18, color: Kati.Theme.Palette.muted())}
    </Row>
    """
  end

  def warning_trailing(count) do
    ~MOB"""
    <Row align="center">
      <Text
        text={Integer.to_string(count)}
        font_family="mono"
        text_size={12.5}
        text_color={Kati.Theme.Palette.sub()}
      />
      <Spacer size={8} />
      {Kati.UI.symbol("expand_more", size: 20, color: Kati.Theme.Palette.tertiary())}
    </Row>
    """
  end

  @doc """
  The cream card, or nothing at all.

  Same rule as `Kati.Screens.Film.note/1`: cream marks the user's own words,
  so a book nobody has written about has no warm rectangle waiting for one.
  """
  @spec notes_section(map()) :: map() | []
  def notes_section(b) do
    case Map.get(b, :notes, Sample.notes()) do
      [] ->
        []

      notes ->
        rows =
          notes
          |> Enum.map(&Kati.Screens.BookDetail.note_row/1)
          |> Enum.intersperse(~MOB"<Spacer size={14} />")

        ~MOB"""
        <Column fill_width={true}>
          {Kati.UI.eyebrow("Your notes and quotes")}
          <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
            {rows}
          </Column>
          <Spacer size={24} />
        </Column>
        """
    end
  end

  @doc false
  def note_row(note) do
    body = if note.kind == :quote, do: "“" <> note.body <> "”", else: note.body

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={body}
        text_size={14}
        line_height={1.45}
        text_color={Kati.Theme.Palette.cream_body()}
      />
      <Spacer size={6} />
      <Text
        text={note.anchor || ""}
        font_family="mono"
        text_size={10.5}
        text_color={Kati.Theme.Palette.cream_meta()}
      />
    </Column>
    """
  end

  @doc """
  Series and ownership: two list rows that push, or as few of them as are true.

  A book in no series and lent to nobody takes the whole band with it rather
  than drawing two empty rows — the same reasoning as the cream card. There is
  nothing to say, so nothing says it.
  """
  @spec series_section(map()) :: map() | []
  def series_section(b) do
    rows =
      [
        b.series_line && series_row(b),
        b.lent_to && lending_row(b)
      ]
      |> Enum.reject(&is_nil/1)

    case rows do
      [] ->
        []

      rows ->
        ~MOB"""
        <Column fill_width={true}>
          {Kati.UI.eyebrow("Series and ownership")}
          {Kati.UI.SettingsList.card(rows)}
          <Spacer size={24} />
        </Column>
        """
    end
  end

  defp series_row(b) do
    SettingsList.row(
      SettingsList.icon_tile("menu_book"),
      SettingsList.body(b.series_line, b.series_next),
      SettingsList.trailing(SettingsList.chevron()),
      on_tap: {self(), :open_series}
    )
  end

  defp lending_row(b) do
    SettingsList.row(
      SettingsList.icon_tile("inventory_2"),
      SettingsList.body(b.lent_to, b.lent_due),
      SettingsList.trailing(SettingsList.chevron()),
      on_tap: {self(), :open_lending}
    )
  end

  @doc """
  The history band, in screen 15's activity-row idiom.

  Empty is a real state and it is drawn as nothing: a book you have not logged
  a sitting for has no history, and a band captioned "Reading history" over a
  blank card would be a promise the app has not kept.
  """
  @spec history_section(map()) :: map() | []
  def history_section(b) do
    case Map.get(b, :sessions, Sample.sessions()) do
      [] ->
        []

      sessions ->
        ~MOB"""
        <Column fill_width={true}>
          {Kati.UI.eyebrow("Reading history")}
          {Kati.UI.SettingsList.card(Enum.map(sessions, &Kati.Screens.BookDetail.session_row/1))}
          <Spacer size={24} />
        </Column>
        """
    end
  end

  @doc false
  def session_row(session) do
    SettingsList.row(
      nil,
      ~MOB"""
      <Row fill_width={true} align="center">
        <Text
          text={session.date}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.12}
          text_color={Kati.Theme.Palette.muted()}
          width={58}
        />
        <Text text={session.span} font_family="mono" text_size={12.5} text_color={:on_surface} />
      </Row>
      """,
      SettingsList.trailing(Kati.Screens.BookDetail.duration(session.duration))
    )
  end

  @doc false
  def duration(nil), do: nil

  def duration(text) do
    ~MOB"""
    <Text text={text} font_family="mono" text_size={12} text_color={Kati.Theme.Palette.muted()} />
    """
  end

  @doc """
  One ink button and three circular seconds — screen 08's action row exactly.

  The ink button relabels rather than moves: a book you have not started says
  `Start reading` in the same place `Log progress` sits, because it is the same
  control at a different point in the same job.
  """
  @spec actions(map()) :: map()
  def actions(b) do
    primary = if b.status == :not_started, do: "Start reading", else: "Log progress"

    seconds =
      @secondary
      |> Enum.map(fn {icon, label, tag} -> Kati.Screens.BookDetail.second(icon, label, tag) end)
      |> Enum.intersperse(~MOB"<Spacer size={10} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :log_progress}}
      >
        <Spacer weight={1.0} />
        <Text
          text={primary}
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={Palette.on_ink()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true}>
        {seconds}
      </Row>
    </Column>
    """
  end

  @doc false
  def second(icon, label, tag) do
    ~MOB"""
    <Column weight={1.0} align="center" on_tap={{self(), tag}}>
      <Box
        width={44}
        height={44}
        corner_radius={22}
        background={Kati.Theme.Palette.card()}
        align="center"
        shadow={Kati.Theme.shadow_button()}
      >
        {Kati.UI.symbol(icon, size: 20)}
      </Box>
      <Spacer size={7} />
      <Text
        text={label}
        text_size={11.5}
        font_weight="semibold"
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  What a write that did not land says, in red, above the action row.

  Red type on the page's own paper rather than a card: every other block on
  this screen is a standing fact about the book, and a failure is not one — it
  happened once, to the tap just made, and borrowing the cream card would give
  it the same permanence as the edition facts.

  It carries its own trailing `Spacer`, so a page with nothing to report is
  spaced to the pixel it was before.
  """
  @spec save_notice(String.t() | nil) :: map() | []
  def save_notice(nil), do: []

  def save_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@message}
        text_size={12.5}
        font_weight="semibold"
        line_height={1.35}
        text_color={Palette.red()}
      />
      <Spacer size={12} />
    </Column>
    """
  end

  # The sheet is pushed with the id of the book this page is drawing, not with
  # nothing. Screen 70 used to re-read the shelf and take its first row, so a
  # page opened on the third book logged a session against the first — #84. The
  # sample has no id, and a sheet handed none still falls back to the drawing,
  # which is what the empty-database sweep renders.
  @doc false
  def handle_tap(:log_progress, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.LogProgress,
         Kati.Screens.LogProgress.params_for(socket.assigns.book)
       )}

  def handle_tap(:rate, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}

  def handle_tap(:add_to_list, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  # `Finish` is a write, not a navigation: it sets the book finished and then
  # hands to screen 33, which is the same handover screen 70's `Finished the
  # book` makes. Two controls, one consequence, and the consequence lives in
  # `Kati.Screens.LogProgress` so neither can drift from the other.
  #
  # The push waits on the write for the same reason screen 70's `Finished the
  # book` does: screen 33 asks you to rate a book you just finished, and
  # arriving there off a write that failed would ask you to rate one the shelf
  # still has you halfway through.
  # It finishes the book this page is drawing, for the reason `:log_progress`
  # above names one: `finish_book/1` defaults to the shelf's head, so a page
  # opened on the third book marked the first as finished and then handed the
  # reader to screen 33 to rate it. The two controls on this row now name the
  # same book, which is the book on the page.
  #
  # `book[:id]` and not `book.id`: `Kati.Books.Sample.detail/0` has no id and is
  # not given a `nil` one, so the sample answers `nil` by absence — the same
  # read `shaped/3` documents at the top of this file.
  def handle_tap(:finish, socket) do
    case Kati.Screens.LogProgress.finish_book(socket.assigns.book[:id]) do
      {:ok, _book} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Mob.Socket.push_screen(Kati.Screens.Rating)}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  # Everything that is not a chip: the series row and the lending row. Answered
  # rather than left dead, because a dead tap is a defect
  # `Kati.Screens.Root.rescue_tap/3` reports by name and this is not one — both
  # controls are drawn, both are reachable, and what each would push is a screen
  # the design has not drawn. `Kati.ScreenTapSweepTest` carries them on
  # `@inert_taps` with that reason written out.
  #
  # The status and edition chips write, and then re-read: the page's whole hero
  # band is derived from the row — the bar, the pace line, the extent, the meta
  # — so assigning the chip alone would leave five other things on the page
  # disagreeing with it.
  def handle_tap(tag, socket) do
    case Kati.Screens.BookDetail.chip_change(tag) do
      nil ->
        {:noreply, socket}

      change ->
        case Kati.Screens.BookDetail.apply_change(change) do
          {:ok, _book} ->
            {:noreply,
             socket
             |> Mob.Socket.assign(:book, Kati.Screens.BookDetail.book())
             |> Mob.Socket.assign(:save_error, nil)}

          # No re-read on failure: the row did not move, so re-reading would
          # redraw the same page under a message saying nothing was written —
          # and on an empty shelf it would redraw the sample, which is the
          # picture that hid this in the first place.
          {:error, _reason} = error ->
            {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
        end
    end
  end

  @doc """
  The attribute a chip tag sets, or `nil` for a tag that is not a chip.

  Split out so the two families share one parser and a third cannot be added
  without going through it.
  """
  @spec chip_change(atom()) :: {atom(), atom()} | nil
  def chip_change(tag) do
    statuses = Enum.map(Kati.Books.Sample.statuses(), &elem(&1, 0))
    formats = Enum.map(Kati.Books.Sample.formats(), &elem(&1, 0))

    cond do
      value = Enum.find(statuses, &(String.to_atom("status_#{&1}") == tag)) -> {:status, value}
      value = Enum.find(formats, &(String.to_atom("format_#{&1}") == tag)) -> {:format, value}
      true -> nil
    end
  end

  @doc """
  Set one attribute on the shelved book, and answer for it.

  Answers `{:ok, book}` or `{:error, reason}`, never a bare `:ok` —
  `Kati.Write`'s contract, and the whole of what was wrong here: the old body
  discarded `Ash.update/2`'s answer, returned `:ok` regardless, and left the
  caller no way to tell a chip that wrote from one that did not.

  An empty shelf is `{:error, :nothing_to_save}` rather than a silent no-op.
  The chips are drawn against `Kati.Books.Sample.detail/0` when nothing is
  shelved, so they are tappable with no row behind them — and "Nothing to save
  yet." is the true answer to that tap, where doing nothing quietly reads as a
  change the page then fails to show.

  No `rescue`. `Ash.update/2` returns `{:error, changeset}`; it does not raise,
  which is why the rescue that used to sit here caught almost nothing while
  looking like the failure was handled.
  """
  @spec apply_change({atom(), atom()}) :: {:ok, term()} | {:error, term()}
  def apply_change({attribute, value}) do
    case newest() do
      %Book{} = book ->
        book
        |> Ash.update(%{attribute => value})
        |> Write.note("book #{attribute}")

      nil ->
        Write.note({:error, :nothing_to_save}, "book #{attribute}")
    end
  end
end
