defmodule Kati.ScreenInboxTest do
  @moduledoc """
  Screen 05 reading `Kati.Media` instead of `Kati.Library.Sample`.

  Four claims, and they are separate:

    * **With followed titles, the screen draws their releases.** Every line is a
      column on `Kati.Media.CachedEpisode`, `Kati.Media.CachedSeason` or
      `Kati.Media.CachedTitle`, so each assertion names the string the drawing
      gives that line. The negative assertions name rows that are *only* in the
      Sample module: a screen that quietly fell back would still draw three
      out-now rows and three coming-up ones and pass a bare count.
    * **With nothing followed, it still draws the drawing.** Asserted as map
      equality against `drawn_inbox/0` rather than as "some rows appeared".
    * **The watcher card reads what screen 25 writes.** It was the last frozen
      thing on the page — `Watching for 24 titles · last checked 18:02 · every
      6h` on every device, one tap from a screen that said *Watching 2 titles*
      and *never checked*. The count rides on the same `:followed` list the two
      sections do, and the mono line is `Kati.Settings.Watcher`'s, which board
      314 built. A reader who picks **Daily** is told daily.
    * **`Kati.Media.Release` decides every date and every bell.** A bare year
      never becomes a row, a muted show never arms, and neither rule is
      re-implemented here — this file only checks that the screen honours the
      answers rather than comparing dates for itself.

  ## The shared database

  `test/test_helper.exs` gives the whole suite one SQLite file, so "nothing
  followed" has to be made rather than assumed — the same reason
  `Kati.ScreenUpNextTest` empties its tables in `setup`.
  Both directions matter: the wipe before makes the fallback test mean
  something, and the wipe after keeps `Kati.ScreenDesignLiteralTest` mounting
  screen 05 against an empty library, which is what lets it find the drawing's
  own copy.
  """
  use Mob.ScreenCase, async: false

  require Ash.Query

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Inbox

  # Child first: a watch carries the only foreign key in the domain.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_episodes cached_seasons cached_titles)

  @day 24 * 60 * 60

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "a library with nothing followed" do
    test "answers board 260 rather than the drawing" do
      # It answered `drawn_inbox/0` — the drawing's three coming-up rows and
      # `Kati.Library.Sample`'s out-now rows — so the one page whose job is to
      # say what is new opened, on a fresh install, on three things that were
      # not. Board 260 is the state it draws instead;
      # `Kati.ScreenInboxEmptyTest` holds that board's own copy.
      refute Inbox.releases()
      assert Inbox.inbox().nothing_followed?
      refute Inbox.inbox() == Inbox.drawn_inbox()
    end

    test "and draws none of the lines frame 05 holds" do
      words = text(tree(mount_screen(Inbox)))
      drawn = Inbox.drawn_inbox()

      # The name survives — board 260 keeps it, and it is what
      # `Kati.ScreenEmptyDatabaseTest` quotes for this screen.
      assert words =~ "New releases"

      refute words =~ "3 out now · 3 coming up"

      for row <- drawn.out_now ++ drawn.coming_up do
        refute words =~ row.title,
               "screen 05 drew #{row.title} — a release out of the drawing that nobody follows"
      end
    end

    test "and board 05's own lines are still checked, in the state that board draws" do
      # Not lost with the fallback: `drawn_inbox/0` is what
      # `Kati.ScreenDesignLiteralTest.drawn_state/0` installs for board 05, so
      # every literal on that frame is still compared — against the page in the
      # state a reader reaches once they follow something.
      drawn = Inbox.drawn_inbox()

      assert length(drawn.out_now) == 3
      assert length(drawn.coming_up) == 3
    end

    test "a followed title with nothing scheduled still draws the drawing" do
      # The gate is `:followed` being empty, not either list being empty — but a
      # library whose titles have no cached episodes at all reaches neither, and
      # this is the shape that would render two empty sections if the gate were
      # written the other way round.
      track!(%{title: "Tidewrack", kind: :tv})

      assert Inbox.inbox().out_now == []
      assert Inbox.inbox().coming_up == []
      refute Inbox.inbox() == Inbox.drawn_inbox()
    end
  end

  describe "out now" do
    setup :seed_releases

    test "is the episodes that have aired, newest first, unticked" do
      rows = Inbox.inbox().out_now

      assert Enum.map(rows, & &1.line) == [
               "S2 E6 — Ash and After",
               "S2 E4 — Saltmarsh"
             ]
    end

    test "carries the show's own name and poster seed" do
      row = hd(Inbox.inbox().out_now)

      assert row.title == "Tidewrack"
      assert row.seed == "hollow71"
      assert row.dot == Kati.Theme.Palette.accent()
    end

    test "says how long an episode is and when it went out" do
      [today, older] = Inbox.inbox().out_now

      # An episode from earlier today is placed by its hour, which is the
      # drawing's own `48 min · aired 20:00` less the service it cannot name.
      assert today.meta == "48 min · aired 00:00"

      # An older one is placed by its day: an hour with no date is only useful
      # while the date is obvious.
      assert older.meta == "51 min · aired " <> day_month(-3)
    end

    test "leaves out an episode the user has already ticked" do
      refute Enum.any?(Inbox.inbox().out_now, &(&1.line =~ "Hollow Season"))
    end

    test "leaves out an episode older than the window" do
      refute Enum.any?(Inbox.inbox().out_now, &(&1.line =~ "Nightjar"))
    end

    test "leaves out a title the user is not following" do
      # `:dropped` is excluded by `TrackedTitle`'s own `:followed` action — this
      # screen does not get a second opinion about what it watches.
      refute Enum.any?(Inbox.inbox().out_now, &(&1.title == "Harbour"))
    end

    test "counts what it drew" do
      assert Inbox.inbox() |> Map.fetch!(:out_now) |> length() == 2
    end
  end

  describe "coming up" do
    setup :seed_releases

    test "lists episodes, season drops and films together, soonest first" do
      rows = Inbox.inbox().coming_up

      assert Enum.map(rows, & &1.title) == [
               "Tidewrack — S2E7",
               "Vellum",
               "Tidewrack — Season 3"
             ]
    end

    test "dates each row from Kati.Media.Release, in the device's own zone" do
      [episode, film, season] = Inbox.inbox().coming_up

      assert episode.month == month(5)
      assert episode.day == day(5)
      assert film.day == day(10)
      assert season.day == day(20)
    end

    test "puts the episode's own name and hour on the line it cannot fill" do
      [episode, film, season] = Inbox.inbox().coming_up

      # `Lumen+ · 20:00` less the service: the name is the one thing on this row
      # a provider does supply.
      assert episode.line =~ ~r/^The Undertow · \d{2}:\d{2}$/

      # A film's `In cinemas` and a season's `Full season drop` are both
      # availability and release pattern, and neither has a column.
      assert film.line =~ ~r/^\d{2}:\d{2}$/
      assert season.line == ""
    end

    test "arms the bell only where an alarm could actually be set" do
      [episode, film, season] = Inbox.inbox().coming_up

      assert episode.armed, "an exact future airing on an unmuted show must arm"
      assert season.armed, "a day-precision season drop must arm"

      refute film.armed,
             "the film's show is muted, and a muted row draws the hollow bell " <>
               "even though its date is exact"
    end

    test "refuses a date Kati.Media.Release will not name" do
      refute Enum.any?(Inbox.inbox().coming_up, &(&1.title =~ "Marram")),
             "a bare-year release has no day at all, and this card's left edge is a day"
    end

    test "gives a series no title-level row of its own" do
      # `next_release_at` on a series restates its next episode, so counting it
      # would draw the same airing twice.
      assert Enum.count(Inbox.inbox().coming_up, &(&1.title =~ "Tidewrack")) == 2
    end

    test "counts what it drew" do
      assert Inbox.inbox() |> Map.fetch!(:coming_up) |> length() == 3
    end
  end

  describe "the watcher card" do
    setup :seed_releases

    test "counts the titles the watcher actually watches" do
      # Three followed: Tidewrack, Vellum and Marram. Harbour is `:dropped`,
      # which `Kati.Media.TrackedTitle`'s own `:followed` action excludes —
      # this screen does not get a second opinion about what it watches.
      assert Inbox.inbox().watching == 3

      assert Inbox.inbox().watching == Inbox.followed_count(),
             "the banner on screen 25 and the inbox it is a banner FOR are counting " <>
               "different things"

      words = text(tree(mount_screen(Inbox)))
      assert words =~ "Watching for 3 titles"

      refute words =~ "Watching for 24 titles",
             "the card still says 24 on a phone that follows three"
    end

    test "says when a check last completed and how often, from the store screen 25 writes" do
      # `Mob.ScreenCase` starts `Mob.State` empty, so this is a fresh install.
      assert Inbox.inbox().last_checked == "never checked · every 6h"

      refute text(tree(mount_screen(Inbox))) =~ "last checked 18:02",
             "board 05's frozen evening is still on the card"

      Kati.Settings.Watcher.put_cadence("Daily")
      Kati.Settings.Watcher.checked!()

      assert Inbox.inbox().last_checked == "checked just now · daily",
             "a reader who set Daily on screen 25 is still told every 6h one tap away"

      assert text(tree(mount_screen(Inbox))) =~ "checked just now · daily"
    end

    test "and screen 25's own line says the same thing" do
      # One store, two readers. The whole finding was that these two disagreed.
      Kati.Settings.Watcher.put_cadence("Hourly")

      assert Inbox.inbox().last_checked =~ "hourly"
      assert Kati.Settings.Watcher.cadence() == "Hourly"
    end
  end

  describe "a title whose cache row was evicted" do
    setup do
      tracked = track!(%{title: nil, kind: :tv})
      episode!(tracked, %{season: 1, episode: 2, title: "Ash and After", runtime: 48, hours: -2})
      :ok
    end

    test "keeps the release and says the name is gone" do
      row = hd(Inbox.inbox().out_now)

      assert row.title == "Untitled"
      assert row.seed == nil
      assert row.line == "S1 E2 — Ash and After"
    end
  end

  describe "the rendered screen" do
    setup :seed_releases

    test "draws the rows, and none of the sample module's own" do
      words = text(tree(mount_screen(Inbox)))

      assert words =~ "Tidewrack"
      assert words =~ "S2 E6 — Ash and After"
      assert words =~ "Tidewrack — S2E7"
      assert words =~ String.upcase("Out now · 2")
      assert words =~ "2 out now · 3 coming up"

      # All of these are in the drawn inbox and in none of these rows. A screen
      # that fell back would still draw a full page and pass every count above.
      refute words =~ "Blue Hour"
      refute words =~ "Paper Cities"
      refute words =~ "The Cartographer"
      refute words =~ "In cinemas"
      refute words =~ "Full season drop"
      refute words =~ "LUMEN+"
    end

    test "draws one poster per out-now row" do
      images = find_all(tree(mount_screen(Inbox)), :image)

      assert length(images) == 2
      assert Enum.all?(images, &(&1.props[:width] == 44))
    end
  end

  # ── fixtures ───────────────────────────────────────────────────────────────

  # One followed series with a week of history and a fortnight of schedule, one
  # muted film, one dropped title and one title whose only date is a bare year.
  describe "the three controls that were drawn without taps" do
    setup :seed_releases

    test "Mark all writes one tick per Out now row, and the section empties" do
      socket = mount_screen(Inbox).socket
      before = length(socket.assigns.inbox.out_now)

      assert before > 0

      {:noreply, marked} = Inbox.handle_tap(:mark_all, socket)

      assert marked.assigns.inbox.out_now == []
      assert length(Ash.read!(Watch)) == before + 1, "the seeded tick is still there"
    end

    test "and the subtitle recounts with it" do
      socket = mount_screen(Inbox).socket
      {:noreply, marked} = Inbox.handle_tap(:mark_all, socket)

      assert inspect(Inbox.title(marked.assigns.inbox), limit: :infinity) =~ "0 out now"
    end

    test "Watch on one row ticks that episode and leaves the others" do
      socket = mount_screen(Inbox).socket
      row = hd(socket.assigns.inbox.out_now)

      {:noreply, ticked} = Inbox.handle_tap(String.to_atom("watch_" <> row.source_id), socket)

      refute Enum.any?(ticked.assigns.inbox.out_now, &(&1.source_id == row.source_id))
      assert length(ticked.assigns.inbox.out_now) == length(socket.assigns.inbox.out_now) - 1
    end

    test "and the tick records the season and number the show uses" do
      socket = mount_screen(Inbox).socket
      row = Enum.find(socket.assigns.inbox.out_now, &(&1.line =~ "Ash and After"))

      {:noreply, _ticked} = Inbox.handle_tap(String.to_atom("watch_" <> row.source_id), socket)

      written = Ash.read!(Watch) |> Enum.find(&(&1.episode_source_id == row.source_id))

      assert written.season_number == 2
      assert written.episode_number == 6
    end

    test "the gear on the cream card opens screen 25" do
      socket = mount_screen(Inbox).socket

      {:noreply, pushed} = Inbox.handle_tap(:open_watcher, socket)

      assert {:push, Kati.Screens.ReleaseWatcher, %{back: "Inbox"}} =
               Map.get(pushed.__mob__, :nav_action)
    end

    test "and a tag naming no row on the page changes nothing" do
      socket = mount_screen(Inbox).socket

      {:noreply, after_tap} = Inbox.handle_tap(:watch_nothing, socket)

      assert after_tap.assigns.inbox == socket.assigns.inbox
    end
  end

  describe "a followed show with an episode airing today" do
    setup do
      show = track!(%{title: "Tidewrack", seed: "hollow71", kind: :tv})
      episode!(show, %{season: 1, episode: 3, title: "Low Water", runtime: 44, midnight: true})
      :ok
    end

    test "is on screen 05, read from CachedEpisode.air_at" do
      words = text(tree(mount_screen(Inbox)))

      assert words =~ "Tidewrack"
      assert words =~ "S1 E3 — Low Water"
      assert words =~ "1 out now · 0 coming up"
    end

    test "and Home's New this week hero announces it" do
      :ok = Kati.Sections.put(Kati.Sections.all())

      assert %{count: 1} = Kati.Screens.Home.hero_summary()

      texts =
        mount_screen(Kati.Screens.Home)
        |> tree()
        |> find_all(:text)
        |> Enum.map(&(&1.props[:text] || ""))

      assert "NEW THIS WEEK" in texts
      assert "1 new episode" in texts
    end

    test "and neither says anything once New episodes is switched off" do
      Kati.Settings.Watcher.put_kind(:new_episodes, true)
      Kati.Settings.Watcher.put_kind(:premieres, false)

      assert length(Inbox.inbox().out_now) == 1, "episode 3 is not a premiere"

      Kati.Settings.Watcher.put_kind(:premieres, true)
      Kati.Settings.Watcher.put_kind(:new_episodes, false)

      assert Inbox.inbox().out_now == []
      assert Kati.Screens.Home.hero_summary() == nil
    end
  end

  describe "the same three over the drawing" do
    test "carry no taps, because the board's rows have no episode behind them" do
      drawn = Inbox.drawn_inbox()

      assert Inbox.tickable(drawn) == []
      assert Enum.all?(drawn.out_now, &(Inbox.watch_tap(&1) == nil))
      refute inspect(Inbox.mark_all(drawn), limit: :infinity) =~ "mark_all"
    end

    test "and Mark all is drawn without a tap on an inbox with nothing out now" do
      # Not the same as inert: there is nothing to mark all OF, which is the
      # smallest case of the gesture rather than a failure of it.
      refute inspect(Inbox.mark_all(%{out_now: []}), limit: :infinity) =~ "mark_all"
    end
  end

  defp seed_releases(_context) do
    series = track!(%{title: "Tidewrack", seed: "hollow71", kind: :tv})

    # Midnight in the device's own zone, so "earlier today" is true whatever
    # hour the suite runs at: a fixed offset back from now crosses into
    # yesterday for the first hours of every day, which is the same class of bug
    # `Kati.ScreenDateTest` exists for.
    episode!(series, %{
      season: 2,
      episode: 6,
      title: "Ash and After",
      runtime: 48,
      midnight: true
    })

    ticked =
      episode!(series, %{
        season: 2,
        episode: 5,
        title: "Hollow Season",
        runtime: 47,
        days: -1
      })

    episode!(series, %{
      season: 2,
      episode: 4,
      title: "Saltmarsh",
      runtime: 51,
      days: -3
    })

    # Older than the seven-day window this screen reads "now" as.
    episode!(series, %{season: 2, episode: 3, title: "Nightjar", runtime: 50, days: -30})

    episode!(series, %{
      season: 2,
      episode: 7,
      title: "The Undertow",
      runtime: 55,
      days: 5
    })

    tick!(series, ticked)

    # A series carries a `next_release_at` of its own, and it must NOT become a
    # fourth coming-up row: on a series that column restates the next episode,
    # which is already listed.
    release!(series, %{days: 5, confidence: :exact})

    season!(series, %{number: 3, name: nil, days: 20, confidence: :day})

    # A film, muted: its date is exact and its bell must still be hollow.
    film = track!(%{title: "Vellum", kind: :movie, notify: false})
    release!(film, %{days: 10, confidence: :exact})

    # A bare year: displayable, never armable, and never a dated row.
    vague = track!(%{title: "Marram", kind: :movie})
    release!(vague, %{days: 40, confidence: :year})

    # Dropped, so `:followed` excludes it however new its episode is.
    dropped = track!(%{title: "Harbour", kind: :tv, status: :dropped})
    episode!(dropped, %{season: 1, episode: 1, title: "Landfall", runtime: 44, hours: -1})

    :ok
  end

  # Both halves of one title. The cache row is written only when the fixture
  # names a title — a `nil` title is the evicted case, and there the durable row
  # stands alone exactly as `Kati.Media.CachedTitle`'s moduledoc promises.
  defp track!(attrs) do
    source_id = "inbox:#{System.unique_integer([:positive])}"

    if attrs[:title] do
      CachedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: source_id,
        kind: attrs.kind,
        title: attrs[:title],
        poster_path: attrs[:seed],
        fetched_at: now()
      })
      |> Ash.create!()
    end

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: attrs.kind,
      status: attrs[:status] || :watching,
      notify_new_episodes: Map.get(attrs, :notify, true)
    })
    |> Ash.create!()
  end

  defp episode!(%TrackedTitle{} = tracked, attrs) do
    source_id = "episode:#{System.unique_integer([:positive])}"

    CachedEpisode
    |> Ash.Changeset.for_create(:create, %{
      source: tracked.source,
      source_id: source_id,
      title_source_id: tracked.source_id,
      season_number: attrs[:season],
      episode_number: attrs[:episode],
      title: attrs[:title],
      runtime_minutes: attrs[:runtime],
      air_at: at(attrs),
      date_confidence: attrs[:confidence] || :exact,
      fetched_at: now()
    })
    |> Ash.create!()

    source_id
  end

  defp season!(%TrackedTitle{} = tracked, attrs) do
    CachedSeason
    |> Ash.Changeset.for_create(:create, %{
      source: tracked.source,
      title_source_id: tracked.source_id,
      season_number: attrs.number,
      name: attrs[:name],
      air_at: at(attrs),
      date_confidence: attrs[:confidence] || :exact,
      fetched_at: now()
    })
    |> Ash.create!()
  end

  # A film's own date, on the cache row the tracked row already points at.
  defp release!(%TrackedTitle{} = tracked, attrs) do
    CachedTitle
    |> Ash.Query.filter(source == ^tracked.source and source_id == ^tracked.source_id)
    |> Ash.read_one!()
    |> Ash.Changeset.for_update(:update, %{
      next_release_at: at(attrs),
      date_confidence: attrs.confidence
    })
    |> Ash.update!()
  end

  defp tick!(%TrackedTitle{} = tracked, episode_source_id) do
    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      episode_source_id: episode_source_id,
      watched_at: now()
    })
    |> Ash.create!()
  end

  # ── clocks ─────────────────────────────────────────────────────────────────

  defp now, do: Kati.Time.now() |> DateTime.shift_zone!("Etc/UTC")

  defp at(%{midnight: true}), do: midnight()

  defp at(attrs) do
    seconds = (attrs[:days] || 0) * @day + (attrs[:hours] || 0) * 60 * 60
    DateTime.add(now(), seconds, :second)
  end

  # The start of the device's own day. `Kati.Time.to_utc/2` rather than a naive
  # subtraction because a midnight that falls in a DST gap has no instant, and
  # that module is where the app already knows it.
  defp midnight do
    zone = Kati.Time.device_zone()
    {:ok, at} = Kati.Time.to_utc(NaiveDateTime.new!(Kati.Time.today(), ~T[00:00:00]), zone)
    at
  end

  defp local(days) do
    Kati.Time.now() |> DateTime.add(days * @day, :second) |> DateTime.to_date()
  end

  defp day(days), do: local(days) |> Calendar.strftime("%d")
  defp month(days), do: local(days) |> Calendar.strftime("%b") |> String.upcase()
  defp day_month(days), do: local(days) |> Calendar.strftime("%-d %b")

  defp empty_the_tables! do
    for table <- @tables,
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end
end
