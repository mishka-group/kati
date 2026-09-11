defmodule Kati.FollowAuthorTest do
  @moduledoc """
  Board 307's Follow row, on both faces of the book page.

  The board gives screen 25 a **New books** switch subtitled *Authors you
  follow* and screen 66 the row that fills it — *"the only new ink 66 needs."*
  There was no noun behind either: `Kati.Books.Book` carries `author` as a free
  string, so `Kati.Books.FollowedAuthor` is what this file is really about, and
  the two rows are what it is for.

  Three questions, and they are the three a switch has to answer to be a
  switch rather than a picture of one: does it *write*, does it *read back*,
  and does it *stay away* from a page that has nobody to follow.

  ## Why the rows go before the test as well as after it

  `Kati.ScreenBookDetailPersianTest`'s discipline and its reason: the suite has no
  Ecto sandbox and several other files render these same screens against this
  same SQLite file. A followed author left behind turns screen 66's switch on
  in a file that never wrote one.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Books.Book
  alias Kati.Books.FollowedAuthor
  alias Kati.Screens.BookDetail
  alias Kati.Screens.BookDetail

  @prefix "follow-author-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  describe "the store" do
    test "following someone, and then not" do
      refute FollowedAuthor.following?(@prefix <> "Ines Karvel")

      assert {:ok, _row} = FollowedAuthor.follow(@prefix <> "Ines Karvel")
      assert FollowedAuthor.following?(@prefix <> "Ines Karvel")

      assert :ok = FollowedAuthor.unfollow(@prefix <> "Ines Karvel")
      refute FollowedAuthor.following?(@prefix <> "Ines Karvel")
    end

    test "one person, however it is spelled or spaced" do
      assert {:ok, first} = FollowedAuthor.follow(@prefix <> "Ines Karvel")
      assert {:ok, second} = FollowedAuthor.follow("  " <> @prefix <> "INES KARVEL ")

      assert first.id == second.id, "case and space made a second row for one person"
      assert mine() == [@prefix <> "Ines Karvel"], "the name is kept as it was typed"
    end

    test "unfollowing somebody who was never followed is the state they asked for" do
      assert :ok = FollowedAuthor.unfollow(@prefix <> "Nobody")
      assert mine() == []
    end

    test "there is no author to follow on a book with no author" do
      assert FollowedAuthor.follow(nil) == {:error, :no_author}
      assert FollowedAuthor.follow("   ") == {:error, :no_author}
      refute FollowedAuthor.following?(nil)
      assert mine() == []
    end
  end

  describe "screen 66" do
    test "the row names the author and the switch writes" do
      a_book!(%{title: @prefix <> "The Estuary Papers", author: @prefix <> "Ines Karvel"})

      view = mount_screen(BookDetail)
      assert Mob.ScreenCase.text(view) =~ "Follow " <> @prefix <> "Ines Karvel"

      socket = view.socket
      refute socket.assigns.following

      {:noreply, socket} = BookDetail.handle_tap(:toggle_follow_author, socket)

      assert socket.assigns.following
      assert FollowedAuthor.following?(@prefix <> "Ines Karvel")
      assert socket.assigns.save_error == nil

      {:noreply, socket} = BookDetail.handle_tap(:toggle_follow_author, socket)

      refute socket.assigns.following
      refute FollowedAuthor.following?(@prefix <> "Ines Karvel")
    end

    test "a page opened on an author already followed opens with the switch on" do
      a_book!(%{title: @prefix <> "The Estuary Papers", author: @prefix <> "Ines Karvel"})
      assert {:ok, _row} = FollowedAuthor.follow(@prefix <> "Ines Karvel")

      assert mount_screen(BookDetail).socket.assigns.following,
             "the row is drawn from the store or it is drawn from nothing"
    end

    test "a book with no author draws no row at all" do
      a_book!(%{title: @prefix <> "Untitled", author: nil})

      assert BookDetail.follow_row(nil, false) == []
      assert BookDetail.follow_row("   ", false) == []
      refute Mob.ScreenCase.text(mount_screen(BookDetail)) =~ "Follow "
    end
  end

  describe "screen 69" do
    test "the Persian row names the author and the switch writes" do
      a_book!(%{title: @prefix <> "سالنامه نمک", author: @prefix <> "اینس کارول"})

      # Board 69 is screen 66 under `:fa` since mishka-group/kati#103, so this
      # half of the file reads as a Persian reader rather than mounting a
      # second module. No restore in `on_exit`: `Mob.ScreenCase` tears
      # `Mob.State` down with the test process, so a write there exits, and the
      # store is per-test anyway.
      Kati.Locale.put(:fa)
      Kati.Locale.activate()

      view = mount_screen(BookDetail)
      assert Mob.ScreenCase.text(view) =~ "دنبال‌کردن " <> @prefix <> "اینس کارول"

      socket = view.socket
      refute socket.assigns.following

      {:noreply, socket} = BookDetail.handle_info({:tap, :toggle_follow_author}, socket)

      assert socket.assigns.following
      assert FollowedAuthor.following?(@prefix <> "اینس کارول")
    end

    test "the Persian name and the English one are two people, and that is the truth" do
      assert {:ok, _row} = FollowedAuthor.follow(@prefix <> "اینس کارول")

      refute FollowedAuthor.following?(@prefix <> "Ines Karvel"),
             "two book pages drawing two different books must not share one follow"
    end
  end

  defp a_book!(attrs), do: Ash.create!(Book, Map.merge(%{title: @prefix <> "A book"}, attrs))

  defp mine, do: Enum.filter(FollowedAuthor.names(), &String.starts_with?(&1, @prefix))

  # Raw SQL because this also runs from `on_exit`, after the test process is gone.
  defp delete_rows! do
    Kati.Repo.query!("DELETE FROM followed_authors WHERE name LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM books WHERE title LIKE ?1", [@prefix <> "%"])
  end
end
