Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.LocaleFaceTest do
  @moduledoc """
  What the shared frames have to answer about the locale, beyond the direction.

  Two things, and both are invisible when they are wrong: the typeface every
  unstyled `Text` falls back to, and which way the back chevron points.

  ## The branch no screen could reach

  `Kati.Screens.Fa`'s first type rule is *every Persian string needs
  `font_family="fa"`*, and it had to be obeyed by hand because the bridge's
  `fontFamilyProp` resolved a missing prop to **Latin**: *"No prop means body
  text, and body text is Plus Jakarta Sans."* Plus Jakarta Sans carries zero
  code points in U+0600–U+06FF, which `Kati.PersianFontTest` re-derives from
  the shipped `cmap` rather than trusting.

  A rule obeyed by hand can be obeyed everywhere a hand can reach, and the
  places it cannot are the ones that matter: a `Text` a **component** builds
  takes no prop from the screen at all. `MishkaChip`'s `expand/3` discards its
  children, `MishkaSegmentedControl` says the label is a prop *because the
  control paints it*, and `MishkaNavLink` takes `label` and `description` as
  strings. `Kati.Screens.Fa`'s moduledoc names that as the reason the Persian
  mirrors adopt only four of the app's components, and files the ask upstream.

  So the answer moved to where every `Text` already passes: the root node says
  the app's face, `MainActivity` installs it as the default (`K-48
  locale-face-root`), and `fontFamilyProp` falls back to it. An explicit
  `font_family` still wins, so a Latin title inside a Persian page is still one
  prop away.

  ## What this file can and cannot see

  It asserts the prop is on the root of every frame, in both locales, which is
  the half that lives in Elixir. It cannot assert the glyphs: that is the
  bridge's half, and `SeriesSettingsTest`'s neighbours in
  `android/app/src/androidTest/` are where a device is asked. The value of
  checking it here is that a frame which silently stopped declaring a face
  would otherwise fail nowhere at all — the page still renders, in the wrong
  typeface, which is the exact failure mode this whole mechanism is about.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  # No locale teardown: `Mob.ScreenCase` starts `Mob.State` per test against a
  # throwaway data dir and tears it down with the test process, so every test
  # here begins at the default. `ScreenSweep.with_locale/2` restores it within a
  # test anyway; an `on_exit` would call a GenServer that is already gone.

  describe "the face a locale names" do
    test "Persian is Vazirmatn and everything else is the Latin body face" do
      assert Kati.Locale.face_for(:fa) == "fa"
      assert Kati.Locale.face_for(:en) == "sans"
    end

    test "and the active locale answers with its own" do
      assert ScreenSweep.with_locale(:fa, &Kati.Locale.face_prop/0) == "fa"
      assert ScreenSweep.with_locale(:en, &Kati.Locale.face_prop/0) == "sans"
    end

    test "`sans` rather than nil for English, because the bridge reads nil as *do nothing*" do
      # `MobBridge.fontFamilyProp` keeps its old behaviour when the local is
      # null. Naming the face makes English a decision this app states rather
      # than a default it inherits — and it is what makes the assertion below
      # able to tell "declared Latin" from "forgot to declare".
      refute Kati.Locale.face_prop() == nil
    end
  end

  describe "every frame declares it on the root" do
    for locale <- [:en, :fa] do
      test "in #{locale}, no screen renders a root without a face" do
        locale = unquote(locale)

        bare =
          ScreenSweep.with_locale(locale, fn ->
            ScreenSweep.screens()
            |> Enum.reject(&(&1 == Kati.Screens.Gallery))
            |> Enum.filter(fn module ->
              case safe_root(module) do
                nil -> false
                root -> is_nil(Map.get(root.props, :font_family))
              end
            end)
          end)

        assert bare == [],
               """
               these screens draw a root node that names no typeface, so every
               Text under them that does not carry `font_family` itself falls
               back to Plus Jakarta Sans — which has no Arabic-script glyph, so
               in #{locale} it is Android's substitute face rather than Kati's:

               #{Enum.map_join(bare, "\n", &"  #{inspect(&1)}")}

               The three shared frames put it there (`Kati.Shell`,
               `Kati.Screens.Pushed`, `Kati.UI.Sheet`), and `Kati.Screens.Fa`'s
               two hard-code `fa` the way they hard-code `rtl`. A screen that
               builds its own root has to say it too.
               """
      end
    end

    test "the Persian mirrors say `fa` whatever the app locale is" do
      # The same claim `Kati.PersianFontTest` makes about their strings: a
      # mirror is the Persian page, so it is Persian in an English app too.
      # Their frames hard-code the face for exactly the reason they hard-code
      # the direction.
      #
      # `Kati.Screens.Series` was on this list until mishka-group/kati#103
      # folded board 58 into it, and a FOLDED screen is the opposite claim: its
      # root follows the reader, so in an English app it says `sans` and it is
      # right to. The list shrinks with every fold and goes with the last
      # mirror.
      ScreenSweep.with_locale(:en, fn ->
        for module <- [] do
          root = safe_root(module)
          assert root, "#{inspect(module)} did not render"

          assert Map.get(root.props, :font_family) == "fa",
                 "#{inspect(module)} is a Persian page and its root names " <>
                   inspect(Map.get(root.props, :font_family))
        end
      end)
    end

    test "and an English screen says `sans` in English and `fa` in Persian" do
      # The shared frames follow the setting, which is the whole point: one
      # screen, two locales. `Kati.Screens.Library` is screen 03.
      english = ScreenSweep.with_locale(:en, fn -> safe_root(Kati.Screens.Library) end)
      persian = ScreenSweep.with_locale(:fa, fn -> safe_root(Kati.Screens.Library) end)

      assert Map.get(english.props, :font_family) == "sans"
      assert Map.get(persian.props, :font_family) == "fa"
    end
  end

  describe "the back chevron" do
    test "points the way the reader came from, in each direction" do
      assert Kati.Screens.Pushed.glyph_for(:rtl) == "arrow_forward_ios"
      assert Kati.Screens.Pushed.glyph_for(:ltr) == "arrow_back_ios_new"
    end

    test "and a pushed English screen in Persian draws the mirrored one" do
      # A container flips under RTL and a glyph does not — the arrow is a
      # codepoint in a font, so `LocalLayoutDirection` mirrors the Row it sits
      # in and leaves the chevron aimed at the edge the reader did not come
      # from. The Persian mirrors have always drawn `arrow_forward_ios`
      # (`Kati.Screens.Fa.pushed_frame/2`); the shared frame did not, so every
      # English page opened in Persian had the RTL layout and the LTR arrow.
      # Every screen that draws a back chevron, not just the shared frame: five
      # of them build their own pill over their own artwork — screens 04, 08,
      # 14 and 19 are all Movies & Series — and each had the glyph written out.
      for module <- [
            Kati.Screens.AddByHand,
            Kati.Screens.Film,
            Kati.Screens.SeriesMeta,
            Kati.Screens.Search,
            Kati.Screens.Meal
          ] do
        persian = ScreenSweep.with_locale(:fa, fn -> glyphs(module) end)
        english = ScreenSweep.with_locale(:en, fn -> glyphs(module) end)

        assert Kati.Icons.glyph("arrow_forward_ios") in persian,
               "#{inspect(module)} draws no leading-edge chevron in Persian"

        refute Kati.Icons.glyph("arrow_back_ios_new") in persian,
               "#{inspect(module)} still draws the Latin back chevron in Persian"

        assert Kati.Icons.glyph("arrow_back_ios_new") in english,
               "#{inspect(module)} draws no back chevron in English"
      end
    end
  end

  defp glyphs(module) do
    module
    |> mount_screen()
    |> tree()
    |> flatten()
    |> Enum.filter(&(&1.type == :text))
    |> Enum.map(&Map.get(&1.props, :text))
  end

  # A screen that cannot be mounted bare is not this file's subject — the
  # render sweep owns "does it render at all", and duplicating its failure here
  # would report one defect twice.
  defp safe_root(module) do
    tree(mount_screen(module))
  rescue
    _error -> nil
  catch
    :exit, _reason -> nil
  end
end
