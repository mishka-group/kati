defmodule Kati.Screens.MonthGrid do
  @moduledoc """
  Screen 16 — Calendar, month.

  Built to `test/design/screens/16.html`. The design's own caption states
  the idea: *"Month view is a load map, not a list"* — one dot per section, a
  filled card on the heaviest day, and the selected day's clashes summarised
  underneath. Nothing on the grid says what an event is called, because at
  seven columns nothing legible would fit.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active, so it renders through `Kati.Shell` and the four-mode switcher is how
  you leave it rather than a back pill.

  ## The square is the bridge's, not a declared number

  Each cell is `aspect-ratio: 1` in the export, and `aspect_ratio={1.0}` is
  what the cell carries — the modifier chain is weight → aspect_ratio, so the
  height follows the width the Row actually handed out, at any frame. The 50
  that used to be declared here was only ever the answer at the drawing's own
  402pt frame: `(360 - 12) / 7 = 49.7`. A 411dp device gives each column 51,
  so a capture measured the cells 51 wide and 50 tall — squares that were not
  square. `Kati.Screens.Widgets` and `Kati.Screens.SeriesMeta` carry the same
  fix for the same reason.

  ## What is Persian on this page, and what is still August 2026

  Almost every word the grid draws comes from `Kati.Calendar.SampleMonth`, and
  nothing under `lib/kati/calendar/` has been folded yet —
  `Kati.Screens.Agenda`'s moduledoc records the same half-state for
  `Kati.Calendar.SampleAgenda`, and `gettext/1` cannot take a variable, so
  those strings can only be wrapped where they are written. What this file
  could reach it did: the weekday letters, the three mono faces, the tracking,
  the legend's case, and the two chevrons.

  What it could not, it left whole rather than half-converted, and the reason
  is worth writing down because it is not an oversight. The month's title, the
  forty-two day numbers, the selected day's summary and the three clash rows
  are ONE fixture — 1–31 August 2026, laid out Monday-first, with
  `SampleMonth`'s `@dots` keyed to the Gregorian day numbers and the 16th and
  20th singled out. Mordad 1405 runs 23 July – 22 August 2026, so folding the
  header on its own would head a Gregorian grid with a Shamsi month it does
  not contain, and running `Kati.Locale.number/1` over the cells would print
  ۱۶ for a day that is not the sixteenth of anything the reader counts —
  `Kati.Locale.day_of_month/1`'s doc names that exact defect on screen 02,
  "the right days, counted in the wrong calendar". The grid and its title
  convert together, in the module that lays them out;
  `Kati.Calendar.Shamsi.month_grid/2` already returns a شنبه-first month for
  the day it does.

  The switcher's four labels are deliberately still Latin, and
  `Kati.Screens.Agenda`'s moduledoc carries that argument in full:
  `Kati.Screens.ViewSwitcher.bar/1` builds each segment's tap tag out of the
  word it prints, so a `gettext/1` here would rename three live controls to
  `:view_روز`, `:view_هفته` and `:view_فهرست` under `:fa` —
  `ViewSwitcher.screen/1` would answer `nil`, the strip would go dead on the
  Persian page, and the tags would fail
  `test/kati/screen_tap_sweep_test.exs`'s *no control is named after the word
  printed on it*. The fix is one prop in the module that builds the tag, and
  screens 17 and 30 draw the same strip and want it too.

  mishka-group/kati#103.
  """
  use Kati.Screens.Root, root: :calendar

  alias Kati.Calendar.SampleMonth
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # The Monday `Kati.Calendar.SampleMonth.days/0`'s first row begins on — the
  # 27 July 2026 that opens the grid. Only its WEEKDAY is read; the date itself
  # never reaches the screen.
  @first_column ~D[2026-07-27]

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :month, SampleMonth.month())

  @doc false
  def content(assigns) do
    month = assigns.month

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.MonthGrid.header(month)}
        {Kati.Screens.MonthGrid.switcher()}
        {Kati.Screens.MonthGrid.weekday_row()}
        {Kati.Screens.MonthGrid.grid(month)}
        {Kati.Screens.MonthGrid.legend()}
        {UI.eyebrow(month.selected_label)}
        {Kati.Screens.MonthGrid.clashes(month)}
      </Column>
    </Scroll>
    """
  end

  # Previous month and next month, and under `rtl` the two glyphs swap.
  # `layout_direction` mirrors the Row — the pair moves to the left edge and
  # the title to the right — but it cannot mirror a PICTURE, so a chevron left
  # as drawn goes on pointing at the month a Persian reader has already left.
  # In reading order the pair is still previous-then-next, so previous points
  # back along the line (right, in Persian) and next points forward.
  #
  # `forward_chevron/0` is the app's answer to "the way this page moves
  # forward". Its opposite has no helper — `Kati.Locale.back_glyph/0` is the
  # arrow and `Kati.Screens.Pushed.back_glyph/0` is the pill's iOS chevron,
  # and neither is this — so it is `pick/2` with both glyphs at the call site,
  # which is what that function's doc asks for.
  @doc false
  def header(month) do
    previous = Kati.Locale.pick("chevron_left", "chevron_right")
    upcoming = Kati.Locale.forward_chevron()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={month.title}
          text_size={24}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={6} />
        {UI.symbol("unfold_more", size: 19, color: Palette.sub())}
        <Spacer weight={1.0} />
        {UI.symbol(previous, size: 22, color: Palette.sub())}
        <Spacer size={8} />
        {UI.symbol(upcoming, size: 22, color: Palette.ink())}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def switcher do
    bar =
      Kati.Screens.ViewSwitcher.bar([
        {"Day", false},
        {"Week", false},
        {"Month", true},
        {"Agenda", false}
      ])

    ~MOB"""
    <Column fill_width={true}>
      {bar}
      <Spacer size={16} />
    </Column>
    """
  end

  # Monday-first, matching the drawing's header row. Duplicated letters are the
  # design's, not a mistake: Tuesday and Thursday are both T.
  #
  # Derived from seven dates rather than written out as `["M", "T", "W", …]`,
  # because they are not the same seven letters in both scripts:
  # `Kati.Locale.weekday_initial/1` answers `M T W T F S S` in Latin and
  # `د س چ پ ج ش ی` in Persian, off `Kati.Calendar.Shamsi.weekday_short/1`.
  # Screens 02 and 22 build their own axes the same way, and
  # `Kati.Screens.Nutrition.daily_buckets/1` carries the long version.
  #
  # A FUNCTION and not the module attribute this replaces, which is the whole
  # reason it moved: `weekday_initial/1` asks `Kati.Locale.current/0` at the
  # moment it is called, and a module attribute is evaluated once at COMPILE
  # time — it would freeze whichever script `mix compile` happened to be in and
  # hand it to both readers.
  #
  # ## Still Monday-first in Persian, and that is the grid's doing
  #
  # Board 137 makes the week start follow the language, so a Persian axis
  # should begin on Saturday — `Kati.Screens.Nutrition` moves its buckets for
  # exactly that. It cannot move here: `Kati.Calendar.SampleMonth.days/0` lays
  # the 42 cells out from Monday in both scripts — five trailing days of July,
  # then August, then six of September — so a شنبه-first header would print ش
  # over a column of Mondays, which is the quiet kind of wrong this fold keeps
  # finding. The letters follow the GRID until the module that lays the grid
  # out starts asking the reader.
  @doc false
  def weekdays do
    Enum.map(0..6, fn offset ->
      @first_column |> Date.add(offset) |> Kati.Locale.weekday_initial()
    end)
  end

  @doc false
  def weekday_row do
    letters = weekdays()

    cells =
      letters
      |> Enum.map(fn letter -> Kati.Screens.MonthGrid.weekday(letter) end)
      |> Enum.intersperse(cell_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {cells}
      </Row>
      <Spacer size={6} />
    </Column>
    """
  end

  # The face asks the LETTER, not the reader. `kati_mono.ttf` carries no
  # Arabic-script glyph, so a `ش` set in `mono` is handed to Android's own
  # substitute face and lands in a typeface that is not Kati's, beside six
  # others that are — `Kati.PersianFontTest` fails exactly this. `M` is ASCII
  # and DM Mono has it, so the Latin axis is untouched.
  #
  # The tracking asks the reader instead, because that is the question it is:
  # 0.08em opens the gaps between Latin capitals and breaks the joins between
  # Persian letters, so there is no one value that is right for both.
  @doc false
  def weekday(letter) do
    ~MOB"""
    <Box weight={1.0} align="center">
      <Text
        text={letter}
        font_family={Kati.Locale.mono_face(letter)}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.08)}
        text_color={Palette.tertiary()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def grid(month) do
    rows = Enum.chunk_every(month.days, 7)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.MonthGrid.grid_row(row) end)}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    cells =
      row
      |> Enum.map(fn day -> Kati.Screens.MonthGrid.day_cell(day) end)
      |> Enum.intersperse(cell_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cells}
      </Row>
      <Spacer size={2} />
    </Column>
    """
  end

  # The cell centres its stack, and both halves of that are load-bearing:
  # a Column takes no horizontal alignment on this bridge, so the number and
  # the dot row are centred by full-width Rows with weighted Spacers either
  # side, and the Box's align="center" is what puts the pair on the cell's
  # vertical middle.
  @doc false
  def day_cell(day) do
    background = day.background
    shadow = day.shadow
    color = day.color
    weight = day.weight

    ~MOB"""
    <Box
      weight={1.0}
      aspect_ratio={1.0}
      corner_radius={13}
      background={background}
      shadow={shadow}
      align="center"
    >
      <Column fill_width={true}>
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text
            text={day.label}
            text_size={13.5}
            font_weight={weight}
            text_color={color}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.MonthGrid.dots(day.dots)}
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Box>
    """
  end

  # An empty day still reserves the 5pt band, so a date with no dots sits at
  # the same height as one with three. The drawing does the same — the dot
  # container is `height:5px` whether or not it has children.
  @doc false
  def dots([]), do: ~MOB"<Row height={5} />"

  def dots(colors) do
    children =
      colors
      |> Enum.map(fn color -> Kati.Screens.MonthGrid.dot(color) end)
      |> Enum.intersperse(dot_gap())

    ~MOB"""
    <Row height={5} align="center">
      {children}
    </Row>
    """
  end

  @doc false
  def dot_gap, do: ~MOB"<Spacer size={2.5} />"

  @doc false
  def dot(color) do
    ~MOB"""
    <Box width={5} height={5} corner_radius={3} background={color} />
    """
  end

  @doc false
  def legend do
    items =
      SampleMonth.legend()
      |> Enum.map(fn {color, label} -> Kati.Screens.MonthGrid.legend_item(color, label) end)
      |> Enum.intersperse(legend_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {items}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={14} />"

  # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`, which is the same
  # edit `Kati.UI.eyebrow/2` already carries: Arabic script has no case, so
  # upcasing عادت‌ها returns عادت‌ها and the call reads as though something
  # happened. The word is the argument to the face as well, for the reason
  # `weekday/1` gives one function up — these three are
  # `Kati.Calendar.SampleMonth.legend/0`'s, so they are ASCII today and take
  # Vazirmatn on the day that module folds, with no second edit here.
  @doc false
  def legend_item(color, label) do
    word = UI.eyebrow_label(label)

    ~MOB"""
    <Row align="center">
      <Box width={6} height={6} corner_radius={3} background={color} />
      <Spacer size={6} />
      <Text
        text={word}
        font_family={Kati.Locale.mono_face(word)}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.08)}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def clashes(month) do
    last = length(month.clashes) - 1

    ~MOB"""
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
      {month.clashes
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.MonthGrid.clash_row(row, i < last) end)}
    </Column>
    """
  end

  # The clock keeps its Latin digits in both scripts and only its FACE is a
  # question, which is `Kati.Locale.number/1`'s own ruling for a figure the
  # design sets in mono: `kati_mono.ttf` carries none of U+06F0–U+06F9, so
  # ۰۹:۳۰ in DM Mono would be a row of empty boxes. `mono_face/1` asks the
  # string — `09:30` is ASCII and stays in DM Mono — so the slot is already
  # right for whatever `Kati.Calendar.SampleMonth.clashes/0` puts there next.
  # `Kati.Screens.Agenda.row/2` draws the same slot the same way.
  @doc false
  def clash_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column width={38}>
          <Text
            text={row.time}
            font_family={Kati.Locale.mono_face(row.time)}
            text_size={11.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Box width={3} height={22} corner_radius={2} background={Palette.accent()} />
        <Spacer size={13} />
        <Text
          text={row.label}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={13} />
        {UI.symbol(Kati.Locale.forward_chevron(), size: 18, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.MonthGrid.hairline(rule?)}
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

  # ── What a tap changes ────────────────────────────────────────────────────

  # The switcher this screen draws is its only control, and its three live
  # segments (`view_Day`, `view_Week`, `view_Agenda`) are routed by the module
  # that drew them. `Kati.Screens.ViewSwitcher.handle_tap/2` returns the socket
  # untouched for anything that is not a `view_*` tag, so delegating the whole
  # callback is safe and stays right if this screen grows a control of its own
  # — those clauses go above this line.
  @impl true
  def handle_tap(tag, socket), do: Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
end
