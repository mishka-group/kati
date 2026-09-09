defmodule Kati.ScreenBookDetailFaTest do
  @moduledoc """
  Screen 69 states no fact about a book that the book does not carry.

  ## The defect, as a device found it

  `D-38` shipped board 177 on 5 September and with it the only control in the
  app that creates a `Kati.Books.Book`. A title was typed on a Pixel 9a — a
  title and nothing else, status *not started* — and screen 69 opened on it
  reading **در حال خواندن** in the status pill with the reading chip lit,
  `۱۴۰۳ · ۳۸۰ صفحه` under it, a bar past half and `ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در
  روز` beside it, ۴٫۵ stars with four of them filled, three content warnings, a
  series, a borrower with a due date, two notes in the cream card and three
  reading sittings. **One fact on that page was the reader's**, and it was the
  title.

  The mechanism was `Map.merge/2` over an `own/1` that named five keys: every
  key it did not name kept the fixture's value, silently, and that had been
  invisible for as long as no Persian book could exist. `D-59` is the ticket and
  this file is its screen-69 half.

  ## Why this file exists beside the sweeps rather than inside them

  Every sweep that would have caught this renders against an **empty database**,
  where screen 69 answers with a complete fixture — which is the one state in
  which the page cannot lie. `Kati.ScreenNilTextTest` says so about itself in as
  many words: *a screen drawing its fixture is the weakest case this can check.*
  So the questions those files ask well are asked again here, on a page that is
  drawing a real row: no `Text` with a `nil` in it, every Persian numeral in the
  `fa` face, and every band that has nothing to say saying nothing.

  ## The second half: WHICH book the page is about

  The first pass closed the merge and left the page unable to say which book it
  was drawing. `mount/3` matched `_params` while board 176's covers carried the
  row's own id, so tapping the second jacket opened the head of the shelf —
  and with `own/3` total over twenty-two keys, that tap drew the head's status,
  position, rating, ISBN, series, borrower, notes and sittings under the title
  you pressed, then wrote تمام شد against it. `D-59`'s acceptance sentence is
  the one it broke, so the describes below ask both halves of it: *is this page
  about the book I opened*, and *does a control on it write to that book*.

  ## Why every row is prefixed and deleted, on both sides

  `Kati.BooksByHandTest`'s discipline, verbatim and for its reason: the suite has
  no Ecto sandbox, and `Kati.ScreenDesignLiteralTest`,
  `Kati.ScreenEmptyDatabaseTest` and `Kati.ScreenSampleOnlyTest` render these
  same screens against this same shared SQLite file. A book left behind here
  fails a file this one never touched — and now fails it harder than before,
  because a stray row removes whole bands from screen 69 rather than merely
  changing its title. So the rows go before the test as well as after it: an
  interrupted run leaves the table dirty, and the next run's `setup` is the only
  thing that can clear it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Books.Book
  alias Kati.Books.Note
  alias Kati.Books.ReadingSession
  alias Kati.Books.SampleFa
  alias Kati.Calendar.Shamsi
  alias Kati.Components.MishkaSwitch
  alias Kati.Screens.BookDetail
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.BooksFa

  @prefix "screen-69-fa-test-"

  # U+06F0–U+06F9, the extended Arabic-Indic digits `fa` renders and
  # `kati_mono.ttf` carries none of.
  @persian_digit ~r/[\x{06F0}-\x{06F9}]/u

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  describe "a book that carries nothing" do
    test "a title and nothing else opens a page with nothing else on it" do
      a_book!(%{title: @prefix <> "نگهبان"})

      page = BookDetailFa.book()
      drawn = BookDetailFa.drawn_book()

      # What the book itself says, key by key. Every one of these is a fact the
      # person gave, or the honest absence of one.
      assert page.title == @prefix <> "نگهبان"
      assert page.author == nil
      assert page.status == :not_started
      assert page.status_label == "شروع نشده"
      assert page.meta == ""
      assert page.progress == nil
      # `""` and not شروع نشده: the pill nine points above has just said that
      # word, and `position_line/2` draws the position half only — see finding 1
      # of `D-59`'s review, and the pill's own assertion further down.
      assert page.progress_line == ""
      assert page.rating == nil
      assert page.rating_label == nil
      assert page.format == :paperback
      assert page.extent_label == nil
      assert page.isbn == nil
      assert page.owned == false
      assert page.warning_count == 0
      assert page.series_line == nil
      assert page.series_next == nil
      assert page.lent_to == nil
      assert page.lent_due == nil
      assert page.notes == []
      assert page.sessions == []

      # And the drawing's, key by key, because this is the test that fails today
      # for eleven separate reasons — the page claiming 214 pages of 380, a 4.5
      # nobody awarded, three warnings, a series and a borrower.
      refute page.status_label == drawn.status_label
      refute page.meta == drawn.meta
      refute page.progress == drawn.progress
      refute page.progress_line == drawn.progress_line
      refute page.rating == drawn.rating
      refute page.rating_label == drawn.rating_label
      refute page.extent_label == drawn.extent_label
      refute page.series_line == drawn.series_line
      refute page.lent_to == drawn.lent_to
      refute page.owned == drawn.owned
    end

    test "not one of the fixture's sentences is anywhere in the rendered tree" do
      a_book!(%{title: @prefix <> "نگهبان"})

      drawn = BookDetailFa.drawn_book()
      words = words_of(BookDetailFa)

      # `status_label` is deliberately not in this list: در حال خواندن is also one
      # of the four words the status chip row draws for every book, and the chip
      # row is a control rather than a claim. The pill's own word is asserted
      # further down.
      for sentence <- [
            drawn.author,
            drawn.meta,
            drawn.progress_line,
            drawn.extent_label,
            drawn.isbn,
            drawn.series_line,
            drawn.series_next,
            drawn.lent_to,
            drawn.lent_due,
            "۳",
            "«جزر و مد دفتر خودش را نگه می‌دارد.»",
            "ص. ۱۴۸",
            "ص. ۱۶۸ → ۲۱۴",
            "۳۸ دقیقه"
          ] do
        refute words =~ sentence,
               "screen 69 drew `#{sentence}` for a book that carries no such fact"
      end

      assert words =~ @prefix <> "نگهبان", "and it drew the one thing it was given"
    end

    test "an empty band takes its own eyebrow with it, and the bands that are controls stay" do
      # `D-58`'s defect, which is what a straight blanking of the four data
      # bands would have left behind. وضعیت and نسخه caption controls — a chip
      # row and a switch — and draw whatever the book says; the other four
      # caption data, and a caption over nothing is a promise the app has not
      # kept.
      a_book!(%{title: @prefix <> "نگهبان"})

      e = SampleFa.eyebrows()
      words = words_of(BookDetailFa)

      assert words =~ e.status
      assert words =~ e.edition

      refute words =~ e.warnings
      refute words =~ e.notes
      refute words =~ e.series
      refute words =~ e.history

      # And the cards under them are gone too, not merely their captions.
      refute words =~ SampleFa.labels().warnings
    end

    test "no Text on the page is drawn with a nil, and no numeral leaves the fa face" do
      # The two questions `Kati.ScreenNilTextTest` and `Kati.PersianFontTest` ask
      # of every screen, asked here of the branch neither can reach: both sweep
      # an empty database, where this page draws a complete fixture.
      #
      # `text={nil}` is not a blank line on a device — it is the word **nil** in
      # the page's own type, which is what a nil `series_line` or `lent_to`
      # through `row/5` would have printed under a Persian eyebrow.
      a_book!(%{title: @prefix <> "نگهبان", author: nil})

      nodes = BookDetailFa |> mount_screen() |> Mob.ScreenCase.flatten()

      nils =
        Enum.filter(nodes, fn node ->
          node.type == :text and Map.get(node.props || %{}, :text) == nil
        end)

      assert nils == [], "screen 69 hands `text=` a nil: #{inspect(Enum.map(nils, & &1.props))}"

      wrong_face =
        Enum.filter(nodes, fn node ->
          props = node.props || %{}
          text = Map.get(props, :text)

          is_binary(text) and text =~ @persian_digit and Map.get(props, :font_family) != "fa"
        end)

      assert wrong_face == [],
             "`kati_mono.ttf` carries none of U+06F0–U+06F9, so a Persian numeral outside " <>
               "the `fa` face is drawn by whatever the platform falls back to: " <>
               inspect(Enum.map(wrong_face, & &1.props))
    end
  end

  describe "the facts the page draws are the book's own" do
    test "the year is the edition's own, in Persian digits, and is never converted to Shamsi" do
      # The decision `D-59` sent to a board and this screen had to answer to draw
      # anything: a Gregorian year straddles two Shamsi years because the year
      # turns at Nowruz, `Kati.Calendar.Shamsi` converts dates and has no
      # year-to-year function, and screens 04, 58, 76 and 77 all keep a stored
      # Gregorian year in Persian digits. The `refute` is the load-bearing half —
      # it fails the day somebody reaches for `from_gregorian/1` on a bare year.
      book = a_book!(%{title: @prefix <> "سالنامه", published_year: 2024, page_count: 380})

      assert BookDetailFa.book().meta == "۲۰۲۴ · ۳۸۰ صفحه"
      refute BookDetailFa.book().meta =~ "۱۴۰۳"

      # A part at a time, and never a nil handed to a Text. Rebound each time,
      # because a second update off a stale struct is a second question.
      book = Ash.update!(book, %{page_count: nil})
      assert BookDetailFa.book().meta == "۲۰۲۴"

      Ash.update!(book, %{published_year: nil})
      assert BookDetailFa.book().meta == ""
    end

    test "the status pill wears the book's own status, and 66 and 69 colour one status alike" do
      a_book!(%{title: @prefix <> "نگهبان"})

      pill = BookDetailFa.status_pill(:not_started, "شروع نشده")

      assert pill.props.background == elem(BookDetailFa.status_colours(:not_started), 2)
      refute pill.props.background == elem(BookDetailFa.status_colours(:reading), 2)
      assert words_of(BookDetailFa) =~ "شروع نشده"

      # The non-tautological form of *the two pages must not disagree about what
      # a status looks like*. 69 mirrors 66's four clauses rather than calling
      # them — `Kati.Screens.BookDetail.status_colours/1` is private and screen
      # 66's file is not this stream's to widen — so this is the guard that
      # actually fails on the day they drift.
      for status <- [:reading, :finished, :paused, :did_not_finish, :not_started] do
        english = BookDetail.status_pill(status, "x")
        persian = BookDetailFa.status_pill(status, "x")

        assert persian.props.background == english.props.background,
               "screens 66 and 69 draw #{inspect(status)} on two different washes"
      end
    end

    test "no status chip lights for a book nobody has opened, and the right one does otherwise" do
      # `Kati.Books.Book`'s own doctrine: the four the control offers are the
      # four you can move *to*, so an unlit row is the honest answer for
      # `:not_started` and screen 66 lights none either.
      book = a_book!(%{title: @prefix <> "نگهبان"})

      for {_value, label} <- SampleFa.statuses() do
        refute lit?(BookDetailFa, label), "#{label} is lit for a book nobody has opened"
      end

      Ash.update!(book, %{status: :paused})

      assert lit?(BookDetailFa, "متوقف")
      refute lit?(BookDetailFa, "در حال خواندن")
    end

    test "the format chip and the ownership switch are the book's own" do
      # Two more assertions the markup used to make about every book that will
      # ever exist: `chips(formats, :paperback, …)` and `switch(true)`. The
      # second one told somebody they own an edition they never said they had —
      # `owned` defaults to false and screen 177 never asks.
      a_book!(%{
        title: @prefix <> "کتاب صوتی",
        format: :audiobook,
        duration_minutes: 680,
        owned: false
      })

      assert BookDetailFa.book().extent_label == "۱۱ ساعت ۲۰ دقیقه"
      assert BookDetailFa.book().owned == false

      assert lit?(BookDetailFa, "صوتی")
      refute lit?(BookDetailFa, "شمیز")

      # `Kati.UI.SettingsList.switch/1` draws the control rather than emitting a
      # native one, so its state is in the thumb's signed offset from the track's
      # centre and not in a `checked` prop — see
      # `Kati.Components.MishkaSwitch.thumb_offset/4`, whose arithmetic this
      # borrows rather than restating as a number.
      off = MishkaSwitch.thumb_offset(false, 46, 22, 3)

      assert thumb_offsets(BookDetailFa) == [off],
             "the نسخه‌ای که دارم switch is drawn on for a book nobody said they own"
    end

    test "the hero's line is the shelf's line, and the pace is the sittings' own" do
      # One book, one sentence, on board 176 and board 69 — through
      # `Kati.Screens.BooksFa.line/1` rather than a second implementation of it,
      # which is the drift `Kati.Screens.Books.rail/2` exists to have ended.
      #
      # For the two statuses `line/1` answers with a WORD rather than a
      # position, the two boards part on purpose: a jacket has no pill and this
      # card does. `the pill says the status, and the line under it does not say
      # it again` below is that half.
      book =
        a_book!(%{
          title: @prefix <> "سالنامه",
          status: :reading,
          page_count: 380,
          current_page: 214
        })

      assert BookDetailFa.book().progress_line == "ص. ۲۱۴ / ۳۸۰"
      assert tile_line(book.title) == "ص. ۲۱۴ / ۳۸۰"

      # `pace/2` is minutes across the last seven calendar days ÷ 7, so 161
      # minutes today is 23 a day — the figure board 69 prints.
      a_session!(book, %{read_on: Kati.Time.today(), from_page: 168, to_page: 214, minutes: 161})

      assert BookDetailFa.book().progress_line == "ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز"
    end

    test "a book with no page count draws no bar, and a page count is what brings one back" do
      # `Kati.Books.Book.fraction/1` answers `nil` rather than `0.0` precisely so
      # this page can decline to draw: a bar pinned at zero claims you have read
      # none of a book whose length nobody knows.
      book = a_book!(%{title: @prefix <> "کتاب صوتی", format: :audiobook, duration_minutes: 680})

      assert BookDetailFa.book().progress == nil
      assert BookDetailFa.bar(BookDetailFa.book().progress) == []

      Ash.update!(book, %{format: :paperback, page_count: 380, current_page: 0})

      assert BookDetailFa.book().progress == 0.0
      refute BookDetailFa.bar(BookDetailFa.book().progress) == []
    end

    test "the rating is the book's own, in Persian digits with the Persian separator" do
      book = a_book!(%{title: @prefix <> "سالنامه"})

      assert BookDetailFa.book().rating == nil
      assert BookDetailFa.book().rating_label == nil

      book = Ash.update!(book, %{rating: 9})

      assert BookDetailFa.book().rating == 9
      assert BookDetailFa.book().rating_label == "۴٫۵"
      refute BookDetailFa.book().rating_label == "4.5"

      Ash.update!(book, %{rating: 8})
      assert BookDetailFa.book().rating_label == "۴"
    end

    test "the series band and the lending band are the book's own, or are absent" do
      book = a_book!(%{title: @prefix <> "سالنامه"})

      assert BookDetailFa.series(BookDetailFa.book()) == []

      Ash.update!(book, %{
        series_name: "دفترهای ساحلی",
        series_position: 3,
        series_total: 7,
        lent_to: "جو",
        lent_due_on: ~D[2025-08-27]
      })

      page = BookDetailFa.book()

      assert page.series_line == "#۳ از ۷ — دفترهای ساحلی"
      assert page.lent_to == "قرض داده به جو"
      assert page.lent_due == "موعد " <> Shamsi.format(~D[2025-08-27], :short)
      refute page.lent_due =~ ~r/[0-9]/

      words = words_of(BookDetailFa)
      assert words =~ SampleFa.eyebrows().series
      assert words =~ "#۳ از ۷ — دفترهای ساحلی"
      assert words =~ "قرض داده به جو"
    end

    test "owning a book is drawn as the switch, and never as a row saying Owned" do
      # 66 puts a standalone `Owned` row in this band. Persian for it exists on
      # no board, rule 6 forbids inventing it, and this page already draws the
      # fact as the نسخه‌ای که دارم switch — so the band stays closed.
      a_book!(%{title: @prefix <> "سالنامه", owned: true})

      assert BookDetailFa.book().lent_to == nil
      assert BookDetailFa.series(BookDetailFa.book()) == []
      refute words_of(BookDetailFa) =~ SampleFa.eyebrows().series
    end
  end

  describe "the notes and the sittings are the reader's, in Persian" do
    test "a book's own notes are drawn, worded in Persian, with the body untouched" do
      book = a_book!(%{title: @prefix <> "سالنامه"})
      a_note!(book, %{kind: :quote, body: "a line the reader typed", page: 148})

      words = words_of(BookDetailFa)

      assert words =~ SampleFa.eyebrows().notes
      assert words =~ "a line the reader typed", "a note's body is never translated"
      assert words =~ "ص. ۱۴۸"
      refute words =~ "p. 148", "`Kati.Books.Note.anchor/1` answers in English"
      refute words =~ "«جزر و مد دفتر خودش را نگه می‌دارد.»", "and the fixture's notes are gone"
    end

    test "a note about a book rather than about a page draws no anchor" do
      book = a_book!(%{title: @prefix <> "سالنامه"})
      a_note!(book, %{kind: :note, body: "a thought about the whole thing", page: nil})

      assert [%{anchor: nil}] = BookDetailFa.book().notes
      assert words_of(BookDetailFa) =~ "a thought about the whole thing"
    end

    test "a book's own sittings are drawn, worded in Persian" do
      book = a_book!(%{title: @prefix <> "سالنامه"})
      a_session!(book, %{read_on: ~D[2025-08-16], from_page: 168, to_page: 214, minutes: 38})

      [session] = BookDetailFa.book().sessions

      assert session.span == "ص. ۱۶۸ → ۲۱۴"
      assert session.duration == "۳۸ دقیقه"
      # A date has a Shamsi counterpart where a bare publication year does not,
      # so this one really is converted — and it is not `16 AUG`.
      assert session.date == Shamsi.format(~D[2025-08-16], :short)
      refute session.date =~ ~r/[0-9A-Za-z]/

      words = words_of(BookDetailFa)

      assert words =~ SampleFa.eyebrows().history
      assert words =~ "ص. ۱۶۸ → ۲۱۴"
      refute words =~ "p. 168 → 214"
      refute words =~ "38m"
    end

    test "a sitting nobody timed draws its span and no duration, not the word nil" do
      # `Kati.Books.ReadingSession`'s own rule reaching a `Text`: a session with
      # no minutes is a session that happened. It is the row a person creates the
      # first time they save from screen 72 without running the timer.
      book = a_book!(%{title: @prefix <> "سالنامه"})
      a_session!(book, %{read_on: ~D[2025-08-16], from_page: 168, to_page: 214, minutes: nil})

      assert [%{duration: nil}] = BookDetailFa.book().sessions
      assert BookDetailFa.duration(nil) == nil

      texts =
        BookDetailFa
        |> mount_screen()
        |> Mob.ScreenCase.flatten()
        |> Enum.filter(&(&1.type == :text))

      refute Enum.any?(texts, &(Map.get(&1.props || %{}, :text) == nil))
      assert words_of(BookDetailFa) =~ "ص. ۱۶۸ → ۲۱۴"
    end
  end

  describe "with nothing shelved the page is still the drawing" do
    test "the reader answers with the fixture, and every band of board 69 draws" do
      # The regression the whole change is balanced on, asserted locally so a
      # break is attributed here rather than three files away.
      # `Kati.ScreenEmptyDatabaseTest` makes the same equality for screen 69 and
      # `Kati.ScreenDesignLiteralTest` compares the rendered tree against every
      # literal of `test/design/screens/69.html`.
      assert BookDetailFa.book() == BookDetailFa.drawn_book()
      assert BookDetailFa.book() == SampleFa.detail()

      words = words_of(BookDetailFa)

      for eyebrow <- Map.values(SampleFa.eyebrows()) do
        assert words =~ eyebrow, "board 69 draws #{eyebrow} and the fixture path must too"
      end

      assert words =~ "۱۴۰۳ · ۳۸۰ صفحه"
      assert words =~ "ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز"
      assert words =~ "4.5"
      assert words =~ "#۳ از ۷ — دفترهای ساحلی"
      assert words =~ "قرض داده به جو"
      assert words =~ "موعد ۵ شهریور"
      assert words =~ "«جزر و مد دفتر خودش را نگه می‌دارد.»"
      assert words =~ "ص. ۱۴۸"
      assert words =~ "۳۸ دقیقه"

      # `warning_count` moved from the string `"۳"` to the integer `3`, and
      # `Kati.Calendar.Shamsi.fa/1` is what puts the board's own glyph back.
      assert SampleFa.detail().warning_count == 3
      assert words =~ "۳"
    end

    test "one shelved book moves the page, and the drawing does not move with it" do
      # So the two nothings can never agree vacuously.
      drawn = BookDetailFa.drawn_book()

      a_book!(%{title: @prefix <> "نگهبان"})

      refute BookDetailFa.book() == drawn
      assert BookDetailFa.drawn_book() == drawn
    end
  end

  describe "the page is about the book the cover carried" do
    test "a named book is drawn whole, and the head of the shelf is nowhere on it" do
      # The defect, in the state a device finds it in. Shelve the rich book
      # first and a bare one second, so the bare one is `updated_at` newest and
      # IS the shelf's head — then open the page on the rich one, which is what
      # board 176's second-through-sixth covers do.
      #
      # Before this, `mount/3` matched `_params` and answered with the head. It
      # cost one wrong string while `own/1` named five keys; with `own/3` total
      # over twenty-two it cost the whole page, which is `D-59`'s acceptance
      # sentence failing literally: *never a page filled in with somebody
      # else's reading*.
      salt =
        a_book!(%{
          title: @prefix <> "سالنامه",
          status: :reading,
          page_count: 380,
          current_page: 214,
          rating: 9,
          isbn: "978-0-571-33915-2",
          series_name: "دفترهای ساحلی",
          series_position: 3,
          series_total: 7,
          lent_to: "جو"
        })

      a_note!(salt, %{kind: :quote, body: "a line the reader typed", page: 148})
      head = a_book!(%{title: @prefix <> "علف مرام"})

      assert BookDetailFa.shelved(nil).id == head.id, "the bare page would draw this one"

      page = BookDetailFa.book(salt.id)

      assert page.id == salt.id
      assert page.title == salt.title
      assert page.status_label == "در حال خواندن"
      assert page.rating_label == "۴٫۵"
      assert page.isbn == "978-0-571-33915-2"
      assert page.series_line == "#۳ از ۷ — دفترهای ساحلی"
      assert page.lent_to == "قرض داده به جو"

      words = words_of(BookDetailFa, %{book_id: salt.id})

      assert words =~ salt.title
      refute words =~ head.title, "screen 69 drew the head of the shelf under a named book"
      assert words =~ "a line the reader typed"

      # And the other direction: opened on the bare book, the page is empty
      # where the app knows nothing rather than filled in with the rich one's.
      bare = words_of(BookDetailFa, %{book_id: head.id})

      assert bare =~ head.title
      refute bare =~ salt.title
      refute bare =~ "#۳ از ۷ — دفترهای ساحلی"
      refute bare =~ "a line the reader typed"
    end

    test "an id that names no row draws the drawing, and never somebody else's book" do
      # `Kati.Screens.BookDetail.shelved_book/1`'s rule, mirrored: a row deleted
      # under you is not the same fact as an empty shelf, and substituting the
      # head is the swap this reader exists to prevent.
      shelved = a_book!(%{title: @prefix <> "نگهبان"})
      dead = a_book!(%{title: @prefix <> "آب کم"})
      Ash.destroy!(dead)

      assert BookDetailFa.book(dead.id) == BookDetailFa.drawn_book()
      refute words_of(BookDetailFa, %{book_id: dead.id}) =~ shelved.title
    end

    test "no id is still the shelf's head, which is what a page opened from nowhere is about" do
      book = a_book!(%{title: @prefix <> "نگهبان"})

      assert BookDetailFa.book(nil) == BookDetailFa.book()
      assert BookDetailFa.book().title == book.title
    end
  end

  describe "the controls write to the book the page drew" do
    test "a status chip writes that book, leaves the other alone, and the page re-reads" do
      # `D-59` made the chips honest — they draw `b.status` instead of asserting
      # `:reading` — and an honest chip that cannot act is the control the brief
      # calls worse than no control. Screen 66's own writer does the work, so
      # the two pages cannot mean different things by one chip.
      first = a_book!(%{title: @prefix <> "سالنامه", status: :reading})
      second = a_book!(%{title: @prefix <> "علف مرام", status: :reading})

      view =
        BookDetailFa
        |> mount_screen(%{book_id: first.id})
        |> render_info({:tap, :status_paused})

      assert Ash.get!(Book, first.id).status == :paused
      assert Ash.get!(Book, second.id).status == :reading, "a chip moved a book off the page"

      # The re-read, and not an assign of the chip alone: the pill is derived
      # from the row and would otherwise disagree with the chip just pressed.
      assert assigns(view).book.status == :paused
      assert assigns(view).book.status_label == "متوقف"
      assert assigns(view).book.id == first.id
    end

    test "a format chip is the same write, and it moves the row the page is on" do
      book = a_book!(%{title: @prefix <> "کتاب صوتی", duration_minutes: 680})

      BookDetailFa
      |> mount_screen(%{book_id: book.id})
      |> render_info({:tap, :format_audiobook})

      assert Ash.get!(Book, book.id).format == :audiobook
    end

    test "تمام شد finishes the book the page is on and not the head of the shelf" do
      first = a_book!(%{title: @prefix <> "سالنامه", status: :reading})
      second = a_book!(%{title: @prefix <> "علف مرام", status: :reading})

      view =
        BookDetailFa
        |> mount_screen(%{book_id: first.id})
        |> render_info({:tap, :finish})

      assert navigated_to(view) == Kati.Screens.Rating
      assert Ash.get!(Book, first.id).status == :finished
      assert Ash.get!(Book, second.id).status == :reading
    end

    test "a page drawing the drawing writes nothing, with a full shelf behind it" do
      # The exposure `target/1` closes, and the reason it is a guard rather than
      # a trust in `finish_book/1`: `finish_book(nil)` and `apply_change(nil, …)`
      # both mean *the shelf's newest*. Two ways to reach that `nil` while books
      # are shelved — an id that names no row, and `shelved/1`'s rescue on a
      # store it could not reach — and in both the page is drawing the fixture
      # over a real shelf. `Kati.ScreenWriteTargetTest` sweeps for exactly this
      # with no domain knowledge; this is the same claim, named.
      dead = a_book!(%{title: @prefix <> "آب کم"})
      Ash.destroy!(dead)

      head = a_book!(%{title: @prefix <> "سالنامه", status: :reading, format: :paperback})

      view = mount_screen(BookDetailFa, %{book_id: dead.id})

      assert assigns(view).book == BookDetailFa.drawn_book()

      for tag <- [:finish, :status_finished, :status_paused, :format_audiobook] do
        render_info(view, {:tap, tag})
      end

      reread = Ash.get!(Book, head.id)

      assert reread.status == :reading, "a page drawing the fixture wrote to the shelf's head"
      assert reread.format == :paperback
    end
  end

  describe "one fact is said once" do
    test "the pill says the status, and the line under it does not say it again" do
      # Finding 1 of `D-59`'s review. `Kati.Screens.BooksFa.line/1` answers with
      # the STATUS WORD for the two statuses that have one, because a jacket in
      # a grid has no pill. This card has a pill nine points above, and a
      # hand-typed book drew شروع نشده twice on one card.
      book = a_book!(%{title: @prefix <> "نگهبان"})

      assert BookDetailFa.book().progress_line == ""
      assert BookDetailFa.pace_line(BookDetailFa.book().progress_line) == []

      words = words_of(BookDetailFa)
      occurrences = length(String.split(words, "شروع نشده")) - 1

      assert occurrences == 1,
             "شروع نشده is drawn #{occurrences} times on one card — the pill and the line " <>
               "under it are saying one fact twice"

      # The sharper half: for a finished book the two disagree in SPELLING —
      # `Kati.Books.SampleFa.statuses/0` writes تمام شد and `BooksFa.line/1`
      # writes تمام‌شده with a ZWNJ — so the card called one state two things.
      Ash.update!(book, %{status: :finished, page_count: 380, current_page: 380})

      assert BookDetailFa.book().progress_line == ""

      refute words_of(BookDetailFa) =~ "تمام‌شده",
             "the hero drew the shelf's spelling of finished under a pill that says another"
    end

    test "a book with a position still draws it, and the pace still joins it" do
      # The half that must not be lost: suppressing the status word is not
      # suppressing the line. Board 69 draws `ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز`.
      book =
        a_book!(%{
          title: @prefix <> "سالنامه",
          status: :reading,
          page_count: 380,
          current_page: 214
        })

      assert BookDetailFa.book().progress_line == "ص. ۲۱۴ / ۳۸۰"

      a_session!(book, %{read_on: Kati.Time.today(), from_page: 168, to_page: 214, minutes: 161})

      assert BookDetailFa.book().progress_line == "ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز"

      # And a pace outlives a dropped position: a book finished this morning was
      # read for twenty-three minutes a day, which is not the pill's fact.
      Ash.update!(book, %{status: :finished})

      assert BookDetailFa.book().progress_line == "۲۳ دقیقه در روز"
    end

    test "an audiobook's duration is never drawn under a row labelled تعداد صفحه" do
      # Finding 9. `extent_label/1` answers `۱۱ ساعت ۲۰ دقیقه`, board 69's row
      # is labelled *number of pages*, and screen 177 offers صوتی — so the
      # moment the format chip stopped asserting `:paperback` this row could
      # present a duration as a page count. Screen 66 escapes it by calling the
      # row `Length`; rule 6 forbids inventing the Persian for that here.
      book =
        a_book!(%{title: @prefix <> "کتاب صوتی", format: :audiobook, duration_minutes: 680})

      l = SampleFa.labels()
      words = words_of(BookDetailFa)

      assert BookDetailFa.book().extent_label == "۱۱ ساعت ۲۰ دقیقه"
      assert BookDetailFa.length_row(l.length, BookDetailFa.book()) == []
      refute words =~ l.length, "تعداد صفحه captioned a duration"

      # Nothing is lost: the meta line under the cover carries it, where no
      # label contradicts it.
      assert words =~ "۱۱ ساعت ۲۰ دقیقه"

      # And a paperback keeps its row, value or no value.
      Ash.update!(book, %{format: :paperback, page_count: 380, duration_minutes: nil})

      assert words_of(BookDetailFa) =~ l.length
      assert BookDetailFa.book().extent_label == "۳۸۰ صفحه"
    end

    test "the page count and the ISBN answer the same absence the same way" do
      # Findings 11 and 16: `own/3` substituted an em dash for a missing ISBN,
      # so a book typed on 177 drew تعداد صفحه blank and `ISBN —` directly under
      # it — two answers to one question, on one card, and `edition/1`'s own doc
      # described the other one.
      a_book!(%{title: @prefix <> "نگهبان"})

      page = BookDetailFa.book()

      assert page.extent_label == nil
      assert page.isbn == nil

      dashes = length(String.split(words_of(BookDetailFa), "—")) - 1

      assert dashes == 2,
             "the em dashes on this page are the two rating cards' (`rating_card/3` draws " <>
               "`value || \"—\"` and nobody has rated this book) — a third is the ISBN row " <>
               "answering an absence its neighbour answers with silence"
    end
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  # Every string the mounted screen draws, joined — the question is what a
  # person reads, not which node it came from. The params are how this file
  # asks the question `D-59` is about: *which book is this page about*.
  defp words_of(module, params \\ %{}),
    do: module |> mount_screen(params) |> Mob.ScreenCase.text()

  # A chip is lit when its label is drawn bold — and the SIZE is what says it is
  # a chip. `chip/3` draws at 12 and `status_pill/2` at 11, and without that
  # second prop this helper matched the pill: the pill's text is the status word
  # in bold, so `lit?(BookDetailFa, "متوقف")` passed for a paused book whether
  # or not `chips/3` ever passed `on? == true`. Breaking `chips/3` to light
  # nothing left this green, which is the assertion answering a question it was
  # not asked.
  defp lit?(module, label) do
    module
    |> mount_screen()
    |> Mob.ScreenCase.find(:text, text: label, text_size: 12, font_weight: "bold")
    |> is_map()
  end

  # Every drawn switch thumb on the page, as its signed offset from the track's
  # centre: negative is off, positive is on.
  defp thumb_offsets(module) do
    module
    |> mount_screen()
    |> Mob.ScreenCase.flatten()
    |> Enum.map(&Map.get(Map.get(&1, :props) || %{}, :offset_x))
    |> Enum.reject(&is_nil/1)
  end

  # This book's caption on board 176's grid, which must be the same sentence
  # board 69's hero draws.
  defp tile_line(title) do
    BooksFa.page().books
    |> Enum.find(%{}, &(Map.get(&1, :title) == title))
    |> Map.get(:line)
  end

  defp a_book!(attrs), do: Ash.create!(Book, Map.merge(%{title: @prefix <> "A book"}, attrs))

  defp a_note!(book, attrs),
    do: Ash.create!(Note, Map.merge(%{book_id: book.id, body: "a note"}, attrs))

  defp a_session!(book, attrs),
    do:
      Ash.create!(
        ReadingSession,
        Map.merge(
          %{book_id: book.id, read_on: Kati.Time.today(), from_page: 0, to_page: 1},
          attrs
        )
      )

  # Raw SQL because this also runs from `on_exit`, after the test process is
  # gone. Children first: the foreign key refuses the parent delete otherwise.
  defp delete_rows! do
    for table <- ~w(book_reading_sessions book_notes) do
      Kati.Repo.query!(
        "DELETE FROM #{table} WHERE book_id IN (SELECT id FROM books WHERE title LIKE ?1)",
        [@prefix <> "%"]
      )
    end

    Kati.Repo.query!("DELETE FROM books WHERE title LIKE ?1", [@prefix <> "%"])
  end
end
