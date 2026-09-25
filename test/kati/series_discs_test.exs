defmodule Kati.SeriesDiscsTest do
  @moduledoc """
  Screen 04's two discs beside *Mark next watched*.

  They were drawn at button size, with a card fill and a
  lift, and carried no tap — so they read as buttons and were not.

  Both were buildable and neither had been built. The star opens screen 33,
  which is the one place a rating is written. The bookmark writes
  `Kati.Media.TrackedTitle.notify_new_episodes` — the column screen 25 is an
  entire page ABOUT, and which nothing anywhere could set for a single show,
  so the watcher's switches were a page about a preference nobody could
  express.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Series

  @prefix "series-discs-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    %{tracked: shelve!()}
  end

  describe "the bookmark disc" do
    test "starts filled, because a show you track is one you are told about", %{tracked: t} do
      assert Series.series(t.id).followed?
    end

    test "writes the column, so screen 25 has something to be about", %{tracked: t} do
      socket = socket_for(t)
      flipped = Series.follow(socket)

      assert {:ok, %{notify_new_episodes: false}} = Ash.get(TrackedTitle, t.id)
      refute flipped.assigns.series.followed?
    end

    test "and flips back", %{tracked: t} do
      t |> socket_for() |> Series.follow() |> Series.follow()

      assert {:ok, %{notify_new_episodes: true}} = Ash.get(TrackedTitle, t.id)
    end

    test "is a control over a real show and a picture over the drawing", %{tracked: t} do
      live = Series.follow_disc(Series.series(t.id)) |> inspect(limit: :infinity)
      drawn = Series.follow_disc(Series.drawn_series()) |> inspect(limit: :infinity)

      assert live =~ ":toggle_follow"
      refute drawn =~ ":toggle_follow"
    end
  end

  describe "the star disc" do
    test "opens the sheet that writes a rating", %{tracked: t} do
      socket = socket_for(t)
      {:noreply, pushed} = Series.handle_info({:tap, :rate_title}, socket)

      assert {:push, Kati.Screens.Rating, %{tracked_title_id: id}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == t.id
    end

    test "and stays a picture over the drawing" do
      drawn = Series.rate_disc(Series.drawn_series()) |> inspect(limit: :infinity)

      refute drawn =~ ":rate_title"
    end
  end

  defp socket_for(tracked) do
    Kati.Screens.Series
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:series, Series.series(tracked.id))
  end

  defp shelve! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Tidewrack",
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
