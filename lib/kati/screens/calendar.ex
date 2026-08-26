defmodule Kati.Screens.Calendar do
  @moduledoc """
  Screen 02 — Schedule.

  Built to `test/design/screens/02.html`. Note how little it shares with
  Home: the title carries a mono subtitle rather than an eyebrow above it, the
  day strip is seven `flex:1` cells at radius 16 rather than fixed 44x62 pills,
  and the timeline is a 44pt mono time column beside a card, not a rule and a
  row. Reading the drawing rather than reusing Home's parts is the difference
  between similar and identical.

  The events are real — `Kati.Calendars.Today`, which is the device's own
  calendar via `CalendarContract` — and every day the user selects, **today
  included**, shows its real emptiness.

  ## Today used to be dressed in the drawing, and that was the defect (#91)

  `day_rows/1` fell TODAY back to `drawn_rows/0` on an empty store, on
  FIDELITY's *missing data is not a reason for a blank screen*. On a device
  that reading is wrong, and the owner said so after installing it: the first
  thing a person saw on this screen was a dentist appointment, a passport
  reminder and a renewal, none of which were theirs. A frame that can only be
  compared with its drawing when the app is lying is not a comparison worth
  keeping. `drawn_rows/0` is still here — it is the transcription of the board
  and the sweeps read it — and nothing renders it.

  ## Two different emptinesses, and a person can tell them apart

  A calendar with nothing on it and a calendar Kati is not allowed to read are
  not the same fact, and #82 made both reachable: `Kati.Calendars.DeviceImport`
  only ever ingests what `Mob.Permissions` has been granted. `empty_reason/2`
  is the pure split and `timeline/2` draws the two cards.

  **No board draws either card.** 02 draws a day with five items on it, and no
  artboard anywhere draws a Schedule that Kati cannot see. So both are built
  from the boards that *do* write this copy, and from nothing else:

    * 139 (*Home — nothing set up*) is the only board that words the calendar's
      own emptiness — a `calendar_month` tile, a title, and
      `Nothing scheduled — add anything with +` — and its caption is the
      argument for drawing it at all: *the calendar and quick-add are
      section-agnostic and stay live*. That row is transcribed here, minus its
      chevron, because this card opens nothing and the house style says a
      chevron means *leads elsewhere*.
    * 40 (*Account & permissions*) writes the Calendars row: purpose before the
      ask, *To show your appointments beside your episodes. Kati only reads
      them.* That sentence is used verbatim.
    * 151 (*Notification access*) fixes the ORDER a permission state is stated
      in — purpose, then scope, then where the control is — and 136's caption
      the reason there is no button here: *a button that silently does nothing
      is worse than a sentence that tells the truth*. The Allow control is
      drawn on 40 and only on 40, so this card names that place instead of
      growing a second copy of it.
    * 96 (*Nothing set up — knock-on*) is the rule both obey: *an empty state
      should say what is missing and offer the one thing that fixes it — never
      render a plausible-looking zero.*

  `:unknown` — the native half absent, which is every host test and any device
  whose bridge method has gone — is deliberately NOT read as denied. It means
  *no answer*, and claiming Kati is locked out on no answer is the same class
  of lie as claiming five events on no data.

  ## The route to screen 09

  Tapping the day cell that is **already selected** pushes `Kati.Screens.Day`.
  Nothing on this screen is drawn differently for it — the gesture rides the
  seven cells the drawing already gives, so the resting frame is unchanged.
  The argument for that cell over the `Today` pill is at the `"day_" <> iso`
  clause of `handle_tap/2`, next to the code it decides.

  ## A row names its own event

  Every card on the timeline carries `row_<kind>_<event id>` rather than
  `row_<kind>`, so the screen it opens is about the row that was tapped. See
  `tag/1`: without the id, screen 31 could only re-query the day and take the
  first event back, which meant tapping the third row and editing the first.
  The drawn day's rows have no stored event to name and keep the bare tag,
  which is what keeps screen 31's sample reachable. Nothing this screen renders
  takes that branch any more — every row it draws comes from a stored event and
  carries that event's id — which is what struck `row_event` off the tap
  sweep's `@known_collisions`.
  """
  use Kati.Screens.Root, root: :calendar

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme
  alias Kati.Theme.Palette

  @impl true
  def load(socket) do
    date = Kati.Time.today()

    Mob.Socket.assign(socket,
      date: date,
      rows: day_rows(date),
      filter: "All",
      menu?: false,
      # Read, never remembered. `Kati.Permissions` says why at length: a
      # permission can be revoked in system settings while Kati is
      # backgrounded, so a cached boolean becomes a lie exactly when it
      # matters. Answered once per mount, which is once per arrival at the
      # screen.
      access: Kati.Permissions.status(:calendar)
    )
  end

  @doc """
  The day's rows, each carrying the shape the drawing gives it.

  `Kati.Calendars.Today` answers with the device's own events, and on a device
  with nothing mirrored it answers with nothing. Nothing is what this returns,
  for every date including today — see the moduledoc for why the today
  exception was removed rather than narrowed.
  """
  @spec day_rows(Date.t()) :: [map()]
  def day_rows(date) do
    date
    |> Kati.Calendars.Today.rows()
    |> Enum.map(&Kati.Screens.Calendar.shaped/1)
  end

  @doc """
  The five rows of `test/design/screens/02.html`, in its own order.

  **The screen does not render these and no code path reaches them.** They are
  the board's transcription, kept because that is a thing worth keeping: the
  design sweeps read them to compare the board against something, and
  `Kati.CalendarsTodayTest` reads them to check `kind/1` against every shape
  the drawing spends a page proving are not one row repeated — a done habit, an
  appointment, a reminder, a renewal and an airing group. Deleting them would
  delete the record of the frame, not the defect; the defect was `day_rows/1`
  handing them to a person as their own day, and that is gone.
  """
  @spec drawn_rows() :: [map()]
  def drawn_rows do
    [
      %{
        shape: :done,
        kind: "event",
        time: "08:00",
        title: "Morning run",
        meta: "Habit · 12-day streak"
      },
      %{
        shape: :event,
        kind: "event",
        time: "11:00",
        title: "Dentist — Marlow Clinic",
        meta: "11:00 – 11:45"
      },
      %{
        shape: :reminder,
        kind: "event",
        time: "15:00",
        title: "Renew passport",
        meta: "reminder"
      },
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

  @doc """
  A real event, given the drawn shape its kind calls for.

  `:kind` changes vocabulary here, and that is deliberate rather than a
  collision: a `Kati.Calendars.Today` row arrives carrying the event's own kind
  atom, and leaves carrying one of this screen's four chip names as a string —
  the value `visible/2`, `tap/1` and `handle_tap/2` all read. `kind/1` maps
  between the two and passes a string straight through, so shaping a row twice
  is the same as shaping it once.
  """
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

    # Read off the UNFILTERED rows. A day that holds a renewal and nothing else
    # goes empty under the Personal chip, and that emptiness is the filter's,
    # not the calendar's — offering "Kati cannot see your calendar" there would
    # be a second false statement in the place the first one was removed from.
    reason = Kati.Screens.Calendar.empty_reason(rows, Map.get(assigns, :access, :unknown))

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Calendar.header(date, rows, assigns.menu?)}
        {Kati.Screens.Calendar.month_row(date)}
        {Kati.Screens.Calendar.day_strip(date)}
        {Kati.Screens.Calendar.rule()}
        <Spacer size={16} />
        {Kati.Screens.Calendar.filters(assigns.filter)}
        {Kati.Screens.Calendar.timeline(Kati.Screens.Calendar.visible(rows, assigns.filter), reason)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(date, rows, menu?) do
    subtitle =
      "#{Kati.Time.day_name(date)} #{date.day} #{Kati.Time.month_name(date.month)} · " <>
        "#{length(rows)} #{if length(rows) == 1, do: "item", else: "items"}"

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Schedule"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={subtitle}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Calendar.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Calendar.menu(menu?)}
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
  @doc """
  The ⋯ disc and the menu behind it.

  The drawing puts a `more_horiz` in screen 02's header and draws nothing on
  the other side of it. It used to go straight to the agenda, which made one
  destination reachable and hid two: screens 18 and 52 were gallery-only.

  Quick add sits between them because it is the only row that writes something
  — the other two change what you are looking at.
  """
  def menu(open?) do
    Kati.UI.Menu.overflow(
      Kati.Screens.Calendar.disc("more_horiz", :toggle_menu),
      open?,
      [
        Kati.UI.Menu.item("density_medium", "Agenda", :open_agenda),
        Kati.UI.Menu.item("bolt", "Quick add", :open_quick_add),
        Kati.UI.Menu.rule(),
        Kati.UI.Menu.item("restaurant", "Meals on the calendar", :open_meals_day),
        Kati.UI.Menu.item("payments", "Money on the calendar", :open_money_day)
      ],
      dismiss: :close_menu
    )
  end

  @doc false
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: tag
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  # ## Why the month name caps and the day numbers do not (#79)
  #
  # It shares a row with a control. At 235% "August 2026" is 727 of 1080
  # pixels, and the Today pill — which hugs its own label — was squeezed until
  # its text ellipsised to "...". A pill that says nothing is not a smaller
  # control, it is a broken one.
  #
  # This is the second half of the rule in `day_strip/1`: content grows, and
  # chrome caps — but a heading that shares a row with a control is competing
  # for the same width, and the control cannot shrink below its own label. So
  # the heading yields. Capping at 1.6 leaves it at 32pt, still the largest
  # thing in the row, with room for the chevron and the pill beside it.
  #
  # The app-wide sweep that capped every display title missed this one: it
  # keyed on `text_size={28}` and this is 20.
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
          <Text
            text={label}
            text_size={20}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.025}
            text_color={:on_surface}
          />
          <Spacer size={6} />
          {Kati.UI.symbol("unfold_more", size: 19, color: Palette.sub())}
        </Row>
        <Spacer weight={1.0} />
        <Row
          height={30}
          corner_radius={15}
          background={Palette.placeholder()}
          padding_left={13}
          padding_right={13}
          align="center"
        >
          <Text
            text="Today"
            text_size={12}
            max_font_scale={1.4}
            font_weight="semibold"
            text_color={:on_surface}
          />
        </Row>
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  # Seven flex:1 cells, gap 2, radius 16 — not the fixed pills Home's earlier
  # version used. Today is ink; the rest sit on card white.
  #
  # ## Which parts of this may grow with the system font size (#79)
  #
  # The rule this screen settles, because 62 screens will meet it:
  #
  #   * **Content grows.** The day NUMBER is what the strip is for, so it takes
  #     the full 235% and the cell's height follows it. Nothing caps it.
  #   * **Chrome whose size carries structure caps instead.** The weekday
  #     abbreviation and the Today pill are labels on a control, and the
  #     control's size means something: seven cells across is a week, and a
  #     30pt pill is a pill. Growing either does not make them more readable —
  #     it makes the week stop being seven-across and the pill stop being one.
  #   * **A fixed size is never the answer to the question.** `width={44}` on
  #     the cell was what clipped the digits out of it entirely; the cells flex
  #     now and the digits are the reason.
  #
  # Capping the label rather than the whole cell is what keeps the number at
  # full size: `max_font_scale` provides a clamped `LocalDensity` for the
  # subtree it is on, so a cap on the Text does not reach its sibling.
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
  def rule,
    do: MishkaSeparator.separator(color: Palette.hairline_soft(), thickness: 1, render: :box)

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

    bg = if today?, do: Palette.ink_fill(), else: Palette.card()
    name_color = if today?, do: Palette.on_ink_muted(), else: Palette.muted()
    num_color = if today?, do: Palette.on_ink(), else: Palette.ink()
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
        <Text
          text={name}
          font_family="mono"
          text_size={10.5}
          max_font_scale={1.5}
          letter_spacing={0.06}
          text_color={name_color}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={"#{date.day}"}
          text_size={16.5}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={num_color}
          text_align="center"
        />
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
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft()
    )
  end

  # `gap:7px` belongs BETWEEN the chips. Carried as a trailing Spacer inside
  # each one it made every chip 7 wider than the drawn `padding:0 15px` and
  # left the row itself with no gap.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  Which of the two emptinesses the timeline is looking at.

  Pure, and separate from the render for the reason
  `Kati.Permissions.affordance/1` is: the choice between *your calendar is
  empty* and *Kati cannot read your calendar* is the whole of what this screen
  decides about a permission, and it should be settleable without a device. On
  a host `Kati.Permissions.status/1` answers `:unknown` for want of a bridge,
  so a test that could only go through `load/1` could never reach the second
  card at all.

  `:unknown` answers `:no_events`, and that is the careful half. Android's four
  states are asymmetric (see `Kati.Permissions`) but they are all ANSWERS;
  `:unknown` is the absence of one, and an absent answer is not a denial. Being
  wrong the other way — a granted calendar told it is locked out — would send a
  person into system settings to fix a permission they already gave.
  """
  @spec empty_reason([map()], Kati.Permissions.state()) :: :no_events | :no_permission
  def empty_reason([], access) when access in [:unasked, :denied, :blocked], do: :no_permission
  def empty_reason(_rows, _access), do: :no_events

  @doc false
  def timeline(rows, reason \\ :no_events)

  def timeline([], :no_permission) do
    Kati.Screens.Calendar.empty_card("lock", "Kati cannot see your calendar", [
      # Screen 40's Calendars row, word for word. Purpose first, then scope —
      # 151's fixed order for stating a permission.
      "To show your appointments beside your episodes. Kati only reads them.",
      # Where the control is, rather than a second copy of it. 40 is the board
      # that draws Allow, and 136's caption is why this is a sentence and not a
      # button: for a permanently refused permission the button would do
      # nothing, and a button that does nothing is worse than the truth.
      "Allow Calendars in Settings, under This device."
    ])
  end

  def timeline([], :no_events) do
    # Screen 139's row, which is the only place any board words this. Its
    # em-dashed sentence is split at the dash into the row's own two lines, and
    # its trailing chevron is dropped: that row pushes the calendar and this
    # card IS the calendar.
    Kati.Screens.Calendar.empty_card("calendar_month", "Nothing scheduled", [
      "Add anything with +"
    ])
  end

  def timeline(rows, _reason) do
    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.Calendar.event_row(row) end)
       |> Enum.intersperse(Kati.Screens.Calendar.row_gap())}
    </Column>
    """
  end

  # Screen 139's list row, built to its own numbers: a 30x30 paper tile at
  # radius 9 with a 17pt `#5C574F` glyph, a 13.5/600 ink title, and 11.5pt
  # `#8A8479` under it. The card is 139's too — radius 20 and the soft card
  # shadow — rather than the timeline's 18 and lifted one, because 139 is the
  # board this content is drawn on and 02 draws no card of this kind at all.
  @doc false
  def empty_card(icon, title, lines) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={17}
      padding_bottom={17}
      align="top"
    >
      {Kati.Screens.Calendar.empty_tile(icon)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text={title} text_size={13.5} font_weight="semibold" text_color={:on_surface} />
        {Enum.map(lines, fn line -> Kati.Screens.Calendar.empty_line(line) end)}
      </Column>
    </Row>
    """
  end

  # The same Theme Icon `payments_tile/0` uses, and for the same reason: a
  # themed container around exactly one icon, and the card around it is not
  # tappable either, so an Action Icon would be claiming an affordance that is
  # not there.
  @doc false
  def empty_tile(icon) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 30, radius: 9],
      [Kati.UI.symbol(icon, size: 17, color: Palette.ink_soft())]
    )
  end

  @doc false
  def empty_line(line) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={line} text_size={11.5} line_height={1.5} text_color={Palette.sub()} />
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
    time_color = if row.shape == :airing, do: Palette.ink(), else: Palette.muted()
    time_weight = if row.shape == :airing, do: "medium", else: "regular"

    ~MOB"""
    <Row fill_width={true} align="top">
      <Column min_width={44} padding_top={top}>
        <Text
          text={row.time}
          font_family="mono"
          text_size={12}
          font_weight={time_weight}
          text_color={time_color}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Box weight={1.0}>
        {Kati.Screens.Calendar.card(row)}
      </Box>
    </Row>
    """
  end

  @doc false
  def card(%{shape: :done} = row), do: Kati.Screens.Calendar.ruled(row, Palette.green(), :done)
  def card(%{shape: :event} = row), do: Kati.Screens.Calendar.ruled(row, Palette.ink(), :event)
  def card(%{shape: :airing} = row), do: Kati.Screens.Calendar.airing(row)

  def card(%{shape: :reminder} = row) do
    tap = Kati.Screens.Calendar.tap(row)

    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={Palette.card_settled()}
      corner_radius={18}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.UI.symbol("radio_button_unchecked", size: 21, color: Palette.tertiary())}
      <Spacer size={12} />
      <Box weight={1.0}>
        <Text
          text={row.title}
          text_size={14}
          font_weight="semibold"
          letter_spacing={-0.01}
          text_color={:on_surface}
          max_lines={1}
        />
      </Box>
      <Spacer size={12} />
      <Text
        text={row.meta}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Row>
    """
  end

  def card(%{shape: :money} = row) do
    tap = Kati.Screens.Calendar.tap(row)

    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={Palette.card_settled()}
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
        <Text
          text={row.title}
          text_size={14}
          font_weight="semibold"
          letter_spacing={-0.01}
          text_color={:on_surface}
          max_lines={1}
        />
      </Box>
      <Spacer size={12} />
      <Text
        text={row.meta}
        font_family="mono"
        text_size={12}
        font_weight="medium"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
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
      [variant: :filled, color: Palette.placeholder(), size: 26, radius: 8],
      [Kati.UI.symbol("payments", size: 15, color: Palette.ink_soft())]
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
    bg = if done?, do: Palette.card_settled(), else: Palette.card()
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
        <Text
          text={row.title}
          text_size={14}
          font_weight="semibold"
          letter_spacing={-0.01}
          text_color={:on_surface}
          max_lines={1}
        />
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
      <Text text={row.meta} text_size={12} text_color={Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  def sub_line(row, false) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={4} />
      <Text
        text={row.meta}
        font_family="mono"
        text_size={11}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  def trailing(true),
    do: Kati.UI.symbol("check_circle", size: 21, color: Palette.green(), fill: true)

  def trailing(false), do: Kati.UI.symbol("more_horiz", size: 19, color: Palette.rail_idle())

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
      background={Palette.card()}
      corner_radius={18}
      shadow={Kati.Theme.shadow_card()}
      padding={15}
      align="center"
    >
      <Box width={3} height={48} corner_radius={2} background={Palette.accent()} />
      <Spacer size={12} />
      {Kati.Screens.Calendar.poster_stack(row)}
      <Spacer size={16} />
      <Column weight={1.0}>
        <Text
          text={row.title}
          text_size={14.5}
          font_weight="bold"
          letter_spacing={-0.015}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={row.meta}
          font_family="mono"
          text_size={11}
          text_color={Palette.sub()}
          max_lines={1}
        />
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
      [variant: :filled, color: Palette.paper(), size: 28, radius: 14],
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
  def chevron(false), do: Kati.UI.symbol("expand_more", size: 18, color: Palette.ink_soft())

  def chevron(true) do
    ~MOB"""
    <Box width={18} height={18} rotate={180.0} align="center">
      {Kati.UI.symbol("expand_more", size: 18, color: Palette.ink_soft())}
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
          <Text
            text={m.title}
            text_size={13.5}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
          <Box fill_width={true} height={3} />
          <Text
            text={m.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
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
      background={Palette.placeholder()}
      border_width={2}
      border_color={Palette.card()}
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
  def tap(row), do: {self(), Kati.Screens.Calendar.tag(row)}

  @doc """
  The tag a timeline row's card carries: `row_<kind>_<event id>`.

  ## Why the id is on the tag at all

  A tap arrives as one atom and nothing else — `handle_info({:tap, tag})` is the
  whole of what the bridge sends back — so whatever the destination screen needs
  to know has to be IN it. Before this the tag was `row_<kind>`, which named the
  destination and not the row, and screen 31 had no choice but to re-query and
  take the first event of the day: tap the third row, edit the first (#84).

  ## Why an atom and not a tuple

  `{:row, "event", id}` would render — mob puts whatever term it is given on
  `on_tap` — and it would draw a control with **no `accessibility_id`**, because
  the id is derived from an atom tag. A row nothing can address by name is a row
  no device test and no screen reader can reach, which is a worse defect than
  the one being fixed. `Kati.Screens.ImportSources.tag/1` settled this shape
  already and this is the same one.

  The atom per event is the cost, and it is bounded by what the user has
  actually looked at: a row re-rendered is the same string and therefore the
  same atom, so a day browsed twice mints nothing the first pass did not.

  ## Why the id is OPTIONAL

  `drawn_rows/0` is the day the drawing shows, and its rows are not stored
  anywhere — there is no event to name. Those keep the bare `row_<kind>` tag,
  and screen 31 answers a push with no id with its own sample, which is what
  the empty-database sweep renders. Splitting on the first `_` after the kind is
  unambiguous in both directions: no kind contains one and a UUID contains none.
  """
  @spec tag(map()) :: atom()
  def tag(row) do
    case Map.get(row, :id) do
      nil -> String.to_atom("row_" <> Kati.Screens.Calendar.kind(row))
      id -> String.to_atom("row_" <> Kati.Screens.Calendar.kind(row) <> "_" <> to_string(id))
    end
  end

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
  Which screen a timeline row belongs to, read off the row's own kind.

  Called once, by `shaped/1`, which stamps the answer onto the row as `:kind`.
  Everything downstream — the chip filter in `visible/2`, the card shape, the
  destination a tap pushes — then reads that one field, so the row's
  destination and its chip cannot drift apart.

  Seven event kinds onto the four names `@row_screens` is keyed on, which is a
  collapse and is meant to be: `Kati.Calendars.Event` calls a habit a habit and
  the drawing files it under Personal along with reminders and notes, so all
  three answer `"event"`. The kind the collapse throws away is still on the row
  for a screen that wants it — 56 draws a reminder differently from an
  appointment.

  **This used to read the answer back out of `meta`** with
  `String.contains?(meta, "Money")`, and that string is the event's location
  joined to a label `Kati.Calendars.Today` writes — so an event at a place the
  user had typed as *Money* was drawn as a payment and pushed Subscriptions,
  and the same label was derived twice, once to render and once to route. The
  row carries `:kind` now, which is the fact both readings were guessing at;
  the label is `Kati.Calendars.Today.kind_label/2`'s alone.

  A string passes through untouched, which is what makes `shaped/1` idempotent
  and lets `drawn_rows/0` state its own kinds outright.
  """
  @spec kind(map()) :: String.t()
  def kind(%{kind: kind}) when is_binary(kind), do: kind
  def kind(%{kind: :meal}), do: "meals"
  def kind(%{kind: :air_date}), do: "screen"
  def kind(%{kind: :money}), do: "money"
  def kind(%{kind: _kind}), do: "event"

  @row_screens %{
    "meals" => Kati.Screens.MealsDay,
    "screen" => Kati.Screens.Film,
    # Screen 126 rather than 23. A money row on a calendar day is a renewal or
    # an expense on THAT DAY, and the page that answers "what does this day
    # cost" is the day — 23 is the account, one tap further in.
    "money" => Kati.Screens.MoneyDay,
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

  def handle_tap(:toggle_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_tap(:close_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_tap(:open_agenda, socket), do: {:noreply, pick(socket, Kati.Screens.Agenda)}

  def handle_tap(:open_quick_add, socket), do: {:noreply, pick(socket, Kati.Screens.QuickAdd)}

  def handle_tap(:open_meals_day, socket), do: {:noreply, pick(socket, Kati.Screens.MealsDay)}

  def handle_tap(:open_money_day, socket), do: {:noreply, pick(socket, Kati.Screens.MoneyDay)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      # The row's own event rides across as `%{id: id}`, so the screen that
      # opens is about the row that was tapped rather than about whatever the
      # destination's own query happens to return first. A row with no id — the
      # drawn day — pushes with no params at all rather than with `%{id: nil}`:
      # a destination that pattern-matches on the key would then take a nil for
      # an answer, and the sample fallback is the branch that has to survive.
      "row_" <> rest ->
        {kind, id} = split_row(rest)
        {:noreply, open_row(socket, Map.fetch!(@row_screens, kind), id)}

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
          # The date is the whole of what this route carries, and screen 09
          # reads it now: `day.ex`'s `load/1` titles the page with the day it
          # was handed and draws that day's own events. This comment used to
          # record the opposite — the param was passed and thrown away — which
          # is the same defect the row tags below had, one screen along.
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

  # `row_event_9f3c…` → `{"event", "9f3c…"}`, `row_event` → `{"event", nil}`.
  # `parts: 2` so the id is never split further; a UUID has no underscore, and
  # neither has any of the four names `@row_screens` is keyed on, so the first
  # separator is the only one that means anything.
  defp split_row(rest) do
    case String.split(rest, "_", parts: 2) do
      [kind, id] when id != "" -> {kind, id}
      [kind] -> {kind, nil}
      [kind, _empty] -> {kind, nil}
    end
  end

  defp open_row(socket, module, nil), do: Mob.Socket.push_screen(socket, module)
  defp open_row(socket, module, id), do: Mob.Socket.push_screen(socket, module, %{id: id})

  # Close the menu, then go. The socket this returns is what `Mob.Screen` saves
  # onto the nav history, so a menu left open is a menu that reopens itself
  # every time the user comes back from what it opened.
  defp pick(socket, module) do
    socket
    |> Mob.Socket.assign(:menu?, false)
    |> Mob.Socket.push_screen(module)
  end
end
