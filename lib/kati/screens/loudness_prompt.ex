defmodule Kati.Screens.LoudnessPrompt do
  @moduledoc """
  Screen 136 — *Loudness → the OS prompt*.

  Built to `test/design/reference/136.html`: screen 38's step-3 question —
  *"How should we tell you?"*, the same title, the same body, the same three
  option cards — with the band the flow was missing bolted underneath it. The
  export's own caption names the gap this fills: *"what each choice **does
  next**"*. Three outcomes, three bands, in the order a reader would ask them:

    1. **Quietly** never raises the OS prompt at all, and says so in one
       sentence.
    2. **Notify me** / **Weekly digest** get a pre-prompt purpose card in
       screen 40's permission-row voice — state the scope before the system
       dialog appears — then a **Continue** that raises it.
    3. **Denied** is drawn as a sentence, not a button: Android will not
       re-prompt once refused, so a button that claims it might is a lie, and
       the caption says exactly that.

  ## The question and its three cards are not redrawn, they are called

  `Kati.Onboarding.Sample.telling/0` already holds this title, this body and
  these three options — `selected?: true` on Quietly and all — because this
  *is* step 3, read again with its consequences attached. A second copy of the
  same three sentences would be two places for one truth to drift out of; this
  screen asks `Sample.telling/0` for it instead.

  The option cards go the same way, and further than data: `Kati.Screens.
  Onboarding.option/1` and `.option_gap/0` are the exact recipe this board
  draws — same 15pt padding, same 20pt radius, same `"0 12 24 -14 #E61A1917"`
  shadow on the selected card, same `on_ink_count` sub-line at 60% — down to
  the accent tick `.option/1` already draws for Quietly via `.tick/3`. Writing
  a second `Box` tree with the same eleven numbers would be a copy waiting to
  disagree with the original; calling the one that already exists cannot.

  ## The step bar is five segments, not four, and that is NOT `Onboarding.steps/1`

  `Kati.Screens.Onboarding.steps/1` is pinned to four total segments — its own
  doc says so — because onboarding was four steps when it was written. The
  first-run flow map (board 134) renumbers the run to five once the locale
  picker (53) sits ahead of it, and this board draws that renumbered position:
  five segments, four filled. Reusing `steps/1` would draw the wrong bar;
  parameterising it is board 134's job, not this screen's. So `steps/0` here
  is a second, smaller copy of the same idiom — weighted `Box`es, a 5pt gap,
  `ink` filled against `track_off` — fixed at 5-total/4-done because that is
  the only state this board draws.

  ## Three cards, three colour recipes, and none of them a raw hex

  The confirmation card's `check_circle` is `Palette.green/0`
  (`#4E9A73`), not `green_text/0` (`#3E8460`) — the drawing's literal is the
  undarkened hue, and `green_text` is that hue *pre-darkened for a wash this
  card does not sit on*. The denial card's `notifications_off` is
  `Palette.gold_icon/0`, its ground is `Palette.cream/0`, its body copy is
  `Palette.cream_body/0`, and its one bold span is `Palette.cream_ink/0` — the
  token documented as "the headline on a cream card", which is exactly what a
  bold span sitting on this cream card is, even though `ink/0` carries the
  identical light literal. The footer's `arrow_back` and its label are the one
  token in the whole table whose light value is `0xFF8A8479`: `Palette.sub/0`,
  by value rather than by name, same as `SettingsList.chevron/0`'s discrepancy.

  ## The two paragraphs lose their bold word, on purpose

  "Kati **won't ask**…" and "…**will not ask again**." are each one `Text`
  through `Kati.UI.rich_text/1`, which is documented to concatenate every run
  and paint the whole paragraph in the longest run's style — there is no
  `AnnotatedString` on this bridge, so per-run bold is not rendered. The
  emphasis is in the runs for whoever gives `MobText` a `runs` prop later; today
  it reads as plain body copy, which is the accepted trade `rich_text/1`
  documents rather than a bug in this screen.

  ## Continue raises the dialog HERE, not on a screen that does not exist

  The pre-prompt card's own copy says *"on the next screen"* — screen 40's
  wording, kept verbatim because it is what the board draws — but no screen
  after this one is built yet, and inventing one to push to would be a screen
  this task was not asked for. `Continue` therefore calls
  `Mob.Permissions.request/2` directly, the same call `Kati.Screens.
  NotificationsHelp.ask/1` makes, and records the ask the same way so a denied
  answer reads as denied rather than as never-asked. When the next screen is
  built, the request moves there and this button starts a push instead; until
  then this is the closest true behaviour to the sentence on screen.

  ## Back to sections

  The drawing gives this screen no back pill — `Kati.Screens.Pushed` draws a
  floating one, and this board has none — only an inline `arrow_back` row
  reading *"Back to sections"*, so this is a plain `Mob.Screen` like
  `Kati.Screens.Onboarding`, not a pushed screen. The label names where a push
  from the sections step (26, `Kati.Screens.PickSections`) would return to, so
  the tap is `Mob.Socket.pop_screen/1` — the same answer `Kati.Screens.
  Pushed`'s own `:back` gives, reached by hand because this screen draws the
  link as content rather than as the shared floating pill.

  ## Audited: two option taps are silent on purpose, two are not

  Nothing on `Kati.Screens.Onboarding.option/1`'s three cards carries
  `on_tap` — that module's own audit explains why the `selected?` flags are
  the drawing's state rather than a choice being forgotten, and calling that
  function here inherits the same silence for the same reason. `Continue` and
  `Back to sections` are the two controls this board actually draws as
  pressable, and both reach a handler that changes the socket.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Onboarding.Sample
  alias Kati.Permissions
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    {:ok, Mob.Socket.assign(socket, :telling, Sample.telling())}
  end

  def render(assigns) do
    telling = assigns.telling

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.LoudnessPrompt.body(telling)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def body(t) do
    ~MOB"""
    <Column fill_width={true} padding_top={26}>
      {Kati.Screens.LoudnessPrompt.steps()}
      <Spacer size={24} />
      {Kati.Screens.LoudnessPrompt.header(t)}
      <Spacer size={18} />
      {Kati.Screens.LoudnessPrompt.options(t.options)}
      <Spacer size={14} />
      {Kati.Screens.LoudnessPrompt.confirmation()}
      <Spacer size={22} />
      {Kati.UI.SettingsList.eyebrow_muted("If Notify me or Weekly digest is chosen")}
      {Kati.Screens.LoudnessPrompt.preprompt()}
      <Spacer size={14} />
      {Kati.Screens.LoudnessPrompt.denial()}
      <Spacer size={20} />
      {Kati.Screens.LoudnessPrompt.back_link()}
    </Column>
    """
  end

  # Five segments, four filled — see the moduledoc for why this is not
  # `Kati.Screens.Onboarding.steps/1`, which is pinned to four total.
  @doc false
  def steps do
    ~MOB"""
    <Row fill_width={true} align="center">
      {1..5
       |> Enum.map(fn i -> Kati.Screens.LoudnessPrompt.step_bar(i <= 4) end)
       |> Enum.intersperse(Kati.Screens.LoudnessPrompt.step_gap())}
    </Row>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()
    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  # The board's own line-heights (1.18 / 1.6) rather than screen 38's own
  # `telling/1` numbers (1.15 / 1.55) — the two frames drew this block
  # slightly differently, and this file follows its own board.
  @doc false
  def header(t) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={t.title}
        text_size={26}
        font_weight="extrabold"
        letter_spacing={-0.035}
        line_height={1.18}
        text_color={:on_surface}
      />
      <Spacer size={11} />
      <Text text={t.body} text_size={13.5} line_height={1.6} text_color={Palette.ink_soft()} />
    </Column>
    """
  end

  @doc false
  def options(opts) do
    ~MOB"""
    <Column fill_width={true}>
      {opts
       |> Enum.map(fn opt -> Kati.Screens.Onboarding.option(opt) end)
       |> Enum.intersperse(Kati.Screens.Onboarding.option_gap())}
    </Column>
    """
  end

  @doc "The Quietly outcome: never raises the OS prompt, and says so once."
  def confirmation do
    body = [
      text_size: 12.5,
      line_height: 1.65,
      text_color: Palette.ink_soft(),
      font_family: "sans"
    ]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 12.5,
      line_height: 1.65,
      font_family: "sans"
    ]

    paragraph =
      UI.rich_text([
        {"Kati ", body},
        {"won’t ask", strong},
        {" for notification permission. Everything arrives in your inbox.", body}
      ])

    ~MOB"""
    <Box
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("check_circle", size: 18, color: Palette.green(), fill: true)}
        <Spacer size={11} />
        <Column weight={1.0}>
          {paragraph}
        </Column>
      </Row>
    </Box>
    """
  end

  @doc "The Notify me / Weekly digest outcome: state the scope, then Continue."
  def preprompt do
    ~MOB"""
    <Box
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Column fill_width={true}>
        <Row fill_width={true} align="top">
          {Kati.Screens.LoudnessPrompt.preprompt_icon()}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text="One prompt, then never again"
              text_size={14}
              font_weight="bold"
              letter_spacing={-0.015}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={6} />
            <Text
              text={"Kati asks the system for permission on the next screen. It is used " <>
                "for new episodes and the meal reminders you switch on — nothing else."}
              text_size={12.5}
              line_height={1.65}
              text_color={Palette.ink_soft()}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        {Kati.Screens.LoudnessPrompt.continue_button()}
      </Column>
    </Box>
    """
  end

  # 36/12/19 — the board's own numbers for this tile, not `SettingsList.
  # icon_tile/1`'s 30/9/17. Same recipe, resized: `Kati.Components.
  # MishkaThemeIcon` around one glyph, the paper token as its ground.
  @doc false
  def preprompt_icon do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Kati.Theme.paper(Palette.mode()), size: 36, radius: 12},
      [Kati.UI.symbol("notifications", size: 19, color: Palette.ink_soft())]
    )
  end

  @doc false
  def continue_button do
    ~MOB"""
    <Box
      on_tap={{self(), :continue}}
      fill_width={true}
      height={54}
      corner_radius={27}
      background={Palette.ink_fill()}
      shadow="0 14 28 -12 #801A1917"
      align="center"
    >
      <Text
        text="Continue"
        text_size={14.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc "The denied outcome: a sentence, not a button — Android will not re-prompt."
  def denial do
    body = [
      text_size: 12.5,
      line_height: 1.65,
      text_color: Palette.cream_body(),
      font_family: "sans"
    ]

    strong = [
      font_weight: "semibold",
      text_color: Palette.cream_ink(),
      text_size: 12.5,
      line_height: 1.65,
      font_family: "sans"
    ]

    paragraph =
      UI.rich_text([
        {"If you say no, Kati falls back to the inbox badge and ", body},
        {"will not ask again", strong},
        {". Android does not allow a second prompt — the only route back is the " <>
           "system settings app, which is where this screen would send you.", body}
      ])

    ~MOB"""
    <Box fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("notifications_off", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {paragraph}
        </Column>
      </Row>
    </Box>
    """
  end

  @doc "The way out — pops back to the sections step this screen was pushed from."
  def back_link do
    ~MOB"""
    <Row on_tap={{self(), :back_to_sections}} align="center">
      {Kati.UI.symbol("arrow_back", size: 17, color: Palette.sub())}
      <Spacer size={7} />
      <Text
        text="Back to sections"
        text_size={13}
        font_weight="semibold"
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  def handle_info({:tap, :continue}, socket) do
    {:noreply, Kati.Screens.LoudnessPrompt.continue(socket)}
  end

  @doc """
  The OS answered, so the run goes on.

  **The screen does not advance until the answer arrives**, and that is not
  politeness — `Mob.Permissions.request/2` delivers its result to the process
  that asked, so pushing the next step in the same breath sends the answer to a
  screen that no longer exists. `Kati.Screens.PickSections` records finding
  exactly that on a device with the calendar: the permission was granted, and
  nothing downstream of it ran until the next cold start.

  A refusal advances too. Android will not re-prompt once refused — this board
  draws that as a sentence rather than a button for the same reason — so
  holding someone here would be holding them at a question that can no longer
  be asked.
  """
  def handle_info({:permission, :notifications, _result}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.OnboardingFirstTitle)}

  def handle_info({:tap, :back_to_sections}, socket) do
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Raise the system dialog, note that it was asked, and re-read.

  The same shape as `Kati.Screens.NotificationsHelp.ask/1` — noting the ask is
  what lets a later `:blocked` read be told apart from `:unasked`, since
  Android reports both identically.
  """
  @spec continue(Mob.Socket.t()) :: Mob.Socket.t()
  def continue(socket) do
    socket = Mob.Permissions.request(socket, :notifications)
    Permissions.note_asked(:notifications)
    Mob.Socket.assign(socket, :notifications, Permissions.status(:notifications))
  rescue
    _error -> socket
  end
end
