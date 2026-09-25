defmodule Kati.AnimeKindTest do
  @moduledoc """
  Anime is a kind something writes now.

  `:anime` was read by `Kati.Screens.Library.shelf/0`,
  `Kati.Screens.Stats`, `Kati.Screens.YearShare`, the importer, the search and
  the notifier, and written by nothing at all — so the Library queried a third
  shelf that was always empty and screen 152's entire subject had no column.

  Board 152 states the rule in priority order and these are those three lines,
  asserted in that order, plus the latent half of #104: `shaped/3` decided
  film-vs-series with `kind == :movie`, so an anime FILM would have opened the
  series screen and asked for its seasons.
  """
  use Mob.ScreenCase, async: false

  require Ash.Query

  doctest Kati.Media.Anime,
    only: [kind_for: 3, provider_says?: 1, source_says?: 1, screen_kind: 1, film?: 2]

  doctest Kati.Screens.Library, only: [anime_chip: 1]

  doctest Kati.Import.Job, only: [marked: 2]

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle

  @prefix "anime-kind-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM media_events", [])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "rule 3 — the provider genre" do
    test "Animation and Japanese origin together, never either alone" do
      assert Kati.Media.Anime.kind_for(:tv, japanese_cartoon(), nil) == :anime

      # Animation alone files Pixar as anime.
      refute Kati.Media.Anime.kind_for(
               :movie,
               %{genres: "Animation", original_language: "en"},
               nil
             ) ==
               :anime

      # Japanese origin alone files every live-action drama as anime.
      refute Kati.Media.Anime.kind_for(:tv, %{genres: "Drama", original_language: "ja"}, nil) ==
               :anime
    end
  end

  describe "rule 2 — the import source" do
    test "a MAL or AniList file marks everything in it" do
      records = [%{name: "Frieren", kind: :tv}, %{name: "Akira", kind: :movie}]

      assert Kati.Import.Job.marked(records, "myanimelist") |> Enum.map(& &1.kind) ==
               [:anime, :anime]

      assert Kati.Import.Job.marked(records, "anilist") |> Enum.map(& &1.kind) ==
               [:anime, :anime]

      # And a Letterboxd file marks nothing.
      assert Kati.Import.Job.marked(records, "letterboxd") == records
    end
  end

  describe "rule 1 — your own tag" do
    test "always wins, in both directions" do
      # A reader who says *not anime* about a Japanese cartoon is answered.
      assert Kati.Media.Anime.kind_for(:tv, japanese_cartoon(), false) == :tv

      # And one who says *anime* about a co-production TMDB files under English.
      assert Kati.Media.Anime.kind_for(:tv, %{genres: "Drama", original_language: "en"}, true) ==
               :anime
    end

    test "and the ⋯ row writes it, both ways" do
      tracked = shelve!(:tv)
      film = %{tracked_id: tracked.id, anime?: false}

      socket =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, film)
        |> Mob.Socket.assign(:menu?, true)

      assert Kati.Screens.Film.anime_label(film) == "Mark as anime"

      {:noreply, marked} = Kati.Screens.Film.handle_info({:tap, :toggle_anime}, socket)

      assert marked.assigns.film.anime?
      assert Ash.get!(TrackedTitle, tracked.id).kind == :anime
      assert Ash.get!(TrackedTitle, tracked.id).anime_override == true

      # And back. `anime_override` is three-valued so that *I have not said*
      # and *no* stay different answers — pressing the row is saying.
      {:noreply, unmarked} =
        Kati.Screens.Film.handle_info({:tap, :toggle_anime}, %{
          marked
          | assigns: Map.put(marked.assigns, :menu?, true)
        })

      refute unmarked.assigns.film.anime?
      assert Ash.get!(TrackedTitle, tracked.id).kind == :tv
      assert Ash.get!(TrackedTitle, tracked.id).anime_override == false
    end

    test "and the series page carries the flag through its own rebuild" do
      # `Kati.Screens.Series` assembles facts and then rebuilds a render shape
      # from them, dropping every key it does not name — its own comment calls
      # that map "where a fact goes to be forgotten". So the ⋯ rows drew *Mark
      # as anime* on a title already marked. Found on the Pixel_9a.
      tracked = shelve!(:anime)
      series = Kati.Screens.Series.series(tracked.id)

      assert series.anime?, "the anime flag did not survive the rebuild"
      assert Map.has_key?(series, :media_kind), "the kind did not survive the rebuild"

      assert Kati.Screens.Film.anime_label(series) == "Not anime"
    end

    test "and there is no row over a drawing" do
      assert Kati.Screens.Film.anime_item(%{}) == []
      refute Kati.Screens.Film.anime_item(%{tracked_id: "x"}) == []
    end
  end

  describe "the shelf" do
    test "a film marked as anime is still a film" do
      # Found on the Pixel_9a: a hand-added film marked as anime moved to the
      # series screen. An override writes the TRACKED row's kind and leaves the
      # cache alone, so the cache is what remembers — and a hand-added film has
      # neither a runtime nor an episode count for the shape guess to read.
      tracked = shelve!(:movie)

      cached =
        CachedTitle
        |> Ash.Query.filter(source_id == ^(@prefix <> "movie"))
        |> Ash.read_one!()

      overridden = %{tracked | kind: :anime}

      assert Kati.Screens.Library.shaped(overridden, cached, [], 0, nil).kind == :film
      assert Kati.Screens.Library.shaped(overridden, cached, [], 0, nil).media_kind == :anime
    end

    test "an anime film opens the film screen, not the series screen" do
      # The latent half of #104: `shaped/3` asked `kind == :movie`, so an anime
      # film would have opened screen 04 and asked for its seasons.
      tracked = shelve!(:anime)

      cached =
        CachedTitle
        |> Ash.Query.filter(source_id == ^(@prefix <> "anime"))
        |> Ash.read_one!()
        |> Ash.Changeset.for_update(:update, %{runtime_minutes: 124})
        |> Ash.update!()

      shaped = Kati.Screens.Library.shaped(tracked, cached, [], 0, nil)

      assert shaped.kind == :film, "an anime film would have opened the series screen"
      assert shaped.media_kind == :anime, "the chip needs the fact, not the route"

      series =
        cached
        |> Ash.Changeset.for_update(:update, %{episode_count: 26})
        |> Ash.update!()

      assert Kati.Screens.Library.shaped(tracked, series, [], 0, nil).kind == :series
    end

    test "the Anime chip appears at the threshold board 152 names, and not before" do
      threshold = Kati.Media.AnimeSample.promote_threshold()

      few = for _ <- 1..(threshold - 1), do: %{status: :watching, media_kind: :anime}
      enough = for _ <- 1..threshold, do: %{status: :watching, media_kind: :anime}

      refute :anime in labels(few)
      assert :anime in labels(enough)
      assert {:anime, "Anime", threshold} in Kati.Screens.Library.chip_counts(enough)
    end

    test "and the chip narrows to anime alone" do
      rows = [
        %{status: :watching, media_kind: :anime, title: "Frieren"},
        %{status: :watching, media_kind: :tv, title: "Severance"}
      ]

      assert Kati.Screens.Library.visible(rows, :anime) |> Enum.map(& &1.title) == ["Frieren"]
      assert Kati.Screens.Library.visible(rows, :all) |> length() == 2
    end

    test "a film marked as anime still opens its own page" do
      # Found on the Pixel_9a: `film_record/1` read `kind: :movie` only, so the
      # one title the reader had just marked answered `nil` and screen 08 fell
      # back to the DRAWING — they tapped their own film and got somebody
      # else's.
      tracked = shelve!(:movie)

      film = Kati.Screens.Film.film(tracked.id)
      assert film.tracked_id == tracked.id

      socket =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, film)
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, marked} = Kati.Screens.Film.handle_info({:tap, :toggle_anime}, socket)
      assert marked.assigns.film.anime?

      reopened = Kati.Screens.Film.film(tracked.id)

      assert reopened.tracked_id == tracked.id,
             "the page fell back to the drawing one tap after the flag was set"

      assert reopened.title == "Akira"
      assert reopened.anime?
    end

    test "and an empty Anime chip says how a title gets the flag" do
      drawn = inspect(Kati.Screens.Library.nothing_here(:anime), limit: :infinity)

      assert drawn =~ "No anime on the shelf"
      assert drawn =~ "MAL or AniList"
    end
  end

  defp labels(rows), do: rows |> Kati.Screens.Library.chip_counts() |> Enum.map(&elem(&1, 0))

  defp japanese_cartoon, do: %{genres: "Animation, Adventure", original_language: "ja"}

  defp shelve!(kind) do
    source_id = @prefix <> to_string(kind)

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: "Akira",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching
    })
  end
end
