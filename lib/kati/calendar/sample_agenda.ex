defmodule Kati.Calendar.SampleAgenda do
  @moduledoc """
  Screen 30's agenda: the view that skips empty days entirely.

  The design's caption is the rule: *"date kickers only appear where something
  exists, and gaps are stated rather than scrolled through."* So the groups are
  not a week — they are TODAY, TOMORROW, a Thursday four days out and a date in
  September, with the silence between them named by the footer rather than
  drawn as empty rows.

  Each kicker carries two labels: a short name in ink and a longer mono
  subtitle in `#A0998F`. The subtitle is where the day's weight goes when it
  has any ("20 Aug · 14 items · 2 clashes"), which is how a heavy day
  announces itself before you reach it.

  Stand-in data until the Calendar domain lands, marked as such.

  ## The drawing in two scripts

  `Kati.Screens.Agenda`'s moduledoc named this module as the one place screen
  30's copy exists — *"this screen receives them already rendered and
  `gettext/1` cannot take a variable, so they can only be wrapped where they
  are written"* — so the fold for board 30 happens here rather than there. The
  screen's own half was done first and needed no second edit: the kicker, its
  subtitle and the row's time all go through `Kati.Locale.mono_face/1`, which
  asks the STRING's script rather than the reader's language, so those three
  mono slots move to Vazirmatn at the mono size on the day this file starts
  answering in Persian. That day is this one.

  Four kinds of string came out of the fold, and they are four different jobs:

    * **Copy** — a msgid, and the drawing's own line character for character.
      `Kati.ScreenDesignLiteralTest` renders board 30 under `:en` and compares
      what it finds, so `habit · 12-day streak` keeps its lower-case `h` even
      though the catalogue already holds board 02's capitalised twin.
    * **The four days** — `Date` structs rather than the words they print. A
      date stored as `"Sun 16 Aug"` is Gregorian for ever, and a Persian
      reader's 16 August 2026 is ۲۵ مرداد ۱۴۰۵ — a different CALENDAR rather
      than a translation of this one, which is the half of
      mishka-group/kati#103 gettext cannot do.
    * **Figures** — the clocks through `Kati.Locale.time/1`, the counts through
      `Kati.Locale.number/1`, and £8.99 through
      `Kati.Services.Service.format/2`, which leads with the symbol in Latin
      and trails it in Persian the way board 97 draws it.
    * **Names** — `Lumen+`, `Orbit` and `Kino` are services and are never
      translated. Board 127 draws `Lumen+` in Latin on a Persian page, and a
      real service name arrives off `Kati.Services.Service` where no msgid can
      reach it — so a fixture that transliterated would spell one thing two
      ways on the one screen that draws it three times.

  mishka-group/kati#103.
  """

  use Gettext, backend: Kati.Gettext

  @screen 0xFFE8823C
  @personal 0xFF1A1917
  @habit 0xFF4E9A73
  @money 0xFF8A8479

  # Board 30's four days, as dates rather than as the words they print. 2026 is
  # the year the boards are drawn in and the weekdays are what fix it: the 16th
  # of August is a Sunday there, the 20th is the Thursday the third group is
  # named after, and `Kati.Locale.date/2`'s own doctest reads
  # `date(~D[2026-08-16]) == "Sun 16 Aug"` — the same three parts, in the same
  # order, that the drawing prints under TODAY.
  @today ~D[2026-08-16]
  @tomorrow ~D[2026-08-17]
  @thursday ~D[2026-08-20]
  @in_september ~D[2026-09-04]

  # The day the footer counts the silence up to, and the only date here with no
  # group of its own — which is the point the footer is making.
  @next_after ~D[2026-09-12]

  @doc "The whole agenda, in the order the drawing lists it."
  @spec agenda() :: map()
  def agenda do
    %{
      groups: groups(),
      # `:short` is `12 Sep` in Latin and ۲۱ شهریور in Persian: the same day,
      # counted in the reader's own calendar. That conversion is the whole
      # reason the footer holds a `Date` rather than the sentence it prints.
      footer: gettext("Nothing else until %{date}", date: Kati.Locale.date(@next_after, :short))
    }
  end

  @doc "The date groups. A group with no rows would not be drawn at all."
  @spec groups() :: [map()]
  def groups do
    [
      %{
        # `Kati.UI.eyebrow_label/1` and not the capitals the drawing shows.
        # `String.upcase/1` is a Latin operation — the Arabic script has no
        # case at all — so a msgid written `TODAY` would buy a second entry for
        # a word the catalogue already names امروز, and upcase it to no effect.
        # The English is still `TODAY`, because that is what the helper does
        # under `:en`.
        kicker: Kati.UI.eyebrow_label(gettext("Today")),
        # `:long` is `%a %-d %b` in Latin, so the drawing's `Sun 16 Aug` is
        # unchanged. In Persian it is Shamsi and carries the year as well —
        # ۲۵ مرداد ۱۴۰۵ — which board 56 does not draw on a day heading. The
        # year is redundant rather than wrong, and the shape that abbreviates
        # without dating belongs in `Kati.Locale.date/2` beside the other five
        # rather than as a sixth spelling invented here for one kicker.
        sub: Kati.Locale.date(@today, :long),
        rows: [
          %{
            time: Kati.Locale.time(~T[20:00:00]),
            rule: @screen,
            seed: "hollow71",
            # A context, because `Kati.Screens.Search` draws this same episode
            # on board 19 as `%{title} S%{s}E%{e} airs` and the two msgids
            # differ by one word. `mix gettext.merge` would fuzzy-match across
            # that gap and hand this row `پخش می‌شود` — a row that says the
            # episode airs, on a board where the time column has already said
            # when. The Persian follows `Kati.Screens.Home`'s `%{title} —
            # S%{s}E%{e}` instead: a title slot, so the season and episode are
            # words rather than the ف۲ق۶ a 10.5pt meta line compresses them to.
            title:
              pgettext("an agenda row's title", "%{title} S%{s}E%{e}",
                title: gettext("The Long Hollow"),
                s: Kati.Locale.number(2),
                e: Kati.Locale.number(6)
              ),
            # A service, so it is never translated — and `Kati.Locale.ltr/1`
            # around it because the `+` is a NEUTRAL in the Unicode
            # bidirectional algorithm. On a right-to-left page it resolves
            # against the paragraph rather than against the word it belongs to
            # and is laid out at the left edge: `+Lumen`. The isolate is the
            # same fix screen 83's licence notices needed for their full stops.
            sub: Kati.Locale.ltr("Lumen+")
          },
          %{
            time: Kati.Locale.time(~T[21:30:00]),
            rule: @personal,
            seed: nil,
            title: gettext("Call Mum"),
            # Lower case, which is the drawing's. The catalogue's `Repeats
            # weekly` is board 01's, where the same fact heads a card instead
            # of trailing a row, and taking it here would change a string
            # `Kati.ScreenDesignLiteralTest` compares against board 30. The
            # Persian is the same sentence either way — هر هفته تکرار می‌شود —
            # so the two entries differ in English and agree in Persian, which
            # is the right way round.
            sub: gettext("repeats weekly")
          }
        ]
      },
      %{
        kicker: Kati.UI.eyebrow_label(gettext("Tomorrow")),
        sub: Kati.Locale.date(@tomorrow, :long),
        rows: [
          %{
            time: Kati.Locale.time(~T[08:00:00]),
            rule: @habit,
            seed: nil,
            title: gettext("Morning run"),
            # The middot is inside this msgid rather than between two halves
            # the way `joined/2` sets the Thursday's tally below, because both
            # halves here are one clause about one habit and neither is a
            # count with a plural rule of its own. The Persian is the catalogue's
            # own wording for board 02's capitalised twin — عادت · ۱۲ روز پیاپی
            # — so the two boards name a streak the same way.
            sub: gettext("habit · %{n}-day streak", n: Kati.Locale.number(12))
          },
          %{
            time: Kati.Locale.time(~T[18:00:00]),
            rule: @money,
            seed: nil,
            # The service is interpolated rather than written into the msgid.
            # The catalogue does hold `Lumen+ renews`, from screen 02, and its
            # Persian transliterates the name — which is the one thing this
            # board cannot do: it draws `Lumen+` twice more in Latin, on the
            # row above and on the Thursday, so a transliteration here would
            # spell one service two ways on one page. A real renewal reads its
            # name off `Kati.Services.Service`, where no msgid reaches it, and
            # this fixture now behaves the way that row will.
            title:
              pgettext("a renewal row, with the service named", "%{service} renews",
                service: Kati.Locale.ltr("Lumen+")
              ),
            # Board 97's ruling, written out rather than called: the symbol
            # leads in Latin and TRAILS in Persian, and the digits and the
            # decimal mark follow the reader's script.
            #
            # `Kati.Services.Service.format/2` is where that rule lives and is
            # what `Kati.Screens.Calendar`'s drawn money row calls — but it is
            # defined on an Ash resource, and `Kati.ScreenEmptyDatabaseTest`
            # derives *which screens read the database* as a transitive closure
            # over the compiled call graph. Calling it from here would put
            # screen 30 in `@migrated`, which obliges a gate of the form
            # `{what the screen reads, what the drawing is}` — and this screen
            # reads nothing, so the only pair available would compare a fixture
            # with itself and pass forever. That is worse than no entry,
            # because it reads as a guard. Moving the function does not help
            # either: `Kati.Money` is itself an `Ash.Domain`.
            #
            # So a fixture holds its own drawn value, which is what a fixture
            # is for. The day the rule needs to change in two places, the fix
            # is to lift it into a module that reaches no resource — not to
            # make a drawing pretend it queries.
            sub: Kati.Locale.pick("£8.99", Kati.Locale.number("8.99") <> " £")
          }
        ]
      },
      %{
        kicker: Kati.UI.eyebrow_label(weekday(@thursday)),
        # The heavy day, announcing itself. Both tallies are the catalogue's
        # existing entries — `Kati.Screens.Day` heads the same day with the
        # same two, and a day cannot be ۱۴ مورد one screen and something else
        # one tap in.
        sub:
          joined(
            joined(
              Kati.Locale.date(@thursday, :short),
              ngettext("%{n} item", "%{n} items", 14, n: Kati.Locale.number(14))
            ),
            ngettext("%{n} clash", "%{n} clashes", 2, n: Kati.Locale.number(2))
          ),
        rows: [
          %{
            time: Kati.Locale.time(~T[09:30:00]),
            rule: @screen,
            seed: nil,
            # One msgid for the whole line rather than three joined by an em
            # dash and a comma. The comma is the part that forces it: Persian
            # lists two things with و, not with `، `, so the separator is a
            # translator's decision rather than punctuation this file can hold
            # out of the catalogue the way `joined/2` holds the middot.
            title:
              gettext("%{n} at once — %{first}, %{second}",
                n: Kati.Locale.number(2),
                first: gettext("Standup"),
                second: gettext("Design review")
              ),
            # The same context `Kati.Screens.EventDetail` gives its capitalised
            # `Clash`, so a translator meets the two spellings of one word
            # together. Lower case here because board 30 draws it lower case,
            # and a context rather than a bare msgid because one word is
            # exactly the length `mix gettext.merge` fuzzy-matches onto
            # something longer that happens to end the same way.
            sub: pgettext("calendar clash", "clash")
          },
          %{
            time: Kati.Locale.time(~T[20:00:00]),
            rule: @screen,
            seed: "ashfall42",
            # The catalogue's own entry, from the lock screen's Up next widget.
            # A plain `gettext/1` and not `ngettext/4` on purpose: the drawing
            # says six and this is a transcription of the drawing, so a
            # singular form would be an entry no board reaches and a translator
            # would have to guess at.
            title: gettext("%{n} episodes air", n: Kati.Locale.number(6)),
            # Three services, so three names that are never translated — and
            # one `Kati.Locale.ltr/1` around the run rather than three around
            # the words, because it is the COMMAS that move: they are neutrals,
            # and on a right-to-left page they resolve against the paragraph
            # and land on the wrong side of the names they separate.
            sub: Kati.Locale.ltr("Lumen+, Orbit, Kino")
          }
        ]
      },
      %{
        # The month, not a weekday: the fourth group is far enough out that the
        # day of the week has stopped being how anybody finds it.
        # `Kati.Locale.month_name/2` takes a DATE rather than a month number,
        # which is the whole of it — 4 September 2026 is in Shahrivar, and no
        # arithmetic on the number 9 produces that.
        kicker: Kati.UI.eyebrow_label(Kati.Locale.month_name(@in_september, :short)),
        # `:short_padded` for the drawing's leading zero — `04 Sep`, so a
        # column of dates lines up. Persian numerals are already even-width, so
        # `Kati.Locale.date/2` hands `:fa` the unpadded `:short` and the column
        # lines up there for the other reason.
        sub: Kati.Locale.date(@in_september, :short_padded),
        rows: [
          %{
            # The one row on this board with no clock. An em dash rather than a
            # blank, because a cinema release has a date and no time, and
            # `Kati.Screens.Agenda.row/2` hands it to the reader's own face —
            # it is the only glyph in that column that is not ASCII.
            time: "—",
            rule: @screen,
            seed: "vellum97",
            title: gettext("%{title} in cinemas", title: gettext("Vellum")),
            sub: pgettext("an agenda row's sub-line", "wishlisted")
          }
        ]
      }
    ]
  end

  # A weekday NAMED, with no day of the month beside it — the one shape
  # `Kati.Locale` has no helper for, and `Kati.Screens.Meal.weekday/1` and
  # `Kati.Screens.QuickAdd` reach for the same two tables for the same reason:
  # `weekday_initial/1` is a chart axis's single letter, and `date/2`'s `:full`
  # carries the day and the month as well.
  #
  # Three letters in Latin, because the drawing's kicker is `THU`. Not in
  # Persian: slicing پنج‌شنبه to three graphemes gives پنج, which is the word
  # for five and not the name of a day. Board 56's own strip cuts a Persian
  # weekday to one letter or leaves it whole; there is no middle.
  defp weekday(date) do
    Kati.Locale.pick(
      String.slice(Kati.Time.day_name(date), 0, 3),
      Kati.Calendar.Shamsi.weekday_name(Kati.Calendar.Shamsi.weekday_index(date))
    )
  end

  # The `·` is the separator in both scripts — board 56 draws
  # `عادت · ۱۲ روز پیاپی` — so it is punctuation between two translated halves
  # rather than copy of its own, and `Kati.Screens.Day.joined/2` makes the same
  # call for the same line one tap in. Kept out of the msgids deliberately: one
  # sentence holding a date and two tallies would multiply two plural rules
  # into a four-form entry, and a msgid that is nothing but a middot between
  # two placeholders is exactly the tiny string `mix gettext.merge`
  # fuzzy-matches onto something else.
  defp joined(left, right), do: left <> " · " <> right
end
