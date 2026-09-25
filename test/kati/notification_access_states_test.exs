defmodule Kati.NotificationAccessStatesTest do
  @moduledoc """
  Screen 151 draws the phone's own notification-access state, and only that.

  Board 151 stacks four specimen states under design-annotation eyebrows and
  counts the board's `128 tracks` on its revoked card. The screen reads
  `Kati.Media.Detect.access/0` and `Kati.Media.Detect.detected_count/0` and
  draws one card: never granted, turned off (only when a detected tick proves
  the grant once existed), granted, or not on this build.

  A host has no bridge, so `access/0` answers `:unavailable` and a bare mount
  draws that state. The other three are drawn by handing the page the status
  `status/2` computes from a grant and the store's real count, which is the
  same value `load/1` assigns on a device.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Screens.NotificationAccess, only: [status: 2, revoked_line: 1]

  alias Kati.Media.CachedTitle
  alias Kati.Media.Detect
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.NotificationAccess

  @prefix "notification-access-test-"

  @annotations [
    "purpose, then scope",
    "different wording",
    "What actually ships",
    "design record",
    "Play Protect"
  ]

  setup do
    Kati.Locale.put(:en)
    on_exit(&wipe!/0)
    wipe!()
    :ok
  end

  defp in_state(access) do
    view = mount_screen(NotificationAccess, %{back: "Auto-detect"})
    %{view | socket: Mob.Socket.assign(view.socket, :access, access)}
  end

  defp texts(view), do: view |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  defp page(view), do: Enum.join(texts(view), "\n")

  defp tags(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node.props || %{}, :on_tap) do
        {pid, tag} when is_pid(pid) and is_atom(tag) -> [tag]
        _other -> []
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp detected!(n) do
    tracked = shelve!()

    for _ <- 1..n do
      Ash.create!(Watch, %{
        tracked_title_id: tracked.id,
        detected: true,
        watched_at: DateTime.truncate(Kati.Time.now(), :second),
        watched_on: Kati.Time.today()
      })
    end
  end

  defp shelve! do
    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Notification access test",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: @prefix <> "title",
      kind: :tv,
      status: :watching
    })
  end

  defp wipe! do
    Kati.Repo.query!(
      "DELETE FROM media_watches WHERE tracked_title_id IN " <>
        "(SELECT id FROM tracked_titles WHERE source_id LIKE ?)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?", [@prefix <> "%"])
  end

  describe "the state the page reads" do
    test "a host has no bridge, so a bare mount is the not-on-this-build state" do
      view = mount_screen(NotificationAccess, %{back: "Auto-detect"})

      assert assigns(view).access.state == :unavailable
      assert NotificationAccess.status().state == :unavailable
    end

    test "denied with no detected tick cannot be told from never granted, and says so" do
      assert NotificationAccess.status(:denied, 0).state == :not_granted
    end

    test "a detected tick in the store is what makes denied read as turned off" do
      before = Detect.detected_count()
      detected!(3)

      assert Detect.detected_count() == before + 3

      assert NotificationAccess.status(:denied, Detect.detected_count()) ==
               %{state: :revoked, kept: before + 3}
    end
  end

  describe "each state draws its own card and nothing else" do
    test "not granted: why, what it can see, one settings button" do
      view = in_state(NotificationAccess.status(:denied, 0))
      text = page(view)

      assert text =~ "NOT GRANTED"
      assert text =~ "Why Kati wants it"
      assert text =~ "every notification on the device, messages included"
      assert text =~ "folded into the ordinary Notifications row under This device"
      refute text =~ "Turned off in system settings"
      refute text =~ "media notifications only"
      refute text =~ "Not set up"
      refute text =~ "on 40"

      assert tags(view) == [:back, :open_settings]
    end

    test "turned off: the real count of detected ticks, and both of its pills" do
      before = Detect.detected_count()
      detected!(2)
      kept = before + 2

      view = in_state(NotificationAccess.status(:denied, Detect.detected_count()))
      text = page(view)

      assert text =~ "TURNED OFF"
      assert text =~ "Turned off in system settings"
      assert text =~ "Kati ticked #{kept} things you watched"
      refute text =~ "Why Kati wants it"
      refute text =~ "media notifications only"
      refute text =~ "Not set up"
      refute text =~ "128"
      refute text =~ "tracks"

      assert tags(view) == [:back, :log_by_hand, :open_settings_revoked]
    end

    test "turned off with nothing kept names no count" do
      view = in_state(%{state: :revoked, kept: 0})
      text = page(view)

      assert text =~ "Nothing new is detected until it is turned back on."
      refute text =~ "ticked"
    end

    test "granted: the live row and nothing to press" do
      view = in_state(NotificationAccess.status(:granted, 0))
      text = page(view)

      assert text =~ "GRANTED"
      assert text =~ "On · media notifications only"
      refute text =~ "Open system settings"
      refute text =~ "Turned off in system settings"
      refute text =~ "Not set up"

      assert tags(view) == [:back]
    end

    test "not on this build: the retired row, which says why" do
      view = mount_screen(NotificationAccess, %{back: "Auto-detect"})
      text = page(view)

      assert text =~ "NOT ON THIS BUILD"
      assert text =~ "Not set up — tap to see why"
      refute text =~ "Open system settings"
      refute text =~ "Why Kati wants it"

      assert tags(view) == [:back, :open_retired]

      pushed = render_info(view, {:tap, :open_retired})
      assert navigated_to(pushed) == Kati.Screens.RetiredTile

      sheet = mount_screen(Kati.Screens.RetiredTile, pushed.socket.__mob__.nav_action |> elem(2))
      sheet_text = page(sheet)

      assert sheet_text =~ "Notification access"
      refute sheet_text =~ "Sleep"
    end

    test "no state carries the board's figure or its design annotations" do
      detected!(1)

      for access <- [
            NotificationAccess.status(:denied, 0),
            NotificationAccess.status(:denied, Detect.detected_count()),
            NotificationAccess.status(:granted, Detect.detected_count()),
            NotificationAccess.status(:unavailable, 0)
          ] do
        text = page(in_state(access))

        refute text =~ "128", "#{access.state} drew the board's 128"

        for note <- @annotations do
          refute text =~ note, "#{access.state} drew the annotation #{inspect(note)}"
        end
      end
    end
  end

  describe "in Persian" do
    test "each state's label and the kept count read in Persian" do
      Kati.Locale.as(:fa, fn ->
        assert page(in_state(NotificationAccess.status(:denied, 0))) =~ "اجازه داده نشده"

        turned_off = page(in_state(%{state: :revoked, kept: 4}))
        assert turned_off =~ "خاموش شده"
        assert turned_off =~ "کاتی ۴ مورد"

        assert page(in_state(NotificationAccess.status(:unavailable, 0))) =~ "در این نسخه نیست"
      end)
    end
  end
end
