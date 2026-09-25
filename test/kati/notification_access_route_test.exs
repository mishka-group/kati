defmodule Kati.NotificationAccessRouteTest do
  @moduledoc """
  Screen 151 has a door, and every control on it goes somewhere.

  `Kati.Screens.NotificationAccess` was drawn, built and reached by nothing but
  the gallery. Its door is the permission row on screen 36 — *This phone*,
  which reads the same grant through `Kati.Media.Detect.access/0` — so the
  row now pushes 151 rather than firing the system intent with no explanation
  in front of it, and 151's own `Open system settings` is what fires it.

  On a host there is no bridge, so the settings intent refuses; that refusal is
  what the two settings taps are asserted to DRAW, since a tap that answers
  with an unchanged page is the dead control this file exists to rule out.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.AutoDetect
  alias Kati.Screens.NotificationAccess

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

  defp texts(view) do
    view |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))
  end

  describe "screen 36's This phone row" do
    test "is drawn with its own tap" do
      view = mount_screen(AutoDetect)

      assert :open_media_access in tags(view)
      assert "This phone" in texts(view)
    end

    test "pushes screen 151, with a back pill naming Auto-detect" do
      view = mount_screen(AutoDetect)

      pushed = render_info(view, {:tap, :open_media_access})

      assert navigated_to(pushed) == NotificationAccess

      assert {:push, NotificationAccess, %{back: "Auto-detect"}} =
               pushed.socket.__mob__.nav_action
    end
  end

  describe "screen 151, arrived at from Auto-detect" do
    test "draws its back pill as Auto-detect and the pill pops" do
      view = mount_screen(NotificationAccess, %{back: "Auto-detect"})

      assert "Auto-detect" in texts(view)
      assert :back in tags(view)
      assert navigated_to(render_info(view, {:tap, :back})) == {:pop}
    end

    test "across its four states, draws every control this file answers for, and nothing else" do
      view = mount_screen(NotificationAccess, %{back: "Auto-detect"})

      drawn =
        for access <- [
              NotificationAccess.status(:denied, 0),
              NotificationAccess.status(:denied, 1),
              NotificationAccess.status(:granted, 0),
              NotificationAccess.status(:unavailable, 0)
            ],
            tag <- tags(%{view | socket: Mob.Socket.assign(view.socket, :access, access)}),
            uniq: true,
            do: tag

      assert Enum.sort(drawn) ==
               Enum.sort([
                 :back,
                 :open_settings,
                 :open_settings_revoked,
                 :log_by_hand,
                 :open_retired
               ])
    end

    test "both Open system settings taps draw the refusal rather than going quiet" do
      for tag <- [:open_settings, :open_settings_revoked] do
        view = mount_screen(NotificationAccess, %{back: "Auto-detect"})
        refute Kati.Native.Links.message(:no_bridge) in texts(view)

        tapped = render_info(view, {:tap, tag})

        assert navigated_to(tapped) == nil
        assert assigns(tapped).link_error == Kati.Native.Links.message(:no_bridge)

        assert Kati.Native.Links.message(:no_bridge) in texts(tapped),
               "#{inspect(tag)} refused and the page said nothing"
      end
    end

    test "Log by hand opens the search over the reader's film and series shelf, not music" do
      view = mount_screen(NotificationAccess, %{back: "Auto-detect"})

      pushed = render_info(view, {:tap, :log_by_hand})

      assert navigated_to(pushed) == Kati.Screens.Search
      refute navigated_to(pushed) == Kati.Screens.LogListen

      assert {:push, Kati.Screens.Search,
              %{scope: :screen, query: "", back: "Notification access"}} =
               pushed.socket.__mob__.nav_action

      search = mount_screen(Kati.Screens.Search, elem(pushed.socket.__mob__.nav_action, 2))

      assert assigns(search).filter == :screen
      assert "Notification access" in texts(search)
    end

    test "the retired row opens the sheet that says why" do
      view = mount_screen(NotificationAccess, %{back: "Auto-detect"})

      assert navigated_to(render_info(view, {:tap, :open_retired})) == Kati.Screens.RetiredTile
    end
  end
end
