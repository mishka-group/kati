Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.LocaleActivateTest do
  @moduledoc """
  Every screen that resolves the theme into its process resolves the locale too.

  ## Why this is a test and not a convention

  `Mob.Theme.set/1` and `Gettext.put_locale/2` both snapshot into the CALLING
  process. A screen is its own process, so a stored locale that nobody
  activated is a preference the screen cannot see — and the failure is silent
  in the worst way available: Gettext falls back to the **msgid**, and the msgid
  is the English copy. A Persian reader gets a correct-looking English page.

  There is no marker, no log and no crash. That is the same class of defect
  `Kati.PersianFontTest` was written for — Persian set in a face that renders,
  in somebody else's typeface — and it is caught the same way, by asserting the
  rule rather than by remembering it.

  ## Why the pairing rather than one global write

  `Application.put_env(:gettext, :default_locale, …)` would be one line instead
  of fifty-one. `Kati.Runtime` is the only module in this app allowed to write
  application environment, and a locale is not a runtime config key — but the
  sharper reason is the test suite: a global default means a test that renders
  one screen in `:fa` has changed the locale for every other test in the run,
  and `Kati.ScreenSweep.with_locale/2` exists precisely so that cannot happen.

  ## What it does not assert

  That the copy is translated. Nothing is, yet — `priv/gettext` has a `fa`
  catalogue and the screens have no call sites, which is
  [mishka-group/kati#103](https://github.com/mishka-group/kati/issues/103). This
  file asserts the plumbing is live before the copy arrives, so the fold cannot
  land on a locale nobody set.
  """
  use ExUnit.Case, async: true

  @lib Path.expand("../../lib", __DIR__)

  describe "the pairing" do
    test "every Kati.Theme.activate/0 in a mount is followed by Kati.Locale.activate/0" do
      unpaired =
        @lib
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(&unpaired_in/1)

      assert unpaired == [],
             """
             these call sites snapshot the theme into the process and leave the
             locale on whatever it happened to be. Gettext then falls back to
             the msgid, which is the English copy — so the page renders, in the
             wrong language, and nothing says so:

             #{Enum.map_join(unpaired, "\n", fn {file, line} -> "  #{file}:#{line}" end)}

             Add `Kati.Locale.activate()` on the next line. The one deliberate
             exception is `Kati.Screens.Settings.put_choice/1`, which is a theme
             WRITE rather than a mount and is listed below.
             """
    end

    test "and the exception is exactly one, named" do
      # `put_choice/1` re-snapshots the palette after storing a theme choice.
      # It is not a mount and has no locale half — pairing it would activate a
      # locale nobody changed, which is noise rather than safety.
      sites =
        @lib
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(&theme_sites/1)

      {paired, bare} = Enum.split_with(sites, fn {file, line} -> paired?(file, line) end)

      assert length(paired) == 48,
             "expected 51 paired activations, found #{length(paired)} — " <>
               "a screen was added or removed and this number moves with it"

      assert Enum.map(bare, &elem(&1, 0)) == ["lib/kati/screens/settings.ex"]
    end
  end

  defp unpaired_in(path) do
    path
    |> theme_sites()
    |> Enum.reject(fn {file, line} -> paired?(file, line) end)
    |> Enum.reject(fn {file, _line} -> file == "lib/kati/screens/settings.ex" end)
  end

  defp theme_sites(path) do
    relative = Path.relative_to(path, Path.dirname(@lib))

    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _n} ->
      String.trim(line) =~ ~r/^:?o?k? ?=? ?Kati\.Theme\.activate\(\)$/
    end)
    |> Enum.map(fn {_line, n} -> {relative, n} end)
  end

  defp paired?(file, line) do
    Path.join(Path.dirname(@lib), file)
    |> File.read!()
    |> String.split("\n")
    |> Enum.at(line)
    |> to_string()
    |> String.trim()
    |> Kernel.==("Kati.Locale.activate()")
  end
end
