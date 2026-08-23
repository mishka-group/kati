defmodule Kati.Screens.WeightStates do
  @moduledoc """
  Screen 110 — the states of screen 109, on one sheet pushed under Settings.

  Screen 109 draws one weight series in good health. This is the board that
  draws the ways it goes quiet: the log with nothing in it, the log with
  exactly one reading, the log with three weeks missing out of the middle, one
  stored reading under all three units, and the page in dark. Five eyebrows
  head six specimens — `Dark` carries two, the reading card and the chart card
  — which is what the mono subtitle counts.

  It is a reference sheet in screen 27's manner, so it is pushed under Settings
  the way 27, 67 and 75 are. The board draws `Health` in its back pill because
  it was traced from 109's chrome; the pill has to name where back actually
  goes, and from a states sheet that is Settings.

  ## One entry says so in words, because a chart of one has nothing to say

  `Kati.Health.Reading.delta/2` answers `nil` for a first reading and
  `Kati.Screens.Weight.delta/1` answers `nil` by drawing nothing, so 109's
  *list* already says *no trend* by leaving the column empty. The chart cannot
  say it at all. `Kati.Screens.Weight.bars/0` normalises against the series'
  own range — `span = max(high - low, 1)` — so a series of one has no range,
  every reading is both the low and the high, and the single bar comes out at
  the floor of 0.35 regardless of what was weighed. A bar at 35% of a track
  that stands for nothing is the same false promise a flat line makes: that
  there is something here to compare against.

  So this band prints the figure and a sentence and draws no chart. The
  sentence is `Kati.UI.rich_text/1`, which concatenates its runs and applies one
  style — the bold opening loses its weight rather than orphaning itself on a
  line of its own. That trade is argued where the helper lives.

  ## A gap is outlined rather than bridged, and the outline is a proposal

  `Kati.Health.Reading`'s own moduledoc settles the first half: *there is one
  row per weighing and nothing between them, so `delta/2` compares a reading
  with the one before it and never interpolates.* A line drawn across three
  unlogged weeks would be three measurements nobody took. The hollow bar is
  that refusal given a shape — the slot is drawn, the value is not.

  The second half is why this band is a proposal rather than a report of
  something 109 does. `Kati.Screens.Weight.bars/0` maps over **readings**, not
  over weeks: one bar per row it read. Three unlogged weeks therefore produce
  no bars at all on the real screen, and the readings either side of them stand
  shoulder to shoulder with nothing between them to notice. There is no hole to
  outline. Indexing `bars/0` by date rather than by row is the change this band
  is asking for, and until that happens the gap is drawn here and nowhere else.

  Which is also the honest note about the three heights.
  `Kati.Health.WeightSample.bars/0` is one list of fourteen, and this sheet
  outlines three of its entries rather than deleting them, so the hollow bars
  carry heights the fixture already had. What the empty fill says is *no
  reading here*. The height it happens to have is the fixture's and is not a
  claim about a week nobody weighed.

  ## Unit switching is display-only, and this band proves it rather than illustrating it

  `Kati.Health.Reading` stores grams and only grams, and `Kati.Health.put_unit/1`
  is one line about it: *Converts nothing.* So the three rows here are
  `Kati.Health.Reading.figure/2` called three times on a single integer —
  `reading/0`, which is the `:grams` field of the newest of
  `Kati.Screens.Weight.drawn_entries/0`. Nothing is transcribed and nothing is
  rounded twice. If the conversion in `Reading` ever moves, all three rows move
  with it, which is the only way a sheet can claim that the stored value does
  not.

  `kg` carries the tick rather than whatever `Kati.Health.unit/0` answers, for
  27's reason: a specimen is a picture of a state, not a report that the app is
  in it, and a band that followed the reader's own preference would show a
  different sheet on every device.

  ## Where the board and screen 109 disagree, and which one wins

  109 wins in all four, on 67's argument — a sheet that redrew a band its own
  way would report a difference the app does not have.

    * **The bars are grey, not gold.** The board paints them `#D3B98A` in light
      and `#4E4437` in dark; `Kati.Screens.Weight.bar/1` paints
      `Kati.Theme.Palette.bar_ink/0`. Neither of the board's two values is a
      token, so the gold is not reachable from a screen at all — and reaching
      around the palette for it would put a chart on this sheet that 109 does
      not draw. The dark inset takes the same token's `:dark` arm rather than a
      second colour.
    * **The newest week is not tipped in ink.** The board fills the last bar
      `#1A1917` in both modes. `bar/1` paints every bar alike and so does this.
    * **The track is 96 tall, not 88.** `bar/1` scales its fraction by 96 and
      109's row is 96 with 3pt gaps at radius 2, where the board draws 88 with
      5pt gaps at radius 4. A 96-scaled height inside an 88-tall row clips, so
      the metrics are 109's throughout and the gap bars match them.
    * **Stones print `11st 13.6`.** The board writes `11 st 13.6`.
      `Kati.Health.Reading.figure/2` is the function the app prints from, and
      spelling the spaced form out here would be a second copy of a conversion
      that can quietly disagree with the first.

  ## The gridlines, and the one thing this sheet stacks

  The three rules behind the bars are `rgba(26,25,23,.05)` on the board and
  `rgba(245,242,238,.06)` in its dark inset. The palette's nearest named thing
  is `Kati.Theme.Palette.hairline/1` — the 7% rule a list draws between two
  rows — which is what a gridline is, so light comes out two units stronger
  than drawn and dark within one. They are `Kati.Components.MishkaSeparator` at
  `render: :box` for the reason `Kati.UI.SettingsList.hairline/1` gives: the
  default divider antialiases a 1dp line into a lighter one.

  Rules and bars share a `Box`, which stacks its children — the same thing
  `Kati.Screens.Pushed.chrome/2` relies on to float the back pill over a
  screen's content. Both children are given the full track height, so neither
  depends on how the box aligns them.

  ## Nothing here reads the store, and nothing here taps

  `Kati.Screens.Weight.entries/0`, `latest/0` and `bars/0` all read
  `Kati.Health.Reading` and fall back to the drawing. This sheet calls
  `drawn_entries/0` and `Kati.Health.WeightSample.bars/0` instead, which are the
  drawing unconditionally — 75's rule, for 27's reason. A board that showed
  four states on a fresh install and five on a used one is the opposite of what
  a reference sheet is for.

  `Log a weight` is drawn and inert. This module defines no `handle_tap/2`, so
  `Kati.Screens.Root.rescue_tap/3` has no dead tag to report, and the footnote
  naming screen 54 is text rather than a link for the same reason: a sheet that
  navigated would be acting on a state the app is not in.
  """

  use Kati.Screens.Pushed, back: "Health"

  alias Kati.Health.Reading
  alias Kati.Health.WeightSample
  alias Kati.Screens.Weight
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Which of `Kati.Health.WeightSample.bars/0`'s fourteen weeks the gap band
  # leaves unlogged, by position. Three consecutive ones, which is what the
  # card's own caption counts.
  @gap [5, 6, 7]

  # The three display units, in the order the board lists them, and the one it
  # ticks. Not `Kati.Health.unit/0` — see the moduledoc.
  @units [:kg, :lb, :st]
  @selected :kg

  # 109's chart track. `Kati.Screens.Weight.bar/1` scales its fraction by this
  # number and bakes its colour in, so a bar this sheet has to paint itself
  # has to restate the arithmetic; `bar_height/1` is the one place it does.
  @track 96

  @impl true
  @spec load(term()) :: term()
  def load(socket), do: Mob.Socket.assign(socket, :grams, reading())

  @doc """
  The one stored value every band on this sheet is drawn from, in grams.

  The newest of `Kati.Screens.Weight.drawn_entries/0` — the drawing's four,
  unconditionally, rather than `entries/0`, which reads the shelf. Taking a
  single integer and formatting it five times is what makes the unit band a
  proof instead of a picture: the hero, the three unit rows and the dark inset
  cannot disagree about what was weighed, because there is only one weighing.
  """
  @spec reading() :: pos_integer()
  def reading, do: Weight.drawn_entries() |> hd() |> Map.fetch!(:grams)

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    g = assigns.grams

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
        {SettingsList.title("Weight", "SIX STATES")}
        {UI.eyebrow("No entries")}
        {Kati.Screens.WeightStates.empty()}
        {SettingsList.eyebrow_muted("One entry — no trend, said in words")}
        {Kati.Screens.WeightStates.one_entry(g)}
        {SettingsList.eyebrow_muted("A gap in the data")}
        {Kati.Screens.WeightStates.gap_chart()}
        {SettingsList.eyebrow_muted("Unit switched")}
        {Kati.Screens.WeightStates.units(g)}
        {Kati.Screens.WeightStates.units_note()}
        {SettingsList.eyebrow_muted("Dark")}
        {Kati.Screens.WeightStates.dark(g)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Nothing logged yet: a disc, two lines and the way in.

  Not `Kati.Screens.States.empty/1`, and the difference is metrics rather than
  taste — 27 draws a 64pt disc under a 17pt title with a glyph inside its
  button and a secondary line under it, all of which this card is a step
  smaller than or does without. Passing a map with two dead keys into a helper
  built for a different drawing would have made both drawings harder to read.

  The copy is the one thing on this sheet that argues for logging: *One reading
  starts the record. Two make a trend.* — which is the same fact the band below
  it states from the other side.
  """
  @spec empty() :: map()
  def empty do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={52} height={52} corner_radius={16} background={Palette.paper()} align="center">
            {UI.symbol("monitor_weight", size: 24, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text="Nothing logged yet"
          text_size={14.5}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text="One reading starts the record. Two make a trend."
          text_size={12.5}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={16} />
        <Row
          fill_width={true}
          height={44}
          corner_radius={22}
          background={Palette.ink_fill()}
          align="center"
        >
          <Spacer weight={1.0} />
          <Text
            text="Log a weight"
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One reading, and the sentence that stands where the chart would.

  See the moduledoc for why there is no chart here: a series of one has no
  range to normalise against, so the bar `Kati.Screens.Weight.bars/0` would
  produce carries no information and looks as though it does.
  """
  @spec one_entry(pos_integer()) :: map()
  def one_entry(grams) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.WeightStates.weight_figure(grams, :light)}
        <Spacer size={13} />
        {Kati.Screens.WeightStates.no_trend()}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The mono figure with its unit on the numeral's baseline.

  Not `Kati.Screens.Weight.hero/1`, which is the whole hero — a mono label
  above, a 38pt sans figure, and a delta row under it coloured by direction.
  Two of those three are exactly what a single reading has nothing to put in,
  so this band draws the part that survives.

  `mode` picks the size as well as the colours, because the board sets the dark
  inset a step smaller throughout — 26/14 against 30/15 — and it is smaller for
  being an inset rather than for being dark. Keeping the pair in one place is
  what stops the two from drifting apart.

  The lift is `(number - unit) / 5`, which is `Kati.UI.number_with_unit/3`'s own
  first guess and is what these two size pairs want: `align="bottom"` bottoms
  out text *boxes*, and a small unit beside a big number lands below the
  number's baseline by roughly a fifth of the difference between them.
  """
  @spec weight_figure(pos_integer(), :light | :dark) :: map()
  def weight_figure(grams, mode) do
    {size, unit_size} = if mode == :dark, do: {26, 14}, else: {30, 15}
    # `@selected` cannot be written inside the sigil — `@` there is an assign.
    shown = @selected

    number = ~MOB"""
    <Text
      text={Reading.figure(grams, shown)}
      font_family="mono"
      text_size={size}
      font_weight="medium"
      letter_spacing={-0.03}
      text_color={Palette.ink(mode)}
      max_lines={1}
    />
    """

    unit = ~MOB"""
    <Text
      text={Reading.unit_label(shown)}
      font_family="mono"
      text_size={unit_size}
      text_color={Palette.sub(mode)}
      max_lines={1}
    />
    """

    UI.number_with_unit(number, unit, (size - unit_size) / 5)
  end

  @doc """
  The sentence that replaces the chart, with its opening emphasised.

  `Kati.UI.rich_text/1` rather than a `Row` of two `Text` nodes: a `Row` does
  not wrap, so the long half would become one unbreakable box and orphan itself
  off the right edge. The cost is that the emphasis is concatenated away — a
  bold that comes out regular reads as plain typography, where an orphaned
  clause reads as a broken layout.

  The base style is the body run's because it is the longer of the two, which
  is `rich_text/1`'s own tie-break and the answer wanted here.
  """
  @spec no_trend() :: map()
  def no_trend do
    body = [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft()]

    UI.rich_text([
      {"One reading, so no trend yet", [font_weight: "bold", text_color: Palette.ink()]},
      {" — a chart with a single point would be a flat line that means nothing.", body}
    ])
  end

  @doc """
  Three weeks missing from the middle, outlined rather than bridged.

  The card is 109's chart with its axis labels swapped for the line that says
  what the hollow bars mean. 109 prints `4 MAY` and `TODAY` under its bars
  because they orient a reader looking at a series; this band is about one
  stretch inside the series, and a footnote saying *outlined, never
  interpolated* is what the reader needs instead.
  """
  @spec gap_chart() :: map()
  def gap_chart do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.WeightStates.chart(:light)}
        <Spacer size={13} />
        {Kati.Screens.WeightStates.info_line("Three weeks unlogged — outlined, never interpolated")}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Fourteen weeks over three rules, three of them unlogged.

  The heights are `Kati.Health.WeightSample.bars/0` — the same list
  `Kati.Screens.Weight.bars/0` falls back to, so this is 109's chart and not a
  second series that happens to look like it. A logged week in light is
  `Kati.Screens.Weight.bar/1` itself, which is the reuse that matters: the day
  109's bar changes shape, this sheet's bars change with it and the comparison
  cannot go stale.

  Dark cannot call it. `bar/1` resolves `Kati.Theme.Palette.bar_ink/0` through
  the installed mode, which is light for the five bands above the inset, so the
  inset's bars are painted here from the same token's explicit `:dark` arm —
  the same reason `Kati.Screens.AlbumDetailStates.dark/1` takes the palette's
  `:dark` arm rather than switching the theme for one card.
  """
  @spec chart(:light | :dark) :: map()
  def chart(mode) do
    track = @track

    bars =
      WeightSample.bars()
      |> Enum.with_index()
      |> Enum.map(fn {fraction, week} ->
        Kati.Screens.WeightStates.chart_bar(fraction, week, mode)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={3} />")

    ~MOB"""
    <Box fill_width={true} height={track}>
      {Kati.Screens.WeightStates.gridlines(mode)}
      <Row fill_width={true} height={track} align="bottom">
        {bars}
      </Row>
    </Box>
    """
  end

  @doc """
  One week: logged or not, light or dark.

  The decision is by position rather than by value, because an unlogged week has
  no value — see the moduledoc on why the height it is drawn at is the
  fixture's rather than a claim.
  """
  @spec chart_bar(float(), non_neg_integer(), :light | :dark) :: map()
  def chart_bar(fraction, week, mode) do
    cond do
      week in @gap -> Kati.Screens.WeightStates.gap_bar(fraction, mode)
      mode == :dark -> Kati.Screens.WeightStates.dark_bar(fraction)
      true -> Weight.bar(fraction)
    end
  end

  @doc """
  A week with no reading: the slot, drawn hollow.

  `Kati.Theme.Palette.hairline_strong/1` is the board's own `rgba(26,25,23,.1)`
  exactly, and its dark arm is the same 10% alpha over ink-on-dark — which is
  the palette's `:alpha` rule, so the outline survives the ground rather than
  needing a second colour.

  The board fills these three bars solid in its dark inset. That is the one
  place this sheet does not follow it: the gap is the state the band exists to
  show, and a version of it that closes in dark would say the app forgets what
  it does not know when the lights go out.
  """
  @spec gap_bar(float(), :light | :dark) :: map()
  def gap_bar(fraction, mode) do
    height = Kati.Screens.WeightStates.bar_height(fraction)
    border = Palette.hairline_strong(mode)

    ~MOB"""
    <Column weight={1.0} align="bottom">
      <Box
        fill_width={true}
        height={height}
        corner_radius={2}
        background={Palette.transparent()}
        border_width={1.5}
        border_color={border}
      />
    </Column>
    """
  end

  @doc """
  A logged week on the inset's near-black card.

  `Kati.Screens.Weight.bar/1`'s node with the colour taken through the
  palette's `:dark` arm; see `chart/1` for why the reuse stops at the colour.
  """
  @spec dark_bar(float()) :: map()
  def dark_bar(fraction) do
    height = Kati.Screens.WeightStates.bar_height(fraction)

    ~MOB"""
    <Column weight={1.0} align="bottom">
      <Box fill_width={true} height={height} corner_radius={2} background={Palette.bar_ink(:dark)} />
    </Column>
    """
  end

  @doc """
  A fraction of the series' range, as a height on 109's track.

  The one piece of arithmetic this file copies from `Kati.Screens.Weight.bar/1`
  rather than calling, and the reason is that `bar/1` paints its colour and
  returns a finished node — there is no way to ask it for a height and supply
  the fill. The floor of 4 is 109's too: a bar rounded to nothing reads as a
  week that was skipped, which is precisely the thing this sheet draws
  differently.
  """
  @spec bar_height(float()) :: pos_integer()
  def bar_height(fraction), do: max(round(fraction * @track), 4)

  @doc """
  The three rules a bar chart is read against.

  `Kati.Components.MishkaSeparator` at `render: :box`, which is the same
  primitive `Kati.UI.SettingsList.hairline/1` uses and for its reason — the
  default `:divider` antialiases a 1dp line and comes out several units lighter
  along one pixel row. A gridline and a row separator are the same mark, so
  they take the same token; see the moduledoc for the two units light gives
  away by doing that.

  The spacers are 47 and 46 rather than two equal halves because three 1pt
  rules and two gaps have to add to 96, and 96 is odd once the rules are
  removed.
  """
  @spec gridlines(:light | :dark) :: map()
  def gridlines(mode) do
    rule =
      Kati.Components.MishkaSeparator.separator(
        color: Palette.hairline(mode),
        thickness: 1,
        render: :box
      )

    ~MOB"""
    <Column fill_width={true}>
      {rule}
      <Spacer size={47} />
      {rule}
      <Spacer size={46} />
      {rule}
    </Column>
    """
  end

  @doc """
  A footnote under a card: the `info` glyph and a sentence.

  Not `Kati.UI.SettingsList.note/2`, which is the bordered pill the settings
  screens use to hold a paragraph apart from the list above it. These two lines
  belong to the card they sit under — they say what its picture means — so they
  are set at the drawing's smaller 11.5pt with no frame around them, the way
  109's own chart caption is.
  """
  @spec info_line(String.t()) :: map()
  def info_line(text) do
    ~MOB"""
    <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
      {UI.symbol("info", size: 15, color: Palette.tertiary())}
      <Spacer size={9} />
      <Text text={text} text_size={11.5} line_height={1.45} text_color={Palette.sub()} weight={1.0} />
    </Row>
    """
  end

  @doc """
  One reading under all three units, converted nowhere.

  `Kati.UI.SettingsList.card/1` and `row/4` unchanged: this is a settings group
  and it should be the same object the Settings subtree is built from, down to
  the 13pt row padding and the hairline the last row does without. What the
  rows carry is not a setting though — every value is
  `Kati.Health.Reading.figure/2` over the one integer `reading/0` returns, so
  the band demonstrates the claim in its footnote rather than illustrating it.

  The body is set in mono rather than through `Kati.UI.SettingsList.body/2`,
  which is 13.5pt semibold sans: these are figures in a column and they have to
  line up with each other, which is the whole reason the design sets numbers in
  DM Mono anywhere.
  """
  @spec units(pos_integer()) :: map()
  def units(grams) do
    last = List.last(@units)

    rows =
      Enum.map(@units, fn unit ->
        tick =
          if unit == @selected, do: UI.symbol("check", size: 18, color: Palette.ink())

        SettingsList.row(
          Kati.Screens.WeightStates.unit_tile(unit),
          Kati.Screens.WeightStates.unit_value(grams, unit),
          tick,
          rule: unit != last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 30pt tile a unit row leads with, carrying two mono letters.

  `Kati.UI.SettingsList.icon_tile/1` is the tile every other settings row uses
  and it takes an icon *name*, resolving it through `Kati.Icons.glyph!/1`.
  There is no Material Symbol for a kilogram, and there should not be — `kg`,
  `lb` and `st` are words, and setting them in the mono face is what makes them
  read as units rather than as an abbreviation someone chose. So the tile is
  built here at the helper's own geometry: 30 square, radius 9, and the paper
  fill inverting to ink for the unit in force.
  """
  @spec unit_tile(:kg | :lb | :st) :: map()
  def unit_tile(unit) do
    selected? = unit == @selected
    background = if selected?, do: Palette.ink_fill(), else: Palette.paper()
    colour = if selected?, do: Palette.on_ink(), else: Palette.ink_soft()

    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={background} align="center">
      <Text
        text={Reading.unit_label(unit)}
        font_family="mono"
        text_size={11}
        text_color={colour}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  The same stored grams, printed in one unit.

  `Kati.Health.Reading.figure/2` and nothing else — the unit in force takes
  full ink and the other two recede to `Kati.Theme.Palette.sub/0`, which is how
  the row says *this is what you would see* without hiding what you would see
  instead.
  """
  @spec unit_value(pos_integer(), :kg | :lb | :st) :: map()
  def unit_value(grams, unit) do
    colour = if unit == @selected, do: Palette.ink(), else: Palette.sub()

    ~MOB"""
    <Text
      text={Reading.figure(grams, unit)}
      font_family="mono"
      text_size={13.5}
      text_color={colour}
      max_lines={1}
    />
    """
  end

  @doc """
  Where the unit comes from, and what switching it does not touch.

  Screen 54 is named as text. There is no link node on this side and a footnote
  that pushed into Settings would be a fifth way to reach one screen — but more
  than that, a reference sheet whose footnotes navigated would be acting rather
  than describing.
  """
  @spec units_note() :: map()
  def units_note do
    note =
      Kati.Screens.WeightStates.info_line(
        "Follows 54 → Content → Units. Stored readings never change — only the display."
      )

    ~MOB"""
    <Column fill_width={true}>
      {note}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The page in dark, reduced to the two cards that carry a number.

  The reading and the chart, because those are the two surfaces screen 28's
  rules actually touch on a weight page: the page drops to `#121110`, a card
  lifts on `Kati.Theme.Palette.card_hairline/1` where light gives it a shadow,
  and the mono figure inverts across the ramp while the bars move one step
  along it. Every colour is taken through the palette's explicit `:dark` arm,
  so the inset draws dark on a light page without a theme switch that would
  repaint the four bands above it.

  The chart is `chart/1` again rather than a second drawing, so the gap stays
  outlined here too — see `gap_bar/2` for why that is the one place the board
  is not followed.
  """
  @spec dark(pos_integer()) :: map()
  def dark(grams) do
    ~MOB"""
    <Column fill_width={true} background={Palette.paper(:dark)} corner_radius={22} padding={16}>
      <Column
        fill_width={true}
        background={Palette.card(:dark)}
        corner_radius={18}
        padding={14}
        border_width={1}
        border_color={Palette.card_hairline(:dark)}
      >
        {Kati.Screens.WeightStates.weight_figure(grams, :dark)}
      </Column>
      <Spacer size={13} />
      <Column
        fill_width={true}
        background={Palette.card(:dark)}
        corner_radius={18}
        padding={14}
        border_width={1}
        border_color={Palette.card_hairline(:dark)}
      >
        {Kati.Screens.WeightStates.chart(:dark)}
      </Column>
    </Column>
    """
  end
end
