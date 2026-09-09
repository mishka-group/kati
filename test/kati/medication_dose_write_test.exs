defmodule Kati.MedicationDoseWriteTest do
  @moduledoc """
  Screen 112 records the dose you touched, and nothing else.

  ## The defect these are written against

  `Kati.Screens.Medication.save_dose/1` re-read the whole day at tap time and
  updated `Enum.find(doses, &(&1.state == :due))` — the head of a query that
  had nothing to do with the control pressed. Every card on the page shared the
  tag `:toggle_dose` and both verbs under the list shared `:mark_taken` and
  `:mark_skipped`, so the tap carried no clue which dose it was about and the
  screen guessed.

  On a day with one dose that is indistinguishable from correct, which is
  exactly why it survived: `Kati.HealthTest`'s screen-112 setup stores one dose,
  taps, and finds it changed. So every assertion here uses **two** doses and
  acts on the **second**. An implementation that re-queries, one that takes the
  first row, and one that falls back to the drawing all pass a one-dose test
  and fail these.

  ## Why a dose deleted underneath the page is the sharpest of them

  A re-query cannot tell "the dose I was handed is gone" from "the head has
  moved on", so it writes the neighbour and reports success. Holding the id
  makes the two different answers: `save_dose/2` asks the store about that id
  and gets nothing, the notice goes up, and the dose still on the page is
  untouched. That test fails on every version of this screen that reads for its
  own subject.

  ## The second defect, D-59: a dose with no row yet

  Nothing in `lib/` ever created a `Kati.Health.Dose`, so every test above
  stores its own rows first and every one of them was, until D-59, a test of a
  state no real device could reach. Screen 112 composes today's list from each
  active medication's `times` now — `Kati.Health.Dose.derive/2` — and writes a
  row the first time somebody marks one, so the ordinary state of a person who
  has just used board 188 is a page of doses with `id: nil` and a
  `:medication_id`.

  `a_medication!/2` and `two_schedules!/0` set that state up, and the tests
  under *a dose derived from a schedule* are the ones that would have caught
  the report: four fixture tablets over one real schedule. They act on the
  **third** row and on two medications sharing 08:00, for the same reason the
  tests above act on the second — a derivation that keyed a row by clock time
  alone, or one that wrote whatever the day's first undecided dose was, passes
  a one-medication test and fails these.

  ## Dates and clocks

  Fixtures are dated off `Kati.Time.today/0` — never `DateTime.utc_now/0`,
  which is the screen rule and just as much a test rule: a dose dated in UTC
  falls out of `:for_day` for the first hours of every Amsterdam day. Nothing
  here asserts `:due` against `:missed` either, because
  `Kati.Health.Dose.resolve/2` derives that from the clock and a suite that
  pinned it would pass in the morning and fail after 08:00. Undecided is what
  the page cares about, and both readings are undecided.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Screens.Medication, as: MedicationScreen

  setup do
    # BOTH sides, and doses before medications because SQLite holds the foreign
    # key. The `with nothing stored` tests below assert the page falls back, so
    # they are exactly the tests a neighbour's leaked row turns into a mystery —
    # and a suite that only cleans on the way out is one leak away from being
    # order-dependent.
    wipe = fn ->
      Kati.Repo.query!("DELETE FROM health_doses", [])
      Kati.Repo.query!("DELETE FROM health_medications", [])
    end

    wipe.()
    on_exit(wipe)

    :ok
  end

  # Two doses of one medication, in the order the page draws them: `:for_day`
  # sorts by `due_at` ascending, so 08:00 is the first row and 21:00 the second.
  defp two_doses! do
    medication =
      Ash.create!(Medication, %{
        name: "Levothyroxine",
        dose: "50 mcg",
        schedule: "every morning, 08:00",
        times: ["08:00", "21:00"],
        instruction: "before food"
      })

    {a_dose!(medication, "08:00"), a_dose!(medication, "21:00")}
  end

  defp a_dose!(medication, at) do
    Ash.create!(Dose, %{
      medication_id: medication.id,
      due_on: Kati.Time.today(),
      due_at: at
    })
  end

  # A medication and NO dose rows — the ordinary state of somebody who has just
  # added a prescription on board 188, and the state in which screen 112 used
  # to draw four tablets belonging to nobody. D-59.
  defp a_medication!(name, times) do
    Ash.create!(Medication, %{name: name, dose: "50 mcg", schedule: "daily", times: times})
  end

  # Two of them, sharing 08:00 on purpose: a key built from the clock time
  # alone would collapse those two cards onto one `accessibility_id`. The
  # derived list is in `{due_at, name}` order, so Iron comes before
  # Levothyroxine at 08:00.
  defp two_schedules! do
    {a_medication!("Levothyroxine", ["08:00", "21:00"]), a_medication!("Iron", ["08:00"])}
  end

  defp rows(view), do: view |> assigns() |> Map.fetch!(:doses)

  defp drawn_tags(view) do
    for node <- flatten(view),
        {pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_pid(pid),
        do: tag
  end

  describe "the dose you touched" do
    test "tapping the second card records the second dose and leaves the first alone" do
      {first, second} = two_doses!()

      view = mount_screen(MedicationScreen)
      [_first_row, second_row] = rows(view)

      render_info(view, {:tap, second_row.tap})

      assert Ash.get!(Dose, second.id).state == :taken,
             "the card that was tapped did not change"

      assert Ash.get!(Dose, first.id).state == :due,
             "the first dose changed instead, which is the re-query this screen was opened for"
    end

    test "the row is in the store on a fresh read, with the moment it was recorded" do
      {_first, second} = two_doses!()

      view = mount_screen(MedicationScreen)
      [_first_row, second_row] = rows(view)

      render_info(view, {:tap, second_row.tap})

      # A fresh query rather than the record handed back by the write: the
      # claim is that it LANDED, and a struct in memory cannot say that.
      stored =
        Dose
        |> Ash.Query.for_read(:for_day, %{day: Kati.Time.today()})
        |> Ash.read!()

      assert [%Dose{state: :due}, %Dose{id: id, state: :taken, recorded_at: %DateTime{}}] = stored
      assert id == second.id
    end

    test "Skip records the dose the two verbs were drawn for, and then the next one" do
      {first, second} = two_doses!()

      view = mount_screen(MedicationScreen)
      verbs = MedicationScreen.undecided(rows(view))

      assert verbs.id == first.id,
             "the verbs name the first undecided dose, which is what the board draws them on"

      render_info(view, {:tap, verbs.skip})

      assert Ash.get!(Dose, first.id).state == :skipped
      assert Ash.get!(Dose, second.id).state == :due

      # And now that the first is answered, the verbs are about the second —
      # which is the only thing left to decide.
      next = mount_screen(MedicationScreen)
      moved = MedicationScreen.undecided(rows(next))

      assert moved.id == second.id

      render_info(next, {:tap, moved.taken})

      assert Ash.get!(Dose, second.id).state == :taken
      assert Ash.get!(Dose, first.id).state == :skipped
    end

    test "a dose deleted underneath the page takes its write with it" do
      {first, second} = two_doses!()

      view = mount_screen(MedicationScreen)
      verbs = MedicationScreen.undecided(rows(view))

      # The screen is still holding a dose that is no longer there. A handler
      # that re-queried would find the 21:00 dose and mark THAT taken, and say
      # nothing about it.
      Ash.destroy!(first)

      tapped = render_info(view, {:tap, verbs.taken})

      assert Ash.get!(Dose, second.id).state == :due,
             "a write for a dose that is gone landed on the dose that is left"

      assert is_binary(assigns(tapped).save_error),
             "a dose that did not record has to say so — see Kati.Write"

      # And says it on the PAGE. An assign nothing reads is the defect #85
      # found once already: `content/1` has to hand `:save_error` to `today/2`
      # for `save_notice/1` to draw it, and an assertion that stops at the
      # socket passes just as happily when that argument is dropped.
      notice = find(tree(tapped), :text, text: assigns(tapped).save_error)

      assert notice, "the :save_error assign never reached a :text node"
      assert notice.props.text == assigns(tapped).save_error
    end

    test "each dose carries its own three tags, and no tag names two doses" do
      {first, second} = two_doses!()

      [first_row, second_row] = rows(mount_screen(MedicationScreen))

      assert first_row.tap == MedicationScreen.tags(first.id).tap
      assert second_row.tap == MedicationScreen.tags(second.id).tap

      tags = [
        first_row.tap,
        first_row.taken,
        first_row.skip,
        second_row.tap,
        second_row.taken,
        second_row.skip
      ]

      # Atoms, not tuples: only `is_atom(tag)` reaches Compose as a testTag and
      # emits an `accessibility_id`, so a tuple here is a control no device test
      # and no screen reader can address.
      assert Enum.all?(tags, &is_atom/1)
      assert Enum.uniq(tags) == tags
    end

    test "the second dose's tag is on the screen, and the rows are named apart" do
      {_first, second} = two_doses!()

      view = mount_screen(MedicationScreen)
      [_first_row, second_row] = rows(view)
      tags = drawn_tags(view)

      assert second_row.tap in tags,
             "the second dose's card is not tappable, so nothing could tap it"

      assert MedicationScreen.tags(second.id).tap in tags

      # And the tag drawn for it is its own rather than a shared name: four
      # cards called `:toggle_dose` is four nodes `onNodeWithTag` throws on.
      assert Enum.uniq(tags) == tags
    end

    test "a day with nothing left to decide draws no verbs at all" do
      {first, second} = two_doses!()
      for dose <- [first, second], do: Ash.update!(dose, %{state: :taken})

      view = mount_screen(MedicationScreen)

      assert MedicationScreen.undecided(rows(view)) == nil
      assert MedicationScreen.actions(nil) == []
    end
  end

  describe "the write contract" do
    test "a stored dose comes back as {:ok, row} and a drawn one as an error" do
      {first, _second} = two_doses!()

      assert {:ok, %Dose{state: :skipped}} = MedicationScreen.save_dose(%{id: first.id}, :skipped)
      assert {:error, :nothing_to_save} = MedicationScreen.save_dose(%{id: nil}, :taken)
    end

    test "a nil id with no medication behind it is still nothing to write against" do
      # D-59 made `id: nil` mean two things — *derived, not materialised yet*
      # when a `:medication_id` rides with it and *this is the drawing* when
      # nothing does. This is the second, and the row shape is the drawing's:
      # `Kati.Health.WeightSample.doses/0` has no `:medication_id` key at all.
      assert {:error, :nothing_to_save} =
               MedicationScreen.save_dose(
                 %{id: nil, due_at: "08:00", due_on: Kati.Time.today()},
                 :taken
               )

      assert Ash.read!(Dose) == []
    end
  end

  describe "a dose derived from a schedule" do
    test "the page draws the reader's own doses, at their own clock times" do
      {levo, iron} = two_schedules!()

      rows = rows(mount_screen(MedicationScreen))

      assert Enum.map(rows, &{&1.time, &1.name}) == [
               {"08:00", "Iron"},
               {"08:00", "Levothyroxine"},
               {"21:00", "Levothyroxine"}
             ]

      # No row yet, and each one carries what a write needs to make one.
      assert Enum.all?(rows, &(&1.id == nil))
      assert Enum.map(rows, & &1.medication_id) == [iron.id, levo.id, levo.id]
      assert Enum.all?(rows, &(&1.due_on == Kati.Time.today()))
      assert Ash.read!(Dose) == []
    end

    test "each derived row has its own three tags, and no tag names two rows" do
      # Two medications share 08:00 here deliberately: a key built from the
      # clock time alone collapses them onto one `accessibility_id`, which
      # `onNodeWithTag` throws on and a screen reader announces twice.
      two_schedules!()

      rows = rows(mount_screen(MedicationScreen))
      tags = Enum.flat_map(rows, &[&1.tap, &1.taken, &1.skip])

      assert Enum.all?(tags, &is_atom/1)
      assert Enum.uniq(tags) == tags

      # And the namespaces are held apart: neither a stored dose's `dose_<uuid>`
      # nor the drawing's `dose_drawn_N`.
      for tag <- tags, do: refute(String.starts_with?(Atom.to_string(tag), "dose_drawn_"))
    end

    test "tapping one writes a dose carrying that row's medication, day, time and state" do
      {levo, _iron} = two_schedules!()

      view = mount_screen(MedicationScreen)
      [_first, _second, third] = rows(view)

      render_info(view, {:tap, third.skip})

      assert [%Dose{} = written] = Ash.read!(Dose)

      # The row the page DREW, not the clock at tap time: a page drawn at 23:59
      # and tapped at 00:01 has to record the dose it was drawing.
      assert written.medication_id == levo.id
      assert written.due_on == Kati.Time.today()
      assert written.due_at == "21:00"

      # Decided, never the `:due` default — the row exists only because
      # somebody decided about it — and stamped with when.
      assert written.state == :skipped
      assert %DateTime{} = written.recorded_at
    end

    test "the tick survives a fresh mount, and a second tap makes no second row" do
      two_schedules!()

      view = mount_screen(MedicationScreen)
      [first | _rest] = rows(view)

      render_info(view, {:tap, first.tap})

      # A fresh mount rather than the socket: the claim is that it LANDED and
      # that the merge lets the stored row win its derived twin, and a struct
      # in memory cannot say either.
      reopened = rows(mount_screen(MedicationScreen))

      assert length(reopened) == 3, "the derived twin redrew over the row that was written"
      assert [%{state: :taken, name: "Iron"} = stored | _rest] = reopened
      assert is_binary(stored.id), "the written row did not come back with its id"

      render_info(mount_screen(MedicationScreen), {:tap, stored.tap})

      assert length(Ash.read!(Dose)) == 1,
             "a second decision about one dose made a second row rather than moving the first"
    end

    test "the two verbs reach the first undecided derived dose" do
      {_levo, iron} = two_schedules!()

      view = mount_screen(MedicationScreen)
      verbs = MedicationScreen.undecided(rows(view))

      render_info(view, {:tap, verbs.taken})

      assert [%Dose{medication_id: id, due_at: "08:00", state: :taken}] = Ash.read!(Dose)
      assert id == iron.id, "the verbs wrote a dose the page had not drawn them on"
    end
  end

  describe "screen 115 on a day with nothing stored yet" do
    test "it mounts at all, which it did not once a dose could be derived" do
      # `Kati.Screens.HealthFa.doses/0` rebuilt each row's tags with
      # `Medication.tags(dose.id)`, and `tags/1` guards on `is_binary(key)` —
      # so the first derived row on a Persian device was a FunctionClauseError
      # inside `mount/3`, and screen 115 did not open for anybody with a
      # medication.
      a_medication!("Levothyroxine", ["08:00"])

      view = mount_screen(Kati.Screens.HealthFa)

      assert [row] = assigns(view).doses
      assert row.name == "Levothyroxine"

      # The tags are 112's own, carried rather than rebuilt.
      assert is_atom(row.tap) and is_atom(row.taken) and is_atom(row.skip)
    end

    test "its chips mark the dose they were drawn for, in ASCII" do
      medication = a_medication!("Levothyroxine", ["08:00"])

      view = mount_screen(Kati.Screens.HealthFa)
      [row] = assigns(view).doses

      render_info(view, {:tap, row.taken})

      assert [%Dose{} = written] = Ash.read!(Dose)
      assert written.medication_id == medication.id
      assert written.state == :taken

      # The clock time the page DREW is Persian — ۰۸:۰۰ — and the one the store
      # holds is not: `Kati.Health.Dose.resolve/2` and `:for_day`'s sort cannot
      # read Persian digits.
      assert written.due_at == "08:00"
      refute row.time == written.due_at
    end

    test "the two bare Persian verbs still write on a derived day" do
      # `next_undecided/0` read `health_doses` at tap time until D-59, so on a
      # day whose doses are composed it answered nothing and both chips
      # reported `Nothing to save yet.` to every real user.
      medication = a_medication!("Levothyroxine", ["08:00"])

      render_info(mount_screen(Kati.Screens.HealthFa), {:tap, :mark_skipped})

      assert [%Dose{medication_id: id, state: :skipped}] = Ash.read!(Dose)
      assert id == medication.id
    end
  end

  describe "screen 115's identity-less verbs" do
    test "still write, against the day's first undecided dose" do
      {first, second} = two_doses!()

      render_info(mount_screen(MedicationScreen), {:tap, :mark_taken})

      assert Ash.get!(Dose, first.id).state == :taken
      assert Ash.get!(Dose, second.id).state == :due
    end

    test "the Persian page's own chips reach the same write" do
      # 115 hands its OWN socket to `handle_tap/2` here, and its doses carry
      # neither ids nor tags — so this is the case that proves the tag lookup
      # falls through rather than crashing on a map without a `:tap` key.
      {first, second} = two_doses!()

      render_info(mount_screen(Kati.Screens.HealthFa), {:tap, :mark_skipped})

      assert Ash.get!(Dose, first.id).state == :skipped
      assert Ash.get!(Dose, second.id).state == :due
    end
  end

  describe "with nothing stored" do
    test "the page is the drawing, and the drawing's cards are tagged apart" do
      view = mount_screen(MedicationScreen)
      doses = rows(view)

      assert MedicationScreen.doses() == MedicationScreen.drawn_doses()
      assert length(doses) == 4

      tags = Enum.map(doses, & &1.tap)

      assert Enum.all?(tags, &is_atom/1)
      assert Enum.uniq(tags) == tags

      # The two namespaces are held apart on purpose: a device test waiting for
      # `dose_drawn_2` is waiting for the empty state, and one waiting for
      # `dose_<uuid>` is waiting for a dose.
      for tag <- tags, do: assert(String.starts_with?(Atom.to_string(tag), "dose_drawn_"))
    end

    test "a drawn card writes nothing, and says so rather than moving its tick" do
      view = mount_screen(MedicationScreen)
      [_first, _second, third | _rest] = rows(view)

      # Absent before the tap, so the node below is there BECAUSE of it.
      refute find(tree(view), :text, text: "Nothing to save yet.")

      tapped = render_info(view, {:tap, third.tap})

      assert assigns(tapped).save_error == "Nothing to save yet."

      assert find(tree(tapped), :text, text: "Nothing to save yet."),
             "the refusal is only in the assigns — see the note on the destroyed-dose test"

      # A sample is not a row: nothing was created to carry the decision, and
      # the list did not pretend otherwise.
      assert Ash.read!(Dose) == []
      assert assigns(tapped).doses == MedicationScreen.drawn_doses()
    end
  end
end
