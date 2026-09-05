defmodule Kati.MedicationHonestPageTest do
  @moduledoc """
  Screen 112 states nothing about a reader that the reader's own rows do not
  carry — the six defects six reviewers found in D-59's first pass.

  D-59 moved three of screen 112's four bands onto the reader's own data and
  each of these is a place the move was incomplete or a place it opened a door
  that was not there before. They are written as one file because they are one
  claim, and it is the claim the ticket's acceptance is written in: *the header
  count, TODAY and SCHEDULES are all the reader's or all the drawing's, never
  one of each* — plus the fourth band nothing had noticed was still the
  drawing's.

  What each describes, in the order the page draws it:

    * **The card with nothing on its second line.** Board 188 saves a
      medication with a name and nothing else, so
      `Kati.Health.Medication.dose_line/1` answers `""` for a real prescription
      — and a dose row could not exist to print it until today's doses started
      being derived. The card drew a `<Spacer>` and an empty `<Text>` under the
      name, and once that dose's time had passed it drew ` · MISSED`: a leading
      middot with nothing before it. `Kati.MedicationWriteTest` already treats
      that shape as a defect one function over, asserting
      `refute Medication.schedule_line(row) =~ " ·  · "`.
    * **A failure that could not have happened.** A dose derived for 08:00 on
      the day the medication was typed in at 15:00 was drawn `· MISSED` with
      the gold ✗. Nothing in the app knew anything about that 08:00 — the row
      did not exist and `Kati.Notifications.Sources.Health` arms forward — so
      the page was asserting a failure against somebody's first prescription,
      and `undecided/1` then aimed the two verbs at the phantom.
    * **A tick that landed twice.** A derived dose is drawn with three tags and
      `save_dose/2`'s create clause looked nothing up, so any caller pressing
      more than one of them against the same socket wrote a duplicate
      `health_doses` row for one (medication, day, time).
      `Kati.ScreenWriteTargetTest`'s sweep is exactly such a caller.
    * **The reminder card.** Still `Kati.Health.WeightSample.reminder/0`
      unconditionally — a 21:00 Magnesium under a heading, on the page of a
      person taking one 08:00 tablet, in a card the screen's own moduledoc
      calls *drawn as the notification it becomes*.
    * **The two identity-less Persian verbs.** `next_undecided/1` re-read the
      store at tap time, which is the shape `Kati.ScreenWriteTargetTest`'s
      moduledoc names as the bug — *a re-read of the shelf at tap time is the
      bug* — so a dose decided elsewhere between draw and tap moved the row the
      chips landed on.

  ## Why the card tests flatten a NODE rather than a page

  `dose_row/1` and `Kati.Screens.HealthFa.dose_card/1` are handed one row and
  asked what they drew, so an empty `<Text>` anywhere else on the page cannot
  make one of these pass or fail. `Mob.ScreenCase.flatten/1` takes a node as
  readily as a view, which is what makes that possible.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Health.WeightSample
  alias Kati.Notifications.Sources.Health
  alias Kati.Screens.HealthFa
  alias Kati.Screens.Medication, as: MedicationScreen

  # The two composition rules the blank-line defects come out of.
  doctest Kati.Screens.Medication, only: [state_line: 1, said: 1]

  setup do
    # Doses before medications, because SQLite holds the foreign key — and on
    # the way in as well as out, because half of what is asserted here is that
    # the page is NOT the drawing's, which a neighbour's leaked row turns into
    # a mystery.
    wipe = fn ->
      Kati.Repo.query!("DELETE FROM health_doses", [])
      Kati.Repo.query!("DELETE FROM health_medications", [])
    end

    wipe.()
    on_exit(wipe)

    :ok
  end

  defp a_medication!(attrs) do
    Ash.create!(
      Medication,
      Map.merge(%{name: "Metformin", dose: "500 mg", schedule: "daily", times: ["08:00"]}, attrs)
    )
  end

  # A medication saved with the bare minimum board 188 allows: a name, and both
  # optional fields stored as `nil` by `Kati.Screens.AddMedication.blank_to_nil/1`.
  # `Kati.MedicationWriteTest` pins that as a supported save.
  defp name_only!(times) do
    Ash.create!(Medication, %{name: "Iron", times: times})
  end

  defp texts(view_or_node) do
    for node <- flatten(view_or_node),
        text = Map.get(Map.get(node, :props) || %{}, :text),
        is_binary(text),
        do: text
  end

  describe "a card with nothing to put on its second line" do
    test "draws no second line at all rather than an empty one" do
      drawn =
        MedicationScreen.dose_row(%{
          time: "08:00",
          name: "Iron",
          line: "",
          state: :due,
          tap: :dose_x
        })

      strings = texts(drawn)

      assert "Iron" in strings

      refute "" in strings,
             "the card drew a blank row under the name — the empty <Text> and its <Spacer> go together"
    end

    test "a missed one says MISSED without a middot in front of it" do
      drawn =
        MedicationScreen.dose_row(%{
          time: "08:00",
          name: "Iron",
          line: "",
          state: :missed,
          tap: :dose_x
        })

      strings = texts(drawn)

      assert "MISSED" in strings
      refute " · MISSED" in strings
      refute "" in strings
    end

    test "and a card that HAS a line is unchanged, to the node" do
      # The other direction, and it is what keeps this a fix rather than a
      # redesign: nothing about the ordinary card moved.
      drawn =
        MedicationScreen.dose_row(%{
          time: "08:00",
          name: "Levothyroxine",
          line: "50 mcg · before food",
          state: :missed,
          tap: :dose_x
        })

      assert "50 mcg · before food · MISSED" in texts(drawn)
    end

    test "screen 115's card mirrors both halves of that" do
      blank = HealthFa.dose_card(%{name: "آهن", line: "", state: :due})
      missed = HealthFa.dose_card(%{name: "آهن", line: "", state: :missed})

      refute "" in texts(blank)
      refute "" in texts(missed)

      suffix = HealthFa.line(%{line: "", state: :missed})

      assert suffix in texts(missed)
      refute (" · " <> suffix) in texts(missed)
    end

    test "the page a name-only medication opens has no blank line and no phantom middot" do
      name_only!(["08:00"])

      strings = texts(mount_screen(MedicationScreen))

      assert "Iron" in strings
      refute Enum.any?(strings, &String.starts_with?(&1, " · "))
    end

    test "its Schedules row is a title alone rather than a title over an empty line" do
      # The same absence one band down, and newly reachable for the same
      # reason: `Kati.Health.Medication.schedule_line/1` answers `""` for a
      # medication with neither a dose nor a sentence, and
      # `Kati.UI.SettingsList.body/3` draws a subtitle for any string.
      name_only!(["08:00"])

      assert [%{line: ""} = row] = MedicationScreen.schedules()
      assert MedicationScreen.said(row.line) == nil

      strings = texts(MedicationScreen.schedule_group(MedicationScreen.schedules()))

      assert "Iron" in strings
      refute "" in strings
    end
  end

  describe "a failure that could not have happened" do
    test "a dose derived for a time before the medication existed is not missed" do
      # The reported flow: board 188 opened at 15:00 and saved on the draft it
      # opens with, whose only time is 08:00. `00:00` and `23:59` are here so
      # the row is on both sides of any clock the suite runs at.
      a_medication!(%{times: ["00:00", "08:00", "23:59"]})

      view = mount_screen(MedicationScreen)

      refute Enum.any?(assigns(view).doses, &(&1.state == :missed)),
             "the app asserted a failure against a prescription it learned about afterwards"

      refute "MISSED" in texts(view)
    end

    test "a dose stored for that time still reads missed, because the row existed" do
      # The converse, and it is the half that keeps `:missed` worth anything: a
      # ROW at 00:00 is a dose the app knew about and nobody answered.
      medication = a_medication!(%{times: ["00:00"]})

      Ash.create!(Dose, %{
        medication_id: medication.id,
        due_on: Kati.Time.today(),
        due_at: "00:00"
      })

      assert [%{state: :missed}] = MedicationScreen.doses()
    end
  end

  describe "a tick lands exactly once, however it was tapped" do
    test "all three of a derived dose's tags against one socket write one row" do
      # `Kati.ScreenWriteTargetTest.walk_drawn/3` presses every drawn tag
      # against the mount-time socket, so this is not a hypothetical caller.
      medication = a_medication!(%{times: ["08:00"]})

      view = mount_screen(MedicationScreen)
      [row] = assigns(view).doses

      for tag <- [row.tap, row.taken, row.skip], do: render_info(view, {:tap, tag})

      assert length(Ash.read!(Dose)) == 1,
             "one dose became more than one row in health_doses"

      assert [%Dose{} = written] = Ash.read!(Dose)
      assert written.medication_id == medication.id
      assert written.due_at == "08:00"

      # The last decision wins, which is what a second tap on one dose means —
      # the same thing it has always meant on a stored row.
      assert written.state == :skipped
    end

    test "a decision recorded elsewhere is moved rather than duplicated" do
      medication = a_medication!(%{times: ["08:00"]})

      Ash.create!(Dose, %{
        medication_id: medication.id,
        due_on: Kati.Time.today(),
        due_at: "08:00",
        state: :taken
      })

      assert {:ok, %Dose{state: :skipped}} =
               MedicationScreen.save_dose(
                 %{
                   id: nil,
                   medication_id: medication.id,
                   due_on: Kati.Time.today(),
                   due_at: "08:00"
                 },
                 :skipped
               )

      assert length(Ash.read!(Dose)) == 1
    end
  end

  describe "the reminder is the one this page arms" do
    test "it is composed by the code that composes the real notification" do
      medication = a_medication!(%{name: "Metformin", times: ["08:00"]})

      view = mount_screen(MedicationScreen)
      card = assigns(view).reminder

      assert card.title == Health.title([medication])
      assert card.body == Health.body([medication])
      assert card.app == "KATI · 08:00"

      strings = texts(view)

      assert card.title in strings

      refute WeightSample.reminder().title in strings,
             "a reader taking one 08:00 tablet was shown a 21:00 Magnesium reminder"

      refute WeightSample.reminder().app in strings
    end

    test "the time on it is one of the reader's own, never one they never typed" do
      medication = a_medication!(%{times: ["06:45", "22:10"]})

      card = assigns(mount_screen(MedicationScreen)).reminder

      assert card.app in Enum.map(medication.times, &("KATI · " <> &1))
    end

    test "nothing armed takes the band's eyebrow with it" do
      # A schedule can be a sentence with no clock in it —
      # `Kati.Notifications.Sources.Health` answers `:no_times` for one — and a
      # suppressed candidate is not a card.
      a_medication!(%{times: []})

      view = mount_screen(MedicationScreen)

      assert assigns(view).reminder == nil
      assert MedicationScreen.reminder_band(nil) == []
      refute "THE REMINDER" in texts(view)
    end

    test "every medication paused is the same answer" do
      a_medication!(%{times: ["08:00"]}) |> Ash.update!(%{active: false})

      view = mount_screen(MedicationScreen)

      assert assigns(view).reminder == nil
      refute WeightSample.reminder().title in texts(view)
    end

    test "with nothing stored the drawing's card is drawn whole" do
      # Board 112's own frame, which is what the empty page still is — and what
      # `Kati.ScreenDesignLiteralTest` compares against.
      view = mount_screen(MedicationScreen)
      strings = texts(view)

      assert assigns(view).reminder == WeightSample.reminder()
      assert "THE REMINDER" in strings
      assert WeightSample.reminder().app in strings
      assert WeightSample.reminder().title in strings
      assert WeightSample.reminder().body in strings
    end
  end

  describe "the two identity-less verbs act on the page they were drawn on" do
    test "a dose decided elsewhere between draw and tap does not move them" do
      # Iron sorts first at 08:00, so the socket's first undecided row is
      # Iron's. A `next_undecided/1` that re-read the store would find Iron
      # already taken and land on Levothyroxine — a dose nobody has answered
      # for, on a page that is still drawing Iron as due.
      iron = a_medication!(%{name: "Iron", times: ["08:00"]})
      levo = a_medication!(%{name: "Levothyroxine", times: ["21:00"]})

      view = mount_screen(MedicationScreen)

      assert [%{name: "Iron"}, %{name: "Levothyroxine"}] = assigns(view).doses

      Ash.create!(Dose, %{
        medication_id: iron.id,
        due_on: Kati.Time.today(),
        due_at: "08:00",
        state: :taken
      })

      render_info(view, {:tap, :mark_taken})

      assert [%Dose{} = written] = Ash.read!(Dose)

      assert written.medication_id == iron.id,
             "the chip wrote a dose the page had not drawn it on — see the comment above"

      refute written.medication_id == levo.id
    end

    test "a quiet page refuses in words rather than picking a row out of the store" do
      # `undecided([])` is `nil`, so `save_dose/2` is handed nothing to write —
      # and the refusal reaches a `:text` node, which is this page's *a dose
      # that did not record says so*.
      a_medication!(%{times: []})

      tapped = render_info(mount_screen(MedicationScreen), {:tap, :mark_taken})

      assert assigns(tapped).save_error == "Nothing to save yet."
      assert find(tree(tapped), :text, text: "Nothing to save yet.")
      assert Ash.read!(Dose) == []
    end
  end

  describe "one question, asked once" do
    test "the three bands are handed one answer rather than each asking" do
      # What the moduledoc claims and what `load/1` now does. Read through the
      # socket rather than by counting queries: the three assigns are what the
      # render sees, and they are built from one tuple.
      a_medication!(%{times: ["08:00"]})

      view = mount_screen(MedicationScreen)
      %{doses: doses, schedules: schedules, reminder: reminder} = assigns(view)

      refute doses == MedicationScreen.drawn_doses()
      refute schedules == WeightSample.schedules()
      refute reminder == WeightSample.reminder()

      assert Enum.map(doses, & &1.name) == ["Metformin"]
      assert Enum.map(schedules, & &1.name) == ["Metformin"]
    end
  end
end
