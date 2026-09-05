defmodule Kati.Screens.LogProgressFa do
  @moduledoc """
  Screen 72 — ثبت پیشرفت, the Persian reading-session sheet.

  Screen 70 in the mirror, and the caption names three things that move and one
  that must not.

  ## What moves

    * **The sheet's close disc goes to the leading edge**, which in Persian is
      the right. `Kati.UI.Sheet.header/1` puts the disc first in a `Row` and
      the root declares `rtl`, so start-to-end layout puts it there without a
      second arrangement — the same mechanism that puts the Persian dock's home
      tab on the right.
    * **The segment order reverses**, for the same reason and by the same
      mechanism.
    * **Every string is Vazirmatn.** Plus Jakarta Sans has no Arabic-script
      glyphs at all, so a Persian label without `font_family="fa"` is a row of
      empty boxes rather than a fallback.

  ## What does not

  **The timer face does not flip.** `۰۰:۳۸:۱۲` reads left to right in both
  languages, because the direction of time is not the direction of reading. A
  mirrored elapsed-time readout would put the hours where the seconds belong,
  which is the one thing on this sheet that would be actively wrong rather than
  merely unfamiliar.

  The stepper column also stays symmetrical, so the mono numeral still aligns
  under itself when the value grows a digit.

  ## The copy is a proposal

  The caption says so: *all Persian copy was open; these strings are
  proposals.* `Kati.Books.SampleFa.sheet/0` holds them in one place for exactly
  that reason — when a native reader corrects one, it is corrected once.

  ## `D-59`: the merge that made this sheet a fixture with a real title on it

  `sheet/1` was `Map.merge(SampleFa.sheet(), own(shelved))` over an `own/1` that
  named a title and a cover seed. `Map.merge/2` keeps every key the right-hand
  map does not name, so **every other line on the sheet stayed the drawing's**:
  a book typed on board 177 a minute ago, opened from screen 69's ثبت پیشرفت,
  drew `ص. ۲۱۴ از ۳۸۰` under its own title, a stepper proposing `۲۶۰`, a timer
  reading `۰۰:۳۸:۱۲`, a start time of `۲۱:۰۲` and a cream line calling it *۴۶
  صفحه در ۳۸ دقیقه — سریع‌ترین این هفته*. That is the literal shape screen 20's
  rule forbids — *either every value on the page is this reader's or every value
  is the drawing's* — and it is the same sentence `D-59` was written about, one
  screen on from the page it was written about.

  So there is no merge. `sheet/1` answers with the drawing whole, or with a map
  built key by key from the row, and the three bands that can only be true of a
  sitting somebody is actually timing — the running face, شروع در, and the
  insight line — are **absent** for a real book rather than inherited. Each
  carries its own leading `Spacer`, so what is left is a shorter sheet and not a
  sheet with holes in it, which is `Kati.Screens.BookDetailFa.hero/1`'s rule for
  the same problem one screen back.

  The stepper opens on the book's own `current_page` through
  `Kati.Screens.LogProgress.starting_page/1` — screen 70's reader, so the two
  sheets cannot open on two different numbers for one book. It was the literal
  `260`, which is the drawing's number after somebody stepped it up forty-six
  times.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Books.Book
  alias Kati.Books.SampleFa
  alias Kati.Calendar.Shamsi
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(params, _session, socket) do
    Kati.Theme.activate()

    # The id is kept and not only spent on `sheet/1`. It arrives —
    # `Kati.Screens.BookDetailFa` pushes `%{book_id: id}` — and the session this
    # sheet writes has to land on the book it drew, which is the whole of #84
    # and the reason `Kati.Screens.LogProgress.mount/3` keeps its own.
    # The id the sheet RESOLVES, not only the one it was named.
    #
    # Named nothing, `sheet(nil)` draws `Kati.Books.SampleFa` while `Save`
    # called `save_session(page, nil)` — and `current_book(nil)` is the head of
    # the shelf, so a session landed on a book this sheet never drew and
    # `move_position/2` walked that book's `current_page` to whatever the
    # stepper showed. Screen 70 does not have it: its `book/1` resolves the head
    # and carries the id, so drawing and writing are one row. Screen 73 was the
    # same defect and took the same fix.
    #
    # Reachable from `Kati.Screens.Gallery` on a device with books on the shelf:
    # screen 71 hands an id whenever it has one, so the bare mount is the
    # catalogue's.
    id = Map.get(params || %{}, :book_id) || shelf_head()

    {:ok,
     socket
     |> Mob.Socket.assign(:book_id, id)
     |> Mob.Socket.assign(:sheet, sheet(id))
     |> Mob.Socket.assign(:unit, :unit_page)
     |> Mob.Socket.assign(:save_error, nil)
     |> Mob.Socket.assign(:page, Kati.Screens.LogProgress.starting_page(id))}
  end

  @doc """
  The sheet this screen draws: the drawing's, or one named book's own.

  `nil` is `Kati.Books.SampleFa.sheet/0` and nothing else, because screen 72 is
  compared against its drawing through `Kati.Screens.Gallery`, which pushes it
  with no params. An id that names no row answers the same, which is
  `Kati.Screens.BookDetail.shelved_book/1`'s rule: a book deleted under you
  draws the drawing, never somebody else's.

  A named book answers `own/1`, which is a complete map and not an overlay —
  see the moduledoc for the merge this replaced and what it cost. The row is
  read as the `%Book{}` through `Kati.Screens.BookDetailFa.shelved/1`, the same
  reader screen 69 uses, so the page and the sheet it opens cannot land on
  different books; screen 66's `shelved_book/1` is not used because its answer
  is English sentences and this sheet cannot print them.
  """
  @spec sheet(String.t() | nil) :: map()
  def sheet(nil), do: SampleFa.sheet()

  def sheet(id) when is_binary(id) do
    case Kati.Screens.BookDetailFa.shelved(id) do
      nil -> SampleFa.sheet()
      %Book{} = row -> Kati.Screens.LogProgressFa.own(row)
    end
  end

  # The shelf's head as an id, or `nil` when nothing is shelved. Through screen
  # 69's own reader, so this sheet and the page that opens it cannot disagree
  # about which book that is.
  defp shelf_head do
    case Kati.Screens.BookDetailFa.shelved(nil) do
      %Book{id: id} -> id
      nil -> nil
    end
  end

  @doc """
  One shelved book as this sheet says it, key for key with the drawing.

  ## Every key the drawing has, so the two answers are one shape

  `sheet/1`'s two branches hand `render/1` maps with the same keys, and that is
  load-bearing rather than tidy: a key that goes missing is a `KeyError` in the
  suite, where a key that goes missing from a MERGE is the fixture's value on a
  device. `Kati.Screens.BookDetailFa.own/3` is total over its page's keys for
  the same reason and says so.

  ## What is the reader's, what is Kati's, and what is nobody's

  The **book's**: the title and the cover, untouched because they are the user's
  own; the position line; the page the stepper opens on. The **chrome**: ثبت
  پیشرفت, the three unit segments and their label, ذخیره و توقف — Persian words
  Kati wrote, none of which is a claim about a book.

  And three bands are **nobody's**, so they are `nil` and are not drawn: the
  running face `۰۰:۳۸:۱۲`, شروع در `۲۱:۰۲`, and *یعنی ۴۶ صفحه در ۳۸ دقیقه —
  سریع‌ترین این هفته*. Every one of them is a fact about a sitting somebody is
  in the middle of timing, and this sheet has no timer: `:stop_timer` is on
  `Kati.ScreenTapSweepTest`'s inert list and nothing in `lib/` starts a Persian
  one. Inherited from the fixture they told a reader who opened the sheet a
  second ago that they had been reading for thirty-eight minutes and that it was
  their fastest this week. Absent, they take their own `Spacer` with them —
  house rule 5, and `Kati.Screens.BookDetailFa.hero/1`'s own arrangement.

  The insight line is the one worth naming twice, because half of it *could* be
  computed: the delta between the stepper and the book's position is arithmetic.
  The other half is not — `در ۳۸ دقیقه` and `سریع‌ترین این هفته` need a timed
  session — and a cream card reading *یعنی ۴۶ صفحه* and stopping is a sentence
  no board draws. So the band waits for the timer rather than being half-built.

  ## The position line is board 72's own sentence with this book's numerals in it

  `ص. ۲۱۴ از ۳۸۰` is what the board draws, and `ص. `, the Persian digits and از
  are all its own literals — so substituting the row's numbers into it is the
  move `Kati.Screens.BookDetailFa.extent_label/1` and `own_note/1` already make
  from the same board's literals, not new copy. It is deliberately not
  `Kati.Screens.BooksFa.line/1`: that sentence has `/` where this board has از,
  and each is right where it is drawn.

  A book with no page count degrades to `ص. ۸۸` — the page you reached, with no
  denominator to name — which is `Kati.Screens.BooksFa.line/1`'s own last clause
  and screen 70's `AT p. 214` in the mirror. `current_page` is `allow_nil?:
  false` with a default of `0`, so a book typed by hand reads `ص. ۰`, exactly as
  screen 70 draws `AT p. 0` for it: the sheet's job is to say where you are
  before you change it.
  """
  @spec own(Book.t()) :: map()
  def own(%Book{} = row) do
    drawn = SampleFa.sheet()

    %{
      title: drawn.title,
      book: row.title,
      seed: row.cover_seed,
      position: position(row),
      page: page_label(row.current_page),
      unit_label: drawn.unit_label,
      units: drawn.units,
      timer: nil,
      stop: drawn.stop,
      started_label: drawn.started_label,
      started_at: nil,
      insight_lead: drawn.insight_lead,
      insight_pages: nil,
      insight_middle: drawn.insight_middle,
      insight_minutes: nil,
      insight_tail: nil,
      commit: drawn.commit
    }
  end

  # The stepper's own number is `assigns.page`, an integer the socket carries;
  # this is the drawing's `۲۶۰` key kept filled so the two branches of `sheet/1`
  # are one shape. Same digits, same guard as `position/1` below.
  defp page_label(page) when is_integer(page), do: Shamsi.fa(page)
  defp page_label(_none), do: nil

  # An audiobook has no page to be on. `Book.extent/1` answers `{minutes,
  # :minutes}` for one, which falls to the degrade below and prints `ص. ۰` —
  # *page 0* — under a stepper labelled اکنون در صفحه, on a book whose length
  # this app measures in hours. Screen 69 already refuses to say this: its
  # `length_row/2` draws nothing for an audiobook rather than putting a
  # duration under تعداد صفحه. `position_line/1` drops the node and its 5pt gap
  # for a nil, so the band takes its own gap with it — house rule 5. A Persian
  # sentence for *where you are in a recording* is copy no board writes, and
  # inventing one here is what rule 6 forbids; when a board words it, this is
  # the clause it replaces.
  defp position(%Book{format: :audiobook}), do: nil

  defp position(%Book{current_page: page} = row) when is_integer(page) do
    case Book.extent(row) do
      {total, :pages} -> "ص. " <> Shamsi.fa(page) <> " از " <> Shamsi.fa(total)
      _other -> "ص. " <> Shamsi.fa(page)
    end
  end

  # `current_page` is `allow_nil?: false` with a default of 0, so this answers
  # for a row that reached the store without going through the create action —
  # a seeded row, a restored backup mid-migration. `Kati.Calendar.Shamsi.fa/1`
  # takes an integer and nothing else, and a sheet that raised on one bad row
  # would take the activity down rather than lose one line of it.
  # `Kati.Screens.BooksFa.line/1` keeps the same clause for the same row.
  defp position(%Book{}), do: nil

  def render(assigns) do
    s = assigns.sheet

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction="rtl"
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} />
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={40} background={Palette.paper()} />
        <Column
          fill_width={true}
          background={Palette.paper()}
          corner_radius={26}
          padding_left={21}
          padding_right={21}
          padding_top={18}
          padding_bottom={34}
        >
          {Kati.Screens.LogProgressFa.header(s.title)}
          {Kati.Screens.LogProgressFa.book_row(s)}
          {Kati.Screens.LogProgressFa.segments(s.units, assigns.unit)}
          <Spacer size={16} />
          {Kati.Screens.LogProgressFa.stepper(s, assigns.page)}
          {Kati.Screens.LogProgressFa.timer(s)}
          {Kati.Screens.LogProgressFa.timing(s)}
          {Kati.Screens.LogProgressFa.insight(s)}
          {Kati.Screens.LogProgressFa.commit(s.commit)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The sheet header: close disc, centred title, and the hole that centres it.

  `Kati.UI.Sheet.header/1`'s arrangement with a Persian `Text` — the shared one
  builds its own and would draw boxes. See `Kati.Screens.Fa`'s moduledoc: a
  component that builds its own `Text` cannot draw Persian.
  """
  @spec header(String.t()) :: map()
  def header(title) do
    assigns = %{title: title}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.UI.Sheet.close_disc()}
        <Box weight={1.0}>
          {Kati.Screens.BookDetailFa.fa(@title, 15, :on_surface, weight: "bold", align: "center")}
        </Box>
        <Box width={36} height={36} />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The book this sheet is about: its cover, its title, and where you are in it.

  The cover seed is read off the sheet rather than defaulted. It was
  `Map.get(s, :seed, "bookaa1")` for as long as `Kati.Books.SampleFa.sheet/0`
  had no `:seed` of its own — and that default is exactly the shape `own/1`'s
  doc argues against: two branches answering with different key sets, one of
  them relying on a fallback to fill the gap. The fixture names its seed now,
  both branches are total over the same keys, and the default has nothing left
  to answer for.

  The position line takes its own 5pt gap with it when the book has no position
  to state — `Kati.Screens.BookDetailFa.title/1`'s rule for a book with no
  author, and the reason is house rule 3's: `own/1` can answer `nil` here, and a
  `nil` through `fa/4` is the word **nil** in 10.5pt under a Persian title.
  """
  @spec book_row(map()) :: map()
  def book_row(s) do
    assigns = %{
      s: s,
      cover: %{seed: s.seed},
      position: Kati.Screens.LogProgressFa.position_line(s.position)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.LogProgress.cover(@cover)}
        <Spacer size={13} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.fa(@s.book, 14.5, :on_surface, weight: "bold")}
          {@position}
        </Column>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def position_line(nil), do: []
  def position_line(""), do: []

  def position_line(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={5} />
      {Kati.Screens.BookDetailFa.fa(@text, 10.5, Palette.muted())}
    </Column>
    """
  end

  @doc """
  The three unit segments, in Persian.

  Hand-rolled rather than `Kati.UI.Segmented.plain/2` for the reason
  `Kati.Screens.BookDetailFa.chips/3` gives about chips: the shared control
  paints its own label, and a Persian label through that door is a row of
  boxes. Same geometry, own `Text`.
  """
  @spec segments([{String.t(), atom()}], atom()) :: map()
  def segments(units, selected) do
    segments =
      units
      |> Enum.map(fn {label, tag} ->
        Kati.Screens.LogProgressFa.segment(label, tag, tag == selected)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={4} />")

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.placeholder()}
      corner_radius={16}
      padding={4}
      align="center"
    >
      {segments}
    </Row>
    """
  end

  @doc false
  def segment(label, tag, true) do
    assigns = %{label: label, tap: {self(), tag}}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Row
        fill_width={true}
        height={34}
        corner_radius={12}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917"
        align="center"
      >
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@label, 12.5, :on_surface, weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  def segment(label, tag, false) do
    assigns = %{label: label, tap: {self(), tag}}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Row fill_width={true} height={34} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@label, 12.5, Palette.segment_idle(), weight: "semibold")}
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  Minus, the value, plus — and the column stays symmetrical.

  The caption asks for that by name: the two discs are the same size and sit at
  the same inset either side, so the mono numeral between them keeps its centre
  when it grows a digit. A stepper whose value drifted as it counted would be
  the one thing on the sheet that moved while you used it.
  """
  @spec stepper(map(), integer()) :: map()
  def stepper(s, page) do
    # The value is an integer here and a Persian numeral on the way out, so the
    # stepper counts in the language arithmetic is done in and prints in the
    # language the reader reads. `Kati.I18n.Digits.to_persian/1` is the one
    # conversion, and the fixture's `۲۶۰` is what it produces for 260.
    assigns = %{page: Kati.I18n.Digits.to_persian(page), label: s.unit_label}

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.LogProgress.step_disc("remove", :step_down)}
      <Spacer size={11} />
      <Column
        weight={1.0}
        height={64}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card()}
        align="center"
      >
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@page, 27, :on_surface, weight: "medium", align: "center")}
        <Spacer size={4} />
        {Kati.Screens.BookDetailFa.fa(@label, 9.5, Palette.muted(), align: "center")}
        <Spacer weight={1.0} />
      </Column>
      <Spacer size={11} />
      {Kati.Screens.LogProgress.step_disc("add", :step_up)}
    </Row>
    """
  end

  @doc """
  The running timer, and the one node on this screen that is not mirrored.

  `layout_direction="ltr"` on the face itself. `۰۰:۳۸:۱۲` is hours, minutes,
  seconds in that order in every language, and reversing it would put the hours
  where the seconds belong. The caption says so in as many words: *the timer
  face does not flip — elapsed time reads left-to-right in both languages,
  because direction of time is not direction of reading.*

  A sheet with no elapsed time draws no timer at all, and takes its 14pt gap
  with it. Nothing in `lib/` starts a Persian timer — `:stop_timer` is inert and
  `Kati.ScreenTapSweepTest` records it — so an elapsed face over a real book
  would be a running clock that never ran, and a توقف beside it would be a
  control that cannot act. See `own/1`.
  """
  @spec timer(map()) :: map() | []
  def timer(%{timer: nil}), do: []

  def timer(s) do
    assigns = %{elapsed: s.timer, stop: s.stop}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row
        fill_width={true}
        height={54}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card()}
        padding_left={16}
        padding_right={16}
        align="center"
      >
        <Box layout_direction="ltr">
          {Kati.Screens.BookDetailFa.fa(@elapsed, 19, :on_surface, weight: "medium")}
        </Box>
        <Spacer weight={1.0} />
        <Row
          height={32}
          corner_radius={16}
          background={Palette.ink_fill()}
          padding_left={14}
          padding_right={14}
          align="center"
          on_tap={{self(), :stop_timer}}
        >
          {Kati.Screens.BookDetailFa.fa(@stop, 12, Palette.on_ink(), weight: "bold")}
        </Row>
      </Row>
    </Column>
    """
  end

  @doc """
  شروع در — when this sitting started — or nothing at all.

  Absent for a book nobody is timing, on `timer/1`'s reason and with its own
  14pt gap: the two cards are one story, and a start time with no elapsed time
  beside it is a clock the app never started.
  """
  @spec timing(map()) :: map() | []
  def timing(%{started_at: nil}), do: []

  def timing(s) do
    assigns = %{label: s.started_label, at: s.started_at}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding_left={15}
        padding_right={15}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
          <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
            {UI.symbol("schedule", size: 17, color: Palette.ink_soft())}
          </Box>
          <Spacer size={13} />
          <Box weight={1.0}>
            {Kati.Screens.BookDetailFa.fa(@label, 13.5, :on_surface, weight: "semibold")}
          </Box>
          {Kati.Screens.BookDetailFa.fa(@at, 12.5, Palette.ink_soft())}
        </Row>
      </Column>
    </Column>
    """
  end

  @doc """
  The cream line, built from five Persian runs.

  Five `Text` nodes rather than `Kati.UI.rich_text/1`: that helper merges its
  runs into one node and drops the per-run font, which on a Persian screen
  means one of the five decides the face for all of them.

  The whole card is absent for a book nobody is timing, with its own 14pt gap —
  the cream marks a claim about what this entry MEANS, and three of its five
  runs are about minutes nobody counted. `own/1` argues it, including why the
  half that could be computed is not drawn on its own.
  """
  @spec insight(map()) :: map() | []
  def insight(%{insight_pages: nil}), do: []

  def insight(s) do
    assigns = %{s: s}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={15}>
        <Row fill_width={true} align="top">
          {UI.symbol("lightbulb", size: 18, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Row fill_width={true} align="center">
              {Kati.Screens.BookDetailFa.fa(@s.insight_lead, 13, Palette.cream_body())}
              <Spacer size={5} />
              {Kati.Screens.BookDetailFa.fa(@s.insight_pages, 13, Palette.cream_ink(), weight: "semibold")}
              <Spacer size={5} />
              {Kati.Screens.BookDetailFa.fa(@s.insight_middle, 13, Palette.cream_body())}
              <Spacer size={5} />
              {Kati.Screens.BookDetailFa.fa(@s.insight_minutes, 13, Palette.cream_ink(), weight: "semibold")}
              <Spacer weight={1.0} />
            </Row>
            <Spacer size={4} />
            {Kati.Screens.BookDetailFa.fa(@s.insight_tail, 13, Palette.cream_body(), lines: 2)}
          </Column>
        </Row>
      </Column>
    </Column>
    """
  end

  @doc """
  ذخیره و توقف, and the 14pt gap above it.

  The gap moved in here with `D-59`: the three bands between the stepper and
  this button are each absent for a real book, and four `Spacer`s left standing
  in a row would be a 56pt hole in the shape of the facts that used to be there.
  Every band on this sheet carries its own leading gap now, which is
  `Kati.Screens.BookDetailFa.hero/1`'s arrangement.
  """
  @spec commit(String.t()) :: map()
  def commit(label) do
    assigns = %{label: label}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :save}}
      >
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@label, 14.5, Palette.on_ink(), weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  # The Persian mirror of screen 70's Save, and the same write — not a second
  # one. `Kati.Screens.LogProgress.save_session/2` is public for the reason
  # `finish_book/1` beside it is: two copies of "what logging a session means"
  # would be two things to keep in step, and `Kati.Screens.BookDetailFa` already
  # hands `Kati.Screens.LogProgress.params_for/1` the same job for the push.
  #
  # This used to pop and write nothing, which is the failure `Kati.Write` exists
  # for, in its worst form: the sheet closed exactly as if the session had
  # landed, and on a fresh install the page behind redraws its fixture either
  # way, so a Persian reader's session vanished with nothing anywhere saying so.
  # The sheet now closes because the session is stored.
  #
  # The failure is kept and not drawn. `Kati.Write.message/1` answers in English
  # and this sheet is Vazirmatn throughout — a Persian error line is copy board
  # 72's caption calls a proposal, and it belongs in `Kati.Books.SampleFa`
  # beside the rest rather than being invented in a handler. What the failure
  # buys today is the half that matters most: the sheet stays open and the page
  # you stepped to is still there.
  def handle_info({:tap, :save}, socket) do
    case Kati.Screens.LogProgress.save_session(socket.assigns.page, socket.assigns.book_id) do
      {:ok, _session} ->
        {:noreply, socket |> Mob.Socket.assign(:save_error, nil) |> Mob.Socket.pop_screen()}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))}
    end
  end

  def handle_info({:tap, unit}, socket) when unit in [:unit_page, :unit_percent, :unit_minutes],
    do: {:noreply, Mob.Socket.assign(socket, :unit, unit)}

  def handle_info({:tap, :step_up}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :page, socket.assigns.page + 1)}

  def handle_info({:tap, :step_down}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :page, max(socket.assigns.page - 1, 0))}

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
