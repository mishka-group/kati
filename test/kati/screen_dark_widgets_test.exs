defmodule Kati.ScreenDarkWidgetsTest do
  @moduledoc """
  Screen 28 — the design's drawn-dark Home — against the domains it now reads,
  and against a database that has nothing to give it.

  Screen 29, the lock screen, shared this file until it was deleted; its board
  is in `test/design/retired/`.

  ## What this screen is, and what that constrains

  It is the reference the whole dark palette was derived from, so two things
  are true at once and both are asserted here:

    * **the palette does not move.** It installs `Kati.Theme.dark/0` in
      `mount/3` regardless of the stored preference, and
      `Kati.ThemeModeTest`/`Kati.ThemeCoverageTest` already stand over that.
      This file's contribution is the other direction — that reading the store
      did not quietly make it follow the app theme — asserted once, cheaply.
    * **the clock does not move either.** Screen 28's date line and greeting
      stay the drawing's evening on a device full of data. That is a decision,
      written out in `Kati.Screens.HomeDark`'s moduledoc, and a later round that
      "finishes the migration" by wiring the clock should fail here rather than
      cost `Kati.ScreenDesignLiteralTest` allow-list entries it has no room for.

  ## Why the sweeps cannot settle the rest

  Same gap `Kati.ScreenFilmTest` and `Kati.ScreenEmptyDatabaseTest` set out:
  `Kati.ScreenRenderSweepTest` never reads the copy, and
  `Kati.ScreenDesignLiteralTest` reads it against a shared SQLite file with no
  Ecto sandbox, so which of the two paths ran moves with `--seed`.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.Event
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.HomeDark

  # Child tables first: overrides and events carry the foreign keys, and a watch
  # carries one to its tracked title.
  @tables ~w(event_occurrence_overrides events calendars calendar_accounts media_watches media_content_warnings tracked_titles cached_titles cached_episodes)

  setup do
    installed = Mob.Theme.current()
    empty_the_tables!()

    on_exit(fn ->
      empty_the_tables!()
      Mob.Theme.set(installed)
    end)

    :ok
  end

  # What this module writes is not inert — a tracked title left behind is a
  # stranger's row on screen 03's grid, and an event left behind is a stranger's
  # evening on screen 01. Same reasoning and the same `on_exit` as
  # `Kati.ScreenCalendarsTest`.
  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  # ── Fixtures ────────────────────────────────────────────────────────────────

  defp calendar! do
    CalendarRow
    |> Ash.Changeset.for_create(:create, %{
      display_name: "Dark #{System.unique_integer([:positive])}",
      kind: :local
    })
    |> Ash.create!()
  end

  # An event at a given wall-clock time **today, in the device's own zone**,
  # which is the question `Kati.Calendars.Today` asks. Built through
  # `Kati.Time.to_utc/2` rather than by naming a UTC instant, so the fixture
  # lands on today's timeline wherever the machine running this thinks it is.
  defp event!(cal, time, summary) do
    zone = Kati.Time.device_zone()
    {:ok, utc} = Kati.Time.to_utc(NaiveDateTime.new!(Kati.Time.today(), time), zone)

    Event
    |> Ash.Changeset.for_create(:create, %{
      uid: "dark-#{System.unique_integer([:positive])}@kati",
      calendar_id: cal.id,
      origin: :kati,
      summary: summary,
      dtstart_utc: utc,
      # `"YYYYMMDDTHHMMSS"` — the authored wall clock, which is what the resource
      # stores and what keeps a 09:15 event at 09:15 across a DST boundary.
      dtstart_wall:
        Calendar.strftime(NaiveDateTime.new!(Kati.Time.today(), time), "%Y%m%dT%H%M%S")
    })
    |> Ash.create!()
  end

  defp track!(source_id, tracked_attrs, cached_attrs) do
    if cached_attrs do
      CachedTitle
      |> Ash.Changeset.for_create(
        :create,
        Map.merge(
          %{source: :tmdb, source_id: source_id, kind: :tv, fetched_at: DateTime.utc_now()},
          cached_attrs
        )
      )
      |> Ash.create!()
    end

    TrackedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{source: :tmdb, source_id: source_id, kind: :tv}, tracked_attrs)
    )
    |> Ash.create!()
  end

  defp episode!(title_source_id, attrs) do
    CachedEpisode
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: :tmdb,
          source_id: "ep-#{System.unique_integer([:positive])}",
          title_source_id: title_source_id,
          season_number: 1,
          episode_number: 1,
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp watch!(tracked, attrs) do
    Watch
    |> Ash.Changeset.for_create(:create, Map.put(attrs, :tracked_title_id, tracked.id))
    |> Ash.create!()
  end

  defp texts(tree), do: tree |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  defp drawn?(tree, string), do: Enum.any?(texts(tree), &(&1 == string))

  # Every tag the tree emits an `accessibility_id` for. `Mob.Renderer` derives
  # one from each `{pid, atom}` `on_tap`, and `onNodeWithTag` throws on the
  # second match, so a repeat here is two controls no device test can address.
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

  # ── Screen 28 ───────────────────────────────────────────────────────────────

  describe "28 — Home in dark" do
    # ## These four assertions are INVERTED from what they were, and the
    # ## inversion is the defect
    #
    # They used to read *an empty calendar draws the drawing's evening, to the
    # term* and *the hero and the continue rail are still the drawing's*, and
    # both were true statements about a screen that fabricated its user's
    # content: with nothing stored, screen 28 announced `3 new episodes are
    # waiting`, drew two half-watched shows nobody had started, and told a
    # device whose calendar Kati had never seen to ring their mother at 21:30.
    # That is #91, one colourway over, and the sentence
    # `Kati.Screens.HomeDark`'s own moduledoc has always carried is what forces
    # it here too: *two pages that are the same page must not disagree about
    # which half of themselves is real*. Screen 01's bands became reads, so
    # these did.
    #
    # Nothing is dropped in the inversion. Each of the old assertions becomes a
    # PAIR — the empty store draws none of it, the transcription still holds it,
    # and a real fixture draws the real thing — which is strictly more than the
    # single presence claim it replaces. `Kati.ScreenHomeEmptyStateTest` is the
    # same shape for screen 01, and `Kati.ScreenEmptyDatabaseTest`'s `empties/0`
    # holds the entry-point half against a database it empties itself.

    test "an empty calendar says so in screen 139's words, not the drawing's evening" do
      assert Kati.Calendars.Today.rows() == [],
             "the calendar answered rows, so nothing below is measuring the empty branch"

      tree = tree(mount_screen(HomeDark))

      for row <- HomeDark.Sample.rest_of_today() do
        refute drawn?(tree, row.time),
               "#{inspect(row.time)} is the drawing's, on a device with nothing mirrored"

        refute drawn?(tree, row.title),
               "#{inspect(row.title)} is the drawing's, on a device with nothing mirrored"

        refute drawn?(tree, row.meta),
               "#{inspect(row.meta)} is the drawing's, on a device with nothing mirrored"
      end

      assert drawn?(tree, "Nothing scheduled — add anything with +"),
             "an empty day has to say what is missing and name the one control that fixes it " <>
               "— screen 96's rule — and screen 139 is the board that words this state. The " <>
               "`+` is the FAB `Kati.Screens.HomeDark.dock/0` draws over this page"

      # Board 315 is the dark 139 this screen's moduledoc used to say did not
      # exist, so the band that stays is 139's own rather than 28's: *The
      # calendar still works* over the same card, in the words the board that
      # draws this state uses.
      assert drawn?(tree, "THE CALENDAR STILL WORKS"),
             "the band stays: 139's whole argument is that the calendar still works"

      refute drawn?(tree, "REST OF TODAY"),
             "REST OF TODAY is board 28's eyebrow over its own timeline, and this page is 139"

      assert drawn?(tree, "Nothing chosen yet"),
             "board 315 is the dark 139, and a device with nothing kept is on it"

      assert drawn?(tree, "Choose sections")
    end

    test "and the drawing's evening is still there for the board to be compared against" do
      # The other half of the pair, and the one that stops the absences above
      # going vacuous: an emptied `Sample` would satisfy every `refute` in this
      # describe block. `Kati.ScreenDesignLiteralTest.drawn_state/0` renders
      # board 28 out of exactly these three functions.
      refute Enum.empty?(HomeDark.Sample.rest_of_today())
      refute Enum.empty?(HomeDark.Sample.continue())
      refute Enum.empty?(HomeDark.drawn_hero().headline)

      assert HomeDark.drawn_hero().sub,
             "`One premiere · two titles leave Lumen+ on Friday` is the board's, and " <>
               "`drawn_hero/0` is where it lives now that no device can reach it"

      assert HomeDark.drawn_hero().checked,
             "`last check 18:02` likewise — `Kati.Screens.Inbox` records that nothing stores " <>
               "when the watcher last swept"
    end

    test "a mirrored calendar draws the device's day and none of the drawn rows" do
      cal = calendar!()
      event!(cal, ~T[09:15:00], "Plumber")
      event!(cal, ~T[21:05:00], "Rowing")

      tree = tree(mount_screen(HomeDark))

      assert drawn?(tree, "Plumber")
      assert drawn?(tree, "Rowing")

      refute drawn?(tree, "Nothing scheduled — add anything with +"),
             "the empty sentence was drawn over a real day, which is the empty state being " <>
               "wrong rather than absent"

      for row <- HomeDark.Sample.rest_of_today() do
        refute drawn?(tree, row.title),
               "#{inspect(row.title)} is the drawing's, and a real day is being shown"
      end
    end

    test "the header stays the drawing's evening even with a real day under it" do
      # A decision, not an omission — `Kati.Screens.HomeDark`'s moduledoc gives
      # the reason: two more clock literals would cost
      # `Kati.ScreenDesignLiteralTest` two allow-list entries it has no room
      # for.
      #
      # `last check 18:02` is no longer part of that bargain and is asserted
      # below instead: it sat in the hero rather than the header, and it is not
      # a frozen clock standing in for a device value — nothing anywhere records
      # when the release watcher last swept, so there is no value for it to
      # stand in for.
      cal = calendar!()
      event!(cal, ~T[09:15:00], "Plumber")

      moment = HomeDark.Sample.moment()
      tree = tree(mount_screen(HomeDark))

      assert drawn?(tree, String.upcase(moment.date))
      assert drawn?(tree, moment.greeting)
    end

    test "the hero and the continue rail are reads now, exactly as Home's are" do
      # The inversion this describe block's preamble is about. Screen 28 reads
      # what screen 01 reads and no more, and what 01 reads is now every band.
      cal = calendar!()
      event!(cal, ~T[09:15:00], "Plumber")

      inbox = HomeDark.Sample.inbox()
      tree = tree(mount_screen(HomeDark))

      for line <- inbox.headline do
        refute drawn?(tree, line),
               "#{inspect(line)} counts episodes of shows nobody follows on this device"
      end

      refute drawn?(tree, inbox.sub)
      refute drawn?(tree, HomeDark.Sample.moment().last_check)

      refute drawn?(tree, inbox.cta),
             "the hero's button is drawn with the hero, and a band with nothing to announce " <>
               "is omitted eyebrow and all"

      refute drawn?(tree, "NEW THIS WEEK"),
             "a section label over an omitted section is a heading for nothing"

      refute drawn?(tree, "CONTINUE WATCHING")

      for row <- HomeDark.Sample.continue() do
        refute drawn?(tree, row.title),
               "#{inspect(row.title)} is a show nobody added, drawn in the shape of one they did"

        refute drawn?(tree, row.meta)
      end

      assert HomeDark.hero_summary() == nil
      assert Kati.Screens.Home.continue_watching_rows() == []
    end

    test "one episode really out this week brings the hero back, in the singular" do
      # The presence half. An absence test alone passes on a band that answers
      # `nil` unconditionally, which is a different way of drawing nothing.
      tracked = track!("dark-hero", %{status: :watching}, %{title: "Marram Lights"})

      episode!(tracked.source_id, %{
        air_at: DateTime.add(DateTime.utc_now(), -2 * 24 * 60 * 60, :second),
        date_confidence: :exact,
        season_number: 1,
        episode_number: 4
      })

      tree = tree(mount_screen(HomeDark))

      assert drawn?(tree, "NEW THIS WEEK")
      assert drawn?(tree, "1 new episode"), "the count is real, so one episode is one episode"
      assert drawn?(tree, "is waiting"), "and the verb has to agree with it"
      assert drawn?(tree, HomeDark.Sample.inbox().cta)

      refute drawn?(tree, "3 new episodes"),
             "the drawing's own count came back beside a real one"

      refute drawn?(tree, HomeDark.Sample.inbox().sub),
             "availability needs a subscribed service to count down from — screen 96 — and no " <>
               "column holds it"
    end

    test "the bell and the hero are two names, so a device test can address either" do
      # Both were `:inbox`. The sweeps never saw it: they render an empty
      # store, where 28 draws board 315's page — a settings disc, no bell, no
      # hero. It takes a real episode to bring both nodes back, which is what
      # this fixture is.
      tracked = track!("dark-inbox-tags", %{status: :watching}, %{title: "Marram Lights"})

      episode!(tracked.source_id, %{
        air_at: DateTime.add(DateTime.utc_now(), -2 * 24 * 60 * 60, :second),
        date_confidence: :exact,
        season_number: 1,
        episode_number: 4
      })

      tags = tap_tags(tree(mount_screen(HomeDark)))

      assert :notifications in tags, "the header bell carries screen 01's name for a bell"
      assert :open_inbox in tags, "the hero's Open inbox button carries screen 01's name for it"

      assert tags == Enum.uniq(tags),
             "28 gives one name to two nodes, and `onNodeWithTag` throws on the second " <>
               "match: #{inspect(tags -- Enum.uniq(tags))}"
    end

    test "and each opens what screen 01's own opens" do
      socket = mount_screen(HomeDark).socket

      assert {:noreply, bell} = HomeDark.handle_info({:tap, :notifications}, socket)
      assert bell.__mob__.nav_action == {:push, Kati.Screens.InboxNotifications, %{}}

      assert {:noreply, hero} = HomeDark.handle_info({:tap, :open_inbox}, socket)
      assert hero.__mob__.nav_action == {:push, Kati.Screens.Inbox, %{}}
    end

    test "a title part-way through draws its own card and none of the drawing's two" do
      tracked = track!("dark-shelf", %{status: :watching}, %{title: "Marram Lights"})
      watch!(tracked, %{episode_source_id: "episode:marram-1", watched_at: DateTime.utc_now()})

      tree = tree(mount_screen(HomeDark))

      assert drawn?(tree, "CONTINUE WATCHING")
      assert drawn?(tree, "Marram Lights"), "the shelf has a title on it and 28 drew none"

      refute drawn?(tree, "The Long Hollow"),
             "a real card came up beside the drawing's two rather than instead of them"

      refute drawn?(tree, "S2 · E6 · 18m left"),
             "nothing writes `progress_season`, `progress_episode` or `progress_seconds`, so a " <>
               "real card has no bookmark line and must not borrow the drawing's"
    end

    test "a card at either end of the bar renders rather than throwing" do
      # `0.0` and `1.0` were unreachable while the row came from
      # `Sample.continue/0` — `0.62` and `0.24` are both safely inside the range
      # — and they are reachable from the first real shelf row: a title marked
      # *watching* with no tick against it is `0.0`, which is the ordinary state
      # of a show somebody has just added. The hand-rolled two-Box bar wrote
      # `weight: 0.0` onto one node or the other at each end, and Compose throws
      # on a zero weight rather than warning.
      for progress <- [0.0, 1.0, nil] do
        row = %{title: "Marram Lights", meta: nil, progress: progress, seed: nil}

        assert %{} = HomeDark.watch_card(row),
               "the dark continue card cannot draw progress #{inspect(progress)}"
      end
    end

    test "reading the calendar did not make it follow the app theme" do
      Kati.Theme.Mode.put(:light)
      _view = mount_screen(HomeDark)

      assert Mob.Theme.current() == Kati.Theme.dark(),
             "screen 28 is the design's dark reference and went light in a light app"
    end
  end
end
