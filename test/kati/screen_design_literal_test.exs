Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenDesignLiteralTest do
  @moduledoc """
  Every word and every icon each drawing contains, found in the screen's
  rendered tree.

  ## The blind spot this closes

  A screen used to be verified by photographing a device frame and comparing it
  with `test/design/screens/NN.html`. A captured frame shows **only what fits on
  the screen**, so the bottom of a long screen was never compared with
  anything. Ten screens are long enough for that to matter — 25, 36, 37, 38, 39,
  40, 47, 48, 49, 50 — and the failure mode is quiet: a section the drawing
  shows is simply not built, every frame looks right, and nothing says so.

  This asks the question a screenshot cannot: is each literal the drawing draws
  **anywhere in the tree**, visible or not. Scroll position is irrelevant to a
  tree, so the last card of screen 48 is checked exactly as closely as the first.
  The capture tooling has since been deleted — `docs/DESIGN-ASSETS.md` carries
  that argument — which does not change what this file checks, only how much of
  the comparison rests on it.

  ## Why the tree and not the source file

  The cheap version of this check greps the screen's SOURCE for the drawing's
  literals — a Python script under `bin/` did exactly that until this file
  replaced it, and `docs/DESIGN-ASSETS.md` records the swap. Grepping the source
  is a weaker question in two directions:

    * it fails on a refactor that is not a defect — moving a card into
      `Kati.UI` or a Mishka component takes the string out of the file the
      grep was pointed at, and

    * it passes on a defect — a `defp` that builds the copy and is never called
      from `render/1` still contains the string. So does a comment quoting it.
      The tree contains only what was actually mounted.

  ## Six screens have two drawings, and this file owns one of them

  A screen used to reach its drawing's state just by being mounted: every
  screen that could come up empty answered an empty store with its Sample
  module, so a bare mount drew the board whatever the database held.

  #91 ended that for the four roots. On a fresh install `Kati.Screens.Library`
  now draws screen 27's *No titles yet* card, `Kati.Screens.Home` draws screen
  139 whole, and `Kati.Screens.Stats` and `Kati.Screens.Calendar` each draw a
  card built from the boards that word their emptiness — because nine invented
  films on a phone that has tracked nothing is the app lying about the one thing
  it exists to hold. Each screen's moduledoc carries that argument.

  Screens 28 and 55 joined them on the round after. They are screen 01 in dark
  and screen 01 in Persian, and their whole reason to exist is to be the same
  page as 01 in another colourway and another script — so the moment 01's bands
  became reads, a dark Home still announcing *3 new episodes are waiting* and a
  Persian Home still drawing ۳ قسمت تازه were the two pages disagreeing with the
  page they mirror about which half of themselves is real. 55 is the sharper of
  the two: `Kati.Onboarding.shell_root/1` answers it for `:fa`, so it is the
  page a Persian user lands on after their first run.

  So those six have **two** drawings, and the one this file is named after is
  the one they draw *once there is something to draw*. `drawn_state/0` is how
  they are put in it; the empty half belongs to `Kati.ScreenEmptyDatabaseTest`,
  which is the only file here that can make the database empty for certain.

  ## What it does not check

  Presence, not placement. A literal drawn in the wrong card, at the wrong
  size, in the wrong order or in the wrong colour passes here. That was the
  frame diff's half, and this is deliberately the half of the comparison a
  frame cannot do. With the diffing scripts gone, the only placement claim
  anything still makes against a drawing is `Kati.ScreenTitleSubtitleTest`'s —
  the size, family and gap of the line under a 28pt title, on the screens that
  head themselves that way — so the rest of layout is read by eye or not at
  all, which is an argument for widening that test rather than for loosening
  this one. `Kati.ScreenRenderSweepTest` owns "does it render at all";
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
  # the owner navigates by and the one `test/design/screens/NN.html` is named
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
  #     `test/design/screens/` stops at 62 and none of the 62 is either of
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
  #
  # `ListDetail` joined for a third reason, and it is the one this list is for:
  # board 12 draws a `chevron_right` on every list row and never drew what it
  # opens. MOVIES-AND-TV.md #106 was first closed by removing the chevrons and
  # filing the gap ([#99](https://github.com/mishka-group/kati/issues/99)); the
  # owner asked for the feature instead. The screen borrows every object it
  # draws from a board that does exist — 12's header, the library's poster row,
  # 146's destructive pill — and its own moduledoc lists which, so the day 12's
  # detail board lands there is one file to change and no resource to move.
  @undesigned [
    # Boards 330-333 and 335 draw the two Lists screens, but each is a STATE
    # CATALOGUE — 330 stacks four states in one frame, 333 is 1249pt of them in
    # an 806pt sheet — so neither can be compared literal-for-literal against a
    # render until a specimen screen per board exists, the way 155 is 154's.
    Kati.Screens.AddToList,
    Kati.Screens.AddToListFa,
    # Board 301, the Persian country sheet. Its frame is drawn beside three
    # notes about what screens 94 and 97 got wrong rather than as a numbered
    # artboard, so it stays in `test/design/incoming/` and the screen is not
    # compared against a file.
    # Board 267 draws the page AND its confirmation in one frame, plus an edit
    # to screen 24's row and a note about what unticks. Same treatment as 330
    # and 333: a state catalogue needs a specimen screen before the literal
    # sweep can hold it. `Kati.ScreenClearHistoryTest` carries the copy, both
    # states, the four counts and the promise about what stays.
    Kati.Screens.ClearHistory,
    Kati.Screens.CountryPickerFa,
    Kati.Screens.Gallery,
    Kati.Screens.InboxNotifications,
    Kati.Screens.ListDetail,
    Kati.Screens.ListDetailFa,
    # Board 328 draws it, and 328 is a state catalogue too: the summary row in
    # both locales, the screen behind it, and the defect it replaces, all in one
    # frame. Same treatment as 330 and 333.
    Kati.Screens.MoreSources,
    Kati.Screens.NotificationsHelp,
    # Board 114 is a states board like the rest of this wave, and this screen is
    # what finally sits behind three surfaces that have drawn *tap to see why*
    # with nothing under it since they were written.
    Kati.Screens.RetiredReason,
    # Boards 252 and 302 are two takes on one service, and both draw sections
    # this device cannot answer — a cost per watched hour, hours watched, and a
    # person the cost is split with. Board 252 argues the first two against
    # itself ("a watch records that an episode was watched, not for how long"),
    # and Kati has no people table for the third. The page drops those groups
    # rather than drawing them dead, so it renders less than either board and
    # cannot be compared literal-for-literal against one.
    # `Kati.ScreenServiceTest` holds what it does draw.
    Kati.Screens.Service,
    Kati.Screens.Sync
  ]

  # Screens 55-62 are the Persian mirrors and hold their Persian copy literally,
  # so only the writing direction actually changes with the locale. Each screen
  # is still rendered in the locale its drawing is written in, because a screen
  # that starts reading `Kati.Locale` should be read the way a user reads it.
  @fa_screens ~w(55 56 57 58 59 60 61 62 69 72 76 79 82 85 90 97 103 108 115 132 137 176)

  # How many of the drawings' literals may rest on `:squashed`, the loosest
  # tier. Today: 21, and twenty of them are rating rows the drawing writes as
  # one run of `★` and the app draws as separate glyph nodes. Raising this
  # bound admits more copy that is only checked with its spacing thrown away,
  # which is a decision rather than a fix.
  #
  # 20 → 21 on 5 September for board 180's `5★`, which is board 33's `5★` on a
  # different noun: the album rating sheet is screen 33's film sheet with an
  # album behind it, and its star run is drawn the same way and read the same
  # way. The failure names its offenders now (see the test below), so the next
  # rise can be judged on the line rather than on the arithmetic.
  @squashed_budget 21

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

  # Symbols a screen deliberately does not draw, because the row that carried
  # them is gone and its absence is the decision.
  #
  # `auto_mode` is screen 49's Auto-switch row, retired under #71: it promised
  # *Travel week when a trip is on the calendar* and there is no trip in Kati —
  # no travel entity, no location state. `Kati.Meals.MealPlan`'s moduledoc has
  # the argument. The row is replaced by a scheduled switch, which is the same
  # intent expressed in a date the schema actually holds.
  #
  # `bookmark` and `inventory_2` are board 12's *Wishlist* and *Owned on disc*
  # rows, retired under #106 with the two lines they carried: both are
  # assertions a reader makes about a title and no column holds, and they were
  # drawn frozen beside two rows that CAN be counted. See
  # `Kati.DesignLiterals.retired_lines/0`, which holds the words.
  @retired_symbols [{"49", "auto_mode"}, {"12", "bookmark"}, {"12", "inventory_2"}]

  # Lines a screen deliberately does not draw, because what carried them is
  # gone and its absence is the decision. `@retired_symbols`' twin, and the
  # first entries are the reason it exists.
  #
  # Screen 80's pairing card printed a six-character code, the address
  # `listenbrainz.org/link`, and `Expires in 9:48`. All three were invented
  # (MOVIES-AND-TV.md #71). Kati talks to none of the three providers it
  # offers, so `pairing_code/1` derived the code from the provider id; the
  # address was ListenBrainz's under every one of them, so a Hardcover reader
  # was sent to somebody else's site; and the clock never started, because
  # nothing had. A reader who took the card at face value went to a URL that
  # was not theirs and typed a code nobody had issued.
  #
  # The card now names the site the token actually comes from — `:site` on
  # `Kati.Sources`, one per provider — says what connecting would bring, and
  # says Kati cannot complete it yet. The slot is still there:
  # `Kati.Screens.DataSources.ready?/1` answers `false` for all three today
  # and the code comes back from the provider the day one answers `true`.
  #
  # 82 is 80 in Persian and lost the same three lines for the same reason. en
  # and fa are one app.

  # Symbols a screen draws on a branch no test can reach. Different from
  # `@retired_symbols` in the way that matters: the row is not gone, it is
  # simply not the branch an empty install takes, so the entry is a statement
  # that the symbol is asserted SOMEWHERE ELSE rather than that it is unused.
  #
  # `cloud_done` is screen 128's status card in its has-been-backed-up state.
  # `Kati.Screens.Backup.status_card/0` reads
  # `Kati.Screens.Settings.last_backup/0`, which is `nil` until a Save As
  # completes, and `Mob.State` is empty in every render this file takes — so
  # every render here draws `cloud_off` and the word `Never`. The moduledoc on
  # `Kati.Screens.Backup` argues at length that this is the correct resting
  # state of a fresh install and not a gap to be filled with the board's frozen
  # date.
  #
  # The branch is covered by `Kati.ScreenBackupTest`'s "the status card once a
  # backup exists", which seeds the ledger, renders the real screen and asserts
  # `cloud_done`, the date and the size are all on the tree — and that
  # `cloud_off` and `Never` are not. Delete this entry if that test goes.
  #
  # `check` is boards 163 and 166's ticked tile, in both scripts. Step 5 of the
  # first run opened with `The Long Hollow` — one of the board's four INVENTED
  # titles — already selected, because the board draws that tile ticked and the
  # tick was read as a default rather than as the drawing showing what a chosen
  # tile looks like. A reader who pressed **Finish setup** without choosing was
  # handed a film they had never heard of, and screen 139 — the state the app is
  # in when it holds nothing — was unreachable by the path most people walk.
  # That is MOVIES-AND-TV.md #91's own sentence, and
  # `FirstRunTest.assertNothingInvented/1` on the device is the assertion
  # written for it.
  #
  # Nothing is picked on a bare mount now, so no tile carries the tick.
  # `Kati.FirstRunTest`'s "finishing puts the chosen title on the shelf" taps a
  # tile and asserts what follows, in both locales — delete these two entries
  # if that test goes.
  @unreachable_symbols [{"128", "cloud_done"}, {"163", "check"}, {"166", "check"}]

  describe "the registry" do
    test "every drawing has a screen, and every screen but the gallery has a drawing" do
      # Rebuilt from three independent sources — the files on disk, the app's
      # registry, and the module list the other two sweeps discover — because
      # each has a silent empty answer, and a sweep over nothing passes.
      on_disk = DesignLiterals.numbers_on_disk()
      numbered = Enum.map(@registry, &elem(&1, 0))
      registered = Enum.map(@registry, &elem(&1, 2))

      # 165 until 5 September, when the first of the 5-September export's
      # ninety-five boards were built. `test/design/incoming/README.md` states
      # the rule this number follows: a board moves into `screens/` in the same
      # commit that builds its screen and registers it here, and this count
      # moves with it.
      #
      # 172 until 8 September, when board 167 moved in: screen 10's tune disc
      # had been pushing board 145's sheet, which sorts by five keys none of
      # which is an ordering of a queue.
      #
      # 173 until 7 September, when board 102 moved OUT — the other direction,
      # and `test/design/retired/README.md` is where it went. It was read as a
      # dark colourway of 98 and built as a second screen, and it is not one:
      # `Kati.Theme.Palette.mode/0` already draws 98 dark on a dark device.
      # What it held was two card faces 98 never previewed, which is what made
      # them unreachable in light. Both are on 98 now (MOVIES-AND-TV.md #3).
      assert length(on_disk) == 173,
             "expected 173 drawings under test/design/screens, found #{length(on_disk)} — " <>
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
      # `DesignLiterals.read!/1` would then raise on a frame that is not there,
      # here in the drawings sweep below and again in
      # `Kati.ScreenEmptyDatabaseTest`, which reads the same files —
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
            {screen.number, literal} not in DesignLiterals.retired_lines(),
            do: "  #{screen.number} #{inspect(screen.module)} never draws #{inspect(literal)}"

      assert unexplained == [],
             "these lines are in the drawing and nowhere in the screen's tree — visible or " <>
               "not, so no scroll position explains them:\n" <> Enum.join(unexplained, "\n")
    end

    test "most of that is found inside one Text, not by joining nodes" do
      # Named rather than counted. A budget that reports only its own arithmetic
      # tells whoever trips it to go and find the offender by hand, and the
      # offender is one literal out of some sixteen hundred.
      located =
        for screen <- render_all(),
            literal <- screen.design.text,
            do: {DesignLiterals.locate(literal, screen.haystacks), screen, literal}

      tiers = Enum.map(located, &elem(&1, 0))

      squashed =
        for {:squashed, screen, literal} <- located,
            do: "  #{screen.number} #{inspect(screen.module)} #{inspect(literal)}"

      assert length(squashed) <= @squashed_budget,
             "#{length(squashed)} literals are only found once whitespace is thrown away, " <>
               "over a budget of #{@squashed_budget}. That tier exists for the rating rows " <>
               "the drawings write as `★★★★☆`; copy arriving there is copy whose spacing " <>
               "nothing checks:\n" <> Enum.join(squashed, "\n")

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
            {screen.number, name} not in @retired_symbols,
            {screen.number, name} not in @unreachable_symbols,
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

  describe "the screens with two drawings" do
    test "each state replaces a real assign with a value the transcription still holds" do
      # `drawn_state/0` is the one thing in this file that changes what a screen
      # is asked, so it is pinned like every allow-list here. It cannot make the
      # comparison weaker — the whole board is still compared — but it can make
      # it *vacuous*, in two ways: a state that changes nothing leaves the screen
      # wherever its mount left it, and a state that installs an emptied
      # transcription compares the board against a blank page. Both are asserted
      # against here, and both against the screen's real mounted assigns rather
      # than against a description of them.
      numbers = Enum.map(drawn_state(), &elem(&1, 0))

      assert length(Enum.uniq(numbers)) == length(numbers),
             "a screen number appears twice in drawn_state/0, so one of the two states is " <>
               "dead code and which one wins depends on the order of a list"

      registry = Map.new(@registry, fn {number, _label, module, _kind} -> {number, module} end)

      for {number, module, state} <- drawn_state() do
        assert registry[number] == module,
               "drawn_state/0 files #{inspect(module)} under screen #{number}, which " <>
                 "Kati.Screens.Gallery registers as #{inspect(registry[number])}. A state " <>
                 "pointed at the wrong screen puts one screen's values on another's board"

        mounted =
          case ScreenSweep.mount(module) do
            {:ok, socket} -> socket.assigns
            {:error, message} -> flunk("#{inspect(module)} does not mount:\n  #{message}")
          end

        drawn = state.(mounted)
        changed = for {key, value} <- drawn, Map.get(mounted, key) != value, do: {key, value}

        refute changed == [],
               "screen #{number}'s state leaves #{inspect(module)} exactly where its mount " <>
                 "left it, so the board below is being compared against whatever the shared " <>
                 "database happened to hold. Either the screen stopped branching on the " <>
                 "store — in which case the entry goes — or the entry names an assign that " <>
                 "is no longer the one the read fills"

        blank = for {key, value} <- changed, value in [nil, [], %{}, ""], do: "  #{number} #{key}"

        assert blank == [],
               "these assigns are set to nothing by the state that is supposed to fill them, " <>
                 "so the drawing would be compared against an empty page and would fail for " <>
                 "a reason that is not the screen's. The transcription behind them has been " <>
                 "emptied:\n" <> Enum.join(blank, "\n")
      end
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
      # Raised to 26 for the five #71 retirements — 46's fridge filter, 49's
      # Auto-switch row and its sub-line, 50 and 120's QR caption, and 51's
      # three notification buttons with the footnote they were evidence for.
      #
      # Raised to 21 for 46's third swap filter and 49's Auto-switch row and
      # its sub-line, all three retired under #71 and all three the flag's kind
      # rather than the clock's: the board promises something the app cannot
      # do, and each pattern insists on the replacement rather than accepting
      # anything.
      #
      # Raised to 18 for screen 115's direction note, which is the second entry
      # of the flag's kind rather than the clock's: the board's sentence says
      # today's column is on the right and the board's own bars put it on the
      # left. Its pattern insists on the corrected word, so the entry checks
      # something rather than merely excusing it.
      # Raised to 30 on 24 August for #25's and #11's boards. Two kinds, both
      # already represented above: 128's pair is the backup ledger, which is
      # exactly why 24 and 62 are here, and 139's pair is the device clock,
      # which is exactly why 01's is. Neither is a new class of excuse — 139 IS
      # screen 01 with an empty database, and 128 is the page 24's Export row
      # links to. Every one of the four insists on the branch the screen
      # actually takes, and 128's is asserted directly by
      # `Kati.ScreenBackupTest`'s "the status card once a backup exists".
      # Raised to 31 on 4 September 2026 for screen 02's month title, and this
      # one is a different kind from the thirty above it: every other entry was
      # added because a literal could not be asserted, while this was added
      # because the suite had already gone red. `Kati.Screens.Calendar` draws
      # the device's month and the board froze `August 2026`, so the assertion
      # passed for as long as it was August and has failed every day since —
      # a test that rots on a date nobody set. Not checking less: the pattern
      # pins this month and this year, which is stricter than the frozen
      # literal it replaces, because a screen that hardcoded the drawing's
      # month now fails eleven months in twelve instead of none.
      # Raised to 33 on 4 September for screen 158, the Persian empty Home. Not
      # a new class of excuse: both entries are screen 55's, on the same
      # `Kati.Screens.HomeFa.moment/0` and with the same patterns — 158 IS 55
      # with nothing stored, exactly as 139 is 01 with nothing stored, and 01's
      # pair is already here for that reason. Each pins today's Shamsi day, so
      # a screen that hardcoded the board's ۲۵ مرداد ۱۴۰۵ still fails.
      # Raised to 38 on 6 September for screen 07's Activity row. Board 07
      # froze `1,204 entries` and the row is now a count of
      # `Kati.Media.Watch` — MOVIES-AND-TV.md #45's neighbour, and the same
      # class as 02's month title: not checking less, because the pattern
      # insists on a plural the screen builds rather than accepting anything,
      # and a screen that hardcoded the board's figure would fail on every
      # device that has not watched exactly 1,204 things. Both ends of the
      # range — none, one, many — are asserted in `Kati.ScreenStatsTest` and
      # `Kati.ScreenStatsEmptyTest`.
      # Raised to 41 on 6 September for board 86's two *Try* rows, and these
      # two are the weakest patterns in the list: a suggestion is a title out
      # of this reader's own library, so nothing about its SHAPE can be
      # asserted. What the entries hold is that the slot is still drawn, and
      # `Kati.SearchSuggestionsTest` holds the rest — including that every
      # suggestion offered is a query that actually matches.
      # Raised to 39 on 6 September for screen 94's field placeholder, and it
      # is the same class as 02's month title: the pattern insists on a count
      # the screen builds, which is stricter than the frozen literal — a screen
      # that hardcoded 190 over a list of seven fails it.
      #
      # 43 → 45 the same day, for 24's and 42's *My services* row: both froze
      # `United Kingdom · 3 subscribed` and the line counts the reader's own
      # services now, which is the count Home has always drawn.
      #
      # 41 → 43 on 6 September, for 92's *Not mine* row: `Show all 47` and
      # `Everything JustWatch lists for the UK` were a promise of a catalogue
      # that does not exist in this app, on a row that opened the empty-state
      # board over a page listing three subscriptions (MOVIES-AND-TV.md #35).
      # Both patterns accept the board's own words as well, because a device
      # with nothing stored still draws board 92 whole.
      # 48 until 7 September, when board 07's *More numbers* card stopped
      # freezing two of its four figures: `Goals` and `Money` are counted now,
      # and a counted line is asserted here by PATTERN rather than by its
      # frozen value, which is what an entry in this list is
      # (MOVIES-AND-TV.md #45). Two entries bought two lines that used to be
      # nobody's.
      # Raised from 50 to 52 for screen 97's country row (board 324). Three
      # entries for one row, and they buy the same thing the two backup entries
      # above bought: a line that was FROZEN — **ایران**, printed to every
      # Persian reader whether or not they had chosen a country — becomes a
      # line checked by contract. The alternative was a second Persian screen
      # for one state, which is the arrangement this file has spent four waves
      # arguing against.
      # Raised again on 8 September for board 05's watcher line, and it is 24's
      # `Last backup` class rather than a new one: the board froze a value the
      # screen now reads from a store, and the store is empty in every test
      # here. Not checking less — the pattern insists on one of the four things
      # the line can say about the sweep AND one of the three cadences, so a
      # screen that kept `last checked 18:02 · every 6h` fails it twice over,
      # where the frozen literal it replaces could only be matched by keeping
      # the lie.
      assert length(device_values()) <= 53,
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

    # The seven names screen 97 can print in that slot, read from the screen so
    # a country added to `Kati.Services.countries/0` cannot leave this pattern
    # behind.
    persian_countries =
      Kati.Services.countries()
      |> Enum.map(fn {code, _name} ->
        Regex.escape(Kati.Screens.MyServicesFa.region_name(code))
      end)
      |> Enum.join("|")

    today = Kati.Time.today()
    month = today.month |> Kati.Time.month_name() |> String.downcase()
    year = Integer.to_string(today.year)
    {_year, _month, shamsi_day} = Kati.Calendar.Shamsi.from_gregorian(Kati.Time.today())
    fa_day = Kati.Calendar.Shamsi.fa(shamsi_day)
    word = "[\\p{L}\\x{200C}]+"

    [
      # ── Screen 97's country row, three lines of it. Board 324.
      #
      # 97 used to read `Kati.Services.region/0` and rewrite its `"GB"` default
      # to `"IR"`, so a reader who had chosen nothing was shown **ایران** — a
      # country invented for them, on the one row the page calls its own
      # precondition. It reads `chosen_region/0` now and draws 324's cream
      # *choose a country* row for a `nil`, which is screen 93's row one
      # language over.
      #
      # So all three lines are the reader's own, and the patterns say which
      # slot must still be filled rather than with what: a country name from
      # `@countries` or the invitation, the row's sub-line or the sentence
      # that replaces it, and the flag or the `public` tile that stands in for
      # one. `Kati.ScreenMyServicesFaTest` picks a country and asserts the
      # other branch.
      {"97", "🇮🇷",
       "this reader's flag, or board 324's `public` tile when they have picked no country",
       ~r/^([\x{1F1E6}-\x{1F1FF}]{2}|#{Regex.escape(Kati.Icons.glyph!("public"))})$/u},
      {"97", "ایران", "the country this reader chose, or board 324's invitation to choose one",
       ~r/^(کشورتان را انتخاب کنید|#{persian_countries})$/u},
      {"97", "معنای «در دسترس» را تعیین می‌کند",
       "what a chosen country decides, or what nothing works without while none is chosen",
       ~r/^(معنای «در دسترس» را تعیین می‌کند|تا این تنظیم نشود چیزی کار نمی‌کند)$/u},
      {"01", "sunday · 16 august",
       "Home's eyebrow is `Kati.Screens.Home.today/0`, which formats `Kati.Time.now/0`",
       ~r/^\p{L}+ · #{day} \p{L}+$/u},
      # 86's two *Try* rows. Board 86's own caption says they are *drawn from
      # what you actually have*, and they were two fixed strings that match
      # nothing on any device but the one the board was captured on
      # (MOVIES-AND-TV.md #72). They are the newest title on the shelf and the
      # book the newest note is about now, so what a device draws there is
      # whatever that device holds — and a shelf with neither still draws these
      # two, which is why the pattern accepts them as well as anything else.
      #
      # The pattern is deliberately permissive and the claim is narrow: the
      # slot is still drawn. `Kati.SearchSuggestionsTest` holds the rest,
      # including that every suggestion offered actually matches something.
      {"86", "what leaves this week",
       "the newest title on this reader's shelf, or the board's own string on a device with " <>
         "no titles", ~r/^.+$/u},
      {"86", "notes about the estuary",
       "the book this reader's newest note is about, or the board's own string on a device " <>
         "with no notes", ~r/^.+$/u},
      # 94's field. Board 94 froze `Search 190 countries` — JustWatch's number
      # over Kati's seven — and the field was a picture that filtered nothing
      # (MOVIES-AND-TV.md #78). The placeholder counts
      # `Kati.Services.countries/0` now, so it is the truth about the list this
      # field actually searches, and it says 190 on the day the list is 190.
      {"94", "search 190 countries",
       "the size of the list the field filters, which board 94 froze at JustWatch's 190 and " <>
         "`Kati.Screens.CountryPicker.search_field/1` now counts", ~r/^search \d+ countries$/u},
      # 07's Activity row. Board 07 froze `1,204 entries` and the row counts
      # `Kati.Media.Watch` now, which on this file's store is none. It is
      # `Kati.Screens.Activity.entries_line/1`'s wording either way, and both
      # ends of the range are asserted in `Kati.ScreenStatsTest` and
      # `Kati.ScreenStatsEmptyTest`.
      {
        "07",
        "3 active · 38 of 52 books",
        "the reader's own goals, which board 07 froze at the drawing's three and " <>
          "`Kati.Screens.Stats.goals_line/0` now counts",
        # Board 309 reworded the zero: *No goals set — Kati counts anyway*, which
        # is what page 105 says of itself. A row's second line at zero is an
        # ANSWER on that board, not an absence.
        ~r/^(no goals set — kati counts anyway|1 goal|\p{N}[\p{N},]* goals)$/u
      },
      {"07", "£46.47 a month · 7 expenses",
       "the reader's own subscriptions and expenses, which board 07 froze at the drawing's " <>
         "and `Kati.Screens.Stats.money_line/0` now reads — through the same function " <>
         "screen 92's Money row reads, so the two pages cannot disagree",
       ~r/^(nothing added yet|.*a month.*|\p{N}+ expenses?)$/u},
      {"07", "1,204 entries",
       "the size of the reader's own history, which board 07 froze at 1,204 and " <>
         "`Kati.Screens.Stats.entries_count/0` now counts",
       ~r/^(\p{N}[\p{N},]* entries|1 entry|nothing logged yet)$/u},
      # 92's *Not mine* row. Board 92 froze `Show all 47 · Everything JustWatch
      # lists for the UK` on a row that opened screen 93 — the empty state —
      # over a page listing three subscriptions (MOVIES-AND-TV.md #35). Kati
      # has no catalogue provider: `Kati.Services.Service` holds the services
      # a person has told it about and nothing else, so 47 was the drawing's
      # number and could never become anyone's. The row counts what Kati
      # actually lists now, and says a fuller list needs a source it has not
      # got. A device with nothing stored still draws the board's own words,
      # which is the state the board was captured in, so the patterns accept
      # both.
      {"92", "show all 47",
       "the number of services Kati lists for this reader, which board 92 froze at " <>
         "JustWatch's 47 and `Kati.Screens.MyServices.catalogue_line/1` now counts",
       ~r/^(show all 47|kati lists \d+ services?)$/u},
      {"92", "everything justwatch lists for the uk",
       "the sub-line under it, which now says where the list comes from rather than naming " <>
         "a provider this app has never integrated",
       ~r/^(everything justwatch lists for the uk|the ones you have told it about\..*)$/u},
      # 24's and 42's *My services* row. Both boards froze `United Kingdom · 3
      # subscribed` and the line counts `Kati.Screens.MyServices.subscribed/0`
      # now — the same count Home has always drawn, which is what let one
      # screen say *No subscriptions yet* while another said 3
      # (MOVIES-AND-TV.md #75). The pattern insists the line is composed from
      # a region and a count, so a screen that hardcoded the drawing's three
      # fails it.
      {"24", "united kingdom · 3 subscribed",
       "the reader's own country and their own count, which board 24 froze at the drawing's " <>
         "three and `Kati.Settings.Sample.services_line/0` now reads",
       ~r/^.+ · (none yet|\d+ subscribed)$/u},
      {"42", "united kingdom · 3 subscribed",
       "42 draws 24's row and reaches the same count through it",
       ~r/^.+ · (none yet|\d+ subscribed)$/u},
      # 23's back pill, and the twin of this entry is in
      # `Kati.ScreenEmptyDatabaseTest`. Board 23 froze `Stats`; the only route
      # into the page is screen 92's Money row.
      {"23", "stats", "where the reader actually came from, which for this page is My services",
       ~r/^(my services|stats)$/u},
      # 92's *Something else* sub-line. The board promises *Kati will remember
      # it for your subscription total* and nothing could enter a price:
      # `Kati.Services.Service.monthly_pence` has existed since the resource
      # was written and every writer left it `nil`, so screen 23's *Every
      # month* read `—` however many services somebody added
      # (MOVIES-AND-TV.md #66). The field takes both now — `Netflix 10.99` —
      # and the row says so. The pattern insists the sentence still promises
      # the total, which is the half of it that was true.
      {"92",
       "kati will remember it for your subscription total, but cannot tell you what is on it",
       "the row explains how to enter a price, now that entering one does something",
       ~r/subscription total/u},
      {"01", "good evening",
       "the greeting is picked from the device clock's hour by the same function. Which of " <>
         "the three it is belongs to `Kati.Screens.Home.today/0`; restating its thresholds " <>
         "here would only make this fail when the product changed its mind about evening",
       ~r/^good (morning|afternoon|evening)$/},
      {"02", "sunday 16 august · 5 items",
       "Schedule's subtitle is the selected day, which starts on the device's today",
       ~r/^\p{L}+ #{day} \p{L}+ · \d+ items$/u},
      {"02", "august 2026",
       "the month title is `Kati.Screens.Calendar.month_row/1` over the selected day, which " <>
         "starts on the device's today. The board froze the month it was drawn in, so this " <>
         "entry is the only one of the thirty-one that was added because the suite had " <>
         "already gone red rather than before it could: every run from 1 September 2026 " <>
         "failed on it, and every run in August had passed. The pattern pins THIS month and " <>
         "THIS year, so a screen that hardcoded the drawing's `August 2026` still fails here",
       ~r/^#{month} #{year}$/u},
      {"09", "thu 20 aug", "the heavy day's header is the device's today, in the same short form",
       ~r/^\p{L}{3} #{day} \p{L}{3}$/u},
      {"55", "یکشنبه ۲۵ مرداد ۱۴۰۵",
       "the Persian Home's date line is `Kati.Screens.HomeFa.moment/0`, which is " <>
         "`Kati.Calendar.Shamsi.format/2` at `:long` over `Kati.Time.today/0` — the mirror " <>
         "of 01's own exemption, in the calendar the screen is drawn in",
       ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"160", "یکشنبه ۲۵ مرداد ۱۴۰۵",
       "160 is a Persian Home too, on the same `Kati.Screens.HomeFa.moment/0`",
       ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"160", "عصر بخیر", "the same greeting, the same hour", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"159", "یکشنبه ۲۵ مرداد ۱۴۰۵", "159 is 158 in the dark colourway and reads the same clock",
       ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"159", "عصر بخیر", "the same greeting, the same hour", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"158", "یکشنبه ۲۵ مرداد ۱۴۰۵",
       "the Persian empty Home's date line is `Kati.Screens.HomeFa.moment/0`, the same " <>
         "function screen 55's is — so 158 carries 55's exemption for the same reason and " <>
         "with the same pattern, pinned to today's Shamsi day",
       ~r/^#{word} #{fa_day} #{word} \p{N}+$/u},
      {"158", "عصر بخیر",
       "the greeting is that same function's, picked from the device clock's hour",
       ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"55", "عصر بخیر",
       "the greeting is picked from the device clock's hour by that same function, on " <>
         "`Kati.Screens.Home.today/0`'s thresholds. Which of the three it is belongs there; " <>
         "restating the hours here would only make this fail when the product changed its " <>
         "mind about evening", ~r/^(صبح|ظهر|عصر) بخیر$/u},
      {"56", "یکشنبه ۲۵ مرداد · ۵ مورد",
       "the Persian Schedule's subtitle is the selected day and the number of rows on it, " <>
         "and the selected day starts on the device's today",
       ~r/^#{word} #{fa_day} #{word} · \p{N}+ مورد$/u},
      # 139 is screen 01 rendered with nothing stored, so it prints the same two
      # clock values 01 does, from the same function. Both entries are 01's,
      # one screen over — see those for the argument. Restating the greeting's
      # hour thresholds here would only make this fail when the product changed
      # its mind about evening.
      {"139", "sunday · 16 august",
       "Home's eyebrow is `Kati.Screens.Home.today/0` over `Kati.Time.now/0`, and 139 is " <>
         "that screen with an empty database rather than a second implementation",
       ~r/^\p{L}+ · #{day} \p{L}+$/u},
      {"139", "good evening",
       "the greeting is picked from the device clock's hour by that same function; which " <>
         "of the three it is belongs to `Kati.Screens.Home.today/0`",
       ~r/^good (morning|afternoon|evening)$/},
      # 128's status card in the state no empty install is in. The pair that
      # 24 and 62 carry for the same ledger, on the page their Export row
      # links to — and unlike those two, this branch is not merely excused:
      # `Kati.ScreenBackupTest` seeds `Mob.State` and asserts the whole card.
      {"128", "14 aug",
       "the value line is `Kati.Screens.Backup.date_text/1` over " <>
         "`Kati.Screens.Settings.last_backup/0`, which is `nil` until a Save As completes. " <>
         "The resting state is the word `Never`, which `Kati.Screens.Backup`'s moduledoc " <>
         "argues is the truth a fresh install should tell rather than the board's frozen " <>
         "date. Both branches are asserted in `Kati.ScreenBackupTest`",
       ~r/^(\d{1,2} \p{L}{3}|never)$/u},
      {"128", "2 weeks ago · 214 mb",
       "the caption is `Kati.Screens.Backup.caption/1` — `Kati.Screens.UpNext.age/1` and " <>
         "the byte ledger, neither of which an empty `Mob.State` has. The resting caption " <>
         "is `STILL ONLY ON THIS PHONE`, and the size half drops out on its own when only " <>
         "the date was ever recorded",
       ~r/^(today|yesterday|\d+ (days|weeks|months|years) ago|1 (week|month|year) ago)( · \d+ [km]b)?$|^still only on this phone$/},
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
      # 46's third swap filter and 49's Auto-switch row — both retired under
      # #71, and both the same shape as 94's flag directly above: the board
      # promises something the app cannot do, and reproducing the promise to
      # keep a sweep quiet would be shipping the promise.
      #
      # *In my fridge* needs a pantry — stock, depletion, expiry — and Kati has
      # none. `Kati.Meals.ShoppingListItem` records the finding from the other
      # side. *Recently eaten* replaces it and is the same kind of thing the
      # other two filters are: something the app already knows, from
      # `Kati.Meals.MealLog`.
      {"46", "in my fridge",
       "a pantry is a whole feature with its own maintenance burden, and one that is 60 per " <>
         "cent accurate is worse than none — the swap tab would quietly stop offering meals " <>
         "you could cook. The rule the filter row is held to is that a filter is only offered " <>
         "if the app can apply it", ~r/^recently eaten$/},

      # *Travel week when a trip is on the calendar* needs a trip, and there is
      # no travel entity, no location state, and the calendar's own "follows
      # travel" is separately unresolved.
      {"49", "auto-switch",
       "a boolean pointing at a concept the schema cannot express is a column that can only " <>
         "ever be false. The scheduled switch carries the same intent in a date the app holds " <>
         "— and the design already draws that shape elsewhere, as *switch takes effect next " <>
         "Monday*", ~r/^switch on a date$/},
      {"49", "travel week when a trip is on the calendar",
       "the sub-line of the retired row above", ~r/^travel week takes effect next monday$/},
      # 50's and 120's QR caption, and 51's three notification buttons with
      # their footnote — the last two of #71's five, and both the flag's kind:
      # the board promises what the platform cannot deliver.
      #
      # A QR holds a few kilobytes and *Cutting v3* is 35 slots with their
      # recipes. `35 MEALS` is a payload the format cannot carry, and a QR that
      # silently fails on a big plan is worse than one that never offered — so
      # it carries the plan's shape and settings, and says so on its face.
      # `Kati.Meals.SampleShare.qr_scope/0` has the argument.
      {"50", "kati://plan/cutting-v3 · 35 meals",
       "the code carries the plan's skeleton — name, slot labels, repeat rule, reminder " <>
         "settings — not the 35 recipes behind them, because they do not fit. The " <>
         "whole-library path is the file export and screen 128's backup, where a big payload " <>
         "has no size limit worth worrying about",
       ~r/^kati:\/\/plan\/cutting-v3 · settings only$/},
      {"120", "kati://plan/cutting-v3 · 35 meals",
       "screen 120 draws the same code from the receiving side",
       ~r/^kati:\/\/plan\/cutting-v3 · settings only$/},

      # Mob supports no notification actions on either platform. Reaching them
      # means patching the host bridge permanently, for three buttons — and
      # #22's retirement ritual exists for exactly this. The notification keeps
      # its place and says what it says; tapping it opens the meal, where the
      # three actions already exist and always have.
      {"51", "eaten",
       "Mob has no notification actions on either platform, so a drawn Eaten button is a " <>
         "button that cannot be pressed. The footnote below it claimed *no need to open the " <>
         "app*, which the platform cannot keep", ~r/^tap it to open tonight's meal/},
      {"51", "snooze", "the third of the same three buttons", ~r/^tap it to open tonight's meal/},
      {"51", "tick it straight from the notification — no need to open the app",
       "the claim the three buttons were the evidence for. It is replaced by what is true: " <>
         "tapping opens the meal, and Kati says plainly that it cannot put buttons on a " <>
         "notification",
       ~r/^tap it to open tonight's meal — kati cannot put buttons on a notification$/},
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
       ~r/^(آخرین پشتیبان \p{N}+ #{word}|هنوز پشتیبانی گرفته نشده)$/u},
      # 05's watcher line. Board 05 froze `last checked 18:02 · every 6h` and
      # board 260's note called both halves *recorded nowhere*; board 314 then
      # built the record, on the page this card's cog opens.
      # `Kati.Screens.Inbox.watcher_line/0` reads the two functions screen 25
      # reads, so a reader who set `Daily` is told daily. In a test it is
      # always `never checked`, because `Mob.ScreenCase` starts `Mob.State`
      # empty; `Kati.ScreenInboxTest` reaches the other branches.
      {"05", "last checked 18:02 · every 6h",
       "when a check last completed and how often one is asked for, which board 05 froze at " <>
         "one device's evening and `Kati.Screens.Inbox.watcher_line/0` now reads from " <>
         "`Kati.Settings.Watcher` — the same store screen 25 writes",
       ~r/^(never checked|checking now|checked just now|checked \d+ (minute|hour|day)s? ago) · (hourly|every 6h|daily)$/u}
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
        # Inside an empty store, and this file did not used to be.
        #
        # It renders every screen once and memoises the trees, and it rendered
        # them against whatever the database happened to hold at that moment.
        # That was harmless while every screen answered an empty store with a
        # Sample module. It stopped being harmless as screens moved onto real
        # reads: a row left behind by another file — this suite shares one
        # connection and cleans up per test rather than rolling back — makes a
        # screen draw the reader's data instead of its board, and the
        # comparison fails on a literal that is only missing because somebody
        # else's fixture was still there. Twice on 6 September, both times on a
        # screen that had just started reading the store, and neither
        # reproducible.
        #
        # The state a drawing is a drawing OF is an empty device plus whatever
        # `drawn_state/0` installs, which is exactly what this gives it.
        screens = in_empty_store(&do_render_all/0)
        :persistent_term.put(key, screens)
        screens

      screens ->
        screens
    end
  end

  # One locale switch per screen rather than per literal: `Kati.Locale` lives in
  # `Mob.State`, which is DETS, so each switch is a `GenServer.call` and a disk
  # write (see `Kati.ScreenSweep.with_locale/2`).
  # `Kati.ScreenParamsSweepTest`'s own, for its own reason: emptied inside a
  # transaction that is always rolled back, so nothing this file does reaches
  # the next one.
  defp in_empty_store(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Kati.Repo.query!("PRAGMA defer_foreign_keys = ON", [])
        Enum.each(app_tables(), &Kati.Repo.query!("DELETE FROM " <> &1, []))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  # Ecto's own ledger and the table Mob keeps screen state in are not the app's
  # data and emptying them would be emptying the harness.
  @not_data ~w(schema_migrations mob_screen_states)

  defp app_tables do
    %{rows: rows} = Kati.Repo.query!("SELECT name FROM sqlite_master WHERE type = 'table'", [])

    for [name] <- rows,
        name not in @not_data,
        not String.starts_with?(name, "sqlite_"),
        do: name
  end

  defp do_render_all do
    for {number, _label, module, _kind} <- @registry do
      locale = if number in @fa_screens, do: :fa, else: :en
      state = Map.get(drawn_states(), number, & &1)

      case ScreenSweep.with_locale(locale, fn -> render_in(module, state) end) do
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

  # ── The four screens whose board is only half their story ───────────────────

  # `{screen number, module, assigns -> assigns}`. The function is applied
  # between `mount/3` and `render/1` and puts the screen in the state its board
  # was captured in. Every other screen renders straight off its mount, which is
  # what `Kati.ScreenSweep.render/1` does and what this file did for all 152.
  #
  # A function rather than an attribute for the reason `device_values/0` is one:
  # an attribute cannot hold an anonymous function, and a state is a change to a
  # map rather than a value.
  #
  # See the moduledoc for why these four need it. What each entry replaces is
  # the assign the screen's own read fills, and what it replaces it with is the
  # screen's own transcription of the board — `drawn_rows/0`, `drawn_titles/0`,
  # `Kati.Stats.Sample`. Those functions are the same ones these screens fell
  # back to before #91: still public, still documented as the board's
  # transcription, and now reachable from a test rather than from a person's
  # phone. **The tree compared here is therefore the tree this file compared
  # before**, node for node. What changed is that the state is asked for rather
  # than arrived at — which also makes these four independent of whatever rows
  # the rest of the suite has left in the shared database, where before they
  # were whichever way `--seed` happened to order the modules.
  #
  # ## Why not rows in the store
  #
  # Rows were the first shape tried and they cannot answer this question for two
  # of the four:
  #
  #   * board 02's sub-lines are `Habit · 12-day streak` and `£8.99`, and
  #     `Kati.Calendars.Today.meta/2` composes a row's sub-line out of an event's
  #     location and its kind label. The only way a stored event renders those
  #     two strings is to type them into its `location` — inventing data to
  #     quiet a sweep, which is the class of thing #91 is about.
  #   * board 07's `312h 40m`, `84 Films`, `19 Series` and `4.1 Avg ★` are 103
  #     titles' worth of arithmetic, and its `Where the hours went` bars are
  #     `Kati.Stats.Sample`'s on every device — `Kati.Media.CachedTitle.genres`
  #     is one free-text column, and `Kati.Screens.Stats`'s moduledoc records
  #     that as a debt rather than deriving hours from it.
  #
  # The read those rows would have exercised is not left unasked. Each of the
  # four has its own suite that writes real rows and asserts the counted page
  # comes back — `Kati.ScreenStatsEmptyTest`'s *comes back whole*,
  # `Kati.ScreenCalendarEmptyStateTest`'s *one appointment on today*,
  # `Kati.ScreenLibraryEmptyTest`'s *a shelf with one row on it*,
  # `Kati.ScreenHomeEmptyStateTest`'s *one tracked title is enough* — and
  # `Kati.ScreenEmptyDatabaseTest` is what stops this list becoming a way to keep
  # the fallback, by asserting against a database it emptied itself that all four
  # read `[]` or `nil` and NOT their drawn value.
  defp drawn_state do
    [
      # Home is now five reads and a boolean, so this entry installs the board's
      # own values into all five rather than flipping the flag over a page of
      # literals. Every one of them used to be written out inside `content/1`
      # and drew on a device whatever the store held — the hero's `3 new
      # episodes`, two half-watched cards, `United Kingdom · 3 subscribed`,
      # `Dinner 19:30`, and `rest_of_today/1`'s `[]` clause substituting
      # `drawn_rows/0` for a day nobody had told Kati about.
      #
      # So the comparison against `test/design/screens/01.html` is unchanged
      # and is now a comparison of the DRAWING against the drawing: each
      # `drawn_*` function is the transcription the board was captured from, and
      # `Kati.ScreenEmptyDatabaseTest`'s `empties/0` holds the other half — that
      # a device answers with none of them.
      {"01", Kati.Screens.Home,
       &Map.merge(&1, %{
         nothing_kept: false,
         hero: Kati.Screens.Home.drawn_hero(),
         continue: Kati.Screens.Home.drawn_continue_watching(),
         services: Kati.Screens.Home.drawn_services(),
         tiles: Kati.Screens.Home.drawn_tiles(),
         timeline: Kati.Screens.Home.drawn_rows()
       })},
      # 12 is drawn with three lists on it, which is a state a reader reaches
      # rather than the one the screen opens in: a device with no lists draws
      # `made/2`'s own card now, because board 12 has no drawn empty state to
      # fall back to and three lists nobody made is #75's defect
      # (MOVIES-AND-TV.md #106). `Kati.ScreenEmptyDatabaseTest`'s
      # `@empty_boards` holds that half.
      # 05 is drawn with a watcher count and two sections of releases, and every
      # one of those belongs to a reader who follows something. A device that
      # follows nothing draws board 260 instead — two cards and a way in —
      # because the alternative was `drawn_inbox/0` on a fresh install: the
      # drawing's three coming-up rows on the one page whose job is to say what
      # is new. `Kati.ScreenEmptyDatabaseTest`'s `@no_empty_board` holds that
      # half; this puts the screen in the state its own board was captured in.
      {"05", Kati.Screens.Inbox, &Map.put(&1, :inbox, Kati.Screens.Inbox.drawn_inbox())},
      {"12", Kati.Screens.Lists,
       &Map.put(&1, :lists, %{Kati.Screens.Lists.Sample.lists() | kept: Kati.Lists.Shelf.kept()})},
      # 154 is drawn with Series chosen, and its own caption says why: the
      # episode-count field is only visible for a series. Board 155 states the
      # screen's actual default — "Resting — empty, Film, nothing assumed" — so
      # the board and the load disagree on purpose and this is the seam.
      {"154", Kati.Screens.AddByHand,
       &(&1
         |> Map.put(:kind, :tv)
         |> Map.put(:title, "The Long Hollow")
         |> Map.put(:year, "2024")
         |> Map.put(:episodes, "7"))},
      # 157 is 154 in the dark colourway, drawn in the same state and for the
      # same reason. It used to LOAD these values, so *Add to library* wrote a
      # series nobody had typed into the reader's real library
      # (MOVIES-AND-TV.md #29). A captured frame belongs here, not in a
      # `load/1`.
      {"157", Kati.Screens.AddByHandDark,
       &(&1
         |> Map.put(:kind, :tv)
         |> Map.put(:title, "The Long Hollow")
         |> Map.put(:year, "2024")
         |> Map.put(:episodes, "7"))},
      # 19 is drawn mid-query and its whole subject is one query matched four
      # ways, so its state is a result set rather than a row: `drawn_results/0`
      # is the transcription board 19 was read from, and a device gets
      # `Kati.Search.Query.run/1`. The recent shelf rides on it, because the
      # drawing pre-chunks that shelf into the rows its `flex-wrap` produces
      # and a device's own history goes through `chunk/1` instead.
      {"19", Kati.Screens.Search,
       &(&1
         |> Map.put(:results, Kati.Screens.Search.drawn_results())
         |> Map.put(:query, "hollow")
         |> Map.put(:history, []))},
      # 86 is the idle page and its shelf is this reader's search history —
      # empty on a fresh install, which board 87 words rather than omits. The
      # five queries are 86's own, and never translated: *they are your words*,
      # in screen 88's row.
      {"86", Kati.Screens.SearchIdle,
       &Map.put(&1, :history, Kati.Screens.SearchIdle.drawn_recent())},
      # 14's back pill was drawn reading `Library`, because the board was
      # captured as an arrival from the shelf. In the app the only door into
      # screen 14 is the series page's *Show details*, so `mount/3` defaults
      # the pill to `Series` and takes `Library` from a push that says so —
      # which is what this entry is. The drawing is still the drawing; what it
      # is a drawing OF is one particular arrival.
      {"14", Kati.Screens.SeriesMeta, &Map.put(&1, :back, "Library")},
      # 23's pill reads `Stats` on its board and the only route into the page
      # is screen 92's Money row, so the word and the gesture disagreed
      # (MOVIES-AND-TV.md #66). The screen says `My services` now and takes a
      # caller's own word ahead of it — which is what this entry is, the
      # arrival board 23 is a drawing of.
      # And `set_up?` beside the back pill's own param: 23 is drawn with
      # subscriptions on it, which is the state a reader reaches rather than
      # the one the screen opens in on a fresh install — board 96's fourth band
      # is what it opens in now (MOVIES-AND-TV.md #120), and
      # `Kati.ScreenEmptyDatabaseTest`'s `@empty_boards` holds that half. The
      # gate is an assign so a captured frame can set it without writing a
      # service into the store.
      {"23", Kati.Screens.Subscriptions,
       &(&1 |> Map.put(:params, %{back: "Stats"}) |> Map.put(:set_up?, true))},
      # 06 is drawn MID-QUERY. The sheet opens empty now — its four results and
      # its `4 results` caption belong to a search somebody has run, and
      # opening on them showed a reader who had typed nothing four invented
      # films (MOVIES-AND-TV.md #43). This is the arrival the board is a
      # drawing OF: a query in the field and the answer under it.
      {"06", Kati.Screens.AddTitle,
       &(&1
         |> Map.put(:results, Kati.Library.Sample.search_results())
         |> Map.put(:query, "hollow"))},
      # 92 is drawn with three subscriptions on it, which is a state a reader
      # reaches by telling Kati about three services. A device that has told it
      # nothing gets board 93 — see `Kati.Screens.MyServices.content/1` and
      # `Kati.ScreenEmptyDatabaseTest`'s `@empty_boards`. This entry is the
      # arrival board 92 is a drawing OF, and it is one assign because the page
      # renders from one map: that is the change MOVIES-AND-TV.md #75 asked for
      # in as many words, and the reason it could not be closed before.
      {"92", Kati.Screens.MyServices,
       &Map.put(&1, :services, Kati.Screens.MyServices.drawn_page())},
      # 97 is 92 in Persian and reads through the same map, so it takes the
      # same arrival. `:on` rides with it: the switches are lit from the
      # subscribed names, and a page whose services came from the drawing must
      # take its switches from there too.
      {"97", Kati.Screens.MyServicesFa,
       fn assigns ->
         drawn = Kati.Screens.MyServices.drawn_page()

         assigns
         |> Map.put(:services, drawn)
         |> Map.put(:on, MapSet.new(Enum.map(drawn.subscribed, & &1.name)))
       end},
      {"02", Kati.Screens.Calendar, &Map.put(&1, :rows, Kati.Screens.Calendar.drawn_rows())},
      {"03", Kati.Screens.Library, &Map.put(&1, :titles, Kati.Screens.Library.drawn_titles())},
      # 28 is screen 01 in dark and its three bands are the same three reads, so
      # its state is 01's with one entry fewer: board 28 has no Watching row and
      # no Sections band. `:moment` is deliberately NOT replaced — the date line
      # and the greeting are pinned to the drawing's evening in `mount/3`
      # itself, because screen 29 draws the lock screen of that same evening and
      # the two have to agree; `Kati.Screens.HomeDark`'s moduledoc argues it and
      # `Kati.ScreenDarkWidgetsTest` holds it. `last check 18:02` used to ride on
      # that pin and now rides on `drawn_hero/0`, where the fact it stands for —
      # nothing records when the watcher last swept — can be stated.
      {"28", Kati.Screens.HomeDark,
       &Map.merge(&1, %{
         # Board 315 gave 28 the gate 139 gives 01, so the flag joins the three
         # values for 01's reason: board 28 is a device with something on it.
         # `Kati.ScreenDarkWidgetsTest` holds the other half.
         nothing_kept: false,
         hero: Kati.Screens.HomeDark.drawn_hero(),
         continue: Kati.Screens.HomeDark.Sample.continue(),
         timeline: Kati.Screens.HomeDark.Sample.rest_of_today()
       })},
      # 55 is screen 01 in Persian, and its four bands are four reads. Every
      # value installed here comes out of `Kati.Screens.HomeFa.Sample` — through
      # `drawn_hero/0` and `drawn_tiles/0`, which are that module reshaped into
      # what the render takes — so board 55 is still compared against the
      # transcription it was captured from, node for node. `:moment` stays the
      # device clock, as it always was: 55's two clock literals are exempted in
      # `device_values/0` and have been since the screen was built.
      {"55", Kati.Screens.HomeFa,
       &Map.merge(&1, %{
         # Board 317 gave 55 the gate 139 gives 01, so the flag joins the four
         # values for 01's reason: this is the board's state, and the board is
         # a device with something on it. `Kati.ScreenHomeFaEmptyStateTest`
         # holds the other half — that a device with nothing draws 158.
         nothing_kept: false,
         hero: Kati.Screens.HomeFa.drawn_hero(),
         continue: Kati.Screens.HomeFa.Sample.continue(),
         tiles: Kati.Screens.HomeFa.drawn_tiles(),
         timeline: Kati.Screens.HomeFa.Sample.rest_of_today()
       })},
      # 07's four assigns are one keyword list out of `figures/0`, and all four
      # are replaced together — a year with a `grid` from somewhere else would be
      # two different years on one card. `range` is the board's own frozen
      # `Jan – Aug 2026` rather than `Kati.Time.today()`'s: the board froze a
      # device value there, this file has no exemption for it, and reading the
      # clock instead would pass in August and fail in September.
      {"07", Kati.Screens.Stats,
       &Map.merge(&1, %{
         year: Map.put(Kati.Stats.Sample.year(), :rising?, true),
         grid: Kati.Stats.Sample.contributions(),
         recent: Kati.Screens.Stats.recent(),
         range: Kati.Stats.Sample.year().range
       })},
      # 188 is board 154's seam again. The sheet is drawn resting AND refused —
      # the card at its foot names what is missing and says nothing was
      # written — and a sheet that opened already announcing a failed save
      # would be telling someone their save failed before they pressed
      # anything. So the refusal is the state this puts it in, and
      # `Kati.ScreenEmptyDatabaseTest` compares the resting band.
      # `Kati.Screens.AddMedication.refusal/0` is the same function the tap
      # sets, so the board's sentence and the screen's cannot drift.
      {"188", Kati.Screens.AddMedication,
       &Map.put(&1, :save_error, Kati.Screens.AddMedication.refusal())}
    ]
  end

  defp drawn_states, do: Map.new(drawn_state(), fn {number, _module, fun} -> {number, fun} end)

  # `Kati.ScreenSweep.render/1` with one step inserted between the two calls it
  # makes. `state` is the identity function for every screen but the four in
  # `drawn_state/0`, so 148 of the 152 render exactly as they did — mounted, then
  # rendered from the assigns their own `mount/3` built.
  defp render_in(module, state) do
    with {:ok, socket} <- ScreenSweep.mount(module),
         assigns = state.(socket.assigns),
         {:ok, tree} <- ScreenSweep.safely(fn -> module.render(assigns) end) do
      {:ok, socket, tree}
    end
  end
end
