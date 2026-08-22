defmodule Kati.FaShellRoutesTest do
  @moduledoc """
  The Persian shell must stay Persian.

  Screen 61 (آمار) shipped, but `Kati.Screens.Fa.roots/0` kept pointing its
  stats tab at `Kati.Screens.Stats` — the English root that stood in while 61
  was unbuilt. In the other direction `Kati.Screens.StatsFa` answered its own
  dock taps against `Kati.Shell.screen_for/1`, which names the English four.

  Either way a single tap on the dock changed the app's language and its
  direction, with no way back except Settings. Neither is visible in a
  screenshot of a resting screen, which is why it survived a full 62-screen
  capture: the bar draws identically, it just means four other screens.
  """
  use ExUnit.Case, async: true

  @persian_roots [
    Kati.Screens.HomeFa,
    Kati.Screens.ScheduleFa,
    Kati.Screens.LibraryFa,
    Kati.Screens.StatsFa
  ]

  describe "the Persian dock names Persian screens" do
    test "every root in Kati.Screens.Fa.roots/0 is a Persian screen" do
      strays =
        Kati.Screens.Fa.roots()
        |> Enum.reject(&(&1.screen in @persian_roots))
        |> Enum.map(&"#{&1.id} -> #{inspect(&1.screen)}")

      assert strays == [],
             "Persian dock tabs pointing at English screens: " <> Enum.join(strays, ", ")
    end

    test "the four tabs are distinct screens" do
      screens = Enum.map(Kati.Screens.Fa.roots(), & &1.screen)
      assert length(Enum.uniq(screens)) == 4
    end

    test "the stats tab is screen 61, not the English stand-in" do
      stats = Enum.find(Kati.Screens.Fa.roots(), &(&1.id == :stats))
      assert stats.screen == Kati.Screens.StatsFa
    end
  end

  describe "a dock tap from a Persian root stays Persian" do
    setup do
      # reset_to/2 only records the target; no Mob runtime is needed for that.
      {:ok, socket: %Mob.Socket{assigns: %{}}}
    end

    for {tag, expected} <- [
          {:root_home, Kati.Screens.HomeFa},
          {:root_calendar, Kati.Screens.ScheduleFa},
          {:root_library, Kati.Screens.LibraryFa}
        ] do
      test "#{tag} from آمار lands on #{inspect(expected)}", %{socket: socket} do
        {:noreply, moved} = Kati.Screens.StatsFa.handle_info({:tap, unquote(tag)}, socket)
        assert target_of(moved) == unquote(expected)
      end
    end

    test "root_stats from آمار is inert", %{socket: socket} do
      {:noreply, moved} = Kati.Screens.StatsFa.handle_info({:tap, :root_stats}, socket)
      assert target_of(moved) == nil
    end
  end

  # `Mob.Socket.reset_to/3` records `{:reset, destination, params}` in
  # `__mob__.nav_action`; the destination is the whole assertion here.
  defp target_of(%Mob.Socket{__mob__: %{nav_action: {:reset, dest, _params}}}), do: dest
  defp target_of(%Mob.Socket{}), do: nil
end
