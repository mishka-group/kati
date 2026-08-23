defmodule Kati.Screens.GoalStates do
  @moduledoc """
  Screen 107 — the four states of screen 104, on one sheet pushed under Settings.

  Screen 104 draws three goal cards and all three are healthy: ahead, on pace,
  behind. These are the four a healthy card cannot show — the target that has
  become arithmetically unreachable, the one that was met in August, the period
  that closed and opened again, and the count that moved because something
  underneath it did. It is a reference sheet in screen 27's manner: four
  pictures of a state you go and look at, rather than something the app puts in
  front of you, which is why it carries a back pill, as 27 and 67 do.

  One eyebrow keeps the orange dash. `Impossible` is the only band here that is
  happening **now** — the day the arithmetic runs out is a particular day, and
  the card asks for a decision on it. The other three are settled: a goal
  finished in August, a rollover that has already happened, a recount already
  applied. Orange means new/now and nothing else on this sheet is either, so
  the other three take 27's grey dash.

  ## Impossible states the arithmetic and never the person

  Every figure in that card comes out of one fixture. `impossible/0` is 104's
  own books goal moved to 48, so **4** is `target - progress`, **Make it 48**
  is `progress`, and the bar is `48 / 52`. A card whose sentence disagreed with
  the numbers printed 40pt above it would be the one thing a states sheet
  cannot afford, and typing the sentence out by hand is exactly how that
  happens.

  What the card does not do matters as much. There is no adjective, no share of
  the year called wasted, and no red anywhere except the drift pill. *The count
  stands either way* is the load-bearing clause: 48 books is 48 books whether or
  not the target moves. The two buttons are a choice rather than a correction —
  `Leave it` sits on paper rather than in a destructive colour, because leaving
  a goal unmet is not an error, and it is offered at equal weight beside
  `Make it 48` rather than as the small way out.

  `11 days` is this sheet's own figure and does not move with the clock, for the
  reason `Kati.Goals.Sample` gives for stating its projections rather than
  computing them: a fixture whose numbers move cannot be compared with the frame
  it was captured from. `Kati.Goals.Sample`'s maps are card-shaped and carry no
  dates, so there is no `ends_on` here to subtract from.

  ## What 104 lends this sheet, and what it could not

  Lent, and load-bearing:

    * **`Kati.Screens.Goals.drawn_goals/0`.** Every figure on the sheet is 104's
      books card with one field moved — `impossible/0` at 48, `completed_early/0`
      at 54. The map-update syntax is deliberate, for the reason
      `Kati.Screens.BookDetailStates.partial/0` records: a key that stops
      existing fails here loudly rather than adding a state a card would
      silently ignore. It also means `52 books this year` is typed once in the
      codebase, in 104's fixture, and this sheet cannot drift from it — three of
      the four cards quote that title and the fourth quotes its target.
    * **`Kati.Screens.Goals.bar/1`.** Which disagrees with the board twice: it
      is 5pt at radius 3 over `Kati.Theme.Palette.track/0`, where the board
      draws 2pt at radius 1 over `Kati.Theme.Palette.rail_idle/0`. 104 wins, for
      67's reason — a sheet that redrew a band its own way would report a
      difference the app does not have. The fill is the board's 92% either way,
      because that is what `48 / 52` is.
    * **`Kati.UI.SettingsList`** for the chrome, the title, both eyebrows and the
      repeat row, and **`Kati.UI.rich_text/1`** for all three explanatory
      sentences, for the reason `Kati.Screens.Goals.projection/1` gives: one
      sentence belongs in one wrapping `Text`, because a `Row` of runs orphans
      the emphasised words onto a line of their own.

  Not lent, and why:

    * **`Goals.card/1`.** The anatomy differs exactly where the state lives. The
      board puts the title and the pill in one row where 104 stacks the pace
      pill above the title, and the footnote that says what counts is replaced
      by the sentence the state exists to say. Nothing of 104's card survives
      that except the rail and the figures.
    * **`Goals.pace_pill/1` and `Goals.drift/1`.** Both read their colour from
      `pace`, and `Goals`' colour table has three paces. There is no fourth, so
      neither can say red, and `drift/1` prints a percentage where the board
      draws an em dash. `impossible_pill/1` is drawn here at the board's
      `Palette.red/0` on `Palette.red_wash_strong/0`; a fourth pace is the change
      104 would have to make first.
    * **`Goals.repeat_group/1`.** Two rows where the board draws one, and the
      sub-line is itself the state — *Off — the goal ends with its period and
      moves to the archive*, against 104's *A yearly goal restarts on 1 January,
      indefinitely*. `repeat_row/0` is built from the same `SettingsList` parts
      104 builds its group from, with the switch off and no `Habits` row under
      it, because a sheet of specimens offers nowhere to go.
    * **`Goals.chrome/0`.** Its disc is a real control that pushes
      `Kati.Screens.NewGoal`. `SettingsList.chrome(nil, 44)` instead: there is
      nothing to add to a sheet of specimens, and the board draws nothing to the
      right of the pill.
    * **The figures band.** 104 draws it inline inside `card/1` rather than as a
      builder, so `figures/1` here is this sheet's own — 27/15 at an 8pt gap,
      where 104's are 26/13 at 4. The rule this file follows throughout is 67's:
      where 104 has a public function the sheet takes it and 104 wins, and where
      it has none the board wins. If `card/1` ever grows a public `figures/1`,
      this is the call site to move.

  The two goal cards carry `Kati.Theme.shadow_card/0` — 104's own card shadow —
  so they lift off the page by exactly as much as the cards they are states of.
  The two note cards and the repeat row take `shadow_card_soft/0`, which is what
  `SettingsList.card/1` gives and what 67's alert pair takes at this radius.

  ## The D-14 answer, in time rather than in the abstract

  104 answers *what counts*: `Kati.Goals.Goal.counts/1` carries the sentence
  beside the kind so a goal type cannot arrive without one, and for `:books` it
  reads *Counts finished books only. A book you did not finish counts its pages
  toward the pages goal, not this one.*

  The last card here is that same rule after the fact. A book that was finished
  stops being finished, and the two goals move in opposite directions: 214 pages
  keep, one finish drops. Nothing in `Kati.Goals` models this yet.
  `Kati.Goals.Goal`'s moduledoc names `Kati.Goals.recount/1` as what writes
  `progress` where a real count exists; that function does not exist, and when
  it does it will write a number with nothing recording that the number moved.
  So the card's last clause is a promise about something still to be built —
  **Kati never silently recounts the past** — and it names where the entry goes:
  15 is `Kati.Screens.Activity`, the append-only trail that already exists and
  already calls itself the undo trail. The screen number is set as copy because
  the drawing sets it as copy, the same way screen 97's rule line carries `23`.

  ## The strip of marks

  34 marks in a five-step ramp under the completed-early figures, chunked into
  rows of **32**: `32*7 + 31*3 = 317`, which is where the export's `flex-wrap`
  breaks inside a 17pt-padded card on the 402dp frame, leaving a second row of
  two. `Kati.Habits.Sample.consistency/0` records the same reasoning for its 27
  — Mob has no wrap primitive, so the count is declared rather than measured —
  and declaring the frame's own break is what keeps the sheet comparable to the
  frame. The cost is the frame's too: 32 is measured for 402dp, and a narrower
  device clips the row rather than rewrapping it.

  The board gives the strip no legend, no axis and no caption, and this file does
  not invent one. What it does on that card is say the year was not thin; naming
  a unit — weeks, books, sittings — would add a fact the drawing does not have
  to a card whose subject is a number that is already true.

  `mark_tone/1` writes all five values as literals, and three of them have
  palette tokens it could have taken. That is the same choice
  `Kati.Habits.Sample.cell_tone/1` and `Kati.Fa.SampleYear.intensity/1` make,
  for the same reason: **a heat ramp is a scale, and a scale whose ends follow
  the ground stops being one.** `Palette.ink/0` is the heaviest step's exact
  value in light and `#F5F2EE` in dark, which would move the heaviest week to
  the pale end and reverse the ramp. The other half of the same fact is that
  `#D3B98A` and `#EFE3CB` are in no `Kati.Theme.Palette` row to take at all —
  the palette is the table of literals the *screens* write, and a five-step ramp
  is only ever written by a fixture. No hex reaches a prop here; `mark_tone/1`
  is the only thing that holds one.

  ## Nothing reads a store, and nothing taps

  27's argument applies unchanged: each card is a picture of a state, not a
  report that the app is in it. There *is* a live table — `Kati.Goals.Goal` and
  its `:live` read — and 104 reads it. This sheet does not, for 27's structural
  reason: a reference sheet draws all four states at once, unconditionally, and
  gating *Completed early* on a goal that had actually finished would show four
  states on one device and one on another.

  No control here carries a tap either. `Kati.Screens.Pushed` defines no
  `handle_tap/2` on purpose, so `Make it 48`, `Leave it`, `Set next year’s` and
  the repeat switch are drawn rather than wired, and none of them reports a dead
  tag. Two of them would be destructive if they were live — `Make it 48` rewrites
  the target of a real goal — which is a second reason the sheet is a sheet.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Screens.Goals
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The board's own figure, held still. See the moduledoc: `Kati.Goals.Sample`'s
  # maps are card-shaped and carry no `ends_on`, so there is no date here to
  # subtract from — and a states sheet whose "11 days" counted down with the
  # clock could not be compared with the frame it was captured from.
  @days_left 11

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :states, %{
      impossible: impossible(),
      completed: completed_early()
    })
  end

  @doc """
  The one goal this whole sheet is about, taken from screen 104's own fixture.

  104 draws the books goal first and it is the card the board quotes, down to
  the title. Taking it by position rather than retyping it keeps
  `52 books this year` in exactly one place in the codebase — 104's
  `Kati.Goals.Sample` — so the sheet cannot say something the screen it
  documents does not.
  """
  @spec goal() :: map()
  def goal, do: hd(Goals.drawn_goals())

  @doc """
  The specimen four short with eleven days left: 48 of 52.

  `pace` and `pace_label` are moved too, even though this card draws neither a
  pace pill nor a drift arrow. A specimen that still claimed *On pace* while the
  sentence under it said the target cannot be reached would be a contradiction
  sitting in the file, waiting for the first person who reuses it.

  `drift` becomes the board's em dash rather than a percentage, because there is
  no meaningful percentage to be behind by once the remaining days cannot carry
  the remaining books.
  """
  @spec impossible() :: map()
  def impossible do
    g = goal()

    %{
      g
      | progress: 48,
        fraction: 48 / g.target,
        pace: :behind,
        pace_label: "Behind",
        drift: "—"
    }
  end

  @doc """
  The same specimen finished, at 54 of 52.

  `fraction` is pinned at 1.0 rather than 54/52 for the reason
  `Kati.Goals.Goal.fraction/1` caps it: a rail that overshot its own track would
  be drawing a number the bar has no room to mean. This card draws no rail — the
  strip of marks stands where it would be — but the fixture stays true anyway,
  because it is the same map the impossible card uses.
  """
  @spec completed_early() :: map()
  def completed_early do
    g = goal()

    %{g | progress: 54, fraction: 1.0, pace: :ahead, pace_label: "Ahead", drift: nil}
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    s = assigns.states

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
        {SettingsList.title("Goals", "FOUR STATES")}
        {UI.eyebrow("Impossible — says so, offers the fix")}
        {Kati.Screens.GoalStates.impossible_card(s.impossible)}
        {SettingsList.eyebrow_muted("Completed early")}
        {Kati.Screens.GoalStates.completed_card(s.completed)}
        {SettingsList.eyebrow_muted("Period rolled over")}
        {Kati.Screens.GoalStates.rollover(s.completed)}
        {Kati.Screens.GoalStates.repeat_row()}
        {SettingsList.eyebrow_muted("Source data changed")}
        {Kati.Screens.GoalStates.recount()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The two styles every explanatory sentence on this sheet is set in.

  Returned as a pair rather than written out three times, because the three
  sentences are the same voice at the same size and a body that drifted a half
  point between cards would read as three different kinds of remark. They are
  the board's 12.5pt at 1.6, which is a shade smaller and looser than
  `Kati.Screens.Goals.projection/1`'s 13 at 1.5 — 104 sets a projection, and
  these are explanations.
  """
  @spec prose() :: {keyword(), keyword()}
  def prose do
    {[text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft()],
     [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]}
  end

  @doc """
  The impossible card: the arithmetic, then the offer.

  Reading order is the argument. The pill says which way this is going, the
  figures say where it stands, the rail says how close, and only then does the
  sentence say the target cannot be reached — so nothing on the card tells you
  the news before it has shown you the working.
  """
  @spec impossible_card(map()) :: map()
  def impossible_card(g) do
    {body, strong} = prose()
    shortfall = "#{g.target - g.progress} books in #{@days_left} days"

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true} align="top">
          <Text
            text={g.title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            weight={1.0}
            max_lines={2}
          />
          <Spacer size={12} />
          {Kati.Screens.GoalStates.impossible_pill(g.drift)}
        </Row>
        <Spacer size={13} />
        {Kati.Screens.GoalStates.figures(g)}
        <Spacer size={13} />
        {Goals.bar(g.fraction)}
        <Spacer size={14} />
        {UI.rich_text([
          {shortfall, strong},
          {" is not going to happen. The count stands either way.", body}
        ])}
        <Spacer size={14} />
        {Kati.Screens.GoalStates.impossible_actions(g)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The drift pill in the one colour `Kati.Screens.Goals` cannot paint it.

  `Goals.pace_pill/1` reads its wash and `Goals.drift/1` reads its ink from the
  same three-pace table, so neither can say red — see the moduledoc. Drawn here
  at the board's `Palette.red/0` on `Palette.red_wash_strong/0`, with the arrow
  filled, which is the one place this sheet uses `FILL 1` on a glyph that is not
  a status tick: a hollow arrow at 15pt on a wash reads as an outline rather
  than as a direction.

  The figure is an em dash rather than a percentage, so it takes DM Mono like
  every other figure on the sheet — a dash set in the body face beside a mono
  `48` would look like a different kind of mark.
  """
  @spec impossible_pill(String.t()) :: map()
  def impossible_pill(figure) do
    ~MOB"""
    <Row
      height={26}
      corner_radius={13}
      background={Palette.red_wash_strong()}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      {UI.symbol("arrow_downward", size: 15, color: Palette.red(), fill: true)}
      <Spacer size={5} />
      <Text
        text={figure}
        font_family="mono"
        text_size={11.5}
        text_color={Palette.red()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The pair of figures: what you have, over what you said.

  Both goal cards use it, which is the point of it being a function — the
  impossible card reads 48 / 52 and the finished one reads 54 / 52, and the two
  have to sit at the same height or the sheet reports a difference between the
  states that is really a difference between two pieces of markup.

  `align="bottom"` rather than a shared baseline: the bridge has no baseline
  alignment, and bottom-aligning a 27pt figure against a 15pt one is within a
  point of where the drawing's `align-items:baseline` puts them.
  """
  @spec figures(map()) :: map()
  def figures(g) do
    ~MOB"""
    <Row fill_width={true} align="bottom">
      <Text
        text={Integer.to_string(g.progress)}
        font_family="mono"
        text_size={27}
        font_weight="medium"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={8} />
      <Text
        text={"/ " <> Integer.to_string(g.target)}
        font_family="mono"
        text_size={15}
        text_color={Palette.meta()}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The two ways out, offered as two ways out.

  `Make it 48` takes the width and the ink fill, because moving the target is
  the thing the card is for; `Leave it` hugs its label on paper and keeps
  `Palette.ink_soft/0` rather than any destructive colour, because deciding not
  to move it is an equally correct answer and must not be dressed as a refusal.
  Neither is wired — see the moduledoc on why a sheet of specimens taps nothing.
  """
  @spec impossible_actions(map()) :: map()
  def impossible_actions(g) do
    make = "Make it " <> Integer.to_string(g.progress)

    ~MOB"""
    <Row fill_width={true} align="center">
      <Row weight={1.0} height={40} corner_radius={20} background={Palette.ink_fill()} align="center">
        <Spacer weight={1.0} />
        <Text
          text={make}
          text_size={12.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={8} />
      <Row
        height={40}
        corner_radius={20}
        background={Palette.paper()}
        padding_left={15}
        padding_right={15}
        align="center"
      >
        <Text
          text="Leave it"
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
      </Row>
    </Row>
    """
  end

  @doc """
  The card for a goal that finished in August.

  The tick leads rather than a pace pill, and the second line dates it — *Done
  on 14 August — 4 months early* — because *early* is the whole content of this
  state and a card that only said `54 / 52` would be indistinguishable from one
  that scraped in on 31 December.

  Below the rule the strip of marks stands where the impossible card puts its
  rail. That is deliberate: a bar pinned at its own end says nothing once the
  target is passed, and the strip says the thing that is actually interesting
  about a year finished four months early.
  """
  @spec completed_card(map()) :: map()
  def completed_card(g) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true} align="center">
          {UI.symbol("check_circle", size: 22, color: Palette.green(), fill: true)}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text={g.title}
              text_size={14.5}
              font_weight="bold"
              letter_spacing={-0.015}
              text_color={:on_surface}
              max_lines={2}
            />
            <Spacer size={4} />
            <Text
              text="Done on 14 August — 4 months early"
              text_size={12}
              text_color={Palette.sub()}
              max_lines={1}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        {Kati.Screens.GoalStates.figures(g)}
        <Spacer size={14} />
        {SettingsList.hairline(true)}
        <Spacer size={13} />
        {Kati.Screens.GoalStates.strip()}
        <Spacer size={15} />
        {Kati.Screens.GoalStates.next_year()}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The one control a finished goal offers, and it points forward.

  `Set next year’s` rather than anything that reopens the goal just closed: the
  period is over, its card goes to the archive intact, and the only useful thing
  left to do is decide the next one. Full width, because there is no second
  option to weigh it against.
  """
  @spec next_year() :: map()
  def next_year do
    ~MOB"""
    <Row
      fill_width={true}
      height={40}
      corner_radius={20}
      background={Palette.ink_fill()}
      align="center"
    >
      <Spacer weight={1.0} />
      <Text
        text="Set next year’s"
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The 34 marks, lightest to heaviest, exactly as the board orders them.

  Held as levels rather than as colours so `mark_tone/1` is the single place a
  ramp value is written, and so the ordering can be read at a glance in the
  source the way it reads on screen.
  """
  @spec marks() :: [0..4]
  def marks do
    [
      3,
      3,
      3,
      2,
      2,
      2,
      0,
      1,
      2,
      4,
      2,
      4,
      0,
      4,
      3,
      2,
      4,
      1,
      4,
      4,
      3,
      2,
      3,
      3,
      1,
      0,
      4,
      0,
      2,
      3,
      1,
      0,
      3,
      0
    ]
  end

  @doc """
  The five steps of the ramp, as literals.

  Three of the five have palette tokens — `ink`, `bronze`, `bar_gold` — and none
  of the three is taken, for the reason the moduledoc gives at length: a ramp is
  a scale, and `Palette.ink/0` inverts in dark, which would move the heaviest
  mark to the pale end and read the year backwards. The other two values are in
  no `Kati.Theme.Palette` row at all. Every literal on this sheet is here, and
  none of them reaches a prop except as this function's return value.
  """
  @spec mark_tone(0..4) :: pos_integer()
  # `Kati.Music.Sample.tone/1`, which is where this five-step bronze ramp
  # already lives — screen 74's listening field uses the identical values, and a
  # second copy here would be a second place for the middle step to drift.
  defdelegate mark_tone(level), to: Kati.Music.Sample, as: :tone

  @doc """
  The strip, chunked at the width the export wraps at.

  32 per row: `32*7 + 31*3 = 317` inside a 17pt-padded card on the 402dp frame,
  which leaves the board's own second row of two. Declared rather than measured
  because Mob has no wrap primitive — `Kati.Habits.Sample.consistency/0` carries
  the same note for its 27, and it is the same trade: the sheet matches the
  frame, and a narrower device clips rather than rewrapping.
  """
  @spec strip() :: map()
  def strip do
    rows =
      marks()
      |> Enum.chunk_every(32)
      |> Enum.map(&Kati.Screens.GoalStates.mark_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={3} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc "One row of the strip, with the board's 3pt gap between marks."
  @spec mark_row([0..4]) :: map()
  def mark_row(levels) do
    dots =
      levels
      |> Enum.map(&Kati.Screens.GoalStates.mark/1)
      |> Enum.intersperse(~MOB"<Spacer size={3} />")

    ~MOB"""
    <Row>
      {dots}
    </Row>
    """
  end

  @doc "One 7pt mark at its level's tone."
  @spec mark(0..4) :: map()
  def mark(level) do
    tone = mark_tone(level)

    ~MOB"""
    <Box width={7} height={7} corner_radius={2} background={tone} />
    """
  end

  @doc """
  The rollover note: what 1 January does to a goal that has already finished.

  Both numbers come from the finished specimen, so *a fresh 52* is its target
  and *54 of 52* is its result — the rollover cannot quote a year the card above
  it did not have. The last clause is the promise that makes a rollover safe to
  accept: the old result keeps its own card rather than being replaced by the
  new period's empty one.

  Gold rather than accent for the glyph. A rollover is scheduled, not new — the
  same distinction that gives this band a grey eyebrow dash.
  """
  @spec rollover(map()) :: map()
  def rollover(g) do
    {body, strong} = prose()

    note(%{
      icon: "repeat",
      color: Palette.gold_icon(),
      title: "1 January — a fresh " <> Integer.to_string(g.target),
      runs: [
        {"Last year finished at ", body},
        {Integer.to_string(g.progress) <> " of " <> Integer.to_string(g.target), strong},
        {". That result keeps its own card in the archive.", body}
      ],
      gap: 11
    })
  end

  @doc """
  The repeat row, switched off, saying what off means.

  Built from the parts `Kati.Screens.Goals.repeat_group/1` builds its own from
  rather than from that function, because the board draws one row where 104
  draws two and the sub-line here is the state itself — see the moduledoc.
  `lines: 2` because that sub-line is an explanation and not a setting's value.
  `Kati.UI.SettingsList.body/3` defaults to one line and truncates, which is
  right for `English · فارسی` and wrong here: what off *means* is the second
  half of this sentence, and a row that dropped it would be reporting the state
  without saying anything about it — the failure `body/3`'s own comment records
  from the diagnostic screen.
  """
  @spec repeat_row() :: map()
  def repeat_row do
    # The switch goes through `SettingsList.trailing/1` before `row/4` gets it,
    # which is what `Kati.Screens.Goals.repeat_group/1` does and what every
    # settings screen in the app does. `row/4` applies `trailing/1` again, so the
    # gap before the control is the app's real one rather than the helper's
    # single 12 — and this row has to measure like the row it is a state of.
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("repeat"),
          SettingsList.body(
            "Repeat each period",
            "Off — the goal ends with its period and moves to the archive",
            lines: 2
          ),
          SettingsList.trailing(SettingsList.switch(false)),
          rule: false
        )
      ])}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The recount note: the D-14 rule happening to a book that was already counted.

  Two goals move in opposite directions from one change, and the card says both
  halves in one breath — the pages keep, the finish drops — because a card that
  reported only the drop would read as data being taken away. The glyph is
  `history` in `Palette.sub/0`: this is the quietest of the four states, an entry
  in a log rather than a thing to answer.
  """
  @spec recount() :: map()
  def recount do
    {body, strong} = prose()

    note(%{
      icon: "history",
      color: Palette.sub(),
      title: "A book moved to Did not finish",
      runs: [
        {"Its 214 pages stay counted toward the pages goal. The books goal drops by one, " <>
           "because that goal counts finishing. ", body},
        {"Kati never silently recounts the past", strong},
        {" — the change appears in 15.", body}
      ],
      gap: 0
    })
  end

  @doc """
  The small note card the last two states share: glyph, title, one paragraph.

  One function for both because they are one band — radius 20 at 15pt of
  padding, the glyph at 19 hung off the top rather than centred so it stays
  beside the title when the paragraph runs to four lines. The two differ only in
  glyph, glyph colour and copy, and writing it twice would let those diverge in
  everything else.

  `gap` is the space under the card, which the card carries rather than the
  caller inserting it: the rollover note is 11 from the repeat row it explains,
  and the recount note is last on the page and takes nothing.
  """
  @spec note(%{
          icon: String.t(),
          color: pos_integer(),
          title: String.t(),
          runs: [{String.t(), keyword()}],
          gap: non_neg_integer()
        }) :: map()
  def note(%{icon: icon, color: color, title: title, runs: runs, gap: gap}) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
        align="top"
      >
        {UI.symbol(icon, size: 19, color: color)}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text={title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={2}
          />
          <Spacer size={6} />
          {UI.rich_text(runs)}
        </Column>
      </Row>
      <Spacer size={gap} />
    </Column>
    """
  end
end
