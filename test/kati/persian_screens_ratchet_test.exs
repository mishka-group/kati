Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.PersianScreensRatchetTest do
  @moduledoc """
  The Persian mirrors are a list that may shrink and may not grow.

  ## The ruling this file enforces

  Kati had 33 Persian screen modules — whole second copies of pages that
  already exist, each holding its own Persian copy as literals. The owner's
  ruling, on 8 September, is that **no more are to be written**:

  > we do not need create any pages for persian all in app, we just have all
  > pages we need just with cldr timing and gettext to translate and rtl and
  > ltr just it like web app we created

  That is a decision about how the app is built, not a preference about this
  round of work, and the way a decision like that survives is a test rather
  than a paragraph. `mishka-group/kati#103` is where the fold itself is
  planned; this file is what stops the pile growing while it waits.

  ## Why a duplicate screen is the expensive answer

  Every mirror doubles the work of every change to the page it mirrors, and it
  does it silently: nothing fails when `Kati.Screens.Home` gains a band and
  `Kati.Screens.HomeFa` does not. That has already happened here more than
  once — MOVIES-AND-TV.md #1 is a Persian Home still announcing three new
  episodes after the English one had stopped, and the fix was the same edit
  twice.

  The pieces the ruling names all exist and are now in use. `ex_cldr` is a
  dependency and `Kati.Cldr` is generated for `:en`, `:fa` and `:und`;
  `Kati.Locale.direction/1` and `direction_prop/0` answer `rtl`/`ltr` and are
  read by `Kati.Shell` and `Kati.UI.Sheet`; `Kati.Gettext` is a
  `Gettext.Backend` with a `priv/gettext` behind it that screen 154 draws
  itself out of.

  **The first fold has landed**, which is what turns the paragraph above from a
  plan into a worked example: `Kati.Screens.AddByHandFa` is gone, board 156 is
  screen 154 rendered under `:fa`, and `Kati.ScreenDesignLiteralTest` compares
  the Persian board against the English module. Nine Movies & Series mirrors
  are left; MOVIES-AND-TV.md #157 is the recipe and #161 is the first one
  written down.

  ## What it does and does not assert

  It asserts the SET, in both directions, because a ratchet that only counted
  would pass on a mirror deleted and another written in the same commit.
  Deleting one is meant to be easy: the failure names exactly which line to
  remove and asks for nothing else. Adding one fails with the ruling quoted.

  It does not assert that a mirror is correct, current, or reachable —
  `Kati.ScreenDesignLiteralTest`, `Kati.ScreenRenderSweepTest` and
  `Kati.AppReachabilityTest` each own a piece of that, and every module below
  is still swept by all three.
  """
  use ExUnit.Case, async: true

  alias Kati.ScreenSweep

  # The mirrors that are left — 32, and the list only shrinks. There were 33 on
  # 8 September 2026; the first to go was `Kati.Screens.AddByHandFa`, folded
  # into `Kati.Screens.AddByHand`, which is what #103's whole fold looks like
  # one screen at a time.
  #
  # `Kati.Screens.Fa` is not here and is not a screen: it is the shared chrome
  # the mirrors call, and the day the last mirror goes it goes with them.
  @mirrors [
    Kati.Screens.AddToListFa,
    Kati.Screens.AlbumDetailFa,
    Kati.Screens.ArtistDetailFa,
    Kati.Screens.AttributionFa,
    Kati.Screens.BookDetailFa,
    Kati.Screens.BooksFa,
    Kati.Screens.CountryPickerFa,
    Kati.Screens.DataSourcesFa,
    Kati.Screens.GoalsFa,
    Kati.Screens.HealthFa,
    Kati.Screens.HomeFa,
    Kati.Screens.HomeFaEmpty,
    Kati.Screens.HomeFaEmptyDark,
    Kati.Screens.HomeFaOmittedSections,
    Kati.Screens.LibraryFa,
    Kati.Screens.ListDetailFa,
    Kati.Screens.LogProgressFa,
    Kati.Screens.MealsMatrixFa,
    Kati.Screens.MoneyFa,
    Kati.Screens.MyServicesFa,
    Kati.Screens.OnboardingFa,
    Kati.Screens.RestoreFa,
    Kati.Screens.ScheduleFa,
    Kati.Screens.SearchFa,
    Kati.Screens.SeriesFa,
    Kati.Screens.SettingsFa,
    Kati.Screens.StatsFa,
    Kati.Screens.TodayFa,
    Kati.Screens.YearShareFa
  ]

  describe "the Persian mirrors" do
    test "no screen module is added to the list" do
      added = found() -- @mirrors

      assert added == [],
             "a new Persian screen module was written:\n" <>
               Enum.map_join(added, "\n", &"  #{inspect(&1)}") <>
               "\n\nThe ruling of 8 September is that there are to be no more: " <>
               "\"we do not need create any pages for persian all in app, we just have all " <>
               "pages we need just with cldr timing and gettext to translate and rtl and " <>
               "ltr just it like web app we created\". A Persian page is the English page " <>
               "with `Kati.Locale.direction_prop/0` and translated strings, not a second " <>
               "module. See mishka-group/kati#103."
    end

    test "and one that goes is taken off it" do
      gone = @mirrors -- found()

      assert gone == [],
             "these mirrors no longer exist, which is the direction this list moves in — " <>
               "delete each line from @mirrors and nothing else:\n" <>
               Enum.map_join(gone, "\n", &"  #{inspect(&1)}")
    end

    test "the pieces the ruling names are all present, so #103 is a fold and not a build" do
      # Stated as a run rather than as prose in the moduledoc, because "gettext
      # is already a dependency" is exactly the kind of claim that is true when
      # written and quietly false a release later.
      assert Code.ensure_loaded?(Kati.Cldr)
      assert :fa in Kati.Cldr.known_locale_names()
      assert Kati.Locale.direction(:fa) == :rtl
      assert Kati.Locale.direction(:en) == :ltr
      assert function_exported?(Kati.Locale, :direction_prop, 0)
      assert Code.ensure_loaded?(Kati.Gettext)
    end
  end

  defp found do
    ScreenSweep.screens()
    |> Enum.filter(&(&1 |> Module.split() |> List.last() |> String.match?(~r/Fa($|[A-Z])/)))
    |> Enum.sort()
  end
end
