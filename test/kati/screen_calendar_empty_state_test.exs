defmodule Kati.ScreenCalendarEmptyStateTest do
  @moduledoc """
  #91 — the Schedule root on a phone that has never been told anything.

  ## The defect

  `Kati.Screens.Calendar.day_rows/1` answered TODAY with `drawn_rows/0` when
  the store was empty: a dentist appointment at a named clinic, a passport
  reminder, a subscription renewal with a price on it, and three episodes of
  three invented series. `Kati.Seeds` is not wired into `Kati.App.on_start/0`,
  so a first launch really is an empty `events` table — which made those five
  cards the first thing the owner saw of his own day, and he read them exactly
  as written: *"you all show dummy data and it is not connected to database"*.

  ## Why the two halves are both needed

    * every string the empty state draws is on the page, **and**
    * every string `drawn_rows/0` fabricates is **not**.

  The first alone is worthless here. `timeline/2`'s empty clause has existed
  since the screen was written — it was simply unreachable on today — so a test
  that only asserted `Nothing scheduled` would have passed against the very
  build this file exists to condemn, on any day the user tapped that was not
  today.

  The fabricated list is not hand-typed: it is read out of
  `Kati.Screens.Calendar.drawn_rows/0`, so a sample edited on one side cannot
  walk out of this file unchecked. Its posters are not strings and are covered
  by a node count instead — five photographs of films nobody has heard of is
  the most obviously invented thing on the page.

  ## The half that is not about emptiness at all

  A calendar with nothing on it and a calendar Kati is **not allowed to read**
  are two different facts, and #82 (`Kati.Calendars.DeviceImport`,
  `Mob.Permissions`) made both reachable on a real device. A person has to be
  able to tell them apart: one is *nothing is on today*, the other is *Kati
  cannot see your calendar*, and only the second has anything they can do
  about it.

  `Kati.Permissions.status/1` answers `:unknown` on a host for want of a
  bridge, so none of that could be asked through `load/1`. It is asked through
  `empty_reason/2` and `content/1` instead, which is why that split is a pure
  function taking the state rather than reading it.

  ## Where the emptiness comes from

  Inside one rolled-back transaction, exactly as `Kati.ScreenEmptyDatabaseTest`
  and `Kati.ScreenHomeEmptyStateTest` do it and for the same reason: this suite
  has no Ecto sandbox, one SQLite file is shared by every test, and several of
  them insert rows that outlive themselves. `pool_size` is 1 and this module is
  `async: false`, so the test process holds the only connection — the mount
  reads through it and sees the empty store, and nothing is kept.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendars.Event
  # Aliased away from `Calendar`, which `event!/5` below needs for `strftime/2`.
  alias Kati.Screens.Calendar, as: Schedule

  # Child first: `event_occurrence_overrides` references `events`, and SQLite
  # enforces it. The calendars themselves stay — screen 32 reads that table and
  # this file has nothing to say about it, and the rollback takes back anything
  # written here either way.
  @emptied ~w(event_occurrence_overrides events)

  # What the screen says when the store is empty and Kati may read it. Screen
  # 139's row (`test/design/screens/139.html`) is the only place any board
  # words this — `calendar_month` tile, a title, and `Nothing scheduled — add
  # anything with +` — and its em-dashed sentence is split at the dash into the
  # row's own two lines. Board 02 draws a day with five items on it and no
  # board anywhere draws an empty Schedule, which is stated here rather than
  # implied so that a future round knows this copy has a source.
  @no_events ["Nothing scheduled", "Add anything with +"]

  # What it says when Kati is not allowed to read the calendar. The first line
  # is screen 40's Calendars row word for word; the second names where 40 draws
  # the control rather than growing a second copy of it here.
  @no_permission [
    "Kati cannot see your calendar",
    "To show your appointments beside your episodes. Kati only reads them.",
    "Allow Calendars in Settings, under This device."
  ]

  # The three hours a real day is built from below. Times, not titles, are what
  # `Kati.Calendars.Today` derives from the stored instant, so a row drawn at
  # the wrong hour would still be caught.
  @rows [
    {~T[09:30:00], ~T[09:45:00], "Standup"},
    {~T[13:00:00], ~T[14:00:00], "Lunch — Jo"},
    {~T[18:30:00], ~T[19:15:00], "Physio"}
  ]

  describe "a device with nothing on it" do
    test "the Schedule draws its own emptiness, on today" do
      texts = with_empty_store(fn -> calendar_texts() end)

      for literal <- @no_events do
        assert literal in texts,
               "the Schedule renders nothing reading #{inspect(literal)} on an empty store, " <>
                 "and today is the day it opens on"
      end

      # Read off the CARD, not off the page. `Kati.UI.symbol/2` draws a Material
      # Symbol as an ordinary `Text` in the symbols font, and `calendar_month`
      # is also the dock's Calendar tab on every root screen — so
      # `text(tree) =~ glyph` is answered by the dock whatever the tile draws.
      # Verified: it passed with `empty_card("info", ...)`.
      assert Kati.Icons.glyph!("calendar_month") in glyphs(Schedule.timeline([], :no_events)),
             "screen 139 draws its empty calendar row behind a `calendar_month` tile"

      # And that the tile it draws reaches the page, which is the half the
      # subtree above cannot see. Counted against a day that has events on it
      # rather than against a fixed number, so the dock is subtracted by
      # measurement instead of by assumption.
      calendar_month = Kati.Icons.glyph!("calendar_month")

      empty_page =
        with_empty_store(fn -> Enum.count(glyphs(calendar_tree()), &(&1 == calendar_month)) end)

      full_page =
        in_a_real_day(fn _events ->
          Enum.count(glyphs(calendar_tree()), &(&1 == calendar_month))
        end)

      assert empty_page == full_page + 1,
             "the empty Schedule draws #{empty_page} `calendar_month` glyphs and a full one " <>
               "draws #{full_page}. The empty state's tile is the one that should be the " <>
               "difference"
    end

    test "and none of the five cards screen 02 was captured from" do
      texts = with_empty_store(fn -> calendar_texts() end)

      present = Enum.filter(fabricated(), &(&1 in texts))

      assert present == [],
             "the Schedule still draws copy it invented on a device with an empty store. " <>
               "This is the whole of #91 — a first launch that fabricates the user's own " <>
               "day:\n" <> Enum.map_join(present, "\n", &"  #{inspect(&1)}")
    end

    test "the three posters the airing group stacks are gone with it" do
      # The fabricated list can only speak for strings. `drawn_rows/0`'s last
      # row carries three poster seeds, and an `Image` left on the empty page
      # would mean the group survived with its caption deleted.
      images = with_empty_store(fn -> find_all(calendar_tree(), :image) end)

      assert images == [],
             "the empty Schedule draws #{length(images)} images. Its one picture is a " <>
               "`calendar_month` glyph in a paper tile"
    end

    test "the screen's own read answers empty, so it is emptiness that drew" do
      # The literal checks above are satisfied by presence anywhere in the tree.
      # This asks the entry point instead: what `load/1` is handed on a device
      # with nothing mirrored. `[]` is the answer that makes the card above the
      # truth rather than a coincidence.
      today = Kati.Time.today()

      {rows, mounted} =
        with_empty_store(fn ->
          {Schedule.day_rows(today), assigns(mount_screen(Schedule)).rows}
        end)

      assert rows == [],
             "`day_rows/1` answered #{length(rows)} rows for today against an empty store"

      assert mounted == [],
             "the mount assigned #{length(mounted)} rows that `day_rows/1` says do not exist"
    end

    test "the subtitle counts nothing, rather than counting the drawing" do
      # `header/3`'s `N items` is the one place on the page where the fallback
      # was legible without reading a single card, and it is the line the
      # design-literal sweeps read the screen's day count from.
      texts = with_empty_store(fn -> calendar_texts() end)

      assert Enum.any?(texts, &String.ends_with?(&1, "· 0 items")),
             "the Schedule's mono subtitle does not say `0 items` on an empty day:\n" <>
               Enum.map_join(texts, "\n", &"  #{inspect(&1)}")
    end

    test "no name is given to two nodes" do
      # `onNodeWithTag` throws on the second match, so a repeated tag makes both
      # nodes untestable on a device. Screen 02 repeated `row_event` for exactly
      # as long as `drawn_rows/0` was rendered — two of its five rows are
      # `kind: "event"` with no stored event to name — and this is the claim
      # that struck it off `Kati.ScreenTapSweepTest`'s `@known_collisions`.
      tags = with_empty_store(fn -> tap_tags(calendar_tree()) end)

      assert tags == Enum.uniq(tags),
             "the empty Schedule repeats #{inspect(tags -- Enum.uniq(tags))}"

      refute :row_event in tags,
             "`row_event` is the bare tag a row with no stored event carries. Nothing on this " <>
               "page has one any more, and a page that draws it is drawing the sample again"
    end
  end

  describe "a device with something on it" do
    test "one appointment on today is enough to put the timeline back" do
      texts = in_a_real_day(fn _events -> calendar_texts() end)

      for {_from, _to, title} <- @rows do
        assert title in texts, "a stored event is not on the timeline"
      end

      for literal <- @no_events do
        refute literal in texts,
               "the Schedule says #{inspect(literal)} over three appointments it is drawing"
      end
    end

    test "and the rows are the stored ones, not the drawn ones dressed up" do
      texts = in_a_real_day(fn _events -> calendar_texts() end)

      present = Enum.filter(fabricated(), &(&1 in texts))

      assert present == [],
             "a real day is drawn with the drawing's copy mixed into it:\n" <>
               Enum.map_join(present, "\n", &"  #{inspect(&1)}")
    end
  end

  describe "empty, versus not allowed to look" do
    test "every permission state maps to one of the two, and only three are a refusal" do
      # `Kati.Permissions` documents four states plus `:unknown`, and they are
      # not symmetric: Android reports never-asked and permanently-refused
      # identically. All three answers a person can act on are a refusal here.
      for state <- [:unasked, :denied, :blocked] do
        assert Schedule.empty_reason([], state) == :no_permission,
               "#{inspect(state)} means Kati may not read the calendar, and an empty day is " <>
                 "not what it should say"
      end

      assert Schedule.empty_reason([], :granted) == :no_events,
             "a granted calendar with nothing on it is empty, not blocked"
    end

    test "no answer is not a refusal" do
      # `:unknown` is what `Kati.Permissions.status/1` returns when the native
      # half is absent — every host test, and any device whose bridge method has
      # gone. Reading it as denied would send somebody who has already granted
      # the permission into system settings to fix nothing.
      assert Schedule.empty_reason([], :unknown) == :no_events
    end

    test "a day that holds something is never either card, whatever the permission says" do
      for state <- [:unasked, :denied, :blocked, :granted, :unknown] do
        assert Schedule.empty_reason([real_row()], state) == :no_events,
               "#{inspect(state)} changed what a day with an event on it is"
      end
    end

    test "the refusal states what Kati wanted it for, and where the control is" do
      texts = texts_of(rendered(rows: [], access: :denied))

      for literal <- @no_permission do
        assert literal in texts,
               "a Schedule Kati may not read renders nothing saying #{inspect(literal)}"
      end

      for literal <- @no_events do
        refute literal in texts,
               "it says #{inspect(literal)} about a calendar it cannot see. That is the one " <>
                 "sentence this state exists to stop being said"
      end
    end

    test "and the sentence it states the purpose with is still screen 40's own" do
      # `@no_permission`'s three lines are the only copy in either root's empty
      # state that no test opens a board to check. The other two states are tied
      # to a drawing by `Kati.ScreenEmptyDatabaseTest`'s `@quoted`, which asserts
      # a line at both ends — still on the board, still on the screen. This card
      # cannot go in that list and the list says why: the branch needs
      # `Kati.Permissions.status(:calendar)` to answer a refusal, and on a host
      # it answers `:unknown`, so the render that sweep makes never reaches it.
      #
      # Which left the citation in `Kati.Screens.Calendar`'s moduledoc —
      # *"screen 40's Calendars row, word for word"* — as the only thing saying
      # where this sentence comes from, and a moduledoc is not a check. A
      # re-export of 40 that reworded the row would leave this screen quoting a
      # sentence no board says any more, and the copy would drift while every
      # test here went on passing against the constant above.
      #
      # So the board is opened, here, at the end the sweep cannot reach. Same
      # shape as `Kati.ScreenStatsEmptyTest`'s *the drawing's figures are still
      # the ones being refuted*: the file's own constants are checked against the
      # artboard rather than trusted. The other end — that the screen renders
      # them — is the test directly above, which is why this one asserts only
      # the board half.
      board = File.read!(Path.join(__DIR__, "../design/screens/40.html"))

      assert board =~ "To show your appointments beside your episodes. Kati only reads them.",
             "screen 40's Calendars row no longer words the purpose this card quotes, so " <>
               "`@no_permission`'s second line is this file's invention rather than the " <>
               "design's. Re-read 40 and take the new wording, or say here why the card " <>
               "keeps the old one"

      # The third line names a place rather than quoting a sentence, so what is
      # checked is that the place is still there: 40 is the board that draws the
      # Allow control, on a row labelled Calendars, under the `This device`
      # heading. If any of the three moved, the card is sending a person to a
      # screen that no longer has what it promised.
      for word <- ["Allow", "Calendars", "This device"] do
        assert board =~ word,
               "screen 40 no longer draws #{inspect(word)}, and this card tells the user to " <>
                 "look for it there. A direction to a control that has moved is worse than " <>
                 "no direction"
      end
    end

    test "and an empty calendar it CAN see never claims to be locked out" do
      texts = texts_of(rendered(rows: [], access: :granted))

      for literal <- @no_events, do: assert(literal in texts)

      for literal <- @no_permission do
        refute literal in texts,
               "an empty calendar Kati has been granted says #{inspect(literal)}"
      end
    end

    test "a filter that empties the day is the filter's emptiness, not the permission's" do
      # The trap this closes: `timeline/2` sees the FILTERED list, so a day
      # holding one appointment goes empty under the Money chip. Reading the
      # permission off that list would put "Kati cannot see your calendar" on a
      # screen that is at that moment drawing the person's own event one chip
      # away.
      texts = texts_of(rendered(rows: [real_row()], filter: "Money", access: :denied))

      for literal <- @no_permission do
        refute literal in texts,
               "the Money chip made the Schedule claim it cannot read a calendar it just drew"
      end

      assert "Nothing scheduled" in texts
    end
  end

  describe "the emptiness this file rests on" do
    test "the transaction is rolled back, so the rest of the suite keeps its rows" do
      # Every assertion above is a claim about a store with nothing in it, and
      # every such claim is satisfied by a store that was empty to begin with.
      # This one writes first and asks the same question of a row it knows
      # exists — seen outside, unseen inside, there again after.
      calendar = calendar!()
      event = event!(calendar, Kati.Time.today(), ~T[07:00:00], ~T[07:30:00], "Probe")

      on_exit(fn ->
        Kati.Repo.query!("DELETE FROM events WHERE id = ?1", [event.id])
        Kati.Repo.query!("DELETE FROM calendars WHERE id = ?1", [calendar.id])
      end)

      assert Ash.get!(Event, event.id)

      inside = with_empty_store(fn -> Ash.read!(Event) end)

      assert inside == [],
             "the deletes did not reach `events`, so nothing above was rendered against an " <>
               "empty store"

      assert Ash.get!(Event, event.id),
             "a row written before the transaction is gone after it rolled back. This module " <>
               "shares one database file with every other test and would be deleting their " <>
               "fixtures"
    end
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  # The fabricated strings, read off the screen rather than copied, so a sample
  # edited in `Kati.Screens.Calendar` cannot walk out of this list. The airing
  # group's members ride along: they are drawn only while it is open, and a
  # round that opened it by default would put three more invented titles on a
  # first launch.
  defp fabricated do
    Enum.flat_map(Schedule.drawn_rows(), fn row ->
      [row.time, row.title, row.meta] ++
        Enum.flat_map(Map.get(row, :airing, []), fn member -> [member.title, member.meta] end)
    end)
  end

  # The screen rendered with the assigns `load/1` builds, minus whichever of
  # them the test is replacing. `:access` is the reason this exists: on a host
  # `Kati.Permissions.status/1` cannot answer anything but `:unknown`, so the
  # refusal card is unreachable through a mount.
  defp rendered(overrides) do
    %{date: Kati.Time.today(), rows: [], filter: "All", menu?: false, access: :unknown}
    |> Map.merge(Map.new(overrides))
    |> Schedule.content()
  end

  # One stored event's row, in the shape `day_rows/1` hands the render. Built
  # rather than queried: `empty_reason/2` reads the length of the list and
  # nothing else about it, and a fixture would tie a pure question to a
  # transaction.
  defp real_row do
    Schedule.shaped(%{
      id: "kati:calendar-empty-state-row",
      time: "09:30",
      title: "Standup",
      meta: "09:30 – 09:45",
      kind: :event,
      location: nil,
      now?: false
    })
  end

  defp calendar_tree, do: tree(mount_screen(Schedule))

  defp calendar_texts, do: texts_of(calendar_tree())

  defp texts_of(tree), do: tree |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  # Every Material Symbol in a tree. `Kati.UI.symbol/2` draws one as a `Text`
  # in `symbols`/`symbols_filled`, so a glyph is a text node like any other and
  # a plain substring search cannot say which node drew it.
  defp glyphs(tree) do
    for node <- find_all(tree, :text),
        String.starts_with?(node.props[:font_family] || "", "symbols"),
        do: node.props[:text]
  end

  # Every `on_tap` atom the tree carries. Tuple tags are skipped deliberately:
  # `Mob.Renderer` emits `accessibility_id` only for `{pid, atom}`, so those are
  # the only ones a device can address and the only ones that can collide.
  defp tap_tags(tree) do
    for node <- flatten(tree),
        {_pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  defp with_empty_store(fun) do
    {:error, {:done, result}} =
      Kati.Repo.transaction(fn ->
        for table <- @emptied, do: Kati.Repo.query!("delete from #{table}")
        Kati.Repo.rollback({:done, fun.()})
      end)

    result
  end

  defp in_a_real_day(fun) do
    {:error, {:done, result}} =
      Kati.Repo.transaction(fn ->
        for table <- @emptied, do: Kati.Repo.query!("delete from #{table}")
        calendar = calendar!()
        today = Kati.Time.today()

        events = for {from, to, title} <- @rows, do: event!(calendar, today, from, to, title)

        Kati.Repo.rollback({:done, fun.(events)})
      end)

    result
  end

  defp calendar! do
    Kati.Calendars.Calendar
    |> Ash.Changeset.for_create(:create, %{
      display_name: "Calendar empty state #{System.unique_integer([:positive])}",
      kind: :local
    })
    |> Ash.create!()
  end

  # The same timing `Kati.Seeds` writes: a UTC instant for the range query, the
  # authored wall clock beside it, and the length as a DURATION rather than an
  # end instant — which is what `Kati.Calendars.Event`'s moduledoc requires.
  defp event!(calendar, date, from, to, summary) do
    zone = Kati.Time.device_zone()
    naive = NaiveDateTime.new!(date, from)
    {:ok, utc} = Kati.Time.to_utc(naive, zone)
    minutes = div(Time.diff(to, from, :second), 60)

    Event
    |> Ash.Changeset.for_create(:create, %{
      uid: "kati-calendar-empty-state-#{System.unique_integer([:positive])}@kati",
      calendar_id: calendar.id,
      origin: :kati,
      summary: summary,
      kind: :event,
      status: :confirmed,
      dtstart_utc: utc,
      dtstart_wall: Calendar.strftime(naive, "%Y%m%dT%H%M%S"),
      tzid: zone,
      duration_iso: "PT#{minutes}M",
      sync_state: :local_only
    })
    |> Ash.create!()
  end
end
