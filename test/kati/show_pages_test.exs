defmodule Kati.ShowPagesTest do
  @moduledoc """
  The ⋯ disc on the two per-show sub-pages.

  Screens 34 and 35 each draw the same ⋯ glyph, in the same place, as screen
  04's — where it opens a menu — and theirs opened nothing.
  `Kati.UI.SettingsList.chrome/2` built a themed icon with no `on_tap`, so it
  reached no handler and `Kati.ScreenTapSweepTest` could not see it either: a
  dead control nothing in the suite had an opinion about.

  It still cannot see it, and for the reason it could not see screen 35's
  status tiles: the sweep renders against an empty store, where there is no
  show to open a sibling page over and the disc is deliberately drawn without
  a tap. So the taps are pressed here, over a real row.

  Two claims:

    * **The disc opens the OTHER per-show pages**, never its own, and each row
      pushes the show the page is already about with a back label naming this
      page rather than *Series*.
    * **Over the drawing it opens nothing**, because a menu whose every row
      would push a bare screen is worse than the picture it replaced.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Screens.ShowPages, only: [items: 1]

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Season
  alias Kati.Screens.SeriesSettings
  alias Kati.Screens.ShowPages

  @prefix "show-pages-"

  setup do
    on_exit(fn ->
      # Child first: a watch carries the only foreign key in the domain, and a
      # tick made here is exactly what the last test in this file leaves behind.
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM cached_episodes WHERE title_source_id LIKE ?1", [
        @prefix <> "%"
      ])

      Kati.Repo.query!("DELETE FROM cached_seasons WHERE title_source_id LIKE ?1", [
        @prefix <> "%"
      ])

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    %{tracked: tracked!()}
  end

  describe "which rows a page offers" do
    test "never its own, so the menu cannot send you where you already are" do
      refute Enum.any?(ShowPages.items(Season), &(&1.tag == :go_episode_order))
      refute Enum.any?(ShowPages.items(SeriesSettings), &(&1.tag == :go_show_settings))
    end

    test "and never screen 04, which is where the back pill goes" do
      for screen <- [Season, SeriesSettings, Kati.Screens.SeriesMeta] do
        assert length(ShowPages.items(screen)) == 2
      end
    end
  end

  describe "the disc on screen 35" do
    test "opens the menu, and the menu closes again", %{tracked: tracked} do
      socket = settings_socket(tracked)

      {:noreply, open} = SeriesSettings.handle_tap(:toggle_menu, socket)
      assert open.assigns.menu?

      {:noreply, shut} = SeriesSettings.handle_tap(:close_menu, open)
      refute shut.assigns.menu?
    end

    test "and its rows push the show this page is about", %{tracked: tracked} do
      socket = settings_socket(tracked)

      {:noreply, pushed} = SeriesSettings.handle_tap(:go_episode_order, socket)

      assert {:push, Season, %{title_id: id, back: "Show settings"}} = nav(pushed)
      assert id == tracked.id
      refute pushed.assigns.menu?
    end

    test "and Show details is handed the id screen 14 reads", %{tracked: tracked} do
      {:noreply, pushed} =
        SeriesSettings.handle_tap(:go_show_details, settings_socket(tracked))

      assert {:push, Kati.Screens.SeriesMeta, %{id: id, back: "Show settings"}} = nav(pushed)
      assert id == tracked.id
    end

    test "and a season-pass tag still reaches the write it always did", %{tracked: tracked} do
      {:noreply, after_tap} =
        SeriesSettings.handle_tap(:pass_notify_new_episodes, settings_socket(tracked))

      refute Ash.get!(TrackedTitle, tracked.id).notify_new_episodes
      refute after_tap.assigns.menu?
    end
  end

  describe "the disc on screen 34" do
    test "opens the sibling pages, carrying this season's show", %{tracked: tracked} do
      socket = season_socket(tracked)

      {:noreply, pushed} = Season.handle_tap(:go_show_settings, socket)

      assert {:push, SeriesSettings, %{tracked_id: id, back: "Episode order"}} = nav(pushed)
      assert id == tracked.id
    end

    test "and an episode tap is still an episode tap", %{tracked: tracked} do
      socket = season_socket(tracked)

      {:noreply, after_tap} = Season.handle_tap(:episode_0, socket)

      assert nav(after_tap) == nil
      assert after_tap.assigns.save_error == nil
      assert hd(after_tap.assigns.season.episodes).watched
    end
  end

  describe "over the drawing" do
    test "the disc is a picture on both screens, because there is nothing to open" do
      for {screen, drawn} <- [
            {Season, drawn_season_tree()},
            {SeriesSettings, drawn_settings_tree()}
          ] do
        refute drawn =~ "toggle_menu", "#{inspect(screen)} draws a live ⋯ over the board"
      end
    end

    test "and a menu tag reaches nothing rather than pushing a bare screen" do
      socket =
        SeriesSettings
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:show, SeriesSettings.show(%{}))
        |> Mob.Socket.assign(:menu?, false)

      {:noreply, after_tap} = SeriesSettings.handle_tap(:go_episode_order, socket)

      assert nav(after_tap) == nil
    end
  end

  defp nav(socket) do
    case Map.get(socket.__mob__, :nav_action) do
      {:push, module, params} -> {:push, module, params}
      _no_push -> nil
    end
  end

  defp settings_socket(tracked) do
    SeriesSettings
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:show, SeriesSettings.show(%{tracked_id: tracked.id}))
    |> Mob.Socket.assign(:menu?, false)
  end

  defp season_socket(tracked) do
    Season
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:params, %{title_id: tracked.id, season: 1})
    |> Mob.Socket.assign(:season, Season.season(%{title_id: tracked.id, season: 1}))
    |> Mob.Socket.assign(:save_error, nil)
    |> Mob.Socket.assign(:menu?, false)
  end

  defp drawn_season_tree do
    inspect(Season.content(%{season: Season.drawn_season(), menu?: false}),
      limit: :infinity,
      printable_limit: :infinity
    )
  end

  defp drawn_settings_tree do
    inspect(SeriesSettings.content(%{show: SeriesSettings.show(%{}), menu?: false}),
      limit: :infinity,
      printable_limit: :infinity
    )
  end

  defp tracked! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Tidewrack",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(Kati.Media.CachedEpisode, %{
      source: :tmdb,
      title_source_id: @prefix <> "title",
      source_id: @prefix <> "ep1",
      season_number: 1,
      episode_number: 1,
      title: "Saltmarsh",
      runtime_minutes: 50,
      air_at: DateTime.add(Kati.Time.now(), -30 * 24 * 60 * 60, :second),
      date_confidence: :exact,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      status: :watching,
      progress_season: 1
    })
  end
end
