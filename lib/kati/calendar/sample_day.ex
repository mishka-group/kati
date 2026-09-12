defmodule Kati.Calendar.SampleDay do
  @moduledoc """
  Screen 09's reference day: *"14 items, 2 clashes"*.

  The design calls this "A heavy day · density rules", and it is drawn to
  exercise every rule at once — sequential cards, a two-lane clash, a
  three-way clash capped at two lanes with a `+1 MORE`, three same-kind items
  collapsing into one grouped card, an all-day band, and two money renewals
  merged into a single row.

  So the data is not decoration: each row is here to make one rule visible. A
  day of ordinary meetings would render the same screen with none of them
  showing.

  ## The drawing in two scripts

  mishka-group/kati#103 folded the Persian mirrors away, so `Kati.Screens.Day`
  draws this fixture under `:fa` as well as `:en`. That screen was already
  doing the work for a **stored** day — `ngettext` on its tally,
  `Kati.Locale.number/1` on its chip counts, `label_for/1` on every clock in
  the gutter — and the drawn day was the one branch on it where a Persian
  reader still met Latin: `14 items · 2 clashes` under a Persian heading, and
  `09:30–09:45` on a card beside a gutter reading ۰۹:۳۰.

  Every string here is now one of three things: a msgid, a figure in the
  reader's own digits, or a name that is never translated. **The English pixels
  do not move** — every msgid is the drawing's own line character for
  character, the clocks print `%H:%M` in both scripts, and `£22.98` is the same
  eight characters `Kati.Services.Service.format/2` has always produced for
  2298 pence in GBP.

  The names that stay Latin, and why each one does:

    * **`Lumen+`** — a service's name for itself, drawn in Latin on a Persian
      page. Board 127's rule, and the reason no msgid ever reaches a real
      service name off `Kati.Services.Service`. It takes `Kati.Locale.ltr/1`
      here because the `+` is a bidi NEUTRAL, and a neutral that is not between
      two Latin characters takes the paragraph's direction rather than the
      run's — under `:fa` the plus jumps to the far side and the row reads
      `+Lumen`, which is `Kati.Settings.DetectSample`'s own finding on this
      same name.
    * **`Screen`, `Personal`, `Money`** — keys rather than copy. `chips/0` says
      the whole of it.
    * **`vellum97` and the other seeds** — `Kati.Library.Sample` asset keys,
      which are file names by another name.

  ## What `Kati.Seeds` reads out of here, and the trap in it

  The seeder writes `occ.title` into an event's `summary`, and then routes that
  event onto a calendar by matching **the same title** against its own
  `@work_events` list — `["Standup", "Design review"]`, in Latin. Those two
  titles are msgids now, so a database seeded while the reader is on `:fa` puts
  both meetings on `Personal` instead of `Work`. Nothing on this screen shows
  it; it surfaces one screen away, on `Kati.Screens.Calendars`.

  The fix belongs in `Kati.Seeds`, which should route on `occ.id` or on a field
  this module states outright, rather than on a string that is now allowed to
  change language. It is named here because this file is where the reason
  lives, and a translation is a strange place to go looking for a seeding bug.
  """

  use Gettext, backend: Kati.Gettext

  @doc "All-day items, drawn in the band above the gutter."
  @spec all_day() :: [map()]
  def all_day do
    [
      %{
        # The film is `gettext("Vellum")` — the msgid screens 19 and 30 already
        # carry — rather than a second Persian name for one film, wrapped in a
        # sentence of its own because the em dash and the phrase after it are
        # copy. `Kati.Calendar.SampleAgenda` draws the same release as
        # `%{title} in cinemas`; this board's dash is the drawing's, so the two
        # msgids differ by it and the Persian says the same thing.
        title: gettext("%{title} — in cinemas", title: gettext("Vellum")),
        # Two labels with a middot between them, not one sentence. The `·` is
        # punctuation separating two words in both scripts — `joined/2` below
        # carries the argument — and each half is its own msgid so a translator
        # is never handed a middot to place.
        #
        # A CONTEXT on both, because `release` and `wishlisted` are single
        # words and `mix gettext.merge` fuzzy-matches a string that short onto
        # any longer sentence that happens to contain it: the catalogue already
        # holds `Release date`, `Release watcher` and `Wishlisted films
        # reaching cinemas or streaming`.
        meta:
          joined(
            pgettext("an all-day band row's meta", "release"),
            pgettext("an all-day band row's meta", "wishlisted")
          ),
        seed: "vellum97"
      }
    ]
  end

  @doc """
  Timed occurrences, in `Kati.Calendar.Layout` shape.

  Clock times are the drawing's, not approximations of it: 08:00, a two-way
  clash at 09:30, a three-way one at 13:00, a todo at 15:00, the renewals at
  18:00 (see `money/0`), three episodes collapsing at 20:00 and a leaving
  notice at 23:15.

  Two fields exist only because the drawing draws them:

    * `:rail` overrides the kind colour on Design review, which the drawing
      alone among the meetings paints orange.
    * `:flat` sinks the 23:15 row onto `#F4F1EC` the way a done or todo row
      sinks. It is a notice rather than an appointment — nothing to do, and
      nothing to tick — so it sits with the settled rows.

  The counts add up to the header's own `14 items · 2 clashes`, and to the
  chips' `6 + 6 + 2`: the third 13:00 item — the one the `+1` tile hides — is
  a Screen item, which is the only split of these rows that reaches 6/6/2.
  """
  @spec occurrences() :: [map()]
  def occurrences do
    [
      # 08:00 — a habit, already ticked. One line: the tick says the rest.
      %{
        id: 1,
        start_min: 480,
        end_min: 510,
        kind: :habit,
        title: gettext("Morning run"),
        done: true
      },
      # 09:30 — two at once.
      %{
        id: 2,
        start_min: 570,
        end_min: 585,
        kind: :event,
        title: gettext("Standup"),
        meta: clock_range(570, 585)
      },
      %{
        id: 3,
        start_min: 570,
        end_min: 630,
        kind: :event,
        title: gettext("Design review"),
        meta: clock_range(570, 630),
        rail: 0xFFE8823C
      },
      # 13:00 — three at once, capped at two lanes with a +1 tile.
      %{
        id: 4,
        start_min: 780,
        end_min: 840,
        kind: :event,
        # Slot and person in one msgid, the way `Kati.Calendar.SampleMealDay`
        # carries `Lunch — chicken, quinoa` and `Dentist — Marlow Clinic`
        # whole. `Jo` is the fixtures' one Jo and the catalogue already spells
        # her جو; the Persian here spells her the same.
        title: gettext("Lunch — Jo"),
        meta: clock_range(780, 840)
      },
      %{
        id: 5,
        start_min: 780,
        end_min: 900,
        kind: :event,
        title: gettext("Plumber"),
        meta: clock_range(780, 900)
      },
      %{
        id: 6,
        start_min: 780,
        end_min: 810,
        kind: :air_date,
        title: gettext("Marram"),
        meta: episode(2, 3)
      },
      # 15:00 — a todo, and the only thing on the day that can be ticked.
      %{
        id: 7,
        start_min: 900,
        end_min: 930,
        kind: :todo,
        title: gettext("Renew passport"),
        todo: true
      },
      # 20:00 — three episodes, which Layout folds into one grouped card.
      %{
        id: 8,
        start_min: 1200,
        end_min: 1230,
        kind: :air_date,
        title: gettext("Ashfall"),
        meta: episode(3, 2),
        seed: "ashfall42"
      },
      %{
        id: 9,
        start_min: 1205,
        end_min: 1235,
        kind: :air_date,
        title: gettext("Salt & Iron"),
        meta: episode(1, 4),
        seed: "saltiron33"
      },
      %{
        id: 10,
        start_min: 1210,
        end_min: 1240,
        kind: :air_date,
        title: gettext("The Cartographer"),
        meta: episode(2, 1),
        seed: "cartog60"
      },
      # 23:15 — a deadline you did not set. Flat paper, and a poster instead
      # of a kind rail.
      %{
        id: 11,
        start_min: 1395,
        end_min: 1410,
        kind: :air_date,
        title: gettext("Blue Hour"),
        # The service is interpolated rather than written into the msgid, so
        # `Lumen+` cannot be translated by accident — and `Kati.Locale.ltr/1`
        # keeps its plus on the right end of it inside a Persian sentence. The
        # isolate costs this line its DM Mono under `:fa`, because
        # `Kati.Locale.mono_face/1` asks whether the STRING is ASCII and U+2066
        # is not; that is the right trade on a line whose other five words are
        # Persian anyway.
        meta: gettext("leaves %{service} at midnight", service: Kati.Locale.ltr("Lumen+")),
        seed: "bluehour58",
        flat: true
      }
    ]
  end

  @doc """
  Money renewals, merged into one row — the design's `2 renewals`, at 18:00.

  `:at` and `:label` are the design's own two labels for this row, and
  `Kati.Screens.Day.money_row/0` draws **neither** of them: it prints
  `label_for/1` over its own `@money_min` and `kind_label(:money, count)`,
  because the clock and the phrase were each the same fact written twice and
  only the screen's copy could be put into the reader's digits. They are kept
  and built the same way here rather than left as frozen Latin, so a caller
  that ever does read them gets the same two strings the screen draws.

  `:total` is the one figure on this row the app cannot reach — no table holds
  a price, which is the third bullet of `Kati.Screens.Day`'s moduledoc — so it
  is stated here. It goes through `Kati.Services.Service.format/2` rather than
  standing as the literal `"£22.98"`: that function is where the app decides
  the symbol leads in Latin and trails in Persian (board 97's `۲۲٫۹۸ £`), and
  `money_row/0` already hands the answer to `Kati.Locale.mono_face/1`, which
  moves the Persian figure to Vazirmatn because `kati_mono.ttf` carries none of
  U+06F0–U+06F9. English is unchanged: 2298 pence in GBP is `£22.98`.
  """
  @spec money() :: map()
  def money do
    count = 2

    %{
      count: count,
      at: clock(18 * 60),
      # `Kati.Screens.Day`'s own msgid for a collapsed money row, so the merged
      # renewals row and every grouped card on the screen say "renewal" in one
      # word. English is unchanged: `2 renewals`.
      label: ngettext("%{n} renewal", "%{n} renewals", count, n: Kati.Locale.number(count)),
      total: Kati.Services.Service.format(2298, "GBP")
    }
  end

  @doc """
  The header's own count. The design says *14 items · 2 clashes*, and it counts
  every drawn thing — the all-day release, the merged money row and the members
  inside a collapsed group — not the number of cards on screen.

  Counted into `Kati.Screens.Day`'s own two msgids rather than quoted as a
  sentence. `subtitle/3` prints this string on the drawn day and its own
  `items_tally/1` and `clashes_tally/1` on every other branch of the same
  screen, so quoting left one heading in Latin above a page that had already
  learnt to count in Persian. The two figures are still stated rather than
  derived — they are facts about the DRAWING, and the moduledoc says why the
  cluster maths cannot recover them.
  """
  @spec summary() :: String.t()
  def summary do
    items = 14
    clashes = 2

    joined(
      ngettext("%{n} item", "%{n} items", items, n: Kati.Locale.number(items)),
      ngettext("%{n} clash", "%{n} clashes", clashes, n: Kati.Locale.number(clashes))
    )
  end

  @doc """
  The filter chips and their counts.

  **The labels are keys and are never translated here.** Each one is four
  things at once — what `Kati.Screens.Day.bucket/1` answers, what `visible/2`
  narrows on, what `band/2` matches, and the tail of the
  `String.to_atom("filter_" <> label)` tag every chip carries — and an atom
  built out of `نمایش` is a tag no clause in `handle_tap/2` can read. The WORD
  a reader sees is `Kati.Screens.Day.chip_label/1`, one call further on, which
  is the last moment the key can become copy.

  The counts are integers and the same function's `chip_count/2` puts them into
  the reader's digits.
  """
  @spec chips() :: [{String.t(), non_neg_integer()}]
  def chips, do: [{"Screen", 6}, {"Personal", 6}, {"Money", 2}]

  # A card's clock range — `09:30–09:45`, and `۰۹:۳۰–۰۹:۴۵`.
  #
  # In MINUTES rather than as two `~T` literals, so the argument and the
  # `start_min`/`end_min` beside it are the same digits and a row that
  # disagrees with itself is visible without arithmetic. The conversion is
  # `Kati.Screens.Day.label_for/1`'s, so a card and the gutter it sits against
  # round the same way.
  #
  # Its own msgid rather than the catalogue's `%{from} – %{to}`: that one is
  # spaced and this drawing's dash is tight, and the English cannot move. A
  # CONTEXT because two placeholders either side of a dash is exactly the tiny
  # string `mix gettext.merge` fuzzy-matches onto the spaced entry. Persian
  # keeps the same shape — the two clocks are numbers and the bidi algorithm
  # lays them out with the earlier one on the right, which is the order a
  # Persian reader reads a range in.
  defp clock_range(from_min, to_min) do
    pgettext("a timed card's clock range", "%{from}–%{to}",
      from: clock(from_min),
      to: clock(to_min)
    )
  end

  # `Time.new!/3` rather than `Time.new/3` with a fallback: these minutes are
  # literals in this file, so a bad one is a typo in the fixture and should
  # raise where it was written rather than print a stand-in clock on a board
  # that is compared against a captured frame.
  defp clock(minutes), do: Kati.Locale.time(Time.new!(div(minutes, 60), rem(minutes, 60), 0))

  # `S2 · E3`, and `ف۲ · ق۳` — `Kati.Screens.Library`'s own msgid, which
  # screens 22, 35 and 92 also print, so every season-and-episode pair in the
  # app is spelled one way. The season and episode go in as placeholders: `S`
  # and `E` are English initials and Persian abbreviates the two words it uses
  # instead, which `"S" <> n` has no room for.
  defp episode(season, number),
    do: gettext("S%{s} · E%{e}", s: Kati.Locale.number(season), e: Kati.Locale.number(number))

  # `Kati.Screens.Day.joined/2` and `Kati.Calendar.SampleAgenda.joined/2`
  # verbatim. The `·` is punctuation between two translated halves rather than
  # copy of its own — board 56 draws `عادت · ۱۲ روز پیاپی` with the same glyph
  # — so it is kept out of the msgids: a msgid that is nothing but a middot
  # between two placeholders is the tiny string `mix gettext.merge`
  # fuzzy-matches onto something else, and one sentence holding two tallies
  # would multiply two plural rules into a four-form entry.
  defp joined(left, right), do: left <> " · " <> right
end
