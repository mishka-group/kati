defmodule Kati.HostHardeningTest do
  @moduledoc """
  Guards the fixes made to the generated host app.

  Every assertion here corresponds to a defect that shipped in a stock
  `mix mob.new` project and failed **silently** — no crash, no warning, just a
  capability that quietly does not work. The native shell is forked at
  generation time and there is no `mix mob.upgrade`, so a future regeneration
  or a hand-merge can reintroduce any of them without a compiler ever noticing.
  These tests are the tripwire.
  """
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @manifest Path.join(@root, "android/app/src/main/AndroidManifest.xml")
  @bridge Path.join(@root, "android/app/src/main/java/com/example/kati/MobBridge.kt")
  @gradle Path.join(@root, "android/app/build.gradle")
  @plist Path.join(@root, "ios/Info.plist")

  # Deletion fences deliberately NAME what was removed, so raw string matching
  # would find "RECORD_AUDIO" in a comment that exists precisely to prove it is
  # gone. Strip comments before asserting on real declarations.
  defp without_xml_comments(path) do
    File.read!(path) |> String.replace(~r/<!--.*?-->/s, "")
  end

  describe "CA trust store" do
    test "priv/cacerts.pem exists and holds real certificates" do
      pem = Path.join(@root, "priv/cacerts.pem")
      assert File.exists?(pem), "priv/cacerts.pem missing — every HTTPS call on Android will fail"

      body = File.read!(pem)
      count = body |> String.split("-----BEGIN CERTIFICATE-----") |> length() |> Kernel.-(1)
      assert count > 100, "expected a full trust store, found #{count} certificates"
    end

    test "the bundle is loaded before anything can use TLS" do
      source = File.read!(Path.join(@root, "lib/kati/app.ex"))
      assert source =~ "Mob.Certs.load_cacerts!"

      certs_at = source |> String.split("Mob.Certs.load_cacerts!") |> hd() |> String.length()
      repo_at = source |> String.split("Kati.Repo.start_link") |> hd() |> String.length()
      assert certs_at < repo_at, "certs must load before anything that might open a connection"
    end
  end

  describe "scheduled notifications survive a reboot" do
    test "a boot receiver is declared for every action that clears AlarmManager" do
      manifest = File.read!(@manifest)
      assert manifest =~ ~s(android:name=".KatiBootReceiver")

      for action <- ~w(BOOT_COMPLETED MY_PACKAGE_REPLACED TIME_SET TIMEZONE_CHANGED) do
        assert manifest =~ "android.intent.action.#{action}",
               "KatiBootReceiver does not listen for #{action}"
      end
    end

    test "the receiver class exists" do
      assert File.exists?(
               Path.join(@root, "android/app/src/main/java/com/example/kati/KatiBootReceiver.kt")
             )
    end

    test "scheduling persists the alarm rather than only arming AlarmManager" do
      bridge = File.read!(@bridge)

      assert bridge =~ "KatiNotificationStore.schedule",
             "notify_schedule must record the alarm, or it cannot be restored after a reboot"

      refute bridge =~ "am.setExactAndAllowWhileIdle",
             "MobBridge should delegate arming to KatiNotificationStore, not arm directly"
    end
  end

  describe "permissions" do
    test "requests only what Kati actually uses" do
      granted =
        @manifest
        |> without_xml_comments()
        |> then(
          &Regex.scan(~r/<uses-permission[^>]*android:name="android\.permission\.([A-Z_]+)"/, &1)
        )
        |> Enum.map(&List.last/1)
        |> Enum.uniq()
        |> MapSet.new()

      expected =
        MapSet.new(~w(INTERNET POST_NOTIFICATIONS SCHEDULE_EXACT_ALARM
                      RECEIVE_BOOT_COMPLETED VIBRATE))

      assert MapSet.equal?(granted, expected),
             "unexpected: #{inspect(MapSet.difference(granted, expected) |> MapSet.to_list())}, " <>
               "missing: #{inspect(MapSet.difference(expected, granted) |> MapSet.to_list())}"
    end
  end

  describe "release safety" do
    test "Erlang distribution is compile-time gated to dev" do
      source = File.read!(Path.join(@root, "lib/kati/app.ex"))
      assert source =~ "@dev?"
      assert source =~ "if @dev? do"

      # The cookie value itself is deliberately mob_dev's default — mob.connect
      # hardcodes it — because the @dev? gate is what actually keeps a
      # listening socket out of release builds. What matters is the gate.
      assert source =~ "MOB_DIST_COOKIE", "the cookie should stay overridable"

      [_, gated] = Regex.run(~r/if @dev\? do\n(.*?)\n    end/s, source)
      assert gated =~ "Mob.Dist.ensure_started", "distribution must be inside the dev gate"
    end

    test "iOS does not declare a background mode it never uses" do
      refute without_xml_comments(@plist) =~ "<key>UIBackgroundModes</key>",
             "UIBackgroundModes:[audio] in a tracker that plays nothing risks App Store rejection"
    end

    test "only 64-bit ABIs are built" do
      # Scoped to the abiFilters line: "armeabi-v7a" also appears in the
      # OTP-release path variables, which are unrelated to what ships.
      abis =
        @gradle
        |> File.read!()
        |> String.split("\n")
        |> Enum.reject(&String.starts_with?(String.trim(&1), "//"))
        |> Enum.find(&(&1 =~ "abiFilters"))

      refute abis =~ "armeabi-v7a", "32-bit ABI would double the OTP payload"
      assert abis =~ "arm64-v8a", "real devices need arm64"
      assert abis =~ "x86_64", "the emulator on this Intel host needs x86_64"
    end
  end

  describe "drift ledger" do
    test "every Kati edit to the vendored bridge is fenced" do
      bridge = File.read!(@bridge)
      starts = bridge |> String.split("KATI-BEGIN") |> length() |> Kernel.-(1)
      ends = bridge |> String.split("KATI-END") |> length() |> Kernel.-(1)

      assert starts == ends, "unbalanced patch fences: #{starts} starts, #{ends} ends"
      assert starts > 0, "expected fenced Kati edits in the vendored bridge"
    end
  end
end
