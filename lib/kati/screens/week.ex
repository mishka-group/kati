defmodule Kati.Screens.Week do
  @moduledoc """
  Screen 17 — Calendar, week.

  Built to `test/design/screens/17.html`. Seven `flex:1` lanes of blocks
  with no titles in them: height is duration, colour is section, and the only
  text a block carries is its start hour in mono. Names live in the card
  underneath, for whichever lane you tap — which is what the `touch_app` line
  between them says out loud.

  ## Whose week

  The reader's: the seven days from their own first weekday
  (`Kati.Screens.Stats.week_start_on/1`) around today, dated in their own
  calendar. Every block, every row in the card and every bar in the load chart
  comes from `Kati.Screens.Calendar.rows_between/2` — the stored events and
  the followed shows' airings screen 02 draws — so an empty week draws empty
  lanes, *Nothing scheduled* in the card and a flat chart.

  Tapping a lane names its day in the card; tapping the named lane again opens
  screen 09 on it. The chevrons move a week either way.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active.

  ## Two eyebrows, two dashes

  `Kati.UI.eyebrow/2` always draws the accent dash, and the drawing uses it
  for the named day. "Load this week" gets a `#C4BDB3` dash instead — the
  design's way of marking a section that reports rather than points at
  something happening — so that one is drawn here.

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

  # The shortest block the drawing sets (a 15-minute standup) and the tallest
  # (an evening), and how many points each hour past the first quarter adds.
  @min_block 46
  @max_block 110
  @per_hour 24

  # The load chart's bar area is 56 tall; the heaviest day fills 54 of it.
  @max_bar 54
  @min_bar 4

  @impl true
  def load(socket) do
    today = Kati.Time.today()
    Mob.Socket.assign(socket, date: today, week: week(today, today))
  end

  @doc """
  Coming back from a day or an event opened from here: the week is read again
  and the named day is kept.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket), do: {:noreply, select(socket, socket.assigns.date)}
  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @doc """
  The week `date` falls in, with `date` named, read from the store.

  `:lanes` holds the seven days in the reader's order, each with its blocks;
  `:rows` is the named day's shaped rows; `:load` is how many things each day
  carries.
  """
  @spec week(Date.t(), Date.t()) :: map()
  def week(%Date{} = date, %Date{} = today) do
    start = Kati.Screens.Stats.week_start_on(date)
    stop = Date.add(start, 6)
    by_day = Schedule.rows_between(start, stop)
    days = Enum.map(0..6, &Date.add(start, &1))

    %{
      range:
        gettext("%{from} – %{to}",
          from: Kati.Locale.date(start, :short),
          to: Kati.Locale.date(stop, :short)
        ),
      start: start,
      lanes:
        Enum.map(days, fn day ->
          %{
            date: day,
            name: lane_name(day),
            day: Kati.Locale.day_of_month(day),
            selected?: day == date,
            today?: day == today,
            blocks: by_day |> Map.get(day, []) |> Enum.map(&block/1)
          }
        end),
      rows: Map.get(by_day, date, []),
      load: Enum.map(days, fn day -> {day, length(Map.get(by_day, day, []))} end)
    }
  end

  # `MON` in Latin; a single letter in Persian, where slicing a weekday's name
  # to three letters gives a different word.
  defp lane_name(day) do
    Kati.Locale.pick(
      day |> Kati.Time.day_name() |> String.slice(0, 3) |> String.upcase(),
      Kati.Locale.weekday_initial(day)
    )
  end

  @doc """
  One lane block for a shaped row: its section, its height and the hour it
  starts at.

  Height is duration — a quarter-hour is the drawing's shortest block and each
  hour past it adds `@per_hour` points, up to its tallest — and an airing or an
  all-day item, which has no
  length, takes the shortest. The hour is the row's own clock cut to its hour,
  or `ALL` for an all-day item.
  """
  @spec block(map()) :: map()
  def block(row) do
    %{
      section: Schedule.section(row),
      height: height(Map.get(row, :minutes)),
      hour: hour(row)
    }
  end

  defp height(minutes) when is_integer(minutes),
    do: (@min_block + div(max(minutes - 15, 0) * @per_hour, 60)) |> min(@max_block)

  defp height(_none), do: @min_block

  defp hour(%{at: %DateTime{} = at}),
    do: at |> Kati.Time.in_zone(Kati.Time.device_zone()) |> Calendar.strftime("%H")

  defp hour(_all_day), do: pgettext("all-day gutter, first line of ALL DAY", "ALL")

  @doc false
  def content(assigns) do
    week = assigns.week
    label = Kati.Screens.MonthGrid.selected_label(assigns.date, week.rows)

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
        {UI.eyebrow(label)}
        {Kati.Screens.Week.events(week.rows)}
        {Kati.Screens.Week.hint()}
        {Kati.Screens.Week.muted_eyebrow(pgettext("eyebrow", "Load this week"))}
        {Kati.Screens.Week.load_card(week)}
      </Column>
    </Scroll>
    """
  end

  # Last week and next week, and under `rtl` the two glyphs swap:
  # `layout_direction` mirrors the Row but not the picture inside a glyph.
  # The range keeps its Latin tightening only in Latin — the same fraction of
  # an em pulls Vazirmatn apart at the joins.
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
        <Box width={30} height={30} align="center" on_tap={{self(), :week_previous}}>
          {UI.symbol(previous, size: 22, color: Palette.sub())}
        </Box>
        <Spacer size={4} />
        <Box width={30} height={30} align="center" on_tap={{self(), :week_next}}>
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

  @doc """
  The tag a lane carries: `lane_<iso date>`.
  """
  @spec lane_tag(Date.t()) :: atom()
  def lane_tag(%Date{} = date), do: String.to_atom("lane_" <> Date.to_iso8601(date))

  @doc false
  def lane(lane) do
    tap = {self(), lane_tag(lane.date)}

    ~MOB"""
    <Column weight={1.0} on_tap={tap}>
      {Kati.Screens.Week.lane_header(lane)}
      <Spacer size={6} />
      {Kati.Screens.Week.blocks(lane.blocks)}
    </Column>
    """
  end

  # The named lane's header sits on a card; the rest are bare paper. Today's
  # number is set in the accent, so today stays findable after another lane is
  # named. The face asks the NAME: `kati_mono.ttf` carries no Arabic-script
  # glyph.
  @doc false
  def lane_header(lane) do
    background = if lane.selected?, do: Palette.card(), else: Palette.transparent()
    shadow = if lane.selected?, do: "0 1 2 0 #0D1A1917", else: nil
    number = if lane.today?, do: Palette.accent(), else: :on_surface

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
        <Text text={lane.day} text_size={14} font_weight="bold" text_color={number} max_lines={1} />
      </Box>
    </Column>
    """
  end

  @doc false
  def blocks(blocks) do
    ~MOB"""
    <Column fill_width={true}>
      {blocks
       |> Enum.map(fn block -> Kati.Screens.Week.block_node(block) end)
       |> Enum.intersperse(Kati.Screens.Week.block_gap())}
    </Column>
    """
  end

  @doc false
  def block_gap, do: ~MOB"<Spacer size={4} />"

  @doc """
  The lane-block recipe for a section: fill, leading rule and lift. A screen
  item is cream, money is settled paper, and a personal item a card with a
  hairline shadow — the day screen's vocabulary at a seventh of the width.
  """
  @spec style(:screen | :money | :personal) :: map()
  def style(:screen), do: %{background: Palette.cream(), rule: Palette.accent(), shadow: nil}

  def style(:money),
    do: %{background: Palette.card_settled(), rule: Palette.bronze(), shadow: nil}

  def style(:personal),
    do: %{background: Palette.card(), rule: Palette.ink(), shadow: "0 1 2 0 #0D1A1917"}

  # `border-left: 2.5px solid` is a real child, not a border prop: the bridge's
  # border draws all four edges, and the drawing wants only the leading one.
  # The hour goes through `Kati.Locale.number/1`, and its face follows the
  # converted string.
  @doc false
  def block_node(block) do
    style = style(block.section)
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

  @doc """
  The named day's rows, or screen 02's empty card for a day with none.
  """
  def events([]) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Calendar.empty_card("calendar_month", gettext("Nothing scheduled"), [gettext("Add anything with +")])}
      <Spacer size={14} />
    </Column>
    """
  end

  def events(rows) do
    last = length(rows) - 1

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
        {rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Week.event_row(row, i < last) end)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  How long a row lasts, as the card's trailing mono figure: `15m`, `1h`,
  `1h 30m` — or *All day* for an item with no clock, and nothing for one with a
  clock and no end.
  """
  @spec length_label(map()) :: String.t()
  def length_label(%{at: nil}), do: gettext("All day")

  def length_label(%{minutes: minutes}) when is_integer(minutes) and minutes > 0,
    do: span(minutes)

  def length_label(_row), do: ""

  defp span(minutes) when minutes < 60, do: gettext("%{n}m", n: Kati.Locale.number(minutes))

  defp span(minutes) when rem(minutes, 60) == 0,
    do: gettext("%{n}h", n: Kati.Locale.number(div(minutes, 60)))

  defp span(minutes),
    do:
      gettext("%{h}h %{m}m",
        h: Kati.Locale.number(div(minutes, 60)),
        m: Kati.Locale.number(rem(minutes, 60))
      )

  @doc false
  def event_row(row, rule?) do
    tap = Schedule.tap(row)
    rule_color = row |> Schedule.section() |> Schedule.section_color()
    length = length_label(row)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11} on_tap={tap}>
        <Column min_width={44}>
          <Text
            text={row.time}
            font_family={Kati.Locale.mono_face(row.time)}
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
          text={length}
          font_family={Kati.Locale.mono_face(length)}
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

  # `render: :box`: the component's default `:divider` is Material3's
  # antialiased `drawLine`, whose last pixel row lands lighter than the rule.
  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  # `touch_app` is a hand, not an arrow, so it means the same thing pointing
  # either way and is left as drawn.
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

  # Kati.UI.eyebrow's dash is always the accent; this one is #C4BDB3. The
  # rest — the Persian face, its half-point and weight — is `Kati.UI.eyebrow/2`'s
  # recipe repeated, so the two eyebrows differ only by the dash.
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

  @doc """
  The load chart's bars: one per day, `{height, peak?}`, scaled so the
  heaviest day fills the chart and a day with nothing is a stub. The first
  heaviest day is the one in ink; an empty week has no peak.
  """
  @spec bars([{Date.t(), non_neg_integer()}]) :: [{number(), boolean()}]
  def bars(load) do
    counts = Enum.map(load, &elem(&1, 1))
    top = Enum.max(counts, fn -> 0 end)
    peak = if top > 0, do: Enum.find_index(counts, &(&1 == top))

    counts
    |> Enum.with_index()
    |> Enum.map(fn {n, i} ->
      height = if top > 0, do: max(@min_bar, div(n * @max_bar, top)), else: @min_bar
      {height, i == peak}
    end)
  end

  @doc """
  The sentence under the bars: which day carries the most and how much, or
  that the week holds nothing.
  """
  @spec load_sentence([{Date.t(), non_neg_integer()}]) :: String.t()
  def load_sentence(load) do
    case Enum.max_by(load, &elem(&1, 1), fn -> {nil, 0} end) do
      {_day, 0} ->
        gettext("Nothing scheduled this week.")

      {day, n} ->
        gettext("%{day} is carrying %{items}.",
          day: Kati.Locale.date(day, :full),
          items: ngettext("%{n} item", "%{n} items", n, n: Kati.Locale.number(n))
        )
    end
  end

  @doc false
  def load_card(week) do
    bars =
      week.load
      |> bars()
      |> Enum.map(fn {height, peak?} -> Kati.Screens.Week.bar(height, peak?) end)
      |> Enum.intersperse(bar_gap())

    letters =
      Enum.map(week.lanes, fn lane ->
        lane.date |> Kati.Locale.weekday_initial() |> Kati.Screens.Week.letter()
      end)

    sentence = load_sentence(week.load)

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

  @doc false
  def bar_gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def bar(height, peak?) do
    color = if peak?, do: Palette.ink(), else: Palette.placeholder()

    ~MOB"""
    <Box weight={1.0} height={height} corner_radius={5} background={color} />
    """
  end

  # The face asks the LETTER, not the reader — `kati_mono.ttf` carries no
  # Arabic-script glyph.
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

  defp select(socket, date) do
    Mob.Socket.assign(socket, date: date, week: week(date, Kati.Time.today()))
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  @impl true
  def handle_tap(:week_previous, socket),
    do: {:noreply, select(socket, Date.add(socket.assigns.date, -7))}

  def handle_tap(:week_next, socket),
    do: {:noreply, select(socket, Date.add(socket.assigns.date, 7))}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "lane_" <> iso ->
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
