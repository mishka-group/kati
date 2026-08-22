defmodule Kati.SyncMergeTest do
  @moduledoc """
  The three-way merge, on real documents, asserting on content.

  Every case here names what came out the far side. A test that only asserted
  the return tag would pass against a merge that returned `{:merged, %{}}` and
  dropped both sides, which is the failure mode worth guarding.
  """
  use ExUnit.Case, async: true

  alias Kati.Sync.ICalendar
  alias Kati.Sync.Merge

  defp doc(overrides \\ %{}) do
    base = """
    BEGIN:VCALENDAR\r
    VERSION:2.0\r
    BEGIN:VEVENT\r
    UID:merge-1@kati\r
    DTSTAMP:20260810T120000Z\r
    LAST-MODIFIED:20260810T120000Z\r
    DTSTART;TZID=Europe/London:20260812T090000\r
    DURATION:PT30M\r
    RRULE:FREQ=WEEKLY;BYDAY=WE\r
    SUMMARY:Standup\r
    LOCATION:Room 4\r
    X-MOZ-LASTACK:20260101T093000Z\r
    END:VEVENT\r
    END:VCALENDAR\r
    """

    {:ok, patched} = ICalendar.apply_lines(base, overrides)
    patched
  end

  defp props(raw) do
    {:ok, properties} = ICalendar.properties(raw)
    properties
  end

  defp value(raw, name), do: raw |> props() |> Map.get(name) |> hd() |> ICalendar.line_value()

  # ── Stage 1: disjoint ──────────────────────────────────────────────────────

  test "different fields changed on each side both survive" do
    base = doc()
    local = doc(%{"SUMMARY" => "SUMMARY:Standup (async)"})
    remote = doc(%{"LOCATION" => "LOCATION:Room 9"})

    assert {:merged, merged} = Merge.merge_raw(base, local, remote, :mirror)

    assert value(merged, "SUMMARY") == "Standup (async)"
    assert value(merged, "LOCATION") == "Room 9"
    assert value(merged, "DURATION") == "PT30M"
  end

  test "a merge patches the remote document, so the server's own additions survive" do
    base = doc()
    local = doc(%{"SUMMARY" => "SUMMARY:Standup (async)"})

    remote =
      doc(%{
        "LOCATION" => "LOCATION:Room 9",
        "X-GOOGLE-CONFERENCE" => "X-GOOGLE-CONFERENCE:https://meet.example/abc-defg"
      })

    assert {:merged, merged} = Merge.merge_raw(base, local, remote, :mirror)

    assert String.contains?(merged, "X-GOOGLE-CONFERENCE:https://meet.example/abc-defg"),
           "a property the server added while Kati was offline was thrown away"

    assert String.contains?(merged, "X-MOZ-LASTACK:20260101T093000Z")
    assert value(merged, "SUMMARY") == "Standup (async)"
  end

  test "both sides making the same change is agreement, not conflict" do
    base = doc()
    same = doc(%{"SUMMARY" => "SUMMARY:Standup (async)"})

    assert {:merged, merged} = Merge.merge_raw(base, same, same, :mirror)
    assert value(merged, "SUMMARY") == "Standup (async)"
  end

  test "a property added on one side and untouched on the other is kept" do
    base = doc()
    local = doc(%{"DESCRIPTION" => "DESCRIPTION:Bring the roadmap"})
    remote = doc(%{"LOCATION" => "LOCATION:Room 9"})

    assert {:merged, merged} = Merge.merge_raw(base, local, remote, :mirror)
    assert value(merged, "DESCRIPTION") == "Bring the roadmap"
    assert value(merged, "LOCATION") == "Room 9"
  end

  # ── Stage 2: overlap falls to ownership ────────────────────────────────────

  test "the same field changed both ways: origin :kati keeps the local value" do
    base = doc()
    local = doc(%{"SUMMARY" => "SUMMARY:Standup — mine"})
    remote = doc(%{"SUMMARY" => "SUMMARY:Standup — theirs", "LOCATION" => "LOCATION:Room 9"})

    assert {:resolved, :local, merged, rejected} = Merge.merge_raw(base, local, remote, :kati)

    assert value(merged, "SUMMARY") == "Standup — mine"
    # The remote's *uncontested* change still lands.
    assert value(merged, "LOCATION") == "Room 9"

    assert rejected.side == :remote
    assert rejected.reason == :ownership_kati
    assert rejected.properties == %{"SUMMARY" => ["SUMMARY:Standup — theirs"]}
    assert rejected.base_properties == %{"SUMMARY" => ["SUMMARY:Standup"]}
  end

  test "the same field changed both ways: origin :mirror keeps the remote value and preserves the local edit" do
    base = doc()
    local = doc(%{"SUMMARY" => "SUMMARY:Standup — mine", "DESCRIPTION" => "DESCRIPTION:Notes"})
    remote = doc(%{"SUMMARY" => "SUMMARY:Standup — theirs"})

    assert {:resolved, :remote, merged, rejected} = Merge.merge_raw(base, local, remote, :mirror)

    assert value(merged, "SUMMARY") == "Standup — theirs"
    # The local *uncontested* change is not collateral damage.
    assert value(merged, "DESCRIPTION") == "Notes"

    assert rejected.side == :local
    assert rejected.reason == :ownership_mirror

    assert rejected.properties == %{"SUMMARY" => ["SUMMARY:Standup — mine"]},
           "the losing local edit was discarded instead of preserved"
  end

  test "entangled timing changed on both sides is contested even when the names differ" do
    base = doc()
    local = doc(%{"DTSTART" => "DTSTART;TZID=Europe/London:20260812T100000"})
    remote = doc(%{"RRULE" => "RRULE:FREQ=DAILY"})

    assert {:resolved, :remote, merged, rejected} = Merge.merge_raw(base, local, remote, :mirror)

    # Neither a daily 10:00 series nor a silent merge: one side's whole timing
    # description wins and the other is preserved.
    assert value(merged, "RRULE") == "FREQ=DAILY"
    assert value(merged, "DTSTART") == "20260812T090000"
    assert Map.has_key?(rejected.properties, "DTSTART")
  end

  test "a lone timing change on one side still merges" do
    base = doc()
    local = doc(%{"DTSTART" => "DTSTART;TZID=Europe/London:20260812T100000"})
    remote = doc(%{"LOCATION" => "LOCATION:Room 9"})

    assert {:merged, merged} = Merge.merge_raw(base, local, remote, :mirror)
    assert value(merged, "DTSTART") == "20260812T100000"
    assert value(merged, "LOCATION") == "Room 9"
  end

  # ── Stage 3: unresolvable ──────────────────────────────────────────────────

  test "deleted locally, edited remotely is unresolvable" do
    base = doc()
    remote = doc(%{"SUMMARY" => "SUMMARY:Standup — theirs"})

    assert {:unresolvable, :delete_edit, context} =
             Merge.merge_raw(base, :deleted, remote, :mirror)

    assert context.deleted_by == :local
    assert context.edited_by == :remote
  end

  test "deleted remotely, edited locally is unresolvable" do
    base = doc()
    local = doc(%{"SUMMARY" => "SUMMARY:Standup — mine"})

    assert {:unresolvable, :delete_edit, context} = Merge.merge_raw(base, local, :deleted, :kati)
    assert context.deleted_by == :remote
    assert context.edited_by == :local
  end

  test "a remote delete over an unchanged local row is not a conflict" do
    base = doc()
    assert {:merged, :deleted} = Merge.merge_raw(base, base, :deleted, :mirror)
  end

  test "a local delete over an unmoved remote is not a conflict" do
    base = doc()
    assert {:merged, :deleted} = Merge.merge_raw(base, :deleted, base, :mirror)
  end

  test "both sides deleted is agreement" do
    assert {:merged, :deleted} = Merge.merge_raw(doc(), :deleted, :deleted, :mirror)
  end

  test "no base is unresolvable rather than a silent overwrite" do
    local = doc(%{"SUMMARY" => "SUMMARY:Standup — mine"})
    remote = doc(%{"SUMMARY" => "SUMMARY:Standup — theirs"})

    assert {:unresolvable, :no_base, _context} = Merge.merge_raw(nil, local, remote, :mirror)
  end

  # ── Clock skew ─────────────────────────────────────────────────────────────

  test "timestamps three minutes apart, or seven years apart, change no outcome" do
    base = doc()
    local = doc(%{"SUMMARY" => "SUMMARY:Standup — mine"})
    remote = doc(%{"SUMMARY" => "SUMMARY:Standup — theirs"})

    skewed_local =
      doc(%{
        "SUMMARY" => "SUMMARY:Standup — mine",
        "DTSTAMP" => "DTSTAMP:20190101T000000Z",
        "LAST-MODIFIED" => "LAST-MODIFIED:20190101T000000Z"
      })

    skewed_remote =
      doc(%{
        "SUMMARY" => "SUMMARY:Standup — theirs",
        "DTSTAMP" => "DTSTAMP:20990101T000000Z",
        "LAST-MODIFIED" => "LAST-MODIFIED:20990101T000000Z"
      })

    {:resolved, straight_winner, straight, _} = Merge.merge_raw(base, local, remote, :kati)

    {:resolved, skewed_winner, skewed, _} =
      Merge.merge_raw(base, skewed_local, skewed_remote, :kati)

    assert straight_winner == :local
    assert skewed_winner == :local

    assert value(straight, "SUMMARY") == value(skewed, "SUMMARY"),
           "a wall-clock timestamp changed which edit survived"

    # And the other direction: a 2099 local clock does not beat ownership.
    {:resolved, mirror_winner, mirror, _} =
      Merge.merge_raw(base, skewed_remote, skewed_local, :mirror)

    assert mirror_winner == :remote
    assert value(mirror, "SUMMARY") == "Standup — mine"
  end
end
