defmodule Kati.TimeTest do
  @moduledoc """
  The two cases RFC 5545 leaves to the implementation, plus the fixed-offset
  case Kati's primary non-English locale lives in.
  """
  use ExUnit.Case, async: true

  setup_all do
    Kati.Runtime.configure()
    :ok
  end

  test "a real timezone database is installed, not the UTC-only stub" do
    refute Calendar.get_time_zone_database() == Calendar.UTCOnlyTimeZoneDatabase
    assert Calendar.get_time_zone_database() == Tz.TimeZoneDatabase
  end

  test "the IANA release is known, so a bug report can name it" do
    assert Kati.Time.iana_version() =~ ~r/^\d{4}[a-z]$/
  end

  describe "Asia/Tehran" do
    test "is a fixed +03:30 — Iran abolished DST in 2022" do
      {:ok, summer, :exact} = Kati.Time.resolve(~N[2026-08-16 07:30:00], "Asia/Tehran")
      {:ok, winter, :exact} = Kati.Time.resolve(~N[2026-01-16 07:30:00], "Asia/Tehran")

      assert summer.utc_offset + summer.std_offset == 12_600
      assert winter.utc_offset + winter.std_offset == 12_600
    end
  end

  describe "gaps and ambiguity" do
    test "a spring-forward gap resolves to the instant AFTER, not dropped" do
      {:ok, dt, :gap} = Kati.Time.resolve(~N[2026-03-29 01:30:00], "Europe/London")

      # RFC 5545 would drop this. Kati fires the alarm rather than silently
      # losing it once a year.
      assert dt.hour == 2
      assert dt.std_offset == 3600
    end

    test "an ambiguous fall-back resolves to the FIRST occurrence" do
      {:ok, dt, :ambiguous} = Kati.Time.resolve(~N[2026-10-25 01:30:00], "Europe/London")

      # The earlier of the two: a reminder fires at the first opportunity
      # rather than an hour late.
      assert dt.std_offset == 3600
    end

    test "the resolution is reported so a caller can tell the user" do
      assert {:ok, _, :exact} = Kati.Time.resolve(~N[2026-06-01 12:00:00], "Europe/London")
      assert {:ok, _, :gap} = Kati.Time.resolve(~N[2026-03-29 01:30:00], "Europe/London")
      assert {:ok, _, :ambiguous} = Kati.Time.resolve(~N[2026-10-25 01:30:00], "Europe/London")
    end
  end

  describe "round trips" do
    test "wall clock to UTC and back is stable for an unambiguous time" do
      naive = ~N[2026-08-16 07:30:00]
      {:ok, utc} = Kati.Time.to_utc(naive, "Asia/Tehran")

      assert utc.time_zone == "Etc/UTC"
      assert utc.hour == 4 and utc.minute == 0

      back = Kati.Time.in_zone(utc, "Asia/Tehran")
      assert NaiveDateTime.compare(DateTime.to_naive(back), naive) == :eq
    end

    test "an unknown zone is an error, not a crash" do
      assert {:error, _} = Kati.Time.resolve(~N[2026-08-16 07:30:00], "Mars/Olympus")
    end
  end

  describe "device zone" do
    test "falls back to Etc/UTC rather than crashing when unavailable" do
      assert Kati.Time.device_zone() in [Kati.Time.device_zone()]
      assert is_binary(Kati.Time.device_zone())
      assert Kati.Time.valid_zone?(Kati.Time.device_zone())
    end

    test "validates zone ids" do
      assert Kati.Time.valid_zone?("Europe/Amsterdam")
      assert Kati.Time.valid_zone?("Asia/Tehran")
      refute Kati.Time.valid_zone?("Not/AZone")
      refute Kati.Time.valid_zone?(nil)
    end
  end
end
