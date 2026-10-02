defmodule Kati.RatingDoorsTest do
  @moduledoc """
  One way to rate on both pages, and one sign that you have (#115).

  The film page's ⋯ opened the rating sheet — rating, review, who you watched
  it with — and the series page's did not: there it was only behind the star.
  Both menus now start with the same row, and both pages draw the star gold
  once the title carries a rating.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Film
  alias Kati.Screens.Series
  alias Kati.Theme.Palette

  @tables ~w(media_events media_watches tracked_titles cached_episodes cached_seasons cached_titles)

  setup do
    Kati.Locale.put(:en)
    wipe!()
    on_exit(&wipe!/0)
    :ok
  end

  describe "the series page" do
    setup do
      %{show: tracked!("dark", "Dark", :tv)}
    end

    test "its ⋯ opens the rating sheet, as the film page's does", %{show: show} do
      page = mount_screen(Series, %{id: show.id}) |> render_info({:tap, :toggle_menu})

      assert "Log a watch" in texts(page)
      assert :rate_title in tap_tags(page)

      {:noreply, socket} = Series.handle_info({:tap, :rate_title}, view_socket(page))
      assert {:push, Kati.Screens.Rating, %{tracked_title_id: id}} = socket.__mob__.nav_action
      assert id == show.id
      refute socket.assigns.menu?, "the menu was still open behind the sheet"
    end

    test "once it is logged the row edits the log", %{show: show} do
      watch!(show, 8)
      page = mount_screen(Series, %{id: show.id}) |> render_info({:tap, :toggle_menu})

      assert "Edit your log" in texts(page)
    end

    test "the star is plain until the show is rated, and gold after", %{show: show} do
      refute gold_star?(Series.rate_disc(Series.series(show.id)))

      watch!(show, 8)
      assert gold_star?(Series.rate_disc(Series.series(show.id)))
    end

    test "an episode's rating is not the show's", %{show: show} do
      Ash.create!(Watch, %{
        tracked_title_id: show.id,
        episode_source_id: "dark-s1e1",
        rating: 9,
        watched_at: DateTime.utc_now()
      })

      refute Series.series(show.id).rated?
    end
  end

  describe "the film page" do
    test "its stars are gold, filled when rated and outlined when not" do
      assert gold_star?(Film.star(:full))
      assert gold_star?(Film.star(:empty))
    end

    test "and its ⋯ row is the same row the series page now has" do
      film = tracked!("arrival", "Arrival", :movie)

      assert %{} = Film.log_item(%{tracked_id: film.id, seen_count: 0})
      assert Film.log_item(%{tracked_id: film.id}, :rate_title) |> inspect() =~ "rate_title"
    end
  end

  defp gold_star?(node),
    do: inspect(node, limit: :infinity) =~ Integer.to_string(Palette.gold_icon())

  defp tracked!(slug, title, kind) do
    source_id = "rating-doors-" <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching
    })
  end

  defp watch!(title, rating) do
    Ash.create!(Watch, %{
      tracked_title_id: title.id,
      rating: rating,
      watched_at: DateTime.utc_now()
    })
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end

  defp view_socket(view), do: view.socket

  defp tap_tags(view) do
    for node <- flatten(view),
        {_pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_atom(tag),
        do: tag
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
