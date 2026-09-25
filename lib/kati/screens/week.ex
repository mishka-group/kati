defmodule Kati.Screens.Week do
  @moduledoc """
  Screen 17 — Calendar, week.

  Built to `test/design/screens/17.html`. Seven `flex:1` lanes of blocks
  with no titles in them: height is duration, colour is section, and the only
  text a block carries is its start hour in mono. Names live in the card
  underneath, for whichever lane you tap — which is what the `touch_app` line
  between them says out loud.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active.

  ## Two eyebrows, two dashes

  `Kati.UI.eyebrow/2` always draws the accent dash, and the drawing uses it
  for the named day. "Load this week" gets a `#C4BDB3` dash instead — the
  design's way of marking a section that reports rather than points at
  something happening — so that one is drawn here.

  ## The sentence under the bars

  The drawing sets `9 items` in bold inside a running sentence. A `Text` node
  carries one style, and this bridge has no rich-text run, so the three
  fragments the design writes are composed into a single wrapping paragraph
  and the inline bold is lost. Splitting it into three `Text` nodes in a `Row`
  would keep the weight and lose the wrap, which is the worse trade for a
  sentence this long.

  ## What is Persian on this page, and what is still 10 – 16 Aug

  Two strings here are this file's own — the `touch_app` line and the load
  chart's eyebrow — and both go through `Kati.Gettext`. Every other word on the
  page is `Kati.Calendar.SampleWeek`'s, and nothing under `lib/kati/calendar/`
  has been folded yet: `Kati.Screens.Agenda`'s moduledoc records the same
  half-state for `Kati.Calendar.SampleAgenda` and `Kati.Screens.MonthGrid`'s
  for `Kati.Calendar.SampleMonth`. `gettext/1` cannot take a variable, so those
  strings can only be wrapped where they are written.

  What this file could reach it did: every clock — the one inside each block
  and the four in the card — every mono face on the page, the tracking, the
  paragraph's leading and its isolate, the two header chevrons, the load axis's
  seven letters and the eyebrow's case.

  What it could not, it left whole rather than half-converted, and that is not
  an oversight. The seven lane names, the seven day numbers, the header's range
  and the eyebrow's `Thu 13 · 9 items` are ONE fixture — the week of 10–16
  August 2026. Mordad 1405 runs 23 July – 22 August 2026, so running
  `Kati.Locale.number/1` over the lane headers would print ۱۰ for a day that is
  not the tenth of anything the reader counts;
  `Kati.Locale.day_of_month/1`'s doc names that exact defect on screen 02 and
  screen 16's moduledoc carries the long version. A grid and its dates convert
  together, in the module that lays them out.

  The load chart's seven letters are the exception, and they are not an
  inconsistency: a weekday INITIAL carries no date, so it is a locale question
  with a locale answer. `axis/0` builds them off seven dates whose weekday is
  the only thing read, exactly as `Kati.Screens.MonthGrid.weekdays/0` builds
  the same axis one screen over.

  The switcher's four labels are deliberately still Latin —
  `Kati.Screens.ViewSwitcher.bar/1` builds each segment's tap tag out of the
  word it prints — and `Kati.Screens.Agenda`'s moduledoc carries that argument
  in full.

  mishka-group/kati#103.
  """
  use Kati.Screens.Root, root: :calendar
  use Gettext, backend: Kati.Gettext

  alias Kati.Calendar.SampleWeek
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # The Monday the drawing's week opens on — 10 August 2026, the `MON` lane
  # `Kati.Calendar.SampleWeek.lanes/0` numbers 10. Only its WEEKDAY is ever
  # read; the date itself never reaches the screen, which is the same contract
  # `Kati.Screens.MonthGrid`'s `@first_column` states for the grid's header.
  @first_lane ~D[2026-08-10]

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :week, SampleWeek.week())

  @doc false
  def content(assigns) do
    week = assigns.week

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Week.header(week)}
        {Kati.Screens.Week.switcher()}
        {Kati.Screens.Week.lanes(week)}
        {UI.eyebrow(week.selected_label)}
        {Kati.Screens.Week.events(week)}
        {Kati.Screens.Week.hint()}
        {Kati.Screens.Week.muted_eyebrow(pgettext("eyebrow", "Load this week"))}
        {Kati.Screens.Week.load_card(week)}
      </Column>
    </Scroll>
    """
  end

  # Last week and next week, and under `rtl` the two glyphs swap.
  # `layout_direction` mirrors the Row — the pair moves to the left edge and the
  # range to the right — but it cannot mirror a PICTURE, so a chevron left as
  # drawn goes on pointing at the week a Persian reader has already left. In
  # reading order the pair is still previous-then-next, so previous points back
  # along the line (right, in Persian) and next points forward.
  #
  # `forward_chevron/0` is the app's answer to "the way this page moves
  # forward". Its opposite has no helper — `Kati.Locale.back_glyph/0` is the
  # arrow and `Kati.Screens.Pushed.back_glyph/0` is the pill's iOS chevron —
  # so it is `pick/2` with both glyphs at the call site, which is what that
  # function's doc asks for. Screen 16's header is the same pair.
  #
  # The range keeps its Latin tightening only in Latin: the same fraction of an
  # em applied to Vazirmatn pulls the letters apart at the joins, which is a
  # different word rather than a tighter one.
  @doc false
  def header(week) do
    previous = Kati.Locale.pick("chevron_left", "chevron_right")
    upcoming = Kati.Locale.forward_chevron()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={week.range}
          text_size={22}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {UI.symbol(previous, size: 22, color: Palette.sub())}
        <Spacer size={8} />
        {UI.symbol(upcoming, size: 22, color: Palette.ink())}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  # These four stay in Latin, and it is not an oversight — see the moduledoc.
  # `Kati.Screens.ViewSwitcher.bar/1` builds each segment's tap tag out of the
  # label it prints and `ViewSwitcher.screen/1` routes on the English word, so
  # a `gettext/1` here renames three live controls per language: the strip goes
  # dead under `:fa` and the tags fail `test/kati/screen_tap_sweep_test.exs`'s
  # "no control is named after the word printed on it". The translation waits
  # on a stable tag in the module that builds it, and screens 16 and 30 draw
  # the same strip and want it too.
  @doc false
  def switcher do
    bar =
      Kati.Screens.ViewSwitcher.bar([
        {"Day", false},
        {"Week", true},
        {"Month", false},
        {"Agenda", false}
      ])

    ~MOB"""
    <Column fill_width={true}>
      {bar}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def lanes(week) do
    columns =
      week.lanes
      |> Enum.map(fn lane -> Kati.Screens.Week.lane(lane) end)
      |> Enum.intersperse(lane_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {columns}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def lane_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def lane(lane) do
    ~MOB"""
    <Column weight={1.0}>
      {Kati.Screens.Week.lane_header(lane)}
      <Spacer size={6} />
      {Kati.Screens.Week.blocks(lane.blocks)}
    </Column>
    """
  end

  # Only the selected lane's header sits on a card; the rest are bare paper.
  #
  # The face asks the NAME, not the reader. `kati_mono.ttf` carries no
  # Arabic-script glyph, so a Persian lane name set in `mono` is handed to
  # Android's own substitute face and lands in a typeface that is not Kati's —
  # but `MON` is ASCII and DM Mono has every letter of it, so the Latin strip
  # is untouched and the slot is already right on the day
  # `Kati.Calendar.SampleWeek` folds. The tracking asks the reader instead,
  # because that is the question it is: 0.06em opens the gaps between Latin
  # capitals and breaks the joins between Arabic-script letters.
  #
  # `lane.day` is NOT put through `Kati.Locale.number/1`, and the moduledoc
  # says why at length: it is the Gregorian day of a Gregorian week, and ۱۰
  # over a Persian lane would be the right digits counting the wrong calendar.
  @doc false
  def lane_header(lane) do
    background = if lane.selected?, do: Palette.card(), else: Palette.transparent()
    shadow = if lane.selected?, do: "0 1 2 0 #0D1A1917", else: nil

    ~MOB"""
    <Column
      fill_width={true}
      corner_radius={12}
      background={background}
      shadow={shadow}
      padding_top={7}
      padding_bottom={9}
    >
      <Box fill_width={true} align="center">
        <Text
          text={lane.name}
          font_family={Kati.Locale.mono_face(lane.name)}
          text_size={9.5}
          letter_spacing={Kati.Locale.tracking(0.06)}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Box>
      <Spacer size={4} />
      <Box fill_width={true} align="center">
        <Text
          text={lane.day}
          text_size={14}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
      </Box>
    </Column>
    """
  end

  @doc false
  def blocks(blocks) do
    ~MOB"""
    <Column fill_width={true}>
      {blocks
       |> Enum.map(fn block -> Kati.Screens.Week.block(block) end)
       |> Enum.intersperse(Kati.Screens.Week.block_gap())}
    </Column>
    """
  end

  @doc false
  def block_gap, do: ~MOB"<Spacer size={4} />"

  # `border-left: 2.5px solid` is a real child, not a border prop: the bridge's
  # border draws all four edges, and the drawing wants only the leading one.
  # The Row's corner_radius clips it, which is exactly what a bordered box with
  # a radius does in the browser.
  #
  # The one label a block carries is its start hour, and a clock converts where
  # a date does not: 08 is eight in the morning in every calendar, so nothing
  # about it depends on the fixture's Gregorian week. `Kati.Locale.number/1`
  # is what `Kati.Screens.AddMedication.time_chip/2` puts its own clocks
  # through, and the face follows the CONVERTED string for the reason it gives:
  # `kati_mono.ttf` carries none of U+06F0–U+06F9, so `۰۸` asked for in DM Mono
  # comes back in Android's substitute face, while the English `08` stays in DM
  # Mono with no second branch here.
  @doc false
  def block(block) do
    style = SampleWeek.style(block.section)
    height = block.height
    background = style.background
    rule = style.rule
    shadow = style.shadow
    hour = Kati.Locale.number(block.hour)

    ~MOB"""
    <Row
      fill_width={true}
      height={height}
      corner_radius={9}
      background={background}
      shadow={shadow}
      align="top"
    >
      <Box width={2.5} height={height} background={rule} />
      <Column padding_left={6} padding_right={6} padding_top={7} padding_bottom={7}>
        <Text
          text={hour}
          font_family={Kati.Locale.mono_face(hour)}
          text_size={10}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  @doc false
  def events(week) do
    last = length(week.events) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {week.events
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Week.event_row(row, i < last) end)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # Three slots, and only one of them can be moved from here.
  #
  # The **clock** converts, for `block/1`'s reason — and this is the column a
  # reader scans as a column, which is the argument `Kati.Screens.Day`'s gutter
  # makes for doing it there.
  #
  # The **title** is left exactly as it arrives. `Standup`, `Design review`,
  # `Lunch — Jo` and `6 episodes air` are `Kati.Calendar.SampleWeek`'s copy and
  # that module's msgids to add; translating them here would give one evening
  # two catalogue entries that could then disagree about the same sentence.
  #
  # The **length** is left whole rather than half-converted: `15m`, `1h` and
  # `to 23:00` are a figure and a WORD, and `Kati.Locale.number/1` over them
  # would set Persian digits against a Latin unit — ۱۵m — which is the worst of
  # the three states. So the face asks the string, and both halves move together
  # on the day that module folds.
  @doc false
  def event_row(row, rule?) do
    rule_color = if row.rule == :screen, do: Palette.accent(), else: Palette.ink()
    time = Kati.Locale.number(row.time)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        <Column width={38}>
          <Text
            text={time}
            font_family={Kati.Locale.mono_face(time)}
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box width={3} height={20} corner_radius={2} background={rule_color} />
        <Spacer size={12} />
        <Text
          text={row.title}
          text_size={13}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={12} />
        <Text
          text={row.length}
          font_family={Kati.Locale.mono_face(row.length)}
          text_size={10.5}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Week.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box, and `render: :box` rather
  # than the component's `:divider` default.
  #
  # `:divider` is NOT the Box this used to be. The comment that stood here said
  # it was — that Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))` — and that is wrong:
  # Material3 draws it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an
  # ANTIALIASED stroke. At this device's 2.6875x a 1dp rule gets a 3px canvas
  # and a 2.6875px stroke centred in it, so the bottom pixel row lands at ~69%
  # coverage — a full-width row 4-5/255 lighter than the two above it. The
  # adoption softened the hairline by one pixel row and nothing said so.
  #
  # `render: :box` is the component's filled-rect primitive: `<Box fill_width
  # height={thickness} background={color}>`, which is the node that was written
  # here by hand before the adoption, so the rule goes back to three full-colour
  # rows. (Its `<Spacer size={1} />` child is an iOS height workaround — on
  # Android the Box's own `height` pins it and the background covers it.)
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  # One of the two sentences this file writes, and the only one on the page
  # that explains a control. `touch_app` is a hand, not an arrow, so it means
  # the same thing pointing either way and is left as drawn; the Row around it
  # mirrors on its own under `rtl` and puts the glyph on the right, which is
  # where a Persian reader starts the line.
  @doc false
  def hint do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {UI.symbol("touch_app", size: 15, color: Palette.tertiary())}
        <Spacer size={8} />
        <Text
          text={gettext("Tap any lane to name its day here")}
          text_size={11.5}
          text_color={Palette.sub()}
        />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Kati.UI.eyebrow's dash is always the accent; this one is #C4BDB3.
  #
  # Everything else about the label is `Kati.UI.eyebrow/2`'s and is repeated
  # here rather than approximated — the Persian face, the half-point the
  # Persian label takes instead of the tracking, and the weight that carries
  # it. The two eyebrows on this page differ by the colour of a 13pt dash, and
  # a reader who could also tell them apart by their typeface would be reading
  # a distinction nobody drew. `Kati.Screens.Nutrition.muted_eyebrow/1` is the
  # same node with the same repetition, for the same pair of eyebrows.
  #
  # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`: Arabic script has
  # no case, so upcasing بار این هفته returns it unchanged and the call reads
  # as though something happened.
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={UI.eyebrow_label(label)}
          font_family={Kati.Locale.mono_face()}
          text_size={Kati.Locale.pick(10.5, 11)}
          font_weight={Kati.Locale.pick("normal", "semibold")}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def load_card(week) do
    load = week.load

    bars =
      load.bars
      |> Enum.map(fn {height, peak?} -> Kati.Screens.Week.bar(height, peak?) end)
      |> Enum.intersperse(bar_gap())

    # `axis/0` and not `load.letters`, which is the same swap
    # `Kati.Screens.Day.money_row/0` makes on its clock: the two are one fact
    # written twice, and only one of them can be asked what script the reader
    # is in. English is unchanged — `weekday_initial/1` answers M T W T F S S
    # for the same seven days, in the same order.
    letters = Enum.map(axis(), fn letter -> Kati.Screens.Week.letter(letter) end)

    sentence = load_sentence(load)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} height={56} align="bottom">
        {bars}
      </Row>
      <Spacer size={10} />
      <Row fill_width={true} align="center">
        {letters}
      </Row>
      <Spacer size={12} />
      <Text
        text={sentence}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.45)}
        text_color={Palette.ink_soft()}
      />
    </Column>
    """
  end

  @doc """
  The seven letters under the bars, one per lane.

  Derived from seven dates rather than read off `Kati.Calendar.SampleWeek`,
  because they are not the same seven letters in both scripts:
  `Kati.Locale.weekday_initial/1` answers `M T W T F S S` in Latin and
  `د س چ پ ج ش ی` in Persian, off `Kati.Calendar.Shamsi.weekday_short/1`.
  Screens 02, 16 and 22 build their own axes the same way.

  A FUNCTION and not a module attribute, which is the reason `@first_lane`
  holds a date and this holds the arithmetic: `weekday_initial/1` asks
  `Kati.Locale.current/0` at the moment it is called, and a module attribute is
  evaluated once at COMPILE time — it would freeze whichever script
  `mix compile` happened to be in and hand it to both readers.

  ## Still Monday-first in Persian, and that is the chart's doing

  Board 137 makes the week start follow the language, so a Persian axis should
  begin on Saturday — `Kati.Screens.Nutrition` moves its buckets for exactly
  that. It cannot move here: `Kati.Calendar.SampleWeek.load/0` lays the seven
  BARS out from Monday in both scripts, with the peak at index 3 for the
  Thursday the sentence underneath names, so a شنبه-first axis would print ش
  over a Monday's bar — the quiet kind of wrong this fold keeps finding. The
  letters follow the chart until the module that builds the chart starts asking
  the reader.
  """
  @spec axis() :: [String.t()]
  def axis do
    Enum.map(0..6, fn offset ->
      @first_lane |> Date.add(offset) |> Kati.Locale.weekday_initial()
    end)
  end

  @doc """
  The running sentence under the bars, assembled and made safe to set.

  The three fragments are `Kati.Calendar.SampleWeek`'s and still English, so
  while that module holds out this is a Latin paragraph on an RTL page — and a
  full stop is a NEUTRAL in the bidirectional algorithm. It resolves against
  the PARAGRAPH rather than the words beside it and lands at the LEFT edge, so
  the card reads `.Thursday is carrying 9 items` with nothing wrong but the
  punctuation. `Kati.Locale.ltr/1`'s own doc walks through the same break on
  screen 83's five licence notices.

  Guarded on the run actually being Latin rather than wrapped outright, because
  the isolate is that same defect the other way round once that module folds:
  an LRI around a Persian paragraph forces ITS punctuation to the wrong edge.
  The test is the one `Kati.Locale.mono_face/1` already uses — printable ASCII
  — so this call site needs no second edit on the day the sentence changes
  script.
  """
  @spec load_sentence(map()) :: String.t()
  def load_sentence(load) do
    text = load.lead <> " " <> load.strong <> load.tail

    if String.match?(text, ~r/\A[\x20-\x7E]*\z/), do: Kati.Locale.ltr(text), else: text
  end

  @doc false
  def bar_gap, do: ~MOB"<Spacer size={6} />"

  # The peak bar is ink; the rest take `placeholder`, which is the token whose
  # light value IS this literal. `bar_neutral` is the name a chart's neutral bar
  # wants, but it is a different colour (#D8D2C8) and taking it would move light.
  @doc false
  def bar(height, peak?) do
    color = if peak?, do: Palette.ink(), else: Palette.placeholder()

    ~MOB"""
    <Box weight={1.0} height={height} corner_radius={5} background={color} />
    """
  end

  # The face asks the LETTER, not the reader — `kati_mono.ttf` carries no
  # Arabic-script glyph, so a `ش` set in `mono` is handed to Android's own
  # substitute face and lands in a typeface that is not Kati's, beside six
  # others that are. `M` is ASCII and DM Mono has it, so the Latin axis is
  # untouched. `Kati.Screens.MonthGrid.weekday/1` is the same node one screen
  # over, and `Kati.PersianFontTest` fails exactly this.
  @doc false
  def letter(letter) do
    ~MOB"""
    <Box weight={1.0} align="center">
      <Text
        text={letter}
        font_family={Kati.Locale.mono_face(letter)}
        text_size={9.5}
        text_color={Palette.tertiary()}
        max_lines={1}
      />
    </Box>
    """
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  # The switcher this screen draws is its only control, and its three live
  # segments (`view_Day`, `view_Month`, `view_Agenda`) are routed by the module
  # that drew them. `Kati.Screens.ViewSwitcher.handle_tap/2` returns the socket
  # untouched for anything that is not a `view_*` tag, so delegating the whole
  # callback is safe and stays right if this screen grows a control of its own
  # — those clauses go above this line.
  @impl true
  def handle_tap(tag, socket), do: Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
end
