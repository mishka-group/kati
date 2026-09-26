Code.require_file("../support/show_boards.exs", __DIR__)

defmodule Kati.SeriesMetaSubjectTest do
  @moduledoc """
  *Show details* describes the show you opened it over.

  Screen 14 read its board's own sample unconditionally, and
  `Kati.Screens.Series`'s menu row pushed it naming nothing — so *Show details*
  on Severance opened a full page about *The Long Hollow*: a synopsis about a
  tidal surveyor, three ratings, four cast members with character names, three
  priced ways to watch and five tags the reader never wrote. Every fact on it
  was confident, specific, and about something else. It was filed
  `lies-to-user`.

  The title, the still, the meta line, the synopsis, the rating trio and the
  offers come off the row now. Cast, tags and a trailer have nothing behind
  them, so on a real series they are empty and their bands go with them: a
  page that answered the fixture's cast under a real title would be the same
  defect with better artwork.

  Three faces are pinned: a real series, a push whose series has gone, and no
  series at all. None of them reaches board 14's own show, which is a test
  fixture now — `Kati.Test.ShowBoards.series_meta/0`.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Screens.SeriesMeta, only: [params_for: 1]

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.SeriesMeta

  @prefix "series-meta-subject-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "params_for/1" do
    test "names the row screen 04 is drawing" do
      assert SeriesMeta.params_for(%{tracked_id: "abc", title: "Severance"}) == %{id: "abc"}
    end

    test "a drawn series has no row to name" do
      assert SeriesMeta.params_for(%{title: "The Long Hollow"}) == %{}
      assert SeriesMeta.params_for(nil) == %{}
    end
  end

  describe "the page a real series gets" do
    setup do
      %{tracked: tracked!("severance", "Severance", "Drama, Mystery", 27)}
    end

    test "is about that series and not the fixture", %{tracked: tracked} do
      page = SeriesMeta.series(tracked.id)

      assert page.title == "Severance"
      refute page.title == "The Long Hollow"
      assert page.synopsis =~ "severed"
      refute page.synopsis =~ "tidal surveyor"
    end

    test "names the one it was asked for, not the top of the shelf" do
      other = tracked!("hollow", "The Long Hollow", "Drama", 26)
      _newer = tracked!("probe", "Probe", "Documentary", 4)

      assert SeriesMeta.series(other.id).title == "The Long Hollow"
    end

    test "the meta line is the three parts that exist", %{tracked: tracked} do
      line = SeriesMeta.series(tracked.id).meta

      assert line == "DRAMA, MYSTERY · 27 EP"

      # The year and the certification the board draws in front of the genres
      # have no column, so they are absent rather than guessed.
      refute line =~ "2024"
      refute line =~ "15"
    end

    test "the still is the row's own poster", %{tracked: tracked} do
      assert SeriesMeta.series(tracked.id).seed == "/severance.jpg"
    end
  end

  describe "the bands with no resource behind them" do
    setup do
      %{page: SeriesMeta.series(tracked!("severance", "Severance", "Drama", 27).id)}
    end

    test "are empty rather than the fixture's", %{page: page} do
      assert page.cast == []
      assert page.where == []
      assert page.tags == []
      refute Map.has_key?(page, :trailer)
      refute Map.has_key?(page, :more)
    end

    test "and the rating trio is the reader's own, not the fixture's", %{page: page} do
      # Board 311 replaced `Audience` and `Critics` — other people's scores that
      # nothing caches — with two things the reader's own columns answer:
      # *"Audience and Critics are gone, not blank."* The labels are the proof
      # the trio is derived and not the sample's, and every value is the answer
      # for a series with nothing logged against it.
      assert Enum.map(page.ratings, & &1.label) == ["Yours", "Episodes", "Hours"]
      assert Enum.map(page.ratings, & &1.value) == ["—", "0 / 27", "—"]

      refute Enum.any?(page.ratings, & &1.star?),
             "a star over a dash is a rating of nothing rather than no rating"
    end

    test "and the render drops them entirely", %{page: page} do
      drawn = inspect(SeriesMeta.render(%{series: page, back: "Series"}), limit: :infinity)

      for gone <- ["CAST", "WHERE TO WATCH", "YOUR TAGS", "Ines Karvel", "Lumen+", "slow burn"] do
        refute drawn =~ gone, "screen 14 still draws #{inspect(gone)} over a real series"
      end

      # Board 311's claim card was a note about the app's schema — *a resource
      # Kati has no column for* — printed to a reader. A page is allowed to be
      # short, and the bands simply are not there.
      refute drawn =~ "No cast, and no scores"
      refute drawn =~ "no column for"
      assert drawn =~ "Severance"
    end
  end

  describe "the still" do
    test "is nothing, not the board's, for a title with no poster" do
      tracked = tracked!("posterless", "Posterless", "Drama", 3, poster_path: nil)
      page = SeriesMeta.series(tracked.id)

      assert page.seed == nil

      drawn = inspect(SeriesMeta.artwork(page), limit: :infinity)

      refute drawn =~ "type: :image",
             "a title with no poster drew an image — the board's own still was the fallback"

      refute drawn =~ "hollow71"
    end
  end

  describe "a push whose series has gone" do
    test "says so, and draws nothing about any other show" do
      page = SeriesMeta.series(Ecto.UUID.generate())

      assert page.gone?

      drawn = inspect(SeriesMeta.render(%{series: page, back: "Series"}), limit: :infinity)

      assert drawn =~ "This title is no longer in your library"
      refute drawn =~ "Ines Karvel"
      refute drawn =~ ":toggle_menu"
    end

    test "and a series removed while the page sat under a sheet is gone on the way back" do
      tracked = tracked!("removed", "Removed", "Drama", 3)
      {:ok, socket} = SeriesMeta.mount(%{id: tracked.id}, %{}, Mob.Socket.new(SeriesMeta))

      refute Map.get(socket.assigns.series, :gone?, false)

      Ash.destroy!(tracked)

      {:noreply, back} = SeriesMeta.handle_info({:kati, :resumed, nil}, socket)

      assert back.assigns.series.gone?
    end
  end

  describe "the ⋯ disc" do
    test "opens the sibling pages over the same show" do
      tracked = tracked!("menu", "Menu", "Drama", 3)
      {:ok, socket} = SeriesMeta.mount(%{id: tracked.id}, %{}, Mob.Socket.new(SeriesMeta))

      drawn = inspect(SeriesMeta.render(socket.assigns), limit: :infinity)
      assert drawn =~ ":toggle_menu"

      {:noreply, open} = SeriesMeta.handle_info({:tap, :toggle_menu}, socket)
      assert open.assigns.menu?

      menu = inspect(SeriesMeta.render(open.assigns), limit: :infinity)
      assert menu =~ ":go_show_settings"
      assert menu =~ ":go_episode_order"
      refute menu =~ ":go_show_details"

      {:noreply, pushed} = SeriesMeta.handle_info({:tap, :go_show_settings}, open)

      assert {:push, Kati.Screens.SeriesSettings, %{tracked_id: id, back: "Show details"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == tracked.id
      refute pushed.assigns.menu?
    end

    test "is a picture over the board, which has no show to open pages about" do
      drawn =
        inspect(
          SeriesMeta.render(%{
            series: Kati.Test.ShowBoards.series_meta(),
            back: "Series",
            menu?: false
          }),
          limit: :infinity
        )

      refute drawn =~ ":toggle_menu"
    end
  end

  describe "with nothing stored" do
    test "the page is empty, not the board's own series" do
      assert SeriesMeta.series() == SeriesMeta.empty_series(),
             "a reader who owns no series was shown the board's synopsis, cast and ratings"

      refute SeriesMeta.series() == Kati.Test.ShowBoards.series_meta()
    end

    test "and none of the board's own content is on the page" do
      drawn =
        inspect(SeriesMeta.render(%{series: SeriesMeta.series(), back: "Series"}),
          limit: :infinity
        )

      for gone <- ["Ines Karvel", "Lumen+", "slow burn", "hollow71"] do
        refute drawn =~ gone, "#{inspect(gone)} is on the page of a reader who owns nothing"
      end

      assert drawn =~ "No series in your library yet"
    end
  end

  defp tracked!(slug, title, genres, episodes, opts \\ []) do
    source_id = @prefix <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: title,
      overview: "Mark leads a team whose memories are severed between work and home.",
      poster_path: Keyword.get(opts, :poster_path, "/#{slug}.jpg"),
      genres: genres,
      episode_count: episodes,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching
    })
  end
end
