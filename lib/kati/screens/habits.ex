defmodule Kati.Screens.Habits do
  @moduledoc """
  Screen 22 — Habits & streaks, pushed under Stats.

  Built to `test/design/screens/22.html`. The drawing's note is the whole
  argument for the screen: *"habits reuse the calendar's green and the stats
  pixel field. A habit is just a repeating calendar item that keeps a streak —
  no new visual language needed."* Nothing here is invented; every colour and
  every shape already exists on another screen.

  ## The screen reads its own store now

  Every number is counted off `Kati.Habits` — the habits this reader made and
  the days they were kept — and every control writes. It used to draw
  `Kati.Habits.Sample` on every device, because nothing anywhere recorded a
  habit being kept; the moduledoc of `Kati.Habits` is where that argument now
  lives, and this screen is its first reader.

  ## A fresh install gets a sentence, not four invented habits

  A screen that fabricates the reader's own content is the app lying about the
  thing it exists to hold — #91's ruling, and the reason Home, Library, Stats
  and Calendar draw their emptiness. Four sample habits with streaks nobody
  has would be worse here than anywhere: the first thing the page says is a
  claim about the reader's own behaviour. So with nothing stored the page is
  the drawing's chrome and a card that says what a habit is and offers the one
  action that fixes it.

  The drawing's own content is not lost: `drawn_habits/0`, `drawn_field/0` and
  `drawn_captions/0` are the fixture `Kati.ScreenDesignLiteralTest` installs to
  compare board 22, and `Kati.ScreenEmptyDatabaseTest`'s `empties/0` holds the
  other half — that a device answers with none of them.

  ## Two components, and no hand-built squares

  The week strip and the thirteen-week field are both `<MishkaHeatmap>`: the
  same grid at two sizes, one with ticks and one without. The card is
  `<MishkaCard>`, the `+` and the today tick are `<MishkaActionIcon>`, the add
  form is `<MishkaTextInput>` and two `<MishkaPill>`s, and the empty state is
  `<MishkaEmptyState>`. A day square built by hand here would be the fourth
  copy of a component this app already vendors.

  ## Why tapping a square works now

  The drawing's seven squares were history with no weekday mapping, so a tap
  could not move one without inventing one. They are real dates now — the
  reader's own week, opening on Monday in English and شنبه in Persian — so a
  square for today or any earlier day in the strip flips that day's tick. A
  future day has no handler, because a habit cannot be kept in advance.

  ## The streak counts days, and today is not a failure yet

  `Kati.Habits.streak/3` counts back from today while today is kept, and from
  yesterday while it is not: an untapped today is a day that has not happened,
  not a broken run. Ticking today moves the card's line and the header's best
  by one, and unticking moves them back — nothing is stored but the tick.

  ## Every number on this screen is derived from the habit list

  The header prints a count and a best, a card prints a streak, and the field
  prints a hit rate; all four are functions of the tick table. Storing a
  rendered `"12 days"` beside the tick would let a tap move one and not the
  other, and the card would print a lit tick above a broken streak.

  ## The same screen in both scripts

  mishka-group/kati#103. The reader's own habit name is never translated — it
  is their writing. Everything else is a count this file derives or a string
  the catalogue holds, and the numbers all go through `Kati.Locale.number/1`.

  `week_ruler/0` is PICKED, not translated: `M T W T F S S` and `ش ی د س چ پ ج`
  are seven columns each of a *different* seven days, so a catalogue pairing
  `M` with `ش` would quietly move every tick two days. The week's dates follow
  the same choice. `Kati.Meals.SamplePlan.columns/0` carries the long version
  of that argument and this follows it.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """

  use Kati.Screens.Pushed, back: "Stats"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaHeatmap
  alias Kati.Components.MishkaPill
  alias Kati.Habits
  alias Kati.Habits.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  # Thirteen weeks of the field, and the same 27-cell chunking the drawing
  # uses: 27*8 + 26*4 = 320, the export's own break inside an 18pt-padded card.
  @weeks 13
  @field_days 91
  @field_columns 27

  # The drawing's own month: 1 May 2026 falls in اردیبهشت under `:fa`, which no
  # arithmetic on the number 5 produces.
  @caption_month ~D[2026-05-01]

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:today, Kati.Time.today())
    |> Mob.Socket.assign(:adding?, false)
    |> Mob.Socket.assign(:draft, "")
    |> Mob.Socket.assign(:save_error, nil)
    |> Mob.Socket.assign(:confirming, nil)
    |> refresh()
  end

  @doc false
  def content(assigns) do
    habits = assigns.habits
    consistency = gettext("Consistency · %{n} weeks", n: Kati.Locale.number(@weeks))

    field_band =
      if habits == [] do
        []
      else
        [UI.eyebrow(consistency), Kati.Screens.Habits.consistency(assigns)]
      end

    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      <Scroll fill_height={true}>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.Habits.back_gap()}
          {Kati.Screens.Habits.header(habits)}
          {Kati.Screens.Habits.composer(assigns)}
          {Kati.Screens.Habits.body(assigns)}
          {field_band}
        </Column>
      </Scroll>
      {Kati.Screens.Habits.confirm_dialog(assigns)}
    </Box>
    """
  end

  # `Kati.Screens.Pushed` floats the back pill over the content, so the content
  # leaves room for it: a 42pt pill and the drawing's 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(habits) do
    subtitle = subtitle(habits)

    # `tracking/1` on the 28pt title and `max_lines={1}` under it: the design
    # tightens its headings by a fraction of an em, which breaks the joins
    # between Persian letters, and عادت‌ها is a longer word than *Habits* on a
    # line that had nothing stopping it wrapping. `mono_face/1` rather than
    # `/0` on the subtitle: `kati_mono.ttf` carries no Persian glyph, so a
    # Persian line in `mono` is handed to Android's own substitute face.
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={gettext("Habits")}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            text_align="start"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={subtitle}
            font_family={Kati.Locale.mono_face(subtitle)}
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Habits.disc("add", :new_habit)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc opposite the title — here, the `+` that adds a habit.

  `Kati.Components.MishkaActionIcon`, the same component the today tick uses:
  a round tap target holding one glyph is exactly what it is. `variant:
  :filled` is what lets `background` through, `shape: :circle` resolves 44 to
  the drawing's own 22, and `shadow` rides on the container untouched.
  """
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), tag}
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc """
  What sits under the header: the add form, then the habits or the empty card.

  The form is above the list on purpose — a composer below four cards is off
  the bottom of the phone, and a control whose result is out of frame reads as
  broken.
  """
  def body(%{habits: [], adding?: true}), do: ~MOB"<Spacer size={0} />"

  def body(%{habits: []} = assigns), do: empty_state(assigns)

  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Habits.cards(assigns.habits)}
    </Column>
    """
  end

  @doc "The add form, or nothing when it is closed."
  def composer(%{adding?: true} = assigns) do
    draft = assigns.draft
    notice = error_line(assigns.save_error)

    ~MOB"""
    <Column fill_width={true}>
      <MishkaCard
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <MishkaTextInput
          id="habit_name"
          value={draft}
          placeholder={gettext("Habit name")}
          caret="end"
          on_change={{self(), :habit_name}}
          on_submit={{self(), :save_habit}}
          background={Palette.paper()}
          corner_radius={14}
          padding_left={12}
          padding_right={12}
          padding_top={10}
          padding_bottom={10}
          text_size={14}
          max_length={80}
          fill_width={true}
        />
        <Spacer size={10} />
        {notice}
        <Row fill_width={true} align="center">
          {Kati.Screens.Habits.save_pill()}
          <Spacer size={8} />
          {Kati.Screens.Habits.cancel_pill()}
        </Row>
      </MishkaCard>
      <Spacer size={11} />
    </Column>
    """
  end

  def composer(_assigns), do: ~MOB"<Spacer size={0} />"

  @doc false
  def save_pill do
    MishkaPill.pill(
      id: "habit_save",
      label: gettext("Add"),
      background: Palette.green(),
      color: 0xFFFBFAF8,
      corner_radius: 15,
      height: 34,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 12.5,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), :save_habit}
    )
  end

  @doc false
  def cancel_pill do
    MishkaPill.pill(
      id: "habit_cancel",
      label: gettext("Cancel"),
      background: Palette.paper(),
      color: :on_surface,
      corner_radius: 15,
      height: 34,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 12.5,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), :cancel_habit}
    )
  end

  defp error_line(nil), do: ~MOB"<Spacer size={0} />"

  defp error_line(message) do
    ~MOB"""
    <Column>
      <Text text={message} text_size={12} text_color={Kati.Theme.red()} max_lines={2} />
      <Spacer size={10} />
    </Column>
    """
  end

  @doc """
  The empty page: what a habit is, and the one control that starts one.

  Board 139's rule — an empty screen says which parts still work — applied to
  the one screen whose whole content is the reader's own behaviour.
  """
  def empty_state(assigns) do
    _ = assigns
    action = empty_action()

    ~MOB"""
    <MishkaEmptyState
      id="habits_empty"
      align={:left}
      title={gettext("No habits yet")}
      description={gettext("A habit is one thing you want to keep doing. Add the first one, then tick it each day.")}
      title_size={18}
      title_weight={:bold}
      padding={0}
    >
      {action}
    </MishkaEmptyState>
    """
  end

  defp empty_action do
    MishkaPill.pill(
      id: "habit_empty_add",
      label: gettext("Add a habit"),
      background: Palette.green(),
      color: 0xFFFBFAF8,
      corner_radius: 15,
      height: 36,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 13,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), :new_habit_from_empty}
    )
  end

  @doc false
  def cards(habits) do
    children =
      habits
      |> Enum.map(&card/1)
      |> Enum.intersperse(card_gap())

    ~MOB"""
    <Column fill_width={true}>
      {children}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def card_gap, do: ~MOB"<Spacer size={11} />"

  @doc false
  def card(habit) do
    name = habit.name
    streak = streak_line(habit.streak)
    ruler = week_ruler()

    press = long_press(habit)

    node =
      ~MOB"""
      <MishkaCard
        id={"habit_" <> habit.id}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        fill_width={true}
        on_long_press={press}
      >
        <Row fill_width={true} align="center">
          <Column weight={1.0}>
            <Text
              text={name}
              text_size={14}
              font_weight="bold"
              letter_spacing={Kati.Locale.tracking(-0.015)}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={streak}
              font_family={Kati.Locale.mono_face(streak)}
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Habits.today_button(habit.today, habit.id)}
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {Kati.Screens.Habits.week(habit)}
          <Spacer weight={1.0} />
          <Text
            text={ruler}
            font_family={Kati.Locale.mono_face(ruler)}
            text_size={9.5}
            letter_spacing={Kati.Locale.tracking(0.08)}
            text_color={Palette.rail_idle()}
            max_lines={1}
          />
        </Row>
      </MishkaCard>
      """

    if press, do: node, else: %{node | props: Map.delete(node.props, :on_long_press)}
  end

  @doc """
  The 34pt round tick at the end of a habit's title row.

  Ticked today is the calendar's green with a white check; not yet is the paper
  colour with a `#C4BDB3` one — present but unlit, so the target reads as
  something you can still press rather than something that failed.
  """
  def today_button(ticked?, habit_id) do
    background = if ticked?, do: Palette.green(), else: Palette.paper()
    ink = if ticked?, do: 0xFFFBFAF8, else: Palette.rail_idle()

    MishkaActionIcon.action_icon(
      [
        id: "habit_today_" <> habit_id,
        size: 34,
        shape: :circle,
        variant: :filled,
        background: background,
        on_tap: {self(), {:toggle_today, habit_id}}
      ],
      [Kati.UI.symbol("check", size: 19, color: ink)]
    )
  end

  @doc """
  A habit's seven day squares, as `<MishkaHeatmap>`.

  One cell per date of the week, in the same order as the ruler, and a tap on a
  square for today or an earlier day flips that day's tick. A future day has no
  handler: a habit cannot be kept in advance, and a control that answers a tap
  with nothing is worse than one that is not a control.
  """
  def week(habit) do
    cells = Enum.map(habit.week, &week_cell(&1, habit.id))

    MishkaHeatmap.heatmap(
      id: "habit_week_" <> habit.id,
      cells: cells,
      columns: 7,
      cell_size: 16,
      gap: 5,
      corner_radius: 5,
      tick_icon: Kati.UI.symbol("check", size: 11, color: 0xFFFBFAF8)
    )
  end

  defp week_cell({date, state}, habit_id) do
    cell = %{color: Sample.day_tone(state), tick: Sample.ticked?(state)}

    if Date.compare(date, Kati.Time.today()) == :gt do
      cell
    else
      Map.put(cell, :on_tap, {self(), {:toggle_day, habit_id, Date.to_iso8601(date)}})
    end
  end

  @doc """
  The field's cells, each one tappable.

  The field is the only place a day older than this week is visible, so it is
  also where a forgotten day gets fixed: a tap says the whole day was kept or
  that it was not, and `Kati.Habits.toggle_all/1` applies that to every habit
  that existed then. The date is in the cell's id, which is what makes the tap
  name a day rather than a position.
  """
  def field_cells(tones, today) do
    count = length(tones)

    tones
    |> Enum.with_index()
    |> Enum.map(fn {tone, index} ->
      date = Date.add(today, -(count - 1 - index))

      %{
        color: Sample.cell_tone(tone),
        id: "habit_field_" <> Date.to_iso8601(date),
        on_tap: {self(), {:toggle_day_all, Date.to_iso8601(date)}}
      }
    end)
  end

  @doc """
  The seven letters opposite a habit's week.

  `Kati.Locale.pick/2` and **not** a msgid: `M T W T F S S` and `ش ی د س چ پ ج`
  are not one ruler translated — an English week opens on Monday and a Persian
  week on شنبه — so they are seven columns each of a *different* seven days.
  Pairing `M` with `ش` would move every tick two days to the left and leave the
  squares looking perfectly correct.
  """
  @spec week_ruler() :: String.t()
  def week_ruler, do: Kati.Locale.pick(Sample.week_ruler(), "ش ی د س چ پ ج")

  @doc """
  The consistency field: thirteen weeks of days, one 8pt cell each.

  Each cell's tone is `Kati.Habits.tone/1`'s — the fraction of the habits that
  existed that day and were kept — so the field is the reader's own history and
  not a picture.
  """
  def consistency(assigns) do
    fields = assigns.field
    columns = @field_columns
    today = assigns.today
    {month, hit} = captions(assigns)

    ~MOB"""
    <MishkaCard
      background={Palette.cream()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={18}
      fill_width={true}
    >
      <MishkaHeatmap
        id="habit_field"
        cells={Kati.Screens.Habits.field_cells(fields, today)}
        columns={columns}
        cell_size={8}
        gap={4}
        row_gap={4}
        corner_radius={2}
      />
      <Spacer size={8} />
      <Row fill_width={true} align="center">
        <Text
          text={month}
          font_family={Kati.Locale.mono_face(month)}
          text_size={10}
          text_color={Palette.cream_meta()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={hit}
          font_family={Kati.Locale.mono_face(hit)}
          text_size={10}
          text_color={Palette.cream_meta()}
          max_lines={1}
        />
      </Row>
    </MishkaCard>
    """
  end

  # Holding a card is the only way in. A visible ⋯ on every card is a control
  # the board never drew, and a row action people rarely use does not need to
  # stand on the page — the drawing's card is a surface, and this is what a
  # held surface answers.
  #
  # `nil` on the board's fixture cards: their ids name no row, and a hold that
  # opens a Delete which cannot delete is the same lie a dead button is.
  defp long_press(habit) do
    if Map.get(habit, :real, false),
      do: {self(), {:confirm_delete, habit.id}},
      else: nil
  end

  @doc """
  The confirmation a hold opens.

  Deleting a habit destroys its ticks — the streak, the week strip and the
  field's cells all go — so it takes a second, explicit choice. An alert
  dialog is the component for exactly that; it cannot be dismissed by tapping
  the backdrop (`Kati.Components.MishkaAlertDialog`'s own rule).
  """
  def confirm_dialog(assigns) do
    confirming = Map.get(assigns, :confirming)
    open? = confirming != nil

    ~MOB"""
    <MishkaAlertDialog id="habit_delete" open={open?} on_close={{self(), :cancel_delete}}>
      <MishkaDialogTitle text={gettext("Delete this habit?")} />
      <MishkaDialogDescription
        text={gettext("Its ticks and streak are deleted with it. This cannot be undone.")}
      />
      <MishkaAlertDialogAction
        text={gettext("Cancel")}
        id="habit_delete_cancel"
        on_tap={{self(), :cancel_delete}}
      />
      <MishkaAlertDialogAction
        text={gettext("Delete")}
        id="habit_delete_go"
        variant={:danger}
        on_tap={{self(), :confirm_delete}}
      />
    </MishkaAlertDialog>
    """
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  @impl true
  def handle_tap(:new_habit, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:adding?, true)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def handle_tap(:new_habit_from_empty, socket), do: handle_tap(:new_habit, socket)

  def handle_tap(:cancel_habit, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:adding?, false)
     |> Mob.Socket.assign(:draft, "")
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def handle_tap(:save_habit, socket) do
    case Habits.add(socket.assigns.draft) do
      {:ok, _habit} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:adding?, false)
         |> Mob.Socket.assign(:draft, "")
         |> Mob.Socket.assign(:save_error, nil)
         |> refresh()}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, save_message(reason))}
    end
  end

  def handle_tap({:open_menu, habit_id}, socket) do
    open = if socket.assigns.menu == habit_id, do: nil, else: habit_id
    {:noreply, Mob.Socket.assign(socket, :menu, open)}
  end

  def handle_tap({:remove_habit, habit_id}, socket) do
    {:noreply,
     socket |> Mob.Socket.assign(:menu, nil) |> Mob.Socket.assign(:confirming, habit_id)}
  end

  def handle_tap(:cancel_delete, socket) do
    {:noreply, Mob.Socket.assign(socket, :confirming, nil)}
  end

  def handle_tap({:confirm_delete, habit_id}, socket) do
    {:noreply, Mob.Socket.assign(socket, :confirming, habit_id)}
  end

  def handle_tap(:confirm_delete, socket) do
    case socket.assigns.confirming do
      nil ->
        {:noreply, socket}

      habit_id ->
        case Habits.delete(habit_id) do
          :ok ->
            {:noreply,
             socket
             |> Mob.Socket.assign(:confirming, nil)
             |> refresh()}

          {:error, reason} ->
            {:noreply,
             socket
             |> Mob.Socket.assign(:save_error, Kati.Write.message({:error, reason}))}
        end
    end
  end

  def handle_tap({:toggle_today, habit_id}, socket) do
    toggle(socket, habit_id, socket.assigns.today)
  end

  def handle_tap({:toggle_day_all, iso}, socket) do
    case Date.from_iso8601(iso) do
      {:ok, date} ->
        case Habits.toggle_all(date) do
          {:ok, _kept?} ->
            {:noreply, socket |> Mob.Socket.assign(:save_error, nil) |> refresh()}

          {:error, reason} ->
            {:noreply,
             Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
        end

      _bad ->
        {:noreply, socket}
    end
  end

  def handle_tap({:toggle_day, habit_id, iso}, socket) do
    case Date.from_iso8601(iso) do
      {:ok, date} ->
        if Date.compare(date, socket.assigns.today) == :gt,
          do: {:noreply, socket},
          else: toggle(socket, habit_id, date)

      _bad ->
        {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  defp toggle(socket, habit_id, date) do
    case Habits.toggle(habit_id, date) do
      {:ok, _kept?} ->
        {:noreply, socket |> Mob.Socket.assign(:save_error, nil) |> refresh()}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
    end
  end

  @impl true
  def handle_info({:change, :habit_name, typed}, socket) when is_binary(typed) do
    {:noreply, Mob.Socket.assign(socket, :draft, typed)}
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  # A held card. mob delivers it apart from the tap stream, so it is routed to
  # the same handler rather than given a second way to say the same thing.
  def handle_info({:long_press, tag}, socket), do: handle_tap(tag, socket)

  def handle_info({:tap, tag}, socket) do
    Kati.Screens.Root.rescue_tap(__MODULE__, tag, socket)
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  # ── What the screen prints, all of it derived ─────────────────────────────

  @doc """
  The cards the page draws, read fresh.

  The empty/read gate `Kati.ScreenEmptyDatabaseTest` asks of a migrated screen:
  over an empty store it must answer `[]`, and it must answer the drawing's four
  when the board's habits exist. `refresh/1` uses the same read, so the gate is
  asking about the page and not about a copy of it.
  """
  @spec habits() :: [map()]
  def habits do
    today = Kati.Time.today()
    cards_from(Habits.list(), Habits.ticks(Date.add(today, -@field_days), today), today)
  end

  # One read for the whole page: the cards and the field ask about the same
  # history, and two queries that must agree about what "this week" means is
  # two chances to disagree.
  defp refresh(socket) do
    today = socket.assigns.today
    habits = Habits.list()
    ticks = Habits.ticks(Date.add(today, -@field_days), today)

    cards = cards_from(habits, ticks, today)

    socket
    |> Mob.Socket.assign(:habits, cards)
    |> Mob.Socket.assign(:field, Habits.field(today, @field_days, habits, ticks))
    |> Mob.Socket.assign(:captions, captions_from(today, habits, ticks))
  end

  defp cards_from(habits, ticks, today) do
    week = Habits.week_dates(today, week_starts_on())

    Enum.map(habits, fn habit ->
      %{
        id: habit.id,
        real: true,
        name: habit.name,
        streak: Habits.streak(habit.id, today, kept?(ticks)),
        best: Habits.longest(habit.id, ticks),
        today: Map.has_key?(ticks, {habit.id, today}),
        week:
          Enum.map(week, fn date -> {date, Habits.day_state(habit.id, date, today, ticks)} end)
      }
    end)
  end

  defp captions_from(today, habits, ticks) do
    {month_caption(today), hit_caption(today, habits, ticks)}
  end

  defp captions(%{captions: {month, hit}}), do: {month, hit}

  defp captions(_assigns),
    do: {month_caption(Kati.Time.today()), hit_caption(Kati.Time.today(), [], %{})}

  defp kept?(ticks), do: fn habit_id, date -> Map.has_key?(ticks, {habit_id, date}) end

  @doc "The week's first weekday: Monday in English, شنبه in Persian."
  @spec week_starts_on() :: non_neg_integer()
  def week_starts_on do
    case Kati.Locale.direction(Kati.Locale.current()) do
      :rtl -> 6
      _ltr -> 1
    end
  end

  @doc "The header's mono line, counted off the list rather than written down."
  @spec subtitle([map()]) :: String.t()
  def subtitle([]), do: gettext("Nothing kept yet")

  def subtitle(habits) do
    best = habits |> Enum.map(&Map.get(&1, :best, 0)) |> Enum.max(fn -> 0 end)

    gettext("%{count} active · %{n}-day best",
      count: Kati.Locale.number(length(habits)),
      n: Kati.Locale.number(best)
    )
  end

  @doc """
  A streak as the card's mono line: `N days`, or `broken` for none.

  `broken` takes a CONTEXT because it is one word: `mix gettext.merge`
  fuzzy-matches a short msgid against any sentence that ends in something like
  it, and this screen's `broken` is a streak that lapsed rather than anything
  that failed.
  """
  @spec streak_line(non_neg_integer()) :: String.t()
  def streak_line(0), do: pgettext("a habit's streak, lapsed", "broken")

  def streak_line(n),
    do: ngettext("%{n} day", "%{n} days", n, n: Kati.Locale.number(n))

  @doc "The month under the consistency field, named in the reader's calendar."
  @spec month_caption(Date.t()) :: String.t()
  def month_caption(date), do: Kati.Locale.month_name(date, :long)

  @doc """
  The hit rate under the field: days on which every habit was kept, as a share
  of the field's ninety-one days.
  """
  @spec hit_caption(Date.t(), [Kati.Habits.Habit.t()], map()) :: String.t()
  def hit_caption(today, habits, ticks) do
    days = for offset <- (@field_days - 1)..0//-1, do: Date.add(today, -offset)

    percent =
      case habits do
        [] ->
          0

        _some ->
          hit = Enum.count(days, fn date -> Habits.fraction(date, habits, ticks) >= 0.999 end)
          round(hit / length(days) * 100)
      end

    gettext("%{n}% of days hit", n: Kati.Locale.number(percent))
  end

  @doc """
  Whether one habit was kept today — the card's lit tick.

  Public for the screen's own tap tests: it is the one read that turns a
  date-keyed tick map into the boolean a control shows.
  """
  @spec kept_today?(term(), Date.t(), map()) :: boolean()
  def kept_today?(habit_id, today, ticks), do: Map.has_key?(ticks, {habit_id, today})

  defp save_message(:empty_name), do: gettext("Give the habit a name.")
  defp save_message(reason), do: Kati.Write.message({:error, reason})

  # ── The drawing's own values, which a device no longer reaches ────────────

  @doc """
  Board 22, as assigns — the fixture `Kati.ScreenDesignLiteralTest` installs.

  A reader's own habits replace every one of these, which is the point: the
  board is a still picture and this screen now draws what was actually kept.
  `Kati.ScreenEmptyDatabaseTest`'s `empties/0` holds the other half — that a
  device answers with none of them.
  """
  @spec drawn_state(map()) :: map()
  def drawn_state(assigns) do
    habits = drawn_habits()

    Map.merge(assigns, %{
      habits: habits,
      adding?: false,
      draft: "",
      save_error: nil,
      field: drawn_field(),
      captions: drawn_captions()
    })
  end

  @doc "The four cards `test/design/screens/22.html` draws."
  @spec drawn_habits() :: [map()]
  def drawn_habits do
    Sample.habits()
    |> Enum.with_index()
    |> Enum.map(fn {habit, index} ->
      %{
        id: "drawn_#{index}",
        name: habit_name(habit.name),
        streak: parse_streak(habit.streak),
        best: parse_streak(habit.streak),
        today: habit.today,
        week: Enum.with_index(habit.days, fn state, day -> {drawn_date(day), state} end)
      }
    end)
  end

  @doc "The field's 91 tones, exactly as drawn."
  @spec drawn_field() :: [atom()]
  def drawn_field, do: Sample.consistency()

  @doc "The field's two mono captions, exactly as drawn."
  @spec drawn_captions() :: {String.t(), String.t()}
  def drawn_captions do
    {Kati.Screens.Habits.month_caption(@caption_month),
     gettext("%{n}% of days hit", n: Kati.Locale.number(84))}
  end

  defp drawn_date(day), do: Date.add(@caption_month, day - 1)

  @doc """
  A habit's name in the reader's language, when it is one of the drawing's.

  A vocabulary with a fall-through: the fixture's own English is the key, and
  anything else — which from the database is the reader's own words — comes
  back untouched. A catalogue is exactly the wrong thing to put a person's own
  writing through.
  """
  @spec habit_name(String.t()) :: String.t()
  def habit_name("Morning run"), do: gettext("Morning run")

  def habit_name("Read 20 pages"),
    do: ngettext("Read %{n} page", "Read %{n} pages", 20, n: Kati.Locale.number(20))

  def habit_name("No screens after 23:00"),
    do: gettext("No screens after %{time}", time: Kati.Locale.time(~T[23:00:00]))

  def habit_name("Water the plants"), do: gettext("Water the plants")
  def habit_name("New habit"), do: gettext("New habit")
  def habit_name(other), do: other

  # The drawing stores a streak the way it prints it; the board's cards need
  # the number back. The `:streak` strings in `Kati.Habits.Sample.habits/0`
  # must stay Latin: `Integer.parse("۱۲ روز")` answers `:error`, which reads as
  # 0 and would draw four lapsed habits under a `0-day best`.
  defp parse_streak(line) do
    case Integer.parse(line) do
      {n, _rest} -> n
      :error -> 0
    end
  end
end
