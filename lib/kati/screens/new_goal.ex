defmodule Kati.Screens.NewGoal do
  @moduledoc """
  Screen 106 — New goal, a sheet over Goals.

  ## Ten types, grouped, so the field reads as four short rows

  The design's caption: *ten types grouped by section with a mono label each,
  so the chip field reads as four short rows rather than one wall.* Ten chips
  in a single flow is a paragraph of buttons; four labelled groups is a
  question with an answer in it.

  The grouping is `Kati.Goals.Goal.kinds/0`'s, not this screen's, so a new kind
  arrives in the right group without anyone editing a layout.

  ## The commit is at the foot, not in the header

  Also the caption's, and the reason is geometric: the sheet is long enough
  that a top-right Save would scroll out of reach, and a commit you have to
  scroll back to is a commit people abandon.

  ## Repeat is here **and** on the card

  Because it is a property of the goal rather than a setting about goals. Screen
  104 shows it on the card you are looking at; this sets it on the one you are
  making. Two places, one fact.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Goals.Goal
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Segmented
  alias Kati.UI.Sheet

  @periods [
    {"Week", :period_week},
    {"Month", :period_month},
    {"Year", :period_year},
    {"Custom", :period_custom}
  ]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:kind, :films)
     |> Mob.Socket.assign(:target, 120)
     |> Mob.Socket.assign(:period, :period_year)
     |> Mob.Socket.assign(:repeat, true)}
  end

  def render(assigns),
    do: Sheet.sheet("New goal", body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("What")}
      {Kati.Screens.NewGoal.kind_groups(assigns.kind)}
      {UI.eyebrow("How many")}
      {Kati.Screens.NewGoal.stepper(assigns.target, assigns.kind)}
      <Spacer size={20} />
      {UI.eyebrow("By when")}
      {Segmented.plain(Kati.Screens.NewGoal.periods(), assigns.period)}
      <Spacer size={16} />
      {Kati.Screens.NewGoal.repeat_row(assigns.repeat, assigns.period)}
      <Spacer size={16} />
      {Sheet.commit("Save goal", :save)}
    </Column>
    """
  end

  @doc false
  def periods, do: @periods

  @doc "Four labelled rows of chips, one per section."
  @spec kind_groups(atom()) :: map()
  def kind_groups(selected) do
    groups =
      Goal.sections()
      |> Enum.map(&Kati.Screens.NewGoal.kind_group(&1, selected))
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    ~MOB"""
    <Column fill_width={true}>
      {groups}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def kind_group(section, selected) do
    chips =
      Goal.kinds()
      |> Enum.filter(fn {_kind, s, _unit, _counts} -> s == section end)
      |> Enum.map(fn {kind, _s, unit, _counts} ->
        UI.chip(unit, selected: kind == selected, on_toggle: String.to_atom("kind_#{kind}"))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    assigns = %{section: section, chips: chips}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={String.upcase(@section)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_color={Palette.muted()}
      />
      <Spacer size={8} />
      <Row fill_width={true}>
        {@chips}
      </Row>
    </Column>
    """
  end

  @doc """
  The target, with the unit beside the number rather than under it.

  Beside, because `120 films` is the sentence being written and `120` with
  `films` on a second line is two facts that have to be joined by the reader.
  """
  @spec stepper(integer(), atom()) :: map()
  def stepper(target, kind) do
    assigns = %{target: Integer.to_string(target), unit: Goal.unit(kind)}

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.LogProgress.step_disc("remove", :step_down)}
      <Spacer size={11} />
      <Row
        weight={1.0}
        height={64}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card()}
        align="center"
      >
        <Spacer weight={1.0} />
        <Text
          text={@target}
          font_family="mono"
          text_size={27}
          font_weight="medium"
          letter_spacing={-0.02}
          text_color={:on_surface}
        />
        <Spacer size={9} />
        <Text text={@unit} text_size={13.5} text_color={Palette.muted()} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      {Kati.Screens.LogProgress.step_disc("add", :step_up)}
    </Row>
    """
  end

  @doc """
  The repeat row, whose sub-line names the date the next period starts on.

  A different date per period, and it is stated rather than implied: *restarts
  1 January* is a promise about a specific day, and a switch that only said
  `Repeat` would be one the user has to test to understand.
  """
  @spec repeat_row(boolean(), atom()) :: map()
  def repeat_row(repeat?, period) do
    Kati.UI.SettingsList.card([
      Kati.UI.SettingsList.row(
        Kati.UI.SettingsList.icon_tile("repeat"),
        Kati.UI.SettingsList.body(
          "Repeat each period",
          Kati.Screens.NewGoal.restart_line(period)
        ),
        Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.switch(repeat?)),
        on_tap: {self(), :toggle_repeat}
      )
    ])
  end

  @doc "What the repeat row says under its title, per period."
  @spec restart_line(atom()) :: String.t()
  def restart_line(:period_week), do: "Restarts every Monday"
  def restart_line(:period_month), do: "Restarts on the 1st"
  def restart_line(:period_custom), do: "Restarts the day after it ends"
  def restart_line(_year), do: "Restarts 1 January"

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :step_up}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :target, socket.assigns.target + 1)}

  def handle_info({:tap, :step_down}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :target, max(socket.assigns.target - 1, 1))}

  def handle_info({:tap, :toggle_repeat}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :repeat, not socket.assigns.repeat)}

  def handle_info({:tap, period}, socket)
      when period in [:period_week, :period_month, :period_year, :period_custom],
      do: {:noreply, Mob.Socket.assign(socket, :period, period)}

  def handle_info({:tap, :save}, socket) do
    save_goal(socket.assigns)
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  def handle_info({:tap, tag}, socket) do
    kinds = Enum.map(Goal.kinds(), &elem(&1, 0))

    case Enum.find(kinds, &(String.to_atom("kind_#{&1}") == tag)) do
      nil -> {:noreply, socket}
      kind -> {:noreply, Mob.Socket.assign(socket, :kind, kind)}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Write the goal, with a window computed from the period and today.

  The window is stored rather than derived at read time, for the reason
  `Kati.Goals.Goal`'s moduledoc gives: a goal set in March runs to 31 December,
  and deriving the window from the period would silently move its deadline.
  """
  @spec save_goal(map()) :: :ok
  def save_goal(assigns) do
    today = Kati.Time.today()
    {starts_on, ends_on} = Kati.Screens.NewGoal.window(assigns.period, today)

    Ash.create(Goal, %{
      kind: assigns.kind,
      target: assigns.target,
      period: Kati.Screens.NewGoal.period_value(assigns.period),
      starts_on: starts_on,
      ends_on: ends_on,
      repeat: assigns.repeat
    })

    :ok
  rescue
    _error -> :ok
  end

  @doc "The dates a period covers, starting from today."
  @spec window(atom(), Date.t()) :: {Date.t(), Date.t()}
  def window(:period_week, today) do
    monday = Date.add(today, -(Date.day_of_week(today) - 1))
    {monday, Date.add(monday, 6)}
  end

  def window(:period_month, today) do
    first = Date.beginning_of_month(today)
    {first, Date.end_of_month(today)}
  end

  def window(:period_custom, today), do: {today, Date.add(today, 29)}

  def window(_year, today) do
    {Date.new!(today.year, 1, 1), Date.new!(today.year, 12, 31)}
  end

  @doc false
  def period_value(:period_week), do: :week
  def period_value(:period_month), do: :month
  def period_value(:period_custom), do: :custom
  def period_value(_year), do: :year
end
