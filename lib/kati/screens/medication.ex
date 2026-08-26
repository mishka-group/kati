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

  ## A dose that did not record says so

  `Taken` and `Skip` used to end in an `Ash.update/2` whose result went
  nowhere, under a `rescue` that caught nothing — `Ash.update/2` returns
  `{:error, changeset}` rather than raising. The page then re-read the day and
  redrew either way, so a decision that landed and one that vanished dismissed
  to identical pixels. On a fresh install they still would: this page draws the
  drawing's four doses whatever the store holds, and none of the four is a row
  anything can be written against.

  Which is the case that matters most here. A medication page whose caption
  already refuses to promise a reminder must not silently pretend to have
  recorded a dose — of everything in this app, *did I take it* is the question
  a wrong answer costs the most. So `save_dose/1` hands back the tuple,
  `save_notice/1` draws the failure above the two buttons, and the list is
  re-read only when there is something new to read.
  """

  use Kati.Screens.Pushed, back: "Health"

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Health.WeightSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.Write

  def load(socket) do
    socket
    |> Mob.Socket.assign(:doses, doses())
    |> Mob.Socket.assign(:schedules, schedules())
    |> Mob.Socket.assign(:save_error, nil)
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
        {Kati.Screens.Medication.today(assigns.doses, assigns[:save_error])}
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

  Takes the failed-write message as well as the doses, because the place it
  belongs is inside this group: between the list it failed to change and the
  buttons that were just pressed.
  """
  @spec today([map()], String.t() | nil) :: map()
  def today(doses, save_error \\ nil) do
    rows =
      doses
      |> Enum.map(&Kati.Screens.Medication.dose_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    notice = Kati.Screens.Medication.save_notice(save_error)

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={12} />
      {notice}
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

  @doc """
  What a dose that did not record leaves above the two buttons.

  Directly above `actions/0` rather than at the top of the page: the buttons
  are what was just pressed, so the eye is already there, and a notice level
  with the title would read as a claim about the whole screen.

  Not one of `footnotes/0`'s `info` pills, though the page has two of them and
  reaching for a third is the obvious move. Those carry the two things that are
  always true of this feature; a write that failed is true for one tap, and
  dressing it as an `info` would both mute it and cast doubt on the pair it
  copied. Red, and its own line.
  """
  @spec save_notice(String.t() | nil) :: map() | []
  def save_notice(nil), do: []

  def save_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@message}
        text_size={12.5}
        font_weight="semibold"
        line_height={1.35}
        text_color={Palette.red()}
      />
      <Spacer size={10} />
    </Column>
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
  def handle_tap(:mark_taken, socket), do: {:noreply, record(socket, :taken)}
  def handle_tap(:mark_skipped, socket), do: {:noreply, record(socket, :skipped)}
  def handle_tap(:toggle_dose, socket), do: {:noreply, record(socket, :taken)}

  # A medication's own page is not drawn anywhere in the 127 artboards, and the
  # row is honest about being a link. `Kati.ScreenTapSweepTest` carries it.
  def handle_tap(_tag, socket), do: {:noreply, socket}

  # The page re-reads the day because a dose was recorded, not because a button
  # was pressed. Those were the same line until now.
  #
  # A failure leaves `:doses` untouched rather than re-reading: the store did
  # not change, so re-reading would redraw the identical list underneath an
  # error saying nothing was written — the same mixed message the bare `:ok`
  # used to send, only louder.
  defp record(socket, state) do
    case save_dose(state) do
      {:ok, _dose} ->
        socket
        |> Mob.Socket.assign(:doses, doses())
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Write.message(error))
    end
  end

  @doc """
  Record the day's next undecided dose as `state`.

  Which dose that is, is the whole question: the two buttons sit under the
  list rather than on a row, so *which one* is answered by *the next one you
  have not decided about*.

  No `rescue`. `Ash.update/2` returns `{:error, changeset}` rather than
  raising, so the one this carried caught nothing while the line above it threw
  the failure away; `Kati.Screens.Root.rescue_tap/3` is already around every
  tap for the raises that are real.

  A day with nothing left to decide — which includes every fresh install, where
  the four doses on the page are the drawing's and belong to no row — is
  `{:error, :nothing_to_save}` rather than a silent success. There is nothing
  to write against, and that is a sentence `Kati.Write.message/1` already has.
  """
  @spec save_dose(:taken | :skipped) :: {:ok, Dose.t()} | {:error, term()}
  def save_dose(state) do
    case next_undecided() do
      %Dose{} = dose ->
        dose
        |> Ash.update(%{
          state: state,
          recorded_at: Kati.Time.now() |> DateTime.truncate(:second)
        })
        |> Write.note("medication dose")

      nil ->
        Write.note({:error, :nothing_to_save}, "medication dose")
    end
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
