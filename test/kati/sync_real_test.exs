Code.require_file("../support/sync_schema.exs", __DIR__)
Code.require_file("../support/sync_fixtures.exs", __DIR__)

defmodule Kati.SyncRealTest do
  @moduledoc """
  `Kati.Screens.Sync` draws the store, and never board 270.

  `fake_hardcoded.md` recorded this page as "always fake", on the strength of
  its moduledoc saying no drawing existed. The audit that followed found the
  opposite — every figure was already a read — and a few things that were not
  data but were still untrue: an empty Accounts card pointing at a *Connect*
  door screen 32 does not have, a phone-mirrored calendar attributed to *this
  device*, and three chevrons promising pages the answers never open.

  `Kati.ScreenSyncTest` holds the page's behaviour row by row. This file holds
  the one claim that audit turned on, from both ends:

    * **Seeded rows come back.** An account, a calendar under it, a queued
      edit and a conflict are written through the real actions, and the page
      is asserted to name each of them — the account's name and state, the
      calendar's name and when it last sent, the event in the outbox, the
      question — with the tallies counting exactly those rows.
    * **Board 270's values never appear.** 270 is the drawing that arrived
      after the page, and every value on it is a sample: *iCloud*,
      *work@studio.co*, *6 MIN AGO*, the 4 / 1 / 1 strip. Neither an empty
      store nor a seeded one may draw any of them.

  The wipe is `Kati.ScreenSyncTest`'s, for its reason: one SQLite file, no
  sandbox, and a leftover calendar is a row on another screen.
  """
  use Mob.ScreenCase, async: false

  import Kati.SyncFixtures

  alias Kati.Calendars.Account
  alias Kati.Screens.Sync, as: Screen

  @tables ~w(
    sync_outbox sync_rejected_changes
    event_occurrence_overrides events calendars calendar_accounts
  )

  # Every sample value board 270 draws that a store-backed page could only
  # show by copying it: the account and calendar names, the account lines,
  # the subtitle, the outbox's events and the kept edits.
  @board_270 [
    "iCloud",
    "work@studio.co",
    "fastmail",
    "Token expired",
    "Last sync 4h ago",
    "LAST SENT 6 MIN AGO",
    "3 CALENDARS",
    "Personal",
    "Family",
    "Birthdays",
    "Design review",
    "Standup",
    "Plumber",
    "Lunch with Jo",
    "Moved to 09:45",
    "6 more, not shown",
    "Set aside 18 Aug"
  ]

  setup_all do
    Kati.SyncSchema.ensure!()
    :ok
  end

  setup do
    empty!()
    on_exit(&empty!/0)
    :ok
  end

  defp empty! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  defp page, do: mount_screen(Screen)
  defp texts(tree), do: tree |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))
  defp says?(tree, needle), do: Enum.any?(texts(tree), &String.contains?(&1, needle))

  defp fixtures_drawn(tree) do
    Enum.filter(@board_270, &says?(tree, &1))
  end

  defp hours_ago(n), do: DateTime.add(DateTime.utc_now(), -n * 3600, :second)

  defp seed! do
    account =
      Account
      |> Ash.Changeset.for_create(:create, %{
        provider: :caldav,
        display_name: "Mishka DAV",
        state: :stale,
        last_sync_at: hours_ago(2)
      })
      |> Ash.create!()

    calendar =
      calendar!(%{
        display_name: "Reading group",
        kind: :provider,
        account_id: account.id,
        remote_id: unique("remote-cal"),
        writeback_policy: :kati_only,
        last_sync_at: hours_ago(3)
      })

    queued = event!(calendar, %{summary: "Chapter nine", remote_id: unique("remote")})
    {:ok, _} = Kati.Sync.edit(queued, calendar, %{summary: "Chapter ten"})

    event!(calendar, %{summary: "Author visit", sync_state: :conflicted})

    %{account: account, calendar: calendar}
  end

  describe "an empty store" do
    test "draws none of board 270's values" do
      assert fixtures_drawn(tree(page())) == []
    end

    test "counts nothing, because there is nothing" do
      state = Screen.state()

      assert {state.waiting, state.stuck, length(state.conflicts)} == {0, 0, 0}
      assert state.last_sync_at == nil
    end

    test "says Kati cannot sign in to an account, not that one can be connected" do
      t = tree(page())

      assert says?(t, "No account is connected")
      assert says?(t, "Kati cannot sign in to a calendar account yet")
      refute says?(t, "Connect one in Calendars")
    end
  end

  describe "a seeded store" do
    setup do
      {:ok, seed!()}
    end

    test "names the account from its own row, with its stored state and last poll" do
      t = tree(page())

      assert says?(t, "Mishka DAV")
      assert says?(t, "1 calendar · last checked 2h ago")
      assert says?(t, "Stale")
    end

    test "names the calendar under its account, and when it last sent" do
      t = tree(page())

      assert says?(t, "Reading group")
      assert says?(t, "Mishka DAV · 1 change waiting")
      assert Screen.subtitle(Screen.state()) == "1 CALENDAR · LAST SENT 3H AGO"
    end

    test "draws the queued edit and the conflict it holds" do
      t = tree(page())

      assert says?(t, "Changed · Chapter ten")
      assert says?(t, "Author visit")
      assert says?(t, "Take Reading group's")
    end

    test "the tallies count exactly the rows that were written" do
      state = Screen.state()

      assert state.waiting == 1
      assert state.stuck == 0
      assert length(state.conflicts) == 1
      assert length(state.outbox) == 1
    end

    test "still draws none of board 270's values" do
      assert fixtures_drawn(tree(page())) == []
    end
  end

  describe "who a calendar belongs to, when no account is stored" do
    test "a calendar mirrored from the phone is the phone's, not this device's" do
      calendar!(%{display_name: "Holidays", kind: :provider, writeback_policy: :none})
      t = tree(page())

      assert says?(t, "The phone's calendars · write-back is off")
      refute says?(t, "This device · write-back is off")
    end

    test "a calendar Kati keeps itself is this device's" do
      calendar!(%{display_name: "Habits", kind: :local})

      assert says?(tree(page()), "This device · local calendar, nothing is ever sent")
    end
  end

  describe "the answers to a question" do
    test "resolve in place, so they carry a Choose pill and no chevron" do
      seed!()
      t = tree(page())

      assert Enum.count(texts(t), &(&1 == "Choose")) == 3
      refute Kati.Locale.forward_chevron() in texts(t)
    end
  end
end
