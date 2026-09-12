defmodule Kati.Settings.DetectMusicSample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in auto-detect state, screen 150 — Auto-detect in music mode.

  `Kati.Settings.DetectSample` is screen 36's TV & film state and this is its
  music sibling, not a variant of it: the two boards share nothing but a
  subtitle line. TV counts episodes ticked at a watched fraction; music
  scrobbles at a fraction OR a floor (`50% or 4 min`, so a two-minute single
  and a nine-minute post-rock track both still count), matches an app by its
  media-session notification rather than by a connected box, and disambiguates
  by which release rather than which title. Sharing a Sample module would have
  meant one of the two domains borrowing the other's shape.

  ## Why this is Sample and not a resource, same as screen 36

  Detection has not been built for either domain. Specifically missing for
  music:

    * **A per-app allow-list.** `apps/0`'s four rows have nowhere to persist
      an on/off — there is no table naming Spotify, YouTube Music, Poweramp or
      "everything else" as sources, let alone one Kati has toggled.

    * **A now-playing session.** Same gap `Kati.Screens.AutoDetect`'s own
      moduledoc records for TV: `Kati.Media.Watch` ticks after a play
      finishes, never while one is running, and nothing else holds a session
      in flight. Music needs this even more urgently than TV does, because
      the elapsed time the bar draws — `1:58 / 4:12` — is read off a media
      session that updates every second, not off a row written once.

    * **The rules themselves.** `30 seconds` minimum length, repeats counting
      individually, speaker plays counting, a 45%-skip not counting — four
      numbers with no column to live in.

    * **The ambiguity queue.** The same "unsure match becomes a question"
      argument screen 36 makes for `decision/0`, transposed to records rather
      than episodes: `Kati.Music.Album` is not yet keyed by release the way a
      queued match would need — "the studio album, a live record and a
      compilation" are three different rows sharing one track title, and nothing
      resolves a play to one of the three today.

  Every value below is therefore written by hand rather than queried, exactly
  as `Kati.Settings.DetectSample` does for TV, and for the same reason: this is
  a screen that has been drawn, not a feature that has been built.

  ## Which half of board 150's copy this module owns

  mishka-group/kati#103 folded the 33 Persian mirrors away, and
  `Kati.Screens.AutoDetectMusic`'s moduledoc names this module as the other
  half of the board's words: **the screen owns its chrome and this owns the
  state** — the subtitle's three counts, the now-playing track with its artist
  and album, the `Live` pill, the scrobble rule, the `With art` eyebrow and its
  caption, the four app names and their reasons, the four rule names and
  theirs, and the queued question with its three releases. That paragraph was
  written while all of them were still English literals and it says what they
  should read like when their turn came — `Kati.Locale.number/1` on the `4:12`
  and `gettext("Low Water")` on the track. This is that turn.

  The track, the artist and the album are the SAME msgids `Kati.Music.Sample`
  already put in the catalogue. Board 76 calls the album **کارهای جزر و مد**
  and this card cannot call it something else; two spellings of one record is
  how a catalogue starts disagreeing with itself, which is the argument
  `Kati.Screens.AutoDetectMusic.apps_note/0` already makes for sharing
  `Everything else` with board 33.

  ## What stays Latin, and why each one does

    * **Spotify, YouTube Music and Poweramp.** These are the names the apps
      call themselves, the rule board 127 draws `Lumen+` in Latin on a Persian
      page for and the one `Kati.Screens.AutoDetect.app_name/1` states at
      length: a transliteration would spell one thing two ways across the app.
      They are pure ASCII, so `Kati.Locale.mono_face/1` keeps their tile
      letters in DM Mono in both scripts. **Everything else** is not a brand
      and is translated, which is why only its tile letter is derived — see
      `apps/0`.

    * **`albm1` and `albm2`** are the file names of shipped artwork
      (`priv/sample/design/albm1_400x400.jpg`), read by
      `Kati.Design.Images.poster/1`. A seed is an identifier, not a word.

    * **`timer`, `repeat`, `cast`, `call_split`** are Material Symbols glyph
      names. None of these four rows opens anything, so there is no
      `chevron_right` here for `Kati.Locale.forward_chevron/0` to answer.

    * **`1:58 / 4:12`.** The one figure on this card that is NOT converted.
      `Kati.Screens.AutoDetect.now_playing/1`'s comment names board 150 by
      number for it: the elapsed clock is the one run both boards keep in DM
      Mono in both scripts, and `kati_mono.ttf` carries none of U+06F0–U+06F9,
      so Persian digits here would push it into Android's own substitute face.
      `Kati.Locale.number/1`'s own doc draws the same line — a figure the
      design sets in DM Mono keeps Latin digits, and conversion is for the
      numerals inside a sentence. See `now_playing/0` for the bidi consequence
      that leaves behind and for whose line it is to fix.

  Everything else on the board is a msgid and every remaining figure goes
  through `Kati.Locale`.
  """

  @doc """
  The mono line under the title. Counts both modes at once — it does not change
  with the tab.

  ## Why the digits convert here and not on the elapsed clock

  `Kati.UI.SettingsList.subtitle/2` sets this line in `Kati.Locale.mono_face/0`
  — the READER's face, asked with no argument — so under `:fa` it is Vazirmatn
  whatever it happens to hold. That is the opposite of the elapsed clock, whose
  face is asked of the STRING and stays in DM Mono for it. Persian numerals
  belong in a Vazirmatn line and would be empty boxes in a DM Mono one, so the
  same three counts would have been answered two different ways depending on
  which slot they landed in. This is the slot that converts.

  ## Three counts, three `ngettext/4` calls, one frozen line

  Not one `3 SOURCES · 41 EPISODES, 128 TRACKS` msgid. `%{n} episode` and
  `%{n} track` are already in the catalogue — screen 36's ticked line put the
  first there and `Kati.Music.Sample` the second — and a whole-line msgid would
  have spelled a قسمت and an آهنگ a second way. Persian does not inflect a noun
  after a numeral, so each pair is one word there and two here, which is the
  whole of what a plural entry is for.

  The joins stay outside the msgids, the shape
  `Kati.Screens.AutoDetectMusic.apps_note/0` uses for its own three runs: a
  msgid with a trailing separator is one a translator loses without noticing.
  The `·` is the same glyph in both scripts; the COMMA is not — Persian writes
  it `،` — so it goes through `Kati.Locale.pick/2` the way screens 128 and 132
  already write theirs.

  The caps are `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`, because
  Arabic script has no case and upcasing Persian is a no-op that still reads,
  in a diff, as a decision somebody made.
  """
  @spec subtitle() :: String.t()
  def subtitle do
    sources = ngettext("%{n} source", "%{n} sources", 3, n: Kati.Locale.number(3))
    episodes = ngettext("%{n} episode", "%{n} episodes", 41, n: Kati.Locale.number(41))
    tracks = ngettext("%{n} track", "%{n} tracks", 128, n: Kati.Locale.number(128))

    line = sources <> " · " <> episodes <> Kati.Locale.pick(", ", "، ") <> tracks

    Kati.UI.eyebrow_label(line)
  end

  @doc """
  What is playing, how far in, and when it will scrobble — the no-art state.

  No-art is the state the board draws first and gives the full card to,
  because a media-session notification carries artwork only when the app
  bothers to attach it, and most of the ones this list names do not always.
  `with_art/0` is the one demonstrating the alternative, not the other way
  round.

  ## The track is board 76's track

  `Low Water` is the opening track of `Tidal Works` by `Kell Ostrand`, which is
  exactly what `Kati.Music.Sample.album/0` and its tracklist already hold, so
  all three take the msgids that module put in the catalogue rather than three
  new ones of this card's. The card and the album page now cannot disagree
  about what the record is called.

  `meta` is joined and then upcased here rather than in the screen, the same
  order `Kati.Screens.AutoDetect.session_meta/1` uses: the board sets the line
  in caps, `Kati.UI.eyebrow_label/1` upcases in Latin and hands Persian back
  untouched, and `Kati.Screens.AutoDetectMusic.now_playing/1` then asks the
  finished string which face it needs.

  ## `1:58 / 4:12` is left alone, and that is not finished business of this file

  The elapsed clock keeps Latin digits — see the moduledoc — but it is also two
  number runs with a neutral ` / ` between them, and a neutral that is not
  directly between two numbers takes the PARAGRAPH's direction rather than
  theirs. Under `:fa` the page is RTL, so the pair lays out `4:12 / 1:58`: the
  elapsed and the duration swapped, contradicting the bar drawn above them.
  `Kati.Screens.AutoDetect.now_playing/1` meets the identical string and fixes
  it at the point of drawing — `Kati.Locale.ltr/1` around the text, the face
  asked of the RAW string so the isolate's U+2066 cannot push a Latin clock out
  of DM Mono. `Kati.Screens.AutoDetectMusic.now_playing/1` draws it with no
  isolate at all.

  Isolating it HERE would fix the order and break the face, because that
  function asks `mono_face/1` about whatever string it is handed and U+2066 is
  not ASCII. So the string stays as the board draws it and the one-line fix
  belongs in the screen, beside the comment on 36 that already explains it.
  """
  @spec now_playing() :: map()
  def now_playing do
    %{
      title: gettext("Low Water"),
      meta: Kati.UI.eyebrow_label(gettext("Kell Ostrand") <> " · " <> gettext("Tidal Works")),
      # The same msgid AND the same context screen 36's live session uses, so
      # the two boards' pills cannot say different words for one state. A bare
      # `Live` would also be fuzzy-matched by `mix gettext.merge` against any
      # longer entry containing it — the catalogue already holds three `Live`
      # entries, for a media session, an account sync and a permission, and a
      # media session is the first of them.
      status: pgettext("now playing pill", "Live"),
      progress: 0.47,
      elapsed: "1:58 / 4:12",
      # `%{n} min` nested rather than a second `min` inside this msgid.
      # `Kati.Music.Sample.album/0` nests `%{n}h` inside `%{hours} listened`
      # for the same reason: a unit spelled in two entries is a unit that gets
      # translated two ways.
      rule:
        gettext("scrobbles at %{percent}% or %{floor}",
          percent: Kati.Locale.number(50),
          floor: gettext("%{n} min", n: Kati.Locale.number(4))
        )
    }
  end

  @doc """
  The compact second card: what a now-playing row looks like when the session
  does carry art.

  `eyebrow` is written in sentence case and left that way.
  `Kati.Screens.AutoDetectMusic.with_art/1` upcases it itself — it needs the
  finished label anyway, to ask `Kati.Locale.mono_face/1` and
  `Kati.Locale.tracking/1` about the same string it draws — and upcasing it
  twice is how the text and the face start disagreeing about which string they
  are.

  **تصویر جلد** and not a new word for artwork: it is what the screen's own
  `Now playing — no art, the common case` eyebrow already calls it.
  """
  @spec with_art() :: map()
  def with_art do
    %{
      seed: "albm1",
      eyebrow: gettext("With art"),
      caption: gettext("When the media session carries it")
    }
  end

  @doc """
  The four rows of `Which apps` — three named exceptions and the catch-all
  under them, on by default for the three Kati has actually seen.

  ## Three frozen letters and one derived one

  `S`, `Y` and `P` are the first characters of brands that stay Latin in both
  scripts, so they are written out. The fourth is not: **Everything else** is
  translated, and a frozen `E` beside **بقیه** is a letter from a word that is
  no longer on the row — `Kati.Screens.AutoDetectMusic.app_tile/1`'s doc names
  this case exactly, and `Kati.Music.Sample.album/0` takes its tile letter off
  its own translated title for the same reason board 76 draws **ک**.

  `Everything else` is the catch-all `Kati.Stats.Sample.year/0` names on board
  33 and `Kati.Screens.AutoDetectMusic.apps_note/0` bolds in its footnote. One
  msgid for all three, so the row, the sentence about the row and the
  breakdown cannot each invent a word.
  """
  @spec apps() :: [map()]
  def apps do
    # Bound once so the tile letter and the row title are the same string in
    # every locale, rather than two `gettext/1` calls that a locale change
    # between them could separate.
    everything_else = gettext("Everything else")

    [
      %{
        initial: "S",
        title: "Spotify",
        sub: gettext("Reads track, artist and album from its notification"),
        on: true
      },
      %{
        initial: "Y",
        title: "YouTube Music",
        sub: gettext("Same, and ignores anything under %{n} seconds", n: Kati.Locale.number(30)),
        on: true
      },
      %{initial: "P", title: "Poweramp", sub: gettext("Reads local file tags"), on: false},
      %{
        initial: String.first(everything_else),
        title: everything_else,
        sub: gettext("Any app that posts a media notification"),
        on: false
      }
    ]
  end

  @doc """
  Music's four rules — a floor, two things that still count, one that does not.

  ## `30s` keeps its abbreviation and loses its letter

  The board draws the floor twice on one row: `30 seconds` spelled out in the
  sub-line and `30s` in the trailing mono slot. The contrast is the point — the
  value is the setting and the sub-line is what it means — so the Persian keeps
  it, with **ث** where the board has `s`. Spelling the trailing slot
  **۳۰ ثانیه** as well would draw the identical run twice on one row, which
  reads as a bug rather than as a value beside its explanation.

  `pgettext/2` for it because `%{n}s` is one character of copy and
  `mix gettext.merge` fuzzy-matches a msgid that short against any longer entry
  that resembles it. The context says which row's value it is.

  `%{n}%` interpolated in the fourth rule's title rather than frozen into the
  msgid: `45` is a numeral inside a sentence, which is precisely what
  `Kati.Locale.number/1` is for, and the row is drawn in the reader's own face
  by `Kati.UI.SettingsList.body/3`.
  """
  @spec rules() :: [map()]
  def rules do
    [
      %{
        icon: "timer",
        title: gettext("Minimum track length"),
        sub: ngettext("%{n} second", "%{n} seconds", 30, n: Kati.Locale.number(30)),
        control: {:value, pgettext("minimum track length", "%{n}s", n: Kati.Locale.number(30))}
      },
      %{
        icon: "repeat",
        title: gettext("Repeats in one session"),
        sub: gettext("Each play counts"),
        control: {:switch, true}
      },
      %{
        icon: "cast",
        title: gettext("Scrobble without headphones"),
        sub: gettext("Speaker plays count too"),
        control: {:switch, true}
      },
      %{
        icon: "call_split",
        title: gettext("A track skipped at %{n}%", n: Kati.Locale.number(45)),
        sub: gettext("Under the threshold — not counted"),
        control: :none
      }
    ]
  end

  @doc """
  The queued question: one track, three releases, and Kati will not guess which
  one played.

  ## The quotation marks are the reader's, not the drawing's

  `Kati.Locale.quoted/1` rather than the `“…”` the board types. A Persian
  reader meets curly doubles as a foreign mark and board 69 writes its own
  quotation with the guillemets — `«آب کم»`. The title inside them is
  `Kati.Music.Sample`'s msgid, so the question and the tracklist name one
  track.

  ## `chosen` is bound to the option, not spelled beside it

  `Kati.Screens.AutoDetectMusic.decision/1` decides which pill is filled with
  `o == d.chosen`, so the chosen release and the option it matches have to be
  the same string in every language. Binding the `gettext/1` call once and
  using it twice makes that structural instead of a coincidence of two calls
  agreeing.

  This is only safe because nothing here turns a LABEL into a TAG.
  `Kati.Screens.AutoDetect.answer_tag/1` is the counter-example and its doc is
  the full account: under `:fa` it mints an atom per label per language that no
  `handle_tap/2` clause matches. Board 150's pills carry no tap at all —
  `Kati.Screens.AutoDetectMusic.choice/2` draws a `MishkaToggle` with no
  handler — so a translated answer has nothing to break.

  ## Three figures, three different answers

  `4:12` is a duration inside a sentence set in the reader's own face, so it
  converts, exactly as `Kati.Music.Sample.tracks/0` converts the same track's
  duration. `20:14` is a clock time and goes through `Kati.Locale.time/1`,
  which is the same conversion with the formatting attached. `Spotify` is a
  brand that stays Latin and therefore needs `Kati.Locale.ltr/1`: the comma
  after it is a neutral, and a neutral between a Latin run and the numerals
  that follow resolves against an RTL page rather than against the run, which
  puts it at the wrong edge.
  """
  @spec decision() :: map()
  def decision do
    album = gettext("Tidal Works")

    %{
      seed: "albm2",
      question:
        gettext("Three albums have %{title}",
          title: Kati.Locale.quoted(gettext("Low Water"))
        ),
      sub:
        gettext("Played %{duration} from %{app}, %{time}",
          duration: Kati.Locale.number("4:12"),
          app: Kati.Locale.ltr("Spotify"),
          time: Kati.Locale.time(~T[20:14:00])
        ),
      options: [album, gettext("Live at Rex"), gettext("Best of")],
      chosen: album
    }
  end
end
