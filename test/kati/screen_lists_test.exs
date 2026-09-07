defmodule Kati.ScreenListsTest do
  @moduledoc """
  Screen 12's *Kept automatically* card counts the reader's own library.

  MOVIES-AND-TV.md #106: all four rows were the drawing's numbers on every
  device, and two of them are one query each. The other two are assertions a
  reader makes about a title and no column holds, so they are not drawn rather
  than drawn frozen — a card where two rows are the reader's library and two are
  somebody else's reads as fully real, which is the call #75 made one screen
  over.

  The rest of the screen is still the fixture and cannot stop being: see the
  moduledoc, and [#99](https://github.com/mishka-group/kati/issues/99) for the
  three drawings that would let it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Lists

  require Ash.Query

  @prefix "lists-test-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM list_memberships", [])
      Kati.Repo.query!("DELETE FROM lists", [])
      Kati.Repo.query!("DELETE FROM media_watches", [])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the two rows the store can answer" do
    test "count nothing on an empty shelf, which is a true answer" do
      Kati.Repo.query!("DELETE FROM media_watches", [])

      assert [%{title: "Rewatches", count: "0"}, %{title: "Abandoned", count: "0"}] =
               Lists.kept_rows()
    end

    test "count a dropped title and a rewatch" do
      dropped = shelve!("one", :dropped)
      watched = shelve!("two", :watching)

      Ash.create!(Watch, %{
        tracked_title_id: watched.id,
        rewatch_number: 2,
        watched_on: ~D[2026-09-01],
        watched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      # A first watch is not a rewatch.
      Ash.create!(Watch, %{
        tracked_title_id: dropped.id,
        watched_on: ~D[2026-09-01],
        watched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      assert Lists.rewatch_count() == 1
      assert Lists.abandoned_count() == 1

      drawn = inspect(Lists.kept(Lists.lists()), limit: :infinity)
      assert drawn =~ "Rewatches"
      assert drawn =~ "Abandoned"
    end

    test "and an archived title is not abandoned, it is hidden" do
      shelve!("gone", :dropped)
      [row] = Ash.read!(TrackedTitle) |> Enum.filter(&(&1.source_id == @prefix <> "gone"))
      row |> Ash.Changeset.for_update(:update, %{archived: true}) |> Ash.update!()

      assert Lists.abandoned_count() == 0
    end
  end

  describe "the two rows nothing stores" do
    test "are not drawn at all" do
      drawn = inspect(Lists.kept(Lists.lists()), limit: :infinity)

      refute drawn =~ "Wishlist"
      refute drawn =~ "Owned on disc"
    end

    test "and neither is a chevron that opens nothing" do
      # Every kept row drew one, at a list-detail screen the design never drew.
      # The MADE rows keep theirs, because those open one now.
      drawn = inspect(Lists.kept(Lists.lists()), limit: :infinity)

      refute drawn =~ Kati.Icons.glyph!("chevron_right")
    end
  end

  describe "the + disc" do
    test "opens a field, and the field makes a real list" do
      # It used to prepend a row titled `New list` to the socket: lost on back,
      # duplicated on a second press, holding nothing either way.
      {:ok, socket} = Lists.mount(%{}, %{}, Mob.Socket.new(Lists))

      refute socket.assigns.naming?
      refute inspect(Lists.name_field(socket.assigns), limit: :infinity) =~ "list_name"

      {:noreply, naming} = Lists.handle_tap(:new_list, socket)
      assert naming.assigns.naming?
      assert inspect(Lists.name_field(naming.assigns), limit: :infinity) =~ "list_name"

      {:noreply, typed} = Lists.handle_info({:change, :list_name, "Rainy Sunday"}, naming)
      {:noreply, made} = Lists.handle_tap(:save_list, typed)

      assert [%{name: "Rainy Sunday"}] = Ash.read!(Kati.Lists.List)
      assert [%{title: "Rainy Sunday", count: "0 titles"}] = made.assigns.lists.made

      # The field clears, with a new epoch — `K-46`.
      assert made.assigns.name == ""
      assert made.assigns.name_epoch > naming.assigns.name_epoch
      refute made.assigns.naming?
    end

    test "and the same name twice is one list" do
      {:ok, socket} = Lists.mount(%{}, %{}, Mob.Socket.new(Lists))

      for _ <- 1..2 do
        {:noreply, typed} = Lists.handle_info({:change, :list_name, "Rainy Sunday"}, socket)
        {:noreply, _} = Lists.handle_tap(:save_list, typed)
      end

      assert length(Ash.read!(Kati.Lists.List)) == 1
    end

    test "and a name of only space is refused, in the app's own words" do
      {:ok, socket} = Lists.mount(%{}, %{}, Mob.Socket.new(Lists))

      {:noreply, typed} = Lists.handle_info({:change, :list_name, "   "}, socket)
      {:noreply, refused} = Lists.handle_tap(:save_list, typed)

      assert refused.assigns.save_error
      assert Ash.read!(Kati.Lists.List) == []
    end

    test "and the keyboard's own key saves too" do
      {:ok, socket} = Lists.mount(%{}, %{}, Mob.Socket.new(Lists))

      {:noreply, typed} = Lists.handle_info({:change, :list_name, "Rainy Sunday"}, socket)
      {:noreply, _made} = Lists.handle_info({:submit, :save_list}, typed)

      assert [%{name: "Rainy Sunday"}] = Ash.read!(Kati.Lists.List)
    end
  end

  describe "a list with titles in it" do
    test "opens, holds them in order, and lets one out again" do
      {:ok, list} = Kati.Lists.Shelf.create("Rainy Sunday")
      one = shelve!("one", :watching)
      two = shelve!("two", :watching)

      assert :ok = Kati.Lists.Shelf.add(list, one.id)
      assert :ok = Kati.Lists.Shelf.add(list, two.id)

      # Adding the same title twice is how somebody checks it is in.
      assert :ok = Kati.Lists.Shelf.add(list, one.id)

      detail = Kati.Lists.Shelf.detail(list.id)
      assert detail.count == "2 titles"
      assert Enum.map(detail.titles, & &1.title) == ["Test one", "Test two"]

      socket =
        Kati.Screens.ListDetail
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:list, detail)

      {:noreply, gone} =
        Kati.Screens.ListDetail.handle_tap(String.to_atom("remove_" <> one.id), socket)

      assert gone.assigns.list.count == "1 title"
      assert Enum.map(gone.assigns.list.titles, & &1.title) == ["Test two"]
    end

    test "and a tag naming a title the page is not holding writes nothing" do
      {:ok, list} = Kati.Lists.Shelf.create("Rainy Sunday")
      one = shelve!("one", :watching)
      stranger = shelve!("stranger", :watching)
      :ok = Kati.Lists.Shelf.add(list, one.id)

      socket =
        Kati.Screens.ListDetail
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:list, Kati.Lists.Shelf.detail(list.id))

      {:noreply, unchanged} =
        Kati.Screens.ListDetail.handle_tap(String.to_atom("remove_" <> stranger.id), socket)

      assert unchanged.assigns.list.count == "1 title"
    end

    test "and coming back from it re-reads the counts" do
      # The page was showing what it mounted with: `Rainy Sunday · 0 titles`
      # one tap after two went in. Found on the Pixel_9a.
      {:ok, list} = Kati.Lists.Shelf.create("Rainy Sunday")
      one = shelve!("one", :watching)

      {:ok, socket} = Lists.mount(%{}, %{}, Mob.Socket.new(Lists))
      assert hd(socket.assigns.lists.made).count == "0 titles"

      :ok = Kati.Lists.Shelf.add(list, one.id)

      {:noreply, back} = Lists.handle_info({:kati, :resumed, nil}, socket)

      assert hd(back.assigns.lists.made).count == "1 title"
    end

    test "and deleting the list takes its memberships and nothing else" do
      {:ok, list} = Kati.Lists.Shelf.create("Rainy Sunday")
      one = shelve!("one", :watching)
      :ok = Kati.Lists.Shelf.add(list, one.id)

      :ok = Kati.Lists.Shelf.delete(list.id)

      assert Ash.read!(Kati.Lists.List) == []
      assert Ash.read!(Kati.Lists.Membership) == []

      assert Ash.get!(TrackedTitle, one.id).id == one.id,
             "a list holds titles, it does not own them"
    end

    test "and board 146's selection lands in the list that was ticked" do
      # This used to happen on screen 12, where a selection in hand swapped
      # every row's verb from *open it* to *add to it*. Board 333 retired that
      # and put the act on a sheet over the page you are on, so the route is
      # `Kati.Screens.AddToList` now — same outcome, one gesture, and the row
      # never changes meaning under the reader.
      alias Kati.Screens.AddToList

      {:ok, list} = Kati.Lists.Shelf.create("Rainy Sunday")
      one = shelve!("one", :watching)
      two = shelve!("two", :watching)
      members = [{:tracked_title, one.id}, {:tracked_title, two.id}]

      {:ok, socket} = AddToList.mount(%{members: members}, %{}, Mob.Socket.new(AddToList))

      assert socket.assigns.members == members
      assert AddToList.state(hd(socket.assigns.lists), members) == :none

      {:noreply, ticked} =
        AddToList.handle_info({:tap, String.to_atom("toggle_" <> list.id)}, socket)

      assert Kati.Lists.Shelf.detail(list.id).count == "2 titles"

      # The sheet stays open and the row now reads as holding all of them —
      # 333: every tick already committed when it was tapped.
      assert AddToList.state(hd(ticked.assigns.lists), members) == :all
      refute Map.get(ticked.__mob__, :nav_action)
    end

    test "and ticking a list that already holds them all takes them out again" do
      alias Kati.Screens.AddToList

      {:ok, list} = Kati.Lists.Shelf.create("Rainy Sunday")
      one = shelve!("one", :watching)
      members = [{:tracked_title, one.id}]
      :ok = Kati.Lists.Shelf.add(list, {:tracked_title, one.id})

      {:ok, socket} = AddToList.mount(%{members: members}, %{}, Mob.Socket.new(AddToList))
      assert AddToList.state(hd(socket.assigns.lists), members) == :all

      {:noreply, off} =
        AddToList.handle_info({:tap, String.to_atom("toggle_" <> list.id)}, socket)

      assert Kati.Lists.Shelf.detail(list.id).count == "0 titles"
      assert AddToList.state(hd(off.assigns.lists), members) == :none
    end

    test "and a book goes in a list beside a film" do
      alias Kati.Screens.AddToList

      {:ok, list} = Kati.Lists.Shelf.create("Rainy Sunday")
      film = shelve!("one", :watching)

      book =
        Ash.create!(Kati.Books.Book, %{title: "The Salt Almanac", author: "Ines Karvel"})

      :ok = Kati.Lists.Shelf.add(list, {:tracked_title, film.id})
      :ok = Kati.Lists.Shelf.add(list, {:book, book.id})

      detail = Kati.Lists.Shelf.detail(list.id)

      assert detail.count == "2 titles"
      assert Enum.map(detail.titles, & &1.kind) == [:film, :book]
      assert Enum.map(detail.titles, & &1.title) == ["Test one", "The Salt Almanac"]

      assert Enum.find(detail.titles, &(&1.kind == :book)).sub == "BOOK · INES KARVEL",
             "board 332 names the kind in words, with the row's own fact after it"

      # And AddToList sees it as held, which is what makes the tick populate.
      assert AddToList.state(hd(Kati.Lists.Shelf.made()), [{:book, book.id}]) == :all
    end
  end

  defp shelve!(id, status) do
    source_id = @prefix <> id

    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: source_id,
      kind: :movie,
      title: "Test " <> id,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: source_id,
      kind: :movie,
      status: status
    })
  end
end
