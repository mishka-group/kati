Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenDesignLiteralTest do
  @moduledoc """
  Every word and every icon each drawing contains, found in the screen's
  rendered tree.

  ## The blind spot this closes

  A screen is verified by capturing a device frame and comparing it with
  `.scratch/design/screens/NN.html`. A captured frame shows **only what fits on
  the screen**, so the bottom of a long screen has never been compared with
  anything. Ten screens are long enough for that to matter — 25, 36, 37, 38, 39,
  40, 47, 48, 49, 50 — and the failure mode is quiet: a section the drawing
  shows is simply not built, every frame looks right, and nothing says so.

  This asks the question a screenshot cannot: is each literal the drawing draws
  **anywhere in the tree**, visible or not. Scroll position is irrelevant to a
  tree, so the last card of screen 48 is checked exactly as closely as the first.

  ## Why the tree and not the source file

  `bin/check_screen.py` already greps the screen's SOURCE for the drawing's
  literals, and that is a weaker question in two directions:

    * it fails on a refactor that is not a defect — moving a card into
      `Kati.UI` or a Mishka component takes the string out of the file the
      script was pointed at, and

    * it passes on a defect — a `defp` that builds the copy and is never called
      from `render/1` still contains the string. So does a comment quoting it.
      The tree contains only what was actually mounted.

  ## What it does not check

  Presence, not placement. A literal drawn in the wrong card, at the wrong
  size, in the wrong order or in the wrong colour passes here. That is the
  frame diff's job, and this is deliberately the half of the comparison a frame
  cannot do. `Kati.ScreenRenderSweepTest` owns "does it render at all";
  `Kati.ScreenTapSweepTest` owns "does every control do something".

  ## The allow-list

  Nine literals cannot be asserted directly, because the drawing froze a value
  the screen reads at runtime: seven from the device clock, and two — screens 24
  and 62's `Last backup` line — from the backup ledger
  `Kati.Screens.Settings.last_backup/0` keeps, which is empty in every test here.
  They are listed in `device_values/0` with the pattern that must stand in for
  each, and there is deliberately no way to add a bare exemption — an entry with
  no stand-in pattern would be an excuse, and `test/support/design_literals.exs`
  has no shape for one.

  That last point is why "just stop drawing the line" is not the cheap way out
  of a frozen value: a line the screen no longer renders can be exempted by
  nothing here, so deleting copy the drawing contains is a change this sweep
  refuses outright rather than one it merely records.

  Two staleness checks keep that list from rotting, and one that would be
  unsound is left out on purpose:

    * **dead entry** — the literal must still be one the drawing contains. If a
      drawing is re-exported, or the extractor changes, an entry for a line
      nobody draws any more fails.
    * **empty slot** — the stand-in pattern must still match something the
      screen renders. If Home stopped drawing a date line, the exemption would
      otherwise hide it.
    * **not asserted: "the literal now appears, so drop the entry".** For a
      clock-driven value that is unsound — Home really does render
      `Good evening` every evening, and `Sunday · 16 August` on the years 16
      August falls on a Sunday. Asserting it would make the suite fail by the
      hour. What replaces it is that each date pattern carries **today's**
      day-of-month, so a screen that hardcoded the drawing's frozen date would
      fail on every day but that one.
  """
  # `Mob.ScreenCase` for the same reason the other two sweeps use it: it opens
  # the DETS-backed `Mob.State` against a throwaway data dir, without which every
  # screen that reads a setting in `mount/3` crashes. `async: false` because the
  # locale these renders switch is global.
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.ScreenSweep

  # `Kati.Screens.Gallery` is the app's own number → module registry, the list
  # the owner navigates by and the one `.scratch/design/screens/NN.html` is named
  # after. Reading it here rather than keeping a second copy means a screen
  # cannot be renumbered in one place and checked in another.
  @registry Kati.Screens.Gallery.screens()

  # The three screens this sweep cannot cover, because no drawing exists to
  # compare them against. Sorted, because the assertion below subtracts one
  # sorted list from another and compares the remainder to this one.
  #
  #   * `Kati.Screens.Gallery` is scaffolding — "every screen in the app, in one
  #     list" — and was never drawn.
  #   * `Kati.Screens.Backup` and `Kati.Screens.Sync` are the two halves of #54.
  #     `.scratch/design/screens/` stops at 62 and none of the 62 is either of
  #     them; issue #25 asks for the drawings and they do not exist. Both are
  #     built in screen 24's idiom instead — every container is
  #     `Kati.UI.SettingsList`'s and every colour a `Kati.Theme.Palette` token —
  #     and each says so in its own moduledoc.
  #
  # An entry here buys **only** exemption from the literal comparison. Both
  # screens are still mounted and rendered by `Kati.ScreenRenderSweepTest`,
  # still tapped by `Kati.ScreenTapSweepTest`, and each has its own suite
  # (`Kati.ScreenSyncTest` and the backup screen's) asserting the copy this file
  # would otherwise have checked. Delete an entry the moment a drawing lands.
  @undesigned [Kati.Screens.Backup, Kati.Screens.Gallery, Kati.Screens.Sync]

  # Screens 55-62 are the Persian mirrors and hold their Persian copy literally,
  # so only the writing direction actually changes with the locale. Each screen
  # is still rendered in the locale its drawing is written in, because a screen
  # that starts reading `Kati.Locale` should be read the way a user reads it.
  @fa_screens ~w(55 56 57 58 59 60 61 62)

  # How many of the drawings' literals may rest on `:squashed`, the loosest
  # tier. Today: 7, all of them rating rows the drawing writes as one run of
  # `★` and the app draws as separate glyph nodes. Raising this bound admits
  # more copy that is only checked with its spacing thrown away, which is a
  # decision rather than a fix.
  @squashed_budget 20

  describe "the registry" do
    test "every drawing has a screen, and every screen but the gallery has a drawing" do
      # Rebuilt from three independent sources — the files on disk, the app's
      # registry, and the module list the other two sweeps discover — because
      # each has a silent empty answer, and a sweep over nothing passes.
      on_disk = DesignLiterals.numbers_on_disk()
      numbered = Enum.map(@registry, &elem(&1, 0))
      registered = Enum.map(@registry, &elem(&1, 2))

      assert length(on_disk) == 64,
             "expected 64 drawings under .scratch/design/screens, found #{length(on_disk)} — " <>
               "the directory is tracked, so an empty or short answer is a broken checkout, " <>
               "not a reason to check less"

      assert Enum.sort(numbered) == on_disk

      assert length(Enum.uniq(numbered)) == length(numbered),
             "a screen number is registered twice"

      assert Enum.all?(registered, &ScreenSweep.screen?/1),
             "the registry names modules that are not screens: " <>
               inspect(Enum.reject(registered, &ScreenSweep.screen?/1))

      assert Enum.sort(ScreenSweep.screens()) -- Enum.sort(registered) == @undesigned,
             "a screen exists that no drawing is checked against:\n" <>
               inspect((ScreenSweep.screens() -- registered) -- @undesigned)
    end

    test "an undrawn screen is still openable from the gallery" do
      # `@undesigned` buys exemption from the literal comparison. It must not
      # also buy invisibility.
      #
      # A screen with no drawing cannot go in `Kati.Screens.Gallery`'s numbered
      # registry — the assertion above is exactly what would fail, and
      # `bin/capture_all.py` would go looking for a frame that does not exist —
      # so the gallery keeps a second, unnumbered list for them. Without this
      # pin, "it has no drawing" would quietly become "it is on no page", which
      # is how `Kati.Screens.Backup` and `Kati.Screens.Sync` arrived: two
      # finished engines behind two screens, and nothing that opened either.
      #
      # The gallery itself is the one exemption, for the obvious reason.
      openable = MapSet.new(Kati.Screens.Gallery.undrawn(), &elem(&1, 2))
      expected = MapSet.delete(MapSet.new(@undesigned), Kati.Screens.Gallery)

      assert openable == expected,
             "the gallery's undrawn list and this file's @undesigned disagree about which " <>
               "screens have no drawing. Missing from the gallery: " <>
               inspect(MapSet.to_list(MapSet.difference(expected, openable))) <>
               "; listed there and not here: " <>
               inspect(MapSet.to_list(MapSet.difference(openable, expected)))

      assert Enum.all?(Kati.Screens.Gallery.undrawn(), fn {tag, _name, _module} ->
               is_atom(tag) and Atom.to_string(tag) =~ ~r/^[a-z_]+$/
             end),
             "a gallery tag is not lowercase ASCII; every tag in this app crosses into " <>
               "Kotlin and back and has to be readable in a log"
    end
  end

  describe "the drawings" do
    test "each one yields the copy and the symbols it visibly contains" do
      # The extraction is regex over HTML, and the way regex over HTML fails is
      # by matching nothing at all. A screen whose literals came back empty
      # would pass every other test in this file, so the counts are asserted
      # before anything is compared against them.
      counts =
        for {number, _label, _module, _kind} <- @registry do
          design = DesignLiterals.read!(number)

          assert DesignLiterals.caption_blocks(number) == 1,
                 "screen #{number}'s drawing has #{DesignLiterals.caption_blocks(number)} " <>
                   "`max-width:380px` blocks; the frame is split at the first, so a second " <>
                   "one earlier in the file would truncate the screen to nothing"

          assert length(design.text) >= 5,
                 "screen #{number}'s drawing yielded only #{length(design.text)} literals " <>
                   "(#{inspect(design.text)}) — the frame is 13KB of markup, so this is the " <>
                   "extractor failing, not a sparse screen"

          assert design.icons != [], "screen #{number}'s drawing yielded no Material Symbols"

          {length(design.text), length(design.icons)}
        end

      {text, icons} = Enum.unzip(counts)

      assert Enum.sum(text) >= 1500,
             "the 62 drawings yielded #{Enum.sum(text)} literals in total; they held 1575 " <>
               "when this was written and the files are fixed artefacts, so a large drop is " <>
               "the extractor, not the design"

      assert Enum.sum(icons) >= 500, "the 62 drawings yielded #{Enum.sum(icons)} symbols in total"
    end

    test "every symbol they draw is one the shipped font subset has" do
      # `Kati.Icons` is generated FROM these drawings, so a name here with no
      # glyph means the generator has not been re-run — and the on-device
      # symptom is an empty space, because `glyph!/1` raises but a screen that
      # never calls it just draws nothing.
      absent =
        for {number, _label, _module, _kind} <- @registry,
            name <- DesignLiterals.read!(number).icons,
            Kati.Icons.glyph(name) == nil,
            do: "  #{number} draws #{name}"

      assert absent == [],
             "these symbols are in a drawing but not in Kati's font subset; " <>
               "run `mix kati.gen.icons`:\n" <> Enum.join(absent, "\n")
    end
  end

  describe "the screens" do
    test "every literal its drawing contains is somewhere in the rendered tree" do
      unexplained =
        for screen <- render_all(),
            literal <- screen.design.text,
            DesignLiterals.locate(literal, screen.haystacks) == :missing,
            not exempt?(screen.number, literal),
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{inspect(literal)}"

      assert unexplained == [],
             "these lines are in the drawing and nowhere in the screen's tree — visible or " <>
               "not, so no scroll position explains them:\n" <> Enum.join(unexplained, "\n")
    end

    test "most of that is found inside one Text, not by joining nodes" do
      tiers =
        for screen <- render_all(),
            literal <- screen.design.text,
            do: DesignLiterals.locate(literal, screen.haystacks)

      squashed = Enum.count(tiers, &(&1 == :squashed))

      assert squashed <= @squashed_budget,
             "#{squashed} literals are only found once whitespace is thrown away, over a " <>
               "budget of #{@squashed_budget}. That tier exists for the rating rows the " <>
               "drawings write as `★★★★☆`; copy arriving there is copy whose spacing nothing " <>
               "checks"

      assert Enum.count(tiers, &(&1 == :node)) >= div(length(tiers) * 95, 100),
             "only #{Enum.count(tiers, &(&1 == :node))} of #{length(tiers)} literals are found " <>
               "inside a single Text; the rest are being matched across node boundaries, which " <>
               "is the loose reading"
    end

    test "every Material Symbol its drawing draws is somewhere in the rendered tree" do
      missing =
        for screen <- render_all(),
            glyphs = DesignLiterals.rendered_glyphs(screen.tree),
            name <- screen.design.icons,
            glyph = Kati.Icons.glyph(name),
            glyph != nil,
            not MapSet.member?(glyphs, glyph),
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{name}"

      assert missing == [],
             "these symbols are in the drawing and nowhere in the screen's tree:\n" <>
               Enum.join(missing, "\n")
    end

    test "no node carries copy in a prop the harvester does not read" do
      # The harvester reads `Kati.DesignLiterals.content_props/0`. If a screen
      # starts putting copy in a prop outside that list — a `TextField`'s
      # `placeholder`, a `Button`'s `label` — every literal in it reads as
      # absent, and the fix is to teach the harvester, not to allow-list the
      # words. This fails the moment such a prop appears, whatever its name.
      known = MapSet.new(DesignLiterals.content_props() ++ DesignLiterals.styling_props())

      unknown =
        for screen <- render_all(),
            key <- DesignLiterals.string_prop_keys(screen.tree),
            not MapSet.member?(known, key),
            reduce: %{} do
          seen -> Map.put_new(seen, key, "#{screen.number} #{inspect(screen.module)}")
        end

      unknown = Enum.map(unknown, fn {key, where} -> "  #{key} (first seen on #{where})" end)

      assert unknown == [],
             "these props hold a string and are neither known copy nor known styling. If one " <>
               "carries words a user reads, add it to `content_props/0` — until then this " <>
               "sweep is blind to it:\n" <> Enum.join(unknown, "\n")
    end
  end

  describe "the allow-list" do
    test "no entry is dead: each literal is still one its drawing contains" do
      refute Enum.empty?(device_values()),
             "the allow-list is empty; delete it and its three tests rather than keeping a " <>
               "mechanism nothing uses"

      dead =
        for {number, literal, _reason, _pattern} <- device_values(),
            literal not in DesignLiterals.read!(number).text,
            do: "  #{number} #{inspect(literal)}"

      assert dead == [],
             "these are exempted from a check that no longer asks about them — the drawing " <>
               "does not contain the line. Remove the entry:\n" <> Enum.join(dead, "\n")
    end

    test "no entry hides an empty slot: each stand-in still matches what the screen draws" do
      by_number = Map.new(render_all(), &{&1.number, &1.texts})

      unmatched =
        for {number, literal, reason, pattern} <- device_values(),
            not Enum.any?(by_number[number], &Regex.match?(pattern, &1)),
            do: "  #{number} #{inspect(literal)} — #{reason}\n      #{inspect(pattern)}"

      assert unmatched == [],
             "the drawing's line is exempted because the screen supplies the value itself, and " <>
               "now the screen supplies nothing that looks like it. The slot is empty, or the " <>
               "value stopped following the device clock:\n" <> Enum.join(unmatched, "\n")
    end

    test "the list stays small enough to read" do
      # Raised from 7 to 9 for screens 24 and 62's `Last backup` line, and the
      # decision is the one this assertion asks for: the drawing's `14 Aug` had
      # nothing behind it, and the alternatives were a ledger the screen reads
      # (this) or deleting the second line entirely — which this sweep has no
      # exemption shape for, because every entry needs a pattern the screen
      # still draws. Two literals move from "checked against a frozen date" to
      # "checked against a two-state contract", which is less than an exact
      # string and more than nothing.
      assert length(device_values()) <= 9,
             "the allow-list has grown to #{length(device_values())}. Each entry is a literal " <>
               "this sweep cannot check; growing the list is a decision to check less, and " <>
               "should be made deliberately by raising this bound"
    end
  end

  # ── The allow-list ──────────────────────────────────────────────────────────

  # `{screen number, the drawing's literal, why it cannot be asserted, what must
  # stand in for it}`. The pattern is matched against the screen's rendered
  # strings; there is no entry shape without one.
  #
  # Built rather than declared because most of the patterns carry today's day of
  # the month: the drawings froze one date, the screens format the device's, and
  # pinning the day is what stops a screen that hardcoded the drawing's date
  # from passing here.
  #
  # The two backup entries (24 and 62) are the exception and say so in their own
  # reason: their value follows a *stored* fact rather than the clock, and the
  # store is empty in every test, so the day cannot be pinned and the pattern
  # states both branches instead.
  #
  # The Persian half carries today's **Shamsi** day, because that is the number
  # those screens print, and two details of its patterns are load-bearing:
  # `\x{200C}` is inside every word class (four of the seven Persian weekday
  # names contain a zero-width non-joiner, which is `\p{Cf}` and not `\p{L}`),
  # and `\p{N}+` rather than `\d+` (the digits are U+06F0-U+06F9).
  defp device_values do
    day = Integer.to_string(Kati.Time.now().day)
    {_year, _month, shamsi_day} = Kati.Calendar.Shamsi.from_gregorian(Kati.Time.today())
    fa_day = Kati.Calendar.Shamsi.fa(shamsi_day)
    word = "[\\p{L}\\x{200C}]+"

    [
      {"01", "sunday · 16 august",
       "Home's eyebrow is `Kati.Screens.Home.today/0`, which formats `Kati.Time.now/0`",
       ~r/^\p{L}+ · #{day} \p{L}+$/u},
      {"01", "good evening",
       "the greeting is picked from the device clock's hour by the same function. Which of " <>
         "the three it is belongs to `Kati.Screens.Home.today/0`; restating its thresholds " <>
         "here would only make this fail when the product changed its mind about evening",
       ~r/^good (morning|afternoon|evening)$/},
      {"02", "sunday 16 august · 5 items",
       "Schedule's subtitle is the selected day, which starts on the device's today",
       ~r/^\p{L}+ #{day} \p{L}+ · \d+ items$/u},
      {"09", "thu 20 aug", "the heavy day's header is the device's today, in the same short form",
       ~r/^\p{L}{3} #{day} \p{L}{3}$/u},
      {"55", "یکشنبه ۲۵ مرداد ۱۴۰۵",
       "the Persian Home's date line is `Kati.Screens.HomeFa.moment/0`, which is " <>
         "`Kati.Calendar.Shamsi.format/2` at `:long` over `Kati.Time.today/0` — the mirror " <>
         "of 01's own exemption, in the calendar the screen is drawn in",
       ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"55", "عصر بخیر",
       "the greeting is picked from the device clock's hour by that same function, on " <>
         "`Kati.Screens.Home.today/0`'s thresholds. Which of the three it is belongs there; " <>
         "restating the hours here would only make this fail when the product changed its " <>
         "mind about evening", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"56", "یکشنبه ۲۵ مرداد · ۵ مورد",
       "the Persian Schedule's subtitle is the selected day and the number of rows on it, " <>
         "and the selected day starts on the device's today",
       ~r/^#{word} #{fa_day} #{word} · \p{N}+ مورد$/u},
      {"24", "last backup 14 aug",
       "the drawing froze a date; the Export row now reports " <>
         "`Kati.Screens.Settings.last_backup/0`, which is `nil` until something completes a " <>
         "Save As. The alternation is the screen's whole contract at this slot — a date in " <>
         "the drawing's own day-and-short-month form, or the absence — and in a test it is " <>
         "always the second branch, because `Mob.ScreenCase` starts `Mob.State` empty. See " <>
         "`Kati.SettingsBackupLineTest` for the branch this cannot reach",
       ~r/^(last backup \d{1,2} \p{L}{3}|never backed up)$/u},
      {"62", "آخرین پشتیبان ۱۴ مرداد",
       "the Persian mirror of 24's Export row, on the same reading through " <>
         "`Kati.Screens.Settings.last_backup/0`, with the date in Shamsi because that is the " <>
         "calendar this screen is drawn in",
       ~r/^(آخرین پشتیبان \p{N}+ #{word}|هنوز پشتیبانی گرفته نشده)$/u}
    ]
  end

  defp exempt?(number, literal) do
    Enum.any?(device_values(), fn {n, l, _reason, _pattern} -> n == number and l == literal end)
  end

  # ── Rendering ───────────────────────────────────────────────────────────────

  # Every screen, rendered once, with its drawing beside it. A screen that fails
  # to render stops this file with one failure rather than forty — that failure
  # belongs to `Kati.ScreenRenderSweepTest`, and repeating its output here would
  # bury the findings this file is for.
  #
  # Memoised in `:persistent_term` for the same reason
  # `Kati.ScreenSweep.drawn_taps/1` is: six tests here read the same 62 trees,
  # each ExUnit test runs in its own process, and `Mob.ScreenCase` restarts
  # `Mob.State` around each one — so a cache in the process dictionary or in ETS
  # would die between the tests that share the work. Rendering once also pins
  # the clock, which three of the allow-list's patterns are read against.
  defp render_all do
    key = {__MODULE__, :render_all}

    case :persistent_term.get(key, :miss) do
      :miss ->
        screens = do_render_all()
        :persistent_term.put(key, screens)
        screens

      screens ->
        screens
    end
  end

  # One locale switch per screen rather than per literal: `Kati.Locale` lives in
  # `Mob.State`, which is DETS, so each switch is a `GenServer.call` and a disk
  # write (see `Kati.ScreenSweep.with_locale/2`).
  defp do_render_all do
    for {number, _label, module, _kind} <- @registry do
      locale = if number in @fa_screens, do: :fa, else: :en

      case ScreenSweep.with_locale(locale, fn -> ScreenSweep.render(module) end) do
        {:ok, _socket, tree} ->
          texts = DesignLiterals.rendered(tree)

          %{
            number: number,
            module: module,
            tree: tree,
            texts: texts,
            haystacks: DesignLiterals.haystacks(texts),
            design: DesignLiterals.read!(number)
          }

        {:error, message} ->
          flunk("screen #{number} (#{inspect(module)}) does not render:\n  #{message}")
      end
    end
  end
end
