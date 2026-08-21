defmodule Kati.SeedsTest do
  @moduledoc """
  The seed path, against the real SQLite file the other schema tests use.

  Two things are being proven, and they are separate:

    * **The guard** — a group runs once and is a no-op afterwards. Easy to fake:
      a seeder that writes nothing passes "seeding twice leaves the same count"
      perfectly. So every count assertion here is anchored to the number the
      **design's own sample module** states, not to a literal typed into the
      test. If the seeder writes nothing, or writes a different day than the one
      screen 09 draws, these fail.
    * **The upserts** — `run(force: true)` bypasses the guard entirely, so
      running it twice exercises the write path twice. Row counts *and row ids*
      must be unchanged, which is what tells an upsert apart from a
      delete-and-recreate.
  """
  use ExUnit.Case, async: false

  alias Kati.Calendar.SampleDay
  alias Kati.Calendars.Account
  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.Event
  alias Kati.Library.Sample, as: LibrarySample
  alias Kati.Media.CachedTitle
  alias Kati.Seeds
  alias Kati.Settings.CalendarsSample
  alias Kati.Subscriptions.Sample, as: SubscriptionsSample
  alias Kati.Theme.Palette

  # The whole suite shares one SQLite file (see test/test_helper.exs), so
  # "an empty database" has to be made rather than assumed. Child tables first:
  # events and overrides carry the foreign keys.
  @tables ~w(event_occurrence_overrides events calendars calendar_accounts cached_titles)

  setup do
    empty_the_tables!()

    # And again afterwards, because what this module leaves behind is not inert:
    # the seeder writes screen 09's fourteen events onto TODAY, and the screen
    # tests mount `Kati.Screens.Home`, `Kati.Screens.Calendar` and screen 09
    # expecting today to be empty so they fall back to the drawing's own rows.
    # Whether those tests pass would otherwise depend on the shuffle putting
    # them before this module rather than after it.
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  defp counts do
    %{
      accounts: Ash.count!(Account),
      calendars: Ash.count!(CalendarRow),
      events: Ash.count!(Event),
      cached_titles: Ash.count!(CachedTitle)
    }
  end

  defp ids(resource), do: resource |> Ash.read!() |> Enum.map(& &1.id) |> Enum.sort()

  # The design's own numbers, read out of the sample modules rather than copied
  # into this file, so a change to a drawing shows up here as a failure.
  defp designed_accounts, do: length(CalendarsSample.accounts())
  defp designed_calendars, do: length(CalendarsSample.calendars())
  defp designed_titles, do: length(LibrarySample.titles())

  # Screen 09's header: "14 items · 2 clashes". Its moduledoc is explicit that
  # the count includes the all-day release and both merged money renewals, which
  # is exactly the set of rows the seeder writes.
  defp designed_items do
    SampleDay.summary() |> String.split(" ") |> hd() |> String.to_integer()
  end

  defp pence("£" <> amount) do
    [pounds, p] = String.split(amount, ".")
    String.to_integer(pounds) * 100 + String.to_integer(p)
  end

  describe "seeding an empty database" do
    test "writes the design's own row counts, not an arbitrary few" do
      assert counts() == %{accounts: 0, calendars: 0, events: 0, cached_titles: 0}

      report = Seeds.run()

      assert report.calendars.status == :seeded
      assert report.media.status == :seeded

      # What the run says it wrote.
      assert report.calendars.rows == %{
               accounts: designed_accounts(),
               calendars: designed_calendars(),
               events: designed_items()
             }

      assert report.media.rows == %{cached_titles: designed_titles()}

      # And what is actually in the tables, which is the assertion that would
      # catch a report computed from the input list rather than the writes.
      assert counts() == %{
               accounts: designed_accounts(),
               calendars: designed_calendars(),
               events: designed_items(),
               cached_titles: designed_titles()
             }

      # Guard against the sample modules themselves going empty and taking the
      # assertions above with them.
      assert designed_accounts() == 3
      assert designed_calendars() == 4
      assert designed_items() == 14
      assert designed_titles() == 9
    end

    test "the calendars are screen 32's four, with its visibility and its colours" do
      Seeds.run()

      rows = CalendarRow |> Ash.read!() |> Map.new(&{&1.display_name, &1})

      assert Map.keys(rows) |> Enum.sort() ==
               CalendarsSample.calendars() |> Enum.map(& &1.title) |> Enum.sort()

      for %{title: title, color: colour, on: on?} <- CalendarsSample.calendars() do
        row = Map.fetch!(rows, title)

        assert row.visible == on?, "#{title}: visibility must match the drawing"

        # colour_source keeps the provider's value verbatim; colour_token is the
        # palette slot. A token that is not in the palette renders as nothing,
        # and a token whose light value is not the drawn colour is the wrong
        # slot — both are silent, so both are checked.
        token = Enum.find(Palette.tokens(), &(&1.name == row.colour_token))
        assert token, "#{title}: #{inspect(row.colour_token)} is not a palette token"
        assert token.light == colour, "#{title}: #{row.colour_token} is not the drawn colour"

        assert row.colour_source ==
                 "#" <> (colour |> rem(0x1000000) |> Integer.to_string(16))
      end
    end

    test "the accounts are screen 32's three, with their live/stale states" do
      Seeds.run()

      rows = Account |> Ash.read!() |> Map.new(&{&1.display_name, &1})

      assert Map.keys(rows) |> Enum.sort() ==
               CalendarsSample.accounts() |> Enum.map(& &1.title) |> Enum.sort()

      for %{title: title, state: state} <- CalendarsSample.accounts() do
        assert Map.fetch!(rows, title).state == state
      end

      # iCloud's own subtitle says "2 calendars" and Google's says "1 calendar";
      # the split has to satisfy both or the drawing and the database disagree.
      by_account =
        CalendarRow
        |> Ash.read!()
        |> Enum.group_by(& &1.account_id)
        |> Map.new(fn {id, cals} -> {id, length(cals)} end)

      assert by_account[Map.fetch!(rows, "iCloud").id] == 2
      assert by_account[Map.fetch!(rows, "Google").id] == 1
    end

    test "every row screen 09 draws becomes an event, with :todo mapped to :reminder" do
      Seeds.run()

      events = Ash.read!(Event)
      summaries = MapSet.new(events, & &1.summary)

      for occ <- SampleDay.occurrences() do
        assert occ.title in summaries, "#{occ.title} is drawn but was not seeded"
      end

      for item <- SampleDay.all_day() do
        assert item.title in summaries, "#{item.title} is drawn but was not seeded"
      end

      # Event.kind has no :todo — a todo is a reminder that can be ticked. The
      # sample uses :todo, so the mapping has to happen somewhere.
      assert Enum.any?(SampleDay.occurrences(), &(&1.kind == :todo)),
             "the sample no longer exercises the :todo mapping"

      kinds = MapSet.new(events, & &1.kind)
      refute :todo in kinds
      assert :reminder in kinds
      assert :habit in kinds
      assert :air_date in kinds
    end

    test "the all-day release is date-valued, not a midnight instant" do
      Seeds.run()

      [item] = SampleDay.all_day()
      row = Event |> Ash.read!() |> Enum.find(&(&1.summary == item.title))

      assert row.is_all_day
      assert row.dtstart_date == Kati.Time.today()
      assert is_nil(row.dtstart_utc)
    end

    test "the two money events add up to the total screen 09 prints" do
      Seeds.run()

      money = Event |> Ash.read!() |> Enum.filter(&(&1.kind == :money))
      assert length(money) == SampleDay.money().count

      total = money |> Enum.map(&pence(&1.description)) |> Enum.sum()
      assert total == pence(SampleDay.money().total)

      # And the descriptions are the subscription sample's prices, not numbers
      # invented here.
      prices = SubscriptionsSample.services() |> Enum.map(& &1.price)
      for row <- money, do: assert(row.description in prices)
    end

    test "timed events land on today at the clock time the drawing gives" do
      Seeds.run()

      standup = Event |> Ash.read!() |> Enum.find(&(&1.summary == "Standup"))
      occ = Enum.find(SampleDay.occurrences(), &(&1.title == "Standup"))

      expected_wall =
        Kati.Time.today()
        |> NaiveDateTime.new!(~T[00:00:00])
        |> NaiveDateTime.add(occ.start_min * 60, :second)
        |> Calendar.strftime("%Y%m%dT%H%M%S")

      assert standup.dtstart_wall == expected_wall
      assert standup.duration_iso == "PT#{occ.end_min - occ.start_min}M"
      # Both are written: the wall clock is what a recurrence expands in, the
      # instant is only the range-query key.
      assert standup.dtstart_utc
      assert standup.tzid == Kati.Time.device_zone()
    end

    test "the cached titles are the library grid's nine, keyed for a tracking row" do
      Seeds.run()

      rows = CachedTitle |> Ash.read!() |> Map.new(&{&1.title, &1})

      assert Map.keys(rows) |> Enum.sort() ==
               LibrarySample.titles() |> Enum.map(& &1.title) |> Enum.sort()

      for sample <- LibrarySample.titles() do
        row = Map.fetch!(rows, sample.title)

        # The join key a tracking row will use — it must survive a cache wipe,
        # so it is computed, not stored twice.
        assert row.source == Seeds.sample_source()
        assert row.source_id == Seeds.sample_source_id(sample.seed)
        assert Seeds.sample_seed(row.source_id) == sample.seed

        assert row.kind == if(sample.kind == :series, do: :tv, else: :movie)
        # allow_nil?: false — a row with no age cannot be evicted.
        assert row.fetched_at
      end

      # Both kinds are present, so the mapping is actually exercised.
      kinds = rows |> Map.values() |> MapSet.new(& &1.kind)
      assert :tv in kinds
      assert :movie in kinds
    end
  end

  describe "seeding twice" do
    test "the second run is skipped and the counts do not move" do
      first = Seeds.run()
      after_first = counts()

      assert first.calendars.status == :seeded
      assert after_first.events == designed_items()

      second = Seeds.run()

      assert second.calendars.status == :skipped
      assert second.media.status == :skipped
      assert second.calendars.rows == %{}
      assert counts() == after_first
    end

    test "forcing past the guard still writes each row once, in place" do
      # The guard makes the test above pass even for a seeder that writes
      # nothing on a second call. This one runs the write path twice.
      Seeds.run()
      after_first = counts()
      calendar_ids = ids(CalendarRow)
      event_ids = ids(Event)
      title_ids = ids(CachedTitle)

      forced = Seeds.run(force: true)

      assert forced.calendars.status == :seeded
      assert forced.calendars.rows.events == designed_items()
      assert counts() == after_first

      # Same rows, not replacements: an upsert that deleted and recreated would
      # keep the counts and change every id.
      assert ids(CalendarRow) == calendar_ids
      assert ids(Event) == event_ids
      assert ids(CachedTitle) == title_ids
    end
  end

  describe "seeding a database that already holds data" do
    test "changes nothing in the group whose tables are occupied" do
      {:ok, mine} =
        CalendarRow
        |> Ash.Changeset.for_create(:create, %{display_name: "Mine", kind: :local})
        |> Ash.create()

      report = Seeds.run()

      assert report.calendars.status == :skipped
      assert report.calendars.rows == %{}

      # Not one row added, and the user's own row untouched.
      assert Ash.count!(CalendarRow) == 1
      assert Ash.count!(Account) == 0
      assert Ash.count!(Event) == 0
      assert Ash.get!(CalendarRow, mine.id).display_name == "Mine"
    end

    test "a busy calendar table does not stop the media group seeding" do
      CalendarRow
      |> Ash.Changeset.for_create(:create, %{display_name: "Mine", kind: :local})
      |> Ash.create!()

      report = Seeds.run()

      assert report.calendars.status == :skipped
      assert report.media.status == :seeded
      assert Ash.count!(CachedTitle) == designed_titles()
    end

    test "an occupied table anywhere in a group blocks the whole group" do
      # Events are empty and calendars are empty, but one account exists — the
      # guard is the group, not the first table, so nothing may be written.
      Account
      |> Ash.Changeset.for_create(:create, %{provider: :local, display_name: "Mine"})
      |> Ash.create!()

      report = Seeds.run(only: [:calendars])

      assert report.calendars.status == :skipped
      assert Ash.count!(CalendarRow) == 0
      assert Ash.count!(Event) == 0
    end
  end

  describe "the group list" do
    test "empty?/1 answers per group and flips once a group is seeded" do
      assert Seeds.empty?(:calendars)
      assert Seeds.empty?(:media)

      Seeds.run(only: [:media])

      assert Seeds.empty?(:calendars)
      refute Seeds.empty?(:media)
    end

    test "only: confines the run to the groups named" do
      report = Seeds.run(only: [:media])

      assert Map.keys(report) == [:media]
      assert report.media.status == :seeded
      assert Ash.count!(CachedTitle) == designed_titles()
      # Untouched, and not merely reported as skipped.
      assert counts().calendars == 0
      assert counts().accounts == 0
    end

    test "every group names markers that are real resources it can count" do
      for group <- Seeds.groups() do
        assert group.markers != [], "#{group.name} has no marker to guard on"
        assert is_function(group.seed, 0)

        for marker <- group.markers do
          assert Ash.count!(marker) == 0
        end
      end
    end

    test "empty?/1 refuses a name that is not a group" do
      assert_raise ArgumentError, fn -> Seeds.empty?(:nope) end
    end
  end
end
