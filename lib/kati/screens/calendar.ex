defmodule Kati.Screens.Calendar do
  @moduledoc """
  Screen 02 — Schedule.

  Built to `.scratch/design/screens/02.html`. Note how little it shares with
  Home: the title carries a mono subtitle rather than an eyebrow above it, the
  day strip is seven `flex:1` cells at radius 16 rather than fixed 44x62 pills,
  and the timeline is a 44pt mono time column beside a card, not a rule and a
  row. Reading the drawing rather than reusing Home's parts is the difference
  between similar and identical.

  The events are real — `Kati.Calendars.Today`, which is the device's own
  calendar via `CalendarContract` — and on a device with nothing mirrored yet
  TODAY falls back to `drawn_rows/0`, the five rows the drawing itself shows,
  so the screen can still be compared with its frame. Any other day the user
  taps shows its real emptiness.

  ## The route to screen 09

  Tapping the day cell that is **already selected** pushes `Kati.Screens.Day`.
  Nothing on this screen is drawn differently for it — the gesture rides the
  seven cells the drawing already gives, so the resting frame is unchanged.
  The argument for that cell over the `Today` pill is at the `"day_" <> iso`
  clause of `handle_tap/2`, next to the code it decides.
  """
  use Kati.Screens.Root, root: :calendar

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme


  @impl true
  def load(socket) do
    date = Kati.Time.today()
    Mob.Socket.assign(socket, date: date, rows: day_rows(date), filter: "All")
  end

  @doc """
  The day's rows, each carrying the shape the drawing gives it.

  `Kati.Calendars.Today` answers with the device's own events, and on a device
  with nothing mirrored it answers with nothing — which drew a single grey
  "Nothing scheduled today" card where the design draws five rows in five
  different shapes, so the screen could not be compared with its frame at all.
  FIDELITY's rule covers this: *missing data is not a reason for a blank
  screen*. TODAY therefore falls back to the drawn day; any other date the
  user taps still shows its real emptiness, so the empty state stays reachable
  and no other day is dressed up with events that are not there.
  """
  @spec day_rows(Date.t()) :: [map()]
  def day_rows(date) do
    case Kati.Calendars.Today.rows(date) do
      [] -> if date == Kati.Time.today(), do: drawn_rows(), else: []
      rows -> Enum.map(rows, &Kati.Screens.Calendar.shaped/1)
    end
  end

  @doc """
  The five rows of `.scratch/design/screens/02.html`, in its own order.

  Stand-in data, and marked as such — but the SHAPES are not stand-in: the
  design draws a done habit, an appointment, a reminder, a renewal and an
  airing group as five different cards, and every one of them is a state the
  real timeline will need.
  """
  @spec drawn_rows() :: [map()]
  def drawn_rows do
    [
      %{shape: :done, kind: "event", time: "08:00", title: "Morning run", meta: "Habit · 12-day streak"},
      %{shape: :event, kind: "event", time: "11:00", title: "Dentist — Marlow Clinic", meta: "11:00 – 11:45"},
      %{shape: :reminder, kind: "event", time: "15:00", title: "Renew passport", meta: "reminder"},
      %{shape: :money, kind: "money", time: "18:00", title: "Lumen+ renews", meta: "£8.99"},
      %{
        shape: :airing,
        kind: "screen",
        time: "20:00",
        title: "3 titles airing",
        meta: "Lumen+ · Northlight · 20:00",
        posters: ~w(hollow71 saltiron33 cartog60),
        # What "3 titles airing" is three OF. The drawing templates these rows
        # ({{ }} in the export) rather than naming them, so they are stated
        # from the posters the group already stacks — same three titles, in the
        # same order, which is the only reading consistent with the artwork.
        airing: [
          %{title: "The Long Hollow", meta: "S2E6 · Lumen+ · 20:00", seed: "hollow71"},
          %{title: "Salt & Iron", meta: "S1E3 · Northlight · 20:00", seed: "saltiron33"},
          %{title: "Cartographers", meta: "S4E1 · Lumen+ · 21:00", seed: "cartog60"}
        ]
      }
    ]
  end

  @doc "A real event, given the drawn shape its kind calls for."
  @spec shaped(map()) :: map()
  def shaped(row) do
    kind = Kati.Screens.Calendar.kind(row)

    shape =
      case kind do
        "money" -> :money
        "screen" -> :airing
        _ -> if row.now?, do: :event, else: :done
      end

    row |> Map.put(:kind, kind) |> Map.put(:shape, shape) |> Map.put_new(:posters, [])
  end

  @doc false
  def content(assigns) do
    date = assigns.date
    rows = assigns.rows

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Calendar.header(date, rows)}
        {Kati.Screens.Calendar.month_row(date)}
        {Kati.Screens.Calendar.day_strip(date)}
        {Kati.Screens.Calendar.rule()}
        <Spacer size={16} />
        {Kati.Screens.Calendar.filters(assigns.filter)}
        {Kati.Screens.Calendar.timeline(Kati.Screens.Calendar.visible(rows, assigns.filter))}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(date, rows) do
    subtitle =
      "#{Kati.Time.day_name(date)} #{date.day} #{Kati.Time.month_name(date.month)} · " <>
        "#{length(rows)} #{if length(rows) == 1, do: "item", else: "items"}"

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Schedule" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        {Kati.Screens.Calendar.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Calendar.disc("more_horiz", :open_menu)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Chelekom's headless Action Icon, which is what a header disc is — a compact
  # icon-only button. It could not draw this one until `shadow` landed: without
  # it `variant: :filled` paints a flat patch of card white on paper that is
  # nearly the same value, and the disc stopped reading as a button at all. The
  # lift IS the control here, and it is the design's own `shadow_button()`.
  #
  # `shape: :circle` computes `size / 2` = 22.0 for the radius the Box stated as
  # 22; `floatProp` reads both as 22.0f. The glyph goes in as a CHILD so
  # `Kati.UI.symbol/2` still supplies the Material Symbol at the drawn 21 rather
  # than the component's own `:lg` text glyph. The only structural difference is
  # the `<Row>` the component wraps children in, which hugs its single `<Text>`
  # and is centred by the same `Alignment.Center` — centring a hugging Row that
  # holds one glyph lands the glyph where centring the glyph did.
  @doc false
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Theme.card(:light),
        shadow: Theme.shadow_button(),
        on_tap: tag
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def month_row(date) do
    label = "#{Kati.Time.month_name(date.month)} #{date.year}"
    # An unfold chevron beside a month name means one thing, and the design
    # already drew screen 16 as the thing it means.
    month_tap = {self(), :open_month}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Row align="center" on_tap={month_tap}>
          <Text text={label} text_size={20} font_weight="bold" letter_spacing={-0.025} text_color={:on_surface} />
          <Spacer size={6} />
          {Kati.UI.symbol("unfold_more", size: 19, color: 0xFF8A8479)}
        </Row>
        <Spacer weight={1.0} />
        <Row height={30} corner_radius={15} background={0xFFE4E0D9} padding_left={13} padding_right={13} align="center">
          <Text text="Today" text_size={12} font_weight="semibold" text_color={:on_surface} />
        </Row>
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  # Seven flex:1 cells, gap 2, radius 16 — not the fixed pills Home's earlier
  # version used. Today is ink; the rest sit on card white.
  @doc false
  def day_strip(today) do
    start = Date.add(today, -Date.day_of_week(today) + 1)
    days = Enum.map(0..6, &Date.add(start, &1))

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {days |> Enum.map(fn d -> Kati.Screens.Calendar.day_cell(d, d == today) end) |> Enum.intersperse(Kati.Screens.Calendar.cell_gap())}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  # The hairline the drawing puts under the day strip, at its own 8% ink —
  # Chelekom's headless Separator rather than a Box pretending to be a line.
  #
  # `render: :box` is load-bearing, and the comment that used to sit here was
  # wrong about why. The default `:divider` is NOT the hand-rolled Box: the
  # bridge maps it to Material3's `HorizontalDivider`, which is a Canvas
  # drawing an ANTIALIASED `drawLine`, not a filled rect. At this device's
  # 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so the last
  # pixel row lands at ~69% coverage — a hairline 4-5/255 lighter than the
  # design's, running the full width under the day strip. `render: :box`
  # swaps the primitive back to `<Box fill_width height={1} background />`,
  # so every pixel row carries the full 8% ink again.
  @doc false
  def rule, do: MishkaSeparator.separator(color: 0x141A1917, thickness: 1, render: :box)

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def day_cell(date, today?) do
    # The tag carries the day, so tapping Thursday shows Thursday. Every cell
    # used to push the same screen, which looked interactive and was not.
    #
    # One tag, two meanings, decided by the handler rather than here: the cell
    # that is NOT selected selects itself, and the cell that IS selected opens
    # screen 09. The cell cannot know which it is without being told twice —
    # `today?` is already that answer, but reading it here would mean two
    # different tags on seven identical-looking controls, and the tag is what
    # the tap sweep enumerates. See `handle_tap/2`'s `"day_" <> iso` clause for
    # why the second tap is the drill-in.
    tap = {self(), String.to_atom("day_" <> Date.to_iso8601(date))}

    bg = if today?, do: Theme.ink(), else: Theme.card(:light)
    name_color = if today?, do: 0xFFBFB8AC, else: 0xFFA9A29A
    num_color = if today?, do: 0xFFFBFAF8, else: 0xFF1A1917
    shadow = if today?, do: Theme.shadow_button(), else: Theme.shadow_card_soft()
    name = Kati.Time.day_name(date) |> String.slice(0, 3)

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Column
        fill_width={true}
        background={bg}
        corner_radius={16}
        shadow={shadow}
        padding_top={9}
        padding_bottom={11}
        align="center"
      >
        <Text text={name} font_family="mono" text_size={10.5} letter_spacing={0.06} text_color={name_color} text_align="center" />
        <Spacer size={5} />
        <Text text={"#{date.day}"} text_size={16.5} font_weight="bold" letter_spacing={-0.02} text_color={num_color} text_align="center" />
      </Column>
    </Box>
    """
  end

  @doc false
  def filters(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {["All", "Screen", "Personal", "Money"]
           |> Enum.map(fn label -> Kati.Screens.Calendar.chip(label, label == active) end)
           |> Enum.intersperse(Kati.Screens.Calendar.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={18} />
    </Column>
    """
  end

  # Chelekom's headless Chip. A filter chip is exactly what the component is —
  # `checked` is the whole state, and until this round every visual below it was
  # a theme token the component picked for itself, which is why the drawn chip
  # could not be built out of it.
  #
  # The node it builds is the node this hand-rolled one built, with one
  # substitution:
  #
  #   was  <Row height={32} corner_radius={16} background padding_left={15}
  #             padding_right={15} align="center" on_tap>
  #          <Text 12.5 semibold max_lines={1} />
  #        </Row>
  #
  #   now  <Box fill_width={false} height={32} corner_radius={16} background
  #             padding_left={15} padding_right={15} padding_top={0}
  #             padding_bottom={0} align="center" on_tap>
  #          <Text 12.5 semibold max_lines={1} />
  #        </Box>
  #
  # Row → Box moves nothing here, and the two reasons are in the bridge:
  #
  #   * `rowAlignProp` returns `CenterVertically` for align="center", and
  #     `boxAlignProp` returns `Alignment.Center` — a 2D centre. The extra axis
  #     is a no-op because the box HUGS: `fill_width={false}` (fence K-17) makes
  #     `boxModifier` skip `fillMaxWidth`, so the box is 15 + label + 15 wide
  #     and there is no leftover width to centre the label in. Vertically both
  #     put the label's box on the same midline of the same 32.
  #   * `padding_top={0}`/`padding_bottom={0}` versus the Row's absent pair are
  #     the same number: `nodeModifier` reads `pad(v) = v ?: uniform ?: 0`, so
  #     an unset edge with no uniform `padding` is already 0. `hasEdge` was
  #     true for the Row too, so the same `Modifier.padding(0, 15, 0, 15)`
  #     chain is built either way, and `height={32}` measures the same box
  #     after it.
  #
  # Everything else is passed in rather than defaulted, so no theme token is
  # consulted: the ink/paper fills, the two label inks, the 16 radius, 12.5
  # semibold and the single line are all the drawing's own numbers.
  @doc false
  def chip(label, on?) do
    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: String.to_atom("filter_" <> label),
      height: 32,
      padding_x: 15,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Theme.ink(),
      text_color: 0xFFFBFAF8,
      unchecked_color: Theme.card(:light),
      unchecked_text_color: 0xFF5C574F
    )
  end

  # `gap:7px` belongs BETWEEN the chips. Carried as a trailing Spacer inside
  # each one it made every chip 7 wider than the drawn `padding:0 15px` and
  # left the row itself with no gap.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def timeline([]) do
    ~MOB"""
    <Box fill_width={true} background={Kati.Theme.card(:light)} corner_radius={18} shadow={Kati.Theme.shadow_card()} padding={18}>
      <Text text="Nothing scheduled today" text_size={14} text_color={0xFF8A8479} />
    </Box>
    """
  end

  def timeline(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.Calendar.event_row(row) end)
       |> Enum.intersperse(Kati.Screens.Calendar.row_gap())}
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={11} />"

  # Every row is a 44pt mono time column beside a card, and the CARD is what
  # changes. The drawing gives five of them, and the difference between them is
  # the whole point of the screen — a done habit is flat #F4F1EC with a green
  # tick, a live appointment is card white with a shadow, a reminder has a
  # hollow circle where the rule would be, a renewal carries a payments tile
  # and its amount, and an air date is a group with the posters stacked in it.
  @doc false
  def event_row(row) do
    top = if row.shape in [:reminder, :money], do: 14, else: 15
    time_color = if row.shape == :airing, do: 0xFF1A1917, else: 0xFFA9A29A
    time_weight = if row.shape == :airing, do: "medium", else: "regular"

    ~MOB"""
    <Row fill_width={true} align="top">
      <Column width={44} padding_top={top}>
        <Text text={row.time} font_family="mono" text_size={12} font_weight={time_weight} text_color={time_color} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box weight={1.0}>
        {Kati.Screens.Calendar.card(row)}
      </Box>
    </Row>
    """
  end

  @doc false
  def card(%{shape: :done} = row), do: Kati.Screens.Calendar.ruled(row, 0xFF4E9A73, :done)
  def card(%{shape: :event} = row), do: Kati.Screens.Calendar.ruled(row, Kati.Theme.ink(), :event)
  def card(%{shape: :airing} = row), do: Kati.Screens.Calendar.airing(row)

  def card(%{shape: :reminder} = row) do
    tap = Kati.Screens.Calendar.tap(row)

    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={0xFFF4F1EC}
      corner_radius={18}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.UI.symbol("radio_button_unchecked", size: 21, color: 0xFFB3ACA2)}
      <Spacer size={12} />
      <Box weight={1.0}>
        <Text text={row.title} text_size={14} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
      </Box>
      <Spacer size={12} />
      <Text text={row.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
    </Row>
    """
  end

  def card(%{shape: :money} = row) do
    tap = Kati.Screens.Calendar.tap(row)

    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={0xFFF4F1EC}
      corner_radius={18}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.Screens.Calendar.payments_tile()}
      <Spacer size={12} />
      <Box weight={1.0}>
        <Text text={row.title} text_size={14} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
      </Box>
      <Spacer size={12} />
      <Text text={row.meta} font_family="mono" text_size={12} font_weight="medium" text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end

  # Chelekom's headless Theme Icon — "a themed container around exactly one
  # icon", which is the whole of what this is. It is the better fit than Action
  # Icon here for the reason the two components differ: an Action Icon is a
  # BUTTON, and this tile is not tappable — the card around it is.
  #
  # It also builds a tighter node. Action Icon wraps caller-supplied children in
  # a `<Row>`; Theme Icon puts them straight into its Box whenever `id` is nil
  # (`markers(nil, …)` returns the children untouched), so the tree is the Box
  # and the glyph, exactly as hand-rolled — no wrapper to reason about at all.
  #
  # `variant: :filled` is what makes `color` the container's fill; the glyph
  # colour the variant derives from it is never used, because a caller-supplied
  # child carries its own ink and `Kati.UI.symbol/2` gives it the drawn
  # #5C574F. `size` and `radius` take raw dp as readily as tokens.
  @doc false
  def payments_tile do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: 0xFFE4E0D9, size: 26, radius: 8],
      [Kati.UI.symbol("payments", size: 15, color: 0xFF5C574F)]
    )
  end

  # The two cards that carry a 3pt rule down their leading edge. `align-self:
  # stretch` in the drawing means the rule is as tall as the card's content,
  # which here is a 14pt title line over a sub-line — 36 either way, stated
  # once rather than left to a fill that would stretch the Row instead.
  @doc false
  def ruled(row, rule, state) do
    tap = Kati.Screens.Calendar.tap(row)
    done? = state == :done
    bg = if done?, do: 0xFFF4F1EC, else: Kati.Theme.card(:light)
    shadow = if done?, do: nil, else: Kati.Theme.shadow_card()

    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={bg}
      corner_radius={18}
      shadow={shadow}
      padding_left={15}
      padding_right={15}
      padding_top={14}
      padding_bottom={14}
      align="center"
    >
      <Box width={3} height={36} corner_radius={2} background={rule} />
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={row.title} text_size={14} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
        {Kati.Screens.Calendar.sub_line(row, done?)}
      </Column>
      <Spacer size={12} />
      {Kati.Screens.Calendar.trailing(done?)}
    </Row>
    """
  end

  # A done habit states its streak in body text 3 under the title; a live
  # appointment states its window in mono, 4 under.
  @doc false
  def sub_line(row, true) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={row.meta} text_size={12} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  def sub_line(row, false) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={4} />
      <Text text={row.meta} font_family="mono" text_size={11} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def trailing(true), do: Kati.UI.symbol("check_circle", size: 21, color: 0xFF4E9A73, fill: true)
  def trailing(false), do: Kati.UI.symbol("more_horiz", size: 19, color: 0xFFC4BDB3)

  # The air-date group: the one card on this screen that opens. Its posters are
  # stacked the way Home stacks the hero's — `margin-left:-12px` shrinks the box
  # as well as shifting the child, so three 34-wide posters measure 78, and the
  # offset is stated on a fixed-width Box because negative padding throws.
  @doc false
  def airing(row) do
    # The flag rides on the row rather than widening card/1, so every other
    # shape keeps the signature it has and only the one card that opens knows
    # about opening.
    open? = Map.get(row, :open?, false)
    tap = {self(), :toggle_airing}

    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={Kati.Theme.card(:light)}
      corner_radius={18}
      shadow={Kati.Theme.shadow_card()}
      padding={15}
      align="center"
    >
      <Box width={3} height={48} corner_radius={2} background={0xFFE8823C} />
      <Spacer size={12} />
      {Kati.Screens.Calendar.poster_stack(row)}
      <Spacer size={16} />
      <Column weight={1.0}>
        <Text text={row.title} text_size={14.5} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
        <Spacer size={4} />
        <Text text={row.meta} font_family="mono" text_size={11} text_color={0xFF8A8479} max_lines={1} />
      </Column>
      <Spacer size={12} />
      {Kati.Screens.Calendar.chevron_tile(open?)}
    </Row>
    """
    |> then(fn card -> Kati.Screens.Calendar.with_members(card, row, open?) end)
  end

  # The same Theme Icon as `payments_tile/0`, and the same reasoning: the disc
  # is not the tap target — the whole air-date card is, so a button component
  # would be claiming an affordance that is not there. The chevron inside it
  # goes in as a child because at 180deg it is a rotated Box rather than a
  # glyph, which no `icon` shorthand can express.
  @doc false
  def chevron_tile(open?) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: 0xFFEFECE7, size: 28, radius: 14],
      [Kati.Screens.Calendar.chevron(open?)]
    )
  end

  @doc false
  def with_members(card, _row, false), do: card

  def with_members(card, row, true) do
    assigns = %{card: card, rows: Kati.Screens.Calendar.airing_rows(row)}

    ~MOB"""
    <Column fill_width={true}>
      {@card}
      {@rows}
    </Column>
    """
  end

  # The collapse glyph is `expand_more` turned over, which is exactly what the
  # design does — the export rotates it 180deg in CSS. There is no
  # `expand_less` in the icon subset and there does not need to be: adding one
  # would mean re-subsetting the font from a source that is not in this repo,
  # for a glyph that is this glyph upside down. Fence K-16 gave the bridge
  # `rotate` instead.
  @doc false
  def chevron(false), do: Kati.UI.symbol("expand_more", size: 18, color: 0xFF5C574F)

  def chevron(true) do
    ~MOB"""
    <Box width={18} height={18} rotate={180.0} align="center">
      {Kati.UI.symbol("expand_more", size: 18, color: 0xFF5C574F)}
    </Box>
    """
  end

  # The rows the group holds, drawn only while it is open. Each is the poster,
  # the title and the mono line — the shape the drawing's own templated
  # sub-rows carry.
  @doc false
  def airing_rows(row) do
    members = Map.get(row, :airing, [])

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(members, fn m -> Kati.Screens.Calendar.airing_row(m) end)}
    </Column>
    """
  end

  @doc false
  def airing_row(m) do
    ~MOB"""
    <Column fill_width={true}>
      <Box fill_width={true} height={9} />
      <Row fill_width={true} align="center" padding_left={30}>
        {Kati.Design.Images.poster(m.seed) |> Kati.Screens.Calendar.member_poster()}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={m.title} text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
          <Box fill_width={true} height={3} />
          <Text text={m.meta} font_family="mono" text_size={10.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
      </Row>
    </Column>
    """
  end

  @doc false
  # `src`, not `source`. An unknown prop is dropped without a word, so the
  # first version of this rendered three rows of text with no artwork and
  # nothing anywhere said why — the same silence that made a literal star
  # draw as empty space.
  def member_poster(nil), do: ~MOB"<Spacer size={0} />"

  def member_poster(src) do
    ~MOB"""
    <Image src={src} width={30} height={42} corner_radius={6} content_mode="fill" />
    """
  end

  @doc false
  def poster_stack(%{posters: []}), do: ~MOB"<Spacer size={0} />"

  def poster_stack(%{posters: seeds}) do
    ~MOB"""
    <Box width={78} height={48}>
      {seeds
       |> Enum.with_index()
       |> Enum.map(fn {seed, i} -> Kati.Screens.Calendar.mini_poster(seed, i) end)}
    </Box>
    """
  end

  def poster_stack(_row), do: ~MOB"<Spacer size={0} />"

  @doc false
  def mini_poster(seed, index) do
    offset = index * 22
    src = Kati.Design.Images.poster(seed)

    ~MOB"""
    <Box
      width={34}
      height={48}
      offset_x={offset}
      corner_radius={7}
      background={0xFFE4E0D9}
      border_width={2}
      border_color={0xFFFBFAF8}
      shadow={Kati.Theme.shadow_poster()}
    >
      {Kati.Screens.Calendar.mini_image(src)}
    </Box>
    """
  end

  @doc false
  def mini_image(nil), do: ~MOB"<Spacer size={0} />"

  def mini_image(src) do
    ~MOB"""
    <Image src={src} width={30} height={44} corner_radius={5} content_mode="fill" />
    """
  end

  @doc false
  def tap(row), do: {self(), String.to_atom("row_" <> row.kind)}

  @doc """
  Rows a filter leaves visible.

  The design's chips are Screen / Personal / Money, which are event KINDS —
  mirrored events all arrive as `:event`, so Personal is what a device
  calendar produces and the other two are Kati's own domains.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(rows, "All"), do: rows

  def visible(rows, filter) do
    wanted =
      case filter do
        "Screen" -> ["screen"]
        "Money" -> ["money"]
        _ -> ["event", "meals"]
      end

    Enum.filter(rows, fn row -> row.kind in wanted end)
  end

  @doc """
  Which screen a timeline row belongs to, read off the row's own meta.

  Called once, by `shaped/1`, which stamps the answer onto the row as `:kind`.
  Everything downstream — the chip filter in `visible/2`, the card shape, the
  destination a tap pushes — then reads that one field, so the row's
  destination and its chip cannot drift apart, and the drawn rows can state
  their kind outright rather than having it inferred from a sub-line that
  names no kind at all.
  """
  @spec kind(map()) :: String.t()
  def kind(%{meta: meta}) do
    cond do
      String.contains?(meta, "Meals") -> "meals"
      String.contains?(meta, "Airs today") -> "screen"
      String.contains?(meta, "Money") -> "money"
      true -> "event"
    end
  end

  @row_screens %{
    "meals" => Kati.Screens.MealsDay,
    "screen" => Kati.Screens.Film,
    "money" => Kati.Screens.Subscriptions,
    "event" => Kati.Screens.EventDetail
  }

  @impl true
  def handle_tap(:toggle_airing, socket) do
    open? = not Map.get(socket.assigns, :airing_open?, false)

    rows =
      Enum.map(socket.assigns.rows, fn row ->
        if row.shape == :airing, do: Map.put(row, :open?, open?), else: row
      end)

    {:noreply, Mob.Socket.assign(socket, airing_open?: open?, rows: rows)}
  end

  def handle_tap(:open_search, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_tap(:open_month, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MonthGrid)}

  def handle_tap(:open_menu, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Agenda)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "row_" <> kind ->
        {:noreply, Mob.Socket.push_screen(socket, Map.fetch!(@row_screens, kind))}

      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      # Two meanings on one tag, and which one you get depends on what is
      # already selected.
      #
      # ## Why this screen needed a route at all
      #
      # Screen 09 is drawn as a PUSHED screen whose back pill reads
      # `‹ Calendar` — so 09 sits over this root, and this root was the one
      # screen with no way to reach it. Screen 30 (`Kati.Screens.Week`) and
      # friends get there through `Kati.Screens.ViewSwitcher`; the Schedule
      # root draws no switcher, so nothing on 02 opened 09.
      #
      # ## Why the already-selected cell, and not the "Today" pill
      #
      # 02 draws exactly four controls above the timeline: two header discs
      # (search → 08, more → 16), the month name with `unfold_more` (→ the
      # month grid), the seven day cells, and the `Today` pill. The discs and
      # the month name are already spoken for, so the route is one of the last
      # two, and the drawings decide between them:
      #
      #   * **09 is date-parameterised.** Its title is `Thu 20 Aug`, not
      #     "Today" — it is the heavy-day view of A day, and its own caption
      #     points back at 02 ("tap the one on 02 to expand it"), so the two
      #     are the same timeline drawn at two densities. A route into it has
      #     to carry WHICH day. The `Today` pill carries only one date, by
      #     definition, so routing 09 through it would make six of the seven
      #     days in the strip unreachable.
      #
      #   * **"Today" names a date, not a view.** Every other pill on these
      #     drawings that names a view says so (`Day` / `Week` / `Month` /
      #     `Agenda` on 16/17/30). A pill labelled with a date is a date
      #     control: it puts the strip back on today. Spending it on
      #     navigation would leave that job undrawn AND leave 09 reachable
      #     from one day only — two losses for one gain.
      #
      #   * **The day cells are the only controls on 02 that carry a date**,
      #     and the drawing already paints one of the seven differently — ink
      #     fill, light numerals, the button lift, while the other six sit
      #     flat on card white. A second tap on that one cannot mean "select
      #     it": it is selected. Opening it is the only thing left for the
      #     gesture to mean, and it costs no new control, no new pixel, and
      #     nothing in the resting frame.
      #
      # Selection is untouched: any of the other six still changes `:date` and
      # reloads `:rows`, which is what the branch below did before and is the
      # whole of what it still does.
      "day_" <> iso ->
        date = Date.from_iso8601!(iso)

        if date == socket.assigns.date do
          # The date rides along as a param even though `Kati.Screens.Day`
          # currently throws it away — `day.ex`'s `load/1` assigns
          # `date: Kati.Time.today()` and never reads `assigns.params`. Said
          # out loud rather than left as a surprise: this is the route stating
          # which day was opened, and the day the drawing titles (`Thu 20
          # Aug`) is whichever cell was tapped. Teaching 09 to read it is a
          # change to `day.ex`, which this screen does not own; passing
          # nothing would mean changing both files instead of one.
          {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Day, %{date: date})}
        else
          {:noreply,
           Mob.Socket.assign(socket,
             date: date,
             rows: Kati.Screens.Calendar.day_rows(date)
           )}
        end

      _ ->
        {:noreply, socket}
    end
  end
end
