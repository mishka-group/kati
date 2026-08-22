defmodule Kati.BooksTest do
  @moduledoc """
  The Books domain, and the two screens standing on it.

  ## What this file is actually guarding

  Screen 20 shelved books off `Kati.Books.Sample` and that was honest for a
  shelf — a cover and a fraction. Screen 66 shows an ISBN, an edition, a
  lending due date and a reading history, and screen 70 *writes*. So the three
  things worth pinning are the three that a picture of an app never has to get
  right:

    * the arithmetic that turns rows into the lines the design prints,
    * the write path, end to end, including what it does to the book, and
    * the fallback, which is the only reason either screen renders at all on a
      phone with an empty shelf.

  ## Why every row is prefixed and deleted

  `Kati.ScreenDesignLiteralTest` renders screens 66 and 70 against this same
  shared database file, and both fall back to their drawing **only while
  `books` is empty**. One book left behind here makes screen 66 take the real
  path, its drawing's literals stop appearing, and the failure lands on a file
  this one never touched — for the seeds that happen to order the two modules
  the wrong way round. `Kati.MediaMoodTest` records the same hazard, and it is
  the same hazard: a coin flip, not a flake.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Books.Book
  alias Kati.Books.Note
  alias Kati.Books.ReadingSession
  alias Kati.Screens.BookDetail
  alias Kati.Screens.LogProgress

  @prefix "books-test-"

  setup do
    on_exit(&delete_rows!/0)
    :ok
  end

  defp delete_rows! do
    # Children first: the foreign keys refuse the parent delete otherwise. Raw
    # SQL because this runs from `on_exit`, after the test process is gone.
    for table <- ~w(book_notes book_reading_sessions) do
      Kati.Repo.query!(
        "DELETE FROM #{table} WHERE book_id IN (SELECT id FROM books WHERE title LIKE ?1)",
        [@prefix <> "%"]
      )
    end

    Kati.Repo.query!("DELETE FROM books WHERE title LIKE ?1", [@prefix <> "%"])
  end

  defp sessions_of(book) do
    ReadingSession
    |> Ash.Query.for_read(:for_book, %{book_id: book.id})
    |> Ash.read!()
  end

  defp a_book!(attrs \\ %{}) do
    Ash.create!(
      Book,
      Map.merge(
        %{
          title: @prefix <> "The Salt Almanac",
          author: "Ines Karvel",
          publisher: "Faber",
          published_year: 2024,
          isbn: "978–0–571–33915–2",
          page_count: 380,
          current_page: 214,
          status: :reading,
          format: :paperback,
          rating: 9,
          owned: true,
          cover_seed: "bookaa1",
          series_name: "The Coastal Ledgers",
          series_position: 3,
          series_total: 7
        },
        attrs
      )
    )
  end

  describe "a book's own arithmetic" do
    test "extent follows the format, not whichever column is filled" do
      # The point of band 5 on screen 66: an edition switched from paperback to
      # audiobook must stop reporting its page count in the same render the chip
      # changes, or a page count is presented as a duration.
      paperback = %Book{format: :paperback, page_count: 380, duration_minutes: 680}
      audiobook = %Book{paperback | format: :audiobook}

      assert Book.extent(paperback) == {380, :pages}
      assert Book.extent(audiobook) == {680, :minutes}
      assert Book.extent(%Book{format: :paperback, page_count: nil}) == nil
    end

    test "fraction is nil without a denominator, never zero" do
      # Screen 67's partial-metadata state draws no bar at all. A bar pinned at
      # zero says "you have read none of it", which is the one claim the state
      # exists to avoid making about a book you are 214 pages into.
      assert Book.fraction(%Book{format: :paperback, page_count: nil, current_page: 214}) == nil

      assert Book.fraction(%Book{format: :paperback, page_count: 380, current_page: 214}) ==
               214 / 380
    end

    test "fraction cannot exceed one" do
      # A book you read past its recorded page count — a different edition, a
      # miscounted appendix — is finished, not 104% finished.
      assert Book.fraction(%Book{format: :paperback, page_count: 380, current_page: 400}) == 1.0
    end

    test "the shelf line says what the status means, then what the pages say" do
      assert Book.shelf_line(%Book{status: :finished}) == "finished"
      assert Book.shelf_line(%Book{status: :not_started}) == "to read"

      assert Book.shelf_line(%Book{
               status: :reading,
               format: :paperback,
               page_count: 380,
               current_page: 214
             }) == "p.214/380"

      # No denominator: the position alone rather than an invented total.
      assert Book.shelf_line(%Book{status: :reading, format: :paperback, current_page: 214}) ==
               "p.214"
    end

    test "the series line degrades a part at a time" do
      full = %Book{series_name: "The Coastal Ledgers", series_position: 3, series_total: 7}

      assert Book.series_line(full) == "#3 of 7 in The Coastal Ledgers"
      assert Book.series_line(%Book{full | series_total: nil}) == "#3 in The Coastal Ledgers"
      assert Book.series_line(%Book{}) == nil
    end
  end

  describe "pace" do
    # Screen 70's own caption is the specification: minutes read across the last
    # seven calendar days ÷ 7. Every case below is that sentence taken literally.
    @today ~D[2026-08-16]

    defp session(days_ago, minutes) do
      %ReadingSession{read_on: Date.add(@today, -days_ago), minutes: minutes}
    end

    test "a skipped night dilutes the figure rather than vanishing from it" do
      # 38 + 31 + 29 = 98 over SEVEN days, not over the three that had a session.
      sessions = [session(0, 38), session(2, 31), session(5, 29)]

      assert ReadingSession.pace(sessions, @today) == div(98, 7)
    end

    test "the window is the last seven calendar days, inclusive of today" do
      assert ReadingSession.pace([session(6, 70)], @today) == 10
      assert ReadingSession.pace([session(7, 70)], @today) == nil
    end

    test "a future session is outside the window too" do
      # A date in the future is a typo or a clock skew. Either way it is not
      # reading that has happened, so it cannot contribute to a trailing mean.
      assert ReadingSession.pace([session(-1, 70)], @today) == nil
    end

    test "nobody timed anything is nil, not zero" do
      # Different claims: "you read for no time" against "no sitting recorded a
      # duration". Only the first belongs on a card, and it is not the true one.
      assert ReadingSession.pace([session(0, nil)], @today) == nil
      assert ReadingSession.pace([], @today) == nil
    end

    test "an untimed session still counts as a session everywhere else" do
      # It has no minutes and so no pace, but it happened: the history band must
      # still show it, which is what `duration_line/1` returning nil is for.
      untimed = %ReadingSession{from_page: 94, to_page: 130, minutes: nil}

      assert ReadingSession.span_line(untimed) == "p. 94 → 130"
      assert ReadingSession.duration_line(untimed) == nil
      assert ReadingSession.pages(untimed) == 36
    end

    test "a re-read runs backwards and still has a positive span" do
      assert ReadingSession.pages(%ReadingSession{from_page: 214, to_page: 194}) == 20
    end
  end

  describe "notes" do
    test "a quote wears quotation marks and a note does not" do
      # Applied on the resource rather than in the screen, so screens 66 and 68
      # — the light page and its dark twin — cannot disagree about it.
      assert Note.display(%Note{kind: :quote, body: "The tide keeps its own ledger."}) ==
               "“The tide keeps its own ledger.”"

      assert Note.display(%Note{kind: :note, body: "Re-read chapter seven."}) ==
               "Re-read chapter seven."
    end

    test "a note about the book rather than about a page has no anchor" do
      assert Note.anchor(%Note{page: 148}) == "p. 148"
      assert Note.anchor(%Note{page: nil}) == nil
      assert Note.anchor(%Note{page: 0}) == nil
    end
  end

  describe "screen 66 with a shelf" do
    test "every band reads the row rather than the drawing" do
      book = a_book!()

      Ash.create!(ReadingSession, %{
        book_id: book.id,
        read_on: Kati.Time.today(),
        from_page: 168,
        to_page: 214,
        minutes: 38
      })

      Ash.create!(Note, %{book_id: book.id, kind: :quote, body: "Its own ledger.", page: 148})

      shown = BookDetail.book()

      assert shown.title == @prefix <> "The Salt Almanac"
      assert shown.meta == "2024 · FABER · 380 PP"
      assert shown.status_label == "Reading"
      assert shown.extent_label == "380 pages"
      assert shown.rating_label == "4.5"
      assert shown.series_line == "#3 of 7 in The Coastal Ledgers"
      assert [%{body: "Its own ledger.", anchor: "p. 148"}] = shown.notes
      assert [%{span: "p. 168 → 214", duration: "38m"}] = shown.sessions

      # The pace joins the position line only once a session has minutes in the
      # window — one 38-minute sitting is 5 min/day, not 38.
      assert shown.progress_line == "p. 214 / 380 · 5 MIN/DAY PACE"
    end

    test "the community rating is an em dash and not a zero" do
      a_book!()

      # `nil` all the way through, because Open Library carries no community
      # rating and a `0` would be a score somebody gave.
      assert BookDetail.book().community == nil
    end

    test "an audiobook restates its unit in both places" do
      a_book!(%{format: :audiobook, duration_minutes: 680, page_count: 380})

      shown = BookDetail.book()

      assert shown.extent_label == "11h 20m"
      assert shown.meta == "2024 · FABER · 11H 20M"
    end

    test "a book with no page count prints the position and says so" do
      a_book!(%{page_count: nil})

      shown = BookDetail.book()

      assert shown.progress_line == "p. 214 · NO PAGE COUNT"
      assert shown.extent_label == nil
      # No denominator means no bar — see `Kati.Books.Book.fraction/1`.
      assert shown.progress == nil
      assert BookDetail.bar(shown.progress) == []
    end

    test "the page renders with the row's copy in the tree" do
      a_book!()

      tree = tree(mount_screen(BookDetail))

      assert find(tree, :text, text: @prefix <> "The Salt Almanac") != nil
      assert find(tree, :text, text: "978–0–571–33915–2") != nil
      assert find(tree, :text, text: "#3 of 7 in The Coastal Ledgers") != nil
    end

    test "the primary button relabels for a book nobody has opened" do
      a_book!(%{status: :not_started, current_page: 0})

      tree = tree(mount_screen(BookDetail))

      assert find(tree, :text, text: "Start reading") != nil
      assert find(tree, :text, text: "Log progress") == nil
    end
  end

  describe "screen 66 with nothing shelved" do
    test "the drawing is what renders, whole" do
      assert BookDetail.book() == BookDetail.drawn_book()
    end

    test "the sheet falls back to the same book the page does" do
      # Not merely "the sheet has a fallback": a sheet aimed at a different book
      # from the screen that opened it would write a session against the wrong
      # title.
      assert LogProgress.book() == BookDetail.drawn_book()
    end
  end

  describe "screen 70, the write path" do
    test "saving writes a session and moves the book" do
      book = a_book!()

      view = mount_screen(LogProgress)
      stepped = Enum.reduce(1..3, view, fn _i, v -> render_info(v, {:tap, :step_up}) end)

      assert assigns(stepped).page == 217

      render_info(stepped, {:tap, :save})

      assert [session] = sessions_of(book)
      assert session.from_page == 214
      assert session.to_page == 217
      assert session.reread == false
      assert session.read_on == Kati.Time.today()

      assert Ash.get!(Book, book.id).current_page == 217
    end

    test "a page below the current one is logged as a re-read and does not move the book" do
      # Screen 71's own reasoning: a page below your position is almost always a
      # re-read rather than a typo. Recording it must not walk the position
      # backwards, or finishing a re-read would un-finish the book.
      book = a_book!()

      view = mount_screen(LogProgress)
      stepped = Enum.reduce(1..20, view, fn _i, v -> render_info(v, {:tap, :step_down}) end)

      render_info(stepped, {:tap, :save})

      assert [session] = sessions_of(book)
      assert session.to_page == 194
      assert session.reread == true

      assert Ash.get!(Book, book.id).current_page == 214
    end

    test "the stepper cannot go below zero" do
      a_book!(%{current_page: 1})

      view = mount_screen(LogProgress)
      floored = Enum.reduce(1..5, view, fn _i, v -> render_info(v, {:tap, :step_down}) end)

      assert assigns(floored).page == 0
    end

    test "finishing saves the session, sets the status, and hands to screen 33" do
      book = a_book!()

      view = mount_screen(LogProgress)
      finished = render_info(view, {:tap, :finish})

      assert navigated_to(finished) == Kati.Screens.Rating
      assert Ash.get!(Book, book.id).status == :finished
      assert [_session] = sessions_of(book)
    end

    test "screen 66's Finish is the same consequence, reached from a different control" do
      book = a_book!()

      finished = render_info(mount_screen(BookDetail), {:tap, :finish})

      assert navigated_to(finished) == Kati.Screens.Rating
      assert Ash.get!(Book, book.id).status == :finished
    end

    test "the timer is a row, so switching it on never takes the field away" do
      a_book!()

      running = render_info(mount_screen(LogProgress), {:tap, :start_timer})
      tree = tree(running)

      assert assigns(running).timing? == true
      assert find(tree, :text, text: "Timing this session") != nil
      assert find(tree, :text, text: "Stop") != nil
      # The manual field is still there, which is the whole point of the row.
      assert find(tree, :text, text: "I AM NOW ON PAGE") != nil
    end

    test "the unit segments change the label under the number" do
      a_book!()

      view = mount_screen(LogProgress)

      for {tag, label} <- [
            {:unit_percent, "I AM NOW AT PERCENT"},
            {:unit_minutes, "MINUTES READ"},
            {:unit_page, "I AM NOW ON PAGE"}
          ] do
        switched = render_info(view, {:tap, tag})

        assert assigns(switched).unit == tag
        assert find(tree(switched), :text, text: label) != nil
      end
    end

    test "the sheet opens on the page you are actually on" do
      # Not on a round number ahead of it: a sheet that guesses is a sheet whose
      # first act is to be corrected.
      a_book!(%{current_page: 96})

      assert assigns(mount_screen(LogProgress)).page == 96
    end

    test "closing writes nothing" do
      book = a_book!()

      view = mount_screen(LogProgress)
      closed = render_info(render_info(view, {:tap, :step_up}), {:tap, :close})

      assert navigated_to(closed) == {:pop}
      assert sessions_of(book) == []
      assert Ash.get!(Book, book.id).current_page == 214
    end

    test "the whole sheet renders a tree the native layer can draw" do
      a_book!()
      assert_renderable(mount_screen(LogProgress))
    end
  end
end
