defmodule Kati.Season.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in data for one season's running order, until the Screen domain exists.

  Screen 34's caption is the specification: *"the messy reality of TV —
  specials inline or hidden, three numbering schemes, and two-part finales
  merged into one 2-hour tick. Progress is stored per episode so switching
  order never loses a tick."*

  So an episode's `number` is a **label**, not an index. `S1` is a special
  sitting between E1 and E2; `E7` is two parts merged into one entry. Deriving
  the number from the list position would be exactly the bug the caption warns
  about — the tick belongs to the episode, and the number is what the chosen
  order happens to call it today.

  The eyebrow says nine episodes and the drawing lists eight. That is the
  design's own count and it is kept as the design's own figure rather than
  computed, because the difference is information: an order can hide an entry
  it still counts.

  ## Persian

  mishka-group/kati#103. This fixture is not read only by a test.
  `Kati.Screens.Season.season/2` draws it whenever there is no tracked season
  to draw instead — every fresh install, and every sweep — so a Persian reader
  meets these strings on the page, and every one of them is a msgid.

  Three of the decisions are worth naming, because none of them is *wrap it*:

    * **`:orders` and `:current_order` stay English.** They are STATE and not
      copy. `Kati.Screens.Season.order_tap/2` builds `:order_Aired` out of a
      label and `order_from/1` parses it back, so a translated label would have
      made the tag `:order_پخش` and every tile on a Persian page dead. That
      screen's `order_title/1` is where the word the reader actually reads is
      asked for, one layer above the identity. `DVD` is a format's name rather
      than a word and stays Latin in both scripts, for the reason board 127
      leaves `Lumen+` in Latin on a Persian page.

    * **The rows are composed rather than frozen.** `54m · 9 Jul` is a runtime,
      a separator and a CALENDAR — 9 Jul 2026 is ۱۸ تیر ۱۴۰۵, and neither is a
      spelling of the other — so each row carries an integer and a `Date` and
      asks `Kati.Locale` at the moment it is built.
      `Kati.Screens.EpisodeRatings.rated_episodes/0` made the identical move
      for the identical six episodes one board over, at the identical runtimes
      and dates.

    * **Every msgid here is one another screen already spells.** The heading,
      the subtitle, the eyebrow, the two numbers, the `SPECIAL` badge, the
      runtime, the `airs` prefix, the episode titles and the footnote's second
      sentence are all `Kati.Screens.Season`'s own or `Kati.Library.Sample`'s
      own. That is the whole point of a fixture that is also a fallback: board
      34, board 143 and screen 04 draw the same evening, and one show cannot be
      called two things one tap apart — in either
      script. A second spelling of *فصل ۲* is how two screens come to disagree.
  """

  @doc "The season, as screen 34 draws it."
  @spec season() :: map()
  def season do
    %{
      # `Kati.Screens.Season.heading/2`'s own msgid rather than a second
      # spelling of it: a real season whose provider named it nothing heads
      # itself `Season %{n}`, and the drawn one must not head itself something
      # else one fallback apart.
      title: gettext("Season %{n}", n: Kati.Locale.number(2)),
      # And `assemble/4`'s own subtitle. Its comment there says the screen
      # "does not edit the fixture, it says the label itself" — this is the
      # fixture saying the same label through the same msgid, so the drawn page
      # and the real one agree in both scripts.
      subtitle: gettext("order & specials"),
      # STATE, not copy — see the moduledoc.
      orders: ["Aired", "Absolute", "DVD"],
      current_order: "Aired",
      options: options(),
      # Nine, over eight rows, and deliberately: see the moduledoc. The numeral
      # still converts, because a count the reader is meant to notice is one
      # they have to be able to read — ۹ over eight rows is the design's point
      # and `9` over eight rows is just Latin.
      eyebrow: gettext("Episodes · %{n} in this order", n: Kati.Locale.number(9)),
      episodes: episodes(),
      note: note()
    }
  end

  # The drawing's two switches.
  #
  # `Include specials` is `Kati.Screens.Season.real_options/1`'s own msgid. Its
  # sub-line deliberately is NOT — that screen says something else there and
  # its comment gives the reason at length — and this is the board's wording,
  # which the board still draws.
  #
  # `Merge multi-part` takes a context because it is two words: `mix
  # gettext.merge` fuzzy-matches a msgid that short onto any longer sentence
  # that happens to contain it, and the catalogue already holds `Merged`,
  # `merged` and `Merge %{count} into this device`.
  defp options do
    [
      %{
        icon: "star",
        title: gettext("Include specials"),
        sub: gettext("Shown inline, at air date"),
        on: true
      },
      %{
        icon: "call_merge",
        title: pgettext("season option", "Merge multi-part"),
        # `E7` and `E8` are INTERPOLATED, through the same msgid the rows' own
        # numbers go through, so the sentence and the row it is about cannot
        # come out spelled two ways — `ق۷` in the list and `E7` in the line
        # under it is the one-thing-two-ways problem this fold keeps hitting.
        # `E8` is not a row here on purpose: it is the half the merge
        # swallowed, which is the whole of what this switch says.
        sub:
          gettext("Treat %{a} & %{b} as one %{h}h finale",
            a: episode_number(7),
            b: episode_number(8),
            h: Kati.Locale.number(2)
          ),
        on: true
      }
    ]
  end

  # Two sentences and two msgids, because they are two different facts.
  #
  # The first is a claim about THIS season and nobody else's — `Kati.Screens.
  # Season`'s moduledoc is where that is set out, and why a real season drops
  # it. The second is true of every season, which is why the real screen keeps
  # exactly that half in `general_note/0`. Splitting them here means the drawn
  # footnote and the real one say the identical Persian sentence rather than
  # two translations of one.
  #
  # `27–35` is a range of numbers the reader reads, so both ends convert. The
  # Persian says `از ۲۷ تا ۳۵` rather than keeping the dash: a neutral sitting
  # between two numerals in an RTL paragraph is precisely the punctuation the
  # bidi algorithm moves to the wrong edge, and a range said in words has
  # nowhere to be moved to.
  defp note do
    gettext("Absolute order renumbers this season %{from}–%{to} and drops the special.",
      from: Kati.Locale.number(27),
      to: Kati.Locale.number(35)
    ) <>
      " " <> gettext("Your ticks follow the episode, not the number.")
  end

  # `special: true` tints the number bronze rather than grey — the drawing's
  # quietest way of saying "this one is not part of the count".
  #
  # A runtime and a `Date` rather than the drawn `54m · 9 Jul`, so the sub-line
  # is composed in the reader's own numerals and the reader's own calendar. The
  # six that board 143 also draws carry 143's runtimes and dates, because
  # `Kati.Screens.EpisodeRatings.rated_episodes/0` is the same six episodes of
  # the same season; the making-of and the two-part finale are this board's
  # alone and sit where its drawing puts them.
  #
  # The titles go through the msgids `Kati.Library.Sample.series/0` already
  # puts them through. Screen 04 and this screen are one back tap apart and
  # `Kati.DrawnSeasonAgreementTest` compares the two lists title by title, so a
  # title spelled a second way here is a season the reader has not been
  # watching — in Persian as much as in English.
  defp episodes do
    [
      %{
        number: episode_number(1),
        title: gettext("Low Water"),
        sub: sub_line(54, aired_on(~D[2026-07-09])),
        watched: true
      },
      %{
        number: special_number(1),
        title: gettext("The Estuary — a making-of"),
        sub: sub_line(22, aired_on(~D[2026-07-12])),
        watched: true,
        special: true,
        badge: %{label: pgettext("episode badge", "SPECIAL"), tone: :cream}
      },
      %{
        number: episode_number(2),
        title: gettext("The Cull"),
        sub: sub_line(49, aired_on(~D[2026-07-16])),
        watched: true
      },
      %{
        number: episode_number(3),
        title: gettext("Blackthorn"),
        sub: sub_line(52, aired_on(~D[2026-07-23])),
        watched: true
      },
      %{
        number: episode_number(4),
        title: gettext("What the Tide Left"),
        sub: sub_line(51, aired_on(~D[2026-07-30])),
        watched: true
      },
      %{
        number: episode_number(5),
        title: gettext("Hollow Season"),
        sub: sub_line(47, aired_on(~D[2026-08-06])),
        watched: true
      },
      %{
        number: episode_number(6),
        title: gettext("The Undertow"),
        sub: sub_line(55, airs_on(~D[2026-08-20])),
        watched: false
      },
      %{
        number: episode_number(7),
        title: gettext("Long Hollow"),
        sub: sub_line(122, airs_on(~D[2026-08-27])),
        watched: false,
        # The merged finale's own badge, and the two part numbers are
        # interpolated for the reason the switch's sub-line interpolates E7 and
        # E8: they are numbers the reader reads. Its Persian says `بخش‌های ۱ و ۲`
        # — the dash again said in words rather than set between two numerals
        # in an RTL line. `pgettext/2` and the badge's own context, which is
        # where `SPECIAL` already sits: `mix gettext.merge` fuzzy-matches a
        # label this short onto any sentence that happens to contain it.
        badge: %{
          label:
            pgettext("episode badge", "PARTS %{a}–%{b}",
              a: Kati.Locale.number(1),
              b: Kati.Locale.number(2)
            ),
          tone: :paper
        }
      }
    ]
  end

  # `E6`, and `S1` for a special, in the reader's own letters and digits: `ق۶`,
  # `و۱`. `Kati.Screens.Season.numbered/2`'s two msgids and not a third of our
  # own — the prefix is an abbreviation of a word, قسمت for an episode and
  # ویژه for a special, so it is translated rather than kept as a Latin
  # initial, and the special takes its own context because `S` in this app
  # already means فصل, a SEASON.
  #
  # The digits convert because the face does: `Kati.Screens.Season.
  # episode_body/3` asks `Kati.Locale.mono_face/1` about this very string, and
  # a label with a Persian letter in it is set in Vazirmatn, which has ۰–۹.
  # `kati_mono.ttf` never sees them.
  defp episode_number(n), do: pgettext("episode number", "E%{e}", e: Kati.Locale.number(n))

  defp special_number(n), do: pgettext("special number", "S%{n}", n: Kati.Locale.number(n))

  # `54m · 9 Jul`. The minute's abbreviation is a LATIN convention and Persian
  # writes the word out — `%{n}m` is `۵۴ دقیقه`, because there is no one-letter
  # form of دقیقه to abbreviate to.
  #
  # Joined with a bare separator rather than through a `%{runtime} · %{date}`
  # msgid. There is one of those in the catalogue and its Persian drops the
  # date, so every sub-line that goes through it loses its air date silently;
  # `Kati.Screens.Season.sub_line/1` and `Kati.Screens.EpisodeRatings` both
  # join by hand for that reason, and this is the same line as theirs.
  defp sub_line(minutes, when_phrase),
    do: gettext("%{n}m", n: Kati.Locale.number(minutes)) <> " · " <> when_phrase

  # `9 Jul` for something that has gone out, `airs 20 Aug` for something that
  # has not — the two states the drawing distinguishes, and which of the two a
  # row is in is FROZEN here rather than compared against the clock. A real row
  # asks `Kati.Media.Release.airing/2`; this is a drawing, and the board's
  # answer is the board's. See the note in the parent issue: these dates sit
  # behind today, so a computed answer would quietly redraw the board.
  #
  # `Kati.Locale.date/2` at `:short`, and that is a CALENDAR rather than a
  # format: 20 Aug 2026 is ۲۹ مرداد ۱۴۰۵, and neither is a spelling of the
  # other. The `airs` prefix is `Kati.Screens.Season.air_phrase/2`'s own msgid
  # — already lowercase and already contexted `episode sub-line` precisely
  # because it sits inside a `55m · airs 20 Aug` line rather than heading a
  # card, which is the distinction the app's other `Airs %{date}` would lose.
  defp aired_on(date), do: Kati.Locale.date(date, :short)

  defp airs_on(date),
    do: pgettext("episode sub-line", "airs %{date}", date: Kati.Locale.date(date, :short))
end
