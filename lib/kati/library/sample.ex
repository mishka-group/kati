defmodule Kati.Library.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in library data, until the Screen domain exists.

  The design's screens are drawn full — nine titles, four of them in progress,
  chips carrying counts. A screen rendered against an empty database cannot be
  compared with its drawing, and every state the design specifies (a title part
  watched, a title finished, a title not started) would go unexercised.

  So this module supplies the shape the domain will supply later:
  `%{title, progress, kind}`, ordered as the grid draws them. When the real
  domain lands, delete this and point `Kati.Screens.Library` at it — the
  screen reads a list of maps and does not care where they came from.

  Marked clearly rather than hidden, because sample data that looks like real
  data is how a demo quietly becomes a lie.
  """

  # The design's own titles and its own photographs. Each `seed` is the
  # picsum seed the export uses for that title — `hollow71` is The Long
  # Hollow — so the app shows the exact picture the drawing shows rather than
  # something that merely occupies the same rectangle.
  # A FUNCTION and not an attribute. `gettext/1` inside a module attribute is
  # evaluated at COMPILE time, so nine titles would freeze in whichever locale
  # the compiler happened to be in — the rule mishka-group/kati#103 has hit on
  # every fixture it has folded. `titles/0` below is the reader.
  defp drawn_titles do
    [
      %{title: gettext("The Long Hollow"), seed: "hollow71", progress: 0.62, kind: :series},
      %{title: gettext("Salt & Iron"), seed: "saltiron33", progress: 0.24, kind: :series},
      %{title: gettext("Blue Hour"), seed: "bluehour58", progress: 0.0, kind: :film},
      %{title: gettext("Ashfall"), seed: "ashfall42", progress: 0.41, kind: :series},
      %{title: gettext("Marram"), seed: "marram15", progress: 1.0, kind: :series},
      %{title: gettext("Harbour"), seed: "harbour86", progress: 0.0, kind: :film},
      %{title: gettext("Nightbirds"), seed: "nightbirds24", progress: 1.0, kind: :film},
      %{title: gettext("Vellum"), seed: "vellum97", progress: 0.08, kind: :film},
      %{title: gettext("The Cartographer"), seed: "cartog60", progress: 0.0, kind: :series}
    ]
  end

  @doc """
  Absolute path to a sample poster, or `nil` when there is none.

  The artwork lives in `priv/sample/`, which #72 proved survives a release
  build, so the same lookup works in dev and on a shipped device. Real artwork
  rather than grey rectangles, because a screen full of placeholders cannot be
  compared with a drawing full of posters.
  """
  @spec poster(String.t()) :: String.t() | nil
  def poster(seed), do: Kati.Design.Images.poster(seed)

  @doc "Wide artwork for a series header."
  @spec art(String.t()) :: String.t() | nil
  def art(seed), do: Kati.Design.Images.hero(seed)

  @doc "Every title, in the order the grid draws them."
  @spec titles() :: [map()]
  def titles, do: drawn_titles()

  # `test/design/reference/146.html`'s own three tiles, in its own words —
  # `S2 · 5/7` and `S1 · 3/8` are a season and an episode fraction, not the
  # `62% watched` `Kati.Screens.Library.tile_meta/1` prints for the same two
  # shows. Two screens, two sentences about one shelf; this list carries the
  # sentence 146 draws rather than teaching `tile_meta/1` a second dialect.
  #
  # `:ashfall` and `:vellum` are not on the board. It crops to three posters
  # at a 402pt frame and still reads "4 selected" — so two more names are
  # selected off the visible edge, the same way a real shelf's selection runs
  # past whatever a phone happens to be showing. Both are titles `titles/0`
  # already carries, given a season/episode line here since 146's grid is not
  # 03's grid and does not print a percentage.
  #
  # A FUNCTION and not the `@selection_shelf` attribute this was, for
  # `drawn_titles/0`'s reason: `gettext/1` inside a module attribute is
  # evaluated at COMPILE time, so five titles and five captions would freeze in
  # whichever locale `mix compile` happened to be in. mishka-group/kati#103.
  defp drawn_selection_shelf do
    [
      %{
        id: :hollow,
        title: gettext("The Long Hollow"),
        seed: "hollow71",
        meta: season_fraction(2, 5, 7),
        selected?: true,
        done?: false
      },
      %{
        id: :saltiron,
        title: gettext("Salt & Iron"),
        seed: "saltiron33",
        meta: season_fraction(1, 3, 8),
        selected?: true,
        done?: false
      },
      %{
        id: :nightbirds,
        title: gettext("Nightbirds"),
        seed: "nightbirds24",
        # The board's own caption for this tile is the WORD `done`, and
        # `Kati.Screens.ShelfSelection.display_meta/1` already holds a msgid for
        # it — the one it draws once `Status` has flipped `done?`. Reused rather
        # than restated, because the reader meets one tile saying تمام‌شده
        # either way and two Persian words for one state would send them looking
        # for a difference that is not there. (`done?` stays `false`: it is what
        # `change_status/2` flips, and the drawing has no control to be one.)
        meta: pgettext("a shelf tile's mono line once Status has marked it complete", "done"),
        selected?: false,
        done?: false
      },
      %{
        id: :ashfall,
        title: gettext("Ashfall"),
        seed: "ashfall42",
        meta: season_fraction(1, 2, 6),
        selected?: true,
        done?: false
      },
      %{
        id: :vellum,
        title: gettext("Vellum"),
        seed: "vellum97",
        # `Kati.Screens.Library.tile_meta/1`'s own msgid for the same state, for
        # the reason `done` above takes `display_meta/1`'s: screen 03 and this
        # grid say *not started* about one shelf row, and one thing gets one
        # word.
        meta: gettext("not started"),
        selected?: true,
        done?: false
      }
    ]
  end

  # `S2 · 5/7` — the season and the episode fraction board 146 captions a tile
  # with. One msgid rather than three fragments glued together here: Persian
  # writes the fraction with a word (*۵ از ۷*) where English writes a solidus,
  # and a fixture that concatenated would have decided that for the translator.
  #
  # `pgettext/2` because the msgid is two tokens and two placeholders.
  # `mix gettext.merge` fuzzy-matches anything that short, and the catalogue
  # already holds `S%{s} · E%{e}` — a different separator for a different row.
  defp season_fraction(season, watched, total) do
    pgettext("a shelf tile's season and episode fraction", "S%{s} · %{watched}/%{total}",
      s: Kati.Locale.number(season),
      watched: Kati.Locale.number(watched),
      total: Kati.Locale.number(total)
    )
  end

  @doc """
  The shelf `Kati.Screens.ShelfSelection` draws: three tiles the board shows
  and two more selected the same board's own count implies.

  `selected?` is the board's own starting selection — two tiles ringed, two
  more counted but off the 402pt crop, `Nightbirds` neither — so a fresh
  mount of the screen opens on exactly `test/design/reference/146.html`'s
  "Four selected" vignette rather than an empty one nothing was drawn for.

  `done?` is not the board's — the drawing has no status control to be one —
  it is what `Kati.Screens.ShelfSelection.change_status/2` flips, standing in
  for the sheet 146 does not draw behind its own `Status` pill.
  """
  @spec selection_shelf() :: [map()]
  def selection_shelf, do: drawn_selection_shelf()

  @doc "The header's mono subtitle: `9 titles · 4 in progress`."
  @spec subtitle() :: String.t()
  def subtitle do
    # `Kati.Screens.Library.subtitle/1` and not a second composition of the
    # same line: board 57 heads its shelf ۹ عنوان · ۴ در حال تماشا and board 03
    # heads its own `9 titles · 4 in progress`, and those are one function over
    # one list. Written out here it was two sentences that could disagree about
    # what a shelf holds. mishka-group/kati#103.
    Kati.Screens.Library.subtitle(
      Enum.map(drawn_titles(), fn title ->
        %{status: if(title.progress > 0.0 and title.progress < 1.0, do: :watching, else: :other)}
      end)
    )
  end

  @doc "Filter chips with their counts, the first one selected."
  # `{tag, label, count}` and not `{label, count}`: the tag is what a tap is
  # keyed on and the label is what the reader sees, and those stopped being one
  # string the day the label went through `gettext/1` — a chip keyed on its own
  # Persian word is `Kati.Screens.Books.chip_counts/1`'s recorded failure. The
  # spec had not been told; it said two elements and the list has held three
  # since.
  @spec chips() :: [{atom(), String.t(), non_neg_integer()}]
  def chips do
    [
      {:all, gettext("All"), length(drawn_titles())},
      {:watching, gettext("Watching"),
       Enum.count(drawn_titles(), &(&1.progress > 0.0 and &1.progress < 1.0))},
      {:not_started, gettext("Not started"), Enum.count(drawn_titles(), &(&1.progress == 0.0))},
      {:finished, gettext("Finished"), Enum.count(drawn_titles(), &(&1.progress == 1.0))}
    ]
  end

  @doc """
  One series, as screen 04 draws it: the header line, the season's progress,
  the next airing, and seven episodes with three distinct states — watched,
  unwatched, and the one that has not aired.
  """
  @spec series() :: map()
  def series do
    %{
      title: gettext("The Long Hollow"),
      seed: "hollow71",
      # `LUMEN+` is a service's own name and stays; the year, the genre and the
      # season count are Kati's.
      meta:
        gettext("%{year} · %{genre} · LUMEN+ · %{seasons}",
          year: Kati.Locale.year(2024),
          genre: Kati.UI.eyebrow_label(gettext("Drama")),
          seasons:
            Kati.UI.eyebrow_label(
              ngettext("%{n} season", "%{n} seasons", 3, n: Kati.Locale.number(3))
            )
        ),
      season: gettext("Season %{n}", n: Kati.Locale.number(2)),
      # `S1`/`S2`/`S3` are tap tags as well as labels and stay ASCII —
      # `Kati.Screens.Series.season_pill_label/1` is what the reader sees.
      seasons: ["S1", "S2", "S3"],
      current_season: "S2",
      watched: 5,
      total: 7,
      next_air:
        gettext("%{date}, %{time}",
          date: Kati.Locale.date(~D[2026-08-20], :long),
          time: Kati.Locale.time(~T[20:00:00])
        ),
      # Board 34's Season 2, which is the only board that NAMES these episodes
      # — screen 04's frame draws `{{ ep.title }}` and nothing else, so it has
      # no opinion about them and this fixture invented seven of its own.
      # Opening *Episode order* from here then showed a different Season 2 one
      # tap apart: *The Weight of Water / Hollow Ground / Salt in the Wound*
      # here, *Low Water / The Cull / Blackthorn* there, same show, same
      # season, same evening.
      #
      # So this list is 34's, in 34's aired order, at 34's runtimes and dates.
      # It is 34's list less the making-of, because a special is exactly what
      # board 34 is ABOUT — *Include specials* is one of its two switches —
      # and 04 draws no badge to say a row is one. Seven rows either way, so
      # the drawing's `5 of 7 watched` and its three row states are untouched.
      episodes: [
        aired_episode(1, gettext("Low Water"), 54, ~D[2026-07-09]),
        aired_episode(2, gettext("The Cull"), 49, ~D[2026-07-16]),
        aired_episode(3, gettext("Blackthorn"), 52, ~D[2026-07-23]),
        aired_episode(4, gettext("What the Tide Left"), 51, ~D[2026-07-30]),
        aired_episode(5, gettext("Hollow Season"), 47, ~D[2026-08-06]),
        %{aired_episode(6, gettext("The Undertow"), 55, ~D[2026-08-20]) | watched: false},
        upcoming_episode(7, gettext("Long Hollow"), ~D[2026-08-27])
      ]
    }
  end

  @doc """
  Episodes for a season the drawing never shows.

  Screen 04 draws S2 and only S2, so `series/0` carries that list verbatim and
  the captured frame is unaffected. But the S1/S2/S3 pills are a real control,
  and a control that changes nothing is a lie told in pixels — so the other
  two seasons need episodes to switch to.

  These are dummy, and shaped like the drawing's own: a runtime and an air
  date in the same mono sub-line, a whole finished season for S1, and S3 with
  nothing aired yet because the header says the next episode is still coming.
  """
  @spec season_episodes(String.t()) :: [map()]
  def season_episodes("S1") do
    [
      aired_episode(1, gettext("Low Water"), 46, ~D[2026-06-04]),
      aired_episode(2, gettext("The Ferry Road"), 44, ~D[2026-06-11]),
      aired_episode(3, gettext("Marram"), 49, ~D[2026-06-18]),
      aired_episode(4, gettext("Every Quiet Thing"), 45, ~D[2026-06-25]),
      aired_episode(5, gettext("The Long Hollow"), 58, ~D[2026-07-02])
    ]
  end

  def season_episodes("S3") do
    [
      upcoming_episode(1, gettext("Undertow"), ~D[2026-08-27]),
      upcoming_episode(2, gettext("The Bell Buoy"), ~D[2026-09-03]),
      upcoming_episode(3, gettext("Saltings"), ~D[2026-09-10])
    ]
  end

  def season_episodes(_s2), do: series().episodes

  # One drawn episode row, composed rather than written out: the runtime and the
  # date are the reader's numerals and the reader's calendar. It was two frozen
  # strings apiece, which is why board 58's mirror kept a second copy of all
  # fifteen rows.
  defp aired_episode(n, title, minutes, on) do
    %{
      n: n,
      title: title,
      sub:
        gettext("%{runtime} · %{date}",
          runtime: gettext("%{n} min", n: Kati.Locale.number(minutes)),
          date: Kati.Locale.date(on, :short)
        ),
      watched: true
    }
  end

  defp upcoming_episode(n, title, on) do
    %{
      n: n,
      title: title,
      sub: gettext("Airs %{date}", date: Kati.Locale.date(on, :long)),
      watched: false,
      aired: false
    }
  end

  @doc """
  The new-releases inbox, screen 05: three titles out now and three coming up.

  The dot colour carries the reason a row is here — a new episode, a premiere,
  or something about to leave a service — which is the design's way of saying
  three different things in one list without three different layouts.
  """
  @spec inbox() :: map()
  def inbox do
    %{
      watching: 24,
      out_now: [
        %{
          title: gettext("The Long Hollow"),
          seed: "hollow71",
          line: episode_line(2, 6, gettext("The Undertow")),
          meta:
            facts([
              gettext("%{n} min", n: Kati.Locale.number(48)),
              service("LUMEN+"),
              pgettext("out now row", "aired %{time}", time: Kati.Locale.time(~T[20:00:00]))
            ]),
          dot: 0xFFE8823C
        },
        %{
          title: gettext("Blue Hour"),
          seed: "bluehour58",
          # The green dot's row: a film opening rather than an episode landing.
          # `pgettext/2` on a one-word line, because `mix gettext.merge` fuzzy
          # matches a msgid that short and the catalogue already holds
          # `Kati.Settings.Sample`'s *Premieres* — the notification the reader
          # switches on, which is a different noun from what this row IS.
          line: pgettext("an out now row's reason", "Premiere"),
          meta:
            facts([
              runtime(1, 52),
              # `CINEMA` is not a service's name — it is Kati's word for the
              # room, and `Kati.Money.Sample` already says سینما for the same
              # place. So it translates where `LUMEN+` beside it does not.
              Kati.UI.eyebrow_label(pgettext("where a film is showing", "Cinema")),
              pgettext("an out now row, for a film released today", "out today")
            ]),
          dot: 0xFF4E9A73
        },
        %{
          title: gettext("Paper Cities"),
          seed: "cartog60",
          line: episode_line(1, 2, gettext("The Cartographer")),
          meta:
            facts([
              gettext("%{n} min", n: Kati.Locale.number(44)),
              service("LUMEN+"),
              pgettext("out now row", "aired %{time}", time: Kati.Locale.time(~T[19:00:00]))
            ]),
          dot: 0xFFE8823C
        }
      ],
      # NOT translated, and deliberately: nothing draws these.
      # `Kati.Screens.Inbox.drawn_inbox/0` lays `coming_up_rows/0` over this key
      # on every path into the screen — that function's own doc says it is
      # stated there "rather than taken from `Kati.Library.Sample`, whose list
      # had drifted to a different three titles" — so no reader, in either
      # script, ever meets these three rows.
      #
      # They are also the wrong SHAPE for the card that would draw them:
      # `upcoming_row/2` reads `row.armed` to pick the bell and these carry no
      # such key, so a render would raise rather than print Latin. Wrapping them
      # in `gettext/1` would put six msgids in the catalogue for copy nobody can
      # see and would not make the rows drawable; deleting them is a change to a
      # public fixture's shape and belongs with whoever removes the override.
      coming_up: [
        %{
          month: "AUG",
          day: "20",
          title: "The Long Hollow",
          line: "S2 E7 — Homecoming",
          meta: "Thu, 20:00"
        },
        %{month: "AUG", day: "23", title: "Salt & Iron", line: "S1 E4", meta: "Sun, 21:00"},
        %{month: "SEP", day: "02", title: "Ember & Ash", line: "Leaves Lumen+", meta: "Tue"}
      ]
    }
  end

  # `S2 E6 — The Undertow`, composed the way `Kati.Screens.Inbox.episode_line/1`
  # composes a real row's: the number through the msgid that screen already
  # draws for it, and an em dash joining two facts rather than making a sentence
  # a translator could want to reorder. `Kati.DrawnSeasonAgreementTest` asks
  # that this line still END in an episode of the season screens 04 and 34 draw,
  # which is why the title goes last in both scripts.
  defp episode_line(season, number, title) do
    pgettext("episode number", "S%{s} E%{e}",
      s: Kati.Locale.number(season),
      e: Kati.Locale.number(number)
    ) <> " — " <> title
  end

  @doc """
  Search results for screen 06, mid-query on "quiet".

  Two states are drawn and both appear here: a title not in the library yet
  (ink `add` button) and one already added (muted `check`), because the design
  distinguishes them and a list of four identical rows would not exercise it.

  **`kind` is new and is load-bearing.** These four rows had none, so
  `Kati.Screens.AddTitle.kind_of/1` fell through to its last resort and read the
  WORDS out of `meta` — `String.contains?(meta, "SERIES")`. That worked only
  while the line was Latin, and its own doc says so in as many words: *"the
  fallback stays, and stays English, because the rows that reach it are
  English"*. `سریال` contains neither `SERIES` nor `FILM`, so a Persian reader
  who tapped **Series** over these four would have got the empty list that
  screen's `visible/2` was rewritten to prevent — and a hand-added row would
  have been stored as a film. The kind is stated on the row now, which is where
  `kind_of/1` looks first and the one answer that does not change with the
  locale.
  """
  @spec search_results() :: [map()]
  def search_results do
    [
      %{
        title: gettext("The Quiet Coast"),
        seed: "quieterplace8",
        kind: :tv,
        meta: facts([Kati.Locale.year(2023), gettext("SERIES"), seasons(2)]),
        note: facts([gettext("Drama"), service("Lumen+")]),
        added: false
      },
      %{
        title: gettext("Quiet Earth"),
        seed: "quietones12",
        kind: :movie,
        meta: facts([Kati.Locale.year(2019), gettext("FILM"), runtime(1, 48)]),
        note: gettext("Science fiction"),
        added: false
      },
      %{
        title: gettext("A Quiet Place to Land"),
        seed: "quieterplace8",
        kind: :movie,
        # `Kati.Locale.pick/2` on the padded minutes and not `number("04")`.
        # The leading zero is a LATIN typographic choice — the drawing pads so a
        # column of runtimes lines up — and `Kati.Locale.date/2` makes the same
        # call about `:short_padded`: Persian numerals are already even-width,
        # so ۰۴ is a zero the reader has no use for. Both values stay at the
        # call site, which is what `pick/2` is for.
        meta:
          facts([
            Kati.Locale.year(2021),
            gettext("FILM"),
            runtime(2, Kati.Locale.pick("04", 4))
          ]),
        note: facts([gettext("Drama"), pgettext("where a film is showing", "Cinema")]),
        added: true
      },
      %{
        title: gettext("Quietus"),
        seed: "quietus39",
        kind: :tv,
        meta: facts([Kati.Locale.year(2024), gettext("SERIES"), seasons(1)]),
        # `Northlight` is a service's own name and stays — see `service/1`. It
        # needs no isolate: it ends in a letter, so there is no neutral for the
        # bidi algorithm to carry to the wrong edge.
        note: facts([gettext("Thriller"), "Northlight"]),
        added: false
      }
    ]
  end

  @doc """
  One film, as screen 08 draws it.

  `12 Aug` is the date twice over — the green pill and the note's eyebrow — and
  it is one `Date` here rather than two strings, because it is one evening:
  under `:fa` both read ۲۱ مرداد, which is the same day in the reader's own
  calendar rather than a Gregorian one spelled in Persian.
  `Kati.Screens.Film.note_date/2` names that exact line in its own comment.
  """
  @spec film() :: map()
  def film do
    watched_on = ~D[2026-08-12]

    %{
      title: gettext("Blue Hour"),
      seed: "bluehour58",
      # `2025 · 1H 52M · DRAMA`, composed out of the three msgids
      # `Kati.Screens.Film.meta_line/1` builds a real film's line from, so the
      # drawn page and the tracked page cannot come to say a runtime two ways.
      # `Kati.Locale.year/1` and never `date/2` on the 2025: a release year is a
      # fact printed on the film, so the digits change and the calendar does
      # not.
      meta:
        facts([
          Kati.Locale.year(2025),
          Kati.UI.eyebrow_label(runtime(1, 52)),
          Kati.UI.eyebrow_label(gettext("Drama"))
        ]),
      watched: gettext("Watched %{date}", date: Kati.Locale.date(watched_on, :short)),
      stars: 4,
      # `ngettext/4` rather than the frozen `2 times`: English inflects the noun
      # after a numeral and Persian does not, and both of `%{n} بار`'s forms are
      # the same words. `Kati.Screens.Film.seen_line/1`'s msgid, because a
      # rewatch count is the same sentence on the drawn page and the real one.
      seen: ngettext("%{n} time", "%{n} times", 2, n: Kati.Locale.number(2)),
      note_date: gettext("Note · %{date}", date: Kati.Locale.date(watched_on, :short)),
      # One literal and not the `<>` pair this was: `gettext/1` takes its msgid
      # from a LITERAL at the call site, and a sentence split across two of them
      # is a sentence no translator can join. Board 08 draws it as one line.
      note:
        gettext(
          "Saw it at the Rex with Jo. The last twenty minutes are the whole film — worth a rewatch on a proper screen."
        ),
      where: [
        # `line` and not `price`, which is a fix rather than a wrapping.
        # `included` is a WORD and `£9.99` is a FIGURE, and
        # `Kati.Screens.Film.where_value/1` typesets the two slots differently
        # on purpose: the price goes to DM Mono because the drawing sets it
        # there and `£` is not Persian, while the word takes
        # `Kati.Locale.mono_face/1` because `kati_mono.ttf` has no glyph for a
        # letter of با اشتراک. Carried in the price slot, the Persian word was
        # handed to DM Mono and came out as Android's substitute face — the
        # exact failure that comment is written to prevent. The msgid is
        # `Kati.Screens.SeriesMeta.where_rows/1`'s, so screen 14 and screen 08
        # name one offer with one word.
        %{badge: "L", name: service("Lumen+"), line: pgettext("where to watch", "included")},
        %{badge: "K", name: "Kino store", price: "£9.99"}
      ],
      # `{icon, tag}` rather than `{icon, label}`, matching
      # `Kati.Screens.Film`'s own list. The label is decided by
      # `Kati.Screens.Film.action_label/2` because it depends on whether the
      # film has been seen — a *rewatch* is a second watch, and this drawing's
      # film has two, so board 08's word is unchanged.
      #
      # All three labels go through the catalogue, and they are the SAME three
      # entries `Kati.Screens.Film.action_row/0` draws for a real film — the
      # *Schedule* under its own context, because that one is the verb and
      # `Kati.Screens.Calendar` already holds the noun. `action_label/3` hands
      # the drawn label straight back for the two that carry no tag, so these
      # are what the reader sees; wrapping them here rather than mapping them
      # back to msgids in the screen is that function's own instruction — the
      # fixture owns its literals.
      actions: [
        {"replay", gettext("Log rewatch"), :log_watch},
        {"event", pgettext("film action pill", "Schedule"), nil},
        {"ios_share", gettext("Share"), nil}
      ],
      seen_count: 2
    }
  end

  # ── Shared pieces of a meta line ───────────────────────────────────────────

  # Facts on one line, joined by the design's middot.
  #
  # Joined here rather than held as one `%{a} · %{b} · %{c}` msgid, and
  # `Kati.Screens.AddTitle.meta_line/1` is where the argument is written out:
  # the middot is a bidi NEUTRAL sitting between a number and a word, so it
  # takes the paragraph's direction and a Persian line lays out right-to-left in
  # the order it was written. There is nothing here for a translator to
  # reorder, and a msgid that is three interpolations and two middots is exactly
  # what `mix gettext.merge` fuzzy-matches against every other `·` line in the
  # catalogue. Each FACT is its own msgid; the punctuation between them is not.
  defp facts(parts), do: Enum.join(parts, " · ")

  # `1h 52m`, through the msgid screen 08, screen 13, screen 61 and
  # `Kati.Screens.SeriesMeta.runtime_label/1` all draw a duration with. Lower
  # case, because the capitals belong to `Kati.UI.eyebrow_label/1` at the call
  # sites that want them — board 08 sets its runtime in caps and board 06 does
  # not, and Persian has no case for either of them to apply.
  defp runtime(hours, minutes),
    do: gettext("%{h}h %{m}m", h: Kati.Locale.number(hours), m: Kati.Locale.number(minutes))

  # `2 SEASONS`. `ngettext/4` and not a hand-picked plural: English inflects the
  # noun after a numeral and Persian does not, so `۲ فصل` and `۱ فصل` are the
  # same words and a fixture that chose the form itself would have chosen it for
  # one language.
  defp seasons(n),
    do:
      Kati.UI.eyebrow_label(ngettext("%{n} season", "%{n} seasons", n, n: Kati.Locale.number(n)))

  # A service's own name, kept in its own script and isolated from the sentence
  # around it.
  #
  # `LUMEN+`, `Lumen+`, `Kino store` and `Northlight` are **names**. A real one
  # comes off `Kati.Services.Service` and no msgid reaches it, so a fixture that
  # transliterated would spell one service two ways across the app — the reason
  # `Kati.Screens.Film.where_row/2` and `Kati.Screens.SeriesMeta.where_rows/1`
  # both give, and the reason board 127, the Persian Money page, draws `Lumen+`
  # in Latin. `Kati.DesignLiterals` carries the same decision as an exemption
  # for board 55's `لومن‌پلاس`.
  #
  # `Kati.Locale.ltr/1` because these runs sit inside a Persian line and one of
  # them ENDS in a neutral: `+` takes the direction of the paragraph rather than
  # of the word before it, so `LUMEN+` is laid out as `+LUMEN` on an RTL page.
  # `U+2066…U+2069` makes the run resolve against itself, and is a no-op in
  # Latin so the English render is unchanged to the byte.
  defp service(name), do: Kati.Locale.ltr(name)
end
