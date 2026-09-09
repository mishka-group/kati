defmodule Kati.ResumeTest do
  @moduledoc """
  A screen you come back to re-reads.

  ## The defect

  `Mob.Screen`'s `{:pop}` restores the socket it saved on the way in and
  `mount/3` does not run again, so every write that ends in a back tap was
  invisible until the reader left the stack. Add *Emergence* from screen 11,
  press back, and screen 03 still reads `6 titles · 5 in progress` over six
  posters — reproduced on a Pixel 9a, which is the only place it shows, because
  switching roots at the dock re-mounts and hides it.

  ## What is being asserted, and what only a device can

  Mob's GenServer dispatches each message to the module currently in its state
  and applies a navigation when the handler returns, so a `send(self(), …)`
  queued while screen 11 answers its back tap is delivered after the pop, to
  screen 03. That ordering lives in `deps/mob` and is not this suite's to
  assert; what is asserted here is both halves either side of it — that every
  back control queues the message, and that each screen that reads the store
  answers it by re-reading.

  The join between them was verified on the device, in the commit that added
  this file.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Resume

  @prefix "resume-test-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  doctest Resume, only: [topic: 0]

  describe "pop/1" do
    test "queues the message and then pops" do
      socket = Resume.pop(Mob.Socket.new(Kati.Screens.Library))

      assert socket.__mob__.nav_action == {:pop}
      assert_received {:kati, :resumed, nil}
    end

    test "announce/0 queues it without navigating" do
      assert Resume.announce() == :ok
      assert_received {:kati, :resumed, nil}
    end
  end

  describe "every back control in the app" do
    test "goes through Resume rather than popping directly" do
      # The one thing a unit test can hold about a change made with `sed` over
      # 59 files: that no screen has quietly gone back to the bare call. A
      # `Mob.Socket.pop_screen/1` in `lib/kati/screens` is a back control whose
      # destination will not re-read, and it will be found on a device weeks
      # later as "the number is wrong sometimes".
      direct =
        "lib/kati/screens"
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.filter(&(File.read!(&1) =~ ~r/Mob\.Socket\.pop_screen\(/))
        |> Enum.reject(&(Path.basename(&1) == "resume.ex"))

      assert direct == [],
             "these screens pop without telling the screen underneath to re-read. Use " <>
               "`Kati.Screens.Resume.pop/1`:\n" <> Enum.map_join(direct, "\n", &("  " <> &1))
    end
  end

  describe "screen 03 — the shelf" do
    test "picks up a title added above it" do
      socket = mounted(Kati.Screens.Library)
      assert socket.assigns.titles == []

      tracked!("emergence", "Emergence")

      {:noreply, resumed} = Kati.Screens.Library.handle_kati(:resumed, nil, socket)

      assert Enum.map(resumed.assigns.titles, & &1.title) == ["Emergence"]
    end

    test "and keeps the filter the reader chose" do
      socket =
        Kati.Screens.Library
        |> mounted()
        |> Mob.Socket.assign(:filter, "Finished")
        |> Mob.Socket.assign(:shelf, "Books")

      {:noreply, resumed} = Kati.Screens.Library.handle_kati(:resumed, nil, socket)

      assert resumed.assigns.filter == "Finished"
      assert resumed.assigns.shelf == "Books"
    end
  end

  describe "screen 01 — Home" do
    test "picks up a title added under it" do
      socket = mounted(Kati.Screens.Home)
      assert socket.assigns.continue == []

      tracked!("emergence", "Emergence")

      {:noreply, resumed} = Kati.Screens.Home.handle_kati(:resumed, nil, socket)

      assert Enum.map(resumed.assigns.continue, & &1.title) == ["Emergence"]
    end
  end

  describe "screen 10 — Up next" do
    test "picks up a title added under it" do
      socket = mounted(Kati.Screens.UpNext)
      before = socket.assigns.queue

      tracked!("emergence", "Emergence")

      {:noreply, resumed} = Kati.Screens.UpNext.handle_kati(:resumed, nil, socket)

      refute resumed.assigns.queue == before
    end
  end

  describe "the two hand-rolled pages" do
    test "screen 08 re-reads the film it is drawing" do
      {:ok, socket} = Kati.Screens.Film.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.Film))

      {:noreply, resumed} =
        Kati.Screens.Film.handle_info({:kati, :resumed, nil}, socket)

      assert resumed.assigns.film.title == socket.assigns.film.title
    end

    test "screen 04 re-reads the series it is drawing" do
      {:ok, socket} = Kati.Screens.Series.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.Series))

      {:noreply, resumed} =
        Kati.Screens.Series.handle_info({:kati, :resumed, nil}, socket)

      assert resumed.assigns.series.title == socket.assigns.series.title
    end
  end

  describe "screen 92 — My services" do
    test "picks up a country chosen on screen 94" do
      socket = mounted(Kati.Screens.MyServices)
      before = socket.assigns.region

      # Restored inside the test, not in `on_exit`: `Mob.ScreenCase` stops
      # `Mob.State` around each one, and a `put_region/1` in the callback exits
      # rather than raising — `Kati.Media.SearchDebounce.ask/2` documents that
      # named-GenServer shape at length.
      Kati.Services.put_region("PT")

      {:noreply, resumed} = Kati.Screens.MyServices.handle_kati(:resumed, nil, socket)

      refute resumed.assigns.region == before
      assert resumed.assigns.region == "PT"

      Kati.Services.put_region(before)
    end

    test "and keeps what the reader typed into the filter" do
      socket =
        Kati.Screens.MyServices
        |> mounted()
        |> Mob.Socket.assign(:query, "lum")

      {:noreply, resumed} = Kati.Screens.MyServices.handle_kati(:resumed, nil, socket)

      assert resumed.assigns.query == "lum"
    end
  end

  defp mounted(module) do
    {:ok, socket} = module.mount(%{}, %{}, Mob.Socket.new(module))
    socket
  end

  defp tracked!(slug, title) do
    source_id = @prefix <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: title,
      episode_count: 13,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching
    })
  end
end
