defmodule Kati.Screens.Home do
  @moduledoc """
  Screen 01 — the Home root: "Today, across every section".

  Composition follows the design: greeting, search, the fixed
  "New this week" hero, a Continue-watching rail, the Sections grid, and the
  "Rest of today" timeline.

  Content is static sample data. The media and calendar domains arrive with
  their own tickets (#48, #73, #74); wiring this screen to them before they
  exist would mean inventing a schema here, which is exactly what those
  tickets are for. The point of this screen today is that the *surface* is
  real and judgeable.
  """
  use Kati.Screens.Root, root: :home

  alias Kati.UI

  defp content(_assigns) do
    ~MOB"""
    <Scroll background={:background}>
      <Column background={:background} fill_width={true}>
        <Spacer size={52} />
        {greeting()}
        <Spacer size={17} />
        {search()}
        <Spacer size={21} />
        {hero()}
        <Spacer size={26} />
        {continue_watching()}
        <Spacer size={26} />
        {sections()}
        <Spacer size={22} />
        {rest_of_today()}
        <Spacer size={150} />
      </Column>
    </Scroll>
    """
  end

  defp greeting do
    {date_line, part_of_day} = Kati.Screens.Home.today()

    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      <Text text={date_line} text_size={11} text_color={:muted} letter_spacing={0.14} />
      <Spacer size={3} />
      <Text text={Kati.Screens.Home.today_fa()} text_size={11} text_color={:muted} />
      <Spacer size={5} />
      <Text
        text={part_of_day}
        text_size={34}
        text_color={:on_surface}
        font_weight="bold"
        letter_spacing={-1.0}
      />
    </Column>
    """
  end

  @doc "Today in Solar Hijri, e.g. یکشنبه ۲۵ مرداد ۱۴۰۵. Display only — storage stays Gregorian."
  def today_fa do
    Kati.Calendar.Shamsi.format(Kati.Time.today(), :long)
  end

  @doc false
  def today do
    # Device zone, not UTC. The greeting is the visible half of this: at
    # 00:30 in Amsterdam a UTC clock reads 22:30 and says "Good evening" on
    # a screen that also names the wrong day.
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

  defp search do
    tap = {self(), :open_search}

    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      <Box background={:surface} corner_radius={22} padding={14} fill_width={true} on_tap={tap}>
        <Row align="center">
          <Icon name="search" text_size={18} text_color={:muted} text="Search" />
          <Spacer size={9} />
          <Text text="Search everything" text_size={13} text_color={:muted} />
        </Row>
      </Box>
    </Column>
    """
  end

  # The one place orange is allowed: this hero is literally "new".
  defp hero do
    accent = Kati.Theme.accent()
    cream = Kati.Theme.cream(:light)
    tap = {self(), :open_inbox}

    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      <Box background={cream} corner_radius={20} padding={21} fill_width={true} on_tap={tap}>
        <Column fill_width={true}>
          <Row align="center">
            <Box width={7} height={7} background={accent} corner_radius={4} />
            <Spacer size={7} />
            <Text text="NEW THIS WEEK" text_size={10} text_color={accent} letter_spacing={0.16} />
          </Row>
          <Spacer size={11} />
          <Text
            text="3 new episodes are waiting"
            text_size={19}
            text_color={:on_surface}
            letter_spacing={-0.5}
          />
          <Spacer size={13} />
          <Row align="center">
            <Text text="Open inbox" text_size={13} text_color={:on_surface} />
            <Spacer size={5} />
            <Icon name="chevron_right" text_size={16} text_color={:on_surface} text="Open inbox" />
          </Row>
        </Column>
      </Box>
    </Column>
    """
  end

  defp continue_watching do
    ~MOB"""
    <Column fill_width={true}>
      <Column padding_left={21}>
        {UI.section_title("CONTINUE WATCHING")}
      </Column>
      <Scroll axis="horizontal">
        <Row>
          <Spacer size={21} />
          {UI.poster("Severance · S2 E6", 0xFF3B4A52)}
          {UI.poster("Dune: Part Two", 0xFF6E5A43)}
          {UI.poster("Shōgun · S1 E9", 0xFF4A3B3B)}
          {UI.poster("The Bear · S3 E2", 0xFF3E4A3B)}
        </Row>
      </Scroll>
    </Column>
    """
  end

  # No wrap primitive and no geometry feedback, so the grid is chunked by a
  # declared column count rather than measured.
  defp sections do
    card = Kati.Theme.card(:light)

    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      {UI.section_title("SECTIONS")}
      <Row>
        {UI.section_tile("Meals", "3 planned today", card)}
        {UI.section_tile("Habits", "2 of 4 done", card)}
      </Row>
      <Row>
        {UI.section_tile("Money", "£41.20 this week", card)}
        {UI.section_tile("Settings", "Sources, backup", card)}
      </Row>
    </Column>
    """
  end

  defp rest_of_today do
    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      {UI.section_title("REST OF TODAY")}
      {UI.timeline_row("19:00", "Dinner — Sheet-pan chicken", "Meals · 620 kcal", false)}
      {UI.timeline_row("20:00", "Severance S2 E6", "Airs tonight · Apple TV+", true)}
      {UI.timeline_row("21:30", "Reading — The Bee Sting", "p. 214 / 380", false)}
      {UI.timeline_row("23:00", "Wind down", "Habit · not done", false)}
    </Column>
    """
  end

  @impl Kati.Screens.Root
  def handle_tap(:open_search, socket), do: {:noreply, socket}
  def handle_tap(:open_inbox, socket), do: {:noreply, socket}
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
