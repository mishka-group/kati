defmodule Kati.SeriesSettingsTest do
  @moduledoc """
  Screen 35 over a real show: every row a reader sees is that show's own
  column or the reader's own device setting, and every row writes or opens
  something.

  Three faces are pinned — a real show, a show that has gone, and no show at
  all — because the second used to fall to the third: a push whose show had
  been removed drew board 35 whole, *Long Hollow*'s status and all eleven of
  its rows, in front of the reader who had just removed their own show.

  The writes are pressed through `handle_tap/2`, the control a reader presses,
  and read back out of `Kati.Media.TrackedTitle` rather than off the socket,
  because a socket assign is exactly what a control that moves first and
  writes nothing would also produce.

  `Kati.ScreenTapSweepTest` can see none of this: it renders against an empty
  store, where there is no show and every tile and switch is a picture.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.SeriesSettings
  alias Kati.Services.Service

  doctest SeriesSettings,
    only: [params_for: 1, change_for: 2, notify_line: 1, region_line: 1, services_line: 1]

  @prefix "series-settings-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    end)

    %{tracked: tracked!()}
  end

  describe "the show the page is about" do
    test "is the one the ⋯ row was opened over", %{tracked: tracked} do
      show = SeriesSettings.show(%{tracked_id: tracked.id})

      assert show.title == "Severance"
      assert show.tracked.id == tracked.id
    end

    test "is the shelf's newest series when the push named nobody, never the board" do
      show = SeriesSettings.show(%{})

      assert %TrackedTitle{} = show.tracked
      refute Map.get(show, :gone?, false)

      page = drawn(show)
      refute page =~ "Auto-add new seasons"
      refute page =~ "Preferred quality"
      refute page =~ "The Long Hollow"
    end

    test "over a shelf with no series is one sentence and nothing to press" do
      page = drawn(SeriesSettings.empty_show())

      assert page =~ "No series in your library yet"
      refute page =~ "Auto-add new seasons"
      refute page =~ "Preferred quality"
      refute page =~ ":pass_"
      refute page =~ ":status_"
      refute page =~ ":open_region"
      refute page =~ ":toggle_menu"
    end

    test "says the show has gone when the push named one that is not there" do
      show = SeriesSettings.show(%{tracked_id: Ecto.UUID.generate()})

      assert show.gone?
      assert show.tracked == nil

      page = drawn(show)

      assert page =~ "This title is no longer in your library"

      for board_word <- [
            "Auto-add new seasons",
            "Preferred quality",
            "Remove from library",
            "Watching",
            "United Kingdom"
          ] do
        refute page =~ board_word,
               "a push whose show has gone drew the board's #{inspect(board_word)}"
      end

      refute page =~ "on_tap"
    end

    test "and a show removed while the page sat under a sheet is gone on the way back", %{
      tracked: tracked
    } do
      socket = socket_over(tracked)
      Ash.destroy!(tracked)

      {:noreply, back} = SeriesSettings.handle_kati(:resumed, nil, socket)

      assert back.assigns.show.gone?
    end
  end

  describe "the route in" do
    test "screen 04's ⋯ hands this page the show it was drawing", %{tracked: tracked} do
      socket =
        Kati.Screens.Series
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:series, Kati.Screens.Series.series(tracked.id))
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, pushed} = Kati.Screens.Series.handle_info({:tap, :open_settings}, socket)

      assert {:push, SeriesSettings, %{tracked_id: id, back: "Series"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == tracked.id
    end
  end

  describe "the three Status tiles" do
    test "light from the row", %{tracked: tracked} do
      lit = fn show ->
        show |> SeriesSettings.status_tiles() |> Enum.find(& &1.on) |> Map.get(:label)
      end

      assert lit.(SeriesSettings.show(%{tracked_id: tracked.id})) == "Watching"

      tracked |> Ash.Changeset.for_update(:update, %{status: :dropped}) |> Ash.update!()

      assert lit.(SeriesSettings.show(%{tracked_id: tracked.id})) == "Dropped"
    end

    test "write the status they name, and it reads back from the store", %{tracked: tracked} do
      {:noreply, socket} = press(tracked, :status_paused)

      assert socket.assigns.show.tracked.status == :paused
      assert Ash.get!(TrackedTitle, tracked.id).status == :paused
      assert lit_label(tracked) == "Paused"
    end

    test "all three carry a tap over a real show", %{tracked: tracked} do
      taps =
        %{tracked_id: tracked.id}
        |> SeriesSettings.show()
        |> SeriesSettings.status_tiles()
        |> Enum.map(&Map.get(SeriesSettings.status(&1).props, :on_tap))

      assert [{_a, :status_watching}, {_b, :status_paused}, {_c, :status_dropped}] = taps
    end
  end

  describe "the season pass over a real show" do
    test "is the two switches something reads, lit from their columns", %{tracked: tracked} do
      tracked
      |> Ash.Changeset.for_update(:update, %{
        notify_new_episodes: false,
        hide_unwatched_titles: true
      })
      |> Ash.update!()

      rows = SeriesSettings.season_pass(SeriesSettings.show(%{tracked_id: tracked.id}))

      assert Enum.map(rows, & &1.title) == ["Tell me about episodes", "Hide unwatched titles"]
      assert Enum.map(rows, & &1.control) == [{:switch, false}, {:switch, true}]
    end

    test "draws no switch over a column nothing in the app reads", %{tracked: tracked} do
      page = drawn(SeriesSettings.show(%{tracked_id: tracked.id}))

      refute page =~ "Auto-add new seasons"
      refute page =~ "Put air dates on calendar"
      refute page =~ "S4 will appear when announced"
    end

    test "each switch flips its own column, and only that one", %{tracked: tracked} do
      {:noreply, _socket} = press(tracked, :pass_notify_new_episodes)

      fresh = Ash.get!(TrackedTitle, tracked.id)

      refute fresh.notify_new_episodes
      refute fresh.hide_unwatched_titles
      assert fresh.auto_add_new_seasons
      assert fresh.add_air_dates_to_calendar

      {:noreply, _socket} = press(tracked, :pass_hide_unwatched_titles)

      assert Ash.get!(TrackedTitle, tracked.id).hide_unwatched_titles

      assert [{:switch, false}, {:switch, true}] =
               %{tracked_id: tracked.id}
               |> SeriesSettings.show()
               |> SeriesSettings.season_pass()
               |> Enum.map(& &1.control)
    end

    test "a tag for a column the page does not draw writes nothing", %{tracked: tracked} do
      {:noreply, _socket} = press(tracked, :pass_auto_add_new_seasons)

      assert Ash.get!(TrackedTitle, tracked.id).auto_add_new_seasons
    end

    test "the reminder row says when the Release watcher has turned every show off", %{
      tracked: tracked
    } do
      Kati.Settings.Watcher.put_new_episodes(false)

      [notify, _hide] = SeriesSettings.season_pass(SeriesSettings.show(%{tracked_id: tracked.id}))

      assert notify.sub == "New episodes is off in Release watcher"

      Kati.Settings.Watcher.put_new_episodes(true)

      [notify, _hide] = SeriesSettings.season_pass(SeriesSettings.show(%{tracked_id: tracked.id}))

      assert notify.sub == "Inbox only, no push"
    end
  end

  describe "region and services over a real show" do
    test "are the reader's own, not the board's", %{tracked: tracked} do
      page = drawn(SeriesSettings.show(%{tracked_id: tracked.id}))

      assert page =~ "REGION & AVAILABILITY"
      assert page =~ "Pick your country"
      assert page =~ SeriesSettings.services_line(Kati.Services.subscribed_names())
      refute page =~ "United Kingdom"
      refute page =~ "Lumen+"
      refute page =~ "Watch for price drops"
      refute page =~ "Preferred quality"
    end

    test "follow what the reader set, re-read on the way back", %{tracked: tracked} do
      socket = socket_over(tracked)

      Kati.Services.put_region("DE")
      Ash.create!(Service, %{name: @prefix <> "Orbit", tier: :subscribed})

      {:noreply, back} = SeriesSettings.handle_kati(:resumed, nil, socket)

      [region, services] = SeriesSettings.region_rows(back.assigns.show)

      assert region.sub == "Germany"
      assert services.sub =~ @prefix <> "Orbit"
    end

    test "open the pages that set them", %{tracked: tracked} do
      {:noreply, region} = press(tracked, :open_region)

      assert {:push, Kati.Screens.CountryPicker, _} = Map.get(region.__mob__, :nav_action)

      {:noreply, services} = press(tracked, :open_services)

      assert {:push, Kati.Screens.MyServices, %{back: "Show settings"}} =
               Map.get(services.__mob__, :nav_action)
    end
  end

  describe "This show" do
    test "is drawn on no face of the page", %{tracked: tracked} do
      refute drawn(SeriesSettings.empty_show()) =~ "THIS SHOW"

      page = drawn(SeriesSettings.show(%{tracked_id: tracked.id}))

      refute page =~ "THIS SHOW"
      refute page =~ "Remove from library"
      refute page =~ "Reset progress"
    end
  end

  describe "a write the store refuses" do
    test "leaves the screen showing what the store still holds", %{tracked: tracked} do
      socket = socket_over(tracked)
      Ash.destroy!(tracked)

      {:noreply, after_tap} = SeriesSettings.handle_tap(:status_dropped, socket)

      assert after_tap.assigns.show.tracked.status == :watching
    end

    test "and a tag this screen does not own changes nothing", %{tracked: tracked} do
      {:noreply, socket} = press(tracked, :pass_not_a_column)

      assert socket.assigns.show.tracked.status == :watching
      assert Ash.get!(TrackedTitle, tracked.id).status == :watching
    end
  end

  defp lit_label(tracked) do
    %{tracked_id: tracked.id}
    |> SeriesSettings.show()
    |> SeriesSettings.status_tiles()
    |> Enum.find(& &1.on)
    |> Map.get(:label)
  end

  defp press(tracked, tag), do: SeriesSettings.handle_tap(tag, socket_over(tracked))

  defp socket_over(tracked) do
    params = %{tracked_id: tracked.id}

    SeriesSettings
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:params, params)
    |> Mob.Socket.assign(:menu?, false)
    |> Mob.Socket.assign(:show, SeriesSettings.show(params))
  end

  defp drawn(show) do
    inspect(SeriesSettings.content(%{show: show}), limit: :infinity, printable_limit: :infinity)
  end

  defp tracked! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Severance",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      status: :watching
    })
  end
end
