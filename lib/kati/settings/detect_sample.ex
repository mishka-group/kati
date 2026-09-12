defmodule Kati.Settings.DetectSample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in auto-detect state, screen 36.

  Manual ticking stays the default; this screen is the opt-in that removes it,
  so the sample has to show the opt-in actually working — something playing
  right now, three sources with real tick counts, and one ambiguous match
  waiting on an answer.

  That last part is the design's argument: an unsure match queues up as a
  question rather than guessing, because a wrong tick pollutes a history the
  user cannot easily audit. A sample with an empty queue would hide the whole
  idea.

  ## The drawing speaks both scripts now

  mishka-group/kati#103 folded the 33 Persian mirrors away, so board 36 is
  `Kati.Screens.AutoDetect` under `:en` and under `:fa`, and the drawing that
  screen falls back to on a device with no bridge has to be readable in both.
  Every word below goes through `Kati.Gettext`.

  `Kati.Screens.AutoDetect`'s own moduledoc still says the opposite — *its
  words are still English literals* — and that paragraph, `row_tap/1`'s doc
  and `tap/1`'s doc are all stale by exactly this change. They are that
  module's to correct.

  Two lookups had to move with the words, because each was keyed on a DRAWN
  string and a drawn string is translated now:

    * **Every row names its own `:tap`.** `Kati.Screens.AutoDetect.row_tap/1`
      falls back to `tap/1`, which matches the English titles *Browser
      extension*, *This phone* and *Tick at*. Under `:fa` those read
      **افزونهٔ مرورگر**, **این گوشی** and **تیک زدن در**, so all three clauses
      would fall through to `nil` — and the permission row would lose its tap
      on the one page a reader opens in order to grant the permission,
      silently, because a row with no tap is indistinguishable from a row that
      never had one. The `:tap` key is the affordance `row_tap/1` documents for
      exactly this, and the tags below are the ones `tap/1` answers today, so
      nothing moves in English.

    * **Every answer names its own tag.** `Kati.Screens.AutoDetect.choice/3`
      spells a bare label's tag out of the label itself — `answer_tag/1`,
      `String.to_atom("answer_" <> …)` — which under `:fa` mints an atom per
      label per language into a table that is never collected. `{label, tag}`
      is the pair shape `choice/3` already takes, and `chosen?/2` already
      compares an option by its label half, so `chosen` still matches.

  ## What stays Latin, and why

  What a service calls itself: `Lumen+`, `Apple TV`, `Chromecast`, `Orbit`.
  Board 127 draws `Lumen+` in Latin on a Persian page, and
  `Kati.Screens.AutoDetect.app_name/1` carries the long version of the rule —
  a real service name comes off `Kati.Services.Service` and no msgid reaches
  it, so a fixture that transliterated would spell one thing two ways across
  the app.

  The elapsed clock stays Latin too, and that one is stated where it is drawn:
  `Kati.Screens.AutoDetect.now_playing/1` isolates the run and then asks
  `Kati.Locale.mono_face/1` about the RAW string, which keeps
  `41:02 / 55:00` in DM Mono in both scripts. `kati_mono.ttf` carries none of
  U+06F0–U+06F9, so Persian digits there would be handed to Android's
  substitute face beside a card that is otherwise in Kati's own.
  """

  @doc "The mono line under the title."
  @spec sources_line() :: String.t()
  def sources_line do
    # A COUNT rather than a label, so the numeral goes through
    # `Kati.Locale.number/1` and the noun through `ngettext/4`. Persian does
    # not inflect a noun after a numeral — ۱ منبع and ۳ منبع take the same word
    # — so the two English forms are one Persian sentence.
    #
    # `3` written out and not `length(sources())`, which is four: the board
    # says `3 sources` over four rows because the browser extension is not
    # installed and so is not a source yet. Deriving it would draw `4 sources`
    # and disagree with `test/design/screens/36.html`.
    #
    # Persian digits are right here even though this is the mono line:
    # `Kati.UI.SettingsList.subtitle/2` sets it in `Kati.Locale.mono_face/0`,
    # which answers the Persian face under `:fa` rather than DM Mono.
    n = 3

    ngettext("%{n} source", "%{n} sources", n, n: Kati.Locale.number(n))
  end

  @doc "The cream banner: the opt-in itself, and what it has done so far."
  @spec banner() :: map()
  def banner do
    # `Kati.Screens.AutoDetect.ticked_line/1`'s own msgid, written out rather
    # than called. The screen is what reads this module, and a Sample that
    # called back into the screen would close a loop between the drawing and
    # the page that draws it. It is the same catalogue entry either way — one
    # figure, one sentence, one line — and `ngettext/4` for the reason stated
    # there.
    ticked = 41

    %{
      title: gettext("Detect what you play"),
      meta:
        ngettext(
          "%{n} EPISODE TICKED FOR YOU",
          "%{n} EPISODES TICKED FOR YOU",
          ticked,
          n: Kati.Locale.number(ticked)
        ),
      on: true
    }
  end

  @doc """
  What is playing, how far in, and when it will tick.

  The progress bar states the rule beside the number — "ticks at 90%" — so the
  thing about to happen is legible before it happens.
  """
  @spec now_playing() :: map()
  def now_playing do
    %{
      seed: "hollow71",
      title: gettext("The Long Hollow"),
      meta: playing_meta(),
      status: pgettext("now playing pill", "Live"),
      progress: 0.74,
      # LATIN DIGITS, AND DELIBERATELY. `Kati.Screens.AutoDetect.now_playing/1`
      # wraps this run in `Kati.Locale.ltr/1` and then asks
      # `Kati.Locale.mono_face/1` about the raw string, so a clock that is pure
      # ASCII keeps DM Mono in both scripts — the one run boards 36 and 150
      # both hold there. `Kati.Locale.number/1`'s own doc states the rule, and
      # the live `clock/1` answers ASCII for the same reason: a drawing whose
      # digits disagreed with the device's would be two spellings of one
      # figure.
      elapsed: "41:02 / 55:00",
      rule: gettext("ticks at %{n}%", n: Kati.Locale.number(90))
    }
  end

  @doc "The four sources, one of which is not installed and offers itself instead."
  @spec sources() :: [map()]
  def sources do
    [
      %{
        icon: "tv",
        # Bare, and not a msgid: this is what the service calls itself.
        # `Kati.Screens.AutoDetect.app_name/1` answers the same two words off a
        # package name and says why none of its eight ever goes through
        # `gettext/1`. No `Kati.Locale.ltr/1` either — a row title is the whole
        # of its own `<Text>`, so it has no Persian run beside it for a neutral
        # to resolve against, and it is pure ASCII in a sans face either way.
        title: "Apple TV",
        sub: connected(28),
        control: {:switch, true},
        tap: nil
      },
      %{
        icon: "cast",
        title: "Chromecast",
        sub: on_this_network(13),
        control: {:switch, true},
        tap: nil
      },
      %{
        icon: "computer",
        # `Kati.Screens.RetiredTile`'s own msgid, and the drawn half of a pair:
        # the sheet matches the ENGLISH `"Browser extension"` as a section key
        # — `Kati.Screens.AutoDetect.handle_tap(:open_retired, …)` sends that
        # literal — and draws `gettext("Browser extension")` as its header. The
        # same string doing two jobs, which is why one of them is translated
        # and the other cannot be. This is the one that is read.
        title: gettext("Browser extension"),
        sub: pgettext("a source that is not installed", "Not installed"),
        control: {:pill, pgettext("the pill that installs a missing source", "Get")},
        tap: :open_retired
      },
      %{
        icon: "phone_iphone",
        # `Kati.Screens.AutoDetect.real_sources/2`'s own msgid, its own
        # sub-line and its own tag. The drawn row and the live row are the same
        # row, so they say the same words and open the same system page.
        title: pgettext("detection source", "This phone"),
        sub: gettext("Detects audio from any app"),
        control: {:switch, false},
        tap: :open_media_access
      }
    ]
  end

  @doc "When a play counts, and what never counts."
  @spec rules() :: [map()]
  def rules do
    [
      %{
        icon: "percent",
        # Both halves are `Kati.Screens.AutoDetect.real_rules/0`'s, which is
        # also where the contexts are argued: `Tick at` alone cannot tell a
        # translator a threshold from a time of day, and `%{n}% watched` is the
        # same figure `Kati.Screens.Library` writes over a progress bar.
        title: pgettext("the detection threshold row", "Tick at"),
        sub: gettext("%{n}% watched", n: Kati.Locale.number(90)),
        control: :chevron,
        tap: :cycle_threshold
      },
      %{
        icon: "help",
        title: gettext("Ask before ticking"),
        sub: gettext("Only when the match is unsure"),
        control: {:switch, true},
        tap: nil
      },
      %{
        icon: "do_not_disturb_on",
        # One word, so `pgettext/2`: `mix gettext.merge` fuzzy-matches a msgid
        # this short against any longer entry containing it, and the context
        # also says what the row IS — an exclusion rule rather than a button
        # that dismisses something.
        title: pgettext("the rule row for what never counts", "Ignore"),
        sub: gettext("Trailers, anything under %{n} min", n: Kati.Locale.number(5)),
        control: {:switch, true},
        tap: nil
      }
    ]
  end

  @doc "The queued question: a 43-minute play that matches two different titles."
  @spec decision() :: map()
  def decision do
    # Bound once and used twice, so `chosen` is the identical string to the
    # option it selects in every locale — `Kati.Screens.AutoDetect.chosen?/2`
    # compares the label half, and two separate calls would still agree but
    # would invite one of them to be re-worded alone.
    series = pgettext("an answer to board 36's unsure match", "The series")

    %{
      seed: "marram15",
      question:
        pgettext(
          "board 36's unsure match, asked between two titles the reader has",
          "%{one} or %{two}?",
          one: Kati.Locale.quoted(marram_episode()),
          two: Kati.Locale.quoted(gettext("Marram Grass"))
        ),
      sub:
        gettext("Played %{run} on %{service}, %{at}",
          # `%{n}m` is the runtime msgid `Kati.Screens.UpNext` and
          # `Kati.Screens.WhatFits` already write; `Orbit` is a service name
          # and stays Latin, isolated because it sits inside a Persian
          # sentence; the clock is the reader's, in their own digits, because
          # this sub-line is set in the sans face rather than in DM Mono.
          run: gettext("%{n}m", n: Kati.Locale.number(43)),
          service: Kati.Locale.ltr("Orbit"),
          at: Kati.Locale.time(~T[21:10:00])
        ),
      # `{label, tag}` pairs rather than bare labels. See the moduledoc: a bare
      # label sends `Kati.Screens.AutoDetect.choice/3` to `answer_tag/1`, which
      # spells an atom out of the drawn string — a new one per label per
      # language, into a table that is never collected. These three tags are
      # exactly what `answer_tag/1` derives in English, so the drawing answers
      # as it always did.
      options: [
        {series, :answer_the_series},
        {pgettext("an answer to board 36's unsure match", "The film"), :answer_the_film},
        {pgettext("an answer to board 36's unsure match", "Neither"), :answer_neither}
      ],
      chosen: series
    }
  end

  # `S2E6 · LUMEN+ · APPLE TV`, composed the way
  # `Kati.Screens.AutoDetect.session_meta/1` composes the live one rather than
  # written as a single `S%{s}E%{e} · %{service} · %{app}` msgid. Composing is
  # what keeps `Lumen+` and `Apple TV` out of the catalogue — a msgid is an
  # invitation to transliterate — and the catalogue already holds
  # `S%{s}E%{e} · %{service} · %{at}` for the airing line, which a
  # near-identical fourth entry would only be confused with.
  #
  # `Kati.Locale.ltr/1` on the two names because HERE they do sit inside a
  # Persian run. `Lumen+` ends in a neutral, and a neutral that is not between
  # two Latin characters takes the paragraph's direction rather than the run's:
  # under `:fa` the plus jumps to the far side and the eyebrow reads `+Lumen`.
  #
  # `Kati.UI.eyebrow_label/1` and not `String.upcase/1`. Arabic script has no
  # case, so upcasing the Persian half is a no-op that leaves the two service
  # names beside it shouting alone. In English every piece upcases and the line
  # is the board's own, character for character.
  defp playing_meta do
    [
      pgettext("the episode on the now playing card", "S%{s}E%{e}",
        s: Kati.Locale.number(2),
        e: Kati.Locale.number(6)
      ),
      Kati.Locale.ltr("Lumen+"),
      Kati.Locale.ltr("Apple TV")
    ]
    |> Enum.join(" · ")
    |> Kati.UI.eyebrow_label()
  end

  # *Marram E3* — `Kati.Library.Sample`'s own Marram and an episode number.
  # That is what makes the question a real one: the series is on the reader's
  # shelf and so is `Kati.Books.Sample`'s *Marram Grass*, so Kati is choosing
  # between two things it actually holds. `Kati.Media.AnimeSample`'s moduledoc
  # states the discipline — the fixture is reused rather than a tenth fictional
  # title invented — and reusing the fixture means reusing its Persian too:
  # **مرام** and **علف مرام** are already in the catalogue.
  #
  # `pgettext/2` because `%{title} E%{e}` is two characters and a space once
  # the interpolations are taken out, and the catalogue already holds four
  # spellings of a season-and-episode bookmark for it to be fuzzy-matched
  # against.
  defp marram_episode do
    pgettext("a series and the episode of it that was heard", "%{title} E%{e}",
      title: gettext("Marram"),
      e: Kati.Locale.number(3)
    )
  end

  # The two tick counts, one helper each. A helper rather than the numeral
  # written twice inside one `ngettext/4` call: the msgid stays a literal at
  # the call site, which is all gettext needs, and the figure is stated once.
  #
  # `ngettext/4` because Persian does not inflect a noun after a numeral —
  # ۱ تیک and ۲۸ تیک take the same word — so the two English forms are one
  # Persian sentence, which is the whole of what a plural entry is for.
  defp connected(ticks) do
    ngettext("Connected · %{n} tick", "Connected · %{n} ticks", ticks,
      n: Kati.Locale.number(ticks)
    )
  end

  defp on_this_network(ticks) do
    ngettext("On this network · %{n} tick", "On this network · %{n} ticks", ticks,
      n: Kati.Locale.number(ticks)
    )
  end
end
