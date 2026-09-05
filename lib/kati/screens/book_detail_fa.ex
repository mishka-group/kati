defmodule Kati.Screens.BookDetailFa do
  @moduledoc """
  Screen 69 — کتاب, the Persian book detail, pushed under کتابخانه.

  Screen 66's page in the mirror. What changes is not only the words.

  ## Four things the caption pins, and each is a real RTL trap

    * **The back chevron is `arrow_forward_ios`.** Back is the way the reader
      came from, and in Persian that is the right edge. A mirrored screen that
      keeps the left-pointing chevron is the commonest RTL bug there is, and
      `Kati.Screens.SeriesFa` records the same thing for screen 58.
    * **The progress bar fills from the right.** `Row` lays out start-to-end
      and the root declares `rtl`, so the fill lands at the right edge for
      free — but only because the rail is a Row rather than an absolutely
      positioned Box. It is the same `Kati.Components.MishkaProgress` call
      screen 66 makes, with 66's own `nil` clause beside it: a book with no
      denominator draws no bar at all — see `bar/1`.
    * **Cover artwork and stars hold their direction.** A photograph does not
      mirror, and a five-star row read right to left would put the filled
      stars on the wrong end of the scale. Both are drawn in the order screen
      66 draws them.
    * **Page figures and the ISBN stay in DM Mono with Persian digits so the
      columns still align.** `kati_mono.ttf` carries no Persian digits, which
      is why `Kati.Screens.Fa`'s own rule applies here too: anything numeric
      the design sets in mono is set in `fa` at the design's size and colour.
      The face is wrong and the glyphs are right, which is the better half of
      an unwinnable trade.

  ## The parent is 57, and it was inferred rather than drawn

  The caption says so: *parent inferred as 57 کتابخانه, the only RTL shelf
  drawn.* There is no Persian Books shelf in the 127, so the back pill names
  the shelf that exists.

  ## The transliteration rule

  `Kati.Books.SampleFa` holds it: the fixture's title and author are Persian
  because the fixture is Persian, and **the user's own note text is never
  touched**. Nothing in `Kati.Books` translates anything, and this screen reads
  the same rows screen 66 does when a book is shelved.

  ## `D-59`: the page that was half the reader's and half the drawing's

  Until 5 September no Persian book could exist. `D-38` shipped board 177, a
  title was typed on a Pixel 9a with nothing else — status *not started* — and
  screen 69 opened on it drawing the title correctly and then **در حال خواندن**
  in the pill, the reading chip lit, `۱۴۰۳ · ۳۸۰ صفحه` under it, a bar past
  half, `ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز`, ۴٫۵ stars, three content warnings, a
  series, a borrower, two notes in the cream card and three sittings that never
  happened. One fact on that page was the reader's.

  The mechanism was `Map.merge(SampleFa.detail(), own(shelved))` over an `own/1`
  that named five keys: **every key it did not name silently kept the fixture's
  value**, and that is the literal shape the app's own doctrine forbids — screen
  20's rule, written into `Kati.ScreenEmptyDatabaseTest`: *either every value on
  the page is this reader's or every value is the drawing's.* So the merge is
  gone. `book/0` answers with one book or with the drawing and never with half
  of each, `own/3` is total over every key the page reads, and a key that goes
  missing is a `KeyError` in the suite rather than somebody else's reading on a
  device.

  ## Why this screen reads the shelf itself rather than through screen 66

  66's `Kati.Screens.BookDetail.shaped/3` is a shaping into **English
  sentences** — `p. 214 / 380`, `Lent to Jo`, `p. 168 → 214`, `38m`, `Due 5
  Sep` — and a Persian sentence cannot be recovered from an English one. So
  what this screen needs is not 66's answer but 66's *question*, and it asks it
  the same way: `Kati.Books.Book`'s own `:shelf` action for a page nobody named
  a book to, `Ash.get/2` for a page that was named one, then that row's sessions
  and notes — three reads and never one per band, which is 66's own rule. The
  words are each page's own.

  ## The page is about the book the cover you pressed carries

  It was not, and that was the sharper half of `D-59`. `mount/3` matched
  `_params` and answered with the head of the shelf, while board 176's tiles
  carry the row's own id in their tag — `Kati.Screens.Books.book_tag/1` — and
  threw it away on the way here. With one book on the shelf the two are the same
  row and every screenshot ever taken of this page agreed; with two, tapping the
  second jacket opened a complete record of the FIRST book. Before this ticket
  that leaked one string, the title, over a fixture. After it, `own/3` is total
  over twenty-two keys, so the same tap drew the head's status, position,
  rating, ISBN, series, borrower, notes and sittings under the wrong title — and
  تمام شد then wrote against that book. `D-59`'s acceptance is the sentence it
  broke: *a hand-typed title opens a page that is empty where the app knows
  nothing, never a page filled in with somebody else's reading.*

  So `mount/3` reads `:book_id` and `book/1` resolves it, on
  `Kati.Screens.BookDetail.shelved_book/1`'s three-way rule: **no id is the
  shelf's head**, which is what a page opened from nowhere in particular is
  about; **an id that names no row is the drawing**, because a book deleted
  under you is not the same fact as an empty shelf and substituting a different
  one is the swap this whole reader exists to prevent; and an id that names a
  row is that row. `Kati.Screens.BooksFa.open_book/2` is the caller's half, and
  the two halves shipped together — either alone is a page that still cannot
  answer which book it is about.

  Everything a shaper already exists for goes through that shaper rather than
  being written twice: `Kati.Screens.BooksFa.line/1` writes the position line,
  so board 176's grid and board 69's hero cannot disagree about one book — the
  drift `Kati.Screens.Books.rail/2` was extracted to end, and the one
  `Kati.Books.SampleFa`'s moduledoc names outright.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Books.Book
  alias Kati.Books.Note
  alias Kati.Books.ReadingSession
  alias Kati.Books.SampleFa
  alias Kati.Calendar.Shamsi
  alias Kati.Screens.Fa
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # U+066B ARABIC DECIMAL SEPARATOR, not the ASCII dot: `۴٫۵` and never `۴.۵`.
  # `Kati.Screens.AlbumDetailFa` and `Kati.Screens.HealthFa` each keep their own
  # for the same reason — it is one character of typography, and a shared
  # constant would be a module three screens depend on to print one glyph.
  @decimal "٫"

  # `:book_id` is assigned as well as spent, and the difference between the two
  # is a write to the wrong row — `Kati.Screens.BookDetail.load/1` argues it in
  # full and this is the same argument in the mirror. `book/1` collapses two
  # facts into one value: *nobody named a book* and *the book they named is
  # gone* both answer `Kati.Books.SampleFa.detail/0`, which has no id. A write
  # that recovered its target from `assigns.book[:id]` alone would read `nil`
  # for both, and `nil` to `apply_change/2` and `finish_book/1` means *the
  # shelf's newest* — a page drawing the fixture would then finish, pause or own
  # a real book the reader is not looking at. Keeping the NAMED id is what lets
  # `target/1` refuse.
  def mount(params, _session, socket) do
    Kati.Theme.activate()

    named = Map.get(params || %{}, :book_id)

    {:ok,
     socket
     |> Mob.Socket.assign(:book_id, named)
     |> Mob.Socket.assign(:book, book(named))}
  end

  @doc """
  The book a write on this page must act on: the id the push NAMED, or the id of
  the book that was resolved.

  `Kati.Screens.BookDetail.target/1` one language over, and for its reason. The
  resolved id is the shelf's newest for a page nobody told which book to open,
  which is the right target for that page. `nil` is the drawing — nobody named a
  book and nothing is shelved, or the named row is gone — and `nil` is the one
  answer no writer may be handed, because `Kati.Screens.LogProgress.finish_book/1`
  and `Kati.Screens.BookDetail.apply_change/2` both read it as *the shelf's
  newest*. The callers below check for it rather than passing it on.

  `Map.get/2` on both keys: `Kati.SheetRowIdentityTest` builds this page's
  assigns by hand to pin one band, and a screen that raised on the assign it was
  not given would be a test-only failure standing in for nothing.
  """
  @spec target(map()) :: String.t() | nil
  def target(assigns) do
    Map.get(assigns, :book_id) || Map.get(assigns, :book, %{})[:id]
  end

  @doc """
  The book this screen is about with nothing naming one: the shelf's, worded in
  Persian, or the drawing.

  The no-id answer, and the one `Kati.ScreenEmptyDatabaseTest` renders through
  `fallbacks/0`. See `book/1` for why an id is the answer whenever there is one.
  """
  @spec book() :: map()
  def book, do: book(nil)

  @doc """
  The book this screen was handed, or — given no id — the shelf's.

  `Kati.Screens.SeriesFa`'s doctrine, applied to a book: *one book, read once,
  presented twice.* What this screen supplies is the Persian half — the status
  word, the position line, the row labels, the eyebrows. What it does **not**
  supply is a translation: a shelved book keeps its own title, its own author
  and its own notes, because those are the user's and nothing in `Kati.Books`
  translates anything.

  ## One book or the drawing, and never half of each

  This used to be `Map.merge(SampleFa.detail(), own(shelved))` and that merge
  was `D-59`'s second finding in one line: `Map.merge/2` keeps every key the
  right-hand map does not name, so a book typed ten seconds ago was answered
  with the fixture's progress, the fixture's rating, the fixture's series, the
  fixture's borrower and the fixture's marginalia. The two branches now answer
  with two complete maps, which is the shape screen 20's rule asks for and the
  reason one whole-page pair in `Kati.ScreenEmptyDatabaseTest` is still the
  correct gate for this screen.

  With nothing shelved — or with an id that names no row — the whole page is
  `Kati.Books.SampleFa`, which is the fixture the frame was captured from, and
  where the title and author ARE Persian because a Persian fixture's book is a
  Persian book.

  ## An id that names no row is the drawing and never the head of the shelf

  `Kati.Screens.BookDetail.shelved_book/1`'s rule, and the reason is the same
  one: a row deleted under you is not the same fact as an empty shelf, and
  quietly substituting a different book is the very swap this reader exists to
  prevent. The two are told apart by `target/1` and not here — the page draws
  one thing for both, and only the writers need the difference.
  """
  @spec book(String.t() | nil) :: map()
  def book(id) do
    case Kati.Screens.BookDetailFa.shelved(id) do
      nil -> SampleFa.detail()
      %Book{} = row -> Kati.Screens.BookDetailFa.own(row, sessions_of(row), notes_of(row))
    end
  end

  @doc """
  One book by id as the row itself, the shelf's head when no id is named, or
  `nil`.

  One reader, two questions, which is `Kati.Screens.BookDetail.shelved_book/1`'s
  own split: a page opened from nowhere in particular still has to draw
  *something*, and the shelf's head — `Kati.Books.Book`'s own `:shelf` action,
  most recently touched first — is the standing answer to that; a page opened
  **off a cover** is asking about that cover's row and nothing else. `D-59`
  found this page answering the second question with the first, and the
  moduledoc says what it cost.

  It answers with the `%Book{}` rather than with a shaping of it, and that is
  the whole difference between this reader and screen 66's: 66's `shaped/3`
  answers in English sentences and a Persian page cannot print them.
  `Kati.Screens.LogProgressFa` reads through here too, so the Persian page and
  the Persian sheet cannot land on different books.

  An id that names no row answers `nil` rather than falling back to the head,
  and the caller draws its fixture for it: a row deleted under you is not the
  same fact as an empty shelf.

  A screen that cannot reach its store answers `nil` and draws the drawing
  rather than taking the activity down, which is `Kati.Screens.BooksFa.shelved/0`'s
  degrade and `Kati.Screens.BookDetail`'s own. That degrade is why `target/1`
  exists in the shape it does: on the day this rescue fires with a full shelf,
  the page draws the fixture, and nothing on it may be written to.
  """
  @spec shelved(String.t() | nil) :: Book.t() | nil
  def shelved(nil) do
    case Ash.read(Book, action: :shelf) do
      {:ok, [%Book{} = book | _rest]} -> book
      _other -> nil
    end
  rescue
    _error -> nil
  end

  def shelved(id) when is_binary(id) do
    case Ash.get(Book, id) do
      {:ok, %Book{} = book} -> book
      _other -> nil
    end
  rescue
    _error -> nil
  end

  # This book's sittings, newest first, and its notes in page order — the two
  # `:for_book` reads screen 66 makes, for the bands that draw them and for the
  # pace the hero line carries. `[]` on any failure: a band that could not be
  # read is a band with nothing in it, and this page has a rule for that.
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

  @doc "The drawing's values, unconditionally."
  @spec drawn_book() :: map()
  def drawn_book, do: SampleFa.detail()

  @doc """
  One shelved book, its sittings and its notes, as this page says them in Persian.

  ## What is the reader's and what is Kati's, restated because it was wrong

  This function's doc used to open *deliberately short: a title, an author, a
  cover and an ISBN — everything else on the page is Kati's copy*, and `D-59`
  quotes that sentence as the defect. It was a fair reading when it was written,
  because no Persian book could exist and the page was only ever its own
  drawing. It is not a fair reading now. **Every fact here is the book's**; what
  stays Kati's is the Persian *words* — the eyebrows, the row labels, the chip
  vocabulary, the noun after a numeral — none of which is a claim about a book.

  Every string is built by a shaper this repo already had, or is a numeral, or
  is a numeral followed by a noun board 69 already draws beside one. No new
  sentence is introduced: `Kati.Screens.BooksFa.line/1` writes the position,
  `Kati.Books.SampleFa.statuses/0` gives the status words, board 69's own
  literals give صفحه, قرض داده به, موعد and the pace's دقیقه در روز.

  ## What a hand-typed title alone produces, key by key

  Because that is the state the defect was found in, and reading it here is
  faster than re-deriving it: status `:not_started`, so the pill reads **شروع
  نشده** in the quiet grey wash and none of the four status chips lights — 66
  lights none either, and `Kati.Books.Book`'s moduledoc says why (*the four the
  control offers are the four you can move to*). `meta` is `""` and the line is
  not drawn. `progress` is `nil`, so there is no bar — a bar pinned at zero
  claims you have read none of it. `progress_line` is `""` and no line is drawn
  under the pill either: the pill has just said شروع نشده, and see
  `position_line/2` for why it does not say it twice. Five empty stars and an em
  dash. No page count and no ISBN — both rows draw their label and no value, and
  they draw the SAME nothing, which is the point of `isbn: row.isbn` here rather
  than an em dash of its own. The ownership switch off. No warnings band, no
  series band, no cream card, no history — each takes its own eyebrow with it,
  which is `Kati.Screens.BookDetail.series_section/1`'s rule: *there is nothing
  to say, so nothing says it.*

  ## The id

  It is not drawn anywhere. It is what lets ثبت پیشرفت name the book it is about
  instead of leaving screen 72 to take the head of the shelf, and what lets تمام
  شد and the status chips write to the row this page drew rather than to the
  head — see `target/1`. `Kati.Screens.BookDetail.shaped/3` carries it for the
  same reasons. `Kati.Books.SampleFa.detail/0` has no id and is not given a
  `nil` one, so the fixture answers `nil` by absence and `book[:id]` is the read.
  """
  @spec own(Book.t(), [ReadingSession.t()], [Note.t()]) :: map()
  def own(%Book{} = row, sessions, notes) do
    %{
      id: row.id,
      title: row.title,
      author: row.author,
      seed: row.cover_seed,
      status: row.status,
      status_label: status_label(row.status),
      meta: meta(row),
      progress: Book.fraction(row),
      progress_line: position_line(row, ReadingSession.pace(sessions, Kati.Time.today())),
      rating: row.rating,
      rating_label: rating_label(row.rating),
      format: row.format,
      extent_label: extent_label(row),
      # `row.isbn` and never `row.isbn || "—"`. The em dash made the ISBN row
      # answer *no value* one way while the تعداد صفحه row above it answered the
      # same absence another — a `Text` with a dash in it over a row with no
      # trailing cell at all — and a book typed on 177 has neither, so the two
      # were adjacent. `Kati.Screens.BookDetail.shaped/3` carries `book.isbn`
      # for the same reason; `row/5`'s `if value` closes both rows the same way.
      isbn: row.isbn,
      owned: row.owned,
      # Nothing in the app stores a content warning — the resource does not
      # exist — so `Kati.Screens.BookDetail.shaped/3` answers 0 and so does
      # this, and the band is absent rather than captioned over a zero.
      warning_count: 0,
      series_line: series_line(row),
      # `بعدی: آب کم` is the drawing's, and it is a fact about a series Kati has
      # no resource for: nothing in `lib/` knows what the next book is. `nil`
      # rather than a guess, and `row/5` draws a title with no sub for it.
      series_next: nil,
      lent_to: lent_line(row),
      lent_due: due_line(row),
      notes: Enum.map(notes, &Kati.Screens.BookDetailFa.own_note/1),
      sessions: Enum.map(sessions, &Kati.Screens.BookDetailFa.own_session/1)
    }
  end

  @doc """
  One note as the cream card prints it: the body untouched, the anchor rebuilt.

  **The body is never touched** — that is this file's transliteration rule and
  the one thing on the page that is a person's own words. The anchor is not
  translated either; it is *rebuilt*, from the page number, because
  `Kati.Books.Note.anchor/1` answers `p. 148` and a Persian page cannot print
  that. `ص. ۱۴۸` is board 69's own anchor line, and `ص. ` with Persian digits is
  the same construction `Kati.Screens.BooksFa.line/1` makes for the shelf.

  A note about a book rather than about a page has no anchor at all —
  `Kati.Books.Note`'s moduledoc calls that ordinary — and `nil` travels to
  `note_row/1`, which draws no anchor line for it.
  """
  @spec own_note(Note.t()) :: map()
  def own_note(%Note{} = note),
    do: %{kind: note.kind, body: note.body, anchor: note_anchor(note.page)}

  defp note_anchor(page) when is_integer(page) and page > 0, do: "ص. " <> Shamsi.fa(page)
  defp note_anchor(_none), do: nil

  @doc """
  One sitting as the تاریخچه خواندن band prints it.

  The three strings board 69 draws — `۲۵ مرداد`, `ص. ۱۶۸ → ۲۱۴`, `۳۸ دقیقه` —
  built from the row's own numbers rather than re-worded out of
  `Kati.Books.ReadingSession.span_line/1`'s `p. 168 → 214`, for the reason the
  moduledoc gives: an English sentence cannot be turned back into a Persian one.
  The date is a real conversion and correctly so — a `%Date{}` has a Shamsi
  counterpart where a bare year does not — through
  `Kati.Calendar.Shamsi.format/2`, which is what `Kati.Screens.SeriesFa` and
  `Kati.Screens.SettingsFa` already use for a short Persian date. The duration
  is `Shamsi.fa(m) <> " دقیقه"`, which is `Kati.Screens.SeriesFa`'s runtime line
  exactly.

  `minutes` is `nil` for a sitting nobody timed — the resource's own rule, *a
  session with no minutes is a session that happened* — and that `nil` reaches
  `session_row/1`, which then draws no trailing cell. It is the row a person
  creates the first time they log progress from screen 72 without the timer.
  """
  @spec own_session(ReadingSession.t()) :: map()
  def own_session(%ReadingSession{} = session) do
    %{
      date: Shamsi.format(session.read_on, :short),
      span: "ص. " <> Shamsi.fa(session.from_page) <> " → " <> Shamsi.fa(session.to_page),
      duration: minutes_label(session.minutes)
    }
  end

  defp minutes_label(m) when is_integer(m) and m > 0, do: Shamsi.fa(m) <> " دقیقه"
  defp minutes_label(_none), do: nil

  @doc """
  The Persian word for one status, as the pill and board 176's hero say it.

  66's `status_label/1` clause for clause: the four the control offers come off
  `Kati.Books.SampleFa.statuses/0` — the same list the chips draw, so the pill
  and the chip row cannot say two different words for one status — and the
  fifth, which nothing moves *to*, is named on its own. شروع نشده is not new
  copy: it is `Kati.Screens.BooksFa.line/1`'s word and
  `Kati.Books.SampleFa.chips/0`'s, whose doc settles the register in as many
  words — *the same word 156 uses, one register, in both places*.

  Public because `Kati.Screens.BooksFa.hero/1` says the same thing about the
  same book one screen back, and used to say it by reading
  `Kati.Books.SampleFa.detail/0.status_label` — the constant در حال خواندن, over
  whatever row the card had picked. A shelf of hand-typed books was captioned
  *reading* while this page called the same book شروع نشده, which is 176's @doc
  ("so the card and screen 69 cannot come to call the state two different
  things") failing on the ordinary case. One function, so they cannot.

  The fallback is the fixture's own در حال خواندن, which is what a row that
  reached the shelf carrying a status this list has never heard of would draw
  rather than raising under one jacket.
  """
  @spec status_label(atom()) :: String.t()
  def status_label(:not_started), do: "شروع نشده"

  def status_label(status) do
    {_value, label} =
      Enum.find(SampleFa.statuses(), {status, "در حال خواندن"}, &(elem(&1, 0) == status))

    label
  end

  # `۲۰۲۴ · ۳۸۰ صفحه`, degrading a part at a time rather than all at once —
  # `Kati.Screens.SeriesFa.meta_line/1`'s shape, and 66's `meta_line/1` minus
  # the publisher.
  #
  # The publisher is dropped rather than forgotten: nothing in `lib/` writes
  # one — screen 177 is the only thing that creates a `Kati.Books.Book` and has
  # no publisher field — so a real book's is `nil` on every device that exists,
  # and board 69's meta line has two parts where 66's has three. It also avoids
  # `String.upcase/1`, which is an English typographic move with no meaning in a
  # script that has no case. If `publisher` ever gets a writer this takes a board
  # decision rather than inheriting 66's upcasing.
  #
  # The year is the **Gregorian** one with Persian digits and is never converted
  # — `Kati.Books.SampleFa`'s moduledoc argues it in full, and it is the one
  # place the drawing (۱۴۰۳) and a real book (۲۰۲۴) deliberately disagree.
  #
  # An empty list joins to `""` and never to `nil`: house rule 3, and the same
  # degrade `Kati.Screens.SeriesFa` makes. `meta_line/1` — the renderer, further
  # down — then draws nothing at all for it rather than an empty line and its
  # 11pt gap.
  defp meta(%Book{} = row) do
    [row.published_year && Shamsi.fa(row.published_year), extent_label(row)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  # `۳۸۰ صفحه` or `۱۱ ساعت ۲۰ دقیقه` — the unit restated, which is band 5's
  # whole point and `Kati.Books.Book.extent/1`'s.
  #
  # صفحه is board 69's own noun, twice over (`۱۴۰۳ · ۳۸۰ صفحه` and the تعداد
  # صفحه row's `۳۸۰ صفحه`). ساعت is drawn on board 76 (`۴ آلبوم · ۶۱ ساعت`) and
  # دقیقه by `Kati.Screens.SeriesFa` and by board 72. The hours-and-minutes
  # split mirrors 66's `11h 20m` rather than screen 177's minutes field, because
  # two pages disagreeing about how long one audiobook is is worse than an
  # unfamiliar unit.
  defp extent_label(%Book{} = row) do
    case Book.extent(row) do
      {pages, :pages} ->
        Shamsi.fa(pages) <> " صفحه"

      {minutes, :minutes} ->
        Shamsi.fa(div(minutes, 60)) <> " ساعت " <> Shamsi.fa(rem(minutes, 60)) <> " دقیقه"

      nil ->
        nil
    end
  end

  # The hero's line under the cover: a POSITION and a pace, each dropped when
  # the book has neither — `meta/1`'s degrade, one card up, and `""` for a book
  # that has nothing to say here, which `pace_line/1` draws as nothing at all.
  #
  # The status half of the shelf's sentence is dropped here, and that is the
  # only place these two screens deliberately part.
  #
  # `Kati.Screens.BooksFa.line/1` still writes the position, so board 176's grid
  # caption and board 69's hero cannot disagree about one book — the drift
  # `Kati.Screens.Books.rail/2` exists to have ended and the one
  # `Kati.Books.SampleFa`'s moduledoc names (*two literals of ص. ۲۱۴ / ۳۸۰ is
  # two places for the shelf and the detail page to disagree about one book*).
  # But `line/1` answers with the STATUS WORD for the two statuses that have one
  # — تمام‌شده and شروع نشده — because a jacket in a grid has no pill and the
  # word is the only thing saying it there. **This card has a pill**, nine points
  # above, and `D-59` found the consequence: a hand-typed book drew شروع نشده in
  # the lozenge and شروع نشده again directly under it, and a finished book drew
  # تمام شد in the lozenge and تمام‌شده under it — one fact twice, in two
  # spellings, on one card, because `Kati.Books.SampleFa.statuses/0` and
  # `line/1` word *finished* differently and each is right where it is drawn.
  #
  # So `position/1` answers the position half only, and house rule 5 does the
  # rest: the pill already says it, so nothing else needs to. It is the same
  # split board 66 makes with different words — 66 draws `p. 0 / 380` beside a
  # `Not started` pill — and the board draws `ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز`
  # here and never a status word.
  #
  # The pace half is board 69's own — `۲۳ دقیقه در روز`, lifted whole from
  # `Kati.Books.SampleFa.detail/0`'s `progress_line` — and is appended only when
  # a sitting in the last seven days recorded minutes, which is
  # `Kati.Books.ReadingSession.pace/2`'s `nil`: a pace of zero and *nobody timed
  # anything* are different claims. It survives a dropped position on purpose: a
  # book finished this morning was read for twenty-three minutes a day, and that
  # is a fact about the reader rather than a second spelling of the pill.
  defp position_line(%Book{} = row, pace) do
    [position(row), pace_part(pace)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp position(%Book{status: status}) when status in [:finished, :not_started], do: nil
  defp position(%Book{} = row), do: Kati.Screens.BooksFa.line(row)

  defp pace_part(pace) when is_integer(pace), do: Shamsi.fa(pace) <> " دقیقه در روز"
  defp pace_part(_none), do: nil

  # `9` is `۴٫۵`, on the ten-point scale `Kati.Books.Book` stores and screen 66
  # prints as halves. The arithmetic is 66's `rating_label/1`, restated here
  # rather than shared because that function is private and this stream does not
  # own its file; the Persian half is `Kati.Screens.AlbumDetailFa`'s
  # `persian_decimal/1` one page over, which folds `4.5` to `۴٫۵` for exactly
  # this reason — *it goes on being right for an album the frame never saw*.
  #
  # `nil` passes through, so `rating_card/3`'s `value || "—"` draws the em dash
  # and `Kati.Screens.BookDetail.stars/1` draws five empty glyphs for a book
  # nobody has rated. The board's own `4.5` is Latin and stays Latin: it is a
  # frozen literal of the drawing, and house rule 10 governs the numerals a real
  # row produces.
  defp rating_label(nil), do: nil

  defp rating_label(rating) when is_integer(rating) do
    case rem(rating, 2) do
      0 -> Shamsi.fa(div(rating, 2))
      _odd -> Shamsi.fa(div(rating, 2)) <> @decimal <> Shamsi.fa(5)
    end
  end

  # `#۳ از ۷ — دفترهای ساحلی`, which is board 69's own line with the numerals
  # and the name substituted — `Kati.Books.Book.series_line/1`'s three clauses,
  # in the shape the Persian board draws rather than the English `#3 of 7 in`.
  # The `#` is Latin because the board's is.
  defp series_line(%Book{series_name: name, series_position: at, series_total: of})
       when is_binary(name) and is_integer(at) and is_integer(of),
       do: "#" <> Shamsi.fa(at) <> " از " <> Shamsi.fa(of) <> " — " <> name

  defp series_line(%Book{series_name: name, series_position: at})
       when is_binary(name) and is_integer(at),
       do: "#" <> Shamsi.fa(at) <> " — " <> name

  defp series_line(%Book{}), do: nil

  # `قرض داده به جو` — board 69's words, with the borrower's name printed as it
  # was typed, because nothing in `Kati.Books` translates anything.
  #
  # A book you own and have not lent draws **nothing**, where 66 draws a
  # standalone `Owned` row. Two reasons, and neither is an omission: Persian for
  # that row exists on no board, and rule 6 forbids inventing it — borrowing
  # 66's English word is the failure this file already records for
  # `Kati.Write.message/1` further down. And the ownership fact is already drawn
  # on this board, as the نسخه‌ای که دارم switch in the نسخه band, which now
  # reads `owned` instead of asserting `true`.
  defp lent_line(%Book{lent_to: name}) when is_binary(name) and name != "",
    do: "قرض داده به " <> name

  defp lent_line(%Book{}), do: nil

  # `موعد ۵ شهریور`, board 69's literal. This one IS a Shamsi conversion and
  # correctly so: `lent_due_on` is a `%Date{}`, and a date has a Shamsi
  # counterpart where a bare publication year does not.
  defp due_line(%Book{lent_due_on: %Date{} = due}), do: "موعد " <> Shamsi.format(due, :short)
  defp due_line(%Book{}), do: nil

  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc """
  The page, in the order board 69 stacks it.

  ## Two eyebrows are drawn here and four are not, and the asymmetry is the point

  وضعیت and نسخه caption **controls** — a chip row and a switch — which draw
  whatever the book says and are never empty, so their captions are
  unconditional. The other four caption **data**, and a caption over nothing is
  `D-58`'s defect: this function used to print all six as siblings, so a band
  that answered `[]` would have left its eyebrow standing over the hole. Each of
  those four now prints its own eyebrow as the first child of markup it only
  builds when it has something to build it from — which is exactly how screen 66
  splits the same six (`Kati.Screens.BookDetail.notes_section/1`,
  `series_section/1` and `history_section/1` each own their caption; Status and
  Edition are drawn by `content/1`).
  """
  @spec content(map()) :: map()
  def content(assigns) do
    b = assigns.book
    e = SampleFa.eyebrows()

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.BookDetailFa.chrome()}
        {Kati.Screens.BookDetailFa.title(b)}
        {Kati.Screens.BookDetailFa.hero(b)}
        {Kati.Screens.BookDetailFa.ratings(b)}
        {Fa.eyebrow(e.status)}
        {Kati.Screens.BookDetailFa.chips(SampleFa.statuses(), b.status, "status")}
        {Fa.eyebrow(e.edition)}
        {Kati.Screens.BookDetailFa.edition(b)}
        {Kati.Screens.BookDetailFa.warnings(b)}
        {Kati.Screens.BookDetailFa.notes(b)}
        {Kati.Screens.BookDetailFa.series(b)}
        {Kati.Screens.BookDetailFa.history(b)}
        {Kati.Screens.BookDetailFa.actions()}
      </Column>
    </Scroll>
    """
  end

  @doc "The back pill, with the chevron pointing the way the reader came from."
  @spec chrome() :: map()
  def chrome do
    assigns = %{label: SampleFa.labels().back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={{self(), :back}}
        >
          {UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          {Kati.Screens.BookDetailFa.fa(@label, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  A Persian `Text`, in Vazirmatn.

  Every string on this screen goes through here. Plus Jakarta Sans carries no
  Arabic-script glyphs at all, so a Persian label without `font_family="fa"` is
  a row of empty boxes rather than a fallback — `Kati.Screens.Fa`'s moduledoc
  checked the font and says so.

  ## `align` defaults to nothing, and defaulted to `"start"` for a long time

  `text_align` is not a free prop. `MobText` reads a present one as *this text
  is wider than its glyphs* and applies `fillMaxWidth()` — which is right for a
  centred title and catastrophic for a `Text` sitting in a `Row` next to
  anything else, because it takes the whole row and every weighted sibling
  measures zero. With `"start"` as the default, **every** Persian string in the
  app carried it, so every Persian row was one unlucky layout away from losing
  a column.

  Two did, and both only on a device: screen 127's service rows drew a badge, a
  price and a per-hour rate with **no service name**, and its one-off expense
  rows drew an amount and nothing else. In a `Column` the two behaviours are
  indistinguishable — a filled `Text` with `text_align="start"` and a hugging
  one both put their glyphs at the container's start edge — which is why this
  survived every screen sweep and every literal check: the strings were in the
  tree, at the right size, in the right colour, measured to nothing.

  So the default is `nil` and the prop is written only when a caller asks for
  it. Twelve callers do, and each of them wants what `text_align` means:
  `"center"` for a code or a stat, `"absolute_left"`/`"absolute_right"` for the
  handful of things the design says must not mirror.
  """
  @spec fa(String.t(), number(), term(), keyword()) :: map()
  def fa(text, size, colour, opts \\ []) do
    assigns = %{
      text: text,
      size: size,
      colour: colour,
      weight: Keyword.get(opts, :weight, "normal"),
      lines: Keyword.get(opts, :lines, 1),
      align: Keyword.get(opts, :align)
    }

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={@size}
      font_weight={@weight}
      text_align={@align}
      text_color={@colour}
      max_lines={@lines}
      line_height={1.4}
    />
    """
  end

  @doc """
  The 25pt title and the 12.5pt line under it, or the title alone.

  A book with no author draws no author line and takes its 5pt gap with it,
  which is `Kati.UI.SettingsList.subtitle/2`'s own rule one language over: a
  page with nothing to say under its title says nothing. Screen 177 asks for a
  title and nothing else, so *no author* is the ordinary state of a book typed
  by hand rather than an edge — and the alternative is the word **nil** in
  12.5pt muted under a Persian title, which is the defect
  `Kati.ScreenNilTextTest` was written after a device found on screen 66.

  `""` takes the same clause as `nil`. `Kati.Screens.AlbumDetailFa` and
  `Kati.Screens.YearShareFa` borrow this helper and both pass a line they
  always have, so their trees are unchanged.
  """
  @spec title(map()) :: map()
  def title(b) do
    assigns = %{title: b.title, byline: byline(b.author)}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(@title, 25, :on_surface, weight: "bold", lines: 2)}
      {@byline}
      <Spacer size={20} />
    </Column>
    """
  end

  defp byline(author) when is_binary(author) and author != "" do
    assigns = %{author: author}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={5} />
      {Kati.Screens.BookDetailFa.fa(@author, 12.5, Palette.muted())}
    </Column>
    """
  end

  defp byline(_none), do: []

  @doc """
  The hero card: cover, status pill, the mono facts and the rail.

  Each of the three things under the pill takes its own leading gap with it —
  `meta_line/1`, `bar/1` and `pace_line/1` carry the `Spacer` that used to sit
  above them here — so a card with nothing but a pill on it has no run of empty
  space where three facts used to be. For a title typed ten seconds ago that is
  the whole card: a cover placeholder, **شروع نشده** in the grey wash, and
  nothing else, because that is the whole of what the app knows about it.
  """
  @spec hero(map()) :: map()
  def hero(b) do
    assigns = %{b: b}

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
          {Kati.Screens.BookDetail.cover(@b)}
          <Spacer size={15} />
          <Column weight={1.0}>
            {Kati.Screens.BookDetailFa.status_pill(@b.status, @b.status_label)}
            {Kati.Screens.BookDetailFa.meta_line(@b.meta)}
            {Kati.Screens.BookDetailFa.bar(@b.progress)}
            {Kati.Screens.BookDetailFa.pace_line(@b.progress_line)}
          </Column>
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The 2pt progress bar, or nothing at all.

  `Kati.Screens.BookDetail.bar/1` one language over, `nil` clause included and
  for its reason: **a bar pinned at zero claims you have read none of it**,
  which is what screen 67's partial-metadata state exists to avoid saying. The
  component does not refuse a `nil` — `Kati.Components.MishkaProgress` falls to
  `fraction || 0.0` and draws an empty track — so the `nil` has to be caught
  here or the page draws a claim instead of raising.

  This is deliberately **not** `Kati.Screens.Books.rail/2`, whose `nil -> 0.0`
  is right for the shelf and wrong here: a jacket in a grid keeps a rail under
  every cover as a constant of the drawing, and screen 176 says so. A hero has
  no such constant and has a line of text beside the bar carrying the honest
  version. Screens 20 and 66 split the same way, so 176 and 69 must.
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
  `۲۰۲۴ · ۳۸۰ صفحه` under the pill, or nothing when the book carries neither.

  `""` and `nil` take the same clause. A book with no year and no page count has
  no meta line to draw, and an empty `Text` would still hold its 11pt line and
  the 11pt gap above it — a hole in the shape of a fact.
  """
  @spec meta_line(String.t() | nil) :: map() | []
  def meta_line(nil), do: []
  def meta_line(""), do: []

  def meta_line(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={11} />
      {Kati.Screens.BookDetailFa.fa(@text, 11, Palette.muted())}
    </Column>
    """
  end

  @doc """
  The position line under the rail — `ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز`.

  `""` is a real answer and not a defensive clause: `position_line/2` joins two
  parts a book may hold neither of, so a title typed with nothing else answers
  the empty string here — and an empty `Text` would still hold its 10.5pt line
  and the 9pt gap above it, a hole in the shape of a fact. `meta_line/1` above
  takes the same pair of clauses for the same reason.

  The `nil` clause should never fire, and is here so that a future shaping which
  forgets a key cannot put the string `nil` under a cover, which is the one
  failure mode house rule 3 exists for.
  """
  @spec pace_line(String.t() | nil) :: map() | []
  def pace_line(nil), do: []
  def pace_line(""), do: []

  def pace_line(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={9} />
      {Kati.Screens.BookDetailFa.fa(@text, 10.5, Palette.muted())}
    </Column>
    """
  end

  @doc """
  The status lozenge: a 5pt dot and a label, on a wash of its own colour.

  ## Why this takes the status and not just the word

  It used to hard-code the green wash and the green dot, because green was the
  only state a fixture could be in — and `D-59` found the consequence on a
  device: a book typed as *not started* wore the live-reading pill. The colour
  is a fact about the status and so it follows the status.

  Green for reading and finished, bronze for paused, tertiary for the two that
  stopped — `:did_not_finish` **and** `:not_started`, so a book nobody has
  opened wears the quiet grey pill. Not the accent: orange belongs to the
  progress bar on this screen, and two oranges is the one thing the palette's
  own rule forbids. That reasoning is screen 66's, in
  `Kati.Screens.BookDetail.status_pill/2`'s own doc, and these four clauses are
  a mirror of its private `status_colours/1` rather than a call to it —
  `Kati.Screens.BookDetail` is not this stream's file to widen. Four copied
  clauses is four chances to drift, so the day it can be shared it should be;
  until then `Kati.ScreenBookDetailFaTest` asserts the two pages paint one
  status identically, for all five, which is the guard that actually fails when
  they part.
  """
  @spec status_pill(atom(), String.t()) :: map()
  def status_pill(status, label) do
    {dot, text, wash} = Kati.Screens.BookDetailFa.status_colours(status)
    assigns = %{label: label, dot: dot, text: text, wash: wash}

    ~MOB"""
    <Row
      height={24}
      corner_radius={12}
      background={@wash}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Box width={5} height={5} corner_radius={3} background={@dot} />
      <Spacer size={6} />
      {Kati.Screens.BookDetailFa.fa(@label, 11, @text, weight: "bold")}
    </Row>
    """
  end

  @doc "`{dot, text, wash}` for a status. Screen 66's four clauses, mirrored — see `status_pill/2`."
  @spec status_colours(atom()) :: {term(), term(), term()}
  def status_colours(:reading), do: {Palette.green(), Palette.green_text(), Palette.green_wash()}

  def status_colours(:finished),
    do: {Palette.green(), Palette.green_text(), Palette.green_wash()}

  def status_colours(:paused), do: {Palette.bronze(), Palette.gold_text(), Palette.cream()}

  def status_colours(_stopped), do: {Palette.tertiary(), Palette.sub(), Palette.track()}

  @doc """
  Two rating columns, and the stars hold their direction.

  Screen 66's `stars/1` unchanged: a five-star row read right to left would put
  the filled stars at the wrong end of the scale, and a rating is a quantity
  rather than a sentence.
  """
  @spec ratings(map()) :: map()
  def ratings(b) do
    l = SampleFa.labels()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.rating_card(l.yours, b.rating, b.rating_label)}
        </Column>
        <Spacer size={10} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.rating_card(l.others, nil, nil)}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def rating_card(label, rating, value) do
    assigns = %{label: label, rating: rating, value: value || "—"}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow={Kati.Theme.shadow_card()}
    >
      {Kati.Screens.BookDetailFa.fa(@label, 9.5, Palette.muted())}
      <Spacer size={9} />
      <Row fill_width={true} align="center">
        {Kati.Screens.BookDetail.stars(@rating)}
        <Spacer size={9} />
        {Kati.Screens.BookDetailFa.fa(@value, 13, :on_surface)}
      </Row>
    </Column>
    """
  end

  @doc """
  A row of chips, in Persian.

  `Kati.UI.chip/2` cannot draw these: `MishkaChip` takes its label as a prop
  and paints it in the chip's own family, and `expand/3` discards children — so
  a Persian label through that door is a row of boxes.
  `Kati.Screens.Fa`'s moduledoc names this as the single upstream ask, and
  until it lands the chips here are hand-rolled with the same geometry.
  """
  @spec chips([{atom(), String.t()}], atom(), String.t()) :: map()
  def chips(options, selected, prefix) do
    chips =
      options
      |> Enum.map(fn {value, label} ->
        Kati.Screens.BookDetailFa.chip(label, value == selected, "#{prefix}_#{value}")
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

  @doc false
  def chip(label, on?, tag) do
    assigns = %{
      label: label,
      background: if(on?, do: Palette.ink_fill(), else: Palette.card()),
      colour: if(on?, do: Palette.on_ink(), else: Palette.ink_soft()),
      weight: if(on?, do: "bold", else: "semibold"),
      tap: {self(), String.to_atom(tag)}
    }

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={@background}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={@tap}
    >
      {Kati.Screens.BookDetailFa.fa(@label, 12, @colour, weight: @weight)}
    </Row>
    """
  end

  @doc """
  Format chips, the two facts that follow from the format, and the toggle.

  ## Three assertions this band used to make about every book that will ever exist

  The lit chip was `:paperback`, the switch was `switch(true)`, and neither was
  a value read off a book. A hand-typed audiobook was drawn as a paperback, and
  a book whose `owned` is `false` by default (`Kati.Books.Book`, and screen 177
  never asks) was drawn with the ownership switch **on** — telling somebody they
  own an edition they never said they had, which is the same class of claim as
  the page count `D-59` reported.

  The band itself always draws: the chips are a control and the switch is a fact
  the book carries, so rule 5's *an empty band takes its own eyebrow with it*
  does not fire here even when both value rows are empty.

  A book with no page count and no ISBN draws the two labels and no values —
  `row/5`'s trailing is `if value, do: …, else: nil` and
  `Kati.UI.SettingsList.trailing/1` answers a nil with a zero `Spacer`, and both
  rows answer the same absence the same way since `own/3` stopped substituting
  an em dash for a missing ISBN. Screen 66 offers **Add page count** and **Add
  ISBN** there instead; those are English words, no board writes them in
  Persian, and this file's own rule about `Kati.Write.message/1` says what
  happens to a page that borrows 66's copy. So the row is quiet, and the
  affordance is a board question rather than a translation.

  ## An audiobook draws no length row at all, and that is not the same nothing

  Board 69's label for that row is **تعداد صفحه** — *number of pages* — because
  the board was captured on a paperback. `extent_label/1` answers `۱۱ ساعت ۲۰
  دقیقه` for an audiobook, and screen 177 offers صوتی, so the moment the format
  chip stopped asserting `:paperback` this row could draw a duration under a
  label that says *page count*. That is the exact failure screen 66's own
  `edition/1` doc says the band exists to prevent, in the mirror: *an edition
  switched from paperback to audiobook whose number did not change its unit
  would be a page count presented as a duration.* 66 escapes it by labelling the
  row `Length`; rule 6 forbids writing a Persian word for that here, because
  مدت appears on none of 69, 72, 76 or 176.

  So the row is absent for an audiobook rather than mislabelled, and nothing is
  lost: `meta/1` already draws `۱۱ ساعت ۲۰ دقیقه` under the cover, where no
  label contradicts it. A paperback with no page count keeps the row and draws
  no value, which is a different sentence — *this book has a page count and
  nobody has said what it is* — and that one board 69 can say.
  """
  @spec edition(map()) :: map()
  def edition(b) do
    l = SampleFa.labels()

    facts =
      Kati.Screens.BookDetailFa.length_row(l.length, b) ++
        [Kati.Screens.BookDetailFa.row("ISBN", nil, b.isbn, nil)]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.chips(SampleFa.formats(), b.format, "format")}
      {Kati.UI.SettingsList.card(facts)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.card([
        Kati.Screens.BookDetailFa.row(l.owned, nil, nil, "inventory_2", trailing: Kati.UI.SettingsList.switch(b.owned))
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The تعداد صفحه row, in a list of one — or in a list of none for an audiobook.

  A list rather than a row so the card is built by `++` and the absent case adds
  no node at all, which is the same shape `series/1` builds its two rows with.
  See `edition/1` for why an audiobook has no row here: the label is a page
  count's label, and `۱۱ ساعت ۲۰ دقیقه` under it would be a duration presented
  as a page count.

  The match is on `format` and not on `Kati.Books.Book.extent/1` because it is
  asking a different question — *does this row's label describe this edition* —
  and `extent/1` answers `{_, :minutes}` for exactly one format anyway.
  """
  @spec length_row(String.t(), map()) :: [map()]
  def length_row(_label, %{format: :audiobook}), do: []

  def length_row(label, b), do: [Kati.Screens.BookDetailFa.row(label, nil, b.extent_label, nil)]

  @doc """
  One list row, with its title and sub in Vazirmatn.

  `Kati.UI.SettingsList.row/4` supplies the geometry and the hairline; only the
  two `Text` nodes are this screen's, because those are the ones that carry
  Persian.
  """
  @spec row(String.t(), String.t() | nil, String.t() | nil, String.t() | nil, keyword()) :: map()
  def row(title, sub, value, icon, opts \\ []) do
    body =
      case sub do
        nil ->
          Kati.Screens.BookDetailFa.fa(title, 13.5, :on_surface, weight: "semibold")

        sub ->
          assigns = %{title: title, sub: sub}

          ~MOB"""
          <Column fill_width={true}>
            {Kati.Screens.BookDetailFa.fa(@title, 13.5, :on_surface, weight: "semibold")}
            <Spacer size={3} />
            {Kati.Screens.BookDetailFa.fa(@sub, 11.5, Palette.sub())}
          </Column>
          """
      end

    trailing =
      Keyword.get_lazy(opts, :trailing, fn ->
        if value, do: Kati.Screens.BookDetailFa.fa(value, 12.5, Palette.sub()), else: nil
      end)

    SettingsList.row(
      if(icon, do: SettingsList.icon_tile(icon), else: nil),
      body,
      SettingsList.trailing(trailing),
      on_tap: Keyword.get(opts, :on_tap)
    )
  end

  @doc """
  The warnings block, closed — or, at zero, absent along with its eyebrow.

  Closed by default and closed on arrival is the ticket's own instruction and is
  not a default that wants overriding: the point of a content warning is that
  you can choose to look at it, which a block that opens itself takes away.

  ## Why zero draws nothing at all, where screen 66 draws `None recorded`

  `D-59`'s second finding put three content warnings on a book somebody typed
  ten seconds ago. Zero is the honest count for every real book — nothing in the
  app stores a content warning, there is no resource — and the question is what
  a zero looks like. 66 answers with an English sentence and an `add` glyph. This
  page cannot: no board words that sentence in Persian, rule 6 forbids inventing
  it, and printing 66's under a Persian title is the failure
  `Kati.Screens.Fa` records for the آمار tab's stand-in and this file records
  again for `Kati.Write.message/1`. What is left is a row reading **هشدارها ۰**
  beside a chevron that expands nothing, which is a control that cannot act —
  the thing `D-59`'s own brief calls worse than no control.

  So the band goes, and its هشدار محتوا eyebrow goes with it, which is
  `Kati.Screens.BookDetail.series_section/1`'s rule and this page's rule
  throughout: *there is nothing to say, so nothing says it.* This mirror is
  quieter than 66 here, deliberately, and it closes the day a board draws the
  words rather than by borrowing English ones.
  """
  @spec warnings(map()) :: map() | []
  def warnings(%{warning_count: 0}), do: []
  def warnings(%{warning_count: nil}), do: []

  def warnings(b) do
    l = SampleFa.labels()

    assigns = %{count: b.warning_count}

    ~MOB"""
    <Column fill_width={true}>
      {Fa.eyebrow(SampleFa.eyebrows().warnings)}
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          nil,
          Kati.Screens.BookDetailFa.fa(l.warnings, 13.5, :on_surface, weight: "semibold"),
          Kati.UI.SettingsList.trailing(Kati.Screens.BookDetailFa.warning_trailing(@count))
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The count and the chevron, with the numeral drawn in the `fa` face.

  The count is an **integer** on both paths — `Kati.Books.SampleFa.detail/0`
  stores `3` where it used to store the string `"۳"`, exactly as its English
  twin has always stored `3` — and the digits are made here, by
  `Kati.Calendar.Shamsi.fa/1`, because the screen is the only thing that knows
  which digit table its face has: `kati_mono.ttf` carries none of U+06F0–U+06F9,
  which is `Kati.Screens.Fa`'s second type rule. `Shamsi.fa(3)` is this board's
  own `۳`, so nothing rendered moved.

  Two types through one function is how a `Text` ends up handed a bare integer:
  before this, the fixture's `"۳"` came through as a string and a shelved book's
  `0` would have come through as a number, into `fa/4`, whose `@spec` says
  `String.t()`.
  """
  @spec warning_trailing(non_neg_integer()) :: map()
  def warning_trailing(count) when is_integer(count) do
    assigns = %{count: Shamsi.fa(count)}

    ~MOB"""
    <Row align="center">
      {Kati.Screens.BookDetailFa.fa(@count, 12.5, Kati.Theme.Palette.sub())}
      <Spacer size={8} />
      {Kati.UI.symbol("expand_more", size: 20, color: Kati.Theme.Palette.tertiary())}
    </Row>
    """
  end

  @doc """
  The cream card, or nothing at all. The user's own words, never translated.

  The rows are the book's own notes, worded by `own_note/1` — the body untouched
  because it is the one thing on this page a person wrote, the anchor rebuilt
  from its page number because `Kati.Books.Note.anchor/1` answers in English.

  `Map.get(b, :notes, SampleFa.notes())` is screen 66's exact mechanism and it
  is what tells a fixture page from a book nobody has written about, since both
  otherwise look like *no rows*: `Kati.Books.SampleFa.detail/0` carries no
  `:notes` key at all, so the drawing answers with the drawing's two notes, and
  a shelved book answers with its own list — empty included, which closes the
  band.

  Empty closes the band **and its eyebrow**, on the cream card's own rule:
  cream marks the user's own words, so a book nobody has written about has no
  warm rectangle waiting for one — and no یادداشت‌ها و نقل‌قول‌ها standing over
  the place where it was. Before `D-59` this drew the fixture's two Persian
  quotations under every book anybody had ever typed.
  """
  @spec notes(map()) :: map() | []
  def notes(b) do
    case Map.get(b, :notes, SampleFa.notes()) do
      [] ->
        []

      notes ->
        rows =
          notes
          |> Enum.map(&Kati.Screens.BookDetailFa.note_row/1)
          |> Enum.intersperse(~MOB"<Spacer size={14} />")

        ~MOB"""
        <Column fill_width={true}>
          {Fa.eyebrow(SampleFa.eyebrows().notes)}
          <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
            {rows}
          </Column>
          <Spacer size={24} />
        </Column>
        """
    end
  end

  @doc """
  One entry in the cream card: the body, and the anchor when there is one.

  A note about a book rather than about a page has no anchor —
  `Kati.Books.Note`'s moduledoc calls that ordinary, *a thought about a book is
  not always a thought about a page* — and it draws no anchor line rather than
  the empty one 66 draws (`text={note.anchor || ""}`). The two pages differ by a
  10.5pt line and a 6pt gap on a row nobody has ever seen, and the reason to
  differ is house rule 3: the third possibility, handing `nil` to `fa/4`, prints
  the word **nil** in a cream card.
  """
  @spec note_row(map()) :: map()
  def note_row(note) do
    body = if note.kind == :quote, do: "«" <> note.body <> "»", else: note.body
    assigns = %{body: body, anchor: anchor_line(note.anchor)}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(@body, 14, Kati.Theme.Palette.cream_body(), lines: 3)}
      {@anchor}
    </Column>
    """
  end

  defp anchor_line(anchor) when is_binary(anchor) and anchor != "" do
    assigns = %{anchor: anchor}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={6} />
      {Kati.Screens.BookDetailFa.fa(@anchor, 10.5, Kati.Theme.Palette.cream_meta())}
    </Column>
    """
  end

  defp anchor_line(_none), do: []

  @doc """
  Series and ownership: two rows that push, or as few of them as are true.

  `chevron_left` and not `chevron_right`: a row that opens something opens it
  in the reading direction, and in Persian that is leftward. The same reasoning
  as the back pill's chevron, in the other direction.

  ## As few as are true, and none is a real answer

  `Kati.Screens.BookDetail.series_section/1`'s rule, quoted because it is the
  house precedent and its own words are the argument: *a book in no series and
  lent to nobody takes the whole band with it rather than drawing two empty
  rows — the same reasoning as the cream card. There is nothing to say, so
  nothing says it.*

  This band drew both rows unconditionally, off a fixture, so a hand-typed book
  was in `دفترهای ساحلی` and lent to `جو`. With the rows carrying the book's own
  facts they are `nil` for most real books, and `row/5` hands its title straight
  to `fa/4` — so without the gate this band is where screen 69 would print the
  word **nil** twice on a device. The eyebrow moved inside for the same reason
  66's did: a caption over nothing is `D-58`'s defect.

  Ownership is not one of these rows. A book you own and have not lent says so
  through the نسخه‌ای که دارم switch in the نسخه band, where board 69 draws it —
  see `lent_line/1` for why 66's standalone `Owned` row is not borrowed.
  """
  @spec series(map()) :: map() | []
  def series(b) do
    rows =
      [
        b.series_line && Kati.Screens.BookDetailFa.series_row(b),
        b.lent_to && Kati.Screens.BookDetailFa.lending_row(b)
      ]
      |> Enum.reject(&is_nil/1)

    case rows do
      [] ->
        []

      rows ->
        ~MOB"""
        <Column fill_width={true}>
          {Fa.eyebrow(SampleFa.eyebrows().series)}
          {Kati.UI.SettingsList.card(rows)}
          <Spacer size={24} />
        </Column>
        """
    end
  end

  @doc false
  def series_row(b) do
    Kati.Screens.BookDetailFa.row(b.series_line, b.series_next, nil, "menu_book",
      trailing: Kati.UI.symbol("chevron_left", size: 18, color: Palette.rail_idle()),
      on_tap: {self(), :open_series}
    )
  end

  @doc false
  def lending_row(b) do
    Kati.Screens.BookDetailFa.row(b.lent_to, b.lent_due, nil, "inventory_2",
      trailing: Kati.UI.symbol("chevron_left", size: 18, color: Palette.rail_idle()),
      on_tap: {self(), :open_lending}
    )
  end

  @doc """
  The reading history, or nothing at all.

  `Kati.Screens.BookDetail.history_section/1` one language over, `Map.get/3`
  default and all: the fixture carries no `:sessions` key, so the drawing keeps
  its three sittings, and a shelved book answers with its own — worded by
  `own_session/1`, because `Kati.Books.ReadingSession`'s own lines are English.

  Empty is a real state and it is drawn as nothing: a book you have not logged a
  sitting for has no history, and a band captioned تاریخچه خواندن over a blank
  card would be a promise the app has not kept. Before `D-59` it was worse than
  a promise — it was three sittings, with dates, that the reader never sat.
  """
  @spec history(map()) :: map() | []
  def history(b) do
    case Map.get(b, :sessions, SampleFa.sessions()) do
      [] ->
        []

      sessions ->
        rows = Enum.map(sessions, &Kati.Screens.BookDetailFa.session_row/1)

        ~MOB"""
        <Column fill_width={true}>
          {Fa.eyebrow(SampleFa.eyebrows().history)}
          {Kati.UI.SettingsList.card(rows)}
          <Spacer size={24} />
        </Column>
        """
    end
  end

  @doc """
  One sitting: the date, the span, and the duration when somebody timed it.

  `Kati.Books.ReadingSession`'s own rule reaches the trailing cell here — *a
  session with no minutes is a session that happened* — so an untimed sitting
  draws its date and its span and no trailing cell at all, which is what
  `Kati.UI.SettingsList.trailing(nil)` answers with. That is the row a person
  creates the first time they save from screen 72 without running the timer, and
  without the nil clause it is the word **nil** on the right of a Persian list
  row: the state `Kati.ScreenNilTextTest` cannot reach, because its sweep
  renders every screen against an empty database and this page answers an empty
  database with a complete fixture.
  """
  @spec session_row(map()) :: map()
  def session_row(session) do
    assigns = %{date: session.date, span: session.span}

    SettingsList.row(
      nil,
      ~MOB"""
      <Row fill_width={true} align="center">
        <Box width={72}>
          {Kati.Screens.BookDetailFa.fa(@date, 10.5, Kati.Theme.Palette.muted())}
        </Box>
        {Kati.Screens.BookDetailFa.fa(@span, 12.5, :on_surface)}
      </Row>
      """,
      SettingsList.trailing(Kati.Screens.BookDetailFa.duration(session.duration))
    )
  end

  @doc false
  def duration(nil), do: nil
  def duration(text), do: Kati.Screens.BookDetailFa.fa(text, 12, Palette.muted())

  @doc false
  def actions do
    l = SampleFa.labels()

    seconds =
      [{"check", l.finish, :finish}, {"star", l.rate, :rate}, {"bookmarks", l.list, :add_to_list}]
      |> Enum.map(fn {icon, label, tag} -> Kati.Screens.BookDetailFa.second(icon, label, tag) end)
      |> Enum.intersperse(~MOB"<Spacer size={10} />")

    assigns = %{primary: l.primary, seconds: seconds}

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
        {Kati.Screens.BookDetailFa.fa(@primary, 15, Palette.on_ink(), weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true}>
        {@seconds}
      </Row>
    </Column>
    """
  end

  @doc false
  def second(icon, label, tag) do
    assigns = %{icon: icon, label: label, tap: {self(), tag}}

    ~MOB"""
    <Column weight={1.0} align="center" on_tap={@tap}>
      <Box
        width={44}
        height={44}
        corner_radius={22}
        background={Kati.Theme.Palette.card()}
        align="center"
        shadow={Kati.Theme.shadow_button()}
      >
        {Kati.UI.symbol(@icon, size: 20)}
      </Box>
      <Spacer size={7} />
      {Kati.Screens.BookDetailFa.fa(@label, 11.5, Kati.Theme.Palette.sub(),
        weight: "semibold",
        align: "center"
      )}
    </Column>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # The sheet is handed the id of the book this page is drawing — screen 66's
  # own door does the same through `Kati.Screens.LogProgress.params_for/1`, and
  # the key is spelled there rather than here so the English sheet and the
  # Persian one cannot drift apart about what `:book_id` means.
  # Through `target/1`, like تمام شد and the chips, and not off
  # `socket.assigns.book`. This is the page's THIRD write-bearing door and it
  # was the one left resolving its own subject: on a page drawing the fixture
  # over a full shelf — an id that names a deleted row, or `shelved/1`'s rescue
  # firing on a store it cannot reach — `assigns.book` is
  # `Kati.Books.SampleFa.detail/0`, which carries no `:id`, so `params_for/1`
  # answered `%{}` and screen 72's `mount/3` fell through to `shelf_head/0` and
  # drew somebody else's book. Then `save_session/2` wrote a sitting against it.
  #
  # `target/1` answers `nil` there, `params_for/1` still answers `%{}` for a
  # nil, and screen 72 still falls back — so this does not close that hole on
  # its own. What it does is make all four writers on this page name ONE row,
  # which is the condition under which closing it once closes it everywhere;
  # `Kati.Screens.BookDetail.handle_tap(:log_progress, …)` has the identical
  # shape and the same argument applies to it.
  def handle_info({:tap, :log_progress}, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.LogProgressFa,
         Kati.Screens.LogProgress.params_for(%{
           id: Kati.Screens.BookDetailFa.target(socket.assigns)
         })
       )}

  def handle_info({:tap, :rate}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}

  # تمام شد is a write and then a handover, which is screen 66's `:finish` one
  # language over. The consequence stays in
  # `Kati.Screens.LogProgress.finish_book/1` so the two pages cannot drift
  # about what finishing a book means, and the book named is the book on the
  # page: `finish_book/1` defaults to the head of the shelf, so a page opened
  # on the third book used to finish the first — the defect #84 fixed one
  # screen over.
  #
  # `target/1` and not `book[:id]`, and the guard is on this side rather than
  # inside `finish_book/1`. `finish_book(nil)` is documented as *the shelf's
  # first* and behaves that way — `current_book(nil)` reads the `:shelf` action
  # and takes its head — so handing it a `nil` is asking it to finish a book
  # this page did not draw. There are two ways to reach that `nil` and both are
  # real: nothing is shelved (harmless, the store answers nothing), and
  # `shelved/1` rescued a store it could not reach while the shelf is full,
  # which is a locked or reopened SQLite handle on a device and the only reason
  # that rescue exists. In the second, the page draws the fixture over a full
  # shelf and تمام شد would mark its head finished and push screen 33 to rate
  # it — a write against a row the page never drew, which is
  # `Kati.ScreenWriteTargetTest`'s whole subject.
  #
  # So the page refuses instead. Making `finish_book(nil)` itself refuse is the
  # deeper fix and is not this stream's to make: screen 70 mounts bare with
  # `book_id: nil`, resolves the shelf's head to DRAW, and its own `Finished the
  # book` then relies on that `nil` meaning the head — `Kati.BooksTest`'s
  # *finishing saves the session, sets the status, and hands to screen 33* is
  # that path, green. The clause and screen 70's mount resolving its head into
  # `:book_id` — which `Kati.Screens.LogProgressFa.mount/3` already does — are
  # one edit, and it is reported rather than half-made here.
  #
  # The push waits on the write for screen 66's reason: screen 33 asks you to
  # rate a book you just finished, and arriving there off a refused write asks
  # you to rate one the shelf still has you halfway through. `:rate` beside it
  # pushes the same English screen, so that debt is this file's already and is
  # not deepened here.
  #
  # A refused write leaves the page as it was and says nothing, which is the
  # one place this mirror is quieter than 66. 66 draws a red notice from
  # `Kati.Write.message/1`; board 69 draws none, and it cannot borrow 66's,
  # because that message answers in English ("Nothing to save yet.") and an
  # English sentence under a Persian title is the failure `Kati.Screens.Fa`
  # records for the آمار tab's stand-in. It closes when a board draws the
  # notice in Persian, not by printing 66's.
  #
  # It therefore stays on `Kati.ScreenTapSweepTest`'s `@inert_taps`, and moves
  # category rather than coming off: not *unwired* any more, but a no-op
  # against the empty shelf that sweep mounts, which is exactly the reason the
  # status and edition chips above it are on that list. 66's own `:finish` is
  # absent from it only because its error branch assigns `:save_error`.
  def handle_info({:tap, :finish}, socket) do
    case Kati.Screens.BookDetailFa.target(socket.assigns) do
      nil ->
        {:noreply, socket}

      id ->
        case Kati.Screens.LogProgress.finish_book(id) do
          {:ok, _book} -> {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}
          {:error, _reason} -> {:noreply, socket}
        end
    end
  end

  # The status and format chips, which write and then re-read — screen 66's
  # catch-all one language over, through the two public halves of it so the two
  # pages cannot come to mean different things by one chip.
  # `Kati.Screens.BookDetail.chip_change/1` parses the tag against
  # `Kati.Books.Sample.statuses/0` and `formats/0`, whose ATOMS are the Persian
  # lists' atoms — `Kati.Books.SampleFa` differs from them in the words and in
  # nothing else, and `chips/3` builds `status_#{value}` from the same atom — so
  # one parser answers for both pages and a fifth status cannot arrive on one of
  # them alone.
  #
  # `D-59` is why this is here at all. The chips used to assert `:reading` and
  # `:paperback` in markup: the row was a frozen picture of the fixture and read
  # like one. They draw the book's own state now, and a chip that lights like a
  # live control and cannot act is the thing `D-59`'s brief calls worse than no
  # control — so making them honest was what obliged them to work.
  #
  # The re-read is `book/1` and not an assign of the chip alone, for 66's
  # reason: the pill, the bar, the meta line, the position line and the extent
  # are all derived from the row, so writing the status without re-reading would
  # leave five things on the card disagreeing with the chip just pressed. It
  # re-reads through `target/1`'s id rather than the page's, so the second tap
  # on a page opened from a cover still lands on that cover's book.
  #
  # `nil` from `target/1` is a refusal for `:finish`'s reason: `apply_change/2`
  # reads a `nil` id as the shelf's newest and would move a real book's status
  # under a page drawing the fixture.
  #
  # A refused write leaves the page as it was and says nothing, which is where
  # this mirror is quieter than 66 — see `:finish` above. That is also why the
  # seven chip tags stay on `Kati.ScreenTapSweepTest`'s `@inert_taps`: against
  # the empty shelf that sweep mounts, `target/1` is `nil` and nothing moves.
  # That list's own note for screen 69 — *the mirror of 66's, which write
  # against a shelved book and no-op against an empty one* — describes this
  # clause and described nothing before it.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    with change when not is_nil(change) <- Kati.Screens.BookDetail.chip_change(tag),
         id when is_binary(id) <- Kati.Screens.BookDetailFa.target(socket.assigns),
         {:ok, _book} <- Kati.Screens.BookDetail.apply_change(id, change) do
      {:noreply, Mob.Socket.assign(socket, :book, Kati.Screens.BookDetailFa.book(id))}
    else
      _no_write -> {:noreply, socket}
    end
  end

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
