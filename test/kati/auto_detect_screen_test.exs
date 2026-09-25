defmodule Kati.AutoDetectScreenTest do
  @moduledoc """
  Screen 36 reads the device and the store, and every control on it writes
  or goes somewhere real.

  A host has no bridge, so `Kati.Media.Detect.access/0` answers
  `:unavailable` here. The two states a phone can be in — `:denied` (the
  usual one for a sideloaded build, which Play Protect keeps from being
  granted) and `:granted` — are put on the socket's `:detect` map and the
  page re-rendered from it, the arrangement `Kati.NotificationAccessRouteTest`
  uses for screen 151's four states.

  `:detect_enabled` and `:detect_threshold` are set explicitly on the way in.
  Nothing needs restoring on the way out: `Mob.ScreenCase` starts `Mob.State`
  per test over a throwaway directory and stops it before `on_exit/1` runs.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.Detect
  alias Kati.Screens.AutoDetect

  doctest AutoDetect, only: [banner_tap: 1]

  setup do
    Mob.State.put(:detect_enabled, false)
    Mob.State.put(:detect_threshold, 90)

    :ok
  end

  defp tags(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node.props || %{}, :on_tap) do
        {pid, tag} when is_pid(pid) and is_atom(tag) -> [tag]
        _other -> []
      end
    end)
  end

  defp texts(view), do: view |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  defp with_access(view, access) do
    detect = %{AutoDetect.detect() | access: access}
    %{view | socket: Mob.Socket.assign(view.socket, :detect, detect)}
  end

  describe "the master switch" do
    test "writes the store through the banner's own tap, and the page reads it back" do
      view = mount_screen(AutoDetect) |> with_access(:granted)

      assert :toggle_detect in tags(view)
      refute Detect.on?()

      on = render_info(view, {:tap, :toggle_detect})

      assert Mob.State.get(:detect_enabled) == true
      assert Detect.on?()
      assert assigns(on).detect.banner.on == true

      off = render_info(on, {:tap, :toggle_detect})

      assert Mob.State.get(:detect_enabled) == false
      refute assigns(off).detect.banner.on
    end

    test "gates detection itself: off, nothing is swept or drained" do
      Detect.put(false)

      assert Detect.sweep() == []
      assert Detect.drain() == []
    end

    test "is a door to screen 151 while access is not granted, not a switch about nothing" do
      view = mount_screen(AutoDetect) |> with_access(:denied)

      refute :toggle_detect in tags(view)
      assert :allow_to_detect in tags(view)

      assert navigated_to(render_info(view, {:tap, :allow_to_detect})) ==
               Kati.Screens.NotificationAccess
    end
  end

  describe "the threshold row" do
    test "is the stored number detection compares a session against" do
      view = mount_screen(AutoDetect)

      assert :cycle_threshold in tags(view)
      assert "90% watched" in texts(view)

      stepped = render_info(view, {:tap, :cycle_threshold})

      assert Mob.State.get(:detect_threshold) == 95
      assert Detect.threshold() == 95
      assert "95% watched" in texts(stepped)

      assert Detect.verdict(%{
               title: "Nothing on this shelf",
               playing?: true,
               position_ms: 93,
               duration_ms: 100
             }) == :ignore,
             "93% must fall short of a 95% threshold"
    end

    test "is the only rule drawn: the board's two with no store behind them are not" do
      view = mount_screen(AutoDetect)

      refute "Ask before ticking" in texts(view)
      refute Enum.any?(texts(view), &String.contains?(&1, "trailers"))
      assert length(AutoDetect.real_rules()) == 1
    end
  end

  describe "the subtitle and the banner" do
    test "say what the device and the store say" do
      assert AutoDetect.sources_line(:denied, true) == "not allowed to look yet"
      assert AutoDetect.sources_line(:granted, false) == "allowed, switched off"
      assert AutoDetect.sources_line(:granted, true) == "watching this phone"

      view = mount_screen(AutoDetect)

      assert "not allowed to look yet" in texts(view)
      assert "NOTHING TICKED FOR YOU YET" in Enum.map(texts(view), &String.upcase/1)
    end
  end

  describe "access that is not granted" do
    test "is said plainly, with a door to 151 and a door to logging by hand" do
      for access <- [:denied, :unavailable] do
        view = mount_screen(AutoDetect) |> with_access(access)

        assert "Kati cannot see what you play yet" in texts(view)
        assert Enum.any?(texts(view), &String.contains?(&1, "Play Store"))
        assert :how_to_allow in tags(view)
        assert :log_by_hand in tags(view)

        assert navigated_to(render_info(view, {:tap, :how_to_allow})) ==
                 Kati.Screens.NotificationAccess
      end
    end

    test "is not drawn once access is granted" do
      view = mount_screen(AutoDetect) |> with_access(:granted)

      refute "Kati cannot see what you play yet" in texts(view)
      refute :log_by_hand in tags(view)
    end

    test "Log by hand opens the search over the reader's own shelf" do
      view = mount_screen(AutoDetect)

      pushed = render_info(view, {:tap, :log_by_hand})

      assert navigated_to(pushed) == Kati.Screens.Search

      assert {:push, Kati.Screens.Search, %{scope: :screen, query: "", back: "Auto-detect"}} =
               pushed.socket.__mob__.nav_action
    end
  end

  describe "board 150" do
    test "is not reachable from 36: no TV & film / Music control is drawn" do
      view = mount_screen(AutoDetect)
      drawn = tags(view)

      refute :music in drawn
      refute :tv in drawn
      refute "Music" in texts(view)
    end
  end

  describe "the Sources card" do
    test "This phone is a chevron door in every state, never a second switch" do
      for access <- [:granted, :denied, :unavailable] do
        [phone] = AutoDetect.real_sources(access, [])

        assert phone.control == :chevron
        assert phone.tap == :open_media_access
      end
    end
  end
end
