defmodule Kati.SupervisionRuleTest do
  @moduledoc """
  Enforces the rule that screens subscribe to nothing.

  A screen is transient — Mob keeps one alive at a time and it dies on every
  root switch. Anything that outlives a screen must live under
  `Kati.Supervisor`. A rule nobody can break by accident is worth more than a
  rule everybody agrees with, so this is a test rather than a convention.
  """
  use ExUnit.Case, async: true

  @screens Path.wildcard(Path.expand("../../lib/kati/screens/**/*.ex", __DIR__))

  # Things that outlive a single render, and therefore outlive the screen.
  @forbidden [
    {~r/\bsubscribe\(/, "PubSub/notifier subscription"},
    {~r/Phoenix\.PubSub/, "Phoenix.PubSub"},
    {~r/Process\.send_after\(/, "Process.send_after/3"},
    {~r/:timer\.send_interval\(/, ":timer.send_interval/3"},
    {~r/Registry\.register\(/, "Registry.register/3"},
    {~r/Process\.register\(/, "Process.register/2"}
  ]

  test "screen modules exist to check" do
    assert @screens != [], "no screens found — the lint would pass vacuously"
  end

  test "no screen subscribes to anything or holds a timer" do
    offences =
      for path <- @screens,
          {pattern, label} <- @forbidden,
          body = File.read!(path),
          # Ignore comments: the rule is documented in prose inside these files.
          stripped = String.replace(body, ~r/^\s*#.*$/m, ""),
          stripped =~ pattern do
        "#{Path.basename(path)}: #{label}"
      end

    assert offences == [],
           "screens must not outlive themselves — move this under Kati.Supervisor:\n" <>
             Enum.join(offences, "\n")
  end

  test "the root screen is a supervised child, not started ad hoc" do
    app = File.read!(Path.expand("../../lib/kati/app.ex", __DIR__))

    refute app =~ "Mob.Screen.start_root(",
           "start_root/3 is a bare GenServer.start_link — an unsupervised screen that " <>
             "crashes stays dead and the app looks frozen. Start it under Kati.Supervisor."

    assert app =~ "Kati.Supervisor.start_link()"
  end

  test "Kati.Supervisor supervises the root screen with a permanent restart" do
    {:ok, {_flags, children}} = Kati.Supervisor.init(:ok)
    screen = Enum.find(children, &(&1.id == :mob_screen))

    assert screen, "the root screen must be supervised"
    assert screen.restart == :permanent
    assert {Mob.Screen, :start_root, [Kati.Screens.Home]} = screen.start
  end

  test "taps are rescued so a handler bug does not kill the screen" do
    defmodule Boom do
      def handle_tap(_tag, _socket), do: raise("boom")
    end

    assert {:noreply, :socket} = Kati.Screens.Root.rescue_tap(Boom, :thing, :socket)
  end

  test "pushes from supervised processes are rescued too" do
    defmodule BoomKati do
      def handle_kati(_topic, _payload, _socket), do: raise("boom")
    end

    assert {:noreply, :socket} =
             Kati.Screens.Root.rescue_kati(BoomKati, :topic, %{}, :socket)
  end
end
