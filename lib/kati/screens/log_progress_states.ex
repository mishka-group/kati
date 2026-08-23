defmodule Kati.Screens.LogProgressStates do
  @moduledoc """
  Screen 71 — Log progress, five states, pushed under Settings.

  Screen 70 is the sheet; this is the sheet's states drawn once, in screen 27's
  manner, so the rest of the app can quote them instead of inventing them. Like
  27 it is a reference sheet rather than a place in the app: each block is a
  *picture* of a state, drawn unconditionally, and none of it is read back out
  of `Kati.Books.ReadingSession`. `46 pages`, `38 minutes`, `p. 214` and
  `p. 194` are the drawing's own numbers against a sitting that never happened,
  and dating them off a real book would make an invented incident read as a
  live one — 27's argument, and it holds here for the same reason.

  Everything the two screens draw the same way is screen 70's function called
  from here: the primary is `Kati.UI.Sheet.commit/2`, the steppers are
  `Kati.Screens.LogProgress.step_disc/2`, the unit control is
  `Kati.UI.Segmented.plain/2` over `Kati.Screens.LogProgress.units/0`, and the
  undo pill is `Kati.Screens.States.undo/1` at 27's own metrics, which are the
  drawing's here to the point.

  ## The two inventions the caption names

  **The disabled segment**, which the frame's own note says *has no precedent in
  the 62*. It is specified there — paper track, a `#C4BDB3` label with a
  hairline strike, no thumb — and it is implemented in `Kati.UI.Segmented`
  rather than in this file, because the next screen that has to grey a unit
  should not have to copy a strike out of a states sheet. This screen only
  chooses which segment gets it: `units_no_pages/0` takes screen 70's own three
  units and marks `Page` disabled, so the two lists cannot drift.

  **The inline correction**, modelled on screen 31's three one-tap clash fixes.
  `Log a re-read` takes the ink, and the reason is a claim about readers rather
  than a coin toss: a page *below* where you already are is almost always a book
  you are going back through, not a typo. `I meant 294` — the transposition —
  is the second-likeliest and gets the quiet fill; `Edit` hugs its label and
  reopens the field for everything else. Two of the three carry a guess and the
  third carries none, which is why they are pills and not a selection: 31 makes
  the same distinction for the same reason, and a chip's `checked` would claim
  a state that is not there.

  `Log a re-read` is also the only one of the three with somewhere to land.
  `Kati.Books.ReadingSession` carries a `reread` flag precisely so a session can
  run backwards through covered pages without moving `current_page`, and screen
  70's `save_session/1` already sets it from `page < book.current_page`. The
  drawing is naming a write path that exists.

  ## First session invents no comparison

  The cream line is `Kati.UI.Sheet.insight/2` with its runs built here rather
  than `Kati.Screens.LogProgress.insight/2`, and that is the whole point of the
  state. That function appends `duration_runs/2`, which ends every sentence with
  *· your fastest this week*. On a first session there is no week to be fastest
  in, and a superlative over one row is a sentence the app cannot support.

  ## Where this departs from the drawing

    * **The 2pt red ring.** The frame draws it as `box-shadow: 0 0 0 2px`, which
      grows *outward*; Compose's border draws inward, so the ring eats two
      points of the value card rather than adding two to it. The card is 64pt
      around two centred lines and has the room.
    * **The controls are inert**, in 31's sense. Every tag this sheet draws is
      answered by name in `handle_tap/2` and answered with nothing, because a
      specimen is not a control — tapping `Stop and save` on a reference sheet
      would save a session that does not exist. The named clauses are there so
      that a control added later without a handler still trips
      `Kati.Screens.Root`'s dead-tap report rather than being swallowed.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaPill
  alias Kati.Screens.LogProgress
  alias Kati.Screens.States
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Segmented
  alias Kati.UI.Sheet
  alias Kati.UI.SettingsList

  @note "A disabled segment has no precedent in the 62, so: paper track, " <>
          "#C4BDB3 label with a hairline strike, no thumb. The undo pill " <>
          "surfaces on both 20 and 66."

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
    note = SettingsList.note("info", @note)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title("Log progress", "five states")}
        {UI.eyebrow("Timer running — primary becomes Stop and save")}
        {Kati.Screens.LogProgressStates.timer_running()}
        {SettingsList.eyebrow_muted("First session — no comparison invented")}
        {Kati.Screens.LogProgressStates.first_session()}
        {SettingsList.eyebrow_muted("Invalid entry — one-tap fix, in 31’s manner")}
        {Kati.Screens.LogProgressStates.invalid_entry()}
        {SettingsList.eyebrow_muted("No page count — segment disabled")}
        {Kati.Screens.LogProgressStates.no_page_count()}
        {SettingsList.eyebrow_muted("Offline · post-save undo")}
        {Kati.Screens.LogProgressStates.offline_undo()}
        {note}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The timer mid-session: a live dot, the elapsed figure, `Pause`, and the ink
  button the caption is about.

  The primary is `Kati.UI.Sheet.commit/2` with a different label and nothing
  else changed, which is what *primary becomes Stop and save* means — the sheet
  does not grow a second button when the timer runs, it relabels the one it has.
  Screen 70's `timing?` assign is the switch; this is the frame it produces.

  The dot is `accent`, and it is one of the few places in Kati where orange is
  literal rather than decorative: the timer is running **now**, which is the
  only thing the colour is ever allowed to mean.
  """
  @spec timer_running() :: map()
  def timer_running do
    pause = pause_pill()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="center">
          <Box width={10} height={10} corner_radius={5} background={Palette.accent()} />
          <Spacer size={13} />
          <Text
            text="00:38:12"
            font_family="mono"
            text_size={26}
            font_weight="medium"
            letter_spacing={-0.02}
            text_color={:on_surface}
            weight={1.0}
            max_lines={1}
          />
          <Spacer size={13} />
          {pause}
        </Row>
        <Spacer size={14} />
        {Sheet.commit("Stop and save", :stop)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  # 32 tall at radius 16 with 13 of side padding, which is two points and one
  # point off `SettingsList.action_pill/1`. The drawing gives all three numbers,
  # so they are written rather than borrowed.
  defp pause_pill do
    MishkaPill.pill(
      label: "Pause",
      background: Palette.paper(),
      color: :on_surface,
      corner_radius: 16,
      height: 32,
      padding: 0,
      padding_left: 13,
      padding_right: 13,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc """
  The cream line on a first session: the subtraction, and nothing after it.

  Two runs carry the numbers and the rest is body, exactly as screen 70 sets it
  — the emphasis is what makes the sentence readable at a glance, and
  `Kati.UI.rich_text/1` flattens it to one style anyway because the bridge has
  no spans. The sentence simply ends at the full stop; see the moduledoc for
  why it cannot come from `Kati.Screens.LogProgress.insight/2`.
  """
  @spec first_session() :: map()
  def first_session do
    body = [text_size: 13, line_height: 1.55, text_color: Palette.cream_body()]
    strong = [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 13]

    card =
      Sheet.insight("lightbulb", [
        {"That’s ", body},
        {"46 pages", strong},
        {" in ", body},
        {"38 minutes", strong},
        {".", body}
      ])

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  A page below your current position, and the three ways out of it.

  The stepper is screen 70's — `step_disc/2` on both sides, unchanged — with
  only the value card restated, because the state lives entirely in that card:
  a red ring, a red figure, and a label that says what is wrong instead of what
  the number means. Nothing else about the row moves, which is what makes the
  error read as *this number* rather than as *this control*.
  """
  @spec invalid_entry() :: map()
  def invalid_entry do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {LogProgress.step_disc("remove", :step_down)}
        <Spacer size={11} />
        {Kati.Screens.LogProgressStates.rejected_value()}
        <Spacer size={11} />
        {LogProgress.step_disc("add", :step_up)}
      </Row>
      <Spacer size={14} />
      {Kati.Screens.LogProgressStates.correction()}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The value card wearing the rejection.

  Same 64pt column screen 70's `stepper/2` builds — same weight, radius, ground
  and two centred mono lines — with the shadow traded for a 2pt ring and the
  figure taken to `red`. The card stops lifting off the page while it is wrong,
  which is the drawing's idea and a good one: an error is not a thing to reach
  for.
  """
  @spec rejected_value() :: map()
  def rejected_value do
    ~MOB"""
    <Column
      weight={1.0}
      height={64}
      corner_radius={20}
      background={Palette.card()}
      border_color={Palette.red()}
      border_width={2}
      align="center"
    >
      <Spacer weight={1.0} />
      <Text
        text="194"
        font_family="mono"
        text_size={27}
        font_weight="medium"
        letter_spacing={-0.02}
        text_align="center"
        text_color={Palette.red()}
      />
      <Spacer size={4} />
      <Text
        text="BELOW YOUR CURRENT POSITION"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.1}
        text_align="center"
        text_color={Palette.muted()}
      />
      <Spacer weight={1.0} />
    </Column>
    """
  end

  @doc """
  The correction card: what happened, then the three one-tap answers.

  On the card rather than on cream, and that is the difference from screen 31.
  31's clash is the app volunteering something; this is the app refusing an
  entry, so it sits on the same white surface the field does and the glyph is
  `red` rather than gold. The pill metrics are 31's exactly — 34 tall at radius
  17, 13 of side padding, an 11.5pt semibold label — because a one-tap fix is
  the same control wherever it appears.

  The first two take a weight and the third hugs, which is the drawing's own
  ranking made structural: the two guesses share the row evenly and `Edit` costs
  only its own label.
  """
  @spec correction() :: map()
  def correction do
    reread = correction_pill("Log a re-read", Palette.ink_fill(), Palette.on_ink(), true)
    meant = correction_pill("I meant 294", Palette.paper(), Palette.ink_soft(), true)
    edit = correction_pill("Edit", Palette.paper(), Palette.ink_soft(), false)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="top">
        {UI.symbol("error", size: 18, color: Palette.red())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text="You are already on p. 214. Did you mean you re-read to p. 194?"
            text_size={12.5}
            line_height={1.55}
            text_color={Palette.cream_body()}
          />
        </Column>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        <Column weight={1.0} fill_width={true}>
          {reread}
        </Column>
        <Spacer size={8} />
        <Column weight={1.0} fill_width={true}>
          {meant}
        </Column>
        <Spacer size={8} />
        {edit}
      </Row>
    </Column>
    """
  end

  # `cream_body` is the one token whose light value is `#4A4238`, and its name
  # is wrong here — this paragraph is on the card, not on cream. Same
  # discrepancy `Kati.UI.SettingsList.chevron/0` records: the value is forced by
  # the drawing and taking a better-named token would move light mode. The cost
  # in dark is that the sentence comes back a shade warm.
  #
  # `fill?` is the drawing's `flex:1`. MishkaPill has no `weight` — a weight is
  # read off the child by the row above it — so the pill fills a weighted column
  # instead, which is `Kati.UI.even_row/2`'s arrangement for the same reason.
  defp correction_pill(label, background, color, fill?) do
    MishkaPill.pill(
      label: label,
      background: background,
      color: color,
      corner_radius: 17,
      height: 34,
      padding: 0,
      padding_left: 13,
      padding_right: 13,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center,
      fill_width: fill?
    )
  end

  @doc """
  An edition with no page count: `Page` struck out, and a way to supply one.

  `Minutes` is the raised segment rather than `Percent`, and that is deliberate
  — a percentage of an unknown length is as unanswerable as a page of one, so
  the control lands on the only unit the book can actually give. `Percent` stays
  live because the reader may know the figure from elsewhere; only `Page`, which
  the app itself cannot compute, is taken away.

  The row underneath is an ordinary settings row and not a second error: it
  names where the missing number is entered, which is screen 66's Edition row,
  rather than apologising for its absence.
  """
  @spec no_page_count() :: map()
  def no_page_count do
    row =
      SettingsList.row(
        SettingsList.icon_tile("menu_book"),
        SettingsList.body("Add a page count", "Jumps to the Edition row on 66"),
        SettingsList.chevron(),
        rule: false
      )

    ~MOB"""
    <Column fill_width={true}>
      {Segmented.plain(Kati.Screens.LogProgressStates.units_no_pages(), :unit_minutes)}
      <Spacer size={11} />
      {SettingsList.card(row)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Screen 70's three units with `Page` marked disabled.

  Derived from `Kati.Screens.LogProgress.units/0` rather than retyped, so a unit
  renamed or reordered there arrives here already correct. The tag survives the
  marking — a disabled segment sends nothing, but it is still the same `Page`
  the live sheet offers, not a different control wearing its label.
  """
  @spec units_no_pages() :: [tuple()]
  def units_no_pages do
    Enum.map(LogProgress.units(), fn
      {label, :unit_page} -> {label, :unit_page, :disabled}
      unit -> unit
    end)
  end

  @doc """
  Offline above, and the undo the save leaves behind.

  Two cards and not one, ten points apart, because they are consequences of
  different things: the cream badge is a condition of the device and the ink
  pill is the receipt for an action. The badge is flat for 27's reason — a
  condition the app is in is not an object lifted off the paper — and the pill
  is `Kati.Screens.States.undo/1` unchanged, since 27's metrics and this
  drawing's are the same metrics.

  It says `The session saves with no degradation` rather than promising a sync,
  because that is true: `Kati.Books.ReadingSession` is a local row and nothing
  about writing one needs the radio.
  """
  @spec offline_undo() :: map()
  def offline_undo do
    undo = States.undo(%{icon: "undo", text: "Logged 46 pages", action: "Undo"})

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={20}
        padding={15}
        align="center"
      >
        {UI.symbol("cloud_off", size: 20, color: Palette.gold_icon())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text="Offline"
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text="The session saves with no degradation"
            text_size={11.5}
            text_color={Palette.cream_sub()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={10} />
      {undo}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Every tag this sheet draws, answered by name and answered with nothing.

  The controls come from screen 70's builders and carry 70's tags with them, so
  they arrive tappable whether or not this screen wants them to be. It does not:
  a reference sheet draws specimens, and stopping a timer that is not running or
  stepping a number that is a picture of a number would both be lies. Screen 70
  is where every one of these tags has a consequence.

  Named clauses rather than a catch-all, deliberately. A control added to this
  file later without a handler should still reach `Kati.Screens.Root`'s dead-tap
  report, which is the only thing that can see a button whose resting pixels are
  perfect.
  """
  @impl true
  @spec handle_tap(atom(), term()) :: {:noreply, term()}
  def handle_tap(tag, socket)
      when tag in [:stop, :step_up, :step_down, :unit_percent, :unit_minutes],
      do: {:noreply, socket}
end
