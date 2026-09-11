defmodule Kati.ScreenLogProgressPersianTest do
  @moduledoc """
  Board 72 states no fact about a sitting that nobody has sat.

  ## The defect, one screen on from the one `D-59` was written about

  `D-59` closed the merge on screen 69 and left the identical one live on the
  sheet 69's primary button opens. `Kati.Screens.LogProgressFa.sheet/1` was
  `Map.merge(Kati.Books.SampleFa.sheet(), own(shelved))` over an `own/1` that
  named a title and a cover seed, and `Map.merge/2` keeps every key the right
  map does not name. So a book typed on board 177 a minute ago — status *not
  started*, no page count, no sitting ever logged — opened a sheet that said, in
  the reader's own language and under the reader's own title:

    * **ص. ۲۱۴ از ۳۸۰**, a position in a book with no page count;
    * a stepper proposing **۲۶۰**, which is a page that does not exist;
    * **۰۰:۳۸:۱۲** on a timer nothing had started;
    * and *یعنی ۴۶ صفحه در **۳۸ دقیقه** — سریع‌ترین این هفته*.

  ## Why this file is about screen 70 now

  mishka-group/kati#103 folded that mirror away: board 72 is
  `Kati.Screens.LogProgress` rendered under `:fa`. The four claims above are
  still the subject, and the fold had to carry the ruling across rather than
  reverse it — screen 70's own insight card read *in 38 minutes · your fastest
  this week* over every book on every device, which is the SAME defect the
  mirror had already refused to have. A fold that handed a Persian reader back
  a lie their own page had stopped telling would be the worst possible outcome
  of tidying two files into one, so `duration_runs/2` answers `[]` and both
  boards lost the clause together.

  ## What this file asks

  Every value the sheet draws for a named book is that book's or is chrome; the
  numbers are in the reader's own numerals; and the sheet writes the session
  from the page it drew. The one thing it no longer asks is that two modules
  agree, because there is one.

  ## Why every row is prefixed and deleted, on both sides

  The suite has no Ecto sandbox and the design sweeps render these screens
  against this same shared SQLite file. A book left behind here fails a file
  this one never touched, so the rows go before the test as well as after it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Books.Book
  alias Kati.Books.ReadingSession
  alias Kati.Screens.LogProgress

  @prefix "screen-72-fa-test-"

  # No locale restore in `on_exit`: `Mob.ScreenCase` tears `Mob.State` down with
  # the test process, so a write there exits. The store is per-test anyway —
  # `Kati.ScreenMyServicesPersianTest` records the same thing for the same
  # reason.
  setup do
    delete_rows!()
    Kati.Locale.put(:fa)
    Kati.Locale.activate()

    on_exit(&delete_rows!/0)

    :ok
  end

  describe "a book that carries nothing" do
    test "not one of the fixture's claims survives onto a hand-typed book's sheet" do
      book = a_book!(%{title: @prefix <> "نگهبان"})

      words = words_of(%{book_id: book.id})

      # Every claim the merge used to carry through, named one at a time
      # because each was its own sentence to a reader. The fixture's are the
      # drawing's numbers in Persian: page 214 of 380, a 38-minute sitting, and
      # a stepper already stepped up to 260.
      for claim <- ["ص. ۲۱۴ از ۳۸۰", "۰۰:۳۸:۱۲", "۳۸ دقیقه", "سریع‌ترین این هفته", "۲۶۰"] do
        refute words =~ claim,
               "board 72 drew `#{claim}` for a book nobody has read a page of"
      end

      assert words =~ book.title, "and it drew the one thing it was given"
    end

    test "the stepper opens on the book's own page and not on the drawing's ۲۶۰" do
      # `۲۶۰` is not a default — `Kati.Screens.LogProgress.starting_page/1` says
      # so — it is the drawing's number after somebody stepped it up forty-six
      # times. Proposed over a book at page 0 it is a page that does not exist.
      book = a_book!(%{title: @prefix <> "سالنامه", page_count: 380, current_page: 214})

      assert assigns(mount_screen(LogProgress, %{book_id: book.id})).page == 214

      bare = a_book!(%{title: @prefix <> "نگهبان"})

      assert assigns(mount_screen(LogProgress, %{book_id: bare.id})).page == 0
    end

    test "the insight card claims a delta and nothing else" do
      # Three clauses, and only the first was ever this reader's. Nothing in the
      # app has timed a session — `:stop_timer` is on `Kati.ScreenTapSweepTest`'s
      # inert list in both scripts — so an elapsed figure is a clock that never
      # ran and *سریع‌ترین این هفته* is a comparison against a week of sittings
      # nobody read.
      assert LogProgress.duration_runs([], []) == []

      book = a_book!(%{title: @prefix <> "نگهبان"})

      words =
        LogProgress
        |> mount_screen(%{book_id: book.id})
        |> render_info({:tap, :step_up})
        |> Mob.ScreenCase.text()

      assert words =~ "۱ صفحه", "the delta the reader just made is the one real number"

      # `دقیقه` on its own is the third unit segment and is chrome; what may
      # not appear is a DURATION, which is that word with a number in front of
      # it.
      refute words =~ "۳۸ دقیقه"
      refute words =~ "سریع‌ترین"
    end

    test "no Text on the sheet is drawn with a nil" do
      # The question `Kati.ScreenNilTextTest` cannot ask of this screen: its
      # sweep renders an empty database, and this sheet answers that with a
      # complete fixture. `text={nil}` is the word **nil** in Vazirmatn.
      book = a_book!(%{title: @prefix <> "نگهبان"})

      nils =
        LogProgress
        |> mount_screen(%{book_id: book.id})
        |> Mob.ScreenCase.flatten()
        |> Enum.filter(&(&1.type == :text and Map.get(&1.props || %{}, :text) == nil))

      assert nils == [], "board 72 hands `text=` a nil: #{inspect(Enum.map(nils, & &1.props))}"
    end
  end

  describe "the position line is the board's sentence with this book's numerals in it" do
    test "a book with a page count reads ص. ۲۱۴ از ۳۸۰, in the board's own words" do
      book = a_book!(%{title: @prefix <> "سالنامه", page_count: 380, current_page: 214})

      assert LogProgress.position_line(shaped(book)) == "ص. ۲۱۴ از ۳۸۰"
      assert words_of(%{book_id: book.id}) =~ "ص. ۲۱۴ از ۳۸۰"

      # از and not `/`: this board's sentence, where `Kati.Screens.BooksFa.line/1`
      # writes the shelf's. Each is right where it is drawn. It was read back
      # out of `progress_line` with `Regex.run(~r/^p\. (\d+) \/ (\d+)/, …)`
      # until #103, and that regex matches nothing here — see
      # `Kati.Screens.BookDetail.shaped/3` on the two integers that replaced it.
      refute LogProgress.position_line(shaped(book)) =~ "/"
    end

    test "a book with no page count reaches the page it reached, and names no total" do
      book = a_book!(%{title: @prefix <> "بی‌شمار", page_count: nil, current_page: 12})

      assert LogProgress.position_line(shaped(book)) == "ص. ۱۲"
      refute LogProgress.position_line(shaped(book)) =~ "از"
    end

    test "no numeral on the sheet is drawn in a face that cannot render it" do
      # `kati_mono.ttf` carries none of U+06F0–U+06F9, which is
      # `Kati.Screens.Fa`'s second type rule — so a Persian digit outside the
      # `fa` face is drawn by whatever the platform falls back to. The root
      # declares the face since `K-48 locale-face`, so a node with none is
      # correct and a node naming `mono` is not.
      book = a_book!(%{title: @prefix <> "سالنامه", page_count: 380, current_page: 214})

      wrong =
        LogProgress
        |> mount_screen(%{book_id: book.id})
        |> Mob.ScreenCase.flatten()
        |> Enum.filter(fn node ->
          props = node.props || %{}
          text = Map.get(props, :text)

          is_binary(text) and text =~ ~r/[\x{06F0}-\x{06F9}]/u and
            Map.get(props, :font_family) == "mono"
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

      LogProgress
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
      words = words_of()

      for literal <- ["ثبت پیشرفت", "ص. ۲۱۴ از ۳۸۰", "۲۶۰", "اکنون در صفحه", "صفحه"] do
        assert words =~ literal, "board 72 draws #{literal} and the fixture path must too"
      end

      assert assigns(mount_screen(LogProgress)).page == 260
    end

    test "an id that names no row answers with the drawing, never with the shelf's head" do
      shelved = a_book!(%{title: @prefix <> "سالنامه"})
      dead = a_book!(%{title: @prefix <> "آب کم"})
      Ash.destroy!(dead)

      refute words_of(%{book_id: dead.id}) =~ shelved.title
    end
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  defp words_of(params \\ %{}),
    do: LogProgress |> mount_screen(params) |> Mob.ScreenCase.text()

  defp shaped(book), do: Kati.Screens.BookDetail.shelved_book(book.id)

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
