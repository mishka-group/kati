defmodule Kati.BooksByHandTest do
  @moduledoc """
  A book reaches the shelf: screen 177 writes it, screen 176 draws it.

  ## What was wrong, and it was the whole of `D-38`

  Nothing in the app created a `Kati.Books.Book`. The resource's only writer
  was `Kati.Backup.Catalog`, so on a device screen 20 drew six books nobody
  owned, screen 66 fell to `Kati.Books.Sample.detail/0` under every cover, and
  every one of Phase 3's book screens could only ever be checked against its
  fixture. Three rounds ended with that sentence in the report.

  In Persian it was worse in the other direction: 57's کتاب‌ها segment had no
  shelf to open, so it pushed `Kati.Screens.BookDetailFa` and dropped the
  reader into one fixture book with no grid and no way back to a list.

  ## Why the shelf half is asserted with two books and not one

  `Kati.ScreenWriteTargetTest`'s rule, on the reading side: with one row on the
  shelf, *the row the page drew* and *the row a fresh query returns* are the
  same row, and a hero that re-queried could not be told from one that read the
  list it drew. So every shelf assertion here stores two books in known states
  and asks which one each band is about.

  ## Why every row is prefixed and deleted, on both sides

  `Kati.Screens.Books`, `Kati.Screens.BooksFa`, `Kati.Screens.BookDetail` and
  `Kati.Screens.LogProgress` all fall back to their drawings only while `books`
  is empty, and `Kati.ScreenDesignLiteralTest`, `Kati.ScreenEmptyDatabaseTest`
  and `Kati.ScreenSampleOnlyTest` render them against this same shared SQLite
  file — the suite has no Ecto sandbox. A book left behind here fails a file
  this one never touched, on the seeds that order the modules the wrong way
  round. So the rows go before the test as well as after it: an interrupted run
  leaves the table dirty, and the next run's `setup` is the only thing that can
  clear it.
  """
  use Mob.ScreenCase, async: false

  # The pure ones, as their own examples. `only:` because the rest of both
  # modules is markup and store calls, and a doctest is worth having where the
  # answer fits on the line above it.
  doctest Kati.Screens.AddByHandBook, only: [length_label: 1, extent: 2, number: 1, taken: 1]
  doctest Kati.Screens.BooksFa, only: [visible: 2]

  alias Kati.Books.Book
  alias Kati.Books.SampleFa
  alias Kati.Screens.AddByHand
  alias Kati.Screens.AddByHandBook
  alias Kati.Screens.BookDetail
  alias Kati.Screens.Books
  alias Kati.Screens.BooksFa
  alias Kati.Screens.LibraryFa

  @prefix "books-by-hand-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  describe "the door" do
    test "57's کتاب‌ها segment opens the Persian shelf, not one fixture book" do
      # The defect `D-38` names in its first paragraph: the segment pushed
      # screen 69 because no Persian shelf had been drawn.
      view =
        LibraryFa
        |> mount_screen()
        |> render_info({:tap, :shelf_1})

      assert pushed(view) == {:push, BooksFa, %{}}
    end

    test "69 is still reachable — from the shelf's covers, where a detail is reached from" do
      view =
        BooksFa
        |> mount_screen()
        |> render_info({:tap, :open_book})

      assert {:push, Kati.Screens.BookDetailFa, _params} = pushed(view)
    end

    test "176's + opens the book form, not the film search screen 06's + opens" do
      # `Kati.Screens.Fa.dock_tap/3` answers `:fab` with `Kati.Screens.AddTitle`
      # for every other Persian root, and that sheet cannot find a book. The
      # board settles it in its own empty card: اولین کتاب را با دکمه + اضافه
      # کنید.
      view =
        BooksFa
        |> mount_screen()
        |> render_info({:tap, :fab})

      assert pushed(view) == {:push, AddByHandBook, %{}}
    end

    test "the Kind chips that are another kind of the same form navigate to it" do
      for tag <- [:kind_Film, :kind_Series] do
        view =
          AddByHandBook
          |> mount_screen()
          |> render_info({:tap, tag})

        assert pushed(view) == {:push, AddByHand, %{}}
      end
    end
  end

  describe "the form writes what was typed" do
    test "a title alone is enough, and the row is there on a fresh read" do
      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:change, :title, @prefix <> "The Salt Almanac"})
        |> render_info({:tap, :add})

      refute assigns(view).save_error

      # Read from scratch rather than through the struct the write handed back:
      # the question is whether the row is in the database.
      assert [book] = shelf()
      assert book.title == @prefix <> "The Salt Almanac"
      assert book.source == :manual
      assert book.status == :not_started
      assert book.format == :paperback

      # `Add to library` lands on 66, on the row it just created and by its own
      # id — the board's own annotation, and screen 66's own builder.
      assert pushed(view) == {:push, BookDetail, %{book_id: book.id}}
    end

    test "every optional field the form offers reaches its own column" do
      AddByHandBook
      |> mount_screen()
      |> render_info({:change, :title, @prefix <> "Estuary"})
      |> render_info({:change, :author, "Ines Karvel"})
      |> render_info({:change, :year, "2024"})
      |> render_info({:change, :length, "240"})
      |> render_info({:change, :isbn, "978-0-571-33915-2"})
      |> render_info({:tap, :status_Reading})
      |> render_info({:tap, :add})

      assert [book] = shelf()
      assert book.author == "Ines Karvel"
      assert book.published_year == 2024
      assert book.page_count == 240
      assert book.isbn == "978-0-571-33915-2"
      assert book.status == :reading
    end

    test "an audiobook stores minutes and no page count, never both" do
      # `Kati.Books.Book`: storing both and showing one would let an edition
      # switch silently keep a stale figure, so `format` decides which column
      # is meaningful and only one is ever written.
      AddByHandBook
      |> mount_screen()
      |> render_info({:change, :title, @prefix <> "Low Water"})
      |> render_info({:change, :length, "680"})
      |> render_info({:tap, :edition_Audiobook})
      |> render_info({:tap, :add})

      assert [book] = shelf()
      assert book.format == :audiobook
      assert book.duration_minutes == 680
      assert book.page_count == nil
      assert Book.extent(book) == {680, :minutes}
    end

    test "the extent label follows the Edition chip, and so does the column" do
      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:change, :length, "380"})

      assert find(tree(view), :text, text: "Length · pages") != nil

      switched = render_info(view, {:tap, :edition_Audiobook})

      assert find(tree(switched), :text, text: "Length · minutes") != nil
      assert find(tree(switched), :text, text: "Length · pages") == nil
    end

    test "a blank optional field is stored as nothing, not as an empty name" do
      # `Kati.Books.Book.author` is nullable on purpose, and an empty string
      # stored is a claim that the book has an author whose name is nothing.
      AddByHandBook
      |> mount_screen()
      |> render_info({:change, :title, @prefix <> "Marram Grass"})
      |> render_info({:tap, :add})

      assert [book] = shelf()
      assert book.author == nil
      assert book.published_year == nil
      assert book.page_count == nil
      assert book.isbn == nil
      assert Book.fraction(book) == nil, "a book with no page count draws no bar"
    end
  end

  describe "a refusal is refused, and says why" do
    test "no title refuses in words and writes nothing" do
      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:tap, :add})

      assert assigns(view).save_error == "A title is the one thing this needs."
      assert shelf() == []
      refute match?({:push, _dest, _params}, pushed(view)), "a refused save leaves the form open"
    end

    test "a title of nothing but spaces is no title" do
      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:change, :title, "   "})
        |> render_info({:tap, :add})

      assert assigns(view).save_error
      assert shelf() == []
    end

    test "a book already on the shelf is refused by name, and nothing is written" do
      a_book!(%{title: @prefix <> "The Salt Almanac"})

      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:change, :title, @prefix <> "The Salt Almanac"})
        |> render_info({:tap, :add})

      assert assigns(view).save_error =~ "is already on your shelf"
      assert assigns(view).save_error =~ "Nothing was written."
      assert length(shelf()) == 1, "the second row was not written"
      refute match?({:push, _dest, _params}, pushed(view))
    end

    test "the duplicate check does not care about case or stray spaces" do
      a_book!(%{title: @prefix <> "The Salt Almanac"})

      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:change, :title, "  " <> @prefix <> "THE SALT ALMANAC  "})
        |> render_info({:tap, :add})

      assert assigns(view).save_error =~ "is already on your shelf"
      assert length(shelf()) == 1
    end

    test "a different title is not a duplicate" do
      a_book!(%{title: @prefix <> "The Salt Almanac"})

      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:change, :title, @prefix <> "Estuary"})
        |> render_info({:tap, :add})

      refute assigns(view).save_error
      assert length(shelf()) == 2
    end

    test "the button is never disabled: the same form saves once the title is typed" do
      # Board 155's rule, unchanged in shape — a dead button explains nothing.
      view =
        AddByHandBook
        |> mount_screen()
        |> render_info({:tap, :add})

      assert assigns(view).save_error

      saved =
        view
        |> render_info({:change, :title, @prefix <> "The Warden"})
        |> render_info({:tap, :add})

      assert [%Book{}] = shelf()
      assert {:push, BookDetail, _params} = pushed(saved)
    end
  end

  describe "the shelf shows the new row afterwards" do
    test "a book typed by hand is on the Persian shelf, in both languages' grids" do
      AddByHandBook
      |> mount_screen()
      |> render_info({:change, :title, @prefix <> "The Salt Almanac"})
      |> render_info({:change, :author, "Ines Karvel"})
      |> render_info({:tap, :add})

      view = mount_screen(BooksFa)

      assert find(tree(view), :text, text: @prefix <> "The Salt Almanac") != nil
      english = mount_screen(Books)
      assert find(tree(english), :text, text: @prefix <> "The Salt Almanac") != nil

      # And the fixture is gone from both: a real shelf is the whole page or
      # none of it.
      assert find(tree(view), :text, text: "خور") == nil
    end

    test "the header, the chips and the hero are counted off the one shelf that was read" do
      a_book!(%{
        title: @prefix <> "A reading",
        status: :reading,
        page_count: 380,
        current_page: 214
      })

      a_book!(%{title: @prefix <> "B finished", status: :finished})

      page = BooksFa.page()

      assert page.header == %{
               title: "کتابخانه",
               subtitle: "۲ کتاب · ۱ در حال خواندن"
             }

      assert page.chips == [
               {"همه", "۲"},
               {"در حال خواندن", "۱"},
               {"تمام‌شده", "۱"},
               {"شروع نشده", "۰"}
             ]

      # The hero is the book being READ, not the head of the shelf's own order —
      # and it comes out of the same list the grid was built from.
      assert page.hero.title == @prefix <> "A reading"
      assert page.hero.id in Enum.map(page.books, & &1.id)
      assert page.hero.pace == "ص. ۲۱۴ / ۳۸۰"
    end

    test "the hero's rail and its own grid tile cannot disagree" do
      # `Kati.Screens.Books.rail/2`'s reason, in the mirror: one finished
      # audiobook was drawn full in the grid and empty in the hero, in one
      # render, because two readers answered the same question differently.
      a_book!(%{
        title: @prefix <> "A finished",
        status: :finished,
        format: :audiobook,
        duration_minutes: 680
      })

      page = BooksFa.page()
      tile = Enum.find(page.books, &(&1.id == page.hero.id))

      assert page.hero.progress == tile.progress
      assert page.hero.progress == 1.0
    end

    test "each count chip leaves the books it names, and only those" do
      a_book!(%{title: @prefix <> "A reading", status: :reading})
      a_book!(%{title: @prefix <> "B finished", status: :finished})
      a_book!(%{title: @prefix <> "C to read", status: :not_started})

      books = BooksFa.page().books

      assert BooksFa.visible(books, 0) |> length() == 3
      assert [%{status: :reading}] = BooksFa.visible(books, 1)
      assert [%{status: :finished}] = BooksFa.visible(books, 2)
      assert [%{status: :not_started}] = BooksFa.visible(books, 3)
    end

    test "a cover's tap tag carries the row's id, so the grid is addressable" do
      # #97: six tiles sharing one tag gave six nodes one `accessibility_id`,
      # and `onNodeWithTag` throws on the second match.
      first = a_book!(%{title: @prefix <> "A first"})
      second = a_book!(%{title: @prefix <> "B second"})

      tags = Enum.map(BooksFa.page().books, &Books.book_tag/1)

      assert String.to_atom("open_book_" <> first.id) in tags
      assert String.to_atom("open_book_" <> second.id) in tags
      assert length(Enum.uniq(tags)) == 2
    end

    test "the Persian line under a jacket is the resource's own, in Persian" do
      assert BooksFa.line(a_book!(%{title: @prefix <> "A finished", status: :finished})) ==
               "تمام‌شده"

      assert BooksFa.line(a_book!(%{title: @prefix <> "B to read"})) == "شروع نشده"

      reading =
        a_book!(%{
          title: @prefix <> "C reading",
          status: :reading,
          page_count: 380,
          current_page: 214
        })

      assert BooksFa.line(reading) == "ص. ۲۱۴ / ۳۸۰"

      # No denominator is not a fraction of an unknown total — it is the page
      # you reached, which is what `Kati.Books.Book.shelf_line/1` prints too.
      no_total = a_book!(%{title: @prefix <> "D reading", status: :reading, current_page: 88})

      assert BooksFa.line(no_total) == "ص. ۸۸"
    end
  end

  describe "the empty state is the empty state" do
    test "with nothing shelved every value on the page is the drawing's" do
      assert shelf() == []
      assert BooksFa.page() == BooksFa.drawn_page()
    end

    test "the drawn page is the board's own six covers and its own counts" do
      page = BooksFa.drawn_page()

      assert length(page.books) == 6
      assert page.header == SampleFa.header()
      assert page.chips == SampleFa.chips()

      # The drawing's ۶۴ is not arithmetic over six — a shelf is a window onto
      # a library, which `Kati.Books.Sample` argues for the English board.
      assert {"همه", "۶۴"} = hd(page.chips)
    end

    test "176's hero copy is 69's book, character for character" do
      # `D-38`'s acceptance: 176 and 69 tell one story, so nothing here is a
      # second literal of a line screen 69 already holds.
      hero = SampleFa.reading_now()
      book = SampleFa.detail()

      assert hero.title == book.title
      assert hero.author == book.author
      assert hero.seed == book.seed
      assert hero.pace == book.progress_line
      assert hero.label == book.status_label
    end

    test "the empty shelf is drawn, and its way out is the + this ticket built" do
      # The one state no board in the 166 draws and every device has on the day
      # it is installed.
      view = mount_screen(BooksFa)
      empty = SampleFa.empty()

      assert find(tree(view), :text, text: empty.title) != nil
      assert find(tree(view), :text, text: empty.body) != nil
      assert empty.body =~ "دکمه +", "the sentence names the control that answers it"

      # And it is not the Goodreads import: `Kati.Screens.ImportRecognised`
      # writes nothing, so pointing a new empty state at it would promise a
      # write that does not happen.
      refute empty.body =~ "گودریدز"
    end

    test "the drawn rows carry no id, so a drawn tile cannot be mistaken for a shelved one" do
      # Rule 3: fixture rows carry no `:id`, by absence and never as `nil` —
      # which is what lets `Kati.Screens.Books.book_tag/1` tell the two apart.
      for row <- BooksFa.drawn_books() do
        refute Map.has_key?(row, :id)
        assert Books.book_tag(row) == String.to_atom("open_book_" <> row.seed)
      end
    end
  end

  describe "the form's own vocabulary is the resource's" do
    test "every status chip maps onto a value Kati.Books.Book accepts" do
      accepted = one_of(:status)

      for label <- AddByHandBook.status_list() do
        assert AddByHandBook.status_atom(label) in accepted
      end

      # And the two the form does NOT offer are still values the resource has —
      # they belong to screen 66's control, which is the argument for leaving
      # them off rather than an omission.
      assert :paused in accepted
      assert :did_not_finish in accepted
      refute "Paused" in AddByHandBook.status_list()
    end

    test "every Edition chip maps onto a format the resource accepts" do
      accepted = one_of(:format)

      for {label, format} <- AddByHandBook.edition_list() do
        assert format in accepted
        assert AddByHandBook.format(label) == format
      end
    end

    test "the five Kind chips are the board's five, with Book the lit one" do
      labels = Enum.map(AddByHandBook.kind_list(), &elem(&1, 0))

      assert labels == ["Film", "Series", "Book", "Album", "Artist"]

      # Board 155's resting band is unchanged: Film is still the default of the
      # form 154 draws, and 177 is a different screen rather than a new default.
      assert Enum.map(AddByHand.kind_list(), &elem(&1, 0)) == ["Film", "Series"]
    end
  end

  defp pushed(view), do: view.socket.__mob__.nav_action

  defp one_of(attribute) do
    Book
    |> Ash.Resource.Info.attribute(attribute)
    |> Map.fetch!(:constraints)
    |> Keyword.fetch!(:one_of)
  end

  # This test's own books, newest first — the shelf's own order, through the
  # shelf's own action so the order is the one screen 176 reads.
  defp shelf do
    Book
    |> Ash.read!(action: :shelf)
    |> Enum.filter(&String.starts_with?(&1.title, @prefix))
  end

  defp a_book!(attrs), do: Ash.create!(Book, Map.merge(%{title: @prefix <> "A book"}, attrs))

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
