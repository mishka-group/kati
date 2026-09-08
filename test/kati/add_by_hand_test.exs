defmodule Kati.AddByHandTest do
  @moduledoc """
  Screen 154 writes a real row, and refuses in words when it cannot.

  The receipt is `Kati.Media.TrackedTitle`, not the socket: a form that moves
  an assign and writes nothing is exactly what screen 89's row was for as long
  as it had no destination.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.TrackedTitle
  alias Kati.Screens.AddByHand

  setup do
    on_exit(fn -> Kati.Repo.query!("DELETE FROM tracked_titles", []) end)
    :ok
  end

  # A real mounted socket, not a map with an `:assigns` key. `Mob.Socket`
  # carries more than its assigns and its own functions pattern-match on the
  # struct, so a stand-in fails inside `assign/3` rather than in the code
  # under test.
  defp socket(overrides) do
    Enum.reduce(overrides, mount_screen(AddByHand).socket, fn {k, v}, s ->
      Mob.Socket.assign(s, k, v)
    end)
  end

  test "a typed title reaches the store as a manual row" do
    AddByHand.save(socket(%{title: "The Long Hollow", kind: :tv, status: :watching}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.source == :manual
    assert row.source_id == "The Long Hollow"
    assert row.kind == :tv
    assert row.status == :watching
  end

  test "a film is a film" do
    AddByHand.save(socket(%{title: "Estuary", kind: :movie}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.kind == :movie
    assert row.status == :not_started
  end

  test "surrounding space is not part of the title" do
    AddByHand.save(socket(%{title: "  Low Water  "}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.source_id == "Low Water"
  end

  describe "the save that refuses" do
    test "no title writes nothing and says so in the board's own two lines" do
      result = AddByHand.save(socket(%{title: ""}))

      assert Ash.count!(TrackedTitle) == 0

      # MOVIES-AND-TV.md #128: one line where board 155 specifies two, and the
      # missing half is the one that matters — a person whose save just failed
      # does not know whether their other four answers survived it.
      assert {title, body} = result.assigns.save_error
      assert title == "A title is needed"
      assert body =~ "Kati cannot keep a thing with no name"
      assert body =~ "your other answers are intact"
    end

    test "a title of only space is no title" do
      result = AddByHand.save(socket(%{title: "   "}))

      assert Ash.count!(TrackedTitle) == 0
      assert {"A title is needed", _body} = result.assigns.save_error
    end

    test "and the Title field takes the ring the board draws on it" do
      # Told *a title is needed* over four fields, a reader had to work out
      # which one. Board 155 rings it.
      refused = AddByHand.save(socket(%{title: ""}))

      assert AddByHand.untitled?(refused.assigns)
      refute AddByHand.untitled?(%{save_error: nil})

      ringed = inspect(AddByHand.field(:title, "", "e.g.", true), limit: :infinity)
      plain = inspect(AddByHand.field(:title, "", "e.g.", false), limit: :infinity)

      assert ringed =~ "border_width"
      refute ringed == plain
    end
  end

  test "every status the board draws maps to one the resource takes" do
    # The label is drawn and the atom is written. They travel together on
    # `status_list/0` rather than through a `status_atom/1` that read one off
    # the other — which was a mapping from ENGLISH words, so the Persian form
    # saved every status as `:not_started`. MOVIES-AND-TV.md #157.
    assert AddByHand.status_list() == [
             {"Not started", :not_started},
             {"Watching", :watching},
             {"Finished", :finished}
           ]

    accepted =
      Kati.Media.TrackedTitle
      |> Ash.Resource.Info.attribute(:status)
      |> Map.fetch!(:constraints)
      |> Keyword.fetch!(:one_of)

    for {_label, status} <- AddByHand.status_list(), do: assert(status in accepted)
  end

  test "and a chip is named for the value, never for the word on it" do
    assert AddByHand.tag("kind_", :tv) == :kind_tv
    assert AddByHand.tag("status_", :not_started) == :status_not_started
  end

  describe "a hand-typed title is a title the app can see" do
    test "it reaches the shelf, which is the only place a person looks for it" do
      # `Kati.Screens.Library`'s own rule: **a row with no cached title is
      # dropped**, because a tile captioned `nil` is worse than a tile that is
      # not there. So writing only the tracked row put a title in the library
      # that the library did not draw — the one path from a fresh install to a
      # library with anything in it, producing a row nobody could see.
      #
      # Every test here counted `tracked_titles` and passed, on device and on
      # the host, because the count was never the question.
      saved(%{title: "Estuary Nights", kind: :movie, status: :not_started})

      titles = Enum.map(Kati.Screens.Library.shelf(), & &1.title)

      assert "Estuary Nights" in titles,
             "the title was written and the shelf does not draw it: " <> inspect(titles)
    end

    test "and search finds it, which is the other place" do
      # `Kati.Search.Query.run/1` reads `Kati.Media.CachedTitle` — the same row
      # the shelf reads the name from — so the two failed together and are
      # fixed together. #92's first criterion is that typing returns rows that
      # match, and a title you added by hand is the one row you are most likely
      # to go looking for.
      saved(%{title: "Estuary Nights", kind: :movie, status: :not_started})

      found = Enum.map(Kati.Search.Query.run("estuary").titles, & &1.title)

      assert "Estuary Nights" in found,
             "a hand-typed title is in the library and cannot be found: " <> inspect(found)
    end

    test "adding one you already have is refused in words a person can act on" do
      # Refusing is right — two rows for one title is not a state the shelf can
      # draw. What was wrong is what it said: the tracked row's uniqueness is a
      # database constraint and Ash reports it as "Has already been taken",
      # which is a sentence about a column. Someone who has just typed a name
      # they already own needs to be told that.
      saved(%{title: "Estuary Nights", kind: :movie, status: :not_started})
      socket = saved(%{title: "Estuary Nights", kind: :tv, status: :watching})

      assert {title, body} = socket.assigns[:save_error]
      assert title == "You already have this"
      assert body =~ "on your shelf already"
      refute body =~ "taken"

      # And what to do instead, because *you already have this* with no way
      # forward is a dead end on the one screen a reader reaches by not
      # finding something (#128's rule, #113's refusal).
      assert body =~ "open it from your library"

      assert length(Kati.Screens.Library.shelf()) == 1,
             "refusing the second add still left two rows on the shelf"
    end

    test "and the guard is the NAME, so a TMDB row and a typed one collide" do
      # MOVIES-AND-TV.md #113: the guard was the unique index on
      # `[:source, :source_id]`, and a TMDB add writes `:tmdb` with a numeric
      # id where a hand-typed one writes `:manual` with the title — they never
      # collided, so the same film sat on the shelf twice.
      Ash.create!(Kati.Media.CachedTitle, %{
        source: :tmdb,
        source_id: "438631",
        kind: :movie,
        title: "Dune",
        fetched_at: Kati.Time.now()
      })

      Ash.create!(Kati.Media.TrackedTitle, %{
        source: :tmdb,
        source_id: "438631",
        kind: :movie,
        status: :watching
      })

      socket = saved(%{title: "dune", kind: :movie, status: :not_started})

      assert {"You already have this", _body} = socket.assigns[:save_error],
             "a TMDB row and a typed one are two rows for one film"

      assert length(Kati.Screens.Library.shelf()) == 1
    end

    test "and a name nobody has is not refused" do
      assert Kati.Screens.AddByHand.already_kept("Nothing By That Name") == nil
    end
  end

  describe "a Kind picked wrong" do
    test "can be corrected from the title's own menu" do
      # MOVIES-AND-TV.md #113's other half. Kind comes from a two-chip answer on
      # 154 and no screen in the app could change it — a show picked as a film
      # sat on the wrong screen forever, and the add path refused to let you
      # type it again because the name was taken.
      saved(%{title: "The Long Hollow", kind: :movie, status: :watching})

      [tracked] = Ash.read!(TrackedTitle)
      assert tracked.kind == :movie

      film = Kati.Screens.Film.film(tracked.id)
      assert film.media_kind == :movie
      assert Kati.Screens.Film.kind_label(film.media_kind) == "This is a series"

      socket =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, film)
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, swapped} = Kati.Screens.Film.handle_info({:tap, :swap_kind}, socket)

      # Both rows. The tracked kind is what the shelf queries and the cached
      # kind is what decides which screen a tile opens, so correcting one and
      # not the other puts the title on the right shelf behind the wrong door.
      assert Ash.get!(TrackedTitle, tracked.id).kind == :tv

      assert [%{kind: :tv}] =
               Kati.Media.CachedTitle
               |> Ash.read!()
               |> Enum.filter(&(&1.title == "The Long Hollow"))

      # And the reader is popped: the page they are on is now about a kind this
      # title is not.
      assert Map.get(swapped.__mob__, :nav_action) == {:pop}
    end

    test "and there is no row over a drawing" do
      assert Kati.Screens.Film.kind_item(%{}) == []
      refute Kati.Screens.Film.kind_item(%{tracked_id: "x", media_kind: :tv}) == []
    end
  end

  defp saved(assigns) do
    Kati.Screens.AddByHand.save(%Mob.Socket{
      Mob.Socket.new(Kati.Screens.AddByHand)
      | assigns: Map.merge(%{save_error: nil}, assigns)
    })
  end
end
