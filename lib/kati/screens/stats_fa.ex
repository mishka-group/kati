defmodule Kati.Screens.StatsFa do
  @moduledoc """
  Screen 61 — آمار, the Persian mirror of the stats root.

  Built to `.scratch/design/screens/61.html`. A **root**, so the dock is here
  and the frame's bottom inset is 132.

  ## Charts are where RTL is usually dropped

  The design's caption says so, and this screen is the proof: the time axis
  reads right-to-left, the bars fill from the right, and the contribution field
  starts its year in the top-**right** corner. None of that is decoration.
  Every one of the three is a consequence of one decision — the container is
  RTL and the sequences start where the reader starts — rather than three
  special cases. So `week/0` and `days/0` in `Kati.Fa.SampleYear` are already
  Saturday-first, and each bar's fill is simply the first child of its track.

  ## Why the shell is wrapped rather than used directly

  `Kati.Shell.render/1` takes its direction from `Kati.Locale`, which is right
  for the four English roots and wrong here: this screen's copy is Persian, so
  it is right-to-left whether or not the app's locale happens to be `:fa`.
  `MainActivity` reads `layout_direction` from the **root node only**, so
  wrapping the shell in one `Box` that declares it makes this screen RTL
  without touching `Kati.Shell` or the roots that share it. The dock itself
  still comes from the shell — there is only one dock.

  Root switching and the FAB are delegated to `Kati.Screens.Fa.dock_tap/3`
  rather than inherited from `Kati.Screens.Root`, whose `render/1` is not
  overridable. `Kati.Screens.Fa.roots/0` is the routing table, as it is for the
  other three Persian roots — not `Kati.Shell.screen_for/1`, which names the
  English four and would carry the reader out of Persian on a dock tap.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Fa.SampleYear
  alias Kati.Screens.Fa
  alias Kati.Theme
  alias Kati.Theme.Palette

  # 27 cells per row — the most the cream card actually holds on the device,
  # rather than the 26 the drawing's 402dp frame allowed. A cell is 8 with a
  # 4pt gap, so n cells measure 12n - 4; the card leaves
  # 411 - 42 gutters - 38 padding = 331, where 27 measures 320 and 28 would
  # measure 332 and clip. At 26 the field measured 308 and left 23 of the card
  # blank down the trailing edge.
  #
  # The old value claimed the card's own "۲۶ هفته" as its justification. That
  # label is a figure in the card's footer beside the streak, not a description
  # of the grid, so it does not move with this. 104 cells now run three rows of
  # 27 and a short one of 23 instead of four clean rows — which is what the
  # drawing's `flex-wrap` does anyway.
  @per_row 27

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, :year, SampleYear.year())}
  end

  def render(assigns) do
    shell = Kati.Shell.render(%{root: :stats, content: content(assigns)})

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      {shell}
    </Box>
    """
  end

  @doc """
  اعداد بیشتر — the two rows screen 61 gained with 108 and 127.

  The Persian mirror of screen 07's More numbers list, cut to the two rows that
  have a Persian page behind them. A row here that pushed an English screen
  would change the app's language out from under the reader —
  `Kati.Screens.Fa`'s moduledoc records that failure for the آمار tab's own
  stand-in — so Activity, Habits, Nutrition and Recently watched are absent
  rather than linked, and they arrive the day their mirrors do.

  سلامت is the first one to arrive that way. `Kati.Screens.HealthFa` is screen
  115, the Persian weight-and-doses page, and until it existed there was no
  Persian route to health at all: the Persian shell's roots are خانه, تقویم,
  کتابخانه and آمار — `Kati.Screens.Fa.roots/0` — and none of them is a health
  hub the way English's screen 42 is. This row is that route. `monitor_weight`
  is the glyph screen 110's board uses for the same page.

  `checklist` and `payments` are the glyphs screen 07 uses for the same two
  rows, and `chevron_left` is the direction a push goes in Persian.
  """
  @spec more_numbers() :: map()
  def more_numbers do
    cards =
      [
        {"checklist", "اهداف", "۳ هدف فعال", :open_goals},
        {"payments", "پول", "۴۶٫۴۷ پوند در ماه", :open_money},
        {"monitor_weight", "سلامت", "۷۶٫۰ کیلوگرم", :open_health}
      ]
      |> Enum.map(fn {icon, title, sub, tag} ->
        Kati.Screens.StatsFa.more_row(icon, title, sub, tag)
      end)

    assigns = %{cards: cards}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.StatsFa.eyebrow("اعداد بیشتر")}
      {Kati.UI.SettingsList.card(@cards)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def more_row(icon, title, sub, tag) do
    assigns = %{icon: icon, title: title, sub: sub, tap: {self(), tag}}

    Kati.UI.SettingsList.row(
      Kati.UI.SettingsList.icon_tile(icon),
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.BookDetailFa.fa(@title, 13.5, :on_surface, weight: "semibold")}
        <Spacer size={3} />
        {Kati.Screens.BookDetailFa.fa(@sub, 11.5, Kati.Theme.Palette.sub())}
      </Column>
      """,
      Kati.UI.SettingsList.trailing(
        Kati.UI.symbol("chevron_left", size: 18, color: Kati.Theme.Palette.rail_idle())
      ),
      on_tap: {self(), tag}
    )
  end

  @doc false
  def content(assigns) do
    year = assigns.year

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.StatsFa.header(year)}
        {Kati.Screens.StatsFa.hero(year)}
        {Kati.Screens.StatsFa.counts(year)}
        {Kati.Screens.StatsFa.eyebrow(year.breakdown_label)}
        {Kati.Screens.StatsFa.breakdown(year)}
        {Kati.Screens.StatsFa.quiet_eyebrow(year.week_label)}
        {Kati.Screens.StatsFa.week(year)}
        {Kati.Screens.StatsFa.note(year)}
        {Kati.Screens.StatsFa.more_numbers()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={year.title}
            font_family="fa"
            text_size={27}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={year.range}
            font_family="fa"
            text_size={11.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Fa.disc("ios_share", {self(), :share_year})}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # No `letter_spacing` on the mono numerals anywhere on this screen: Persian
  # digits are not in DM Mono and fall back to another face, and tracking
  # mis-measures the fallback run — wide enough that `max_lines={1}` ellipsised
  # the number itself (۳۱۲ came out as "۳…"). The English screen keeps its -0.03.
  #
  # `align="bottom"` lines up the two Texts' boxes, not their baselines, so the
  # 15pt unit sat 9dp under the 32pt number's baseline; the padding on its
  # Column lifts it back onto the line the drawing puts it on.
  @doc false
  def hero(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Theme.shadow_card_soft()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text
              text={year.time_label}
              font_family="fa"
              text_size={11}
              font_weight="semibold"
              text_color={Palette.cream_meta()}
              max_lines={1}
            />
            <Spacer size={7} />
            <Row align="bottom">
              <Text
                text={year.hours}
                font_family="mono"
                text_size={32}
                font_weight="medium"
                text_color={:on_surface}
                max_lines={1}
              />
              <Spacer size={5} />
              <Column padding_bottom={9}>
                <Text
                  text={year.hours_unit}
                  font_family="fa"
                  text_size={15}
                  font_weight="semibold"
                  text_color={Palette.cream_meta()}
                  max_lines={1}
                />
              </Column>
            </Row>
          </Column>
          <Column padding_bottom={5}>
            <Row
              height={28}
              corner_radius={14}
              background={Palette.green_wash()}
              padding_left={11}
              padding_right={11}
              align="center"
            >
              {Kati.UI.symbol("arrow_drop_up", size: 14, color: Palette.green_text(), fill: true)}
              <Spacer size={5} />
              <Text
                text={year.change}
                font_family="mono"
                text_size={11.5}
                text_color={Palette.green_text()}
                max_lines={1}
              />
            </Row>
          </Column>
        </Row>
        <Spacer size={18} />
        {Kati.Screens.StatsFa.field()}
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          <Text
            text={year.weeks}
            font_family="fa"
            text_size={10}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={year.streak}
            font_family="fa"
            text_size={10}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # The year starts in the top-right corner because the rows are RTL, not
  # because the list is reversed — reversing it would run the year backwards.
  @doc false
  def field do
    rows = Enum.chunk_every(SampleYear.contributions(), @per_row)
    last = length(rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.StatsFa.field_row(row, i < last) end)}
    </Column>
    """
  end

  # The 4pt gap goes *between* rows, so the last row does not carry one. It did,
  # and it stacked onto the 12pt Spacer `hero/1` sets under the field, making
  # the space below the grid 16 where the drawing asks for 12.
  @doc false
  def field_row(row, gap?) do
    ~MOB"""
    <Column>
      <Row>
        {row
         |> Enum.map(&Kati.Screens.StatsFa.cell/1)
         |> Enum.intersperse(Kati.Screens.StatsFa.cell_gap())}
      </Row>
      {Kati.Screens.StatsFa.field_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def field_gap(false), do: ~MOB"<Spacer size={0} />"
  def field_gap(true), do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell(level) do
    color = SampleYear.intensity(level)

    ~MOB"<Box width={8} height={8} corner_radius={2} background={color} />"
  end

  @doc false
  def counts(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {year.counts
         |> Enum.map(fn {number, label} -> Kati.Screens.StatsFa.count_card(number, label) end)
         |> Enum.intersperse(Kati.Screens.StatsFa.count_gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def count_gap, do: ~MOB"<Spacer size={12} />"

  # Untracked mono, for the reason given above `hero/1`: tracking the Persian
  # fallback digits mis-measures them, and `max_lines={1}` then eats the number.
  @doc false
  def count_card(number, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding={15}
      >
        <Text
          text={number}
          font_family="mono"
          text_size={25}
          font_weight="medium"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={5} />
        <Text
          text={label}
          font_family="fa"
          text_size={11}
          font_weight="semibold"
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc """
  The section label, in Persian.

  `Kati.UI.eyebrow/2` is DM Mono, uppercased and letter-spaced. The drawing's
  Persian labels are Vazirmatn at 11 semibold with `letter-spacing:0` — Persian
  has no case, and tracking it apart breaks the joins between letters.
  """
  def eyebrow(label), do: dash_label(label, Theme.accent())

  @doc "The same label with the muted dash the design gives a section you do not act on."
  def quiet_eyebrow(label), do: dash_label(label, Palette.rail_idle())

  defp dash_label(label, dash) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={dash} />
        <Spacer size={9} />
        <Text
          text={label}
          font_family="fa"
          text_size={11}
          font_weight="semibold"
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def breakdown(year) do
    last = length(year.breakdown) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding={17}
      >
        {year.breakdown
         |> Enum.with_index()
         |> Enum.map(fn {bar, i} -> Kati.Screens.StatsFa.bar(bar, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # The fill is the track's FIRST child, so it grows from the leading edge —
  # which under RTL is the right. That is the design's `float:right`, and it
  # needs no mirroring logic of its own.
  #
  # And it is why the two weighted cells stay: `Kati.Components.MishkaMeter` is
  # what a scalar gauge in a known range should be, and it renders Mob's native
  # `Progress`, which `MobBridge.kt:2980` hands to Material 3 1.2.0's
  # `LinearProgressIndicator`. That composable ends its modifier chain with
  # `.size(240.dp, 4.dp)`, applied after the caller's, so the bar would be
  # 240 wide inside a weighted slot about 200 wide and 4 tall where the drawing
  # says 8 — and `MobProgress` forwards no track colour, so the unfilled part
  # would paint the theme's `linearTrackColor` rather than `#EFECE7`. Its
  # `strokeCap` is `Butt`, so the 4pt radius has nowhere to go either.
  @doc false
  def bar({name, share, value, color}, gap?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column width={76}>
          <Text
            text={name}
            font_family="fa"
            text_size={12.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Box fill_width={true} height={8} corner_radius={4} background={Palette.paper()}>
            <Row fill_width={true}>
              <Box weight={share} height={8} corner_radius={4} background={color} />
              <Spacer weight={1.0 - share} />
            </Row>
          </Box>
        </Box>
        <Spacer size={12} />
        <Column width={30}>
          <Text
            text={value}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            text_align="absolute_left"
            max_lines={1}
          />
        </Column>
      </Row>
      {Kati.Screens.StatsFa.bar_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def bar_gap(false), do: ~MOB"<Spacer size={0} />"
  def bar_gap(true), do: ~MOB"<Spacer size={13} />"

  @doc false
  def week(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} height={56} align="bottom">
          {year.week
           |> Enum.map(fn {height, on?} -> Kati.Screens.StatsFa.week_bar(height, on?) end)
           |> Enum.intersperse(Kati.Screens.StatsFa.week_gap())}
        </Row>
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          {Enum.map(year.days, fn day -> Kati.Screens.StatsFa.week_label(day) end)}
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def week_gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def week_bar(height, on?) do
    color = if on?, do: Palette.ink(), else: Palette.placeholder()

    ~MOB"<Box weight={1.0} height={height} corner_radius={5} background={color} />"
  end

  @doc false
  def week_label(day) do
    ~MOB"""
    <Box weight={1.0}>
      <Text
        text={day}
        font_family="fa"
        text_size={10.5}
        text_color={Palette.tertiary()}
        text_align="center"
        max_lines={1}
      />
    </Box>
    """
  end

  # A dashed 1.5pt rule in the drawing; solid here, because `Modifier.border`
  # through this bridge takes a width and a colour and no dash pattern.
  @doc false
  def note(year) do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Text
        text={year.note}
        font_family="fa"
        text_size={12.5}
        line_height={1.7}
        text_color={Palette.ink_soft()}
        weight={1.0}
      />
    </Row>
    """
  end

  # The dock's four tabs and the FAB go to `Kati.Screens.Fa.dock_tap/3`, which
  # is where the other three Persian roots send theirs.
  #
  # This screen used to answer them here against `Kati.Shell.screen_for/1`,
  # and that table is the ENGLISH one: tapping home, calendar or library from
  # آمار landed on screen 01, 02 or 03 and left the app in English, LTR, with
  # no way back to Persian except Settings. The tags are identical either way,
  # so nothing about the drawn bar changes — only which four screens it means.
  # The share disc, and the Persian card page rather than the English one — the
  # same rule `Kati.Screens.HomeFa` follows for its search field.
  def handle_info({:tap, :share_year}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.YearShareFa)}

  def handle_info({:tap, :open_goals}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.GoalsFa)}

  def handle_info({:tap, :open_money}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MoneyFa)}

  def handle_info({:tap, :open_health}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.HealthFa)}

  def handle_info({:tap, tag}, socket), do: Kati.Screens.Fa.dock_tap(tag, :stats, socket)

  def handle_info(_message, socket), do: {:noreply, socket}
end
