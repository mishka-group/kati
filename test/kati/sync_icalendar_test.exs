defmodule Kati.SyncICalendarTest do
  @moduledoc """
  The lossless write-back rule, proven on bytes.

  Every assertion here is about **what survived**, not about what the patcher
  produced. A test that only checked the new title would pass against a
  regenerate-from-columns pipeline, which is the exact implementation this
  module exists to forbid.
  """
  use ExUnit.Case, async: true

  alias Kati.Sync.ICalendar

  # A real-shaped VEVENT: a folded Apple geofence, Outlook's busy status,
  # Thunderbird's snooze state, and a VALARM whose DESCRIPTION must not be
  # mistaken for the event's.
  @apple "X-APPLE-STRUCTURED-LOCATION;VALUE=URI;X-ADDRESS=\"1 Infinite Loop, Cup\r\n ertino CA 95014\";X-APPLE-RADIUS=100;X-TITLE=Work:geo:37.33182,-122.03118"
  @busy "X-MICROSOFT-CDO-BUSYSTATUS:BUSY"
  @moz "X-MOZ-LASTACK:20260101T093000Z"

  defp document do
    """
    BEGIN:VCALENDAR\r
    VERSION:2.0\r
    PRODID:-//Example Corp//NONSGML v1.0//EN\r
    BEGIN:VEVENT\r
    UID:9f4e-2211@example.com\r
    DTSTAMP:20260810T120000Z\r
    DTSTART;TZID=Europe/London:20260812T090000\r
    DURATION:PT30M\r
    SUMMARY:Daily standup\r
    LOCATION:Room 4\r
    SEQUENCE:2\r
    #{@apple}\r
    #{@busy}\r
    #{@moz}\r
    BEGIN:VALARM\r
    ACTION:DISPLAY\r
    DESCRIPTION:Standup in 10 minutes\r
    TRIGGER:-PT10M\r
    END:VALARM\r
    END:VEVENT\r
    END:VCALENDAR\r
    """
  end

  test "a title-only edit leaves every vendor property byte-identical" do
    {:ok, patched} = ICalendar.patch(document(), %{"SUMMARY" => "Daily standup (moved)"})

    assert String.contains?(patched, @apple),
           "the folded X-APPLE-STRUCTURED-LOCATION did not survive verbatim"

    assert String.contains?(patched, @busy)
    assert String.contains?(patched, @moz)
    assert String.contains?(patched, "SUMMARY:Daily standup (moved)")
    refute String.contains?(patched, "SUMMARY:Daily standup\r\n")

    # Everything except the one line is untouched, counted rather than eyeballed.
    original_lines = String.split(document(), "\r\n")
    patched_lines = String.split(patched, "\r\n")
    assert length(original_lines) == length(patched_lines)
    assert Enum.count(Enum.zip(original_lines, patched_lines), fn {a, b} -> a != b end) == 1
  end

  test "the VALARM's DESCRIPTION is not the event's" do
    {:ok, props} = ICalendar.properties(document())

    refute Map.has_key?(props, "DESCRIPTION"),
           "a nested VALARM property leaked into the event's property set"

    {:ok, patched} = ICalendar.patch(document(), %{"DESCRIPTION" => "Event notes"})
    assert String.contains?(patched, "DESCRIPTION:Standup in 10 minutes")
    assert String.contains?(patched, "DESCRIPTION:Event notes")
    assert length(String.split(patched, "DESCRIPTION:")) == 3
  end

  test "properties are read as whole content lines, parameters included" do
    {:ok, props} = ICalendar.properties(document())

    assert props["DTSTART"] == ["DTSTART;TZID=Europe/London:20260812T090000"]
    assert props["SUMMARY"] == ["SUMMARY:Daily standup"]
    assert ICalendar.line_value(props["DTSTART"] |> hd()) == "20260812T090000"
  end

  test "SEQUENCE increments, and an absent SEQUENCE starts at one" do
    {:ok, bumped} = ICalendar.bump_sequence(document())
    assert String.contains?(bumped, "SEQUENCE:3")
    refute String.contains?(bumped, "SEQUENCE:2")

    without = String.replace(document(), "SEQUENCE:2\r\n", "")
    {:ok, first} = ICalendar.bump_sequence(without)
    assert String.contains?(first, "SEQUENCE:1")
  end

  test "removing a property removes only that property" do
    {:ok, patched} = ICalendar.patch(document(), %{"LOCATION" => nil})

    refute String.contains?(patched, "LOCATION:Room 4")
    assert String.contains?(patched, @apple), "X-APPLE-STRUCTURED-LOCATION was collateral damage"
  end

  test "TEXT values are escaped and non-TEXT values are not" do
    {:ok, patched} =
      ICalendar.patch(document(), %{
        "SUMMARY" => "Lunch, then; review",
        "DTSTART" => "20260812T100000Z"
      })

    assert String.contains?(patched, "SUMMARY:Lunch\\, then\\; review")
    assert String.contains?(patched, "DTSTART:20260812T100000Z")
  end

  test "a new long property is folded at 75 octets with a leading space" do
    long = String.duplicate("a", 300)
    {:ok, patched} = ICalendar.patch(document(), %{"DESCRIPTION" => long})

    physical =
      patched
      |> String.split("\r\n")
      |> Enum.drop_while(&(not String.starts_with?(&1, "DESCRIPTION:" <> String.slice(long, 0, 5))))
      |> Enum.take_while(&(&1 != "END:VEVENT"))

    assert length(physical) > 1, "a 300-character value was not folded at all"
    assert Enum.all?(physical, &(byte_size(&1) <= 75))
    assert Enum.all?(tl(physical), &String.starts_with?(&1, " "))

    # And it unfolds back to exactly what went in.
    {:ok, props} = ICalendar.properties(patched)
    assert ICalendar.line_value(hd(props["DESCRIPTION"])) == long
  end

  test "multi-byte characters are never split across a fold" do
    persian = String.duplicate("سلام ", 40)
    {:ok, patched} = ICalendar.patch(document(), %{"DESCRIPTION" => persian})
    {:ok, props} = ICalendar.properties(patched)

    assert ICalendar.line_value(hd(props["DESCRIPTION"])) == persian
    assert String.valid?(patched)
  end

  test "a document with no VEVENT is an error, not an empty event" do
    only_timezone = "BEGIN:VCALENDAR\r\nBEGIN:VTIMEZONE\r\nTZID:UTC\r\nEND:VTIMEZONE\r\nEND:VCALENDAR\r\n"

    assert ICalendar.properties(only_timezone) == {:error, :no_vevent}
    assert ICalendar.patch(only_timezone, %{"SUMMARY" => "x"}) == {:error, :no_vevent}
  end

  test "LF-only documents keep LF line endings" do
    lf = String.replace(document(), "\r\n", "\n")
    {:ok, patched} = ICalendar.patch(lf, %{"SUMMARY" => "Changed"})

    refute String.contains?(patched, "\r\n")
    assert String.contains?(patched, "SUMMARY:Changed\n")
  end

  test "a repeated property is replaced as a set, not multiplied" do
    with_exdates =
      String.replace(
        document(),
        "SEQUENCE:2\r\n",
        "SEQUENCE:2\r\nEXDATE:20260813T090000Z\r\nEXDATE:20260814T090000Z\r\n"
      )

    {:ok, props} = ICalendar.properties(with_exdates)
    assert length(props["EXDATE"]) == 2

    {:ok, patched} =
      ICalendar.apply_lines(with_exdates, %{"EXDATE" => ["EXDATE:20260815T090000Z"]})

    {:ok, after_props} = ICalendar.properties(patched)
    assert after_props["EXDATE"] == ["EXDATE:20260815T090000Z"]
  end
end
