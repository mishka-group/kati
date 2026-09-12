Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.PersianScreensRatchetTest do
  @moduledoc """
  The Persian mirrors are a list that may shrink and may not grow.

  ## The ruling this file enforces

  Kati had 33 Persian screen modules — whole second copies of pages that
  already exist, each holding its own Persian copy as literals. **There are
  none.** The owner's ruling, on 8 September, was that no more were to be
  written:

  > we do not need create any pages for persian all in app, we just have all
  > pages we need just with cldr timing and gettext to translate and rtl and
  > ltr just it like web app we created

  Restated on 11 September, while the fold was running, and it is the sharper
  form — it names the END STATE rather than only forbidding new ones:

  > every page we have in english with all feceleties just in persian has
  > translate with gettext or cldr for number and date and dattime **no another
  > _fa page if still exist so do not let it and fix it too**

  So `@mirrors` is not a list to be kept. It is a list to be emptied, and this
  file is what makes each deletion cheap and each addition impossible.

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

  **The fold is finished.** `Kati.Screens.AddByHandFa` was the first to go and
  the four roots were the last — board 55 is `Kati.Screens.Home` under `:fa`,
  56 is `Kati.Screens.Calendar`, 57 is `Kati.Screens.Library`, 61 is
  `Kati.Screens.Stats` — and `Kati.Screens.Fa`, the chrome they shared, went
  with them. Every Persian board in `test/design/screens/` is now compared
  against the English module that draws it, by
  `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.

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

  # **Empty.** There were 33 on 8 September 2026; the first to go was
  # `Kati.Screens.AddByHandFa`, folded into `Kati.Screens.AddByHand`, and the
  # last four were the roots — `Kati.Screens.HomeFa`, `ScheduleFa`, `LibraryFa`
  # and `StatsFa` — which went with `Kati.Screens.Fa` itself, the shared chrome
  # they called.
  #
  # The list stays, and stays empty. It is the ratchet: `found/0` sweeps every
  # screen module for a name ending in `Fa`, and an empty list is what turns
  # "no more are to be written" from a paragraph into a failing test the moment
  # somebody writes one.
  #
  # Two Persian-only BOARDS survive as screens and neither is a mirror.
  # `Kati.Screens.HomeEmptyDark` is board 139 in the dark colourway — the
  # relation 28 has to 01 — and `Kati.Screens.HomeOmittedSections` is a
  # reference sheet in board 27's manner. Both draw translated copy and take
  # their script from `Kati.Locale`, which is what the ruling asks; neither has
  # `Fa` in its name, which is what this sweep looks for.
  @mirrors []

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
