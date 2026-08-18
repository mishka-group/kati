defmodule Kati.Screens.Calendar do
  @moduledoc """
  Screen 02 — the Calendar root, day view.

  The design calls the calendar the spine every other section feeds into, so
  this view mixes kinds deliberately: an air date, an appointment, a habit and
  a renewal all share one gutter.

  The real model — recurrence, timezones, external mirrors — is #47/#48. This
  is the surface those will render into.
  """
  use Kati.Screens.Root, root: :calendar

  @impl Kati.Screens.Root
  def load(socket) do
    Mob.Socket.assign(socket, :events, Kati.Calendars.Today.rows())
  end

  alias Kati.UI

  defp content(assigns) do
    ~MOB"""
    <Scroll background={:background}>
      <Column background={:background} fill_width={true}>
        <Spacer size={52} />
        {header()}
        <Spacer size={17} />
        {day_strip()}
        <Spacer size={17} />
        {filters()}
        <Spacer size={22} />
        {day(assigns)}
        <Spacer size={150} />
      </Column>
    </Scroll>
    """
  end

  defp header do
    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      <Text text="AUGUST 2026" text_size={11} text_color={:muted} letter_spacing={0.14} />
      <Spacer size={5} />
      <Text
        text="Tuesday 18"
        text_size={34}
        text_color={:on_surface}
        font_weight="bold"
        letter_spacing={-1.0}
      />
    </Column>
    """
  end

  # Seven cells, chunked by a declared count — Row does not wrap.
  defp day_strip do
    days = [
      {"SAT", "15", false},
      {"SUN", "16", false},
      {"MON", "17", false},
      {"TUE", "18", true},
      {"WED", "19", false},
      {"THU", "20", false},
      {"FRI", "21", false}
    ]

    ~MOB"""
    <Scroll axis="horizontal">
      <Row>
        <Spacer size={21} />
        {Enum.map(days, fn {d, n, today?} -> Kati.UI.day_cell(d, n, today?) end)}
      </Row>
    </Scroll>
    """
  end

  defp filters do
    ~MOB"""
    <Scroll axis="horizontal">
      <Row>
        <Spacer size={21} />
        {UI.chip("All", :selected)}
        {UI.chip("Screen", false)}
        {UI.chip("Personal", false)}
        {UI.chip("Money", false)}
      </Row>
    </Scroll>
    """
  end

  defp day(assigns) do
    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      {UI.section_title("ALL DAY")}
      {UI.card(all_day_band())}
      <Spacer size={22} />
      {UI.section_title("TODAY")}
      {Kati.Screens.Calendar.rows(assigns)}
    </Column>
    """
  end

  @doc false
  def rows(assigns) do
    case assigns[:events] do
      [] -> Kati.Screens.Calendar.empty_state()
      nil -> Kati.Screens.Calendar.empty_state()
      events -> Enum.map(events, &Kati.Screens.Calendar.event_row/1)
    end
  end

  @doc false
  def empty_state do
    ~MOB"""
    <Column fill_width={true} padding_top={13}>
      <Text text="Nothing scheduled" text_size={14} text_color={:on_surface} />
      <Spacer size={4} />
      <Text
        text="Device calendars appear here once you grant access."
        text_size={12}
        text_color={:muted}
      />
    </Column>
    """
  end

  @doc false
  def event_row(e) do
    UI.timeline_row(e.time, e.title, e.meta, e.now?)
  end

  defp all_day_band do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Apple TV+ renews" text_size={14} text_color={:on_surface} />
      <Spacer size={3} />
      <Text text="Money · £8.99 · merged with 1 other renewal" text_size={11} text_color={:muted} />
    </Column>
    """
  end
end
