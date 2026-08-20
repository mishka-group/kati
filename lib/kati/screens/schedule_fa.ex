defmodule Kati.Screens.ScheduleFa do
  @moduledoc """
  Screen 56 — برنامه, the Persian Schedule root.

  Built to `.scratch/design/screens/56.html`. Screen 02's page, right to left:
  the header with its two 44pt discs, seven `flex:1` day cells at radius 16
  with a 2pt gap, the filter chips, and a 44pt time gutter beside every card.

  ## What changes, and why it is not mirroring

  **The week restarts.** شنبه is the first column, not Monday moved to the
  right. `Kati.Screens.ScheduleFa.Sample` holds the order for that reason, and
  `Kati.Calendar.Shamsi` already returns weeks the same way, so nothing here
  reverses a list.

  **The selected day is card white.** Screen 02 paints today ink; this drawing
  lifts ی/۲۵ onto `#FBFAF8` with the button shadow and leaves the ink for the
  20:00 gutter figure. Copying 02's ink cell would have been the reasonable
  guess and the wrong one.

  **The time gutter is at the right,** which the direction does on its own —
  the gutter is simply the first child of the row.

  ## Five rows, five shapes

  The drawing spends the page proving a schedule row is not one row repeated:
  a finished habit on the flat `#F4F1EC` card with a filled `check_circle`; an
  appointment lifted on card white; a reminder whose lead is a hollow circle
  rather than a rule; a payment behind a 26pt `#E4E0D9` glyph tile; and the
  evening's episode on its own deeper-shadowed card with the poster inline and
  a cream pill. `tone`, `lead` and `trailing` in the sample carry exactly those
  three axes.

  Persian text is Vazirmatn throughout, digits included — see
  `Kati.Screens.Fa` for why the times cannot be set in DM Mono.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.ScheduleFa.Sample
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())

    socket
    |> Mob.Socket.assign(:header, Sample.header())
    |> Mob.Socket.assign(:events, Sample.events())
    |> Mob.Socket.assign(:feature, Sample.feature())
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    Fa.frame(:calendar, Kati.Screens.ScheduleFa.content(assigns))
  end

  @doc false
  def content(assigns) do
    header = assigns.header
    events = assigns.events
    feature = assigns.feature

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.ScheduleFa.header(header)}
        {Kati.Screens.ScheduleFa.day_strip()}
        {Kati.Screens.ScheduleFa.week_note()}
        {Kati.Screens.ScheduleFa.chips()}
        {Kati.Screens.ScheduleFa.timeline(events)}
        {Kati.Screens.ScheduleFa.feature_row(feature)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(header) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={header.title}
            font_family="fa"
            font_weight="bold"
            text_size={27}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={header.subtitle}
            font_family="fa"
            text_size={11.5}
            text_color={0xFFA9A29A}
            max_lines={1}
          />
        </Column>
        {Fa.disc("search", :open_search)}
        <Spacer size={9} />
        {Fa.disc("more_horiz", :open_menu)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def day_strip do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Sample.days()
         |> Enum.map(&Kati.Screens.ScheduleFa.day_cell/1)
         |> Enum.intersperse(Kati.Screens.ScheduleFa.cell_gap())}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={2} />"

  # Two clauses rather than one with conditional colours: the unselected cell
  # carries no fill and no shadow at all, and a transparent shadow is not the
  # same node as no shadow.
  @doc false
  def day_cell(%{selected?: true} = day) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={16}
        shadow={Kati.Theme.shadow_button()}
        padding_top={9}
        padding_bottom={11}
      >
        <Text
          text={day.name}
          font_family="fa"
          font_weight="medium"
          text_size={11}
          text_color={0xFF8A8479}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={day.num}
          font_family="fa"
          font_weight="medium"
          text_size={15}
          text_color={0xFF1A1917}
          text_align="center"
        />
      </Column>
    </Box>
    """
  end

  def day_cell(day) do
    ~MOB"""
    <Box weight={1.0}>
      <Column fill_width={true} corner_radius={16} padding_top={9} padding_bottom={11}>
        <Text
          text={day.name}
          font_family="fa"
          font_weight="medium"
          text_size={11}
          text_color={0xFFB3ACA2}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={day.num}
          font_family="fa"
          font_weight="medium"
          text_size={15}
          text_color={0xFF8A8479}
          text_align="center"
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def week_note do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {UI.symbol("info", size: 15, color: 0xFFB3ACA2)}
        <Spacer size={8} />
        <Text
          text={Sample.week_note()}
          font_family="fa"
          text_size={11.5}
          text_color={0xFF8A8479}
        />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Sample.chips()
           |> Enum.with_index()
           |> Enum.map(fn {label, i} -> Kati.Screens.ScheduleFa.chip(label, i == 0) end)}
        </Row>
      </Scroll>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def chip(label, on?) do
    bg = if on?, do: 0xFF1A1917, else: 0xFFFBFAF8
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    shadow = if on?, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={bg}
      shadow={shadow}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      <Text text={label} font_family="fa" font_weight="semibold" text_size={12.5} text_color={fg} max_lines={1} />
      <Spacer size={7} />
    </Row>
    """
  end

  @doc false
  def timeline(events) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(events, &Kati.Screens.ScheduleFa.event_row/1)}
    </Column>
    """
  end

  @doc false
  def event_row(row) do
    bg = if row.tone == :done, do: 0xFFF4F1EC, else: 0xFFFBFAF8
    shadow = if row.tone == :done, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={14}>
          <Text text={row.time} font_family="fa" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row
            fill_width={true}
            background={bg}
            corner_radius={18}
            shadow={shadow}
            padding_left={15}
            padding_right={15}
            padding_top={13}
            padding_bottom={13}
            align="center"
          >
            {Kati.Screens.ScheduleFa.lead(row.lead)}
            <Spacer size={12} />
            <Column weight={1.0}>
              <Text
                text={row.title}
                font_family="fa"
                font_weight="semibold"
                text_size={13.5}
                text_color={:on_surface}
                max_lines={1}
              />
              <Spacer size={3} />
              <Text text={row.meta} font_family="fa" text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
            </Column>
            {Kati.Screens.ScheduleFa.trailing(row.trailing)}
          </Row>
        </Box>
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  # The drawing stretches the rule to the card (`align-self:stretch`). Nothing
  # in this bridge stretches a child inside a wrap-height Row, so it is the
  # card's own content height: 13.5 + 3 + 11.5 of text at the design's
  # leading, which measures 36.
  @doc false
  def lead({:rule, color}) do
    ~MOB"<Box width={3} height={36} corner_radius={2} background={color} />"
  end

  def lead({:icon, name}) do
    ~MOB"""
    <Column>
      {Kati.UI.symbol(name, size: 21, color: 0xFFB3ACA2)}
    </Column>
    """
  end

  def lead({:badge, name}) do
    ~MOB"""
    <Box width={26} height={26} corner_radius={8} background={0xFFE4E0D9} align="center">
      {Kati.UI.symbol(name, size: 15, color: 0xFF5C574F)}
    </Box>
    """
  end

  @doc false
  def trailing(nil), do: ~MOB"<Spacer size={0} />"

  def trailing({:icon, name, color}) do
    ~MOB"""
    <Row align="center">
      <Spacer size={12} />
      {Kati.UI.symbol(name, size: 21, color: color, fill: true)}
    </Row>
    """
  end

  # The evening's episode: padding 15 rather than 13/15, a deeper shadow
  # (`0 16px 30px -18px rgba(26,25,23,.75)`), the poster inline, and the gutter
  # figure in ink at 500 rather than muted.
  #
  # The accent rule is a declared 72 because that is the card's content height —
  # title, meta and the pill beneath them — and a Row gives a child no way to
  # inherit it. At 60 the rule stopped level with the middle of the pill, which
  # reads as a rule that failed to draw rather than as one marking the card.
  @doc false
  def feature_row(feature) do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column width={44} padding_top={15}>
        <Text
          text={feature.time}
          font_family="fa"
          font_weight="medium"
          text_size={12}
          text_color={0xFF1A1917}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Box weight={1.0}>
        <Row
          fill_width={true}
          background={0xFFFBFAF8}
          corner_radius={18}
          shadow="0 1 2 0 #0D1A1917 | 0 16 30 -18 #BF1A1917"
          padding={15}
          align="top"
        >
          <Box width={3} height={72} corner_radius={2} background={0xFFE8823C} />
          <Spacer size={12} />
          {Kati.Screens.ScheduleFa.poster(feature.seed)}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text={feature.title}
              font_family="fa"
              font_weight="bold"
              text_size={14}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text text={feature.meta} font_family="fa" text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
            <Spacer size={9} />
            <Row
              height={24}
              corner_radius={12}
              background={0xFFFBF1DE}
              padding_left={10}
              padding_right={10}
              align="center"
            >
              <Box width={5} height={5} corner_radius={3} background={0xFFE8823C} />
              <Spacer size={5} />
              <Text
                text={feature.pill}
                font_family="fa"
                font_weight="semibold"
                text_size={11}
                text_color={0xFF96723C}
                max_lines={1}
              />
            </Row>
          </Column>
        </Row>
      </Box>
    </Row>
    """
  end

  @doc false
  def poster(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={42} height={60} corner_radius={8} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={42} height={60} corner_radius={8} content_mode="fill" />
        """
    end
  end

  def handle_info({:tap, :open_search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :calendar, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
