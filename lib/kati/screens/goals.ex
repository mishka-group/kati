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

  def load(socket) do
    socket
    |> Mob.Socket.assign(:goals, goals())
    |> Mob.Socket.assign(:repeat, repeat?())
  end

  @doc """
  Whether the goals on this page come back when their period closes.

  One switch for the page rather than one per card, because that is what the
  drawing gives it — and because a goals page where half the goals repeated and
  half did not would need to say which, on every card, forever. With nothing
  stored it answers the drawing's `true`.
  """
  @spec repeat?() :: boolean()
  def repeat? do
    case stored() do
      [] -> true
      goals -> Enum.all?(goals, & &1.repeat)
    end
  end

  @doc "The live goals: what is stored, or the drawing's three."
  @spec goals() :: [map()]
  def goals do
    case stored() do
      [] -> Sample.goals()
      goals -> Enum.map(goals, &shaped(&1, Kati.Time.today()))
    end
  end

  @doc "The drawing's three, unconditionally."
  @spec drawn_goals() :: [map()]
  def drawn_goals, do: Sample.goals()

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
        {Kati.Screens.Goals.repeat_group(assigns.repeat)}
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
    icon = if goal.pace == :ahead, do: "arrow_drop_up", else: "arrow_drop_down"
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
  Repeat, and the row that says what a goal is not.

  Both are on the page rather than in a menu, because both answer a question
  somebody asks on their first visit: *does this come back*, and *why is this
  not the streak page*.
  """
  @spec repeat_group(boolean()) :: map()
  def repeat_group(repeat?) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("repeat"),
          Kati.UI.SettingsList.body("Repeat each period", "A yearly goal restarts on 1 January, indefinitely"),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.switch(repeat?)),
          on_tap: {self(), :toggle_repeat}
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("bolt"),
          Kati.UI.SettingsList.body("Habits", "“Read every day” is a habit. “Read 52 books” is a goal."),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :open_habits}
        )
      ])}
    </Column>
    """
  end

  @doc false
  # Writes through to every live goal, then re-reads. One switch, one meaning:
  # see `repeat?/0` for why the page has one rather than one per card.
  def handle_tap(:toggle_repeat, socket) do
    now = not socket.assigns.repeat
    Enum.each(stored(), fn goal -> Ash.update(goal, %{repeat: now}) end)
    {:noreply, Mob.Socket.assign(socket, :repeat, now)}
  rescue
    _error -> {:noreply, Mob.Socket.assign(socket, :repeat, not socket.assigns.repeat)}
  end

  def handle_tap(:open_habits, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Habits)}

  def handle_tap(:add, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.NewGoal)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
