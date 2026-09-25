defmodule Kati.Screens.SeriesMeta.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in metadata for screen 14, until the Screen domain exists.

  The drawing's own copy: three ratings from three sources, four cast members
  with their character names, three ways to watch — one of which is the user's
  own shelf — and four tags the user wrote.

  ## The star

  The drawing writes your own rating as `&starf; 4.5` — a U+2605 glyph followed
  by the number. Plus Jakarta Sans does not carry U+2605; screen 08 proved that
  the hard way, where five text stars rendered as nothing at all and read as a
  layout bug. So `star?` asks for the Material Symbols glyph instead and the
  value stays plain text. The mark is the same mark; only the font that draws
  it changed.

  ## Where to watch

  `Your shelf` carries `owned` where the others carry a price, and Lumen+
  carries nothing at all — the drawing leaves that cell empty because
  "included" already said it in the line above. `nil` rather than `""`, so the
  screen can drop the node instead of laying out an empty one.

  ## Both scripts

  mishka-group/kati#103. Board 14 is drawn from this module in English and in
  Persian now — there is no mirror — so every word here is a msgid and every
  figure goes through `Kati.Locale`. Four kinds of string deliberately do not:

    * **A service's own name.** `Lumen+` and `Kino` stay Latin on a Persian page
      for the reason board 127 draws all three of its services that way: a real
      row takes its name off `Kati.Services.Service`, no msgid reaches it, and a
      fixture that transliterated would spell one service two ways in one app.
      `Kino` is passed as a BINDING rather than written into a msgid, which is
      what makes that structural rather than a request — `Kati.Library.Sample`
      wrote `LUMEN+` into its own meta msgid and the catalogue promptly answered
      لومن‌پلاس, so screen 03 and board 127 now disagree about one service.
    * **A price.** `£14.99` keeps its sterling sign and its Latin digits because
      `Kati.Screens.SeriesMeta.price/1` sets that cell in DM Mono and says why.
    * **A seed.** `hollow71` and `face26` are file names.
    * **`more` and `trailer`.** Neither is drawn any more; both are read as the
      presence of a thing. See `series/0`.

  Everything else is the drawing's copy and translates — the cast included. A
  fixture's PEOPLE are transliterated rather than left Latin, which is the rule
  `Kati.Calendar.SampleEvent.invitees/0` writes out: what keeps `TMDB` and
  `Lumen+` in Latin is a name that can be spelled two ways in one app, and
  nothing reaches this list but the drawing. Three of the four are already in
  the catalogue, so the app spells each of them once.

  The four tags translate too, and that is the one call here worth stating.
  They read as words a user wrote, which is the class
  `Kati.Screens.SearchIdle.drawn_recent/0` refuses to translate — *they are your
  words*. The difference is that 86's five queries stand in for a real store
  (`Kati.Search.Recent.all/0`) and these stand in for nothing: no column holds a
  tag against a `Kati.Media.TrackedTitle`, so `Kati.Screens.SeriesMeta.shaped/2`
  answers `[]` and these four are the drawing's own copy on every device that
  will ever render them. Four Latin chips under برچسب‌های شما is a page that
  reads as broken.
  """

  @doc "Everything screen 14 draws."
  @spec series() :: map()
  def series do
    %{
      title: gettext("The Long Hollow"),
      seed: "hollow71",
      meta: meta_line(),
      ratings: ratings(),
      synopsis:
        gettext(
          "A tidal surveyor returns to the estuary village she left at seventeen, " <>
            "and finds the water has been keeping records of its own."
        ),
      # Both of these are flags wearing the word they used to be. `more_link/1`
      # and `actions/1` read them as the PRESENCE of an expander and of a
      # trailer and own the copy they draw — a msgid has to be a literal at the
      # call site, so `gettext(label)` never compiled and the screen took the
      # words. Translating them here would put two msgids in the catalogue that
      # nothing ever asks for, and the first reader to change one would change
      # nothing at all.
      more: "more",
      trailer: "Trailer",
      cast: cast(),
      where: where(),
      tags: tags(),
      # Screen 33's own msgid, context and all: `Kati.Screens.Rating.add_tag/1`
      # draws the identical chip out of the identical `MishkaPill` and the
      # catalogue already answers `+ برچسب`. The `+` stays inside the msgid
      # rather than being prefixed to a translated word, in 33's words: it is
      # part of the affordance's name, and which side of the word it sits on is
      # the bidi algorithm's answer rather than this file's — `+ برچسب` puts it
      # at the start of the line, which under `rtl` is the right-hand edge,
      # exactly where the Latin chip has it.
      add_tag: pgettext("the chip that opens the tag field", "+ tag")
    }
  end

  # `2024 · 15 · DRAMA, MYSTERY · 3 SEASONS · 26 EP`, built the way
  # `Kati.Screens.SeriesMeta.meta_line/1` builds a real title's — the same
  # msgids, the same interpunct join — so the board and a tracked series say the
  # identical thing in the identical words. Five parts here rather than four,
  # because the drawing carries a certification and no column holds one.
  #
  # Every part that is a WORD goes through `Kati.UI.eyebrow_label/1` and not
  # `String.upcase/1`: the upper case is the drawing's in Latin only, Persian
  # has no case, and upcasing it is a no-op that still reads as a decision
  # somebody made.
  #
  # The year converts its DIGITS and never its calendar — `Kati.Locale.year/1`'s
  # rule and board 69's: a first-air year is a fact about the broadcast
  # calendar, so `2024` is `۲۰۲۴` and not `۱۴۰۳`. The `15` is an age in years
  # and is read as a number rather than as a code, so it takes the reader's
  # digits the same way.
  #
  # The genres are ONE msgid and not two joined with a comma, because the comma
  # is the part that changes: Persian separates a list with `،` (U+060C), and a
  # translator who is handed the whole run writes it without being asked.
  defp meta_line do
    [
      Kati.Locale.year(2024),
      Kati.Locale.number(15),
      Kati.UI.eyebrow_label(gettext("Drama, Mystery")),
      Kati.UI.eyebrow_label(seasons_label(3)),
      Kati.UI.eyebrow_label(episodes_label(26))
    ]
    |> Enum.join(" · ")
  end

  # Screen 04's and screen 14's own two msgids, asked for here rather than
  # written again: `Kati.Screens.SeriesMeta.meta_line/1` draws the identical
  # clause over a real series and one word for it is the whole point of a
  # catalogue. Persian does not inflect a noun after a numeral, so both plural
  # forms are `%{n} فصل`.
  defp seasons_label(n),
    do: ngettext("%{n} season", "%{n} seasons", n, n: Kati.Locale.number(n))

  # `26 EP` is invariant on the board — no `EPS` at any count — so this is the
  # `pgettext/2` the real line already uses and not an `ngettext/3` inventing an
  # English plural the drawing does not draw.
  defp episodes_label(n),
    do: pgettext("series meta line", "%{n} ep", n: Kati.Locale.number(n))

  # `Yours` is the trio's first word on both pages: `Kati.Screens.SeriesMeta.
  # yours/2` asks for the same msgid over a real series, so the board and the
  # reader's own trio name that column identically. `Audience` and `Critics` are
  # the board's alone — board 311 replaced them with `Episodes` and `Hours` the
  # moment there is a reader to compute for — so their msgids are new here.
  #
  # The VALUES stay bare figures. `rating_card/1` puts every one of them through
  # `Kati.Locale.number/1` at the draw, which is the one place the board's trio
  # and the reader's own trio both arrive, and doing it twice would be doing it
  # in two places. `96%` is the exception and needs a msgid: the per-cent sign is
  # punctuation Persian writes as `٪` (U+066A), and `number/1` converts digits
  # and the decimal point and nothing else. `%{n}%` is the catalogue's own —
  # `Kati.Stats.Sample` and screen 61 already ask for it.
  defp ratings do
    [
      %{label: gettext("Yours"), value: "4.5", color: 0xFFE8823C, star?: true},
      %{label: gettext("Audience"), value: "8.1", color: 0xFF1A1917, star?: false},
      %{
        label: gettext("Critics"),
        value: gettext("%{n}%", n: Kati.Locale.number(96)),
        color: 0xFF4E9A73,
        star?: false
      }
    ]
  end

  # `Ines Karvel`, `Tomas Rhee` and `Ada Vance` are already in the catalogue —
  # screen 20's shelf, screen 66's invitee list and the discover rail wrote
  # them — so these rows ask for those msgids rather than opening a second
  # spelling of the same person.
  #
  # `The Warden` is `Kati.Books.Sample`'s msgid, deliberately: a warden is a
  # warden, board 20 draws the words as a book's title and board 14 draws them
  # as a character's name, and one Persian word for one English word is what a
  # catalogue is for.
  #
  # Plain `gettext/1` on all eight and not `pgettext/2`, even for the four-letter
  # ones. A proper noun is not the fuzzy-match hazard a four-letter LABEL is —
  # `mix gettext.merge` matches a short msgid against a sentence that contains
  # it, and no sentence in this app contains `Bryn` — and the catalogue already
  # holds `Jo`, `Marram` and `Ashfall` as bare msgids for the same reason.
  defp cast do
    [
      %{name: gettext("Ines Karvel"), role: gettext("Mara"), seed: "face26"},
      %{name: gettext("Tomas Rhee"), role: gettext("Bryn"), seed: "face14"},
      %{name: gettext("Ada Vance"), role: gettext("Sister Ill"), seed: "face45"},
      %{name: gettext("Ola Beck"), role: gettext("The Warden"), seed: "face58"}
    ]
  end

  # The three ways the board can be watched. Every `line` reuses the availability
  # vocabulary `Kati.Screens.SeriesMeta.where_rows/1` already built — `included`
  # under the `where to watch` context — rather than restating it, so the board
  # and a real TMDB answer use one word for one offer.
  #
  # Every msgid on this card takes that same context. They are one and two words
  # long, and `mix gettext.merge` fuzzy-matches a msgid that short against any
  # sentence that happens to contain it: *buy* and *owned* are in a dozen.
  defp where do
    [
      %{
        # `L` is `Lumen+`'s own initial and stays a Latin capital, which is the
        # rule `where_rows/1` states for a real row's badge: it is the first
        # letter of a NAME, not an eyebrow whose case is a Latin convention.
        #
        # `Kati.Locale.ltr/1` on the name because the `+` is a bidi NEUTRAL. On
        # an RTL page the algorithm resolves it against the paragraph rather
        # than against the word, and lays it out at the other end — the row
        # reads `+Lumen`, which is the failure screen 83's licence notices had
        # with their full stops.
        badge: "L",
        name: Kati.Locale.ltr("Lumen+"),
        line:
          pgettext("where to watch", "%{line} · 4K HDR",
            line: pgettext("where to watch", "included")
          ),
        price: nil
      },
      %{
        badge: "K",
        # `Kino` arrives as a BINDING and is therefore not inside a msgid at
        # all, which is the only way a service's name is actually kept: a name
        # a translator cannot reach cannot drift. `store` is this page's own
        # word for what the row is and translates.
        name: pgettext("where to watch", "%{name} store", name: "Kino"),
        line: pgettext("where to watch", "buy season"),
        # Latin in both scripts, and `Kati.Screens.SeriesMeta.price/1` is where
        # the argument is: the drawing sets this cell in DM Mono, DM Mono has
        # the sterling sign, and a figure in mono keeps Latin digits because
        # `kati_mono.ttf` carries none of U+06F0–U+06F9. The screen wraps it in
        # `Kati.Locale.ltr/1` for the `£`, which is a neutral like the `+` above.
        price: "£14.99"
      },
      %{
        # `D` is for *disc*, and it is the one badge on this card that is NOT a
        # service's initial — the row is the reader's own shelf and there is no
        # provider behind it, which is why the drawing had to pick a letter at
        # all. So it is an English word's first letter on a Persian page rather
        # than a name, and it takes the first letter of دیسک.
        badge: pgettext("your shelf badge", "D"),
        name: gettext("Your shelf"),
        # `Blu-ray` is a format's brand name and stays Latin, as a binding, for
        # `Kino`'s reason; the season range is Kati's and translates. `S1–S2` is
        # what the drawing writes and the English line still writes it, so the
        # Latin page is untouched and only the Persian one gains the word فصل.
        line:
          pgettext("where to watch", "%{format}, S%{first}–S%{last}",
            format: Kati.Locale.ltr("Blu-ray"),
            first: Kati.Locale.number(1),
            last: Kati.Locale.number(2)
          ),
        # A WORD in the price cell rather than a figure, and the one string on
        # this page whose face is wrong once it is translated — see the note in
        # `Kati.Screens.SeriesMeta.price/1`, which hard-codes `mono` because the
        # only two values it had ever drawn were this and `£14.99`. It is
        # translated anyway: *owned* is copy a Persian reader has to read, and a
        # typeface is a one-line fix where a missing msgid is not.
        price: pgettext("where to watch", "owned")
      }
    ]
  end

  # `Jo` comes through as a binding and is the catalogue's own msgid — board
  # 66's invitee is جو and this is the same friend to a reader who meets them on
  # two boards. `pgettext/2` on all four: each is one or two words, which is
  # exactly the length `mix gettext.merge` fuzzy-matches against any sentence
  # that happens to contain it.
  defp tags do
    [
      pgettext("series tag", "slow burn"),
      pgettext("series tag", "coastal"),
      pgettext("series tag", "watch with %{name}", name: gettext("Jo")),
      pgettext("series tag", "rewatchable")
    ]
  end
end
