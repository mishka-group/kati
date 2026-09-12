defmodule Kati.Screens.QuickAdd.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  The one draft screen 18 is drawn mid-parse on, until a parser exists.

  `test/design/screens/18.html` does not draw an empty field. It draws
  *dentist thu 11am for 45m, remind 1h before* already typed, already
  understood, with a caret still blinking after the last token — so the screen
  can only be compared with its drawing if the sample carries the same
  half-finished sentence.

  ## Why the query is a list of pieces rather than a string

  The design highlights **inside** the sentence: `thu 11am`, `45m` and
  `1h before` sit on their own tinted grounds while the words between them do
  not. There is no inline-span primitive on this bridge, so the sentence is
  modelled the way it is drawn — a run of typed pieces, each knowing whether it
  is plain prose, a parsed token, or the accent-tinted reminder token, and how
  much space precedes it.

  Lines are declared rather than measured, for the same reason every other grid
  in this app is: nothing reports geometry back to `render/1`. The break falls
  where the browser puts it in the drawing — after `, remind`.

  ## What is frozen here and what is computed

  The values below are the drawing's own, held as a `Date`, a `Time` and two
  counts of minutes rather than as the strings it prints. Everything on the
  cream card is then composed from them the way
  `Kati.Screens.QuickAdd.facts/1` composes a real parse — so `11am for 45m`
  cannot stop agreeing with the `11:00 – 11:45` chip beside it, and a frozen
  `"Thu 20 Aug"` with no year in it cannot sit untranslatable on a Persian
  page. `Kati.Locale.date/2` answers the drawing's own `Thu 20 Aug` under
  `:en` and `پنج‌شنبه ۲۹ مرداد ۱۴۰۵` under `:fa`, which is a different
  CALENDAR and not a formatting of the Latin one.

  When the parser lands, delete this and hand `Kati.Screens.QuickAdd` the same
  shape: the screen reads pieces and facts and does not care who produced them.
  """

  # Board 18's day, hour, duration and reminder. Sigils and integers, so
  # nothing here is evaluated in a locale — the trap a `gettext/1` in a module
  # attribute falls into is that it freezes in whichever locale the COMPILER
  # was in, and every translated value in this file is therefore in a function.
  @day ~D[2026-08-20]
  @at ~T[11:00:00]
  @for_minutes 45
  @remind_minutes 60

  # Board 124's day: `Sun 16 Aug`, the day the book was bought.
  @spent_on ~D[2026-08-16]

  @doc """
  The draft as screen 18 draws it.

  `kind` is stored in capitals because the drawing types it in capitals —
  there is no `text-transform` on that line, so `PERSONAL EVENT` is the copy
  itself and not a styling of *Personal event*. The capitals are therefore in
  the MSGID, which is the same reading `Kati.Screens.QuickAdd.kind_line/1`
  gives it and the reason neither needs `Kati.UI.eyebrow_label/1`: Persian has
  no case, so the translation carries none and nothing has to be undone at the
  leaf. It is the same msgid that function answers with, so the board's card
  and a parsed one cannot spell one kind two ways.
  """
  @spec draft() :: map()
  def draft do
    %{
      query: query(),
      # `pgettext/2` on a one-word title: `mix gettext.merge` fuzzy-matches a
      # short msgid against any sentence resembling it, and `Dentist — Marlow
      # Clinic` is already in the catalogue for a bare `Dentist` to be caught
      # by. The context also keeps it apart from the lowercase `dentist` the
      # sentence above the card is typed with.
      title: pgettext("quick add sample card", "Dentist"),
      kind: gettext("PERSONAL EVENT"),
      facts: facts(),
      # The three pieces `Kati.Screens.QuickAdd.clash/1` bolds the middle of,
      # and the same three msgids `clash_for/1` builds a real one out of. The
      # middle piece is the event's own summary there and is never translated
      # — it is what the reader wrote on their own calendar — but this one is
      # the DRAWING's event, and `Kati.Calendar.SampleEvent` already draws the
      # same *Design review* through the same msgid on board 31.
      clash:
        {pgettext("quick add clash", "Clashes with"), gettext("Design review"),
         pgettext("quick add clash", "— add anyway?")},
      kinds: kinds(),
      # `Add to %{day}`, not a frozen `Add to Thursday`: it is the msgid
      # `Kati.Screens.QuickAdd.cta/2` fills from a parsed date, and the day is
      # named through that screen's own `weekday/1` rather than through a
      # second copy of the pick. `Calendar.strftime(date, "%A")` was the
      # English name in BOTH scripts, which is the defect that function exists
      # to hold — a Persian reader's commit button read `افزودن به Thursday`.
      cta: gettext("Add to %{day}", day: Kati.Screens.QuickAdd.weekday(@day))
    }
  end

  @doc """
  The typed sentence, one entry per drawn line.

  `caret` marks the line the cursor is still sitting on — the last one, which
  is what makes the screen read as mid-typing rather than as a result.

  ## Why this sentence is translated and the field's placeholder is not

  `Kati.Screens.QuickAdd.input/1` carries this same sentence as its
  placeholder and deliberately leaves it in Latin, isolated with
  `Kati.Locale.ltr/1`. A placeholder is an INSTRUCTION — *type this shape and
  Kati will read it* — and `Kati.QuickAdd.Parse` is four English regexes with
  no Persian table behind any of them, so a translated one would teach a
  Persian reader a syntax this app answers with nothing.

  These pieces are not that. Nothing is ever typed into them and the parser
  never sees them: they are a PICTURE of a parse that has already happened,
  drawn as one `Text` per piece inside that screen's `query_line/1` **`Row`**.
  `layout_direction` mirrors a Row, so a Latin run laid out one word per child
  comes out word-reversed under `:fa` — `, remind 45m for thu 11am dentist` —
  which is the failure that reads as a broken screen rather than as a foreign
  example. Persian is the only content that survives that Row, and it also
  puts each piece's leading `gap` and the trailing caret on the correct side
  without either being asked to.

  The day `Kati.QuickAdd.Parse` learns Persian the placeholder joins this, and
  the two land together.

  The numbers go through `Kati.Locale.number/1` rather than sitting inside the
  msgids, so `45m` is `۴۵ دقیقه` and not a Persian phrase with Latin digits in
  the middle of it. Every piece is `pgettext/2`: each is one or two words, and
  `, remind` is exactly the short msgid `mix gettext.merge` would fuzzy-match
  against any sentence that happens to resemble it.
  """
  @spec query() :: [map()]
  def query do
    hour = pgettext("quick add sample sentence", "thu %{n}am", n: Kati.Locale.number(@at.hour))
    duration = pgettext("quick add sample sentence", "%{n}m", n: Kati.Locale.number(@for_minutes))

    lead =
      pgettext("quick add sample sentence", "%{n}h before",
        n: Kati.Locale.number(div(@remind_minutes, 60))
      )

    [
      %{
        caret: false,
        pieces: [
          {:plain, pgettext("quick add sample sentence", "dentist"), 0},
          {:token, hour, 4},
          {:plain, pgettext("quick add sample sentence", "for"), 4},
          {:token, duration, 4},
          {:plain, pgettext("quick add sample sentence", ", remind"), 0}
        ]
      },
      %{caret: true, pieces: [{:accent, lead, 0}]}
    ]
  end

  @doc """
  What Kati understood, as chips.

  Chunked into the two rows the drawing's `flex-wrap` produces at 402pt, since
  there is no wrapping primitive to produce them from a flat list.

  The Persian day is the widest thing on this card — `Kati.Locale.date/2`'s
  `:long` carries its year in Shamsi and does not in Gregorian, because a
  reader knows this year by heart in one calendar and not in the other — and
  the chip's own `max_lines={1}` in `Kati.Screens.QuickAdd.fact/1` is what
  that rests on.
  """
  @spec facts() :: [[{String.t(), String.t()}]]
  def facts do
    ends = Time.add(@at, @for_minutes * 60)
    alert = Time.add(@at, -(@remind_minutes * 60))

    [
      [
        {"calendar_today", Kati.Locale.date(@day, :long)},
        # The range is one msgid and not a join, so a script that puts the two
        # hours the other way round can say so — and it is the msgid
        # `Kati.Screens.QuickAdd.hours/1`, `Kati.Screens.Calendar` and
        # `Kati.Screens.EventDetail` already compose a real range from, so the
        # four cannot come out writing one range four ways.
        {"schedule",
         gettext("%{from} – %{to}", from: Kati.Locale.time(@at), to: Kati.Locale.time(ends))}
      ],
      [
        {"notifications",
         pgettext("quick add alert chip", "%{at} alert", at: Kati.Locale.time(alert))},
        # `Kati.Screens.QuickAdd.personal_calendar/0` writes `Personal` into
        # the database in English on purpose — a name translated at the WRITE
        # freezes whichever language the reader was in that day — and names it
        # in Persian where it is READ. This chip is a read, so it takes the
        # same msgid `Kati.Screens.Calendars.copy/1` reads it through.
        {"label", gettext("Personal")}
      ]
    ]
  end

  @doc """
  The six things one field can become, the first one selected.

  This is the design's real claim — *one field for the whole app* — so the list
  is every section Kati keeps, not only the calendar ones.

  ## The six labels stay English, and they are not msgids

  On this row a label is STATE as well as copy:
  `Kati.Screens.QuickAdd.kind_tap/1` builds `:file_as_event` out of it,
  `filing/1` matches on it, and `expense_kinds/0` below compares against
  `"Expense"`. Translated at the source, a Persian reader tapping **Note**
  would send `:"file_as_یادداشت"`, `filing/1` would fall through to `nil`, and
  the chip would light while an event was filed anyway — the quiet failure,
  and one that also mints an atom per label per language.

  `Kati.Screens.QuickAdd.kind_label/1` is where the six are translated, once,
  at the one place they are read, and its doc carries the argument in full.
  """
  @spec kinds() :: [{String.t(), String.t(), boolean()}]
  def kinds do
    [
      {"event", "Event", true},
      {"check_circle", "Reminder", false},
      {"movie", "Title", false},
      {"bolt", "Habit", false},
      {"edit_note", "Note", false},
      {"payments", "Expense", false}
    ]
  end

  @doc """
  Screen 124's draft: the same field, with the Expense chip selected and no
  amount parsed.

  A separate draft rather than a flag on `draft/0`, because it is a different
  sentence — *bought the salt almanac at the bookshop today* — parsed into a
  different set of facts. One field, two things it became, which is the whole
  claim screen 18 makes.
  """
  @spec expense_draft() :: map()
  def expense_draft do
    %{
      query: expense_query(),
      # The same msgid `Kati.Books.Sample` draws the book through on boards 20,
      # 66 and 72 — **سالنامه نمک** — so one book is not spelled two ways in
      # one app. `Kati.Screens.QuickAddExpense.parsed/1` already runs this Text
      # through `Kati.Locale.tracking/1` for it, because a fiftieth of an em
      # pulls the Persian apart at its joins.
      title: gettext("The Salt Almanac"),
      # Capitals in the msgid, for the reason `draft/0` gives for
      # `PERSONAL EVENT`: the drawing types them and there is no
      # `text-transform` on that line. `Kati.Screens.QuickAddExpense` asks
      # `Kati.Locale.mono_face/1` about this string rather than about the
      # reader, so `EXPENSE · BOOKS` keeps DM Mono and `هزینه · کتاب` — which
      # `kati_mono.ttf` has no glyph for — takes Vazirmatn.
      kind: gettext("EXPENSE · BOOKS"),
      kind_icon: "payments",
      facts: [
        [
          {"calendar_today", Kati.Locale.date(@spent_on, :long)},
          # `pgettext/2` and not the bare `Books` msgid. That one is the
          # library SECTION and is **کتاب‌ها**; this is a spending category and
          # is **کتاب**, which is what `Kati.Money.Sample` already writes and
          # what the kind line directly above this chip says. One card
          # spelling one category two ways is how a catalogue starts
          # disagreeing with itself.
          {"menu_book", pgettext("expense category", "Books")}
        ]
      ],
      amount: nil,
      # Screen 124's own context, the one `AMOUNT` above the field already
      # uses: three lowercase words are short enough for `mix gettext.merge` to
      # fuzzy-match against any sentence ending the same way.
      amount_placeholder: pgettext("quick add expense", "no amount found"),
      clash: nil,
      kinds: expense_kinds(),
      # Its own msgid rather than a shared `Save`. Board 262's caption is
      # explicit that each commit label names what is about to exist, and that
      # a shared word would lose the one thing these labels do.
      cta: gettext("Save the expense")
    }
  end

  @doc """
  The typed sentence on screen 124, one entry per drawn line.

  Translated for the reason `query/0` gives at length, and in the drawing's own
  piece order so the mirrored `Row` reads as a Persian sentence rather than as
  a reversed English one: *«خرید سالنامه نمک از کتاب‌فروشی / امروز»*. The
  tinted token is the same book the card above it names, so it takes the same
  Persian as `expense_draft/0`'s title and differs only in the case the
  sentence is typed in.
  """
  @spec expense_query() :: [map()]
  def expense_query do
    [
      %{
        caret: false,
        pieces: [
          {:plain, pgettext("quick add sample sentence", "bought"), 0},
          {:token, pgettext("quick add sample sentence", "the salt almanac"), 4},
          {:plain, pgettext("quick add sample sentence", "at the bookshop"), 4}
        ]
      },
      %{caret: true, pieces: [{:accent, pgettext("quick add sample sentence", "today"), 0}]}
    ]
  end

  @doc """
  The same six chips, with Expense selected instead of Event.

  The match is against the ENGLISH label, because that is what a label is on
  this row — see `kinds/0`. It is the third reader of that identity after
  `Kati.Screens.QuickAdd.kind_tap/1` and `filing/1`, and the one that would
  fail most quietly if the six were ever translated at the source: no chip
  would be lit at all.
  """
  @spec expense_kinds() :: [{String.t(), String.t(), boolean()}]
  def expense_kinds do
    Enum.map(kinds(), fn {icon, label, _on?} -> {icon, label, label == "Expense"} end)
  end
end
