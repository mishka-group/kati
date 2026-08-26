defmodule Kati.ScreenHomeEmptyStateTest do
  @moduledoc """
  #91 — the first thing a new phone shows is not somebody else's evening.

  ## The defect

  `Kati.Screens.Home` drew screen 01 unconditionally. Screen 01 is Home with a
  library behind it: a hero announcing *3 new episodes are waiting*, two
  half-watched shows, and a *Rest of today* card whose `[]` clause substituted
  `Call Mum · Repeats weekly` for a calendar nobody had mirrored yet. Installed
  on a phone that had never been told anything, all of it was fabricated, and
  the owner read it exactly as written — *"you all show dummy data and it is not
  connected to database"*.

  ## What is asserted, and why presence alone would not do it

  Two halves, and only the pair means anything:

    * every string screen 139 draws is on the page, and
    * every string screen 01 fabricates is **not**.

  A test that only checks the first passes unchanged on a Home still carrying
  all nine sample cards, because 139's greeting and 01's greeting are the same
  line — which is precisely how a fallback survives a round of "we removed the
  dummy data".

  The fabricated list is not hand-typed where the screen already names it:
  `Kati.Screens.Home.drawn_hero/0`, `drawn_continue_watching/0`,
  `drawn_services/0`, `drawn_tiles/0` and `drawn_rows/0` are read from the
  screen itself — the same five functions
  `Kati.ScreenDesignLiteralTest.drawn_state/0` installs to compare screen 01
  against its board — so a transcription edited on one side cannot go unchecked
  here, and this file and that comparison cannot drift apart.

  ## The state that had no fixture, and the ordering it settles

  The gate above kept screen 01 off a device with **nothing on it**. It never
  said anything about a device with an empty store whose owner had *answered*
  the first run's sections question, and that is the state every real first run
  ends in: `Kati.Sections.answered?/0` is now the third term in
  `nothing_kept?/1`, so those people reach screen 01 rather than being told
  they chose nothing.

  Which is only safe because every band on screen 01 became a read in the same
  round. The five `describe` blocks in the middle of this file are that claim,
  one band at a time, each as a **pair**: an empty store with the invented
  strings named literally, and a real fixture with the true value drawn.
  Neither half alone is worth anything — an absence test passes on a band that
  answers `nil` unconditionally, and a presence test passes on a screen still
  full of samples.

  ## Where the emptiness comes from

  Inside one rolled-back transaction, exactly as `Kati.ScreenEmptyDatabaseTest`
  does it and for the same reason: this suite has no Ecto sandbox, one SQLite
  file is shared by every test, and several of them insert rows that outlive
  themselves. `pool_size` is 1 and this module is `async: false`, so the test
  process holds the only connection — the mount reads through it and sees the
  empty store, and nothing is kept.

  `Kati.CalendarsTodayTest`'s moduledoc records what happens to a file that
  writes an event and leaves it: `Kati.ScreenDarkWidgetsTest` fails from three
  files away, on some seeds and not others. Nothing here escapes the rollback.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Home
  alias Kati.Screens.HomeEmpty

  # Child tables first, so the deletes below do not trip a foreign key:
  # `media_watches` references `tracked_titles`, `event_occurrence_overrides`
  # references `events`. SQLite enforces both.
  #
  # `cached_*` and `services` joined the list on the round the media spine
  # started reading. Before it, a leftover cache row or a leftover service could
  # not change what Home drew — every band was a literal. Now they are the
  # difference between *No subscriptions yet* and a count, so an empty store has
  # to mean these too or "the fabricated strings are absent" would be a claim
  # about whatever the shared SQLite file happened to hold.
  @emptied ~w(media_watches tracked_titles cached_episodes cached_seasons cached_titles services event_occurrence_overrides events)

  # Screen 139's own copy, `test/design/screens/139.html`, verbatim. The
  # eyebrow is upper-cased by `Kati.UI.SettingsList.eyebrow_muted/1` rather
  # than in the drawing's text, so it is written here the way the tree holds it.
  @drawn_139 [
    "Search anything you keep",
    "Nothing chosen yet",
    "Kati keeps what you tell it to. Pick a section and this page fills with what you are " <>
      "watching, reading and eating.",
    "Choose sections",
    "or restore a backup",
    "THE CALENDAR STILL WORKS",
    "Today",
    "Nothing scheduled — add anything with +",
    "Home is a page of section cards, so with no sections there is nothing for it to show. " <>
      "The calendar and quick-add are section-agnostic and stay live — the app is usable " <>
      "before it is configured."
  ]

  # Screen 01's fabricated content: the copy that describes a library, a
  # viewing history and a day this device has never been told about. The three
  # `Kati.Design.Images` seeds behind the hero posters and the two stills are
  # not strings and are covered by the node counts instead.
  #
  # The section labels are upper-cased in the tree rather than in the drawing —
  # `Kati.UI.eyebrow/2` does it — so they are written here the way the tree
  # holds them. Written in the drawing's own case they would be absent from
  # every render, and each of these assertions would pass over a Home still
  # carrying all nine cards.
  #
  # The list is in two halves now, and they answer different questions, because
  # screen 01 itself is now a page a device with an empty store can be on.
  #
  # This half is screen 01's own chrome: drawn on 01 whatever the store holds,
  # absent from 139, and invented by nobody. It says WHICH PAGE was drawn.
  @screen_01_chrome [
    "Search films, shows, events…",
    "REST OF TODAY",
    "See all"
  ]

  # And this half is the labels of the two bands that are omitted whole when
  # they have nothing to announce — see `Kati.Screens.Home.continue_watching/1`
  # for which artboard says so. A heading over an omitted band is the band
  # still being drawn, so these belong with the invented values rather than
  # with the chrome above. Every invented VALUE is read off the screen's own
  # `drawn_*` functions in `invented/0`, so a transcription edited on one side
  # cannot walk out of this list.
  @omitted_when_empty [
    "NEW THIS WEEK",
    "Open inbox",
    "CONTINUE WATCHING"
  ]

  # Every tag screen 139's controls carry. Written out rather than read off the
  # tree, because the point of the list is that a control which stopped being
  # drawn is a control nobody can reach — a tree-derived list would shrink with
  # the page and assert nothing.
  @empty_taps [
    {:open_settings, Kati.Screens.Settings},
    {:open_search, Kati.Screens.SearchIdle},
    {:choose_sections, Kati.Screens.PickSections},
    {:restore_backup, Kati.Screens.Restore},
    {:open_calendar, Kati.Screens.Calendar}
  ]

  describe "a device with nothing on it" do
    test "Home draws screen 139's own page" do
      texts = with_empty_store(fn -> home_texts() end)

      for literal <- @drawn_139 do
        assert literal in texts,
               "Home renders nothing reading #{inspect(literal)} on an empty store. That is " <>
                 "screen 139's own copy, and 139 is the only Home the design draws for a " <>
                 "device that has been told nothing"
      end
    end

    test "and none of screen 01's fabricated content" do
      texts = with_empty_store(fn -> home_texts() end)

      present = Enum.filter(fabricated(), &(&1 in texts))

      assert present == [],
             "Home still draws copy it invented on a device with an empty store. This is the " <>
               "whole of #91 — a first launch that fabricates the user's own content:\n" <>
               Enum.map_join(present, "\n", &"  #{inspect(&1)}")
    end

    test "the two posters and two stills the hero and the cards carry are gone too" do
      # The fabricated list above can only speak for strings, and the most
      # obviously invented thing on screen 01 is five photographs of films
      # nobody has heard of. An `Image` on the empty page would mean a sample
      # card survived with its caption deleted.
      images = with_empty_store(fn -> find_all(home_tree(), :image) end)

      assert images == [],
             "the empty page draws #{length(images)} images. Screen 139 draws none — its one " <>
               "picture is a `grid_view` glyph in a paper tile"
    end

    test "the empty page is HomeEmpty's, not a second copy of it" do
      # The instruction this screen was changed under: do not put the design in
      # two places that can drift. `Kati.Screens.Home.content/1`'s empty clause
      # therefore CALLS `Kati.Screens.HomeEmpty.content/1` rather than
      # restating its column, and this is that claim as a run rather than as a
      # sentence in a moduledoc.
      #
      # Both are built in this process, so the `{self(), tag}` taps inside them
      # compare equal — which is also the reason Home can borrow the page at
      # all: the taps bind to whichever screen is rendering.
      assert Home.content(%{nothing_kept: true, timeline: []}) == HomeEmpty.content(%{}),
             "Home's empty page has diverged from screen 139's. One of the two has been " <>
               "edited and the other has not, which is the drift that made copying the " <>
               "design a bad idea in the first place"
    end

    test "every control the empty page draws is answered, and by 139's own destination" do
      drawn = with_empty_store(fn -> tap_tags(home_tree()) end)

      for {tag, _screen} <- @empty_taps do
        assert tag in drawn,
               "screen 139 draws a control tagged #{inspect(tag)} and Home's empty page does " <>
                 "not. A control that is not drawn cannot be tapped"
      end

      for {tag, screen} <- @empty_taps do
        {:noreply, socket} = Home.handle_tap(tag, Mob.Socket.new(Home))

        assert {:push, ^screen, _params} = socket.__mob__.nav_action,
               "Home answers #{inspect(tag)} with #{inspect(socket.__mob__.nav_action)}. " <>
                 "Kati.Screens.HomeEmpty sends it to #{inspect(screen)}, and one page drawn " <>
                 "from two modules must not mean two different things"
      end
    end

    test "no name is given to two nodes" do
      # `onNodeWithTag` throws on the second match, so a repeated tag makes both
      # nodes untestable on a device. Home's own header disc carries
      # `:open_calendar` and so does 139's Today row — on one page that would be
      # exactly this collision, and it is not, because the two pages are
      # branches rather than halves.
      tags = with_empty_store(fn -> tap_tags(home_tree()) end)

      assert tags == Enum.uniq(tags),
             "the empty page repeats #{inspect(tags -- Enum.uniq(tags))}"
    end
  end

  describe "a device with something on it" do
    test "one tracked title is enough to bring screen 01 back" do
      texts =
        with_empty_store(fn ->
          {:ok, _title} =
            TrackedTitle
            |> Ash.Changeset.for_create(:create, %{
              source: :manual,
              source_id: "kati:home-empty-state-test",
              kind: :tv,
              status: :watching
            })
            |> Ash.create()

          home_texts()
        end)

      # `CONTINUE WATCHING` used to be the marker here, and it stopped being one
      # the round that band started querying: this fixture writes a tracked row
      # with no cache row behind it — the evicted case
      # `Kati.Screens.Library.shelf/0` drops rather than captioning `nil` — so
      # the band correctly draws nothing and the eyebrow goes with it. Asserting
      # it would now be asserting that Home invents a card for a title it cannot
      # name, which is the defect this file is about, one layer down.
      #
      # Screen 01's search placeholder is the marker instead. It is the one line
      # the two boards word differently and neither queries: 139 draws *Search
      # anything you keep*, 01 draws *Search films, shows, events…*, and both
      # are chrome, so it says which page was drawn without saying anything
      # about what is on it.
      assert "Search films, shows, events…" in texts,
             "a device with a title tracked is not an empty device, and screen 01 is the page " <>
               "for it"

      refute "Nothing chosen yet" in texts,
             "139 tells this person they have chosen nothing while they are tracking a show"

      refute "Search anything you keep" in texts,
             "the page drawn is still 139's, whatever else is on it"
    end

    test "an archived title still counts as something kept" do
      texts =
        with_empty_store(fn ->
          {:ok, _title} =
            TrackedTitle
            |> Ash.Changeset.for_create(:create, %{
              source: :manual,
              source_id: "kati:home-empty-state-test-archived",
              kind: :tv,
              archived: true
            })
            |> Ash.create()

          home_texts()
        end)

      refute "Nothing chosen yet" in texts,
             "`archived` means *hides from shelf*, not *never happened*. A row in " <>
               "tracked_titles means this person has used the app, and 139 says they have not"
    end

    test "a day with an appointment on it is never covered by 139's empty calendar row" do
      # The second half of the guard, and the one with a wrong answer that is
      # easy to ship: `Kati.Screens.HomeEmpty`'s moduledoc is explicit that its
      # `Nothing scheduled — add anything with +` is the drawing's sentence
      # VERBATIM rather than a query. Drawn over a real 09:00 it is not an empty
      # state, it is a false one.
      #
      # No event is written for this. `nothing_kept?/1` takes the timeline as
      # its argument precisely so the rule can be asked without a fixture, and
      # `Kati.CalendarsTodayTest` records what an event left behind costs.
      row = %{
        id: "kati:not-a-real-event",
        time: "09:00",
        title: "Dentist — Marlow Clinic",
        meta: "Calendar",
        kind: :event,
        location: nil,
        now?: false
      }

      refute Home.nothing_kept?([row]),
             "Home would draw `Nothing scheduled — add anything with +` over a real appointment"

      texts = texts_of(drawn_page(%{timeline: [row]}))

      assert "Dentist — Marlow Clinic" in texts
      refute "Nothing scheduled — add anything with +" in texts
    end

    test "a real event stored on today brings screen 01 back through the mount" do
      # The test above asks `nothing_kept?/1` and `content/1` directly, with a
      # timeline row built by hand. That settles the RULE and says nothing about
      # the WIRING: `load/1` is where `Kati.Calendars.Today.rows()` meets
      # `nothing_kept?/1`, and a version of this screen that computed the flag
      # from `Ash.count/1` alone — dropping the timeline on the floor — passes
      # every assertion above and ships 139 over a real morning.
      #
      # So this one writes an event into the store, on today, and goes in
      # through `mount_screen/1`. Inside the same rolled-back transaction as
      # everything else here: `Kati.CalendarsTodayTest`'s moduledoc records what
      # an event left behind costs three files away.
      texts =
        with_empty_store(fn ->
          event_today!("Dentist — Marlow Clinic")
          home_texts()
        end)

      assert "Dentist — Marlow Clinic" in texts,
             "an event this person really has today did not reach Home. Either `load/1` " <>
               "never asked `Kati.Calendars.Today`, or it asked and then drew 139 over the " <>
               "answer"

      refute "Nothing chosen yet" in texts,
             "screen 139 is drawn on a device whose calendar has something on it today, " <>
               "which is the empty state being wrong rather than absent"

      refute "Nothing scheduled — add anything with +" in texts
    end
  end

  describe "the page that is still drawn, which this change must not have stranded" do
    # Screen 01 is now a BRANCH, and `Kati.ScreenTapSweepTest` renders each
    # screen once against an empty store — so from this round on that sweep sees
    # 139's five controls where it used to see screen 01's ten, and every guard
    # it applies to Home applies to the branch a user with data never sees. The
    # two checks it stopped making for screen 01 are made here instead, against
    # the populated branch, so the coverage moves rather than disappears.

    test "every control screen 01 draws is a name, and no name is given to two nodes" do
      tags = full_page_taps()

      assert Enum.all?(tags, &is_atom/1),
             "a tap on screen 01 is not an atom, so `Mob.Renderer` emits no " <>
               "`accessibility_id` for it and no device test can reach it: " <>
               inspect(Enum.reject(tags, &is_atom/1))

      assert tags == Enum.uniq(tags),
             "screen 01 gives one name to two nodes, and `onNodeWithTag` throws on the " <>
               "second match: #{inspect(tags -- Enum.uniq(tags))}"
    end

    test "and every one of them still reaches something that changes" do
      # `Kati.ScreenTapSweepTest`'s own heuristic, at the one screen it can no
      # longer point at: dispatch the tag, dispatch a tag nothing could draw,
      # and compare. Identical assigns and identical nav action means the real
      # tag landed exactly where the nonsense one did — on `handle_tap/2`'s
      # `_tag` catch-all.
      inert = for tag <- full_page_taps(), inert?(tag), do: tag

      assert inert == [],
             "these controls on screen 01 reach nothing that changes anything, and the tap " <>
               "sweep no longer renders the page they are on:\n" <>
               Enum.map_join(inert, "\n", &"  #{inspect(&1)}")
    end
  end

  describe "sections, which are a different question from emptiness" do
    test "a section that is off is absent from the page that has something to draw" do
      :ok = Kati.Sections.put(["screen"])

      # `tile_rows/0` rather than `drawn_tiles/0`: the section filter lives on
      # the read, which is the point — the drawing's transcription is unfiltered
      # because a board has no sections to have turned off.
      texts = texts_of(drawn_page(%{tiles: Home.tile_rows()}))

      refute "Habits" in texts,
             "the home card outlived the choice, which is the design's rule failing quietly"

      assert "Settings" in texts,
             "Meals and Settings are not sections the first run offers to keep, so they stay"
    end

    test "a section that is kept and holds nothing draws that section, empty — not 139" do
      # This assertion is INVERTED from what it was, and the inversion is the
      # defect. It used to read `assert "Nothing chosen yet" in texts` and
      # `refute "Habits" in texts`, on the argument that KEPT-AND-EMPTY is the
      # page itself being screen 139.
      #
      # It is not. Screen 139 is `Kati.Screens.HomeEmpty`, whose own moduledoc
      # calls it "the state after *Skip, I will add*", and it offers **Choose
      # sections** as the one thing that fixes it. Drawn at somebody who has
      # just chosen two sections it says their answer did not register and
      # offers to redo the step they finished — which is what a clean install on
      # a Pixel 9a did, and which no test here could catch, because every one of
      # them asked about an empty STORE and this is a person with an empty store
      # WHO HAS ANSWERED.
      #
      # So the pair is still opposite outcomes and still the whole point, and
      # the second half now reads the other way: OFF means the card is gone from
      # a page that has something to draw; KEPT-AND-EMPTY means the card is
      # there and holds nothing.
      :ok = Kati.Sections.put(Kati.Sections.all())

      assert Kati.Sections.on?("habits")

      texts = with_empty_store(fn -> home_texts() end)

      refute "Nothing chosen yet" in texts,
             "Home told a person who kept every section that they had chosen none"

      assert "Habits" in texts,
             "a section this person kept has no card on the page they land on"

      # And the reason the inversion above is safe rather than a regression:
      # every band on the page they now land on is a read, so an empty store
      # draws no invented row on it either. Without this half, flipping the
      # assertion would simply have moved the lie from 139's sentence to screen
      # 01's spine — which is exactly what happened on the device.
      present = Enum.filter(invented(), &(&1 in texts))

      assert present == [],
             "screen 01 is now drawn to somebody who answered the sections question, and it " <>
               "still carries copy it invented:\n" <>
               Enum.map_join(present, "\n", &"  #{inspect(&1)}")
    end
  end

  # Everything below is about the page a person who ANSWERED the sections
  # question lands on — screen 01, with an empty store behind it. It is the
  # state the walk-through on the Pixel 9a was in, and until this round no
  # fixture in the suite described it: `nothing_kept?/1` kept screen 01 off a
  # device that had nothing, so nothing ever rendered its bands empty.
  #
  # Each band gets a PAIR. The absence half names the invented strings
  # literally, because a presence-only test passes on a screen still full of
  # samples — which is the whole reason this ticket exists. The presence half
  # writes a real row and asserts the real value draws, because a band that
  # answers `nil` unconditionally would pass every absence test ever written.
  describe "New this week, with nothing to announce" do
    test "draws no hero and no eyebrow, and none of the drawing's three episodes" do
      texts = with_empty_store(fn -> answered_home_texts() end)

      for literal <- ["3 new episodes", "are waiting", "NEW THIS WEEK", "Open inbox"] do
        refute literal in texts,
               "Home announces #{inspect(literal)} on a device that follows nothing. That " <>
                 "sentence is the sharpest form of #91 — a count of episodes over a library " <>
                 "with no titles in it"
      end

      refute Home.drawn_hero().sub in texts,
             "`One premiere · two titles leave Lumen+ on Friday` is availability, which " <>
               "screen 96 says needs a subscribed service to count down from, and no column " <>
               "holds"

      refute Home.drawn_hero().checked in texts,
             "`last check 18:02` — `Kati.Screens.Inbox`'s moduledoc records that nothing " <>
               "stores when the watcher last swept"

      assert Home.hero_summary() == nil
    end

    test "one episode really out this week draws the hero, in the singular" do
      texts =
        with_empty_store(fn ->
          tracked = track!(%{kind: :tv, title: "Marram Lights", seed: "marram15"})
          episode!(tracked, %{season: 1, episode: 4, title: "Low Water", days: -2})

          answered_home_texts()
        end)

      assert "NEW THIS WEEK" in texts
      assert "1 new episode" in texts, "the count is real, so one episode is one episode"
      assert "is waiting" in texts, "and the verb has to agree with it"
      assert "Open inbox" in texts

      refute "3 new episodes" in texts,
             "the drawing's own count came back beside a real one, which is the frozen value " <>
               "this whole change is about"
    end
  end

  describe "Continue watching, with nothing in progress" do
    test "draws no cards and no eyebrow, and neither of the drawing's two shows" do
      texts = with_empty_store(fn -> answered_home_texts() end)

      for literal <- [
            "The Long Hollow",
            "Salt & Iron",
            "S2 · E6 · 18m left",
            "S1 · E3 · 41m left",
            "CONTINUE WATCHING"
          ] do
        refute literal in texts,
               "Home draws #{inspect(literal)} on a device with nothing on its shelf"
      end

      assert Home.continue_watching_rows() == []

      images = with_empty_store(fn -> find_all(answered_home_tree(), :image) end)

      assert images == [],
             "the page draws #{length(images)} photographs of shows nobody added. The strings " <>
               "above can only speak for captions"
    end

    test "a title the person is part-way through draws its own card" do
      texts =
        with_empty_store(fn ->
          tracked = track!(%{kind: :tv, title: "Marram Lights", seed: "marram15"})
          tick!(tracked, "episode:marram-1")

          answered_home_texts()
        end)

      assert "CONTINUE WATCHING" in texts
      assert "Marram Lights" in texts, "the shelf has a title on it and Home drew none"

      refute "The Long Hollow" in texts,
             "a real card came up beside the drawing's two rather than instead of them"

      refute "S2 · E6 · 18m left" in texts,
             "nothing writes `progress_season`, `progress_episode` or `progress_seconds`, so " <>
               "a real card has no bookmark line to draw and must not borrow the drawing's"
    end
  end

  describe "the Watching card, with no services set up" do
    test "says so in screen 96's words rather than counting the drawing's three" do
      texts = with_empty_store(fn -> answered_home_texts() end)

      refute "United Kingdom · 3 subscribed" in texts,
             "the Watching card counted `Kati.Screens.MyServices.subscribed/0`, which answers " <>
               "an empty table with the drawing's three services"

      refute "3 subscribed" in texts

      refute "United Kingdom · 0 subscribed" in texts,
             "screen 96: `an empty ledger, not £0.00 a month — there is nothing here to be " <>
               "zero`"

      assert "My services" in texts,
             "96 puts a `My services` action under all four of its empty bands — the empty " <>
               "state has to offer the one thing that fixes it"

      assert "No subscriptions yet" in texts, "which is 96's own sentence for this state"
    end

    test "two services really stored are counted as two" do
      texts =
        with_empty_store(fn ->
          service!("Lumen+")
          service!("Harbour")

          answered_home_texts()
        end)

      assert "United Kingdom · 2 subscribed" in texts

      refute "No subscriptions yet" in texts,
             "the card says nothing is set up over two services that are"

      refute "United Kingdom · 3 subscribed" in texts
    end
  end

  describe "Rest of today, on a day with nothing on it" do
    test "draws its own emptiness rather than the drawing's two rows" do
      texts = with_empty_store(fn -> answered_home_texts() end)

      for literal <- [
            "20:00",
            "The Long Hollow — S2E6",
            "Airs tonight · Lumen+",
            "21:30",
            "Call Mum",
            "Repeats weekly"
          ] do
        refute literal in texts,
               "an empty day silently became the drawing's, so Home told somebody who has " <>
                 "never opened a calendar to ring their mother at 21:30"
      end

      assert "Nothing scheduled — add anything with +" in texts,
             "screen 139 is where that sentence comes from, and screen 96 is why an empty " <>
               "card has to say something rather than nothing"

      assert "REST OF TODAY" in texts,
             "the band stays: 139's whole argument is that the calendar still works"
    end

    test "a real event on today draws instead of it" do
      texts =
        with_empty_store(fn ->
          event_today!("Dentist — Marlow Clinic")
          answered_home_texts()
        end)

      assert "Dentist — Marlow Clinic" in texts

      refute "Nothing scheduled — add anything with +" in texts,
             "the empty sentence was drawn over a real appointment, which is the empty state " <>
               "being wrong rather than absent"

      refute "Call Mum" in texts
    end
  end

  describe "the section tiles, whose two metas nothing counts" do
    test "draw the cards and neither of the drawing's counts" do
      texts = with_empty_store(fn -> answered_home_texts() end)

      assert "Meals" in texts
      assert "Habits" in texts
      assert "Settings" in texts

      refute "Dinner 19:30" in texts,
             "screen 43 owns the day's meals and has its own active-plan gate; Home reached " <>
               "past it and printed a dinner nobody planned"

      refute "2 left today" in texts,
             "`Kati.Screens.Habits`'s moduledoc: there is no resource anywhere in this app " <>
               "that records a habit being kept, so nothing can be left today"

      refute "0 left today" in texts,
             "and a counted nought is the plausible-looking zero screen 96 forbids"
    end
  end

  describe "answering the sections question, which is not the same as filling one" do
    test "somebody who kept two sections gets their own page, with nothing invented on it" do
      # The state the walk-through was in: clean install, Screen and Books
      # picked, calendar permission declined, run finished. What Home drew was
      # 139 — *Nothing chosen yet*, over a button offering to redo the step just
      # finished. `Kati.OnboardingResumeTest` holds the flag; this holds what is
      # on the page the flag now selects, which is the half that made the
      # ordering matter.
      texts =
        with_empty_store(fn ->
          :ok = Kati.Sections.put(["screen", "books"])
          home_texts()
        end)

      refute "Nothing chosen yet" in texts
      refute "Choose sections" in texts

      assert "SECTIONS" in texts, "their sections are what Home is a page of"

      present = Enum.filter(invented(), &(&1 in texts))

      assert present == [],
             "the page a person reaches by answering the first run's question carries copy " <>
               "Kati invented. Doing the sections half of this change before the five bands " <>
               "became reads is exactly what put these strings on a device:\n" <>
               Enum.map_join(present, "\n", &"  #{inspect(&1)}")
    end

    test "somebody who kept none still gets 139" do
      # The other half, so the rule above cannot be a blanket `false`.
      Kati.Sections.forget!()

      texts = with_empty_store(fn -> home_texts() end)

      assert "Nothing chosen yet" in texts
      assert "Choose sections" in texts
    end
  end

  describe "the emptiness this file rests on" do
    test "the transaction is rolled back, so the rest of the suite keeps its rows" do
      # Every assertion above is a claim about a store with nothing in it, and
      # every such claim is satisfied by a store that was empty to begin with.
      # This one writes first and asks the same question of a row it knows
      # exists — seen outside, unseen inside, there again after.
      {:ok, title} =
        TrackedTitle
        |> Ash.Changeset.for_create(:create, %{
          source: :manual,
          source_id: "kati:home-empty-state-probe",
          kind: :movie
        })
        |> Ash.create()

      on_exit(fn -> Kati.Repo.query!("DELETE FROM tracked_titles WHERE id = ?1", [title.id]) end)

      assert Ash.get!(TrackedTitle, title.id)

      inside = with_empty_store(fn -> Ash.read!(TrackedTitle) end)

      assert inside == [],
             "the deletes did not reach tracked_titles, so nothing above was rendered against " <>
               "an empty store"

      assert Ash.get!(TrackedTitle, title.id),
             "a row written before the transaction is gone after it rolled back. This module " <>
               "shares one database file with every other test and would be deleting their " <>
               "fixtures"
    end
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  # Screen 01's chrome, plus every value the screen itself names as the
  # drawing's, so a transcription edited in `Kati.Screens.Home` cannot walk out
  # of this list. `drawn_hero/0`, `drawn_continue_watching/0`,
  # `drawn_services/0`, `drawn_tiles/0` and `drawn_rows/0` are exactly what
  # `Kati.ScreenDesignLiteralTest.drawn_state/0` installs to compare screen 01
  # against its board — so this list and that comparison cannot drift apart.
  defp fabricated, do: @screen_01_chrome ++ invented()

  # Everything on screen 01 that describes a library, a viewing history, a
  # subscription or a day this device has never been told about. Nothing here
  # may appear on ANY page a device with an empty store draws — 139's, and
  # screen 01's own, which is what a person who answered the sections question
  # now lands on.
  defp invented do
    hero = Home.drawn_hero()

    @omitted_when_empty ++
      Home.headline_lines(hero.count) ++
      [hero.sub, hero.checked, Home.services_line(Home.drawn_services())] ++
      Enum.flat_map(Home.drawn_continue_watching(), fn row -> [row.title, row.meta] end) ++
      (Home.drawn_tiles() |> Enum.map(& &1.meta) |> Enum.reject(&is_nil/1)) ++
      Enum.flat_map(Home.drawn_rows(), fn row -> [row.time, row.title, row.meta] end)
  end

  # Screen 01's own page, with the board's values in the five assigns `load/1`
  # fills from the store. `content/1` reads assigns and nothing else now, so
  # this is how a test names the populated branch — and using the `drawn_*`
  # values rather than empty ones is what keeps every control on it drawn.
  defp drawn_page(overrides \\ %{}) do
    %{
      nothing_kept: false,
      timeline: Home.drawn_rows(),
      hero: Home.drawn_hero(),
      continue: Home.drawn_continue_watching(),
      services: Home.drawn_services(),
      tiles: Home.drawn_tiles()
    }
    |> Map.merge(overrides)
    |> Home.content()
  end

  defp with_empty_store(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Enum.each(@emptied, &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  defp home_tree, do: tree(mount_screen(Home))

  defp home_texts, do: texts_of(home_tree())

  # Home as somebody who has answered the sections question sees it: screen 01,
  # mounted through `load/1` so every band is filled by its own read rather than
  # by an assign this file chose. Called INSIDE `with_empty_store/1`, so the
  # reads see nothing unless the same block wrote something first.
  #
  # `Kati.Sections.put/1` rather than a flag: `nothing_kept?/1` asks
  # `Kati.Sections.answered?/0`, and the point of these tests is the page a real
  # first run ends on. `Mob.ScreenCase` starts `Mob.State` per test against a
  # throwaway data dir, so this does not outlive the test that calls it.
  defp answered_home_tree do
    :ok = Kati.Sections.put(Kati.Sections.all())
    home_tree()
  end

  defp answered_home_texts, do: texts_of(answered_home_tree())

  defp texts_of(tree) do
    tree
    |> find_all(:text)
    |> Enum.map(&(&1.props[:text] || ""))
    |> Enum.reject(&(&1 == ""))
  end

  # Screen 01's own controls, taken off the branch a device with data draws.
  # `content/1` rather than `mount_screen/1`: the flag is what selects the
  # branch, and passing it is how this file names which of the two it means.
  #
  # The DRAWN values, not empty ones. Two of screen 01's bands are omitted
  # entirely when they have nothing to say, and the taps inside them go with
  # them — so a page built from an empty spine would quietly stop asserting
  # anything about the hero's `Open inbox`.
  defp full_page_taps, do: tap_tags(drawn_page())

  # Does this tag land where a tag nobody could draw lands — `handle_tap/2`'s
  # `_tag` catch-all? Compared on both halves of what a tap can move, because a
  # screen that only assigned and a screen that only navigated would each look
  # wired on the other one.
  defp inert?(tag) do
    {:noreply, real} = Home.handle_tap(tag, Mob.Socket.new(Home))
    {:noreply, nonsense} = Home.handle_tap(:kati_no_screen_draws_this, Mob.Socket.new(Home))

    real.assigns == nonsense.assigns and real.__mob__.nav_action == nonsense.__mob__.nav_action
  end

  # One confirmed event on today, in the calendar this call makes for it. The
  # same shape `Kati.EventRowIdentityTest` writes: a UTC instant for the range
  # query, the authored wall clock beside it, and the length as a duration.
  defp event_today!(summary) do
    calendar =
      Kati.Calendars.Calendar
      |> Ash.Changeset.for_create(:create, %{
        display_name: "Home empty state #{System.unique_integer([:positive])}",
        kind: :local
      })
      |> Ash.create!()

    zone = Kati.Time.device_zone()
    naive = NaiveDateTime.new!(Kati.Time.today(), ~T[09:00:00])
    {:ok, utc} = Kati.Time.to_utc(naive, zone)

    Kati.Calendars.Event
    |> Ash.Changeset.for_create(:create, %{
      uid: "kati-home-empty-#{System.unique_integer([:positive])}@kati",
      calendar_id: calendar.id,
      origin: :kati,
      summary: summary,
      kind: :event,
      status: :confirmed,
      dtstart_utc: utc,
      dtstart_wall: Calendar.strftime(naive, "%Y%m%dT%H%M%S"),
      tzid: zone,
      duration_iso: "PT30M",
      sync_state: :local_only
    })
    |> Ash.create!()
  end

  # ── Fixtures, written INSIDE the rolled-back transaction ────────────────────

  # Both halves of one title, the way `Kati.ScreenInboxTest` writes them: the
  # cache row for what a provider said, the tracked row for what the user did,
  # joined by the `{source, source_id}` value pair rather than a foreign key.
  defp track!(attrs) do
    source_id = "home-spine:#{System.unique_integer([:positive])}"

    Kati.Media.CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: attrs.kind,
      title: attrs.title,
      poster_path: attrs[:seed],
      episode_count: attrs[:episodes] || 8,
      fetched_at: utc_now()
    })
    |> Ash.create!()

    Kati.Media.TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: attrs.kind,
      status: attrs[:status] || :watching
    })
    |> Ash.create!()
  end

  # One episode of a followed title, dated relative to now. `:exact` because
  # `Kati.Media.Release.airing/2` is the gate `Kati.Screens.Inbox` reads through
  # and a coarser confidence would never reach `:aired`.
  defp episode!(tracked, attrs) do
    Kati.Media.CachedEpisode
    |> Ash.Changeset.for_create(:create, %{
      source: tracked.source,
      source_id: "home-spine-episode:#{System.unique_integer([:positive])}",
      title_source_id: tracked.source_id,
      season_number: attrs[:season],
      episode_number: attrs[:episode],
      title: attrs[:title],
      air_at: DateTime.add(utc_now(), (attrs[:days] || 0) * 24 * 60 * 60, :second),
      date_confidence: :exact,
      fetched_at: utc_now()
    })
    |> Ash.create!()
  end

  # A tick, which is what the shelf's fraction is derived from — the counter is
  # never stored, per `Kati.Media.TrackedTitle`.
  defp tick!(tracked, episode_source_id) do
    Kati.Media.Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      episode_source_id: episode_source_id,
      watched_at: utc_now()
    })
    |> Ash.create!()
  end

  defp service!(name) do
    Kati.Services.Service
    |> Ash.Changeset.for_create(:create, %{name: name, tier: :subscribed, monthly_pence: 899})
    |> Ash.create!()
  end

  defp utc_now, do: Kati.Time.now() |> DateTime.shift_zone!("Etc/UTC")

  defp tap_tags(tree) do
    tree
    |> Mob.ScreenCase.flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node.props || %{}, :on_tap) do
        {pid, tag} when is_pid(pid) and is_atom(tag) -> [tag]
        _other -> []
      end
    end)
  end
end
