defmodule Kati.HealthTest do
  @moduledoc """
  Weight and medication — screens 109, 111 and 112.

  ## The two decisions this file pins

    * **Grams, always.** Screen 111's unit switch is a *correction* rather than
      a preference, and that is only coherent because the stored value never
      moves: you say which number you just read, and every other reading in the
      log is untouched.
    * **`:missed` is derived.** A dose due at 14:00 is due at 13:59 and missed
      at 14:01, and nothing has to run at midnight for that to be true.
    * **The whole day is derived.** D-59. Today's doses are composed from each
      active medication's `times` — the field `Kati.Notifications.Sources.Health`
      already arms the reminder from — and a `health_doses` row is written the
      first time somebody marks one. So a row means *somebody decided about
      this*, and its absence means nothing more than *not yet*.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Health
  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Health.Reading
  alias Kati.Screens.LogWeight
  alias Kati.Screens.Medication, as: MedicationScreen
  alias Kati.Screens.Weight

  # `clock?/1` is what bounds the atom family screen 112 builds for a derived
  # dose, so its three answers are worth running rather than only reading.
  doctest Kati.Health.Dose, only: [clock?: 1]

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM health_doses", [])
      Kati.Repo.query!("DELETE FROM health_medications", [])
      Kati.Repo.query!("DELETE FROM health_readings", [])
    end)

    :ok
  end

  defp a_reading!(grams, on) do
    Ash.create!(Reading, %{grams: grams, taken_on: on})
  end

  describe "a weight in three units" do
    test "the same grams print as the same weight said differently" do
      assert Reading.display(76_000, :kg) == "76.0 kg"
      assert Reading.display(76_000, :lb) == "167.6 lb"
      assert Reading.display(76_000, :st) == "11st 13.6"
    end

    test "the figure and the unit are separable, because the hero sets them apart" do
      assert Reading.figure(76_000, :kg) == "76.0"
      assert Reading.unit_label(:kg) == "kg"
    end

    test "one decimal place, never two" do
      # A scale that reads to 100g does not justify printing 76.04.
      assert Reading.display(76_042, :kg) == "76.0 kg"
    end
  end

  describe "deltas" do
    test "a first reading has no delta, rather than a delta of zero" do
      # A first weighing did not hold steady — it has nothing before it.
      assert Reading.delta(%Reading{grams: 76_000}, nil) == nil
      assert Reading.delta_label(nil, :kg) == nil
    end

    test "the sign is a true minus, so the column aligns" do
      assert Reading.delta_label(-400, :kg) == "−0.4"
      assert Reading.delta_label(100, :kg) == "+0.1"
    end
  end

  describe "screen 109" do
    test "the list reads the stored series and carries each change" do
      a_reading!(76_500, ~D[2026-08-06])
      a_reading!(76_400, ~D[2026-08-13])
      a_reading!(76_000, ~D[2026-08-16])

      entries = Weight.entries()

      assert Enum.map(entries, & &1.weight) == ["76.0 kg", "76.4 kg", "76.5 kg"]
      assert Enum.map(entries, & &1.delta) == ["−0.4", "−0.1", nil]
    end

    test "the hero measures the whole arc, not the last step" do
      a_reading!(78_400, ~D[2026-05-04])
      a_reading!(76_000, ~D[2026-08-16])

      latest = Weight.latest()

      assert latest.figure == "76.0"
      assert latest.direction == :down
      assert latest.change == "2.4 kg"
      assert latest.since =~ "DOWN FROM 78.4 ON 4 MAY"
    end

    test "the bars are normalised against the series, not against zero" do
      # Every reading in a weight series is a large number close to every
      # other, so a zero-based axis draws identical bars and says nothing.
      a_reading!(76_000, ~D[2026-08-16])
      a_reading!(78_000, ~D[2026-08-06])

      bars = Weight.bars()

      assert length(bars) == 2
      assert Enum.min(bars) < Enum.max(bars)
      assert Enum.all?(bars, &(&1 > 0.0 and &1 <= 1.0))
    end

    test "with nothing stored the drawing renders, whole" do
      assert Weight.entries() == Weight.drawn_entries()
    end

    test "the page says nothing here leaves the device" do
      tree = tree(mount_screen(Weight))

      assert find(tree, :text,
               text:
                 "Kati stores the readings you type and nothing else — no scale is " <>
                   "connected, and nothing here leaves the device."
             ) != nil
    end
  end

  describe "screen 111" do
    test "the sheet opens on your last reading" do
      a_reading!(74_200, Kati.Time.today())

      assert assigns(mount_screen(LogWeight)).grams == 74_200
    end

    test "the step follows the display unit, not the stored one" do
      # 0.1 kg is 100g and 0.1 lb is 45g. A stepper that moved 100g while the
      # label said pounds would jump by 0.22 a press.
      assert LogWeight.step(:kg) == 100
      assert LogWeight.step(:lb) == 45
    end

    test "changing the unit converts nothing" do
      a_reading!(76_000, Kati.Time.today())

      view = mount_screen(LogWeight)
      switched = render_info(view, {:tap, :unit_lb})

      assert assigns(switched).unit == :lb
      assert Health.unit() == :lb
      # The same weight, said differently — the grams did not move.
      assert assigns(switched).grams == 76_000
    end

    test "saving writes grams, dated today" do
      view = mount_screen(LogWeight)
      stepped = view |> render_info({:tap, :step_up}) |> render_info({:tap, :step_up})

      render_info(stepped, {:tap, :save})

      assert [reading] = Ash.read!(Reading)
      assert reading.grams == assigns(stepped).grams
      assert reading.taken_on == Kati.Time.today()
    end

    test "the confirmation compares with the last DIFFERENT day" do
      # The sheet opens on your last weight so you can nudge it, so comparing
      # with the newest would compare a value with itself.
      a_reading!(76_400, Date.add(Kati.Time.today(), -3))
      a_reading!(76_000, Kati.Time.today())

      {icon, lead, tail} = LogWeight.change(76_000)

      assert icon == "arrow_downward"
      assert lead == "0.4 kg down"
      assert tail =~ "three days ago"
    end

    test "a first reading says so rather than inventing a delta" do
      a_reading!(76_000, Kati.Time.today())

      {icon, lead, _tail} = LogWeight.change(76_000)

      assert icon == "lightbulb"
      assert lead == "Your first reading"
    end

    test "small counts are words and larger ones are numerals" do
      # `three days ago` reads as prose; `seventeen days ago` does not.
      assert LogWeight.ago(%{date: shifted(-3)}) == "three days ago"
      assert LogWeight.ago(%{date: shifted(-1)}) == "yesterday"
      assert LogWeight.ago(%{date: shifted(-17)}) == "17 days ago"
    end

    test "closing writes nothing" do
      before = length(Ash.read!(Reading))

      closed =
        mount_screen(LogWeight) |> render_info({:tap, :step_up}) |> render_info({:tap, :close})

      assert navigated_to(closed) == {:pop}
      assert length(Ash.read!(Reading)) == before
    end
  end

  describe "doses" do
    test "missed is derived from the clock, not stored" do
      due = %Dose{due_on: ~D[2026-08-16], due_at: "14:00", state: :due}
      zone = Kati.Time.device_zone()

      before = DateTime.new!(~D[2026-08-16], ~T[13:59:00], zone)
      after_ = DateTime.new!(~D[2026-08-16], ~T[14:01:00], zone)

      assert Dose.resolve(due, before) == :due
      assert Dose.resolve(due, after_) == :missed
    end

    test "a decided dose stays decided whatever the clock says" do
      taken = %Dose{due_on: ~D[2026-08-16], due_at: "08:00", state: :taken}
      zone = Kati.Time.device_zone()

      assert Dose.resolve(taken, DateTime.new!(~D[2026-08-20], ~T[09:00:00], zone)) == :taken
    end

    test "the suffix names only the states worth naming" do
      assert Dose.state_suffix(:missed) == "MISSED"
      assert Dose.state_suffix(:skipped) == "SKIPPED"
      # A taken dose already has a tick; a due one has not happened.
      assert Dose.state_suffix(:taken) == nil
      assert Dose.state_suffix(:due) == nil
    end
  end

  describe "a day composed from the schedules — D-59" do
    test "one row per medication AND clock time, in clock order" do
      # Per medication would leave the 21:00 tablet unreachable all day, on a
      # page whose two verbs only ever answer about a row that is drawn.
      rows = Dose.derive([iron(), vitamin_d()], ~D[2026-09-05])

      assert Enum.map(rows, &{&1.due_at, &1.medication_id}) == [
               {"08:00", "med-iron"},
               {"08:00", "med-d"},
               {"21:00", "med-iron"}
             ]

      # Unsaved, dated for the day asked about, and undecided — a plan, not a
      # record.
      assert Enum.all?(rows, &(&1.id == nil and &1.state == :due))
      assert Enum.all?(rows, &(&1.due_on == ~D[2026-09-05]))

      # And the medication rides with the row, so one shaper on screen 112 can
      # read a derived row and a loaded one without telling them apart.
      assert Enum.map(rows, & &1.medication.name) == ["Iron", "Vitamin D", "Iron"]
    end

    test "a clock time that does not parse contributes no row, and a repeat contributes one" do
      # `Kati.Notifications.Sources.Health.wall/2`'s decision, quoted: a row
      # whose time does not parse is dropped rather than guessed at. It is also
      # what keeps `Kati.Screens.Medication.tags/1`'s atom family bounded, and
      # what stops two identical cards sharing one `accessibility_id`.
      messy = %Medication{
        id: "med-messy",
        name: "Iron",
        times: ["08:00", "08:00", "morning", "25:00", ""]
      }

      assert [%Dose{due_at: "08:00"}] = Dose.derive([messy], Kati.Time.today())
      assert Dose.clock?("08:00")
      refute Dose.clock?("morning")
    end

    test "a medication with no times contributes nothing at all" do
      # Which is the quiet day screen 112 words rather than falls back on, and
      # the ordinary result of board 188 saving a prescription with no clock on
      # it.
      assert Dose.derive([%Medication{id: "m", name: "Metformin", times: []}], Kati.Time.today()) ==
               []
    end

    test "the stored dose wins its derived twin" do
      day = Kati.Time.today()

      stored = %Dose{
        id: "row-1",
        medication_id: "med-iron",
        medication: iron(),
        due_on: day,
        due_at: "08:00",
        state: :taken
      }

      merged = Dose.merge([stored], Dose.derive([iron()], day))

      # Two rows, not three, and the 08:00 one is still taken: a derived twin
      # replacing a stored one un-ticks a tick on the next reload, which is the
      # one failure a medication page cannot have.
      assert [%Dose{id: "row-1", state: :taken}, %Dose{id: nil, due_at: "21:00"}] = merged
    end

    test "a stored dose at a time the medication no longer lists survives the merge" do
      # Edit `times` on screen 189 after marking a dose and the record of what
      # you actually took is still the record: the derived side is the plan and
      # the stored side is what happened.
      day = Kati.Time.today()
      moved = %Medication{id: "med-iron", name: "Iron", times: ["21:00"]}

      stored = %Dose{
        id: "row-1",
        medication_id: "med-iron",
        medication: moved,
        due_on: day,
        due_at: "08:00",
        state: :taken
      }

      assert [%Dose{due_at: "08:00", state: :taken}, %Dose{due_at: "21:00", id: nil}] =
               Dose.merge([stored], Dose.derive([moved], day))
    end

    test "a derived dose is not missed for a clock time before its medication existed" do
      # The reported flow, with the clock written down: board 188 opened at
      # 15:00 and Save pressed on the draft it opens with — Levothyroxine,
      # `times: ["08:00"]`. Nothing in the app knew anything about that 08:00.
      # The row did not exist, `Kati.Notifications.Sources.Health` arms wall
      # clock candidates FORWARD so no reminder was ever sent, and drawing
      # `· MISSED` against it asserts a failure that could not have happened —
      # on the page whose own moduledoc says *did I take it* is the question a
      # wrong answer costs the most.
      day = ~D[2026-09-05]
      zone = Kati.Time.device_zone()

      [dose] = Dose.derive([typed(day, ~T[15:00:00])], day)

      assert Dose.resolve(dose, DateTime.new!(day, ~T[15:30:00], zone)) == :due
    end

    test "and it IS missed once a time the medication was already there for passes" do
      # The other direction, and it is what keeps `:missed` worth anything: the
      # same tablet, typed in yesterday, at the same clock time today.
      day = ~D[2026-09-05]
      zone = Kati.Time.device_zone()

      [dose] = Dose.derive([typed(Date.add(day, -1), ~T[21:00:00])], day)

      assert dose.due_at == "08:00"
      assert Dose.resolve(dose, DateTime.new!(day, ~T[15:30:00], zone)) == :missed
    end

    test "a STORED row at that time keeps the plain clock reading" do
      # `resolve/2`'s original argument is an argument about a row: it existed
      # at 08:00 and nobody answered. That premise holds for anything in
      # `health_doses` whatever its medication's `inserted_at` says — a row is
      # written when somebody decides, and `merge/2` lets it win its derived
      # twin precisely because it is the record rather than the plan.
      day = ~D[2026-09-05]
      zone = Kati.Time.device_zone()
      medication = typed(day, ~T[15:00:00])

      stored = %Dose{
        id: "row-1",
        medication_id: medication.id,
        medication: medication,
        due_on: day,
        due_at: "08:00",
        state: :due
      }

      assert Dose.resolve(stored, DateTime.new!(day, ~T[15:30:00], zone)) == :missed
    end
  end

  describe "screen 112" do
    setup do
      medication =
        Ash.create!(Medication, %{
          name: "Levothyroxine",
          dose: "50 mcg",
          schedule: "every morning, 08:00",
          times: ["08:00"],
          instruction: "before food"
        })

      Ash.create!(Dose, %{
        medication_id: medication.id,
        due_on: Kati.Time.today(),
        due_at: "08:00"
      })

      %{medication: medication}
    end

    test "the page reads today's doses" do
      assert [dose] = MedicationScreen.doses()
      assert dose.name == "Levothyroxine"
      assert dose.line == "50 mcg · before food"
    end

    test "the schedule line joins the dose and the sentence" do
      assert [%{line: "50 mcg · every morning, 08:00"}] = MedicationScreen.schedules()
    end

    test "Taken and Skip both write, and the page re-reads" do
      view = mount_screen(MedicationScreen)

      taken = render_info(view, {:tap, :mark_taken})

      assert [%{state: :taken}] = assigns(taken).doses
      assert [%Dose{state: :taken}] = Ash.read!(Dose)
    end

    test "skipping records the decision rather than deleting the dose" do
      render_info(mount_screen(MedicationScreen), {:tap, :mark_skipped})

      assert [%Dose{state: :skipped, recorded_at: %DateTime{}}] = Ash.read!(Dose)
    end

    test "the subtitle counts the day's real doses" do
      assert MedicationScreen.subtitle(MedicationScreen.doses()) =~ "1 DOSE"
    end

    test "both required claims are on the page, in the flow" do
      tree = tree(mount_screen(MedicationScreen))

      assert find(tree, :text,
               text:
                 "Reminders can arrive late if the phone is restricting alarms to save " <>
                   "battery, so treat them as a nudge and not a guarantee."
             ) != nil

      assert find(tree, :text,
               text:
                 "Kati is not a medical device and gives no medical advice — it only " <>
                   "records what you tell it."
             ) != nil
    end
  end

  describe "screen 112 with nothing stored" do
    test "the drawing renders, whole, and keeps its own date" do
      assert MedicationScreen.doses() == MedicationScreen.drawn_doses()
      # Dating the drawing's doses with the device's today would put a real
      # date on a fixture.
      assert MedicationScreen.subtitle(MedicationScreen.doses()) == "SUNDAY 16 AUGUST · 4 DOSES"
    end
  end

  describe "the three screens render" do
    test "each one draws a tree the native layer can take" do
      for module <- [Weight, LogWeight, MedicationScreen] do
        assert_renderable(mount_screen(module))
      end
    end
  end

  # Structs rather than rows: `Kati.Health.Dose.derive/2` reads nothing and
  # writes nothing, and a test that stored them first could not tell that apart
  # from one that reads.
  # Levothyroxine as board 188 stores it, with the moment it was stored written
  # in. `inserted_at` is UTC in the store — `Ash`'s `timestamps()` — and
  # `DateTime.compare/2` reads instants, so the zone the test thinks in and the
  # zone the column holds cannot disagree.
  defp typed(day, time) do
    at = DateTime.new!(day, time, Kati.Time.device_zone()) |> DateTime.shift_zone!("Etc/UTC")

    %Medication{
      id: "med-levo",
      name: "Levothyroxine",
      times: ["08:00"],
      inserted_at: at
    }
  end

  defp iron, do: %Medication{id: "med-iron", name: "Iron", times: ["21:00", "08:00"]}
  defp vitamin_d, do: %Medication{id: "med-d", name: "Vitamin D", times: ["08:00"]}

  defp shifted(days) do
    Kati.Time.today() |> Date.add(days) |> Calendar.strftime("%d %b") |> String.upcase()
  end
end
