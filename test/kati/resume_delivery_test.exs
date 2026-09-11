defmodule Kati.ResumeDeliveryTest do
  @moduledoc """
  `:resumed` reaches the screen underneath, in a real router with real processes.

  ## Why this file exists beside `Kati.ResumeTest`

  `Kati.ResumeTest` asserts the contract — that every back control calls
  `Kati.Screens.Resume.pop/1`, and that a screen implementing
  `handle_kati(:resumed, …)` re-reads. It runs through `Mob.ScreenCase`, which
  calls `mount/3` inline in the TEST process, so `self()` is the test and a
  message sent there is trivially found.

  That is precisely the assumption mob 0.8.0 broke. MOB-146 gave every screen
  its own process and `Mob.Router` now tracks them by pid, so on a device
  `send(self(), …)` from a back tap reaches the screen being LEFT and dies with
  it. Screen 03 went back to saying `0 titles` after an add — the defect
  `Kati.Screens.Resume` was written to fix, back verbatim — and the whole host
  suite stayed green through it.

  So this file drives a real `Mob.Router` with real screen processes and asks
  the only question that distinguishes the two: after a push and a pop, did the
  screen that is now on top hear `:resumed`?
  """
  use ExUnit.Case, async: false

  setup do
    # `Kati.Theme.activate/0` inside `Resume.pop/1` reads `Mob.State`, which is
    # a dets table. `Mob.ScreenCase` starts it for the same reason; this file
    # does not use that case, so it starts it itself.
    if Process.whereis(Mob.State) == nil, do: start_supervised!(Mob.State)
    :ok
  end

  defmodule Bottom do
    @moduledoc false
    use Mob.Screen
    import Mob.Sigil

    def mount(_params, _session, socket) do
      {:ok, Mob.Socket.assign(socket, :resumes, 0)}
    end

    def render(assigns) do
      assigns = %{n: assigns.resumes}
      ~MOB"<Text text={Integer.to_string(@n)} />"
    end

    # The topic-addressed shape `Kati.Screens.Root` documents: a screen that
    # cares answers, a screen that does not drops it.
    def handle_info({:kati, :resumed, _payload}, socket) do
      {:noreply, Mob.Socket.assign(socket, :resumes, socket.assigns.resumes + 1)}
    end

    def handle_info({:go, dest}, socket), do: {:noreply, Mob.Socket.push_screen(socket, dest)}
    def handle_info(_message, socket), do: {:noreply, socket}
  end

  defmodule Top do
    @moduledoc false
    use Mob.Screen
    import Mob.Sigil

    def mount(_params, _session, socket), do: {:ok, socket}
    def render(assigns) do
      assigns = %{label: "top"}
      ~MOB"<Text text={@label} />"
    end

    # The one line under test: every back control in Kati goes through it.
    def handle_info(:back, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}
    def handle_info(_message, socket), do: {:noreply, socket}
  end

  # The router applies a navigation asynchronously (0.8.0), so a bare assert
  # after `send/2` races it.
  defp until(fun, tries \\ 100) do
    cond do
      fun.() -> :ok
      tries == 0 -> :timeout
      true -> Process.sleep(10) && until(fun, tries - 1)
    end
  end

  defp bottom_pid(router) do
    router |> Mob.Router.entries() |> Enum.find_value(fn {m, pid} -> m == Bottom && pid end)
  end

  defp resumes(pid), do: Mob.Screen.Server.socket(pid).assigns.resumes

  test "a pop tells the screen it lands on, and the screen that left hears nothing it can act on" do
    {:ok, router} = Mob.Router.start_link(Bottom, %{})
    on_exit(fn -> if Process.alive?(router), do: GenServer.stop(router) end)

    bottom = bottom_pid(router)
    assert is_pid(bottom)
    assert resumes(bottom) == 0

    send(router, {:go, Top})
    assert until(fn -> Mob.Router.get_current_module(router) == Top end) == :ok

    # Bottom is still resident — that is MOB-129, and it is why a re-read has
    # to be asked for rather than happening through a fresh mount.
    assert bottom_pid(router) == bottom
    assert resumes(bottom) == 0

    send(router, :back)

    assert until(fn -> Mob.Router.get_current_module(router) == Bottom end) == :ok

    assert until(fn -> resumes(bottom) >= 1 end) == :ok,
           "the screen popped back to never heard :resumed. On a device that is screen 03 " <>
             "still saying `0 titles` after screen 06 added one — mishka-group/kati#98's " <>
             "upgrade re-opened the defect Kati.Screens.Resume exists to close."

    # Exactly once: a courier per navigation, not a subscription.
    assert resumes(bottom) == 1
  end

  test "and it still lands when the router holds its registered name" do
    # The half the first test cannot see, and the half that shipped broken.
    #
    # `Mob.Router.init/1` takes the `:mob_screen` name only when `render_mode`
    # is `:render` — so a test router has no name, and `proc_lib` records the
    # parent of each screen as a PID. On a device it has one, and `proc_lib`
    # records a registered parent BY NAME: `$ancestors` is `[:mob_screen | _]`,
    # an atom. The first version of `owner/0` guarded on `is_pid/1` and fell
    # through to `self()`, so the courier sent `:resumed` to the pid of the
    # screen that had just died. Every host test passed; screen 03 still said
    # `0 titles`.
    #
    # Registering the name here puts the device's shape under test.
    {:ok, router} = Mob.Router.start_link(Bottom, %{}, name: :mob_screen)

    on_exit(fn ->
      if Process.alive?(router), do: GenServer.stop(router)
    end)

    assert Process.whereis(:mob_screen) == router

    bottom = bottom_pid(router)
    send(router, {:go, Top})
    assert until(fn -> Mob.Router.get_current_module(router) == Top end) == :ok

    send(router, :back)
    assert until(fn -> Mob.Router.get_current_module(router) == Bottom end) == :ok

    assert until(fn -> resumes(bottom) >= 1 end) == :ok,
           "the courier did not find the router by its registered name"
  end
end
