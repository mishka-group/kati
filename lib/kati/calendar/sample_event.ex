defmodule Kati.Calendar.SampleEvent do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Screen 31's event: Design review, opened for editing.

  The design's caption names what this screen is for: *"Every field the
  quick-add parser can fill, editable by hand — plus the recurrence rule,
  timezone behaviour when you travel, invitee replies, and three one-tap ways
  to resolve the clash."* So the fields are not a generic form; each one exists
  because the parser can produce it and therefore can get it wrong.

  The clash card is the part that has to stay honest. It states the overlap in
  minutes and offers three resolutions, one of which is "Keep both" — an
  overlap the user chose is not an error, and the screen must let them say so.

  Stand-in data until the Calendar domain lands, marked as such.

  ## The words, since mishka-group/kati#103

  `Kati.Screens.EventDetail`'s moduledoc named this module as the one place
  screen 31's drawn copy exists — *"this screen receives them already rendered
  and `gettext/1` cannot take a variable"* — so the fold for board 31 happens
  here rather than there. Everything the page draws out of this file is a msgid
  now, and the date, the clock, the duration and every figure go through
  `Kati.Locale` as well, because a Gregorian date in Latin digits is not a thing
  a catalogue can translate.

  Where the catalogue already has a word, this file takes it rather than
  inventing a second one: `Timezone`, `Location`, `Repeats`, `follows travel`,
  `Keep both`, the clock range `%{from} – %{to}` and the three duration forms
  are all msgids some other screen drew first. A section called one thing on
  the calendar and another one tap into it is how a Persian page starts reading
  as a translation.

  ## Three strings stay English, and they are KEYS rather than copy

  `Kati.Screens.EventDetail.section_chip/2` builds its tap out of a section's
  name (`section_<label>`) and compares a tapped chip back against that same
  name; `field_tap/1` builds `switch_<title>` out of the timezone row's title,
  which is the one switch on the page. So `Personal`, `Work` and `Timezone` are
  each a control's name as well as its label, and translating them renames the
  control when the reader changes language — an atom made of Persian words is a
  name no device test can type, and `Kati.ScreenTapSweepTest`'s *no control is
  named after the word printed on it* is what fails the moment one appears.

  `Kati.Screens.Day.chip_label/1` carries the long version of the argument and
  the shape of the fix: the key travels English the whole way down and becomes
  a word at the last possible moment, which is the call site that draws it. Here
  that call site is in `Kati.Screens.EventDetail`, so the fix is a `:key` beside
  the label in these maps and a `chip_label/1` there — one change across two
  files rather than a wrap, which `field_tap/1`'s own doc already says is left
  for whoever makes it. Until then the three read Latin on a Persian page, which
  is the honest half-state rather than a control that answers to nothing.
  """

  @doc "The event the screen edits."
  @spec event() :: map()
  def event do
    %{
      title: gettext("Design review"),
      # KEYS, not copy — see the moduledoc. These two strings are
      # `Kati.Screens.EventDetail.section_chip/2`'s tap tag and the value its
      # `handle_info/2` compares a tapped chip against.
      sections: [{"Personal", false}, {"Work", true}],
      fields: fields(),
      clash: clash(),
      invitees: invitees()
    }
  end

  @doc """
  The detail rows. `trailing` says how each one is changed — a value, a switch,
  or a chevron into its own screen — because "1 hour before · at start" cannot
  be edited in place and "Timezone" does not need a screen at all.
  """
  @spec fields() :: [map()]
  def fields do
    [
      %{
        icon: "schedule",
        # Board 31's own Thursday, frozen as a `Date` rather than transcribed as
        # two words. `Kati.Locale.date/2`'s `:long` IS the `%a %-d %b` this was
        # written as, so the Latin page does not move — and under `:fa` it is
        # پنج‌شنبه ۲۹ مرداد ۱۴۰۵, the same day in the reader's own calendar and
        # not a formatting of the Gregorian one. `Kati.Library.Sample`'s
        # next-air line takes the same 20 August the same way.
        title: Kati.Locale.date(~D[2026-08-20], :long),
        # The catalogue's existing range msgid — the one
        # `Kati.Screens.EventDetail.clock_line/2` and `Kati.Screens.QuickAdd`
        # already draw — rather than a second one that would say the same thing.
        # The en dash needs no isolate around it: two runs of digits either side
        # of a neutral both resolve right-to-left, so the pair lays out in
        # READING order and the start time lands where the reader begins.
        sub:
          gettext("%{from} – %{to}",
            from: Kati.Locale.time(~T[09:30:00]),
            to: Kati.Locale.time(~T[10:30:00])
          ),
        # The catalogue's own duration form, which
        # `Kati.Screens.EventDetail.span/2`, `Kati.Screens.Library.runtime_line/1`
        # and `Kati.Screens.Stats` share: `1h` in Latin and `۱ ساعت` in Persian.
        # Two Latin letters glued to a number is legible enough to read as a
        # deliberate abbreviation rather than as untranslated copy, which is the
        # failure this whole fold keeps meeting.
        #
        # Nothing here has to think about the typeface: `trailing({:value, _})`
        # asks the STRING's script for its face, so the Latin form keeps the DM
        # Mono it is drawn in and the Persian one moves to Vazirmatn — which is
        # exactly the case that comment was written against.
        trailing: {:value, gettext("%{n}h", n: Kati.Locale.number(1))}
      },
      %{
        icon: "public",
        # A KEY as well as a label — see the moduledoc. This is the only switch
        # on the page, so `Kati.Screens.EventDetail.field_tap/1` names its tap
        # after this string.
        title: "Timezone",
        # `Kati.Screens.EventDetail.zone_field/1`'s line, said the same way so
        # the drawn event and a stored one cannot come out reading differently.
        # The zone is an IANA identifier and is never translated: it is the key
        # the store holds and the name every other calendar on the device uses
        # for the same zone. So under `:fa` it is a Latin run inside a Persian
        # line and takes `Kati.Locale.ltr/1` — the solidus inside it is a bidi
        # neutral and would otherwise resolve against the paragraph rather than
        # against the name, landing at the wrong end of it.
        #
        # The interpunct stays a literal rather than becoming a msgid of its
        # own, for that function's reason: every `·` line in this app writes the
        # separator identically in both scripts, and a strong Latin run and a
        # strong Persian run either side of a neutral are laid out in source
        # order by the bidi algorithm anyway.
        sub:
          Kati.Locale.ltr("Europe/London") <>
            " · " <> pgettext("timezone behaviour", "follows travel"),
        trailing: {:switch, true}
      },
      %{
        icon: "repeat",
        title: gettext("Repeats"),
        # The rule the quick-add parser produced, said as a sentence rather than
        # as `FREQ=WEEKLY;INTERVAL=2;BYDAY=TH`. Two things are not the same kind
        # of value and are handled apart:
        #
        #   * the interval is a NUMERAL INSIDE A SENTENCE, which is the case
        #     `Kati.Locale.number/1` is for — as against a figure the design
        #     sets in DM Mono, which keeps Latin digits.
        #   * the weekday is a WORD, and it is its own msgid because `gettext/1`
        #     cannot take a variable. It is not a date and does not go through
        #     `Kati.Locale.date/2`: Shamsi and Gregorian share the seven-day
        #     cycle, so Thursday is پنج‌شنبه in both calendars and there is no
        #     arithmetic to do.
        sub:
          gettext("Every %{n} weeks on %{day}",
            n: Kati.Locale.number(2),
            day: gettext("Thursday")
          ),
        trailing: :chevron
      },
      %{
        icon: "notifications",
        title: gettext("Alerts"),
        # `یادآور` is the word this app already uses for a notification it will
        # raise — `Kati.Screens.MealReminders` draws it — and a calendar alert
        # is that thing, so *Alerts* takes it rather than a second noun.
        #
        # Two alerts joined by the interpunct, split at it rather than held as
        # one msgid, for the reason the timezone row above gives.
        #
        # `ngettext/4` on the first even though the drawing freezes it at one.
        # Persian does not inflect a noun after a numeral, so its plural form is
        # the same words — but the English half is a real plural the moment the
        # alerts screen behind that chevron exists, and a msgid that has to
        # change shape later is a msgid that quietly acquires a second
        # translation. `pgettext/2` on the second: `at start` is two lowercase
        # words, which is the length `mix gettext.merge` fuzzy-matches against
        # any sentence that happens to end the same way.
        sub:
          ngettext("%{n} hour before", "%{n} hours before", 1, n: Kati.Locale.number(1)) <>
            " · " <> pgettext("event alert", "at start"),
        trailing: :chevron
      },
      %{
        icon: "place",
        title: gettext("Location"),
        # The drawing's own line, and it is COPY rather than a stored place: it
        # names the two kinds of thing this field takes. That is the line
        # `Kati.Screens.EventDetail.place_field/1` draws on the other side of —
        # a `location` a user typed is never translated, and this is a sentence
        # the board wrote.
        sub: gettext("Studio B, or a link"),
        trailing: :chevron
      }
    ]
  end

  @doc "The overlap, and the three ways out of it."
  @spec clash() :: map()
  def clash do
    # The abbreviated duration the two filled pills are drawn with, which is the
    # catalogue's `%{n}m` and not a second form invented here.
    fifteen = gettext("%{n}m", n: Kati.Locale.number(15))
    forty_five = gettext("%{n}m", n: Kati.Locale.number(45))

    %{
      # One msgid with two holes rather than a join, because
      # `Kati.Screens.EventDetail.clash/1` bolds this line whole and because
      # Persian puts the verb after both of them — ۱۵ دقیقه با جلسهٔ روزانه تداخل
      # دارد — and a screen that concatenates has already decided where the verb
      # goes. `Kati.Screens.Calendars.copy/1` carries the same argument for its
      # own two-hole line.
      #
      # The minutes take the catalogue's spelled-out `%{n} min` where the pills
      # take the abbreviated `%{n}m`, which is how the board writes the two.
      line:
        pgettext("calendar clash", "Overlaps %{event} by %{length}",
          event: gettext("Standup"),
          length: gettext("%{n} min", n: Kati.Locale.number(15))
        ),
      actions: [
        # `pgettext/2` on both resolutions: each is three words around a
        # placeholder, and the context also groups them with the card's own
        # `Clash` heading, which `Kati.Screens.EventDetail` already writes as
        # `pgettext("calendar clash", "Clash")`.
        {pgettext("calendar clash", "Shift %{length} later", length: fifteen), :primary},
        {pgettext("calendar clash", "Shorten to %{length}", length: forty_five), :primary},
        # The catalogue's own `Keep both` — `Kati.Screens.Sync` offers it over a
        # sync conflict, under board 37's *Keep mine / Take file / Keep both*
        # strip, and draws it against the same `call_split` glyph this card
        # heads its line with. Both mean *leave the pair as it is*, and a second
        # msgid here would let one screen say in different words what the other
        # says.
        {gettext("Keep both"), :quiet}
      ]
    }
  end

  @doc """
  The guest list. A reply is a state with its own glyph — accepted is a filled
  green check, silence is a grey clock — so "no reply yet" reads as pending
  rather than declined.

  `:state` is what `Kati.Screens.EventDetail.reply/1` switches on and `:sub` is
  only ever drawn, so the reply line is copy and translating it moves no
  behaviour. That is the difference between these rows and the section chips
  `event/0` leaves in English, and it is worth saying out loud: a label that is
  also a state is the one thing this fold cannot wrap.
  """
  @spec invitees() :: [map()]
  def invitees do
    [
      # A fixture's people are transliterated rather than left Latin. The rule
      # that keeps `TMDB` and `Lumen+` in Latin is about a name that comes off
      # `Kati.Services.Service` and can therefore be spelled two ways in one
      # app; nothing reaches this list but the drawing, so there is no second
      # spelling to disagree with. `Kati.Books.Sample` already transliterates
      # its own — `Ines Karvel` is اینس کارول and its `Jo` is جو — and this Jo
      # takes the same جو.
      %{
        name: gettext("Jo Mercer"),
        # `pgettext/2` on both replies: each is a short lowercase fragment, and
        # `accepted` alone is exactly the length `mix gettext.merge` fuzzy-matches
        # against any sentence that happens to end in the same word.
        sub: pgettext("invitee reply", "accepted"),
        seed: "face32",
        state: :accepted
      },
      %{
        name: gettext("Tomas Rhee"),
        sub: pgettext("invitee reply", "no reply yet"),
        seed: "face14",
        state: :waiting
      }
    ]
  end
end
