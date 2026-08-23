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
  # Sorted, because the assertion below subtracts one sorted list from another.
  #
  # The two notification screens joined for the reason `Kati.Screens.Gallery`'s
  # undrawn list gives: the 127 drawings hold the lock screen showing a Kati
  # notification and the release watcher's loudness settings and nothing
  # between them, and #26 is a design ticket that names components rather than
  # supplying a frame. Both are built from those components and each says so.
  @undesigned [
    Kati.Screens.Backup,
    Kati.Screens.Gallery,
    Kati.Screens.InboxNotifications,
    Kati.Screens.NotificationsHelp,
    Kati.Screens.Sync
  ]

  # Screens 55-62 are the Persian mirrors and hold their Persian copy literally,
  # so only the writing direction actually changes with the locale. Each screen
  # is still rendered in the locale its drawing is written in, because a screen
  # that starts reading `Kati.Locale` should be read the way a user reads it.
  @fa_screens ~w(55 56 57 58 59 60 61 62 69 72 76 79 82 85 90 97 103 108 115)

  # How many of the drawings' literals may rest on `:squashed`, the loosest
  # tier. Today: 7, all of them rating rows the drawing writes as one run of
  # `★` and the app draws as separate glyph nodes. Raising this bound admits
  # more copy that is only checked with its spacing thrown away, which is a
  # decision rather than a fix.
  @squashed_budget 20

  # The floor above is 5 because a frame that yields fewer than five strings is
  # almost always the extractor having matched nothing. One drawing genuinely
  # holds fewer, and it is the one screen in the app that is *supposed* to be
  # nearly wordless: 65, the launch screen, which is a mark, a wordmark in two
  # scripts and a byline. Its floor is its exact count, so a literal going
  # missing from it still fails here — the exemption lowers the bar to what the
  # frame has, it does not remove it.
  @sparse %{"65" => 4}

  # The same screen, for the same reason, against the symbol assertion below.
  # 65 is a mark, a wordmark and a byline on a paper ground; it draws no
  # Material Symbol because a launch screen has no controls to put one on. It
  # is listed rather than the assertion softened, so every other drawing still
  # has to yield at least one.
  @symbolless ["65"]

  describe "the registry" do
    test "every drawing has a screen, and every screen but the gallery has a drawing" do
      # Rebuilt from three independent sources — the files on disk, the app's
      # registry, and the module list the other two sweeps discover — because
      # each has a silent empty answer, and a sweep over nothing passes.
      on_disk = DesignLiterals.numbers_on_disk()
      numbered = Enum.map(@registry, &elem(&1, 0))
      registered = Enum.map(@registry, &elem(&1, 2))

      assert length(on_disk) == 127,
             "expected 127 drawings under .scratch/design/screens, found #{length(on_disk)} — " <>
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

          assert length(design.text) >= Map.get(@sparse, number, 5),
                 "screen #{number}'s drawing yielded only #{length(design.text)} literals " <>
                   "(#{inspect(design.text)}) — the frame is 13KB of markup, so this is the " <>
                   "extractor failing, not a sparse screen"

          assert design.icons != [] or number in @symbolless,
                 "screen #{number}'s drawing yielded no Material Symbols"

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
      #
      # Raised to 10 for screen 80's connected ListenBrainz row. Same shape of
      # decision and the same kind of value: the account name and the listen
      # count come from a provider Kati has no client for yet, the row is
      # unreachable in a test because `Kati.SecureStore` is empty, and the
      # pattern states both branches of what the row can say.
      #
      # Raised again to 13 for screen 80's two cache figures and screen 94's
      # flag. The cache pair are device values in the plainest sense — a file
      # size and the age of a row. The flag is a different case and is the only
      # entry here that exists because the DRAWING is wrong: it pairs Cambodia's
      # flag with the Netherlands, and the app derives the emoji from the
      # country code, so reproducing the slip would mean shipping a wrong flag
      # to keep this sweep quiet.
      #
      # Raised to 14 for screen 111's `Today` row, which prints the device's own
      # clock. Same category as screens 01, 02 and 09's date lines and pinned
      # the same way — the pattern carries today's day of the month, so a sheet
      # that hardcoded 16 August would fail on every other day.
      #
      # Raised to 18 for screen 115's direction note, which is the second entry
      # of the flag's kind rather than the clock's: the board's sentence says
      # today's column is on the right and the board's own bars put it on the
      # left. Its pattern insists on the corrected word, so the entry checks
      # something rather than merely excusing it.
      assert length(device_values()) <= 18,
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
      {"80", "connected as ines.k · 412 listens",
       "the account name and the listen count come from ListenBrainz, and Kati has no " <>
         "client for it yet. The row's contract is the alternation: what the provider " <>
         "supplies when a token is present, or what the provider is FOR when none is. In a " <>
         "test it is always the second branch, because `Kati.SecureStore` is empty. See " <>
         "`Kati.Screens.DataSources.connected_line/1` for the branch this cannot reach",
       ~r/^(connected as \p{L}[\p{L}.]* · \d+ listens|scrobbles, listening history|pairing — expanded)$/u},
      {"80", "34 mb cached",
       "the row reports this database file's own size, which is the question it exists to " <>
         "answer — how much of the phone is this using. The drawing froze one device's " <>
         "figure; the pattern is the row's contract, a whole number of megabytes or the " <>
         "sentence a cache with nothing in it says", ~r/^(\d+ mb cached|nothing cached yet)$/u},
      {"80", "oldest entry 2 months",
       "the age of the oldest cache row, read off `fetched_at`. Same shape as above: the " <>
         "drawing froze one device's answer, and the alternation is what the row can say — " <>
         "an age in the drawing's own units, or that there is nothing to refresh",
       ~r/^(oldest entry (today|\d+ (day|days|month|months))|nothing to refresh)$/u},
      {"94", "🇰🇭",
       "the drawing pairs Cambodia's flag with the Netherlands. `Kati.Services.flag/1` " <>
         "derives the emoji from the ISO country code, so the row draws the Dutch flag and " <>
         "cannot draw the wrong one for any country — reproducing the slip to satisfy this " <>
         "sweep would be shipping a wrong flag to keep a test quiet", ~r/^🇳🇱$/u},
      # 115's direction note. Same shape as 94's flag directly above: the board
      # says *…و ستون امروز در سمت راست است* — today's column is on the right —
      # and its own bars put the ink one at the left, because
      # `Kati.Screens.Weight.bars/0` returns them oldest-first and an `rtl` row
      # lays the first child out at the right edge. `Kati.Screens.HealthFa`'s
      # moduledoc carries the full argument. The pattern insists on چپ rather
      # than accepting either word, so a revert to the board's راست fails here.
      {"115",
       "نمودار از راست به چپ خوانده می‌شود و ستون امروز در سمت راست است. " <>
         "اعداد وزن در dm mono با ارقام فارسی و جداکننده اعشار",
       "the board's own chart contradicts this sentence: the ink bar is the last child of " <>
         "an `rtl` row and lands at the left, and the axis prints امروز under it. A note " <>
         "pointing at the wrong end of the chart is wrong to everyone who reads the screen, " <>
         "where the DM Mono clause in the same sentence is a claim about a font subset that " <>
         "no reader can check — so that half is reproduced and this half is corrected",
       ~r/^نمودار از راست به چپ .+ ستون امروز در سمت چپ است\./u},
      {"111", "16 august, 07:42",
       "the sheet's `Today` row is `Kati.Screens.LogWeight.taken_line/0`, which formats " <>
         "`Kati.Time.now/0`. The drawing froze one device's minute; what the row promises is " <>
         "the day and the time it is being logged at", ~r/^#{day} \p{L}+, \d{2}:\d{2}$/u},
      # Screen 82's three, the Persian mirror of screen 80's. Same values, same
      # reasons: a pairing code for a provider Kati has no client for, the
      # database file's own size, and the age of its oldest row.
      {"82", "۴kq9۲",
       "the Persian mirror of 80's pairing code, which is stated because nothing in Kati " <>
         "talks to ListenBrainz yet", ~r/^\p{N}?[\p{L}\p{N}]+$/u},
      {"82", "۳۴ مگابایت",
       "the database file's own size, in Persian digits — the mirror of 80's `34 mb cached`",
       ~r/^(\p{N}+ مگابایت|هنوز چیزی ذخیره نشده)$/u},
      {"82", "۲ ماه قدیمی‌ترین",
       "the age of the oldest cache row, in Persian — the mirror of 80's `oldest entry 2 months`",
       ~r/^(.*قدیمی‌ترین|چیزی برای تازه‌سازی نیست)$/u},
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
