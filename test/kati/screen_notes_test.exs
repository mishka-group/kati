Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenNotesTest do
  @moduledoc """
  The Notes section, end to end: the page reads `Kati.Books.Note`, a note is
  written on the book's own page, and holding a card deletes it.

  The section existed in `Kati.Sections` and had no page; this is the page.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Books.Book
  alias Kati.Books.Note
  alias Kati.DesignLiterals
  alias Kati.ScreenSweep
  alias Kati.Screens.BookDetail
  alias Kati.Screens.Notes

  @prefix "screen-62-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  describe "the page" do
    test "with nothing written it says so, and offers the shelf" do
      assert {:ok, _socket, tree} = ScreenSweep.render(Notes)
      texts = DesignLiterals.rendered(tree)

      assert "no notes yet" in texts
      assert "open books" in texts
      assert Notes.notes() == []
    end

    test "a note appears with its body, its anchor and its book" do
      {book, note} = seed_note("The sea was a rumour.", kind: :quote, page: 148)

      assert {:ok, _socket, tree} = ScreenSweep.render(Notes)
      texts = DesignLiterals.rendered(tree)

      assert Enum.any?(texts, &String.contains?(&1, String.downcase(note.body)))
      assert "p. 148" in texts
      assert Enum.any?(texts, &String.contains?(&1, String.downcase(book.title)))
    end

    test "tapping a card opens the book it is about" do
      {book, _note} = seed_note("A thought without a page.")

      id = book.id
      view = mount_screen(Notes) |> render_info({:tap, {:open_book, id}})

      assert {:push, BookDetail, %{book_id: ^id}} = pushed(view)
    end

    test "holding a card asks, and a confirmed delete removes the note" do
      {_book, note} = seed_note("Delete me.")

      view = mount_screen(Notes)
      assert assigns(view).confirming == nil

      view = render_info(view, {:long_press, {:confirm_delete, note.id}})
      assert assigns(view).confirming == note.id

      view = render_info(view, {:tap, :cancel_delete})
      assert assigns(view).confirming == nil
      assert length(Notes.notes()) == 1

      view =
        view
        |> render_info({:long_press, {:confirm_delete, note.id}})
        |> render_info({:tap, :confirm_delete})

      assert assigns(view).notes == []
      assert Notes.notes() == []
    end
  end

  describe "writing one on the book's page" do
    test "the composer writes the note and the page redraws with it" do
      book = seed_book()

      view =
        mount_screen(BookDetail, %{book_id: book.id})
        |> render_info({:tap, :add_note})
        |> render_info({:change, :note_body, "It held."})
        |> render_info({:change, :note_page, "148"})
        |> render_info({:tap, :save_note})

      assert assigns(view).note_open? == false

      assert [note] = Ash.read!(Note)
      assert note.body == "It held."
      assert note.kind == :note
      assert note.page == 148

      assert Enum.any?(assigns(view).book.notes, &(&1.body == "It held."))
    end

    test "Quote is a kind, and the body is drawn in quotation marks" do
      book = seed_book()

      view =
        mount_screen(BookDetail, %{book_id: book.id})
        |> render_info({:tap, :add_note})
        |> render_info({:tap, :kind_quote})
        |> render_info({:change, :note_body, "The sea was a rumour."})
        |> render_info({:tap, :save_note})

      assert [note] = Ash.read!(Note)
      assert note.kind == :quote

      assert [%{kind: :quote, body: body}] = assigns(view).book.notes
      assert body == "The sea was a rumour."
      assert Kati.Books.Note.display(note) != body
    end

    test "an empty body keeps the composer open and writes nothing" do
      book = seed_book()

      view =
        mount_screen(BookDetail, %{book_id: book.id})
        |> render_info({:tap, :add_note})
        |> render_info({:change, :note_body, "   "})
        |> render_info({:tap, :save_note})

      assert assigns(view).note_open? == true
      assert assigns(view).note_error
      assert Ash.read!(Note) == []
    end

    test "cancel closes it and leaves nothing behind" do
      book = seed_book()

      view =
        mount_screen(BookDetail, %{book_id: book.id})
        |> render_info({:tap, :add_note})
        |> render_info({:change, :note_body, "Unwritten"})
        |> render_info({:tap, :cancel_note})

      assert assigns(view).note_open? == false
      assert assigns(view).note_draft.body == ""
      assert Ash.read!(Note) == []
    end
  end

  defp pushed(view), do: view.socket.__mob__.nav_action

  defp seed_book do
    Ash.create!(Book, %{title: @prefix <> "Book", author: "The Author"})
  end

  defp seed_note(body, opts \\ []) do
    book = seed_book()

    note =
      Ash.create!(Note, %{
        book_id: book.id,
        body: body,
        kind: Keyword.get(opts, :kind, :note),
        page: Keyword.get(opts, :page)
      })

    {book, note}
  end

  defp delete_rows! do
    Kati.Repo.query!(
      "DELETE FROM book_notes WHERE book_id IN (SELECT id FROM books WHERE title LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM books WHERE title LIKE ?1", [@prefix <> "%"])
  end
end
