defmodule Kati.Screens.ImportRecognised do
  @moduledoc """
  Screen 141 — Import, source recognised, pushed under Settings.

  Built to `.scratch/design/incoming/141.html`. One step earlier than screen
  37: the file has been read and a source has been guessed, but nobody has
  looked at the mapping yet. The drawing's argument is proportion — a person
  who has not asked to see nine columns matched one by one should not be
  handed a table before they have even confirmed the guess is right, so the
  mapping opens collapsed to one line and the guess itself is offered a
  correction before anything else on the screen.

  ## The board draws the mapping twice, and so does the screen

  Board 141 lays the mapping card out twice, each under its own mono label —
  `Mapping — collapsed` after a grey dash, `Mapping — expanded` after an
  orange one — and its caption says why in one line: *expanded below so both
  states are comparable*. That is the same sentence, and the same two dash
  colours, that a dozen screens in this app already answer by drawing every
  state one under the other with a labelled divider between them
  (`Kati.Screens.EpisodeRatings` draws its episode list rated and unrated,
  `Kati.Screens.BackupStates` its card never-backed-up and stale). Grey is
  `Kati.UI.SettingsList.eyebrow_muted/1` — a footnote to the section above it —
  and orange is `Kati.UI.eyebrow/2`, new-or-now. Both labels are copy on the
  board and both are drawn.

  An earlier build of this screen read the two frames as a *spec caption*
  rather than copy and collapsed them into one disclosure: one card, an
  `:toggle_mapping` assign, `chevron_right` swapping for `expand_more`. That
  invented a control the board does not draw and hid nine rows of copy behind
  it, which is the failure `Kati.ScreenDesignLiteralTest` exists to catch — a
  section the drawing shows, built but never mounted, with every frame still
  looking right. The board's chevron is `chevron_right`, which everywhere else
  in this app means *this row opens a page*, not *this row unfolds*.

  So `mapping_collapsed/1` draws the resting card and `mapping_expanded/1` the
  open one, both always, and the summary row's tap does what its chevron
  promises: `:check_mapping` pushes `Kati.Screens.Import`, screen 37, which is
  this same mapping with a sampled value beside every row. Screen 140 already
  pushes here; this is the next step of the same flow, not a placeholder.

  ## `What will happen` keeps its footnote grey rather than screen 37's orange

  Screen 37 opens `UI.eyebrow("What will happen")` at the accent dash — the
  primary thing on that screen, three steps in, mapping already reviewed.
  Board 141 draws the same label at `#C4BDB3`, the grey `eyebrow_muted/1`
  reserves for a section that is a footnote to the one above it. That is the
  correct dash for step 1: the counts are a preview of what the still-collapsed
  mapping will do, not the thing this screen is asking the person to look at.

  ## The star the font turned out to have

  Board 141 draws ★ twice — `converts 10pt → 5★` under *My Rating*, and
  `10pt → 5★` inside the `auto_awesome` banner. Both are the character, in
  one `Text` each, and that contradicts screens 08, 15, 33 and 37, which all
  splice a Material Symbols `star` glyph into a `Row` because *Plus Jakarta
  Sans carries no U+2605*. **That is no longer true of the font this app
  ships**, and it is worth writing down where it can be re-checked:

      android/app/src/main/res/font/kati_sans_400.ttf
        cmap: U+2605 → glyph 981
        glyf: 1 contour, 10 on-curve points, bbox (36,-12)-(845,757)
              (191,-12) (286,281) (36,463) (345,463) (440,757)
              (536,463) (845,463) (595,281) (691,-12) (440,169)
        hmtx: advance 882/1000 upem

  Ten points alternating outer and inner radius about (440,372) is a
  five-pointed star, and it is in all five weights (400-800) with the advance
  scaling 882→938. `kati_mono` genuinely has no U+2605, which is why the
  mapping row's mono *column* is not where this note lives.

  The splice was never free, and this board is where the cost shows. A
  `Row` of [Text, glyph, Text] cannot wrap, so the banner's sentence — three
  lines at the card's width — could not have the mark at all: an earlier build
  of this screen wrote `5 stars` there and said the literal was unreachable.
  With the character it is one `Text`, it wraps, and it says what the board
  says. The mapping row's note gets the same treatment for consistency within
  the screen rather than necessity.

  **This is deliberately not a change to screens 08, 15, 33 or 37.** Those
  splice a *rating* — five glyphs in a row at 30px, one of them outlined for a
  half — which is a different problem from one mark inside a line of copy, and
  unifying them is a change that wants a device capture behind it rather than
  a font table. `Kati.Screens.ShelfFilters` already ships `4★ and up` as the
  character, so this screen is the second, not the first.

  ## `Not Goodreads? Change` pops the screen, honestly

  There is no source-picker screen or resource this can hand the guess back
  to — the note under `Kati.Import.Sample`'s moduledoc is still true, there is
  no reader and no job. `Mob.Socket.pop_screen/1` is the one real thing this
  tap can honestly do: return to whatever screen offered the file in the
  first place, which is where picking a different source actually happens.
  It is a genuine navigation change, not a placeholder dressed as one.

  No dock on a pushed screen, so the frame's bottom inset is 40 rather than
  132, same as screen 37.

  ## Why this screen is still on `Kati.Import.Sample`

  Same case screen 37 already makes in full: no reader and no job resource, so
  a screen drawn mid-flow has nothing behind it to read the file, the guess or
  the nine-column mapping from. `Kati.Import.Sample.recognised/0` is a second
  job beside `job/0` in the same module, not a new one, because both are the
  same stand-in for the same not-yet-real reader — and `recognised_columns/0`
  is what both mapping frames on this screen draw, so the two states cannot
  drift apart into two hand-written tables.

  ## Audited

  Two taps are drawn and both reach a handler that navigates: `Check the
  mapping` pushes screen 37, and `Not Goodreads? Change` pops back to whoever
  offered the file. Nothing else on the board is a control — the mapping
  table's rows describe a match, they do not offer one, and the three outcome
  cards are a count, not a button.

  **What neither tap can do yet is change the mapping.** The board's summary
  line ends `still editable` and screen 37 shows the same nine rows without a
  control on any of them, because there is no job resource to write a
  correction into: `Kati.Import.Sample` is a literal, so a person who decides
  *Publisher* should not be skipped has nowhere to say so. That is the same
  missing resource screen 37's own moduledoc names, and it is the one promise
  on this board the app does not keep.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Import.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :job, Sample.recognised())
  end

  @doc false
  def content(assigns) do
    job = assigns.job

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.ImportRecognised.header(job)}
        {Kati.Screens.ImportRecognised.title(job)}
        {Kati.Screens.ImportRecognised.steps(job)}
        {Kati.Screens.ImportRecognised.file_card(job)}
        {Kati.Screens.ImportRecognised.matched_note()}
        {UI.SettingsList.eyebrow_muted("Mapping — collapsed")}
        {Kati.Screens.ImportRecognised.mapping_collapsed(job)}
        {UI.eyebrow("Mapping — expanded")}
        {Kati.Screens.ImportRecognised.mapping_expanded(job)}
        {UI.SettingsList.eyebrow_muted("What will happen")}
        {Kati.Screens.ImportRecognised.outcome(job)}
      </Column>
    </Scroll>
    """
  end

  # Same 44pt reservation Import.header/1 draws for the same reason: the
  # pushed macro floats the back pill over this row, so the row only owns the
  # ink pill on the right.
  @doc false
  def header(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Row
          height={38}
          corner_radius={19}
          background={Palette.ink_fill()}
          padding_left={16}
          padding_right={16}
          align="center"
        >
          <Text
            text={job.action}
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={job.source}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={6} />
      <Text
        text={job.step_label}
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
  The five-bar meter, three filled — `job.progress`'s own booleans, drawn
  literally rather than derived from a step/steps pair.

  It is worth saying plainly: the board draws this at three of five while
  `job.step_label` reads `STEP 1 OF 4`, and the two numbers do not agree with
  each other. That is the drawing's own inconsistency, not a transcription
  slip made building this screen — both are reproduced exactly as drawn
  rather than one being quietly changed to match the other.
  """
  def steps(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {job.progress
         |> Enum.map(fn done? -> Kati.Screens.ImportRecognised.step_bar(done?) end)
         |> Enum.intersperse(Kati.Screens.ImportRecognised.step_gap())}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()

    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc """
  The file card, extended with the source guess and its correction.

  Radius 22 and 17pt padding, not screen 37's 20/15 — a different card the
  board draws at its own numbers, not the same recipe copied wrong. The
  hairline and the `Read as a … export` row beneath it are this board's own
  addition: nothing screen 37 draws has a guess to correct.
  """
  def file_card(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.ImportRecognised.file_tile()}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text
              text={job.file}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={job.shape}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          <Spacer size={13} />
          {UI.symbol("check_circle", size: 20, color: Palette.green(), fill: true)}
        </Row>
        <Spacer size={14} />
        {MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)}
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          <Column weight={1.0}>
            {Kati.Screens.ImportRecognised.source_line(job.source)}
          </Column>
          <Spacer size={11} />
          {Kati.Screens.ImportRecognised.change_pill(job.source)}
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc "The 38x38 paper tile the file card leads with — same recipe as screen 37's `file_tile/0`."
  def file_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 38, radius: 11},
      [UI.symbol("description", size: 20, color: Palette.ink_soft())]
    )
  end

  @doc """
  `Read as a **Goodreads** export`, one bold run inside a running line.

  `Kati.UI.rich_text/1`: the bridge has no per-run styling, so the whole line
  takes one style — the regular run's, marked `base: true` because at this
  length editing the source name could otherwise flip which run is longest.
  """
  def source_line(source) do
    base = [text_size: 12.5, text_color: Palette.ink_soft()]

    UI.rich_text([
      {"Read as a ", [base: true] ++ base},
      {source, [font_weight: "semibold", text_color: :on_surface]},
      {" export", base}
    ])
  end

  @doc "The `Not <source>? Change` pill — screen `account.ex`'s `pill/1` recipe, with a real tap."
  def change_pill(source) do
    MishkaPill.pill(
      label: "Not #{source}? Change",
      background: Palette.paper(),
      color: :on_surface,
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center,
      max_lines: 1,
      on_tap: :change_source
    )
  end

  @doc """
  The `auto_awesome` note, cream card, one wrapping paragraph.

  `Kati.UI.rich_text/1` again, for the same reason `source_line/1` uses it: the
  bridge has no per-run styling, so a paragraph that must wrap is one `Text`.
  That is exactly why the `5★` in it is the character rather than a spliced
  glyph — see "The star the font turned out to have" in this module's doc.
  """
  def matched_note do
    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
        <Row fill_width={true} align="top">
          {UI.symbol("auto_awesome", size: 18, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            {Kati.Screens.ImportRecognised.note()}
          </Column>
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def note do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]

    UI.rich_text([
      {"Kati matched ", [base: true] ++ body},
      {"7 of 9 columns", :semibold},
      {" and set the conversions: ", body},
      {"10pt → 5★", :semibold},
      {", and dates read as ", body},
      {"YYYY/MM/DD", :semibold},
      {". Two columns are skipped.", body}
    ])
  end

  @doc """
  The mapping at rest: one row, the counts, and the chevron that opens it.

  `rule: false` because it is the only row in its card — the hairline in
  `Kati.UI.SettingsList.row/4` separates a row from the next one, and there is
  no next one. The sub-line is built from `job.matched` and `job.skipped`
  rather than written out, so the board's `7 matched · 2 skipped` and the nine
  rows `mapping_expanded/1` draws cannot disagree with each other.
  """
  def mapping_collapsed(job) do
    summary_row =
      SettingsList.row(
        SettingsList.icon_tile("checklist"),
        SettingsList.body(
          "Check the mapping",
          "#{job.matched} matched · #{job.skipped} skipped · still editable"
        ),
        SettingsList.chevron(),
        rule: false,
        on_tap: {self(), :check_mapping}
      )

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([summary_row])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The mapping opened: every column in the file against the field it will write.

  The board draws no summary row above this frame and none is added — the two
  frames are the same control at rest and open, and a header repeated in both
  would read as two cards rather than two states of one. `rule?` is false on
  the last row for `mapping_collapsed/1`'s reason.
  """
  def mapping_expanded(job) do
    last = length(job.columns) - 1

    table_rows =
      job.columns
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.ImportRecognised.map_row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(table_rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def map_row(row, rule?) do
    field_color = if row.skipped?, do: Palette.tertiary(), else: Palette.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        <Column weight={1.0}>
          <Text
            text={row.column}
            font_family="mono"
            text_size={11}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.ImportRecognised.map_note(row.note)}
        </Column>
        <Spacer size={11} />
        {UI.symbol(row.icon, size: 15, color: Palette.rail_idle())}
        <Spacer size={11} />
        <Column width={96}>
          <Text
            text={row.field}
            text_size={12.5}
            font_weight="semibold"
            text_color={field_color}
            text_align="right"
            max_lines={1}
          />
        </Column>
      </Row>
      {Kati.Screens.ImportRecognised.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def map_note(nil), do: ~MOB"<Spacer size={0} />"

  def map_note(note) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={4} />
      {Kati.Screens.ImportRecognised.note_line(note)}
    </Column>
    """
  end

  @doc """
  A mapping row's own note — `converts 10pt → 5★`, `to-read → Wishlist`,
  `skipped` — at `Palette.eyebrow/0`, the drawing's `#A0998F` and not
  screen 37's `tertiary`.

  One `Text`, star and all. See "The star the font turned out to have" in this
  module's doc for why this does not split at the ★ the way screen 37's
  `star_text/3` does.
  """
  def note_line(text) do
    ~MOB"<Text text={text} text_size={10} text_color={Palette.eyebrow()} max_lines={1} />"
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two mapping rows — `render: :box`
  for the reason screen 37's own `hairline/1` gives in full: the default
  `:divider` primitive antialiases a 1dp rule unevenly at this device's pixel
  ratio, and `render: :box` draws a filled rect instead, every row at the
  drawing's flat 7% ink.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  The three outcome cards — `job.outcome`, reused whole from
  `Kati.Import.Sample.outcome/0`, at this board's own type: mono, `medium`
  weight, 22/9.5pt, not screen 37's sans `extrabold` at 22/10.
  """
  def outcome(job) do
    ~MOB"""
    <Row fill_width={true} align="top">
      {job.outcome
       |> Enum.map(fn card -> Kati.Screens.ImportRecognised.outcome_card(card) end)
       |> Enum.intersperse(Kati.Screens.ImportRecognised.outcome_gap())}
    </Row>
    """
  end

  @doc false
  def outcome_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def outcome_card(card) do
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
          text_color={card.color}
          text_align="center"
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

  @doc false
  @impl true
  def handle_tap(:check_mapping, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Import)}
  end

  def handle_tap(:change_source, socket) do
    {:noreply, Mob.Socket.pop_screen(socket)}
  end
end
