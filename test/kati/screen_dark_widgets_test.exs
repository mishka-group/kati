defmodule Kati.ScreenDarkWidgetsTest do
  @moduledoc """
  Screens 28 and 29 — the design's only drawn-dark pages — against the domains
  they now read, and against a database that has nothing to give them.

  ## What these two screens are, and what that constrains

  They are the reference the whole dark palette was derived from, so two things
  are true at once and both are asserted here:

    * **the palette does not move.** Both install `Kati.Theme.dark/0` in
      `mount/3` regardless of the stored preference, and
      `Kati.ThemeModeTest`/`Kati.ThemeCoverageTest` already stand over that.
      This file's contribution is the other direction — that reading the store
      did not quietly make them follow the app theme — asserted once, cheaply.
    * **the clock does not move either.** Screen 28's date line and greeting and
      screen 29's `21:40` stay the drawing's evening on a device full of data.
      That is a decision, written out in both moduledocs, and a later round that
      "finishes the migration" by wiring the clock should fail here rather than
      break the pairing between the two pages and cost
      `Kati.ScreenDesignLiteralTest` three allow-list entries.

  ## Why the sweeps cannot settle the rest

  Same gap `Kati.ScreenFilmTest` and `Kati.ScreenEmptyDatabaseTest` set out:
  `Kati.ScreenRenderSweepTest` never reads the copy, and
  `Kati.ScreenDesignLiteralTest` reads it against a shared SQLite file with no
  Ecto sandbox, so which of the two paths ran moves with `--seed`. Screen 29
  needs more than that anyway — it falls back **one widget at a time**, and no
  whole-screen check can tell three fallen-back widgets from four.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.Event
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.HomeDark
  alias Kati.Screens.Lock

  # Child tables first: overrides and events carry the foreign keys, and a watch
  # carries one to its tracked title.
  @tables ~w(
    event_occurrence_overrides events calendars calendar_accounts
    media_watches tracked_titles cached_titles cached_episodes
  )

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

  # ── Screen 28 ───────────────────────────────────────────────────────────────

  describe "28 — Home in dark" do
    test "an empty calendar draws the drawing's evening, to the term" do
      assert Kati.Calendars.Today.rows() == [],
             "the calendar answered rows, so nothing below is measuring the fallback"

      assert HomeDark.rest_of_today([]) ==
               HomeDark.rest_of_today(HomeDark.Sample.rest_of_today()),
             "the `[]` clause is not `Kati.Screens.HomeDark.Sample.rest_of_today/0`, and that " <>
               "fixture is what `.scratch/design/audit/28.png` was captured from"

      tree = tree(mount_screen(HomeDark))

      for row <- HomeDark.Sample.rest_of_today() do
        assert drawn?(tree, row.time)
        assert drawn?(tree, row.title)
        assert drawn?(tree, row.meta)
      end
    end

    test "a mirrored calendar draws the device's day and none of the drawn rows" do
      cal = calendar!()
      event!(cal, ~T[09:15:00], "Plumber")
      event!(cal, ~T[21:05:00], "Rowing")

      tree = tree(mount_screen(HomeDark))

      assert drawn?(tree, "Plumber")
      assert drawn?(tree, "Rowing")

      for row <- HomeDark.Sample.rest_of_today() do
        refute drawn?(tree, row.title),
               "#{inspect(row.title)} is the drawing's, and a real day is being shown"
      end
    end

    test "the header stays the drawing's evening even with a real day under it" do
      # A decision, not an omission — `Kati.Screens.HomeDark`'s moduledoc gives
      # both reasons. Screens 28 and 29 are drawn at one evening and have to
      # agree about it, and three clock literals would cost
      # `Kati.ScreenDesignLiteralTest` three of the four entries its allow-list
      # is capped at.
      cal = calendar!()
      event!(cal, ~T[09:15:00], "Plumber")

      moment = HomeDark.Sample.moment()
      tree = tree(mount_screen(HomeDark))

      assert drawn?(tree, String.upcase(moment.date))
      assert drawn?(tree, moment.greeting)
      assert drawn?(tree, moment.last_check)
    end

    test "the hero and the continue rail are still the drawing's, exactly as Home's are" do
      # Screen 28 reads what screen 01 reads and no more. Home leaves these to
      # the drawing until the Screen domain feeds them, and a dark Home that
      # went further would make the two pages disagree about which half of
      # themselves is real.
      cal = calendar!()
      event!(cal, ~T[09:15:00], "Plumber")

      inbox = HomeDark.Sample.inbox()
      tree = tree(mount_screen(HomeDark))

      for line <- inbox.headline, do: assert(drawn?(tree, line))
      assert drawn?(tree, inbox.sub)
      assert drawn?(tree, inbox.cta)

      for row <- HomeDark.Sample.continue() do
        assert drawn?(tree, row.title)
        assert drawn?(tree, row.meta)
      end
    end

    test "reading the calendar did not make it follow the app theme" do
      Kati.Theme.Mode.put(:light)
      _view = mount_screen(HomeDark)

      assert Mob.Theme.current() == Kati.Theme.dark(),
             "screen 28 is the design's dark reference and went light in a light app"
    end
  end

  # ── Screen 29 ───────────────────────────────────────────────────────────────

  describe "29 — the lock screen, with nothing stored" do
    test "every widget draws its drawn self, to the term" do
      assert Lock.widgets() == Lock.drawn_widgets(),
             "a widget answered from the store against an empty database, or a fallback is " <>
               "no longer the fixture `.scratch/design/audit/29.png` was captured from"
    end

    test "every string the drawing carries reaches the rendered tree" do
      tree = tree(mount_screen(Lock))
      w = Lock.drawn_widgets()

      for string <- [
            w.clock.date,
            w.clock.time,
            w.up_next.eyebrow,
            w.up_next.title,
            w.up_next.meta,
            w.tonight.eyebrow,
            w.tonight.count,
            w.tonight.label,
            w.today.eyebrow,
            w.year.eyebrow,
            w.year.watched,
            w.year.streak
          ] do
        assert drawn?(tree, string), "#{inspect(string)} is nowhere in the tree"
      end

      for row <- w.today.rows do
        assert drawn?(tree, row.time)
        assert drawn?(tree, row.title)
      end
    end
  end

  describe "29 — Up next" do
    test "it is the top of the watching shelf, with the bookmark and what is left" do
      track!(
        "lock-hollow",
        %{
          status: :watching,
          progress_season: 2,
          progress_episode: 6,
          # 18 minutes short of a 100-minute runtime.
          progress_seconds: 82 * 60
        },
        %{title: "Low Water", runtime_minutes: 100, poster_path: "hollow71"}
      )

      widget = Lock.widgets().up_next

      assert widget.title == "Low Water"
      assert widget.meta == "S2E6 · 18M"
      assert widget.seed == "hollow71"

      assert widget.eyebrow == Lock.drawn_widgets().up_next.eyebrow,
             "the eyebrow is the widget's own name and should survive the migration"

      tree = tree(mount_screen(Lock))
      assert drawn?(tree, "Low Water")
      refute drawn?(tree, Lock.drawn_widgets().up_next.title)
    end

    test "a shelf with nothing being watched draws the drawn widget" do
      track!("lock-done", %{status: :finished}, %{title: "Undertow"})

      assert Lock.widgets().up_next == Lock.drawn_widgets().up_next,
             ":finished is not :watching, and there is nothing to be up next"
    end

    test "an archived show is not up next either" do
      track!("lock-hidden", %{status: :watching, archived: true}, %{title: "Hidden Coast"})

      assert Lock.widgets().up_next == Lock.drawn_widgets().up_next,
             "`keeps history, hides from shelf` is the whole meaning of the flag"
    end

    test "an evicted cache leaves the position and takes the name" do
      track!("lock-evicted", %{status: :watching, progress_season: 1, progress_episode: 4}, nil)

      widget = Lock.widgets().up_next
      assert widget.title == "Untitled"
      assert widget.meta == "S1E4", "the bookmark is durable; the runtime was in the cache"
    end
  end

  describe "29 — Tonight" do
    test "it counts the episodes of followed titles that air today" do
      track!("lock-airs", %{status: :watching}, %{title: "Marram"})

      episode!("lock-airs", %{air_at: today_at(~T[20:00:00]), date_confidence: :exact})
      episode!("lock-airs", %{air_at: today_at(~T[20:30:00]), date_confidence: :exact})
      episode!("lock-airs", %{air_at: today_at(~T[20:45:00]), date_confidence: :day})

      assert Lock.widgets().tonight.count == "3"
    end

    test "a date nobody asserted a day for is not counted" do
      # The 1 January rule `Kati.Media.Release` exists to make impossible: a
      # `:month` answer carries no day component, so reading its instant as
      # "airs tonight" is asserting something no source said.
      track!("lock-vague", %{status: :watching}, %{title: "Vellum"})

      episode!("lock-vague", %{air_at: today_at(~T[20:00:00]), date_confidence: :month})
      episode!("lock-vague", %{air_at: today_at(~T[21:00:00]), date_confidence: :unknown})

      assert Lock.widgets().tonight.count == "0"
    end

    test "an episode of a title nobody follows is not counted" do
      track!("lock-followed", %{status: :watching}, %{title: "Ashfall"})
      episode!("lock-stranger", %{air_at: today_at(~T[20:00:00]), date_confidence: :exact})

      assert Lock.widgets().tonight.count == "0"
    end

    test "a finished show's episodes are not tonight's business" do
      track!("lock-over", %{status: :finished}, %{title: "The Cartographer"})
      episode!("lock-over", %{air_at: today_at(~T[20:00:00]), date_confidence: :exact})

      # `:followed` excludes finished and dropped outright, so this library has
      # nothing followed at all and the widget falls back rather than saying 0.
      assert Lock.widgets().tonight == Lock.drawn_widgets().tonight
    end

    test "a followed library with a quiet evening says nought, not the drawing's six" do
      track!("lock-quiet", %{status: :watching}, %{title: "Salt & Iron"})

      assert Lock.widgets().tonight.count == "0",
             "`how loaded tonight is` has `not at all` among its answers, and a fallback " <>
               "here would report six episodes nobody is airing"
    end

    test "nothing followed at all draws the drawn widget" do
      assert Lock.widgets().tonight == Lock.drawn_widgets().tonight
    end
  end

  describe "29 — Today" do
    test "it draws the device's day and the same events screen 28 does" do
      cal = calendar!()
      event!(cal, ~T[09:15:00], "Plumber")
      event!(cal, ~T[23:59:00], "Rowing")

      widget = Lock.widgets().today
      titles = Enum.map(widget.rows, & &1.title)

      assert titles != []
      assert Enum.all?(titles, &(&1 in ["Plumber", "Rowing"]))

      # The pairing the design's caption claims — the two pages are one evening.
      # Both read `Kati.Calendars.Today.rows/1`, so an event on one is an event
      # on the other by construction rather than by coincidence.
      assert drawn?(tree(mount_screen(HomeDark)), "Rowing")
      assert drawn?(tree(mount_screen(Lock)), "Rowing")
    end

    test "an event at the last minute of the day is always still ahead" do
      # Deterministic at every hour, which a fixture at a fixed morning time
      # would not be: `23:59` is at or after any `HH:MM` the device clock can
      # read, so this pins the count itself rather than a shape.
      cal = calendar!()
      event!(cal, ~T[23:59:00], "Rowing")

      assert Lock.widgets().today.eyebrow == "TODAY · 1 LEFT"
    end

    test "with nothing ahead the widget still draws the day rather than an empty panel" do
      cal = calendar!()
      event!(cal, ~T[00:00:00], "Morning run")

      widget = Lock.widgets().today

      assert widget.rows != [],
             "a glass panel with nothing in it is not a state the design has; `0 LEFT` is " <>
               "the honest count and the day is still what the widget is about"

      assert Enum.all?(widget.rows, &(&1.title == "Morning run"))
      assert widget.eyebrow =~ ~r/^TODAY · \d+ LEFT$/
    end

    test "it never draws more than the two rows the panel is sized for" do
      # All ten at `23:59` on purpose. Spread across the evening they would be
      # past or ahead depending on the hour this file runs at, and the count
      # this pins would be right for most of the day and wrong for the rest.
      cal = calendar!()
      for n <- 1..10, do: event!(cal, ~T[23:59:00], "Thing #{n}")

      widget = Lock.widgets().today

      assert widget.eyebrow == "TODAY · 10 LEFT"
      assert length(widget.rows) == 2, "the medium widget has room for two rows and draws two"
    end

    test "an empty calendar draws the drawn widget" do
      assert Lock.widgets().today == Lock.drawn_widgets().today
    end
  end

  describe "29 — This year" do
    test "the hours and the streak are the watch log's, not the drawing's" do
      tracked =
        track!("lock-year", %{status: :watching}, %{title: "Ashfall", runtime_minutes: 100})

      # Three consecutive nights inside the current year whatever today's date
      # is: a fixture counted back from today would fall into last year every
      # January and this file would be green for eleven months out of twelve.
      for day <- 4..6 do
        watch!(tracked, %{watched_on: Date.new!(Kati.Time.today().year, 1, day)})
      end

      widget = Lock.widgets().year

      assert widget.watched == "5h watched", "three 100-minute watches is 300 minutes"
      assert widget.streak == "3-night streak"
      assert widget.eyebrow == Lock.drawn_widgets().year.eyebrow

      refute widget.watched == Lock.drawn_widgets().year.watched
      refute widget.streak == Lock.drawn_widgets().year.streak
    end

    test "the field keeps the drawing's shape: 78 cells, chunked 33" do
      tracked = track!("lock-field", %{status: :watching}, %{title: "Marram"})
      watch!(tracked, %{watched_on: Kati.Time.today()})

      rows = Lock.widgets().year.rows

      assert Enum.map(rows, &length/1) == [33, 33, 12],
             "the ragged last row of twelve is what the drawing shows, and a field built " <>
               "from real watches has to be the same object"

      assert Enum.map(rows, &length/1) ==
               Enum.map(Lock.drawn_widgets().year.rows, &length/1)
    end

    test "the field ends today, and today is the cell that lit" do
      tracked = track!("lock-today", %{status: :watching}, %{title: "Harbour"})
      watch!(tracked, %{watched_on: Kati.Time.today()})

      cells = Lock.widgets().year.rows |> List.flatten()

      assert List.last(cells) == 1, "the last cell is today, and today has one watch on it"
      assert Enum.count(cells, &(&1 > 0)) == 1
    end

    test "a heavy day stops at the darkest cell there is" do
      tracked = track!("lock-heavy", %{status: :watching}, %{title: "Vellum"})
      for _ <- 1..6, do: watch!(tracked, %{watched_on: Kati.Time.today()})

      cells = Lock.widgets().year.rows |> List.flatten()

      assert List.last(cells) == 3,
             "`Kati.Screens.Lock.Sample.intensity/1` paints four steps; a busier day is not " <>
               "a different colour"
    end

    test "a watch with no date takes part in none of it" do
      # *"I have seen this, I do not remember when"* is an answer
      # `Kati.Media.Watch` deliberately allows, and every figure on this widget
      # is a question about when.
      tracked = track!("lock-undated", %{status: :watching}, %{title: "Low Water"})
      watch!(tracked, %{rating: 8})

      assert Lock.widgets().year == Lock.drawn_widgets().year
    end

    test "an empty log draws the drawn widget" do
      assert Lock.widgets().year == Lock.drawn_widgets().year
    end
  end

  describe "29 — what does not move" do
    test "the clock stays the drawing's evening on a device full of data" do
      cal = calendar!()
      event!(cal, ~T[23:59:00], "Rowing")
      tracked = track!("lock-full", %{status: :watching}, %{title: "Ashfall"})
      watch!(tracked, %{watched_on: Kati.Time.today()})

      assert Lock.widgets().clock == Lock.drawn_widgets().clock

      tree = tree(mount_screen(Lock))
      assert drawn?(tree, Lock.drawn_widgets().clock.date)
      assert drawn?(tree, Lock.drawn_widgets().clock.time)
    end

    test "reading the store did not make it follow the app theme" do
      Kati.Theme.Mode.put(:light)
      _view = mount_screen(Lock)

      assert Mob.Theme.current() == Kati.Theme.dark(),
             "screen 29 is the design's dark reference and went light in a light app"
    end
  end

  # Noon-and-so-on today, in the device's own zone, as the UTC instant a cache
  # row stores. `Kati.Media.Release.air/1` reads `:exact` back through the same
  # zone, so this lands on today wherever the machine thinks it is.
  defp today_at(%Time{} = time) do
    {:ok, utc} =
      Kati.Time.to_utc(NaiveDateTime.new!(Kati.Time.today(), time), Kati.Time.device_zone())

    utc
  end
end
