defmodule Kati.Settings.DropStatesSample do
  @moduledoc """
  The copy screen 148 puts across five states and three media.

  Same reasoning as `Kati.Settings.StatesSample`, restated rather than
  cross-referenced because the two boards earn it independently: this is a
  reference sheet, not a screen with a domain behind it, so the "sample" here
  is the specimen itself. `Kati.Media.TrackedTitle.status` holds
  `:not_started | :watching | :paused | :finished | :dropped` — this sheet's
  *Active* is `:watching`, and its *Gone cold* is not a stored value at all but
  a question `Kati.Media.Staleness` asks of the row. This moduledoc used to say
  the column held `:active` and `:gone_cold` as well, and it never has
  (`Kati.Screens.DropStates` struck the same claim out of its own). Either
  way, a sheet that draws all five at once, three media
  wide, unconditionally, cannot be the result of reading one row's status —
  there is no title that is simultaneously every state, and a sheet gated on
  which titles happen to exist today would show a different grid on every
  device. So every line below is real copy from `148.html`, typed once, not
  fetched.

  ## `S1 E3`, `p. 148 of 380`, `2 listens` are not measurements

  They read like they came off a real title because that is the entire point
  of the Dropped band: *never a bare "dropped"* is the rule the board draws,
  and a rule about always keeping a position needs a position in the
  specimen or it is not shown obeying its own rule.

  ## The specimen speaks both scripts, and its figures are half of that

  mishka-group/kati#103. `Kati.Screens.DropStates` owns eight strings — its
  title, its subtitle and the six section eyebrows. Every other word on the
  sheet is this module's, and the split is not tidiness: a msgid has to be a
  literal at its own call site, so wrapping these from the screen would move
  the copy out of the specimen, which is the one thing the specimen exists to
  hold. The fifteen rows, the six transitions, the two dashed footnotes and the
  two cream notes are `Kati.Gettext`'s here. Their TYPESETTING is the screen's
  — the mono face, the tracking, the transitions arrow — and that file says so.

  The figures are the half no catalogue can carry, and this board is made of
  them. `Kati.Locale.number/1` on every one, so a position reads **ف۲ ق۶**
  rather than **ف2 ق6**. `Kati.Locale.date/2` on Finished's one date, which is
  a different CALENDAR rather than the same date translated — `12 Aug` and
  **۲۱ مرداد** are the same day, and `:en` still draws the board's own
  `12 Aug`. Screen 07's `%{n}%` msgid on the percentage, so `۳۹٪` is
  punctuated with U+066A once for the whole app rather than twice differently.

  ## The state lines are contexted, and it is a near neighbour they are kept off

  `mix gettext.merge` fuzzy-matches a new msgid onto an existing one, and most
  of these rows are a catalogue entry with the interesting words in front of
  it: `Reading · p. %{at} / %{of}` sits beside `Kati.Books.Sample`'s own
  `p. %{at} / %{of}`, `Dropped at S%{s} E%{e}` beside
  `Kati.Screens.DropSheet`'s `at S%{s} E%{e}`, `Finished %{date}` beside the
  plain `Finished` four screens draw. A match landing the shorter entry's
  Persian would leave **ص. ۲۱۴ / ۳۸۰** in a row whose entire job is to say
  what the reader is DOING with page 214 — and it would be wrong silently, in
  one locale, on a sheet where nothing is asserted against a string. A context
  puts a msgid out of reach of that, and it also tells a translator which band
  a line belongs to, so the rows take one context between them rather than one
  apiece.

  The five counted lines are `ngettext/4` without one, because nothing in the
  app calls `pngettext/5` and a lone call site is a worse bet than the counts
  themselves, which carry their own preposition (`No play for %{n} month` is
  not `%{n} month` with a prefix as far as a Jaro window is concerned).

  The bare state words are the other exception: `Paused` on Album's row and the
  four names either side of the six arrows take `Kati.Screens.DropStates`' own
  `drop state` context, which is the msgid its *Active* eyebrow already draws.
  Those are not lines ABOUT a state, they ARE the state, and a board that spelt
  its own eyebrow one way and its own arrow another would be disagreeing with
  itself down a single page.
  """

  use Gettext, backend: Kati.Gettext

  # The three medium labels, one function apiece rather than fifteen literals:
  # every band draws the same three words, and a msgctxt typed out five times
  # is a msgctxt that drifts on the fifth.
  #
  # `Book` and `Album` are plain `gettext/1` precisely BECAUSE those msgids
  # already exist — `Kati.Screens.AddByHand` and `Kati.Screens.Stats` draw both,
  # and they are already **کتاب** and **آلبوم**. An exact msgid always beats a
  # fuzzy one, and a contexted twin would be a second Persian word for a thing
  # the app has already named once. `Show` has no msgid anywhere in the
  # catalogue and is one word, which is exactly what `gettext.merge` matches
  # onto a neighbour, so that one is contexted.
  #
  # These are what `Kati.Screens.DropStates.media_row/4` sets in the 42pt
  # gutter, and it asks `Kati.Locale.mono_face/1` about the RESULT: `Show` is
  # ASCII and keeps DM Mono, **نمایش** cannot, because `kati_mono.ttf` carries
  # no Persian glyph.
  defp show, do: pgettext("the medium a row on board 148 is about", "Show")
  defp book, do: gettext("Book")
  defp album, do: gettext("Album")

  @doc "Active — the ordinary in-progress line per medium."
  @spec active() :: [{String.t(), String.t()}]
  def active do
    # One msgid per LINE and not one per word, which is
    # `Kati.Screens.BookDetailStates.did_not_finish/0`'s rule and this board's
    # too: the verb, the separator and the position are one sentence, and a
    # translator handed *Watching* on its own could not put it where Persian
    # wants it — **بعدی** goes in front of the numbers, not behind them.
    watching =
      pgettext("a state line on board 148", "Watching · next up S%{s} E%{e}",
        s: Kati.Locale.number(2),
        e: Kati.Locale.number(6)
      )

    reading =
      pgettext("a state line on board 148", "Reading · p. %{at} / %{of}",
        at: Kati.Locale.number(214),
        of: Kati.Locale.number(380)
      )

    # `ngettext/4` rather than the number inside one msgid: eleven is a figure
    # on a specimen, but the msgid a specimen needs is the msgid a real count
    # would need. Persian does not inflect a noun after a numeral, so both its
    # forms are the same three words — which is a fact about the language, not
    # a translation nobody finished.
    rotation =
      ngettext("In rotation · %{n} play", "In rotation · %{n} plays", 11,
        n: Kati.Locale.number(11)
      )

    [{show(), watching}, {book(), reading}, {album(), rotation}]
  end

  @doc "Paused — chosen, so the line says so rather than inferring it."
  @spec paused() :: [{String.t(), String.t()}]
  def paused do
    # Bound once and used twice, so the Show row and the Book row are the
    # identical string in every locale rather than two calls that agree today
    # and invite one of them to be re-worded alone.
    deliberately = pgettext("a state line on board 148", "Paused, deliberately")

    # Album's row is the bare state word — no comma, no adverb, the adverb is
    # spent on the rows that have an inference to rule out — so it takes the
    # `drop state` context rather than the line one. It is the same msgid
    # `transitions/0` puts either side of an arrow and the same word screen
    # 148's own *Paused — chosen* eyebrow is built on.
    bare = pgettext("drop state", "Paused")

    [{show(), deliberately}, {book(), deliberately}, {album(), bare}]
  end

  @doc "Gone cold — observed, so the line names the gap rather than a choice."
  @spec gone_cold() :: [{String.t(), String.t()}]
  def gone_cold do
    # Three spans and three different nouns, because a book and an album are
    # not watched weekly. `Kati.Media.Staleness` takes the Show row's four
    # months as its own threshold and names this function while doing it, so
    # the figure below is load-bearing rather than decorative — but it is the
    # NUMBER that module reads, not this string, which is why translating the
    # sentence around it moves nothing.
    activity =
      ngettext("No activity for %{n} month", "No activity for %{n} months", 4,
        n: Kati.Locale.number(4)
      )

    session =
      ngettext("No session for %{n} week", "No session for %{n} weeks", 6,
        n: Kati.Locale.number(6)
      )

    play =
      ngettext("No play for %{n} month", "No play for %{n} months", 3, n: Kati.Locale.number(3))

    [{show(), activity}, {book(), session}, {album(), play}]
  end

  @doc """
  The footnote under Gone cold, split at its three bold runs.

  Segmented rather than handed over as one string, so the screen can style
  the emphasis the way `Kati.Screens.Money.suggestion/1` already does for the
  same shape of sentence — a cream note with bold words inside a running
  paragraph, which `Kati.UI.rich_text/1` needs as separate runs because a
  single `Text` carries exactly one style.

  ## The spaces between the runs are here, and the msgids do not carry them

  `Kati.Money.Sample.suggestion/0` holds the same shape of sentence and its
  screen adds the spaces at the call site, for the reason
  `Kati.Screens.AnimeFilter` writes out: a msgid with a space on either end is
  a msgid a translator silently trims, and the trim shows up as two words run
  together in the one paragraph nobody reads twice. This board's call site,
  `Kati.Screens.DropStates.gone_cold_note/1`, concatenates the runs exactly as
  they arrive, so the seam belongs to the specimen instead — same rule, one
  module over.
  """
  @spec gone_cold_note() :: map()
  def gone_cold_note do
    # One msgctxt over all seven runs rather than seven contexts of their own:
    # it is what tells a translator these fragments are a single sentence cut
    # at its bold words, which have to go back together in this order. The
    # Persian moves *throughout* into the first run and the verb into the
    # third, and that is only safe because the whole sentence is visible under
    # one context.
    lead = pgettext("board 148's gone cold footnote", "Rendered at a")
    weight = pgettext("board 148's gone cold footnote", "lighter weight")

    inferred =
      pgettext(
        "board 148's gone cold footnote",
        "throughout, because Kati inferred it. Dropping from here reads as"
      )

    accepting = pgettext("board 148's gone cold footnote", "accepting Kati’s suggestion")
    and_there = pgettext("board 148's gone cold footnote", "— and there is a")

    # `Kati.Locale.quoted/1` rather than the board's own `“…”` typed into the
    # msgid: the marks belong to the reader's typography and not to the
    # quotation, so Persian gets the guillemets it expects —
    # **«نه، هنوز دنبالش هستم»**. The words are the answer screen 149's keep
    # card gives, which is the answer this footnote says the app had nowhere to
    # give before.
    answer = Kati.Locale.quoted(pgettext("board 148's gone cold footnote", "No, still on it"))

    tail =
      pgettext(
        "board 148's gone cold footnote",
        "answer, which the app previously had nowhere to give."
      )

    %{
      lead: lead <> " ",
      bold_1: weight,
      mid_1: " " <> inferred <> " ",
      bold_2: accepting,
      mid_2: " " <> and_there <> " ",
      bold_3: answer,
      tail: " " <> tail
    }
  end

  @doc "Dropped — chosen, and always with the position that makes it useful later."
  @spec dropped() :: [{String.t(), String.t()}]
  def dropped do
    at_episode =
      pgettext("a state line on board 148", "Dropped at S%{s} E%{e}",
        s: Kati.Locale.number(1),
        e: Kati.Locale.number(3)
      )

    # Screen 07's `%{n}%` msgid rather than a percent sign written out here, so
    # `۳۹٪` is punctuated once for the whole app — Persian closes a percentage
    # with U+066A, and `Kati.Screens.YearShareBooks.pages_face/0` records what
    # happens when two pages answer that question separately.
    #
    # This is the same book at the same page as
    # `Kati.Screens.BookDetailStates.did_not_finish/0`, which draws **۳۹٪** off
    # the same msgid: one book, one figure, two boards that agree.
    pct = gettext("%{n}%", n: Kati.Locale.number(39))

    at_page =
      pgettext("a state line on board 148", "Did not finish at p. %{at} of %{of} (%{pct})",
        at: Kati.Locale.number(148),
        of: Kati.Locale.number(380),
        pct: pct
      )

    after_listens =
      ngettext("Dropped after %{n} listen", "Dropped after %{n} listens", 2,
        n: Kati.Locale.number(2)
      )

    [{show(), at_episode}, {book(), at_page}, {album(), after_listens}]
  end

  @doc """
  The dashed footnote under Dropped, flattened to one string.

  `Kati.UI.SettingsList.note/2` is built for exactly this frame — an icon
  over one paragraph, border rather than fill — and it takes plain text, the
  same trade every other call site in the app makes for a footnote with an
  emphasised word inside it. The bold on *"Never a bare dropped"* and
  *percentage* does not survive; the sentence does.
  """
  @spec dropped_note() :: String.t()
  def dropped_note do
    # `Kati.Locale.quoted/1` again, and `gettext("dropped")` inside it rather
    # than a fourth Persian word for the state: `Kati.Screens.Library` already
    # draws that msgid on a tile and it is already **رهاشده**. The marks are
    # the reader's, so the rule this sentence states arrives in Persian as
    # **«رهاشده»** and not as a foreign mark around a familiar word.
    gettext(
      "Never a bare %{dropped}. The captured position is the single thing that " <>
        "makes this better than every incumbent, all of which throw it away. " <>
        "For a book the percentage is the useful part.",
      dropped: Kati.Locale.quoted(gettext("dropped"))
    )
  end

  @doc "Finished — and Album's third row says there is no such thing for it."
  @spec finished() :: [{String.t(), String.t()}]
  def finished do
    complete = pgettext("a state line on board 148", "Season complete / series complete")

    # The board writes `12 Aug` with no year, and a bare `12 Aug` on a Persian
    # page is a calendar nobody there reads. `Kati.Locale.date/2` on a real
    # `Date` gives the board's own `12 Aug` under `:en` and **۲۱ مرداد** under
    # `:fa` — the same day in the reader's own calendar, which is the half of
    # #103 gettext cannot do. `:short` is the shape a row under a title wants
    # and drops the year again; the year itself is the app's sample year, the
    # one `Kati.Settings.Sample` dates its last backup to.
    on =
      pgettext("a state line on board 148", "Finished %{date}",
        date: Kati.Locale.date(~D[2026-08-12], :short)
      )

    none = pgettext("a state line on board 148", "Deliberately none")

    [{show(), complete}, {book(), on}, {album(), none}]
  end

  @doc "The dashed footnote under Finished, flattened the same way as `dropped_note/0`."
  @spec finished_note() :: String.t()
  def finished_note do
    # The four state names are interpolated rather than typed into the
    # sentence, and they are the same four `transitions/0` puts either side of
    # its arrows. A chain that named the states in words of its own would be a
    # second Persian vocabulary for the board's own five states, one paragraph
    # under the band that draws them.
    #
    # The ARROW is part of the copy and not part of this code: `→` in the
    # msgid, `←` in the Persian. `Kati.Locale.forward_glyph/0` answers for an
    # icon and there is no icon here — this is a character inside a sentence,
    # and in a right-to-left line a chain still pointing right would run the
    # album backwards through its own states.
    gettext(
      "Album has no Finished state, on purpose: an album does not finish the " <>
        "way a series does. It goes %{active} → %{paused} → %{cold} → %{dropped} " <>
        "and back, and that is the whole of it.",
      active: pgettext("drop state", "Active"),
      paused: pgettext("drop state", "Paused"),
      cold: pgettext("drop state", "Gone cold"),
      dropped: pgettext("drop state", "Dropped")
    )
  end

  @doc """
  The six transitions, and what each one captures on the way through.

  `from` and `to` are the state names either side of the arrow; `capture` is
  the board's own answer to *what does Kati write down when this happens*,
  which is the whole reason this band exists — the five state bands say what
  a title looks like at rest, this one says what changes hands at the
  border.

  The arrow between them is `Kati.Screens.DropStates`', not this module's:
  under `:fa` the row lays its columns out right-to-left on its own, and the
  glyph has to turn round with them or every transition is drawn backwards.
  """
  @spec transitions() :: [{String.t(), String.t(), String.t()}]
  def transitions do
    active = pgettext("drop state", "Active")
    paused = pgettext("drop state", "Paused")
    cold = pgettext("drop state", "Gone cold")
    dropped = pgettext("drop state", "Dropped")

    known = pgettext("what a transition captures", "nothing — position already known")
    stopped = pgettext("what a transition captures", "the date activity stopped")

    # The quoted answer is `Kati.Locale.quoted/1`'s for `gone_cold_note/0`'s
    # reason, and it is the short form of the same sentence — the board says
    # *"No, still on it"* on the cream note and *"still on it"* here.
    cleared =
      pgettext("what a transition captures", "nothing — %{answer} just clears it",
        answer: Kati.Locale.quoted(pgettext("the answer a gone cold row offers", "still on it"))
      )

    with_reason = pgettext("what a transition captures", "position + optional reason")

    # Bound here and read again by `resume_note/0`, which quotes this row word
    # for word: one promise, one msgid, one Persian clause. Two calls would
    # agree today and drift the first time either is re-worded.
    resumes = pgettext("what a transition captures", "resumes at the captured position")

    [
      {active, paused, known},
      {active, cold, stopped},
      {cold, active, cleared},
      {cold, dropped, with_reason},
      {active, dropped, with_reason},
      {dropped, active, resumes}
    ]
  end

  @doc """
  The closing note, split at its two bold runs the same way as `gone_cold_note/0`.

  The spaces between the runs are added here and are not part of any msgid,
  for the reason written out on `gone_cold_note/0`.
  """
  @spec resume_note() :: map()
  def resume_note do
    lead = pgettext("board 148's closing note", "Picking a dropped title back up")

    # `transitions/0`'s own clause, deliberately: the note is quoting the
    # Dropped → Active row four lines above it, and a twin msgid here would let
    # the board promise one thing in the band and a differently-worded thing in
    # the note under it.
    resumes = pgettext("what a transition captures", "resumes at the captured position")

    mid =
      pgettext(
        "board 148's closing note",
        "— it was captured for a reason. Kati says where you were and offers"
      )

    over = pgettext("board 148's closing note", "start over")
    tail = pgettext("board 148's closing note", "beside it.")

    %{
      lead: lead <> " ",
      bold_1: resumes,
      mid: " " <> mid <> " ",
      bold_2: over,
      tail: " " <> tail
    }
  end
end
