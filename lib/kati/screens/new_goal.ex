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

  ## A failed save keeps the sheet

  Saving used to pop the screen whatever `Ash.create/2` said, and Goals draws a
  sample when the table is empty — so a goal that never landed left behind a
  screen full of goals, and nobody could tell it from one that had. The sheet
  now stays up on `{:error, _}` and says so, which is also the only way the
  chips and the target the person just set survive to be tried again. See
  `Kati.Write`.
  """

  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Goals.Goal
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Segmented
  alias Kati.UI.Sheet

  # THE TAG, AND THE WORD DERIVED FROM IT — not `{"Week", :period_week}`.
  #
  # Two reasons, and `Kati.Screens.Weight`'s `@ranges` took this shape for both
  # of them. A `gettext/1` inside a module attribute is evaluated at COMPILE
  # time, so the four words would freeze in whichever locale the compiler
  # happened to be in and no reader would ever move them. And a word written
  # beside its own state is a word that can move with it: under `:fa` the label
  # is هفته and the tag must stay `:period_week`, because the tag is what
  # `handle_info/2` matches, what `period_value/1` writes to the row and what
  # `Segmented.plain/2` compares the selection against.
  @periods [:period_week, :period_month, :period_year, :period_custom]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:kind, :films)
     |> Mob.Socket.assign(:target, 120)
     |> Mob.Socket.assign(:period, :period_year)
     |> Mob.Socket.assign(:repeat, true)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def render(assigns),
    do: Sheet.sheet(gettext("New goal"), body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    # `pgettext/2` rather than `gettext/1` on the three eyebrows: *What*, *How
    # many* and *By when* are one and two words long, and `mix gettext.merge`
    # fuzzy-matches a msgid that short against any sentence that happens to
    # open with it — the catalogue already holds *What fits?*, *What will
    # happen* and *What it would be*. The context is what keeps this sheet's
    # three questions their own entries.
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow(pgettext("new goal sheet section", "What"))}
      {Kati.Screens.NewGoal.kind_groups(assigns.kind)}
      {UI.eyebrow(pgettext("new goal sheet section", "How many"))}
      {Kati.Screens.NewGoal.stepper(assigns.target, assigns.kind)}
      <Spacer size={20} />
      {UI.eyebrow(pgettext("new goal sheet section", "By when"))}
      {Segmented.plain(Kati.Screens.NewGoal.periods(), assigns.period)}
      <Spacer size={16} />
      {Kati.Screens.NewGoal.repeat_row(assigns.repeat, assigns.period)}
      <Spacer size={16} />
      {Kati.Screens.NewGoal.save_notice(assigns.save_error)}
      {Sheet.commit(gettext("Save goal"), :save)}
    </Column>
    """
  end

  @doc "The four segments as `{label, tag}`, in the drawing's order."
  @spec periods() :: [{String.t(), atom()}]
  def periods, do: Enum.map(@periods, &{Kati.Screens.NewGoal.period_label(&1), &1})

  @doc """
  The word on a segment, built per call rather than held in `@periods`.

  Four common labels and therefore four plain msgids: `Week`, `Month` and
  `Year` are already in the catalogue — screen 111's range control and screen
  66's year field wrote them — and a segment that said هفته here and something
  else there would be the app disagreeing with itself about a word it has.
  """
  @spec period_label(atom()) :: String.t()
  def period_label(:period_week), do: gettext("Week")
  def period_label(:period_month), do: gettext("Month")
  def period_label(:period_year), do: gettext("Year")
  def period_label(:period_custom), do: gettext("Custom")

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
      |> Enum.map(fn {kind, _s, _unit, _counts} ->
        # `Goal.unit/1` rather than the table's own element: the tuple carries
        # the English word because `unit_label/1` matches on it, and the chip
        # wants the reader's.
        UI.chip(Goal.unit(kind),
          selected: kind == selected,
          on_toggle: String.to_atom("kind_#{kind}")
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`: Persian has no
    # case, so the upcase is a no-op there — it looks like a decision and does
    # nothing, which is the half of this fold that is hardest to see.
    #
    # `Kati.Locale.mono_face/1` asks the DRAWN section's own script rather than
    # the reader's, which is the right question for a slot whose word this
    # screen does not own. `Goal.section_label/1` now answers «تماشا» under
    # `:fa`, and the same call hands it to Vazirmatn rather than to DM Mono,
    # which carries none of it — the English keys still come off
    # `Kati.Goals.Goal.sections/0`, because that is what `kind_group/2` filters
    # `kinds/0` on.
    label = Goal.section_label(section)

    assigns = %{
      section: UI.eyebrow_label(label),
      face: Kati.Locale.mono_face(label),
      chips: chips
    }

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@section}
        font_family={@face}
        text_size={9.5}
        letter_spacing={Kati.Locale.tracking(0.12)}
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
    # `Kati.Locale.number/1` and not `Integer.to_string/1`: this is the figure
    # the sentence is about, and a Persian sheet that asked چه تعداد and then
    # answered `120` in Latin digits would be half a page in each script.
    #
    # Then `Kati.Locale.mono_face/1` about the RESULT rather than `"mono"`,
    # the way `Kati.Screens.LogProgress.stepper/2` does it: `kati_mono.ttf`
    # carries none of U+06F0–U+06F9, so ۱۲۰ in DM Mono is handed to Android's
    # own substitute face — it renders, in a typeface that is not Kati's, on
    # the biggest number on the sheet. Latin digits keep DM Mono, which is what
    # the drawing sets them in.
    figure = Kati.Locale.number(target)

    assigns = %{
      target: figure,
      face: Kati.Locale.mono_face(figure),
      unit: Goal.unit(kind)
    }

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
          font_family={@face}
          text_size={27}
          font_weight="medium"
          letter_spacing={Kati.Locale.tracking(-0.02)}
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
          gettext("Repeat each period"),
          Kati.Screens.NewGoal.restart_line(period)
        ),
        Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.switch(repeat?)),
        on_tap: {self(), :toggle_repeat}
      )
    ])
  end

  @doc """
  What the repeat row says under its title, per period.

  The weekly line names the day rather than spelling `Monday` into the
  sentence, because the day the week starts on follows the LANGUAGE: board 137
  lists it with the writing direction, the calendar and the numerals as the
  four things step one decides, and `Kati.Locale.week_start/0` is where that
  answer lives. A Persian reader is promised شنبه, which is the day their week
  actually begins on. `Kati.Screens.PickSections.follows_note/0` interpolates
  the same call into the same fact.

  The other three are sentences and are translated as sentences — see
  `window/2` for the half of this that is arithmetic rather than wording.
  """
  @spec restart_line(atom()) :: String.t()
  def restart_line(:period_week),
    do: gettext("Restarts every %{day}", day: Kati.Locale.week_start())

  def restart_line(:period_month), do: gettext("Restarts on the 1st")
  def restart_line(:period_custom), do: gettext("Restarts the day after it ends")
  def restart_line(_year), do: gettext("Restarts 1 January")

  @doc """
  What a failed save says, drawn where the eye already is.

  Above the commit button rather than below it: the button is the last thing in
  the sheet, and a notice under it would land in the 34pt bottom padding or off
  the edge on the phones this sheet already fills. Above it, the sentence is
  between the person and the control they just pressed.

  `nil` draws a zero Spacer instead of nothing, so the healthy sheet and the
  failed one have the same node shape and the field above does not shift when
  the notice appears.
  """
  @spec save_notice(String.t() | nil) :: map()
  def save_notice(nil), do: ~MOB"<Spacer size={0} />"

  def save_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text text={@message} text_size={13} text_color={Palette.red()} />
      <Spacer size={12} />
    </Column>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :step_up}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :target, socket.assigns.target + 1)}

  def handle_info({:tap, :step_down}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :target, max(socket.assigns.target - 1, 1))}

  def handle_info({:tap, :toggle_repeat}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :repeat, not socket.assigns.repeat)}

  # `@periods` rather than the four atoms written out a second time. They were
  # the same list already; with the labels off them there is no longer any
  # reason for the guard to keep its own copy, and a fifth period added above
  # is selectable the moment it exists.
  def handle_info({:tap, period}, socket) when period in @periods,
    do: {:noreply, Mob.Socket.assign(socket, :period, period)}

  def handle_info({:tap, :save}, socket) do
    case save_goal(socket.assigns) do
      {:ok, _goal} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Kati.Screens.Resume.pop()}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))}
    end
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

  Returns `Ash.create/2`'s own answer rather than `:ok`. There is no `rescue`
  here because there was nothing to rescue: `Ash.create/2` reports a rejected
  changeset as `{:error, _}` and does not raise, so the old rescue caught
  nothing while the `:ok` beneath it threw the failure away. `Kati.Write.note/2`
  puts the reason somewhere a device failure can still be read afterwards.
  """
  @spec save_goal(map()) :: {:ok, struct()} | {:error, term()}
  def save_goal(assigns) do
    today = Kati.Time.today()
    {starts_on, ends_on} = Kati.Screens.NewGoal.window(assigns.period, today)

    Goal
    |> Ash.create(%{
      kind: assigns.kind,
      target: assigns.target,
      period: Kati.Screens.NewGoal.period_value(assigns.period),
      starts_on: starts_on,
      ends_on: ends_on,
      repeat: assigns.repeat
    })
    |> Kati.Write.note("new goal")
  end

  @doc """
  The dates a period covers, starting from today.

  ## These four are GREGORIAN in both languages, and `restart_line/1` is not

  Left that way on purpose and worth naming, because the sub-line above now
  reads in the reader's own calendar: the week is cut on Monday here while
  board 137 gives a Persian reader a week that begins on شنبه, the month is a
  Gregorian month rather than a شمسی one, and the year runs 1 January to 31
  December where `Kati.Goals.Goal`'s own moduledoc says a Persian yearly goal
  ends at the end of اسفند.

  Moving them is a domain change rather than a translation — these two dates
  are written to the row and are the deadline of every goal already saved — so
  it belongs with the rest of the Persian calendar work rather than in a pass
  over this screen's copy. `Kati.Locale.year_start/1` is the tool the yearly
  clause wants; `Kati.Calendar.Shamsi.days_in_month/2` is what the monthly one
  needs.
  """
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
