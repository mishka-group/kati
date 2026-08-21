defmodule Kati.Screens.QuickAdd do
  @moduledoc """
  Screen 18 — Quick add.

  Built to `.scratch/design/screens/18.html`: the `64px 21px 40px` frame with
  no dock at the bottom, a focused field carrying a 2px ink ring, the cream
  card of what Kati understood, the six things the sentence could be filed as,
  and a 52pt commit row with a microphone beside it.

  ## The three ideas the drawing is making

    1. **One field for the whole app.** The chip row is not a filter — it is
       every section Kati keeps, and the sentence becomes whichever one you
       pick. That is why `Title`, `Habit` and `Expense` sit next to `Event`.
    2. **The parse is shown before it is committed.** Tokens are tinted where
       they were typed, not summarised underneath, so the user can see what was
       understood while the caret is still in the line.
    3. **The clash arrives before the save, not after.** The `info` row is
       inside the cream card, above the button, and it ends in a question.

  ## Not `Kati.Screens.Pushed`

  The drawing dismisses itself with a 44pt `close` disc in its own header. The
  pushed chrome would float a second back affordance over the title, so this
  screen owns its `mount/3` and `render/1` — the same choice screen 06 made,
  and for the same reason. #45 turns both into native sheets later.

  ## Where the drawing wraps

  Two places wrap in the browser and cannot wrap here: the typed sentence and
  the fact chips. Both are declared as lines in `Kati.Screens.QuickAdd.Sample`
  at the break the drawing shows, because `Row` does not wrap and no geometry
  comes back from `render/1`.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaCloseButton
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Screens.QuickAdd.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    {:ok, Mob.Socket.assign(socket, :draft, Sample.draft())}
  end

  def render(assigns) do
    draft = assigns.draft

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.QuickAdd.header()}
          {Kati.Screens.QuickAdd.field(draft)}
          {UI.eyebrow("Kati read that as")}
          {Kati.Screens.QuickAdd.parsed(draft)}
          {UI.eyebrow("Or file it as")}
          {Kati.Screens.QuickAdd.kinds(draft)}
          {Kati.Screens.QuickAdd.actions(draft)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text="Quick add"
          text_size={26}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.QuickAdd.close_disc()}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 44pt disc that dismisses the sheet — `Kati.Components.MishkaCloseButton`.

  This screen has no back pill precisely because the drawing gives it this
  disc instead (see the moduledoc), so the one control that closes it is worth
  spelling the way the library spells closing. The close button is a thin
  preset over `Kati.Components.MishkaActionIcon` — ✕ and `shape: :circle` baked
  in — and children override the ✕, so the glyph stays the Material Symbol
  `close` at the drawn 21 rather than the component's own character.

  It could not be adopted before this round for one missing prop: `shadow`.
  The drawing's disc is `Kati.Theme.shadow_button()` floating over paper, and
  `variant: :filled` alone would have flattened it into a #FBFAF8 patch.

  **The pixels are the same node**: `<Box width={44} height={44}
  align={:center} corner_radius={22.0} background shadow on_tap>` is what this
  markup said by hand, `size / 2` being the 22 it wrote out. The port's `<Row>`
  around the children hugs the single glyph and is centred by the same Box, so
  nothing measures differently.
  """
  def close_disc do
    MishkaCloseButton.close_button(
      [
        size: 44,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), :close}
      ],
      [Kati.UI.symbol("close", size: 21)]
    )
  end

  # `0 0 0 2px #1A1917` is a ring, not a shadow. A shadow at zero blur and zero
  # offset draws nothing under the card's own elevation, so it is a 2px border
  # here and the drawing's second layer stays a shadow.
  @doc false
  def field(draft) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={24}
        border_width={2}
        border_color={Palette.ink()}
        shadow="0 10 22 -14 #991A1917"
        padding_left={18}
        padding_right={18}
        padding_top={16}
        padding_bottom={16}
      >
        {Enum.map(draft.query, fn line -> Kati.Screens.QuickAdd.query_line(line) end)}
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def query_line(line) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(line.pieces, fn piece -> Kati.Screens.QuickAdd.piece(piece) end)}
      {Kati.Screens.QuickAdd.caret(line.caret)}
    </Row>
    """
  end

  @doc false
  def piece({:plain, text, gap}) do
    ~MOB"""
    <Row align="center">
      <Spacer size={gap} />
      <Text
        text={text}
        text_size={15.5}
        font_weight="medium"
        line_height={1.5}
        text_color={:on_surface}
        max_lines={1}
      />
    </Row>
    """
  end

  def piece({:token, text, gap}), do: token(text, gap, Palette.hairline_soft(), Palette.ink())

  def piece({:accent, text, gap}),
    do: token(text, gap, Palette.accent_wash(), Palette.gold_text())

  @doc false
  def token(text, gap, background, color) do
    ~MOB"""
    <Row align="center">
      <Spacer size={gap} />
      <Row
        background={background}
        corner_radius={5}
        padding_left={4}
        padding_right={4}
        padding_top={1}
        padding_bottom={1}
        align="center"
      >
        <Text
          text={text}
          text_size={15.5}
          font_weight="medium"
          line_height={1.5}
          text_color={color}
          max_lines={1}
        />
      </Row>
    </Row>
    """
  end

  @doc false
  def caret(false), do: ~MOB"<Spacer size={0} />"

  def caret(true) do
    ~MOB"""
    <Row align="center">
      <Spacer size={2} />
      <Box width={2} height={18} background={Palette.accent()} />
    </Row>
    """
  end

  @doc false
  def parsed(draft) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.QuickAdd.kind_tile()}
          <Spacer size={10} />
          <Column weight={1.0}>
            <Text
              text={draft.title}
              text_size={16}
              font_weight="bold"
              letter_spacing={-0.02}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={3} />
            <Text
              text={draft.kind}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.cream_meta()}
              max_lines={1}
            />
          </Column>
        </Row>
        <Spacer size={16} />
        {draft.facts
         |> Enum.map(fn row -> Kati.Screens.QuickAdd.fact_row(row) end)
         |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
        <Spacer size={14} />
        {Kati.Screens.QuickAdd.rule()}
        <Spacer size={14} />
        {Kati.Screens.QuickAdd.clash(draft)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The ink tile that says what Kati filed the sentence as —
  `Kati.Components.MishkaThemeIcon`.

  "A themed container around exactly one glyph" is that component's own
  description of itself and it is exactly this: 34pt, radius 11, ink fill, one
  Material Symbol. It is not tappable and carries no shadow, so unlike the
  header disc it needed nothing new to be adopted — `size` and `radius` have
  always taken a raw dp number, and `variant: :filled` paints `color` as the
  fill.

  **The node is identical, prop for prop.** The port builds a bare
  `%{type: :box}` with `%{width: 34, height: 34, align: :center,
  corner_radius: 11, background: <ink>}` and the children it was handed — no
  wrapper Row, because only an `id` (for test tags) makes it wrap, and this
  has none. That is the same five props and the same single child the markup
  wrote out here.

  `icon_color` is not passed: the glyph is a child, and children are placed as
  given, so `Kati.UI.symbol/2` still supplies the drawn 18 in the drawn
  #FBFAF8. The component's own luminance guess never runs.
  """
  def kind_tile do
    MishkaThemeIcon.theme_icon(
      %{size: 34, radius: 11, variant: :filled, color: Palette.ink_fill()},
      [UI.symbol("event", size: 18, color: Palette.on_ink())]
    )
  end

  @doc "The drawing's 7pt flex gap, used between chips and between chip rows."
  def gap, do: ~MOB"<Spacer size={7} />"

  # The cream card's `1px solid rgba(176,154,114,.3)` divider, drawn by
  # `MishkaSeparator` — with `render: :box`, not the component's `:divider`
  # default.
  #
  # `:divider` is not the Box that was written inline here. The comment that
  # stood in this spot said Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))`; Material3 actually draws
  # it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an antialiased stroke.
  # At 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so its last
  # pixel row lands at ~69% coverage and the hairline came out softer than the
  # drawing's on one row. `render: :box` is the filled rect — the original node
  # — so the line is back to a solid 1dp of 30% bronze.
  @doc false
  def rule, do: MishkaSeparator.separator(color: Palette.cream_rule(), thickness: 1, render: :box)

  @doc false
  def fact_row(chips) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {chips
       |> Enum.map(fn chip -> Kati.Screens.QuickAdd.fact(chip) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
    </Row>
    """
  end

  @doc false
  # `0xA6FFFFFF` stays a literal: the only token carrying it is `lock_ink_65`,
  # which is a lock-screen line over a photograph and does not follow the theme.
  # The cream card's raised chip is `cream_raise`, and that is 0x99FFFFFF — a
  # different colour, so taking it would move light mode. Reported, not guessed.
  def fact({icon, label}) do
    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={0xA6FFFFFF}
      padding_left={11}
      padding_right={11}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 14, color: Palette.gold_text())}
      <Spacer size={6} />
      <Text
        text={label}
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  # Three Texts rather than one, because the drawing bolds the clashing event's
  # name inside the sentence and there is no inline span on this bridge.
  @doc false
  def clash(draft) do
    {lead, subject, tail} = draft.clash

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.UI.symbol("info", size: 15, color: Palette.cream_meta())}
      <Spacer size={7} />
      <Text text={lead} text_size={11.5} text_color={Palette.cream_sub()} max_lines={1} />
      <Spacer size={4} />
      <Text
        text={subject}
        text_size={11.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text text={tail} text_size={11.5} text_color={Palette.cream_sub()} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def kinds(draft) do
    ~MOB"""
    <Column fill_width={true}>
      {draft.kinds
       |> Enum.chunk_every(3)
       |> Enum.map(fn row -> Kati.Screens.QuickAdd.kind_row(row) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def kind_row(row) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {row
       |> Enum.map(fn kind -> Kati.Screens.QuickAdd.kind(kind) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
    </Row>
    """
  end

  @doc false
  def kind({icon, label, true}) do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.ink_fill()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 16, color: Palette.on_ink())}
      <Spacer size={7} />
      <Text
        text={label}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  def kind({icon, label, false}) do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 16, color: Palette.sub())}
      <Spacer size={7} />
      <Text
        text={label}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  # The commit button is a Box with `weight`, not a Row: it has to fill the
  # line beside the 52pt microphone, and a Row would hug the label.
  @doc false
  def actions(draft) do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Box
        weight={1.0}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        shadow="0 12 24 -12 #D91A1917"
        align="center"
      >
        <Text
          text={draft.cta}
          text_size={14}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
      <Spacer size={10} />
      {Kati.Screens.QuickAdd.mic()}
    </Row>
    """
  end

  @doc """
  The 52pt microphone beside the commit button —
  `Kati.Components.MishkaActionIcon`.

  The same round icon target as `close_disc/0` and adopted for the same new
  prop: this one wears `Kati.Theme.shadow_card_soft()` rather than the button
  shadow, and without `shadow` the port could only have drawn it flat.

  It is wired to nothing, and that is the drawing's position rather than an
  omission — dictation is not built, and the export gives the microphone no
  destination. `on_tap` is simply not passed, so the port leaves the key off
  the node entirely; the disc renders exactly as the hand-rolled `Box` did,
  which also carried no handler.

  **The pixels are the same node**: `<Box width={52} height={52}
  align={:center} corner_radius={26.0} background shadow>` plus the port's
  `<Row>` around the glyph, which hugs it and is centred by that Box.
  """
  def mic do
    MishkaActionIcon.action_icon(
      [
        size: 52,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_card_soft()
      ],
      [UI.symbol("mic", size: 21)]
    )
  end
end
