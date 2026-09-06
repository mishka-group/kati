defmodule Kati.ShareCardScopeTest do
  @moduledoc """
  Screen 98's scope chips and its privacy switch, reading something at last.

  MOVIES-AND-TV.md #103: *"The five non-resting scope chips and the privacy
  switch move assigns that nothing reads, so they relight over an unchanged
  card."* A chip that lights and changes nothing is worse than one that is
  absent — it says the card is now about Books.

  The privacy switch had a second problem underneath the first: there was
  nothing to mark. `Kati.Media.TrackedTitle.private` is the column, set from
  the ⋯ menu on the title's own page, which is where a decision about one
  title belongs. It hides the title from the CARD and nowhere else — the
  shelf, Up next and the year's numbers are unchanged, because a private title
  is still a title you watched.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.YearShare

  doctest YearShare, only: [shareable?: 3]

  @prefix "share-scope-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the scope chips" do
    test "All and Screen both show a watched film" do
      watch!(shelve!("Dune", :movie))

      assert [%{title: "Dune"}] = YearShare.top_titles("All")
      assert [%{title: "Dune"}] = YearShare.top_titles("Screen")
    end

    test "and a scope with nothing in it shows nothing, not the same three titles" do
      watch!(shelve!("Dune", :movie))

      assert YearShare.top_titles("Books") == []
      assert YearShare.top_titles("Music") == []
      assert YearShare.top_titles("Meals") == []
    end
  end

  describe "the privacy switch" do
    test "leaves a title alone until it is marked" do
      watch!(shelve!("Dune", :movie))

      assert [%{title: "Dune"}] = YearShare.top_titles("All", true)
    end

    test "and takes a marked one off the card" do
      tracked = shelve!("Dune", :movie)
      watch!(tracked)
      mark_private!(tracked)

      assert YearShare.top_titles("All", true) == []
      assert [%{title: "Dune"}] = YearShare.top_titles("All", false)
    end

    test "which is the card and nowhere else" do
      tracked = shelve!("Dune", :movie)
      watch!(tracked)
      mark_private!(tracked)

      assert Enum.any?(Kati.Screens.Library.shelf(), &(&1.title == "Dune")),
             "a private title left the shelf, and the switch is about the picture"
    end
  end

  describe "the ⋯ row that marks it" do
    test "draws a glyph Kati actually has, in both states" do
      # `visibility` is not in Kati's subset and `Kati.Icons.glyph!/1` raises
      # on anything that is not — which took the film screen down on the
      # Pixel_9a and sent the app back to Home. Found by pressing it.
      for film <- [%{private?: false}, %{private?: true}] do
        assert Kati.Icons.glyph(Kati.Screens.Film.private_icon(film)) != nil
      end
    end

    test "says what pressing it does, both ways" do
      assert Kati.Screens.Film.private_label(%{private?: false}) == "Keep off shared cards"
      assert Kati.Screens.Film.private_label(%{private?: true}) == "Show on shared cards"
    end

    test "and writes the column" do
      tracked = shelve!("Dune", :movie)

      socket =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, Kati.Screens.Film.film(tracked.id))
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, marked} = Kati.Screens.Film.handle_info({:tap, :toggle_private}, socket)

      assert {:ok, %{private: true}} = Ash.get(TrackedTitle, tracked.id)
      assert marked.assigns.film.private?
      refute marked.assigns.menu?
    end
  end

  defp mark_private!(tracked) do
    tracked
    |> Ash.Changeset.for_update(:update, %{private: true})
    |> Ash.update!()
  end

  defp shelve!(title, kind) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      status: :watching
    })
  end

  defp watch!(tracked) do
    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      watched_on: Kati.Time.today(),
      watched_at: Kati.Time.now() |> DateTime.truncate(:second)
    })
  end
end
