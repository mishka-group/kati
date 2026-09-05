defmodule Kati.Screens.AddMedication do
  @moduledoc """
  Screen 188 — Add a medication, a sheet over screen 112.

  Built to `test/design/screens/188.html`, and it is the first thing in this
  app that can put a row in `health_medications`. `Kati.Health.Medication` has
  had `create: :*` since it was written and nothing in `lib/` called it: the
  only writer that has ever existed is `Kati.Backup.Catalog`'s restore, which
  is why screen 112 draws four tablets belonging to nobody on every fresh
  install and why screen 115's dose verbs — fixed one commit ago — could not
  be checked by a person.

  ## Board 119's chassis, with one change

  Scrim, bottom sheet, close disc, centred title, DM Mono field labels, 44pt
  inset troughs, and above all **the preview band**: 119's line is *"This is
  how the row will look in the meal"* and this one's is the same sentence
  about the Schedules row. The one change is the commit: board 188 puts a 34pt
  ink **Save** pill in the header where `Kati.UI.Sheet.header/1` puts a 36pt
  hole, and draws no 54pt primary at the foot. So the header is composed here
  rather than borrowed, the way `Kati.Screens.DropSheet` and
  `Kati.Screens.RateEpisode` compose theirs — `Kati.UI.Sheet.scrim/0` and
  `Kati.UI.Sheet.close_disc/0` are still the shared pieces.

  ## The sheet scrolls, because it is taller than a phone

  Five fields, the no-times note, the preview band, the method note and the
  refusal do not fit on a 2424px screen. Bottom-anchored and unscrolled, the
  overflow goes off the TOP: on a Pixel 9a the header — the close disc, the
  title and the only Save in the sheet — was drawn half under the status bar
  and the sheet could be neither committed nor abandoned. `Kati.Screens.
  RateEpisode`'s shell is copied here and its sheet is short, so the shape was
  right for the screen it came from and wrong for this one. `<Scroll>` inside
  the bottom-aligned box is `Kati.Screens.RateAlbum`'s answer to the same
  thing, in the same round, and this is that answer.

  Found on a device and only on a device: every host check renders a tree and
  a tree has no viewport, so nothing on the host can see a sheet leave the
  screen.

  The top padding is **64 rather than the board's 18** for the same reason and
  it is the same number every pushed page in the app uses. Board 188 puts the
  header 18 below the sheet's rounded top edge, which is right while the sheet
  rests at the bottom with scrim above it. A sheet taller than the screen has
  no scrim above it: its top edge IS the top of the screen, and 18 puts the
  close disc under the status bar. `Kati.Screens.Pushed.page/2` defaults to 64
  for exactly this clearance — 18 of the board's own padding and the rest of
  the system's chrome — so this borrows the house number rather than inventing
  one.

  ## The sheet opens on a draft, and the preview is why

  `Kati.Screens.AddIngredient` opens on `Kati.Meals.SampleLibrary.draft/0` for
  a reason that applies here exactly: the bottom half of the sheet is a
  picture of the row this becomes, and a preview of nothing is not a preview.
  So `draft/0` is board 188's own values, the fields are real `<TextField>`s
  over them, and what Save writes is what the fields hold — typed or drawn.

  ## Times is a chip row and a stepper, not a clock picker

  The board decides this in as many words and the reason is #45: Mob has no
  time input, so a picker is undrawable today. `common_times/0` is the row —
  `08:00`, `13:00`, `21:00` — the dashed disc adds the next one that is not
  already set, and tapping a chip takes it off again. That is buildable now
  and a picker is not.

  ## What Save writes, and what it refuses

  One `Kati.Health.Medication`, with `times` as set and `active: true`.
  **No dose rows**: a dose is what a day did with a prescription and
  `Kati.Health.Dose.resolve/2` is what decides it, so inventing four of them
  at create time would be the app answering *did I take it* on the user's
  behalf — the one question screen 112's own moduledoc says a wrong answer
  costs the most.

  D-59 is what makes that refusal cost nothing on the page. Screen 112 composes
  today's list from `times` — `Kati.Health.Dose.derive/2` — so a medication
  saved here appears under TODAY at its own clock times immediately, with no
  row written anywhere, and a row is created the first time somebody marks one.
  A medication saved with no times draws no dose and the page says so rather
  than falling back to a fixture, which is `Kati.Screens.Medication.nothing_due/1`.

  Save with no name refuses in words and writes nothing, which is
  `Kati.Write`'s contract and what `Kati.WriteContractTest` enforces. The
  sheet stays open and Save stays live, because a dead button explains
  nothing. `refusal/0` is that sentence, in one place, so the card the board
  draws and the message a refusal sets cannot disagree.

  ## Why the refusal card is only drawn when there is one

  The board draws the sheet in two states at once — resting, with a value in
  every trough, and refused. `Kati.ScreenDesignLiteralTest.drawn_state/0` puts
  this screen in the second for the comparison, exactly as it does for screen
  154, and `Kati.ScreenEmptyDatabaseTest` compares the resting band. Drawing
  the refusal at rest would be a sheet that opens by telling someone their
  save failed before they pressed anything.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Health.Medication
  alias Kati.Theme.Palette
  alias Kati.Write

  # The three clock times the stepper offers. Not a picker and not a
  # vocabulary of medicine — three times a day is what a prescription with
  # clock times in it usually says, and anything else is typed into Schedule.
  @common_times ["08:00", "13:00", "21:00"]

  @doc "Board 188's own values: the draft this sheet opens on."
  @spec draft() :: map()
  def draft do
    %{
      name: "Levothyroxine",
      dose: "50 mcg",
      schedule: "every morning, 08:00",
      times: ["08:00"],
      instruction: "before food"
    }
  end

  @doc "The clock times the dashed disc steps through."
  @spec common_times() :: [String.t()]
  def common_times, do: @common_times

  @doc """
  The sentence a nameless save is refused with.

  One function rather than two literals, because the card board 188 draws and
  the message the tap sets are the same sentence, and a second copy is a
  second thing to keep in step.
  """
  @spec refusal() :: String.t()
  def refusal, do: "A medication needs a name"

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    d = draft()

    {:ok,
     socket
     |> Mob.Socket.assign(:name, d.name)
     |> Mob.Socket.assign(:dose, d.dose)
     |> Mob.Socket.assign(:schedule, d.schedule)
     |> Mob.Socket.assign(:times, d.times)
     |> Mob.Socket.assign(:instruction, d.instruction)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def render(assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} />
      <Box fill_width={true} fill_height={true} align="bottom">
        <Scroll>
          <Column
            fill_width={true}
            background={Kati.Theme.Palette.paper()}
            corner_radius={26}
            padding_left={21}
            padding_right={21}
            padding_top={64}
            padding_bottom={34}
          >
            {Kati.Screens.AddMedication.header()}
            {Kati.Screens.AddMedication.fields(assigns)}
            {Kati.Screens.AddMedication.no_times_note()}
            {Kati.UI.Eyebrow.quiet("This is how it will look")}
            {Kati.Screens.AddMedication.preview(assigns)}
            {Kati.Screens.AddMedication.method_note()}
            {Kati.Screens.AddMedication.error(assigns[:save_error])}
          </Column>
        </Scroll>
      </Box>
    </Box>
    """
  end

  @doc """
  Close disc, centred title, Save pill.

  `Kati.UI.Sheet.header/1`'s arrangement with the 36pt hole filled in: the
  title still takes the weight between two edges, so it is centred in the
  sheet rather than in the space left beside the disc.
  """
  @spec header() :: map()
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.UI.Sheet.close_disc()}
        <Text
          text="Add a medication"
          weight={1.0}
          text_size={15}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.AddMedication.save_pill()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The only commit on this sheet: 34pt ink, in the header where 119 keeps a hole."
  @spec save_pill() :: map()
  def save_pill do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={{self(), :save}}
    >
      <Text
        text="Save"
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The five fields, in the order the board draws them and never another.

  The vertical order is the one thing the RTL spec pins as *not* mirroring —
  Name before Dose before Schedule before Times before Instruction, in Persian
  exactly as in English — so it is written once, here.
  """
  @spec fields(map()) :: map()
  def fields(assigns) do
    assigns = %{
      name: assigns.name,
      dose: assigns.dose,
      schedule: assigns.schedule,
      times: assigns.times,
      instruction: assigns.instruction
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddMedication.labelled("Name", Kati.Screens.AddMedication.trough(:name, @name, "Levothyroxine"))}
      {Kati.Screens.AddMedication.labelled("Dose", Kati.Screens.AddMedication.trough(:dose, @dose, "50 mcg"))}
      {Kati.Screens.AddMedication.labelled("Schedule", Kati.Screens.AddMedication.trough(:schedule, @schedule, "every morning, 08:00"))}
      {Kati.Screens.AddMedication.labelled("Times", Kati.Screens.AddMedication.time_chips(@times, :add_time, "time_"))}
      {Kati.Screens.AddMedication.labelled("Instruction", Kati.Screens.AddMedication.trough(:instruction, @instruction, "before food"))}
    </Column>
    """
  end

  @doc "A field under its DM Mono label, at board 119's spacing."
  @spec labelled(String.t(), map()) :: map()
  def labelled(label, body) do
    assigns = %{label: label, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@label}
        font_family="mono"
        text_size={10}
        letter_spacing={0.1}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={7} />
      {@body}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  The 44pt inset trough, with a real field in it.

  Board 157 made the only dark decision this stack needs: a trough goes
  `#2A2826` rather than inverting to card colour, so a field still reads as a
  hole rather than a raised surface. `Kati.Theme.Palette.placeholder/0` is
  that value in both modes.
  """
  @spec trough(atom(), String.t(), String.t()) :: map()
  def trough(tag, value, placeholder) do
    assigns = %{
      value: value,
      placeholder: placeholder,
      on_change: {self(), tag},
      id: Atom.to_string(tag)
    }

    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={14}
      background={Palette.placeholder()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <TextField
        value={@value}
        placeholder={@placeholder}
        return_key="done"
        weight={1.0}
        accessibility_id={@id}
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc """
  The chip row: one chip per set time, then the disc that adds the next.

  Each chip carries its own time in its tag, which is #97's shape — three
  chips sharing `:time` would be three nodes with one `accessibility_id`, and
  `onNodeWithTag` throws on the second match. `prefix` and `add_tag` are
  arguments because screen 189 draws the same row over the same times and the
  two screens must not share a tag namespace.
  """
  @spec time_chips([String.t()], atom(), String.t()) :: map()
  def time_chips(times, add_tag, prefix) do
    chips =
      times
      |> Enum.map(fn at -> Kati.Screens.AddMedication.time_chip(at, prefix) end)
      |> Enum.intersperse(gap())

    assigns = %{chips: chips, add: {self(), add_tag}, lead: if(times == [], do: [], else: gap())}

    ~MOB"""
    <Row fill_width={true} align="center">
      {@chips}
      {@lead}
      <Row
        height={34}
        corner_radius={17}
        background={Palette.placeholder()}
        padding_left={13}
        padding_right={13}
        align="center"
        on_tap={@add}
      >
        {Kati.UI.symbol("add", size: 16, color: Palette.sub())}
        <Spacer size={6} />
        <Text
          text="Add a time"
          text_size={12}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def time_chip(at, prefix) do
    assigns = %{at: at, tap: {self(), String.to_atom(prefix <> at)}}

    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={@tap}
    >
      <Text
        text={@at}
        font_family="mono"
        text_size={12.5}
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The quiet line under Times.

  A drawn state rather than an edge case: `Kati.Notifications.Sources.Health`
  contributes a suppressed `:no_times` candidate for a medication with none,
  precisely so *this one never reminds me* is answerable.
  """
  @spec no_times_note() :: map()
  def no_times_note do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {Kati.UI.symbol("notifications_off", size: 15, color: Palette.tertiary())}
        <Spacer size={9} />
        <Text
          text="No time set is a real answer — it is recorded and simply never reminds."
          text_size={11.5}
          line_height={1.5}
          text_color={Palette.sub()}
          weight={1.0}
        />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The preview band: the two rows this draft becomes, composed by the two
  functions that already draw them.

  `Kati.Health.Medication.schedule_line/1` is screen 112's Schedules row and
  `dose_line/1` is its today card, so nothing here re-words either — which is
  the whole point of a preview: a second composer would be a second sentence
  able to disagree with the page it is previewing.
  """
  @spec preview(map()) :: map()
  def preview(assigns) do
    row = row_of(assigns)

    assigns = %{
      name: row.name,
      schedule_line: Medication.schedule_line(row),
      dose_line: String.upcase(Medication.dose_line(row)),
      time: first_time(assigns.times)
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
        {Kati.Screens.AddMedication.band_label("Schedules row")}
        <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
          {Kati.UI.SettingsList.icon_tile("medication")}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text
              text={@name}
              text_size={13.5}
              font_weight="semibold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={3} />
            <Text text={@schedule_line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
          </Column>
          <Spacer size={12} />
          {Kati.UI.SettingsList.chevron()}
        </Row>
        <Box fill_width={true} height={1} background={Palette.hairline()} />
        <Spacer size={13} />
        {Kati.Screens.AddMedication.band_label("Today card")}
        <Row fill_width={true} align="top">
          <Text
            text={@time}
            font_family="mono"
            text_size={12}
            text_color={Palette.muted()}
            width={44}
          />
          <Spacer size={12} />
          <Column
            weight={1.0}
            background={Palette.paper()}
            corner_radius={16}
            padding_left={13}
            padding_right={13}
            padding_top={11}
            padding_bottom={11}
          >
            <Text
              text={@name}
              text_size={13}
              font_weight="semibold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={@dose_line}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
        </Row>
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def band_label(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@text}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.1}
        text_color={Palette.tertiary()}
        max_lines={1}
      />
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The draft as a `Kati.Health.Medication` struct, for the two line composers.

  A struct rather than a map because `schedule_line/1` and `dose_line/1` match
  on one, and the alternative — two more copies of *join the non-empty parts
  with a middot* — is exactly the second reader rule 4 is about. It is never
  written: `save/1` builds its own changeset from the same assigns.

  It carries no id and cannot: a preview is a picture of a row that does not
  exist yet.
  """
  @spec row_of(map()) :: Medication.t()
  def row_of(assigns) do
    %Medication{
      name: shown(assigns.name, "Levothyroxine"),
      dose: shown(assigns.dose, "50 mcg"),
      schedule: shown(assigns.schedule, "every morning, 08:00"),
      instruction: shown(assigns.instruction, "before food"),
      times: assigns.times
    }
  end

  # A preview of nothing is not a preview: an emptied trough previews the
  # board's own example rather than a blank line, and the trough's placeholder
  # says the same word underneath it.
  defp shown(value, example) do
    case String.trim(to_string(value)) do
      "" -> example
      typed -> typed
    end
  end

  defp first_time([]), do: "08:00"
  defp first_time([at | _rest]), do: at

  @doc "What the board says about the two things this sheet cannot do yet."
  @spec method_note() :: map()
  def method_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "Times is a chip row with a stepper behind it, not a clock picker — the platform has no time input, so a picker is undrawable today and a row of common times plus ±5 minutes is buildable now. Every trough is drawn for the keyboard that does not exist yet, which is why 119’s preview band is here: what you cannot type, you can at least see.")}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  The refusal, in the shape board 155 established: what is missing, that
  nothing was written, and a button that is still live.
  """
  @spec error(String.t() | nil) :: map() | []
  def error(nil), do: []

  def error(message) do
    assigns = %{message: message}

    ~MOB"""
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
          <Text text={@message} text_size={13} font_weight="bold" text_color={:on_surface} />
          <Spacer size={5} />
          {Kati.Screens.AddMedication.refusal_body()}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc false
  def refusal_body do
    Kati.UI.rich_text([
      {"Nothing was written.",
       [
         font_weight: "semibold",
         text_color: :on_surface,
         text_size: 12.5,
         line_height: 1.6
       ]},
      {" The sheet stays open and Save stays live — a dead button explains nothing.",
       [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft(), base: true]}
    ])
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # A save that landed closes the sheet; a save that did not KEEPS IT OPEN and
  # says so — `Kati.Write`'s contract, and the reason
  # `Kati.Screens.AddIngredient` reads the same way.
  def handle_info({:tap, :save}, socket) do
    case save(socket.assigns) do
      {:ok, _medication} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Mob.Socket.pop_screen()}

      {:error, :no_name} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, refusal())}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  def handle_info({:tap, :add_time}, socket) do
    {:noreply, Mob.Socket.assign(socket, :times, add_time(socket.assigns.times))}
  end

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "time_" <> at ->
        {:noreply, Mob.Socket.assign(socket, :times, socket.assigns.times -- [at])}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info({:change, field, typed}, socket)
      when field in [:name, :dose, :schedule, :instruction] and is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  The next common time not already set, appended in clock order.

  All three set is a no-op rather than a duplicate: two chips reading `08:00`
  would be two nodes with one `accessibility_id`, and
  `Kati.Notifications.Sources.Health` groups by clock time, so a repeated one
  would arm the same reminder twice.
  """
  @spec add_time([String.t()]) :: [String.t()]
  def add_time(times) do
    case Enum.reject(@common_times, &(&1 in times)) do
      [] -> times
      [next | _rest] -> Enum.sort(times ++ [next])
    end
  end

  @doc """
  Write the medication, or say why not.

  A name is the resource's one `allow_nil? false` string and the only thing
  this needs; everything else is optional, because a prescription you have not
  finished reading off the box is still one you are taking.

  No dose rows are created alongside it — see the moduledoc.
  """
  @spec save(map()) :: {:ok, Medication.t()} | {:error, term()}
  def save(assigns) do
    name = String.trim(to_string(assigns.name))

    if name == "" do
      Write.note({:error, :no_name}, "add medication")
    else
      Medication
      |> Ash.Changeset.for_create(:create, %{
        name: name,
        dose: blank_to_nil(assigns.dose),
        schedule: blank_to_nil(assigns.schedule),
        instruction: blank_to_nil(assigns.instruction),
        times: assigns.times,
        active: true
      })
      |> Ash.create()
      |> Write.note("add medication #{name}")
    end
  end

  defp blank_to_nil(value) do
    case String.trim(to_string(value)) do
      "" -> nil
      text -> text
    end
  end
end
