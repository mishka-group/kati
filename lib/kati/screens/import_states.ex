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

  ## The bold spans are not bold

  As in `Kati.Screens.MoneyStates`: `Kati.UI.rich_text/1` concatenates its
  runs and applies the longest one's style, because `MobText` takes a
  `String` and the bridge has no `AnnotatedString`. `Goodreads`,
  `Letterboxd URI`, `Watched Date`, `418 books arrive with no finish dates`
  and `what it found` are still written as their own runs — the day the
  bridge grows a `runs` prop, these five call sites are already right.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
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
        {SettingsList.title("Import", "THREE EDGE STATES")}
        {UI.eyebrow("Wrong guess — back at the grid, choice remembered")}
        {Kati.Screens.ImportStates.wrong_guess()}
        {SettingsList.eyebrow_muted("Unrecognised for the named tile — name what it looks like")}
        {Kati.Screens.ImportStates.unrecognised()}
        {SettingsList.eyebrow_muted("Partial columns — right source, old export")}
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
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"You picked ", body},
        {"Goodreads", strong},
        {" and that file is not one. Pick again, or use Something else to map it by hand.", body}
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
        font_family="mono"
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
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"It has ", body},
        {"Letterboxd URI", strong},
        {" and ", body},
        {"Watched Date", strong},
        {" columns, which Goodreads files do not. Nothing has been imported.", body}
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
            <Text
              text="This looks like a Letterboxd export"
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
            />
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
          {SettingsList.action_pill("Pick again")}
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
  """
  @spec letterboxd_cta() :: map()
  def letterboxd_cta do
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
        text="Use Letterboxd instead"
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
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"This is a Goodreads export from before 2019. Everything else maps. ", body},
        {"418 books arrive with no finish dates", strong},
        {", so they will not appear in your year or on the calendar — ratings, reviews and shelves are unaffected.",
         body}
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
            <Text
              text="No Date Read column"
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
            />
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
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"Every one of the three names ", body},
        {"what it found", strong},
        {" rather than what failed. “Unrecognised format” tells a switcher nothing; “this looks like Letterboxd” hands them the next tap.",
         body}
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
