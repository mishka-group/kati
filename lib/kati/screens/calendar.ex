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
  calendar via `CalendarContract`.
  """
  use Kati.Screens.Root, root: :calendar

  alias Kati.Theme


  @impl true
  def load(socket) do
    date = Kati.Time.today()
    Mob.Socket.assign(socket, date: date, rows: Kati.Calendars.Today.rows(date))
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
        <Box fill_width={true} height={1} background={0x141A1917} />
        <Spacer size={16} />
        {Kati.Screens.Calendar.filters()}
        {Kati.Screens.Calendar.timeline(rows)}
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

  @doc false
  def disc(icon, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box
      width={44}
      height={44}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_button()}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
  end

  @doc false
  def month_row(date) do
    label = "#{Kati.Time.month_name(date.month)} #{date.year}"

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Text text={label} text_size={20} font_weight="bold" letter_spacing={-0.025} text_color={:on_surface} />
        <Spacer size={6} />
        {Kati.UI.symbol("unfold_more", size: 19, color: 0xFF8A8479)}
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

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def day_cell(date, today?) do
    tap = {self(), :open_day}

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
  def filters do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {["All", "Screen", "Personal", "Money"]
           |> Enum.with_index()
           |> Enum.map(fn {label, i} -> Kati.Screens.Calendar.chip(label, i == 0) end)}
        </Row>
      </Scroll>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def chip(label, on?) do
    bg = if on?, do: Theme.ink(), else: Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={bg} padding_left={15} padding_right={15} align="center">
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      <Spacer size={7} />
    </Row>
    """
  end

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
      {Enum.map(rows, fn row -> Kati.Screens.Calendar.event_row(row) end)}
    </Column>
    """
  end

  @doc false
  def event_row(row) do
    # Orange only ever means new/now; everything else takes ink.
    rule = if row.now?, do: 0xFFE8823C, else: Theme.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={15}>
          <Text text={row.time} font_family="mono" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row
            fill_width={true}
            background={Kati.Theme.card(:light)}
            corner_radius={18}
            shadow={Kati.Theme.shadow_card()}
            padding_left={15}
            padding_right={15}
            padding_top={14}
            padding_bottom={14}
            align="center"
          >
            <Box width={3} height={34} corner_radius={2} background={rule} />
            <Spacer size={12} />
            <Column weight={1.0}>
              <Text text={row.title} text_size={14} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
              <Spacer size={3} />
              <Text text={row.meta} text_size={12} text_color={0xFF8A8479} max_lines={1} />
            </Column>
          </Row>
        </Box>
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @impl true
  def handle_tap(:open_day, socket), do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Day)}
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
