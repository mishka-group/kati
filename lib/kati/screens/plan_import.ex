defmodule Kati.Screens.PlanImport do
  @moduledoc """
  Screen 120 — Import a plan, pushed under Plans.

  Built to `.scratch/design/pending/120.html`. This is screen 37's import idiom
  moved onto a plan: a step meter over the title, three plain counts of what the
  write will do, one conflict answered at a time, and nothing committed until the
  last of the four steps. Screen 50 is the other half of the same sentence — it
  exports the document this screen opens — so the card at the top does not invent
  a file name: `plan/0` reads `Kati.Meals.SampleShare.share/0`, and the mono line
  under *Cutting v3* is the same `KATI://PLAN/CUTTING-V3 · 35 MEALS` screen 50
  prints under its QR code. If export's copy moves, this screen stops agreeing
  with it at compile time rather than at read time.

  ## What is literally screen 37's, and what is re-drawn

  Five of `Kati.Screens.Import`'s builders are called here rather than copied,
  because both drawings put the identical node on screen:

    * `Kati.Screens.Import.header/1` — the 38pt ink pill opposite the back pill,
      reading `Import 35`. Both drawings close it with the same 16pt gap.
    * `Kati.Screens.Import.step_bar/1` and `step_gap/0` — a 4pt bar at radius 2,
      ink when the step is done and `track_off` when it is not, with 5pt between.
    * `Kati.Screens.Import.choice/1` and `choice_gap/0` — the three 32pt answer
      pills on the cream conflict card. That function's own doc carries the whole
      argument for why they are `Kati.Components.MishkaToggle` rather than a chip
      or a segmented control, and none of it changes for a meal.
    * `Kati.Screens.Import.outcome_gap/0` — the 10pt between the count cards.

  Four things are re-drawn here, and each is a place the two drawings differ
  rather than a place this file preferred its own numbers:

    * **The meter sits above the title, not below it.** So `steps/1` composes
      37's bar and gap itself and closes at 20pt rather than calling
      `Kati.Screens.Import.steps/1`, which closes at 22. The gap is not a style:
      on 37 it is the space down to the file card, and here it is the space down
      to a headline. Both numbers are the design's.
    * **The counts are set in DM Mono at weight 500**, where 37 sets them in Plus
      Jakarta at 800, and their labels are 9.5pt rather than 10. A plan's counts
      belong to the same family as the `35 MEALS` line above them — this screen
      counts what a machine-readable document contains — so `count_card/1` is its
      own function and `Kati.Screens.Import.outcome_card/1` is left alone.
    * **The card at the top is a 40pt tile at radius 12 on a radius-22 card**,
      against 37's 38pt tile at radius 11 on a radius-20 card, and its glyph is
      `qr_code_scanner` rather than `description`. `Kati.Screens.Import.file_tile/0`
      hardcodes the glyph, so the tile could not have been borrowed even if the
      geometry had matched.
    * **The conflict leads with an icon tile, not a poster.** A meal has no
      artwork on this screen, so `conflict/1` is re-drawn around
      `conflict_tile/1` instead of `Kati.Screens.Import.conflict_poster/1`. Its
      second line carries no `★` either, which is why it is a plain `Text` and
      not `Kati.Screens.Import.star_text/3`.

  ## The two as-is rows

  They are the reason the caption says silence would be dishonest, and both are
  claims the schema can actually keep:

    * **`7 meals with partial nutrition`** arrive marked approximate because
      approximate is *derived*, not stored.
      `Kati.Screens.MealLibrary.approximate?/1` answers it from the ingredient
      rows — any ingredient carrying an amount and no calories — so an imported
      recipe is approximate the moment it lands, with no flag to set on the way
      in and none to forget. There is nothing here that could launder a partial
      figure into an exact one, which is what makes the row safe to print.
    * **`12 ingredients with no aisle`** land in `Kati.Meals.Aisle`'s `:other`,
      the value that exists so an aisle is always answerable. Screen 119 states
      the consequence this row is quietly promising against: *a dropped
      ingredient vanishes from the shopping list*, so a missing aisle is filed
      under one rather than filed nowhere. The drawing writes `Uncategorised`
      where `Kati.Meals.Aisle.label/1` writes `Other`; the copy on screen is the
      drawing's, and the domain's word is the one that would have to move.

  ## Three things the drawing asks for that this cannot draw

    * **The idle answer pills are 62% white and render at 60%.**
      `Palette.cream_raise/0` is `0x99FFFFFF`, which is `rgba(255,255,255,.60)`,
      and there is no token at `.62`. Two percent of white on cream is under one
      unit of each channel; inventing a token, or writing the literal, would cost
      more than it buys and would take the pill out of step with screen 37's,
      which is the same control.
    * **The gold tile behind `help` is a 14% wash and renders at 19%.**
      `Kati.Theme.Palette` has washes for orange, green and red and none for
      gold, so the ground comes from `Kati.Components.MishkaThemeIcon`'s `:light`
      variant, which tints whatever colour it is handed to `0x30`. Handing it
      `Palette.gold_icon/0` keeps the hue exactly the drawing's and moves the
      strength by five points. `Palette.cream/0` was the other candidate and is
      worse: it is the *surface* the two warm cards on this screen already use,
      and re-using it for a 30pt tile would say the tile is a small cream card.
    * **`they never leave their device` is bold in the export and renders
      regular.** The footer is one wrapping paragraph, so it is
      `Kati.UI.rich_text/1`, which concatenates its runs into a single `Text` —
      the bridge has no `AnnotatedString`, and a `Row` of styled runs would
      orphan the emphasised clause onto a line of its own. That helper's doc has
      the bridge change that would make the emphasis real.

  ## Audited

  **Every string on this screen is drawn, and nothing here writes.** The counts,
  the conflict and the two as-is rows are the design's own numbers held in this
  module, because the state they describe cannot be held anywhere else yet:
  `lib/kati/import` contains one sample module, and no Ash resource models an
  import job, a merge outcome or a conflict queue. `Kati.Screens.Import`'s own
  moduledoc sets that out in full and names `Kati.Backup.inspect_file/1` as the
  shape to copy — it opens a file and reports what a restore would write
  *without writing it*, which is exactly the promise the step meter is making.

  The gap is sharper here than on 37, because a plan is a smaller thing to model.
  `Kati.Meals.MealPlan` and `Kati.Meals.MealPlanSlot` already hold everything the
  footer says travels — the meals, the targets and the reminder times, 35 slots
  and a repeat rule — so what is missing is not the destination but the staging:
  somewhere to keep a parsed plan, its counted outcome and an answered conflict
  alive across the two renders that *step 3 of 4* implies. Without it the answer
  to `Overnight oats` would be forgotten the moment the screen popped, which is
  why no control on this screen carries a tap and why `Kati.Screens.Pushed`
  defines no `handle_tap/2` to swallow the ones that do not exist.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Plans"

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Meals.SampleShare
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :import, %{
      plan: plan(),
      counts: counts(),
      conflict: conflict(),
      as_is: as_is()
    })
  end

  @doc """
  The page, in the order the export lays it out.

  The two orange eyebrows label sections that are *happening* — what the write
  will do, and the question waiting for an answer — while `Coming in as-is`
  takes the grey dash, because it is a footnote to the counts above it rather
  than something new. Orange means new or now in this design and nothing else,
  which is the whole reason `Kati.UI.SettingsList.eyebrow_muted/1` exists beside
  `Kati.UI.eyebrow/2`.
  """
  @spec content(map()) :: term()
  def content(assigns) do
    job = assigns.import

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Import.header(job.plan)}
        {Kati.Screens.PlanImport.steps(job.plan)}
        {Kati.Screens.PlanImport.title(job.plan)}
        {Kati.Screens.PlanImport.source_card(job.plan)}
        {UI.eyebrow("What will happen")}
        {Kati.Screens.PlanImport.count_row(job.counts)}
        {UI.eyebrow("Conflicts · keep which?")}
        {Kati.Screens.PlanImport.conflict(job.conflict)}
        {SettingsList.eyebrow_muted("Coming in as-is")}
        {Kati.Screens.PlanImport.as_is(job.as_is)}
        {Kati.Screens.PlanImport.footer()}
      </Column>
    </Scroll>
    """
  end

  # ── The data the drawing holds ────────────────────────────────────────────

  @doc """
  The plan being imported, and how far through the import we are.

  `name` and `uri` are read from `Kati.Meals.SampleShare.share/0` rather than
  written out again, because the file this screen is opening is the file screen
  50 produces — *"import accepts the same file export produces, which is the only
  reason the two live on one screen"* — and two copies of one URI is how that
  claim quietly stops being true.

  `action` is a count of meals rather than of rows: a plan arrives as 35 slots,
  and `35 MEALS` is already the last thing the URI line says.
  """
  @spec plan() :: map()
  def plan do
    share = SampleShare.share()

    %{action: "Import 35", name: share.plan, uri: share.qr_uri, steps: 4, step: 3}
  end

  @doc """
  What the write would do, as three counts.

  `tone` rather than a colour, and the difference matters: `load/1` runs at mount
  and `Kati.Theme.Palette`'s tokens resolve against the theme installed at the
  moment they are called, so a colour baked in here would be the mount's answer
  rather than the frame's. `count_card/1` resolves the tone at render instead.

  Green for merged and red for conflicts, because those are the two outcomes a
  person has to think about; new meals are the boring majority and stay ink.
  """
  @spec counts() :: [map()]
  def counts do
    [
      %{value: "29", label: "New", tone: :ink},
      %{value: "4", label: "Merged", tone: :green},
      %{value: "2", label: "Conflicts", tone: :red}
    ]
  end

  @doc """
  The conflict on top of the pile.

  One at a time, with `apply to all` offered underneath rather than taken as the
  default — two decisions is a short queue, and a blanket answer to a question
  nobody has read is how an import quietly overwrites a figure someone measured.

  The line names both numbers rather than summarising the disagreement, so the
  three pills below it are a choice between two known values and not a bet.
  """
  @spec conflict() :: map()
  def conflict do
    %{
      icon: "restaurant",
      title: "Overnight oats",
      line: "Yours 410 kcal · file says 385 kcal",
      choices: [{"Keep mine", true}, {"Take file", false}, {"Keep both", false}],
      progress: "1 of 2 · apply to all"
    }
  end

  @doc """
  The two things that arrive imperfect and are said out loud.

  `tone` picks the tile: gold for the row that is about a *figure* being partial,
  which is the palette's note hue, and paper for the row that is about a *label*
  being absent, which is filing rather than doubt.

  Both sub-lines are sentences rather than settings values, which is why
  `as_is/1` passes `lines: 2` to `Kati.UI.SettingsList.body/3` — at one line the
  first would stop at *exactly as the sender* and the second would delete the
  half that says the ingredients still reach the shopping list.
  """
  @spec as_is() :: [map()]
  def as_is do
    [
      %{
        tone: :gold,
        icon: "help",
        title: "7 meals with partial nutrition",
        sub: "Arrive marked approximate, exactly as the sender had them"
      },
      %{
        tone: :paper,
        icon: "label",
        title: "12 ingredients with no aisle",
        sub: "Filed as Uncategorised — they still reach the shopping list"
      }
    ]
  end

  # ── The frame ─────────────────────────────────────────────────────────────

  @doc """
  The four-segment step meter, over the title rather than under it.

  Composed from `Kati.Screens.Import.step_bar/1` and `step_gap/0` rather than
  calling `Kati.Screens.Import.steps/1`, because that function closes with the
  22pt it needs on screen 37 — where the meter sits under the title and the next
  thing is a card — and here the meter opens the page and the next thing is a
  headline, which the drawing sets 20pt away.
  """
  @spec steps(map()) :: term()
  def steps(plan) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..plan.steps
         |> Enum.map(fn i -> Kati.Screens.Import.step_bar(i <= plan.step) end)
         |> Enum.intersperse(Kati.Screens.Import.step_gap())}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The headline and the mono step kicker under it.

  The kicker is built from the same two numbers the meter is drawn from rather
  than being written out as `STEP 3 OF 4`, so the sentence and the bars above it
  cannot disagree — a meter showing three of four over a line reading step 2 is
  the kind of wrong that survives review because both halves look right alone.

  `~MOB` is an uppercase sigil, so `#{}` inside it is literal text; the string is
  assembled out here for that reason and not by preference.
  """
  @spec title(map()) :: term()
  def title(plan) do
    kicker = "STEP #{plan.step} OF #{plan.steps}"

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Import a plan"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={6} />
      <Text
        text={kicker}
        font_family="mono"
        text_size={11.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The card that says what was scanned, and that it parsed.

  The filled `check_circle` is the only green on the page above the counts, and
  it is deliberately about the *file* rather than about the import: the document
  was read, which is what step 3 of 4 is allowed to claim. Nothing on this card
  says anything has been written.
  """
  @spec source_card(map()) :: term()
  def source_card(plan) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        {Kati.Screens.PlanImport.source_tile()}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={plan.name}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={plan.uri}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        {UI.symbol("check_circle", size: 20, color: Palette.green(), fill: true)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 40pt paper tile the source card leads with.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon" — at this drawing's own numbers, which are two points and one radius unit
  away from screen 37's file tile and so could not reuse it.

  `variant: :filled` with an explicit `color`, not `variant: :white`: the white
  variant paints the theme's `:surface`, which here is the card the tile sits on.

  The glyph goes in as a child rather than through the `icon` prop, because that
  shorthand builds a `Text` with no `font_family` and the ligature
  `"qr_code_scanner"` would then be typeset as the word instead of resolving to
  the Material Symbols glyph. Passing `Kati.UI.symbol/2` also keeps
  `Kati.Icons.glyph!/1`'s raise for a name outside the shipped subset.
  """
  @spec source_tile() :: term()
  def source_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 40, radius: 12},
      [UI.symbol("qr_code_scanner", size: 20, color: Palette.ink_soft())]
    )
  end

  @doc """
  The three counts, in one weighted row.

  `Kati.Screens.Import.outcome_gap/0` sets the 10pt between them — the two
  drawings agree on that number exactly — while the cards themselves are this
  screen's, for the typeface reason the moduledoc gives.
  """
  @spec count_row([map()]) :: term()
  def count_row(cards) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cards
         |> Enum.map(fn card -> Kati.Screens.PlanImport.count_card(card) end)
         |> Enum.intersperse(Kati.Screens.Import.outcome_gap())}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One count: a mono figure over a mono, letter-spaced caps label.

  The figure is DM Mono at weight 500, which is where this parts company with
  screen 37's sans 800. These numbers are read off a document rather than
  announced, and the drawing sets them in the same face as the `35 MEALS` on the
  card above — so the whole page counts in one voice.

  The tone is resolved here rather than in `counts/0` so that the colour is the
  frame's answer and not the mount's; see that function's doc.
  """
  @spec count_card(map()) :: term()
  def count_card(card) do
    color =
      case card.tone do
        :ink -> Palette.ink()
        :green -> Palette.green()
        :red -> Palette.red()
      end

    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
      >
        <Text
          text={card.value}
          font_family="mono"
          text_size={22}
          font_weight="medium"
          letter_spacing={-0.03}
          text_color={color}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={5} />
        <Text
          text={String.upcase(card.label)}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.1}
          text_color={Palette.muted()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc """
  The open conflict, on the palette's one warm surface.

  Cream marks the single place on this page where the screen is asking rather
  than telling — the same warming a note gets on screen 08 and the conflict card
  gets on screen 37. Everything above it is a report; this is the question.

  The title takes `Palette.cream_ink/0` rather than the theme's `:on_surface`.
  Both are `#1A1917` in light, so the drawing is untouched, and the cream token
  is the one whose stated meaning is *the headline on a cream card* — which is
  what keeps it legible when the card warms to a lit-lamp brown in dark.

  The three pills are `Kati.Screens.Import.choice/1` unchanged, so the answer to
  a clashing rating and the answer to a clashing calorie count are the same
  control rather than two that resemble each other.
  """
  @spec conflict(map()) :: term()
  def conflict(c) do
    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={15}>
        <Row fill_width={true} align="center">
          {Kati.Screens.PlanImport.conflict_tile(c.icon)}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text={c.title}
              text_size={13}
              font_weight="bold"
              text_color={Palette.cream_ink()}
              max_lines={1}
            />
            <Spacer size={3} />
            <Text text={c.line} text_size={11.5} text_color={Palette.cream_sub()} max_lines={1} />
          </Column>
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {c.choices
           |> Enum.map(fn choice -> Kati.Screens.Import.choice(choice) end)
           |> Enum.intersperse(Kati.Screens.Import.choice_gap())}
        </Row>
        <Spacer size={12} />
        <Text
          text={c.progress}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.cream_meta()}
          text_align="center"
          max_lines={1}
        />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 40pt tile the conflict leads with, in place of screen 37's poster.

  Screen 37's conflict is a film and has artwork; a meal on this screen has none,
  so `Kati.Screens.Import.conflict_poster/1` would draw a 34x48 grey rectangle
  standing in for a picture that is never coming.

  `Palette.poster_on_cream/0` is the ground, and it is the exactly right token
  rather than a near one: the palette names it *an image placeholder sitting ON
  the cream card, warmer than the plain one*, which is this tile's whole
  situation. The glyph is `Palette.gold_icon/0`, the note hue the rest of the
  warm surfaces on this page already carry.
  """
  @spec conflict_tile(String.t()) :: term()
  def conflict_tile(icon) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.poster_on_cream(), size: 40, radius: 11},
      [UI.symbol(icon, size: 19, color: Palette.gold_icon())]
    )
  end

  @doc """
  The two rows that arrive imperfect, as a settings group.

  `Kati.UI.SettingsList` is what this shape is — a radius-20 card at 4/15 padding
  holding *tile · title · sub-line* rows with a 7% hairline between them — so the
  card, the rows, the bodies and the rule are all its, and the last row's missing
  hairline is `rule: false` rather than a condition written here.

  `lines: 2` on every body, because both sub-lines are explanatory sentences and
  `body/3` truncates to one by default. That default is right for a settings
  value and wrong for a sentence; the comment on `body/3` records the screenshot
  that proved it.
  """
  @spec as_is([map()]) :: term()
  def as_is(rows) do
    last = length(rows) - 1

    built =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          as_is_tile(row.tone, row.icon),
          SettingsList.body(row.title, row.sub, lines: 2),
          nil,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(built)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 30pt tile on an as-is row, in the tone the row's subject calls for.

  Neither tone can be `Kati.UI.SettingsList.icon_tile/1`: that helper is paper
  under a 17pt glyph in `Palette.ink_soft/0`, and this drawing sets both glyphs
  at 16 — the gold one on a wash of its own colour, the grey one in
  `Palette.sub/0`, which is the same colour as the sentence underneath it.

  `:gold` goes through the component's `:light` variant, which tints whatever
  colour it is handed. That is the only way to get a wash of the design's gold
  without writing an alpha literal, since `Kati.Theme.Palette` carries washes for
  orange, green and red and none for gold. It lands at 19% where the export draws
  14%; the moduledoc records the trade and why `Palette.cream/0` was the worse
  answer.

  `:paper` is `variant: :filled` with an explicit colour rather than
  `variant: :white`, for the reason `source_tile/0` gives — the white variant
  paints the theme's `:surface`, which is the card these rows sit on.
  """
  @spec as_is_tile(:gold | :paper, String.t()) :: term()
  def as_is_tile(:gold, icon) do
    MishkaThemeIcon.theme_icon(
      %{variant: :light, color: Palette.gold_icon(), size: 30, radius: 9},
      [UI.symbol(icon, size: 16, color: Palette.gold_icon())]
    )
  end

  def as_is_tile(:paper, icon) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [UI.symbol(icon, size: 16, color: Palette.sub())]
    )
  end

  @doc """
  The closing note: what does not travel, and why that is not a limitation.

  It is the one paragraph on the page, so it is `Kati.UI.rich_text/1` — a single
  wrapping `Text` — rather than a `Row` of styled runs. A `Row` does not wrap, so
  the emphasised clause would become its own unbreakable box and orphan onto a
  line by itself, which reads as a broken layout where a lost bold reads as plain
  typography. The export's bold on *they never leave their device* is therefore
  dropped; the sentence still says it.

  The runs are kept split at the emphasis anyway, so the day `rich_text/1` gains
  the `runs` prop its own doc specifies, this paragraph starts rendering the way
  it was drawn without anyone having to find it again.

  Flat cream with no shadow, exactly as the export draws it: this is a statement
  about the app's behaviour, not an object lifted off the page.
  """
  @spec footer() :: term()
  def footer do
    body = [text_size: 12.5, line_height: 1.6, text_color: Palette.cream_body()]

    paragraph =
      UI.rich_text([
        {"The sender’s history, notes and ratings do not travel — ", body},
        {"they never leave their device", :bold},
        {". You are importing meals, targets and reminder times, and nothing about how they ate.",
         body}
      ])

    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
      {UI.symbol("info", size: 18, color: Palette.gold_icon())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {paragraph}
      </Column>
    </Row>
    """
  end
end
