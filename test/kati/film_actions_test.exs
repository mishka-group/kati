defmodule Kati.FilmActionsTest do
  @moduledoc """
  Screen 08's three action buttons, and its two painted cards.

  MOVIES-AND-TV.md #84 and #85.

  **#84.** *Log rewatch* was wired earlier this round; *Schedule* and *Share*
  carried no tag, and the comment beside them said each was waiting on
  something Kati did not have. Both had arrived:

    * *Schedule* wanted a date sheet. Screen 18 is one — it takes a sentence
      and writes a calendar event — so this opens it with `Watch <title>`
      already typed. The verb and the subject are the part a reader should not
      have to retype; what they came to say is WHEN.
    * *Share* wanted the Android share intent, "a fence nobody has written".
      `Mob.Share.text/2` is Mob's own and had been there all along.

  **#85.** The rating card and the note pencil were painted. Both open screen
  33, which is where a rating and a review are written — so *change my four
  stars* and *edit this note* are the same door, from the two things on 08
  that are about it.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Film

  @prefix "film-actions-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  doctest Film, only: [share_line: 1, where_line: 1]

  describe "Schedule" do
    test "opens Quick add with the film's name already typed" do
      tracked = shelve!("Dune", nil)

      socket =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, Film.film(tracked.id))
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, pushed} = Film.handle_info({:tap, :schedule_watch}, socket)

      assert {:push, Kati.Screens.QuickAdd, %{sentence: "Watch Dune"}} =
               Map.get(pushed.__mob__, :nav_action)
    end

    test "and closes the menu on the way, so it is not open on the way back" do
      tracked = shelve!("Dune", nil)

      socket =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, Film.film(tracked.id))
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, pushed} = Film.handle_info({:tap, :schedule_watch}, socket)

      refute pushed.assigns.menu?
    end

    test "and Quick add opens on that sentence, read" do
      draft = Kati.Screens.QuickAdd.draft("Watch Dune tomorrow 8pm")

      assert draft.title == "Watch Dune"
      assert draft.cta == "Add to tomorrow"
    end
  end

  describe "Share" do
    test "names the film, its year and where it can be watched" do
      tracked = shelve!("Dune", %{"GB" => %{"flatrate" => ["Kanopy"]}})
      film = Film.film(tracked.id)

      assert Film.share_line(film) =~ "Dune"
      assert Film.share_line(film) =~ "Kanopy"
    end

    test "and says nothing about availability for a film nobody has looked up" do
      tracked = shelve!("Dune", nil)

      refute Film.share_line(Film.film(tracked.id)) =~ "—"
    end
  end

  describe "the Where to watch band" do
    test "fills from the same column the rules read" do
      tracked = shelve!("Dune", %{"GB" => %{"flatrate" => ["Kanopy"], "rent" => ["Apple TV"]}})

      assert [%{name: "Kanopy", line: "included"}, %{name: "Apple TV", line: "rent"}] =
               Film.film(tracked.id).where
    end

    test "and stays empty for a film nobody has looked up, so the heading drops" do
      tracked = shelve!("Dune", nil)

      assert Film.film(tracked.id).where == []
      assert Film.where_section(Film.film(tracked.id)) == []
    end
  end

  describe "the rating card and the note pencil" do
    test "open the sheet that writes a rating and a review" do
      tracked = shelve!("Dune", nil)
      film = Film.film(tracked.id)

      card = Film.rating_card(film) |> inspect(limit: :infinity)
      pencil = Film.note_pencil(film) |> inspect(limit: :infinity)

      # Three doors, three tags, one handler. All three carried `:log_watch`
      # and two of them are drawn at once, so `ui.sh ids` on the Pixel_9a
      # listed the tag twice — and `onNodeWithTag` throws on the second match.
      assert card =~ ":rate"
      assert pencil =~ ":edit_note"

      for tag <- [:log_watch, :rate, :edit_note] do
        {:noreply, opened} =
          Film.handle_info({:tap, tag}, Mob.Socket.assign(Mob.Socket.new(Film), :film, film))

        assert {:push, Kati.Screens.Rating, _params} = Map.get(opened.__mob__, :nav_action),
               "#{tag} did not open the sheet that writes a rating"
      end
    end

    test "and no two of the three doors carry the same one" do
      tracked = shelve!("Dune", nil)
      film = Film.film(tracked.id)

      drawn =
        Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, film)
        |> Mob.Socket.assign(:menu?, false)
        |> Mob.Socket.assign(:save_error, nil)
        |> then(&inspect(Film.render(&1.assigns), limit: :infinity))

      # Two nodes may not share an `accessibility_id` — `onNodeWithTag` throws
      # on the second match — and all three of these carried `:log_watch`, two
      # of which are drawn at once. Asked of these three by name rather than of
      # every tag on the page: the page also draws a row per watch and a band
      # per provider, and how many of those the store holds is another file's
      # business.
      for tag <- [":log_watch", ":rate", ":edit_note"] do
        assert length(Regex.scan(~r/#{tag}\}/, drawn)) <= 1,
               "#{tag} is drawn more than once on one frame"
      end
    end

    test "and stay pictures on a film that is only a drawing" do
      drawn = Film.drawn_film()

      refute Film.rating_card(drawn) |> inspect(limit: :infinity) =~ ":rate"
      refute Film.note_pencil(drawn) |> inspect(limit: :infinity) =~ ":edit_note"
    end
  end

  defp shelve!(title, providers) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :movie,
      title: title,
      providers: providers,
      runtime_minutes: 155,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :movie,
      status: :watching
    })
  end
end
