defmodule Kati.UpNextTapsTest do
  @moduledoc """
  Screen 10's controls, which it had none of.

  The audit's finding: *"Screen 10 draws no tappable control at all. The hero
  play disc, the four ready-row play discs, the `tune` disc and every `Drop`
  pill are built without a tap."* On the page whose own board caption calls it
  *the screen the whole app is for*.

  It was invisible to `Kati.ScreenTapSweepTest` by construction, and that is
  worth stating: `ScreenSweep.tap_tags/1` collects the tags a screen DOES
  draw, so a screen with none passes every check in the file. A sweep that
  finds dead controls cannot find missing ones.

  A drawn row carries no id and therefore no tag, so the board's discs stay
  pictures — `nil` is the sweep's own value for *not tappable rather than
  broken*.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.UpNext

  @prefix "up-next-taps-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "with nothing on the shelf" do
    test "the board's discs are pictures, not dead controls" do
      assert UpNext.open_tag(%{id: nil}) == nil
      assert UpNext.open_tap(%{id: nil}) == nil
      assert UpNext.drop_tap(%{id: nil}) == nil
    end
  end

  describe "with a title being watched" do
    test "the hero's disc opens it" do
      tracked = shelve!("Dune", :movie)
      queue = UpNext.queue()

      socket =
        Kati.Screens.UpNext
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:queue, queue)

      pushed = UpNext.open(socket, UpNext.open_tag(queue.hero))

      assert {:push, Kati.Screens.Film, %{id: id, back: "Up next"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == tracked.id
    end

    test "and a series opens the series screen, which is what the design draws" do
      tracked = shelve!("Severance", :tv)
      queue = UpNext.queue()

      socket =
        Kati.Screens.UpNext |> Mob.Socket.new() |> Mob.Socket.assign(:queue, queue)

      pushed = UpNext.open(socket, UpNext.open_tag(queue.hero))

      assert {:push, Kati.Screens.Series, %{id: id}} = Map.get(pushed.__mob__, :nav_action)
      assert id == tracked.id
    end

    test "the disc is drawn with that tap on it" do
      shelve!("Dune", :movie)
      words = drawn()

      assert words =~ "open_"
    end

    test "and the tune disc opens board 167, which is this page's own sheet" do
      socket = Mob.Socket.new(Kati.Screens.UpNext)
      {:noreply, pushed} = UpNext.handle_tap(:open_filters, socket)

      # Not `Kati.Screens.ShelfFilters`, which is what it pushed until board
      # 167 was built. 145 sorts by Recently added, Title, Your rating,
      # Runtime and Release date, and a queue is ordered by none of those —
      # and both sheets wrote one stored key, so choosing `Title` on the shelf
      # silently reordered this page.
      assert {:push, Kati.Screens.UpNextFilters, _} = Map.get(pushed.__mob__, :nav_action)
    end
  end

  describe "a cold row's Drop pill" do
    test "opens the drop sheet over that show, not the newest paused one" do
      tracked = shelve!("Emergence", :tv)
      socket = Mob.Socket.new(Kati.Screens.UpNext)

      {:noreply, pushed} =
        UpNext.handle_tap(String.to_atom("drop_" <> tracked.id), socket)

      assert {:push, Kati.Screens.DropSheet, %{tracked_id: id, back: "Up next"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == tracked.id
    end
  end

  defp drawn do
    {:ok, socket} = UpNext.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.UpNext))

    socket.assigns
    |> UpNext.render()
    |> inspect(limit: :infinity, printable_limit: :infinity)
  end

  defp shelve!(title, kind) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      title: title,
      runtime_minutes: 155,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      status: :watching
    })
  end
end
