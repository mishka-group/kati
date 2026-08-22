defmodule Kati.ScreenFilmTest do
  @moduledoc """
  Screen 08 against `Kati.Media`, and against an empty database.

  ## Why this is not covered by the sweeps

  `Kati.ScreenRenderSweepTest` mounts the screen once and asserts it renders;
  `Kati.ScreenTapSweepTest` taps what that render drew. Neither reads the copy,
  so a film screen that queried the wrong kind, picked the wrong row, or drew
  somebody else's note would pass both.

  `Kati.ScreenDesignLiteralTest` does read the copy, and for this screen it
  cannot settle the question either — for the reason
  `Kati.ScreenEmptyDatabaseTest` sets out at length. That suite has no Ecto
  sandbox: one SQLite file is shared, several modules leave rows behind, and
  which of the two paths ran when the sweep rendered screen 08 moves with
  `--seed`. So each half is asserted here, deliberately, both ways round:

    * **empty database** — `Kati.Library.Sample`'s film, exactly, including the
      `Where to watch` card and the cream note. This is the half that keeps the
      screen comparable with `.scratch/design/audit/08.png` on a machine that
      has never tracked anything.
    * **rows present** — the user's own film, and *none* of the drawn values. A
      fallback that fired when it should not is exactly as wrong as one that
      never fires, and asserting only the first half would not notice.

  The second block also pins the two things screen 08 deliberately stops
  drawing once it has real data — the availability card and the year — because
  those are a decision (`Kati.Screens.Film`'s moduledoc says why) rather than an
  omission, and a later round that quietly fills them with sample rows should
  fail here rather than ship a price for a film nobody priced.

  ## The wipe in `setup`

  The suite shares one SQLite file, so "an empty database" has to be made rather
  than assumed — and what this module writes is not inert either: a tracked film
  left behind would put a stranger's title on this screen, and on screen 03's
  grid, the moment another module mounts either. Same reasoning and the same
  `on_exit` as `Kati.ScreenLibraryShelfTest`.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Library.Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Film

  # Child first: a watch carries the foreign key.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles)

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  # One library row: the durable half and, unless `cached_attrs` is nil, the
  # evictable half it references by `{source, source_id}`.
  defp track!(source_id, tracked_attrs, cached_attrs) do
    if cached_attrs do
      CachedTitle
      |> Ash.Changeset.for_create(
        :create,
        Map.merge(
          %{source: :tmdb, source_id: source_id, kind: :movie, fetched_at: DateTime.utc_now()},
          cached_attrs
        )
      )
      |> Ash.create!()
    end

    TrackedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{source: :tmdb, source_id: source_id, kind: :movie}, tracked_attrs)
    )
    |> Ash.create!()
  end

  defp watch!(tracked, attrs) do
    Watch
    |> Ash.Changeset.for_create(:create, Map.put(attrs, :tracked_title_id, tracked.id))
    |> Ash.create!()
  end

  # `last_touched_at` is stamped by `Kati.Media.Changes.Touch` on every write, so
  # the only way to say "this one is older" without depending on how fast two
  # creates run is to write the column directly. Screen 08 picks the top of the
  # film shelf and the shelf is ordered by this, so the tests that care which
  # film was chosen have to own the ordering rather than infer it.
  defp touched!(tracked, %DateTime{} = at) do
    Ecto.Adapters.SQL.query!(
      Kati.Repo,
      "update tracked_titles set last_touched_at = ? where id = ?",
      [DateTime.to_iso8601(at), tracked.id]
    )

    tracked
  end

  # The film the "rows present" block expects to see drawn. Rated 8 of 10 —
  # four whole stars — reviewed once, and watched three times, which is every
  # value the drawing's cards are made of.
  #
  # Not one of the drawing's own numbers is reused here, deliberately: the
  # drawing is watched twice on 12 August, so a fixture that agreed with it on
  # either would let a screen that never left the fallback pass the block below.
  defp a_watched_film! do
    tracked =
      track!(
        "film-paper",
        %{status: :finished, rating: 8},
        %{
          title: "Paper Cities",
          runtime_minutes: 100,
          genres: "Thriller",
          poster_path: "cartog60"
        }
      )

    watch!(tracked, %{watched_on: ~D[2026-07-04], review: "Rex, back row, worth the trip."})
    watch!(tracked, %{watched_on: ~D[2025-11-02]})
    watch!(tracked, %{watched_on: ~D[2024-03-01]})
    tracked
  end

  defp texts(tree), do: tree |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  defp drawn?(tree, string), do: Enum.any?(texts(tree), &(&1 == string))

  describe "an empty database" do
    test "nothing is tracked, so the screen draws the drawing" do
      assert Film.tracked_film() == nil,
             "a film answered against an empty database, so nothing below is measuring " <>
               "the fallback"

      assert Film.film() == Sample.film(),
             "the fallback is not `Kati.Library.Sample.film/0` verbatim, and that fixture " <>
               "is what `.scratch/design/audit/08.png` was captured from"
    end

    test "every string the drawing carries reaches the rendered tree" do
      tree = tree(mount_screen(Film))
      film = Sample.film()

      for string <- [
            film.title,
            film.meta,
            film.watched,
            film.seen,
            film.note,
            String.upcase(film.note_date),
            "WHERE TO WATCH"
          ] do
        assert drawn?(tree, string), "#{inspect(string)} is nowhere in the tree"
      end

      # The availability card, which a real film deliberately does not draw.
      for %{badge: badge, name: name, price: price} <- film.where do
        assert drawn?(tree, badge)
        assert drawn?(tree, name)
        assert drawn?(tree, price)
      end

      for {_icon, label} <- film.actions, do: assert(drawn?(tree, label))
    end

    test "the rating card draws four filled stars and one empty" do
      tree = tree(mount_screen(Film))

      assert length(find_all(tree, :text, font_family: "symbols_filled", text_size: 22)) == 4
      assert length(find_all(tree, :text, font_family: "symbols", text_size: 22)) == 1
    end
  end

  describe "with the user's own film" do
    test "the screen draws that film and none of the drawn values" do
      a_watched_film!()

      film = Film.film()
      assert film.title == "Paper Cities"
      assert film.meta == "1H 40M · THRILLER"
      assert film.watched == "Watched 4 Jul"
      assert film.seen == "3 times"
      assert film.stars == 4
      assert film.note == "Rex, back row, worth the trip."
      assert film.note_date == "Note · 4 Jul"

      tree = tree(mount_screen(Film))

      for string <- ["Paper Cities", "1H 40M · THRILLER", "Watched 4 Jul", "3 times"] do
        assert drawn?(tree, string), "#{inspect(string)} is nowhere in the tree"
      end

      drawn = Sample.film()

      for string <- [drawn.title, drawn.meta, drawn.note, drawn.seen, drawn.watched] do
        refute drawn?(tree, string),
               "#{inspect(string)} is the drawing's, and a real film is being shown"
      end
    end

    test "the availability card and its eyebrow are not drawn at all" do
      a_watched_film!()
      tree = tree(mount_screen(Film))

      refute drawn?(tree, "WHERE TO WATCH"),
             "the eyebrow is still there. Nothing in Kati.Media can say where a film is " <>
               "streaming, so the heading has nothing to head"

      for %{badge: badge, name: name, price: price} <- Sample.film().where do
        refute drawn?(tree, name), "#{name} is the drawing's own service"
        refute drawn?(tree, price), "#{price} is a price quoted for a film nobody priced"
        refute drawn?(tree, badge)
      end
    end

    test "the year is absent from the meta line, because nothing stores one" do
      a_watched_film!()

      # `next_release_at` is the NEXT release and would print next Tuesday as a
      # film's year. The line is the runtime and the genres and nothing else.
      refute Film.film().meta =~ ~r/\d{4}/
    end

    test "the action row is still drawn — those are affordances, not data" do
      a_watched_film!()
      tree = tree(mount_screen(Film))

      for label <- ["Log rewatch", "Schedule", "Share"], do: assert(drawn?(tree, label))
    end

    test "the newest film on the shelf is the one drawn" do
      older = track!("film-old", %{status: :finished}, %{title: "Low Water"})
      newer = track!("film-new", %{status: :finished}, %{title: "Undertow"})

      touched!(older, ~U[2026-01-01 00:00:00Z])
      touched!(newer, ~U[2026-08-01 00:00:00Z])

      assert Film.film().title == "Undertow"

      touched!(older, ~U[2026-09-01 00:00:00Z])
      assert Film.film().title == "Low Water"
    end

    test "an archived film is not on the shelf, so the drawing is drawn instead" do
      track!("film-hidden", %{status: :finished, archived: true}, %{title: "Hidden Coast"})

      assert Film.tracked_film() == nil,
             "`keeps history, hides from shelf` is the whole meaning of the flag"

      assert Film.film() == Sample.film()
    end

    test "a series is never chosen — this screen is films" do
      CachedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: "film-series",
        kind: :tv,
        title: "Northlight Bay",
        fetched_at: DateTime.utc_now()
      })
      |> Ash.create!()

      TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: "film-series",
        kind: :tv,
        status: :watching
      })
      |> Ash.create!()

      assert Film.tracked_film() == nil
      assert Film.film() == Sample.film()
    end
  end

  describe "the halves a real film can be missing" do
    test "an evicted cache row leaves the memory, not the drawing's title" do
      tracked = track!("film-ghost", %{status: :finished, rating: 10}, nil)
      watch!(tracked, %{watched_on: ~D[2026-08-12]})

      film = Film.film()

      assert film.title == "Untitled",
             "the poster and the title went with the cache; the user's own rating did not, " <>
               "and handing them somebody else's film instead is the one answer that is a lie"

      assert film.stars == 5
      assert film.meta == ""
      assert film.seen == "1 time"
    end

    test "a film with nothing logged draws no pill, no note and `never`" do
      track!("film-fresh", %{status: :not_started}, %{title: "Blue Harbour"})

      film = Film.film()
      assert film.watched == nil
      assert film.note == nil
      assert film.seen == "never"

      tree = tree(mount_screen(Film))

      assert drawn?(tree, "Blue Harbour")
      assert drawn?(tree, "never")

      refute Enum.any?(texts(tree), &String.starts_with?(&1, "Watched")),
             "a watched pill is an assertion that the film has been seen, and nothing here " <>
               "asserts it"

      refute Enum.any?(texts(tree), &String.starts_with?(&1, "NOTE")),
             "the cream card is the user's own words and there are none"
    end

    test "a finished film with no dated watch still says it was watched" do
      track!("film-sure", %{status: :finished}, %{title: "Marram"})

      assert Film.film().watched == "Watched",
             "the user marked it finished, which is the same statement without a date"
    end

    test "an undated watch is honoured without inventing a day for it" do
      tracked = track!("film-vague", %{status: :finished}, %{title: "Vellum"})
      watch!(tracked, %{review: "No idea when."})

      film = Film.film()

      assert film.watched == "Watched"
      assert film.note_date == "Note"
      assert film.note == "No idea when."
    end

    test "the user's own rewatch count beats the number of rows" do
      tracked = track!("film-again", %{status: :finished}, %{title: "Ashfall"})
      watch!(tracked, %{watched_on: ~D[2026-08-12], rewatch_number: 3})

      assert Film.film().seen == "3 times",
             "one row claiming a third rewatch is someone who saw it twice before Kati " <>
               "existed, and counting rows would print `1 time`"
    end

    test "a runtime with no genres, and genres with no runtime, both still read" do
      track!("film-part", %{status: :finished}, %{title: "Harbour", runtime_minutes: 52})
      assert Film.film().meta == "52M"

      empty_the_tables!()

      track!("film-genre", %{status: :finished}, %{title: "Salt", genres: "Drama, Mystery"})
      assert Film.film().meta == "DRAMA, MYSTERY"
    end
  end
end
