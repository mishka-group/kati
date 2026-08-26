Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.OnboardingResumeTest do
  @moduledoc """
  A first run you were interrupted during picks up where it left off.

  The first run is the one part of Kati nobody can skip, and it is also the
  part most likely to be interrupted: it happens in the first minute, on a new
  phone, usually while doing something else. Killed after choosing a language
  and ticking two sections, the app used to reopen on screen 53 and ask both
  again.

  The answers were never lost — `Kati.Locale.put/1` and `Kati.Sections.put/1`
  both write at the moment of the answer rather than at the end of the run. So
  the app HAD them and asked anyway, which is worse than not having them: it
  tells someone the first thing they said did not count.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Onboarding

  setup do
    Onboarding.reset!()
    Kati.Sections.forget!()
    Kati.Locale.put(:en)
    :ok
  end

  describe "where the run reopens" do
    test "a fresh install starts at the language step" do
      assert Onboarding.step() == :language
      assert Onboarding.first_screen() == Kati.Screens.LanguagePick
    end

    test "a run interrupted on sections reopens on sections, not at the start" do
      Onboarding.reached!(:sections)

      assert Onboarding.first_screen() == Kati.Screens.PickSections,
             "the run reopened at the beginning and asked a question already answered"
    end

    test "a run interrupted on the last step reopens there" do
      Onboarding.reached!(:finish)

      assert Onboarding.first_screen() == Kati.Screens.Onboarding
    end

    test "a completed run opens the app, not the run" do
      Onboarding.reached!(:finish)
      Onboarding.complete!()

      assert Onboarding.first_screen() == Kati.Screens.Home
    end

    test "a completed Persian run opens the Persian home" do
      Kati.Locale.put(:fa)
      Onboarding.complete!()

      assert Onboarding.first_screen() == Kati.Screens.HomeFa,
             "the language chosen on screen 53 did not survive into the app"
    end
  end

  describe "the recorded step only moves forwards" do
    test "arriving at an earlier step does not drag the run backwards" do
      # Screens mount for reasons other than someone walking forwards — the
      # back gesture is one, Mob remounting a screen is another. A resume that
      # either could drag backwards would be worse than no resume: it would
      # reopen on a step the person had already passed.
      Onboarding.reached!(:finish)
      Onboarding.reached!(:language)

      assert Onboarding.step() == :finish,
             "going back a screen rewound the run"
    end

    test "re-arming a first run forgets the step it had reached" do
      # Without this, `reset!/0` re-arms a run that immediately reopens on its
      # LAST step and finishes — a reset that resets nothing a person can see.
      Onboarding.reached!(:finish)
      Onboarding.reset!()

      assert Onboarding.step() == :language
      assert Onboarding.first_screen() == Kati.Screens.LanguagePick
    end
  end

  describe "earlier answers are still on the screen" do
    test "the sections picker opens on the design's two when nothing was answered" do
      refute Kati.Sections.answered?()

      view = mount_screen(Kati.Screens.PickSections)

      assert assigns(view).chosen == Kati.Screens.PickSections.Sample.chosen(),
             "a first arrival did not open on the drawing's own selection"
    end

    test "the sections picker reopens on what THIS person ticked" do
      Kati.Sections.put(["music", "money"])

      view = mount_screen(Kati.Screens.PickSections)

      assert assigns(view).chosen == MapSet.new(["music", "money"]),
             "coming back to an interrupted run showed the drawing's sample instead " <>
               "of the answer already given"

      refute assigns(view).chosen == Kati.Screens.PickSections.Sample.chosen()
    end

    test "an answered run does not open on every section" do
      # The specific way seeding from `Kati.Sections.chosen/0` alone goes
      # wrong: it answers "everything" when nothing has been said, so a person
      # who ticked two would come back to six ticked and, pressing Continue,
      # silently widen their own choice.
      Kati.Sections.put(["books"])

      view = mount_screen(Kati.Screens.PickSections)

      assert MapSet.size(assigns(view).chosen) == 1
    end
  end

  describe "what mounting a step records" do
    test "opening the sections picker records that the run reached it" do
      assert Onboarding.step() == :language

      _view = mount_screen(Kati.Screens.PickSections)

      assert Onboarding.step() == :sections,
             "the step was never recorded, so a kill here would reopen at the start"
    end

    test "opening the last step records it" do
      _view = mount_screen(Kati.Screens.Onboarding)

      assert Onboarding.step() == :finish
    end
  end

  describe "restoring a backup during the first run" do
    test "the sections step offers a way to restore" do
      # Criterion of #91, and the one that matters most on a SECOND phone: a
      # person moving devices should not have to walk a setup that invents a
      # fresh library when they already have one.
      view = mount_screen(Kati.Screens.PickSections)

      tags = Kati.ScreenSweep.tap_tags(tree(view))

      assert :import_backup in tags,
             "nothing on the sections step offers a restore, so a person with a backup " <>
               "has no way to use it during the run: " <> inspect(tags)
    end
  end

end
