defmodule Kati.MedicationWriteTest do
  @moduledoc """
  A medication can be put into Kati by hand, opened, changed and removed.

  ## What this is written against

  `Kati.Health.Medication` has had `create: :*` since it was written and
  **nothing in `lib/` called it**. The only writer that had ever existed was
  `Kati.Backup.Catalog`'s restore, so on every fresh install screen 112's four
  tablets were `Kati.Health.WeightSample.doses/0` — the drawing's own four,
  belonging to nobody — and screen 115's dose verbs, fixed one commit before
  these boards landed, could not be checked by a person at all. Three rounds
  ended with that sentence in the report.

  So the receipt in every test here is **the row**, read back with a fresh
  query, and never the socket: a form that moves an assign and writes nothing
  is exactly the state D-43 exists to end, and it looks identical from the
  assigns.

  ## Two medications, and the second one

  Every assertion about *which* row a control acted on uses two stored
  medications and acts on the **second**. An implementation that re-queries,
  one that takes the head of `:active`, and one that falls back to the drawing
  all pass a one-row test and fail these — which is the shape
  `Kati.MedicationDoseWriteTest` settled on for the doses above them, for the
  same reason.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Screens.AddMedication
  alias Kati.Screens.Medication, as: MedicationScreen
  alias Kati.Screens.MedicationDetail
  alias Kati.Screens.MedicationEmpty

  setup do
    # Doses before medications, because SQLite holds the foreign key. Both on
    # the way in as well as out: several tests below assert a page falls back
    # to its drawing, which is precisely what a neighbour's leaked row turns
    # into a mystery.
    wipe = fn ->
      Kati.Repo.query!("DELETE FROM health_doses", [])
      Kati.Repo.query!("DELETE FROM health_medications", [])
    end

    wipe.()
    on_exit(wipe)

    :ok
  end

  defp two! do
    {a!("Iron", "65 mg", ["13:00"]), a!("Vitamin D", "1000 IU", ["08:00"])}
  end

  defp a!(name, dose, times) do
    Ash.create!(Medication, %{
      name: name,
      dose: dose,
      schedule: "daily, " <> hd(times),
      times: times,
      instruction: "with water"
    })
  end

  defp typed(view, field, text), do: render_info(view, {:change, field, text})

  defp texts(view) do
    for node <- flatten(view),
        text = Map.get(Map.get(node, :props) || %{}, :text),
        is_binary(text),
        do: text
  end

  describe "screen 188 writes what was typed" do
    test "a typed name, dose, schedule and instruction reach the store" do
      view =
        AddMedication
        |> mount_screen()
        |> typed(:name, "Metformin")
        |> typed(:dose, "500 mg")
        |> typed(:schedule, "with breakfast and dinner")
        |> typed(:instruction, "after food")

      render_info(view, {:tap, :save})

      # A fresh read rather than the record the write handed back: the claim is
      # that it LANDED, and a struct in memory cannot say that.
      assert [row] = Ash.read!(Medication)
      assert row.name == "Metformin"
      assert row.dose == "500 mg"
      assert row.schedule == "with breakfast and dinner"
      assert row.instruction == "after food"
      assert row.active == true
    end

    test "the times the chip row holds are the times that are stored" do
      view = mount_screen(AddMedication)

      assert assigns(view).times == ["08:00"], "the sheet opens on board 188's own time"

      view = render_info(view, {:tap, :add_time})
      assert assigns(view).times == ["08:00", "13:00"]

      render_info(view, {:tap, :save})

      assert [%Medication{times: ["08:00", "13:00"]}] = Ash.read!(Medication)
    end

    test "a time chip taken off is a time that is not armed" do
      view =
        AddMedication
        |> mount_screen()
        |> render_info({:tap, :"time_08:00"})

      assert assigns(view).times == []

      render_info(view, {:tap, :save})

      # `times: []` is a real answer, not a missing one:
      # `Kati.Notifications.Sources.Health` contributes a suppressed `:no_times`
      # candidate for it rather than nothing at all.
      assert [%Medication{times: []}] = Ash.read!(Medication)
    end

    test "the empty optional fields are stored as nothing, not as an empty string" do
      view =
        AddMedication
        |> mount_screen()
        |> typed(:name, "Iron")
        |> typed(:dose, "")
        |> typed(:instruction, "  ")

      render_info(view, {:tap, :save})

      assert [row] = Ash.read!(Medication)
      assert row.dose == nil
      assert row.instruction == nil

      # And the two lines screen 112 prints still compose, which is the whole
      # reason `schedule_line/1` rejects the empty parts.
      refute Medication.schedule_line(row) =~ " ·  · "
    end
  end

  describe "screen 188 refuses, and says why" do
    test "Save with no name writes nothing and names what is missing" do
      view =
        AddMedication
        |> mount_screen()
        |> typed(:name, "   ")
        |> render_info({:tap, :save})

      assert Ash.read!(Medication) == [], "a nameless medication reached the store"
      assert assigns(view).save_error == AddMedication.refusal()
      assert assigns(view).save_error == "A medication needs a name"
    end

    test "the sheet stays open and what was typed is still there" do
      view =
        AddMedication
        |> mount_screen()
        |> typed(:name, "")
        |> typed(:dose, "500 mg")
        |> render_info({:tap, :save})

      assert navigated_to(view) == nil,
             "the sheet closed on a failed save, which is how a lost write looks like a " <>
               "completed one"

      assert assigns(view).dose == "500 mg"
    end

    test "the refusal card draws the three sentences board 188 draws" do
      # The card at the foot of board 188 and the message a refusal produces
      # are one sentence, so `refusal/0` is the only place it is written. This
      # is the state `Kati.ScreenDesignLiteralTest.drawn_state/0` compares the
      # board against.
      view = mount_screen(AddMedication)

      refused = %{
        view
        | socket: Mob.Socket.assign(view.socket, :save_error, AddMedication.refusal())
      }

      drawn = texts(refused)

      assert AddMedication.refusal() in drawn
      assert Enum.any?(drawn, &String.contains?(&1, "Nothing was written."))
      assert Enum.any?(drawn, &String.contains?(&1, "a dead button explains nothing"))
    end

    test "a save that landed closes the sheet" do
      view =
        AddMedication
        |> mount_screen()
        |> typed(:name, "Iron")
        |> render_info({:tap, :save})

      refute navigated_to(view) == nil, "a save that landed left the sheet open"
      assert assigns(view).save_error == nil
    end
  end

  describe "the shelf shows the new row afterwards" do
    test "screen 112's Schedules group draws what screen 188 wrote" do
      assert MedicationScreen.schedules() == Kati.Health.WeightSample.schedules(),
             "with nothing stored the group is the drawing's four"

      AddMedication
      |> mount_screen()
      |> typed(:name, "Metformin")
      |> typed(:dose, "500 mg")
      |> typed(:schedule, "with breakfast and dinner")
      |> render_info({:tap, :save})

      assert [row] = MedicationScreen.schedules()
      assert row.name == "Metformin"
      assert row.line == "500 mg · with breakfast and dinner"

      # And the page can name it, which is what a chevron needs before it can
      # open anything: a stored row carries `:id`, the drawing's four do not.
      assert Map.has_key?(row, :id)
      refute Enum.any?(Kati.Health.WeightSample.schedules(), &Map.has_key?(&1, :id))
    end

    test "the name reaches the rendered page, not only the reader" do
      AddMedication
      |> mount_screen()
      |> typed(:name, "Metformin")
      |> render_info({:tap, :save})

      assert "Metformin" in texts(mount_screen(MedicationScreen))
    end
  end

  describe "the door" do
    test "screen 112's add disc opens the sheet" do
      view = render_info(mount_screen(MedicationScreen), {:tap, :add})

      assert navigated_to(view) == AddMedication
    end

    test "a Schedules chevron opens the medication that row drew, not the head of a query" do
      {_iron, vitamin_d} = two!()

      view = mount_screen(MedicationScreen)
      schedules = assigns(view).schedules

      # `:active` sorts by name, so Iron leads and Vitamin D is the second row.
      assert Enum.map(schedules, & &1.name) == ["Iron", "Vitamin D"]

      second = Enum.at(schedules, 1)
      opened = render_info(view, {:tap, MedicationScreen.schedule_tag(second)})

      assert navigated_to(opened) == MedicationDetail

      assert {:push, MedicationDetail, %{medication_id: id}} =
               opened.socket.__mob__.nav_action

      assert id == vitamin_d.id, "the second row opened the first medication"
    end

    test "a chevron over the drawing hands the page nothing rather than a lie" do
      view = mount_screen(MedicationScreen)
      first = hd(assigns(view).schedules)

      opened = render_info(view, {:tap, MedicationScreen.schedule_tag(first)})

      assert {:push, MedicationDetail, %{}} = opened.socket.__mob__.nav_action
      assert MedicationDetail.params_for(first) == %{}
    end
  end

  describe "screen 189 acts on the row it drew" do
    test "it opens on the medication it was named" do
      {_iron, vitamin_d} = two!()

      view = mount_screen(MedicationDetail, %{medication_id: vitamin_d.id})

      assert assigns(view).medication.name == "Vitamin D"
      assert assigns(view).medication.id == vitamin_d.id
    end

    test "Stop taking pauses that medication and leaves the other alone" do
      {iron, vitamin_d} = two!()

      MedicationDetail
      |> mount_screen(%{medication_id: vitamin_d.id})
      |> render_info({:tap, :stop_taking})

      assert Ash.get!(Medication, vitamin_d.id).active == false
      assert Ash.get!(Medication, iron.id).active == true

      # And it is off screen 112's Schedules group, which is what `active` is
      # for — while every dose already recorded is untouched.
      assert Enum.map(MedicationScreen.schedules(), & &1.name) == ["Iron"]
    end

    test "Remind me off clears the times, which is what arms the reminder" do
      {_iron, vitamin_d} = two!()

      MedicationDetail
      |> mount_screen(%{medication_id: vitamin_d.id})
      |> render_info({:tap, :remind_off})

      assert Ash.get!(Medication, vitamin_d.id).times == []

      # `Kati.Notifications.Sources.Health` is explicit that this is a state
      # rather than an absence: a medication with no times still contributes a
      # candidate, so *this one never reminds me* stays answerable.
      assert [_suppressed] =
               Kati.Notifications.Sources.Health.candidates(
                 [Ash.get!(Medication, vitamin_d.id)],
                 Kati.Time.today()
               )
    end

    test "a page named a row that is gone writes nothing at all" do
      {iron, vitamin_d} = two!()
      bogus = Ash.UUID.generate()

      view = mount_screen(MedicationDetail, %{medication_id: bogus})

      assert assigns(view).medication == MedicationDetail.drawn_medication(),
             "a page told about a row it cannot find must draw its own drawing"

      refute Map.has_key?(assigns(view).medication, :id),
             "the drawing carries no id, by absence — a nil one is a name a write can be handed"

      for tag <- [:stop_taking, :remind_off, :add_time, :"time_08:00"] do
        acted = render_info(view, {:tap, tag})
        assert assigns(acted).save_error == "Nothing to save yet."
      end

      assert Ash.get!(Medication, iron.id).active == true
      assert Ash.get!(Medication, vitamin_d.id).active == true
      assert Ash.get!(Medication, vitamin_d.id).times == ["08:00"]
    end

    test "a field edited in place lands on that row" do
      {iron, vitamin_d} = two!()

      MedicationDetail
      |> mount_screen(%{medication_id: vitamin_d.id})
      |> typed(:dose, "2000 IU")

      assert Ash.get!(Medication, vitamin_d.id).dose == "2000 IU"
      assert Ash.get!(Medication, iron.id).dose == "65 mg"
    end
  end

  describe "screen 189 deletes, in two taps" do
    test "the first tap arms and writes nothing; the second takes the doses with it" do
      {iron, vitamin_d} = two!()

      dose =
        Ash.create!(Dose, %{
          medication_id: vitamin_d.id,
          due_on: Kati.Time.today(),
          due_at: "08:00"
        })

      armed =
        MedicationDetail
        |> mount_screen(%{medication_id: vitamin_d.id})
        |> render_info({:tap, :delete})

      assert assigns(armed).confirm_delete? == true
      assert Ash.get!(Medication, vitamin_d.id).id == vitamin_d.id, "one tap deleted the row"

      gone = render_info(armed, {:tap, :delete})

      refute navigated_to(gone) == nil, "the page stayed open over a medication it deleted"
      assert Enum.map(Ash.read!(Medication), & &1.id) == [iron.id]

      assert Ash.read!(Dose) == [],
             "a dose outlived the medication it belongs to, which its own " <>
               "`allow_nil? false` says it cannot"

      refute Enum.any?(Ash.read!(Dose), &(&1.id == dose.id))
    end

    test "the card says how many doses go, counted rather than claimed" do
      {_iron, vitamin_d} = two!()

      for at <- ["08:00", "13:00", "21:00"] do
        Ash.create!(Dose, %{
          medication_id: vitamin_d.id,
          due_on: Kati.Time.today(),
          due_at: at
        })
      end

      view = mount_screen(MedicationDetail, %{medication_id: vitamin_d.id})

      assert assigns(view).medication.doses == 3
      assert "This takes 3 recorded doses with it" in texts(view)
    end
  end

  describe "screen 190 is the empty state" do
    test "it says there is nothing rather than counting a fixture's four" do
      drawn = texts(mount_screen(MedicationEmpty))

      assert "No medications yet" in drawn
      assert MedicationEmpty.subtitle() in drawn
      assert MedicationEmpty.subtitle() == "SUNDAY 16 AUGUST · NO DOSES"

      refute Kati.Health.WeightSample.doses_subtitle() in drawn,
             "the empty page printed the fixture's `4 DOSES`, which is the whole defect " <>
               "board 190 was drawn against"
    end

    test "both of its actions open something" do
      view = mount_screen(MedicationEmpty)

      assert navigated_to(render_info(view, {:tap, :add})) == AddMedication
      assert navigated_to(render_info(view, {:tap, :add_first})) == AddMedication
      assert navigated_to(render_info(view, {:tap, :restore_backup})) == Kati.Screens.Restore
    end

    test "its two controls do not share one name" do
      # `Mob.Renderer` emits an `accessibility_id` from every atom tag, so two
      # controls under one name is a node `onNodeWithTag` throws on and a
      # screen reader announces twice.
      tags =
        for node <- flatten(mount_screen(MedicationEmpty)),
            {pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
            is_pid(pid),
            do: tag

      assert length(Enum.uniq(tags)) == length(tags), "a tag is drawn twice: #{inspect(tags)}"
    end
  end

  describe "the notification this page previews is the one that gets sent" do
    test "the preview's title and body are composed by the source, not by the screen" do
      m = MedicationDetail.drawn_medication()

      assert m.notification_title == "3 doses",
             "three tablets at 08:00 is one thing that happens at 08:00"

      assert m.notification_body == "50 mcg · before food"
      assert m.shared_line == "08:00 · with Vitamin D and Iron"
    end

    test "a medication sharing no clock time draws no Shared with row" do
      {_iron, vitamin_d} = two!()

      m = MedicationDetail.medication(vitamin_d.id)

      assert m.shared == []
      assert m.shared_line == nil
      assert m.notification_title == "Vitamin D"
      assert m.notification_body == "1000 IU · with water"
    end
  end
end
