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
  a wrong answer costs the most. So `save_dose/2` hands back the tuple,
  `save_notice/1` draws the failure above the two buttons, and the list is
  re-read only when there is something new to read.

  ## The dose that changes is the dose you touched

  And that was the half still missing. Every control on this page — four rows
  and two verbs — carried one of two shared tags, and the write behind them
  re-queried the day and took the head of whatever came back. Three things were
  wrong with that at once, and only the third is visible in a screenshot:

    * **The row you tapped was not the row that changed.** Tapping the 21:00
      card marked the 14:00 one, because the query answered first-undecided and
      the tap carried no clue which card had been pressed. #84's rule, one
      screen over: *act on the row you were handed, not on the head of a
      re-query.*
    * **Four rows shared one name.** `Mob.Renderer` emits `accessibility_id`
      from the tag, so `:toggle_dose` on four cards is four nodes called the
      same thing — `onNodeWithTag` throws on the second match rather than
      picking one, and a screen reader announced four identical controls.
      `Kati.ScreenTapSweepTest`'s own duplicate-id check names this exact fix.
    * **The re-query could answer differently from the page.** A dose recorded
      on another screen between draw and tap moves the head, so the verbs would
      land somewhere the user was not looking.

  So `tags/1` builds a row's three tags out of the row's own id, `doses/0` and
  `drawn_doses/0` carry them, and `handle_tap/2` resolves a tag **against the
  doses already on the socket** rather than parsing an id back out of it —
  `Kati.Screens.Goals` fixed the same defect the same way, and the reason to
  resolve rather than parse is that nothing can then name a row that is not on
  the screen.

  The drawing's four keep `id: nil` and are tagged by position, which for a
  fixture is identity. Tapping one answers `Nothing to save yet.` rather than
  moving a tick: screen 104 flips its drawn switch in place and is right to,
  because a repeat toggle that lies costs a redrawn switch — here the same
  courtesy would be the app telling someone they had taken a tablet.

  ## `:mark_taken` and `:mark_skipped` survive, and only screen 115 uses them

  Screen 115 is this page in Persian and draws its two verbs inside the due
  card, with `Kati.Screens.HealthFa.doses/0` behind them — a list that keeps
  the name, the line and the state and drops the id. So its chips have no row
  in them to act on, and they come through `handle_tap/2` here to reach
  `next_undecided/0`, which is what they have always reached. They are the
  identity-less door, kept working rather than quietly broken; wiring them
  properly means giving 115's own list ids, which is 115's change.
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
        drawn_doses()

      doses ->
        now = Kati.Time.now()

        Enum.map(doses, fn dose ->
          Map.merge(
            %{
              time: dose.due_at,
              name: dose.medication.name,
              line: Medication.dose_line(dose.medication),
              state: Dose.resolve(dose, now),
              id: dose.id
            },
            tags(dose.id)
          )
        end)
    end
  end

  @doc """
  The drawing's four doses, unconditionally — each with `id: nil`.

  Built through the same merge a stored dose goes through, so the
  empty-database gate still compares `doses/0` with this term for term and
  `id: nil` is the whole of what separates them. It is also what `save_dose/2`
  reads to decide there is nothing to write against.
  """
  @spec drawn_doses() :: [map()]
  def drawn_doses do
    WeightSample.doses()
    |> Enum.with_index(1)
    |> Enum.map(fn {dose, position} ->
      dose |> Map.put(:id, nil) |> Map.merge(tags("drawn_#{position}"))
    end)
  end

  @doc """
  A dose's three tap tags, named after the dose rather than after the control.

  Atoms rather than `{:dose, id}` tuples for the reason
  `Kati.Screens.ImportSources.tag/1` sets out at length: `Mob.Renderer` emits
  `accessibility_id` only for the `is_atom(tag)` clause, so a tuple-tagged card
  fires on the device and is invisible to every sweep and unnamed to a screen
  reader.

  Three, because a dose has three ways of being decided about — its own card,
  and the two verbs that sit under the list — and all three have to name the
  same row. The id rather than the row's position: `:for_day` sorts by clock
  time, so a dose's position moves the moment another medication is taken at
  09:00, and a tag that moves names a different dose tomorrow.

  The drawing's rows have no id and cannot borrow one, so they take
  `"drawn_1"`..`"drawn_4"` — held in the same `dose_` namespace so one
  `handle_tap/2` reads both, and distinct from each other so the four cards on
  a fresh install stop sharing one `accessibility_id`.

  `String.to_atom/1` on a uuid is the shape screens 98, 03 and 104 already use,
  and doses are the one place worth saying why it is still safe: this is the
  only family in the app that grows every day rather than every time the user
  adds something. Three atoms per dose and a handful of doses a day is a few
  thousand a year against a table of a million, and the atoms are only ever
  built for the doses of **one** day — `:for_day` never reads a second.
  """
  @spec tags(String.t()) :: %{tap: atom(), taken: atom(), skip: atom()}
  def tags(key) when is_binary(key) do
    %{
      tap: String.to_atom("dose_" <> key),
      taken: String.to_atom("dose_" <> key <> "_taken"),
      skip: String.to_atom("dose_" <> key <> "_skip")
    }
  end

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
    actions = Kati.Screens.Medication.actions(Kati.Screens.Medication.undecided(doses))

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={12} />
      {notice}
      {actions}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The dose the two verbs belong to: the first on the page not decided about.

  `:missed` counts as undecided, and that is the whole reason this is a
  function rather than a `state == :due` test. A dose reads `:missed` the
  minute after it was due — `Kati.Health.Dose.resolve/2` derives it from the
  clock rather than storing it — so a page opened at 21:00 with an untouched
  14:00 tablet on it has one thing left to answer and it is that one. A verb
  that skipped past it would leave the only undecided dose of the day
  unreachable from the two controls drawn for exactly that job.
  """
  @spec undecided([map()]) :: map() | nil
  def undecided(doses), do: Enum.find(doses, &(&1.state in [:due, :missed]))

  @doc false
  def dose_row(dose) do
    suffix = Dose.state_suffix(dose.state)
    line = if suffix, do: dose.line <> " · " <> suffix, else: dose.line

    assigns = %{
      time: dose.time,
      name: dose.name,
      line: line,
      background: Kati.Screens.Medication.fill(dose.state),
      tap: {self(), dose.tap}
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
  The two verbs a dose takes, tagged with the dose they are about to decide.

  `Taken` and `Skip`, side by side rather than as a swipe: a dose is a thing you
  decide about once a day and a gesture with no affordance is not a control.

  They take the row rather than reading for it, so *which dose* is answered at
  draw time by the list the user is looking at. The board answers it visually,
  by drawing this pair inside the one undecided card; this page keeps them
  under the list, as it always has, and carries the same answer in the tag.

  A day with nothing left to decide draws no verbs at all. Two buttons whose
  only possible outcome is a red line saying there is nothing to save would be
  a control that exists to fail — and a page listing four ticks has already
  said what it has to say.
  """
  @spec actions(map() | nil) :: map() | []
  def actions(nil), do: []

  def actions(dose) do
    assigns = %{taken: {self(), dose.taken}, skip: {self(), dose.skip}}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Row
        weight={1.0}
        height={40}
        corner_radius={20}
        background={Palette.ink_fill()}
        align="center"
        on_tap={@taken}
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
        on_tap={@skip}
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
  # Every tag this page draws for a dose is one of that dose's own three, so
  # the doses already on the socket are what a tag is resolved against —
  # rather than the id being parsed back out of the atom. `Kati.Screens.Goals`
  # settled the same question the same way, and the reason is the same: nothing
  # can then name a row that is not on the screen.
  #
  # `Map.get/3` rather than `socket.assigns.doses`, because screen 115 forwards
  # its own two tags here with its own socket, which carries Persian doses
  # under the same key and no ids in them.
  def handle_tap(tag, socket) when is_atom(tag) do
    case Enum.find_value(Map.get(socket.assigns, :doses, []), &decision(&1, tag)) do
      nil -> other_tap(tag, socket)
      {dose, state} -> {:noreply, record(socket, dose, state)}
    end
  end

  defp decision(%{tap: tag} = dose, tag), do: {dose, :taken}
  defp decision(%{taken: tag} = dose, tag), do: {dose, :taken}
  defp decision(%{skip: tag} = dose, tag), do: {dose, :skipped}
  defp decision(_dose, _tag), do: nil

  # Screen 115's two chips, which carry no dose — see the moduledoc. They are
  # the only callers left of `next_undecided/0`, and they are why it is still
  # here.
  defp other_tap(:mark_taken, socket),
    do: {:noreply, record(socket, %{id: next_undecided()}, :taken)}

  defp other_tap(:mark_skipped, socket),
    do: {:noreply, record(socket, %{id: next_undecided()}, :skipped)}

  # A medication's own page is not drawn anywhere in the 127 artboards, and the
  # row is honest about being a link. So is the `add` disc this page borrows
  # from screen 104's chrome: no new-medication sheet is drawn either, and
  # inventing one would be inventing a door. `Kati.ScreenTapSweepTest` carries
  # both.
  defp other_tap(_tag, socket), do: {:noreply, socket}

  # The page re-reads the day because a dose was recorded, not because a button
  # was pressed. Those were the same line until now.
  #
  # A failure leaves `:doses` untouched rather than re-reading: the store did
  # not change, so re-reading would redraw the identical list underneath an
  # error saying nothing was written — the same mixed message the bare `:ok`
  # used to send, only louder.
  defp record(socket, dose, state) do
    case save_dose(dose, state) do
      {:ok, _dose} ->
        socket
        |> Mob.Socket.assign(:doses, doses())
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Write.message(error))
    end
  end

  @doc """
  Record `dose` — the row a control was drawn for — as `state`.

  Takes the row rather than looking one up, which is the whole of the fix. The
  row is then read back **by its own id** and that row is updated: the page
  hands over an id it drew, and the store answers about that id or about
  nothing. A dose deleted or already decided underneath the page comes back as
  the tuple rather than as a write landing on a neighbour.

  No `rescue`. `Ash.update/2` returns `{:error, changeset}` rather than
  raising, so the one this carried caught nothing while the line above it threw
  the failure away; `Kati.Screens.Root.rescue_tap/3` is already around every
  tap for the raises that are real.

  `id: nil` — every row on a fresh install, where the four doses on the page
  are the drawing's and belong to no row — is `{:error, :nothing_to_save}`
  rather than a silent success. There is nothing to write against, and that is
  a sentence `Kati.Write.message/1` already has.
  """
  @spec save_dose(map(), :taken | :skipped) :: {:ok, Dose.t()} | {:error, term()}
  def save_dose(%{id: nil}, _state) do
    Write.note({:error, :nothing_to_save}, "medication dose")
  end

  def save_dose(%{id: id}, state) do
    with {:ok, %Dose{} = dose} <- Ash.get(Dose, id) do
      Ash.update(dose, %{
        state: state,
        recorded_at: Kati.Time.now() |> DateTime.truncate(:second)
      })
    end
    |> Write.note("medication dose")
  end

  # The id of the day's first undecided dose, for the two Persian chips that
  # carry none of their own — see the moduledoc. Stored `:due` rather than
  # resolved `:due`, so a tablet that has gone missed is still the next thing
  # to answer about.
  defp next_undecided do
    Dose
    |> Ash.Query.for_read(:for_day, %{day: Kati.Time.today()})
    |> Ash.read()
    |> case do
      {:ok, doses} -> doses |> Enum.find(&(&1.state == :due)) |> id_of()
      _other -> nil
    end
  end

  defp id_of(%Dose{id: id}), do: id
  defp id_of(nil), do: nil
end
