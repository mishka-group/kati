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
    test "53 Continue opens 161, the welcome step" do
      # 26 until `D-33` split screen 38 into its three panels. The welcome is
      # now a step of its own, which is what gives it a Persian address.
      Kati.Locale.put(:en)
      assert push_of(Screens.LanguagePick, :continue) == Screens.OnboardingWelcome
    end

    test "53 Continue opens 164 for a reader who just chose فارسی" do
      # The tap that reached this handler WAS the language choice, so this is
      # the first push that can honour it — and the one that used to send a
      # Persian run into the English drawings for the whole middle of the
      # sequence. #91's fourth criterion, in one assertion.
      Kati.Locale.put(:fa)
      assert push_of(Screens.LanguagePick, :continue) == Screens.OnboardingWelcomeFa
    end

    test "161 Continue opens 26" do
      assert push_of(Screens.OnboardingWelcome, :next) == Screens.PickSections
    end

    test "164 Continue opens 137, which is screen 26 in Persian" do
      assert push_of(Screens.OnboardingWelcomeFa, :next) == Screens.OnboardingFa
    end

    test "26 Continue opens 162, the loudness step" do
      assert push_of(Screens.PickSections, :continue) == Screens.OnboardingLoudness
    end

    test "137's ادامه pill opens 165 rather than nothing at all" do
      # It drew no `on_tap` for as long as the screen existed: there was no
      # Persian step four to push it to, and a dead button reads as a bug
      # where an untranslated screen reads as unfinished. 165 is that step.
      assert push_of(Screens.OnboardingFa, :continue) == Screens.OnboardingLoudnessFa
    end

    test "162 Continue opens 163, and 165 opens 166" do
      assert push_of(Screens.OnboardingLoudness, :next) == Screens.OnboardingFirstTitle
      assert push_of(Screens.OnboardingLoudnessFa, :next) == Screens.OnboardingFirstTitleFa
    end

    test "26's Continue asks for the calendar on the way out" do
      # The entire device-calendar pipe was built and switched off for want of
      # this one call: the manifest declares `READ_CALENDAR`, `MobBridge` maps
      # the capability both ways, `KatiCalendarReader.publish/1` writes the JSON
      # and `Kati.Calendars.DeviceImport.run/0` ingests it at every boot.
      # Nothing asked, so the reader published nothing and the calendar drew a
      # sample forever.
      #
      # Asserted through `Kati.Permissions.asked/0` rather than by watching for
      # a dialog, because there is no bridge on the host to raise one — which is
      # also why `ask_for_calendar/1` rescues. The claim here is that the ask
      # HAPPENS and is recorded; that the OS dialog appears is #82's e2e.
      Kati.Permissions.forget_asked!()
      refute :calendar in Kati.Permissions.asked()

      _ = push_of(Screens.PickSections, :continue)

      assert :calendar in Kati.Permissions.asked(),
             "Continue left the sections step without ever asking for the calendar, " <>
               "which is the state that made every calendar screen a drawing"
    end

    test "granting the calendar mid-session re-ingests rather than waiting for a cold start" do
      # `Kati.Calendars.DeviceImport.run/0` runs once, in `Kati.App`, long
      # before this screen exists. Without a clause for the permission result,
      # someone grants access and nothing reads the freshly published files
      # until the next cold start — "I allowed it and nothing happened".
      view = mount_screen(Screens.PickSections)

      assert {:noreply, %Mob.Socket{}} =
               Screens.PickSections.handle_info({:permission, :calendar, :granted}, view.socket)

      # A denial is an answer, not an error: the screen carries on and every
      # calendar surface keeps drawing what it drew before.
      assert {:noreply, %Mob.Socket{}} =
               Screens.PickSections.handle_info({:permission, :calendar, :denied}, view.socket)
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
    # Both ways out of the last step finish the run. Skip is a way past adding
    # a title, not a way to abandon setup: someone who takes it has still
    # chosen a language and their sections, and the board sends them to the
    # empty Home — the page that says which parts still work — rather than to
    # a half-set-up one.
    for {tag, landing} <- [finish: Screens.Home, skip: Screens.HomeEmpty] do
      test "#{tag} records completion and resets the stack to #{inspect(landing)}" do
        # Rolled back because `:finish` now WRITES — it shelves the picked
        # title, which is the whole point of the step. Left committed, this
        # test would put `The Long Hollow` in the library for every file that
        # runs after it, and the design sweeps compare a screen's render with
        # its drawing: a shelf with something on it draws the something.
        rolled_back(fn ->
          Kati.Onboarding.reset!()
          Kati.Locale.put(:en)

          {:noreply, moved} =
            Screens.OnboardingFirstTitle.handle_info(
              {:tap, unquote(tag)},
              socket_for(Screens.OnboardingFirstTitle)
            )

          assert Kati.Onboarding.complete?()

          assert moved.__mob__.nav_action == {:reset, unquote(landing), %{}},
                 "must reset, not push: pushing leaves the whole first run under Home " <>
                   "and the back gesture walks straight back into it"
        end)
      end
    end

    test "finishing puts the chosen title on the shelf" do
      # The defect this replaced: `:picked` was assigned by the tap, read by
      # the grid to draw a tick, and dropped. A person chose a title, pressed
      # Finish setup, and landed on a Home with an empty library — the state
      # screen 139 exists to describe, reached by the one path meant to avoid
      # it. Screen 163's own moduledoc claimed the opposite in prose, which is
      # why the claim is asserted here rather than left as prose.
      rolled_back(fn ->
        Kati.Onboarding.reset!()
        Kati.Locale.put(:en)

        socket = socket_for(Screens.OnboardingFirstTitle)
        picked = socket.assigns.picked

        # The board's four are the suite's own fixture names — `The Long
        # Hollow` is written by `Kati.AddByHandTest` as the same `:manual` row
        # this writes — so the precondition is MADE rather than assumed. Inside
        # the rollback, so nothing else sees it.
        clear_manual!(picked)
        refute tracked(picked)

        {:noreply, _moved} =
          Screens.OnboardingFirstTitle.handle_info({:tap, :finish}, socket)

        assert %{status: :watching, source: :manual} = tracked(picked)

        # Both rows. The cache row is what search reads and what gives the
        # shelf a name to draw; writing only it is what a device showed —
        # findable in search, absent from the Library.
        assert %{title: ^picked} = cached(picked)
      end)
    end

    test "skipping adds nothing, because skipping is an answer" do
      rolled_back(fn ->
        Kati.Onboarding.reset!()
        Kati.Locale.put(:en)

        socket = socket_for(Screens.OnboardingFirstTitle)
        clear_manual!(socket.assigns.picked)

        {:noreply, _moved} = Screens.OnboardingFirstTitle.handle_info({:tap, :skip}, socket)

        refute tracked(socket.assigns.picked)
      end)
    end

    test "a second run is not refused over a title already kept" do
      # The one ordinary refusal: the tracked row's uniqueness. Trapping
      # someone in setup over a row that already exists would be worse than
      # the defect the write fixes, so the refusal is swallowed and the run
      # still finishes.
      rolled_back(fn ->
        Kati.Onboarding.reset!()
        Kati.Locale.put(:en)

        socket = socket_for(Screens.OnboardingFirstTitle)
        clear_manual!(socket.assigns.picked)

        {:noreply, _first} = Screens.OnboardingFirstTitle.handle_info({:tap, :finish}, socket)
        Kati.Onboarding.reset!()
        {:noreply, again} = Screens.OnboardingFirstTitle.handle_info({:tap, :finish}, socket)

        assert Kati.Onboarding.complete?()
        assert again.__mob__.nav_action == {:reset, Screens.Home, %{}}
      end)
    end

    test "a Persian first run shelves the Persian title it drew" do
      # `Kati.Media.CachedTitle.title` is what the shelf draws, so a Persian
      # run must not put an English name on a Persian shelf.
      rolled_back(fn ->
        Kati.Onboarding.reset!()
        Kati.Locale.put(:fa)

        socket = socket_for(Screens.OnboardingFirstTitleFa)
        picked = socket.assigns.picked
        clear_manual!(picked)

        {:noreply, _moved} =
          Screens.OnboardingFirstTitleFa.handle_info({:tap, :finish}, socket)

        assert %{title: ^picked} = cached(picked)
        refute picked =~ ~r/^[[:ascii:]]+$/
      end)
    end

    test "a Persian first run finishes on screen 55, not on the English home" do
      # Rolled back for the reason the pair above is: finishing shelves a title.
      rolled_back(fn ->
        Kati.Onboarding.reset!()
        Kati.Locale.put(:fa)

        {:noreply, moved} =
          Screens.OnboardingFirstTitleFa.handle_info(
            {:tap, :finish},
            socket_for(Screens.OnboardingFirstTitleFa)
          )

        assert moved.__mob__.nav_action == {:reset, Screens.HomeFa, %{}}
      end)
    end

    test "skipping a Persian run lands on 158, the Persian empty home" do
      # Screen 139 is the English one. Landing there would end an entirely
      # Persian run on an English page — the pairing `D-32` and `D-33`
      # complete between them.
      Kati.Onboarding.reset!()
      Kati.Locale.put(:fa)

      {:noreply, moved} =
        Screens.OnboardingFirstTitleFa.handle_info(
          {:tap, :skip},
          socket_for(Screens.OnboardingFirstTitleFa)
        )

      assert moved.__mob__.nav_action == {:reset, Screens.HomeFaEmpty, %{}}
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

  # A transaction that is always rolled back, the shape
  # `Kati.ScreenSweep.rolled_back/1` uses. Written out rather than required,
  # because that helper is loaded by the sweeps and this file is not one — and
  # the alternative, prefixed rows deleted in `on_exit`, cannot be used here:
  # the titles are the board's own four and this file does not get to choose
  # them.
  defp rolled_back(fun) when is_function(fun, 0) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn -> Kati.Repo.rollback({:rolled_back, fun.()}) end)

    result
  end

  # Remove any `:manual` row for `title`, children first. Only ever called
  # inside `rolled_back/1`.
  defp clear_manual!(title) do
    Kati.Repo.query!(
      "DELETE FROM media_watches WHERE tracked_title_id IN " <>
        "(SELECT id FROM tracked_titles WHERE source = 'manual' AND source_id = ?1)",
      [title]
    )

    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source = 'manual' AND source_id = ?1", [
      title
    ])

    Kati.Repo.query!("DELETE FROM cached_titles WHERE source = 'manual' AND source_id = ?1", [
      title
    ])

    :ok
  end

  defp tracked(title) do
    case Ash.read(Kati.Media.TrackedTitle) do
      {:ok, rows} -> Enum.find(rows, &(&1.source == :manual and &1.source_id == title))
      _error -> nil
    end
  end

  defp cached(title) do
    case Ash.read(Kati.Media.CachedTitle) do
      {:ok, rows} -> Enum.find(rows, &(&1.source == :manual and &1.source_id == title))
      _error -> nil
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
