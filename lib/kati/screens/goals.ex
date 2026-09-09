defmodule Kati.Screens.Goals do
  @moduledoc """
  Screen 104 — Goals, pushed under Your year.

  Three cards, one anatomy, and each in a different state, because a goals page
  where everything is going well is a drawing of a mood rather than of a screen.

  ## The projection is the point

  *On pace to finish 106 of 120*, never *you're falling behind*. The design's
  caption says so and `Kati.Goals.Goal.project/2` is where it is kept honest —
  it extrapolates the rate so far and states the number. Nothing on this page
  computes an adjective about the person reading it.

  ## Orange is legitimate here

  The palette's rule is one accent per screen and orange means *new or now*.
  Progress **is** now — it is the only thing on the page that moved today — so
  the bars take it, and the pace pills take green, bronze and tertiary instead.

  ## The footnote is the D-14 question made visible

  Every card says what counts: *counts finished books only. A book you did not
  finish counts its pages toward the pages goal, not this one.* That sentence
  lives on `Kati.Goals.Goal.counts/1` beside the kind, not in this screen, so a
  goal type cannot arrive without one.

  ## Repeat belongs to a goal, not to the page

  This page used to carry ONE repeat switch, and its own doc argued for it: the
  drawing has one row, and a page where half the goals repeated and half did
  not would have to say which, on every card, forever.

  Both halves of that were wrong. The drawing is a picture of three goals that
  happen to agree — it is not a claim that they must — and the switch answered
  the question by writing `repeat` to **every** live goal at once. Toggling it
  on a page of four goals rewrote four rows to answer something asked about
  one, and there was no way to tell from the screen which goal you had changed,
  because the row never named one.

  So the Repeat group draws a row per goal, each **titled by the goal it
  changes** and tagged `goal_repeat_<id>`. The tag is an atom carrying the id
  for the reason `Kati.Screens.ImportSources.tag/1` sets out at length: only an
  atom tag reaches Compose as a `testTag` and emits an `accessibility_id`, so a
  tuple would render a switch that no device test and no screen reader could
  address. The write reads that one row back by its id and updates it; nothing
  else on the page moves.

  Then the page re-reads. A switch that moved because a tap was *sent* is the
  shape of defect `Kati.Write` exists for — on a page there is no sheet to hold
  open, so the version of that promise is that the switch shows what the store
  says and snaps back when a write did not land. It is also what happens to a
  row that was deleted under a screen still holding it: the re-read drops it,
  rather than leaving a switch for a goal nobody has.

  The drawn sentence stays on every row — *Repeat each period — a yearly goal
  restarts on 1 January, indefinitely* — because it states the RULE rather than
  a fact about the goal above it, and the rule is the same on all of them.

  ## What a drawn row's switch does

  With nothing stored the page is `Kati.Goals.Sample`'s three, which have no
  ids. Their switches still move, because a control that cannot be pressed is a
  picture of a control and a fresh install is where most people meet this page.
  Nothing is written, because there is no row to write to.

  ## A goal is not a habit

  The last row on the page draws the line and then offers the other thing:
  *"Read every day" is a habit. "Read 52 books" is a goal.* It pushes screen 22.
  """

  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Goals.Goal
  alias Kati.Goals.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The drawn sub-line, kept verbatim so the frame comparison keeps working, and
  # said on every row because it is the rule rather than a fact about one goal.
  @repeat_line "Repeat each period — a yearly goal restarts on 1 January, indefinitely"

  def load(socket), do: Mob.Socket.assign(socket, :goals, goals())

  @doc "The live goals: what is stored, or the drawing's three."
  @spec goals() :: [map()]
  def goals do
    case stored() do
      [] -> drawn_goals()
      goals -> Enum.map(goals, &shaped(&1, Kati.Time.today()))
    end
  end

  @doc """
  The drawing's three, unconditionally.

  Stamped with the same `:id`, `:repeat` and `:repeat_tag` a stored goal
  carries, so one row builder draws both and the empty-database gate still
  compares this to `goals/0` term for term. `id: nil` is the whole of what
  separates them, and it is what `handle_tap/2` reads to decide there is
  nothing to write.
  """
  @spec drawn_goals() :: [map()]
  def drawn_goals do
    Sample.goals()
    |> Enum.with_index(1)
    |> Enum.map(fn {goal, position} ->
      Map.merge(goal, %{id: nil, repeat: true, repeat_tag: drawn_tag(position)})
    end)
  end

  @doc """
  A goal's repeat switch, as an atom naming the goal it belongs to.

  An atom rather than `{:goal, id}` for the reason
  `Kati.Screens.ImportSources.tag/1` gives: `Mob.Renderer` emits
  `accessibility_id` only for the `is_atom(tag)` clause, so a tuple-tagged
  switch fires on device and is invisible to every sweep and unnamed to a
  screen reader.

  The id rather than the row's position, because position is what the sort
  happens to give today — `:live` orders by `ends_on`, so a goal's row moves
  the day another one is added — and a tag that moves is a tag that names a
  different goal tomorrow.
  """
  @spec repeat_tag(String.t()) :: atom()
  def repeat_tag(id) when is_binary(id), do: String.to_atom("goal_repeat_" <> id)

  # The drawing's rows have no id and cannot borrow one, so they are tagged by
  # the position the drawing draws them in — which for a fixture is identity.
  # Held apart from a stored goal's tag by the `drawn_` prefix, so the two
  # namespaces cannot collide and a device test can tell which page it is on.
  defp drawn_tag(position), do: String.to_atom("goal_repeat_drawn_#{position}")

  defp stored do
    Goal
    |> Ash.Query.for_read(:live, %{today: Kati.Time.today()})
    |> Ash.read()
    |> case do
      {:ok, goals} -> goals
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc """
  One goal as the card wants it. Pure, so the projection can be tested without
  a database.
  """
  @spec shaped(Goal.t(), Date.t()) :: map()
  def shaped(%Goal{} = goal, %Date{} = today) do
    pace = Goal.pace(goal, today)
    projected = Goal.project(goal, today)

    %{
      # The id is what makes the repeat row a row about THIS goal rather than
      # about goals in general — see the moduledoc's second section.
      id: goal.id,
      # `== true` rather than the value: the column is `allow_nil?: false`, so
      # this is an identity on anything Ash read back, and it keeps
      # `Kati.UI.SettingsList.switch/1`'s boolean guard true for a `%Goal{}`
      # built in memory, which is how the projection is tested without a store.
      repeat: goal.repeat == true,
      repeat_tag: goal.id && repeat_tag(goal.id),
      pace: pace,
      pace_label: pace_label(pace),
      title: Goal.title(goal),
      progress: goal.progress,
      target: goal.target,
      fraction: Goal.fraction(goal),
      drift: drift_label(pace, Goal.drift(goal, today)),
      projection_lead: projection_lead(goal, projected),
      projection: projection(goal, projected, today),
      projection_tail: projection_tail(goal, projected),
      projection_date: projection_date(goal, projected),
      counts: Goal.counts(goal.kind)
    }
  end

  defp pace_label(:ahead), do: "Ahead"
  defp pace_label(:behind), do: "Behind"
  defp pace_label(:on_pace), do: "On pace"

  # No percentage beside `On pace`, because a number attached to it invites
  # reading the band as a failure — which is exactly the reading this page is
  # written to avoid.
  defp drift_label(:on_pace, _drift), do: nil
  defp drift_label(_pace, nil), do: nil
  defp drift_label(_pace, drift), do: "#{drift}%"

  defp projection_lead(%Goal{progress: progress, target: target}, _projected)
       when progress >= target,
       do: "Already past it, with"

  defp projection_lead(%Goal{}, nil), do: "Too early to say."
  defp projection_lead(%Goal{}, _projected), do: "On pace to finish"

  defp projection(%Goal{progress: progress, target: target} = goal, _projected, today)
       when progress >= target do
    days = Goal.days_left(goal, today)
    "#{days} #{if days == 1, do: "day", else: "days"}"
  end

  defp projection(%Goal{}, nil, _today), do: nil
  defp projection(%Goal{target: target}, projected, _today), do: "#{projected} of #{target}"

  defp projection_tail(%Goal{progress: progress, target: target} = goal, _projected)
       when progress >= target,
       do: "left in #{Calendar.strftime(goal.ends_on, "%B")}."

  defp projection_tail(%Goal{}, nil), do: nil
  defp projection_tail(%Goal{period: :year}, _projected), do: "by"
  defp projection_tail(%Goal{}, _projected), do: "."

  defp projection_date(%Goal{progress: progress, target: target}, _projected)
       when progress >= target,
       do: nil

  defp projection_date(%Goal{period: :year} = goal, projected) when not is_nil(projected),
    do: Calendar.strftime(goal.ends_on, "%-d %B")

  defp projection_date(%Goal{}, _projected), do: nil

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
        {SettingsList.title("Goals", Kati.Screens.Goals.subtitle())}
        {Kati.Screens.Goals.cards(assigns.goals)}
        {UI.eyebrow("Repeat")}
        {Kati.Screens.Goals.repeat_group(assigns.goals)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back-pill row, with the add disc on the right.

  Its own rather than `Kati.UI.SettingsList.chrome/2`, because that helper's
  disc is decorative — it takes no `on_tap`, and every screen that uses it
  draws a disc nothing happens on. Here the disc is the only way to make a
  goal, so it is a real control.
  """
  @spec chrome() :: map()
  def chrome do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Palette.card()}
          align="center"
          shadow={Kati.Theme.shadow_button()}
          on_tap={{self(), :add}}
        >
          {Kati.UI.symbol("add", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "The header's mono subtitle, carrying the real count."
  @spec subtitle() :: String.t()
  def subtitle do
    case stored() do
      [] ->
        Sample.subtitle()

      goals ->
        span = goals |> Enum.map(& &1.ends_on) |> Enum.max(Date)
        "#{length(goals)} ACTIVE · TO #{String.upcase(Calendar.strftime(span, "%-d %b %Y"))}"
    end
  end

  @doc "One card per goal."
  @spec cards([map()]) :: map()
  def cards(goals) do
    cards =
      goals
      |> Enum.map(&Kati.Screens.Goals.card/1)
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One goal card: pace pill, title, the pair of numbers, the bar, the
  projection, and the sentence that says what counts.
  """
  @spec card(map()) :: map()
  def card(goal) do
    assigns = %{goal: goal}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      padding={17}
      shadow={Kati.Theme.shadow_card()}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.Goals.pace_pill(@goal)}
        <Spacer weight={1.0} />
        {Kati.Screens.Goals.drift(@goal)}
      </Row>
      <Spacer size={11} />
      <Text
        text={@goal.title}
        text_size={17}
        font_weight="bold"
        letter_spacing={-0.02}
        text_color={:on_surface}
        max_lines={2}
      />
      <Spacer size={11} />
      <Row fill_width={true} align="bottom">
        <Text
          text={Integer.to_string(@goal.progress)}
          font_family="mono"
          text_size={26}
          font_weight="medium"
          letter_spacing={-0.02}
          text_color={:on_surface}
        />
        <Spacer size={4} />
        <Text
          text={"/ " <> Integer.to_string(@goal.target)}
          font_family="mono"
          text_size={13}
          text_color={Palette.muted()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      {Kati.Screens.Goals.bar(@goal.fraction)}
      <Spacer size={12} />
      {Kati.Screens.Goals.projection(@goal)}
      <Spacer size={11} />
      <Text text={@goal.counts} text_size={11.5} line_height={1.45} text_color={Palette.muted()} />
    </Column>
    """
  end

  @doc """
  The pace pill: a dot and a word, on a wash of its own colour.

  Green for ahead, tertiary for on pace, bronze for behind. Bronze rather than
  red, because behind on a goal is not an error — it is a fact about a Tuesday.
  """
  @spec pace_pill(map()) :: map()
  def pace_pill(goal) do
    {dot, text, wash} = pace_colours(goal.pace)
    assigns = %{label: goal.pace_label, dot: dot, text: text, wash: wash}

    ~MOB"""
    <Row
      height={24}
      corner_radius={12}
      background={@wash}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Box width={5} height={5} corner_radius={3} background={@dot} />
      <Spacer size={6} />
      <Text text={@label} text_size={11} font_weight="bold" text_color={@text} max_lines={1} />
    </Row>
    """
  end

  defp pace_colours(:ahead), do: {Palette.green(), Palette.green_text(), Palette.green_wash()}
  defp pace_colours(:behind), do: {Palette.bronze(), Palette.gold_text(), Palette.cream()}
  defp pace_colours(_on_pace), do: {Palette.tertiary(), Palette.sub(), Palette.track()}

  @doc "The arrow and the percentage, or nothing at all."
  @spec drift(map()) :: map() | []
  def drift(%{drift: nil}), do: []

  def drift(goal) do
    icon = if goal.pace == :ahead, do: "arrow_drop_up", else: "arrow_downward"
    colour = if goal.pace == :ahead, do: Palette.green_text(), else: Palette.gold_text()
    assigns = %{icon: icon, colour: colour, label: goal.drift}

    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol(@icon, size: 20, color: @colour)}
      <Text text={@label} font_family="mono" text_size={12} text_color={@colour} max_lines={1} />
    </Row>
    """
  end

  @doc "The progress rail — the one orange thing on the page."
  @spec bar(float()) :: map()
  def bar(fraction) do
    Kati.Components.MishkaProgress.progress(
      render: :box,
      value: fraction,
      max: 1,
      height: 5,
      corner_radius: 3,
      color: Palette.accent(),
      track_color: Palette.track()
    )
  end

  @doc """
  The projection sentence, with the number emphasised inside it.

  `Kati.UI.rich_text/1` rather than three Texts, because it is one sentence and
  breaking it into nodes would let it wrap in the wrong place.
  """
  @spec projection(map()) :: map()
  def projection(goal) do
    body = [text_size: 13, line_height: 1.5, text_color: Palette.ink_soft()]
    strong = [font_weight: "semibold", text_color: Palette.ink(), text_size: 13]

    runs =
      [{goal.projection_lead, body}]
      |> maybe(goal.projection, [{" ", body}, {goal.projection, strong}])
      |> maybe(goal.projection_tail, [{" " <> (goal.projection_tail || ""), body}])
      |> maybe(goal.projection_date, [
        {" ", body},
        {goal.projection_date || "", strong},
        {".", body}
      ])

    UI.rich_text(runs)
  end

  defp maybe(runs, nil, _extra), do: runs
  defp maybe(runs, _value, extra), do: runs ++ extra

  @doc """
  One repeat row per goal, then the row that says what a goal is not.

  Both are on the page rather than in a menu, because both answer a question
  somebody asks on their first visit: *does this come back*, and *why is this
  not the streak page*.

  The goal's own title is the row's first line — that is the whole of the fix:
  a switch that does not name what it changes is a switch you cannot use
  correctly, whatever it writes.
  """
  @spec repeat_group([map()]) :: map()
  def repeat_group(goals) do
    rows = Enum.map(goals, &Kati.Screens.Goals.repeat_row/1) ++ [habits_row()]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
    </Column>
    """
  end

  @doc "One goal's repeat switch, tapped by the tag that names that goal."
  @spec repeat_row(map()) :: map()
  def repeat_row(goal) do
    SettingsList.row(
      SettingsList.icon_tile("repeat"),
      SettingsList.body(goal.title, @repeat_line, lines: 2),
      SettingsList.trailing(SettingsList.switch(goal.repeat)),
      on_tap: {self(), goal.repeat_tag}
    )
  end

  defp habits_row do
    SettingsList.row(
      SettingsList.icon_tile("bolt"),
      SettingsList.body("Habits", "“Read every day” is a habit. “Read 52 books” is a goal.",
        lines: 2
      ),
      SettingsList.trailing(SettingsList.chevron()),
      on_tap: {self(), :open_habits}
    )
  end

  @doc false
  # Every tag on this page is an atom, and the repeat tags are the ones that
  # carry an id — so the page's own goals are what a tag is resolved against,
  # rather than the tag being parsed back into an id. Nothing else can then
  # spoof a row that is not on the screen.
  #
  # `Map.get/3` rather than `socket.assigns.goals`: screen 105 forwards its
  # `:add` here (`Kati.Screens.GoalsEmpty.handle_tap/2`) with its own socket,
  # which has no goals on it at all.
  def handle_tap(tag, socket) when is_atom(tag) do
    case Enum.find(Map.get(socket.assigns, :goals, []), &(&1[:repeat_tag] == tag)) do
      nil -> other_tap(tag, socket)
      goal -> {:noreply, toggle_repeat(socket, goal)}
    end
  end

  defp other_tap(:open_habits, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Habits)}

  defp other_tap(:add, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.NewGoal)}

  defp other_tap(_tag, socket), do: {:noreply, socket}

  # A drawn row has nothing to write to, so its switch is moved in place. The
  # alternative is a control that visibly does nothing on the screen most
  # people meet first.
  defp toggle_repeat(socket, %{id: nil} = goal) do
    Mob.Socket.assign(socket, :goals, flip(socket.assigns.goals, goal, not goal.repeat))
  end

  # A stored row is written and then the page is READ BACK, rather than the
  # switch being moved on the strength of having asked.
  #
  # That is `Kati.Write`'s contract as a page rather than as a sheet: a sheet
  # that stays open is how a failed save stays visible, and a page's version is
  # a switch that snaps back to whatever the store actually says. It also
  # answers the case the sweep found — the row deleted underneath a screen that
  # is still holding it — because the re-read drops it from the page instead of
  # leaving a switch that toggles a goal nobody has.
  defp toggle_repeat(socket, goal) do
    write_repeat(goal.id, not goal.repeat)

    Mob.Socket.assign(socket, :goals, goals())
  end

  defp flip(goals, %{repeat_tag: tag}, repeat?) do
    Enum.map(goals, fn goal ->
      if goal.repeat_tag == tag, do: %{goal | repeat: repeat?}, else: goal
    end)
  end

  # Reads the one row back by id and updates that row. The old switch wrote to
  # `stored()` — every live goal — which is the defect this screen was opened
  # for.
  defp write_repeat(id, repeat?) do
    with {:ok, goal} <- Ash.get(Goal, id) do
      Ash.update(goal, %{repeat: repeat?})
    end
    |> Kati.Write.note("goal repeat")
  rescue
    # No store at all — the same state `stored/0` rescues, one write later.
    error -> Kati.Write.note({:error, error}, "goal repeat")
  end
end
