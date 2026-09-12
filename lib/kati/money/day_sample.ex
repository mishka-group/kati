defmodule Kati.Money.DaySample do
  @moduledoc """
  Screen 126, as the drawing captured it.

  ## A renewal and an expense are different kinds of thing

  The board says it in one line and the whole screen follows from it: *a
  renewal is a commitment — solid card, a time, an amount you will owe. An
  expense is a fact — outlined card, no time slot, an amount already spent.*

  Both belong on the day. One tells you what is coming and the other what
  happened, and the difference is drawn rather than coloured: the same palette,
  a filled card against an outlined one. Inventing a colour for *past* would
  have meant a fifth lane hue on a screen that already has four.

  ## The drawing in two scripts

  mishka-group/kati#103 folded the Persian mirrors away, so these four rows are
  rendered under `:fa` as well as `:en` and every string here had to become one
  of three things: a msgid, a figure in the reader's own script, or a name that
  is never translated. `Kati.Screens.MoneyDay` was already doing all three for
  a **stored** day — `Kati.Locale.date/2` on its heading, `ngettext/4` on its
  tally, `gettext/1` on an expense's meta line — and a drawn day that kept its
  Latin was the one page on that screen where the two branches disagreed about
  what language the reader had chosen. `Kati.Calendar.SampleMealDay` is the
  same fixture one section over and went the same way.

  The English pixels do not move. Every msgid is the drawing's own line
  character for character, the clocks print `%H:%M` in both scripts, and the
  amounts come back out of `Kati.Money.display/1` as the `£89.00` they were
  frozen as.

  **The services keep their names.** `Kino`, `Lumen+`, `Orbit` and
  `Aria Audio` are what they call themselves in both scripts — board 127's
  rule, and the deeper reason is that a real renewal's name comes off
  `Kati.Services.Service` with no catalogue anywhere near it, so a fixture that
  transliterated would spell one provider two ways depending on whether the row
  was stored or drawn. So a renewal's title is a msgid with a name interpolated
  INTO it rather than a msgid that contains one.
  """

  use Gettext, backend: Kati.Gettext

  # Board 126's day as a DATE rather than as the three words it prints.
  #
  # `"Mon 24 Aug"` was stored as a string, and a string is Gregorian for ever:
  # a Persian reader's 24 August 2026 is ۲ شهریور ۱۴۰۵, which is a different
  # CALENDAR rather than a translation of this one — the half of
  # mishka-group/kati#103 gettext cannot do. `Kati.Locale.date/2`'s `:long` is
  # the same three parts the drawing prints (`%a %-d %b` in Latin), so the
  # English heading is `Mon 24 Aug` character for character, and it is the call
  # `Kati.Screens.MoneyDay.title/1` already makes for every day that is not
  # this one.
  #
  # 2026 because that is the year the boards are drawn in, and the weekday is
  # what fixes it: 24 August is a Monday there and in neither 2024 nor 2025.
  # `Kati.Calendar.SampleMealDay` heads board 52 with the Monday a week before
  # it, and 24 August is the day `Kati.Money.Sample` has Orbit renewing on —
  # which is one of the three renewals this day merges.
  @on ~D[2026-08-24]

  @doc "The day's header line and its mono subtitle."
  @spec day() :: map()
  def day do
    %{
      title: Kati.Locale.date(@on, :long),
      # The drawing's own counts, not `rows/0`'s. Board 126 heads the day
      # `3 RENEWALS · 5 OTHER ITEMS` and chips it `3 · 2 · 3` — eight items —
      # while the spine underneath transcribes four of them, one per case the
      # board is making. The drawing is the specification and this module is
      # its transcription, so deriving these would print `3 renewals · 1 other
      # item` and disagree with the frame it exists to reproduce.
      #
      # Both msgids are `Kati.Screens.MoneyDay.subtitle/2`'s own — the two
      # halves it counts a STORED day with — so the drawn line and a computed
      # one are one sentence in two places rather than two sentences.
      #
      # `Kati.UI.eyebrow_label/1` rather than capitals frozen into the msgid:
      # upper case is a LATIN typographic effect, the Arabic script has no case
      # at all, and a msgid written `3 RENEWALS · 5 OTHER ITEMS` would freeze a
      # shout into a language that cannot make one. English still draws the
      # design's literal, character for character.
      subtitle:
        Kati.UI.eyebrow_label(
          joined(
            ngettext("%{n} renewal", "%{n} renewals", 3, n: Kati.Locale.number(3)),
            ngettext("%{n} other item", "%{n} other items", 5, n: Kati.Locale.number(5))
          )
        )
    }
  end

  @doc """
  The filter chips, with the counts the drawing prints.

  **The label is a key and stays English in every locale.**
  `Kati.Screens.MoneyDay.shows?/2` matches the active filter against the
  literals `"All"` and `"Money"`, and `chips/1` builds `filter_<label>` into
  the tap tag `handle_tap/2` splits back apart — so a Persian label here would
  empty the spine on every chip but `All` and name an atom no clause can read.
  `Kati.Screens.MoneyDay.chip_label/1` is where the word becomes Persian, at
  the last moment before it is drawn, and its own doc carries the long version
  of this argument.

  The COUNT is the reader's, which is what `Kati.Calendar.SampleMealDay.chips/0`
  already does one section over: a chip reading `Money ۳` beside one reading
  `Screen 2` would be one row of counts in two numeral systems.
  """
  @spec chips() :: [{String.t(), String.t() | nil}]
  def chips,
    do: [
      {"All", nil},
      {"Money", Kati.Locale.number(3)},
      {"Screen", Kati.Locale.number(2)},
      {"Personal", Kati.Locale.number(3)}
    ]

  @doc """
  The rows, in the order the spine draws them.

  Four kinds: an all-day renewal with no set time, a merged group of three, a
  single renewal, and a past expense. Each is the drawing's own.

  Clock times are `Kati.Locale.time/1`'s rather than the strings they were,
  which is the call `Kati.Calendar.SampleMealDay.rows/0` makes for the spine
  one section over: the clock is 24-hour in both scripts and what changes is
  the numerals, so a gutter reading ۱۸:۰۰ against one reading 09:00 would be
  one column in two numeral systems. The FACE follows the string rather than
  the reader — `Kati.Screens.MoneyDay.time_column/1` asks
  `Kati.Locale.mono_face/1`, so an ASCII clock keeps DM Mono and a Persian one
  takes the face that can draw it, `kati_mono.ttf` carrying none of
  U+06F0–U+06F9.

  Amounts are `Kati.Money.display/1`'s, and the minor units rather than a
  formatted string are what they are stored as here for two reasons. Board 127
  writes a price as `۸٫۹۹ پوند` — Persian numerals and the currency as a WORD,
  which is Kati's own copy rather than CLDR's symbol — and it cannot be got to
  from `"£8.99"` without parsing the English apart, which is
  mishka-group/kati#103's recurring defect. And the figures are screen 92's
  prices: `Kati.Money.Sample` draws the same four services on 122 at the same
  pence, so passing the pence is what keeps the two fixtures agreeing.
  """
  @spec rows() :: [map()]
  def rows do
    [
      %{
        kind: :renewal,
        # Never read as things stand — `Kati.Screens.MoneyDay.time_column/1`
        # draws the all-day gutter from `all_day?` and its own two msgids, and
        # matches that clause before it reaches `:time`. It is the reader's
        # anyway rather than the frozen `ALL DAY` it was, so the next reader of
        # this row cannot inherit a Latin string nobody would think to check.
        # `All day` is the msgid `Kati.Screens.MoneyDay.label/1` and
        # `Kati.Screens.EventDetail` already carry, and `Kati.UI.eyebrow_label/1`
        # keeps the capitals the drawing sets.
        time: Kati.UI.eyebrow_label(gettext("All day")),
        all_day?: true,
        title: renewal_title(:annual, "Kino"),
        meta:
          Kati.UI.eyebrow_label(
            joined(
              pgettext("an all-day renewal's meta line", "No set time"),
              Kati.Money.display(8900)
            )
          ),
        amount: nil
      },
      %{
        kind: :merged,
        time: Kati.Locale.time(~T[18:00:00]),
        all_day?: false,
        # The msgid `Kati.Screens.MoneyDay.subtitle/2` counts renewals with, so
        # the merged card and the line above it name the same three rows with
        # the same word. Persian does not inflect a noun after a numeral, so
        # the catalogue's two forms are one word — which is the catalogue's
        # answer to give rather than one this module assumes.
        # A stable name for the control, because the title beside it is a msgid
        # and `Kati.Screens.MoneyDay.expand_tag/1` is what reads this.
        key: :renewals,
        title: ngettext("%{n} renewal", "%{n} renewals", 3, n: Kati.Locale.number(3)),
        # Three provider names and no copy at all, so there is no msgid here to
        # write: a service is called what it calls itself in both scripts.
        # `Kati.Screens.MoneyDay.meta/1` asks `Kati.Locale.mono_face/1` whether
        # the STRING is ASCII — this one is, so it keeps DM Mono on a Persian
        # page, which is what board 127 draws. `Kati.Locale.ltr/1` would be the
        # wrong tool for the same reason it is wrong on screen 80's provider
        # list: U+2066 is not ASCII, so the isolate would cost this line its
        # mono face to fix a bidi problem it has not got — every neutral in it
        # sits between two Latin letters.
        meta: "LUMEN+, ORBIT, ARIA",
        # The drawing's total, and it is the three members added up: 899 +
        # 1399 + 500. Left as the figure the board prints rather than summed
        # here, because this module transcribes a frame and a derived total
        # that disagreed with it would be the drawing losing an argument to
        # arithmetic silently.
        amount: Kati.Money.display(2798),
        members: [
          %{badge: "L", name: "Lumen+", amount: Kati.Money.display(899)},
          %{badge: "O", name: "Orbit", amount: Kati.Money.display(1399)},
          %{badge: "A", name: "Aria Audio", amount: Kati.Money.display(500)}
        ]
      },
      %{
        kind: :renewal,
        time: Kati.Locale.time(~T[09:00:00]),
        all_day?: false,
        title: renewal_title(:monthly, "Kino"),
        meta: nil,
        amount: Kati.Money.display(1149)
      },
      %{
        kind: :expense,
        # The em dash is the absent time slot itself rather than a word for one
        # — `Kati.Screens.MoneyDay.shape/1` draws the same one for a stored
        # expense — and a dash is punctuation in both scripts.
        time: "—",
        all_day?: false,
        # `The Salt Almanac` is the msgid `Kati.Books.Sample` already carries,
        # and screen 122 buys the same book for the same £9.99; one book in the
        # fixtures is named one way in Persian or the app has two books. The
        # title is interpolated rather than written into the sentence for the
        # reason a service's name is, and one more: what stands here for a real
        # day is `Kati.Money.Expense`'s `description`, typed by the reader on
        # screen 122, and no catalogue reaches that at all.
        title:
          pgettext("an expense row on board 126's spine", "Bought %{title}",
            title: gettext("The Salt Almanac")
          ),
        # The msgid `Kati.Screens.MoneyDay.shape/1` gives a STORED expense, so
        # the drawn fact and a real one say the same sentence. Upper case is
        # `Kati.UI.eyebrow_label/1`'s here as it is there: English is
        # `RECORDED, NOT SCHEDULED` to the pixel and Persian is a sentence
        # rather than an upcasing that changes nothing.
        meta: Kati.UI.eyebrow_label(gettext("Recorded, not scheduled")),
        amount: Kati.Money.display(999)
      }
    ]
  end

  @doc """
  The sentence that says why money merges at three.

  Screen 09 merges at two and is the exception; meals on 52 and episodes merge
  at three. The board moves money to three so the app has one density rule
  rather than two, and says which one lost.

  The board numbers are interpolated through `Kati.Locale.number/1` rather than
  written into the msgid, for `Kati.Screens.RateAlbum.omissions_body/0`'s
  reason: a figure a translator has to retype in order to convert it is a
  figure that can come back wrong. `%{board}` appears twice because the same
  board is named twice, which is the sentence's own point.
  """
  @spec merge_note() :: String.t()
  def merge_note do
    gettext(
      "%{board} merges at two; money merges at three, matching meals on %{meals} " <>
        "and episodes on %{board}. Two renewals stay two rows.",
      board: Kati.Locale.number("09"),
      meals: Kati.Locale.number(52)
    )
  end

  @doc """
  The sentence that distinguishes a commitment from a fact.

  One msgid rather than the six clauses it is made of. The two halves are a
  pair of parallel definitions and Persian does not lay them out in English's
  order, so fragments could only ever be reassembled as English — the trade
  `Kati.Screens.RateAlbum.omissions_body/0` makes at length for the same shape
  of paragraph.
  """
  @spec kinds_note() :: String.t()
  def kinds_note do
    gettext(
      "A renewal is a commitment: solid card, a time, an amount you will owe. " <>
        "An expense is a fact: outlined card, no time slot, an amount already " <>
        "spent. Both belong on the day — one tells you what is coming, the " <>
        "other what happened."
    )
  end

  @doc "How many items on one day collapse into a summary row."
  @spec merge_threshold() :: pos_integer()
  def merge_threshold, do: 3

  # A renewal's title: the catalogue's sentence with the service's own name
  # dropped into it.
  #
  # The name is NOT part of the msgid — board 127's rule, and the moduledoc has
  # the long version. `Kati.Money.Sample.suggestion/0` interpolates a service
  # the same way.
  #
  # Both take a CONTEXT, and the second one is why: `%{service} renews` is one
  # word behind a placeholder, which is precisely the string
  # `mix gettext.merge` fuzzy-matches onto a neighbour — and the neighbour is
  # already in the catalogue, `Lumen+ renews` off screen 02, whose Persian
  # names a different service. A renewal that silently became another
  # provider's would read as a perfectly plausible row.
  #
  # `Kati.Locale.ltr/1` because the name lands inside a Persian sentence:
  # `Kino` has no neutral of its own to lose, but the three services this very
  # page merges include `Lumen+`, whose `+` is the neutral
  # `Kati.Calendar.SampleMealDay` watched jump to the far side of a line and
  # render as `+Lumen`. A title is not a mono slot —
  # `Kati.Screens.MoneyDay.commitment/1` draws it in the reader's own face — so
  # the isolate costs nothing here, which is the trade that fixture has to
  # weigh the other way for a sub-line set in DM Mono.
  defp renewal_title(:annual, service) do
    pgettext("a renewal row on board 126's spine", "%{service} annual renews",
      service: Kati.Locale.ltr(service)
    )
  end

  defp renewal_title(:monthly, service) do
    pgettext("a renewal row on board 126's spine", "%{service} renews",
      service: Kati.Locale.ltr(service)
    )
  end

  # The `·` is the separator in both scripts, so it is punctuation between two
  # translated halves rather than copy of its own — the shape
  # `Kati.Calendar.SampleMealDay.joined/2` uses for the same two-part lines.
  # Folding the subtitle's halves into one msgid would multiply two plural
  # rules into a single four-form entry, and a two-placeholder msgid that is
  # nothing but a middot is exactly the tiny string `mix gettext.merge`
  # fuzzy-matches onto something else.
  defp joined(left, right), do: left <> " · " <> right
end
