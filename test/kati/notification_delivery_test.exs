defmodule Kati.NotificationDeliveryTest do
  @moduledoc """
  The backend that finally arms something, and the seam it sits behind.

  Kati's notification layer was complete except for its last step: `:mob_nif`
  has no notify entry anywhere in mob 0.7.20 and `mob_notify` is not a
  dependency, so `MobBridge.notify_schedule` — correct since
  `K-01 notify-persist`, and reboot-durable — had no caller at all. Every
  budget, quiet-hours and digest decision ended in
  `Kati.Notifications.Delivery.Inert`, which returns `:ok` and does nothing.

  A host cannot arm an alarm. What it can prove is that the decisions now
  travel to a real backend, that the payload the backend builds is the one the
  Kotlin parses, and that with no native half the failure is visible rather
  than a phantom success.
  """
  use ExUnit.Case, async: true

  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Delivery
  alias Kati.Notifications.Delivery.Android
  alias Kati.Notifications.Reconcile
  alias Kati.Notifications.Scheduler

  @root Path.expand("../..", __DIR__)
  @bridge Path.join(@root, "android/app/src/main/java/com/example/kati/MobBridge.kt")
  @activity Path.join(@root, "android/app/src/main/java/com/example/kati/MainActivity.kt")

  @fire ~U[2026-09-01 17:00:00Z]

  defp episode(opts \\ []) do
    Candidate.absolute(
      "ep:tmdb:1396:5:16",
      :tv,
      @fire,
      Keyword.merge([title: "Felina", body: "Season 5, episode 16"], opts)
    )
  end

  describe "choosing a backend" do
    test "the host gets the inert one, and it is a real choice not a default" do
      refute Android.available?()
      assert Delivery.backend() == Delivery.Inert

      # ...and the inert backend is still a working backend, so a plan can be
      # produced and rendered in the in-app inbox with nothing armed.
      assert Delivery.Inert.arm(episode()) == :ok
    end
  end

  describe "arming with no native half" do
    test "a live candidate fails visibly rather than reporting success" do
      assert Android.arm(episode()) == {:error, :no_bridge}
      assert Android.cancel("ep:tmdb:1396:5:16") == {:error, :no_bridge}
      assert Android.status() == {:error, :no_bridge}
    end

    test "a suppressed candidate is refused, carrying the reason the gate gave" do
      # Arming it would contradict a decision the scheduler already made and
      # recorded; answering :ok would tell the reconciler an alarm exists that
      # does not, which is what it compares against next time.
      muted = Candidate.suppressed("ep:tmdb:1396:5:16", :tv, :muted)

      assert Android.arm(muted) == {:error, {:suppressed, :muted}}
    end

    test "an unresolved wall-clock candidate is refused" do
      floating =
        Candidate.wall_clock("habit:3:2026-08-21", :habits, ~N[2026-08-21 07:00:00], nil)

      assert floating.fire_at == nil
      assert Android.arm(floating) == {:error, :unresolved}
    end
  end

  describe "the payload the Kotlin parses" do
    test "carries the id, the text and the instant as epoch seconds" do
      payload = Android.payload(episode())

      assert payload["id"] == "ep:tmdb:1396:5:16"
      assert payload["title"] == "Felina"
      assert payload["body"] == "Season 5, episode 16"

      # Seconds, because MobBridge.katiNotifyArm multiplies by 1000. A
      # millisecond value here would arm alarms ~55,000 years out.
      assert payload["trigger_at"] == DateTime.to_unix(@fire)
      assert payload["trigger_at"] == 1_788_282_000
    end

    test "missing text becomes empty strings, never the atom nil" do
      bare = Candidate.absolute("ep:tmdb:1", :tv, @fire)
      payload = Android.payload(bare)

      assert payload["title"] == ""
      assert payload["body"] == ""

      # Erlang's :json.encode renders the atom nil as the STRING "nil", so a
      # nil here reaches the notification shade as the word "nil".
      refute encoded(bare) =~ "nil"
    end

    test "meta is flattened to JSON-safe values and nil keys are dropped" do
      candidate =
        episode(
          members: ["ep:tmdb:1396:5:16", "ep:tmdb:1396:5:15"],
          meta: %{source: :tmdb, season: 5, episode: nil, confidence: :confirmed}
        )

      payload = Android.payload(candidate)

      assert payload["data"]["domain"] == "tv"
      assert payload["data"]["members"] == ["ep:tmdb:1396:5:16", "ep:tmdb:1396:5:15"]

      assert payload["data"]["meta"] == %{
               "source" => "tmdb",
               "season" => 5,
               "confidence" => "confirmed"
             }

      refute Map.has_key?(payload["data"]["meta"], "episode"),
             "a nil meta value must be absent, not the string \"nil\""
    end

    test "a struct in meta degrades to text instead of breaking every arm" do
      # One domain putting a Date in meta must not stop every other domain's
      # notifications from being armed.
      payload = Android.payload(episode(meta: %{aired_on: ~D[2026-09-01]}))

      assert payload["data"]["meta"]["aired_on"] == "2026-09-01"
      assert is_binary(encoded(episode(meta: %{aired_on: ~D[2026-09-01]})))
    end

    test "the payload survives a round trip through the JSON the bridge receives" do
      candidate = episode(meta: %{note: "She said \"go\",\nthen ۱۲"})
      decoded = candidate |> encoded() |> :json.decode()

      assert decoded["id"] == "ep:tmdb:1396:5:16"
      assert decoded["trigger_at"] == DateTime.to_unix(@fire)
      assert decoded["data"]["meta"]["note"] == "She said \"go\",\nthen ۱۲"
    end
  end

  describe "reading the platform's answer" do
    test "a status reply becomes the three facts a screen needs" do
      # Reached through the same code path as a real reply — Bridge.split/1 —
      # so a change to the reply grammar breaks this rather than passing.
      assert Kati.Native.Bridge.split("ok:14:true:false") == {:ok, "14:true:false"}
    end

    test "the periodic reply reports what WorkManager actually accepted" do
      assert Kati.Background.Periodic.decode_ensure("ok:360:120") ==
               {:ok, %{interval_minutes: 360, flex_minutes: 120}}

      # WorkManager silently raises anything under 15 minutes to its floor, so
      # the accepted values are not the requested ones and the caller is told.
      assert Kati.Background.Periodic.decode_ensure("ok:15:14") ==
               {:ok, %{interval_minutes: 15, flex_minutes: 14}}

      assert Kati.Background.Periodic.decode_ensure("error:no_context") ==
               {:error, :no_context}

      # A reply that is neither "ok…" nor "error:…" is carried whole rather
      # than read as success — a bridge that has drifted must be visible.
      assert Kati.Background.Periodic.decode_ensure("nonsense") ==
               {:error, {:native, "nonsense"}}

      # And a well-formed "ok" with the wrong payload shape is a bad reply, not
      # a silent {:ok, %{}} with missing numbers.
      assert Kati.Background.Periodic.decode_ensure("ok:360") ==
               {:error, {:bad_reply, "ok:360"}}

      assert Kati.Background.Periodic.decode_ensure("ok:six:two") ==
               {:error, {:bad_reply, "ok:six:two"}}
    end

    test "an unknown native reason is carried as a string and creates no atom" do
      novel = "reason_#{System.unique_integer([:positive])}"

      assert Kati.Background.Periodic.decode_ensure("error:" <> novel) ==
               {:error, {:native, novel}}

      assert_raise ArgumentError, fn -> String.to_existing_atom(novel) end
    end
  end

  describe "the whole pipeline, host end to host end" do
    test "a plan reaches the real backend and every failure is reported" do
      now = ~U[2026-08-21 10:00:00Z]

      candidates = [
        episode(),
        Candidate.absolute("ev:9", :calendar, ~U[2026-08-22 09:00:00Z], title: "Dentist")
      ]

      {plan, operations} =
        Scheduler.reconcile(candidates, [], platform: :android, now: now, zone: "Etc/UTC")

      assert length(operations) == 2
      assert Enum.all?(operations, &match?({:arm, _}, &1))

      result = Delivery.run(operations, Android)

      # Nothing armed, everything reported. The inert backend would have
      # claimed both — which is precisely the difference this ticket closes.
      assert result.armed == []
      assert length(result.errors) == 2
      assert Enum.all?(result.errors, fn {_operation, reason} -> reason == :no_bridge end)

      # ...and the plan itself is unaffected by delivery failing, so the in-app
      # inbox still renders.
      assert length(Kati.Notifications.Plan.armed_ids(plan)) == 2
    end

    test "cancels reach the backend as ids" do
      operations =
        Reconcile.operations(%Kati.Notifications.Plan{armed: []}, [
          %Kati.Notifications.Armed{id: "ep:tmdb:1396:5:16", fingerprint: 1}
        ])

      assert operations == [{:cancel, "ep:tmdb:1396:5:16"}]

      result = Delivery.run(operations, Android)
      assert result.cancelled == []
      assert [{{:cancel, "ep:tmdb:1396:5:16"}, :no_bridge}] = result.errors
    end
  end

  describe "the Android half" do
    test "the bridge methods exist and answer, rather than returning void" do
      code = fence(@bridge, "K-22 notify-and-periodic-bridge")

      for signature <- [
            "fun katiNotifyArm(argsJson: String): String",
            "fun katiNotifyCancel(id: String): String",
            "fun katiNotifyStatus(): String",
            "fun katiPeriodicEnsure(configJson: String): String",
            "fun katiPeriodicCancel(): String"
          ] do
        assert code =~ signature,
               "MobBridge.#{signature} is gone — a void bridge method cannot report a failed " <>
                 "arm, which is the whole reason these exist beside the K-01 pair"
      end
    end

    test "arming uses a context that outlives the Activity" do
      # activityRef is a WeakReference. Re-arming happens on foreground, but a
      # quiet-hours reschedule or a token refresh happens with the Activity
      # destroyed and the BEAM alive in BeamForegroundService — where the K-01
      # methods return having done nothing, silently.
      code = fence(@bridge, "K-22 notify-and-periodic-bridge")

      assert code =~ "KatiHostContext.get()"
      assert code =~ "error:no_context"
      assert File.read!(@activity) =~ "KatiHostContext.attach(this)"
    end

    test "status reports whether notifications may be shown at all" do
      # With POST_NOTIFICATIONS refused Android still arms the alarm, still
      # runs the receiver and still accepts nm.notify() — the notification
      # simply never appears, and nothing reports an error anywhere.
      code = fence(@bridge, "K-22 notify-and-periodic-bridge")

      assert code =~ "areNotificationsEnabled()"
      assert code =~ "canScheduleExactAlarms()"
    end

    test "the K-01 pair is left alone" do
      # It is Mob's contract — void, pid-first, Activity-scoped — and the next
      # Mob release may finally ship a NIF for it. Two implementations of the
      # same arming would be worse than the one that could not be reached.
      persist = fence(@bridge, "K-01 notify-persist")
      assert persist =~ "fun notify_schedule(pid: Long, optsJson: String)"
      refute persist =~ "KatiHostContext"
    end
  end

  defp encoded(candidate) do
    candidate |> Android.payload() |> Kati.Native.Bridge.encode()
  end

  defp fence(path, label) do
    [region] =
      Regex.run(
        ~r/KATI-BEGIN\(#{Regex.escape(label)}\)(?s).*?KATI-END\(#{Regex.escape(label)}\)/,
        File.read!(path)
      )

    region
  end
end
