defmodule Kati.Screens.Calendars do
  @moduledoc """
  Screen 32 — Calendars, pushed under Settings.

  Built to `.scratch/design/screens/32.html`. Two-way sync stated plainly, in
  three groups that answer three different questions: which accounts come in,
  which of their calendars are drawn, and exactly what Kati is allowed to
  write out.

  Write back gets the grey dash rather than the orange one. It is the
  consequence of the two groups above it — you cannot push to a calendar you
  have not connected — and orange means new/now.

  Each calendar row leads with a 12pt swatch instead of an icon tile, because
  the colour is the thing being configured: it is what the imported events
  will be drawn in on screens 02 and 09.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Settings.CalendarsSample, as: Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :calendars, %{
      connected: Sample.connected(),
      accounts: Sample.accounts(),
      add_account: Sample.add_account(),
      calendars: Sample.calendars(),
      write_back: Sample.write_back(),
      note: Sample.note()
    })
  end

  @doc false
  def content(assigns) do
    c = assigns.calendars

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("Calendars", c.connected)}
        {UI.eyebrow("Accounts")}
        {Kati.Screens.Calendars.accounts(c)}
        {UI.eyebrow("Which calendars show")}
        {Kati.Screens.Calendars.calendars(c.calendars)}
        {SettingsList.eyebrow_muted("Write back")}
        {Kati.Screens.Calendars.write_back(c.write_back)}
        {SettingsList.note("lock", c.note)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def accounts(c) do
    rows =
      Enum.map(c.accounts, fn a -> Kati.Screens.Calendars.account_row(a) end) ++
        [Kati.Screens.Calendars.add_row(c.add_account)]

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def account_row(a) do
    SettingsList.row(
      SettingsList.icon_tile(a.icon),
      SettingsList.body(a.title, a.sub),
      Kati.Screens.Calendars.status(a.status, a.state),
      padding: 13
    )
  end

  @doc false
  def status(label, :live), do: SettingsList.status_pill(label, 0xFF3E8460, 0x294E9A73)
  def status(label, :stale), do: SettingsList.status_pill(label, 0xFFB4553C, 0x24B4553C)

  # The one row with no trailing control and no filled tile: a dashed square
  # that reads as a slot waiting to be filled rather than a button.
  @doc false
  def add_row(label) do
    SettingsList.row(
      Kati.Screens.Calendars.add_tile(),
      SettingsList.body_muted(label),
      nil,
      padding: 13,
      rule: false
    )
  end

  @doc false
  def add_tile do
    ~MOB"""
    <Box
      width={30}
      height={30}
      corner_radius={9}
      border_color={0x331A1917}
      border_width={1.5}
      align="center"
    >
      {Kati.UI.symbol("add", size: 16, color: 0xFF8A8479)}
    </Box>
    """
  end

  @doc false
  def calendars(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Calendars.calendar_row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def calendar_row(row, rule?) do
    SettingsList.row(
      Kati.Screens.Calendars.swatch(row.color),
      Kati.Screens.Calendars.calendar_title(row),
      SettingsList.switch(row.on),
      padding: 13,
      rule: rule?
    )
  end

  @doc false
  def swatch(color) do
    ~MOB"""
    <Box width={12} height={12} corner_radius={4} background={color} />
    """
  end

  # A calendar that is not drawn has a grey title as well as a grey swatch, so
  # the row reads as off at a glance rather than only at the switch.
  @doc false
  def calendar_title(%{on: true, title: title}), do: SettingsList.body(title)
  def calendar_title(%{title: title}), do: SettingsList.body_muted(title)

  @doc false
  def write_back(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Calendars.write_row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def write_row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      SettingsList.switch(row.on),
      padding: 13,
      rule: rule?
    )
  end
end
