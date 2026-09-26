defmodule Kati.Screens.MonthGrid do
  @moduledoc """
  Screen 16 — Calendar, month.

  Built to `test/design/screens/16.html`. The design's own caption states
  the idea: *"Month view is a load map, not a list"* — one dot per section
  under each date, today on an ink card, and the selected day's items listed
  underneath. Nothing on the grid says what an event is called, because at
  seven columns nothing legible would fit.

  ## Whose month

  The reader's. It opens on today's month in the reader's own calendar —
  Gregorian, or Shamsi under Persian (`Kati.Locale.month_span/1`) — laid out
  from the reader's own first weekday (`Kati.Screens.Stats.week_start_on/1`).
  The dots, the legend and the rows under the grid all come from
  `Kati.Screens.Calendar.rows_between/2`: the stored events and the followed
  shows' airings, the same rows screen 02 draws for any one of these days. A
  month with nothing in it draws no dots, no legend and screen 02's own
  *Nothing scheduled* card.

  The chevrons move a month either way. Tapping a date selects it; tapping the
  selected date again opens screen 09 on it, the gesture screen 02's day strip
  already uses.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active, so it renders through `Kati.Shell` and the four-mode switcher is how
  you leave it rather than a back pill.

  ## The square is the bridge's, not a declared number

  Each cell is `aspect-ratio: 1` in the export, and `aspect_ratio={1.0}` is
  what the cell carries — the modifier chain is weight → aspect_ratio, so the
  height follows the width the Row actually handed out, at any frame.

  The switcher's four labels stay Latin: `Kati.Screens.ViewSwitcher.bar/1`
  builds each segment's tap tag out of the word it prints, and
  `Kati.Screens.Agenda`'s moduledoc carries that argument in full.
  """
  use Kati.Screens.Root, root: :calendar
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaSeparator
  alias Kati.Screens.Calendar, as: Schedule
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  @sections [:screen, :personal, :money]

  # `box-shadow: 0 1px 2px rgba(26,25,23,.05)` — one layer, not the card
  # recipe. The selected tile sits on the grid, not lifted off paper.
  @selected_shadow "0 1 2 0 #0D1A1917"

  @impl true
  def load(socket) do
    today = Kati.Time.today()
    Mob.Socket.assign(socket, date: today, month: month(today, today))
  end

  @doc """
  Coming back from a day or an event opened from here: the month is read again
  and the selected date is kept.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket), do: {:noreply, select(socket, socket.assigns.date)}
  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @doc """
  The month `date` falls in, with `date` selected, read from the store.

  `:days` is every cell of the grid, whole weeks from the reader's first
  weekday; `:rows` is the selected day's shaped rows; `:sections` the sections
  that have anything this month, in legend order.
  """
  @spec month(Date.t(), Date.t()) :: map()
  def month(%Date{} = date, %Date{} = today) do
    {first, last} = Kati.Locale.month_span(date)
    start = Kati.Screens.Stats.week_start_on(first)
    weeks = div(Date.diff(last, start), 7) + 1
    by_day = Schedule.rows_between(first, last)

    days =
      for offset <- 0..(weeks * 7 - 1) do
        day = Date.add(start, offset)
        in_month? = Date.compare(day, first) != :lt and Date.compare(day, last) != :gt

        %{
          date: day,
          label: Kati.Locale.day_of_month(day),
          in_month?: in_month?,
          today?: day == today,
          selected?: day == date,
          sections: if(in_month?, do: sections(Map.get(by_day, day, [])), else: [])
        }
      end

    %{
      title:
        gettext("%{month} %{year}",
          month: Kati.Locale.month_name(date),
          year: Kati.Locale.year_of(date)
        ),
      first: first,
      last: last,
      days: days,
      rows: Map.get(by_day, date, []),
      sections: by_day |> Map.values() |> List.flatten() |> sections()
    }
  end

  @doc "The sections a day's rows fall in, in legend order, each once."
  @spec sections([map()]) :: [atom()]
  def sections(rows) do
    present = rows |> Enum.map(&Schedule.section/1) |> MapSet.new()
    Enum.filter(@sections, &MapSet.member?(present, &1))
  end

  @doc """
  The line above the selected day's rows: its date and how many things it
  holds, or that it holds nothing.
  """
  @spec selected_label(Date.t(), [map()]) :: String.t()
  def selected_label(date, []),
    do: Kati.Locale.date(date, :long) <> " · " <> gettext("Nothing scheduled")

  def selected_label(date, rows) do
    n = length(rows)

    Kati.Locale.date(date, :long) <>
      " · " <> ngettext("%{n} item", "%{n} items", n, n: Kati.Locale.number(n))
  end

  @doc false
  def content(assigns) do
    month = assigns.month
    label = selected_label(assigns.date, month.rows)

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
        {Kati.Screens.MonthGrid.weekday_row(month)}
        {Kati.Screens.MonthGrid.grid(month)}
        {Kati.Screens.MonthGrid.legend(month.sections)}
        {UI.eyebrow(label)}
        {Kati.Screens.MonthGrid.day_rows(month.rows)}
      </Column>
    </Scroll>
    """
  end

  # Previous month and next month, and under `rtl` the two glyphs swap:
  # `layout_direction` mirrors the Row but not the picture inside a glyph, so
  # previous points back along the line (right, in Persian) and next forward.
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
        <Spacer weight={1.0} />
        <Box width={30} height={30} align="center" on_tap={{self(), :month_previous}}>
          {UI.symbol(previous, size: 22, color: Palette.sub())}
        </Box>
        <Spacer size={4} />
        <Box width={30} height={30} align="center" on_tap={{self(), :month_next}}>
          {UI.symbol(upcoming, size: 22, color: Palette.ink())}
        </Box>
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

  @doc """
  The seven weekday letters over the grid, read off the grid's own first row
  so a letter always heads the column of the day it names.
  """
  @spec weekdays(map()) :: [String.t()]
  def weekdays(month) do
    month.days |> Enum.take(7) |> Enum.map(&Kati.Locale.weekday_initial(&1.date))
  end

  @doc false
  def weekday_row(month) do
    cells =
      month
      |> weekdays()
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

  # The face asks the LETTER: `kati_mono.ttf` carries no Arabic-script glyph,
  # so a `ش` set in `mono` would land in Android's substitute face.
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

  @doc """
  The tag a date cell carries: `day_<iso date>`, the shape screen 02's strip
  uses, so the handler reads the date straight off it.
  """
  @spec day_tag(Date.t()) :: atom()
  def day_tag(%Date{} = date), do: String.to_atom("day_" <> Date.to_iso8601(date))

  @doc """
  How a cell is painted: `{background, shadow, number colour, weight, dot
  colours}`.

  Today is an ink card with its dots inverted to paper; the selected day, when
  it is not today, a card-white tile with a hairline shadow; a date outside the
  month is muted and carries no dots.
  """
  @spec paint(map()) :: {term(), term(), term(), String.t(), [term()]}
  def paint(%{today?: true} = day),
    do:
      {Palette.ink_fill(), nil, Palette.on_ink(), "bold",
       Enum.map(day.sections, fn _ -> Palette.on_ink() end)}

  def paint(%{selected?: true} = day),
    do:
      {Palette.card(), @selected_shadow, Palette.ink(), "bold",
       Enum.map(day.sections, &Schedule.section_color/1)}

  def paint(%{in_month?: false}),
    do: {Palette.transparent(), nil, Palette.rail_idle(), "medium", []}

  def paint(day),
    do:
      {Palette.transparent(), nil, Palette.ink(), "medium",
       Enum.map(day.sections, &Schedule.section_color/1)}

  # The cell centres its stack with full-width Rows and weighted Spacers either
  # side — a Column takes no horizontal alignment on this bridge — and the
  # Box's align="center" puts the pair on the cell's vertical middle.
  @doc false
  def day_cell(day) do
    {background, shadow, color, weight, dots} = paint(day)
    tap = {self(), day_tag(day.date)}

    ~MOB"""
    <Box
      weight={1.0}
      aspect_ratio={1.0}
      corner_radius={13}
      background={background}
      shadow={shadow}
      align="center"
      on_tap={tap}
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
          {Kati.Screens.MonthGrid.dots(dots)}
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Box>
    """
  end

  # An empty day still reserves the 5pt band, so a date with no dots sits at
  # the same height as one with three.
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

  @doc """
  The key under the grid: one entry per section that has anything this month,
  and nothing at all for an empty month — a key to colours that are not on
  the page would be decoration.
  """
  def legend([]), do: ~MOB"<Spacer size={0} />"

  def legend(sections) do
    items =
      sections
      |> Enum.map(fn section ->
        Kati.Screens.MonthGrid.legend_item(
          Schedule.section_color(section),
          Schedule.section_label(section)
        )
      end)
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

  # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`: Arabic script has
  # no case. The face asks the word, so a Persian label takes Vazirmatn.
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

  @doc """
  The selected day's rows, or screen 02's empty card for a day with none.
  """
  def day_rows([]) do
    Schedule.empty_card("calendar_month", gettext("Nothing scheduled"), [
      gettext("Add anything with +")
    ])
  end

  def day_rows(rows) do
    last = length(rows) - 1

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
      {rows
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.MonthGrid.day_row(row, i < last) end)}
    </Column>
    """
  end

  # The clock's face is asked of the string: `kati_mono.ttf` carries none of
  # U+06F0–U+06F9, so a Persian clock set in DM Mono would be empty boxes.
  @doc false
  def day_row(row, rule?) do
    tap = Schedule.tap(row)
    rule = row |> Schedule.section() |> Schedule.section_color()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13} on_tap={tap}>
        <Column min_width={44}>
          <Text
            text={row.time}
            font_family={Kati.Locale.mono_face(row.time)}
            text_size={11.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Box width={3} height={22} corner_radius={2} background={rule} />
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={12.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={2} />
          <Text
            text={row.meta}
            font_family={Kati.Locale.mono_face(row.meta)}
            text_size={10.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        {UI.symbol(Kati.Locale.forward_chevron(), size: 18, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.MonthGrid.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  # `render: :box`: the component's default `:divider` is Material3's
  # antialiased `drawLine`, whose last pixel row lands lighter than the rule.
  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  The month before or after the one `date` is in, and which day of it to
  select: today when today is in it, otherwise its first day.
  """
  @spec shift(Date.t(), :previous | :next, Date.t()) :: Date.t()
  def shift(date, direction, today) do
    {first, last} = Kati.Locale.month_span(date)
    landing = if direction == :previous, do: Date.add(first, -1), else: Date.add(last, 1)
    {start, stop} = Kati.Locale.month_span(landing)

    if Date.compare(today, start) != :lt and Date.compare(today, stop) != :gt,
      do: today,
      else: start
  end

  defp select(socket, date) do
    Mob.Socket.assign(socket, date: date, month: month(date, Kati.Time.today()))
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  @impl true
  def handle_tap(:month_previous, socket),
    do: {:noreply, select(socket, shift(socket.assigns.date, :previous, Kati.Time.today()))}

  def handle_tap(:month_next, socket),
    do: {:noreply, select(socket, shift(socket.assigns.date, :next, Kati.Time.today()))}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "day_" <> iso ->
        date = Date.from_iso8601!(iso)

        if date == socket.assigns.date,
          do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Day, %{date: date})},
          else: {:noreply, select(socket, date)}

      "row_" <> _rest ->
        {:noreply, Schedule.open_timeline_row(socket, tag, socket.assigns.date)}

      _other ->
        Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
    end
  end
end
