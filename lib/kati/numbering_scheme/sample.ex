defmodule Kati.NumberingScheme.Sample do
  @moduledoc """
  Stand-in copy for board 153, which explains a feature rather than one show.

  Every other screen this pattern was built for shows a resource: `show/0` in
  `Kati.SeriesSettings.Sample` is the specific title screen 35's settings
  belong to, sample only because `Kati.Media` cannot fill it in yet. This
  screen is different in kind, not just in progress. `Kati.Media.TrackedTitle`
  carries no numbering-scheme column at all — not "not built", *not asked
  for*, because the two cards below are not one show's current setting shown
  twice. `inherited/0` is the row a title with no override draws; `overridden/0`
  is the row a title whose default was wrong draws once corrected. A single
  show cannot be in both states at once, and the drawing does not claim it is
  — it draws the feature's two shapes side by side, the way the design system
  panel at the foot of this board draws Palette and Type and Rhythm as
  concepts rather than as one screen's colours. There is nothing here for a
  future `Kati.Media` migration to inherit, because there is no per-show fact
  being approximated: `%{icon: "pin", title: "Absolute", ...}` is not screen
  153's guess at a row that will one day read `title.numbering_scheme`, it is
  the whole of what the row says.

  Marked clearly rather than hidden all the same: sample data that looks like
  real data is how a demo quietly becomes a lie, whether or not a resource is
  ever coming for it.

  ## Every word on board 153 that is copy lives here

  mishka-group/kati#103. `Kati.Screens.NumberingScheme` owns the chrome — its
  four eyebrows, its two info notes and the MAL tile's three row labels, all
  literals at that file's own call sites — and this module owns everything the
  cards are *filled* with: the header, both rows' titles, subs and pills, the
  comparison card's two labels and its footnote, and every line of the MAL
  tile's body. The screen's moduledoc states the split and the reason: one
  msgid per string, wherever the string lives, and a screen that made its own
  copy of a fixture's copy would be two strings to keep in step. A `gettext/1`
  over there could not reach these anyway — the extractor needs a literal at
  the call site and what the screen holds is a map key.

  Every group is a FUNCTION and none of them is an attribute, which matters now
  that they hold `gettext/1`: a module attribute is evaluated at COMPILE time
  and would freeze this board in whichever locale the compiler happened to be
  in.

  ## What stays Latin, and the one place that is not a name

  `MyAnimeList`, its initial `M` and `animelist.xml` stay out of the catalogue
  altogether — a service's name for itself, the letter the drawing sets in the
  tile, and a file that service writes. Board 127 draws `Lumen+` in Latin on a
  Persian page for the same reason, and the screen's own eyebrow above this
  tile keeps `MyAnimeList` inside its Persian sentence rather than
  transliterating it. `MAL` and `XML` ride inside their msgids on the same
  ticket.

  `E32` and `S2 E6` are the exception that is not a name. They are the
  numbering ITSELF — the two looks the comparison card exists to set side by
  side — so they stay Latin the way a typography board's specimen line stays
  Latin: translating the specimen deletes the thing being shown.
  `Kati.Screens.AnimeFilter.anime_subchoice/1` draws the same two codes one
  board earlier and argues it there. `comparison/0` carries the rest of that
  argument, including why neither of them takes `Kati.Locale.ltr/1`.

  Everything else is a msgid, the numerals included where there are any. There
  are none here — this board's only figures are those two codes — but the rule
  `Kati.SeriesSettings.Sample` states holds anyway: a Persian page drawing
  Latin numerals is the half of this fold no audit catches, because the sweep
  matches runs of four or more Latin LETTERS and cannot see a numeral at all.
  """

  use Gettext, backend: Kati.Gettext

  @doc "The screen's own header."
  @spec header() :: map()
  def header do
    %{
      # `pgettext/2` and not `gettext("Numbering")`. The catalogue already
      # answers `Numbering` under `msgctxt "what a MyAnimeList import brings"`
      # — the middle of the MAL tile's three row labels, which the screen owns
      # — and a second one-word entry sitting beside it with no context is
      # precisely what `mix gettext.merge` fuzzy-matches, silently, into
      # whichever of the two it reached first. Two entries with the same
      # Persian word in them is the correct outcome here: this board's heading
      # and that row are the same noun, and a translator has to be able to tell
      # which one is being asked for.
      title: pgettext("the screen that explains episode numbering", "Numbering"),
      # The capitals belong in the msgid. `Kati.UI.SettingsList.subtitle/2`
      # draws this line as written — it sets mono and does not upcase, unlike
      # `Kati.UI.eyebrow_label/1` — so a sentence-case msgid would quietly
      # demote board 153's eyebrow in ENGLISH, where the capitals are the
      # typography. Persian has no case and the msgstr is an ordinary sentence,
      # which is the shape every all-capital entry in the catalogue already
      # takes: `Kati.Screens.Restore`'s NOTHING IS WRITTEN UNTIL THE LAST STEP
      # is «تا آخرین گام چیزی نوشته نمی‌شود».
      subtitle: gettext("A DEFAULT THAT ANNOUNCES ITS OWN REASON")
    }
  end

  @doc """
  The un-touched row: a guess, with the reason attached.

  `sub` is the whole argument the board is making — "because this is anime" is
  not filler under the value, it is the fact that turns a guess into something
  the user can trust or correct on sight.
  """
  @spec inherited() :: map()
  def inherited do
    %{
      icon: "pin",
      title: scheme_absolute(),
      sub: gettext("because this is anime"),
      # `Override` and `Reset` below are two one-word pills and both take a
      # context. `Reset` needs one most: the catalogue's existing entry is
      # `msgctxt "clears every filter on the sheet"`, which is a different act
      # with the same English word, and a bare msgid here would have been
      # merged onto it. Neither label is ever a TAG — the screen's moduledoc
      # argues at length that these pills carry no `on_tap`, so nothing is
      # built out of the word and a translated pill cannot go dead the way
      # `Kati.Season.Sample`'s `:orders` would have.
      action: pgettext("the pill that replaces an inherited default", "Override")
    }
  end

  @doc """
  The corrected row: a title the anime default got wrong.

  `sub` names both halves out loud — what the user set AND what the default
  would have picked — which is the same self-explaining move `inherited/0`
  makes, aimed the other way.
  """
  @spec overridden() :: map()
  def overridden do
    %{
      icon: "pin",
      title: scheme_seasons(),
      # The default's name is INTERPOLATED rather than written into this msgid.
      # The sentence's whole job is to name what the default would have picked,
      # and the row that picked it is drawn a card above with `scheme_absolute/0`
      # as its title: a translator given `anime default was Absolute` whole
      # could render that word one way here and another way there, and board
      # 153's claim — that the default announces itself — is exactly what
      # breaks when the announcement uses a different word from the thing it
      # announces. `Kati.Screens.AnimeFilter.anime_subchoice/1` interpolates
      # the same kind of name into the same kind of sentence for the same
      # reason.
      sub: gettext("you set this · anime default was %{default}", default: scheme_absolute()),
      action: pgettext("the pill that reverts an override to the inherited default", "Reset")
    }
  end

  @doc "The two labels the comparison card sets side by side, and its footnote."
  @spec comparison() :: map()
  def comparison do
    # `E32` and `S2 E6` are the only two strings in this file that stay Latin
    # and stay out of the catalogue, and they are the SUBJECT of the card
    # rather than copy on it.
    # `Kati.Screens.AnimeFilter.anime_subchoice/1` draws the same two specimens
    # one board earlier and states the rule: they are *"the numbering itself —
    # the thing the sentence is about — so a translator must not be given the
    # chance to edit them"*. A card whose entire job is to show what the two
    # schemes LOOK like cannot have the two looks translated out from under it,
    # which is the same exception the typography boards make for their Latin
    # specimen lines.
    #
    # No `Kati.Locale.ltr/1` on them either, and that is a decision rather than
    # an omission. Board 152 needs the isolate because its codes sit inside a
    # Persian sentence and one of them trails a full stop — a NEUTRAL, which
    # resolves against the paragraph and lands at the wrong edge. Here each
    # code is alone in its own `Text`: the single space in `S2 E6` sits between
    # two strong-Latin runs and resolves Latin with them, so there is no
    # neutral for an isolate to protect. Adding one would cost something real.
    # `Kati.Screens.NumberingScheme.comparison_column/1` asks
    # `Kati.Locale.mono_face(value)`, which decides on the string being pure
    # ASCII — and `U+2066`/`U+2069` are not ASCII. The isolate would hand two
    # ASCII specimens to Vazirmatn and take them out of the DM Mono the drawing
    # sets them in, which is the one thing that call was put there to prevent.
    %{
      left: %{label: scheme_absolute(), value: "E32"},
      right: %{label: scheme_seasons(), value: "S2 E6"},
      # One msgid, `<>`-joined for the line width rather than split into
      # sentences — Gettext expands a concatenation of literals at compile time,
      # so the extractor sees the whole paragraph and a translator gets it in
      # one piece instead of three clauses whose Persian order is not the
      # English one. `Kati.Screens.NumberingScheme.reason_note/0` carries the
      # long version of this note.
      note:
        gettext(
          "Same episode. Numbering changes only what is displayed — Kati always " <>
            "stores season and episode, so switching never loses a tick and never " <>
            "shows both at once."
        )
    }
  end

  @doc """
  The MyAnimeList import tile.

  `does_not` exists because this tile is, per the board's own eyebrow, "the
  whole of a MAL user's onboarding" — the only integration those users get, so
  it has to say what does NOT come across as plainly as what does.
  """
  @spec mal() :: map()
  def mal do
    %{
      # Three names and no msgid between them. `M` is MyAnimeList's own initial
      # and the screen sets it in DM Mono deliberately — `mal_glyph/1` is the
      # one mono slot on that board which is NOT `Kati.Locale.mono_face/1`,
      # because a transliterated `M` would be a brand spelled two ways. The
      # title is the service's name for itself and the file is one the service
      # writes.
      glyph: "M",
      title: "MyAnimeList",
      file: "animelist.xml",
      comes_across: gettext("Titles, scores, watched counts, status, dates"),
      # `Absolute` interpolated for the reason `overridden/0` gives, and `MAL`
      # written into the msgid rather than interpolated for the reason the
      # screen's own eyebrow gives: `The MyAnimeList tile — sole integration
      # those users get` carries the Latin run inside its Persian sentence, and
      # the three letters hold no neutral character an isolate would have
      # anything to protect.
      numbering:
        gettext("Set to %{scheme} — MAL exports are absolute", scheme: scheme_absolute()),
      does_not: gettext("Reviews, tags and your MAL friends"),
      footnote:
        gettext(
          "XML is importer-only — there is no MAL sync. This tile is the whole of " <>
            "a MAL user’s onboarding, so it states both halves."
        )
    }
  end

  # The two scheme names, asked for in one place each.
  #
  # `Absolute` is drawn four times on this board — the inherited tile's title,
  # the comparison card's left kicker, the override's sub-line and the MAL
  # tile's numbering row — and `Seasons` twice. One msgid behind all six, so
  # the board cannot say one word in the tile and another in the sentence
  # explaining the tile.
  #
  # `msgctxt "episode order"` and not a context of this board's own, because
  # `Kati.Screens.Season.order_title/1` already spells `Absolute` in exactly
  # that context, with `Aired` beside it. Board 34 and board 153 are one push
  # apart — `Kati.Screens.Season` is what pushes this screen — and
  # one thing must not be called two things one back tap apart. It is the
  # same rule in Persian: the season sheet
  # says «مطلق» and this card has to as well.
  #
  # Functions and not module attributes. `gettext/1` inside an attribute is
  # evaluated at COMPILE time and would freeze both names in whichever locale
  # the compiler was in — which is the trap this whole fixture is arranged
  # around.
  defp scheme_absolute, do: pgettext("episode order", "Absolute")

  defp scheme_seasons, do: pgettext("episode order", "Seasons")
end
