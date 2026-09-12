defmodule Kati.Calendars.TodayTest do
  @moduledoc """
  The timeline row's sub-line, and the field the screens route by.

  ## What this file is for

  A row used to leave `Kati.Calendars.Today` carrying one composed English
  sentence and nothing else, so two different things had to be read back out of
  it. Boards 55 and 56 drew that sentence
  under a Persian title, ending every real row in `Airs today` or `Habit`; and
  `Kati.Screens.Calendar.kind/1` searched it for `"Money"` to decide a card's
  shape, its chip and the screen a tap pushed — over a string that begins with a
  location the user typed.

  The row carries `:kind` and `:location` now. Which makes two claims that have
  to be settled by a run rather than asserted in a moduledoc, and they pull in
  opposite directions:

    * **English must not have moved.** Screens 01, 02 and 28 draw this line and
      are compared pixel-by-pixel with `.scratch/design/audit/NN.png`, so a row's
      sub-line is inside the frame. `@english` is that table, and it may only
      change when a capture does.
    * **Persian must actually be Persian.** Not "different from English" —
      Persian: no Latin letter anywhere in a Kati-written word.

  ## Why nothing here writes a row

  This suite has no Ecto sandbox and shares one SQLite file, and
  `Kati.ScreenDarkWidgetsTest` opens by asserting `Kati.Calendars.Today.rows()`
  is `[]` — an event inserted here would fail that test from another file, on
  some seeds and not others. So `row/2` is exercised against an
  `%Kati.Calendars.Event{}` built in memory, which is the same struct a read
  returns and the reason that function is public.
  """
  use ExUnit.Case, async: true

  alias Kati.Calendars.Event
  alias Kati.Calendars.Today
  alias Kati.Screens.Calendar

  # Every kind the column accepts, read off the resource rather than written out
  # here. A kind added to `Kati.Calendars.Event` and never given a word would
  # otherwise be invisible to this file — `kind_label/2` has a catch-all, so it
  # would answer "Calendar" and nothing would say so.
  @kinds Ash.Resource.Info.attribute(Event, :kind).constraints[:one_of]

  # The five English words, exactly as this module has always written them.
  @english %{
    air_date: "Airs today",
    meal: "Meals",
    habit: "Habit",
    money: "Money",
    event: "Calendar",
    reminder: "Calendar",
    note: "Calendar"
  }

  # UTC, so the formatted time in an assertion is the time in the fixture and
  # not a fact about the machine running the suite.
  @zone "Etc/UTC"

  defp event(attrs) do
    struct!(
      Event,
      Map.merge(
        %{
          summary: "Dentist — Marlow Clinic",
          location: nil,
          kind: :event,
          is_all_day: false,
          dtstart_utc: ~U[2026-08-21 11:00:00.000000Z]
        },
        Map.new(attrs)
      )
    )
  end

  defp row(attrs), do: Today.row(event(attrs), @zone)

  # Arabic script, plus the zero-width non-joiner a Persian compound needs
  # (وعده‌ها is one) and the space between words. A Latin letter anywhere in a
  # word Kati wrote is the whole of the bug this change is about.
  defp persian?(string) do
    string
    |> String.to_charlist()
    |> Enum.all?(fn c -> c in 0x0600..0x06FF or c == 0x200C or c == ?\s end)
  end

  describe "the English label, which is what the captured frames hold" do
    test "every kind's word is unchanged" do
      for {kind, word} <- @english do
        assert Today.kind_label(kind) == word,
               "the English label for #{inspect(kind)} moved, and screens 01, 02 and 28 are " <>
                 "compared pixel-by-pixel against frames that hold it"

        assert Kati.Locale.as(:en, fn -> Today.kind_label(kind) end) == word,
               "asking for English explicitly must answer what the default answers"
      end
    end

    test "every kind the schema allows has a word of its own here" do
      assert Enum.sort(@kinds) == @kinds |> Enum.uniq() |> Enum.sort()

      assert Enum.sort(@kinds) == @english |> Map.keys() |> Enum.sort(),
             "`Kati.Calendars.Event` and this table disagree about which kinds exist, so a " <>
               "kind is being labelled by `kind_label/1`'s catch-all with nothing checking it"
    end

    test "an unknown locale answers in English rather than raising" do
      # `Kati.Locale` ships two, and English is its default; a third arriving
      # before its words do must degrade to a readable line, not a crash.
      # gettext's own fallback since mishka-group/kati#103 folded board 56: the
      # label took a locale argument while a mirror needed to ask for the other
      # language by name, and now there is one caller in the reader's own.
      for kind <- @kinds,
          do: assert(Kati.Locale.as(:de, fn -> Today.kind_label(kind) end) == @english[kind])
    end

    test "no label is ever empty, in either locale" do
      # `meta/1` drops blanks before joining and then relies on the label never
      # being one, which is why it has no "the line came out empty" branch.
      for kind <- @kinds, locale <- [:en, :fa] do
        refute Kati.Locale.as(locale, fn -> Today.kind_label(kind) end) == ""
      end
    end
  end

  describe "the English sub-line, byte for byte" do
    test "a kind with no location is the label alone" do
      for kind <- @kinds do
        assert Today.meta(%{location: nil, kind: kind}) == @english[kind]
      end
    end

    test "the location leads, joined by the middot the drawings use" do
      assert Today.meta(%{location: "Marlow Clinic", kind: :habit}) == "Marlow Clinic · Habit"
      assert Today.meta(%{location: "Lumen+", kind: :air_date}) == "Lumen+ · Airs today"
    end

    test "an empty location is dropped rather than joined to nothing" do
      # A stored `""` is a column that was written to and says nothing, and
      # ` · Airs today` with a dangling separator is worse than the label alone.
      assert Today.meta(%{location: "", kind: :air_date}) == "Airs today"
    end

    test "the event itself answers the same line its row does" do
      # `meta/1` takes the row or the `%Event{}` it came from, and the two are
      # the same sentence — the row's `:meta` is this call.
      event = event(kind: :money, location: "Lumen+")

      assert Today.meta(event) == "Lumen+ · Money"
      assert Today.row(event, @zone).meta == Today.meta(event)
    end
  end

  describe "the Persian sub-line" do
    test "every kind's word is Persian, not merely different" do
      for kind <- @kinds do
        word = Kati.Locale.as(:fa, fn -> Today.kind_label(kind) end)

        assert persian?(word),
               "#{inspect(kind)} answers #{inspect(word)} in Persian, which is not Persian — " <>
                 "screens 55 and 56 draw this word at the end of every real row"

        refute word == @english[kind]
      end
    end

    test "the line is the user's own words joined to a Persian word" do
      Kati.Locale.as(:fa, fn ->
        assert Today.meta(%{location: "کلینیک مارلو", kind: :habit}) == "کلینیک مارلو · عادت"
        assert Today.meta(%{location: nil, kind: :air_date}) == "پخش امروز"
      end)
    end

    test "the user's own words are not rewritten on the way past" do
      # A location is what the user typed and a title is their own words; only
      # the label is Kati's, so only the label changes language. Same rule
      # board 55 states for digits.
      assert Kati.Locale.as(:fa, fn -> Today.meta(%{location: "Lumen+", kind: :air_date}) end) ==
               "Lumen+ · پخش امروز"
    end

    test "a real row can be recomposed in Persian without touching its English" do
      # This is the whole fix, in one assertion: the field stays English for
      # screens 01 and 02, and 55 and 56 ask for their own line off the same row.
      row = row(kind: :air_date, location: "Lumen+")

      assert row.meta == "Lumen+ · Airs today"
      assert Kati.Locale.as(:fa, fn -> Today.meta(row) end) == "Lumen+ · پخش امروز"
    end
  end

  describe "the row" do
    test "carries the event's own kind, uncollapsed" do
      # `:reminder` and `:event` share a label and draw differently on screen 56
      # — a hollow ring against a rule — so the row keeps the value that can
      # still tell them apart. The old shape could not say this at all.
      assert row(kind: :reminder).kind == :reminder
      assert row(kind: :event).kind == :event
      assert row(kind: :air_date).kind == :air_date
    end

    test "carries the event's location, separately from the composed line" do
      assert row(location: "Marlow Clinic").location == "Marlow Clinic"
      assert row(location: nil).location == nil
    end

    test "still answers the time, the title and the hour-ahead flag" do
      row = row(summary: "Morning run", dtstart_utc: ~U[2026-08-21 08:00:00.000000Z])

      assert row.time == "08:00"
      assert row.title == "Morning run"
      # Long past, on any clock this suite runs on.
      refute row.now?
    end

    test "a summary-less event is Untitled rather than nil" do
      assert row(summary: nil).title == "Untitled"
    end
  end

  describe "screen 02 routes by the kind, not by words in the user's own text" do
    test "a location the user typed cannot change where a row goes" do
      # The regression this change exists for. `String.contains?(meta, "Money")`
      # over a line that starts with the location sent an ordinary appointment
      # at a place called Money to Subscriptions, drawn as a payment.
      row = row(kind: :event, location: "Money")

      assert Calendar.kind(row) == "event"
      assert Calendar.shaped(row).shape != :money

      # And the other two words the old cond looked for.
      assert Calendar.kind(row(kind: :event, location: "Airs today")) == "event"
      assert Calendar.kind(row(kind: :event, location: "Meals")) == "event"
    end

    test "each event kind maps onto the chip it belongs to" do
      chips = %{
        meal: "meals",
        air_date: "screen",
        money: "money",
        habit: "event",
        event: "event",
        reminder: "event",
        note: "event"
      }

      for kind <- @kinds do
        assert Calendar.kind(row(kind: kind)) == chips[kind]
      end
    end

    test "the chips still filter what they always filtered" do
      rows = Enum.map(@kinds, &Calendar.shaped(row(kind: &1)))

      # The KEY, since mishka-group/kati#103. The chip's tag was
      # `String.to_atom("filter_" <> label)` and this matched `"Screen"`, so
      # board 56's نمایش chip tagged `:"filter_نمایش"` and fell through to the
      # Personal branch — the Screen filter hid the episodes it names.
      assert Calendar.visible(rows, :all) == rows
      assert Enum.map(Calendar.visible(rows, :money), & &1.kind) == ["money"]
      assert Enum.map(Calendar.visible(rows, :screen), & &1.kind) == ["screen"]

      assert Calendar.visible(rows, :personal)
             |> Enum.map(& &1.kind)
             |> Enum.uniq()
             |> Enum.sort() ==
               ["event", "meals"]
    end

    test "and the same four keys answer the same way in the other script" do
      rows = Enum.map(@kinds, &Calendar.shaped(row(kind: &1)))

      Kati.Locale.as(:fa, fn ->
        assert Enum.map(Calendar.visible(rows, :screen), & &1.kind) == ["screen"]
        assert Keyword.keys(Calendar.chips()) == [:all, :screen, :personal, :money]
        assert Keyword.fetch!(Calendar.chips(), :screen) == "نمایش"
      end)
    end

    test "a payment is drawn as money and an air date as airing" do
      assert Calendar.shaped(row(kind: :money)).shape == :money
      assert Calendar.shaped(row(kind: :air_date)).shape == :airing
    end

    test "shaping a row twice is shaping it once" do
      # `shaped/1` swaps the atom for one of the four chip names, so it has to
      # be able to read its own output — which is what the string clause on
      # `kind/1` is for.
      shaped = Calendar.shaped(row(kind: :air_date))

      assert Calendar.shaped(shaped) == shaped
      assert Calendar.kind(shaped) == "screen"
    end

    test "the drawn rows still name their own kind" do
      # `drawn_rows/0` states its kinds outright and never went through the
      # parser; it must not start needing one now.
      for drawn <- Calendar.drawn_rows() do
        assert Calendar.kind(drawn) == drawn.kind
      end
    end
  end

  # Board 56 is screen 02 read under `:fa` since mishka-group/kati#103, so the
  # questions this block asked of `Kati.Screens.ScheduleFa.shaped/1` are asked
  # of `Kati.Screens.Calendar.shaped/1` in the other locale. The mirror carried
  # its own `tone`/`lead` pair; the folded screen has one `:shape`, which is
  # what both boards' rows were always drawn from.
  describe "board 56 reads the same field" do
    test "a payment still gets the shape it always had" do
      assert Calendar.shaped(row(kind: :money)).shape == :money
    end

    test "an air date is its own shape, and a row that is not imminent settles" do
      assert Calendar.shaped(row(kind: :air_date)).shape == :airing
      assert Calendar.shaped(row(kind: :event)).shape == :done
    end

    test "the time is Persian-digited and the user's own title is not" do
      shaped =
        Kati.Locale.as(:fa, fn ->
          Calendar.shaped(row(summary: "Dentist", dtstart_utc: ~U[2026-08-21 20:00:00.000000Z]))
        end)

      assert shaped.time == "۲۰:۰۰"
      assert shaped.title == "Dentist"
    end

    test "and the same row in English keeps Latin digits" do
      shaped =
        Kati.Locale.as(:en, fn ->
          Calendar.shaped(row(summary: "Dentist", dtstart_utc: ~U[2026-08-21 20:00:00.000000Z]))
        end)

      assert shaped.time == "20:00"
    end
  end

  # The two tests above this block ask what shape a kind gets, and the block
  # before them asks what `Today.meta/1` composes. Neither asks the question the
  # whole change exists for — *what does the page actually draw under the title*
  # — and the answer was `Airs today` on both Persian screens for a full round
  # after `meta/1` and `:kind` existed to prevent it. A locale-aware composer
  # nothing calls is not a fix, so the assertions below are made against the two
  # screen functions rather than against `Kati.Calendars.Today`.
  describe "the Persian screens draw the Persian line" do
    test "board 56 composes its own sub-line for every kind" do
      # `row/1` builds the row, so the locale has to be in force for THAT call
      # rather than for the shaping: `Today.row/2` is where `:meta` is composed
      # and where the clock is digited.
      for kind <- @kinds do
        {drawn, persian} =
          Kati.Locale.as(:fa, fn ->
            {Calendar.shaped(row(kind: kind, location: nil)).meta, Today.kind_label(kind)}
          end)

        assert drawn == persian

        refute drawn == @english[kind],
               "board 56 draws #{inspect(drawn)} under a Persian title for #{inspect(kind)}"
      end
    end

    test "board 55 composes its own sub-line for every kind" do
      # Board 55 is screen 01 read under `:fa` since mishka-group/kati#103, and
      # it draws the timeline rows `Kati.Calendars.Today.rows/0` composes —
      # the same `:meta` board 56 draws, because there is one composer.
      for kind <- @kinds do
        {drawn, persian} =
          Kati.Locale.as(:fa, fn ->
            {Today.row(event(kind: kind, location: nil), @zone).meta, Today.kind_label(kind)}
          end)

        assert drawn == persian
        refute drawn == @english[kind]
      end
    end

    test "neither board draws a Latin letter Kati wrote" do
      # The location is the user's own words and stays as typed, so the check is
      # made on a row that has none: everything left in the line is Kati's.
      for kind <- @kinds do
        drawn = Kati.Locale.as(:fa, fn -> Calendar.shaped(row(kind: kind)).meta end)

        assert persian?(drawn),
               "a Persian timeline row draws #{inspect(drawn)} for #{inspect(kind)}"
      end
    end

    test "a location the user typed survives unrewritten" do
      assert Kati.Locale.as(:fa, fn ->
               Calendar.shaped(row(kind: :air_date, location: "Lumen+")).meta
             end) == "Lumen+ · پخش امروز"
    end

    test "the row's own field is the language it was built in" do
      # `:meta` is composed by `Today.row/2` at the moment the row is built, so
      # a row built in English carries English — which is what screens 01, 02
      # and 28 were captured drawing. The mirrors had to recompose it because
      # they were a second module reading a row somebody else had built; there
      # is one builder now, and it builds in the reader's own language.
      real = row(kind: :air_date, location: "Lumen+")

      assert real.meta == "Lumen+ · Airs today"

      assert Kati.Locale.as(:fa, fn ->
               Today.row(event(kind: :air_date, location: "Lumen+"), @zone).meta
             end) == "Lumen+ · پخش امروز"
    end
  end
end
