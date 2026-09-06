defmodule Kati.SeriesSettingsTest do
  @moduledoc """
  Screen 35, the settings page that saved nothing.

  MOVIES-AND-TV.md #99: eleven rows, three tiles and four switches, every one
  of them without an `on_tap`. Four of the switches sat directly over columns
  `Kati.Media.TrackedTitle` had carried since it was written — with the
  drawing's own four positions as their defaults — and the three Status tiles
  over `TrackedTitle.status`, which takes exactly those three values.

  What kept them frozen was a rule, not a missing schema: half of the screen
  would have become the reader's own and half would have stayed a picture,
  which is the arrangement `Kati.Screens.Series` rejects. The rule holds and it
  named the wrong unit — the half with no schema is two whole GROUPS, and a
  group with nothing behind it is dropped. So the assertions here come in
  pairs: what the tiles and switches now write, and what the page stops drawing
  the moment it has a real show to draw it for.

  `Kati.ScreenTapSweepTest` can see none of this. It renders against an empty
  store, where `show/1` answers the board and every tile and switch answers
  `nil` — the sweep's own blind spot, a screen whose controls exist only over
  data. Hence the real row below, and the taps pressed against it.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.SeriesSettings

  @prefix "series-settings-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    %{tracked: tracked!()}
  end

  describe "the show the page is about" do
    test "is the one the ⋯ row was opened over", %{tracked: tracked} do
      show = SeriesSettings.show(%{tracked_id: tracked.id})

      assert show.title == "Severance"
      assert show.tracked.id == tracked.id
    end

    test "and is the drawing's when the push named nobody" do
      show = SeriesSettings.show(%{})

      assert show.tracked == nil
      assert show.title == Kati.SeriesSettings.Sample.show().title
    end

    test "and is the drawing's when the push named a show that has gone" do
      assert SeriesSettings.show(%{tracked_id: Ecto.UUID.generate()}).tracked == nil
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

    test "and a drawn series hands it nothing, so it draws the board" do
      socket =
        Kati.Screens.Series
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:series, Kati.Screens.Series.drawn_series())
        |> Mob.Socket.assign(:menu?, true)

      {:noreply, pushed} = Kati.Screens.Series.handle_info({:tap, :open_settings}, socket)

      assert {:push, SeriesSettings, %{}} = Map.get(pushed.__mob__, :nav_action)
    end
  end

  describe "the three Status tiles" do
    test "light from the row rather than from the fixture", %{tracked: tracked} do
      lit = fn show ->
        show |> SeriesSettings.status_tiles() |> Enum.find(& &1.on) |> Map.get(:label)
      end

      assert lit.(SeriesSettings.show(%{tracked_id: tracked.id})) == "Watching"

      tracked |> Ash.Changeset.for_update(:update, %{status: :dropped}) |> Ash.update!()

      assert lit.(SeriesSettings.show(%{tracked_id: tracked.id})) == "Dropped"
    end

    test "write the status they name", %{tracked: tracked} do
      {:noreply, socket} = press(tracked, :status_Paused)

      assert socket.assigns.show.tracked.status == :paused
      assert Ash.get!(TrackedTitle, tracked.id).status == :paused
    end

    test "and the one already lit writes the same value rather than going dead", %{
      tracked: tracked
    } do
      {:noreply, socket} = press(tracked, :status_Watching)

      assert socket.assigns.show.tracked.status == :watching
      assert Ash.get!(TrackedTitle, tracked.id).status == :watching
    end

    test "all three carry a tap over a real show, not only the one already lit", %{
      tracked: tracked
    } do
      # The whole finding restated for one clause: `status/1` has an on-state
      # arm and an off-state arm, and the off-state arm computed the tap and
      # then drew a `Box` without it. Two of the three tiles were dead, which
      # is the two you press to CHANGE anything. Asserted on the drawn tree
      # rather than on `status_tap/1`, because `status_tap/1` was right.
      taps =
        %{tracked_id: tracked.id}
        |> SeriesSettings.show()
        |> SeriesSettings.status_tiles()
        |> Enum.map(&Map.get(SeriesSettings.status(&1).props, :on_tap))

      assert [{_a, :status_Watching}, {_b, :status_Paused}, {_c, :status_Dropped}] = taps
    end

    test "are drawn without taps over the board, so nothing can be written onto it" do
      Enum.each(SeriesSettings.status_tiles(SeriesSettings.show(%{})), fn tile ->
        assert SeriesSettings.status_tap(tile) == nil
        assert Map.get(SeriesSettings.status(tile).props, :on_tap) == nil
      end)
    end
  end

  describe "the four season-pass switches" do
    test "read the columns that had no reader", %{tracked: tracked} do
      tracked
      |> Ash.Changeset.for_update(:update, %{
        auto_add_new_seasons: false,
        hide_unwatched_titles: true
      })
      |> Ash.update!()

      assert [false, true, true, true] =
               %{tracked_id: tracked.id}
               |> SeriesSettings.show()
               |> SeriesSettings.season_pass()
               |> Enum.map(fn %{control: {:switch, on?}} -> on? end)
    end

    test "flip the column they sit over, and only that one", %{tracked: tracked} do
      {:noreply, _socket} = press(tracked, :pass_notify_new_episodes)

      fresh = Ash.get!(TrackedTitle, tracked.id)

      refute fresh.notify_new_episodes
      assert fresh.auto_add_new_seasons
      assert fresh.add_air_dates_to_calendar
      refute fresh.hide_unwatched_titles
    end

    test "and the flip survives leaving the screen and coming back", %{tracked: tracked} do
      {:noreply, _socket} = press(tracked, :pass_hide_unwatched_titles)

      assert %{control: {:switch, true}, tap: {_pid, :pass_hide_unwatched_titles}} =
               %{tracked_id: tracked.id}
               |> SeriesSettings.show()
               |> SeriesSettings.season_pass()
               |> List.last()
    end

    test "carry no tags at all over the board", %{tracked: _tracked} do
      Enum.each(SeriesSettings.season_pass(SeriesSettings.show(%{})), fn row ->
        refute Map.has_key?(row, :tap)
      end)
    end
  end

  describe "the two groups with nothing behind them" do
    test "are drawn whole over the board", %{tracked: _tracked} do
      board = drawn(SeriesSettings.show(%{}))

      assert board =~ "REGION & AVAILABILITY"
      assert board =~ "THIS SHOW"
      assert board =~ "Preferred quality"
    end

    test "and are dropped over a real show rather than left as a picture", %{tracked: tracked} do
      page = drawn(SeriesSettings.show(%{tracked_id: tracked.id}))

      refute page =~ "REGION & AVAILABILITY"
      refute page =~ "THIS SHOW"
      refute page =~ "Preferred quality"
      refute page =~ "Remove from library"
    end

    test "so what is left on a real show is the two the reader owns", %{tracked: tracked} do
      page = drawn(SeriesSettings.show(%{tracked_id: tracked.id}))

      assert page =~ "STATUS"
      assert page =~ "SEASON PASS"
      assert page =~ "Auto-add new seasons"
      assert page =~ "Severance"
    end
  end

  describe "a write the store refuses" do
    test "leaves the screen showing what the store still holds", %{tracked: tracked} do
      socket = socket_over(tracked)
      Ash.destroy!(tracked)

      {:noreply, after_tap} = SeriesSettings.handle_tap(:status_Dropped, socket)

      assert after_tap.assigns.show.tracked.status == :watching
    end

    test "and a tag this screen does not own changes nothing", %{tracked: tracked} do
      {:noreply, socket} = press(tracked, :pass_not_a_column)

      assert socket.assigns.show.tracked.status == :watching
      assert Ash.get!(TrackedTitle, tracked.id).status == :watching
    end
  end

  defp press(tracked, tag), do: SeriesSettings.handle_tap(tag, socket_over(tracked))

  defp socket_over(tracked) do
    SeriesSettings
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:show, SeriesSettings.show(%{tracked_id: tracked.id}))
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
