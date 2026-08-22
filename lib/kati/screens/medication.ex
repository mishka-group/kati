defmodule Kati.Screens.Medication do
  @moduledoc """
  Screen 112 — Medication, pushed under Health.

  ## Drawn with the honesty note accepted rather than the tile retired

  The design's caption. The tile could have been dropped — a medication tracker
  is the kind of feature an app ships and then regrets — and instead it ships
  with the two claims it has to make written plainly on the page:

    * *Reminders can arrive late if the phone is restricting alarms to save
      battery, so treat them as a nudge and not a guarantee.* Android's
      `AlarmManager` is best-effort under Doze, and an app that implied
      otherwise about a medication reminder would be making a promise it cannot
      keep about something that matters.
    * *Kati is not a medical device and gives no medical advice — it only
      records what you tell it.*

  Neither is small print. Both are `info` rows in the flow of the page.

  ## Doses reuse screen 43's meal cards exactly

  Taken, missed and skipped are the same three states as eaten, skipped and
  upcoming, and the caption says so. Deliberately parallel vocabulary: a person
  reading both pages should not have to learn two systems for *did this
  happen*.

  ## The reminder is drawn as the notification it becomes

  Because its three actions — Taken, Skip, Snooze — are the whole reason
  arming it is worth anything, and a user deciding whether to turn it on needs
  to see them before they do.
  """

  use Kati.Screens.Pushed, back: "Health"

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Health.WeightSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:doses, doses())
    |> Mob.Socket.assign(:schedules, schedules())
  end

  @doc "Today's doses: what is stored, or the drawing's four."
  @spec doses() :: [map()]
  def doses do
    case stored_doses() do
      [] ->
        WeightSample.doses()

      doses ->
        now = Kati.Time.now()

        Enum.map(doses, fn dose ->
          %{
            time: dose.due_at,
            name: dose.medication.name,
            line: Medication.dose_line(dose.medication),
            state: Dose.resolve(dose, now),
            id: dose.id
          }
        end)
    end
  end

  @doc "The drawing's four doses, unconditionally."
  @spec drawn_doses() :: [map()]
  def drawn_doses, do: WeightSample.doses()

  @doc "The schedules: what is stored, or the drawing's four."
  @spec schedules() :: [map()]
  def schedules do
    Medication
    |> Ash.Query.for_read(:active)
    |> Ash.read()
    |> case do
      {:ok, []} ->
        WeightSample.schedules()

      {:ok, medications} ->
        Enum.map(medications, fn m -> %{name: m.name, line: Medication.schedule_line(m)} end)

      _other ->
        WeightSample.schedules()
    end
  rescue
    _error -> WeightSample.schedules()
  end

  defp stored_doses do
    Dose
    |> Ash.Query.for_read(:for_day, %{day: Kati.Time.today()})
    |> Ash.Query.load(:medication)
    |> Ash.read()
    |> case do
      {:ok, doses} -> doses
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc false
  def content(assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Goals.chrome()}
        {SettingsList.title("Medication", Kati.Screens.Medication.subtitle(assigns.doses))}
        {UI.eyebrow("Today")}
        {Kati.Screens.Medication.today(assigns.doses)}
        {UI.eyebrow("Schedules")}
        {Kati.Screens.Medication.schedule_group(assigns.schedules)}
        {UI.eyebrow("The reminder")}
        {Kati.Screens.Medication.reminder()}
        {Kati.Screens.Medication.footnotes()}
      </Column>
    </Scroll>
    """
  end

  @doc "The header's mono subtitle, carrying today's real count."
  @spec subtitle([map()]) :: String.t()
  def subtitle(doses) do
    # Asks the STORE, not the list: with nothing stored the list is the
    # drawing's four, and dating the drawing's doses with the device's today
    # would put a real date on a fixture. Same reasoning as every other
    # fallback in this app — the drawing is drawn whole or not at all.
    case stored_doses() do
      [] ->
        WeightSample.doses_subtitle()

      _stored ->
        String.upcase(
          Calendar.strftime(Kati.Time.today(), "%A %-d %B") <>
            " · #{length(doses)} #{if length(doses) == 1, do: "dose", else: "doses"}"
        )
    end
  end

  @doc """
  Today's doses, each in screen 43's card treatment.

  A taken dose sits on the settled fill with a green tick; a missed one keeps
  card white and takes a close glyph, so *missed* reads as something that
  happened rather than as an error.
  """
  @spec today([map()]) :: map()
  def today(doses) do
    rows =
      doses
      |> Enum.map(&Kati.Screens.Medication.dose_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={12} />
      {Kati.Screens.Medication.actions()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def dose_row(dose) do
    suffix = Dose.state_suffix(dose.state)
    line = if suffix, do: dose.line <> " · " <> suffix, else: dose.line

    assigns = %{
      time: dose.time,
      name: dose.name,
      line: line,
      background: Kati.Screens.Medication.fill(dose.state),
      tap: {self(), :toggle_dose}
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={@background}
      corner_radius={18}
      padding_left={14}
      padding_right={14}
      padding_top={12}
      padding_bottom={12}
      align="center"
      on_tap={@tap}
    >
      <Text text={@time} font_family="mono" text_size={12} text_color={Palette.muted()} width={44} />
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={@name}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={@line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
      </Column>
      <Spacer size={12} />
      {Kati.Screens.Medication.mark(dose.state)}
    </Row>
    """
  end

  @doc false
  def fill(:taken), do: Palette.card_settled()
  def fill(_other), do: Palette.card()

  @doc "The trailing glyph: a green tick, or the close that means missed."
  @spec mark(atom()) :: map()
  def mark(:taken), do: UI.symbol("check", size: 20, color: Palette.green())
  def mark(:skipped), do: UI.symbol("close", size: 20, color: Palette.tertiary())
  def mark(:missed), do: UI.symbol("close", size: 20, color: Palette.gold_icon())
  def mark(_due), do: UI.symbol("check", size: 20, color: Palette.border_strong())

  @doc """
  The two verbs a dose takes.

  `Taken` and `Skip`, side by side rather than as a swipe: a dose is a thing you
  decide about once a day and a gesture with no affordance is not a control.
  """
  @spec actions() :: map()
  def actions do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Row
        weight={1.0}
        height={40}
        corner_radius={20}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :mark_taken}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Taken"
          text_size={13}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={10} />
      <Row
        weight={1.0}
        height={40}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_button()}
        align="center"
        on_tap={{self(), :mark_skipped}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Skip"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Row>
    """
  end

  @doc "The schedules, each pushing nowhere yet — see `handle_tap/2`."
  @spec schedule_group([map()]) :: map()
  def schedule_group(schedules) do
    rows =
      Enum.map(schedules, fn schedule ->
        SettingsList.row(
          SettingsList.icon_tile("medication"),
          SettingsList.body(schedule.name, schedule.line),
          SettingsList.trailing(SettingsList.chevron()),
          on_tap: {self(), :open_schedule}
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The reminder, drawn as the notification it becomes.

  On the page rather than only on the lock screen — see the moduledoc. Its
  three actions are drawn and inert here, because tapping a picture of a
  notification is not taking a dose; the real ones live on the notification.
  """
  @spec reminder() :: map()
  def reminder do
    r = WeightSample.reminder()

    assigns = %{
      app: r.app,
      title: r.title,
      body: r.body,
      actions:
        r.actions
        |> Enum.map(&Kati.Screens.Medication.reminder_action/1)
        |> Enum.intersperse(~MOB"<Spacer size={9} />")
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.card_settled()} corner_radius={20} padding={16}>
        <Text
          text={@app}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        <Text
          text={@title}
          text_size={14.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={@body} text_size={12.5} text_color={Palette.sub()} max_lines={1} />
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {@actions}
        </Row>
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def reminder_action(label) do
    assigns = %{label: label}

    ~MOB"""
    <Text
      text={@label}
      text_size={12.5}
      font_weight="semibold"
      text_color={Kati.Theme.Palette.ink_soft()}
    />
    """
  end

  @doc "The two claims this page has to make, both in the flow rather than as small print."
  @spec footnotes() :: map()
  def footnotes do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "Reminders can arrive late if the phone is restricting alarms to save battery, so treat them as a nudge and not a guarantee.")}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Kati is not a medical device and gives no medical advice — it only records what you tell it.")}
    </Column>
    """
  end

  @doc false
  def handle_tap(:mark_taken, socket), do: {:noreply, mark(socket, :taken)}
  def handle_tap(:mark_skipped, socket), do: {:noreply, mark(socket, :skipped)}
  def handle_tap(:toggle_dose, socket), do: {:noreply, mark(socket, :taken)}

  # A medication's own page is not drawn anywhere in the 127 artboards, and the
  # row is honest about being a link. `Kati.ScreenTapSweepTest` carries it.
  def handle_tap(_tag, socket), do: {:noreply, socket}

  # Marks the first unresolved dose of the day, which is the one the two buttons
  # are about — they sit under the list, not on a row, so "which dose" is
  # answered by *the next one you have not decided about*.
  defp mark(socket, state) do
    with %Dose{} = dose <- next_undecided() do
      Ash.update(dose, %{state: state, recorded_at: Kati.Time.now() |> DateTime.truncate(:second)})
    end

    Mob.Socket.assign(socket, :doses, doses())
  rescue
    _error -> socket
  end

  defp next_undecided do
    Dose
    |> Ash.Query.for_read(:for_day, %{day: Kati.Time.today()})
    |> Ash.read()
    |> case do
      {:ok, doses} -> Enum.find(doses, &(&1.state == :due))
      _other -> nil
    end
  end
end
