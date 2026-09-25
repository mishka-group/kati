defmodule Kati.ShareCardScopeTest do
  @moduledoc """
  Screen 98's scope chips and its privacy switch, reading something at last.

  The audit's finding: *"The five non-resting scope chips and the privacy
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

      assert [%{title: "Dune"}] = YearShare.top_titles(:all)
      assert [%{title: "Dune"}] = YearShare.top_titles(:screen)
    end

    test "and a scope with nothing in it shows nothing, not the same three titles" do
      watch!(shelve!("Dune", :movie))

      assert YearShare.top_titles(:books) == []
      assert YearShare.top_titles(:music) == []
      assert YearShare.top_titles("Meals") == []
    end
  end

  describe "the privacy switch" do
    test "leaves a title alone until it is marked" do
      watch!(shelve!("Dune", :movie))

      assert [%{title: "Dune"}] = YearShare.top_titles(:all, true)
    end

    test "and takes a marked one off the card" do
      tracked = shelve!("Dune", :movie)
      watch!(tracked)
      mark_private!(tracked)

      assert YearShare.top_titles(:all, true) == []
      assert [%{title: "Dune"}] = YearShare.top_titles(:all, false)
    end

    test "which is the card and nowhere else" do
      tracked = shelve!("Dune", :movie)
      watch!(tracked)
      mark_private!(tracked)

      assert Enum.any?(Kati.Screens.Library.shelf(), &(&1.title == "Dune")),
             "a private title left the shelf, and the switch is about the picture"
    end
  end

  describe "the card" do
    test "draws no `nil` where a first year has no change to report" do
      # `hours_face/1` has always answered `change: nil` for a first year and
      # the card drew it anyway, so a green up-arrow sat beside the four
      # letters `nil`. Found on the Pixel_9a.
      watch!(shelve!("Dune", :movie))

      words =
        %{scope: :all, hide_private: false, aspect: :aspect_square, share: YearShare.share()}
        |> YearShare.content()
        |> inspect(limit: :infinity, printable_limit: :infinity)

      refute words =~ "\"nil\""
    end

    test "and the arrow goes with it, because an arrow is a direction" do
      # An up-arrow beside nothing is a claim about a rise nobody measured.
      #
      # `change_pill/1` takes the hours face WHOLE now: the arrow is that
      # face's `:direction`, not a decoration around its `:change`. So a
      # direction has to be supplied here, and the assertions are unchanged.
      absent = YearShare.change_pill(%{change: nil, direction: :up}) |> inspect(limit: :infinity)

      present =
        YearShare.change_pill(%{change: "18%", direction: :up}) |> inspect(limit: :infinity)

      assert absent == inspect(%{type: :spacer, children: [], props: %{size: 0}})
      assert present =~ "18%"
    end

    test "and it points the way the year went, which is the half that leaves the phone" do
      # Screen 07 draws a fallen year red and pointing down; this card drew the
      # same figure green and pointing up, because it took `:change` alone and
      # the literal glyph was `arrow_drop_up`. Neither page prints a sign —
      # `Kati.Screens.Stats`'s year takes `abs/1` — so the arrow was the only
      # place the direction was written down.
      up = YearShare.change_pill(%{change: "22%", direction: :up}) |> inspect(limit: :infinity)

      down =
        YearShare.change_pill(%{change: "22%", direction: :down}) |> inspect(limit: :infinity)

      assert up =~ Kati.Icons.glyph!("arrow_drop_up")
      assert down =~ Kati.Icons.glyph!("arrow_downward")

      refute down =~ Kati.Icons.glyph!("arrow_drop_up"),
             "a year that fell must not carry the rising glyph"

      assert up != down, "one year up and the same year down drew the same pill"
    end

    test "and it is screen 07's decision, asked once rather than copied" do
      # The two pages share the glyph and the colour and nothing else. A second
      # copy of that choice is exactly how they came to disagree about one year,
      # so this asserts the card's pill CONTAINS the node 07's helper builds.
      for {rising?, direction} <- [{true, :up}, {false, :down}] do
        from_stats =
          Kati.Screens.Stats.arrow(%{rising?: rising?}, size: 20, fill: false)
          |> inspect(limit: :infinity)

        in_card =
          YearShare.change_pill(%{change: "1%", direction: direction})
          |> inspect(limit: :infinity)

        assert String.contains?(in_card, from_stats),
               "the share card built its own #{direction} arrow instead of asking screen 07's"
      end
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

    test "is on the series page too, because a series is as private as a film" do
      tracked = shelve!("Tidewrack", :tv)

      socket =
        Kati.Screens.Series
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:series, Kati.Screens.Series.series(tracked.id))
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, marked} = Kati.Screens.Series.handle_info({:tap, :toggle_private}, socket)

      assert {:ok, %{private: true}} = Ash.get(TrackedTitle, tracked.id)
      assert marked.assigns.series.private?
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
