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
  """
  use Mob.ScreenCase, async: false

  alias Kati.Health
  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Health.Reading
  alias Kati.Screens.LogWeight
  alias Kati.Screens.Medication, as: MedicationScreen
  alias Kati.Screens.Weight

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

  defp shifted(days) do
    Kati.Time.today() |> Date.add(days) |> Calendar.strftime("%d %b") |> String.upcase()
  end
end
