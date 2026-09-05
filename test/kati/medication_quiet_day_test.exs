defmodule Kati.MedicationQuietDayTest do
  @moduledoc """
  Screen 112 asks one question, and answers a quiet day in words — D-59.

  ## The defect these are written against

  Two gates asking different questions. `Kati.Screens.Medication.schedules/0`
  asked whether a `Kati.Health.Medication` was stored; `doses/0` and
  `subtitle/1` asked whether a `Kati.Health.Dose` was. Nothing in `lib/` could
  write either table outside a backup restore, so the two questions had the
  same answer on every device that had ever existed — and board 188 changed the
  first answer and not the second. A person typed one prescription and got a
  page reading `SUNDAY 16 AUGUST · 4 DOSES`, four tablets under TODAY belonging
  to nobody with an Iron marked MISSED, and their own single row under
  SCHEDULES.

  So every assertion here is about **one page saying one thing**: the header,
  TODAY and SCHEDULES are all the reader's or all the drawing's, which is screen
  20's rule as `Kati.ScreenEmptyDatabaseTest` writes it down. Both directions
  are pinned — a suite that only checked the populated half would pass on a
  page that had stopped falling back at all.

  ## Why the fixture names were checked against the LIST and not the page

  Because the reminder card used to draw `Kati.Health.WeightSample.reminder/0`'s
  Magnesium unconditionally, so *Magnesium* was on the page legitimately and the
  only assertion that meant anything was that it was not in TODAY's list. That
  is no longer true of the page — `Kati.Screens.Medication.reminder/1` composes
  the card from `Kati.Notifications.Sources.Health`, and
  `Kati.MedicationHonestPageTest` is where the fourth band is pinned — so the
  list assertions here are kept as the narrow claim they always were, and the
  page-wide ones live next door.

  ## The quiet day is the ordinary day, not an edge

  `Kati.Screens.AddMedication.save/1` writes whatever clock times were set and
  no more, so the first medication somebody saves without one puts them
  straight here; a Mon/Wed/Fri tablet, whose schedule sentence Kati
  deliberately does not parse, is the same state four days a week.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Health.WeightSample
  alias Kati.Screens.HealthFa
  alias Kati.Screens.Medication, as: MedicationScreen
  alias Kati.Screens.MedicationEmpty

  # The header's zero clause, whose whole argument is that `NO DOSES` is board
  # 190's word rather than a numeral this file invented.
  doctest Kati.Screens.Medication, only: [count_clause: 1]

  setup do
    # Doses before medications, because SQLite holds the foreign key, and on
    # the way IN as well as out: half the tests here assert the page falls back
    # to its drawing, which is exactly what a neighbour's leaked row turns into
    # a mystery.
    wipe = fn ->
      Kati.Repo.query!("DELETE FROM health_doses", [])
      Kati.Repo.query!("DELETE FROM health_medications", [])
    end

    wipe.()
    on_exit(wipe)

    :ok
  end

  defp a_medication!(name, times) do
    Ash.create!(Medication, %{
      name: name,
      dose: "500 mg",
      schedule: "with breakfast",
      times: times
    })
  end

  # Every drawn string, one per `:text` node rather than joined, because half
  # the assertions here are about a word appearing ONCE — `Kati.MedicationWriteTest`
  # keeps the same helper for the same reason.
  defp texts(view) do
    for node <- flatten(view),
        text = Map.get(Map.get(node, :props) || %{}, :text),
        is_binary(text),
        do: text
  end

  defp drawn_tags(view) do
    for node <- flatten(view),
        {pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_pid(pid),
        do: tag
  end

  describe "one page, one question" do
    test "with a medication stored, neither TODAY nor SCHEDULES is the drawing's" do
      a_medication!("Metformin", ["08:00"])

      refute MedicationScreen.doses() == MedicationScreen.drawn_doses(),
             "TODAY is still the drawing's four beside the reader's own schedule — D-59"

      refute MedicationScreen.schedules() == WeightSample.schedules()
    end

    test "with nothing stored, both halves ARE the drawing's" do
      # The other direction, and it is not decoration: a gate that stopped
      # falling back would pass every assertion above and break screen 190,
      # board 188's empty state and `Kati.ScreenEmptyDatabaseTest`'s pair at
      # once.
      assert MedicationScreen.doses() == MedicationScreen.drawn_doses()
      assert MedicationScreen.schedules() == WeightSample.schedules()
      assert MedicationScreen.subtitle(MedicationScreen.doses()) == WeightSample.doses_subtitle()
    end

    test "the medication you just added is the only thing under TODAY, at its own time" do
      a_medication!("Metformin", ["08:00"])

      view = mount_screen(MedicationScreen)
      doses = assigns(view).doses

      assert Enum.map(doses, & &1.name) == ["Metformin"],
             "somebody's first prescription was answered with prescriptions they have never heard of"

      assert Enum.map(doses, & &1.time) == ["08:00"]
      assert "Metformin" in texts(view)

      refute WeightSample.doses_subtitle() in texts(view),
             "the header still counts the drawing's four over one real medication"
    end

    test "a medication paused with nothing recorded is still the reader's page" do
      # The direction the first pass stepped around, and the sharpest of the
      # two: `Kati.Screens.MedicationDetail`'s *Stop taking* is two taps from
      # here, and the gate was `Kati.Notifications.Sources.Health.active/0`. So
      # somebody who owned one prescription and paused it — a hospital stay, a
      # course finished — answered `{[], []}` and got the whole fixture back:
      # four tablets they never took, an Iron marked MISSED, a header counting
      # four. That is the page D-59 was filed against, reached from the other
      # side.
      medication = a_medication!("Metformin", ["08:00"])
      Ash.update!(medication, %{active: false})

      refute MedicationScreen.doses() == MedicationScreen.drawn_doses(),
             "a reader who paused their own prescription was handed the drawing's four"

      assert MedicationScreen.doses() == []
      assert MedicationScreen.schedules() == []

      strings = texts(mount_screen(MedicationScreen))

      for drawn <- WeightSample.doses(), do: refute(drawn.name in strings)
      refute WeightSample.doses_subtitle() in strings
      refute "SCHEDULES" in strings
    end

    test "and its quiet-day sentence stops pointing at a band that is not drawn" do
      # `nothing_due/1`'s tail names `UI.eyebrow("Schedules")`, and an
      # all-paused page draws no Schedules band at all — so the tail is dropped,
      # which is what `Kati.Screens.HealthFa`'s own label already does with 139's
      # tail for the same reason. The requirement is the one `empty_day/0` states:
      # *the control it names is real.*
      medication = a_medication!("Metformin", ["08:00"])
      Ash.update!(medication, %{active: false})

      strings = texts(mount_screen(MedicationScreen))

      assert MedicationScreen.nothing_due([]) in strings
      refute MedicationScreen.nothing_due([%{}]) in strings
      assert "TODAY" in strings, "the page's first section vanished on a quiet day"
    end

    test "a paused medication with a dose recorded today draws neither half from the drawing" do
      medication = a_medication!("Metformin", ["08:00"])

      Ash.create!(Dose, %{
        medication_id: medication.id,
        due_on: Kati.Time.today(),
        due_at: "08:00",
        state: :taken
      })

      Ash.update!(medication, %{active: false})

      # This is D-59's defect with its halves swapped, and screen 189's `active`
      # switch is what makes it reachable: under the old gates TODAY was the
      # reader's and SCHEDULES was the drawing's four.
      refute MedicationScreen.doses() == MedicationScreen.drawn_doses()
      assert MedicationScreen.schedules() == []

      # And the empty band takes its own eyebrow with it rather than drawing a
      # heading over nothing — `Kati.Screens.BookDetail.series_section/1`'s rule.
      assert MedicationScreen.schedule_band([]) == []
      refute "SCHEDULES" in texts(mount_screen(MedicationScreen))
    end
  end

  describe "the header cannot disagree with the list" do
    test "it is the drawing's exactly when the list is" do
      assert MedicationScreen.subtitle(MedicationScreen.drawn_doses()) ==
               WeightSample.doses_subtitle()

      refute MedicationScreen.subtitle([]) == WeightSample.doses_subtitle()
    end

    test "a quiet day says NO DOSES, with the device's own date" do
      a_medication!("Metformin", [])

      subtitle = MedicationScreen.subtitle(MedicationScreen.doses())

      assert String.ends_with?(subtitle, " · NO DOSES"),
             "a page with nothing to count printed a count"

      assert String.starts_with?(
               subtitle,
               String.upcase(Calendar.strftime(Kati.Time.today(), "%A %-d %B"))
             )
    end

    test "NO DOSES is board 190's word rather than one this page invented" do
      # What pins the borrowed literal to the board it came from, rather than
      # to a comment claiming it did.
      assert String.ends_with?(MedicationEmpty.subtitle(), MedicationScreen.count_clause(0))
    end
  end

  describe "a day with medications and nothing due" do
    setup do
      a_medication!("Metformin", [])

      %{view: mount_screen(MedicationScreen)}
    end

    test "the list is empty, which it could never be before", %{view: view} do
      assert assigns(view).doses == []
    end

    test "the band keeps its eyebrow and draws the sentence", %{view: view} do
      strings = texts(view)

      assert MedicationScreen.nothing_due(assigns(view).schedules) in strings
      assert "TODAY" in strings, "the page's first section vanished on a quiet day"
    end

    test "and draws no verbs at all — absent rather than inert", %{view: view} do
      assert MedicationScreen.undecided(assigns(view).doses) == nil
      assert MedicationScreen.actions(nil) == []

      # `Taken` used to be on the page once whatever the store held, in the
      # reminder card's picture of a notification. `reminder/1` composes that
      # card from `Kati.Notifications.Sources.Health` now, and a medication
      # whose schedule is a sentence with no clock in it arms nothing — so this
      # page draws no reminder either and the word is absent entirely. What is
      # asserted is what was always asserted: the pair under the list is not
      # drawn over a dose that does not exist.
      assert Enum.count(texts(view), &(&1 == "Taken")) == 0
      assert Enum.count(texts(view), &(&1 == "Skip")) == 0
    end

    test "the quiet-day card carries no tap", %{view: view} do
      # Nothing here is broken and nothing needs adding, so a control could
      # only act on a premise that is false. This also keeps
      # `Kati.ScreenTapSweepTest` from needing an entry it was never given.
      refute Enum.any?(drawn_tags(view), &String.starts_with?(Atom.to_string(&1), "dose_"))
    end

    test "none of the drawing's four tablets is anywhere in the list", %{view: view} do
      names = Enum.map(assigns(view).doses, & &1.name)

      for drawn <- WeightSample.doses(), do: refute(drawn.name in names)
    end
  end

  describe "the Persian mirror" do
    test "words the quiet day rather than drawing its own three fixtures" do
      a_medication!("Metformin", [])

      assert HealthFa.doses() == []

      strings = texts(mount_screen(HealthFa))

      assert HealthFa.labels().nothing_due in strings

      for drawn <- HealthFa.drawn_doses() do
        refute drawn.name in strings,
               "screen 115 drew its Persian fixtures beside a real medication"
      end
    end

    test "still draws its three with nothing stored" do
      assert HealthFa.doses() == HealthFa.drawn_doses()
    end
  end
end
