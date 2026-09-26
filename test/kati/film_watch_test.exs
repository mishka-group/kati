Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.FilmWatchTest do
  @moduledoc """
  Marking a film watched — which nothing in the app could do.

  `Kati.Screens.Rating.save_watch/1` only ever ran `Ash.update/1` against a
  `Kati.Media.Watch` that already existed, and `%{watch_id: nil}` was a flat
  refusal. `grep -rn "Ash.create(Kati.Media.Watch" lib/` returned nothing at
  all, so the FIRST watch of a film could not be recorded — and with it went
  the rating, the review, the Activity log and Your year's Films count, each of
  which reads rows nothing could make.

  Screen 08's *Log a watch* has always pushed this sheet with the film's
  tracked id. The sheet looked the id up, used it to find an existing log, and
  then threw it away.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Screens.Rating, only: [params_for: 1, params_for: 2, scale_options: 0]

  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Rating

  @prefix "film-watch-test-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  defp a_film! do
    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: @prefix <> Integer.to_string(System.unique_integer([:positive])),
      kind: :movie,
      status: :watching
    })
  end

  defp rewatch_sheet(film) do
    params = Rating.params_for(%{tracked_id: film.id}, :new)
    {:ok, sheet} = Rating.mount(params, %{}, Mob.Socket.new(Rating))
    sheet
  end

  defp watches_for(id) do
    Watch |> Ash.read!() |> Enum.filter(&(&1.tracked_title_id == id))
  end

  describe "the first watch of a film" do
    test "is created, with the night it is being logged for" do
      film = a_film!()

      assert [] = watches_for(film.id)

      assert {:ok, watch} =
               Rating.save_watch(%{
                 watch_id: nil,
                 tracked_title_id: film.id,
                 watch: %{rating: 4.5, review: "Held up."}
               })

      assert watch.tracked_title_id == film.id
      assert watch.rating == 9, "4.5 stars is 9 on the ten-point scale the store keeps"
      assert watch.review == "Held up."
      assert watch.watched_on == Kati.Time.today()
      assert watch.watched_at

      assert [_one] = watches_for(film.id)
    end

    test "a rating with no review is a watch, not a refusal" do
      film = a_film!()

      assert {:ok, watch} =
               Rating.save_watch(%{
                 watch_id: nil,
                 tracked_title_id: film.id,
                 watch: %{rating: 3.0, review: ""}
               })

      assert watch.rating == 6
      refute watch.review, "an empty review is stored as nothing, not as a blank string"
    end

    test "and the second save updates that watch rather than making another" do
      film = a_film!()

      {:ok, first} =
        Rating.save_watch(%{
          watch_id: nil,
          tracked_title_id: film.id,
          watch: %{rating: 3.0, review: nil}
        })

      {:ok, again} =
        Rating.save_watch(%{
          watch_id: first.id,
          tracked_title_id: film.id,
          watch: %{rating: 5.0, review: "Better second time."}
        })

      assert again.id == first.id
      assert again.rating == 10
      assert [_only_one] = watches_for(film.id)
    end
  end

  describe "what it still refuses" do
    test "a sheet naming a title that is gone writes nothing" do
      # `Kati.ScreenWriteTargetTest` refused the first version of this clause
      # for exactly this: a sheet pushed with an id whose row has since been
      # deleted was still creating a watch hanging off a title that is not
      # there. Its rule is *refuse when the named row is gone*.
      before = Watch |> Ash.read!() |> length()

      assert {:error, _why} =
               Rating.save_watch(%{
                 watch_id: nil,
                 tracked_title_id: Ash.UUID.generate(),
                 watch: %{rating: 4.0, review: "x"}
               })

      assert Watch |> Ash.read!() |> length() == before
    end

    test "the drawing, which names no title at all, writes nothing" do
      before = Watch |> Ash.read!() |> length()

      assert {:error, _why} = Rating.save_watch(%{watch_id: nil})

      assert Watch |> Ash.read!() |> length() == before
    end
  end

  describe "the sheet a film with no log opens on" do
    test "is about that film, not about the drawing" do
      # On a Pixel 9a, pressing *Log a watch* on **Arrival** opened a sheet
      # about **Blue Hour**: its poster, its `2nd rewatch`, its review, its
      # tags, its `Watched on Sun 16 Aug`, its `With Jo`. Save would then have
      # written all of it against Arrival's id.
      film = a_film!()

      {:ok, socket} = Rating.mount(%{tracked_title_id: film.id}, %{}, Mob.Socket.new(Rating))

      draft = socket.assigns.watch
      drawn = Kati.DesignLiterals.rating_board()

      refute draft.title == drawn.title, "the sheet opened on the drawing's film"
      refute draft.rewatch, "a first watch was called a rewatch"
      refute draft.rating, "it arrived pre-rated"
      assert draft.review == ""
      assert draft.tags == []
      assert draft.context == [], "it claimed a night, a place and a companion"
      assert socket.assigns.watch_id == nil
      assert socket.assigns.tracked_title_id == film.id
    end

    test "with nothing named at all it is an empty sheet" do
      # Pushed with no params there is no film to rate, so the sheet opens on
      # its own empty state. It used to open on `Kati.DesignLiterals.rating_board/0` —
      # a sheet already carrying Blue Hour's rating, review and three context
      # rows over a reader who had named nothing.
      {:ok, socket} = Rating.mount(%{}, %{}, Mob.Socket.new(Rating))

      assert blank(socket.assigns.watch) == blank(Rating.empty_watch())
      assert socket.assigns.watch_id == nil
    end

    test "an id that names nothing is empty rather than somebody else's film" do
      {:ok, socket} =
        Rating.mount(%{tracked_title_id: Ash.UUID.generate()}, %{}, Mob.Socket.new(Rating))

      assert blank(socket.assigns.watch) == blank(Rating.empty_watch())
      assert socket.assigns.watch_id == nil
    end

    test "blank_for/1 answers nil for a row that is gone" do
      assert Rating.blank_for(Ash.UUID.generate()) == nil
    end
  end

  describe "screen 08 hands the sheet what it needs" do
    test "Log a watch carries the film's tracked id" do
      assert Rating.params_for(%{tracked_id: "abc"}) == %{tracked_title_id: "abc"}
      assert Rating.params_for(%{}) == %{}
    end

    test "and the sheet keeps it, which is what makes a create possible" do
      film = a_film!()

      {:ok, socket} =
        Rating.mount(%{tracked_title_id: film.id}, %{}, Mob.Socket.new(Rating))

      assert socket.assigns.tracked_title_id == film.id,
             "the sheet looked the id up and threw it away, which is the whole defect"
    end
  end

  describe "logging from screen 08" do
    test "the one ⋯ item on a seen film edits the saved watch, and Save changes it in place" do
      # The owner, 26 Sep: one logging item, which shows the current data. Log
      # rewatch — a blank second sheet — is no longer on screen 08.
      film = a_film!()
      rated = Ash.create!(Watch, %{tracked_title_id: film.id, rating: 8, review: "First."})

      page =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, Kati.Screens.Film.film(film.id))

      assert %{tag: :rate} = item = Kati.Screens.Film.log_item(page.assigns.film)
      refute inspect(item) =~ "rewatch"

      {:noreply, pushed} = Kati.Screens.Film.handle_info({:tap, :rate}, page)
      {:push, Rating, params} = Map.get(pushed.__mob__, :nav_action)
      {:ok, sheet} = Rating.mount(params, %{}, Mob.Socket.new(Rating))

      assert sheet.assigns.watch_id == rated.id
      assert sheet.assigns.watch.review == "First."

      {:noreply, starred} = Rating.handle_info({:tap, :star_7}, sheet)
      {:noreply, _saved} = Rating.handle_info({:tap, :save}, starred)

      assert [only] = watches_for(film.id)
      assert only.id == rated.id
      assert only.rating == 7
    end

    test "the badge counts rewatches, one behind the viewings the store keeps" do
      film = a_film!()
      Ash.create!(Watch, %{tracked_title_id: film.id, rating: 8})
      assert rewatch_sheet(film).assigns.watch.rewatch == "1st rewatch"

      Ash.create!(Watch, %{tracked_title_id: film.id, rating: 6, rewatch_number: 2})
      sheet = rewatch_sheet(film)
      assert sheet.assigns.watch.rewatch == "2nd rewatch"

      {:noreply, starred} = Rating.handle_info({:tap, :star_7}, sheet)
      {:noreply, _saved} = Rating.handle_info({:tap, :save}, starred)

      assert film.id |> watches_for() |> Enum.map(& &1.rewatch_number) |> Enum.sort() ==
               [2, 3, nil],
             "the column counts viewings, so the 2nd rewatch is stored as 3"

      assert Kati.Screens.Film.film(film.id).seen == "3 times"
    end

    test "the Persian badge names the rewatch, not the viewing" do
      film = a_film!()
      Ash.create!(Watch, %{tracked_title_id: film.id, rating: 8})

      Kati.Locale.as(:fa, fn ->
        assert rewatch_sheet(film).assigns.watch.rewatch == "بازتماشای اول",
               "board 297 spells the ordinal after the noun"
      end)
    end

    test "reads Log a watch on a film nobody has seen" do
      film = a_film!()

      assert inspect(Kati.Screens.Film.log_item(Kati.Screens.Film.film(film.id)),
               limit: :infinity
             ) =~ "Log a watch"
    end

    test "the rating card rates the watch already there rather than adding one" do
      film = a_film!()
      bare = Ash.create!(Watch, %{tracked_title_id: film.id, watched_on: ~D[2026-09-01]})

      page =
        Kati.Screens.Film
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:film, Kati.Screens.Film.film(film.id))

      {:noreply, pushed} = Kati.Screens.Film.handle_info({:tap, :rate}, page)
      {:push, Rating, params} = Map.get(pushed.__mob__, :nav_action)
      {:ok, sheet} = Rating.mount(params, %{}, Mob.Socket.new(Rating))

      assert sheet.assigns.watch_id == bare.id

      {:noreply, starred} = Rating.handle_info({:tap, :star_9}, sheet)
      {:noreply, _saved} = Rating.handle_info({:tap, :save}, starred)

      assert [only] = watches_for(film.id)
      assert only.rating == 9
    end
  end

  # `watched_at` is stamped at the moment it is read, so two calls a
  # microsecond apart are unequal over a field neither branch chose.
  defp blank(watch), do: Map.drop(watch, [:watched_at])
end
