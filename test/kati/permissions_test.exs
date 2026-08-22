defmodule Kati.PermissionsTest do
  @moduledoc """
  Reading a permission, and the one case Android cannot answer on its own.

  ## The defect this exists for

  `Mob.Permissions.request/2` can ask; nothing in Mob can read. Screen 40's
  moduledoc had recorded that gap and drawn its trailing states as pictures —
  "this is the shape a granted permission takes" — because a switch position is
  a read and there was nothing to read from.

  A remembered answer would have been worse than none: a permission can be
  revoked in system settings while Kati is backgrounded, which is the normal
  way permissions change, so any app-local copy is a lie exactly when it
  matters.
  """
  # `Mob.ScreenCase` rather than `ExUnit.Case`: the asked-record lives in
  # `Mob.State`, a named GenServer this case starts and plain ExUnit does not.
  use Mob.ScreenCase, async: false

  alias Kati.Permissions

  setup do
    Permissions.forget_asked!()
    :ok
  end

  describe "which capabilities are reported at all" do
    test "only the ones the manifest actually declares" do
      # Camera, microphone, location and the media-library permissions are
      # deliberately absent from AndroidManifest.xml (K-30, K-31). A row for any
      # of them would be asking the user about something Kati cannot do.
      assert Permissions.runtime_capabilities() == [:notifications, :calendar, :exact_alarms]
    end

    test "every reported capability is declared in the manifest" do
      manifest =
        File.read!(Path.expand("../../android/app/src/main/AndroidManifest.xml", __DIR__))

      declared =
        Regex.scan(~r/<uses-permission android:name="android\.permission\.([A-Z_]+)"/, manifest)
        |> Enum.map(fn [_, name] -> name end)

      # The mapping the bridge uses, asserted here so a row cannot outlive its
      # permission. `exact_alarms` is a settings toggle rather than a runtime
      # grant, but it still has to be declared to be togglable at all.
      for {capability, permission} <- [
            notifications: "POST_NOTIFICATIONS",
            calendar: "READ_CALENDAR",
            exact_alarms: "SCHEDULE_EXACT_ALARM"
          ] do
        assert capability in Permissions.runtime_capabilities()

        assert permission in declared,
               "#{capability} is reported on screen 40 but #{permission} is not in the manifest"
      end
    end
  end

  describe "unasked and blocked look identical to Android" do
    test "denied with no rationale is unasked until Kati has asked" do
      # shouldShowRequestPermissionRationale is false BOTH for a permission
      # never requested and one refused permanently. Kati's own record is the
      # only thing that separates them.
      refute :calendar in Permissions.asked()

      Permissions.note_asked(:calendar)
      assert :calendar in Permissions.asked()
    end

    test "the record survives being set twice" do
      Permissions.note_asked(:calendar)
      Permissions.note_asked(:calendar)
      assert Enum.count(Permissions.asked(), &(&1 == :calendar)) == 1
    end

    test "forgetting is total" do
      Permissions.note_asked(:notifications)
      Permissions.forget_asked!()
      assert Permissions.asked() == []
    end
  end

  describe "what control a state earns" do
    test "an unasked permission gets Allow" do
      assert Permissions.affordance(:unasked) == :allow
    end

    test "a denied-once permission still gets Allow, because Android will ask again" do
      assert Permissions.affordance(:denied) == :allow
    end

    test "a blocked permission gets system settings, not an Allow that cannot work" do
      # Once permanently denied, request/2 does not re-prompt. An Allow button
      # there is a control that silently does nothing.
      assert Permissions.affordance(:blocked) == :settings
    end

    test "granted and unknown earn no control" do
      assert Permissions.affordance(:granted) == :none
      assert Permissions.affordance(:unknown) == :none
    end
  end

  describe "off the device" do
    test "status is :unknown rather than :denied when there is no bridge" do
      # Folding the two together would draw an Allow button on a host, and on a
      # phone whose bridge method went missing — a control that cannot work,
      # reported as a user decision.
      assert Permissions.status(:calendar) == :unknown
    end
  end
end
