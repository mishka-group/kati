defmodule Kati.Activity.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in activity history, until the Screen domain keeps a real one.

  Screen 15 is the app's append-only log — *"every tick, rating, drop and
  import"* — and it is also the undo trail, so the shape here is the shape a
  real entry has to have: **when** it happened, **what** it happened to, and a
  verb that names the change. Nothing else.

  The verb is stored apart from the rest of the line (`lead` / `rest`) because
  the drawing sets it in bold ink against `#5C574F` body text, and Mob's `Text`
  carries one weight. Two runs in a `Row`, not one string with markup.

  `stars` is present on exactly one row, which is the design's own doing: a
  rating entry shows the rating it recorded. Rows without it simply do not
  carry the key.

  ## Which of these fields is copy and which is a key

  `Kati.Screens.Activity.drawn/0` renders this module verbatim on a device that
  has recorded nothing — which is a fresh install, so it is the first thing a
  Persian reader ever sees of screen 15. Two of the five keys reach a `Text`
  and are therefore the reader's own language; the other three never do:

    * `stamp` and `rest` are **drawn**. They are built here exactly the way
      `Kati.Screens.Activity` builds a real row's — through `Kati.Locale` and
      through the same msgids `verb/2`, `event_verb/3` and `episode_label/1`
      already use — because `Kati.ScreenActivityTest` asserts a shaped real row
      is *equal* to the drawn one it corresponds to. A second wording here would
      be a second wording on the same screen one empty database apart.
    * `lead` and `filters/0` are **keys** and stay English in every locale.
      `Kati.Screens.Activity.visible/2` matches the chip's value against `lead`
      and `filter_chip/2` builds its tap tag out of the value
      (`String.to_atom("filter_" <> value)`), so a translated one would tap
      nothing. `filter_label/1` and `verb_label/1` are the only places the
      reader's language gets in, and they get in on the way to a `Text` —
      `Kati.Screens.AddTitle`'s Persian mirror stored «همه» in the value and
      drew four perfect chips that each showed everything.
    * `seed` is a picsum seed — `hollow71` is The Long Hollow — resolved by
      `Kati.Design.Images.poster/1`. It is a file lookup, never a word. `stars`
      is a count of Material Symbols glyphs, so no digit of it is ever drawn.

  mishka-group/kati#103.
  """

  @doc """
  The mono line under the title — `1,204 entries`, and `۱,۲۰۴ مورد`.

  The FIGURE board 15 was captured at, through the screen's own sentence rather
  than frozen as a string. This was `"1,204 entries"`, and
  `Kati.Screens.Activity.drawn/0` routed around it for exactly that reason: a
  frozen Latin line puts `1,204 entries` under **فعالیت**, in Latin numerals,
  on every Persian device with nothing recorded. `entries_line/1` is where the
  wording, the grouping comma and the digits already live, and its own doc says
  one wording, one place — the same fix `Kati.Stats.Sample`'s copy of this line
  got on 6 September.

  A remote call rather than a second `ngettext/4` here, because the thousands
  separator this line needs is `Kati.Screens.Activity`'s private `delimited/1`
  and a second grouper is the drift this replaces.
  """
  @spec entries_line() :: String.t()
  def entries_line, do: Kati.Screens.Activity.entries_line(1204)

  @doc """
  The filter chips, the first one selected.

  ENGLISH in every locale, and not an oversight: each of these is both the
  value `Kati.Screens.Activity.visible/2` matches against a row's `lead` and
  the word its tap tag is built from. `Kati.Screens.Activity.filter_label/1`
  translates them on the way to the chip, which is the only place a reader
  sees them. A fifth verb is a change to this list and to that function.
  """
  @spec filters() :: [String.t()]
  def filters, do: ["All", "Watched", "Rated", "Added"]

  @doc """
  Today's entries, newest first, stamped with a clock.
  """
  @spec today() :: [map()]
  def today do
    [
      %{
        stamp: clock_stamp("21:12"),
        seed: "hollow71",
        lead: "Watched",
        rest: gettext("The Long Hollow") <> " " <> episode_label(2, 5)
      },
      %{
        stamp: clock_stamp("20:40"),
        seed: "bluehour58",
        lead: "Rated",
        rest: gettext("Blue Hour"),
        stars: 4
      },
      %{
        stamp: clock_stamp("18:03"),
        seed: "vellum97",
        lead: "Added",
        # The one drawn row `Kati.Media.Event` still cannot store — this
        # screen's own moduledoc: *there is no list resource for a wishlist to
        # be added to* — so the sentence is this file's rather than
        # `event_verb/3`'s, and it needs a msgid of its own. The list is named
        # inside the msgid rather than interpolated, because فهرست آرزو is the
        # app's one word for it (`Kati.Import.Sample`'s `%{shelf} → Wishlist`,
        # `Kati.Screens.ReleaseWatcher`'s *Titles on your wishlist*) and a bare
        # `Wishlist` msgid is one word that `mix gettext.merge` would fuzzy-match
        # onto any of them.
        rest:
          pgettext("an added-to-a-list row in the activity log", "%{title} to Wishlist",
            title: gettext("Vellum")
          )
      }
    ]
  end

  @doc """
  Earlier this month, stamped with a date instead of a clock.

  Same row, different gutter: once a day has passed the time stops carrying
  information and the date starts to.
  """
  @spec earlier() :: [map()]
  def earlier do
    [
      %{
        stamp: date_stamp(~D[2026-08-12]),
        seed: "nightbirds24",
        lead: "Rewatched",
        # `verb/2`'s own shape: the named episode, a middle dot, and which
        # viewing this was. `%{ordinal} time` rather than an ordinal glued to a
        # translated `time`, for the reason that msgid was introduced with — the
        # counter word comes FIRST in Persian (بار ۳ام), so the two halves
        # cannot be assembled in English's order.
        rest:
          gettext("Nightbirds") <>
            " " <>
            episode_label(1, 1) <>
            " · " <>
            pgettext("the nth viewing, on a rewatch row", "%{ordinal} time", ordinal: third())
      },
      %{
        stamp: date_stamp(~D[2026-08-10]),
        seed: "nightbirds24",
        lead: "Finished",
        # The em dash is the DRAWING's separator and stays a literal: board 15
        # writes `Nightbirds — Season 1` where `event_verb/3` writes a middle
        # dot for a real one, and the captured frame is what this module is.
        # Both runs around it are the reader's script, so the dash resolves
        # against them and needs no isolate.
        #
        # `Season %{n}` rather than a msgid of this file's own:
        # `Kati.Screens.Series`, `Kati.Screens.Season` and `Kati.Screens.Inbox`
        # all draw that one, and a second Persian word for a season is a season
        # spelled two ways.
        rest: gettext("Nightbirds") <> " — " <> gettext("Season %{n}", n: Kati.Locale.number(1))
      },
      %{
        stamp: date_stamp(~D[2026-08-07]),
        seed: "quietones12",
        lead: "Dropped",
        rest:
          gettext("The Quiet Ones") <>
            " " <>
            pgettext("where a series was left, on an activity row", "after S%{s}E%{e}",
              s: Kati.Locale.number(1),
              e: Kati.Locale.number(3)
            )
      },
      %{
        stamp: date_stamp(~D[2026-08-02]),
        seed: "cartog60",
        lead: "Imported",
        # `event_verb/3`'s import clause, with the board's own source. A real
        # import names the FILE it was read out of and wraps it in
        # `Kati.Locale.ltr/1`; the drawing names a kind of file instead, which
        # is prose and translates — so no isolate here, and `CSV` rides inside
        # the Persian the way it does in `Kati.Settings.Sample`'s
        # *CSV، JSON یا پشتیبان دیگر*.
        rest:
          pgettext("an import row in the activity log", "%{titles} from %{source}",
            titles: ngettext("%{n} title", "%{n} titles", 412, n: Kati.Locale.number(412)),
            source: pgettext("the kind of file an import row was read out of", "a CSV backup")
          )
      }
    ]
  end

  @doc "What has been watched more than once, and how many times."
  @spec rewatch() :: [{String.t(), String.t()}]
  def rewatch do
    [
      {gettext("Nightbirds") <> " " <> episode_label(1, 1), times(3)},
      {gettext("Blue Hour"), times(2)},
      {gettext("The Cartographer") <> " " <> season_label(1), times(2)}
    ]
  end

  # `21:12`, and `۲۱:۱۲`. `Kati.Screens.Activity.clock_stamp/1` verbatim:
  # `Kati.Locale.number/1` rather than `Kati.Locale.time/1`, because the clock
  # is already formatted by the time it reaches this and only its digits are in
  # question. `entry_row/5` hands the result to `Kati.Locale.mono_face/1`, which
  # keeps the Latin stamp in DM Mono and moves the Persian one to Vazirmatn —
  # `kati_mono.ttf` carries no Persian digit.
  defp clock_stamp(clock), do: Kati.Locale.number(clock)

  # `12 AUG`, and `۲۱ مرداد` — a different CALENDAR rather than the same date
  # translated. A `Date` in and the reader's own month out, which is the whole
  # of it: board 15 was captured in August 2026, and 12 August 2026 falls in
  # Mordad. No formatting of the number 8 produces that, so the stamps cannot
  # stay the frozen strings they were.
  #
  # `Kati.Screens.Activity.date_stamp/1`'s own two calls, in its order.
  # `:short_padded` is the style `%d %b` was — the leading zero is what lines
  # `02 AUG` up with `12 AUG` in a 44pt mono column — and `Kati.Locale` resolves
  # it to Shamsi's `:short`, whose numerals are already even-width and have no
  # column to pad. `Kati.UI.eyebrow_label/1` rather than `String.upcase/1` for
  # the caps: the Arabic script has no case, and upcasing مرداد is a no-op that
  # reads in a diff as a decision somebody made.
  defp date_stamp(date), do: Kati.UI.eyebrow_label(Kati.Locale.date(date, :short_padded))

  # `S2E5`, and `ف۲ق۵`. The msgid `Kati.Screens.Activity.episode_label/1`
  # already carries, so a drawn row and a real one name an episode the same
  # way — its `pgettext/2` is there because `S%{s}E%{e}` is two characters and
  # two bindings, which `mix gettext.merge` will hand to any neighbour it half
  # resembles.
  defp episode_label(season, episode),
    do:
      pgettext("episode label on an activity row", "S%{s}E%{e}",
        s: Kati.Locale.number(season),
        e: Kati.Locale.number(episode)
      )

  # `S1`, and `ف۱` — the rewatch card's Cartographer row, which counts a whole
  # season rather than an episode.
  defp season_label(season),
    do: pgettext("season label on an activity row", "S%{s}", s: Kati.Locale.number(season))

  # `3×`, and `۳×`. `rewatch_counts/2`'s own msgid: the count is a figure and a
  # symbol rather than a sentence, so the msgid is mostly there to let a
  # translator who wants `۳ بار` have it without editing this file.
  defp times(n),
    do: pgettext("how many times a title has been watched", "%{n}×", n: Kati.Locale.number(n))

  # `3rd`, and `۳ام`. `Kati.Screens.Activity.ordinal/1` at the one number this
  # board needs, and a `Kati.Locale.pick/2` over two whole answers rather than a
  # shared skeleton with a translated suffix: English's four suffixes are an
  # English rule, and Persian suffixes ـُم to the numeral with no exceptions at
  # all. Writing `3` <> a translated `rd` would be the English rule in Persian
  # letters.
  defp third, do: Kati.Locale.pick("3rd", Kati.Locale.number(3) <> "ام")
end
