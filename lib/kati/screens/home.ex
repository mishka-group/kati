defmodule Kati.Screens.Home do
  @moduledoc """
  Screen 01 — Home.

  Built to `.scratch/design/screens/01.html`, where every number is literal:
  the `64px 21px 132px` frame, the 44px header discs, the 52px search bar at
  radius 26, the cream hero at radius 24 with its three overlapping posters,
  the two continue-watching cards, three section tiles, and the rest-of-today
  card whose rows are separated by a `rgba(26,25,23,.07)` hairline.

  The design's one fixed element is the **New this week** card; everything
  below it is a shelf that can be swapped as sections arrive.

  ## Real data versus the drawing

  The date, the greeting and *Rest of today* come from the device — the last
  from `Kati.Calendars.Today`, so it shows the user's actual calendar. The
  hero, Continue watching and the section counts still render the drawing's
  own copy, because the Screen domain that would supply them is not built
  yet. Those are placeholders that look exactly like the design and will be
  fed by their domains as each lands, rather than empty space that makes the
  screen impossible to compare against the drawing.
  """
  use Kati.Screens.Root, root: :home

  alias Kati.Theme
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :timeline, Kati.Calendars.Today.rows())

  @doc false
  def content(assigns) do
    timeline = assigns.timeline

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Home.header()}
        {Kati.Screens.Home.search()}
        {UI.eyebrow("New this week")}
        {Kati.Screens.Home.hero()}
        {UI.eyebrow("Continue watching")}
        {Kati.Screens.Home.continue_watching()}
        {UI.eyebrow("Sections")}
        {Kati.Screens.Home.sections()}
        {UI.eyebrow("Rest of today", trailing: "See all")}
        {Kati.Screens.Home.rest_of_today(timeline)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header do
    {date_line, greeting} = today()

    ~MOB"""
    <Column fill_width={true}>
    <Row fill_width={true} vertical_align="top">
      <Column weight={1.0}>
        <Text
          text={String.upcase(date_line)}
          font_family="mono"
          text_size={11}
          letter_spacing={0.14}
          text_color={0xFFA9A29A}
        />
        <Spacer size={7} />
        <Text
          text={greeting}
          text_size={28}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
        />
      </Column>
      {Kati.Screens.Home.disc("notifications", true, :notifications)}
      <Spacer size={9} />
      {Kati.Screens.Home.disc("calendar_month", false, :open_calendar)}
    </Row>
    <Spacer size={20} />
    </Column>
    """
  end

  # A 44px disc. The unread dot is 8px of #E8823C with a 2px paper-coloured
  # ring, which is how the design keeps it legible against the icon behind it.
  @doc false
  def disc(icon, badge?, tag) do
    tap = {self(), tag}
    card = Theme.card(:light)
    shadow = Theme.shadow_button()

    ~MOB"""
    <Box width={44} height={44} background={card} corner_radius={22} shadow={shadow} align="center" on_tap={tap}>
      {UI.symbol(icon, size: 21)}
      {Kati.Screens.Home.badge(badge?)}
    </Box>
    """
  end

  @doc false
  def badge(false), do: ~MOB"<Spacer size={0} />"

  def badge(true) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top_trailing">
      <Column padding_top={9} padding_right={10}>
        <Box
          width={8}
          height={8}
          corner_radius={4}
          background={0xFFE8823C}
          border_width={2}
          border_color={0xFFFBFAF8}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def search do
    tap = {self(), :open_search}
    card = Theme.card(:light)
    shadow = Theme.shadow_search()

    ~MOB"""
    <Column fill_width={true}>
    <Box
      fill_width={true}
      height={52}
      background={card}
      corner_radius={26}
      shadow={shadow}
      padding_left={18}
      padding_right={18}
      on_tap={tap}
    >
      <Row fill_width={true} fill_height={true} vertical_align="center">
        {UI.symbol("search", size: 20, color: 0xFFA9A29A)}
        <Spacer size={11} />
        <Text
          text="Search films, shows, events…"
          text_size={14.5}
          text_color={0xFFA9A29A}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={11} />
        {UI.symbol("tune", size: 19)}
      </Row>
    </Box>
    <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def hero do
    tap = {self(), :open_inbox}
    ink = Theme.ink()

    ~MOB"""
    <Column fill_width={true}>
    <Box
      fill_width={true}
      background={0xFFFBF1DE}
      corner_radius={24}
      shadow={Kati.Theme.shadow_hero()}
      padding_left={19}
      padding_right={19}
      padding_top={19}
      padding_bottom={17}
    >
      <Column fill_width={true}>
        <Row fill_width={true} vertical_align="top">
          <Column weight={1.0}>
            <Text
              text="3 new episodes are waiting"
              text_size={21}
              font_weight="bold"
              letter_spacing={-0.025}
              line_height={1.2}
              text_color={:on_surface}
            />
            <Spacer size={8} />
            <Text
              text="One premiere · two titles leave Lumen+ on Friday"
              text_size={13}
              line_height={1.45}
              text_color={0xFF8A7B60}
            />
          </Column>
          <Spacer size={14} />
          {Kati.Screens.Home.poster_stack()}
        </Row>
        <Spacer size={17} />
        <Row vertical_align="center">
          <Box height={40} corner_radius={20} background={ink} padding_left={18} padding_right={18} on_tap={tap}>
            <Row fill_height={true} vertical_align="center">
              <Text text="Open inbox" text_size={13.5} font_weight="semibold" text_color={0xFFFBFAF8} />
              <Spacer size={7} />
              {UI.symbol("arrow_forward", size: 17, color: 0xFFFBFAF8)}
            </Row>
          </Box>
          <Spacer size={10} />
          <Text text="last check 18:02" font_family="mono" text_size={11} text_color={0xFFB09A72} />
        </Row>
      </Column>
    </Box>
    <Spacer size={26} />
    </Column>
    """
  end

  # Three 46x64 posters overlapping leftward by 16, each ringed 2px in the
  # hero's own cream so the overlap reads as a stack rather than a smear.
  #
  # The design does this with `margin-left:-16px`, which both shifts the poster
  # AND shrinks the box it occupies: three 46px posters at -16 measure
  # 46*3 - 16*2 = 106, not 138. Negative padding cannot express that — Compose
  # throws and takes the activity down — so the stack is a fixed 106-wide Box
  # with each poster offset by 30. Same geometry, stated once.
  @doc false
  def poster_stack do
    ~MOB"""
    <Box width={106} height={64}>
      {Enum.map(0..2, fn i -> Kati.Screens.Home.poster(i) end)}
    </Box>
    """
  end

  @doc false
  def poster(index) do
    shadow = Theme.shadow_poster()
    offset = index * 30

    ~MOB"""
    <Box
      width={46}
      height={64}
      offset_x={offset}
      corner_radius={9}
      background={0xFFEADFC6}
      border_width={2}
      border_color={0xFFFBF1DE}
      shadow={shadow}
    />
    """
  end

  @doc false
  def continue_watching do
    ~MOB"""
    <Column fill_width={true}>
    <Row fill_width={true} vertical_align="top">
      {Kati.Screens.Home.watch_card("The Long Hollow", "S2 · E6 · 18m left", 0.62)}
      <Spacer size={13} />
      {Kati.Screens.Home.watch_card("Salt & Iron", "S1 · E3 · 41m left", 0.24)}
    </Row>
    <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def watch_card(title, meta, progress) do
    card = Theme.card(:light)
    shadow = Theme.shadow_card()
    ink = Theme.ink()

    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} background={card} corner_radius={20} shadow={shadow} padding={11}>
        <Column fill_width={true}>
          <Box fill_width={true} height={112} corner_radius={12} background={0xFFE4E0D9} />
          <Spacer size={11} />
          <Text
            text={title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.02}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
          <Spacer size={10} />
          <Box fill_width={true} height={4} corner_radius={2} background={0xFFE7E3DC}>
            <Row fill_width={true}>
              <Box weight={progress} height={4} corner_radius={2} background={ink} />
              <Spacer weight={1.0 - progress} />
            </Row>
          </Box>
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def sections do
    ~MOB"""
    <Column fill_width={true}>
    <Row fill_width={true} vertical_align="top">
      {Kati.Screens.Home.tile("restaurant", "Meals", "Dinner 19:30", 0xFFB08E55)}
      <Spacer size={9} />
      {Kati.Screens.Home.tile("bolt", "Habits", "2 left today", 0xFF4E9A73)}
      <Spacer size={9} />
      {Kati.Screens.Home.tile("tune", "Settings", nil, nil)}
    </Row>
    <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def tile(icon, title, meta, dot) do
    card = Theme.card(:light)
    shadow = Theme.shadow_card_soft()

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        background={card}
        corner_radius={18}
        shadow={shadow}
        padding_left={12}
        padding_right={12}
        padding_top={13}
        padding_bottom={13}
      >
        <Column fill_width={true}>
          <Row fill_width={true} vertical_align="center">
            {UI.symbol(icon, size: 19)}
            <Spacer weight={1.0} />
            {Kati.Screens.Home.dot(dot)}
          </Row>
          <Spacer size={10} />
          <Text
            text={title}
            text_size={12.5}
            font_weight="bold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.Home.tile_meta(meta)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def dot(nil), do: ~MOB"<Spacer size={0} />"
  def dot(color), do: ~MOB"<Box width={6} height={6} corner_radius={3} background={color} />"

  @doc false
  def tile_meta(nil), do: ~MOB"<Spacer size={0} />"

  def tile_meta(meta) do
    ~MOB"""
    <Column>
      <Spacer size={3} />
      <Text text={meta} font_family="mono" text_size={9.5} text_color={0xFFA9A29A} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def rest_of_today([]) do
    # The design never draws this empty, but a real device often is. Same card,
    # same padding, one line — rather than a card-shaped hole.
    card = Theme.card(:light)

    ~MOB"""
    <Box fill_width={true} background={card} corner_radius={20} shadow={Kati.Theme.shadow_card()} padding_left={15} padding_right={15} padding_top={18} padding_bottom={18}>
      <Text text="Nothing else today" text_size={14} text_color={0xFF8A8479} />
    </Box>
    """
  end

  def rest_of_today(rows) do
    card = Theme.card(:light)
    last = length(rows) - 1

    ~MOB"""
    <Box fill_width={true} background={card} corner_radius={20} shadow={Kati.Theme.shadow_card()} padding_left={15} padding_right={15} padding_top={5} padding_bottom={5}>
      <Column fill_width={true}>
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} ->
          Kati.Screens.Home.timeline_row(row, i < last)
        end)}
      </Column>
    </Box>
    """
  end

  @doc false
  def timeline_row(row, rule?) do
    accent = if row.now?, do: 0xFFE8823C, else: 0xFFC4BDB3
    icon = if row.now?, do: "notifications_active", else: "radio_button_unchecked"

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="center" padding_top={14} padding_bottom={14}>
        <Box width={40}>
          <Text text={row.time} font_family="mono" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
        </Box>
        <Spacer size={14} />
        <Box width={3} height={34} corner_radius={2} background={accent} />
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={14}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.meta} text_size={12} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={14} />
        {UI.symbol(icon, size: 20, color: 0xFFC4BDB3)}
      </Row>
      {Kati.Screens.Home.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  @doc "Today's date line and greeting, in the device's zone."
  def today do
    now = Kati.Time.now()
    day = Kati.Time.day_name(now)
    month = Kati.Time.month_name(now.month)

    greeting =
      cond do
        now.hour < 12 -> "Good morning"
        now.hour < 18 -> "Good afternoon"
        true -> "Good evening"
      end

    {"#{day} · #{now.day} #{month}", greeting}
  end
end
