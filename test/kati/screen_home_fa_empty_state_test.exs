defmodule Kati.ScreenHomeFaEmptyStateTest do
  @moduledoc """
  #91 in Persian — the page a Persian install opens on is not somebody else's
  evening.

  ## Why this screen and not another mirror

  `Kati.Onboarding.shell_root/1` answers `Kati.Screens.HomeFa` for `:fa`. It is
  not a gallery board and not a colourway: it is **the root a Persian user lands
  on after answering screen 53**, and until this round it drew
  `Kati.Screens.HomeFa.Sample` whole — ۳ قسمت تازه over a library with nothing in
  it, two half-watched shows nobody had added, شام ۱۹:۳۰ and ۲ مورد مانده under
  section tiles nothing counts, and a باقی امروز card telling a person whose
  calendar Kati had never been shown to ring their mother at ۲۱:۳۰.

  Screen 01 was fixed for the English user and this was left, which made the
  defect worse rather than smaller: the same first launch was honest in one
  language and invented in the other.

  ## The false negative this file exists to make impossible

  The first probe of this screen grepped screen 01's **English** invented
  strings — `The Long Hollow`, `3 new episodes`, `Call Mum` — against screen 55
  and found none of them. That reads exactly like a clean bill of health and is
  worth nothing: the Persian page never contained those strings. Every absence
  asserted here is therefore named with the **Persian literal**, and named off
  `Kati.Screens.HomeFa.Sample` itself rather than typed, so a transcription
  edited on one side cannot walk out of this list.

  ## What is asserted, and why each half alone is worthless

  Every band is a **pair**:

    * an empty store with the invented Persian strings named literally — a
      presence-only test passes on a screen still full of samples; and
    * a real fixture with the true value drawn — an absence-only test passes on
      a band that answers `nil` unconditionally, which is a different way of
      drawing nothing.

  Plus the third claim `Kati.ScreenEmptyDatabaseTest` calls the anti-vacuity
  one: the `Sample` module still holds the drawing. Without it every `refute`
  here goes vacuous the moment somebody empties the transcription, and
  `Kati.ScreenDesignLiteralTest.drawn_state/0` renders board 55 out of those
  same functions.

  ## The one sentence no artboard contains

  `Kati.Screens.HomeFa.empty_day/0`. There is no Persian mirror of screen 139,
  so باقی امروز with nothing on it has no drawn wording anywhere, and that
  function's own doc argues the three ways out and why this is the one taken.
  It is pinned here at both ends — drawn on an empty day, gone the moment a real
  event lands on today — because `Kati.ScreenEmptyDatabaseTest` cannot hold it:
  its `@quoted` mechanism checks a line against the board it is quoted from, and
  this line is quoted from nothing.

  ## Where the emptiness comes from

  Inside one rolled-back transaction, exactly as `Kati.ScreenHomeEmptyStateTest`
  and `Kati.ScreenEmptyDatabaseTest` do it and for the same reason: this suite
  has no Ecto sandbox, one SQLite file is shared by every test, and several of
  them insert rows that outlive themselves. `pool_size` is 1 and this module is
  `async: false`, so the test process holds the only connection — the mount
  reads through it and sees the empty store, and nothing is kept.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.HomeFa
  alias Kati.Screens.HomeFa.Sample

  # Child tables first, so the deletes do not trip a foreign key:
  # `media_watches` references `tracked_titles`, `event_occurrence_overrides`
  # references `events`. SQLite enforces both. The same list
  # `Kati.ScreenHomeEmptyStateTest` empties, because this screen reads the same
  # three domains screen 01 does.
  @emptied ~w(media_watches tracked_titles cached_episodes cached_seasons cached_titles services event_occurrence_overrides events)

  # Board 55's own copy that is NOT stand-in data: the search placeholder, the
  # two eyebrows whose bands survive, and the three section labels. All six must
  # still be on the page when there is nothing to put under them — an empty
  # Persian Home is board 55 emptied, not a different page — and
  # `Kati.ScreenEmptyDatabaseTest`'s `@quoted` holds the same six against the
  # board file itself, so neither end can drift alone.
  @board_55_chrome [
    "جست‌وجوی فیلم، سریال، رویداد…",
    "بخش‌ها",
    "وعده‌ها",
    "عادت‌ها",
    "تنظیمات",
    "باقی امروز"
  ]

  # The two eyebrows that go with their bands. A heading over an omitted band is
  # the band still being drawn, so these belong with the invented values rather
  # than with the chrome above.
  @omitted_when_empty ["تازه‌های این هفته", "ادامه تماشا"]

  describe "a Persian device with nothing on it" do
    test "draws none of screen 55's fabricated content" do
      texts = with_empty_store(&home_texts/0)

      present = Enum.filter(invented(), &(&1 in texts))

      assert present == [],
             "screen 55 still draws copy it invented on a device with an empty store. This is " <>
               "#91 on the page a Persian install OPENS on:\n" <>
               Enum.map_join(present, "\n", &"  #{inspect(&1)}")
    end

    test "and keeps every line of its own board that was never stand-in data" do
      texts = with_empty_store(&home_texts/0)

      for literal <- @board_55_chrome do
        assert literal in texts,
               "screen 55 renders nothing reading #{inspect(literal)} on an empty store. That " <>
                 "is board 55's own chrome, and an empty Persian Home is board 55 emptied " <>
                 "rather than a smaller page"
      end
    end

    test "says what is missing on an empty day, in the one sentence this app wrote" do
      texts = with_empty_store(&home_texts/0)

      assert HomeFa.empty_day() in texts,
             "باقی امروز drew nothing at all. Screen 96's rule is that an empty state says " <>
               "what is missing and offers the one thing that fixes it, and screen 139's whole " <>
               "argument is that the calendar still works when nothing else is set up"

      assert String.contains?(HomeFa.empty_day(), "+"),
             "the sentence has to name the control that ends the state, and the control is the " <>
               "64pt `+` `Kati.Screens.Fa.dock/1` draws over this page"
    end

    test "and draws no photographs of films nobody added" do
      # The string lists above can only speak for captions. The most obviously
      # invented thing on board 55 is five photographs — three poster thumbnails
      # in the cream card and two stills in the continue cards — and an `Image`
      # on the empty page would mean a sample card survived with its caption
      # deleted.
      images = with_empty_store(fn -> find_all(home_tree(), :image) end)

      assert images == [],
             "the empty Persian Home draws #{length(images)} images"
    end

    test "no name is given to two nodes" do
      # `onNodeWithTag` throws on the second match. 55 used to give
      # `:open_inbox` to both the notification disc and the hero's button —
      # `Kati.ScreenTapSweepTest`'s `@known_collisions` carried it — and the
      # collision is gone on this branch because the hero is.
      tags = with_empty_store(fn -> tap_tags(home_tree()) end)

      assert tags == Enum.uniq(tags),
             "the empty page repeats #{inspect(tags -- Enum.uniq(tags))}"
    end
  end

  describe "تازه‌های این هفته, with nothing to announce" do
    test "draws no card and no eyebrow" do
      texts = with_empty_store(&home_texts/0)

      inbox = Sample.inbox()

      for literal <- [
            inbox.headline,
            inbox.line,
            inbox.checked,
            inbox.action | @omitted_when_empty
          ] do
        refute literal in texts,
               "screen 55 announces #{inspect(literal)} on a device that follows nothing"
      end

      assert with_empty_store(fn -> HomeFa.hero_summary() end) == nil
    end

    test "one episode really out this week draws the card, with a real Persian count" do
      texts =
        with_empty_store(fn ->
          tracked = track!(%{kind: :tv, title: "Marram Lights"})
          episode!(tracked, %{season: 1, episode: 4, title: "Low Water", days: -2})

          home_texts()
        end)

      assert "تازه‌های این هفته" in texts
      assert "باز کردن صندوق" in texts

      assert "۱ قسمت تازه\nدر انتظار شماست" in texts,
             "the count is the only thing that moves — every word is board 55's own, and " <>
               "Persian does not inflect a noun after a numeral, so one episode takes the " <>
               "drawing's own sentence with `۱` in it"

      refute Sample.inbox().headline in texts,
             "the drawing's own ۳ came back beside a real count, which is the frozen value " <>
               "this whole change is about"

      refute Sample.inbox().line in texts,
             "availability needs a subscribed service to count down from — screen 96 — and no " <>
               "column holds it"

      refute Sample.inbox().checked in texts,
             "`Kati.Screens.Inbox` records that nothing stores when the watcher last swept"
    end
  end

  describe "ادامه تماشا, with nothing in progress" do
    test "draws no cards and no eyebrow" do
      texts = with_empty_store(&home_texts/0)

      for row <- Sample.continue(), literal <- [row.title, row.meta] do
        refute literal in texts,
               "screen 55 draws #{inspect(literal)} on a device with nothing on its shelf"
      end

      refute "ادامه تماشا" in texts
    end

    test "a title the person is part-way through draws its own card" do
      texts =
        with_empty_store(fn ->
          tracked = track!(%{kind: :tv, title: "Marram Lights"})
          tick!(tracked, "episode:marram-1")

          home_texts()
        end)

      assert "ادامه تماشا" in texts
      assert "Marram Lights" in texts, "the shelf has a title on it and 55 drew none"

      refute "گودال بلند" in texts,
             "a real card came up beside the drawing's two rather than instead of them"

      refute "فصل ۲ · قسمت ۶" in texts,
             "nothing writes `progress_season`, `progress_episode` or `progress_seconds`, so a " <>
               "real card has no bookmark line and must not borrow the drawing's"
    end

    test "a card at either end of the bar renders rather than throwing" do
      # `0.0` and `1.0` were unreachable while the cards came from
      # `Sample.continue/0` and are reachable from the first real shelf row: a
      # title marked *watching* with no tick against it is `0.0`. The component
      # omits whichever node would carry the zero weight Compose throws on.
      for progress <- [0.0, 1.0, nil] do
        row = %{title: "Marram Lights", meta: nil, progress: progress, seed: nil}

        assert %{} = HomeFa.watch_card(row),
               "the Persian continue card cannot draw progress #{inspect(progress)}"
      end
    end
  end

  describe "بخش‌ها, whose two counts nothing counts" do
    test "draws the three tiles and neither of the drawing's counts" do
      texts = with_empty_store(&home_texts/0)

      assert "وعده‌ها" in texts
      assert "عادت‌ها" in texts
      assert "تنظیمات" in texts

      refute "شام ۱۹:۳۰" in texts,
             "screen 43 owns the day's meals and has its own active-plan gate; 55 reached past " <>
               "it and printed a dinner nobody planned"

      refute "۲ مورد مانده" in texts,
             "`Kati.Screens.Habits`'s moduledoc: there is no resource anywhere in this app " <>
               "that records a habit being kept, so nothing can be left today"

      refute "۰ مورد مانده" in texts,
             "and a counted nought is the plausible-looking zero screen 96 forbids"

      assert Enum.map(HomeFa.tile_rows(), & &1.meta) == [nil, nil, nil]
      assert Enum.map(HomeFa.tile_rows(), & &1.dot) == [nil, nil, nil]
    end

    test "a section that is off leaves the page" do
      :ok = Kati.Sections.put(["screen"])

      texts = with_empty_store(&home_texts/0)

      refute "عادت‌ها" in texts,
             "the home card outlived the choice, which is the design's rule failing quietly"

      assert "تنظیمات" in texts,
             "وعده‌ها and تنظیمات are not sections the first run offers to keep, so they stay"
    end

    test "the live labels and the drawn ones are the same three words" do
      # The one thing `drawn_tiles/0` does not read off the Sample is the label,
      # because the live tiles need labels too and a render may not reach the
      # Sample. So the two lists are pinned against each other here rather than
      # left to drift — board 55 is compared against the drawn side by
      # `Kati.ScreenDesignLiteralTest` and against the live side by the chrome
      # assertion at the top of this file.
      assert Enum.map(HomeFa.drawn_tiles(), & &1.label) ==
               Enum.map(Sample.sections(), & &1.label)

      assert Enum.map(HomeFa.tile_rows(), & &1.label) ==
               Enum.map(HomeFa.drawn_tiles(), & &1.label)
    end
  end

  describe "باقی امروز, on a day with nothing on it" do
    test "draws its own emptiness rather than the drawing's two rows" do
      texts = with_empty_store(&home_texts/0)

      for row <- Sample.rest_of_today(), literal <- [row.time, row.title, row.meta] do
        refute literal in texts,
               "an empty day silently became the drawing's, so 55 told somebody who has never " <>
                 "opened a calendar to ring their mother at ۲۱:۳۰"
      end

      assert "باقی امروز" in texts,
             "the band stays: 139's whole argument is that the calendar still works"
    end

    test "a real event on today draws instead of it, sub-line in Persian" do
      texts =
        with_empty_store(fn ->
          event_today!("قرار دندان‌پزشکی")
          home_texts()
        end)

      assert "قرار دندان‌پزشکی" in texts

      assert "تقویم" in texts,
             "a row's `:meta` is its sub-line in ENGLISH — `Kati.Calendars.Today.meta/2` at " <>
               "`:fa` is what keeps a real row from ending in an English word under a Persian " <>
               "title"

      refute HomeFa.empty_day() in texts,
             "the empty sentence was drawn over a real appointment, which is the empty state " <>
               "being wrong rather than absent"

      refute "تماس با مامان" in texts
    end
  end

  describe "the transcription this file's absences rest on" do
    test "the Sample still holds the drawing" do
      # Every `refute` above compares against `Kati.Screens.HomeFa.Sample`, so
      # an emptied Sample would make all of them pass over a screen that had
      # lost both branches. This is the same anti-vacuity claim
      # `Kati.ScreenEmptyDatabaseTest`'s `empties/0` makes at the entry point,
      # and `Kati.ScreenDesignLiteralTest.drawn_state/0` renders board 55 out of
      # exactly these functions.
      inbox = Sample.inbox()

      assert inbox.headline != ""
      assert inbox.line != ""
      assert inbox.checked != ""
      refute Enum.empty?(Sample.continue())
      refute Enum.empty?(Sample.rest_of_today())
      refute Sample.sections() |> Enum.map(& &1.meta) |> Enum.reject(&is_nil/1) |> Enum.empty?()

      assert HomeFa.drawn_hero() == inbox,
             "`drawn_hero/0` is the Sample itself, so the board and the transcription cannot " <>
               "be edited apart"
    end

    test "and nothing a render reaches answers with it" do
      empty =
        with_empty_store(fn ->
          %{
            hero: HomeFa.hero_summary(),
            continue: Kati.Screens.Home.continue_watching_rows(),
            metas: Enum.map(HomeFa.tile_rows(), & &1.meta),
            timeline: Kati.Calendars.Today.rows()
          }
        end)

      assert empty == %{hero: nil, continue: [], metas: [nil, nil, nil], timeline: []},
             "a reader answered with a value on an empty store, which is the drawing being " <>
               "handed to a person as their own"
    end
  end

  describe "the emptiness this file rests on" do
    test "the transaction is rolled back, so the rest of the suite keeps its rows" do
      # Every assertion above is a claim about a store with nothing in it, and
      # every such claim is satisfied by a store that was empty to begin with.
      # This one writes first and asks the same question of a row it knows
      # exists — seen outside, unseen inside, there again after.
      {:ok, title} =
        Kati.Media.TrackedTitle
        |> Ash.Changeset.for_create(:create, %{
          source: :manual,
          source_id: "kati:home-fa-empty-state-probe",
          kind: :movie
        })
        |> Ash.create()

      on_exit(fn -> Kati.Repo.query!("DELETE FROM tracked_titles WHERE id = ?1", [title.id]) end)

      assert Ash.get!(Kati.Media.TrackedTitle, title.id)

      inside = with_empty_store(fn -> Ash.read!(Kati.Media.TrackedTitle) end)

      assert inside == [],
             "the deletes did not reach tracked_titles, so nothing above was rendered against " <>
               "an empty store"

      assert Ash.get!(Kati.Media.TrackedTitle, title.id),
             "a row written before the transaction is gone after it rolled back. This module " <>
               "shares one database file with every other test and would be deleting their " <>
               "fixtures"
    end
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  # Everything on board 55 that describes a library, a viewing history or a day
  # this device has never been told about — read off
  # `Kati.Screens.HomeFa.Sample` rather than typed, so a transcription edited
  # there cannot walk out of this list, plus the two eyebrows that go with the
  # bands they head.
  defp invented do
    inbox = Sample.inbox()

    @omitted_when_empty ++
      [inbox.headline, inbox.line, inbox.checked, inbox.action] ++
      Enum.flat_map(Sample.continue(), fn row -> [row.title, row.meta] end) ++
      (Sample.sections() |> Enum.map(& &1.meta) |> Enum.reject(&is_nil/1)) ++
      Enum.flat_map(Sample.rest_of_today(), fn row -> [row.time, row.title, row.meta] end)
  end

  defp with_empty_store(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Enum.each(@emptied, &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  defp home_tree, do: tree(mount_screen(HomeFa))

  defp home_texts, do: texts_of(home_tree())

  defp texts_of(tree) do
    tree
    |> find_all(:text)
    |> Enum.map(&(&1.props[:text] || ""))
    |> Enum.reject(&(&1 == ""))
  end

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

  # ── Fixtures, written INSIDE the rolled-back transaction ────────────────────

  # Both halves of one title, the way `Kati.ScreenHomeEmptyStateTest` writes
  # them: the cache row for what a provider said, the tracked row for what the
  # user did, joined by the `{source, source_id}` value pair rather than by a
  # foreign key.
  defp track!(attrs) do
    source_id = "home-fa-spine:#{System.unique_integer([:positive])}"

    Kati.Media.CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: attrs.kind,
      title: attrs.title,
      episode_count: 8,
      fetched_at: utc_now()
    })
    |> Ash.create!()

    Kati.Media.TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: attrs.kind,
      status: :watching
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
      source_id: "home-fa-episode:#{System.unique_integer([:positive])}",
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

  # One confirmed event on today, in the calendar this call makes for it. The
  # same shape `Kati.ScreenHomeEmptyStateTest` writes: a UTC instant for the
  # range query, the authored wall clock beside it, and the length as a
  # duration.
  defp event_today!(summary) do
    calendar =
      Kati.Calendars.Calendar
      |> Ash.Changeset.for_create(:create, %{
        display_name: "Home fa empty state #{System.unique_integer([:positive])}",
        kind: :local
      })
      |> Ash.create!()

    zone = Kati.Time.device_zone()
    naive = NaiveDateTime.new!(Kati.Time.today(), ~T[09:00:00])
    {:ok, utc} = Kati.Time.to_utc(naive, zone)

    Kati.Calendars.Event
    |> Ash.Changeset.for_create(:create, %{
      uid: "kati-home-fa-empty-#{System.unique_integer([:positive])}@kati",
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

  defp utc_now, do: Kati.Time.now() |> DateTime.shift_zone!("Etc/UTC")
end
