defmodule Kati.Screens.ShelfLarge do
  @moduledoc """
  Board 147 — selection and filters at 235% Dynamic Type, a reference sheet
  pushed under Library.

  Two hard cases, not one screen re-typeset. Board 146 draws the Library
  shelf's selection mode at rest and mid-flow — a header bar with a live
  count and a stack of bulk actions — and board 145 draws the shelf's sort
  and filter sheet, already built as `Kati.Screens.ShelfFilters`. Neither
  board answers what either looks like at the largest text size Android
  offers, and the brief calls out two spots where the answer is not obvious:
  a header whose one job is a number that must stay readable, and a filter
  state whose whole point is naming which chip to blame. This file draws
  both, the way screen 91 draws search's hard case and screen 133 draws
  backup's — a specimen to be checked by looking, not a screen a user reaches
  by tapping anything.

  Board 146 is itself unbuilt (`test/design/reference/README.md` still
  lists it `queued`), so unlike `Kati.Screens.SearchLarge`, which can lean on
  `Kati.Screens.Search` for chrome and `Kati.Search.chip_labels/0` for data,
  this file has no sibling selection-mode module to borrow from. Every
  literal below is typed from board 147 itself — the same choice
  `Kati.Screens.BackupLarge`'s moduledoc defends for its own board: a
  specimen, not a stand-in for a screen that is nearly ready. The zero-result
  card is new content besides — 145's own board never draws it, for the
  reason its own caption gives: *at this size it is a whole board, not a
  band*.

  ## One number, one word, and where else they appear

  `@selected_count` is 4 and `@chip_label` is `"Comedy"` — the two facts the
  board draws, typed once so `selection_title/0` and the header both read `4
  selected`, and so `drop_label/0` and `empty_reason/0` both name the same
  chip rather than risking a header that says one count and a body that
  implies another. It is the same discipline `Kati.Screens.SearchLarge`
  applies to its Screen chip and its eyebrow: the number lives in one place
  and every reader of it reads that place.

  ## Chrome caps, content grows — fence K-29, the selection-shaped instance

  `Kati.Screens.Calendar.day_strip/1`'s rule and `Kati.Screens.SearchLarge`'s
  moduledoc both give this the same way, and this board draws as clean a
  split as either:

    * **Content grows.** `4 selected` carries no `max_lines` and no cap — the
      board's own caption names it as the one thing this bar exists to say,
      so it is the one thing here guaranteed never to clip. The zero-result
      card's heading, its reason, and both footnotes are the same: no fixed
      height above them, nothing capping how many lines they take.
    * **Chrome whose size carries structure caps instead.** The close glyph,
      the three 56pt action rows and the 56pt `Drop the Comedy chip` pill are
      all fixed-height shapes the board itself calls out — *"the close glyph
      caps at 26px because it is chrome whose size carries structure"* — so
      each is wrapped in `max_font_scale={cap/0}`, which is 1.0 for the same
      reason it is 1.0 on 91: every `sp` on this page is already the
      drawing's 235% figure, typed out, and a device genuinely running at
      235% would otherwise apply the factor a second time.

  `max_font_scale` reaches any node — `MobBridge.kt`'s `RenderNode` checks it
  before dispatching to a node's own renderer, "so it needs no cooperation
  from any node type" — which is what lets the close glyph sit capped inside
  the very row whose count sits beside it uncapped: a `Box` around the one
  glyph, not around the row.

  ## The header row: one capped child beside one uncapped one

  `selection_header/0` is a `Row` with two children — a capped `Box` holding
  the close glyph, then the count `Text` at `weight={1.0}` — rather than one
  `max_font_scale` on the row itself, which would have capped the count along
  with the glyph and contradicted the one thing the caption insists on.
  `weight={1.0}` on the `Text` directly, the way screen 91's `action/0` gives
  its `Open` label the row's leftover space: a wrapping `Column` would do the
  same job with a node this file does not need.

  ## The Drop pill centres its own label

  A single child in a full-width `Row` with `text_align="center"` is safe
  here specifically because it IS the only child — the hard rule against
  `text_align` eating a row is about a `Text` with weighted siblings
  measuring zero, and this pill has none. `Kati.Screens.HealthEmptyStates`'s
  centred paragraphs are the same shape of call for the same reason.

  ## Two bold words, and the one place the loss cannot be worked around

  `Comedy` and `which chip` are `<strong>` spans in the board's two
  paragraphs, and `Kati.UI.rich_text/1` is the answer screens 14, 17, 23, 33
  and 91 already give: the runs go in typed, `MobText` takes one `fontWeight`
  for the whole string, and the emphasis is silently dropped rather than the
  sentence being split across a `Row` of runs that cannot wrap. `empty_reason/0`
  and `empty_note/0` both take that trade, and both mark their long run
  `base: true` so an edit to the short one — `Comedy`, six characters — can
  never flip which style the paragraph renders in.

  `never truncates` in the dashed footnote is the same kind of span, and it
  is lost a second way: `Kati.UI.SettingsList.note/2` takes a plain `text`,
  not runs, because its own `note_text/1` is private and pinned to one style.
  There is no rich-text path into it at all. Hand-rolling a second dashed
  footnote just to keep three bold words would be inventing a component that
  already exists for the reason the hard rule gives, so `selection_note/0`
  calls it as-is and the words survive with their emphasis gone — the same
  frame `note/2`'s own doc already trades a dashed border for a solid one on,
  recorded there rather than restated here.

  ## Nothing here reads a store, and nothing here taps

  Every value below is typed, for the reason the moduledoc's second
  paragraph gives: board 146 is unbuilt, so there is no live selection state
  and no `Kati.Library` count behind this frame, only the board's own four
  and its own Comedy. The three action rows, the close glyph and the Drop
  pill read as controls because that is what the board draws, not because
  any of them is wired — a tap that actually removed four titles or dropped
  a real chip would need the shelf this specimen has none of.
  `Kati.Screens.Pushed` defines no `handle_tap/2` on purpose, so none of them
  reports a dead tag.

  The pill says **Library**, not Settings: both boards this file draws from
  are the Library shelf's own escalations — 145 already ships as
  `Kati.Screens.ShelfFilters`, reached from the Library tabs — so the pill
  names where the *screen* came from, the same call `Kati.Screens.SearchLarge`
  makes for Home and `Kati.Screens.WeightStates` makes for Health.

  No dock on a pushed screen, so the frame closes at 40 rather than 132.
  """

  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The two facts the board draws — see "One number, one word" above. Typed
  # rather than read from a store: board 146 does not exist yet, so there is
  # no live selection and no real shelf for a chip to empty.
  @selected_count 4
  @chip_label "Comedy"

  @doc """
  The sheet, top to bottom: the header-bar card and its footnote, then the
  zero-result card and its footnote.
  """
  @spec content(map()) :: map()
  def content(_assigns) do
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
        {UI.eyebrow("The header bar — the hard case")}
        {Kati.Screens.ShelfLarge.selection_card()}
        <Spacer size={14} />
        {Kati.Screens.ShelfLarge.selection_note()}
        <Spacer size={24} />
        {SettingsList.eyebrow_muted("A chip that would empty the shelf")}
        {Kati.Screens.ShelfLarge.empty_card()}
        <Spacer size={14} />
        {Kati.Screens.ShelfLarge.empty_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The ceiling on how far chrome may grow, as a `fontScale`.

  1.0 — every `sp` on this screen is already the drawing's 235% size, so this
  reads as "do not scale this twice" rather than "do not scale this at all".
  See the moduledoc for which nodes carry it and which deliberately do not.
  """
  @spec cap() :: float()
  def cap, do: 1.0

  @doc "The header bar's own text: the live count, the one thing it must never lose."
  @spec selection_title() :: String.t()
  def selection_title, do: "#{@selected_count} selected"

  @doc "The chip a zero-result filter names. Shared by the reason and the drop pill."
  @spec chip_label() :: String.t()
  def chip_label, do: @chip_label

  @doc "The drop pill's own label, built from the same chip the reason names."
  @spec drop_label() :: String.t()
  def drop_label, do: "Drop the #{@chip_label} chip"

  @doc "The header-bar card: the count row, then the three bulk actions."
  @spec selection_card() :: map()
  def selection_card do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={18}
    >
      {Kati.Screens.ShelfLarge.selection_header()}
      <Spacer size={16} />
      {Kati.Screens.ShelfLarge.selection_actions()}
    </Column>
    """
  end

  @doc """
  The close glyph and the live count, one capped and one not.

  See the moduledoc's "header row" section for why this is two children with
  one `max_font_scale`, rather than one `max_font_scale` on the row.
  """
  @spec selection_header() :: map()
  def selection_header do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Box max_font_scale={Kati.Screens.ShelfLarge.cap()}>
        {UI.symbol("close", size: 26, color: Palette.ink())}
      </Box>
      <Spacer size={14} />
      <Text
        text={Kati.Screens.ShelfLarge.selection_title()}
        text_size={24}
        font_weight="bold"
        letter_spacing={-0.025}
        text_color={:on_surface}
        weight={1.0}
      />
    </Row>
    """
  end

  @doc "The three bulk actions, stacked as full-width rows and capped as one subtree."
  @spec selection_actions() :: map()
  def selection_actions do
    ~MOB"""
    <Column fill_width={true} max_font_scale={Kati.Screens.ShelfLarge.cap()}>
      {Kati.Screens.ShelfLarge.action_row("bookmarks", "Add to list", Palette.paper(), Palette.ink())}
      <Spacer size={10} />
      {Kati.Screens.ShelfLarge.action_row("label", "Change status", Palette.paper(), Palette.ink())}
      <Spacer size={10} />
      {Kati.Screens.ShelfLarge.action_row("delete", "Remove", Palette.red_wash(), Palette.red())}
    </Column>
    """
  end

  @doc """
  One bulk action: a 56pt full-width row, icon then label, in one colour.

  `Palette.red_wash()` under `Palette.red()` for Remove is the drawing's own
  10% tint — `rgba(180,85,60,.1)` — the same pairing
  `Kati.Screens.SeriesSettings.danger_tile/1` uses for its 30pt tile, restated
  here at the row's own full width because that tile has no full-width form.
  """
  @spec action_row(String.t(), String.t(), non_neg_integer(), non_neg_integer()) :: map()
  def action_row(icon, label, background, ink) do
    ~MOB"""
    <Row
      fill_width={true}
      height={56}
      corner_radius={20}
      background={background}
      align="center"
      padding_left={18}
      padding_right={18}
    >
      {UI.symbol(icon, size: 22, color: ink)}
      <Spacer size={12} />
      <Text text={label} text_size={18} font_weight="semibold" text_color={ink} max_lines={1} />
    </Row>
    """
  end

  @doc "The header bar's footnote, in `Kati.UI.SettingsList.note/2`'s frame. See the moduledoc for the bold word it cannot carry."
  @spec selection_note() :: map()
  def selection_note, do: SettingsList.note("info", Kati.Screens.ShelfLarge.selection_note_text())

  @doc false
  def selection_note_text do
    "The count never truncates — it is the one thing the bar exists to say. Actions leave the row " <>
      "and stack as full-width rows, and the close glyph caps at 26px because it is chrome whose " <>
      "size carries structure."
  end

  @doc "The zero-result card: the reason, then the pill that answers it."
  @spec empty_card() :: map()
  def empty_card do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={18}
    >
      {Kati.Screens.ShelfLarge.empty_header()}
      <Spacer size={16} />
      {Kati.Screens.ShelfLarge.drop_button()}
    </Column>
    """
  end

  @doc "The `search` glyph beside the heading and the reason, uncapped content throughout."
  @spec empty_header() :: map()
  def empty_header do
    ~MOB"""
    <Row fill_width={true} align="top">
      {UI.symbol("search", size: 22, color: Palette.sub())}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text="Nothing matches"
          text_size={19}
          font_weight="bold"
          line_height={1.3}
          text_color={:on_surface}
        />
        <Spacer size={9} />
        {Kati.Screens.ShelfLarge.empty_reason()}
      </Column>
    </Row>
    """
  end

  @doc """
  The reason, with the emptying chip as its own run.

  See the moduledoc for why the emphasis this records cannot render, and why
  the longer run rather than `chip_label/0`'s carries `base: true`.
  """
  @spec empty_reason() :: map()
  def empty_reason do
    tail = [
      base: true,
      text_size: 16,
      line_height: 1.55,
      text_color: Palette.sub()
    ]

    emphasis = [font_weight: "semibold", text_color: Palette.ink()]

    [
      {Kati.Screens.ShelfLarge.chip_label(), emphasis},
      {" is what emptied it — you have no comedies on this shelf.", tail}
    ]
    |> UI.rich_text()
  end

  @doc "The 56pt stadium: `Drop the Comedy chip`, centred as the row's only child. Capped — see the moduledoc."
  @spec drop_button() :: map()
  def drop_button do
    ~MOB"""
    <Column fill_width={true} max_font_scale={Kati.Screens.ShelfLarge.cap()}>
      <Row fill_width={true} height={56} corner_radius={28} background={Palette.ink()} align="center">
        <Text
          text={Kati.Screens.ShelfLarge.drop_label()}
          text_size={18}
          font_weight="bold"
          text_align="center"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  The zero-result footnote — a solid cream card, hand-rolled rather than
  `Kati.UI.SettingsList.note/2`.

  The board draws this frame filled rather than dashed-outlined, at
  `Palette.cream()` under `Palette.gold_icon()`/`Palette.cream_body()` — the
  same recipe `Kati.Screens.Account.privacy/1` hand-rolls for its own privacy
  note, restated here because `note/2`'s frame is a border over the page and
  this one is a fill. Its bold run goes in through `Kati.UI.rich_text/1`
  because this call site owns its own `Text`, unlike `selection_note/0`'s.
  """
  @spec empty_note() :: map()
  def empty_note do
    lead = [base: true, text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]
    emphasis = [font_weight: "semibold", text_color: Palette.ink()]
    tail = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]

    paragraph =
      UI.rich_text([
        {"A zero-result filter names ", lead},
        {"which chip", emphasis},
        {" did it and offers to drop that one. “No results” alone leaves the user to unpick four " <>
           "chips by trial.", tail}
      ])

    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
      {UI.symbol("help", size: 18, color: Palette.gold_icon())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {paragraph}
      </Column>
    </Row>
    """
  end
end
