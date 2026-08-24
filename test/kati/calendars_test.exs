defmodule Kati.CalendarsTest do
  @moduledoc """
  Schema behaviour against a real SQLite file, not a mock.

  The range-query design rests on assumptions about how ecto_sqlite3 actually
  stores things, so those are proven here rather than assumed.
  """
  use ExUnit.Case, async: false

  alias Kati.Calendars.{Calendar, Event}

  # `Kati.Screens.Calendars` reads `calendars` now — its "which calendars show"
  # group is `stored_calendars/0` — so the twelve `Test N` rows this module's
  # `setup` used to leave behind are twelve rows on somebody else's screen.
  # `Kati.ScreenDesignLiteralTest` renders screen 32 at an arbitrary point in the
  # run and compares its copy with `test/design/screens/32.html`; with these
  # rows standing it drew them instead of the drawing's four, and whether it
  # passed depended on `--seed`.
  #
  # Same reasoning and the same wipe as `Kati.SeedsTest`, whose own teardown puts
  # it plainly: what this module leaves behind is not inert.
  setup_all do
    on_exit(&empty_the_calendar_tables!/0)
    :ok
  end

  # Child tables first: overrides and events carry the foreign keys.
  defp empty_the_calendar_tables! do
    for table <- ~w(event_occurrence_overrides events calendars calendar_accounts),
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  setup do
    {:ok, cal} =
      Calendar
      |> Ash.Changeset.for_create(:create, %{
        display_name: "Test #{System.unique_integer([:positive])}",
        kind: :local
      })
      |> Ash.create()

    {:ok, calendar: cal}
  end

  defp event!(cal, attrs) do
    Event
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          uid: "uid-#{System.unique_integer([:positive])}@kati",
          calendar_id: cal.id,
          origin: :kati,
          summary: "thing"
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  describe "storage assumptions the range queries rest on" do
    test "utc_datetime_usec sorts lexicographically in instant order", %{calendar: cal} do
      # ecto_sqlite3 stores these as fixed-width ISO-8601 text, and UUIDs as text
      # too. If text order and
      # instant order ever diverged, every events_in_range query would be wrong.
      times = [
        ~U[2026-01-01 09:00:00.000000Z],
        ~U[2026-01-01 09:00:00.000001Z],
        ~U[2026-01-01 10:00:00.000000Z],
        ~U[2026-02-01 09:00:00.000000Z],
        ~U[2027-01-01 09:00:00.000000Z]
      ]

      for t <- Enum.shuffle(times), do: event!(cal, %{dtstart_utc: t})

      {:ok, %{rows: rows}} =
        Ecto.Adapters.SQL.query(
          Kati.Repo,
          "select dtstart_utc from events where calendar_id = ? order by dtstart_utc",
          [cal.id]
        )

      stored = Enum.map(rows, &hd/1)
      assert stored == Enum.sort(stored), "text order must equal instant order"
      assert length(stored) == 5
    end
  end

  describe "origin immutability" do
    test "a mirrored event cannot become a Kati-owned one", %{calendar: cal} do
      e = event!(cal, %{origin: :mirror})

      assert {:error, _} =
               e
               |> Ash.Changeset.for_update(:update, %{origin: :kati})
               |> Ash.update()
    end

    test "setting the same origin again is not an error", %{calendar: cal} do
      e = event!(cal, %{origin: :kati})

      assert {:ok, _} =
               e |> Ash.Changeset.for_update(:update, %{origin: :kati}) |> Ash.update()
    end
  end

  describe "dirty tracking" do
    test "local_rev bumps on every write, synced_rev does not", %{calendar: cal} do
      e = event!(cal, %{summary: "one"})
      assert e.local_rev == 1
      assert e.synced_rev == 0

      {:ok, e2} = e |> Ash.Changeset.for_update(:update, %{summary: "two"}) |> Ash.update()
      assert e2.local_rev == 2
      assert e2.synced_rev == 0

      # local_rev > synced_rev is what "dirty" means.
      assert e2.local_rev > e2.synced_rev
    end
  end

  describe "derived timing" do
    test "dtend_utc is recomputed from duration_iso, never trusted", %{calendar: cal} do
      e =
        event!(cal, %{
          dtstart_utc: ~U[2026-08-16 09:00:00.000000Z],
          duration_iso: "PT1H30M",
          # A deliberately wrong dtend: it must be overwritten.
          dtend_utc: ~U[2030-01-01 00:00:00.000000Z]
        })

      assert DateTime.compare(e.dtend_utc, ~U[2026-08-16 10:30:00.000000Z]) == :eq
    end

    test "recurs_until_utc is nil for an unbounded rule", %{calendar: cal} do
      e = event!(cal, %{dtstart_utc: ~U[2026-08-16 09:00:00.000000Z], rrule: "FREQ=DAILY"})
      assert is_nil(e.recurs_until_utc)
    end

    test "recurs_until_utc is set from UNTIL so expired masters can be pruned", %{calendar: cal} do
      e =
        event!(cal, %{
          dtstart_utc: ~U[2026-08-16 09:00:00.000000Z],
          rrule: "FREQ=DAILY;UNTIL=20260820T090000Z"
        })

      assert DateTime.compare(e.recurs_until_utc, ~U[2026-08-20 09:00:00Z]) == :eq
    end

    test "a non-recurring event ends when it ends", %{calendar: cal} do
      e = event!(cal, %{dtstart_utc: ~U[2026-08-16 09:00:00.000000Z]})
      assert DateTime.compare(e.recurs_until_utc, ~U[2026-08-16 09:00:00.000000Z]) == :eq
    end
  end

  describe "all-day events" do
    test "are date-valued, never midnight instants", %{calendar: cal} do
      e = event!(cal, %{is_all_day: true, dtstart_date: ~D[2026-08-16]})

      assert e.is_all_day
      assert e.dtstart_date == ~D[2026-08-16]
      # Storing a midnight instant is what makes an all-day event shift a day
      # when the user flies.
      assert is_nil(e.dtstart_utc)
    end
  end

  describe "tombstones" do
    test "soft_delete marks rather than removes, so sync can propagate it", %{calendar: cal} do
      e = event!(cal, %{summary: "doomed"})

      {:ok, deleted} = e |> Ash.Changeset.for_update(:soft_delete, %{}) |> Ash.update()

      assert deleted.deleted_at
      assert deleted.local_rev > e.local_rev

      # Still present in the table: a synced row that vanishes cannot be told
      # apart from one that never existed, and the other end would resurrect it.
      assert {:ok, _} = Ash.get(Event, e.id)
    end
  end

  describe "floating time" do
    test "tzid nil means floating, which is a value not a gap", %{calendar: cal} do
      e = event!(cal, %{tz_behaviour: :floating, tzid: nil, dtstart_wall: "20260816T090000"})

      assert is_nil(e.tzid)
      assert e.tz_behaviour == :floating
      assert e.dtstart_wall == "20260816T090000"
    end
  end

  describe "lossless round-tripping" do
    test "unknown properties survive as JSON text", %{calendar: cal} do
      json = ~s({"X-APPLE-TRAVEL-DURATION":"PT30M"})
      e = event!(cal, %{unknown_props: json, raw_icalendar: "BEGIN:VEVENT\nEND:VEVENT"})

      {:ok, reloaded} = Ash.get(Event, e.id)
      assert reloaded.unknown_props == json
      assert reloaded.raw_icalendar =~ "VEVENT"
    end
  end
end
