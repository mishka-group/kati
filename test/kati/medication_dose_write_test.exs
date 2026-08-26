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
