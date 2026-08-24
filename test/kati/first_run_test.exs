defmodule Kati.FirstRunTest do
  @moduledoc """
  The first-run sequence: screens 53 → 26 → 38 → the shell.

  ## The defect this exists for

  All three screens were drawn, built and unreachable. `Kati.App.navigation/1`
  named `Kati.Screens.Home` as the stack root unconditionally, so a fresh
  install opened a home page for a library that did not exist yet, and the
  three onboarding screens could only be seen from `Kati.Screens.Gallery` — a
  development scaffold that reaches all 62 by construction and therefore
  proves nothing about whether a user can get anywhere.

  Screen 53's own moduledoc had recorded the blocker: writing a locale from a
  step 1 with no step 2 strands the reader in a flipped interface whose only
  exit is a back button. The fix was the flow, not the write.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens

  # State is set at the START of each test rather than restored in `on_exit`:
  # `Mob.State` is a named GenServer that is not alive by the time an on_exit
  # callback runs, so restoring there exits with `no process`. Every test below
  # writes the locale and the flag it needs, so none depends on the last one.
  setup do
    Kati.Locale.put(:en)
    Kati.Onboarding.reset!()
    :ok
  end

  describe "which screen the app opens on" do
    test "a fresh install opens the language picker" do
      Kati.Onboarding.reset!()
      assert Kati.Onboarding.first_screen() == Screens.LanguagePick
    end

    test "afterwards it opens the shell root for the chosen locale" do
      Kati.Onboarding.complete!()

      Kati.Locale.put(:en)
      assert Kati.Onboarding.first_screen() == Screens.Home

      Kati.Locale.put(:fa)
      assert Kati.Onboarding.first_screen() == Screens.HomeFa
    end

    test "the flag defaults to false rather than to done" do
      # A store that has never been written is a fresh install. Defaulting the
      # other way skips the sequence on exactly the device that needs it.
      Kati.Onboarding.reset!()
      refute Kati.Onboarding.complete?()
    end
  end

  describe "walking the sequence" do
    test "53 Continue opens 26" do
      assert push_of(Screens.LanguagePick, :continue) == Screens.PickSections
    end

    test "26 Continue opens 38" do
      assert push_of(Screens.PickSections, :continue) == Screens.Onboarding
    end

    test "26's escape hatch goes to the chromeless Restore, not straight to Import" do
      # This asserted `Screens.Import` until 24 August, and was right to: 135 did
      # not exist, so the only place a `Restore from a backup instead` tap could
      # land was the importer. Screen 134 — the first-run flow map — draws the
      # edge as `26 call_split Restore from a backup instead → 135`, and the same
      # branch offered from 38·1. Import is still downstream, one hop later:
      # 135's own `file accepted` edge goes to 37, which is where the pre-write
      # summary and the conflicts live.
      #
      # The distinction is load-bearing rather than cosmetic. Landing on 37
      # directly would ask someone to resolve conflicts for a file they have not
      # chosen yet; 135 is the chromeless screen where the file or the QR is
      # picked, and it is the screen that can refuse one.
      assert push_of(Screens.PickSections, :import_backup) == Screens.RestoreFirstRun
    end

    test "26 does not mark the run complete — step two is not the end" do
      Kati.Onboarding.reset!()
      _ = push_of(Screens.PickSections, :continue)

      refute Kati.Onboarding.complete?(),
             "backing out at step three would never be offered the run again"
    end
  end

  describe "finishing" do
    for tag <- [:get_started, :finish] do
      test "#{tag} records completion and resets the stack to the shell" do
        Kati.Onboarding.reset!()
        Kati.Locale.put(:en)

        {:noreply, moved} =
          Screens.Onboarding.handle_info({:tap, unquote(tag)}, socket_for(Screens.Onboarding))

        assert Kati.Onboarding.complete?()

        assert moved.__mob__.nav_action == {:reset, Screens.Home, %{}},
               "must reset, not push: pushing leaves the whole first run under Home " <>
                 "and the back gesture walks straight back into it"
      end
    end

    test "a Persian first run finishes on screen 55, not on the English home" do
      Kati.Onboarding.reset!()
      Kati.Locale.put(:fa)

      {:noreply, moved} =
        Screens.Onboarding.handle_info({:tap, :finish}, socket_for(Screens.Onboarding))

      assert moved.__mob__.nav_action == {:reset, Screens.HomeFa, %{}}
    end
  end

  describe "the launch latch" do
    test "opens once per run and closes behind itself" do
      Kati.Screens.Root.rearm_launch!()
      assert Kati.Screens.Root.launching?()
      refute Kati.Screens.Root.launching?()
      refute Kati.Screens.Root.launching?()
    after
      Kati.Screens.Root.launching?()
    end

    test "a root mounted after the latch closes queues no redirect" do
      # The defect this guards: `nav_stack == []` is also true when the user
      # pops back to a root, so on that test alone the first-run sequence
      # re-runs mid-session. `Kati.CalendarDayRouteTest` caught it by backing
      # off screen 09 into a language picker.
      Kati.Onboarding.reset!()
      Kati.Screens.Root.rearm_launch!()
      Kati.Screens.Root.launching?()

      {:ok, _} = Screens.Calendar.mount(%{}, %{}, %Mob.Socket{})

      refute_received :kati_first_run
    end

    test "a root mounted at launch does queue one" do
      Kati.Onboarding.reset!()
      Kati.Screens.Root.rearm_launch!()

      {:ok, _} = Screens.Home.mount(%{}, %{}, %Mob.Socket{})

      assert_received :kati_first_run
    after
      Kati.Screens.Root.launching?()
    end

    test "an onboarded fa install is sent to the Persian root at launch" do
      Kati.Onboarding.complete!()
      Kati.Locale.put(:fa)
      Kati.Screens.Root.rearm_launch!()

      {:ok, _} = Screens.Home.mount(%{}, %{}, %Mob.Socket{})

      assert_received :kati_locale_root
    after
      Kati.Locale.put(:en)
      Kati.Screens.Root.launching?()
    end

    test "an onboarded en install is left alone" do
      Kati.Onboarding.complete!()
      Kati.Locale.put(:en)
      Kati.Screens.Root.rearm_launch!()

      {:ok, _} = Screens.Home.mount(%{}, %{}, %Mob.Socket{})

      refute_received :kati_first_run
      refute_received :kati_locale_root
    after
      Kati.Screens.Root.launching?()
    end
  end

  defp socket_for(module) do
    {:ok, socket} = module.mount(%{}, %{}, %Mob.Socket{})
    socket
  end

  defp push_of(module, tag) do
    {:noreply, moved} = module.handle_info({:tap, tag}, socket_for(module))

    case moved.__mob__.nav_action do
      {:push, dest, _} -> dest
      {:reset, dest, _} -> dest
      other -> flunk("#{inspect(module)} answered #{inspect(tag)} with #{inspect(other)}")
    end
  end
end
