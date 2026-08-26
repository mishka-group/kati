defmodule Kati.CalendarDayRouteTest do
  @moduledoc """
  The route from screen 02 (Schedule) to screen 09 (a heavy day), and back.

  ## What was missing

  Screen 09 is drawn as a pushed screen under this root — its back pill reads
  `‹ Calendar` — and nothing on 02 opened it. The other calendar views reach
  it through `Kati.Screens.ViewSwitcher`; the Schedule root draws no switcher,
  so the drawing's own back pill pointed at a screen that could not be got to.

  `Kati.Screens.Calendar` now gives the gesture to the day cell that is
  **already selected**: the first tap on a cell selects that date, a second tap
  on the same cell opens it. The argument for that control over the `Today`
  pill lives beside the code, in `handle_tap/2`.

  ## Why these tests are shaped the way they are

  Two failures are possible here and only one of them is obvious.

    * **The obvious one** — the open gesture does not push. Caught by
      `handle_tap/2` returning a socket with no nav action.

    * **The one that would matter more** — the open gesture eats the
      *selection*. One tag now carries two meanings, so a branch on the wrong
      side of the `==` turns every day cell into a push and the week strip
      stops selecting anything at all, while the screen's resting pixels stay
      exactly as they were. Every test below that taps a day therefore asserts
      on BOTH halves: what the assigns became AND what the screen navigated
      to, because either one alone passes while the other is broken.

  The last test drives the real `Mob.Screen` navigation stack rather than a
  socket, because "back returns to the Schedule root" is a claim about that
  stack: `apply_nav_action/3` saves `{module, socket}` on push and restores
  that exact pair on pop (`mob/lib/mob/screen.ex:554-580`). Asserting
  `pop_screen/1` was *requested* would prove nothing about where it lands, or
  that the day the user had selected survives the trip.

  ## Where the rows a selection changes come from (#91)

  Two tests below need a day that HOLDS something, so that reloading it is a
  visible act rather than one empty list replacing another. They used to get
  that for free: `Kati.Screens.Calendar.day_rows/1` answered TODAY with
  `drawn_rows/0` on an empty store, so every mount arrived carrying the five
  cards `test/design/screens/02.html` was captured with. #91 removed that
  fallback — a first launch was drawing the owner a dentist appointment that
  was not his — and took these tests' only fixture with it. `drawn_rows/0` is
  still there and no code path renders it, which is exactly why nothing here
  may lean on it again.

  So they write the days they select: real `Kati.Calendars.Event` rows through
  the resource's own create action, inside one transaction that is always
  rolled back. Three things about that fixture are load-bearing.

    * **It is written against the column the query reads.**
      `Kati.Calendars.Today.rows/1` filters `dtstart_utc` between the day's
      local midnight and 23:59:59 converted to UTC, so `event!/5` stores that
      instant (and the authored wall clock and DURATION beside it, which is
      what `Kati.Calendars.Event`'s moduledoc requires). An event written on
      `dtstart_date` instead would return zero rows and every assertion here
      would be back to comparing nothing with nothing.

    * **The second day's date is read OFF THE STRIP**, in `two_stored_days/1`,
      rather than recomputed from `Kati.Time.today()`. A helper that rebuilt
      the week here would agree with a broken `day_strip/1` about which days
      exist and would seed a day the tap never asks for — the one way this
      fixture fails silently.

    * **Every count asserted is non-zero and named.** The tests compare the
      TITLES they stored, not a length, so an empty answer cannot satisfy them
      and neither can the other day's rows arriving under this day's date.

  Rolled back rather than deleted in `on_exit`: this suite has no Ecto sandbox
  and one SQLite file is shared by every test, `pool_size` is 1 and this module
  is `async: false`, so the test process holds the only connection — the mounts
  read through it and see the fixture, and nothing survives the test, including
  when it fails. `Kati.EventRowIdentityTest` says the same thing from the other
  side: what it must not leak is "events on a day `Kati.CalendarDayRouteTest`
  asserts is empty".
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendars.Event
  alias Kati.Screens.Calendar
  alias Kati.Screens.Day
  alias Kati.Theme

  # `day_strip/1` draws the Monday-to-Sunday week around the selected date.
  # Asserted as a number, not as "more than zero": a strip that resolved to a
  # single cell would satisfy every other test in this file, since the one cell
  # left would be the selected one.
  @strip_cells 7

  # The day the screen opens on, as rows this file stores. Three rather than
  # one: with one row, "reloaded the other day" and "dropped the day it had"
  # are the same observation, and a length that can only be 0 or 1 cannot tell
  # them apart.
  @today_rows [
    {~T[09:30:00], ~T[09:45:00], "Bike service"},
    {~T[11:00:00], ~T[11:30:00], "Call the letting agent"},
    {~T[18:30:00], ~T[19:15:00], "Swim"}
  ]

  # The day the strip is tapped ONTO. A different count and different words
  # from `@today_rows`, so a reload that kept the old day's rows and a reload
  # that found nothing are two distinguishable failures.
  #
  # Both times are afternoon on purpose. `Kati.Calendars.Today.row/2` sets
  # `now?` from `DateTime.diff(dtstart_utc, now) in 0..3600`, and the tests
  # compare a row list against a second read of the same day; a fixture in the
  # small hours of a strip cell that happened to be TOMORROW could flip that
  # flag between the two reads and fail on the clock rather than on the code.
  @other_rows [
    {~T[13:00:00], ~T[14:00:00], "Pick up prescription"},
    {~T[16:30:00], ~T[17:00:00], "Tea with Nadia"}
  ]

  # Nothing in `@today_rows` or `@other_rows` is a title `Kati.Calendar.SampleDay`
  # or `Kati.Screens.Calendar.drawn_rows/0` writes — checked against both, and
  # the reason `Standup`, `Design review` and `Lunch — Jo` are not used here
  # even though they are the obvious names for these slots. A fixture sharing a
  # title with the drawing would let a screen that fell back to the sample
  # satisfy an assertion about a row this file stored.

  describe "the week strip" do
    test "draws one tappable cell per day of the week around the selected date" do
      view = mount_screen(Calendar)
      cells = day_cells(view)

      assert length(cells) == @strip_cells,
             "the strip drew #{length(cells)} tappable day cells, not #{@strip_cells}: " <>
               inspect(Enum.map(cells, &elem(&1, 1)))

      dates = cells |> Enum.map(&elem(&1, 1)) |> Enum.sort(Date)

      assert Date.day_of_week(hd(dates)) == 1, "the strip does not start on a Monday"
      assert Date.diff(List.last(dates), hd(dates)) == @strip_cells - 1
      assert assigns(view).date in dates, "the selected date is not one of the cells drawn"
    end

    test "paints exactly one cell as selected, and it is the assigned date" do
      view = mount_screen(Calendar)
      date = assigns(view).date

      selected = for {tag, d} <- day_cells(view), cell_fill(view, tag) == Theme.ink(), do: d

      assert selected == [date],
             "the ink cell must be the selected date and nothing else, got #{inspect(selected)}"

      for {tag, d} <- day_cells(view), d != date do
        assert cell_fill(view, tag) == Theme.card(:light),
               "#{d} is not selected but is not drawn on card white"
      end
    end
  end

  describe "selecting a different day" do
    test "changes the date and reloads that day's rows without navigating" do
      two_stored_days(fn %{view: view, tag: tag, date: date} ->
        %{date: was, rows: drawn} = assigns(view)

        # The screen opens on today, and today holds the rows this test wrote —
        # so there is something for the reload to change FROM. Asserted by
        # TITLE rather than by count: the count this used to assert was five,
        # and it was five because `day_rows/1` invented a day when the store was
        # empty (#91). A fixture that never landed answers `[]` here, which is
        # the failure this line exists to make loud.
        assert Enum.map(drawn, & &1.title) == titles(@today_rows),
               "the mount drew #{inspect(Enum.map(drawn, & &1.title))} for today, not the " <>
                 "rows this test stored on it"

        view = tapped(view, tag)

        assert navigated_to(view) == nil, "selecting a day must not leave the Schedule"
        assert assigns(view).date == date
        assert assigns(view).rows == Calendar.day_rows(date)

        # The reload found the OTHER day's own rows. `refute rows == drawn`
        # below is satisfied by an empty list too, so on its own it cannot tell
        # "read the day tapped" from "read a day with nothing on it".
        assert Enum.map(assigns(view).rows, & &1.title) == titles(@other_rows),
               "the strip moved to #{date} and the timeline is not that day's stored rows"

        refute assigns(view).rows == drawn,
               "the rows were not reloaded — the strip changed the date and nothing else"

        assert assigns(view).date != was
      end)
    end

    test "moves the ink cell and redraws the timeline for the day tapped" do
      view = mount_screen(Calendar)
      was = assigns(view).date
      {tag, date} = other_day(view)

      view = tapped(view, tag)

      assert cell_fill(view, tag) == Theme.ink()
      assert cell_fill(view, day_tag(was)) == Theme.card(:light)

      # A day with no mirrored events shows its real emptiness, and that empty
      # card is the proof the reload reached the render rather than stopping at
      # the assigns.
      assert text(view) =~ "Nothing scheduled"
      assert text(view) =~ "#{date.day} #{Kati.Time.month_name(date.month)}"
    end

    test "every unselected cell selects, and none of them navigates" do
      view = mount_screen(Calendar)
      date = assigns(view).date

      for {tag, d} <- day_cells(view), d != date do
        stepped = tapped(view, tag)

        assert navigated_to(stepped) == nil, "#{d} navigated instead of selecting"
        assert assigns(stepped).date == d
      end
    end
  end

  describe "opening the selected day" do
    test "a second tap on the selected cell pushes screen 09" do
      view = mount_screen(Calendar)
      date = assigns(view).date

      opened = tapped(view, day_tag(date))

      assert navigated_to(opened) == Day
    end

    test "the push names the day that was open, not the clock" do
      view = mount_screen(Calendar)
      {tag, date} = other_day(view)

      # Select first, then open — so the date the route carries is provably the
      # SELECTED day and not `Kati.Time.today()` arriving by coincidence.
      opened = view |> tapped(tag) |> tapped(tag)

      assert date != Kati.Time.today()
      assert navigated_to(opened) == Day
      assert opened.socket.__mob__.nav_action == {:push, Day, %{date: date}}
    end

    test "opening leaves the Schedule's own state exactly as it was" do
      view = mount_screen(Calendar)
      before = assigns(view)

      opened = tapped(view, day_tag(before.date))

      # The socket the nav stack saves on push is this one, so anything the
      # open gesture changed here is what the user would find on the way back.
      assert assigns(opened).date == before.date
      assert assigns(opened).rows == before.rows
      assert assigns(opened).filter == before.filter
    end

    test "what opens agrees with what was under it — the day's own rows, not a blank page" do
      # The failure this pins is the one a gesture test cannot see: the push
      # lands, the date is right, and the page under it is empty while the
      # Schedule behind it is drawing that same day's cards.
      #
      # It used to be pinned through the samples — 02 fell back to
      # `drawn_rows/0` on today and 09 to `Kati.Calendar.SampleDay`, so the two
      # agreed by both being invented. #91 took the first fallback away, and
      # what is left is the claim that was always the point: ONE day, TWO
      # screens, one tap apart, and the same events on both. Stored rows say
      # that; two sample modules never could.
      stored_today(fn %{view: view, events: stored} ->
        date = assigns(view).date

        assert date == Kati.Time.today()

        assert Enum.map(assigns(view).rows, & &1.title) == titles(@today_rows),
               "the Schedule is not drawing the day this test stored"

        {:push, Day, params} = tapped(view, day_tag(date)).socket.__mob__.nav_action
        opened = mount_screen(Day, params)

        assert assigns(opened).date == date

        # The whole of "agrees with what was under it", as identity rather than
        # as wording: `Kati.Calendars.Today` gives a row and an occurrence the
        # same `:id`, so the two screens can be compared on WHICH events they
        # hold and not merely on how many.
        assert Enum.map(assigns(opened).occurrences, & &1.id) == Enum.map(stored, & &1.id)

        assert Enum.map(assigns(opened).occurrences, & &1.id) ==
                 Enum.map(assigns(view).rows, & &1.id),
               "screen 09 opened a different set of events from the ones screen 02 was " <>
                 "drawing under the cell that was tapped"

        body = text(opened)
        refute body =~ "Nothing scheduled"

        for title <- titles(@today_rows) do
          assert body =~ title, "screen 09 does not draw #{inspect(title)}, a row of this day"
        end

        # A day the user opened is drawn as itself. `drawn?` gates the all-day
        # band, the merged renewals row and the drawing's own headline, and
        # `Kati.Screens.Day`'s moduledoc spends five bullets on why none of them
        # can be computed from a stored event — so over real rows they must all
        # be absent, and the flag alone would not say whether they were.
        assert assigns(opened).drawn? == false
        refute body =~ "£22.98"
        refute body =~ "Vellum — in cinemas"
        refute body =~ Kati.Calendar.SampleDay.summary()
      end)
    end

    test "today with nothing stored still opens the drawn day, band and renewals and all" do
      # Every assertion the test above used to make, kept whole and moved to
      # the state it is actually about. `Kati.Screens.Day.day/1`'s `empty/1`
      # answers TODAY-with-nothing-stored with `Kati.Calendar.SampleDay`, and
      # this is the only place in the suite that renders that branch:
      # `Kati.EventRowIdentityTest` covers the no-date branch and an empty day
      # thirty days out, and both of its other cases have events on today.
      # Deleting it here would have taken the branch's only coverage with it.
      #
      # The emptiness is MADE rather than assumed. The old version guarded with
      # `assert Kati.Calendars.Today.occurrences(date) == []` and a message
      # reading "something seeded today", which is a test that fails when
      # another file leaks; emptying the table inside a rolled-back transaction
      # cannot be leaked into.
      #
      # NOTE, and it is not a test problem: `day/1`'s moduledoc argues this
      # branch from "screen 02 draws five cards for today", and after #91 it
      # draws `Nothing scheduled` instead. So the two screens now disagree the
      # other way about a first launch — 02 says the day is empty and 09 draws
      # fourteen invented items one tap later. Whether the exception survives is
      # a decision about `lib/kati/screens/day.ex`, and it belongs in #91; until
      # it is made, the behaviour that ships is the behaviour under test.
      with_empty_store(fn ->
        view = mount_screen(Calendar)
        date = assigns(view).date

        assert date == Kati.Time.today()

        assert assigns(view).rows == [],
               "the Schedule invented a day on an empty store, which is the whole of #91"

        {:push, Day, params} = tapped(view, day_tag(date)).socket.__mob__.nav_action
        opened = mount_screen(Day, params)

        assert assigns(opened).date == date
        assert assigns(opened).occurrences == Kati.Calendar.SampleDay.occurrences()
        assert assigns(opened).drawn? == true

        body = text(opened)
        refute body =~ "Nothing scheduled"
        assert body =~ Kati.Calendar.SampleDay.summary()

        # The furniture `drawn?` gates, checked in the tree rather than off the
        # flag: the band, the merged renewals row and the drawing's own chip
        # counts all go together or the day is only half drawn.
        assert body =~ "£22.98"
        assert body =~ "Vellum — in cinemas"
      end)
    end

    test "any other empty day still opens empty, so the exception is today's alone" do
      view = mount_screen(Calendar)
      {tag, date} = other_day(view)

      assert Kati.Calendars.Today.occurrences(date) == []

      {:push, Day, params} =
        view |> tapped(tag) |> tapped(tag) |> then(& &1.socket.__mob__.nav_action)

      opened = mount_screen(Day, params)

      assert assigns(opened).date == date
      assert assigns(opened).occurrences == []
      assert assigns(opened).drawn? == false
      assert text(opened) =~ "Nothing scheduled"
      refute text(opened) =~ "£22.98"
    end
  end

  describe "the way back from screen 09" do
    test "the back pill is drawn, tagged :back, and labelled for this root" do
      view = mount_screen(Day)
      label = Enum.find(Kati.Shell.roots(), &(&1.id == :calendar)).label

      pill = find(view, :row, on_tap: {self(), :back})
      assert pill, "screen 09 draws no control tagged :back"

      # Matched as its own Text node rather than against `text(pill)`, which
      # also picks up the `arrow_back_ios_new` glyph the pill draws beside the
      # word — `Kati.UI.symbol/2` renders a Material Symbol as a Text carrying
      # the private-use codepoint, so the joined string is " Calendar".
      assert find(pill, :text, text: label),
             "the back pill reads #{inspect(text(pill))}; the root it returns to is " <>
               "#{inspect(label)}, and the drawing gives the pill that root's name"

      assert Kati.Shell.screen_for(:calendar) == Calendar
      assert navigated_to(tapped(view, :back)) == {:pop}
    end

    test "back off screen 09 lands on the Schedule root with the day still selected" do
      pid = screen_process(Calendar)
      {tag, date} = other_day(Calendar.render(socket(pid).assigns))

      # Move the selection off today first: what comes back has to be provably
      # the screen we left, not a freshly mounted Schedule that happens to look
      # the same because it also opens on today.
      send(pid, {:tap, tag})
      assert Mob.Screen.get_current_module(pid) == Calendar
      assert socket(pid).assigns.date == date

      send(pid, {:tap, tag})
      assert Mob.Screen.get_current_module(pid) == Day
      assert length(Mob.Screen.get_nav_history(pid)) == 1

      send(pid, {:tap, :back})

      assert Mob.Screen.get_current_module(pid) == Calendar
      assert Mob.Screen.get_nav_history(pid) == [], "the pop left something on the stack"

      back = socket(pid)
      assert back.assigns.root == :calendar
      assert back.assigns.date == date
      assert back.assigns.rows == Calendar.day_rows(date)
    end
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  defp tapped(view, tag), do: render_info(view, {:tap, tag})

  defp day_tag(date), do: String.to_atom("day_" <> Date.to_iso8601(date))

  # `{tag, date}` for every day cell the tree draws, read off `on_tap` rather
  # than recomputed from the date — a helper that rebuilt the week here would
  # agree with a broken `day_strip/1` about which days exist.
  defp day_cells(view_or_tree) do
    view_or_tree
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(Map.get(node, :props) || %{}, :on_tap) do
        {pid, tag} when is_pid(pid) -> day_pair(tag)
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  defp day_pair(tag) do
    case Atom.to_string(tag) do
      "day_" <> iso -> [{tag, Date.from_iso8601!(iso)}]
      _ -> []
    end
  end

  defp other_day(view_or_tree) do
    selected = day_cells(view_or_tree) |> Enum.map(&elem(&1, 1))

    # The selected date is the one drawn in ink, but this helper is also used
    # against a bare tree where the assigns are not to hand — so pick the first
    # cell that is not today, which is the day the screen opens on.
    Enum.find(day_cells(view_or_tree), fn {_tag, d} -> d != Kati.Time.today() end) ||
      flunk("the strip drew no day other than today: #{inspect(selected)}")
  end

  # The fill of the `Column` inside one day cell — `day_cell/2` paints the
  # selected one in ink and the rest on card white, and that is the only thing
  # on this screen that says which day the next tap will open.
  defp cell_fill(view_or_tree, tag) do
    cell = find(view_or_tree, :box, on_tap: {self(), tag})
    assert cell, "no day cell is tagged #{inspect(tag)}"

    column = find(cell, :column)
    assert column, "the cell tagged #{inspect(tag)} holds no Column to be filled"

    column.props[:background]
  end

  # A real screen process in `:no_render` mode: mounts and dispatches through
  # `Mob.Screen`'s own navigation stack, and touches no NIF.
  defp screen_process(module) do
    start_supervised!(%{
      id: {Mob.Screen, module},
      start: {Mob.Screen, :start_link, [module, %{}]}
    })
  end

  defp socket(pid), do: Mob.Screen.get_socket(pid)

  # ── the days these tests run against ───────────────────────────────────────

  defp titles(rows), do: for({_from, _to, title} <- rows, do: title)

  # Today, holding `@today_rows` and nothing else, with the Schedule already
  # mounted against it. `:events` is the stored rows, so a test can name the
  # events it is asking two screens about rather than counting them.
  defp stored_today(fun) do
    rolled_back(fn ->
      calendar = calendar!()
      events = store!(calendar, Kati.Time.today(), @today_rows)

      fun.(%{view: mount_screen(Calendar), events: events})
    end)
  end

  # Today holding `@today_rows`, and one OTHER day of the drawn week holding
  # `@other_rows`.
  #
  # The second date is taken from `other_day/1` — off the strip the screen just
  # drew — and only then written to, because the tap under test asks the store
  # for whatever date that cell carries. Computing the date here instead would
  # put the fixture on the day this file THINKS the strip drew: if the two ever
  # parted company the events would land on a day nothing asks for, both reads
  # would answer `[]`, and the assertions would compare nothing with nothing
  # while staying green.
  #
  # The mount happens before the second day is written, which is deliberate and
  # harmless: `handle_tap/2` re-reads through `day_rows/1` on the tap, so what
  # it finds is what is in the store at tap time, not at mount time.
  defp two_stored_days(fun) do
    rolled_back(fn ->
      calendar = calendar!()
      today = store!(calendar, Kati.Time.today(), @today_rows)
      view = mount_screen(Calendar)
      {tag, date} = other_day(view)
      other = store!(calendar, date, @other_rows)

      fun.(%{view: view, tag: tag, date: date, today: today, other: other})
    end)
  end

  # `rolled_back/1` named for what the test is asking of it: the two fixtures
  # above empty the table on the way in as a precondition, and this one is the
  # whole of the state under test.
  defp with_empty_store(fun), do: rolled_back(fun)

  # One transaction, emptied of every event and always rolled back. Child table
  # first: `event_occurrence_overrides` references `events` and SQLite enforces
  # it. The calendars stay — screen 32 reads that table and this file has
  # nothing to say about it — and the rollback takes back the one written here
  # either way.
  defp rolled_back(fun) do
    {:error, {:done, result}} =
      Kati.Repo.transaction(fn ->
        for table <- ~w(event_occurrence_overrides events),
            do: Kati.Repo.query!("delete from #{table}")

        Kati.Repo.rollback({:done, fun.()})
      end)

    result
  end

  defp store!(calendar, date, rows),
    do: for({from, to, title} <- rows, do: event!(calendar, date, from, to, title))

  defp calendar! do
    Kati.Calendars.Calendar
    |> Ash.Changeset.for_create(:create, %{
      display_name: "Day route #{System.unique_integer([:positive])}",
      kind: :local
    })
    |> Ash.create!()
  end

  # The same timing `Kati.Seeds` writes, and the same shape
  # `Kati.EventRowIdentityTest` and `Kati.ScreenCalendarEmptyStateTest` store:
  # a UTC instant for the range query `Kati.Calendars.Today.rows/1` actually
  # filters on, the authored wall clock beside it, and the length as a DURATION
  # rather than an end instant — `dtend_utc` is derived from it by
  # `Kati.Calendars.Changes.DeriveTiming`, which is why this goes through the
  # resource's create action rather than an insert.
  #
  # The wall clock is built from `NaiveDateTime.to_iso8601/1` rather than
  # `Calendar.strftime/2`: `Calendar` is aliased to `Kati.Screens.Calendar` at
  # the top of this module, which has no `strftime/2`.
  defp event!(calendar, date, from, to, summary) do
    zone = Kati.Time.device_zone()
    naive = NaiveDateTime.new!(date, from)
    {:ok, utc} = Kati.Time.to_utc(naive, zone)
    minutes = div(Time.diff(to, from, :second), 60)

    Event
    |> Ash.Changeset.for_create(:create, %{
      uid: "kati-day-route-#{System.unique_integer([:positive])}@kati",
      calendar_id: calendar.id,
      origin: :kati,
      summary: summary,
      kind: :event,
      status: :confirmed,
      dtstart_utc: utc,
      dtstart_wall: naive |> NaiveDateTime.to_iso8601() |> String.replace(["-", ":"], ""),
      tzid: zone,
      duration_iso: "PT#{minutes}M",
      sync_state: :local_only
    })
    |> Ash.create!()
  end
end
