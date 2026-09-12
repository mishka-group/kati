defmodule Kati.Calendar.SampleMealDay do
  @moduledoc """
  Screen 52's day: Monday 17 August, with five meals on the spine.

  The design's caption states the decision this data exists to make visible:
  *"Meals join the spine on equal terms with a bronze lane colour, and inherit
  the density rules already written — five in a day collapse to one row exactly
  as six episodes do."* So the day is drawn twice over — eight expanded rows,
  then the collapsed summary underneath — because the screen is an argument
  about density, and one of those two states alone would not make it.

  Three row states, and they are three different facts:

    * **past** — `#F4F1EC`, no lift, muted title. The morning has happened.
    * **eaten** — past, plus a filled green check. A meal you logged.
    * **live** — card white with the usual lift, and an empty ring on the
      meals, because an unlogged meal is a thing you can still do.

  Bronze (`#B08E55`) is the meal lane throughout, which is what lets five rows
  read as one section without a heading.

  Stand-in data until the Meals domain lands, marked as such.

  ## The drawing in two scripts

  mishka-group/kati#103 folded the Persian mirrors away, so this fixture is
  rendered under `:fa` as well as `:en` and every string here had to become one
  of three things: a msgid, a number in the reader's own digits, or a name that
  is never translated. `Kati.Screens.MealsDay` was already doing all three for
  a **stored** day — `Kati.Locale.date/2` on its heading, `ngettext` on its
  tally, `Kati.Locale.number/1` on its chip counts — and a drawn day that kept
  its Latin was the one page on that screen where the two branches disagreed
  about what language the reader had chosen.

  The English pixels do not move. Every msgid is the drawing's own line
  character for character, the clocks print `%H:%M` in both scripts, and
  `1,960` keeps the drawing's grouping mark because `Kati.Locale.number/1`
  converts the digits and leaves the comma where board 59 puts it.
  """

  use Gettext, backend: Kati.Gettext

  @meal 0xFFB08E55
  @habit 0xFF4E9A73
  @personal 0xFF1A1917
  @screen 0xFFE8823C

  # Board 52's day as a DATE rather than as the three words it prints.
  #
  # `"Mon 17 Aug"` was stored as a string, and a string is Gregorian for ever:
  # a Persian reader's 17 August 2026 is ۲۶ مرداد ۱۴۰۵, which is a different
  # CALENDAR rather than a translation of this one — the half of
  # mishka-group/kati#103 gettext cannot do. `Kati.Locale.date/2`'s `:long` is
  # the same three parts the drawing prints (`%a %-d %b` in Latin), so the
  # English heading is `Mon 17 Aug` character for character, and it is the call
  # `Kati.Screens.MealsDay` already makes for a stored day and for an empty one
  # — the drawn day and the two real ones now head themselves the same way.
  #
  # 2026 because that is the year the boards are drawn in, and the weekday is
  # what fixes it: 17 August is a Monday there and in neither 2024 nor 2025.
  # `Kati.Locale.date/2`'s own doctest reads `date(~D[2026-08-16]) == "Sun 16
  # Aug"`, and screen 17's week runs 10 – 16 Aug with Thursday on the 13th.
  @on ~D[2026-08-17]

  @doc "The day the screen renders."
  @spec day() :: map()
  def day do
    %{
      title: Kati.Locale.date(@on, :long),
      # The drawing's own counts, not `rows/0`'s. Board 52 heads the day
      # `5 meals · 6 other items` and chips it `5 · 2 · 4` — eleven items —
      # while the spine underneath transcribes eight of them. The drawing is
      # the specification and this module is its transcription, so deriving
      # these would print `5 meals · 3 other items` and disagree with the frame
      # it exists to reproduce.
      subtitle:
        joined(
          ngettext("%{n} meal", "%{n} meals", 5, n: Kati.Locale.number(5)),
          ngettext("%{n} other item", "%{n} other items", 6, n: Kati.Locale.number(6))
        ),
      chips: chips(),
      rows: rows(),
      collapsed: collapsed(),
      note:
        gettext(
          "Five meals a day would drown the calendar, so they obey the same 3+ rule as episodes."
        )
    }
  end

  @doc """
  The section filters. `All` carries no count; the sections carry theirs.

  **The label is a key and stays English in every locale.**
  `Kati.Screens.MealsDay.kind/1` answers one of these four strings off a row's
  lane colour, `visible/2` compares the active filter against that answer, and
  `chip/3` builds `filter_<label>` into the tap's atom — so a Persian label
  here would empty the spine on every chip but `All` and name a tag no clause
  in `handle_tap/2` can read. `Kati.Screens.MealsDay.chip_label/1` is where the
  word becomes Persian, at the last moment before it is drawn, and its own doc
  carries the long version of this argument.

  The COUNT is the reader's, which is what `chips_for/1` already does for a
  stored day: a chip reading `Meals ۵` beside one reading `Screen 2` would be
  one row of counts in two numeral systems.
  """
  @spec chips() :: [{String.t(), String.t() | nil}]
  def chips,
    do: [
      {"All", nil},
      {"Meals", Kati.Locale.number(5)},
      {"Screen", Kati.Locale.number(2)},
      {"Personal", Kati.Locale.number(4)}
    ]

  @doc """
  The day's spine, in clock order, meals and everything else together.

  Clock times are `Kati.Locale.time/1`'s rather than the strings they were,
  which is the same call `Kati.Calendars.Today.row/2` makes for a real row: the
  clock is 24-hour in both scripts and what changes is the numerals, so a
  gutter reading ۰۷:۳۰ against one reading 08:00 would be one column in two
  numeral systems.
  """
  @spec rows() :: [map()]
  def rows do
    [
      %{
        time: Kati.Locale.time(~T[07:30:00]),
        rule: @meal,
        # Slot and dish in one msgid, the way `Kati.Screens.Calendar`'s own
        # drawn rows carry `Dentist — Marlow Clinic` whole. `Kati.Screens.MealsDay`
        # joins a stored meal's slot and title with the same em dash, so the
        # shape is the one real data takes; what a msgid per half would buy is
        # five fragments — `miso salmon`, `yoghurt, walnuts` — short enough for
        # `mix gettext.merge` to fuzzy-match onto screen 43's longer dishes.
        title: gettext("Breakfast — overnight oats"),
        sub: calories(410),
        state: :past,
        check: :eaten
      },
      %{
        time: Kati.Locale.time(~T[08:00:00]),
        rule: @habit,
        title: gettext("Morning run"),
        # A context, because the catalogue already holds
        # `Habit · %{n}-day streak` for board 02's sub-line and the two differ
        # by a prefix `mix gettext.merge` would fuzzy-match straight across —
        # which would put `عادت ·` on a row the drawing gives no such word.
        sub: pgettext("a habit row's sub-line", "%{n}-day streak", n: Kati.Locale.number(12)),
        state: :past,
        check: :none
      },
      %{
        time: Kati.Locale.time(~T[10:30:00]),
        rule: @meal,
        title: gettext("Snack — yoghurt, walnuts"),
        sub: calories(180),
        state: :live,
        check: :todo
      },
      %{
        time: Kati.Locale.time(~T[11:00:00]),
        rule: @personal,
        # The msgid board 02 already carries for this appointment, so the one
        # clinic in the fixtures is spelled one way on both boards.
        title: gettext("Dentist — Marlow Clinic"),
        sub:
          gettext("%{from} – %{to}",
            from: Kati.Locale.time(~T[11:00:00]),
            to: Kati.Locale.time(~T[11:45:00])
          ),
        state: :live,
        check: :none
      },
      %{
        time: Kati.Locale.time(~T[13:00:00]),
        rule: @meal,
        title: gettext("Lunch — chicken, quinoa"),
        sub: calories(540),
        state: :live,
        check: :todo
      },
      %{
        time: Kati.Locale.time(~T[16:00:00]),
        rule: @meal,
        title: gettext("Snack — apple, almond butter"),
        sub: calories(210),
        state: :live,
        check: :todo
      },
      %{
        time: Kati.Locale.time(~T[19:30:00]),
        rule: @meal,
        title: gettext("Dinner — miso salmon"),
        sub: calories(620),
        state: :live,
        check: :todo
      },
      %{
        time: Kati.Locale.time(~T[20:00:00]),
        rule: @screen,
        # The series is `gettext("The Long Hollow")` — the msgid screens 19 and
        # 02 already carry — rather than a second Persian name for one show,
        # and the season and episode are the reader's own digits inside a msgid
        # that can reorder them: Persian writes فصل ۲ قسمت ۶, which `S2E6` has
        # no room for.
        title:
          gettext("%{title} S%{s}E%{e}",
            title: gettext("The Long Hollow"),
            s: Kati.Locale.number(2),
            e: Kati.Locale.number(6)
          ),
        # `Lumen+` is a service's name for itself and is never translated —
        # board 127's rule, and the reason no msgid reaches a real service
        # name off `Kati.Services.Service`.
        #
        # `Kati.Locale.ltr/1` because it sits on a Persian page. The `+` is a
        # NEUTRAL in the bidirectional algorithm and a neutral that is not
        # between two Latin characters takes the paragraph's direction rather
        # than the run's — so under `:fa` the plus jumps to the far side and
        # the row reads `+Lumen`, which is `Kati.Settings.DetectSample`'s own
        # finding on the same name. The isolate costs this one sub-line its DM
        # Mono, because `Kati.Locale.mono_face/1` asks whether the STRING is
        # ASCII and U+2066 is not; that is the right trade on this page, where
        # every other sub-line is already Persian and set in Vazirmatn.
        sub: Kati.Locale.ltr("Lumen+"),
        state: :live,
        check: :none
      }
    ]
  end

  @doc """
  The same five meals as one row.

  The mono line is upper-case in the drawing's own markup rather than by
  `text-transform`, and it goes through `Kati.UI.eyebrow_label/1` rather than
  being stored in capitals: upper case is a LATIN typographic effect, the
  Arabic script has no case at all, and a msgid written `1 EATEN · NEXT AT
  10:30` would freeze a shout into a language that cannot make one. English
  still draws the design's literal, character for character.

  Both halves are the msgids `Kati.Screens.MealsDay` composes this same row
  out of when it has meals to count, so the drawn summary and a computed one
  are one sentence in two places rather than two sentences.
  """
  @spec collapsed() :: map()
  def collapsed do
    %{
      rule: @meal,
      title:
        joined(
          ngettext("%{n} meal", "%{n} meals", 5, n: Kati.Locale.number(5)),
          # The grouping mark is the drawing's and stays: `Kati.Locale.number/1`
          # converts the digits and the decimal point and leaves a comma alone,
          # which is what board 59 draws as ۱,۴۸۰ and what screen 43's own
          # fixture asks for with the same string argument.
          gettext("%{count} kcal", count: Kati.Locale.number("1,960"))
        ),
      sub:
        Kati.UI.eyebrow_label(
          gettext("%{n} eaten · next at %{time}",
            n: Kati.Locale.number(1),
            time: Kati.Locale.time(~T[10:30:00])
          )
        )
    }
  end

  # The `·` is the separator in both scripts, so it is punctuation between two
  # translated halves rather than copy of its own — the reasoning
  # `Kati.Screens.MealsDay.joined/2` sets out at length, and the same two
  # halves it joins. Folding them into one msgid would multiply two plural
  # rules into a four-form entry.
  defp joined(left, right), do: left <> " · " <> right

  # The msgid both meal screens already carry for a calorie figure, so one word
  # names calories across 43, 44 and 52.
  defp calories(kcal), do: gettext("%{count} kcal", count: Kati.Locale.number(kcal))
end
