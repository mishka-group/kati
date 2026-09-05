defmodule Kati.Screens.MedicationDetail do
  @moduledoc """
  Screen 189 — One medication, pushed from screen 112's Schedules group.

  Built to `test/design/screens/189.html`. Screen 112 has drawn four chevrons
  since it shipped and `Kati.ScreenTapSweepTest` listed all four by name with
  the reason *"no per-medication page is drawn anywhere in the artboards"*.
  This is the other end of them.

  ## One form, drawn twice

  The field stack is `Kati.Screens.AddMedication`'s — the same five troughs,
  the same labels, the same order — which is why board 188 and board 189 are
  one brief. Nothing here re-implements a trough or a time chip: the sheet
  owns them and this page calls them, so a change to the shape of a field
  cannot land on one of the two and not the other.

  The vertical order never reverses, in either script: Name, Dose, Schedule,
  Times, Instruction, and on the page as a whole prescription, reminder,
  taking, delete.

  ## The row this page drew, and nothing else

  `medication/1` resolves the id screen 112 handed over, and **every write on
  this page acts on `assigns.medication`** — `persist/2` reads the row back by
  the id the page is holding and updates that row. Handed an id that names
  nothing, the page draws `drawn_medication/0`, which carries no `:id` at all,
  and every control answers `Nothing to save yet.` rather than landing on a
  neighbour. That is #84's rule and `Kati.ScreenWriteTargetTest`'s assertion,
  and it is why the fixture has no id rather than a `nil` one.

  ## `times` is the reminder, so the switch writes `times`

  `Kati.Notifications.Sources.Health` arms from that field and reads nothing
  else, so a separate *reminder on* column would be a second reader able to
  disagree with the times printed beside it. **Remind me** off therefore
  clears `times`, and a medication with none is the `:no_times` case the
  source already handles: it contributes a suppressed candidate rather than
  nothing, precisely so *this one never reminds me* is answerable. The switch
  is **absent** in that state rather than off, which is what the board draws,
  and the chip row is how the times come back.

  ## What the reminder does not offer

  No quiet-hours switch: health is the one domain that is `:exempt`, and *a
  21:00 dose that shifts to 08:00 is not a late reminder, it is the wrong
  instruction*. No priority control: `:high` is a budget allocation, not a
  loudness. No free-text notification body: `Kati.Notifications.Sources.Health`
  composes it from `dose` and `instruction`, and this page previews it by
  calling that composer rather than by writing the sentence a second time.

  The **Shared with** row exists because without it the switch reads as *a
  notification for this tablet*, and it is not one: three tablets at 08:00 is
  one thing that happens at 08:00 and the title is `3 doses`.

  ## Stop taking is not delete

  `active` is a filter — the `:active` read is screen 112's Schedules group —
  and turning it off keeps every `Kati.Health.Dose` already recorded. Delete
  removes the medication, and a dose `belongs_to` its medication with
  `allow_nil? false`, so the doses go with it. The card under the control says
  how many, counted rather than claimed, and `:delete` is two taps: the first
  arms it, the second writes. That is what keeps a destructive control safe
  under a sweep that presses every tag on the page exactly once.

  ## The bands below the page

  Board 189 is a page and its own states sheet, in board 110's manner: the
  switch drawn off, the `times: []` case, the delete consequence, the undo bar
  and a dark inset carrying the two surfaces board 157 does not answer. They
  are drawn here as the board draws them, under the board's own eyebrows —
  specimens, not controls, so none of them carries an `on_tap`.
  """

  use Kati.Screens.Pushed, back: "Medication"

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Notifications.Sources.Health
  alias Kati.Screens.AddMedication
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList
  alias Kati.Write

  require Ash.Query

  @doc """
  The params screen 112 pushes with.

  `%{}` for a row with no id — the drawing's four have none — so the sheet is
  handed nothing rather than being handed a lie. `Kati.ScreenParamsSweepTest`
  records that door on `@empty_builders` until the shelf holds real rows.
  """
  @spec params_for(map()) :: map()
  def params_for(row) do
    case Map.get(row, :id) do
      nil -> %{}
      id -> %{medication_id: id}
    end
  end

  @impl true
  def load(socket) do
    id = Map.get(socket.assigns.params || %{}, :medication_id)

    socket
    |> Mob.Socket.assign(:medication, medication(id))
    |> Mob.Socket.assign(:save_error, nil)
    |> Mob.Socket.assign(:confirm_delete?, false)
  end

  @doc "The medication this page is about: the one named, or the drawing's."
  @spec medication(String.t() | nil) :: map()
  def medication(id \\ nil)

  def medication(nil) do
    case active() do
      [] -> drawn_medication()
      [first | _rest] -> shape(first)
    end
  end

  def medication(id) when is_binary(id) do
    case Ash.get(Medication, id) do
      {:ok, %Medication{} = row} -> shape(row)
      _other -> drawn_medication()
    end
  rescue
    _error -> drawn_medication()
  end

  @doc """
  Board 189's own medication, with **no `:id`**.

  Built through the same `shape/3` a stored row goes through, so the
  empty-database gate compares the two term for term and the absent id is the
  whole of what separates them.
  """
  @spec drawn_medication() :: map()
  def drawn_medication do
    shape(
      %Medication{
        name: "Levothyroxine",
        dose: "50 mcg",
        schedule: "every morning, 08:00",
        instruction: "before food",
        times: ["08:00", "13:00"],
        active: true
      },
      ["Vitamin D", "Iron"],
      214
    )
  end

  @doc """
  A row as this page holds it.

  Every line the page prints is composed here, by the function that already
  composes it somewhere else: `Kati.Health.Medication.schedule_line/1` and
  `dose_line/1` are screen 112's two lines, and
  `Kati.Notifications.Sources.Health.title/1` and `body/1` are what the
  notification will actually say. Nothing on this page words any of them a
  second time.
  """
  @spec shape(Medication.t(), [String.t()], non_neg_integer()) :: map()
  def shape(row, shared \\ nil, doses \\ nil)

  def shape(%Medication{} = row, shared, doses) do
    shared = shared || shared_names(row)
    doses = doses || dose_count(row)
    group = [row | Enum.map(shared, fn name -> %Medication{name: name} end)]

    base = %{
      name: row.name,
      dose: row.dose || "",
      schedule: row.schedule || "",
      instruction: row.instruction || "",
      times: row.times,
      active: row.active,
      schedule_line: Medication.schedule_line(row),
      dose_line: Medication.dose_line(row),
      subtitle: subtitle(row),
      shared: shared,
      shared_line: shared_line(row.times, shared),
      notification_at: notification_at(row.times),
      notification_title: Health.title(group),
      notification_body: Health.body([row]),
      doses: doses
    }

    # `id:` is added rather than defaulted to `nil`, because a fixture row that
    # carries a `nil` id is a row a write can be handed. Absence is the whole
    # signal — see `Kati.Screens.Medication.drawn_doses/0`.
    case row.id do
      nil -> base
      id -> Map.put(base, :id, id)
    end
  end

  @doc "The mono line under the title: `50 MCG · ACTIVE`."
  @spec subtitle(Medication.t()) :: String.t()
  def subtitle(%Medication{dose: dose, active: active}) do
    state = if active, do: "ACTIVE", else: "PAUSED"

    case dose do
      nil -> state
      "" -> state
      text -> String.upcase(text) <> " · " <> state
    end
  end

  @doc """
  The **Shared with** line: `08:00 · with Vitamin D and Iron`.

  The first clock time, and who else is due at it. `nil` when nobody is, which
  is the row being omitted rather than a row saying *with nobody*.
  """
  @spec shared_line([String.t()], [String.t()]) :: String.t() | nil
  def shared_line([], _shared), do: nil
  def shared_line(_times, []), do: nil

  def shared_line([at | _rest], shared) do
    at <> " · with " <> join_names(shared)
  end

  defp join_names([one]), do: one
  defp join_names(names), do: Enum.join(Enum.drop(names, -1), ", ") <> " and " <> List.last(names)

  defp notification_at([]), do: "08:00"
  defp notification_at([at | _rest]), do: at

  # Every other active medication due at this one's first clock time. The
  # store, not a guess: the aggregation the notification actually makes is by
  # clock time, so the row has to be read the same way.
  defp shared_names(%Medication{times: []}), do: []

  defp shared_names(%Medication{times: [at | _rest], id: id}) do
    for row <- active(), row.id != id, at in row.times, do: row.name
  end

  defp dose_count(%Medication{id: nil}), do: 0

  defp dose_count(%Medication{id: id}) do
    Dose
    |> Ash.Query.filter(medication_id == ^id)
    |> Ash.read()
    |> case do
      {:ok, rows} -> length(rows)
      _other -> 0
    end
  rescue
    _error -> 0
  end

  defp active do
    Medication
    |> Ash.Query.for_read(:active)
    |> Ash.read()
    |> case do
      {:ok, rows} -> rows
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc false
  def content(assigns) do
    m = assigns.medication

    Kati.Screens.Pushed.page(
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.MedicationDetail.heading(m.name, m.subtitle)}
        {Kati.UI.eyebrow("The prescription")}
        {Kati.Screens.MedicationDetail.prescription(m)}
        {Kati.UI.Eyebrow.quiet("Reminder")}
        {Kati.Screens.MedicationDetail.reminder(m)}
        {Kati.Screens.MedicationDetail.preview(m)}
        {Kati.Screens.MedicationDetail.aggregation_note()}
        {Kati.UI.Eyebrow.quiet("Switch off, and the no-times case")}
        {Kati.Screens.MedicationDetail.reminder_states()}
        {Kati.UI.Eyebrow.quiet("Taking")}
        {Kati.Screens.MedicationDetail.taking(m)}
        {Kati.Screens.MedicationDetail.notice(assigns[:save_error])}
        {Kati.Screens.MedicationDetail.delete_control(assigns[:confirm_delete?])}
        {Kati.Screens.MedicationDetail.consequence(m)}
        {Kati.Screens.MedicationDetail.undo_bar(m)}
        {Kati.UI.Eyebrow.quiet("Dark — the two surfaces 157 does not answer")}
        {Kati.Screens.MedicationDetail.dark_inset()}
      </Column>
      """,
      Kati.Screens.Pushed.content_top()
    )
  end

  @doc """
  The 28pt title over its mono line, at **boards 189 and 190's own metrics**.

  `Kati.UI.SettingsList.title/4` draws three shapes and neither of these two
  boards is any of them: both set 11.5px DM Mono over a 5px gap, where
  `:meta` is 11.5 over 6 and `:meta_tight` is 11 over 5. Board 112, the page
  these two are about, is `:meta` — so this is a fourth shape rather than a
  screen disagreeing with its board, and `Kati.ScreenTitleSubtitleTest` reads
  the board rather than a list, which is exactly why it has to be drawn and
  not rounded to the nearest existing style.

  Here rather than in `Kati.UI.SettingsList` because two boards is not yet a
  family, and `title_text/1` — the half that IS shared — is called rather than
  copied. Screen 190 calls this.
  """
  @spec heading(String.t(), String.t()) :: map()
  def heading(title, sub) do
    assigns = %{title: title, sub: sub}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.title_text(@title)}
      <Spacer size={5} />
      <Text
        text={@sub}
        font_family="mono"
        text_size={11.5}
        text_color={Kati.UI.SettingsList.subtitle_ink()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The five fields, editable in place — `Kati.Screens.AddMedication`'s stack."
  @spec prescription(map()) :: map()
  def prescription(m) do
    assigns = %{m: m}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Kati.Screens.AddMedication.labelled("Name", Kati.Screens.AddMedication.trough(:name, @m.name, "Levothyroxine"))}
        {Kati.Screens.AddMedication.labelled("Dose", Kati.Screens.AddMedication.trough(:dose, @m.dose, "50 mcg"))}
        {Kati.Screens.AddMedication.labelled("Schedule", Kati.Screens.AddMedication.trough(:schedule, @m.schedule, "every morning, 08:00"))}
        {Kati.Screens.AddMedication.labelled("Times", Kati.Screens.AddMedication.time_chips(@m.times, :add_time, "time_"))}
        {Kati.Screens.AddMedication.labelled("Instruction", Kati.Screens.AddMedication.trough(:instruction, @m.instruction, "before food"))}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The reminder card: the switch, who it is shared with, and the one fact that
  is not a choice.

  Board 51's Manners group — a card of list rows with no chevrons, because
  none of them leads anywhere.
  """
  @spec reminder(map()) :: map()
  def reminder(m) do
    rows =
      [
        remind_row(m),
        shared_row(m.shared_line),
        SettingsList.row(
          SettingsList.icon_tile("bedtime"),
          SettingsList.body("Quiet hours", "21:00 stays 21:00 — medication is never moved",
            lines: 2
          ),
          nil,
          rule: false
        )
      ]
      |> Enum.reject(&(&1 == []))

    assigns = %{rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={11} />
    </Column>
    """
  end

  # The switch is ABSENT when there are no times, rather than off: there is
  # nothing to arm, and an off switch would offer to arm it.
  defp remind_row(%{times: []}) do
    SettingsList.row(
      SettingsList.icon_tile("notifications_off"),
      SettingsList.body(
        "This one never reminds",
        "No time set. A schedule can be a sentence with no clock in it.",
        lines: 2
      ),
      nil
    )
  end

  defp remind_row(m) do
    SettingsList.row(
      SettingsList.icon_tile("notifications"),
      SettingsList.body("Remind me", Enum.join(m.times, ", ")),
      SettingsList.switch(true),
      on_tap: {self(), :remind_off}
    )
  end

  defp shared_row(nil), do: []

  defp shared_row(line) do
    SettingsList.row(
      SettingsList.icon_tile("group"),
      SettingsList.body("Shared with", line),
      nil
    )
  end

  @doc """
  What the notification will say, composed by the code that composes it.

  Drawn and inert, and annotated as such: tapping a picture of a notification
  is not taking a dose, and the real actions live on the notification.
  """
  @spec preview(map()) :: map()
  def preview(m) do
    assigns = %{
      eyebrow: "KATI · " <> m.notification_at,
      title: m.notification_title,
      body: m.notification_body
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Kati.Screens.AddMedication.band_label("What it will say")}
        <Column fill_width={true} background={Palette.card_settled()} corner_radius={20} padding={14}>
          <Text
            text={@eyebrow}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.1}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={9} />
          <Text
            text={@title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text text={@body} text_size={12.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={11} />
        <Text
          text="Drawn and inert — tapping a picture of a notification is not taking a dose."
          text_size={11.5}
          line_height={1.5}
          text_color={Palette.sub()}
        />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "Why the switch is not a promise of one notification per medication."
  @spec aggregation_note() :: map()
  def aggregation_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "Three tablets at 08:00 is one thing that happens at 08:00, so the reminder aggregates by clock time and the title reads 3 doses. Without the Shared-with row the switch would be a lie by omission. No quiet-hours switch and no priority control: a 21:00 dose shifted to 08:00 is the wrong instruction, not a late reminder.")}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The two states the live card is not in: the switch off, and `times: []`.

  Specimens, in board 110's manner — no `on_tap` on either, because the
  control they picture is the one above them.
  """
  @spec reminder_states() :: map()
  def reminder_states do
    rows = [
      SettingsList.row(
        SettingsList.icon_tile("notifications"),
        SettingsList.body("Remind me", "Off — the doses still appear on 112"),
        SettingsList.switch(false)
      ),
      SettingsList.row(
        SettingsList.icon_tile("notifications_off"),
        SettingsList.body(
          "This one never reminds",
          "No time set. A schedule can be a sentence with no clock in it.",
          lines: 2
        ),
        nil,
        rule: false
      )
    ]

    assigns = %{rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The `active` switch, and the sentence that says what it keeps."
  @spec taking(map()) :: map()
  def taking(m) do
    row =
      SettingsList.row(
        SettingsList.icon_tile("pause_circle"),
        SettingsList.body(
          "Stop taking",
          "Off the Schedules group and off the reminder list. Every dose already recorded is kept.",
          lines: 3
        ),
        SettingsList.switch(m.active),
        on_tap: {self(), :stop_taking},
        rule: false
      )

    assigns = %{row: row}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([@row])}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  A write that did not land, above the control that was pressed.

  Screen 112's `save_notice/1` in the same red and for the same reason: of
  everything in this app, a page about medication must not pretend to have
  recorded something it did not.
  """
  @spec notice(String.t() | nil) :: map() | []
  def notice(nil), do: []

  def notice(message) do
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

  @doc """
  Board 31's destructive control: outlined, never filled.

  Two taps. The first arms it and says so; the second writes. A confirmation
  the user has to pass through is what makes a control that destroys rows safe
  to draw beside controls that do not — and it is what keeps this page honest
  under a sweep that presses every tag on it once.
  """
  @spec delete_control(boolean()) :: map()
  def delete_control(armed?) do
    label = if armed?, do: "Delete this medication — tap again", else: "Delete this medication"
    assigns = %{label: label}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={48}
        corner_radius={24}
        background={Palette.transparent()}
        align="center"
        on_tap={{self(), :delete}}
      >
        <Spacer weight={1.0} />
        {Kati.UI.symbol("delete", size: 18, color: Palette.red())}
        <Spacer size={8} />
        <Text
          text={@label}
          text_size={13}
          font_weight="bold"
          text_color={Palette.red()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  What deleting takes with it, counted rather than claimed.

  `Kati.Health.Dose` `belongs_to` its medication with `allow_nil? false`, so
  the doses cannot outlive it. The number is this medication's own; the
  drawing's is 214.
  """
  @spec consequence(map()) :: map()
  def consequence(m) do
    assigns = %{
      title: "This takes #{m.doses} recorded doses with it",
      body:
        Kati.UI.rich_text([
          {"A dose belongs to its medication and cannot outlive it. ",
           [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft(), base: true]},
          {"Stop taking", [font_weight: "semibold"]},
          {" keeps them.", []}
        ])
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.symbol("error", size: 18, color: Palette.red())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text text={@title} text_size={13} font_weight="bold" text_color={:on_surface} />
            <Spacer size={5} />
            {@body}
          </Column>
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  Board 27's undo bar, drawn as the specimen it is.

  No `on_tap`: the bar is what follows a delete, and this page is not in that
  state — a tappable Undo here would be a control with nothing to undo.
  """
  @spec undo_bar(map()) :: map()
  def undo_bar(m) do
    assigns = %{label: "Deleted " <> m.name}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.ink_fill()}
        corner_radius={20}
        padding_left={16}
        padding_right={16}
        padding_top={13}
        padding_bottom={13}
        align="center"
      >
        {Kati.UI.symbol("undo", size: 19, color: Palette.on_ink())}
        <Spacer size={12} />
        <Text
          text={@label}
          weight={1.0}
          text_size={13}
          font_weight="semibold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Text
          text="Undo"
          text_size={12.5}
          font_weight="bold"
          text_color={Palette.accent()}
          max_lines={1}
        />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The dark inset: the off track and the destructive control, and nothing else.

  Board 157 already answered the field trough. These are the two surfaces it
  does not, and both are colour carrying meaning rather than decoration — an
  off track at `#DCD7CF` reads as a raised chip on `#121110`, and `#B4553C` on
  paper is a different amount of contrast from `#B4553C` on `#121110`.
  """
  @spec dark_inset() :: map()
  def dark_inset do
    ~MOB"""
    <Column fill_width={true} background={Palette.paper(:dark)} corner_radius={22} padding={16}>
      <Row
        fill_width={true}
        background={Palette.card(:dark)}
        corner_radius={20}
        padding_left={15}
        padding_right={15}
        padding_top={13}
        padding_bottom={13}
        align="center"
      >
        {Kati.UI.symbol("notifications", size: 17, color: Palette.sub(:dark))}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text="Remind me"
            text_size={13.5}
            font_weight="semibold"
            text_color={Palette.ink(:dark)}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text="Off — track goes #3A3733, not #DCD7CF"
            text_size={11.5}
            line_height={1.5}
            text_color={Palette.sub(:dark)}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box
          width={46}
          height={28}
          corner_radius={14}
          background={Palette.track_off(:dark)}
          align="center"
        >
          <Box width={22} height={22} corner_radius={11} background={Palette.on_ink(:light)} />
        </Box>
      </Row>
      <Spacer size={12} />
      <Row
        fill_width={true}
        height={48}
        corner_radius={24}
        background={Palette.transparent()}
        align="center"
      >
        <Spacer weight={1.0} />
        {Kati.UI.symbol("delete", size: 18, color: Palette.red(:dark))}
        <Spacer size={8} />
        <Text
          text="Delete this medication"
          text_size={13}
          font_weight="bold"
          text_color={Palette.red(:dark)}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @impl true
  def handle_info({:change, field, typed}, socket)
      when field in [:name, :dose, :schedule, :instruction] and is_binary(typed) do
    {:noreply, edit(socket, field, typed)}
  end

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(:remind_off, socket), do: {:noreply, write(socket, %{times: []})}

  def handle_tap(:add_time, socket) do
    times = AddMedication.add_time(socket.assigns.medication.times)
    {:noreply, write(socket, %{times: times})}
  end

  def handle_tap(:stop_taking, socket),
    do: {:noreply, write(socket, %{active: not socket.assigns.medication.active})}

  # The first tap arms, the second writes — see `delete_control/1`.
  def handle_tap(:delete, %{assigns: %{confirm_delete?: false}} = socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirm_delete?, true)}

  def handle_tap(:delete, socket), do: {:noreply, destroy(socket)}

  def handle_tap(tag, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "time_" <> at ->
        {:noreply, write(socket, %{times: socket.assigns.medication.times -- [at]})}

      _other ->
        {:noreply, socket}
    end
  end

  # A field edit moves the page first and the row second: what was typed is on
  # the screen either way, and a store that refuses says so in the notice
  # rather than by silently restoring the old word.
  defp edit(socket, field, typed) do
    socket
    |> Mob.Socket.assign(:medication, Map.put(socket.assigns.medication, field, typed))
    |> then(fn s -> if held?(s), do: write(s, %{field => typed}), else: s end)
  end

  defp held?(socket), do: Map.has_key?(socket.assigns.medication, :id)

  @doc """
  Update the row **this page drew**, and redraw from what came back.

  `Kati.Screens.Medication.save_dose/2`'s shape exactly: the id the page is
  holding is read back and that row is updated, so a row deleted underneath
  the page answers as a tuple rather than a write landing on a neighbour. A
  page holding the drawing has no id to hand over and writes nothing.
  """
  @spec update(map(), map()) :: {:ok, Medication.t()} | {:error, term()}
  def update(%{id: id}, attrs) when is_binary(id) do
    with {:ok, %Medication{} = row} <- Ash.get(Medication, id) do
      Ash.update(row, attrs)
    end
    |> Write.note("medication #{inspect(Map.keys(attrs))}")
  end

  def update(_drawn, _attrs), do: Write.note({:error, :nothing_to_save}, "medication")

  defp write(socket, attrs) do
    case update(socket.assigns.medication, attrs) do
      {:ok, %Medication{} = row} ->
        socket
        |> Mob.Socket.assign(:medication, shape(row))
        |> Mob.Socket.assign(:save_error, nil)

      error ->
        Mob.Socket.assign(socket, :save_error, Write.message(error))
    end
  end

  @doc """
  Delete the medication the page drew, and the doses that belong to it.

  Cascade rather than orphan, because `Kati.Health.Dose.medication_id` is
  `allow_nil? false` — a dose cannot outlive its medication, and the card
  above the control says how many go.
  """
  @spec delete(map()) :: {:ok, :deleted} | {:error, term()}
  def delete(%{id: id}) when is_binary(id) do
    with {:ok, %Medication{} = row} <- Ash.get(Medication, id),
         {:ok, doses} <- Dose |> Ash.Query.filter(medication_id == ^id) |> Ash.read(),
         :ok <- destroy_each(doses),
         :ok <- destroyed(Ash.destroy(row)) do
      {:ok, :deleted}
    end
    |> Write.note("delete medication")
  end

  def delete(_drawn), do: Write.note({:error, :nothing_to_save}, "delete medication")

  defp destroy_each([]), do: :ok

  defp destroy_each([dose | rest]) do
    case destroyed(Ash.destroy(dose)) do
      :ok -> destroy_each(rest)
      error -> error
    end
  end

  # `Ash.destroy/1` answers `:ok` on this version and `{:ok, record}` on
  # others, and a `with` that only matched one of the two would fall through a
  # SUCCESSFUL delete into the caller's error branch. Normalised once here
  # rather than pattern-matched twice at two call sites.
  defp destroyed(:ok), do: :ok
  defp destroyed({:ok, _record}), do: :ok
  defp destroyed(other), do: other

  defp destroy(socket) do
    case delete(socket.assigns.medication) do
      {:ok, _deleted} ->
        Mob.Socket.pop_screen(socket)

      error ->
        socket
        |> Mob.Socket.assign(:confirm_delete?, false)
        |> Mob.Socket.assign(:save_error, Write.message(error))
    end
  end
end
