defmodule Kati.FilmLogEditTest do
  @moduledoc """
  N56: the rating card on a film that already has a logged watch opens that
  watch in screen 33 to be edited — its stars, review, spoiler flag, date,
  where, who with and tags — and Save updates that row. *Log rewatch* in the
  ⋯ is still a new, blank viewing, and a film with nothing logged still opens
  a blank first log. An episode already rated opens screen 144 on its rating.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Film
  alias Kati.Screens.Rating

  @tables ~w(media_events media_watches tracked_titles cached_episodes cached_seasons cached_titles)

  setup do
    Kati.Locale.put(:en)
    wipe!()
    on_exit(&wipe!/0)
    :ok
  end

  describe "the rating card on a film with a watch" do
    test "pushes screen 33 on that watch, drawn with what was saved" do
      film = a_film!()
      watch = a_watch!(film)

      opened = film |> film_page() |> render_info({:tap, :rate})

      assert {:push, Rating, params} = opened.socket.__mob__.nav_action
      assert params[:watch_id] == watch.id
      assert params[:tracked_title_id] == film.id
      refute params[:new]

      sheet = mount_screen(Rating, params)
      drawn = texts(sheet)

      assert assigns(sheet).watch_id == watch.id
      assert assigns(sheet).watch.rating == 4.0
      assert review_field(sheet) == "Held up on a second look."
      assert assigns(sheet).watch.spoilers
      assert assigns(sheet).watch.watched_on == ~D[2026-09-01]
      assert assigns(sheet).watch.place == "Home"
      assert assigns(sheet).watch.companions == "Jo"
      assert assigns(sheet).watch.tags == ["cosy"]

      assert Rating.edit_heading() in drawn, "an edit of a log was headed as a new one"
      refute "Log a watch" in drawn
    end

    test "Save updates that watch rather than adding another" do
      film = a_film!()
      watch = a_watch!(film)

      params = film |> film_page() |> render_info({:tap, :rate}) |> nav_params()
      sheet = mount_screen(Rating, params)
      sheet = render_info(sheet, {:change, :review, "Better every time."})
      _saved = render_info(sheet, {:tap, :save})

      assert [only] = watches_of(film)
      assert only.id == watch.id
      assert only.review == "Better every time."
      assert only.rating == 8, "the stars were lost on the edit"
      assert only.place == "Home"
    end

    test "the newest of two watches is the one opened" do
      film = a_film!()
      _older = a_watch!(film, watched_on: ~D[2026-08-01], review: "First time.")
      newer = a_watch!(film, watched_on: ~D[2026-09-10], review: "Second time.", rewatch: 2)

      params = film |> film_page() |> render_info({:tap, :rate}) |> nav_params()
      assert params[:watch_id] == newer.id
      assert review_field(mount_screen(Rating, params)) == "Second time."
    end

    test "the note pencil opens the watch its note is from" do
      film = a_film!()
      watch = a_watch!(film)

      params = film |> film_page() |> render_info({:tap, :edit_note}) |> nav_params()
      assert params[:watch_id] == watch.id
    end
  end

  describe "a new viewing" do
    test "Log rewatch in the ⋯ is still a blank sheet, and Save adds a row" do
      film = a_film!()
      _watch = a_watch!(film)

      params = film |> film_page() |> render_info({:tap, :log_watch}) |> nav_params()
      assert params[:new] == true
      refute params[:watch_id]

      sheet = mount_screen(Rating, params)
      assert assigns(sheet).watch_id == nil
      assert assigns(sheet).watch.review == ""
      assert assigns(sheet).watch.rewatch == "1st rewatch"
      refute Rating.edit_heading() in texts(sheet)

      sheet = render_info(sheet, {:change, :review, "Third look."})
      _saved = render_info(sheet, {:tap, :save})

      assert length(watches_of(film)) == 2
    end

    test "a film with nothing logged opens a blank first log from the rating card" do
      film = a_film!()

      params = film |> film_page() |> render_info({:tap, :rate}) |> nav_params()
      refute params[:watch_id]

      sheet = mount_screen(Rating, params)
      assert assigns(sheet).watch_id == nil
      assert assigns(sheet).watch.live?
      assert "Log a watch" in texts(sheet)
      refute Rating.edit_heading() in texts(sheet)
    end
  end

  describe "an episode already rated" do
    test "opens screen 144 on its saved rating" do
      film = a_film!(:tv)

      Ash.create!(Watch, %{
        tracked_title_id: film.id,
        episode_source_id: "n56-ep-1",
        season_number: 1,
        episode_number: 1,
        rating: 6,
        watched_on: ~D[2026-09-01]
      })

      sheet =
        mount_screen(Kati.Screens.RateEpisode, %{
          tracked_id: film.id,
          episode_source_id: "n56-ep-1"
        })

      assert assigns(sheet).sheet.rating == 3.0, "a rated episode opened on no rating"
    end
  end

  defp film_page(film), do: mount_screen(Film, %{id: film.id})

  defp nav_params(view) do
    assert {:push, Rating, params} = view.socket.__mob__.nav_action
    params
  end

  defp a_film!(kind \\ :movie) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: "n56-#{kind}",
      kind: kind,
      title: "Arrival",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: "n56-#{kind}",
      kind: kind,
      status: :finished
    })
  end

  defp a_watch!(film, opts \\ []) do
    on = Keyword.get(opts, :watched_on, ~D[2026-09-01])

    Ash.create!(Watch, %{
      tracked_title_id: film.id,
      rating: 8,
      review: Keyword.get(opts, :review, "Held up on a second look."),
      contains_spoilers: true,
      watched_on: on,
      watched_at: DateTime.new!(on, ~T[20:00:00], "Etc/UTC"),
      place: "Home",
      companions: "Jo",
      tags: "cosy",
      rewatch_number: Keyword.get(opts, :rewatch)
    })
  end

  defp watches_of(film) do
    Watch |> Ash.read!() |> Enum.filter(&(&1.tracked_title_id == film.id))
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end

  defp review_field(view) do
    view
    |> flatten()
    |> Enum.find_value(fn node ->
      case Map.get(node, :props) || %{} do
        %{accessibility_id: "review", value: value} -> value
        _other -> nil
      end
    end)
  end

  defp texts(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end
end
