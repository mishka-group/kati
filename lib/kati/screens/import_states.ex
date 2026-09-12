defmodule Kati.Screens.ImportStates do
  @moduledoc """
  Screen 142 — Import, source states, on one sheet pushed under Settings.

  `Kati.Screens.ImportSources` (140) is a grid of every source Kati
  recognises; `Kati.Screens.ImportRecognised` (141) is what opens once a tile
  is tapped and a file is read — a recognised export with its guess offered
  a correction and its columns mapped, collapsed or expanded. Neither screen
  can show what happens when the guess is wrong, because both are drawn for
  the case where it is right. This is the board for the three ways it is
  not: the file does not match the tile that was tapped, the file matches a
  *different* tile than the one that was tapped, and the file matches the
  right tile but is missing a column a newer export would carry. It is a
  reference sheet in screen 27's manner — pictures of states you go and look
  at rather than something the app puts in front of you — and it carries a
  back pill for exactly that reason, as 27, 67, 75, 95 and 123 do. The back
  pill says `Settings`, undisguised, because 140 and 141 are both reached
  from there and so is this sheet.

  ## Orange once, grey twice

  *Wrong guess* keeps the orange dash. It is the state right after a tap —
  something just happened, and the reader is looking at the result of their
  own last action. The other two are not moments; they are what the file
  itself turned out to be, settled the instant it was opened, so they take
  27's grey dash the way `Kati.Screens.MoneyStates`' three already-settled
  bands do.

  ## The grid under the cream card is screen 140's own two tiles

  `Goodreads` and `StoryGraph` are two of the picker's six — the same
  letters, names and filenames `Kati.Screens.ImportSources`'s own `@commonest`
  carries for them, typed again here rather than read from that module
  attribute, because it is private and a states sheet reading a sibling
  screen's constant would break the moment that screen's own drawing added a
  seventh source. Chosen because the cream banner above them names Goodreads
  as the wrong guess — the reader needs to see the tile they tapped sitting
  back in the grid, unselected, next to the one they might have meant.
  Nothing in the grid is highlighted: the guess is *remembered* in the
  sentence above it, not in the grid's own state, because the grid itself has
  gone back to being a grid. A picker that greyed out or ringed the wrong
  tile would be claiming to remember something no resource here holds.

  See `source_tile/3`'s own doc for why the card is rebuilt rather than
  calling `Kati.Screens.ImportSources.source_tile/1` outright.

  ## Cream is where the last screen 37 note left it: the one place asking, not telling

  `Kati.Screens.Import`'s conflict card sits on cream "to mark the one place
  the screen is asking rather than telling." This card is the same move for
  the same reason — *Pick again, or use Something else* is an invitation, not
  a report, and it is the only card on this board that offers a choice rather
  than stating a fact. The other two sit on plain card ground because they
  are findings.

  ## Naming what it found, never what failed

  The board's own dashed footnote states the rule this sheet is built to
  demonstrate, and the icon choice enforces it. *Unrecognised for the named
  tile* gets the red `error` glyph because it is a hard stop — the file does
  not belong to any source Kati can name with confidence beyond a guess, nothing
  is written, and the reader needs a different file or a different tile.
  *Wrong guess* and *partial columns* both get the amber `help` glyph,
  because both still end somewhere useful: pick again, or import an old
  export that will simply be missing one thing. Red is reserved for the one
  card that goes nowhere.

  *No Date Read column* answers the two questions a partial match actually
  raises — which column, and what happens without it — instead of the single
  word `Warning`. `Kati.Money.per_hour/2`'s guard already made this app's
  argument once: withholding a number is not the same as hiding what withholding
  it costs.

  ## Nothing on this board taps

  Every control here is drawn at full contrast and answers nothing.
  `Kati.Screens.MoneyStates` already made the case for why: a specimen on a
  reference sheet that actually navigated would take the reader off the
  sheet they came to compare states on, mid-comparison. `Use Letterboxd
  instead` and `Pick again` exist to be looked at as the buttons a wrong
  guess draws, not to be pressed — pressing "Pick again" here would pop this
  whole sheet rather than open `Kati.Screens.ImportSources`, because this
  screen has no picker state of its own for a fresh grid to land in.
  `Kati.Screens.Pushed` defines no `handle_tap/2` on purpose, so an unwired
  tap is reported rather than swallowed — which is exactly why none of these
  props are set at all.

  ## What stays Latin when this page renders under `:fa`

  mishka-group/kati#103. The chrome translates — the title, the subtitle, the
  three eyebrows, all three cards and the footnote. What does not is the grid's
  own four strings and the three names the cards spell out. `Goodreads`,
  `StoryGraph`, `goodreads_library_export.csv` and `storygraph_export.csv` are
  140's, and `Kati.Screens.ImportSources`'s moduledoc is where the rule is
  written down: board 278 transliterated the overflow four («سیمکل») and board
  328 ruled against it, because a transliterated export name matches no file on
  the phone. `Letterboxd`, `Letterboxd URI` and `Watched Date` go the same way
  and the last two for a sharper version of the same reason — they are COLUMN
  HEADERS the reader is being asked to find in a row of their own file, so a
  Persian rendering of either would name a column that is not there.

  Each of those is handed to `Kati.Locale.ltr/1` wherever it lands inside a
  Persian sentence, because a Latin run's neutrals otherwise resolve against
  the paragraph rather than against the run — the failure screen 83 drew for
  five licence notices. The two filenames are not: they are whole lines of
  their own rather than runs inside a sentence, which is how
  `Kati.Screens.ImportSources.source_tile/1` draws the same two, and a tile
  that differed from the picker's by an invisible isolate would be the one
  difference this sheet is not for.

  `font_family` on the filename is `Kati.Locale.mono_face/1` rather than the
  hardcoded `"mono"` it used to be: it asks the STRING and not the reader, so
  both values this board holds today keep DM Mono, and a filename typed here
  tomorrow that is not pure ASCII is typeset in Vazirmatn rather than handed to
  Android's substitute face. `letter_spacing` on the tile's name stays the
  drawing's literal and that is not an oversight — 140's own `source_tile/1`
  carries the argument: `Kati.Locale.tracking/1` exists to drop the Latin
  design's tightening off text that turns into Persian, and a trade name never
  does.

  ## The bold spans are not bold

  As in `Kati.Screens.MoneyStates`: `Kati.UI.rich_text/1` concatenates its
  runs and applies the longest one's style, because `MobText` takes a
  `String` and the bridge has no `AnnotatedString`. `Goodreads`,
  `Letterboxd URI`, `Watched Date`, `418 books arrive with no finish dates`
  and `what it found` are still written as their own runs — the day the
  bridge grows a `runs` prop, these five call sites are already right.

  Each body run is its own msgid, so the seam survives translation: the Persian
  is split at the same five places and reads straight through them. And the
  body run of all four paragraphs is marked `base: true` rather than left to
  win on length — `rich_text/1` takes its one style from the longest run when
  nothing is marked, which was the body here only by arithmetic, and a Persian
  run that came out shorter than the bold span beside it would set a whole
  paragraph semibold in ink.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
    # The page's whole copy resolved above the sigil, which is how
    # `Kati.Screens.SearchResultStates.content/1` arranges its own four bands
    # and for the same reason: the three eyebrows are read against each other,
    # and a ~MOB block is the wrong place to compare three labels.
    #
    # The subtitle takes a context and the title does not. `THREE EDGE STATES`
    # is three words sitting in the catalogue beside `FIVE STATES`,
    # `THREE VARIANTS`, `four edge states` and half a dozen other reference
    # sheets' subtitles — exactly what `mix gettext.merge` fuzzy-matches a short
    # msgid onto — and nothing on this screen is asserted against a string, so a
    # sheet headed **پنج حالت** is a wrong word no test here would catch. That
    # is screen 89's own argument for `pgettext("screen subtitle", …)` and this
    # is the second sheet to need it. `Import` needs none: the catalogue already
    # carries it for screen 37's heading and for the back pill, it is the same
    # word in the same register, and a second entry would be the disagreement.
    title = gettext("Import")
    subtitle = pgettext("screen subtitle", "THREE EDGE STATES")

    wrong_band = gettext("Wrong guess — back at the grid, choice remembered")
    unrecognised_band = gettext("Unrecognised for the named tile — name what it looks like")
    partial_band = gettext("Partial columns — right source, old export")

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(title, subtitle)}
        {UI.eyebrow(wrong_band)}
        {Kati.Screens.ImportStates.wrong_guess()}
        {SettingsList.eyebrow_muted(unrecognised_band)}
        {Kati.Screens.ImportStates.unrecognised()}
        {SettingsList.eyebrow_muted(partial_band)}
        {Kati.Screens.ImportStates.partial_columns()}
        {Kati.Screens.ImportStates.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The file that was read against the tile that was tapped, and the two ways out.

  Both actions read as buttons and neither is wired — see the moduledoc's
  "Nothing on this board taps" for why. `Something else` is named in the
  sentence rather than drawn as a third control, because the board draws it
  that way: it is the picker's own manual-mapping tile, mentioned as where
  the second tap would land rather than repeated here as a third choice
  competing with the two the board actually draws.
  """
  @spec wrong_guess() :: map()
  def wrong_guess do
    # `Kati.Locale.leading/1` on the paragraph and `base: true` on its body run,
    # the two moves every folded card on this board makes — the moduledoc's
    # "The bold spans are not bold" carries the argument for the mark, and
    # `Kati.Theme.fa_line_height/0` the one for the leading: Vazirmatn's metrics
    # are not Plus Jakarta's, so a paragraph set at the drawing's 1.65 sets
    # Persian lines too close together to read.
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.cream_body(),
      base: true
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    # `Something else` is INTERPOLATED from screen 140's own msgid rather than
    # typed into this sentence, and that is the same fix board 328 made for its
    # count: the sentence names a tile the picker draws, and a tile named one
    # way in the grid and another in the card is how a catalogue starts
    # disagreeing with itself. It is the one string on this board that is copy
    # in both scripts — *Something else* is not a trade name — so it translates
    # where `Goodreads` beside it does not, and `Goodreads` takes
    # `Kati.Locale.ltr/1` because it sits inside a Persian sentence.
    #
    # `pgettext/2` on `You picked `: two words and a trailing space is exactly
    # what `mix gettext.merge` fuzzy-matches onto some other screen's sentence.
    message =
      UI.rich_text([
        {pgettext("wrong import guess", "You picked "), body},
        {Kati.Locale.ltr("Goodreads"), strong},
        {gettext(" and that file is not one. Pick again, or use %{tile} to map it by hand.",
           tile: pgettext("import source", "Something else")
         ), body}
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
        <Row fill_width={true} align="top">
          {UI.symbol("help", size: 18, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            {message}
          </Column>
        </Row>
      </Column>
      <Spacer size={11} />
      {Kati.Screens.ImportStates.picker_grid()}
    </Column>
    """
  end

  @doc """
  Two of screen 140's six source tiles, side by side, neither one marked chosen.

  A `Row` does not wrap, so the pair is two explicit weighted columns rather
  than a grid that would need more of them — the board draws exactly two
  here and this sheet draws exactly two back.
  """
  @spec picker_grid() :: map()
  def picker_grid do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.ImportStates.source_tile("G", "Goodreads", "goodreads_library_export.csv")}
        </Column>
        <Spacer size={12} />
        <Column weight={1.0}>
          {Kati.Screens.ImportStates.source_tile("S", "StoryGraph", "storygraph_export.csv")}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One picker tile: `Kati.Screens.ImportSources.source_letter/1`'s own avatar,
  over the source's name and its export filename.

  Not `Kati.Screens.ImportSources.source_tile/1` whole — that function is
  this same card, letter for letter, but it carries
  `on_tap={{self(), {:source, source.id}}}`, and a specimen that opened the
  picker's own next step would be exactly the navigating-off-the-sheet
  problem `Kati.Screens.MoneyStates` already refused for `Money.service_row/1`.
  The 34pt mono avatar is the safe half — `source_letter/1` carries no tap —
  so it is reused whole and only the card around it is rebuilt without one.
  The filename carries no `max_lines`: the board sets `word-break: break-all`
  rather than truncating, because a filename cut short would stop naming the
  file it is meant to confirm.

  Neither string is wrapped for translation and the moduledoc's Latin section
  says why — both are 140's, one a trade name and one a file a reader has to
  recognise in a picker. `font_family` asks the filename rather than the reader
  all the same, exactly as `Kati.Screens.ImportSources.source_tile/1` does.
  """
  @spec source_tile(String.t(), String.t(), String.t()) :: map()
  def source_tile(letter, name, filename) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.ImportSources.source_letter(letter)}
      <Spacer size={12} />
      <Text
        text={name}
        text_size={13.5}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={filename}
        font_family={Kati.Locale.mono_face(filename)}
        text_size={10.5}
        line_height={1.5}
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  @doc """
  The file that matched a source Kati can name, and it is not the one tapped.

  `error` in `Palette.red/0`, not `help` in gold — see the moduledoc's
  paragraph on the two glyphs. Nothing is imported here, in as many words as
  the icon: red is the one colour on this board that goes nowhere.
  """
  @spec unrecognised() :: map()
  def unrecognised do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft(),
      base: true
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    # `Kati.Screens.ImportRecognised`'s own msgid and not a second spelling of
    # it: 141 draws this exact sentence over the file whose guess was wrong, and
    # the screen that demonstrates the state cannot word it differently from the
    # screen that has it. Built above the sigil because it carries an
    # interpolation — a `%{source}` inside a `~MOB` block's `{}` is a brace the
    # sigil has no reason to read as Elixir's, and every wrapped string on this
    # board that needs a comment has to live out here anyway.
    heading =
      gettext("This looks like a %{source} export", source: Kati.Locale.ltr("Letterboxd"))

    # The two bold runs are COLUMN HEADERS, not copy — see the moduledoc — so
    # they stay Latin and go through `Kati.Locale.ltr/1`, which is what keeps
    # the space between `Letterboxd` and `URI` from resolving against a Persian
    # paragraph. The two joins between them take `pgettext/2`: ` and ` is one
    # word, `It has ` is two, and a msgid that short is what `mix gettext.merge`
    # fuzzy-matches against any line in the catalogue that ends the same way.
    message =
      UI.rich_text([
        {pgettext("before two import column names", "It has "), body},
        {Kati.Locale.ltr("Letterboxd URI"), strong},
        {pgettext("between two import column names", " and "), body},
        {Kati.Locale.ltr("Watched Date"), strong},
        {gettext(" columns, which %{source} files do not. Nothing has been imported.",
           source: Kati.Locale.ltr("Goodreads")
         ), body}
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="top">
          {UI.symbol("error", size: 19, color: Palette.red())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text text={heading} text_size={13.5} font_weight="bold" text_color={:on_surface} />
            <Spacer size={6} />
            {message}
          </Column>
        </Row>
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Column weight={1.0}>
            {Kati.Screens.ImportStates.letterboxd_cta()}
          </Column>
          <Spacer size={8} />
          {SettingsList.action_pill(gettext("Pick again"))}
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  `Use Letterboxd instead`, drawn at `SettingsList.action_pill/1`'s neighbour geometry and inert.

  Not `SettingsList.action_pill/1` itself — that pill is 30pt tall with side
  padding sized to its label; this one is a 40pt full-width CTA the board
  draws in ink, the same `Palette.ink_fill/0` and `Palette.on_ink/0` pairing
  `Kati.Screens.MoneyStates.nothing_set_up/0` uses for its own inert button.

  ## The Persian label is shorter than its msgid, on purpose

  It shares a `Row` with `Pick again`, which is a pill sized to its own label
  and not to the space left over — so the CTA gets what that pill does not
  want, and *دوباره انتخاب کنید* wants about 35pt more of it than `Pick again`
  does. The label carries `max_lines={1}`, so an over-long translation does not
  wrap, it truncates, and a primary action with an ellipsis in it names
  nothing. `Kati.Screens.PickSections`'s *Restore from a backup instead* is the
  precedent and went the same way — the Persian drops *instead* and keeps the
  action, because the card above has already said twice that this file is not
  the one that was asked for.
  """
  @spec letterboxd_cta() :: map()
  def letterboxd_cta do
    # Built above the sigil rather than inside it: the label carries an
    # interpolation now, and a `%{source}` inside a `~MOB` block's `{}` is a
    # brace the sigil has no reason to read as Elixir's.
    label = gettext("Use %{source} instead", source: Kati.Locale.ltr("Letterboxd"))

    ~MOB"""
    <Row
      fill_width={true}
      height={40}
      corner_radius={20}
      background={Palette.ink_fill()}
      align="center"
    >
      <Spacer weight={1.0} />
      <Text
        text={label}
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The right source, an export old enough to be missing one column.

  Names the column (`Date Read`) and what its absence costs (418 books with
  no finish date, silent everywhere a finish date would show), rather than a
  bare "some data may be missing." A reader deciding whether to import a
  four-year-old export needs the second half of that sentence at least as
  much as the first.
  """
  @spec partial_columns() :: map()
  def partial_columns do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft(),
      base: true
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    # `Date Read` is the export's own column header and stays Latin for the
    # moduledoc's reason, so the heading is an interpolation rather than a
    # sentence — and it is the same shape 141 already writes for the same
    # finding, `No %{column} column — everything else maps`, minus the half this
    # card says in its body instead.
    heading = gettext("No %{column} column", column: Kati.Locale.ltr("Date Read"))

    # `Kati.Locale.year/1` on 2019 and `Kati.Locale.number/1` on 418, and the
    # difference between them is the whole rule. 2019 is a date an EXPORTER
    # stamped on a file — `year/1`'s doc argues it at length for a publication
    # year, and 141 puts this same figure through it — so its digits convert and
    # its calendar does not: a Goodreads export from before 2019 is not one from
    # before ۱۳۹۷. 418 is a plain count inside a sentence and takes the reader's
    # own numerals whole. The audit that found this board's Latin could see
    # neither: a bare numeral carries no Latin letters.
    #
    # `gettext/1` with `%{n}` rather than `ngettext/4`, which is the one place
    # this board departs from `Kati.Screens.Import`'s own tallies: 418 is a
    # specimen and not a count of anything, the singular can never render, and a
    # plural form nothing reaches is a second Persian string to keep correct.
    message =
      UI.rich_text([
        {gettext("This is a %{source} export from before %{year}. Everything else maps. ",
           source: Kati.Locale.ltr("Goodreads"),
           year: Kati.Locale.year(2019)
         ), body},
        {gettext("%{n} books arrive with no finish dates", n: Kati.Locale.number(418)), strong},
        {gettext(
           ", so they will not appear in your year or on the calendar — ratings, reviews and shelves are unaffected."
         ), body}
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="top">
          {UI.symbol("help", size: 19, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text text={heading} text_size={13.5} font_weight="bold" text_color={:on_surface} />
            <Spacer size={6} />
            {message}
          </Column>
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The board's own argument for itself, dashed rather than shadowed.

  Not `Kati.UI.SettingsList.note/2`, which `Kati.Screens.ImportSources` uses
  for its own dashed footer — that helper's `text` prop is a plain string, so
  `what it found` could only land there unbolded, and the board's whole point
  is which two words carry the weight. This is the same shape drawn by hand
  so `UI.rich_text/1` has somewhere to put the emphasis.

  `Palette.border/0` is a 16% ink alpha in both modes, never the fully
  transparent light value `Kati.Theme.Palette` warns against passing
  unconditionally — so `border_width` and `border_color` are safe here with
  no light/dark branch, unlike `card_hairline/0`.
  """
  @spec footnote() :: map()
  def footnote do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft(),
      base: true
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    # `pgettext/2` on the bold half: `what it found` is three words with no
    # terminating punctuation, which is the shape `mix gettext.merge` fuzzy
    # matches onto a longer line, and this is the one run on the board whose
    # exact words are the board's argument.
    #
    # The two quoted specimens are translated rather than left in English — both
    # are COPY being quoted, one as the wording this sheet refuses and one as
    # the wording it draws, and a Persian page that criticised an English
    # sentence would be criticising a sentence it never shows. The guillemets go
    # in the msgstr rather than through `Kati.Locale.quoted/1`, because they are
    # punctuation inside a sentence and not a name being quoted — which is how
    # every other quoted specimen in the catalogue is already written.
    # `Letterboxd` inside the second is interpolated so the footnote and the
    # card it quotes cannot come out naming two different services.
    message =
      UI.rich_text([
        {gettext("Every one of the three names "), body},
        {pgettext("the bold half of a footnote", "what it found"), strong},
        {gettext(
           " rather than what failed. “Unrecognised format” tells a switcher nothing; “this looks like %{source}” hands them the next tap.",
           source: Kati.Locale.ltr("Letterboxd")
         ), body}
      ])

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {message}
      </Column>
    </Row>
    """
  end
end
