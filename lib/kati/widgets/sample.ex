defmodule Kati.Widgets.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in data for the off-app surfaces screen 39 draws.

  Widgets, voice shortcuts and the share extension all read the same three
  facts the app already knows — what is next, what airs tonight, how long the
  streak is — so this module supplies them in one shape rather than three. The
  values are the design's own, from `test/design/screens/39.html`.

  The shortcut rows carry `toggle` only when the drawing gives them a switch;
  the row without one gets a chevron instead, which is how the screen tells
  "this is on or off" apart from "this opens somewhere else".

  ## Where the words come from

  mishka-group/kati#103 folded the 33 Persian mirrors away, so board 39 is
  `Kati.Screens.Widgets` under `:en` and under `:fa`, and every word this
  module writes is drawn on both. That screen's moduledoc draws the line and
  this side keeps it: **the screen owns the chrome and this module owns the
  drawing** — one msgid per string, wherever the string lives, because
  `gettext/1` needs a literal at the call site and what the screen holds is a
  map key. `Kati.Settings.DetectSample` stands in the same place for board 36.

  Every msgid below is byte-identical to the literal it replaces, so nothing
  about the English render moves.

  What this module does NOT do is typeset. The faces, the tracking, the
  leading and the forward chevron are `Kati.Screens.Widgets`'s, and so are two
  conversions it would otherwise be handed twice:
  `Kati.Screens.Widgets.count_tile/5` puts both tile counts through
  `Kati.Locale.number/1` and `Kati.Screens.Widgets.wide_event/1` does the same
  to both clocks. So `6`, `11`, `20:00` and `21:30` stay Latin **here** and
  still reach a Persian reader as ۶، ۱۱، ۲۰:۰۰ and ۲۱:۳۰ — converting them on
  this side would hand that screen a string to convert a second time. The one
  figure the screen never sees is the six inside *6 episodes air*: that is a
  numeral inside a sentence rather than a value of its own, and it is
  converted where it is written.

  ## What stays Latin

  `seed` is a file name rather than a word — `Kati.Design.Images.poster/1`
  looks the picture up by `hollow71` — and a translated file name finds no
  file. The `icon` values are Material Symbols ligatures, which are a font's
  names for its own glyphs.

  *Kati* itself is the one name that reads two ways in this app, and the share
  card is prose: the mark stays Latin wherever it IS the mark, while the
  catalogue writes کاتی in every sentence that has the app as its subject. The card's note is such a sentence
  and its title sits two lines above it, so both say کاتی — a card that spelt
  the name one way in its heading and another in its paragraph would be the
  drift the rule is there to prevent.
  """

  # Six is one fact rather than two that agree today: it is what the TONIGHT
  # tile counts and what the wide widget's 20:00 row names, which is the
  # export's own caption — *four widget sizes off one data model*.
  #
  # Integers, and deliberately not msgids: `gettext/1` inside a module
  # attribute is evaluated while the file compiles and freezes into whichever
  # locale the compiler happened to be in. Every word below is written in a
  # function for that reason.
  @airing 6
  @nights 11

  @doc "Everything screen 39 shows, in the order it shows it."
  @spec widgets() :: map()
  # The four widget captions — `UP NEXT`, `TONIGHT`, `STREAK`, `TODAY · WIDE`.
  #
  # They are capitals in the drawing's own copy rather than a `text-transform`
  # — screen 39's moduledoc says so — which is why the capitals are in the
  # msgid and why nothing upcases them on the way out. Persian has no case to
  # raise and simply says the word.
  #
  # `pgettext/2` on all four: each is under three words, and `mix
  # gettext.merge` fuzzy-matches a msgid that short against any sentence it
  # resembles — the catalogue holds `Tomorrow — needs prep tonight` and `13
  # What fits tonight` for `TONIGHT` alone. The context names the surface.
  #
  # The Persian is بعدی and امشب, the words board 29's lock-screen widgets
  # used for the same two captions (29 is deleted; its board is retired), so
  # the widget family keeps one vocabulary.
  def widgets do
    %{
      up_next: %{
        label: pgettext("a home-screen widget's own name", "UP NEXT"),
        # An invented series the app already names in both scripts:
        # `Kati.Library.Sample` puts this exact msgid on the same show,
        # گودال بلند. The board writes it without the article —
        # 113pt beside a poster — and the catalogue holds that spelling too.
        title: gettext("Long Hollow"),
        # `S2E6` is the app's bookmark rather than this board's string, and the
        # app writes it ف۲ق۶ — the initials of فصل and قسمت — on an activity
        # row. A Latin `S2E6` here would be one bookmark spelt two ways in one
        # app.
        #
        # `pgettext/3` because `S%{s}E%{e}` is eight characters, far under the length
        # `mix gettext.merge` stops fuzzy-matching at, and the catalogue already
        # holds four spellings of this same bookmark for it to match against.
        # The context is what keeps this entry the home screen's own — the
        # catalogue holds one bookmark per surface here, not one shared entry,
        # which is how the activity row's already sits. A fuzzy pre-fill from
        # a byte-identical msgid under another context is ف%{s}ق%{e} — the
        # right answer, wearing a flag somebody has to clear.
        #
        # `Kati.Screens.Widgets.up_next_tile/1` asks `Kati.Locale.mono_face/1`
        # about this string rather than about the reader, so the Latin form
        # stays in DM Mono and the Persian one is set in Vazirmatn — DM Mono
        # carries no glyph in U+0600–U+06FF at all.
        episode:
          pgettext("the episode bookmark on the home screen's Up next widget", "S%{s}E%{e}",
            s: Kati.Locale.number(2),
            e: Kati.Locale.number(6)
          ),
        seed: "hollow71"
      },
      tonight: %{
        label: pgettext("a home-screen widget's own name", "TONIGHT"),
        # Latin here on purpose — `Kati.Screens.Widgets.count_tile/5` converts
        # it. See the moduledoc.
        count: Integer.to_string(@airing),
        # One plural entry, قسمت در حال پخش under the figure. The plural form
        # is the one the board's six selects.
        line: ngettext("episode airing", "episodes airing", @airing)
      },
      streak: %{
        label: pgettext("a home-screen widget's own name", "STREAK"),
        count: Integer.to_string(@nights),
        # Plural in the msgid rather than `ngettext/3`: this line is the
        # drawing's, its eleven is the drawing's, and nothing
        # varies it — a plural form nothing could ever select is a form to
        # translate for nothing. It becomes an `ngettext/3` the day a habit
        # completion exists to count, which is the move screen 39's moduledoc
        # already names for this tile.
        #
        # `pgettext/2` and not `gettext/1` because what is left is one word.
        # `mix gettext.merge` measures a new msgid against every old one by
        # Jaro distance and `Gettext.Fuzzy` ignores the context while it does,
        # so a context cannot stop the pre-fill this will get — `nights` sits
        # at 0.82 from `eight`, `Units` and `Light`, and a fuzzy msgstr is
        # compiled and shipped like any other. What the context does is make
        # the entry this board's own, so the one word cannot be quietly joined
        # to another screen's `nights`, and name the job it does so a reviewer
        # can see the pre-fill is wrong before it ships.
        line: pgettext("the line under a home-screen widget's count", "nights")
      },
      today_label: pgettext("a home-screen widget's own name", "TODAY · WIDE"),
      today: [
        # The six is this row's own numeral rather than a value the screen is
        # handed, so `Kati.Screens.Widgets.wide_event/1` — which converts the
        # clock beside it — never sees this one, and it is converted here:
        # ۶ قسمت پخش می‌شود. One msgid with the count as a binding, the
        # catalogue's own.
        %{
          time: "20:00",
          title: gettext("%{n} episodes air", n: Kati.Locale.number(@airing)),
          color: 0xFFE8823C
        },
        # The evening's second row; the catalogue already holds it:
        # تماس با مامان.
        %{time: "21:30", title: gettext("Call Mum"), color: 0xFFC4BDB3}
      ],
      shortcuts: shortcuts(),
      share: share()
    }
  end

  @doc """
  Three voice shortcuts and the automations row.

  The quotes are the phrases as spoken, which is why they are drawn in
  quotation marks — the row is the sentence, not a setting name.

  The marks themselves are `Kati.Locale.quoted/1`'s rather than typed into the
  string, which is the fold `Kati.Screens.Widgets.shortcut_row/3` asks for: a
  Persian reader meets `“…”` as a foreign mark and is given the guillemets,
  «…», that board 69 writes. The English side is unchanged — the same function
  answers U+201C/U+201D there — and a translator is handed the sentence rather
  than its punctuation.

  The three phrases are commands addressed to an assistant, so the Persian
  puts them in the singular imperative — اضافه کن, علامت بزن — where the rest
  of the app addresses the reader as شما. That is what their `pgettext/2`
  context carries: with no context a translator is handed *Mark it watched*
  beside the app's own *Mark watched* and writes the polite plural the rest of
  the catalogue uses, and the row stops being something anybody says out loud.
  The line under each phrase is the app describing itself and keeps the app's
  own voice, so those stay bare.

  *Siri* is transliterated rather than kept Latin, which is what this
  catalogue does with a platform's name everywhere else: اندروید, آی‌کلاد,
  آی‌پد. The Latin rule is for a service name that comes off
  `Kati.Services.Service` with no msgid to reach it, and none of these three
  is one — there is no voice layer in `lib/` at all, so the row describes a
  surface rather than naming a provider.
  """
  @spec shortcuts() :: [map()]
  def shortcuts do
    [
      %{
        icon: "mic",
        title:
          Kati.Locale.quoted(pgettext("a voice shortcut, as spoken", "Hey Siri, what’s next?")),
        sub: gettext("Reads your next episode"),
        toggle: true
      },
      %{
        icon: "play_arrow",
        title: Kati.Locale.quoted(pgettext("a voice shortcut, as spoken", "Mark it watched")),
        sub: gettext("Ticks whatever is in progress"),
        toggle: true
      },
      %{
        icon: "add",
        title: Kati.Locale.quoted(pgettext("a voice shortcut, as spoken", "Add to my list")),
        sub: gettext("Adds a title by name"),
        toggle: true
      },
      # No quotes on this one: it is a setting's name rather than a phrase
      # somebody says, which is the same fact `Kati.Screens.Widgets.trailing/1`
      # reads off the missing `toggle` to give the row a chevron.
      %{
        icon: "bolt",
        title: gettext("Automations"),
        sub: gettext("Run a shortcut when a season ends")
      }
    ]
  end

  @doc """
  The share extension, described in the app rather than in the App Store.

  The note is the one paragraph on board 39, and once it is folded it is a
  Persian sentence, its full stop included — which is exactly the state
  `Kati.Screens.Widgets.share/1` says must NOT then be wrapped in
  `Kati.Locale.ltr/1`: there is no Latin run left inside it to isolate, and
  isolating the whole paragraph would pin a Persian sentence to LTR. Until
  this fold that period sat at the left edge, which is the symptom that doc
  names on screen 83.
  """
  @spec share() :: map()
  def share do
    %{
      title: gettext("Save to Kati"),
      sub: gettext("from any app, link or screenshot"),
      note:
        gettext(
          "Share a trailer, a review link or a photo of a cinema listing — " <>
            "Kati reads the title out of it and files it on your wishlist."
        )
    }
  end
end
