defmodule Kati.SearchOpenLibraryTest do
  @moduledoc """
  A book found in Open Library is a row that adds itself.

  Screen 19's books panel used to say *marketing: searching is coming*; the
  catalogue is real now (`Kati.Media.OpenLibrary`), so the row exists, its tag
  names the work, and pressing it writes the book and opens the page it just
  created. Nothing here reaches the network — the row is the fixture the
  client's own test proves the client produces.
  """

  use Mob.ScreenCase, async: false
  use Gettext, backend: Kati.Gettext

  alias Kati.Books.Book
  alias Kati.Screens.Search

  @row %{
    title: "The Salt Almanac",
    sub: "Ines Karvel · 2024 · 380 p.",
    seed: "ol-12345",
    kind: :book,
    source: :open_library,
    source_id: "/works/OL123W",
    author: "Ines Karvel",
    year: 2024,
    pages: 380,
    isbn: "9780571339152",
    cover_id: 12_345
  }

  setup do
    on_exit(fn -> Book |> Ash.read!() |> Enum.each(&Ash.destroy!/1) end)
    :ok
  end

  test "a catalogue row's tag names the work" do
    assert Search.hit_tag(@row) == :shelf_book_OL123W
  end

  test "the books section draws the catalogue's rows before the shelf's" do
    drawn = text(Search.books(%{book_hits: [@row], books: []}))

    assert drawn =~ "The Salt Almanac"
    assert drawn =~ "Ines Karvel"
  end

  test "a books group with only a catalogue hit is not blank" do
    refute Search.blank?(%{books: [], book_hits: [@row]}, :books)
    assert Search.blank?(%{books: [], book_hits: []}, :books)
  end

  test "adding a catalogue row writes the book, and only once" do
    assert {:ok, book} = Search.add_book(@row)
    assert book.title == "The Salt Almanac"
    assert book.source == :open_library
    assert book.source_id == "/works/OL123W"
    assert book.author == "Ines Karvel"
    assert book.isbn == "9780571339152"
    assert book.page_count == 380
    assert book.cover_seed == "ol-12345"

    assert {:ok, again} = Search.add_book(@row)
    assert again.id == book.id
    assert length(Ash.read!(Book)) == 1
  end

  test "pressing the row adds the book and opens its page" do
    view = mount_screen(Search, %{query: "salt"})
    socket = Mob.Socket.assign(view.socket, :book_hits, [@row])

    moved = Search.handle_info({:tap, :shelf_book_OL123W}, socket) |> elem(1)

    assert [book] = Ash.read!(Book)
    assert book.title == "The Salt Almanac"
    assert moved.__mob__.nav_action == {:push, Kati.Screens.BookDetail, %{book_id: book.id}}
  end
end
