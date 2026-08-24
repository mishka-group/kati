defmodule Kati.Screens.DropStates do
  @moduledoc """
  Screen 148 — Drop states, a reference sheet pushed under Settings.

  Built to `test/design/reference/148.html` in screen 27's own manner —
  27 drew the four states nobody designs, this draws the five `TrackedTitle`
  can be in, three media wide, so the parallel between Show, Book and Album
  is *visible* rather than *asserted*. `Kati.Media.TrackedTitle.status` is
  `:active | :paused | :gone_cold | :dropped | :finished`; this sheet is
  what each of those five looks like, once per medium, side by side.

  ## The one distinction the whole board exists to draw

  Paused and Dropped are things a person decided. Gone cold is something
  Kati noticed. The board draws that difference rather than stating it once
  and hoping it sticks:

    * **Weight.** Every Gone cold row is 12.5pt medium in `Palette.sub()`
      where every other band is 13pt semibold in `Palette.ink()` — a
      suggestion sits one step back from a status, in the same way
      `Kati.UI.SettingsList.body_muted/1` sits one step back from
      `body/2` for a control that is off rather than disabled. No opacity
      prop is involved and none is needed; the drawing gets there with a
      smaller size, a lighter weight and a paler colour, all three of which
      are ordinary `Text` props.
    * **The footnote under it says so in words.** *"Dropping from here reads
      as accepting Kati's suggestion — and there is a 'No, still on it'
      answer, which the app previously had nowhere to give."* Gone cold is
      the one state on this sheet that offers a way to be told it was wrong.

  ## Which eyebrow gets which dash, and it is not the usual rule

  `Kati.UI.eyebrow/2`'s accent dash means *new or now* everywhere else in
  the app; the grey one (`SettingsList.eyebrow_muted/1`) means *a footnote to
  the section above it*. Neither reading fits this board on its own — Active
  is not "new," Dropped is not "now" — so the dashes here are taken as drawn
  rather than re-derived from a rule they were not written under: Active,
  Dropped and Transitions carry the accent dash (`#E8823C`); Paused, Gone
  cold and Finished carry the grey one (`#C4BDB3`). Three of five states and
  the summary band get the louder mark; the two that are consequences of
  time passing — a pause holding, a title finishing — get the quieter one.

  ## Two custom rows, because neither existing one fits

  `SettingsList.row/4` is *icon tile · body · trailing control* and every
  row on this sheet is *mono medium label · value line*, with no icon and no
  trailing control at all — so this file draws its own `media_row/4` and
  `transition_row/3`, each closing with `SettingsList.hairline/1` exactly as
  `row/4` does, rather than inventing a second hairline convention.

  ## Reused rather than rebuilt

  `SettingsList.card/1` for every grouped list (the shadow and radius are
  `shadow_card_soft/0` to the pixel), `SettingsList.eyebrow_muted/1` and
  `Kati.UI.eyebrow/2` for the section labels, `SettingsList.note/2` for both
  dashed footnotes, and `Kati.UI.rich_text/1` — in the shape
  `Kati.Screens.Money.suggestion/1` already uses — for the two cream notes
  that carry bold words inside a running sentence. `SettingsList.note/2`
  takes one flat style, so the dashed footnotes' emphasis (*"Never a bare
  'dropped'"*, *percentage*) does not survive; that is the same trade every
  other `note/2` call site in the app already makes, not a new one.

  ## Album has no Finished row for a real reason, not a missing one

  The board says it plainly and this file repeats it rather than hiding it
  behind an empty cell: *"an album does not finish the way a series does. It
  goes Active → Paused → Gone cold → Dropped and back, and that is the whole
  of it."* Finished's third row reads `Deliberately none` — the word
  `Deliberately` is doing the same job here that it does in Paused's Album
  row (`Paused`, no comma, no adverb — the adverb is spent on the row that
  needs to rule something out, not the row that is just stating itself).

  ## Nothing here is read from `Kati.Media`, and for the same reason 27 reads nothing

  A sheet that draws all five states, three media wide, unconditionally,
  cannot be the result of querying one title's `status` — no row is
  simultaneously Active, Paused, Gone cold, Dropped and Finished, and a
  sheet gated on which real titles exist today would draw a different grid
  on every device rather than the reference this one screen has to stay.
  `Kati.Settings.DropStatesSample` is the specimen, typed once from the
  board, the same relationship `Kati.Settings.StatesSample` has to screen 27.

  No dock — pushed screen — so the frame closes at
  `Kati.Screens.Pushed.content_top/0`'s neighbourhood rather than at a tab
  bar, and there is no trailing disc in the header: the board's back pill is
  the only thing at 64pt, so `SettingsList.chrome/2` is called with `nil`.

  ## Nothing on this sheet is a live tap

  Every other reference sheet in this round (`Kati.Screens.States`) ends on
  one live control — screen 27's dashed tile pushes `RetiredTile`. 148 draws
  none: no button, no dashed tile, no row carries an affordance. The
  designer's own caption for this board files "Gone cold can be dismissed
  without dropping" as an *open item the board decided*, not as a control
  the board draws — that dismissal, and the resume-with-position flow the
  closing note describes, belong to board 149, *"Dropping — the sheet and
  after,"* which is a different screen. Adding a tap here to anticipate it
  would be answering a question this sheet does not ask.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Settings.DropStatesSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :drop_states, %{
      active: Sample.active(),
      paused: Sample.paused(),
      gone_cold: Sample.gone_cold(),
      gone_cold_note: Sample.gone_cold_note(),
      dropped: Sample.dropped(),
      dropped_note: Sample.dropped_note(),
      finished: Sample.finished(),
      finished_note: Sample.finished_note(),
      transitions: Sample.transitions(),
      resume_note: Sample.resume_note()
    })
  end

  @doc false
  def content(assigns) do
    s = assigns.drop_states

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil)}
        {SettingsList.title(
          "Five states, three media",
          "GONE COLD IS OBSERVED · PAUSED AND DROPPED ARE CHOSEN"
        )}
        {UI.eyebrow("Active")}
        {SettingsList.card(Kati.Screens.DropStates.media_rows(s.active, false))}
        <Spacer size={20} />
        {SettingsList.eyebrow_muted("Paused — chosen")}
        {SettingsList.card(Kati.Screens.DropStates.media_rows(s.paused, false))}
        <Spacer size={20} />
        {SettingsList.eyebrow_muted("Gone cold — observed, a suggestion not a status")}
        {SettingsList.card(Kati.Screens.DropStates.media_rows(s.gone_cold, true))}
        <Spacer size={11} />
        {Kati.Screens.DropStates.gone_cold_note(s.gone_cold_note)}
        <Spacer size={20} />
        {UI.eyebrow("Dropped — chosen, always with a position")}
        {SettingsList.card(Kati.Screens.DropStates.media_rows(s.dropped, false))}
        <Spacer size={11} />
        {SettingsList.note("info", s.dropped_note)}
        <Spacer size={20} />
        {SettingsList.eyebrow_muted("Finished")}
        {SettingsList.card(Kati.Screens.DropStates.media_rows(s.finished, false))}
        <Spacer size={11} />
        {SettingsList.note("info", s.finished_note)}
        <Spacer size={20} />
        {UI.eyebrow("Transitions — and what each captures")}
        {SettingsList.card(Kati.Screens.DropStates.transition_rows(s.transitions))}
        <Spacer size={14} />
        {Kati.Screens.DropStates.resume_note(s.resume_note)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  One band's three rows — Show, Book, Album — as the card's children.

  `light?` is the Gone cold band's whole distinction: everywhere else a row
  is 13pt semibold ink, and Gone cold is 12.5pt medium `Palette.sub()`. The
  list is where that switch is made once, rather than at each of the fifteen
  call sites that draw a row.
  """
  @spec media_rows([{String.t(), String.t()}], boolean()) :: [term()]
  def media_rows(items, light?) do
    count = length(items)

    items
    |> Enum.with_index(1)
    |> Enum.map(fn {{label, value}, i} ->
      Kati.Screens.DropStates.media_row(label, value, light?, i < count)
    end)
  end

  @doc """
  One row: a fixed 42pt mono medium label, then the state's own line.

  `Column min_width={42}` rather than a `Box width`, the same fixed-gutter
  shape `Kati.Screens.Day.all_day_row/1` uses for its `ALL` / `DAY` column —
  a hugging container with a floor, so `Album` and `Show` share one baseline
  without either one being clipped. The value carries `weight={1.0}` and no
  `text_align`, per the rule that a `Text` given `text_align` fills its Row
  and starves everything beside it; this one only needs the *width*, not
  centring, so `weight` alone is correct and safer.
  """
  @spec media_row(String.t(), String.t(), boolean(), boolean()) :: term()
  def media_row(label, value, light?, rule?) do
    {size, weight, color} =
      if light?, do: {12.5, "medium", Palette.sub()}, else: {13, "semibold", Palette.ink()}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        <Column min_width={42}>
          <Text
            text={String.upcase(label)}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.1}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Text
          text={value}
          text_size={size}
          font_weight={weight}
          text_color={color}
          max_lines={1}
          weight={1.0}
        />
      </Row>
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The transitions card's six rows, as the card's children.

  Each row is `from → to` at a fixed 62pt gutter apiece — wide enough for
  `Gone cold`, the longest state name on the sheet — then what the move
  captures, weighted to take the rest of the row.
  """
  @spec transition_rows([{String.t(), String.t(), String.t()}]) :: [term()]
  def transition_rows(rows) do
    count = length(rows)

    rows
    |> Enum.with_index(1)
    |> Enum.map(fn {{from, to, capture}, i} ->
      Kati.Screens.DropStates.transition_row(from, to, capture, i < count)
    end)
  end

  @doc """
  One transition: two fixed-width state names either side of an arrow, then
  what the move writes down.

  `from` is `Palette.ink_soft()`, `to` is `Palette.ink()` — the destination
  reads a shade darker than the state being left, the same weight the
  drawing gives an outcome over a starting point.
  """
  @spec transition_row(String.t(), String.t(), String.t(), boolean()) :: term()
  def transition_row(from, to, capture, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        <Column min_width={62}>
          <Text
            font_family="mono"
            text={from}
            text_size={10.5}
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
        </Column>
        <Spacer size={9} />
        {Kati.UI.symbol("arrow_forward", size: 14, color: Palette.rail_idle())}
        <Spacer size={9} />
        <Column min_width={62}>
          <Text
            font_family="mono"
            text={to}
            text_size={10.5}
            text_color={Palette.ink()}
            max_lines={1}
          />
        </Column>
        <Spacer size={9} />
        <Text
          text={capture}
          text_size={11}
          line_height={1.45}
          text_color={Palette.sub()}
          weight={1.0}
        />
      </Row>
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  Gone cold's footnote: `help` on cream, three bold runs inside one sentence.

  `Kati.Screens.Money.suggestion/1`'s shape exactly — `Palette.cream()`
  ground, `Kati.UI.rich_text/1` for the paragraph, because a plain `Text`
  cannot mix weights and `SettingsList.note/2`'s frame is the dashed one,
  not this filled one.
  """
  @spec gone_cold_note(map()) :: term()
  def gone_cold_note(n) do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]
    strong = [font_weight: "semibold", text_color: Palette.ink(), text_size: 12.5]

    runs = [
      {n.lead, body},
      {n.bold_1, strong},
      {n.mid_1, body},
      {n.bold_2, strong},
      {n.mid_2, body},
      {n.bold_3, strong},
      {n.tail, body}
    ]

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("help", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {Kati.UI.rich_text(runs)}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc """
  The closing note: `replay` on cream, the two bold runs of `resume_note/0`.

  Same shape as `gone_cold_note/1` — the board draws this one and Gone
  cold's footnote in the identical `#FBF1DE` frame, so the same builder
  logic applies, just with two runs instead of three.
  """
  @spec resume_note(map()) :: term()
  def resume_note(n) do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]
    strong = [font_weight: "semibold", text_color: Palette.ink(), text_size: 12.5]

    runs = [
      {n.lead, body},
      {n.bold_1, strong},
      {n.mid, body},
      {n.bold_2, strong},
      {n.tail, body}
    ]

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("replay", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {Kati.UI.rich_text(runs)}
        </Column>
      </Row>
    </Column>
    """
  end
end
