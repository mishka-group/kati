defmodule Kati.ScreenLogProgressFaTest do
  @moduledoc """
  Screen 72 states no fact about a sitting that nobody has sat.

  ## The defect, one screen on from the one `D-59` was written about

  `D-59` closed the merge on screen 69 and left the identical one live on the
  sheet 69's primary button opens. `sheet/1` was
  `Map.merge(Kati.Books.SampleFa.sheet(), own(shelved))` over an `own/1` that
  named a title and a cover seed, and `Map.merge/2` keeps every key the right
  map does not name. So a book typed on board 177 a minute ago — status *not
  started*, no page count, no sitting ever logged — opened a sheet that said, in
  the reader's own language and under the reader's own title:

    * **ص. ۲۱۴ از ۳۸۰**, a position in a book with no page count;
    * a stepper proposing **۲۶۰**, which is a page that does not exist;
    * **۰۰:۳۸:۱۲** on a timer nothing had started;
    * **شروع در ۲۱:۰۲**, whatever time it actually was;
    * and *یعنی ۴۶ صفحه در ۳۸ دقیقه — **سریع‌ترین این هفته***.

  Screen 20's rule, which the whole ticket enforces on 69, was broken on 72 by
  one line of code — and 69's own fixed primary action was the door to it.

  ## What this file asks

  The same three questions the screen-69 file asks, on the sheet: every value
  the sheet draws for a named book is that book's or is chrome, no band that
  has nothing to say says anything, and the drawing is still exactly the drawing
  when nothing is shelved — which is the state `Kati.ScreenDesignLiteralTest`
  and `Kati.ScreenEmptyDatabaseTest` render 72 in.

  ## Why every row is prefixed and deleted, on both sides

  `Kati.ScreenBookDetailFaTest`'s discipline and its reason: the suite has no
  Ecto sandbox and the design sweeps render these screens against this same
  shared SQLite file. A book left behind here fails a file this one never
  touched, so the rows go before the test as well as after it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Books.Book
  alias Kati.Books.ReadingSession
  alias Kati.Books.SampleFa
  alias Kati.Screens.LogProgressFa

  @prefix "screen-72-fa-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  describe "a book that carries nothing" do
    test "not one of the fixture's claims survives onto a hand-typed book's sheet" do
      book = a_book!(%{title: @prefix <> "نگهبان"})

      sheet = LogProgressFa.sheet(book.id)
      drawn = SampleFa.sheet()

      assert sheet.book == book.title
      assert sheet.seed == book.cover_seed

      # Every claim the merge used to carry through, named one at a time
      # because each was its own sentence to a reader.
      refute sheet.position == drawn.position
      assert sheet.timer == nil
      assert sheet.started_at == nil
      assert sheet.insight_pages == nil
      assert sheet.insight_minutes == nil
      assert sheet.insight_tail == nil

      words = words_of(%{book_id: book.id})

      # `drawn.stop` is NOT on this list, and the reason is worth a sentence
      # because it read like an omission. توقف is the timer's own button label
      # — chrome, in `own/1`'s vocabulary, a Persian word Kati wrote rather
      # than a claim about a book — and it is also a substring of ذخیره و توقف,
      # the commit label this same test asserts must still be drawn two lines
      # below. Forbidding it and requiring it are the same assertion twice with
      # opposite signs, and the one that is right is the requirement.
      for claim <- [
            drawn.position,
            drawn.timer,
            drawn.started_at,
            drawn.started_label,
            drawn.insight_pages,
            drawn.insight_minutes,
            drawn.insight_tail
          ] do
        refute words =~ claim,
               "screen 72 drew `#{claim}` for a book nobody has read a page of"
      end

      assert words =~ book.title, "and it drew the one thing it was given"
      assert words =~ drawn.commit, "and the button that saves is still there"
    end

    test "the stepper opens on the book's own page and not on the drawing's ۲۶۰" do
      # `۲۶۰` is not a default — `Kati.Screens.LogProgress.starting_page/1` says
      # so — it is the drawing's number after somebody stepped it up forty-six
      # times. Proposed over a book at page 0 it is a page that does not exist.
      book = a_book!(%{title: @prefix <> "سالنامه", page_count: 380, current_page: 214})

      assert assigns(mount_screen(LogProgressFa, %{book_id: book.id})).page == 214

      bare = a_book!(%{title: @prefix <> "نگهبان"})

      assert assigns(mount_screen(LogProgressFa, %{book_id: bare.id})).page == 0
    end

    test "an untimed sheet draws no timer, no start time and no insight card" do
      # Three bands that can only be true of a sitting somebody is in the middle
      # of timing. Nothing in `lib/` starts a Persian timer — `:stop_timer` is
      # on `Kati.ScreenTapSweepTest`'s inert list — so an elapsed face over a
      # real book is a clock that never ran, and توقف beside it is a control
      # that cannot act.
      book = a_book!(%{title: @prefix <> "نگهبان"})
      sheet = LogProgressFa.sheet(book.id)

      assert LogProgressFa.timer(sheet) == []
      assert LogProgressFa.timing(sheet) == []
      assert LogProgressFa.insight(sheet) == []

      # And the gaps went with them: every band carries its own leading Spacer,
      # so what is left is a shorter sheet rather than a 56pt hole where three
      # cards used to be.
      refute LogProgressFa.commit(sheet.commit) == []
    end

    test "no Text on the sheet is drawn with a nil" do
      # The question `Kati.ScreenNilTextTest` cannot ask of this screen: its
      # sweep renders an empty database, and this sheet answers that with a
      # complete fixture. `text={nil}` is the word **nil** in Vazirmatn.
      book = a_book!(%{title: @prefix <> "نگهبان"})

      nils =
        LogProgressFa
        |> mount_screen(%{book_id: book.id})
        |> Mob.ScreenCase.flatten()
        |> Enum.filter(&(&1.type == :text and Map.get(&1.props || %{}, :text) == nil))

      assert nils == [], "screen 72 hands `text=` a nil: #{inspect(Enum.map(nils, & &1.props))}"
    end
  end

  describe "the position line is the board's sentence with this book's numerals in it" do
    test "a book with a page count reads ص. ۲۱۴ از ۳۸۰, in the board's own words" do
      book = a_book!(%{title: @prefix <> "سالنامه", page_count: 380, current_page: 214})

      assert LogProgressFa.sheet(book.id).position == "ص. ۲۱۴ از ۳۸۰"
      assert words_of(%{book_id: book.id}) =~ "ص. ۲۱۴ از ۳۸۰"

      # از and not `/`: this board's sentence, where `Kati.Screens.BooksFa.line/1`
      # writes the shelf's. Each is right where it is drawn.
      refute LogProgressFa.sheet(book.id).position == "ص. ۲۱۴ / ۳۸۰"
    end

    test "a book with no page count reaches the page it reached, and names no total" do
      book = a_book!(%{title: @prefix <> "بی‌شمار", page_count: nil, current_page: 12})

      assert LogProgressFa.sheet(book.id).position == "ص. ۱۲"
      refute LogProgressFa.sheet(book.id).position =~ "از"
    end

    test "an audiobook is not on a page at all, so the line goes with the number" do
      # This test used to BE the one above, with an audiobook standing in for a
      # book with no page count — and it asserted `ص. ۰`, which is the defect
      # rather than the behaviour: *page 0*, under a stepper labelled اکنون در
      # صفحه, on a book this app measures in hours. Screen 69 already refuses
      # to say it — `length_row/2` draws nothing for an audiobook rather than
      # putting a duration under تعداد صفحه — and the two pages have to agree
      # about what a recording's position is, which is that there isn't one.
      book = a_book!(%{title: @prefix <> "کتاب صوتی", format: :audiobook, duration_minutes: 680})

      refute LogProgressFa.sheet(book.id).position,
             "screen 72 put an audiobook on a page number"

      words = words_of(%{book_id: book.id})

      refute words =~ "ص. ",
             "the position line was dropped from the sheet but drawn anyway"
    end

    test "no numeral on the sheet is drawn in a face that cannot render it" do
      # `kati_mono.ttf` carries none of U+06F0–U+06F9, which is
      # `Kati.Screens.Fa`'s second type rule — so a Persian digit outside the
      # `fa` face is drawn by whatever the platform falls back to.
      book = a_book!(%{title: @prefix <> "سالنامه", page_count: 380, current_page: 214})

      wrong =
        LogProgressFa
        |> mount_screen(%{book_id: book.id})
        |> Mob.ScreenCase.flatten()
        |> Enum.filter(fn node ->
          props = node.props || %{}
          text = Map.get(props, :text)

          is_binary(text) and text =~ ~r/[\x{06F0}-\x{06F9}]/u and
            Map.get(props, :font_family) != "fa"
        end)

      assert wrong == [], inspect(Enum.map(wrong, & &1.props))
    end
  end

  describe "the sheet writes what it drew" do
    test "saving logs the session from the page the sheet said you were on" do
      # The whole point of the stepper opening on the book's own page: the
      # session's `from_page` is where the sheet said you were, so a book at
      # page 0 cannot record a forty-six-page sitting nobody read.
      book = a_book!(%{title: @prefix <> "نگهبان"})

      LogProgressFa
      |> mount_screen(%{book_id: book.id})
      |> render_info({:tap, :step_up})
      |> render_info({:tap, :step_up})
      |> render_info({:tap, :save})

      assert [session] = sessions_of(book)
      assert session.from_page == 0
      assert session.to_page == 2
      assert Ash.get!(Book, book.id).current_page == 2
    end
  end

  describe "with nothing shelved the sheet is still the drawing" do
    test "the reader answers with the fixture, and every band of board 72 draws" do
      # The regression the whole change is balanced on. `Kati.Screens.Gallery`
      # pushes this screen with no params, and that is the state
      # `Kati.ScreenDesignLiteralTest` compares against the board.
      assert LogProgressFa.sheet(nil) == SampleFa.sheet()

      drawn = SampleFa.sheet()
      words = words_of()

      for literal <- [
            drawn.title,
            drawn.book,
            drawn.position,
            drawn.timer,
            drawn.stop,
            drawn.started_label,
            drawn.started_at,
            drawn.insight_lead,
            drawn.insight_pages,
            drawn.insight_middle,
            drawn.insight_minutes,
            drawn.insight_tail,
            drawn.commit
          ] do
        assert words =~ literal, "board 72 draws #{literal} and the fixture path must too"
      end

      assert assigns(mount_screen(LogProgressFa)).page == 260
    end

    test "both branches answer with the same keys, so a missing one is a KeyError" do
      # What replaced the merge, and the reason it is a complete map rather
      # than an overlay: a key that goes missing from a merge is the fixture's
      # value on a device, and a key that goes missing from this is red.
      book = a_book!(%{title: @prefix <> "نگهبان"})

      assert Map.keys(LogProgressFa.sheet(book.id)) == Map.keys(SampleFa.sheet())
    end

    test "an id that names no row answers with the drawing, never with the shelf's head" do
      shelved = a_book!(%{title: @prefix <> "سالنامه"})
      dead = a_book!(%{title: @prefix <> "آب کم"})
      Ash.destroy!(dead)

      assert LogProgressFa.sheet(dead.id) == SampleFa.sheet()
      refute words_of(%{book_id: dead.id}) =~ shelved.title
    end
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  defp words_of(params \\ %{}),
    do: LogProgressFa |> mount_screen(params) |> Mob.ScreenCase.text()

  defp a_book!(attrs), do: Ash.create!(Book, Map.merge(%{title: @prefix <> "A book"}, attrs))

  defp sessions_of(book) do
    ReadingSession
    |> Ash.Query.for_read(:for_book, %{book_id: book.id})
    |> Ash.read!()
  end

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
